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
  m._ = rodash()
  m.NodeHelpers = TubiNodeHelpers()
  m.theme = m.global.theme
  Request = TubiRequest(m.constants.settings.mode)
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)
  m.Loading = m.top.findNode("Loading")
  m.LoadingProgressBar = m.top.findNode("LoadingProgressBar")
  m.LoadingMessage = m.top.findNode("LoadingMessage")
  m.Transport = m.top.findNode("Transport")
  m.UpNext = m.top.findNode("UpNext")
  m.UpNext.observeField("contentSelected", "onUpNextContentSelected")
  m.UpNext.observeField("opacity", "onUpNextOpacityChange")
  m.UpNext.observeField("autoplayMode", "onUpNextAutolayModeChange")

  m.Video = m.top.findNode("VideoNode")  ' reference in case we change from extending Video to extending Group
  m.Video.observeField("position", "onVideoPositionChange")
  m.Video.observeField("state", "onVideoStateChange")
  m.Video.observeField("bufferingStatus", "onBufferingStatus")
  m.Video.observeField("globalCaptionMode", "onCaptionModeChange")

  m.top.observeField("updateContent", "onContentChange")
  m.top.observeField("sprites", "onSpritesReceived")
  m.top.observeField("control", "onControlChange")
  m.top.observeField("transportVoiceRequest", "handleTransportVoiceEvent")
  m.top.observeField("kidsMode", "onKidsModeChange")
  m.top.observeField("adState", "onAdStateChange")
  m.top.observeField("adProgress", "onAdProgressChange")
  m.top.observeField("displayAdLoadingMessage", "onDisplayAdLoadingMessage")

  m.logo = m.top.findNode("tubiLogo")
  m.logoKids = m.top.findNode("tubiKidsLogo")
  if m.constants.deviceInfo.language = "es"
    m.logoKids.uri = "pkg:/images/locale/es_ES/logo-kids-white-xlarge.png"
  end if

  m.ElapsedLabel = m.top.findNode("ElapsedLabel")
  m.RemainingLabel = m.top.findNode("RemainingLabel")
  m.ProgressBar = m.top.findNode("ProgressBar")
  m.Overlay = m.top.findNode("VideoOverlay")
  m.ScrubTimer = m.top.findNode("ScrubTimer")
  m.HUD = m.top.findNode("HUD")
  m.TransportGradient = m.top.findNode("TransportGradient")
  m.AdHeadsUp = m.top.findNode("AdHeadsUp")
  m.AdHeadsUpText = m.top.findNode("AdHeadsUpText")
  m.Thumbnail = m.top.findNode("Thumbnail")

  BackLabel = m.top.findNode("BackLabel")
  BackLabel.text = getTranslation("goBack_videoPlayer_controls")
  if m.constants.deviceInfo.uiResolution <> "FHD"
    '//if the display is not 1080, then adjust the BackLabel to ensure proper vertical alignment 
    BackLabel.translation = [BackLabel.translation[0], BackLabel.translation[1] + 3]
  end if

  m.AdsTask = m.top.findNode("AdsTask")
  m.AdsTask.videoPlayerNode = m.top
  m.AdsTask.control = "RUN"

  'm.VideoState is source of truth for the state of the video player for the UI
  'possible values are "play", "pause", "rew", "ffw", "stop", "refresh", "skip", "hop"
  m.VideoState = "stop"

  'm.scrubAmt is the 0-based level of scrub speed - current design allows for 0, 1, 2
  m.scrubAmt = -1
  m.maxScrub = m.constants.player.maxScrub
  m.scrubMultipliers = m.constants.player.scrubMultipliers
  m.scrubTimespan = CreateObject("roTimespan")
  ' m.positionAtJumpStart holds the state during FF/REW/Skips/Hops so we can tell if at the end of all user actions
  ' the user ended up moving forward or backwards from their original position. Also used for "seek" event tracking.
  m.positionAtJumpStart = -1
  m.playerPosition = 0

  m.lastButtonPressPos = 0
  m.transportAutoHideTime = m.constants.player.transportAutoHideTime
  m.ignoreOptionsKey = m.constants.deviceInfo.firmwareCaptionMenu
  m.bufferingInfo = invalid
  m.progressBarFocused = false

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
  m.ClosedCaption = m.TransportButtons.findNode("ClosedCaption")
  m.CCRailOn = m.TransportButtons.findNode("CCRailOn")
  m.CCRailOff = m.TransportButtons.findNode("CCRailOff")
  m.CCNipple = m.TransportButtons.findNode("CCNipple")
  m.buttonUris = m.constants.player.transportButtons
  m.focusedButtonIndex = 0
  setFocusedButton(m.PlayPauseButton)
  m.ClosedCaptionDisabled = m.top.findNode("ClosedCaptionDisabled")

  m.lastPingTime = 0
  m.lastSavedPosition = 0
  m.adPrefetchTime = 15
  m.adHeadsUpTime = 10
  m.adBreakAdvance = 0.5

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

  ' checking m.recentCuepointFetch and m.recentCuepoint prevents multiple ad calls and multiple tracking events
  ' for a single cuepoint if the position callback happens at 10.2 and 10.7 for instance
  m.recentCuepointFetch = 0
  m.recentCuepoint = 0

  m.analyticsInterval = m.constants.player.pingFrequency
  m.historyInterval = m.constants.player.historyFrequency

  'if global captions are turned on, slide the closed caption toggle to on position
  m.CCNippleOnTranslation = [89,0]
  m.CCNippleOffTranslation = [58,0]

  if m.Video.globalCaptionMode = "On"
    m.CCRailOn.opacity = 1.0
    m.CCRailOff.opacity = 0.0
    m.CCNipple.translation = m.CCNippleOnTranslation
  end if

  updateColors()

  ' set to the end position of replay if caption mode is temporarily turned on during a replay
  m.replayCaptionEnd = 0

  ' used by CC dialog
  m.ccSelections = [ 0 ]  ' modeled as an array for adding caption and audio tracks selection
  m.ccModes = [
    ' globalCaptionMode text,       Button text on software caption dialog      Dialog Subtype for analytics
    ["Off",                          "Off",                                      "off"]
    ["On",                           "On always",                                "on-always"]
    ["Instant replay",               "On replay",                                "on-replay"]
  ]

  m.thumbnailMinXOffset = 238 ' based on zeplin designs
  m.thumbnailMaxXOffset = 1920 - 238 - m.Thumbnail.width
  m.thumbnailMaxYOffset = 889

  if m.constants.deviceInfo.scaledUi = true then
    m.ProgressBar.scaledUI = m.constants.deviceInfo.scaledUi
    m.LoadingProgressBar.scaledUI = m.constants.deviceInfo.scaledUi
    m.TransportGradient.uri = "pkg:/images/playback-gradient-hd.9.png"
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
End Function


