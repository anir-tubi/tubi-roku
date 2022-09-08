'@constants: assocArray, the constants object returned from getContstants()
'@request: assocArray, the object returned from TubiRequest()
Function TubiAuth(constants, request)
  authRegSection = "auth"
  if constants.settings.stagingApis = true then
    authRegSection = "auth_staging"
  end if

  return {
    authRegSection: authRegSection
    firstVisitRegSection: "visit"
    guestUserHasAgeRegSection: "has_age"

    constants: constants
    request: request

    'public methods
    getAuthInfoNoUpdate: tubiAuth_getAuthInfoNoUpdate
    getAuthInfo: tubiAuth_getAuthInfo
    setAuthInfo: tubiAuth_setAuthInfo
    getFirstVisit: tubiAuth_getFirstVisit
    setFirstVisit: tubiAuth_setFirstVisit
    clearFirstVisit: tubiAuth_clearFirstVisit
    handleRegistration: tubiAuth_handleRegistration
    logout: tubiAuth_deleteAuthInfo
    refreshAuthToken: tubiAuth_refreshAuthToken
    transferRefreshToken: tubiAuth_transferRefreshToken
    getAuthHeaders: tubiAuth_getAuthHeaders
    createAuthRequest: tubiAuth_createAuthRequest
    updateAuthInfoWithAge: tubiAuth_updateAuthInfoWithAge
    getGuestUserHasAgeInfo: tubiAuth_getGuestUserHasAgeInfo
    setGuestUserHasAgeInfo: tubiAuth_setGuestUserHasAgeInfo
    deleteGuestUserHasAgeInfo: tubiAuth_deleteGuestUserHasAgeInfo
    setEnableVideoPreview: tubiAuth_setEnableVideoPreview


    'private methods
    saveAuthInfo: tubiAuth_saveAuthInfo
    deleteAuthInfo: tubiAuth_deleteAuthInfo
    checkIfAuthExpired: tubiAuth_checkIfAuthExpired
    requestTokenRefresh: tubiAuth_requestTokenRefresh
    requestTokenTransfer: tubiAuth_requestTokenTransfer
    handleRefreshResponse: tubiAuth_handleRefreshResponse
    updateAuthInfo: tubiAuth_updateAuthInfo
    formatAuthInfoFromServer: tubiAuth_formatAuthInfoFromServer

    fetchAnonymousAuthInfo: tubiAuth_fetchAnonymousAuthInfo
    fetchAndSaveAnonymousAuthInfo: tubiAuth_fetchAndSaveAnonymousAuthInfo
    updateAnonymousAuthInfo: tubiAuth_updateAnonymousAuthInfo

    getAnonymousSigningKeyRequest: tubiAuth_getAnonymousSigningKeyRequest
    handleAnonymousSigningKeyResponse: tubiAuth_handleAnonymousSigningKeyResponse

    getAnonymousTokenRequest: tubiAuth_getAnonymousTokenRequest
    handleAnonymousTokenResponse: tubiAuth_handleAnonymousTokenResponse

    refreshAnonymousToken: tubiAuth_refreshAnonymousToken
    getAnonymousRefreshTokenRequest: tubiAuth_getAnonymousRefreshTokenRequest
    handleAnonymousRefreshTokenResponse: tubiAuth_handleAnonymousRefreshTokenResponse

    createSignature: tubiAuth_createSignature
    constructCanonicalRequest: tubiAuth_constructCanonicalRequest
    getAbsolutePath: tubiAuth_getAbsolutePath
    constructCanonicalQueryString: tubiAuth_constructCanonicalQueryString
    constructCanonicalHeaders: tubiAuth_constructCanonicalHeaders
    constructSignedHeaders: tubiAuth_constructSignedHeaders
    constructHashedPayload: tubiAuth_constructHashedPayload
    getHash: tubiAuth_getHash
    createStringtoSignSignature: tubiAuth_createStringtoSignSignature
    calculateSignature: tubiAuth_calculateSignature
    getSignedHeaders: tubiAuth_getSignedHeaders

    regRead: tubiAuth_regRead
    regReadAll: tubiAuth_regReadAll
    regWrite: tubiAuth_regWrite
    regDelete: tubiAuth_regDelete
  }
End Function


'returns invalid or an assocArray that looks like the following
' For loggedIn user
'authInfo = {
'  refreshToken: someRefreshToken(String)
'  accessToken: someAccessToken(String)
'  expireTime: numberOfSecondsUntilExpires(Integer)
'  userId: userId(Integer as String)
'  firstName: firstName(String)
'  lastName: lastName(String)
'  name: name(String)
'  authType: analyticsAuthType(String)
'  hasAge: true indicates Tubi has an age on record and the age is >= 13 (Boolean)
'}
'
' For Guest user
'authInfo = {
'  refreshToken: someRefreshToken(String)
'  accessToken: someAccessToken(String)
'  expireTime: numberOfSecondsUntilExpires(Integer)
'}
' tubiAuth_getAuthInfo will try to make a roUrlTransfer if the token needs to be updated which isn't allowed on the render thread.
' This function allows accessing auth info from the render thread without this issue
Function tubiAuth_getAuthInfoNoUpdate()
  authInfo = m.regReadAll(m.authRegSection) 'returns empty assocArray if nothing in the auth registry

  firstName = authInfo.fn
  if firstName <> invalid then
    authInfo.firstName = firstName
    authInfo.delete("fn")
  end if

  lastName = authInfo.ln
  if lastName <> invalid then
    authInfo.lastName = lastName
    authInfo.delete("ln")
  end if

  if authInfo.enablevideopreview <> invalid 'convert string to boolean since authGlobal will have boolean.
    if authInfo.enablevideopreview = "false"
      authInfo.enablevideopreview = false
    else
      authInfo.enablevideopreview = true
    end if
  end if

  if authInfo.expireTime <> invalid   'used as test to determine if we have any auth info in the auth registry
    authInfo.expireTime = authInfo.expireTime.toInt()

    if isString(authInfo.hasAge) = true
      if authInfo.hasAge = "true"
        authInfo.hasAge = true
      else if authInfo.hasAge = "false"
        authInfo.hasAge = false
      end if
    end if
    return authInfo
  end if

  return authInfo  'can return invalid
