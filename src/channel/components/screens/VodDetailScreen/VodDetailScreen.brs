' Initializes the VOD Detail Screen component
' Sets up node references, observers, constants, and initial component state
Function init()
  m.constants = getConstantsFromGlobal()
  m.nodeHelpers = TubiNodeHelpers()
  m.tracking = TubiTrackingInfo(m.constants)
  topRef = m.top

  topRef.screenLevel = m.constants.ui.screenLevels.vodDetailScreen

  ' Initialize analytics configuration
  initAnalytics()

  m.contentGroup = topRef.findNode("contentGroup")
  m.relatedContentContainer = topRef.findNode("relatedContentContainer")
  m.additionalContentContainer = topRef.findNode("additionalContentContainer")
  m.contentContainer = topRef.findNode("contentContainer")
  m.actionButtonList = topRef.findNode("actionButtonList")
  m.sectionTabs = topRef.findNode("sectionTabs")
  m.videoMetadataPanel = topRef.findNode("videoMetadataPanel")
  m.videoDetailsPanel = topRef.findNode("videoDetailsPanel")
  m.episodesContainer = topRef.findNode("episodesContainer")
  m.contentTitle = topRef.findNode("contentTitle")
  m.contentTitleLabel = m.contentTitle.findNode("contentTitleLabel")
  m.gradient = topRef.findNode("gradient")
  m.belowFoldGradient = topRef.findNode("belowFoldGradient")
  m.leftChevron = topRef.findNode("leftChevron")

  m.aboveFoldGradientTranslation = [193, 360]
  m.contentContainer.translation = m.aboveFoldGradientTranslation
  topRef.isStackable = true
  topRef.handlesTransportVoiceRequests = true

  topRef.observeFieldScoped("focusedChild", "onScreenFocusChange")
  topRef.observeFieldScoped("contentUpdated", "onContentChange")
  topRef.observeFieldScoped("userSignedIn", "onUserSignedInChange")
  topRef.observeFieldScoped("shouldRefreshButtonList", "refreshButtonList")
  m.relatedContentContainer.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
  m.relatedContentContainer.observeFieldScoped("trackingContext", "onTrackingContextChange")
  m.episodesContainer.observeFieldScoped("trackingContext", "onTrackingContextChange")
  m.episodesContainer.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
  m.actionButtonList.observeFieldScoped("navigateWithinPageEventInfo", "onButtonListNavigateWithinPageEventInfoChange")
  m.sectionTabs.observeFieldScoped("navigateWithinPageEventInfo", "onButtonListNavigateWithinPageEventInfoChange")
  m.contentContainer.observeFieldScoped("navigateWithinPageEventInfo", "onButtonListNavigateWithinPageEventInfoChange")
  topRef.observeFieldScoped("trackingPageInfo", "onTrackingPageInfoChange")
  m.sectionTabs.observeFieldScoped("buttonFocused", "onSectionTabFocused")
  m.contentContainer.observeFieldScoped("focusedIndex", "onContentContainerFocusIndexChange")
  topRef.observeFieldScoped("seasonList", "refreshButtonList")
  m.actionButtonList.observeFieldScoped("buttonSelected", "onActionButtonSelected")
  ' Component interaction tracking
  m.actionButtonList.observeFieldScoped("buttonFocused", "onActionButtonFocused")
  topRef.observeFieldScoped("episodes", "onEpisodesChange")
  topRef.observeFieldScoped("shouldRefreshScreen", "refreshScreen")
  topRef.observeFieldScoped("wasContentFetchCompleted", "onWasContentFetchCompletedChange")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.contentTitleLabel, typographyConstants.ids.headerSmall)

  m.animationDuration = 0.4

  m.isComingSoon = false ' Initialize coming soon flag

  experiment = getStatsigExperimentResource("roku_content_details", "roku_content_details_v2", false)
  m.isLeftBackExitEnabled = experiment <> invalid AND experiment.enable_left_button_exit = true

  m.leftChevron.visible = m.isLeftBackExitEnabled

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


