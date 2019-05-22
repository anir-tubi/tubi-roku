Function init()
  m.top.functionName = "watchLoop"
  ' Observe pattern which ensures that we don't lose events before the thread
  ' is running
  m.port = CreateObject("roMessagePort")
  m.top.observeField("trackEvent", m.port)
  m.top.observeField("logMsg", m.port)
  m.top.observeField("logException", m.port)
  m.top.control = "RUN"
End Function


'''''''''''''''''''''''''
' watchLoop
'
' "main" loop of the task thread, watches for requests on
' the "trackEvent" field
'
Function watchLoop()
  tubiLog("TrackingLoggingTask.watchLoop started")
  m.queue = TubiRequestQueue().create(m.port)
  m.constants = m.global.constants   ' this should grab a thread-local copy
  m.request = TubiRequest()
  m.auth = TubiAuth(m.constants, m.request)
  m.logger = TubiLogger(m.constants, m.request, m.auth)
  m.tracking = TubiTracking(m.constants, m.request, m.auth)

  'when the trackEvent field for the metadata task field is updated, the event is heard in this loop
  'and beginRequest() is called
  while true
    msg = wait(0, m.port)
    if type(msg) = "roSGNodeEvent" then
      if msg.GetField() = "trackEvent" then
        trackSceneGraphEvent(msg.GetData())

      else if msg.GetField() = "logMsg" then
        sendSceneGraphLog(msg.GetData())

      else if msg.GetField() = "logException" then
        sendSceneGraphException(msg.GetData())

      end if
    else if type(msg) = "roUrlEvent" then
      handledRequest = m.queue.handleEvent(msg)
    end if
  end while
End Function


'@evtData: assocArray, has the following fields
'           type: string, corresponds to one of the eventTypes found in m.tracking.getAnalyticsEvent()
'           values: assocArray, fields that correspond to the fields specified for the eventType in m.tracking.getAnalyticsEvent()
Function trackSceneGraphEvent(evtData)
  if evtData <> invalid and type(evtData.type) = "roString"
    tubiLog("TrackingLoggingTask.trackSceneGraphEvent for " + evtData.type)
    m.tracking.trackUserEvent(evtData.type, evtData.values, m.queue)  'creates a request and adds it to the requestQueue
  end if
End Function


Function sendSceneGraphLog(logInfo)
  'runs the appropriate method (debug, error, etc.) from the logger object and add the log request to the tracking/logging queue
  m.logger[logInfo.level](logInfo.message, logInfo.serverTypeName, logInfo.subtype, m.queue)
End Function


Function sendSceneGraphException(logInfo)
  'runs the appropriate method (debug, error, etc.) from the logger object and add the log request to the tracking/logging queue
  m.logger.exception(logInfo.level, logInfo.message)
End Function