Function playContent()
  tubilog("VideoPlayer.playContent")

  ' Always reset ad state when we first start playback.  Preroll fetch will populate midrolls list
  m.top.midrolls = []
  m.recentCuepointFetch = 0
  m.recentCuepoint = 0

  ' reset the seekReferenceQueue
  m.seekReferenceQueue = []

  if m.Video.content.nowPos <> invalid and m.Video.content.nowPos >= 0
    m.playerPosition = m.Video.content.nowPos
    m.lastSavedPosition = m.Video.content.nowPos
    m.lastPingTime = m.Video.content.nowPos
    m.lastButtonPressPos = m.Video.content.nowPos
    m.seekReferenceQueue.push(m.Video.content.nowPos)
    seekToPosition(m.Video.content.nowPos)
  else
    m.lastButtonPressPos = 0
  end if

  'start_video user event analytics
  if m.top.analyticsMode = "trailer"
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
    autoPlayAutomatic = false
    autoPlayDeliberate = false
    isLiveTv = false
    isFullScreen = true
    isEmbedded = false
    if m.top.analyticsMode = "autoplay-automatic"
      autoPlayAutomatic = true
    else if m.top.analyticsMode = "autoplay-deliberate"
      autoPlayDeliberate = true
    end if

    hasSubtitles = false
    if m.Video.globalCaptionMode = "On" and m.Video.content.hasSubtitles = true
      hasSubtitles = true
    end if

    trackEvent({
      type: "start_video"
      values: {
        video_id: m.Video.content.id.toInt()
        start_position: Int(m.playerPosition * 1000)
        current_cdn: ""   'not possible for Roku client
        has_subtitles: hasSubtitles  'the video player will show subtititles at start
        is_livetv: isLiveTv
        is_embedded: isEmbedded
        is_fullscreen: isFullScreen
        from_autoplay_deliberate: autoPlayDeliberate
        from_autoplay_automatic: autoPlayAutomatic
      }
    })
  end if

  m.top.adPosition = 0
  m.VideoState = "play"
  if m.top.enableAds then
    '//Set the midrolls of the videoplayer now and set the adControl state to preroll
    if m.Video.content.cuepoints <> invalid
      m.top.midrolls = m.Video.content.cuepoints
      for each time in m.top.midrolls
        print "VideoPlayer: MIDROLL: " ; time
      end for
    end if
    ' Start pre-roll fetch
    m.top.adControl = "preroll"
  else
    m.Video.control = "play"
  end if
