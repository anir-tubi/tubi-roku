Function onKeyEvent(key As String, press As Boolean) as Boolean
  tubiLog("VideoTransportHandling.onKeyEvent key = " + key + " press: " + press.toStr())
  ' Making sure when the closed captioning overlay is displayed playerscreen only handles back button and ignore rest of the events.
  if press
    m.lastButtonPressPos = m.playerPosition
    if isButtonPressAllowed(key, m.VideoState, m.Video)
      hidePauseAdOverlay() ' added for extra safety

      ' Resetting the timer when there is any user interaction during pause
      if m.pauseAdOverlayTimer.control = "start"
        restartPauseAdTimer(5)
      end if

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
          showTransport()
          stopPauseAdTimer()
          if m.isPixelFiredForCurrentPauseAd = false
            sendPauseAdPixel(m.constants.pauseAd.notUsedPixel)
          end if
          showClosedCaptionAudioTrackOverlay()
        end if

      else if key = "left"
        'video is in playback mode and user wants to skip back
        if m.HUD.opacity = 0 AND m.progressBarFocused = false AND isActiveVideoState(m.VideoState, m.Video)
          handleSkipVideo(-10, m.progressBarFocused)

        'user is in skip ahead mode (the progress bar is focused) and wants to skip back.
        else if m.progressBarFocused = true AND isActiveVideoState(m.VideoState, m.Video)
          handleSkipVideo(-10, m.progressBarFocused)

        else
          'navigate the transport buttons, skipping disabled ones
          if m.focusedButtonIndex = 0
            return false
          else
            for i=m.focusedButtonIndex-1 to 0 step -1
              button = m.TransportButtons.getChild(i)
              if button.enabled then
                setFocusedButton(button, true)
                exit for
              end if
            end for
          end if
        end if

      else if key = "right"
        'video is in playback mode and user wants to skip ahead
        if m.HUD.opacity = 0 AND m.progressBarFocused = false AND isActiveVideoState(m.VideoState, m.Video)
          handleSkipVideo(10, m.progressBarFocused)

        'user is in skip ahead mode (the progress bar is focused) and wants to skip ahead.
        else if m.progressBarFocused = true AND isActiveVideoState(m.VideoState, m.Video)
          handleSkipVideo(10, m.progressBarFocused)

        else
          if m.focusedButtonIndex = m.TransportButtons.getChildCount()-1
            return false
          else
            'navigate the transport buttons, skipping disabled ones
            for i=m.focusedButtonIndex+1 to m.TransportButtons.getChildCount()-1
              button = m.TransportButtons.getChild(i)
              if button.enabled then
                setFocusedButton(button, true)
                exit for
              end if
            end for
          end if
        end if

      else if key = "up"
        if m.Overlay.opacity = 0
          showTransport()
        else if m.progressBarFocused = false AND m.skipCuepointsButton.hasFocus() = false
          setFocusedButton(m.ProgressBar)
        else if m.progressBarFocused = true AND m.skipCuepointsButton <> invalid AND m.skipCuepointsButton.visible = true
          m.progressBarFocused = false
          m.skipCuepointsButton.setFocus(true)
        else
          return false
        end if

      else if key = "down"
        if m.Overlay.opacity = 0
          showTransport()
        else if m.progressBarFocused = true
          setFocusedButton(m.PlayPauseButton, true)
        else if m.skipCuepointsButton.hasFocus() = true
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

          if m.VideoState = "stop" AND m.UpNext.contentFocused <> invalid
            m.top.upNextContentToAutoplay = m.UpNext.contentFocused
          end if

          removeFocusFromUpNext()
        else if m.VideoState = "play"
          if m.HUD.opacity = 0
            clearSkipCuepointsButtonAndTimer()
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
' @amt: integer, the amount of time in seconds by which m.playerPosition should be updated
Function updatePlayerPosition(amt = 0)
  videoPosition = m.Video.position
  videoDuration = m.Video.duration

  if amt > 0
    m.playerPosition = m._.min(m.playerPosition + amt, videoDuration - 5)
  else if amt < 0
    m.playerPosition = m._.max(m.playerPosition + amt, 0)
  else if videoPosition < 0
    m.playerPosition = 0
  else if videoPosition > videoDuration
    m.playerPosition = videoDuration
  else
    m.playerPosition = videoPosition
  end if

  ' update transport details only when it is shown
  if m.HUD.opacity > 0 or amt <> 0
    updateTransport()
  end if
