Function onKeyEvent(key As String, press As Boolean) as Boolean
  tubiLog("VideoTransportHandling.onKeyEvent key = " + key + " press: " + press.toStr())
  ' Making sure when the closed captioning overlay is displayed playerscreen only handles back button and ignore rest of the events.
  if press
    m.lastButtonPressPos = m.playerPosition

    if isButtonPressAllowed(key, m.VideoState, m.Video)
      hidePauseAdOverlay() ' added for extra safety

      ' Resetting the timer when there is any user interaction during pause
      if m.pauseAdOverlayTimer.control = "start"
        restartPauseAdTimer()
      end if

      if key = "OK"
        handleOk()
      else if key = "play"
        handlePlayPause()

      else if key = "fastforward"
        handleFastForward()

      else if key = "rewind"
        handleRewind()

      else if key = "replay"
        handleHopBack(true, 20)

      else if key = "options"
        if m.ignoreOptionsKey = false then
          showTransport()
          showBrowseWhileWatching()
          stopPauseAdTimer()
          if m.isPixelFiredForCurrentPauseAd = false

            if m.lastFiredPixelType = m.constants.pauseAd.pixelTypes.startPixel
              action = "exit_mid_pod" 'this happens if the notUsed pixel triggers after start but before imp pixel
            else
              action = "exit_pre_pod" 'this happens if the notUsed pixel triggers before start pixel
            end if
            sendPauseAdPixel(m.constants.pauseAd.pixelTypes.notUsedPixel, action)
          end if
          if m.Video.availableAudioTracks.Count() > 1 OR m.Video.availableSubtitleTracks.Count() > 0
            showClosedCaptionAudioTrackOverlay()
          end if
        end if

      else if key = "left" AND m.focusedNode.isSameNode(m.BrowseWhileWatching) = false
        'video is in playback mode and user wants to skip back
        if m.HUD.opacity = 0 AND m.focusedNode.isSameNode(m.progressBar) = false AND isActiveVideoState(m.VideoState, m.Video)
          handleSkipVideo(-10)

        'user is in skip ahead mode (the progress bar is focused) and wants to skip back.
        else if m.focusedNode.isSameNode(m.progressBar) = true AND isActiveVideoState(m.VideoState, m.Video)
          handleSkipVideo(-10)

        else if (m.playerControlExperimentType = "variant2" OR m.playerControlExperimentType = "variant3") AND m.focusedNode.isSameNode(m.sendFeedBackButton) = true
          setFocusToComponent(m.sendFeedBackButton)
        else
          'navigate the transport buttons, skipping disabled ones
          if m.focusedButtonIndex = 0
            return false
          else

            buttonComponent = m.TransportButtons
            if m.TransportLayoutGroup <> invalid
              buttonComponent = m.TransportLayoutGroup
            end if

            for i=m.focusedButtonIndex-1 to 0 step -1
              button = buttonComponent.getChild(i)
              if button.enabled then
                setFocusToComponent(button, true)
                exit for
              end if
            end for
          end if
        end if

      else if key = "right" AND m.focusedNode.isSameNode(m.BrowseWhileWatching) = false
        'video is in playback mode and user wants to skip ahead
        if m.HUD.opacity = 0 AND m.focusedNode.isSameNode(m.progressBar) = false AND isActiveVideoState(m.VideoState, m.Video)
          handleSkipVideo(10)

        'user is in skip ahead mode (the progress bar is focused) and wants to skip ahead.
        else if m.focusedNode.isSameNode(m.progressBar) = true AND isActiveVideoState(m.VideoState, m.Video)
          handleSkipVideo(10)

        else if (m.playerControlExperimentType = "variant2" OR m.playerControlExperimentType = "variant3") AND m.focusedNode.isSameNode(m.sendFeedBackButton) = true
          setFocusToComponent(m.sendFeedBackButton)
        else

          buttonComponent = m.TransportButtons
          if m.TransportLayoutGroup <> invalid
            buttonComponent = m.TransportLayoutGroup
          end if

          buttonCount = buttonComponent.getChildCount()
          if m.focusedButtonIndex = buttonCount-1
            return false
          else
            'navigate the transport buttons, skipping disabled ones
            for i=m.focusedButtonIndex + 1 to buttonCount-1
              button = buttonComponent.getChild(i)
              if button.enabled then
                setFocusToComponent(button, true)
                exit for
              end if
            end for
          end if

        end if

      else if key = "up"
        if m.focusedNode.isSameNode(m.BrowseWhileWatching) = true
          animateTransportAndBrowseWhileWatching("out")

          if m.playerControlExperimentType = "none"
            setFocusToPlaybackControl()
          else if m.playerControlExperimentType = "variant1"
            if m.top.isTrailer = true
              setFocusToComponent(m.SkipTrailerButton, true)
            else
              setFocusToComponent(m.StartButton, true)
            end if
          else if m.playerControlExperimentType = "variant2" OR m.playerControlExperimentType = "variant3"
            if m.top.isTrailer = true
              setFocusToComponent(m.SkipTrailerButton, true)
            else
              setFocusToComponent(m.PlayFromBeginning, true)
            end if
          end if

        else if m.Thumbnail.visible = false AND m.TopOverlay.opacity = 0 AND m.focusedNode.isSameNode(m.BrowseWhileWatching) = false
          showTransport()
          showBrowseWhileWatching()
        else if m.focusedNode.isSameNode(m.progressBar) = true AND m.skipCuepointsButton.visible = true
          setFocusToComponent(m.skipCuepointsButton)
        else if m.focusedNode.isSameNode(m.progressBar) = true
          if (m.playerControlExperimentType = "variant2" OR m.playerControlExperimentType = "variant3") AND m.TopOverlay.opacity = 1.0 AND m.sendFeedBackButton.visible = true
            setFocusToComponent(m.sendFeedBackButton)
          else
            setFocusToComponent(m.progressBar)
          end if
        else if m.skipCuepointsButton.hasFocus() = true
          if (m.playerControlExperimentType = "variant2" OR m.playerControlExperimentType = "variant3") AND m.TopOverlay.opacity = 1.0 AND m.sendFeedBackButton.visible = true
            setFocusToComponent(m.sendFeedBackButton)
          else
            setFocusToComponent(m.progressBar)
          end if
        else if m.focusedNode.isSameNode(m.progressBar) = false  
          if m.focusedNode.isSameNode(m.sendFeedBackButton) = true AND (m.playerControlExperimentType = "variant2" OR m.playerControlExperimentType = "variant3")
            'do nothing
          else
            setFocusToComponent(m.progressBar)
          end if
        else
          return false
        end if

      else if key = "down"
        if (m.TopOverlay.opacity = 0 AND m.Thumbnail.visible = false) AND m.focusedNode.isSameNode(m.BrowseWhileWatching) = false
          showTransport()
          showBrowseWhileWatching()
        else if m.focusedNode.isSameNode(m.progressBar) = true
          if m.playerControlExperimentType = "none"
            setFocusToComponent(m.PlayPauseButton, true)
          else if m.playerControlExperimentType = "variant1"
            if m.top.isTrailer = true
              setFocusToComponent(m.SkipTrailerButton, true)
            else
              setFocusToComponent(m.StartButton, true)
            end if
          else if m.playerControlExperimentType = "variant2" OR m.playerControlExperimentType = "variant3"
            if m.top.isTrailer = true
              setFocusToComponent(m.SkipTrailerButton, true)
            else
              setFocusToComponent(m.PlayFromBeginning, true)
            end if
          end if
        else if m.skipCuepointsButton.hasFocus() = true
          setFocusToComponent(m.ProgressBar)
        else if (m.playerControlExperimentType = "variant2" OR m.playerControlExperimentType = "variant3") AND m.focusedNode.isSameNode(m.sendFeedBackButton) = true
          if m.skipCuepointsButton.visible = true
            m.skipCuepointsButton.setFocus(true)
          else
            setFocusToComponent(m.ProgressBar)
          end if
        else if isFocusOnPlayerControl() = true AND m.top.isTrailer = false
          relatedContent = m.top.browseContent

          if relatedContent <> invalid AND relatedContent.getChildCount() > 0
            setFocusToComponent(m.BrowseWhileWatching)
            animateTransportAndBrowseWhileWatching("in")
          else
            return false
          end if

        else
          return false
        end if

      else if key = "back"
        if m.UpNext.isInFocusChain()
          m.UpNext.hide = true
          if m.UpNext.isAutoPlayOff = true AND m.VideoState = "stop"
            backButtonExit()
          else
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

            setFocusToPlaybackControl()
          end if
        else if m.VideoState = "play"
          hideBrowseWhileWatching()
          setFocusToPlaybackControl()

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

          if m.playerControlExperimentType = "none"
            setFocusToComponent(m.PlayPauseButton)
          else
            setFocusToComponent(m.progressBar)
          end if

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
  resetPauseAdOverlay()
  hidePauseAdOverlay()

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

  if m.playerControlExperimentType = "variant1" OR m.playerControlExperimentType = "variant2" OR m.playerControlExperimentType = "variant3"
    m.controlIcon.uri = "pkg:/images/transport/sgplayer/icon-pause.webp"
    fade(m.controlIcon, "in", 0.6)
  else
    fade(m.controlIcon, "out", 0.2)
  end if

  m.Video.control = "pause"
  updateVideoState("pause")

  if shouldShowTransport
    if m.HUD.opacity < 1.0
      showTransport()
    end if

    showBrowseWhileWatching()
  end if

  if m.playerControlExperimentType = "none"
    if m.focusedNode.isSameNode(m.BrowseWhileWatching) = true
      animateTransportAndBrowseWhileWatching("out")
      setFocusToPlaybackControl()
    end if
  
    m.PlayPauseButton.uri = m.buttonUris.play
    setFocusToComponent(m.PlayPauseButton)
  else
    if m.focusedNode.isSameNode(m.BrowseWhileWatching) = true
      animateTransportAndBrowseWhileWatching("out")
    end if
    setFocusToComponent(m.progressBar) 
  end if

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

    if m.isPauseAdReqInProgress = false AND m.isPixelFiredForCurrentPauseAd = true
      resetPauseAd()
      resetPauseAdTimers()
      m.isPauseAdReqInProgress = true
      startPauseAdTimer()
      m.top.getPauseAd = true
    end if

  end if
