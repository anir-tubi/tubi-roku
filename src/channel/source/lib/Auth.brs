' TubiAuth provides a read only way to access auth info
'@constants: assocArray, the constants object returned from getConstants()
Function TubiAuth(constants)
  authRegSection = "auth"
  if constants <> invalid AND constants.settings.stagingApis = true then
    authRegSection = "auth_staging"
  end if

  return {
    authRegSection: authRegSection
    constants: constants

    'public methods
    getAuthInfoNoUpdate: tubiAuth_getAuthInfoNoUpdate
    getAuthInfo: tubiAuth_getAuthInfoNoUpdate ' Duplicated to allow easier migration
    checkIfAuthExpired: tubiAuth_checkIfAuthExpired
    getAuthHeaders: tubiAuth_getAuthHeaders

    'private methods
    regRead: tubiAuth_regRead
    regReadAll: tubiAuth_regReadAll
  }
End Function


' TubiAuthUpdate provides all the capabilities of TubiAuth and adds ability to update auth
'@constants: assocArray, the constants object returned from getConstants()
Function TubiAuthUpdate(constants)
  ' Verify we are being called from a controller
  if m.generalTask = invalid then
    tubiLog("TubiAuthUpdate() must be called from a controller", "error")
    return invalid
  end if

  module = TubiAuth(constants)
  module.append({
    ' controllerCallbackIds
    callbackForLogout: invalid
    callBackForInitOrUpdateAuthInfo: invalid
    callBackForTransferRefreshToken: invalid

    ' public methods
    initOrUpdateAuthInfo: tubiAuth_initOrUpdateAuthInfo
    setAuthInfo: tubiAuth_setAuthInfo
    logout: tubiAuth_logout ' Should only be called internally or by logout() in shared.brs
    updateAuthInfoWithAge: tubiAuth_updateAuthInfoWithAge
    transferRefreshToken: tubiAuth_transferRefreshToken
    handleRegistration: tubiAuth_handleRegistration

    'private methods
    saveAuthInfo: tubiAuth_saveAuthInfo
    deleteAuthInfo: tubiAuth_deleteAuthInfo
    getTokenRefreshInfo: tubiAuth_getTokenRefreshInfo
    getRequestTokenTransferInfo: tubiAuth_getRequestTokenTransferInfo
    handleRefreshResponse: tubiAuth_handleRefreshResponse
    handleTransferRefreshResponse: tubiAuth_handleTransferRefreshResponse
    updateAuthInfo: tubiAuth_updateAuthInfo
    formatAuthInfoFromServer: tubiAuth_formatAuthInfoFromServer

    fetchAndSaveAnonymousAuthInfo: tubiAuth_fetchAndSaveAnonymousAuthInfo

    getAnonymousSigningKeyRequestInfo: tubiAuth_getAnonymousSigningKeyRequestInfo
    handleAnonymousSigningKeyResponse: tubiAuth_handleAnonymousSigningKeyResponse

    getAnonymousTokenRequestInfo: tubiAuth_getAnonymousTokenRequestInfo
    handleAnonymousTokenResponse: tubiAuth_handleAnonymousTokenResponse

    refreshAnonymousToken: tubiAuth_refreshAnonymousToken
    getAnonymousRefreshTokenRequestInfo: tubiAuth_getAnonymousRefreshTokenRequestInfo
    handleAnonymousRefreshTokenResponse: tubiAuth_handleAnonymousRefreshTokenResponse
    refreshAuthToken: tubiAuth_refreshAuthToken

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

    makeRequest: tubiAuth_makeRequest
  })
  return module
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

  if authInfo.expireTime <> invalid 'used as test to determine if we have any auth info in the auth registry
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

  return authInfo 'can return an empty assocArray
End Function


