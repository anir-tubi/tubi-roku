Function init()
  tubiLog("MyStuffScreen.init")
  m.constants = getConstantsFromGlobal()
  Request = TubiRequest(m.constants.settings)
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)
  m.ContentArea = m.top.findNode("ContentArea")
  m.ScreenTitle = m.top.findNode("ScreenTitle")
  m.SignedOutUI = m.top.findNode("SignedOutUI")
  m.SignedOutUITitle = m.top.findNode("SignedOutUITitle")
  m.SignedOutUISubtitle = m.top.findNode("SignedOutUISubtitle")
  m.SignedOutUIBlurb = m.top.findNode("SignedOutUIBlurb")
  m.ScreenTitle.text = getTranslation("screenMyStuff_title")
  m.SignedOutUITitle.text = getTranslation("screenMyStuff_signedOutUITitle")
  m.SignedOutUISubtitle.text = getTranslation("screenMyStuff_signedOutUISubtitle")
  m.SignedOutUIBlurb.text = getTranslation("screenMyStuff_signedOutUIBlurb")
  m.top.screenLevel = m.constants.ui.screenLevels.myStuffScreen
  m.top.id = m.constants.ui.screenIds.myStuffScreen

  m.top.handlesTransportVoiceRequests = true

  m.oldCursorPosition = [-1,-1]
  m.top.cursorPosition = [-1,-1]
  m.oldCategoryId = ""
  m.currCategoryId = ""

  'used to know when to send tracking info. Do not send focus tracking info when the rowlist is 1st loaded
  m.gridHasGainedInitialFocus = false

  m.defaultBackgroundUri = m.constants.ui.uris.defaultBackground

  m.metadataTranslate = TubiMetadataTranslate(m.constants)

  BackLabel = m.top.findNode("callToAction")
  BackLabel.text = getTranslation("goBack_menu")
  if m.constants.deviceInfo.uiResolution <> "FHD"
    '//if the display is not 1080, then adjust the BackLabel to ensure proper vertical alignment
    BackLabel.translation = [BackLabel.translation[0], BackLabel.translation[1] + 3]
  end if

  'Content area
  m.RowList = m.top.findNode("RowList")
  m.GuestMenu = m.top.findNode("GuestMenu")
  m.GuestMenu.focusBitmapUri = "pkg:/images/menu-focus-fhd.9.png"
  m.RowList.focusBitmapUri = "pkg:/images/selector-fhd.9.png"
  m.GuestMenu.focusFootprintBitmapUri = "pkg:/images/menu-disabled-focus-fhd.9.png"
  if m.constants.deviceInfo.scaledUi = true
    m.GuestMenu.focusBitmapUri = "pkg:/images/menu-focus-hd.9.png"
    m.GuestMenu.focusFootprintBitmapUri = "pkg:/images/menu-disabled-focus-hd.9.png"
    m.RowList.focusBitmapUri = "pkg:/images/selector-hd.9.png"
  end if

  defaultGuestMenuWidth = m.GuestMenu.itemSize[0]
  signInOutButton = m.top.findNode("SignInOutButton")
  signInOutButton.title = getTranslation("menu_signIn")
  
  ' Adjust the width of the guest menu if text of the button is too long for the default width. Mostly spanish text are generally longer in length.
  tempChannelMenuItem = CreateObject("roSGNode", "DetailMenuItem")
  tempChannelMenuItem.itemContent = signInOutButton

  potentialWidth = tempChannelMenuItem.calculatedTextWidth + tempChannelMenuItem.leftTextPadding + tempChannelMenuItem.rightTextPadding
  if potentialWidth > defaultGuestMenuWidth AND potentialWidth > m.GuestMenu.itemSize[0]
    m.GuestMenu.itemSize = [potentialWidth, m.GuestMenu.itemSize[1]]
  end if

  m.RowList.observeFieldScoped("rowItemFocused", "onRowItemFocused")
  m.RowList.observeFieldScoped("rowItemSelected", "onRowItemSelected")
  m.GuestMenu.observeFieldScoped("itemSelected", "onMenuItemSelected")

  m.top.observeFieldScoped("focusedChild", "onScreenFocusChange")
  m.top.observeFieldScoped("isLoading", "onLoadingChange")
  m.top.observeFieldScoped("contentUpdated", "onContentUpdateChange")
  m.top.observeFieldScoped("transportVoiceRequest", "onTransportVoiceRequest")
  m.top.observeFieldScoped("signedIn", "onSignedInChange")
  m.top.observeFieldScoped("jumpToRowItemByIdAndIndex", "onJumpToRowItemChange")
  m.top.observeFieldScoped("reset", "onResetChange")
  
  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if
  
  if theme <> invalid
    m.SignedOutUITitle.color = theme.primaryTextColor
    m.ScreenTitle.color = theme.primaryTextColor
    m.SignedOutUISubtitle.color = theme.secondaryTextColor
    m.SignedOutUIBlurb.color = theme.focusedColor
    m.GuestMenu.focusBitmapBlendColor = theme.focusedColor
    m.RowList.focusBitmapBlendColor = theme.focusedColor
  end if
