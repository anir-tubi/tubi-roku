Function init()
  m.nodeHelpers = TubiNodeHelpers()

  m.metadataGroup = m.top.findNode("metadataGroup")
  m.constants = getConstantsFromGlobal()
  m.leftHeaderImage = m.top.findNode("LeftHeaderImage")
  m.logoBackground = m.top.findNode("logoBackground")
  m.offset = m.top.findNode("Offset")
  m.title = m.top.findNode("Title")
  m.titleImage = m.top.findNode("TitleImage")
  m.episode = m.top.findNode("episode")
  m.sotTopLabelGroup = m.top.findNode("sotTopLabelGroup")
  m.sotMarkerGroup = m.top.findNode("sotMarkerGroup")
  m.sotMarker = m.top.findNode("sotMarker")

  m.BadgeTypes = {
    live: "live"
    onNow: "onNow"
    sot: "sot"
  }

  ' We are only limiting the height since title logo is displayed on it's own row we are good to let the width flow.
  m.titleImage.loadHeight = 90
  m.titleImage.loadWidth = 320

  m.firstLineGroup = m.top.findNode("FirstLineGroup")
  m.lineOneData = m.firstLineGroup.findNode("lineOneData")
  m.rating = m.firstLineGroup.findNode("Rating")
  m.ratingBackground = m.rating.findNode("RatingBackground")
  m.ratingLabel = m.rating.findNode("RatingLabel")

  m.top.observeFieldScoped("itemContent", "onItemContentChange")
  m.titleImage.observeFieldScoped("loadStatus", "onTitleImageLoadStatus")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.title, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.episode, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.lineOneData, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.ratingLabel, typographyConstants.ids.bodyExtraSmallStrong)
  m.badgeTextFont = typographyConstants.ids.bodyExtraSmallStrong

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
    m.title.color = theme.primaryTextColor
    m.episode.color = theme.primaryTextColor
    m.lineOneData.color = theme.primaryTextColor
    m.RatingLabel.color = theme.primaryTextColor
    m.focused2Color = theme.focused2Color
    m.blueBadgeColor = theme.blueBadgeColor
    m.ratingBackground.blendColor = theme.tertiaryTextColor
    m.focusedTextColor = theme.focusedTextColor
    m.cautionColor = theme.cautionColor
  end if
End Function


Function setTitle(titleImageUri)
  if isNonEmptyString(titleImageUri) = true
    parent = m.title.getParent()
    index = m.nodeHelpers.getChildIndex(parent, m.title)
    if index >= 0
      m.offset.insertChild(m.titleImage, index)
      m.offset.removeChild(m.title)
    end if

    if m.top.titleImageScale < 1.0
      m.titleImage.loadHeight = 90 * 0.75
      m.titleImage.loadWidth = 320 * 0.75
    end if

    m.titleImage.uri = titleImageUri
  else
    parent = m.titleImage.getParent()
    index = m.nodeHelpers.getChildIndex(parent, m.titleImage)
    m.title.visible = true
    if index >= 0
      m.offset.insertChild(m.title, index)
      m.offset.removeChild(m.titleImage)
    end if

    m.titleImage.uri = ""
  end if
End Function


Function setThumbnailImage(thumbnailUri, contentType)
  leftHeaderIsPresent = (m.logoBackground.getParent() <> invalid)
  if isNonEmptyString(thumbnailUri) = true AND (contentType = m.constants.ui.contentTypes.sportsEvent OR contentType = m.constants.ui.contentTypes.linear)
    if leftHeaderIsPresent = false
      m.top.insertChild(m.logoBackground, 0)
    end if

    m.leftHeaderImage.uri = thumbnailUri
  else if leftHeaderIsPresent = true
    m.top.removeChild(m.logoBackground)
  end if
End Function


Function onItemContentChange(msg)
  itemContent = msg.getData()

  if itemContent <> invalid
    m.title.visible = false
    m.title.lineSpacing = 0

    if itemContent.type = m.constants.ui.contentTypes.linear
      setThumbnailImage(itemContent.thumbnailUri, itemContent.type)
      currentProgram = getCurrentLiveProgram(itemContent)

      if currentProgram <> invalid

        if currentProgram.live = true
          setBadge(m.badgeTypes.live)
        else
          setBadge(m.badgeTypes.onNow)
        end if

        metadataOnLivePosterContent(currentProgram, itemContent)
      else
        setBadge(m.badgeTypes.onNow)
        metadataOnPosterContent(itemContent)
      end if

    else
      'Remove thumbnail image and badge we showed for live
      if m.logoBackground.getParent() <> invalid
        m.top.removeChild(m.logoBackground)
      end if

      setBadge(m.badgeTypes.sot, itemContent.sotInfo)
      metadataOnPosterContent(itemContent)
    end if

    adjustMetadataGroupTranslation()
  end if
