'******************************************************
'
'returns current time in UTC seconds
'******************************************************

Function getCurrentUTCTime() as integer
  now = CreateObject("roDateTime")
  return now.AsSeconds()
End Function


'******************************************************
'
'returns current time in UTC seconds
'******************************************************

Function getCurrentLocalTime() as integer
  now = CreateObject("roDateTime")
  now.ToLocalTime()
  return now.AsSeconds()
End Function


'******************************************************
' This functions converts the seconds into mins.
' The function returns the given number of seconds converted to minutes rounded up to the nearest minute.
' For example, passing in 12 would return 1. Passing in 119 would return 2.
' @param seconds : integer
'******************************************************
Function convertSecondsToMins(seconds As Integer) As Integer
  mins = (seconds / 60) + 1
  return fix(mins)
End Function


'******************************************************
'
'returns number of days since Unix epoch
'******************************************************

Function getNumberOfDaysSinceEpoch() as integer
  nowDate = CreateObject("roDateTime")
  secondsFromEpoch = nowDate.AsSeconds()
  daysFromEpoch = Int(secondsFromEpoch / 60 / 60 / 24)
  return daysFromEpoch
End Function


'******************************************************
'returns year for current roDateTime
'******************************************************
Function getCurrentYear()
  dateTime = createObject("roDateTime")
  currentYear = dateTime.getYear()
  return currentYear
End Function


'******************************************************
'@month: string, between 1 and 12
'@day: string, between 1 and 31
'@year: string, year in 4 digit
'returns translated month name, day, year in shortest version. Eg. Nov 25, 2022
'******************************************************
Function getShortVersionOfDateFormat(month = "", day = "", year = "")
  dynamicValues = {
    month: month
    day: day
    year: year
  }
  shortVersionOfDateFormat = getTranslation("short_version_date_format_" + month, dynamicValues)
  return shortVersionOfDateFormat
End Function


'******************************************************
'returns string in this format : Dec 15
'******************************************************
Function getMonthAndDay(datetime)
  month = datetime.GetMonth().toStr()
  day = datetime.GetDayOfMonth().toStr()
  shortVersionOfDateFormat = getShortVersionOfDateFormat(month, day)
  ' replacing "," with empty string as the string does not have year.
  return shortVersionOfDateFormat.replace(",","")
End Function


'******************************************************
'returns string in this format : Dec 15, 2022
'******************************************************
Function getMonthAndDayWithYear(datetime)
  month = datetime.GetMonth().toStr()
  day = datetime.GetDayOfMonth().toStr()
  year = datetime.getYear().toStr()
  shortVersionOfDateFormat = getShortVersionOfDateFormat(month, day, year)
  return shortVersionOfDateFormat
End Function


' Determines if the current time is within the passed in startTime and endTime, inclusive.
' IMPORTANT: The ISO-8601 strings of the params must match the formats documented at
' https://developer.roku.com/en-gb/docs/references/brightscript/interfaces/ifdatetime.md#fromiso8601stringdatestring-as-string-as-void
'
' @startTime: string, an ISO-8601 string representing the earliest time in the period, UTC time
' @endTime: string, an ISO-8601 string representing the latest time in the period, UTC time
Function isNowWithinTimePeriod(startTime, endTime)
  if isIso8601String(startTime) = true AND isIso8601String(endTime) = true
    dateTime = CreateObject("roDateTime")
    nowSeconds = dateTime.AsSeconds()

    dateTime.FromISO8601String(startTime)
    startSeconds = dateTime.AsSeconds()

    dateTime.FromISO8601String(endTime)
    endSeconds = dateTime.AsSeconds()

    if startSeconds <= nowSeconds AND endSeconds >= nowSeconds
      return true
    end if
  end if

  return false
End Function


