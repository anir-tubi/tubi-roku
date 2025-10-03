Function init()
  topRef = m.top
  m.adIndicator = topRef.findNode("adIndicator")
  m.poster = topRef.findNode("poster")

  topRef.observeFieldScoped("itemContent", "onContentChange")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.adIndicator, typographyConstants.ids.bodyExtraSmallStrong)

  m.adIndicator.text = getTranslation("ad")

  setThemeColors()
End Function


Function setThemeColors()
  theme = getThemeFromGlobal()

  if theme <> invalid
    m.adIndicator.fontColor = theme.backgroundColor
    m.focusedColor = theme.focusedColor
    m.neutralColor2 = theme.neutralColor2
  end if
End Function


Function onContentChange(msg)
  itemContent = msg.getData()

  if itemContent <> invalid
    m.poster.uri = itemContent.hdGridPosterUrl
  end if
End Function