End Function


Function updateColors()
  m.focusedColor = m.theme.focused
  m.ProgressBar.focusColor = m.focusedColor
  m.LoadingProgressBar.focusColor = m.focusedColor
  m.LoadingProgressBar.unfocusColor = m.focusedColor
  m.CCRailOn.blendColor = m.focusedColor
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
      prepareToStartVideo(m.top.content, 0)
      playContent()
    end if

  else if m.top.control = "stop" then
    cancelReplayCaptions()
    stopVideo()

    m.UpNext.stopAutoPlayTimer = true

    'in the case where an ad break has started, but RAF does not yet have control, we want to break out of ads on back button pressed
    if m.top.adState = "fetching" or m.top.adState = "adsPending"
      m.top.adControl = "stop"
    end if
  else if m.top.control = "pause" then
    pauseVideo(false, false)
  else if m.top.control = "resume" and m.Video.state = "paused" then
    resumeFromPause(false)
  end if
End Function


'Occurs when m.Video.state changes (not when m.top.state changes)
Function onVideoStateChange(msg)
  tubiLog("VideoPlayer.onVideoStateChange " + msg.GetData())
  state = msg.GetData()

  if state = "finished" and m.VideoState = "play"
    if m.didAdvanceDrm = true
      ' video player always changes state to "finished" after reaching a state of "error"
      ' so we wait until the "finished" state is reached to play the next available stream for the video
      ' in order to prevent race conditions due to video player state changing.
      m.didAdvanceDrm = false
      playContent()
    else
      ' the video reached the end
      if m.Video.content <> invalid
        ' the video has been stopped, send a final playProgressEvent
        playProgressEvent = getPlayProgressEvent()
        if playProgressEvent <> invalid
          trackEvent(playProgressEvent)
        end if

        if m.top.analyticsMode = "trailer"
          trackEvent({
            type: "finish_trailer"
            values: {
              end_position: Int(m.playerPosition * 1000)
              video_id: m.Video.content.id.toInt()
            }
          })
        end if
      end if

      m.VideoState = "stop"

      ' setting the m.top.state field to finished triggers autoplay content to start
      ' we don't want that trigger to fire if the up next component is still visible
      if m.UpNext.opacity = 0
        m.top.state = state
      end if

    end if
  else if state = "error"
    content = m.Video.content
    errorInfo = getPlaybackErrorInfo(m.Video.position, m.Video.downloadedSegment, m.Video.streamingSegment, m.Video.streamingInfo,m.Video.errorCode, m.Video.errorMsg, content)
    tubiLog(FormatJSON(errorInfo), "error", "videoPlayback", "video-playback")
    m.top.sendYouboraError = true

    ' Set up the next DRM scheme. Playback of next DRM scheme is triggered when state = "finished",
    ' right after error state occurs.
    m.didAdvanceDrm = advanceDrmOnContent(content)
    if m.didAdvanceDrm <> true
      m.top.errorMsg = getTranslation("videoPlayer_error_playback_description")  'is used in error modal
      m.top.state = state   'triggers error modal in ContentController
    end if
  else if state = "stopped" and m.VideoState = "stop"
    ' player has stopped (not due to an ad break)
    if m.top.adState = "noads" or m.top.adState = "init"
      if m.Video.content <> invalid
        ' the video has been stopped, send a final playProgressEvent
        playProgressEvent = getPlayProgressEvent()
        if playProgressEvent <> invalid
          trackEvent(playProgressEvent)
        end if

        if m.top.analyticsMode = "trailer"
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
  else if state = "playing" and m.VideoState <> "pause"
    ' reset the last ping time to the position at which video playback is starting or re-starting (after a seek)
    ' in order to avoid race conditions in which the video position might update while the handle logic is being completed.
    m.lastPingTime = m.Video.position
    m.lastSavedPosition = m.lastSavedPosition
  end if

  ' Loading page visibility
  if state = "playing" or state = "paused"
    m.Loading.visible = false
    m.top.state = state
  else
    m.LoadingProgressBar.progress = 0
    m.Loading.visible = true
  end if
End Function