' If the access token has expired it will try to refresh it.
' If there is no auth info available it will get anonymous auth info
' @callback: function, the callback that will called after the auth info is available
' @forceUpdate: boolean - if true will attempt to refresh access token even if the access token does not appear to be expired
Function tubiAuth_initOrUpdateAuthInfo(callback, forceUpdate = false)
  controllerCallbackId = "callBackForInitOrUpdateAuthInfo"
  m[controllerCallbackId] = callback
  authInfo = m.getAuthInfoNoUpdate()

  if authInfo.expireTime <> invalid 'used as test to determine if we have any auth info in the auth registry
    if m.checkIfAuthExpired(authInfo) = true OR forceUpdate = true then
      if authInfo.userId <> invalid
        m.refreshAuthToken(authInfo, controllerCallbackId)
      else if isAA(authInfo) = true AND isString(authInfo.secretKey) = true then
        m.refreshAnonymousToken(authInfo, controllerCallbackId)
      else
        m.logout(callback)
      end if
    else
      ' authInfo is not expired so nothing to do. Just call the callback immediately
      callback()
    end if
  else
    m.fetchAndSaveAnonymousAuthInfo(controllerCallbackId)
  end if
End Function


'Saves the key value pair in registry
'@key : String, authInfo key
'@value: String, Value for the provided key
Function tubiAuth_setAuthInfo(key, value)

  if isString(key) = true AND isString(value) = true
    ' Make sure keys are stored in the registry in the same way always
    lCaseKey = lcase(key)
    acceptedKeys = {
      accesstoken: true
      authtype: true
      expiretime: true
      firstname: true
      hasage: true
      lastname: true
      name: true
      refreshtoken: true
      secretkey: true
      userid: true
    }

    correctlyCasedKey = invalid
    if acceptedKeys[lCaseKey] = true
      if lCaseKey = "secretkey"
        correctlyCasedKey = "secretKey"
      else
        correctlyCasedKey = lCaseKey
      end if
    end if

    if correctlyCasedKey <> invalid then
      sec = createObject("roRegistrySection", m.authRegSection)
      sec.write(correctlyCasedKey, value)
      sec.flush() ' commit it
    else
      tubiLog("Key " + key + " is not a valid auth registry value", "warn")
    end if
  else
    tubiLog("Key/Value provided for SetAuthInfo Function are not Strings.", "warn")
  end if
End Function


' It refreshes the accessToken using refresh Token
' @authInfo: assocarray, contains accessToken, refreshToken, expireTime
' @controllerCallbackId: string, the id for the callback function that should be called when this process is completed ex. "callBackForInitOrUpdateAuthInfo"
Function tubiAuth_refreshAnonymousToken(authInfo, controllerCallbackId)
  tokenReqInfo = m.getAnonymousRefreshTokenRequestInfo(authInfo)
  m.makeRequest(tokenReqInfo, "handleAnonymousRefreshTokenResponse", controllerCallbackId)
End Function


' It creates request object for refreshToken Request
' @authInfo: assocarray, contains accessToken, refreshToken, expireTime
'
' returns AnonymousRefreshToken request object in assocarray
Function tubiAuth_getAnonymousRefreshTokenRequestInfo(authInfo)

  algorithm = m.constants.anonymous.algorithm
  dateTime = createObject("roDateTime").ToISOString()
  dateTimeFormatted = dateTime.replace("-", "").replace(":", "")

  headers = m.getAuthHeaders(authInfo.refreshToken)

  secretKey = authInfo.secretKey

  body = {}
  bodyJson = FormatJSON(body)

  tokenReqInfo = {
    url: m.constants.urls.account.anonymousRefreshToken
    options: {
      body: bodyJson
      headers: headers
      method: m.constants.reqTypes.post
    }
  }

  signature = m.createSignature(dateTime, tokenReqInfo, secretKey, algorithm)
  signedHeaders = m.getSignedHeaders(headers)

  tokenReqInfo.options.params = {
    "X-Tubi-Algorithm": algorithm
    "X-Tubi-SignedHeaders": signedHeaders
    "X-Tubi-Date": dateTimeFormatted
    "X-Tubi-Expires": "60"
    "X-Tubi-Signature": signature
  }


  return tokenReqInfo
End Function


' Kicks off the process to fetch an anonymous auth token
' @controllerCallbackId: string, the id for the callback function that should be called when this process is completed ex. "callBackForInitOrUpdateAuthInfo
Function tubiAuth_fetchAndSaveAnonymousAuthInfo(controllerCallbackId)
  roDeviceInfo = CreateObject("roDeviceInfo")
  verifier = roDeviceInfo.GetRandomUUID()

  timeout = 10
  anonymousSigningKeyReqInfo = m.getAnonymousSigningKeyRequestInfo(verifier)
  anonymousSigningKeyReqInfo.timeoutInMilliSec = timeout * 1000
  m.makeRequest(anonymousSigningKeyReqInfo, "handleAnonymousSigningKeyResponse", controllerCallbackId, {
    verifier: verifier
  })