End Function

' Same as getAuthInfoNoUpdate but will request a new auth token and update the registry if necessary.
' Should not be called from render thread!
Function tubiAuth_getAuthInfo()
  authInfo = m.getAuthInfoNoUpdate()

  isExpired = m.checkIfAuthExpired(authInfo)
  newAuthInfo = invalid
  if authInfo.expireTime <> invalid   'used as test to determine if we have any auth info in the auth registry
    if isExpired = true
      if authInfo.userId <> invalid
        newAuthInfo = m.refreshAuthToken(authInfo, 3) 'can return invalid
      else if isString(authInfo.secretKey) = true
        newAuthInfo = m.refreshAnonymousToken(authInfo, 3) 'can return invalid
      else
        tubiLog("AuthInfo did not have secretKey! This should not have happened: " + FormatJson(authInfo), "warn", "clientWarn", "no-secret-key")
        newAuthInfo = m.fetchAndSaveAnonymousAuthInfo() 'can return invalid
      end if
    else
      newAuthInfo = authInfo
    end if
  else
    newAuthInfo = m.fetchAndSaveAnonymousAuthInfo()
  end if

  return newAuthInfo 'can return invalid
End Function


'Saves the key value pair in registry
'@key : String, authInfo key
'@value: String, Value for the provided key
Function tubiAuth_setAuthInfo(key, value)

  if isString(key) = true and isString(value) = true
    m.regWrite(key, value, m.authRegSection)
  else
    tubiLog("Key/Value provided for SetAuthInfo Function are not Strings.", "warn")
  end if

End Function


' It refreshes the accessToken using refresh Token
' @authInfo: assocarray, contains accessToken, refreshToken, expireTime
' @timeout: integer, the max amount of time to wait for a response from the server in seconds
'
' returns authInfo = {
'  refreshToken: someRefreshToken(String)
'  accessToken: someAccessToken(String)
'  expireTime: numberOfSecondsUntilExpires(Integer)
'}
Function tubiAuth_refreshAnonymousToken(authInfo, timeout)
  newAuthInfo = invalid

  if authInfo = invalid
    newAuthInfo = m.fetchAndSaveAnonymousAuthInfo()
  else
    authPort = CreateObject("roMessagePort")
    refreshTokenReq = m.getAnonymousRefreshTokenRequest(authInfo)

    if refreshTokenReq.start(authPort) = true
      timer = CreateObject("roTimespan")
      while true
        msg = wait(100, authPort)

        newAccess = m.handleAnonymousRefreshTokenResponse(msg, refreshTokenReq)
        ' newAccess might be invalid if there was a network error other than 403
        ' in which case we don't have any new auth info to update and we don't want to
        ' delete the previous auth info.
        if newAccess <> invalid
          if newAccess.access_token <> invalid
            newAuthInfo = m.updateAnonymousAuthInfo(newAccess, authInfo)
            newAuthInfo = m.saveAuthInfo(newAuthInfo) 'returns invalid if not saved to the registry
          else
            ' Most likely in this block if receiving a 401 when attempting to refresh the anonymous token.
            ' Be careful to only do this if the service rejected auth refresh.  We don't
            ' want to delete auth info for transient errors like network down.
            m.deleteAuthInfo()
            newAuthInfo = m.fetchAndSaveAnonymousAuthInfo()
          end if
          exit while
        end if

        'wait max x secs for a response to refresh the auth token
        if timer.totalMilliseconds() > (timeout * 1000)
          exit while
        end if
      end while
    end if

  end if

  return newAuthInfo 'may return invalid

End Function


' It creates request object for refreshToken Request
' @authInfo: assocarray, contains accessToken, refreshToken, expireTime
'
' returns AnonymousRefreshToken request object in assocarray
Function tubiAuth_getAnonymousRefreshTokenRequest(authInfo)

  algorithm = m.constants.anonymous.algorithm
  dateTime = createObject("roDateTime").ToISOString()
  dateTimeFormatted = dateTime.replace("-","").replace(":","")

  headers = m.getAuthHeaders(authInfo.refreshToken)

  secretKey = authInfo.secretKey

  body = {}
  bodyJson = FormatJSON(body)

  tokenReqOptions = {
    url : m.constants.urls.account.anonymous.refreshToken
    body: bodyJson
    headers: headers
    method: m.constants.reqTypes.post
    retries: 0
  }
  signature = m.createSignature(dateTime, tokenReqOptions, secretKey, algorithm)
  signedHeaders = m.getSignedHeaders(headers)

  params = {
    "X-Tubi-Algorithm": algorithm
    "X-Tubi-SignedHeaders": signedHeaders
    "X-Tubi-Date": dateTimeFormatted
    "X-Tubi-Expires": "60"
    "X-Tubi-Signature" : signature
  }

  tokenReqOptions["params"] = params

  return m.request.createAsync(m.constants.urls.account.anonymous.refreshToken, "refreshAnonymousToken", tokenReqOptions)

End Function


Function tubiAuth_fetchAndSaveAnonymousAuthInfo()
  authInfo = m.fetchAnonymousAuthInfo()
  return m.saveAuthInfo(authInfo)
End Function


