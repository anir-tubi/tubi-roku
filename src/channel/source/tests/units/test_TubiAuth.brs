Function TestSuite_TubiAuth()
  this = BaseTestSuite()
  this.Name = "TubiAuthTestSuite"
  this.addTest("formatAuthInfoFromServer", testCase_tubiAuth_formatAuthInfoFromServer)
  this.addTest("checkIfAuthExpired", testCase_tubiAuth_checkIfAuthExpired)
  this.addTest("updateAuthInfo", testCase_tubiAuth_updateAuthInfo)
  this.addTest("getAuthHeaders", testCase_tubiAuth_getAuthHeaders)
  this.addTest("saveAuthInfo", testCase_tubiAuth_saveAuthInfo)
  this.addTest("deleteAuthInfo", testCase_tubiAuth_deleteAuthInfo)
  this.addTest("requestTokenRefresh", testCase_tubiAuth_requestTokenRefresh)
  this.addTest("testRequestTokenTransfer", testCase_tubiAuth_requestTokenTransfer)
  this.addTest("handleRefreshResponse", testCase_tubiAuth_handleRefreshResponse)
  this.addTest("handleRefreshResponse_403", testCase_tubiAuth_handleRefreshResponse_403)
  this.addTest("refreshAuthtoken", testCase_tubiAuth_refreshAuthToken)
  this.addTest("refreshAuthtoken_failed", testCase_tubiAuth_refreshAuthToken_failed)
  this.addTest("refreshAuthtoken_403", testCase_tubiAuth_refreshAuthToken_403)
  this.addTest("transferRefreshToken", testCase_tubiAuth_transferRefreshToken)
  this.addTest("transferRefreshToken_failed", testCase_tubiAuth_transferRefreshToken_failed)
  this.addTest("transferRefreshToken_403", testCase_tubiAuth_transferRefreshToken_403)
  this.addTest("getFirstVisit", testCase_tubiAuth_getFirstVisit)
  this.addTest("setFirstVisit", testCase_tubiAuth_setFirstVisit)
  this.addTest("getKidsMode", testCase_tubiAuth_getKidsMode)
  this.addTest("getDefaultKidsMode", testCase_tubiAuth_getDefaultKidsMode)
  this.addTest("setKidsMode", testCase_tubiAuth_setKidsMode)
  return this
End Function

Function testCase_tubiAuth_refreshAuthToken()
  constants = getConstants()
  request = TubiRequest()
  auth = TubiAuth(constants, request)
  oldAuthInfo = {
    expireTime: 123456
    accessToken: "Some555Other666String777"
    refreshToken: "Some111Refresh999String000"
    userId: "6735"
  }
  result = ""
  ' mocks
  auth.requestTokenRefresh = Function(authInfo, authPort)
    return {} ' passes through to handleRefreshResponse so it can be anything but invalid
  End Function

  auth.handleRefreshResponse = Function(msg, refreshReq)
    return {
      access_token: "AABBCCDD"
      refresh_token: "AABBCCDD"
      expires_in: 86400
      user_id: "6735"
    }
  End Function

  newAuthInfo = auth.refreshAuthToken(oldAuthInfo, 1)
  result += m.AssertNotInvalid(newAuthInfo.accessToken)
  result += m.AssertNotInvalid(newAuthInfo.refreshtoken)
  return result
End Function


Function testCase_tubiAuth_refreshAuthToken_failed()
  constants = getConstants()
  request = TubiRequest()
  auth = TubiAuth(constants, request)
  oldAuthInfo = {
    expireTime: 123456
    accessToken: "Some555Other666String777"
    refreshToken: "Some111Refresh999String000"
    userId: "6735"
  }
  result = ""
  ' mocks
  auth.requestTokenRefresh = Function(authInfo, authPort)
    return {} ' passes through to handleRefreshResponse so it can be anything but invalid
  End Function

  auth.handleRefreshResponse = Function(msg, refreshReq)
    return invalid
  End Function

  newAuthInfo = auth.refreshAuthToken(oldAuthInfo, 1)
  return m.AssertInvalid(newAuthInfo)
End Function

