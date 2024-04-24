Function init()
  m.constants = getConstantsFromGlobal()

  m.nodeHelpers = TubiNodeHelpers()

  m.offset = m.top.findNode("Offset")
  m.infoPanelGroup = m.top.findNode("infoPanelGroup")
  m.topHeaderImage = m.top.findNode("TopHeaderImage")
  m.liveBadgeHeader = m.top.findNode("liveBadgeHeader")
  m.leftHeaderImage = m.top.findNode("LeftHeaderImage")

  m.title = m.top.findNode("Title")
  m.episode = m.top.findNode("Episode")
  m.twoLineInfo = m.top.findNode("TwoLineInfo")

  m.firstLineGroup = m.twoLineInfo.findNode("FirstLineGroup")
  m.firstLineAvailabilityBadge = m.firstLineGroup.findNode("FirstLineAvailabilityBadge")
  m.line1 = m.firstLineGroup.findNode("Line1")
  m.line1Bold = m.firstLineGroup.findNode("Line1Bold")
  m.resolutionPoster = m.firstLineGroup.findNode("ResolutionPoster")
  m.closedCaptions = m.firstLineGroup.findNode("ClosedCaptionPoster")
  m.audioDescriptionPoster = m.firstLineGroup.findNode("AudioDescriptionPoster")
  m.rating = m.firstLineGroup.findNode("Rating")
  m.ratingBackground = m.rating.findNode("RatingBackground")
  m.ratingLabel = m.rating.findNode("RatingLabel")
  m.descriptorCode = m.firstLineGroup.findNode("DescriptorCode")
  m.expireWarning = m.firstLineGroup.findNode("ExpireWarning")
  m.partnerLogo = m.firstLineGroup.findNode("PartnerLogo")

  m.secondLineGroup = m.top.findNode("SecondLineGroup")
  m.secondLineAvailabilityBadge = m.secondLineGroup.findNode("SecondLineAvailabilityBadge")
  m.resumeProgressBar = m.secondLineGroup.findNode("ResumeProgressBar")
  m.line2 = m.secondLineGroup.findNode("Line2")

  m.descriptionGroup = m.top.findNode("DescriptionGroup")
  m.description = m.top.findNode("Description")
  m.descriptionFocusButton = m.top.findNode("DescriptionFocusButton")

  m.signInGroup = m.top.findNode("signInGroup")
  m.SignInLock = m.twoLineInfo.findNode("SignInLock")
  m.signInText = m.top.findNode("signInText")
  m.reminderGroup = m.top.findNode("ReminderGroup")
  m.reminderTitle = m.top.findNode("ReminderTitle")

  m.directorGroup = m.top.findNode("DirectorGroup")
  m.director = m.top.findNode("Director")
  m.directorTag = m.top.findNode("DirectorTag")
  DirectorRect = m.top.findNode("DirectorRect")
  m.starringGroup = m.top.findNode("StarringGroup")
  m.starring = m.top.findNode("Starring")
  m.starringTag = m.top.findNode("StarringTag")
  StarringRect = m.top.findNode("StarringRect")

  m.playerCountdownGroup = m.top.findNode("PlayerCountdownGroup")

  m.top.observeFieldScoped("mode", "onModeChange")
  m.top.observeFieldScoped("width", "onWidthChange")
  m.top.observeFieldScoped("leftHeaderImageUri", "onLeftHeaderImageUriChange")
  m.top.observeFieldScoped("description", "onDescriptionChange")
  m.top.observeFieldScoped("lineOneData", "onLineOneDataChange")
  m.top.observeFieldScoped("lineTwoData", "onLineTwoDataChange")
  m.top.observeFieldScoped("seasonEpisodeCount", "onSeasonEpisodeCountChange")
  m.top.observeFieldScoped("directors", "onDirectorsChange")
  m.top.observeFieldScoped("starring", "onStarringChange")
  m.top.observeFieldScoped("needsLogin", "onNeedsLoginChange")
  m.top.observeFieldScoped("reminderIsSet", "onReminderChange")
  m.top.observeFieldScoped("episodeTitle","onEpisodeTitleChange")
  m.top.observeFieldScoped("fullscreenCountdown", "onPlayerCountDownChange")
  m.top.observeFieldScoped("calculateHeight", "onCalculateHeight")
  m.top.observeFieldScoped("focusedChild", "onComponentFocus")
  m.offset.observeFieldScoped("translation", "onOffsetTranslationChange")
  m.partnerLogo.observeFieldScoped("loadStatus", "onPosterLoadStatus")
  m.rating.observeFieldScoped("loadStatus", "onPosterLoadStatus")
  m.closedCaptions.observeFieldScoped("loadStatus", "onPosterLoadStatus")
  m.audioDescriptionPoster.observeFieldScoped("loadStatus", "onPosterLoadStatus")
  m.resolutionPoster.observeFieldScoped("loadStatus", "onPosterLoadStatus")

  m.signInText.text = getTranslation("registration_signIn_to_play_R_rated")
  m.reminderTitle.text = getTranslation("info_panel_reminder_is_set")

  onWidthChange()

  m.starringTag.width = 0
  m.directorTag.width = 0
  m.directorTag.text = getTranslation("metadata_directed")
  m.starringTag.text = getTranslation("metadata_starring")

  '//Set a line after the directed by and starring text to be right aligned so the values associated with those lines are left aligned
  nStarringWidth = m.starringTag.boundingRect().width
  nDirectorWidth = m.directorTag.boundingRect().width
  spacerWidth = 32
  nMatchDirectorWidth = nStarringWidth - nDirectorWidth
  nMatchStarringWidth = nDirectorWidth - nStarringWidth

  if nMatchStarringWidth >= 0
    nMatchDirectorWidth = 0
  else
    nMatchStarringWidth = 0
  end if

  DirectorRect.width = nMatchDirectorWidth + spacerWidth
  StarringRect.width = nMatchStarringWidth + spacerWidth

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.title, typographyConstants.ids.headerSmall)
  setTypographyOfLabel(m.episode, typographyConstants.ids.subheaderSmall)
  setTypographyOfLabel(m.Line1, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.Line1Bold, typographyConstants.ids.subheaderSmall)
  setTypographyOfLabel(m.DescriptorCode, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.RatingLabel, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.ExpireWarning, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.Line2, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.Description, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.SignInText, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.ReminderTitle, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.DirectorTag, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.Director, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.StarringTag, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.Starring, typographyConstants.ids.bodyMedium)

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
    m.descriptionFocusButton.blendColor = theme.focusedColor
    m.expireWarning.color = theme.cautionColor
    m.SignInLock.blendColor = theme.cautionColor
    m.signInText.color = theme.cautionColor
    m.Title.color = theme.primaryTextColor
    m.RatingLabel.color = theme.primaryTextColor
    m.Description.color = theme.primaryTextColor
    m.Director.color = theme.primaryTextColor
    m.Starring.color = theme.primaryTextColor
    m.resumeProgressBar.focusColor = theme.focusedColor
    m.resumeProgressBar.trackColor = theme.neutralColor
    m.resumeProgressBar.unfocusColor = theme.focusedColor
  end if
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
  theme = getThemeFromGlobal()
  if m.top.isInFocusChain() AND  m.top.description <> invalid AND m.top.description <> ""
    m.descriptionFocusButton.visible = true
    if theme <> invalid
      m.Description.color = theme.backgroundColor
    end if
  else
    m.descriptionFocusButton.visible = false
    if theme <> invalid
      m.Description.color = theme.primaryTextColor
    end if
  end if
