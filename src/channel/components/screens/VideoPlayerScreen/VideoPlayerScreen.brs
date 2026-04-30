'   Analytics tracking:
'
'      EVENT            TRIGGERS
'      ===============================
'      start_video        only on start of episode playback, or autoplay invoked playback
'
'      resume_after_break   after pre-roll and each mid-roll
'
'      play_progress      on start of scrubbing
'                         at regular intervals set by 'pingFrequency' in constants
'
'      seek               at end of scrubbing
'
'      pause_toggle       when paused using pause/play button
'                         when resumed using pause/play button
'
'   User History tracking:
'
'      - when user exits the ad or video by pressing 'back'
'      - right before a mid-roll
'      - every 3 minutes of watching
'

Function init()
  logDebug("VideoPlayer.init")

  ' handle BaseScreen functionality (see BaseScreen.xml)
  m.constants = getConstantsFromGlobal()
  m.auth = TubiAuth(m.constants)
  m.top.screenLevel = m.constants.ui.screenLevels.videoPlayerScreen
  m.top.trackingPageInfo = {
    pageType: "video_player_page"
    pageValues: {}
  }

  m.isAlignAdRequestExposureFired = false 'using this variable to avoid experiment calls during every video position change

  m.tubiTrackingInfo = TubiTrackingInfo(m.constants)
  m.top.observeFieldScoped("focusedChild", "onScreenFocusChange")

  m.top.handlesTransportVoiceRequests = true
  m._ = rodash()
  m.NodeHelpers = TubiNodeHelpers()

  m.Tracking = TubiTracking(m.constants, m.auth, m.top.userConsentsOptOutStatus, TubiRequest(m.constants.settings))
  isGDPRinArg = isOneTrustConsentEnabled()
  m.adsLimited = TubiAdsLimited(m.constants, m.auth, m.top.tcfString, m.top.userConsentsOptOutStatus, isGDPRinArg)
  m.top.observeFieldScoped("tcfString", "onTCFStringChange")
  m.top.observeFieldScoped("userConsentsOptOutStatus", "onUserConsentsOptOutStatusChange")
  m.Loading = m.top.findNode("Loading")
  m.MinimizedAssets = m.top.findNode("MinimizedAssets")
  m.LoadingProgressBar = m.top.findNode("LoadingProgressBar")
  m.LoadingMessage = m.top.findNode("LoadingMessage")

  m.LoadingSpinner = m.top.findNode("LoadingSpinner")

  m.UpNext = m.top.findNode("UpNext")
  m.UpNextParent = m.top.findNode("UpNextParent")
  m.UpNext.observeFieldScoped("contentSelected", "onUpNextContentSelected")
  m.UpNext.observeFieldScoped("opacity", "onUpNextOpacityChange")
  m.UpNext.observeFieldScoped("autoplayMode", "onUpNextAutolayModeChange")
  m.Video = m.top.findNode("VideoNode") ' reference in case we change from extending Video to extending Group
  m.Video.observeFieldScoped("streamInfo", "onStreamInfoChanged")
  m.Video.observeFieldScoped("position", "onVideoPositionChange")
  m.Video.observeFieldScoped("state", "onVideoStateChange")
  m.Video.observeFieldScoped("bufferingStatus", "onBufferingStatus")
  m.Video.observeFieldScoped("streamingSegment", "onStreamingSegmentChange")
  m.video.observeFieldScoped("availableSubtitleTracks", "setCCAudioTransportBarVisibility")
  m.video.observeFieldScoped("availableAudioTracks", "onAvailableAudioTracksChange")
  m.video.observeFieldScoped("audioTrack", "onAudioTrackChanged")
  m.video.observeFieldScoped("subtitleTrack", "onSubtitleTrackChanged")
  'downloadedSegment is needed for player log - Quality Of Service event
  m.video.observeFieldScoped("downloadedSegment", "onDownloadedSegment")
  m.videoBorder = m.top.findNode("VideoBorder")

  m.adPrefetchTimeUsedForExposure = 15 ' default prefetch time for ad request cuepoint alignment experiment used for exposure firing
  ' Initialize all experiments in one place
  initExperiments()

  ' Enable decoder stats with a 20% probability.
  ' Generates a random number between 0 and 1 using Rnd(0).
  ' If the number is less than or equal to 0.2 (20%), decoder stats are enabled; otherwise, they are disabled.
  fRandom = Rnd(0)

  if fRandom <= 0.2
    m.isDecoderStatsEnabled = true
  else
    m.isDecoderStatsEnabled = false
  end if

  if m.isDecoderStatsEnabled = true
    m.Video.enableDecoderStats = true
    m.cumulativeDecoderStats = {
      renderCount: 0,
      repeatCount: 0,
      frameDropCount: 0,
      streamErrorCount: 0
    }

    ' Store last observed renderCount to handle resets
    m.lastRenderCount = 0
    m.Video.observeFieldScoped("decoderStats", "onDecoderStatsChange")
  end if

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

  m.marginX = m.constants.ui.translations.player.marginX

  browseWhileWatchingRow = m.top.findNode("BrowseWhileWatchingRow")

  ' Create either landscape or portrait BWW based on experiment
  if m.isBWWLandscapeEnabled = true
    m.BrowseWhileWatching = browseWhileWatchingRow.createChild("RelatedLandscape")
    m.BrowseWhileWatching.translation = [m.marginX, 945]
    m.BrowseWhileWatching.observeFieldScoped("selectedRelatedContentItem", "onRelatedItemSelected")
  else
    m.BrowseWhileWatching = browseWhileWatchingRow.createChild("Related")
    m.BrowseWhileWatching.translation = [m.marginX, 550]
    m.BrowseWhileWatching.observeFieldScoped("selectedRelatedContentTrigger", "onRelatedItemSelected")
  end if

  m.BrowseWhileWatching.associatedPageName = "video_player_page"
  m.BrowseWhileWatching.observeFieldScoped("trackingComponentInfo", "onTrackingComponentInfo")
  m.BrowseWhileWatching.observeFieldScoped("focusedContent", "onRelatedItemFocused")
  m.BrowseWhileWatching.observeFieldScoped("keyPress", "onKeyPressWhenBrowseWhileWatchingHasFocus")
  m.BrowseWhileWatching.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")

  m.top.observeFieldScoped("updateRelatedContent", "onRelatedContentUpdated")
  m.top.observeFieldScoped("updateContent", "onContentChange")
  m.top.observeFieldScoped("sprites", "onSpritesReceived")
  m.top.observeFieldScoped("control", "onControlChange")
  m.top.observeFieldScoped("transportVoiceRequest", "handleTransportVoiceEvent")
  m.top.observeFieldScoped("adState", "onAdStateChange")
  m.top.observeFieldScoped("adProgress", "onAdProgressChange")
  m.top.observeFieldScoped("displayAdLoadingMessage", "onDisplayAdLoadingMessage")
  m.top.observeFieldScoped("seekTo", "onSeekToChange")
  m.top.observeFieldScoped("adTrackingObject", "onAdTrackingObject")
  m.top.observeFieldScoped("adBufferingObject", "onAdBufferingObject")
  m.top.observeFieldScoped("filledAdData", "onHandleFilledAdData")
  m.top.observeFieldScoped("showYMALInFullScreen", "onShowYMALInFullScreen")
  m.top.observeFieldScoped("videoPlayerScrubberShowcaseResponse", "onVideoPlayerScrubberShowcaseResponse")

  'isPauseAdReqInProgress is the state of pauseAd requests in flight.
  'If pause ad request is in flight, we do not send another pause ad request
  m.isPauseAdReqInProgress = false

  'isPixelFiredForCurrentPauseAd helps to find whether any ad pixel fired for current pause ad.
  'Based on this field we request pause ad or reuse the previous pause ad response
  'If any pixel event is missing for current pause ad, we do not make new pause ad request
  m.isPixelFiredForCurrentPauseAd = true

  'this field holds the last fired pixel type which helps to fire the appropriate pixels in order
  m.lastFiredPixelType = ""

  ' When user starts playback while preview-warm preroll is still fetching; discard adsPending and log preloadAdMissed
  m.ignorePreviewWarmPrerollOnAdsPending = false

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

  ' Initialize retry configuration for network errors
  m.retryConfig = {
    network: {
      maxRetries: 3
      delays: [0.5, 1, 2] ' Seconds: 0.5s, 1s, 2s exponential backoff
      errorCodes: {
        "-1": true ' Network error
        "-2": true ' Connection timeout
        "-3": true ' Unknown/generic error
      }
    }
    isRetrying: false
    currentRetryCount: 0
    lastErrorCode: 0
  }
  m.shouldRetryPlayback = false ' Flag to indicate retry (same resource) vs fallback (different resource)

  ' Map error codes to retry strategies for O(1) lookup
  m.errorRetryStrategyMap = {
    "-1": "retry_network" ' Network error
    "-2": "retry_network" ' Connection timeout
    "-3": "retry_network" ' Unknown/generic error
    "-5": "fallback_codec" ' Media error; format unknown or unsupported
    "-6": "fallback_drm" ' DRM error
  }

  ' Create retry and fallback timers once for reuse
  m.retryTimer = m.top.findNode("retryTimer")
  m.fallbackTimer = m.top.findNode("fallbackTimer")

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
  m.ratingOverlayTimer.observeFieldScoped("fire", "hideRatingOverlay")

  m.subtitleSelectionOverlay = m.top.findNode("subtitleSelectionOverlay")
  m.subtitleSelectionOverlay.observeFieldScoped("selectedTrack", "onSubtitleSelectionOverlayTrackSelected")
  m.subtitleSelectionOverlay.observeFieldScoped("backPressed", "onSubtitleSelectionOverlayBackPressed")
  m.subtitleSelectionOverlay.observeFieldScoped("playPressed", "onSubtitleSelectionOverlayPlayPressed")

  m.showSubtitleSelection = false
  ' Flag to defer showing subtitle overlay until HUD closes (when skip button timer fires while HUD is visible)
  m.pendingSubtitleOverlayOnHudClose = false

  m.RemainingMinimizedGroup = m.top.findNode("RemainingMinimizedGroup")
  m.RemainingMinimizedBground = m.top.findNode("RemainingMinimizedBground")
  m.RemainingMinimizedLabel = m.top.findNode("RemainingMinimizedLabel")

  m.TopOverlay = m.top.findNode("TopOverlay")
  m.TitleGroup = m.TopOverlay.findNode("TitleGroup")
  m.ScrubTimer = m.top.findNode("ScrubTimer")
  m.HUD = m.top.findNode("HUD")
  m.AdHeadsUp = m.top.findNode("AdHeadsUp")
  m.adHeadsUpGroup = m.top.findNode("adHeadsUpGroup")
  m.AdHeadsUpText = m.top.findNode("AdHeadsUpText")
  m.Thumbnail = m.top.findNode("Thumbnail")
  m.VideoOverlay = m.top.findNode("VideoOverlay")
  m.VideoBrowseWhileWatchingOverlay = m.top.findNode("VideoBrowseWhileWatchingOverlay")

  m.skipCuepointsButton = m.top.findNode("skipCuepointsTextIconButton")
  m.skipCuepointsButton.visible = true
  m.skipCuepointsButton.observeFieldScoped("wasSelected", "onSkipCuepointsButtonWasSelected")
  m.SkipTrailerButton = m.top.findNode("SkipTrailerTextIconButton")
  m.SkipTrailerButton.observeFieldScoped("wasSelected", "onSkipTrailerButtonWasSelected")
  initSkipCuepointsEnhancedButton()
  initSkipTrailerEnhancedButton()

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
  m.lastShownSkipCuepointType = ""

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

  m.bufferingTimer = m.top.findNode("bufferingTimer")

  m.controlIcon = m.top.findNode("controlIcon")
  m.Transport = m.top.findNode("Transport")

  m.Transport.itemSpacings = "[39, 3]"
  m.TransportButtonsXTranslation = 1730

  m.ProgressBar = m.Transport.findNode("ProgressBar")
  m.timeGroup = m.Transport.findNode("timeGroup")
  m.ElapsedLabel = m.timeGroup.findNode("ElapsedLabel")
  m.quickSeekIcon = m.timeGroup.findNode("quickSeekIcon")
  m.RemainingLabel = m.timeGroup.findNode("RemainingLabel")

  m.TransportButtons = m.Transport.findNode("TransportButtons")

  m.seekGroup = m.top.findNode("seekGroup")
  m.currentSeekLabel = m.top.findNode("currentSeekLabel")
  m.seekControlGroup = m.top.findNode("seekControlGroup")

  m.seekSpeed = m.top.findNode("seekSpeedLabel")
  m.seekIcon = m.top.findNode("seekIcon")
  m.quickSeekLabel = m.top.findNode("quickSeekLabel")

  m.typographyConstants = getTypographyConstants()
  setupTransportButtons()
  primeTransportButtonList()

  m.focusedNode = m.progressBar

  m.lastPingTime = 0
  m.lastSavedPosition = 0
  m.adHeadsUpTime = m.constants.player.adHeadsUpTime ' adHeadsUpTime helps to decide how long we need to show the AdHeadsup
  m.midrolls = {} ' midrolls holds all cuepoints from API response

  ' Prevent re-fetching ads when playback resumes after an ad break.
  ' Roku may resume a few seconds earlier due to frame alignment, which can
  ' accidentally trigger another ad request. This cooldown flag avoids that.
  m.adFetchCooldown = false ' cooldown flag to prevent re-fetching ads on resume after ad break
  m.adFetchCooldownTimer = m.top.findNode("adFetchCooldownTimer") ' timer for ad fetch cooldown
  m.adFetchCooldownTimer.observeFieldScoped("fire", "onAdFetchCooldownTimerFired")

  m.mostRecentCompletedCuepoint = -1 'used to prevent multiple resume_after_break events from firing
  m.notificationInterval = 0.999 ' The interval that we are targeting for player position updates. We specify a value lower than a second in order to get a float value
  m.Video.notificationInterval = m.notificationInterval

  'This information is used in quality of service event
  m.adImpressionMap = { "0": 0, "1": 0, "2": 0, "3": 0, "4": 0 }

  'This variable holds the value of Ad information from rainmaker response
  m.filledAdData = {}
  'This variable is used to send an AdMissed event if the previous cue point was missed
  m.isMissedAdEventSent = true
  'This variable is used to track if ad buffering happened before ad playback started
  m.adBufferingBeforeStart = true

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

  m.ProgressBar.observeFieldScoped("brandedScrubberImageReady", "onBrandedScrubberImageReadyChange")

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

  m.skipCuepointsButtonUpTranslation = 744
  m.Transport.translation = [0, 783]
  m.thumbnailMaxYOffset = 825
  m.hudYTranslation = -759
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

  setTypographyOfLabel(m.title, m.typographyConstants.ids.subheaderLarge)
  setTypographyOfLabel(m.episodeTitle, m.typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.AdHeadsUpText, m.typographyConstants.ids.subheaderMedium)
  setTypographyOfLabel(m.ratedLabel, m.typographyConstants.ids.bodySmallStrong)
  setTypographyOfLabel(m.ratingLabel, m.typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.ElapsedLabel, m.typographyConstants.ids.bodySmallStrong)
  setTypographyOfLabel(m.RemainingLabel, m.typographyConstants.ids.bodySmallStrong)

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
  positionQuickSeekIconHorizontally()
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


