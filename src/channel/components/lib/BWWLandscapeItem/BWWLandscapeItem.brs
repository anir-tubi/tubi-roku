' BWWLandscapeItem - Landscape poster item for Browse While Watching row
' Similar to EpisodeItem but for YMAL/Related content in video player


' Initializes component: caches nodes, sets typography in init and colors in onThemeChange
Function init() as Void
  topRef = m.top
  typographyConstants = getTypographyConstants()

  m.thumbnail = topRef.findNode("thumbnail")
  m.focusIndicator = topRef.findNode("focusIndicator")
  m.contentTitle = topRef.findNode("contentTitle")
  m.description = topRef.findNode("description")
  m.metadata = topRef.findNode("metadata")
  m.subtitlesIcon = topRef.findNode("subtitlesIcon")
  m.ratingBadge = topRef.findNode("ratingBadge")

  setTypographyOfLabel(m.contentTitle, typographyConstants.ids.subheaderSmall, { lineSpacing: 2 })
  setTypographyOfLabel(m.description, typographyConstants.ids.bodyMedium, { lineSpacing: 2 })
  setTypographyOfLabel(m.metadata, typographyConstants.ids.bodyMedium)
  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()

  topRef.observeFieldScoped("itemContent", "onItemContentChange")
  topRef.observeFieldScoped("focusPercent", "onFocusPercentChange")
  topRef.observeFieldScoped("gridHasFocus", "onFocusPercentChange")
End Function


' Applies theme colors to labels and focus indicator
' @param msg - Optional message containing theme data
Function onThemeChange(msg = invalid) as Void
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.contentTitle.color = theme.primaryTextColor
    m.description.color = theme.primaryTextColor
    m.metadata.color = theme.secondaryTextColor
    m.focusIndicator.blendColor = theme.focusedColor
  end if
End Function


' Handles focus percent changes to show/hide focus indicator on poster only
' Only shows focus when grid has focus
' @param msg - Optional field change message
Function onFocusPercentChange(msg = invalid) as Void
  focusPercent = m.top.focusPercent
  gridHasFocus = m.top.gridHasFocus

  if focusPercent > 0 AND gridHasFocus = true
    m.focusIndicator.visible = true
    m.focusIndicator.opacity = focusPercent
  else
    m.focusIndicator.visible = false
  end if
End Function


' Handles itemContent changes and populates the item
' @param msg - Optional field change message
Function onItemContentChange(msg = invalid) as Void
  content = m.top.itemContent
  if content = invalid then return

  ' Set thumbnail
  imageUrl = content.landscape
  if isNonEmptyString(imageUrl) = false
    imageUrl = content.HDPosterUrl
  end if
  m.thumbnail.uri = imageUrl

  ' Set title
  title = content.title
  if title = invalid then title = ""
  m.contentTitle.text = title
  m.contentTitle.maxLines = 1

  ' Set metadata (year and duration)
  metadataText = buildMetadataText(content)
  m.metadata.text = metadataText

  m.ratingBadge.rating = content.rating

  ' Set subtitles icon
  m.subtitlesIcon.visible = (content.hasSubtitles = true OR isNonEmptyArray(content.subtitleTracks) = true)

  ' Set description
  if content.description <> invalid
    m.description.text = content.description
  else
    m.description.text = ""
  end if

  ' Hide description when showDescription is false (e.g. from VideoPlayerScreen BWW row)
  m.description.visible = (content.showDescription <> false)
End Function


' Builds metadata text string from content (year and duration)
' @param content - Content node with releaseDate and length
' @return Formatted string e.g. "2024 · 1h 30m" or empty
Function buildMetadataText(content) as String
  parts = []

  ' Add year from releaseDate
  if isNonEmptyString(content.releaseDate)
    year = Left(content.releaseDate, 4)
    if isNonEmptyString(year)
      parts.push(year)
    end if
  end if

  ' Add duration (Figma format: "1h 56m" / "45 min")
  contentLength = content.length
  if contentLength <> invalid AND contentLength > 0
    durationText = formatLengthAsHourAndMins(contentLength)
    if isNonEmptyString(durationText)
      parts.push(durationText)
    end if
  end if

  if parts.count() > 0
    return parts.join(" · ")
  end if

  return ""
End Function
