Function init()
  tubiLog("CategoryGridList.init")
  m.top.observeField("metadataFetchTaskResponse", "onMetadataFetchTaskResponse")
  m.top.observeField("metadataFetchTaskBatch", "onMetadataFetchTaskBatchResponse")
  m.top.observeField("focusedChild", "onComponentFocusChange")
  m.top.observeField("content", "onContentChange")
  m.top.observeField("dirtyUserCategories", "onDirtyUserCategories")
  m.top.observeField("animateToCategory", "onAnimateToCategory")
  m.RowList = m.top.findNode("RowList")
  m.RowList.observeField("itemFocused", "onItemFocused")
  m.RowList.observeField("rowItemFocused", "onRowItemFocused")
  m.RowList.observeField("rowItemSelected", "onRowItemSelected")

  m.RowListItemDebounce = m.top.findNode("RowListitemDebounce")
  m.RowListItemDebounce.observeField("fire", "onRowListItemDebounce")
  m.RowListCategoryDebounce = m.top.findNode("RowListCategoryDebounce")
  m.RowListCategoryDebounce.observeField("fire", "onRowListCategoryDebounce")
  m.AnimateToCategoryDebounce = m.top.findNode("AnimateToCategoryDebounce")
  m.AnimateToCategoryDebounce.observeField("fire", "onAnimateToCategoryDebounce")
  ' The metadata block cache.  Each entry has the following structure
  '
  '  {
  '    id: "<category>-<offset>"
  '    contentNode: <node reference to grid component assigned to this content block>
  '    parentContentNode: <node reference to category parent of the content block>
  '    index: <index of category content node in m.internalContent>
  '  }
  '
  m.metadataCache = []

  m.constants = m.global.constants

  ' Parameters for the metadata block cache. Window size is number of items to fetch, page delimiter
  ' is what focus thresholds trigger a fetch.
  m.blockSize = m.constants.performance.categoryGridList.blockSize
  m.categoryWindowSize = m.constants.performance.categoryGridList.categoryWindowSize

  ' The most cached blocks we can have.  This should balance out with blockSize and expectations on
  ' network performance and metadata decode speed.
  ' Max total posters at any time is (m.blockSize * (2 * m.categoryWindowsSize + 2))
  m.metadataCacheMaxEntries = m.constants.performance.categoryGridList.metadataCacheMaxEntries

  m.metadataFetchTaskDTO = MetadataFetchTaskDTO()
  m.metadataTranslate = TubiMetadataTranslate(m.constants)

   ' if low-spec device, use the native poster nodes rather than custom components
  if m.constants.deviceInfo.limitedNewUi then
    m.RowList.itemComponentName = ""
  end if
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
  if m.top.hasFocus() then
    m.RowList.setFocus(true)
  end if
End Function


Function onContentChange()
  tubiLog("CategoryGridList.onContentChange")
  m.RowList.content = invalid
  if m.top.content <> invalid then
    ' Clone here since we are replacing nodes within the category tree
    m.internalContent = cloneDeep(m.top.content)
    loadCategories(0)
  end if
End Function

Function onDirtyUserCategories()
  tubiLog("CategoryGridList.onDirtyUserCategories")
  ' expire any cache entries. this will also remove them from the content tree
  while metadataCacheExpireOne("MyQueue"): end while
  while metadataCacheExpireOne("ContinueWatching"): end while

  ' Calling this will kick off any fetches needed if the user categories
  ' are within the cache window
  loadCategories(m.RowList.itemFocused)
End Function

' animateToCategory doesn't cause rowItemFocused or itemFocused to be triggered unless
' the RowList has focus.  We capture this in order to load categories even when the
' RowList doesn't have focus.
Function onAnimateToCategory()
  tubiLog("CategoryGridList.onAnimateToCategory")
  m.AnimateToCategoryDebounce.control = "start"
End Function

Function onAnimateToCategoryDebounce()
  loadCategories(m.top.animateToCategory)
End Function

'''''''''''''''''''''
' onItemFocused
'
' The RowList has changed to a new category row
Function onItemFocused()
  tubiLog("CategoryGridList.onItemFocused")
  if m.RowList.itemFocused <> -1 then
    m.RowListCategoryDebounce.control = "start"
  end if
End Function

Function onRowListCategoryDebounce()
  tubiLog("CategoryGridList.onRowLisCategoryDebounce")
  m.top.categoryFocused = m.RowList.itemFocused
  loadCategories(m.RowList.itemFocused)
End function

' Load the current ContentGrid and its adjacent categories
Function loadCategories(index) As Void
  if m.internalContent = invalid or index < 0 then
    return
  end if

  categoryContent = m.internalContent.getChild(index)
  if categoryContent <> invalid then
    ' Make sure adjacent categories are warm
    requests = []
    for i = index - m.categoryWindowSize to index + m.categoryWindowSize
      adjacent = m.internalContent.getChild(i)
      if adjacent <> invalid then
        request = fetch(adjacent, adjacent.id, i, "", m.blockSize)
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
'
' @rowItemIndex is 2D array of [rowindex, itemindex] from RowList.rowItemSelected or m.RowList.rowItemFocused
Function resolveAbbreviatedContent(rowItemIndex)
  category = m.internalContent.getChild(rowItemIndex[0])
  if category <> invalid then
    if category.json <> invalid and category.json <> "" then
      parsed = ParseJson(category.json)
      if parsed <> invalid then
        fullContent = parsed.children[rowItemIndex[1]]
        translated = CreateObject("roSGNode", "TubiContentNode")
        m.metadataTranslate.translateRecursive(fullContent, translated)
        return translated
      end if
    end if
    ' just return the abbreviated content.  This happens for user categories every time
    return category.getChild(rowItemIndex[1])
  end if
  return invalid
End Function

''''''''''''''''
' onRowItemSelected - RowList.rowItemSelected event handler, triggered when user presses "OK"
Function onRowItemSelected()
  tubiLog("CategoryGridList.onRowItemSelected")
  m.top.itemSelected = resolveAbbreviatedContent(m.RowList.rowItemSelected)
