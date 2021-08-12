'@TestSuite [CmsApi] CmsApi.brs 

'@Setup
Function CmsApiSetup()
  constants = getConstants()
  request = TubiRequest(constants.settings)
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
    "gn_fields"
  ]

  upNextUrl = m.cmsApi.constants.urls.cms.upNextContent + "/123456/next"
  upNextOptions = {
    params: {
      "app_id": m.cmsApi.constants.settings.shortAppName
      "platform": m.cmsApi.constants.platform
      "device_id": m.cmsApi.constants.deviceInfo.deviceId
      "video_resources": m.cmsApi.constants.player.drmOrder
      "gn_fields": "tms_id"
      "custom_param": 42
    }
  }

  passedOptions = {
    params: {
      "custom_param": 42
    }
  }
  upNextInfo = m.cmsApi.upNextContentRequestInfo("123456", passedOptions)

  m.assertEqual(upNextInfo.count(), 2)
  m.assertAAHasKeys(upNextInfo, infoKeys)
  m.assertEqual(upNextInfo.url, upNextUrl)
  m.assertAAHasKeys(upNextInfo.options.params, params)
  m.assertEqual(upNextInfo.options.params["app_id"], upNextOptions.params["app_id"])
  m.assertEqual(upNextInfo.options.params["platform"], upNextOptions.params["platform"])
  m.assertEqual(upNextInfo.options.params["device_id"], upNextOptions.params["device_id"])
  m.assertEqual(upNextInfo.options.params["video_resources"], upNextOptions.params["video_resources"])
  m.assertEqual(upNextInfo.options.params["gn_fields"], upNextOptions.params["gn_fields"])
  m.assertEqual(upNextInfo.options.params["custom_param"], upNextOptions.params["custom_param"])
End Function



'@Test unit tests singleContentReqInfo
Function cmsApi_singleContentReqInfo_test()
  infoKeys = [
    "url"
    "options"
  ]
  params = [
    "app_id"
    "platform"
    "device_id"
    "content_id"
    "isKidsMode"
    "includeChannels"
    "video_resources"
    "gn_fields"
    "images[landscape_tb]"
  ]

  singleContentUrl = m.cmsApi.constants.urls.cms.singleContent
  singleContentOptions = {
    params: {
      "app_id": m.cmsApi.constants.settings.shortAppName
      "platform": m.cmsApi.constants.platform
      "device_id": m.cmsApi.constants.deviceInfo.deviceId
      "content_id": "123456"
      "isKidsMode": false
      "includeChannels": true
      "video_resources": m.cmsApi.constants.player.drmOrder
      "gn_fields": "tms_id"
      "images[landscape_tb]": "w" + m.cmsApi.constants.ui.imageSizes.landscape[0].ToStr() + "h" + m.cmsApi.constants.ui.imageSizes.landscape[1].ToStr() + "_hero"
    }
  }

  ' include channels, no kids mode
  singleContentInfo = m.cmsApi.singleContentReqInfo("123456", true, false)

  m.assertEqual(singleContentInfo.count(), 2)
  m.assertAAHasKeys(singleContentInfo, infoKeys)
  m.assertEqual(singleContentInfo.url, singleContentUrl)
  m.assertAAHasKeys(singleContentInfo.options.params, params)
  m.assertEqual(singleContentInfo.options.params["app_id"], singleContentOptions.params["app_id"])
  m.assertEqual(singleContentInfo.options.params["platform"], singleContentOptions.params["platform"])
  m.assertEqual(singleContentInfo.options.params["device_id"], singleContentOptions.params["device_id"])
  m.assertEqual(singleContentInfo.options.params["content_id"], singleContentOptions.params["content_id"])
  m.assertEqual(singleContentInfo.options.params["isKidsMode"], singleContentOptions.params["isKidsMode"])
  m.assertEqual(singleContentInfo.options.params["includeChannels"], singleContentOptions.params["includeChannels"])
  m.assertEqual(singleContentInfo.options.params["video_resources"], singleContentOptions.params["video_resources"])
  m.assertEqual(singleContentInfo.options.params["gn_fields"], singleContentOptions.params["gn_fields"])
  m.assertEqual(singleContentInfo.options.params["images[landscape_tb]"], singleContentOptions.params["images[landscape_tb]"])

  ' include channels, with kids mode
  singleContentInfo = m.cmsApi.singleContentReqInfo("123456", true, true)

  singleContentOptions.params["isKidsMode"] = true

  m.assertEqual(singleContentInfo.count(), 2)
  m.assertAAHasKeys(singleContentInfo, infoKeys)
  m.assertEqual(singleContentInfo.url, singleContentUrl)
  m.assertAAHasKeys(singleContentInfo.options.params, params)
  m.assertEqual(singleContentInfo.options.params["app_id"], singleContentOptions.params["app_id"])
  m.assertEqual(singleContentInfo.options.params["platform"], singleContentOptions.params["platform"])
  m.assertEqual(singleContentInfo.options.params["device_id"], singleContentOptions.params["device_id"])
  m.assertEqual(singleContentInfo.options.params["content_id"], singleContentOptions.params["content_id"])
  m.assertEqual(singleContentInfo.options.params["isKidsMode"], singleContentOptions.params["isKidsMode"])
  m.assertEqual(singleContentInfo.options.params["includeChannels"], singleContentOptions.params["includeChannels"])
  m.assertEqual(singleContentInfo.options.params["video_resources"], singleContentOptions.params["video_resources"])
  m.assertEqual(singleContentInfo.options.params["gn_fields"], singleContentOptions.params["gn_fields"])
  m.assertEqual(singleContentInfo.options.params["images[landscape_tb]"], singleContentOptions.params["images[landscape_tb]"])

  ' don't include channels, with kids mode
  singleContentInfo = m.cmsApi.singleContentReqInfo("123456", false, true)

  singleContentOptions.params["includeChannels"] = false
  singleContentOptions.params["isKidsMode"] = true

  m.assertEqual(singleContentInfo.count(), 2)
  m.assertAAHasKeys(singleContentInfo, infoKeys)
  m.assertEqual(singleContentInfo.url, singleContentUrl)
  m.assertAAHasKeys(singleContentInfo.options.params, params)
  m.assertEqual(singleContentInfo.options.params["app_id"], singleContentOptions.params["app_id"])
  m.assertEqual(singleContentInfo.options.params["platform"], singleContentOptions.params["platform"])
  m.assertEqual(singleContentInfo.options.params["device_id"], singleContentOptions.params["device_id"])
  m.assertEqual(singleContentInfo.options.params["content_id"], singleContentOptions.params["content_id"])
  m.assertEqual(singleContentInfo.options.params["isKidsMode"], singleContentOptions.params["isKidsMode"])
  m.assertEqual(singleContentInfo.options.params["includeChannels"], singleContentOptions.params["includeChannels"])
  m.assertEqual(singleContentInfo.options.params["video_resources"], singleContentOptions.params["video_resources"])
  m.assertEqual(singleContentInfo.options.params["gn_fields"], singleContentOptions.params["gn_fields"])
  m.assertEqual(singleContentInfo.options.params["images[landscape_tb]"], singleContentOptions.params["images[landscape_tb]"])
