Function testExternalConfigInitSuccess(t As Object)
  constants = getConstants()
  request = TubiRequest()
  config = TubiExternalConfig(request, constants)
  config.getConfigs = MockGetConfigs
  t.assertInvalid(constants.externalConfig.info)
  config.init()
  t.assertNotInvalid(constants.externalConfig.info)
  t.assertFalse(constants.externalConfig.info.livetv)
End Function

Function testExternalConfigInitFailed(t As Object)
  constants = getConstants()
  request = TubiRequest()
  config = TubiExternalConfig(request, constants)
  defaultConfig = {
      somevalue: "yes"
    }
  config.defaultValues = defaultConfig
  config.getConfigs = MockGetInvalidConfigs
  t.assertInvalid(constants.externalConfig.info)
  config.init()
  t.assertNotInvalid(constants.externalConfig.info)
  t.assertEqual(constants.externalConfig.info, defaultConfig)
End Function

' Mock that the server did not respond, or response was invalid
Function MockGetInvalidConfigs() As Object
  return invalid
End Function

Function MockGetConfigs() As Object
  return ParseJson("{""livetv"":false,""intro_landscape_hibpr"":""http://c12.adrise.tv/v2/sources/content-owners/adrise-no-ads/325254/v20169072053-1920x1080-2413k.mp4"",""intro_landscape_lowbpr"":""http://c12.adrise.tv/v2/sources/content-owners/adrise-no-ads/325254/v20169072053-1920x1080-341k.mp4"",""intro_portrait_hibpr"":""http://c12.adrise.tv/v2/sources/content-owners/adrise-no-ads/325255/v20169072050-1080x1920-2624k.mp4"",""intro_portrait_lowbpr"":""http://c12.adrise.tv/v2/sources/content-owners/adrise-no-ads/325255/v20169072050-1080x1920-335k.mp4""}")
End Function