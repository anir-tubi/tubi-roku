Function TestSuite_Sentry()
  this = BaseTestSuite()
  this.name = "SentryTestSuite"
  this.addTest("constructor", testCase_sentry_constructor)
  this.addTest("parseDsn", testCase_sentry_parseDsn)
  this.addTest("deepAppend", testCase_sentry_deepAppend)
  this.addTest("captureMessage", testCase_sentry_captureMessage)
  this.addTest("getUrl", testCase_sentry_getUrl)
  return this
End Function

'******************
' constructor
'******************

Function testCase_sentry_constructor()
  result = ""
  s = Sentry("")
  result += m.assertNotInvalid(s)

  s = Sentry(invalid)
  result += m.assertNotInvalid(s)

  s = Sentry("", {}, {})
  result += m.assertNotInvalid(s)

  return result
End Function


'**************
' parseDsn
'**************

Function testCase_sentry_parseDsn()
  result = ""
  dsn = sentry_parseDsn("not a url")
  result += m.assertNotInvalid(dsn)
  result += m.assertInvalid(dsn.protocol)
  result += m.assertInvalid(dsn.publicKey)
  result += m.assertInvalid(dsn.secretKey)
  result += m.assertInvalid(dsn.host)
  result += m.assertInvalid(dsn.port)
  result += m.assertInvalid(dsn.project)

  dsn = sentry_parseDsn("https://public:secret@sentry.io/1377102")
  result += m.assertNotInvalid(dsn)
  result += m.assertEqual(dsn.protocol, "https")
  result += m.assertEqual(dsn.publicKey, "public")
  result += m.assertEqual(dsn.secretKey, "secret")
  result += m.assertEqual(dsn.host, "sentry.io")
  result += m.assertEqual(dsn.port, "")
  result += m.assertEqual(dsn.project, "1377102")

  return result
End Function


'**************
' deepAppend
'**************

Function testCase_sentry_deepAppend()
  a = {
    "one": 1
    "two": 2
    "child": {
      "three": 3
    }
  }

  b = {
    "child": {
      "four": 4
    }
  }
  appended = sentry_deepAppend(a, b)
  result = m.assertEqual(appended["one"], 1)
  result += m.assertEqual(appended["two"], 2)
  result += m.assertEqual(appended["child"]["three"], 3)
  result += m.assertEqual(appended["child"]["four"], 4)
  return result
End Function


Function testCase_sentry_captureMessage()
  s = Sentry("")
  s._sendEvent = Function(event)
    m._testEvent = event
  End Function
  s.captureMessage("Test Message")
  result = m.assertEqual(s._testEvent["message"], "Test Message")
  result += m.assertEqual(s._testEvent["level"], "info")

  s.captureMessage("Test Message", "warning")
  result += m.assertEqual(s._testEvent["message"], "Test Message")
  result += m.assertEqual(s._testEvent["level"], "warning")

  s.captureMessage("Test Message", "error")
  result += m.assertEqual(s._testEvent["message"], "Test Message")
  result += m.assertEqual(s._testEvent["level"], "error")

  return result
End Function

Function testCase_sentry_getUrl()
  s = Sentry("https://public:secret@sentry.io/1377102")
  url = s._getUrl()
  return m.assertEqual(url, "https://sentry.io/api/1377102/store/")
End Function