End Function


'@Test unit tests thumbnailsReqInfo
Function cmsApi_thumbnailsReqInfo_test()
  infoKeys = [
    "url"
    "options"
  ]
  params = [
    "app_id"
    "platform"
    "device_id"
    "type"
    "max_width"
  ]

  thumbsUrl = m.cmsApi.constants.urls.cms.thumbnails + "/123456/thumbnail_sprites"
  thumbsOptions = {
    params: {
      "app_id": m.cmsApi.constants.settings.shortAppName
      "platform": m.cmsApi.constants.platform
      "device_id": m.cmsApi.constants.deviceInfo.deviceId
      "type": "5x"
      "max_width": m.cmsApi.constants.deviceInfo.displayWidth
    }
  }

  thumbsInfo = m.cmsApi.thumbnailsReqInfo("123456")

  m.assertEqual(thumbsInfo.count(), 2)
  m.assertAAHasKeys(thumbsInfo, infoKeys)
  m.assertEqual(thumbsInfo.url, thumbsUrl)
  m.assertAAHasKeys(thumbsInfo.options.params, params)
  m.assertEqual(thumbsInfo.options.params["app_id"], thumbsOptions.params["app_id"])
  m.assertEqual(thumbsInfo.options.params["platform"], thumbsOptions.params["platform"])
  m.assertEqual(thumbsInfo.options.params["device_id"], thumbsOptions.params["device_id"])
  m.assertEqual(thumbsInfo.options.params["type"], thumbsOptions.params["type"])
  m.assertEqual(thumbsInfo.options.params["max_width"], thumbsOptions.params["max_width"])
End Function


'@Test unit tests channelReqInfo
Function cmsApi_channelReqInfo_test()
  infoKeys = [
    "url"
    "options"
  ]
  params = [
    "app_id"
    "platform"
    "device_id"
    "cursor"
    "limit"
    "isKidsMode"
    "includeChannels"
    "images[poster_tb]"
  ]

  channelUrl = m.cmsApi.constants.urls.matrix.channel + "/my_channel"
  channelOptions = {
    params: {
      "app_id": m.cmsApi.constants.settings.shortAppName
      "platform": m.cmsApi.constants.platform
      "device_id": m.cmsApi.constants.deviceInfo.deviceId
      "cursor": 0
      "limit": 54
      "isKidsMode": false
      "includeChannels": true
      "images[poster_tb]": "w" + m.cmsApi.constants.ui.imageSizes.poster[0].ToStr() + "h" + m.cmsApi.constants.ui.imageSizes.poster[1].ToStr() + "_poster"
    }
  }

  ' no kids mode
  channelInfo = m.cmsApi.channelReqInfo("my_channel", 54, false)

  m.assertEqual(channelInfo.count(), 2)
  m.assertAAHasKeys(channelInfo, infoKeys)
  m.assertEqual(channelInfo.url, channelUrl)
  m.assertAAHasKeys(channelInfo.options.params, params)
  m.assertEqual(channelInfo.options.params["app_id"], channelOptions.params["app_id"])
  m.assertEqual(channelInfo.options.params["platform"], channelOptions.params["platform"])
  m.assertEqual(channelInfo.options.params["device_id"], channelOptions.params["device_id"])
  m.assertEqual(channelInfo.options.params["cursor"], channelOptions.params["cursor"])
  m.assertEqual(channelInfo.options.params["limit"], channelOptions.params["limit"])
  m.assertEqual(channelInfo.options.params["isKidsMode"], channelOptions.params["isKidsMode"])
  m.assertEqual(channelInfo.options.params["includeChannels"], channelOptions.params["includeChannels"])
  m.assertEqual(channelInfo.options.params["images[poster_tb]"], channelOptions.params["images[poster_tb]"])

  ' with kids mode
  channelInfo = m.cmsApi.channelReqInfo("my_channel", 12, true)
  channelOptions.params["limit"] = 12
  channelOptions.params["isKidsMode"] = true

  m.assertEqual(channelInfo.count(), 2)
  m.assertAAHasKeys(channelInfo, infoKeys)
  m.assertEqual(channelInfo.url, channelUrl)
  m.assertAAHasKeys(channelInfo.options.params, params)
  m.assertEqual(channelInfo.options.params["app_id"], channelOptions.params["app_id"])
  m.assertEqual(channelInfo.options.params["platform"], channelOptions.params["platform"])
  m.assertEqual(channelInfo.options.params["device_id"], channelOptions.params["device_id"])
  m.assertEqual(channelInfo.options.params["cursor"], channelOptions.params["cursor"])
  m.assertEqual(channelInfo.options.params["limit"], channelOptions.params["limit"])
  m.assertEqual(channelInfo.options.params["isKidsMode"], channelOptions.params["isKidsMode"])
  m.assertEqual(channelInfo.options.params["includeChannels"], channelOptions.params["includeChannels"])
  m.assertEqual(channelInfo.options.params["images[poster_tb]"], channelOptions.params["images[poster_tb]"])
