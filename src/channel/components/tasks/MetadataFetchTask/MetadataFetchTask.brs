Function init()
  m.top.functionName = "fetchLoop"
  ' Observe pattern which ensures that we don't lose events before the thread
  ' is running. This works because m.top is copied from the render thread to the task
  ' thread at the point at which m.top.control = "RUN" is run. Any events that m.port
  ' has heard before fetchLoop runs remain on the port until they are handled by the while loop within fetchLoop.
  m.port = CreateObject("roMessagePort")
  m.top.observeField("request", m.port)
  m.top.observeField("batchRequest", m.port)
  m.top.observeField("cancel", m.port)
  m.top.control = "RUN"
End Function


'''''''''''''''''''''''''
' fetchLoop
'
' "main" loop of the task thread, watches for requests on
' the "request" field
'
Function fetchLoop()
  tubiLog("MetadataFetchTask.fetchLoop started")
  m.queue = TubiRequestQueue().create(m.port)
  while true
    m.constants = m.global.getField("constants")   ' this should grab a thread-local copy
    if m.constants <> invalid then
      exit while
    end if
    tubiLog("WARNING: Rendezvous failed for constants")
  end while

  m.timespan = CreateObject("roTimeSpan")
  m.timespan.mark()
  m.epoch = m.timespan.TotalMilliseconds()
  m.totalConversionTime = 0

  ' Ready the translator
  experiments = TubiExperiments(m.constants)
  m.metadataTranslate = TubiMetadataTranslate(m.constants, experiments)

  ' Prepare the auth module
  m.Request = TubiRequest(m.constants.settings.mode)
  m.Auth = TubiAuth(m.constants, m.Request)  
  m.CmsApi = CmsApi(m.constants, m.Request, m.Auth)
  m.NodeHelpers = TubiNodeHelpers()
  m.Bookmarks = TubiBookmarks(m.Request, m.Auth, m.constants, m.NodeHelpers)

  ' Cache a few values we don't want to look up from m.global each call to translateRecursive.
  ' Timings here were reduced from 33ms to 2ms per content item by not referencing m.global in
  ' the recursive function below.
  setTranslateGlobalsToLocal()  ' do this once up front

  'when the request field for the metadata task field is updated, the event is heard in this loop
  'and beginRequest() is called
  while true
    msg = wait(0, m.port)
    if type(msg) = "roSGNodeEvent" then
      tubiLog("MetadataFetchRequest received roSGNodeEvent for field: '" + msg.GetField() + "'")
      if msg.GetField() = "request" then
        beginRequest(msg.GetData())
      else if msg.GetField() = "batchRequest" then
        beginBatch(msg.GetData())
      else if msg.GetField() = "cancel" then
        cancelRequests(msg.GetData())
      end if
    else if type(msg) = "roUrlEvent" then
      handleResponse(msg)
    end if
  end while
End Function


Function beginBatch(batchRequest) As Void
  tubiLog("MetadataFetchTask.beginBatch")
  m.totalConversionTime = 0
  if type(batchRequest.node) <> "roSGNode" then
    tubiLog("MetadataFetchTask.beginBatch: invalid 'node' argument")
    return
  end if

  if batchRequest.field = invalid or batchRequest.field = "" then
    tubiLog("MetadataFetchTask.beginBatch: invalid 'field' argument")
    return
  end if

  if type(batchRequest.requests) <> "roAssociativeArray" then
    tubiLog("MetadataFetchTask.beginBatch: invalid requests array")
    return
  end if

  batchResponse = {}
  for each requestId in batchRequest.requests
    request = batchRequest.requests[requestId]
    batchResponse[requestId] = invalid  ' seed the response holder
    request.batchResponse = batchResponse
    ' duplicate these so that the beginRequest logic can stay the same
    request.node = batchRequest.node
    request.field = batchRequest.field
    beginRequest(request)
  end for
End Function


'''''''''''''''''''''''''
' beginRequest
'
' process an incoming for metadata
'
Function beginRequest(metadataRequest) As Void
  tubiLog("MetadataFetchTask.beginRequest")
  if type(metadataRequest.node) <> "roSGNode" then
    tubiLog("MetadataFetchTask.beginRequest: invalid 'node' argument")
    return
  end if

  if metadataRequest.field = invalid or metadataRequest.field = "" then
    tubiLog("MetadataFetchTask.beginRequest: invalid 'field' argument")
    return
  end if

  ' if the user is logged in, create an auth request for parental control purposes.
  ' If there is no auth info, a regular request will be created below
  httpRequest = invalid
  if metadataRequest.name = m.constants.reqNames.getHomescreen

    if metadataRequest.options = invalid
      metadataRequest.options = {}
    end if

    if metadataRequest.options.params = invalid
      metadataRequest.options.params = {}
    end if

    if metadataRequest.options.params.limit = invalid
      metadataRequest.options.params.limit = m.constants.performance.categoryGridList.initialBlockSize
    end if

    httpRequest = m.CmsApi.homeScreenReq(metadataRequest.kidsMode, metadataRequest.options)
  else if metadataRequest.name = m.constants.reqNames.getCategory or metadataRequest.name = m.constants.reqNames.getSearchDefault
    categoryId = metadataRequest.id
    name = metadataRequest.name
    kidsMode = metadataRequest.kidsMode 
    httpRequest = m.CmsApi.categoryReq(categoryId, name, kidsMode, metadataRequest.options)
  else if metadataRequest.name = m.constants.reqNames.searchAPI
    kidsMode = metadataRequest.kidsMode 
    httpRequest = m.CmsApi.searchReq(metadataRequest.searchText, kidsMode)
  end if

  if httpRequest = invalid then
    tubiLog("MetadataFetchTask.beginRequest: createAsyncHTTPRequest returned invalid")
    return
  end if

  ' store some context in the request object
  context = {}
  context.append(metadataRequest)
  context.request_start_time = m.timespan.TotalMilliseconds()
  httpRequest.context = context

  m.queue.pushRequest(httpRequest)
