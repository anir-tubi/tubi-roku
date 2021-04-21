'@TestSuite [TubiAuth] Auth.brs 

'@Setup
Function TubiAuthSetup()
  m.constants = getConstants()
  m.request = TubiRequest()
  m.auth = TubiAuth(m.constants, m.request)
  
  m.externalAuthInfo = {
    platform: "ios"
    externalDeviceId: "AABBCCDD"
    externalRefreshToken: "Some111Refresh999String000"
    userId: "6735"
  }
  
  m.oldAuthInfo = {
    expireTime: "123456"
    accessToken: "Some555Other666String777"
    refreshToken: "Some111Refresh999String000"
    userId: "6735"
  }
  
  'stub auth info from server after registration
  'some APIs return "name", others return "first_name" and "last_name"
  'we don't save facebook id or email in the registry
  m.serverAuthInfo = {
    user_id: 654722
    facebook_id: invalid,
    email: "generic@email.com"
    name: "somebody"
    first_name: "somebody"
    last_name: "special"
    access_token: "abcdefgHIJKKV1QiLCJhbGciOiJIUzI1NiJ9"
    refresh_token: "LMNOPquestuvJKV1QiLCJhbGciOiJIUzI1NiJ9"
    expires_in: 1209600
    authType: "EMAIL"
    has_age: true
  }  
    
  ' mocks
  m.requestTokenRefresh = Function(authInfo, authPort)
    return {} ' passes through to handleRefreshResponse so it can be anything but invalid
  End Function
  
  m.requestTokenTransfer = Function(externalAuthInfo, authPort)
    return {} 
  End Function
  
End function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It AuthToken functions in Auth.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test refreshAuthToken unit tests
Function tubiAuth_refreshAuthToken_test()
  auth = m.auth
  oldAuthInfo = m.oldAuthInfo
  
  auth.handleRefreshResponse = Function(msg, refreshReq)
    return {
      access_token: "AABBCCDD"
      refresh_token: "AABBCCDD"
      expires_in: 86400
      user_id: "6735"
    }
  End Function

  newAuthInfo = auth.refreshAuthToken(oldAuthInfo, 1)
  m.AssertNotInvalid(newAuthInfo.accessToken)
  m.AssertNotInvalid(newAuthInfo.refreshtoken)
End Function


'@Test refreshAuthToken failed unit tests
Function tubiAuth_refreshAuthToken_failed_test()
  auth = m.auth
  oldAuthInfo = m.oldAuthInfo
  
  auth.handleRefreshResponse = Function(msg, refreshReq)
    return invalid
  End Function

  newAuthInfo = auth.refreshAuthToken(oldAuthInfo, 1)
  m.AssertInvalid(newAuthInfo)
End Function


'@Test refreshAuthToken_403 unit tests
Function tubiAuth_refreshAuthToken_403_test()
  auth = m.auth
  oldAuthInfo = m.oldAuthInfo
  
  auth.saveAuthInfo(oldAuthInfo)  ' save it to the registry to verify clearing

  auth.handleRefreshResponse = Function(msg, refreshReq)
    return {} ' indicative of the old tokens being invalid and should not be stored
  End Function

  savedAuthInfo = RegReadAll(auth.authRegSection)
  m.AssertNotInvalid(savedAuthInfo)
  m.AssertNotInvalid(savedAuthInfo.accessToken)
  m.AssertNotInvalid(savedAuthInfo.refreshToken)
  newAuthInfo = auth.refreshAuthToken(oldAuthInfo, 1)
  m.AssertInvalid(newAuthInfo)
  savedAuthInfo = RegReadAll(auth.authRegSection)
  m.AssertNotInvalid(savedAuthInfo)
  m.AssertInvalid(savedAuthInfo.accessToken)
  m.AssertInvalid(savedAuthInfo.refreshToken)
End Function


