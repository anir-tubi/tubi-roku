Function testFormatAuth(t As Object)
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
  t.assertNotInvalid(authInfo.userId)
  t.assertEqual(authInfo.userId, serverAuthInfo.user_id.toStr())

  t.assertNotInvalid(authInfo.name)
  t.assertEqual(authInfo.name, serverAuthInfo.name)

  t.assertNotInvalid(authInfo.fn)
  t.assertEqual(authInfo.fn, serverAuthInfo.first_name)

  t.assertNotInvalid(authInfo.ln)
  t.assertEqual(authInfo.ln, serverAuthInfo.last_name)

  t.assertNotInvalid(authInfo.accessToken)
  t.assertEqual(authInfo.accessToken, serverAuthInfo.access_token)

  t.assertNotInvalid(authInfo.refreshToken)
  t.assertEqual(authInfo.refreshToken, serverAuthInfo.refresh_token)

  t.assertNotInvalid(authInfo.expireTime)
  t.assertEqual(authInfo.expireTime, expireCheck)
End Function


Function testCheckIfAuthExpired(t As Object)
  constants = getConstants()
  request = TubiRequest()
  auth = TubiAuth(constants, request)

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
  t.assertTrue(isPastExpired)


  'stub non expired authInfo
  validAuthInfo = {
    refreshToken: "123456789101112131415"
    accessToken: "1617181920212223242526"
    expireTime: future
    userId: "12345"
  }

  isFutureExpired = auth.checkIfAuthExpired(validAuthInfo)
  t.assertFalse(isFutureExpired)
End Function


Function testUpdateAuthInfo(t as Object)
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
  ' t.assertEqual(updatedAuthInfo.refreshToken, authInfo.refreshToken)
  ' t.assertEqual(updatedAuthInfo.userId, authInfo.userId)
  ''' t.assertNotEqual(updatedAuthInfo.expireTime, authInfo.expireTime)
  ' t.assertNotEqual(updatedAuthInfo.accessToken, authInfo.accessToken)
  t.assertEqual(updatedAuthInfo.expireTime, future)
  ' t.assertEqual(updatedAuthInfo.accessToken, refreshInfo.access_token)
End Function


Function testGetAuthHeaders(t as Object)
  constants = getConstants()
  request = TubiRequest()
  auth = TubiAuth(constants, request)
  token = "Some555Other666String777"
  
  authHeaders = auth.getAuthHeaders(token)
  t.assertNotInvalid(authHeaders["Content-Type"])
  t.assertEqual(authHeaders["Content-Type"], "application/json")
  t.assertNotInvalid(authHeaders["Authorization"])
  t.assertEqual(authHeaders["Authorization"], "Bearer " + token)
End Function


Function testSaveAuthInfo(t as Object)
  constants = getConstants()
  request = TubiRequest()
  auth = TubiAuth(constants, request)
  auth.authRegKey = "testauth"

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
  
  savedAuthInfo = RegReadAll(auth.authRegKey)

  t.assertNotInvalid(authInfo1)
  t.assertInvalid(authInfo2)
  t.assertInvalid(authInfo3)
  t.assertInvalid(authInfo4)
  t.assertInvalid(authInfo5)
  t.assertInvalid(authInfo6)

  t.assertEqual(savedAuthInfo.expireTime, authInfo1.expireTime)
  t.assertEqual(savedAuthInfo.accessToken, authInfo1.accessToken)
  t.assertEqual(savedAuthInfo.refreshToken, authInfo1.refreshToken)
  t.assertEqual(savedAuthInfo.userId, authInfo1.userId)

  authSection = CreateObject("roRegistry")
  authSection.delete(auth.authRegKey)
  authSection.flush()
End Function


Function testDeleteAuthInfo(t as Object)
  constants = getConstants()
  request = TubiRequest()
  auth = TubiAuth(constants, request)
  auth.authRegKey = "testauth"

  authInfo = {
    expireTime: "123456"
    accessToken: "Some555Other666String777"
    refreshToken: "Some111Refresh999String000"
    userId: "6735"
  }

  for each a in authInfo
    RegWrite(a, authInfo[a], auth.authRegKey)
  end for

  auth.deleteAuthInfo()

  deletedAuthInfo = RegReadAll(auth.authRegKey)

  authInfoStillExists = false
  if deletedAuthInfo.count() > 0 
    authInfoStillExists = true
  end if

  t.assertFalse(authInfoStillExists)
End Function


Function testRequestTokenRefresh(t as Object)
  constants = getConstants()
  request = TubiRequest()
  auth = TubiAuth(constants, request)
  auth.constants.urls.users.refreshToken = "http://127.0.0.1:65535/"

  server = createMetadataFetchTaskServer(65535)
  msgPort = CreateObject("roMessagePort")
  server.SetMessagePort(msgPort)

  savedAuthInfo = {
    expireTime: 123456
    accessToken: "Some555Other666String777"
    refreshToken: "Some111Refresh999String000"
    userId: "6735"
  }

  authRequest = auth.requestTokenRefresh(savedAuthInfo, msgPort)

  t.assertNotInvalid(authRequest)
  t.assertNotInvalid(authRequest.isHttps)
  t.assertNotInvalid(authRequest.url)
  t.assertEqual(authRequest.url, auth.constants.urls.users.refreshToken)
  t.assertNotInvalid(authRequest.method)
  t.assertEqual(authRequest.method, "POST")
End Function


Function testHandleRefreshResponse(t as Object)
  constants = getConstants()
  requestObj = TubiRequest()
  auth = TubiAuth(constants, requestObj)
  url = "http://127.0.0.1:65535/"

  server = createMetadataFetchTaskServer(65535)
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

  t.assertNotInvalid(newAccess)
  t.assertNotInvalid(newAccess.user_id)
  t.assertEqual(newAccess.user_id, mockServerInfo.user_id)
  t.assertNotInvalid(newAccess.access_token)
  t.assertEqual(newAccess.access_token, mockServerInfo.access_token)
  t.assertNotInvalid(newAccess.expires_in)
  t.assertEqual(newAccess.expires_in, mockServerInfo.expires_in)
End Function


Function testCreateAuthRequest(t as Object)
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


  authRequest = auth.createAuthRequest(url, "goodAuthRequest")
  t.assertNotInvalid(authRequest)
  t.assertNotInvalid(authRequest.getAuthHeaders)
  t.assertNotInvalid(authRequest.refreshAuthToken)
  t.assertNotInvalid(authRequest.updateAuthInfo)
  t.assertNotInvalid(authRequest.saveAuthInfo)
  t.assertNotInvalid(authRequest.handleRefreshResponse)
  t.assertNotInvalid(authRequest.constants)
  t.assertNotInvalid(authRequest.request)
  t.assertNotInvalid(authRequest.authInfo)

  'a bad set of authInfo... should create an invalid auth request
  auth.getAuthInfo = function()
    return {
      expireTime: 123456
      refreshToken: "Some111Refresh999String000w"
      userId: "6739"
    }
  end function

  authRequest = auth.createAuthRequest(url, "badAuthRequest")
  t.assertInvalid(authRequest)


End Function
