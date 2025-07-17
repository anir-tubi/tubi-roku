Function init()
  topRef = m.top
  m.poster = topRef.findNode("Poster")
  m.videoGridMetadata = topRef.findNode("videoGridMetadata")
  m.videoInGridGradient = topRef.findNode("videoInGridGradient")
  topRef.observeFieldScoped("itemContent", "onItemContentChange")
  topRef.observeFieldScoped("height", "onHeightChange")
  m.title = topRef.findNode("title")
  m.subtitle = topRef.findNode("subtitle")
  m.titleGroup = topRef.findNode("titleGroup")
  m.titleImage = topRef.findNode("titleImage")
  m.posterGroup = topRef.findNode("posterGroup")
  ' We are only limiting the height since title logo is displayed on it's own row we are good to let the width flow.
  m.titleImage.loadHeight = 68
  m.titleImage.loadWidth = 240

  m.BadgeTypes = {
    live: "live"
    onNow: "onNow"
    sot: "sot"
  }

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.title, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.subtitle, typographyConstants.ids.bodySmallStrong)

  m.titleImage.observeFieldScoped("loadStatus", "onTitleImageLoadStatus")
  topRef.observeFieldScoped("showContentPoster", "onShowContentPosterChange")
  topRef.observeFieldScoped("width", "onWidthChange")

  onThemeChange()

  m.metadataFadeDelay = 0.5
  m.title.lineSpacing = 0

  m.titleAnimation = invalid
End Function


Function onThemeChange()
  theme = getThemeFromGlobal()

  if theme <> invalid
    m.primaryTextColor = theme.primaryTextColor
    m.title.color = m.primaryTextColor
    m.subtitle.color = m.primaryTextColor
    m.focused2Color = theme.focused2Color
    m.blueBadgeColor = theme.blueBadgeColor
    m.focusedTextColor = theme.focusedTextColor
    m.primaryTextColor = theme.primaryTextColor
  end if
End Function


Function onItemContentChange(msg)
  itemContent = msg.getData()

  if itemContent <> invalid
    isBadgeAdded = false

    currentProgram = invalid
    if m.badge <> invalid
      m.posterGroup.removeChild(m.badge)
      m.badge = invalid
    end if

    if itemContent.type = "linear"
      currentProgram = getCurrentLiveProgram(itemContent)
      isBadgeAdded = true
      setBadge(m.badgeTypes.onNow)
    end if

    if itemContent.type = "linear"
      m.title.maxLines = 1
    else
      m.title.maxLines = 2
    end if

    if currentProgram <> invalid
      if currentProgram.live = true
        isBadgeAdded = true
        setBadge(m.badgeTypes.live)
      end if
      if isNonEmptyString(currentProgram.landscapePosterUrl) = true
        m.poster.uri = currentProgram.landscapePosterUrl
      end if
    else if isNonEmptyString(itemContent.featuredLandscape) = true
      m.poster.uri = itemContent.featuredLandscape
    else if isNonEmptyString(itemContent.landscape) = true
      m.poster.uri = itemContent.landscape
    end if

    ' For Linear content, we are using the title from the current program.
    if currentProgram <> invalid
      setSubtitle(itemContent.title)
      setTitle(currentProgram.epgProgramTitle)
    else
      if m.subtitle.getParent() <> invalid
        m.titleGroup.removeChild(m.subtitle)
      end if
      setTitle(itemContent.title, itemContent.titleImageUri)
    end if

    m.videoGridMetadata.itemContent = itemContent
    m.videoGridMetadata.opacity = 0
    fade(m.videoGridMetadata, "in", 0.5, m.metadataFadeDelay)
    m.metadataFadeDelay = 0

    if isBadgeAdded = false AND isAA(itemContent.sotPosterLabels) = true AND itemContent.sotPosterLabels.count() > 0
      setBadge(m.badgeTypes.sot, itemContent.sotPosterLabels)
    end if
  end if
End Function


Function setTitle(title = "", titleImageUri = "")
  m.title.text = title
  titleImageUri = titleImageUri
  m.titleImage.scale = [1.0, 1.0]
  m.titleGroup.opacity = 0
  m.titleImage.opacity = 0

  ' Stopping any existing animations
  if m.titleAnimation <> invalid
    m.titleAnimation.control = "stop"
    m.titleAnimation = invalid
  end if
  
  if isNonEmptyString(titleImageUri) = true
    m.titleImage.uri = titleImageUri
  else
    m.titleImage.uri = ""
    m.titleGroup.translation = [16, m.top.height - 16 - m.titleGroup.boundingRect().height]
    m.titleAnimation = fade(m.titleGroup, "in", 0.5)
  end if
End Function


Function setSubtitle(subtitle = "")
  m.subtitle.text = subtitle
  if m.subtitle.getParent() = invalid
    m.titleGroup.insertChild(m.subtitle, 1)
  end if
End Function




Function onTitleImageLoadStatus(msg)
  if msg.getData() = "ready"
    adjustTitleImageTranslation()
    m.titleAnimation = fade(m.titleImage, "in", 0.5)
  end if
End Function


'@badgeType - string, Indicating format of the badge
'@badgeText - string, Indicating text on the badge
Function setBadge(badgeType = "live", badgeInfo = {})

  if m.badge = invalid
    m.badge = m.posterGroup.createChild("Badge")
    m.badge.textColor = m.primaryTextColor
    m.badge.translation = [16, 16]
  end if

  m.badge.badgeTextWidth = 0.0

  if badgeType = m.badgeTypes.live
    m.badge.backgroundColor = m.focused2Color
    m.badge.iconUri = "pkg:/images/live-icon-filled.webp"
    m.badge.text = UCase(getTranslation("screenSearch_liveText"))
  else if badgeType = m.badgeTypes.onNow
    m.badge.backgroundColor = m.blueBadgeColor
    m.badge.text = UCase(getTranslation("onNow"))
  else if badgeType = m.badgeTypes.sot
    m.badge.badgeTextWidth = 80.0
    m.badge.text = badgeInfo.sotLabelText
    m.badge.iconUri = badgeInfo.sotIcon
    m.badge.textColor = m.focusedTextColor
  end if

End Function


Function onHeightChange(msg)
  height = msg.getData()
  if height > 0
    m.videoInGridGradient.height = height
  end if
End Function


Function onShowContentPosterChange(msg)
  if isNonEmptyString(m.titleImage.uri) = true
    if m.titleImage.loadStatus = "ready" AND m.titleImage.opacity = 0
      m.titleAnimation = fade(m.titleImage, "in", 0.5)
    end if
    adjustTitleImageTranslation()
  end if
End Function


Function adjustTitleImageTranslation()
  translationY = m.top.height - 16 - m.titleImage.boundingRect().height
  m.titleImage.translation = [16, translationY]
End Function


Function onWidthChange(msg)
  width = msg.getData()
  if width > 0
    m.videoGridMetadata.width = width
  end if
End Function