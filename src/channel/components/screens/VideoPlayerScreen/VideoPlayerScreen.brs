'   Analytics tracking:
'
'      EVENT            TRIGGERS
'      ===============================
'      start_video        only on start of episode playback, or autoplay invoked playback
'
'      resume_after_ads   after pre-roll and each mid-roll
'
'      play_progress      on start of scrubbing
'                         at regular intervals set by 'pingFrequency' in constants
'
'      seek               at end of scrubbing
'
'      pause_toggle       when paused using pause/play button
'                         when resumed using pause/play button
'
'      subtitles_toggle   when subtitles turned off
'                         when subtitles turned on
'
'
'
'
'   User History tracking:
'
'      - when user exits the ad or video by pressing 'back'
'      - right before a mid-roll
'      - every 60 seconds of watching
'

Function init()
  tubiLog("VideoPlayer.init")

  ' handle BaseScreen functionality (see BaseScreen.xml)
  m.constants = getConstantsFromGlobal()
  m.top.screenLevel = m.constants.ui.screenLevels.videoPlayerScreen
  m.top.trackingPageInfo = {
    pageType: "video_player_page"
    pageValues: {}
  }

  m.top.observeFieldScoped("focusedChild", "onScreenFocusChange")

  m.top.handlesTransportVoiceRequests = true
  m._ = rodash()
  m.NodeHelpers = TubiNodeHelpers()
  Request = TubiRequest(m.constants.settings)
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)
  m.adsLimited = TubiAdsLimited(m.constants, Auth)
  m.Loading = m.top.findNode("Loading")
  m.LoadingProgressBar = m.top.findNode("LoadingProgressBar")
  m.LoadingMessage = m.top.findNode("LoadingMessage")
  m.Transport = m.top.findNode("Transport")
  m.Related = m.top.findNode("Related")
  m.Related.associatedPageName = "video_player_page"
  m.Related.observeFieldScoped("isRelatedContentFocused", "onRelatedItemFocused")
  m.Related.observeFieldScoped("selectedRelatedContentItem", "onRelatedItemSelected")
  m.Related.observeFieldScoped("keyPress", "onKeyPressWhenYMALHasFocus")
  m.UpNext = m.top.findNode("UpNext")
  m.UpNext.observeField("contentSelected", "onUpNextContentSelected")
  m.UpNext.observeField("opacity", "onUpNextOpacityChange")
  m.UpNext.observeField("autoplayMode", "onUpNextAutolayModeChange")

  m.Video = m.top.findNode("VideoNode")  ' reference in case we change from extending Video to extending Group
  m.Video.observeFieldScoped("position", "onVideoPositionChange")
  m.Video.observeField("state", "onVideoStateChange")
  m.Video.observeField("bufferingStatus", "onBufferingStatus")
  m.Video.observeField("streamingSegment", "onStreamingSegmentChange")
  m.video.observeFieldScoped("availableSubtitleTracks", "setCCAudioTransportBarVisibility")
  m.video.observeFieldScoped("availableAudioTracks", "onAvailableAudioTracksChange")

  m.top.observeField("updateContent", "onContentChange")
  m.top.observeField("sprites", "onSpritesReceived")
  m.top.observeField("control", "onControlChange")
  m.top.observeField("transportVoiceRequest", "handleTransportVoiceEvent")
  m.top.observeField("adState", "onAdStateChange")
  m.top.observeField("adProgress", "onAdProgressChange")
  m.top.observeField("displayAdLoadingMessage", "onDisplayAdLoadingMessage")
  m.top.observeField("seekTo", "onSeekToChange")
  m.top.observeFieldScoped("showYMALInFullScreen", "onShowYMALInFullScreen")

  'isPauseAdReqInProgress is the state of pauseAd requests in flight.
  'If pause ad request is in flight, we do not send another pause ad request
  m.isPauseAdReqInProgress = false

  'isPixelFiredForCurrentPauseAd helps to find whether any ad pixel fired for current pause ad.
  'Based on this field we request pause ad or reuse the previous pause ad response
  'If any pixel event is missing for current pause ad, we do not make new pause ad request
  m.isPixelFiredForCurrentPauseAd = true

  'this field holds the last fired pixel type which helps to fire the appropriate pixels in order
  m.lastFiredPixelType = ""

  'pauseAdAnimation helps for stopping the pasue ad animation
  m.pauseAdAnimation = invalid

  m.top.observeFieldScoped("sendPendingPauseAdPixel", "onSendPendingPauseAdPixel")
  m.top.observeFieldScoped("pauseAdResponse", "onPauseAdResponse")
  m.pauseAdOverlayTimer = m.top.findNode("PauseAdOverlayTimer")
  m.pauseAdOverlayTimer.observeFieldScoped("fire", "onPauseAdOverlayTimer")
  m.pauseAdOverlay = m.top.findNode("PauseAdOverlay")
  m.pauseAdOverlay.observeFieldScoped("close", "onClosePauseAdOverlay")

  m.logo = m.top.findNode("tubiLogo")
  m.logoKids = m.top.findNode("tubiKidsLogo")
  if m.constants.deviceInfo.language = "es"
    m.logoKids.uri = "pkg:/images/locale/es_ES/logo-kids-white-xlarge.png"
  end if

  m.ratingOverlay = m.top.findNode("ratingOverlay")
  m.ratingGradient = m.top.findNode("ratingGradient")
  m.ratingBar = m.top.findNode("ratingBar")
  m.ratedLabel = m.top.findNode("ratedLabel")
  m.ratedLabel.text = getTranslation("rated_Label")
  m.ratingBackground = m.top.findNode("ratingBackground")
  m.ratingLabel = m.top.findNode("ratingLabel")
  m.descriptorCode = m.top.findNode("descriptorCode")
  m.descriptorDesc = m.top.findNode("descriptorDesc")
  m.ratingOverlayTimer = m.top.findNode("ratingOverlayTimer")
  m.ratingOverlayTimer.observeField("fire", "hideRatingOverlay")

  m.ElapsedLabel = m.top.findNode("ElapsedLabel")
  m.RemainingLabel = m.top.findNode("RemainingLabel")
  m.ProgressBar = m.top.findNode("ProgressBar")
  m.TopOverlay = m.top.findNode("TopOverlay")
  m.TopHint = m.top.findNode("TopHint")
  m.ScrubTimer = m.top.findNode("ScrubTimer")
  m.HUD = m.top.findNode("HUD")
  m.AdHeadsUp = m.top.findNode("AdHeadsUp")
  m.AdHeadsUpText = m.top.findNode("AdHeadsUpText")
  m.Thumbnail = m.top.findNode("Thumbnail")

  m.VideoOverlay = m.top.findNode("VideoOverlay")
  m.VideoYMALOverlay = m.top.findNode("VideoYMALOverlay")

  m.skipCuepointsButton = m.top.findNode("SkipCuepointsButton")
  m.skipCuepointsButton.observeFieldScoped("selected", "onSkipCuepointsButtonSelected")
  m.top.playbackSource = {
    "srcForAnalytic": m.constants.player.playbackSource.unknown
    "srcForAds": m.constants.player.playbackOrigin.unknown
  }

  ' Map to store the history whether cuePoints button were shown or not.
  ' skip button for each cuepoint should only be shown once per video
  m.cuePointsHistory = {}

  m.skipCuepointsButton.uri = "pkg:/images/selector-$$RES$$.9.png"

  BackLabel = m.top.findNode("BackLabel")
  BackLabel.text = getTranslation("goBack_videoPlayer_controls")
  if m.constants.deviceInfo.uiResolution <> "FHD"
    '//if the display is not 1080, then adjust the BackLabel to ensure proper vertical alignment
    BackLabel.translation = [BackLabel.translation[0], BackLabel.translation[1] + 3]
  end if

  m.RAFAdContainer = m.top.findNode("RAFAdContainer")

  m.AdsTask = m.top.findNode("AdsTask")
  m.AdsTask.videoPlayerNode = m.top
  m.AdsTask.control = "RUN"

  'm.VideoState is source of truth for the state of the video player for the UI
  'possible values are "play", "pause", "rew", "ffw", "stop", "refresh", "skip", "hop"
  updateVideoState("stop")

  'm.scrubAmt is the 0-based level of scrub speed - current design allows for 0, 1, 2
  m.scrubAmt = -1
  m.maxScrub = m.constants.player.maxScrub
  m.scrubMultipliers = m.constants.player.scrubMultipliers
  m.scrubTimespan = CreateObject("roTimespan")
  ' m.positionAtJumpStart holds the state during FF/REW/Skips/Hops so we can tell if at the end of all user actions
  ' the user ended up moving forward or backwards from their original position. Also used for "seek" event tracking.
  m.positionAtJumpStart = -1
  m.playerPosition = 0

  ' m.previousPlayerPosition and m.previousPlayProgressCallSource are used to help diagnose the large
  ' playProgressEvent bug, and should be removed after a fix is in place.
  m.previousPlayerPosition = 0
  m.previousPlayProgressCallSource = ""

  ' m.positionArr is used to help diagnose the large playProgressEvent bug, and should be removed after a fix is in place,
  ' m.positionArr is temperory variable which is used to find whether any position callback event is missing or not.
  ' It will be attached with view-time-exceeds logging and cleared
  m.positionArr = []

  ' ratingInterval is time in seconds which helps to show tv ratings/descriptors on player
  m.ratingInterval = 0
  ' m.showRatings boolean variable is to avoid showing ratingoverlay every time when player state changes from buffering to playing.
  ' we want to show only first time when playing state happens & after every ad break & timer. Also we are setting m.showRatings = true after every ad break.
  m.showRatings = true

  ' startUpBuffering will be true for initial buffering (play/resume) and will be false when buffering happens in middle of playback
  m.startUpBuffering = true

  m.lastButtonPressPos = 0
  m.transportAutoHideTime = m.constants.player.transportAutoHideTime
  m.ymalAutoHideTime = m.constants.player.ymalAutoHideTime
  m.ignoreOptionsKey = m.constants.deviceInfo.firmwareCaptionMenu
  m.bufferingInfo = invalid

  m.bufferingTimer = m.top.createChild("Timer")
  m.bufferingTimer.duration = 10
  m.bufferingTimer.repeat = false

  'buttons
  m.TransportButtons = m.top.findNode("TransportButtons")
  m.SkipTrailerButton = m.TransportButtons.findNode("SkipTrailerButton")
  m.StartButton = m.TransportButtons.findNode("StartButton")
  m.RewindButton = m.TransportButtons.findNode("RewindButton")
  m.HopBackButton = m.TransportButtons.findNode("HopBackButton")
  m.PlayPauseButton = m.TransportButtons.findNode("PlayPauseButton")
  m.HopForwardButton = m.TransportButtons.findNode("HopForwardButton")
  m.FastForwardButton = m.TransportButtons.findNode("FastForwardButton")
  m.EndButton = m.TransportButtons.findNode("EndButton")
  m.closedCaptionAudioButton = m.top.findNode("closedCaptionAudioButton")
  m.closedCaptionAndAudioSelectionOverlay = m.top.findNode("closedCaptionAndAudioSelectionOverlay")
  m.closedCaptionAndAudioSelectionOverlay.observeFieldScoped("globalCaptionTurnedOn", "onGlobalCaptionTurnedOnChange")
  m.closedCaptionAndAudioSelectionOverlay.observeFieldScoped("globalCaptionTurnedOff", "onGlobalCaptionTurnedOffChange")
  m.closedCaptionAndAudioSelectionOverlay.observeFieldScoped("wasBackButtonSelected", "onWasBackButtonSelectedChange")
  m.closedCaptionAndAudioSelectionOverlay.observeFieldScoped("trackingEventInfo", "onTrackingEventInfoChange")
  m.closedCaptionAndAudioSelectionOverlay.observeFieldScoped("audioTrack", "onAudioTrackChange")
  m.closedCaptionAndAudioSelectionOverlayGroup = m.top.findNode("closedCaptionAndAudioSelectionOverlayGroup")

  'm.focusedNode holds the node/component which helps setting/unsetting focus to component/m.top on video player screen
  m.focusedNode = m.PlayPauseButton

  m.buttonUris = m.constants.player.transportButtons
  m.focusedButtonIndex = 0
  setFocusToComponent(m.PlayPauseButton)

  m.lastPingTime = 0
  m.lastSavedPosition = 0
  m.adPrefetchTime = 15 ' adPrefetchTime is used to help to prefetch the ad before the actual cuepoint
  m.adHeadsUpTime = 10 ' adHeadsUpTime helps to decide how long we need to show the AdHeadsup
  m.midrolls = {} ' midrolls holds all cuepoints from API response
  m.mostRecentCompletedCuepoint = -1 'used to prevent multiple resume_after_break events from firing
  m.notificationInterval = 0.999 ' The interval that we are targeting for player position updates. We specify a value lower than a second in order to get a float value
  m.Video.notificationInterval = m.notificationInterval

  ' m.isSeeking is used keep track of the time from when m.Video.control = "seek" is set until the
  ' onVideoPositionChange() callback is fired which indicates the video player has concluded the seek.
  ' While m.isSeeking is true, we will not fire playProgressEvents from the onVideoPositionChange() callback
  ' that may unexpectedly occur while the video player is in the process of performing the seek.
  m.isSeeking = false

  ' m.seekReferenceQueue is used to record the playback positions to which m.Video.seek is set.
  ' Context: setting a value on m.Video.seek will cause the onVideoPositionChange() callback to fire.
  ' We do not want playProgressEvents to fire from onVideoPositionChange() if the callback occurs due to a seek,
  ' so we check if the position associated with the onVideoPositionChange() callback is at the 0 index of
  ' m.seekReferenceQueue, and if it is, we know that the callback is firing due to seek. We use a "queue" to protect
  ' against the edge case / race condition that multiple seek events may occur prior to the onVideoPositionChange()
  ' callback being run for the first seek event. If we used a single value instead of the queue, in the event of the
  ' previously described edge case, the value would be changed by the 2nd seek event prior to the onVideoPositionChange()
  ' callback referencing the value, which would lead to badly formed playProgressEvents.
  m.seekReferenceQueue = []

  ' sometimes the firmware not sending position for videoNode, so seekReferenceQueue is not getting cleared out as we check
  ' seekReferenceQueue[] entries with playback position in onVideoPositionChange(). In this case we see invalid play progress events with large view-time.
  ' To avoid this we wanted to check playback position >= seekReferenceQueue, so that even if any position callback is missed seekReferenceQueue will be cleared out on next position callbacks.
  ' This will be running as a experiment with 5% allocation.
  m.playProgressExpEnabled = false

  if getExperimentResource("roku_large_play_progress", "roku_large_play_progress_v1", false).enabled = true
    m.playProgressExpEnabled = true
  end if

  ' this variable helps to identify whether the play progress exposure event was fired or not.
  m.wasExposureEventForPlayProgressFired = false
  m.analyticsInterval = m.constants.player.pingFrequency
  m.historyInterval1Min = m.constants.player.historyFrequency1Min 'historyInterval1Min is used for sending exposure event

  ' set to the end position of replay if caption mode is temporarily turned on during a replay
  m.replayCaptionEnd = 0

  m.thumbnailMinXOffset = 238 ' based on zeplin designs
  m.thumbnailMaxXOffset = 1920 - 238 - m.Thumbnail.width

  isScaledUI = m.constants.deviceInfo.scaledUi
  if isScaledUI = true then
    m.ProgressBar.scaledUI = isScaledUI
    m.LoadingProgressBar.scaledUI = isScaledUI
  end if

  ' m.didAdvanceDrm holds current state regarding if playback failed, and the player is going to try the
  ' the next video stream available
  m.didAdvanceDrm = false

  ' m.shouldShowUpNext holds the state of whether the up next / autoplay UI should be shown when the
  ' user reaches the credits cuepoint. Decisions to show the up next / autoplay UI will be made in each
  ' update to m.Video.position. If the position is prior to the credits cuepoint, then shouldShowUpNext
  ' should be set to true. If the position is after the credits cuepoint, then shouldShowUpNext should be
  ' set to false, and shouldShowUpNext should be reset to true at the beginning of each video playback
  m.shouldShowUpNext = true

  ' the video player screen should be false until placed upon the screen stack
  m.top.visible = false

  ' Creating internal state to track when the overlay is visible to users.
  m.isClosedCaptionAudioOverlayShowing = false

  if getExperimentResource("roku_browse_while_watching_ymal", "roku_browse_while_watching_ymal_v2", false).enabled = true
    m.skipCuepointsButtonUpTranslation = 681
    m.skipCuepointsButtonDownTranslation = 780
    m.thumbnailMaxYOffset = 825
    m.Transport.translation = [0,783]
  else
    m.skipCuepointsButtonUpTranslation = 741
    m.skipCuepointsButtonDownTranslation = 840
    m.thumbnailMaxYOffset = 888
    m.Transport.translation = [0,849]
  end if

  title = m.TopOverlay.findNode("VideoOverlayTitle")
  episodeTitle = m.TopOverlay.findNode("VideoOverlayEpisodeTitle")
  SkipTrailerButtonLabel = m.TopOverlay.findNode("SkipTrailerButtonLabel")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(BackLabel, typographyConstants.ids.bodySmallStrong)
  setTypographyOfLabel(title, typographyConstants.ids.headerMedium)
  setTypographyOfLabel(episodeTitle, typographyConstants.ids.subheaderSmall)
  setTypographyOfLabel(m.AdHeadsUpText, typographyConstants.ids.subheaderMedium)
  setTypographyOfLabel(m.ratedLabel, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.ratingLabel, typographyConstants.ids.bodySmallStrong)
  setTypographyOfLabel(SkipTrailerButtonLabel, typographyConstants.ids.bodyLargeStrong)
  setTypographyOfLabel(m.ElapsedLabel, typographyConstants.ids.subheaderMedium)
  setTypographyOfLabel(m.LoadingMessage, typographyConstants.ids.subheaderMedium)
  setTypographyOfLabel(m.RemainingLabel, typographyConstants.ids.subheaderMedium)
  setTypographyOfLabel(m.descriptorCode, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.descriptorDesc, typographyConstants.ids.bodySmall)

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


