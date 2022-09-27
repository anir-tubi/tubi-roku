Function init()
  m.port = createObject("roMessagePort")

  m.hdmiStatus = createObject("roHdmiStatus")
  m.hdmiStatus.setMessagePort(m.port)

  ' Go ahead and set our starting isHdmiStatusOk state
  m.top.isHdmiStatusOk = (m.hdmiStatus.isConnected() = true)

  m.cecStatus = createObject("roCECStatus")
  m.cecStatus.setMessagePort(m.port)

  m.top.functionName = "taskThread"
  m.top.control = "run"
End Function

' All code run here is run on task thread
Function taskThread()
  while true
    msg = wait(0, m.port)
    messageType = type(msg)

    if messageType = "roHdmiStatusEvent" OR messageType = "roHdmiHotPlugEvent" then
      ' We can't check cecStatus.isActiveSource() here because there are cases where it will have the wrong value until it receives another roCECStatusEvent
      m.top.isHdmiStatusOk = (m.hdmiStatus.isConnected() = true)
    else if messageType = "roCECStatusEvent" then
      m.top.isHdmiStatusOk = (m.hdmiStatus.isConnected() = true AND m.cecStatus.isActiveSource() = true)
    end if

    tubiLog("MainTask received " + messageType + " hdmiStatus.isConnected(): " + m.hdmiStatus.isConnected().toStr() + " cecStatus.isActiveSource(): " + m.cecStatus.isActiveSource().toStr())

  end while
End Function
