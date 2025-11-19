'@TestSuite [TubiAuthUpdate] Auth.brs


'@Setup
Function TubiAuthUpdateSetup()
  m.constants = getConstants()

  getGlobalAA().generalTask = {} ' Mock general task
  m.auth = TubiAuthUpdate(m.constants)
  m.auth.authRegSection = "testauth"

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

  m.requestObjKeys = [
    "url"
    "options"
  ]
End Function


'@AfterEach
Function TubiAuthUpdateAfterEach()
  authSection = createObject("roRegistry")
  authSection.delete(m.auth.authRegSection)
  authSection.flush()
End Function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It TubiAuthUpdate
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

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

  'stub non expired authInfo
  validAuthInfo = {
    refreshToken: "123456789101112131415"
    accessToken: "1617181920212223242526"
    expireTime: present + 20
    userId: "12345"
  }
  isFutureWithOffsetExpired = auth.checkIfAuthExpired(validAuthInfo, 30)
  m.assertTrue(isFutureWithOffsetExpired)
End Function


'@Test updateAuthInfo unit tests
Function tubiAuth_updateAuthInfo_test()
  auth = m.auth

  dateTime = CreateObject("roDateTime")
  timeToNow = dateTime.AsSeconds()
  future = (timeToNow + 86400).toStr()
  refreshInfo = {
    user_id: "6735"
    expires_in: 86400
    access_token: "Some222Crazy333String444"
  }

  updatedAuthInfo = auth.updateAuthInfo(refreshInfo)
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

  auth.saveAuthInfo(authInfo1)
  savedAuthInfo = RegReadAll(auth.authRegSection)
  m.assertNotInvalid(savedAuthInfo)
  m.assertEqual(savedAuthInfo.expireTime, authInfo1.expireTime)
  m.assertEqual(savedAuthInfo.accessToken, authInfo1.accessToken)
  m.assertEqual(savedAuthInfo.refreshToken, authInfo1.refreshToken)
  m.assertEqual(savedAuthInfo.userId, authInfo1.userId)


  ' We want to test a number of scenarios where the authInfo is invalid so should maintain the existing authInfo instead of updating it. We use user id as the key we test to confirm this.
  auth.saveAuthInfo(authInfo2)
  savedAuthInfo = RegReadAll(auth.authRegSection)
  m.assertEqual(savedAuthInfo.userId, authInfo1.userId)

  auth.saveAuthInfo(authInfo3)
  savedAuthInfo = RegReadAll(auth.authRegSection)
  m.assertEqual(savedAuthInfo.userId, authInfo1.userId)

  auth.saveAuthInfo(authInfo4)
  savedAuthInfo = RegReadAll(auth.authRegSection)
  m.assertEqual(savedAuthInfo.userId, authInfo1.userId)

  auth.saveAuthInfo(authInfo5)
  savedAuthInfo = RegReadAll(auth.authRegSection)
  m.assertEqual(savedAuthInfo.userId, authInfo1.userId)
End Function


'@Test deleteAuthInfo unit tests
Function tubiAuth_deleteAuthInfo_test()
  auth = m.auth
  authInfo = m.oldAuthInfo

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
  dateTime = createObject("roDateTime")
  timeInSecs = dateTime.asSeconds() + 100
  authInfo = {
    expireTime: timeInSecs.toStr()
    accessToken: "Some555Other666String777"
    refreshToken: "Some111Refresh999String000"
    userId: "6735"
  }

  ' save auth info as a precursor to the test - updateAuthInfo() expects an authInfo to exist
  ' in the registry. To be deleted at end of this test function.
  auth.saveAuthInfo(authInfo)

  auth.updateAuthInfoWithAge(hasAge)
  savedAuthInfo = auth.getAuthInfo()

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
  auth.updateAuthInfoWithAge(hasAge)
  savedAuthInfo = auth.getAuthInfo()
  m.assertInvalid(savedAuthInfo.hasAge)
End Function