Function onScreenFocusChange()
  if m.top.hasFocus() = true then
    if m.top.adState = "adsPlaying" then
      ' If the screensaver screen takes over while an ad is paused when they leave the screensaver they are brought back to the video player screen but the focus is on the screen itself not the RAF renderer. We are manually setting it back so a user can properly resume the ad.
      rafChild = m.RAFAdContainer.getChild(0)
      if rafChild <> invalid then
        rafChild.setFocus(true)
      end if
    end if
  end if
End Function


'set the text for skipCuepoints button, making it visible and timer to autohide
'@skipCuepointsTitle: string, text of the skipCuepoints button
Function setSkipCuepointsButtonTextAndTimer(skipCuepointsTitle as string) As Void
  tubiLog("VideoPlayer.setSkipCuepointsButtonTextAndTimer")
  m.skipCuepointsButtonTimer = m.top.createChild("Timer")
  m.skipCuepointsButtonTimer.duration = 10
  m.skipCuepointsButtonTimer.repeat = false
  m.skipCuepointsButtonTimer.observeFieldScoped("fire", "autoHideSkipCuepointsButton")
  m.skipCuepointsButtonTimer.control = "start"
  m.skipCuepointsButton.text = skipCuepointsTitle
  showSkipCuepointsButton()
End Function


