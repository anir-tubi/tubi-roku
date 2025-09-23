Function init()
  m.nodeHelpers = TubiNodeHelpers()

  m.metadataGroup = m.top.findNode("metadataGroup")
  m.constants = getConstantsFromGlobal()
  m.channelLogo = m.top.findNode("channelLogo")
  m.firstLineGroup = m.top.findNode("firstLineGroup")
  m.thirdLineGroup = m.top.findNode("thirdLineGroup")
  m.description = m.top.findNode("description")
  m.progressBar = m.top.findNode("progressBar")
  m.progressBarGroup = m.top.findNode("progressBarGroup")
  m.rating = m.firstLineGroup.findNode("Rating")
  m.ratingBackground = m.rating.findNode("RatingBackground")
  m.ratingLabel = m.rating.findNode("RatingLabel")
  m.sotBadge = m.firstLineGroup.findNode("sotBadge")
  m.closedCaptions = m.firstLineGroup.findNode("ClosedCaptionPoster")
  m.subHeadlinePrefixGroup = m.top.findNode("subHeadlinePrefixGroup")
  m.subHeadlineSuffixGroup = m.top.findNode("subHeadlineSuffixGroup")

  m.top.observeFieldScoped("itemContent", "onItemContentChange")
  m.top.observeFieldScoped("hideTitle", "onHideTitleChange")
  m.top.observeFieldScoped("width", "onWidthChange")

  experimentInfo = getExperimentResource("roku_home_screen_redesign", "roku_home_screen_redesign_v_1_6", false)
  m.variant = experimentInfo.variant

  typographyConstants = getTypographyConstants()
  m.bodyMediumFont = typographyConstants.ids.bodyMedium

  m.bodySmallFont = typographyConstants.ids.bodySmall

  m.title = invalid
  if m.variant = "typography_improvements"
    m.title = createObject("roSGNode", "Label")
    m.title.id = "title"
    setTypographyOfLabel(m.title, typographyConstants.ids.subheaderMedium)
    m.metadataGroup.insertChild(m.title, 0)

    m.metadataGroup.itemSpacings = [8, 4]
    setTypographyOfLabel(m.description, m.bodyMediumFont)
  else
    setTypographyOfLabel(m.description, m.bodySmallFont)
  end if

  setTypographyOfLabel(m.ratingLabel, typographyConstants.ids.bodyExtraSmallStrong)
  m.badgeTextFont = typographyConstants.ids.bodySmallStrong

  m.description.observeFieldScoped("isTextEllipsized", "onIsTextEllipsizedChange")

  m.top.observeFieldScoped("isBillboardRow", "onIsBillboardRowChange")

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.primaryTextColor = theme.primaryTextColor
    m.secondaryTextColor = theme.secondaryTextColor
    m.RatingLabel.color = theme.secondaryTextColor
    m.description.color = m.primaryTextColor

    m.progressBar.focusColor = theme.focusedColor
    m.progressBar.trackColor = theme.neutralColor
    m.progressBar.unfocusColor = theme.focusedColor
    m.ratingBackground.blendColor = theme.tertiaryTextColor

    if m.title <> invalid
      m.title.color = m.primaryTextColor
    end if
  end if
End Function


Function setThumbnailImage(thumbnailUri, contentType)
  channelLogoIsPresent = (m.channelLogo.getParent() <> invalid)
  if isNonEmptyString(thumbnailUri) = true AND (contentType = m.constants.ui.contentTypes.sportsEvent OR contentType = m.constants.ui.contentTypes.linear)
    if channelLogoIsPresent = false
      m.firstLineGroup.insertChild(m.channelLogo, 0)
    end if
    m.channelLogo.uri = thumbnailUri
  else if channelLogoIsPresent = true
    m.firstLineGroup.removeChild(m.channelLogo)
  end if
End Function