End Function


Function onScreenFocusChange()
  if m.top.hasFocus() = true
    if m.top.signedIn = false
      m.GuestMenu.setFocus(true)
    else if m.top.content <> invalid
      if m.top.content.getChildCount() > 0
        oldFcousedRowItem = m.top.cursorPosition
        m.RowList.setFocus(true)
        if oldFcousedRowItem <> invalid
          '//when regaining focus, focus on previous item instead of [0,0]
          m.RowList.jumpToRowItem = oldFcousedRowItem
        end if
      end if

      if m.RowList.content <> invalid AND shouldRefresh(m.RowList.content) = true  'cacheValidationMixin
        m.top.refreshContent = true
      end if
    end if

    m.top.backgroundUriList = [m.defaultBackgroundUri]  
  end if
End Function


Function onLoadingChange(msg)
  tubiLog("MyStuffScreen.onLoadingChange")
  isNotLoading = (msg.getData() = false)
  m.RowList.visible = isNotLoading
  if isNotLoading = false
    m.RowList.content = invalid   'When not fully loaded, then the rowlist should not show any content
  end if
End Function


Function onContentUpdateChange(msg) As Void
  tubiLog("MyStuffScreen.onContentUpdateChange") 
  content = m.top.content
  if content <> invalid
    ' Delayed setting of Rowlist content until first batch arrives
    setRowHeights()

    if content.getChildCount() > 0 AND m.top.hasFocus() = true
      m.RowList.setFocus(true) 
    end if
  else
    m.RowList.content = invalid
    m.RowList.visible = false
  end if
End Function


Function setRowHeights()
  'determine the height of each row in the RowList so we can set it on RowList.rowItemSize
  rowItemSize = []
  rowHeights = []
  aRowLabelVisible = []
  for i=0 to m.top.content.getChildCount()-1
    bShowRowLabel = true
    category = m.top.content.getChild(i)
    rowHeight = 0
    rowHeightAdjustment = 0
    gridItemType = category.gridItemType
    gridItemTypes = m.constants.ui.gridItemTypes
    if gridItemType = gridItemTypes.emptyContainer
      rowItemSize.push(m.constants.ui.imageSizes.emptyContainer)
      rowHeight = m.constants.ui.imageSizes.emptyContainer[1]
      bShowRowLabel = false
    else if gridItemType = gridItemTypes.portrait
      posterWidth = m.constants.ui.imageSizes.poster[0]
      posterHeight = m.constants.ui.imageSizes.poster[1]
      rowHeightAdjustment = 80
      rowItemSize.push([posterWidth, posterHeight])
      rowHeight = posterHeight
    else if gridItemType = gridItemTypes.landscapeLarge
      posterWidth = m.constants.ui.imageSizes.landscapeLarge[0]
      posterHeight = m.constants.ui.imageSizes.landscapeLarge[1]
      rowHeightAdjustment = 50
      rowItemSize.push([posterWidth, posterHeight])
      rowHeight = posterHeight
    end if
    aRowLabelVisible.push(bShowRowLabel)
    rowHeights.push(rowHeight + rowHeightAdjustment)
  end for

  '//setting the height of the m.RowList.itemSize is superceded by the rowHeight of each row
  itemSize = [1752, 364]
  m.Rowlist.update({
    "itemSize" : itemSize
    "rowItemSize": rowItemSize
    "rowHeights": rowHeights
    "showRowLabel": aRowLabelVisible
  })
  m.RowList.content = m.top.content
