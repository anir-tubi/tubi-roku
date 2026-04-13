' Self-configuring availability badge for linear content.
' Accepts either itemContent (to auto-derive availability) or a badgeInfo AA.
' Handles all styling, colors, and experiment logic internally.
' Refreshes on a timer while an event is upcoming (same cadence as LiveEventsContainer).
Function init()
  topRef = m.top
  m.badgeRefreshTimer = topRef.findNode("badgeRefreshTimer")
  m.badgeRefreshTimer.duration = 60
  m.badgeRefreshTimer.observeFieldScoped("fire", "onBadgeRefreshTimerFired")
  topRef.observeFieldScoped("itemContent", "onItemContentChange")
End Function


' Derives availability from itemContent — uses scheduleData if present, otherwise getCurrentLiveProgram
Function onItemContentChange(msg) as Void
  itemContent = msg.getData()
  refreshAvailabilityFromItemContent(itemContent)
  updateBadgeRefreshTimer()
End Function


' Recomputes badge from itemContent (also used by the periodic refresh timer).
Function refreshAvailabilityFromItemContent(itemContent) as Void
  if itemContent = invalid
    applyAvailabilityStyle(invalid)
    return
  end if

  if itemContent.scheduleData <> invalid
    isReplay = (itemContent.isReplay = true)
    badgeInfo = getLinearContentBadgeInfo(itemContent.scheduleData, isReplay)
  else
    currentProgram = getCurrentLiveProgram(itemContent)
    if currentProgram <> invalid AND currentProgram.live = true
      badgeInfo = { availability: "live" }
    else
      badgeInfo = { availability: "onNow" }
    end if
  end if

  applyAvailabilityStyle(badgeInfo)
End Function


' Starts a 60s refresh timer while start time is still in the future (countdown / pre-live UI).
Function updateBadgeRefreshTimer() as Void
  if m.badgeRefreshTimer = invalid
    return
  end if

  m.badgeRefreshTimer.control = "stop"
  itemContent = m.top.itemContent
  if isNode(itemContent) = false OR itemContent.scheduleData = invalid OR isNonEmptyString(itemContent.scheduleData.startTime) = false
    return
  end if

  currentDatetime = CreateObject("roDateTime")
  airDatetime = CreateObject("roDateTime")
  airDatetime.FromISO8601String(itemContent.scheduleData.startTime)
  secondsUntilAirTime = airDatetime.asSeconds() - currentDatetime.asSeconds()
  if secondsUntilAirTime > 0
    m.badgeRefreshTimer.control = "start"
  end if
End Function


Function onBadgeRefreshTimerFired(_msg) as Void
  refreshAvailabilityFromItemContent(m.top.itemContent)
  updateBadgeRefreshTimer()
End Function


' Applies colors, background, icon, text, and experiment overrides based on availability
Function applyAvailabilityStyle(badgeInfo) as Void
  topRef = m.top
  if badgeInfo = invalid
    topRef.visible = false
    topRef.isConfigured = false
    return
  end if

  theme = getThemeFromGlobal()
  availability = badgeInfo.availability

  topRef.textColor = theme.primaryTextColor
  topRef.borderUri = ""
  topRef.iconUri = ""
  topRef.visible = true

  if availability = "live"
    topRef.backgroundColor = "#FFFFFFFF"
    topRef.backgroundUri = "pkg:/images/rounded-rect-live-$$RES$$.9.png"
    topRef.iconUri = "pkg:/images/live-icon-filled.webp"
    topRef.text = getTranslation("screenSearch_liveText")
  else if availability = "onNow"
    topRef.backgroundUri = "pkg:/images/rounded-rect-on-now-$$RES$$.9.png"
    if badgeInfo.badgeText <> invalid AND badgeInfo.badgeText <> ""
      topRef.text = badgeInfo.badgeText
    else
      topRef.text = getTranslation("onNow")
    end if
  else if availability = "upcoming" OR availability = "replay"
    topRef.backgroundColor = theme.shadeColor
    topRef.backgroundUri = "pkg:/images/rounded-background-$$RES$$.9.png"
    topRef.text = badgeInfo.badgeText
  else
    topRef.textColor = theme.neutralSolidColor
    topRef.backgroundColor = theme.primaryTextColor
    topRef.text = badgeInfo.badgeText
  end if

  topRef.isConfigured = true
End Function