Function onItemContentChange(msg)
  itemContent = msg.getData()

  if itemContent <> invalid
    m.nodeHelpers.removeAllChildren(m.subHeadlinePrefixGroup)
    m.nodeHelpers.removeAllChildren(m.subHeadlineSuffixGroup)

    ' Resetting the visibility of the rating and sot badge.
    m.rating.visible = true
    m.sotBadge.visible = true
    onWidthChange()

    if m.title <> invalid
      m.title.text = itemContent.title
    end if

    if itemContent.type = m.constants.ui.contentTypes.linear
      setThumbnailImage(itemContent.thumbnailUri, itemContent.type)
      currentProgram = getCurrentLiveProgram(itemContent)
      if currentProgram <> invalid
        metadataOnLivePosterContent(currentProgram, itemContent)

        if isNonEmptyString(currentProgram.description) = true
          m.description.text = currentProgram.description
        end if

        progress = getLinearProgramProgress(currentProgram)
        m.progressBar.progress = progress
        m.progressBar.visible = true

        if m.progressBarGroup.getParent() = invalid
          index = m.nodeHelpers.getChildIndex(m.firstLineGroup, m.subHeadlinePrefixGroup)
          m.firstLineGroup.insertChild(m.progressBarGroup, index + 1)
        end if

        if m.subHeadlineSuffixGroup.getParent() = invalid
          index = m.nodeHelpers.getChildIndex(m.firstLineGroup, m.progressBarGroup)
          m.firstLineGroup.insertChild(m.subHeadlineSuffixGroup, index + 1)
        end if

        if m.sotBadge.getParent() <> invalid
          m.firstLineGroup.removeChild(m.sotBadge)
        end if
      else
        metadataOnPosterContent(itemContent)
        m.description.text = itemContent.description

        if m.subHeadlineSuffixGroup.getParent() <> invalid
          m.firstLineGroup.removeChild(m.subHeadlineSuffixGroup)
        end if

        if m.progressBarGroup.getParent() <> invalid
          m.firstLineGroup.removeChild(m.progressBarGroup)
        end if
      end if

    else
      'Remove thumbnail image and badge we showed for live
      if m.channelLogo.getParent() <> invalid
        m.firstLineGroup.removeChild(m.channelLogo)
      end if

      if m.subHeadlineSuffixGroup.getParent() <> invalid
        m.firstLineGroup.removeChild(m.subHeadlineSuffixGroup)
      end if

      if m.progressBarGroup.getParent() <> invalid
        m.firstLineGroup.removeChild(m.progressBarGroup)
      end if

      m.description.text = itemContent.description

      categoryContent = itemContent.getParent()
      if categoryContent <> invalid AND categoryContent.id = "continue_watching" AND itemContent.type <> m.constants.ui.contentTypes.series
        metadataOnContinueWatchingContent(itemContent)
      else
        metadataOnPosterContent(itemContent)
      end if
    end if
  end if
End Function


