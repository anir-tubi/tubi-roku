Function init()
  m.top.observeField("bgURL", "onBgURLChange")
  m.top.drawFocusFeedbackOnTop = false
  m.top.focusBitmapUri = "pkg://images/menu-focus-$$RES$$.9.png"
  theme = getThemeFromGlobal()
  if theme <> invalid
    m.top.focusBitmapBlendColor = theme.focusedColor
  end if
End Function


Function onBgURLChange()
  m.top.focusBitmapUri = m.top.bgURL
End Function