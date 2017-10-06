Function init()
  tubiLog("CategoryGridList.init")
  m.top.observeField("metadataFetchTaskResponse", "onMetadataFetchTaskResponse")
  m.top.observeField("metadataFetchTaskBatch", "onMetadataFetchTaskBatchResponse")
  m.top.observeField("focusedChild", "onComponentFocusChange")
  m.top.observeField("content", "onContentChange")
  m.top.observeField("dirtyUserCategories", "onDirtyUserCategories")
  m.ScrollingList = m.top.findNode("ScrollingList")
  m.ScrollingList.observeField("itemFocused", "onListFocusChange")
  m.ScrollingList.observeField("preItemFocused", "onPreListFocusChange")

  ' The metadata block cache.  Each entry has the following structure
  '
  '  {
  '    id: "<category>-<offset>"
  '    contentNode: <node reference to first item in the block>
  '    componentNode: <node reference to grid component assigned to this content block>
  '  }
  '
  m.metadataCache = []

  constants = m.global.constants

  ' Parameters for the metadata block cache. Window size is number of items to fetch, page delimiter
  ' is what focus thresholds trigger a fetch.
  m.blockSize = constants.performance.categoryGridList.blockSize
  m.categoryWindowSize = constants.performance.categoryGridList.categoryWindowSize

  ' The most cached blocks we can have.  This should balance out with blockSize and expectations on
  ' network performance and metadata decode speed.
  ' Max total posters at any time is (m.blockSize * (2 * m.categoryWindowsSize + 2))
  m.metadataCacheMaxEntries = constants.performance.categoryGridList.metadataCacheMaxEntries

  m.ScrollingList.focusChangeDuration = constants.performance.categoryGridList.categoryAnimationDuration
  m.gridAnimationDuration = constants.performance.categoryGridList.gridAnimationDuration

  ' Used to bubble up that the first poster in the first category content grid has been loaded
  m.firstCategoryContentGrid = invalid

  m.metadataFetchTaskDTO = MetadataFetchTaskDTO()
End Function


'###########
'Function onKeyEvent(key As String, press As Boolean) As Boolean
'  if press and key = "options" then
'    DumpCacheEntries()
'    DumpItemStats()
'    STOP
'    return true
'  end if
'  return false
'End Function
'###########




'''''''''''''''''''''''''
' onComponentFocusChange
'
Function onComponentFocusChange()
  tubiLog("CategoryGridList.onComponentFocusChange" + focusState(m.top))
  if m.top.hasFocus() and m.ContentGrid <> invalid then
    m.ContentGrid.setFocus(true)
  end if
End Function


Function onContentChange()
  tubiLog("CategoryGridList.onContentChange")
  m.ScrollingList.content = m.top.content
  
  contentGridsParent = m.ScrollingList.findNode("Items")
  ' Set some particulars to the content grids.  We do this here so
  ' that we can consolidate control of these parameters and references
  ' to m.global where they come from.  m.global references take a performance
  ' hit each time they happen

  for i=0 to contentGridsParent.getChildCount()-1
    categoryContentGrid = contentGridsParent.getChild(i)    
    categoryContentGrid.focusChangeDuration = m.gridAnimationDuration
  end for

  'listen so we can send load time to server
  if m.firstCategoryContentGrid = invalid
    m.firstCategoryContentGrid = contentGridsParent.getChild(0)
    m.firstCategoryContentGrid.isFirstInList = true
    m.firstCategoryContentGrid.observeField("firstPosterLoaded", "onFirstPosterLoaded")
  end if
End Function

Function onDirtyUserCategories()
  tubiLog("CategoryGridList.onDirtyUserCategories")
  ' expire any cache entries. this will also remove them from the content tree
  while metadataCacheExpireOne("MyQueue"): end while
  while metadataCacheExpireOne("ContinueWatching"): end while

  ' Calling this will kick off any fetches needed if the user categories
  ' are within the cache window
  loadCategories(m.ScrollingList.itemFocused)
End Function


