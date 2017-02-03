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
'      - every 60 seconds of watching (hard-coded in TubiPlayer.brs)
'


Function init()
  tubiLog("VideoPlayer.init")
  m.BufferText = m.top.findNode("BufferText")
  m.Transport = m.top.findNode("Transport")
  m.Video = m.top.findNode("VideoNode")  ' reference in case we change from extending Video to extending Group
  m.ElapsedLabel = m.top.findNode("ElapsedLabel")
  m.RemainingLabel = m.top.findNode("RemainingLabel")
  m.ProgressBar = m.top.findNode("ProgressBarForeground")
  m.ScrubTimer = m.top.findNode("ScrubTimer")

  'm.VideoState is source of truth for the state of the video player for the UI
  'possible values are "play", "pause", "rew", "ffw"
  m.VideoState = m.Video.state
  m.scrubAmt = -1
  m.playerPosition = 0
  m.maxScrub = m.global.constants.player.maxScrub
  m.scrubMultipliers = m.global.constants.player.scrubMultipliers
  m.scrubTimespan = CreateObject("roTimespan")

  'buttons
  m.TransportButtons = m.top.findNode("TransportButtons")
  m.StartButton = m.TransportButtons.findNode("StartButton")
  m.RewindButton = m.TransportButtons.findNode("RewindButton")
  m.HopBackButton = m.TransportButtons.findNode("HopBackButton")
  m.PlayPauseButton = m.TransportButtons.findNode("PlayPauseButton")
  m.HopForwardButton = m.TransportButtons.findNode("HopForwardButton")
  m.FastForwardButton = m.TransportButtons.findNode("FastForwardButton")
  m.EndButton = m.TransportButtons.findNode("EndButton")
  m.buttonUris = m.global.constants.player.transportButtons
  m.defaultButton = 3
  m.focusedButtonIndex = m.defaultButton

  m.Video.observeField("bufferingStatus", "onBufferStatus")
  m.Video.observeField("position", "updatePlayerPosition")
  m.top.observeField("content", "onContentChange")
  m.Video.observeField("globalCaptionMode", "onCaptionModeChange")

  m.lastPingTime = 0
  m.lastsavedPosition = 0

  m.analyticsInterval = m.global.constants.player.pingFrequency
  m.historyInterval = m.global.constants.player.historyFrequency
End Function


Function onBufferStatus()
  if m.Video.bufferingStatus <> invalid
    m.BufferText.visible = true
    text = "Loading... " 
    if m.Video.bufferingStatus.percentage <> invalid
      text = text + m.Video.bufferingStatus.percentage.toStr() + "%"
    end if
    text = text + Chr(10) + m.Video.content.title
    m.BufferText.text = text
  else
    m.BufferText.visible = false
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
  ' only update the transport when it's visible
  if m.Transport.visible = true then

    'update the position and remaining time text
    updateTransportTimes()

    'update the position bar width
    if m.Video.duration > 0
      maxWidth = m.top.findNode("ProgressBarBackground").width
      m.ProgressBar.width = (m.playerPosition / m.Video.duration) * maxWidth
    end if
  end if
End Function


'''''''''''''''''''''''''
' onVideoPositionChange
'
' The notificationInterval and analyticsInterval are not necessarily equal or evenly divisible
' so we check the time passage before we send playProgress events
Function onVideoPositionChange()
  tubiLog("VideoPlayer.onVideoPositionChange")
  if m.Video.position >= m.lastPingTime + m.analyticsInterval then
    m.global.trackingLoggingTask.trackEvent = {
      trackType: "playProgress"
      ctx: m.Video.content.id
      value: m.playerPosition
      extraCtx: {
        interval: m.playerPosition - m.lastPingTime
      }
    }
    m.lastPingTime = m.playerPosition
    'TODO(Chris): When scrubbing shows up, lastPingTime should be reset once playback resumes
  end if

  if m.playerPosition > m.lastsavedPosition + m.historyInterval or m.playerPosition < m.lastsavedPosition - m.historyInterval
    m.top.historyPosition = m.playerPosition
    m.lastSavedPosition = m.playerPosition
  end if
