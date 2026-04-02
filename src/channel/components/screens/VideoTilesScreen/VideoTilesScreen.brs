' Video Tiles Screen
' Provides common functionality for screens that support video tiles
'
' USAGE:
' ============================================================================
' To enable video tiles support for your screen:
'
' 1. Extend VideoTilesScreen instead of BaseScreen in your XML:
'    <component name="YourScreen" extends="VideoTilesScreen">
'
' 2. In your screen's init() function, call:
'    initVideoTilesScreen(m.ContentArea, m.RowList, m.InfoPanel)
'
' 3. In ContentController helpers (e.g., YourScreenHelpers.brs), call:
'    setupVideoTilesObservers(screen)
'    This sets up observers for video tile focus and scrolling events.
'    Call this after creating the screen and before pushing it to the stack.
'
' All required fields are automatically inherited from VideoTilesScreen.
'
' The screen sets up sub-observers to sync RowList.currFocusRow and RowList.scrollingStatus
' to the screen's listCurrFocusRow and listScrollingStatus fields automatically.
' ============================================================================


' Initializes video tiles support for a screen
' Sets up required member variables and field observers
' @param contentAreaNode - The content area node (MaskGroup or Group)
' @param rowListNode - The row list node
' @param infoPanelNode - The info panel node (optional, can be invalid)
Function initVideoTilesScreen(contentAreaNode, rowListNode, infoPanelNode = invalid) as Void
  m.constants = getConstantsFromGlobal()
  constants = m.constants
  m.nodeHelpers = TubiNodeHelpers()

  m.contentAreaNode = contentAreaNode
  m.originalContentAreaTranslation = m.contentAreaNode.translation

  ' Store row list reference
  m.rowListNode = rowListNode

  ' Store original row focus animation style
  m.originalRowFocusAnimationStyle = rowListNode.rowFocusAnimationStyle

  ' Store original translations
  m.currentContentAreaTranslation = m.originalContentAreaTranslation
  m.videoTilesListTranslation = constants.ui.videoTilesListTranslation

  ' Store info panel reference
  m.infoPanelNode = infoPanelNode

  ' Initialize video tiles support variables
  m.featuredRowPoster = constants.ui.imageSizes.featuredRowPoster
  m.gridItemSize = constants.ui.imageSizes.videoTilesPortrait
  m.expandedTileFocusXOffset = m.featuredRowPoster[0] - m.gridItemSize[0] + 4
  m.lastCurrentFocusColumn = 0
  m.lastFocusColumnIndex = 0
  m.lastFocusRow = 0
  m.ignoreCurrColumnChange = false
  m.ignoreRowColumnChange = false

  ' Set up row list observers for video tiles
  rowListNode.observeFieldScoped("currFocusColumn", "onRowCurrFocusColumnChange")
  rowListNode.observeFieldScoped("currFocusRow", "onListCurrFocusRowChange")
  rowListNode.observeFieldScoped("rowItemFocused", "onRowItemFocusedChange")
  rowListNode.observeFieldScoped("vertFocusDirection", "onVertFocusDirectionChange")
  rowListNode.observeFieldScoped("translation", "onRowListTranslationChange")
  rowListNode.observeFieldScoped("scrollingStatus", "onRowListScrollingStatusChange")

  ' Set up sub-observers to sync RowList fields to screen fields (for external access)
  rowListNode.observeFieldScoped("currFocusRow", "syncListCurrFocusRow")
  rowListNode.observeFieldScoped("scrollingStatus", "syncListScrollingStatus")

  ' Set up top-level observer for enableVideoTiles
  m.top.observeFieldScoped("enableVideoTiles", "onEnableVideoTilesChange")
  m.top.observeFieldScoped("focusedChild", "onScreenFocusChange")
  m.top.observeFieldScoped("rowCurrFocusColumn", "onRowCurrFocusColumnUpdate")
  m.top.observeFieldScoped("expiredContainerIds", "onExpiredContainerIds")
  m.top.observeFieldScoped("listingRefreshData", "onListingRefreshData")

  ' Initialize rowListTranslation and field syncs immediately
  updateRowListTranslation(rowListNode.translation)
  m.top.listCurrFocusRow = rowListNode.currFocusRow
  m.top.listScrollingStatus = rowListNode.scrollingStatus
