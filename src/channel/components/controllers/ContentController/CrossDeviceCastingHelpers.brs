' CrossDeviceCastingHelpers.brs
' ContentController helpers for Voyager cross-device communication.
' Manages the interaction between LongPollingTask and VideoPlayerScreen, and handles commands from other devices.


' Initialize Long Polling Task and set up observers
' Should be called during ContentController init if needed
Function initLongPollingTask() as Void
  logDebug("CrossDeviceCastingHelpers.initLongPollingTask")
  m.longPollingTask = CreateObject("roSGNode", "LongPollingTask")
  m.longPollingTask.observeFieldScoped("connectionState", "onCastingConnectionStateChanged")
  m.longPollingTask.observeFieldScoped("receivedMessages", "onCastingMessagesReceived")
  m.longPollingTask.observeFieldScoped("state", "onLongPollingTaskStateChanged")
  m.longPollingTask.control = "run"
End Function


' Destroy the Long Polling Task and remove all observers
' Should be called after the task has stopped to free resources before creating a new instance
Function destroyLongPollingTask() as Void
  if m.longPollingTask = invalid
    return
  end if

  logDebug("CrossDeviceCastingHelpers.destroyLongPollingTask")
  m.longPollingTask.unobserveFieldScoped("connectionState")
  m.longPollingTask.unobserveFieldScoped("receivedMessages")
  m.longPollingTask.unobserveFieldScoped("state")
  m.longPollingTask = invalid
End Function


' Start a Voyager session using room ID from m.deeplinkContent
Function startCastingSession() as Void
  if isNonEmptyString(m.deeplinkContent.roomId) = false
    logWarn("CrossDeviceCastingHelpers.startCastingSession - No room ID")
    resetDeeplinkValues()
    return
  end if

  roomId = m.deeplinkContent.roomId
  isActive = false
  if m.longPollingTask <> invalid
    connectionState = m.longPollingTask.connectionState
    isActive = (connectionState = "connecting" OR connectionState = "connected" OR connectionState = "polling")
  end if

  if isActive = true
    currentRoomId = m.longPollingTask.roomId
    if currentRoomId = roomId
      if m.longPollingTask.connectionState = "polling"
        processCastingDeeplinkPlayAndReset()
      end if
      ' If not yet polling, leave m.deeplinkContent intact so onCastingConnectionStateChanged can process it when polling is reached.
      return
    end if

    logDebug("CrossDeviceCastingHelpers.startCastingSession: Already in room " + currentRoomId + "; tearing down session before joining new room " + roomId)
    sendCastingSessionMetadata()
    stopCurrentCastingPlayback()
    stopCastingSession()
  else
    destroyLongPollingTask()
    initLongPollingTask()
    logDebug("CrossDeviceCastingHelpers.startCastingSession: Starting session for room: " + roomId)
    m.longPollingTask.roomId = roomId
  end if
End Function


' When the Voyager session is ready (polling), apply optional cast deeplink play and clear deeplink state
Function processCastingDeeplinkPlayAndReset() as Void
  if isNonEmptyString(m.deeplinkContent.id) = true
    playPayload = { contentId: m.deeplinkContent.id }
    if m.deeplinkContent.nowPos >= 0
      playPayload.position = m.deeplinkContent.nowPos
    end if
    handleCastingPlayContentCommand(playPayload)
  end if

  resetDeeplinkValues()
End Function


' Stop the current Voyager session
Function stopCastingSession()
  if m.longPollingTask <> invalid
    m.longPollingTask.stopSession = true
  end if
End Function


' Handler for Voyager connection state changes.
Function onCastingConnectionStateChanged(msg)
  state = msg.getData()
  logDebug("CrossDeviceCastingHelpers.onCastingConnectionStateChanged - state: " + state)

  if state = "polling"
    if isDeeplinkRoomSameAsCurrentSessionRoom() = true
      processCastingDeeplinkPlayAndReset()
    end if
  else if state = "error"
    if isDeeplinkRoomSameAsCurrentSessionRoom() = true
      resetDeeplinkValues()
    end if
  else if state = "disconnected"
    m.castingPlayPosition = invalid
    m.castingAdPlaybackPosition = invalid
  end if
End Function


' Handler for LongPollingTask state changes
' When a pending room switch is queued, waits for disconnection and task reset, then starts the new session.
Function onLongPollingTaskStateChanged(msg)
  state = msg.getData()
  logDebug("CrossDeviceCastingHelpers.onLongPollingTaskStateChanged - state: " + state)

  if state = "stop"
    destroyLongPollingTask()

    if m.deeplinkContent <> invalid AND isNonEmptyString(m.deeplinkContent.roomId) = true
      initLongPollingTask()
      logDebug("CrossDeviceCastingHelpers.onLongPollingTaskStateChanged - Creating new session in room: " + m.deeplinkContent.roomId)
      m.longPollingTask.roomId = m.deeplinkContent.roomId
    end if
  end if
