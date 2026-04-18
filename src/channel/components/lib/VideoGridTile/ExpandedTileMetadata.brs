' Initializes the component and caches node references
' Sets up observers for content changes, theme changes, and width changes
' Initializes typography constants and experiment variants
Function init()
  m.nodeHelpers = TubiNodeHelpers()

  m.metadataGroup = m.top.findNode("metadataGroup")
  m.constants = getConstantsFromGlobal()
  m.channelLogo = m.top.findNode("channelLogo")
  m.firstLineGroup = m.top.findNode("firstLineGroup")
  m.secondLineGroup = m.top.findNode("secondLineGroup")
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
  m.top.observeFieldScoped("currentEpisode", "onCurrentEpisodeChange")
  m.top.observeFieldScoped("hideTitle", "onHideTitleChange")
  m.top.observeFieldScoped("width", "onWidthChange")

  typographyConstants = getTypographyConstants()
  m.bodyMediumFont = typographyConstants.ids.bodyMedium
  m.bodySmallFont = typographyConstants.ids.bodySmall
  m.headerSmallFont = typographyConstants.ids.headerSmall
  m.headerMediumFont = typographyConstants.ids.headerMedium
  m.bodyExtraSmallStrongFont = typographyConstants.ids.bodyExtraSmallStrong
  m.bodySmallStrong = typographyConstants.ids.bodySmallStrong
  m.bodyMediumStrongFont = typographyConstants.ids.bodyMediumStrong
  m.subheaderSmallFont = typographyConstants.ids.subheaderSmall

  m.title = invalid
  m.currentEpisodeTitleLabel = invalid
  setTypographyOfLabel(m.description, m.bodyMediumFont)
  setTypographyOfLabel(m.ratingLabel, m.bodyExtraSmallStrongFont)

  m.description.observeFieldScoped("isTextEllipsized", "onIsTextEllipsizedChange")

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


' Handles theme changes and applies color values to UI elements
' @param msg - Optional message containing theme data
Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.primaryTextColor = theme.primaryTextColor
    m.secondaryTextColor = theme.secondaryTextColor
    m.ratingLabel.color = theme.secondaryTextColor
    m.description.color = m.primaryTextColor
    m.focusedTextColor = theme.focusedTextColor
    m.shadeColor = theme.shadeColor
    m.backgroundColor = theme.shadeColor

    m.progressBar.focusColor = theme.focusedColor
    m.progressBar.trackColor = theme.neutralColor
    m.progressBar.unfocusColor = theme.focusedColor
    m.ratingBackground.blendColor = theme.tertiaryTextColor

    if m.title <> invalid
      m.title.color = m.primaryTextColor
    end if
    if m.currentEpisodeTitleLabel <> invalid
      m.currentEpisodeTitleLabel.color = m.primaryTextColor
    end if
  end if
End Function


' Sets the thumbnail image for sports events and linear content
' Shows channel logo if applicable, removes it otherwise
' @param thumbnailUri - String, URI of the thumbnail image
' @param contentType - String, type of content
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


' Handles item content changes and populates metadata based on content type
' Clears existing SOT badges and rebuilds metadata display
' Routes to appropriate metadata rendering function based on content category
' @param msg - Message containing the content node data
Function onItemContentChange(msg) as Void
  itemContent = msg.getData()
  if itemContent = invalid then return

  cleanupMetadata()
  setupTitleAndConfig(itemContent)
  routeContentDisplay(itemContent)
  handleSOTBadgesAndLayout(itemContent)

End Function


' Cleans up existing metadata elements before displaying new content
Function cleanupMetadata() as Void
  m.nodeHelpers.removeAllChildren(m.sotTopLabelGroup)
  m.metadataGroup.removeChild(m.sotTopLabelGroup)
  m.nodeHelpers.removeAllChildren(m.subHeadlinePrefixGroup)
  m.nodeHelpers.removeAllChildren(m.subHeadlineSuffixGroup)

  if m.secondLineGroup <> invalid
    clearSOTBadges(m.secondLineGroup)
  end if

  if m.audioDescriptionPoster <> invalid
    m.firstLineGroup.removeChild(m.audioDescriptionPoster)
    m.audioDescriptionPoster = invalid
  end if

  if m.sotMarker <> invalid
    m.metadataGroup.removeChild(m.sotMarker)
  end if

  if m.ratingDescriptorBadges <> invalid
    for each badge in m.ratingDescriptorBadges
      m.firstLineGroup.removeChild(badge)
    end for
    m.ratingDescriptorBadges = invalid
  end if

  removeCurrentEpisodeTitleLabel()

