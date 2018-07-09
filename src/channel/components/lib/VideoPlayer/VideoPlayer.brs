' TODO(Chris): These events and their triggers
'
'   Analytics tracking:
'
'      EVENT            TRIGGERS
'      ===============================
'      videoPlay        only on start of episode playback, or autoplay invoked playback
'
'      resumeAfterAds   after pre-roll and each mid-roll
'
'      playProgress     on start of scrubbing
'                       at regular intervals set by 'pingFrequency' in constants
'
'      seek             at end of scrubbing
'
'      pauseToggle      when paused using pause/play button
'                       when resumed using pause/play button
'
'      subtitle         when subtitles turned off
'                       when subtitles turned on
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
  m.Spinner = m.top.findNode("BufferSpinner")
  m.Loading = m.top.findNode("Loading")
  m.Transport = m.top.findNode("Transport")
  m.Video = m.top.findNode("VideoNode")  ' reference in case we change from extending Video to extending Group
  m.Video.observeField("position", "onVideoPositionChange")
  m.Video.observeField("state", "onVideoStateChange")
  m.Video.observeField("downloadedSegment", "onDownloadedSegment")
  m.top.observeField("control", "onControlChange")
  m.top.observeField("content", "onContentChange")
  m.top.observeField("playlist", "onPlaylistChange")
  m.top.observeField("seekPlaylist", "onSeekPlaylist")
  m.top.observeField("dock", "onDockedChange")
  m.top.observeField("showTransport", "onShowTransport")
  m.ElapsedLabel = m.top.findNode("ElapsedLabel")
  m.RemainingLabel = m.top.findNode("RemainingLabel")
  m.ProgressBar = m.top.findNode("ProgressBarForeground")
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

  'm.VideoState is source of truth for the state of the video player for the UI
  'possible values are "play", "pause", "rew", "ffw", "stop", "refresh"
  m.VideoState = "stop"
  m.scrubAmt = -1
  m.playerPosition = 0
  m.maxScrub = m.constants.player.maxScrub
  m.scrubMultipliers = m.constants.player.scrubMultipliers
  m.scrubTimespan = CreateObject("roTimespan")
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

  m.lastPingTime = 0
  m.lastSavedPosition = 0
  m.adPrefetchTime = 15
  m.adHeadsUpTime = 10

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

  m.focusedColor = m.constants.ui.colors.focused

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

  ' Workaround for 9-patch bug
  '
  ' ProgressBarBackground and ProgressBarForeground use 9-patch images which have
  ' special undocumented handling (bugs?).  For manifest with ui_resolution=fhd, we
  ' need to provide 2 resolutions: fhd and hd, where hd 0.75 the intended resolution.  For instance,
  ' we expect the FHD height to be 16 pixels so the hd source image height has to be 12 pixels.  Roku
  ' wrongly applies a 1.5x scaling when ui_resolution=fhd and the screen is 720p.  SD resolutions are
  ' not needed since 720p ui resolution is used and scaled down properly.
  '
  ' NOTE2: 9-patch images can't have width/height set below their native resolution (bitmapWidth/bitmapHeight)
  '        else the 9-patch logic does not get applied and you will just see stretched images.  Because of
  '        scaling wackiness, bitmapWidth or bitmapHeight may report half-pixel values.  It's best to not
  '        set a height explicitly.
  if m.constants.deviceInfo.scaledUi = true then
    background = m.top.findNode("ProgressBarBackground")
    background.uri = "pkg:/images/transport/sgplayer/hd/progress-background.9.png"
    foreground = m.top.findNode("ProgressBarForeground")
    foreground.uri = "pkg:/images/transport/sgplayer/hd/white-progress-foreground.9.png"
    m.TransportGradient.uri = "pkg:/images/playback-gradient-hd.9.png"
    m.PickerGradient.uri = "pkg:/images/browse-picker-gradient-hd.9.png"
  end if
End Function


Function onDockedChange()
  if m.top.dock
    ' immediately hide all HUD components
    m.Overlay.opacity = 0.0
    m.HUD.opacity = 0.0
    m.Loading.visible = false
    m.Spinner.visible = false
    m.top.isDocked = true
  else
    m.top.isDocked = false
  end if
