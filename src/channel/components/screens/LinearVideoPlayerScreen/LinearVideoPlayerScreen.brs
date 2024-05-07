Function init()
  tubiLog("LinearVideoPlayerScreen.init")
  m._ = rodash()

  ' handle BaseScreen functionality (see BaseScreen.xml)
  m.constants = getConstantsFromGlobal()
  m.metadataTranslate = TubiMetadataTranslate(m.constants)
  m.top.screenLevel = m.constants.ui.screenLevels.linearVideoPlayerScreen

  trackingPageInfo = {
    pageType: "video_player_page"
    pageValues: {}
  }
  m.top.trackingPageInfo = trackingPageInfo
  m.top.trackingPageContext = trackingPageInfo

  m.NodeHelpers = TubiNodeHelpers()
  m.LoadingBackground = m.top.findNode("LoadingBackground")
  m.Loading = m.top.findNode("Loading")
  m.LoadingProgressBar = m.top.findNode("LoadingProgressBar")
  m.logoGroup = m.top.findNode("logoGroup")
  m.LoadingMessage = m.top.findNode("LoadingMessage")
  m.AdsSSAITask = m.top.findNode("PlayerAdsSSAITask")
  m.AdsSSAITask.observeField("nowPlaying", "onAdChange")

  m.Video = m.top.findNode("VideoNode") ' reference in case we change from extending Video to extending Group
  m.Video.observeFieldScoped("position", "onVideoPositionChange")
  m.Video.observeField("state", "onVideoStateChange")
  m.Video.observeField("bufferingStatus", "onBufferingStatus")
  m.Video.observeField("timedMetaData", "onId3")
  if getExperimentResource("roku_async_stop", "roku_async_stop_v5", false).enabled = true then
    m.Video.asyncStopSemantics = true
  end if

  m.notificationInterval = 0.999 ' The interval that we are targeting for player position updates. We specify a value lower than a second in order to get a float value
  m.Video.notificationInterval = m.notificationInterval

  m.Video.timedMetaDataSelectionKeys = ["*"]
  m.isClosedCaptionAudioOverlayShowing = false

  m.top.observeField("fullscreen", "onFullScreenChange")
  m.top.observeField("updateContent", "onContentChange")
  m.top.observeField("control", "onControlChange")
  m.top.observeField("pollUrlAA", "onPollUrlChange")
  m.top.observeField("closeTransport", "hideOverlay")
  m.top.observeFieldScoped("displayVideoplayerBg", "onDisplayVideoplayerBg")

  m.logo = m.top.findNode("tubiLogo")
  m.backgroundImage = m.top.findNode("backgroundImage")

  'm.VideoState is source of truth for the state of the video player for the UI
  'possible values are "play", "pause", "rew", "ffw", "stop", "refresh", "skip", "hop"
  m.VideoState = "stop"

  m.playerPosition = 0

  m.lastButtonPressPos = 0
  m.overlayAutoHideTime = m.constants.settings.videoOverlayAutoHideTime
  m.overlayLiteAutoHideTime = m.constants.settings.videoOverlayLiteAutoHideTime
  m.bufferingInfo = invalid

  'm.lastPingTime helps to prevent extra live play progress event and also helps to send live play progress event in proper interval.
  m.lastPingTime = 0

  ' m.positionArr is used to help diagnose the large playProgressEvent bug, and should be removed after a fix is in place,
  ' m.positionArr is temperory variable which is used to find whether any position callback event is missing or not.
  ' It will be attached with live-view-time-exceeds logging and cleared
  m.positionArr = []

  m.analyticsInterval = m.constants.player.pingFrequency

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.LoadingMessage, typographyConstants.ids.subheaderMedium)

  updateColors()

  if m.constants.deviceInfo.scaledUi = true then
    m.LoadingProgressBar.scaledUI = m.constants.deviceInfo.scaledUi
  end if

  ' m.didAdvanceDrm holds current state regarding if playback failed, and the player is going to try the
  ' the next video stream available
  m.didAdvanceDrm = false

  ' the video player screen should be false until placed upon the screen stack
  m.top.visible = false

  setupOverlay()

  m.tubiTrackingInfo = TubiTrackingInfo(m.constants)
  ' these are local variables to keep track of if ads are playing or content. Valus are
  ' ad = ads playing
  ' filler = filler playing
  ' content = content playing
  m.isPlayingAdsPreviousState = "content"
  m.isPlayingAdsCurrentState = "content"
End Function


' set up the video player's overlay controls
Function setupOverlay()
  if getExperimentResource("roku_linear_player_view", "roku_linear_player_view_v2", false).enabled = true
    m.VideoOverlay = m.top.findNode("VideoOverlayLite")
    m.VideoOverlay.observeFieldScoped("isClosedCaptionAudioOverlayShowing", "OnClosedCaptionAudioOverlayShowing")
    m.VideoOverlay.observeFieldScoped("trackingComponentInfo", "onTrackingComponentInfo")
  else
    m.VideoOverlay = m.top.findNode("VideoOverlay")
    m.VideoOverlay.observeFieldScoped("okPressed", "onOKPressed")
    m.VideoOverlay.observeFieldScoped("closedCaptioningSelectedLanguage", "onClosedCaptioningSelected")
    m.VideoOverlay.observeFieldScoped("epgTrackingComponentInfo", "oneEPGTrackingComponentInfoChange")
  end if
  m.VideoOverlay.observeFieldScoped("linearChannelToPlayUpdated", "onChannelSelectedToPlayChanged")
  m.VideoOverlay.observeFieldScoped("isDisplaying", "onVideoOverlayIsDisplayingChanged")
  m.VideoOverlay.observeFieldScoped("reactedToKeyPresss", "onOverlayReactedToKeyPress")
  m.VideoOverlay.visible = true
