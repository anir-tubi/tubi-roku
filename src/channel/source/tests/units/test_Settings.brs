Function TestSuite_Settings()
  this = BaseTestSuite()
  this.name = "SettingsTestSuite"
  this.addTest("getSettings", testCase_settings_getSettings)
  this.addTest("getManifest", testCase_settings_getManifest)
  return this
End Function

Function testCase_settings_getSettings()
  settings = getSettings()
  env = settings.mode
  return m.assertEqual(env, "test")
End Function

Function testCase_settings_getManifest()
  manifest = getManifest()
  title = manifest.title
  result = m.assertNotInvalid(title)
  result = result + m.assertNotEqual(title, "")
  return result
End Function