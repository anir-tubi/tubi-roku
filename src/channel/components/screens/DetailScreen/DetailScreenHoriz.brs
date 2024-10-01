Function init()
  m.constants = getConstantsFromGlobal()
  m.Tracking = TubiTrackingInfo(m.constants)
  m.NodeHelpers = TubiNodeHelpers()
  m.PageGroup = m.top.findNode("PageGroup")
  m.PageGroup.translation = [m.constants.ui.translations.marginX, 0]
  m.Info = m.top.findNode("DetailInfoPanel")
  m.Menu = m.top.findNode("Menu")
  m.Menu.itemClippingRect = {
    height: 600.0
    width: 1732.0
    x: 0.0
    y: 0.0
  }

  m.defaultMenuWidth = m.Menu.itemSize[0]
  m.ResumeMenuItem = m.top.findNode("ResumeMenuItem")
  m.PlayMenuItem = m.top.findNode("PlayMenuItem")
  m.LikeMenuItem = m.top.findNode("LikeMenuItem")
  m.DislikeMenuItem = m.top.findNode("DislikeMenuItem")
  m.EpisodesMenuItem = m.top.findNode("EpisodesMenuItem")
  m.AddQueueMenuItem = m.top.findNode("AddQueueMenuItem")
  m.RemoveQueueMenuItem = m.top.findNode("RemoveQueueMenuItem")
  m.RemoveHistoryMenuItem = m.top.findNode("RemoveHistoryMenuItem")
  m.ChannelMenuItem = m.top.findNode("ChannelMenuItem")
  m.WatchTrailerMenuItem = m.top.findNode("WatchTrailerMenuItem")
  m.signUpMenuItem = m.top.findNode("signUpMenuItem")

  m.RelatedContentParentGroup = m.top.findNode("RelatedContentParentGroup")
  m.RelatedContentGroup = m.RelatedContentParentGroup.findNode("RelatedContentGroup")
  m.RelatedGrid = m.top.findNode("RelatedGrid")
  m.RelatedTitle = m.top.findNode("RelatedTitle")
  m.RelatedRowLabel = m.top.findNode("RelatedRowLabel")
  m.AnimationGroup = m.top.findNode("AnimationGroup")

  m.RelatedGrid.itemSize = m.constants.ui.imageSizes.largePoster
  m.menuFocused = false

  'These are used to avoid sending the component_interaction event with toggle_off event when user selected an item from the main/secondary menu.
  m.mainMenuSelected = false

  m.Menu.observeFieldScoped("focusedChild", "onMenuFocusChange")

  m.top.observeFieldScoped("removeSignupButton", "onRemoveSignupButton")
  m.top.observeFieldScoped("length", "onLengthChange")
  m.top.observeFieldScoped("isSeries", "onIsSeries")
  m.top.observeFieldScoped("isInKidsMode", "onIsInKidsMode")
  m.top.observeFieldScoped("isBookmark", "onIsBookmark")
  m.top.observeFieldScoped("likeDislikeState", "onLikeDislikeStateChanged")
  m.top.observeFieldScoped("availabilityType", "onAvailabilityTypeChange")
  m.top.observeFieldScoped("isHistory", "onIsHistory")
  m.top.observeFieldScoped("isChannelItem", "onIsChannel")
  m.top.observeFieldScoped("resumePoint", "onResumePointChange")
  m.top.observeFieldScoped("hasTrailer", "onHasTrailer")
  m.top.observeFieldScoped("focusedChild", "onScreenFocusChange")
  m.top.observeFieldScoped("isLoading", "onIsLoading")
  m.top.observeFieldScoped("disableBookmarks", "onDisableBookmarksChange")
  m.top.observeFieldScoped("transportVoiceRequest", "onTransportVoiceRequest")

  m.top.observeFieldScoped("stringSignUpButton", "onStringChange")
  m.top.observeFieldScoped("stringQueueButton", "onStringChange")
  m.top.observeFieldScoped("stringNoQueueButton", "onStringChange")
  m.top.observeFieldScoped("stringChannelButton", "onStringChange")
  m.top.observeFieldScoped("stringNoHistoryButton", "onStringChange")
  m.top.observeFieldScoped("stringDislikeButton", "onStringChange")
  m.top.observeFieldScoped("stringLikeButton", "onStringChange")
  m.top.observeFieldScoped("stringPlayButton", "onStringChange")

  m.Menu.observeFieldScoped("itemSelected", "onMenuItemSelected")
  m.Menu.observeFieldScoped("itemFocused", "onMenuItemFocused")
  m.top.observeFieldScoped("relatedContent", "onRelatedContentChange")
  m.RelatedGrid.observeFieldScoped("itemSelected", "onRelatedContentSelected")
  m.RelatedGrid.observeFieldScoped("itemFocused", "onRelatedItemFocused")
  m.Info.observeFieldScoped("descriptionSelected", "onDescriptionSelected")

  setInitialMenuItems()

  setDetailStrings()
  m.focusAnimationDuration = 0.4

  ' Used to send NavigateWithinPageInfo state values as appropriate.Only send when the menu is already
  ' has focus, not when it gains focus.
  m.oldFocusedMenuAnalyticsSection = invalid

  ' modal popup to show full, scrollable description
  m.descriptionModal = invalid

  'set initial tracking values
  m.top.trackingPageInfo = {
    pageType: "video_page"
    pageValues: {
      video_id: 0
    }
  }

  ' Used to determine if navigate_within_page events should be sent. Only send when the related content already
  ' has focus, not when it gains focus.
  m.relatedHasFocus = false

  ' isChannelMenuSelected variable is used for handling the channel selection from detail menu
  m.isChannelMenuSelected = false

  m.top.screenLevel = m.constants.ui.screenLevels.detailScreen
  m.top.isStackable = true
  m.top.handlesTransportVoiceRequests = true

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.RelatedTitle, typographyConstants.ids.bodyMedium)

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
    m.RelatedGrid.focusBitmapBlendColor = theme.focusedColor
    m.RelatedTitle.color = theme.primaryTextColor
    m.Menu.focusBitmapBlendColor = theme.focusedColor
    m.Menu.focusFootprintBlendColor = theme.neutralColor2
  end if
