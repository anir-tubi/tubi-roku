Function init()
  tubiLog("CategoryGridList.init")
  m.constants = getConstantsFromGlobal()

  m.top.observeFieldScoped("categoryResponseInBatch", "onCategoryResponseInBatch")
  m.top.observeFieldScoped("focusedChild", "onComponentFocusChange")
  m.top.observeFieldScoped("jumpToRowItemByID", "onJumpToRowItemByIDChange")
  m.top.observeFieldScoped("contentUpdated", "onContentChange")
  m.top.observeFieldScoped("purpleCarpetContentUpdated", "onPurpleCarpetContentUpdatedChange")
  m.top.observeFieldScoped("repopulateContent", "onRepopulateContent")
  m.top.observeFieldScoped("animateToCategory", "onAnimateToCategory")
  m.top.observeFieldScoped("removeFocusFromRowList", "onRemoveFocusFromRowList")
  m.top.observeFieldScoped("signedIn", "onSignedInChange")
  m.RowList = m.top.findNode("RowList")
  m.RowList.observeFieldScoped("rowItemFocused", "onRowItemFocused")
  m.RowList.observeFieldScoped("rowItemSelected", "onRowItemSelected")

  ' Parameters for the metadata block cache. Window size is number of items to fetch, page delimiter
  ' is what focus thresholds trigger a fetch.
  m.initialBlockSize = m.constants.performance.categoryGridList.initialBlockSize
  m.finalBlockSize = m.constants.performance.categoryGridList.finalBlockSize
  m.eagerLoad = m.constants.performance.categoryGridList.eagerLoad

  ' If eager loading, we don't need to listen for row changes
  if not m.eagerLoad
    m.RowList.observeFieldScoped("itemFocused", "onItemFocused")
  end if

  experimentsInfo = getExperimentsInfoFromGlobal()
  experiments = TubiExperiments(experimentsInfo)
  m.metadataTranslate = TubiMetadataTranslate(m.constants, experiments)

  m.RowList.drawFocusFeedbackOnTop = true

  ' stores an array of the form [y, x], which can be set on RowList.jumpToItem
  m.itemToJumpTo = invalid

  m.LinearProgramRefreshTimer = m.top.findNode("LinearProgramRefreshTimer")
  m.LinearProgramRefreshTimer.observeFieldScoped("fire", "onLinearProgramRefreshTimer")

  m.skinAdRow = m.top.findNode("skinAdRow")
  m.skinAdRow.observeFieldScoped("rowItemSelected", "onSkinAdRowItemSelected")
  m.skinAdRow.observeFieldScoped("rowItemFocused", "onSkinAdRowItemFocused")

  m.purpleCarpetRow = m.top.findNode("purpleCarpetRow")
  m.purpleCarpetRow.observeFieldScoped("rowItemSelected", "onPurpleCarpetRowItemSelected")
  m.purpleCarpetRow.observeFieldScoped("rowItemFocused", "onPurpleCarpetRowItemFocused")
  m.purpleCarpetRow.observeFieldScoped("primaryEventContent", "onReloadedItemToBeFocused")
  
  m.originalTranslationPurpleCarpetRow = m.purpleCarpetRow.translation
  m.originalTranslationSkinAdRow = m.skinAdRow.translation

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()

  ' Holds the value of last focused list, possible values are "", "skinAdRow" "rowlist", "purpleCarpetRow".
  ' These IDs match with the IDs of the components in the XML. 
  m.lastFocusedList = ""
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.RowList.focusBitmapBlendColor = theme.focusedColor
  end if
End Function


Function onRemoveFocusFromRowList()
  m.RowList.setFocus(false)
End Function


Function onJumpToRowItemByIDChange()
  tubiLog("CategoryGridList.onJumpToRowItemByIDChange")
  sDesiredContainerID = ""
  sContentID = ""
  if m.top.jumpToRowItemByID <> invalid
    sContentID = m.top.jumpToRowItemByID[0]
    sDesiredContainerID = m.top.jumpToRowItemByID[1]
  end if

  '//Loop thru the containers to find the content item with an ID that matches sContentID and focus on that content item
  for i=0 to m.RowList.content.getChildCount()-1
    container = m.RowList.content.getChild(i)
    sTempContainerID = container.id
    if sDesiredContainerID = sTempContainerID or sDesiredContainerID = ""
      for j=0 to container.getChildCount()-1
        item = container.getChild(j)
        if item.id = sContentID
          'focus on the item
          m.RowList.jumpToRowItem = [i,j]
          return true
        end if
      end for
    end if
  end for
  return false
End Function


