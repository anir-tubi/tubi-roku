'@TestSuite [Settings] build.js

'@Setup
Function SettingsSetup()
End Function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in build.js
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test getSettings unit tests
Function settings_getSettings_test()
  settings = getSettings()
  env = settings.mode
  m.assertEqual(env, "test")
End Function
