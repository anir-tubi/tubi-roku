Function init()
  m.constants = getConstantsFromGlobal()

  m.nodeHelpers = TubiNodeHelpers()
  m.TitleGroup = m.top.findNode("TitleGroup")
  m.Title = m.top.findNode("Title")
  m.infoPanelGroup = m.top.findNode("infoPanelGroup")
  m.LiveVideoIndicator = m.top.findNode("LiveVideoIndicator")
  m.TitleLogo = m.top.findNode("TitleLogo")
  m.HeaderImage = m.top.findNode("HeaderImage")
  m.Episode = m.top.findNode("Episode")
  m.CategoryDetails = m.top.findNode("CategoryDetails")
  m.SeasonDetails = m.top.findNode("SeasonDetails")
  m.TwoLineInfo = m.top.findNode("TwoLineInfo")
  m.ClosedCaptions = m.top.findNode("ClosedCaptionPoster")
  m.resolutionPoster = m.top.findNode("resolutionPoster")
  m.Rating = m.top.findNode("Rating")
  m.RatingBackground = m.Rating.findNode("RatingBackground")
  m.RatingLabel = m.Rating.findNode("RatingLabel")

  m.FifaWorldCupGameDetails = m.top.findNode("FifaWorldCupGameDetails")
  m.fifaImage = m.top.findNode("fifaImage")
  m.FifaWorldCupTitle = m.top.findNode("FifaWorldCupTitle")
  m.sportsBadge = m.top.findNode("sportsBadge")
  m.matchTime = m.FifaWorldCupGameDetails.findNode("matchTime")
  m.roundGroupInfo = m.FifaWorldCupGameDetails.findNode("roundGroupInfo")
  m.FifaWorldCupDescription = m.top.findNode("FifaWorldCupDescription")
  m.FifaWorldCupClosedCaption = m.top.findNode("FifaWorldCupClosedCaptionPoster")
  m.FifaWorldCup4k = m.top.findNode("FifaWorldCup4kPoster")
  m.FifaWorldCupRating = m.top.findNode("FifaWorldCupRating")
  m.FifaWorldCupRatingBackground = m.FifaWorldCupRating.findNode("FifaWorldCupRatingBackground")
  m.FifaWorldCupRatingLabel = m.FifaWorldCupRating.findNode("FifaWorldCupRatingLabel")
  m.ReminderGroup = m.top.findNode("ReminderGroup")
  m.ReminderLogo = m.top.findNode("ReminderLogo")
  m.ReminderTitle = m.top.findNode("ReminderTitle")
  m.signInGroup = m.top.findNode("signInGroup")
  m.lockIcon = m.top.findNode("lockIcon")
  m.signInTitle = m.top.findNode("signInTitle")

  m.DescriptorCode = m.top.findNode("DescriptorCode")

  m.Description = m.top.findNode("Description")
  m.DescriptionGroup = m.top.findNode("DescriptionGroup")
  m.DescriptionFocusButton = m.top.findNode("DescriptionFocusButton")

  ' trying to access m.global can sometimes/rarely time out creating a run time error if we
  ' try to access m.global.theme directly, so use GlobalMixin.getThemeFromGlobal() which retries if issues arise.
  theme = getThemeFromGlobal()
  if theme <> invalid
    m.DescriptionFocusButton.blendColor = theme.focused
  end if

  m.StarringTag = m.top.findNode("StarringTag")
  m.DirectorTag = m.top.findNode("DirectorTag")
  m.Director = m.top.findNode("Director")
  m.DirectorGroup = m.top.findNode("DirectorGroup")
  m.StarringGroup = m.top.findNode("StarringGroup")
  m.Starring = m.top.findNode("Starring")
  m.PlayerCountdownGroup = m.top.findNode("PlayerCountdownGroup")
  m.CountdownText = m.top.findNode("CountdownText")
  m.Offset = m.top.findNode("Offset")
  m.PartnerLogo = m.top.findNode("PartnerLogo")
  m.ExpireWarning = m.top.findNode("ExpireWarning")
  m.ExpireWarning.color = m.constants.ui.colors.expirationWarning
  m.SecondLineGroup = m.top.findNode("SecondLineGroup")
  m.top.observeField("mode", "onModeChange")
  m.top.observeField("width", "onWidthChange")

  m.top.observeField("titleLogoUri", "onTitleLogoUriChange")
  m.top.observeField("headerImageUri", "onHeaderImageUriChange")
  m.top.observeFieldScoped("needsLogIn", "onNeedsLogInChange")
  m.top.observeField("lineOneData", "onLineOneDataChange")
  m.top.observeField("genres", "onGenresChange")
  m.top.observeField("description", "onDescriptionChange")
  m.top.observeField("directors", "onDirectorsChange")
  m.top.observeField("starring", "onStarringChange")
  m.top.observeField("seasonEpisodeCount", "onSeasonEpisodeCountChange")
  m.top.observeField("categoryContentCount", "onCategoryContentCountChange")
  m.top.observeField("fullscreenCountdown", "onPlayerCountDownChange")
  m.top.observeField("calculateHeight", "onCalculateHeight")
  m.top.observeField("focusedChild", "onComponentFocus")
  m.PartnerLogo.observeField("loadStatus", "onPosterLoadStatus")
  m.Rating.observeField("loadStatus", "onPosterLoadStatus")
  m.ClosedCaptions.observeField("loadStatus", "onPosterLoadStatus")
  m.resolutionPoster.observeField("loadStatus", "onPosterLoadStatus")
  m.FifaWorldCupClosedCaption.observeFieldScoped("loadStatus", "onPosterLoadStatus")
  m.FifaWorldCup4k.observeFieldScoped("loadStatus", "onPosterLoadStatus")
  m.FifaWorldCupRating.observeFieldScoped("loadStatus", "onPosterLoadStatus")

  onWidthChange()

  'set the default CC state to be no CC
  m.firstLineGroup = m.TwoLineInfo.findNode("FirstLineGroup")