End Function


Function onCaptionModeChange()
  tubiLog("VideoPlayer.onCaptionModeChange")
  if m.Video.content <> invalid then
    if m.Video.globalCaptionMode <> "Off" then
      value = "off"
    else
      value = "on"
    end if
    m.global.trackingLoggingTask.trackEvent = {
      trackType: "subtitles"
      ctx: m.Video.content.id
      value: value
    }
  end if
End Function


Function onContentChange()
  tubiLog("VideoPlayer.onContentChange")
  if m.Video.content <> invalid and m.Video.state <> "playing" then
    if m.Video.content.nowPos <> invalid then
      m.Video.seek = m.Video.content.nowPos
    end if

    m.lastsavedPosition = m.Video.content.nowPos
    m.Video.control = "play"
    m.VideoState = "play"
    
    m.global.trackingLoggingTask.trackEvent = {
      trackType: "videoPlay"
      value: m.Video.content.id
      ctx: m.Video.content.nowPos
      extraCtx: {
        subtitles: m.Video.content.showSubtitles
        livetv: false  ' TODO(Chris): remove this if unnecessary
      }
    }
  end if
End Function

Function onKeyEvent(key As String, press As Boolean)
  tubiLog("VideoPlayer.onKeyEvent key = " + key)
  if press 
    if key = "OK"
      if m.Transport.visible = false
        showTransport()
      else
        'do action based on the current focused button
        focusButtonId = m.TransportButtons.getChild(m.focusedButtonIndex).id
        if focusButtonId = m.StartButton.id
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
        end if
      end if
 
    else if key = "play" then
      handlePlayPause()

    else if key = "fastforward"
      handleFastForward()     

    else if key = "rewind"
      handleRewind()

    else if key = "replay"
      handleHopBack()

    else if key = "left"
      if m.Transport.visible = false
        showTransport()

      else
        'navigate the transport buttons
        if m.focusedButtonIndex - 1 >= 0
          currentButton = m.TransportButtons.getChild(m.focusedButtonIndex)
          currentButton.focusState = false
          
          m.focusedButtonIndex = m.focusedButtonIndex - 1
          newCurrentButton = m.TransportButtons.getChild(m.focusedButtonIndex)
          newCurrentButton.focusState = true
        end if
      end if

    else if key = "right"
      if m.Transport.visible = false
        showTransport()

      else    
        'navigate the transport buttons
        if m.focusedButtonIndex + 1 < m.TransportButtons.getChildCount()
          currentButton = m.TransportButtons.getChild(m.focusedButtonIndex)
          currentButton.focusState = false
          
          m.focusedButtonIndex = m.focusedButtonIndex + 1
          newCurrentButton = m.TransportButtons.getChild(m.focusedButtonIndex)
          newCurrentButton.focusState = true
        end if
      end if

    else if key = "up" or key = "down"
      if m.transport.visible = false
        showTransport()
      end if

    else if key = "back" then
      if m.VideoState = "play"
        if m.Transport.visible = false
          'exit the video player
          m.top.backButtonPressed = true

        else if m.Transport.visible = true
          'close the transport
          m.Transport.visible = false
          resetTransportButtons()
          ' m.PlayPauseButton.uri = m.buttonUris.play
        end if

      else if m.VideoState = "pause"
        resumeFromPause()

      else if m.VideoState = "rew" or m.VideoState = "ffw"
        endScrub()
      end if
    end if
  end if
  ' Consume all key presses
  return true
End Function


'show transport
Function showTransport()
  m.PlayPauseButton.focusedUri = m.buttonUris.pauseFocus
  m.PlayPauseButton.unfocusedUri = m.buttonUris.pause
  m.focusedButtonIndex = m.defaultButton
  m.PlayPauseButton.focusState = true
  updateTransportTimes()
  m.Transport.visible = true
End Function


'load Video player and play
Function playVideo()
  m.Video.control = "play"
  m.VideoState = "play"
  m.Transport.visible = false
