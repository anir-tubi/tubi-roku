Function init()
  m.constants = getConstantsFromGlobal()
  Request = TubiRequest(m.constants.settings)
  m.Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, m.Auth)
  m.NodeHelpers = TubiNodeHelpers()
  m.Info = m.top.findNode("DetailInfoPanel")
  m.Menu = m.top.findNode("Menu")
  m.SecondaryMenu = m.top.findNode("SecondaryMenu")
  m.defaultMenuWidth = m.Menu.itemSize[0]
  m.defaultSecondaryMenuY = m.SecondaryMenu.translation[1]
  m.ResumeMenuItem = m.top.findNode("ResumeMenuItem")
  m.PlayMenuItem = m.top.findNode("PlayMenuItem")
  m.LikeMenuItem = m.top.findNode("LikeMenuItem")
  ' // REMOVE BELOW CODE ONCE FIFA WORLD CUP IS DONE
  m.SeeAllGamesMenuItem = m.top.findNode("SeeAllGamesMenuItem")
  m.DislikeMenuItem = m.top.findNode("DislikeMenuItem")
  m.LikeDislikeMenuItem = m.top.findNode("LikeDislikeMenuItem")
  m.EpisodesMenuItem = m.top.findNode("EpisodesMenuItem")
  m.AddQueueMenuItem = m.top.findNode("AddQueueMenuItem")
  m.RemoveQueueMenuItem = m.top.findNode("RemoveQueueMenuItem")
  m.RemoveHistoryMenuItem = m.top.findNode("RemoveHistoryMenuItem")
  m.ChannelMenuItem = m.top.findNode("ChannelMenuItem")
  m.WatchTrailerMenuItem = m.top.findNode("WatchTrailerMenuItem")
  ' fire exposure event when detail screen is
  m.RelatedContentParentGroup = m.top.findNode("RelatedContentParentGroup")
  m.RelatedContentGroup = m.RelatedContentParentGroup.findNode("RelatedContentGroup")
  m.RelatedGrid = m.top.findNode("RelatedGrid")
  m.RelatedTitle = m.top.findNode("RelatedTitle")
  m.RelatedRowLabel = m.top.findNode("RelatedRowLabel")
  m.AnimationGroup = m.top.findNode("AnimationGroup")
  m.signUpMenuItem = m.top.findNode("signUpMenuItem")
  m.signUpMenuItem.iconUrl = "pkg:/images/icon-sign-in.webp"

  m.menuFocused = false
  m.secondaryMenuFocused = false

  'These are used to avoid sending the component_interaction event with toggle_off event when user selected an item from the main/secondary menu.
  m.mainMenuSelected = false
  m.secondaryMenuSelected = false

  m.Menu.observeFieldScoped("focusedChild", "onMenuFocusChange")
  m.SecondaryMenu.observeFieldScoped("focusedChild", "onSecondaryMenuFocusChange")

  m.top.observeFieldScoped("removeSignupButton", "onRemoveSignupButton")
  m.top.observeFieldScoped("stringSignUpButton", "onStringChange")
  m.top.observeFieldScoped("length", "onLengthChange")
  m.top.observeFieldScoped("isSeries", "onIsSeries")
  m.top.observeFieldScoped("availabilityType", "onAvailabilityTypeChange")
  m.top.observeFieldScoped("isInKidsMode", "onIsInKidsMode")
  m.top.observeFieldScoped("isBookmark", "onIsBookmark")
  m.top.observeFieldScoped("likeDislikeState", "onLikeDislikeStateChanged")
  m.top.observeFieldScoped("isHistory", "onIsHistory")
  m.top.observeFieldScoped("isChannelItem", "onIsChannel")
  m.top.observeFieldScoped("resumePoint", "onResumePointChange")
  m.top.observeFieldScoped("hasTrailer", "onHasTrailer")
  m.top.observeFieldScoped("focusedChild", "onScreenFocusChange")
  m.top.observeFieldScoped("isLoading", "onIsLoading")
  m.top.observeFieldScoped("disableBookmarks", "onDisableBookmarksChange")
  m.top.observeFieldScoped("transportVoiceRequest", "onTransportVoiceRequest")

  m.top.observeFieldScoped("stringQueueButton", "onStringChange")
  m.top.observeFieldScoped("stringNoQueueButton", "onStringChange")
  m.top.observeFieldScoped("stringChannelButton", "onStringChange")
  m.top.observeFieldScoped("stringNoHistoryButton", "onStringChange")
  m.top.observeFieldScoped("stringLikeDislikeButton", "onStringChange")
  m.top.observeFieldScoped("stringPlayButton", "onStringChange")


  m.Menu.observeFieldScoped("itemSelected", "onMenuItemSelected")
  m.Menu.observeFieldScoped("itemFocused", "onMenuItemFocused")
  m.SecondaryMenu.observeFieldScoped("itemSelected", "onSecondaryMenuItemSelected")
  m.SecondaryMenu.observeFieldScoped("itemFocused", "onSecondaryMenuItemFocused")
  m.top.observeFieldScoped("relatedContent", "onRelatedContentChange")
  m.RelatedGrid.observeFieldScoped("itemSelected", "onRelatedContentSelected")
  m.RelatedGrid.observeFieldScoped("itemFocused", "onRelatedItemFocused")
  m.Info.observeFieldScoped("descriptionSelected", "onDescriptionSelected")

  m.defaultHeroUri = "pkg:/images/art-blur-background.webp"
  setInitialMenuItems()
  setInitialSecondaryMenuItems()

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
  end if
