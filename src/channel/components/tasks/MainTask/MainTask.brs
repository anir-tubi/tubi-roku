Function init()
  m.port = createObject("roMessagePort")

  m.top.observeFieldScoped("request", m.port)

  ' Enabling low memory event. Adding it to m scope since roku does not fire the event if it is not in m scope.
  m.deviceInfo = CreateObject("roAppMemoryMonitor")
  m.deviceInfo.setMessagePort(m.port)
  m.deviceInfo.EnableMemoryWarningEvent(true)
  ' Since we only want to fire once for the user session to not have too many calls.
  m.wasLowMemoryEventFired = false

  constants = getConstantsFromGlobal()
  disableHdmiStatusChecks = false
  if constants.settings.mode = "qa" AND constants.settings.disableHdmiStatusChecks = true then
    disableHdmiStatusChecks = true
  end if

  settings = constants.settings
  if settings.mode <> "production" then
    m.overrideScreensaverTimeout = settings.overrideScreensaverTimeout
  end if

  if disableHdmiStatusChecks <> true then
    m.cecStatus = createObject("roCECStatus")
    m.cecStatus.setMessagePort(m.port)
    m.lastCecStatusIsActiveSource = true

    m.hdmiStatus = createObject("roHdmiStatus")
    m.hdmiStatus.setMessagePort(m.port)
  end if

  ' Go ahead and set our starting isHdmiStatusOk state
  isHdmiStatusOk = (disableHdmiStatusChecks = true) OR (m.hdmiStatus.isConnected() = true)
  modelType = createObject("roDeviceInfo").getModelType()
  if modelType <> "STB" OR constants.deviceInfo.isAnalogOutputDevice = true then
    isHdmiStatusOk = true
  end if

  m.top.isHdmiStatusOk = isHdmiStatusOk

  m.top.functionName = "taskThread"
  m.top.control = "run"
End Function

' All code run here is run on task thread
Function taskThread()
  ' We can not use roAppManager in the render thread so have to do it here
  m.top.screensaverTimeout = getScreensaverTimeout()

  while true
    msg = wait(0, m.port)
    messageType = type(msg)
    if messageType = "roHdmiStatusEvent" OR messageType = "roHdmiHotPlugEvent" then
      ' We can't check cecStatus.isActiveSource() here because there are cases where it will have the wrong value until it receives another roCECStatusEvent
      m.top.isHdmiStatusOk = (m.hdmiStatus.isConnected() = true AND m.lastCecStatusIsActiveSource = true)
      tubiLog("MainTask received " + messageType + " hdmiStatus.isConnected(): " + m.hdmiStatus.isConnected().toStr() + " lastCecStatusIsActiveSource: " + m.lastCecStatusIsActiveSource.toStr())
    else if messageType = "roCECStatusEvent" then
      ' Only update lastCecStatusIsActiveSource if m.hdmiStatus.isConnected is true since theoretically the only time we should get a roCECStatusEvent where it is false is when the HDMI cable was unplugged and we won't receive a CEC isActiveSource when the cable is plugged back in.
      if m.hdmiStatus.isConnected() = true then
        m.lastCecStatusIsActiveSource = msg.getInfo().active
      end if
      m.top.isHdmiStatusOk = (m.hdmiStatus.isConnected() = true AND m.lastCecStatusIsActiveSource = true)
      tubiLog("MainTask received " + messageType + " hdmiStatus.isConnected(): " + m.hdmiStatus.isConnected().toStr() + " lastCecStatusIsActiveSource: " + m.lastCecStatusIsActiveSource.toStr())
    else if messageType = "roSGNodeEvent" then
        if msg.getField() = "request" then
          handleRequest(msg.getData())
        end if
    else if messageType = "roAppMemoryNotificationEvent" AND m.wasLowMemoryEventFired = false
      m.wasLowMemoryEventFired = true
      m.top.lowMemoryEventInfo = getLowMemoryEventInfo()
    end if
  end while
End Function


Function handleRequest(request)
  requestType = request.type
  if requestType = "updateScreensaverTimeout" then
    m.top.screensaverTimeout = getScreensaverTimeout()
  end if
End Function


Function getScreensaverTimeout()
  if m.overrideScreensaverTimeout <> invalid then
    return  m.overrideScreensaverTimeout
  end if

  return createObject("roAppManager").getScreensaverTimeout() * 60
End Function


Function getLowMemoryEventInfo()
  return {
    ' Gets the total amount of time the user was using our application.
    "upTime": createObject("roAppManager").getUptime().totalMilliseconds()
    ' Total number of nodes present at the scene level. Doing it in task since it is better performant when done inside task.
    "totalNodes": m.top.getAll().count()
  }
End Function