End Function


'load pause the video player
Function pauseVideo()
  m.Video.control = "pause"
  m.VideoState = "pause"
  m.PlayPauseButton.focusedUri = m.buttonUris.playFocus
  m.PlayPauseButton.unfocusedUri = m.buttonUris.play
  m.PlayPauseButton.focusState = true
  m.focusedButtonIndex = m.defaultButton
  m.Transport.visible = true
  updateTransport()
  m.global.trackingLoggingTask.trackEvent = {
    trackType: "pauseToggle"
    ctx: m.Video.content.id
    value: "paused"
  }  
End Function


'Resume play from a paused state
Function resumeFromPause()
  m.Transport.visible = false
  m.Video.control = "resume"
  m.VideoState = "play"
  resetTransportButtons()
  m.PlayPauseButton.uri = m.buttonUris.play
  m.global.trackingLoggingTask.trackEvent = {
    trackType: "pauseToggle"
    ctx: m.Video.content.id
    value: "resumed"
  }
End Function


Function resetTransportButtons()
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
  m.Transport.visible = true
  m.scrubTimespan.mark()
End Function


'Perform at end of FF or RW
Function endScrub()
  m.scrubAmt = -1 'reset just in case it somehow got to less than -1
  m.ScrubTimer.control = "stop"
  m.ScrubTimer.unobserveField("fire")
  m.Video.seek = m.playerPosition 'will load and play the video at the seeked to point
  m.Transport.visible = false
  m.VideoState = "play"
  resetTransportButtons()
  m.focusedButtonIndex = m.defaultButton
End Function


'handles StartButton selection
'moves the player to the 0:00:00 position
Function goToStart()
  jumpToPosition(0)
End Function


'handles EndButton selection
'moves the player to 5 seconds before the end of the video
Function goToEnd()
  jumpToPosition(m.Video.duration - 5)
End Function


'handles play key press or PlayPause button selection
Function handlePlayPause()
  if m.VideoState = "play" then
    pauseVideo()
  else if m.VideoState = "pause" then
    resumeFromPause()
  else if m.VideoState = "rew" or m.VideoState = "ffw"
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
    m.RewindButton.focusState = false
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

  'always remove focus from other buttons and add focus to fast forward button
  m.TransportButtons.getChild(m.focusedButtonIndex).focusState = false 'in case a user has left/righted to another button
  m.FastForwardButton.focusState = true
  setFocusedButtonIndex(m.FastForwardButton) 
End Function


'handles rewind key press or Rewind button selection
Function handleRewind()
  'begin rewinding, but don't need everything in beginScrub()
  if m.VideoState = "ffw"
    m.VideoState = "rew"
    m.scrubAmt = 0
    m.FastForwardButton.focusedUri = m.buttonUris.fastforwardFocus
    m.FastForwardButton.unfocusedUri = m.buttonUris.fastforward
    m.FastForwardButton.focusState = false
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

  'always remove focus from other buttons and add focus to rewind button
  m.TransportButtons.getChild(m.focusedButtonIndex).focusState = false    'in case a user has left/righted to another button
  m.RewindButton.focusState = true
  setFocusedButtonIndex(m.RewindButton)
End Function


'handles HopForward button selection
Function handleHopForward()
  jumpToPosition(m.playerPosition + 30)
End Function


'handles HopBack button selection
Function handleHopBack()
  jumpToPosition(m.playerPosition - 30)
End Function


'handles replay key press or HopBack button selection
Function jumpToPosition(position)
  if position > (m.Video.duration - 5)
    position = m.Video.duration - 5
  else if position < 0
    position = 0
  end if

  m.Video.seek = position
End Function


'Finds the 'index' of the passed in transport button node and sets it on m.focusedButtonIndex
Function setFocusedButtonIndex(TransportButton)
  for i=0 to m.TransportButtons.getChildCount()-1
    if TransportButton.id = m.TransportButtons.getChild(i).id
      m.focusedButtonIndex = i
    end if
  end for
End Function