End Function


' Sets up title and initial configuration based on component variant
' @param itemContent - Content node with title and metadata
Function setupTitleAndConfig(itemContent) as Void
  if m.top.variant = "detailScreenInfoPanel"
    m.metadataGroup.itemSpacings = [15]
  else
    m.metadataGroup.itemSpacings = [9]
  end if

  variant = m.top.variant
  if (variant = "portraitWithMetadata" OR variant = "detailScreenInfoPanel") AND m.title = invalid
    appendTitleToMetadataGroup()
  end if

  ' Resetting the visibility of the rating and sot badge.
  m.rating.visible = true
  m.sotBadge.visible = true
  onWidthChange()

  if m.title <> invalid
    m.title.text = itemContent.title
  end if
End Function


' Routes content display to appropriate metadata function based on content type
' @param itemContent - Content node to display
Function routeContentDisplay(itemContent) as Void
  if itemContent.type = m.constants.ui.contentTypes.linear
    setThumbnailImage(itemContent.thumbnailUri, itemContent.type)
    currentProgram = getCurrentLiveProgram(itemContent)
    if currentProgram <> invalid
      metadataOnLivePosterContent(currentProgram)

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
      history = getHistory(itemContent.id)

      if history <> invalid
        metadataOnContinueWatchingContent(itemContent)
      else
        metadataOnPosterContent(itemContent)
      end if
    else
      metadataOnPosterContent(itemContent)
    end if
  end if
End Function


