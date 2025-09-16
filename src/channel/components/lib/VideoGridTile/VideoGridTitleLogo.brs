Function init()
  topRef = m.top
  m.tileLayout = topRef.findNode("tileLayout")
  m.videoInGridGradient = topRef.findNode("videoInGridGradient")
  topRef.observeFieldScoped("itemContent", "onItemContentChange")
  topRef.observeFieldScoped("height", "onHeightChange")
  m.title = topRef.findNode("title")
  m.subtitle = topRef.findNode("subtitle")
  m.titleGroup = topRef.findNode("titleGroup")
  m.titleImage = topRef.findNode("titleImage")
  m.posterGroup = topRef.findNode("posterGroup")

  m.sotTopLabelGroup = m.top.findNode("sotTopLabelGroup")
  m.sotMarkerGroup = m.top.findNode("sotMarkerGroup")
  m.sotMarker = m.top.findNode("sotMarker")
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
  m.badgeTextFont = typographyConstants.ids.bodyextrasmallstrong

  m.titleImage.observeFieldScoped("loadStatus", "onTitleImageLoadStatus")
  topRef.observeFieldScoped("showContentPoster", "onShowContentPosterChange")

  m.title.lineSpacing = 0

  onThemeChange()

  m.titleAnimation = invalid
End Function


Function onThemeChange()
  theme = getThemeFromGlobal()

  if theme <> invalid
    m.title.color = theme.primaryTextColor
    m.subtitle.color = theme.primaryTextColor
    m.focused2Color = theme.focused2Color
    m.blueBadgeColor = theme.blueBadgeColor
    m.cautionColor = theme.cautionColor
    m.focusedTextColor = theme.focusedTextColor
  end if
End Function


Function onItemContentChange(msg)
  itemContent = msg.getData()

  if itemContent <> invalid
    m.tileLayout.visible = true
    currentProgram = invalid
    isBadgeAdded = false
    if itemContent.type = "linear"
      currentProgram = getCurrentLiveProgram(itemContent)
      ' Only add the onNow badge if there is no live program or the live program is not live.
      if currentProgram = invalid OR currentProgram.live = false
        setBadge(m.badgeTypes.onNow)
      else
        setBadge(m.badgeTypes.live)
      end if
    end if

    if itemContent.type = "linear"
      isBadgeAdded = true
      m.title.maxLines = 1
    else
      m.title.maxLines = 2
    end if

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

    if isBadgeAdded = false AND isAA(itemContent.sotInfo) = true
      setBadge(m.badgeTypes.sot, itemContent.sotInfo)
    end if
  else
    m.tileLayout.visible = false
  end if
End Function


Function setTitle(title = "", titleImageUri = "")
  ' Stopping any existing animations
  if m.titleAnimation <> invalid
    m.titleAnimation.control = "finish"
    m.titleAnimation = invalid
  end if

  m.title.text = title
  titleImageUri = titleImageUri
  m.titleImage.scale = [1.0, 1.0]
  m.titleImage.opacity = 0
  m.titleGroup.opacity = 0

  if isNonEmptyString(titleImageUri) = true
    m.titleImage.uri = titleImageUri
  else
    m.titleImage.uri = ""
    m.titleGroup.translation = [16, m.top.height - 63 - m.titleGroup.boundingRect().height]
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
'@badgeInfo - assocArray, includes sotMarkers, sotMetaDataTopLabels, sotMetaData
Function setBadge(badgeType = "live", badgeInfo = {})
  topLabelCount = m.sotTopLabelGroup.getChildCount()
  m.sotTopLabelGroup.removeChildrenIndex(topLabelCount, 0)
  m.sotMarkerGroup.removeChild(m.sotMarker)

  if badgeType = m.badgeTypes.live
    badge = m.sotTopLabelGroup.createChild("Badge")
    badge.textColor = m.primaryTextColor
    badge.translation = [15, 15]
    badge.backgroundColor = m.focused2Color
    badge.iconUri = "pkg:/images/live-icon-filled.webp"
    badge.text = UCase(getTranslation("screenSearch_liveText"))
  else if badgeType = m.badgeTypes.onNow
    badge = m.sotTopLabelGroup.createChild("Badge")
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
        translationX = 15
        translationY = m.top.height - m.sotMarker.boundingRect().height - 15
        m.sotMarkerGroup.translation = [translationX, translationY]
        m.sotMarkerGroup.appendChild(m.sotMarker)
      end if
    end if
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
  translationY = m.top.height - 63 - m.titleImage.boundingRect().height
  m.titleImage.translation = [16, translationY]
End Function
