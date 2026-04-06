'@TestSuite [CmsApi] CmsApi.brs

'@Setup
Function CmsApiSetup()
  constants = getConstants()
  pub_serverPersistentData = createObject("roSGNode", "ServerPersistentData")
  utils = ApiUtils(constants, pub_serverPersistentData)
  m.cmsApi = CmsApi(constants, utils)

  ' Cache 720p check (won't change during tests)
  m.is720p = (m.cmsApi.constants.deviceInfo.displayHeight = 720 OR m.cmsApi.constants.deviceInfo.lowVram = true)

  ' Helper function to convert image sizes for 720p (matches CmsApi conversion logic)
  m.convertImageSizeFor720p = Function(originalSize as Object) as Object
    scaleFactor = 0.6667
    newWidth = Int(originalSize[0] * scaleFactor)
    newHeight = Int(originalSize[1] * scaleFactor)
    return [newWidth, newHeight]
  End Function

  ' Helper function to get expected app_images param string the same way setAppImageParams does
  ' (uses background/creatorTileLogo sizes, applies 720p conversion if needed, returns formatted string)
  m.getExpectedAppImageParam = Function(imageType as String) as String
    imageSizes = m.cmsApi.constants.ui.imageSizes
    if imageType = "background"
      size = imageSizes.background
      suffix = "_hero"
    else if imageType = "logo"
      size = imageSizes.creatorTileLogo
      suffix = "_logo"
    else
      return ""
    end if

    if m.is720p = true
      size = m.convertImageSizeFor720p(size)
    end if

    return "w" + size[0].ToStr() + "h" + size[1].ToStr() + suffix
  End Function

  ' Helper function to get expected image param string the same way setImageParams does
  ' (uses largePoster/largeLandscape, applies 720p conversion if needed, returns formatted string)
  m.getExpectedImageParam = Function(imageType as String, isSearchScreen = false) as String
    imageSizes = m.cmsApi.constants.ui.imageSizes
    if imageType = "poster"
      if isSearchScreen = true
        size = imageSizes.poster
      else
        size = imageSizes.largePoster
      end if
      suffix = "_poster"
    else if imageType = "landscape"
      size = imageSizes.largeLandscape
      suffix = "_landscape"
    else
      return ""
    end if

    if m.is720p = true
      size = m.convertImageSizeFor720p(size)
    end if

    return "w" + size[0].ToStr() + "h" + size[1].ToStr() + suffix
  End Function
End Function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in CmsApi.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test unit tests createRelatedContentReqInfo
Function cmsApi_createRelatedContentReqInfo_test()
  infoKeys = [
    "url"
    "options"
  ]
  params = [
    "is_kids_mode"
    "video_resources"
    "images[poster_tb]"
    "platform"
    "device_id"
  ]

  kidsRelatedReqUrl = m.cmsApi.constants.urls.autopilot.relatedContent

  kidsRelatedReqOptions = {
    params: {
      "is_kids_mode": true,
      "video_resources": m.cmsApi.constants.player.drmOrderWithHlsWidevine
      "images[poster_tb]": m.getExpectedImageParam("poster")
      "platform": m.cmsApi.constants.platform
      "device_id": m.cmsApi.constants.deviceInfo.deviceId
      "content_id": "123456"
    }
  }

  kidsRelatedReqInfo = m.cmsApi.createRelatedContentReqInfo("123456", true)

  m.assertEqual(kidsRelatedReqInfo.count(), 2)
  m.assertAAHasKeys(kidsRelatedReqInfo, infoKeys)
  m.assertEqual(kidsRelatedReqUrl, kidsRelatedReqInfo.url)
  m.assertAAHasKeys(kidsRelatedReqOptions.params, params)
  m.assertEqual(kidsRelatedReqOptions.params["is_kids_mode"], kidsRelatedReqInfo.options.params["is_kids_mode"])
  m.assertEqual(kidsRelatedReqOptions.params["video_resources"], kidsRelatedReqInfo.options.params["video_resources"])
  m.assertEqual(kidsRelatedReqOptions.params["images[poster_tb]"], kidsRelatedReqInfo.options.params["images[poster_tb]"])
  m.assertEqual(kidsRelatedReqOptions.params["platform"], kidsRelatedReqInfo.options.params["platform"])
  m.assertEqual(kidsRelatedReqOptions.params["device_id"], kidsRelatedReqInfo.options.params["device_id"])

  relatedReqUrl = m.cmsApi.constants.urls.autopilot.relatedContent

  relatedReqOptions = {
    params: {
      "is_kids_mode": false,
      "video_resources": m.cmsApi.constants.player.drmOrderWithHlsWidevine
      "images[poster_tb]": m.getExpectedImageParam("poster")
      "platform": m.cmsApi.constants.platform
      "device_id": m.cmsApi.constants.deviceInfo.deviceId
      "content_id": "123456"
    }
  }

  relatedReqInfo = m.cmsApi.createRelatedContentReqInfo("123456", false)

  m.assertEqual(kidsRelatedReqInfo.count(), 2)
  m.assertAAHasKeys(kidsRelatedReqInfo, infoKeys)
  m.assertEqual(relatedReqUrl, relatedReqInfo.url)
  m.assertAAHasKeys(relatedReqInfo.options.params, params)
  m.assertEqual(relatedReqInfo.options.params["is_kids_mode"], relatedReqOptions.params["is_kids_mode"])
  m.assertEqual(relatedReqInfo.options.params["video_resources"], relatedReqOptions.params["video_resources"])
  m.assertEqual(relatedReqInfo.options.params["platform"], relatedReqOptions.params["platform"])
  m.assertEqual(relatedReqInfo.options.params["device_id"], relatedReqOptions.params["device_id"])
  m.assertEqual(relatedReqInfo.options.params["images[poster_tb]"], relatedReqOptions.params["images[poster_tb]"])
End Function


