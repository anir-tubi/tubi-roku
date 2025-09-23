Function init()
  topRef = m.top
  topRef.observeFieldScoped("itemContent", "onItemContentChange")
  topRef.observeFieldScoped("height", "onHeightChange")
  m.title = topRef.findNode("title")
  m.subtitle = topRef.findNode("subtitle")
  m.titleGroup = topRef.findNode("titleGroup")
  m.titleImage = topRef.findNode("titleImage")
  m.sotTopLabelGroup = topRef.findNode("sotTopLabelGroup")
  m.bottomContentGroup = topRef.findNode("bottomContentGroup")
  m.sotMarker = topRef.findNode("sotMarker")
  m.billboardTileMetadata = invalid


  m.BadgeTypes = {
    live: "live"
    onNow: "onNow"
    sot: "sot"
  }

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.title, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.subtitle, typographyConstants.ids.bodySmallStrong)
  m.badgeTextFont = typographyConstants.ids.bodyExtraSmallStrong
  m.headerSmallFont = typographyConstants.ids.headerSmall
  m.bodyMediumStrongFont = typographyConstants.ids.bodyMediumStrong

  m.titleImage.observeFieldScoped("loadStatus", "onTitleImageLoadStatus")
  topRef.observeFieldScoped("showContentPoster", "onShowContentPosterChange")
  topRef.observeFieldScoped("width", "onWidthChange")
  topRef.observeFieldScoped("skipAnimation", "onSkipAnimationChange")
  topRef.observeFieldScoped("containerIndex", "onContainerIndexChange")

  onThemeChange()

  m.metadataFadeDelay = 0.5
  m.animationDuration = 0
  m.title.lineSpacing = 0

  m.titleAnimation = invalid

  m.billboardSize = 0
  experimentInfo = getExperimentResource("roku_home_screen_redesign", "roku_home_screen_redesign_v_1_6", false)
  if isAA(experimentInfo) = true
    m.variant = experimentInfo.variant

    if m.variant = "billboard"
      m.billboardTileMetadata = createObject("roSGNode", "ExpandedTileMetadata")
      m.billboardTileMetadata.id = "billboardTileMetadata"
      m.billboardTileMetadata.hideTitle = true
      m.billboardTileMetadata.descriptionWidth = 726
      m.billboardTileMetadata.isBillboardRow = true

      constants = getConstantsFromGlobal()
      m.billboardSize = constants.ui.imageSizes.billboard
    end if
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
    m.cautionColor = theme.cautionColor
  end if
End Function


Function onItemContentChange(msg)
  itemContent = msg.getData()

  if itemContent <> invalid
    adjustPosterBottomContentTranslation()
    isBillboardRow = m.variant = "billboard" AND m.top.containerIndex = m.top.billboardContainerIndex
    titleImageLoadHeight = 160
    titleImageLoadWidth = 478
    if isBillboardRow = false
      m.bottomContentGroup.translation = [15, m.top.height - 24]
      titleImageLoadHeight = 68
      titleImageLoadWidth = 240
      setTypographyOfLabel(m.title, m.bodyMediumStrongFont)
    else
      setTypographyOfLabel(m.title, m.headerSmallFont)
    end if
    ' We are only limiting the height since title logo is displayed on it's own row we are good to let the width flow.
    m.titleImage.loadHeight = titleImageLoadHeight
    m.titleImage.loadWidth = titleImageLoadWidth
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

    if m.billboardTileMetadata <> invalid
      m.billboardTileMetadata.itemContent = itemContent
      m.billboardTileMetadata.opacity = 0
    end if
    if isBillboardRow = true
      parent = m.billboardTileMetadata.getParent()
      if (parent = invalid OR parent.id <> "bottomContentGroup")
        m.bottomContentGroup.appendChild(m.billboardTileMetadata)
      end if
      fade(m.billboardTileMetadata, "in", m.animationDuration, m.metadataFadeDelay)
      adjustPosterBottomContentTranslation()
    else if m.billboardTileMetadata <> invalid
      m.bottomContentGroup.removeChild(m.billboardTileMetadata)
    end if

    if isBadgeAdded = false AND isAA(itemContent.sotInfo) = true
      setBadge(m.badgeTypes.sot, itemContent.sotInfo)
    end if

    if itemContent.type = "linear"
      m.title.maxLines = 1
    else
      m.title.maxLines = 2
    end if

    if m.variant <> "typography_improvements"
      ' For Linear content, we are using the title from the current program.
      if currentProgram <> invalid
        setSubtitle(itemContent.title)
        setTitle(currentProgram.epgProgramTitle)
      else
        if m.subtitle.getParent() <> invalid
          m.titleGroup.removeChild(m.subtitle)
        end if
        setTitle(itemContent.title, itemContent.titleImageUrl)
      end if
    end if
    m.metadataFadeDelay = 0
    adjustPosterBottomContentTranslation()
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
    if m.titleImage.getParent() = invalid
      m.bottomContentGroup.insertChild(m.titleImage, 0)
    end if
    m.titleImage.uri = titleImageUri
  else
    m.titleImage.uri = ""
    m.bottomContentGroup.removeChild(m.titleImage)
    if m.titleGroup.getParent() = invalid
      m.bottomContentGroup.insertChild(m.titleGroup, 0)
    end if
    m.titleAnimation = fade(m.titleGroup, "in", m.animationDuration)
  end if
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


