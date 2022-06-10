Function init()
  m.constants = m.global.constants
  Request = TubiRequest(m.constants.settings)
  m.Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, m.Auth)
  m.NodeHelpers = TubiNodeHelpers()
  m.Info = m.top.findNode("DetailInfoPanel")
  m.Menu = m.top.findNode("Menu")
  m.defaultMenuWidth = m.Menu.itemSize[0]
  m.ResumeMenuItem = m.top.findNode("ResumeMenuItem")
  m.PlayMenuItem = m.top.findNode("PlayMenuItem")
  m.EpisodesMenuItem = m.top.findNode("EpisodesMenuItem")
  m.AddQueueMenuItem = m.top.findNode("AddQueueMenuItem")
  m.RemoveQueueMenuItem = m.top.findNode("RemoveQueueMenuItem")
  m.RemoveHistoryMenuItem = m.top.findNode("RemoveHistoryMenuItem")
  m.ChannelMenuItem = m.top.findNode("ChannelMenuItem")
  m.WatchTrailerMenuItem = m.top.findNode("WatchTrailerMenuItem")
  ' fire exposure event when detail screen is
  updateIconsEnabled = getExperimentResource("roku_update_icons", "roku_update_icons_v1", false).enabled
  if updateIconsEnabled = false
    m.ResumeMenuItem.iconUrl = "pkg:/images/icon-resume.png"
    m.PlayMenuItem.iconUrl = "pkg:/images/icon-play.png"
    m.EpisodesMenuItem.iconUrl = "pkg:/images/icon-all-episodes.png"
    m.AddQueueMenuItem.iconUrl = "pkg:/images/icon-add-to-queue.png"
    m.RemoveQueueMenuItem.iconUrl = "pkg:/images/icon-remove-from-queue.png"
    m.RemoveHistoryMenuItem.iconUrl = "pkg:/images/icon-remove-from-history.png"
    m.WatchTrailerMenuItem.iconUrl = "pkg:/images/icon-trailer.png"
  end if
  m.RelatedContentParentGroup = m.top.findNode("RelatedContentParentGroup")
  m.RelatedContentGroup = m.RelatedContentParentGroup.findNode("RelatedContentGroup")
  m.RelatedGrid = m.top.findNode("RelatedGrid")
  m.RelatedTitle = m.top.findNode("RelatedTitle")
  m.RelatedRowLabel = m.top.findNode("RelatedRowLabel")
  m.AnimationGroup = m.top.findNode("AnimationGroup")
  m.signUpMenuItem = m.top.findNode("signUpMenuItem")
  if updateIconsEnabled = true
    m.signUpMenuItem.iconUrl = "pkg:/images/icon-sign-in.webp"
  end if
  m.top.observeFieldScoped("removeSignupButton", "onRemoveSignupButton")
  m.top.observeFieldScoped("stringSignUpButton", "onStringChange")
  m.top.observeField("length", "onLengthChange")
  m.top.observeField("isSeries", "onIsSeries")
  m.top.observeField("isInKidsAgeGateMode", "onIsInKidsAgeGateMode")
  m.top.observeField("isBookmark", "onIsBookmark")
  m.top.observeField("isHistory", "onIsHistory")
  m.top.observeField("isChannelItem", "onIsChannel")
  m.top.observeField("resumePoint", "onResumePointChange")
  m.top.observeField("hasTrailer", "onHasTrailer")
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("isLoading", "onIsLoading")
  m.top.observeField("disableBookmarks", "onDisableBookmarksChange")
  m.top.observeField("transportVoiceRequest", "onTransportVoiceRequest")

  m.top.observeFieldScoped("stringQueueButton", "onStringChange")
  m.top.observeFieldScoped("stringNoQueueButton", "onStringChange")
  m.top.observeFieldScoped("stringChannelButton", "onStringChange")
  m.top.observeFieldScoped("stringNoHistoryButton", "onStringChange")


  m.Menu.observeField("itemSelected", "onMenuItemSelected")
  m.top.observeField("relatedContent", "onRelatedContentChange")
  m.RelatedGrid.observeField("itemSelected", "onRelatedContentSelected")
  m.RelatedGrid.observeField("itemFocused", "onRelatedItemFocused")
  m.Info.observeField("descriptionSelected", "onDescriptionSelected")

  m.defaultHeroUri = "pkg:/images/art-blur-background.png"
  setInitialMenuItems()
  m.focusTarget = m.Menu
  setDetailStrings()
  m.focusAnimationDuration = 0.4

  ' modal popup to show full, scrollable description
  m.descriptionModal = invalid

  'set initial tracking values
  m.top.trackingPageInfo = {
    pageType: "video_page"
    pageValues: {
      video_id: 0
    }
  }

  if m.constants.deviceInfo.scaledUi = true then
    m.RelatedGrid.focusBitmapUri = "pkg:/images/selector-hd.9.png"
  end if

  m.RelatedGrid.focusBitmapBlendColor = m.global.theme.focused

  ' Used to determine if navigate_within_page events should be sent. Only send when the related content already
  ' has focus, not when it gains focus.
  m.relatedHasFocus = false

  ' isChannelMenuSelected variable is used for handling the channel selection from detail menu
  m.isChannelMenuSelected = false

  m.top.screenLevel = m.constants.ui.screenLevels.detailScreen
  m.top.isStackable = true
  m.top.handlesTransportVoiceRequests = true