'Make the skipCuepoints Button visible and based on transport
'control visibility, set the translation and focus
Function showSkipCuepointsButton()
  tubiLog("videoPlayerScreen.showSkipCuepointsButton")
  xPosition = m.top.width - (m.skipCuepointsButton.boundingRect().width + 60)

  if m.HUD.opacity = 1
    m.skipCuepointsButton.translation = [xPosition, m.skipCuepointsButtonUpTranslation]
  else if m.HUD.opacity > 0
    setFocusToComponent(m.skipCuepointsButton, true)
    m.skipCuepointsButton.translation = [xPosition, m.skipCuepointsButtonUpTranslation]
  else
    setFocusToComponent(m.skipCuepointsButton, true)
    m.skipCuepointsButton.translation = [xPosition, m.skipCuepointsButtonDownTranslation]
  end if

  if m.focusedNode.isSameNode(m.Related) = false
    m.skipCuepointsButton.visible = true
  end if

End Function


'Removes the skip intro button from the screen and sets focus on the appropriate component
'@componentToFocus: roSGNode, the component to focus after the skip intro button loses focus.
'Don't send this parameter if no focus should be set (for instance if the transport is open and has focus)
Function hideSkipCuepointsButton(componentToFocus = invalid)
  m.skipCuepointsButton.visible = false
  if componentToFocus <> invalid
    if componentToFocus.isSameNode(m.top) = true
      m.skipCuepointsButton.setFocus(false)
    end if
    componentToFocus.setFocus(true)
  end if
End Function


'Autohide the SkipCuepoints button after timer reached and HUD is not visible
Function autoHideSkipCuepointsButton()
  clearSkipCuepointsTimer()
  if m.HUD.opacity < 1
    hideSkipCuepointsButton(m.top)
  end if
End Function


Function clearSkipCuepointsButtonAndTimer()
  m.skipCuepointsButton.text = ""
  clearSkipCuepointsTimer()
  hideSkipCuepointsButton(m.top)
End Function


Function clearSkipCuepointsTimer()
  if m.skipCuepointsButtonTimer <> invalid
    m.skipCuepointsButtonTimer.control = "stop"
    m.top.removeChild(m.skipCuepointsButtonTimer)
    m.skipCuepointsButtonTimer.unobserveFieldScoped("fire")
    m.skipCuepointsButtonTimer = invalid
  end if
End Function


Function playContent()
  tubilog("VideoPlayer.playContent")

  if m.Video.content <> invalid

    ' Always reset ad state when we first start playback.  Preroll fetch will populate midrolls list
    m.midrolls = {}

    ' reset the seekReferenceQueue
    m.seekReferenceQueue = []

    if m.Video.content.nowPos <> invalid AND m.Video.content.nowPos >= 0
      m.playerPosition = m.Video.content.nowPos
      m.lastSavedPosition = m.Video.content.nowPos
      updateLastPingTime(m.Video.content.nowPos)
      m.lastButtonPressPos = m.Video.content.nowPos
      m.seekReferenceQueue.push(m.Video.content.nowPos)
      seekToPosition(m.Video.content.nowPos)

      if m.Video.content.nowPos = 0
        ' At this point seekReferenceQueue will have value 0. But the player position callback starts from 1
        ' and the play progress event does not fire as per logic written in onVideoPositionChange() in 10 seconds because m.isSeeking is not setting to false.
        ' If the video is seeked to 0, set the m.isSeeking to false, so that play progress event fires correctly.
        m.isSeeking = false
      end if

    else
      m.lastButtonPressPos = 0
      updateLastPingTime(0)
    end if

    'start_video user event analytics
    if m.top.isTrailer = true
      'set up tracking for trailer
      trackEvent({
        type: "start_trailer"
        values: {
          video_id: m.Video.content.id.toInt()
          is_fullscreen: true
        }
      })
    else
      'set up tracking for normal playback
      playbackSource = m.top.playbackSource
      isLiveTv = false
      isFullScreen = true
      isEmbedded = false

      hasSubtitles = false
      if m.Video.globalCaptionMode = "On" AND m.Video.content.hasSubtitles = true
        hasSubtitles = true
      end if

      resourceType = "VIDEO_RESOURCE_TYPE_UNKNOWN"
      if m.Video.content.drmType = m.constants.player.drmTypes.dashWidevine
        resourceType = "VIDEO_RESOURCE_TYPE_DASH_WIDEVINE"
      else if m.Video.content.drmType = m.constants.player.drmTypes.dashPlayready
        resourceType = "VIDEO_RESOURCE_TYPE_DASH_PLAYREADY"
      else if m.Video.content.drmType = m.constants.player.drmTypes.dash
        resourceType = "VIDEO_RESOURCE_TYPE_DASH"
      else if m.Video.content.drmType = m.constants.player.drmTypes.hlsv6
        resourceType = "VIDEO_RESOURCE_TYPE_HLSV6"
      else if m.Video.content.drmType = m.constants.player.drmTypes.hlsv3
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
        type: "start_video"
        values: {
          video_id: m.Video.content.id.toInt()
          start_position: Int(m.playerPosition * 1000)
          current_cdn: ""   'not possible for Roku client
          has_subtitles: hasSubtitles  'the video player will show subtitles at start
          is_livetv: isLiveTv
          is_embedded: isEmbedded
          is_fullscreen: isFullScreen
          playback_source: playbackSource.srcForAnalytic
          video_player: "DEFAULT"
          video_resource_type: resourceType
          video_resource_url: m.Video.content.URL
          video_codec_type: codeType
          video_resolution: resolution
        }
      })
    end if

    updateVideoState("play")
    if m.top.enableAds = true then
      '//Set the midrolls of the videoplayer now and set the adControl state to preroll
      cuepoints = m.Video.content.cuepoints
      if cuepoints <> invalid
        ' Iterating all cuepoints and storing it in assocarray, so that we don't want to iterate on every position change(notificationInterval) of video.
        for each cuepoint in cuepoints
          tubilog("VideoPlayer: MIDROLL: " + strI(cuepoint))
          m.midrolls[strI(cuepoint)] = true
        end for
      end if
      ' Start pre-roll fetch
      m.top.adControl = "preroll"
    else

      m.Video.control = "play"

      ' Calling the set initial audio track in the start of video playback.
      ' The reason we are calling it here is to cover a use case where if we play the same video or the next video as the same value.
      ' For ex: Between different video with audio tracks the available tracks value is exactly the same value.
      ' It has 2 elements with Eng as language and track as dash/a~AAC~en~description~~2 and dash/a~AAC~en~main~~2.
      ' Which results in the observer for available audio track not being fired.
      ' With the below approach we are setting the value again using existing data from the previous content
      ' that was played by the video player, which covers the case if the previous and current content have the
      ' same audio track. In the case where the previous and current content have different audio tracks,
      ' setInitialAudioTrack() may attempt to set a track that the current content does not contain in which
      ' case Roku's video player logic will choose an audio track
      setInitialAudioTrack(m.Video.availableAudioTracks)
    end if

  end if

End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.focusedColor = theme.focusedColor
    m.ProgressBar.focusColor = m.focusedColor
    m.LoadingProgressBar.focusColor = m.focusedColor
    m.LoadingProgressBar.unfocusColor = m.focusedColor
    m.ratingBar.color = m.focusedColor
    m.ratingLabel.color = theme.primaryTextColor
    m.LoadingProgressBar.trackColor = theme.neutralColor2
    m.ProgressBar.trackColor = theme.neutralColor2
    m.SkipCuepointsButton.color = theme.backgroundColorLight2
    m.skipCuepointsButton.notFilledBackgroundColor = theme.shadeColor2
    m.closedCaptionAndAudioSelectionOverlayGroup.color = theme.shadeColor

    if theme.id = m.constants.ui.themeIDs.kidsMode
      m.logo.visible = false
      m.logoKids.visible = true
    else
      m.logo.visible = true
      m.logoKids.visible = false
    end if
  end if
End Function


Function onContentChange() As Void
  tubiLog("VideoPlayer.onContentChange")
  stopVideo()

  if m.top.content <> invalid
    'set page tracking values for analytics
    m.top.trackingPageInfo = {
      pageType: m.top.trackingPageInfo.pageType
      pageValues: {
        video_id: m.top.content.id.toInt()
      }
    }

    m.UpNext.videoId = m.top.content.id
  end if
End Function


Function onControlChange()
  tubiLog("VideoPlayer.onControlChange " + m.top.control)
  if m.top.control = "play"
    if m.top.content <> invalid
      prepareToStartVideo(m.top.content)
      playContent()
    end if

  else if m.top.control = "stop" then
    stopAdsPlayback()
    cancelReplayCaptions()
    clearSkipCuepointsButtonAndTimer()
    stopVideo()
    animateTransport("out")
    hideYMAL()
    setFocusToPlaybackControl()
    m.UpNext.stopAutoPlayTimer = true
    m.UpNext.hide = true

    'in the case where an ad break has started, but RAF does not yet have control, we want to break out of ads on back button pressed
    m.top.adControl = "stop"
  else if m.top.control = "pause" then
    pauseVideo(false, false)
  else if m.top.control = "resume" AND m.Video.state = "paused" then
    resumeFromPause(false)
  end if
End Function


