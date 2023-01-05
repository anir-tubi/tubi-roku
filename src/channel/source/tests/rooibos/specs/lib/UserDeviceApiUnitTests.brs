'@TestSuite [UserDeviceApi] UserDeviceApi.brs

'@Setup
Function UserDeviceApiSetup()

  m.constants = getConstants()
  utils = ApiUtils(m.constants)
  m.userDeviceApi = UserDeviceApi(m.constants, utils)
  m.emailExistsUrl = m.constants.urls.account.emailExists
  m.signupUrl = m.constants.urls.userDevice.signup
  m.deviceRegisterUrl = m.constants.urls.account.deviceRegister
  m.checkBirthdayUrl = m.constants.urls.account.checkBirthday
  m.patchSettingsUrl = m.constants.urls.account.settings
  m.historyUrl = m.constants.urls.lishi.viewHistory
  m.app_id = m.constants.settings.shortAppName
  m.platform = m.constants.platform
  m.device_id = m.constants.deviceInfo.deviceId
  m.testEmail = "test@tubi.tv"
  m.testPassword = "111111"
  m.deviceId = m.constants.deviceInfo.deviceId

  m.movieContent = CreateObject("roSGNode", "TubiContentNode")
  m.movieContent.type = "movie"

  m.episodeContent = CreateObject("roSGNode", "TubiContentNode")
  m.episodeContent.type = "episode"

End function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in UserDeviceApi.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test emailExistsReqInfo unit tests
Function userDeviceApi_emailExistsReqInfo_test()

  options = {}
  options.params = {
    email: m.testEmail
  }
  requestInfo = m.userDeviceApi.emailExistsReqInfo(options)
  m.assertNotInvalid(requestInfo)
  m.assertNotInvalid(requestInfo.url)
  m.assertEqual(requestInfo.url, m.emailExistsUrl)

  m.assertNotInvalid(requestInfo.options)
  params = requestInfo.options.params
  m.assertNotInvalid(params)

  m.assertNotInvalid(params.app_id)
  m.assertEqual(params.app_id, m.app_id)

  m.assertNotInvalid(params.device_id)
  m.assertEqual(params.device_id, m.device_id)

  m.assertNotInvalid(params.email)
  m.assertEqual(params.email, m.testEmail)

  m.assertNotInvalid(params.platform)
  m.assertEqual(params.platform, m.platform)

End Function


'@Test signUpReqInfo unit tests
Function userDeviceApi_signUpReqInfo_test()

  options = {}
  options.body = {
    platform: m.constants.platform
    device_id: m.constants.deviceInfo.deviceId
    credentials: {
      email: m.testEmail
      password: m.testPassword
      gender: ""
      first_name: "Unit"
      last_name: "Test"
      birthday: ""
    }
  }
  requestInfo = m.userDeviceApi.signUpReqInfo(options)
  m.assertNotInvalid(requestInfo)
  m.assertNotInvalid(requestInfo.url)
  m.assertEqual(requestInfo.url, m.signupUrl)

  options = requestInfo.options
  m.assertNotInvalid(options)

  m.assertNotInvalid(options.method)
  m.assertEqual(options.method, "POST")

  m.assertNotInvalid(options.body)
  body = ParseJson(options.body)

  m.assertNotInvalid(body.platform)
  m.assertEqual(body.platform, m.constants.platform)

  m.assertNotInvalid(body.device_id)
  m.assertEqual(body.device_id, m.constants.deviceInfo.deviceId)

  m.assertNotInvalid(body.credentials)

  m.assertNotInvalid(body.credentials.email)
  m.assertEqual(body.credentials.email, m.testEmail)

  m.assertNotInvalid(body.credentials.password)
  m.assertEqual(body.credentials.password, m.testPassword)

  m.assertNotInvalid(body.credentials.gender)
  m.assertEqual(body.credentials.gender, "")

  m.assertNotInvalid(body.credentials.first_name)
  m.assertEqual(body.credentials.first_name, "Unit")

  m.assertNotInvalid(body.credentials.last_name)
  m.assertEqual(body.credentials.last_name, "Test")

  m.assertNotInvalid(body.credentials.birthday)
  m.assertEqual(body.credentials.birthday, "")

End Function