'@Test formatAuthInfoFromServer unit tests
Function tubiAuth_formatAuthInfoFromServer_test()
  auth = m.auth
  serverAuthInfo = m.serverAuthInfo

  dateTime = CreateObject("roDateTime")
  timeToNow = dateTime.AsSeconds()
  expireCheck = (serverAuthInfo.expires_in + timeToNow).toStr()
  authInfo = auth.formatAuthInfoFromServer(serverAuthInfo)
  m.assertNotInvalid(authInfo.userId)
  m.assertEqual(authInfo.userId, serverAuthInfo.user_id.toStr())
  m.assertNotInvalid(authInfo.name)
  m.assertEqual(authInfo.name, serverAuthInfo.name)
  m.assertNotInvalid(authInfo.fn)
  m.assertEqual(authInfo.fn, serverAuthInfo.first_name)
  m.assertNotInvalid(authInfo.ln)
  m.assertEqual(authInfo.ln, serverAuthInfo.last_name)
  m.assertNotInvalid(authInfo.accessToken)
  m.assertEqual(authInfo.accessToken, serverAuthInfo.access_token)
  m.assertNotInvalid(authInfo.refreshToken)
  m.assertEqual(authInfo.refreshToken, serverAuthInfo.refresh_token)
  m.assertNotInvalid(authInfo.expireTime)
  m.assertEqual(authInfo.expireTime, expireCheck)

  m.assertNotInvalid(authInfo.authType)
  m.assertEqual(authInfo.authType, serverAuthInfo.authType)

  m.assertNotInvalid(authInfo.hasAge)
  m.assertEqual(authInfo.hasAge, serverAuthInfo.has_age.toStr())
End Function


'@Test checkIfAuthExpired unit tests
Function tubiAuth_checkIfAuthExpired_test()
  auth = m.auth
  clock = CreateObject("roDateTime")
  present = clock.AsSeconds()
  past = present - 30000
  future = present + 30000

  'stub expired authInfo
  expiredAuthInfo = {
    refreshToken: "123456789101112131415"
    accessToken: "1617181920212223242526"
    expireTime: past
    userId: "12345"
  }
  isPastExpired = auth.checkIfAuthExpired(expiredAuthInfo)
  m.assertTrue(isPastExpired)

  'stub non expired authInfo
  validAuthInfo = {
    refreshToken: "123456789101112131415"
    accessToken: "1617181920212223242526"
    expireTime: future
    userId: "12345"
  }
  isFutureExpired = auth.checkIfAuthExpired(validAuthInfo)
  m.assertFalse(isFutureExpired)
End Function


'@Test updateAuthInfo unit tests
Function tubiAuth_updateAuthInfo_test()
  auth = m.auth
  authInfo = m.oldAuthInfo
  
  dateTime = CreateObject("roDateTime")
  timeToNow = dateTime.AsSeconds()
  future = (timeToNow + 86400).toStr()
  refreshInfo = {
    user_id: "6735"
    expires_in: 86400
    access_token: "Some222Crazy333String444"
  }
  
  updatedAuthInfo = auth.updateAuthInfo(refreshInfo, authInfo)
  m.assertEqual(updatedAuthInfo.expireTime, future)
End Function


'@Test getAuthHeaders unit tests
Function tubiAuth_getAuthHeaders_test()
  auth = m.auth
  token = "Some555Other666String777"
  authHeaders = auth.getAuthHeaders(token)
  m.assertNotInvalid(authHeaders["Content-Type"])
  m.assertEqual(authHeaders["Content-Type"], "application/json")
  m.assertNotInvalid(authHeaders["Authorization"])
  m.assertEqual(authHeaders["Authorization"], "Bearer " + token)
End Function