'''''''''''''''''''''''''
' onComponentFocusChange
'
Function onComponentFocusChange()
  tubiLog("CategoryGridList.onComponentFocusChange " + focusState(m.top))
  content = m.top.content
  itemToJumpTo = invalid
  if m.itemToJumpTo <> invalid AND resolveAbbreviatedContent(content, m.itemToJumpTo) <> invalid then
    itemToJumpTo = m.itemToJumpTo
  end if
  m.itemToJumpTo = invalid

  ' If top has focus then we need to focus the RowList itself
  if m.top.hasFocus() = true then
    if (isSkinAdsAvailable() = true) AND (m.lastFocusedList = "skinAdRow" OR m.lastFocusedList = "")
      m.lastFocusedList = "skinAdRow"
      m.purpleCarpetRow.opacity = 0
      m.skinAdRow.opacity = 1
      m.skinAdRow.setFocus(true)
    else if isPurpleCarpetContainerEmpty() = false AND m.lastFocusedList <> "rowlist"
      m.lastFocusedList = "purpleCarpetRow"
      m.purpleCarpetRow.opacity = 1
      m.skinAdRow.opacity = 0
      m.purpleCarpetRow.setFocus(true)
      ' We are cloning so that itemfocused gets fired when user focuses back on the same item.
      ' Ex: User focusing on purple carpet and moves focus to sidenav and then back to purple carpet.
      m.top.itemFocused = m.top.primaryEventContent.clone(true)
    else if isPurpleCarpetContainerEmpty() = false AND m.top.resetGridPosition = true
      ' Below logic is executed when user switches between kids mode and regular mode.
      ' Due to the fact that kids mode does not have purple carpet we need to reset focus back to purple carpet container from rowlist.
      setFocusToPurpleCarpetContainer()

      m.top.resetGridPosition = false
    else
      ' Don't want to do any of this logic if we are already have an item we are going to jump to
      if itemToJumpTo = invalid then
        rowItemFocused = m.RowList.rowItemFocused
        if rowItemFocused.count() = 2 AND resolveAbbreviatedContent(content, rowItemFocused) <> invalid then
          '// If count does not equal 2 then the rowList has not gained focus yet so use the default first item in the else block
          itemToJumpTo = rowItemFocused
        else
          itemToJumpTo = [0, 0]
        end if
      end if

      if resolveAbbreviatedContent(content, itemToJumpTo) <> invalid
        m.lastFocusedList = "rowlist"
        m.RowList.setFocus(true)

        ' Adding to check to make sure if reset grid position was requested.
        ' Making sure we are resetting after focus is set to rowlist.
        if m.top.resetGridPosition = true
          itemToJumpTo = [0, 0]
          m.top.resetGridPosition = false
        end if
      end if

      m.LinearProgramRefreshTimer.control = "start"
      ' When Grid get focus refresh all visible channels
      onLinearProgramRefreshTimer()
    end if
  else if m.top.isInFocusChain() = false
    m.LinearProgramRefreshTimer.control = "stop"
  end if

  ' We used to only jump to if m.top had focus. In some cases we would not jump back to the correct item after we modified the RowList content which triggers a jump to the first position usually. Now if we have a m.itemToJumpTo we will always jump to it when we receive a focus change event
  if itemToJumpTo <> invalid then
    m.RowList.jumpToRowItem = itemToJumpTo
  end if
End Function