' Initializes all experiment configurations in one place
' This function should be called from init() after m.constants and m.video are set
Function initExperiments()
  ' Ad request cuepoint alignment experiment (roku_player_align_ad_request_cuepoint_v3):
  alignAdRequestExperimentConfig = getStatsigExperimentResource("roku_player_improvement", "roku_player_align_ad_request_cuepoint_v3", false)
  m.adPrefetchTime = alignAdRequestExperimentConfig.prefetchTime
  m.alignAdRequestWithinWindow = alignAdRequestExperimentConfig.requestWithinWindow

  ' Postplay series countdown experiment
  m.seriesPostplayTimerExperiment = getStatsigExperimentResource("roku_player_improvement", "roku_postplay_countdown_timer_series_v3", false)
  m.seriesPostplayCountdown = m.seriesPostplayTimerExperiment.countdown

  ' Async stop experiment - only enable on firmware 14.0+
  isFirmwareOk = createObject("roDeviceInfo").getOSVersion().major.toInt() >= 14
  if isFirmwareOk = true AND getStatsigExperimentResource("roku_async_stop", "roku_async_stop_v6", false).enabled = true then
    m.video.asyncStopSemantics = true
  end if

  ' Network error retry experiment
  m.isRetryExperimentEnabled = getStatsigExperimentResource("roku_player_improvement", "roku_player_retry_network_errors_v1", false).enabled

  ' Subtitle overlay experiment
  m.isSubtitleOverlayExperimentEnabled = getStatsigExperimentResource("roku_player_improvement", "roku_player_subtitle_overlay_v1", false).enabled

  ' BWW Landscape experiment
  m.isBWWLandscapeEnabled = getStatsigExperimentResource("roku_player_improvement", "roku_bww_landscape_v2", false).enabled

  ' Branded Scrubber experiment
  m.isBrandedScrubberEnabled = getStatsigExperimentResource("ads_player_layer", "roku_branded_scrubber_v1", false).enabled
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
      if m.sendFeedBackButton <> invalid
        setFocusToComponent(m.sendFeedBackButton)
      end if
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

    if m.sendFeedBackButton <> invalid
      setFocusToComponent(m.sendFeedBackButton)
    end if
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


' setSkipCuepointsButtonTextAndTimer sets the text for skipCuepoints button, making it visible and starting timer to autohide.
' @param skipCuepointsTitle - String, text to display on the skipCuepoints button (e.g., "Skip Intro", "Skip Recap")
' @param skipCuepointType - String, type of cuepoint (intro, recap, earlyCredits) used to determine subtitle overlay behavior
Function setSkipCuepointsButtonTextAndTimer(skipCuepointsTitle as String, skipCuepointType = "" as String) as Void
  logDebug("VideoPlayer.setSkipCuepointsButtonTextAndTimer")
  m.skipCuepointsButtonTimer = m.top.createChild("Timer")
  m.skipCuepointsButtonTimer.duration = m.constants.player.skipButtonDuration
  m.skipCuepointsButtonTimer.repeat = false
  m.skipCuepointsButtonTimer.observeFieldScoped("fire", "autoHideSkipCuepointsButton")
  m.skipCuepointsButtonTimer.control = "start"
  setSkipCuepointsButtonTitle(skipCuepointsTitle)
  m.lastShownSkipCuepointType = skipCuepointType
  showSkipCuepointsButton()
End Function