End Function


' Apply width to all components. Since the outer LayoutGroup has
' horizAlignment set to "custom", each child will have its translation
' field set to adjust it's x offset. We account for the x offset in
' setting each width here so that the children don't go beyond the right edge.
Function onWidthChange()
  tubiLog("InfoPanel.onWidthChange")
  topWidth = m.top.width

  if m.title.width <> 0
    '//if the title is set to 0, then we do not want to make changes to the width of the title
    m.title.width = topWidth - m.title.translation[0]
  end if

  m.episode.width = topWidth - m.episode.translation[0]
  m.line2.width = topWidth - m.twoLineInfo.translation[0]

  ' The description text needs a right margin which matches its left margin
  m.description.width = topWidth - 2 * m.description.translation[0]
  ' Reduce the director width based on "Direct by..." prefix
  directorPrefixBoundingRect = m.top.findNode("DirectorPrefix").boundingRect()
  m.director.width =topWidth - directorPrefixBoundingRect.width + m.directorGroup.itemSpacings[0] - m.directorGroup.translation[0]
  starringPrefixBoundingRect = m.top.findNode("StarringPrefix").boundingRect()
  m.starring.width = topWidth - starringPrefixBoundingRect.width + m.starringGroup.itemSpacings[0] - m.starringGroup.translation[0]
  m.descriptionFocusButton.width = topWidth + -m.descriptionGroup.translation[0]
End Function


' Needed in case the mode doesn't change but the leftHeaderImageUri does
Function onLeftHeaderImageUriChange(msg)
  tubiLog("InfoPanel.onLeftHeaderImageUriChange")
  sPosterURL = msg.getData()
  leftHeaderIsPresent = (m.leftHeaderImage.getParent() <> invalid)
  if isNonEmptyString(sPosterURL) = true
    if leftHeaderIsPresent = false
      m.infoPanelGroup.insertChild(m.leftHeaderImage, 0)
    end if

    m.leftHeaderImage.uri = sPosterURL

  else if leftHeaderIsPresent = true
    m.infoPanelGroup.removeChild(m.leftHeaderImage)
  end if
End Function


Function onEpisodeTitleChange(msg)
  tubiLog("InfoPanel.onEpisodeTitleChange")

  episodeTitle = msg.getData()
  episodeIsPresent = (m.episode.getParent() <> invalid)

  if isNonEmptyString(episodeTitle) = true
    if episodeIsPresent = false
      programEpisodeIndex = m.nodeHelpers.getChildIndex(m.offset, m.title) + 1
      m.offset.insertChild(m.episode, programEpisodeIndex)
    end if
    m.episode.text = episodeTitle
  else if episodeIsPresent = true
      m.offset.removeChild(m.episode)
  end if
End Function