End Function


'@Test unit tests homeScreenReqInfo
Function cmsApi_homeScreenReqInfo_test()
  infoKeys = [
    "url"
    "options"
  ]
  params = [
    "app_id"
    "platform"
    "device_id"
    "includeEmptyHistory"
    "includeEmptyQueue"
    "isKidsMode"
    "includeVideoInGrid"
    "images[landscape_tb]"
    "images[poster_tb]"
    "images[vitg_tb]"
    "customParam"
  ]
  headers = [
    "x-tubi-inject-live-news"
    "x-custom-header"
    "x-client-platform"
    "x-client-version"
  ]

  homeUrl = m.cmsApi.constants.urls.matrix.homescreen
  homeOptions = {
    params: {
      "app_id": m.cmsApi.constants.settings.shortAppName
      "platform": m.cmsApi.constants.platform
      "device_id": m.cmsApi.constants.deviceInfo.deviceId
      "includeEmptyHistory": true
      "includeEmptyQueue": true
      "isKidsMode": false
      "includeVideoInGrid": true
      "images[poster_tb]": "w" + m.cmsApi.constants.ui.imageSizes.poster[0].ToStr() + "h" + m.cmsApi.constants.ui.imageSizes.poster[1].ToStr() + "_poster"
      "images[landscape_tb]": "w" + m.cmsApi.constants.ui.imageSizes.landscape[0].ToStr() + "h" + m.cmsApi.constants.ui.imageSizes.landscape[1].ToStr() + "_hero"
      "images[vitg_tb]": "w" + m.cmsApi.constants.ui.imageSizes.largeVITG[0].ToStr() + "h" + m.cmsApi.constants.ui.imageSizes.largeVITG[1].ToStr() + "_hero"
      "contentMode": m.cmsApi.constants.ui.contentMode.homescreen
      "customParam": "custom_param_value"
    }
    headers: {
      "x-tubi-inject-live-news": "true"
      "x-custom-header": "custom_header_value"
      "x-client-platform": m.cmsApi.constants.headers.commonUapi["x-client-platform"] 
      "x-client-version": m.cmsApi.constants.headers.commonUapi["x-client-version"]
    }
  }

  passedOptions = {
    params: {
      "contentMode": m.cmsApi.constants.ui.contentMode.homescreen
      "customParam": "custom_param_value"
    }
    headers: {
      "x-custom-header": "custom_header_value"
    }
  }

  ' no kids mode and homescreen contentMode
  homeInfo = m.cmsApi.homeScreenReqInfo(false, passedOptions)

  m.assertEqual(homeInfo.count(), 2)
  m.assertAAHasKeys(homeInfo, infoKeys)
  m.assertEqual(homeInfo.url, homeUrl)
  m.assertAAHasKeys(homeInfo.options.params, params)
  m.assertAAHasKeys(homeInfo.options.headers, headers)
  m.assertEqual(homeInfo.options.params["app_id"], homeOptions.params["app_id"])
  m.assertEqual(homeInfo.options.params["platform"], homeOptions.params["platform"])
  m.assertEqual(homeInfo.options.params["device_id"], homeOptions.params["device_id"])
  m.assertEqual(homeInfo.options.params["includeEmptyHistory"], homeOptions.params["includeEmptyHistory"])
  m.assertEqual(homeInfo.options.params["includeEmptyQueue"], homeOptions.params["includeEmptyQueue"])
  m.assertEqual(homeInfo.options.params["isKidsMode"], homeOptions.params["isKidsMode"])
  m.assertEqual(homeInfo.options.params["includeVideoInGrid"], homeOptions.params["includeVideoInGrid"])
  m.assertEqual(homeInfo.options.params["images[poster_tb]"], homeOptions.params["images[poster_tb]"])
  m.assertEqual(homeInfo.options.params["images[landscape_tb]"], homeOptions.params["images[landscape_tb]"])
  m.assertEqual(homeInfo.options.params["images[vitg_tb]"], homeOptions.params["images[vitg_tb]"])
  m.assertEqual(homeInfo.options.params["contentMode"], homeOptions.params["contentMode"])
  m.assertEqual(homeInfo.options.params["customParam"], homeOptions.params["customParam"])
  m.assertEqual(homeInfo.options.headers["x-tubi-inject-live-news"], homeOptions.headers["x-tubi-inject-live-news"])
  m.assertEqual(homeInfo.options.headers["x-custom-header"], homeOptions.headers["x-custom-header"])
  m.assertEqual(homeInfo.options.headers["x-client-platform"], homeOptions.headers["x-client-platform"])
  m.assertEqual(homeInfo.options.headers["x-client-version"], homeOptions.headers["x-client-version"])

  ' with kids mode and homescreen contentMode
  homeInfo = m.cmsApi.homeScreenReqInfo(true, passedOptions)
  homeOptions.params["isKidsMode"] = true

  m.assertEqual(homeInfo.count(), 2)
  m.assertAAHasKeys(homeInfo, infoKeys)
  m.assertEqual(homeInfo.url, homeUrl)
  m.assertAAHasKeys(homeInfo.options.params, params)
  m.assertAAHasKeys(homeInfo.options.headers, headers)
  m.assertEqual(homeInfo.options.params["app_id"], homeOptions.params["app_id"])
  m.assertEqual(homeInfo.options.params["platform"], homeOptions.params["platform"])
  m.assertEqual(homeInfo.options.params["device_id"], homeOptions.params["device_id"])
  m.assertEqual(homeInfo.options.params["includeEmptyHistory"], homeOptions.params["includeEmptyHistory"])
  m.assertEqual(homeInfo.options.params["includeEmptyQueue"], homeOptions.params["includeEmptyQueue"])
  m.assertEqual(homeInfo.options.params["isKidsMode"], homeOptions.params["isKidsMode"])
  m.assertEqual(homeInfo.options.params["includeVideoInGrid"], homeOptions.params["includeVideoInGrid"])
  m.assertEqual(homeInfo.options.params["images[poster_tb]"], homeOptions.params["images[poster_tb]"])
  m.assertEqual(homeInfo.options.params["images[landscape_tb]"], homeOptions.params["images[landscape_tb]"])
  m.assertEqual(homeInfo.options.params["images[vitg_tb]"], homeOptions.params["images[vitg_tb]"])
  m.assertEqual(homeInfo.options.params["contentMode"], homeOptions.params["contentMode"])
  m.assertEqual(homeInfo.options.params["customParam"], homeOptions.params["customParam"])
  m.assertEqual(homeInfo.options.headers["x-tubi-inject-live-news"], homeOptions.headers["x-tubi-inject-live-news"])
  m.assertEqual(homeInfo.options.headers["x-custom-header"], homeOptions.headers["x-custom-header"])
  m.assertEqual(homeInfo.options.headers["x-client-platform"], homeOptions.headers["x-client-platform"])
  m.assertEqual(homeInfo.options.headers["x-client-version"], homeOptions.headers["x-client-version"])

  ' with contentMode = "tv"
  passedOptions.params["contentMode"] = m.cmsApi.constants.ui.contentMode.tv
  homeInfo = m.cmsApi.homeScreenReqInfo(false, passedOptions)
  homeOptions.params["isKidsMode"] = false
  homeOptions.params["contentMode"] = m.cmsApi.constants.ui.contentMode.tv
  homeOptions.headers["x-tubi-inject-live-news"] = "false"

  m.assertEqual(homeInfo.count(), 2)
  m.assertAAHasKeys(homeInfo, infoKeys)
  m.assertEqual(homeInfo.url, homeUrl)
  m.assertAAHasKeys(homeInfo.options.params, params)
  m.assertAAHasKeys(homeInfo.options.headers, headers)
  m.assertEqual(homeInfo.options.params["app_id"], homeOptions.params["app_id"])
  m.assertEqual(homeInfo.options.params["platform"], homeOptions.params["platform"])
  m.assertEqual(homeInfo.options.params["device_id"], homeOptions.params["device_id"])
  m.assertEqual(homeInfo.options.params["includeEmptyHistory"], homeOptions.params["includeEmptyHistory"])
  m.assertEqual(homeInfo.options.params["includeEmptyQueue"], homeOptions.params["includeEmptyQueue"])
  m.assertEqual(homeInfo.options.params["isKidsMode"], homeOptions.params["isKidsMode"])
  m.assertEqual(homeInfo.options.params["includeVideoInGrid"], homeOptions.params["includeVideoInGrid"])
  m.assertEqual(homeInfo.options.params["images[poster_tb]"], homeOptions.params["images[poster_tb]"])
  m.assertEqual(homeInfo.options.params["images[landscape_tb]"], homeOptions.params["images[landscape_tb]"])
  m.assertEqual(homeInfo.options.params["images[vitg_tb]"], homeOptions.params["images[vitg_tb]"])
  m.assertEqual(homeInfo.options.params["contentMode"], homeOptions.params["contentMode"])
  m.assertEqual(homeInfo.options.params["customParam"], homeOptions.params["customParam"])
  m.assertEqual(homeInfo.options.headers["x-tubi-inject-live-news"], homeOptions.headers["x-tubi-inject-live-news"])
  m.assertEqual(homeInfo.options.headers["x-custom-header"], homeOptions.headers["x-custom-header"])
  m.assertEqual(homeInfo.options.headers["x-client-platform"], homeOptions.headers["x-client-platform"])
  m.assertEqual(homeInfo.options.headers["x-client-version"], homeOptions.headers["x-client-version"])

  ' with contentMode = "news"
  passedOptions.params["contentMode"] = m.cmsApi.constants.ui.contentMode.news
  homeInfo = m.cmsApi.homeScreenReqInfo(false, passedOptions)
  homeOptions.params["contentMode"] = m.cmsApi.constants.ui.contentMode.news
  homeOptions.params.delete("images[landscape_tb]")
  homeOptions.params.delete("images[poster_tb]")
  homeOptions.params.delete("images[vitg_tb]")
  params = [
    "app_id"
    "platform"
    "device_id"
    "includeEmptyHistory"
    "includeEmptyQueue"
    "isKidsMode"
    "includeVideoInGrid"
  ]
  homeOptions.headers["x-tubi-inject-live-news"] = "true"
  headers = [
    "x-tubi-inject-live-news"
    "x-custom-header"
  ]

  m.assertEqual(homeInfo.count(), 2)
  m.assertAAHasKeys(homeInfo, infoKeys)
  m.assertEqual(homeInfo.url, homeUrl)
  m.assertAAHasKeys(homeInfo.options.params, params)
  m.assertAAHasKeys(homeInfo.options.headers, headers)
  m.assertEqual(homeInfo.options.params["app_id"], homeOptions.params["app_id"])
  m.assertEqual(homeInfo.options.params["platform"], homeOptions.params["platform"])
  m.assertEqual(homeInfo.options.params["device_id"], homeOptions.params["device_id"])
  m.assertEqual(homeInfo.options.params["includeEmptyHistory"], homeOptions.params["includeEmptyHistory"])
  m.assertEqual(homeInfo.options.params["includeEmptyQueue"], homeOptions.params["includeEmptyQueue"])
  m.assertEqual(homeInfo.options.params["isKidsMode"], homeOptions.params["isKidsMode"])
  m.assertEqual(homeInfo.options.params["includeVideoInGrid"], homeOptions.params["includeVideoInGrid"])
  m.assertEqual(homeInfo.options.params["contentMode"], homeOptions.params["contentMode"])
  m.assertEqual(homeInfo.options.params["customParam"], homeOptions.params["customParam"])
  m.assertEqual(homeInfo.options.headers["x-tubi-inject-live-news"], homeOptions.headers["x-tubi-inject-live-news"])
  m.assertEqual(homeInfo.options.headers["x-custom-header"], homeOptions.headers["x-custom-header"])
  m.assertEqual(homeInfo.options.headers["x-client-platform"], homeOptions.headers["x-client-platform"])
  m.assertEqual(homeInfo.options.headers["x-client-version"], homeOptions.headers["x-client-version"])
