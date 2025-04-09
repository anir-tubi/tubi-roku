Function init()
  m.nodeHelpers = TubiNodeHelpers()

  m.metadataGroup = m.top.findNode("metadataGroup")
  m.constants = getConstantsFromGlobal()
  m.leftHeaderImage = m.top.findNode("LeftHeaderImage")
  m.offset = m.top.findNode("Offset")
  m.title = m.top.findNode("Title")
  m.titleImage = m.top.findNode("TitleImage")

  m.BadgeTypes = {
    live: "live"
    onNow: "onNow"
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
  setTypographyOfLabel(m.lineOneData, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.ratingLabel, typographyConstants.ids.bodyExtraSmallStrong)

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
    m.lineOneData.color = theme.primaryTextColor
    m.RatingLabel.color = theme.primaryTextColor
    m.focused2Color = theme.focused2Color
    m.blueBadgeColor = theme.bluebadgecolor
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
  leftHeaderIsPresent = (m.leftHeaderImage.getParent() <> invalid)
  if isNonEmptyString(thumbnailUri) = true AND (contentType = m.constants.ui.contentTypes.sportsEvent OR contentType = m.constants.ui.contentTypes.linear)
    if leftHeaderIsPresent = false
      m.top.insertChild(m.leftHeaderImage, 0)
    end if

    m.leftHeaderImage.uri = thumbnailUri
  else if leftHeaderIsPresent = true
    m.top.removeChild(m.leftHeaderImage)
  end if
End Function


Function onItemContentChange(msg)
  itemContent = msg.getData()

  m.title.visible = false
  m.title.lineSpacing = 0

  if itemContent.type = m.constants.ui.contentTypes.linear
    setThumbnailImage(itemContent.thumbnailUri,  itemContent.type)
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
    leftHeaderIsPresent = (m.leftHeaderImage.getParent() <> invalid)
    if leftHeaderIsPresent = true
      m.top.removeChild(m.leftHeaderImage)
    end if

    badgePresent = (m.badge <> invalid AND m.badge.getParent() <> invalid)
    if badgePresent = true
      m.top.removeChild(m.badge)
    end if

    metadataOnPosterContent(itemContent)
  end if

  adjustMetadataGroupTranslation()
End Function


Function metadataOnPosterContent(itemContent)

  firstLineGroup = m.firstLineGroup
  insertIndex = 0

  text = ""

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
      text += getTranslation("metadata_seasons_plural", {seasons: seasons.toStr()})
    end if
  else if length <> invalid AND length <> 0
    if text.len() > 0
      text += Chr(&hb7) + " "
    end if

    lengthString = formatLengthSelectedLocale(length)
    text += lengthString.replace("min", "m") + " "
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

  if isNonEmptyArray(content.title) = true
    text = content.title + " "
  end if

  timeleft = calculateProgramTimeLeft(currentProgram)

  if timeleft <> invalid
    if text.len() > 0
      text += Chr(&hb7) + " "
    end if

    text += timeleft.replace("min", "m") + " "
  end if

  if isNonEmptyString(text) = true
    m.lineOneData.text = text
    insertIndex++
  end if

  ' handle rating
  ratingIsPresent = (m.rating.getParent() <> invalid)
  if isNonEmptyArray(currentProgram.rating) = true
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
  setTitle(content.titleImageUri)
End Function


'@badgeType - string, Indicating format of the badge
'@badgeText - string, Indicating text on the badge
Function setBadge(badgeType = "live", badgeText = "")

  if m.badge = invalid
    m.badge = m.top.createChild("Badge")
    m.badge.textColor = m.primaryTextColor
    m.badge.translation = [20, 20]
  end if

  if badgeType = m.badgeTypes.live
    m.badge.backgroundColor = m.focused2Color
    m.badge.iconUri = "pkg:/images/live-icon-filled.webp"
    m.badge.text = UCase(getTranslation("screenSearch_liveText"))
  else if badgeType = m.badgeTypes.onNow
    m.badge.backgroundColor = m.blueBadgeColor
    m.badge.text = UCase(getTranslation("onNow"))
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
Function getDurationHoursString(seconds As Integer) As String
  retVal = ""

  if seconds <> invalid
    hourValue = Int(seconds / 3600)
    minValue = StrI((Int(seconds / 60) mod 60) + 1) 'increase the min by one so that we dont show 0 min

    if hourValue > 0
      retVal =  getTranslation("hour_mins_left", {"hour": StrI(hourValue), "minutes": minValue})
    else
      retVal = getTranslation("mins_left", {"minutes": minValue})
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

  if m.leftHeaderImage.getParent() <> invalid
    'If the live have thumbnail we will add thumbnail width and 21 px gap for the metadaGroup translation.
    leftHeaderImageWidth = m.leftHeaderImage.boundingRect().width
    m.metadataGroup.translation = [20 + leftHeaderImageWidth + 21, yTranslation]
  else
    m.metadataGroup.translation = [20, yTranslation]
  end if
End Function