Function onNeedsLoginChange(msg)
  tubiLog("InfoPanel.onNeedsLoginChange")
  needsLogin = msg.getData()
  mode = m.top.mode
  signInGroupIsPresent = (m.signInGroup.getParent() <> invalid)

  modesWithTimerAtBottom = {}
  modesWithTimerAtBottom[m.constants.ui.infoPanelModes.linearHomeScreen] = true



  if needsLogin = false AND signInGroupIsPresent = true
    m.offset.removeChild(m.signInGroup)

    ' login info overwrites countdown timer or reminder text if the user is not logged in
    ' add them back as appropriate, if login info is not necessary
    if modesWithTimerAtBottom[mode] = true
      m.offset.appendChild(m.playerCountdownGroup)
    else if m.top.reminderIsSet = true
      m.offset.appendChild(m.reminderGroup)
    end if
  else if needsLogin = true AND signInGroupIsPresent = false
    ' login info overwrites countdown timer or reminder text if the user is not logged in
    ' remove them back as appropriate, if login info is necessary
    countdownTimerPresent = (m.playerCountdownGroup.getParent() <> invalid AND modesWithTimerAtBottom[mode] = true)
    reminderPresent = (m.reminderGroup.getParent() <> invalid)

    if countdownTimerPresent = true
      m.offset.removeChild(m.playerCountdownGroup)
    else if reminderPresent = true
      m.offset.removeChild(m.reminderGroup)
    end if

    m.offset.appendChild(m.signInGroup)
  end if
End Function


Function onReminderChange(msg)
  tubiLog("InfoPanel.onReminderChange")
  isReminder = msg.getData()

  reminderIsPresent = (m.reminderGroup.getParent() <> invalid)
  if isReminder = true and reminderIsPresent = false
    m.offset.appendChild(m.reminderGroup)
  else if isReminder = false and reminderIsPresent = true
    m.offset.removeChild(m.reminderGroup)
  end if
End Function