End Function


Function setDetailStrings()
  m.PlayMenuItem.title = getTranslation("screenDetails_button_play")
  m.ResumeMenuItem.title = getTranslation("screenDetails_button_resume")
  m.EpisodesMenuItem.title = getTranslation("screenDetails_button_episodes")
  m.WatchTrailerMenuItem.title = getTranslation("screenDetails_button_trailer")
  RelatedRowLabelContent = m.top.findNode("RelatedRowLabelContent")
  RelatedRowLabelContent.title = getTranslation("screenDetails_relatedTitles")
End Function


Function onStringChange(message)
  sStringField = message.GetField()
  sText = message.GetData()

  stringNode = invalid

  if sStringField = "stringQueueButton"
    stringNode = m.AddQueueMenuItem
  else if sStringField = "stringNoQueueButton"
    stringNode = m.RemoveQueueMenuItem
  else if sStringField = "stringChannelButton"
    stringNode = m.ChannelMenuItem
  else if sStringField = "stringNoHistoryButton"
    stringNode = m.RemoveHistoryMenuItem
  else if sStringField = "stringSignUpButton"
    stringNode = m.signUpMenuItem
  end if

  if stringNode <> invalid
    sTextSplitArray = sText.split(";")
    if sTextSplitArray.count() > 1
      stringNode.title = sText.split(";")[0]
      stringNode.badgeText = sText.split(";")[1]
    else
      stringNode.title = sText
    end if

    ' Adjust the width of the menu if the Channel name is too long for the default width
    if sStringField = "stringChannelButton" or sStringField = "stringSignUpButton"
      tempChannelMenuItem = CreateObject("roSGNode", "DetailMenuItem")
      tempChannelMenuItem.itemContent = stringNode

      potentialWidth = tempChannelMenuItem.calculatedTextWidth + tempChannelMenuItem.leftTextPadding + tempChannelMenuItem.rightTextPadding
      if potentialWidth > m.defaultMenuWidth
        m.Menu.itemSize = [potentialWidth, m.Menu.itemSize[1]]
      end if

      tempChannelMenuItem = invalid
    end if
  end if

End Function


Function onDescriptionSelected()
  tubiLog("DetailScreen.onDescriptionSelected")
  m.top.fullDescriptionSelected = true
End Function


Function refocusMenuItem()
  if m.Menu.content <> invalid
    if m.Menu.itemFocused >= m.Menu.content.getChildCount()
      jumpToItem = m.Menu.content.getChildCount() - 1

      if jumpToItem >= 0
        m.Menu.jumpToItem = jumpToItem
      end if
    end if
  end if

  focusMenu(true)
End Function


