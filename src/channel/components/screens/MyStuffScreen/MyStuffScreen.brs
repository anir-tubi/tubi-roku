Function init()
  tubiLog("MyStuffScreen.init")
  m.constants = getConstantsFromGlobal()
  m._ = rodash()
  Request = TubiRequest(m.constants.settings)
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)
  m.ContentArea = m.top.findNode("ContentArea")
  m.InfoPanel = m.top.findNode("InfoPanel")
  m.SignedOutUI = m.top.findNode("SignedOutUI")
  m.SignedOutUITitle = m.top.findNode("SignedOutUITitle")
  m.SignedOutUISubtitle = m.top.findNode("SignedOutUISubtitle")
  m.SignedOutUIBlurb = m.top.findNode("SignedOutUIBlurb")
  m.AllEmptyUI = m.top.findNode("AllEmptyUI")
  m.AllEmptyUIMenu = m.top.findNode("AllEmptyUIMenu")
  m.AllEmptyUITitle = m.top.findNode("AllEmptyUITitle")
  m.AllEmptyUISubtitle = m.top.findNode("AllEmptyUISubtitle")
  m.AllEmptyUISubtitle2 = m.top.findNode("AllEmptyUISubtitle2")
  m.AllEmptyUISubtitle2Icon = m.top.findNode("AllEmptyUISubtitle2Icon")

  m.SignedOutUITitle.text = getTranslation("screenMyStuff_signedOutUITitle")
  m.SignedOutUISubtitle.text = getTranslation("screenMyStuff_signedOutUISubtitle")
  m.SignedOutUIBlurb.text = getTranslation("screenMyStuff_signedOutUIBlurb")
  m.AllEmptyUITitle.text = getTranslation("screenMyStuff_allEmptyUITitle")
  m.AllEmptyUISubtitle.text = getTranslation("screenMyStuff_signedOutUISubtitle")
  m.AllEmptyUISubtitle2.text = getTranslation("screenMyStuff_allEmptyUISubtitle")
  m.AllEmptyUISubtitle2.width = 0 '//set to 0 so the boundingRect()'s dimensions are properly set
  m.AllEmptyUISubtitle2.width = m.AllEmptyUISubtitle2.boundingRect().width
  m.top.screenLevel = m.constants.ui.screenLevels.myStuffScreen
  m.top.id = m.constants.ui.screenIds.myStuffScreen
  m.isAllContentEmpty = false '//when the content is loaded and it is discovered that all the containers are empty, then this is set to true

  m.top.handlesTransportVoiceRequests = true

  m.oldCursorPosition = [-1, -1]
  m.top.cursorPosition = [-1, -1]
  m.oldCategoryId = ""
  m.currCategoryId = ""

  'used to know when to send tracking info. Do not send focus tracking info when the rowlist is 1st loaded
  m.gridHasGainedInitialFocus = false

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
  m.RowList.focusBitmapUri = "pkg:/images/selector-$$RES$$.9.png"
  m.GuestMenu.focusBitmapUri = "pkg:/images/menu-focus-$$RES$$.9.png"
  m.GuestMenu.focusFootprintBitmapUri = "pkg:/images/menu-disabled-focus-$$RES$$.9.png"
  m.AllEmptyUIMenu.focusBitmapUri = "pkg:/images/menu-focus-$$RES$$.9.png"
  m.AllEmptyUIMenu.focusFootprintBitmapUri = "pkg:/images/menu-disabled-focus-$$RES$$.9.png"

  defaultGuestMenuWidth = m.GuestMenu.itemSize[0]
  signInOutButton = m.top.findNode("SignInOutButton")
  signInOutButton.title = getTranslation("menu_signIn")

  allEmptyUIButton = m.top.findNode("AllEmptyUIButton")
  allEmptyUIButton.title = getTranslation("menu_goHome")

  ' Adjust the width of the guest menu if text of the button is too long for the default width. Mostly spanish text are generally longer in length.
  tempChannelMenuItem = CreateObject("roSGNode", "DetailMenuItem")
  tempChannelMenuItem.itemContent = signInOutButton

  potentialWidth = tempChannelMenuItem.calculatedTextWidth + tempChannelMenuItem.leftTextPadding + tempChannelMenuItem.rightTextPadding
  if potentialWidth > defaultGuestMenuWidth AND potentialWidth > m.GuestMenu.itemSize[0]
    m.GuestMenu.itemSize = [potentialWidth, m.GuestMenu.itemSize[1]]
  end if

  ' Adjust the width of the guest menu if text of the button is too long for the default width. Mostly spanish text are generally longer in length.
  tempChannelMenuItem.itemContent = allEmptyUIButton

  potentialWidth = tempChannelMenuItem.calculatedTextWidth + tempChannelMenuItem.leftTextPadding + tempChannelMenuItem.rightTextPadding
  if potentialWidth > defaultGuestMenuWidth AND potentialWidth > m.GuestMenu.itemSize[0]
    m.AllEmptyUIMenu.itemSize = [potentialWidth, m.AllEmptyUIMenu.itemSize[1]]
  end if

  m.RowList.observeFieldScoped("rowItemFocused", "onRowItemFocused")
  m.RowList.observeFieldScoped("rowItemSelected", "onRowItemSelected")
  m.GuestMenu.observeFieldScoped("itemSelected", "onGuestMenuItemSelected")
  m.AllEmptyUIMenu.observeFieldScoped("itemSelected", "onAllEmptyMenuItemSelected")

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

  bKidsTheme = false

  if theme <> invalid
    m.SignedOutUITitle.color = theme.primaryTextColor
    m.SignedOutUISubtitle.color = theme.secondaryTextColor
    m.SignedOutUIBlurb.color = theme.primaryTextColor
    m.AllEmptyUITitle.color = theme.primaryTextColor
    m.AllEmptyUISubtitle.color = theme.secondaryTextColor
    m.AllEmptyUISubtitle2.color = theme.secondaryTextColor
    m.AllEmptyUISubtitle2Icon.blendColor = theme.secondaryTextColor
    m.GuestMenu.focusBitmapBlendColor = theme.focusedColor
    m.AllEmptyUIMenu.focusBitmapBlendColor = theme.focusedColor
    m.RowList.focusBitmapBlendColor = theme.focusedColor

    bKidsTheme = (theme.id = m.constants.ui.themeIDs.kidsMode)
  end if

  if bKidsTheme = true
    m.defaultBackgroundUri = "https://cdn.adrise.tv/image/roku_support_images/backgroundMyStuffDefault_kids.webp"
  else
    m.defaultBackgroundUri = "https://cdn.adrise.tv/image/roku_support_images/backgroundMyStuffDefault.webp"
  end if