End Function


' It creates request info for anonymous Token
' @verifier: string, random string used for anonymous token request
' @signingKeyResponse: assocarray, signingKey response {id, key}
'
' returns request object used to fetch an anonymous token as returned by Request().createAsync()
Function tubiAuth_getAnonymousTokenRequestInfo(verifier, signingKeyResponse)
  id = signingKeyResponse.id
  secretKey = signingKeyResponse.key
  algorithm = m.constants.anonymous.algorithm

  dateTime = createObject("roDateTime").ToISOString()
  dateTimeFormatted = dateTime.replace("-", "").replace(":", "")

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
    url: m.constants.urls.account.anonymousToken
    options: {
      body: bodyJson
      headers: headers
      method: m.constants.reqTypes.post
    }
  }

  signature = m.createSignature(dateTime, tokenReqInfo, secretKey, algorithm)
  signedHeaders = m.getSignedHeaders(headers)

  tokenReqInfo.options.params = {
    "X-Tubi-Algorithm": algorithm
    "X-Tubi-SignedHeaders": signedHeaders
    "X-Tubi-Date": dateTimeFormatted
    "X-Tubi-Expires": "60"
    "X-Tubi-Signature": signature
  }

  return tokenReqInfo
End Function


' It creates request info for anonymous signingKey
' @verifier: string, random string used for anonymous signingKey request
'
' returns request info object
Function tubiAuth_getAnonymousSigningKeyRequestInfo(verifier)
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

  options = {
    "method": m.constants.reqTypes.post
    "body": bodyJson
    "headers": headers
  }

  return {
    "url": m.constants.urls.account.anonymousSigningKey
    "options": options
  }
End Function


' handles anonymous signingKey response
Function tubiAuth_handleAnonymousSigningKeyResponse(response)
  signingKeyResponse = response.data
  if signingKeyResponse = invalid OR (signingKeyResponse.id = invalid OR signingKeyResponse.key = invalid) then
    tubiLog("Signing Key Response is invalid", "warn")
  else
    responseContext = response.responseContext
    anonymousTokenReqInfo = m.getAnonymousTokenRequestInfo(responseContext.verifier, signingKeyResponse)
    anonymousTokenReqInfo.timeoutInMilliSec = 10000
    m.makeRequest(anonymousTokenReqInfo, "handleAnonymousTokenResponse", responseContext.controllerCallbackId, {
      "secretKey": signingKeyResponse.key
    })
  end if
End Function


' Handles anonymous token response
Function tubiAuth_handleAnonymousTokenResponse(response)
  token = response.data
  if token <> invalid
    if token.access_token <> invalid AND token.refresh_token <> invalid AND token.expires_in <> invalid
      if isString(response.responseContext.secretKey) = true then
        authInfo = m.formatAuthInfoFromServer(token)
        authInfo["secretKey"] = response.responseContext.secretKey ' store secretKey in registry, we need it for refreshing anonymous token
        m.saveAuthInfo(authInfo)
      else
        tubiLog("Secret Key is invalid", "warn")
      end if
    else
      tubiLog("Token response is invalid", "warn")
    end if
  end if

  ' We want to always call the callback so we don't get stuck waiting indefinitely
  controllerCallbackId = response.responseContext.controllerCallbackId
  callback = m[controllerCallbackId]
  if callback <> invalid then
    m[controllerCallbackId] = invalid
    callback()
  end if
End Function


