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

  ' get single feature poster value
  m.singleFeaturePoster = false
  if m.constants.ui.categoryScreen.singleFeaturePoster <> invalid
     m.singleFeaturePoster = m.constants.ui.categoryScreen.singleFeaturePoster
  else
    m.singleFeaturePoster = (getExperimentValue("UserNamespace", "roku_single_feature_poster") = 1)
  end if

  m.timespan = CreateObject("roTimeSpan")
  m.timespan.mark()
  m.epoch = m.timespan.TotalMilliseconds()
  m.totalConversionTime = 0

  ' Ready the translator
  m.metadataTranslate = TubiMetadataTranslate(m.constants)

  ' Prepare the auth module
  m.Request = TubiRequest()
  m.Auth = TubiAuth(m.constants, m.Request)
  m.NodeHelpers = TubiNodeHelpers()
  m.Bookmarks = TubiBookmarks(m.Request, m.Auth, m.constants, m.NodeHelpers)

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
        else if handledRequest.context.name = m.constants.reqNames.getCategory
          handledRequest.convertedMetadata = translateCategoryMetadata(parsed, handledRequest.response.data)
        else if handledRequest.context.name = m.constants.reqNames.getHomescreen
          handledRequest.convertedMetadata = translateHomescreenMetadata(parsed)
        else
          handledRequest.convertedMetadata = translateMetadata(parsed)
        end if
      end if
      convert_end_time = m.timespan.TotalMilliseconds()
      m.totalConversionTime = m.totalConversionTime + (convert_end_time - request_end_time)
      handledRequest.id = handledRequest.context.id
      tubiLog("MetadataFetchTask convert duration = " + tostr(convert_end_time - request_end_time))

      ' if not a batch, return now, otherwise collect all responses
      if handledRequest.context.batchResponse = invalid then
        success = handledRequest.context.node.setField(handledRequest.context.field, handledRequest)
        tubiLog("MetadataFetchTask rendezvous duration = " + tostr(m.timespan.TotalMilliseconds() - convert_end_time))
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

          tubiLog("MetadataFetchTask total conversion time = " + tostr(m.totalConversionTime))
          tubiLog("MetadataFetchTask rendezvous duration = " + tostr(m.timespan.TotalMilliseconds() - convert_end_time))
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


''''''''''''''''''''
' translateCategoryMetadata
'
' Translate content specifically targeted at CategoryGridList.  This is aimed at PERFORMANCE
' above ease of use so it only translates the minimal necessary fields.  The performance
' tricks used here, found through measurement are:
' 1) Use ContentNode instead of TubiContentNode
' 2) Use ifSGNodeChildren.update() to leverage native code for node creation and setting fields
' 3) Avoid custom fields in favor of ContentNode's defined fields, this avoiding addField() calls in a loop
Function translateCategoryMetadata(contentToTranslate, fullJson) As Object
  translated = CreateObject("roSGNode", "CategoryContentNode")
  container = contentToTranslate.container
  contents = contentToTranslate.contents

  contentsJson = getContentsJson(contents, fullJson)

  node_count = 0
  categoryMetadata = buildCategoryAA(container, contents, contentsJson)
  if categoryMetadata = invalid  'happens if a container has no valid content in it (ie. all content is out of window)
    return invalid
  end if

  if type(categoryMetadata) = "roAssociativeArray"
    ' buildCategoryAA always returns AA.state = "partial", 
    ' but any single category request should be considered fully loaded
    categoryMetadata.state = "loaded"
    translated.update(categoryMetadata)
    node_count = 1 + translated.getChildCount()
  end if

  ' Set a flag only on content with landscape posters.  We do it here manually
  ' to avoid having to define a custom content node which have
  ' proven to be much slower to instantiate.  Could use some testing,
  ' though.
  if container.id = m.constants.ui.categoryIds.featured and m.singleFeaturePoster <> true
    for i = 0 to translated.getChildCount()-1
      child = translated.getChild(i)
      child.addField("isLandscape", "boolean", false)
      child.isLandscape = true
    end for
  end if

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


