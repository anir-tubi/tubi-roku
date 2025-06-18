Function init()
  m.poster = m.top.findNode("Poster")
  m.badgeGroup = m.top.findNode("badgeGroup")
  m.progressBar = m.top.findNode("progressBar")
  m.top.observeField("itemContent", "onContentChange")
  m.top.observeFieldScoped("height", "onPosterSizeChange")
  m.top.observeFieldScoped("width", "onPosterSizeChange")

  if m.global <> invalid
    m.global.observeFieldScoped("refreshLinearChannels", "onRefreshLinearChannels")
  end if

  m.BadgeTypes = {
    live: "live"
    onNow: "onNow"
    tomorrow: "tomorrow"
    today: "today"
    tonight: "tonight"
    language: "language"
  }

  m.languages = {
    spanish: "ESPAÑOL"
    french: "FRANÇAIS"
  }

  setThemeColors()
End Function


Function onRefreshLinearChannels()
  itemContent = m.top.itemContent
  updateItemContent(itemContent)
End Function


Function setThemeColors()
  theme = getThemeFromGlobal()

  if theme <> invalid
    m.primaryTextColor = theme.primarytextcolor
    m.focused2Color = theme.focused2color
    m.neutralSolidColor = theme.neutralsolidcolor
    m.blueBadgeColor = theme.bluebadgecolor

    m.progressBar.focusColor = theme.focusedcolor
    m.progressBar.trackColor = theme.neutralcolor
    m.progressBar.unfocusColor = theme.focusedcolor
  end if
End Function


Function onContentChange(msg)
  itemContent = msg.getData()
  updateItemContent(itemContent)
End Function


Function updateItemContent(itemContent)
  removeBadges()
  sPosterURL = ""

  if itemContent <> invalid
    sPosterURL = itemContent.hdgridposterurl

    if itemContent.needsLogin = true
      setLockIcon()
    else
      removeLockIcon()
    end if

    currentProgram = getCurrentliveProgram(itemContent)

    if currentProgram <> invalid
      if isNonEmptyString(currentProgram.hdgridposterurl) = true
        sPosterURL = currentProgram.hdgridposterurl
      end if

      'make sure to add language badges before other badges
      if itemContent.language <> invalid
        setBadge(m.badgeTypes.language, itemContent.language)
      end if

      if currentProgram.live = true
        setBadge(m.badgeTypes.live)
      else
        ' TODO Add other badges like today/tomorrow etc
        setBadge(m.badgeTypes.onNow)
      end if

      progress = getLinearProgramProgress(currentProgram)
      setProgressBar(progress)
    else 'showing channel info
      m.progressBar.visible = false
      setBadge(m.badgeTypes.onNow)
    end if
  end if

  m.poster.uri = sPosterURL
End Function


Function setProgressBar(progress)
  m.progressBar.progress = progress
  m.progressBar.visible = true
End Function


Function onPosterSizeChange()
  m.progressBar.width = (m.top.width - 32) ' 16 left + 16 right margin
  m.progressBar.height = 8
  translationY = m.top.height - 24
  m.progressBar.translation = [16, translationY]
End Function


Function onHandleFocus()
  focusPercent = m.top.focusPercent
  if m.lockIcon <> invalid
    if focusPercent > 0.1 AND (m.top.rowHasFocus = true OR m.top.itemHasFocus = true)
      m.lockIcon.opacity = focusPercent
    else
      m.lockIcon.opacity = 0.0
    end if
  end if
End Function

'@badgeType - string, Indicating format of the badge
'@badgeText - string, Indicating text on the badge
Function setBadge(badgeType = "live", badgeText = "")

  if badgeType = m.badgeTypes.live
    badge = m.badgeGroup.createChild("Badge")
    badge.backgroundColor = m.focused2Color
    badge.textColor = m.primaryTextColor
    badge.iconUri = "pkg:/images/live-icon-filled.webp"
    badge.text = UCase(getTranslation("screenSearch_liveText"))
  else if badgeType = m.badgeTypes.onNow
    badge = m.badgeGroup.createChild("Badge")
    badge.backgroundColor = m.blueBadgeColor
    badge.textColor = m.primaryTextColor
    badge.text = UCase(getTranslation("onNow"))
  else if badgeType = m.badgeTypes.language
    if badgeText <> ""
      lang = Ucase(badgeText)
      if lang <> "ENGLISH"
        badge = m.badgeGroup.createChild("Badge")
        badge.backgroundColor = m.neutralSolidcolor
        badge.textColor = m.primaryTextColor
        badge.text = m.languages[lang]
      end if
    end if
  end if

  translationX = m.top.width - m.badgeGroup.boundingRect().width - 16
  translationY = m.top.height - 76
  m.badgeGroup.translation = [translationX, translationY]

End Function


Function removeBadges()
  childCount = m.badgeGroup.getChildCount()
  m.badgeGroup.removeChildrenIndex(childCount, 0)
End Function


Function setLockIcon()

  if m.lockIcon = invalid
    m.lockIcon = m.top.createChild("Poster")
    m.lockIcon.opacity = 0.0
    m.lockIcon.width = 48
    m.lockIcon.height = 48
    m.lockIcon.uri = "pkg:/images/icon-lock.webp"
    m.lockIcon.translation = [m.top.width - 56, 8]
    m.top.observeFieldScoped("focusPercent", "onHandleFocus")
    m.top.observeFieldScoped("rowHasFocus", "onHandleFocus")
    m.top.observeFieldScoped("itemHasFocus", "onHandleFocus")
  end if
End Function


Function removeLockIcon()
  if m.lockIcon <> invalid
    m.top.removeChild(m.lockIcon)
    m.lockIcon = invalid
    m.top.unObserveFieldScoped("focusPercent")
    m.top.unObserveFieldScoped("rowHasFocus")
    m.top.unObserveFieldScoped("itemHasFocus")
  end if
End Function
