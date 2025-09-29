' gets the video player state for content passed as param
' @content : TubiContentNode, which has the details about the title/video
' returns state : string, the state of videopreview
Function getVideoPreviewStateForThisContent(content = invalid, isInFeaturedRowExp = false)
  tubiLog("VideoPreviewHelpers.getVideoPreviewStateForThisContent")
  state = "none"

  videoPreview = m.videoPreviewPlayer
  if content <> invalid AND videoPreview <> invalid AND videoPreview.content <> invalid
    if videoPreview.content.id = content.id
      state = videoPreview.state
    end if
  end if

  return state
End Function


' gets the video player state
' returns state : string, the state of videopreview
Function getVideoPreviewState()
  tubiLog("VideoPreviewHelpers.getVideoPreviewState")
  state = "none"
  videoPreview = m.videoPreviewPlayer
  if videoPreview <> invalid
    state = videoPreview.state
  end if

  return state
End Function


Function onStopVideoPreview()
  tubiLog("VideoPreviewHelpers.onStopVideoPreview")
  stopVideoPreview()
End Function


' stopVideoPreview stops the video preview
' @node : roSGNode, a VideoPreviewPlayer node
Function stopVideoPreview(node = invalid)
  tubiLog("VideoPreviewHelpers.stopVideoPreview")
  if node = invalid
    node = m.videoPreviewPlayer
  end if

  ' TODO: Remove if we do not graduate roku_home_screen_redesign_v_1_6 experiment.
  ' This is needed to provide smooth scrolling experience when the user is scrolling the list because calling video stop causes glitchy behavior.
  isListScrolling = false
  screen = getCurrentScreen()
  if screen <> invalid AND screen.hasField("featuredListScrollingStatus") = true
    isListScrolling = screen.featuredListScrollingStatus
  end if

  if node <> invalid AND node.subType() = "VideoPreviewPlayer" AND isListScrolling = false
    if node.playerState <> "stopped"
      sendVideoPlayerCommand(node, "stop")
    end if
    node.visible = false
  end if
End Function


Function onPauseVideoPreview()
  tubiLog("VideoPreviewHelpers.onPauseVideoPreview")
  if m.isUserInVideoTilesExperiment = true
    m.inlineVideoMetadataOverlay.showContentPoster = true
  end if

  pauseVideoPreview()
End Function


Function pauseVideoPreview()
  tubiLog("VideoPreviewHelpers.pauseVideoPreview")
  videoPreview = m.videoPreviewPlayer
  if videoPreview <> invalid
    sendVideoPlayerCommand(videoPreview, "pause")
  end if
End Function