'returns invalid or an assocArray that looks like the following
'authInfo = {
'  refreshToken: someRefreshToken(String)
'  accessToken: someAccessToken(String)
'  expireTime: numberOfSecondsUntilExpires(Integer as String)
'  secretKey: someSecretKey(String)
'}
Function tubiAuth_fetchAnonymousAuthInfo()

  authInfo = invalid

  roDeviceInfo = CreateObject("roDeviceInfo")
  verifier = roDeviceInfo.GetRandomUUID()

  authPort = CreateObject("roMessagePort")
  timeout = 10
  anonymousSigningKeyReq = m.getAnonymousSigningKeyRequest(verifier)

  signingKeyResponse = invalid
  if anonymousSigningKeyReq.start(authPort) = true
    timer = CreateObject("roTimespan")
    while true
      msg = wait(100, authPort)
      signingKeyResponse = m.handleAnonymousSigningKeyResponse(msg, anonymousSigningKeyReq)
      if signingKeyResponse <> invalid
        exit while
      end if
      'wait max x secs for a response to refresh the auth token
      if timer.totalMilliseconds() > (timeout * 1000)
        exit while
      end if
    end while
  end if

  if signingKeyResponse = invalid or (signingKeyResponse.id = invalid or signingKeyResponse.key = invalid)
    return invalid
  end if

  authPort = CreateObject("roMessagePort")
  anonymousTokenReq = m.getAnonymousTokenRequest(verifier, signingKeyResponse)

  if anonymousTokenReq.start(authPort) = true
    timer = CreateObject("roTimespan")
    while true
      msg = wait(100, authPort)
      token = m.handleAnonymousTokenResponse(msg, anonymousTokenReq)
      if token <> invalid
        if token.access_token <> invalid and token.refresh_token <> invalid and token.expires_in <> invalid
          authInfo = m.formatAuthInfoFromServer(token)
          authInfo["secretKey"] = signingKeyResponse.key ' store secretKey in registry, we need it for refreshing anonymous token
        end if
        exit while
      end if
      'wait max x secs for a response to refresh the auth token
      if timer.totalMilliseconds() > (timeout * 1000)
        exit while
      end if
    end while
  end if

  return authInfo

End Function


' It creates request object for anonymous Token
' @verifier: string, random string used for anonymous token request
' @response: assocarray, signingKey response {id, key}
'
' returns request object used to fetch an anonymous token as returned by Request().createAsync()
Function tubiAuth_getAnonymousTokenRequest(verifier, response)

  id = response.id
  secretKey = response.key
  algorithm = m.constants.anonymous.algorithm

  dateTime = createObject("roDateTime").ToISOString()
  dateTimeFormatted = dateTime.replace("-","").replace(":","")

  body = {
    id: id
    verifier: verifier
    device_id: m.constants.deviceInfo.deviceId
    platform: m.constants.platform
  }
  bodyJson = FormatJSON(body)

  headers = {}
  headers.append(m.constants.headers.commonUapi)

  tokenReqInfo = {
    url : m.constants.urls.account.anonymous.token
    body: bodyJson
    headers: headers
    method: m.constants.reqTypes.post
  }
  signature = m.createSignature(dateTime, tokenReqInfo, secretKey, algorithm)
  signedHeaders = m.getSignedHeaders(headers)

  params = {
    "X-Tubi-Algorithm": algorithm
    "X-Tubi-SignedHeaders": signedHeaders
    "X-Tubi-Date": dateTimeFormatted
    "X-Tubi-Expires": "60"
    "X-Tubi-Signature" : signature
  }

  reqOptions = {
    method: m.constants.reqTypes.post
    body: bodyJson
    headers: headers
    params: params
    retries: 0
  }

  return m.request.createAsync(m.constants.urls.account.anonymous.token, "getAnonymousToken", reqOptions)
End Function


' It creates request object for anonymous signingKey
' @verifier: string, random string used for anonymous signingKey request
'
' returns request object as returned by Request().createAsync()
Function tubiAuth_getAnonymousSigningKeyRequest(verifier)

  ba1 = CreateObject("roByteArray")
  ba1.FromAsciiString(verifier)
  digest = CreateObject("roEVPDigest")
  digest.Setup("sha256")
  digest.Update(ba1)
  hash = digest.Final()

  ' base64 encode the hash
  ba2 = CreateObject("roByteArray")
  ba2.FromHexString(hash)
  challenge = ba2.ToBase64String().replace("+", "-").replace("/", "_")

  body = {
    challenge: challenge
    version: m.constants.deviceInfo.clientVersion
    platform: m.constants.platform
    device_id: m.constants.deviceInfo.deviceId
  }
  bodyJson = FormatJson(body)

  headers = {}
  headers.append(m.constants.headers.commonUapi)

  reqOptions = {
    method: m.constants.reqTypes.post
    body: bodyJson
    headers: headers
    retries: 0
  }

  return m.request.createAsync(m.constants.urls.account.anonymous.signingKey, "getAnonymousSigningKey", reqOptions)
End Function


' handles anonymous signingKey response
' @msg: roUrlEvent
' @anonymousSigningKeyReq: assocarray, a request object as returned by Request().createAsync()
'                                      and used to make the request to fetch the signing key
'
' returns response in assocarray (id, key)
Function tubiAuth_handleAnonymousSigningKeyResponse(msg, anonymousSigningKeyReq)
  signingKey = invalid

  responseInfo = anonymousSigningKeyReq.handleEvent(msg)

  if responseInfo <> invalid and responseInfo.response <> invalid and responseInfo.response.data <> invalid
    code = responseInfo.response.code
    if code < 200 or code >= 400
      ' challenge was not valid
      signingKey = {}
    else if responseInfo.response.data.len() > 0
      signingKey = ParseJson(responseInfo.response.data)
    end if
  end if

  return signingKey
End Function