End Function


'@Test unit tests categoryReqInfo
Function cmsApi_categoryReqInfo_test()
  infoKeys = [
    "url"
    "options"
  ]
  params = [
    "app_id"
    "platform"
    "device_id"
    "isKidsMode"
    "includeChannels"
    "includeVideoInGrid"
    "cursor"
    "limit"
    "images[landscape_tb]"
    "images[poster_tb]"
    "images[vitg_tb]"
    "contentMode"
    "customParam"
  ]
  headers = [
    "x-tubi-inject-live-news"
    "x-custom-header"
    "x-client-platform"
    "x-client-version"
  ]

  categoryUrl = m.cmsApi.constants.urls.matrix.channel + "/my_category"
  categoryOptions = {
    params: {
      "app_id": m.cmsApi.constants.settings.shortAppName
      "platform": m.cmsApi.constants.platform
      "device_id": m.cmsApi.constants.deviceInfo.deviceId
      "isKidsMode": false
      "includeChannels": true
      "includeVideoInGrid": true
      "cursor": 0
      "limit": 19
      "images[poster_tb]": "w" + m.cmsApi.constants.ui.imageSizes.poster[0].ToStr() + "h" + m.cmsApi.constants.ui.imageSizes.poster[1].ToStr() + "_poster"
      "images[landscape_tb]": "w" + m.cmsApi.constants.ui.imageSizes.landscape[0].ToStr() + "h" + m.cmsApi.constants.ui.imageSizes.landscape[1].ToStr() + "_hero"
      "images[vitg_tb]": "w" + m.cmsApi.constants.ui.imageSizes.largeVITG[0].ToStr() + "h" + m.cmsApi.constants.ui.imageSizes.largeVITG[1].ToStr() + "_hero"
      "contentMode": m.cmsApi.constants.ui.contentMode.homescreen
      "customParam": "custom_param_value"
    }
    headers: {
      "x-tubi-inject-live-news": "true"
      "x-custom-header": "custom_header_value"
      "x-client-platform": m.cmsApi.constants.headers.commonUapi["x-client-platform"] 
      "x-client-version": m.cmsApi.constants.headers.commonUapi["x-client-version"]
    }
  }

  ' no kids mode
  passedOptions = {
    params: {
      "customParam": "custom_param_value"
      "contentMode": m.cmsApi.constants.ui.contentMode.homescreen
    }
    headers: {
      "x-custom-header": "custom_header_value"
    }
  }
  name = m.cmsApi.constants.reqNames.getCategory
  categoryInfo = m.cmsApi.categoryReqInfo("my_category", name, false, passedOptions)

  m.assertEqual(categoryInfo.count(), 2)
  m.assertAAHasKeys(categoryInfo, infoKeys)
  m.assertEqual(categoryInfo.url, categoryUrl)
  m.assertAAHasKeys(categoryInfo.options.params, params)
  m.assertAAHasKeys(categoryInfo.options.headers, headers)
  m.assertEqual(categoryInfo.options.params["app_id"], categoryOptions.params["app_id"])
  m.assertEqual(categoryInfo.options.params["platform"], categoryOptions.params["platform"])
  m.assertEqual(categoryInfo.options.params["device_id"], categoryOptions.params["device_id"])
  m.assertEqual(categoryInfo.options.params["isKidsMode"], categoryOptions.params["isKidsMode"])
  m.assertEqual(categoryInfo.options.params["includeChannels"], categoryOptions.params["includeChannels"])
  m.assertEqual(categoryInfo.options.params["includeVideoInGrid"], categoryOptions.params["includeVideoInGrid"])
  m.assertEqual(categoryInfo.options.params["images[poster_tb]"], categoryOptions.params["images[poster_tb]"])
  m.assertEqual(categoryInfo.options.params["images[landscape_tb]"], categoryOptions.params["images[landscape_tb]"])
  m.assertEqual(categoryInfo.options.params["images[vitg_tb]"], categoryOptions.params["images[vitg_tb]"])
  m.assertEqual(categoryInfo.options.params["contentMode"], categoryOptions.params["contentMode"])
  m.assertEqual(categoryInfo.options.params["customParam"], categoryOptions.params["customParam"])
  m.assertEqual(categoryInfo.options.headers["x-tubi-inject-live-news"], categoryOptions.headers["x-tubi-inject-live-news"])
  m.assertEqual(categoryInfo.options.headers["x-custom-header"], categoryOptions.headers["x-custom-header"])
  m.assertEqual(categoryInfo.options.headers["x-client-platform"], categoryOptions.headers["x-client-platform"])
  m.assertEqual(categoryInfo.options.headers["x-client-version"], categoryOptions.headers["x-client-version"])

  ' with kids mode
  categoryOptions.params["isKidsMode"] = true
  categoryInfo = m.cmsApi.categoryReqInfo("my_category", name, true, passedOptions)

  m.assertEqual(categoryInfo.count(), 2)
  m.assertAAHasKeys(categoryInfo, infoKeys)
  m.assertEqual(categoryInfo.url, categoryUrl)
  m.assertAAHasKeys(categoryInfo.options.params, params)
  m.assertAAHasKeys(categoryInfo.options.headers, headers)
  m.assertEqual(categoryInfo.options.params["app_id"], categoryOptions.params["app_id"])
  m.assertEqual(categoryInfo.options.params["platform"], categoryOptions.params["platform"])
  m.assertEqual(categoryInfo.options.params["device_id"], categoryOptions.params["device_id"])
  m.assertEqual(categoryInfo.options.params["isKidsMode"], categoryOptions.params["isKidsMode"])
  m.assertEqual(categoryInfo.options.params["includeChannels"], categoryOptions.params["includeChannels"])
  m.assertEqual(categoryInfo.options.params["includeVideoInGrid"], categoryOptions.params["includeVideoInGrid"])
  m.assertEqual(categoryInfo.options.params["images[poster_tb]"], categoryOptions.params["images[poster_tb]"])
  m.assertEqual(categoryInfo.options.params["images[landscape_tb]"], categoryOptions.params["images[landscape_tb]"])
  m.assertEqual(categoryInfo.options.params["images[vitg_tb]"], categoryOptions.params["images[vitg_tb]"])
  m.assertEqual(categoryInfo.options.params["contentMode"], categoryOptions.params["contentMode"])
  m.assertEqual(categoryInfo.options.params["customParam"], categoryOptions.params["customParam"])
  m.assertEqual(categoryInfo.options.headers["x-tubi-inject-live-news"], categoryOptions.headers["x-tubi-inject-live-news"])
  m.assertEqual(categoryInfo.options.headers["x-custom-header"], categoryOptions.headers["x-custom-header"])
  m.assertEqual(categoryInfo.options.headers["x-client-platform"], categoryOptions.headers["x-client-platform"])
  m.assertEqual(categoryInfo.options.headers["x-client-version"], categoryOptions.headers["x-client-version"])

  ' with contentMode not homescreen
  categoryOptions.params["isKidsMode"] = false
  categoryOptions.params["contentMode"] = m.cmsApi.constants.ui.contentMode.latino
  categoryOptions.headers["x-tubi-inject-live-news"] = "false"
  passedOptions.params.contentMode = m.cmsApi.constants.ui.contentMode.latino
  categoryInfo = m.cmsApi.categoryReqInfo("my_category", name, false, passedOptions)

  m.assertEqual(categoryInfo.count(), 2)
  m.assertAAHasKeys(categoryInfo, infoKeys)
  m.assertEqual(categoryInfo.url, categoryUrl)
  m.assertAAHasKeys(categoryInfo.options.params, params)
  m.assertAAHasKeys(categoryInfo.options.headers, headers)
  m.assertEqual(categoryInfo.options.params["app_id"], categoryOptions.params["app_id"])
  m.assertEqual(categoryInfo.options.params["platform"], categoryOptions.params["platform"])
  m.assertEqual(categoryInfo.options.params["device_id"], categoryOptions.params["device_id"])
  m.assertEqual(categoryInfo.options.params["isKidsMode"], categoryOptions.params["isKidsMode"])
  m.assertEqual(categoryInfo.options.params["includeChannels"], categoryOptions.params["includeChannels"])
  m.assertEqual(categoryInfo.options.params["includeVideoInGrid"], categoryOptions.params["includeVideoInGrid"])
  m.assertEqual(categoryInfo.options.params["images[poster_tb]"], categoryOptions.params["images[poster_tb]"])
  m.assertEqual(categoryInfo.options.params["images[landscape_tb]"], categoryOptions.params["images[landscape_tb]"])
  m.assertEqual(categoryInfo.options.params["images[vitg_tb]"], categoryOptions.params["images[vitg_tb]"])
  m.assertEqual(categoryInfo.options.params["contentMode"], categoryOptions.params["contentMode"])
  m.assertEqual(categoryInfo.options.params["customParam"], categoryOptions.params["customParam"])
  m.assertEqual(categoryInfo.options.headers["x-tubi-inject-live-news"], categoryOptions.headers["x-tubi-inject-live-news"])
  m.assertEqual(categoryInfo.options.headers["x-custom-header"], categoryOptions.headers["x-custom-header"])
  m.assertEqual(categoryInfo.options.headers["x-client-platform"], categoryOptions.headers["x-client-platform"])
  m.assertEqual(categoryInfo.options.headers["x-client-version"], categoryOptions.headers["x-client-version"])