End Function


'Resume play from a paused state
Function resumeFromPause(shouldSendAnalytics)
  animateTransport("out")
  hideBrowseWhileWatching()
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

  if m.playerControlExperimentType <> "none"
    m.controlIcon.uri = "pkg:/images/transport/sgplayer/icon-play.webp"
    fade(m.controlIcon, "in", 0.6)
    fade(m.controlIcon, "out", 0.2)
    setFocusToComponent(m.progressBar)
  else
    fade(m.controlIcon, "out", 0.2)
    m.PlayPauseButton.uri = m.buttonUris.pause
    setFocusToComponent(m.PlayPauseButton)
  end if

End Function


Function resumeFromSkip()
  tubiLog("VideoTransportHandling.resumeFromSkip")
  animateTransport("out")
  hideBrowseWhileWatching(false)
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

  if m.playerControlExperimentType = "none"
    setFocusToComponent(m.PlayPauseButton)
  else
    setFocusToComponent(m.progressBar)
  end if
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
  hideBrowseWhileWatching()
  resetTransportButtons()

  if m.playerControlExperimentType = "none"
    setFocusToComponent(m.PlayPauseButton)
  else
    setFocusToComponent(m.progressBar)
  end if
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
    if m.playerControlExperimentType = "none"
      setFocusToComponent(m.StartButton)
    else
      setFocusToComponent(m.progressBar)
    end if
  else if m.VideoState <> "skip"
    playProgressEvent = getPlayProgressEvent("goToStart")
    if playProgressEvent <> invalid
      trackEvent(playProgressEvent)
    end if
  end if

  'Hiding HUD while buffering
  if m.HUD.opacity > 0.0
    animateTransport("out")
    hideBrowseWhileWatching()
    setFocusToPlaybackControl()
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
  hideBrowseWhileWatching()
  setFocusToPlaybackControl()
  resetTransportButtons()
End Function