Function onVideoPreviewStateChanged(msg)
  videoPreview = msg.getRoSGNode()
  videoPreviewState = msg.getData()
  tubiLog("VideoPreviewHelpers.onVideoPreviewStateChanged, " + videoPreviewState)
  currentScreen = getCurrentScreen()
  if (videoPreviewState = "playing" OR videoPreviewState = "paused") AND videoPreview <> invalid AND videoPreview.isBufferingComplete = true
    if currentScreen.featuredListHasFocus = false AND m.isUserInVideoTilesExperiment = true
      m.inlineVideoMetadataOverlay.showContentPoster = true
    else
      m.inlineVideoMetadataOverlay.showContentPoster = false

      showVideoPreviewPlayer = currentScreen.isInFocusChain() = true OR currentScreen.lastFocusedList <> "featuredRowList"
      videoPreview.visible = (showVideoPreviewPlayer = true)

      bDisplayBackgroundGroup = (showVideoPreviewPlayer = false)
      if currentScreen.contentFocused <> invalid AND currentScreen.contentFocused.gridItemType = m.constants.ui.gridItemTypes.adRowlistSpotlight
        '//Keep the background group visible for adRowlistSpotlight content
        bDisplayBackgroundGroup = true
      end if
      m.backgroundGroup.posterVisible = bDisplayBackgroundGroup
    end if
    if m.inlinePreviewPlayerFadeAnimation <> invalid
      m.inlinePreviewPlayerFadeAnimation.control = "stop"
    end if
    m.videoPreviewPlayer.opacity = 1

    showVideoPreviewPlayer = (currentScreen <> invalid AND currentScreen.isInFocusChain() = true) OR currentScreen.lastFocusedList <> "featuredRowList"
    videoPreview.visible = (showVideoPreviewPlayer = true)
    m.backgroundGroup.posterVisible = (showVideoPreviewPlayer = false)
  else if videoPreviewState = "error"
    ' unobserve the state if we have any error while playing mp4 video previews to avoid autostarting the focused content on autostart variant of experiment.
    videoPreview.unobserveFieldScoped("state")
    videoPreview.unobserveFieldScoped("position")
  else
    if videoPreview <> invalid
      videoPreview.visible = false
    end if
    m.backgroundGroup.posterVisible = true
  end if

  if videoPreviewState = "finished"
    if currentScreen <> invalid AND currentScreen.contentFocused <> invalid

      'Don't want to continue to full player from video preview if the user is in kidsMode, teen level for UK and NZ region as per GDPR guidelines.
      'Also don't auto start locked contents.
      item = currentScreen.contentFocused

      if currentScreen.subType() = "DetailScreen"
        item = currentScreen.content
      end if

      isReplay = false
      if item <> invalid AND item.gridItemType = m.constants.ui.gridItemTypes.skinAd
        isReplay = true
      end if

      isFullPlayerBlockedForUser = (isGDPR(m.constants) = true AND (isKidsUIOn() = true OR isParentalControlsAdultLevel() = false)) OR (item <> invalid AND item.needsLogin = true AND isLoggedInUser() = false) OR arrayIncludes(m.constants.ui.fullScreenVideoPlayerGridItemTypes, item.gridItemType) = true OR item.playerType = m.constants.ui.playerTypes.fox
      if isReplay = true
        '//Loop the video in this case
        if m.maintask.isHdmiStatusOk = true
          ' Don't want to continue playback if the user has their tv turned off
          sendVideoPlayerCommand(videoPreview, "play")
        end if
        m.backgroundGroup.posterVisible = true

      else if item <> invalid AND item.gridItemType = m.constants.ui.gridItemTypes.adRowlistCarousel OR item.gridItemType = m.constants.ui.gridItemTypes.adRowlistSpotlight
        '// Simply stop the video preview for adRowlistCarousel or adRowlistSpotlight content
        m.backgroundGroup.posterVisible = true
        if isCurrentScreenHomeScreen() = true AND item.gridItemType = m.constants.ui.gridItemTypes.adRowlistCarousel
          currentScreen.allowCarouselAutoRotate = true
        end if
      else if m.maintask.isHdmiStatusOk = true AND isFullPlayerBlockedForUser = false
        ' Don't want to continue playback if the user has their tv turned off
        if currentScreen.subType() = "DetailScreen"

          playbackSource = {
            "srcForAnalytic": "previews"
            "srcForAds": currentScreen.playbackSource.srcForAds
            "playbackContainer": currentScreen.playbackSource.playbackContainer
          }
          if currentScreen.resumePoint > 0
            resumeVideoDetailScreen(currentScreen, playbackSource)
          else
            playVideoDetailScreen(currentScreen, playbackSource)
          end if
        else
          '//by default open the detail screen
          playbackSource = {
            "srcForAnalytic": "previews"
            "srcForAds": m.constants.player.playbackOrigin.container
            "playbackContainer": currentScreen.currCategoryId
          }

          contentFocused = currentScreen.contentFocused
          if isNonEmptyString(currentScreen.lastFocusedList) = true AND currentScreen.lastFocusedList = "featuredRowList"
            contentFocused = currentScreen.featuredRowFocusedItem
          end if

          showDetailScreen(contentFocused, false, skipDetailScreen, invalid, playbackSource)
        end if
      else if isFullPlayerBlockedForUser = true
        'Updating backgroundUriList once video preview finished to show the background images instead of black background.
        currentScreen.backgroundUriList = currentScreen.backgroundUriList
      end if
    end if
  end if

  trackVideoPlayerStoppingState(videoPreviewState)
End Function


Function onVideoBufferingStatusChanged(msg)
  startVideoPreviewIfBufferingComplete()
End Function


Function startVideoPreviewIfBufferingComplete()
  videoPreview = m.videoPreviewPlayer
  bufferingStatus = m.videoPreviewPlayer.bufferingStatus
  if bufferingStatus <> invalid
    videoPreview.isBufferingComplete = (bufferingStatus.percentage = 100)
    if videoPreview.isBufferingComplete = true AND videoPreview.control <> "play"
      screen = getCurrentScreen()
      ' Making sure current screen is in focus chain before playing the video preview.
      ' This is to avoid playing the video preview when the user navigates quickly to side nav or some modal opens up.
      if screen <> invalid AND screen.isInFocusChain() = true
        sendVideoPlayerCommand(videoPreview, "play")
      else
        ' Resetting the state to none so that we reset the video preview to the default state and preview restarts properly from buggy state.
        videoPreview.state = "none"
      end if
    end if
  end if