Function onScreenFocusChange()
  tubiLog("DetailScreen.onScreenFocusChange")
  if m.top.hasFocus() then

    'After Instant Resume, when pressing back from one detail screen to another detail screen via YMAL
    'related content(YMAL) thunbnails are not loading. Resetting relatedContent node fixes the issue.
    relatedContent = m.top.relatedContent
    m.top.relatedContent = invalid
    m.top.relatedContent = relatedContent

    m.focusTarget.setFocus(true)

    'determine if the content should be refreshed
    if shouldRefresh(m.top.content) = true
      m.top.refreshContent = true
    end if

    if shouldRefresh(m.top.relatedContent) = true
      m.RelatedContentGroup.visible = false
      m.top.refreshRelatedContent = true
    end if
  end if
  ' force a background update
  m.top.backgroundUriList = m.top.backgroundUriList
End Function


Function onLengthChange()
  tubiLog("DetailScreen.onLengthChange")
  m.ResumeMenuItem.length = m.top.length
End Function


Function onResumePointChange()
  tubiLog("DetailScreen.onResumePointChange")
  menuItems = m.Menu.content
  resumeIndex = m.NodeHelpers.getChildIndexById(menuItems, m.ResumeMenuItem.id)

  m.ResumeMenuItem.playstart = m.top.resumePoint
  if resumeIndex = -1 and m.top.resumePoint > 0
    m.Menu.content.insertChild(m.ResumeMenuItem, 0)
  else if resumeIndex > -1 and m.top.resumePoint = 0
    m.Menu.content.removeChildIndex(resumeIndex)
  end if
End Function


Function onIsBookmark()
  tubiLog("DetailScreen.onIsBookmark")
  menuItems = m.Menu.content
  addQueueIndex = m.NodeHelpers.getChildIndexById(menuItems, m.AddQueueMenuItem.id)
  removeQueueIndex = m.NodeHelpers.getChildIndexById(menuItems, m.RemoveQueueMenuItem.id)

  if m.top.disableBookmarks = false
    if m.top.isBookmark = false
      if addQueueIndex = -1
      'add queue item doesn't exist
        if removeQueueIndex > -1
          'remove queue item does exist so replace remove queue item with add queue item
          m.Menu.content.removeChildIndex(removeQueueIndex)
          m.Menu.content.insertChild(m.AddQueueMenuItem, removeQueueIndex)
        else
          m.Menu.content.appendChild(m.AddQueueMenuItem)
        end if
      else if removeQueueIndex > -1
        'both add to queue and remove from queue items exist... this shouldn't happen
        m.Menu.content.removeChildIndex(removeQueueIndex)
      end if
    else
      if removeQueueIndex = -1
        'remove queue item doesn't exist
        if addQueueIndex > -1
          'add queue item exists, so replace add queue item with remove queue item
          m.Menu.content.removeChildIndex(addQueueIndex)
          m.Menu.content.insertChild(m.RemoveQueueMenuItem, addQueueIndex)
        else
          m.Menu.content.appendChild(m.RemoveQueueMenuItem)
        end if
      else if addQueueIndex > -1
        'both add to queue and remove from queue items exist... this shouldn't happen
        m.Menu.content.removeChildIndex(m.AddQueueMenuItem)
      end if
    end if
  end if
End Function


Function onIsHistory()
  tubiLog("DetailScreen.onIsHistory")
  'if removing from history, remove the resume button
  resumeIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.ResumeMenuItem.id)
  if not m.top.isHistory
    addRemoveMenuItem(m.top.isHistory, resumeIndex)
  end if

  removeHistoryIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.RemoveHistoryMenuItem.id)
  previousItems = [m.AddQueueMenuItem, m.RemoveQueueMenuItem]
  addRemoveMenuItem(m.top.isHistory, removeHistoryIndex, m.RemoveHistoryMenuItem, previousItems)
End Function


