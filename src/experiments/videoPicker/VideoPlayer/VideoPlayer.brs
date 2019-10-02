' TODO(Chris): These events and their triggers
'
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
  m._ = rodash()
  m.NodeHelpers = TubiNodeHelpers()
  m.constants = m.global.constants
  Request = TubiRequest()
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)
  m.Loading = m.top.findNode("Loading")
  m.LoadingProgressBar = m.top.findNode("LoadingProgressBar")
  m.LoadingMessage = m.top.findNode("LoadingMessage")
  m.Transport = m.top.findNode("Transport")
  m.Video = m.top.findNode("VideoNode")  ' reference in case we change from extending Video to extending Group
  m.Video.observeField("position", "onVideoPositionChange")
  m.Video.observeField("state", "onVideoStateChange")
  m.Video.observeField("bufferingStatus", "onBufferingStatus")
  m.top.observeField("control", "onControlChange")
  m.top.observeField("playlist", "onPlaylistChange")
  m.top.observeField("seekPlaylist", "onSeekPlaylist")
  m.top.observeField("dock", "onDockedChange")
  m.top.observeField("showTransport", "onShowTransport")
  m.ElapsedLabel = m.top.findNode("ElapsedLabel")
  m.RemainingLabel = m.top.findNode("RemainingLabel")
  m.ProgressBar = m.top.findNode("ProgressBar")
  m.Overlay = m.top.findNode("VideoOverlay")
  m.ScrubTimer = m.top.findNode("ScrubTimer")
  m.PickerGroup = m.top.findNode("Picker")
  m.HUD = m.top.findNode("HUD")
  m.TransportGradient = m.top.findNode("TransportGradient")
  m.PickerGradient = m.top.findNode("PickerGradient")
  m.VideoPicker = m.top.findNode("VideoPicker")
  m.VideoPicker.observeField("contentFocused", "onVideoPickerFocused")
  m.VideoPicker.observeField("contentSelected", "onVideoPickerSelected")
  m.AdHeadsUp = m.top.findNode("AdHeadsUp")
  m.AdHeadsUpText = m.top.findNode("AdHeadsUpText")
  m.Thumbnail = m.top.findNode("Thumbnail")

  m.AdsTask = m.top.findNode("AdsTask")
  m.AdsTask.videoPlayerNode = m.top
  m.AdsTask.control = "RUN"

  'm.VideoState is source of truth for the state of the video player for the UI
  'possible values are "play", "pause", "rew", "ffw", "stop", "refresh", "skip"
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

  m.Video.observeField("globalCaptionMode", "onCaptionModeChange")
  m.top.observeField("adState", "onAdStateChange")
  m.top.observeField("adProgress", "onAdProgressChange")

  m.lastPingTime = 0
  m.lastSavedPosition = 0
  m.adPrefetchTime = 15
  m.adHeadsUpTime = 10
  m.adBreakAdvance = 0.5

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

  m.global.observeField("theme", "onThemeChange")
  '//Set the theme colors of the video player
  onThemeChange()

  ' set to the end position of replay if caption mode is temporarily turned on during a replay
  m.replayCaptionEnd = 0

  ' used by CC dialog
  m.ccSelections = [ 0 ]  ' modeled as an array for adding caption and audio tracks selection
  m.ccModes = [
    ' globalCaptionMode text,       Button text on software caption dialog
    ["Off",                          "Off"]
    ["On",                           "On always"]
    ["Instant replay",               "On replay"]
  ]

  m.thumbnailMinXOffset = 238 ' based on zeplin designs
  m.thumbnailMaxXOffset = 1920 - 238 - m.Thumbnail.width
  m.thumbnailMaxYOffset = 889

  if m.constants.deviceInfo.scaledUi = true then
    m.ProgressBar.scaledUI = m.constants.deviceInfo.scaledUi
    m.LoadingProgressBar.scaledUI = m.constants.deviceInfo.scaledUi
    m.TransportGradient.uri = "pkg:/images/playback-gradient-hd.9.png"
    m.PickerGradient.uri = "pkg:/images/browse-picker-gradient-hd.9.png"
  end if

  ' m.didAdvanceDrm holds current state regarding if playback failed, and the player is going to try the
  ' the next video stream available
  m.didAdvanceDrm = false
End Function


Function onThemeChange()
  m.focusedColor = m.global.theme.focused 
  m.ProgressBar.focusColor = m.focusedColor
  m.LoadingProgressBar.focusColor = m.focusedColor
  m.LoadingProgressBar.unfocusColor = m.focusedColor
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

Function onDockedChange()
  if m.top.dock
    ' immediately hide all HUD components
    m.Overlay.opacity = 0.0
    m.HUD.opacity = 0.0
    m.Loading.visible = false
    m.top.isDocked = true
  else
    m.top.isDocked = false
  end if
End Function


Function onVideoPickerSelected()
  tubiLog("VideoPlayer.onVideoPickerSelected " + stri(m.VideoPicker.contentSelected))
  if m.VideoPicker.contentFocused <> -1
    animateTransport("out")
    m.lastButtonPressPos = m.playerPosition

    if m.VideoPicker.contentSelected <> m.top.playlistIndex
      m.top.seekPlaylist = [m.VideoPicker.contentSelected, 0]
    else
      if m.Video.state = "paused"
        resumeFromPause()
      end if
    end if
  end if