End Function


Function setDetailStrings()
  m.PlayMenuItem.title = getTranslation("screenDetails_button_play")
  m.PlayMenuItem.analyticsButtonValue = m.Tracking.detailScreenMenuItemMap[m.PlayMenuItem.id]

  m.LikeMenuItem.title = getTranslation("screenDetails_button_likeIt")
  m.LikeMenuItem.analyticsButtonValue = m.Tracking.detailScreenMenuItemMap[m.LikeMenuItem.id]

  m.DislikeMenuItem.title = getTranslation("screenDetails_button_notForMe")
  m.DislikeMenuItem.analyticsButtonValue = m.Tracking.detailScreenMenuItemMap[m.DislikeMenuItem.id]

  m.ResumeMenuItem.title = getTranslation("screenDetails_button_resume_playing")
  m.ResumeMenuItem.analyticsButtonValue = m.Tracking.detailScreenMenuItemMap[m.ResumeMenuItem.id]

  m.EpisodesMenuItem.title = getTranslation("screenDetails_button_episodes")
  m.EpisodesMenuItem.analyticsButtonValue = m.Tracking.detailScreenMenuItemMap[m.EpisodesMenuItem.id]

  m.WatchTrailerMenuItem.title = getTranslation("screenDetails_button_trailer")
  m.WatchTrailerMenuItem.analyticsButtonValue = m.Tracking.detailScreenMenuItemMap[m.WatchTrailerMenuItem.id]

  m.AddQueueMenuItem.title = getTranslation("screenDetails_button_queue")
  m.AddQueueMenuItem.analyticsButtonValue = m.Tracking.detailScreenMenuItemMap[m.AddQueueMenuItem.id]

  m.RemoveQueueMenuItem.title = getTranslation("screenDetails_button_noQueue")
  m.RemoveQueueMenuItem.analyticsButtonValue = m.Tracking.detailScreenMenuItemMap[m.RemoveQueueMenuItem.id]

  m.RemoveHistoryMenuItem.title = getTranslation("screenDetails_button_noHistory")
  m.RemoveHistoryMenuItem.analyticsButtonValue = m.Tracking.detailScreenMenuItemMap[m.RemoveHistoryMenuItem.id]

  RelatedRowLabelContent = m.top.findNode("RelatedRowLabelContent")
  RelatedRowLabelContent.title = getTranslation("screenDetails_relatedTitles")

End Function


Function onStringChange(message)
  sButtonStringId = message.GetField()
  sButtonText = message.GetData()
  changeButtonText(sButtonStringId, sButtonText)
End Function