'  firstLineGroup.removeChild(m.ClosedCaptions)

  m.FifaWorldCupFirstLineGroup = m.FifaWorldCupGameDetails.findNode("FifaWorldCupFirstLineGroup")

  'set the default title logo state to be no title logo
  m.TitleGroup.removeChild(m.TitleLogo)

  'Remove LiveVideoIndicator here because otherwise the poster is visible prior to any information being passed to info panel, when we open the app
  m.offset.removeChild(m.LiveVideoIndicator)

  m.StarringTag.width = 0
  m.DirectorTag.width = 0
  m.DirectorTag.text = getTranslation("metadata_directed")
  m.StarringTag.text = getTranslation("metadata_starring")


  '//Set a line after the directed by and starring text to be right aligned so the values associated with those lines are left aligned
  nStarringWidth = m.StarringTag.boundingRect().width
  nDirectorWidth = m.DirectorTag.boundingRect().width
  nLineMin = 43
  nMatchDirectorWidth = nStarringWidth - nDirectorWidth
  nMatchStarringWidth = nDirectorWidth - nStarringWidth

  if nMatchStarringWidth >= 0
    nMatchDirectorWidth = 0
  else
    nMatchStarringWidth = 0
  end if

  DirectorRect = m.top.findNode("DirectorRect")
  StarringRect = m.top.findNode("StarringRect")

  DirectorRect.width = nMatchDirectorWidth + nLineMin
  StarringRect.width = nMatchStarringWidth + nLineMin

End Function


Function onPosterLoadStatus(msg)
  poster = msg.getRoSGNode()
  if poster <> invalid AND poster.loadStatus = "ready"
    ' set width based on aspect ratio
    if poster.bitmapHeight > 0 'prevent divide by 0'
      poster.width = (poster.bitmapWidth / poster.bitmapHeight) * poster.height
      poster.visible = true
    else
      poster.visible = false
    end if

  end if
End Function


Function onComponentFocus()
  tubiLog("InfoPanel.onComponentFocus")
  if m.top.isInFocusChain() AND  m.top.description <> invalid AND m.top.description <> ""
    m.DescriptionFocusButton.visible = true
  else
    m.DescriptionFocusButton.visible = false
  end if
End Function


