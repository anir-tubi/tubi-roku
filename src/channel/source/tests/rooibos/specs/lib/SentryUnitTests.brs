'@TestSuite [Sentry] Sentry.brs

'@Setup
Function SentrySetup()
  m.constants = getConstants()
  request = TubiRequest(m.constants.settings)
  m.auth = TubiAuth(m.constants, request)
End function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in Sentry.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test initSentry unit tests
Function sentry_init_test()
  s = initSentry("")
  m.assertNotInvalid(s)

  s = initSentry(invalid)
  m.assertNotInvalid(s)

  s = initSentry("", {}, {})
  m.assertNotInvalid(s)
End Function


'@Test parseDsn unit tests
Function tsentry_parseDsn_test()
  dsn = sentry_parseDsn("not a url")
  m.assertNotInvalid(dsn)
  m.assertInvalid(dsn.protocol)
  m.assertInvalid(dsn.publicKey)
  m.assertInvalid(dsn.secretKey)
  m.assertInvalid(dsn.host)
  m.assertInvalid(dsn.port)
  m.assertInvalid(dsn.project)

  dsn = sentry_parseDsn("https://public:secret@sentry.io/1377102")
  m.assertNotInvalid(dsn)
  m.assertEqual(dsn.protocol, "https")
  m.assertEqual(dsn.publicKey, "public")
  m.assertEqual(dsn.secretKey, "secret")
  m.assertEqual(dsn.host, "sentry.io")
  m.assertEqual(dsn.port, "")
  m.assertEqual(dsn.project, "1377102")
End Function


'@Test deepAppend unit tests
Function sentry_deepAppend_test()
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
  m.assertEqual(appended["one"], 1)
  m.assertEqual(appended["two"], 2)
  m.assertEqual(appended["child"]["three"], 3)
  m.assertEqual(appended["child"]["four"], 4)
End Function


'@Test captureMessage unit tests
Function sentry_captureMessage_test()
  s = Sentry(m.constants, m.auth)
  s._sendEvent = Function(event)
    m._testEvent = event
  End Function
  s.captureMessage("Test Message")
  m.assertEqual(s._testEvent["message"], "Test Message")
  m.assertEqual(s._testEvent["level"], "info")

  s.captureMessage("Test Message", "warning")
  m.assertEqual(s._testEvent["message"], "Test Message")
  m.assertEqual(s._testEvent["level"], "warning")

  s.captureMessage("Test Message", "error")
  m.assertEqual(s._testEvent["message"], "Test Message")
  m.assertEqual(s._testEvent["level"], "error")
End Function


'@Test getUrl unit tests
Function sentry_getUrl_test()
  s = Sentry(m.constants, m.auth)
  url = s._getUrl()
  m.assertEqual(url, "https://sentry.io/api/1377102/store/")
End Function
