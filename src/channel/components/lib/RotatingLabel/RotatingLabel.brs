Function init()
  tubiLog("RotatingLabel.init")
  m.top.observeField("texts", "onTextsChange")
  m.LabelGroup = m.top.findNode("RotatingLabelGroup")
  m.CrossfadeAnimation = m.top.findNode("RotatingLabelCrossfade")
  m.DisplayTimer = m.top.findNode("DisplayTimer")
  m.textsIndex = -1
End Function

Function onTextsChange()
  tubiLog("RotatingLabel.onTextsChange")
  if m.top.texts <> invalid and m.top.texts.count() > 0 then
    m.textsIndex = 0
    startCrossfade()
  else
    m.textsIndex = -1
  end if
End Function

Function startCrossfade()
  tubiLog("RotatingLabel.startCrossfade")
  oldLabel = m.top.findNode("OldLabel")
  newLabel = m.top.findNode("NewLabel")
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
    oldLabel[attribute] = m.top[attribute]
    newLabel[attribute] = m.top[attribute]
  end for

  oldLabel.text = newLabel.text
  newLabel.text = m.top.texts[m.textsIndex]
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
  if m.top.texts <> invalid and m.top.texts.count() > 0 then
    m.textsIndex = m.textsIndex + 1
    if m.top.texts <> invalid and m.textsIndex >= m.top.texts.count() then
      m.textsIndex = 0
    end if
    startCrossfade()
  end if
End Function