'******************************************************
'
'returns time offset for testing purposes if it has been specified
'******************************************************

Function getTestingTimeOffset(constants) as Integer
  if constants <> invalid AND constants.settings.mode <> "production" AND isNumber(constants.settings.testingTimeOffset) = true then
    return constants.settings.testingTimeOffset
  end if
  return 0
End Function


'******************************************************
'
'returns current time in UTC seconds with the testing offset if it has been set
'******************************************************

Function getCurrentUTCTimeWithOffset(constants) as Integer
  now = createObject("roDateTime")
  return now.asSeconds() + getTestingTimeOffset(constants)
End Function


'******************************************************
'
'returns current time in UTC seconds with the testing offset if it has been set
'******************************************************

Function getCurrentLocalTimeWithOffset(constants) as Integer
  now = createObject("roDateTime")
  now.toLocalTime()
  return now.asSeconds() + getTestingTimeOffset(constants)
End Function