End Function



Function setDetailStrings()
  m.PlayMenuItem.title = getTranslation("screenDetails_button_play")
  m.PlayMenuItem.analyticsButtonValue = m.Tracking.detailScreenMenuItemMap[m.PlayMenuItem.id]

  m.LikeMenuItem.title = getTranslation("screenDetails_button_like")
  m.LikeMenuItem.analyticsButtonValue = m.Tracking.detailScreenMenuItemMap[m.LikeMenuItem.id]

  m.DislikeMenuItem.title = getTranslation("screenDetails_button_dislike")

  m.DislikeMenuItem.analyticsButtonValue = m.Tracking.detailScreenMenuItemMap[m.DislikeMenuItem.id]

  m.ResumeMenuItem.title = getTranslation("screenDetails_button_resume_playing")
  m.ResumeMenuItem.analyticsButtonValue = m.Tracking.detailScreenMenuItemMap[m.ResumeMenuItem.id]

  m.EpisodesMenuItem.title = getTranslation("screenDetails_button_episodes")
  m.EpisodesMenuItem.analyticsButtonValue = m.Tracking.detailScreenMenuItemMap[m.EpisodesMenuItem.id]

  m.WatchTrailerMenuItem.title = getTranslation("screenDetails_button_trailer")
  m.WatchTrailerMenuItem.analyticsButtonValue = m.Tracking.detailScreenMenuItemMap[m.WatchTrailerMenuItem.id]

  RelatedRowLabelContent = m.top.findNode("RelatedRowLabelContent")
  RelatedRowLabelContent.title = getTranslation("screenDetails_relatedTitles")

  ' // REMOVE BELOW CODE ONCE FIFA WORLD CUP IS DONE
  m.SeeAllGamesMenuItem.title = getTranslation("screenDetails_button_see_all_games")
  m.SeeAllGamesMenuItem.analyticsButtonValue = m.Tracking.detailScreenMenuItemMap[m.SeeAllGamesMenuItem.id]
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
  else if sButtonStringId = "stringLikeDislikeButton"
    stringNode = m.LikeDislikeMenuItem
    setVisibilityOfSecondaryMenu()

    if sButtonText = getTranslation("screenDetails_button_changingRating")
      '//if the rating is changing, then change icon to default like button
      stringNode.iconUrl = "pkg:/images/icon-like.webp"
    end if

  else if sButtonStringId = "stringPlayButton"
    stringNode = m.PlayMenuItem
  end if

  if stringNode <> invalid
    sTextSplitArray = sButtonText.split(";")
    if sTextSplitArray.count() > 1
      stringNode.title = sButtonText.split(";")[0]
      stringNode.badgeText = sButtonText.split(";")[1]
    else
      stringNode.title = sButtonText
      stringNode.badgeText = ""
    end if

    ' Adjust the width of the menu if text of the button is too long for the default width. Mostly spanish text are generally longer in length.
    tempChannelMenuItem = CreateObject("roSGNode", "DetailMenuItem")
    tempChannelMenuItem.itemContent = stringNode

    potentialWidth = tempChannelMenuItem.calculatedTextWidth + tempChannelMenuItem.leftTextPadding + tempChannelMenuItem.rightTextPadding
    if potentialWidth > m.defaultMenuWidth AND potentialWidth > m.Menu.itemSize[0]
      m.Menu.itemSize = [potentialWidth, m.Menu.itemSize[1]]
      '//move SecondaryMenu to ensure it is not overlapping the Menu
      m.SecondaryMenu.translation = [potentialWidth + 200, m.SecondaryMenu.translation[1]]
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
    m.Menu.content.insertChild(m.ResumeMenuItem, 0)
  else if resumeIndex > -1 AND m.top.resumePoint = 0
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