'''''''''''''''''''''''''
' onVideoPositionChange
'
' The notificationInterval and analyticsInterval are not necessarily equal or evenly divisible
' so we check the time passage before we send playProgress events
Function onVideoPositionChange()
  tubiLog("VideoPlayer.onVideoPositionChange position = " + m.Video.position.toStr())

  ' protects against video positions being updated after we've told the player to pause
  if m.VideoState = "play"
    updatePlayerPosition()  'updates m.playerPosition with m.Video.position
  end if

  playProgressOk = true
  if positionInSeekReferenceQueue(m.playerPosition, m.seekReferenceQueue) = true 'updates m.seekReferenceQueue as neccessary
    playProgressOk = false
  end if

  ' Auto hide transport
  if m.VideoState = "play" and m.HUD.opacity = 1 and m.playerPosition > m.lastButtonPressPos + m.transportAutoHideTime
    animateTransport("out")
  end if

  ' Cancel temporary captions
  if m.replayCaptionEnd <> 0 and m.playerPosition >= m.replayCaptionEnd
    cancelReplayCaptions()
  end if

  ' Analytics
  if m.playerPosition >= m.lastPingTime + m.analyticsInterval and playProgressOk = true
    playProgressEvent = getPlayProgressEvent()
    if playProgressEvent <> invalid
      m.lastPingTime = m.playerPosition
      trackEvent(playProgressEvent)
    end if
  end if

  ' User history
  ' NOTE: historyPosition should not be set near an ad break due to race condition where RAF being
  ' invoked will cause the AuthTask thread to get stuck, never completing and staying in a "run"
  ' state perpetually.
  if (m.playerPosition > m.lastsavedPosition + m.historyInterval or m.playerPosition < m.lastsavedPosition - m.historyInterval) and m.top.adState <> "adspending"
    historyPosition(m.playerPosition)
  end if

  ' Credits Cuepoint / Up Next (Autoplay)
  if m.top.content <> invalid and m.top.content.creditsCuePoint <> invalid and m.top.content.creditsCuePoint > 0
    if m.playerPosition >= m.top.content.creditsCuePoint and m.shouldShowUpNext = true
      ' Always fire history here to fix a race condition where the user has
      ' watched beyond the cuepoint but the title doesn't get removed due
      ' to no history events triggering after the cuepoint
      historyPosition(m.playerPosition + 5)
       
      if m.UpNext.content <> invalid
        animateTransport("out")
        m.UpNext.show = true
        m.UpNext.setFocus(true)
        m.shouldShowUpNext = false
        if m.top.content.id <> invalid
          trackEvent({
            type: "auto_play"
            values: {
              video_id: m.top.content.id.toInt()
              auto_play_action: "SHOW" 'AutoPlayAction enum
            }
          })
        end if
      end if
    else if m.playerPosition < m.top.content.creditsCuePoint
      m.shouldShowUpNext = true
    end if
    
    if m.playerPosition + m.constants.player.fetchNextDuration >= m.top.content.creditsCuePoint
      m.top.upNextCuepointReached = true
    end if
  end if


  'Advertisements
  if m.top.enableAds and m.top.midrolls <> invalid and m.top.midrolls.count() > 0 then
    m.AdHeadsUp.visible = false  ' default to AdHeadsUp being off; this will catch ff, replay, rew during the countdown
    for each cuepoint in m.top.midrolls

      ' attempt to fetch midroll ads
      if isAtPosition(m.playerPosition, cuepoint - m.adPrefetchTime) and m.UpNext.opacity = 0
        if cuepoint - m.adPrefetchTime <> m.recentCuepointFetch
          m.recentCuepointFetch = cuepoint - m.adPrefetchTime
          m.top.adPosition = cuepoint
          m.top.adControl = "midroll"
        end if
      end if

      ' show the ads countdown if appropriate
      if isInWindow(m.playerPosition, cuepoint, m.adHeadsUpTime) and m.top.adState = "adspending"
        if m.Overlay.opacity = 0
          ' Don't show the ad heads up when the transport/overlay is showing, since it crowds the space of the title on the overlay
          m.AdHeadsUp.visible = true
          seconds = stri(cuepoint - m.playerPosition).trim()
          m.AdHeadsUpText.text = getTranslation("videoPlayer_adHeadsUp", {seconds: seconds})
        end if
      end if

      ' Fire up the midroll
      if cuepoint > 0 and isAtPosition(m.playerPosition, cuepoint - m.adBreakAdvance) and m.UpNext.opacity = 0
        if cuepoint <> m.recentCuepoint
          m.AdHeadsUp.visible = false
          m.recentCuepoint = cuepoint
          if m.top.adState = "adspending" then
            ' Send a play_progress event before we show ads to be most accurate in case the user exits during ad playback
            playProgressEvent = getPlayProgressEvent()
            if playProgressEvent <> invalid
              trackEvent(playProgressEvent)

              ' set m.lastPingTime here to prevent an extra playProgressEvent if a user backs out of the ads
              ' thereby triggering backButtonExit() which also sends a playProgressEvent.
              m.lastPingTime = m.playerPosition
            end if
            
            ' update history when showing adBreak
            historyPosition(m.playerPosition)

            ' We must stop the video here, not just pause it, in order to release
            ' system resources to the RAF video player
            showAdBreak()
          else if m.top.adState = "noads"
            ' when we reach the cuepoint, we find that the last ad call returned no ads
            trackEvent({
              type: "resume_after_break"
              values: {
                video_id: m.Video.content.id.toInt()
                position: Int(m.playerPosition * 1000)  'without Int(), can return scientific notation, causing API error
              }
            })
          end if
        end if
      end if
    end for
  end if
