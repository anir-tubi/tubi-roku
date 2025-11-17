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
  m.auth = TubiAuth(m.constants)
  m.top.screenLevel = m.constants.ui.screenLevels.videoPlayerScreen
  m.top.trackingPageInfo = {
    pageType: "video_player_page"
    pageValues: {}
  }
  m.bAutostartRefreshExperimentEnabled = getExperimentResource("roku_video_autostart_ui_refresh", "roku_video_autostart_ui_refresh_v1", false).enabled = true

  m.alignAdRequestExperiment = getStatsigExperimentResource("roku_player_improvement", "roku_player_align_ad_request_cuepoint_v1", false).enabled
  m.isAlignAdRequestExposureFired = false 'using this variable to avoid experiment calls during every video position change

  m.tubiTrackingInfo = TubiTrackingInfo(m.constants)
  m.top.observeFieldScoped("focusedChild", "onScreenFocusChange")

  m.moviePostplayCountdown = getStatsigExperimentResource("roku_postplay_countdown_timer", "roku_postplay_countdown_timer_movie_v1", false).countdown
  m.seriesPostplayCountdown = getStatsigExperimentResource("roku_postplay_countdown_timer", "roku_postplay_countdown_timer_series_v1", false).countdown

  m.top.handlesTransportVoiceRequests = true
  m._ = rodash()
  m.NodeHelpers = TubiNodeHelpers()

  request = TubiRequest(m.constants.settings)
  m.Tracking = TubiTracking(m.constants, m.auth, m.top.userConsentsOptOutStatus, request)
  isGDPRinArg = isGDPR()
  m.adsLimited = TubiAdsLimited(m.constants, m.auth, m.top.tcfString, m.top.userConsentsOptOutStatus, isGDPRinArg)
  m.top.observeFieldScoped("tcfString", "onTCFStringChange")
  m.top.observeField("userConsentsOptOutStatus", "onUserConsentsOptOutStatusChange")
  m.Loading = m.top.findNode("Loading")
  m.MinimizedAssets = m.top.findNode("MinimizedAssets")
  m.LoadingProgressBar = m.top.findNode("LoadingProgressBar")
  m.LoadingMessage = m.top.findNode("LoadingMessage")

  m.LoadingSpinner = m.top.findNode("LoadingSpinner")

  m.UpNext = m.top.findNode("UpNext")
  m.UpNextParent = m.top.findNode("UpNextParent")
  m.UpNext.observeField("contentSelected", "onUpNextContentSelected")
  m.UpNext.observeField("opacity", "onUpNextOpacityChange")
  m.UpNext.observeField("autoplayMode", "onUpNextAutolayModeChange")
  m.Video = m.top.findNode("VideoNode") ' reference in case we change from extending Video to extending Group
  m.Video.observeField("streamInfo", "onStreamInfoChanged")
  m.Video.observeFieldScoped("position", "onVideoPositionChange")
  m.Video.observeFieldScoped("state", "onVideoStateChange")
  m.Video.observeFieldScoped("bufferingStatus", "onBufferingStatus")
  m.Video.observeField("streamingSegment", "onStreamingSegmentChange")
  m.video.observeFieldScoped("availableSubtitleTracks", "setCCAudioTransportBarVisibility")
  m.video.observeFieldScoped("availableAudioTracks", "onAvailableAudioTracksChange")
  m.video.observeFieldScoped("audioTrack", "onAudioTrackChanged")
  m.video.observeFieldScoped("subtitleTrack", "onSubtitleTrackChanged")
  'downloadedSegment is needed for player log - Quality Of Service event
  m.video.observeFieldScoped("downloadedSegment", "onDownloadedSegment")
  m.videoBorder = m.top.findNode("VideoBorder")

  m.showPlayerStats = false
  ' Player Stats Overlay initialization for nonproduction mode
  if m.constants.settings.mode <> "production"
    m.playerStatsOverlay = m.top.findNode("playerStatsOverlay")

    if m.global <> invalid
      m.global.observeFieldScoped("showPlayerStats", "onShowPlayerStatsChange")

      if m.global.showPlayerStats <> invalid AND m.global.showPlayerStats = true
        m.showPlayerStats = true
      else
        m.showPlayerStats = false
      end if

    end if
  end if

  ' asyncStopSemantics was broken prior to 14.0 so we are not running it on older firmware versions
  isFirmwareOk = createObject("roDeviceInfo").getOSVersion().major.toInt() >= 14
  if isFirmwareOk = true AND getExperimentResource("roku_async_stop", "roku_async_stop_v6", false).enabled = true then
    m.video.asyncStopSemantics = true
  end if

  m.playerControlExperimentType = getExperimentResource("roku_player_ui_refresh", "roku_player_control_ui_refresh_v3", false).type
  m.marginX = m.constants.ui.translations.player.marginX

  if m.playerControlExperimentType = "none"
    m.marginX = m.constants.ui.translations.marginX
  end if

  BrowseWhileWatchingRow = m.top.findNode("BrowseWhileWatchingRow")

  if getStatsigExperimentResource("roku_player_improvement", "roku_player_bww_ymal_v1", false).enabled = true then
    m.BrowseWhileWatching = BrowseWhileWatchingRow.createChild("Related")
    m.BrowseWhileWatching.observeFieldScoped("selectedRelatedContentItem", "onRelatedItemSelected")
  else
    m.BrowseWhileWatching = BrowseWhileWatchingRow.createChild("BrowseContentOnPlayer")
    m.BrowseWhileWatching.observeFieldScoped("selectedRelatedContentItem", "onBrowseContentSelected")
  end if

  m.BrowseWhileWatching.translation = [m.marginX, 550]
  m.BrowseWhileWatching.associatedPageName = "video_player_page"
  m.BrowseWhileWatching.observeFieldScoped("trackingComponentInfo", "onTrackingComponentInfo")
  m.BrowseWhileWatching.observeFieldScoped("focusedContent", "onRelatedItemFocused")
  m.BrowseWhileWatching.observeFieldScoped("keyPress", "onKeyPressWhenBrowseWhileWatchingHasFocus")
  m.BrowseWhileWatching.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")

  m.top.observeFieldScoped("updateRelatedContent", "onRelatedContentUpdated")
  m.top.observeFieldScoped("updateBrowseContent", "onBrowseContentUpdated")
  m.top.observeField("updateContent", "onContentChange")
  m.top.observeField("sprites", "onSpritesReceived")
  m.top.observeField("control", "onControlChange")
  m.top.observeField("transportVoiceRequest", "handleTransportVoiceEvent")
  m.top.observeField("adState", "onAdStateChange")
  m.top.observeField("adProgress", "onAdProgressChange")
  m.top.observeField("displayAdLoadingMessage", "onDisplayAdLoadingMessage")
  m.top.observeField("seekTo", "onSeekToChange")
  m.top.observeFieldScoped("showBrowseWhileWatchingInFullScreen", "onShowBrowseWhileWatchingInFullScreen")
  m.top.observeFieldScoped("adTrackingObject", "onAdTrackingObject")
  m.top.observeFieldScoped("adBufferingObject", "onAdBufferingObject")
  m.top.observeFieldScoped("filledAdData", "onHandleFilledAdData")
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

  'pauseAdAnimation helps for stopping the pause ad animation
  m.pauseAdAnimation = invalid

  m.top.observeFieldScoped("sendPendingPauseAdPixel", "onSendPendingPauseAdPixel")
  m.top.observeFieldScoped("pauseAdResponse", "onPauseAdResponse")
  m.top.observeFieldScoped("exitPlayer", "onExitPlayer")
  m.pauseAdOverlayTimer = m.top.findNode("PauseAdOverlayTimer")
  m.pauseAdOverlayTimer.observeFieldScoped("fire", "onPauseAdOverlayTimer")
  m.pauseAdOverlay = m.top.findNode("PauseAdOverlay")
  m.pauseAdOverlay.observeFieldScoped("close", "onClosePauseAdOverlay")

  m.logo = m.top.findNode("tubiLogo")
  m.logoKids = m.top.findNode("tubiKidsLogo")
  m.brandingLogo = m.top.findNode("brandingLogo")

  m.isBrandingLogoExperimentEnabled = getStatsigExperimentResource("roku_player_improvement", "roku_player_branding_v2", false).enabled

  '//Variable to keep track where the m.ratingOverlay UI element should animated when the down button is pressed.
  m.ratingOverlayAnimatedPositionY = 150

  m.ratingOverlay = m.top.findNode("ratingOverlay")
  m.ratingBarAndLabel = m.top.findNode("ratingBarAndLabel")
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
  m.RemainingMinimizedGroup = m.top.findNode("RemainingMinimizedGroup")
  m.RemainingMinimizedBground = m.top.findNode("RemainingMinimizedBground")
  m.RemainingMinimizedLabel = m.top.findNode("RemainingMinimizedLabel")

  m.ProgressBar = m.top.findNode("ProgressBar")
  m.TopOverlay = m.top.findNode("TopOverlay")
  m.ScrubTimer = m.top.findNode("ScrubTimer")
  m.HUD = m.top.findNode("HUD")
  m.AdHeadsUp = m.top.findNode("AdHeadsUp")
  m.adHeadsUpGroup = m.top.findNode("adHeadsUpGroup")
  m.adBreakStartsInOverlay = m.top.findNode("AdBreakStartsInOverlay")
  m.AdHeadsUpText = m.top.findNode("AdHeadsUpText")
  m.Thumbnail = m.top.findNode("Thumbnail")
  m.VideoOverlay = m.top.findNode("VideoOverlay")
  m.VideoBrowseWhileWatchingOverlay = m.top.findNode("VideoBrowseWhileWatchingOverlay")

  if m.playerControlExperimentType = "none"
    m.skipCuepointsButton = m.top.findNode("skipCuepointsSimpleButton")
    m.SkipTrailerButton = m.top.findNode("SkipTrailerButton")
  else
    m.skipCuepointsButton = m.top.findNode("skipCuepointsTextIconButton")
    m.skipCuepointsButton.alwaysShowLabel = true
    m.SkipTrailerButton = m.top.findNode("SkipTrailerTextIconButton")
    m.SkipTrailerButton.alwaysShowLabel = true
  end if
  m.skipCuepointsButton.visible = true
  m.skipCuepointsButton.observeFieldScoped("selected", "onSkipCuepointsButtonSelected")

  m.top.playbackSource = {
    "srcForAnalytic": m.constants.player.playbackSource.unknown
    "srcForAds": m.constants.player.playbackOrigin.unknown
  }

  m.playerLogLib = invalid

  if m.constants.settings.clientLogsEnabled = true
    m.playerLogLib = PlayerLogLib(m.constants, m.Tracking)
  end if

  'playerExitInfo has ad_counts, is_ad fields, which are used in player exit event
  'ad_counts helps to find the total ads played during the single player session
  'is_ad helps to find out whether the Ad is displayed when user exit the player
  'message_map helps to add additional logs which may be needed for debugging
  m.playerExitInfo = {
    ad_counts: 0
    is_ad: false
    message_map: {}
  }

  ' Map to store the history whether cuePoints button were shown or not.
  ' skip button for each cuepoint should only be shown once per video
  m.cuePointsHistory = {}

  m.RAFAdContainer = m.top.findNode("RAFAdContainer")

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

  ' Variable that keeps track if the ad-countdown has started. This is used to plug a hack that allowed users to
  ' skip an ad break by seeking after the app got the ad break info from the backend. If this variable is set to true
  ' after the seek is done, then the ad break will start immediately.
  m.didSeeAdCountdown = false

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
  m.browseWhileWatchingAutoHideTime = m.constants.player.browseWhileWatchingAutoHideTime
  m.ignoreOptionsKey = m.constants.deviceInfo.firmwareCaptionMenu
  m.bufferingInfo = invalid

  m.bufferingTimer = m.top.createChild("Timer")
  m.bufferingTimer.duration = 10
  m.bufferingTimer.repeat = false

  m.controlIcon = m.top.findNode("controlIcon")
  m.Transport = m.top.findNode("Transport")

  if m.playerControlExperimentType = "none"
    m.Transport.itemSpacings = "[9, 18]"
    m.TransportButtonsXTranslation = 0
  else
    m.Transport.itemSpacings = "[39, 3]"
    m.TransportButtonsXTranslation = 1730
  end if

  m.ProgressBar = createObject("roSGNode", "TubiProgressBar")
  m.timeGroup = createObject("roSGNode", "Group")

  m.ElapsedLabel = createObject("roSGNode", "Label")
  m.ElapsedLabel.id = "ElapsedLabel"
  m.ElapsedLabel.text = "00:00:00"
  m.ElapsedLabel.translation = [m.marginX, 0]
  m.timeGroup.appendChild(m.ElapsedLabel)

  m.quickSeekIcon = createObject("roSGNode", "Poster")
  m.quickSeekIcon.id = "quickSeekIcon"
  m.quickSeekIcon.width = 36
  m.quickSeekIcon.height = 36
  m.quickSeekIcon.translation = [m.marginX + 120, -2]
  m.quickSeekIcon.visible = false
  m.timeGroup.appendChild(m.quickSeekIcon)

  m.RemainingLabel = createObject("roSGNode", "Label")
  m.RemainingLabel.id = "RemainingLabel"
  m.RemainingLabel.text = "-00:00:00"
  m.RemainingLabel.translation = "[1695, 0]"
  m.timeGroup.appendChild(m.RemainingLabel)

  if m.playerControlExperimentType = "none"
    m.TransportButtons = createObject("roSGNode", "Group")
    m.TransportButtons.id = "TransportButtons"
  else
    m.TransportButtons = createObject("roSGNode", "LayoutGroup")
    m.TransportButtons.id = "TransportButtons"
    m.TransportButtons.layoutDirection = "horiz"
    m.TransportButtons.vertAlignment = "top"
    m.TransportButtons.horizAlignment = "right"
    m.TransportButtons.translation = [m.TransportButtonsXTranslation, 0]
    m.TransportButtons.itemSpacings = [12]
  end if

  'seekUI for variant1
  m.seekGroup = m.top.findNode("seekGroup")
  m.currentSeekLabel = m.top.findNode("currentSeekLabel")
  m.seekControlGroup = m.top.findNode("seekControlGroup")

  m.seekSpeed = m.top.findNode("seekSpeedLabel")
  m.seekIcon = m.top.findNode("seekIcon")
  m.quickSeekLabel = m.top.findNode("quickSeekLabel")

  m.typographyConstants = getTypographyConstants()
  createTransportButtons()

  if m.playerControlExperimentType = "variant1"
    m.focusedNode = m.progressBar
  else
    'm.focusedNode holds the node/component which helps setting/unsetting focus to component/m.top on video player screen
    m.focusedNode = m.PlayPauseButton
  end if

  m.buttonUris = m.constants.player.transportButtons
  m.focusedButtonIndex = 0

  m.lastPingTime = 0
  m.lastSavedPosition = 0
  m.adPrefetchTime = 15 ' adPrefetchTime is used to help to prefetch the ad before the actual cuepoint
  m.adHeadsUpTime = 10 ' adHeadsUpTime helps to decide how long we need to show the AdHeadsup
  m.midrolls = {} ' midrolls holds all cuepoints from API response
  m.mostRecentCompletedCuepoint = -1 'used to prevent multiple resume_after_break events from firing
  m.notificationInterval = 0.999 ' The interval that we are targeting for player position updates. We specify a value lower than a second in order to get a float value
  m.Video.notificationInterval = m.notificationInterval

  'This information is used in quality of service event
  m.adImpressionMap = { "0": 0, "1": 0, "2": 0, "3": 0, "4": 0 }

  'This variable holds the value of Ad information from rainmaker response
  m.filledAdData = {}
  'This variable is used to send an AdMissed event if the previous cue point was missed
  m.missedAdReported = true

  'The field typically indicates whether a user has already seen a signup save progress modal or not.
  m.wasSignUpToSaveProgressModalAlreadyShown = false

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

  m.analyticsInterval = m.constants.player.pingFrequency
  m.historyInterval1Min = m.constants.player.historyFrequency1Min 'historyInterval1Min is used for sending exposure event

  ' set to the end position of replay if caption mode is temporarily turned on during a replay
  m.replayCaptionEnd = 0

  m.thumbnailMinXOffset = m.marginX
  m.thumbnailMaxXOffset = 1920 - m.marginX - m.Thumbnail.width

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

  ' Creating internal state to track when the sendfeedback overlay is visible to users.
  m.isSendFeedbackOverlayShowing = false

  ' Now that we are using async stop we need to wait until we get stopped state on the Video node before starting the ad. This variable helps track if we have requested a stop and are waiting for it to complete.
  m.isShowAdBreakPendingStop = false

  if m.playerControlExperimentType = "none"
    m.skipCuepointsButtonUpTranslation = 648
    m.Transport.translation = [0, 762]
    m.thumbnailMaxYOffset = 750
    m.hudYTranslation = -696
  else
    m.skipCuepointsButtonUpTranslation = 744
    m.Transport.translation = [0, 783]
    m.thumbnailMaxYOffset = 825
    m.hudYTranslation = -759
  end if
  m.skipCuepointsButtonDownTranslation = 888

  setFocusToComponent(m.focusedNode)

  m.TitleGroup = m.TopOverlay.findNode("TitleGroup")

  m.title = CreateObject("roSGNode", "Label")
  m.title.update({
    id: "VideoOverlayTitle"
    width: 1311
    height: 57
    ellipsizeOnBoundary: true
    vertAlign: "top"
  })

  m.titleImage = CreateObject("roSGNode", "Poster")
  m.titleImage.update({
    id: "VideoOverlayTitleImage"
    loadWidth: 366
    loadHeight: 57
    loadDisplayMode: "limitSize"
  })
  m.titleImage.observeFieldScoped("loadStatus", "onDisplayTitleArt")

  m.episodeTitle = CreateObject("roSGNode", "Label")
  m.episodeTitle.update({
    id: "VideoOverlayEpisodeTitle"
    translation: [0, 66]
    width: 1311
    height: 57
    ellipsizeOnBoundary: true
    vertAlign: "top"
  })

  SkipTrailerButtonLabel = m.TopOverlay.findNode("SkipTrailerButtonLabel")

  setTypographyOfLabel(m.title, m.typographyConstants.ids.subheaderLarge)
  setTypographyOfLabel(m.episodeTitle, m.typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.AdHeadsUpText, m.typographyConstants.ids.subheaderMedium)
  setTypographyOfLabel(m.ratedLabel, m.typographyConstants.ids.bodySmallStrong)
  setTypographyOfLabel(m.ratingLabel, m.typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(SkipTrailerButtonLabel, m.typographyConstants.ids.bodyLargeStrong)

  if m.playerControlExperimentType = "none"
    setTypographyOfLabel(m.ElapsedLabel, m.typographyConstants.ids.bodyLargeStrong)
    setTypographyOfLabel(m.RemainingLabel, m.typographyConstants.ids.bodyLargeStrong)
  else
    setTypographyOfLabel(m.ElapsedLabel, m.typographyConstants.ids.bodySmallStrong)
    setTypographyOfLabel(m.RemainingLabel, m.typographyConstants.ids.bodySmallStrong)
  end if

  setTypographyOfLabel(m.currentSeekLabel, m.typographyConstants.ids.bodySmallStrong)
  setTypographyOfLabel(m.quickSeekLabel, m.typographyConstants.ids.bodySmallStrong)
  setTypographyOfLabel(m.LoadingMessage, m.typographyConstants.ids.subheaderMedium)
  setTypographyOfLabel(m.descriptorCode, m.typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.descriptorDesc, m.typographyConstants.ids.bodySmall)
  setTypographyOfLabel(m.seekSpeed, m.typographyConstants.ids.bodySmallStrong)
  setTypographyOfLabel(m.RemainingMinimizedLabel, m.typographyConstants.ids.bodySmallStrong)

  '//Once the Typography has been set for RemainingMinimizedLabel, then set the width and height of the RemainingMinimizedBground
  boundingRectRemainingMinimizedLabel = m.RemainingMinimizedLabel.boundingRect()
  m.RemainingMinimizedBground.width = boundingRectRemainingMinimizedLabel.width + m.RemainingMinimizedLabel.translation[0] * 2
  m.RemainingMinimizedBground.height = boundingRectRemainingMinimizedLabel.height + m.RemainingMinimizedLabel.translation[1] * 2

  '//Position elements based on the margin set in constants
  m.SkipTrailerButton.translation = [m.marginX, m.SkipTrailerButton.translation[1]]
  m.AdHeadsUpText.translation = [m.marginX, m.AdHeadsUpText.translation[1]]
  m.ratingBarAndLabel.translation = [m.marginX, m.ratingBarAndLabel.translation[1]]
  m.descriptorDesc.translation = [m.marginX + 27, m.descriptorDesc.translation[1]]
  m.ElapsedLabel.translation = [m.marginX, m.ElapsedLabel.translation[1]]
  m.RemainingLabel.translation = [1920 - m.marginX - m.RemainingLabel.boundingRect().width - 10, m.RemainingLabel.translation[1]]

  m.RemainingMinimizedGroup.translation = [1779, 346]
  m.ProgressBar.translation = [m.marginX, m.ProgressBar.translation[1]]
  m.ProgressBar.width = 1920 - (m.marginX * 2)

  m.closedCaptionAndAudioSelectionOverlay = m.top.findNode("closedCaptionAndAudioSelectionOverlay")
  m.closedCaptionAndAudioSelectionOverlay.observeFieldScoped("globalCaptionChanged", "onGlobalCaptionChanged")
  m.closedCaptionAndAudioSelectionOverlay.observeFieldScoped("wasBackButtonSelected", "onWasCCBackButtonSelectedChange")
  m.closedCaptionAndAudioSelectionOverlay.observeFieldScoped("trackingEventInfo", "onTrackingEventInfoChange")
  m.closedCaptionAndAudioSelectionOverlay.observeFieldScoped("subtitleTrack", "onSubtitleTrackChangedOnCCOverlay")
  m.closedCaptionAndAudioSelectionOverlay.observeFieldScoped("audioTrack", "onAudioTrackChangedOnCCOverlay")
  m.closedCaptionAndAudioSelectionOverlayGroup = m.top.findNode("closedCaptionAndAudioSelectionOverlayGroup")

  m.sendFeedbackSelectionOverlayGroup = m.top.findNode("sendFeedbackSelectionOverlayGroup")
  m.sendFeedbackSelectionOverlay = m.top.findNode("sendFeedbackSelectionOverlay")
  m.sendFeedbackSelectionOverlay.translation = [1230, 60]
  m.sendFeedbackSelectionOverlay.width = 630
  m.sendFeedbackSelectionOverlay.height = 960

  m.sendFeedbackSelectionOverlay.observeFieldScoped("backOrLeftKeyPress", "onWasBackORLeftButtonSelectedForSendFeedback")
  m.sendFeedbackSelectionOverlay.observeFieldScoped("itemSelected", "onSendFeedBackOverlayItemSelected")

  m.isAdsOverlayExperimentEnabled = getExperimentResource("roku_player_ui_refresh", "roku_ads_overlay_v1", false).overlay_type <> "none"
  if m.isAdsOverlayExperimentEnabled = true
    m.adCountdownOverlay = CreateObject("roSGNode", "AdCountdownOverlay")
    m.adCountdownOverlay.id = "adCountdownOverlay"
    m.adCountdownOverlay.translation = [81, 81]
  end if

  ' Will be used to track the current subtitle and audio language for analytics purposes.
  m.currentSubtitleLanguage = ""
  m.currentAudioLanguage = ""

  ' Since we will not be able to get audio track language until the video is playing,
  ' we will not fire the start video event until the video is playing.
  ' To avoid from code firing multiple start video events, we will set this variable to track when to fire vs not.
  m.shouldFireStartVideoEvent = false

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()

  'Setting ad task control to "RUN" as the last step in init() because making UI updates, as in onThemeChange(), while the task is starting up causes bright script to throw loop detected error for some reason.
  m.AdsTask = m.top.findNode("AdsTask")
  m.AdsTask.videoPlayerNode = m.top
  m.AdsTask.control = "RUN"
End Function


Function onSendFeedBackOverlayItemSelected(msg)
  itemSelected = msg.getData()
  feedbackOverlay = msg.getRoSGNode()

  if itemSelected <> invalid
    'Send accept dialog event when user selected item on  overlay.
    trackingPageInfo = m.top.trackingPageInfo
    if trackingPageInfo <> invalid
      trackEvent({
        type: "dialog"
        values: {
          dialog_type: "INFORMATION"
          pageOneof: m.Tracking.getAnalyticsPage(trackingPageInfo.pageType, trackingPageInfo.pageValues)
          dialog_action: "ACCEPT_DELIBERATE"
          dialog_sub_type: "player_problem"
        }
      })
    end if

    selectedFeedbackTitle = itemSelected.title
    if itemSelected.id <> "cancel"
      indexSelected = 1

      if feedbackOverlay <> invalid
        indexSelected = feedbackOverlay.indexSelected + 1
      end if

      ' send RequestForInfo analytics event
      selectorValues = {
        options: [selectedFeedbackTitle]
        selections: [indexSelected]
        string_selector_type: "GENERIC_SURVEY" 'StringSelectorComponent.type enum
        sub_type: "report_problem_player"
      }

      trackEvent({
        type: "request_for_info"
        values: {
          request_for_info_action: "SURVEY"
          selectorOneOf: m.Tracking.getAnalyticsSelector("string_selector", selectorValues)
        }
      })

      userFeedbackInfo = {
        "feedback_issue": itemSelected.id
        "is_live": false
      }
      updatePlayerLogLib(m.playerLogLib, "setUserFeedback", userFeedbackInfo)

      updatePlayerLogLib(m.playerLogLib, "setPlayerFeedback", itemSelected.id)
      sendPlayerFeedbackInfo(selectedFeedbackTitle)
      showQRCodeScreen()
    else
      hideSendFeedbackOverlay()
    end if
  end if
End Function


Function onStreamInfoChanged(msg)
  streamInfo = msg.GetData()
  updatePlayerLogLib(m.playerLogLib, "setStreamInfo", streamInfo)
  updatePlayerStatsOverlay()
End Function


'@feedbackIssue: string, The player issue that was chosen to send feedback on.
Function sendPlayerFeedbackInfo(feedbackIssue)
  playerContent = m.top.content
  if playerContent <> invalid
    sendFeedBackInfo = {
      device_id: m.constants.deviceInfo.deviceId
      platform: m.constants.platform
      feedback_issue: feedbackIssue
      is_live: false
      content_id: playerContent.id
      video_resource_type: playerContent.drmType
      video_resource_resolution: playerContent.resolution
      position: playerContent.position
      current_buffering_duration: 0
      userId: 0
    }

    authInfo = m.auth.getAuthInfo()
    if authInfo <> invalid AND authInfo.userId <> invalid
      sendFeedBackInfo.userId = authInfo.userId
    end if

    sendFeedBackInfo = formatJson(sendFeedBackInfo)

    logInfo(sendFeedBackInfo, "videoInfo", "send-feedback-from-player")
  end if
End Function


Function showQRCodeScreen()
  'Create a component for QR code
  sendFeedbackQRCodeOverlay = CreateObject("roSGNode", "SendFeedbackQRCodeOverlayOnPlayer")
  sendFeedbackQRCodeOverlay.update({
    title: getTranslation("thank_you_title")
    subTitle: getTranslation("send_feedback_submitted_description")
    sendFeedbackHintText: getTranslation("send_feedback_overlay_feedback_hint")
    uri: "pkg:/images/sendFeedback.webp"
  })

  sendFeedbackQRCodeOverlay.translation = [0, 0]
  sendFeedbackQRCodeOverlay.width = 630
  sendFeedbackQRCodeOverlay.height = 960
  m.sendFeedbackSelectionOverlay.appendChild(sendFeedbackQRCodeOverlay)

  sendFeedbackQRCodeOverlay.observeFieldScoped("closeQRCodeOverlay", "onCloseQRCodeOverlay")
  sendFeedbackQRCodeOverlay.observeFieldScoped("closeSendFeedbackOverlay", "onCloseSendFeedbackOverlay")
  sendFeedbackQRCodeOverlay.setFocus(true)
End Function


Function onCloseQRCodeOverlay(msg)
  sendFeedbackQRCodeOverlay = msg.getRoSGNode()

  if sendFeedbackQRCodeOverlay <> invalid
    sendFeedbackQRCodeOverlay.setFocus(false)
    m.sendFeedbackSelectionOverlay.removeChild(sendFeedbackQRCodeOverlay)
    m.sendFeedbackSelectionOverlay.setFocus(true)
  end if
End Function


Function onCloseSendFeedbackOverlay(msg)
  isCloseSendFeedbackOverlay = msg.getData()
  qrCodeOverlay = msg.getRoSGNode()

  if isCloseSendFeedbackOverlay = true AND qrCodeOverlay <> invalid
    hideSendFeedbackOverlay()
    m.sendFeedbackSelectionOverlay.removeChild(qrCodeOverlay)
  end if

End Function


Function removeOverLayItems()
  childCount = m.sendFeedbackSelectionOverlay.getChildCount() - 1
  m.sendFeedbackSelectionOverlay.removeChildrenIndex(childCount, 1)
End Function


Function onScreenFocusChange()

  if m.top.isInFocusChain() = true
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
Function setSkipCuepointsButtonTextAndTimer(skipCuepointsTitle as String) as Void
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

  if m.HUD.opacity = 1
    xPosition = m.top.width - (m.skipCuepointsButton.boundingRect().width + m.marginX)
    m.skipCuepointsButton.translation = [xPosition, m.skipCuepointsButtonUpTranslation]
    width = m.skipCuepointsButton.boundingRect().width + 12

    if m.playerControlExperimentType = "variant1"
      slideTransportButtons(true, width)
    end if
  else if m.HUD.opacity > 0
    setFocusToComponent(m.skipCuepointsButton, true)
    xPosition = m.top.width - (m.skipCuepointsButton.boundingRect().width + m.marginX)
    m.skipCuepointsButton.translation = [xPosition, m.skipCuepointsButtonUpTranslation]
    width = m.skipCuepointsButton.boundingRect().width + 12

    if m.playerControlExperimentType = "variant1"
      slideTransportButtons(true, width)
    end if
  else
    setFocusToComponent(m.skipCuepointsButton, true)
    xPosition = m.top.width - (m.skipCuepointsButton.boundingRect().width + m.marginX)
    m.skipCuepointsButton.translation = [xPosition, m.skipCuepointsButtonDownTranslation]

    if m.playerControlExperimentType = "variant1"
      slideTransportButtons(false)
    end if
  end if

  if m.focusedNode.isSameNode(m.BrowseWhileWatching) = false
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

  if m.playerControlExperimentType = "variant1"
    slideTransportButtons(false)
  end if
End Function


' slideTransportButtons
'
' Wrapper function for sliding TransportButtons with consistent animation
'
' @param offsetLeft: Boolean - If true, slides left by button width; if false, slides to original position
' @param width: Integer - Width of button for offset calculation (optional, default: 0)
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
Function slideTransportButtons(offsetLeft as Boolean, width = 0 as Integer)
  transportButtonsTranslation = m.TransportButtons.translation

  if offsetLeft = true
    targetX = m.TransportButtonsXTranslation - width
  else
    targetX = m.TransportButtonsXTranslation
  end if

  destination = [targetX, transportButtonsTranslation[1]]
  return slideTo(m.TransportButtons, destination, 0.6)
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
  if m.focusedNode.isSameNode(m.skipCuepointsButton) = true AND m.HUD.opacity > 0
    componentToFocus = m.progressBar
  else
    componentToFocus = m.top
  end if
  hideSkipCuepointsButton(componentToFocus)
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

    updateVideoState("play")

    if m.top.enableAds = true then
      'The fetchPreroll boolean determines whether to fetch the preroll. This value is updated based on the cue point, with a default setting of false.
      fetchPreroll = false

      '//Set the midrolls of the videoplayer now and set the adControl state to preroll
      cuepoints = m.Video.content.cuepoints

      if cuepoints <> invalid
        ' Iterating all cuepoints and storing it in assocarray, so that we don't want to iterate on every position change(notificationInterval) of video.
        for each cuepoint in cuepoints
          tubilog("VideoPlayer: MIDROLL: " + strI(cuepoint))

          if Int(cuepoint) = 0
            fetchPreroll = true
          end if

          m.midrolls[strI(cuepoint)] = true
        end for
      end if

      if fetchPreroll = true
        updatePlayerLogLib(m.playerLogLib, "setAdType", "preroll")

        'Fire roku_player_ad_preroll_timeout_v2 exposure event when fetching preroll ads
        getStatsigExperimentResource("roku_player_improvement", "roku_player_ad_preroll_timeout_v2")

        ' Start pre-roll fetch
        m.top.adControl = "preroll"
      else
        m.Video.control = "play"
        setInitialCCAndAudioTracks()
      end if

    else
      m.Video.control = "play"
      setInitialCCAndAudioTracks()
    end if
    m.shouldFireStartVideoEvent = true
  end if

End Function


Function setInitialCCAndAudioTracks()
  setInitialSubtitleTrack(m.Video.availableSubtitleTracks)
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
  updatePlayerLogLib(m.playerLogLib, "setCaptions", m.Video.availableSubtitleTracks)
  updatePlayerLogLib(m.playerLogLib, "updateCaptionIndex", m.Video.subtitleTrack)
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
    m.closedCaptionAndAudioSelectionOverlayGroup.color = theme.shadeColor
    m.sendFeedbackSelectionOverlayGroup.color = theme.shadeColor
    m.videoBorder.blendColor = theme.focusedColor
    m.RemainingLabel.color = theme.primaryTextColor
    m.RemainingMinimizedLabel.color = theme.primaryTextColor
    m.seekSpeed.color = theme.backgroundColor
    m.LoadingSpinner.blendColor = m.focusedColor
    m.seekIcon.blendColor = theme.backgroundColor

    if theme.id = m.constants.ui.themeIDs.kidsMode
      m.logo.visible = false
      m.logoKids.visible = true
    else
      m.logo.visible = true
      m.logoKids.visible = false
    end if
  end if
End Function


Function onContentChange() as Void
  tubiLog("VideoPlayer.onContentChange")
  stopVideo()
  m.isBWWShownForDeeplinkUser = false

  if m.top.isTrailer = false AND m.top.appMode <> "KIDS_MODE"
    if m.sendFeedBackButton.hasField("enabled") = true
      m.sendFeedBackButton.enabled = true
    end if
    m.sendFeedBackButton.visible = true
  else
    if m.sendFeedBackButton.hasField("enabled") = true
      m.sendFeedBackButton.enabled = false
    end if
    m.sendFeedBackButton.visible = false
  end if

  if m.top.content <> invalid
    'set page tracking values for analytics
    m.top.trackingPageInfo = {
      pageType: m.top.trackingPageInfo.pageType
      pageValues: {
        video_id: m.top.content.id.toInt()
      }
      additionalContextValues: {
        isCdc: m.top.content.isCdc
        isAdultParentalLevel: m.top.isAdultParentalLevel
      }
    }

    m.UpNext.videoId = m.top.content.id
  end if
End Function


Function onControlChange()
  control = m.top.control
  tubiLog("VideoPlayer.onControlChange " + control)
  updatePlayerLogLib(m.playerLogLib, "setVideoControl", control)

  if control = "play"
    if m.top.content <> invalid
      playerLoadTime = m.top.loadTime
      updatePlayerLogLib(m.playerLogLib, "setPlayerInitialization", playerLoadTime)
      prepareToStartVideo(m.top.content)
      updatePlayerLogLib(m.playerLogLib, "setPlayerSetupEndTime")
      updatePlayerLogLib(m.playerLogLib, "setLastStartStep", "START_LOAD")
      updatePlayerLogLib(m.playerLogLib, "setPlayerStage", "READY")
      updatePlayerLogLib(m.playerLogLib, "setPlaybackSource", m.top.playbackSource)
      playContent()
    end if

  else if control = "stop" then
    stopAdsPlayback()
    cancelReplayCaptions()
    clearSkipCuepointsButtonAndTimer()

    adState = m.top.adState

    if m.missedAdReported = false AND (adState = "adsClosed" OR adState = "adsPlaying" OR adState = "fetching" OR adState = "adsPending")
      if m.top.goToNext = true
        reason = "autoPlay"
      else
        if adState = "adsClosed" OR adState = "adsPlaying"
          reason = "exitDuringPlayback"
        else if adState = "fetching"
          reason = "exitBeforeResponse"
        else 'adsPending
          reason = "exitBeforePlayback"
        end if
      end if

      sendAdMissedEvent(reason)
      m.missedAdReported = true

      'Reset filledAdData to prevent it from being used for future events.
      m.filledAdData = {}
    end if

    fireBrowseWhileWatchingPlaybackSessionEndEvent()
    updatePlayerLogLib(m.playerLogLib, "fireQualityOfServiceEvent", m.adImpressionMap)
    m.adImpressionMap = { "0": 0, "1": 0, "2": 0, "3": 0, "4": 0 } 'reset adImpressionMap after sending QualityOfService event

    updatePlayerLogLib(m.playerLogLib, "fireRealtimeQoSEvent")

    updatePlayerLogLib(m.playerLogLib, "setVideoStateWhenExitingPlayer", m.video.state)
    updatePlayerLogLib(m.playerLogLib, "setPlayerStateWhenExitingPlayer", m.top.state)

    stopVideo()
    animateTransport("out")
    hideBrowseWhileWatching()
    setFocusToPlaybackControl()
    m.UpNext.stopAutoPlayTimer = true
    m.UpNext.hide = true
    resetVideoPlayerBackToOriginalPosition()

    'in the case where an ad break has started, but RAF does not yet have control, we want to break out of ads on back button pressed
    m.top.adControl = "stop"
  else if control = "pause" then
    pauseVideo(false, false)
  else if control = "resume" AND m.Video.state = "paused" then
    resumeFromPause(false)
  end if
End Function


'Occurs when the fallback timer fires.
'This is used to advance the codec on the content in the case where the codec is not supported.
Function onFallbackTimerFired()
  m.fallbackTimer.unObserveFieldScoped("fire")
  m.fallbackTimer = invalid

  if isNode(m.Video) AND m.Video.errorCode = -5 ' Media error; the media format is unknown or unsupported
    advanceCodecOnContent(m.Video.content)
  else
    advanceDrmOnContent(m.Video.content)
  end if
  playContent()
End Function


'Occurs when m.Video.state changes (not when m.top.state changes)
Function onVideoStateChange(msg)
  tubiLog("VideoPlayer.onVideoStateChange " + msg.GetData())
  state = msg.GetData()
  updatePlayerLogLib(m.playerLogLib, "setVideoState", state)

  if m.shouldFireStartVideoEvent = true AND (state = "playing" OR state = "error")
    ' Covers a case where we only have one audio track but that is non english.
    if isNonEmptyString(m.currentAudioLanguage) = false AND isNonEmptyArray(m.Video.availableAudioTracks) = true AND isNonEmptyString(m.Video.availableAudioTracks[0].language) = true
      m.currentAudioLanguage = m.tubiTrackingInfo.getLanguageCode(m.Video.availableAudioTracks[0].language)
    end if
    m.shouldFireStartVideoEvent = false
    fireStartVideoOrTrailerEvent()
  end if

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
      ' Adding a small timer so that we move the execution to the next frame rather than immediately executing the fallback logic
      ' This is that video player state gets out of the error state.
      m.fallbackTimer = createObject("roSGNode", "Timer")
      ' We just need a minute delay to ensure that the video player state gets out of the error state.
      m.fallbackTimer.duration = 0.01
      m.fallbackTimer.observeFieldScoped("fire", "onFallbackTimerFired")
      m.fallbackTimer.control = "start"
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
    errorInfo = getPlaybackErrorInfo(m.Video.position, m.Video.downloadedSegment, m.Video.streamingSegment, m.Video.streamingInfo, m.Video.errorCode, m.Video.errorStr, content)

    errorCode = m.video.errorCode
    errorInfo.type = m.constants.errors.type.videoError + " " + errorCode.toStr()
    errorInfo.name = m.constants.errors.message.videoPlayer

    videoErrorInfo = m.video.errorInfo
    if videoErrorInfo <> invalid
      errorInfo.debug_msg = videoErrorInfo.dbgmsg
    end if

    if content <> invalid
      if content.codec <> invalid
        errorInfo.codec = content.codec
      end if

      if content.resolution <> invalid
        errorInfo.resolution = content.resolution
      end if
    end if

    ' If the error is related to DRM adding additional info to the log.
    if errorCode = -6
      licenseStatus = m.Video.licenseStatus

      if videoErrorInfo <> invalid
        errorInfo.drm_error_code = videoErrorInfo.drmerrcode
      end if

      if licenseStatus <> invalid
        if licenseStatus.keysystem <> invalid
          errorInfo.drm_type = licenseStatus.keysystem
        end if

        if licenseStatus.response <> invalid
          errorInfo.license_response = licenseStatus.response
        end if

        if licenseStatus.duration <> invalid
          errorInfo.license_req_duration = licenseStatus.duration
        end if
      end if
    end if

    jsonErrorInfo = FormatJSON(errorInfo)
    ' sending the logs to uapi
    logError(jsonErrorInfo, "videoPlayback", "video-playback", 0.1)

    ' sending the logs to sentry sdk
    tubiException(errorInfo, "error", 0.1)

    m.top.sendYouboraError = true

    if content.isTrailer = true
      m.didAdvanceDrm = false
    else
      updatePlayerLogLib(m.playerLogLib, "setBreakOffError", m.Video.errorCode)
      ' Set up the next DRM scheme. Playback of next DRM scheme is triggered when state = "finished",
      ' right after error state occurs.
      if m.Video.errorCode = -5 ' Media error; the media format is unknown or unsupported
        m.didAdvanceDrm = checkIfCodecFallbackIsAvailable(content)
      else
        m.didAdvanceDrm = checkIfDRMFallbackIsAvailable(content)
      end if
    end if

    contentErrorInfo = {}
    contentErrorInfo["error_code"] = m.Video.errorCode
    contentErrorInfo["error_details"] = m.Video.errorMsg

    if m.didAdvanceDrm <> true
      isFatal = true
    else
      isFatal = false
    end if

    contentErrorInfo["fatal"] = isFatal
    updatePlayerLogLib(m.playerLogLib, "fireContentErrorEvent", contentErrorInfo)

    if m.didAdvanceDrm <> true
      updatePlayerLogLib(m.playerLogLib, "setErrorCode", m.Video.errorCode)
      updatePlayerLogLib(m.playerLogLib, "setErrorModal", true)
      m.top.errorMsg = getTranslation("videoPlayer_error_playback_description") 'is used in error modal
      m.top.state = state 'triggers error modal in ContentController
    end if
  else if state = "stopped" then

    if m.isShowAdBreakPendingStop = true then
      showAdBreakStoppedCallback()
    else if m.VideoState = "stop" then
      ' player has stopped (not due to an ad break)
      if m.top.adState = "noAds" OR m.top.adState = "init" OR m.top.adState = "adsCompleted"
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

          m.top.state = state
        end if
      end if
    end if
  end if

  ' Loading page visibility
  if state = "playing" OR state = "paused"
    m.Loading.visible = false
    m.top.state = state
  else
    if m.bAutostartRefreshExperimentEnabled = true AND m.UpNext.opacity > 0 AND m.Video.width <> 1920
      '//the video player is not in full screen mode and the up next component is visible, so do not display the loading screen
      m.RemainingMinimizedGroup.opacity = 0
      m.Video.opacity = 0
      if m.VideoBorder.visible = true
        m.VideoBorder.visible = false
        m.UpNext.setFocus(true)
      end if
    else
      m.LoadingProgressBar.progress = 0
      m.Loading.visible = true
    end if
  end if

  if state = "playing"
    if m.showRatings = true AND m.ratingOverlay.opacity = 0.0 AND m.AdHeadsUp.visible = false
      m.showRatings = false
      if isAA(m.top.playbackSource) = true AND m.top.playbackSource.srcForAds = m.constants.player.playbackOrigin.deeplink AND getExperimentResource("roku_bww_deeplinked_content", "roku_bww_deeplinked_content_v1", true).enabled = true AND m.isBWWShownForDeeplinkUser = false
        showRatingOverlay(deeplinkBWWCallBack)
      else
        showRatingOverlay()
      end if
    end if

  end if

  if state = "stopped" OR state = "finished" OR state = "error" OR state = "paused" then
    m.top.timestampOfLastVideoPlayback = createObject("roDateTime").asSeconds()
  else if state = "buffering" OR state = "playing" then
    m.top.timestampOfLastVideoPlayback = -1
  end if

  if state = "stopping" AND m.isShowAdBreakPendingStop = false then
    ' Update external state as stopping as long as we aren't currently playing an ad since we already handle that internally
    m.top.state = state
  end if
End Function


' updates the lastPingTime
' @position: int, this is video position
Function updateLastPingTime(position)
  m.lastPingTime = position
End Function


Function fireStartVideoOrTrailerEvent()

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
      resolution = "VIDEO_RESOLUTION_" + m.Video.content.resolution + "P"
    end if

    startPosition = Int(m.playerPosition * 1000)
    if startPosition < 0
      startPosition = 0 'reset the player position to 0 since we do not know why
    end if

    trackEvent({
      type: "start_video"
      values: {
        video_id: m.Video.content.id.toInt()
        start_position: startPosition
        current_cdn: "" 'not possible for Roku client
        has_subtitles: hasSubtitles 'the video player will show subtitles at start
        is_livetv: isLiveTv
        is_embedded: isEmbedded
        is_fullscreen: isFullScreen
        playback_source: playbackSource.srcForAnalytic
        video_player: "DEFAULT"
        video_resource_type: resourceType
        video_resource_url: m.Video.content.URL
        video_codec_type: codeType
        video_resolution: resolution
        audio_language: UCase(m.currentAudioLanguage)
        subtitle_language: UCase(m.currentSubtitleLanguage)
      }
    })
  end if

End Function


'''''''''''''''''''''''''
' onVideoPositionChange
'
' The notificationInterval and analyticsInterval are not necessarily equal or evenly divisible
' so we check the time passage before we send playProgress events
Function onVideoPositionChange(msg)

  floatPosition = msg.getData()
  m.top.position = floatPosition
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
  updatePlayerLogLib(m.playerLogLib, "setVideoPosition", position)

  ' protects against video positions being updated after we've told the player to pause
  if m.VideoState = "play"
    updatePlayerPosition() 'updates m.playerPosition with m.Video.position
    m.ratingInterval = m.ratingInterval + m.Video.notificationInterval
  end if

  ' show the TV Rating/Descriptors every hour
  if m.ratingInterval >= (60 * 60) AND m.ratingOverlay.opacity = 0.0 AND m.AdHeadsUp.visible = false
    showRatingOverlay()
  end if

  playProgressOk = true
  if m.seekReferenceQueue.Count() > 0 AND positionInSeekReferenceQueue(m.playerPosition, m.seekReferenceQueue) = true 'updates m.seekReferenceQueue as necessary
    playProgressOk = false
    m.isSeeking = false
  end if

  if m.focusedNode.isSameNode(m.BrowseWhileWatching) = true
    if m.playerPosition > m.lastButtonPressPos + m.browseWhileWatchingAutoHideTime AND m.isClosedCaptionAudioOverlayShowing = false AND m.isSendFeedbackOverlayShowing = false
      animateTransport("out")
      hideBrowseWhileWatching()
      setFocusToPlaybackControl()
    end if
  else
    if m.VideoState = "play" AND m.HUD.opacity = 1 AND m.playerPosition > m.lastButtonPressPos + m.transportAutoHideTime AND m.isClosedCaptionAudioOverlayShowing = false AND m.isSendFeedbackOverlayShowing = false
      animateTransport("out")
      hideBrowseWhileWatching()
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
  if (m.playerPosition > m.lastsavedPosition + m.historyInterval1Min OR m.playerPosition < m.lastsavedPosition - m.historyInterval1Min) AND adState <> "adsPending"

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

        ' When upNext UI appears, we will close the sendFeedback overlay to avoid the focus issues.
        hideSendFeedbackOverlay()

        ' Hiding the audio and closed captioning overlay.
        if m.isClosedCaptionAudioOverlayShowing = true
          hideClosedCaptionAudioTrackOverlay()
        end if

        animateTransport("out")
        hideBrowseWhileWatching()
        setFocusToPlaybackControl()
        clearSkipCuepointsButtonAndTimer()

        if m.bAutostartRefreshExperimentEnabled = true
          if m.top.content.parentType = "series"
            '//Make sure the upNext component is located in the original layer
            m.UpNextParent.insertChild(m.UpNext, 0)
          else
            '//Minimize the movie player if this is a movie
            m.top.insertChild(m.UpNext, 0)
            nVideoMinimizedTranslation = m.MinimizedAssets.translation
            resizeToLocation(m.Video, 640, 360, nVideoMinimizedTranslation, .5) ' Resize the video player to a smaller size for the UpNext screen
            m.RemainingMinimizedGroup.opacity = 0
            fade(m.RemainingMinimizedGroup, "in", 0.5, 0.5)
            updateMinimizedTimes()
            m.RemainingMinimizedGroup.visible = true
            m.VideoBorder.width = 640
            m.VideoBorder.height = 360
          end if
        end if

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
    m.AdHeadsUp.visible = false ' default to AdHeadsUp being off; this will catch ff, replay, rew during the countdown

    ' Initialize variables
    isCuepointPrefetchTimeReached = false
    potentialCuepoint = -1
    shouldFireExposure = false

    ' Skip exposure when cue point is exactly 15 seconds ahead of playback.
    ' Fetch midroll ads early only if ads are neither pending nor currently fetching.
    if (adState <> "adsPending" AND adState <> "fetching")
      currentPosition = m.playerPosition
      prefetchCuepoint = currentPosition + m.adPrefetchTime

      ' Check if we're at the exact prefetch time for a cuepoint
      if m.midrolls[strI(prefetchCuepoint)] = true
        isCuepointPrefetchTimeReached = true
        potentialCuepoint = prefetchCuepoint
      else
        ' Check if any cuepoint falls within the 5-15 second window
        for each cuepointStr in m.midrolls
          cuepoint = val(cuepointStr)
          timeToCuepoint = cuepoint - currentPosition

          if timeToCuepoint >= 5 AND timeToCuepoint < 15
            shouldFireExposure = true
            ' Only set ad request flags if experiment is enabled
            if m.alignAdRequestExperiment = true
              isCuepointPrefetchTimeReached = true
              potentialCuepoint = cuepoint
            end if
            exit for
          end if
        end for
      end if

      ' Fire exposure event if needed and not already fired
      if shouldFireExposure = true AND m.isAlignAdRequestExposureFired = false
        getStatsigExperimentResource("roku_player_improvement", "roku_player_align_ad_request_cuepoint_v1")
        m.isAlignAdRequestExposureFired = true
      end if
    end if

    ' Fetch midroll ads if conditions are met
    if isCuepointPrefetchTimeReached = true AND m.UpNext.opacity = 0 AND potentialCuepoint > 0
      m.top.adPosition = potentialCuepoint
      m.top.adControl = "midroll"
      updatePlayerLogLib(m.playerLogLib, "setAdType", "midroll")
    end if

    ' show the ads countdown if appropriate (show if ads are available and within adHeadsUpTime)
    adPosition = m.top.adPosition
    if adState = "adsPending" AND isInWindow(m.playerPosition, adPosition, m.adHeadsUpTime) = true
      if m.TopOverlay.opacity = 0
        ' Don't show the ad heads up when the transport/overlay is showing, since it crowds the space of the title on the overlay
        m.ratingOverlay.opacity = 0

        '//Ensure that we know a pending ad has been set to start
        m.didSeeAdCountdown = true
        showAdHeadUpText(adPosition)
      end if
    end if

    ' check midroll and fire if any
    isCuepointReached = m.midrolls[strI(m.playerPosition)]

    'A pending ad from the previous cue point was not played for some reason. we need to fire the AdMissed event for the previous one.
    if adState = "adsPending" AND m.missedAdReported = false AND Int(m.playerPosition) > Int(m.top.adPosition)

      sendAdMissedEvent("exitAfterCuePointPassed")
      m.missedAdReported = true

      'Reset filledAdData to prevent it from being used for future events.
      m.filledAdData = {}
    end if

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
      else if adState = "noAds" OR adState = "adsCompleted"
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
              position: Int(m.playerPosition * 1000) 'without Int(), can return scientific notation, causing API error
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

  if m.isAdsOverlayExperimentEnabled = true
    m.adBreakStartsInOverlay.visible = true
    m.adBreakStartsInOverlay.timeRemaining = seconds
  else
    m.adBreakStartsInOverlay.visible = false
    m.AdHeadsUpText.text = getTranslation("videoPlayer_adHeadsUp", { seconds: seconds })
    m.adBreakStartsInOverlay.reCalculateWidth = true
  end if
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
'   "adsCompleted": an ad break has played to completion.
Function onAdStateChange(msg)
  adState = msg.getData()
  updatePlayerLogLib(m.playerLogLib, "setAdState", adState)

  'if ads are pending, reset the flag to indicate that the missed ad has not yet been reported
  if adState = "adsPending"
    m.missedAdReported = false
  end if

  tubiLog("VideoPlayer.onAdStateChange adState = " + adState + " VideoState = " + m.VideoState + " Video.State = " + m.Video.state)
  if adState = "ready"
    m.top.adState = "init"
    if m.top.adControl <> ""
      ' There is a race condition that can occur during deeplinks such that m.top.adControl can be set before the adShim is listening
      ' which results in a ad/video loading screen that never loads. Reset the ad control once the ad state is in init if this is the case
      ' to fix the issue.
      m.top.adControl = m.top.adControl
    end if
  else if adState = "adsPending" AND (m.top.adControl = "preroll" OR m.top.adControl = "seek") AND m.top.enableAds = true then
    ' Midrolls are triggered from position changes since they are prefetched.  Other ad breaks have
    ' video playback stopped and should play right away when we get adsPending.
    ' pre-roll or resume-roll. Play ads right away
    showAdBreak()
    m.showRatings = true
  else if (adState = "noAds" OR adState = "adsCompleted") AND (m.VideoState = "play" OR m.VideoState = "pause" OR m.VideoState = "ffw" OR m.VideoState = "rew" OR m.VideoState = "skip" OR m.VideoState = "hop") AND m.Video.state <> "playing" then
    'The below check is to remove the resumeFrom ad param once we've already sent the resumeFrom param in the previous ad request to avoid sending it again for future midrolls if it is not expected.
    content = m.top.content
    if content.adParam <> invalid AND content.adParam.resumeFrom <> invalid
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

      unObserveClosedCaptionAndAudioTrack()
      observeClosedCaptionAndAudioTrack()
      m.Video.control = "play"
      setInitialCCAndAudioTracks()

      ' sometimes position callback not getting triggered for longtime after playing Ads.
      ' so unobserving and observing it, it may trigger the position callback properly.
      m.Video.unobserveFieldScoped("position")
      m.Video.observeFieldScoped("position", "onVideoPositionChange")

      ' Adding the initial subtitle track here to cover use case where pre-roll ads are requested.
      ' Refer playContent for the reasoning behind why we are calling setInitialSubtitleTrack.
      setInitialSubtitleTrack(m.Video.availableSubtitleTracks)

      ' Adding the initial audio track here to cover use case where pre-roll ads are requested.
      ' Refer playContent for the reasoning behind why we are calling setInitialAudioTrack.
      setInitialAudioTrack(m.Video.availableAudioTracks)
      m.mostRecentCompletedCuepoint = m.playerPosition
      trackEvent({
        type: "resume_after_break"
        values: {
          video_id: m.Video.content.id.toInt()
          position: Int(m.playerPosition * 1000) 'without Int(), can return scientific notation, causing API error
        }
      })
    else
      updatePlayerLogLib(m.playerLogLib, "setErrorModal", true)
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
      logError(jsonErrorInfo, "videoPlayback", "invalid-video-url", 0.1)

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
  thumbnailsInfo = msg.getData() 'expect a TubiContentNode with thumbnail fields populated

  m.Thumbnail.visible = false ' always start with thumbnail invisible, then show it when scrubbing

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
      m.thumbnailMaxXOffset = 1920 - m.marginX - m.Thumbnail.width
      m.Thumbnail.translation = [m.thumbnailMinXOffset, m.thumbnailMaxYOffset - m.Thumbnail.height]

      quickSeekLabelWidth = m.quickSeekLabel.boundingRect().width
      m.quickSeekLabel.translation = [m.thumbnailMinXOffset + thumbnailsInfo.thumbnailSize[0] / 2 - quickSeekLabelWidth / 2, m.thumbnailMaxYOffset - m.Thumbnail.height - 110]
      m.seekGroup.translation = [m.thumbnailMinXOffset + thumbnailsInfo.thumbnailSize[0] / 2, m.thumbnailMaxYOffset - m.Thumbnail.height - 100]
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
    resetVideoPlayerBackToOriginalPosition()
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
    logWarn(FormatJSON(errorInfo), "videoBuffer", "video-buffer-startup", 0.1)
  else
    logWarn(FormatJSON(errorInfo), "videoBuffer", "video-re-buffer", 0.1)
  end if

End Function



' Helper function to prevent tracking events being sent for trailers
Function trackEvent(event as Object)
  allowedTrailerEvents = {
    "start_trailer": true
    "trailer_play_progress": true
    "finish_trailer": true
  }

  if m.top.isTrailer = false OR allowedTrailerEvents[event.type] = true
    appendContentUserContextValues(event.values, m.top.content, m.top.isAdultParentalLevel)
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
  content = m.top.content

  'Guest user who is watching series and it's player position greater than or equal to 5 minutes then display prompt only once per session
  if content <> invalid AND content.parentType = m.constants.ui.contentTypes.series AND m.top.appMode <> "KIDS_MODE" AND isLoggedInUser() = false AND m.playerPosition >= 300 AND m.wasSignUpToSaveProgressModalAlreadyShown = false
    m.wasSignUpToSaveProgressModalAlreadyShown = true
    pauseVideo(false, false)
    m.top.showSignUpModal = true
  else
    m.top.backButtonPressed = true
  end if
End Function


' Make sure the Video node is stopped and we have an accurate playback position before launching ads
Function showAdBreak()
  m.didSeeAdCountdown = false 'reset the variable

  'un-observing globalCaptionMode, subtitle and audioTrack to avoid callbacks of those video node fields when Ad starts/ends
  unObserveClosedCaptionAndAudioTrack()

  ' leave m.VideoState = "play" because from the component's perspective video is still playing

  ' If Video node is already in stopped state then calling control = "stop" on it will not trigger onVideoStateChange (async will but will leave it stuck in state=stopping).
  ' Because of this we don't want to call stop on the Video node and instead trigger the callback ourselves in this case
  if m.Video.state = "stopped" then
    showAdBreakStoppedCallback()
  else
    ' In order to try and change the behavior as little as possible we only want the async stop to rely on the onVideoStateChange callback and just trigger the callback right away here if in the control
    immediatelyTriggerCallback = true

    ' asyncStopSemantics was broken prior to 14.0 so we are not running it on older firmware versions
    isFirmwareOk = createObject("roDeviceInfo").getOSVersion().major.toInt() >= 14
    if isFirmwareOk = true AND getExperimentResource("roku_async_stop", "roku_async_stop_v6", true).enabled = true then
      ' the ad break will be shown by showAdBreakStoppedCallback() which will be triggered by
      ' onVideoStateChange() when the video node's state is updated to "stopped".
      ' m.isShowAdBreakPendingStop keeps state to let us know if an break is waiting for the
      ' stop process to complete before starting.
      m.isShowAdBreakPendingStop = true
      immediatelyTriggerCallback = false
    end if

    m.Video.control = "stop"
    if immediatelyTriggerCallback = true then
      showAdBreakStoppedCallback()
    end if
  end if
End Function


' Now that we are using async stop we need to wait until we get stopped state on the Video node before starting the ad
Function showAdBreakStoppedCallback()
  m.isShowAdBreakPendingStop = false
  hideClosedCaptionAudioTrackOverlay() ' if dialog is showing, it's awkward to have it still show after ad break
  hideSendFeedbackOverlay() ' if sendFeedback overlay is showing, it's awkward to have it still show after ad break
  m.top.adPosition = m.playerPosition
  m.top.adControl = "play"

  ' Update to notify we're still playing just an ad instead
  m.top.timestampOfLastVideoPlayback = -1
End Function


Function observeClosedCaptionAndAudioTrack()
  m.Video.observeFieldScoped("globalCaptionMode", "onCaptionModeChange")
  m.Video.observeFieldScoped("subtitleTrack", "onSubtitleTrackChanged")
  m.Video.observeFieldScoped("audioTrack", "onAudioTrackChanged")
End Function


Function unObserveClosedCaptionAndAudioTrack()
  m.Video.unObserveFieldScoped("globalCaptionMode")
  m.Video.unObserveFieldScoped("subtitleTrack")
  m.Video.unObserveFieldScoped("audioTrack")
End Function


' Helper function that aggregates any tasks that need to be done before playing a new video
' @contentNode: roSGNode, a TubiContentNode
' @videoResourceIndex: intarray, [0] -> codexIndex & [1] -> drmIndex
Function prepareToStartVideo(content, videoResourceIndex = [0, 0])

  'To prevent duplicate callbacks for the globalCaptionMode, subtitle, and audio track fields when a new video starts or when there are changes to the subtitle or audio track, unobserve these fields.
  unObserveClosedCaptionAndAudioTrack()
  'Calling observeClosedCaptionAndAudioTrack() before resetVideoPlayerState() ensures that the "subtitle/audioTrack" callbacks are properly executed when the content node is assigned to the video node in resetVideoPlayerState()
  'This process is also needed for setting preferred subtitle and audio track and updating the closed caption overlay accordingly.
  observeClosedCaptionAndAudioTrack()

  resetVideoPlayerState(content)
  resetPauseAd()
  resetPauseAdTimers()

  videoResources = content.videoResources
  codecIndex = videoResourceIndex[0]
  drmIndex = videoResourceIndex[1]

  resource = invalid
  if videoResources <> invalid AND videoResources[codecIndex] <> invalid
    resource = videoResources[codecIndex][drmIndex]
  end if

  setDrmOnContent(content, resource, videoResourceIndex)

  ' Update player stats overlay when new content is loaded
  updatePlayerStatsOverlay()

  m.top.content = content 'sends content to video node and makes current content available to contentController
  if m.constants.settings.youboraEnabledVod = true
    m.top.sendVideoTrackingStart = true
  else
    m.top.sendVideoTrackingStart = false
  end if
End Function


Function onCaptionModeChange(msg)
  globalCaptionMode = msg.getData()
  m.closedCaptionAndAudioSelectionOverlay.globalCaptionMode = globalCaptionMode
  setAudioSubtitleTransportBarIcon(globalCaptionMode)
End Function


' Reset video player state to a state relevant to starting a video
' @content: TubiContentNode
Function resetVideoPlayerState(content = invalid)
  ' setting startUpBuffering to true as this function will be triggered when user tries to play or resume video
  m.startUpBuffering = true
  m.playerPosition = 0
  m.top.position = 0
  m.LoadingProgressBar.progress = 0
  m.LoadingMessage.text = ""
  cancelReplayCaptions()
  m.AdHeadsUp.visible = false
  m.didSeeAdCountdown = false
  m.top.adPosition = 0
  m.top.goToNext = false
  m.controlIcon.opacity = 0
  hideSeekGroup()
  hideQuickSeekLabelAndIcon()
  m.pauseAdOverlay.opacity = 0
  m.ratingOverlay.opacity = 0
  m.showRatings = true
  m.ratingInterval = 0
  m.focusedButtonIndex = 0
  m.brandingLogo.opacity = 0

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

  resetVideoPlayerBackToOriginalPosition()
  setFocusToPlaybackControl()

  if m.RewindButton <> invalid
    m.RewindButton.uri = m.buttonUris.rewind
  end if

  if m.FastForwardButton <> invalid
    m.FastForwardButton.uri = m.buttonUris.fastforward
  end if

  clearSkipCuepointsButtonAndTimer()
  m.cuePointsHistory = {}
  ' Set the icon for audio/subtitle track based on the closed caption display status.
  setAudioSubtitleTransportBarIcon(m.Video.globalCaptionMode)
  ' Hiding the closed caption and audio overlay on every playback start if in case it is open.
  m.isClosedCaptionAudioOverlayShowing = false
  ' resetting the sendFeedbackOverlayShowing value incase if it is still true.
  m.closedCaptionAndAudioSelectionOverlayGroup.opacity = 0
  m.sendFeedbackSelectionOverlayGroup.opacity = 0
  m.isSendFeedbackOverlayShowing = false
End Function


Function resetVideoPlayerBackToOriginalPosition()
  resizeToLocation(m.Video, 1920, 1080, [0, 0], 0) ' reset the video player to full screen
  m.Video.opacity = 1
  m.RemainingMinimizedGroup.visible = false
  m.VideoBorder.visible = false
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

  'unObserveClosedCaptionAndAudioTrack is required to prevent callbacks for the globalCaptionMode, subtitle, and audio track fields when user exits player or changes the video content
  unObserveClosedCaptionAndAudioTrack()

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
  ' We were just using videoState before but there are times videoState might be something besides stop but the Video node is actually still stopped.
  ' Before this didn't matter but now if asyncStopSemantics=true and we call control=stop when player is already in stopped state
  ' then state will switch to stopping and never switches to stopped.
  ' After much effort I am still unable to reproduce this behavior in a simple test app but it happens in our app for some reason
  if videoState <> "stop" AND m.Video.state <> "stopped" then
    ' asyncStopSemantics was broken prior to 14.0 so we are not running it on older firmware versions and don't want to expose for the experiment on older firmware versions
    if createObject("roDeviceInfo").getOSVersion().major.toInt() >= 14
      getExperimentResource("roku_async_stop", "roku_async_stop_v6", true)
    end if

    m.Video.control = "stop"
  end if
End Function


' wrapper around setting a value on m.Video.seek to protect against trying to seek to negative
' values. Seeking to negative values will lead m.Video.seek field to equal 1.844674407371e+16 which
' may or may not cause weird behavior
' @position: integer/float, the playback position to seek to
Function seekToPosition(position)
  if position < 0
    position = 0
  end if

  m.isSeeking = true
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

  m.episodeTitle.text = ""

  if content.parentType = "series"
    m.title.text = content.parentTitle
    m.episodeTitle.text = content.title
    'TODO: check once the API data is ready and remove the hardcoded values
  else if content.parentType = m.constants.uapiContentTypes.sportsEvent
    m.title.text = content.title
    episodeTitleText = ""
    if content.length <> invalid AND content.length <> 0
      ' add 'dot' spacer only if we had a release date
      if episodeTitleText.len() > 0
        episodeTitleText = episodeTitleText + Chr(&hb7) + " "
      end if
      episodeTitleText = episodeTitleText + formatLengthSelectedLocale(content.length) + " "
    end if
    m.episodeTitle.text = "" '.matchTime + " . " + episodeTitleText
  else
    m.title.text = content.title
    m.episodeTitle.text = ""
  end if

  m.ratingOverlayAnimatedPositionY = 80
  if m.episodeTitle.text <> ""
    '//if the episode title has text, then move the rating y position down to fit the episode title.
    m.ratingOverlayAnimatedPositionY = 150
  end if

  childrenCount = m.titleGroup.getChildCount()
  m.titleGroup.removeChildrenIndex(childrenCount, 0)
  m.titleGroup.appendChild(m.title)
  m.titleGroup.appendChild(m.episodeTitle)

  updateTransportButtons(content)

  if m.playerControlExperimentType = "none"
    m.transport.appendChildren([m.timeGroup, m.ProgressBar, m.TransportButtons])
  else
    m.transport.appendChildren([m.TransportButtons, m.ProgressBar, m.timeGroup])
  end if
End Function


Function onDisplayTitleArt(msg)
  loadStatus = msg.getData()

  if loadStatus = "failed"
    content = m.top.content

    if content.parentType = "series"
      m.TitleGroup.translation = [m.constants.ui.translations.player.marginX, 540]
    else
      m.TitleGroup.translation = [m.constants.ui.translations.player.marginX, 580]
    end if

    m.titleGroup.removeChild(m.titleImage)
    m.titleGroup.insertChild(m.title, 0)
  else if loadStatus = "ready"
    m.titleGroup.removeChild(m.title) 'needed this line, because this function gets triggered twice as we are setting empty uri before setting actual uri for poster
    m.TitleGroup.translation = [m.constants.ui.translations.player.marginX, 580]
  end if
End Function


Function updateTransportButtons(content)
  m.SkipTrailerButton.enabled = false

  if m.playerControlExperimentType = "variant1"
    m.ProgressBar.highlightPointer = true

    childrenCount = m.TransportButtons.getChildCount()
    m.TransportButtons.removeChildrenIndex(childrenCount, 0)
    m.HUD.removeChild(m.SkipTrailerButton)

    if content.isTrailer = true
      m.Transport.translation = [0, 783]
      m.thumbnailMaxYOffset = 870
      m.SkipTrailerButton.enabled = true

      if content.type = "series"
        m.SkipTrailerButton.text = getTranslation("videoPlayer_button_watchSeries")
      else
        m.SkipTrailerButton.text = getTranslation("videoPlayer_button_watchMovie")
      end if

      'Thumbnail should be placed as the last child of the HUD component so that transport buttons or components do not overlay it.
      m.HUD.insertChild(m.SkipTrailerButton, m.HUD.getChildCount() - 1)

      m.StartButton.uri = "pkg:/images/icon-resume.webp"
      m.TransportButtons.appendChild(m.StartButton)
    else
      m.Transport.translation = [0, 744]
      m.thumbnailMaxYOffset = 825
      m.StartButton.uri = "pkg:/images/icon-resume.webp"
      m.TransportButtons.appendChild(m.StartButton)

      if content.parentType = "series"
        m.TransportButtons.appendChild(m.EndButton)
      end if

      if m.closedCaptionAudioButton.visible = true
        m.TransportButtons.appendChild(m.closedCaptionAudioButton)
      end if

      if m.sendFeedBackButton.visible = true
        m.TransportButtons.appendChild(m.sendFeedBackButton)
      end if
    end if

  else if m.playerControlExperimentType = "none"
    m.ProgressBar.highlightPointer = false
    m.Transport.translation = [0, 762]

    childrenCount = m.TransportButtons.getChildCount()
    m.TransportButtons.removeChildrenIndex(childrenCount, 0)

    if content.isTrailer = true
      m.SkipTrailerButton.enabled = true

      if content.type = "series"
        m.SkipTrailerButtonLabel.text = getTranslation("videoPlayer_button_watchSeries")
      else
        m.SkipTrailerButtonLabel.text = getTranslation("videoPlayer_button_watchMovie")
      end if

      m.TransportButtons.appendChild(m.SkipTrailerButton)
    end if

    m.TransportButtons.appendChild(m.StartButton)
    m.TransportButtons.appendChild(m.RewindButton)
    m.TransportButtons.appendChild(m.HopBackButton)
    m.TransportButtons.appendChild(m.PlayPauseButton)
    m.TransportButtons.appendChild(m.HopForwardButton)
    m.TransportButtons.appendChild(m.FastForwardButton)
    m.TransportButtons.appendChild(m.EndButton)

    if content.isTrailer = false
      m.TransportButtons.appendChild(m.closedCaptionAudioButton)
      m.TransportButtons.appendChild(m.sendFeedBackButton)
    end if

  end if

  if m.playerControlExperimentType = "variant1"
    m.TitleGroup.translation = [m.constants.ui.translations.player.marginX, 0]
  else
    m.TitleGroup.translation = [m.constants.ui.translations.marginX, 0]
  end if
End Function


Function createTransportButtons()
  if m.playerControlExperimentType = "variant1"

    m.StartButton = CreateObject("roSGNode", "TextIconButton")
    m.StartButton.update({
      hasUnfocusedBackground: true
      id: "StartButton"
      uri: "pkg:/images/icon-resume.webp"
      text: getTranslation("screenDetails_button_startOver")
      iconWidth: 36
      iconHeight: 36
      alwaysShowLabel: false
    })

    m.EndButton = CreateObject("roSGNode", "TextIconButton")
    m.EndButton.update({
      hasUnfocusedBackground: true
      id: "EndButton"
      uri: "pkg:/images/transport/sgplayer/icon-to-end.webp"
      text: getTranslation("videoPlayer_button_nextEpisode")
      iconWidth: 36
      iconHeight: 36
      alwaysShowLabel: false
    })

    m.closedCaptionAudioButton = CreateObject("roSGNode", "TextIconButton")
    m.closedCaptionAudioButton.update({
      hasUnfocusedBackground: true
      id: "closedCaptionAudioButton"
      uri: "pkg:/images/transport/sgplayer/icon-subtitles.webp"
      text: getTranslation("videoPlayer_button_audio_subtitles")
      iconWidth: 36
      iconHeight: 36
      alwaysShowLabel: false
    })

    m.sendFeedBackButton = CreateObject("roSGNode", "TextIconButton")
    m.sendFeedBackButton.update({
      hasUnfocusedBackground: true
      id: "sendFeedBackButton"
      uri: "pkg:/images/transport/sgplayer/icon-help.webp"
      text: getTranslation("send_feedback_overlay_title")
      iconWidth: 36
      iconHeight: 36
      alwaysShowLabel: false
    })

  else

    m.SkipTrailerButtonLabel = CreateObject("roSGNode", "Label")
    m.SkipTrailerButtonLabel.update({
      id: "SkipTrailerButtonLabel"
      width: 260
      height: 80
      horizAlign: "center"
      vertAlign: "center"
    })

    setTypographyOfLabel(m.SkipTrailerButtonLabel, m.typographyConstants.ids.bodyLargeStrong)
    m.SkipTrailerButton.appendChild(m.SkipTrailerButtonLabel)

    m.StartButton = CreateObject("roSGNode", "TransportButton")
    m.StartButton.update({
      id: "StartButton"
      width: 60
      height: 60
      translation: [540, 0]
      uri: "pkg:/images/transport/sgplayer/icon-to-start.webp"
    })

    m.EndButton = CreateObject("roSGNode", "TransportButton")
    m.EndButton.update({
      id: "EndButton"
      width: 60
      height: 60
      translation: [1320, 0]
      uri: "pkg:/images/transport/sgplayer/icon-to-end.webp"
    })

    m.closedCaptionAudioButton = CreateObject("roSGNode", "TransportButton")
    m.closedCaptionAudioButton.update({
      id: "closedCaptionAudioButton"
      width: 60
      height: 60
      translation: [1070, 0]
      uri: "pkg:/images/transport/sgplayer/icon-subtitles.webp"
    })

    m.sendFeedBackButton = CreateObject("roSGNode", "TransportButton")
    m.sendFeedBackButton.update({
      id: "sendFeedBackButton"
      enabled: false
      width: 60
      height: 60
      translation: [1140, 0]
      uri: "pkg:/images/transport/sgplayer/icon-help.webp"
    })
  end if

  m.RewindButton = CreateObject("roSGNode", "TransportButton")
  m.RewindButton.update({
    id: "RewindButton"
    width: 60
    height: 60
    uri: "pkg:/images/transport/sgplayer/icon-rew.webp"
  })

  if m.playerControlExperimentType = "none"
    m.RewindButton.translation = [672, 0]
  end if

  m.HopBackButton = CreateObject("roSGNode", "TransportButton")
  m.HopBackButton.update({
    id: "HopBackButton"
    width: 60
    height: 60
    uri: "pkg:/images/transport/sgplayer/icon-rew-30s.webp"
  })

  if m.playerControlExperimentType = "none"
    m.HopBackButton.translation = [800, 0]
  end if

  m.PlayPauseButton = CreateObject("roSGNode", "TransportButton")
  m.PlayPauseButton.update({
    id: "PlayPauseButton"
    width: 60
    height: 60
    uri: "pkg:/images/transport/sgplayer/icon-play.webp"
  })

  if m.playerControlExperimentType = "none"
    m.PlayPauseButton.translation = [930, 0]
  end if

  m.HopForwardButton = CreateObject("roSGNode", "TransportButton")
  m.HopForwardButton.update({
    id: "HopForwardButton"
    width: 60
    height: 60
    uri: "pkg:/images/transport/sgplayer/icon-fwd-30s.webp"
  })

  if m.playerControlExperimentType = "none"
    m.HopForwardButton.translation = [1060, 0]
  end if

  m.FastForwardButton = CreateObject("roSGNode", "TransportButton")
  m.FastForwardButton.update({
    id: "FastForwardButton"
    width: 60
    height: 60
    uri: "pkg:/images/transport/sgplayer/icon-ffw.webp"
  })

  if m.playerControlExperimentType = "none"
    m.FastForwardButton.translation = [1190, 0]
  end if

  m.SkipTrailerButton.translation = [m.marginX, m.SkipTrailerButton.translation[1]]

  if m.playerControlExperimentType = "variant1"
    m.focusedNode = m.progressBar
  else if m.playerControlExperimentType = "none"
    m.focusedNode = m.PlayPauseButton
  end if

  if m.top.appMode <> "KIDS_MODE"
    m.sendFeedBackButton.visible = true
    if m.playerControlExperimentType = "none"
      m.closedCaptionAudioButton.translation = [1520, 0]
      m.sendFeedBackButton.translation = [1655, 0]
    end if
  else if m.playerControlExperimentType = "none"
    m.closedCaptionAudioButton.translation = [1655, 0]
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

        if nextResource <> invalid AND setDrmOnContent(contentNode, nextResource, [nextCodecIndex, nextDrmIndex]) = true
          sendVideoResourceFallbackToPlayerLogLib(currentResource, nextResource, "CODEC")

          fallbackInfo = {
            failed_url: removeExcessUrl(currentResource.url)
            failed_codec: currentResource.codec
            fallback_url: removeExcessUrl(nextResource.url)
            fallback_codec: nextResource.codec
            model: m.constants.deviceInfo.model
            video_id: contentNode.id
          }

          ' log that we fell back to the next playback option after playback failed due to Codec
          logError(FormatJSON(fallbackInfo), "videoLoad", "codec-fallback", 0.1)
          return true
        end if
      end if
    end if
  end if
  return false
End Function


' checkIfCodecFallbackIsAvailable function checks if a codec fallback is available.
' @contentNode: roSGNode, a TubiContentNode
Function checkIfCodecFallbackIsAvailable(contentNode)
  tubiLog("VideoPlayer.advanceCodecOnContent")

  if contentNode <> invalid
    videoResources = contentNode.videoResources
    currentVideoResourceIndex = contentNode.currentVideoResourceIndex

    if videoResources <> invalid AND currentVideoResourceIndex <> invalid AND currentVideoResourceIndex.Count() >= 2
      currentCodecIndex = currentVideoResourceIndex[0]
      nextCodecIndex = currentCodecIndex + 1
      if videoResources[currentCodecIndex] <> invalid AND videoResources[nextCodecIndex] <> invalid
        return videoResources[nextCodecIndex][0] <> invalid
      end if
    end if
  end if
  return false
End Function


' checkIfDRMFallbackIsAvailable function checks if a DRM fallback is available.
' @contentNode: roSGNode, a TubiContentNode
Function checkIfDRMFallbackIsAvailable(contentNode)
  tubiLog("VideoPlayer.advanceDrmOnContent")

  if contentNode <> invalid
    videoResources = contentNode.videoResources
    currentVideoResourceIndex = contentNode.currentVideoResourceIndex
    if videoResources <> invalid AND currentVideoResourceIndex <> invalid AND currentVideoResourceIndex.Count() >= 2

      currentCodecIndex = currentVideoResourceIndex[0]
      currentDrmIndex = currentVideoResourceIndex[1]

      if videoResources[currentCodecIndex] <> invalid
        nextDrmIndex = currentDrmIndex + 1
        nextResource = videoResources[currentCodecIndex][nextDrmIndex]

        if nextResource = invalid
          nextCodecIndex = currentCodecIndex + 1
          nextDrmIndex = 0

          if videoResources[nextCodecIndex] <> invalid
            nextResource = videoResources[nextCodecIndex][nextDrmIndex]
          end if
        end if

        return nextResource <> invalid
      end if
    end if
  end if
  return false
End Function


'sends the video information to playerloglib in order to fire VideoResourceFallbackEvent
'@failedResource: assocarray, contains information about failed resource of current video
'@fallbackResource: assocarray, contains information about fallback resource of current video
'@failedType: string, possible values are CODEC, DRM
'
Function sendVideoResourceFallbackToPlayerLogLib(failedResource, fallbackResource, failedType)
  if isAA(failedResource) = true AND isAA(fallbackResource) = true AND isNonEmptyString(failedType) = true

    if isNonEmptyString(failedResource.type) = true
      resourceType = UCase(failedResource.type)
      failedResourceType = m.constants.player.videoResourceType[resourceType]
    else
      failedResourceType = m.constants.player.videoResourceType["UNKNOWN"]
    end if

    if isNonEmptyString(failedResource.codec) = true
      resourceCodec = UCase(failedResource.codec)
      failedCodecType = m.constants.player.videoCodecType[resourceCodec]
    else
      failedCodecType = m.constants.player.videoCodecType["UNKNOWN"]
    end if

    if isNonEmptyString(failedResource.hdcpversion) = true
      hdcpversion = UCase(failedResource.hdcpversion)
      failedHdcpversion = m.constants.player.hdcpVersion[hdcpversion]
    else
      failedHdcpversion = m.constants.player.hdcpVersion["UNKNOWN"]
    end if

    if isNonEmptyString(fallbackResource.type) = true
      resourceType = UCase(fallbackResource.type)
      fallbackResourceType = m.constants.player.videoResourceType[resourceType]
    else
      fallbackResourceType = m.constants.player.videoResourceType["UNKNOWN"]
    end if

    if isNonEmptyString(fallbackResource.codec) = true
      resourceCodec = UCase(fallbackResource.codec)
      fallbackCodecType = m.constants.player.videoCodecType[resourceCodec]
    else
      fallbackCodecType = m.constants.player.videoCodecType["UNKNOWN"]
    end if

    if isNonEmptyString(fallbackResource.hdcpversion) = true
      hdcpversion = UCase(fallbackResource.hdcpversion)
      fallbackHdcpversion = m.constants.player.hdcpVersion[hdcpversion]
    else
      fallbackHdcpversion = m.constants.player.hdcpVersion["UNKNOWN"]
    end if

    videoResourceFallback = {
      type: failedType
      failed_video_resource_type: failedResourceType
      failed_video_codec_type: failedCodecType
      failed_hdcp_version: failedHdcpversion
      failed_url: removeExcessUrl(failedResource.url)
      fallback_video_resource_type: fallbackResourceType
      fallback_video_codec_type: fallbackCodecType
      fallback_hdcp_version: fallbackHdcpversion
      fallback_url: removeExcessUrl(fallbackResource.url)
    }
    updatePlayerLogLib(m.playerLogLib, "fireVideoResourceFallbackEvent", videoResourceFallback)
  end if
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

        if nextResource <> invalid AND setDrmOnContent(contentNode, nextResource, [nextCodecIndex, nextDrmIndex]) = true
          sendVideoResourceFallbackToPlayerLogLib(currentResource, nextResource, "DRM")

          fallbackInfo = {
            failed_url: removeExcessUrl(currentResource.url)
            failed_drm: currentResource.type
            fallback_url: removeExcessUrl(nextResource.url)
            fallback_drm: nextResource.type
            model: m.constants.deviceInfo.model
            video_id: contentNode.id
          }

          ' log that we fell back to the next playback option after playback failed due to DRM
          logError(FormatJSON(fallbackInfo), "videoLoad", "drm-fallback", 0.1)
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
    contentNode.length = resource.length
    contentNode.streamFormat = resource.streamFormat
    contentNode.drmType = resource.type
    contentNode.codec = resource.codec
    contentNode.resolution = resource.resolution
    contentNode.currentVideoResourceIndex = videoResourceIndex
    contentNode.hdcpVersion = resource.hdcpVersion

    updatePlayerLogLib(m.playerLogLib, "setVideoContent", contentNode)

    '//set youbora field
    youboraTracking = {}
    trackingKeys = m.constants.thirdParty.youbora.trackingKeys
    youboraTracking[trackingKeys.titanVersionOrExperimentVersion] = resource.titanVersionOrExperimentVersion
    youboraTracking[trackingKeys.generatorVersion] = resource.generatorVersion
    contentNode.youboraTracking = youboraTracking

    ' set DRM scheme specific fields
    if resource.type = m.constants.player.drmTypes.dashWidevine
      contentNode.drmParams = resource.drmParams
    else if resource.type = m.constants.player.drmTypes.dashPlayready
      contentNode.encodingType = resource.encodingType
      contentNode.encodingKey = resource.encodingKey
    end if
    return true
  else
    updatePlayerLogLib(m.playerLogLib, "setVideoContent", contentNode)
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
  if type(url) = "roString" OR type(url) = "String"
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

    viewTime = Int((m.playerPosition - m.lastPingTime) * 1000) 'ms

    playProgressEvent = {
      type: "play_progress"
      values: {
        video_id: m.Video.content.id.toInt()
        position: Int(m.playerPosition * 1000) 'ms - without Int(), can return scientific notation, causing API error
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
      logInfo(FormatJSON(videoInfo), "videoInfo", "view-time-exceeds")
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
      measuredBitrate = Int(m.Video.streamInfo.measuredBitrate / 1000000) 'dividing by 10^6

      if measuredBitrate >= 0
        playProgressEvent.values.nominal_speed = measuredBitrate
      end if
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

  for i = 0 to seekReferenceQueue.count() - 1
    positionMatchesWithSeekReferenceQueue = (seekReferenceQueue[i] <= position) ' this handles if video node not returned any callback position

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
  if streamingSegment <> invalid AND streamingSegment.segBitrateBps <> invalid AND (streamingSegment.segType = invalid OR streamingSegment.segType = 2 OR streamingSegment.segType = 0) then
    m.top.segInfo = streamingSegment
  end if

  ' Update player stats overlay when streaming segment changes
  updatePlayerStatsOverlay()
End Function


Function onDownloadedSegment(msg)
  downloadedSegment = msg.getData()

  if isAA(downloadedSegment) = true
    updatePlayerLogLib(m.playerLogLib, "setDownloadedSegmentData", downloadedSegment)
    updatePlayerStatsOverlay()
  end if
End Function


' This function can be deleted if roku_bww_deeplinked_content experiment does not graduate.
Function deeplinkBWWCallBack()
  showTransport()
  showBrowseWhileWatching()
  m.isBWWShownForDeeplinkUser = true
End Function


' showratingOverlay helps to show the rating overlay and start the timer to hide it after certain amount of time.
' @callback: function, optional callback function to be called after the rating overlay is shown.
'            this parameter should be deleted if roku_bww_deeplinked_content experiment does not graduate.
Function showRatingOverlay(callback = invalid)

  content = m.Video.content

  if content <> invalid AND isNonEmptyString(content.rating) = true
    if callback <> invalid
      fade(m.ratingOverlay, "in", 0.1, 0, -1, callback)
    else
      fade(m.ratingOverlay, "in", 0.6)
    end if

    if m.TopOverlay.opacity > 0.0
      m.ratingOverlay.translation = [0, m.ratingOverlayAnimatedPositionY]
    else
      m.ratingOverlay.translation = [0, 0]
    end if
    m.ratingOverlayTimer.control = "start"

    ' Update branding logo visibility when rating overlay is shown
    updateBrandingLogoVisibility(true, 0.5)
  end if

End Function


' hideRatingOverlay helps to hide the rating overlay and reset the rating Interval.
Function hideRatingOverlay()

  if m.ratingOverlay.opacity > 0
    ' resetting ratingInterval to zero, because we don't want to show the ratingOverlay immediately after hiding
    m.ratingInterval = 0
    fade(m.ratingOverlay, "out", 0.6)

    ' Update branding logo visibility when rating overlay is hidden
    if m.HUD.opacity = 0
      updateBrandingLogoVisibility(false, 0.5)
    end if
  end if

End Function


' updateBrandingLogoVisibility manages the visibility of the branding logo group
' The branding logo should be visible when either transport controls or rating overlay is displayed
' @shouldShowBrandingLogo: boolean, true to show the logo with animation, false to hide the logo with animation
' @delay: integer, delay to start the animation
Function updateBrandingLogoVisibility(shouldShowBrandingLogo = false, delay = 0)
  'roku_player_branding_v2 exposure event should be fired when content loads
  if shouldShowBrandingLogo = true AND getStatsigExperimentResource("roku_player_improvement", "roku_player_branding_v2", true).enabled = true
    ' Update branding logo URI and width based on app mode, then show with animation
    if m.top.appMode = "KIDS_MODE"
      m.brandingLogo.uri = "pkg:/images/logo-kids-large.webp"
      m.brandingLogo.width = 255
    else
      m.brandingLogo.uri = "pkg:/images/logo-large.webp"
      m.brandingLogo.width = 135
    end if
    fade(m.brandingLogo, "in", 0.6, delay)
  else
    ' Hide branding logo with shrink-out animation
    fade(m.brandingLogo, "out", 0.6, delay)
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
  if content <> invalid AND content.creditCuePoints <> invalid
    creditCuePoints = content.creditCuePoints
  end if

  return creditCuePoints
End Function


Function setCCAudioTransportBarVisibility()
  isCCOrAudioAvailable = m.Video.availableAudioTracks.Count() > 1 OR m.Video.availableSubtitleTracks.Count() > 0
  m.closedCaptionAudioButton.visible = (isCCOrAudioAvailable = true)
  m.closedCaptionAudioButton.enabled = (isCCOrAudioAvailable = true)
End Function


Function onGlobalCaptionChanged(msg)
  caption = msg.getData()
  m.Video.globalCaptionMode = caption

  if caption = "Off"
    setAudioSubtitleTransportBarIcon("Off")
  else
    setAudioSubtitleTransportBarIcon("On")
  end if
End Function


Function onWasCCBackButtonSelectedChange(msg)
  wasBackSelected = msg.getData()
  if wasBackSelected = true
    hideClosedCaptionAudioTrackOverlay()
    m.closedCaptionAudioButton.focusState = true
  end if
End Function


Function onWasBackORLeftButtonSelectedForSendFeedback(msg)
  wasBackOrLeftSelected = msg.getData()
  if wasBackOrLeftSelected = true
    hideSendFeedbackOverlay()
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
  setCCAudioTransportBarVisibility()
End Function


Function onSubtitleTrackChanged(msg)
  subtitleTrack = msg.getData()
  m.closedCaptionAndAudioSelectionOverlay.currentSubtitleTrack = subtitleTrack
  availableSubtitleTracks = m.Video.availableSubtitleTracks

  for each track in availableSubtitleTracks

    if subtitleTrack = track.trackName

      languageCode = m.tubiTrackingInfo.getLanguageCode(track.language)
      selectedSubtitleTrack = {
        language: languageCode,
      }

      m.top.subtitleTrackSettings = selectedSubtitleTrack
      m.top.preferredSubtitleTrack = selectedSubtitleTrack
      exit for

    end if

  end for

  updatePlayerLogLib(m.playerLogLib, "updateCaptionIndex", subtitleTrack)
End Function


Function onAudioTrackChanged(msg)
  audioTrack = msg.getData()
  m.closedCaptionAndAudioSelectionOverlay.currentAudioTrack = audioTrack
  availableAudioTracks = m.Video.availableAudioTracks

  for each track in availableAudioTracks

    if audioTrack = track.Track
      audioDescriptionTrackNamePrefix = m.constants.player.audioTrack.audioDescriptionTrackNamePrefix

      if isNonEmptyString(track.name) = true AND track.name.instr(audioDescriptionTrackNamePrefix) > -1
        role = m.constants.player.audioTrack.roles.description
      else
        role = m.constants.player.audioTrack.roles.main
      end if

      languageCode = m.tubiTrackingInfo.getLanguageCode(track.language)
      selectedAudioTrack = {
        language: languageCode,
        role: role
      }

      m.top.audioTrackSettings = selectedAudioTrack
      m.top.preferredAudioTrack = selectedAudioTrack

    end if

  end for
End Function


Function setInitialSubtitleTrack(availableSubtitleTracks)
  preferredSubtitleTrack = m.top.preferredSubtitleTrack
  m.currentSubtitleLanguage = ""

  ' Proceeding only if we have stored device level settings.
  if availableSubtitleTracks <> invalid AND availableSubtitleTracks.Count() > 0 AND isAA(preferredSubtitleTrack) = true AND isNonEmptyString(preferredSubtitleTrack.language) = true
    ' Holds the value of the subtitleTrack to be set to the video node.
    updatedSubtitleTrack = invalid

    for each track in availableSubtitleTracks

      if isNonEmptyString(track.TrackName) then
        languageCode = m.tubiTrackingInfo.getLanguageCode(track.language)
        if languageCode = preferredSubtitleTrack.language
          updatedSubtitleTrack = track
          m.currentSubtitleLanguage = languageCode
          exit for
        end if
      end if
    end for

    ' Setting updated subtitle track to the video node.
    if updatedSubtitleTrack <> invalid
      m.Video.subtitleTrack = updatedSubtitleTrack.TrackName
      m.closedCaptionAndAudioSelectionOverlay.currentSubtitleTrack = updatedSubtitleTrack.TrackName
    else
      m.closedCaptionAndAudioSelectionOverlay.currentSubtitleTrack = availableSubtitleTracks[0].TrackName
    end if

  else if availableSubtitleTracks <> invalid AND availableSubtitleTracks.Count() > 0 AND isNonEmptyString(m.video.currentSubtitleTrack) = true
    ' This else block will handle case where we do not have a preferred subtitle track saved for device.
    m.closedCaptionAndAudioSelectionOverlay.currentSubtitleTrack = m.video.currentSubtitleTrack
    m.currentSubtitleLanguage = m.tubiTrackingInfo.getLanguageCode(availableSubtitleTracks[0].language)
  end if
End Function


Function setInitialAudioTrack(availableAudioTracks)
  preferredAudioTrack = m.top.preferredAudioTrack
  m.currentAudioLanguage = ""

  ' Proceeding only if we have stored device/user level settings.
  if availableAudioTracks <> invalid AND availableAudioTracks.Count() > 1 AND isAA(preferredAudioTrack) = true AND isNonEmptyString(preferredAudioTrack.language) = true
    ' Holds the value of the audioTrack to be set to the video node.
    updatedAudioTrack = invalid
    for each track in availableAudioTracks

      if isNonEmptyString(track.name) then

        hasAccessibilityDescription = false
        if track.name.instr(m.constants.player.audioTrack.audioDescriptionTrackNamePrefix) > -1
          hasAccessibilityDescription = true
        end if

        languageCode = m.tubiTrackingInfo.getLanguageCode(track.language)

        if languageCode = preferredAudioTrack.language
          m.currentAudioLanguage = languageCode
          ' If it is normal audio track and user did not prefer one with audio description.
          if hasAccessibilityDescription = false AND preferredAudioTrack.role = m.constants.player.audioTrack.roles.main
            updatedAudioTrack = track
          else if hasAccessibilityDescription = true AND preferredAudioTrack.role = m.constants.player.audioTrack.roles.description
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
End Function


Function onSubtitleTrackChangedOnCCOverlay(msg)
  subtitleTrack = msg.getData()
  m.Video.subtitleTrack = subtitleTrack
End Function


Function onAudioTrackChangedOnCCOverlay(msg)
  audioTrack = msg.getData()
  m.Video.audioTrack = audioTrack
End Function


Function onRelatedItemFocused()
  m.lastButtonPressPos = m.playerPosition
  ' Do not show the PauseAd if the user interacting the BrowseWhileWatching row.
  ' Resetting the timer when there is any user interaction during pause
  if m.pauseAdOverlayTimer.control = "start"
    restartPauseAdTimer()
  end if
End Function


Function onBrowseContentSelected(msg)
  screen = msg.getRoSGNode()

  if screen <> invalid then
    selectedContent = screen.selectedRelatedContentItem
    animateTransport("out")
    hideBrowseWhileWatching()
    setFocusToPlaybackControl()
    m.top.homescreenContentToPlay = selectedContent
    m.top.homescreenContentToPlayUpdated = true
    resetTransportButtons()

    updatePlayerLogLib(m.playerLogLib, "setBrowseWhileWatchingDidConvert", true)
  end if
End Function


Function onRelatedItemSelected(msg)
  screen = msg.getRoSGNode()

  if screen <> invalid then
    selectedContent = screen.selectedRelatedContentItem
    animateTransport("out")
    hideBrowseWhileWatching()
    setFocusToPlaybackControl()
    m.top.relatedContentToPlay = selectedContent
    resetTransportButtons()

    updatePlayerLogLib(m.playerLogLib, "setBrowseWhileWatchingDidConvert", true)
  end if

End Function


Function onKeyPressWhenBrowseWhileWatchingHasFocus(msg)
  keyPress = msg.getData()

  if keyPress = "fastforward"
    animateTransportAndBrowseWhileWatching("out")
    handleFastForward()
  else if keyPress = "rewind"
    animateTransportAndBrowseWhileWatching("out")
    handleRewind()
  end if

End Function


Function onSeekToChange(msg)
  position = msg.getData()
  jumpToPosition(position)
End Function


Function onRelatedContentUpdated(msg)
  m.BrowseWhileWatching.content = m.top.relatedContent
  m.BrowseWhileWatching.updateContent = true
End Function


Function onBrowseContentUpdated(msg)
  m.BrowseWhileWatching.content = m.top.browseContent
  m.BrowseWhileWatching.isLoading = false
  m.BrowseWhileWatching.updateContent = true
End Function


Function onNavigateWithinPageInfoChange(msg)
  navigateWithinPageInfo = msg.getData()
  appendContentUserContextValues(navigateWithinPageInfo, m.top.content, m.top.isAdultParentalLevel)
  m.top.relatedNavigateWithinPageInfo = navigateWithinPageInfo
End Function


Function onTrackingComponentInfo(msg)
  componentInfo = msg.getData()
  if componentInfo <> invalid
    appendContentUserContextValues(componentInfo, m.top.content, m.top.isAdultParentalLevel)
    m.top.trackingComponentInfo = componentInfo
  end if
End Function


Function onTCFStringChange(msg)
  m.adsLimited.tcfString = msg.getData()
End Function


Function onUserConsentsOptOutStatusChange(msg)
  m.adsLimited.userConsentsOptOutStatus = msg.getData()
End Function


Function onHandleFilledAdData(msg)
  m.filledAdData = msg.getData()

  adPosition = m.top.adPosition

  if isAA(m.filledAdData) = true AND isNumber(m.playerPosition) AND isNumber(adPosition) = true
    adCount = 0
    if isNumber(m.filledAdData.adCount) = true
      adCount = m.filledAdData.adCount
    end if

    currentPosition = Int(m.playerPosition)
    adPosition = Int(adPosition)
    adControl = m.top.adControl
    positionDeviation = currentPosition - adPosition 'Position minus cue point. We can know we might miss this cue point because it responds too slowly.

    if adControl = "midroll"
      adRequestPosition = adPosition - m.adPrefetchTime 'we prefetch 15 seconds before cuepoint
    else
      adRequestPosition = adPosition
    end if

    cuepointInfo = {
      is_preroll: (adControl = "preroll")
      position: currentPosition * 1000 'ms
      request_position: adRequestPosition * 1000 'ms
      position_deviation: positionDeviation * 1000 'ms
      ad_count: adCount
      cue_point: adPosition * 1000 'ms
    }
    updatePlayerLogLib(m.playerLogLib, "fireCuepointFilledEvent", cuepointInfo) 'bs:disable-line 1140 LINT1001
  end if
End Function


Function onAdTrackingObject(msg)
  adInfo = msg.getData()
  adStatus = adInfo.type
  'possible adStatus are PodStart, Start, Complete, Error, PodComplete, Close
  'adStatus=PodStart, when AdPod Starts
  'adStatus=Start, when individual Ad starts
  'adStatus=Complete, when individual Ad completes
  'adStatus=Error, when there is an error in individual Ad
  'adStatus=PodComplete, when AdPod completes
  'adStatus=Close, when user closes the Ad

  if m.isAdsOverlayExperimentEnabled = true
    m.adCountdownOverlay.adInfo = adInfo
  end if

  pixelsFiredStatus = adInfo.pixelsFiredStatus

  if isAA(pixelsFiredStatus) = true
    if pixelsFiredStatus["Impression"] = true
      m.adImpressionMap["0"] += 1
    end if

    if pixelsFiredStatus["FirstQuartile"] = true
      m.adImpressionMap["1"] += 1
    end if

    if pixelsFiredStatus["Midpoint"] = true
      m.adImpressionMap["2"] += 1
    end if

    if pixelsFiredStatus["ThirdQuartile"] = true
      m.adImpressionMap["3"] += 1
    end if

    if pixelsFiredStatus["Complete"] = true
      m.adImpressionMap["4"] += 1
    end if
  end if

  if adStatus = "PodStart"
    ' Firing the exposure event when ad is loaded.
    getExperimentResource("roku_player_ui_refresh", "roku_ads_overlay_v1", true)
    updatePlayerLogLib(m.playerLogLib, "setTotalAdDurationInCurrentPod", adInfo)
  else if adStatus = "Impression" AND m.isAdsOverlayExperimentEnabled = true
    ' Since Roku clears out the node when the ad is complete, we need to re-append the adCountdownOverlay to the RAFAdContainer.
    overlay = m.RAFAdContainer.findNode("adCountdownOverlay")
    if overlay = invalid
      rafRender = m.RAFAdContainer.getChild(0)
      if rafRender <> invalid
        rafRender.appendChild(m.adCountdownOverlay)
      end if
    end if
  else if adStatus = "Start"
    m.playerExitInfo["ad_counts"] += 1
    updatePlayerLogLib(m.playerLogLib, "setAdCount", 1)
    updatePlayerLogLib(m.playerLogLib, "fireAdStartupPerformanceEvent", adInfo)
    updatePlayerLogLib(m.playerLogLib, "fireAdStartEvent", adInfo)
  else if adStatus = "Complete"
    updatePlayerLogLib(m.playerLogLib, "setAdViewTime", adInfo)
    updatePlayerLogLib(m.playerLogLib, "fireAdCompleteEvent", adInfo)
  else if adStatus = "Error"
    'If the last ad in the ad pod returns an error, we need to reset is_buffering to false, as onAdBufferingObject won't be triggered afterward.
    updatePlayerLogLib(m.playerLogLib, "setIsBuffering", false)
    updatePlayerLogLib(m.playerLogLib, "fireAdDiscontinueEvent", adInfo)
  else if adStatus = "PodComplete"
    updatePlayerLogLib(m.playerLogLib, "fireAdPodCompleteEvent", adInfo)
  else if adStatus = "Close"
    updatePlayerLogLib(m.playerLogLib, "setAdViewTime", adInfo)
    updatePlayerLogLib(m.playerLogLib, "resetAdPodInfo")
  end if

  'This helps to set the different startup results like START_LOAD, VIEWED_FIRST_FRAME, PLAY_STARTED, UNKNOWN
  updatePlayerLogLib(m.playerLogLib, "setAdPodStartupResult", adInfo)


  isAd = (adStatus <> "PodComplete")
  m.playerExitInfo["is_ad"] = isAd
  updatePlayerLogLib(m.playerLogLib, "setIsAd", isAd)
End Function


Function onAdBufferingObject(msg)
  adBufferingInfo = msg.getData()
  if isAA(adBufferingInfo) = true AND adBufferingInfo.eventType = "reBuffer"
    if isAA(adBufferingInfo) = true AND isAA(adBufferingInfo.ad) = true AND adBufferingInfo.ad.adId <> invalid
      updatePlayerLogLib(m.playerLogLib, "trackAdReBuffer", adBufferingInfo.ad.adId)
    end if
    updatePlayerLogLib(m.playerLogLib, "setIsBuffering", true)
    updatePlayerLogLib(m.playerLogLib, "setAdBufferingDurationStartTime")
  else if isAA(adBufferingInfo) = true AND adBufferingInfo.eventType = "reBufferEnd"
    updatePlayerLogLib(m.playerLogLib, "setAdBufferingDurationEndTime")
    updatePlayerLogLib(m.playerLogLib, "setIsBuffering", false)
  else
    updatePlayerLogLib(m.playerLogLib, "setIsBuffering", false)
  end if

  progress = adBufferingInfo.progress
  if progress = invalid 'progress field will not present on adBufferingInfo when Ad begins to buffer, so checking against invalid
    updatePlayerLogLib(m.playerLogLib, "setAdBufferStartTime")
  end if

  if m.isAdsOverlayExperimentEnabled = true
    ' Adding a check for optimization so that we do not have to perform find node always.
    if progress = 100
      ' Hide the overlay when the ad is fully buffered.
      overlay = m.RAFAdContainer.findNode("overlay")
      if overlay <> invalid
        overlay.opacity = 0
      end if
    end if
    m.adCountdownOverlay.adInfo = adBufferingInfo
  end if
End Function


Function onExitPlayer(msg)
  exitPlayer = msg.getData()

  if exitPlayer = true
    ' Handle startup failure count logic in PlayerLogLib
    updatePlayerLogLib(m.playerLogLib, "setStartupFailureCount")

    m.playerExitInfo.message_map = {}
    m.playerExitInfo.message_map.exitReason = m.top.exitReason
    updatePlayerLogLib(m.playerLogLib, "firePlayerPageExitEvent", m.playerExitInfo)
    'reset playerExitInfo
    m.playerExitInfo = {
      ad_counts: 0
      is_ad: false
      message_map: {}
    }
    m.top.exitReason = ""
    m.top.exitPlayer = false
  end if
End Function


'Determine the reason for the missed ad event
'@reason: string, possible values are autoPlay, exitDuringPlayback, exitBeforeResponse, exitBeforePlayback, exitAfterCuePointPassed
'
Function sendAdMissedEvent(reason)
  adMissedInfo = {
    reason: reason
    position: Int(m.playerPosition) * 1000 'ms
    cue_point: Int(m.top.adPosition) * 1000 'ms
  }

  if isAA(m.filledAdData) = true

    if m.filledAdData.adResponseTime <> invalid AND m.filledAdData.adResponseTime <> -1
      adMissedInfo.response_time = m.filledAdData.adResponseTime * 1000 'ms
    end if

    if m.filledAdData.adCount <> invalid AND m.filledAdData.adCount > 0
      adMissedInfo.ad_count = m.filledAdData.adCount
    end if

    if m.filledAdData.totalAdsDuration <> invalid AND m.filledAdData.totalAdsDuration > 0
      adMissedInfo.total_ads_duration = Int(m.filledAdData.totalAdsDuration) * 1000 'ms
    end if

  end if

  if isNonEmptyArray(m.positionArr) = true
    sPositionArr = []

    for each arr in m.positionArr
      sPositionArr.push(arr.toStr())
    end for

    adMissedInfo.message_map = { playerPositionArr: sPositionArr.join(",") }
  end if
  updatePlayerLogLib(m.playerLogLib, "fireAdMissedEvent", adMissedInfo)
End Function


Function fireBrowseWhileWatchingPlaybackSessionEndEvent()
  if m.playerLogLib <> invalid AND m.playerLogLib.didUserSeeBwwPeek = true
    isSeries = m.top.content <> invalid AND m.top.content.parentType = "series"
    playbackSource = m.playerLogLib.playbackSource
    isFromDeeplink = false
    if isAA(playbackSource) = true
      srcForAds = playbackSource.srcForAds
      isFromDeeplink = (srcForAds = m.constants.player.playbackOrigin.deeplink)
    end if
    data = {
      "openCount": m.playerLogLib.bwwOpenCount
      "didConvert": m.playerLogLib.bwwDidConvert
      "isSeries": isSeries
      "isDeeplink": isFromDeeplink
    }

    logInfo(FormatJson(data), "videoInfo", "browseWhileWatchingPlaybackSessionEnd")
  end if
End Function


Function onShowPlayerStatsChange(msg)
  m.showPlayerStats = msg.getData()
End Function


Function updatePlayerStatsOverlay()
  updatePlayerStatsOverlayMixin(m.constants, m.Video, m.showPlayerStats, m.playerStatsOverlay)
End Function