Function onIsChannel()
  tubiLog("DetailScreen.onIsChannel")
  channelIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.ChannelMenuItem.id)
  previousItems = [
    m.RemoveHistoryMenuItem
    m.RemoveQueueMenuItem
    m.AddQueueMenuItem
  ]
  addRemoveMenuItem(m.top.isChannelItem, channelIndex, m.ChannelMenuItem, previousItems)
End Function


Function onIsSeries()
  tubiLog("DetailScreen.onIsSeries")
  isSeries = m.top.isSeries
  episodeListIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.EpisodesMenuItem.id)
  signUpIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.signUpMenuItem.id)
  menuItems = [m.signUpMenuItem, m.PlayMenuItem]
  if isLoggedInUser() = false and isReturningUser()
    if getExperimentResource("roku_register_signup_to_save", "roku_register_signup_to_save_v3", true).enabled = true
      if isSeries = true and signUpIndex = 1
        'Remove the signup button at 1st index and make signup button as default for series.
        addRemoveMenuItem(false, signUpIndex)
        addRemoveMenuItem(true, -1, m.signUpMenuItem, [])
        menuItems = [m.PlayMenuItem, m.signUpMenuItem]
      else if isSeries = false and signUpIndex = 0
        'Move sign up button to 1st index for movies
        addRemoveMenuItem(false, signUpIndex)
        addRemoveMenuItem(true, -1, m.signUpMenuItem, [m.PlayMenuItem])
      end if 
    else
      if signUpIndex = -1
        menuItems = [m.PlayMenuItem]
      end if
    end if
  else
    'remove the sign up button if it's not needed
    addRemoveMenuItem(false, signUpIndex, m.signUpMenuItem, [])
    menuItems = [m.PlayMenuItem]
  end if
  addRemoveMenuItem(m.top.isSeries, episodeListIndex, m.EpisodesMenuItem, menuItems)
End Function


Function onRemoveSignupButton(msg)
  signUpIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.signUpMenuItem.id)
  if signUpIndex <> invalid
    addRemoveMenuItem(false, signUpIndex)
  end if
End Function


Function onIsInKidsAgeGateMode()
  if isLoggedInUser() = false and isReturningUser() = true
    signUpIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.signUpMenuItem.id)
    if m.top.isInKidsAgeGateMode = true and signUpIndex > -1
      addRemoveMenuItem(false, signUpIndex)
    else if m.top.isInKidsAgeGateMode = false and signUpIndex = -1
      addRemoveMenuItem(true, signUpIndex, m.signUpMenuItem, [m.PlayMenuItem])
    end if
  end if
End Function


Function onHasTrailer()
  tubiLog("DetailScreen.onHasTrailer")
  trailerIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.WatchTrailerMenuItem.id)
  signUpIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.signUpMenuItem.id)
  if m.signUpMenuItem <> invalid
    if signUpIndex > -1
      addRemoveMenuItem(m.top.hasTrailer, trailerIndex, m.WatchTrailerMenuItem, [m.signUpMenuItem])
    else
      addRemoveMenuItem(m.top.hasTrailer, trailerIndex, m.WatchTrailerMenuItem, [m.PlayMenuItem])
    end if
  else
    addRemoveMenuItem(m.top.hasTrailer, trailerIndex, m.WatchTrailerMenuItem, [m.PlayMenuItem])
  end if
End Function


Function onIsLoading()
  tubiLog("DetailScreen.onIsLoading")

  ' we only want to remove the menu on the initial loading of series screens.
  ' In the case of an error, we populate the screen with series metadata (as opposed to episode metadata)
  ' and we don't want to remove the menu once the screen already has metadata.
  if m.top.description = ""
    m.Menu.visible = not m.top.isLoading
  end if

  if m.top.relatedContent <> invalid and m.top.relatedContent.getChildCount() > 0
    m.RelatedContentGroup.visible = not m.top.isLoading
  else
    m.RelatedContentGroup.visible = false
  end if
End Function