Function onLineOneDataChange(msg)
  tubiLog("InfoPanel.onLineOneDataChange")
  data = msg.getData()

    firstLineGroup = m.firstLineGroup
    firstLineGroupIsPresent = (firstLineGroup.getParent() <> invalid)

    if isAA(data) AND data.count() > 0 AND firstLineGroupIsPresent = false
      m.twoLineInfo.insertChild(firstLineGroup, 0)
    else if (isAA(data) = false OR data.count() = 0) AND firstLineGroupIsPresent = true
      m.twoLineInfo.removeChild(firstLineGroup)
    end if

    if isAA(data)
      insertIndex = 0

      ' handle availability badge
      availabilityBadgeIsPresent = (m.firstLineAvailabilityBadge.getParent() <> invalid)
      if isNonEmptyString(data.badgeText)
        if availabilityBadgeIsPresent = false
          firstLineGroup.insertChild(m.firstLineAvailabilityBadge, insertIndex)
        end if

        formatBadge(data.badgeText, m.firstLineAvailabilityBadge)
        insertIndex++
      else
        if availabilityBadgeIsPresent = true
          firstLineGroup.removeChild(m.firstLineAvailabilityBadge)
        end if
      end if

      ' handle text
      text = ""

      if isNonEmptyString(data.timeLeft)
        text = data.timeLeft + " "
      end if

      ' expect that data.releaseDate and data.hoursOfAiring are mutually exclusive
      if isNonEmptyString(data.releaseDate)
        ' add 'dot' spacer only if we had a timeLeft & releaseDate
        if text.len() > 0
          text += Chr(&hb7) + " "
        end if
        text += data.releaseDate + " "
      else if isNonEmptyString(data.hoursOfAiring) = true
        ' add 'dot' spacer only if we had a timeLeft & hoursOfAiring
        if text.len() > 0
          text += Chr(&hb7) + " "
        end if
        text += data.hoursOfAiring + " "
      end if

      if data.length <> invalid AND data.length <> 0
        ' add 'dot' spacer only if we had a timeLeft/releaseDate/hoursOfAiring
        if text.len() > 0
          text += Chr(&hb7) + " "
        end if

        text += formatLengthSelectedLocale(data.length) + " "
      end if

      if data.programLength <> invalid AND data.programLength <> ""
        ' add 'dot' spacer only if we had a timeLeft/releaseDate/hoursOfAiring
        if text.len() > 0
          text += Chr(&hb7) + " "
        end if

        text += data.programLength + " "

      end if

      if data.type <> invalid AND data.type = m.constants.ui.contentTypes.series
        ' add 'dot' spacer
        text += Chr(&hb7) + " "

        if data.seasons <> invalid AND data.seasons > 0
          if data.seasons = 1
            text += getTranslation("metadata_seasons_singular") + " "
          else
            text += getTranslation("metadata_seasons_plural", {seasons: data.seasons.toStr()}) + " "
          end if
        else
          text += getTranslation("metadata_series") + " "
        end if
      end if

      line1IsPresent = (m.line1.getParent() <> invalid)
      line1BoldIsPresent = (m.line1Bold.getParent() <> invalid)
      textIsPresent = (line1IsPresent = true OR line1BoldIsPresent = true)

      if isNonEmptyString(text)
        if textIsPresent = false
          mode = m.top.mode
          if mode = m.constants.ui.infoPanelModes.sportsEvent
            firstLineGroup.insertChild(m.line1Bold, insertIndex)
          else
            firstLineGroup.insertChild(m.line1, insertIndex)
          end if
        end if

        m.line1Bold.text = text
        m.line1.text = text
        insertIndex++
      else
        if textIsPresent = true
          firstLineGroup.removeChild(m.line1)
          firstLineGroup.removeChild(m.line1Bold)
        end if
      end if

      ' handle resolution poster (4k)
      resolutionPosterIsPresent = (m.resolutionPoster.getParent() <> invalid)
      if data.has4k = true
        if resolutionPosterIsPresent = false
          firstLineGroup.insertChild(m.resolutionPoster, insertIndex)
        end if

        insertIndex++
        ' Although this uri does not change, if it is set in the component XML, the icon will appear
        ' during the initial channel load, so set it dynamically when it should appear
        m.resolutionPoster.uri = "pkg:/images/icon-4k-ready-badge.webp"
      else
        if resolutionPosterIsPresent = true
          firstLineGroup.removeChild(m.resolutionPoster)
        end if
      end if

      ' handle closed captions
      closedCaptionsIsPresent = (m.closedCaptions.getParent() <> invalid)
      if data.hasCC = true
        if closedCaptionsIsPresent = false
          firstLineGroup.insertChild(m.closedCaptions, insertIndex)
        end if

        insertIndex++
        ' Although this uri does not change, if it is set in the component XML, the icon will appear
        ' during the initial channel load, so set it dynamically when it should appear
        m.closedCaptions.uri = "pkg:/images/icon-closed-caption.webp"
      else
        if closedCaptionsIsPresent = true
          firstLineGroup.removeChild(m.closedCaptions)
        end if
      end if

      ' handle audio description
      audioDescriptionIsPresent = (m.audioDescriptionPoster.getParent() <> invalid)
      if data.hasAudioDescription = true
        if audioDescriptionIsPresent = false
          firstLineGroup.insertChild(m.audioDescriptionPoster, insertIndex)
        end if

        insertIndex++
      else
        if audioDescriptionIsPresent = true
          firstLineGroup.removeChild(m.audioDescriptionPoster)
        end if
      end if

      ' handle rating
      ratingIsPresent = (m.rating.getParent() <> invalid)
      if isNonEmptyString(data.rating) = true AND m.top.mode <> m.constants.ui.infoPanelModes.sportsEvent
        if ratingIsPresent = false
          firstLineGroup.insertChild(m.rating, insertIndex)
        end if

        m.ratingLabel.width = 0
        m.ratingLabel.text = Ucase(data.rating)

        nRatingBoundingBoxIncrease = m.ratingLabel.boundingRect().width + 24
        m.ratingBackground.width = nRatingBoundingBoxIncrease
        m.ratingLabel.width = nRatingBoundingBoxIncrease
        insertIndex++
      else
        if ratingIsPresent = true
          firstLineGroup.removeChild(m.rating)
        end if
      end if

      ' handle descriptor codes
      descriptorsArePresent = (m.descriptorCode.getParent() <> invalid)
      if isNonEmptyString(data.descriptorCode)
        if descriptorsArePresent = false
          firstLineGroup.insertChild(m.descriptorCode, insertIndex)
        end if

        m.descriptorCode.text = UCase(data.descriptorCode)
        insertIndex++
      else
        if descriptorsArePresent = true
          firstLineGroup.removeChild(m.descriptorCode)
        end if
      end if

      ' handle expiration warning
      expirationWarningPresent = (m.expireWarning.getParent() <> invalid)
      if isNonEmptyString(data.availabilityEnds)
        datetime = CreateObject("roDateTime")
        datetime.FromISO8601String(data.availabilityEnds)
        endSeconds = datetime.AsSeconds()
        nowSeconds = CreateObject("roDateTime").AsSeconds()
        daysRemaining = ((endSeconds - nowSeconds) \ 86400) + 1
        ' BIZ REQ: only titles expiring in the next 2 weeks should display message
        if daysRemaining > 0 AND daysRemaining <= 14
          if daysRemaining > 1
            m.expireWarning.text = getTranslation("metadata_expiresIn_plural", {days: daysRemaining.toStr()})
          else
            m.expireWarning.text = getTranslation("metadata_expiresIn_singular")
          end if

          if expirationWarningPresent = false
            firstLineGroup.insertChild(m.expireWarning, insertIndex)
          end if

          insertIndex++
        else if expirationWarningPresent = true
          firstLineGroup.removeChild(m.expireWarning)
        end if
      else if isNonEmptyString(data.programTimeLeft) = true
        m.expireWarning.text = data.programTimeLeft

        if expirationWarningPresent = false
          firstLineGroup.insertChild(m.expireWarning, insertIndex)
        end if

        insertIndex++

      else if expirationWarningPresent = true
        firstLineGroup.removeChild(m.expireWarning)
      end if

      ' handle parter logos
      partnerLogoIsPresent = (m.partnerLogo.getParent() <> invalid)
      if isNonEmptyString(data.partnerLogoUri)
        if partnerLogoIsPresent = false
          firstLineGroup.insertChild(m.partnerLogo, insertIndex)
        end if

        m.partnerLogo.uri = data.partnerLogoUri
        insertIndex++
      else
        if partnerLogoIsPresent = true
          firstLineGroup.removeChild(m.partnerLogo)
        end if
      end if
    end if
End Function