' Handles theme changes and updates UI colors accordingly
' @param msg - Optional message object containing theme data
Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if
  if theme <> invalid
    m.contentTitleLabel.color = theme.primaryTextColor
    m.neutralColor2 = theme.neutralColor2
    m.neutralColor = theme.neutralColor
  end if
End Function


' Updates content title to use titleImage if available, otherwise uses text label
' @param content - Content node with title and titleImageUrl
Function updateContentTitle(content) as Void
  if content = invalid then return
  m.contentTitleLabel.text = content.title
End Function


' Handles screen focus changes
' Manages side navigation state and sets background images when screen gains focus
Function onScreenFocusChange()
  if m.top.hasFocus() = true
    if m.top.openSideNav = true
      setSideNavState(false)
    end if

    m.contentContainer.setFocus(true)

    if m.top.content <> invalid AND isNonEmptyArray(m.top.content.backgrounds) = true
      m.top.backgroundUriList = m.top.content.backgrounds
    end if
  end if
End Function


' Handles content changes for the detail screen
' Updates buttons, tabs, metadata panel and shows appropriate content containers
Function onContentChange()
  content = m.top.content

  if content <> invalid
    if m.top.wasContentFetchCompleted <> invalid
      m.contentGroup.visible = m.top.wasContentFetchCompleted
    else
      m.contentGroup.visible = false
    end if

    m.isComingSoon = isComingSoonContent(content)

    refreshButtonList()
    if m.sectionTabs = invalid OR isNonEmptyArray(m.sectionTabs.buttons) = false
      renderSectionTabs()
    end if

    if m.top.isInKidsMode = true
      m.gradient.uri = "pkg:/images/details_kids_above_fold_gradient_$$RES$$.webp"
      m.belowFoldGradient.uri = "pkg:/images/details_kids_below_fold_gradient.png"
    end if

    ' Set title image or text label based on availability
    updateContentTitle(content)

    if content.type <> "series"
      m.relatedContentContainer.visible = true
    else
      m.episodesContainer.seriesId = content.id.toStr()
      m.episodesContainer.visible = true
    end if

    height = m.videoMetadataPanel.boundingRect().height
    m.contentGroup.translation = [0, 312 - height]
  end if
End Function


' Handles episodes data changes for series content
' Determines the current episode based on history and updates the metadata panel
' @param msg - Message object containing episodes data
Function onEpisodesChange(msg = invalid)
  if msg <> invalid
    episodes = msg.getData()
  else
    episodes = m.top.episodes
  end if
  if episodes <> invalid AND m.top.content <> invalid
    contentId = m.top.content.id
    history = getHistory(contentId)
    if history <> invalid
      currentEpisodeId = history.currentEpisodeId
      currentEpisode = m.nodeHelpers.getChildById(episodes, currentEpisodeId)
    else
      currentEpisode = episodes.getChild(0)
    end if

    m.videoMetadataPanel.currentEpisode = currentEpisode
  end if
End Function


' NOTE: Analytics event handlers (onNavigateWithinPageInfoChange, onTrackingComponentInfoChange,
' onTrackingPageInfoChange, onButtonListNavigateWithinPageEventInfoChange) are defined in VodDetailScreenAnalytics.brs


' Refreshes the action button list based on current content and user state
' Builds buttons for play/resume, sign-in, trailer, queue, like/dislike, history, and channel
Function refreshButtonList()
  itemContent = m.top.content
  buttons = []
  isButtonsListInFocusChain = m.actionButtonList.isInFocusChain() = true

  if itemContent <> invalid
    contentId = itemContent.id
    bookmark = getBookmark(contentId)
    history = getHistory(contentId)
    like = getLike(contentId)

    ' Build button list using helper functions
    if m.isComingSoon = false
      addPlayOrResumeButtons(buttons, itemContent, history)
      addSignInButton(buttons)
      addRemoveHistoryButton(buttons, history)

      if m.top.isInKidsMode = false
        addLikeDislikeButtons(buttons, like)

        if isNonEmptyString(itemContent.channelId)
          addChannelButton(buttons, itemContent)
        end if
      end if
    end if

    addTrailerButton(buttons, itemContent)
    addQueueButton(buttons, bookmark)

  end if

  ' Pass buttons array to the button list component
  m.actionButtonList.buttons = buttons
  m.actionButtonList.visible = isNonEmptyArray(buttons)

  if isNonEmptyArray(buttons) AND isButtonsListInFocusChain = true
    m.actionButtonList.setFocus(true)
  end if
