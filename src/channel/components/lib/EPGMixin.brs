' This function will return if a linear program is live based on the passed parameter.
' This function requires the importation of source/lib/TimeUtils.brs
' @param program: roSGNode, EPG program node
Function isProgramLive(program)
  now = getCurrentLocalTime()
  if program <> invalid AND program.startTime = 0 AND program.endTime = 0 ' No programs and EPG has single element and click will play live
    return true
  else if program <> invalid AND isInt(program.startTime) AND isInt(program.endTime)
    return program.startTime <= now AND program.endTime > now
  else
    return false
  end if
End Function


' This function will return the current live program of a linear content if it can be found.
' This function requires the importation of source/lib/TimeUtils.brs
' @param content: roSGNode, linear Content node or EPG node
Function getCurrentLiveProgram(content)
  if content <> invalid
    for i = 0 to content.getChildCount() - 1
      program = content.getChild(i)
      if isProgramLive(program) = true
        return program
      end if
    end for
  end if
  return invalid
End Function


Function getLinearProgramProgress(currentProgram)
  now = getCurrentLocalTime()
  if currentProgram <> invalid
    nowPos = now - currentProgram.startTime

    if nowPos <= 0
      return 0
    end if

    duration = currentProgram.endTime - currentProgram.startTime

    if duration <= 0
      return 0
    else
      return (nowPos / duration) * 100
    end if
  end if
  return 0
End Function


' This function will set the badge for the linear content based on the schedule data.
' This function requires the importation of TimeUtils.brs, typeUtils.brs, Log.brs
' @param schedule: roSGNode, EPG program node
' @return: object, containing the badge info.
Function getLinearContentBadgeInfo(schedule)
  currentDatetime = CreateObject("roDateTime")
  airDatetime = CreateObject("roDateTime")
  if schedule.startTime <> invalid AND schedule.endTime <> invalid
    airDatetime.FromISO8601String(schedule.startTime)

    ' Calculating the seconds until the air time.
    secondsUntilAirTime = airDatetime.asSeconds() - currentDatetime.asSeconds()
    hasEventEnded = isLessThanOrEqualToCurrentTime(schedule.endTime)

    if airDatetime.asSeconds() <= currentDatetime.asSeconds() AND hasEventEnded = false
      ' Not using constants to avoid having to access global.
      return { availability: "live" }
    else if secondsUntilAirTime > (7 * 24 * 60 * 60) AND FindMemberFunction(airDatetime, "asDateStringLoc") <> invalid
      airDatetime.toLocalTime()
      formattedDate = airDatetime.asDateStringLoc("MMM d")
      badgeText = getTranslation("starts_date", { "date": formattedDate })
      return {
        availability: "upcoming",
        badgeText: UCase(badgeText)
      }
    else if hasEventEnded = false
      remainingDays = Cint(secondsUntilAirTime / 86400)
      remainingHours = Cint(secondsUntilAirTime / 3600)
      remainingMinutes = Cint(secondsUntilAirTime / 60)

      ' If the total time remaining is less than 60 seconds, display 1 minute since we don't have seconds component
      if secondsUntilAirTime < 60
        remainingMinutes = 1
      end if

      if remainingMinutes < 60
        timeString = getTranslation("m_duration", { "minutes": remainingMinutes.toStr() })
      else if remainingHours < 24
        timeString = getTranslation("h_duration", { "hours": remainingHours.toStr() })
      else
        timeString = getTranslation("d_duration", { "days": remainingDays.toStr() })
      end if

      badgeText = getTranslation("live_in_date", { "timeString": timeString })
      return {
        availability: "upcoming",
        badgeText: UCase(badgeText)
      }
    end if
  end if

  return invalid
End Function


'@badge - node, Badge Component.
'@availability - string, Indicating availability of the event. Possible values of type "live" or "upcoming".
'@textColor - string, Indicating text color of the badge.
'@backgroundColor - string, Indicating background color of the badge.
'@badgeText - string, Indicating text on the badge. Should be passed when we want to use "today" badge type.
Function setLinearAvailabilityBadge(badge, availability, textColor, backgroundColor, badgeText = "")
  if availability = "live"
    badge.text = UCase(getTranslation("screenSearch_liveText"))
    badge.iconUri = "pkg:/images/live-icon-filled.webp"
  else
    badge.text = badgeText
    badge.iconUri = ""
  end if
  badge.backgroundColor = backgroundColor
  badge.textColor = textColor
End Function