' Handles SOT badges and metadata height adjustments for control variant
' @param itemContent - Content node with SOT information
Function handleSOTBadgesAndLayout(itemContent) as Void
  badgeTextFont = m.bodySmallFont
  textColor = m.primaryTextColor
  markerTextColor = m.primaryTextColor
  backgroundUri = "pkg:/images/rounded-background-$$RES$$.9.png"
  markerFont = m.bodySmallStrong
  translation = [15, 15]


  if m.top.variant = "detailScreenInfoPanel"
    config = {
      focusedTextColor: m.focusedTextColor
      textColor: textColor
      maxWidth: m.top.width - 12
      badgeTextFont: badgeTextFont
      translation: translation
      markerFont: markerFont
      markerTextColor: markerTextColor
      backgroundUri: backgroundUri
    }

    '// Add Coming Soon label (if applicable) to sotInfo for badge creation
    sotInfo = itemContent.sotInfo
    if isComingSoonContent(itemContent) = true
      startDateTime = CreateObject("roDateTime")
      startDateTime.FromISO8601String(itemContent.availabilityStarts)
      startDateTime.ToLocalTime()

      month = startDateTime.GetMonth()
      day = startDateTime.GetDayOfMonth().toStr()
      sComingSoonDate = getTranslation("short_version_date_wo_year_format_" + month.toStr(), { day: day })
      sComingSoonText = getTranslation("info_panel_coming_soon", { date: sComingSoonDate })

      sotComingSoon = {}
      sotComingSoon.sotLabelText = sComingSoonText
      sotComingSoon.sotIcon = ""

      ' Create a deep copy of sotInfo to avoid mutating original content node data
      modifiedSotInfo = {}
      if isNonEmptyAA(sotInfo) = true
        modifiedSotInfo.append(sotInfo)
      end if

      ' Add coming soon label to the beginning of sotMetaDataTopLabels or sotMetaData
      ' Deep copy arrays before mutation to avoid modifying original content node
      if isNonEmptyAA(sotInfo) = true AND isNonEmptyArray(sotInfo.sotMetaDataTopLabels) = true
        copiedTopLabels = []
        copiedTopLabels.append(sotInfo.sotMetaDataTopLabels)
        copiedTopLabels.unshift(sotComingSoon)
        modifiedSotInfo.sotMetaDataTopLabels = copiedTopLabels
      else if isNonEmptyAA(sotInfo) = true AND isNonEmptyArray(sotInfo.sotMetaData) = true
        copiedMetaData = []
        copiedMetaData.append(sotInfo.sotMetaData)
        copiedMetaData.unshift(sotComingSoon)
        modifiedSotInfo.sotMetaData = copiedMetaData
      else
        modifiedSotInfo.sotMetaDataTopLabels = [sotComingSoon]
      end if

      sotInfo = modifiedSotInfo
    end if

    sotBadges = createSOTBadges(sotInfo, config)

    marker = sotBadges.marker
    ' Insert sotMarker below the title if title exists
    if m.title <> invalid AND marker <> invalid
      titleIndex = m.nodeHelpers.getChildIndex(m.metadataGroup, m.title)
      if titleIndex <> -1
        showMarkerLabels(m.metadataGroup, marker, titleIndex + 1)
      else
        showMarkerLabels(m.metadataGroup, marker, 0)
      end if
    else if marker <> invalid
      showMarkerLabels(m.metadataGroup, marker, 0)
    end if


    ' Clear and prepare secondLineGroup
    if m.secondLineGroup <> invalid
      clearSOTBadges(m.secondLineGroup)
      if m.secondLineGroup.getParent() <> invalid
        m.metadataGroup.removeChild(m.secondLineGroup)
      end if
    end if

    topLabels = sotBadges.topLabels
    metaDataLabels = sotBadges.metaDataLabels

    ' Add secondLineGroup if we have labels to display
    if m.secondLineGroup <> invalid AND (isNonEmptyArray(topLabels) = true OR isNonEmptyArray(metaDataLabels) = true)
      ' Calculate insert position: after firstLineGroup for series, before description otherwise
      insertIndex = -1
      if itemContent.type = m.constants.ui.contentTypes.series AND m.firstLineGroup <> invalid AND m.firstLineGroup.getParent() <> invalid
        firstLineGroupIndex = m.nodeHelpers.getChildIndex(m.metadataGroup, m.firstLineGroup)
        if firstLineGroupIndex <> -1 then insertIndex = firstLineGroupIndex + 1
      end if

      if insertIndex = -1 AND m.description <> invalid
        descriptionIndex = m.nodeHelpers.getChildIndex(m.metadataGroup, m.description)
        if descriptionIndex <> -1 then insertIndex = descriptionIndex
      end if

      if insertIndex <> -1
        currentChildCount = m.metadataGroup.getChildCount()
        if insertIndex > currentChildCount then insertIndex = currentChildCount
        m.metadataGroup.insertChild(m.secondLineGroup, insertIndex)
      else
        m.metadataGroup.appendChild(m.secondLineGroup)
      end if

      if isNonEmptyArray(topLabels) = true
        showTopLabels(m.secondLineGroup, topLabels)
      end if

      if isNonEmptyArray(metaDataLabels) = true
        if m.sotBadge <> invalid AND m.sotBadge.getParent() <> invalid
          m.firstLineGroup.removeChild(m.sotBadge)
        end if
        showMetaDataLabels(m.secondLineGroup, metaDataLabels)
      end if

    end if

    ' With 3 lines of description text, the height is 230px and with 2 lines of description text, the height is 192px.
    ' And parent level translation is set based on 2 lines of description text. So we are adjusting the bottom padding by negative margining the metadataGroup.
    ' This is required only for control variant.
    if m.top.variant <> "detailScreenInfoPanel"
      height = m.metadataGroup.boundingRect().height
      translation = m.metadataGroup.translation
      m.metadataGroup.translation = [translation[0], 192 - height]
    end if
  end if
End Function