Function onContentChange()
  tubiLog("CategoryGridList.onContentChange")

  bSetRowListFocus = false
  '//RESET position of 1st-row elements
  m.skinAdRow.translation = m.originalTranslationSkinAdRow
  m.purpleCarpetRow.translation = m.originalTranslationPurpleCarpetRow
  
  ' set the translation position of the page based on presense or absence of any 1st rows. 
  ' DO this BEFORE setting the content of the rowList (later in this function) or else the translation will not be properly set.
  if isPurpleCarpetContainerEmpty() = false OR isSkinAdsAvailable() = true
    m.rowList.translation = [0, 384]

    if isSkinAdsAvailable() = true
      m.skinAdRow.opacity = 1
      m.lastFocusedList = "skinAdRow"
      category = m.top.skinAdContent.getChild(0)
      if category <> invalid
        content = category.getChild(0)
        m.top.reloadedItemToBeFocused = content
      end if
    else if isPurpleCarpetContainerEmpty() = false
      m.lastFocusedList = "purpleCarpetRow"
      slideFade(m.purpleCarpetRow, "below", "in", 0.3)
      m.top.reloadedItemToBeFocused = m.top.primaryEventContent
    end if
  else    
    ' Resetting the state of the UI.
    ' Below logic will be used in case of there is no purple carpet on initial load.
    ' Also covers the case where user switches between different home screen modes or to kids mode in which purple carept container gets removed.
    m.rowList.translation = [0, 0]
    m.purpleCarpetRow.opacity = 0
    m.skinAdRow.opacity = 0
    bSetRowListFocus = true
  end if

  if m.top.content = invalid
    m.RowList.content = invalid
    '//reset some values. According to the Roku documentation, these fields should be read only but they seem to be writable.
    if m.RowList.currFocusColumn <> invalid
      m.RowList.currFocusColumn = 0
    end if
    m.RowList.rowItemFocused = [0,0]
    m.RowList.currFocusRow = 0
  ' This is a verbose check that makes sure we only refresh the whole RowList content if the root node is different
  else
    ' Setting RowList invalid here will empty the grid.  It will be set after the first batch of
    ' metadata is received.  Setting RowList.content with a few full categories will cause it to prefetch
    ' posters and do a nice fade-in.
    m.RowList.content = invalid
    if m.top.content <> invalid then
      setRowHeights()

      'At this point, there is a limited set (as defined in constants) of content in each category.
      'loadCategoriesIndex will get the rest of the content for each category.
      m.top.loadCategoriesIndex = 0
      if bSetRowListFocus = true
        setRowListFocus()
      end if
    end if
  end if

  m.top.gridContentIsReady = true
End Function


' onRepopulateContent callback gets triggered when adding/removing any row
' it sets RowHeight and jumps the focus to a specified content.
Function onRepopulateContent()
  setRowHeights()

  rowItemFocused = m.RowList.rowItemFocused
  if m.itemToJumpTo <> invalid
    rowItemFocused = m.itemToJumpTo
  end if

  if rowItemFocused = invalid
    rowItemFocused = [0,0]
  end if

  rowAdded = m.top.rowAdded
  rowRemoved = m.top.rowRemoved

  ' Resetting rowAdded & rowRemoved
  m.top.rowAdded = ""
  m.top.rowRemoved = ""

  ' setting the rowItemSize and/or rowHeights moves the focus indicator back to the origin so
  ' we need to move the focus back to it's appropriate place. But we need to check that there is content
  ' at the location or else the RowList loses focus and can't get it back.
  if resolveAbbreviatedContent(m.top.content, rowItemFocused) <> invalid
    ' re-focus the most recently focused content
    m.itemToJumpTo = rowItemFocused
  else if resolveAbbreviatedContent(m.top.content, [rowItemFocused[0], 0]) <> invalid
    ' if there is no content at the most recently focused coordinates, then
    ' check if there is at least one content in the most recently focused row and focus the last content in the row
    rowIndex = 0
    if rowItemFocused[0] <> invalid
      rowIndex = rowItemFocused[0]
    end if

    lastContentIndex = m.top.content.getChild(rowIndex).getChildCount() - 1
    m.itemToJumpTo = [rowIndex, lastContentIndex]
  else
    ' if there is no content at the most recently focused coordinates, and
    ' there is no content in the most recently focused row, then
    ' check if there is any content in each row prior to the most recently focused row
    ' and focus the first content in that row
    rowIndex = 0
    if rowItemFocused[0] <> invalid
      rowIndex = rowItemFocused[0]
    end if

    while resolveAbbreviatedContent(m.top.content, [rowIndex, 0]) = invalid AND rowIndex >= 0
      rowIndex -= 1
    end while

    m.itemToJumpTo = [rowIndex, 0] ' m.itemToJumpTo might equal [-1, 0] in worst case scenario
  end if

  ' there are 4 options here
  ' 1) new continue_watching row got inserted, so increment the focus index by 1
  ' 2) new queue row got inserted, so increment the focus index by 1
  ' 3) continue_watching row got removed, so decrement the focus index by 1
  ' 4) queue row got removed, so decrement the focus index by 1
  if m.Rowlist <> invalid AND m.Rowlist.content <> invalid AND rowItemFocused[0] <> invalid
    if rowAdded = m.constants.ui.categoryIds.history
      if rowItemFocused[0] >= m.RowList.content.continueWatchingIndex
        m.itemToJumpTo = [m.itemToJumpTo[0] + 1, m.itemToJumpTo[1]]
      end if
    else if rowAdded = m.constants.ui.categoryIds.queue
      if rowItemFocused[0] >= m.RowList.content.queueIndex
        m.itemToJumpTo = [m.itemToJumpTo[0] + 1, m.itemToJumpTo[1]]
      end if
    else if rowRemoved = m.constants.ui.categoryIds.history
      if rowItemFocused[0] >= m.RowList.content.continueWatchingIndex
        m.itemToJumpTo = [m.itemToJumpTo[0] - 1, m.itemToJumpTo[1]]
      end if
    else if rowRemoved = m.constants.ui.categoryIds.queue
      if rowItemFocused[0] >= m.RowList.content.queueIndex
        m.itemToJumpTo = [m.itemToJumpTo[0] - 1, m.itemToJumpTo[1]]
      end if
    end if
  end if
