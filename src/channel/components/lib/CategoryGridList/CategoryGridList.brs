Function init()
  tubiLog("CategoryGridList.init")
  m.top.observeField("metadataFetchTaskBatch", "onMetadataFetchTaskBatchResponse")
  m.top.observeField("focusedChild", "onComponentFocusChange")
  m.top.observeField("content", "onContentChange")
  m.top.observeField("dirtyUserCategories", "onDirtyUserCategories")
  m.top.observeField("animateToCategory", "onAnimateToCategory")
  m.RowList = m.top.findNode("RowList")
  m.RowList.observeField("rowItemFocused", "onRowItemFocused")
  m.RowList.observeField("rowItemSelected", "onRowItemSelected")

  m.RowListItemDebounce = m.top.findNode("RowListitemDebounce")
  m.RowListItemDebounce.observeField("fire", "onRowListItemDebounce")
  m.AnimateToCategoryDebounce = m.top.findNode("AnimateToCategoryDebounce")
  m.AnimateToCategoryDebounce.observeField("fire", "onAnimateToCategoryDebounce")

  m.constants = m.global.constants

  ' Parameters for the metadata block cache. Window size is number of items to fetch, page delimiter
  ' is what focus thresholds trigger a fetch.
  m.blockSize = m.constants.performance.categoryGridList.blockSize
  m.categoryWindowSize = m.constants.performance.categoryGridList.categoryWindowSize
  m.eagerLoad = m.constants.performance.categoryGridList.eagerLoad

  ' If eager loading, we don't need to listen for row changes
  if not m.eagerLoad
    m.RowList.observeField("itemFocused", "onItemFocused")
  end if

  m.metadataFetchTaskDTO = MetadataFetchTaskDTO()
  m.metadataTranslate = TubiMetadataTranslate(m.constants)

   ' if low-spec device, use the native poster nodes rather than custom components
  if m.constants.deviceInfo.limitedUi then
    m.RowList.itemComponentName = ""
  end if

  ' The content that actually populates the RowList.  Cloned from m.top so that we have a local tree we can modify
  ' Content should be structured as:
  ' <CategoryContentNode>
  '   <CategoryContentNode title="category1" />
  '     <ContentNode title="item1" />
  '     <ContentNode title="item2" />
  '   <CategoryContentNode title="category2" />
  '     <ContentNode title="item3" />
  '     <ContentNode title="item4" />
  '   <CategoryContentNode title="category3" />
  '   ...
  ' </CategoryContentNode>
  m.internalContent = invalid

  ' A stashed reference to m.top.content.  We call observeField on m.top.content so if it changes, we'll need a
  ' reference to the old value so we can unobserve it.
  m.lastContent = invalid

  if m.constants.deviceInfo.scaledUi = true then
    m.RowList.focusBitmapUri = "pkg:/images/selector-hd.9.png"
  end if

  ' suppress debounce if we have just gained focus
  m.justGainedFocus = false
End Function


'''''''''''''''''''''''''
' onComponentFocusChange
'
Function onComponentFocusChange()
  tubiLog("CategoryGridList.onComponentFocusChange " + focusState(m.top))
  if m.top.hasFocus() then
    m.RowList.setFocus(true)
    m.justGainedFocus = true
  end if
End Function

