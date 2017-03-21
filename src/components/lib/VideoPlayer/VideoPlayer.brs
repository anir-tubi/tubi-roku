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
'   User History tracking:
'
'      - when user exits the ad or video by pressing 'back'
'      - right before a mid-roll
'      - every 60 seconds of watching
'


Function init()
  tubiLog("VideoPlayer.init")
  m.Spinner = m.top.findNode("BufferSpinner")
  m.Transport = m.top.findNode("Transport")
  m.Video = m.top.findNode("VideoNode")  ' reference in case we change from extending Video to extending Group
  m.Video.observeField("position", "onVideoPositionChange")
  m.top.observeField("control", "onControlChange")
  m.top.observeField("content", "onContentChange")
  m.ElapsedLabel = m.top.findNode("ElapsedLabel")
  m.RemainingLabel = m.top.findNode("RemainingLabel")
  m.ProgressBar = m.top.findNode("ProgressBarForeground")
  m.Overlay = m.top.findNode("VideoOverlay")
  m.ScrubTimer = m.top.findNode("ScrubTimer")

  'm.VideoState is source of truth for the state of the video player for the UI
  'possible values are "play", "pause", "rew", "ffw", "stop"
  m.VideoState = "stop"
  m.scrubAmt = -1
  m.playerPosition = 0
  m.maxScrub = m.global.constants.player.maxScrub
  m.scrubMultipliers = m.global.constants.player.scrubMultipliers
  m.scrubTimespan = CreateObject("roTimespan")
  m.lastButtonPressPos = 0
  m.transportAutoHideTime = m.global.constants.player.transportAutoHideTime
  m.ignoreOptionsKey = m.global.constants.deviceInfo.firmwareCaptionMenu

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
  m.buttonUris = m.global.constants.player.transportButtons
  m.focusedButtonIndex = 0
  setFocusedButton(m.PlayPauseButton)
  m.ClosedCaptionDisabled = m.top.findNode("ClosedCaptionDisabled")

  m.Video.observeField("bufferingStatus", "onBufferStatus")
  m.Video.observeField("globalCaptionMode", "onCaptionModeChange")
  m.top.observeField("adState", "onAdStateChange")

  m.lastPingTime = 0
  m.lastSavedPosition = 0
  m.adPrefetchTime = 5

  m.analyticsInterval = m.global.constants.player.pingFrequency
  m.historyInterval = m.global.constants.player.historyFrequency

  'if global captions are turned on, slide the closed caption toggle to on position
  m.CCSlideAmt = 31
  if m.Video.globalCaptionMode = "On"
    m.CCRailOn.opacity = 1.0
    m.CCRailOff.opacity = 0.0
    m.CCNipple.translation = [m.CCNipple.translation[0] + m.CCSlideAmt, m.CCNipple.translation[1]]
  end if
End Function


Function onBufferStatus()
  if m.Video.bufferingStatus <> invalid
    m.Spinner.visible = true
  else
    m.Spinner.visible = false
  end if
End Function


Function onContentChange()
  tubiLog("VideoPlayer.onContentChange")
  'there are no subtitles so grey out the captions button
  if m.top.content.subtitleUrls.count() = 0
    m.TransportButtons.removeChild(m.ClosedCaption)
    m.ClosedCaptionDisabled.visible = true
  
  'there are subtitles, so check if captions button has been greyed out previously
  else if doesChildExist(m.TransportButtons, m.ClosedCaption) = false
    m.TransportButtons.appendChild(m.ClosedCaption)
    m.ClosedCaptionDisabled.visible = false
  end if

  liveTVGroup = m.top.findNode("LiveTVGroup")
  if m.top.content.isLiveTV then
    liveTVGroup.visible = true
    m.HopForwardButton.enabled = false
    m.FastForwardButton.enabled = false
    m.EndButton.enabled = false
  else
    liveTVGroup.visible = false
    m.HopForwardButton.enabled = true
    m.FastForwardButton.enabled = true
    m.EndButton.enabled = true
  end if

  'if it's not a trailer, remove the skip trailer button
  if m.top.content.isTrailer = false
    m.TransportButtons.removeChild(m.SkipTrailerButton)
    setFocusedButton(m.PlayPauseButton)

  'add the skip trailer button if it's a trailer and it doesn't already exist on the transport
  else if doesChildExist(m.TransportButtons, m.SkipTrailerButton) = false
    m.TransportButtons.insertChild(m.SkipTrailerButton, 0)
  end if
End Function