End Function


' m.playerPosition is the main source of truth for position.
' It can be updated by the video node or by calculations made while scrubbing
Function updatePlayerPosition(amt=0)
  if amt > 0
    m.playerPosition = m._.min(m.playerPosition + amt, m.Video.duration - 5)
  else if amt < 0
    m.playerPosition = m._.max(m.playerPosition + amt, 0)
  else
    m.playerPosition = m.Video.position
  end if

  updateTransport()
End Function


' Callback when listening to the ScrubTimer fire
' Determine what the new playerPosition should be based on the scrubAmt and time spent scrubbing
Function updateScrubTime()
  timeSinceLastMark = m.scrubTimespan.totalMilliseconds() / 1000
  scrubTime = timeSinceLastMark * m.scrubMultipliers[m.scrubAmt]

  if m.VideoState = "rew"
    if m.playerPosition - scrubTime < 0
      m.playerPosition = 0
    else
      m.playerPosition = Int(m.playerPosition - scrubTime)
    end if

  else if m.VideoState = "ffw"
  '//Ensure scrub can't go past the timer for the UpNext Overlay
    nMaxScrub = m.Video.duration - m.global.constants.player.upNextCountdown - 5
    if m.playerPosition + scrubTime > nMaxScrub 
      m.playerPosition = nMaxScrub
    else
      m.playerPosition = Int(m.playerPosition + scrubTime)
    end if
  end if

  m.scrubTimespan.mark()

  updateTransport()
End Function


' Set the timestamps and position indicator
Function updateTransport()
  'update the position and remaining time text
  updateTransportTimes()

  'update the position bar width
  if m.Video.duration > 0
    percentComplete = (m.playerPosition / m.Video.duration)
    m.ProgressBar.progress = percentComplete * 100

    progressBarRight = m.ProgressBar.translation[0] + (m.ProgressBar.width * percentComplete)

    thumbnailXOffset = progressBarRight - m.Thumbnail.width / 2
    if thumbnailXOffset > m.thumbnailMaxXOffset
      thumbnailXOffset = m.thumbnailMaxXOffset
    end if
    if thumbnailXOffset < m.thumbnailMinXOffset
      thumbnailXOffset = m.thumbnailMinXOffset
    end if

    m.Thumbnail.translation = [thumbnailXOffset, m.Thumbnail.translation[1]]
    m.Thumbnail.jumpToSprite = m.playerPosition \ m.constants.player.thumbnailFrequency
  end if
End Function


'''''''''''''''''''''''''
' onVideoPositionChange
'
' The notificationInterval and analyticsInterval are not necessarily equal or evenly divisible
' so we check the time passage before we send playProgress events
Function onVideoPositionChange()
  tubiLog("VideoPlayer.onVideoPositionChange position = " + m.playerPosition.toStr())

  updatePlayerPosition()

  ' Auto hide transport
  if m.VideoState = "play" and m.HUD.opacity = 1 and m.playerPosition > m.lastButtonPressPos + m.transportAutoHideTime
    animateTransport("out")
  end if

  ' Cancel temporary captions
  if m.replayCaptionEnd <> 0 and m.playerPosition >= m.replayCaptionEnd
    cancelReplayCaptions()
  end if

  ' Analytics
  if m.playerPosition >= m.lastPingTime + m.analyticsInterval then
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

  if m.top.content <> invalid and m.top.content.creditsCuePoint <> invalid and m.top.content.creditsCuePoint > 0
    if m.top.creditsPosition > 0 and m.playerPosition < m.top.content.creditsCuePoint
      '//reset the creditsPosition if the current position is prior to the end credits: i.e. after watching the end credits, the user decided to rewind  before the credits
      m.top.creditsPosition = 0
    else if (m.top.creditsPosition <= 0 and m.playerPosition >= m.top.content.creditsCuePoint)
      ' Always fire history here to fix a race condition where the user has
      ' watched beyond the cuepoint but the title doesn't get removed due
      ' to no history events triggering after the cuepoint
      historyPosition(m.playerPosition + 5)
      m.top.creditsPosition = m.playerPosition
    end if
  end if

  'Advertisements
  if m.top.enableAds and m.top.midrolls <> invalid and m.top.midrolls.count() > 0 then
    m.AdHeadsUp.visible = false  ' default to AdHeadsUp being off; this will catch ff, replay, rew during the countdown
    for each cuepoint in m.top.midrolls

      if isAtPosition(m.playerPosition, cuepoint - m.adPrefetchTime)
        if cuepoint - m.adPrefetchTime <> m.recentCuepointFetch
          m.recentCuepointFetch = cuepoint - m.adPrefetchTime
          m.top.adPosition = cuepoint
          m.top.adControl = "midroll"
        end if
      end if

      if isInWindow(m.playerPosition, cuepoint, m.adHeadsUpTime) and m.top.adState = "adspending"
        if m.Overlay.opacity = 0
          ' Don't show the ad heads up when the transport/overlay is showing, since it crowds the space of the title on the overlay
          m.AdHeadsUp.visible = true
          m.AdHeadsUpText.text = " " + Chr(&hb7) + " Starts in " + stri(cuepoint - m.playerPosition).trim() + " s"
        end if
      end if

      ' Fire up the midroll
      if cuepoint > 0 and isAtPosition(m.playerPosition, cuepoint - m.adBreakAdvance)
        if cuepoint <> m.recentCuepoint
          m.AdHeadsUp.visible = false
          m.recentCuepoint = cuepoint
          if m.top.adState = "adspending" then
            ' Send a play_progress event before we show ads to be most accurate in case the user exits during ad playback
            playProgressEvent = getPlayProgressEvent()
            if playProgressEvent <> invalid
              m.lastPingTime = m.playerPosition
              trackEvent(playProgressEvent)
            end if

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


