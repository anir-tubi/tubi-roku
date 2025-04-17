Function init()
  m.ButtonBG = m.top.findNode("ButtonBG")
  m.ButtonIcon = m.top.findNode("ButtonIcon")
  m.ButtonText = m.top.findNode("ButtonText")

  m.top.observeFieldScoped("focusState", "updateUI")
  m.top.observeFieldScoped("enabled", "updateUI")
  m.top.observeFieldScoped("focusedChild", "updateUI")

  m.top.observeFieldScoped("text", "drawButton")
  m.top.observeFieldScoped("uri", "drawButton")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.ButtonText, typographyConstants.ids.bodyMediumStrong)

  m.top.focusable = true

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


Function drawButton()
  text = m.top.text
  uri = m.top.uri

  if text <> ""
    m.ButtonText.text = text
  end if

  if uri <> ""
    m.ButtonIcon.uri = uri
  end if

  textWidth = m.ButtonText.boundingRect().width + 40
  iconWidth = m.ButtonIcon.boundingRect().width + 40
  m.ButtonBG.width = textWidth + iconWidth
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  m.focusedColor = invalid
  m.neutralColor = invalid
  m.neutralColor2 = invalid
  m.backgroundColor = invalid
  m.primaryTextColor = invalid

  if theme <> invalid
    m.focusedColor = theme.focusedColor
    m.neutralColor = theme.neutralColor
    m.neutralColor2 = theme.neutralColor2
    m.backgroundColor = theme.backgroundColor
    m.primaryTextColor = theme.primaryTextColor
    m.ButtonText.color = m.primaryTextColor

    if m.top.hasUnfocusedBackground = true
      m.ButtonBG.blendcolor = m.neutralColor2
      m.ButtonBG.visible = true
    else
      m.ButtonBG.blendcolor = m.neutralColor
      m.ButtonBG.visible = false
    end if

  end if
End Function


Function updateUI()
  if m.top.focusState = true OR m.top.hasFocus() = true
    m.ButtonText.color = m.backgroundColor
    m.ButtonIcon.blendcolor = m.backgroundColor
    m.ButtonBG.blendcolor = m.focusedColor
    m.ButtonBG.visible = true
  else
    if m.top.hasUnfocusedBackground = true
      m.ButtonBG.blendcolor = m.neutralColor2
      m.ButtonBG.visible = true
    else
      m.ButtonBG.blendcolor = m.neutralColor
      m.ButtonBG.visible = false
    end if
    m.ButtonIcon.blendcolor = m.primaryTextColor
    m.ButtonText.color = m.primaryTextColor
  end if
End Function