End Function


' Handler for received Voyager message batches
Function onCastingMessagesReceived(msg) as Void
  messages = msg.getData()
  if isNonEmptyArray(messages) = false
    return
  end if

  for each message in messages
    commandPayload = extractCastingCommandPayload(message)
    if commandPayload = invalid
      logWarn("CrossDeviceCastingHelpers.onCastingMessagesReceived - No command in message payload: " + FormatJson(message))
    else
      handleCastingCommand(commandPayload)
    end if
  end for
End Function


' Route a Voyager command to the appropriate handler
' @param payload: assocarray - The command payload from Voyager message
Function handleCastingCommand(payload as Object) as Void
  messageTypes = m.constants.player.casting.messageTypes

  if isCastingCommandType(payload, messageTypes.play)
    handleCastingPlayContentCommand(payload)

  else if isCastingCommandType(payload, messageTypes.pause) OR isCastingCommandType(payload, messageTypes.resume)
    handleCastingVideoPlayerControlCommand(payload)

  else if isCastingCommandType(payload, messageTypes.seek)
    handleCastingSeekCommand(payload)

  else if isCastingCommandType(payload, messageTypes.skipForward) OR isCastingCommandType(payload, messageTypes.skipBackward)
    handleCastingSkipCommand(payload)

  else if isCastingCommandType(payload, messageTypes.toggleMute)
    handleCastingToggleMuteCommand()

  else if isCastingCommandType(payload, messageTypes.setSubtitles)
    handleCastingSetSubtitlesCommand(payload)

  else if isCastingCommandType(payload, messageTypes.getMetadata)
    handleCastingGetMetadataCommand()

  else if isCastingCommandType(payload, messageTypes.stopCasting)
    handleCastingStopCastingCommand()

  else
    logWarn("CrossDeviceCastingHelpers.handleCastingCommand - Unknown command type: " + FormatJson(payload))
  end if
End Function


' Handle play command from Voyager
' Fetches content by ID and starts playback
' @param payload: assocarray - The payload from Voyager message
Function handleCastingPlayContentCommand(payload as Object) as Void
  contentId = payload.contentId
  if isNonEmptyString(contentId) = false
    logError("CrossDeviceCastingHelpers.handleCastingPlayContentCommand: No content ID")
    return
  end if

  position = getNumber(payload.position)
  logDebug("CrossDeviceCastingHelpers.handleCastingPlayContentCommand: contentId: " + contentId + ", position: " + Str(position))

  ' Stop current playback if any
  stopCurrentCastingPlayback()

  ' Create a content node to fetch
  emptyNode = CreateObject("roSGNode", "TubiContentNode")
  emptyNode.id = contentId
  emptyNode.type = m.constants.ui.contentTypes.video

  ' Fetch content from server and play
  getSingleContentFromServer(emptyNode, onCastingContentFetchSuccess, onCastingContentFetchError, { position: position })
End Function


' Callback for successful content fetch from Voyager play command
Function onCastingContentFetchSuccess(content as Object) as Void
  if content = invalid
    logError("CrossDeviceCastingHelpers.onCastingContentFetchSuccess: Fetched content is invalid")
    return
  end if

  ' Set playback source for analytics
  playbackSource = {
    "srcForAnalytic": m.constants.player.playbackSource.unknown
    "srcForAds": m.constants.player.playbackOrigin.deeplink
    "isCastingSession": true
  }

  playbackPosition = 0
  if content.responseContext <> invalid
    playbackPosition = getNumber(content.responseContext.position)
  end if

  logDebug("CrossDeviceCastingHelpers.onCastingContentFetchSuccess: Playing content: " + content.id + " at position: " + Str(playbackPosition))

  ' Player screen is pushed to the screen stack asynchronously (ScreenStack.onPush() callback).
  ' Hence getting it from the screen cache instead of getCurrentVideoPlayerScreen(). Further references to the player
  ' screen will use the screen stack instead.
  if content.type = m.constants.ui.contentTypes.linear
    playLinearVideoContent(content, false, "", false, playbackSource)
    linearVideoPlayerScreen = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
    if linearVideoPlayerScreen <> invalid
      attachCastingVideoPlayerObservers(linearVideoPlayerScreen)
    end if
  else
    playVideoContent(content, playbackSource, playbackPosition)
    videoPlayerScreen = getFromScreenCache(m.constants.ui.screenIds.videoPlayerScreen)
    if videoPlayerScreen <> invalid
      attachCastingVideoPlayerObservers(videoPlayerScreen)
    end if
  end if
End Function


' Callback for content fetch error from Voyager play command
Function onCastingContentFetchError(error as Object)
  logError("CrossDeviceCastingHelpers.onCastingContentFetchError: " + FormatJson(error))
