Function init()
  m.top.functionName = "watchLoop"
End Function


'''''''''''''''''''''''''
' watchLoop
'
' "main" loop of the task thread, watches for requests on
' the "trackEvent" field
'
Function watchLoop()
  tubiLog("TrackingLoggingTask.watchLoop started")
  m.port = CreateObject("roMessagePort")
  m.queue = TubiRequestQueue().create(m.port)
  m.top.observeField("trackEvent", m.port)
  m.top.observeField("logMsg", m.port)
  m.constants = m.global.constants   ' this should grab a thread-local copy

  ' Signal that we're ready for requests
  m.top.ready = true

  'when the trackEvent field for the metadata task field is updated, the event is heard in this loop
  'and beginRequest() is called
  while true
    msg = wait(0, m.port)
    if type(msg) = "roSGNodeEvent" then
      if msg.GetField() = "trackEvent" then
        tubiLog("Received roSGNodeEvent for field " + msg.GetField())
        trackSceneGraphEvent(msg.GetData())

      else if msg.GetField() = "logMsg" then
        sendSceneGraphLog(msg.GetData())

      end if
    else if type(msg) = "roUrlEvent" then
      handledRequest = m.queue.handleEvent(msg)
    end if
  end while
End Function


'@evt: assocArray: has the following fields
'           trackType: string, corresponds to one of the eventTypes found in getTrackingTags
'           value: dynamic, depends on the eventType
'           ctx: dynamic, depends on the eventType
'           extraCtx: dynamic, depends on the eventType
Function trackSceneGraphEvent(evt)
  constants = m.constants
  Request = TubiRequest()
  Auth = TubiAuth(constants, Request)
  Tracking = TubiTracking(constants, Request, Auth)

  evt.requestQ = m.queue
  Tracking.trackUserEvent(evt)  'creates a request and adds it to the requestQueue

End Function


Function sendSceneGraphLog(logInfo)
  constants = m.global.constants
  request = TubiRequest()
  auth = TubiAuth(constants, request)
  logger = TubiLogger(constants, request, auth)

  'runs the appropriate method (debug, error, etc.) from the logger object and add the log request to the tracking/logging queue
  logger[logInfo.level](logInfo.message, logInfo.serverTypeName, logInfo.subtype, m.queue)
End Function