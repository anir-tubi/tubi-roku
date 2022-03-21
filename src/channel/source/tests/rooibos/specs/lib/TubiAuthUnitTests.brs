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

  m.requestObjKeys = [
    "isHttps"
    "url"
    "start"
    "handleEvent"
    "hasData"
    "runSynchronous"
    "cancel"
    "name"
    "response"
    "uuid"
    "addParamsToUrl_"
    "urltransfer"
    "klass"
    "configMode"
    "charlesProxyEnabled"
    "charlesProxyUrl"
    "passThroughCharlesProxy"
  ]

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
  m.assertNotInvalid(authInfo.firstName)
  m.assertEqual(authInfo.firstName, serverAuthInfo.first_name)
  m.assertNotInvalid(authInfo.lastName)
  m.assertEqual(authInfo.lastName, serverAuthInfo.last_name)
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
  m.assertNotInvalid(authHeaders["x-client-platform"])
  m.assertNotInvalid(authHeaders["x-client-version"])
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
  savedAuthInfo = RegReadAll(auth.authRegSection)
  m.assertNotInvalid(authInfo1)
  m.assertInvalid(authInfo2)
  m.assertInvalid(authInfo3)
  m.assertInvalid(authInfo4)
  m.assertInvalid(authInfo5)
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
  m.assertInvalid(newAuthInfo.hasAge)
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


'@Test getGuestUserHasAgeInfo unit tests
Function tubiAuth_getGuestUserHasAgeInfo_test()
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


'@Test setGuestUserHasAgeInfo unit tests
Function tubiAuth_setGuestUserHasAgeInfo_test()
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


'@Test deleteGuestUserHasAgeInfo unit tests
Function tubiAuth_deleteGuestUserHasAgeInfo_test()
  ' add hasAge info to the device registry
  m.tubiAuth.setGuestUserHasAgeInfo(true)

  ' verify there is some info in the registry
  registryHasAgeInfo = m.tubiAuth.regRead("ageInfo", m.tubiAuth.guestUserHasAgeRegSection)
  registryHasAgeInfo = ParseJson(registryHasAgeInfo)
  m.assertNotInvalid(registryHasAgeInfo)

  ' remove the info from the registry (testing that this function works properly!)
  m.tubiAuth.deleteGuestUserHasAgeInfo()

  ' verify that there is no more ageInfo in the registry
  registryHasAgeInfo = m.tubiAuth.regRead("ageInfo", m.tubiAuth.guestUserHasAgeRegSection)
  m.assertInvalid(registryHasAgeInfo)
End Function


'@AfterEach
Function tubiAuth_hasAge_AfterEach() as void
  'clear out any leftover info in the "testHasAge" section
  m.tubiAuth.regDelete("ageInfo", m.tubiAuth.guestUserHasAgeRegSection)
End Function


'@Test createSignature unit tests
Function tubiAuth_createSignature_test()

  auth = m.auth
  dateTime = "2021-12-13T22:27:04Z"

  sampleBody = {
    "device_id":"5d9bb3b3-dfab-50af-a65e-28d25ca4d32b",
    "id":"419f8a8e-b1aa-4763-ac4e-e451ee7358e7",
    "platform":"roku",
    "verifier":"846d141f-e75e-4414-9116-b83cda6f9e5f"
  }
  bodyJson = FormatJson(sampleBody)

  headers = {
    "Accept-Language": "en-US"
    "Content-Type": "application/json"
    "x-client-platform": "roku"
    "x-client-version": "2.16.0"
  }

  tokenReqInfo = {
    body: bodyJson
    headers: headers
    method: "POST"
    retries: 0
    url: "https://account.staging-public.tubi.io/device/anonymous/token"
  }

  secretKey = "E0/oUbuegEiXkHF7L7QGEA/tMS2HjybWMOb9WoKgwww="
  algorithm = "TUBI-HMAC-SHA256"

  expected_signature = "e316fa7e1a49730292161f5041859b5455f69f288e542fa53162db638233aa4f"
  signature = auth.createSignature(dateTime, tokenReqInfo, secretKey, algorithm)
  m.assertEqual(signature, expected_signature)

