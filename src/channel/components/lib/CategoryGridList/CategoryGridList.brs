Function init()
  tubiLog("CategoryGridList.init")
  m.constants = m.global.constants
  m.NodeHelpers = TubiNodeHelpers()

  m.top.observeField("metadataFetchTaskBatch", "onMetadataFetchTaskBatchResponse")
  m.top.observeField("focusedChild", "onComponentFocusChange")
  m.top.observeField("contentUpdated", "onContentChange")
  m.top.observeField("repopulateContent", "onRepopulateContent")
  m.top.observeField("animateToCategory", "onAnimateToCategory")
  m.RowList = m.top.findNode("RowList")
  m.RowList.observeField("rowItemFocused", "onRowItemFocused")
  m.RowList.observeField("rowItemSelected", "onRowItemSelected")

  m.RowListItemDebounce = m.top.findNode("RowListitemDebounce")
  m.RowListItemDebounce.observeField("fire", "onRowListItemDebounce")
  m.AnimateToCategoryDebounce = m.top.findNode("AnimateToCategoryDebounce")
  m.AnimateToCategoryDebounce.observeField("fire", "onAnimateToCategoryDebounce")

  ' Parameters for the metadata block cache. Window size is number of items to fetch, page delimiter
  ' is what focus thresholds trigger a fetch.
  m.initialBlockSize = m.constants.performance.categoryGridList.initialBlockSize
  m.finalBlockSize = m.constants.performance.categoryGridList.finalBlockSize
  m.categoryWindowSize = m.constants.performance.categoryGridList.categoryWindowSize
  m.eagerLoad = m.constants.performance.categoryGridList.eagerLoad

  ' If eager loading, we don't need to listen for row changes
  if not m.eagerLoad
    m.RowList.observeField("itemFocused", "onItemFocused")
  end if

  m.metadataFetchTaskDTO = MetadataFetchTaskDTO()
  m.metadataTranslate = TubiMetadataTranslate(m.constants)

  if getExperimentResource("roku2", "roku_safe_area").enabled = true
    m.RowList.rowItemSpacing="[[12,0]]"
  end if

  if m.constants.deviceInfo.scaledUi = true then
    m.RowList.focusBitmapUri = "pkg:/images/selector-hd.9.png"
  end if
  m.RowList.focusBitmapBlendColor = m.global.theme.focused
  m.global.observeField("theme", "onThemeChange")

  ' suppress debounce if we have just gained focus
  m.justGainedFocus = false

  ' stores an array of the form [y, x], which can be set on RowList.jumpToItem
  m.itemToJumpTo = invalid
End Function


Function onThemeChange()
  m.RowList.focusBitmapBlendColor = m.global.theme.focused
End Function


'''''''''''''''''''''''''
' onComponentFocusChange
'
Function onComponentFocusChange()
  tubiLog("CategoryGridList.onComponentFocusChange " + focusState(m.top))
  if m.top.hasFocus()

    rowItemFocused = m.RowList.rowItemFocused
    if rowItemFocused.count() <> 2
      '//The rowList has not gained focus yet so use the default upperleft item.
      rowItemFocused = [0,0]
    end if 

    if resolveAbbreviatedContent(rowItemFocused) <> invalid or (m.itemToJumpTo <> invalid and resolveAbbreviatedContent(m.itemToJumpTo) <> invalid)
      if m.itemToJumpTo <> invalid
        m.RowList.jumpToRowItem = m.itemToJumpTo
        m.itemToJumpTo = invalid
      end if

      m.justGainedFocus = true
      m.RowList.setFocus(true)
      'an extra set focus is necessary due to a bug in the roku Rowlist component that offsets the cursor in error. 
      '   This is especially true when the Rowlist does not have initial focus when the content has loaded.
      m.RowList.setFocus(false)
      m.RowList.setFocus(true)
    end if
  end if
End Function