Function metadataOnPosterContent(itemContent)
  insertIndex = 0

  prefixTextParts = []

  tags = itemContent.tags
  if isNonEmptyArray(tags) = true
    text = tags[0]
    if tags[1] <> invalid
      if m.top.isBillboardRow = false
        text += ", " + tags[1]
      else
        text += " " + Chr(&hb7) + " " + tags[1]
      end if
    end if
    prefixTextParts.push(text)
  end if

  if itemContent.year <> invalid
    text = itemContent.year.toStr()
    prefixTextParts.push(text)
  end if

  seasons = itemContent.seasons
  length = itemContent.length
  if seasons <> invalid AND seasons > 0
    if seasons = 1
      text = getTranslation("metadata_seasons_singular")
    else
      text = getTranslation("metadata_seasons_plural", { seasons: seasons.toStr() })
    end if
    prefixTextParts.push(text)
  else if length <> invalid AND length <> 0
    lengthString = convertSecondsToHoursString(length)
    prefixTextParts.push(lengthString)
  end if

  if isNonEmptyArray(prefixTextParts) = true
    renderSubHeadline(prefixTextParts, true)
    insertIndex++
  end if


  if m.thirdLineGroup <> invalid
    ratingSotParent = m.thirdLineGroup
  else
    ratingSotParent = m.firstLineGroup
  end if

  ' handle rating
  ratingIsPresent = (m.rating.getParent() <> invalid)
  if isNonEmptyArray(itemContent.ratings) = true AND isAA(itemContent.ratings[0]) = true
    if ratingIsPresent = false
      ratingSotParent.insertChild(m.rating, insertIndex)
    end if

    m.ratingLabel.width = 0
    m.ratingLabel.text = UCase(itemContent.ratings[0].value)
    nRatingBoundingBoxIncrease = m.ratingLabel.boundingRect().width + 24
    nRatingBoundingBoxIncrease = ensureDivisibleBy3(nRatingBoundingBoxIncrease)
    m.ratingBackground.width = nRatingBoundingBoxIncrease
    m.ratingLabel.width = nRatingBoundingBoxIncrease
  else
    if ratingIsPresent = true
      ratingSotParent.removeChild(m.rating)
    end if
  end if

  isSotBadgePresent = (m.sotBadge.getParent() <> invalid)

  sotBadge = {}

  if isAA(itemContent.sotInfo) = true AND isNonEmptyArray(itemContent.sotInfo.sotMetadata)
    sotBadge = itemContent.sotInfo.sotMetadata[0]
  end if

  if itemContent.type <> "linear" AND isAA(sotBadge) = true AND sotBadge.count() > 0
    if isSotBadgePresent = false
      ratingIndex = m.nodeHelpers.getChildIndex(ratingSotParent, m.rating)
      if ratingIndex <> -1
        insertIndex = ratingIndex + 1
      end if
      ratingSotParent.insertChild(m.sotBadge, insertIndex)
    end if

    m.sotBadge.textColor = m.primaryTextColor
    m.sotBadge.showBackground = false
    m.sotBadge.badgeTextFont = m.badgeTextFont
    m.sotBadge.text = sotBadge.sotLabelText
    m.sotBadge.iconUri = sotBadge.sotIcon

  else if isSotBadgePresent = true
    ratingSotParent.removeChild(m.sotBadge)
  end if

  if itemContent.hascc = true
    m.closedCaptions.visible = true
  else
    m.closedCaptions.visible = false
  end if
End Function


Function metadataOnContinueWatchingContent(itemContent)
  m.closedCaptions.visible = false
  m.rating.visible = false
  ' Sot badge is will not be present in the continue watching content portrait mode.
  ' Due to progress bar being present in the poster already.
  m.sotBadge.visible = false

  history = getHistory(itemContent.id)
  nowPos = 0
  if history <> invalid AND isNumber(history.nowPos) = true
    nowPos = history.nowPos
  end if
  duration = itemContent.length
  if nowPos > 0 AND isNumber(duration) = true AND duration > 0
    percentage = nowPos / duration
    m.progressBar.progress = (percentage * 100)
    m.progressBar.visible = true

    if m.progressBarGroup.getParent() = invalid
      index = m.nodeHelpers.getChildIndex(m.firstLineGroup, m.subHeadlinePrefixGroup)
      timeLeft = convertSecondsToTimeLeftString(duration - nowPos)
      if isNonEmptyString(timeLeft) = true
        renderSubHeadline([timeLeft], false)
        m.firstLineGroup.insertChild(m.subHeadlineSuffixGroup, index + 1)
      end if

      m.firstLineGroup.insertChild(m.progressBarGroup, index + 1)
    end if
  end if
End Function


