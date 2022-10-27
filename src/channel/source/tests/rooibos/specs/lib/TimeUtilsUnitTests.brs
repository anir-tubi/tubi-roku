'@TestSuite [TimeUtils] TimeUtils.brs

'@Setup
Function TimeUtilsSetup()
End Function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in TimeUtils.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test getCurrentUTCTime unit tests
Function timeUtils_getCurrentUTCTime_test()
  dt = CreateObject("roDateTime")
  now = dt.AsSeconds()
  diff = getCurrentUTCTime(invalid) - now
  ' check if current time retured by getCurrentUTCTime is very close to current time
  m.AssertTrue(diff < 2)
End Function


'@Test getCurrentLocalTime unit tests
Function timeUtils_getCurrentLocalTime_test()
  dt = CreateObject("roDateTime")
  dt.ToLocalTime()
  now = dt.AsSeconds()
  diff = getCurrentLocalTime(invalid) - now

  'Check if local Time returned by getCurrentLocalTime is very close to current time
  m.AssertTrue(diff < 2)
End Function


'@Test convertSecondsToMins unit tests
Function timeUtils_convertSecondsToMins_test()
  mins = CreateObject("roInt") ' Interface equivalent for intrinsic type 'Integer' which is the return type of function
  mins.setInt(90 / 60)
  totalmins = convertSecondsToMins(90)
  m.AssertEqual(mins+1,totalmins)

  mins.setInt(0)
  totalmins = convertSecondsToMins(0)
  m.AssertEqual(mins+1, totalmins)

  mins.setInt(123456789 / 60)
  totalmins = convertSecondsToMins(123456789)
  m.AssertEqual(mins+1, totalmins)


  mins.SetInt(-90/60)
  totalmins = convertSecondsToMins(-90)
  m.AssertEqual(mins+1, totalmins)


End Function


'@Test getNumberOfDaysSinceEpoch unit tests
Function timeUtils_getNumberOfDaysSinceEpoch_test()
  dt = CreateObject("roDateTime")
  secondsFromEpoch = dt.AsSeconds()
  daysFromEpoch = Int(secondsFromEpoch / 60 / 60 / 24)
  diff = getNumberOfDaysSinceEpoch() - daysFromEpoch

  'Check if no of epoch days returned by getNumberOfDaysSinceEpoch is equal to the epoch Days to now
  m.assertEqual(daysFromEpoch, getNumberOfDaysSinceEpoch())

  daysFromEpoch = 19067 'March 16, 2022
  diff = getNumberOfDaysSinceEpoch() - daysFromEpoch

  'Check if no of epoch days returned by getNumberOfDaysSinceEpoch is greater than to the epoch Days to March 16, 2022
  m.AssertTrue(diff > 0)

End Function


'@Test getCurrentYear unit tests
Function timeUtils_getCurrentYear_test()
  m.assertEqual(createObject("roDateTime").getYear(), getCurrentYear())
End Function
