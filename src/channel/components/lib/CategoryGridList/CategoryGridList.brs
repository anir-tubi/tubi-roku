Function init()
  tubiLog("CategoryGridList.init")
  m.top.observeField("metadataFetchTaskResponse", "onMetadataFetchTaskResponse")
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
  '    offset: <offset into category items>
  '    length: <length of block>
  '    contentNode: <node reference to first item in the block>
  '    componentNode: <node reference to grid component assigned to this content block>
  '  }
  '
  m.metadataCache = []

  constants = m.global.constants

  ' Parameters for the metadata block cache. Window size is number of items to fetch, page delimiter
  ' is what focus thresholds trigger a fetch.
  m.blockSize = constants.performance.categoryGridList.blockSize
  m.triggerSize = constants.performance.categoryGridList.triggerSize
  m.categoryWindowSize = constants.performance.categoryGridList.categoryWindowSize

  ' The most cached blocks we can have.  This should balance out with blockSize and expectations on
  ' network performance and metadata decode speed.
  ' Max total posters at any time is (m.blockSize * (2 * m.categoryWindowsSize + 2))
  m.metadataCacheMaxEntries = constants.performance.categoryGridList.metadataCacheMaxEntries

  m.ScrollingList.focusChangeDuration = constants.performance.categoryGridList.categoryAnimationDuration
  m.gridAnimationDuration = constants.performance.categoryGridList.gridAnimationDuration
End Function


'###########
'Function onKeyEvent(key As String, press As Boolean) As Boolean
'  if key = "options" then 
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
  tubiLog("CategoryGridList.onComponentFocusChange")
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
End Function

Function onDirtyUserCategories()
  tubiLog("CategoryGridList.onDirtyUserCategories")
  ' expire any cache entries. this will also remove them from the content tree
  while metadataCacheExpireOne("MyQueue"): end while
  while metadataCacheExpireOne("ContinueWatching"): end while

  ' Calling this will kick off any fetches needed if the user categories
  ' are within the cache window
  onListFocusChange()
End Function


'''''''''''''''''''''
' onListFocusChange
'
' The ScrollingList has changed to a new category grid
Function onListFocusChange()
  tubiLog("CategoryGridList.onListFocusChange")
  m.top.categoryFocused = m.ScrollingList.itemFocused
  ' Stop listening to old category grid
  if m.ContentGrid <> invalid then
    m.ContentGrid.unobserveField("itemSelected")
    m.ContentGrid.unobserveField("itemFocused")
    m.ContentGrid.unobserveField("cursorIndex")
    m.ContentGrid.unobserveField("cursorPosition")
  end if
  m.ContentGrid = m.ScrollingList.findNode("Items").getChild(m.ScrollingList.itemFocused)
  if m.ContentGrid <> invalid then 
    m.ContentGrid.observeField("itemSelected", "onItemSelected")
    m.ContentGrid.observeField("itemFocused", "onItemFocused")
    m.ContentGrid.observeField("cursorIndex", "onCursorIndexChange")
    m.ContentGrid.observeField("cursorPosition", "onCursorPositionChange")
    m.top.cursorPosition = m.ContentGrid.cursorPosition
    if m.ContentGrid.cursorIndex = -1 then
      ' seed the first items
      fetch(m.ContentGrid, m.ContentGrid.content.id, "metadataFetchTaskResponse", m.blockSize, 1)
    else
      fetch(m.ContentGrid, m.ContentGrid.content.id, "metadataFetchTaskResponse", m.blockSize, m.ContentGrid.cursorIndex \ m.blockSize + 1)
    end if

    ' Make sure adjacent categories are warm
    for i = m.ScrollingList.itemFocused - m.categoryWindowSize to m.ScrollingList.itemFocused + m.categoryWindowSize
      adjacent = m.ScrollingList.findNode("Items").getChild(i)
      if adjacent <> invalid then
        fetch(adjacent, adjacent.content.id, "metadataFetchTaskResponse", m.blockSize, adjacent.cursorIndex \ m.blockSize + 1)
      end if
    end for

    ' Finally, set focus on the grid so user can scroll
    if m.top.isInFocusChain() then m.ContentGrid.setFocus(true)
  end if
End Function


Function onPreListFocusChange()
  m.top.preCategoryFocused = m.ScrollingList.preItemFocused
End Function


''''''''''''''''
' Item focus and selection proxies
Function onItemSelected()
  tubiLog("CategoryGridList.onItemSelected")
  m.top.itemSelected = m.ContentGrid.itemSelected
End Function

Function onItemFocused()
  tubiLog("CategoryGridList.onItemFocused")
  m.top.itemFocused = m.ContentGrid.itemFocused
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