End Function


'@Test constructCanonicalRequest unit tests
Function tubiAuth_constructCanonicalRequest_test()

  auth = m.auth
  sampleBody = {
    "device_id":"5d9bb3b3-dfab-50af-a65e-28d25ca4d32b",
    "id":"daa3a5ee-d410-414a-8512-20cfe550468b",
    "platform":"roku",
    "verifier":"846d141f-e75e-4414-9116-b83cda6f9e5f"
  }
  bodyJson = FormatJson(sampleBody)

  headers = {
    "Accept-Language": "en-US"
    "Content-Type": "application/json"
    "x-client-platform": "roku"
    "x-client-version": "2.16.0"
  }

  tokenReqInfo = {
    body: bodyJson
    headers: headers
    method: "POST"
    retries: 0
    url: "https://account.staging-public.tubi.io/device/anonymous/token"
  }

  expected_canonicalRequest = "POST" + chr(10) + "/device/anonymous/token" + chr(10) + "" + chr(10) + "accept-language:en-US" + chr(10) + "content-type:application/json" + chr(10) + "x-client-platform:roku" + chr(10) + "x-client-version:2.16.0" + chr(10) + "" + chr(10) + "accept-language;content-type;x-client-platform;x-client-version" + chr(10) + "9486237d473bb33fe8dbb139bb158c097bc913fa5ed6ec96e615bda168d16352"
  canonicalRequest = auth.constructCanonicalRequest(tokenReqInfo)
  m.assertEqual(canonicalRequest, expected_canonicalRequest)

End Function


'@Test getAbsolutePath unit tests
Function tubiAuth_getAbsolutePath_test()

  auth = m.auth
  url = "https://account.staging-public.tubi.io/device/anonymous/token"
  expected_absolutePath = "/device/anonymous/token"
  absolutePath = auth.getAbsolutePath(url)
  m.assertEqual(absolutePath, expected_absolutePath)

End Function


'@Test constructCanonicalQueryString unit tests
Function tubiAuth_constructCanonicalQueryString_test()

  auth = m.auth
  params = {
    "userId": "12345"
    "platform": "roku"
  }
  expected_queryString = "platform=roku&userId=12345"
  queryString = auth.constructCanonicalQueryString(params)
  m.assertEqual(queryString, expected_queryString)

End Function


'@Test constructCanonicalHeaders unit tests
Function tubiAuth_constructCanonicalHeaders_test()

  auth = m.auth
  headers = {
    "Accept-Language": "en-US"
    "Content-Type": "application/json"
    "x-client-platform": "roku"
    "x-client-version": "2.16.0"
  }
  expected_CanonicalHeaders = "accept-language:en-US" + chr(10) + "content-type:application/json" + chr(10) + "x-client-platform:roku" + chr(10) + "x-client-version:2.16.0" + chr(10)
  canonicalHeaders = auth.constructCanonicalHeaders(headers)
  m.assertEqual(canonicalHeaders, expected_CanonicalHeaders)

End Function


'@Test constructSignedHeaders unit tests
Function tubiAuth_constructSignedHeaders_test()

  auth = m.auth
  headers = {
    "Accept-Language": "en-US"
    "Content-Type": "application/json"
    "x-client-platform": "roku"
    "x-client-version": "2.16.0"
  }
  expected_SignedHeaders = "accept-language;content-type;x-client-platform;x-client-version"
  signedHeaders = auth.constructSignedHeaders(headers)
  m.assertEqual(signedHeaders, expected_SignedHeaders)

End Function