Function onLikeDislikeStateChanged()
  changeLikeDislikeButtonText()
End Function


Function changeLikeDislikeButtonText()
  if m.top.selectedContentType <> m.constants.ui.contentTypes.sportsEvent
    sButtonText = ""
    sIconUrl = ""
    if m.top.likeDislikeState = m.constants.ui.likeDislikeStates.liked OR m.top.likeDislikeState = m.constants.ui.likeDislikeStates.disliked
      if m.top.likeDislikeState = m.constants.ui.likeDislikeStates.liked
        '//The Like State is "liked", so display liked state
        sButtonText = getTranslation("screenDetails_button_liked")
        m.LikeDislikeMenuItem.analyticsButtonValue = m.Tracking.detailScreenMenuItemMap[m.constants.ui.detailScreenMenuItemIds.likeRemoveRatingMenuItem]
        sIconUrl = "pkg:/images/icon-liked.webp"
      else
        '//The Like State is "disliked", so display disliked state
        sButtonText = getTranslation("screenDetails_button_disliked")

        m.LikeDislikeMenuItem.analyticsButtonValue = m.Tracking.detailScreenMenuItemMap[m.constants.ui.detailScreenMenuItemIds.dislikeRemoveRatingMenuItem]
        sIconUrl = "pkg:/images/icon-disliked.webp"
      end if

      if m.Menu.content <> invalid AND m.Menu.itemFocused >= 0

        focusedMenuItem = m.Menu.content.getChild(m.Menu.itemFocused)
        if m.Menu.isInFocusChain() = true AND focusedMenuItem <> invalid AND focusedMenuItem.id = "LikeDislikeMenuItem"
          sButtonText = sButtonText + getTranslation("screenDetails_button_like_instructions")
        end if

      end if

    else if m.top.likeDislikeState = m.constants.ui.likeDislikeStates.changing
      sButtonText = getTranslation("screenDetails_button_changingRating")
      sIconUrl = m.LikeDislikeMenuItem.iconUrl '//Keep the icon as it is while the like state is set to changing
    else
      '//The Like State is nothing so display default state
      sButtonText = ""

      like_dilike_button_title_type = getExperimentResource("roku_notforme_dislike", "roku_notforme_dislike_v2", true).like_dilike_button_title_type

      if like_dilike_button_title_type = "rate_this_title"
        sButtonText = getTranslation("screenDetails_button_rateThisTitle")
      else if like_dilike_button_title_type = "tell_us_what_you_think"
        sButtonText = getTranslation("screenDetails_button_tellUsWhatYouThink")
      else
        sButtonText = getTranslation("screenDetails_button_likeDislike")
      end if

      m.LikeDislikeMenuItem.analyticsButtonValue = m.Tracking.detailScreenMenuItemMap[m.LikeDislikeMenuItem.id]
      sIconUrl = "pkg:/images/icon-like.webp"
    end if

    changeButtonText("stringLikeDislikeButton", sButtonText)
    m.LikeDislikeMenuItem.iconUrl = sIconUrl
    setVisibilityOfSecondaryMenu()
  end if