End Function


Function onContentChange() As Void
  tubiLog("VideoPlayer.onContentChange")
  cancelReplayCaptions()
  m.AdHeadsUp.visible = false
  if m.top.content = invalid then return

  'add the title and episode title to the overlay
  title = m.Overlay.findNode("VideoOverlayTitle")
  episodeTitle = m.Overlay.findNode("VideoOverlayEpisodeTitle")
  if m.top.content.parentType = "series"
    title.text = m.top.content.parentTitle
    episodeTitle.text = m.top.content.title
  else
    title.text = m.top.content.title
    episodeTitle.text = ""
  end if

  'there are no subtitles so grey out the captions button
  if m.top.content.subtitleTracks = invalid or m.top.content.subtitleTracks.count() = 0
    m.TransportButtons.removeChild(m.ClosedCaption)
    m.ClosedCaptionDisabled.visible = true
  
  'there are subtitles, so check if captions button has been greyed out previously
  else if m.NodeHelpers.getChildIndex(m.TransportButtons, m.ClosedCaption) < 0
    m.TransportButtons.appendChild(m.ClosedCaption)
    m.ClosedCaptionDisabled.visible = false
  end if

  liveTVGroup = m.top.findNode("LiveTVGroup")

  if m.top.content.isLiveTV then
    liveTVGroup.visible = true
  else
    liveTVGroup.visible = false
  end if

  'if it's not a trailer, remove the skip trailer button
  if m.top.content.isTrailer = false
    m.TransportButtons.removeChild(m.SkipTrailerButton)

  'add the skip trailer button if it's a trailer and it doesn't already exist on the transport
  else if m.NodeHelpers.getChildIndex(m.TransportButtons, m.SkipTrailerButton) < 0
    m.TransportButtons.insertChild(m.SkipTrailerButton, 0)
  end if

  m.Thumbnail.visible = false   ' always start with thumbnail invisible, then show it when scrubbin
  if m.top.content.thumbnailUrls <> invalid and m.top.content.thumbnailUrls.count() > 0 and m.constants.deviceInfo.limitedUi = false
    m.Thumbnail.numSprites = m.top.content.thumbnailSpan
    ' This should bring the 4400px image width down below the 4kx4k texture size limit
    ' which would otherwise cause the images to fail to load.
    scaleFactor = 0.75
    m.Thumbnail.spriteSheetWidth = m.top.content.thumbnailSize[0] * m.top.content.thumbnailSpan * scaleFactor
    m.Thumbnail.spriteSheetHeight = m.top.content.thumbnailSize[1] * scaleFactor
    m.Thumbnail.spriteUrls = m.top.content.thumbnailUrls
    m.Thumbnail.jumpToSprite = 0
    ' Always keep height of thumbnail the same, varying the width if necessary
    thumbnailAspect = m.top.content.thumbnailSize[0] / m.top.content.thumbnailSize[1]
    m.Thumbnail.width = m.Thumbnail.height * thumbnailAspect
    m.thumbnailMaxXOffset = 1920 - 238 - m.Thumbnail.width
    m.Thumbnail.translation = [m.thumbnailMinXOffset, m.thumbnailMaxYOffset - m.Thumbnail.height]
  else
  end if
End Function