End Function


Function setRowHeights()
  'determine the height of each row in the RowList so we can set it on RowList.rowItemSize
  rowItemSize = []
  rowHeights = []
  rowItemSpacings = []
  focusXOffsets = []
  numRows = 2
  posterSize = m.constants.ui.imageSizes.largePoster
  landscapeSize = m.constants.ui.imageSizes.largeLandscape
  showRowLabel = []

  for i=0 to m.top.content.getChildCount()-1
    category = m.top.content.getChild(i)
    rowHeight = 0
    rowHeightAdjustment = 57 '//The height of the row container heading and its vertical spacing
    gridItemType = category.gridItemType
    gridItemTypes = m.constants.ui.gridItemTypes

    if gridItemType = gridItemTypes.historySignedOutUser
      posterHeight = posterSize[1]
      rowItemSize.push([1693, posterHeight])
      rowHeight = posterHeight
      rowItemSpacings.push([15, 0])
      focusXOffsets.push(0)
    else if gridItemType = gridItemTypes.banner
      bannerSize = m.constants.ui.imageSizes.banner
      rowItemSize.push(bannerSize)
      rowHeight = bannerSize[1]
      rowItemSpacings.push([10, 0])
      focusXOffsets.push(0)
    else if gridItemType = gridItemTypes.portrait
      posterWidth = posterSize[0]
      posterHeight = posterSize[1]
      rowItemSize.push([posterWidth, posterHeight])
      rowHeight = posterHeight
      rowItemSpacings.push([15, 0])
      focusXOffsets.push(0)
    else if gridItemType = gridItemTypes.portraitTopTen
      posterWidth = posterSize[0]
      posterHeight = posterSize[1]
      rowItemSize.push([posterWidth, posterHeight])
      rowHeight = posterHeight
      rowItemSpacings.push([243, 0])
      'push the focus indicator to the right so it doesn't cover the top ten label
      focusXOffsets.push(243)
    else if gridItemType = gridItemTypes.landscape OR gridItemType = gridItemTypes.landscapeNoTitle OR gridItemType = gridItemTypes.linear
      posterWidth = landscapeSize[0]
      posterHeight = landscapeSize[1]
      if gridItemType = gridItemTypes.landscape then
        rowHeightAdjustment = rowHeightAdjustment + 21
      end if
      rowItemSize.push([posterWidth, posterHeight])
      rowHeight = posterHeight
      rowItemSpacings.push([15, 0])
      focusXOffsets.push(0)
    end if

    if gridItemType = gridItemTypes.banner
      showRowLabel.push(false)
      ' Just adding the spacing and not the row header component height.
      rowHeightAdjustment = 18
    else
      showRowLabel.push(true)
    end if

    if category.sponsorImages <> invalid
      '//if this is a sponsored row, then adjust the spacing so row includes the header size of the sponsored row
      rowHeightAdjustment = rowHeightAdjustment + 32
    end if
    rowHeights.push(rowHeight + rowHeightAdjustment)
  end for

  '//setting the height of the m.RowList.itemSize is superceded by the rowHeight of each row
  '//However, just in case the height of a row is not defined, then it will default to the height defined by itemSize
  itemSize = [1752, posterSize[1]]
  m.Rowlist.update({
    "itemSize" : itemSize
    "rowItemSize": rowItemSize
    "rowHeights": rowHeights
    "showRowLabel": showRowLabel
    "numRows": numRows
    "rowItemSpacing": rowItemSpacings
    "focusXOffset" : focusXOffsets
  })
  m.RowList.content = m.top.content
End Function

' animateToCategory doesn't cause rowItemFocused or itemFocused to be triggered unless
' the RowList has focus.  We capture this in order to load categories even when the
' RowList doesn't have focus.
Function onAnimateToCategory()
  tubiLog("CategoryGridList.onAnimateToCategory")

  m.top.loadCategoriesIndex = m.top.animateToCategory
End Function