Function playContent()
  tubilog("VideoPlayer.playContent")
  if m.Video.content.nowPos <> invalid then
    m.Video.seek = m.Video.content.nowPos
    m.playerPosition = m.Video.content.nowPos
    m.lastSavedPosition = m.Video.content.nowPos
    m.lastPingTime = m.Video.content.nowPos
    m.lastButtonPressPos = m.Video.content.nowPos
  else
    m.lastPingTime = 0
    m.lastSavedPosition = 0
    m.lastButtonPressPos = 0
  end if
  m.top.midrolls = []  ' Always reset midrolls when we first start playback.  Preroll will populate these
    
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
    ' Start pre-roll fetch
    m.top.adControl = "preroll"
  else
    m.Video.control = "play"
  end if
End Function


Function onControlChange()
  tubiLog("VideoPlayer.onControlChange " + m.top.control)
  if currentPlaylistContent() <> invalid and m.Video.state <> "playing" and m.top.control = "play" then
    cancelReplayCaptions()
    refreshContent(currentPlaylistContent().nowPos)

  else if m.top.control = "stop" then
    cancelReplayCaptions()
    m.Video.control = "stop"
    m.VideoState = "stop"

    'in the case where an ad break has started, but RAF does not yet have control, we want to break out of ads on back button pressed
    if m.top.adState = "fetching" or m.top.adState = "adsPending"
      m.top.adControl = "stop"
    end if
  else if m.top.control = "pause" then
    pauseVideo(false)
  else if m.top.control = "resume" and m.Video.state = "paused" then
    resumeFromPause()
  end if
End Function


Function onKeyEvent(key As String, press As Boolean)
  tubiLog("VideoPlayer.onKeyEvent key = " + key)
  if press
    m.lastButtonPressPos = m.playerPosition

    if isButtonPressAllowed(key,  m.VideoState, m.Video)
      if key = "OK"
        if m.HUD.opacity = 0
          showTransport()
        else
          'do action based on the current focused button
          focusButtonId = m.TransportButtons.getChild(m.focusedButtonIndex).id
          if focusButtonId = m.SkipTrailerButton.id
            handleSkipTrailer()
          else if focusButtonId = m.StartButton.id
            goToStart()
          else if focusButtonId = m.RewindButton.id
            handleRewind()
          else if focusButtonId = m.HopBackButton.id
            handleHopBack(false)
          else if focusButtonId = m.PlayPauseButton.id
            handlePlayPause()
          else if focusButtonId = m.HopForwardButton.id
            handleHopForward()
          else if focusButtonId = m.FastForwardButton.id
            handleFastForward()
          else if focusButtonId = m.EndButton.id
            goToNext()
          else if focusButtonId = m.ClosedCaption.id
            handleClosedCaption()
          end if
        end if

      else if key = "play" then
        if m.PlayPauseButton.enabled then
          handlePlayPause()
        end if

      else if key = "fastforward"
        if m.FastForwardButton.enabled then
          handleFastForward()
        end if

      else if key = "rewind"
        if m.RewindButton.enabled then
          handleRewind()
        end if

      else if key = "replay"
        if m.HopBackButton.enabled then
          handleHopBack(true)
        end if

      else if key = "options"
        if m.ignoreOptionsKey = false then
          showCCDialog()
        end if

      else if key = "left"
        'video is in playback mode and user wants to skip back
        if m.HUD.opacity = 0 and m.progressBarFocused = false and isActiveVideoState(m.VideoState, m.Video)
          handleSkipVideo(-10, m.progressBarFocused)

        'user is in skip ahead mode (the progress bar is focused) and wants to skip back.
        else if m.progressBarFocused = true and isActiveVideoState(m.VideoState, m.Video)
          handleSkipVideo(-10, m.progressBarFocused)

        else
          'navigate the transport buttons, skipping disabled ones
          for i=m.focusedButtonIndex-1 to 0 step -1
            button = m.TransportButtons.getChild(i)
            if button.enabled then
              setFocusedButton(button)
              exit for
            end if
          end for
        end if

      else if key = "right"
        'video is in playback mode and user wants to skip ahead
        if m.HUD.opacity = 0 and m.progressBarFocused = false and isActiveVideoState(m.VideoState, m.Video)
          handleSkipVideo(10, m.progressBarFocused)

        'user is in skip ahead mode (the progress bar is focused) and wants to skip ahead.
        else if m.progressBarFocused = true and isActiveVideoState(m.VideoState, m.Video)
          handleSkipVideo(10, m.progressBarFocused)

        else
          'navigate the transport buttons, skipping disabled ones
          for i=m.focusedButtonIndex+1 to m.TransportButtons.getChildCount()-1
            button = m.TransportButtons.getChild(i)
            if button.enabled then
              setFocusedButton(button)
              exit for
            end if
          end for
        end if

      else if key = "up"
        if m.Overlay.opacity = 0
          showTransport()
        else if m.progressBarFocused = false
          setFocusedButton(m.ProgressBar)
        end if

      else if key = "down"
        if m.Overlay.opacity = 0
          showTransport()
        else if m.progressBarFocused = true
          button = m.TransportButtons.getChild(m.focusedButtonIndex)
          setFocusedButton(button)
        end if

      else if key = "back" then
        if m.VideoState = "play"
          if m.HUD.opacity = 0
            backButtonExit()
          else
            'close the transport
            animateTransport("out")
            resetTransportButtons()
          end if
        else if m.VideoState = "pause"
          resumeFromPause()
        else if m.VideoState = "rew" or m.VideoState = "ffw"
          setFocusedButton(m.PlayPauseButton)
          endScrub(true)
        else if m.VideoState = "skip"
          resumeFromSkip()
        end if
      end if
    end if
    ' Consume all key presses
    return true
  end if
  ' Allow unconsumed keypress to trickle up to ContentController, which is using
  ' keypresses to reset an inactivity timer
  return false
