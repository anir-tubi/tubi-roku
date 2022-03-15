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
  m.animateIndex = 0
End Function


Function onAnimate()
  if m.top.shouldAnimate = false
    m.liveAnimateImage.uri = "pkg:/images/icon_live_4.png"
  else
    animateTimer = m.top.createChild("Timer")
    animateTimer.repeat = true
    animateTimer.duration = 0.6
    animateTimer.observeField("fire", "onAnimateTimerFired")
    animateTimer.control = "start"
  end if
end Function


Function onAnimateTimerFired()
  if m.animateIndex >= m.posterArray.count() 
    m.animateIndex = 0
  end if
  m.liveAnimateImage.uri = m.posterArray[m.animateIndex]
  m.animateIndex++
End Function