'@Test saveAuthInfo unit tests
Function tubiAuth_saveAuthInfo_test()
  auth = m.auth
  auth.authRegSection = "testauth"
  authInfo1 = {
    expireTime: "123456"
    accessToken: "Some555Other666String777"
    refreshToken: "Some111Refresh999String000"
    userId: "6735"
  }
  authInfo2 = {
    expireTime: "234567"
    refreshToken: "Some111Refresh999String000x"
    userId: "6736"
  }
  authInfo3 = {
    accessToken: "Some555Other666String777a"
    refreshToken: "Some111Refresh999String000y"
    userId: "6737"
  }
  authInfo4 = {
    expireTime: "123456"
    accessToken: "Some555Other666String777b"
    userId: "6738"
  }
  authInfo5 = {
    expireTime: "123456"
    accessToken: "Some555Other666String777c"
    refreshToken: "Some111Refresh999String000z"
  }
  authInfo6 = {
    expireTime: 123456
    accessToken: "Some555Other666String777d"
    refreshToken: "Some111Refresh999String000w"
    userId: "6739"
  }

  authInfo1 = auth.saveAuthInfo(authInfo1) 
  authInfo2 = auth.saveAuthInfo(authInfo2) 'invalid?
  authInfo3 = auth.saveAuthInfo(authInfo3) 'invalid?
  authInfo4 = auth.saveAuthInfo(authInfo4) 'invalid?
  authInfo5 = auth.saveAuthInfo(authInfo5) 'invalid?
  authInfo6 = auth.saveAuthInfo(authInfo6) 'invalid?
  savedAuthInfo = RegReadAll(auth.authRegSection)
  m.assertNotInvalid(authInfo1)
  m.assertInvalid(authInfo2)
  m.assertInvalid(authInfo3)
  m.assertInvalid(authInfo4)
  m.assertInvalid(authInfo5)
  m.assertInvalid(authInfo6)
  m.assertEqual(savedAuthInfo.expireTime, authInfo1.expireTime)
  m.assertEqual(savedAuthInfo.accessToken, authInfo1.accessToken)
  m.assertEqual(savedAuthInfo.refreshToken, authInfo1.refreshToken)
  m.assertEqual(savedAuthInfo.userId, authInfo1.userId)
  authSection = CreateObject("roRegistry")
  authSection.delete(auth.authRegSection)
  authSection.flush()
End Function


'@Test deleteAuthInfo unit tests
Function tubiAuth_deleteAuthInfo_test()
  auth = m.auth
  authInfo = m.oldAuthInfo
  auth.authRegSection = "testauth"
  
  'authInfo = {
  '  expireTime: "123456"
  '  accessToken: "Some555Other666String777"
  '  refreshToken: "Some111Refresh999String000"
  '  userId: "6735"
  '}

  for each a in authInfo
    RegWrite(a, authInfo[a], auth.authRegSection)
  end for
  auth.deleteAuthInfo()
  deletedAuthInfo = RegReadAll(auth.authRegSection)
  authInfoStillExists = false
  if deletedAuthInfo.count() > 0 
    authInfoStillExists = true
  end if
  m.assertFalse(authInfoStillExists)
End Function


'@Test updateAuthInfoWithAge unit tests
Function tubiAuth_updateAuthInfoWithAge_test()
  auth = m.auth
  hasAge = true

  ' test when there is an existing authInfo in the registry
  dateTime = CreateObject("roDateTime")
  timeInSecs = dateTime.asSeconds() + 100
  authInfo = {
    expireTime: timeInSecs.toStr()
    accessToken: "Some555Other666String777"
    refreshToken: "Some111Refresh999String000"
    userId: "6735"
  }

  ' save auth info as a precursor to the test - updateAuthInfo() expects an authInfo to exist
  ' in the registry. To be deleted at end of this test function.
  auth.authRegSection = "testauth"
  auth.saveAuthInfo(authInfo)

  newAuthInfo = auth.updateAuthInfoWithAge(hasAge)
  savedAuthInfo = auth.getAuthInfo()

  m.assertNotInvalid(newAuthInfo)
  m.assertAAHasKeys(newAuthInfo, [
    "expireTime"
    "accessToken"
    "refreshToken"
    "userId"
    "hasAge"
  ])
  m.assertEqual(newAuthInfo.hasAge, true)

  m.assertNotInvalid(savedAuthInfo)
  m.assertAAHasKeys(savedAuthInfo, [
    "expireTime"
    "accessToken"
    "refreshToken"
    "userId"
    "hasAge"
  ])
  m.assertEqual(savedAuthInfo.hasAge, true)

  ' remove the test auth registry
  auth.deleteAuthInfo()

  ' test when there is no authInfo in the registry (guest user)
  newAuthInfo = auth.updateAuthInfoWithAge(hasAge)
  m.assertInvalid(newAuthInfo)