End Function


' starts the video preview
' @content : TubiContentNode, it has all the required information to start the video preview
' @pageInfo: assocarray, value can be { pagetype: "home_page", pagevalues: {}}
' @componentInfo: assocarray, value can be { componentType: "category_page", componentValues: {}}
Function startVideoPreview(content, pageInfo = {}, componentInfo = {})
  tubiLog("VideoPreviewHelpers.startVideoPreview")
  if content <> invalid AND (isVideoPreviewOn() = true OR (content.gridItemType = m.constants.ui.gridItemTypes.skinAd AND m.constants.deviceInfo.IsAutoplayEnabled = true AND m.constants.deviceInfo.limitedUi = false))
    '//::NOTE:: if this is a skinAd content, the above conditional statement checks if the device auto play setting is on and that the device is not a limited UI device before playing the looping background video
    videoPreview = m.videoPreviewPlayer
    videoPreview.isBufferingComplete = false

    ' If the experiment is enabled and focused content is from featured row than expand preview to full screen.
    if content.gridItemType = m.constants.ui.gridItemTypes.skinAd OR content.gridItemType = m.constants.ui.gridItemTypes.adRowlistCarousel OR content.gridItemType = m.constants.ui.gridItemTypes.adRowlistSpotlight
      videoPreview.unObserveFieldScoped("position")
      videoPreview.observeFieldScoped("position", "onVideoPreviewPositionChanged")
      if content.gridItemType = m.constants.ui.gridItemTypes.adRowlistCarousel AND isCurrentScreenHomeScreen() = true
        currentScreen = getCurrentScreen()
        currentScreen.allowCarouselAutoRotate = false
      end if

      videoContent = createObject("RoSGNode", "AdContentNode")
      videoContent.adInfo = content.adInfo

    else
      videoContent = createObject("RoSGNode", "ContentNode")
      videoContent.addField("type", "string", false)
    end if

    updatePlayerLayoutBasedOnFocusedContent(content)

    ' unObserve field just in case previous state was errorsstart observing a fresh status.
    videoPreview.unObserveFieldScoped("state")
    videoPreview.observeFieldScoped("state", "onVideoPreviewStateChanged")
    videoPreview.observeFieldScoped("bufferingStatus", "onVideoBufferingStatusChanged")
    setPageInfoForVideoPreview(pageInfo)
    ' Add componentInfo to the video preview player node for analytics
    videoPreview.componentInfoForAnalytics = componentInfo

    videoContent.id = content.id
    videoContent.url = content.videoPreviewUrl
    videoContent.type = content.type
    videoContent.streamformat = "mp4" ' backend will return always as mp4 for video previews

    videoContent.addField("previewId", "string", false)
    if isString(content.previewId) = true
      videoContent.previewId = content.previewId
    else
      videoContent.previewId = ""
    end if

    if isKidsUIOn() = false AND m.isUserInVideoTilesExperiment = true
      videoContent.addField("parentCategory", "string", false)
      videoContent.parentCategory = content.parentId
    end if

    videoPreview.content = videoContent
    videoPreview.updateContent = true

    screen = getCurrentScreen()
    if isKidsUIOn() = false AND m.isUserInVideoTilesExperiment = true AND screen <> invalid AND screen.id = m.constants.ui.screenIds.homeScreen
      m.videoPreviewPlayer.videoPlayerType = "VIDEO_IN_GRID"
    else
      m.videoPreviewPlayer.videoPlayerType = "BANNER"
    end if
    m.videoPreviewPlayer.isDetailScreen = false

    ' If there is no delay, we can start the video preview immediately.
    sendVideoPlayerCommand(videoPreview, "prebuffer")
  end if

End Function


Function updatePreviewPlayerToCondensedView()
  tubiLog("VideoPreviewHelpers.updatePreviewPlayerToCondensedView")
  currentScreen = getCurrentScreen()
  if currentScreen <> invalid
    setPageInfoForVideoPreview(currentScreen.trackingPageInfo) ' this will help to trigger analytics
  end if

  m.videoPreviewPlayer.reParent(m.backgroundVideoPreviewPlayerContainer, false)
  m.videoPreviewPlayer.clippingRect = [0, 0, 1920, 1080]
  resizeToLocation(m.videoPreviewPlayer, 1120, 630, [799, 0], 0)
  m.videoPreviewPlayer.unObserveFieldScoped("position")
  m.videoPreviewPlayer.opacity = 1
