'@TestSuite [TubiLanguageTranslate] TubiLanguageTranslate.brs

'@Setup
Function TubiLanguageTranslateSetup()
End Function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in TubiLanguageTranslate.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test formatLengthSelectedLocale unit tests
Function tubiLanguageTranslate_formatLengthSelectedLocale_test()
  m.AssertEqual(formatLengthSelectedLocale(invalid), "")
  m.AssertEqual(formatLengthSelectedLocale(60), "1 min")
  m.AssertEqual(formatLengthSelectedLocale(123.45), "2 min")
  m.AssertEqual(formatLengthSelectedLocale(3610), "1 h")
  m.AssertEqual(formatLengthSelectedLocale(3660), "1 h 1 min")
End Function