' @strToCheck: string, hopefully an ISO-861 formatted string as recognized by Roku
'                      ie. in the format "2009-01-01 01:00:00.000" or "2009-01-01T01:00:00.000"
Function isIso8601String(strToCheck)
  ' check we have a string
  if isNonEmptyString(strToCheck) = false
    return false
  end if

  ' Since Z indicates UTC, allowing Z at the end.
  ' Removing it from the end if present so that integer validation at line number 245 does not fail.
  if strToCheck.EndsWith("Z") = true
    strLen = strToCheck.len()
    strToCheck = strToCheck.left(strLen - 1)
  end if

  ' check we have the date and time parts
  dateTimeParts = strToCheck.split(" ")
  if dateTimeParts.count() <> 2
    dateTimeParts = strToCheck.split("T")
    if dateTimeParts.count() <> 2
      return false
    end if
  end if

  ' check the date part is formatted correctly
  date = dateTimeParts[0]
  dateParts = date.split("-")
  if dateParts.count() <> 3
    return false
  end if

  year = dateParts[0]
  month = dateParts[1]
  day = dateParts[2]

  if year.len() <> 4 OR month.len() <> 2 OR day.len() <> 2
    return false
  end if

  ' check that only digits were used. toInt() returns 0 if the string contains letters
  yearChars = year.split("")
  monthChars = month.split("")
  dayChars = day.split("")
  allDateChars = []
  allDateChars.append(yearChars)
  allDateChars.append(monthChars)
  allDateChars.append(dayChars)
  for each char in allDateChars
    asciiVal = Asc(char)
    if asciiVal < 48 OR asciiVal > 57
      return false
    end if
  end for

  if month.toInt() < 1 OR month.toInt() > 12
    return false
  end if

  if day.toInt() < 1 OR day.toInt() > 31
    return false
  end if

  ' check the time part is formatted correctly
  time = dateTimeParts[1]
  timeParts = time.split(":")
  if timeParts.count() <> 3
    return false
  end if

  hours = timeParts[0]
  minutes = timeParts[1]
  seconds = timeParts[2]

  hoursChars = hours.split("")
  minutesChars = minutes.split("")
  allTimeChars = []
  allTimeChars.append(hoursChars)
  allTimeChars.append(minutesChars)

  if hours.len() <> 2 OR minutes.len() <> 2
    return false
  end if

  if hours.toInt() < 0 OR hours.toInt() > 24
    return false
  end if

  if minutes.toInt() < 0 OR minutes.toInt() > 59
    return false
  end if

  ' check the seconds and milliseconds are formatted correctly
  secsAndMillis = seconds.split(".")
  if secsAndMillis.count() < 1 OR secsAndMillis.count() > 2
    return false
  end if

  secs = secsAndMillis[0]
  if secs.len() <> 2
    return false
  end if

  if secs.toInt() < 0 OR secs.toInt() > 59
    return false
  end if

  secondsChars = secs.split("")
  allTimeChars.append(secondsChars)

  if secsAndMillis.count() = 2
    milliseconds = secsAndMillis[1]
    millisecondsChars = milliseconds.split("")
    allTimeChars.append(millisecondsChars)
  end if

  ' check that only digits were used. toInt() returns 0 if the string contains letters
  for each char in allTimeChars
    asciiVal = Asc(char)
    if asciiVal < 48 OR asciiVal > 57
      return false
    end if
  end for

  return true
End Function


' Determines if the input date is greater than current time.
' IMPORTANT: The ISO-8601 strings of the params must match the formats documented at
' https://developer.roku.com/en-gb/docs/references/brightscript/interfaces/ifdatetime.md#fromiso8601stringdatestring-as-string-as-void
'
' @dateString: string, an ISO-8601 string representing the UTC time to check against the current UTC time
Function isGreaterThanCurrentTime(dateString)
  if isIso8601String(dateString) = true
    dateTime = CreateObject("roDateTime")
    nowSeconds = dateTime.AsSeconds()

    dateTime.FromISO8601String(dateString)
    dateSeconds = dateTime.AsSeconds()

    return dateSeconds > nowSeconds
  end if

  return false
End Function


' Compares 2 dates. Returns true if dateString1 is later than dateString2
' IMPORTANT: The ISO-8601 strings of the params must match the formats documented at
' https://developer.roku.com/en-gb/docs/references/brightscript/interfaces/ifdatetime.md#fromiso8601stringdatestring-as-string-as-void
'
' @dateString1: string, an ISO-8601 string representing the UTC time
' @dateString2: string, an ISO-8601 string representing the UTC time
Function compareDates(dateString1, dateString2)
  if isIso8601String(dateString1) = true AND isIso8601String(dateString2) = true
    dateTime = CreateObject("roDateTime")
    dateTime.FromISO8601String(dateString1)
    nowSeconds1 = dateTime.AsSeconds()

    dateTime.FromISO8601String(dateString2)
    nowSeconds2 = dateTime.AsSeconds()

    return nowSeconds1 > nowSeconds2
  end if

  return false
End Function


' Determines if the input date is current day. That is the month and day of the input date is same as current date.
' @dateString: string, an ISO-8601 string representing the UTC time
Function isToday(dateString)
  if isIso8601String(dateString) = true
    currentDatetime = CreateObject("roDateTime")
    currentDatetime.toLocalTime()
    currentMonth = currentDatetime.getMonth()
    currentDayOfMonth = currentDatetime.getDayOfMonth()

    inputDatetime = CreateObject("roDateTime")
    inputDatetime.FromISO8601String(dateString)
    inputDatetime.toLocalTime()

    inputDateMonth = inputDatetime.GetMonth()
    inputDateDay = inputDatetime.getDayOfMonth()

    return inputDateMonth = currentMonth AND inputDateDay = currentDayOfMonth
  end if

  return false
End Function
