'@TestSuite [CmsApi] CmsApi.brs 

'@Setup
Function CmsApiSetup()
  constants = getConstants()
  request = TubiRequest(constants.settings.mode)
  auth = TubiAuth(constants, request)
  m.cmsApi = CmsApi(constants, request, auth)
End function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in CmsApi.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test unit tests relatedContentReqInfo
Function cmsApi_relatedContentReqInfo_test()
  infoKeys = [
    "url"
    "options"
  ]
  params = [
    "isKidsMode"
    "video_resources"
    "images[poster_tb]"
    "app_id"
    "platform"
    "device_id"
  ]

  kidsRelatedReqUrl = m.cmsApi.constants.urls.cms.relatedContent + "/123456/related"
  kidsRelatedReqOptions = {
    params: {
      "isKidsMode": true,
      "video_resources": m.cmsApi.constants.player.drmOrder
      "images[poster_tb]": "w" + m.cmsApi.constants.ui.imageSizes.poster[0].ToStr() + "h" + m.cmsApi.constants.ui.imageSizes.poster[1].ToStr() + "_poster"
      "app_id": m.cmsApi.constants.settings.shortAppName
      "platform": m.cmsApi.constants.platform
      "device_id": m.cmsApi.constants.deviceInfo.deviceId
    }
  }

  kidsRelatedReqInfo = m.cmsApi.relatedContentReqInfo("123456", true)

  m.assertEqual(kidsRelatedReqInfo.count(), 2)
  m.assertAAHasKeys(kidsRelatedReqInfo, infoKeys)
  m.assertEqual(kidsRelatedReqUrl, kidsRelatedReqInfo.url)
  m.assertAAHasKeys(kidsRelatedReqOptions.params, params)
  m.assertEqual(kidsRelatedReqOptions.params["isKidsMode"], kidsRelatedReqInfo.options.params["isKidsMode"])
  m.assertEqual(kidsRelatedReqOptions.params["video_resources"], kidsRelatedReqInfo.options.params["video_resources"])
  m.assertEqual(kidsRelatedReqOptions.params["images[poster_tb]"], kidsRelatedReqInfo.options.params["images[poster_tb]"])
  m.assertEqual(kidsRelatedReqOptions.params["app_id"], kidsRelatedReqInfo.options.params["app_id"])
  m.assertEqual(kidsRelatedReqOptions.params["platform"], kidsRelatedReqInfo.options.params["platform"])
  m.assertEqual(kidsRelatedReqOptions.params["device_id"], kidsRelatedReqInfo.options.params["device_id"])

  relatedReqUrl = m.cmsApi.constants.urls.cms.relatedContent + "/123456/related"
  relatedReqOptions = {
    params: {
      "isKidsMode": false,
      "video_resources": m.cmsApi.constants.player.drmOrder
      "images[poster_tb]": "w" + m.cmsApi.constants.ui.imageSizes.poster[0].ToStr() + "h" + m.cmsApi.constants.ui.imageSizes.poster[1].ToStr() + "_poster"
      "app_id": m.cmsApi.constants.settings.shortAppName
      "platform": m.cmsApi.constants.platform
      "device_id": m.cmsApi.constants.deviceInfo.deviceId
    }
  }

  relatedReqInfo = m.cmsApi.relatedContentReqInfo("123456", false)

  m.assertEqual(kidsRelatedReqInfo.count(), 2)
  m.assertAAHasKeys(kidsRelatedReqInfo, infoKeys)
  m.assertEqual(relatedReqUrl, relatedReqInfo.url)
  m.assertAAHasKeys(relatedReqInfo.options.params, params)
  m.assertEqual(relatedReqInfo.options.params["isKidsMode"], relatedReqOptions.params["isKidsMode"])
  m.assertEqual(relatedReqInfo.options.params["video_resources"], relatedReqOptions.params["video_resources"])
  m.assertEqual(relatedReqInfo.options.params["app_id"], relatedReqOptions.params["app_id"])
  m.assertEqual(relatedReqInfo.options.params["platform"], relatedReqOptions.params["platform"])
  m.assertEqual(relatedReqInfo.options.params["device_id"], relatedReqOptions.params["device_id"])
  m.assertEqual(relatedReqInfo.options.params["images[poster_tb]"], relatedReqOptions.params["images[poster_tb]"])
End Function


'@Test unit tests getUpNextContentRequestInfo
Function cmsApi_getUpNextContentRequestInfo_test()
  infoKeys = [
    "url"
    "options"
  ]
  params = [
    "video_resources"
    "app_id"
    "platform"
    "device_id"
    "custom_param"
  ]

  upNextUrl = m.cmsApi.constants.urls.cms.upNextContent + "/123456/next"
  upNextOptions = {
    params: {
      "app_id": m.cmsApi.constants.settings.shortAppName
      "platform": m.cmsApi.constants.platform
      "device_id": m.cmsApi.constants.deviceInfo.deviceId
      "video_resources": m.cmsApi.constants.player.drmOrder
      "custom_param": 42
    }
  }

  passedOptions = {
    params: {
      "custom_param": 42
    }
  }
  upNextInfo = m.cmsApi.getUpNextContentRequestInfo("123456", passedOptions)

  m.assertEqual(upNextInfo.count(), 2)
  m.assertAAHasKeys(upNextInfo, infoKeys)
  m.assertEqual(upNextInfo.url, upNextUrl)
  m.assertAAHasKeys(upNextInfo.options.params, params)
  m.assertEqual(upNextInfo.options.params["app_id"], upNextOptions.params["app_id"])
  m.assertEqual(upNextInfo.options.params["platform"], upNextOptions.params["platform"])
  m.assertEqual(upNextInfo.options.params["device_id"], upNextOptions.params["device_id"])
  m.assertEqual(upNextInfo.options.params["video_resources"], upNextOptions.params["video_resources"])
  m.assertEqual(upNextInfo.options.params["custom_param"], upNextOptions.params["custom_param"])
End Function


'@Test unit tests singleContentReqInfo
Function cmsApi_singleContentReqInfo_test()

End Function


'@Test unit tests thumbnailsReqInfo
Function cmsApi_thumbnailsReqInfo_test()

End Function


'@Test unit tests channelReq
Function cmsApi_channelReq_test()

End Function


'@Test unit tests homeScreenReq
Function cmsApi_homeScreenReq_test()

End Function


'@Test unit tests channelsCategoriesScreenReq
Function cmsApi_channelsCategoriesScreenReq_test()

End Function


'@Test unit tests categoryReq
Function cmsApi_categoryReq_test()

End Function


'@Test unit tests searchReq
Function cmsApi_searchReq_test()

End Function



'@Test unit tests    ' private commonOptions
Function cmsApi_commonOptions_test()

End Function

'@Test unit tests createAuthRequest
Function cmsApi_createAuthRequest_test()

End Function

'@Test unit tests setImageParams
Function cmsApi_setImageParams_test()

End Function

'@Test unit tests setTupianPosterParam
Function cmsApi_setTupianPosterParam_test()

End Function

'@Test unit tests setTupianLandscapeParam
Function cmsApi_setTupianLandscapeParam_test()

End Function

'@Test unit tests setTupianLargeVitgParam
Function cmsApi_setTupianLargeVitgParam_test()

End Function