'Occurs when m.Video.state changes (not when m.top.state changes)
Function onVideoStateChange(msg)
  tubiLog("VideoPlayer.onVideoStateChange " + msg.GetData())
  state = msg.GetData()

  if state = "buffering"
    m.bufferingTimer.observeFieldScoped("fire", "onBufferingTimerFired")
    m.bufferingTimer.control = "start"
  else
    ' setting startUpBuffering to false as this block will be triggered when the video is not buffering.
    m.startUpBuffering = false
    m.bufferingTimer.unobserveFieldScoped("fire")
    m.bufferingTimer.control = "stop"
  end if

  if state = "finished" AND m.VideoState = "play"
    if m.didAdvanceDrm = true
      ' video player always changes state to "finished" after reaching a state of "error"
      ' so we wait until the "finished" state is reached to play the next available stream for the video
      ' in order to prevent race conditions due to video player state changing.
      m.didAdvanceDrm = false
      ' ensure that when the new DRM resource plays, it starts where the previous resource had been playing - if it had been playing
      if m.Video.content <> invalid AND m.playerPosition >= 0
        m.Video.content.nowPos = m.playerPosition
      end if
      playContent()
    else
      ' the video reached the end
      if m.Video.content <> invalid
        ' the video has been stopped, send a final playProgressEvent
        playProgressEvent = getPlayProgressEvent("onVideoStateChange:finished")
        if playProgressEvent <> invalid
          trackEvent(playProgressEvent)
        end if

        if m.top.isTrailer = true
          trackEvent({
            type: "finish_trailer"
            values: {
              end_position: Int(m.playerPosition * 1000)
              video_id: m.Video.content.id.toInt()
            }
          })
        end if
      end if

      updateVideoState("stop")

      ' setting the m.top.state field to finished triggers autoplay content to start
      ' we don't want that trigger to fire if the up next component is still visible
      if m.UpNext.opacity = 0
        m.top.state = state
      end if

    end if
  else if state = "error"
    content = m.Video.content
    errorInfo = getPlaybackErrorInfo(m.Video.position, m.Video.downloadedSegment, m.Video.streamingSegment, m.Video.streamingInfo,m.Video.errorCode, m.Video.errorStr, content)
    jsonErrorInfo = FormatJSON(errorInfo)
    ' sending the logs to uapi
    tubiLog(jsonErrorInfo, "error", "videoPlayback", "video-playback", 0.1)

    errorInfo.type = m.constants.errors.type.videoError + " " + m.video.errorCode.toStr()
    errorInfo.name = m.constants.errors.message.videoPlayer
    ' sending the logs to sentry sdk
    tubiException(errorInfo, "error", 0.1)

    m.top.sendYouboraError = true

    if content.isTrailer = true
      m.didAdvanceDrm = false
    else
      ' Set up the next DRM scheme. Playback of next DRM scheme is triggered when state = "finished",
      ' right after error state occurs.
      if m.Video.errorCode = -5 ' Media error; the media format is unknown or unsupported
        m.didAdvanceDrm = advanceCodecOnContent(content)
      else
        m.didAdvanceDrm = advanceDrmOnContent(content)
      end if
    end if

    if m.didAdvanceDrm <> true
      m.top.errorMsg = getTranslation("videoPlayer_error_playback_description")  'is used in error modal
      m.top.state = state   'triggers error modal in ContentController
    end if
  else if state = "stopped" AND m.VideoState = "stop"
    ' player has stopped (not due to an ad break)
    if m.top.adState = "noAds" or m.top.adState = "init"
      if m.Video.content <> invalid

        ' the video has been stopped, send a final playProgressEvent
        playProgressEvent = getPlayProgressEvent("onVideoStateChange:stopped")
        if playProgressEvent <> invalid
          trackEvent(playProgressEvent)
        end if

        if m.top.isTrailer = true
          trackEvent({
            type: "finish_trailer"
            values: {
              end_position: Int(m.playerPosition * 1000)
              video_id: m.Video.content.id.toInt()
            }
          })
        end if

      end if
    end if
  end if

  ' Loading page visibility
  if state = "playing" or state = "paused"
    m.Loading.visible = false
    m.top.state = state
  else
    m.LoadingProgressBar.progress = 0
    m.Loading.visible = true
  end if

  if state = "playing"
    if m.showRatings = true AND m.ratingOverlay.opacity  = 0.0 AND m.AdHeadsUp.visible = false
      m.showRatings = false
      showRatingOverlay()
    end if
  end if

  if state = "stopped" OR state = "finished" OR state = "error" OR state = "paused" then
    m.top.timestampOfLastVideoPlayback = createObject("roDateTime").asSeconds()
  else if state = "buffering" OR state = "playing" then
    m.top.timestampOfLastVideoPlayback = -1
  end if
End Function


' updates the lastPingTime
' @position: int, this is video position
Function updateLastPingTime(position)
  m.lastPingTime = position
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

  positionLog = ""
  if position <> invalid
    positionLog = position.toStr()
  end if
  tubiLog("VideoPlayer.onVideoPositionChange position = " + positionLog)

  ' protects against video positions being updated after we've told the player to pause
  if m.VideoState = "play"
    updatePlayerPosition()  'updates m.playerPosition with m.Video.position
    m.ratingInterval = m.ratingInterval + m.Video.notificationInterval
  end if

  ' show the TV Rating/Descriptors every hour
  if m.ratingInterval  >= (60 * 60) AND m.ratingOverlay.opacity = 0.0 AND m.AdHeadsUp.visible = false
    showRatingOverlay()
  end if

  playProgressOk = true
  if m.seekReferenceQueue.Count() > 0 AND positionInSeekReferenceQueue(m.playerPosition, m.seekReferenceQueue) = true 'updates m.seekReferenceQueue as necessary
    playProgressOk = false
    m.isSeeking = false
  end if

  if m.focusedNode.isSameNode(m.Related) = true
    if m.playerPosition > m.lastButtonPressPos + m.ymalAutoHideTime AND m.isClosedCaptionAudioOverlayShowing = false
      animateTransport("out")
      hideYMAL()
      setFocusToPlaybackControl()
    end if
  else
    if m.VideoState = "play" AND m.HUD.opacity = 1 AND m.playerPosition > m.lastButtonPressPos + m.transportAutoHideTime AND m.isClosedCaptionAudioOverlayShowing = false
      animateTransport("out")
      hideYMAL()
      setFocusToPlaybackControl()
    end if
  end if

  ' Cancel temporary captions
  if m.replayCaptionEnd <> 0 AND m.playerPosition >= m.replayCaptionEnd
    cancelReplayCaptions()
  end if

  ' Analytics
  if m.VideoState = "play"
    ' videoPosition can change after the player has been paused (like right button press),
    ' we do not want to send play progress events in that case.
    if m.playerPosition >= m.lastPingTime + m.analyticsInterval AND playProgressOk = true AND m.isSeeking = false
      playProgressEvent = getPlayProgressEvent("onVideoPositionChange:playing")
      if playProgressEvent <> invalid
        updateLastPingTime(m.playerPosition)
        trackEvent(playProgressEvent)
      end if
    end if
  end if

  adState = m.top.adState
  content = m.top.content

  ' User history
  ' NOTE: historyPosition should not be set near an ad break due to race condition where RAF being
  ' invoked will cause the AuthTask thread to get stuck, never completing and staying in a "run"
  ' state perpetually.
  if (m.playerPosition > m.lastsavedPosition + m.historyInterval1Min or m.playerPosition < m.lastsavedPosition - m.historyInterval1Min) AND adState <> "adsPending"

    if m.top.isTrailer = false AND isLoggedInUser() = true AND (content.type = m.constants.ui.contentTypes.video OR content.type = m.constants.ui.contentTypes.sportsEvent)

      ' update history when interval reaches 3 minutes for treatment group OR 1 minute for control group
      if m.playerPosition > m.lastsavedPosition + m.constants.player.historyFrequency3Mins
        historyPosition(m.playerPosition)
      end if
    end if
  end if

  ' Credits Cuepoint / Up Next (Autoplay)
  if content <> invalid AND content.creditCuePoints <> invalid AND content.creditCuePoints.postlude <> invalid AND content.creditCuePoints.postlude > 0
    if m.playerPosition >= content.creditCuePoints.postlude AND m.shouldShowUpNext = true
      ' Always fire history here to fix a race condition where the user has
      ' watched beyond the cuepoint but the title doesn't get removed due
      ' to no history events triggering after the cuepoint
      historyPosition(m.playerPosition + 5)

      if m.UpNext.content <> invalid
        animateTransport("out")
        hideYMAL()
        setFocusToPlaybackControl()
        clearSkipCuepointsButtonAndTimer()
        m.UpNext.show = true
        m.UpNext.setFocus(true)
        m.shouldShowUpNext = false
        if content.id <> invalid
          trackEvent({
            type: "auto_play"
            values: {
              video_id: content.id.toInt()
              auto_play_action: "SHOW" 'AutoPlayAction enum
            }
          })
        end if
      end if
    else if m.playerPosition < content.creditCuePoints.postlude
      m.shouldShowUpNext = true
    end if

    if m.playerPosition + m.constants.player.fetchNextDuration >= content.creditCuePoints.postlude
      m.top.upNextCuepointReached = true
    end if
  end if

  'set the content, focus to SkipCuepoints and send exposure event when Skip Intro/recap/early credit cue points available
  if content <> invalid AND content.creditCuePoints <> invalid
    if isSkipIntroCuePointsReached(content.creditCuePoints)
      'implement intro
      if canSkipCuepointsButtonBeShown(m.constants.player.skipCuepointsButtonTypes.intro, playProgressOk)
        m.cuePointsHistory[m.constants.player.skipCuepointsButtonTypes.intro] = true
        skipCuepointsText = getTranslation("skipIntro_Player")
        setSkipCuepointsButtonTextAndTimer(skipCuepointsText)
      end if
    else if isSkipRecapCuePointsReached(content.creditCuePoints)
      'Implement recap
      if canSkipCuepointsButtonBeShown(m.constants.player.skipCuepointsButtonTypes.recap, playProgressOk)
        m.cuePointsHistory[m.constants.player.skipCuepointsButtonTypes.recap] = true
        skipRecapText = getTranslation("skipRecap_Player")
        setSkipCuepointsButtonTextAndTimer(skipRecapText)
      end if
    else if isSkipEarlyCreditCuePointsReached(content.creditCuePoints)
      'Implement Early credits
      if canSkipCuepointsButtonBeShown(m.constants.player.skipCuepointsButtonTypes.earlyCredits, playProgressOk)
        m.cuePointsHistory[m.constants.player.skipCuepointsButtonTypes.earlyCredits] = true
        skipEarlyCredits = getTranslation("skipEarlyCredits_Player")
        setSkipCuepointsButtonTextAndTimer(skipEarlyCredits)
      end if
    else if m.skipCuepointsButton.text <> ""
      clearSkipCuepointsButtonAndTimer()
    end if
  end if

  'Advertisements
  if m.top.enableAds = true AND m.midrolls.count() > 0 then

    m.AdHeadsUp.visible = false  ' default to AdHeadsUp being off; this will catch ff, replay, rew during the countdown

    ' attempt to fetch midroll ads before actual cuepoint
    potentialCuepoint = m.playerPosition + m.adPrefetchTime
    isCuepointPrefetchTimeReached = m.midrolls[strI(potentialCuepoint)]
    if isCuepointPrefetchTimeReached = true AND m.UpNext.opacity = 0
      m.top.adPosition = potentialCuepoint
      m.top.adControl = "midroll"
    end if

    ' show the ads countdown if appropriate (show if ads are available and within adHeadsUpTime)
    adPosition = m.top.adPosition
    if adState = "adsPending" AND isInWindow(m.playerPosition, adPosition, m.adHeadsUpTime) = true
      if m.TopOverlay.opacity = 0
        ' Don't show the ad heads up when the transport/overlay is showing, since it crowds the space of the title on the overlay
        m.ratingOverlay.opacity = 0
        showAdHeadUpText(adPosition)
      end if
    end if

    ' check midroll and fire if any
    isCuepointReached = m.midrolls[strI(m.playerPosition)]
    if isCuepointReached = true AND m.UpNext.opacity = 0

      m.AdHeadsUp.visible = false
      if adState = "adsPending" then
        ' Send a play_progress event before we show ads to be most accurate in case the user exits during ad playback
        playProgressEvent = getPlayProgressEvent("onVideoPositionChange:ads")
        if playProgressEvent <> invalid
          trackEvent(playProgressEvent)

          ' set m.lastPingTime here to prevent an extra playProgressEvent if a user backs out of the ads
          ' thereby triggering backButtonExit() which also sends a playProgressEvent.
          updateLastPingTime(m.playerPosition)
        end if

        ' update history when showing adBreak
        historyPosition(m.playerPosition)

        ' We must stop the video here, not just pause it, in order to release
        ' system resources to the RAF video player
        showAdBreak()
        m.showRatings = true
      else if adState = "noAds"
        ' when we reach the cuepoint, we find that the last ad call returned no ads

        if m.mostRecentCompletedCuepoint <> m.playerPosition
          ' If ad playback concluded, a resume_after_break event will be fired in onAdStateChange().
          ' Restarting playback after ads could also trigger this resume_after_break event to fire
          ' if the player position hits the cuepoint again. We check against m.mostRecentCompletedCuepoint
          ' to prevent two resume_after_break from firing. We need to send the resume_after_break event
          ' here if we make a request for ads but no ads are returned and we pass over the cuepoint without
          ' playing any ads.
          trackEvent({
            type: "resume_after_break"
            values: {
              video_id: m.Video.content.id.toInt()
              position: Int(m.playerPosition * 1000)  'without Int(), can return scientific notation, causing API error
            }
          })
        end if

        m.mostRecentCompletedCuepoint = -1
      end if
    end if
  end if

  ' for logging/debugging purposes, we keep track of the video position each time this function is called
  m.previousPlayerPosition = position