End Function


Function handleTransportVoiceEvent()
  inputInfo = m.top.transportVoiceRequest
  command = ""

  if inputInfo <> invalid AND inputInfo.command <> invalid
    command = inputInfo.command
  end if
  tubiLog("VideoTransportHandling.handleTransportVoiceEvent " + command)

  response = "unhandled"
  hidePauseAdOverlay()
  resetPauseAdOverlay()

  if m.top.visible = true AND m.UpNext.opacity = 0
    response = "success"
    if command = "play"
      resumeFromPause(true)
    else if command = "ok"
      handleOk()
    else if command = "pause" or command = "stop"
      if m.VideoState = "play"
        pauseVideo(true, true)
      else
        stopScrubTimer()
      end if
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
      duration = 0
      if inputInfo <> invalid AND inputInfo.duration <> invalid AND inputInfo.direction <> invalid
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
    else if command = "skip"
      'If the content has an intro/recap/early credits, handle the "skip" command.
      'otherwise, handle it like a "next" command
      if isNonEmptyString(m.skipCuepointsButton.id)
        onSkipCuepointsButtonSelected()
      else
        goToNext()
      end if
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
  updateVideoState("pause")

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

  m.top.videoPositionForPauseAdRequest = m.playerPosition 'this position is used in pauseAd request

  if m.top.isTrailer = false and m.top.hasFocus() = true

    if getExperimentResource("roku_pause_ads", "roku_pause_ads_v2", false).enabled = true

      if m.isPauseAdReqInProgress = false AND m.isPixelFiredForCurrentPauseAd = true
        resetPauseAd()
        resetPauseAdTimers()
        m.isPauseAdReqInProgress = true
        ' // REMOVE duration which are added dynamically as we have default value in VideoPlayerScreen.xml, when we graduate roku_pause_ads_v2
        m.pauseAdOverlayTimer.duration = 5
        startPauseAdTimer()
        m.top.getPauseAd = true
      end if

    else
      resetPauseAdTimers()
      m.pauseAdOverlayTimer.duration = 5
      startPauseAdTimer()
    end if

  end if
End Function


'Resume play from a paused state
Function resumeFromPause(shouldSendAnalytics)
  animateTransport("out")
  'Only hide the button, don't clear the button so that the button will be shown again
  'if the transport is shown during playback between the intro or other skippable cuepoints'
  hideSkipCuepointsButton(m.top)
  clearSkipCuepointsTimer()

  ' when pausing the video, due to a firmware regression the Video.position can update
  ' an additional time after pausing, but m.playerPosition will not update after pausing leading the
  ' two values to be out of sync. If the difference is less than 1 second, treat it as if the
  ' m.playerPosition and m.Video.positions are equal.
  if m.playerPosition <> m.Video.position AND Abs(m.playerPosition - m.Video.position) > 1
    jumpToPosition(m.playerPosition)
  else
    m.Video.control = "resume"
    updateVideoState("play")

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
  hideSkipCuepointsButton(m.top)
  clearSkipCuepointsTimer()

  ' when pausing the video in order to implement the 10s skip, due to a firmware regression,
  ' the Video.position can update an additional time after pausing, but m.playerPosition will
  ' not update after pausing leading the two values to be out of sync. If the difference is less
  ' than 1 second, treat it as if the m.playerPosition and m.Video.positions are equal.
  if m.playerPosition <> m.Video.position AND Abs(m.playerPosition - m.Video.position) > 1
    jumpToPosition(m.playerPosition)
  else
    m.Video.control = "resume"
    updateVideoState("play")
  end if
  m.PlayPauseButton.uri = m.buttonUris.pause
  setFocusedButton(m.PlayPauseButton)
End Function


' updates the VideoState
' @videoState: string, possible values are play/pause/stop/rew/ffw/hop/skip
Function updateVideoState(videoState)
  m.VideoState = videoState
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
  else if m.VideoState <> "skip"
    playProgressEvent = getPlayProgressEvent("goToStart")
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
  hideSkipCuepointsButton(m.top)
  clearSkipCuepointsTimer()
  m.playerPosition = 0
  jumpToPosition(m.playerPosition)
End Function


