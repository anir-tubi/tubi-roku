Function init()
  m.port = createObject("roMessagePort")

  m.top.observeFieldScoped("request", m.port)

  ' Enabling low memory event. Adding it to m scope since roku does not fire the event if it is not in m scope.
  m.deviceInfo = CreateObject("roAppMemoryMonitor")
  m.deviceInfo.setMessagePort(m.port)

  constants = getConstantsFromGlobal()
  disableHdmiStatusChecks = false
  if constants.settings.mode = "qa" AND constants.settings.disableHdmiStatusChecks = true then
    disableHdmiStatusChecks = true
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
  handleLastExitInfo()

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
    end if
  end while
End Function


Function handleLastExitInfo()
  ' We can't call getLastExitInfo() on the render thread so have to get the info here and pass back to the render thread. To avoid extra rendezvouses we only send back if we have an exit code we want to send to the server

  appManager = createObject("roAppManager")
  if findMemberFunction(appManager, "getLastExitInfo") <> invalid then
    lastExitInfo = appManager.getLastExitInfo()
    if lastExitInfo <> invalid AND lastExitInfo.exit_code <> invalid then
      whitelist = {
        "EXIT_OUT_OF_MEMORY": true
        "EXIT_IDLE_AUTO_EXIT": false ' may eventually be interested in sending
        "EXIT_BRIGHTSCRIPT_CRASH": true
        "EXIT_BRIGHTSCRIPT_STOP": true
        "EXIT_BRIGHTSCRIPT_UNK_FUNC": true
        "EXIT_BRIGHTSCRIPT_TIMEOUT": true
        "EXIT_USER_KILL": true
        "EXIT_SYSTEM_KILL": true
        "EXIT_GRAPHICS_NOT_RELEASED": true
        "EXIT_DECODER_NOT_RELEASED": true
        "EXIT_RUNNING_AFTER_SUSPEND": true
        "EXIT_NOT_RESUMED": true
        "EXIT_SIGNAL_TIMEOUT": true
        "EXIT_APP_ERROR": true
        "EXIT_UNLOADED": true
        "EXIT_OS_UPDATE": true
        "EXIT_CHANNEL_UPDATE": true
        "EXIT_CHANNEL_RESTART": true
        "EXIT_CHANNEL_MEM_LIMIT_FG": true
        "EXIT_CHANNEL_MEM_LIMIT_BG": true
        "EXIT_SOFTFAIL": true
      }

      if whitelist[lastExitInfo.exit_code] = true then
        m.top.lastExitInfo = lastExitInfo
      end if
    end if
  end if
End Function


Function handleRequest(request)
  ' Not using for now
  ' requestType = request.type
End Function