End Function


Function onIsHistory()
  tubiLog("DetailScreen.onIsHistory")
  'if removing from history, remove the resume button
  resumeIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.ResumeMenuItem.id)
  
  bHasHistory = m.top.isHistory
  if bHasHistory = false
    addRemoveMenuItem(bHasHistory, resumeIndex)
  end if

  if bHasHistory = false
    m.PlayMenuItem.iconUrl = "pkg:/images/icon-play.webp"
  else
    m.PlayMenuItem.iconUrl = "pkg:/images/icon-resume.webp"
  end if

  removeHistoryIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.RemoveHistoryMenuItem.id)
  previousItems = [m.AddQueueMenuItem, m.RemoveQueueMenuItem]
  addRemoveMenuItem(bHasHistory, removeHistoryIndex, m.RemoveHistoryMenuItem, previousItems)
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

  m.menuFocused = false

  '//Change the button order of the signup button depending on isSeries state
  if isLoggedInUser() = false AND isNewUser() = false AND m.top.availabilityType <> m.constants.ui.contentTimings.upcoming

    if isSeries = true AND signUpIndex = 1
      'Remove the signup button at 1st index and make signup button as default for series.
      addRemoveMenuItem(false, signUpIndex)
      addRemoveMenuItem(true, -1, m.signUpMenuItem, [])
      menuItems = [m.PlayMenuItem, m.signUpMenuItem]
    else if isSeries = false AND signUpIndex = 0
      'Add sign up button after the Play button for movies
      addRemoveMenuItem(false, signUpIndex)
      addRemoveMenuItem(true, -1, m.signUpMenuItem, menuItems)
    end if

  end if


  addRemoveMenuItem(m.top.isSeries, episodeListIndex, m.EpisodesMenuItem, menuItems)
End Function


Function onAvailabilityTypeChange()
  tubiLog("DetailScreen.onAvailabilityTypeChange")
  availabilityType = m.top.availabilityType
  menuItems = []
  isTournamentTime = tournamentTimeFrame()
  signUpIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.signUpMenuItem.id)
  likeDisLikeIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.LikeDislikeMenuItem.id)

  if UCase(availabilityType) = UCase(m.constants.ui.contentTimings.replay)
    if likeDisLikeIndex <> invalid
      addRemoveMenuItem(false, likeDisLikeIndex)
    end if

    if signUpIndex <> invalid
      addRemoveMenuItem(false, signUpIndex)
    end if

    menuItems = [m.AddQueueMenuItem]
    if isTournamentTime = "duringTournament" OR isTournamentTime = "preTournament"
      addRemoveMenuItem(true, -1, m.SeeAllGamesMenuItem, menuItems)
    end if
  else if UCase(availabilityType) = UCase(m.constants.ui.contentTimings.upcoming)
    if likeDisLikeIndex <> invalid
      addRemoveMenuItem(false, likeDisLikeIndex)
    end if

    if signUpIndex <> invalid
      addRemoveMenuItem(false, signUpIndex)
    end if

    playIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.PlayMenuItem.id)
    addRemoveMenuItem(false, playIndex)
    menuItems = [m.AddQueueMenuItem]
    if isTournamentTime = "duringTournament" OR isTournamentTime = "preTournament"
      addRemoveMenuItem(true, -1, m.SeeAllGamesMenuItem, menuItems)
    end if
  end if

End Function


Function onRemoveSignupButton()
  signUpIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.signUpMenuItem.id)
  if signUpIndex <> invalid
    addRemoveMenuItem(false, signUpIndex)

    if m.top.isInKidsMode = false AND m.top.selectedContentType <> m.constants.ui.contentTypes.sportsEvent
      '//add like/dislike button
      nLikeIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.LikeDislikeMenuItem.id)
      if nLikeIndex = -1
        '//if the like/dislike button does not exist yet, then add it
        addRemoveMenuItem(true, nLikeIndex, m.LikeDislikeMenuItem, [m.PlayMenuItem])
      end if

    end if

  end if