End Function


'@Test unit tests searchReqInfo
Function cmsApi_searchReqInfo_test()
  infoKeys = [
    "url"
    "options"
  ]
  params = [
    "app_id"
    "platform"
    "device_id"
    "search"
    "isKidsMode"
    "images[poster_tb]"
  ]

  searchUrl = m.cmsApi.constants.urls.cms.search

  searchOptions = {
    params: {
      "app_id": m.cmsApi.constants.settings.shortAppName
      "platform": m.cmsApi.constants.platform
      "device_id": m.cmsApi.constants.deviceInfo.deviceId
      "search": "search_text"
      "isKidsMode": false
      "images[poster_tb]": "w" + m.cmsApi.constants.ui.imageSizes.poster[0].ToStr() + "h" + m.cmsApi.constants.ui.imageSizes.poster[1].ToStr() + "_poster"
    }
  }

  ' without kids mode
  searchInfo = m.cmsApi.searchReqInfo("search_text", false)

  m.assertEqual(searchInfo.count(), 2)
  m.assertAAHasKeys(searchInfo, infoKeys)
  m.assertEqual(searchInfo.url, searchUrl)
  m.assertAAHasKeys(searchInfo.options.params, params)
  m.assertEqual(searchInfo.options.params["app_id"], searchOptions.params["app_id"])
  m.assertEqual(searchInfo.options.params["platform"], searchOptions.params["platform"])
  m.assertEqual(searchInfo.options.params["device_id"], searchOptions.params["device_id"])
  m.assertEqual(searchInfo.options.params["search"], searchOptions.params["search"])
  m.assertEqual(searchInfo.options.params["isKidsMode"], searchOptions.params["isKidsMode"])
  m.assertEqual(searchInfo.options.params["images[poster_tb]"], searchOptions.params["images[poster_tb]"])

  ' with kids mode
  searchInfo = m.cmsApi.searchReqInfo("search_text", false)

  m.assertEqual(searchInfo.count(), 2)
  m.assertAAHasKeys(searchInfo, infoKeys)
  m.assertEqual(searchInfo.url, searchUrl)
  m.assertAAHasKeys(searchInfo.options.params, params)
  m.assertEqual(searchInfo.options.params["app_id"], searchOptions.params["app_id"])
  m.assertEqual(searchInfo.options.params["platform"], searchOptions.params["platform"])
  m.assertEqual(searchInfo.options.params["device_id"], searchOptions.params["device_id"])
  m.assertEqual(searchInfo.options.params["search"], searchOptions.params["search"])
  m.assertEqual(searchInfo.options.params["isKidsMode"], searchOptions.params["isKidsMode"])
  m.assertEqual(searchInfo.options.params["images[poster_tb]"], searchOptions.params["images[poster_tb]"])