Function onDisableBookmarksChange()
  if m.top.disableBookmarks = true
    ' remove any Add to My List or Remove from My List items that might be showing
    menuItems = m.Menu.content
    addQueueIndex = m.NodeHelpers.getChildIndexById(menuItems, m.AddQueueMenuItem.id)
    removeQueueIndex = m.NodeHelpers.getChildIndexById(menuItems, m.RemoveQueueMenuItem.id)

    if addQueueIndex > -1
      m.Menu.content.removeChildIndex(addQueueIndex)
    end if

    if removeQueueIndex > -1
      m.Menu.content.removeChildIndex(removeQueueIndex)
    end if
  end if
End Function


''''''''''''''''''''''
' setInitialMenuItems
'
' Detail screen always has at least a play button and "add to queue" button
' Set basic buttons first, additional buttons will be added based on the input fields of the details screen
Function setInitialMenuItems() As Void
  tubiLog("DetailScreen.setInitialMenuItems")
  menuItems = CreateObject("roSGNode", "ContentNode")
  menuItems.appendChild(m.PlayMenuItem)
  'Add SignUp button for registration experiemnt at 1st index by default
  if isLoggedInUser() = false and isReturningUser() = true
    menuItems.appendChild(m.signUpMenuItem)
  end if
  menuItems.appendChild(m.AddQueueMenuItem)
  m.Menu.content = menuItems
End Function


''''''''''''''''''''''
' addRemoveMenuItem
'
' add or remove a specific menu item
' @add: boolean, add an item if true, remove if false
' @itemIndex: int, index location of the item in the menuItems. -1 indicates the item does not exist in the menuItems.
' @itemToAdd: one of the DetailMenuItemContentNode children of the DetailScreen (ie m.EpisodesMenuItem). This is optional for remove.
' @previousItem: array, indicates which existing item the added item will follow. If the array contains multiple items,
'                       the first item in the array that is found will dictate the placement of the new item,
'                       and all other items will be disregarded.
' Set basic buttons first, additional buttons will be added based on the input fields of the details screen
Function addRemoveMenuItem(add, itemIndex, itemToAdd = invalid, previousItems = []) As Void
  menuItems = m.Menu.content

  if add = false and itemIndex > -1
    'menu item exists, so we need to remove it
    m.Menu.content.removeChildIndex(itemIndex)
    refocusMenuItem()
  else if add = true and itemIndex = -1
    'we don't have menu item, and need to add one
    'find the previous item index, and insert the Watch Trailer item one index after
    previousItemIndex = -1
    if itemToAdd <> invalid and previousItems <> invalid and previousItems.count() > 0
      for i=0 to previousItems.count()-1
        previousItem = previousItems[i]
        if previousItem <> invalid
          previousItemIndex = m.NodeHelpers.getChildIndexById(menuItems, previousItem.id)
          if previousItemIndex > -1
            exit for
          end if
        end if
      end for
    end if

    if previousItemIndex > -1
      m.Menu.content.insertChild(itemToAdd, previousItemIndex + 1)
    else if previousItems.count() = 0
      m.Menu.content.insertChild(itemToAdd, previousItemIndex + 1)
    else
      m.Menu.content.appendChild(itemToAdd)
    end if
    refocusMenuItem()
  end if
End Function


''''''''''''''''''''''''
' onMenuItemSelected
'
Function onMenuItemSelected()
  selection = m.Menu.content.getChild(m.Menu.itemSelected)
  handleMenuItemSelected(selection)
End Function


' @itemSelected: roSGNode: ContentNode representing the content that was selected by the user
Function handleMenuItemSelected(itemSelected)
  if itemSelected <> invalid then
    tubiLog("DetailScreen.handleMenuItemSelected" + itemSelected.title)
    m.top.stopVideoPreview = true
    if itemSelected.id = "ResumeMenuItem"
      m.top.resumeSelected = true
    else if itemSelected.id = "PlayMenuItem"
      m.top.playSelected = true
    else if itemSelected.id = "WatchTrailerMenuItem"
      m.top.watchTrailerSelected = true
    else if itemSelected.id = "EpisodesMenuItem"
      m.top.episodeListSelected = true
    else if itemSelected.id = "AddQueueMenuItem"
      m.top.addToQueueSelected = true
    else if itemSelected.id = "RemoveQueueMenuItem"
      m.top.removeFromQueueSelected = true
    else if itemSelected.id = "RemoveHistoryMenuItem"
      m.top.removeFromHistorySelected = true
    else if itemSelected.id = "ChannelMenuItem"
      'on selecting this menu, it is removing the detailScreen from screen stack, so roku negative audio sound is played,
      'To play Roku positive audio sound, channelMenuSelected is handled in onKeyEvent.
      m.isChannelMenuSelected = true
    else if itemSelected.id = "signUpMenuItem"
      m.top.signUpButtonSelected = true
    end if
  end if