' handles anonymous token response
' @msg: roUrlEvent
' @anonymousTokenReq: assocarray, a request object as returned by Request().createAsync()
'                                 and used to make the request to fetch the anonymous auth token
'
' returns response in assocarray (accessToken, refreshToken, expires_in)
Function tubiAuth_handleAnonymousTokenResponse(msg, anonymousTokenReq)
  anonymousTokenInfo = invalid

  responseInfo = anonymousTokenReq.handleEvent(msg)

  if responseInfo <> invalid and responseInfo.response <> invalid and responseInfo.response.data <> invalid
    code = responseInfo.response.code
    if code < 200 or code >= 400
      ' signing key was not valid
      anonymousTokenInfo = {}
    else if responseInfo.response.data.len() > 0
      anonymousTokenInfo = ParseJson(responseInfo.response.data)
    end if
  end if

  return anonymousTokenInfo
End Function


' handles anonymous refresh token response
' @msg: roUrlEvent
' @anonymousTokenReq: assocarray
'
' returns response in assocarray (accessToken, refreshToken, expires_in), empty AA if 401, or invalid
Function tubiAuth_handleAnonymousRefreshTokenResponse(msg, anonymousTokenReq)
  newAccess = invalid

  responseInfo = anonymousTokenReq.handleEvent(msg)

  if responseInfo <> invalid and responseInfo.response <> invalid and responseInfo.response.data <> invalid
    if responseInfo.response.code = 403
      ' refresh token was expired
      newAccess = {}
    else if responseInfo.response.data.len() > 0
      newAccess = ParseJson(responseInfo.response.data)
    end if
  end if

  return newAccess
End Function


Function tubiAuth_clearFirstVisit()
  firstVisit = m.regDelete("firstVisit", m.firstVisitRegSection)
  return firstVisit
End Function


'reads device registry for firstVisit value
'returns firstVisit value if value is present, otherwise return -1
Function tubiAuth_getFirstVisit()
  firstVisit = m.regRead("firstVisit", m.firstVisitRegSection)
  if firstVisit <> invalid
    firstVisit = firstVisit.toInt()
  else
    firstVisit = -1
  end if
  return firstVisit
End Function


'sets the first visit value (number of days since Unix epoch) in the device registry
'returns the number of days since Unix epoch
Function tubiAuth_setFirstVisit()
  dateTime = CreateObject("roDateTime")
  secondsFromEpoch = dateTime.AsSeconds()
  daysFromEpoch = Int(secondsFromEpoch / 60 / 60 / 24)
  m.regWrite("firstVisit", daysFromEpoch.toStr(), m.firstVisitRegSection)
  return daysFromEpoch
End Function


'@choice - user choice of Video preview
'         true - show video preview
'         false - do not show video preview
Function tubiAuth_setEnableVideoPreview(choice)
  if isString(choice) = true
    if choice = "true"
      m.setAuthInfo("enablevideopreview", "true")
    else if choice = "false"
      m.setAuthInfo("enablevideopreview", "false")
    end if
  else
    if choice = true
      m.setAuthInfo("enablevideopreview", "true")
    else
      m.setAuthInfo("enablevideopreview", "false")
    end if
  end if
End Function


'parses auth info from the server and saves it into the registry for further access
'returns invalid or the authInfo assocArray that was successfully saved into the registry:
'authInfo = {
'  refreshToken: someRefreshToken(String)
'  accessToken: someAccessToken(String)
'  expireTime: numberOfSecondsUntilExpires(Integer as String)
'  userId: userId(Integer as String)
'  firstName: firstName(String)
'  lastName: lastName(String)
'  name: name(String)
'  authType: analyticsAuthType(String)
'  hasAge: true indicates Tubi has an age on record and the age is >= 13 (Boolean)
'}
'@serverAuthInfo: assocArray of auth info as received from the server
Function tubiAuth_handleRegistration(serverAuthInfo)
  authInfo = m.formatAuthInfoFromServer(serverAuthInfo)
  authInfo = m.saveAuthInfo(authInfo)

  return authInfo
End Function



'requests and receives a new auth token from the server
'this is a helper function that wraps tubiAuth_requestTokenRefresh_ and tubiAuth_handleRefreshResponse_
'this function behaves synchronously and blocks until a response is received or the timeout is reached
'@authInfo = {
'  refreshToken: someRefreshToken(String)
'  accessToken: someAccessToken(String)
'  expireTime: numberOfSecondsUntilExpires(Integer as String)
'  userId: userId(Integer as String)
'  firstName: firstName(String)
'  lastName: lastName(String)
'  name: name(String)
'  authType: analyticsAuthType(String)
'  hasAge: true indicates Tubi has an age on record and the age is >= 13 (Boolean)
'}
'@timeout: integer, the max amount of time to wait for a response from the server in seconds
'
'returns the new authInfo if updated or invalid if there was a problem receiving or updating the new authInfo
'side effects... overwrites the old authInfo in the registry with the new authInfo
Function tubiAuth_refreshAuthToken(authInfo, timeout)
  authPort = CreateObject("roMessagePort")
  refreshReq = m.requestTokenRefresh(authInfo, authPort)
  newAuthInfo = invalid

  if refreshReq <> invalid
    timer = CreateObject("roTimespan")
    while true
      msg = wait(100, authPort)
      newAccess = m.handleRefreshResponse(msg, refreshReq)

      if newAccess <> invalid
        if newAccess.access_token <> invalid
          newAuthInfo = m.updateAuthInfo(newAccess, authInfo)

          ' prior to saving authType as part of the authInfo in the registry, the only possible
          ' authType for analytics was "CODE" which was hard coded in the analytics module.
          ' At this point in the code, it's possible that the previously saved authInfo does
          ' not have an authType, so we default to "CODE". Over time the number of devices
          ' that enter this if block should drop to 0 as newly signed in/activated users save
          ' the authType in the registry, and older users add the "CODE" authType as they
          ' refresh their token.
          if authInfo.authType = invalid
            newAuthInfo.authType = "CODE"
          end if
          newAuthInfo = m.saveAuthInfo(newAuthInfo) 'returns invalid if not saved to the registry
        else
          ' Be careful to only do this if the service rejected suth refresh.  We don't
          ' want to sign users out for transient errors like network down.
          m.deleteAuthInfo()
        end if
        exit while
      end if

      'wait max x secs for a response to refresh the auth token
      if timer.totalMilliseconds() > (timeout * 1000)
        exit while
      end if
    end while
  end if

  return newAuthInfo 'may return invalid