End Function


' Handles CTA button selection events
' Propagates the selected button ID to parent
' @param msg - Message object containing button ID
Function onCtaButtonSelected(msg)
  buttonId = msg.getData()
  if buttonId <> invalid
    m.top.ctaButtonSelectedId = buttonId
  end if
End Function


' Handles user sign-in state changes
' Refreshes button list to show/hide sign-in dependent buttons
' @param msg - Message object containing sign-in state
Function onUserSignedInChange(msg)
  userSignedIn = msg.getData()
  if userSignedIn = true
    refreshButtonList()
  end if
End Function


' Renders section tabs based on content type
' Creates tabs for Episodes (series only), More Like This, and Details
Function renderSectionTabs()
  itemContent = m.top.content
  tabs = []

  if itemContent <> invalid
    ' Episodes tab - only show for series content
    if itemContent.type = "series"
      episodesTab = {
        id: "episodes"
        title: getTranslation("button_episodes")
        isPrimaryButton: true
        trackingContext: createButtonAnalytics("episodes")
      }
      tabs.push(episodesTab)
    end if

    ' More Like This tab - always show for related content
    moreLikeThisTab = {
      id: "moreLikeThis"
      title: getTranslation("screenDetails_relatedTitles")
      isPrimaryButton: true
      trackingContext: createButtonAnalytics("moreLikeThis")
    }
    tabs.push(moreLikeThisTab)

    ' Details tab - always show
    detailsTab = {
      id: "details"
      title: getTranslation("screenHome_button_spotlight_details")
      isPrimaryButton: true
      trackingContext: createButtonAnalytics("details")
    }
    tabs.push(detailsTab)
  end if

  ' Pass tabs array to the section tabs component
  if m.sectionTabs <> invalid
    m.sectionTabs.buttons = tabs
    m.sectionTabs.visible = isNonEmptyArray(tabs)
  end if

  playbackSource = m.top.playbackSource
  if isAA(playbackSource) AND playbackSource.srcForAds = "deeplink"
    m.contentContainer.jumpToIndex = 2
    m.sectionTabs.jumpToIndex = getYmalTabIndex()
  end if
End Function


' Returns the index of the "More Like This" (YMAL) tab
' Index depends on whether YMAL is shown first and if content is a series
' @return Integer index of YMAL tab
Function getYmalTabIndex() as Integer
  if m.top.content <> invalid AND m.top.content.type = "series"
    return 1
  else
    return 0
  end if
End Function


' Handles section tab focus changes
' Sends navigation tracking events and shows/hides appropriate content containers
' @param msg - Message object containing focused tab data
Function onSectionTabFocused(msg)
  focusedTab = msg.getData()
  if focusedTab <> invalid AND focusedTab.id <> invalid
    ' Send CONFIRM component interaction event for section tab focus
    setComponentInteractionEventForButton("CONFIRM", focusedTab)

    tabId = focusedTab.id
    m.relatedContentContainer.visible = false
    m.episodesContainer.visible = false
    m.videoDetailsPanel.visible = false

    ' Details panel is not focusable when the user is on the details tab
    m.additionalContentContainer.focusable = tabId <> "details"

    ' Configure content container based on selected tab
    if tabId = "details"
      m.videoDetailsPanel.itemContent = m.top.content
      m.videoDetailsPanel.visible = true
    else if tabId = "moreLikeThis"
      m.relatedContentContainer.visible = true
    else if tabId = "episodes"
      m.episodesContainer.visible = true
    end if

    ' Set spacing: episodes tab has different bottom spacing (0) vs other tabs (42)
    if tabId = "episodes"
      m.contentContainer.itemSpacings = [60, 63, 0]
    else
      m.contentContainer.itemSpacings = [60, 63, 42]
    end if

    m.top.selectedSection = tabId
  end if