Function handleOk()

  if m.HUD.opacity = 0 AND m.skipCuepointsButton.hasFocus() = false
    showTransport()
    showBrowseWhileWatching()
  else if (m.playerControlExperimentType = "variant2" OR m.playerControlExperimentType = "variant3") AND m.sendFeedBackButton.hasFocus() = true
    showSendFeedbackOverlay()
  else if m.focusedNode.isSameNode(m.ProgressBar) = true 
    handlePlayPause()
  else
    'do action based on the current focused button
    buttonComponent = m.TransportButtons
    if m.TransportLayoutGroup <> invalid
      buttonComponent = m.TransportLayoutGroup
    end if

    focusButtonId = buttonComponent.getChild(m.focusedButtonIndex).id
    if focusButtonId = m.SkipTrailerButton.id
      handleSkipTrailer()
    else if focusButtonId = m.StartButton.id OR focusButtonId = m.PlayFromBeginning.id
      if focusButtonId = m.PlayFromBeginning.id
        setComponentInteractionInfo("play_from_beginning")
      end if
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
    else if focusButtonId = m.EndButton.id OR focusButtonId = m.NextEpisode.id
      if focusButtonId = m.NextEpisode.id
        setComponentInteractionInfo("next_episode")
      end if
      goToNext()
    else if focusButtonId = m.closedCaptionAudioButton.id
      stopPauseAdTimer()
      if m.isPixelFiredForCurrentPauseAd = false
        sendPauseAdPixel(m.constants.pauseAd.pixelTypes.notUsedPixel, "exit_pre_pod")
      end if
      showClosedCaptionAudioTrackOverlay()
    else if focusButtonId = m.sendFeedBackButton.id
      showSendFeedbackOverlay()
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

  if m.playerControlExperimentType = "none"
    setFocusToComponent(m.PlayPauseButton)
  else
    setFocusToComponent(m.progressBar) 
  end if
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
    seekSpeed = m.scrubAmt + 1

  'increase the fast forward speed
  else if m.VideoState = "ffw"
    if m.scrubAmt < m.maxScrub
      m.scrubAmt = m.scrubAmt + 1
    else
      m.scrubAmt = 0
    end if
    m.FastForwardButton.uri = m.buttonUris.fastForwardLevels[m.scrubAmt]
    seekSpeed = m.scrubAmt + 1

  'start the fast forward
  else
    m.positionAtJumpStart = m.playerPosition
    beginScrub()
    updateVideoState("ffw")
    m.FastForwardButton.uri = m.buttonUris.fastForwardLevels[0]
    m.PlayPauseButton.uri = m.buttonUris.play
    seekSpeed = 1
  end if

  if m.playerControlExperimentType <> "none"
    m.seekIcon.uri = "pkg:/images/transport/sgplayer/icon-vector-fwd.webp"
    m.seekSpeed.text = seekSpeed
    childrenCount = m.seekControlGroup.getChildCount()
    m.seekControlGroup.removeChildrenIndex(childrenCount, 0)
    m.seekControlGroup.appendChild(m.seekIcon)
    m.seekControlGroup.appendChild(m.seekSpeed)
    m.thumbnail.showBorder = true
  end if

  if m.playerControlExperimentType = "none"
    setFocusToComponent(m.FastForwardButton)
  else
    setFocusToComponent(m.progressBar)
  end if
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
    seekSpeed = m.scrubAmt + 1

  'increase the rewind speed
  else if m.VideoState = "rew"
    if m.scrubAmt < m.maxScrub
      m.scrubAmt = m.scrubAmt + 1
    else
      m.scrubAmt = 0
    end if
    m.RewindButton.uri = m.buttonUris.rewindLevels[m.scrubAmt]
    seekSpeed = m.scrubAmt + 1

  'start the rewind
  else
    m.positionAtJumpStart = m.playerPosition
    beginScrub()
    updateVideoState("rew")
    m.RewindButton.uri = m.buttonUris.rewindLevels[0]
    m.PlayPauseButton.uri = m.buttonUris.play
    seekSpeed = 1
  end if

  if m.playerControlExperimentType <> "none"
    m.seekIcon.uri = "pkg:/images/transport/sgplayer/icon-vector-rew.webp"
    m.seekSpeed.text = seekSpeed
    childrenCount = m.seekControlGroup.getChildCount()
    m.seekControlGroup.removeChildrenIndex(childrenCount, 0)
    m.seekControlGroup.appendChild(m.seekSpeed)
    m.seekControlGroup.appendChild(m.seekIcon)
    m.thumbnail.showBorder = true
  end if

  if m.playerControlExperimentType = "none"
    setFocusToComponent(m.RewindButton)
  else
    setFocusToComponent(m.progressBar)
  end if
End Function


'handles HopForward button selection
Function handleHopForward(duration)
  if m.VideoState = "ffw" or m.VideoState = "rew"
    endScrub(false)
    if m.playerControlExperimentType = "none"
      setFocusToComponent(m.HopForwardButton)
    else
      setFocusToComponent(m.progressBar)
    end if
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
    hideBrowseWhileWatching()
    setFocusToPlaybackControl()
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
  if m.playerControlExperimentType = "none"
    setFocusToComponent(m.HopBackButton) 'necessary because there is a dedicated hop back button on certain roku remotes
  else
    setFocusToComponent(m.progressBar)
  end if

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

  if m.HUD.opacity > 0.0
    animateTransport("out")
    hideBrowseWhileWatching()
    setFocusToPlaybackControl()
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
Function handleSkipVideo(amt)
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

  if m.HUD.opacity = 0
    showTransport()
  end if

  showBrowseWhileWatching()
  m.PlayPauseButton.uri = m.buttonUris.play

  if m.focusedNode.isSameNode(m.ProgressBar) = false
    setFocusToComponent(m.ProgressBar)
  end if

  if m.playerControlExperimentType = "variant3"
    hideTopOverlay()
  end if
  
  showThumbnail()
  hideSeekGroup()

  if m.playerControlExperimentType <> "none"
    if amt = 10
      m.quickSeekIcon.uri = "pkg:/images/transport/sgplayer/forward-10.webp"
    else
      m.quickSeekIcon.uri = "pkg:/images/transport/sgplayer/rewind-10.webp"
    end if
    
    duration = m.Video.duration
    position = m.playerPosition + amt

    if duration <> invalid then
  
      if duration < 3600
        currentSeekPosition = formatLengthasMinsAndSecs(position)
      else
        currentSeekPosition = formatLengthAsTimestamp(position)
      end if

      m.quickSeekLabel.text = currentSeekPosition
      showQuickSeekLabelAndIcon()

    end if  
    
  end if

  updatePlayerPosition(amt)
End Function


' Displays the closed caption and audio track selection overlay.
Function showClosedCaptionAudioTrackOverlay()
  m.closedCaptionAndAudioSelectionOverlay.globalCaptionMode = m.video.globalCaptionMode
  m.closedCaptionAndAudioSelectionOverlay.availableClosedCaptionTracks = m.video.availableSubtitleTracks
  m.closedCaptionAndAudioSelectionOverlay.availableAudioTracks = m.video.availableAudioTracks
  m.closedCaptionAndAudioSelectionOverlay.setFocus(true)
  setFocusToComponent(m.closedCaptionAudioButton)
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