End Function


Function onRowItemFocused(msg) as Boolean
  if m.RowList.content <> invalid
    tubiLog("MyStuffScreen.onRowItemFocused")
    newCursorPosition = msg.getData()

    '//if the screen is loading or if the grid is not in focus or the topnav is not in focus, then exit out of this function
    if m.RowList.isInFocusChain() <> true OR m.top.isLoading = true
      return true
    end if

    '//Update the position values
    m.oldCursorPosition = m.top.cursorPosition
    m.top.cursorPosition = newCursorPosition
    oldFocusedContent = m.top.contentFocused
    m.top.contentFocused = getAbbreviatedContent(newCursorPosition)

    category = m.RowList.content.getChild(newCursorPosition[0])
    if category <> invalid
      m.oldCategoryId = m.currCategoryId
      m.currCategoryId = category.id

      ' immediately update the position counter
      category.focusIndex = newCursorPosition[1]
    end if

    'Set up the navigateWithinPageInfo to send to ContentController.
    oldAnalyticsRow = m.oldCursorPosition[0] + 1
    oldAnalyticsCol = m.oldCursorPosition[1] + 1
    newAnalyticsRow = newCursorPosition[0] + 1
    newAnalyticsCol = newCursorPosition[1] + 1

    if m.gridHasGainedInitialFocus = true AND oldAnalyticsRow > 0 AND oldAnalyticsCol > 0
      if oldAnalyticsRow <> newAnalyticsRow OR oldAnalyticsCol <> newAnalyticsCol

        categoryComponentInfo = {}
        categoryComponentInfo["category_slug"] = m.oldCategoryId
        categoryComponentInfo["category_row"] = oldAnalyticsRow
        'row is hardcoded to 1 in the line below because the row represents the row within the category_component, not within the grid
        'and the current design only has one row per category
        tile = m.Tracking.getAnalyticsTile(oldFocusedContent, oldAnalyticsCol, 1)
        categoryComponentInfo["content_tile"] = tile
        m.top.navigateWithinPageInfo = {
          pageOneof: m.Tracking.getAnalyticsPage(m.top.trackingPageInfo.pageType, m.top.trackingPageInfo.pageValues)
          componentOneof: m.Tracking.getAnalyticsComponent("category_component", categoryComponentInfo)
          means_of_navigation: "BUTTON" 'MeansOfNavigation enum
          vertical_location: newAnalyticsRow
          vertical_location_mode: "INDEX" 'LocationMode enum
          horizontal_location: newAnalyticsCol
          horizontal_location_mode: "INDEX" 'LocationMode enum
        }

      end if
    end if
    m.gridHasGainedInitialFocus = true
  end if

  return true
End Function


Function onRowItemSelected(msg)
  tubiLog("MyStuffScreen.onRowItemSelected")
  selectedPosition = msg.getData()
  handleItemSelected(selectedPosition)
End Function
  

Function onMenuItemSelected(msg)
  tubiLog("MyStuffScreen.onMenuItemSelected")
  '//communicate that the user is asking to start the sign in process
  m.top.signUpButtonSelected = true
End Function