' Displays metadata for poster/thumbnail content (movies, series, etc.)
' Shows genres, release date, seasons/length, rating, descriptors, and badges
' @param itemContent - Content node with metadata to display
Function metadataOnPosterContent(itemContent)
  insertIndex = 0
  isDetailScreenInfoPanel = m.top.variant = "detailScreenInfoPanel"

  ' Remove channel info group if it exists
  if m.channelInfoGroup <> invalid
    m.metadataGroup.removeChild(m.channelInfoGroup)
    m.channelInfoGroup = invalid
  end if

  ' Remove network logo poster if it exists
  if m.networkLogoPoster <> invalid
    m.metadataGroup.removeChild(m.networkLogoPoster)
    m.networkLogoPoster = invalid
  end if

  prefixTextParts = []
  tags = itemContent.genres
  if isNonEmptyArray(tags) = true
    maxTags = 2
    if isDetailScreenInfoPanel
      maxTags = 3
    end if

    text = ""
    for i = 0 to maxTags - 1
      if tags[i] <> invalid
        if text <> ""
          text += ", "
        end if
        text += tags[i]
      end if
    end for

    prefixTextParts.push(text)
  end if

  if itemContent.releaseDate <> invalid
    text = itemContent.releaseDate.toStr()
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
  if isNonEmptyString(itemContent.rating) = true
    if ratingIsPresent = false
      ratingSotParent.insertChild(m.rating, insertIndex)
    end if
    m.ratingLabel.width = 0
    m.ratingLabel.text = UCase(itemContent.rating)
    nRatingBoundingBoxIncrease = m.ratingLabel.boundingRect().width + 24
    nRatingBoundingBoxIncrease = ensureDivisibleBy3(nRatingBoundingBoxIncrease)
    m.ratingBackground.width = nRatingBoundingBoxIncrease
    m.ratingLabel.width = nRatingBoundingBoxIncrease
  else
    if ratingIsPresent = true
      ratingSotParent.removeChild(m.rating)
    end if
  end if

  if isDetailScreenInfoPanel = true
    displayRatingDescriptor(itemContent)

    networkLogoUri = resolveNetworkLogoUriFromContent(itemContent)
    if isNonEmptyString(networkLogoUri)
      displayNetworkLogo(networkLogoUri)
    else if isNonEmptyString(itemContent.channelLogoShort) AND isNonEmptyString(itemContent.channelName)
      displayChannelInfo(itemContent.channelLogoShort, itemContent.channelName)
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
        insertIndex = ratingIndex
      end if
      ratingSotParent.insertChild(m.sotBadge, insertIndex)
    end if

    textColor = m.primaryTextColor
    backgroundUri = "pkg:/images/rounded-background-$$RES$$.9.png"
    badgeTextFont = m.bodySmallFont

    m.sotBadge.textColor = textColor
    m.sotBadge.borderUri = ""
    m.sotBadge.backgroundUri = backgroundUri
    m.sotBadge.badgeTextFont = badgeTextFont
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

  ' if the variant is detailScreenInfoPanel then we need to display rating descriptor codes (D, L, S, V, FV) also audio description badge if present
  if isDetailScreenInfoPanel = true AND itemContent.hasAudioDescription = true
    displayAudioDescriptionBadge()
  end if

End Function


' Displays metadata for continue watching content
' Shows progress bar and time remaining based on viewing history
' Hides rating, closed captions, and SOT badge
' @param itemContent - Content node with viewing history
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


' Displays metadata for live/linear content
' Shows release date, program duration, and time remaining
' @param currentProgram - Current program node with scheduling information
Function metadataOnLivePosterContent(currentProgram)
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


' Displays rating information for live content
' Shows or hides rating based on currentProgram rating field
' @param currentProgram - Current program node with rating information
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


' Triggers when the description text is ellipsized.
Function onIsTextEllipsizedChange(msg)
  isTextEllipsized = msg.getData()
  if isTextEllipsized = true
    m.description.width = 884
  end if
End Function


' Handles hideTitle field changes and shows/hides the title element
' @param msg - Message containing hideTitle boolean value
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


' Renders subtitle/subheadline text parts with bullet separators
' @param parts - Array of text strings to display
' @param isPrefix - Boolean, true for prefix group, false for suffix group
Function renderSubHeadline(parts, isPrefix)
  if isPrefix = true
    group = m.subHeadlinePrefixGroup
  else
    group = m.subHeadlineSuffixGroup
  end if

  ' Determine typography font once before loop
  typographyFont = m.bodySmallFont

  ' Collect labels in array for batch insertion
  labels = []
  prefix = ""
  for each part in parts
    label = createLabel(prefix + part, {
      height: 40
      color: m.secondaryTextColor
      typographyFont: typographyFont
      vertAlign: "center"
    })
    labels.push(label)

    prefix = " " + Chr(&hb7) + " "
  end for

  ' Batch append all labels at once
  if isNonEmptyArray(labels)
    group.appendChildren(labels)
  end if