'handles EndButton selection
Function goToNext()
  'reset before endScrub because we don't want an ad call made when moving to the next video, let prerolls hit instead
  if m.VideoState = "ffw" or m.VideoState = "rew"
    endScrub(true)
  else if m.VideoState = "skip"
    ' this block get executes when video plays if user presses "right" key few times and then press "Go to next" button on transport layer.
    ' in this case we need to update the last-ping time to current video position to fix large play progress issue
    updateLastPingTime(m.playerPosition)
  end if
  clearSkipCuepointsButtonAndTimer()
  stopVideo()
  m.top.goToNext = true

  animateTransport("out")
  resetTransportButtons()
End Function


Function handleOk()
  if m.HUD.opacity = 0 AND m.skipCuepointsButton.hasFocus() = false
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
    else if focusButtonId = m.closedCaptionAudioButton.id
      stopPauseAdTimer()
      if m.isPixelFiredForCurrentPauseAd = false
        sendPauseAdPixel(m.constants.pauseAd.notUsedPixel)
      end if
      showClosedCaptionAudioTrackOverlay()
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
  hideSkipCuepointsButton(m.top)
  clearSkipCuepointsTimer()

  'begin fast forwarding, but don't need everything in beginScrub()
  if m.VideoState = "rew"
    updateVideoState("ffw")
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
    updateVideoState("ffw")
    m.FastForwardButton.uri = m.buttonUris.fastForwardLevels[0]
    m.PlayPauseButton.uri = m.buttonUris.play
  end if

  setFocusedButton(m.FastForwardButton)
End Function


'handles rewind key press or Rewind button selection
Function handleRewind()
  'Only hide the button, don't clear the button so that the button will be shown again
  'if the transport is shown during playback between the intro or other skippable cuepoints'
  hideSkipCuepointsButton(m.top)
  clearSkipCuepointsTimer()

  'begin rewinding, but don't need everything in beginScrub()
  if m.VideoState = "ffw"
    updateVideoState("rew")
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
    updateVideoState("rew")
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
    playProgressEvent = getPlayProgressEvent("handleHopForward")
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
  hideSkipCuepointsButton(m.top)
  clearSkipCuepointsTimer()
  updateVideoState("hop")
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
    playProgressEvent = getPlayProgressEvent("handleHopBack")
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
  hideSkipCuepointsButton(m.top)
  clearSkipCuepointsTimer()

  hopPosition = m.playerPosition - duration
  if remoteReplayButton = true
    hopPosition = m.playerPosition - duration
    if m.Video.globalCaptionMode = "Instant replay"
      tubilog("Turning on replay captions")
      m.replayCaptionEnd = m.positionAtJumpStart
      m.video.globalCaptionMode = "On"
    end if
  end if

  updateVideoState("hop")
  jumpToPosition(hopPosition)
End Function


'handles the functionality for Roku's requirement to skip the video forward or backward while pausing the video.
'functionality is: pause video, jump 10s forward or back, show the transport
Function handleSkipVideo(amt, isProgressBarFocused)
  'handle the first skip press
  if m.VideoState <> "skip"
    m.Video.control = "pause"

    'Only hide the button, don't clear the button so that the button will be shown again
    'if the transport is shown during playback between the intro or other skippable cuepoints'
    hideSkipCuepointsButton(m.top)
    clearSkipCuepointsTimer()

    if m.VideoState <> "rew" AND m.VideoState <> "ffw"
      playProgressEvent = getPlayProgressEvent("handleSkipVideo")
      if playProgressEvent <> invalid
        trackEvent(playProgressEvent)
      end if

      'only update m.positionAtJumpStart if we are not concluding another seek interaction
      m.positionAtJumpStart = m.playerPosition
    else
      stopScrubTimer()
    end if

    updateVideoState("skip")
  end if

  if m.HUD.opacity < 1.0
    showTransport()
  end if

  m.PlayPauseButton.uri = m.buttonUris.play

  if isProgressBarFocused <> true
    setFocusedButton(m.ProgressBar)
  end if
  showThumbnail()

  updatePlayerPosition(amt)
End Function


