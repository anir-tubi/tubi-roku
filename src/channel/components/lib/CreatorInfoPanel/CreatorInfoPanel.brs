Function init()
  m.constants = getConstantsFromGlobal()

  m.poster = m.top.findNode("poster")
  m.nameLabel = m.top.findNode("nameLabel")
  m.genresLabel = m.top.findNode("genresLabel")
  m.descriptionLabel = m.top.findNode("descriptionLabel")

  m.poster.width = m.constants.ui.imageSizes.creatorScreenLogo[0]
  m.poster.height = m.constants.ui.imageSizes.creatorScreenLogo[1]

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.nameLabel, typographyConstants.ids.headerMedium)
  setTypographyOfLabel(m.genresLabel, typographyConstants.ids.bodySmall)
  setTypographyOfLabel(m.descriptionLabel, typographyConstants.ids.bodyMedium)

  m.global.observeFieldScoped("theme", "onThemeChange")

  theme = getThemeFromGlobal()
  updateTheme(theme)

  m.top.observeFieldScoped("content", "onContentChange")
End Function


Function onThemeChange(msg)
  theme = msg.getData()
  updateTheme(theme)
End Function


Function updateTheme(theme)
  if theme <> invalid
    m.genresLabel.color = theme.secondaryTextColor
  end if
End Function


Function onContentChange(msg) as Void
  content = msg.getData()
  if content = invalid then
    return
  end if

  m.nameLabel.text = content.title
  m.descriptionLabel.text = content.description
  m.genresLabel.text = content.genres.join(", ")
  m.poster.uri = content.images.logo[0]
End Function
