Function init()
  topRef = m.top
  m.elementsGroup = topRef.findNode("elementsGroup")
  m.airDate = topRef.findNode("airDate")
  m.day = topRef.findNode("day")
  m.minute = topRef.findNode("minute")
  m.hour = topRef.findNode("hour")

  m.dateText = topRef.findNode("dateText")
  m.dayText = topRef.findNode("dayText")
  m.hourText = topRef.findNode("hourText")
  m.minuteText = topRef.findNode("minuteText")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.dateText, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.dayText, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.hourText, typographyConstants.ids.bodyExtraSmallStrong)
  setTypographyOfLabel(m.minuteText, typographyConstants.ids.bodyExtraSmallStrong)

  topRef.observeField("airDateTime", "updateUI")
  topRef.observeFieldScoped("timerShouldRun", "onTimerShouldRun")

  m.timer = CreateObject("roSGNode", "Timer")
  m.timer.duration = 60
  m.timer.observeFieldScoped("fire", "updateUI")

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.hour.blendColor = theme.focusedColor
    m.minute.blendColor = theme.focusedColor
    m.day.blendColor = theme.focusedColor

    m.dateText.color = theme.backgroundColor
    m.dayText.color = theme.backgroundColor
    m.hourText.color = theme.backgroundColor
    m.minuteText.color = theme.backgroundColor
  end if
End Function


Function updateUI()
  data = m.top.airDateTime
  currentDatetime = CreateObject("roDateTime")
  currentDatetime.toLocalTime()
  currentMonth = currentDatetime.getMonth()
  currentDayOfMonth = currentDatetime.getDayOfMonth()

  airDatetime = CreateObject("roDateTime")
  airDatetime.FromISO8601String(data)
  airDatetime.toLocalTime()

  airDateMonth = airDatetime.GetMonth()
  if airDateMonth < 10
    monthStr = "0" + airDateMonth.toStr()
  else
    monthStr = airDateMonth.toStr()
  end if

  airDateDay = airDatetime.getDayOfMonth()
  if airDateDay < 10
    dayStr = "0" + airDateDay.toStr()
  else
    dayStr = airDateDay.toStr()
  end if

  ' Checking if the current day and air date are same.
  if airDateMonth = currentMonth AND airDateDay = currentDayOfMonth
    formattedTime = airDatetime.asTimeStringLoc("h:mm a")
    m.dateText.text = getTranslation("live_on_date_today", {"time": formattedTime})
  else
    m.dateText.text = getTranslation("live_on_date", {"month": monthStr, "day": dayStr})
  end if

  remainingDays = airDateDay - currentDayOfMonth
  secondsUntilAirTime = airDatetime.asSeconds() - currentDatetime.asSeconds()
  
  if secondsUntilAirTime > 0
    if remainingDays > 0
      remainingSeconds = secondsUntilAirTime mod 86400
      hour = Cint(remainingSeconds / 3600)
  
      remainingSeconds = secondsUntilAirTime mod 3600
      minutes = Cint(remainingSeconds / 60)
      
      if remainingDays < 10
        m.dayText.text = getTranslation("live_on_day", {"day": remainingDays.toStr()})
      else
        m.dayText.text = getTranslation("live_on_day", {"day": "0" + remainingDays.toStr()})
      end if
  
      m.hourText.text = getTranslation("live_on_hour", {"hour": hour.toStr()})
      m.minuteText.text = getTranslation("live_on_minute", {"min": minutes.toStr()})
    else
      m.elementsGroup.removeChild(m.day)
      
      hour = Cint(secondsUntilAirTime / 3600)
      minutes = Cint(secondsUntilAirTime / 60)
  
      if hour > 0
        m.hourText.text = getTranslation("live_on_hour", {"hour": hour.toStr()})
      else
        m.elementsGroup.removeChild(m.hour)
      end if
      
      ' If both hour and minute is zero removing the minute.
      if minutes > 0 OR hour > 0
        m.minuteText.text = getTranslation("live_on_minute", {"min": minutes.toStr()})
      else
        m.elementsGroup.removeChild(m.minute)
      end if
    end if
    
    padding = 32
  
    textWidth = m.dateText.boundingRect().width
    m.airDate.width = textWidth + padding
    m.dateText.translation = [(m.airDate.width / 2) - (textWidth / 2) , 0]
  
    textWidth = m.dayText.boundingRect().width
    m.day.width = textWidth + padding
    m.dayText.translation = [(m.day.width / 2) - (textWidth / 2) , 0]
  
    textWidth = m.hourText.boundingRect().width
    m.hour.width = textWidth + padding
    m.hourText.translation = [(m.hour.width / 2) - (textWidth / 2) , 0]
  
    textWidth = m.minuteText.boundingRect().width
    m.minute.width = textWidth + padding
    m.minuteText.translation = [(m.minute.width / 2) - (textWidth / 2) , 0]
  
    m.timer.control = "stop"
    m.timer.control = "start"
  else
    m.top.visible = false
  end if
End Function


' The purpose creating a variable timerShouldRun and having this called is control when to start and stop the refresh timer to update the countdown.
' To avoid us from updating the countdown unnecessarily when the purple carpet container for ex is hidden may be due to user navigating to other page or navigating down to other rows.
' timerShouldRun field will be set to true whenever the purple carpet container becomes visible.
Function onTimerShouldRun(msg)
  m.timer.control = "stop"
  timerShouldRun = msg.getData()
  if timerShouldRun = true
    m.timer.control = "start"
  end if
End Function