'Make the skipCuepoints Button visible and based on transport
'control visibility, set the translation and focus
Function showSkipCuepointsButton()
  logDebug("videoPlayerScreen.showSkipCuepointsButton")
  skipButtonWidth = m.skipCuepointsButton.boundingRect().width

  if m.HUD.opacity = 1
    xPosition = m.top.width - (skipButtonWidth + m.marginX)
    m.skipCuepointsButton.translation = [xPosition, m.skipCuepointsButtonUpTranslation]
    width = skipButtonWidth + 12

    slideTransportButtons(true, width)
  else if m.HUD.opacity > 0
    setFocusToComponent(m.skipCuepointsButton, true)
    xPosition = m.top.width - (skipButtonWidth + m.marginX)
    m.skipCuepointsButton.translation = [xPosition, m.skipCuepointsButtonUpTranslation]
    width = skipButtonWidth + 12

    slideTransportButtons(true, width)
  else
    setFocusToComponent(m.skipCuepointsButton, true)
    xPosition = m.top.width - (skipButtonWidth + m.marginX)
    m.skipCuepointsButton.translation = [xPosition, m.skipCuepointsButtonDownTranslation]

    slideTransportButtons(false)
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

  slideTransportButtons(false)
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
  m.TransportButtons.translationOverride = destination
  return slideTo(m.TransportButtons, destination, 0.6)
End Function


'Autohide the SkipCuepoints button after timer reached and HUD is not visible
Function autoHideSkipCuepointsButton()
  clearSkipCuepointsTimer()

  ' Show subtitle selection overlay after skip cuepoints button auto-hides
  ' Only show for SkipIntro and SkipRecap, not for SkipEarlyCredits
  isIntroOrRecap = m.lastShownSkipCuepointType = m.constants.player.skipCuepointsButtonTypes.intro OR m.lastShownSkipCuepointType = m.constants.player.skipCuepointsButtonTypes.recap
  shouldShowSubtitleOverlay = (m.showSubtitleSelection = true AND isIntroOrRecap = true)

  if m.HUD.opacity < 1
    hideSkipCuepointsButton(m.top)

    if shouldShowSubtitleOverlay = true
      showSubtitleSelectionOverlay()
      m.hasShownSubtitleOverlayForCurrentPlayback = true
    else
      if m.isBrandedScrubberEnabled = true AND m.top.videoPlayerScrubberShowcaseResponse <> invalid
        showTransport()
        showBrowseWhileWatching()
      end if
    end if
  else
    ' HUD is visible - defer showing subtitle overlay until HUD closes
    if shouldShowSubtitleOverlay = true
      m.pendingSubtitleOverlayOnHudClose = true
    end if
  end if
End Function


Function clearSkipCuepointsButtonAndTimer()
  setSkipCuepointsButtonTitle("")
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
  logDebug("VideoPlayer.playContent")

  ' If recap was skipped during autoplay (user clicked Next Episode with experiment enabled),
  ' mark recap as already shown to prevent "Skip Recap" button from appearing when playback
  ' starts slightly before recap_end due to video segment boundaries.
  if m.top.recapSkippedOnAutoplay = true
    m.cuePointsHistory[m.constants.player.skipCuepointsButtonTypes.recap] = true
    m.top.recapSkippedOnAutoplay = false
  end if

  if m.Video.content <> invalid

    m.hasShownSubtitleOverlayForCurrentPlayback = false

    ' Always reset ad state when we first start playback.  Preroll fetch will populate midrolls list
    m.midrolls = {}
    cleanupAdFetchCooldownTimer() ' Reset cooldown timer for new playback

    ' reset the seekReferenceQueue
    m.seekReferenceQueue = []

    ' Do not use getNumber() alone: it maps invalid to 0, which would incorrectly run the resume/seek path.
    playNowPos = -1
    if m.Video.content.nowPos <> invalid
      playNowPos = getNumber(m.Video.content.nowPos)
    end if

    if playNowPos >= 0
      m.playerPosition = playNowPos
      m.lastSavedPosition = playNowPos
      updateLastPingTime(playNowPos)
      m.lastButtonPressPos = playNowPos
      m.seekReferenceQueue.push(playNowPos)
      seekToPosition(playNowPos)

      if playNowPos = 0
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
          cuepointStr = strI(cuepoint)
          logDebug("VideoPlayer: MIDROLL: " + cuepointStr)

          if Int(cuepoint) = 0
            fetchPreroll = true
          end if

          m.midrolls[cuepointStr] = true
        end for
      end if

      ' Skip pre-roll for casting-initiated sessions starting from the beginning when the experiment is enabled.
      if fetchPreroll = true AND m.top.isCastingSession = true
        fetchPreroll = (getStatsigExperimentResource("casting_playback_preroll_skip", "casting_playback_preroll_skip_v1").enabled = false)
      else if fetchPreroll = true AND playNowPos > 0
        ' Below block is needed for resume_playback_preroll_strategy_v1 experiment.
        prerollFetchStrategy = getStatsigExperimentResource("roku_player_improvement", "resume_playback_preroll_strategy_v1", true).strategy

        if prerollFetchStrategy = "resume_ad_break_previous_cue_or_zero"
          m.top.adPosition = getPreviousCuepointBeforeNowPos(cuepoints, playNowPos)
        else if prerollFetchStrategy = "resume_ad_break_at_zero"
          m.top.adPosition = 0
        else if prerollFetchStrategy = "resume_skip_preroll"
          fetchPreroll = false
        end if
      end if

      if fetchPreroll = true
        getStatsigExperimentResource("roku_dynamic_ad_load", "roku_dynamic_ad_load_v1")

        updatePlayerLogLib(m.playerLogLib, "setAdType", "preroll")

        ' Check whether VideoPlayerScreen has prefetched / in-flight preroll (preview warm can leave "fetching")
        if m.top.adState = "adsPending"
          tubiLog("VideoPlayer: Using pre-fetched preroll ads from preview")

          ' Ads are already fetched and ready - play them immediately
          showAdBreak()
          m.showRatings = true
        else if m.top.adState = "fetching" ' Edge case: occurs when an ad fetch is in progress on the home screen preview and the user presses the play button
          tubiLog("VideoPlayer: In-flight preroll from preview warm; starting content; will ignore adsPending and log preloadAdMissed")
          m.ignorePreviewWarmPrerollOnAdsPending = true
          updatePlayerLogLib(m.playerLogLib, "setFirstFrameForContentStart")
          m.Video.control = "play"
          setInitialCCAndAudioTracks()
        else
          tubiLog("VideoPlayer: Fetching preroll ads")
          ' Start pre-roll fetch
          m.top.adControl = "preroll"
        end if

      else
        updatePlayerLogLib(m.playerLogLib, "setFirstFrameForContentStart")
        m.Video.control = "play"
        setInitialCCAndAudioTracks()
      end if

    else
      updatePlayerLogLib(m.playerLogLib, "setFirstFrameForContentStart")
      m.Video.control = "play"
      setInitialCCAndAudioTracks()
    end if

    m.shouldFireStartVideoEvent = true
  end if

End Function


Function logPreviewWarmAdMissed() as Void
  content = m.top.content
  if content = invalid OR content.id = invalid
    return
  end if

  adCount = 0
  totalAdDurationMs = 0
  if isAA(m.top.filledAdData) = true
    if isNumber(m.top.filledAdData.adCount) = true
      adCount = Int(m.top.filledAdData.adCount)
    end if
    if isNumber(m.top.filledAdData.totalAdsDuration) = true
      totalAdDurationMs = Int(m.top.filledAdData.totalAdsDuration * 1000)
    end if
  end if

  logPayload = {
    preRequestFrom: "autoplay"
    content_id: content.id.toStr()
    adCount: adCount
    isSeries: (content.type = m.constants.ui.contentTypes.series)
    totalAdDuration: totalAdDurationMs
  }
  logInfo(FormatJson(logPayload), "adInfo", "preloadAdMissed")
End Function


Function getPreviousCuepointBeforeNowPos(cuepoints, nowPos) as Float
  best = invalid

  if cuepoints = invalid OR type(cuepoints) <> "roArray"
    return 0
  end if

  for each cuepoint in cuepoints
    if isNumber(cuepoint) = true AND cuepoint < nowPos
      if best = invalid OR cuepoint > best
        best = cuepoint
      end if
    end if
  end for

  if best = invalid
    return 0
  end if

  return best
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
  ' Determine if subtitle selection overlay should be shown
  ' This also fires the exposure event for both variant and control groups
  m.showSubtitleSelection = shouldShowSubtitleSelectionOverlay()

  ' Only populate subtitle selection overlay if we're going to show it
  if m.showSubtitleSelection = true
    m.subtitleSelectionOverlay.availableSubtitleTracks = m.Video.availableSubtitleTracks
    m.subtitleSelectionOverlay.currentSubtitleTrack = m.Video.subtitleTrack
    m.subtitleSelectionOverlay.globalCaptionMode = m.Video.globalCaptionMode
  end if
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
  logDebug("VideoPlayer.onContentChange")
  stopVideo()

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
    updateTransportButtons(m.top.content)
  end if

End Function


