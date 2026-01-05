Function init()
  m.constants = getConstantsFromGlobal()
  topRef = m.top
  topRef.observeFieldScoped("itemContent", "onItemContentChange")
  topRef.observeFieldScoped("height", "adjustPosterBottomContentTranslation")
  m.title = topRef.findNode("title")
  m.subtitle = topRef.findNode("subtitle")
  m.titleGroup = topRef.findNode("titleGroup")
  m.sotTopLabelGroup = topRef.findNode("sotTopLabelGroup")
  m.bottomContentGroup = topRef.findNode("bottomContentGroup")
  m.channelLogo = topRef.findNode("channelLogo")
  m.overlayTitleRow = topRef.findNode("overlayTitleRow")
  m.channelLogoGroup = topRef.findNode("channelLogoGroup")
  m.channelLogoBackground = topRef.findNode("channelLogoBackground")

  m.BadgeTypes = {
    live: "live"
    onNow: "onNow"
    sot: "sot"
  }

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.title, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.subtitle, typographyConstants.ids.bodySmallStrong)
  m.badgeTextFont = typographyConstants.ids.bodyExtraSmallStrong
  m.headerMediumFont = typographyConstants.ids.headerMedium
  m.bodyMediumStrongFont = typographyConstants.ids.bodyMediumStrong
  m.subheaderMediumFont = typographyConstants.ids.subheaderMedium
  m.badgeSmallFont = typographyConstants.ids.bodySmall

  topRef.observeFieldScoped("skipAnimation", "onSkipAnimationChange")

  onThemeChange()

  m.metadataFadeDelay = 0.5
  m.animationDuration = 0
  m.title.lineSpacing = 0

  m.titleAnimation = invalid

  experimentInfo = getStatsigExperimentResource("roku_video_tiles", "roku_video_tiles_1_7", false)
  if isAA(experimentInfo) = true
    m.variant = experimentInfo.variant
  end if
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
    m.backgroundColor = theme.neutralSolidColor
    m.shadeColor = theme.shadeColor
    m.cautionColor = theme.cautionColor
    m.channelLogoBackground.blendColor = theme.tertiaryTextColor
  end if
End Function


Function onItemContentChange(msg)
  itemContent = msg.getData()

  if itemContent <> invalid
    if m.subtitle.getParent() <> invalid
      m.titleGroup.removeChild(m.subtitle)
    end if
    m.overlayTitleRow.removeChild(m.channelLogoGroup)
    adjustPosterBottomContentTranslation()
    m.bottomContentGroup.translation = [15, m.top.height - 24]
    setTypographyOfLabel(m.title, m.subheaderMediumFont)

    m.title.height = 0
    m.title.vertAlign = "bottom"
    m.title.maxLines = 2

    removeAllSotBadges()
    isBadgeAdded = false

    currentProgram = invalid
    if m.badge <> invalid
      m.posterGroup.removeChild(m.badge)
      m.badge = invalid
    end if

    if itemContent.type = "linear"
      currentProgram = getCurrentLiveProgram(itemContent)
      isBadgeAdded = true
      ' Only add the onNow badge if there is no live program or the live program is not live.
      if currentProgram = invalid OR currentProgram.live = false
        setBadge(m.badgeTypes.onNow)
      else
        setBadge(m.badgeTypes.live)
      end if
    end if

    sotInfo = itemContent.sotInfo
    sotposterlabels = itemContent.sotposterlabels
    if isBadgeAdded = false AND (isNonEmptyAA(sotInfo) = true OR isNonEmptyAA(sotposterlabels) = true)
      removeAllSotBadges()
      setBadge(m.badgeTypes.sot, sotInfo, sotposterlabels)
    end if

    if itemContent.type = "linear"
      m.title.maxLines = 1
    end if

    ' For Linear content, we are using the title from the current program.
    if currentProgram <> invalid
      setSubtitle(itemContent.title)
      if isNonEmptyString(currentProgram.epgProgramTitle) = true
        setTitle(currentProgram.epgProgramTitle)
      else
        setTitle(currentProgram.title)
      end if
    else
      setTitle(itemContent.title)
    end if

    m.metadataFadeDelay = 0
    adjustPosterBottomContentTranslation()
  end if
End Function


Function setTitle(title = "")
  m.title.text = title
  m.titleGroup.opacity = 0
  ' Stopping any existing animations
  if m.titleAnimation <> invalid
    m.titleAnimation.control = "stop"
    m.titleAnimation = invalid
  end if
  displayVideoTitle()
