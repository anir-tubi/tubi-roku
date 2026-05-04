Function init()
  m.titleLabel = m.top.findNode("titleLabel")
  m.genresLabel = m.top.findNode("genresLabel")
  m.ratingBadge = m.top.findNode("ratingBadge")
  m.subtitlesIcon = m.top.findNode("subtitlesIcon")
  m.descriptionLabel = m.top.findNode("descriptionLabel")


  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.titleLabel, typographyConstants.ids.headerSmall)
  setTypographyOfLabel(m.genresLabel, typographyConstants.ids.bodySmall)
  setTypographyOfLabel(m.descriptionLabel, typographyConstants.ids.bodyMedium, { lineSpacing: 2 })

  m.top.observeFieldScoped("content", "onContentChange")
  m.global.observeFieldScoped("theme", "onThemeChange")

  theme = getThemeFromGlobal()
  updateTheme(theme)
End Function


Function onThemeChange(msg)
  theme = msg.getData()
  updateTheme(theme)
End Function


Function updateTheme(theme)
  if theme <> invalid then
    m.titleLabel.color = theme.primaryTextColor

    m.genresLabel.color = theme.secondaryTextColor

    m.descriptionLabel.color = theme.primaryTextColor
  end if
End Function


Function onContentChange(msg) as Void
  content = msg.getData()
  if content = invalid then
    return
  end if

  if isArray(content.genres) = false then
    content.genres = []
  end if

  m.titleLabel.text = content.title
  m.genresLabel.text = content.genres.join(", ")
  m.subtitlesIcon.visible = content.hasSubtitles

  m.ratingBadge.rating = content.rating

  m.descriptionLabel.text = content.description
End Function