Function changeButtonText(sButtonStringId, sButtonText)
  stringNode = invalid

  if sButtonStringId = "stringQueueButton"
    stringNode = m.AddQueueMenuItem

    if sButtonText = getTranslation("screenDetails_button_queue")
      stringNode.analyticsButtonValue = m.Tracking.detailScreenMenuItemMap[m.AddQueueMenuItem.id]
      stringNode.iconUrl = "pkg:/images/icon-add-to-queue.webp"
    else
      stringNode.analyticsButtonValue = m.Tracking.detailScreenMenuItemMap[m.constants.ui.detailScreenMenuItemIds.setReminderMenuItem]
      stringNode.iconUrl = "pkg:/images/set-reminder.webp"
    end if

  else if sButtonStringId = "stringNoQueueButton"
    stringNode = m.RemoveQueueMenuItem

    if sButtonText = getTranslation("screenDetails_button_noQueue")
      stringNode.analyticsButtonValue = m.Tracking.detailScreenMenuItemMap[m.RemoveQueueMenuItem.id]
      stringNode.iconUrl = "pkg:/images/icon-remove-from-queue.webp"
    else
      stringNode.analyticsButtonValue = m.Tracking.detailScreenMenuItemMap[m.constants.ui.detailScreenMenuItemIds.removeReminderMenuItem]
      stringNode.iconUrl = "pkg:/images/reminder-set.webp"
    end if

  else if sButtonStringId = "stringChannelButton"
    stringNode = m.ChannelMenuItem
  else if sButtonStringId = "stringNoHistoryButton"
    stringNode = m.RemoveHistoryMenuItem
  else if sButtonStringId = "stringSignUpButton"
    stringNode = m.signUpMenuItem
    stringNode.isPrimaryButton = true
  else if sButtonStringId = "stringDislikeButton"
    stringNode = m.DislikeMenuItem

    if sButtonText = getTranslation("screenDetails_button_removeRating")
      stringNode.iconUrl = "pkg:/images/icon-disliked.webp"
    else
      stringNode.iconUrl = "pkg:/images/icon-dislike.webp"
    end if

  else if sButtonStringId = "stringLikeButton"
    stringNode = m.LikeMenuItem

    if sButtonText = getTranslation("screenDetails_button_removeRating")
      stringNode.iconUrl = "pkg:/images/icon-liked.webp"
    else
      stringNode.iconUrl = "pkg:/images/icon-like.webp"
    end if

  else if sButtonStringId = "stringPlayButton"
    stringNode = m.PlayMenuItem

    if sButtonText = getTranslation("screenDetails_button_startOver")
      stringNode.isPrimaryButton = false
      stringNode.analyticsButtonValue = m.Tracking.detailScreenMenuItemMap[m.constants.ui.detailScreenMenuItemIds.startFromBeginningMenuItem]
    else
      stringNode.isPrimaryButton = true
      stringNode.analyticsButtonValue = m.Tracking.detailScreenMenuItemMap[m.PlayMenuItem.id]
    end if

  else if sButtonStringId = "stringResumeButton"
    stringNode = m.ResumeMenuItem
    stringNode.isPrimaryButton = true
  end if

  if stringNode <> invalid
    stringNode.title = sButtonText
    updateMenuWidths()
  end if

End Function


Function updateMenuWidths()
  colWidths = []
  for i = 0 to m.Menu.content.getChildCount() - 1
    item = m.Menu.content.GetChild(i)
    if item.isPrimaryButton = true
      ' Adjust the width of the menu if text of the button is too long for the default width. Mostly spanish text are generally longer in length.
      tempMenuItem = CreateObject("roSGNode", "DetailHorizMenuItem")
      tempMenuItem.itemContent = item

      potentialWidth = tempMenuItem.calculatedTextWidth + 64 '32 left padding + 32 right padding
      if potentialWidth > m.defaultMenuWidth
        colWidths[i] = potentialWidth
      end if
    else
      colWidths[i] = m.defaultMenuWidth

    end if
  end for

  m.Menu.update({"columnWidths": colWidths})
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

  ' Avoid refocusing the menu again if it is already in focus.
  ' So that we do not fire unnecessary focus analytics events.
  ' Since we add and remove menu items like during when we click remove from history button.
  if m.Menu.isInFocusChain() = false
    focusMenu(true)
  end if
End Function


Function onScreenFocusChange()
  tubiLog("DetailScreen.onScreenFocusChange")

  if m.top.hasFocus() = true

    'After Instant Resume, when pressing back from one detail screen to another detail screen via YMAL
    'related content(YMAL) thumbnails are not loading. Resetting relatedContent node fixes the issue.
    relatedContent = m.top.relatedContent
    m.top.relatedContent = invalid
    m.top.relatedContent = relatedContent

    if m.focusTarget <> invalid
      m.focusTarget.setFocus(true)
      if m.focusTarget.isSameNode(m.Menu) = true
        focusedItem = m.Menu.content.getChild(m.Menu.itemFocused)
        if focusedItem <> invalid
          setComponentInteractionEventForMenu("TOGGLE_ON", focusedItem)
        end if
      end if
    end if

    'determine if the content should be refreshed
    content = m.top.content
    if content <> invalid AND content.isSubtype("DeeplinkContentNode") = false
      ' only refresh if we are not in the process of handling a deeplink (input or regular).
      ' DeeplinkContentNodes are just temporary content nodes and will always seem like
      ' they should be refreshed, but there is no need to refresh them since we will fetch the
      ' content for them always.
      if shouldRefresh(m.top.content) = true
        m.top.refreshContent = true
      end if

      if shouldRefresh(m.top.relatedContent) = true
        m.RelatedContentGroup.visible = false
        m.top.refreshRelatedContent = true
      end if

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

  if resumeIndex = -1 AND m.top.resumePoint > 0
    menuItems.insertChild(m.ResumeMenuItem, 0)
  else if resumeIndex > -1 AND m.top.resumePoint = 0
    menuItems.removeChildIndex(resumeIndex)
    stringPlayButton = getTranslation("screenDetails_button_play")
    changeButtonText("stringPlayButton", stringPlayButton)
    m.PlayMenuItem.iconUrl = "pkg:/images/icon-play.webp"
  end if

  'keep the sign up button at the 2 nd place
  signUpIndex = m.NodeHelpers.getChildIndexById(menuItems, m.signUpMenuItem.id)
  if signUpIndex > -1 AND signUpIndex <> 1
    menuItems.removeChildIndex(signUpIndex)
    menuItems.insertChild(m.signUpMenuItem, 1)
  end if

  m.Menu.content = menuItems
  stringResumeButton = getTranslation("screenDetails_button_resume_playing")
  changeButtonText("stringResumeButton", stringResumeButton)
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