'@Test createSignature unit tests
Function tubiAuth_createSignature_test()
  auth = m.auth
  dateTime = "2021-12-13T22:27:04Z"

  sampleBody = {
    "device_id": "5d9bb3b3-dfab-50af-a65e-28d25ca4d32b",
    "id": "419f8a8e-b1aa-4763-ac4e-e451ee7358e7",
    "platform": "roku",
    "verifier": "846d141f-e75e-4414-9116-b83cda6f9e5f"
  }
  bodyJson = FormatJson(sampleBody)

  headers = {
    "Accept-Language": "en-US"
    "Content-Type": "application/json"
    "x-client-platform": "roku"
    "x-client-version": "2.16.0"
  }

  tokenReqInfo = {
    url: "https://account.staging-public.tubi.io/device/anonymous/token"
    options: {
      body: bodyJson
      headers: headers
      method: "POST"
    }
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
    "device_id": "5d9bb3b3-dfab-50af-a65e-28d25ca4d32b",
    "id": "daa3a5ee-d410-414a-8512-20cfe550468b",
    "platform": "roku",
    "verifier": "846d141f-e75e-4414-9116-b83cda6f9e5f"
  }
  bodyJson = formatJson(sampleBody)

  headers = {
    "Accept-Language": "en-US"
    "Content-Type": "application/json"
    "x-client-platform": "roku"
    "x-client-version": "2.16.0"
  }

  tokenReqInfo = {
    url: "https://account.staging-public.tubi.io/device/anonymous/token"
    options: {
      method: "POST"
      body: bodyJson
      headers: headers
    }
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
    "device_id": "5d9bb3b3-dfab-50af-a65e-28d25ca4d32b",
    "id": "419f8a8e-b1aa-4763-ac4e-e451ee7358e7",
    "platform": "roku",
    "verifier": "846d141f-e75e-4414-9116-b83cda6f9e5f"
  }
  body = formatJSON(body)
  expected_HashedPayload = "7b3e447fd60d2543df79f5af98b2fddd698c1a3f01b5a04287594f7cbab8c5be"
  hashedPayload = auth.constructHashedPayload(body)
  m.assertEqual(hashedPayload, expected_HashedPayload)
End Function


'@Test getHash unit tests
Function tubiAuth_getHash_test()
  auth = m.auth
  text = {
    "device_id": "5d9bb3b3-dfab-50af-a65e-28d25ca4d32b",
    "id": "419f8a8e-b1aa-4763-ac4e-e451ee7358e7",
    "platform": "roku",
    "verifier": "846d141f-e75e-4414-9116-b83cda6f9e5f"
  }
  body = formatJSON(text)
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


'@Test getAnonymousSigningKeyRequestInfo unit tests
Function tubiAuth_getAnonymousSigningKeyRequestInfo_test()
  auth = m.auth
  verifier = "test"
  anonymousSigningKeyReqInfo = auth.getAnonymousSigningKeyRequestInfo(verifier)
  m.assertNotInvalid(anonymousSigningKeyReqInfo)
  m.assertAAHasKeys(anonymousSigningKeyReqInfo, m.requestObjKeys)

  m.assertEqual(anonymousSigningKeyReqInfo.url, m.constants.urls.account.anonymousSigningKey)

  options = anonymousSigningKeyReqInfo.options
  m.assertEqual(options.method, "POST")
  m.assertNotInvalid(options.body)

  expectedBodyKeys = [
    "challenge"
    "version"
    "platform"
    "device_id"
  ]
  m.assertAAHasKeys(ParseJson(options.body), expectedBodyKeys)

  m.assertNotInvalid(options.headers)
End Function


'@Test getAnonymousTokenRequestInfo unit tests
Function tubiAuth_getAnonymousTokenRequestInfo_test()
  verifier = "1234"
  response = {
    id: "d9bfd534-9719-48d8-9f2a-101365092b35"
    key: "E0/oUbuegEiXkHF7L7QGEA/tMS2HjybWMOb9WoKgwww="
  }

  auth = m.auth
  tokenReqInfo = auth.getAnonymousTokenRequestInfo(verifier, response)
  m.assertNotInvalid(tokenReqInfo)
  m.assertAAHasKeys(tokenReqInfo, m.requestObjKeys)

  m.assertEqual(tokenReqInfo.url, m.constants.urls.account.anonymousToken)

  options = tokenReqInfo.options
  m.assertEqual(options.method, "POST")
  m.assertNotInvalid(options.body)

  expectedBodyKeys = [
    "id"
    "verifier"
    "device_id"
    "platform"
  ]
  m.assertAAHasKeys(ParseJson(options.body), expectedBodyKeys)

  m.assertNotInvalid(options.headers)

  expectedQueryParams = [
    "X-Tubi-Algorithm"
    "X-Tubi-SignedHeaders"
    "X-Tubi-Date"
    "X-Tubi-Expires"
    "X-Tubi-Signature"
  ]
  m.assertAAHasKeys(options.params, expectedQueryParams)
End Function