Function onControlChange()
  control = m.top.control
  logDebug("VideoPlayer.onControlChange " + control)
  updatePlayerLogLib(m.playerLogLib, "setVideoControl", control)

  if control = "play"
    content = m.top.content
    if content <> invalid
      playerLoadTime = m.top.loadTime
      updatePlayerLogLib(m.playerLogLib, "setPlayerInitialization", playerLoadTime)
      prepareToStartVideo(content)
      updatePlayerLogLib(m.playerLogLib, "setPlayerSetupEndTime")
      updatePlayerLogLib(m.playerLogLib, "setLastStartStep", "START_LOAD")
      updatePlayerLogLib(m.playerLogLib, "setPlayerStage", "READY")
      updatePlayerLogLib(m.playerLogLib, "setPlaybackSource", m.top.playbackSource)
      requestScrubberShowcase(content.id)
      playContent()
    end if

  else if control = "stop" then
    stopAdsPlayback()
    cancelReplayCaptions()
    clearSkipCuepointsButtonAndTimer()

    adState = m.top.adState

    if m.isMissedAdEventSent = false AND (adState = "adsClosed" OR adState = "adsPlaying" OR adState = "fetching" OR adState = "adsPending")
      if m.top.goToNext = true
        reason = "autoPlay"
      else if adState = "fetching"
        reason = "exitBeforeResponse"
      else 'adsClosed OR adsPlaying OR adsPending
        if m.adBufferingBeforeStart = true
          reason = "exitBeforePlayback"
        else
          reason = "exitDuringPlayback"
        end if
      end if

      sendAdMissedEvent(reason)
      m.isMissedAdEventSent = true

      'Reset filledAdData to prevent it from being used for future events.
      m.filledAdData = {}
    end if

    fireBrowseWhileWatchingPlaybackSessionEndEvent()

    ' Only send cumulativeDecoderStats if enabled
    if m.isDecoderStatsEnabled = true
      updatePlayerLogLib(m.playerLogLib, "setCumulativeDecoderStats", m.cumulativeDecoderStats)
    end if

    updatePlayerLogLib(m.playerLogLib, "fireQualityOfServiceEvent", m.adImpressionMap)
    m.adImpressionMap = { "0": 0, "1": 0, "2": 0, "3": 0, "4": 0 } 'reset adImpressionMap after sending QualityOfService event

    ' Reset isDecoderStatsEnabled
    if m.isDecoderStatsEnabled = true
      m.cumulativeDecoderStats = {
        renderCount: 0,
        repeatCount: 0,
        frameDropCount: 0,
        streamErrorCount: 0
      }
      m.lastRenderCount = 0
    end if

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


' Occurs when the retry timer fires (network error retry with same resource)
Function onRetryTimerFired()
  cleanupRetryTimer()
  m.retryConfig.isRetrying = false

  ' QA DEBUG LOG
  logDebug("RETRY_TEST: Attempting retry " + m.retryConfig.currentRetryCount.toStr() + " of " + m.retryConfig.network.maxRetries.toStr())

  updatePlayerLogLib(m.playerLogLib, "setRetryCount", 1)
  ' RETRY: Play the same content again without advancing codec/DRM
  playContent()
End Function


' Occurs when the fallback timer fires (codec/DRM fallback with different resource)
' This is used to advance the codec on the content in the case where the codec is not supported.
Function onFallbackTimerFired()
  cleanupFallbackTimer()
  m.retryConfig.isRetrying = false

  ' FALLBACK: Advance to next codec/DRM resource
  if isNode(m.Video) AND m.Video.errorCode = -5 ' Media error; the media format is unknown or unsupported
    advanceCodecOnContent(m.Video.content)
  else
    advanceDrmOnContent(m.Video.content)
  end if
  playContent()
End Function


' Fetches scrubber showcase from the play path before playContent(), and again after imp pixels fire (see fireScrubberShowcaseImpPixels).
Function requestScrubberShowcase(contentId) as Void
  if isNonEmptyString(contentId) = true
    logDebug("VideoPlayer.requestScrubberShowcase for contentId: " + contentId)
    m.top.requestVideoPlayerScrubberShowcase = true
  end if
End Function


'Occurs when m.Video.state changes (not when m.top.state changes)
Function onVideoStateChange(msg)
  logDebug("VideoPlayer.onVideoStateChange " + msg.GetData())
  state = msg.GetData()

  updatePlayerLogLib(m.playerLogLib, "setVideoState", state)

  if m.shouldFireStartVideoEvent = true AND (state = "playing" OR state = "error")
    ' Covers a case where we only have one audio track but that is non english.
    if isNonEmptyString(m.currentAudioLanguage) = false AND isNonEmptyArray(m.Video.availableAudioTracks) = true AND isNonEmptyString(m.Video.availableAudioTracks[0].language) = true
      m.currentAudioLanguage = m.tubiTrackingInfo.getLanguageCode(m.Video.availableAudioTracks[0].language)
    end if
    m.shouldFireStartVideoEvent = false
    fireStartVideoOrTrailerEvent()

    if state = "playing"
      if m.isBrandedScrubberEnabled = true AND m.top.videoPlayerScrubberShowcaseResponse <> invalid AND contentHasSkipCuepoints() = false
        showTransport()
        showBrowseWhileWatching()
      end if
    end if

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

  if state = "finished" AND m.VideoState = "play" AND m.retryConfig.isRetrying = false
    if m.shouldRetryPlayback = true
      m.retryConfig.isRetrying = true

      ' Video player always changes state to "finished" after reaching a state of "error"
      ' Wait until the "finished" state to retry in order to prevent race conditions
      m.shouldRetryPlayback = false

      ' Preserve playback position for retry
      if m.Video.content <> invalid AND m.playerPosition >= 0
        m.Video.content.nowPos = m.playerPosition
      end if

      timerDelay = 0.5
      errorCode = m.retryConfig.lastErrorCode

      if isNetworkRetryableError(errorCode, m.retryConfig)
        retryConfigType = m.retryConfig.network

        if retryConfigType <> invalid
          retryDelayCount = retryConfigType.delays.Count()
          delayIndex = m.retryConfig.currentRetryCount - 1

          if delayIndex >= 0 AND delayIndex < retryDelayCount
            timerDelay = retryConfigType.delays[delayIndex]
          else if retryConfigType.delays.Count() > 0
            timerDelay = retryConfigType.delays[retryDelayCount - 1]
          end if
        end if
      end if

      ' Start retry timer with exponential backoff delay
      startRetryTimer(timerDelay)

      ' Handle FALLBACK: Different resource (codec/DRM change) with immediate execution
    else if m.didAdvanceDrm = true
      m.retryConfig.isRetrying = true

      ' Video player always changes state to "finished" after reaching a state of "error"
      ' Wait until the "finished" state to play the next available stream
      m.didAdvanceDrm = false

      ' Preserve playback position for fallback
      if m.Video.content <> invalid AND m.playerPosition >= 0
        m.Video.content.nowPos = m.playerPosition
      end if

      ' Start fallback timer with minimal delay (just to move to next frame)
      startFallbackTimer(0.01)

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
  else if state = "error" AND m.retryConfig.isRetrying = false
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

      ' Fire exposure event for retry experiment (tracks both control and variant) if the error code is -1 or -2 or -3
      ' This should be called on every playback error to properly track experiment exposure
      if errorCode = -1 OR errorCode = -2 OR errorCode = -3
        getStatsigExperimentResource("roku_player_improvement", "roku_player_retry_network_errors_v1", true)
      end if

      ' Retry logic with exponential backoff for network errors (experiment gated)
      handlePlaybackError(content, errorCode)
    end if

    contentErrorInfo = {}
    contentErrorInfo["error_code"] = m.Video.errorCode
    contentErrorInfo["error_details"] = m.Video.errorMsg

    ' Error is fatal if neither retry nor fallback is available
    if m.shouldRetryPlayback = false AND m.didAdvanceDrm = false
      isFatal = true
    else
      isFatal = false
    end if

    contentErrorInfo["fatal"] = isFatal
    updatePlayerLogLib(m.playerLogLib, "fireContentErrorEvent", contentErrorInfo)

    ' Show error modal only if it's a fatal error
    if m.shouldRetryPlayback = false AND m.didAdvanceDrm = false
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
    if m.UpNext.opacity > 0 AND m.Video.width <> 1920
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
    ' Reset retry counter on successful playback recovery
    if m.isRetryExperimentEnabled = true AND m.retryConfig.currentRetryCount > 0
      resetRetryConfig()
    end if

    if m.showRatings = true AND m.ratingOverlay.opacity = 0.0 AND m.AdHeadsUp.visible = false
      m.showRatings = false
      showRatingOverlay()
    end if

    ' Show subtitle selection overlay only when playback begins (first transition to playing), not on every pause/resume
    if m.hasShownSubtitleOverlayForCurrentPlayback = false AND m.showSubtitleSelection = true AND contentHasSkipCuepoints() = false
      showSubtitleSelectionOverlay()
      m.hasShownSubtitleOverlayForCurrentPlayback = true
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

  'return true
End Function