End Function


' Handles screen focus changes and triggers content/container refresh when needed
Function onScreenFocusChange() as Void
  if m.top.hasFocus() = true
    contentRefreshed = checkContentRefresh()
    if contentRefreshed = false
      checkContainerRefresh()
    end if
    m.rowListNode.setFocus(true)
  end if
  m.top.listHasFocus = m.rowListNode.isInFocusChain()
End Function


' Checks if top-level content has expired and fires refreshContent signal
' @return Boolean - true if content refresh was triggered
Function checkContentRefresh() as Boolean
  if m.top.enableContentRefresh = true AND m.top.content <> invalid AND shouldRefresh(m.top.content)
    m.top.refreshContent = true
    return true
  end if
  return false
End Function


' Checks individual containers for expiration and fires expiredContainerIds signal
Function checkContainerRefresh() as Void
  if m.top.enableContainerRefresh <> true OR m.top.content = invalid then return

  expiredIds = []
  containers = m.top.content.getChildren(-1, 0)
  for each container in containers
    if shouldRefresh(container) = true
      expiredIds.push(container.id)
    end if
  end for
  if expiredIds.count() > 0
    m.top.expiredContainerIds = expiredIds
  end if
End Function


' Fetches expired containers via batch request
' Requires m.cmsApi to be initialized by the child screen
' @param msg - Message containing array of expired container IDs
Function onExpiredContainerIds(msg) as Void
  containerIds = msg.getData()
  if isNonEmptyArray(containerIds) = false OR m.cmsApi = invalid then return

  batchRequests = m.cmsApi.createBatchReqInfoForContainers({
    containerIds: containerIds
    bKidsMode: m.top.isKidsMode
    isSignedInUser: m.top.isSignedInUser
    uiMode: m.top.uiMode
    screenId: m.top.id
    appId: m.top.containerRefreshAppId
  })
  if batchRequests <> invalid AND batchRequests.count() > 0
    makeBatchNetworkRequest({
      requests: batchRequests
      responseType: "node"
      successCallback: onContainerRefreshSuccess
    })
  end if
End Function


' Handles successful container refresh batch response
' Replaces expired containers in the existing content tree
' @param response - Batch response node containing refreshed container data
Function onContainerRefreshSuccess(response) as Void
  if response = invalid OR m.top.content = invalid then return

  refreshedContainers = response.getChildren(-1, 0)
  existingContainers = m.top.content.getChildren(-1, 0)

  for each refreshedContainer in refreshedContainers
    if refreshedContainer = invalid then continue for

    for j = 0 to existingContainers.count() - 1
      existingContainer = existingContainers[j]
      if existingContainer <> invalid AND existingContainer.id = refreshedContainer.id
        m.top.content.replaceChild(refreshedContainer, j)
        exit for
      end if
    end for
  end for
End Function


' Observer callback for listingRefreshData field — delegates to BaseScreen's processListingRefreshData
' @param msg - Message containing AA keyed by scheduleId with listing data from the EPG API
Function onListingRefreshData(msg) as Void
  processListingRefreshData(msg.getData())
End Function


