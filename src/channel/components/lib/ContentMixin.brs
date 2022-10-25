' @airDateTime: string, airdatetime from backend
' @hasVideoResources: boolean, true means it has manifest urls
Function getAvailabilityTypeBadgeAndMatchTimeValues(airDateTime = "", hasVideoResources = false)

  dateTimeString = ""
  if isNonEmptyString(airDateTime) = true
    dateTimeString = airDateTime
  end if

  badgeText = ""
  badgeAndInfoPanelValues = {}

  if hasVideoResources = invalid
    hasVideoResources = false
  end if

  if isNonEmptyString(dateTimeString) = true
    'find current time
    currentDateTime = CreateObject("roDateTime")
    currentTimeAsSeconds = currentDateTime.AsSeconds()
    currentDateTime.ToLocalTime()
    today = currentDateTime.asDateString("short-date")

    'Find program start
    startDateTime = CreateObject("roDateTime")
    startDateTime.FromISO8601String(dateTimeString)
    startTimeAsSeconds = startDateTime.AsSeconds()
    startDateTime.ToLocalTime()
    programDate = startDateTime.asDateString("short-date")


    'Find tomorrow
    tomorrowDate = createObject("roDateTime")
    tomorrowDate.fromSeconds(currentTimeAsSeconds + 86400)
    tomorrowDate.ToLocalTime()
    tomorrow = tomorrowDate.asDateString("short-date")

    availabilityType = ""
    if (hasVideoResources = true) AND currentTimeAsSeconds > startTimeAsSeconds
      availabilityType = "replay"
    else
      availabilityType = "upcoming"
    end if

    if availabilityType = "upcoming"
      if programDate = today
        badgeText = getTranslation("today")
      else if programDate = tomorrow
        badgeText = getTranslation("tomorrow")
      else
        date = getMonthAndDay(startDateTime)
        badgeText = UCase(date)
      end if
      badgeAndInfoPanelValues.availabilityType = availabilityType
      badgeAndInfoPanelValues.badgeText = badgeText
      badgeAndInfoPanelValues.matchTime = ""
    else
      date = getMonthAndDayWithYear(startDateTime)
      badgeAndInfoPanelValues.availabilityType = availabilityType
      badgeAndInfoPanelValues.badgeText = getTranslation(availabilityType)
      badgeAndInfoPanelValues.matchTime = date
    end if
  end if

  return badgeAndInfoPanelValues

End Function