End Function


'@Test requestTokenRefresh unit tests
Function tubiAuth_requestTokenRefresh_test()
  auth = m.auth
  auth.constants.urls.users.refreshToken = "http://127.0.0.1:65535/"
  savedAuthInfo = m.oldAuthInfo

  server = tubiAuth_createMetadataFetchTaskServer_testHelper(65535)
  msgPort = CreateObject("roMessagePort")
  server.SetMessagePort(msgPort)
  authRequest = auth.requestTokenRefresh(savedAuthInfo, msgPort)
  m.assertNotInvalid(authRequest)
  m.assertNotInvalid(authRequest.isHttps)
  m.assertNotInvalid(authRequest.url)
  m.assertEqual(authRequest.url, auth.constants.urls.users.refreshToken)
  m.assertNotInvalid(authRequest.method)
  m.assertEqual(authRequest.method, "POST")
End Function


'@Test requestTokenTransfer unit tests
Function tubiAuth_requestTokenTransfer_test()
  auth = m.auth
  auth.constants.urls.users.transferToken = "http://127.0.0.1:65535/"
  externalAuthInfo = {
    platform: "iphone"
    externalDeviceId: "Some555Other666String777"
    externalRefreshToken: "Some111Refresh999String000"
    userId: "6735"
  }

  server = tubiAuth_createMetadataFetchTaskServer_testHelper(65535)
  msgPort = CreateObject("roMessagePort")
  server.SetMessagePort(msgPort)
  authRequest = auth.requestTokenTransfer(externalAuthInfo, msgPort)
  m.assertNotInvalid(authRequest)
  m.assertNotInvalid(authRequest.isHttps)
  m.assertNotInvalid(authRequest.url)
  m.assertEqual(authRequest.url, auth.constants.urls.users.transferToken)
  m.assertNotInvalid(authRequest.method)
  m.assertEqual(authRequest.method, "POST")
End Function


'@Test handleRefreshResponse unit tests
Function tubiAuth_handleRefreshResponse_test()

  constants = getConstants()
  requestObj = TubiRequest()
  auth = TubiAuth(constants, requestObj)
  
  url = "http://127.0.0.1:65535/"
  server = tubiAuth_createMetadataFetchTaskServer_testHelper(65535)
  msgPort = CreateObject("roMessagePort")
  server.SetMessagePort(msgPort)
  request = requestObj.createAsync(url, "fakeRequest", {})
  isReqStarted = request.start(msgPort)
  newAccess = invalid
  mockServerInfo = {
    user_id: 12345
    access_token: "some333acess666Token901234565"
    expires_in: 1209600
  }
  json = FormatJSON(mockServerInfo)

  if isReqStarted = true
    while true
      msg = wait(0, msgPort)

      if type(msg) = "roSocketEvent"

        connection = server.accept()
        buffer = connection.receiveStr(1024)

        response =            "HTTP/1.1 200 OK" + Chr(13) + Chr(10)
        response = response + "Content-length: " + stri(json.len()) + Chr(13) + Chr(10)
        response = response + "Connection: close" + Chr(13) + Chr(10)
        response = response + Chr(13) + Chr(10)
        response = response + json + Chr(13) + Chr(10)
        response = response + Chr(13) + Chr(10)
        connection.sendstr(response)
        connection.close()
      
      else if type(msg) = "roUrlEvent"
        newAccess = auth.handleRefreshResponse(msg, request)
        exit while
      end if

    end while
  end if
  m.assertNotInvalid(newAccess)
  m.assertNotInvalid(newAccess.user_id)
  m.assertEqual(newAccess.user_id, mockServerInfo.user_id)
  m.assertNotInvalid(newAccess.access_token)
  m.assertEqual(newAccess.access_token, mockServerInfo.access_token)
  m.assertNotInvalid(newAccess.expires_in)
  m.assertEqual(newAccess.expires_in, mockServerInfo.expires_in)
End Function