Function onLikeDislikeStateChanged()
  changeLikeDislikeButtonText()
End Function


Function changeLikeDislikeButtonText()
  sButtonText = ""
  sButtonId = ""

  if m.top.likeDislikeState = m.constants.ui.likeDislikeStates.liked
    '//The Like State is "liked", so display liked state
    sButtonText = getTranslation("screenDetails_button_removeRating")
    sButtonId = m.likeMenuItem.id
    m.likeMenuItem.analyticsButtonValue = m.Tracking.detailScreenMenuItemMap[m.constants.ui.detailScreenMenuItemIds.likeRemoveRatingMenuItem]
    m.likeMenuItem.iconUrl = "pkg:/images/icon-liked.webp"
    sButtonId = "stringLikeButton"
    changeButtonText(sButtonId, sButtonText)

    sButtonText = getTranslation("screenDetails_button_notForMe")
    m.dislikeMenuItem.analyticsButtonValue = m.Tracking.detailScreenMenuItemMap[m.dislikeMenuItem.id]
    m.dislikeMenuItem.iconUrl = "pkg:/images/icon-dislike.webp"
    sButtonId = "stringDislikeButton"
    changeButtonText(sButtonId, sButtonText)

  else if m.top.likeDislikeState = m.constants.ui.likeDislikeStates.disliked
    '//The Like State is "disliked", so display disliked state
    sButtonText = getTranslation("screenDetails_button_removeRating")
    sButtonId = m.DislikeMenuItem.id
    m.DislikeMenuItem.analyticsButtonValue = m.Tracking.detailScreenMenuItemMap[m.constants.ui.detailScreenMenuItemIds.dislikeRemoveRatingMenuItem]
    m.DislikeMenuItem.iconUrl = "pkg:/images/icon-disliked.webp"
    sButtonId = "stringDislikeButton"
    changeButtonText(sButtonId, sButtonText)

    sButtonText = getTranslation("screenDetails_button_likeIt")
    m.likeMenuItem.analyticsButtonValue = m.Tracking.detailScreenMenuItemMap[m.likeMenuItem.id]
    m.likeMenuItem.iconUrl = "pkg:/images/icon-like.webp"
    sButtonId = "stringLikeButton"
    changeButtonText(sButtonId, sButtonText)
  else if m.top.likeDislikeState = m.constants.ui.likeDislikeStates.changing
    sButtonText = getTranslation("screenDetails_button_changingRating")
  else
    focused = m.Menu.content.getChild(m.Menu.itemFocused)

    if focused.id = m.likeMenuItem.id
      sButtonText = getTranslation("screenDetails_button_likeIt")
      m.likeMenuItem.analyticsButtonValue = m.Tracking.detailScreenMenuItemMap[m.likeMenuItem.id]
      m.likeMenuItem.iconUrl = "pkg:/images/icon-like.webp"
      sButtonId = "stringLikeButton"
    else if focused.id = m.dislikeMenuItem.id
      sButtonText = getTranslation("screenDetails_button_notForMe")
      m.dislikeMenuItem.analyticsButtonValue = m.Tracking.detailScreenMenuItemMap[m.dislikeMenuItem.id]
      m.dislikeMenuItem.iconUrl = "pkg:/images/icon-dislike.webp"
      sButtonId = "stringDislikeButton"
    end if

    changeButtonText(sButtonId, sButtonText)
  end if

End Function


Function onIsHistory()
  tubiLog("DetailScreen.onIsHistory")

  bHasHistory = m.top.isHistory

  if bHasHistory = false
    'if removing from history, remove the resume button
    resumeIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.ResumeMenuItem.id)
    addRemoveMenuItem(bHasHistory, resumeIndex)
  end if

  if bHasHistory = false
    m.PlayMenuItem.iconUrl = "pkg:/images/icon-play.webp"
  else
    m.PlayMenuItem.iconUrl = "pkg:/images/icon-resume.webp"
  end if

  removeHistoryIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.RemoveHistoryMenuItem.id)
  previousItems = [m.watchTrailerMenuItem, m.dislikeMenuItem, m.likeMenuItem]
  addRemoveMenuItem(bHasHistory, removeHistoryIndex, m.RemoveHistoryMenuItem, previousItems)

  'keep the sign up button at the 2 nd place
  signUpIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.signUpMenuItem.id)
  if signUpIndex > -1 AND signUpIndex <> 1
    addRemoveMenuItem(false, signUpIndex)
    addRemoveMenuItem(true, 1, m.signUpMenuItem, [m.PlayMenuItem])
  end if

  updateMenuWidths()