End Function


' Callback for player state changes
Function onCastingPlayerStateChanged(msg as Object) as Void
  if m.castingVideoPlayerObserversActive <> true
    ' Guard against state events arriving after casting observers were released.
    ' Cannot unobserve "state" directly because it would also remove the shared
    ' onVideoPlayerState observer registered by VideoHelpers.
    return
  end if

  state = msg.getData()
  logDebug("CrossDeviceCastingHelpers.onCastingPlayerStateChanged - state: " + state)
  sendCastingSessionMetadata()
End Function


' Callback for player position changes
Function onCastingPlayerPositionChanged(msg as Object)
  position = msg.getData()
  if m.castingPlayPosition = invalid
    m.castingPlayPosition = position
  end if

  if abs(position - m.castingPlayPosition) >= 10
    logDebug("CrossDeviceCastingHelpers.onCastingPlayerPositionChanged - position: " + Str(position))
    m.castingPlayPosition = position
    sendCastingSessionMetadata()
  end if
End Function


' Callback for global caption mode changes
Function onCastingGlobalCaptionModeChanged(msg as Object)
  globalCaptionMode = msg.getData()
  logDebug("CrossDeviceCastingHelpers.onCastingGlobalCaptionModeChanged - globalCaptionMode: " + globalCaptionMode)
  sendCastingSessionMetadata()
End Function


' Callback for per-second ad playback position updates from RAF.
' Throttled to send metadata every 10 seconds, matching content position behavior.
Function onCastingAdPlaybackPositionChanged(msg as Object)
  adPosition = msg.getData()
  if m.castingAdPlaybackPosition = invalid
    m.castingAdPlaybackPosition = adPosition
  end if

  if abs(adPosition - m.castingAdPlaybackPosition) >= 10
    logDebug("CrossDeviceCastingHelpers.onCastingAdPlaybackPositionChanged - adPosition: " + Str(adPosition))
    m.castingAdPlaybackPosition = adPosition
    sendCastingSessionMetadata()
  end if
End Function


' Callback for back button pressed
Function onCastingExitPlayerChanged(msg as Object)
  logDebug("CrossDeviceCastingHelpers.onCastingExitPlayerChanged")
  handleCastingStopCastingCommand()
End Function


' Handle casting command from Voyager
' @param payload: assocarray - The command payload
Function handleCastingVideoPlayerControlCommand(payload as Object)
  videoPlayerScreen = getCurrentVideoPlayerScreen()
  if videoPlayerScreen <> invalid
    logDebug("CrossDeviceCastingHelpers.handleCastingVideoPlayerControlCommand")
    sendVideoPlayerCommand(videoPlayerScreen, payload.type)
  else
    logWarn("CrossDeviceCastingHelpers.handleCastingVideoPlayerControlCommand: No active video player")
  end if
End Function


' Handle seek command from Voyager
' @param payload: assocarray - The command payload
Function handleCastingSeekCommand(payload as Object)
  videoPlayerScreen = getCurrentVideoPlayerScreen()
  if videoPlayerScreen <> invalid AND videoPlayerScreen.id <> m.constants.ui.screenIds.linearVideoPlayerScreen AND isNumber(payload.position) = true
    logDebug("CrossDeviceCastingHelpers.handleCastingSeekCommand: position: " + Str(payload.position))
    videoPlayerScreen.seekTo = payload.position
  else
    logWarn("CrossDeviceCastingHelpers.handleCastingSeekCommand: No active video player or linear video player, or invalid position")
  end if
End Function


' Handle skip forward/backward command from Voyager
' @param payload: assocarray - The command payload
Function handleCastingSkipCommand(payload as Object)
  videoPlayerScreen = getCurrentVideoPlayerScreen()
  if videoPlayerScreen <> invalid AND videoPlayerScreen.id <> m.constants.ui.screenIds.linearVideoPlayerScreen
    ' Get skip amount from payload, default to 10 seconds
    skipSeconds = getNumber(payload.seconds, 10)

    ' Get current position and seek backward
    position = videoPlayerScreen.position
    if payload.type = m.constants.player.casting.messageTypes.skipForward
      position += skipSeconds
    else
      position -= skipSeconds
    end if
    logDebug("CrossDeviceCastingHelpers.handleCastingSkipCommand: Seeking to: " + Str(position))
    videoPlayerScreen.seekTo = position
  else
    logWarn("CrossDeviceCastingHelpers.handleCastingSkipCommand: No active video player or linear video player")
  end if
End Function


