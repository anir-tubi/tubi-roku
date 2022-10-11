Function init()
  m.top.drawFocusFeedbackOnTop = false
  m.top.focusBitmapUri = "pkg://images/menu-focus-fhd.9.png"

  constants = getConstantsFromGlobal()
  if constants <> invalid AND constants.deviceInfo.scaledUi = true
    m.top.focusBitmapUri = "pkg://images/menu-focus-hd.9.png"
  end if

  theme = getThemeFromGlobal()
  if theme <> invalid
    m.top.focusBitmapBlendColor = theme.focused
  end if
End Function