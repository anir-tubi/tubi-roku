Function onKeyEvent(key As String, press As Boolean) as Boolean
  tubiLog("VideoTransportHandling.onKeyEvent key = " + key + " press: " + press.toStr())
  if press
    m.lastButtonPressPos = m.playerPosition

    if isButtonPressAllowed(key,  m.VideoState, m.Video)
      if key = "OK"
        handleOk()

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
          handleHopBack(true, 20)
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
          if m.focusedButtonIndex = 0
            return false
          else
            for i=m.focusedButtonIndex-1 to 0 step -1
              button = m.TransportButtons.getChild(i)
              if button.enabled then
                setFocusedButton(button)
                exit for
              end if
            end for
          end if
        end if

      else if key = "right"
        'video is in playback mode and user wants to skip ahead
        if m.HUD.opacity = 0 and m.progressBarFocused = false and isActiveVideoState(m.VideoState, m.Video)
          handleSkipVideo(10, m.progressBarFocused)

        'user is in skip ahead mode (the progress bar is focused) and wants to skip ahead.
        else if m.progressBarFocused = true and isActiveVideoState(m.VideoState, m.Video)
          handleSkipVideo(10, m.progressBarFocused)

        else
          if m.focusedButtonIndex = m.TransportButtons.getChildCount()-1
            return false
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
        end if

      else if key = "up"
        if m.Overlay.opacity = 0
          showTransport()
        else if m.progressBarFocused = false and m.SkipIntro.hasFocus() = false
          setFocusedButton(m.ProgressBar)
        else if m.progressBarFocused = true and m.SkipIntro <> invalid and m.SkipIntro.visible = true
          m.progressBarFocused = false
          m.SkipIntro.setFocus(true)
        else
          return false
        end if

      else if key = "down"
        if m.Overlay.opacity = 0
          showTransport()
        else if m.progressBarFocused = true
          button = m.TransportButtons.getChild(m.focusedButtonIndex)
          setFocusedButton(button)
        else if m.skipIntro.hasFocus() = true
          setFocusedButton(m.ProgressBar)
        else
          return false  
        end if

      else if key = "back"
        if m.UpNext.isInFocusChain()
          m.UpNext.hide = true
          trackEvent({
            type: "auto_play"
            values: {
              video_id: m.top.content.id.toInt()
              auto_play_action: "DISMISS" 'AutoPlayAction enum
            }
          })

          ' if the next video plays after this point it will be considered automatic since the user
          ' will not be interacting with the autoplay UI again.
          setAutoplayMode("automatic")

          if m.VideoState = "stop" and m.UpNext.contentFocused <> invalid
            m.top.upNextContentToAutoplay = m.UpNext.contentFocused
          end if

          removeFocusFromUpNext()
        else if m.VideoState = "play"
          if m.HUD.opacity = 0
            clearSkipIntroButtonAndTimer()
            backButtonExit()
          else
            'close the transport
            animateTransport("out")
            resetTransportButtons()
          end if
        else if m.VideoState = "pause"
          resumeFromPause(true)
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


' m.playerPosition is the main source of truth for position.
' It can be updated by the video node or by calculations made while scrubbing
Function updatePlayerPosition(amt=0)
  if amt > 0
    m.playerPosition = m._.min(m.playerPosition + amt, m.Video.duration - 5)
  else if amt < 0
    m.playerPosition = m._.max(m.playerPosition + amt, 0)
  else if m.Video.position < 0
    m.playerPosition = 0
  else if m.Video.position > m.Video.duration
    m.playerPosition = m.Video.duration
  else
    m.playerPosition = m.Video.position
  end if

  ' update transport details only when it is shown
  if m.HUD.opacity > 0 or amt <> 0
    updateTransport()
  end if
End Function


