' VideoMetadataMixin.brs
' Common video metadata functionality for content display components


' Converts seconds to a formatted hour/minute string
' Examples: "2h 30m", "1 h", "45 min"
' Note: Not using translation for better performance since h and m are same in all languages
' @param seconds - Integer, duration in seconds
' @return String - Formatted duration string (e.g., "2h 30m", "1h", "45m")
Function convertSecondsToHoursString(seconds as Integer) as String
  retVal = ""

  if seconds <> invalid
    hourValue = Int(seconds / 3600)
    minValue = Int(seconds / 60) mod 60

    if hourValue > 0 AND minValue > 0
      retVal = Substitute("{0}h {1}m", hourValue.toStr(), minValue.toStr())
    else if hourValue > 0
      retVal = Substitute("{0} h", hourValue.toStr())
    else
      if minValue < 1
        minValue = 1
      end if
      retVal = Substitute("{0} min", minValue.toStr())
    end if
  end if

  return retVal
End Function


' Calculates remaining time for a live program
' Compares program end time with current time to determine how much time is left
' @param program - AssocArray, program object with endTime field
' @return String - Formatted time left string, or empty string if program has ended or endTime is invalid
Function calculateProgramTimeLeft(program as Object) as String
  retVal = ""
  now = getCurrentLocalTime()

  if isInt(program.endTime) = true AND program.endTime > now
    timeLeft = program.endTime - now
    retVal = convertSecondsToTimeLeftString(timeLeft)
  end if

  return retVal
End Function


' Calculates total duration of a program
' Computes difference between program end time and start time
' @param program - AssocArray, program object with startTime and endTime fields
' @return String - Formatted duration string (e.g., "2h 30m"), or empty string if times are invalid
Function calculateProgramTime(program as Object) as String
  retVal = ""

  if isInt(program.endTime) = true AND isInt(program.startTime) = true
    duration = program.endTime - program.startTime
    retVal = convertSecondsToHoursString(duration)
  end if

  return retVal
End Function