' Handles enable video tiles field changes
' Updates mask URI and content area positioning based on video tiles state
Function onEnableVideoTilesChange() as Void
  if m.top.enableVideoTiles = true
    m.maskUri = ""
    if m.infoPanelNode <> invalid
      m.infoPanelNode.visible = false
    end if
    m.contentAreaNode.translation = m.videoTilesListTranslation
    ' Change to fixedFocus for video tiles
    if m.rowListNode <> invalid
      m.rowListNode.rowFocusAnimationStyle = "fixedFocus"
    end if
  else
    m.maskUri = "pkg:/images/poster-mask.png"
    if m.infoPanelNode <> invalid
      m.infoPanelNode.visible = true
    end if
    m.contentAreaNode.translation = m.originalContentAreaTranslation
    ' Restore original row focus animation style
    if m.rowListNode <> invalid
      m.rowListNode.rowFocusAnimationStyle = m.originalRowFocusAnimationStyle
    end if
  end if
  m.contentAreaNode.maskUri = m.maskUri

  ' Update rowListTranslation to reflect new ContentArea position
  if m.rowListNode <> invalid
    updateRowListTranslation(m.rowListNode.translation)
  end if
End Function


' Updates the rowListTranslation field
' Adjusts translation based on content area position (similar to HomeScreen)
' @param translation - The RowList translation array
Function updateRowListTranslation(translation) as Void
  if translation <> invalid AND m.contentAreaNode <> invalid
    ' Adjust translation by adding content area translation Y offset
    translation[1] = translation[1] + m.contentAreaNode.translation[1]
    m.top.rowListTranslation = translation
  end if
End Function


' Handles row list translation changes
' Delegates to updateRowListTranslation helper
Function onRowListTranslationChange(msg) as Void
  updateRowListTranslation(msg.getData())
End Function


' Handles row list scrolling status changes
' Updates the listScrollingStatus field for video tiles animations
Function onRowListScrollingStatusChange(msg) as Void
  scrollingStatus = msg.getData()
  m.top.listScrollingStatus = scrollingStatus
End Function


' Observer that handles vertical focus direction field changes
' Tracks scroll direction (up/down) for list navigation
' @param msg - Message containing direction ("up", "down", or "none")
Function onVertFocusDirectionChange(msg) as Void
  direction = msg.getData()
  ' Since the direction gets reset during the flow.
  ' The value of m.scrollDirection gets reset to none after the value changes to up or down during scrolling.
  ' This is the reason we are maintaining our own directional scope variable.
  if direction <> "none"
    m.top.listScrollDirection = direction
  end if
End Function


' Handles current focus row changes in the row list
' Updates focus X offset and bounding rect, manages column focus index
' @param msg - Message containing new current focus row
Function onListCurrFocusRowChange(msg) as Void
  if m.top.enableVideoTiles = false then return

  rowListNode = msg.getRoSGNode()
  currFocusRow = 0
  rowContent = m.top.content
  if isNode(rowContent) = true
    rowItemFocused = rowListNode.rowItemFocused
    if isNonEmptyArray(rowItemFocused) = true
      currFocusRow = rowItemFocused[0]
    end if

    nextFocusRow = 0
    if m.top.listScrollDirection = "down"
      nextFocusRow = currFocusRow + 1
    else if currFocusRow > 0
      nextFocusRow = currFocusRow - 1
    end if
    updateFocusXOffset(rowListNode, nextFocusRow)

    updateCurrentFocusedItemBoundingRect(rowListNode)

    category = rowContent.getChild(nextFocusRow)
    if category <> invalid AND isNumber(category.focusIndex) = true AND category.focusIndex > 0
      m.lastFocusColumnIndex = category.focusIndex
    else
      m.lastFocusColumnIndex = 0
    end if
  end if
End Function


