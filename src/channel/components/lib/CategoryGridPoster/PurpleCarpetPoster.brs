Function init()
  m.poster = m.top.findNode("Poster")
  m.badgeGroup = m.top.findNode("badgeGroup")
  m.top.observeField("itemContent", "onContentChange")

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

  ' Creating a timer to refresh the Call to actions button since we have badge logic based on whether game is live vs not.
  m.badgeRefreshTimer = CreateObject("roSGNode", "Timer")
  m.badgeRefreshTimer.observeFieldScoped("fire", "updateUIWithBadges")
End Function


Function setThemeColors()
  theme = getThemeFromGlobal()

  if theme <> invalid
    m.primaryTextColor = theme.primaryTextColor
    m.focused2Color = theme.focused2Color
    m.neutralSolidColor = theme.neutralSolidColor
    m.blueBadgeColor = theme.blueBadgeColor
  end if
End Function


Function onContentChange(msg)
  itemContent = msg.getData()
  if itemContent <> invalid
    m.poster.uri = itemContent.hdgridposterurl

    if itemContent.needsLogin = true
      setLockIcon()
    else
      removeLockIcon()
    end if

    updateUIWithBadges()
  end if
End Function


Function updateUIWithBadges()
  removeBadges()
  itemContent = m.top.itemContent
  'TODO: Will be controlled by listing api in future for now using airdate time.
  currentDatetime = CreateObject("roDateTime")
  airDatetime = CreateObject("roDateTime")
  if itemContent.airDatetime <> invalid
    airDatetime.FromISO8601String(itemContent.airDatetime)

    if airDatetime.asSeconds() < currentDatetime.asSeconds()
      setBadge(m.badgeTypes.live)
    end if

    if m.badgeRefreshTimer <> invalid
      secondsUntilAirTime = airDatetime.asSeconds() - currentDatetime.asSeconds()
      if secondsUntilAirTime > 0
        m.badgeRefreshTimer.duration = secondsUntilAirTime
        m.badgeRefreshTimer.control = "stop"
        m.badgeRefreshTimer.control = "start"
      end if
    end if
  end if
End Function


'@badgeType - string, Indicating format of the badge. Possible values "live", "onNow", "language".
'@badgeText - string, Indicating text on the badge. Should be passed when we want to use "language" badge type.
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
    m.lockIcon.width = 48
    m.lockIcon.height = 48
    m.lockIcon.uri = "pkg:/images/icon-lock.webp"
    m.lockIcon.translation = [m.top.width - 56, 8]
  end if
End Function


Function removeLockIcon()
  if m.lockIcon <> invalid
    m.top.removeChild(m.lockIcon)
    m.lockIcon = invalid
  end if
End Function