' Displays the closed caption and audio track selection overlay.
Function showClosedCaptionAudioTrackOverlay()
  m.closedCaptionAndAudioSelectionOverlay.globalCaptionMode = m.video.globalCaptionMode
  m.closedCaptionAndAudioSelectionOverlay.availableClosedCaptionTracks = m.video.availableSubtitleTracks
  m.closedCaptionAndAudioSelectionOverlay.availableAudioTracks = m.video.availableAudioTracks
  m.closedCaptionAndAudioSelectionOverlay.setFocus(true)
  setFocusedButton(m.closedCaptionAudioButton)
  fade(m.closedCaptionAndAudioSelectionOverlayGroup, "in", 0.6)
  m.isClosedCaptionAudioOverlayShowing = true
  trackingPageInfo = m.top.trackingPageInfo
  if m.top.content <> invalid
    m.closedCaptionAndAudioSelectionOverlay.videoId = m.top.content.id.toInt()
  end if
  ' Fire button click event.
  trackEvent({
    type: "dialog"
    values: {
      dialog_type: "SUBTITLE_AUDIO"
      pageOneof: m.Tracking.getAnalyticsPage(trackingPageInfo.pageType, trackingPageInfo.pageValues)
      dialog_action: "SHOW"
    }
  })
End Function


' Hides the closed caption and audio track selection overlay.
Function hideClosedCaptionAudioTrackOverlay()
  m.isClosedCaptionAudioOverlayShowing = false
  m.closedCaptionAndAudioSelectionOverlay.setFocus(false)
  fade(m.closedCaptionAndAudioSelectionOverlayGroup, "out", 0.6)
  m.top.setFocus(true)
End Function


'handles the Skip Intro selection
Function onSkipCuepointsButtonSelected()
  tubiLog("VideoTransportHandling.onSkipCuepointsButtonSelected")
  if m.HUD.opacity > 0.0
    animateTransport("out")
  end if

  creditCuePoints = getCreditCuepointsFromContent(m.top.content)

  hopPosition = -1
  if isSkipIntroCuePointsReached(creditCuePoints) = true
    hopPosition = creditCuePoints.intro_end
  else if isSkipRecapCuePointsReached(creditCuePoints) = true
    hopPosition = creditCuePoints.recap_end
  else if isSkipEarlyCreditCuePointsReached(creditCuePoints) = true
    hopPosition = creditCuePoints.earlycredits_end
  end if

  if hopPosition > 0
    m.positionAtJumpStart = m.playerPosition
    updateVideoState("hop")
    jumpToPosition(hopPosition)
  end if

  clearSkipCuepointsButtonAndTimer()
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
    playProgressEvent = getPlayProgressEvent("beginScrub")
    if playProgressEvent <> invalid
      trackEvent(playProgressEvent)
    end if
  end if
End Function


Function stopScrubTimer()

  m.scrubAmt = -1 'reset just in case it somehow got to less than -1
  m.ScrubTimer.control = "stop"
  m.ScrubTimer.unobserveField("fire")

End Function


'Perform at end of FF or RW
' @shouldJump: boolean, indicates if we should use jumpToPosition - don't use if will use later on in the calling function
Function endScrub(shouldJump = false)
  stopScrubTimer()
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
  if m.Video.content.seriesId <> invalid AND m.Video.content.seriesId <>""
    nMaxScrub = m.Video.duration - m.constants.player.upNextCountdownForSeries - 5
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
  cancelReplayCaptions() 'on any jump we cancel any temporary caption modifications

  'Don't let position be out of bounds of the duration of the video
  if position > (m.Video.duration - 5)
    position = m.Video.duration - 5
  else if position < 0
    position = 0
  end if

  ' in case position is updated by the above block
  ' setting m.playerPosition here also ensures post ad break video playback at the correct position
  m.playerPosition = position

  shouldAdBreak = false
  adPosition = position
  if m.top.enableAds = true
    if m.positionAtJumpStart > -1 AND position > m.positionAtJumpStart
    ' only request ad breaks on fast forward (don't request on rewind)

      cuepoints = m.Video.content.cuepoints
      for i = cuepoints.count() - 1 to 0 step -1  'iterate backwards to send last cuepoint that was seek passed
        cuepoint = cuepoints[i]
        if m.positionAtJumpStart < cuepoint AND position >= cuepoint
          ' only request ad breaks if fast forward past a cue point
          shouldAdBreak = true
          exit for
        end if
      end for
    end if
  end if

  m.PlayPauseButton.uri = m.buttonUris.pause
  m.lastButtonPressPos = position

  ' update history when seeking
  historyPosition(m.positionAtJumpStart)

  updateLastPingTime(m.playerPosition)

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

  if shouldAdBreak = true
    ' leave m.VideoState = "play" because from the component's perspective video is still playing
    m.Video.control = "stop"
    m.top.adPosition = adPosition
    m.top.adControl = "seek"
  else
    m.seekReferenceQueue.push(position)
    seekToPosition(position) 'will load and play the video at the seeked to point
    updateVideoState("play")
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
  m.closedCaptionAudioButton.focusState = false