End Function


' onAdStateChange
'
' adState values are: init, fetching, adspending, noads, adsplaying, adsclosed, noads
Function onAdStateChange()
  tubiLog("VideoPlayer.onAdStateChange adState = " + m.top.adState + " VideoState = " + m.VideoState + " Video.State = " + m.Video.state)
  if m.top.adState = "init" and m.top.adControl <> ""
    ' There is a race condition that can occur during deeplinks such that m.top.adControl can be set before the adShim is listening
    ' which results in a ad/video loading screen that never loads. Reset the ad control once the ad state is in init if this is the case
    ' to fix the issue.
    m.top.adControl = m.top.adControl
  else if m.top.adState = "adspending" and (m.top.adControl = "preroll" or m.top.adControl = "seek") and m.top.enableAds then
    ' Midrolls are triggered from position changes since they are prefetched.  Other ad breaks have
    ' video playback stopped and should play right away when we get adspending.
    ' pre-roll or resume-roll. Play ads right away
    showAdBreak()
  else if m.top.adState = "noads" and (m.VideoState = "play" or m.VideoState = "pause" or m.VideoState = "ffw" or m.VideoState = "rew" or m.VideoState = "skip") and m.Video.state <> "playing" then
    ' no ads were returned from preroll or resumeroll, or we just came back from an ad break.  Make sure we start playing
    ' TODO(Chris): model the ad break more explicitly in m.VideoState so we're not trying to glean state from m.VideoState, m.Video.State, video control and ad control
    ' Set the m.Video.control prior to the m.Video.seek to ensure that the video is not started from the beginning even if m.playerPosition <> 0.
    ' This is a seeming inconsistency with the firmware and should not neccessarily work this way, but it does.
    ' Normally we would expect to set the seek prior to setting control to "play"
    ' Unfortunately, this order of play before seek causes a device crash if the content url is not a valid video url.
    if m.Video.content.url <> invalid and m.Video.content.url <> ""
      m.top.setFocus(true)
      m.VideoState = "play"
      m.Video.control = "play"
      m.Video.seek = m.playerPosition
      trackEvent({
        type: "resume_after_break"
        values: {
          video_id: m.Video.content.id.toInt()
          position: Int(m.playerPosition * 1000)    'without Int(), can return scientific notation, causing API error
        }
      })
    else
      errorMsg = "Video URL is not valid."
      m.top.errorMsg = errorMsg
      m.top.state = "error"
      errorInfo = {
        message: errorMsg
        video_id: m.top.content.id.toInt()
        video_url: m.top.content.url
      }
      tubiException(errorInfo, "error")
    end if
  else if m.top.adState = "adsclosed"
    m.top.setFocus(true)
    backButtonExit()
  end if
End Function


' Helper function to prevent tracking events being sent for trailers
Function trackEvent(event As Object)
  allowedTrailerEvents = {
    "start_trailer": true
    "trailer_play_progress": true
  }

  if m.top.analyticsMode <> "trailer" or allowedTrailerEvents[event.type] = true
    m.global.trackingLoggingTask.trackEvent = event
  end if
End Function


' Helper function to prevent historyPosition being sent during  trailers
Function historyPosition(position)
  if m.top.analyticsMode = "normal" or m.top.analyticsMode = "autoplay-automatic" or m.top.analyticsMode = "autoplay-deliberate" then
    m.top.historyPosition = Int(position)
    m.lastSavedPosition = position
  end if
End Function


'show transport
Function showTransport()
  resetTransportButtons()
  m.PlayPauseButton.uri = m.buttonUris.pause
  setFocusedButton(m.PlayPauseButton)
  m.PickerGroup.opacity = 0.0
  m.PickerGroup.translation = [0,0]
  m.Transport.opacity = 1.0
  m.Transport.translation = [0,0]
  m.PickerGradient.opacity = 0.0
  m.TransportGradient.opacity = 1.0
  animateTransport("in")
