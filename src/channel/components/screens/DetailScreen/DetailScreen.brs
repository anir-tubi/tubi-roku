Function init()
  m.constants = m.global.constants
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
  m.Menu.observeFieldScoped("itemUnfocused", "onMenuItemUnfocused")
  m.SecondaryMenu.observeFieldScoped("itemSelected", "onSecondaryMenuItemSelected")
  m.SecondaryMenu.observeFieldScoped("itemFocused", "onSecondaryMenuItemFocused")
  m.SecondaryMenu.observeFieldScoped("itemUnfocused", "onSecondaryMenuItemUnfocused")
  m.top.observeFieldScoped("relatedContent", "onRelatedContentChange")
  m.RelatedGrid.observeFieldScoped("itemSelected", "onRelatedContentSelected")
  m.RelatedGrid.observeFieldScoped("itemFocused", "onRelatedItemFocused")
  m.Info.observeFieldScoped("descriptionSelected", "onDescriptionSelected")

  m.defaultHeroUri = "pkg:/images/art-blur-background.png"
  setInitialMenuItems()
  setInitialSecondaryMenuItems()

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


' @param bSendExposureEvent: Boolean, Should the experiment exposure event be sent? true=send event.
Function isLikeDislikeEnabled(bSendExposureEvent = false)
  bLikeDislikeEnabled = (getExperimentResource("roku_title_reactions", "roku_title_reactions_v3", bSendExposureEvent).enabled = true OR isLoggedInUser() = true)
  return bLikeDislikeEnabled
End Function


Function setDetailStrings()
  if isLoggedInUser() = false
    m.PlayMenuItem.title = getTranslation("registration_signIn_to_play_button") + ";" + getTranslation("registration_signup_button_free")
  else
    m.PlayMenuItem.title = getTranslation("screenDetails_button_play")
  end if

  m.LikeMenuItem.title = getTranslation("screenDetails_button_like")
  m.DislikeMenuItem.title = getTranslation("screenDetails_button_dislike")
  m.ResumeMenuItem.title = getTranslation("screenDetails_button_resume")
  m.EpisodesMenuItem.title = getTranslation("screenDetails_button_episodes")
  m.WatchTrailerMenuItem.title = getTranslation("screenDetails_button_trailer")
  RelatedRowLabelContent = m.top.findNode("RelatedRowLabelContent")
  RelatedRowLabelContent.title = getTranslation("screenDetails_relatedTitles")
  ' // REMOVE BELOW CODE ONCE FIFA WORLD CUP IS DONE
  m.SeeAllGamesMenuItem.title = getTranslation("screenDetails_button_see_all_games")
End Function


Function onStringChange(message)
  sButtonStringId = message.GetField()
  sButtonText = message.GetData()
  changeButtonText(sButtonStringId, sButtonText)
End function


