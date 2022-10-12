' @authInfo: assocArray, authInfo AA as returned by Auth().getAuthInfo()
Function isLoggedInUser(authInfo = invalid)
  if authInfo = invalid
    authInfo = m.global.authInfo
  end if

  return (authInfo <> invalid AND authInfo.userId <> invalid)
End Function


Function isNewUser()

  bNewUser = m.global.isNewUser
  return (bNewUser <> invalid AND bNewUser = true AND isLoggedInUser() = false)

End Function


Function needsToShowAgeVerificationScreen()
  if isLoggedInUser() = true AND m.global.authInfo.hasAge = true then
    return false
  else
    guestUserHasAgeInfo = TubiAuth(m.constants, m.Request).getGuestUserHasAgeInfo()
    ' In the case that the user is logged in but there is no age information associated with the account, hasAge defaults to false.
    if guestUserHasAgeInfo.hasAge = true AND guestUserHasAgeInfo.expired <> true
      return false
    end if
  end if
  return true
End Function


Function isContentLocked(content) as boolean
  'whether content is explicitly locked and user is guest, lock the content
  return (content.needsLogin = true AND isLoggedInUser() = false)
End Function


' @airDateTime: tring, airdatetime from backend
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
        badgeText = date
      end if
      badgeAndInfoPanelValues.availabilityType = availabilityType
      badgeAndInfoPanelValues.badgeText = badgeText
      badgeAndInfoPanelValues.matchTime = ""
    else
      date = getMonthAndDayWithYear(startDateTime)
      badgeAndInfoPanelValues.availabilityType = availabilityType
      badgeAndInfoPanelValues.badgeText = availabilityType
      badgeAndInfoPanelValues.matchTime = date
    end if
  end if

  return badgeAndInfoPanelValues

End Function