End Function


Function metadataOnPosterContent(itemContent)

  firstLineGroup = m.firstLineGroup
  insertIndex = 0

  text = ""

  episodePresent = (m.episode.getParent() <> invalid)

  if episodePresent = true
    m.offset.removeChild(m.episode)
  end if

  if isNonEmptyArray(itemContent.tags) = true
    text = itemContent.tags[0] + " "
  end if

  if itemContent.year <> invalid
    ' add 'dot' spacer only if we had a tag/genre
    if text.len() > 0
      text += Chr(&hb7) + " "
    end if
    text += itemContent.year.toStr() + " "
  end if

  seasons = itemContent.seasons
  length = itemContent.length
  if seasons <> invalid AND seasons > 0

    if text.len() > 0
      text += Chr(&hb7) + " "
    end if

    if seasons = 1
      text += getTranslation("metadata_seasons_singular")
    else
      text += getTranslation("metadata_seasons_plural", { seasons: seasons.toStr() })
    end if
  else if length <> invalid AND length <> 0
    if text.len() > 0
      text += Chr(&hb7) + " "
    end if

    lengthString = formatLengthSelectedLocale(length)
    firstSubString = lengthString.split("h")
    secondSubString = ""

    if isNonEmptyArray(firstSubString) = true AND firstSubString[1] <> invalid
      secondSubString = firstSubString[1].split("min")
    else
      ' To handle cases where we only have minutes.
      arr = lengthString.split("min")
      firstSubString = arr[0].trim() + "m"
    end if

    if isNonEmptyArray(secondSubString) = true
      finalString = firstSubString[0].trim() + "h" + " " + secondSubString[0].trim() + "m"
    else
      finalString = firstSubString
    end if

    text += finalString + " "
  end if

  if isNonEmptyString(text) = true
    m.lineOneData.text = text
    insertIndex++
  end if

  ' handle rating
  ratingIsPresent = (m.rating.getParent() <> invalid)
  if isNonEmptyArray(itemContent.ratings) = true AND isAA(itemContent.ratings[0]) = true
    if ratingIsPresent = false
      firstLineGroup.insertChild(m.rating, insertIndex)
    end if

    m.ratingLabel.width = 0
    m.ratingLabel.text = UCase(itemContent.ratings[0].value)

    nRatingBoundingBoxIncrease = m.ratingLabel.boundingRect().width + 24
    m.ratingBackground.width = nRatingBoundingBoxIncrease
    m.ratingLabel.width = nRatingBoundingBoxIncrease
  else
    if ratingIsPresent = true
      firstLineGroup.removeChild(m.rating)
    end if
  end if

  m.title.text = itemContent.title
  setTitle(itemContent.titleImageUri)
End Function

Function metadataOnLivePosterContent(currentProgram, content)
  firstLineGroup = m.firstLineGroup
  insertIndex = 0

  text = ""

  if isNonEmptyString(content.title) = true
    text = content.title + " "
  end if

  timeLeft = calculateProgramTimeLeft(currentProgram)

  if timeLeft <> invalid
    if text.len() > 0
      text += Chr(&hb7) + " "
    end if

    text += timeLeft + " "
  end if

  if isNonEmptyString(text) = true
    m.lineOneData.text = text
    insertIndex++
  end if

  ' handle rating
  ratingIsPresent = (m.rating.getParent() <> invalid)
  if isNonEmptyString(currentProgram.rating) = true
    if ratingIsPresent = false
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

  m.title.text = currentProgram.title
  episodePresent = (m.episode.getParent() <> invalid)
  if isNonEmptyString(currentProgram.epgProgramTitle) = true
    parent = m.title.getParent()
    if episodePresent = false
      programEpisodeIndex = m.nodeHelpers.getChildIndex(parent, m.title) + 1
      m.offset.insertChild(m.episode, programEpisodeIndex)
    end if
    m.episode.text = currentProgram.epgProgramTitle
  else if episodePresent = true
    m.offset.removeChild(m.episode)
  end if

  setTitle(content.titleImageUri)
End Function