' Apply width to all components. Since the outer LayoutGroup has
' horizAlignment set to "custom", each child will have its translation
' field set to adjust it's x offset. We account for the x offset in
' setting each width here so that the children don't go beyond the right edge.
Function onWidthChange()
  tubiLog("InfoPanel.onWidthChange")

  if m.Title.width <> 0
    '//if the title is set to 0, then we do not want to make changes to the width of the title
    if m.TitleLogo.visible = true
      m.Title.width = m.top.width - m.Title.translation[0] - m.TitleGroup.itemSpacings[0] - m.TitleLogo.width - m.TitleLogo.translation[0]
    else
      m.Title.width = m.top.width - m.Title.translation[0]
    end if

  end if

  m.Episode.width = m.top.width - m.Episode.translation[0]
  categoryLine1 = m.CategoryDetails.findNode("CategoryLine1")
  categoryLine1.width = m.top.width - m.CategoryDetails.translation[0]
  seasonLine1 = m.SeasonDetails.findNode("SeasonLine1")
  seasonLine1.width = m.top.width - m.SeasonDetails.translation[0]
  line2 = m.TwoLineInfo.findNode("Line2")
  line2.width = m.top.width - m.TwoLineInfo.translation[0]

  ' The description text needs a right margin which matches its left margin
  m.Description.width = m.top.width - 2 * m.Description.translation[0]
  ' Reduce the director width based on "Direct by..." prefix
  directorPrefixBoundingRect = m.top.findNode("DirectorPrefix").boundingRect()
  m.Director.width = m.top.width - directorPrefixBoundingRect.width + m.DirectorGroup.itemSpacings[0] - m.DirectorGroup.translation[0]
  starringPrefixBoundingRect = m.top.findNode("StarringPrefix").boundingRect()
  m.Starring.width = m.top.width - starringPrefixBoundingRect.width + m.StarringGroup.itemSpacings[0] - m.StarringGroup.translation[0]
  m.DescriptionFocusButton.width = m.top.width + -m.DescriptionGroup.translation[0]
End Function


Function onTitleLogoUriChange()
  tubiLog("InfoPanel.onTitleLogoUriChange")
  if m.top.titleLogoUri <> ""
    m.TitleLogo.uri = m.top.titleLogoUri
    m.TitleGroup.insertChild(m.TitleLogo, 0)
    m.TitleLogo.visible = true
  else
    m.TitleGroup.removeChild(m.TitleLogo)
    m.TitleLogo.visible = false
  end if
End Function

Function onHeaderImageUriChange()
  tubiLog("InfoPanel.onHeaderImageUriChange")
  if m.top.headerImageUri <> ""
    m.HeaderImage.uri = m.top.headerImageUri
    m.infoPanelGroup.insertChild(m.HeaderImage, 0)
    m.HeaderImage.visible = true
  else
    m.infoPanelGroup.removeChild(m.HeaderImage)
  end if
End Function


Function onNeedsLogInChange()
  tubiLog("InfoPanel.onNeedsLogInChange")
  if m.signInGroup <> invalid
    m.offset.removeChild(m.signInGroup)
  end if

  if m.top.needsLogIn = true
    m.lockIcon.visible = true
    m.signInTitle.text = getTranslation("registration_signIn_to_play_hint")
    m.offset.appendChild(m.signInGroup)
  end if
End Function


