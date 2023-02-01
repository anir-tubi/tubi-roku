'@TestSuite [TimeOffsetUtils] TimeOffsetUtils.brs

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in TimeOffsetUtils.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test getTestingTimeOffset unit tests
Function timeOffsetUtils_getTestingTimeOffset_test()
  ' Should adjust offset when not in prod
  actual = getTestingTimeOffset({
    "settings": {
      "mode": "dev"
      "testingTimeOffset": 100
    }
  })
  m.assertEqual(actual, 100)

  ' Should not return offset when in prod
  actual = getTestingTimeOffset({
    "settings": {
      "mode": "production"
      "testingTimeOffset": 100
    }
  })
  m.assertEqual(actual, 0)
End Function