'@badgeType - string, Indicating format of the badge
'@badgeInfo - assocArray, includes sotMarkers, sotMetaDataTopLabels, sotMetaData
Function setBadge(badgeType = "live", badgeInfo = {})

  topLabelCount = m.sotTopLabelGroup.getChildCount()
  m.sotTopLabelGroup.removeChildrenIndex(topLabelCount, 0) 'remove all the previous top labels
  m.sotMarkerGroup.removeChild(m.sotMarker)

  if badgeType = m.badgeTypes.live
    m.badge = m.sotTopLabelGroup.createChild("Badge")
    m.badge.textColor = m.primaryTextColor
    m.badge.translation = [20, 20]
    m.badge.backgroundColor = m.focused2Color
    m.badge.iconUri = "pkg:/images/live-icon-filled.webp"
    m.badge.text = UCase(getTranslation("screenSearch_liveText"))
  else if badgeType = m.badgeTypes.onNow
    m.badge = m.sotTopLabelGroup.createChild("Badge")
    m.badge.textColor = m.primaryTextColor
    m.badge.translation = [20, 20]
    m.badge.backgroundColor = m.blueBadgeColor
    m.badge.text = UCase(getTranslation("onNow"))
  else if badgeType = m.badgeTypes.sot
    sotInfo = badgeInfo
    if sotInfo <> invalid
      sotTopLabelSignals = sotInfo.sotMetaDataTopLabels
      sotMarkers = sotInfo.sotMarkers

      if isNonEmptyArray(sotTopLabelSignals) = true
        for each signal in sotTopLabelSignals
          topLabel = createObject("roSGNode", "Badge")
          topLabel.text = signal.sotLabelText
          topLabel.iconUri = signal.sotIcon
          topLabel.textColor = m.focusedTextColor
          topLabel.maxWidth = m.top.width - 12
          m.sotTopLabelGroup.appendChild(topLabel)
        end for
      end if

      if isAA(sotMarkers) = true
        m.sotMarker = createObject("roSGNode", "Badge")
        m.sotMarker.id = "sotMarker"
        m.sotMarker.showBackground = false
        m.sotMarker.maxWidth = m.top.width
        m.sotMarker.text = sotMarkers.sotLabelText
        m.sotMarker.iconUri = sotMarkers.sotIcon
        m.sotMarker.badgeTextFont = m.badgeTextFont
        m.sotMarker.textColor = m.cautionColor
        translationX = 15
        translationY = m.top.height - m.sotMarker.boundingRect().height - 15
        m.sotMarkerGroup.translation = [translationX, translationY]
        m.sotMarkerGroup.appendChild(m.sotMarker)
      end if
    end if

  end if


End Function


Function calculateProgramTimeLeft(program) as String
  retVal = ""
  now = getCurrentLocalTime()

  if isInt(program.endTime) = true AND program.endTime > now
    timeLeft = program.endTime - now
    retVal = getDurationHoursString(timeLeft)
  end if

  return retVal
End Function


'helper function which returns the time left in the format 'x hour and y mins left' if timeleft is more than an hour
' else it retuns 'y mins left'
Function getDurationHoursString(seconds as Integer) as String
  retVal = ""

  if seconds <> invalid
    hourValue = Int(seconds / 3600)
    minValue = StrI((Int(seconds / 60) mod 60) + 1) 'increase the min by one so that we dont show 0 min

    if hourValue > 0
      retVal = getTranslation("h_m_left", { "hour": StrI(hourValue), "minutes": minValue })
    else
      retVal = getTranslation("m_left", { "minutes": minValue })
    end if
  end if

  return retVal
End Function


Function onTitleImageLoadStatus(msg)
  if msg.getData() = "ready"
    adjustMetadataGroupTranslation()
  end if
End Function


Function adjustMetadataGroupTranslation()
  height = m.metadataGroup.boundingRect().height
  if height > 100
    ' 330 is the poster height, 21 is 16 px gap from bottom and 5 px line spacing
    yTranslation = 330 - height - 21
  else
    yTranslation = 330 - height - 16
  end if

  if m.logoBackground.getParent() <> invalid
    'If the live have thumbnail we will add thumbnail width and 21 px gap for the metadaGroup translation.
    leftHeaderImageWidth = m.logoBackground.boundingRect().width
    m.metadataGroup.translation = [20 + leftHeaderImageWidth + 21, yTranslation]
    translationX = m.logoBackground.translation[0]
    translationY = 330 - m.logoBackground.boundingRect().height - 21
    m.logoBackground.translation = [translationX, translationY]
  else
    m.metadataGroup.translation = [20, yTranslation]
  end if
End Function
