Sub testAdd(t as object)
  t.assertEqual( (1+2), 3)
  t.assertEqual( 0+1, 1)
End Sub

Sub testEnv(t as object)
  settings = getSettings()
  env = settings.mode
  t.assertEqual(env, "test")
End Sub

Sub testManifest(t as object)
  manifest = getManifest()
  title = manifest.title
  t.assertNotInvalid(title)
  t.assertNotEqual(title, "")
End Sub

Sub testTheme(t as object)
  theme = getTheme()
  t.assertNotInvalid(theme)
End Sub