Function onContentChange()
  tubiLog("CategoryGridList.onContentChange")
  if m.top.content = invalid
    m.RowList.content = invalid
  ' This is a verbose check that makes sure we only refresh the whole RowList content if the root node is different
  else
    ' Setting RowList invalid here will empty the grid.  It will be set after the first batch of
    ' metadata is received.  Setting RowList.content with a few full categories will cause it to prefetch
    ' posters and do a nice fade-in.
    m.RowList.content = invalid
    if m.top.content <> invalid then
      setRowHeights()

      itemFocused = [1, 1]
      if resolveAbbreviatedContent(itemFocused) <> invalid
        ' set focus for high spec models that already have categories with content from the matrix/homescreen response
        setRowListFocus()  'only happens if m.top has focus, ie. when the app is launched or signin/signout
      end if

      'At this point, there is a limited set (as defined in constants) of content in each category.
      'loadCategories will get the rest of the content for each category.
      loadCategories(0)
    end if
  end if
End Function


' onRepopulateContent callback gets triggered when adding/removing any row
' it sets RowHeight and jumps the focus to a specified content.
Function onRepopulateContent()
  setRowHeights()
  ' setting the rowItemSize and/or rowHeights moves the focus indicator back to the origin so
  ' we need to move the focus back to it's appropriate place. But we need to check that there is content
  ' at the location or else the RowList loses focus and can't get it back.
  if resolveAbbreviatedContent(m.RowList.rowItemFocused) <> invalid
    ' re-focus the most recently focused content
    m.itemToJumpTo = m.RowList.rowItemFocused
  else if resolveAbbreviatedContent([m.RowList.rowItemFocused[0], 0]) <> invalid
    ' if there is no content at the most recently focused coordinates, then
    ' check if there is at least one content in the most recently focused row and focus the last content in the row
    rowIndex = m.RowList.rowItemFocused[0]
    lastContentIndex = m.top.content.getChild(rowIndex).getChildCount() - 1
    m.itemToJumpTo = [rowIndex, lastContentIndex]
  else
    ' if there is no content at the most recently focused coordinates, and
    ' there is no content in the most recently focused row, then
    ' check if there is any content in each row prior to the most recently focused row
    ' and focus the first content in that row
    rowIndex = 0
    if m.RowList.rowItemFocused[0] <> invalid
      rowIndex = m.RowList.rowItemFocused[0]
    end if

    while resolveAbbreviatedContent([rowIndex, 0]) = invalid and rowIndex >= 0
      rowIndex -= 1
    end while

    m.itemToJumpTo = [rowIndex, 0] ' m.itemToJumpTo might equal [-1, 0] in worst case scenario
  end if
End Function


Function setRowHeights()
  'determine the height of each row in the RowList so we can set it on RowList.rowItemSize
  rowItemSize = []
  rowHeights = []
  showRowLabel = []
  numRows = 2
  for i=0 to m.top.content.getChildCount()-1
    category = m.top.content.getChild(i)
    if category.gridItemType = m.constants.ui.gridItemTypes.utility
      rowItemSize.push([324,84])
      rowHeights.push(130)
      showRowLabel.push(false)
    else if category.gridItemType = m.constants.ui.gridItemTypes.portrait
      if getExperimentResource("roku2", "roku_safe_area").enabled = true
        posterWidth = m.constants.ui.imageSizes.poster[0]
        posterHeight = m.constants.ui.imageSizes.poster[1]
        rowHeightAdjustment = 64
      else
        posterWidth = 210
        posterHeight = 300
        rowHeightAdjustment = 64
      end if
      rowItemSize.push([posterWidth, posterHeight])
      rowHeights.push(posterHeight + rowHeightAdjustment)
      showRowLabel.push(true)
    else if category.gridItemType = m.constants.ui.gridItemTypes.landscape or category.gridItemType = m.constants.ui.gridItemTypes.vitg_small
      if getExperimentResource("roku2", "roku_safe_area").enabled = true
        posterWidth = m.constants.ui.imageSizes.landscape[0]
        posterHeight = m.constants.ui.imageSizes.landscape[1]
        rowHeightAdjustment = 115
      else
        posterWidth = 430
        posterHeight = 242
        rowHeightAdjustment = 122
      end if
      rowItemSize.push([posterWidth,posterHeight])
      rowHeights.push(posterHeight + rowHeightAdjustment)
      showRowLabel.push(true)
    else if category.gridItemType = m.constants.ui.gridItemTypes.vitg_large
      if getExperimentResource("roku2", "roku_safe_area").enabled = true
        posterWidth = m.constants.ui.imageSizes.largeVITG[0]
        posterHeight = m.constants.ui.imageSizes.largeVITG[1]
        rowHeightAdjustment = 85
      else
        posterWidth = 1205
        posterHeight = 677
        rowHeightAdjustment = 123
      end if
      rowItemSize.push([posterWidth,posterHeight])
      rowHeights.push(posterHeight + rowHeightAdjustment)
      showRowLabel.push(true)
      numRows = 3
    end if
  end for

  '//setting the height of the m.RowList.itemSize is superceded by the rowHeight of each row
  if getExperimentResource("roku2", "roku_safe_area").enabled = true
    m.RowList.itemSize = [1776,364]
  else
    m.RowList.itemSize = [1835,364]
  end if
  m.RowList.rowItemSize = rowItemSize
  m.RowList.rowHeights = rowHeights
  m.RowList.showRowLabel = showRowLabel
  m.RowList.content = m.top.content
  m.RowList.numRows = numRows