Function onLineOneDataChange(msg)
  tubiLog("InfoPanel.onLineOneDataChange")
  data = msg.getData()
  if m.TwoLineInfo.findNode("FirstLineGroup") <> invalid
    m.twoLineInfo.removeChild(m.firstLineGroup)
  end if

  m.twoLineInfo.insertChild(m.firstLineGroup, 0)
  firstLineGroup = m.firstLineGroup
  line1Label = m.TwoLineInfo.findNode("Line1")

  text = ""
  if data.releasedate <> invalid AND data.releasedate <> ""
    text = data.releasedate + " "
  end if

  if data.length <> invalid AND data.length <> 0
    ' add 'dot' spacer only if we had a release date
    if text.len() > 0
      text = text + Chr(&hb7) + " "
    end if

    text = text + formatLengthAsEnglish(data.length) + " "
  end if

  if data.hoursOfAiring <> invalid AND data.hoursOfAiring <> ""
    text = text + data.hoursOfAiring
  end if

  if data.type <> invalid AND data.type = m.constants.ui.contentTypes.series
    ' add 'dot' spacer
    text = text + Chr(&hb7) + " "

    if data.seasons <> invalid AND data.seasons > 0

      if data.seasons = 1
        text = text + getTranslation("metadata_seasons_singular") + " "
      else
        text = text + getTranslation("metadata_seasons_plural", {seasons: data.seasons.toStr()}) + " "
      end if

    else
      text = text + getTranslation("metadata_series") + " "
    end if

  end if
  line1Label.text = text

  insertIndex = 1

  if data.hasCC = true
    if m.ClosedCaptions.getParent() = invalid
      firstLineGroup.insertChild(m.ClosedCaptions, insertIndex)
    end if

    insertIndex++
    ' Although this uri does not change, if it is set in the component XML, the icon will appear
    ' during the initial channel load, so set it dynamically when it should appear
    m.ClosedCaptions.uri = "pkg:/images/icon-closed-caption.png"
  else
    if m.ClosedCaptions.getParent() <> invalid
      firstLineGroup.removeChild(m.ClosedCaptions)
    end if

  end if

  if data.has4k = true
    if m.resolutionPoster.getParent() = invalid
      firstLineGroup.insertChild(m.resolutionPoster, insertIndex)
    end if

    insertIndex++
    ' Although this uri does not change, if it is set in the component XML, the icon will appear
    ' during the initial channel load, so set it dynamically when it should appear
    m.resolutionPoster.uri = "pkg:/images/icon-4k-ready-badge.png"
  else
    if m.resolutionPoster.getParent() <> invalid
      firstLineGroup.removeChild(m.resolutionPoster)
    end if

  end if

  if data.rating <> invalid AND data.rating <> ""
    if m.Rating.getParent() = invalid
      firstLineGroup.insertChild(m.Rating, insertIndex)
    end if

    insertIndex++
    m.RatingLabel.width = 0
    m.RatingLabel.text = Ucase(data.rating)

    nRatingBoundingBoxIncrease = m.RatingLabel.boundingRect().width + 24
    m.RatingBackground.width = nRatingBoundingBoxIncrease
    m.RatingLabel.width = nRatingBoundingBoxIncrease
    m.Rating.visible = true
  else
    if m.Rating.getParent() <> invalid
      firstLineGroup.removeChild(m.Rating)
    end if

    m.Rating.visible = false
  end if

  fifaWorldCupInsertIndex = 1
  firstLineInsertIndex = 0

  if m.FifaWorldCupGameDetails.findNode("FifaWorldCupFirstLineGroup") <> invalid
    m.FifaWorldCupGameDetails.removeChild(m.FifaWorldCupFirstLineGroup)
  end if

  if m.FifaWorldCupGameDetails.findNode("ReminderGroup") <> invalid
    m.FifaWorldCupGameDetails.removeChild(m.ReminderGroup)
  end if

  if data.availabilityType = m.constants.ui.categoryIds.fifawc
    fifaWorldCupInsertIndex++
  end if

  m.FifaWorldCupGameDetails.insertChild(m.FifaWorldCupFirstLineGroup, fifaWorldCupInsertIndex)
  FifaWorldCupFirstLineGroup = m.FifaWorldCupFirstLineGroup
  fifaWorldCupInsertIndex++

  'Upcoming and Replay Info
  if isNonEmptyString(data.availabilityType) = true
    'Need to add the correct background for badge
    if isNonEmptyString(data.badgeText) = true
      m.sportsBadge.visible = true
      if UCase(data.availabilityType) = UCase(m.constants.ui.contentTimings.replay)
        m.sportsBadge.backgroundColor = "0xF0F1F5"
        m.sportsBadge.textColor = "0x1C1F29"
      else if UCase(data.availabilityType) = UCase(m.constants.ui.contentTimings.upcoming)
        m.sportsBadge.backgroundColor = "0x585B66"
        m.sportsBadge.textColor = "0xF0F1F5"
      end if

      m.sportsBadge.text = Ucase(data.badgeText)
      FifaWorldCupFirstLineGroup.insertChild(m.sportsBadge, firstLineInsertIndex)
      firstLineInsertIndex++
    else
      m.sportsBadge.visible = false
      if m.sportsBadge.getParent() <> invalid
        FifaWorldCupFirstLineGroup.removeChild(m.sportsBadge)
      end if

    end if

  else
    m.sportsBadge.visible = false
    if m.sportsBadge.getParent() <> invalid
      FifaWorldCupFirstLineGroup.removeChild(m.sportsBadge)
    end if

  end if

  if isNonEmptyString(data.matchTime) = true
     m.matchTime.visible = true
    text = ""
    if data.length <> invalid AND data.length <> 0
      ' add 'dot' spacer only if we had a release date
      if text.len() > 0
        text = text + Chr(&hb7) + " "
      end if

      text = text + formatLengthAsEnglish(data.length) + " "
    end if

    m.matchTime.text = data.matchTime + " . " + text
    FifaWorldCupFirstLineGroup.insertChild(m.matchTime, firstLineInsertIndex)
    firstLineInsertIndex++
  else
    FifaWorldCupFirstLineGroup.removeChild(m.matchTime)
  end if

  if data.hasFifaWorldCup4k = true
    if m.FifaWorldCup4k.getParent() = invalid
      FifaWorldCupFirstLineGroup.insertChild(m.FifaWorldCup4k, firstLineInsertIndex)
    end if

    firstLineInsertIndex++
    ' Although this uri does not change, if it is set in the component XML, the icon will appear
    ' during the initial channel load, so set it dynamically when it should appear
    m.FifaWorldCup4k.uri = "pkg:/images/icon-4k-ready-badge.png"
  else
    if m.FifaWorldCup4k.getParent() <> invalid
      FifaWorldCupFirstLineGroup.removeChild(m.FifaWorldCup4k)
    end if

  end if

  if data.hasFifaWorldCupCC = true
    if m.FifaWorldCupClosedCaption.getParent() = invalid
      m.matchTime.visible = true
      FifaWorldCupFirstLineGroup.insertChild(m.FifaWorldCupClosedCaption, firstLineInsertIndex)
    end if

    firstLineInsertIndex++
    ' Although this uri does not change, if it is set in the component XML, the icon will appear
    ' during the initial channel load, so set it dynamically when it should appear
    m.FifaWorldCupClosedCaption.uri = "pkg:/images/icon-cc-filled.png"
  else
    if m.FifaWorldCupClosedCaption.getParent() <> invalid
      FifaWorldCupFirstLineGroup.removeChild(m.FifaWorldCupClosedCaption)
    end if

  end if


  if isNonEmptyString(data.fifaWorldCupRating)
    if m.FifaWorldCupRating.getParent() = invalid
      FifaWorldCupFirstLineGroup.insertChild(m.FifaWorldCupRating, firstLineInsertIndex)
    end if

    firstLineInsertIndex++
    m.FifaWorldCupRatingLabel.width = 0
    m.FifaWorldCupRatingLabel.text = Ucase(data.fifaWorldCupRating)

    nRatingBoundingBoxIncrease = m.FifaWorldCupRatingLabel.boundingRect().width + 24
    m.FifaWorldCupRatingBackground.width = nRatingBoundingBoxIncrease
    m.FifaWorldCupRatingLabel.width = nRatingBoundingBoxIncrease
    m.FifaWorldCupRating.visible = true
  else
    if m.FifaWorldCupRating.getParent() <> invalid
      FifaWorldCupFirstLineGroup.removeChild(m.FifaWorldCupRating)
    end if

    m.FifaWorldCupRating.visible = false
  end if

  if isNonEmptyString(data.roundGroupInfo) = true
    m.roundGroupInfo.text = data.roundGroupInfo
    if m.roundGroupInfo.getParent() = invalid
      m.FifaWorldCupGameDetails.insertChild(m.roundGroupInfo, fifaWorldCupInsertIndex)
    end if

    fifaWorldCupInsertIndex ++
  else
    if m.roundGroupInfo.getParent() <> invalid
      m.FifaWorldCupGameDetails.removeChild(m.roundGroupInfo)
    end if

  end if

  if data.isReminderSet <> invalid AND data.isReminderSet = true

    if m.ReminderGroup.getParent() = invalid
      m.ReminderLogo.visible = true
      m.ReminderTitle.text = getTranslation("screenDetails_button_reminder_set")
      m.FifaWorldCupGameDetails.insertChild(m.ReminderGroup, fifaWorldCupInsertIndex)
      fifaWorldCupInsertIndex++
    end if

  else
    m.FifaWorldCupGameDetails.removeChild(m.ReminderGroup)
  end if

  descriptorCode = data.descriptorCode

  if descriptorCode <> invalid AND descriptorCode <> ""

    if m.DescriptorCode.getParent() = invalid
      firstLineGroup.insertChild(m.DescriptorCode, insertIndex)
    end if

    insertIndex++

    m.DescriptorCode.text = UCase(descriptorCode)
    m.DescriptorCode.visible = true
  else

    if m.DescriptorCode.getParent() <> invalid
      firstLineGroup.removeChild(m.DescriptorCode)
    end if

    m.DescriptorCode.visible = false
  end if

  if data.availabilityEnds <> invalid AND data.availabilityEnds <> ""
    datetime = CreateObject("roDateTime")
    datetime.FromISO8601String(data.availabilityEnds)
    endSeconds = datetime.AsSeconds()
    nowSeconds = CreateObject("roDateTime").AsSeconds()
    daysRemaining = ((endSeconds - nowSeconds) \ 86400) + 1
    ' BIZ REQ: only titles expiring in the next 2 weeks should display message
    if daysRemaining > 0 AND daysRemaining <= 14
      if daysRemaining > 1
        m.ExpireWarning.text = getTranslation("metadata_expiresIn_plural", {days: daysRemaining.toStr()})
      else
        m.ExpireWarning.text = getTranslation("metadata_expiresIn_singular")
      end if

      if m.ExpireWarning.getParent() = invalid
        firstLineGroup.insertChild(m.ExpireWarning, insertIndex)
      end if

      insertIndex++
    else
      if m.ExpireWarning.getParent() <> invalid
        firstLineGroup.removeChild(m.ExpireWarning)
      end if

    end if
  else
    firstLineGroup.removeChild(m.ExpireWarning)
  end if

  if data.partnerLogoUri <> invalid AND data.partnerLogoUri <> ""
    if m.PartnerLogo.getParent() = invalid
      firstLineGroup.insertChild(m.PartnerLogo, insertIndex)
    end if

    insertIndex++
    m.PartnerLogo.uri = data.partnerLogoUri
  else
    if m.PartnerLogo.getParent() <> invalid
      firstLineGroup.removeChild(m.PartnerLogo)
    end if

  end if