End Function


Function onTrackingComponentInfo(msg)
  trackingComponentInfo = msg.getData()
  m.top.TrackingComponentInfo = trackingComponentInfo
End Function


Function onClosedCaptionAudioOverlayShowing(msg)
  m.isClosedCaptionAudioOverlayShowing = msg.getData()
End Function


Function onVideoOverlayIsDisplayingChanged(msg)
  if msg <> invalid
    if msg.getData() = false
      '//if the overlay is no longer displaying, then change the focus to the the player
      m.Video.setFocus(true)
    end if
  end if
End Function


Function onChannelSelectedToPlayChanged()
  tubiLog("LinearVideoPlayerScreen.onChannelSelectedToPlayChanged")
  playContent = true
  if m.VideoOverlay.linearChannelToPlay.needsLogin = true
    if isLoggedInUser() = false
      m.top.control = "stop"
      m.top.channelSelected = m.VideoOverlay.linearChannelToPlay
      setVideoplayerLoadingScreenBackGround(true)
      playContent = false
    end if
  end if

  if playContent = true
    m.top.channelSelected = m.VideoOverlay.linearChannelToPlay
    setVideoplayerLoadingScreenBackGround(false)
    m.top.ChannelSelectedUpdated = true
  end if
End Function


Function playContent()
  tubiLog("LinearVideoPlayerScreen.playContent")
  m.lastButtonPressPos = 0

  'start_live_video user event analytics
  hasSubtitles = false
  if m.Video.globalCaptionMode = "On" AND m.Video.content.hasSubtitles = true AND m.top.fullscreen = true
    hasSubtitles = true
  end if

  isFullScreen = m.top.fullScreen

  videoPlayerType = "DEFAULT"
  if isFullScreen = false
    videoPlayerType = "BANNER"
  end if

  resourceType = "VIDEO_RESOURCE_TYPE_UNKNOWN"
  if m.top.content.drmType = m.constants.player.drmTypes.hlsv3
    resourceType = "VIDEO_RESOURCE_TYPE_HLSV3"
  end if

  codeType = "VIDEO_CODEC_UNKNOWN"
  if isNonEmptyString(m.Video.content.codec) = true
    codeType = "VIDEO_CODEC_" + m.Video.content.codec
  end if

  resolution = "VIDEO_RESOLUTION_UNKNOWN"
  if isNonEmptyString(m.Video.content.resolution) = true
    resolution = "VIDEO_RESOLUTION_" + m.Video.content.resolution
  end if

  trackEvent({
    type: "start_live_video"
    values: {
      video_id: m.Video.content.id.toInt()
      current_cdn: "" 'not possible for Roku client
      has_subtitles: hasSubtitles 'the video player will show subtitles at start
      video_resource_url: m.top.content.url
      video_resource_type: resourceType
      video_player: videoPlayerType
      video_codec_type: codeType
      video_resolution: resolution
      is_fullscreen: isFullScreen
      input_device: "UNKNOWN_DEVICE" 'InputDevice enum
    }
  })

  m.VideoState = "play"
  m.Video.control = "play"
End Function


Function updateColors()
  theme = getThemeFromGlobal()
  if theme <> invalid
    m.focusedColor = theme.focusedColor
    m.LoadingProgressBar.focusColor = m.focusedColor
    m.LoadingProgressBar.unfocusColor = m.focusedColor
    m.LoadingBackground.color = theme.backgroundColor
    m.LoadingProgressBar.trackColor = theme.neutralColor2
  end if
End Function


Function onContentChange() as void
  tubiLog("LinearVideoPlayerScreen.onContentChange")
  m.top.state = ""

  ' reset whats playing on state.
  m.isPlayingAdsPreviousState = "content"
  m.isPlayingAdsCurrentState = "content"

  if m.top.content <> invalid
    'set page tracking values for analytics
    m.top.trackingPageInfo = {
      pageType: "video_player_page"
      pageValues: {
        video_id: m.top.content.id.toInt()
      }
    }
  end if
End Function


' needed in case the pollUrl is set via the alias prior to the AdsSSAITask being in a "ready" state
Function onPollUrlChange()
  tubiLog("LinearVideoPlayerScreen.onPollUrlChange")
  if m.AdsSSAITask.state <> "ready"
    m.AdsSSAITask.observeField("state", "onAdsSSAITaskStateChange")
  end if
End Function