End Function


'aggregates all the animation for showing/hiding the transport
'@direction: string, value may be "out" or "in"
Function animateTransport(direction)
  tubiLog("VideoPlayer.AnimateTransport, direction = " + direction)
  slideFade(m.HUD, "below", direction, 0.6)
  fade(m.Overlay, direction, 0.6)
  
  ' always set focus back to here when hiding transport, that way left/right won't navigate VideoPicker overlay
  if m.top.isInFocusChain()
    if direction = "out" and m.PickerGroup.opacity > 0
      m.VideoPicker.setFocus(false)
      m.top.setFocus(true)
    end if
    if direction = "in" and m.Transport.opacity = 0
      m.VideoPicker.setFocus(true)
      m.VideoPicker.jumpToIndex = m.top.playlistIndex
    end if
  end if
End Function

Function focusVideoPicker(focus)
  tubiLog("VideoPlayer.focusVideoPicker")
  if not focus and m.VideoPicker.isInFocusChain()
    ' I'm not sure why we have to setFocus(false) here, but it doesn't work otherwise
    slideFade(m.PickerGroup, "below", "out", 0.6)
    slideFade(m.Transport, "below", "in", 0.6)
    fade(m.PickerGradient, "out", 0.6)
    fade(m.TransportGradient, "in", 0.6)
    m.VideoPicker.setFocus(false)
    m.top.setFocus(true)
    setFocusedButton(m.ProgressBar)
  else if focus and m.top.hasFocus()
    m.VideoPicker.jumpToIndex = m.top.playlistIndex
    slideFade(m.PickerGroup, "below", "in", 0.6)
    slideFade(m.Transport, "below", "out", 0.6)
    fade(m.PickerGradient, "in", 0.6)
    fade(m.TransportGradient, "out", 0.6)
    m.VideoPicker.setFocus(true)
    m.progressBarFocused = false
  end if
End Function


'pause the video player
Function pauseVideo(shouldShowTransport)
  m.Video.control = "pause"
  m.VideoState = "pause"

  if shouldShowTransport
    if m.HUD.opacity < 1.0
      showTransport()
    else
      ' make sure transport is showing
      focusVideoPicker(false)
    end if
  end if

  m.PlayPauseButton.uri = m.buttonUris.play
  setFocusedButton(m.PlayPauseButton)
  
  updateTransport()
  trackEvent({
    type: "pause_toggle"
    values: {
      video_id: m.Video.content.id.toInt()
      pause_state: "PAUSED"
    }
  })
End Function


'Resume play from a paused state
Function resumeFromPause()
  animateTransport("out")

  if m.playerPosition <> m.Video.position
    jumpToPosition(m.playerPosition)
  else
    m.Video.control = "resume"
    m.VideoState = "play"

  trackEvent({
    type: "pause_toggle"
    values: {
      video_id: m.Video.content.id.toInt()
      pause_state: "RESUMED"
    }
  })
  end if

  m.PlayPauseButton.uri = m.buttonUris.pause
  setFocusedButton(m.PlayPauseButton)
End Function


Function resumeFromSkip()
  tubiLog("VideoPlayer.resumeFromSkip")
  animateTransport("out")
  if m.playerPosition <> m.Video.position
    jumpToPosition(m.playerPosition)
  else
    m.Video.control = "resume"
    m.VideoState = "play"
  end if
  m.lastPingTime = m.playerPosition
  m.PlayPauseButton.uri = m.buttonUris.pause
  setFocusedButton(m.PlayPauseButton)
End Function


Function resetTransportButtons()
  m.SkipTrailerButton.focusState = false
  m.StartButton.focusState = false
  m.RewindButton.uri = m.buttonUris.rewind
  m.RewindButton.focusState = false
  m.HopBackButton.focusState = false
  m.PlayPauseButton.uri = m.buttonUris.play
  m.PlayPauseButton.focusState = false
  m.HopForwardButton.focusState = false
  m.FastForwardButton.uri = m.buttonUris.fastForward
  m.FastForwardButton.focusState = false
  m.EndButton.focusState = false
  m.ClosedCaption.focusState = false

  'also upate the transport timestamps
  updateTransportTimes()
End Function


Function updateTransportTimes()
  m.ElapsedLabel.text = formatLengthAsTimestamp(m.playerPosition)
  if m.Video.duration <> invalid then
    m.RemainingLabel.text = "-" + formatLengthAsTimestamp(m.Video.duration - m.playerPosition)
  end if
End Function

Function showThumbnail()
  if m.Thumbnail.spriteUrls <> invalid and m.Thumbnail.spriteUrls.count() > 0 and m.constants.deviceInfo.limitedUi = false
    m.Thumbnail.visible = true
  else
    m.Thumbnail.visible = false
  end if
end Function