'@Test signInReqInfo unit tests
Function userDeviceApi_signInReqInfo_test()

  loginUrl = m.constants.urls.account.login

  options = {}
  options.body = {
    platform: m.constants.platform
    device_id: m.constants.deviceInfo.deviceId
    type: "email"
    credentials: {
      email: m.testEmail
      password: m.testPassword
    }
  }
  requestInfo = m.userDeviceApi.signInReqInfo(options)
  m.assertNotInvalid(requestInfo)
  m.assertNotInvalid(requestInfo.url)
  m.assertEqual(requestInfo.url, loginUrl)

  options = requestInfo.options
  m.assertNotInvalid(options)

  m.assertNotInvalid(options.method)
  m.assertEqual(options.method, "POST")

  m.assertNotInvalid(options.body)
  body = ParseJson(options.body)

  m.assertNotInvalid(body.platform)
  m.assertEqual(body.platform, m.constants.platform)

  m.assertNotInvalid(body.device_id)
  m.assertEqual(body.device_id, m.constants.deviceInfo.deviceId)

  m.assertNotInvalid(body.type)
  m.assertEqual(body.type, "email")

  m.assertNotInvalid(body.credentials)

  m.assertNotInvalid(body.credentials.email)
  m.assertEqual(body.credentials.email, m.testEmail)

  m.assertNotInvalid(body.credentials.password)
  m.assertEqual(body.credentials.password, m.testPassword)

End Function


'@Test deviceRegisterInfo unit tests
Function userDeviceApi_deviceRegisterInfo_test()
  birthdate = "04-01-1984"
  deviceRegisterInfo = m.userDeviceApi.deviceRegisterInfo(birthdate)

  m.assertNotInvalid(deviceRegisterInfo)

  m.assertNotInvalid(deviceRegisterInfo.url)
  m.assertEqual(deviceRegisterInfo.url, m.deviceRegisterUrl)

  m.assertNotInvalid(deviceRegisterInfo.options)

  m.assertNotInvalid(deviceRegisterInfo.options.body)
  body = ParseJson(deviceRegisterInfo.options.body)

  m.assertNotInvalid(body.platform)
  m.assertEqual(body.platform, m.constants.platform)

  m.assertNotInvalid(body.device_id)
  m.assertEqual(body.device_id, m.constants.deviceInfo.deviceId)

  m.assertNotInvalid(body.birthday)
  m.assertEqual(body.birthday, birthdate)

  m.assertEqual(deviceRegisterInfo.options.method, "POST")
End Function


'@Test checkBirthdayInfo unit tests
Function userDeviceApi_checkBirthdayInfo_test()
  checkBirthdayInfo = m.userDeviceApi.checkBirthdayInfo()

  m.assertNotInvalid(checkBirthdayInfo)

  m.assertNotInvalid(checkBirthdayInfo.url)
  m.assertEqual(checkBirthdayInfo.url, m.checkBirthdayUrl)

  m.assertNotInvalid(checkBirthdayInfo.options)

  m.assertNotInvalid(checkBirthdayInfo.options.params)
End Function


'@Test patchSettingsInfo unit tests
Function userDeviceApi_patchSettingsInfo_test()
  birthdate = "04-01-1984"
  passedOptions = {
    body: {
      birthday: birthdate
      random_setting: true
    }
  }
  patchSettingsInfo = m.userDeviceApi.patchSettingsInfo(passedOptions)

  m.assertNotInvalid(patchSettingsInfo)

  m.assertNotInvalid(patchSettingsInfo.url)
  m.assertEqual(patchSettingsInfo.url, m.patchSettingsUrl)

  m.assertNotInvalid(patchSettingsInfo.options)

  m.assertNotInvalid(patchSettingsInfo.options.body)
  body = ParseJson(patchSettingsInfo.options.body)

  m.assertNotInvalid(body.birthday)
  m.assertEqual(body.birthday, birthdate)

  m.assertNotInvalid(body.random_setting)
  m.assertEqual(body.random_setting, true)

  m.assertEqual(patchSettingsInfo.options.method, "PATCH")
End Function


'@Test patchAutoplayPreviewSettingInfo unit tests
Function userDeviceApi_patchAutoplayPreviewSettingInfo_test()

  patchSettingsInfo = m.userDeviceApi.patchAutoplayPreviewSettingInfo(false)

  m.assertNotInvalid(patchSettingsInfo)

  m.assertNotInvalid(patchSettingsInfo.url)
  m.assertEqual(patchSettingsInfo.url, m.constants.urls.account.settings)

  m.assertNotInvalid(patchSettingsInfo.options)
  m.assertNotInvalid(patchSettingsInfo.options.body)
  body = ParseJson(patchSettingsInfo.options.body)
  m.assertNotInvalid(body.enable_video_preview)
  m.assertFalse(body.enable_video_preview)

  m.assertNotInvalid(patchSettingsInfo.options.headers)
  m.assertEqual(patchSettingsInfo.options.method, "PATCH")