End Function


' onAdStateChange
'
' adState values are:
'   "ready": the ad shim task is ready and listening for updates to the adControl field (should happen once per user session)
'   "init": no ad request has yet to be made for this video (adState is reset back to init when video is about to be started)
'   "fetching": a request has been made to the ad server, awaiting a response
'   "adspending": an ad response has been returned, the player is waiting to reach the appropriate cuepoint in order to play it
'   "adsplaying": ads are currently playing - RAF has control
'   "adsclosed": a user has hit the back button while RAF has control, closing the ad experience
'   "noads": an ad response has been received but there are no ads in it. Or an ad break has played to completion.
Function onAdStateChange()
  tubiLog("VideoPlayer.onAdStateChange adState = " + m.top.adState + " VideoState = " + m.VideoState + " Video.State = " + m.Video.state)
  if m.top.adState = "ready"
    m.top.adState = "init"
    if m.top.adControl <> ""
      ' There is a race condition that can occur during deeplinks such that m.top.adControl can be set before the adShim is listening
      ' which results in a ad/video loading screen that never loads. Reset the ad control once the ad state is in init if this is the case
      ' to fix the issue.
      m.top.adControl = m.top.adControl
    end if
  else if m.top.adState = "adspending" and (m.top.adControl = "preroll" or m.top.adControl = "seek") and m.top.enableAds then
    ' Midrolls are triggered from position changes since they are prefetched.  Other ad breaks have
    ' video playback stopped and should play right away when we get adspending.
    ' pre-roll or resume-roll. Play ads right away
    showAdBreak()
  else if m.top.adState = "noads" and (m.VideoState = "play" or m.VideoState = "pause" or m.VideoState = "ffw" or m.VideoState = "rew" or m.VideoState = "skip" or m.VideoState = "hop") and m.Video.state <> "playing" then
    ' no ads were returned from preroll or resumeroll, or we just came back from an ad break.  Make sure we start playing
    ' TODO(Chris): model the ad break more explicitly in m.VideoState so we're not trying to glean state from m.VideoState, m.Video.State, video control and ad control
    ' Set the m.Video.control prior to the m.Video.seek to ensure that the video is not started from the beginning even if m.playerPosition <> 0.
    ' This is a seeming inconsistency with the firmware and should not neccessarily work this way, but it does.
    ' Normally we would expect to set the seek prior to setting control to "play"
    ' Unfortunately, this order of play before seek causes a device crash if the content url is not a valid video url.
    if m.Video.content.url <> invalid and m.Video.content.url <> ""
      m.top.setFocus(true)
      m.seekReferenceQueue.push(m.playerPosition)
      m.VideoState = "play"
      m.Video.control = "play"
      seekToPosition(m.playerPosition)
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
      tubiException(jsonErrorInfo, "error")
    end if
  else if m.top.adState = "adsclosed"
    m.top.setFocus(true)
    backButtonExit()
  end if
End Function


