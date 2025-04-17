Function init()
  m.label = m.top.findNode("Label")
  m.icon = m.top.findNode("Icon")
  m.top.observeFieldScoped("unFocusUri", "unFocusUriUpdated")
  m.top.observeFieldScoped("focusedChild", "onComponentFocus")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.label, typographyConstants.ids.bodyMediumStrong)

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


Function unFocusUriUpdated()
  m.icon.uri = m.top.unFocusUri
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.label.color = theme.unfocusedColor
  end if

End Function


Function onComponentFocus()
  if m.top.hasFocus() = true
    m.icon.uri = m.top.focusUri
    m.label.visible = true
  else
    m.icon.uri = m.top.unFocusUri
    m.label.visible = false
  end if
End Function