' Displays the SendFeedback selection overlay.
Function showSendFeedbackOverlay()
  if m.top.appMode <> "KIDS_MODE"
    m.isSendFeedbackOverlayShowing = true
    setFocusToComponent(m.sendFeedBackButton)
    fade(m.sendFeedbackSelectionOverlayGroup, "in", 0.6)
    m.sendFeedbackSelectionOverlay.itemList = getItemListForSendFeedback()
    m.sendFeedbackSelectionOverlay.setFocus(true)

    'Send Dialog event when sendFeedback button clicked.
    trackingPageInfo = m.top.trackingPageInfo
    trackEvent({
      type: "dialog"
      values: {
        dialog_type: "INFORMATION"
        pageOneof: m.Tracking.getAnalyticsPage(trackingPageInfo.pageType, trackingPageInfo.pageValues)
        dialog_action: "SHOW"
        dialog_sub_type: "player_problem"
      }
    })
  end if
End Function


' Hides the send feedback on video player selection overlay.
Function hideSendFeedbackOverlay()
  if m.isSendFeedbackOverlayShowing = true
    m.isSendFeedbackOverlayShowing = false
    m.sendFeedbackSelectionOverlay.setFocus(false)
    removeOverLayItems()
    fade(m.sendFeedbackSelectionOverlayGroup, "out", 0.1)

    if m.playerControlExperimentType = "variant2" OR m.playerControlExperimentType = "variant3"
      m.sendFeedBackButton.setFocus(true)
    else
      m.top.setFocus(true)
    end if

    'Send dismiss dialog event when user presses back or closed overlay.
    trackingPageInfo = m.top.trackingPageInfo
    if trackingPageInfo <> invalid AND isNonEmptyString(trackingPageInfo.pageType) = true
      trackEvent({
        type: "dialog"
        values: {
          dialog_type: "INFORMATION"
          pageOneof: m.Tracking.getAnalyticsPage(trackingPageInfo.pageType, trackingPageInfo.pageValues)
          dialog_action: "DISMISS_DELIBERATE"
          dialog_sub_type: "player_problem"
        }
      })
    end if
  end if
End Function


Function getItemListForSendFeedback()
  sendFeedbackMenuItems = [
    {
      id: "cancel"
      title: getTranslation("dialog_button_cancel")
    },
    {
      id: "start_from_beginning_after_ads"
      title: getTranslation("send_feedback_menuItem_start_from_beginning_after_ads")
    },
    {
      id: "stuck_in_ads"
      title: getTranslation("send_feedback_menuItem_stuck_in_ads")
    },
    {
      id: "freezing_after_ads"
      title: getTranslation("send_feedback_menuItem_freezing_after_ads")
    },
    {
      id: "black_screen"
      title: getTranslation("send_feedback_menuItem_seeing_a_black_screen")
    },
    {
      id: "buffering_before_video"
      title: getTranslation("send_feedback_menuItem_buffering_before_video")
    },
    {
      id: "buffering_during_video"
      title: getTranslation("send_feedback_menuItem_buffering_during_video")
    },
    {
      id: "buffering_after_ads"
      title: getTranslation("send_feedback_menuItem_buffering_after_ads")
    },
    {
      id: "video_freeze"
      title: getTranslation("send_feedback_menuItem_video_freeze")
    },
    {
      id: "fast_forward_or_rewind_failed"
      title: getTranslation("send_feedback_menuItem_fastforward_rewind_failed")
    },
    {
      id: "captions_not_working"
      title: getTranslation("send_feedback_menuItem_captions_not_working")
    },
    {
      id: "audio_not_working"
      title: getTranslation("send_feedback_menuItem_audio_not_working")
    },
    {
      id: "audio_video_out_of_sync"
      title: getTranslation("send_feedback_menuItem_audio_video_out_of_sync")
    },
    {
      id: "caption_selection_not_persisting"
      title: getTranslation("send_feedback_menuItem_caption_selection_not_persisting")
    },
    {
      id: "captions_out_of_sync"
      title: getTranslation("send_feedback_menuItem_captions_out_of_sync")
    },
    {
      id: "audio_not_working"
      title: getTranslation("send_feedback_menuItem_audio_not_working")
    },
    {
      id: "video_does_not_play"
      title: getTranslation("send_feedback_menuItem_video_does_not_play")
    }
  ]

  node = CreateObject("roSGNode", "ContentNode")
  node.id = "sendFeedbackMenu"
  node.update(sendFeedbackMenuItems, true)

  overlayItems = [
    {
      id: "sendFeedbackOnPlayer"
      hasSubMenu: false
      content: node
      numRows: 10
    }
  ]

  if m.playerControlExperimentType = "none" OR m.playerControlExperimentType = "variant1"
    overlayItems[0].title = getTranslation("send_feedback_overlay_title")
    overlayItems[0].subtitle = getTranslation("send_feedback_overlay_subtitle")
  end if

  return overlayItems
End Function


'handles the Skip Intro selection
Function onSkipCuepointsButtonSelected()
  tubiLog("VideoTransportHandling.onSkipCuepointsButtonSelected")
  if m.HUD.opacity > 0.0
    animateTransport("out")
    hideBrowseWhileWatching()
    setFocusToPlaybackControl()
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

  showBrowseWhileWatching()
  if m.playerControlExperimentType = "variant3"
    hideTopOverlay()
  end if
  fade(m.controlIcon, "out", 0.2)
  showThumbnail()

  if m.playerControlExperimentType <> "none"
    hideQuickSeekLabelAndIcon()
    showSeekGroup()
  end if
  
  m.scrubTimespan.mark()

  ' playProgress analytics
  if m.VideoState <> "skip"
    playProgressEvent = getPlayProgressEvent("beginScrub")
    if playProgressEvent <> invalid
      trackEvent(playProgressEvent)
    end if
  end if

  updatePlayerLogLib(m.playerLogLib, "setIsSeeking")
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
  hideBrowseWhileWatching(false)
  resetTransportButtons()
  m.PlayPauseButton.uri = m.buttonUris.pause

  if m.playerControlExperimentType = "none"
    setFocusToComponent(m.PlayPauseButton)
  else
    setFocusToComponent(m.progressBar)
    fade(m.controlIcon, "out", 0.2)
  end if

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
      m.playerPosition = m.playerPosition - scrubTime
    end if

  else if m.VideoState = "ffw"
    if m.playerPosition + scrubTime < 0
      m.playerPosition = 0
    else if m.playerPosition + scrubTime > nMaxScrub
      m.playerPosition = nMaxScrub
    else
      m.playerPosition = m.playerPosition + scrubTime
    end if
  end if

  m.scrubTimespan.mark()

  updateTransport()