End Function


'takes a refresh token from another device along with additional auth info and uses that info to
'get a roku refresh token. Then takes the new roku refresh token and get's a new auth token
'
'@externalAuthInfo: assocArray, the necessary info needed to do a token transfer from a different platform
'   platform: string, the originating platform (iphone, ipad, android, etc.)
'   externalDeviceId: string of integers, the device id for the originating device
'   externalRefreshToken: string, the refresh token sent by the originating device
'   userId: string of integers, the user id sent by the originating device
'@timeout: integer, the max amount of time (in ms) to wait for a response from the server
'
Function tubiAuth_transferRefreshToken(externalAuthInfo, timeout=10)
  newAuthInfo = invalid
  authPort = CreateObject("roMessagePort")

  'create and send transfer request
  transferReq = m.requestTokenTransfer(externalAuthInfo, authPort)

  'listen for transfer request response
  if transferReq <> invalid
    timer = CreateObject("roTimespan")
    while true
      msg = wait(100, authPort)
      newRefreshToken = m.handleRefreshResponse(msg, transferReq)

      if newRefreshToken <> invalid
        if newRefreshToken.refresh_token <> invalid
          stubbedAuthInfo = {
            refreshToken: newRefreshToken.refresh_token
            userId: externalAuthInfo.userId
          }

          'get new auth token and save new auth info to registry
          newAuthInfo = m.refreshAuthToken(stubbedAuthInfo, timeout)
        end if
        exit while
      end if

      'wait max x secs for a response to refresh the auth token
      if timer.totalMilliseconds() > (timeout * 1000)
        exit while
      end if
    end while
  end if

  return newAuthInfo
End Function


'@authToken can be the server access_token or refresh_token depending on the call being made
Function tubiAuth_getAuthHeaders(authToken)
  if isString(authToken) = true
    headers = {
      Authorization: "Bearer " + authToken
    }
    headers.append(m.constants.headers.json)
    headers.append(m.constants.headers.commonUapi)

    return headers
  else
    return invalid
  end if
End Function


'a wrapper for TubiRequest().createAsync(). Used to create requests that require authorization
' @url - The URL (with or without query params) to request
' @name (optional) - a human readable name for the request, to track in logs
' @options (optional) - options to tune the behavior of the request
'         valid Options:
'               method - HTTP method as string: GET, PUT, POST, PATCH, or DELETE
'               params - assoc array of URL query params
'               body - PUT or POST body as string
'               headers - assoc array of headers and their values
'
' returns a request objects as created by TubiRequest().createAsync() with an additional property(authInfo)
'   and additional method(getAuthHeaders) - both are needed in request.handleEvent()
' or returns invalid if there is no authInfo in the registry
Function tubiAuth_createAuthRequest(url as String, name = "" as String, options={} as Object) as Object
  authReq = invalid
  authInfo = m.getAuthInfo()
  if authInfo <> invalid and authInfo.accessToken <> invalid and authInfo.userId <> invalid
    authHeaders = m.getAuthHeaders(authInfo.accessToken)
    if authHeaders <> invalid
      if options.headers <> invalid
        options.headers.append(authHeaders)
      else
        options.headers = authHeaders
      end if
    end if

    'add user id if not already added
    if options.params = invalid
      options.params = {}
    end if
    if options.params["user_id"] = invalid and (url <> m.constants.urls.account.settings and url <> m.constants.urls.account.parentalRating)
      options.params["user_id"] = authInfo.userId
    end if

    authReq = m.request.createAsync(url, name, options)
    authReq.getAuthHeaders = m.getAuthHeaders
    authReq.refreshAuthToken = m.refreshAuthToken
    authReq.requestTokenRefresh = m.requestTokenRefresh
    authReq.updateAuthInfo = m.updateAuthInfo
    authReq.saveAuthInfo = m.saveAuthInfo
    authReq.handleRefreshResponse = m.handleRefreshResponse
    authReq.deleteAuthInfo = m.deleteAuthInfo
    authReq.constants = m.constants
    authReq.request = m.request
    authReq.authInfo = authInfo
    authReq.regWrite = m.regWrite
    authReq.authRegSection = m.authRegSection
    authReq.setAuthInfo = m.setAuthInfo
  end if

  return authReq
End Function


' @hasAge: boolean, backend response field "has_age". True indicates the user has an age
'                   associated with the account, and the age is >= 13.
Function tubiAuth_updateAuthInfoWithAge(hasAge)
  authInfo = m.getAuthInfo()

  if authInfo <> invalid
    if authInfo.userId <> invalid
      ' presence of userId indicates the user is logged in.
      ' Only save hasAge for a logged in user.
      authInfo.hasAge = hasAge.toStr()
    end if

    ' getAuthInfo() returns an int, but saveAuthInfo() expects a string for expire time
    expireTime = authInfo.expireTime
    if isInteger(expireTime) = true
      authInfo.expireTime = expireTime.toStr()
    end if
  end if

  m.saveAuthInfo(authInfo)
  return m.getAuthInfo()
End Function


Function tubiAuth_getGuestUserHasAgeInfo()
  hasAgeStored = m.regRead("ageInfo", m.guestUserHasAgeRegSection)
  if hasAgeStored <> invalid

    hasAgeStored = ParseJson(hasAgeStored)
    dateTime = CreateObject("roDateTime")
    nowTime = dateTime.AsSeconds()

    hasAgeInfo = {
      hasAge: hasAgeStored.hasAge
      expired: true
    }

    if hasAgeStored.expireTime > nowTime
      hasAgeInfo.expired = false
    end if
  else
    hasAgeInfo = {
      hasAge: false
      expired: true
    }
  end if
  return hasAgeInfo