Function onContentModify(message)
  change = message.GetData()
  tubiLog("CategoryGridList.onContentModify operation = " + change.operation)
  rowItemFocused = m.RowList.rowItemFocused
  if change.operation = "insert" or change.operation = "add"
    ' insert - A child node was inserted at change.index1
    ' add - A child node was added to the end of the children node tree (at change.index1)
    new = clone(m.top.content.getChild(change.index1))

    ' NOTE!: There is a bug internal to RowList caused by inserting a child content node,
    ' causing it to create a whole bunch of new components and crash low-end devices.  Here we avoid this
    ' by removing the content first before manipulating it.  In the end the RowList doesn't destroy
    ' the rowItemComponent items when content is set to invalid, so this has almost no overhead.
    m.RowList.content = invalid  ' temporarily
    m.internalContent.insertChild(new, change.index1)
    m.RowList.content = m.internalContent
    ' RowList doesn't update the focus row automatically so we do it here to keep cursor at the same spot
    if rowItemFocused[0] <> -1 and change.index1 <= rowItemFocused[0]
      rowItemFocused[0] = rowItemFocused[0] + 1
      m.RowList.jumpToRowItem = rowItemFocused
    end if
  else if change.operation = "remove"
    ' remove - A child node was removed from position change.index1, and if change.index2>change.index1, all the children
    ' nodes between change.index1 and change.index2 inclusive were removed
    removed = m.internalContent.getChildren(change.index2-change.index1+1, change.index1)
    m.internalContent.removeChildrenIndex(change.index2-change.index1+1, change.index1)
    if rowItemFocused[0] <> -1 and change.index1 < rowItemFocused[0]
      rowItemFocused[0] = rowItemFocused[0] - 1
      m.RowList.jumpToRowItem = rowItemFocused
    end if
  else if change.operation = "set"
    ' The child node at position change.index1 was replaced with a new child node
    new = clone(m.top.content.getChild(change.index1))
    replaced = m.internalContent.getChild(new, change.index1)
    m.internalContent.replaceChild(new, change.index1)
  else if change.operation = "clear" or change.operation = "setall"
    ' clear - All the children nodes were removed
    ' setall - All the children nodes were replaced
    return onContentChange()  ' reset the entire cache
  else if change.operation = "move"
    ' move - The child node at position change.index1 was moved to the new position change.index2
    m.internalContent.insertChild(m.internalContent.getChild(index1), index2)
  else if change.operation = "modify"
    ' modify - A pre-defined content meta-data field of a ContentNode node child at change.index1  was
    '          changed (only set for ContentNode node children when a pre-defined content meta-data
    '          field changes)
    ' NOTE: ignored for CategoryGridList
  end if
  loadCategories(rowItemFocused[0])
End Function

Function onContentChange()
  tubiLog("CategoryGridList.onContentChange")
  if m.top.content = invalid
    m.RowList.content = invalid
    m.lastContent = invalid
    m.internalContent = invalid
  ' This is a verbose check that makes sure we only refresh the whole RowList content if the root node is different
  else if not m.top.content.isSameNode(m.lastContent) or (m.lastContent <> invalid and not m.lastContent.isSameNode(m.top.content)) then
    ' Setting RowList invalid here will empty the grid.  It will be set after the first batch of
    ' metadata is received.  Setting RowList.content with a few full categories will cause it to prefetch
    ' posters and do a nice fade-in.
    m.RowList.content = invalid
    if m.lastContent <> invalid then
      m.lastContent.unobserveField("change")
    end if
    m.lastContent = m.top.content
    if m.top.content <> invalid then
      ' Clone here since we are replacing nodes within the category tree
      m.internalContent = cloneDeep(m.top.content)
      loadCategories(0)
      m.top.content.observeField("change", "onContentModify")
    end if
  end if
End Function

Function onDirtyUserCategories()
  tubiLog("CategoryGridList.onDirtyUserCategories")
  if m.internalContent <> invalid
    myQueue = m.internalContent.findNode(m.constants.ui.categoryIds.queue)
    if myQueue <> invalid
      myQueue.removeChildrenIndex(myQueue.getChildCount(), 0)
      myQueue.state = "none"
    end if
    continueWatching = m.internalContent.findNode(m.constants.ui.categoryIds.history)
    if continueWatching <> invalid
      continueWatching.removeChildrenIndex(continueWatching.getChildCount(), 0)
      continueWatching.state = "none"
    end if

    ' reload the categories
    ' this is done separately in case they are not contiguous or overlap
    ' a fetch window
    myQueueIndex = getChildIndex(m.internalContent, myQueue)
    loadCategories(myQueueIndex)
    continueWatchingIndex = getChildIndex(m.internalContent, continueWatching)
    loadCategories(continueWatchingIndex)
  end if

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
  loadCategories(m.RowList.itemFocused)
End Function

' Load the current category and its adjacent categories
Function loadCategories(index) As Void
  if m.internalContent = invalid or index < 0 then
    return
  end if

  requests = []
  windowStart = (index \ m.categoryWindowSize) * m.categoryWindowSize
  for i = windowStart to (windowStart + m.categoryWindowSize)-1
    category = m.internalContent.getChild(i)
    ' If category.json is not empty, category is already loaded
    if category <> invalid and category.state = "none" then
      request = getRequest(category.id, i, "", m.blockSize)
      if request <> invalid then
        requests.push(request)
      end if
      category.state = "loading"
    end if
  end for
  if requests.count() > 0 then
    m.global.metadataFetchTask.batchRequest = m.metadataFetchTaskDTO.createBatchRequest(m.top, "metadataFetchTaskBatch", requests)
  end if
