'@TestSuite [TensorApi] TensorApi.brs

'@Setup
Function TensorApiSetup()
  constants = getConstants()
  pub_serverPersistentData = createObject("roSGNode", "ServerPersistentData")
  m.tensorApi = TensorApi(constants, pub_serverPersistentData)
End Function



'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in TensorApi.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test unit tests commonOptions
Function tensorApi_commonOptions_Test()
  options = [
    "headers"
    "params"
  ]

  headers = [
    "Content-Type"
    "x-client-platform"
    "x-client-version"
  ]

  params = [
    "app_id"
    "platform"
    "device_id"
  ]

  deviceId = m.tensorApi.constants.deviceInfo.deviceId
  platform = m.tensorApi.constants.platform
  appId = m.tensorApi.constants.settings.shortAppName
  clientVersion = m.tensorApi.constants.deviceInfo.clientVersion

  commonOptions = m.tensorApi.commonOptions()
  m.assertAAHasKeys(commonOptions, options)
  m.assertAAHasKeys(commonOptions.headers, headers)
  m.assertAAHasKeys(commonOptions.params, params)
  m.assertEqual(commonOptions.params.app_id, appId)
  m.assertEqual(commonOptions.params.platform, platform)
  m.assertEqual(commonOptions.params.device_id, deviceId)
  m.assertEqual(commonOptions.headers["Content-Type"], "application/json")
  m.assertEqual(commonOptions.headers["x-client-platform"], platform)
  m.assertEqual(commonOptions.headers["x-client-version"], clientVersion)
End Function


'@Test unit tests epgChannelIds
Function tensorApi_getEPGChannelIdsReqInfo_test()
  infoKeys = [
    "url"
    "options"
  ]

  options = [
    "headers"
    "params"
  ]

  headers = [
    "Content-Type"
    "x-client-platform"
    "x-client-version"
  ]

  params = [
    "app_id"
    "platform"
    "device_id"
    "mode"
  ]

  platform = m.tensorApi.constants.platform
  deviceId = m.tensorApi.constants.deviceInfo.deviceId
  appId = m.tensorApi.constants.settings.shortAppName
  mode = "news"

  'test with mode as param
  epgReqWithMode = m.tensorApi.getEPGChannelIdsReqInfo(mode)

  m.assertAAHasKeys(epgReqWithMode, infoKeys)
  m.assertAAHasKeys(epgReqWithMode.options, options)
  m.assertAAHasKeys(epgReqWithMode.options.headers, headers)
  m.assertAAHasKeys(epgReqWithMode.options.params, params)
  m.assertEqual(epgReqWithMode.options.params.platform, platform)
  m.assertEqual(epgReqWithMode.options.params.device_id, deviceId)
  m.assertEqual(epgReqWithMode.options.params.app_id, appId)
  m.assertEqual(epgReqWithMode.options.params.mode, mode)
  m.assertEqual(epgReqWithMode.options.headers["Content-Type"], "application/json")

  'test without mode (default mode) as param
  epgReqWithOutMode = m.tensorApi.getEPGChannelIdsReqInfo()

  params = [
    "app_id"
    "platform"
    "device_id"
  ]

  m.assertAAHasKeys(epgReqWithOutMode, infoKeys)
  m.assertAAHasKeys(epgReqWithMode.options, options)
  m.assertAAHasKeys(epgReqWithOutMode.options.headers, headers)
  m.assertAAHasKeys(epgReqWithOutMode.options.params, params)
  m.assertEqual(epgReqWithOutMode.options.params.platform, platform)
  m.assertEqual(epgReqWithOutMode.options.params.device_id, deviceId)
  m.assertEqual(epgReqWithOutMode.options.params.app_id, appId)
  m.assertEqual(epgReqWithOutMode.options.headers["Content-Type"], "application/json")

End Function


'@Test unit tests getEPGProgramReqInfo
Function tensorApi_getEPGProgramReqInfo_test()
  infoKeys = [
    "url"
    "options"
  ]

  options = [
    "headers"
    "params"
  ]

  headers = [
    "Content-Type"
    "x-client-platform"
    "x-client-version"
    "x-capability"
  ]

  params = [
    "app_id"
    "device_id"
    "platform"
    "lookahead"
  ]

  platform = m.tensorApi.constants.platform
  deviceId = m.tensorApi.constants.deviceInfo.deviceId
  content_ids = ["555117", "555118"]
  lookahead = 1

  content_id = content_ids.Join(",")

  epgProgramReq = m.tensorApi.getEPGProgramReqInfo(content_ids)

  m.assertAAHasKeys(epgProgramReq, infoKeys)
  m.assertAAHasKeys(epgProgramReq.options, options)
  m.assertAAHasKeys(epgProgramReq.options.headers, headers)
  m.assertAAHasKeys(epgProgramReq.options.params, params)
  m.assertEqual(epgProgramReq.options.params.platform, platform)
  m.assertEqual(epgProgramReq.options.params.device_id, deviceId)
  m.assertEqual(epgProgramReq.options.params.lookahead, lookahead)
  m.assertEqual(epgProgramReq.options.params.content_id, content_id)
  m.assertEqual(epgProgramReq.options.headers["Content-Type"], "application/json")
  m.assertEqual(epgProgramReq.options.headers["x-capability"], formatJson({ "program_title_differ_with_episode_title": true }))
End Function