End Function


Function onGenresChange()
  tubiLog("InfoPanel.onGenresChange")
  if m.SecondLineGroup.getParent() = invalid
    m.TwoLineInfo.appendChild(m.SecondLineGroup)
  end if

  line2Label = m.TwoLineInfo.findNode("Line2")
  text = ""
  if m.top.genres <> invalid AND m.top.genres.count() > 0
    capitalGenres = []
    for each c in m.top.genres
      capitalGenres.push(capitalize(c))
    end for
    text = capitalGenres.Join(", ")
  end if

  line2Label.text = text
End Function


Function onDescriptionChange()
  tubiLog("InfoPanel.onDescriptionChange")
  if m.top.description <> invalid AND m.top.description <> ""
    m.Description.visible = true
    m.Description.height = 0  ' reset for calculations below
    m.Description.text = m.top.description
  else
    m.Description.visible = false
  end if
End Function


Function onDirectorsChange()
  tubiLog("InfoPanel.onDirectorChange")
  text = ""
  if m.top.directors <> invalid AND m.top.directors.count() > 0
    text = m.top.directors.Join(", ")
  end if

  if text = ""
    ' hide the whole group if no directors listed
    m.DirectorGroup.visible = false
  else if m.DirectorGroup.visible = false
    m.DirectorGroup.visible = true
  end if

  m.Director.text = text