Function onCaptionModeChange()
  tubiLog("VideoPlayer.onCaptionModeChange")
  if m.Video.globalCaptionMode = "On"
    fade(m.CCRailOn, "in", 0.5)
    fade(m.CCRailOff, "out", 0.5)
    slideTo(m.CCNipple, m.CCNippleOnTranslation, 0.5)
    toggleState = "ON"
  else  'handles "Off", "Instant replay", and "When mute"
    fade(m.CCRailOn, "out", 0.5)
    fade(m.CCRailOff, "in", 0.5)
    slideTo(m.CCNipple, m.CCNippleOffTranslation, 0.5)
    toggleState = "OFF"
  end if

  if m.Video.content <> invalid then
    language = "UNKNOWN"
    for i=0 to m.Video.availableSubtitleTracks.count()-1
      trackInfo = m.Video.availableSubtitleTracks[i]
      if m.Video.subtitleTrack = trackInfo.TrackName
        if trackInfo.language = "eng"
          language = "EN"
        else if trackInfo.language = "spa"
          language = "ES"
        else if trackInfo.language = "fre"
          language = "FR"
        else if trackInfo.language = "fra"
          language = "FR"
        else if trackInfo.language = "kor"
          language = "KO"
        else if trackInfo.language = "cho"
          language = "ZH"
        else if trackInfo.language = "zhi"
          language = "ZH"
        end if
      end if
    end for

    trackEvent({
      type: "subtitles_toggle"
      values: {
        video_id: m.Video.content.id.toInt()
        toggle_state: toggleState  'ToggleState enum
        language: language  'Language enum
      }
    })
  end if
End Function


Function onSpritesReceived(msg)
  thumbnailsInfo = msg.getData()  'expect a TubiContentNode with thumbnail fields populated
  
  m.Thumbnail.visible = false   ' always start with thumbnail invisible, then show it when scrubbing

  if thumbnailsInfo <> invalid
    ' sprites are reset to invalid when video playback stops. Don't log when that happens because
    ' it's confusing when reading the logs.
    tubiLog("VideoPlayer.onSpritesReceived")
 
    if thumbnailsInfo.thumbnailUrls <> invalid and thumbnailsInfo.thumbnailUrls.count() > 0
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
  removeFocusFromUpNext()
End Function


Function onUpNextOpacityChange(msg)
  opacity = msg.getData()

  ' in the case that the video finished and the up next UI was still showing, we did not update m.top.state
  ' which triggers the next video to autoplay. But now the up next UI has been closed, so we
  ' are ready to trigger the autoplay by setting m.top.state
  if opacity = 0 and m.VideoState = "stop"
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
  if status <> invalid and status.percentage <> invalid
    m.LoadingProgressBar.progress = status.percentage
  end if
End Function


Function onKidsModeChange()
  tubilog("VideoPlayer.onKidsModeChange")
  m.theme = m.global.theme
  updateColors()
  if m.top.kidsMode = false
    m.logo.visible = true
    m.logoKids.visible = false
  else
    m.logo.visible = false
    m.logoKids.visible = true
  end if
End Function


' Helper function to prevent tracking events being sent for trailers
Function trackEvent(event As Object)
  allowedTrailerEvents = {
    "start_trailer": true
    "trailer_play_progress": true
    "finish_trailer": true
  }

  if m.top.analyticsMode <> "trailer" or allowedTrailerEvents[event.type] = true
    m.global.trackingLoggingTask.trackEvent = event
  end if
End Function


' Helper function to prevent historyPosition being sent during  trailers
Function historyPosition(position)
  if m.top.analyticsMode = "normal" or m.top.analyticsMode = "autoplay-automatic" or m.top.analyticsMode = "autoplay-deliberate"
    ' round the position up/down based on 0.5 rule.
    ' this is necessary since isAtPosition() is returning true if the decimal is greater than 0.5.
    ' If we do not round here, and a user exits the video player during ad playback, the history would be
    ' stored always rounding down, but the ad check is done while rounding up over 0.5. So, if a user then
    ' resumes playback, the ad call sends the position as 1 second less than the midroll cuepoint, and
    ' no ads are returned, when they should be returned.
    wholeNum = Int(position)
    remainder = position - wholeNum
    if remainder >= 0.5
      position = wholeNum + 1
    else
      position = wholeNum
    end if

    m.top.historyPosition = Int(position)
    m.lastSavedPosition = position
  end if
End Function


Function cancelReplayCaptions()
  if m.video.globalCaptionMode = "On" and m.replayCaptionEnd <> 0
    tubilog("Turning off replay captions")
    m.replayCaptionEnd = 0
    m.video.globalCaptionMode = "Instant replay"
  end if
End Function


' Discover the current cc settings and format button text accordingly
Function getCCButtons()
  if m.top.content.subtitleTracks = invalid or m.top.content.subtitleTracks.count() = 0 then
    return ["Close"]
  else
    for i=0 to m.ccModes.count()-1
      if m.video.globalCaptionMode = m.ccModes[i][0]
        m.ccSelections[0] = i
      end if
    end for
    return ["Mode: " + m.ccModes[m.ccSelections[0]][1], "Close"]
  end if
