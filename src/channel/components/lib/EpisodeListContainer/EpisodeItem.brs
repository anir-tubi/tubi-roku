Function init() as Void
  topRef = m.top
  m.typographyConstants = getTypographyConstants()

  m.metadataRow = topRef.findNode("metadataRow")
  m.thumbnail = topRef.findNode("thumbnail")
  m.episodeTitle = topRef.findNode("episodeTitle")
  m.description = topRef.findNode("description")
  m.duration = topRef.findNode("duration")
  m.subtitlesIcon = topRef.findNode("subtitlesIcon")
  m.rating = topRef.findNode("rating")
  m.ratingBackground = topRef.findNode("ratingBackground")
  m.ratingLabel = topRef.findNode("ratingLabel")
  m.progressBarGroup = topRef.findNode("progressBarGroup")
  m.progressBar = topRef.findNode("progressBar")

  ' Set typography
  setTypographyOfLabel(m.episodeTitle, m.typographyConstants.ids.subheaderSmall)
  setTypographyOfLabel(m.description, m.typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.duration, m.typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.ratingLabel, m.typographyConstants.ids.bodyExtraSmallStrong)

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()

  nodeHelpers = TubiNodeHelpers()
  parentMarkupGrid = nodeHelpers.findParentWithField(topRef, "itemClippingRect")
  if parentMarkupGrid <> invalid
    m.itemHeight = parentMarkupGrid.itemClippingRect.height
  end if

  topRef.observeFieldScoped("itemContent", "onItemContentChange")
End Function


Function onThemeChange(msg = invalid) as Void
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.episodeTitle.color = theme.primaryTextColor
    m.description.color = theme.primaryTextColor
    m.duration.color = theme.secondaryTextColor
    m.ratingLabel.color = theme.secondaryTextColor
    m.progressBar.focusColor = theme.focusedColor
    m.progressBar.trackColor = theme.neutralColor
    m.progressBar.unfocusColor = theme.focusedColor
  end if
End Function


' Handles itemContent changes and populates the episode item
' @param msg - Optional message containing itemContent node
Function onItemContentChange(msg = invalid) as Void
  content = m.top.itemContent
  if content = invalid then return

  ' Set basic info
  m.thumbnail.uri = content.landscape
  ' TODO: Temporary fix for episode title formatting. Remove this once we have a proper backend solution.
  m.episodeTitle.text = formatEpisodeTitle(content.title)

  ' Set description if available
  if content.description <> invalid
    m.description.text = content.description
  end if

  ' Set duration if available
  contentLength = content.length
  if contentLength <> invalid AND contentLength > 0
    durationMin = int(contentLength / 60)
    m.duration.text = durationMin.toStr() + " min"
  end if

  ' Set rating badge
  setRatingBadge(content.rating)
  m.subtitlesIcon.visible = content.hasSubtitles

  ' Set progress bar based on viewing history
  setProgressBar(content.id.toStr(), contentLength)


  if m.itemHeight <> invalid AND m.itemHeight > 600
    m.description.maxLines = 5
  end if
End Function


' Sets the progress bar based on viewing history
' @param contentId - String, the content ID to look up in history
' @param duration - Integer, content duration in seconds
Function setProgressBar(contentId, duration) as Void
  history = getHistory(contentId)
  progressPercentage = calculateProgressPercentage(history, duration)

  if progressPercentage > 0
    m.progressBar.progress = progressPercentage
    m.progressBar.visible = true
  else
    m.progressBar.visible = false
  end if
End Function


' Calculates progress percentage from history and duration
' @param history - History object containing nowPos
' @param duration - Content duration in seconds
' @return Float - Progress percentage (0-100), or 0 if invalid
Function calculateProgressPercentage(history, duration) as Float
  if history = invalid OR not isNumber(history.nowPos) OR history.nowPos <= 0 then return 0
  if not isNumber(duration) OR duration <= 0 then return 0

  return (history.nowPos / duration) * 100
End Function


' Formats episode title from "S01:E01 - Pilot" to "S1 E1 - Pilot"
' @param title - String, the original episode title
' @return String - Formatted episode title
Function formatEpisodeTitle(title as String) as String
  if not isNonEmptyString(title) then return title

  ' Match pattern: S followed by digits, colon, E followed by digits
  regex = CreateObject("roRegex", "S([0-9]+):E([0-9]+)", "i")
  matches = regex.Match(title)

  if matches.Count() >= 3
    ' Extract season and episode numbers
    seasonNum = matches[1].toInt()
    episodeNum = matches[2].toInt()

    ' Replace "S01:E01" with "S1 E1"
    replacement = "S" + seasonNum.toStr() + " E" + episodeNum.toStr()
    formattedTitle = regex.Replace(title, replacement)
    return formattedTitle
  end if

  ' If pattern doesn't match, return original title
  return title
End Function


' Sets the rating badge visibility and sizing
' @param rating - String, the content rating (e.g., "PG", "R")
Function setRatingBadge(rating) as Void
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