'@Test handleRefreshResponse 403 unit tests
Function tubiAuth_handleRefreshResponse_403()
  
  constants = getConstants()
  requestObj = TubiRequest()
  auth = TubiAuth(constants, requestObj)
  
  url = "http://127.0.0.1:65535/"
  server = tubiAuth_createMetadataFetchTaskServer_testHelper(65535)
  msgPort = CreateObject("roMessagePort")
  server.SetMessagePort(msgPort)
  request = requestObj.createAsync(url, "fakeRequest", {})
  isReqStarted = request.start(msgPort)
  newAccess = invalid

  if isReqStarted = true
    while true
      msg = wait(0, msgPort)

      if type(msg) = "roSocketEvent"

        connection = server.accept()
        buffer = connection.receiveStr(1024)

        response =            "HTTP/1.1 403 Forbidden" + Chr(13) + Chr(10)
        response = response + "Content-length: 0" + Chr(13) + Chr(10)
        response = response + "Connection: close" + Chr(13) + Chr(10)
        response = response + Chr(13) + Chr(10)
        connection.sendstr(response)
        connection.close()
      
      else if type(msg) = "roUrlEvent"
        newAccess = auth.handleRefreshResponse(msg, request)
        exit while
      end if

    end while
  end if
  m.assertNotInvalid(newAccess)
  m.assertInvalid(newAccess.user_id)
  m.assertInvalid(newAccess.access_token)
  m.assertInvalid(newAccess.refresh_token)
  m.assertInvalid(newAccess.expires_in)
End Function


'@Test createAuthRequest unit tests
Function tubiAuth_createAuthRequest_test()
  auth = m.auth
  url = "https://somefakeurl.com"
  'a good set of authInfo... should create a valid auth request
  auth.getAuthInfo = Function()
    return {
      expireTime: 123456
      accessToken: "Some555Other666String777d"
      refreshToken: "Some111Refresh999String000w"
      userId: "6739"
    }
  End Function

  authRequest = auth.createAuthRequest(url, "goodAuthRequest")
  m.assertNotInvalid(authRequest)
  m.assertNotInvalid(authRequest.getAuthHeaders)
  m.assertNotInvalid(authRequest.refreshAuthToken)
  m.assertNotInvalid(authRequest.updateAuthInfo)
  m.assertNotInvalid(authRequest.saveAuthInfo)
  m.assertNotInvalid(authRequest.handleRefreshResponse)
  m.assertNotInvalid(authRequest.constants)
  m.assertNotInvalid(authRequest.request)
  m.assertNotInvalid(authRequest.authInfo)

  'a bad set of authInfo... should create an invalid auth request
  auth.getAuthInfo = Function()
    return {
      expireTime: 123456
      refreshToken: "Some111Refresh999String000w"
      userId: "6739"
    }
  End Function

  authRequest = auth.createAuthRequest(url, "badAuthRequest")
  m.assertInvalid(authRequest)
End Function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It transferRefreshToken functions in Auth.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test transferRefreshToken unit tests
Function tubiAuth_transferRefreshToken_test()
  auth = m.auth
  externalAuthInfo = m.externalAuthInfo
  
  auth.requestTokenRefresh = m.requestTokenRefresh
  auth.requestTokenTransfer = m.requestTokenTransfer

  auth.handleRefreshResponse = Function(msg, refreshReq)
    return {
      access_token: "AABBCCDD"
      refresh_token: "AABBCCDD"
      expires_in: 86400
      user_id: "6735"
    }
  End Function

  auth.refreshAuthToken = Function(stubbedAuthInfo, timeout)
    return {
      accessToken: "AABBCCDD"
      refreshToken: "AABBCCDD"
      expiresTime: 86400
      userId: "6735"
    }
  End Function

  newAuthInfo = auth.transferRefreshToken(externalAuthInfo, 1)
  m.AssertNotInvalid(newAuthInfo)
  m.AssertNotInvalid(newAuthInfo.accessToken)
  m.AssertNotInvalid(newAuthInfo.refreshtoken)
End Function