'''''''''''''''''''''''''
' onVideoPositionChange
'
' The notificationInterval and analyticsInterval are not necessarily equal or evenly divisible
' so we check the time passage before we send playProgress events
Function onVideoPositionChange(msg) as Void
  'Early exit for stopped state
  if m.VideoState = "stop"
    return
  end if

  topRef = m.top
  content = topRef.content
  adState = topRef.adState
  constants = m.constants

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
  updatePlayerLogLib(m.playerLogLib, "setVideoPosition", position)

  ' protects against video positions being updated after we've told the player to pause
  if m.VideoState = "play"
    updatePlayerPosition() 'updates m.playerPosition with m.Video.position
    m.ratingInterval = m.ratingInterval + m.Video.notificationInterval
  end if

  ' show the TV Rating/Descriptors every hour
  if m.ratingInterval >= m.constants.player.ratingDisplayInterval AND m.ratingOverlay.opacity = 0.0 AND m.AdHeadsUp.visible = false
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

  ' User history
  ' NOTE: historyPosition should not be set near an ad break due to race condition where RAF being
  ' invoked will cause the AuthTask thread to get stuck, never completing and staying in a "run"
  ' state perpetually.
  if (m.playerPosition > m.lastsavedPosition + m.historyInterval1Min OR m.playerPosition < m.lastsavedPosition - m.historyInterval1Min) AND adState <> "adsPending"

    if topRef.isTrailer = false AND isLoggedInUser() = true AND (content.type = constants.ui.contentTypes.video OR content.type = constants.ui.contentTypes.sportsEvent)

      ' update history when interval reaches 3 minutes
      if m.playerPosition > m.lastsavedPosition + constants.player.historyFrequency3Mins
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

        if topRef.content.parentType = "series"
          '//Make sure the upNext component is located in the original layer
          m.UpNextParent.insertChild(m.UpNext, 0)
        else
          '//Minimize the movie player if this is a movie
          topRef.insertChild(m.UpNext, 0)
          nVideoMinimizedTranslation = m.MinimizedAssets.translation
          resizeToLocation(m.Video, 640, 360, nVideoMinimizedTranslation, .5) ' Resize the video player to a smaller size for the UpNext screen
          m.RemainingMinimizedGroup.opacity = 0
          fade(m.RemainingMinimizedGroup, "in", 0.5, 0.5)
          updateMinimizedTimes()
          m.RemainingMinimizedGroup.visible = true
          m.VideoBorder.width = 640
          m.VideoBorder.height = 360
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

    if m.playerPosition + constants.player.fetchNextDuration >= content.creditCuePoints.postlude
      topRef.upNextCuepointReached = true
    end if
  end if

  'set the content, focus to SkipCuepoints and send exposure event when Skip Intro/recap/early credit cue points available
  if content <> invalid AND content.creditCuePoints <> invalid
    if isSkipIntroCuePointsReached(content.creditCuePoints)
      'implement intro
      if canSkipCuepointsButtonBeShown(constants.player.skipCuepointsButtonTypes.intro, playProgressOk)
        m.cuePointsHistory[constants.player.skipCuepointsButtonTypes.intro] = true
        skipCuepointsText = getTranslation("skipIntro_Player")
        setSkipCuepointsButtonTextAndTimer(skipCuepointsText, constants.player.skipCuepointsButtonTypes.intro)
      end if
    else if isSkipRecapCuePointsReached(content.creditCuePoints)
      'Implement recap
      if canSkipCuepointsButtonBeShown(constants.player.skipCuepointsButtonTypes.recap, playProgressOk)
        m.cuePointsHistory[constants.player.skipCuepointsButtonTypes.recap] = true
        skipRecapText = getTranslation("skipRecap_Player")
        setSkipCuepointsButtonTextAndTimer(skipRecapText, constants.player.skipCuepointsButtonTypes.recap)
      end if
    else if isSkipEarlyCreditCuePointsReached(content.creditCuePoints)
      'Implement Early credits
      if canSkipCuepointsButtonBeShown(constants.player.skipCuepointsButtonTypes.earlyCredits, playProgressOk)
        m.cuePointsHistory[constants.player.skipCuepointsButtonTypes.earlyCredits] = true
        skipEarlyCredits = getTranslation("skipEarlyCredits_Player")
        setSkipCuepointsButtonTextAndTimer(skipEarlyCredits, constants.player.skipCuepointsButtonTypes.earlyCredits)
      end if
    else if getSkipCuepointsButtonTitle() <> ""
      clearSkipCuepointsButtonAndTimer()
    end if
  end if

  'Advertisements
  if topRef.enableAds = true AND m.midrolls.count() > 0 then
    m.AdHeadsUp.visible = false ' default to AdHeadsUp being off; this will catch ff, replay, rew during the countdown

    ' Initialize variables
    isCuepointPrefetchTimeReached = false
    potentialCuepoint = -1

    ' Fetch midroll ads early only if ads are neither pending nor currently fetching.
    if (adState <> "adsPending" AND adState <> "fetching")
      currentPosition = m.playerPosition
      prefetchCuepoint = currentPosition + m.adPrefetchTime

      if m.isAlignAdRequestExposureFired = false
        ' Determine if we should fire exposure: when timeToCuepoint is within 15s of m.adPrefetchTimeUsedForExposure
        for each cuepointStr in m.midrolls
          cuepoint = val(cuepointStr)
          timeToCuepoint = cuepoint - currentPosition
          if timeToCuepoint > 0 AND timeToCuepoint <= m.adPrefetchTimeUsedForExposure
            ' Fire exposure event if needed and not already fired
            getStatsigExperimentResource("roku_player_improvement", "roku_player_align_ad_request_cuepoint_v3")
            m.isAlignAdRequestExposureFired = true
            exit for
          end if
        end for
      end if

      ' Check if we're at the exact prefetch time boundary for a cuepoint
      if m.midrolls[strI(prefetchCuepoint)] = true
        isCuepointPrefetchTimeReached = true
        potentialCuepoint = prefetchCuepoint
      else
        ' Check if any cuepoint falls within the window (0 to prefetchTime)
        for each cuepointStr in m.midrolls
          cuepoint = val(cuepointStr)
          timeToCuepoint = cuepoint - currentPosition

          if timeToCuepoint > 0 AND timeToCuepoint < m.adPrefetchTime
            ' Request ads within window only if requestWithinWindow = true
            ' Skip if cooldown is active (prevents re-fetch on resume after ad break)
            if m.alignAdRequestWithinWindow = true AND m.adFetchCooldown = false
              isCuepointPrefetchTimeReached = true
              potentialCuepoint = cuepoint
            end if
            exit for
          end if
        end for
      end if


    end if

    ' Fetch midroll ads if conditions are met
    if isCuepointPrefetchTimeReached = true AND m.UpNext.opacity = 0 AND potentialCuepoint > 0
      getStatsigExperimentResource("roku_dynamic_ad_load", "roku_dynamic_ad_load_v1")

      m.top.adPosition = potentialCuepoint
      m.top.adControl = "midroll"
      updatePlayerLogLib(m.playerLogLib, "setAdType", "midroll")
    end if

    ' show the ads countdown if appropriate (show if ads are available and within adHeadsUpTime)
    adPosition = topRef.adPosition
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
    if adState = "adsPending" AND m.isMissedAdEventSent = false AND Int(m.playerPosition) > Int(m.top.adPosition)

      sendAdMissedEvent("exitAfterCuePointPassed")
      m.isMissedAdEventSent = true

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
  seconds = strI(cuepoint - m.playerPosition).trim()
  m.AdHeadsUpText.text = getTranslation("videoPlayer_adHeadsUp", { seconds: seconds })
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

  'When ads are pending or fetching, reset flags to track missed ad events and mark buffering phase before ad starts.
  'When ads are completed or no ads available, mark that no missed ad event needs to be sent.
  if adState = "adsPending" OR adState = "fetching"
    m.isMissedAdEventSent = false
    m.adBufferingBeforeStart = true
  else if adState = "adsCompleted" OR adState = "noAds"
    m.isMissedAdEventSent = true
  end if

  logDebug("VideoPlayer.onAdStateChange adState = " + adState + " VideoState = " + m.VideoState + " Video.State = " + m.Video.state)
  if adState = "ready"
    m.top.adState = "init"
    if m.top.adControl <> ""
      ' There is a race condition that can occur during deeplinks such that m.top.adControl can be set before the adShim is listening
      ' which results in a ad/video loading screen that never loads. Reset the ad control once the ad state is in init if this is the case
      ' to fix the issue.
      m.top.adControl = m.top.adControl
    end if
  else if m.ignorePreviewWarmPrerollOnAdsPending = true AND m.top.visible = true AND adState = "adsPending" AND (m.top.adControl = "preroll" OR m.top.adControl = "seek") AND m.top.enableAds = true
    tubiLog("VideoPlayer: Discarding preview-warm preroll (adsPending); user already playing content")
    logPreviewWarmAdMissed()
    m.ignorePreviewWarmPrerollOnAdsPending = false
    m.isMissedAdEventSent = true
    m.adBufferingBeforeStart = false
    m.top.adControl = "stop"
  else if m.top.visible = true AND adState = "adsPending" AND (m.top.adControl = "preroll" OR m.top.adControl = "seek") AND m.top.enableAds = true then
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
      ' Start cooldown timer only for requestWithinWindow (Variant 2) to prevent re-fetch on resume
      ' Timer starts BEFORE video resumes so the cooldown is active when position callback fires
      if m.alignAdRequestWithinWindow = true
        cleanupAdFetchCooldownTimer()
        startAdFetchCooldownTimer()
      end if

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
    logDebug("VideoPlayer.onSpritesReceived")

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
    logDebug("VideoPlayer.onUpNextContentSelected")
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


Function cancelReplayCaptions()
  if m.video.globalCaptionMode = "On" AND m.replayCaptionEnd <> 0
    logDebug("Turning off replay captions")
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

  ' Clean up retry and fallback timers to prevent them from firing during ad breaks
  cleanupFallbackTimer()
  cleanupRetryTimer()
  resetRetryConfig()

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
    if isFirmwareOk = true AND getStatsigExperimentResource("roku_async_stop", "roku_async_stop_v6", true).enabled = true then
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


