'@TestSuite [TypeUtils] TypeUtils.brs

'@Setup
Function TypeUtilsSetup()
End Function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in TypeUtils.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test isNonEmptyAA unit tests
Function typeUtils_isNonEmptyAA_test()
  aa = { a: 1 }
  m.assertTrue(isNonEmptyAA(aa))
  aa = {}
  m.assertFalse(isNonEmptyAA(aa))
  aa = invalid
  m.assertFalse(isNonEmptyAA(aa))
  aa = "a"
  m.assertFalse(isNonEmptyAA(aa))
  aa = 1
  m.assertFalse(isNonEmptyAA(aa))
End Function