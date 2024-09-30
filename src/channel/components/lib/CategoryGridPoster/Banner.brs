Function init()
  topRef = m.top
  m.poster = topRef.findNode("poster")
  m.title = topRef.findNode("title")
  m.titleImage = topRef.findNode("titleImage")
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

    if isNonEmptyString(itemContent.bannerTitleImageUrl) = true
      m.titleImage.uri = itemContent.bannerTitleImageUrl

      if itemContent.needsLogin = true
        m.titleImage.translation = [132, 27]
      else
        m.titleImage.translation = [60, 27]
      end if

    end if

    if itemContent.needsLogin = true
      setLockIcon()
      m.title.text = getTranslation("registration_signIn_to_play_hint")
    else
      removeLockIcon()
      if itemContent.airDate <> invalid
        airDatetime = CreateObject("roDateTime")
        airDatetime.FromISO8601String(itemContent.airDate)
        airDatetime.toLocalTime()
        dateString = airDatetime.asDateStringLoc("MMM d")
        m.title.text = getTranslation("watch_for_free", {"date": dateString})
      end if
    end if
    m.title.translation = [(m.top.width / 2) - (m.title.width / 2), 0]
  end if
End Function


Function setLockIcon()
  if m.lockIcon = invalid
    m.lockIcon = m.top.createChild("Poster")
    m.lockIcon.width = 60
    m.lockIcon.height = 60
    m.lockIcon.uri = "pkg:/images/icon-lock.webp"
    m.lockIcon.translation = [32, (m.top.height / 2) - 30]
  end if
End Function


Function removeLockIcon()
  if m.lockIcon <> invalid
    m.top.removeChild(m.lockIcon)
    m.lockIcon = invalid
  end if
End Function