End Function


'@Test unit tests commonOptions
Function cmsApi_commonOptions_test()
  options = [
    "headers"
    "params"
  ]
  params = [
    "app_id"
    "platform"
    "device_id"
  ]

  deviceId = m.cmsApi.constants.deviceInfo.deviceId
  platform = m.cmsApi.constants.platform
  appId = m.cmsApi.constants.settings.shortAppName

  commonOptions = m.cmsApi.commonOptions()
  m.assertAAHasKeys(commonOptions, options)
  m.assertAAHasKeys(commonOptions.params, params)
  m.assertEqual(commonOptions.params.app_id, appId)
  m.assertEqual(commonOptions.params.platform, platform)
  m.assertEqual(commonOptions.params.device_id, deviceId)
  m.assertEqual(commonOptions.headers["Content-Type"], "application/json")
End Function


'@Test unit tests createAuthRequest
Function cmsApi_createAuthRequest_test()
  url = "https://someUrl"
  reqName = "getHomepage"
  params = {
    userid: "1234"
  }
  headers = {
    "x-custom-header": "header_value"
  }
  body = {
    content_id: "5678"
  }
  options = {
    params: params
    headers: headers
    body: FormatJson(body)
  }

  ' test expecting an auth request
  m.cmsApi.auth.getAuthInfo = function()
    return {
       refreshToken: "xyz"
       accessToken: "abc"
       expireTime: "60"
       userId: "1234"
    }
  end function

  authInfo = m.cmsApi.auth.getAuthInfo()
  authHeaders = m.cmsApi.auth.getAuthHeaders(authInfo.accessToken)
  authRequest = m.cmsApi.createAuthRequest(url, reqName, options)

  m.assertNotInvalid(authRequest.url)
  m.assertNotInvalid(authRequest.name)
  m.assertNotInvalid(authRequest.params)
  m.assertNotInvalid(authRequest.body)
  m.assertNotInvalid(authRequest.headers)
  m.assertNotInvalid(authRequest.handleEvent)
  m.assertNotInvalid(authRequest.uuid)
  m.assertNotInvalid(authRequest.isHttps)
  m.assertNotInvalid(authRequest.getAuthHeaders)
  m.assertNotInvalid(authRequest.refreshAuthToken)
  m.assertNotInvalid(authRequest.requestTokenRefresh)
  m.assertNotInvalid(authRequest.updateAuthInfo)
  m.assertNotInvalid(authRequest.saveAuthInfo)
  m.assertNotInvalid(authRequest.handleRefreshResponse)
  m.assertNotInvalid(authRequest.deleteAuthInfo)
  m.assertNotInvalid(authRequest.constants)
  m.assertNotInvalid(authRequest.request)
  m.assertNotInvalid(authRequest.authInfo)
  m.assertNotInvalid(authRequest.regWrite)
  m.assertNotInvalid(authRequest.authRegSection)
  m.assertEqual(authRequest.params["userid"], params.userid)
  m.assertEqual(authRequest.headers["x-custom-header"], headers["x-custom-header"])
  m.assertEqual(authRequest.body, FormatJson(body))
  m.assertTrue(authRequest.isHttps)
  m.assertEqual(authRequest.headers.authorization, authHeaders.authorization)
  m.assertEqual(authRequest.headers.["Content-Type"], authHeaders["Content-Type"])
  m.assertEqual(authRequest.headers.["x-client-platform"], authHeaders["x-client-platform"])
  m.assertEqual(authRequest.headers.["x-client-version"], authHeaders["x-client-version"])

  ' test expecting a non auth request
  params = {
    userid: "1234"
  }
  headers = {
    "x-custom-header": "header_value"
  }
  body = {
    content_id: "5678"
  }
  options = {
    params: params
    headers: headers
    body: FormatJson(body)
  }

  m.cmsApi.auth.getAuthInfo = function()
    return invalid
  end function
  nonAuthRequest = m.cmsApi.createAuthRequest(url, reqName, options)

  m.assertNotInvalid(nonAuthRequest.url)
  m.assertNotInvalid(nonAuthRequest.name)
  m.assertNotInvalid(nonAuthRequest.params)
  m.assertNotInvalid(nonAuthRequest.body)
  m.assertNotInvalid(nonAuthRequest.headers)
  m.assertNotInvalid(nonAuthRequest.handleEvent)
  m.assertNotInvalid(nonAuthRequest.uuid)
  m.assertNotInvalid(nonAuthRequest.isHttps)
  m.assertInvalid(nonAuthRequest.getAuthHeaders)
  m.assertInvalid(nonAuthRequest.refreshAuthToken)
  m.assertInvalid(nonAuthRequest.requestTokenRefresh)
  m.assertInvalid(nonAuthRequest.updateAuthInfo)
  m.assertInvalid(nonAuthRequest.saveAuthInfo)
  m.assertInvalid(nonAuthRequest.handleRefreshResponse)
  m.assertInvalid(nonAuthRequest.deleteAuthInfo)
  m.assertInvalid(nonAuthRequest.request)
  m.assertInvalid(nonAuthRequest.authInfo)
  m.assertInvalid(nonAuthRequest.regWrite)
  m.assertInvalid(nonAuthRequest.authRegSection)
  m.assertEqual(nonAuthRequest.params["userid"], params.userid)
  m.assertEqual(nonAuthRequest.headers["x-custom-header"], headers["x-custom-header"])
  m.assertInvalid(nonAuthRequest.headers["x-client-platform"])
  m.assertInvalid(nonAuthRequest.headers["x-client-version"])
  m.assertEqual(authRequest.body, FormatJson(body))
  m.assertTrue(nonAuthRequest.isHttps)
  m.assertInvalid(nonAuthRequest.headers.authorization)