Function onVideoPickerFocused()
  tubiLog("VideoPlayer.onVideoPickerFocused = " + stri(m.VideoPicker.contentFocused))
  if m.VideoPicker.contentFocused <> -1
    m.lastButtonPressPos = m.playerPosition

    'content grid naturally debounces the content selections, so trackEvent and navigations increment
    'only happen when a user has settled on a content
    m.VideoPicker.navigations = m.VideoPicker.navigations + 1
    
    trackEvent({
      trackType: "navigateInPage"
      value: m.VideoPicker.navigations
      ctx: "/on_now/" + m.top.content.slug + "/1/" + m.VideoPicker.contentFocused.toStr()
    })
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
    if m.playerPosition + scrubTime > (m.Video.duration - 5)
      m.playerPosition = m.Video.duration - 5
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
    maxWidth = m.top.findNode("ProgressBarBackground").width
    minWidth = m.ProgressBar.bitmapWidth
    percentComplete = (m.playerPosition / m.Video.duration)
    m.ProgressBar.width = minWidth + percentComplete * (maxWidth - minWidth)

    progressBarRight = m.ProgressBar.translation[0] + m.ProgressBar.width

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
  tubiLog("VideoPlayer.onVideoPositionChange position =" + stri(m.Video.position))

  updatePlayerPosition()

  ' Auto hide transport
  if m.VideoState = "play" and m.HUD.opacity > 0 and m.playerPosition > m.lastButtonPressPos + m.transportAutoHideTime
    animateTransport("out")
  end if

  ' Cancel temporary captions
  if m.replayCaptionEnd <> 0 and m.playerPosition >= m.replayCaptionEnd
    cancelReplayCaptions()
  end if

  ' Analytics
  if m.playerPosition >= m.lastPingTime + m.analyticsInterval then
    playProgressEvent = getPlayProgressEvent()
    m.lastPingTime = m.playerPosition

    trackEvent(playProgressEvent)
  end if

  ' User history
  ' NOTE: historyPosition should not be set near an ad break due to race condition where RAF being
  ' invoked will cause the AuthTask thread to get stuck, never completing and staying in a "run"
  ' state perpetually.
  if (m.playerPosition > m.lastsavedPosition + m.historyInterval or m.playerPosition < m.lastsavedPosition - m.historyInterval) and m.top.adState <> "adspending"
    historyPosition()
  end if

  if (m.top.content.creditsCuePoint <> invalid and m.top.content.creditsCuePoint > 0 and m.playerPosition = m.top.content.creditsCuePoint)
    m.top.creditsPosition = m.playerPosition
  end if

  'Advertisements
  if m.top.enableAds and m.top.midrolls <> invalid and m.top.midrolls.count() > 0 then
    m.AdHeadsUp.visible = false  ' default to AdHeadsUp being off; this will catch ff, replay, rew during the countdown
    for each cuepoint in m.top.midrolls

      if m.playerPosition = (cuepoint - m.adPrefetchTime)
        m.top.adPosition = m.playerPosition
        m.top.adControl = "midroll"
      end if

      if m.playerPosition >= (cuepoint - m.adHeadsUpTime) and m.playerPosition < cuepoint and m.top.adState = "adspending"
        if m.Overlay.opacity = 0
          ' Don't show the ad heads up when the transport/overlay is showing, since it crowds the space of the title on the overlay
          m.AdHeadsUp.visible = true
          m.AdHeadsUpText.text = " " + Chr(&hb7) + " Starts in " + stri(cuepoint - m.playerPosition).trim() + " s"
        end if
      end if

      ' Fire up the midroll
      if m.playerPosition = cuepoint
        if m.top.adState = "adspending" then
          ' We must stop the video here, not just pause it, in order to release
          ' system resources to the RAF video player
          showAdBreak()
        else if m.top.adState = "noads"
          ' when we reach the cuepoint, we find that the last ad call returned no ads
          trackEvent({
            trackType: "resumeAfterAds"
            value: m.playerPosition
            ctx: m.top.content.id
          })
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
    value = "on"
  else  'handles "Off", "Instant replay", and "When mute"
    fade(m.CCRailOn, "out", 0.5)
    fade(m.CCRailOff, "in", 0.5)
    slideTo(m.CCNipple, m.CCNippleOffTranslation, 0.5)
    value = "off"
  end if
  
  if m.Video.content <> invalid then
    trackEvent({
      trackType: "subtitles"
      ctx: m.Video.content.id
      value: value
      extraCtx: {
        livetv: m.Video.content.isLiveTV
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
    trackEvent({
      trackType: "startTrailer"
      value: m.Video.content.id
    })
  else
    extraCtx = {subtitles: m.Video.content.showSubtitles}

    if m.top.analyticsMode = "autoplay"
      extraCtx.autoplay = true
    else if m.top.analyticsMode = "onnow-autoplay" 
      'onnow-autoplay signifies the onnow video started without input from the user (ie. when the on now screen loads)
      extraCtx.on_now = true
      extraCtx.livetv = true  'server uses this flag to determine if viewing should be part of CVT
    else if m.top.analyticsMode = "onnow-engaged"
      'onnow-engaged signifies the on now video started while the user has been "engaged" (ie. they selected an on now video, or an on now video autoplayed)
      extraCtx.on_now = true
    else if m.top.analyticsMode = "onnow-docked"
      'onnow-docked signifies the on now video started while while in docked mode
      extraCtx.on_now = true
      extraCtx.livetv = true
      extraCtx.embedded = true
    end if

    trackEvent({
      trackType: "videoPlay"
      value: m.Video.content.id
      ctx: m.Video.content.nowPos
      extraCtx: extraCtx
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
    if m.Video.state <> "error" or m.Video.position > 0
      ' There is a bug in roku firmware 8.0 that causes an execution timeout if
      ' a video node's control is set to "stop" when the state is "error" and position = 0
      m.Video.control = "stop"
    end if
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

    if isButtonPressAllowed(key)
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
            goToEnd()
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
        if m.HUD.opacity = 0 and m.progressBarFocused = false and isActiveVideoState()
          handleSkipVideo(-10, m.progressBarFocused)

        'user is in skip ahead mode (the progress bar is focused) and wants to skip back.
        else if m.progressBarFocused = true and isActiveVideoState()
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
        if m.HUD.opacity = 0 and m.progressBarFocused = false and isActiveVideoState()
          handleSkipVideo(10, m.progressBarFocused)

        'user is in skip ahead mode (the progress bar is focused) and wants to skip ahead.
        else if m.progressBarFocused = true and isActiveVideoState()
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
        else if m.top.content <> invalid and m.top.content.isLiveTV = true then
          if m.top.hasFocus()
            focusVideoPicker(true)
          end if
        end if

      else if key = "down"
        if m.Overlay.opacity = 0
          showTransport()
        else if m.progressBarFocused = true
          button = m.TransportButtons.getChild(m.focusedButtonIndex)
          setFocusedButton(button)
        else if m.top.content <> invalid and m.top.content.isLiveTV = true then
          if not m.top.hasFocus()
            focusVideoPicker(false)
          end if
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
          endScrub()
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
  ' Midrolls are triggered from position changes since they are prefetched.  Other ad breaks have
  ' video playback stopped and should play right away when we get adspending.
  if m.top.adState = "adspending" and (m.top.adControl = "preroll" or m.top.adControl = "seek") and m.top.enableAds then
    ' pre-roll or resume-roll. Play ads right away
    showAdBreak()
  ' no ads were returned from preroll or resumeroll, or we just came back from an ad break.  Make sure we start playing
  'TODO(Chris): model the ad break more explicitly in m.VideoState so we're not trying to glean state from m.VideoState, m.Video.State, video control and ad control
  else if m.top.adState = "noads" and (m.VideoState = "play" or m.VideoState = "pause") and m.Video.state <> "playing" then
    ' Came back from an ad break
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
        trackType: "resumeAfterAds"
        value: m.playerPosition
        ctx: m.top.content.id
      })
    else
      m.top.errorMsg = "Video URL is not valid. Please contact: support@tubi.tv"
      m.top.state = "error"
      errorInfo = {
        video_id: m.top.content.id
        video_url: m.top.content.url
      }
      tubiLog(FormatJson(errorInfo), "error", "videoPlayback", "video-url")
    end if
  else if m.top.adState = "adsclosed"
    ' This is not ideal implementation but we want the OnNow experience to continue playing
    ' even if the user presses back during an ad.  We don't want to resume play under normal 
    ' VOD playback so we skip restarting the video. Resuming play in the VOD case was
    ' causing a bug where there was a very long black screen after exiting an ad break 
    ' via the back button (i assume the render thread was busy caching the video segments).
    m.top.setFocus(true)
    if m.Video.content.isLiveTV
      m.Video.seek = m.playerPosition
      m.Video.control = "play"
      trackEvent({
        trackType: "resumeAfterAds"
        value: m.Video.content.nowPos
        ctx: m.Video.content.id
        extraCtx: {
          livetv: m.Video.content.isLiveTV
        }
      })
    end if

    backButtonExit()
  end if
End Function


' Helper function to prevent tracking events being sent for trailers
Function trackEvent(event As Object)
  if m.top.analyticsMode <> "trailer" or event.trackType = "startTrailer" then
    m.global.trackingLoggingTask.trackEvent = event
  end if
End Function


' Helper function to prevent historyPosition being sent during  trailers
Function historyPosition()
  if m.top.analyticsMode = "normal" or m.top.analyticsMode = "autoplay" then
    m.top.historyPosition = m.playerPosition
    m.lastSavedPosition = m.playerPosition
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
  tubiLog("VideoPlayer.AnimateTransport")
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
  tubiLog("VideoPlayerFocusVideoPicker")
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
    trackType: "pauseToggle"
    ctx: m.Video.content.id
    value: "paused"
    extraCtx: {
      livetv: m.Video.content.isLiveTV
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
      trackType: "pauseToggle"
      ctx: m.Video.content.id
      value: "resumed"
      extraCtx: {
        livetv: m.Video.content.isLiveTV
      }
    })
  end if

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
  if m.top.content.thumbnailUrls <> invalid and m.top.content.thumbnailUrls.count() > 0 and m.constants.deviceInfo.limitedUi = false
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
    animateTransport("in")
  end if
  showThumbnail()
  m.scrubTimespan.mark()

  ' playProgress analytics
  playProgressEvent = getPlayProgressEvent()
  trackEvent(playProgressEvent)
End Function


'Perform at end of FF or RW
Function endScrub()
  m.scrubAmt = -1 'reset just in case it somehow got to less than -1
  m.ScrubTimer.control = "stop"
  m.ScrubTimer.unobserveField("fire")
  oldVideoState = m.VideoState
  m.VideoState = "play"
  ' Reset periodic event trackers
  m.lastPingTime = m.playerPosition

  resetTransportButtons()
  m.PlayPauseButton.uri = m.buttonUris.pause
  m.PlayPauseButton.focusState = true

  shouldAdBreak = false
  if m.top.enableAds and oldVideoState = "ffw" then
    shouldAdBreak = true
  end if

  handleSeek(m.playerPosition, shouldAdBreak)
End Function


'handles the Skip Trailer selection
'triggers callback on ContentController to play the full video
Function handleSkipTrailer()
  m.top.skipTrailer = true
  setFocusedButton(m.PlayPauseButton)
End Function


'handles StartButton selection
'moves the player to the 0:00:00 position
Function goToStart()
  if m.VideoState = "ffw" or m.VideoState = "rew"
    endScrub()
    setFocusedButton(m.StartButton)
  end if
  jumpToPosition(0)
End Function


'handles EndButton selection
'moves the player to 5 seconds before the end of the video
Function goToEnd()
  if m.VideoState = "ffw" or m.VideoState = "rew"
    endScrub()
    setFocusedButton(m.EndButton)
  end if
  if not advancePlaylist() then
    'the end of the video playback
    m.VideoState = "stop"
    m.video.control = "stop"
    m.top.state = "finished"
  end if
End Function


'handles play key press or PlayPause button selection
Function handlePlayPause()
  tubiLog("VideoPlayer.handlePlayPause VideoState = " + m.VideoState)
  if m.VideoState = "play" then
    pauseVideo(true)
  else if m.VideoState = "pause" then
    resumeFromPause()
  else if m.VideoState = "rew" or m.VideoState = "ffw"
    endScrub()
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
    beginScrub()
    m.VideoState = "ffw"
    m.FastForwardButton.uri = m.buttonUris.fastForwardLevels[0]
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
    beginScrub()
    m.VideoState = "rew"
    m.RewindButton.uri = m.buttonUris.rewindLevels[0]
  end if

  setFocusedButton(m.RewindButton, true)
End Function


'handles HopForward button selection
Function handleHopForward()
  if m.VideoState = "ffw" or m.VideoState = "rew"
    endScrub()
    setFocusedButton(m.HopForwardButton)
  end if
  if m.HUD.opacity > 0.0
    animateTransport("out")
  end if
  jumpToPosition(m.playerPosition + 30)
End Function


'handles HopBack button selection
Function handleHopBack(remoteReplayButton)
  setFocusedButton(m.HopBackButton)  'necessary because there is a dedicated hop back button on certain roku remotes
  if m.VideoState = "ffw" or m.VideoState = "rew"
    endScrub()
  end if
  setFocusedButton(m.HopBackButton, true)
  if m.HUD.opacity > 0.0
    animateTransport("out")
  end if
  oldPosition = m.playerPosition
  jumpToPosition(m.playerPosition - 30)
  if remoteReplayButton and m.Video.globalCaptionMode = "Instant replay"
    tubilog("Turning on replay captions")
    m.replayCaptionEnd = oldPosition
    m.video.globalCaptionMode = "On"
  end if
End Function


'helper function to conclude a hop, skip, or end scrub
'performs the seek tracking and runs an ad break if told to
Function handleSeek(position as Integer, shouldAdBreak as Boolean)
  m.Thumbnail.visible = false
  ' seek analytics
  trackEvent({
    trackType: "seek"
    value: position
    ctx: m.top.content.id
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
  if m.VideoState <> "pause"
    m.Video.control = "pause"
    m.VideoState = "pause"
    m.PlayPauseButton.uri = m.buttonUris.play
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
Function jumpToPosition(position)
  cancelReplayCaptions() ' on any jump we cancel any temporary caption modifications

  if position > (m.Video.duration - 5)
    position = m.Video.duration - 5
  else if position < 0
    position = 0
  end if

  shouldAdBreak = false
  if m.top.enableAds and position > m.playerPosition
    shouldAdBreak = true
  end if

  m.playerPosition = position
  m.PlayPauseButton.uri = m.buttonUris.pause

  handleSeek(position, shouldAdBreak)
End Function


'Finds the 'index' of the passed in transport button node and sets it on m.focusedButtonIndex
'Additionally updates the image of the button to the focused version and all other buttons to the unfocused version
'
' If keyFocus is true it will forcefully set focus to the transport
Function setFocusedButton(TransportButton, keyFocus=false)
  if keyfocus
    focusVideoPicker(false)
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

  if TransportButton.id = "ProgressBarForeground"
    m.progressBarFocused = true
    m.ProgressBar.blendColor = m.focusedColor
  else
    m.progressBarFocused = false
    m.ProgressBar.blendColor = "0xFFFFFFFF"
  end if
End Function

'exit the video player due to back button while no transport displaying, or during ad break
Function backButtonExit()
  historyPosition()
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


Function getPlayProgressEvent()
  extraCtx = {
    interval: m.playerPosition - m.lastPingTime
  }

  if m.top.analyticsMode = "autoplay"
    extraCtx.autoplay = true
  else if m.top.analyticsMode = "onnow-autoplay"
    extraCtx.on_now = true
    extraCtx.livetv = true
  else if m.top.analyticsMode = "onnow-engaged"
    extraCtx.on_now = true
  else if m.top.analyticsMode = "onnow-docked"
    extraCtx.embedded = true
    extraCtx.on_now = true
    extraCtx.livetv = true
  end if

  if m.top.deeplinkSource <> ""
    extraCtx.casting = m.top.deeplinkSource
  end if

  return {
    trackType: "playProgress"
    ctx: m.Video.content.id
    value: m.playerPosition
    extraCtx: extraCtx
  }
End Function


' Helper function to determine if we should ignore or handle a button press
' We don't want to handle button presses that affect video playback when the video is not loaded
' Moving focus around the transport is ok though
Function isButtonPressAllowed(key)
  disabledKeys = {
    OK: true
    rewind: true
    fastforward: true
    play: true
    replay: true
    options: true
  }

  if not isActiveVideoState() and disabledKeys[key] = true
    return false
  else
    return true
  end if
End Function


' Helper function to determine if the video state is such that we should handle button presses
' Currently we don't want to handle most button presses when m.VideoState is in the "refresh" or "stop" states
Function isActiveVideoState()
  disactiveStates = {
    refresh: true
    stop: true
  }

  if disactiveStates[m.VideoState] = true
    return false
  else
    return true
  end if
End Function
