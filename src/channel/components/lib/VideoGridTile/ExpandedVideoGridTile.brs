Function init()
  topRef = m.top
  m.poster = topRef.findNode("Poster")
  m.videoGridMetadata = topRef.findNode("videoGridMetadata")
  m.videoInGridGradient = topRef.findNode("videoInGridGradient")
  topRef.observeFieldScoped("itemContent", "onItemContentChange")
  topRef.observeFieldScoped("height", "onHeightChange")
  m.title = topRef.findNode("title")
  m.titleImage = topRef.findNode("titleImage")
  m.posterGroup = topRef.findNode("posterGroup")
  ' We are only limiting the height since title logo is displayed on it's own row we are good to let the width flow.
  m.titleImage.loadHeight = 90
  m.titleImage.loadWidth = 320

  m.BadgeTypes = {
    live: "live"
    onNow: "onNow"
  }

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.title, typographyConstants.ids.bodyMediumStrong)

  m.titleImage.observeFieldScoped("loadStatus", "onTitleImageLoadStatus")
  topRef.observeFieldScoped("showContentPoster", "onShowContentPosterChange")

  onThemeChange()
End Function


Function onThemeChange()
  theme = getThemeFromGlobal()

  if theme <> invalid
    m.title.color = theme.primaryTextColor
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
    end if

    if currentProgram <> invalid
      if currentProgram.live = true
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
      setTitle(currentProgram.title)
    else
      setTitle(itemContent.title, itemContent.titleImageUri)
    end if

    m.videoGridMetadata.itemContent = itemContent
  end if
End Function


Function setTitle(title = "", titleImageUri = "")
  m.title.text = title
  titleImageUri = titleImageUri
  m.titleImage.scale = [1.0, 1.0]
  if isNonEmptyString(titleImageUri) = true
    m.titleImage.uri = titleImageUri
    m.title.visible = false
  else
    m.titleImage.uri = ""
    m.title.translation = [16, m.top.height - 16 - m.title.boundingRect().height]
    m.title.visible = true
  end if
End Function


Function onTitleImageLoadStatus(msg)
  if msg.getData() = "ready"
    adjustTitleImageTranslation()
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
  showContentPoster = msg.getData()
  if isNonEmptyString(m.titleImage.uri) = true
    if showContentPoster = true
      m.titleImage.scale = [1.0, 1.0]
    else
      m.titleImage.scale = [0.75, 0.75]
    end if
    adjustTitleImageTranslation()
  end if
End Function


Function adjustTitleImageTranslation()
  translationY = m.top.height - 16 - m.titleImage.boundingRect().height
  m.titleImage.translation = [16, translationY]
End Function