'''''''''''''''''''''
' onListFocusChange
'
' The ScrollingList has changed to a new category grid.
' This is debounced so only called when user stops on a category
Function onListFocusChange()
  tubiLog("CategoryGridList.onListFocusChange")
  loadCategories(m.ScrollingList.itemFocused)
  m.top.categoryFocused = m.ScrollingList.itemFocused
End function

'''''''''''''''''''''''''
' onPreListFocusChange
'
' This is a leading-edge trigger and will happen even when fast scrolling
Function onPreListFocusChange()
  tubiLog("CategoryGridList.onPreListFocusChange")
  focusCategory(m.ScrollingList.preItemFocused)
  m.top.preCategoryFocused = m.ScrollingList.preItemFocused
End Function

Function focusCategory(newIndex)
  ' Stop listening to old category grid
  if m.ContentGrid <> invalid then
    m.ContentGrid.unobserveField("itemSelected")
    m.ContentGrid.unobserveField("itemFocused")
    m.ContentGrid.unobserveField("cursorPosition")
  end if
  m.ContentGrid = m.ScrollingList.findNode("Items").getChild(newIndex)
  if m.ContentGrid <> invalid then 
    'check if we need to update the spinner placement/width
    if m.top.isFullWidth = false
      m.ContentGrid.findNode("Spinner").width = 1310
    else
      m.ContentGrid.findNode("Spinner").width = 1750
    end if

    m.ContentGrid.observeField("itemSelected", "onItemSelected")
    m.ContentGrid.observeField("itemFocused", "onItemFocused")
    m.ContentGrid.observeField("cursorPosition", "onCursorPositionChange")
    m.top.cursorPosition = m.ContentGrid.cursorPosition
    ' Finally, set focus on the grid so user can scroll
    if m.top.isInFocusChain() then m.ContentGrid.setFocus(true)
  end if
End Function

' Load the current ContentGrid and its adjacent categories
Function loadCategories(index)
  contentGrid = m.ScrollingList.findNode("Items").getChild(index)
  if contentGrid <> invalid then
    if contentGrid.cursorIndex = -1 then
      ' seed the first items
      immediate = fetch(contentGrid, contentGrid.content.id, "metadataFetchTaskResponse", m.blockSize)
    else
      immediate = fetch(contentGrid, contentGrid.content.id, "metadataFetchTaskResponse", m.blockSize)
    end if
    if immediate <> invalid then
      m.global.metadataFetchTask.request = immediate
    end if

    ' Make sure adjacent categories are warm
    requests = []
    for i = index - m.categoryWindowSize to index + m.categoryWindowSize
      adjacent = m.ScrollingList.findNode("Items").getChild(i)
      if adjacent <> invalid then
        request = fetch(adjacent, adjacent.content.id, "", m.blockSize)
        if request <> invalid then
          requests.push(request)
        end if
      end if
    end for
    if requests.count() > 0 then
      m.global.metadataFetchTask.batchRequest = m.metadataFetchTaskDTO.createBatchRequest(m.top, "metadataFetchTaskBatch", requests)
    end if
  end if
End Function

' Resolve and internal ContentNode that's been abbreviated for the CategoryGridList
' into a fully parsed TubiContentNode
Function resolveAbbreviatedContent(abbreviated, index)
  if abbreviated <> invalid and abbreviated.subType() = "ContentNode" then
    category = abbreviated.getParent()
    if category <> invalid and category.json <> invalid then
      parsed = ParseJson(category.json)
      if parsed <> invalid then
        fullContent = parsed.children[index]
        translated = CreateObject("roSGNode", "TubiContentNode")
        TubiMetadataTranslate(m.global.constants).translateRecursive(fullContent, translated)
        return translated
      end if
    end if
    return invalid
  else
    return abbreviated
  end if
End Function

''''''''''''''''
' Item focus and selection proxies
Function onItemSelected()
  tubiLog("CategoryGridList.onItemSelected")
  ' Resolve the abbreviated category content into a full TubiContentNode
  m.top.itemSelected = resolveAbbreviatedContent(m.ContentGrid.itemSelected, m.ContentGrid.cursorIndex)
End Function

Function onItemFocused()
  tubiLog("CategoryGridList.onItemFocused")
  m.top.itemFocused = resolveAbbreviatedContent(m.ContentGrid.itemFocused, m.ContentGrid.cursorIndex)
End Function

Function onCursorPositionChange()
  tubiLog("CategoryGridList.onCursorPositionChange")
  m.top.cursorPosition = m.ContentGrid.cursorPosition
End Function


Function sortUserContent(unsortedContent, order)
  for i=0 to order.getChildCount()-1
    orderItem = order.getChild(i)
    contentItem = unsortedContent.findNode(orderItem.id)
    ' push it to bottom, it will behave like a stack
    if contentItem <> invalid then unsortedContent.appendChild(contentItem)
  end for
End Function

Function onMetadataFetchTaskBatchResponse(message) As Void
  tubiLog("CategoryGridList.onMetadataFetchTaskBatchResponse")
  responses = message.GetData()
  for each requestId in responses
    mergeMetadata(responses[requestId])
  end for
End Function

Function onMetadataFetchTaskResponse(message) As Void
  tubiLog("CategoryGridList.onMetadataFetchTaskResponse")
  mergeMetadata(message.GetData())
End Function