' Updates the content node's url and httpHeaders fields with the videoResource info indicated by the index value
'
' @contentNode: roSGNode, a TubiContentNode
' @resource: assocarray, contains manifest details
' @videoResourceIndex: intarray, [0] -> codexIndex & [1] -> drmIndex
Function setDrmOnContent(contentNode, resource, videoResourceIndex)
  logDebug("VideoPlayer.setDrmOnContent")

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
    if resource.type = m.constants.player.drmTypes.dashWidevine OR resource.type = m.constants.player.drmTypes.hlsv6Widevine
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
  m.brandingLogo.opacity = 0
  m.subtitleSelectionOverlay.hide = true
  m.showSubtitleSelection = false
  m.pendingSubtitleOverlayOnHudClose = false

  cleanupFallbackTimer()
  cleanupRetryTimer()
  resetRetryConfig()

  m.shouldRetryPlayback = false
  m.didAdvanceDrm = false

  if content <> invalid
    m.top.adPosition = content.nowPos
    updateVideoPlayerState(content)
  end if

  resetBrandedScrubberShowcaseState()
  m.top.videoPlayerScrubberShowcaseResponse = invalid

  m.isPauseAdReqInProgress = false
  m.isPixelFiredForCurrentPauseAd = true
  m.lastFiredPixelType = ""

  m.ignorePreviewWarmPrerollOnAdsPending = false

  ' Keep ad shim state when a preroll request is in flight or already returned (see onAdStateChange / playContent)
  if m.top.adState <> "adsPending" AND m.top.adState <> "fetching"
    m.top.adState = "init"
  end if

  m.top.upNextContentToAutoplay = invalid
  m.shouldShowUpNext = true
  m.UpNext.resetContent = true

  resetVideoPlayerBackToOriginalPosition()
  setFocusToPlaybackControl()

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
  logDebug("VideoPlayer.stopAdsPlayback")

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
  logDebug("VideoPlayer.stopVideo")

  'unObserveClosedCaptionAndAudioTrack is required to prevent callbacks for the globalCaptionMode, subtitle, and audio track fields when user exits player or changes the video content
  unObserveClosedCaptionAndAudioTrack()

  ' Clean up retry and fallback timers to prevent them from firing after video is stopped
  cleanupFallbackTimer()
  cleanupRetryTimer()
  resetRetryConfig()

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
      getStatsigExperimentResource("roku_async_stop", "roku_async_stop_v6", true)
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


' Resting translation for the transport EnhancedButtonList (parent positioning only, no in-list scroll).
' When skip-cuepoints is visible the bar is shifted left; otherwise uses m.TransportButtonsXTranslation.
Function getTransportButtonsRestingTranslation() as Object
  y = 0
  if m.TransportButtons <> invalid
    t = m.TransportButtons.translation
    if isNonEmptyArray(t) = true
      y = t[1]
    end if
  end if
  if m.skipCuepointsButton <> invalid AND m.skipCuepointsButton.visible = true
    width = m.skipCuepointsButton.boundingRect().width + 12
    return [m.TransportButtonsXTranslation - width, y]
  end if
  return [m.TransportButtonsXTranslation, y]
End Function


Function updateTransportButtons(content) as Void
  if type(content) <> "roSGNode" then return

  restingTranslation = getTransportButtonsRestingTranslation()
  if restingTranslation <> invalid AND m.TransportButtons <> invalid
    m.TransportButtons.translationOverride = restingTranslation
  end if

  ' Set list styling before assigning buttons — onButtonsChange/createButton reads these synchronously.
  m.TransportButtons.buttonBackgroundUri = "pkg:/images/pill_top_nav_$$RES$$.9.png"
  m.TransportButtons.buttonSpacing = [12]
  m.TransportButtons.buttonHeight = 72
  m.TransportButtons.padding = 18

  updateSkipTrailerTransportButton(false, "")
  isComingSoon = isComingSoonContent(content)

  m.ProgressBar.highlightPointer = true

  m.HUD.removeChild(m.SkipTrailerButton)

  if content.isTrailer = true
    m.Transport.translation = [0, 783]
    m.thumbnailMaxYOffset = 870
    if isComingSoon = false
      trailerTitle = ""
      if content.type = "series"
        trailerTitle = getTranslation("videoPlayer_button_watchSeries")
      else
        trailerTitle = getTranslation("videoPlayer_button_watchMovie")
      end if
      updateSkipTrailerTransportButton(true, trailerTitle)

      'Thumbnail should be placed as the last child of the HUD component so that transport buttons or components do not overlay it.
      m.HUD.insertChild(m.SkipTrailerButton, m.HUD.getChildCount() - 1)
    end if

    m.TransportButtons.buttons = [transportIconButtonFields("StartButton", getTranslation("screenDetails_button_startOver"), "pkg:/images/icon-resume.webp", false)]
  else
    m.Transport.translation = [0, 744]
    m.thumbnailMaxYOffset = 825

    specs = [transportIconButtonFields("StartButton", getTranslation("screenDetails_button_startOver"), "pkg:/images/icon-resume.webp", false)]

    if content.parentType = "series"
      specs.push(transportIconButtonFields("EndButton", getTranslation("videoPlayer_button_nextEpisode"), "pkg:/images/transport/sgplayer/icon-to-end.webp", false))
    end if

    if isVideoCcOrAudioAvailable() = true
      specs.push(transportIconButtonFields("closedCaptionAudioButton", getTranslation("videoPlayer_button_audio_subtitles"), getClosedCaptionTransportIconUri(), false))
    end if

    if showSendFeedbackInTransport() = true
      specs.push(transportIconButtonFields("sendFeedBackButton", getTranslation("send_feedback_overlay_title"), "pkg:/images/transport/sgplayer/icon-help.webp", false))
    end if

    m.TransportButtons.buttons = specs
  end if

  cacheTransportButtonRefsFromTransportList()

  m.TitleGroup.translation = [m.constants.ui.translations.player.marginX, 0]
End Function


' Wires transport EnhancedButtonList observer and skip-trailer layout.
Function setupTransportButtons() as Void
  m.TransportButtons.observeFieldScoped("buttonFocused", "onTransportButtonFocused")
  m.TransportButtons.observeFieldScoped("buttonSelected", "onTransportButtonSelected")
  m.SkipTrailerButton.translation = [m.marginX, m.SkipTrailerButton.translation[1]]
End Function


Function primeTransportButtonList() as Void
  content = m.top.content
  if content = invalid
    content = createTransportButtonsPlaceholderContent()
  end if
  updateTransportButtons(content)
End Function


Function createTransportButtonsPlaceholderContent() as Object
  node = CreateObject("roSGNode", "TubiContentNode")
  node.isTrailer = false
  node.parentType = ""
  node.type = "movie"
  return node
End Function


Function cacheTransportButtonRefsFromTransportList() as Void
  m.StartButton = m.TransportButtons.findNode("StartButton")
  m.EndButton = m.TransportButtons.findNode("EndButton")
  m.closedCaptionAudioButton = m.TransportButtons.findNode("closedCaptionAudioButton")
  m.sendFeedBackButton = m.TransportButtons.findNode("sendFeedBackButton")
End Function


Function transportIconButtonFields(id as String, text as String, iconUrl as String, disabled as Boolean) as Object
  return {
    id: id
    title: text
    iconUrl: iconUrl
    disabled: disabled
    showUnfocusedButtonBackground: true
  }
End Function


Function isVideoCcOrAudioAvailable() as Boolean
  if m.Video = invalid then return false
  return m.Video.availableAudioTracks.Count() > 1 OR m.Video.availableSubtitleTracks.Count() > 0
End Function


Function showSendFeedbackInTransport() as Boolean
  return m.top.isTrailer = false AND m.top.appMode <> "KIDS_MODE"
End Function


Function getClosedCaptionTransportIconUri() as String
  captionMode = "Off"
  if m.Video <> invalid AND m.Video.globalCaptionMode <> invalid
    captionMode = m.Video.globalCaptionMode
  end if
  if captionMode = "Off"
    return "pkg:/images/transport/sgplayer/icon-subtitles.webp"
  end if
  return "pkg:/images/transport/sgplayer/icon-subtitles-enabled.webp"
End Function


Function onTransportButtonFocused(msg as Object) as Void
  m.lastButtonPressPos = m.playerPosition
  data = msg.getData()
  if data <> invalid
    if data.button <> invalid
      m.focusedNode = data.button
    end if
    if isNonEmptyString(data.id)
      sayFocusedButtonAudioGuide(data.id)
    end if
  end if
End Function


Function onTransportButtonSelected(msg as Object) as Void
  data = msg.getData()
  if data = invalid OR data.id = invalid OR data.id = "" then return
  dispatchTransportButtonAction(data.id)
End Function


Function updateSkipTrailerTransportButton(enabled as Boolean, title as String) as Void
  if m.SkipTrailerButton = invalid then return

  buttonContent = CreateObject("roSGNode", "ContentNode")
  buttonContent.update({
    id: "SkipTrailerTextIconButton"
    title: title
    iconUrl: "pkg:/images/transport/sgplayer/icon-movie-series.webp"
    isPrimaryButton: true
    disabled: (enabled <> true)
  }, true)

  m.SkipTrailerButton.itemContent = buttonContent