End Function


Function onIsChannel()
  tubiLog("DetailScreen.onIsChannel")
  channelIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.ChannelMenuItem.id)
  previousItems = [
    m.RemoveHistoryMenuItem
  ]
  addRemoveMenuItem(m.top.isChannelItem, channelIndex, m.ChannelMenuItem, previousItems)
End Function


Function onIsSeries()
  tubiLog("DetailScreenHoriz.onIsSeries")
  episodeListIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.EpisodesMenuItem.id)

  menuItems = [ m.signUpMenuItem, m.PlayMenuItem ]

  m.menuFocused = false
  addRemoveMenuItem(m.top.isSeries, episodeListIndex, m.EpisodesMenuItem, menuItems)
End Function


Function onAvailabilityTypeChange()
  tubiLog("DetailScreen.onAvailabilityTypeChange")
  availabilityType = m.top.availabilityType
  signUpIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.signUpMenuItem.id)
  disLikeIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.DislikeMenuItem.id)
  likeIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.LikeMenuItem.id)

  if UCase(availabilityType) = UCase(m.constants.ui.contentTimings.replay)
    if likeIndex <> invalid
      addRemoveMenuItem(false, likeIndex)
    end if

    if disLikeIndex <> invalid
      addRemoveMenuItem(false, disLikeIndex)
    end if

    if signUpIndex <> invalid
      addRemoveMenuItem(false, signUpIndex)
    end if
  else if UCase(availabilityType) = UCase(m.constants.ui.contentTimings.upcoming)
    if likeIndex <> invalid
      addRemoveMenuItem(false, likeIndex)
    end if

    if disLikeIndex <> invalid
      addRemoveMenuItem(false, disLikeIndex)
    end if

    if signUpIndex <> invalid
      addRemoveMenuItem(false, signUpIndex)
    end if

    playIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.PlayMenuItem.id)
    addRemoveMenuItem(false, playIndex)
  end if

End Function


Function onRemoveSignupButton()
  signUpIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.signUpMenuItem.id)
  ' -1 is been returned when we are not able to find the button.
  if signUpIndex <> -1
    addRemoveMenuItem(false, signUpIndex)

    if m.top.isInKidsMode = false AND m.top.selectedContentType <> m.constants.ui.contentTypes.sportsEvent
      '//add like/dislike button
      nLikeIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.likeMenuItem.id)
      if nLikeIndex = -1
        '//if the like/dislike button does not exist yet, then add it
        addRemoveMenuItem(true, nLikeIndex, m.likeMenuItem, [m.addQueueMenuItem, m.playMenuItem])
      end if

      nDislikeIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.dislikeMenuItem.id)
      if nDislikeIndex = -1
        '//if the like/dislike button does not exist yet, then add it
        addRemoveMenuItem(true, nDislikeIndex, m.dislikeMenuItem, [m.likeMenuItem, m.addQueueMenuItem])
      end if

    end if

  end if

  updateMenuWidths()
End Function


Function onIsInKidsMode(msg)
  isInKidsMode = msg.getData()
  if isLoggedInUser() = false AND isNewUser() = false
    signUpIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.signUpMenuItem.id)
    if isInKidsMode = true AND signUpIndex > -1
      addRemoveMenuItem(false, signUpIndex)
    else if isInKidsMode = false AND signUpIndex = -1
      addRemoveMenuItem(true, 1, m.signUpMenuItem, [m.PlayMenuItem])
    end if
  end if

  if isInKidsMode = true
    '//remove like/dislike button
    dislikeButtonIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.dislikeMenuItem.id)
    addRemoveMenuItem(false, dislikeButtonIndex)

    likeButtonIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.likeMenuItem.id)
    addRemoveMenuItem(false, likeButtonIndex)
  else
    '//add like/dislike button
    nLikeIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.likeMenuItem.id)
    if nLikeIndex = -1
      addRemoveMenuItem(true, nLikeIndex, m.likeMenuItem, [m.addQueueMenuItem])
    end if

    nDislikeIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.dislikeMenuItem.id)
    if nDislikeIndex = -1
      addRemoveMenuItem(true, nDislikeIndex, m.dislikeMenuItem, [m.likeMenuItem])
    end if
  end if
End Function


Function onHasTrailer()
  tubiLog("DetailScreen.onHasTrailer")
  trailerIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.WatchTrailerMenuItem.id)

  previousItems = [
    m.dislikeMenuItem
    m.likeMenuItem
    m.addQueueMenuItem
    m.signUpMenuItem
    m.PlayMenuItem
  ]

  addRemoveMenuItem(m.top.hasTrailer, trailerIndex, m.WatchTrailerMenuItem, previousItems)
End Function