End Function


'exit the video player due to back button while no transport displaying, or during ad break
Function backButtonExit()
  historyPosition(m.playerPosition)
  m.top.backButtonPressed = true
End Function


' Make sure the Video node is stopped and we have an accurate playback position before launching ads
Function showAdBreak()
  ' leave m.VideoState = "play" because from the component's perspective video is still playing
  m.Video.control = "stop"
  closeCCDialog()  ' if dialog is showing, it's awkward to have it still show after ad break

  m.top.adPosition = m.playerPosition
  m.top.adControl = "play"
End Function


' Helper function that aggregates any tasks that need to be done before playing a new video
Function prepareToStartVideo(content, drmIndex)
  resetVideoPlayerState(content)
  setDrmOnContent(content, drmIndex)
  m.top.content = content  'sends content to video node and makes current content available to contentController
  m.top.sendVideoTrackingStart = true
End Function


' Reset video player state to a state relevant to starting a video
' @content: TubiContentNode
Function resetVideoPlayerState(content = invalid)
  m.LoadingProgressBar.progress = 0
  m.LoadingMessage.text = ""
  cancelReplayCaptions()
  m.AdHeadsUp.visible = false
  if content <> invalid
    updateVideoPlayerState(content)
  end if
  m.top.adState = "init"
  m.top.upNextContentToAutoplay = invalid
  m.shouldShowUpNext = true
  m.UpNext.resetContent = true
End Function


Function stopVideo()
  tubilog("VideoPlayer.stopVideo")
  m.VideoState = "stop"

  ' add check so that onVideoStateChange doesn't get called
  ' if the video is already in a non playing state.
  if m.Video.state <> "stopped" and m.Video.state <> "finished"
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

  m.Video.seek = position
End Function


' Set video player state based on passed in content
' @content: TubiContentNode
Function updateVideoPlayerState(content) as Void
  if type(content) <> "roSGNode" then return

  ' make the content available to the video node
  m.Video.content = content

  ' add the title and episode title to the overlay
  title = m.Overlay.findNode("VideoOverlayTitle")
  episodeTitle = m.Overlay.findNode("VideoOverlayEpisodeTitle")
  if content.parentType = "series"
    title.text = content.parentTitle
    episodeTitle.text = content.title
  else
    title.text = content.title
    episodeTitle.text = ""
  end if

  'there are no subtitles so gray out the captions button
  if content.subtitleTracks = invalid or content.subtitleTracks.count() = 0
    m.TransportButtons.removeChild(m.ClosedCaption)
    m.ClosedCaptionDisabled.visible = true

  'there are subtitles, so check if captions button has been grayed out previously
  else if m.NodeHelpers.getChildIndex(m.TransportButtons, m.ClosedCaption) < 0
    m.TransportButtons.appendChild(m.ClosedCaption)
    m.ClosedCaptionDisabled.visible = false
  end if

  'if it's not a trailer, remove the skip trailer button
  if content.isTrailer = false
    m.TransportButtons.removeChild(m.SkipTrailerButton)

  'add the skip trailer button if it's a trailer and it doesn't already exist on the transport
  else if m.NodeHelpers.getChildIndex(m.TransportButtons, m.SkipTrailerButton) < 0
    m.TransportButtons.insertChild(m.SkipTrailerButton, 0)
  end if
End Function


Function removeFocusFromUpNext()
  m.UpNext.unfocus = true
  m.top.setFocus(true)
End Function


Function advanceDrmOnContent(contentNode)
  tubiLog("VideoPlayer.advanceDrmOnContent")
  nextIndex = 0
  if contentNode.drmType <> ""
    for i=0 to contentNode.videoResources.count()-1
      resource = contentNode.videoResources[i]
      if contentNode.drmType = resource.type
        nextIndex = i + 1
        exit for
      end if
    end for
  end if

  if setDrmOnContent(contentNode, nextIndex) = true
    nextResource = contentNode.videoResources[nextIndex]

    fallbackInfo = {
      failed_url: removeExcessUrl(resource.url)
      failed_drm: resource.type
      fallback_url: removeExcessUrl(nextResource.url)
      fallback_drm: nextResource.type
      model: m.constants.deviceInfo.model
      video_id: contentNode.id
    }

    ' log that we fell back to the next playback option after playback failed due to DRM
    tubiLog(FormatJSON(fallbackInfo), "error", "videoLoad", "drm-fallback")
    return true
  else
    return false
  end if
