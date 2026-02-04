
' Based on the passed contentNode, is the content not available yet? Is it coming soon?
' @param {TubiContentNode} content - The content object to check for coming soon status
Function isComingSoonContent(content) as Boolean
  if content <> invalid AND (content.type = "video" OR content.type = "series")
    return isComingSoonBasedOnDate(content.availabilityStarts) = true
  else
    return false
  end if
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