' If an ad is playing then temporary stop showing captions
Function onAdChange(msg)
  tubiLog("LinearVideoPlayerScreen.onAdChange")
  m.isPlayingAdsCurrentState = msg.getData()

  if m.isPlayingAdsCurrentState = "ad" AND m.isPlayingAdsPreviousState = "content"
    ' Send a play_progress event before we show ads to be most accurate in case the user exits during ad playback
    playProgressEvent = getPlayProgressEvent(m.top.fullscreen)
    if playProgressEvent <> invalid
      trackEvent(playProgressEvent)

      ' set m.lastPingTime here to prevent an extra playProgressEvent if a user backs out of the ads
      ' thereby triggering backButtonExit() which also sends a playProgressEvent.
      m.lastPingTime = m.playerPosition
    end if
  end if

  if m.isPlayingAdsCurrentState = "content"
    m.Video.suppressCaptions = false
  else
    m.Video.suppressCaptions = true
  end if

  if m.isPlayingAdsCurrentState = "content" AND m.isPlayingAdsPreviousState = "ad"
    trackEvent({
      type: "resume_after_break"
      values: {
        video_id: m.Video.content.id.toInt()
        position: Int(m.playerPosition * 1000) 'without Int(), can return scientific notation, causing API error
      }
    })
    ' update m.lastPingTime with current video position when ad break completes.
    ' so it will not add the viewtime of ad break in next playprogressEvent.
    m.lastPingTime = m.playerPosition
  end if

  if m.isPlayingAdsCurrentState = "content" AND m.isPlayingAdsPreviousState = "filler"
    ' update m.lastPingTime when a filler concludes that way we will not fire play progress events if there over 10 seconds of filler
    m.lastPingTime = m.playerPosition
  end if

  ' Keep track what was playing
  m.isPlayingAdsPreviousState = m.isPlayingAdsCurrentState
End Function

Function onAdsSSAITaskStateChange(msg)
  state = msg.getData()
  if state = "ready"
    m.AdsSSAITask.pollUrlAA = m.top.pollUrlAA
    m.AdsSSAITask.unobserveField("state")
  end if
End Function


Function onControlChange()
  tubiLog("LinearVideoPlayerScreen.onControlChange " + m.top.control)
  if m.top.control = "play"
    if m.top.content <> invalid
      prepareToStartVideo(m.top.content)
      playContent()
    end if

  else if m.top.control = "stop" then
    m.AdsSSAITask.playbackStopped = true
    stopVideo()
  else if m.top.control = "pause" then
    pauseVideo()
  else if m.top.control = "resume" AND m.Video.state = "paused" then
    resumeFromPause()
  else if m.top.control = "error"
    stopVideo()
    m.top.errorMsg = getTranslation("videoPlayer_error_playback_description") 'is used in error modal
    m.top.state = "error"
  end if
End Function


'Occurs when m.Video.state changes (not when m.top.state changes)
Function onVideoStateChange(msg)

  state = msg.GetData()
  tubiLog("LinearVideoPlayerScreen.onVideoStateChange, state = " + state)

  sPreviousState = m.top.state
  if state = "finished" AND m.VideoState = "play"
    if m.didAdvanceDrm = true
      ' video player always changes state to "finished" after reaching a state of "error"
      ' so we wait until the "finished" state is reached to play the next available stream for the video
      ' in order to prevent race conditions due to video player state changing.
      m.didAdvanceDrm = false
      playContent()
    else
      ' the video reached the end
      if m.Video.content <> invalid AND m.isPlayingAdsCurrentState = "content"
        ' the video has been stopped, send a final playProgressEvent
        playProgressEvent = getPlayProgressEvent(m.top.fullscreen)
        if playProgressEvent <> invalid
          trackEvent(playProgressEvent)
        end if
      end if

      m.top.state = state

    end if
  else if state = "error"
    content = m.Video.content
    errorInfo = getPlaybackErrorInfo(m.Video.position, m.Video.downloadedSegment, m.Video.streamingSegment, m.Video.streamingInfo, m.Video.errorCode, m.Video.errorMsg, content)
    jsonErrorInfo = FormatJSON(errorInfo)
    ' sending the logs to uapi
    tubiLog(jsonErrorInfo, "error", "videoPlayback", "video-playback", 0.1)

    errorInfo.type = m.constants.errors.type.videoError + " " + m.video.errorCode.toStr()
    errorInfo.name = m.constants.errors.message.linearVideoPlayer
    ' sending the logs to sentry sdk
    tubiException(errorInfo, "error", 0.1)

    m.top.sendYouboraError = true

    ' Set up the next DRM scheme. Playback of next DRM scheme is triggered when state = "finished",
    ' right after error state occurs.
    if m.Video.errorCode = -5 ' Media error; the media format is unknown or unsupported
      m.didAdvanceDrm = advanceCodecOnContent(content)
    else
      m.didAdvanceDrm = advanceDrmOnContent(content)
    end if

    if m.didAdvanceDrm <> true
      m.top.errorMsg = getTranslation("videoPlayer_error_playback_description") 'is used in error modal
      m.top.state = state 'triggers error modal in ContentController
    end if
  else if state = "stopped" AND m.VideoState = "stop"
    ' player has stopped (not due to an ad break)
    ' we don't want to send playprogress when user change channel during ad break
    if m.Video.content <> invalid AND m.isPlayingAdsCurrentState = "content"
      ' the video has been stopped, send a final playProgressEvent
      playProgressEvent = getPlayProgressEvent(m.top.fullscreen)
      if playProgressEvent <> invalid
        trackEvent(playProgressEvent)
      end if
      m.top.state = state
    end if
  else if state = "playing" AND m.VideoState <> "pause"
    ' reset the last ping time to the position at which video playback is starting or re-starting (after a seek)
    ' in order to avoid race conditions in which the video position might update while the handle logic is being completed.
    ' when video starts playing after buffering, m.lastPingTime will not get updated and remain -1, because
    ' the video.position returned from videoNode here is not accurate, so we will update lastPingTime on videoPositionChange function where we get accurate video.position
    if m.lastPingTime > -1
      m.lastPingTime = m.Video.position
    end if
  else if state = "buffering"
    ' sends the live play progress event when video buffers, this way we are not missing any viewtime
    ' This avoids higher viewTime live play progress events

    'Send play progress event only for midbuffer (not prebuffer)
    if m.playerPosition > 0 AND m.isPlayingAdsCurrentState = "content"
      playProgressEvent = getPlayProgressEvent(m.top.fullscreen)
      if playProgressEvent <> invalid
        trackEvent(playProgressEvent)
      end if
    end if

    ' setting m.lastPingTime to -1 for mid buffering, so that next time when videoPositionChange callback triggers the large live play progress event will not be sent
    if m.lastPingTime > 0
      m.lastPingTime = -1
    end if
  end if

  ' Loading page visibility
  if state = "playing" or state = "paused"
    m.Loading.visible = false
    m.top.state = state

    if m.top.state = "playing" AND (sPreviousState = "stopped" or sPreviousState = "") AND m.top.fullscreen = true
      if m.VideoOverlay.timeGridContentLoading = false AND m.VideoOverlay.timeGridContent <> invalid
        if m.top.allowTransportToAppear = true
          showOverlay(true)
        else
          if m.VideoOverlay.hasField("updateAndShowComingUpInfo") = true
            m.VideoOverlay.updateAndShowComingUpInfo = true
          end if
        end if
      end if
    end if
  else
    m.LoadingProgressBar.progress = 2
    m.Loading.visible = true
    if m.VideoOverlay <> invalid AND m.VideoOverlay.isDisplaying = true
      m.logoGroup.visible = false
    else
      m.logoGroup.visible = true
    end if
  end if

  if state = "stopped" OR state = "finished" OR state = "error" then
    m.top.timestampOfLastVideoPlayback = createObject("roDateTime").asSeconds()
  else if state = "buffering" OR state = "playing" then
    m.top.timestampOfLastVideoPlayback = -1
  end if

  if state = "stopping" then
    m.top.state = state
  end if