Function onLineTwoDataChange(msg)
  tubiLog("InfoPanel.onLineTwoDataChange")
  data = msg.getData()
  secondLineGroup = m.firstLineGroup
  secondLineGroupIsPresent = (secondLineGroup.getParent() <> invalid)

  if isAA(data) AND data.count() > 0 AND secondLineGroupIsPresent = false
    m.twoLineInfo.appendChild(secondLineGroup)
  else if (isAA(data) = false OR data.count() = 0) AND secondLineGroupIsPresent = true
    m.twoLineInfo.removeChild(secondLineGroup)
  end if

  if isAA(data) = true
    insertIndex = 0

    ' handle availability badge
    availabilityBadgeIsPresent = (m.secondLineAvailabilityBadge.getParent() <> invalid)
    if isNonEmptyString(data.badgeText)
      if availabilityBadgeIsPresent = false
        secondLineGroup.insertChild(m.secondLineAvailabilityBadge, insertIndex)
      end if

      formatBadge(data.badgeText, m.secondLineAvailabilityBadge)
      insertIndex++
    else
      if availabilityBadgeIsPresent = true
        secondLineGroup.removeChild(m.secondLineAvailabilityBadge)
      end if
    end if

    ' handle 2nd line text
    text = getSecondLineText(data)
    line2IsPresent = (m.line2.getParent() <> invalid)

    if isNonEmptyString(text) = true
      if line2IsPresent = false
        secondLineGroup.insertChild(m.line2, insertIndex)
      end if

      m.line2.text = text
      insertIndex++
    else
      if line2IsPresent = true
        m.line2.text = ""
        secondLineGroup.removeChild(m.line2)
      end if
    end if

    progressBarIsPresent = m.resumeProgressBar.getParent() <> invalid

    if data.displayProgressBar = true

      if progressBarIsPresent = false
        secondLineGroup.insertChild(m.resumeProgressBar, insertIndex)
      end if

      m.resumeProgressBar.progress = data.progressPercent
    else

      if progressBarIsPresent = true
        m.resumeProgressBar.progress = 0
        secondLineGroup.removeChild(m.resumeProgressBar)
      end if

    end if
  end if
End Function


Function onDescriptionChange(msg)
  tubiLog("InfoPanel.onDescriptionChange")
  description = msg.getData()
  if isNonEmptyString(description) = true
    m.description.visible = true
    m.description.height = 0  ' reset for calculations below
    m.description.text = description
  else
    m.description.visible = false
  end if
End Function


Function onDirectorsChange(msg)
  tubiLog("InfoPanel.onDirectorChange")
  directors = msg.getData()
  text = ""
  if isNonEmptyArray(directors) = true
    text = directors.Join(", ")
  end if

  if text = ""
    ' hide the whole group if no directors listed
    m.directorGroup.visible = false
  else if m.directorGroup.visible = false
    m.directorGroup.visible = true
  end if

  m.director.text = text
End Function


Function onStarringChange(msg)
  tubiLog("InfoPanel.onStarringChange")
  starring = msg.getData()
  text = ""
  if isArray(starring) AND starring.count() > 0
    text = starring.Join(", ")
  end if

  if text = invalid or text = ""
    ' hide the whole group if no actors/starring listed
    m.starringGroup.visible = false
  else
    m.starringGroup.visible = true
  end if

  m.starring.text = text
End Function


Function onSeasonEpisodeCountChange(msg)
  tubiLog("InfoPanel.onSeasonEpisodeCountChange")
  seasonEpisodeCount = msg.getData()
  if seasonEpisodeCount > 0
    m.line2.text = stri(seasonEpisodeCount).trim() + " episodes"
  else
    m.line2.text = ""
  end if
End Function


Function onPlayerCountDownChange()
  tubiLog("InfoPanel.onPlayerCountDownChange")
  if m.top.fullscreenCountdown >= 0
    m.playerCountdownGroup.display = true
    m.playerCountdownGroup.seconds = m.top.fullscreenCountdown
  else
    m.playerCountdownGroup.display = false
  end if
End Function


Function onOffsetTranslationChange(msg)
  leftHeaderIsPresent = (m.leftHeaderImage.getParent() <> invalid)
  if leftHeaderIsPresent = false then
    ' We are using custom x translation for offset LayoutGroup. We use a negative value on DescriptionGroup which shifts over infoPanelGroup that much to the right to compensate. This code below counteracts that change. We only want to do that if leftHeaderImage isn't present though
    offsetTranslation = msg.getData()
    translation = m.infoPanelGroup.translation
    translation[0] = offsetTranslation[0] * -1
    m.infoPanelGroup.translation = translation
  end if
End Function


Function onCalculateHeight()
  tubiLog("InfoPanel.onCalculateHeight")
  topMargin = 15
  bottomMargin = 8
  descriptionBoundingHeight = m.description.boundingRect().height
  m.descriptionFocusButton.height = descriptionBoundingHeight + topMargin + bottomMargin

  ' try to shorten description to fit max height
  offsetBoundingHeight = m.offset.BoundingRect().height
  if m.top.maxHeight <> 0 AND m.top.maxHeight < offsetBoundingHeight
    m.description.height = descriptionBoundingHeight - (offsetBoundingHeight - m.top.maxHeight)
    if m.description.height <= 0
      m.description.text = ""
    end if

    updatedDescriptionBoundingHeight = m.description.boundingRect().height
    m.descriptionFocusButton.height = updatedDescriptionBoundingHeight + topMargin + bottomMargin
  end if

