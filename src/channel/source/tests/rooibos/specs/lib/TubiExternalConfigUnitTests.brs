'@TestSuite [TubiExternalConfig] TubiExternalConfig.brs 

'@Setup
Function TubiExternalConfigSetup()
End function


' Mock that the server did not respond, or response was invalid
Function tubiExternalConfig_mockGetInvalidConfigs_testHelper() As Object
  return invalid
End Function


' Mock that the server responses
Function tubiExternalConfig_mockGetConfigs_testHelper() As Object
  return ParseJson("{""livetv"":false,""intro_landscape_hibpr"":""http://c12.adrise.tv/v2/sources/content-owners/adrise-no-ads/325254/v20169072053-1920x1080-2413k.mp4"",""intro_landscape_lowbpr"":""http://c12.adrise.tv/v2/sources/content-owners/adrise-no-ads/325254/v20169072053-1920x1080-341k.mp4"",""intro_portrait_hibpr"":""http://c12.adrise.tv/v2/sources/content-owners/adrise-no-ads/325255/v20169072050-1080x1920-2624k.mp4"",""intro_portrait_lowbpr"":""http://c12.adrise.tv/v2/sources/content-owners/adrise-no-ads/325255/v20169072050-1080x1920-335k.mp4""}")
End Function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in TubiExternalConfig.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@BeforeEach
Function tubiExternalConfig_config()
  m.constants = getConstants()
  request = TubiRequest()
  m.config = TubiExternalConfig(request, m.constants)  
End Function


'@Test initSuccess unit tests
Function tubiExternalConfig_initSuccess_test()
  config = m.config
  constants = m.constants
  config.getConfigs = tubiExternalConfig_mockGetConfigs_testHelper
  m.assertInvalid(constants.externalConfig.info)
  config.init()
  m.assertNotInvalid(constants.externalConfig.info)
  m.assertFalse(constants.externalConfig.info.livetv)
End Function


'@Test initDefaults unit tests
Function tubiExternalConfig_initDefaults_test()
  config = m.config
  constants = m.constants
  config.getConfigs = tubiExternalConfig_mockGetConfigs_testHelper
  m.assertInvalid(constants.externalConfig.info)
  config.init()
  m.assertNotInvalid(constants.externalConfig.info)
End Function


'@Test initFailed unit tests
Function tubiExternalConfig_initFailed_test()
  config = m.config
  constants = m.constants
  defaultConfig = {
      somevalue: "yes"
    }
  config.defaultValues = defaultConfig
  config.getConfigs = tubiExternalConfig_mockGetInvalidConfigs_testHelper
  m.assertInvalid(constants.externalConfig.info)
  config.init()
  m.assertNotInvalid(constants.externalConfig.info)
  m.assertEqual(constants.externalConfig.info, defaultConfig)
End Function