'''''''''''''''''''''
' onItemFocused
'
' The RowList has changed to a new category row
Function onItemFocused()
  tubiLog("CategoryGridList.onItemFocused")
  m.top.loadCategoriesIndex = m.RowList.itemFocused
End Function


' Resolve and internal ContentNode that's been abbreviated for the CategoryGridList
' into a fully parsed TubiContentNode
'
' @content rowlist content node.
' @rowItemIndex is 2D array of [rowindex, itemindex] from RowList.rowItemSelected or m.RowList.rowItemFocused
Function resolveAbbreviatedContent(content, rowItemIndex)
  if content <> invalid AND rowItemIndex[0] <> invalid AND rowItemIndex[1] <> invalid
    contentId = invalid
    category = content.getChild(rowItemIndex[0])
    if category <> invalid
      content = category.getChild(rowItemIndex[1])
      if content <> invalid
        contentId = content.id
      end if
    end if

    if isNonEmptyString(contentId) = true
      ' Making sure we add back the airdatetime and foxContentId to the content node since we are fetching updated data from css category json which will not have data added dynamically from listing api.
      originalAirDateTime = content.airDateTime
      foxContentId = content.foxContentId
      singleContent = m.metadataTranslate.getContentFromCategoryJson(category, contentId, m.top.signedIn) ' can return invalid
      
      if singleContent <> invalid AND content.gridItemType = m.constants.ui.gridItemTypes.purpleCarpet
        singleContent.update({
          airDateTime: originalAirDateTime
          foxContentId: foxContentId
        }, true)
      end if

      return singleContent
    end if
  end if

  return invalid
End Function


''''''''''''''''
' onRowItemSelected - RowList.rowItemSelected event handler, triggered when user presses "OK"
Function onRowItemSelected(msg)
  tubiLog("CategoryGridList.onRowItemSelected")
  if m.top.content <> invalid 'should not be necessary but crash reports show that it is.
    ' If we have purple carpet content than we need to increment y position by 1 since purple carpet is the first row.
    rowItemSelected = msg.getData()
    if isPurpleCarpetContainerEmpty() = false
      m.top.selectedPosition = [rowItemSelected[0] + 1, rowItemSelected[1]]
    else
      m.top.selectedPosition = rowItemSelected
    end if
    
    category = m.top.content.getChild(rowItemSelected[0])
    if category <> invalid
      m.top.oldCategoryId = m.top.currCategoryId
      m.top.currCategoryId = category.id
    end if
    itemSelected = resolveAbbreviatedContent(m.top.content, rowItemSelected)
    if itemSelected <> invalid
      m.top.itemSelected = itemSelected
    end if
  end if
End Function