End Function


' Handles action button selection events
' Sends component interaction tracking event and propagates button ID to parent
' @param msg - Message object containing selected button data
Function onActionButtonSelected(msg)
  buttonSelected = msg.getData()
  if buttonSelected <> invalid AND buttonSelected.id <> invalid
    ' Send CONFIRM component interaction event
    setComponentInteractionEventForButton("CONFIRM", buttonSelected)

    buttonId = buttonSelected.id
    m.top.ctaSelectedButtonId = buttonId
  end if
End Function


' Handles content container focus index changes
' Manages UI animations and spacing adjustments based on focused component
' @param msg - Message object containing focused index
Function onContentContainerFocusIndexChange(msg)
  focusedIndex = msg.getData()
  if focusedIndex <> invalid
    m.top.shouldPauseVideoPreview = focusedIndex > 1
    componentGainingFocus = m.contentContainer.componentGainingFocus
    m.leftChevron.visible = (m.isLeftBackExitEnabled = true AND focusedIndex = 1)

    if componentGainingFocus <> invalid
      translationX = m.contentContainer.translation[0]
      didUserNavigateToAdditionalContent = (componentGainingFocus.id = "sectionTabs" OR componentGainingFocus.id = "additionalContentContainer")
      if didUserNavigateToAdditionalContent = true
        fade(m.contentTitle, "in", 0.3)
        fade(m.belowFoldGradient, "in", 0.3)
        m.additionalContentContainer.opacity = 1.0
      else
        fade(m.contentTitle, "out", 0.3)
        fade(m.belowFoldGradient, "out", 0.3)
        m.additionalContentContainer.opacity = 0.5
      end if

      if componentGainingFocus.id = "actionButtonList" AND m.sectionTabs <> invalid AND m.sectionTabs.buttonFocused <> invalid AND m.sectionTabs.buttonFocused.id = "details"
        m.additionalContentContainer.opacity = 0
      end if

      ' Check content validity before accessing type property
      content = m.top.content
      m.episodesContainer.showSeasonSelector = (didUserNavigateToAdditionalContent = true AND content <> invalid AND content.type = m.constants.ui.contentTypes.series)

      ' Adjust UI layout based on focus position
      if focusedIndex = 1
        ' User is on action buttons - slide down to show buttons area
        slideTo(m.contentContainer, m.aboveFoldGradientTranslation, 0.3)
        m.contentContainer.itemSpacings = [60, 63, 24]
        fade(m.actionButtonList, "in", 0.3)
        ' Use foreground-10 when action buttons are focused
        m.sectionTabs.buttonBackgroundBlendColor = m.neutralColor2
      else
        ' User is on content area - slide up to maximize content viewing area
        slideTo(m.contentContainer, [translationX, -372], 0.3)
        fade(m.actionButtonList, "out", 0.3)
        ' Use foreground-20 when section tabs are focused
        m.sectionTabs.buttonBackgroundBlendColor = m.neutralColor

        ' Adjust spacing based on content type and selected section
        ' Episodes need less bottom spacing (0) while other sections need more (51)
        ' This is due to presence of season selector in episodes section.
        content = m.top.content
        isEpisodesSection = content <> invalid AND content.type = m.constants.ui.contentTypes.series AND m.top.selectedSection = "episodes"
        bottomSpacing = 0 ' For episodes section
        if isEpisodesSection = false then bottomSpacing = 42 ' For other sections

        m.contentContainer.itemSpacings = [60, 63, bottomSpacing]
      end if
    end if
  end if
End Function


' Handles action button focus changes
' Pauses video preview for non-play buttons, resumes for play/resume buttons
' @param msg - Message object containing focused button data
Function onActionButtonFocused(msg) as Void
  focusedButton = msg.getData()
  if focusedButton <> invalid AND m.top.shouldPauseVideoPreview = true
    m.top.shouldPauseVideoPreview = false
  end if
End Function


' NOTE: Analytics function (setComponentInteractionEventForButton) is defined in VodDetailScreenAnalytics.brs