End Function


'Finds the 'index' of the passed in transport button node and sets it on m.focusedButtonIndex
'Additionally updates the image of the button to the focused version and all other buttons to the unfocused version
' @transportButton: roSGNode, a node of type TransportButton or TubiProgressBar
' @sayAudioText: boolean, true if we want to announce the audio guide.
Function setFocusedButton(transportButton, sayAudioText = false)
  shouldSetFocusOnTop = false

  if transportButton.isSameNode(m.ProgressBar) = true
    m.progressBarFocused = true
    m.ProgressBar.setFocus(true)
  else
    m.ProgressBar.setFocus(false)
    m.progressBarFocused = false
    shouldSetFocusOnTop = true
  end if

  if transportButton.isSameNode(m.skipCuepointsButton) = true
    m.skipCuepointsButton.setFocus(true)
  else
    shouldSetFocusOnTop = true
  end if

  if shouldSetFocusOnTop = true
    m.top.setFocus(true)
  end if

  ' set focused/unfocused UI on each button in the transport bar as necessary
  for i=0 to m.TransportButtons.getChildCount()-1
    button = m.TransportButtons.getChild(i)
    if transportButton.id = button.id
      m.focusedButtonIndex = i
      button.focusState = true
    else
      button.focusState = false
    end if
  end for

  ' Use case when we will pass true are as below. Following general standards based on testing of other competitor apps.
  ' When we focus on the skip cuepoints button.
  ' When the user navigates within the transport bar.
  ' When the user moves focus into the transport control icon from the progress bar.
  if sayAudioText = true
    sayFocusedButtonAudioGuide(transportButton.id)
  end if
End Function


Function sayFocusedButtonAudioGuide(focusButtonId)
  audioGuideText = ""
  audioGuideHints = m.constants.audioGuideHints.transportBarIcons

  if focusButtonId = m.SkipTrailerButton.id
    audioGuideText = audioGuideHints.skipTrailerButtonHint
  else if focusButtonId = m.StartButton.id
    audioGuideText = audioGuideHints.playFromBeginningButtonHint
  else if focusButtonId = m.RewindButton.id
    audioGuideText = audioGuideHints.rewindButtonHint
  else if focusButtonId = m.HopBackButton.id
    audioGuideText = audioGuideHints.hopBackButtonHint + " 30 seconds " + m.constants.audioGuideHints.buttonHint
  else if focusButtonId = m.PlayPauseButton.id

    ' Based on video state using play or pause text.
    if m.VideoState = "play" then
      audioGuideText = audioGuideHints.pauseButtonHint
    else
      audioGuideText = audioGuideHints.playButtonHint
    end if

  else if focusButtonId = m.HopForwardButton.id
    audioGuideText = audioGuideHints.hopForwardButtonHint + " 30 seconds " + m.constants.audioGuideHints.buttonHint
  else if focusButtonId = m.FastForwardButton.id
    audioGuideText = audioGuideHints.fastForwardButtonHint
  else if focusButtonId = m.EndButton.id
    audioGuideText = audioGuideHints.goToNextVideoButtonHint
  else if focusButtonId = m.closedCaptionAudioButton.id
    audioGuideText = audioGuideHints.closedCaptionAudioButtonHint
  end if

  if isNonEmptyString(audioGuideText)
    readAudioGuideText(audioGuideText)
  end if
End Function


'show transport
Function showTransport()
  ' update transport thumbnails before showing the transport UI
  updateTransport()

  if m.videoState = "pause"
    m.PlayPauseButton.uri = m.buttonUris.play
  else
    m.PlayPauseButton.uri = m.buttonUris.pause
  end if

  creditCuePoints = getCreditCuepointsFromContent(m.top.content)
  if m.top.hasFocus() = true AND isSkipIntroCuePointsReached(creditCuePoints) = false
    ' Only set focus on the play/pause button if the video player has focus (as opposed to some other UI)
    ' and the skip cuepoints button should not be focused (ie. nowPos is not within intro)
    setFocusedButton(m.PlayPauseButton)
  end if

  animateTransport("in")
End Function