''''''''''''''''''''''
' translateHomescreenMetadata
' Translate the initial homescreen call to matrix api
'
' @contentToTranslate: roAssocArray, should have a form like:
'                     {
'                        containers: [
'                           {
'                             id: "featured"
'                             children: ["37108", "337825", "304771"]
'                             ...
'                           }
'                           {
'                             id: "most_popular"
'                             children: ["346629", "407698", "300175"]
'                             ...
'                           }
'                        ],
'                        contents: {
'                           "37108": {
'                               id: "37108"
'                               title: ...
'                           },
'                           "337825": {
'                               id: "337825"
'                               title: ...
'                           },
'                           ...
'                        }
'                     }
'
' Returns a set of content meta data in the form below.
' The ContentNodes will have a limited set of meta data, just enough to propagate the category grid.
' The outer most CategoryContentNode's json field will be filled with the contents json
' <CategoryContentNode json={...all contents info...}>
'   <CategoryContentNode id="featured">
'     <ContentNode id="37108" />
'     <ContentNode id="337825" />
'      ...
'   </CategoryContentNode>
'   <CategoryContentNode id="most_popular" />
'     <ContentNode id="346629" />
'     <ContentNode id="407698" />
'      ...
'   </CategoryContentNode>
' </CategoryContentNode>
'
Function translateHomescreenMetadata(contentToTranslate) As Object
  translated = CreateObject("roSGNode", "CategoryContentNode")
  homescreenAA = {
    id: ""
    title: ""
    children: []    'categories
  }

  containers = contentToTranslate.containers
  contents = contentToTranslate.contents

  'set up AAs for all categories including any nested categories
  for i=0 to containers.count()-1
    container = containers[i]
    if container.type <> "complex"
      categoryAA = buildCategoryAA(container, contents)
      if categoryAA <> invalid
        homescreenAA.children.push(categoryAA)
      end if
    else
      for j=0 to container.children.count()-1
        nestedContainer = container.children[j]
        categoryAA = buildCategoryAA(nestedContainer, contents)
        if categoryAA <> invalid
          categoryAA.parentId = container.id
          homescreenAA.children.push(categoryAA)
        end if
      end for
    end if
  end for

  translated.update(homescreenAA)
  node_count = 1 + translated.getChildCount()
  tubiLog("TranslateMetadata converted " + stri(node_count) + " nodes")
  return translated
End Function


''''''''''''''''''''''
' buildCategoryAA
'
' @container: assocArray, a single container as found in the matrix API
' @contents: assocArray, a set of content meta data as found in the matrix API
' @contentsJson: string, the JSON string of just the contents portion of the matrix API
'
' returns an associative array that can be passed to ContentNode.udpate() to populate the ContentNode and it's children
Function buildCategoryAA(container, contents, contentsJson=invalid)
  updateMetadata = {}
  if type(container) = "roAssociativeArray" and type(contents) = "roAssociativeArray"
    updateMetadata = {
      id: container.id
      title: container.title
      description: container.description
      children: CreateObject("roArray", container.children.count(), false)
      totalCount: 0
      offset: m.constants.performance.categoryGridList.initialBlockSize
      type: m.contentTypes.category
      json: ""
      state: "partial"
    }

    jsonAA = {}
    validCount = 0
    for each child in container.children
      ' contents[child].valid is "true" or "false" for user categories and is invalid for all other categories.
      ' For all other categories, assume all contents are valid.
      if contents[child] <> invalid and contents[child].valid <> false
        fullChild = contents[child]

        childAA = {
          id: fullChild.id
          title: fullChild.title
          description: fullChild.description
          length: fullChild.duration
          subtype: "ContentNode"
        }
        if container.id = m.constants.ui.categoryIds.featured and m.singleFeaturePoster <> true and fullChild.hero_images <> invalid then
          childAA.hdgridposterurl = fullChild.hero_images[0]
        else if fullChild.posterarts <> invalid then
          childAA.hdgridposterurl = fullChild.posterarts[0]
        end if

        ' normalize ids for series, should always be zero-prefixed
        if fullChild.type = "s" or fullChild.type = "a"
          childAA.id = "0" + fullChild.id
        end if
        jsonAA[childAA.id] = fullChild
        validCount += 1
        updateMetadata.children.push(childAA)
      end if
    end for

    ' if all the content is out of window, do not return category metadata aa
    ' container.cursor = 0 for limitedUI matrix/homescreen calls
    ' container.cursor = invalid for matrix/containers/{id} calls
    ' if we are getting category from matrix/containers/{id} and it returns no valid content,
    ' we want to remove that category from the category screen
    if container.cursor = invalid and validCount = 0
      return invalid
    end if

    updateMetadata.totalCount = validCount
    if contentsJson <> invalid
      updateMetadata.json = contentsJson
    else
      updateMetadata.json = FormatJSON(jsonAA)
    end if
  end if

  return updateMetadata
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


'helper function to encapsulate getting the contents JSON from a matrix single container response
Function getContentsJson(contents, fullJson)
  contentsJson = invalid

  'Doing string operations to isolate the contents portion of the JSON matrix response is considerably faster than re-formatting the JSON
  contentsIdentifier =  Chr(34) + "contents" + Chr(34) + ":{"
  contentsPos = Instr(0, fullJson, contentsIdentifier)
  if contentsPos > 0
    contentsJsonLength = fullJson.len() - contentsPos - contentsIdentifier.len() + 1
    contentsJson = Mid(fullJson, contentsPos + contentsIdentifier.len()-1, contentsJsonLength)
  else
    'Do a Format JSON since we can't find the contents with our string search
    tubiLog("Formatted JSON for category metadata", "warn", "clientWarn", "category-metadata-format-json")
    contentsJson = FormatJSON(contents)
  end if

  return contentsJson
End Function
