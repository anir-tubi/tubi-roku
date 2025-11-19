
'@TestSuite [RokuContinueWatchingApi] RokuContinueWatchingApi.brs

'@Setup
Function RokuContinueWatchingApiSetup()

  m.constants = getConstants()
  m.rokuContinueWatchingApi = RokuContinueWatchingApi(m.constants)
End Function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in RokuContinueWatchingApi.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test createUpdateContinueWatchingReqInfo unit tests
Function rokuContinueWatchingApi_createUpdateContinueWatchingReqInfo_test()
  body = {
    "items": [{
      "contentId": "testContentId",
      "episodeId": "testEpisodeId",
      "lastInteractionTime": 123456,
      "position": 854,
      "duration": 1678
    }]
  }
  req = m.rokuContinueWatchingApi.createUpdateContinueWatchingReqInfo(body)

  m.assertNotInvalid(req)
  m.assertEqual(m.constants.urls.rokuContinueWatchingEndpoint, req.url)

  options = req.options
  m.assertNotInvalid(options)
  m.assertNotEmpty(options.body)
  m.assertEqual(m.constants.reqTypes.post, options.method)

  headers = options.headers
  m.assertAAHasKeys(headers, ["x-roku-reserved-jwt", "x-roku-reserved-channel-id", "x-roku-reserved-channel-store-code", "x-roku-reserved-virtual-user-id", "x-roku-reserved-device-id", "x-roku-reserved-serial-number"])
  m.assertEqual(m.constants.productionApplicationId, headers["x-roku-reserved-channel-id"])

  requestBody = ParseJson(options.body)
  m.assertNotInvalid(requestBody.items)
  m.assertEqual("testContentId", requestBody.items[0].contentId)
  m.assertEqual("testEpisodeId", requestBody.items[0].episodeId)
  m.assertEqual(123456, requestBody.items[0].lastInteractionTime)
  m.assertEqual(854, requestBody.items[0].position)
  m.assertEqual(1678, requestBody.items[0].duration)
End Function


'@Test createDeleteContinueWatchingReqInfo unit tests
Function rokuContinueWatchingApi_createDeleteContinueWatchingReqInfo_test()
  body = {
    "items": [{
      "contentId": "testContentId",
      "episodeId": "testEpisodeId"
    }]
  }
  req = m.rokuContinueWatchingApi.createDeleteContinueWatchingReqInfo(body)

  options = req.options
  m.assertNotInvalid(options)
  m.assertNotEmpty(options.body)
  m.assertEqual(m.constants.reqTypes.del, options.method)

  headers = options.headers
  m.assertAAHasKeys(headers, ["x-roku-reserved-jwt", "x-roku-reserved-channel-id", "x-roku-reserved-channel-store-code", "x-roku-reserved-virtual-user-id", "x-roku-reserved-device-id", "x-roku-reserved-serial-number"])
  m.assertEqual(m.constants.productionApplicationId, headers["x-roku-reserved-channel-id"])

  requestBody = ParseJson(options.body)
  m.assertNotInvalid(requestBody.items)
  m.assertEqual("testContentId", requestBody.items[0].contentId)
  m.assertEqual("testEpisodeId", requestBody.items[0].episodeId)
End Function