'''''''''''''''''''''''''
' onCursorPositionChange
'
Function onCursorIndexChange() As Void
  tubiLog("CategoryGridList.onCursorIndexChange")
  if m.ContentGrid.cursorIndex < 0 then return

  '#####
  'print "*** Cursor position is " + stri(m.ContentGrid.cursorIndex)
  'print "*** Offset is " + stri(m.ContentGrid.content.offset)
  'print "*** Count is " + stri(m.ContentGrid.content.getChildCount())
  'print "*** Total is " + stri(m.ContentGrid.content.totalCount)
  '#####

  ' Make sure the current block is being fetched and/or at the top of the cache
  fetch(m.ContentGrid, m.ContentGrid.content.id, "metadataFetchTaskResponse", m.blockSize, m.ContentGrid.cursorIndex \ m.blockSize + 1)

  ' Fetch any adjacent blocks
  if (m.ContentGrid.cursorIndex MOD m.blockSize) >= (m.blockSize - m.triggerSize) and (m.ContentGrid.content.totalCount > (m.ContentGrid.content.offset + m.ContentGrid.content.getChildCount())) then
    ' next window
    fetch(m.ContentGrid, m.ContentGrid.content.id, "metadataFetchTaskResponse", m.blockSize, m.ContentGrid.cursorIndex \ m.blockSize + 2)
  else if m.ContentGrid.content.offset <> invalid and m.ContentGrid.content.offset > 0 and (m.ContentGrid.cursorIndex MOD m.blockSize) < m.triggerSize then
    ' previous window
    fetch(m.ContentGrid, m.ContentGrid.content.id, "metadataFetchTaskResponse", m.blockSize, m.ContentGrid.cursorIndex \ m.blockSize)
  end if
End Function


Function onMetadataFetchTaskResponse() As Void
  tubiLog("CategoryGridList.onMetadataFetchTaskResponse")
  response = m.top.metadataFetchTaskResponse.response

  ' TODO(Chris): handle this better.  if we set an error it should also be reset hwen the category is next fetched
  newContent = invalid
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
    newContent = m.top.metadataFetchTaskResponse.convertedMetadata
  end if

  entry = metadataCacheHasEntry(m.top.metadataFetchTaskResponse.id)
  if entry = -1 then
    'entry was expired before reponse made it here, ignore it
    tubiLog("Ignoring response for expired block " + m.top.metadataFetchTaskResponse.id)
    return
  end if

  ' we apply order to the bookmarks and history categories here since they come back from
  ' the server in any order
  if newContent <> invalid
    if Left(m.top.metadataFetchTaskResponse.id, 7) = "MyQueue" and m.global.bookmarkIds <> invalid then
      tubiLog("Sorting queue content")
      sortUserContent(newContent, m.global.bookmarkIds)
    else if Left(m.top.metadataFetchTaskResponse.id, 16) = "ContinueWatching" and m.global.historyIds <> invalid then
      tubiLog("Sorting history content")
      sortUserContent(newContent, m.global.historyIds)
    end if
  end if

  tubiLog("Received response for request id " + m.top.metadataFetchTaskResponse.id)
  m.metadataCache[entry].contentNode = newContent.getChild(0)
  m.metadataCache[entry].length = newContent.getChildCount()
  contentGrid = m.metadataCache[entry].componentNode

  ' set the offset of this block
  if m.top.metadataFetchTaskResponse.params.per_page <> invalid and m.top.metadataFetchTaskResponse.params.page <> invalid
    newContent.offset = m.top.metadataFetchTaskResponse.params.per_page *  (m.top.metadataFetchTaskResponse.params.page - 1)
  else
    newContent.offset = 0
  end if

  '#####
  'print "Received offset " + stri(newContent.offset)
  'print "Received count " + stri(newContent.getChildCount())
  '#####

  ' Merge the new content with any existing.
  'TODO(Chris): Handle the case where there is a gap between the cached content and the new content
  if contentGrid.content <> invalid then
    if newContent.offset < contentGrid.content.offset then
      if (newContent.offset + newContent.getChildCount()) >= contentGrid.content.offset then
        ' prepend new items to existing content
        overlap = (newContent.offset + newContent.getChildCount()) - contentGrid.content.offset
        prepend = newContent.getChildren(newContent.getChildCount() - overlap, 0)
        contentGrid.content.insertChildren(prepend, 0)
        contentGrid.content.offset = newContent.offset
      end if
    else
      ' append new items to existing content
      if newContent.offset <= (contentGrid.content.offset + contentGrid.content.getChildCount()) then
        overlap = (contentGrid.content.offset + contentGrid.content.getChildCount()) - newContent.offset
        contentGrid.content.removeChildrenIndex(overlap, contentGrid.content.getChildCount()-overlap)
        append = newContent.getChildren(newContent.getChildCount(), 0)
        contentGrid.content.appendChildren(append)
      end if        
    end if
  end if

  ' Add totalCount which we only get from pagination APIs
  if newContent.totalCount <> invalid and newContent.totalCount <> -1 then
    contentGrid.content.totalCount = newContent.totalCount
  else
    contentGrid.content.totalCount = contentGrid.content.getChildCount()
  end if
  contentGrid.content = contentGrid.content  ' force redraw
End Function


