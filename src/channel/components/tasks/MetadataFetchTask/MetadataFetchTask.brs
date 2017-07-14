Function init()
  m.top.functionName = "fetchLoop"
End Function


'''''''''''''''''''''''''
' fetchLoop
'
' "main" loop of the task thread, watches for requests on
' the "request" field
'
Function fetchLoop()
  tubiLog("MetadataFetchTask.fetchLoop started")
  m.port = CreateObject("roMessagePort")
  m.queue = TubiRequestQueue().create(m.port)
  m.top.observeField("request", m.port)
  m.top.observeField("cancel", m.port)
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

  ' Ready the translator
  m.metadataTranslate = TubiMetadataTranslate(m.constants)

  ' Prepare the auth module
  m.Request = TubiRequest()
  m.Auth = TubiAuth(m.constants, m.Request)  

  ' Cache a few values we don't want to look up from m.global each call to translateRecursive.
  ' Timings here were reduced from 33ms to 2ms per content item by not referencing m.global in
  ' the recursive function below.
  setTranslateGlobalsToLocal()  ' do this once up front

  ' Signal that we're ready for requests
  m.top.ready = true

  'when the request field for the metadata task field is updated, the event is heard in this loop
  'and beginRequest() is called
  while true
    msg = wait(0, m.port)
    if type(msg) = "roSGNodeEvent" then
      if msg.GetField() = "request" then
        tubiLog("Received roSGNodeEvent for field " + msg.GetField())
        beginRequest(msg.GetData())
      else if msg.GetField() = "cancel" then
        cancelRequests(msg.GetData())
      end if
    else if type(msg) = "roUrlEvent" then
      handleResponse(msg)
    end if
  end while
End Function


'''''''''''''''''''''''''
' beginRequest
'
' process an incoming for metadata
'
Function beginRequest(metadataRequest) As Void
  tubiLog("MetadataFetchTask.beginRequest")
  if metadataRequest.node = invalid or type(metadataRequest.node) <> "roSGNode" then
    tubiLog("MetadataFetchTask.beginRequest: invalid 'node' argument")
    return
  end if

  if metadataRequest.field = invalid or metadataRequest.field = "" then
    tubiLog("MetadataFetchTask.beginRequest: invalid 'field' argument")
    return
  end if

  ' if the user is logged in, create an auth request for parental control purposes.
  ' If there is no auth info, a regular request will be created below
  httpRequest = m.Auth.createAuthRequest(metadataRequest.url, metadataRequest.name, metadataRequest.options)

  if httpRequest = invalid
    httpRequest = m.Request.createAsync(metadataRequest.url, metadataRequest.name, metadataRequest.options)
  end if

  if httpRequest = invalid then
    tubiLog("MetadataFetchTask.beginRequest: createAsyncHTTPRequest returned invalid")
    return
  end if

  ' store some context in the request object
  if metadataRequest.id <> invalid then httpRequest.mftId = metadataRequest.id
  httpRequest.node = metadataRequest.node
  httpRequest.field = metadataRequest.field
  httpRequest.request_start_time = m.timespan.TotalMilliseconds()

  m.queue.pushRequest(httpRequest)
End Function


