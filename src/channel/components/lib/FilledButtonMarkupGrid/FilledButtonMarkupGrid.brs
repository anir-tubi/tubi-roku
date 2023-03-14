Function init()
  m.top.drawFocusFeedbackOnTop = false
  m.top.focusBitmapUri = "pkg://images/menu-focus-{size}.9.png"

  theme = getThemeFromGlobal()
  if theme <> invalid
    m.top.focusBitmapBlendColor = theme.focusedColor
  end if
End Function