End Function


' Handles width changes and adjusts description width accordingly
Function onWidthChange()
  if m.top.descriptionWidth <= 0
    m.description.width = m.top.width
  else
    m.description.width = m.top.descriptionWidth
  end if
End Function


' Appends title label or title image to metadata group and configures spacing based on variant
' For detailScreenInfoPanel with title art, displays poster image; otherwise displays text label
Function appendTitleToMetadataGroup()
  isDetailScreenInfoPanel = m.top.variant = "detailScreenInfoPanel"

  ' Create text label for title
  m.title = createObject("roSGNode", "Label")
  m.title.id = "title"
  if isDetailScreenInfoPanel = true
    m.title.update({
      width: 960
      height: 60
      vertAlign: "bottom"
    })
  end if
  if isDetailScreenInfoPanel = true
    setTypographyOfLabel(m.title, m.headerMediumFont)
  else
    setTypographyOfLabel(m.title, m.headerSmallFont)
  end if
  m.metadataGroup.insertChild(m.title, 0)

  if isDetailScreenInfoPanel = false
    m.metadataGroup.itemSpacings = [9, 3]
  end if
  setTypographyOfLabel(m.description, m.bodyMediumFont)
End Function



' Displays rating descriptor codes (D, L, S, V, FV) with descriptions
' @param itemContent - Content node containing descriptorCode and descriptorDescription
Function displayRatingDescriptor(itemContent) as Void
  if itemContent.descriptorCode = invalid OR itemContent.descriptorCode = "" then return

  descriptorCode = itemContent.descriptorCode.trim().split(" ")

  ' Create all rating descriptor badges in an array
  m.ratingDescriptorBadges = []
  ratingSize = 27

  for i = 0 to descriptorCode.count() - 1
    code = descriptorCode[i]

    ' Create rating code badge using mixin helper
    codeBadge = createRatingDescriptorBadge(code, {
      ratingSize: ratingSize
      labelFont: m.bodyExtraSmallStrongFont
      labelColor: m.secondaryTextColor
    })

    m.ratingDescriptorBadges.push(codeBadge)
  end for

  ' Insert badges into firstLineGroup after rating using appendChildren
  ratingIndex = m.nodeHelpers.getChildIndex(m.firstLineGroup, m.rating)
  if ratingIndex <> -1
    m.firstLineGroup.insertChildren(m.ratingDescriptorBadges, ratingIndex + 1)
  end if
End Function


' Displays the audio description badge in the first line group
Function displayAudioDescriptionBadge()
  audioDescriptionIndex = m.nodeHelpers.getChildIndex(m.firstLineGroup, m.rating)

  audioDescriptionPoster = createPoster("pkg:/images/icon-audio-description.webp", {
    id: "audioDescriptionPoster"
    width: 63
    height: 27
    loadDisplayMode: "scaleToFit"
  })

  m.firstLineGroup.insertChild(audioDescriptionPoster, audioDescriptionIndex)
  m.audioDescriptionPoster = audioDescriptionPoster
End Function


' Renders genre tags in the metadata group
' @param tags - String containing genre tags to display
Function renderTags(tags)
  if m.tagsLabel <> invalid
    m.metadataGroup.removeChild(m.tagsLabel)
  end if

  label = createLabel(tags, {
    id: "tags"
    height: 40
    color: m.secondaryTextColor
    typographyFont: m.bodyMediumFont
    vertAlign: "center"
  })

  m.metadataGroup.insertChild(label, 2)
  m.tagsLabel = label
End Function