Function mergeMetadata(fetched) As Void
  ' TODO(Chris): handle this better.  if we set an error it should also be reset hwen the category is next fetched
  newContent = invalid
  response = fetched.response
  if response.code < 200 or response.code >= 300 then
    testLog("Category content returned " + stri(response.code))
    m.top.error = {
      code: response.code
      failReason: response.failReason
    }

    ' Fake an empty response on 400s, which may be due to empty user categories
    if response.code = 400 then
      newContent = CreateObject("roSGNode", "TubiContentNode")
    else
      return
    end if
  else
    newContent = fetched.convertedMetadata
  end if

  entry = metadataCacheHasEntry(fetched.id)
  if entry = -1 then
    'entry was expired before reponse made it here, ignore it
    tubiLog("Ignoring response for expired block " + fetched.id)
    return
  end if

  ' we apply order to the bookmarks and history categories here since they come back from
  ' the server in any order
  if newContent <> invalid
    if Left(fetched.id, 7) = "MyQueue" and m.global.bookmarkIds <> invalid then
      tubiLog("Sorting queue content")
      sortUserContent(newContent, m.global.bookmarkIds)
    else if Left(fetched.id, 16) = "ContinueWatching" and m.global.historyIds <> invalid then
      tubiLog("Sorting history content")
      sortUserContent(newContent, m.global.historyIds)
    end if
  end if

  tubiLog("Received response for request id " + fetched.id)
  m.metadataCache[entry].contentNode = newContent.getChild(0)
  contentGrid = m.metadataCache[entry].componentNode
  parentCategory = contentGrid.content

  ' Add the new content
  if parentCategory <> invalid then
    ' replace any existing content.  This will work for populating empty categories as well as reloading user categories    
    if parentCategory.getChildCount() = 0 then
      parentCategory.removeChildrenIndex(parentCategory.getChildCount(), 0)
    end if
    parentCategory.appendChildren(newContent.getChildren(newContent.getChildCount(), 0))
  end if

  ' Add json source string
  if newContent.json <> invalid then
    parentCategory.json = newContent.json
  end if

  ' Add totalCount
  parentCategory.totalCount = contentGrid.content.getChildCount()
  parentCategory.offset = 0  ' offset is always zero since we load whole categories only
  contentGrid.content = parentCategory  ' force redraw
End Function


'''''''''''''''''''''
' fetch
'
' Load a single category's content
Function fetch(component As Object, categoryId As String, field="categoryResponse" As String, per_page=0 As Integer)
  tubiLog("CategoryGridList.fetch " + categoryId)

  if categoryId = "MyQueue" or categoryId = "ContinueWatching" then
    per_page = 0
  end if

  requestId = categoryId + "-0"

  ' if there is already a request in the cache, just refresh its cache position
  request = invalid
  if metadataCacheHasEntry(requestId) <> -1 then
    tubiLog("CategoryGridList.fetch: Skipping duplicate request for " + requestId)
  else
    if categoryId = "MyQueue" then
      request = bookmarksRequest(requestId, field)
    else if categoryId = "ContinueWatching" then
      request = historyRequest(requestId, field)
    else
      request = categoryRequest(requestId, field, categoryId, per_page)
    end if

    ' If global bookmark or history ids are unavailable then we will get invalid
    if request = invalid then
      tubiLog("CategoryGridList.fetch: Unvailable request for category " + categoryId)
    else
      tubiLog("CategoryGridList.fetch: Asking MetadataFetchTask for " + requestId)
    end if
  end if
  metadataCachePush(component, categoryId)
  return request
End Function


'''''''''''''''''''''
' categoryRequest
'
'
Function categoryRequest(requestId As String, field As String, categoryId As String, per_page As Integer) As Object
  constants = m.global.constants  ' only one reference to m.global for performance
  url = constants.urls.cms.categories
  options = {
    params: {
      "app_id": constants.settings.shortAppName,
      "platform": constants.platform,
      "device_id": constants.deviceInfo.deviceId,
      "cat_id": categoryId,
      "all": false,
      "page_enabled": true,
      "page": 1,
      "per_page": per_page
    }
  }
  if categoryId = "featured" then
    isFeaturedCategory = true
  else
    isFeaturedCategory = false
  end if
  return m.metadataFetchTaskDTO.createRequest(requestId, m.top, field, url, constants.reqNames.getCategory, options, isFeaturedCategory)
End Function


