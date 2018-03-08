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