End Function


'handles replay key press or HopBack button selection
'@position: float, should be m.playerPosition in most cases
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

  updatePlayerLogLib(m.playerLogLib, "setSeekEndPosition", position)

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
  hideSeekGroup()
  hideQuickSeekLabelAndIcon()

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

  if m.didSeeAdCountdown = true
    '//if the user saw the ad-countdown before seeking, then start playing the ad immediately after the seek is done.

    adMissedInfo = {
      adPosition: adPosition * 1000 'ms
    }
    if m.top.adState = "adsPending"
      logInfo(formatJson(adMissedInfo), "videoInfo", "ad-missed-recovered")
    end if

    showAdBreak()
    m.showRatings = true
  else if shouldAdBreak = true
    unObserveClosedCaptionAndAudioTrack()
    ' leave m.VideoState = "play" because from the component's perspective video is still playing

    adMissedInfo = {
      adPosition: adPosition * 1000 'ms
    }
    if m.top.adState = "adsPending"
      logInfo(formatJson(adMissedInfo), "videoInfo", "ad-missed-recovered")
    end if

    m.Video.control = "stop"
    m.top.adPosition = adPosition
    m.top.adControl = "seek"
    updatePlayerLogLib(m.playerLogLib, "setAdType", "seek")
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

    progressBarRight = 192 + (m.ProgressBar.width * percentComplete)
    thumbnailXOffset = progressBarRight - m.Thumbnail.width / 2

    if thumbnailXOffset > m.thumbnailMaxXOffset
      thumbnailXOffset = m.thumbnailMaxXOffset
    end if
    if thumbnailXOffset < m.thumbnailMinXOffset
      thumbnailXOffset = m.thumbnailMinXOffset
    end if

    m.Thumbnail.translation = [thumbnailXOffset, m.Thumbnail.translation[1]]
    m.Thumbnail.jumpToSprite = m.playerPosition \ m.constants.player.thumbnailFrequency
    quickSeekLabelWidth = m.quickSeekLabel.boundingRect().width
    m.quickSeekLabel.translation = [thumbnailXOffset + m.Thumbnail.width / 2 - quickSeekLabelWidth / 2, m.Thumbnail.translation[1] - 40]
    m.seekGroup.translation = [thumbnailXOffset + m.Thumbnail.width / 2, m.Thumbnail.translation[1] - 30]
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
  if m.sendFeedBackButton.hasField("focusState") = true
    m.sendFeedBackButton.focusState = false
  end if
End Function


'@sayAudioText: boolean, true if we want to announce the audio guide.
Function setFocusToPlaybackControl(sayAudioText = false)

  if m.playerControlExperimentType = "none"
    if m.VideoState = "ffw"
      setFocusToComponent(m.FastForwardButton, sayAudioText)
    else if m.VideoState = "rew"
      setFocusToComponent(m.RewindButton, sayAudioText)
    else
      setFocusToComponent(m.PlayPauseButton, sayAudioText)
    end if
  else
    setFocusToComponent(m.progressBar)
  end if

End Function


'If the passed component is focusable, then it sets the focus to component or else it sets focus to m.top
'
'@component: roSGNode, child node of videoplayerscreen
'@sayAudioText: boolean, true if we want to announce the audio guide.
'
'side effects... updates the m.focusedNode with passed component
'side effects... if the passed component is button, then it updates the m.focusedButtonIndex with button index
Function setFocusToComponent(component, sayAudioText = false)
  m.focusedNode = component
  'set focused/unfocused UI on each button in the transport bar as necessary

  buttonComponent = m.TransportButtons
  if m.TransportLayoutGroup <> invalid
    buttonComponent = m.TransportLayoutGroup
  end if

  for i=0 to buttonComponent.getChildCount()-1
    button = buttonComponent.getChild(i)
    if component.id = button.id AND button.hasField("focusState") = true
      m.focusedButtonIndex = i
      button.focusState = true
    else if button.hasField("focusState") = true
      button.focusState = false
    end if
  end for

  if isFocusable(component) = true
    m.focusedNode.setFocus(true)
  else
    ' remove all child focus & set the focus to screen
    removeFocusForAllChildComponents()
    setFocusOnTop()
  end if

  ' Use case when we will pass true are as below. Following general standards based on testing of other competitor apps.
  ' When we focus on the skip cuepoints button.
  ' When the user navigates within the transport bar.
  ' When the user moves focus into the transport control icon from the progress bar.
  if sayAudioText = true
    sayFocusedButtonAudioGuide(component.id)
  end if

End Function


'@component: roSGNode, child node of videoplayerscreen
Function isFocusable(component)
  focusable = false

  if component.isSameNode(m.skipCuepointsButton) = true
    focusable = true
  else if component.isSameNode(m.BrowseWhileWatching) = true
    focusable = true
  else if component.isSameNode(m.UpNext) = true
    focusable = true
  else if component.isSameNode(m.pauseAdOverlay) = true
    focusable = true
  else if component.isSameNode(m.progressBar) = true
    focusable = true
  else if component.isSameNode(m.sendFeedBackButton) = true
    focusable = true
  end if

  return focusable
End Function


Function setFocusOnTop()
  m.top.setFocus(true)
End Function


Function removeFocusForAllChildComponents()
  'setting all child component's focus to false
  if m.skipCuepointsButton.isInFocusChain() = true
    m.skipCuepointsButton.setFocus(false)
  end if

  if m.BrowseWhileWatching.isInFocusChain() = true
    m.BrowseWhileWatching.setFocus(false)
  end if

  if m.UpNext.isInFocusChain() = true
    m.UpNext.setFocus(false)
  end if

  if m.pauseAdOverlay.isInFocusChain() = true
    m.pauseAdOverlay.setFocus(false)
  end if

  if m.progressBar.isInFocusChain() = true
    m.progressBar.setFocus(false)
  end if

  if m.sendFeedbackButton.isInFocusChain() = true
    m.sendFeedbackButton.setFocus(false)
  end if

End Function


Function isFocusOnPlayerControl()

  buttonComponent = m.TransportButtons
  if m.TransportLayoutGroup <> invalid
    buttonComponent = m.TransportLayoutGroup
  end if

  for i=0 to buttonComponent.getChildCount()-1
    transportButton = buttonComponent.getChild(i)

    if m.focusedNode.isSameNode(transportButton)
      return true
    end if

  end for

  return false
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
  else if focusButtonId = m.sendFeedBackButton.id
    audioGuideText = audioGuideHints.sendFeedbackButtonHint
  end if

  if isNonEmptyString(audioGuideText)
    readAudioGuideText(audioGuideText)
  end if