End Function


Function initSkipTrailerEnhancedButton() as Void
  updateSkipTrailerTransportButton(false, "")
End Function


Function initSkipCuepointsEnhancedButton() as Void
  if m.skipCuepointsButton = invalid then return

  buttonContent = CreateObject("roSGNode", "ContentNode")
  buttonContent.update({
    id: "skipCuepointsTextIconButton"
    title: ""
    iconUrl: "pkg:/images/transport/sgplayer/icon-skip-intro-nonfocus.webp"
    isPrimaryButton: true
  }, true)

  m.skipCuepointsButton.itemContent = buttonContent
End Function


Function getSkipCuepointsButtonTitle() as String
  if m.skipCuepointsButton = invalid OR m.skipCuepointsButton.itemContent = invalid then return ""
  t = m.skipCuepointsButton.itemContent.title
  if t = invalid then return ""
  return t
End Function


Function setSkipCuepointsButtonTitle(title as String) as Void
  if m.skipCuepointsButton = invalid OR m.skipCuepointsButton.itemContent = invalid then return
  m.skipCuepointsButton.itemContent.update({ title: title }, true)
End Function


Function onSkipCuepointsButtonWasSelected(msg as Object) as Void
  if msg.getData() <> true then return
  m.skipCuepointsButton.wasSelected = false
  onSkipCuepointsButtonSelected()
End Function


Function onSkipTrailerButtonWasSelected(msg as Object) as Void
  if msg.getData() <> true then return
  m.SkipTrailerButton.wasSelected = false
  handleSkipTrailer()
End Function


' advanceDrmOnContent function gets triggered when player error occurs due to drm
' @contentNode: roSGNode, a TubiContentNode
Function advanceDrmOnContent(contentNode)
  logDebug("VideoPlayer.advanceDrmOnContent")

  if contentNode = invalid then return false

  videoResources = contentNode.videoResources
  currentVideoResourceIndex = contentNode.currentVideoResourceIndex
  if videoResources = invalid OR currentVideoResourceIndex = invalid OR currentVideoResourceIndex.Count() < 2
    return false
  end if

  currentCodecIndex = currentVideoResourceIndex[0]
  currentDrmIndex = currentVideoResourceIndex[1]
  if videoResources[currentCodecIndex] = invalid then return false

  currentResource = videoResources[currentCodecIndex][currentDrmIndex]
  nextCodecIndex = currentCodecIndex
  nextDrmIndex = currentDrmIndex + 1
  nextResource = videoResources[currentCodecIndex][nextDrmIndex]

  if nextResource = invalid
    nextCodecIndex = currentCodecIndex + 1
    nextDrmIndex = 0
    nextResource = videoResources[nextCodecIndex]
    if nextResource <> invalid then nextResource = nextResource[nextDrmIndex]
  end if

  if nextResource = invalid then return false

  if setDrmOnContent(contentNode, nextResource, [nextCodecIndex, nextDrmIndex]) = true
    sendVideoResourceFallbackToPlayerLogLib(currentResource, nextResource, "DRM")
    logError(FormatJSON({
      failed_url: removeQueryParams(currentResource.url)
      failed_drm: currentResource.type
      fallback_url: removeQueryParams(nextResource.url)
      fallback_drm: nextResource.type
      model: m.constants.deviceInfo.model
      video_id: contentNode.id
    }), "videoLoad", "drm-fallback", 0.1)
    return true
  end if

  return false
End Function


' advanceCodecOnContent function gets triggered when player error occurs due to codec capability
' @contentNode: roSGNode, a TubiContentNode
Function advanceCodecOnContent(contentNode)
  logDebug("VideoPlayer.advanceCodecOnContent")

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
            failed_url: removeQueryParams(currentResource.url)
            failed_codec: currentResource.codec
            fallback_url: removeQueryParams(nextResource.url)
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
  logDebug("VideoPlayer.advanceCodecOnContent")

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
  logDebug("VideoPlayer.advanceDrmOnContent")

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
      failed_url: removeQueryParams(failedResource.url)
      fallback_video_resource_type: fallbackResourceType
      fallback_video_codec_type: fallbackCodecType
      fallback_hdcp_version: fallbackHdcpversion
      fallback_url: removeQueryParams(fallbackResource.url)
    }
    updatePlayerLogLib(m.playerLogLib, "fireVideoResourceFallbackEvent", videoResourceFallback)
  end if
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


Function onDecoderStatsChange(msg)
  stats = msg.getData()

  if isAA(stats) = true
    'Added this logic to handle the reset of renderCount after seeking or resuming content.
    deltaRender = stats.renderCount - m.lastRenderCount
    if deltaRender < 0 then
      deltaRender = stats.renderCount
    end if
    m.lastRenderCount = stats.renderCount

    m.cumulativeDecoderStats.renderCount = m.cumulativeDecoderStats.renderCount + deltaRender
    m.cumulativeDecoderStats.repeatCount = stats.repeatCount
    m.cumulativeDecoderStats.frameDropCount = stats.frameDropCount
    m.cumulativeDecoderStats.streamErrorCount = stats.streamErrorCount
  end if
End Function


Function showRatingOverlay()

  content = m.Video.content

  if content <> invalid AND isNonEmptyString(content.rating) = true

    fade(m.ratingOverlay, "in", 0.6)

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


' shouldShowSubtitleSelectionOverlay determines if the subtitle selection overlay should be shown.
' Logic:
' - Only show if there are available subtitle tracks
' - Only show if roku_player_subtitle_overlay_v1 experiment is enabled
' - If user has preferredSubtitleTrack: show only once ever (persisted in registry)
' - If no preferredSubtitleTrack: show on every video
' - Fires exposure event for both variant and control groups
' @return boolean - true if overlay should be shown
Function shouldShowSubtitleSelectionOverlay() as Boolean
  ' Only show if there are available subtitle tracks
  availableTracks = m.Video.availableSubtitleTracks
  if availableTracks = invalid OR availableTracks.Count() = 0
    return false
  end if

  ' Check if there's a preferred subtitle track
  preferredSubtitleTrack = m.top.preferredSubtitleTrack
  hasPreferredSubtitleTrack = isAA(preferredSubtitleTrack) = true AND isNonEmptyString(preferredSubtitleTrack.language) = true
  hasShownOverlay = RegRead("hasShownSubtitleOverlayWithPreference", "subtitleOverlay")

  if hasPreferredSubtitleTrack = false OR hasShownOverlay <> "true"
    return true ' no preference, show every time
  else
    return false
  end if
End Function


' showSubtitleSelectionOverlay shows the subtitle selection overlay component.
' Writes registry for both treatment & control, but show overlay only for treatment.
Function showSubtitleSelectionOverlay()
  hasShownOverlay = RegRead("hasShownSubtitleOverlayWithPreference", "subtitleOverlay")

  if hasShownOverlay <> "true"
    RegWrite("hasShownSubtitleOverlayWithPreference", "true", "subtitleOverlay")
    getStatsigExperimentResource("roku_player_improvement", "roku_player_subtitle_overlay_v1", true)
  end if

  if m.isSubtitleOverlayExperimentEnabled = true
    m.subtitleSelectionOverlay.show = true
    m.focusedNode = m.subtitleSelectionOverlay
  end if
End Function


' hideSubtitleSelectionOverlay hides the subtitle selection overlay component.
' When overlay is dismissed by user (back/key) or auto-hide, focus is restored via onSubtitleSelectionOverlayBackPressed.
Function hideSubtitleSelectionOverlay()
  m.pendingSubtitleOverlayOnHudClose = false
  m.showSubtitleSelection = false
  m.subtitleSelectionOverlay.hide = true
End Function


' contentHasSkipCuepoints checks if the current video position has not yet crossed any skip cuepoints.
' @return boolean - true if there are skip cuepoints ahead that haven't been crossed, false otherwise
Function contentHasSkipCuepoints() as Boolean
  content = m.Video.content
  if content = invalid OR content.creditCuePoints = invalid
    return false
  end if

  cuePoints = content.creditCuePoints
  currentPosition = m.playerPosition

  ' Check if intro cuepoint exists and hasn't been crossed yet
  hasIntroPending = cuePoints.intro_start <> invalid AND cuePoints.intro_end <> invalid AND cuePoints.intro_start > 0 AND currentPosition < cuePoints.intro_end

  ' Check if recap cuepoint exists and hasn't been crossed yet
  hasRecapPending = cuePoints.recap_start <> invalid AND cuePoints.recap_end <> invalid AND cuePoints.recap_start > 0 AND currentPosition < cuePoints.recap_end

  return hasIntroPending OR hasRecapPending
End Function


' updateBrandingLogoVisibility manages the visibility of the branding logo group
' The branding logo should be visible when either transport controls or rating overlay is displayed
' @shouldShowBrandingLogo: boolean, true to show the logo with animation, false to hide the logo with animation
' @delay: integer, delay to start the animation
Function updateBrandingLogoVisibility(shouldShowBrandingLogo = false, delay = 0)
  if shouldShowBrandingLogo = true
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


