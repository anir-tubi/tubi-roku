Function init()
  m.time = m.top.findNode("time")
  m.clockTimer = m.top.findNode("clockTimer")

  m.top.enableRenderTracking = true
  m.top.observeFieldScoped("renderTracking", "onRenderTrackingChange")
  m.top.observeFieldScoped("control", "onControlChange")
  m.clockTimer.observeFieldScoped("fire", "onTimerFire")
End Function


' When the clock is not visible then stop the timer and vice versa
Function onRenderTrackingChange(msg)
  if msg.getData() = "none" then
    m.clockTimer.control = "stop"
  else
    onTimerFire()
  end if
End Function


'//If the control is changed, then update the timer accordingly
Function onControlChange(msg)
  if msg.getData() = "start" then
    setCurrentTime()
  end if
End Function


Function onTimerFire()
  ' We want the clock to fire at the start of each minute so we see how many seconds until the next minute and set the timer to that amount
  date = CreateObject("roDateTime")
  m.clockTimer.duration = 60 - date.getSeconds()
  m.clockTimer.control = "start"

  setCurrentTime()
End Function


Function setCurrentTime()
  date = CreateObject("roDateTime")
  date.ToLocalTime()

  '//Set the clock's time
  m.time.text = GetAMPMTimeString(date)
End Function