End Function


'show transport
Function showTransport()
  ' update transport thumbnails before showing the transport UI
  updateTransport()

  if m.playerControlExperimentType = "none"
    updatePlayPauseUri()
  end if

  'Send exposure event for send feedback when transport control is visible
  if m.top.appMode <> "KIDS_MODE"
    getExperimentResource("roku_send_feedback_on_player", "roku_send_feedback_on_player_v1")
  end if

  creditCuePoints = getCreditCuepointsFromContent(m.top.content)
  if m.top.hasFocus() = true AND isSkipIntroCuePointsReached(creditCuePoints) = false
    ' Only set focus on the play/pause button if the video player has focus (as opposed to some other UI)
    ' and the skip cuepoints button should not be focused (ie. nowPos is not within intro)

    if m.playerControlExperimentType <> "none"
      m.focusedNode = m.progressBar
    else
       'm.focusedNode holds the node/component which helps setting/unsetting focus to component/m.top on video player screen
      m.focusedNode = m.PlayPauseButton
    end if

    setFocusToComponent(m.focusedNode)

  end if

  animateTransport("in")
End Function


'aggregates all the animation for showing/hiding the transport
'@direction: string, value may be "out" or "in"
Function animateTransport(direction)
  tubiLog("VideoTransportHandling.AnimateTransport, direction = " + direction)
  handleSkipCuepointsButtonOnAnimateTransport(direction)

  if direction = "in" AND m.ratingOverlay.opacity = 1.0
    hideRatingGradient()
    fade(m.VideoOverlay, direction, 0.4)
    showTopOverlay()
  else if direction = "out" AND m.ratingOverlay.opacity = 1.0
    hideTopOverlay()
    fade(m.VideoOverlay, direction, 0.4)
    showRatingGradient()
  else
    fade(m.VideoOverlay, direction, 0.4)

    if direction = "in"
      showTopOverlay()
    else
      hideTopOverlay()
    end if
  end if

  'Changing opacity to 1, since we changed the opacity to 0 when hiding BrowseWhileWatching
  if direction = "in" AND m.TransportButtons.opacity = 0.0
    fade(m.TransportButtons, "in", 0.4)
  end if

  m.hudState = slideFade(m.HUD, "below", direction, 0.6)
  m.hudState.observeFieldScoped("state" , "onHudStateChanged")
End Function


Function onHudStateChanged(msg)
  state = msg.getData()
  if state = "stopped" AND m.HUD.opacity = 0
    if m.skipCuepointsButton.visible = true
      skipCuepointsButtonTransLation = m.skipCuepointsButton.translation
      slideTo(m.skipCuepointsButton,[skipCuepointsButtonTransLation[0], m.skipCuepointsButtonDownTranslation], 0.6)
    end if
  end if
End Function


'@direction: string, value may be "out" or "in"
Function handleSkipCuepointsButtonOnAnimateTransport(direction)
  tubiLog("VideoTransportHandling.handleSkipCuepointsButtonOnAnimateTransport")
  skipCuepointsButtonTransLation = m.skipCuepointsButton.translation
  creditCuePoints = getCreditCuepointsFromContent(m.top.content)
  currentCuepoint = getCurrentCuepoint(creditCuePoints)

  if direction = "in"
    if isNonEmptyString(currentCuepoint) = true
      if canSkipCuepointsButtonBeShown(currentCuepoint, true) = true AND m.skipCuepointsButtonTimer = invalid AND isNonEmptyString(m.skipCuepointsButton.text) = true
        showSkipCuepointsButton()
      end if
      slideTo(m.skipCuepointsButton,[skipCuepointsButtonTransLation[0], m.skipCuepointsButtonUpTranslation], 0.6)
    end if
  else if direction = "out"
    if m.focusedNode.isSameNode(m.BrowseWhileWatching) = true
      hideSkipCuepointsButton()
    else if m.skipCuepointsButton.visible = true AND m.skipCuepointsButtonTimer <> invalid
      slideTo(m.skipCuepointsButton,[skipCuepointsButtonTransLation[0], m.skipCuepointsButtonDownTranslation], 0.6)
      m.skipCuepointsButton.setFocus(true)
    else if m.skipCuepointsButton.visible = true AND m.skipCuepointsButtonTimer = invalid
      hideSkipCuepointsButton()
    end if
  end if
End Function


' update the progress bar time
Function updateTransportTimes()
  duration = m.Video.duration

  if duration <> invalid then

    if m.playerControlExperimentType <> "none" AND duration < 3600
      currentSeekPosition = formatLengthasMinsAndSecs(m.playerPosition)
      remainingTime = formatLengthasMinsAndSecs(duration - m.playerPosition)
    else
      currentSeekPosition = formatLengthAsTimestamp(m.playerPosition)
      remainingTime = formatLengthAsTimestamp(duration - m.playerPosition)
    end if

    m.ElapsedLabel.text = currentSeekPosition
    m.currentSeekLabel.text = currentSeekPosition
    m.RemainingLabel.text = "-" + remainingTime
    m.RemainingLabel.translation = [1920 - m.marginX - m.RemainingLabel.boundingRect().width - 10, m.RemainingLabel.translation[1]]
  end if
End Function


Function showThumbnail()
  tubiLog("videoTransportHandling.showThumbnail")
  if m.Thumbnail.spriteUrls <> invalid AND m.Thumbnail.spriteUrls.count() > 0
    m.Thumbnail.visible = true
  else
    m.Thumbnail.visible = false
    hideSeekGroup()
    hideQuickSeekLabelAndIcon()
  end if
End Function


Function showSeekGroup()
  m.seekGroup.visible = true
End Function


Function hideSeekGroup()
  m.seekGroup.visible = false
End Function


Function showQuickSeekLabelAndIcon()
  m.quickSeekLabel.visible = true
  m.quickSeekIcon.visible = true
End Function


Function hideQuickSeekLabelAndIcon()
  m.quickSeekLabel.visible = false
  m.quickSeekIcon.visible = false
End Function