'''''''''''''''
' onRowItemFocused - RowList.rowItemFocused event handler.
Function onRowItemFocused(msg)
  tubiLog("CategoryGridList.onRowItemFocused")

  rowItemFocused = msg.getData()
  m.top.focusedPosition = rowItemFocused
  if m.top.content <> invalid AND rowItemFocused <> invalid
    category = m.top.content.getChild(rowItemFocused[0])
    if category <> invalid then
      category.focusIndex = rowItemFocused[1]
      m.top.oldCategoryId = m.top.currCategoryId
      m.top.currCategoryId = category.id

      itemFocused = resolveAbbreviatedContent(m.top.content, rowItemFocused)
      if itemFocused <> invalid
        m.top.oldCursorPosition = m.top.cursorPosition
        m.top.cursorPosition = rowItemFocused
        m.top.oldItemFocused = m.top.itemFocused
        m.top.rowFocused = m.top.content.getChild(rowItemFocused[0])
        m.top.itemFocused = itemFocused
      end if
    end if

    if m.firstTimeLinearProgramEnabled = false
      m.firstTimeLinearProgramEnabled = true
      getExperimentResource("roku_sports_onnow_rows", "roku_sports_onnow_rows_v2", true)
    end if
  end if
End Function


Function onCategoryResponseInBatch(msg) As Void
  tubiLog("CategoryGridList.categoryResponseInBatch")

  response = msg.getData()
  shouldInformHomeScreen = false
  removableCategories = {}

  if response <> invalid
    batchMaxIndex = 0

    ' the function mergeMetadata (which is called in the subsequent for loop) calls
    ' node.replaceChild() which will reparent the node being looped over, thereby reducing
    ' the number of children nodes in the parent node as the looping is happening.
    ' In order to work around this, we need to iterate backwards over a set of child node containers/categories.
    ' But we also want to iterate in the order in which the containers are displayed on the screen,
    ' so we need to reverse the order of the nodes before iterating over them,
    ' such that when iterating from end to beginning, the order is the same as
    ' iterating from beginning to end without pre-reversing the nodes.
    subtype = response.subtype()
    reverseOrder = CreateObject("roSGNode", subtype)

    for i = response.getChildCount() - 1 to 0 step -1
      ' note: reparenting is quicker than appending
      response.getChild(i).reparent(reverseOrder, false)
    end for


    for i = reverseOrder.getChildCount() - 1 to 0 step -1
      content = reverseOrder.getChild(i)

      if content <> invalid
        categoryId = content.ID
        index = mergeMetadata(content)

        if index = -1
          'categories with index = -1 means they have no content and should be removed
          removableCategories[categoryId] = true
        else if index = 0
          ' index is 0 for the top most category in the homescreen grid. LimitedUI models do not start out with any
          ' content in their categories, and we must inform the homescreen that content has arrived so that it may
          ' populate the info panel
          shouldInformHomeScreen = true
        end if

        if index > batchMaxIndex
          batchMaxIndex = index
        end if

      end if
    end for

    if m.eagerLoad then
      m.top.loadCategoriesIndex = batchMaxIndex + 1
    end if

    if m.top.content <> invalid
      if removableCategories.count() > 0
        for i = m.top.content.getChildCount() - 1 to 0 step -1
          child = m.top.content.getChild(i)
          if removableCategories[child.id] = true
            m.top.content.removeChildIndex(i)
          end if
        end for
        setRowHeights()
      end if
    end if

    ' Delayed setting of Rowlist content until first batch arrives
    if m.RowList.content = invalid then
      m.RowList.content = m.top.content
    end if

    ' inform home screen of first content after content has been set on RowList
    ' Only proceed if we do not have purple carpet content. Since this triggers info panel update for the first row of non purple carpet content.
    if shouldInformHomeScreen = true AND isPurpleCarpetContainerEmpty() = true AND m.skinAdRow.content = invalid 
      ' set focus once we have content to focus on.
      ' will only affect limitedUI models as high spec models will set focus on m.RowList when m.top gains focus
      ' because their homescreen response contains content in it, but limitedUI models homescreen responses don't.
      setRowListFocus()   'only happens if m.top has focus, ie. when the app is launched or signin/signout
    end if

    ' free references to the batch so that it can be garbage collected
    m.top.categoryResponseInBatch = invalid
  end if
End Function


Function mergeMetadata(fetchedContent)
  tubiLog("Merging metadata for categoryId: " + fetchedContent.id)
  index = -1

  categories = invalid
  if m.top.content <> invalid
    categories = m.top.content.getChildren(m.top.content.getChildCount(), 0)
  end if

  if categories <> invalid AND fetchedContent <> invalid AND fetchedContent.id <> invalid
    for i=0 to categories.count()-1
      if categories[i].id = fetchedContent.id then
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
      tubiLog("Ignoring response due to changed index " + fetchedContent.id)
      return -1
    end if

    fetchedContent.state = "loaded"

    'Add the existing preliminarily loaded contents to the newly received contents
    m.top.content.replaceChild(fetchedContent, index)
    return index
  else
    return -1
  end if
End Function


' Sets focus on the rowlist, but only if the m.top has focus.
' This function is called when content has been loaded on the RowList and the RowList is ready to accept focus.
' In some cases where side nav or other components have focus, we don't want to set focus on the RowList however.
' Setting focus on RowList triggers an update to itemFocused which Homescreen.brs listens to in order to update
' the info panel. In the case that we do not want set focus on the RowList, we still need to let Homescreen.brs that
' that content has loaded so it can update the infoPanel.
Function setRowListFocus()
  tubiLog("CategoryGridList.setRowListFocus")
  if m.top.hasFocus() = true
    m.lastFocusedList = "rowlist"
    m.RowList.setFocus(true)
  else
    if m.RowList.currFocusRow <> invalid AND m.RowList.currFocusRow >= 0 AND m.RowList.currFocusColumn <> invalid AND m.RowList.currFocusColumn >= 0
      '//If rowList is not in focus and new content is set, then one would think that rowItemFocused should be [0,0] but it isn't,
      '//so that is why we use currFocusRow and currFocusColumn - to ensure the proper item is announced
      row = Int(m.RowList.currFocusRow)
      col = Int(m.RowList.currFocusColumn)
      reloadedItemIndex = [row, col]
    else if isNonEmptyArray(m.RowList.rowItemFocused) = true AND m.RowList.rowItemFocused[0] >= 0 AND m.RowList.rowItemFocused[1] >= 0
      '//currFocusColumn is not available in firmware lower than Roku OS 10.5, so use rowItemFocused. It's imperfect, as it
      '// may think a different item is focused instead of the 1st colum/1st row,
      '// but it will not display a wrong metadata when the user quickly navigates away from 1st rowItem [0,0] as the content is loading
      reloadedItemIndex = m.RowList.rowItemFocused
    else
      reloadedItemIndex = [0, 0]
    end if
    m.top.rowFocused = m.RowList.content.getChild(reloadedItemIndex[0])
    m.top.reloadedItemToBeFocused = resolveAbbreviatedContent(m.top.content, reloadedItemIndex)
  end if
End Function


Function onLinearProgramRefreshTimer()

  if m.global <> invalid AND m.global.refreshLinearChannels <> invalid
    ' force trigger linear channel refresh by changing the global field.
    m.global.refreshLinearChannels = not m.global.refreshLinearChannels
  end if

End Function


Function onSkinAdRowItemSelected(msg)
  content = m.top.skinAdContent
  rowItemSelected = msg.getData()

  if content <> invalid 
    m.top.oldCategoryId = m.top.currCategoryId
    m.top.currCategoryId = "skinAdRow"
    m.top.selectedPosition = rowItemSelected
    m.top.itemSelected = content.clone(true)
  end if
End Function


Function onSkinAdRowItemFocused(msg)
  tubiLog("CategoryGridList.onSkinAdRowItemFocused")
  rowItemFocused = msg.getData()
  content = m.top.skinAdContent

  'fire exposure event when skinAd row gains focus
  getExperimentResource("ads_tubi_skins", "ads_tubi_skin_mufasa", true)

  if content <> invalid    
    category = content.getChild(rowItemFocused[0])
    
    if category <> invalid then
      category.focusIndex = rowItemFocused[1]
      m.top.oldCategoryId = m.top.currCategoryId
      m.top.currCategoryId = category.id
      content = category.getChild(rowItemFocused[1])

      if content <> invalid then
        m.top.oldCursorPosition = m.top.cursorPosition
        m.top.cursorPosition = rowItemFocused
        m.top.oldItemFocused = m.top.itemFocused
        m.top.rowFocused = category
        m.top.itemFocused = content.clone(true)
        m.top.focusedPosition = rowItemFocused
      end if
    end if
end if
End Function


Function onReloadedItemToBeFocused(msg)
  tubiLog("CategoryGridList.onReloadedItemToBeFocused")
  ' Not creating an alias to avoid it becoming bi-directional field into the skinAd, and purple carpet row.
  ' Since we refresh the purple carpet container on every home screen reload.
  ' Due to the fact that purple carpet container is not aware what was previously focused we will avoid overriding the previously 
  ' focused info panel if it was not purple carpet. Below logic should only get triggered for initial load and when backing out to home screen if the user navigated from purple carpet, skinAd row.
  itemToBeFocused = msg.getData()
  triggeredRowId = msg.getNode()

  if itemToBeFocused <> invalid AND m.lastFocusedList = triggeredRowId
    m.top.reloadedItemToBeFocused = itemToBeFocused
  end if
End Function


Function onPurpleCarpetRowItemFocused()
  tubiLog("CategoryGridList.onPurpleCarpetRowItemFocused")
  rowItemFocused = m.purpleCarpetRow.rowItemFocused
  listContent = m.purpleCarpetRow.listContent
  if listContent <> invalid
    category = listContent.getChild(0)
    itemFocused = resolveAbbreviatedContent(listContent, rowItemFocused)
    if category <> invalid AND itemFocused <> invalid
      m.top.oldCategoryId = m.top.currCategoryId
      m.top.currCategoryId = m.constants.ui.categoryIds.purpleCarpet
      m.top.oldCursorPosition = m.top.cursorPosition
      m.top.cursorPosition = rowItemFocused
      m.top.oldItemFocused = m.top.itemFocused
      m.top.rowFocused = category
      m.top.itemFocused = itemFocused
      m.top.focusedPosition = rowItemFocused
    end if
  end if
End Function


Function onPurpleCarpetRowItemSelected(msg)
  if m.top.itemFocused <> invalid
    m.top.itemSelected = m.top.itemFocused
  end if
End Function


Function onSignedInChange(msg)
  ' We cannot use alias because for boolean and few other core data types roku does not allow alias to fields from different components.
  isSignedIn = msg.getData()
  m.purpleCarpetRow.signedIn = isSignedIn
End Function


Function isPurpleCarpetContainerEmpty()
  purpleCarpetContent = m.top.purpleCarpetContent

  if isNode(purpleCarpetContent) = true
    child = purpleCarpetContent.getChild(0)

    if child <> invalid AND child.getChildCount() > 0
      return false
    end if
  end if

  return true
End Function


Function isSkinAdsAvailable()
  return (m.top.skinAdContent <> invalid AND m.top.skinAdContent.getChildCount() > 0)
End Function


Function onPurpleCarpetContentUpdatedChange()
  tubiLog("CategoryGridList.onPurpleCarpetContentUpdatedChange")
  ' Handling a use case where last focused list was purple carpet container but during refresh all items got removed due to event reaching end resetting the focus to rowlist.
  ' Checking to check to make sure the rowlist has content before setting focus to it.
  if isPurpleCarpetContainerEmpty() = true AND m.lastFocusedList = "purpleCarpetRow" AND isNode(m.top.content) = true

    m.rowList.translation = [0, 0]
    m.purpleCarpetRow.opacity = 0
    m.lastFocusedList = "rowlist"
    m.RowList.setFocus(true)
  else if m.constants.deviceInfo.limitedUi = true AND isPurpleCarpetContainerEmpty() = false AND m.RowList.rowItemFocused[1] = -1
    ' Adding a condition to be executed in case of limited ui since initial request will always not have content returned.
    ' This logic will only get executed for the initial load and not on refresh.
    ' m.RowList.rowItemFocused[1] will be -1 before the rowlist gets focused.
    m.rowList.translation = [0, 384]
    m.lastFocusedList = "purpleCarpetRow"
    m.purpleCarpetRow.opacity = 1
    
    m.top.itemFocused = m.top.primaryEventContent
    m.purpleCarpetRow.setFocus(true)
  end if
End Function


Function setFocusToPurpleCarpetContainer()
  ' updating the itemFocused which in turn triggers onGridFocusChange inside homescreen.brs.
  ' Which causes the regular info panel to be hidden and the background to be updated to full screen version.
  ' The reason for calling this manually is because purple carept has cta button list and rowlist.
  ' Since we need to update the info panel even when ctaButtonList we need to force call it here.
  m.top.itemFocused = m.top.primaryEventContent

  m.purpleCarpetRow.setFocus(true)
  if m.purpleCarpetRow.opacity < 1
    slideFade(m.purpleCarpetRow, "below", "in", 0.3)
  end if
  m.lastFocusedList = "purpleCarpetRow"
  m.purpleCarpetRow.isContainerVisible = true
  slideTo(m.RowList, [0, 384], 0.3)
End Function


Function onKeyEvent(key as String, press as Boolean) as Boolean
  if press = true
    bSkinAdAvailable = (isSkinAdsAvailable() = true)

    if key = "down" AND m.skinAdRow.isInFocusChain() = true
      slideFade(m.skinAdRow, "above", "out", 0.3)
      if isPurpleCarpetContainerEmpty() = false
        m.top.itemFocused = m.top.primaryEventContent
        m.purpleCarpetRow.setFocus(true)
        slideFade(m.purpleCarpetRow, "below", "in", 0.3)
        m.lastFocusedList = "purpleCarpetRow"
        m.purpleCarpetRow.isContainerVisible = true
      else
        m.RowList.setFocus(true)
        slideTo(m.RowList, [0, 0], 0.3)
        m.lastFocusedList = "rowlist"
      end if
      return true
    else if key = "down" AND m.RowList.isInFocusChain() = false
      if m.purpleCarpetRow.isInFocusChain() = true
        m.purpleCarpetRow.isContainerVisible = false
        slideFade(m.purpleCarpetRow, "above", "out", 0.3)
      end if
      slideTo(m.RowList, [0, 0], 0.3)
      m.lastFocusedList = "rowlist"
      m.RowList.setFocus(true)
      return true
    else if key = "up" AND m.RowList.isInFocusChain() = true
      if isPurpleCarpetContainerEmpty() = false
        setFocusToPurpleCarpetContainer()
        return true
      else if bSkinAdAvailable = true
        slideFade(m.skinAdRow, "below", "in", 0.3)
        m.lastFocusedList = "skinAdRow"
        m.skinAdRow.setFocus(true)
        slideTo(m.RowList, [0, 384], 0.3)
        return true
      end if
    else if key = "up" AND bSkinAdAvailable = true
      slideFade(m.skinAdRow, "above", "in", 0.3)
      m.lastFocusedList = "skinAdRow"
      m.skinAdRow.setFocus(true)
      return true
    else if key = "up" AND m.purpleCarpetRow.isInFocusChain() = true AND bSkinAdAvailable = true
      slideFade(m.skinAdRow, "above", "in", 0.3)
      m.lastFocusedList = "skinAdRow"
      m.skinAdRow.setFocus(true)
      slideFade(m.purpleCarpetRow, "below", "out", 0.3)
      return true
    end if
  end if
  return false
End Function