' Creates and displays channel/network information with logo and name
' Creates a horizontal layout group containing the logo and channel name label
' @param channelLogoUri - String, the URI for the channel logo
' @param channelName - String, the name of the channel/network to display
Function displayChannelInfo(channelLogoUri as String, channelName as String) as Void
  ' Create logo poster
  networkLogo = createPoster(channelLogoUri, {
    id: "networkLogo"
    height: 40
    width: 40
    loadDisplayMode: "scaleToFit"
    loadingBitmapUri: "pkg:/images/placeholder-featured.webp"
    failedBitmapUri: "pkg:/images/placeholder-featured.webp"
  })

  ' Create channel name label
  channelNameLabel = createLabel(channelName, {
    id: "channelNameLabel"
    color: m.primaryTextColor
    typographyFont: m.subheaderSmallFont
    vertAlign: "center"
    height: 40
  })

  ' Create horizontal layout group with logo and name
  channelInfoGroup = createLayoutGroup("horiz", {
    id: "channelInfoGroup"
    itemSpacings: [9]
    children: [networkLogo, channelNameLabel]
  })

  ' Insert into metadata group and cache references
  m.metadataGroup.insertChild(channelInfoGroup, 0)
  m.channelInfoGroup = channelInfoGroup
End Function


' Displays a network logo poster above the channel info in the metadata group
' @param logoUri - String, the URI for the network logo
Function displayNetworkLogo(logoUri as String) as Void
  m.networkLogoPoster = createPoster(logoUri, {
    id: "networkLogoPoster"
    loadWidth: 192
    loadHeight: 102
    loadDisplayMode: "limitSize"
  })

  m.networkLogoPoster.observeFieldScoped("loadStatus", "onNetworkLogoLoadStatusChange")
  m.metadataGroup.insertChild(m.networkLogoPoster, 0)
End Function


' Fires layoutChanged when the network logo finishes loading so parent
' components can recalculate positioning based on the updated height.
Function onNetworkLogoLoadStatusChange(msg) as Void
  status = msg.getData()
  if status = "ready" OR status = "failed"
    m.networkLogoPoster.unobserveFieldScoped("loadStatus")
    m.top.layoutChanged = true
  end if
End Function


' Removes the current episode title label from metadata group
Function removeCurrentEpisodeTitleLabel() as Void
  if m.currentEpisodeTitleLabel <> invalid
    m.metadataGroup.removeChild(m.currentEpisodeTitleLabel)
    m.currentEpisodeTitleLabel = invalid
  end if
End Function


' Handles changes to currentEpisode field
' Creates and updates the episode title label when currentEpisode is set
Function onCurrentEpisodeChange() as Void
  currentEpisode = m.top.currentEpisode
  removeCurrentEpisodeTitleLabel()

  if currentEpisode <> invalid AND isNonEmptyString(currentEpisode.title)
    m.currentEpisodeTitleLabel = createLabel(formatEpisodeTitle(currentEpisode.title), {
      id: "currentEpisodeTitleLabel"
      height: 33
      width: 960
      vertAlign: "center"
      color: m.primaryTextColor
      typographyFont: m.subheaderSmallFont
    })

    ' Insert after title label
    titleIndex = m.nodeHelpers.getChildIndex(m.metadataGroup, m.title)
    m.metadataGroup.insertChild(m.currentEpisodeTitleLabel, titleIndex + 1)

    if isNonEmptyString(currentEpisode.description) = true
      m.description.text = currentEpisode.description

      lengthString = convertSecondsToHoursString(currentEpisode.length)

      if m.currentEpisodeLengthLabel <> invalid
        m.subHeadlinePrefixGroup.removeChild(m.currentEpisodeLengthLabel)
      end if

      m.currentEpisodeLengthLabel = createLabel(" " + Chr(&hb7) + " " + lengthString, {
        height: 40
        color: m.secondaryTextColor
        typographyFont: m.bodySmallFont
        vertAlign: "center"
      })
      ' TODO: Revisit this logic we need a better solution for this.
      m.subHeadlinePrefixGroup.insertChild(m.currentEpisodeLengthLabel, m.subHeadlinePrefixGroup.getChildCount() - 1)
    end if

    m.metadataGroup.itemSpacings = [9, 15]
  end if
End Function


' TODO: This is a temporary solution to format the episode title. Backend will be formatting the title in the future.

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