' Sets the side navigation menu state (open/closed)
' @param isOpen - Boolean, true to open side nav, false to close it
Function setSideNavState(isOpen as Boolean) as Void
  m.top.openSideNav = isOpen

  xPosition = m.constants.ui.translations.screenXWhenSideNavClosed
  if isOpen = true
    xPosition = m.constants.ui.translations.screenXWhenSideNavOpen
  end if

  slideTo(m.contentContainer, [xPosition, m.contentContainer.translation[1]], .2)

  m.leftChevron.visible = m.isLeftBackExitEnabled AND isOpen = false
End Function


' Adds play or resume buttons based on history state
' @param buttons - Array, the buttons list to append to
' @param content - Object, the content item
' @param history - Object, the history object or invalid
Function addPlayOrResumeButtons(buttons, content, history) as Void
  playButtonSuffix = getPlayButtonSuffix(content, history)

  ' Check if user has watched past the postlude credit cue point
  isEndReached = (history <> invalid AND content <> invalid AND content.creditCuePoints <> invalid AND content.creditCuePoints.postlude <> invalid AND content.creditCuePoints.postlude > 0 AND history.nowPos > content.creditCuePoints.postlude)

  if history <> invalid AND isEndReached = false
    progress = calculatePlayProgress(content, history)

    ' Resume button when there's a resume point
    buttons.push({
      id: "resume"
      title: getTranslation("screenDetails_button_resume") + playButtonSuffix
      iconUrl: "pkg:/images/icon-play.webp"
      isPrimaryButton: true
      progress: progress
      trackingContext: createButtonAnalytics("resume")
    })

    ' Start from beginning button
    buttons.push({
      id: "startFromBeginning"
      title: getTranslation("screenDetails_button_startFromBeginning")
      iconUrl: "pkg:/images/icon-restart.webp"
      trackingContext: createButtonAnalytics("startFromBeginning")
    })
  else
    ' Regular play button when no resume point
    buttons.push({
      id: "play"
      title: getTranslation("screenDetails_button_play") + playButtonSuffix
      iconUrl: "pkg:/images/icon-play.webp"
      isPrimaryButton: true
      trackingContext: createButtonAnalytics("play")
    })
  end if
End Function


' Creates analytics object for buttons with middle_nav_component type
' @param buttonId - String, the button ID (e.g., "play", "moreLikeThis")
' @return Object - Analytics object with type and values
Function createButtonAnalytics(buttonId as String) as Object
  if m.buttonIdToAnalyticsSection = invalid then initAnalytics()

  analyticsValue = ""

  if m.buttonIdToAnalyticsSection <> invalid
    analyticsValue = m.buttonIdToAnalyticsSection[buttonId]
  end if

  return {
    type: "middle_nav_component"
    values: {
      middle_nav_section: analyticsValue
    }
  }
End Function


' Gets the play button suffix for series content (e.g., " S1 E1")
' @param content - Object, the content item
' @param history - Object, the history object or invalid
' @return String - The suffix to append to play button text, or empty string
Function getPlayButtonSuffix(content, history) as String
  seasonList = m.top.seasonList

  ' Early return if not a series or missing season data
  if content.type <> "series" OR seasonList = invalid OR seasonList.seasons = invalid
    return ""
  end if

  seasonNum = invalid
  episodeNum = invalid

  ' Try to get season/episode from history first
  if history <> invalid AND history.currentEpisodeId <> invalid AND seasonList.episodeSeasonMap <> invalid
    currentEpisodeId = history.currentEpisodeId.toStr()
    currentEpisodeSeasonMap = seasonList.episodeSeasonMap[currentEpisodeId]

    if currentEpisodeSeasonMap <> invalid
      seasonNum = currentEpisodeSeasonMap.seasonNum.toStr()
      episodeNum = currentEpisodeSeasonMap.episodeNum.toStr()
    end if
  end if

  ' Early return if we found valid season/episode in history
  if seasonNum <> invalid AND episodeNum <> invalid
    return " " + substitute(getTranslation("season_episode_label"), seasonNum, episodeNum)
  end if

  ' Fall back to first episode if not found in history
  if isNode(seasonList.seasonSelectorContent) = true AND seasonList.seasonSelectorContent.getChildCount() > 0
    seasonNode = seasonList.seasonSelectorContent.getChild(0)
    firstSeasonItem = seasonNode.getChild(0)
    if firstSeasonItem <> invalid
      ' Extract season number from the first season item
      seasonNum = firstSeasonItem.seasonNumber.toStr()
      episodeList = seasonList.seasons[seasonNum]
      if isNonEmptyArray(episodeList)
        ' Get the first episode number from the list
        episodeNum = episodeList[0].num.toStr()
        return " " + substitute(getTranslation("season_episode_label"), seasonNum, episodeNum)
      end if
    end if
  end if

  return ""
