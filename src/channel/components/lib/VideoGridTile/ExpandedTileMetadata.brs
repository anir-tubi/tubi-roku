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
  m.tubiPresentsLogo = m.firstLineGroup.findNode("tubiPresentsLogo")
  m.sotTopLabelGroup = m.top.findNode("sotTopLabelGroup")

  m.top.observeFieldScoped("itemContent", "onItemContentChange")
  m.top.observeFieldScoped("hideTitle", "onHideTitleChange")
  m.top.observeFieldScoped("width", "onWidthChange")

  experimentInfo = getStatsigExperimentResource("roku_video_tiles", "roku_video_tiles_1_7", false)
  m.variant = experimentInfo.variant

  typographyConstants = getTypographyConstants()
  m.bodyMediumFont = typographyConstants.ids.bodyMedium
  m.bodySmallFont = typographyConstants.ids.bodySmall
  m.headerSmallFont = typographyConstants.ids.headerSmall
  m.bodyMediumStrongFont = typographyConstants.ids.bodyMediumStrong

  m.title = invalid
  if m.variant = "typography_improvements"
    appendTitleToMetadataGroup()
  else
    setTypographyOfLabel(m.description, m.bodyMediumFont)
  end if

  setTypographyOfLabel(m.ratingLabel, typographyConstants.ids.bodyExtraSmallStrong)
  m.badgeTextFont = typographyConstants.ids.bodySmallStrong

  m.description.observeFieldScoped("isTextEllipsized", "onIsTextEllipsizedChange")

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
    m.focusedTextColor = theme.focusedTextColor
    m.cautionColor = theme.cautionColor

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
    m.nodeHelpers.removeAllChildren(m.sotTopLabelGroup)
    m.metadataGroup.removeChild(m.sotTopLabelGroup)
    m.nodeHelpers.removeAllChildren(m.subHeadlinePrefixGroup)
    m.nodeHelpers.removeAllChildren(m.subHeadlineSuffixGroup)

    if m.sotMarker <> invalid
      m.metadataGroup.removeChild(m.sotMarker)
    end if

    isVideoTilesControlMetadata = m.top.id = "videoTilesControlMetadata"
    if isVideoTilesControlMetadata = false
      m.metadataGroup.itemSpacings = [9]
    end if
    if isVideoTilesControlMetadata = true AND m.title = invalid
      appendTitleToMetadataGroup()
    end if

    ' Resetting the visibility of the rating and sot badge.
    m.rating.visible = true
    m.sotBadge.visible = true
    onWidthChange()

    if m.title <> invalid
      m.title.text = itemContent.title
    end if

    if itemContent.type = m.constants.ui.contentTypes.linear
      if m.top.isBillboardRow = false
        setThumbnailImage(itemContent.thumbnailUri, itemContent.type)
      else
        m.firstLineGroup.removeChild(m.channelLogo)
      end if
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
        displayLiveRating(currentProgram)
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

    if isVideoTilesControlMetadata = true AND itemContent.type <> m.constants.ui.contentTypes.linear AND isNonEmptyString(itemContent.availabilityEnds) AND m.sotBadge.getParent() = invalid
      setupExpiresBadge(itemContent)
    end if

    ' Adjust the translation based on height of the description text.
    if isVideoTilesControlMetadata
      ' Create SOT badges using helper function
      sotBadges = createSOTBadges(itemContent.sotInfo, {
        focusedTextColor: m.focusedTextColor
        maxWidth: m.top.width - 12
        bodyMediumStrongFont: m.bodyMediumStrongFont
        cautionColor: m.cautionColor
      })

      if isNonEmptyArray(sotBadges.topLabels) = true
        m.metadataGroup.insertChild(m.sotTopLabelGroup, 0)
      end if

      ' Append top label badges
      for each topLabel in sotBadges.topLabels
        m.sotTopLabelGroup.appendChild(topLabel)
      end for

      ' Append marker badge if exists
      if sotBadges.marker <> invalid
        ' Update maxWidth for marker to full width
        sotBadges.marker.maxWidth = m.top.width
        m.sotMarker = sotBadges.marker
        m.metadataGroup.appendChild(m.sotMarker)
      end if
      ' With 3 lines of description text, the height is 230px and with 2 lines of description text, the height is 192px.
      ' And parent level translation is set based on 2 lines of description text. So we are adjusting the bottom padding by negative margining the metadataGroup.
      ' This is required only for control variant.
      height = m.metadataGroup.boundingRect().height
      translation = m.metadataGroup.translation
      m.metadataGroup.translation = [translation[0], 192 - height]
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
    if m.variant <> "trueControlTop2Rows" OR m.top.id <> "videoTilesControlMetadata"
      prefixTextParts.push(text)
    else
      renderTags(text)
    end if
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

  if itemContent.type <> "linear" AND isAA(sotBadge) = true AND sotBadge.count() > 0 AND sotBadge.sotType <> "tubiPresentsLogo"
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

  sotInfo = itemContent.sotInfo
  ' handle sotMetaData - append tubiPresentsLogo Poster to firstLineGroup if type is "tubiPresentsLogo"
  tubiPresentsLogoIsPresent = (m.tubiPresentsLogo.getParent() <> invalid)
  ' Remove the poster if no sotMetaData or no matching type
  if tubiPresentsLogoIsPresent = true
    m.firstLineGroup.removeChild(m.tubiPresentsLogo)
    m.tubiPresentsLogo.visible = false
  end if

  if isAA(sotInfo) = true AND isNonEmptyArray(sotInfo.sotMetaData) = true
    for each sotMetadata in sotInfo.sotMetaData
      if sotMetadata.sotType = "tubiPresentsLogo"

        ' Append the tubiPresentsLogo Poster to firstLineGroup
        m.firstLineGroup.appendChild(m.tubiPresentsLogo)

        ' Set Poster properties - use sotIcon as the uri
        if isNonEmptyString(sotMetadata.sotIcon) = true
          m.tubiPresentsLogo.uri = sotMetadata.sotIcon
        end if

        ' Set dimensions if provided
        if isNumber(sotMetadata.width) = true
          m.tubiPresentsLogo.width = sotMetadata.width
        end if

        if isNumber(sotMetadata.height) = true
          m.tubiPresentsLogo.height = sotMetadata.height
        end if

        m.tubiPresentsLogo.visible = true
        exit for ' Only process the first matching item
      end if
    end for
  end if

  if itemContent.hasSubtitles = true
    if m.closedCaptions.getParent() = invalid
      index = m.nodeHelpers.getChildIndex(ratingSotParent, m.rating)
      ' Which means rating is not present in the first line group.
      ' As a fallback displaying in a fixed position.
      if index = -1
        index = 1
      end if
      m.firstLineGroup.insertChild(m.closedCaptions, index + 1)
    end if
    m.closedCaptions.visible = true
  else
    m.firstLineGroup.removeChild(m.closedCaptions)
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
End Function