End Function

' animateToCategory doesn't cause rowItemFocused or itemFocused to be triggered unless
' the RowList has focus.  We capture this in order to load categories even when the
' RowList doesn't have focus.
Function onAnimateToCategory()
  tubiLog("CategoryGridList.onAnimateToCategory")
  m.AnimateToCategoryDebounce.control = "start"
End Function


Function onAnimateToCategoryDebounce()
  tubiLog("CategoryGridList.onAnimateToCategoryDebounce")
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
  tubiLog("CategoryGridList.loadCategories")
  if m.top.content = invalid or index < 0 then
    return
  end if

  requests = []
    'Determine the window start and window size for lazy loading
  windowInfo = getWindowInfo(index)
  if windowInfo <> invalid
    'Create requests for each category in the window
    for i = windowInfo.start to (windowInfo.start + windowInfo.size)-1
      category = m.top.content.getChild(i)
      if category <> invalid
        request = invalid
        if category.state = "partial" or category.state = "none"
          request = getWholeCategoryRequest(category, "")
          category.state = "loading"
        end if
        if request <> invalid then
          requests.push(request)
          category.state = "loading"
        end if
      end if
    end for
    
    if requests.count() > 0 then
      m.global.metadataFetchTask.batchRequest = m.metadataFetchTaskDTO.createBatchRequest(m.top, "metadataFetchTaskBatch", requests)
    end if
  end if
End Function


'Helper function to retrieve the starting index for the window to be loaded, as well as the number of categories in the window
'Returns an assocArray with the keys: "start", "size"
'@index: integer, the index of the category within the category grid
Function getWindowInfo(index)
  currentCategory = m.top.content.getChild(index)
  if currentCategory <> invalid
    currentWindowStart = (index \ m.categoryWindowSize) * m.categoryWindowSize
    windowSize = m.categoryWindowSize
    if currentCategory.state = "partial" or currentCategory.state = "none"
      windowStart = (index \ m.categoryWindowSize) * m.categoryWindowSize
      if (index + 1) MOD m.categoryWindowSize = 0
        ' if the user lands on an empty category that is also the last category in its window,
        ' add some more categories to the batch in order to fill the "next" category
        windowSize = m.categoryWindowSize + (m.categoryWindowSize \ 2)
      end if
    else
      ' attempt to load the current window, or next window depending on the index of the current category
      nextBatchIndex = (m.categoryWindowSize \ 2)
      windowStart = ((index + m.categoryWindowSize - (nextBatchIndex)) \ (m.categoryWindowSize)) * m.categoryWindowSize
    end if
    
    return {
      start: windowStart
      size: windowSize
    }
  end if
  return invalid
End Function

