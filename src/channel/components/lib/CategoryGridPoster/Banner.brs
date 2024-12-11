Function init()
  topRef = m.top
  m.poster = topRef.findNode("poster")
  m.title = topRef.findNode("title")
  topRef.observeFieldScoped("itemContent", "onContentChange")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.title, typographyConstants.ids.bodyMedium)
  setThemeColors()
End Function


Function setThemeColors()
  theme = getThemeFromGlobal()

  if theme <> invalid
    m.title.color = theme.primarytextcolor
  end if
End Function


Function onContentChange(msg)
  itemContent = msg.getData()
  
  if itemContent <> invalid

    if isNonEmptyString(itemContent.hdgridposterurl) = true
      m.poster.uri = itemContent.hdgridposterurl
    end if

    titleText = ""

    if itemContent.needsLogin = true
      if itemContent.bannerTextGuest <> invalid
        titleText = itemContent.bannerTextGuest
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

      titleText = titleText.replace("{date}", airDatetime.asDateStringLoc("MMM d"))
    end if
    m.title.text = titleText
    m.title.translation = [(m.top.width / 2) - (m.title.width / 2), 0]
  end if
End Function
