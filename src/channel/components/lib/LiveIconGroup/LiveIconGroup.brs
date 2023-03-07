Function init()
  m.liveAnimateImage = m.top.findNode("LiveAnimateImage")
  m.liveTitle = m.top.findNode("liveTitle")
  m.top.layoutDirection = "horiz"
  m.top.itemSpacings = [6]
  m.liveTitle.text = getTranslation("screenSearch_liveText")
  m.top.observeField("shouldAnimate", "onAnimate")
  m.posterArray = [
    "pkg:/images/icon_live_1.png",
    "pkg:/images/icon_live_2.png",
    "pkg:/images/icon_live_3.png"
  ]
  m.nonAnimatingUri = "pkg:/images/icon_live_4.png"
  m.liveAnimateImage.uri = m.nonAnimatingUri
  m.animateIndex = 0

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if
  
  if theme <> invalid
    m.liveTitle.color = theme.primaryTextColor
  end if
End Function


Function onAnimate()
  if m.top.shouldAnimate = false
    m.liveAnimateImage.uri = m.nonAnimatingUri
    if m.animateTimer <> invalid then
      m.animateTimer.control = "stop"
    end if
  else
    m.top.enableRenderTracking = true
    m.top.observeFieldScoped("renderTracking", "onRenderTrackingChange")
    if m.animateTimer = invalid then
      timer = m.top.createChild("Timer")
      timer.repeat = true
      timer.duration = 0.6
      timer.observeFieldScoped("fire", "onAnimateTimerFired")
      m.animateTimer = timer
    end if
    m.animateTimer.control = "start"
    onAnimateTimerFired()
  end if
end Function


Function onAnimateTimerFired()
  ' We want to keep the previous image showing until the new image loads to avoid flashing
  m.liveAnimateImage.loadingBitmapUri = m.liveAnimateImage.uri
  m.liveAnimateImage.uri = m.posterArray[m.animateIndex]
  m.animateIndex++
  if m.animateIndex >= m.posterArray.count()
    m.animateIndex = 0
  end if
End Function


Function onRenderTrackingChange(msg)
  if msg.getData() = "none" then
    m.animateTimer.control = "stop"
  else if m.top.shouldAnimate = true then
    m.animateTimer.control = "start"
  end if
End Function
