'@TestSuite [UserDeviceApi] UserDeviceApi.brs 

'@Setup
Function UserDeviceApiSetup()

  m.constants = getConstants()
  request = TubiRequest()
  auth = TubiAuth(m.constants, request)
  m.userDeviceApi = UserDeviceApi(m.constants, request, auth)
  m.emailExistsUrl = m.constants.urls.account.emailExists
  m.signupUrl = m.constants.urls.users.signup
  m.loginUrl = m.constants.urls.account.login
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


'@Test commonOptions unit tests
Function userDeviceApi_commonOptions_test()

  options = m.userDeviceApi.commonOptions()
  m.assertNotInvalid(options)
  
  params = options.params
  m.assertNotInvalid(params)
  
  m.assertNotInvalid(params.app_id)
  m.assertEqual(params.app_id, m.app_id)
  
  m.assertNotInvalid(params.platform)
  m.assertEqual(params.platform, m.platform)
  
  m.assertNotInvalid(params.device_id)
  m.assertEqual(params.device_id, m.device_id)

End Function


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
  m.assertEqual(requestInfo.url, m.loginUrl)  
  
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