' Updates focus X offset for video tile expansion effect
' @param currFocusRow - Current focused row index
Function updateFocusXOffset(rowListNode, currFocusRow, currFocusColumn = -1) as Void
  if m.top.enableVideoTiles = false then return

  rowContent = rowListNode.content
  focusXOffsets = rowListNode.focusXOffset
  isComponentInFocusChain = m.top.isInFocusChain() = true
  if isNode(rowContent) = true AND isNonEmptyArray(focusXOffsets) = true
    focusXOffset = []
    for i = 0 to rowContent.getChildCount() - 1
      category = rowContent.getChild(i)
      gridItemType = category.gridItemType
      if i = currFocusRow AND isVideoTileEnabledContainer(gridItemType) = true AND isComponentInFocusChain = true
        columnIndex = currFocusColumn
        if columnIndex < 0 then columnIndex = category.focusIndex
        if columnIndex = invalid OR columnIndex < 0 then columnIndex = 0
        focusedItem = m.nodeHelpers.getNodeFromPosition(rowContent, [i, columnIndex])
        if focusedItem <> invalid AND arrayIncludes(m.constants.ui.nonVideoTileGridItemTypes, focusedItem.gridItemType) = true
          focusXOffset.push(0)
        else
          focusXOffset.push(m.expandedTileFocusXOffset)
        end if
      else
        focusXOffset.push(0)
      end if
    end for
    ' To Avoid unnecessary updates to the focusXOffset field, doing a simple array comparison.
    if FormatJson(focusXOffset) <> FormatJson(rowListNode.focusXOffset)
      m.ignoreCurrColumnChange = true
      m.lastFocusColumnIndex = currFocusColumn
      rowListNode.focusXOffset = focusXOffset
      m.ignoreCurrColumnChange = false
    end if
  end if
End Function


' Updates bounding rectangles for current and next focused items
' Used for UI animations and positioning based on focus state
' @param rowListNode - The row list node
Function updateCurrentFocusedItemBoundingRect(rowListNode) as Void
  if m.top.enableVideoTiles = false then return

  rowItemFocused = rowListNode.rowItemFocused
  rowContent = m.top.content
  if isNonEmptyArray(rowItemFocused) = true AND isNode(rowContent) = true
    currFocusRow = rowItemFocused[0]

    ' Will be used to avoid updating the in transit bounding rect when the user scroll is about to end and the rowItemFocused gets updated.
    ' This avoids the slight flicker of the next in transit from appearing for a split second.
    diff = Abs(currFocusRow - m.lastFocusRow)
    ' Since we are trying to update the bounding rect as the user scrolls we cannot use any of the row list fields to figure out the next row.
    ' Based on the scroll direction we are updating the next focus row.
    nextFocusRow = 1
    if m.top.listScrollDirection = "down"
      nextFocusRow = currFocusRow + 1
    else if currFocusRow > 0
      nextFocusRow = currFocusRow - 1
    end if

    ' Updating the bounding rect for the next focus row.
    category = rowContent.getChild(nextFocusRow)
    if category <> invalid AND category.focusIndex <> invalid AND diff <= 0
      columnFocused = category.focusIndex
      if columnFocused < 0
        columnFocused = 0
      end if
      nextBoundingRect = rowListNode.subBoundingRect("item" + nextFocusRow.toStr() + "_" + columnFocused.toStr())
      m.top.inTransitCurrentFocusedItemBoundingRect = nextBoundingRect
    end if

    ' Updating the bounding rect for the current focus row.
    columnFocused = rowItemFocused[1]
    boundingRect = rowListNode.subBoundingRect("item" + currFocusRow.toStr() + "_" + columnFocused.toStr())
    m.top.currentFocusedItemBoundingRect = boundingRect

    m.lastFocusRow = currFocusRow
  end if
End Function