Function metadataOnLivePosterContent(currentProgram, content)
  firstLineGroup = m.firstLineGroup

  prefixTextParts = []

  releaseDate = currentProgram.releaseDate
  if releaseDate <> invalid
    releaseDate = releaseDate.toStr()
    if isNonEmptyString(releaseDate) = true
      prefixTextParts.push(releaseDate)
    end if
  end if

  duration = calculateProgramTime(currentProgram)
  if isNonEmptyString(duration) = true
    prefixTextParts.push(duration)
  end if

  timeLeft = calculateProgramTimeLeft(currentProgram)
  if timeLeft <> invalid
    renderSubHeadline([timeLeft], false)
  end if

  if isNonEmptyArray(prefixTextParts) = true
    renderSubHeadline(prefixTextParts, true)
  end if

  ' handle rating
  ratingIsPresent = (m.rating.getParent() <> invalid)
  if isNonEmptyString(currentProgram.rating) = true
    if ratingIsPresent = false
      insertIndex = m.nodeHelpers.getChildIndex(m.firstLineGroup, m.subHeadlinePrefixGroup)
      firstLineGroup.insertChild(m.rating, insertIndex + 1)
    end if

    m.ratingLabel.width = 0
    m.ratingLabel.text = UCase(currentProgram.rating)

    nRatingBoundingBoxIncrease = m.ratingLabel.boundingRect().width + 24
    m.ratingBackground.width = nRatingBoundingBoxIncrease
    m.ratingLabel.width = nRatingBoundingBoxIncrease
  else
    if ratingIsPresent = true
      firstLineGroup.removeChild(m.rating)
    end if
  end if
End Function


Function calculateProgramTimeLeft(program) as String
  retVal = ""
  now = getCurrentLocalTime()

  if isInt(program.endTime) = true AND program.endTime > now
    timeLeft = program.endTime - now
    retVal = convertSecondsToTimeLeftString(timeLeft)
  end if

  return retVal
End Function


Function calculateProgramTime(program) as String
  retVal = ""

  if isInt(program.endTime) = true AND isInt(program.startTime) = true
    duration = program.endTime - program.startTime
    retVal = convertSecondsToHoursString(duration)
  end if

  return retVal
End Function


Function convertSecondsToHoursString(seconds as Integer) as String
  retVal = ""

  if seconds <> invalid
    hourValue = Int(seconds / 3600)
    minValue = Int(seconds / 60) mod 60
    ' Not using translation for better performance since in all languages h and m are same.
    ' Please refer h_m_left for reference.
    if hourValue > 0 AND minValue > 0
      retVal = Substitute("{0}h {1}m", hourValue.toStr(), minValue.toStr())
    else if hourValue > 0
      retVal = Substitute("{0}h", hourValue.toStr())
    else
      if minValue < 1
        minValue = 1
      end if
      retVal = Substitute("{0}m", minValue.toStr())
    end if
  end if

  return retVal
End Function


' Triggers when the description text is ellipsized.
Function onIsTextEllipsizedChange(msg)
  isTextEllipsized = msg.getData()
  if isTextEllipsized = true
    m.description.width = 884
  end if
End Function


Function onHideTitleChange(msg)
  hideTitle = msg.getData()
  if m.title <> invalid
    if hideTitle = true
      m.title.scale = [0, 0]
    else
      m.title.scale = [1, 1]
    end if
  end if
End Function


Function onIsBillboardRowChange(msg)
  isBillboardRow = msg.getData()
  if isBillboardRow = true
    setTypographyOfLabel(m.description, m.bodyMediumFont)
    m.subHeadlinePrefixGroup.itemSpacings = [20]
    m.subHeadlineSuffixGroup.itemSpacings = [20]
    m.firstLineGroup.itemSpacings = [20]
  end if
End Function


Function renderSubHeadline(parts, isPrefix)
  if isPrefix = true
    group = m.subHeadlinePrefixGroup
  else
    group = m.subHeadlineSuffixGroup
  end if

  prefix = ""
  for each part in parts
    label = createObject("roSGNode", "Label")
    label.color = m.secondaryTextColor
    setTypographyOfLabel(label, m.bodySmallFont)
    label.text = prefix + part
    group.appendChild(label)
    if m.top.isBillboardRow = false
      prefix = " " + Chr(&hb7) + " "
    end if
  end for
End Function


Function onWidthChange()
  if m.top.descriptionWidth <= 0
    m.description.width = m.top.width
  else
    m.description.width = m.top.descriptionWidth
  end if
End Function
