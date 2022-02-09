Function init()
  m.constants = getConstantsFromGlobal()

  m.background = m.top.findNode("clockBground")
  m.time = m.top.findNode("time")
  m.clockTimer = m.top.findNode("clockTimer")

  if m.constants.deviceInfo.scaledUi = true then
    m.background.uri = "pkg:/images/tab_short_component_alt_hd.9.png"
  else
    m.background.uri = "pkg:/images/tab_short_component_alt_fhd.9.png"
  end if
  m.top.observeField("width", "onWidthChange")
  m.top.observeField("height", "onHeightChange")
  m.top.observeField("visible", "onVisibleChange")
  m.top.observeField("control", "onControlChange")
  m.clockTimer.observeField("fire", "onTimerFire")

  if m.top.visible = true
    turnOn()
  end if
  
End Function


' When the visibility of this compomnent is changed, start or stop the clock timer
Function onVisibleChange()
  if m.top.visible = false
    m.clockTimer.control = "stop"
  else
    turnOn()
  end if
End Function


'//If the control is changed, then update the timer accordingly 
Function onControlChange()
  m.clockTimer.control = m.top.control
  if m.top.control = "start"
    setCurrentTime()
  end if
End Function


Function turnOn()
  m.clockTimer.control = "start"
  setCurrentTime()
End Function



Function onWidthChange()
  m.background.width = m.top.width
  m.time.width = m.top.width
End Function


Function onHeightChange()
m.background.height = m.top.height
m.time.height = m.top.height
End Function


Function onTimerFire()
  setCurrentTime()
End Function 


Function setCurrentTime()
  date = CreateObject("roDateTime")
  date.ToLocalTime()

  '//Set the clock's time
  m.time.text = GetAMPMTimeString(date)
End Function