End Function

' Resolve and internal ContentNode that's been abbreviated for the CategoryGridList
' into a fully parsed TubiContentNode
'
' @rowItemIndex is 2D array of [rowindex, itemindex] from RowList.rowItemSelected or m.RowList.rowItemFocused
Function resolveAbbreviatedContent(rowItemIndex)
  if m.internalContent <> invalid
    category = m.internalContent.getChild(rowItemIndex[0])
    if category <> invalid then
      return m.metadataTranslate.getContentFromCategoryJson(category, rowItemIndex[1])
    end if
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

  if m.justGainedFocus
    onRowListItemDebounce()
    m.justGainedFocus = false
  else
    m.RowListItemDebounce.control = "start"
    ' immediately update the position counter
    category = m.internalContent.getChild(m.RowList.rowItemFocused[0])
    if category <> invalid then
      category.focusIndex = m.RowList.rowItemFocused[1]
    end if
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
  if responses <> invalid
    batchMaxIndex = 0
    for each requestId in responses
      index = mergeMetadata(responses[requestId])
      if index > batchMaxIndex
        batchMaxIndex = index
      end if
    end for

    if m.eagerLoad then
      loadCategories(batchMaxIndex+1)
    end if

    ' Delayed setting of Rowlist content until first batch arrives
    if m.RowList.content = invalid then
      m.RowList.content = m.internalContent
    end if

    ' free references to the batch so that it can be garbage collected
    m.top.metadataFetchTaskBatch = invalid
  end if
End Function

Function mergeMetadata(fetched)
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
      return -1
    end if
  else
    newContent = fetched.convertedMetadata
  end if

  tubiLog("Received response for request id " + fetched.id)
  index = -1
  categories = m.internalContent.getChildren(m.internalContent.getChildCount(), 0)
  for i=0 to categories.count()-1
    if categories[i].id = fetched.id then
      index = i
      exit for
    end if
  end for
  parentCategory = m.internalContent.getChild(index)

  ' Check if a response arrives but the cache has been flushed and categories moved, such as adding or removing user categories
  if parentCategory = invalid then
    tubiLog("Ignoring response due to changed index " + fetched.id)
    return -1
  end if

  ' These fields don't come down with the category metadata parent
  newContent.id = parentCategory.id
  newContent.title = parentCategory.title
  newContent.state = "loaded"
  m.internalContent.replaceChild(newContent, index)

  ' If RowList gets content for a focused row, it doesn't automatically emit rowItemFocused so we manually handle that here
  if index = m.RowList.rowItemFocused[0] and m.RowList.rowItemFocused[1] = -1 then
    m.RowList.jumpToRowItem = [index,0]
  end if
  if m.top.firstPosterLoaded = false then
    m.top.firstPosterLoaded = true
  end if
  return index
End Function


'''''''''''''''''''''
' getRequest
'
' Load a single category's content
Function getRequest(categoryId As String, index As Integer, field="categoryResponse" As String, per_page=0 As Integer)
  tubiLog("CategoryGridList.fetch " + categoryId)

  if categoryId = m.constants.ui.categoryIds.queue or categoryId = m.constants.ui.categoryIds.history then
    per_page = 0
  end if

  ' if there is already a request in the cache, just refresh its cache position
  request = invalid
  if categoryId = m.constants.ui.categoryIds.queue then
    request = bookmarksRequest(categoryId, field)
  else if categoryId = m.constants.ui.categoryIds.history then
    request = historyRequest(categoryId, field)
  else
    request = categoryRequest(categoryId, field, categoryId, per_page)
  end if

  ' If global bookmark or history ids are unavailable then we will get invalid
  if request = invalid then
    tubiLog("CategoryGridList.fetch: Unvailable request for category " + categoryId)
  else
    tubiLog("CategoryGridList.fetch: Asking MetadataFetchTask for " + categoryId)
  end if
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
