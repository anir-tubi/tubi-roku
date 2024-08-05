Function init()
  m.Menu = m.top.findNode("Menu")

  '//m.top.list is needed to defined for the panelList
  m.top.list = m.Menu

  m.Menu.focusBitmapUri = "pkg:/images/menu-focus-$$RES$$.9.png"

  m.Menu.focusFootprintBitmapUri = "pkg:/images/menu-disabled-focus-$$RES$$.9.png"

  m.top.observeField("focusedChild", "onComponentFocus")


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
    m.Menu.focusBitmapBlendColor = theme.focusedColor
    m.Menu.focusFootprintBlendColor = theme.neutralColor
  end if
End Function


Function onComponentFocus()
  if m.top.isInFocusChain() = true
    m.top.opacity = 1.0
    if m.top.hasFocus() = true
      m.Menu.setFocus(true)
    end if
  else
    m.top.opacity = 0.7
  end if
End Function