Function init()
  topRef = m.top
  m.nodeHelpers = TubiNodeHelpers()
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
  airDateDay = airDatetime.getDayOfMonth()

  ' Checking if the current day and air date are same.
  if airDateMonth = currentMonth AND airDateDay = currentDayOfMonth
    formattedTime = airDatetime.asTimeStringLoc("h:mm a")
    m.dateText.text = getTranslation("live_on_date_today", {"time": formattedTime})
  else
    formattedMonth = airDatetime.asDateStringLoc("MMM")
    formattedMonth = UCase(formattedMonth)

    formattedDay = airDatetime.asDateStringLoc("d")
    
    m.dateText.text = getTranslation("live_on_date", {"day": formattedDay, "month": formattedMonth})
  end if

  secondsUntilAirTime = airDatetime.asSeconds() - currentDatetime.asSeconds()
  if secondsUntilAirTime > 0
    
    ' Finding difference between dates in number of days.
    remainingDays = Fix(secondsUntilAirTime / 86400)

    ' Adding a check to see if it just 24 hours and some minutes so that we do not display like 1 day and 30 mins instead display 24 hours and 30 mins.
    remainingHours = Fix(secondsUntilAirTime / 3600)

    remainingSeconds = secondsUntilAirTime mod 86400
    hour = Fix(remainingSeconds / 3600)
    remainingSeconds = secondsUntilAirTime mod 3600

    ' If the remainingSeconds is less than 60 seconds than using fix will cause the minutes to zero for like 50 seconds etc.
    if remainingSeconds > 60
      minutes = Fix(remainingSeconds / 60)
    else if remainingSeconds > 0
      ' Making sure until the seconds becomes zero we will still display 1 min since we do not have seconds component.
      minutes = 1
    else
      minutes = 0
    end if

    ' Position of components within the elementsgroup
    ' 0 - air date string for ex: displays like LIVE ON SEP 28
    ' 1 - remaining days until the air date
    ' 2 - remaining hours until the air date
    ' 3 - remaining minutes until the air date.

    ' Since we re-use the same info panel between different items and we remove the fields if we do not have values we need to make sure they are added if needed.
    if remainingDays > 0 AND remainingHours >= 24
      if m.nodeHelpers.getChildIndex(m.elementsGroup, m.day) = -1
        m.elementsGroup.insertChild(m.day, 1)
      end if
      m.dayText.text = getTranslation("live_on_day", {"day": remainingDays.toStr()})
    else
      m.elementsGroup.removeChild(m.day)
    end if
    
    if hour > 0
      if m.nodeHelpers.getChildIndex(m.hour, m.hour) = -1
        m.elementsGroup.insertChild(m.hour, 2)
      end if
      m.hourText.text = getTranslation("live_on_hour", {"hour": hour.toStr()})
    else
      m.elementsGroup.removeChild(m.hour)
    end if

    ' If both hour and minute is zero removing the minute.
    if minutes > 0 OR hour > 0
      if m.nodeHelpers.getChildIndex(m.minute, m.hour) = -1
        m.elementsGroup.insertChild(m.minute, 3)
      end if

      m.minuteText.text = getTranslation("live_on_minute", {"min": minutes.toStr()})
    else
      m.elementsGroup.removeChild(m.minute)
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

    ' Updating the UI along with starting of the timer.
    updateUI()
  end if
End Function