' Resolve and internal ContentNode that's been abbreviated for the CategoryGridList
' into a fully parsed TubiContentNode
'
' @rowItemIndex is 2D array of [rowindex, itemindex] from RowList.rowItemSelected or m.RowList.rowItemFocused
Function resolveAbbreviatedContent(rowItemIndex)
  tubiLog("CategoryGridList.resolveAbbreviatedContent")
  if m.top.content <> invalid and rowItemIndex[0] <> invalid and rowItemIndex[1] <> invalid
    contentId = invalid
    category = m.top.content.getChild(rowItemIndex[0])
    if category <> invalid
      content = category.getChild(rowItemIndex[1])
      if content <> invalid
        contentId = content.id
      end if
    end if
    if contentId <> invalid and contentId <> ""
      return m.metadataTranslate.getContentFromCategoryJson(category, contentId) ' can return invalid
    end if
  end if
  return invalid
End Function


''''''''''''''''
' onRowItemSelected - RowList.rowItemSelected event handler, triggered when user presses "OK"
Function onRowItemSelected()
  tubiLog("CategoryGridList.onRowItemSelected")
  category = m.top.content.getChild(m.RowList.rowItemSelected[0])
  if category <> invalid
    m.top.oldCategoryId = m.top.currCategoryId
    m.top.currCategoryId = category.id
  end if

  itemSelected = resolveAbbreviatedContent(m.RowList.rowItemSelected)
  if itemSelected <> invalid
    m.top.itemSelected = itemSelected
  end if
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
    category = m.top.content.getChild(m.RowList.rowItemFocused[0])
    if category <> invalid then
      category.focusIndex = m.RowList.rowItemFocused[1]
    end if
  end if
End Function


'''''''''''''''
' onRowListItemDebounce - RowList.rowItemFocus debounce handler
Function onRowListItemDebounce()
  tubiLog("CategoryGridList.onRowListItemDebounce")
  if m.top.content <> invalid
    category = m.top.content.getChild(m.RowList.rowItemFocused[0])

    if category <> invalid
      m.top.oldCategoryId = m.top.currCategoryId
      m.top.currCategoryId = category.id
    end if
  end if

  itemFocused = resolveAbbreviatedContent(m.RowList.rowItemFocused)
  if itemFocused <> invalid
    m.top.oldCursorPosition = m.top.cursorPosition
    m.top.cursorPosition = m.RowList.rowItemFocused
    m.top.oldItemFocused = m.top.itemFocused
    m.top.itemFocused = itemFocused
  end if
End Function


Function onMetadataFetchTaskBatchResponse(message) As Void
  tubiLog("CategoryGridList.onMetadataFetchTaskBatchResponse")

  responses = message.GetData()
  shouldInformHomeScreen = false
  removableCategories = {}
  if responses <> invalid
    batchMaxIndex = 0
    for each requestId in responses
      index = mergeMetadata(responses[requestId])
      if index = -1
        'we rely on the request id to be the same as the category id here
        'it works but is not best practice
        'categories with index = -1 means they have no content and should be removed
        removableCategories[requestId] = true
      else if index = 0
        ' index is 0 for the top most category in the homescreen grid. LimitedUI models do not start out with any
        ' content in their categories, and we must inform the homescreen that content has arrived so that it may
        ' populate the info panel
        shouldInformHomeScreen = true
      end if
      if index > batchMaxIndex
        batchMaxIndex = index
      end if
    end for

    if m.eagerLoad then
      loadCategories(batchMaxIndex+1)
    end if

    ' Delayed setting of Rowlist content until first batch arrives
    if m.RowList.content = invalid then
      m.RowList.content = m.top.content
    end if

    ' inform home screen of first content after content has been set on RowList
    if shouldInformHomeScreen = true
      ' set focus once we have content to focus on.
      ' will only affect limitedUI models as high spec models will set focus on m.RowList when m.top gains focus
      ' because their homescreen response contains content in it, but limiteUI models homescreen responses don't.
      setRowListFocus()   'only happens if m.top has focus, ie. when the app is launched or signin/signout
    end if

    ' free references to the batch so that it can be garbage collected
    m.top.metadataFetchTaskBatch = invalid
  end if

  counts = []
  if m.top.content <> invalid
    children = m.top.content.getChildren(m.top.content.getChildCount(), 0)
    for each child in children
      if removableCategories[child.id] = true
        counts.push(-1)
      else if child.totalCount <> invalid
        counts.push(child.totalCount)
      else
        counts.push(0)
      end if
    end for
  end if
  m.top.categoryTotalCounts = counts
