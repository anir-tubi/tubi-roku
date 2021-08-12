'@constants: assocArray, the constants object returned from getContstants()
'@request: assocArray, the object returned from TubiRequest()
Function TubiAuth(constants, request)
  return {
    authRegSection: "auth"
    firstVisitRegSection: "visit"
    guestUserHasAgeRegSection: "has_age"
    
    constants: constants
    request: request

    'public methods
    getAuthInfo: tubiAuth_getAuthInfo
    getFirstVisit: tubiAuth_getFirstVisit
    setFirstVisit: tubiAuth_setFirstVisit
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

    'private methods
    saveAuthInfo: tubiAuth_saveAuthInfo
    deleteAuthInfo: tubiAuth_deleteAuthInfo
    checkIfAuthExpired: tubiAuth_checkIfAuthExpired
    requestTokenRefresh: tubiAuth_requestTokenRefresh
    requestTokenTransfer: tubiAuth_requestTokenTransfer
    handleRefreshResponse: tubiAuth_handleRefreshResponse
    updateAuthInfo: tubiAuth_updateAuthInfo
    formatAuthInfoFromServer: tubiAuth_formatAuthInfoFromServer
    
    regRead: tubiAuth_regRead
    regReadAll: tubiAuth_regReadAll
    regWrite: tubiAuth_regWrite
    regDelete: tubiAuth_regDelete
  }
End Function


'returns invalid or an assocArray that looks like the following
'authInfo = {
'  refreshToken: someRefreshToken(String)
'  accessToken: someAccessToken(String)
'  expireTime: numberOfSecondsUntilExpires(Integer)
'  userId: userId(Integer as String)
'  fn: firstName(String)
'  ln: lastName(String)
'  name: name(String)
'  authType: analyticsAuthType(String)
'  has_age: true indicates Tubi has an age on record and the age is >= 13 (Boolean)
'}
Function tubiAuth_getAuthInfo()
  authInfo = m.regReadAll(m.authRegSection) 'returns empty assocArray if nothing in the auth registry
  newAuthInfo = invalid
  if authInfo.expireTime <> invalid   'used as test to determine if we have any auth info in the auth registry
    authInfo.expireTime = authInfo.expireTime.toInt()

    if type(authInfo.hasAge) = "roString" or type(authInfo.hasAge) = "String"
      if authInfo.hasAge = "true"
        authInfo.hasAge = true
      else if authInfo.hasAge = "false"
        authInfo.hasAge = false
      end if
    end if

    isExpired = m.checkIfAuthExpired(authInfo)

    if isExpired = true
      newAuthInfo = m.refreshAuthToken(authInfo, 3) 'can return invalid
    else
      newAuthInfo = authInfo
    end if
  end if

  return newAuthInfo  'can return invalid
End Function


'checks device registry for first visit value, if none exists, set today's value as the first visit value.
'returns stored first visit value (number of days since Unix epoch) or today's value
Function tubiAuth_getFirstVisit()
  firstVisit = m.regRead("firstVisit", m.firstVisitRegSection)
  if firstVisit <> invalid
    firstVisit = firstVisit.toInt()
  else
    firstVisit = m.setFirstVisit()
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


'parses auth info from the server and saves it into the registry for further access
'returns invalid or the authInfo assocArray that was successfully saved into the registry:
'authInfo = {
'  refreshToken: someRefreshToken(String)
'  accessToken: someAccessToken(String)
'  expireTime: numberOfSecondsUntilExpires(Integer as String)
'  userId: userId(Integer as String)
'  fn: firstName(String)
'  ln: lastName(String)
'  name: name(String)
'  authType: analyticsAuthType(String)
'  has_age: true indicates Tubi has an age on record and the age is >= 13 (Boolean)
'}
'@serverAuthInfo: assocArray of auth info as received from the server
Function tubiAuth_handleRegistration(serverAuthInfo)
  authInfo = m.formatAuthInfoFromServer(serverAuthInfo)
  authInfo = m.saveAuthInfo(authInfo)

  return authInfo
End Function