'Perform at start of FF or RW
Function beginScrub()
  m.Video.control = "pause"
  m.scrubAmt = 0
  resetTransportButtons()
  m.ScrubTimer.observeField("fire", "updateScrubTime")
  m.ScrubTimer.control = "start"

  if m.HUD.opacity < 1.0
    showTransport()
  end if
  showThumbnail()
  m.scrubTimespan.mark()

  ' playProgress analytics
  if m.VideoState <> "skip"
    playProgressEvent = getPlayProgressEvent()
    if playProgressEvent <> invalid
      trackEvent(playProgressEvent)
    end if
  end if
End Function


'Perform at end of FF or RW
' @shouldJump: boolean, indicates if we should use jumpToPosition - don't use if will use later on in the calling function
Function endScrub(shouldJump = false)
  m.scrubAmt = -1 'reset just in case it somehow got to less than -1
  m.ScrubTimer.control = "stop"
  m.ScrubTimer.unobserveField("fire")
  ' Reset periodic event trackers
  m.lastPingTime = m.playerPosition

  animateTransport("out")
  resetTransportButtons()
  m.PlayPauseButton.uri = m.buttonUris.pause
  setFocusedButton(m.PlayPauseButton)

  if shouldJump = true
    jumpToPosition(m.playerPosition)
  end if
End Function


'handles the Skip Trailer selection
'triggers callback on ContentController to play the full video
Function handleSkipTrailer()
  m.top.skipTrailer = true
  animateTransport("out")
  resetTransportButtons()  
  setFocusedButton(m.PlayPauseButton)
End Function


'handles StartButton selection
'moves the player to the 0:00:00 position
Function goToStart()
  m.positionAtJumpStart = m.playerPosition
  if m.VideoState = "ffw" or m.VideoState = "rew"
    endScrub(false)
    setFocusedButton(m.StartButton)
  else
    playProgressEvent = getPlayProgressEvent()
    if playProgressEvent <> invalid
      trackEvent(playProgressEvent)
    end if
  end if
  m.playerPosition = 0
  m.lastPingTime = m.playerPosition
  jumpToPosition(m.playerPosition)
End Function


'handles EndButton selection
Function goToNext()
  'reset before endScrub because we don't want an ad call made when moving to the next video, let prerolls hit instead
  if m.VideoState = "ffw" or m.VideoState = "rew"
    endScrub(true)
  end if

  if not advancePlaylist() then
    'the end of the video playback
    m.VideoState = "stop"
    m.Video.control = "stop"
    m.top.goToNext = true
  end if
  animateTransport("out")
  resetTransportButtons()
End Function


'handles play key press or PlayPause button selection
Function handlePlayPause()
  tubiLog("VideoPlayer.handlePlayPause VideoState = " + m.VideoState)
  if m.VideoState = "play" then
    pauseVideo(true)
  else if m.VideoState = "pause" then
    resumeFromPause()
  else if m.VideoState = "rew" or m.VideoState = "ffw"
    endScrub(true)
  else if m.VideoState = "skip"
    resumeFromSkip()
  end if
  setFocusedButton(m.PlayPauseButton, true)
End Function


'handles fast forward key press or FastForward button selection
Function handleFastForward()
  'begin fast forwarding, but don't need everything in beginScrub()
  if m.VideoState = "rew"
    m.VideoState = "ffw"
    m.scrubAmt = 0
    m.RewindButton.uri = m.buttonUris.rewind
    m.FastForwardButton.uri = m.buttonUris.fastForwardLevels[0]

  'increase the fast forward speed
  else if m.VideoState = "ffw"
    if m.scrubAmt < m.maxScrub
      m.scrubAmt = m.scrubAmt + 1
    else
      m.scrubAmt = 0
    end if
    m.FastForwardButton.uri = m.buttonUris.fastForwardLevels[m.scrubAmt]

  'start the fast forward
  else
    m.positionAtJumpStart = m.playerPosition
    beginScrub()
    m.VideoState = "ffw"
    m.FastForwardButton.uri = m.buttonUris.fastForwardLevels[0]
    m.PlayPauseButton.uri = m.buttonUris.play
  end if

  setFocusedButton(m.FastForwardButton, true)
End Function


'handles rewind key press or Rewind button selection
Function handleRewind()
  'begin rewinding, but don't need everything in beginScrub()
  if m.VideoState = "ffw"
    m.VideoState = "rew"
    m.scrubAmt = 0
    m.FastForwardButton.uri = m.buttonUris.fastforward
    m.RewindButton.uri = m.buttonUris.rewindLevels[0]

  'increase the rewind speed
  else if m.VideoState = "rew"
    if m.scrubAmt < m.maxScrub
      m.scrubAmt = m.scrubAmt + 1
    else
      m.scrubAmt = 0
    end if
    m.RewindButton.uri = m.buttonUris.rewindLevels[m.scrubAmt]

  'start the rewind
  else
    m.positionAtJumpStart = m.playerPosition
    beginScrub()
    m.VideoState = "rew"
    m.RewindButton.uri = m.buttonUris.rewindLevels[0]
    m.PlayPauseButton.uri = m.buttonUris.play
  end if

  setFocusedButton(m.RewindButton, true)
End Function