End Function


' @hasAge: boolean, true indicates that the backend has determined that this user is >= 13 years old
Function tubiAuth_setGuestUserHasAgeInfo(hasAge)
  if isBoolean(hasAge) = false
    hasAge = false
  end if

  dateTime = CreateObject("roDateTime")
  nowTime = dateTime.AsSeconds()

  'set the default expire time (ie. the user failed the age gate)
  hasAgeStored = {
    hasAge: hasAge
    expireTime: nowTime + m.constants.timers.coppaFailTimeout
  }

  if hasAge = true
    ' update with the expire time used if the user passed the age gate
    hasAgeStored.expireTime = nowTime + m.constants.timers.coppaPassTimeout
  end if

  hasAgeStoredJson = FormatJson(hasAgeStored)
  m.regWrite("ageInfo", hasAgeStoredJson, m.guestUserHasAgeRegSection)
  return hasAgeStored
End Function


Function tubiAuth_deleteGuestUserHasAgeInfo()
  m.regDelete("ageInfo", m.guestUserHasAgeRegSection)
End Function


'@authInfo = {
'  refreshToken: someRefreshToken(String)
'  accessToken: someAccessToken(String)
'  expireTime: numberOfSecondsUntilExpires(Integer as String)
'  userId: userId(Integer as String)
'  firstName: firstName(String)
'  lastName: lastName(String)
'  name: name(String)
'  authType: analyticsAuthType(String)
'  hasAge: true indicates Tubi has an age on record and the age is >= 13 (Boolean)
'}
Function tubiAuth_saveAuthInfo(authInfo)
  if authInfo <> invalid and authInfo.refreshToken <> invalid and authInfo.accessToken <> invalid and authInfo.expireTime <> invalid and isString(authInfo.expireTime) = true
    for each key in authInfo
      value = authInfo[key]
      if isString(value) = false
        value = value.toStr()
      end if
      m.regWrite(key, value, m.authRegSection)
    end for
  else
    authInfo = invalid
  end if
  return authInfo
End Function


Function tubiAuth_deleteAuthInfo()
  authSection = CreateObject("roRegistry")
  authSection.delete(m.authRegSection)
  authSection.flush()
End Function


'should only be called by getAuthInfo
'returns true if expired and false if not expired
'@authInfo = {
'  refreshToken: someRefreshToken(String)
'  accessToken: someAccessToken(String)
'  expireTime: numberOfSecondsUntilExpires(Integer as String)
'  userId: userId(Integer as String)
'  firstName: firstName(String)
'  lastName: lastName(String)
'  name: name(String)
'  authType: analyticsAuthType(String)
'  hasAge: true indicates Tubi has an age on record and the age is >= 13 (Boolean)
'}
Function tubiAuth_checkIfAuthExpired(authInfo)
  isExpired = true

  dateTime = CreateObject("roDateTime")
  timeInSecs = dateTime.asSeconds()

  if isInteger(authInfo.expireTime) and timeInSecs < authInfo.expireTime
    isExpired = false
  end if

  return isExpired
End Function


'returns an authInfo object that is ready to be sent into the registry (expireTime is a string representation of an integer)
'@newAccess: assocArray, contains the new auth token and expire time as sent from the server during a refresh token action
'@authInfo: assocArray, authInfo as pulled from the registry with the old auth token and expire time
Function tubiAuth_updateAuthInfo(newAccess, authInfo)
  updatedAuthInfo = invalid

  if newAccess <> invalid and newAccess.expires_in <> invalid and newAccess.access_token <> invalid
    dateTime = CreateObject("roDateTime")
    newExpireTime = dateTime.asSeconds() + newAccess.expires_in

    if authInfo <> invalid
      authInfo.expireTime = newExpireTime.ToStr()
      authInfo.accessToken = newAccess.access_token

      updatedAuthInfo = authInfo
    end if
  end if

  return updatedAuthInfo
End Function


'returns an authInfo object that is ready to be sent into the registry (expireTime is a string representation of an integer)
'@newAccess: assocArray, contains the new auth token and expire time as sent from the server during a refresh token action
'@authInfo: assocArray, authInfo as pulled from the registry with the old auth token and expire time
Function tubiAuth_updateAnonymousAuthInfo(newAccess, authInfo)
  updatedAuthInfo = invalid

  if newAccess <> invalid and newAccess.expires_in <> invalid and newAccess.access_token <> invalid and newAccess.refresh_token <> invalid
    dateTime = CreateObject("roDateTime")
    newExpireTime = dateTime.asSeconds() + newAccess.expires_in

    if authInfo <> invalid

      authInfo.expireTime = newExpireTime.ToStr()
      authInfo.accessToken = newAccess.access_token
      authInfo.refreshToken = newAccess.refresh_token
      authInfo.authType = "NOT_AUTHED"

      updatedAuthInfo = authInfo
    end if
  end if

  return updatedAuthInfo
End Function


'used to get a new auth token when the current auth token has expired
'@authInfo: assocArray, expired authToken
'@port: roMessagePort
Function tubiAuth_requestTokenRefresh(authInfo, port)

  headers = m.getAuthHeaders(authInfo.refreshToken)

  reqOptions = {
    method: "POST"
    headers: headers
    retries: 0
  }

  newTokenReq = m.request.createAsync(m.constants.urls.userDevice.refreshToken, "getNewAccessToken", reqOptions)
  reqSent = newTokenReq.start(port)

  if reqSent = true
    return newTokenReq
  end if

  return invalid
End Function