' handles anonymous refresh token response
' @response: assocarray as returned from request made in refreshAnonymousToken
Function tubiAuth_handleAnonymousRefreshTokenResponse(response)
  if response <> invalid
    controllerCallbackId = response.responseContext.controllerCallbackId
    if response.code = 401 OR response.code = 403
      ' Be careful to only do this if the service rejected auth refresh. We don't
      ' want to clear auth info for error code besides these

      ' We are deleting the stored token info since backend said it cannot use the refresh token to provide
      ' a new access token.
      callback = m[controllerCallbackId]
      if callback <> invalid then
        m[controllerCallbackId] = invalid
        m.logout(callback)
      end if
    else
      newAuthInfo = m.updateAuthInfo(response.data)
      if newAuthInfo <> invalid
        ' handling the succesful token refresh
        m.saveAuthInfo(newAuthInfo, true)
      else
        ' Since the refresh token call failed.
        ' This else part is triggered because backend HTTP code was not 401 or 403.
        ' Assuming it is some temporary issue we are not logging the user out but instead returning the same token
        ' So that we can re-use existing registry values to refresh the token again during relaunch or next re-try.
        ' callback
      end if

      callback = m[controllerCallbackId]
      if callback <> invalid then
        m[controllerCallbackId] = invalid
        callback()
      end if
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
  m.saveAuthInfo(authInfo)
End Function



'requests and receives a new auth token from the server
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
' @controllerCallbackId: string, the id for the callback function that should be called when this process is completed ex. "callBackForInitOrUpdateAuthInfo
Function tubiAuth_refreshAuthToken(authInfo, controllerCallbackId)
  requestInfo = m.getTokenRefreshInfo(authInfo)
  m.makeRequest(requestInfo, "handleRefreshResponse", controllerCallbackId)
End Function


'takes a refresh token from another device along with additional auth info and uses that info to
'get a roku refresh token. Then takes the new roku refresh token and get's a new auth token
'
'@externalAuthInfo: assocArray, the necessary info needed to do a token transfer from a different platform
'   platform: string, the originating platform (iphone, ipad, android, etc.)
'   externalDeviceId: string of integers, the device id for the originating device
'   externalRefreshToken: string, the refresh token sent by the originating device
'   userId: string of integers, the user id sent by the originating device
' @callback: function, the callback that will called after the token transfer has finished
Function tubiAuth_transferRefreshToken(externalAuthInfo, callback)
  'create and send transfer request
  requestInfo = m.getRequestTokenTransferInfo(externalAuthInfo)

  controllerCallbackId = "callBackForTransferRefreshToken"
  m[controllerCallbackId] = callback

  m.makeRequest(requestInfo, "handleTransferRefreshResponse", controllerCallbackId, {
    "userId": externalAuthInfo.userId
  })
End Function


'@authToken can be the server access_token or refresh_token depending on the call being made
Function tubiAuth_getAuthHeaders(authToken, authorizationHeaderOnly = false)
  if isString(authToken) = true
    headers = {
      Authorization: "Bearer " + authToken
    }

    ' In some cases we don't want to append these headers and just want to use the Authorization header
    if authorizationHeaderOnly = false then
      headers.append(m.constants.headers.json)
      headers.append(m.constants.headers.commonUapi)
    end if

    return headers
  else
    return invalid
  end if
End Function


' @hasAge: boolean, backend response field "has_age". True indicates the user has an age
'                   associated with the account, and the age is >= 13.
Function tubiAuth_updateAuthInfoWithAge(hasAge)
  authInfo = m.getAuthInfo()

  if authInfo <> invalid
    if authInfo.userId <> invalid
      ' presence of userId indicates the user is logged in.
      ' Only save hasAge for a logged in user.
      m.setAuthInfo("hasage", hasAge.toStr())
    end if
  end if
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
' @authInfoMustHaveRefreshToken: boolean, if the authInfo to be saved was generated from a requsest
'                                         to refresh the auth/anonymous token, the refresh token is not
'                                         expected to be included in the passed in authInfo and authInfoMustHaveRefreshToken
'                                         should be set to false. If the authInfo to be saved was generated
'                                         as part of the initial setup of auth/anonymous token, a refresh
'                                         token is expected to be included in the passed in authInfo and
'                                         authInfoMustHaveRefreshToken should be set to true
Function tubiAuth_saveAuthInfo(authInfo, authInfoMustHaveRefreshToken = false)
  if authInfo <> invalid AND authInfo.accessToken <> invalid AND isString(authInfo.expireTime) = true then
    if authInfoMustHaveRefreshToken = false then
      if authInfo.refreshToken = invalid then
        tubiLog("AuthInfo is missing refreshToken and refresh was false", "warn")
        authInfo = [] ' Setting empty to prevent saving to registry
      end if
    end if

    for each key in authInfo
      value = authInfo[key]
      if isString(value) = false
        value = value.toStr()
      end if

      m.setAuthInfo(key, value)
    end for
  else
    tubiLog("AuthInfo is invalid or missing required fields", "warn")
  end if