Function handleItemSelected(selectedPosition)
  tubiLog("MyStuffScreen.handleItemSelected")
  if m.top.content <> invalid
    itemSelected = resolveAbbreviatedContent(selectedPosition)
    
    m.top.trackingComponentInfo = getTrackingComponentInfoOfRowList(itemSelected, selectedPosition)

    if itemSelected <> invalid
      m.top.contentSelected = itemSelected
    end if
  end if
End Function


' @gridItem: roSGNode, TubiContentNode with metadata for an item in the grid
' @itemPosition: array, 2d array with [x,y] grid coordinate information
Function getTrackingComponentInfoOfRowList(gridItem, itemPosition)
  trackingComponentInfo = {}
  if gridItem <> invalid AND itemPosition <> invalid AND itemPosition.Count() = 2
    componentValues = {}
    componentValues["category_slug"] = m.currCategoryId
    componentValues["category_row"] = itemPosition[0] + 1 'all analytics are 1 based
    tile = m.Tracking.getAnalyticsTile(gridItem, itemPosition[1] + 1)
    componentValues["content_tile"] = tile

    ' Set the tracking component of the gridItem that was passed so it can be accessed as part of the navigateToPage event
    trackingComponentInfo = {
      componentType: "category_component"
      componentValues: componentValues
    }
  end if

  return trackingComponentInfo
End Function



' Get the abbreviated version of the TubiContentNode for the RowList associated with the passed rowItemIndex
'
' @rowItemIndex is 2D array of [rowindex, itemindex] from RowList.rowItemSelected or m.RowList.rowItemFocused
Function getAbbreviatedContent(rowItemIndex)
  tubiLog("MyStuffScreen.getAbbreviatedContent")
  content = invalid
  if m.top.content <> invalid AND rowItemIndex[0] <> invalid AND rowItemIndex[1] <> invalid
    category = m.top.content.getChild(rowItemIndex[0])
    if category <> invalid
      content = category.getChild(rowItemIndex[1])
    end if
  end if

  return content
End Function


' Resolve and internal ContentNode that's been abbreviated for the RowList
' into a fully parsed TubiContentNode
'
' @rowItemIndex is 2D array of [rowindex, itemindex] from RowList.rowItemSelected or m.RowList.rowItemFocused
Function resolveAbbreviatedContent(rowItemIndex)
  tubiLog("MyStuffScreen.resolveAbbreviatedContent")

  content = getAbbreviatedContent(rowItemIndex)
  category = m.top.content.getChild(rowItemIndex[0])
  if content <> invalid AND isNonEmptyString(content.id)
    contentId = content.id
    contentFromJSON = m.metadataTranslate.getContentFromCategoryJson(category, contentId) ' can return invalid
    return contentFromJSON
  end if

  return invalid
End Function


Function onTransportVoiceRequest(msg)
  response = "unhandled"
  inputInfo = msg.getData()
  if m.RowList.isInFocusChain() = true
    command = ""
    if inputInfo <> invalid AND inputInfo.command <> invalid
      command = inputInfo.command
    end if
    tubiLog("MyStuffScreen.onTransportVoiceRequest " + command)

    if command = "play"
      if handlePlayInput() = true
        response = "success"
      end if
    else if command = "ok"
      if m.top.signedIn = true
        handleItemSelected(m.top.cursorPosition)
      else
        '//communicate that the user is asking to start the sign in process
        m.top.signUpButtonSelected = true
      end if
    end if
  end if

  inputInfo.response = response
  m.top.transportVoiceResponse = inputInfo
End Function


' returns true if action was taken based on the "play" input and false if no action taken
Function handlePlayInput()
  if m.top.isLoading <> true and m.top.signedIn = true
    itemFocused = resolveAbbreviatedContent(m.RowList.rowItemFocused)
    positionFocused = m.top.cursorPosition

    ' Content controller observes contentSelected to populate/push the detail screen
    if itemFocused <> invalid AND itemFocused.type <> m.constants.ui.contentTypes.linear
      m.top.trackingComponentInfo = getTrackingComponentInfoOfRowList(itemFocused, positionFocused)
      m.top.contentToPlay = itemFocused
      return true
    end if
  end if
  return false