End Function


Function resetDefaultState()
  infoPanelGroupChildrenCount = m.infoPanelGroup.getChildCount()
  m.infoPanelGroup.removeChildrenIndex(infoPanelGroupChildrenCount, 0)

  offsetChildrenCount = m.offset.getChildCount()
  m.offset.removeChildrenIndex(offsetChildrenCount, 0)

  twoLineInfoChildrenCount = m.twoLineInfo.getChildCount()
  m.twoLineInfo.removeChildrenIndex(twoLineInfoChildrenCount, 0)

  firstLineGroupChildrenCount = m.firstLineGroup.getChildCount()
  m.firstLineGroup.removeChildrenIndex(firstLineGroupChildrenCount, 0)

  secondLineGroupChildrenCount = m.secondLineGroup.getChildCount()
  m.secondLineGroup.removeChildrenIndex(secondLineGroupChildrenCount, 0)

  'm.playerCountdownGroup has been added to parent to accommodate EPG Screen design
  if m.playerCountdownGroup <> invalid
    m.top.removeChild(m.playerCountdownGroup)
  end if

  ' reset any boolean INPUT state fields m.top
  m.top.needsLogin = false
  m.top.reminderIsSet = false

  if m.topHeaderImage <> invalid
    m.topHeaderImage.height = 0
    m.topHeaderImage.width = 0
  end if

  m.top.descriptionMaxLines = 5
End Function