Function updatePlayPauseUri()
  if m.videoState = "pause"
    m.PlayPauseButton.uri = m.buttonUris.play
  else
    m.PlayPauseButton.uri = m.buttonUris.pause
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
  if isActiveVideoState(videoState, videoNode) = false AND disabledKeys[key] = true
    isAllowed = false
  end if

  'When upnext is focused, only back keys are allowed.
  if m.UpNext.isInFocusChain() = true AND disabledKeys[key] = true
    isAllowed = false
  end if

  ' If closed caption and audio overlay is showing then we ignore button press in the screen level.
  if m.isClosedCaptionAudioOverlayShowing = true
    isAllowed = false
  end if

  if m.isSendFeedbackOverlayShowing = true
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
      m.pauseAdOverlay.posterUri = pauseAdResponse.mediaUrl
    else
      if m.lastFiredPixelType = m.constants.pauseAd.pixelTypes.startPixel
        action = "exit_mid_pod" 'this happens if the notUsed pixel triggers after start but before imp pixel
      else
        action = "exit_pre_pod" 'this happens if the notUsed pixel triggers before start pixel
      end if
      sendPauseAdPixel(m.constants.pauseAd.pixelTypes.notUsedPixel, action)
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
    if m.lastFiredPixelType = m.constants.pauseAd.pixelTypes.startPixel
      'this happens if the notUsed pixel triggers after start but before imp pixel
      sendPauseAdPixel(m.constants.pauseAd.pixelTypes.notUsedPixel, "exit_mid_pod")
    end if
    sendPauseAdPixel(m.constants.pauseAd.pixelTypes.endPixel)
  else
    sendPauseAdPixel(m.constants.pauseAd.pixelTypes.notUsedPixel, "exit_pre_pod")
  end if

  resetPauseAdTimers()
  resetPauseAd()

  if m.HUD.opacity < 1.0
    showTransport()
  end if

  showBrowseWhileWatching()
End Function


'onPauseAdOverlayTimer triggers 5 seconds after the user pauses the video
Function onPauseAdOverlayTimer()
  m.pauseAdOverlay.unobserveFieldScoped("posterLoadStatus")

  if m.videoState = "pause"
    loadStatus = m.pauseAdOverlay.posterLoadStatus

    if loadStatus = "ready"
      showPauseAd()
    else if loadStatus = "failed"
      sendPauseAdPixel(m.constants.pauseAd.pixelTypes.errorPixel)
    else if loadStatus = "loading"
      m.pauseAdOverlay.observeFieldScoped("posterLoadStatus", "onPauseAdPosterLoadStatus")
    end if

  else
    sendPauseAdPixel(m.constants.pauseAd.pixelTypes.notUsedPixel, "exit_pre_pod")
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
      sendPauseAdPixel(m.constants.pauseAd.pixelTypes.errorPixel)
    end if

  else
    m.pauseAdOverlay.unobserveFieldScoped("posterLoadStatus")
    sendPauseAdPixel(m.constants.pauseAd.pixelTypes.notUsedPixel, "exit_pre_pod")
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

  ' When PauseAd appears, we will close the sendFeed overlay to avoid the focus issues.
  hideSendFeedbackOverlay()

  hideBrowseWhileWatching()
  m.pauseAdAnimation = fade(m.pauseAdOverlay, "in", 0.6, 0.4)
  sendPauseAdPixel(m.constants.pauseAd.pixelTypes.startPixel)
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
    sendPauseAdPixel(m.constants.pauseAd.pixelTypes.impTrackingPixel)
  end if
End Function


'resetPauseAd resets the posters in pauseAdOverlay and invalidate the pauseAdResponse
Function resetPauseAd()
  if m.pauseAdOverlay <> invalid
    m.pauseAdOverlay.posterUri = ""

    if m.pauseAdAnimation <> invalid
      stopAnimation(m.pauseAdAnimation)
    end if

  end if
  m.top.pauseAdResponse = invalid
End Function


'resetPauseAdTimers resets the pauseAd related timers
Function resetPauseAdTimers()
  stopPauseAdTimer()
  stopImpTrackingTimer()
End Function


'restartPauseAdTimer restarts the pause ad timer
Function restartPauseAdTimer()
  if m.pauseAdOverlayTimer <> invalid
    stopPauseAdTimer()
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
'@action: String, (optional) only used for "notUsedPixel". Possible values are "exit_pre_pod" / "exit_mid_pod".
Function sendPauseAdPixel(pixelType = "", action = "")
  pauseAdResponse = m.top.pauseAdResponse
  pixelUrls = []

  if pauseAdResponse <> invalid
    if pixelType = m.constants.pauseAd.pixelTypes.startPixel
      pixelUrls = pauseAdResponse.startPixels
    else if pixelType = m.constants.pauseAd.pixelTypes.impTrackingPixel
      pixelUrls = pauseAdResponse.impTrackingPixels
    else if pixelType = m.constants.pauseAd.pixelTypes.endPixel
      pixelUrls = pauseAdResponse.endPixels
    else if pixelType = m.constants.pauseAd.pixelTypes.notUsedPixel
      pixelUrls = pauseAdResponse.notUsedPixels
    else if pixelType = m.constants.pauseAd.pixelTypes.errorPixel
      pixelUrls = pauseAdResponse.errorPixels
    end if
  end if

  for each pixelUrl in pixelUrls
    if isNonEmptyString(pixelUrl)
      m.isPixelFiredForCurrentPauseAd = true

      if pixelType = m.constants.pauseAd.pixelTypes.notUsedPixel AND isNonEmptyString(action) = true
        pixelUrl = m.adsLimited.replaceMacro(pixelUrl, "[TUBI:NOT_USED_ACTION]", action)
      else if pixelType = m.constants.pauseAd.pixelTypes.errorPixel
        pixelUrl = m.adsLimited.replaceMacro(pixelUrl, "[ERRORCODE]", "401")
      end if

      m.top.sendPauseAdPixel = pixelUrl
    end if
  end for

  m.lastFiredPixelType = pixelType
End Function


' onSendPendingPauseAdPixel will be triggered when user presses Home key on remote when video player is visible.
' This function does below
' - resets the pause ad related timers
' - sends missed pixels for pause ad
' - resets the previous pause ad response & poster
Function onSendPendingPauseAdPixel()
  resetPauseAdTimers()

  if m.pauseAdOverlay.posterLoadStatus = "ready"

    if m.lastFiredPixelType = m.constants.pauseAd.pixelTypes.startPixel
      sendPauseAdPixel(m.constants.pauseAd.pixelTypes.notUsedPixel, "exit_mid_pod")
      sendPauseAdPixel(m.constants.pauseAd.pixelTypes.endPixel)
    else if m.lastFiredPixelType = m.constants.pauseAd.pixelTypes.impTrackingPixel
      sendPauseAdPixel(m.constants.pauseAd.pixelTypes.endPixel)
    else
      sendPauseAdPixel(m.constants.pauseAd.pixelTypes.notUsedPixel, "exit_pre_pod")
    end if

  else if m.pauseAdOverlay.posterLoadStatus = "failed"
    sendPauseAdPixel(m.constants.pauseAd.pixelTypes.errorPixel)
  end if

  resetPauseAd()