Function onIsLoading()
  tubiLog("DetailScreen.onIsLoading")

  ' we only want to remove the menu on the initial loading of series screens.
  ' In the case of an error, we populate the screen with series metadata (as opposed to episode metadata)
  ' and we don't want to remove the menu once the screen already has metadata.
  if m.top.description = ""
    m.Menu.visible = not m.top.isLoading
  end if

  if m.top.relatedContent <> invalid AND m.top.relatedContent.getChildCount() > 0
    m.RelatedContentGroup.visible = not m.top.isLoading
  else
    m.RelatedContentGroup.visible = false
  end if

  if m.top.isLoading = false
    focusMenu()
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

  if isLoggedInUser() = false AND isNewUser() = false
    menuItems.appendChild(m.signUpMenuItem)
  end if

  menuItems.appendChild(m.AddQueueMenuItem)

  if m.top.selectedContentType <> m.constants.ui.contentTypes.sportsEvent
    menuItems.appendChild(m.LikeMenuItem)
    menuItems.appendChild(m.DislikeMenuItem)
  end if

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
Function addRemoveMenuItem(add, itemIndex, itemToAdd = invalid, previousItems = []) As void
  menuItems = m.Menu.content

  if add = false AND itemIndex > -1
    'menu item exists, so we need to remove it
    m.Menu.content.removeChildIndex(itemIndex)

    refocusMenuItem()

  else if add = true AND itemIndex = -1
    'we don't have menu item, and need to add one
    previousItemIndex = -1
    if itemToAdd <> invalid AND previousItems <> invalid AND previousItems.count() > 0
      for i = 0 to previousItems.count() - 1
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
  m.mainMenuSelected = true
  selection = m.Menu.content.getChild(m.Menu.itemSelected)
  setComponentInteractionEventForMenu("CONFIRM", selection)
  handleMenuItemSelected(selection)
End Function


Function onMenuItemFocused()
  focused = m.Menu.content.getChild(m.Menu.itemFocused)
  focusedMenuAnalyticsSection = ""

  if isNonEmptyString(focused.analyticsButtonValue)
    focusedMenuAnalyticsSection = focused.analyticsButtonValue
  else
    focusedMenuAnalyticsSection = m.Tracking.detailScreenMenuItemMap[focused.id]
  end if

  newFocusedMenuAnalyticsSection = {
    middle_nav_section: focusedMenuAnalyticsSection
  }

  ' If oldFocusedMenuAnalyticsSection exists and is not the same as the focusedMenuItem,
  ' then the user is focusing from another menu item.
  if m.oldFocusedMenuAnalyticsSection <> invalid AND m.oldFocusedMenuAnalyticsSection.middle_nav_section <> focusedMenuAnalyticsSection
    row = 1
    col = m.Menu.itemFocused + 1

    pageInfo = m.top.trackingPageInfo
    m.top.navigateWithinPageInfo = {
      pageOneof: m.Tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
      componentOneof: m.Tracking.getAnalyticsComponent("middle_nav_component", m.oldFocusedMenuAnalyticsSection)
      dest_componentOneof: m.Tracking.getAnalyticsDestinationComponent("dest_middle_nav_component", newFocusedMenuAnalyticsSection)
      means_of_navigation: "SCROLL" 'MeansOfNavigation enum

      vertical_location: row '//The row location of the menu item
      horizontal_location: col '//The column location of the menu item
    }
  end if

  m.oldFocusedMenuAnalyticsSection = newFocusedMenuAnalyticsSection

End Function


Function onMenuFocusChange()
  focusedItem = invalid
  componentInteractionValue = ""

  'This will trigger when menu gains and loses the focus and avoid send the component interaction event with user interaction toggle_on/toggle_off when item is selected.
  if m.top.isInFocusChain() = true
    if m.menuFocused = false AND m.Menu.isInFocusChain() = true AND m.Menu.itemFocused >= 0
      'This block represents menu gaining focus
      m.oldFocusedMenuAnalyticsSection = invalid
      focusedItem = m.Menu.content.getChild(m.Menu.itemFocused)
      componentInteractionValue = "TOGGLE_ON"
    else if m.menuFocused = true AND m.Menu.isInFocusChain() = false AND m.Menu.itemFocused >= 0 AND m.mainMenuSelected = false
      'This block represents menu losing focus
      focusedItem = m.Menu.content.getChild(m.Menu.itemFocused)
      componentInteractionValue = "TOGGLE_OFF"
    end if

    if isNonEmptyString(componentInteractionValue) = true AND focusedItem <> invalid
      setComponentInteractionEventForMenu(componentInteractionValue, focusedItem)
    end if

    m.menuFocused = m.Menu.isInFocusChain()
  end if
End Function