'create/send a request that can be used to obtain a roku refresh token when given a refresh token from a different platfrom (ios, android, etc.)
'@externalAuthInfo: assocArray, the necessary info needed to do a token transfer from a different platform
'   platform: string, the originating platform (iphone, ipad, android, etc.)
'   externalDeviceId: string of integers, the device id for the originating device
'   externalRefreshToken: string, the refresh token sent by the originating device
'   userId: string of integers, the user id sent by the originating device
Function tubiAuth_requestTokenTransfer(externalAuthInfo, port)
  body = {
    device_id: m.constants.deviceInfo.deviceId
    platform: m.constants.platform
    from_device_id: externalAuthInfo.externalDeviceId
    from_platform: externalAuthInfo.platform
  }
  bodyJson = FormatJson(body)

  headers = m.getAuthHeaders(externalAuthInfo.externalRefreshToken)
  reqOptions = {
    method: "POST"
    body: bodyJson
    headers: headers
    retries: 0
  }

  newTokenReq = m.request.createAsync(m.constants.urls.userDevice.transferToken, "getRefreshTokenFromTransfer", reqOptions)
  reqSent = newTokenReq.start(port)

  if reqSent = true
    return newTokenReq
  end if

  return invalid
End Function


'@refreshRequest: assocArray, a reqest object as created by tubiRequest().createAsyncHTTPRequest()
Function tubiAuth_handleRefreshResponse(msg, refreshRequest)
  newAccess = invalid

  responseInfo = refreshRequest.handleEvent(msg)

  if responseInfo <> invalid and responseInfo.response <> invalid and responseInfo.response.data <> invalid
    if responseInfo.response.code = 403
      ' refresh token was expired
      newAccess = {}
    else if responseInfo.response.data.len() > 0
      newAccess = ParseJson(responseInfo.response.data)
    end if
  end if

  return newAccess
End Function


'used when getting back a response from the server after a successful registration.
'We need to format the information to match what we store in the registry
'returns authInfo = {
'                     refreshToken: someRefreshToken(String)
'                     accessToken: someAccessToken(String)
'                     expireTime: numberOfSecondsUntilExpires(Integer as String)
'                     userId: userId(Integer as String)
'                     fn: firstName(String)
'                     ln: lastName(String)
'                     name: name(String)
'                     authType: analyticsAuthType(String)
'                     has_age: true indicates Tubi has an age on record and the age is >= 13 (Boolean)
'                   }
Function tubiAuth_formatAuthInfoFromServer(serverAuthInfo)
  clock = CreateObject("roDateTime")
  secondsToNow = clock.AsSeconds()
  authInfo = {}

  if serverAuthInfo.refresh_token <> invalid then authInfo.refreshToken = serverAuthInfo.refresh_token
  if serverAuthInfo.access_token <> invalid then authInfo.accessToken = serverAuthInfo.access_token
  if serverAuthInfo.expires_in <> invalid then authInfo.expireTime = (serverAuthInfo.expires_in + secondsToNow).ToStr()
  if serverAuthInfo.user_id <> invalid then authInfo.userId = serverAuthInfo.user_id.toStr()
  if serverAuthInfo.authType <> invalid then authInfo.authType = serverAuthInfo.authType
  if serverAuthInfo.has_age <> invalid then authInfo.hasAge = serverAuthInfo.has_age.toStr()
  if serverAuthInfo.enable_video_preview <> invalid then authInfo.enableVideoPreview = serverAuthInfo.enable_video_preview

  authInfo.firstName = ""
  if serverAuthInfo.first_name <> invalid
    authInfo.firstName = serverAuthInfo.first_name
  end if

  authInfo.lastName = ""
  if serverAuthInfo.last_name <> invalid
    authInfo.lastName = serverAuthInfo.last_name
  end if

  authInfo.name = ""
  if serverAuthInfo.name <> invalid
    authInfo.name = serverAuthInfo.name
  end if

  return authInfo
End Function


' copied from /source/3rdparty/roku/generalUtils.brs so that it won't need to be added as a dependency for any logic that wants to call
' auth.getAuthInfo
Function tubiAuth_regReadAll(section="")
  if section = "" then section = "Default"
  sec = CreateObject("roRegistrySection", section)
  keys = sec.GetKeyList()
  allInfo = {}
  for each key in keys
      value = m.regRead(key, section)
      allInfo[key] = value
  end for
  return allInfo
End Function


' copied from /source/3rdparty/roku/generalUtils.brs so that it won't need to be added as a dependency for any logic that wants to call
' auth.getAuthInfo
Function tubiAuth_regRead(key, section=invalid)
  if section = invalid then section = "Default"
  sec = CreateObject("roRegistrySection", section)
  if sec.Exists(key) then return sec.Read(key)
  return invalid
End Function


' copied from /source/3rdparty/roku/generalUtils.brs so that it won't need to be added as a dependency
Function tubiAuth_regWrite(key, val, section=invalid)
  if section = invalid then section = "Default"
  sec = CreateObject("roRegistrySection", section)
  sec.Write(key, val)
  sec.Flush() ' commit it
End Function


' copied from /source/3rdparty/roku/generalUtils.brs so that it won't need to be added as a dependency
Function tubiAuth_regDelete(key, section=invalid)
  if section = invalid then section = "Default"
  sec = CreateObject("roRegistrySection", section)
  sec.Delete(key)
  sec.Flush()
End Function


' tubiAuth_createSignature
' Creates a signature to be used for signing requests, as documented by Amazon Signature 4 spec
' https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html
' The signature will be used when making a request fetch anonymous auth tokens for signed out users.
'
' @dateTime : ISO 8601 as String
' @tokenReqInfo : assocarray,
' @secretKey : string, key response of signing_key
' @algorithm : string, from constants
'
' returns signature : string
'
Function tubiAuth_createSignature(dateTime, tokenReqInfo, secretKey, algorithm)

  canonicalRequest = m.constructCanonicalRequest(tokenReqInfo)

  hashedCanonicalRequest = m.getHash(canonicalRequest)

  stringToSign = m.createStringtoSignSignature(hashedCanonicalRequest, dateTime, algorithm)

  calculatedSignature = m.calculateSignature(stringToSign, secretKey, dateTime)

  return lcase(calculatedSignature)