Function displayLiveRating(currentProgram)
  firstLineGroup = m.firstLineGroup
  ' handle rating
  ratingIsPresent = (m.rating.getParent() <> invalid)
  if isNonEmptyString(currentProgram.rating) = true
    if ratingIsPresent = false
      insertIndex = m.nodeHelpers.getChildIndex(m.firstLineGroup, m.subHeadlineSuffixGroup) + 1
      firstLineGroup.insertChild(m.rating, insertIndex)
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
    isVideoTilesControlMetadata = m.top.id = "videoTilesControlMetadata"
    if isVideoTilesControlMetadata = true
      setTypographyOfLabel(label, m.bodyMediumFont)
    else
      setTypographyOfLabel(label, m.bodySmallFont)
    end if
    label.text = prefix + part
    label.height = 40
    label.vertAlign = "center"
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


Function appendTitleToMetadataGroup()
  m.title = createObject("roSGNode", "Label")
  m.title.id = "title"
  setTypographyOfLabel(m.title, m.headerSmallFont)
  m.metadataGroup.insertChild(m.title, 0)
  if m.variant = "trueControlTop2Rows" AND m.top.id = "videoTilesControlMetadata"
    m.metadataGroup.itemSpacings = [18, 3, 15]
  else if m.variant = "refinedControlTop2Rows" AND m.top.id = "videoTilesControlMetadata"
    m.metadataGroup.itemSpacings = [15, 18]
  else if m.variant = "cinematicTop2Rows" AND m.top.id = "videoTilesControlMetadata"
    m.metadataGroup.itemSpacings = [9, 9]
  else
    m.metadataGroup.itemSpacings = [9, 3]
  end if
  setTypographyOfLabel(m.description, m.bodyMediumFont)
End Function


Function setupExpiresBadge(itemContent)
  badgeInfo = getExpiresBadgeInfo(itemContent.availabilityEnds)
  if badgeInfo <> invalid
    m.sotBadge.textColor = m.focusedTextColor
    m.sotBadge.text = badgeInfo.text
    m.sotBadge.visible = true
    m.firstLineGroup.appendChild(m.sotBadge)
  end if
End Function


Function renderTags(tags)
  if m.tagsLabel <> invalid
    m.metadataGroup.removeChild(m.tagsLabel)
  end if

  label = createObject("roSGNode", "Label")
  label.id = "tags"
  label.color = m.secondaryTextColor
  setTypographyOfLabel(label, m.bodyMediumFont)
  label.text = tags
  label.height = 40
  label.vertAlign = "center"
  m.metadataGroup.insertChild(label, 2)

  m.tagsLabel = label
End Function