Function onTitleImageLoadStatus(msg)
  if msg.getData() = "ready"
    m.bottomContentGroup.removeChild(m.titleGroup)
    m.titleAnimation = fade(m.titleImage, "in", m.animationDuration)
    adjustPosterBottomContentTranslation()
  end if
End Function


'@badgeType - string, Indicating format of the badge
'@badgeInfo - assocArray, includes sotMarkers, sotMetaDataTopLabels, sotMetaData
Function setBadge(badgeType = "live", badgeInfo = {})
  if badgeType = m.badgeTypes.live
    badge = m.sotTopLabelGroup.createChild("Badge")
    badge.badgeTextWidth = 0.0
    badge.textColor = m.primaryTextColor
    badge.translation = [15, 15]
    badge.backgroundColor = m.focused2Color
    badge.iconUri = "pkg:/images/live-icon-filled.webp"
    badge.text = UCase(getTranslation("screenSearch_liveText"))
  else if badgeType = m.badgeTypes.onNow
    badge = m.sotTopLabelGroup.createChild("Badge")
    badge.badgeTextWidth = 0.0
    badge.textColor = m.primaryTextColor
    badge.translation = [15, 15]
    badge.backgroundColor = m.blueBadgeColor
    badge.text = UCase(getTranslation("onNow"))
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
        m.bottomContentGroup.appendChild(m.sotMarker)
      end if
    end if

  end if
End Function


Function onShowContentPosterChange(msg)
  if isNonEmptyString(m.titleImage.uri) = true AND m.titleImage.loadStatus = "ready" AND m.titleImage.opacity = 0
    m.titleAnimation = fade(m.titleImage, "in", m.animationDuration)
  end if
End Function


Function onWidthChange(msg)
  width = msg.getData()
  if width > 0 AND m.billboardTileMetadata <> invalid
    m.billboardTileMetadata.width = width - 64
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
  topLabelCount = m.sotTopLabelGroup.getChildCount()
  m.sotTopLabelGroup.removeChildrenIndex(topLabelCount, 0)
  m.bottomContentGroup.removeChild(m.sotMarker)
End Function


Function adjustPosterBottomContentTranslation()
  height = m.bottomContentGroup.boundingRect().height
  isBillboardRow = m.variant = "billboard" AND m.top.containerIndex = m.top.billboardContainerIndex
  containerHeight = m.top.height
  translationX = 15
  if isBillboardRow = true
    containerHeight = m.billboardSize[1]
    translationX = 33
  end if
  m.bottomContentGroup.translation = [translationX, containerHeight - height - 24]
End Function


Function onContainerIndexChange(msg)
  containerIndex = msg.getData()
  if containerIndex > m.top.billboardContainerIndex AND m.billboardTileMetadata <> invalid
    m.bottomContentGroup.removeChild(m.billboardTileMetadata)
    adjustPosterBottomContentTranslation()
  end if
End Function