'aggregates all the animation for showing/hiding the transport
'@direction: string, value may be "out" or "in"
Function animateTransport(direction)
  tubiLog("VideoTransportHandling.AnimateTransport, direction = " + direction)
  handleSkipCuepointsButtonOnAnimateTransport(direction)

  if direction = "in" AND m.ratingOverlay.opacity = 1.0
    slideTo(m.ratingOverlay, [0,250], 0.6)
    fade(m.ratingGradient, "out", 0.2)
    fade(m.Overlay, direction, 0.6, 0.2)
  else if direction = "out" AND m.ratingOverlay.opacity = 1.0
    fade(m.Overlay, direction, 0.6)
    slideTo(m.ratingOverlay, [0,0], 0.6, 0.2)
    fade(m.ratingGradient, "in", 0.6, 0.6)
  else
    fade(m.Overlay, direction, 0.6)
  end if

  slideFade(m.HUD, "below", direction, 0.6)
End Function


'@direction: string, value may be "out" or "in"
Function handleSkipCuepointsButtonOnAnimateTransport(direction)
  tubiLog("VideoTransportHandling.handleSkipCuepointsButtonOnAnimateTransport")
  skipCuepointsButtonTransLation = m.skipCuepointsButton.translation
  creditCuePoints = getCreditCuepointsFromContent(m.top.content)
  currentCuepoint = getCurrentCuepoint(creditCuePoints)

  if direction = "in"
    if isNonEmptyString(currentCuepoint) = true
      if canSkipCuepointsButtonBeShown(currentCuepoint, true) = true AND m.skipCuepointsButtonTimer = invalid
        showSkipCuepointsButton()
      end if
      slideTo(m.skipCuepointsButton,[skipCuepointsButtonTransLation[0], m.skipCuepointsButtonUpTranslation], 0.6)
    end if
  else if direction = "out"
    if m.skipCuepointsButton.visible = true AND m.skipCuepointsButtonTimer <> invalid
      slideTo(m.skipCuepointsButton,[skipCuepointsButtonTransLation[0], m.skipCuepointsButtonDownTranslation], 0.6)
      m.skipCuepointsButton.setFocus(true)
    else if m.skipCuepointsButton.visible = true AND m.skipCuepointsButtonTimer = invalid
      hideSkipCuepointsButton()
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
  if m.Thumbnail.spriteUrls <> invalid AND m.Thumbnail.spriteUrls.count() > 0
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
    up: true
    down: true
    left: true
    right: true
  }

  isAllowed  = true
  'in non active video states, we don't allow the disabled keys, non disable keys are always allowed
  if not isActiveVideoState(videoState, videoNode) AND disabledKeys[key] = true
    isAllowed = false
  end if

  ' If closed caption and audio overlay is showing then we ignore button press in the screen level.
  if m.isClosedCaptionAudioOverlayShowing = true
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

  if videoNode.state = "buffering" OR videoNode.state = "stopped"
    isActive = false
  end if

  return isActive
End Function


Function onPauseAdResponse(msg)
  pauseAdResponse = msg.GetData()
  m.isPauseAdReqInProgress = false

  if pauseAdResponse <> invalid

    if pauseAdResponse.mediaUrl <> ""
      m.isPixelFiredForCurrentPauseAd = false
    end if

    if m.top.hasFocus()
      m.pauseAdOverlay.posterWidth = pauseAdResponse.width
      m.pauseAdOverlay.posterHeight = pauseAdResponse.height
      m.pauseAdOverlay.posterUri = pauseAdResponse.mediaUrl
    else
      sendPauseAdPixel(m.constants.pauseAd.notUsedPixel)
      'If the video player does not have focus, resetting timer here to avoid notUsed Pixel being fired again in PauseAdTimers observer.
      resetPauseAdTimers()
    end if

  end if
End Function


' onClosePauseAdOverlay triggers when user presses back/rew/fwd/play/replay/options
Function onClosePauseAdOverlay()
  resetPauseAdOverlay()
End Function


Function resetPauseAdOverlay()
  if m.pauseAdOverlay.hasFocus() = true
    m.pauseAdOverlay.setFocus(false)
    m.top.setFocus(true)
  end if

  if m.isPixelFiredForCurrentPauseAd = true
    sendPauseAdPixel(m.constants.pauseAd.endPixel)
  else
    sendPauseAdPixel(m.constants.pauseAd.notUsedPixel)
  end if

  resetPauseAdTimers()
  resetPauseAd()

  if m.HUD.opacity < 1.0
    showTransport()
  end if