'''''''''''''''''''''
' fetch
'
' Load a single category's content
' NOTE!: Server-side pages are 1-based, not zero-based
Function fetch(component As Object, categoryId As String, field="categoryResponse" As String, per_page=0 As Integer, page=1 As Integer) As Void
  tubiLog("CategoryGridList.fetch " + categoryId)
  offset = per_page * (page - 1)

  ' special categories can have deprecated ids in them, causing trouble
  ' with pagination. Here we just force it to always grab the whole category

  request = invalid
  if categoryId = "MyQueue" then
    request = bookmarksRequest()
    offset = 0
    per_page = 0
  else if categoryId = "ContinueWatching" then
    request = historyRequest()
    offset = 0
    per_page = 0
  else if categoryId = "SearchSignIn" or categoryId = "SearchSignOut" then
    ' NO-OP
  else
    request = categoryRequest(categoryId)
  end if

  ' If global bookmark or history ids are unavailable then we will get invalid
  if request = invalid then
    tubiLog("Unvailable request for category " + categoryId)
    return
  end if

  requestId = categoryId + "-" + stri(offset).trim()

  ' if there is already a request in the cache, just refresh its cache position
  if metadataCacheHasEntry(requestId) <> -1 then
    tubiLog("Skipping duplicate request for " + requestId)
  else
    request.id = requestId
    request.node = m.top
    request.field = field
    if per_page <> 0 then
      request.options.params.page_enabled = true
      request.options.params.per_page = per_page
      request.options.params.page = page
    end if

    tubiLog("Asking MetadataFetchTask for " + requestId)
    m.global.metadataFetchTask.request = request
  end if
  metadataCachePush(component, categoryId, offset)
End Function


'''''''''''''''''''''
' categoryRequest
'
'
Function categoryRequest(categoryId As String) As Object
  settings = m.global.constants.settings
  url = m.global.constants.urls.cms.categories
  platform = m.global.constants.platform
  deviceInfo = m.global.constants.deviceInfo
  constants = m.global.constants

  request = {
    url: url
    name: "getCategory"
    options: {
        params: {
          "app_id": settings.shortAppName
          platform: platform
          "device_id": deviceInfo.deviceId
          "cat_id": categoryId
          all: false
          page_enabled: false
        }
      }
    }
  return request
End Function


'''''''''''''''''''''
' historyRequest
'
' Load the user's history content for "Continue Watching"
Function historyRequest()
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
    return Bookmarks.getFullHistoryReq(idList)
  end if
  return invalid
End Function


'''''''''''''''''''''
' bookmarksRequest
'
' Load the user's history content for "Continue Watching"
Function bookmarksRequest() As Object
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
    return Bookmarks.getFullBookmarksReq(idList)
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
    m.global.metadataFetchTask.cancel = {
      node: m.top
      field: "categoryResponse"
      id: expired.id
    }
  else
    ' remove the entries from the contentnode tree
    parent = expired.contentNode.getParent()

    ' check if parent is valid, it may be that the nodes were removed when adding a non-contiguous block to the parent
    if parent <> invalid then

      ' possible scenarios
      ' - expired nodes are all items in the category, remove them all
      ' - expired nodes are the prefix of items in the category, need to increase the offset number as well as remove nodes
      ' - expired nodes are the suffix of items in the category, just need to remove nodes
      ' - expired nodes are in the middle of the items in the category, need to expire another block as well? we have a 
      '   constraint of only allowing contiguous blocks
      if parent.offset = expired.offset then
        if parent.getChildCount() <= expired.length then
          'print "EXPIRE A " + expired.id
          parent.removeChildrenIndex(parent.getChildCount(), 0)
          parent.offset = 0
        else
          'print "EXPIRE B " + expired.id
          parent.removeChildrenIndex(expired.length, 0)
          parent.offset = parent.offset + expired.length
        end if
      else
        if ((parent.offset + parent.getChildCount()) - expired.offset) <= expired.length then
          'print "EXPIRE C " + expired.id
          parent.removeChildrenIndex(expired.length, expired.offset)
        else
          'print "EXPIRE D " + expired.id
          ' Here if this block is in-between two other blocks.  The proper way would be to delete all 
          ' blocks before or all blocks after, depending on where the user most recently was in the category.
          ' That's rather tedious so we'll simply refresh the cache position of this block and allow the
          ' extremeties of the span to trickle up the cache and get expired on their own. Eventually this
          ' block will not be in the middle.
          if expired <> invalid then m.metadataCache.Push(expired)
          return metadataCacheExpireOne(categoryId)  ' this will just expire the subsequent entry
        end if
      end if
      ' kick a refresh of the grid to destroy the item nodes for the expired content
      expired.componentNode.content =  expired.componentNode.content
    end if
  end if
  return true
End Function

Function metadataCachePush(component As Object, categoryId As String, offset As Integer)
  id = categoryId + "-" + stri(offset).trim()

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
      offset: offset
      length: 0    ' will be filled when the response arrives
      contentNode: invalid
      componentNode: component
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
      offset = 0
      numContent = 0
    else
      id = grid.content.id
      offset = grid.content.offset
      if offset = invalid then offset = 0
      numContent = grid.content.getChildCount()
    end if
    gridItems = grid.findNode("ContentsMask").findNode("Items")
    numItems = gridItems.getChildCount()
    print "CATEGORY-GRID-LIST[" + id + "] offset=" + stri(offset) + " numContent=" + stri(numContent) + " numItems=" + stri(numItems)
  end for
End Function