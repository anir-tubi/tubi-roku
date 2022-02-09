
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
' function returns Integer part of result. For exmaple : 60 to 119 seconds will return 1
' return value is casted to roku intrinsic type 'Integer' which returns the integer part of the number which might not be same as Int()
' @param seconds : integer
'******************************************************
Function convertSecondsToMins(seconds As Integer) As Integer 
    mins = fix(seconds / 60)
    return mins
End Function