'''''''''''''''''''
' onModeChange
'
' Make various fields visible or invisible by removing them from
' the children for rendering
Function onModeChange()
  tubiLog("InfoPanel.onModeChange")
  resetDefaultState()
  if m.top.mode = m.constants.ui.infoPanelModes.item
    ' used for movies and series on the homescreen and similar screens
    m.infoPanelGroup.appendChild(m.offset)
    m.offset.appendChild(m.title)
    m.offset.appendChild(m.twoLineInfo)
    m.offset.appendChild(m.descriptionGroup)
    m.offset.itemSpacings = [24, 15]

    m.twoLineInfo.appendChild(m.firstLineGroup)
    m.firstLineGroup.appendChild(m.firstLineAvailabilityBadge)
    m.firstLineGroup.appendChild(m.line1)
    m.firstLineGroup.appendChild(m.resolutionPoster)
    m.firstLineGroup.appendChild(m.closedCaptionPoster)
    m.firstLineGroup.appendChild(m.audioDescriptionPoster)
    m.firstLineGroup.appendChild(m.rating)
    m.firstLineGroup.appendChild(m.descriptorCode)
    m.firstLineGroup.appendChild(m.expireWarning)
    m.firstLineGroup.appendChild(m.partnerLogo)

    m.twoLineInfo.appendChild(m.secondLineGroup)
    m.secondLineGroup.appendChild(m.line2)
  else if m.top.mode = m.constants.ui.infoPanelModes.movie
    ' used for movies on the details screen
    m.infoPanelGroup.appendChild(m.offset)
    m.offset.appendChild(m.title)
    m.offset.appendChild(m.twoLineInfo)
    m.offset.appendChild(m.descriptionGroup)
    m.offset.appendChild(m.starringGroup)
    m.offset.appendChild(m.directorGroup)

    m.twoLineInfo.appendChild(m.firstLineGroup)
    m.firstLineGroup.appendChild(m.firstLineAvailabilityBadge)
    m.firstLineGroup.appendChild(m.line1)
    m.firstLineGroup.appendChild(m.resolutionPoster)
    m.firstLineGroup.appendChild(m.closedCaptionPoster)
    m.firstLineGroup.appendChild(m.audioDescriptionPoster)
    m.firstLineGroup.appendChild(m.rating)
    m.firstLineGroup.appendChild(m.descriptorCode)
    m.firstLineGroup.appendChild(m.expireWarning)
    m.firstLineGroup.appendChild(m.partnerLogo)

    m.twoLineInfo.appendChild(m.secondLineGroup)
    m.secondLineGroup.appendChild(m.line2)

    m.offset.itemSpacings = [24, 15, 18, 12]
  else if m.top.mode = m.constants.ui.infoPanelModes.series
    ' used for episodes/series on the details screen
    m.infoPanelGroup.appendChild(m.offset)
    m.offset.appendChild(m.title)
    m.offset.appendChild(m.episode)
    m.offset.appendChild(m.twoLineInfo)
    m.offset.appendChild(m.descriptionGroup)
    m.offset.appendChild(m.starringGroup)
    m.offset.appendChild(m.directorGroup)

    m.twoLineInfo.appendChild(m.firstLineGroup)
    m.firstLineGroup.appendChild(m.firstLineAvailabilityBadge)
    m.firstLineGroup.appendChild(m.line1)
    m.firstLineGroup.appendChild(m.resolutionPoster)
    m.firstLineGroup.appendChild(m.closedCaptionPoster)
    m.firstLineGroup.appendChild(m.audioDescriptionPoster)
    m.firstLineGroup.appendChild(m.rating)
    m.firstLineGroup.appendChild(m.descriptorCode)
    m.firstLineGroup.appendChild(m.expireWarning)
    m.firstLineGroup.appendChild(m.partnerLogo)

    m.twoLineInfo.appendChild(m.secondLineGroup)
    m.secondLineGroup.appendChild(m.line2)

    m.offset.itemSpacings = [24, 24, 15, 18, 12]
  else if m.top.mode = m.constants.ui.infoPanelModes.episode
    ' used for episodes on the episode list screen
    m.infoPanelGroup.appendChild(m.offset)
    m.offset.appendChild(m.title)
    m.offset.appendChild(m.episode)
    m.offset.appendChild(m.twoLineInfo)
    m.offset.appendChild(m.descriptionGroup)

    m.twoLineInfo.appendChild(m.firstLineGroup)
    m.firstLineGroup.appendChild(m.firstLineAvailabilityBadge)
    m.firstLineGroup.appendChild(m.line1)
    m.firstLineGroup.appendChild(m.resolutionPoster)
    m.firstLineGroup.appendChild(m.closedCaptionPoster)
    m.firstLineGroup.appendChild(m.audioDescriptionPoster)
    m.firstLineGroup.appendChild(m.rating)
    m.firstLineGroup.appendChild(m.descriptorCode)
    m.firstLineGroup.appendChild(m.expireWarning)
    m.firstLineGroup.appendChild(m.partnerLogo)

    m.twoLineInfo.appendChild(m.secondLineGroup)
    m.secondLineGroup.appendChild(m.line2)
    m.offset.itemSpacings = [24, 24, 15, 18]
  else if m.top.mode = m.constants.ui.infoPanelModes.season
    ' used when the side nav season item is focused on the episode list screen
    m.infoPanelGroup.appendChild(m.offset)
    m.offset.appendChild(m.title)
    m.offset.appendChild(m.twoLineInfo)
    m.offset.appendChild(m.descriptionGroup)

    m.twoLineInfo.appendChild(m.secondLineGroup)
    m.secondLineGroup.appendChild(m.line2)

    m.offset.itemSpacings = [24, 24]
  else if m.top.mode = m.constants.ui.infoPanelModes.continueWatching 'guest User
    ' used for guest user continue watching row on the home screen
    m.infoPanelGroup.appendChild(m.offset)
    m.offset.appendChild(m.title)
    m.offset.appendChild(m.descriptionGroup)
    m.offset.itemSpacings = [15]

  else if m.top.mode = m.constants.ui.infoPanelModes.CWSignedInUser
    m.infoPanelGroup.appendChild(m.offset)
    m.offset.appendChild(m.title)
    m.offset.appendChild(m.twoLineInfo)
    m.twoLineInfo.appendChild(m.firstLineGroup)
    m.firstLineGroup.appendChild(m.line1)
    m.twoLineInfo.appendChild(m.secondLineGroup)
    m.secondLineGroup.appendChild(m.resumeProgressBar)
    m.offset.appendChild(m.descriptionGroup)
  else if m.top.mode = m.constants.ui.infoPanelModes.linearHomeScreen
    '//For when the linear player is on the home screen
    m.infoPanelGroup.appendChild(m.offset)
    m.offset.appendChild(m.liveBadgeHeader)
    m.offset.appendChild(m.title)
    m.offset.appendChild(m.descriptionGroup)
    m.offset.appendChild(m.playerCountdownGroup)
    m.offset.itemSpacings = [24, 15]
  else if m.top.mode = m.constants.ui.infoPanelModes.epg
    '//For when the linear player is on its own EPG screen
    m.infoPanelGroup.appendChild(m.leftHeaderImage)
    m.infoPanelGroup.appendChild(m.offset)
    m.offset.appendChild(m.title)
    m.offset.appendChild(m.twoLineInfo)
    m.offset.appendChild(m.descriptionGroup)

    m.twoLineInfo.appendChild(m.firstLineGroup)
    m.firstLineGroup.appendChild(m.line1)
    m.firstLineGroup.appendChild(m.resolutionPoster)
    m.firstLineGroup.appendChild(m.closedCaptionPoster)
    m.firstLineGroup.appendChild(m.audioDescriptionPoster)
    m.firstLineGroup.appendChild(m.rating)
    m.firstLineGroup.appendChild(m.descriptorCode)

    m.offset.itemSpacings = [15, 15]
    m.top.appendChild(m.playerCountdownGroup)
    m.playerCountdownGroup.translation = [1215, -111]
  else if m.top.mode = m.constants.ui.infoPanelModes.simplifiedLinearPlayer
    '//For when the linear player is on its own EPG screen
    m.infoPanelGroup.appendChild(m.offset)
    m.offset.appendChild(m.title)
    m.offset.appendChild(m.twoLineInfo)
    m.offset.appendChild(m.descriptionGroup)

    m.twoLineInfo.appendChild(m.firstLineGroup)
    m.firstLineGroup.appendChild(m.line1)
    m.firstLineGroup.appendChild(m.resolutionPoster)
    m.firstLineGroup.appendChild(m.closedCaptionPoster)
    m.firstLineGroup.appendChild(m.audioDescriptionPoster)
    m.firstLineGroup.appendChild(m.rating)
    m.firstLineGroup.appendChild(m.descriptorCode)

    m.offset.itemSpacings = [15, 15]
    m.top.appendChild(m.playerCountdownGroup)
    m.playerCountdownGroup.translation = [1216, -78]
  else if m.top.mode = m.constants.ui.infoPanelModes.linearSearch
    ' when linear content is focused on the search screen
    m.infoPanelGroup.appendChild(m.offset)
    m.offset.appendChild(m.title)
    m.offset.appendChild(m.twoLineInfo)
    m.offset.appendChild(m.descriptionGroup)

    m.twoLineInfo.appendChild(m.secondLineGroup)
    m.secondLineGroup.appendChild(m.secondLineAvailabilityBadge)
    m.secondLineGroup.appendChild(m.line2)

    m.offset.itemSpacings = [24, 15]
  else if m.top.mode = m.constants.ui.infoPanelModes.sportsEvent
    m.infoPanelGroup.appendChild(m.offset)
    m.offset.appendChild(m.title)
    m.offset.appendChild(m.twoLineInfo)

    m.twoLineInfo.appendChild(m.firstLineGroup)
    m.firstLineGroup.appendChild(m.firstLineAvailabilityBadge)
    m.firstLineGroup.appendChild(m.line1Bold)
    m.firstLineGroup.appendChild(m.resolutionPoster)
    m.firstLineGroup.appendChild(m.closedCaptionPoster)
    m.firstLineGroup.appendChild(m.audioDescriptionPoster)

    m.twoLineInfo.appendChild(m.secondLineGroup)
    m.secondLineGroup.appendChild(m.line2)

    m.offset.itemSpacings = [15]
  else if m.top.mode = m.constants.ui.infoPanelModes.linearProgramHomescreen
    ' This infopanel mode is for linear programs in response with V4 api (treament group of roku_sports_onnow_rows_v2)
    m.infoPanelGroup.appendChild(m.offset)
    m.offset.appendChild(m.title)

    if isNonEmptyString(m.episode.text)
      m.offset.appendChild(m.episode)
    end if

    m.offset.appendChild(m.twoLineInfo)

    m.twoLineInfo.appendChild(m.firstLineGroup)
    m.firstLineGroup.appendChild(m.line1)

    m.twoLineInfo.appendChild(m.secondLineGroup)
    m.secondLineGroup.appendChild(m.line2)

    m.offset.appendChild(m.descriptionGroup)
    m.offset.itemSpacings = [15, 15]
  else if m.top.mode = m.constants.ui.infoPanelModes.programHomescreen
    ' This infopanel mode is for linear channel/program in response with V3 api (control group of roku_sports_onnow_rows_v2)
    m.infoPanelGroup.appendChild(m.offset)
    m.offset.appendChild(m.topHeaderImage)
    m.topHeaderImage.height = 72
    m.topHeaderImage.width = 72
    m.offset.appendChild(m.title)

    if isNonEmptyString(m.episode.text)
      m.offset.appendChild(m.episode)
    end if
    m.offset.appendChild(m.twoLineInfo)

    m.twoLineInfo.appendChild(m.firstLineGroup)
    m.firstLineGroup.appendChild(m.line1Bold)
    m.firstLineGroup.appendChild(m.closedCaptionPoster)
    m.firstLineGroup.appendChild(m.audioDescriptionPoster)

    m.offset.appendChild(m.descriptionGroup)
    m.offset.appendChild(m.playerCountdownGroup)
    m.offset.itemSpacings = [15, 15]
  end if
