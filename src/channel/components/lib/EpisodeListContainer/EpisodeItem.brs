Function init() as Void
  topRef = m.top
  m.typographyConstants = getTypographyConstants()

  m.metadataRow = topRef.findNode("metadataRow")
  m.thumbnail = topRef.findNode("thumbnail")
  m.episodeTitle = topRef.findNode("episodeTitle")
  m.description = topRef.findNode("description")
  m.duration = topRef.findNode("duration")
  m.subtitlesIcon = topRef.findNode("subtitlesIcon")
  m.ratingBadge = topRef.findNode("ratingBadge")
  m.progressBarGroup = topRef.findNode("progressBarGroup")
  m.progressBar = topRef.findNode("progressBar")

  setTypographyOfLabel(m.episodeTitle, m.typographyConstants.ids.subheaderSmall, { lineSpacing: 2 })
  setTypographyOfLabel(m.description, m.typographyConstants.ids.bodyMedium, { lineSpacing: 2 })
  setTypographyOfLabel(m.duration, m.typographyConstants.ids.bodySmall)
  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
    m.global.observeFieldScoped("historyUpdated", "onHistoryUpdated")
  end if
  onThemeChange()

  nodeHelpers = TubiNodeHelpers()
  parentMarkupGrid = nodeHelpers.findParentWithField(topRef, "itemClippingRect")
  if parentMarkupGrid <> invalid
    m.itemHeight = parentMarkupGrid.itemClippingRect.height
  end if

  topRef.observeFieldScoped("itemContent", "onItemContentChange")
  topRef.observeFieldScoped("width", "onWidthChange")
End Function


Function onWidthChange(msg) as Void
  itemWidth = msg.getData()
  if itemWidth <= 0 then return

  thumbnailHeight = int(itemWidth * 9 / 16)

  progressBarPadding = 32
  progressBarWidth = itemWidth - progressBarPadding

  m.thumbnail.width = itemWidth
  m.thumbnail.height = thumbnailHeight
  m.episodeTitle.width = itemWidth
  m.description.width = itemWidth
  m.progressBarGroup.width = progressBarWidth
  m.progressBarGroup.translation = [15, thumbnailHeight - 18]
  m.progressBar.width = progressBarWidth
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

  episodeTitle = content.title

  if episodeTitle = invalid then
    episodeTitle = ""
  end if

  if content.gridItemType = "episodeItemLatestEpisodes" then
    m.description.scale = [0, 0]
    m.description.visible = false
    m.episodeTitle.maxLines = 2

    if isNonEmptyString(content.seriesTitle) = true then
      episodeTitle = content.seriesTitle + chr(10) + episodeTitle
    end if
  else if content.gridItemType = "landscapeSeriesMultiple" then
    m.episodeTitle.maxLines = 2
    m.description.maxLines = 2

    m.description.text = content.description

    if isNonEmptyString(content.seriesTitle) = true then
      episodeTitle = content.seriesTitle + chr(10) + episodeTitle
    end if
  else if content.gridItemType = "landscapeSeries" then
    m.description.maxLines = 3
    m.episodeTitle.maxLines = 1

    m.description.text = content.description
  else
    m.description.scale = [1, 1]
    m.description.visible = true

    ' Will need to revisit with next detail screen experiment
    m.description.maxLines = 2
    m.episodeTitle.maxLines = 1

    ' Set description if available
    if content.description <> invalid
      m.description.text = content.description
    end if
  end if

  ' Set basic info
  imageUrl = content.landscape
  m.thumbnail.uri = imageUrl
  m.episodeTitle.text = episodeTitle

  ' Set duration if available
  durationText = ""
  contentLength = content.length
  if contentLength <> invalid AND contentLength > 0
    durationMin = int(contentLength / 60)
    durationText = durationMin.toStr() + " min"
  end if
  m.duration.text = durationText

  m.ratingBadge.rating = content.rating
  m.subtitlesIcon.visible = content.hasSubtitles

  ' Set progress bar based on viewing history
  ' IMPROVEMENT Do not believe toStr is needed
  setProgressBar(content.id.toStr(), contentLength)

  if m.itemHeight <> invalid AND m.itemHeight > 600
    m.description.maxLines = 5
  end if
End Function


Function onHistoryUpdated() as Void
  content = m.top.itemContent
  if content = invalid then return

  contentLength = content.length
  if contentLength = invalid then return

  setProgressBar(content.id, contentLength)
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
