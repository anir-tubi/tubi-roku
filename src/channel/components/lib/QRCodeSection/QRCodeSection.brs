Function init()
  topRef = m.top
  m.constants = getConstantsFromGlobal()
  topRef.observeFieldScoped("focusedChild", "onComponentFocusChange")
  topRef.observeFieldScoped("qrCodeSize", "onQRCodeSizeChange")
  m.heading = topRef.findNode("heading")
  m.subheading = topRef.findNode("subheading")
  m.qrCodePosterFocusRing = topRef.findNode("qrCodePosterFocusRing")
  m.qrCodeHolder = topRef.findNode("qrCodeHolder")
  m.qrCodePoster = topRef.findNode("qrCodePoster")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.heading, typographyConstants.ids.subheaderMedium) 
  setTypographyOfLabel(m.subheading, typographyConstants.ids.bodyMedium)

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
  m.top.focusable = true
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.heading.color = theme.primaryTextColor
    m.subheading.color = theme.secondaryTextColor
    m.qrCodeHolder.color = theme.backgroundColorLight
    m.qrCodePosterFocusRing.blendColor = theme.focusedColor
  end if
End Function


Function onComponentFocusChange()
  m.qrCodePosterFocusRing.visible = (m.top.hasFocus() = true)
End Function


Function onQRCodeSizeChange(msg)
  size = msg.getData()
  ' Adding padding around the qr code.
  focusRingSize = size + 21

  ' Increasing the height and width of the focus right and qr code holder based on qr code size.
  ' Not using alias to avoid having lengthy alias with all 4 of the below items.
  m.qrCodePosterFocusRing.width = focusRingSize
  m.qrCodePosterFocusRing.height = focusRingSize
  m.qrCodeHolder.width = focusRingSize
  m.qrCodeHolder.height = focusRingSize

  m.qrCodePoster.width = size
  m.qrCodePoster.height = size
End Function


Function onKeyEvent(key as string, press as boolean) as boolean
  if press = false
    return false
  end if

  if key = "OK"
    m.top.qrCodeSelected = true
    return true
  end if

  return false
End Function