End Function


'@Test unit tests setImageParams
Function cmsApi_setImageParams_test()
  posterParam = "w198h282_poster"
  landscapeParam = "w408h231_hero"
  vitgParam = "w1248h701_hero"

  ' test add poster only
  existingParams = {
    userid: "1234"
    is_existing: true
  }

  imageTypes = [
    "poster"
  ]
  updatedParams = m.cmsApi.setImageParams(imageTypes, existingParams)

  m.assertNotInvalid(updatedParams.userid)
  m.assertNotInvalid(updatedParams.is_existing)
  m.assertInvalid(updatedParams["images[landscape_tb]"])
  m.assertInvalid(updatedParams["images[vitg_tb]"])
  m.assertNotInvalid(updatedParams["images[poster_tb]"])
  m.assertEqual(updatedParams["images[poster_tb]"], posterParam)

  ' test add landscape only
  existingParams = {
    userid: "1234"
    is_existing: true
  }

  imageTypes = [
    "landscape"
  ]
  updatedParams = m.cmsApi.setImageParams(imageTypes, existingParams)

  m.assertNotInvalid(updatedParams.userid)
  m.assertNotInvalid(updatedParams.is_existing)
  m.assertInvalid(updatedParams["images[vitg_tb]"])
  m.assertInvalid(updatedParams["images[poster_tb]"])
  m.assertNotInvalid(updatedParams["images[landscape_tb]"])
  m.assertEqual(updatedParams["images[landscape_tb]"], landscapeParam)

  ' test add vitg only
  existingParams = {
    userid: "1234"
    is_existing: true
  }

  imageTypes = [
    "large_vitg"
  ]
  updatedParams = m.cmsApi.setImageParams(imageTypes, existingParams)

  m.assertNotInvalid(updatedParams.userid)
  m.assertNotInvalid(updatedParams.is_existing)
  m.assertInvalid(updatedParams["images[poster_tb]"])
  m.assertInvalid(updatedParams["images[landscape_tb]"])
  m.assertNotInvalid(updatedParams["images[vitg_tb]"])
  m.assertEqual(updatedParams["images[vitg_tb]"], vitgParam)

  ' test add all
  existingParams = {
    userid: "1234"
    is_existing: true
  }

  imageTypes = [
    "poster"
    "landscape"
    "large_vitg"
  ]
  updatedParams = m.cmsApi.setImageParams(imageTypes, existingParams)

  m.assertNotInvalid(updatedParams.userid)
  m.assertNotInvalid(updatedParams.is_existing)
  m.assertNotInvalid(updatedParams["images[poster_tb]"])
  m.assertNotInvalid(updatedParams["images[landscape_tb]"])
  m.assertNotInvalid(updatedParams["images[vitg_tb]"])
  m.assertEqual(updatedParams["images[vitg_tb]"], vitgParam)
  m.assertEqual(updatedParams["images[landscape_tb]"], landscapeParam)
  m.assertEqual(updatedParams["images[poster_tb]"], posterParam)