'''''''''''''''''''''
' historyRequest
'
' Load the user's history content for "Continue Watching"
Function historyRequest(requestId As String, field As String) As Object
  constants = m.global.constants
  Request = TubiRequest()
  Auth = TubiAuth(constants, Request)
  Bookmarks = TubiBookmarks(Request, Auth, constants)
  historyIds = m.global.historyIds
  if historyIds <> invalid then
    idList = []
    for i=0 to historyIds.getChildCount()-1
      idList.push(historyIds.getChild(i).id)
    end for
    request = Bookmarks.getFullHistoryReq(idList)
    return m.metadataFetchTaskDTO.createRequest(requestId, m.top, field, request.url, constants.reqNames.getFullHistory, request.options)
  end if
  return invalid
End Function


'''''''''''''''''''''
' bookmarksRequest
'
' Load the user's history content for "My Queue"
Function bookmarksRequest(requestId As String, field As String) As Object
  constants = m.global.constants
  Request = TubiRequest()
  Auth = TubiAuth(constants, Request)
  Bookmarks = TubiBookmarks(Request, Auth, constants)
  bookmarkIds = m.global.bookmarkIds
  if bookmarkIds <> invalid then
    idList = []
    for i=0 to bookmarkIds.getChildCount()-1
      idList.push(bookmarkIds.getChild(i).id)
    end for
    request = Bookmarks.getFullBookmarksReq(idList)
    return m.metadataFetchTaskDTO.createRequest(requestId, m.top, field, request.url, constants.reqNames.getFullBookmarks, request.options)
  end if
  return invalid
End Function


''''''''''''''''''''
' Metadata Cache management
'
Function metadataCacheHasEntry(id As String) As Integer
  for i=0 to m.metadataCache.count()-1
    if m.metadataCache[i].id = id then return i
  end for
  return -1
End Function


'''''''''''''''''''''''''''
' metadataCacheExpireOne
'
' Expire one entry, optionally giving a categoryId to only expire items for that
' category
'
' returns true if entry was expired, or false if a categoryId was given and no entries matched
Function metadataCacheExpireOne(categoryId="" As String) As Boolean
  expired = invalid
  ' expire one entry
  if categoryId="" then
    expired = m.metadataCache.Shift()
  else
    ' find an entry whose category matches
    for i=0 to m.metadataCache.count()-1
      if Left(m.metadataCache[i].id, Len(categoryId)) = categoryId then
        expired = m.metadataCache[i]
        m.metadataCache.Delete(i)
        exit for
      end if
    end for
  end if

  ' cache was empty or categoryId was given and no matches found
  if expired = invalid then
    return false
  end if

  'tubiLog("Expiring cache entry for " + expired.id)
  if expired.contentNode = invalid then
    'print "CANCELLING IN-FLIGHT REQUEST for " + expired.id
    ' Cancel in-flight requests.  There is a race condition here where response may have already come in.
    ' We need to check for this at the response handler.
    m.global.metadataFetchTask.cancel = m.metadataFetchTaskDTO.createCancel(expired.id, m.top, "categoryResponse")
  else
    ' remove the entries from the contentnode tree
    parent = expired.contentNode.getParent()
    if parent <> invalid then
      parent.removeChildrenIndex(parent.getChildCount(), 0)
      parent.offset = 0
      ' kick a refresh of the grid to destroy the item nodes for the expired content
      expired.componentNode.content =  expired.componentNode.content
    end if
  end if
  return true
End Function

Function metadataCachePush(component As Object, categoryId As String)
  id = categoryId + "-0"

  ' check if entry already exists and reset its cache position
  i = metadataCacheHasEntry(id)
  if i <> -1 then
    'print "FOUND CACHE ENTRY AT INDEX " + stri(i) + ". RESETTING ITS POSITION " + id
    entry = m.metadataCache[i]
    m.metadataCache.Delete(i)
    m.metadataCache.Push(entry)
  else
    ' put the new entry in first so we can detect expire case D and keep blocks adjacent to the new block
    entry = {
      id: id
      category: categoryId
      contentNode: invalid
      componentNode: component
    }
    m.metadataCache.Push(entry)

    if m.metadataCache.count() >= m.metadataCacheMaxEntries then
      metadataCacheExpireOne()
    end if      
  end if
End Function



'This is used as an intermediary to bubble up info that content has loaded on screen so we can let the server know time to load
Function onFirstPosterLoaded()
  m.firstCategoryContentGrid.unobserveField("firstPosterLoaded")
  m.top.firstPosterLoaded = true
End Function

''''''''''''''''''''
' Debugging Helpers
''''''''''''''''''''


Function DumpCacheEntries()
  for i=0 to m.metadataCache.count()-1
    entry = m.metadataCache[i]
    hasData = (entry.contentNode <> invalid)
    print "METADATA-CACHE[" + stri(i) + "]: " + entry.id + " hasData = " + hasData.toStr()
  end for
End Function

Function DumpItemStats()
  gridList = m.ScrollingList.findNode("Items")
  for i=0 to gridList.getChildCount()-1
    grid = gridList.getChild(i)
    if grid.content = invalid then
      id = ""
      numContent = 0
    else
      id = grid.content.id
      numContent = grid.content.getChildCount()
    end if
    gridItems = grid.findNode("ContentsMask").findNode("Items")
    numItems = gridItems.getChildCount()
    print "CATEGORY-GRID-LIST[" + id + "] numContent=" + stri(numContent) + " numItems=" + stri(numItems)
  end for
End Function