'@Test getAnonymousRefreshTokenRequestInfo unit tests
Function tubiAuth_getAnonymousRefreshTokenRequestInfo_test()
  oldAuthInfo = {
    accesstoken: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJKb2tlbiIsImRldmljZV9pZCI6IjVkOWJiM2IzLWRmYWItNTBhZi1hNjVlLTI4ZDI1Y2E0ZDMyYiIsImV4cCI6MTYzOTQ0MzMwMiwiZ2VuZXJhdGlvbiI6ImJkMDNlOGM4LWUxZTgtNGI4OS05OTcwLWEzNmIxM2NjMmU4ZiIsImlhdCI6MTYzOTQ0MzI0MiwiaXNzIjoiVHViaSBBY2NvdW50IFNlcnZpY2UiLCJqdGkiOiIycjA3aHNiMXN0bnE4ZGQzZGcwM2tmNjEiLCJuYmYiOjE2Mzk0NDMyNDIsInBsYXRmb3JtIjoicm9rdSIsInR5cGUiOjUsInV1aWQiOiI0MTlmOGE4ZS1iMWFhLTQ3NjMtYWM0ZS1lNDUxZWU3MzU4ZTcifQ.TG8vqb5p6QLK7D-h2hQ2rzC8CJa9cQjkyrzA2Jl9mi0"
    expiretime: 1639443302
    refreshtoken: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJKb2tlbiIsImRldmljZV9pZCI6IjVkOWJiM2IzLWRmYWItNTBhZi1hNjVlLTI4ZDI1Y2E0ZDMyYiIsImV4cCI6MTYzOTQ0MzU0MiwiZ2VuZXJhdGlvbiI6ImJkMDNlOGM4LWUxZTgtNGI4OS05OTcwLWEzNmIxM2NjMmU4ZiIsImlhdCI6MTYzOTQ0MzI0MiwiaXNzIjoiVHViaSBBY2NvdW50IFNlcnZpY2UiLCJqdGkiOiIycjA3aHNiMXQ1cjJrZGQzZGcwM2tmODEiLCJuYmYiOjE2Mzk0NDMyNDIsInBsYXRmb3JtIjoicm9rdSIsInR5cGUiOjYsInV1aWQiOiI0MTlmOGE4ZS1iMWFhLTQ3NjMtYWM0ZS1lNDUxZWU3MzU4ZTcifQ.Dszj_pzJ64A79BFT9CiTQXuaqc_D1IE7PY9VtxoeidM"
    secretKey: "E0/oUbuegEiXkHF7L7QGEA/tMS2HjybWMOb9WoKgwww="
  }

  auth = m.auth
  tokenReqInfo = auth.getAnonymousRefreshTokenRequestInfo(oldAuthInfo)
  m.assertNotInvalid(tokenReqInfo)
  m.assertAAHasKeys(tokenReqInfo, [
    "url"
    "options"
  ])

  m.assertEqual(tokenReqInfo.url, m.constants.urls.account.anonymousRefreshToken)

  options = tokenReqInfo.options
  m.assertEqual(options.method, "POST")
  m.assertNotInvalid(options.body)
  m.assertNotInvalid(options.headers)
  m.assertEqual(options.headers.Authorization, "Bearer " + oldAuthInfo.refreshtoken)

  expectedQueryParams = [
    "X-Tubi-Algorithm"
    "X-Tubi-SignedHeaders"
    "X-Tubi-Date"
    "X-Tubi-Expires"
    "X-Tubi-Signature"
  ]
  m.assertAAHasKeys(options.params, expectedQueryParams)
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
    "TestHeader2": { "not": "valid" }
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


'@Test setAuthInfo unit tests
Function tubiAuth_setAuthInfo_test()
  auth = m.auth

  keyValue3 = { "userId": "somebody" }
  auth.setAuthInfo(keyValue3.keys()[0], keyValue3.userId)
  savedAuthInfo = RegReadAll(auth.authRegSection)
  m.assertNotInvalid(savedAuthInfo)
  m.assertEqual(savedAuthInfo.userId, keyValue3.userId)


  keyValue4 = { userId: true }
  auth.setAuthInfo(keyValue4.keys()[0], keyValue4.userId)
  savedAuthInfo = RegReadAll(auth.authRegSection)
  m.assertNotInvalid(savedAuthInfo)
  m.assertNotEqual(savedAuthInfo.userId, keyValue4.userId)
  m.assertEqual(savedAuthInfo.userId, keyValue3.userId)
End Function
