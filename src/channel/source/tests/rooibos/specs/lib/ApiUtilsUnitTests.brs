'@TestSuite [ApiUtils] ApiUtils.brs 

'@Setup
Function ApiUtilsSetup()
  constants = getConstants()
  pub_serverPersistentData = createObject("roSGNode", "ServerPersistentData")
  m.apiUtils = ApiUtils(constants, pub_serverPersistentData)
End function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in ApiUtils.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test unit tests getCommonOptions
Function apiUtils_getCommonOptions_test()

  options = [
    "headers"
    "params"
  ]
  params = [
    "app_id"
    "platform"
    "device_id"
  ]

  deviceId = m.apiUtils.constants.deviceInfo.deviceId
  platform = m.apiUtils.constants.platform
  appId = m.apiUtils.constants.settings.shortAppName

  clientVersion = m.apiUtils.constants.deviceInfo.clientVersion

  commonOptions = m.apiUtils.getCommonOptions()

  m.assertAAHasKeys(commonOptions, options)
  m.assertAAHasKeys(commonOptions.params, params)
  m.assertEqual(commonOptions.params.app_id, appId)
  m.assertEqual(commonOptions.params.platform, platform)
  m.assertEqual(commonOptions.params.device_id, deviceId)
  m.assertInvalid(commonOptions.headers["X-TUBI-PLATFORM"])

  m.assertEqual(commonOptions.headers["Content-Type"], "application/json")
  m.assertEqual(commonOptions.headers["x-client-platform"], platform)
  m.assertEqual(commonOptions.headers["x-client-version"], clientVersion)

  commonOptions = m.apiUtils.getCommonOptions(true)
  m.assertEqual(commonOptions.headers["X-TUBI-PLATFORM"], m.apiUtils.constants.analyticsPlatform)

End Function
