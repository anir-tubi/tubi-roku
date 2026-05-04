' RatingBadge - Reusable content rating badge (e.g., "TV-14", "PG-13")
' Dynamically sizes based on text length.
Function init() as Void
  topRef = m.top
  m.ratingLabel = topRef.findNode("ratingLabel")
  m.ratingBackground = topRef.findNode("ratingBackground")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.ratingLabel, typographyConstants.ids.bodyExtraSmallStrong)

  topRef.observeFieldScoped("rating", "onRatingChange")
  topRef.visible = false

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


' Applies theme colors to the rating label
' @param msg - Optional message containing theme data
Function onThemeChange(msg = invalid) as Void
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.ratingLabel.color = theme.secondaryTextColor
  end if
End Function


' Handles rating field changes and sizes the badge accordingly
Function onRatingChange(msg) as Void
  rating = msg.getData()
  if not isNonEmptyString(rating)
    m.top.visible = false
    return
  end if

  ratingLabel = m.ratingLabel
  ratingLabel.width = 0
  ratingLabel.text = UCase(rating)

  badgeWidth = ratingLabel.boundingRect().width + 24
  badgeWidth = ensureDivisibleBy3(badgeWidth)

  ratingLabel.width = badgeWidth
  m.ratingBackground.width = badgeWidth
  m.top.visible = true
End Function
