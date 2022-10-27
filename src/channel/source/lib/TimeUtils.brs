'******************************************************
'
'returns time offset for testing purposes if it has been specified
'******************************************************

Function getTestingTimeOffset(constants) as integer
  if constants <> invalid AND constants.settings.mode <> "production" AND isNumber(constants.settings.testingTimeOffset) = true then
    return constants.settings.testingTimeOffset
  end if
  return 0
End Function


'******************************************************
'
'returns current time in UTC seconds
'******************************************************

Function getCurrentUTCTime(constants) as integer
  now = CreateObject("roDateTime")
  return now.AsSeconds() + getTestingTimeOffset(constants)
End Function

'******************************************************
'
'returns current time in UTC seconds
'******************************************************

Function getCurrentLocalTime(constants) as integer
  now = CreateObject("roDateTime")
  now.ToLocalTime()
  return now.AsSeconds() + getTestingTimeOffset(constants)
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
'returns datetime in this format : Dec 15
'******************************************************
Function getMonthAndDay(datetime)
  month = datetime.GetMonth().tostr()
  day = datetime.GetDayOfMonth().tostr()
  shortVersionOfDateFormat = getShortVersionOfDateFormat(month, day)
  ' replacing "," with empty string as the string does not have year.
  return shortVersionOfDateFormat.replace(",","")
End Function


'******************************************************
'returns datetime in this format : Dec 15, 2022
'******************************************************
Function getMonthAndDayWithYear(datetime)
  month = datetime.GetMonth().tostr()
  day = datetime.GetDayOfMonth().tostr()
  year = datetime.getYear().toStr()
  shortVersionOfDateFormat = getShortVersionOfDateFormat(month, day, year)
  return shortVersionOfDateFormat
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