Function testCase_tubiAuth_refreshAuthToken_403()
  constants = getConstants()
  request = TubiRequest()
  auth = TubiAuth(constants, request)
  oldAuthInfo = {
    expireTime: 123456
    accessToken: "Some555Other666String777"
    refreshToken: "Some111Refresh999String000"
    userId: "6735"
  }
  auth.saveAuthInfo(oldAuthInfo)  ' save it to the registry to verify clearing
  result = ""
  ' mocks
  auth.requestTokenRefresh = Function(authInfo, authPort)
    return {} ' passes through to handleRefreshResponse so it can be anything but invalid
  End Function

  auth.handleRefreshResponse = Function(msg, refreshReq)
    return {} ' indicative of the old tokens being invalid and shoule not be stored
  End Function

  savedAuthInfo = RegReadAll(auth.authRegSection)
  result += m.AssertNotInvalid(savedAuthInfo)
  result += m.AssertNotInvalid(savedAuthInfo.accessToken)
  result += m.AssertNotInvalid(savedAuthInfo.refreshToken)
  newAuthInfo = auth.refreshAuthToken(oldAuthInfo, 1)
  result += m.AssertInvalid(newAuthInfo)
  result += m.AssertInvalid(newAuthInfo)
  savedAuthInfo = RegReadAll(auth.authRegSection)
  result += m.AssertNotInvalid(savedAuthInfo)
  result += m.AssertInvalid(savedAuthInfo.accessToken)
  result += m.AssertInvalid(savedAuthInfo.refreshToken)
  return result
End Function

Function testCase_tubiAuth_formatAuthInfoFromServer()
  constants = getConstants()
  request = TubiRequest()
  auth = TubiAuth(constants, request)

  'stub auth info from server after registration
  'some APIs return "name", others return "first_name" and "last_name"
  'we don't save facebook id or email in the registry
  serverAuthInfo = {
    user_id: 654722
    facebook_id: invalid,
    email: "generic@email.com"
    name: "somebody"
    first_name: "somebody"
    last_name: "special"
    access_token: "abcdefgHIJKKV1QiLCJhbGciOiJIUzI1NiJ9"
    refresh_token: "LMNOPquestuvJKV1QiLCJhbGciOiJIUzI1NiJ9"
    expires_in: 1209600
  }

  dateTime = CreateObject("roDateTime")
  timeToNow = dateTime.AsSeconds()
  expireCheck = (serverAuthInfo.expires_in + timeToNow).toStr()
  authInfo = auth.formatAuthInfoFromServer(serverAuthInfo)
  result = ""
  result += m.assertNotInvalid(authInfo.userId)
  result += m.assertEqual(authInfo.userId, serverAuthInfo.user_id.toStr())
  result += m.assertNotInvalid(authInfo.name)
  result += m.assertEqual(authInfo.name, serverAuthInfo.name)
  result += m.assertNotInvalid(authInfo.fn)
  result += m.assertEqual(authInfo.fn, serverAuthInfo.first_name)
  result += m.assertNotInvalid(authInfo.ln)
  result += m.assertEqual(authInfo.ln, serverAuthInfo.last_name)
  result += m.assertNotInvalid(authInfo.accessToken)
  result += m.assertEqual(authInfo.accessToken, serverAuthInfo.access_token)
  result += m.assertNotInvalid(authInfo.refreshToken)
  result += m.assertEqual(authInfo.refreshToken, serverAuthInfo.refresh_token)
  result += m.assertNotInvalid(authInfo.expireTime)
  result += m.assertEqual(authInfo.expireTime, expireCheck)
  return result
End Function

Function testCase_tubiAuth_checkIfAuthExpired()
  constants = getConstants()
  request = TubiRequest()
  auth = TubiAuth(constants, request)
  clock = CreateObject("roDateTime")
  present = clock.AsSeconds()
  past = present - 30000
  future = present + 30000
  result = ""

  'stub expired authInfo
  expiredAuthInfo = {
    refreshToken: "123456789101112131415"
    accessToken: "1617181920212223242526"
    expireTime: past
    userId: "12345"
  }
  isPastExpired = auth.checkIfAuthExpired(expiredAuthInfo)
  result += m.assertTrue(isPastExpired)

  'stub non expired authInfo
  validAuthInfo = {
    refreshToken: "123456789101112131415"
    accessToken: "1617181920212223242526"
    expireTime: future
    userId: "12345"
  }
  isFutureExpired = auth.checkIfAuthExpired(validAuthInfo)
  result += m.assertFalse(isFutureExpired)
  return result
