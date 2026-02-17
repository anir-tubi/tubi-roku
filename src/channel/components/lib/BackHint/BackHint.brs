' BackHint - Displays "Press [Back] For" hint with styled pill button
Function init() as Void
  topRef = m.top

  ' Cache node references
  m.pressLabel = topRef.findNode("pressLabel")
  m.backLabel = topRef.findNode("backLabel")
  m.forLabel = topRef.findNode("forLabel")
  m.pillBackground = topRef.findNode("pillBackground")

  ' Set typography
  typographyConstants = getTypographyConstants()
  bodySmallStrongFont = typographyConstants.ids.bodySmallStrong
  setTypographyOfLabel(m.pressLabel, bodySmallStrongFont)
  setTypographyOfLabel(m.backLabel, bodySmallStrongFont)
  setTypographyOfLabel(m.forLabel, bodySmallStrongFont)

  ' Set text using translations
  m.pressLabel.text = getTranslation("back_hint_press")
  m.backLabel.text = getTranslation("back_hint_back")
  m.forLabel.text = getTranslation("back_hint_for")

  ' Set up theme observer
  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


' Handles theme changes and applies colors
' @param msg - Optional message containing theme data
Function onThemeChange(msg = invalid) as Void
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.pressLabel.color = theme.primaryTextColor
    m.forLabel.color = theme.primaryTextColor
    m.pillBackground.blendColor = theme.primaryTextColor
    m.backLabel.color = theme.brandColor
  end if
End Function