'''''''''''''''''''''''
' cancelRequests
'
' Cancel outstanding requests, scoped to node, field, and optionally request id
Function cancelRequests(metadataRequest As Object) As Void
  tubiLog("MetadataFetchTask.cancelRequests")
  for each entry in m.queue.queue
    if entry.request.node.isSameNode(metadataRequest.node) and entry.request.field = metadataRequest.field then
      if metadataRequest.id <> invalid and entry.request.mftId <> invalid then
        if entry.request.mftId = metadataRequest.id then
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
    handledRequest.request_end_time = m.timespan.TotalMilliseconds()

    ' double check that we have our context
    if handledRequest.node <> invalid and handledRequest.field <> invalid and handledRequest.response <> invalid then
      ' response should have fields: code, data, failReason
      tubiLog("MetadataFetchTask response code was " + stri(handledRequest.response.code) + " for " + handledRequest.name)

      tubiLog("MetadataFetchTask.handleResponse setting response field " + handledRequest.field)
      tubiLog("MetadataFetchTask request duration = " + tostr(handledRequest.request_end_time - handledRequest.request_start_time))

      parsed = ParseJSON(handledRequest.response.data)
      if parsed = invalid then
        tubiLog("MetadataFetchTask failed to parse JSON response")
      else
        'indicates a request from the details screen. this request needs to be handled slightly differently
        if handledRequest.name = "getSingleContent"
          handledRequest.convertedMetadata = translateDetailsMetadata(parsed)

        'indicates a request for the full data for bookmarks - we need to handle differently because we may need to re-arrange content order
        else if handledRequest.name = m.constants.reqNames.getFullBookmarks
          handledRequest.convertedMetadata = translateBookmarkMetadata(parsed)
        else if handledRequest.name = m.constants.reqNames.getFullHistory
          handledRequest.convertedMetadata = translateBookmarkMetadata(parsed)
        else
          handledRequest.convertedMetadata = translateMetadata(parsed)
        end if
      end if
      handledRequest.convert_end_time = m.timespan.TotalMilliseconds()
      handledRequest.id = handledRequest.mftId
      tubiLog("MetadataFetchTask convert duration = " + tostr(handledRequest.convert_end_time - handledRequest.request_end_time))
      success = handledRequest.node.setField(handledRequest.field, handledRequest)
      if not success
        tubiLog("WARNING: Rendezvous failed to set response field " + handledRequest.field)
      end if
    end if
  else
    tubiLog("Request handled but response was empty or node/field was invalid")
  end if
End Function





'See example metadata at "https://uapi.adrise.tv/cms/categories?app_id=tubitv&platform=roku&device_id=AABBCCDDEEFF&page_enabled=false"

''''''''''''''''''''''
' translateMetadata
'
' Translates content from server into format that roku understands
' contentToTranslate should be parsed from JSON before it hits this function
Function translateMetadata(contentToTranslate) As Object
  translated = CreateObject("roSGNode", "TubiContentNode")

  node_count = 0

  if contentToTranslate <> invalid
    'expect a list of categories with one category filled with content or a list of contents
    if type(contentToTranslate) = "roArray"
      for each content in contentToTranslate
        if content.title <> "After Hours" or m.allowAfterHours = true
          node = translated.createChild("TubiContentNode")
          node_count = node_count + m.metadataTranslate.translateRecursive(content, node)
        end if
      end for

    'expect a single piece of content, or several (as an associative array)
    else if type(contentToTranslate) = "roAssociativeArray"

      'expect this to happen just for the search API
      if contentToTranslate.children <> invalid
        node_count = m.metadataTranslate.translateRecursive(contentToTranslate, translated)
      
      'expect this to happen for history/queue content
      else
        for each content in contentToTranslate
          if contentToTranslate[content] <> invalid
            node = translated.createChild("TubiContentNode")
            node_count = node_count + m.metadataTranslate.translateRecursive(contentToTranslate[content], node)
          end if
        end for
      end if
    end if
  end if

  setTotalCount(translated)
  tubiLog("TranslateMetadata converted " + stri(node_count) + " nodes")
  return translated
end Function


''''''''''''''''''''''
' translateDetailsMetadata
'
' Translates content from server into format that roku understands, specifically for details screen
' contentToTranslate should be parsed from JSON before it hits this function
Function translateDetailsMetadata(contentToTranslate) As Object
  translated = CreateObject("roSGNode", "TubiContentNode")
  'will affect/update the translated node that is passed in
  m.metadataTranslate.translateRecursive(contentToTranslate, translated)
  setTotalCount(translated)
  return translated
End Function


''''''''''''''''''''''
' translateBookmarkMetadata
'
' Translates content from server into format that roku understands, specifically for bookmarks AND history
Function translateBookmarkMetadata(contentToTranslate) As Object
  translated = CreateObject("roSGNode", "TubiContentNode")
  nodeCount = 0
  for each contentId in contentToTranslate
    if contentToTranslate[contentId] <> invalid
      node = translated.createChild("TubiContentNode")
      nodeCount = nodeCount + m.metadataTranslate.translateRecursive(contentToTranslate[contentId], node)
    end if
  end for
  setTotalCount(translated)
  tubiLog("TranslateMetadata converted " + stri(nodeCount) + " nodes")
  return translated
End Function


Function setTranslateGlobalsToLocal()
  m.contentTypes = m.global.constants.ui.contentTypes
  m.captionsMode = m.global.constants.deviceInfo.captionsMode
  m.creditsDuration = m.global.constants.player.creditsDuration
  m.allowAfterHours = m.global.constants.settings.allowAfterHours
end Function


Function setTotalCount(metadata As Object)
  if metadata.totalCount = -1 and metadata.getChildCount() <> 0 then
    metadata.totalCount = metadata.getChildCount()
  end if
End Function