End Function


Function showAdHeadUpText(cuepoint)

  m.AdHeadsUp.visible = true
  seconds = stri(cuepoint - m.playerPosition).trim()
  m.AdHeadsUpText.text = getTranslation("videoPlayer_adHeadsUp", {seconds: seconds})

End Function


' Returns true if the position is between (target - window) and the target
Function isInWindow(position, target, window)
  return (position >= (target - window) AND position < target)
End Function


' onAdStateChange
'
' adState values are:
'   "ready": the ad shim task is ready and listening for updates to the adControl field (should happen once per user session)
'   "init": no ad request has yet to be made for this video (adState is reset back to init when video is about to be started)
'   "fetching": a request has been made to the ad server, awaiting a response
'   "adsPending": an ad response has been returned, the player is waiting to reach the appropriate cuepoint in order to play it
'   "adsPlaying": ads are currently playing - RAF has control
'   "adsClosed": a user has hit the back button while RAF has control, closing the ad experience
'   "noAds": an ad response has been received but there are no ads in it. Or an ad break has played to completion.
Function onAdStateChange(msg)
  adState = msg.getData()
  tubiLog("VideoPlayer.onAdStateChange adState = " + adState + " VideoState = " + m.VideoState + " Video.State = " + m.Video.state)
  if adState = "ready"
    m.top.adState = "init"
    if m.top.adControl <> ""
      ' There is a race condition that can occur during deeplinks such that m.top.adControl can be set before the adShim is listening
      ' which results in a ad/video loading screen that never loads. Reset the ad control once the ad state is in init if this is the case
      ' to fix the issue.
      m.top.adControl = m.top.adControl
    end if
  else if adState = "adsPending" AND (m.top.adControl = "preroll" or m.top.adControl = "seek") AND m.top.enableAds = true then
    ' Midrolls are triggered from position changes since they are prefetched.  Other ad breaks have
    ' video playback stopped and should play right away when we get adsPending.
    ' pre-roll or resume-roll. Play ads right away
    showAdBreak()
    m.showRatings = true
  else if adState = "noAds" AND (m.VideoState = "play" or m.VideoState = "pause" or m.VideoState = "ffw" or m.VideoState = "rew" or m.VideoState = "skip" or m.VideoState = "hop") AND m.Video.state <> "playing" then
    'The below check is to remove the resumeFrom ad param once we've already sent the resumeFrom param in the previous ad request to avoid sending it again for future midrolls if it is not expected.
    content = m.top.content
    if content.adParam <> invalid and content.adParam.resumeFrom <> invalid
      adParams = content.adParam
      adParams.resumeFrom = invalid
      content.adParam = adParams
      m.top.content = content
    end if

    ' no ads were returned from preroll or resumeroll, or we just came back from an ad break.  Make sure we start playing
    ' TODO(Chris): model the ad break more explicitly in m.VideoState so we're not trying to glean state from m.VideoState, m.Video.State, video control and ad control
    if m.Video.content.url <> invalid AND m.Video.content.url <> ""
      m.top.setFocus(true)
      m.seekReferenceQueue.push(m.playerPosition)
      seekToPosition(m.playerPosition)

      if m.playerPosition = 0
        ' At this point seekReferenceQueue will have value 0. But the player position callback starts from 1
        ' and the play progress event does not fire as per logic written in onVideoPositionChange() in 10 seconds because m.isSeeking is not setting to false.
        ' If the video is seeked to 0, set the m.isSeeking to false, so that play progress event fires correctly.
        m.isSeeking = false
      end if

      updateVideoState("play")
      updateLastPingTime(m.playerPosition) ' updating lastPingtime for extra safety

      m.Video.control = "play"

      ' sometimes position callback not getting triggered for longtime after playing Ads.
      ' so unobserving and observing it, it may trigger the position callback properly.
      m.Video.unobserveFieldScoped("position")
      m.Video.observeFieldScoped("position", "onVideoPositionChange")

      ' Adding the initial audio track here to cover use case where pre-roll ads are requested.
      ' Refer playContent for the reasoning behind why we are calling setInitialAudioTrack.
      setInitialAudioTrack(m.Video.availableAudioTracks)
      m.mostRecentCompletedCuepoint = m.playerPosition
      trackEvent({
        type: "resume_after_break"
        values: {
          video_id: m.Video.content.id.toInt()
          position: Int(m.playerPosition * 1000)    'without Int(), can return scientific notation, causing API error
        }
      })
    else
      errorMsg = getTranslation("videoPlayer_error_invalidURL_description")
      m.top.errorMsg = errorMsg
      m.top.state = "error"
      errorInfo = {
        message: errorMsg
        video_id: m.top.content.id.toInt()
        video_url: m.top.content.url
      }
      jsonErrorInfo = FormatJSON(errorInfo)
      ' sending the logs to uapi
      tubiLog(jsonErrorInfo, "error", "videoPlayback", "invalid-video-url", 0.1)

      errorInfo.type = m.constants.errors.type.videoError
      errorInfo.name = m.constants.errors.message.invalidVideoUrl
      ' sending the logs to sentry sdk
      tubiException(errorInfo, "error", 0.1)
    end if
  else if adState = "adsClosed"
    m.top.setFocus(true)
    backButtonExit()
  end if
End Function