' @itemSelected: roSGNode: ContentNode representing the content that was selected by the user
Function handleMenuItemSelected(itemSelected)
  if itemSelected <> invalid then
    tubiLog("DetailScreen.handleMenuItemSelected" + itemSelected.title)
    if m.top.isVideoPreviewOn = true
      m.top.stopVideoPreview = true
    end if

    if itemSelected.id = m.constants.ui.detailScreenMenuItemIds.resumeMenuItem
      m.top.resumeSelected = true
      m.Menu.jumpToItem = 0 '//reset menu back to the first item after a video is requested to play
    else if itemSelected.id = m.constants.ui.detailScreenMenuItemIds.playMenuItem
      m.top.playSelected = true
      m.Menu.jumpToItem = 0 '//reset menu back to the first item after a video is requested to play
    else if itemSelected.id = m.constants.ui.detailScreenMenuItemIds.likeMenuItem
      if m.likeMenuItem.title = getTranslation("screenDetails_button_changingRating")
        '//If it is still trying to change the rating then do nothing if this button is clicked again
      else if m.top.likeDislikeState = m.constants.ui.likeDislikeStates.liked
        '//when the current item is liked, then remove the like state
        m.top.removeLikeSelected = true
      else
        m.top.likeSelected = true
      end if
    else if itemSelected.id = m.constants.ui.detailScreenMenuItemIds.dislikeMenuItem
      if m.dislikeMenuItem.title = getTranslation("screenDetails_button_changingRating")
        '//If it is still trying to change the rating then do nothing if this button is clicked again
      else if m.top.likeDislikeState = m.constants.ui.likeDislikeStates.disliked
        '//when the current item is disliked, then remove the dislike state
        m.top.removeDislikeSelected = true
      else

        m.top.dislikeSelected = true
      end if

    else if itemSelected.id = m.constants.ui.detailScreenMenuItemIds.watchTrailerMenuItem
      m.top.watchTrailerSelected = true
    else if itemSelected.id = m.constants.ui.detailScreenMenuItemIds.episodesMenuItem
      m.top.episodeListSelected = true
    else if itemSelected.id = m.constants.ui.detailScreenMenuItemIds.addQueueMenuItem
      m.top.addToQueueSelected = true
    else if itemSelected.id = m.constants.ui.detailScreenMenuItemIds.removeQueueMenuItem
      m.top.removeFromQueueSelected = true
    else if itemSelected.id = m.constants.ui.detailScreenMenuItemIds.removeHistoryMenuItem
      m.top.removeFromHistorySelected = true
    else if itemSelected.id = m.constants.ui.detailScreenMenuItemIds.channelMenuItem
      'on selecting this menu, it is removing the detailScreen from screen stack, so roku negative audio sound is played,
      'To play Roku positive audio sound, channelMenuSelected is handled in onKeyEvent.
      m.isChannelMenuSelected = true
    else if itemSelected.id = m.constants.ui.detailScreenMenuItemIds.signUpMenuItem
      m.top.signUpButtonSelected = true
    end if
  end if

  m.mainMenuSelected = false
End Function


Function onRelatedContentChange()
  tubiLog("DetailScreen.onRelatedContentChange")
  relatedContent = m.top.relatedContent
  if relatedContent <> invalid
    if relatedContent.getChildCount() > 0
      m.RelatedContentGroup.visible = true
      ' To force a single row in postergrid, set the columns
      m.RelatedGrid.numColumns = relatedContent.getChildCount()
      m.RelatedGrid.jumpToItem = m.RelatedGrid.itemFocused
    else
      m.RelatedContentGroup.visible = false
      if m.RelatedContentGroup.isInFocusChain() = true
        focusMenu()
      end if
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
  'Need to check NavigateToPageEvent for Upcoming or Replay
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
    if m.top.isVideoPreviewOn = true
      m.top.stopVideoPreview = true
      ' force a background update
      m.top.backgroundUriList = m.top.backgroundUriList
    end if

    focusedContent = m.RelatedGrid.content.getChild(m.RelatedGrid.itemFocused)
    if focusedContent <> invalid
      m.RelatedTitle.text = focusedContent.title

      col = m.RelatedGrid.itemFocused + 1
      row = 1

      pageInfo = m.top.trackingPageInfo

      ' trigger navigate_within_page events in ContentController
      if m.relatedHasFocus = true
        m.top.navigateWithinPageInfo = {
          pageOneof: m.Tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
          componentOneof: m.Tracking.getAnalyticsComponent("related_component", m.oldYmalComponent) 'category_list_component doesn't exist in protos
          means_of_navigation: "SCROLL" 'MeansOfNavigation enum
          vertical_location: row '1 based index
          horizontal_location: col
        }
        m.oldYmalComponent = {
          content_tile: m.Tracking.getAnalyticsTile(focusedContent, col, row)
        }
      else
        m.oldYmalComponent = {
          content_tile: m.Tracking.getAnalyticsTile(focusedContent, col, row)
        }
      end if

    end if

    m.relatedHasFocus = true
  end if
End Function


