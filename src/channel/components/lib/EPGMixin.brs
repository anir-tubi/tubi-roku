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
Function getLinearContentBadgeInfo(schedule = invalid, isReplay = false)
  ' Replays always show the Replay badge regardless of schedule data
  if isReplay = true
    return {
      availability: "replay",
      badgeText: getTranslation("replay")
    }
  end if

  if schedule = invalid
    return invalid
  end if

  currentDatetime = CreateObject("roDateTime")
  airDatetime = CreateObject("roDateTime")
  if schedule.startTime <> invalid AND schedule.endTime <> invalid
    airDatetime.FromISO8601String(schedule.startTime)

    hasEventEnded = isLessThanOrEqualToCurrentTime(schedule.endTime)

    if airDatetime.asSeconds() <= currentDatetime.asSeconds() AND hasEventEnded = false
      return { availability: "live" }
    else if hasEventEnded = false
      if isTomorrow(schedule.startTime)
        return {
          availability: "upcoming",
          badgeText: getTranslation("liveTomorrow")
        }
      else if isToday(schedule.startTime)
        localAir = CreateObject("roDateTime")
        localAir.FromISO8601String(schedule.startTime)
        localAir.toLocalTime()
        minuteValue = localAir.getMinutes()
        if minuteValue = 0
          formattedTime = UCase(localizedTimeString(localAir, "h a"))
        else
          formattedTime = UCase(localizedTimeString(localAir, "h:mm a"))
        end if
        return {
          availability: "upcoming",
          badgeText: getTranslation("live_time", { "time": formattedTime })
        }
      else
        airDatetime.toLocalTime()
        if FindMemberFunction(airDatetime, "asDateStringLoc") <> invalid
          formattedDate = airDatetime.asDateStringLoc("MMM d")
        else
          formattedDate = airDatetime.asDateString("short-date")
        end if
        return {
          availability: "upcoming",
          badgeText: getTranslation("live_date", { "date": formattedDate })
        }
      end if
    end if
  end if

  return invalid
End Function


' Resolves a network logo URI from content node fields.
' Priority: creatorTensorApp.images.title_art > scheduleData.channelLogo > inlineLogoUri > empty string
' @param content: roSGNode or AA containing creatorTensorApp and/or scheduleData
' @return: string, the resolved logo URI or empty string
Function resolveNetworkLogoUriFromContent(content) as String
  if content = invalid then return ""

  creatorApp = content.creatorTensorApp
  if isAA(creatorApp) AND isAA(creatorApp.images) AND isNonEmptyArray(creatorApp.images.title_art)
    return creatorApp.images.title_art[0]
  end if

  scheduleData = content.scheduleData
  if isAA(scheduleData) AND isNonEmptyString(scheduleData.channelLogo)
    return scheduleData.channelLogo
  end if

  if isNonEmptyString(content.inlineLogoUri)
    return content.inlineLogoUri
  end if

  return ""
End Function