End Function


'onPauseAdOverlayTimer triggers 5 seconds after the user pauses the video
Function onPauseAdOverlayTimer()
  m.pauseAdOverlay.unobserveFieldScoped("posterLoadStatus")

  currentUTCTimeInSecs = getCurrentUTCTime()
  pauseAdStartDate = m.constants.pauseAdExp.startDate
  pauseAdEndDate = m.constants.pauseAdExp.endDate

  ' //BELOW BLOCK IS ADDED FOR QA TESTING. QA can change the dates on <env>.yml file for testing pauseAd experiment
  if m.constants.settings.mode <> "production"
    if isNonEmptyString(m.constants.settings.pauseAdStartDate)
      pauseAdStartDate = m.constants.settings.pauseAdStartDate
    end if
    if isNonEmptyString(m.constants.settings.pauseAdEndDate)
      pauseAdEndDate = m.constants.settings.pauseAdEndDate
    end if
  end if

  pauseAdExpStartDate = CreateObject("roDateTime")
  pauseAdExpStartDate.FromISO8601String(pauseAdStartDate)
  pauseAdExpEndDate = CreateObject("roDateTime")
  pauseAdExpEndDate.FromISO8601String(pauseAdEndDate)

  m.pauseAdDeviceCap = 0
  if m.top.pauseAdDeviceCap <> invalid
    m.pauseAdDeviceCap = m.top.pauseAdDeviceCap
  end if

  if m.videoState = "pause" AND m.pauseAdDeviceCap < 5 AND currentUTCTimeInSecs >= pauseAdExpStartDate.asSeconds() AND currentUTCTimeInSecs <= pauseAdExpEndDate.asSeconds()
    'roku_pause_ads_v2 exposure event will be fired after 5 seconds for both treatment & control only first day of experiment
    getExperimentResource("roku_pause_ads", "roku_pause_ads_v2", true).enabled = true
    loadStatus = m.pauseAdOverlay.posterLoadStatus

    if loadStatus = "ready"
      showPauseAd()
    else if loadStatus = "failed"
      sendPauseAdPixel(m.constants.pauseAd.errorPixel)
    else if loadStatus = "loading"
      m.pauseAdOverlay.observeFieldScoped("posterLoadStatus", "onPauseAdPosterLoadStatus")
    end if

  else if getExperimentResource("roku_pause_ads", "roku_pause_ads_v2", false).enabled = true
    sendPauseAdPixel(m.constants.pauseAd.notUsedPixel)
  end if

End Function


'callback for pauseAdPoster loadStatus attribute
Function onPauseAdPosterLoadStatus(msg)
  loadStatus = msg.GetData()

  if m.videoState = "pause"

    if loadStatus = "ready"
      m.pauseAdOverlay.unobserveFieldScoped("posterLoadStatus")
      showPauseAd()
    else if loadStatus = "failed"
      m.pauseAdOverlay.unobserveFieldScoped("posterLoadStatus")
      sendPauseAdPixel(m.constants.pauseAd.errorPixel)
    end if

  else
    m.pauseAdOverlay.unobserveFieldScoped("posterLoadStatus")
    sendPauseAdPixel(m.constants.pauseAd.notUsedPixel)
  end if
End Function


'showPauseAd does below
' - animates out the transport ui
' - amimates in pause ad overlay
' - send pause ad start pixel
' - starts imp tracking timer for pause ad
' - sets the focus to pause ad overlay
Function showPauseAd()
  animateTransport("out")
  m.pauseAdAnimation = fade(m.pauseAdOverlay, "in", 0.6, 0.4)
  m.top.isPauseAdDisplayed = true
  sendPauseAdPixel(m.constants.pauseAd.startPixel)
  startImpTrackingTimer()
  m.pauseAdOverlay.setFocus(true)
End Function


'startImpTrackingTimer starts the imp tracking timer which will send pixel event 1 min after ad is shown
Function startImpTrackingTimer()
  if m.impTrackingTimer = invalid
    m.impTrackingTimer = m.top.createChild("Timer")
  end if
  stopImpTrackingTimer()
  m.impTrackingTimer.observeFieldScoped("fire", "impTrackingTimerFired")
  m.impTrackingTimer.control = "start"
End Function