End Function


Function onStarringChange()
  tubiLog("InfoPanel.onStarringChange")
  text = ""
  if m.top.starring <> invalid AND m.top.starring.count() > 0
    text = m.top.starring.Join(", ")
  end if

  if text = invalid or text = ""
    ' hide the whole group if no actors/starring listed
    m.StarringGroup.visible = false
  else
    m.StarringGroup.visible = true
  end if

  m.Starring.text = text
End Function


Function onSeasonEpisodeCountChange()
  tubiLog("InfoPanel.onSeasonEpisodeCountChange")
  seasonLabel = m.SeasonDetails.findNode("SeasonLine1")
  if m.top.seasonEpisodeCount > 0
    seasonLabel.text = stri(m.top.seasonEpisodeCount).trim() + " episodes"
  else
    seasonLabel.text = ""
  end if
End Function


Function onCategoryContentCountChange()
  tubiLog("InfoPanel.onCategoryContentCountChange")
  categoryLine1 = m.CategoryDetails.findNode("CategoryLine1")
  if m.top.categoryContentCount <> invalid AND m.top.categoryContentCount > 0
    categoryLine1.text = stri(m.top.categoryContentCount).trim() + " titles in this category"
  else
    categoryLine1.text = ""
  end if
End Function


Function onPlayerCountDownChange()
  tubiLog("InfoPanel.onPlayerCountDownChange")
  if m.top.fullscreenCountdown >= 0
    m.PlayerCountdownGroup.visible = true
    m.CountdownText.text = getTranslation("metadata_fullscreen_countdown_plural", {seconds: m.top.fullscreenCountdown.toStr()})
  else
    m.PlayerCountdownGroup.visible = false
  end if
End Function


Function onCalculateHeight()
  tubiLog("InfoPanel.onCalculateHeight")
  topMargin = 15
  bottomMargin = 8
  m.DescriptionFocusButton.height = m.Description.boundingRect().height + topMargin + bottomMargin
  ' try to shorten description to fit max height
  if m.top.maxHeight <> 0 AND m.top.maxHeight < m.Offset.BoundingRect().height
    m.Description.height = m.Description.boundingRect().height - (m.offset.BoundingRect().height - m.top.maxHeight)
    if m.Description.height <= 0
      m.Description.text = ""
    end if

    m.DescriptionFocusButton.height = m.Description.boundingRect().height + topMargin + bottomMargin
  end if

  if m.top.needsLogIn = false AND m.top.mode = m.constants.ui.infoPanelModes.linearTournament AND m.top.mode <> m.constants.ui.infoPanelModes.epg
    m.top.appendChild(m.PlayerCountdownGroup)
    m.PlayerCountdownGroup.translation = [0, m.infoPanelGroup.boundingRect().height + 40]
  end if