End Function


Function updatePreviewPlayerToInlineView()
  tubiLog("VideoPreviewHelpers.updatePreviewPlayerToInlineView")
  if isCurrentScreenHomeScreen() = true
    screen = getCurrentScreen()

    if screen <> invalid
      setPageInfoForVideoPreview(screen.trackingPageInfo)
    end if
    playerTranslationY = 0
    playerSize = [m.inlineVideoMetadataOverlay.width, m.inlineVideoMetadataOverlay.height]

    isCloseTo16By9 = isCloseTo16By9AspectRatio(playerSize)
    if isCloseTo16By9 = false
      ' If the aspect ratio is not close to 16:9, adjust the height to 16:9
      adjustedHeight = playerSize[0] * (9 / 16)
      playerTranslationY = (playerSize[1] - adjustedHeight) / 2
    end if

    index = m.nodeHelpers.getChildIndex(m.inlineVideoPreviewPlayerContainer, m.inlineVideoMetadataOverlay)
    m.videoPreviewPlayer.width = playerSize[0]
    if isCloseTo16By9 = false
      ' If the aspect ratio is not close to 16:9, adjust the height to 16:9
      adjustedHeight = playerSize[0] * (9 / 16)
      m.videoPreviewPlayer.height = adjustedHeight
      m.videoPreviewPlayer.clippingRect = [0, Abs(playerTranslationY), playerSize[0], playerSize[1]]
    else
      m.videoPreviewPlayer.height = playerSize[1]
      m.videoPreviewPlayer.clippingRect = [0, 0, playerSize[0], playerSize[1]]
    end if
    if m.videoPreviewPlayer.getParent().isSameNode(m.inlineVideoPreviewPlayerContainer) = false OR index <> 0
      m.inlineVideoMetadataOverlay.reParent(m.inlineVideoPreviewPlayerContainer, false)
      m.videoPreviewPlayer.reParent(m.inlineVideoPreviewPlayerContainer, false)
      m.inlineVideoGridTitleLogo.reParent(m.inlineVideoPreviewPlayerContainer, false)
      m.inlinePreviewFocusIndicator.reParent(m.inlineVideoPreviewPlayerContainer, false)
    end if

    m.inlinePreviewFocusIndicator.height = playerSize[1] + 9
    m.inlinePreviewFocusIndicator.width = playerSize[0] + 12
    m.inlinePreviewFocusIndicator.translation = [0, 0]

    m.videoPreviewPlayer.unObserveFieldScoped("position")
    m.videoPreviewPlayer.observeFieldScoped("position", "onInlineVideoPreviewPositionChanged")
    m.videoPreviewPlayer.translation = [6, playerTranslationY]
    m.videoPreviewPlayer.videoPlayerType = "VIDEO_IN_GRID"
  end if
End Function


Function updatePreviewPlayerToFullScreen()
  tubiLog("VideoPreviewHelpers.updatePreviewPlayerToFullScreen")
  m.videoPreviewPlayer.reParent(m.backgroundVideoPreviewPlayerContainer, false)
  m.videoPreviewPlayer.clippingRect = [0, 0, 1920, 1080]
  m.videoPreviewPlayer.videoPlayerType = "BANNER"
  resizeToLocation(m.videoPreviewPlayer, 1919, 1079, [0, 0], 0)
End Function


Function updatePreviewPlayerToAdCarousel()
  tubiLog("VideoPreviewHelpers.updatePreviewPlayerToAdCarousel")
  m.videoPreviewPlayer.reParent(m.backgroundVideoPreviewPlayerContainer, false)
  m.videoPreviewPlayer.clippingRect = [0, 0, 1920, 595]
  resizeToLocation(m.videoPreviewPlayer, 1919, 595, [0, 0], 0)
End Function