'handles HopForward button selection
Function handleHopForward()
  if m.VideoState = "ffw" or m.VideoState = "rew"
    endScrub(false)
    setFocusedButton(m.HopForwardButton)
  else if m.VideoState <> "skip"
    playProgressEvent = getPlayProgressEvent()
    if playProgressEvent <> invalid
      trackEvent(playProgressEvent)
    end if

    'only update m.positionAtJumpStart if we are not concluding another seek interaction
    m.positionAtJumpStart = m.playerPosition  'used for seek event analytics
  end if
  if m.HUD.opacity > 0.0
    animateTransport("out")
  end if
  hopPosition = m.playerPosition + 30
  jumpToPosition(hopPosition)
  m.lastPingTime = hopPosition        'used for accurate play_progress accounting
End Function


'handles HopBack button selection
Function handleHopBack(remoteReplayButton)
  setFocusedButton(m.HopBackButton)  'necessary because there is a dedicated hop back button on certain roku remotes

  if m.VideoState = "ffw" or m.VideoState = "rew"
    endScrub(false)
  else if m.VideoState <> "skip"
    playProgressEvent = getPlayProgressEvent()
    if playProgressEvent <> invalid
      trackEvent(playProgressEvent)
    end if

    'only update m.positionAtJumpStart if we are not concluding another seek interaction
    m.positionAtJumpStart = m.playerPosition   'used for seek event analytics
  end if

  setFocusedButton(m.HopBackButton, true)

  if m.HUD.opacity > 0.0
    animateTransport("out")
  end if

  hopPosition = m.playerPosition - 30
  if remoteReplayButton = true
    hopPosition = m.playerPosition - 20
    if m.Video.globalCaptionMode = "Instant replay"
      tubilog("Turning on replay captions")
      m.replayCaptionEnd = m.positionAtJumpStart
      m.video.globalCaptionMode = "On"
    end if
  end if

  jumpToPosition(hopPosition)
  m.lastPingTime = hopPosition    'used for accurate play_progress accounting
End Function


'helper function to conclude a hop, skip, or end scrub
'performs the seek tracking and runs an ad break if told to
Function handleSeek(position as Float, positionAtJumpStart as Float, shouldAdBreak as Boolean)
  m.Thumbnail.visible = false
  ' seek analytics
  trackEvent({
    type: "seek"
    values: {
      video_id: m.Video.content.id.toInt()
      from_position: Int(positionAtJumpStart * 1000)
      to_position: Int(position * 1000)
    }
  })

  if shouldAdBreak
    m.Video.control = "stop"
    m.top.adPosition = position
    m.top.adControl = "seek"
  else
    m.Video.seek = position 'will load and play the video at the seeked to point
    m.VideoState = "play"
  end if
End Function


'handles the functionality for Roku's requirement to skip the video forward or backward while pausing the video.
'functionality is: pause video, jump 10s forward or back, show the transport
Function handleSkipVideo(amt, isProgressBarFocused)
  'handle the first skip press
  print "m.VideoState "; m.VideoState
  if m.VideoState <> "skip"
    m.Video.control = "pause"
    m.PlayPauseButton.uri = m.buttonUris.play

    if m.VideoState <> "rew" and m.VideoState <> "ffw"
      playProgressEvent = getPlayProgressEvent()
      if playProgressEvent <> invalid
        trackEvent(playProgressEvent)
      end if

      'only update m.positionAtJumpStart if we are not concluding another seek interaction
      m.positionAtJumpStart = m.playerPosition
    end if

    m.VideoState = "skip"
  end if

  if isProgressBarFocused <> true
    showTransport()
    m.PlayPauseButton.uri = m.buttonUris.play
    setFocusedButton(m.ProgressBar)
  end if
  showThumbnail()

  updatePlayerPosition(amt)
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

'handles ClosedCaption button/toggle selection
Function handleClosedCaption()
  cancelReplayCaptions()
  if m.HUD.opacity < 1.0
    animateTransport("in")
  end if

  setFocusedButton(m.ClosedCaption, true)

  'setting the globalCaptionMode will trigger a callback that updates the images and does user tracking
  if m.Video.globalCaptionMode = "On"
    m.Video.globalCaptionMode = "Off"
  else ' If "When mute" or "Instant replay", also turn it on
    m.Video.globalCaptionMode = "On"
  end if
End Function

Function showCCDialog()
  ' show full options dialog
  if m.VideoState = "play" or m.VideoState = "pause" then
    m.ccWasPlaying = false
    if m.VideoState = "play" then
      m.ccWasPlaying = true
      pauseVideo(false)
    end if
    m.ccDialog = CreateObject("roSGNode", "ModalDialogScreen")
    m.ccDialog.title = "Closed Caption/Audio Configuration"
    buttons = getCCButtons()
    m.ccDialog.buttons = buttons
    if buttons.count() = 1 then
      m.ccDialog.message = "No captions are available for this video."
    end if
    m.ccDialog.observeField("buttonSelected", "onCCDialogButton")
    m.ccDialog.observeField("exitButton", "closeCCDialog")
    m.top.appendChild(m.ccDialog)
    m.ccDialog.visible = true
    m.ccDialog.setFocus(true)
    trackEvent({
      type: "dialog"
      values: {
        dialog_type: "INFORMATION" 'DialogType enum
        pageOneof: m.Tracking.getAnalyticsPage("", {})
      }
    })
  end if
End Function