'@Test constructHashedPayload unit tests
Function tubiAuth_constructHashedPayload_test()

  auth = m.auth
  body = {
    "device_id":"5d9bb3b3-dfab-50af-a65e-28d25ca4d32b",
    "id":"419f8a8e-b1aa-4763-ac4e-e451ee7358e7",
    "platform":"roku",
    "verifier":"846d141f-e75e-4414-9116-b83cda6f9e5f"
  }
  body = FormatJSON(body)
  expected_HashedPayload = "7b3e447fd60d2543df79f5af98b2fddd698c1a3f01b5a04287594f7cbab8c5be"
  hashedPayload = auth.constructHashedPayload(body)
  m.assertEqual(hashedPayload, expected_HashedPayload)

End Function


'@Test getHash unit tests
Function tubiAuth_getHash_test()

  auth = m.auth
  text = {
    "device_id":"5d9bb3b3-dfab-50af-a65e-28d25ca4d32b",
    "id":"419f8a8e-b1aa-4763-ac4e-e451ee7358e7",
    "platform":"roku",
    "verifier":"846d141f-e75e-4414-9116-b83cda6f9e5f"
  }
  body = FormatJSON(text)
  expected_hashedValue = "7b3e447fd60d2543df79f5af98b2fddd698c1a3f01b5a04287594f7cbab8c5be"
  hashedValue = auth.getHash(body)
  m.assertEqual(hashedValue, expected_hashedValue)

End Function


'@Test createStringtoSignSignature unit tests
Function tubiAuth_createStringtoSignSignature_test()

  auth = m.auth
  hashedCanonicalRequest = "ef0416b45da57e525cbf22efd414724a4ca8f63486ab7fb2e7f92eedeabac16e"
  dateTime = "2021-12-14T00:54:02Z"
  algorithm = "TUBI-HMAC-SHA256"
  expected_stringToSign = "TUBI-HMAC-SHA256" + chr(10) + "20211214T005402Z" + chr(10) + "ef0416b45da57e525cbf22efd414724a4ca8f63486ab7fb2e7f92eedeabac16e"
  stringToSign = auth.createStringtoSignSignature(hashedCanonicalRequest, dateTime, algorithm)
  m.assertEqual(stringToSign, expected_stringToSign)

End Function


'@Test calculateSignature unit tests
Function tubiAuth_calculateSignature_test()

  auth = m.auth
  stringToSign = "TUBI-HMAC-SHA256" + chr(10) + "20211214T005402Z" + chr(10) + "ef0416b45da57e525cbf22efd414724a4ca8f63486ab7fb2e7f92eedeabac16e"
  secreyKey = "E0/oUbuegEiXkHF7L7QGEA/tMS2HjybWMOb9WoKgwww="
  dateTime = "2021-12-14T00:54:02Z"
  expected_calculatedSignature = "9bc5922f61e216f800229d029c80f8dc2df63310ddfc7c15bfd342a9434262f8"
  calculatedSignature = auth.calculateSignature(stringToSign, secreyKey, dateTime)
  m.assertEqual(calculatedSignature, expected_calculatedSignature)

End Function


'@Test fetchAnonymousAuthInfo unit tests
Function tubiAuth_fetchAnonymousAuthInfo_test()

  auth = m.auth
  anonymousAuthInfo = auth.fetchAnonymousAuthInfo()
  m.assertNotInvalid(anonymousAuthInfo)

  anonAuthInfoKeys = [
    "refreshToken"
    "accessToken"
    "expireTime"
    "secretKey"
  ]
  m.assertAAHasKeys(anonymousAuthInfo, anonAuthInfoKeys)

  m.assertType(anonymousAuthInfo.refreshToken, "String")
  m.assertType(anonymousAuthInfo.accessToken, "String")
  m.assertType(anonymousAuthInfo.expireTime, "String")
  m.assertType(anonymousAuthInfo.secretKey, "String")

End Function


