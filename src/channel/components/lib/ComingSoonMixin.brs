
' Based on the passed contentNode, is the content not available yet? Is it coming soon?
' @param {TubiContentNode} content - The content object to check for coming soon status
Function isComingSoonContent(content) as Boolean
  if content <> invalid AND (content.type = "video" OR content.type = "series")
    return isComingSoonBasedOnDate(content.availabilityStarts) = true
  else
    return false
  end if
End Function


' Returns the formatted "Coming {date}" label string for a given availability start date.
' Centralizes the date-formatting logic shared by InfoPanel, ExpandedTileMetadata, and video tiles.
' @param {string} availabilityStarts - The date in ISO 8601 format: eg. "2019-03-31T00:00:00Z"
' @returns {string} Translated label, e.g. "Coming Mar 31"
Function getComingSoonText(availabilityStarts as String) as String
  startDateTime = CreateObject("roDateTime")
  startDateTime.FromISO8601String(availabilityStarts)
  startDateTime.ToLocalTime()

  month = startDateTime.GetMonth()
  day = startDateTime.GetDayOfMonth().toStr()
  '::TODO:: Use localized full month day format when available: version Roku OS 12.0
  ' sComingSoonDate = startDateTime.asDateStringLoc("MMMM d")
  sComingSoonDate = getTranslation("short_version_date_wo_year_format_" + month.toStr(), { day: day })
  return getTranslation("info_panel_coming_soon", { date: sComingSoonDate })
End Function


' Based on the passed date, is the content not available yet? Is it coming soon?
' @param {string} availabilityStarts - The date in string ISO 8601 format: eg. "2019-03-31T00:00:00Z"
Function isComingSoonBasedOnDate(availabilityStarts) as Boolean
  if availabilityStarts <> invalid
    startDateTime = CreateObject("roDateTime")
    startDateTime.FromISO8601String(availabilityStarts)
    startDateTime.ToLocalTime()
    startTimeInSeconds = startDateTime.asSeconds()

    now = getCurrentLocalTime()
    if startTimeInSeconds > now
      return true
    end if
  end if

  return false
End Function