' m.playerPosition is the main source of truth for position.
' It can be updated by the video node or by calculations made while scrubbing
Function updatePlayerPosition()
  m.playerPosition = m.Video.position
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
    m.ProgressBar.width = minWidth + (m.playerPosition / m.Video.duration) * (maxWidth - minWidth)
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
  if m.VideoState = "play" and m.Transport.opacity > 0 and m.playerPosition > m.lastButtonPressPos + m.transportAutoHideTime
    animateTransport("out")
  end if

  ' Analytics
  if m.playerPosition >= m.lastPingTime + m.analyticsInterval then
    trackEvent({
      trackType: "playProgress"
      ctx: m.Video.content.id
      value: m.playerPosition
      extraCtx: {
        interval: m.playerPosition - m.lastPingTime
        livetv: m.Video.content.isLiveTV
      }
    })
    m.lastPingTime = m.playerPosition
  end if

  ' User history
  if m.playerPosition > m.lastsavedPosition + m.historyInterval or m.playerPosition < m.lastsavedPosition - m.historyInterval
    historyPosition()
  end if

  if m.top.enableAds and m.top.midrolls <> invalid and m.top.midrolls.count() > 0 then
    for each cuepoint in m.top.midrolls

      if m.playerPosition = (cuepoint - m.adPrefetchTime)
        m.top.adControl = "midroll"
      end if

      ' Fire up the midroll
      if m.playerPosition = cuepoint and m.top.adState = "adspending" then
        ' We must stop the video here, not just pause it, in order to release
        ' system resources to the RAF video player
        showAdBreak()
        ' store latest history
        historyPosition()
      end if
    end for
  end if 
End Function


Function onCaptionModeChange()
  tubiLog("VideoPlayer.onCaptionModeChange")
  if m.Video.globalCaptionMode = "On"
    fade(m.CCRailOn, "in", 0.5)
    fade(m.CCRailOff, "out", 0.5)
    slideTo(m.CCNipple, [m.CCNipple.translation[0] + m.CCSlideAmt, m.CCNipple.translation[1]], 0.5)
    value = "on"
  else  'handles "Off", "Instant replay", and "When mute"
    fade(m.CCRailOn, "out", 0.5)
    fade(m.CCRailOff, "in", 0.5)
    slideTo(m.CCNipple, [m.CCNipple.translation[0] - m.CCSlideAmt, m.CCNipple.translation[1]], 0.5)
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

Function onControlChange()
  tubiLog("VideoPlayer.onControlChange")
  if m.Video.content <> invalid and m.Video.state <> "playing" and m.top.control = "play" then
    if m.Video.content.nowPos <> invalid then
      m.Video.seek = m.Video.content.nowPos
      m.playerPosition = m.Video.content.nowPos
      m.lastSavedPosition = m.Video.content.nowPos
      m.lastPingTime = m.Video.content.nowPos
    else
      m.lastPingTime = 0
      m.lastSavedPosition = 0
    end if
    m.top.midrolls = []  ' Always reset midrolls when we first start playback.  Preroll will populate these
    m.VideoState = "play"
    
    if m.video.content.isLiveTV = false then
      trackEvent({
        trackType: "videoPlay"
        value: m.Video.content.id
        ctx: m.Video.content.nowPos
        extraCtx: {
          subtitles: m.Video.content.showSubtitles
        }
      })
    end if

    if m.top.enableAds then
      ' Start pre-roll fetch
      m.top.adControl = "preroll"
    else
      m.Video.control = "play"
      m.top.adControl = "cuepoints"
    end if
  else if m.top.control = "stop" then
    'TODO: If ad break is happening, abort it.  I don't think it's possible, though
    m.Video.control = "stop"
    m.VideoState = "stop"
  else if m.top.control = "pause" then
    m.Video.control = "pause"
    m.VideoState = "pause"
  end if
End Function

Function onKeyEvent(key As String, press As Boolean)
  tubiLog("VideoPlayer.onKeyEvent key = " + key)
  if press
    m.lastButtonPressPos = m.playerPosition

    if key = "OK"
      if m.Transport.opacity = 0
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
          handleHopBack()
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
        handleHopBack()
      end if

    else if key = "options"
      if m.ignoreOptionsKey = false then
        handleClosedCaption()
      end if

    else if key = "left"
      if m.Transport.opacity = 0
        showTransport()

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
      if m.Transport.opacity = 0
        showTransport()

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

    else if key = "up" or key = "down"
      if m.transport.opacity = 0
        showTransport()
      else
        if m.top.content.isLiveTV then
          m.top.upButtonPressed = true
          animateTransport("out")
        end if
      end if

    else if key = "back" then
      if m.VideoState = "play"
        if m.transport.opacity = 0
          backButtonExit()

        else if m.transport.opacity > 0
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
  else if m.top.adState = "noads" and m.VideoState = "play" and m.Video.state <> "playing" and m.Video.state <> "buffering" then
    ' came back from an ad break
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
  else if m.top.adState = "adsclosed"
    backButtonExit()
  end if
End Function