End Function


'''''''''''''''
' onRowItemFocused - RowList.rowItemFocused event handler.  To reduce jank we debounce these events
Function onRowItemFocused()
  tubiLog("CategoryGridList.onRowItemFocused")

  m.RowListItemDebounce.control = "start"
  ' immediately update the position counter
  category = m.internalContent.getChild(m.RowList.rowItemFocused[0])
  if category <> invalid then
    category.focusIndex = m.RowList.rowItemFocused[1]
  end if
End Function

'''''''''''''''
' onRowListItemDebounce - RowList.rowItemFocus debounce handler
Function onRowListItemDebounce()
  tubiLog("CategoryGridList.onRowListItemDebounce")
  m.top.itemFocused = resolveAbbreviatedContent(m.RowList.rowItemFocused)
End Function


Function onMetadataFetchTaskBatchResponse(message) As Void
  tubiLog("CategoryGridList.onMetadataFetchTaskBatchResponse")
  responses = message.GetData()
  for each requestId in responses
    mergeMetadata(responses[requestId])
  end for

  ' Delayed setting of Rowlist content until first batch arrives
  if m.RowList.content = invalid then
    m.RowList.content = m.internalContent
  end if
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

  tubiLog("Received response for request id " + fetched.id)
  m.metadataCache[entry].contentNode = newContent.getChild(0)
  parentCategory = m.metadataCache[entry].parentContentNode
  index = m.metadataCache[entry].index

  ' Add the new content
  if parentCategory <> invalid then
    ' These fields don't come down with the category metadata parent
    newContent.id = parentCategory.id
    newContent.title = parentCategory.title
    newContent.addField("focusIndex", "integer", false)
    m.internalContent.replaceChild(newContent, index)
    m.metadataCache[entry].parentContentNode = newContent
    parentCategory = newContent
  end if

  ' If RowList gets content for a focused row, it doesn't automatically emit rowItemFocused so we manually handle that here
  if index = m.RowList.rowItemFocused[0] and m.RowList.rowItemFocused[1] = -1 then
    m.RowList.jumpToRowItem = [index,0]
  end if
  if m.top.firstPosterLoaded = false then
    m.top.firstPosterLoaded = true
  end if
End Function


'''''''''''''''''''''
' fetch
'
' Load a single category's content
Function fetch(parentContentNode As Object, categoryId As String, index As Integer, field="categoryResponse" As String, per_page=0 As Integer)
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
  metadataCachePush(parentContentNode, categoryId, index)
  return request
End Function


'''''''''''''''''''''
' categoryRequest
'
'
Function categoryRequest(requestId As String, field As String, categoryId As String, per_page As Integer) As Object
  url = m.constants.urls.cms.categories
  options = {
    params: {
      "app_id": m.constants.settings.shortAppName,
      "platform": m.constants.platform,
      "device_id": m.constants.deviceInfo.deviceId,
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
  return m.metadataFetchTaskDTO.createRequest(requestId, m.top, field, url, m.constants.reqNames.getCategory, options, isFeaturedCategory)
End Function


'''''''''''''''''''''
' historyRequest
'
' Load the user's history content for "Continue Watching"
Function historyRequest(requestId As String, field As String) As Object
  Request = TubiRequest()
  Auth = TubiAuth(m.constants, Request)
  Bookmarks = TubiBookmarks(Request, Auth, m.constants)
  historyIds = m.global.historyIds
  idList = []
  for i=0 to historyIds.getChildCount()-1
    idList.push(historyIds.getChild(i).id)
  end for
  request = Bookmarks.getFullHistoryReq(idList)
  return m.metadataFetchTaskDTO.createRequest(requestId, m.top, field, request.url, m.constants.reqNames.getFullHistory, request.options, false, idList)
End Function


'''''''''''''''''''''
' bookmarksRequest
'
' Load the user's history content for "My Queue"
Function bookmarksRequest(requestId As String, field As String) As Object
  Request = TubiRequest()
  Auth = TubiAuth(m.constants, Request)
  Bookmarks = TubiBookmarks(Request, Auth, m.constants)
  bookmarkIds = m.global.bookmarkIds
  idList = []
  for i=0 to bookmarkIds.getChildCount()-1
    idList.push(bookmarkIds.getChild(i).id)
  end for
  request = Bookmarks.getFullBookmarksReq(idList)
  return m.metadataFetchTaskDTO.createRequest(requestId, m.top, field, request.url, m.constants.reqNames.getFullBookmarks, request.options, false, idList)
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
    parent = expired.parentContentNode
    if parent <> invalid then
      parent.removeChildrenIndex(parent.getChildCount(), 0)
      parent.offset = 0
    end if
  end if
  return true
End Function

Function metadataCachePush(parentContentNode As Object, categoryId As String, index As Integer)
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
      parentContentNode: parentContentNode
      index: index
    }
    m.metadataCache.Push(entry)

    if m.metadataCache.count() >= m.metadataCacheMaxEntries then
      metadataCacheExpireOne()
    end if      
  end if
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