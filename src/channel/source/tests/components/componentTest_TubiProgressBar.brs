Function componentTestHelper_ProgressBar(screen, runTests, progress)
  data = {
    "width":      1000
    "progress":   progress
    "trackColor": "0xFFFFFFFF"
    "focusColor": "0x0000FFFF"
    "unfocusColor": "0x00FF00FF"
    "scaledUI": true
  }
  runTests("TubiProgressBar", data)
End Function

' foreground should not be visible at all
Function componentTest_ProgressBar_0(screen, runTests)
  componentTestHelper_ProgressBar(screen, runTests, 0)
End Function

' foreground should show at minimum size equal to bitmapWidth
Function componentTest_ProgressBar_0_1(screen, runTests)
  componentTestHelper_ProgressBar(screen, runTests, 0.1)
End Function

Function componentTest_ProgressBar_25(screen, runTests)
  componentTestHelper_ProgressBar(screen, runTests, 25)
End Function

Function componentTest_ProgressBar_50(screen, runTests)
  componentTestHelper_ProgressBar(screen, runTests, 50)
End Function

Function componentTest_ProgressBar_75(screen, runTests)
  componentTestHelper_ProgressBar(screen, runTests, 75)
End Function

Function componentTest_ProgressBar_100(screen, runTests)
  componentTestHelper_ProgressBar(screen, runTests, 100)
End Function

Function componentTest_ProgressBar_99(screen, runTests)
  componentTestHelper_ProgressBar(screen, runTests, 99)
End Function

' should clamp to progress of 100 and display ok
Function componentTest_ProgressBar_150(screen, runTests)
  componentTestHelper_ProgressBar(screen, runTests, 150)
End Function

' should clamp to progress of 0 and display ok
Function componentTest_ProgressBar_less_50(screen, runTests)
  componentTestHelper_ProgressBar(screen, runTests, -50)
End Function


' Should display at width=bitmapWidth
Function componentTest_ProgressBar_width_0(screen, runTests)
  data = {
    "width":      0
    "progress":   100
    "trackColor": "0xFFFFFFFF"
    "focusColor": "0x0000FFFF"
    "unfocusColor": "0x00FF00FF"
    "scaledUI": true
  }
  runTests("TubiProgressBar", data)
End Function