' Helper function to check enableTracking field before sending tracking events
Function trackEvent(event As Object)
  if m.top.enableTracking then
    m.global.trackingLoggingTask.trackEvent = event
  end if
End Function


' Helper function to check enableTracking before updating historyPosition
Function historyPosition()
  if m.top.enableTracking then
    m.top.historyPosition = m.playerPosition
    m.lastSavedPosition = m.playerPosition
  end if
End Function


'show transport
Function showTransport()
  resetTransportButtons()
  m.PlayPauseButton.focusedUri = m.buttonUris.pauseFocus
  m.PlayPauseButton.unfocusedUri = m.buttonUris.pause
  setFocusedButton(m.PlayPauseButton)
  animateTransport("in")
End Function


'aggregates all the animation for showing/hiding the transport
'@direction: string, value may be "out" or "in"
Function animateTransport(direction)
  slideFade(m.Transport, "below", direction, 0.6)
  fade(m.Overlay, direction, 0.6)
End Function


'load Video player and play
Function playVideo()
  m.Video.control = "play"
  m.VideoState = "play"
  animateTransport("out")
End Function


'pause the video player
Function pauseVideo()
  m.Video.control = "pause"
  m.VideoState = "pause"
  m.PlayPauseButton.focusedUri = m.buttonUris.playFocus
  m.PlayPauseButton.unfocusedUri = m.buttonUris.play
  setFocusedButton(m.PlayPauseButton)

  if m.Transport.opacity < 1.0
    animateTransport("in")
  end if
  
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
  m.PlayPauseButton.focusedUri = m.buttonUris.pauseFocus
  m.PlayPauseButton.unfocusedUri = m.buttonUris.pause
  setFocusedButton(m.PlayPauseButton)

  animateTransport("out")
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
End Function


Function resetTransportButtons()
  m.SkipTrailerButton.focusState = false

  m.StartButton.focusState = false

  m.RewindButton.focusedUri = m.buttonUris.rewindFocus
  m.RewindButton.unfocusedUri = m.buttonUris.rewind
  m.RewindButton.focusState = false

  m.HopBackButton.focusState = false

  m.PlayPauseButton.focusedUri = m.buttonUris.playFocus
  m.PlayPauseButton.unfocusedUri = m.buttonUris.play
  m.PlayPauseButton.focusState = false

  m.HopForwardButton.focusState = false

  m.FastForwardButton.focusedUri = m.buttonUris.fastForwardFocus
  m.FastForwardButton.unfocusedUri = m.buttonUris.fastForward
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


'Perform at start of FF or RW
Function beginScrub()
  m.Video.control = "pause"
  m.scrubAmt = 0
  resetTransportButtons()
  m.ScrubTimer.observeField("fire", "updateScrubTime")
  m.ScrubTimer.control = "start"

  if m.Transport.opacity < 1.0
    animateTransport("in")
  end if
  m.scrubTimespan.mark()
End Function


'Perform at end of FF or RW
Function endScrub()
  m.scrubAmt = -1 'reset just in case it somehow got to less than -1
  m.ScrubTimer.control = "stop"
  m.ScrubTimer.unobserveField("fire")
  m.VideoState = "play"
  ' Resent periodic event trackers
  m.lastSavedPosition = m.playerPosition
  m.lastPingTime = m.playerPosition

  resetTransportButtons()
  m.PlayPauseButton.unfocusedUri = m.buttonUris.pause
  m.PlayPauseButton.focusedUri = m.buttonUris.pauseFocus
  m.PlayPauseButton.focusState = true

  ' resume ad break
  if m.top.enableAds then
    m.Video.control = "stop"
    m.top.content.nowPos = m.playerPosition
    m.top.adControl = "seek"
  else
    m.Video.seek = m.playerPosition 'will load and play the video at the seeked to point
  end if
End Function


'handles the Skip Trailer selection
'triggers callback on ContentController to play the full video
Function handleSkipTrailer()
  m.top.skipTrailer = true
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
  jumpToPosition(m.Video.duration - 5)
End Function


'handles play key press or PlayPause button selection
Function handlePlayPause()
  if m.VideoState = "play" then
    pauseVideo()
  else if m.VideoState = "pause" then
    resumeFromPause()
  else if m.VideoState = "rew" or m.VideoState = "ffw"
    setFocusedButton(m.PlayPauseButton)
    endScrub()
  end if
End Function


