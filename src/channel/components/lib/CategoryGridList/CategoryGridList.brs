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
    m.ContentGrid.unobserveField("cursorIndex")
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
    m.ContentGrid.observeField("cursorIndex", "onCursorIndexChange")
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
      immediate = fetch(contentGrid, contentGrid.content.id, "metadataFetchTaskResponse", m.blockSize, 1)
    else
      immediate = fetch(contentGrid, contentGrid.content.id, "metadataFetchTaskResponse", m.blockSize, contentGrid.cursorIndex \ m.blockSize + 1)
    end if
    if immediate <> invalid then
      m.global.metadataFetchTask.request = immediate
    end if

    ' Make sure adjacent categories are warm
    requests = []
    for i = index - m.categoryWindowSize to index + m.categoryWindowSize
      adjacent = m.ScrollingList.findNode("Items").getChild(i)
      if adjacent <> invalid then
        request = fetch(adjacent, adjacent.content.id, "", m.blockSize, adjacent.cursorIndex \ m.blockSize + 1)
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
  requests = []
  currentBlock = fetch(m.ContentGrid, m.ContentGrid.content.id, "metadataFetchTaskResponse", m.blockSize, m.ContentGrid.cursorIndex \ m.blockSize + 1)
  if currentBlock <> invalid then
    requests.push(currentBlock)
  end if

  ' Fetch any adjacent blocks
  if (m.ContentGrid.cursorIndex MOD m.blockSize) >= (m.blockSize - m.triggerSize) and (m.ContentGrid.content.totalCount > (m.ContentGrid.content.offset + m.ContentGrid.content.getChildCount())) then
    ' next window
    request = fetch(m.ContentGrid, m.ContentGrid.content.id, "metadataFetchTaskResponse", m.blockSize, m.ContentGrid.cursorIndex \ m.blockSize + 2)
    if request <> invalid then
      requests.push(request)
    end if
  else if m.ContentGrid.content.offset <> invalid and m.ContentGrid.content.offset > 0 and (m.ContentGrid.cursorIndex MOD m.blockSize) < m.triggerSize then
    ' previous window
    request = fetch(m.ContentGrid, m.ContentGrid.content.id, "metadataFetchTaskResponse", m.blockSize, m.ContentGrid.cursorIndex \ m.blockSize)
    if request <> invalid then
      requests.push(request)
    end if
  end if
  if requests.count() > 0 then
    m.global.metadataFetchTask.batchRequest = m.metadataFetchTaskDTO.createBatchRequest(m.top, "metadataFetchTaskBatch", requests)
  end if
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
  m.metadataCache[entry].length = newContent.getChildCount()
  contentGrid = m.metadataCache[entry].componentNode

  ' set the offset of this block
  if fetched.params.per_page <> invalid and fetched.params.page <> invalid
    newContent.offset = fetched.params.per_page * (fetched.params.page - 1)
  else
    newContent.offset = 0
  end if

  '#####
  'print "Received offset " + stri(newContent.offset)
  'print "Received count " + stri(newContent.getChildCount())
  '#####

  ' Merge the new content with any existing.
  if contentGrid.content <> invalid then
    if newContent.offset < contentGrid.content.offset and (newContent.offset + newContent.getChildCount()) >= contentGrid.content.offset then
      ' new content prefixes existing content without gaps
      overlap = (newContent.offset + newContent.getChildCount()) - contentGrid.content.offset
      prepend = newContent.getChildren(newContent.getChildCount() - overlap, 0)
      '#####
      'print "Prefix: "; contentGrid.content.offset; "-"; (contentGrid.content.offset+contentGrid.content.getChildCount()); " with "; newContent.offset; "-"; newContent.offset+prepend.count()
      '#####
      contentGrid.content.insertChildren(prepend, 0)
      contentGrid.content.offset = newContent.offset
    else if newContent.offset >= contentGrid.content.offset and newContent.offset <= (contentGrid.content.offset + contentGrid.content.getChildCount()) then
      ' new content suffixes existing content without gaps
      overlap = (contentGrid.content.offset + contentGrid.content.getChildCount()) - newContent.offset
      contentGrid.content.removeChildrenIndex(overlap, contentGrid.content.getChildCount()-overlap)
      '#####
      'print "Suffix: "; contentGrid.content.offset; "-"; (contentGrid.content.offset+contentGrid.content.getChildCount()); " with "; newContent.offset-overlap; "-"; newContent.offset + newContent.getChildCount()
      '#####
      append = newContent.getChildren(newContent.getChildCount(), 0)
      contentGrid.content.appendChildren(append)
    else
      ' Corner case: content is not adjacent to existing content"
      if contentGrid.cursorIndex >= newContent.offset and contentGrid.cursorIndex <= (newContent.offset + newContent.getChildCount() - 1) then
        ' purge existing items
        reentry = m.metadataCache[entry]  ' this will get purged so we keep a reference to it
        m.metadataCache[entry].contentNode = invalid 'so that the purge doesn't mess with our new content
        '#####
        'print "Replace A: "; contentGrid.content.offset; "-"; (contentGrid.content.offset+contentGrid.content.getChildCount()); " with "; newContent.offset; "-"; newContent.offset + newContent.getChildCount()
        '#####
        while metadataCacheExpireOne(reentry.category): end while
        metadataCachePush(reentry.componentNode, reentry.category, reentry.offset)
        entry = metadataCacheHasEntry(reentry.id)
        m.metadataCache[entry].contentNode = newContent.getChild(0)
        m.metadataCache[entry].length = newContent.getChildCount()
        append = newContent.getChildren(newContent.getChildCount(), 0)
        '#####
        'print "Replace B: "; contentGrid.content.offset; "-"; (contentGrid.content.offset+contentGrid.content.getChildCount()); " with "; newContent.offset; "-"; newContent.offset + newContent.getChildCount()
        '#####
        contentGrid.content.appendChildren(append)
        contentGrid.content.offset = newContent.offset
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
Function fetch(component As Object, categoryId As String, field="categoryResponse" As String, per_page=0 As Integer, page=1 As Integer)
  tubiLog("CategoryGridList.fetch " + categoryId)
  offset = per_page * (page - 1)
  if offset < 0 then
    tubiLog("CategoryGridList.fetch: Skipping request for negative offset")
    return invalid
  end if

  ' special categories can have deprecated ids in them, causing trouble
  ' with pagination. Here we just force it to always grab the whole category
  if categoryId = "MyQueue" or categoryId = "ContinueWatching" then
    offset = 0
    per_page = 0
  end if

  requestId = categoryId + "-" + stri(offset).trim()

  ' if there is already a request in the cache, just refresh its cache position
  request = invalid
  if metadataCacheHasEntry(requestId) <> -1 then
    tubiLog("CategoryGridList.fetch: Skipping duplicate request for " + requestId)
  else
    if categoryId = "MyQueue" then
      request = bookmarksRequest()
    else if categoryId = "ContinueWatching" then
      request = historyRequest()
    else if categoryId = "SearchSignIn" or categoryId = "SearchSignOut" then
      ' NO-OP
    else
      request = categoryRequest(categoryId)
    end if

    ' If global bookmark or history ids are unavailable then we will get invalid
    if request = invalid then
      tubiLog("CategoryGridList.fetch: Unvailable request for category " + categoryId)
    else
      if per_page <> 0 then
        request.options.params.page_enabled = true
        request.options.params.per_page = per_page
        request.options.params.page = page
      end if
      request = m.metadataFetchTaskDTO.createRequest(requestId, m.top, field, request.url, request.name, request.options)
      tubiLog("CategoryGridList.fetch: Asking MetadataFetchTask for " + requestId)
    end if
  end if
  metadataCachePush(component, categoryId, offset)
  return request
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
    m.global.metadataFetchTask.cancel = m.metadataFetchTaskDTO.createCancel(expired.id, m.top, "categoryResponse")
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
          parent.removeChildrenIndex(expired.length, expired.offset - parent.offset)
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
      category: categoryId
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