'@Test requestAnonymousSigningKey unit tests
Function tubiAuth_getAnonymousSigningKeyRequest_test()

  auth = m.auth
  verifier = "test"
  signingKeyReq = auth.getAnonymousSigningKeyRequest(verifier)
  m.assertNotInvalid(signingKeyReq)
  m.assertAAHasKeys(signingKeyReq, m.requestObjKeys)
  m.assertEqual(signingKeyReq.method, "POST")
  m.assertNotInvalid(signingKeyReq.body)

  expectedBodyKeys = [
    "challenge"
    "version"
    "platform"
    "device_id"
  ]
  m.assertAAHasKeys(ParseJson(signingKeyReq.body), expectedBodyKeys)

  m.assertNotInvalid(signingKeyReq.headers)
  m.assertEqual(signingKeyReq.url, m.constants.urls.account.anonymous.signingKey)

End Function


'@Test getAnonymousTokenRequest unit tests
Function tubiAuth_getAnonymousTokenRequest_test()

  verifier = "1234"
  response = {
    id: "d9bfd534-9719-48d8-9f2a-101365092b35"
    key: "E0/oUbuegEiXkHF7L7QGEA/tMS2HjybWMOb9WoKgwww="
  }

  auth = m.auth
  anonymousTokenReq = auth.getAnonymousTokenRequest(verifier, response)
  m.assertNotInvalid(anonymousTokenReq)
  m.assertAAHasKeys(anonymousTokenReq, m.requestObjKeys)

  m.assertEqual(anonymousTokenReq.method, "POST")
  m.assertNotInvalid(anonymousTokenReq.body)

  expectedBodyKeys = [
    "id"
    "verifier"
    "device_id"
    "platform"
  ]
  m.assertAAHasKeys(ParseJson(anonymousTokenReq.body), expectedBodyKeys)

  m.assertNotInvalid(anonymousTokenReq.headers)

  expectedQueryParams = [
    "X-Tubi-Algorithm"
    "X-Tubi-SignedHeaders"
    "X-Tubi-Date"
    "X-Tubi-Expires"
    "X-Tubi-Signature"
  ]
  m.assertAAHasKeys(anonymousTokenReq.params, expectedQueryParams)
  m.assertEqual(anonymousTokenReq.url, m.constants.urls.account.anonymous.token)

End Function


'@Test getAnonymousRefreshTokenRequest unit tests
Function tubiAuth_getAnonymousRefreshTokenRequest_test()

  oldAuthInfo = {
    accesstoken: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJKb2tlbiIsImRldmljZV9pZCI6IjVkOWJiM2IzLWRmYWItNTBhZi1hNjVlLTI4ZDI1Y2E0ZDMyYiIsImV4cCI6MTYzOTQ0MzMwMiwiZ2VuZXJhdGlvbiI6ImJkMDNlOGM4LWUxZTgtNGI4OS05OTcwLWEzNmIxM2NjMmU4ZiIsImlhdCI6MTYzOTQ0MzI0MiwiaXNzIjoiVHViaSBBY2NvdW50IFNlcnZpY2UiLCJqdGkiOiIycjA3aHNiMXN0bnE4ZGQzZGcwM2tmNjEiLCJuYmYiOjE2Mzk0NDMyNDIsInBsYXRmb3JtIjoicm9rdSIsInR5cGUiOjUsInV1aWQiOiI0MTlmOGE4ZS1iMWFhLTQ3NjMtYWM0ZS1lNDUxZWU3MzU4ZTcifQ.TG8vqb5p6QLK7D-h2hQ2rzC8CJa9cQjkyrzA2Jl9mi0"
    expiretime: 1639443302
    refreshtoken: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJKb2tlbiIsImRldmljZV9pZCI6IjVkOWJiM2IzLWRmYWItNTBhZi1hNjVlLTI4ZDI1Y2E0ZDMyYiIsImV4cCI6MTYzOTQ0MzU0MiwiZ2VuZXJhdGlvbiI6ImJkMDNlOGM4LWUxZTgtNGI4OS05OTcwLWEzNmIxM2NjMmU4ZiIsImlhdCI6MTYzOTQ0MzI0MiwiaXNzIjoiVHViaSBBY2NvdW50IFNlcnZpY2UiLCJqdGkiOiIycjA3aHNiMXQ1cjJrZGQzZGcwM2tmODEiLCJuYmYiOjE2Mzk0NDMyNDIsInBsYXRmb3JtIjoicm9rdSIsInR5cGUiOjYsInV1aWQiOiI0MTlmOGE4ZS1iMWFhLTQ3NjMtYWM0ZS1lNDUxZWU3MzU4ZTcifQ.Dszj_pzJ64A79BFT9CiTQXuaqc_D1IE7PY9VtxoeidM"
    secretKey: "E0/oUbuegEiXkHF7L7QGEA/tMS2HjybWMOb9WoKgwww="
  }

  auth = m.auth
  anonymousRefreshTokenReq = auth.getAnonymousRefreshTokenRequest(oldAuthInfo)
  m.assertNotInvalid(anonymousRefreshTokenReq)
  m.assertAAHasKeys(anonymousRefreshTokenReq, m.requestObjKeys)
  m.assertEqual(anonymousRefreshTokenReq.method, "POST")
  m.assertNotInvalid(anonymousRefreshTokenReq.body)
  m.assertNotInvalid(anonymousRefreshTokenReq.headers)
  m.assertEqual(anonymousRefreshTokenReq.headers.Authorization, "Bearer " + oldAuthInfo.refreshtoken)

  expectedQueryParams = [
    "X-Tubi-Algorithm"
    "X-Tubi-SignedHeaders"
    "X-Tubi-Date"
    "X-Tubi-Expires"
    "X-Tubi-Signature"
  ]
  m.assertAAHasKeys(anonymousRefreshTokenReq.params, expectedQueryParams)
  m.assertEqual(anonymousRefreshTokenReq.url, m.constants.urls.account.anonymous.refreshToken)