Function handleTransportVoiceEvent()
  inputInfo = m.top.transportVoiceRequest
  command = ""

  if inputInfo <> invalid and inputInfo.command <> invalid
    command = inputInfo.command
  end if
  tubiLog("VideoTransportHandling.handleTransportVoiceEvent " + command)
  
  response = "unhandled"

  if m.top.visible = true and m.UpNext.opacity = 0
    response = "success"
    if command = "play"
      resumeFromPause(true)
    else if command = "ok"
      handleOk()
    else if command = "pause" or command = "stop"
      pauseVideo(true, true)
    else if command = "replay"
      handleHopBack(false, 20)
    else if command = "startover"
      goToStart()
    else if command = "rewind" 
      handleRewind()
    else if command = "forward"
      handleFastForward()
    else if command = "seek"  
      direction = ""
      if inputInfo <> invalid and inputInfo.duration <> invalid and inputInfo.direction <> invalid
        duration = inputInfo.duration.toInt()
        direction = inputInfo.direction
      end if
      if direction = "forward"
        seekPosition = m.Video.position + duration
        if seekPosition > m.Video.duration then
          response = "success.seek-end"
        end if
        handleHopForward(duration)
      else if direction = "backward"
        seekPosition = m.Video.position - duration
        if seekPosition < 0 then
          response = "success.seek-start"
        end if
        handleHopBack(false, duration)
      else
        response = "unhandled"  
      end if
    else if command = "next" 
      goToNext()
    else
      response = "unhandled"     
    end if
  else if m.UpNext.isInFocusChain()
    if command = "play" or command = "ok"
      m.UpNext.command = command
    else
      m.UpNext.invalidCommand = command
      response = "unhandled"
    end if
  end if
  
  inputInfo.response = response
  m.top.transportVoiceResponse = inputInfo
End Function


'pause the video player
Function pauseVideo(shouldShowTransport, shouldSendAnalytics = true)
  m.Video.control = "pause"
  m.VideoState = "pause"

  if shouldShowTransport
    if m.HUD.opacity < 1.0
      showTransport()
    end if
  end if

  m.PlayPauseButton.uri = m.buttonUris.play
  setFocusedButton(m.PlayPauseButton)
  
  if shouldSendAnalytics = true
    trackEvent({
      type: "pause_toggle"
      values: {
        video_id: m.Video.content.id.toInt()
        pause_state: "PAUSED"
        video_player: "DEFAULT"
      }
    })
  end if
End Function


'Resume play from a paused state
Function resumeFromPause(shouldSendAnalytics)
  animateTransport("out")
  'Only hide the button, don't clear the button so that the button will be shown again
  'if the transport is shown during playback between the intro or other skippable cuepoints'
  hideSkipIntroButton(m.top)
  clearSkipIntroTimer()

  ' when pausing the video, due to a firmware regression the Video.position can update
  ' an additional time after pausing, but m.playerPosition will not update after pausing leading the
  ' two values to be out of sync. If the difference is less than 1 second, treat it as if the 
  ' m.playerPosition and m.Video.positions are equal.
  if m.playerPosition <> m.Video.position and Abs(m.playerPosition - m.Video.position) > 1
    jumpToPosition(m.playerPosition)
  else
    m.Video.control = "resume"
    m.VideoState = "play"

    if shouldSendAnalytics = true
      trackEvent({
        type: "pause_toggle"
        values: {
          video_id: m.Video.content.id.toInt()
          pause_state: "RESUMED"
          video_player: "DEFAULT"
        }
      })
    end if
  end if

  m.PlayPauseButton.uri = m.buttonUris.pause
  setFocusedButton(m.PlayPauseButton)
End Function


Function resumeFromSkip()
  tubiLog("VideoTransportHandling.resumeFromSkip")
  animateTransport("out")
  'Only hide the button, don't clear the button so that the button will be shown again
  'if the transport is shown during playback between the intro or other skippable cuepoints'
  hideSkipIntroButton(m.top)
  clearSkipIntroTimer()

  ' when pausing the video in order to implement the 10s skip, due to a firmware regression,
  ' the Video.position can update an additional time after pausing, but m.playerPosition will
  ' not update after pausing leading the two values to be out of sync. If the difference is less
  ' than 1 second, treat it as if the m.playerPosition and m.Video.positions are equal.
  if m.playerPosition <> m.Video.position and Abs(m.playerPosition - m.Video.position) > 1
    jumpToPosition(m.playerPosition)
  else
    m.Video.control = "resume"
    m.VideoState = "play"
  end if
  m.PlayPauseButton.uri = m.buttonUris.pause
  setFocusedButton(m.PlayPauseButton)
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
  'only set positionAtJumpStart if it hasn't been set by other seek types
  if m.VideoState = "play" or m.VideoState = "pause"
    m.positionAtJumpStart = m.playerPosition
  end if

  if m.VideoState = "ffw" or m.VideoState = "rew"
    endScrub(false)
    setFocusedButton(m.StartButton)
  else
    playProgressEvent = getPlayProgressEvent()
    if playProgressEvent <> invalid
      trackEvent(playProgressEvent)
    end if
  end if

  'Hiding HUD while buffering
  if m.HUD.opacity > 0.0
    animateTransport("out")
  end if
  'Only hide the button, don't clear the button so that the button will be shown again
  'if the transport is shown during playback between the intro or other skippable cuepoints'
  hideSkipIntroButton(m.top)
  clearSkipIntroTimer()
  m.playerPosition = 0
  jumpToPosition(m.playerPosition)