'@Test transferRefreshToken failed unit tests
Function tubiAuth_transferRefreshToken_failed_test()
  auth = m.auth
  externalAuthInfo = m.externalAuthInfo
  
  auth.requestTokenRefresh = m.requestTokenRefresh
  auth.requestTokenTransfer = m.requestTokenTransfer  

  auth.handleRefreshResponse = Function(msg, refreshReq)
    return invalid
  End Function

  newAuthInfo = auth.transferRefreshToken(externalAuthInfo, 1)
  m.AssertInvalid(newAuthInfo)
End Function


'@Test transferRefreshToken 403 unit tests
Function tubiAuth_transferRefreshToken_403_test()
  auth = m.auth
  externalAuthInfo = m.externalAuthInfo
  
  auth.requestTokenRefresh = m.requestTokenRefresh
  auth.requestTokenTransfer = m.requestTokenTransfer  

  auth.handleRefreshResponse = Function(msg, refreshReq)
    return {} ' indicates 403
  End Function

  newAuthInfo = auth.transferRefreshToken(externalAuthInfo, 1)
  m.AssertInvalid(newAuthInfo)
End Function


Function tubiAuth_createMetadataFetchTaskServer_testHelper(tcpPort As Integer)
  server = CreateObject("roStreamSocket")
  address = CreateObject("roSocketAddress")
  address.setPort(tcpPort)
  server.setAddress(address)
  server.notifyReadable(true)
  server.listen(4)
  return server
End Function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests visit functions in Auth.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@BeforeEach
Function tubiAuth_visit_BeforeEach() as void

  m.tubiAuth = m.auth
  
  'use a fake section so not to disturb actual first visit info
  m.tubiAuth.firstVisitRegSection = "testVisit"

End Function


'@Test getFirstVisit unit tests
Function tubiAuth_getFirstVisit_test()

  'set up a fake value that we will attempt to get
  m.tubiAuth.regWrite("firstVisit", "56789", m.tubiAuth.firstVisitRegSection)
  firstVisit = m.tubiAuth.getFirstVisit()
  m.AssertEqual(firstVisit, 56789)

End Function


'@Test setFirstVisit unit tests
Function tubiAuth_setFirstVisit_test()

  dateTime = CreateObject("roDateTime")
  days = Int(dateTime.AsSeconds() / 24 / 60 / 60)
  firstVisit = m.tubiAuth.setFirstVisit() 'should be integer
  m.assertEqual(firstVisit, days)

  registryFirstVisit = m.tubiAuth.regRead("firstVisit", m.tubiAuth.firstVisitRegSection)
  m.assertNotInvalid(registryFirstVisit)
  m.assertEqual(firstVisit, registryFirstVisit.toInt())
  
End Function


'@AfterEach
Function tubiAuth_visit_AfterEach() as void
  'clear out any leftover info in the "testVisit" section
  m.tubiAuth.regDelete("firstVisit", m.tubiAuth.firstVisitRegSection)
End Function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests hasAge functions in Auth.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@BeforeEach
Function tubiAuth_hasAge_BeforeEach() as void
  m.tubiAuth = m.auth

  'use a fake section so not to disturb actual first visit info
  m.tubiAuth.guestUserHasAgeRegSection = "testHasAge"
End Function


'@Test getHasAge unit tests
Function tubiAuth_getHasAge_test()
  'stub a value into the registry that we will attempt to get for not expired
  dateTime = CreateObject("roDateTime")
  nowTime = dateTime.AsSeconds()
  hasAgeStored = {
    expireTime: nowTime + 500
    hasAge: true
  }
  hasAgeStored = FormatJSON(hasAgeStored)
  m.tubiAuth.regWrite("ageInfo", hasAgeStored, m.tubiAuth.guestUserHasAgeRegSection)

  hasAgeInfo = m.tubiAuth.getGuestUserHasAgeInfo()

  m.AssertNotInvalid(hasAgeInfo)
  m.AssertEqual(hasAgeInfo.hasAge, true)
  m.AssertEqual(hasAgeInfo.expired, false)

  'stub a value into the registry that we will attempt to get for expired
  hasAgeStored = {
    expireTime: nowTime - 500
    hasAge: true
  }
  hasAgeStored = FormatJSON(hasAgeStored)
  m.tubiAuth.regWrite("ageInfo", hasAgeStored, m.tubiAuth.guestUserHasAgeRegSection)

  hasAgeInfo = m.tubiAuth.getGuestUserHasAgeInfo()

  m.AssertNotInvalid(hasAgeInfo)
  m.AssertEqual(hasAgeInfo.hasAge, true)
  m.AssertEqual(hasAgeInfo.expired, true)

  ' test when there is no hasAge information in the registry
  m.tubiAuth.regDelete("ageInfo", m.tubiAuth.guestUserHasAgeRegSection)

  hasAgeInfo = m.tubiAuth.getGuestUserHasAgeInfo()

  m.AssertNotInvalid(hasAgeInfo)
  m.AssertEqual(hasAgeInfo.hasAge, false)
  m.AssertEqual(hasAgeInfo.expired, true)
