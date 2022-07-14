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
  m.app_id = m.constants.settings.shortAppName
  m.platform = m.constants.platform
  m.device_id = m.constants.deviceInfo.deviceId
  m.testEmail = "test@tubi.tv"
  m.testPassword = "111111"
  m.app_id = "tubitv"

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


'@Test deleteHistory unit tests
Function userDeviceApi_deleteHistory_test()

  historyId="56788"
  url = m.constants.urls.userDevice.urlBase + "/histories/" + historyId

  deleteHistory = m.userDeviceApi.deleteHistory(historyId)

  m.assertNotInvalid(deleteHistory)

  m.assertNotInvalid(deleteHistory.url)
  m.assertEqual(deleteHistory.url, url)

  m.assertNotInvalid(deleteHistory.options)
  m.assertEqual(deleteHistory.options.method, "DELETE")

  params = deleteHistory.options.params
  m.assertNotInvalid(params)

End Function
