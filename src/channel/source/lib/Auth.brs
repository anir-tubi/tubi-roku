'@constants: assocArray, the constants object returned from getContstants()
'@request: assocArray, the object returned from TubiRequest()
Function TubiAuth(constants, request)
  return {
    authRegKey: "auth"
    
    constants: constants
    request: request

    'public methods
    getAuthInfo: tubiAuth_getAuthInfo
    handleRegistration: tubiAuth_handleRegistration
    oneTimeLoginMigration: tubiAuth_oneTimeLoginMigration
    logout: tubiAuth_deleteAuthInfo_
    refreshAuthToken: tubiAuth_refreshAuthToken
    getAuthHeaders: tubiAuth_getAuthHeaders
    createAuthRequest: tubiAuth_createAuthRequest

    'private methods
    saveAuthInfo: tubiAuth_saveAuthInfo_
    deleteAuthInfo: tubiAuth_deleteAuthInfo_
    checkIfAuthExpired: tubiAuth_checkIfAuthExpired_
    requestTokenRefresh: tubiAuth_requestTokenRefresh_
    handleRefreshResponse: tubiAuth_handleRefreshResponse_
    updateAuthInfo: tubiAuth_updateAuthInfo_
    formatAuthInfoFromServer: tubiAuth_formatAuthInfoFromServer_
    
    'used for old logins, should not be used except in oneTimeLoginMigration
    getUserData: tubiAuth_getUserData_
    deleteUserData: tubiAuth_deleteUserData_
    userDataFromString: tubiAuth_userDataFromString_
  }
End Function


'returns invalid or an assocArray that looks like the following
'authInfo = {
'   refreshToken: someRefreshToken(String)
'   accessToken: someAccessToken(String)
'   expireTime: numberOfSecondsUntilExpires(Integer)
'   userId: userId(Integer as String)
'}
function tubiAuth_getAuthInfo()
  authInfo = RegReadAll(m.authRegKey) 'returns empty assocArray if nothing in the auth registry
  newAuthInfo = invalid
  if authInfo.expireTime <> invalid   'used as test to determine if we have any auth info in the auth registry
    authInfo.expireTime = authInfo.expireTime.toInt()
    isExpired = m.checkIfAuthExpired(authInfo)

    if isExpired = true
      newAuthInfo = m.refreshAuthToken(authInfo, 3) 'can return invalid
    else
      newAuthInfo = authInfo
    end if
  end if

  return newAuthInfo  'can return invalid
end function


'parses auth info from the server and saves it into the registry for further access
'returns invalid or the authInfo assocArray that was successfully saved into the registry:
'authInfo = {
'   refreshToken: someRefreshToken(String)
'   accessToken: someAccessToken(String)
'   expireTime: numberOfSecondsUntilExpires(Integer as String)
'   userId: userId(Integer as String)
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
'   refreshToken: someRefreshToken(String)
'   accessToken: someAccessToken(String)
'   expireTime: numberOfSecondsUntilExpires(Integer or Integer as String)
'   userId: userId(Integer as String)
'}
'@timeout: integer, the max amount of time to wait for a response from the server
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
        newAuthInfo = m.updateAuthInfo(newAccess, authInfo)
        newAuthInfo = m.saveAuthInfo(authInfo) 'returns invalid if not saved to the registry

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


'@authToken can be the server access_token or refresh_token depending on the call being made
function tubiAuth_getAuthHeaders(authToken)
  if type(authToken) = "String" or type(authToken) = "roString"
    headers = {
      Authorization: "Bearer " + authToken
    }
    headers.append(m.constants.headers.json)

    return headers
  else
    return invalid
  end if
end function


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
function tubiAuth_createAuthRequest(url as String, name = "" as String, options={} as Object) as Object
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

    authReq = m.request.createAsync(url, name, options)
    authReq.getAuthHeaders = m.getAuthHeaders
    authReq.refreshAuthToken = m.refreshAuthToken
    authReq.requestTokenRefresh = m.requestTokenRefresh
    authReq.updateAuthInfo = m.updateAuthInfo
    authReq.saveAuthInfo = m.saveAuthInfo
    authReq.handleRefreshResponse = m.handleRefreshResponse
    authReq.constants = m.constants
    authReq.request = m.request
    authReq.authInfo = authInfo
  end if

  return authReq
end function


'@authInfo = {
'   refreshToken: someRefreshToken(String)
'   accessToken: someAccessToken(String)
'   expireTime: numberOfSecondsUntilExpires(Integer as String)
'   userId: userId(Integer as String)
'}
function tubiAuth_saveAuthInfo_(authInfo)
  if authInfo <> invalid and authInfo.refreshToken <> invalid and authInfo.accessToken <> invalid and authInfo.expireTime <> invalid  and (type(authInfo.expireTime) = "String" or type(authInfo.expireTime) = "roString") and authInfo.userId <> invalid
    for each key in authInfo
      RegWrite(key, authInfo[key], m.authRegKey)
    end for
  else
    authInfo = invalid
  end if
  return authInfo