'impTrackingTimerFired fires 1 second after the pauseAd is displayed on video screen
Function impTrackingTimerFired()
  if m.videoState = "pause"
    sendPauseAdPixel(m.constants.pauseAd.impTrackingPixel)
  end if
End Function


'resetPauseAd resets the posters in pauseAdOverlay and invalidate the pauseAdResponse
Function resetPauseAd()
  if m.pauseAdOverlay <> invalid
    m.pauseAdOverlay.posterUri = ""
    m.pauseAdOverlay.posterWidth = 0
    m.pauseAdOverlay.posterHeight = 0

    if m.pauseAdAnimation <> invalid
      stopAnimation(m.pauseAdAnimation)
    end if

    m.pauseAdOverlay.opacity = 0.0
  end if
  m.top.pauseAdResponse = invalid
End Function


'resetPauseAdTimers resets the pauseAd related timers
Function resetPauseAdTimers()
  stopPauseAdTimer()
  stopImpTrackingTimer()
End Function


'restartPauseAdTimer restarts the pause ad timer
'@duration : float, default is 5 seconds
Function restartPauseAdTimer(duration = 5)
  if m.pauseAdOverlayTimer <> invalid
    stopPauseAdTimer()
    m.pauseAdOverlayTimer.duration = duration
    startPauseAdTimer()
  end if
End Function


'stopPauseAdTimer stops the pause ad timer
Function stopPauseAdTimer()
  if m.pauseAdOverlayTimer <> invalid
    m.pauseAdOverlayTimer.unObserveFieldScoped("fire")
    m.pauseAdOverlayTimer.control = "stop"
  end if
End Function


'stopImpTrackingTimer stops the imp tracking timer for pause ad
Function stopImpTrackingTimer()
  if m.impTrackingTimer <> invalid
    m.impTrackingTimer.control = "stop"
    m.impTrackingTimer.unObserveFieldScoped("fire")
  end if
End Function


'startPauseAdTimer stops the pause ad timer
Function startPauseAdTimer()
  if m.pauseAdOverlayTimer <> invalid
    m.pauseAdOverlayTimer.observeFieldScoped("fire", "onPauseAdOverlayTimer")
    m.pauseAdOverlayTimer.control = "start"
  end if
End Function


'this function triggers the pauseAdPixel interface to send pause ad related pixels
'@pixelType: String, possible values are from m.constants.pauseAd
Function sendPauseAdPixel(pixelType = "")
  pauseAdResponse = m.top.pauseAdResponse
  pixelUrl = ""

  if pauseAdResponse <> invalid
    if pixelType = m.constants.pauseAd.startPixel
      pixelUrl = pauseAdResponse.startPixel
    else if pixelType = m.constants.pauseAd.impTrackingPixel
      pixelUrl = pauseAdResponse.impTrackingPixel
    else if pixelType = m.constants.pauseAd.endPixel
      pixelUrl = pauseAdResponse.endPixel
    else if pixelType = m.constants.pauseAd.notUsedPixel
      pixelUrl = pauseAdResponse.notUsedPixel
    else if pixelType = m.constants.pauseAd.errorPixel
      pixelUrl = pauseAdResponse.errorPixel
    end if
  end if

  if isNonEmptyString(pixelUrl) AND getExperimentResource("roku_pause_ads", "roku_pause_ads_v2", false).enabled = true
    m.isPixelFiredForCurrentPauseAd = true
    m.top.sendPauseAdPixel = pixelUrl
  end if
End Function


' onSendPendingPauseAdPixel will be triggered when user presses Home key on remote when video player is visible.
' This function does below
' - resets the pause ad related timers
' - sends missed pixels for pause ad
' - resets the previous pause ad response & poster
Function onSendPendingPauseAdPixel()
  resetPauseAdTimers()

  if m.pauseAdOverlay.posterLoadStatus = "ready"
    if m.pauseAdOverlay.opacity > 0
      sendPauseAdPixel(m.constants.pauseAd.endPixel)
    else
      sendPauseAdPixel(m.constants.pauseAd.notUsedPixel)
    end if
  else if m.pauseAdOverlay.posterLoadStatus = "failed"
    sendPauseAdPixel(m.constants.pauseAd.errorPixel)
  end if

  resetPauseAd()
End Function


Function hidePauseAdOverlay()
  if m.pauseAdAnimation <> invalid
    stopAnimation(m.pauseAdAnimation)
  end if

  fade(m.pauseAdOverlay, "out", 0.1)
End Function