' Component for displaying label-value pairs in metadata
' Used to show information like "Starring: Actor Names"
Function init()
  topRef = m.top

  topRef.layoutDirection = "horiz"
  topRef.itemSpacings = [33]

  m.infoLabel = topRef.findNode("infoLabel")
  m.infoValue = topRef.findNode("infoValue")

  typographyConstants = getTypographyConstants()
  bodySmallFont = typographyConstants.ids.bodySmall
  setTypographyOfLabel(m.infoLabel, bodySmallFont)
  setTypographyOfLabel(m.infoValue, bodySmallFont)

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


' Handles theme changes and applies colors to labels
' @param msg - Optional message containing theme data
Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.infoLabel.color = theme.secondaryTextColor
    m.infoValue.color = theme.primaryTextColor
  end if
End Function
