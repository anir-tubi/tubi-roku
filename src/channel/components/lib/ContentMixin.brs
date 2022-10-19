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
    startDateTime = CreateObject("roDateTime")
    startDateTime.FromISO8601String(dateTimeString)
    startDateTime.ToLocalTime()
    startTimeAsSeconds = startDateTime.AsSeconds()
    programYear = startDateTime.GetYear()
    programMonth = startDateTime.GetMonth()
    programDay = startDateTime.GetDayOfMonth()

    currentDateTime = CreateObject("roDateTime")
    currentDateTime.ToLocalTime()
    currentTimeAsSeconds = currentDateTime.AsSeconds()
    currentYear = currentDateTime.GetYear()
    currentMonth = currentDateTime.GetMonth()
    today = currentDateTime.GetDayOfMonth()

    availabilityType = ""
    if (hasVideoResources = true) AND currentTimeAsSeconds > startTimeAsSeconds
      availabilityType = "replay"
    else
      availabilityType = "upcoming"
    end if

    currentDateTime.FromSeconds(currentDateTime.AsSeconds() + 86400)
    tomorrow = currentDateTime.GetDayOfMonth()

    if availabilityType = "upcoming"
      if programDay = today AND programMonth = currentMonth AND programYear = currentYear
        badgeText = getTranslation("today")
      else if programDay = tomorrow
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