End Function


'@Test setContentRating unit tests
Function userDeviceApi_setContentRating_test()
  likeDislikeUrl = m.constants.urls.account.contentRating
  testTitleId = "321251"

  requestInfo = m.userDeviceApi.setContentRating(testTitleId, m.constants.ui.likeDislikeActions.like)
  m.assertNotInvalid(requestInfo)
  m.assertNotInvalid(requestInfo.url)
  m.assertEqual(requestInfo.url, likeDislikeUrl)

  m.assertNotInvalid(requestInfo.options)
  m.assertNotInvalid(requestInfo.options.body)
  params = parseJSON(requestInfo.options.body)

  m.assertNotInvalid(params)
  m.assertNotInvalid(params.action)
  m.assertEqual(params.action,  m.constants.ui.likeDislikeActions.like)

  m.assertNotInvalid(params.data)
  m.assertEqual(type(params.data), "roArray")
  m.assertEqual(params.data[0], testTitleId)

End Function


'@Test magicLink unit tests
Function userDeviceApi_magicLink_test()
  magicLinkUrl = m.constants.urls.account.magicLink
  email = m.testEmail
  options = {}
  options.params = {
    device_id: m.device_id
    platform: m.platform
  }

  requestInfo = m.userDeviceApi.magicLink(email)
  m.assertNotInvalid(requestInfo)
  m.assertNotInvalid(requestInfo.url)
  m.assertEqual(requestInfo.url, magicLinkUrl)

  m.assertNotInvalid(requestInfo.options)
  params = requestInfo.options.params
  m.assertNotInvalid(params)

  m.assertNotInvalid(params.email)
  m.assertEqual(params.email, m.testEmail)

  m.assertNotInvalid(params.device_id)
  m.assertEqual(params.device_id, m.device_id)

  m.assertNotInvalid(params.platform)
  m.assertEqual(params.platform, m.platform)
End Function


'@Test queryStatusOfMagicLink unit tests
Function userDeviceApi_queryStatusOfMagicLink_test()
  uid = "07ff5657-07f1-40d0-b3e0-27f60bbd90fa"
  options = {}
  options.params = {
    device_id: m.device_id
    platform: m.platform
  }
  queryUrlForMagicLink = m.constants.urls.account.magicLink + "/" + uid
  requestInfo = m.userDeviceApi.queryStatusOfMagicLink(uid)

  m.assertNotInvalid(requestInfo)
  m.assertNotInvalid(requestInfo.url)
  m.assertEqual(requestInfo.url, queryUrlForMagicLink)

  m.assertNotInvalid(requestInfo.options)
  params = requestInfo.options.params
  m.assertNotInvalid(params)

  m.assertNotInvalid(params.device_id)
  m.assertEqual(params.device_id, m.device_id)

  m.assertNotInvalid(params.platform)
  m.assertEqual(params.platform, m.platform)
End Function


'@Test updateParentalRatingReqInfo unit tests
Function userDeviceApi_updateParentalRatingReqInfo_test()
  parentalRating = 3
  userEnteredPassword = "password@tubi"
  parentalRatingReq = m.userDeviceApi.updateParentalRatingReqInfo(parentalRating, userEnteredPassword)

  m.assertNotInvalid(parentalRatingReq)

  m.assertNotInvalid(parentalRatingReq.url)
  m.assertEqual(parentalRatingReq.url, m.constants.urls.account.parentalRating)

  m.assertNotInvalid(parentalRatingReq.options)
  m.assertNotInvalid(parentalRatingReq.options.body)
  body = ParseJson(parentalRatingReq.options.body)
  m.assertNotInvalid(body.parental_rating)
  m.assertNotInvalid(body.password)
  m.assertEqual(body.parental_rating, 3)
  m.assertEqual(body.password, "password@tubi")

  m.assertNotInvalid(parentalRatingReq.options.headers)
  m.assertEqual(parentalRatingReq.options.method, "PUT")
End Function