End Function


'''''''''''''''''''''''''
' onVideoPositionChange
'
' The notificationInterval and analyticsInterval are not necessarily equal or evenly divisible
' so we check the time passage before we send playProgress events
Function onVideoPositionChange(msg)
  floatPosition = msg.getData()

  ' position is a float so we have to convert it to an integer for our key based lookups to work correctly
  position = int(floatPosition)
  positionDecimalPart = floatPosition - position
  if positionDecimalPart > .5 then
    m.video.notificationInterval = 1 - positionDecimalPart
  else
    m.video.notificationInterval = m.notificationInterval
  end if

  m.positionArr.push(position)

  ' protects against video positions being updated after we've told the player to pause
  if m.VideoState = "play"
    m.playerPosition = position
    m.AdsSSAITask.videoPosition = position
  end if

   '//After some time has elapsed and the channel guide isn't currently visible and loading, then hide the overlay
  if m.VideoState = "play" AND m.VideoOverlay <> invalid AND m.VideoOverlay.isDisplaying = true
    if m.VideoOverlay.subtype() = "LinearVideoPlayerScreenOverlayLite" AND m.isClosedCaptionAudioOverlayShowing = false AND m.playerPosition > m.lastButtonPressPos + m.overlayLiteAutoHideTime
      hideOverlay()
    else if m.VideoOverlay.epgScrollingStatus = false AND m.playerPosition > m.lastButtonPressPos + m.overlayAutoHideTime
      hideOverlay()
    end if
  end if

  ' Analytics
  if m.lastPingTime > -1 AND m.playerPosition >= m.lastPingTime + m.analyticsInterval AND m.isPlayingAdsCurrentState = "content"
    playProgressEvent = getPlayProgressEvent(m.top.fullscreen)
    if playProgressEvent <> invalid
      m.lastPingTime = m.playerPosition
      trackEvent(playProgressEvent)
    end if
  else if m.lastPingTime = -1
    ' updating m.lastPingTime to m.playerPosition(video.position), when the m.lastPingTime is -1
    ' This happens when video starts playing right after buffering
    m.lastPingTime = m.playerPosition
  end if

End Function


' id3 tags within the linear stream are used to signify when ads are playing
Function onId3(msg)
  id3 = msg.getData()
  m.AdsSSAITask.id3Tags = id3
End Function


Function onFullScreenChange()
  ' When the linear video player changes sizes, we want to send a play progress event for the previous size.
  if m.isPlayingAdsCurrentState = "content"
    isFullScreenForPlayProgressEvent = (m.top.fullScreen <> true)
    playProgressEvent = getPlayProgressEvent(isFullScreenForPlayProgressEvent)

    if playProgressEvent <> invalid
      m.lastPingTime = m.playerPosition
      trackEvent(playProgressEvent)
    end if
  end if

  if m.top.fullScreen = true
    m.Video.observeFieldScoped("globalCaptionMode", "onCaptionModeChange")

    if m.top.state = "playing"
      if m.VideoOverlay.timeGridContentLoading = false AND m.VideoOverlay.timeGridContent <> invalid AND m.top.allowTransportToAppear = true
        '//Set the showOverlay() function's param to true to display on delay so player has time to animate into fullscreen and user has time to view the player w/o an overlay
        showOverlay(true)
      end if
    end if
  else
    m.Video.unobserveFieldScoped("globalCaptionMode")
  end if

  trackFullScreen(m.top.fullScreen)