End Function


Function tubiAuth_logout(callback = invalid)
  controllerCallbackId = "callbackForLogout"
  m[controllerCallbackId] = callback
  m.deleteAuthInfo()
  m.fetchAndSaveAnonymousAuthInfo(controllerCallbackId)
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
' @timeOffset: integer, the number of seconds to offset the current time by. Used to allowing checking if the auth token will expire soon. Only positive numbers are allowed.
Function tubiAuth_checkIfAuthExpired(authInfo, timeOffset = 0)
  isExpired = true

  if timeOffset < 0 then
    tubiLog("timeOffset must be a positive number", "warn")
    timeOffset = 0
  end if

  dateTime = CreateObject("roDateTime")
  timeInSecs = dateTime.asSeconds()

  if isInteger(authInfo.expireTime) AND timeInSecs + timeOffset < authInfo.expireTime
    isExpired = false
  end if

  return isExpired
End Function


'returns an authInfo object that is ready to be sent into the registry (expireTime is a string representation of an integer)
'@newAccess: assocArray, contains the new auth token and expire time as sent from the server during a refresh token action
Function tubiAuth_updateAuthInfo(newAccess)
  updatedAuthInfo = invalid

  if newAccess <> invalid AND newAccess.expires_in <> invalid AND newAccess.access_token <> invalid
    dateTime = CreateObject("roDateTime")
    newExpireTime = dateTime.asSeconds() + newAccess.expires_in

    updatedAuthInfo = {
      expireTime: newExpireTime.ToStr()
      accessToken: newAccess.access_token
    }

    if newAccess.refresh_token <> invalid
      updatedAuthInfo.refreshToken = newAccess.refresh_token
    end if
  end if

  return updatedAuthInfo
End Function


'used to get a new auth token when the current auth token has expired
'@authInfo: assocArray, contains the refreshToken we will use to refresh the auth token
Function tubiAuth_getTokenRefreshInfo(authInfo)
  headers = m.getAuthHeaders(authInfo.refreshToken)

  requestInfo = {
    "url": m.constants.urls.account.refreshToken
    "options": {
      "method": m.constants.reqTypes.post
      "headers": headers
    }
  }
  return requestInfo
End Function


'create/send a request that can be used to obtain a roku refresh token when given a refresh token from a different platfrom (ios, android, etc.)
'@externalAuthInfo: assocArray, the necessary info needed to do a token transfer from a different platform
'   platform: string, the originating platform (iphone, ipad, android, etc.)
'   externalDeviceId: string of integers, the device id for the originating device
'   externalRefreshToken: string, the refresh token sent by the originating device
'   userId: string of integers, the user id sent by the originating device
Function tubiAuth_getRequestTokenTransferInfo(externalAuthInfo)
  body = {
    device_id: m.constants.deviceInfo.deviceId
    platform: m.constants.platform
    from_device_id: externalAuthInfo.externalDeviceId
    from_platform: externalAuthInfo.platform
  }
  bodyJson = FormatJson(body)

  headers = m.getAuthHeaders(externalAuthInfo.externalRefreshToken)

  options = {
    "method": m.constants.reqTypes.post
    "body": bodyJson
    "headers": headers
  }

  params = {}
  'passing device advertiser id to tokenTransfer request.
  params["idfa"] = m.constants.deviceInfo.deviceAdId

  options["params"] = params

  return {
    "url": m.constants.urls.account.transferToken
    "options": options
  }
End Function


Function tubiAuth_handleTransferRefreshResponse(response)
  if response <> invalid
    m.handleRefreshResponse(response, true)
  end if
End Function


