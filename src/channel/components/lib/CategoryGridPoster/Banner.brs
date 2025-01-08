Function init()
  topRef = m.top
  m.poster = topRef.findNode("poster")
  m.title = topRef.findNode("title")
  m.disclaimer = topRef.findNode("disclaimer")
  m.textGroup = topRef.findNode("textGroup")
  topRef.observeFieldScoped("itemContent", "onContentChange")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.title, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.disclaimer, typographyConstants.ids.bodyExtraSmall)
  setThemeColors()
End Function


Function setThemeColors()
  theme = getThemeFromGlobal()

  if theme <> invalid
    m.title.color = theme.primaryTextColor
    m.disclaimer.color = theme.secondaryTextColor
  end if
End Function


Function onContentChange(msg)
  itemContent = msg.getData()
  
  if itemContent <> invalid
    
    if itemContent.needsLogin = true AND isNonEmptyString(itemContent.bannerBackgroundGuest) = true
      m.poster.uri = itemContent.bannerBackgroundGuest
    else if isNonEmptyString(itemContent.hdGridPosterUrl) = true
      m.poster.uri = itemContent.hdGridPosterUrl
    end if

    titleText = ""
    
    m.disclaimer.scale = [0, 0]

    if itemContent.needsLogin = true
      if itemContent.bannerTextGuest <> invalid
        titleText = itemContent.bannerTextGuest
      end if

      if isNonEmptyString(itemContent.bannerDisclaimerText) = true
        m.disclaimer.text = itemContent.bannerDisclaimerText
        m.disclaimer.scale = [1, 1]
      end if
    else
      if itemContent.bannerTextRegistered <> invalid
        titleText = itemContent.bannerTextRegistered
      end if
    end if

    if itemContent.airDateTime <> invalid
      airDatetime = CreateObject("roDateTime")
      airDatetime.FromISO8601String(itemContent.airDateTime)
      airDatetime.toLocalTime()

      if FindMemberFunction(airDatetime, "asDateStringLoc") <> invalid
        titleText = titleText.replace("{date}", airDatetime.asDateStringLoc("MMM d"))
      else
        titleText = titleText.replace("{date}", airDatetime.asDateString("no-weekday"))
      end if
    end if
    m.title.text = titleText
    m.title.translation = [(m.top.width / 2) - (m.title.width / 2), 0]
    titleHeight = m.title.boundingRect().height
    m.disclaimer.translation = [0, titleHeight + 4]

    textGroupHeight = m.textGroup.boundingRect().height
    m.textGroup.translation = [0, (m.top.height / 2) - (textGroupHeight / 2)]
  end if
End Function
