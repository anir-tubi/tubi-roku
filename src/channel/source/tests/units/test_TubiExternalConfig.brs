Function TestSuite_TubiExternalConfig()
  this = BaseTestSuite()
  this.Name = "TubiExternalConfigTestSuite"
  this.addTest("init_success", testCase_tubiExternalConfig_initSuccess)
  this.addTest("init_failed", testCase_tubiExternalConfig_initFailed)
  this.addTest("init_defaults", testCase_tubiExternalConfig_initDefaults)
  return this
End Function


Function testCase_tubiExternalConfig_initSuccess()
  constants = getConstants()
  request = TubiRequest()
  config = TubiExternalConfig(request, constants)
  config.getConfigs = testHelper_tubiExternalConfig_mockGetConfigs
  result = m.assertInvalid(constants.externalConfig.info)
  config.init()
  result += m.assertNotInvalid(constants.externalConfig.info)
  result += m.assertFalse(constants.externalConfig.info.livetv)
  return result
End Function

Function testCase_tubiExternalConfig_initDefaults()
  constants = getConstants()
  request = TubiRequest()
  config = TubiExternalConfig(request, constants)
  config.getConfigs = testHelper_tubiExternalConfig_mockGetConfigs
  result = m.assertInvalid(constants.externalConfig.info)
  config.init()
  result += m.assertNotInvalid(constants.externalConfig.info)
  result += m.assertFalse(constants.externalConfig.info.livetv)
  ' check default value explicitly not in the MockGetConfigs values
  result += m.assertNotInvalid(constants.externalConfig.info.limited_newui_enabled)
  return result
End Function

Function testCase_tubiExternalConfig_initFailed()
  constants = getConstants()
  request = TubiRequest()
  config = TubiExternalConfig(request, constants)
  defaultConfig = {
      somevalue: "yes"
    }
  config.defaultValues = defaultConfig
  config.getConfigs = testHelper_tubiExternalConfig_mockGetInvalidConfigs
  result = m.assertInvalid(constants.externalConfig.info)
  config.init()
  result += m.assertNotInvalid(constants.externalConfig.info)
  result += m.assertEqual(constants.externalConfig.info, defaultConfig)
  return result
End Function

' Mock that the server did not respond, or response was invalid
Function testHelper_tubiExternalConfig_mockGetInvalidConfigs() As Object
  return invalid
End Function

Function testHelper_tubiExternalConfig_mockGetConfigs() As Object
  return ParseJson("{""livetv"":false,""intro_landscape_hibpr"":""http://c12.adrise.tv/v2/sources/content-owners/adrise-no-ads/325254/v20169072053-1920x1080-2413k.mp4"",""intro_landscape_lowbpr"":""http://c12.adrise.tv/v2/sources/content-owners/adrise-no-ads/325254/v20169072053-1920x1080-341k.mp4"",""intro_portrait_hibpr"":""http://c12.adrise.tv/v2/sources/content-owners/adrise-no-ads/325255/v20169072050-1080x1920-2624k.mp4"",""intro_portrait_lowbpr"":""http://c12.adrise.tv/v2/sources/content-owners/adrise-no-ads/325255/v20169072050-1080x1920-335k.mp4""}")
End Function