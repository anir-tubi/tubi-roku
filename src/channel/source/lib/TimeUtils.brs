
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

