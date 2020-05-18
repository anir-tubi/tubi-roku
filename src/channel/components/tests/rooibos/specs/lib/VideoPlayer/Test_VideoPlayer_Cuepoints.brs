Function TestSuite_VideoPlayer_Cuepoints() as Object
  this = BaseTestSuite()
  this.Name = "TestSuite_VideoPlayer_Cuepoints"
  this.addTest("isInWindow", testCase_isInWindow)
  this.addTest("isAtPosition", testCase_isAtPosition)
  return this
End Function


Function testCase_isInWindow()
  ' way outside
  result = m.assertFalse(isInWindow(1.72, 90, 15))

  ' way inside
  result += m.assertTrue(isInWindow(81.72, 90, 15))

  ' borderline
  result += m.assertTrue(isInWindow(46.739, 60, 15))
  result += m.assertFalse(isInWindow(44.739, 60, 15))
  return result
End Function

Function testCase_isAtPosition()
  ' way outside
  result = m.assertFalse(isAtPosition(1.72, 90))
  ' borderline
  result += m.assertFalse(isAtPosition(90.72, 90))
  result += m.assertTrue(isAtPosition(90.22, 90))
  ' only hits if >=
  result += m.assertFalse(isAtPosition(89.72, 90))
  return result
End Function

