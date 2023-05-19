'@TestSuite [RainmakerApi] RainmakerApi.brs

'@Setup
Function RainmakerApiSetup()
  m.constants = getConstants()
  m.rainmakerApi = RainmakerApi(m.constants)
End function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in RainmakerApi.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test pauseAdsRequestInfo_test unit tests
Function rainmakerApi_pauseAdsRequestInfo_test()
  url = m.constants.urls.pauseAdsUrl

  content = {
    id: "testId"
    pubId: "testPubId"
  }

  nowPos = 100
  appMode = "DEFAULT_MODE"
  requestInfo = m.rainmakerApi.pauseAdsRequestInfo(content, nowPos, appMode)

  m.assertNotInvalid(requestInfo)
  m.assertNotInvalid(requestInfo.url)
  m.assertEqual(requestInfo.url, url)

  options = requestInfo.options
  m.assertNotInvalid(options)

  params = options.params
  m.assertNotInvalid(params)

  ' checking only required params
  m.assertNotInvalid(params.content_id)
  m.assertEqual(params.content_id, content.id)

  m.assertNotInvalid(params.pub_id)
  m.assertEqual(params.pub_id, content.pubId)

  m.assertNotInvalid(params.device_id)
  m.assertEqual(params.device_id, m.constants.deviceInfo.deviceId)

  m.assertNotInvalid(params.now_pos)
  m.assertEqual(params.now_pos, nowPos)
End Function