'handles fast forward key press or FastForward button selection
Function handleFastForward()
  'begin fast forwarding, but don't need everything in beginScrub()
  if m.VideoState = "rew"
    m.VideoState = "ffw"
    m.scrubAmt = 0
    m.RewindButton.focusedUri = m.buttonUris.rewindFocus
    m.RewindButton.unfocusedUri = m.buttonUris.rewind
    m.FastForwardButton.focusedUri = m.buttonUris.fastForwardLevelsFocus[0]
    m.FastForwardButton.unfocusedUri = m.buttonUris.fastForwardLevels[0]

  'increase the fast forward speed
  else if m.VideoState = "ffw"
    if m.scrubAmt < m.maxScrub
      m.scrubAmt = m.scrubAmt + 1
    else
      m.scrubAmt = 0
    end if
    m.FastForwardButton.focusedUri = m.buttonUris.fastForwardLevelsFocus[m.scrubAmt]
    m.FastForwardButton.unfocusedUri = m.buttonUris.fastForwardLevels[m.scrubAmt]

  'start the fast forward
  else
    beginScrub()
    m.VideoState = "ffw"
    m.FastForwardButton.focusedUri = m.buttonUris.fastForwardLevelsFocus[0]
    m.FastForwardButton.unfocusedUri = m.buttonUris.fastForwardLevels[0]
  end if

  setFocusedButton(m.FastForwardButton)
End Function


'handles rewind key press or Rewind button selection
Function handleRewind()
  'begin rewinding, but don't need everything in beginScrub()
  if m.VideoState = "ffw"
    m.VideoState = "rew"
    m.scrubAmt = 0
    m.FastForwardButton.focusedUri = m.buttonUris.fastforwardFocus
    m.FastForwardButton.unfocusedUri = m.buttonUris.fastforward
    m.RewindButton.focusedUri = m.buttonUris.rewindLevelsFocus[0]
    m.RewindButton.unfocusedUri = m.buttonUris.rewindLevels[0]

  'increase the rewind speed
  else if m.VideoState = "rew"
    if m.scrubAmt < m.maxScrub
      m.scrubAmt = m.scrubAmt + 1
    else
      m.scrubAmt = 0
    end if
    m.RewindButton.focusedUri = m.buttonUris.rewindLevelsFocus[m.scrubAmt]
    m.RewindButton.unfocusedUri = m.buttonUris.rewindLevels[m.scrubAmt]

  'start the rewind
  else
    beginScrub()
    m.VideoState = "rew"
    m.RewindButton.focusedUri = m.buttonUris.rewindLevelsFocus[0]
    m.RewindButton.unfocusedUri = m.buttonUris.rewindLevels[0]
  end if

  setFocusedButton(m.RewindButton)
End Function


'handles HopForward button selection
Function handleHopForward()
  if m.VideoState = "ffw" or m.VideoState = "rew"
    endScrub()
    setFocusedButton(m.HopForwardButton)
  end if
  jumpToPosition(m.playerPosition + 30)
End Function


'handles HopBack button selection
Function handleHopBack()
  setFocusedButton(m.HopBackButton)  'necessary because there is a dedicated hop back button on certain roku remotes
  if m.VideoState = "ffw" or m.VideoState = "rew"
    endScrub()
    setFocusedButton(m.HopBackButton)
  end if
  jumpToPosition(m.playerPosition - 30)
End Function


'handles ClosedCaption button/toggle selection
Function handleClosedCaption()
  if m.Transport.opacity < 1.0
    animateTransport("in")
  end if

  setFocusedButton(m.ClosedCaption)

  'setting the globalCaptionMode will trigger a callback that updates the images and does user tracking
  if m.Video.globalCaptionMode = "On"
    m.Video.globalCaptionMode = "Off"
  else ' If "When mute" or "Instant replay", also turn it on
    m.Video.globalCaptionMode = "On"
  end if
End Function


'handles replay key press or HopBack button selection
Function jumpToPosition(position)
  if position > (m.Video.duration - 5)
    position = m.Video.duration - 5
  else if position < 0
    position = 0
  end if

  m.playerPosition = position
  m.Video.seek = position
  m.VideoState = "play"

  m.PlayPauseButton.focusedUri = m.buttonUris.pauseFocus
  m.PlayPauseButton.unfocusedUri = m.buttonUris.pause
End Function


'Finds the 'index' of the passed in transport button node and sets it on m.focusedButtonIndex
'Additionally updates the image of the button to the focused version and all other buttons to the unfocused version
Function setFocusedButton(TransportButton)
  for i=0 to m.TransportButtons.getChildCount()-1
    button = m.TransportButtons.getChild(i)
    if TransportButton.id = button.id
      m.focusedButtonIndex = i
      button.focusState = true
    else
      button.focusState = false
    end if
  end for
End Function

'exit the video player due to back button while no transport displaying, or during ad break
Function backButtonExit()
  historyPosition()
  ' minor detail... set backButtonPressed first so that observers get that event before any video state change
  m.top.backButtonPressed = true
End Function

' Make sure the Video node is stopped and we have an accurate playback position before launching ads
Function showAdBreak()
  m.Video.control = "stop"
  m.top.content.nowPos = m.playerPosition
  m.top.adControl = "play"
End Function