End Function


' @data: assocArray, that matches form of m.top.lineTwoData
Function getSecondLineText(data)
  ' handle genres
  text = ""
  genres = data.genres
  if isNonEmptyArray(genres) = true
    capitalGenres = []
    for each genre in genres
      capitalGenres.push(capitalize(genre))
    end for
    text = capitalGenres.Join(", ")
  end if

  ' handle sports event round/group info
  roundGroupInfo = data.roundGroupInfo
  if isNonEmptyString(roundGroupInfo) = true

    if text.len() > 0
      text += " " + Chr(&hb7) + " "
    end if

    text += roundGroupInfo
  end if

  if isString(data.channelName)
    if text.len() > 0
      text += " " + Chr(&hb7) + " "
    end if

    text +=  data.channelName
  end if

  return text
End Function


' @text: string, the translated text that will appear on the badge
' @badgeComponent: a Badge node
Function formatBadge(text, badgeComponent)
  tubiLog("InfoPanel.formatBadge")
  theme = getThemeFromGlobal()
  if theme <> invalid
    if UCase(text) = UCase(getTranslation("screenSearch_liveText"))
      ' LIVE badge
      badgeComponent.backgroundColor = theme.focused2Color
      badgeComponent.textColor = theme.primaryTextColor
      badgeComponent.iconUri = "pkg:/images/live-icon-filled.webp"
    else if UCase(text) = UCase(getTranslation("replay"))
      ' REPLAY badge
      badgeComponent.backgroundColor = theme.backgroundColorLight
      badgeComponent.textColor = theme.textDarkColor
    else
      ' TODAY, TOMORROW, <<Date>> badge
      badgeComponent.backgroundColor = theme.neutralColor
      badgeComponent.textColor = theme.primaryTextColor
    end if
  end if

  badgeComponent.text = UCase(text)
End Function


Function onKeyEvent(key, press) as Boolean
  if press AND key = "OK"
    m.top.descriptionSelected = true
    return true
  end if

  return false
End Function