' Observer that handles row column focus changes
' Manages scroll direction tracking and updates rowCurrFocusColumn field
' @param msg - Message object containing the new focus column
Function onRowCurrFocusColumnChange(msg) as Void
  if m.top.enableVideoTiles = false then return

  ' ignoreCurrColumnChange is set to true when the user is scrolling through the columns of the row.
  ' Updating the focusXOffset field triggers currFocusColumnChange twice one for the row which we are removing the offset and one for which we are adding the offset.
  ' This optimizes the performance when unnecessary updates been triggered.
  if m.ignoreCurrColumnChange = false
    currentFocusColumn = msg.getData()
    absCurCol = Int(currentFocusColumn)
    ' To account for fast scrolling.
    diff = Abs(absCurCol - m.lastFocusColumnIndex)

    ' Ignoring all updates when user is fast scrolling through the columns of the row.
    ' When the user stops the scrolling we will process the column change.
    if currentFocusColumn <> absCurCol AND diff <= 1
      ' If the current focus column is greater than the last current focus column, then we are scrolling right.
      ' If the current focus column is less than the last current focus column, then we are scrolling left.
      if currentFocusColumn > m.lastCurrentFocusColumn
        rowCurrFocusColumn = m.lastFocusColumnIndex + 1
        m.top.listScrollDirection = "right"
      else
        rowCurrFocusColumn = m.lastFocusColumnIndex - 1
        m.top.listScrollDirection = "left"
      end if
      m.top.rowCurrFocusColumn = rowCurrFocusColumn
    else
      m.lastFocusColumnIndex = absCurCol
      if m.lastFocusColumnIndex <> m.top.rowCurrFocusColumn
        m.top.rowCurrFocusColumn = m.lastFocusColumnIndex
      end if
    end if

    m.lastCurrentFocusColumn = currentFocusColumn
  end if
End Function


' Persists the focused column index on the category content node
' Fires on every focus change (row or column), keeping focusIndex
' in sync for bounding rect and focus offset calculations
' @param msg - Message containing [rowIndex, columnIndex]
Function onRowItemFocusedChange(msg) as Void
  rowItemFocused = msg.getData()
  rowContent = m.top.content
  if isNonEmptyArray(rowItemFocused) = true AND isNode(rowContent) = true
    category = rowContent.getChild(rowItemFocused[0])
    if category <> invalid
      category.focusIndex = rowItemFocused[1]
      updateFocusXOffset(m.rowListNode, rowItemFocused[0])
    end if
  end if
End Function


' Checks if a container type supports video tiles
' Returns true for video tile grid item type
' @param gridItemType - The grid item type to check
' @return Boolean - True if video tiles are enabled for this container
Function isVideoTileEnabledContainer(gridItemType) as Boolean
  return arrayIncludes(m.constants.ui.nonVideoTileGridItemTypes, gridItemType) = false AND gridItemType = m.constants.ui.gridItemTypes.videoTile
End Function


' Helper function to call from onRowItemFocused when video tiles are enabled
' Updates focus X offset and bounding rect
' @param rowListNode - The row list node
' @param rowIndex - Current focused row index
Function updateFocusForItem(rowListNode, rowIndex) as Void
  if m.top.enableVideoTiles = false then return

  updateCurrentFocusedItemBoundingRect(rowListNode)
  updateFocusXOffset(rowListNode, rowIndex)
End Function


' Helper function to set up row heights for video tiles
' Call this from setRowHeights() in the screen
' @param rowListNode - The row list node
' @param rowItemSize - Array of row item sizes
' @param rowHeights - Array of row heights
' @param content - Content node
' @param variableWidthItems - Array of booleans indicating which rows have variable-width items (e.g. hub lockup)
Function configureRowHeights(rowListNode, rowItemSize, rowHeights, content, variableWidthItems = []) as Void
  rowListNode.update({
    "itemSize": [1920, m.gridItemSize[1]]
    "rowItemSize": rowItemSize
    "rowHeights": rowHeights
    "showRowLabel": [true]
    "variableWidthItems": variableWidthItems
  }, true)

  ' Set initial focus offset for video tiles if enabled
  if m.top.enableVideoTiles = true AND content <> invalid
    container = content.getChild(0)
    if container <> invalid AND isVideoTileEnabledContainer(container.gridItemType) = true
      rowListNode.focusXOffset = [m.expandedTileFocusXOffset, 0]
    else
      rowListNode.focusXOffset = [0, 0]
    end if
  end if

  rowListNode.content = content
  rowListNode.drawFocusFeedback = (m.top.enableVideoTiles = false)