End Function


' Calculates play progress percentage for resume button
' @param content - Object, the content item
' @param history - Object, the history object
' @return Float - Progress percentage (0-100)
Function calculatePlayProgress(content, history) as Float
  if history = invalid then return 0
  progress = 0
  nowPos = history.nowPos
  contentLength = content.length

  if content.type = "series"
    if isNonEmptyString(history.currentEpisodeId)
      episodeHistory = m.nodeHelpers.getChildById(history, history.currentEpisodeId)
      if episodeHistory <> invalid
        nowPos = episodeHistory.nowPos
        contentLength = episodeHistory.contentLength
      end if
    end if
  end if

  if isNumber(contentLength) = true AND isNumber(nowPos) = true AND contentLength > 0 AND nowPos > 0
    percentage = nowPos / contentLength
    progress = (percentage * 100)
  end if

  return progress
End Function


' Adds sign-in button if user is not signed in
' @param buttons - Array, the buttons list to append to
Function addSignInButton(buttons) as Void
  if m.top.userSignedIn = false
    buttons.push({
      id: "signIn"
      title: getTranslation("dialog_button_signUp")
      iconUrl: "pkg:/images/icon-account.webp"
      subtitle: getTranslation("save_progress_button")
      badgeText: getTranslation("registration_signup_button_free")
      isPrimaryButton: true
      displayOnlyIconTileWhenNotFocused: true
      trackingContext: createButtonAnalytics("signIn")
    })
  end if
End Function


' Adds trailer button if content has trailer
' @param buttons - Array, the buttons list to append to
' @param content - Object, the content item
Function addTrailerButton(buttons, content) as Void
  if content.hasTrailer = true
    buttons.push({
      id: "watchTrailer"
      title: getTranslation("screenDetails_button_trailer")
      iconUrl: "pkg:/images/watch-trailer-film-strip.webp"
      trackingContext: createButtonAnalytics("watchTrailer")
    })
  end if
End Function


' Adds queue button (add or remove based on bookmark state)
' @param buttons - Array, the buttons list to append to
' @param bookmark - Object, the bookmark object or invalid
Function addQueueButton(buttons, bookmark) as Void
  if bookmark <> invalid
    buttonId = "removeFromQueue"

    if m.isComingSoon = false
      translationKey = "screenDetails_button_noQueue"
      iconUrl = "pkg:/images/icon-remove-from-queue.webp"
    else
      translationKey = "screenDetails_button_remove_reminder"
      iconUrl = "pkg:/images/reminder-set.webp"
    end if
  else
    buttonId = "addToQueue"

    if m.isComingSoon = false
      translationKey = "screenDetails_button_queue"
      iconUrl = "pkg:/images/icon-add-to-queue.webp"
    else
      if isLoggedInUser() = false
        translationKey = "screenDetails_button_sign_in_to_set_reminder"
      else
        translationKey = "screenDetails_button_set_reminder"
      end if
      iconUrl = "pkg:/images/set-reminder.webp"
    end if
  end if

  buttons.push({
    id: buttonId
    title: getTranslation(translationKey)
    iconUrl: iconUrl
    trackingContext: createButtonAnalytics(buttonId)
  })
End Function