End Function


' Updates the content node's url and httpHeaders fields with the videoResource info indicated by the index value
'
' @contentNode: roSGNode, a TubiContentNode
' @index: int, the index of the video resource we want to use for DRM
Function setDrmOnContent(contentNode, index)
  tubiLog("VideoPlayer.setDrmOnContent")
  if contentNode.videoResources <> invalid and contentNode.videoResources.count() > 0 and contentNode.videoResources[index] <> invalid and contentNode.isTrailer <> true
    ' reset DRM fields
    contentNode.drmParams = {}
    contentNode.encodingType = ""
    contentNode.encodingKey = ""

    resource = contentNode.videoResources[index]

    ' set general fields related to DRM
    contentNode.httpHeaders = resource.drmHeaders
    contentNode.url = resource.url
    contentNode.length = resource.length
    contentNode.streamFormat = resource.streamFormat
    contentNode.drmType = resource.type

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
    if position > 0 and downloadedSegment <> invalid
      ' in the case of errorCode = -3, it likely means there was a 504 or 404 response from the server which ultimately was the source of the error.
      ' we get the last downloaded segment which is the last good segment instead of the current streaming segment, which may be several segments ahead of the bad segment.
      ' in this case, the segment causing the error is the segment AFTER the logged segment.
      errorInfo.segment_sequence = downloadedSegment.segSequence
      errorInfo.segment_url = removeExcessUrl(downloadedSegment.SegUrl)
      errorInfo.segment_bitrate = downloadedSegment.BitrateBps
    end if
  else if errorMsg <> invalid
    if errorCode = 0
      ' orignal network error message is to long:
      ' "Network error.  This could be caused by any of the following problems: (1) The server is down or unresponsive. (2) The server is unreachable. (3) There is a network setup issue on the client."
      errorInfo.error_message = "Network error"
    else
      errorInfo.error_message = errorMsg
    end if
    if position > 0 and streamingSegment <> invalid
      ' streamingSegment can be invalid when the server returns a 504, 404, etc.
      errorInfo.segment_url = removeExcessUrl(streamingSegment.segUrl)
      errorInfo.segment_start_time = streamingSegment.segStartTime
      errorInfo.segment_sequence = streamingSegment.segSequence
      errorInfo.segment_bitrate = streamingSegment.segBitrateBps
    end if
  end if
  errorInfo.error_code = errorCode

  if content <> invalid then errorInfo.video_id = content.id

  if position > 0 and streamInfo <> invalid
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
Function getPlayProgressEvent()
  playProgressEvent = invalid
  if m.playerPosition > m.lastPingTime
    playProgressEvent = {
      type: "play_progress"
      values: {
        video_id: m.Video.content.id.toInt()
        position: Int(m.playerPosition * 1000)   'ms - without Int(), can return scientific notation, causing API error
        view_time: Int((m.playerPosition - m.lastPingTime) * 1000)   'ms
      }
    }

    if m.top.analyticsMode = "trailer"
      playProgressEvent.type = "trailer_play_progress"
    else
      playProgressEvent.values.from_autoplay_deliberate = m.top.analyticsMode = "autoplay-deliberate"
      playProgressEvent.values.from_autoplay_automatic = m.top.analyticsMode = "autoplay-automatic"
    end if

    'nominal_speed will be added to the Connection message, rather than the PlayProgressEvent message,
    'but is still sent via this interface
    if m.Video.streamInfo <> invalid and m.Video.streamInfo.measuredBitrate <> invalid
      'measuredBitrate appears to be reported in bits despite the documentation that it is kibibits
      playProgressEvent.values.nominal_speed = Int(m.Video.streamInfo.measuredBitrate / (10^6))
    end if
  end if

  return playProgressEvent
End Function


' Returns true if the position is between the target and target+notificationInterval
Function isAtPosition(position, target)
  return (position >= target and position <= target + m.Video.notificationInterval)
End Function


' Returns true if the position is between (target - window) and the target
Function isInWindow(position, target, window)
  return (position >= (target - window) and position < target)
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
  for i=0 to seekReferenceQueue.count() - 1
    if seekReferenceQueue[i] = position
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
    none: true
  }
  
  if autoplayModes[mode] <> true
    mode = "none"
  end if

  m.top.autoplayMode = mode
End Function


' m.top.autoplayMode can take the value from the UpNext component, but also be updated
' from within the VideoPlayer component
Function onUpNextAutolayModeChange(msg)
  setAutoplayMode(msg.getData())
End Function