'@Test unit tests createUpNextContentReqInfo
Function cmsApi_createUpNextContentReqInfo_test()
  infoKeys = [
    "url"
    "options"
  ]
  params = [
    "video_resources"
    "platform"
    "device_id"
    "custom_param"
    "content_id"
  ]

  upNextUrl = m.cmsApi.constants.urls.autopilot.upNextContent
  upNextOptions = {
    params: {
      "platform": m.cmsApi.constants.platform
      "device_id": m.cmsApi.constants.deviceInfo.deviceId
      "video_resources": m.cmsApi.constants.player.drmOrderWithHlsWidevine
      "custom_param": 42
      "content_id": "123456"
    }
  }

  passedOptions = {
    params: {
      "custom_param": 42
      "content_id": "123456"
    }
  }
  upNextInfo = m.cmsApi.createUpNextContentReqInfo(passedOptions)

  m.assertEqual(upNextInfo.count(), 2)
  m.assertAAHasKeys(upNextInfo, infoKeys)
  m.assertEqual(upNextInfo.url, upNextUrl)
  m.assertAAHasKeys(upNextInfo.options.params, params)
  m.assertEqual(upNextInfo.options.params["platform"], upNextOptions.params["platform"])
  m.assertEqual(upNextInfo.options.params["device_id"], upNextOptions.params["device_id"])
  m.assertEqual(upNextInfo.options.params["video_resources"], upNextOptions.params["video_resources"])
  m.assertEqual(upNextInfo.options.params["custom_param"], upNextOptions.params["custom_param"])
  m.assertEqual(upNextInfo.options.params["content_id"], upNextOptions.params["content_id"])
End Function



'@Test unit tests createSingleContentReqInfo
Function cmsApi_createSingleContentReqInfo_test()
  infoKeys = [
    "url"
    "options"
  ]
  params = [
    "platform"
    "device_id"
    "content_id"
    "is_kids_mode"
    "include_channels"
    "video_resources"
    "images[landscape_tb]"
  ]

  singleContentUrl = m.cmsApi.constants.urls.content.singleContent
  singleContentOptions = {
    params: {
      "platform": m.cmsApi.constants.platform
      "device_id": m.cmsApi.constants.deviceInfo.deviceId
      "content_id": "123456"
      "is_kids_mode": false
      "include_channels": true
      "video_resources": m.cmsApi.constants.player.drmOrderWithHlsWidevine
      "images[landscape_tb]": m.getExpectedImageParam("landscape")
    }
  }

  ' include channels, no kids mode
  singleContentInfo = m.cmsApi.createSingleContentReqInfo("123456", true, false)

  m.assertEqual(singleContentInfo.count(), 2)
  m.assertAAHasKeys(singleContentInfo, infoKeys)
  m.assertEqual(singleContentInfo.url, singleContentUrl)
  m.assertAAHasKeys(singleContentInfo.options.params, params)
  m.assertEqual(singleContentInfo.options.params["platform"], singleContentOptions.params["platform"])
  m.assertEqual(singleContentInfo.options.params["device_id"], singleContentOptions.params["device_id"])
  m.assertEqual(singleContentInfo.options.params["content_id"], singleContentOptions.params["content_id"])
  m.assertEqual(singleContentInfo.options.params["is_kids_mode"], singleContentOptions.params["is_kids_mode"])
  m.assertEqual(singleContentInfo.options.params["include_channels"], singleContentOptions.params["include_channels"])
  m.assertEqual(singleContentInfo.options.params["video_resources"], singleContentOptions.params["video_resources"])
  m.assertEqual(singleContentInfo.options.params["images[landscape_tb]"], singleContentOptions.params["images[landscape_tb]"])

  ' include channels, with kids mode
  singleContentInfo = m.cmsApi.createSingleContentReqInfo("123456", true, true)

  singleContentOptions.params["is_kids_mode"] = true

  m.assertEqual(singleContentInfo.count(), 2)
  m.assertAAHasKeys(singleContentInfo, infoKeys)
  m.assertEqual(singleContentInfo.url, singleContentUrl)
  m.assertAAHasKeys(singleContentInfo.options.params, params)
  m.assertEqual(singleContentInfo.options.params["platform"], singleContentOptions.params["platform"])
  m.assertEqual(singleContentInfo.options.params["device_id"], singleContentOptions.params["device_id"])
  m.assertEqual(singleContentInfo.options.params["content_id"], singleContentOptions.params["content_id"])
  m.assertEqual(singleContentInfo.options.params["is_kids_mode"], singleContentOptions.params["is_kids_mode"])
  m.assertEqual(singleContentInfo.options.params["include_channels"], singleContentOptions.params["include_channels"])
  m.assertEqual(singleContentInfo.options.params["video_resources"], singleContentOptions.params["video_resources"])
  m.assertEqual(singleContentInfo.options.params["images[landscape_tb]"], singleContentOptions.params["images[landscape_tb]"])

  ' don't include channels, with kids mode
  singleContentInfo = m.cmsApi.createSingleContentReqInfo("123456", false, true)

  singleContentOptions.params["include_channels"] = false
  singleContentOptions.params["is_kids_mode"] = true

  m.assertEqual(singleContentInfo.count(), 2)
  m.assertAAHasKeys(singleContentInfo, infoKeys)
  m.assertEqual(singleContentInfo.url, singleContentUrl)
  m.assertAAHasKeys(singleContentInfo.options.params, params)
  m.assertEqual(singleContentInfo.options.params["platform"], singleContentOptions.params["platform"])
  m.assertEqual(singleContentInfo.options.params["device_id"], singleContentOptions.params["device_id"])
  m.assertEqual(singleContentInfo.options.params["content_id"], singleContentOptions.params["content_id"])
  m.assertEqual(singleContentInfo.options.params["is_kids_mode"], singleContentOptions.params["is_kids_mode"])
  m.assertEqual(singleContentInfo.options.params["include_channels"], singleContentOptions.params["include_channels"])
  m.assertEqual(singleContentInfo.options.params["video_resources"], singleContentOptions.params["video_resources"])
  m.assertEqual(singleContentInfo.options.params["images[landscape_tb]"], singleContentOptions.params["images[landscape_tb]"])
End Function