End Function



Function trackFullScreen(bFullScreen)
  toggleState = "OFF"
  if bFullScreen = true
    toggleState = "ON"
  end if

  if m.top.content <> invalid
    trackEvent({
      type: "fullscreen_toggle"
      values: {
        video_id: m.top.content.id.toInt()
        toggle_state: toggleState 'ToggleState enum
      }
    })
  end if
End Function


Function onCaptionModeChange()
  tubiLog("LinearVideoPlayerScreen.onCaptionModeChange")

  if m.VideoOverlay <> invalid
    if m.VideoOverlay.subtype() = "LinearVideoPlayerScreenOverlay"
      hideOverlay()
      ' update the closed captions UI. It may look the same but the enabled icon may be different
      createContentForClosedCaptioning()
    else if m.VideoOverlay.subtype() = "LinearVideoPlayerScreenOverlayLite"
      m.VideoOverlay.videoNode = m.Video
    end if
  end if

  if m.Video.globalCaptionMode = "On"
    toggleState = "ON"
  else 'handles "Off", "Instant replay", and "When mute"
    toggleState = "OFF"
  end if

  if m.Video.content <> invalid then
    language = "UNKNOWN"
    for i = 0 to m.Video.availableSubtitleTracks.count() - 1
      trackInfo = m.Video.availableSubtitleTracks[i]
      if m.Video.subtitleTrack = trackInfo.TrackName
        language = m.tubiTrackingInfo.getLanguageCode(trackInfo.language)
      end if
    end for
    trackEvent({
      type: "subtitles_toggle"
      values: {
        video_id: m.Video.content.id.toInt()
        toggle_state: toggleState 'ToggleState enum
        language_code: language 'LanguageCode enum
      }
    })
  end if
End Function



Function createContentForClosedCaptioning()
  tubiLog("LinearVideoPlayerScreen.createContentForClosedCaptioning")
  bCaptionsAvailable = false
  availableSubtitleTracks = m.Video.availableSubtitleTracks
  if availableSubtitleTracks <> invalid AND availableSubtitleTracks.Count() > 0
    bCaptionsAvailable = true
  end if


  if bCaptionsAvailable = true
    root = CreateObject("roSGNode", "ContentNode")
    row = root.createChild("ContentNode")

    bCaptionsOn = false
    if m.Video.globalCaptionMode = "On"
      bCaptionsOn = true
    end if
    content = createClosedCaptioningNode("off", (not bCaptionsOn))
    row.appendChild(content)
    usedLanguage = {} '//make sure only a single language subtitle is displayed and used
    for each track in availableSubtitleTracks
      language = LCase(track.language)
      if (language = "eng" or language = "spa") AND usedLanguage[language] = invalid'//::TODO:: allow for multiple languages. When backend provides more captioning support, then this should be changed
        bEnabled = false
        if bCaptionsOn = true
          if m.Video.subtitleTrack = track.trackname
            '//Get the enabled state of language
            bEnabled = true
          end if
        end if
        usedLanguage[language] = true
        content = createClosedCaptioningNode(language, bEnabled, track.trackname)
        row.appendChild(content)
      end if
    end for

    m.VideoOverlay.closedCaptioningItems = root
  else
    m.VideoOverlay.closedCaptioningItems = invalid
  end if
End Function



Function createClosedCaptioningNode(lang, bEnabled = false, trackname = invalid)
  content = CreateObject("roSGNode", "ClosedCaptioningContentNode")
  ' content = parent.createChild("ClosedCaptioningContentNode")
  if lang = "eng"
    language_label = "English"
  else if lang = "spa"
    language_label = "Español"
  else
    language_label = getTranslation("dialog_button_off")
    trackname = "off"
  end if
  content.language_label = language_label
  content.language_id = lang
  content.trackname = trackname
  content.enabled = bEnabled
  content.isForeground = true

  return content
End Function


Function onBufferingStatus(msg)
  status = msg.GetData()
  m.LoadingMessage.text = ""
  if status <> invalid AND status.percentage <> invalid
    m.LoadingProgressBar.progress = status.percentage
  end if
End Function


Function trackEvent(event as object)
  m.top.trackingLoggingEvent = event
End Function


'exit the video player due to back button while no transport displaying, or during ad break
Function backButtonExit()
  m.top.backButtonPressed = true

  if m.VideoOverlay.hasField("animationDuration") = true
    m.VideoOverlay.animationDuration = 0
  end if

  m.VideoOverlay.hideOverlay = true

  if m.VideoOverlay.hasField("hideComingUpOverlay") = true
    m.VideoOverlay.hideComingUpOverlay = true
  end if
End Function


' Helper function that aggregates any tasks that need to be done before playing a new video
' @contentNode: roSGNode, a TubiContentNode
' @videoResourceIndex: intarray, [0] -> codexIndex & [1] -> drmIndex
Function prepareToStartVideo(content, videoResourceIndex = [0,0])
  resetVideoPlayerState(content)

  videoResources = content.videoResources
  codecIndex = videoResourceIndex[0]
  drmIndex = videoResourceIndex[1]

  resource = invalid
  if videoResources[codecIndex] <> invalid
    resource = videoResources[codecIndex][drmIndex]
  end if

  setDrmOnContent(content, resource, videoResourceIndex)

  m.AdsSSAITask.content = content
  m.AdsSSAITask.updateContent = true

  m.VideoOverlay.currentLinearVideoContent = content
  m.top.content = content 'sends content to video node and makes current content available to contentController
  m.top.sendVideoTrackingStart = true