Function onSpritesReceived(msg)
  thumbnailsInfo = msg.getData()  'expect a TubiContentNode with thumbnail fields populated

  m.Thumbnail.visible = false   ' always start with thumbnail invisible, then show it when scrubbing

  if thumbnailsInfo <> invalid
    ' sprites are reset to invalid when video playback stops. Don't log when that happens because
    ' it's confusing when reading the logs.
    tubiLog("VideoPlayer.onSpritesReceived")

    if thumbnailsInfo.thumbnailUrls <> invalid AND thumbnailsInfo.thumbnailUrls.count() > 0
      m.Thumbnail.numSprites = thumbnailsInfo.thumbnailSpan
      m.Thumbnail.rows = thumbnailsInfo.thumbnailRows
      m.Thumbnail.columns = thumbnailsInfo.thumbnailColumns
      m.Thumbnail.spriteUrls = thumbnailsInfo.thumbnailUrls
      m.Thumbnail.jumpToSprite = 0
      ' Always keep height of thumbnail the same, varying the width if necessary
      thumbnailAspect = thumbnailsInfo.thumbnailSize[0] / thumbnailsInfo.thumbnailSize[1]
      m.Thumbnail.thumbnailWidth = thumbnailsInfo.thumbnailSize[0]
      m.Thumbnail.thumbnailHeight = thumbnailsInfo.thumbnailSize[1]
      m.Thumbnail.width = m.Thumbnail.height * thumbnailAspect
      m.thumbnailMaxXOffset = 1920 - 238 - m.Thumbnail.width
      m.Thumbnail.translation = [m.thumbnailMinXOffset, m.thumbnailMaxYOffset - m.Thumbnail.height]
    else
      ' reset the sprites
      m.Thumbnail.visible = false
      m.Thumbnail.numSprites = 0
      m.Thumbnail.spriteUrls = []
    end if
  else
    ' reset the sprites
    m.Thumbnail.visible = false
    m.Thumbnail.numSprites = 0
    m.Thumbnail.spriteUrls = []
  end if
End Function


' upNextContentSelected is set when the autoplay countdown timer expires
' or a user selects a content with the remote
Function onUpNextContentSelected(msg)
  contentSelected = msg.getData()
  ' can be invalid when up next content is reset when new video is played
  ' we don't want to trigger potential animations at that point.
  if contentSelected <> invalid
    tubiLog("VideoPlayer.onUpNextContentSelected")
    m.UpNext.hide = true
  end if

  m.top.trackingComponentInfo = {
    componentType: "auto_play_component"
    componentValues: {
      content_tile: m.Tracking.getAnalyticsTile(contentSelected, m.UpNext.itemFocused + 1, 1)
    }
  }

  ' if contentSelected is invalid, it is handled by the callback in VideoHelpers
  m.top.upNextContentToAutoplay = contentSelected
  setFocusToPlaybackControl()
End Function


Function onUpNextOpacityChange(msg)
  opacity = msg.getData()

  ' in the case that the video finished and the up next UI was still showing, we did not update m.top.state
  ' which triggers the next video to autoplay. But now the up next UI has been closed, so we
  ' are ready to trigger the autoplay by setting m.top.state
  if opacity = 0 AND m.VideoState = "stop"
    ' we hard code finished instead of referencing m.VideoPlayer.state because m.VideoPlayer.state
    ' changes from "playing" to "finished" and then to "stopped" when video playback completes and
    ' VideoHelpers is looking specifically for the "finished" state.
    m.top.state = "finished"
  end if
End Function


Function onDisplayAdLoadingMessage()
  if m.top.displayAdLoadingMessage = true
    m.LoadingMessage.text = getTranslation("videoPlayer_adLoadingMessage")
  end if
End Function


Function onAdProgressChange(msg)
  progress = msg.GetData()
  m.LoadingProgressBar.progress = progress
End Function


Function onBufferingStatus(msg)
  status = msg.GetData()
  m.LoadingMessage.text = ""
  if status <> invalid AND status.percentage <> invalid
    m.LoadingProgressBar.progress = status.percentage
  end if
End Function


Function onBufferingTimerFired()

  m.bufferingTimer.unobserveFieldScoped("fire")
  m.bufferingTimer.control = "stop"

  content = m.Video.content
  errorInfo = getPlaybackErrorInfo(m.Video.position, m.Video.downloadedSegment, m.Video.streamingSegment, m.Video.streamingInfo, m.Video.errorCode, m.Video.errorStr, content)

  if m.startUpBuffering = true
    tubiLog(FormatJSON(errorInfo), "warn", "videoBuffer", "video-buffer-startup", 0.1)
  else
    tubiLog(FormatJSON(errorInfo), "warn", "videoBuffer", "video-re-buffer", 0.1)
  end if

End Function



' Helper function to prevent tracking events being sent for trailers
Function trackEvent(event As Object)
  allowedTrailerEvents = {
    "start_trailer": true
    "trailer_play_progress": true
    "finish_trailer": true
  }

  if m.top.isTrailer = false or allowedTrailerEvents[event.type] = true
    m.global.trackingLoggingTask.trackEvent = event
  end if
End Function


' Helper function to prevent historyPosition being sent during trailers
Function historyPosition(position)
  if m.top.isTrailer = false
    ' round the position up/down based on 0.5 rule.
    ' this is necessary since isAtPosition() is returning true if the decimal is greater than 0.5.
    ' If we do not round here, and a user exits the video player during ad playback, the history would be
    ' stored always rounding down, but the ad check is done while rounding up over 0.5. So, if a user then
    ' resumes playback, the ad call sends the position as 1 second less than the midroll cuepoint, and
    ' no ads are returned, when they should be returned.
    position = round(position)
    m.top.historyPosition = position
    m.lastSavedPosition = position
  end if
End Function


Function cancelReplayCaptions()
  if m.video.globalCaptionMode = "On" AND m.replayCaptionEnd <> 0
    tubilog("Turning off replay captions")
    m.replayCaptionEnd = 0
    m.video.globalCaptionMode = "Instant replay"
  end if
End Function


'exit the video player due to back button while no transport displaying, or during ad break
Function backButtonExit()
  m.top.backButtonPressed = true
End Function


' Make sure the Video node is stopped and we have an accurate playback position before launching ads
Function showAdBreak()
  ' leave m.VideoState = "play" because from the component's perspective video is still playing
  m.Video.control = "stop"
  hideClosedCaptionAudioTrackOverlay()  ' if dialog is showing, it's awkward to have it still show after ad break

  m.top.adPosition = m.playerPosition
  m.top.adControl = "play"

  ' Update to notify we're still playing just an ad instead
  m.top.timestampOfLastVideoPlayback = -1
End Function


' Helper function that aggregates any tasks that need to be done before playing a new video
' @contentNode: roSGNode, a TubiContentNode
' @videoResourceIndex: intarray, [0] -> codexIndex & [1] -> drmIndex
Function prepareToStartVideo(content, videoResourceIndex = [0,0])

  resetVideoPlayerState(content)
  resetPauseAd()
  resetPauseAdTimers()
  m.Video.observeFieldScoped("globalCaptionMode", "onCaptionModeChange")

  videoResources = content.videoResources
  codecIndex = videoResourceIndex[0]
  drmIndex = videoResourceIndex[1]

  resource = invalid
  if videoResources <> invalid AND videoResources[codecIndex] <> invalid
    resource = videoResources[codecIndex][drmIndex]
  end if

  setDrmOnContent(content, resource, videoResourceIndex)

  m.top.content = content  'sends content to video node and makes current content available to contentController
  m.top.sendVideoTrackingStart = true
End Function


Function onCaptionModeChange(msg)
  globalCaptionMode = msg.getData()
  setAudioSubtitleTransportBarIcon(globalCaptionMode)
End Function


' Reset video player state to a state relevant to starting a video
' @content: TubiContentNode
Function resetVideoPlayerState(content = invalid)
  ' setting startUpBuffering to true as this function will be triggered when user tries to play or resume video
  m.startUpBuffering = true
  m.Video.position = 0
  m.LoadingProgressBar.progress = 0
  m.LoadingMessage.text = ""
  cancelReplayCaptions()
  m.AdHeadsUp.visible = false
  m.top.adPosition = 0

  m.pauseAdOverlay.opacity = 0
  m.ratingOverlay.opacity = 0
  m.showRatings = true
  m.ratingInterval = 0

  if content <> invalid
    m.top.adPosition = content.nowPos
    updateVideoPlayerState(content)
  end if

  m.isPauseAdReqInProgress = false
  m.isPixelFiredForCurrentPauseAd = true
  m.lastFiredPixelType = ""

  m.top.adState = "init"
  m.top.upNextContentToAutoplay = invalid
  m.shouldShowUpNext = true
  m.UpNext.resetContent = true

  m.RewindButton.uri = m.buttonUris.rewind
  m.FastForwardButton.uri = m.buttonUris.fastforward

  clearSkipCuepointsButtonAndTimer()
  m.cuePointsHistory = {}
  ' Set the icon for audio/subtitle track based on the closed caption display status.
  setAudioSubtitleTransportBarIcon(m.Video.globalCaptionMode)
  ' Hiding the closed caption and audio overlay on every playback start if in case it is open.
  m.isClosedCaptionAudioOverlayShowing = false
  m.closedCaptionAndAudioSelectionOverlayGroup.opacity = 0
End Function


Function stopAdsPlayback()
  tubilog("VideoPlayer.stopAdsPlayback")

  renderer = m.RAFAdContainer.getChild(0)
  rendererType = getNodeSubtype(renderer)
  if rendererType = "RAFContentRenderer" then
    ' stitched ads renderer
    renderer.control = "stop"
  else if rendererType = "RAFRenderer" then
    ' nonstitched ads renderer
    renderer.stopAd = true
  end if
End Function


Function stopVideo()
  tubilog("VideoPlayer.stopVideo")
  m.Video.unobserveFieldScoped("globalCaptionMode")
  videoState = m.videoState

  ' updating last ping time with current player position if the video is not playing OR not paused.
  ' this happens when user presses home button during seek
  ' this prevents firing play progress event with larger view-time in stopped video state observer.
  if videoState <> "play" AND videoState <> "pause"
    updateLastPingTime(m.playerPosition)
  end if

  updateVideoState("stop")

  ' add check so that onVideoStateChange doesn't get called
  ' if the video is already in a non playing state.
  if videoState <> "stop"
    m.Video.control = "stop"
  end if
End Function