End Function


' tubiAuth_constructCanonicalRequest
'
' @tokenReqInfo : assocarray,
'
' returns canonicalRequest : string
'
Function tubiAuth_constructCanonicalRequest(tokenReqInfo)

  method = tokenReqInfo.method
  absolutePath = m.getAbsolutePath(tokenReqInfo.url)
  queryString = m.constructCanonicalQueryString(tokenReqInfo.params)
  canonicalHeader = m.constructCanonicalHeaders(tokenReqInfo.headers)
  signedHeader = m.constructSignedHeaders(tokenReqInfo.headers)
  hashedPayload = m.constructHashedPayload(tokenReqInfo.body)

  canonicalRequest = method + chr(10) + absolutePath + chr(10) + queryString + chr(10) + canonicalHeader + chr(10) + signedHeader + chr(10) + hashedPayload
  return canonicalRequest

End Function


' tubiAuth_getAbsolutePath
'
' @url : string, api request url
'
' returns absolutePath : string
'
Function tubiAuth_getAbsolutePath(url)

  absolutePath = getUrlParts(url).path
  return absolutePath

End Function


' tubiAuth_constructCanonicalQueryString
'
' @params : assocarray,
'
' returns queryString : string
'
Function tubiAuth_constructCanonicalQueryString(params)

  queryString = buildQueryString(params)
  return queryString

End Function


' tubiAuth_constructCanonicalHeaders
'
' @headers : assocarray,
'
' returns canonicalHeader : string
'
Function tubiAuth_constructCanonicalHeaders(headers)
  canonicalHeader = ""

  if headers <> invalid
    for each item in headers.Items()
      canonicalHeader = canonicalHeader + lcase(item.key).trim() + ":" + item.value.tostr().trim() + chr(10)
    end for
  end if

  return canonicalHeader
End Function


' tubiAuth_constructSignedHeaders
'
' @headers : assocarray,
'
' returns signedHeader : string
'
Function tubiAuth_constructSignedHeaders(headers)

  signedHeader = ""
  index = 0

  if headers <> invalid
    headersCount = headers.count()

    for each item in headers.Items()
      signedHeader = signedHeader + lcase(item.key).trim()
      index = index + 1
      if index <> headersCount
        signedHeader = signedHeader + ";"
      end if
    end for
  end if

  if signedHeader = ""
    signedHeader = chr(10)
  end if

  return signedHeader

End Function


' tubiAuth_constructHashedPayload
'
' @body : string,
'
' returns hashedPayload : string
'
Function tubiAuth_constructHashedPayload(body)

  hashedPayload = m.getHash(body)
  return hashedPayload

End Function


' tubiAuth_getHash
'
' @text : string,  to be hashed
'
' returns hash(lowercase) : string
'
Function tubiAuth_getHash(text)

  ba1 = CreateObject("roByteArray")
  ba1.FromAsciiString(text)
  digest = CreateObject("roEVPDigest")
  digest.Setup("sha256")
  digest.Update(ba1)
  hash = digest.Final()

  return lcase(hash)

End Function


' tubiAuth_createStringtoSignSignature
'
' @hashedCanonicalRequest : string
' @dateTime : roDateTIme
' @algorithm : string, from constants
'
' returns stringToSign : string
'
Function tubiAuth_createStringtoSignSignature(hashedCanonicalRequest, dateTime, algorithm)

  dateTimeFormatted = dateTime.replace("-","").replace(":","")
  stringToSign = algorithm + chr(10) + dateTimeFormatted + chr(10) + hashedCanonicalRequest
  return stringToSign

End Function


' tubiAuth_calculateSignature
' Takes the component parts needed for constructing a signature and constructs the
' signature to be used for signing requests, as documented by Amazon Signature 4 spec
' https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html
' The signature will be used when making a request fetch anonymous auth tokens for signed out users.
'
' @stringToSign : string, derived string from hashedcanonicalrequest
' @secretKey : string, key response of signing_key
'
' returns signature : string
'
Function tubiAuth_calculateSignature(stringToSign, secretKey, dateTime)

  signature = invalid

  date = dateTime.replace("-","").split("T")[0]

  ba = CreateObject("roByteArray")
  ba.FromBase64String(secretKey)

  ba1 = CreateObject("roByteArray")
  ba1.FromAsciiString("TUBI")

  ba1.append(ba)

  hmac = CreateObject("roHMAC")

  if hmac.setup("sha256", ba1) = 0
    message = CreateObject("roByteArray")
    message.fromAsciiString(date)
    kDate = hmac.process(message)

    hmac = CreateObject("roHMAC")

    if hmac.setup("sha256", kDate) = 0
      message = CreateObject("roByteArray")
      message.fromAsciiString("tubi_request")
      kSigning = hmac.process(message)

      hmac = CreateObject("roHMAC")

      if hmac.setup("sha256", kSigning) = 0
        message = CreateObject("roByteArray")
        message.fromAsciiString(stringToSign)
        signature = hmac.process(message)
        signature = lcase(signature.ToHexString())
      end if

    end if
  end if

  if signature <> invalid
    return lcase(signature)
  end if

  return signature

End Function


Function tubiAuth_getSignedHeaders(headers)
  signedHeaders = ""

  index = 0
  if headers <> invalid
    headersCount = headers.count()
    for each item in headers.Items()
      index = index + 1

      if FindMemberFunction(item.value, "toStr") <> invalid
        ' only add headers with values that can be converted to strings
        signedHeaders = signedHeaders + lcase(item.key).trim()
        if index <> headersCount
          signedHeaders = signedHeaders + ";"
        end if
      end if
    end for
  end if

  return signedHeaders
End Function
