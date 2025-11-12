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
    startDateTime.ToLocalTime()
    programDate = startDateTime.asDateString("short-date")

    'Find tomorrow
    tomorrowDate = createObject("roDateTime")
    tomorrowDate.fromSeconds(currentTimeAsSeconds + 86400)
    tomorrowDate.ToLocalTime()
    tomorrow = tomorrowDate.asDateString("short-date")

    availabilityType = ""
    if (hasVideoResources = true)
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


' Creates SOT (Signals of Trust) badge nodes from sotInfo data
' @param sotInfo - AssocArray containing sotMetaDataTopLabels and sotMarkers
' @param config - AssocArray with optional styling configuration:
'   - focusedTextColor: color for top label badges (required)
'   - maxWidth: maximum width for badges (required)
'   - bodyMediumStrongFont: font for marker badge (optional)
'   - cautionColor: color for marker badge (optional)
' @return AssocArray with topLabels (array of Badge nodes) and marker (Badge node or invalid)
Function createSOTBadges(sotInfo, config)
  result = {
    topLabels: []
    marker: invalid
  }

  if sotInfo = invalid OR config = invalid then return result

  ' Create top label badges from sotMetaDataTopLabels
  sotTopLabelSignals = sotInfo.sotMetaDataTopLabels
  if isNonEmptyArray(sotTopLabelSignals) = true
    for each signal in sotTopLabelSignals
      topLabel = createObject("roSGNode", "Badge")
      topLabel.text = signal.sotLabelText
      topLabel.iconUri = signal.sotIcon
      topLabel.textColor = config.focusedTextColor
      topLabel.maxWidth = config.maxWidth
      result.topLabels.push(topLabel)
    end for
  end if

  ' Create marker badge from sotMarkers
  sotMarkers = sotInfo.sotMarkers
  if isAA(sotMarkers) = true
    marker = createObject("roSGNode", "Badge")
    marker.id = "sotMarker"
    marker.showBackground = false
    marker.maxWidth = config.maxWidth
    marker.text = sotMarkers.sotLabelText
    marker.iconUri = sotMarkers.sotIcon

    if config.bodyMediumStrongFont <> invalid
      marker.badgeTextFont = config.bodyMediumStrongFont
    end if

    if config.cautionColor <> invalid
      marker.textColor = config.cautionColor
    end if

    result.marker = marker
  end if

  return result
End Function