'requests and receives a new auth token from the server
'this is a helper Function that wraps tubiAuth_requestTokenRefresh_ and tubiAuth_handleRefreshResponse_
'this Function behaves synchronously and blocks until a response is received or the timeout is reached
'@authInfo = {
'  refreshToken: someRefreshToken(String)
'  accessToken: someAccessToken(String)
'  expireTime: numberOfSecondsUntilExpires(Integer as String)
'  userId: userId(Integer as String)
'  fn: firstName(String)
'  ln: lastName(String)
'  name: name(String)
'  authType: analyticsAuthType(String)
'  has_age: true indicates Tubi has an age on record and the age is >= 13 (Boolean)
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
  if type(authToken) = "String" or type(authToken) = "roString"
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
  if authInfo <> invalid and authInfo.accessToken <> invalid
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
    if options.params["user_id"] = invalid
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
  end if

  return authReq
End Function


' @hasAge: boolean, backend response field "has_age". True indicates the user has an age
'                   associated with the account, and the age is >= 13.
Function tubiAuth_updateAuthInfoWithAge(hasAge)
  authInfo = m.getAuthInfo()
  if authInfo <> invalid
    authInfo.hasAge = hasAge.toStr()

    ' getAuthInfo() returns an int, but saveAuthInfo() expects a string for expire time
    if type(authInfo.expireTime) = "roInteger" or type(authInfo.expireTime) = "Integer"
      authInfo.expireTime = authInfo.expireTime.toStr()
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
  if type(hasAge) <> "roBoolean" and type(hasAge) <> "Boolean"
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
'  fn: firstName(String)
'  ln: lastName(String)
'  name: name(String)
'  authType: analyticsAuthType(String)
'  has_age: true indicates Tubi has an age on record and the age is >= 13 (Boolean)
'}
Function tubiAuth_saveAuthInfo(authInfo)
  if authInfo <> invalid and authInfo.refreshToken <> invalid and authInfo.accessToken <> invalid and authInfo.expireTime <> invalid  and (type(authInfo.expireTime) = "String" or type(authInfo.expireTime) = "roString") and authInfo.userId <> invalid
    for each key in authInfo
      value = authInfo[key]
      if type(value) <> "roString"
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
'  fn: firstName(String)
'  ln: lastName(String)
'  name: name(String)
'  authType: analyticsAuthType(String)
'  has_age: true indicates Tubi has an age on record and the age is >= 13 (Boolean)
'}
Function tubiAuth_checkIfAuthExpired(authInfo)
  isExpired = true

  dateTime = CreateObject("roDateTime")
  timeInSecs = dateTime.asSeconds()

  if (type(authInfo.expireTime) = "Integer" or type(authInfo.expireTime) = "roInteger") and timeInSecs < authInfo.expireTime
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


'used to get a new auth token when the current auth token has expired
Function tubiAuth_requestTokenRefresh(authInfo, port)
  body = {
    user_id: authInfo.userId
    device_id: m.constants.deviceInfo.deviceId
    platform: m.constants.platform
  }
  bodyJson = FormatJson(body)

  headers = m.getAuthHeaders(authInfo.refreshToken)

  reqOptions = {
    method: "POST"
    body: bodyJson
    headers: headers
    retries: 0
  }

  newTokenReq = m.request.createAsync(m.constants.urls.users.refreshToken, "getNewAccessToken", reqOptions)
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
    user_id: externalAuthInfo.userId
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

  newTokenReq = m.request.createAsync(m.constants.urls.users.transferToken, "getRefreshTokenFromTransfer", reqOptions)
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
  if serverAuthInfo.first_name <> invalid then authInfo.fn = serverAuthInfo.first_name
  if serverAuthInfo.last_name <> invalid then authInfo.ln = serverAuthInfo.last_name
  if serverAuthInfo.name <> invalid then authInfo.name = serverAuthInfo.name
  if serverAuthInfo.authType <> invalid then authInfo.authType = serverAuthInfo.authType
  if serverAuthInfo.has_age <> invalid then authInfo.hasAge = serverAuthInfo.has_age.toStr()

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
