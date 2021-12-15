'@SGNode Test_VideoPlayer
'@TestSuite [VideoCuepointHelpers] VideoCuepoints in VideoPlayer.brs


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests video cuepoint helpers in VideoPlayer.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test isInWindow unit test
Function videoCuepoints_isInWindow_test()
  ' way outside
  m.AssertFalse(isInWindow(1.72, 90, 15))

  ' way inside
  m.AssertTrue(isInWindow(81.72, 90, 15))

  ' borderline
  m.AssertTrue(isInWindow(46.739, 60, 15))
  m.AssertFalse(isInWindow(44.739, 60, 15))
End Function
