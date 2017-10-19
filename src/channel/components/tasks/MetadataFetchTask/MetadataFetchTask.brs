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
  m.top.observeField("batchRequest", m.port)
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
      tubiLog("Received roSGNodeEvent for field " + msg.GetField())
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
  httpRequest = m.Auth.createAuthRequest(metadataRequest.url, metadataRequest.name, metadataRequest.options)

  if httpRequest = invalid
    httpRequest = m.Request.createAsync(metadataRequest.url, metadataRequest.name, metadataRequest.options)
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
      tubiLog("MetadataFetchTask request duration = " + tostr(request_end_time - handledRequest.context.request_start_time))

      parsed = ParseJSON(handledRequest.response.data)
      if parsed = invalid then
        tubiLog("MetadataFetchTask failed to parse JSON response")
      else
        'indicates a request from the details screen. this request needs to be handled slightly differently
        if handledRequest.context.name = m.constants.reqNames.getSingleContent
          handledRequest.convertedMetadata = translateDetailsMetadata(parsed)

        'indicates a request for the full data for bookmarks - we need to handle differently because we may need to re-arrange content order
        else if handledRequest.context.name = m.constants.reqNames.getFullBookmarks
          handledRequest.convertedMetadata = translateBookmarkMetadata(parsed, handledRequest.context.sortOrder)
        else if handledRequest.context.name = m.constants.reqNames.getFullHistory
          handledRequest.convertedMetadata = translateBookmarkMetadata(parsed, handledRequest.context.sortOrder)
        else if handledRequest.context.name = m.constants.reqNames.getCategory
          handledRequest.convertedMetadata = translateCategoryMetadata(parsed, handledRequest.response.data, handledRequest.context.isFeaturedCategory)
        else if handledRequest.context.name = m.constants.reqNames.getAllCategories
          handledRequest.convertedMetadata = translateAllCategoriesMetadata(parsed)
        else
          handledRequest.convertedMetadata = translateMetadata(parsed)
        end if
      end if
      convert_end_time = m.timespan.TotalMilliseconds()
      handledRequest.id = handledRequest.context.id
      tubiLog("MetadataFetchTask convert duration = " + tostr(convert_end_time - request_end_time))

      ' if not a batch, return now, otherwise collect all responses
      if handledRequest.context.batchResponse = invalid then
        success = handledRequest.context.node.setField(handledRequest.context.field, handledRequest)
        tubiLog("MetadataFetchTask rendezvous duration = " + tostr(m.timespan.TotalMilliseconds() - convert_end_time))
      else
        batchResponse = handledRequest.context.batchResponse
        batchResponse[handledRequest.context.id] = handledRequest

        ' see if all responses are complete
        expected = batchResponse.count()
        completed = 0
        for each requestId in batchResponse
          if batchResponse[requestId] <> invalid then
            completed = completed + 1
          end if
        end for
        if completed = expected then
          success = handledRequest.context.node.setField(handledRequest.context.field, batchResponse)
          tubiLog("MetadataFetchTask rendezvous duration = " + tostr(m.timespan.TotalMilliseconds() - convert_end_time))
        else
          tubiLog("MetadataFetchTask completed " + stri(completed) + " of " + stri(expected))
          success = true
        end if
      end if

      if not success
        tubiLog("WARNING: Rendezvous failed to set response field " + handledRequest.context.field)
      end if
    end if
  else
    tubiLog("Request handled but response was empty or node/field was invalid")
  end if
End Function


''''''''''''''''''''
' translateCategoryMetadata
'
' Translate content specifically targeted at CategoryGridList.  This is aimed at PERFORMANCE
' above ease of use so it only translates the minimal necessary fields.  The performance
' tricks used here, found through measurement are:
' 1) Use ContentNode instead of TubiContentNode
' 2) Use ifSGNodeChildren.update() to leverage native code for node creation and setting fields
' 3) Avoid custom fields in favor of ContentNode's defined fields, this avoiding addField() calls in a loop
Function translateCategoryMetadata(contentToTranslate, json, isFeaturedCategory) As Object
  translated = CreateObject("roSGNode", "CategoryContentNode")
  node_count = 0
  if isFeaturedCategory = invalid then
    isFeaturedCategory = false
  end if
  if contentToTranslate <> invalid and type(contentToTranslate) = "roAssociativeArray" and contentToTranslate.children <> invalid
    updateMetadata = {
      id: contentToTranslate.id
      title: contentToTranslate.title
      children: CreateObject("roArray", contentToTranslate.children.count(), false)
      totalCount: contentToTranslate.children.count()
      json: json
    }
    for each child in contentToTranslate.children
      childAA = {
        id: child.id
        title: child.title
        description: child.description
        length: child.duration
        subtype: "ContentNode"
      }
      if isFeaturedCategory and child.hero_images <> invalid then
        childAA.hdgridposterurl = child.hero_images[0]
      else if child.posterarts <> invalid then
        childAA.hdgridposterurl = child.posterarts[0]
      end if
      ' normalize ids for series, should always be zero-prefixed
      if child.type = "s" or child.type = "a"
        childAA.id = "0" + child.id
      end if
      updateMetadata.children.push(childAA)
    end for
    translated.update(updateMetadata)
    node_count = 1 + translated.getChildCount()
  end if

  setTotalCount(translated)
  tubiLog("TranslateMetadata converted " + stri(node_count) + " nodes")
  return translated
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


Function translateAllCategoriesMetadata(contentToTranslate) As Object
  translated = CreateObject("roSGNode", "CategoryContentNode")
  wrappedContent = {
    id: ""
    title: ""
    children: CreateObject("roArray", contentToTranslate.count(), false)
  }
  for i=0 to contentToTranslate.count()-1
    content = contentToTranslate[i]
    if content.title <> "After Hours" or m.allowAfterHours = true
      childAA = {
        id: content.id
        title: content.title
        description: content.description
      }
      wrappedContent.children.push(childAA)
    end if
  end for
  translated.update(wrappedContent)
  node_count = 1 + translated.getChildCount()
  tubiLog("TranslateMetadata converted " + stri(node_count) + " nodes")
  return translated
End Function

''''''''''''''''''''''
' translateBookmarkMetadata
'
' Translates content from server into format that roku understands, specifically for bookmarks AND history
' @sortOrder - array of string content ids to use for sorting the items in contentToTranslate
Function translateBookmarkMetadata(contentToTranslate, sortOrder) As Object
  wrappedContent = {
    id: ""
    title: ""
    children: CreateObject("roArray", contentToTranslate.count(), false)
  }

  for i=0 to sortOrder.count()-1
    contentItem = contentToTranslate[sortOrder[i]]
    if contentItem <> invalid then
      wrappedContent.children.push(contentItem)
      contentToTranslate.Delete(sortOrder[i])
    end if
  end for

  ' remaining unsorted items will be appended
  for each contentId in contentToTranslate
    if contentToTranslate[contentId] <> invalid then
      wrappedContent.children.push(contentToTranslate[contentId])
    end if
  end for
  json = FormatJSON(wrappedContent)
  return translateCategoryMetadata(wrappedContent, json, false)
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