End Function


Function displayVideoTitle()
  if m.titleGroup.getParent() = invalid
    m.overlayTitleRow.appendChild(m.titleGroup)
  end if
  m.titleAnimation = fade(m.titleGroup, "in", m.animationDuration)
End Function


Function setSubtitle(subtitle = "")
  m.subtitle.text = subtitle
  if m.subtitle.getParent() = invalid
    m.titleGroup.insertChild(m.subtitle, 1)
  end if
End Function


Function onPreloadPosterLoadStatus(msg)
  if msg.getData() = "ready"
    m.poster.uri = m.preloadPoster.uri
    m.preloadPoster.uri = ""
    m.preloadPosterTimer.control = "stop"
  end if
End Function


'@badgeType - string, Indicating format of the badge
'@badgeInfo - assocArray, includes sotMarkers, sotMetaDataTopLabels, sotMetaData
Function setBadge(badgeType = "live", badgeInfo = {}, posterLabels = {})
  if badgeType = m.badgeTypes.live
    badge = m.sotTopLabelGroup.createChild("Badge")
    badge.badgeTextWidth = 0.0
    badge.maxWidth = m.top.width - 12
    badge.textColor = m.primaryTextColor
    badge.translation = [15, 15]
    badge.badgeTextFont = m.badgeSmallFont
    badge.borderUri = ""
    badge.backgroundUri = "pkg:/images/rounded-rect-live-$$RES$$.9.png"
    badge.iconUri = "pkg:/images/live-icon-filled.webp"
    badge.text = getTranslation("screenSearch_liveText")
  else if badgeType = m.badgeTypes.onNow
    badge = m.sotTopLabelGroup.createChild("Badge")
    badge.badgeTextWidth = 0.0
    badge.maxWidth = m.top.width - 12
    badge.textColor = m.primaryTextColor
    badge.translation = [15, 15]
    badge.badgeTextFont = m.badgeSmallFont
    badge.borderUri = ""
    badge.backgroundUri = "pkg:/images/rounded-rect-on-now-$$RES$$.9.png"
    badge.text = getTranslation("onNow")
  else if badgeType = m.badgeTypes.sot
    config = {
      focusedTextColor: m.primaryTextColor
      primaryTextColor: m.primaryTextColor
      maxWidth: m.top.width - 12
      bodyMediumStrongFont: m.badgeSmallFont
      badgeTextFont: m.badgeSmallFont
      textColor: m.primaryTextColor
    }
    showSotBadges(badgeInfo, config, m.sotTopLabelGroup, m.bottomContentGroup, posterLabels)
  end if
End Function


Function onPreloadPosterTimerFire(msg)
  if isNonEmptyString(m.preloadPoster.uri) = true
    ' If the image is taking more time to load switching to placeholder image until the image is loaded.
    m.poster.uri = "pkg:/images/placeholder-featured.webp"
  end if
End Function


Function onSkipAnimationChange(msg)
  skipAnimation = msg.getData()

  if skipAnimation = true
    m.animationDuration = 0
  else
    m.animationDuration = 0.3
  end if
End Function


Function removeAllSotBadges()
  ' Remove all top label badges
  topLabelCount = m.sotTopLabelGroup.getChildCount()
  if topLabelCount > 0
    m.sotTopLabelGroup.removeChildrenIndex(topLabelCount, 0)
  end if

  ' Remove marker badge if it exists
  existingMarker = m.bottomContentGroup.findNode("sotMarker")
  if existingMarker <> invalid
    m.bottomContentGroup.removeChild(existingMarker)
  end if
End Function


Function adjustPosterBottomContentTranslation()
  height = m.bottomContentGroup.boundingRect().height
  containerHeight = m.top.height
  m.bottomContentGroup.translation = [15, containerHeight - height - 12]
End Function


Function setThumbnailImage(thumbnailUri, contentType)
  channelLogoIsPresent = (m.channelLogoGroup.getParent() <> invalid)
  if isNonEmptyString(thumbnailUri) = true AND (contentType = m.constants.ui.contentTypes.sportsEvent OR contentType = m.constants.ui.contentTypes.linear)
    if channelLogoIsPresent = false
      m.overlayTitleRow.insertChild(m.channelLogoGroup, 0)
    end if
    m.channelLogo.uri = thumbnailUri
  end if
End Function
