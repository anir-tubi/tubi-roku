'@TestSuite [UserDeviceApi] UserDeviceApi.brs 

'@Setup
Function UserDeviceApiSetup()

  m.constants = getConstants()
  utils = ApiUtils(m.constants)
  m.userDeviceApi = UserDeviceApi(m.constants, utils)
  m.emailExistsUrl = m.constants.urls.account.emailExists
  m.signupUrl = m.constants.urls.users.signup
  m.deviceRegisterUrl = m.constants.urls.account.deviceRegister
  m.checkBirthdayUrl = m.constants.urls.account.checkBirthday
  m.patchSettingsUrl = m.constants.urls.users.settings
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
  userId = "1234"
  checkBirthdayInfo = m.userDeviceApi.checkBirthdayInfo(userId)

  m.assertNotInvalid(checkBirthdayInfo)

  m.assertNotInvalid(checkBirthdayInfo.url)
  m.assertEqual(checkBirthdayInfo.url, m.checkBirthdayUrl)

  m.assertNotInvalid(checkBirthdayInfo.options)

  m.assertNotInvalid(checkBirthdayInfo.options.params)
  m.assertNotInvalid(checkBirthdayInfo.options.params.user_id)
End Function


'@Test patchSettingsInfo unit tests
Function userDeviceApi_patchSettingsInfo_test()
  userId = "1234"
  birthdate = "04-01-1984"
  passedOptions = {
    body: {
      birthday: birthdate
      random_setting: true
    }
  }
  patchSettingsInfo = m.userDeviceApi.patchSettingsInfo(userId, passedOptions)

  m.assertNotInvalid(patchSettingsInfo)

  m.assertNotInvalid(patchSettingsInfo.url)
  m.assertEqual(patchSettingsInfo.url, m.patchSettingsUrl + "/" + userId + "/settings")

  m.assertNotInvalid(patchSettingsInfo.options)

  m.assertNotInvalid(patchSettingsInfo.options.body)
  body = ParseJson(patchSettingsInfo.options.body)

  m.assertNotInvalid(body.birthday)
  m.assertEqual(body.birthday, birthdate)

  m.assertNotInvalid(body.random_setting)
  m.assertEqual(body.random_setting, true)

  m.assertEqual(patchSettingsInfo.options.method, "PATCH")
End Function