End Function


' Reset video player state to a state relevant to starting a video
' @content: TubiContentNode
Function resetVideoPlayerState(content = invalid)
  m.LoadingProgressBar.progress = 0
  m.LoadingMessage.text = ""
  m.playerPosition = 0
  m.lastPingTime = 0

  if content <> invalid
    updateVideoPlayerState(content)
  end if
End Function


Function stopVideo()
  tubiLog("LinearVideoPlayerScreen.stopVideo")
  m.VideoState = "stop"
  ' add check so that onVideoStateChange doesn't get called
  ' if the video is already in a non playing state.
  videoNodeState = m.Video.state
  if videoNodeState <> "stopped" AND videoNodeState <> "finished" AND videoNodeState <> "none"
    getExperimentResource("roku_async_stop", "roku_async_stop_v5", true)
    m.Video.control = "stop"
  end if
End Function

Function pauseVideo()
  tubiLog("LinearVideoPlayerScreen.pauseVideo not implemented yet")
End Function


Function resumeFromPause()
  tubiLog("LinearVideoPlayerScreen.resumeFromPause not implemented yet")
End Function


' Set video player state based on passed in content
' @content: TubiContentNode
Function updateVideoPlayerState(content) as void
  if type(content) <> "roSGNode" then return

  ' make the content available to the video node
  m.Video.content = content

  if m.VideoOverlay <> invalid
    if m.VideoOverlay.subtype() = "LinearVideoPlayerScreenOverlayLite"
      m.VideoOverlay.videoNode = m.Video
    else if m.VideoOverlay.subtype() = "LinearVideoPlayerScreenOverlay"
      'Update the closed captioning
      createContentForClosedCaptioning()
    end if
  end if
End Function


' advanceCodecOnContent function gets triggered when player error occurs due to codec capability
' @contentNode: roSGNode, a TubiContentNode
Function advanceCodecOnContent(contentNode)
  tubiLog("VideoPlayer.advanceCodecOnContent")

  if contentNode <> invalid

    videoResources = contentNode.videoResources
    currentVideoResourceIndex = contentNode.currentVideoResourceIndex

    if videoResources <> invalid AND currentVideoResourceIndex <> invalid  AND currentVideoResourceIndex.Count() >= 2
      currentCodecIndex = currentVideoResourceIndex[0]
      currentDrmIndex = currentVideoResourceIndex[1]

      if videoResources[currentCodecIndex] <> invalid
        currentResource = videoResources[currentCodecIndex][currentDrmIndex]

        nextCodecIndex = currentCodecIndex + 1
        nextDrmIndex = 0

        nextResource = invalid
        if videoResources[nextCodecIndex] <> invalid
          nextResource = videoResources[nextCodecIndex][nextDrmIndex]
        end if

        if nextResource <> invalid and setDrmOnContent(contentNode, nextResource, [nextCodecIndex, nextDrmIndex]) = true

          fallbackInfo = {
            failed_url: removeExcessUrl(currentResource.url)
            failed_codec: currentResource.codec
            fallback_url: removeExcessUrl(nextResource.url)
            fallback_codec: nextResource.codec
            model: m.constants.deviceInfo.model
            video_id: contentNode.id
          }

          ' log that we fell back to the next playback option after playback failed due to Codec
          tubiLog(FormatJSON(fallbackInfo), "error", "videoLoad", "codec-fallback", 0.1)
          return true
        end if
      end if
    end if
  end if

  return false


End Function


' advanceDrmOnContent function gets triggered when player error occurs due to drm
' @contentNode: roSGNode, a TubiContentNode
Function advanceDrmOnContent(contentNode)
  tubiLog("VideoPlayer.advanceDrmOnContent")

  if contentNode <> invalid
    videoResources = contentNode.videoResources
    currentVideoResourceIndex = contentNode.currentVideoResourceIndex

    if videoResources <> invalid AND currentVideoResourceIndex <> invalid AND currentVideoResourceIndex.Count() >= 2
      currentCodecIndex = currentVideoResourceIndex[0]
      currentDrmIndex = currentVideoResourceIndex[1]

      if videoResources[currentCodecIndex] <> invalid
        currentResource = videoResources[currentCodecIndex][currentDrmIndex]

        nextCodecIndex = currentCodecIndex
        nextDrmIndex = currentDrmIndex + 1
        nextResource = invalid

        if videoResources[currentCodecIndex] <> invalid
          nextResource = videoResources[currentCodecIndex][nextDrmIndex]
        end if

        if nextResource = invalid
          nextCodecIndex = currentCodecIndex + 1
          nextDrmIndex = 0

          if videoResources[nextCodecIndex] <> invalid
            nextResource = videoResources[nextCodecIndex][nextDrmIndex]
          end if
        end if

        if nextResource <> invalid and setDrmOnContent(contentNode, nextResource, [nextCodecIndex, nextDrmIndex]) = true

          fallbackInfo = {
            failed_url: removeExcessUrl(currentResource.url)
            failed_drm: currentResource.type
            fallback_url: removeExcessUrl(nextResource.url)
            fallback_drm: nextResource.type
            model: m.constants.deviceInfo.model
            video_id: contentNode.id
          }

          ' log that we fell back to the next playback option after playback failed due to DRM
          tubiLog(FormatJSON(fallbackInfo), "error", "videoLoad", "drm-fallback", 0.1)
          return true
        end if
      end if
    end if
  end if
  return false
