Function init()
  m.constants = m.global.constants
  m.top.drawFocusFeedbackOnTop = false
  m.top.focusBitmapUri = "pkg://images/menu-focus-fhd.9.png"

  if m.constants <> invalid and m.constants.deviceInfo.scaledUi = true
    m.top.focusBitmapUri = "pkg://images/menu-focus-hd.9.png"
  end if
End Function