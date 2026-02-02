Function init()
  m.titleLabel = m.top.findNode("titleLabel")
  m.genresLabel = m.top.findNode("genresLabel")
  m.rating = m.top.findNode("rating")
  m.ratingLabel = m.top.findNode("ratingLabel")
  m.ratingBackground = m.top.findNode("ratingBackground")
  m.subtitlesIcon = m.top.findNode("subtitlesIcon")
  m.descriptionLabel = m.top.findNode("descriptionLabel")


  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.titleLabel, typographyConstants.ids.headerSmall)
  setTypographyOfLabel(m.genresLabel, typographyConstants.ids.bodySmall)
  setTypographyOfLabel(m.ratingLabel, typographyConstants.ids.bodyExtraSmallStrong)
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
    m.ratingLabel.color = theme.secondaryTextColor

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

  ' Set rating badge
  setRatingBadge(content.rating)

  m.descriptionLabel.text = content.description
End Function


' Sets the rating badge visibility and sizing
' @param rating - String, the content rating (e.g., "PG", "R")
Function setRatingBadge(rating) as Void
  ' IMPROVEMENT copied for now from EpisodeItem. If we use in one more place we should move to a mixin or helper
  if not isNonEmptyString(rating) then return

  ' Calculate badge width based on text
  ratingLabel = m.ratingLabel
  ratingLabel.width = 0
  ratingLabel.text = UCase(rating)

  badgeWidth = ratingLabel.boundingRect().width + 24
  badgeWidth = ensureDivisibleBy3(badgeWidth)

  ' Batch update both label and background
  ratingLabel.width = badgeWidth
  m.ratingBackground.width = badgeWidth
  m.rating.visible = true
End Function