'@Test unit tests createThumbnailsReqInfo
Function cmsApi_createThumbnailsReqInfo_test()
  infoKeys = [
    "url"
    "options"
  ]
  params = [
    "platform"
    "device_id"
    "type"
    "max_width"
  ]

  thumbsUrl = m.cmsApi.constants.urls.cms.thumbnails + "/123456/thumbnail_sprites"
  thumbsOptions = {
    params: {
      "platform": m.cmsApi.constants.platform
      "device_id": m.cmsApi.constants.deviceInfo.deviceId
      "type": "5x"
      "max_width": m.cmsApi.constants.deviceInfo.displayWidth
    }
  }

  thumbsInfo = m.cmsApi.createThumbnailsReqInfo("123456")

  m.assertEqual(thumbsInfo.count(), 2)
  m.assertAAHasKeys(thumbsInfo, infoKeys)
  m.assertEqual(thumbsInfo.url, thumbsUrl)
  m.assertAAHasKeys(thumbsInfo.options.params, params)
  m.assertEqual(thumbsInfo.options.params["platform"], thumbsOptions.params["platform"])
  m.assertEqual(thumbsInfo.options.params["device_id"], thumbsOptions.params["device_id"])
  m.assertEqual(thumbsInfo.options.params["type"], thumbsOptions.params["type"])
  m.assertEqual(thumbsInfo.options.params["max_width"], thumbsOptions.params["max_width"])
End Function