'@Test removeFromQueueReqInfo unit tests
Function userDeviceApi_removeFromQueueReqInfo_test()
  bookmarkId = "AABBCCDD"
  contentId = "6682144"
  contentType = "series"
  url = m.constants.urls.userQueues.queues
  removeFromQueueReq = m.userDeviceApi.removeFromQueueReqInfo(bookmarkId, contentId, contentType)

  m.assertNotInvalid(removeFromQueueReq)

  m.assertNotInvalid(removeFromQueueReq.url)
  m.assertEqual(removeFromQueueReq.url, url)

  m.assertNotInvalid(removeFromQueueReq.options)

  m.assertNotInvalid(removeFromQueueReq.options.headers)
  m.assertEqual(removeFromQueueReq.options.method, "DELETE")

  params = removeFromQueueReq.options.params
  m.assertNotInvalid(params)

  m.assertNotInvalid(params.queue_id)
  m.assertEqual(params.queue_id, "AABBCCDD")

  m.assertNotInvalid(params.content_id)
  m.assertEqual(params.content_id, "6682144")

  m.assertNotInvalid(params.content_type)
  m.assertEqual(params.content_type, "series")
End Function


'@Test addToQueueReqMovie unit tests
Function userDeviceApi_addToQueueReqMovie_test()
  userId = 1234
  contentId = "321221"
  contentType = "movie"
  typeOfQueue = "watch_later"
  movieAddToQueueReq = m.userDeviceApi.addToQueueReqInfo(userId, contentId, contentType, typeOfQueue)

  m.assertNotInvalid(movieAddToQueueReq)

  m.assertNotInvalid(movieAddToQueueReq.url)
  m.assertEqual(movieAddToQueueReq.url, m.constants.urls.userQueues.queues)

  m.assertNotInvalid(movieAddToQueueReq.options)
  m.assertNotInvalid(movieAddToQueueReq.options.body)
  body = ParseJson(movieAddToQueueReq.options.body)
  m.assertNotInvalid(body.content_id)
  m.assertNotInvalid(body.content_type)
  m.assertEqual(body.content_id, "321221")
  m.assertEqual(body.content_type, "movie")
  m.assertEqual(body.type, "watch_later")

  m.assertNotInvalid(movieAddToQueueReq.options.headers)
  m.assertEqual(movieAddToQueueReq.options.method, "POST")
End Function


'@Test addToQueueReqSeries unit tests
Function userDeviceApi_addToQueueReqSeries_test()
  userId = 1234
  contentId = "01079"
  contentType = "series"
  typeOfQueue = "watch_later"
  seriesAddToQueueReqInfo = m.userDeviceApi.addToQueueReqInfo(userId, contentId, contentType, typeOfQueue)

  m.assertNotInvalid(seriesAddToQueueReqInfo)

  m.assertNotInvalid(seriesAddToQueueReqInfo.url)
  m.assertEqual(seriesAddToQueueReqInfo.url, m.constants.urls.userQueues.queues)

  m.assertNotInvalid(seriesAddToQueueReqInfo.options)
  m.assertNotInvalid(seriesAddToQueueReqInfo.options.body)
  body = ParseJson(seriesAddToQueueReqInfo.options.body)
  m.assertNotInvalid(body.content_id)
  m.assertNotInvalid(body.content_type)
  m.assertEqual(body.content_id, "01079")
  m.assertEqual(body.content_type, "series")
  m.assertEqual(body.type, "watch_later")

  m.assertNotInvalid(seriesAddToQueueReqInfo.options.headers)
  m.assertEqual(seriesAddToQueueReqInfo.options.method, "POST")
End Function


'@Test deleteHistory unit tests
Function userDeviceApi_deleteHistory_test()

  historyId = "56788"
  url = m.constants.urls.lishi.viewHistory + "/" + historyId

  deleteHistory = m.userDeviceApi.deleteHistory(historyId)

  m.assertNotInvalid(deleteHistory)

  m.assertNotInvalid(deleteHistory.url)
  m.assertEqual(deleteHistory.url, url)

  m.assertNotInvalid(deleteHistory.options)
  m.assertEqual(deleteHistory.options.method, "DELETE")

  params = deleteHistory.options.params
  m.assertNotInvalid(params)

End Function