Function closeCCDialog()
  if m.ccDialog <> invalid then
    if m.ccWasPlaying then
      resumeFromPause()
    end if
    m.ccDialog.unobserveField("buttonSelected")
    m.ccDialog.unobserveField("exitButton")
    m.ccDialog.setFocus(false)
    m.top.setFocus(true)
    m.top.removeChild(m.ccDialog)
    m.ccDialog = invalid
  end if
End Function

Function onCCDialogButton()
  tubiLog("VideoPlayer.onCCDialogButton")
  index = m.ccDialog.buttonSelected
  if m.ccDialog.buttons[index] = "Close" then
    ' Close
    closeCCDialog()
  else
    ' Captions mode
    m.ccSelections[0] = (m.ccSelections[0] + 1) MOD m.ccModes.count()
    m.video.globalCaptionMode = m.ccModes[m.ccSelections[0]][0]
    m.ccDialog.buttons = getCCButtons()
  end if
End Function

'handles replay key press or HopBack button selection
'@position: integer, should be m.playerPosition in most cases
'
'function calling jumpToPosition should reset m.positionAtJumpStart to -1 after calling jumpToPosition
Function jumpToPosition(position)
  tubiLog("VideoPlayer.jumpToPosition")
  cancelReplayCaptions() ' on any jump we cancel any temporary caption modifications

  'Don't let position be out of bounds of the duration of the video
  if position > (m.Video.duration - 5)
    position = m.Video.duration - 5
  else if position < 0
    position = 0
  end if
  m.playerPosition = position 'in case position is updated by the above block

  shouldAdBreak = false
  if m.top.enableAds and m.positionAtJumpStart > -1 and position > m.positionAtJumpStart
    shouldAdBreak = true
  end if

  m.PlayPauseButton.uri = m.buttonUris.pause
  m.lastButtonPressPos = position

  handleSeek(position, m.positionAtJumpStart, shouldAdBreak)
End Function


'Finds the 'index' of the passed in transport button node and sets it on m.focusedButtonIndex
'Additionally updates the image of the button to the focused version and all other buttons to the unfocused version
'
' If keyFocus is true it will forcefully set focus to the transport
Function setFocusedButton(TransportButton, keyFocus=false)
  if keyfocus
    focusVideoPicker(false)
  end if

  if TransportButton.id = "ProgressBar"
    m.progressBarFocused = true
    m.ProgressBar.setFocus(true)
  else
    m.ProgressBar.setFocus(false)
    m.progressBarFocused = false
    m.top.setFocus(true)
  end if

  for i=0 to m.TransportButtons.getChildCount()-1
    button = m.TransportButtons.getChild(i)
    if TransportButton.id = button.id
      m.focusedButtonIndex = i
      ' if overlay has focus, don't set the icon to orange
      if m.top.hasFocus()
        button.focusState = true
      else
        button.focusState = false
      end if
    else
      button.focusState = false
    end if
  end for
End Function

'exit the video player due to back button while no transport displaying, or during ad break
Function backButtonExit()
  historyPosition(m.playerPosition)
  m.top.backButtonPressed = true
End Function


' Make sure the Video node is stopped and we have an accurate playback position before launching ads
Function showAdBreak()
  m.Video.control = "stop"
  closeCCDialog()  ' if dialog is showing, it's awkward to have it still show after ad break

  m.top.adPosition = m.playerPosition
  m.top.adControl = "play"
End Function


Function onShowTransport()
  if m.top.showTransport then
    m.lastButtonPressPos = m.playerPosition
    showTransport()
  else
    animateTransport("out")
  end if
End Function


' Play progress events should occur (and m.lastPingTime should be set!) at the following instances
' a user watches for 10s (pauses should not set m.lastPingTime)
' an ad break starts
' a user begins a "seek" functionality (skip 10s, hop 30s, ff/rew)
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


' Helper function to determine if we should ignore or handle a button press
' We don't want to handle button presses that affect video playback when the video is not loaded
' Moving focus around the transport is ok though
Function isButtonPressAllowed(key, videoState, videoNode)
  disabledKeys = {
    OK: true
    rewind: true
    fastforward: true
    play: true
    replay: true
    options: true
  }

  isAllowed  = true
  'in non active video states, we don't allow the disabled keys, non disable keys are always allowed
  if not isActiveVideoState(videoState, videoNode) and disabledKeys[key] = true
    isAllowed = false
  end if

  return isAllowed
End Function


' Helper function to determine if the video state (m.VideoState) is such that we should handle button presses
' Currently we don't want to handle most button presses when m.VideoState is in the "refresh" or "stop" states
Function isActiveVideoState(videoState, videoNode)
  disactiveStates = {
    refresh: true
    stop: true
  }

  isActive = true
  if disactiveStates[videoState] = true
    isActive = false
  end if

  if videoNode.state = "buffering" or videoNode.state = "stopped"
    isActive = false
  end if

  return isActive
End Function


' Returns true if the position is between the target and target+notificationInterval
Function isAtPosition(position, target)
  return (position >= target and position <= target + m.Video.notificationInterval)
End Function

' Returns true if the position is between (target - window) and the target
Function isInWindow(position, target, window)
  return (position >= (target - window) and position < target)
End Function
