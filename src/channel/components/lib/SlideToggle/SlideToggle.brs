Function init()
  topRef = m.top
  m.toggleRail = topRef.findNode("toggleRail")
  m.selector = topRef.findNode("selector")

  m.selectorOnTranslation = [89,0]
  m.selectorOffTranslation = [57,0]
  m.top.observeFieldScoped("isToggleOn", "onToggleUpdated")

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    m.theme = msg.getData()
  else
    m.theme = getThemeFromGlobal()
  end if
End Function


Function onToggleUpdated(msg)
  isToggleOn = msg.getData()

  if isToggleOn = true
    slideTo(m.selector, m.selectorOnTranslation, 0.2)
    m.toggleRail.uri = "pkg:/images/toggle-rail-on.png"
    m.toggleRail.blendColor = m.theme.successColor
  else
    slideTo(m.selector, m.selectorOffTranslation, 0.2)
    m.toggleRail.uri = "pkg:/images/toggle-rail-off.png"
    m.toggleRail.blendColor = m.theme.backgroundColorLight
  end if
End Function