end function


function tubiAuth_deleteAuthInfo_()
  authSection = CreateObject("roRegistry")
  authSection.delete(m.authRegKey)
  authSection.flush()
end function


'should only be called by getAuthInfo
'returns true if expired and false if not expired
'@authInfo = {
'   refreshToken: someRefreshToken(String)
'   accessToken: someAccessToken(String)
'   expireTime: numberOfSecondsUntilExpires(Integer)
'   userId: userId(Integer as String)
'}
function tubiAuth_checkIfAuthExpired_(authInfo)
  isExpired = true

  dateTime = CreateObject("roDateTime")
  timeInSecs = dateTime.asSeconds()

  if (type(authInfo.expireTime) = "Integer" or type(authInfo.expireTime) = "roInteger") and timeInSecs < authInfo.expireTime
    isExpired = false
  end if

  return isExpired
end function


'returns an authInfo object that is ready to be sent into the registry (expireTime is a string representation of an integer)
'@newAccess: assocArray, contains the new auth token and expire time as sent from the server during a refresh token action
'@authInfo: assocArray, authInfo as pulled from the registry with the old auth token and expire time
function tubiAuth_updateAuthInfo_(newAccess, authInfo)
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
end function


'used to get a new auth token when the current auth token has expired
function tubiAuth_requestTokenRefresh_(authInfo, port)
  body = {
    user_id: authInfo.userId
    device_id: m.constants.deviceInfo.deviceId
    platform: m.constants.settings.platformName
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
end function


'@refreshRequest: assocArray, a reqest object as created by tubiRequest().createAsyncHTTPRequest()
function tubiAuth_handleRefreshResponse_(msg, refreshRequest)
  newAccess = invalid

  responseInfo = refreshRequest.handleEvent(msg)

  if responseInfo <> invalid and responseInfo.response <> invalid and responseInfo.response.data <> invalid
    if responseInfo.response.data.len() > 0
      newAccess = ParseJson(responseInfo.response.data)
    end if
  end if

  return newAccess
end function


'used when getting back a response from the server after a successful registration.
'We need to format the information to match what we store in the registry
function tubiAuth_formatAuthInfoFromServer_(serverAuthInfo)
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

  return authInfo
end function


'checks if old registration data exists in the registry (device memory)
'if so, get a new auth info set and delete the old registration data
function tubiAuth_oneTimeLoginMigration()
  migratePort = CreateObject("roMessagePort")

  authInfo = {}
  oldUserData = m.getUserData()
  if oldUserData <> invalid and oldUserData.token <> invalid and oldUserData.token.len() > 0 'token is the userId
    
    migrateToken = m.constants.settings.migrateToken
    body = {
      user_id: oldUserData.token
      device_id: m.constants.deviceInfo.deviceId
      platform: "roku"
    }
    bodyJson = FormatJson(body)
    headers = m.getAuthHeaders(migrateToken)
    ' m.sendAsyncRequest(url, migratePort, "oneTimeLoginMigration", "POST", true, bodyJson, headers)

    reqOptions = {
      method: "POST"
      body: body
      headers: headers
    }

    newMigrationReq = m.request.createAsync(m.constants.urls.users.migrateLogin, "oneTimeLoginMigration", reqOptions)
    reqSent = newMigrationReq.start(migratePort)

    if reqSent = true
      authInfo = invalid
      
      while true
        msg = wait(0, migratePort)
        
        responseInfo = newMigrationReq.handleEvent(msg)

        if responseInfo <> invalid and responseInfo.response <> invalid and responseInfo.response.data <> invalid and responseInfo.response.data.len() > 0
          newAccess = ParseJson(responseInfo.response.data)

          if newAccess.refresh_token <> invalid
            'since we now have new auth info, save it to memory and delete the old login info

            'format and save the auth info returned from the server
            authInfo = m.handleRegistration(newAccess)

            if authInfo <> invalid
              m.deleteUserData()
            end if

          end if
        end if
      end while
    end if
  end if

  return authInfo
end function


'gets the old user data - only necessary for doing one time login registration syncs
Function tubiAuth_getUserData_()
  str = RegRead("userdata")
  if(str <> invalid)
    return m.userDataFromString(str)
  end if
  return invalid
End Function


'deletes the old user data - only necessary for doing one time login registration syncs
Function tubiAuth_deleteUserData_()
    RegDelete("userdata")
End Function


'parses the old user data as stored in the registry into an assocArray - only needed for doing one time login registration syncs
Function tubiAuth_userDataFromString_(str)
  r = CreateObject("roRegex", ",", "")
  a = r.Split(str)
  num = a.count()
  if(num > 2)
    return {token: a[0], fn: a[1], ln: a[2]}
  end if
  return invalid
End Function