' Applies CC/audio transport visibility from available tracks without rebuilding the transport row.
' Full rebuild (updateTransportButtons) drops all buttons, resets layout and focus, and retriggers list scroll state.
Function setCCAudioTransportBarVisibility() as Void
  shouldShow = isVideoCcOrAudioAvailable()

  if m.closedCaptionAudioButton <> invalid

    if shouldShow = true
      m.closedCaptionAudioButton.visible = true
      m.closedCaptionAudioButton.itemContent.update({
        disabled: false
        iconUrl: getClosedCaptionTransportIconUri()
      }, true)
    else
      m.closedCaptionAudioButton.visible = false
      m.closedCaptionAudioButton.itemContent.update({
        disabled: true
      }, true)
    end if

    return
  end if

  content = m.top.content
  if shouldShow = true AND content <> invalid
    if content.isTrailer = true then return

    updateTransportButtons(content)
  end if
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
    ' Real dismiss: user had the CC/audio overlay on screen. Initial track sync from the video node can
    ' set wasBackButtonSelected without the overlay being visible; ignore to keep focus on the progress bar.
    if m.isClosedCaptionAudioOverlayShowing <> true
      m.closedCaptionAndAudioSelectionOverlay.wasBackButtonSelected = false
    else
      hideClosedCaptionAudioTrackOverlay()
      hideSubtitleSelectionOverlay()

      if m.closedCaptionAudioButton <> invalid AND m.closedCaptionAudioButton.visible = true
        setFocusToComponent(m.closedCaptionAudioButton)
      end if
    end if
  end if
End Function


Function onWasBackORLeftButtonSelectedForSendFeedback(msg)
  wasBackOrLeftSelected = msg.getData()
  if wasBackOrLeftSelected = true
    hideSendFeedbackOverlay()
    if m.sendFeedBackButton <> invalid
      setFocusToComponent(m.sendFeedBackButton)
    end if
  end if
End Function


Function onTrackingEventInfoChange(msg)
  eventInfo = msg.getData()
  trackEvent(eventInfo)
End Function


' @captionMode: string, will contain the current caption mode, "On"/"Off"/"Instant replay" are the possible values
Function setAudioSubtitleTransportBarIcon(captionMode) as Void
  if m.closedCaptionAudioButton = invalid OR m.closedCaptionAudioButton.itemContent = invalid then return

  iconUri = "pkg:/images/transport/sgplayer/icon-subtitles.webp"
  if captionMode <> "Off"
    iconUri = "pkg:/images/transport/sgplayer/icon-subtitles-enabled.webp"
  end if

  m.closedCaptionAudioButton.itemContent.update({ iconUrl: iconUri }, true)
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


Function onRelatedItemSelected(msg)
  screen = msg.getRoSGNode()

  if screen <> invalid then
    selectedContent = screen.selectedRelatedContentItem
    if selectedContent <> invalid
      animateTransport("out")
      hideBrowseWhileWatching()
      setFocusToPlaybackControl()
      m.top.relatedContentToPlay = selectedContent
      resetTransportButtons()

      updatePlayerLogLib(m.playerLogLib, "setBrowseWhileWatchingDidConvert", true)
    end if
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
    updatePlayerLogLib(m.playerLogLib, "setTotalAdDurationInCurrentPod", adInfo)
  else if adStatus = "Start"
    m.adBufferingBeforeStart = false
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


Function onShowPlayerStatsChange(msg)
  m.showPlayerStats = msg.getData()
End Function


Function updatePlayerStatsOverlay()
  updatePlayerStatsOverlayMixin(m.constants, m.Video, m.showPlayerStats, m.playerStatsOverlay)
End Function


' Helper sub to stop and cleanup the retry timer
sub cleanupRetryTimer()
  if m.retryTimer <> invalid
    m.retryTimer.control = "stop"
    m.retryTimer.unObserveFieldScoped("fire")
  end if
end sub


' Helper sub to configure and start the retry timer with a given delay
' @timerDelay: float, the delay in seconds before the timer fires
sub startRetryTimer(timerDelay as Float)
  cleanupRetryTimer()
  m.retryTimer.duration = timerDelay
  m.retryTimer.observeFieldScoped("fire", "onRetryTimerFired")
  m.retryTimer.control = "start"
end sub


' Helper sub to stop and cleanup the fallback timer
sub cleanupFallbackTimer()
  if m.fallbackTimer <> invalid
    m.fallbackTimer.control = "stop"
    m.fallbackTimer.unObserveFieldScoped("fire")
  end if
end sub


' Helper sub to configure and start the fallback timer with a given delay
' @timerDelay: float, the delay in seconds before the timer fires
sub startFallbackTimer(timerDelay as Float)
  cleanupFallbackTimer()
  m.fallbackTimer.duration = timerDelay
  m.fallbackTimer.observeFieldScoped("fire", "onFallbackTimerFired")
  m.fallbackTimer.control = "start"
end sub


Function handlePlaybackError(content as Object, errorCode as Integer) as Void
  if m.isRetryExperimentEnabled = true
    strategy = getErrorRetryStrategy(errorCode)

    ' Try network retry if within max attempts
    if strategy = "retry_network" AND m.retryConfig.currentRetryCount < m.retryConfig.network.maxRetries
      m.retryConfig.currentRetryCount += 1
      m.retryConfig.lastErrorCode = errorCode
      m.shouldRetryPlayback = true
      return
    end if

    ' Retry exhausted or not retryable - try fallback
    resetRetryConfig()
    m.shouldRetryPlayback = false

    ' Apply fallback strategy based on error type
    if strategy = "retry_network" OR strategy = "fallback_drm"
      m.didAdvanceDrm = checkIfDRMFallbackIsAvailable(content)
    else if strategy = "fallback_codec"
      m.didAdvanceDrm = checkIfCodecFallbackIsAvailable(content)
    else
      m.didAdvanceDrm = false ' Fatal/unsupported case
    end if

  else
    ' Experiment disabled - use original fallback logic
    if errorCode = -5 ' Media error; the media format is unknown or unsupported
      m.didAdvanceDrm = checkIfCodecFallbackIsAvailable(content)
    else
      m.didAdvanceDrm = checkIfDRMFallbackIsAvailable(content)
    end if
  end if

End Function


' Helper sub to reset retry configuration state
sub resetRetryConfig()
  m.retryConfig.append({
    isRetrying: false
    currentRetryCount: 0
    lastErrorCode: 0
  })
end sub


' Helper sub to start the ad fetch cooldown timer
' This prevents re-fetching ads on resume after ad break (due to Roku frame alignment)
sub startAdFetchCooldownTimer()
  m.adFetchCooldown = true
  m.adFetchCooldownTimer.observeFieldScoped("fire", "onAdFetchCooldownTimerFired")
  m.adFetchCooldownTimer.control = "start"
end sub


' Helper sub to cleanup the ad fetch cooldown timer
sub cleanupAdFetchCooldownTimer()
  m.adFetchCooldown = false
  m.adFetchCooldownTimer.control = "stop"
  m.adFetchCooldownTimer.unObserveFieldScoped("fire")
end sub


' Callback when ad fetch cooldown timer expires
Function onAdFetchCooldownTimerFired()
  cleanupAdFetchCooldownTimer()
End Function


' onSubtitleSelectionOverlayTrackSelected handles when a subtitle track is selected from the overlay.
' Updates the video subtitle track and caption mode.
' When "Off" is selected, only globalCaptionMode is updated (subtitleTrack is not modified).
' When a track is selected, subtitleTrack is set to the actual id(trackName).
Function onSubtitleSelectionOverlayTrackSelected(msg)
  item = msg.getData()

  if item <> invalid
    m.Video.subtitleTrack = item.id
    if item.id = "Off"
      m.Video.globalCaptionMode = "Off"
      setAudioSubtitleTransportBarIcon("Off")
    else
      m.Video.globalCaptionMode = "On"
      setAudioSubtitleTransportBarIcon("On")
    end if
  end if

  setFocusToComponent(m.ProgressBar)
End Function


' onSubtitleSelectionOverlayBackPressed handles back/dismiss from subtitle overlay; restores focus to progress bar.
Function onSubtitleSelectionOverlayBackPressed(msg)
  if msg.getData() = true
    setFocusToComponent(m.ProgressBar)
  end if
End Function


' onSubtitleSelectionOverlayPlayPressed handles when the play button is pressed while overlay is shown.
' Shows transport and pauses the video.
Function onSubtitleSelectionOverlayPlayPressed(msg)
  if msg.getData() = true
    showTransport()
    pauseVideo(true, true)
  end if
End Function


' Applies scrubber showcase assets when image URI is valid; imp pixels only after the pointer image loads successfully.
Function onVideoPlayerScrubberShowcaseResponse(msg) as Void
  response = msg.getData()
  resetBrandedScrubberShowcaseState()

  if response <> invalid
    if m.isBrandedScrubberEnabled = true
      m.ProgressBar.brandedScrubberUri = response.brandedScrubberUri
    end if
    fireScrubberShowcaseExposure()
  end if

End Function


Function onBrandedScrubberImageReadyChange(msg) as Void
  m.brandedScrubberImageReady = msg.getData()

  if m.brandedScrubberImageReady = true AND m.isBrandedScrubberEnabled = true AND m.top.videoPlayerScrubberShowcaseResponse <> invalid AND m.scrubberShowcaseImpPixelFired = false AND m.HUD.opacity > 0 AND m.focusedNode.isSameNode(m.progressBar) = true
    fireScrubberShowcaseImpPixels()
  end if

End Function


Function resetBrandedScrubberShowcaseState()
  m.ProgressBar.brandedScrubberUri = ""
  m.scrubberShowcaseImpPixelFired = false
  m.top.sendScrubberShowcaseAdPixels = invalid
  m.brandedScrubberImageReady = false
End Function