End Function


Function onRelatedContentChange()
  tubiLog("DetailScreen.onRelatedContentChange")
  if m.top.relatedContent <> invalid and m.top.relatedContent.getChildCount() > 0
    m.RelatedContentGroup.visible = true
    ' To force a single row in postergrid, set the columns
    m.RelatedGrid.numColumns = m.top.relatedContent.getChildCount()
    m.RelatedGrid.jumpToItem = m.RelatedGrid.itemFocused
  else
    m.RelatedContentGroup.visible = false
    if m.RelatedContentGroup.isInFocusChain()
      focusMenu()
    end if
  end if
End Function


Function onRelatedContentSelected()
  selectedContent = m.RelatedGrid.content.getChild(m.RelatedGrid.itemSelected)
  handleRelatedContentSelected(selectedContent, m.RelatedGrid.itemSelected)
End Function


' @selectedContent: roSGNode, ContentNode that was selected from the RelatedGrid
' @postion: integer, the horizontal position of the content in the RelatedGrid
Function handleRelatedContentSelected(selectedContent, position)
  m.relatedHasFocus = false

  'set the component info so it can be used in navigate_to_page event
  col = m.RelatedGrid.itemSelected + 1
  row = 1
  m.top.trackingComponentInfo = {
    componentType: "related_component"
      componentValues: {
        content_tile: m.Tracking.getAnalyticsTile(selectedContent, col, row)
      }
  }

  m.top.relatedContentSelected = position
End Function


Function onRelatedItemFocused()
  tubiLog("DetailScreen.onRelatedItemFocused")
  if m.RelatedGrid.content <> invalid
    m.top.stopVideoPreview = true
    ' force a background update
    m.top.backgroundUriList = m.top.backgroundUriList

    focusedContent = m.RelatedGrid.content.getChild(m.RelatedGrid.itemFocused)
    if focusedContent <> invalid
      m.RelatedTitle.text = focusedContent.title
    end if

    col = m.RelatedGrid.itemFocused + 1
    row = 1
    videoId = m.top.content.id.toInt()

    ' trigger navigate_within_page events in ContentController
    if m.relatedHasFocus = true
      m.top.navigateWithinPageInfo = {
        pageOneof: m.Tracking.getAnalyticsPage("video_page", {video_id: videoId} )
        componentOneof: m.Tracking.getAnalyticsComponent("related_component", m.oldYmalComponent) 'category_list_component doesn't exist in protos
        means_of_navigation: "BUTTON"  'MeansOfNavigation enum
        vertical_location: row '1 based index
        vertical_location_mode: "INDEX"  'LocationMode enum
        horizontal_location: col
        horizontal_location_mode: "INDEX"  'LocationMode enum
      }
      m.oldYmalComponent = {
        content_tile: m.Tracking.getAnalyticsTile(focusedContent, col, row)
      }
    else
      m.oldYmalComponent = {
        content_tile: m.Tracking.getAnalyticsTile(focusedContent, col, row)
      }
    end if
    m.relatedHasFocus = true
  end if
End Function