End Function


Function onScreenFocusChange()
  tubiLog("MyStuffScreen.onScreenFocusChange")
  if m.top.hasFocus() = true
    if m.top.signedIn = false
      m.GuestMenu.setFocus(true)
      m.top.backgroundUriList = [m.defaultBackgroundUri]
    else if m.top.content <> invalid
      if m.top.content.getChildCount() > 0
        oldFocusedRowItem = m.top.cursorPosition
        if m.isAllContentEmpty = true
          m.AllEmptyUIMenu.setFocus(true)
          m.top.backgroundUriList = [m.defaultBackgroundUri]
        else
          m.RowList.setFocus(true)
          if oldFocusedRowItem <> invalid
            '//when regaining focus, focus on previous item instead of [0,0]
            m.RowList.jumpToRowItem = oldFocusedRowItem
          end if
        end if
      end if

      if m.RowList.content <> invalid AND shouldRefresh(m.RowList.content) = true 'cacheValidationMixin
        m.top.refreshContent = true
      end if
    end if
  end if
End Function


Function onLoadingChange(msg)
  tubiLog("MyStuffScreen.onLoadingChange")
  isLoading = msg.getData()

  if isLoading = true
    m.SignedOutUI.visible = false
    m.RowList.visible = false
    m.InfoPanel.visible = false
    m.RowList.content = invalid 'When not fully loaded, then the rowlist should not show any content
    m.AllEmptyUI.visible = false
    m.top.backgroundUriList = [m.defaultBackgroundUri]
  end if
