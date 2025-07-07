Function init()
  topRef = m.top
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
  }

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.title, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.subtitle, typographyConstants.ids.bodySmallStrong)

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
  end if
End Function


Function onItemContentChange(msg)
  itemContent = msg.getData()

  if itemContent <> invalid
    currentProgram = invalid
    if itemContent.type = "linear"
      currentProgram = getCurrentLiveProgram(itemContent)
      setBadge(m.badgeTypes.onNow)
    else if m.badge <> invalid
        m.posterGroup.removeChild(m.badge)
        m.badge = invalid
    end if

    if currentProgram <> invalid
      if currentProgram.live = true
        setBadge(m.badgeTypes.live)
      end if
    end if

    if itemContent.type = "linear"
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
      setTitle(itemContent.title, itemContent.titleImageUri)
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
Function setBadge(badgeType = "live", badgeText = "")

  if m.badge = invalid
    m.badge = m.posterGroup.createChild("Badge")
    m.badge.textColor = m.primaryTextColor
    m.badge.translation = [16, 16]
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