'@Test unit tests createHomeScreenReqInfo
Function cmsApi_createHomeScreenReqInfo_test()
  infoKeys = [
    "url"
    "options"
  ]
  params = [
    "platform"
    "device_id"
    "include_empty_history"
    "include_empty_queue"
    "is_kids_mode"
    "images[landscape_tb]"
    "images[poster_tb]"
    "customParam"
    "idfa"
  ]
  headers = [
    "x-custom-header"
    "x-client-platform"
    "x-client-version"
  ]

  homeUrl = m.cmsApi.constants.urls.tensor.cdn.homescreen
  homeOptions = {
    params: {
      "platform": m.cmsApi.constants.platform
      "device_id": m.cmsApi.constants.deviceInfo.deviceId
      "include_empty_history": true
      "include_empty_queue": true
      "is_kids_mode": false
      "images[poster_tb]": m.getExpectedImageParam("poster")
      "images[landscape_tb]": m.getExpectedImageParam("landscape")
      "contentMode": m.cmsApi.constants.ui.contentMode.homescreen
      "customParam": "custom_param_value"
      "idfa": m.cmsApi.constants.deviceInfo.deviceAdId
    }
    headers: {
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
  homeInfo = m.cmsApi.createHomeScreenReqInfo(false, passedOptions)

  m.assertEqual(homeInfo.count(), 2)
  m.assertAAHasKeys(homeInfo, infoKeys)
  m.assertEqual(homeInfo.url, homeUrl)
  m.assertAAHasKeys(homeInfo.options.params, params)
  m.assertAAHasKeys(homeInfo.options.headers, headers)
  m.assertEqual(homeInfo.options.params["platform"], homeOptions.params["platform"])
  m.assertEqual(homeInfo.options.params["device_id"], homeOptions.params["device_id"])
  m.assertEqual(homeInfo.options.params["include_empty_history"], homeOptions.params["include_empty_history"])
  m.assertEqual(homeInfo.options.params["include_empty_queue"], homeOptions.params["include_empty_queue"])
  m.assertEqual(homeInfo.options.params["is_kids_mode"], homeOptions.params["is_kids_mode"])
  m.assertEqual(homeInfo.options.params["images[poster_tb]"], homeOptions.params["images[poster_tb]"])
  m.assertEqual(homeInfo.options.params["images[landscape_tb]"], homeOptions.params["images[landscape_tb]"])
  m.assertEqual(homeInfo.options.params["contentMode"], homeOptions.params["contentMode"])
  m.assertEqual(homeInfo.options.params["idfa"], homeOptions.params["idfa"])
  m.assertEqual(homeInfo.options.params["customParam"], homeOptions.params["customParam"])
  m.assertEqual(homeInfo.options.headers["x-custom-header"], homeOptions.headers["x-custom-header"])
  m.assertEqual(homeInfo.options.headers["x-client-platform"], homeOptions.headers["x-client-platform"])
  m.assertEqual(homeInfo.options.headers["x-client-version"], homeOptions.headers["x-client-version"])

  ' with kids mode and homescreen contentMode
  homeInfo = m.cmsApi.createHomeScreenReqInfo(true, passedOptions)
  homeOptions.params["is_kids_mode"] = true

  m.assertEqual(homeInfo.count(), 2)
  m.assertAAHasKeys(homeInfo, infoKeys)
  m.assertEqual(homeInfo.url, homeUrl)
  m.assertAAHasKeys(homeInfo.options.params, params)
  m.assertAAHasKeys(homeInfo.options.headers, headers)
  m.assertEqual(homeInfo.options.params["platform"], homeOptions.params["platform"])
  m.assertEqual(homeInfo.options.params["device_id"], homeOptions.params["device_id"])
  m.assertEqual(homeInfo.options.params["include_empty_history"], homeOptions.params["include_empty_history"])
  m.assertEqual(homeInfo.options.params["include_empty_queue"], homeOptions.params["include_empty_queue"])
  m.assertEqual(homeInfo.options.params["is_kids_mode"], homeOptions.params["is_kids_mode"])
  m.assertEqual(homeInfo.options.params["images[poster_tb]"], homeOptions.params["images[poster_tb]"])
  m.assertEqual(homeInfo.options.params["images[landscape_tb]"], homeOptions.params["images[landscape_tb]"])
  m.assertEqual(homeInfo.options.params["contentMode"], homeOptions.params["contentMode"])
  m.assertEqual(homeInfo.options.params["customParam"], homeOptions.params["customParam"])
  m.assertEqual(homeInfo.options.headers["x-custom-header"], homeOptions.headers["x-custom-header"])
  m.assertEqual(homeInfo.options.headers["x-client-platform"], homeOptions.headers["x-client-platform"])
  m.assertEqual(homeInfo.options.headers["x-client-version"], homeOptions.headers["x-client-version"])

  ' with contentMode = "tv"
  passedOptions.params["contentMode"] = m.cmsApi.constants.ui.contentMode.tv
  homeInfo = m.cmsApi.createHomeScreenReqInfo(false, passedOptions)
  homeOptions.params["is_kids_mode"] = false
  homeOptions.params["contentMode"] = m.cmsApi.constants.ui.contentMode.tv

  m.assertEqual(homeInfo.count(), 2)
  m.assertAAHasKeys(homeInfo, infoKeys)
  m.assertEqual(homeInfo.url, homeUrl)
  m.assertAAHasKeys(homeInfo.options.params, params)
  m.assertAAHasKeys(homeInfo.options.headers, headers)
  m.assertEqual(homeInfo.options.params["platform"], homeOptions.params["platform"])
  m.assertEqual(homeInfo.options.params["device_id"], homeOptions.params["device_id"])
  m.assertEqual(homeInfo.options.params["include_empty_history"], homeOptions.params["include_empty_history"])
  m.assertEqual(homeInfo.options.params["include_empty_queue"], homeOptions.params["include_empty_queue"])
  m.assertEqual(homeInfo.options.params["is_kids_mode"], homeOptions.params["is_kids_mode"])
  m.assertEqual(homeInfo.options.params["images[poster_tb]"], homeOptions.params["images[poster_tb]"])
  m.assertEqual(homeInfo.options.params["images[landscape_tb]"], homeOptions.params["images[landscape_tb]"])
  m.assertEqual(homeInfo.options.params["contentMode"], homeOptions.params["contentMode"])
  m.assertEqual(homeInfo.options.params["customParam"], homeOptions.params["customParam"])
  m.assertEqual(homeInfo.options.headers["x-custom-header"], homeOptions.headers["x-custom-header"])
  m.assertEqual(homeInfo.options.headers["x-client-platform"], homeOptions.headers["x-client-platform"])
  m.assertEqual(homeInfo.options.headers["x-client-version"], homeOptions.headers["x-client-version"])

  ' with contentMode = "linear"
  passedOptions.params["contentMode"] = m.cmsApi.constants.ui.contentMode.linear
  homeInfo = m.cmsApi.createHomeScreenReqInfo(false, passedOptions)
  homeOptions.params["contentMode"] = m.cmsApi.constants.ui.contentMode.linear
  homeOptions.params.delete("images[landscape_tb]")
  homeOptions.params.delete("images[poster_tb]")
  params = [
    "platform"
    "device_id"
    "include_empty_history"
    "include_empty_queue"
    "is_kids_mode"
  ]
  headers = [
    "x-custom-header"
  ]

  m.assertEqual(homeInfo.count(), 2)
  m.assertAAHasKeys(homeInfo, infoKeys)
  m.assertEqual(homeInfo.url, homeUrl)
  m.assertAAHasKeys(homeInfo.options.params, params)
  m.assertAAHasKeys(homeInfo.options.headers, headers)
  m.assertEqual(homeInfo.options.params["platform"], homeOptions.params["platform"])
  m.assertEqual(homeInfo.options.params["device_id"], homeOptions.params["device_id"])
  m.assertEqual(homeInfo.options.params["include_empty_history"], homeOptions.params["include_empty_history"])
  m.assertEqual(homeInfo.options.params["include_empty_queue"], homeOptions.params["include_empty_queue"])
  m.assertEqual(homeInfo.options.params["is_kids_mode"], homeOptions.params["is_kids_mode"])
  m.assertEqual(homeInfo.options.params["contentMode"], homeOptions.params["contentMode"])
  m.assertEqual(homeInfo.options.params["customParam"], homeOptions.params["customParam"])
  m.assertEqual(homeInfo.options.headers["x-custom-header"], homeOptions.headers["x-custom-header"])
  m.assertEqual(homeInfo.options.headers["x-client-platform"], homeOptions.headers["x-client-platform"])
  m.assertEqual(homeInfo.options.headers["x-client-version"], homeOptions.headers["x-client-version"])
End Function


'@Test unit tests createMiniHomeScreenReqInfo
Function cmsApi_createMiniHomeScreenReqInfo_test()
  infoKeys = [
    "url"
    "options"
  ]
  params = [
    "platform"
    "device_id"
    "is_kids_mode"
    "images[landscape_tb]"
    "images[poster_tb]"
    "customParam"
    "idfa"
  ]
  headers = [
    "x-custom-header"
    "x-client-platform"
    "x-client-version"
  ]

  homeUrl = m.cmsApi.constants.urls.tensor.cdn.homescreen
  homeOptions = {
    params: {
      "platform": m.cmsApi.constants.platform
      "device_id": m.cmsApi.constants.deviceInfo.deviceId
      "is_kids_mode": false
      "images[poster_tb]": m.getExpectedImageParam("poster")
      "images[landscape_tb]": m.getExpectedImageParam("landscape")
      "contentMode": m.cmsApi.constants.ui.contentMode.homescreen
      "customParam": "custom_param_value"
      "idfa": m.cmsApi.constants.deviceInfo.deviceAdId
    }
    headers: {
      "x-custom-header": "custom_header_value"
      "x-client-platform": m.cmsApi.constants.headers.commonUapi["x-client-platform"]
      "x-client-version": m.cmsApi.constants.headers.commonUapi["x-client-version"]
      "Accept-Version": "6.0.0"
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
  homeInfo = m.cmsApi.createMiniHomeScreenOnPlayerReqInfo(false, passedOptions)

  m.assertEqual(homeInfo.count(), 2)
  m.assertAAHasKeys(homeInfo, infoKeys)
  m.assertEqual(homeInfo.url, homeUrl)
  m.assertAAHasKeys(homeInfo.options.params, params)
  m.assertAAHasKeys(homeInfo.options.headers, headers)
  m.assertEqual(homeInfo.options.params["platform"], homeOptions.params["platform"])
  m.assertEqual(homeInfo.options.params["device_id"], homeOptions.params["device_id"])
  m.assertEqual(homeInfo.options.params["is_kids_mode"], homeOptions.params["is_kids_mode"])
  m.assertEqual(homeInfo.options.params["images[poster_tb]"], homeOptions.params["images[poster_tb]"])
  m.assertEqual(homeInfo.options.params["images[landscape_tb]"], homeOptions.params["images[landscape_tb]"])
  m.assertEqual(homeInfo.options.params["contentMode"], homeOptions.params["contentMode"])
  m.assertEqual(homeInfo.options.params["idfa"], homeOptions.params["idfa"])
  m.assertEqual(homeInfo.options.params["customParam"], homeOptions.params["customParam"])
  m.assertEqual(homeInfo.options.headers["x-custom-header"], homeOptions.headers["x-custom-header"])
  m.assertEqual(homeInfo.options.headers["x-client-platform"], homeOptions.headers["x-client-platform"])
  m.assertEqual(homeInfo.options.headers["x-client-version"], homeOptions.headers["x-client-version"])
  m.assertEqual(homeInfo.options.headers["Accept-Version"], homeOptions.headers["Accept-Version"])

  ' with kids mode and homescreen contentMode
  homeInfo = m.cmsApi.createHomeScreenReqInfo(true, passedOptions)
  homeOptions.params["is_kids_mode"] = true

  m.assertEqual(homeInfo.count(), 2)
  m.assertAAHasKeys(homeInfo, infoKeys)
  m.assertEqual(homeInfo.url, homeUrl)
  m.assertAAHasKeys(homeInfo.options.params, params)
  m.assertAAHasKeys(homeInfo.options.headers, headers)
  m.assertEqual(homeInfo.options.params["platform"], homeOptions.params["platform"])
  m.assertEqual(homeInfo.options.params["device_id"], homeOptions.params["device_id"])
  m.assertEqual(homeInfo.options.params["is_kids_mode"], homeOptions.params["is_kids_mode"])
  m.assertEqual(homeInfo.options.params["images[poster_tb]"], homeOptions.params["images[poster_tb]"])
  m.assertEqual(homeInfo.options.params["images[landscape_tb]"], homeOptions.params["images[landscape_tb]"])
  m.assertEqual(homeInfo.options.params["contentMode"], homeOptions.params["contentMode"])
  m.assertEqual(homeInfo.options.params["customParam"], homeOptions.params["customParam"])
  m.assertEqual(homeInfo.options.headers["x-custom-header"], homeOptions.headers["x-custom-header"])
  m.assertEqual(homeInfo.options.headers["x-client-platform"], homeOptions.headers["x-client-platform"])
  m.assertEqual(homeInfo.options.headers["x-client-version"], homeOptions.headers["x-client-version"])
  m.assertEqual(homeInfo.options.headers["Accept-Version"], homeOptions.headers["Accept-Version"])

  ' with contentMode = "tv"
  passedOptions.params["contentMode"] = m.cmsApi.constants.ui.contentMode.tv
  homeInfo = m.cmsApi.createHomeScreenReqInfo(false, passedOptions)
  homeOptions.params["is_kids_mode"] = false
  homeOptions.params["contentMode"] = m.cmsApi.constants.ui.contentMode.tv

  m.assertEqual(homeInfo.count(), 2)
  m.assertAAHasKeys(homeInfo, infoKeys)
  m.assertEqual(homeInfo.url, homeUrl)
  m.assertAAHasKeys(homeInfo.options.params, params)
  m.assertAAHasKeys(homeInfo.options.headers, headers)
  m.assertEqual(homeInfo.options.params["platform"], homeOptions.params["platform"])
  m.assertEqual(homeInfo.options.params["device_id"], homeOptions.params["device_id"])
  m.assertEqual(homeInfo.options.params["is_kids_mode"], homeOptions.params["is_kids_mode"])
  m.assertEqual(homeInfo.options.params["images[poster_tb]"], homeOptions.params["images[poster_tb]"])
  m.assertEqual(homeInfo.options.params["images[landscape_tb]"], homeOptions.params["images[landscape_tb]"])
  m.assertEqual(homeInfo.options.params["contentMode"], homeOptions.params["contentMode"])
  m.assertEqual(homeInfo.options.params["customParam"], homeOptions.params["customParam"])
  m.assertEqual(homeInfo.options.headers["x-custom-header"], homeOptions.headers["x-custom-header"])
  m.assertEqual(homeInfo.options.headers["x-client-platform"], homeOptions.headers["x-client-platform"])
  m.assertEqual(homeInfo.options.headers["x-client-version"], homeOptions.headers["x-client-version"])
  m.assertEqual(homeInfo.options.headers["Accept-Version"], homeOptions.headers["Accept-Version"])

  ' with contentMode = "linear"
  passedOptions.params["contentMode"] = m.cmsApi.constants.ui.contentMode.linear
  homeInfo = m.cmsApi.createHomeScreenReqInfo(false, passedOptions)
  homeOptions.params["contentMode"] = m.cmsApi.constants.ui.contentMode.linear
  homeOptions.params.delete("images[landscape_tb]")
  homeOptions.params.delete("images[poster_tb]")
  params = [
    "platform"
    "device_id"
    "is_kids_mode"
  ]
  headers = [
    "x-custom-header"
  ]

  m.assertEqual(homeInfo.count(), 2)
  m.assertAAHasKeys(homeInfo, infoKeys)
  m.assertEqual(homeInfo.url, homeUrl)
  m.assertAAHasKeys(homeInfo.options.params, params)
  m.assertAAHasKeys(homeInfo.options.headers, headers)
  m.assertEqual(homeInfo.options.params["platform"], homeOptions.params["platform"])
  m.assertEqual(homeInfo.options.params["device_id"], homeOptions.params["device_id"])
  m.assertEqual(homeInfo.options.params["is_kids_mode"], homeOptions.params["is_kids_mode"])
  m.assertEqual(homeInfo.options.params["contentMode"], homeOptions.params["contentMode"])
  m.assertEqual(homeInfo.options.params["customParam"], homeOptions.params["customParam"])
  m.assertEqual(homeInfo.options.headers["x-custom-header"], homeOptions.headers["x-custom-header"])
  m.assertEqual(homeInfo.options.headers["x-client-platform"], homeOptions.headers["x-client-platform"])
  m.assertEqual(homeInfo.options.headers["x-client-version"], homeOptions.headers["x-client-version"])
  m.assertEqual(homeInfo.options.headers["Accept-Version"], homeOptions.headers["Accept-Version"])
End Function


'@Test unit tests createCategoryReqInfo
Function cmsApi_createCategoryReqInfo_test()
  infoKeys = [
    "url"
    "options"
  ]
  params = [
    "platform"
    "device_id"
    "is_kids_mode"
    "cursor"
    "contents_limit"
    "images[landscape_tb]"
    "images[poster_tb]"
    "contentMode"
    "customParam"
  ]
  headers = [
    "x-custom-header"
    "x-client-platform"
    "x-client-version"
  ]

  categoryUrl = m.cmsApi.constants.urls.tensor.cdn.container + "/my_category"
  categoryOptions = {
    params: {
      "platform": m.cmsApi.constants.platform
      "device_id": m.cmsApi.constants.deviceInfo.deviceId
      "is_kids_mode": false
      "cursor": 0
      "contents_limit": 19
      "images[poster_tb]": m.getExpectedImageParam("poster")
      "images[landscape_tb]": m.getExpectedImageParam("landscape")
      "contentMode": m.cmsApi.constants.ui.contentMode.homescreen
      "customParam": "custom_param_value"
    }
    headers: {
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
  categoryInfo = m.cmsApi.createCategoryReqInfo("my_category", false, passedOptions)

  m.assertEqual(categoryInfo.count(), 2)
  m.assertAAHasKeys(categoryInfo, infoKeys)
  m.assertEqual(categoryInfo.url, categoryUrl)
  m.assertAAHasKeys(categoryInfo.options.params, params)
  m.assertAAHasKeys(categoryInfo.options.headers, headers)
  m.assertEqual(categoryInfo.options.params["platform"], categoryOptions.params["platform"])
  m.assertEqual(categoryInfo.options.params["device_id"], categoryOptions.params["device_id"])
  m.assertEqual(categoryInfo.options.params["is_kids_mode"], categoryOptions.params["is_kids_mode"])
  m.assertEqual(categoryInfo.options.params["images[poster_tb]"], categoryOptions.params["images[poster_tb]"])
  m.assertEqual(categoryInfo.options.params["images[landscape_tb]"], categoryOptions.params["images[landscape_tb]"])
  m.assertEqual(categoryInfo.options.params["contentMode"], categoryOptions.params["contentMode"])
  m.assertEqual(categoryInfo.options.params["customParam"], categoryOptions.params["customParam"])
  m.assertEqual(categoryInfo.options.headers["x-custom-header"], categoryOptions.headers["x-custom-header"])
  m.assertEqual(categoryInfo.options.headers["x-client-platform"], categoryOptions.headers["x-client-platform"])
  m.assertEqual(categoryInfo.options.headers["x-client-version"], categoryOptions.headers["x-client-version"])

  ' with kids mode
  categoryOptions.params["is_kids_mode"] = true
  categoryInfo = m.cmsApi.createCategoryReqInfo("my_category", true, passedOptions)

  m.assertEqual(categoryInfo.count(), 2)
  m.assertAAHasKeys(categoryInfo, infoKeys)
  m.assertEqual(categoryInfo.url, categoryUrl)
  m.assertAAHasKeys(categoryInfo.options.params, params)
  m.assertAAHasKeys(categoryInfo.options.headers, headers)
  m.assertEqual(categoryInfo.options.params["platform"], categoryOptions.params["platform"])
  m.assertEqual(categoryInfo.options.params["device_id"], categoryOptions.params["device_id"])
  m.assertEqual(categoryInfo.options.params["is_kids_mode"], categoryOptions.params["is_kids_mode"])
  m.assertEqual(categoryInfo.options.params["images[poster_tb]"], categoryOptions.params["images[poster_tb]"])
  m.assertEqual(categoryInfo.options.params["images[landscape_tb]"], categoryOptions.params["images[landscape_tb]"])
  m.assertEqual(categoryInfo.options.params["contentMode"], categoryOptions.params["contentMode"])
  m.assertEqual(categoryInfo.options.params["customParam"], categoryOptions.params["customParam"])
  m.assertEqual(categoryInfo.options.headers["x-custom-header"], categoryOptions.headers["x-custom-header"])
  m.assertEqual(categoryInfo.options.headers["x-client-platform"], categoryOptions.headers["x-client-platform"])
  m.assertEqual(categoryInfo.options.headers["x-client-version"], categoryOptions.headers["x-client-version"])

  ' with contentMode not homescreen
  categoryOptions.params["is_kids_mode"] = false
  categoryOptions.params["contentMode"] = m.cmsApi.constants.ui.contentMode.latino
  passedOptions.params.contentMode = m.cmsApi.constants.ui.contentMode.latino
  categoryInfo = m.cmsApi.createCategoryReqInfo("my_category", false, passedOptions)

  m.assertEqual(categoryInfo.count(), 2)
  m.assertAAHasKeys(categoryInfo, infoKeys)
  m.assertEqual(categoryInfo.url, categoryUrl)
  m.assertAAHasKeys(categoryInfo.options.params, params)
  m.assertAAHasKeys(categoryInfo.options.headers, headers)
  m.assertEqual(categoryInfo.options.params["platform"], categoryOptions.params["platform"])
  m.assertEqual(categoryInfo.options.params["device_id"], categoryOptions.params["device_id"])
  m.assertEqual(categoryInfo.options.params["is_kids_mode"], categoryOptions.params["is_kids_mode"])
  m.assertEqual(categoryInfo.options.params["images[poster_tb]"], categoryOptions.params["images[poster_tb]"])
  m.assertEqual(categoryInfo.options.params["images[landscape_tb]"], categoryOptions.params["images[landscape_tb]"])
  m.assertEqual(categoryInfo.options.params["contentMode"], categoryOptions.params["contentMode"])
  m.assertEqual(categoryInfo.options.params["customParam"], categoryOptions.params["customParam"])
  m.assertEqual(categoryInfo.options.headers["x-custom-header"], categoryOptions.headers["x-custom-header"])
  m.assertEqual(categoryInfo.options.headers["x-client-platform"], categoryOptions.headers["x-client-platform"])
  m.assertEqual(categoryInfo.options.headers["x-client-version"], categoryOptions.headers["x-client-version"])


  ' categorydetailPage lazy loading
  ' lazy loading starting at 10 to next 48 contents
  lazyCategoryOptions = {
    params: {
      "platform": m.cmsApi.constants.platform
      "device_id": m.cmsApi.constants.deviceInfo.deviceId
      "is_kids_mode": false
      "cursor": 10
      "contents_limit": m.cmsApi.constants.performance.categoryGridList.lazyLoadBatchSize
      "images[poster_tb]": m.getExpectedImageParam("poster")
      "images[landscape_tb]": m.getExpectedImageParam("landscape")
      "contentMode": ""
      "expanded": true
    }
    headers: {
      "x-client-platform": m.cmsApi.constants.headers.commonUapi["x-client-platform"]
      "x-client-version": m.cmsApi.constants.headers.commonUapi["x-client-version"]
    }
  }

  passedOptions = {
    params: {
      "cursor": 10
      "contents_limit": m.cmsApi.constants.performance.categoryGridList.lazyLoadBatchSize
      "expanded": true
    }
  }

  categoryInfo = m.cmsApi.createCategoryReqInfo("my_category", false, passedOptions)

  m.assertEqual(categoryInfo.count(), 2)
  m.assertAAHasKeys(categoryInfo, infoKeys)
  m.assertEqual(categoryInfo.url, categoryUrl)
  m.assertEqual(categoryInfo.options.params["platform"], lazyCategoryOptions.params["platform"])
  m.assertEqual(categoryInfo.options.params["device_id"], lazyCategoryOptions.params["device_id"])
  m.assertEqual(categoryInfo.options.params["is_kids_mode"], lazyCategoryOptions.params["is_kids_mode"])
  m.assertEqual(categoryInfo.options.params["images[poster_tb]"], lazyCategoryOptions.params["images[poster_tb]"])
  m.assertEqual(categoryInfo.options.params["images[landscape_tb]"], lazyCategoryOptions.params["images[landscape_tb]"])
  m.assertEqual(categoryInfo.options.params["cursor"], lazyCategoryOptions.params["cursor"])
  m.assertEqual(categoryInfo.options.params["contents_limit"], lazyCategoryOptions.params["contents_limit"])
  m.assertEqual(categoryInfo.options.headers["x-client-platform"], lazyCategoryOptions.headers["x-client-platform"])
  m.assertEqual(categoryInfo.options.headers["x-client-version"], lazyCategoryOptions.headers["x-client-version"])
  m.assertEqual(categoryInfo.options.params["expanded"], lazyCategoryOptions.params["expanded"])

End Function


'@Test unit tests createAutocompleteReqInfo
Function cmsApi_createAutocompleteReqInfo_test()
  infoKeys = [
    "url"
    "options"
  ]
  params = [
    "platform"
    "device_id"
    "search"
  ]

  autocompleteUrl = m.cmsApi.constants.urls.autocomplete

  autocompleteOptions = {
    params: {
      "platform": m.cmsApi.constants.platform
      "device_id": m.cmsApi.constants.deviceInfo.deviceId
      "search": "search_text"
    }
  }

  autocompleteInfo = m.cmsApi.createAutocompleteReqInfo("search_text")

  m.assertEqual(autocompleteInfo.count(), 2)
  m.assertAAHasKeys(autocompleteInfo, infoKeys)
  m.assertEqual(autocompleteInfo.url, autocompleteUrl)
  m.assertAAHasKeys(autocompleteInfo.options.params, params)
  m.assertEqual(autocompleteInfo.options.params["platform"], autocompleteOptions.params["platform"])
  m.assertEqual(autocompleteInfo.options.params["device_id"], autocompleteOptions.params["device_id"])
  m.assertEqual(autocompleteInfo.options.params["search"], autocompleteOptions.params["search"])

End Function


'@Test unit tests createSearchReqInfo
Function cmsApi_createSearchReqInfo_test()
  infoKeys = [
    "url"
    "options"
  ]
  params = [
    "platform"
    "device_id"
    "search"
    "is_kids_mode"
    "images[poster_tb]"
  ]

  searchUrl = m.cmsApi.constants.urls.search

  searchOptions = {
    params: {
      "platform": m.cmsApi.constants.platform
      "device_id": m.cmsApi.constants.deviceInfo.deviceId
      "search": "search_text"
      "is_kids_mode": false
      "images[poster_tb]": m.getExpectedImageParam("poster", true)
    }
  }

  ' without kids mode
  searchInfo = m.cmsApi.createSearchReqInfo("search_text", false)

  m.assertEqual(searchInfo.count(), 2)
  m.assertAAHasKeys(searchInfo, infoKeys)
  m.assertEqual(searchInfo.url, searchUrl)
  m.assertAAHasKeys(searchInfo.options.params, params)
  m.assertEqual(searchInfo.options.params["platform"], searchOptions.params["platform"])
  m.assertEqual(searchInfo.options.params["device_id"], searchOptions.params["device_id"])
  m.assertEqual(searchInfo.options.params["search"], searchOptions.params["search"])
  m.assertEqual(searchInfo.options.params["is_kids_mode"], searchOptions.params["is_kids_mode"])
  m.assertEqual(searchInfo.options.params["images[poster_tb]"], searchOptions.params["images[poster_tb]"])

  ' with kids mode
  searchOptions.params["is_kids_mode"] = true
  searchInfo = m.cmsApi.createSearchReqInfo("search_text", true)

  m.assertEqual(searchInfo.count(), 2)
  m.assertAAHasKeys(searchInfo, infoKeys)
  m.assertEqual(searchInfo.url, searchUrl)
  m.assertAAHasKeys(searchInfo.options.params, params)
  m.assertEqual(searchInfo.options.params["platform"], searchOptions.params["platform"])
  m.assertEqual(searchInfo.options.params["device_id"], searchOptions.params["device_id"])
  m.assertEqual(searchInfo.options.params["search"], searchOptions.params["search"])
  m.assertEqual(searchInfo.options.params["is_kids_mode"], searchOptions.params["is_kids_mode"])
  m.assertEqual(searchInfo.options.params["images[poster_tb]"], searchOptions.params["images[poster_tb]"])

  ' with includeApps - uses searchV3 url and adds app image params
  appsParams = [
    "platform"
    "device_id"
    "search"
    "is_kids_mode"
    "images[poster_tb]"
    "include_apps"
    "app_images[background_tb]"
    "app_images[logo]"
  ]

  searchInfo = m.cmsApi.createSearchReqInfo("search_text", false, invalid, true, true)

  m.assertEqual(searchInfo.count(), 2)
  m.assertAAHasKeys(searchInfo, infoKeys)
  m.assertEqual(searchInfo.url, searchUrl)
  m.assertAAHasKeys(searchInfo.options.params, appsParams)
  m.assertEqual(searchInfo.options.params["platform"], m.cmsApi.constants.platform)
  m.assertEqual(searchInfo.options.params["device_id"], m.cmsApi.constants.deviceInfo.deviceId)
  m.assertEqual(searchInfo.options.params["search"], "search_text")
  m.assertEqual(searchInfo.options.params["is_kids_mode"], false)
  m.assertEqual(searchInfo.options.params["include_apps"], true)
  m.assertEqual(searchInfo.options.params["app_images[background_tb]"], m.getExpectedAppImageParam("background"))
  m.assertEqual(searchInfo.options.params["app_images[logo]"], m.getExpectedAppImageParam("logo"))

  ' without includeApps - does not use searchV3 url and has no app image params
  searchInfo = m.cmsApi.createSearchReqInfo("search_text", false)

  m.assertEqual(searchInfo.url, searchUrl)
  m.assertInvalid(searchInfo.options.params["include_apps"])
  m.assertInvalid(searchInfo.options.params["app_images[background_tb]"])
  m.assertInvalid(searchInfo.options.params["app_images[logo]"])
End Function


'@Test unit tests setImageParams
Function cmsApi_setImageParams_test()
  posterParam = m.getExpectedImageParam("poster")
  landscapeParam = m.getExpectedImageParam("landscape")

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
  m.assertInvalid(updatedParams["images[poster_tb]"])
  m.assertNotInvalid(updatedParams["images[landscape_tb]"])
  m.assertEqual(updatedParams["images[landscape_tb]"], landscapeParam)

  ' test add all
  existingParams = {
    userid: "1234"
    is_existing: true
  }

  imageTypes = [
    "poster"
    "landscape"
  ]
  updatedParams = m.cmsApi.setImageParams(imageTypes, existingParams)

  m.assertNotInvalid(updatedParams.userid)
  m.assertNotInvalid(updatedParams.is_existing)
  m.assertNotInvalid(updatedParams["images[poster_tb]"])
  m.assertNotInvalid(updatedParams["images[landscape_tb]"])
  m.assertEqual(updatedParams["images[landscape_tb]"], landscapeParam)
  m.assertEqual(updatedParams["images[poster_tb]"], posterParam)
End Function


'@Test unit tests setTupianPosterParam
Function cmsApi_setTupianPosterParam_test()
  posterParam = m.getExpectedImageParam("poster")

  existingParams = {
    userid: "1234"
    is_existing: true
  }

  updatedParams = m.cmsApi.setTupianPosterParam(existingParams)

  m.assertNotInvalid(updatedParams.userid)
  m.assertNotInvalid(updatedParams.is_existing)
  m.assertInvalid(updatedParams["images[landscape_tb]"])
  m.assertNotInvalid(updatedParams["images[poster_tb]"])
  m.assertEqual(updatedParams["images[poster_tb]"], posterParam)
End Function


'@Test unit tests setTupianLandscapeParam
Function cmsApi_setTupianLandscapeParam_test()
  landscapeParam = m.getExpectedImageParam("landscape")

  existingParams = {
    userid: "1234"
    is_existing: true
  }

  updatedParams = m.cmsApi.setTupianLandscapeParam(existingParams)

  m.assertNotInvalid(updatedParams.userid)
  m.assertNotInvalid(updatedParams.is_existing)
  m.assertInvalid(updatedParams["images[poster_tb]"])
  m.assertNotInvalid(updatedParams["images[landscape_tb]"])
  m.assertEqual(updatedParams["images[landscape_tb]"], landscapeParam)
End Function


'@Test unit tests setAppImageParams
Function cmsApi_setAppImageParams_test()
  backgroundParam = m.getExpectedAppImageParam("background")
  logoParam = m.getExpectedAppImageParam("logo")

  ' test add background and logo with pre-existing params
  existingParams = {
    userid: "1234"
    is_existing: true
  }

  updatedParams = m.cmsApi.setAppImageParams(existingParams)

  m.assertNotInvalid(updatedParams.userid)
  m.assertNotInvalid(updatedParams.is_existing)
  m.assertNotInvalid(updatedParams["app_images[background_tb]"])
  m.assertNotInvalid(updatedParams["app_images[logo]"])
  m.assertEqual(updatedParams["app_images[background_tb]"], backgroundParam)
  m.assertEqual(updatedParams["app_images[logo]"], logoParam)

  ' test that no poster/landscape image params are added
  existingParams = {
    userid: "1234"
    is_existing: true
  }

  updatedParams = m.cmsApi.setAppImageParams(existingParams)

  m.assertInvalid(updatedParams["images[poster_tb]"])
  m.assertInvalid(updatedParams["images[landscape_tb]"])
End Function
