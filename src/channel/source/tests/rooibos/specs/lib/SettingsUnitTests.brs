'@TestSuite [Settings] build.js 

'@Setup
Function SettingsSetup()
End function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in build.js
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test getSettings unit tests
Function settings_getSettings_test()
  settings = getSettings()
  env = settings.mode
  m.assertEqual(env, "test")
End Function


'@Test getManifest unit tests
Function settings_getManifest_test()
  manifest = getManifest()
  title = manifest.title
  m.assertNotInvalid(title)
  m.assertNotEqual(title, "")
End Function