End Function


' Helper function to get video tile row height
' Call this when calculating row heights for video tile containers
' @param sponsorImages - Sponsor images from category (or invalid)
' @return Integer - The calculated row height for video tiles
Function getVideoTileRowHeight(sponsorImages = invalid) as Integer
  metadataSectionHeight = 240
  featuredRowHeight = m.featuredRowPoster[1] + metadataSectionHeight

  if sponsorImages <> invalid
    featuredRowHeight = featuredRowHeight + 32
  end if

  return featuredRowHeight
End Function


' Syncs RowList.currFocusRow to screen's listCurrFocusRow field
' This allows external components (like helpers) to observe the current focus row
Function syncListCurrFocusRow() as Void
  if m.rowListNode <> invalid
    m.top.listCurrFocusRow = m.rowListNode.currFocusRow
  end if
End Function


' Syncs RowList.scrollingStatus to screen's listScrollingStatus field
' This allows external components (like helpers) to observe scrolling status
Function syncListScrollingStatus() as Void
  if m.rowListNode <> invalid
    m.top.listScrollingStatus = m.rowListNode.scrollingStatus
  end if
End Function


' Gets the content node from a RowList position
' @param rowItemIndex - 2D array of [rowIndex, itemIndex] from RowList.rowItemFocused or RowList.rowItemSelected
' @return ContentNode - The content node at the specified position, or invalid
Function getContentNodeFromRowItem(rowItemIndex) as Dynamic
  content = invalid
  if m.top.content <> invalid AND rowItemIndex[0] <> invalid AND rowItemIndex[1] <> invalid
    category = m.top.content.getChild(rowItemIndex[0])
    if category <> invalid
      content = category.getChild(rowItemIndex[1])
    end if
  end if

  return content
End Function


' Gets a fully parsed TubiContentNode from a RowList position
' Uses metadataTranslate to get full content details from category JSON
' @param rowItemIndex - 2D array of [rowIndex, itemIndex] from RowList.rowItemFocused or RowList.rowItemSelected
' @param metadataTranslate - TubiMetadataTranslate instance for parsing content (optional)
' @param isSignedIn - Whether the user is signed in (optional, default: false)
' @return ContentNode - Fully parsed TubiContentNode, or invalid
Function getTubiContentNodeFromRowItem(rowItemIndex, metadataTranslate = invalid, isSignedIn = false) as Dynamic
  content = getContentNodeFromRowItem(rowItemIndex)

  if content = invalid then return invalid

  gridItemType = content.gridItemType
  ' This is needed hack to account for items appending client side.
  isNonResolvableGridItem = arrayIncludes(m.constants.ui.nonVideoTileGridItemTypes, gridItemType) = true AND arrayIncludes(m.constants.ui.liveEventsGridTypes, gridItemType) = false

  if isNonResolvableGridItem = true then return content

  if content <> invalid AND isNonEmptyString(content.id) AND metadataTranslate <> invalid
    category = m.top.content.getChild(rowItemIndex[0])
    if category <> invalid
      contentId = content.id
      contentFromJSON = metadataTranslate.getContentFromCategoryJson(category, contentId, isSignedIn)
      return contentFromJSON
    end if
  end if

  return invalid
End Function


' Recalculates focus X offset when the focused column changes within a row
Function onRowCurrFocusColumnUpdate(msg) as Void
  rowItemFocused = m.rowListNode.rowItemFocused
  if rowItemFocused <> invalid AND m.ignoreRowColumnChange = false
    columnFocused = msg.getData()
    if columnFocused < 0 then columnFocused = 0
    updateFocusXOffset(m.rowListNode, rowItemFocused[0], columnFocused)
  else
    m.ignoreRowColumnChange = false
  end if
End Function