Function changeButtonText(sButtonStringId, sButtonText)
  stringNode = invalid
  if sButtonStringId = "stringQueueButton"
    stringNode = m.AddQueueMenuItem

    if sButtonText = getTranslation("screenDetails_button_queue")
      stringNode.iconUrl = "pkg:/images/icon-add-to-queue.webp"
    else
      stringNode.iconUrl = "pkg:/images/set_reminder.png"
    end if

  else if sButtonStringId = "stringNoQueueButton"
    stringNode = m.RemoveQueueMenuItem

    if sButtonText = getTranslation("screenDetails_button_noQueue")
      stringNode.iconUrl = "pkg:/images/icon-remove-from-queue.webp"
    else
      stringNode.iconUrl = "pkg:/images/reminder_set.png"
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

    ' Adjust the width of the menu if the Channel name, the signin button (if signin conditions), or the like/dislike button (if signin conditions) is too long for the default width
    isSignUpButton = (sButtonStringId = "stringSignUpButton" AND isLoggedInUser() = false AND isNewUser() = false)
    isLikeButton = (sButtonStringId = "stringLikeDislikeButton" AND (isLikeDislikeEnabled() = true))
    if sButtonStringId = "stringChannelButton" OR isSignUpButton = true OR isLikeButton = true
      tempChannelMenuItem = CreateObject("roSGNode", "DetailMenuItem")
      tempChannelMenuItem.itemContent = stringNode

      potentialWidth = tempChannelMenuItem.calculatedTextWidth + tempChannelMenuItem.leftTextPadding + tempChannelMenuItem.rightTextPadding
      if potentialWidth > m.defaultMenuWidth AND potentialWidth > m.Menu.itemSize[0]
        m.Menu.itemSize = [potentialWidth, m.Menu.itemSize[1]]
        '//move SecondaryMenu to ensure it is not overlapping the Menu
        m.SecondaryMenu.translation = [potentialWidth + 200, m.SecondaryMenu.translation[1]]
      end if

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

  if m.top.hasFocus() = true

    'After Instant Resume, when pressing back from one detail screen to another detail screen via YMAL
    'related content(YMAL) thunbnails are not loading. Resetting relatedContent node fixes the issue.
    relatedContent = m.top.relatedContent
    m.top.relatedContent = invalid
    m.top.relatedContent = relatedContent

    if m.focusTarget <> invalid
      m.focusTarget.setFocus(true)
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
  if isLikeDislikeEnabled() = true AND m.top.selectedContentType <> m.constants.ui.contentTypes.sportsEvent
    sButtonText = ""
    sIconUrl = ""
    if m.top.likeDislikeState = m.constants.ui.likeDislikeStates.liked OR m.top.likeDislikeState = m.constants.ui.likeDislikeStates.disliked
      if m.top.likeDislikeState = m.constants.ui.likeDislikeStates.liked
        '//The Like State is "liked", so display liked state
        sButtonText = getTranslation("screenDetails_button_liked")
        sIconUrl = "pkg:/images/icon-liked.webp"
      else
        '//The Like State is "disliked", so display disliked state
        sButtonText = getTranslation("screenDetails_button_disliked")
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
      sButtonText = getTranslation("screenDetails_button_likeDislike")
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
  menuItems = [m.LikeDislikeMenuItem, m.signUpMenuItem, m.PlayMenuItem]
  if isLoggedInUser() = false OR getExperimentResource("roku_title_reactions", "roku_title_reactions_v4", true).enabled = true
    '//If a guest user (and if roku_title_reactions_v3 is enabled which is checked before OR if a registered user and roku_title_reactions_v4 is enabled,
    '// then ensure the like/dislike button comes AFTER the episodeList button
    menuItems = [m.signUpMenuItem, m.PlayMenuItem]
  end if

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
  signUpIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.signUpMenuItem.id)
  likeDisLikeIndex =  m.NodeHelpers.getChildIndexById(m.Menu.content, m.LikeDislikeMenuItem.id)

  if UCase(availabilityType) = UCase(m.constants.ui.contentTimings.replay)
    if likeDisLikeIndex <> invalid
      addRemoveMenuItem(false, likeDisLikeIndex)
    end if

    if signUpIndex <> invalid
      addRemoveMenuItem(false, signUpIndex)
    end if

    menuItems = [m.AddQueueMenuItem]
    addRemoveMenuItem(true, -1, m.SeeAllGamesMenuItem, menuItems)
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
    addRemoveMenuItem(true, -1, m.SeeAllGamesMenuItem, menuItems)
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
        '//if the like/dislke button does not exist yet, then add it
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
    if isLikeDislikeEnabled(true) = true
      '//add like/dislike button
      nLikeIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.LikeDislikeMenuItem.id)
      if nLikeIndex = -1
        addRemoveMenuItem(true, nLikeIndex, m.LikeDislikeMenuItem, [m.PlayMenuItem])
      end if

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
    if isLoggedInUser() = false
      '//as long as the user is logged out, send the like/dislike experiment exposure event here
      if isLikeDislikeEnabled(true) = true
        '//if the experiment is enabled then add the add like button for a guest user
        menuItems.appendChild(m.LikeDislikeMenuItem)
      end if

    else
      menuItems.appendChild(m.LikeDislikeMenuItem)
    end if

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
  selection = m.Menu.content.getChild(m.Menu.itemSelected)
  m.top.confirmButtonValue = selection.analyticsButtonValue
  handleMenuItemSelected(selection)
End Function


Function onMenuItemFocused()
  setVisibilityOfSecondaryMenu()
  focused = m.Menu.content.getChild(m.Menu.itemFocused)
  m.top.toggleOnButtonValue = focused.analyticsButtonValue

  if m.top.likeDislikeState <> m.constants.ui.likeDislikeStates.changing
    '//When the user has liked or disliked content and then moves to or away from the like/dislike button, then change the text to be the focused or unfocused versions
    changeLikeDislikeButtonText()
  end if

End Function


Function onMenuItemUnfocused(msg)
  itemUnfocusedIndex = msg.getData()
  itemUnfocused = m.Menu.content.getChild(itemUnfocusedIndex)

  if itemUnfocused <> invalid
    m.top.toggleOffButtonValue = itemUnfocused.analyticsButtonValue
  end if

End Function


Function onSecondaryMenuItemSelected()
  selection = m.SecondaryMenu.content.getChild(m.SecondaryMenu.itemSelected)
  m.top.confirmButtonValue = selection.analyticsButtonValue
  handleMenuItemSelected(selection)
End Function


Function onSecondaryMenuItemFocused()
  focused = m.SecondaryMenu.content.getChild(m.SecondaryMenu.itemFocused)
  m.top.toggleOnButtonValue = focused.analyticsButtonValue
End Function


Function onSecondaryMenuItemUnfocused(msg)
  itemUnfocusedIndex = msg.getData()
  itemUnfocused = m.SecondaryMenu.content.getChild(itemUnfocusedIndex)

  if itemUnfocused <> invalid
    m.top.toggleOffButtonValue = itemUnfocused.analyticsButtonValue
  end if