Function updatePreviewPlayerToAdSpotlight()
  playerSize = m.constants.ui.imageSizes.adRowlistThumbnail
  if m.isUserInVideoTilesExperiment = false
    m.inlineVideoPreviewPlayerContainer.translation = [138, 168]
  else
    m.inlineVideoPreviewPlayerContainer.translation = [160, 213]
  end if

  m.inlineVideoMetadataOverlay.visible = false
  m.inlineVideoGridTitleLogo.visible = false
  nSizeDiff = 6
  m.inlinePreviewFocusIndicator.width = playerSize[0] + nSizeDiff
  m.inlinePreviewFocusIndicator.height = playerSize[1] + nSizeDiff
  m.inlinePreviewFocusIndicator.translation = [0, -nSizeDiff / 2]
  m.inlineVideoPreviewPlayerContainer.opacity = 1
  m.inlineVideoPreviewPlayerContainer.visible = true
  m.inlinePreviewFocusIndicator.visible = true
  m.inlinePreviewFocusIndicator.opacity = 1
  m.videoPreviewPlayer.reParent(m.inlineVideoPreviewPlayerContainer, false)
  m.inlinePreviewFocusIndicator.reParent(m.inlineVideoPreviewPlayerContainer, false)

  videoPlayerSize = [playerSize[0], playerSize[1]]
  m.videoPreviewPlayer.clippingRect = [0, 0, videoPlayerSize[0] - nSizeDiff, videoPlayerSize[1]]
  resizeToLocation(m.videoPreviewPlayer, videoPlayerSize[0] - nSizeDiff, videoPlayerSize[1], [nSizeDiff, 0], 0)
  m.videoPreviewPlayer.videoPlayerType = "VIDEO_IN_GRID"
End Function


Function resumeVideoPreview()
  tubiLog("VideoPreviewHelpers.resumeVideoPreview")
  videoPreview = m.videoPreviewPlayer
  if videoPreview <> invalid
    sendVideoPlayerCommand(videoPreview, "resume")
  end if

End Function


' setPageInfoForVideoPreview sets the pageType in video preview screen for analytics
' @pageInfo: assocarray, value can be { pagetype: "home_page", pagevalues: {}}
Function setPageInfoForVideoPreview(pageInfo = {})
  tubiLog("VideoPreviewHelpers.setPageTypeForVideoPreview")
  videoPreview = m.videoPreviewPlayer
  if videoPreview <> invalid
    videoPreview.pageInfoForAnalytics = pageInfo
  end if

End Function


' setVideoPreviewAfterFocus sets the proper state of the video preview video player when a video content has gained focus
' @param focusedContent, roSGNode - The TubiContentNode of the focused content
' @pageInfo: assocarray, value can be { pagetype: "home_page", pagevalues: {}}
' @componentInfo: assocarray, value can be { componentType: "category_page", componentValues: {}}
Function setVideoPreviewAfterFocus(focusedContent, pageInfo = {}, componentInfo = {})
  tubiLog("VideoPreviewHelpers.setVideoPreviewAfterFocus")
  m.videoPreviewDebounce.control = "stop"
  if focusedContent <> invalid AND focusedContent.type <> invalid AND m.SideNav.opened <> true
    if isVideoPreviewOn() = true OR focusedContent.gridItemType = m.constants.ui.gridItemTypes.skinAd OR focusedContent.gridItemType = m.constants.ui.gridItemTypes.adRowlistCarousel OR focusedContent.gridItemType = m.constants.ui.gridItemTypes.adRowlistSpotlight
      previewState = getVideoPreviewStateForThisContent(focusedContent)
      updatePlayerLayoutBasedOnFocusedContent(focusedContent)
      if previewState = "buffering" OR previewState = "playing"
        videoPreview = m.videoPreviewPlayer
        if videoPreview <> invalid
          setPageInfoForVideoPreview(pageInfo)
          if previewState = "buffering"
            startVideoPreviewIfBufferingComplete()
          end if
        end if
        if focusedContent.gridItemType <> m.constants.ui.gridItemTypes.adRowlistSpotlight
          m.backgroundGroup.posterVisible = false
        end if
      else if previewState = "paused"
        resumeVideoPreview()
      else
        ' this block is needed if user focuses to different content,
        ' it stops the preview of current content & starts the preview of new content
        stopVideoPreview()

        if isLinearPlayerPlayingThisContent(focusedContent) = false
          m.backgroundGroup.posterVisible = true
        end if

        if focusedContent.videoPreviewUrl <> ""
          startVideoPreview(focusedContent, pageInfo, componentInfo)
        end if

      end if
    else

      ' this block is needed if user focuses to different content that is not the skinAd,
      ' it ensures it stops the preview of the skinAd content if the skinAd content was the previous current content
      stopVideoPreview()
    end if

  end if
