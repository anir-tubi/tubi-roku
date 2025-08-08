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
  m.ButtonText.width = 0

  if text <> ""
    m.ButtonText.text = text
  end if

  if uri <> ""
    m.ButtonIcon.uri = uri
  end if

  if m.top.alwaysShowLabel = true
    m.ButtonBG.width = calculateButtonWidth()
  else
    m.ButtonBG.width = 72
  end if

  if m.top.hasUnfocusedBackground = true
    m.ButtonBG.blendcolor = m.neutralColor2
    m.ButtonBG.visible = true
  else
    m.ButtonBG.visible = false
  end if

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
      m.ButtonBG.visible = false
    end if

  end if
End Function


Function updateUI()
  if m.top.focusState = true OR m.top.hasFocus() = true
    m.ButtonText.color = m.backgroundColor
    m.ButtonIcon.blendcolor = m.backgroundColor
    m.ButtonBG.blendcolor = m.focusedColor

    m.ButtonText.scale = [1, 1]
    m.ButtonBG.width = calculateButtonWidth()
    m.ButtonBG.visible = true

  else
    m.ButtonIcon.blendcolor = m.primaryTextColor
    if m.top.hasUnfocusedBackground = true
      m.ButtonBG.blendcolor = m.neutralColor2
      m.ButtonBG.visible = true
    else
      m.ButtonBG.blendcolor = m.neutralColor
      m.ButtonBG.visible = false
    end if
    if m.top.alwaysShowLabel = false
      m.ButtonText.scale = [0, 0]
      m.ButtonBG.width = 72
    else
      m.ButtonBG.width = calculateButtonWidth()
      m.ButtonText.scale = [1, 1]
    end if
    m.ButtonText.color = m.primaryTextColor
  end if
End Function


Function calculateButtonWidth()
  return m.ButtonText.boundingRect().width + 90
End Function