End Function


'@Test unit tests setTupianPosterParam
Function cmsApi_setTupianPosterParam_test()
  posterParam = "w198h282_poster"

  existingParams = {
    userid: "1234"
    is_existing: true
  }

  imageTypes = [
    "poster"
  ]
  updatedParams = m.cmsApi.setTupianPosterParam(existingParams)

  m.assertNotInvalid(updatedParams.userid)
  m.assertNotInvalid(updatedParams.is_existing)
  m.assertInvalid(updatedParams["images[landscape_tb]"])
  m.assertInvalid(updatedParams["images[vitg_tb]"])
  m.assertNotInvalid(updatedParams["images[poster_tb]"])
  m.assertEqual(updatedParams["images[poster_tb]"], posterParam)
End Function


'@Test unit tests setTupianLandscapeParam
Function cmsApi_setTupianLandscapeParam_test()
  landscapeParam = "w408h231_hero"

  existingParams = {
    userid: "1234"
    is_existing: true
  }

  updatedParams = m.cmsApi.setTupianLandscapeParam(existingParams)

  m.assertNotInvalid(updatedParams.userid)
  m.assertNotInvalid(updatedParams.is_existing)
  m.assertInvalid(updatedParams["images[vitg_tb]"])
  m.assertInvalid(updatedParams["images[poster_tb]"])
  m.assertNotInvalid(updatedParams["images[landscape_tb]"])
  m.assertEqual(updatedParams["images[landscape_tb]"], landscapeParam)
End Function


'@Test unit tests setTupianLargeVitgParam
Function cmsApi_setTupianLargeVitgParam_test()
  vitgParam = "w1248h701_hero"

  existingParams = {
    userid: "1234"
    is_existing: true
  }

  updatedParams = m.cmsApi.setTupianLargeVitgParam(existingParams)

  m.assertNotInvalid(updatedParams.userid)
  m.assertNotInvalid(updatedParams.is_existing)
  m.assertInvalid(updatedParams["images[poster_tb]"])
  m.assertInvalid(updatedParams["images[landscape_tb]"])
  m.assertNotInvalid(updatedParams["images[vitg_tb]"])
  m.assertEqual(updatedParams["images[vitg_tb]"], vitgParam)
End Function
