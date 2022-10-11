
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
'returns datetime in this format : DEC 15
'******************************************************
Function getMonthAndDay(datetime)
  month = getShortMonthName(datetime.GetMonth())
  day = datetime.GetDayOfMonth().tostr()
  return UCase(month) + " " + day
End Function


'******************************************************
'returns datetime in this format : DEC 15
'******************************************************
Function getMonthAndDayWithYear(datetime)
  year = datetime.getYear().toStr()
  month = getShortMonthName(datetime.GetMonth())
  day = datetime.GetDayOfMonth().tostr()
  return UCase(month) + " " + day + ", " + year
End Function


'******************************************************
'@month: integer, month as integer. possible values are (1 to 12)
'returns translated month name in shortest version. Eg. Jan
'******************************************************
Function getShortMonthName(month as integer)
  monthName = getTranslation("short_version_month_" + month.tostr())
  return monthName
End Function