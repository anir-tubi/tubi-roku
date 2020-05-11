Function init()
  m.top.functionName = "sendExposureEvent"
End Function


Function sendExposureEvent()

  m.constants = m.top.constants
  m.experimentTracking = m.top.experimentTracking

  port = CreateObject("roMessagePort")
  
  m.request = TubiRequest(m.constants.settings.mode)
  m.auth = TubiAuth(m.constants, m.request)
  m.tracking = TubiTracking(m.constants, m.request, m.auth)
  
  eventType = m.experimentTracking.type
  eventValues = m.experimentTracking.values
  eventValues.appMode = "DEFAULT_MODE"
  
  tubiLog("AnalyticsTask.sendExposureEvent for " + eventType)
  
  trackData = m.tracking.getClientEvent(eventType, eventValues)
  userRequest = m.tracking.getUserTrackingRequest(eventType, trackData)
  
  if userRequest <> invalid
    userRequest.start(port)
  end if
  
End Function
