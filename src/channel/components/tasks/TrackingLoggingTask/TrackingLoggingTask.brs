Function init()
  m.top.functionName = "watchLoop"
  ' Observe pattern which ensures that we don't lose events before the thread
  ' is running
  m.port = CreateObject("roMessagePort")
  m.top.observeField("trackEvent", m.port)
  m.top.observeField("trackPlayerEvent", m.port)
  m.top.observeField("logMsg", m.port)
  m.top.observeField("logException", m.port)
  m.top.observeField("analyticsAppMode", m.port)
  m.top.observeField("userConsentsOptOutStatus", m.port)
  m.top.observeField("trackRealtimeEvent", m.port)

  m.constants = getConstantsFromGlobal()
  m.externalConfigInfo = getExternalConfigInfoFromGlobal()

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
  m.request = TubiRequest(m.constants.settings)
  m.auth = TubiAuth(m.constants)
  sentryInfo = Sentry(m.constants, m.auth)
  m.logger = TubiLogger(m.constants, m.request, m.auth, sentryInfo)
  m.tracking = TubiTracking(m.constants, m.auth, m.top.userConsentsOptOutStatus, m.request, m.externalConfigInfo)
  m.analyticsAppMode = "DEFAULT_MODE"

  'when the trackEvent field for the metadata task field is updated, the event is heard in this loop
  'and beginRequest() is called
  while true
    msg = wait(0, m.port)
    if type(msg) = "roSGNodeEvent" then
      field = msg.GetField()
      data = msg.GetData()
      if field = "trackEvent" then
        trackSceneGraphEvent(data, m.analyticsAppMode)
      else if field = "trackPlayerEvent" then
        trackSceneGraphPlayerEvent(data)
      else if field = "trackRealtimeEvent" then
        trackSceneGraphRealtimeEvent(data)
      else if field = "logMsg" then
        sendSceneGraphLog(data)
      else if field = "logException" then
        sendSceneGraphException(data)
      else if field = "analyticsAppMode"
        m.analyticsAppMode = data
      else if field = "userConsentsOptOutStatus"
        m.tracking.userConsentsOptOutStatus = data
      end if
    else if type(msg) = "roUrlEvent" then
      m.queue.handleEvent(msg)
    end if
  end while
End Function


'@evtData: assocArray, has the following fields
'           type: string, corresponds to one of the eventTypes found in m.tracking.getAnalyticsEvent()
'           values: assocArray, fields that correspond to the fields specified for the eventType in m.tracking.getAnalyticsEvent()
'@analyticsAppMode: string: corresponds to one of the App message Mode enum as in found in protos
Function trackSceneGraphEvent(evtData, analyticsAppMode)
  if evtData <> invalid AND type(evtData.type) = "roString"
    tubiLog("TrackingLoggingTask.trackSceneGraphEvent for " + evtData.type)
    evtData.values.appMode = analyticsAppMode
    m.tracking.trackUserEvent(evtData.type, evtData.values, m.queue) 'creates a request and adds it to the requestQueue
  end if
End Function


'@evtData: assocArray, has the following fields
'           type: string, corresponds to one of the eventTypes found in m.tracking.getAnalyticsEvent()
'           values: assocArray, fields that correspond to the fields specified for the eventType in m.tracking.getAnalyticsEvent()
Function trackSceneGraphPlayerEvent(evtData)
  if evtData <> invalid AND isAA(evtData) = true
    m.tracking.trackPlayerEvent(evtData, m.queue) 'creates a request and adds it to the requestQueue
  end if
End Function


'@evtData: assocArray, has the following fields
'           type: string, corresponds to one of the eventTypes found in m.tracking.getAnalyticsEvent()
'           values: assocArray, fields that correspond to the fields specified for the eventType in m.tracking.getAnalyticsEvent()
Function trackSceneGraphRealtimeEvent(evtData)
  if evtData <> invalid AND isAA(evtData) = true
    m.tracking.trackRealtimeEvent(evtData, m.queue) 'creates a request and adds it to the requestQueue
  end if
End Function


Function sendSceneGraphLog(logInfo)
  'runs the appropriate method (debug, error, etc.) from the logger object and add the log request to the tracking/logging queue
  m.logger[logInfo.level](logInfo.message, logInfo.serverTypeName, logInfo.subtype, m.queue, logInfo.samplePercent)
End Function


Function sendSceneGraphException(logInfo)
  'runs the exception method from the logger object and send the log request to the sentry sdk
  m.logger.exception(logInfo.message, logInfo.level, m.queue, logInfo.samplePercent)
End Function