' Adds like and dislike buttons with appropriate state
' @param buttons - Array, the buttons list to append to
' @param like - Object, the like object or invalid
Function addLikeDislikeButtons(buttons, like) as Void
  ' Like button
  likeTranslationKey = "screenDetails_button_like"
  likeIconUrl = "pkg:/images/icon-like.webp"
  if like <> invalid AND like.state = "liked"
    likeTranslationKey = "screenDetails_button_liked"
    likeIconUrl = "pkg:/images/icon-liked.webp"
  end if

  buttons.push({
    id: "like"
    title: getTranslation(likeTranslationKey)
    iconUrl: likeIconUrl
    trackingContext: createButtonAnalytics("like")
  })

  ' Dislike button
  dislikeTranslationKey = "screenDetails_button_dislike"
  dislikeIconUrl = "pkg:/images/icon-dislike.webp"
  if like <> invalid AND like.state = "disliked"
    dislikeTranslationKey = "screenDetails_button_disliked"
    dislikeIconUrl = "pkg:/images/icon-disliked.webp"
  end if

  buttons.push({
    id: "dislike"
    title: getTranslation(dislikeTranslationKey)
    iconUrl: dislikeIconUrl
    trackingContext: createButtonAnalytics("dislike")
  })
End Function


' Adds remove from history button if content has history
' @param buttons - Array, the buttons list to append to
' @param history - Object, the history object or invalid
Function addRemoveHistoryButton(buttons, history) as Void
  if history <> invalid
    buttons.push({
      id: "removeFromHistory"
      title: getTranslation("screenDetails_button_noHistory")
      iconUrl: "pkg:/images/icon-remove-from-history.webp"
      trackingContext: createButtonAnalytics("removeFromHistory")
    })
  end if
End Function


' Adds channel button if content has a channel
' @param buttons - Array, the buttons list to append to
' @param content - Object, the content item
Function addChannelButton(buttons, content) as Void
  if isNonEmptyString(content.channelId)
    buttons.push({
      id: "gotoChannel"
      title: getTranslation("screenDetails_button_gotoChannel", { channel: content.channelName })
      iconUrl: "pkg:/images/icon-networks.png"
      trackingContext: createButtonAnalytics("gotoChannel")
    })
  end if
End Function


' Refreshes the screen
Function refreshScreen() as Void
  if m.top.content <> invalid AND m.top.content.type = m.constants.ui.contentTypes.series
    onEpisodesChange()
  end if
  refreshButtonList()
End Function


' Handles wasContentFetchCompleted changes
' @param msg - Message object containing wasContentFetchCompleted data
Function onWasContentFetchCompletedChange(msg) as Void
  wasContentFetchCompleted = msg.getData()
  if wasContentFetchCompleted = true
    m.contentGroup.visible = true
  end if
End Function


Function onTrackingContextChange(msg) as Void
  trackingContext = msg.getData()

  if trackingContext <> invalid
    m.top.trackingComponentInfo = {
      componentType: trackingContext.type
      componentValues: trackingContext.values
    }
  end if
End Function


' Handles key press events for the screen
' Manages back button and side navigation trigger
' @param key - String, the key that was pressed
' @param press - Boolean, true if key was pressed (not released)
' @return Boolean - True if event was handled, false otherwise
Function onKeyEvent(key as String, press as Boolean) as Boolean
  if press = true
    if key = "back"
      if m.contentContainer.focusedIndex <> 1
        m.actionButtonList.jumpToIndex = 0
        m.contentContainer.jumpToIndex = 1
        ' Resume video preview when navigating back to buttons
        m.top.shouldPauseVideoPreview = false
      else
        m.top.backTriggerKey = "BACK"
        m.top.backButtonPressed = true
      end if
      return true
    else if key = "left" AND m.contentContainer.focusedIndex = 1 AND m.isLeftBackExitEnabled = true
      m.top.shouldPauseVideoPreview = true
      fireButtonComponentInteractionEvent("LEFT", "IMAGE", "CONFIRM")
      fireNavigateToSideNavEvent()
      setSideNavState(true)
      return true
    end if
  end if

  return false
End Function