End Function


'handles EndButton selection
Function goToNext()
  'reset before endScrub because we don't want an ad call made when moving to the next video, let prerolls hit instead
  if m.VideoState = "ffw" or m.VideoState = "rew"
    endScrub(true)
  end if
  clearSkipIntroButtonAndTimer()
  stopVideo()
  m.top.goToNext = true

  animateTransport("out")
  resetTransportButtons()
End Function


Function handleOk()
  if m.HUD.opacity = 0 and m.skipIntro.hasFocus() = false
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
      handleHopBack(false, 30)
    else if focusButtonId = m.PlayPauseButton.id
      handlePlayPause()
    else if focusButtonId = m.HopForwardButton.id
      handleHopForward(30)
    else if focusButtonId = m.FastForwardButton.id
      handleFastForward()
    else if focusButtonId = m.EndButton.id
      goToNext()
    else if focusButtonId = m.ClosedCaption.id
      handleClosedCaption()
    end if
  end if
End Function


'handles play key press or PlayPause button selection
Function handlePlayPause()
  tubiLog("VideoTransportHandling.handlePlayPause VideoState = " + m.VideoState)
  if m.VideoState = "play" then
    pauseVideo(true, true)
  else if m.VideoState = "pause" then
    resumeFromPause(true)
  else if m.VideoState = "rew" or m.VideoState = "ffw"
    endScrub(true)
  else if m.VideoState = "skip"
    resumeFromSkip()
  end if
  setFocusedButton(m.PlayPauseButton)
End Function


'handles fast forward key press or FastForward button selection
Function handleFastForward()

  'Only hide the button, don't clear the button so that the button will be shown again
  'if the transport is shown during playback between the intro or other skippable cuepoints'
  hideSkipIntroButton(m.top)
  clearSkipIntroTimer()

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

  setFocusedButton(m.FastForwardButton)
End Function


'handles rewind key press or Rewind button selection
Function handleRewind()
  'Only hide the button, don't clear the button so that the button will be shown again
  'if the transport is shown during playback between the intro or other skippable cuepoints'
  hideSkipIntroButton(m.top)
  clearSkipIntroTimer()

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

  setFocusedButton(m.RewindButton)
End Function


'handles HopForward button selection
Function handleHopForward(duration)
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
  'Only hide the button, don't clear the button so that the button will be shown again
  'if the transport is shown during playback between the intro or other skippable cuepoints'
  hideSkipIntroButton(m.top)
  clearSkipIntroTimer()
  m.VideoState = "hop"
  hopPosition = m.playerPosition + duration
  jumpToPosition(hopPosition)
End Function


' handles HopBack button selection
' remoteReplayButton - true/false (true - if replay button on remote is pressed/voice input, false - if replay icon is pressed or seek voice input)
' duration is seek/skip/replay in seconds.
Function handleHopBack(remoteReplayButton, duration)
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

  setFocusedButton(m.HopBackButton)

  if m.HUD.opacity > 0.0
    animateTransport("out")
  end if
  'Only hide the button, don't clear the button so that the button will be shown again
  'if the transport is shown during playback between the intro or other skippable cuepoints'
  hideSkipIntroButton(m.top)
  clearSkipIntroTimer()

  hopPosition = m.playerPosition - duration
  if remoteReplayButton = true
    hopPosition = m.playerPosition - duration
    if m.Video.globalCaptionMode = "Instant replay"
      tubilog("Turning on replay captions")
      m.replayCaptionEnd = m.positionAtJumpStart
      m.video.globalCaptionMode = "On"
    end if
  end if

  m.VideoState = "hop"
  jumpToPosition(hopPosition)
End Function


'handles the functionality for Roku's requirement to skip the video forward or backward while pausing the video.
'functionality is: pause video, jump 10s forward or back, show the transport
Function handleSkipVideo(amt, isProgressBarFocused)
  'handle the first skip press
  if m.VideoState <> "skip"
    m.Video.control = "pause"
    m.PlayPauseButton.uri = m.buttonUris.play
    'Only hide the button, don't clear the button so that the button will be shown again
    'if the transport is shown during playback between the intro or other skippable cuepoints'
    hideSkipIntroButton(m.top)
    clearSkipIntroTimer()

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