End Function


Function onIsInKidsMode()
  if isLoggedInUser() = false AND isNewUser() = false
    signUpIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.signUpMenuItem.id)
    if m.top.isInKidsMode = true AND signUpIndex > -1
      addRemoveMenuItem(false, signUpIndex)
    else if m.top.isInKidsMode = false AND signUpIndex = -1
      addRemoveMenuItem(true, signUpIndex, m.signUpMenuItem, [m.PlayMenuItem])
    end if

  end if

  if m.top.isInKidsMode = true
    '//remove like/dislike button
    likeDislikeButtonIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.LikeDislikeMenuItem.id)
    addRemoveMenuItem(false, likeDislikeButtonIndex)
  else
    '//add like/dislike button
    nLikeIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.LikeDislikeMenuItem.id)
    if nLikeIndex = -1
      addRemoveMenuItem(true, nLikeIndex, m.LikeDislikeMenuItem, [m.PlayMenuItem])
    end if
  end if
End Function


Function onHasTrailer()
  tubiLog("DetailScreen.onHasTrailer")
  trailerIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.WatchTrailerMenuItem.id)

  previousItems = [
    m.LikeDislikeMenuItem
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

  if m.top.selectedContentType <> m.constants.ui.contentTypes.sportsEvent
    menuItems.appendChild(m.LikeDislikeMenuItem)
  end if

  menuItems.appendChild(m.AddQueueMenuItem)
  m.Menu.content = menuItems
End Function



''''''''''''''''''''''
' setInitialSecondaryMenuItems
'
' The secondary menu currently only displays the like/dislike options when
'   the "like or dislike" button of the main menu is focused. However, since it is possible other menu items
'   will need a secondary menu, let's set up the secondary menu like how we set up the main menu.
Function setInitialSecondaryMenuItems() As Void
  tubiLog("DetailScreen.setInitialSecondaryMenuItems")
  menuItems = CreateObject("roSGNode", "ContentNode")
  menuItems.appendChild(m.LikeMenuItem)
  menuItems.appendChild(m.DislikeMenuItem)
  m.SecondaryMenu.content = menuItems
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

  if add = false AND itemIndex > -1
    'menu item exists, so we need to remove it
    m.Menu.content.removeChildIndex(itemIndex)

    refocusMenuItem()

  else if add = true AND itemIndex = -1
    'we don't have menu item, and need to add one
    'find the previous item index, and insert the Watch Trailer item one index after
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


' assign the focusedMenuItemAnalyticsIds field with the passed ID and the previous focused ID
Function setNewFocusedId(sCurrentFocusedId)
  sPreviousFocusedId = ""
  if m.top.focusedMenuItemAnalyticsIds.Count() = 2
    sPreviousFocusedId = m.top.focusedMenuItemAnalyticsIds[0]
  end if

  m.top.focusedMenuItemAnalyticsIds = [sCurrentFocusedId, sPreviousFocusedId]
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
  setVisibilityOfSecondaryMenu()
  focused = m.Menu.content.getChild(m.Menu.itemFocused)
  focusedMenuAnalyticsSection = ""

  if focused.id = m.constants.ui.detailScreenMenuItemIds.PlayMenuItem AND m.top.isHistory = true
    'When we have history, considering the play as Start from beginning.
    focusedMenuAnalyticsSection = m.Tracking.detailScreenMenuItemMap[m.constants.ui.detailScreenMenuItemIds.startFromBeginningMenuItem]
  else if isNonEmptyString(focused.analyticsButtonValue)
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
    row = m.Menu.itemFocused + 1
    col = 1

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

  if m.top.likeDislikeState <> m.constants.ui.likeDislikeStates.changing
    '//When the user has liked or disliked content and then moves to or away from the like/dislike button, then change the text to be the focused or unfocused versions
    changeLikeDislikeButtonText()
  end if

End Function


Function onMenuFocusChange(msg)
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


Function onSecondaryMenuFocusChange()
  focusedItem = invalid
  componentInteractionValue = ""

  secondaryMenuIsInFocusChain = m.SecondaryMenu.isInFocusChain()

  if m.secondaryMenuFocused = false AND secondaryMenuIsInFocusChain = true
    'This block executed when SecondaryMenu gains focus.
    if m.SecondaryMenu.itemFocused = -1
      'This block executed when SecondaryMenu gains focus but not item has focus.
      focusedItem = m.SecondaryMenu.content.getChild(0)
    else
      focusedItem = m.SecondaryMenu.content.getChild(m.SecondaryMenu.itemFocused)
    end if

    componentInteractionValue = "TOGGLE_ON"
  else if m.secondaryMenuFocused = true AND secondaryMenuIsInFocusChain = false AND m.secondaryMenuSelected = false
    'This block executed when SecondaryMenu loses focus.
    focusedItem = m.SecondaryMenu.content.getChild(m.SecondaryMenu.itemFocused)
    componentInteractionValue = "TOGGLE_OFF"
  end if

  if isNonEmptyString(componentInteractionValue) = true AND focusedItem <> invalid
    setComponentInteractionEventForMenu(componentInteractionValue, focusedItem)
  end if

  m.secondaryMenuFocused = secondaryMenuIsInFocusChain
End Function


Function onSecondaryMenuItemSelected()
  m.secondaryMenuSelected = true
  selection = m.SecondaryMenu.content.getChild(m.SecondaryMenu.itemSelected)
  if isNonEmptyString(selection.analyticsButtonValue) = true
    setComponentInteractionEventForMenu("CONFIRM", selection)
  end if
  handleMenuItemSelected(selection)
End Function


Function onSecondaryMenuItemFocused()
  focused = m.SecondaryMenu.content.getChild(m.SecondaryMenu.itemFocused)
  focusedSecondaryMenuAnalyticsSection = m.Tracking.detailScreenMenuItemMap[focused.id]

  newFocusedSecondaryMenuAnalyticsSection = {
    middle_nav_section: focusedSecondaryMenuAnalyticsSection
  }

  ' If oldFocusedSecondaryMenuAnalyticsSection exists and is not the same as the focusedMenuItem,
  ' then the user is focusing from another menu item.
  if m.oldFocusedSecondaryMenuAnalyticsSection <> invalid AND m.oldFocusedSecondaryMenuAnalyticsSection.middle_nav_section <> focusedSecondaryMenuAnalyticsSection
    row = m.SecondaryMenu.itemFocused + 1
    col = 1

    pageInfo = m.top.trackingPageInfo
    m.top.navigateWithinPageInfo = {
      pageOneof: m.Tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
      componentOneof: m.Tracking.getAnalyticsComponent("middle_nav_component", m.oldFocusedSecondaryMenuAnalyticsSection)
      dest_componentOneof: m.Tracking.getAnalyticsDestinationComponent("dest_middle_nav_component", newFocusedSecondaryMenuAnalyticsSection)
      means_of_navigation: "SCROLL" 'MeansOfNavigation enum

      vertical_location: row '//The row location of the menu item
      horizontal_location: col '//The column location of the menu item
    }
  end if

  m.oldFocusedSecondaryMenuAnalyticsSection = newFocusedSecondaryMenuAnalyticsSection

End Function


' checks if the secondary menu should be seen and then perform the proper actions if the menu should be seen or not.
' @return boolean, Should the menu be seen? (The function will ensure the menu is made visible if it should and not if it should not.)
Function setVisibilityOfSecondaryMenu()
  result = false
  itemFocused = m.Menu.content.getChild(m.Menu.itemFocused)
  if m.SecondaryMenu.isInFocusChain() = true OR (m.Menu.isInFocusChain() = true AND itemFocused <> invalid AND itemFocused.id = "LikeDislikeMenuItem" AND m.top.likeDislikeState <> m.constants.ui.likeDislikeStates.liked AND m.top.likeDislikeState <> m.constants.ui.likeDislikeStates.disliked AND m.top.likeDislikeState <> m.constants.ui.likeDislikeStates.changing)
    alignSecondaryMenuWithMenu()

    m.SecondaryMenu.visible = true
    m.Menu.focusFootprintBitmapUri = "pkg://images/menu-focus-$$RES$$.9.png"

    theme = getThemeFromGlobal()

    if theme <> invalid
      m.Menu.focusFootprintBlendColor = theme.selectedListItemColor
    end if

    result = true
  else
    m.SecondaryMenu.visible = false
    m.Menu.focusFootprintBitmapUri = ""
  end if

  return result
End Function


' Properly Align SecondaryMenu with the like/dislike button in the Menu
Function alignSecondaryMenuWithMenu()
  likeDislikeButtonIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.LikeDislikeMenuItem.id)
  boundingBoxLikeDislike = m.Menu.ancestorSubBoundingRect("item" + likeDislikeButtonIndex.toStr() + "_0", m.Menu)
  nMenuHeight = m.Menu.itemSize[1] + m.Menu.itemSpacing[1]
  nSubMenuLocation = boundingBoxLikeDislike.y / nMenuHeight
  if nSubMenuLocation = 0
    m.SecondaryMenu.translation = [m.SecondaryMenu.translation[0], m.Menu.translation[1]]
  else
    m.SecondaryMenu.translation = [m.SecondaryMenu.translation[0], m.defaultSecondaryMenuY]
  end if

End Function


' @itemSelected: roSGNode: ContentNode representing the content that was selected by the user
Function handleMenuItemSelected(itemSelected)
  if itemSelected <> invalid then
    tubiLog("DetailScreen.handleMenuItemSelected" + itemSelected.title)
    if m.top.isVideoPreviewOn = true
      m.top.stopVideoPreview = true
    end if

    if itemSelected.id = "ResumeMenuItem"
      m.top.resumeSelected = true
      m.Menu.jumpToItem = 0 '//reset menu back to the top after a video is requested to play
    else if itemSelected.id = "PlayMenuItem"
      m.top.playSelected = true
      m.Menu.jumpToItem = 0 '//reset menu back to the top after a video is requested to play
    else if itemSelected.id = "LikeDislikeMenuItem"
      if m.LikeDislikeMenuItem.title = getTranslation("screenDetails_button_changingRating")
        '//If it is still trying to change the rating then do nothing if this button is clicked again
      else if m.top.likeDislikeState = m.constants.ui.likeDislikeStates.liked
        '//when the current item is liked, then remove the like state
        m.top.removeLikeSelected = true
      else if m.top.likeDislikeState = m.constants.ui.likeDislikeStates.disliked
        '//when the current item is disliked, then remove the dislike state
        m.top.removeDislikeSelected = true
      else
        '//if displaying the like or dislike button, then clicking this should not cause a change of like status,
        '//   but it may be confusing to the user if nothing happens, so
        '//   the focus should move to the 2nd menu
        focusSecondaryMenu()
      end if

    else if itemSelected.id = "LikeMenuItem"
      m.top.likeSelected = true
      if isLoggedInUser() = true
        '//if the user is logged in, then focus back onto the main menu
        focusMenu()
      end if

    else if itemSelected.id = "DislikeMenuItem"
      m.top.dislikeSelected = true
      if isLoggedInUser() = true
        '//if the user is logged in, then focus back onto the main menu
        focusMenu()
      end if

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
    ' // REMOVE BELOW CODE ONCE FIFA WORLD CUP IS DONE
    else if itemSelected.id = "SeeAllGamesMenuItem"
      m.top.seeAllGamesSelected = true
    end if
  end if

  m.mainMenuSelected = false
  m.secondaryMenuSelected = false
End Function


Function onRelatedContentChange()
  tubiLog("DetailScreen.onRelatedContentChange")
  if m.top.relatedContent <> invalid AND m.top.relatedContent.getChildCount() > 0
    m.RelatedContentGroup.visible = true
    ' To force a single row in postergrid, set the columns
    m.RelatedGrid.numColumns = m.top.relatedContent.getChildCount()
    m.RelatedGrid.jumpToItem = m.RelatedGrid.itemFocused
  else
    m.RelatedContentGroup.visible = false
    if m.RelatedContentGroup.isInFocusChain() = true
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
    end if

    col = m.RelatedGrid.itemFocused + 1
    row = 1

    pageInfo = m.top.trackingPageInfo

    ' trigger navigate_within_page events in ContentController
    if m.relatedHasFocus = true
      m.top.navigateWithinPageInfo = {
        pageOneof: m.Tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
        componentOneof: m.Tracking.getAnalyticsComponent("related_component", m.oldYmalComponent) 'category_list_component doesn't exist in protos
        means_of_navigation: "BUTTON" 'MeansOfNavigation enum
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


Function focusSecondaryMenu()
  m.focusTarget = m.SecondaryMenu
  if m.top.isInFocusChain() = true
    m.SecondaryMenu.jumpToItem = 0 'reset focus to the 1st menu item
    m.SecondaryMenu.setFocus(true)
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

  setVisibilityOfSecondaryMenu()
End Function


Function focusInfo()
  m.focusTarget = m.Info
  if m.top.isInFocusChain() = true
    m.Info.setFocus(true)
  end if

  setVisibilityOfSecondaryMenu()
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

  if m.Menu.isInFocusChain() = true AND itemFocused.id = "PlayMenuItem"
    m.top.playSelected = true
    m.Menu.jumpToItem = 0 '//reset menu back to the top after a video is requested to play
  else if m.Menu.isInFocusChain() = true AND itemFocused.id = "WatchTrailerMenuItem"
    m.top.watchTrailerSelected = true
  else if m.RelatedGrid.isInFocusChain() = true
    selectedContent = m.RelatedGrid.content.getChild(m.RelatedGrid.itemFocused)
    m.top.relatedContentToPlay = selectedContent
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
    else if key = "right" AND m.Menu.isInFocusChain() = true AND m.Menu.content.getChild(m.Menu.itemFocused).id = "LikeDislikeMenuItem" AND m.top.likeDislikeState <> m.constants.ui.likeDislikeStates.changing AND m.top.likeDislikeState <> m.constants.ui.likeDislikeStates.liked AND m.top.likeDislikeState <> m.constants.ui.likeDislikeStates.disliked
      'This is to send component_interaction with toggle_off when user Liked and then removed the rating and then set focus to secondary menu.
      focusSecondaryMenu()
      return true
    else if key = "left"
      if m.SecondaryMenu.isInFocusChain() = false AND m.RelatedGrid.isInFocusChain() = false
        m.top.backButtonPressed = true
        return true
      else if m.SecondaryMenu.isInFocusChain() = true
        focusMenu()
        return true
      end if
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

  ''//::TODO:: Remove below block once we fixed sending invalid component interaction events- added this for debugging purpose
  if isAA(pageValues) = true AND pageValues.count() > 0 AND pageValues.series_id = 0
    pageValuesInfo = {}
    pageValuesInfo.sourceOrigin = m.top.pageOrigin
    pageValuesInfo.isSeries = m.top.isSeries
    pageValuesInfo.seriesId = pageValues.series_id
    pageValuesInfo.contentIsInvalid = (m.top.content = invalid)
    tubiLog(FormatJSON(pageValuesInfo), "info", "videoInfo", "series-id-invalid")
  else if m.top.content <> invalid
    pageValuesInfo = {}
    pageValuesInfo.sourceOrigin = m.top.pageOrigin
    pageValuesInfo.isSeries = m.top.isSeries
    pageValuesInfo.seriesId = m.top.content.id.toInt()
    pageValuesInfo.contentIsInvalid = false
    tubiLog(FormatJSON(pageValuesInfo), "info", "videoInfo", "series-id-invalid")
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
