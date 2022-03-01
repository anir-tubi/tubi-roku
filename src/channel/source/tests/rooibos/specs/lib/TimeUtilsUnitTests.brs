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
  ' check if current time retured by getCurrentUTCTime is very close to current time
  m.AssertTrue(diff < 2) 
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