'handles ClosedCaption button/toggle selection
Function handleClosedCaption()
  cancelReplayCaptions()
  if m.HUD.opacity < 1.0
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


Function showCCDialog()
  ' show full options dialog
  if m.VideoState = "play" or m.VideoState = "pause" then
    m.ccWasPlaying = false
    if m.VideoState = "play" then
      m.ccWasPlaying = true
      pauseVideo(false, false)
    end if
    m.ccDialog = CreateObject("roSGNode", "ModalDialogScreen")
    m.ccDialog.id = "ccDialog"
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
        dialog_type: "CLOSED_CAPTIONS" 'DialogType enum
        pageOneof: m.Tracking.getAnalyticsPage("", {})  'TODO: Add the video player page
        dialog_action: "SHOW"  'Action enum
        dialog_sub_type: m.ccModes[m.ccSelections[0]][2]  '"off", "on-always", "on-replay"
      }
    })
  end if
End Function


Function closeCCDialog()
  if m.ccDialog <> invalid then
    if m.ccWasPlaying then
      resumeFromPause(false)
    end if
    m.ccDialog.unobserveField("buttonSelected")
    m.ccDialog.unobserveField("exitButton")
    m.ccDialog.setFocus(false)
    m.top.setFocus(true)
    m.top.removeChild(m.ccDialog)
    m.ccDialog = invalid

    trackEvent({
      type: "dialog"
      values: {
        dialog_type: "CLOSED_CAPTIONS" 'DialogType enum
        pageOneof: m.Tracking.getAnalyticsPage("", {})  'TODO: Add the video player page
        dialog_action: "ACCEPT_DELIBERATE"  'Action enum
        dialog_sub_type: m.ccModes[m.ccSelections[0]][2]  '"off", "on-always", "on-replay"
      }
    })
  end if
End Function


Function onCCDialogButton()
  tubiLog("VideoTransportHandling.onCCDialogButton")
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


'handles the Skip Intro selection
Function onSkipIntroSelected()
  if m.HUD.opacity > 0.0
    animateTransport("out")
  end if
  m.VideoState = "hop"
  if m.skipIntro.id = "skipIntro"
    hopPosition = m.top.content.creditsCuePoints.intro_end
  else if m.skipIntro.id = "skipRecap"
    hopPosition = m.top.content.creditsCuePoints.recap_end
  else if m.skipIntro.id = "skipEarlyCredits"
    hopPosition = m.top.content.creditsCuePoints.earlycredits_end
  end if
  jumpToPosition(hopPosition)
  clearSkipIntroButtonAndTimer()
End Function


'Perform at start of FF or RW
Function beginScrub()
  m.Video.control = "pause"
  m.scrubAmt = 0
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

  animateTransport("out")
  resetTransportButtons()
  m.PlayPauseButton.uri = m.buttonUris.pause
  setFocusedButton(m.PlayPauseButton)

  if shouldJump = true
    jumpToPosition(m.playerPosition)
  end if
End Function


' Callback when listening to the ScrubTimer fire
' Determine what the new playerPosition should be based on the scrubAmt and time spent scrubbing
Function updateScrubTime()
  timeSinceLastMark = m.scrubTimespan.totalMilliseconds() / 1000
  scrubTime = timeSinceLastMark * m.scrubMultipliers[m.scrubAmt]

  '//Ensure scrub can't go past the timer for the UpNext Overlay
  if m.Video.content.seriesId <> invalid and m.Video.content.seriesId <>""
    nMaxScrub = m.Video.duration - getExperimentResource("roku_postplayexp_aptimer_5sec", "roku_postplayexp_aptimer_10sec", false).ap_timer - 5
  else
    nMaxScrub = m.Video.duration - m.constants.player.upNextCountdown - 5
  end if
  if nMaxScrub < 0
    nMaxScrub = m.Video.duration
  end if

  if m.VideoState = "rew"
    if m.playerPosition - scrubTime < 0
      m.playerPosition = 0
    else if m.playerPosition - scrubTime > nMaxScrub
      m.playerPosition = nMaxScrub
    else
      m.playerPosition = Int(m.playerPosition - scrubTime)
    end if

  else if m.VideoState = "ffw"
    if m.playerPosition + scrubTime < 0
      m.playerPosition = 0
    else if m.playerPosition + scrubTime > nMaxScrub
      m.playerPosition = nMaxScrub
    else
      m.playerPosition = Int(m.playerPosition + scrubTime)
    end if
  end if

  m.scrubTimespan.mark()

  updateTransport()