End Function


Function onVideoPreviewPositionChanged(msg)
  videoPreviewScreen = msg.getRoSGNode()
  position = msg.getData()
  duration = videoPreviewScreen.duration
  currentScreen = getCurrentScreen()
  contentFocused = currentScreen.contentFocused
  if contentFocused <> invalid AND (contentFocused.gridItemType = m.constants.ui.gridItemTypes.skinAd OR contentFocused.gridItemType = m.constants.ui.gridItemTypes.adRowlistCarousel OR contentFocused.gridItemType = m.constants.ui.gridItemTypes.adRowlistSpotlight)
    reportAdQuartileIfNeeded(contentFocused, position, duration)

    if position >= (duration - 1)
      '//this is a loop video. Display the background poster while the video buffers to show again
      m.backgroundGroup.posterVisible = true
    end if
  end if
End Function


Function reportAdQuartileIfNeeded(adItem, position, duration)
  adInfo = adItem.adInfoProcessed

  if isAA(adInfo) = true AND isNonEmptyArray(adInfo.tracking) = true AND isNumber(position) = true AND isNumber(duration) = true AND position >= 0 AND duration > 0
    trackingPixels = adInfo.tracking

    for i = 0 to trackingPixels.Count() - 1
      trackingPixel = trackingPixels[i]
      eventType = trackingPixel.event
      triggered = trackingPixel.triggered
      timeToTrigger = trackingPixel.time
      url = trackingPixel.url

      if isNonEmptyString(eventType) = true AND isBoolean(triggered) = true AND triggered = false AND isNumber(timeToTrigger) = true AND isNonEmptyString(url) = true AND position >= timeToTrigger
        tubiLog("VideoPreviewHelpers: reportAdQuartileIfNeeded(), Triggering tracking pixel for eventType: " + eventType + ", url: " + url)
        sendAdPixels([url])

        '// Mark the tracking pixel as triggered to avoid firing it again
        trackingPixel.triggered = true
      end if
    end for

    '//adInfoProcessed is not mutable so we need to assign the modified copy back to adItem.adInfoProcessed so that the changes are saved.
    adItem.adInfoProcessed = adInfo
  end if
End Function


Function onInlineVideoPreviewPositionChanged(msg)
  tubiLog("VideoPreviewHelpers.onInlineVideoPreviewPositionChanged")
  screen = getCurrentScreen()
  content = screen.featuredRowFocusedItem
  if content <> invalid
    previewState = getVideoPreviewStateForThisContent(content)
    if m.videoPreviewPlayer.visible = true AND previewState = "playing"
      m.inlineVideoMetadataOverlay.showContentPoster = false
    end if
  end if
End Function


Function updatePlayerLayoutBasedOnFocusedContent(content)
  tubiLog("VideoPreviewHelpers.updatePlayerLayoutBasedOnFocusedContent")
  currentScreen = getCurrentScreen()
  isHomeScreen = currentScreen <> invalid AND currentScreen.id = m.constants.ui.screenIds.homeScreen
  if arrayIncludes(m.constants.ui.fullScreenVideoPlayerGridItemTypes, content.gridItemType)
    ' Reducing 1px from both width and height since the player is in background and keeping full width causes roku to display closed captioning overlay.
    ' To avoid any other Roku OS level default behavior from kicking in reducing 1px to give a impression that player is not in full screen.
    updatePreviewPlayerToFullScreen()
  else if content.gridItemType = m.constants.ui.gridItemTypes.adRowlistSpotlight
    updatePreviewPlayerToAdSpotlight()
  else if content.gridItemType = m.constants.ui.gridItemTypes.adRowlistCarousel
    updatePreviewPlayerToAdCarousel()
  else if isKidsUIOn() = false AND isHomeScreen = true AND m.isUserInVideoTilesExperiment = true
    updatePreviewPlayerToInlineView()
  else
    updatePreviewPlayerToCondensedView()
  end if
End Function


' isVideoPreviewPlaying checks if the video preview is playing
' returns true if the video preview is playing, false otherwise
Function isVideoPreviewPlaying()
  return getVideoPreviewState() = "playing"
End Function


Function getVideoPreviewContentId()
  videoPreview = m.videoPreviewPlayer
  if videoPreview <> invalid AND videoPreview.content <> invalid
    return videoPreview.content.id
  end if

  return invalid
End Function