End Function


' checks if the secondary menu should be seen and then perform the proper actions if the menu should be seen or not.
' @return boolean, Should the menu be seen? (The function will ensure the menu is made visible if it should and not if it should not.)
Function setVisibilityOfSecondaryMenu()
  result = false

  if isLikeDislikeEnabled() = true
    itemFocused = m.Menu.content.getChild(m.Menu.itemFocused)
    if m.SecondaryMenu.isInFocusChain() = true OR (m.Menu.isInFocusChain() = true AND itemFocused <> invalid AND itemFocused.id = "LikeDislikeMenuItem" AND m.top.likeDislikeState <> m.constants.ui.likeDislikeStates.liked AND m.top.likeDislikeState <> m.constants.ui.likeDislikeStates.disliked AND m.top.likeDislikeState <> m.constants.ui.likeDislikeStates.changing)
      alignSecondaryMenuWithMenu()

      m.SecondaryMenu.visible = true
      m.Menu.focusFootprintBlendColor = m.constants.ui.colors.selectedListItem
      m.Menu.focusFootprintBitmapUri = "pkg://images/menu-focus-fhd.9.png"
      if m.constants.deviceInfo.scaledUi = true
        m.Menu.focusFootprintBitmapUri = "pkg://images/menu-focus-hd.9.png"
      end if

      result = true
    else
      m.SecondaryMenu.visible = false
      m.Menu.focusFootprintBitmapUri = ""
    end if

  end if

  return result
End Function


' Properly Align SecondaryMenu with the like/dislike button in the Menu
Function alignSecondaryMenuWithMenu()
  likeDislikeButtonIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.LikeDislikeMenuItem.id)
  boundingBoxLikeDislike = m.Menu.ancestorSubBoundingRect("item" + likeDislikeButtonIndex.toStr() + "_0", m.Menu)
  nMenuHeight = m.Menu.itemSize[1] + m.Menu.itemSpacing[1]
  nSubMenuLocation = boundingBoxLikeDislike.y/nMenuHeight
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
    if getExperimentResource("roku_video_preview", "roku_video_preview_v2", false).enabled = true
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
        '//If it is still trying to change the rating then do nothing if this btton is clicked again
      else if m.top.likeDislikeState = m.constants.ui.likeDislikeStates.liked
        '//when the current item is liked, then remove the like state
        m.top.removeLikeSelected = true
      else if m.top.likeDislikeState = m.constants.ui.likeDislikeStates.disliked
        '//when the current item is disliked, then remove the dislike state
        m.top.removeDislikeSelected = true
      else
        '//if displaying the like or dislike button, then clicking this should not cause a change of like status,
        '//   but it may be confusing to the useer if nothing happens, so
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
    if getExperimentResource("roku_video_preview", "roku_video_preview_v2", false).enabled = true
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
        vertical_location_mode: "INDEX" 'LocationMode enum
        horizontal_location: col
        horizontal_location_mode: "INDEX" 'LocationMode enum
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
    m.top.focusOnLikeMenu = false '//make sure this is set to false in case cominng from secondary menus
    m.Menu.setFocus(true)
    m.relatedHasFocus = false
  end if
End Function


Function focusSecondaryMenu()
  m.focusTarget = m.SecondaryMenu
  if m.top.isInFocusChain() = true
    m.top.focusOnLikeMenu = true
    m.SecondaryMenu.jumpToItem = 0  'reset focus to the 1st menu item
    m.SecondaryMenu.setFocus(true)
  end if
End Function


Function focusRelated()
  m.focusTarget = m.RelatedGrid
  if m.top.isInFocusChain() = true
    focusedMenuItem = m.Menu.content.getChild(m.Menu.itemFocused)
    m.top.toggleOffButtonValue = focusedMenuItem.analyticsButtonValue
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
    focusedMenuItem = m.Menu.content.getChild(m.Menu.itemFocused)
    m.top.toggleOffButtonValue = focusedMenuItem.analyticsButtonValue
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
  if getExperimentResource("roku_video_preview", "roku_video_preview_v2", false).enabled = true
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
    if key = "back" OR (key = "left" AND m.SecondaryMenu.isInFocusChain() = false)
      if not m.top.isWaitingForServerResponse
        m.top.backButtonPressed = true
      end if

      return true
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
      focusedItem = m.Menu.content.getChild(m.Menu.itemFocused)
      m.top.toggleOffButtonValue = focusedItem.analyticsButtonValue
      focusSecondaryMenu()
      return true
    else if key = "left" AND m.SecondaryMenu.isInFocusChain() = true
      focusedItem = m.SecondaryMenu.content.getChild(m.SecondaryMenu.itemFocused)
      m.top.toggleOffButtonValue = focusedItem.analyticsButtonValue
      focusMenu()
      return true
    end if

  end if

  return false
End Function