'''''''''''''''''''''''
' onKeyEvent
'
' Hijack any back button presses before they make it to the screen stack if we are waiting for a server
' response from any of add/remove queue/history so that we make sure the category screen can update with new user category content
Function onKeyEvent(key As String, press As Boolean) as Boolean
  tubiLog("DetailScreen.onKeyEvent key = " + key)
  if press then
    if key = "back" or key = "left"
      if not m.top.isWaitingForServerResponse
        m.top.backButtonPressed = true
      end if
      return true
    ' Down presses arrive here if not consumed by the menu, meaning it's already at the bottom button
    else if key = "down"
      if m.Menu.isInFocusChain() = true and m.RelatedContentParentGroup.visible = true and m.RelatedContentGroup.visible = true then
        focusRelated()
        return true
      else if m.Info.isInFocusChain()
        focusMenu()
        return true
      end if
    else if key = "up"
      if m.RelatedGrid.isInFocusChain()
        focusMenu()
        return true
      else if m.Menu.isInFocusChain() and m.Info.isDescriptionEllipsized
        focusInfo()
        return true
      end if
    else if key = "OK"
      if m.isChannelMenuSelected = true
        m.isChannelMenuSelected = false
        m.top.channelSelected = true
      end if
      '//ensure this keypress is captured so the default Roku positive audio sound is played.
      return true
    else if key = "play"
      handlePlayInput()
      return true
    end if
  end if

  return false
End Function


Function focusMenu(immediately=false)
  m.focusTarget = m.Menu
  if immediately
    m.AnimationGroup.translation = [0,0]
    m.RelatedContentGroup.opacity = 0.2
    m.Info.opacity = 1.0
  else
    slideTo(m.AnimationGroup, [0,0], m.focusAnimationDuration)
    animate(m.RelatedContentGroup, { opacity: 0.2, duration: m.focusAnimationDuration})
    animate(m.Info, { opacity: 1.0, duration: m.focusAnimationDuration})
  end if
  if m.top.isInFocusChain()
    m.Menu.setFocus(true)
    m.relatedHasFocus = false
  end if
End Function


Function focusRelated()
  m.focusTarget = m.RelatedGrid
  if m.top.isInFocusChain()
    m.RelatedGrid.setFocus(true)
  end if
  slideTo(m.AnimationGroup, [0,-392], m.focusAnimationDuration)
  animate(m.RelatedContentGroup, { opacity: 1.0, duration: m.focusAnimationDuration })
  animate(m.Info, { opacity: 0.2, duration: m.focusAnimationDuration })
End Function


Function focusInfo()
  m.focusTarget = m.Info
  if m.top.isInFocusChain()
    m.Info.setFocus(true)
  end if
End Function


Function onTransportVoiceRequest(msg)
  inputInfo = msg.getData()
  command = ""
  if inputInfo <> invalid and inputInfo.command <> invalid
    command = inputInfo.command
  end if
  tubiLog("DetailScreen.onTransportVoiceRequest " + command)

  response = "unhandled"
  if command = "play"
    handlePlayInput()
    response = "success"
  else if command = "ok"
    if m.Menu.isInFocusChain() = true
      selection = m.Menu.content.getChild(m.Menu.itemFocused)
      handleMenuItemSelected(selection)
      response = "success"
    else if m.RelatedGrid.isInFocusChain() = true
      selectedContent = m.RelatedGrid.content.getChild(m.RelatedGrid.itemFocused)
      handleRelatedContentSelected(selectedContent, m.RelatedGrid.itemFocused)
      response = "success"
    end if
  end if

  inputInfo.response = response
  m.top.transportVoiceResponse = inputInfo
End Function


Function handlePlayInput()
  itemFocused = m.Menu.content.getChild(m.Menu.itemFocused)
  m.top.stopVideoPreview = true
  if itemFocused.id = "PlayMenuItem" and m.Menu.isInFocusChain() = true
    m.top.playSelected = true
  else if itemFocused.id = "WatchTrailerMenuItem" and m.Menu.isInFocusChain() = true
    m.top.watchTrailerSelected = true
  else if m.RelatedGrid.isInFocusChain() = true
    selectedContent = m.RelatedGrid.content.getChild(m.RelatedGrid.itemFocused)
    m.top.relatedContentToPlay = selectedContent
  else
    m.top.resumeSelected = true
  end if
End Function