'@Test addHistoryReqVideo_ParentIdAsInvalid unit tests
Function userDeviceApi_addHistoryReqVideo_ParentIdAsInvalid_test()
  content = m.movieContent
  content.id = "321221"
  content.title = "We Are Young"
  content.parentId = invalid
  reqInfo = m.userDeviceApi.getAddHistoryRequestInfo(content, 1478)

  m.assertNotInvalid(reqInfo)
  m.assertNotInvalid(reqInfo.url)
  m.assertEqual(m.historyUrl, reqInfo.url)

  options = reqInfo.options
  m.assertNotInvalid(options)

  body = ParseJson(options.body)
  m.assertEqual(content.id, body.content_id)
  m.assertEqual(content.type, body.content_type)
  m.assertInvalid(body.parent_id)

  m.assertEqual(1478, body["position"])

  headers = options.headers

  clientVersion = m.userDeviceApi.constants.deviceInfo.clientVersion

  m.assertEqual(headers["x-client-version"], clientVersion)
  m.assertEqual(headers["x-client-platform"], "roku")

  m.assertEqual(options.params.device_id, m.deviceId)
  m.assertEqual(options.params.app_id, m.app_id)
  m.assertEqual(options.params.platform, m.platform)
End Function


'@Test addHistoryReqVideo_ParentIdAsEmpty unit tests
Function userDeviceApi_addHistoryReqVideo_ParentIdAsEmpty_test()
  content = m.movieContent
  content.id = "321221"
  content.title = "We Are Young"
  content.parentId = ""
  reqInfo = m.userDeviceApi.getAddHistoryRequestInfo(content, 1478)

  m.assertNotInvalid(reqInfo)
  m.assertNotInvalid(reqInfo.url)
  m.assertEqual(m.historyUrl, reqInfo.url)

  options = reqInfo.options
  m.assertNotInvalid(options)

  body = ParseJson(options.body)
  m.assertEqual(content.id, body.content_id)
  m.assertEqual(content.type, body.content_type)
  m.assertInvalid(body.parent_id)

  m.assertEqual(1478, body["position"])

  headers = options.headers

  clientVersion = m.userDeviceApi.constants.deviceInfo.clientVersion

  m.assertEqual(headers["x-client-version"], clientVersion)
  m.assertEqual(headers["x-client-platform"], "roku")

  m.assertEqual(options.params.device_id, m.deviceId)
  m.assertEqual(options.params.app_id, m.app_id)
  m.assertEqual(options.params.platform, m.platform)
End Function


'@Test addHistoryReqEpisodeParentIdAsString unit tests
Function userDeviceApi_addHistoryReqEpisodeParentIdAsString_test()
  content = m.episodeContent
  content.id = "302800"
  content.title = "S02:E05 - You, I'll Be Following"
  content.parentId = "1079"

  reqInfo = m.userDeviceApi.getAddHistoryRequestInfo(content, 1478)

  m.assertNotInvalid(reqInfo)
  m.assertNotInvalid(reqInfo.url)
  m.assertEqual(m.historyUrl, reqInfo.url)

  options = reqInfo.options
  m.assertNotInvalid(options)

  body = ParseJson(options.body)
  m.assertEqual(content.id, body.content_id)
  m.assertEqual(content.type, body.content_type)

  m.assertEqual(1079, body.parent_id)

  m.assertEqual(1478, body["position"])

  headers = options.headers

  clientVersion = m.userDeviceApi.constants.deviceInfo.clientVersion

  m.assertEqual(headers["x-client-version"], clientVersion)
  m.assertEqual(headers["x-client-platform"], "roku")

  m.assertEqual(options.params.device_id, m.deviceId)
  m.assertEqual(options.params.app_id, m.app_id)
  m.assertEqual(options.params.platform, m.platform)
End Function


'@Test addHistoryReqEpisodeParentIdAsInteger unit tests
Function userDeviceApi_addHistoryReqEpisodeParentIdAsInteger_test()
  content = m.episodeContent
  content.id = "302800"
  content.title = "S02:E05 - You, I'll Be Following"
  content.parentId = 1079

  req = m.userDeviceApi.getAddHistoryRequestInfo(content, 1478)

  m.assertNotInvalid(req)
  m.assertNotInvalid(req.url)
  m.assertEqual(m.historyUrl, req.url)

  options = req.options
  m.assertNotInvalid(options)

  body = ParseJson(options.body)
  m.assertEqual(content.id, body.content_id)
  m.assertEqual(content.type, body.content_type)

  m.assertEqual(1079, body.parent_id)

  m.assertEqual(1478, body["position"])

  headers = options.headers

  clientVersion = m.userDeviceApi.constants.deviceInfo.clientVersion

  m.assertEqual(headers["x-client-version"], clientVersion)
  m.assertEqual(headers["x-client-platform"], "roku")

  m.assertEqual(options.params.device_id, m.deviceId)
  m.assertEqual(options.params.app_id, m.app_id)
  m.assertEqual(options.params.platform, m.platform)
End Function