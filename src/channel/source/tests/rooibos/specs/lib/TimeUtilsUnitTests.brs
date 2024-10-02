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
  diff = getCurrentUTCTime() - now
  ' check if current time returned by getCurrentUTCTime is very close to current time
  m.AssertTrue(diff < 2)
End Function


'@Test getCurrentUTCTimeWithOffset unit tests
Function timeUtils_getCurrentUTCTimeWithOffset_test()
  dt = createObject("roDateTime")
  now = dt.asSeconds()

  testingTimeOffset = 10
  constants = {
    "settings": {
      "mode": "dev"
      "testingTimeOffset": testingTimeOffset
    }
  }
  diff = getCurrentUTCTimeWithOffset(constants) - now

  'Check if local Time returned by getCurrentLocalTime is very close to current time
  m.assertEqual(diff, testingTimeOffset)
End Function


'@Test getCurrentLocalTime unit tests
Function timeUtils_getCurrentLocalTime_test()
  dt = CreateObject("roDateTime")
  dt.ToLocalTime()
  now = dt.AsSeconds()
  diff = getCurrentLocalTime() - now

  'Check if local Time returned by getCurrentLocalTime is very close to current time
  m.AssertTrue(diff < 2)
End Function


'@Test getCurrentLocalTimeWithOffset unit tests
Function timeUtils_getCurrentLocalTimeWithOffset_test()
  dt = createObject("roDateTime")
  dt.toLocalTime()
  now = dt.asSeconds()

  testingTimeOffset = 10
  constants = {
    "settings": {
      "mode": "dev"
      "testingTimeOffset": testingTimeOffset
    }
  }
  diff = getCurrentLocalTimeWithOffset(constants) - now

  'Check if local Time returned by getCurrentLocalTime is very close to current time
  m.assertEqual(diff, testingTimeOffset)
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


'@Test isNowWithinTimePeriod unit tests
Function timeUtils_isNowWithinTimePeriod_test()
  startTime = "2009-01-01 01:00:00.000"
  endTime = "4000-01-01 01:00:00.000"
  m.assertTrue(isNowWithinTimePeriod(startTime, endTime))

  startTime = "4000-01-01 01:00:00.000"
  endTime = "4001-01-01 01:00:00.000"
  m.assertFalse(isNowWithinTimePeriod(startTime, endTime))

  startTime = "2009-01-01 01:00:00.000"
  endTime = "2010-01-01 01:00:00.000"
  m.assertFalse(isNowWithinTimePeriod(startTime, endTime))

  startTime = "2009-01-01 01:00:00.000"
  endTime = "2007-01-01 01:00:00.000"
  m.assertFalse(isNowWithinTimePeriod(startTime, endTime))

  startTime = "4001-01-01 01:00:00.000"
  endTime = "4000-01-01 01:00:00.000"
  m.assertFalse(isNowWithinTimePeriod(startTime, endTime))
End Function