End Function


Function hidePauseAdOverlay()
  if m.pauseAdAnimation <> invalid
    stopAnimation(m.pauseAdAnimation)
  end if

  fade(m.pauseAdOverlay, "out", 0.1)
End Function


' animateBrowseWhileWatching function helps to show the BrowseWhileWatching at center of screen and also helps to move the BrowseWhileWatching to bottom of the screen based on param value
'
' @direction: String - in or out
'   if the direction value is "in",
'     - hide overlay
'     - hide TransportButtons
'     - move the position of rating info
'     - move the progress bar to top of screen
'     - show BrowseWhileWatching info panel & set focus to BrowseWhileWatching row
'     - hide Skip buttons if any

'   if the direction value is "out",
'     - show Skip buttons if any
'     - moves the position of rating info
'     - show overlay
'     - move the progress bar to bottom of screen
'     - hide BrowseWhileWatching info panel & BrowseWhileWatching row
'     - show TransportButtons
Function animateTransportAndBrowseWhileWatching(direction)

  if direction = "in"
    m.Thumbnail.visible = false
    hideSeekGroup()
    hideQuickSeekLabelAndIcon()

    handleSkipCuepointsButtonOnAnimateTransport("out")
    fade(m.TopOverlay, "out", 0.4)
    fade(m.TransportButtons, "out", 0.4)
    fade(m.VideoOverlay, "out", 0.4)
    fade(m.VideoBrowseWhileWatchingOverlay, "in", 0.4)
    hideRatingOverlay()
    slideTo(m.HUD, [0, -696], 0.6)
    m.BrowseWhileWatching.open = true

    if m.playerControlExperimentType <> "none"
      fade(m.controlIcon, "out", 0.6)
    end if

  else
    if m.skipCuepointsButtonTimer <> invalid
      showSkipCuepointsButton()
    end if

    if m.VideoState = "ffw" or m.VideoState = "rew"
      if m.playerControlExperimentType = "variant3"
        hideTopOverlay()
      end if
      if m.playerControlExperimentType <> "none"
        hideQuickSeekLabelAndIcon()
        showSeekGroup()
      end if
      m.Thumbnail.visible = true
    else
      fade(m.TopOverlay, "in", 0.6, 0.2)
    end if

    fade(m.VideoBrowseWhileWatchingOverlay, "out", 0.4)
    fade(m.VideoOverlay, "in", 0.4)
    slideTo(m.HUD, [0, 0], 0.6)
    m.BrowseWhileWatching.close = true
    fade(m.TransportButtons, "in", 0.4)

    if m.playerControlExperimentType <> "none"
      if m.videoState = "pause"
        fade(m.controlIcon, "in", 0.6)
      end if
    end if

  end if

End Function


' show BrowseWhileWatching row on bottom of the screen and fire exposure event
Function showBrowseWhileWatching()
  if m.top.appMode <> "KIDS_MODE" AND m.top.isTrailer = false
    content = m.top.browseContent

    'fire exposure event when BrowseWhileWatching row is displayed at bottom area of the screen
    if content <> invalid AND content.getChildCount() > 0
      m.BrowseWhileWatching.jumpToRowItem = [0,0]
      m.BrowseWhileWatching.isLoading = false
    end if

    m.BrowseWhileWatching.show = true

  end if
End Function


' hideBrowseWhileWatching does below tasks
'   - hide BrowseWhileWatching info panel
'   - move BrowseWhileWatching row to bottom of the screen & hide it
'   - Removing focus from BrowseWhileWatching row
'   - Setting focus to Video player
'   - move the position of rating info
'   - show skip cue point button if applicable
'   - show skipSignUp Save Progress button if applicable
'@showSignUpButton: boolean, used to show the signup button and incase of ffw/rew/skip we will hide the signup button.
Function hideBrowseWhileWatching(showSignUpButton = true)
  fade(m.VideoBrowseWhileWatchingOverlay, "out", 0.4)
  m.BrowseWhileWatching.hide = true

  if m.BrowseWhileWatching.opacity > 0
    m.BrowseWhileWatching.showInfoPanel = false
    m.BrowseWhileWatching.setFocus(false)

    if m.ratingOverlay.opacity = 1.0
      showRatingGradient()
    end if

    if m.skipCuepointsButtonTimer <> invalid
      showSkipCuepointsButton()
    end if
  end if
End Function


Function showRatingGradient()
  slideTo(m.ratingOverlay, [0,0], 0.6)
  fade(m.ratingGradient, "in", 0.6)
End Function


Function hideRatingGradient()
  slideTo(m.ratingOverlay, [0, m.ratingOverlayAnimatedPositionY], 0.6)
  fade(m.ratingGradient, "out", 0.2)
End Function


Function showTopOverlay()
  fade(m.TopOverlay, "in", 0.6, 0.2)
End Function


Function hideTopOverlay()
  fade(m.TopOverlay, "out", 0.2)
End Function


Function onShowBrowseWhileWatchingInFullScreen()
  fade(m.VideoBrowseWhileWatchingOverlay, "in", 0.4)
  m.HUD.translation = [0, -696]
  fade(m.HUD, "in", 0.6)
  m.BrowseWhileWatching.showInFullScreen = true
  m.BrowseWhileWatching.setFocus(true)
End Function


'@buttonValue: String, value used in button_value attribute of analytic event
Function setComponentInteractionInfo(buttonValue)
  componentValues = {
    button_type: "TEXT"
    button_value: buttonValue
  }

  pageValues =  {video_id: m.top.content.id.toInt()}

  if pageValues.video_id <> invalid
    trackingPageInfo = m.top.trackingPageInfo
    pageOneof = m.Tracking.getAnalyticsPage(trackingPageInfo.pageType, trackingPageInfo.pageValues)
    componentOneof = m.tubiTrackingInfo.getAnalyticsComponent("button_component", componentValues)

    m.top.componentInteractionInfo = {
      pageOneof: pageOneof
      componentOneof: componentOneof
      user_interaction: "CONFIRM"
    }
  end if
End Function