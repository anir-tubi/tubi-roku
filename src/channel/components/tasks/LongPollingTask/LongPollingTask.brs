' LongPollingTask.brs
' Background task for Voyager long-polling cross-device communication.
' Handles establishing session, joining/leaving rooms, and polling for messages.


Function init()
  tubiLog("LongPollingTask.init")
  m.port = CreateObject("roMessagePort")
  m.constants = getConstantsFromGlobal()
  m.auth = TubiAuth(m.constants)
  m.request = Request(m.constants.settings)
  m.requestCallbacks = {}
  m.connectionState = "disconnected"
  m.sessionToken = invalid
  m.roomId = ""
  m.joinRef = ""
  m.messageRef = 1
  m.isPolling = false
  m.shouldStop = false

  ' Observe input fields
  m.top.observeField("roomId", m.port)
  m.top.observeField("stopSession", m.port)
  m.top.observeField("metadata", m.port)
  m.top.functionName = "runTaskLoop"
End Function


Function runTaskLoop()
  logDebug("LongPollingTask.runTaskLoop")

  while m.shouldStop = false
    msg = wait(0, m.port)
    if msg <> invalid then
      if type(msg) = "roSGNodeEvent"
        messageField = msg.getField()

        if messageField = "roomId"
          startSession(msg.getData())
        else if messageField = "stopSession"
          stopSession()
        else if messageField = "metadata"
          sendMetadata(msg.getData())
        end if
      else if type(msg) = "roUrlEvent"
        processVoyagerResponse(msg)
      end if
    end if
  end while

  logDebug("LongPollingTask.runTaskLoop - Stopping task")
  m.top.control = "stop"
End Function


' ************************************************************************
' Step 1: Establish session with Voyager using JWT token
' ************************************************************************

Function startSession(roomId = m.roomId as String) as Void
  if isNonEmptyString(roomId) = false
    logWarn("LongPollingTask.startSession - No room ID provided")
    return
  else
    m.roomId = roomId
  end if

  logDebug("LongPollingTask.startSession")
  setConnectionState("connecting")

  authInfo = m.auth.getAuthInfo()
  if authInfo = invalid OR authInfo.accessToken = invalid
    logError("LongPollingTask.startSession - Authentication token not available")
    setConnectionState("error")
    m.shouldStop = true
    return
  end if

  url = m.constants.urls.voyager.longpoll + "?token=" + authInfo.accessToken
  options = {
    method: "GET"
    headers: {
      "Accept": "application/json"
    }
  }
  makeVoyagerRequest(url, m.constants.reqNames.voyagerEstablishSession, options, onEstablishSessionSuccess, onEstablishSessionError)
End Function


' Callback for successful session establishment
Function onEstablishSessionSuccess(response, m) as Void
  data = parseJson(response.data)

  if data = invalid
    onEstablishSessionError(response, m)
  else if data.status = 410 AND isNonEmptyString(data.token) = true
    logDebug("LongPollingTask.onEstablishSessionSuccess - Session established successfully")
    m.sessionToken = data.token
    joinRoom()
  else if data.status = 403 OR (data.status = 410 AND data.token = invalid)
    logError("LongPollingTask.onEstablishSessionSuccess - Authentication failed; response: " + response.data)
    setConnectionState("error")
    m.shouldStop = true
  else
    onEstablishSessionError(response, m)
  end if
End Function


' Callback for session establishment error
Function onEstablishSessionError(error, m) as Void
  logError("LongPollingTask.onEstablishSessionError - Failed to establish session; unexpected response: " + FormatJson(error))
  setConnectionState("error")
  m.shouldStop = true
End Function


' ************************************************************************
' Step 2: Join room received via Casting deeplink
' ************************************************************************

Function joinRoom() as Void
  if m.sessionToken = invalid
    logError("LongPollingTask.joinRoom - No session token available; cannot join room")
    setConnectionState("error")
    m.shouldStop = true
    return
  end if

  logDebug("LongPollingTask.joinRoom; roomId: " + m.roomId)

  url = m.constants.urls.voyager.longpoll + "?token=" + m.sessionToken
  body = {
    topic: "room:" + m.roomId
    event: m.constants.player.casting.requestTypes.joinRoom
    payload: {}
    ref: getMessageRef()
  }
  options = {
    method: "POST"
    headers: {
      "Content-Type": "application/json"
    }
    body: FormatJson(body)
  }
  makeVoyagerRequest(url, m.constants.reqNames.voyagerJoinRoom, options, onJoinRoomSuccess, onJoinRoomError)

  m.joinRef = body.ref