End Function


' Updates the content node's url and httpHeaders fields with the videoResource info indicated by the index value
'
' @contentNode: roSGNode, a TubiContentNode
' @resource: assocarray, contains manifest details
' @videoResourceIndex: intarray, [0] -> codexIndex & [1] -> drmIndex
Function setDrmOnContent(contentNode, resource, videoResourceIndex)
  if resource <> invalid
    ' reset DRM fields
    contentNode.drmParams = {}
    contentNode.encodingType = ""
    contentNode.encodingKey = ""

    ' set general fields related to DRM
    contentNode.httpHeaders = resource.drmHeaders
    contentNode.url = resource.url
    contentNode.length = resource.length
    contentNode.streamFormat = resource.streamFormat
    contentNode.drmType = resource.type
    contentNode.codec = resource.codec
    contentNode.resolution = resource.resolution
    contentNode.currentVideoResourceIndex = videoResourceIndex
    contentNode.hdcpVersion = resource.hdcpVersion

    '//set youbora field
    youboraTracking = {}
    trackingKeys = m.constants.thirdParty.youbora.trackingKeys
    youboraTracking[trackingKeys.titanVersionOrExperimentVersion] = resource.titanVersionOrExperimentVersion
    youboraTracking[trackingKeys.generatorVersion] = resource.generatorVersion
    youboraTracking[trackingKeys.ssaiVersion] = resource.ssaiVersion
    contentNode.youboraTracking = youboraTracking

    ' set DRM scheme specific fields
    if resource.type = m.constants.player.drmTypes.dashWidevine
      contentNode.drmParams = resource.drmParams
    else if resource.type = m.constants.player.drmTypes.dashPlayready
      contentNode.encodingType = resource.encodingType
      contentNode.encodingKey = resource.encodingKey
    end if
    return true
  end if
  return false
End Function


Function getPlaybackErrorInfo(position, downloadedSegment, streamingSegment, streamInfo, errorCode, errorMsg, content)
  errorInfo = {
    video_id: ""
    video_url: ""
  }
  if errorCode = -3
    errorInfo.error_message = "Server did not respond with hls segment. Potential 504 or 404. Following segment likely has issue."
    ' Check for position to be > 0 in order to prevent segments from previous videos to populate
    ' the error messaging for the current video.
    if position > 0 AND downloadedSegment <> invalid
      ' in the case of errorCode = -3, it likely means there was a 504 or 404 response from the server which ultimately was the source of the error.
      ' we get the last downloaded segment which is the last good segment instead of the current streaming segment, which may be several segments ahead of the bad segment.
      ' in this case, the segment causing the error is the segment AFTER the logged segment.
      errorInfo.segment_sequence = downloadedSegment.segSequence
      errorInfo.segment_url = removeExcessUrl(downloadedSegment.SegUrl)
      errorInfo.segment_bitrate = downloadedSegment.BitrateBps
    end if
  else if errorMsg <> invalid
    if errorCode = 0
      ' original network error message is to long:
      ' "Network error.  This could be caused by any of the following problems: (1) The server is down or unresponsive. (2) The server is unreachable. (3) There is a network setup issue on the client."
      errorInfo.error_message = "Network error"
    else
      errorInfo.error_message = errorMsg
    end if
    if position > 0 AND streamingSegment <> invalid
      ' streamingSegment can be invalid when the server returns a 504, 404, etc.
      errorInfo.segment_url = removeExcessUrl(streamingSegment.segUrl)
      errorInfo.segment_start_time = streamingSegment.segStartTime
      errorInfo.segment_sequence = streamingSegment.segSequence
      errorInfo.segment_bitrate = streamingSegment.segBitrateBps
    end if
  end if
  errorInfo.error_code = errorCode

  if content <> invalid then errorInfo.video_id = content.id

  if position > 0 AND streamInfo <> invalid
    errorInfo.video_url = removeExcessUrl(streamInfo.streamUrl)
  else if content <> invalid
    errorInfo.video_url = removeExcessUrl(content.url)
  end if

  return errorInfo
End Function


'Helper function that removes all characters after the ? in the url
Function removeExcessUrl(url)
  cutUrl = ""
  if type(url) = "roString" or type(url) = "String"
    position = url.Instr(Chr(63)) 'checks for the position of the "?" in the url string
    if position > -1
      cutUrl = url.Left(position)
    else
      cutUrl = url
    end if
  end if
  return cutUrl
End Function