End Function


'handles replay key press or HopBack button selection
'@position: integer, should be m.playerPosition in most cases
'
'function calling jumpToPosition should reset m.positionAtJumpStart to -1 after calling jumpToPosition
Function jumpToPosition(position)
  tubiLog("VideoTransportHandling.jumpToPosition")
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
  
  ' update history when seeking
  historyPosition(m.positionAtJumpStart)
  
  m.Thumbnail.visible = false
  ' seek analytics
  trackEvent({
    type: "seek"
    values: {
      video_id: m.Video.content.id.toInt()
      from_position: Int(m.positionAtJumpStart * 1000)
      to_position: Int(position * 1000)
      video_player: "DEFAULT"
    }
  })

  if shouldAdBreak
    ' leave m.VideoState = "play" because from the component's perspective video is still playing
    m.Video.control = "stop"
    m.top.adPosition = position
    m.top.adControl = "seek"
  else
    m.seekReferenceQueue.push(position)
    seekToPosition(position) 'will load and play the video at the seeked to point
    m.VideoState = "play"
  end if

  return position
End Function


' update the progress bar time & thumbnail on transport UI
Function updateTransport()
  updateTransportTimes()
  updateTransportThumbnail()
End Function


' update the thumbnail (video preview image)
Function updateTransportThumbnail()
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


' reset the buttons on transport UI
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
End Function


'Finds the 'index' of the passed in transport button node and sets it on m.focusedButtonIndex
'Additionally updates the image of the button to the focused version and all other buttons to the unfocused version
Function setFocusedButton(TransportButton)
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


'show transport
Function showTransport()
  ' update transport thumbnails before showing the transport UI
  updateTransport()
  m.PlayPauseButton.uri = m.buttonUris.pause
  setFocusedButton(m.PlayPauseButton)
  animateTransport("in")
End Function


'aggregates all the animation for showing/hiding the transport
'@direction: string, value may be "out" or "in"
Function animateTransport(direction)
  tubiLog("VideoTransportHandling.AnimateTransport, direction = " + direction)

  'call function to handle the skipIntro button based on the direction
  if getExperimentResource("roku_skip_intro", "roku_skip_intro_v2", false).skip_button_type <> "no_button"
    handleSkipIntroButtonOnAnimateTransport(direction)
  end if

  if direction = "in" and m.ratingOverlay.opacity = 1.0
    slideTo(m.ratingOverlay, [0,250], 0.6)
    fade(m.ratingGradient, "out", 0.2)  
    fade(m.Overlay, direction, 0.6, 0.2)
  else if direction = "out" and m.ratingOverlay.opacity = 1.0  
    fade(m.Overlay, direction, 0.6)
    slideTo(m.ratingOverlay, [0,0], 0.6, 0.2)
    fade(m.ratingGradient, "in", 0.6, 0.6)
  else
    fade(m.Overlay, direction, 0.6)  
  end if

  slideFade(m.HUD, "below", direction, 0.6)
  
End Function


'@direction: string, value may be "out" or "in"
Function handleSkipIntroButtonOnAnimateTransport(direction)
  skipIntroTransLation = m.SkipIntro.translation
  if direction = "in"
    if m.skipintro.id <> ""
      if m.skipintro.visible = false and m.skipIntroButtonTimer = invalid
        showSkipIntroButton()
      end if
      slideTo(m.SkipIntro,[skipIntroTransLation[0], m.skipIntroUpTranslation], 0.6)
    end if
  else if direction = "out"
    if m.skipintro.visible = true and m.skipIntroButtonTimer <> invalid
      slideTo(m.SkipIntro,[skipIntroTransLation[0], m.skipIntroDownTranslation], 0.6)
      m.skipintro.setFocus(true)
    else if m.skipintro.visible = true and m.skipIntroButtonTimer = invalid
      hideSkipIntroButton()
    end if
  end if

End Function

' update the progress bar time
Function updateTransportTimes()
  m.ElapsedLabel.text = formatLengthAsTimestamp(m.playerPosition)
  if m.Video.duration <> invalid then
    m.RemainingLabel.text = "-" + formatLengthAsTimestamp(m.Video.duration - m.playerPosition)
  end if
End Function


Function showThumbnail()
  tubiLog("videoTransportHandling.showThumbnail")
  if m.Thumbnail.spriteUrls <> invalid and m.Thumbnail.spriteUrls.count() > 0
    m.Thumbnail.visible = true
  else
    m.Thumbnail.visible = false
  end if
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