End Function


Function mergeMetadata(fetched)
  ' TODO(Chris): handle this better.  if we set an error it should also be reset when the category is next fetched
  newContent = invalid
  response = fetched.response
  if response.code < 200 or response.code >= 300 then
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
  else if fetched.convertedMetadata <> invalid
    newContent = fetched.convertedMetadata  'this is a category node filled with content children
  else
    return -1
  end if
  

  tubiLog("Received response for request id " + fetched.id)
  index = -1
  categories = invalid
  if m.top.content <> invalid
    categories = m.top.content.getChildren(m.top.content.getChildCount(), 0)
  end if
  if categories <> invalid and newContent.id <> invalid
    for i=0 to categories.count()-1
      if categories[i].id = newContent.id then
        index = i
        exit for
      end if
    end for

    parentCategory = invalid
    if m.top.content <> invalid
      parentCategory = m.top.content.getChild(index)
    end if

    ' Check if a response arrives but the cache has been flushed and categories moved, such as adding or removing user categories
    if parentCategory = invalid then
      tubiLog("Ignoring response due to changed index " + fetched.id)
      return -1
    end if

    newContent.state = "loaded"

    'Add the existing preliminarily loaded contents to the newly received contents
    m.top.content.replaceChild(newContent, index)
    return index
  else
    return -1
  end if
End Function


'''''''''''''''''''''
' getWholeCategoryRequest
'
' Returns a request to get all the content for a category - used to refresh categories in their entirety
Function getWholeCategoryRequest(category As Object, field="wholeCategoryResponse" As String)
  if category <> invalid and type(category.id) = "roString"
    categoryId = category.id
    tubiLog("CategoryGridList.fetch whole " + categoryId)

    categoryId = getFullCategoryId(category)
    if categoryId <> invalid
      tubiLog("CategoryGridList.fetch whole: Asking MetadataFetchTask for " + categoryId)
       
      params = {
        contentMode: m.top.contentMode
      }

      if getExperimentResource("roku2", "roku_safe_area").enabled = true
        params.posterSize = m.constants.ui.imageSizes.poster
        params.landscapeSize = m.constants.ui.imageSizes.landscape
        params.largeVitgSize = m.constants.ui.imageSizes.largeVITG
      end if
      return m.metadataFetchTaskDTO.createRequest(categoryId, m.top, field, m.constants.reqNames.getCategory, invalid, m.top.shouldKidsModeBeSentToServer, params)
    end if
  end if

  return invalid
End Function


'''''''''''''''''''''
' getFullCategoryId
'
'
' Helper function to build category ids for nested categories that matrix API can recognize
' @category: sgNode, a CateogorContentNode
' if a nested category returns an id in the form of 'parentCat/sub/childCat'
' if not a nested category, returns the categoryId
' if there is no categoryId, returns invalid
Function getFullCategoryId(category)
  categoryId = invalid
  if type(category) = "roSGNode" and category.id <> ""
    categoryId = category.id
    if category.parentId <> invalid and category.parentId <> ""
      categoryId = category.parentId + "/sub/" + category.id
      ' categoryId = categoryId.encodeUriComponent()
    end if
  end if
  return categoryId
End Function


' Sets focus on the rowlist, but only if the m.top has focus.
' This function is called when content has been loaded on the RowList and the RowList is ready to accept focus.
' In some cases where side nav or other components have focus, we don't want to set focus on the RowList however.
' Setting focus on RowList triggers an update to itemFocused which Homescreen.brs listens to in order to update
' the info panel. In the case that we do not want set focus on the RowList, we still need to let Homescreen.brs that
' that content has loaded so it can update the infoPanel.
Function setRowListFocus()
  if m.top.hasFocus()
    m.justGainedFocus = true
    m.RowList.setFocus(true)
  else
    topLeftIndex = [0, 0]
    m.top.reloadedItemToBeFocused = resolveAbbreviatedContent(topLeftIndex)
  end if
End Function