' Play progress events should occur at the following instances
' a user watches for 10s
' an ad break starts
Function getPlayProgressEvent(isFullScreen = true)
  playProgressEvent = invalid

  if m.playerPosition > m.lastPingTime
    videoPlayerType = "DEFAULT"
    if isFullScreen = false
      videoPlayerType = "BANNER"
    end if

    pageType = ""
    if m.top.trackingPageContext <> invalid AND m.top.trackingPageContext.pageType <> invalid
      pageType = m.top.trackingPageContext.pageType
    end if

    viewTime = Int((m.playerPosition - m.lastPingTime) * 1000) 'ms

    playProgressEvent = {
      type: "live_play_progress"
      values: {
        video_id: m.Video.content.id.toInt()
        view_time: viewTime
        video_player: videoPlayerType
        page_type: pageType
      }
    }

    if viewTime >= 15000
      videoInfo = {}
      videoInfo.viewTime = viewTime.tostr()
      videoInfo.videoState = m.VideoState
      videoInfo.playerPosition = m.playerPosition
      videoInfo.lastPingTime = m.lastPingTime
      videoInfo.positionArr = m.positionArr
      content = m.Video.content
      if content <> invalid AND content.id <> invalid
        videoInfo.video_id = content.id
      end if
      tubiLog(FormatJSON(videoInfo), "info", "videoInfo", "live-view-time-exceeds")
    end if

    ' resetting m.positionArr everytime play progress event gets fires
    m.positionArr = []

  end if

  return playProgressEvent
End Function


'show the overlay
'
'@bDelay: boolean, the epg overlay displayed after a delay. Default is false
'@key: String, remote key press
Function showOverlay(bDelay = false, key = "")
  if getExperimentResource("roku_linear_player_view", "roku_linear_player_view_v2", true).enabled = true
    showLiteOverlay(key)
  else
    showEPGOverlay(bDelay)
  end if
End Function


'showEPGOverlay displays the EPG overlay
'
'@bDelay: boolean, the epg overlay displayed after a delay. Default is false
Function showEPGOverlay(bDelay = false)
  m.lastButtonPressPos = m.playerPosition
  m.VideoOverlay.displayWithDelay = bDelay
  m.VideoOverlay.animationDuration = .15
  m.VideoOverlay.showOverlay = true
End Function


'showLiteOverlay displays the lite overlay
'
'@key: string, remote key press
Function showLiteOverlay(key = "")
  m.lastButtonPressPos = m.playerPosition

  if key = "up"
    m.VideoOverlay.decreaseChannel = true
  else if key = "down"
    m.VideoOverlay.increaseChannel = true
  else
    m.VideoOverlay.showOverlay = true
  end if
End Function


' Hide the overlay
Function hideOverlay()
  m.VideoOverlay.hideOverlay = true

  if m.VideoOverlay.hasField("hideClosedCaptionAudioTrackOverlay") = true
    m.VideoOverlay.hideClosedCaptionAudioTrackOverlay = true
  end if
End Function


' When the overlay reacts to the key press, then ensure the timer that hides the overlay gets prolonged
Function onOverlayReactedToKeyPress()
  m.lastButtonPressPos = m.playerPosition
End Function


Function onClosedCaptioningSelected()
  '//::NOTE:: - When  m.Video.globalCaptionMode is changed, it triggers an observer which will change the enabled status of the closed captioning UI options
  if m.VideoOverlay.closedCaptioningSelectedLanguage <> invalid AND m.VideoOverlay.closedCaptioningSelectedLanguage <> ""
    m.Video.subtitleTrack = m.VideoOverlay.closedCaptioningSelectedLanguage
    m.Video.globalCaptionMode = "On"
  else
    m.Video.globalCaptionMode = "Off"
  end if
End Function


Function onKeyEvent(key as string, press as boolean) as boolean
  if press AND m.top.fullscreen = true
    tubiLog("LinearVideoPlayerScreen.onKeyEvent key = " + key)
    m.lastButtonPressPos = m.playerPosition
    if m.VideoOverlay.isDisplaying <> true
      '//only the video player is visible
      if key = "back"
        backButtonExit()
      else if m.top.state = "playing"
        '// Any button should wake the overlays as long as the video is playing
        showOverlay(false, key)
      else if m.top.state = "stopped" and m.top.channelSelected <> invalid and m.top.channelSelected.needsLogin = true and m.Loading.visible = true
        '// Any button should wake the overlay even when video is not playing and channel selected is locked
        showOverlay(false, key)
      end if
    end if

    ' Consume all key presses
    return true
  end if

  ' Allow unconsumed keypress to trickle up to ContentController, which is using
  ' keypresses to reset an inactivity timer
  return false
End Function


' dismiss the epg when ok is pressed on live program
Function onOKPressed()
  item = m.VideoOverlay.rowItemfocused
  if item <> invalid AND item.count() = 2 AND item[1] = 0
    hideOverlay()
  end if
  if m.top.channelSelected <> invalid AND  m.top.channelSelected.needsLogin = true
    m.top.ChannelSelectedUpdated = true
  end if
End Function

Function onDisplayVideoplayerBg(msg)

  if msg <> invalid
    displayBg = msg.getData()
    setVideoplayerLoadingScreenBackGround(displayBg)
  end if

End Function


Function setVideoplayerLoadingScreenBackGround(set = true)
  tubilog("LinearVideoPlayerScreen.setVideoplayerLoadingScreenBackGround")
  if set = true
    if m.VideoOverlay.linearChannelToPlay <> invalid and m.VideoOverlay.linearChannelToPlay.backgrounds <> invalid
      m.backgroundImage.uri = m.VideoOverlay.linearChannelToPlay.backgrounds[0]
      m.backgroundImage.visible = true
    end if
  else
    m.backgroundImage.uri = ""
    m.backgroundImage.visible = false
    m.backgroundImage.animationControl = "stop"
  end if

End Function


Function oneEPGTrackingComponentInfoChange(msg)
  m.top.trackingComponentInfo = msg.getData()
End Function