End Function


'''''''''''''''''''''''''''
' onSignedInChange
'
' When signed in/out changes, we need to change the UI experience
' users
Function onSignedInChange()
  tubiLog("MyStuffScreen.onSignedInChange")
  if m.top.signedIn = false
    m.ContentArea.visible = false
    m.SignedOutUI.visible = true
    m.GuestMenu.setFocus(true)
  else
    m.ContentArea.visible = true
    m.SignedOutUI.visible = false
    m.RowList.setFocus(true)
  end if
End Function


'''''''''''''''''''''''''''
' onJumpToRowItemChange
' 
' Jump to the desired row item. The data object within the event object should be an associative array. It should have 2 params: id AND index;
' where ID is the ID string of the item that should be jumped to, and index is the 2-element array containing the desired row and column to jump to.
' The function will attempt to jump to the element with the desired ID, in the desired row. This may be the desired index, but since the content may have changed,
' the index may not be reliable, so this is why the ID is also passed.
Function onJumpToRowItemChange(msg)
  tubiLog("MyStuffScreen.onJumpToRowItemChange")
  rowItemToSetFocus = msg.getData()
  if m.RowList.content <> invalid AND rowItemToSetFocus <> invalid AND (isNonEmptyString(rowItemToSetFocus.id) = true OR isNonEmptyArray(rowItemToSetFocus.index) = true)
    itemIndex = [0,0]
    if isNonEmptyArray(rowItemToSetFocus.index) = true
      itemIndex = rowItemToSetFocus.index
    end if
    sItemID = rowItemToSetFocus.id
    row = itemIndex[0]
    column = itemIndex[1]

    if isNonEmptyString(sItemID) = true 
      focusRow = m.RowList.content.getChild(row)
      nColumnCount = focusRow.getChildCount() - 1

      '//Try to find the content within the provided row
      bFindByID = false
      for i = 0 to nColumnCount
        item = focusRow.getChild(i)
        if item.id = sItemID
          bFindByID = true
          column = i
          exit for
        end if
      end for

      '//If the content cannot be located, (it may have been removed from the container), then use the provided column or the closest column available within that row if that column no longer exists.
      if bFindByID = false
        if column > nColumnCount
          column = nColumnCount
        end if
      end if
    end if

    if m.RowList.content.getChild(row).gridItemType = m.constants.ui.gridItemTypes.emptyContainer
      '//If the current row is empty, then check if the other row is empty
      column = 0
      nOtherRow = Abs(row - 1)
      if m.RowList.content.getChild(nOtherRow).gridItemType <> m.constants.ui.gridItemTypes.emptyContainer
        '//if the other row is not empty, then set focus on other row
        row = nOtherRow
      else
        '//if the other row is empty, then default focus on the top row
        row = 0
      end if
    end if

    m.RowList.jumpToRowItem = [row, column]

    '//After jumping to a row item, then immediately reset the row's counter index
    '//   This is when an item is added to the list and the user backs up to the MyStuffScreen again
    category = m.RowList.content.getChild(m.RowList.rowItemFocused[0])
    if category <> invalid
      category.focusIndex = m.RowList.rowItemFocused[1]
    end if
  end if

End Function


'''''''''''''''''''''''''''
' onResetChange
'
' When the reset field is set to true, then reset some values back to where they were when the screen 1st loaded.
Function onResetChange(msg)
  tubiLog("MyStuffScreen.onResetChange")
  bReset = msg.getData()
  if bReset = true
    m.top.contentFocused  = invalid
    m.oldCursorPosition = [-1,-1]
    m.top.cursorPosition = [-1,-1]
    m.RowList.jumpToRowItem = [0, 0]
  end if
End Function