End Function


'''''''''''''''''''''''
' cancelRequests
'
' Cancel outstanding requests, scoped to node, field, and optionally request id
Function cancelRequests(metadataRequest As Object) As Void
  tubiLog("MetadataFetchTask.cancelRequests")
  for each entry in m.queue.queue
    if entry.request.context.node.isSameNode(metadataRequest.node) and entry.request.context.field = metadataRequest.field then
      if metadataRequest.id <> invalid and entry.request.context.id <> invalid then
        if entry.request.context.id = metadataRequest.id then
          tubiLog("CANCELLING REQUEST")
          m.queue.cancelRequest(entry.request)
        end if
      else
        ' don't match id if it was never given
        tubiLog("CANCELLING REQUEST")
        m.queue.cancelRequest(entry.request)
      end if
    end if
  end for
  tubiLog("Queue size = " + stri(m.queue.count()))
End Function


'''''''''''''''''''''''''
' handleResponse
'
' route an incoming metadata response to the node which requested it
'
Function handleResponse(message)
  tubiLog("MetadataFetchTask.handleResponse")
  handledRequest = m.queue.handleEvent(message)

  ' invalid can be returned if request is being retried
  if handledRequest <> invalid then
    request_end_time = m.timespan.TotalMilliseconds()

    ' double check that we have our context
    if handledRequest.context.node <> invalid and handledRequest.context.field <> invalid and handledRequest.response <> invalid then
      ' response should have fields: code, data, failReason
      tubiLog("MetadataFetchTask response code was " + stri(handledRequest.response.code) + " for " + handledRequest.context.name)

      tubiLog("MetadataFetchTask.handleResponse setting response field " + handledRequest.context.field)
      tubiLog("MetadataFetchTask request duration = " + (request_end_time - handledRequest.context.request_start_time).toStr())

      parsed = ParseJSON(handledRequest.response.data)
      
      if parsed = invalid then
        tubiLog("MetadataFetchTask failed to parse JSON response")
      else
        'indicates a request from the details screen. this request needs to be handled slightly differently
        if handledRequest.context.name = m.constants.reqNames.getCategory or handledRequest.context.name = m.constants.reqNames.getSearchDefault
          '//tell translate function to only include specific orientation thumbnails: featured search result 
          orientation = ""
          bFullData = false
          if handledRequest.context.name = m.constants.reqNames.getSearchDefault
            orientation = m.constants.ui.gridItemTypes.portrait
            bFullData = true
          end if
          contentMode = handledRequest.params.contentMode
          handledRequest.convertedMetadata = m.metadataTranslate.translateContainer(parsed, handledRequest.response.data, orientation, bFullData, contentMode)
        else if handledRequest.context.name = m.constants.reqNames.getHomescreen
          bFullData = false
          if handledRequest.context.options <> invalid and handledRequest.context.options.contentMode <> invalid and handledRequest.context.options.contentMode = "news"
            '//If this is news, then get the full data so the logo info is available immediately
            bFullData = true
          end if
          contentMode = handledRequest.params.contentMode
          authInfo = m.global.authInfo
          isKidsModeEnabled = handledRequest.params.isKidsMode
          handledRequest.convertedMetadata = m.metadataTranslate.translateHomescreen(parsed, contentMode, authInfo, isKidsModeEnabled, bFullData)
        else
          ' I believe that search is the only other entry point here
          handledRequest.convertedMetadata = m.metadataTranslate.translate(parsed)
        end if
      end if

      convert_end_time = m.timespan.TotalMilliseconds()
      m.totalConversionTime = m.totalConversionTime + (convert_end_time - request_end_time)
      handledRequest.id = handledRequest.context.id
      tubiLog("MetadataFetchTask convert duration = " + (convert_end_time - request_end_time).toStr())

      ' if not a batch, return now, otherwise collect all responses
      if handledRequest.context.batchResponse = invalid then
        success = handledRequest.context.node.setField(handledRequest.context.field, handledRequest)
        tubiLog("MetadataFetchTask rendezvous duration = " + (m.timespan.TotalMilliseconds() - convert_end_time).toStr())
      else
        context = handledRequest.context 
        handledRequest.context = invalid  ' to avoid circular reference
        batchResponse = context.batchResponse
        batchResponse[handledRequest.id] = handledRequest

        ' see if all responses are complete
        expected = batchResponse.count()
        completed = 0
        for each requestId in batchResponse
          if batchResponse[requestId] <> invalid then
            completed = completed + 1
          end if
        end for
        if completed = expected then
          success = context.node.setField(context.field, batchResponse)

          tubiLog("MetadataFetchTask total conversion time = " + m.totalConversionTime.toStr())
          tubiLog("MetadataFetchTask rendezvous duration = " + (m.timespan.TotalMilliseconds() - convert_end_time).toStr())
        else
          tubiLog("MetadataFetchTask completed " + stri(completed) + " of " + stri(expected))
          success = true
        end if
      end if

      if not success
        tubiLog("WARNING: Rendezvous failed to set response field")
      end if

    end if
  else
    tubiLog("Request handled but response was empty or node/field was invalid")
  end if
End Function



Function setTranslateGlobalsToLocal()
  m.contentTypes = m.global.constants.ui.contentTypes
  m.creditsDuration = m.global.constants.player.creditsDuration
  m.allowAfterHours = m.global.constants.settings.allowAfterHours
end Function

