'@TestSuite [TubiExternalConfig] TubiExternalConfig.brs

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in TubiExternalConfig.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@BeforeEach
Function tubiExternalConfig_config()
  m.constants = getConstants()
  m.externalConfig = TubiExternalConfig(m.constants)
End Function


'@Test parseBlockedAnalyticsEvents
Function tubiExternalConfig_parseBlockedAnalyticsEvents_test()
  blockedAnalyticsEvents = {
    "essential": ["active"]
    "analytics": ["auto_play"]
  }
  result = m.externalConfig.parseBlockedAnalyticsEvents(blockedAnalyticsEvents)
  m.assertAAHasKeys(result, ["active", "auto_play"])
  m.assertEqual(result.active, "essential")
  m.assertEqual(result.auto_play, "analytics")
End Function