' wrapper around setting a value on m.Video.seek to protect against trying to seek to negative
' values. Seeking to negative values will lead m.Video.seek field to equal 1.844674407371e+16 which
' may or may not cause weird behavior
' @position: integer, the playback position to seek to
Function seekToPosition(position)
  if position < 0
    position = 0
  end if

  if m.playProgressExpEnabled = true
    m.isSeeking = true
  end if

  m.Video.seek = position
End Function


' Set video player state based on passed in content
' @content: TubiContentNode
Function updateVideoPlayerState(content) as Void
  if type(content) <> "roSGNode" then return
  ' make the content available to the video node
  m.Video.content = content
  m.ratingLabel.text = ""
  if content.rating <> invalid AND content.rating <> ""

    m.ratingLabel.width = 0
    m.ratingLabel.text = Ucase(content.rating)
    nRatingBoundingBoxIncrease = m.ratingLabel.boundingRect().width + 24
    m.RatingBackground.width = nRatingBoundingBoxIncrease
    m.ratingLabel.width = nRatingBoundingBoxIncrease

  end if
  m.descriptorCode.text = ""
  descriptorCode = content.descriptorCode
  sDescriptorCodeText = ""
  if descriptorCode <> invalid AND descriptorCode <> ""
    sDescriptorCodeText = UCase(descriptorCode)
  end if
  m.descriptorCode.text = sDescriptorCodeText


  descriptorDescription = content.descriptorDescription
  sDescriptorDescText = ""
  ' if the descriptor is not present, reduce the height of rating bar
  if descriptorDescription <> invalid AND descriptorDescription <> ""
    sDescriptorDescText = descriptorDescription
    m.ratingBar.height = 87
  else
    m.ratingBar.height = 45
  end if
  m.descriptorDesc.text = sDescriptorDescText

  ' add the title and episode title to the overlay
  title = m.TopOverlay.findNode("VideoOverlayTitle")
  'This field is also used to display the gameInfo for Replay sports
  episodeTitle = m.TopOverlay.findNode("VideoOverlayEpisodeTitle")
  if content.parentType = "series"
    title.text = content.parentTitle
    episodeTitle.text = content.title
  'TODO: check once the API data is ready and remove the hardcoded values
  else if content.parentType = m.constants.uapiContentTypes.sportsEvent
    title.text = content.title
    '// REMOVE BELOW CODE ONCE FIFA WORLD CUP IS DONE
    episodeTitleText = ""
    if content.length <> invalid and content.length <> 0
      ' add 'dot' spacer only if we had a release date
      if episodeTitleText.len() > 0
        episodeTitleText = episodeTitleText + Chr(&hb7) + " "
      end if
      episodeTitleText = episodeTitleText + formatLengthSelectedLocale(content.length) + " "
    end if
    episodeTitle.text = "" '.matchTime + " . " + episodeTitleText
  else
    title.text = content.title
    episodeTitle.text = ""
  end if

  'if it's not a trailer, remove the skip trailer button
  if content.isTrailer = false
    m.TransportButtons.removeChild(m.SkipTrailerButton)

  'add the skip trailer button if it's a trailer and it doesn't already exist on the transport
  else if m.NodeHelpers.getChildIndex(m.TransportButtons, m.SkipTrailerButton) < 0
    m.TransportButtons.insertChild(m.SkipTrailerButton, 0)
  end if
End Function


' advanceCodecOnContent function gets triggered when player error occurs due to codec capability
' @contentNode: roSGNode, a TubiContentNode
Function advanceCodecOnContent(contentNode)
  tubiLog("VideoPlayer.advanceCodecOnContent")

  if contentNode <> invalid
    videoResources = contentNode.videoResources
    currentVideoResourceIndex = contentNode.currentVideoResourceIndex

    if videoResources <> invalid AND currentVideoResourceIndex <> invalid AND currentVideoResourceIndex.Count() >= 2
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
  tubiLog("VideoPlayer.setDrmOnContent")

  if resource <> invalid
    ' reset DRM fields
    contentNode.drmParams = {}
    contentNode.encodingType = ""
    contentNode.encodingKey = ""

    ' set general fields related to DRM
    contentNode.httpHeaders = resource.drmHeaders
    contentNode.url = resource.url
    contentNode.titanVersionOrExperimentVersion = resource.titanVersionOrExperimentVersion
    contentNode.length = resource.length
    contentNode.streamFormat = resource.streamFormat
    contentNode.drmType = resource.type
    contentNode.codec = resource.codec
    contentNode.resolution = resource.resolution
    contentNode.currentVideoResourceIndex = videoResourceIndex
    contentNode.hdcpVersion = resource.hdcpVersion

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


Function getPlaybackErrorInfo(position, downloadedSegment, streamingSegment, streamInfo, errorCode, errorStr, content)
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
  else if errorStr <> invalid
    errorInfo.error_message = errorStr
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
' a user begins a "seek" functionality (skip 10s, hop 30s, ff/rew, jump to beginning)
' a user selects to "jump to next video"
'
' @callSource: string, temporary param used for debugging large playProgressEvents,
'              should be removed after issue is fixed.
Function getPlayProgressEvent(callSource = "")
  playProgressEvent = invalid
  if m.playerPosition > m.lastPingTime

    viewTime = Int((m.playerPosition - m.lastPingTime) * 1000)   'ms

    playProgressEvent = {
      type: "play_progress"
      values: {
        video_id: m.Video.content.id.toInt()
        position: Int(m.playerPosition * 1000)   'ms - without Int(), can return scientific notation, causing API error
        view_time: viewTime
        video_player: "DEFAULT"
      }
    }

    ''//::TODO:: Remove this block once the play_progress viewtime value exceeds 15000 issue fixed - added this for debugging purpose
    if viewTime >= 15000
      adState = m.top.adState
      videoInfo = {}
      videoInfo.adState = adState
      videoInfo.viewTime = viewTime.tostr()
      videoInfo.videoState = m.VideoState
      videoInfo.playerPosition = m.playerPosition
      videoInfo.previousPlayerPosition = m.previousPlayerPosition
      videoInfo.callSource = callSource
      videoInfo.previousCallSource = m.previousPlayProgressCallSource
      videoInfo.positionArr = m.positionArr
      tubiLog(FormatJSON(videoInfo), "info", "videoInfo", "view-time-exceeds")
    end if

    ' resetting m.positionArr everytime play progress event gets fires
    m.positionArr = []

    if m.top.isTrailer = true
      playProgressEvent.type = "trailer_play_progress"
    else
      playProgressEvent.values.playback_source = m.top.playbackSource.srcForAnalytic
    end if

    'nominal_speed will be added to the Connection message, rather than the PlayProgressEvent message,
    'but is still sent via this interface
    if m.Video.streamInfo <> invalid AND m.Video.streamInfo.measuredBitrate <> invalid
      'measuredBitrate appears to be reported in bits despite the documentation that it is kibibits
      playProgressEvent.values.nominal_speed = Int(m.Video.streamInfo.measuredBitrate / (10^6))
    end if
  end if

  m.previousPlayProgressCallSource = callSource
  return playProgressEvent
End Function


' This function potentially modifies seekReferenceQueue if the position is found in the seekReferenceQueue
' @position: float, check if this value exists in the seekReferenceQueue
' @seekReferenceQueue: array, m.seekReferenceQueue
Function positionInSeekReferenceQueue(position, seekReferenceQueue)
  ' iterate the seekReferenceQueue until we find an index that contains the position.
  ' Once we find that position, remove all indexes up to and including the index that contains the position.

  ' This iteration is done to account for a potential edge case where there are seeks in the seekReferenceQueue that
  ' do not have this function called on them, so we clean out the queue when a seek position is successfully found
  ' in the queue.

  ' //REMOVE roku_large_play_progress_v1 related logics once we graduate roku_large_play_progress
  for i=0 to seekReferenceQueue.count() - 1

    positionMatchesWithSeekReferenceQueue = false
    if m.playProgressExpEnabled = true
      positionMatchesWithSeekReferenceQueue = (seekReferenceQueue[i] <= position) ' this handles if video node not returned any callback position
    else
      positionMatchesWithSeekReferenceQueue = (seekReferenceQueue[i] = position)
    end if

    ' fire exposure event for roku_large_play_progress_v1 for both treatment & control only once
    if m.wasExposureEventForPlayProgressFired = false
      getExperimentResource("roku_large_play_progress", "roku_large_play_progress_v1", true)
      m.wasExposureEventForPlayProgressFired = true
    end if

    if positionMatchesWithSeekReferenceQueue = true

      j = 0
      while j <= i
        seekReferenceQueue.shift()
        j += 1
      end while

      return true
    end if

  end for

  return false
End Function


Function setAutoplayMode(mode)
  autoplayModes = {
    automatic: true
    deliberate: true
    unknown: true
  }

  if autoplayModes[mode] <> true
    mode = "unknown"
  end if

  m.top.autoplayMode = mode
End Function


' m.top.autoplayMode can take the value from the UpNext component, but also be updated
' from within the VideoPlayer component
Function onUpNextAutolayModeChange(msg)
  setAutoplayMode(msg.getData())
End Function


Function onStreamingSegmentChange(msg)
  streamingSegment = msg.GetData()

  'setting segInfo except for audio
  if streamingSegment <> invalid AND streamingSegment.segBitrateBps <> invalid AND (streamingSegment.segType = invalid or streamingSegment.segType = 2 or streamingSegment.segType = 0) then
    m.top.segInfo = streamingSegment
  end if
End Function


' showratingOverlay helps to show the rating overlay and start the timer to hide it after certain amount of time.
Function showRatingOverlay()

  content = m.Video.content
  if content <> invalid AND isNonEmptyString(content.rating) = true
    fade(m.ratingOverlay, "in", 0.6)
    if m.TopOverlay.opacity > 0.0
      m.ratingOverlay.translation = [0,250]
    else
      m.ratingOverlay.translation = [0,0]
    end if
    m.ratingOverlayTimer.control = "start"
  end if