' Handle toggle mute command from Voyager
Function handleCastingToggleMuteCommand()
  videoPlayerScreen = getCurrentVideoPlayerScreen()
  if videoPlayerScreen <> invalid
    logDebug("CrossDeviceCastingHelpers.handleCastingToggleMuteCommand")
    videoPlayerScreen.muteAudio = not videoPlayerScreen.muteAudio
    sendCastingSessionMetadata()
  else
    logWarn("CrossDeviceCastingHelpers.handleCastingToggleMuteCommand: No active video player")
  end if
End Function


' Handle set subtitles command from Voyager
' @param payload: assocarray - The command payload
Function handleCastingSetSubtitlesCommand(payload as Object)
  videoPlayerScreen = getCurrentVideoPlayerScreen()
  if videoPlayerScreen <> invalid
    logDebug("CrossDeviceCastingHelpers.handleCastingSetSubtitlesCommand")
    if isNonEmptyString(payload.language) = true
      videoPlayerScreen.globalCaptionMode = "On"
      if videoPlayerScreen.id <> m.constants.ui.screenIds.linearVideoPlayerScreen
        videoPlayerScreen.preferredSubtitleTrack = { language: UCase(payload.language) }
      end if
    else
      videoPlayerScreen.globalCaptionMode = "Off"
    end if
  end if
End Function


' Handle getMetadata command from Voyager
Function handleCastingGetMetadataCommand()
  logDebug("CrossDeviceCastingHelpers.handleCastingGetMetadataCommand")
  sendCastingSessionMetadata()
End Function


' Handle stopCasting command from Voyager
' This signals the end of the cross-device session
Function handleCastingStopCastingCommand()
  logDebug("CrossDeviceCastingHelpers.handleCastingStopCastingCommand")
  sendCastingSessionMetadata()
  stopCurrentCastingPlayback()
  stopCastingSession()
End Function


' Stop current playback for Voyager commands
Function stopCurrentCastingPlayback()
  logDebug("CrossDeviceCastingHelpers.stopCurrentCastingPlayback")

  videoPlayerScreen = getCurrentVideoPlayerScreen()
  if videoPlayerScreen <> invalid
    releaseCastingVideoPlayerObservers(videoPlayerScreen)
    stopVideoContent(videoPlayerScreen)
    popScreen(false, false)
    showHideSpinner(false)
  else
    videoPlayerScreen = getFromScreenCache(m.constants.ui.screenIds.videoPlayerScreen)
    if videoPlayerScreen = invalid
      videoPlayerScreen = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
    end if
    if videoPlayerScreen <> invalid
      releaseCastingVideoPlayerObservers(videoPlayerScreen)
    end if
  end if
End Function


' Triggers a metadata update to Voyager through the LongPollingTask
Function sendCastingSessionMetadata() as Void
  if m.longPollingTask = invalid OR m.longPollingTask.connectionState <> "polling"
    logInfo("CrossDeviceCastingHelpers.sendCastingSessionMetadata - LongPollingTask is not initialized or not polling")
    return
  end if

  videoPlayerScreen = getCurrentVideoPlayerScreen()
  if videoPlayerScreen <> invalid AND videoPlayerScreen.content <> invalid
    metadata = {
      "type": m.constants.player.casting.payloadTypes.metadata
      "contentId": videoPlayerScreen.content.id
      "isLive": false
      "title": videoPlayerScreen.content.title
      "duration": videoPlayerScreen.content.length
      "position": videoPlayerScreen.position
      "rate": 1.0
      "isMuted": videoPlayerScreen.muteAudio
      "volume": 100
      "subtitleLanguage": getCastingSubtitleLanguage(videoPlayerScreen)
      "ad": getCastingAdInfo(videoPlayerScreen)
    }

    if videoPlayerScreen.id = m.constants.ui.screenIds.linearVideoPlayerScreen
      metadata.duration = 0
      metadata.isLive = true
    end if

    if videoPlayerScreen.state <> "playing"
      metadata.rate = 0.0
    end if

    m.longPollingTask.metadata = metadata
    m.castingPlayPosition = videoPlayerScreen.position
  end if
End Function


' Get the current video player screen if active
' @return: roSGNode or invalid - The current video player screen
Function getCurrentVideoPlayerScreen() as Object
  currentScreen = getCurrentScreen()
  if currentScreen <> invalid
    if currentScreen.id = m.constants.ui.screenIds.videoPlayerScreen OR currentScreen.id = m.constants.ui.screenIds.linearVideoPlayerScreen
      return currentScreen
    end if
  end if

  return invalid
End Function


' True when cast deeplink room matches the current session room
' @return: boolean
Function isDeeplinkRoomSameAsCurrentSessionRoom() as Boolean
  if m.deeplinkContent = invalid OR m.longPollingTask = invalid
    return false
  end if

  if isNonEmptyString(m.deeplinkContent.roomId) = false OR isNonEmptyString(m.longPollingTask.roomId) = false
    return false
  end if

  return m.deeplinkContent.roomId = m.longPollingTask.roomId
End Function