End Function

Function testCase_tubiAuth_updateAuthInfo()
  constants = getConstants()
  request = TubiRequest()
  auth = TubiAuth(constants, request)
  dateTime = CreateObject("roDateTime")
  timeToNow = dateTime.AsSeconds()
  future = (timeToNow + 86400).toStr()
  refreshInfo = {
    user_id: "6735"
    expires_in: 86400
    access_token: "Some222Crazy333String444"
  }
  authInfo = {
    expireTime: 123456
    accessToken: "Some555Other666String777"
    refreshToken: "Some111Refresh999String000"
    userId: "6735"
  }

  updatedAuthInfo = auth.updateAuthInfo(refreshInfo, authInfo)
  result = ""
  ' m.assertEqual(updatedAuthInfo.refreshToken, authInfo.refreshToken)
  ' m.assertEqual(updatedAuthInfo.userId, authInfo.userId)
  ''' m.assertNotEqual(updatedAuthInfo.expireTime, authInfo.expireTime)
  ' m.assertNotEqual(updatedAuthInfo.accessToken, authInfo.accessToken)
  result += m.assertEqual(updatedAuthInfo.expireTime, future)
  ' m.assertEqual(updatedAuthInfo.accessToken, refreshInfo.access_token)
  return result
End Function

Function testCase_tubiAuth_getAuthHeaders()
  constants = getConstants()
  request = TubiRequest()
  auth = TubiAuth(constants, request)
  token = "Some555Other666String777"
  result = ""
  authHeaders = auth.getAuthHeaders(token)
  result += m.assertNotInvalid(authHeaders["Content-Type"])
  result += m.assertEqual(authHeaders["Content-Type"], "application/json")
  result += m.assertNotInvalid(authHeaders["Authorization"])
  result += m.assertEqual(authHeaders["Authorization"], "Bearer " + token)
  return result
End Function

Function testCase_tubiAuth_saveAuthInfo()
  constants = getConstants()
  request = TubiRequest()
  auth = TubiAuth(constants, request)
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
  result = ""

  authInfo1 = auth.saveAuthInfo(authInfo1) 
  authInfo2 = auth.saveAuthInfo(authInfo2) 'invalid?
  authInfo3 = auth.saveAuthInfo(authInfo3) 'invalid?
  authInfo4 = auth.saveAuthInfo(authInfo4) 'invalid?
  authInfo5 = auth.saveAuthInfo(authInfo5) 'invalid?
  authInfo6 = auth.saveAuthInfo(authInfo6) 'invalid?
  savedAuthInfo = RegReadAll(auth.authRegSection)
  result += m.assertNotInvalid(authInfo1)
  result += m.assertInvalid(authInfo2)
  result += m.assertInvalid(authInfo3)
  result += m.assertInvalid(authInfo4)
  result += m.assertInvalid(authInfo5)
  result += m.assertInvalid(authInfo6)
  result += m.assertEqual(savedAuthInfo.expireTime, authInfo1.expireTime)
  result += m.assertEqual(savedAuthInfo.accessToken, authInfo1.accessToken)
  result += m.assertEqual(savedAuthInfo.refreshToken, authInfo1.refreshToken)
  result += m.assertEqual(savedAuthInfo.userId, authInfo1.userId)
  authSection = CreateObject("roRegistry")
  authSection.delete(auth.authRegSection)
  authSection.flush()
  return result
End Function

Function testCase_tubiAuth_deleteAuthInfo()
  constants = getConstants()
  request = TubiRequest()
  auth = TubiAuth(constants, request)
  auth.authRegSection = "testauth"
  authInfo = {
    expireTime: "123456"
    accessToken: "Some555Other666String777"
    refreshToken: "Some111Refresh999String000"
    userId: "6735"
  }
  result = ""

  for each a in authInfo
    RegWrite(a, authInfo[a], auth.authRegSection)
  end for
  auth.deleteAuthInfo()
  deletedAuthInfo = RegReadAll(auth.authRegSection)
  authInfoStillExists = false
  if deletedAuthInfo.count() > 0 
    authInfoStillExists = true
  end if
  result += m.assertFalse(authInfoStillExists)
  return result
End Function


Function testCase_tubiAuth_requestTokenRefresh()
  constants = getConstants()
  request = TubiRequest()
  auth = TubiAuth(constants, request)
  auth.constants.urls.users.refreshToken = "http://127.0.0.1:65535/"
  savedAuthInfo = {
    expireTime: 123456
    accessToken: "Some555Other666String777"
    refreshToken: "Some111Refresh999String000"
    userId: "6735"
  }
  result = ""

  server = testHelper_tubiAuth_createMetadataFetchTaskServer(65535)
  msgPort = CreateObject("roMessagePort")
  server.SetMessagePort(msgPort)
  authRequest = auth.requestTokenRefresh(savedAuthInfo, msgPort)
  result += m.assertNotInvalid(authRequest)
  result += m.assertNotInvalid(authRequest.isHttps)
  result += m.assertNotInvalid(authRequest.url)
  result += m.assertEqual(authRequest.url, auth.constants.urls.users.refreshToken)
  result += m.assertNotInvalid(authRequest.method)
  result += m.assertEqual(authRequest.method, "POST")
  return result
End Function

Function testCase_tubiAuth_requestTokenTransfer()
  constants = getConstants()
  request = TubiRequest()
  auth = TubiAuth(constants, request)
  auth.constants.urls.users.transferToken = "http://127.0.0.1:65535/"
  externalAuthInfo = {
    platform: "iphone"
    externalDeviceId: "Some555Other666String777"
    externalRefreshToken: "Some111Refresh999String000"
    userId: "6735"
  }
  result = ""

  server = testHelper_tubiAuth_createMetadataFetchTaskServer(65535)
  msgPort = CreateObject("roMessagePort")
  server.SetMessagePort(msgPort)
  authRequest = auth.requestTokenTransfer(externalAuthInfo, msgPort)
  result += m.assertNotInvalid(authRequest)
  result += m.assertNotInvalid(authRequest.isHttps)
  result += m.assertNotInvalid(authRequest.url)
  result += m.assertEqual(authRequest.url, auth.constants.urls.users.transferToken)
  result += m.assertNotInvalid(authRequest.method)
  result += m.assertEqual(authRequest.method, "POST")
  return result
End Function


Function testCase_tubiAuth_handleRefreshResponse()
  constants = getConstants()
  requestObj = TubiRequest()
  auth = TubiAuth(constants, requestObj)
  url = "http://127.0.0.1:65535/"
  server = testHelper_tubiAuth_createMetadataFetchTaskServer(65535)
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
  result = ""

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
  result += m.assertNotInvalid(newAccess)
  result += m.assertNotInvalid(newAccess.user_id)
  result += m.assertEqual(newAccess.user_id, mockServerInfo.user_id)
  result += m.assertNotInvalid(newAccess.access_token)
  result += m.assertEqual(newAccess.access_token, mockServerInfo.access_token)
  result += m.assertNotInvalid(newAccess.expires_in)
  result += m.assertEqual(newAccess.expires_in, mockServerInfo.expires_in)
  return result
End Function

Function testCase_tubiAuth_handleRefreshResponse_403()
  constants = getConstants()
  requestObj = TubiRequest()
  auth = TubiAuth(constants, requestObj)
  url = "http://127.0.0.1:65535/"
  server = testHelper_tubiAuth_createMetadataFetchTaskServer(65535)
  msgPort = CreateObject("roMessagePort")
  server.SetMessagePort(msgPort)
  request = requestObj.createAsync(url, "fakeRequest", {})
  isReqStarted = request.start(msgPort)
  newAccess = invalid
  result = ""

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
  result += m.assertNotInvalid(newAccess)
  result += m.assertInvalid(newAccess.user_id)
  result += m.assertInvalid(newAccess.access_token)
  result += m.assertInvalid(newAccess.refresh_token)
  result += m.assertInvalid(newAccess.expires_in)
  return result
End Function

Function testCase_tubiAuth_createAuthRequest()
  constants = getConstants()
  requestObj = TubiRequest()
  auth = TubiAuth(constants, requestObj)
  url = "https://somefakeurl.com"
  'a good set of authInfo... should create a valid auth request
  auth.getAuthInfo = function()
    return {
      expireTime: 123456
      accessToken: "Some555Other666String777d"
      refreshToken: "Some111Refresh999String000w"
      userId: "6739"
    }
  end function
  result = ""

  authRequest = auth.createAuthRequest(url, "goodAuthRequest")
  result += m.assertNotInvalid(authRequest)
  result += m.assertNotInvalid(authRequest.getAuthHeaders)
  result += m.assertNotInvalid(authRequest.refreshAuthToken)
  result += m.assertNotInvalid(authRequest.updateAuthInfo)
  result += m.assertNotInvalid(authRequest.saveAuthInfo)
  result += m.assertNotInvalid(authRequest.handleRefreshResponse)
  result += m.assertNotInvalid(authRequest.constants)
  result += m.assertNotInvalid(authRequest.request)
  result += m.assertNotInvalid(authRequest.authInfo)

  'a bad set of authInfo... should create an invalid auth request
  auth.getAuthInfo = function()
    return {
      expireTime: 123456
      refreshToken: "Some111Refresh999String000w"
      userId: "6739"
    }
  end function

  authRequest = auth.createAuthRequest(url, "badAuthRequest")
  result += m.assertInvalid(authRequest)
  return result
End Function


'**********************
' transferRefreshToken
'**********************

Function testCase_tubiAuth_transferRefreshToken()
  constants = getConstants()
  request = TubiRequest()
  auth = TubiAuth(constants, request)
  externalAuthInfo = {
    platform: "ios"
    externalDeviceId: "AABBCCDD"
    externalRefreshToken: "Some111Refresh999String000"
    userId: "6735"
  }
  result = ""
  ' mocks
  auth.requestTokenRefresh = Function(authInfo, authPort)
    return {} ' passes through to handleRefreshResponse so it can be anything but invalid
  End Function

  auth.handleRefreshResponse = Function(msg, refreshReq)
    return {
      access_token: "AABBCCDD"
      refresh_token: "AABBCCDD"
      expires_in: 86400
      user_id: "6735"
    }
  End Function

  auth.requestTokenTransfer = Function(externalAuthInfo, authPort)
    return {}
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
  result += m.AssertNotInvalid(newAuthInfo)
  result += m.AssertNotInvalid(newAuthInfo.accessToken)
  result += m.AssertNotInvalid(newAuthInfo.refreshtoken)
  return result
End Function

Function testCase_tubiAuth_transferRefreshToken_failed()
  constants = getConstants()
  request = TubiRequest()
  auth = TubiAuth(constants, request)
  externalAuthInfo = {
    platform: "ios"
    externalDeviceId: "AABBCCDD"
    externalRefreshToken: "Some111Refresh999String000"
    userId: "6735"
  }
  result = ""
  ' mocks
  auth.requestTokenRefresh = Function(authInfo, authPort)
    return {} ' passes through to handleRefreshResponse so it can be anything but invalid
  End Function

  auth.handleRefreshResponse = Function(msg, refreshReq)
    return invalid
  End Function

  auth.requestTokenTransfer = Function(externalAuthInfo, authPort)
    return {}
  End Function

  newAuthInfo = auth.transferRefreshToken(externalAuthInfo, 1)
  result += m.AssertInvalid(newAuthInfo)
  return result
End Function

Function testCase_tubiAuth_transferRefreshToken_403()
  constants = getConstants()
  request = TubiRequest()
  auth = TubiAuth(constants, request)
  externalAuthInfo = {
    platform: "ios"
    externalDeviceId: "AABBCCDD"
    externalRefreshToken: "Some111Refresh999String000"
    userId: "6735"
  }
  result = ""
  ' mocks
  auth.requestTokenRefresh = Function(authInfo, authPort)
    return {} ' passes through to handleRefreshResponse so it can be anything but invalid
  End Function

  auth.handleRefreshResponse = Function(msg, refreshReq)
    return {} ' indicates 403
  End Function

  auth.requestTokenTransfer = Function(externalAuthInfo, authPort)
    return {}
  End Function

  newAuthInfo = auth.transferRefreshToken(externalAuthInfo, 1)
  result += m.AssertInvalid(newAuthInfo)
  return result
End Function

Function testHelper_tubiAuth_createMetadataFetchTaskServer(tcpPort As Integer)
  server = CreateObject("roStreamSocket")
  address = CreateObject("roSocketAddress")
  address.setPort(tcpPort)
  server.setAddress(address)
  server.notifyReadable(true)
  server.listen(4)
  return server
End Function

Function testCase_tubiAuth_getFirstVisit()
  constants = getConstants()
  request = TubiRequest()
  auth = TubiAuth(constants, request)

  'use a fake section so not to disturb actual first visit info
  auth.firstVisitRegSection = "testVisit"

  'clear out any leftover info in the "testVisit" section
  auth.regDelete("firstVisit", auth.firstVisitRegSection)
  'set up a fake value that we will attempt to get
  auth.regWrite("firstVisit", "56789", auth.firstVisitRegSection)

  firstVisit = auth.getFirstVisit()
  result = m.AssertEqual(firstVisit, 56789)
  return result
End Function

Function testCase_tubiAuth_setFirstVisit()
  constants = getConstants()
  request = TubiRequest()
  auth = TubiAuth(constants, request)

  'use a fake section so not to disturb actual first visit info
  auth.firstVisitRegSection = "testVisit"

  'clear out any leftover info in the "testVisit" section
  auth.regDelete("firstVisit", auth.firstVisitRegSection)

  dateTime = CreateObject("roDateTime")
  days = Int(dateTime.AsSeconds() / 24 / 60 / 60)
  firstVisit = auth.setFirstVisit() 'should be integer
  result = m.assertEqual(firstVisit, days)

  registryFirstVisit = auth.regRead("firstVisit", auth.firstVisitRegSection)
  result += m.assertNotInvalid(registryFirstVisit)
  result += m.assertEqual(firstVisit, registryFirstVisit.toInt())
  return result
End Function


Function testCase_tubiAuth_getKidsMode()
  constants = getConstants()
  request = TubiRequest()
  auth = TubiAuth(constants, request)

  'use a fake section so not to disturb actual kidsMode info
  auth.kidsModeRegSection = "testKidsMode"

  'clear out any leftover info in the "testKidsMode" section
  auth.regDelete("kidsMode", auth.kidsModeRegSection)
  'set up a fake value that we will attempt to get

  oKidsModeInput = {kidsEnabled:true}
  auth.regWrite("kidsMode", FormatJson(oKidsModeInput), auth.kidsModeRegSection)

  kidsMode = auth.getKidsMode()
  
  result = m.assertNotInvalid(kidsMode)
  result += m.AssertEqual(kidsMode.kidsEnabled, true)
  return result
End Function

Function testCase_tubiAuth_getDefaultKidsMode()
  constants = getConstants()
  request = TubiRequest()
  auth = TubiAuth(constants, request)

  'use a fake section so not to disturb actual kidsMode info
  auth.kidsModeRegSection = "testKidsMode"

  'clear out any leftover info in the "testKidsMode" section
  auth.regDelete("kidsMode", auth.kidsModeRegSection)
  kidsMode = auth.getKidsMode() 'get kidsMode without setting it so we can get the default value
  
  result = m.assertNotInvalid(kidsMode)
  result += m.AssertEqual(kidsMode.kidsEnabled, false) '//The default value should be false.
  return result
End Function


Function testCase_tubiAuth_setKidsMode()
  constants = getConstants()
  request = TubiRequest()
  auth = TubiAuth(constants, request)

  'use a fake section so not to disturb actual kidsMode info
  auth.kidsModeRegSection = "testKidsMode"

  'clear out any leftover info in the "testKidsMode" section
  auth.regDelete("kidsMode", auth.kidsModeRegSection)

  oKidsModeInput = {kidsEnabled:true}
  auth.setKidsMode({kidsEnabled:true})

  kidsMode = auth.regRead("kidsMode", auth.kidsModeRegSection)
  result = m.assertNotInvalid(kidsMode)
  kidsMode = ParseJson(kidsMode) '//convert JSON string into an object
  result += m.AssertEqual(kidsMode.kidsEnabled, true)
  result += m.assertEqual(kidsMode.kidsEnabled, oKidsModeInput.kidsEnabled)
  return result
End Function