End Function


' hideRatingOverlay helps to hide the rating overlay and reset the rating Interval.
Function hideRatingOverlay()

  if m.ratingOverlay.opacity  > 0
    ' resetting ratingInterval to zero, because we don't want to show the ratingOverlay immediately after hiding
    m.ratingInterval = 0
    fade(m.ratingOverlay, "out", 0.6)
  end if

End Function


' This function tells whether the SkipCuepoints/SkipRecap/SkipEarlyCredits is already shown or not created yet.
' @skipCuepointsButtonId: string, the cuepoint button type, one of the options in m.constants.player.skipCuepointsButtonTypes
' @isPlaying: boolean, videoPosition can change after the player has been paused (like right button press),
' we do not want to show when it's fastforward/rewind/buffering or already showing/shown
Function canSkipCuepointsButtonBeShown(skipCuepointsButtonType, isPlaying)
  return isSkipCuepointButtonAlreadyShown(skipCuepointsButtonType) = false AND isPlaying = true AND m.skipCuepointsButton.visible = false
End Function


' @skipCuepointsButtonId: string, the cuepoint button type, one of the options in m.constants.player.skipCuepointsButtonTypes
Function isSkipCuepointButtonAlreadyShown(skipCuepointsButtonType)
  return (m.cuePointsHistory[skipCuepointsButtonType] = true)
End Function


'This function to check Whether the current player position is in between skipCuepoints cuePoints
'@creditCuePoints: assocArray, which has intro, recap, earlyCredit cuepointes and prelogue and postlude
Function isSkipIntroCuePointsReached(creditCuePoints)
  return creditCuePoints.intro_start <> invalid AND creditCuePoints.intro_end <> invalid AND creditCuePoints.intro_start > 0 AND m.playerPosition >= creditCuePoints.intro_start AND m.playerPosition <= creditCuePoints.intro_end
End Function


'This function to check Whether the current player position is in between skipRecap cuePoints
'@creditCuePoints: assocArray, which has intro, recap, earlyCredit cuepointes and prelogue and postlude
Function isSkipRecapCuePointsReached(creditCuePoints)
  return creditCuePoints.recap_start <> invalid AND creditCuePoints.recap_end <> invalid AND creditCuePoints.recap_start > 0 AND m.playerPosition >= creditCuePoints.recap_start AND m.playerPosition <= creditCuePoints.recap_end
End Function


'This function to check Whether the current player position is in between skipEarlyCredits cuePoints
'@creditCuePoints: assocArray, which has intro, recap, earlyCredit cuepointes and prelogue and postlude
Function isSkipEarlyCreditCuePointsReached(creditCuePoints)
  return creditCuePoints.earlycredits_start <> invalid AND creditCuePoints.earlycredits_end <> invalid AND creditCuePoints.earlycredits_start > 0 AND m.playerPosition >= creditCuePoints.earlycredits_start AND m.playerPosition <= creditCuePoints.earlycredits_end
End Function


' @creditCuePoints: assocArray, which has intro, recap, earlyCredit cuepointes and prelogue and postlude
' @returns: string, one of the values in constants.player.skipCuepointsButtonTypes or empty string if
'                   the current playback position does not correspond to one of the cuepoints
Function getCurrentCuepoint(creditCuePoints)
  currentCuepoint = ""

  if isSkipIntroCuePointsReached(creditCuePoints) = true
    currentCuepoint = m.constants.player.skipCuepointsButtonTypes.intro
  else if isSkipRecapCuePointsReached(creditCuePoints) = true
    currentCuepoint = m.constants.player.skipCuepointsButtonTypes.recap
  else if isSkipEarlyCreditCuePointsReached(creditCuePoints) = true
    currentCuepoint = m.constants.player.skipCuepointsButtonTypes.earlyCredits
  end if

  return currentCuepoint
End Function


' Extracts the credit cuepoints AA from the passed in content, or returns an empty AA, so that the output
' can be used with isSkipIntroCuePointsReached() etc.
' @content: roSGNode, ContentNode
Function getCreditCuepointsFromContent(content)
  creditCuePoints = {}
  if content <> invalid and content.creditCuePoints <> invalid
    creditCuePoints = content.creditCuePoints
  end if

  return creditCuePoints
End Function


Function setCCAudioTransportBarVisibility()
  isCCOrAudioAvailable = m.Video.availableAudioTracks.Count() > 1 OR m.Video.availableSubtitleTracks.Count() > 0
  m.closedCaptionAudioButton.visible = (isCCOrAudioAvailable = true)
  m.closedCaptionAudioButton.enabled = (isCCOrAudioAvailable = true)
End Function


Function onGlobalCaptionTurnedOnChange(msg)
  if msg.getData() = true
    m.Video.globalCaptionMode = "On"
  end if
  setAudioSubtitleTransportBarIcon("On")
End Function


Function onGlobalCaptionTurnedOffChange(msg)
  if msg.getData() = true
    m.Video.globalCaptionMode = "Off"
  end if
  setAudioSubtitleTransportBarIcon("Off")
End Function


Function onWasBackButtonSelectedChange(msg)
  wasSelected = msg.getData()

  if wasSelected = true
    hideClosedCaptionAudioTrackOverlay()
  end if
End Function


Function onTrackingEventInfoChange(msg)
  eventInfo = msg.getData()
  trackEvent(eventInfo)
End Function


' @captionMode: string, will contain the current caption mode, "On"/"Off"/"Instant replay" are the possible values
Function setAudioSubtitleTransportBarIcon(captionMode)
  if captionMode = "Off"
    m.closedCaptionAudioButton.uri = "pkg:/images/transport/sgplayer/icon-subtitles.webp"
  else
    m.closedCaptionAudioButton.uri = "pkg:/images/transport/sgplayer/icon-subtitles-enabled.webp"
  end if
End Function


Function onAvailableAudioTracksChange(msg)
  availableAudioTracks = msg.getData()
  setInitialAudioTrack(availableAudioTracks)
End Function


Function setInitialAudioTrack(availableAudioTracks)
  preferredAudioTrack = m.top.preferredAudioTrack

  ' Proceeding only if we have stored device/user level settings.
  if availableAudioTracks <> invalid AND availableAudioTracks.Count() > 1 AND isAA(preferredAudioTrack) = true AND isNonEmptyString(preferredAudioTrack.language) = true
    ' Holds the value of the audioTrack to be set to the video node.
    updatedAudioTrack = invalid
    for each track in availableAudioTracks

      if isNonEmptyString(track.name) then

        hasAccessibilityDescription = false
        if track.name.instr(m.constants.player.audioDescriptionTrackNamePrefix) > -1
          hasAccessibilityDescription = true
        end if

        if track.language = preferredAudioTrack.language
          ' If it is normal audio track and user did not prefer one with audio description.
          if hasAccessibilityDescription = false AND preferredAudioTrack.role = m.constants.player.audioTrackRoles.main
            updatedAudioTrack = track
          else if hasAccessibilityDescription = true AND preferredAudioTrack.role = m.constants.player.audioTrackRoles.description
            updatedAudioTrack = track
          end if
        end if

      end if
    end for

    ' Setting updated audio track to the video node.
    if updatedAudioTrack <> invalid
      ' Setting the default audio track.
      m.Video.audioTrack = updatedAudioTrack.track
      ' Setting the current audio track into the closed caption overlay.
      m.closedCaptionAndAudioSelectionOverlay.currentAudioTrack = updatedAudioTrack.track
    else if isNonEmptyString(m.video.currentAudioTrack) = true
      ' Providing a fallback if in future we have multiple langauge tracks and the user preferred track is not available for the program.
      m.closedCaptionAndAudioSelectionOverlay.currentAudioTrack = m.video.currentAudioTrack
    end if

  else if availableAudioTracks <> invalid AND availableAudioTracks.Count() > 1 AND isNonEmptyString(m.video.currentAudioTrack) = true
    ' This else block will handle case where we do not have a preferred audio track saved for user.
    m.closedCaptionAndAudioSelectionOverlay.currentAudioTrack = m.video.currentAudioTrack
  end if
  setCCAudioTransportBarVisibility()
End Function


Function onAudioTrackChange(msg)
  audioTrack = msg.getData()
  m.Video.audioTrack = audioTrack
End Function


Function onRelatedItemFocused()
  m.lastButtonPressPos = m.playerPosition
  ' Do not show the PauseAd if the user interacting the YMAL row.
  ' Resetting the timer when there is any user interaction during pause
  if m.pauseAdOverlayTimer.control = "start"
    restartPauseAdTimer()
  end if
End Function


Function onRelatedItemSelected(msg)
  selectedContent = msg.getData()

  m.top.trackingComponentInfo = {
    componentType: "related_component"
    componentValues: {
      content_tile: m.Tracking.getAnalyticsTile(selectedContent, m.Related.itemFocused + 1, 1)
    }
  }

  animateTransport("out")
  hideYMAL()
  setFocusToPlaybackControl()
  m.top.relatedContentToPlay = selectedContent
  resetTransportButtons()
End Function


Function onKeyPressWhenYMALHasFocus(msg)
  keyPress = msg.getData()

  if keyPress = "fastforward"
    if m.FastForwardButton.enabled = true then
      animateTransportAndYMAL("out")
      handleFastForward()
    end if
  else if keyPress = "rewind"
    if m.RewindButton.enabled = true then
      animateTransportAndYMAL("out")
      handleRewind()
    end if
  end if

End Function


Function onSeekToChange(msg)
  position = msg.getData()
  jumpToPosition(position)
End Function