End Function


'@Test setHasAge unit tests
Function tubiAuth_setHasAge_test()
  dateTime = CreateObject("roDateTime")
  nowTime = dateTime.AsSeconds()

  ' test when hasAge param is true
    ' test what is returned by the function is correct
  hasAgeInfo = m.tubiAuth.setGuestUserHasAgeInfo(true)
  m.assertNotInvalid(hasAgeInfo)
  m.assertTrue(hasAgeInfo.hasAge)
  m.assertType(hasAgeInfo.expireTime, "roInteger")
  m.assertTrue(hasAgeInfo.expireTime >= nowTime)

    'test what has been saved to the registry is correct
  registryHasAgeInfo = m.tubiAuth.regRead("ageInfo", m.tubiAuth.guestUserHasAgeRegSection)
  registryHasAgeInfo = ParseJson(registryHasAgeInfo)
  m.assertNotInvalid(registryHasAgeInfo)
  m.assertType(hasAgeInfo.expireTime, "roInteger")
  m.assertTrue(hasAgeInfo.expireTime >= nowTime)
  m.assertTrue(registryHasAgeInfo.hasAge)

  ' test when hasAge param is false
    ' test what is returned by the function is correct
  hasAgeInfo = m.tubiAuth.setGuestUserHasAgeInfo(false)
  m.assertNotInvalid(hasAgeInfo)
  m.assertFalse(hasAgeInfo.hasAge)
  m.assertType(hasAgeInfo.expireTime, "roInteger")
  m.assertTrue(hasAgeInfo.expireTime >= nowTime)

    'test what has been saved to the registry is correct
  registryHasAgeInfo = m.tubiAuth.regRead("ageInfo", m.tubiAuth.guestUserHasAgeRegSection)
  registryHasAgeInfo = ParseJson(registryHasAgeInfo)
  m.assertNotInvalid(registryHasAgeInfo)
  m.assertType(hasAgeInfo.expireTime, "roInteger")
  m.assertTrue(hasAgeInfo.expireTime >= nowTime)
  m.assertFalse(registryHasAgeInfo.hasAge)

  ' test when hasAge param is not boolean
    ' test what is returned by the function is correct
  hasAgeInfo = m.tubiAuth.setGuestUserHasAgeInfo("notBool")
  m.assertNotInvalid(hasAgeInfo)
  m.assertFalse(hasAgeInfo.hasAge)
  m.assertType(hasAgeInfo.expireTime, "roInteger")
  m.assertTrue(hasAgeInfo.expireTime >= nowTime)

    'test what has been saved to the registry is correct
  registryHasAgeInfo = m.tubiAuth.regRead("ageInfo", m.tubiAuth.guestUserHasAgeRegSection)
  registryHasAgeInfo = ParseJson(registryHasAgeInfo)
  m.assertNotInvalid(registryHasAgeInfo)
  m.assertType(hasAgeInfo.expireTime, "roInteger")
  m.assertTrue(hasAgeInfo.expireTime >= nowTime)
  m.assertFalse(registryHasAgeInfo.hasAge)
End Function


'@AfterEach
Function tubiAuth_hasAge_AfterEach() as void
  'clear out any leftover info in the "testHasAge" section
  m.tubiAuth.regDelete("ageInfo", m.tubiAuth.guestUserHasAgeRegSection)
End Function