End Function


'@Test getSignedHeaders unit tests
Function tubiAuth_getSignedHeaders_test()
  ' test no headers
  headers = {}
  expectedSignedHeaders = ""
  signedHeaders = m.auth.getSignedHeaders(headers)
  m.assertEqual(signedHeaders, expectedSignedHeaders)

  ' test invalid headers
  headers = invalid
  expectedSignedHeaders = ""
  signedHeaders = m.auth.getSignedHeaders(headers)
  m.assertEqual(signedHeaders, expectedSignedHeaders)

  ' test headers that aren't strings
  headers = {
    "TestHeader": 12
    "TestHeader2": {"not": "valid"}
    "TestHeader3": "Ok"
  }

  expectedSignedHeadersAA = {
    "testheader": true
    "testheader3": true
  }

  signedHeaders = m.auth.getSignedHeaders(headers)
  ' signedHeaders should looks something like (with order not guaranteed):
  ' "testheader;testheader3"
  splitSignedHeaders = signedHeaders.split(";")
  m.assertEqual(splitSignedHeaders.count(), 2)
  m.assertAAHasKeys(expectedSignedHeadersAA, splitSignedHeaders)

  ' test the happy case
  headers = {
    "Content-Type": "application/json"
    "Authorization": "Bearer someString"
    "X-Tubi-Signature": "3lkajf9c"
  }
  expectedSignedHeadersAA = {
    "content-type": true
    "authorization": true
    "x-tubi-signature": true
  }

  signedHeaders = m.auth.getSignedHeaders(headers)
  ' signedHeaders should looks something like (with order not guaranteed):
  ' "content-type;authorization;x-tubi-signature"
  splitSignedHeaders = signedHeaders.split(";")
  m.assertEqual(splitSignedHeaders.count(), 3)
  m.assertAAHasKeys(expectedSignedHeadersAA, splitSignedHeaders)

  ' test a single header
  headers = {
    "Connection": "keep-alive"
  }
  expectedSignedHeaders = "connection"
  signedHeaders = m.auth.getSignedHeaders(headers)
  m.assertEqual(signedHeaders, expectedSignedHeaders)
End Function