End Function


Function onContentUpdateChange(msg) As Void
  tubiLog("MyStuffScreen.onContentUpdateChange")
  content = m.top.content
  if content <> invalid
    ' Delayed setting of Rowlist content until first batch arrives
    setRowHeights()

    nContainers = content.getChildCount()
    if nContainers > 0
      m.isAllContentEmpty = true
      for i = 0 to nContainers - 1
        container = content.getChild(i)
        if container.gridItemType <> m.constants.ui.gridItemTypes.emptyContainer
          m.isAllContentEmpty = false
          exit for
        end if
      end for

      if m.isAllContentEmpty = false
        m.AllEmptyUI.visible = false
        m.RowList.visible = true
        m.InfoPanel.visible = true
        m.RowList.setFocus(true)
      else
        m.AllEmptyUI.visible = true
        m.RowList.visible = false
        m.InfoPanel.visible = false
        m.AllEmptyUIMenu.setFocus(true)
        m.top.backgroundUriList = [m.defaultBackgroundUri]
      end if
    end if
  else
    m.AllEmptyUI.visible = false
    m.RowList.content = invalid
    m.RowList.visible = false
    m.InfoPanel.visible = false
    m.isAllContentEmpty = false
  end if
End Function


Function setRowHeights()
  'determine the height of each row in the RowList so we can set it on RowList.rowItemSize
  rowItemSize = []
  rowHeights = []
  for i = 0 to m.top.content.getChildCount() - 1
    category = m.top.content.getChild(i)
    rowHeight = 0
    rowHeightAdjustment = 0
    gridItemType = category.gridItemType
    gridItemTypes = m.constants.ui.gridItemTypes
    if gridItemType = gridItemTypes.emptyContainer
      rowHeightAdjustment = m.constants.ui.imageSizes.emptyContainer[1] - m.constants.ui.imageSizes.landscape[1]
      rowItemSize.push(m.constants.ui.imageSizes.emptyContainer)
      rowHeight = m.constants.ui.imageSizes.emptyContainer[1]
    else if gridItemType = gridItemTypes.portrait
      posterWidth = m.constants.ui.imageSizes.poster[0]
      posterHeight = m.constants.ui.imageSizes.poster[1]
      rowHeightAdjustment = 80
      rowItemSize.push([posterWidth, posterHeight])
      rowHeight = posterHeight
    else if gridItemType = gridItemTypes.landscapeInnerMetadata
      posterWidth = m.constants.ui.imageSizes.landscape[0]
      posterHeight = m.constants.ui.imageSizes.landscape[1]
      rowHeightAdjustment = 50
      rowItemSize.push([posterWidth, posterHeight])
      rowHeight = posterHeight
    end if
    rowHeights.push(rowHeight + rowHeightAdjustment)
  end for

  '//setting the height of the m.RowList.itemSize is superceded by the rowHeight of each row
  itemSize = [1752, 364]
  m.Rowlist.update({
    "itemSize": itemSize
    "rowItemSize": rowItemSize
    "rowHeights": rowHeights
    "showRowLabel": [true]
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

    m.top.contentFocused = resolveAbbreviatedContent(newCursorPosition)

    category = m.RowList.content.getChild(newCursorPosition[0])
    if category <> invalid
      m.oldCategoryId = m.currCategoryId
      m.currCategoryId = category.id

      ' immediately update the position counter
      category.focusIndex = newCursorPosition[1]
    end if

    '//Set the Metadata
    itemFocused = resolveAbbreviatedContent(m.RowList.rowItemFocused)
    m.top.backgroundUriList = determineBackgroundImage(itemFocused)

    mode = m.constants.ui.infoPanelModes.item
    if category.gridItemType = m.constants.ui.gridItemTypes.emptyContainer
      emptyContentNode = CreateObject("roSGNode", "TubiContentNode")
      if category.id = m.constants.ui.categoryIds.history
        emptyContentNode.title = getTranslation("metadata_myStuff_empty_continueWatchingInfoPanel_title")
        emptyContentNode.description = getTranslation("metadata_myStuff_empty_continueWatchingInfoPanel_description")
        mode = m.constants.ui.infoPanelModes.continueWatching
      else if category.id = m.constants.ui.categoryIds.queue
        emptyContentNode.title = getTranslation("metadata_myStuff_empty_myListInfoPanel_title")
        emptyContentNode.description = getTranslation("metadata_myStuff_empty_myListInfoPanel_description")
        mode = m.constants.ui.infoPanelModes.continueWatching
      end if

      populateInfoPanel(mode, emptyContentNode) 'empties the info panel
    else
      populateInfoPanelByContent(itemFocused)
    end if

    'Set up the navigateWithinPageInfo to send to ContentController.
    oldAnalyticsRow = m.oldCursorPosition[0] + 1
    oldAnalyticsCol = m.oldCursorPosition[1] + 1
    newAnalyticsRow = newCursorPosition[0] + 1
    newAnalyticsCol = newCursorPosition[1] + 1

    if m.gridHasGainedInitialFocus = true AND oldAnalyticsRow > 0 AND oldAnalyticsCol > 0
      if oldAnalyticsRow <> newAnalyticsRow OR oldAnalyticsCol <> newAnalyticsCol

        myStuffComponentInfo = {}
        myStuffComponentInfo["category_slug"] = m.oldCategoryId
        'row is hardcoded to 1 in the line below because the row represents the row within the category_component, not within the grid
        'and the current design only has one row per category
        tile = m.Tracking.getAnalyticsTile(oldFocusedContent, oldAnalyticsCol, 1)
        myStuffComponentInfo["content_tile"] = tile
        myStuffComponentInfo["category_row"] = oldAnalyticsRow
        myStuffComponentInfo["category_col"] = oldAnalyticsCol
        m.top.navigateWithinPageInfo = {
          pageOneof: m.Tracking.getAnalyticsPage(m.top.trackingPageInfo.pageType, m.top.trackingPageInfo.pageValues)
          componentOneof: m.Tracking.getAnalyticsComponent("category_component", myStuffComponentInfo)
          means_of_navigation: "BUTTON" 'MeansOfNavigation enum
          vertical_location: newAnalyticsRow
          horizontal_location: newAnalyticsCol
        }

      end if
    end if
    m.gridHasGainedInitialFocus = true
  end if

  return true
End Function


Function populateInfoPanelByContent(focusedContent)
  if focusedContent <> invalid
    sType = focusedContent.type
    mode = m.constants.ui.infoPanelModes.item
    if sType = m.constants.ui.categoryTypes.linear
      mode = m.constants.ui.infoPanelModes.linearHomeScreen
    else if sType = m.constants.ui.categoryTypes.historySignedOutUser
      mode = m.constants.ui.infoPanelModes.continueWatching
    else if sType = m.constants.ui.categoryTypes.preview
      mode = m.constants.ui.infoPanelModes.vitg
    '// REMOVE BELOW CODE ONCE FIFA WORLD CUP IS DONE
    else if sType = m.constants.ui.contentTypes.navigate
      mode = m.constants.ui.infoPanelModes.navigateSports
    '// REMOVE BELOW CODE ONCE FIFA WORLD CUP IS DONE
    else if sType = m.constants.ui.contentTypes.sportsEvent
      mode = m.constants.ui.infoPanelModes.sportsEvent
    end if

    populateInfoPanel(mode, focusedContent)
  end if
End Function


'@mode: string, one of the valid constants.ui.infoPanelModes info panel modes (see InfoPanel.xml for details)
'@contentNode: content node
Function populateInfoPanel(mode, contentNode)
  if contentNode <> invalid
    if mode = m.constants.ui.infoPanelModes.vitg
      m.InfoPanel.mode = mode
    else if mode = m.constants.ui.infoPanelModes.item
      populateInfoPanelWithHomescreenStyleItemMode(contentNode, m.InfoPanel)
    else if mode = m.constants.ui.infoPanelModes.linearHomeScreen
      m.InfoPanel.mode = mode
      m.InfoPanel.topHeaderImageUri = m.constants.ui.uris.infoPanelEpgLiveIcon
      m.InfoPanel.title = contentNode.title
      m.InfoPanel.description = contentNode.description
      m.InfoPanel.needsLogin = contentNode.needsLogin AND (m.top.signedIn <> true)
      m.InfoPanel.reminderIsSet = false
      m.InfoPanel.width = 650
    else if mode = m.constants.ui.infoPanelModes.continueWatching
      m.InfoPanel.mode = mode
      m.InfoPanel.title = contentNode.title
      m.InfoPanel.description = contentNode.description
      m.InfoPanel.reminderIsSet = false
      m.InfoPanel.width = 960
    else if mode = m.constants.ui.infoPanelModes.programHomescreen
      populateInfoPanelWithProgramHomescreenMode(contentNode, m.InfoPanel)
    '// REMOVE BELOW CODE ONCE FIFA WORLD CUP IS DONE
    else if mode = m.constants.ui.infoPanelModes.navigateSports
      m.InfoPanel.mode = mode
      m.InfoPanel.topHeaderImageUri = m.constants.ui.uris.infoPanelWorldCupLogo
      m.InfoPanel.title = contentNode.title
      'Fifa Worldcup description and dates are constant when show all games is focused, so hardcoding it
      m.InfoPanel.description = getTranslation("show_all_games_description")
      lineOneData = {}
      lineOneData.hoursOfAiring = getTranslation("show_all_games_gameInfo")
      'Showing 4k badge by default for show all CTA Infopanel
      lineOneData.has4k = true
      lineOneData.hasCC = contentNode.hasSubtitles
      m.InfoPanel.lineOneData = lineOneData
      m.InfoPanel.needsLogin = false
      m.InfoPanel.reminderIsSet = false
      m.InfoPanel.width = 960
    else if mode = m.constants.ui.infoPanelModes.sportsEvent
      populateInfoPanelWithHomescreenStyleSportsMode(contentNode, m.InfoPanel)
    end if

    m.InfoPanel.calculateHeight = true
  end if
End Function


Function onRowItemSelected(msg)
  tubiLog("MyStuffScreen.onRowItemSelected")
  selectedPosition = msg.getData()
  handleItemSelected(selectedPosition)
End Function


Function onGuestMenuItemSelected(msg)
  tubiLog("MyStuffScreen.onGuestMenuItemSelected")
  setSignUpButtonSelectedIndicator()
End Function


Function onAllEmptyMenuItemSelected(msg)
  tubiLog("MyStuffScreen.onAllEmptyMenuItemSelected")
  setAllEmptyMenuItemSelectedIndicator()
End Function


Function setSignUpButtonSelectedIndicator()
  sendButtonComponentAnalytics("SIGNUP_TO_SAVE_PROGRESS")
  '//communicate that the user is asking to start the sign in process
  m.top.signUpButtonSelected = true
End Function


Function setAllEmptyMenuItemSelectedIndicator()
  sendButtonComponentAnalytics("GO_TO_HOME")
  '//communicate that the user is asking to go to the homescreen
  m.top.homeButtonSelected = true
End Function


' Set the componentInteractionInfo so the analytics of the button press is sent
' @sButtonValue: string, The 'section value' of the button to send to the analytics
Function sendButtonComponentAnalytics(sButtonValue)
  'send analytics that signin button was pressed
  componentValues = {
    button_type: "TEXT"
    button_value: sButtonValue 'Button value is always upper case and concatinated by "_"
  }
  pageInfo = m.top.trackingPageInfo
  m.top.componentInteractionInfo = {
    pageOneof: m.Tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
    componentOneof: m.Tracking.getAnalyticsComponent("button_component", componentValues)
    user_interaction: "CONFIRM"
  }
End Function


Function handleItemSelected(selectedPosition)
  tubiLog("MyStuffScreen.handleItemSelected")
  if m.top.content <> invalid
    itemSelected = resolveAbbreviatedContent(selectedPosition)

    category = m.RowList.content.getChild(selectedPosition[0])
    if category.gridItemType <> m.constants.ui.gridItemTypes.emptyContainer
      '//don't do anything if the empty container is selected

      m.top.trackingComponentInfo = getTrackingComponentInfoOfRowList(itemSelected, selectedPosition)
      if itemSelected <> invalid
        m.top.contentSelected = itemSelected
      end if

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
    tile = m.Tracking.getAnalyticsTile(gridItem, itemPosition[1] + 1)
    componentValues["content_tile"] = tile
    componentValues["category_row"] = itemPosition[0] + 1 'all analytics are 1 based
    componentValues["category_col"] = itemPosition[1] + 1 'all analytics are 1 based

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
        if m.isAllContentEmpty = false
          handleItemSelected(m.top.cursorPosition)
          response = "success"
        else
          '//communicate that the user is asking to go to the home screen
          setAllEmptyMenuItemSelectedIndicator()
          response = "success"
        end if
      else
        '//communicate that the user is asking to start the sign in process
        setSignUpButtonSelectedIndicator()
        response = "success"
      end if
    end if
  end if

  inputInfo.response = response
  m.top.transportVoiceResponse = inputInfo
End Function


' returns true if action was taken based on the "play" input and false if no action taken
Function handlePlayInput()
  if m.top.isLoading <> true AND m.top.signedIn = true
    if isVideoPreviewEnabled() = true
      m.top.stopVideoPreview = true
    end if

    itemFocused = resolveAbbreviatedContent(m.RowList.rowItemFocused)
    positionFocused = m.top.cursorPosition
    category = m.RowList.content.getChild(positionFocused[0])
    ' Content controller observes contentSelected to populate/push the detail screen
    if itemFocused <> invalid AND itemFocused.type <> m.constants.ui.contentTypes.linear AND category.gridItemType <> m.constants.ui.gridItemTypes.emptyContainer
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
    m.AllEmptyUI.visible = false
    m.InfoPanel.visible = false
    m.isAllContentEmpty = false
    m.top.backgroundUriList = [m.defaultBackgroundUri]
  else
    m.ContentArea.visible = true
    m.SignedOutUI.visible = false
    m.AllEmptyUI.visible = false
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
    itemIndex = [0, 0]
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

    m.RowList.jumpToRowItem = [row, column]

    '//After jumping to a row item, then immediately reset the row's counter index
    '//   This is when an item is added to the list and the user backs up to the MyStuffScreen again
    rowItemFocused = m.RowList.rowItemFocused
    if rowItemFocused[0] <> invalid
      category = m.RowList.content.getChild(rowItemFocused[0])
      if category <> invalid
        category.focusIndex = rowItemFocused[1]
      end if
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
    m.top.contentFocused = invalid
    m.oldCursorPosition = [-1, -1]
    m.top.cursorPosition = [-1, -1]
    m.RowList.jumpToRowItem = [0, 0]
  end if
End Function

Function onKeyEvent(key As String, press As Boolean) as Boolean
  tubiLog("MyStuffScreen.onKeyEvent key = " + key)
  if press = true
    if key = "OK"
      '//ensure this keypress is captured so the default Roku positive audio sound is played.
      return true
    else if key = "play" AND m.RowList.isInFocusChain() = true
      
      if handlePlayInput() = true
        return true
      end if

    else if key = "left" OR key = "back"

      if isVideoPreviewEnabled() = true
        m.top.pauseVideoPreview = true
      end if

    end if
  end if
  return false
End Function
