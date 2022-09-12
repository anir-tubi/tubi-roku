Function init()
  tubiLog("RotatingLabel.init")
  m.top.observeField("texts", "onTextsChange")
  m.top.observeField("runCrossfade", "onRunCrossfade")
  m.LabelGroup = m.top.findNode("RotatingLabelGroup")
  m.CrossfadeAnimation = m.top.findNode("RotatingLabelCrossfade")
  m.DisplayTimer = m.top.findNode("DisplayTimer")
  m.textsIndex = -1
  m.oldLabel = m.top.findNode("OldLabel")
  m.newLabel = m.top.findNode("NewLabel")
End Function

Function onTextsChange()
  tubiLog("RotatingLabel.onTextsChange")
  if m.top.texts <> invalid AND m.top.texts.count() > 0 then
    m.textsIndex = 0
  else
    m.textsIndex = -1
  end if
End Function

Function onRunCrossfade()
  if m.top.runCrossfade = true
    startCrossfade()
  else if m.top.runCrossfade = false
    m.DisplayTimer.control = "stop"
    m.oldLabel.text = ""
    m.newLabel.text = ""
  end if
End Function

Function startCrossfade()
  tubiLog("RotatingLabel.startCrossfade")
  ' attributes to set on the oldLabel as it fades out

  whitelist = [
    "color"
    "width"
    "font"
    "horizAlign"
    "vertAlign"
    "numLines"
    "maxLines"
    "wrap"
    "lineSpacing"
    "displayPartialLines"
    "ellipsizeOnBoundary"
    "truncateOnDelimiter"
    "wordBreakChars"
    "ellipsisText"
  ]
  for each attribute in whitelist
    m.oldLabel[attribute] = m.newLabel[attribute]
  end for
  m.oldLabel.opacity = 1.0
  m.oldLabel.text = m.newLabel.text
  m.newLabel.opacity = 0.0
  m.newLabel.text = m.top.texts[m.textsIndex]
  m.CrossfadeAnimation.observeField("state", "onCrossfadeStateChange")
  m.CrossfadeAnimation.control = "start"
End Function

Function onCrossfadeStateChange()
  tubiLog("RotatingLabel.onCrossfadeStateChange: state = " + m.CrossfadeAnimation.state)
  if m.CrossfadeAnimation.state = "stopped"
    m.CrossfadeAnimation.unobserveField("state")
    m.DisplayTimer.observeField("fire", "onDisplayTimerFire")
    m.DisplayTimer.control = "start"        
  end if
End Function

Function onDisplayTimerFire()
  tubiLog("RotatingLabel.onDisplayTimerFire")
  m.DisplayTimer.unobserveField("fire")
  if m.top.texts <> invalid AND m.top.texts.count() > 0 then
    m.textsIndex = m.textsIndex + 1
    if m.top.texts <> invalid AND m.textsIndex >= m.top.texts.count() then
      m.textsIndex = 0
    end if
    startCrossfade()
  end if
End Function