Function focusMenu(immediately = false)
  m.focusTarget = m.Menu
  if immediately
    m.AnimationGroup.translation = [0, 0]
    m.RelatedContentGroup.opacity = 0.2
    m.Info.opacity = 1.0
  else
    slideTo(m.AnimationGroup, [0, 0], m.focusAnimationDuration)
    animate(m.RelatedContentGroup, {opacity: 0.2, duration: m.focusAnimationDuration})
    animate(m.Info, {opacity: 1.0, duration: m.focusAnimationDuration})
  end if

  if m.top.isInFocusChain() = true
    m.Menu.setFocus(true)
    m.relatedHasFocus = false
  end if

End Function


Function focusRelated()
  m.focusTarget = m.RelatedGrid
  if m.top.isInFocusChain() = true
    m.RelatedGrid.setFocus(true)
  end if

  slideTo(m.AnimationGroup, [0, -392], m.focusAnimationDuration)
  animate(m.RelatedContentGroup, {opacity: 1.0, duration: m.focusAnimationDuration})
  animate(m.Info, {opacity: 0.2, duration: m.focusAnimationDuration})

End Function


Function focusInfo()
  m.focusTarget = m.Info
  if m.top.isInFocusChain() = true
    m.Info.setFocus(true)
  end if
End Function


Function onTransportVoiceRequest(msg)
  inputInfo = msg.getData()
  command = ""
  if inputInfo <> invalid AND inputInfo.command <> invalid
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
  if m.top.isVideoPreviewOn = true
    m.top.stopVideoPreview = true
  end if

  if m.Menu.isInFocusChain() = true AND itemFocused.id = m.constants.ui.detailScreenMenuItemIds.playMenuItem
    m.top.playSelected = true
    m.Menu.jumpToItem = 0 '//reset menu back to the top after a video is requested to play
  else if m.Menu.isInFocusChain() = true AND itemFocused.id = m.constants.ui.detailScreenMenuItemIds.watchTrailerMenuItem
    m.top.watchTrailerSelected = true
  else if m.RelatedGrid.isInFocusChain() = true
    selectedContent = m.RelatedGrid.content.getChild(m.RelatedGrid.itemFocused)
    m.top.relatedContentToPlay = selectedContent
    m.top.relatedContentToPlayUpdated = true
  else
    m.top.resumeSelected = true
    m.Menu.jumpToItem = 0 '//reset menu back to the top after a video is requested to play
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
    if key = "back"
      if not m.top.isWaitingForServerResponse
        m.top.backButtonPressed = true
        return true
      end if
    else if key = "left"
      if m.RelatedGrid.isInFocusChain() = false
        m.top.backButtonPressed = true
        return true
      end if
    ' Down presses arrive here if not consumed by the menu, meaning it's already at the bottom button
    else if key = "down"
      if m.Menu.isInFocusChain() = true AND m.RelatedContentParentGroup.visible = true AND m.RelatedContentGroup.visible = true then
        focusRelated()
        return true
      else if m.Info.isInFocusChain() = true
        focusMenu()
        return true
      end if

    else if key = "up"
      if m.RelatedGrid.isInFocusChain() = true
        focusMenu()
        return true
      else if m.Menu.isInFocusChain() = true AND m.Info.isDescriptionEllipsized = true
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


'Set the componentInteractionInfo value which will pass through to ContentController via DetailScreenHelper.brs
'to fire a component_interaction analytics event.
' @componentInteractionValue: the interaction that the user is having with the focused or selected menu item. Allowed values "TOGGLE_ON", "TOGGLE_OFF", and "CONFIRM".
' @menuItem: Node, DetailMenuItemContentNode for focused, unfocused or selected item of menu or secondary menu.
Function setComponentInteractionEventForMenu(componentInteractionValue, menuItem)
  tubiLog("DetailScreen.setComponentInteractionEventForMenu")
  menuItemId = ""
  middleNavSection = ""
  componentValues = {}

  if menuItem <> invalid
    menuItemId = menuItem.id

    if isNonEmptyString(menuItem.analyticsButtonValue)
      middleNavSection = menuItem.analyticsButtonValue
    else
      middleNavSection = m.Tracking.detailScreenMenuItemMap[menuItemId]
    end if
  end if

  if isNonEmptyString(middleNavSection) = true
    componentValues.middle_nav_section = middleNavSection
  end if

  pageType = ""
  pageValues = {}
  trackingPageInfo = m.top.trackingPageInfo

  if trackingPageInfo <> invalid
    if trackingPageInfo.pagetype <> invalid
      pageType = trackingPageInfo.pagetype
    end if

    if trackingPageInfo.pageValues <> invalid
      pageValues = trackingPageInfo.pageValues
    end if
  end if

  if isNonEmptyString(pageType) = true
    pageOneof = m.Tracking.getAnalyticsPage(pageType, pageValues)
    componentOneof = m.Tracking.getAnalyticsComponent("middle_nav_component", componentValues)

    m.top.componentInteractionInfo = {
      pageOneof: pageOneof
      componentOneof: componentOneof
      user_interaction: componentInteractionValue
    }
  end if
End Function