End Function


'''''''''''''''''''
' onModeChange
'
' Make various fields visible or invisible by removing them from
' the children for rendering
Function onModeChange()
  tubiLog("InfoPanel.onModeChange")
  m.matchTime.visible = false
  m.fifaImage.visible = false
  while m.Offset.getChildCount() > 0
    m.Offset.removeChildIndex(0)
  end while

  if m.top.mode = m.constants.ui.infoPanelModes.navigateSports
    m.FifaWorldCupGameDetails.insertChild(m.FifaWorldCupDescription, 4)
  else if m.FifaWorldCupGameDetails.findNode("FifaWorldCupDescription") <> invalid
    m.FifaWorldCupGameDetails.removeChild(m.FifaWorldCupDescription)
  end if

  if m.HeaderImage <> invalid
    m.infoPanelGroup.removeChild(m.HeaderImage)
  end if

  if m.SecondLineGroup.getParent() = invalid
    m.TwoLineInfo.appendChild(m.SecondLineGroup)
  end if

  'm.PlayerCountdownGroup has been added to parent to accommodate EPG Screen design
  if m.PlayerCountdownGroup <> invalid
    m.top.removeChild(m.PlayerCountdownGroup)
  end if

  secondLineGroup = m.SecondLineGroup.getChild(0)

  if m.liveIconGroup <> invalid AND m.liveIconGroup.isSameNode(secondLineGroup) then
    m.SecondLineGroup.removeChild(m.liveIconGroup)
    m.liveIconGroup.shouldAnimate = false
  end if

  if m.fifaImage <> invalid
    m.FifaWorldCupGameDetails.removeChild(m.fifaImage)
  end if

  if m.badge <> invalid AND m.badge.isSameNode(secondLineGroup) then
    m.SecondLineGroup.removeChild(m.badge)
  end if

  if m.top.mode = m.constants.ui.infoPanelModes.category
    m.Offset.appendChild(m.TitleGroup)
    m.Offset.appendChild(m.CategoryDetails)
    m.Offset.appendChild(m.DescriptionGroup)
    m.Offset.itemSpacings = [52, 15]
  else if m.top.mode = m.constants.ui.infoPanelModes.vitg
    m.Offset.itemSpacings = [25, 15]
  else if m.top.mode = m.constants.ui.infoPanelModes.item
    m.Offset.appendChild(m.TitleGroup)
    m.Offset.appendChild(m.TwoLineInfo)
    m.Offset.appendChild(m.DescriptionGroup)
    m.Offset.itemSpacings = [25, 15]
  else if m.top.mode = m.constants.ui.infoPanelModes.movie
    m.Offset.appendChild(m.TitleGroup)
    m.Offset.appendChild(m.TwoLineInfo)
    m.Offset.appendChild(m.DescriptionGroup)
    m.Offset.appendChild(m.StarringGroup)
    m.Offset.appendChild(m.DirectorGroup)
    m.Offset.itemSpacings = [25, 15, 17, 11]
  else if m.top.mode = m.constants.ui.infoPanelModes.series
    m.Offset.appendChild(m.TitleGroup)
    m.Offset.appendChild(m.Episode)
    m.Offset.appendChild(m.TwoLineInfo)
    m.Offset.appendChild(m.DescriptionGroup)
    m.Offset.appendChild(m.StarringGroup)
    m.Offset.appendChild(m.DirectorGroup)
    m.Offset.itemSpacings = [25, 25, 15, 17, 11]
  else if m.top.mode = m.constants.ui.infoPanelModes.season
    m.Offset.appendChild(m.TitleGroup)
    m.Offset.appendChild(m.SeasonDetails)
    m.Offset.appendChild(m.DescriptionGroup)
    m.Offset.itemSpacings = [52, 15]
  else if m.top.mode = m.constants.ui.infoPanelModes.continue_watching
    m.Offset.appendChild(m.TitleGroup)
    m.Offset.appendChild(m.DescriptionGroup)
    m.Offset.itemSpacings = [15]
  else if m.top.mode = m.constants.ui.infoPanelModes.episode
    m.Offset.appendChild(m.TitleGroup)
    m.Offset.appendChild(m.Episode)
    m.Offset.appendChild(m.TwoLineInfo)
    m.Offset.appendChild(m.DescriptionGroup)
    m.Offset.itemSpacings = [25, 18]
  else if m.top.mode = m.constants.ui.infoPanelModes.linearHomeScreen
    '//For when the linear player is on the homepage
    m.Offset.appendChild(m.LiveVideoIndicator)
    m.Offset.appendChild(m.TitleGroup)
    m.Offset.appendChild(m.DescriptionGroup)
    m.Offset.appendChild(m.PlayerCountdownGroup)
    m.Offset.itemSpacings = [25,15]
  else if m.top.mode = m.constants.ui.infoPanelModes.epg
    '//For when the linear player is on its own EPG page
    m.infoPanelGroup.insertChild(m.HeaderImage,0)
    m.Offset.appendChild(m.TitleGroup)
    m.Offset.appendChild(m.TwoLineInfo)
    m.Offset.appendChild(m.DescriptionGroup)
    m.top.appendChild(m.PlayerCountdownGroup)
    m.PlayerCountdownGroup.translation = [1216,-78]
    m.Offset.itemSpacings = [12,0,12,11]
  else if m.top.mode = m.constants.ui.infoPanelModes.linearsearch
    m.Offset.appendChild(m.TitleGroup)
    m.Offset.appendChild(m.TwoLineInfo)
    m.Offset.appendChild(m.DescriptionGroup)
    m.Offset.itemSpacings = [25, 15]
    if m.firstLineGroup <> invalid
      m.twoLineInfo.removeChild(m.firstLineGroup)
    end if

    if getExperimentResource("roku_search_live_badge", "roku_search_live_badge_v1", true).enabled = true
      if m.badge = invalid then
        setLiveBadge()
      end if

      m.SecondLineGroup.insertChild(m.badge, 0)
    else
      if m.liveIconGroup = invalid then
        m.liveIconGroup = createObject("roSGNode", "LiveIconGroup")
      end if

      m.liveIconGroup.shouldAnimate = true
      m.SecondLineGroup.insertChild(m.liveIconGroup, 0)
    end if

  else if m.top.mode = m.constants.ui.infoPanelModes.linearTournament
    if m.top.headerImageUri <> ""
      m.infoPanelGroup.insertChild(m.HeaderImage,0)
    end if

    m.Offset.appendChild(m.TitleGroup)
    if m.SecondLineGroup <> invalid
      m.TwoLineInfo.removeChild(m.SecondLineGroup)
    end if

    m.Offset.appendChild(m.TwoLineInfo)
    m.Offset.appendChild(m.DescriptionGroup)
    m.Offset.itemSpacings = [12,0]
  '// REMOVE BELOW CODE ONCE FIFA WORLD CUP IS DONE
  else if m.top.mode = m.constants.ui.infoPanelModes.sportsEvent
    if UCase(m.top.availabilityType) = UCase(m.constants.ui.contentTimings.replay)
      m.matchTime.visible = true
    end if

    if UCase(m.top.availabilityType) = UCase(m.constants.ui.contentTimings.upcoming)
      m.matchTime.visible = false
    end if

    m.Offset.appendChild(m.FifaWorldCupGameDetails)
  '// REMOVE BELOW CODE ONCE FIFA WORLD CUP IS DONE
  else if m.top.mode = m.constants.ui.infoPanelModes.navigateSports
    m.fifaImage.visible = true
    m.FifaWorldCupGameDetails.insertChild(m.fifaImage , 0)
    m.matchTime.visible = true
    if m.FifaWorldCupGameDetails <> invalid
      m.FifaWorldCupGameDetails.removeChild(m.roundGroupInfo)
    end if

    m.Offset.appendChild(m.FifaWorldCupGameDetails)
  '// REMOVE BELOW CODE ONCE FIFA WORLD CUP IS DONE
  else if m.top.mode = m.constants.ui.infoPanelModes.noteworthy
    m.Offset.appendChild(m.TitleGroup)
    m.Offset.appendChild(m.TwoLineInfo)
    m.Offset.appendChild(m.DescriptionGroup)
    m.Offset.itemSpacings = [25, 25, 15, 17, 11]
  end if

End Function


Function setLiveBadge()
  tubiLog("InfoPanel.setLiveBadge")
  m.badge = CreateObject("roSGNode", "Badge")
  m.badge.translation = [12,12]
  m.badge.backgroundColor = "0xCC090B"
  m.badge.textColor = "0xFFFFFF"
  m.badge.iconUri = "pkg:/images/live-icon.png"
  m.badge.text = UCase(getTranslation("screenSearch_liveText"))
End Function


Function onKeyEvent(key, press) as Boolean
  if press AND key = "OK"
    m.top.descriptionSelected = true
    return true
  end if

  return false
End Function