Function tubiAuth_handleRefreshResponse(response, isTransferRefreshResponse = false)
  if response <> invalid
    controllerCallbackId = response.responseContext.controllerCallbackId
    if response.code = 401 OR response.code = 403
      ' Be careful to only do this if the service rejected auth refresh.  We don't
      ' want to sign users out for transient errors like network down.

      ' We are deleting the stored token info since backend said it cannot use the refresh token to provide
      ' a new access token.
      callback = m[controllerCallbackId]
      if callback <> invalid then
        m[controllerCallbackId] = invalid
        m.logout(callback)
      end if
    else
      newAuthInfo = m.updateAuthInfo(response.data)
      if newAuthInfo <> invalid
        ' If it is a transfer refresh response, we need to set authType or else it will stay with whatever the last one was
        if isTransferRefreshResponse = true then
          ' Transfer refresh does not have the userId in the response so we have to add from the info passed in from mobile
          newAuthInfo.userId = response.responseContext.userId
          newAuthInfo.authType = "MOBILE_APP"
        end if

        m.saveAuthInfo(newAuthInfo, true)
      else
        ' Since the refresh token call failed.
        ' This else part is triggered because backend HTTP code was not 401 or 403.
        ' Assuming it is some temporary issue we are not logging the user out but instead returning the same token
        ' So that we can re-use existing registry values to refresh the token again during relaunch or next re-try.
        ' callback
      end if

      callback = m[controllerCallbackId]
      if callback <> invalid then
        m[controllerCallbackId] = invalid
        callback()
      end if
    end if
  end if
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
'                     userUuid: 32 bit hex string.
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
  if serverAuthInfo.user_uuid <> invalid then authInfo.userUuid = serverAuthInfo.user_uuid

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
Function tubiAuth_regReadAll(section = "")
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
Function tubiAuth_regRead(key, section = invalid)
  if section = invalid then section = "Default"
  sec = CreateObject("roRegistrySection", section)
  if sec.Exists(key) then return sec.Read(key)
  return invalid
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
  options = tokenReqInfo.options
  method = options.method
  absolutePath = m.getAbsolutePath(tokenReqInfo.url)
  queryString = m.constructCanonicalQueryString(options.params)
  canonicalHeader = m.constructCanonicalHeaders(options.headers)
  signedHeader = m.constructSignedHeaders(options.headers)
  hashedPayload = m.constructHashedPayload(options.body)

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

  dateTimeFormatted = dateTime.replace("-", "").replace(":", "")
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

  date = dateTime.replace("-", "").split("T")[0]

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


' Function as a wrapper around the GeneralTaskModule makeRequest method to allow us calling it from in here without storing a reference to controller m that could create a loop
' @requestInfo: assocarray, contains information needed to make the request. Expected fields:
'   url (required): String, url of the request api
'   requestType (required): String, name of the request api, for example "getHomescreen".
'                           Can be found in constants.reqNames
'   options: AA, options as expected by TubiRequest().createAsync. (For example: method, params, body, headers)
' @authCallbackName: string, the name of the callback function inside of Auth.brs that should be called after the request is completed
' @controllerCallbackId: string, the id for the callback function that should be called when this process is completed ex. "callBackForInitOrUpdateAuthInfo
' @responseContext: assocarray, additional context to be passed to the callback function
Function tubiAuth_makeRequest(requestInfo, authCallbackName, controllerCallbackId, responseContext = {})
  makeRequest = getGlobalAA().makeRequest
  if makeRequest <> invalid then
    requestInfo.successCallback = tubiAuthGeneralTaskRequestCallback
    requestInfo.errorCallback = tubiAuthGeneralTaskRequestCallback

    responseContext.append({
      "authCallbackName": authCallbackName
      "controllerCallbackId": controllerCallbackId
    })

    requestInfo.append({
      "responseContext": responseContext
      "responseType": "assocarray"
      "requestType": m.constants.reqNames.genericWithResponseContext
      "retries": 0 ' We don't want to retry any auth requests
    })
    makeRequest(requestInfo)
  end if
End Function


Function tubiAuthGeneralTaskRequestCallback(response)
  auth = m.tubiAuthUpdate
  if auth = invalid then
    tubiLog("tubiAuthGeneralTaskRequestCallback: auth is invalid", "warn")
  else
    if response.responseContext <> invalid AND isNonEmptyString(response.responseContext.authCallbackName) AND isFunction(auth[response.responseContext.authCallbackName]) then
      auth[response.responseContext.authCallbackName](response)
    else
      tubiLog("tubiAuthGeneralTaskRequestCallback: responseContext.callbackName is invalid", "warn")
    end if
  end if
End Function