End Function


' Callback for successful room join
Function onJoinRoomSuccess(response, m) as Void
  data = parseJson(response.data)
  if data = invalid
    onJoinRoomError(response, m)
    return
  end if

  ' Update session token if provided
  if isNonEmptyString(data.token) = true
    m.sessionToken = data.token
  end if

  ' Process messages in the response
  if data.status = 200
    setConnectionState("connected")
    startPolling()
  else
    onJoinRoomError(response, m)
  end if
End Function


' Callback for room join error
Function onJoinRoomError(error, m) as Void
  logError("LongPollingTask.onJoinRoomError - Failed to join Voyager room: " + FormatJson(error))
  setConnectionState("error")
  m.shouldStop = true
End Function


' ************************************************************************
' Step 3: Poll for messages from casting device
' ************************************************************************

Function startPolling()
  logDebug("LongPollingTask.startPolling")
  m.isPolling = true
  pollForMessages()
End Function


Function pollForMessages() as Void
  if m.isPolling = false
    return
  else if m.connectionState = "connected"
    setConnectionState("polling")
  end if

  logDebug("LongPollingTask.pollForMessages")

  url = m.constants.urls.voyager.longpoll + "?token=" + m.sessionToken
  options = {
    method: "GET"
    headers: {
      "Accept": "application/json"
    }
  }
  makeVoyagerRequest(url, m.constants.reqNames.voyagerPoll, options, onPollSuccess, onPollError)
End Function


' Callback for successful poll
Function onPollSuccess(response, m) as Void
  if m.isPolling = false
    return
  end if

  data = parseJson(response.data)
  if data = invalid
    onPollError(response, m)
    return
  end if

  ' Update session token if provided. If a token is not provided AND the status is 410,
  ' we need to reestablish the session as the current token has expired.
  if isNonEmptyString(data.token) = true
    m.sessionToken = data.token
  else if data.status = 410
    logError("LongPollingTask.onPollSuccess - Session expired; need to reconnect")
    setConnectionState("error")
    startSession()
    return
  end if

  ' Status 200 means we may have messages
  if data.status = 200 AND isNonEmptyArray(data.messages) = true
    commandMessages = []
    for each message in data.messages
      logDebug("LongPollingTask.onPollSuccess - Received message: " + message)
      parsedMessage = parseJson(message)
      if isNonEmptyAA(parsedMessage) = true
        if parsedMessage.event = "message"
          commandMessages.push(parsedMessage)
        end if
      end if
    end for
    if commandMessages.count() > 0
      m.top.receivedMessages = commandMessages
    end if
  end if

  ' Continue polling, for example, when status code is 204 (normal timeout)
  pollForMessages()
End Function


' Callback for poll error
Function onPollError(error, m)
  logError("LongPollingTask.onPollError - Error polling for new messages: " + FormatJson(error))
  setConnectionState("error")
  stopSession()
End Function


' ************************************************************************
' Step 4: Stop session and leave room
' ************************************************************************

Function stopSession()
  logDebug("LongPollingTask.stopSession")
  m.isPolling = false

  if m.sessionToken <> invalid AND isNonEmptyString(m.roomId) = true
    leaveRoom()
  else
    m.shouldStop = true
  end if
End Function


Function leaveRoom()
  logDebug("LongPollingTask.leaveRoom")
  cancelRequestsInFlight()

  url = m.constants.urls.voyager.longpoll + "?token=" + m.sessionToken
  body = {
    topic: "room:" + m.roomId
    event: m.constants.player.casting.requestTypes.leaveRoom
    payload: {}
    ref: getMessageRef()
    join_ref: m.joinRef
  }
  options = {
    method: "POST"
    headers: {
      "Content-Type": "application/json"
    }
    body: FormatJson(body)
  }
  makeVoyagerRequest(url, m.constants.reqNames.voyagerLeaveRoom, options, onLeaveRoom, onLeaveRoom)
End Function


' Callback for successful room leave
Function onLeaveRoom(response, m)
  logDebug("LongPollingTask.onLeaveRoom")
  m.shouldStop = true
End Function


' ************************************************************************
' Step 5: Send metadata to Voyager
' ************************************************************************