'@Test isIso8601String unit tests
Function timeUtils_isIso8601String_test()
  m.assertTrue(isIso8601String("2009-01-01 01:00:00.000"))
  m.assertTrue(isIso8601String("2009-01-01 01:01:01.001"))
  m.assertTrue(isIso8601String("2009-01-01 10:10:10.111"))
  m.assertTrue(isIso8601String("1984-12-14 01:00:00"))
  m.assertTrue(isIso8601String("2009-01-01T01:00:00.000"))
  m.assertTrue(isIso8601String("2009-01-01T01:01:01.001"))
  m.assertTrue(isIso8601String("2009-01-01T10:10:10.111"))
  m.assertTrue(isIso8601String("1984-12-14T01:00:00"))
  m.assertFalse(isIso8601String("1984-65-14 01:00:00.000"))
  m.assertFalse(isIso8601String("1984-12-65 01:00:00.000"))
  m.assertFalse(isIso8601String("19843-12-14 01:00:00"))
  m.assertFalse(isIso8601String("YYYY-12-14 01:00:00"))
  m.assertFalse(isIso8601String("1984-MM-14 01:00:00"))
  m.assertFalse(isIso8601String("1984-12-DD 01:00:00.000"))
  m.assertFalse(isIso8601String("YYYY-MM-DD 01:00:00"))
  m.assertFalse(isIso8601String("2009-01-01THH:00:00.000"))
  m.assertFalse(isIso8601String("2009-01-01 25:00:00.000"))
  m.assertFalse(isIso8601String("2009-01-01 08:60:00.000"))
  m.assertFalse(isIso8601String("2009-01-01 08:12:60.000"))
  m.assertFalse(isIso8601String("2009-05-14 01:00:00:000"))
  m.assertFalse(isIso8601String("2009-05-14 01:00:00;000"))
  m.assertFalse(isIso8601String("2009-01-01 8:06:25.000"))
  m.assertFalse(isIso8601String("2009-05-14 01:6:00.000"))
  m.assertFalse(isIso8601String("2009-05-14 01:6:3.000"))
  m.assertFalse(isIso8601String("2009-05-14 01:6:3.00"))
  m.assertFalse(isIso8601String("200e-05-14 01:06:39.013"))
  m.assertFalse(isIso8601String("2009-W5-14 01:06:39.009"))
  m.assertFalse(isIso8601String("2009-05-1L 01:06:39.006"))
  m.assertFalse(isIso8601String("2009-05-14 r1:06:32.156"))
  m.assertFalse(isIso8601String("2009-05-14 01:P6:32.002"))
  m.assertFalse(isIso8601String("2009-05-14 01:06:3T.002"))
  m.assertFalse(isIso8601String("2009-05-14 01:06:39.00d"))
  m.assertFalse(isIso8601String("20094-05-18 01:06:39.006"))
  m.assertFalse(isIso8601String("2009-056-18 01:06:39.006"))
  m.assertFalse(isIso8601String("2009-05-183 01:06:39.006"))
  m.assertFalse(isIso8601String("2009-05-18 114:06:39.006"))
  m.assertFalse(isIso8601String("2009-05-18 01:064:39.006"))
  m.assertFalse(isIso8601String("2009-05-18 01:06:395.006"))
  m.assertTrue(isIso8601String("2009-05-18 01:06:39.1234"))
  m.assertTrue(isIso8601String("2009-05-18 01:06:39.123Z"))
  m.assertTrue(isIso8601String("2009-05-18 01:06:39Z"))
  m.assertTrue(isIso8601String("2009-05-18 01:06:39.123456Z"))
  m.assertFalse(isIso8601String("2009-05-18 01:06:39.Z123"))
  m.assertFalse(isIso8601String("2009-05-18 01:06:39.12avZ"))
  m.assertFalse(isIso8601String("65-14 01:00:00000"))
  m.assertFalse(isIso8601String("BRIGHTSCRIP"))
  m.assertFalse(isIso8601String(""))
  m.assertFalse(isIso8601String(" "))
  m.assertFalse(isIso8601String("Hi there"))
  m.assertFalse(isIso8601String(1234567))
  m.assertFalse(isIso8601String("1234567"))
  m.assertFalse(isIso8601String(invalid))
End Function


'@Test isGreaterThanCurrentTime unit tests
Function timeUtils_isGreaterThanCurrentTime_test()
  dateTime = CreateObject("roDateTime")
  nowSeconds = dateTime.AsSeconds()
  dateTime.fromSeconds(nowSeconds + (24 * 60 * 60))
  nextDayString = dateTime.ToISOString()
  m.assertTrue(isGreaterThanCurrentTime(nextDayString))
  m.assertFalse(isGreaterThanCurrentTime("2009-01-01 01:01:01.001"))
  m.assertFalse(isGreaterThanCurrentTime(1234567))
  m.assertFalse(isGreaterThanCurrentTime("1234567"))
  m.assertFalse(isGreaterThanCurrentTime(invalid))
End Function