Function sendMetadata(metadata as Object) as Void
  if m.sessionToken = invalid
    logError("LongPollingTask.sendMetadata - No session token available; cannot send metadata")
    return
  end if

  logDebug("LongPollingTask.sendMetadata")
  url = m.constants.urls.voyager.longpoll + "?token=" + m.sessionToken
  body = {
    topic: "room:" + m.roomId
    event: m.constants.player.casting.requestTypes.message
    payload: metadata
    ref: getMessageRef()
    join_ref: m.joinRef
  }
  options = {
    method: "POST"
    headers: {
      "Content-Type": "application/json"
    }
    body: FormatJson(body)
  }
  makeVoyagerRequest(url, m.constants.reqNames.voyagerSendMessage, options, onMetadataSent, onMetadataSent)
End Function


' Callback for successful metadata send
Function onMetadataSent(response, m)
  logDebug("LongPollingTask.onMetadataSent")
End Function


' ************************************************************************
' Helper functions
' ************************************************************************

' Make a Voyager HTTP request
Function makeVoyagerRequest(url, name, options, successCallback, errorCallback)
  requestInstance = m.request.createAsync(url, name, options)
  urlTransfer = createUrlTransfer()
  requestId = urlTransfer.getIdentity().toStr()
  logDebug("LongPollingTask.makeVoyagerRequest - Making " + name + " request with ID: " + requestId)

  if requestInstance.start(urlTransfer) = true
    m.requestCallbacks[requestId] = {
      requestInstance: requestInstance
      name: name
      success: successCallback
      error: errorCallback
    }
  else if errorCallback <> invalid
    errorCallback({ failReason: "Failed to send request" }, m)
  end if
End Function


' Process a Voyager HTTP response
Function processVoyagerResponse(msg) as Void
  requestId = msg.GetSourceIdentity().toStr()
  job = m.requestCallbacks[requestId]
  if job = invalid
    logError("LongPollingTask.processVoyagerResponse - No job found for request ID: " + requestId)
    return
  else
    m.requestCallbacks.Delete(requestId)
  end if

  requestInstance = job.requestInstance
  result = requestInstance.handleEvent(msg)
  if result <> invalid AND result.response <> invalid AND result.response.code <> invalid
    logDebug("LongPollingTask.processVoyagerResponse - Result: " + FormatJson(result.response))
    if result.response.code >= 200 AND result.response.code < 400
      job.success(result.response, m)
    else if job.requestInstance.retries > 0 AND (result.response.code < 0 OR result.response.code >= 500)
      handleRetry(job, result)
    else
      job.error(result.response, m)
    end if
  else
    job.error(result, m)
  end if
End Function


' Handle a retry of a Voyager HTTP request
Function handleRetry(job as Object, result as Object)
  urlTransfer = createUrlTransfer()
  requestId = urlTransfer.getIdentity().toStr()
  job.requestInstance.retries -= 1
  logDebug("LongPollingTask.handleRetry - Retrying previous request; new ID: " + requestId + "; retries left: " + job.requestInstance.retries.toStr())
  sleep(300) ' Delaying to allow the backend systems to sync before retrying
  if job.requestInstance.start(urlTransfer) = true
    m.requestCallbacks[requestId] = job
  else if job.error <> invalid
    job.error(result.response, m)
  end if
End Function


Function createUrlTransfer() as Object
  urlTransfer = CreateObject("roUrlTransfer")
  urlTransfer.SetPort(m.port)
  return urlTransfer
End Function


Function cancelRequestsInFlight()
  if m.requestCallbacks = invalid
    m.requestCallbacks = {}
  else
    requestIds = m.requestCallbacks.keys()
    for each requestId in requestIds
      job = m.requestCallbacks[requestId]
      if job.name = m.constants.reqNames.voyagerSendMessage
        ' Do not cancel any in-flight metadata POST requests as this helps terminate the session cleanly,
        ' and we don't care about the response.
        continue for
      end if
      job.requestInstance.cancel()
      m.requestCallbacks.Delete(requestId)
    end for
  end if
End Function


Function getMessageRef() as String
  messageRef = m.messageRef
  m.messageRef += 1
  return messageRef.toStr()
End Function


Function setConnectionState(state as String)
  if state <> m.connectionState
    m.connectionState = state
    m.top.connectionState = state
  end if
End Function
