function AdriseUtils (appName)
  return {
    getTextFile: adriseUtils_getTextFile
    getXml: adriseUtils_getXml
    sendAsyncRequest: adriseUtils_sendAsyncRequest
    sendAuthAsyncRequest: adriseUtils_sendAuthAsyncRequest
    getAsyncResponse: adriseUtils_getAsyncResponse
    showErrorMessage: adriseUtils_showErrorMessage
    showAdLoadingLayer: adriseUtils_showAdLoadingLayer
    showImageOnCanvas: adriseUtils_showImageOnCanvas
    channelStoreGoToAPP: adriseUtils_channelStoreGoToApp
    trackEvent: adriseUtils_trackEvent
    getTrackingTags: adriseUtils_getTrackingTags
    getTrackData: adriseUtils_getTrackData
    setProxy: adriseUtils_setProxy
    buildUrl: adriseUtils_buildUrl
    proxyUrl: invalid
    proxyFolder: invalid
    supportsSubtitles: adriseUtils_supportsSubtitles
    getAuthInfo: adriseUtils_getAuthInfo
    saveAuthInfo: adriseUtils_saveAuthInfo
    deleteAuthInfo: adriseUtils_deleteAuthInfo
    checkIfAuthExpired: adriseUtils_checkIfAuthExpired
    getNewAccessToken: adriseUtils_getNewAccessToken
    getAuthHeaders: adriseUtils_getAuthHeaders
    formatAuthInfoFromServer: adriseUtils_formatAuthInfoFromServer
    oneTimeLoginMigration: adriseUtils_oneTimeLoginMigration
    oneTimeBookmarkSync: adriseUtils_oneTimeBookmarkSync
    oneTimePreviouslyViewedSync: adriseUtils_oneTimePreviouslyViewedSync
    updateBookmarks: adriseUtils_updateBookmarks
    updatePreviouslyViewed: adriseUtils_updatePreviouslyViewed
    sluggify: adriseUtils_sluggify
    deviceInfo: adriseUtils_getDeviceInfo()
    appName: appName

    generateUniqueHex: function(length, uuid=false)
        uid = ""
        hexChars = "0123456789ABCDEF"
        if uuid = true
          hexChars = "0123456789abcdef"
        end if
        for i = 1 to length
            uid = uid + hexChars.Mid(Rnd(16) - 1, 1)
        next
        return uid
    end function

    generateUuid: function() 'conforms to the "random" variant of the UUID standard'
      allowed = "89ab"
      pre = allowed.Mid(Rnd(4) - 1, 1)

      first = m.generateUniqueHex(8, true)
      second = m.generateUniqueHex(4, true)
      third = "4" + m.generateUniqueHex(3, true)
      fourth = pre + m.generateUniqueHex(3, true)
      fifth = m.generateUniqueHex(12, true)
      uuid = first + "-" + second + "-" + third + "-" + fourth + "-" + fifth

      return uuid
    end function

    'returns a unique ID string made up of 12 randomly generated hex characters
    getUniqueId: function ()
      uid = RegRead("uniqueid")
      if (uid <> invalid)
        return uid
      end if
      uid = m.generateUniqueHex(12)
      RegWrite("uniqueid", uid)
      return uid
    end function

    'return an associative array of all saved content from the registry section named by they playlistType
    getUserPlaylistContent: function(playlistType)
      return RegReadAll(playlistType) 'called from generalUtilities
    end function

    'check if a specific piece of content has been added to a user playlist (bookmarks, previously viewed, etc.)
    checkUserPlaylistContent: function(id, playlistType, contentType)
      if playlistType <> invalid and id <> invalid and contentType <> invalid
      'prepend a letter so we don't have a collision in case someone bookmarks a series and movie with the same id
        if contentType = "video"
          id = "v" + id
        else if contentType = "series"
          id = "s" + id
        else
          print "playlist content not updated"
          return false
        end if
        savedContentType = RegRead(id, playlistType)
        if savedContentType <> invalid
          return true
        else
          return false
        end if
      end if
    end function

    getSavedContentData: function (contentId)
      out = {pos: 0, time: 0}

      str = RegRead(contentId)

      if str = invalid
        return out
      end if

      r = CreateObject("roRegex", ",", "")
      a = r.Split(str)
      num = a.count()

      if(num>0)
        out.pos = a[0].toInt()
      end if
      if (num > 1)
        out.time = a[1].toInt()
      end if
      return out
    end function

    'data is a comma delimited string - "userId,firstname,lastname"
    saveUserData: function (data)
        RegWrite("userdata", data)
    end function

    deleteUserData: function ()
        RegDelete("userdata")
    end function

    userDataFromString: function(str)
      r = CreateObject("roRegex", ",", "")
      a = r.Split(str)
      num = a.count()
      if(num > 2)
        return {token: a[0], fn: a[1], ln: a[2]}
      end if
      return invalid
    end function

    getUserData: function ()
      str = RegRead("userdata")
      if(str <> invalid)
        return m.userDataFromString(str)
      end if
      return invalid
    end function

    getRunCount: function ()
      countStr = RegRead("runcount")
      if (countStr <> invalid)
        count = countStr.toInt()
        RegWrite("runcount", toStr(count + 1))
        return count
      end if
      RegWrite("runcount", "1")
      return 0
    end function

    cancelAsyncRequest: function(id) as Object
        which = m.asynchRequests[str(id)]
        if which <> invalid
          which.AsyncCancel()
          print "cancelled async " ; id
          m.asynchRequests.delete(str(id))
        else
          print "failed to cancelled async " ; id
        end if
      end function

    getSubscribed: function()
        return GetGlobalAA().app.player.subscription
      end function

    getRegisterScreen: function()
        return GetGlobalAA().app.registerScreen
      end function

    getSettings: function()
        return GetGlobalAA().app.settings
      end function

  }
end function

'should always return a roAssocArray {} (which can be empty)
function adriseUtils_getAuthInfo()
  authInfo = RegReadAll("auth")
  if authInfo.expireTime <> invalid
    authInfo.expireTime = val(authInfo.expireTime)
  end if
  return authInfo
end function


'@authInfo = {
'   refreshToken: someRefreshToken(String)
'   accessToken: someAccessToken(String)
'   expireTime: numberOfSecondsUntilExpires(Integer as String)
'   userId: userId(Integer as String)
'}
function adriseUtils_saveAuthInfo(authInfo)
  for each key in authInfo
    RegWrite(key, authInfo[key], "auth")
  end for
end function

function adriseUtils_deleteAuthInfo()
  authSection = CreateObject("roRegistry")
  authSection.delete("auth")
  authSection.flush()
end function

function adriseUtils_checkIfAuthExpired(authInfo)
  dateTime = CreateObject("roDateTime")
  timeInSecs = dateTime.asSeconds()
  if authInfo.expireTime <> invalid and timeInSecs >= authInfo.expireTime
    newAccess = m.getNewAccessToken(authInfo)
    ' print "new Access Info "; type(newAccess); " "; newAccess.expires_in
    if newAccess <> invalid and newAccess.expires_in <> invalid
      dateTime.mark()
      authInfo.expireTime = dateTime.asSeconds() + newAccess.expires_in
      authInfo.expireTime = authInfo.expireTime.ToStr()
      authInfo.accessToken = newAccess.access_token
      m.saveAuthInfo(authInfo)
    end if
  end if
  return authInfo
end function

function adriseUtils_getNewAccessToken(authInfo)
  settings = m.getSettings()
  accessTokenPort = CreateObject("roMessagePort")
  body = {
    user_id: authInfo.userId
    device_id: m.deviceInfo.deviceId
    platform: settings.platformName
  }
  bodyJson = FormatJson(body)
  headers = {
    "Content-Type": "application/json"
    Authorization: "Bearer " + authInfo.refreshToken
  }
  reqId = m.sendAsyncRequest(settings.getAccessTokenUrl, accessTokenPort, "getNewAccessToken", "POST", true, bodyJson, headers)

  while true
    msg = wait(0, accessTokenPort)
    if type(msg) = "roUrlEvent"
      response = m.getAsyncResponse(msg, 0)
      print "GET NEW ACCESS RESPONSE "; response
      if response.data <> invalid and response.data.len() > 0
        newAccess = ParseJson(response.data)
      else
        newAccess = invalid
      end if
      return newAccess
    end if
  end while
end function

function adriseUtils_formatAuthInfoFromServer(serverAuthInfo)
  clock = CreateObject("roDateTime")
  secondsToNow = clock.AsSeconds()
  authInfo = {}

  if serverAuthInfo.refresh_token <> invalid then authInfo.refreshToken = serverAuthInfo.refresh_token
  if serverAuthInfo.access_token <> invalid then authInfo.accessToken = serverAuthInfo.access_token
  if serverAuthInfo.expires_in <> invalid then authInfo.expireTime = (serverAuthInfo.expires_in + secondsToNow).ToStr()
  if serverAuthInfo.user_id <> invalid then authInfo.userId = serverAuthInfo.user_id.toStr()
  if serverAuthInfo.first_name <> invalid then authInfo.fn = serverAuthInfo.first_name
  if serverAuthInfo.last_name <> invalid then authInfo.ln = serverAuthInfo.last_name

  return authInfo
end function

'@authToken can be the server access_token or refresh_token depending on the call being made
function adriseUtils_getAuthHeaders(authToken)
  return {
    "Content-Type": "application/json"
    Authorization: "Bearer " + authToken 
  }
end function


'checks if old registration data exists in the registry (device memory)
'if so, get a new auth info set and delete the old registration data
function adriseUtils_oneTimeLoginMigration()
  settings = m.getSettings()
  migratePort = CreateObject("roMessagePort")

  authInfo = {}
  oldUserData = m.getUserData()
  if oldUserData <> invalid and oldUserData.token <> invalid and oldUserData.token.len() > 0 'token is the userId
    migrateToken = settings.migrateToken
    url = settings.migrateLoginUrl
    body = {
      user_id: oldUserData.token
      device_id: m.deviceInfo.deviceId
      platform: "roku"
    }
    bodyJson = FormatJson(body)
    headers = m.getAuthHeaders(migrateToken)
    m.sendAsyncRequest(url, migratePort, "oneTimeLoginMigration", "POST", true, bodyJson, headers)

    while true
      msg = wait(0, migratePort)
      if type(msg) = "roUrlEvent"
        response = m.getAsyncResponse(msg, 0)
        if response.data <> invalid and response.data.len() > 0
          newAccess = ParseJson(response.data)
          if newAccess.refresh_token <> invalid
            authInfo = m.formatAuthInfoFromServer(newAccess)

            'since we now have new auth info, save it to memory and delete the old login info
            m.saveAuthInfo(authInfo)
            m.deleteUserData()
          end if
        end if
        exit while
      end if
    end while
  end if
  
  return authInfo
end function

'gets all bookmarks that have previously been stored locally, and sends them to the server
'this should only happen once, as the whold bookmark registry will be deleted upon adding bookmarks to the server
function adriseUtils_oneTimeBookmarkSync()
  settings = m.getSettings()
  authInfo = m.getAuthInfo()
  migratePort = CreateObject("roMessagePort")

  'get all the local bookmarks from device registry/memory
  localBookmarks = m.getUserPlaylistContent(settings.bookmarkRegistry)
  if localBookmarks.count() = 0
    return invalid
  end if
  
  sendBookmarks = []
  for each bookmark in localBookmarks
    bookmarkStarter = Left(bookmark, 1)
    if bookmarkStarter = "v"
      bookmarkType = "movie"
    else if bookmarkStarter = "s"
      bookmarkType = "series"
    end if
    bookmarkId = Mid(bookmark, 2, bookmark.len())
    sendBookmarks.push({
      user_id: authInfo.userId
      content_id: bookmarkId
      content_type: bookmarkType
    })
  end for

  url = settings.bookmarksUrl
  bodyJson = FormatJson(sendBookmarks)

  authInfo = m.checkIfAuthExpired(authInfo)
  headers = m.getAuthHeaders(authInfo.accessToken)
  m.sendAsyncRequest(url, migratePort, "oneTimeBookmarkMigration", "POST", true, bodyJson, headers)

  while true
    msg = wait(0, migratePort)
    if type(msg) = "roUrlEvent"
      response = m.getAsyncResponse(msg, 0)
      print "GET NEW Bookmark Migration RESPONSE "; response
      if response.data <> invalid and response.data.len() > 0 and response.responseCode = 200
        'dont' really care about the response, as long as it's valid, since we will get all bookmarks later
        'since we successfully send the bookmarks data, we can delete the old bookmarks info

        authSection = CreateObject("roRegistry")
        authSection.delete(settings.bookmarkRegistry)
        authSection.flush()

      end if
      exit while
    end if
  end while
end function


'gets any content saved in the previously viewed registry, and sends it to the server - syncing previouslyViewed/history
function adriseUtils_oneTimePreviouslyViewedSync()
  settings = m.getSettings()
  authInfo = m.getAuthInfo()
  cp = GetGlobalAA().app.cp

  'get all nowPosi (old view history) from the device registry
  localNowPos = m.getUserPlaylistContent(invalid) 'super hacky, but it works...(except you get some other junk that you need to separate out)

  'first filter out any non nowPos and separate the time the nowPos was save from the nowPos itself
  for each id in localNowPos
    if Val(id) = 0
      localNowPos.delete(id)
    else
      nowPosPlus = localNowPos[id]
      separated = nowPosPlus.Tokenize(",")
      localNowPos[id] = Int(Val(separated[0]))
    end if
  end for

  if localNowPos.count() = 0
    return invalid
  end if

  'show a dialog letting the user know the one time sync might take a while
  dialog = CreateObject("roMessageDialog")
  dialog.setTitle("Sending Queue and View History To Tubi TV Server")
  dialog.setText("This may take a few minutes. It will only happen once. Once sending is complete, you will be able to access your Tubi TV Queue and View History on all your devices!")
  dialog.show()

  'get all previously viewed content from device memory/registry
  prevViewed = m.getUserPlaylistContent(settings.previouslyViewedRegistry)

  toSend = []
  seriesIds = []

  for each prevViewedId in prevViewed
    cid = Mid(prevViewedId, 2)

    'we have a video
    if Left(prevViewedId, 1) = "v"
      if localNowPos[cid] <> invalid
        toSend.push({
          user_id: authInfo.userId
          content_id: cid
          content_type: "movie"
          position: localNowPos[cid]
        })
      end if

    'we have a series - we'll accumulate all the series ids so we just make one call to the server to get info for all the series
    'we'll iterate over all the series and add them to toSend as necessary in a subsequent loop
    else if Left(prevViewedId, 1) = "s"
      seriesIds.push(cid)
    end if
  end for

  seriesFromServer = cp.getSeriesFromServer(seriesIds)

  if seriesFromServer <> invalid
    'add all the view histories for the series' episodes
    seriesToSend = []
    for each seriesId in seriesIds
      serverSeriesId = "0" + seriesId
      series = seriesFromServer[serverSeriesId]

      if series <> invalid and series.children <> invalid
        for each season in series.children
          if season.children <> invalid
            for each episode in season.children
              if episode.id <> invalid and localNowPos[episode.id] <> invalid
                seriesToSend.push({
                  user_id: authInfo.userId
                  content_id: episode.id
                  content_type: "episode"
                  position: localNowPos[episode.id]
                  parent_id: seriesId
                })
              end if
            end for
          end if
        end for
      end if
    end for

    toSend.Append(seriesToSend)
  end if

  migratePort = createObject("roMessagePort")
  url = settings.previouslyViewedUrl
  bodyJson = FormatJson(toSend)
  authInfo = m.checkIfAuthExpired(authInfo)
  headers = m.getAuthHeaders(authInfo.accessToken)
  m.sendAsyncRequest(url, migratePort, "oneTimePreviouslyViewedMigration", "POST", true, bodyJson, headers)

  while true
    msg = wait(0, migratePort)
    if type(msg) = "roUrlEvent"
      response = m.getAsyncResponse(msg, 0)
      if response.data <> invalid and response.data.len() > 0 and response.responseCode = 200
        'dont' really care about the response, as long as it's valid, since we will get all previously viewed/history later
        'since we successfully send the previously viewed data, we can delete the old previously viewed/history info

        'removes all ids from the old view history
        for each previouslyViewedId in localNowPos
          RegDelete(previouslyViewedId)
        end for

        'delete any previously viewed items... we don't need them anymore, will sync with the saved positions instead
        authSection = CreateObject("roRegistry")
        authSection.delete(settings.previouslyViewedRegistry)
        authSection.flush()

      end if
      exit while
    end if
  end while

  'close the dialog
  dialog.close()

end function


'sends a bookmark/history item to the server
'@id: stringified content id of series or video that we are adding/deleting
  'if add, @id should be the contentId
  'if delete @id should be the 'bookmark server id'
'@action: string (should be "add" or "delete")
'@contentType: string (should be "series" or "movie")
'@port: roMessagePort that will be used to listen for the async response - probably the port defined in detailsPage.show()
function adriseUtils_updateBookmarks(id, action, contentType, port)
  settings = m.getSettings()

  authInfo = m.getAuthInfo()  'from memory
  
  if authInfo.accessToken = invalid
    return invalid
  end if

  authInfo = m.checkIfAuthExpired(authInfo)
  headers = m.getAuthHeaders(authInfo.accessToken)
  body = {
    user_id: authInfo.userId
    content_id: id
    content_type: contentType
  }
  bodyJson = FormatJson(body)

  verb = ""
  url = settings.bookmarksUrl
  
  if action = "add"
    verb = "POST"
  else if action = "delete"
    bodyJson = invalid
    verb = "DELETE"
    url = url + "/" + id
  end if

  requestId = m.sendAsyncRequest(url, port, action+"Bookmark", verb, true, bodyJson, headers)
  
  if requestId = 0
    return invalid
  end if
  
  return requestId
end function



'sends a previously viewed/history item to the server
'@id: stringified content id of series or video that we are adding/deleting
  'if add, @id should be the contentId
  'if delete @id should be the 'previously viewed server id
'@parentId: stringified content id of the parent series id for an episode - should be invalid for deletes
'@position: int(player positino or nowPos in seconds) - should be invalid for deletes
'@action: string (should be "add" or "delete")
'@contentType: string (should be "series" or "movie") - should be invalid for deletes
'@port: roMessagePort that will be used to listen for the async response - probably the port defined in detailsPage.show()
function adriseUtils_updatePreviouslyViewed(id, parentId, position, action, contentType, port)
  settings = m.getSettings()

  authInfo = m.getAuthInfo()  'from memory

  if authInfo.accessToken = invalid
    return invalid
  end if
  
  authInfo = m.checkIfAuthExpired(authInfo)
  headers = m.getAuthHeaders(authInfo.accessToken)

  body = {
    user_id: authInfo.userId
    content_id: id
    content_type: contentType
    position: position
  }

  if parentId <> invalid
    body.parent_id = parentId
  end if
  bodyJson = FormatJson(body)

  verb = ""
  url = settings.previouslyViewedUrl
  
  if action = "add"
    verb = "POST"
  else if action = "delete"
    bodyJson = invalid
    verb = "DELETE"
    url = url + "/" + id
  end if

  requestId = m.sendAsyncRequest(url, port, action+"History", verb, true, bodyJson, headers)

  if requestId = 0
    return invalid
  end if

  return requestId
end function


function adriseUtils_setProxy(url, folder)
  if url <> "none" and url <> "" and url <> invalid and folder <> "none" and folder <> "" and folder <> invalid
    m.proxyUrl = url
    m.proxyFolder = folder
  end if
end function

' --------------------------------------------------------
' .buildUrl (orig As String ) As String
'  accounts for proxy
' --------------------------------------------------------
function adriseUtils_buildUrl(orig As String, name as String, httpObj as Object) As String
  if m.proxyUrl <> invalid
    escapedUrl = httpObj.escape(orig)
    return m.proxyUrl + "/adriseProxy?url=" + escapedUrl + "&type=" + name + "&dir=" + m.proxyFolder
  end if
  return orig
end function

' --------------------------------------------------------

' --------------------------------------------------------
function adriseUtils_supportsSubtitles()
  if m.deviceInfo.firmwareVersion >= 3.9
    return true
  else
    return false
  end if
end function


' --------------------------------------------------------
' .getXml
' --------------------------------------------------------
' name is optional, for debugging (prints url and name to debug console)
function adriseUtils_getXml(url as String, name = "" as String, auth = false As Boolean) as Object
  text = m.getTextFile(url, name, auth)
  xml = CreateObject("roXMLElement")

  if not xml.Parse(text)
    if name <> ""
      print name + " (error): " + url + " (" + str(len(text)) + ")"
    end if
    return invalid
  end if

  return xml
end function

' --------------------------------------------------------
' .getTextFile
' --------------------------------------------------------
function adriseUtils_getTextFile(url as String, name = "" as String, auth = false As Boolean) as Object
  h = CreateObject("roUrlTransfer")
  h.SetPort(CreateObject("roMessagePort"))

  m.log.debug(invalid, "clientDebug", name, url)
  print ""

  if url.Left(5) = "https"
    h.SetCertificatesFile("common:/certs/ca-bundle.crt")
    h.AddHeader("X-Roku-Reserved-Dev-Id", "")
  end if

  url = m.buildUrl(url, name, h)
  h.SetUrl(url)

  'add auth header
  if auth
    authInfo = m.getAuthInfo()  'from memory
    if authInfo.accessToken <> invalid
      authInfo = m.checkIfAuthExpired(authInfo)
      headers = m.getAuthHeaders(authInfo.accessToken)
      for each headerType in headers
        h.addHeader(headerType, headers[headerType])
      end for
    end if
  end if

  h.AddHeader("Content-Type", "application/x-www-form-urlencoded")
  h.AddHeader("User-Agent", m.deviceInfo.userAgent + " " + m.deviceInfo.model)
  h.EnableEncodings(true)
  rsp = h.GetToString()
  return rsp
end function

' --------------------------------------------------------
' .sendAuthAsyncRequest
' --------------------------------------------------------
function adriseUtils_sendAuthAsyncRequest(url as String, port, name = "" as String, reqType = invalid, isHttps = false, body = invalid, headers = invalid) as Integer
  authInfo = m.getAuthInfo()  'from memory
  if authInfo.accessToken <> invalid
    authInfo = m.checkIfAuthExpired(authInfo)
    authHeaders = m.getAuthHeaders(authInfo.accessToken)
    if headers = invalid then headers = {}
    headers.append(authHeaders)
  end if
  return m.sendAsyncRequest(url, port, name, reqType, isHttps, body, headers)
end function

' --------------------------------------------------------
' .sendAsyncRequest
' --------------------------------------------------------
' url: the url
' port: port that is being monitored with wait()
' name: string used for logging purposes in side load console
' reqType: string with the request type (GET, POST, PUT, DELETE)
' isHttps: boolean - adds proper certificates if true
' body: string of info to send with request
' headers: associative array of headers to add like: {Content-Type: "application/json"}
' return value: the unique id of the request (or 0 for failure).
function adriseUtils_sendAsyncRequest(url as String, port, name = "" as String, reqType = invalid, isHttps = false, body = invalid, headers = invalid) as Integer
  settings = m.getSettings()
  urlXfer = CreateObject("roURLTransfer")
  'urlXfer.InitClientCertificates()


  'if we send logging for logging API requests, we end up in an infinite loop
  if url <> settings.loggingUrl
    m.log.debug(port, "clientDebug", "send-async-request-id", urlXfer.GetIdentity().toStr())
    m.log.debug(port, "clientDebug", "send-async-request-name", name)
    m.log.debug(port, "clientDebug", "send-async-request-type", reqType)
    m.log.debug(port, "clientDebug", "send-async-request-url", url)
    m.log.debug(port, "clientDebug", "send-async-request-body", body)
    m.log.debug(port, "clientDebug", "send-async-request-headers", headers)
  end if

  url = m.buildUrl(url, name, urlXfer)

  urlXfer.setUrl(url)

  urlXfer.addHeader("User-Agent",  m.deviceInfo.userAgent + " " + m.deviceInfo.model)
  if (port = invalid)
    port = CreateObject("roMessagePort")
  end if
  urlXfer.setPort(port)
  urlXfer.EnableEncodings(true)
  
  if isHttps = true
    urlXfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    urlXfer.AddHeader("X-Roku-Reserved-Dev-Id", "")
  end if

  'add any passed headers
  if type(headers) = "roAssociativeArray" and headers.count() > 0
    for each headerType in headers
      urlXfer.addHeader(headerType, headers[headerType])
    end for
  end if

  validRequestTypes = {
    POST: true
    GET: true
    DELETE: true
    PUT: true
  }

  if reqType = invalid or validRequestTypes[reqType] = invalid
    reqType = "GET"
  end if
  urlXfer.setRequest(reqType)
  
  if reqType = "POST" or reqType = "PUT"
    if type(body) <> "String"
      body = ""
    end if

    if urlXfer.asyncPostFromString(body) = false
      print reqType; " request failed. "; url
      return 0
    end if
  else
    if urlXfer.asyncGetToString() = false
      print reqType; " request failed. "; url 
      return 0
    end if
  end if

  id = urlXfer.GetIdentity()
  if (port <> invalid)
    'stores the roUrlTransfer object so that any response can be matched with it
    if m.asynchRequests = invalid
      m.asynchRequests = {}
    end if
    m.asynchRequests[id.ToStr()] = urlXfer

    if url <> settings.loggingUrl
      m.log.debug(port, "clientDebug", "stored-async-request-objects", "async request objects stored = " +  m.asynchRequests.count().toStr())
      print ""
    end if
  end if

  return id
end function

' --------------------------------------------------------
' .getAsyncResponse
' --------------------------------------------------------
' msg: the message returned from wait()
' id: (optional)  it will ignore responses with different ids
' return value: object with the string (as "data") and the id,
' and the response code if failure OR
' invalid if not the right id, or not an async response
function adriseUtils_getAsyncResponse (msg as Object, id as Integer) as Object
  if type(msg) = "roUrlEvent"
    currId = msg.GetSourceIdentity()

    if id = 0 or id = currId
      out = {
          data : msg.GetString()
          id : currId
          responseCode : msg.GetResponseCode()
          obj: m.asynchRequests[currId.toStr()]
          failReason: msg.GetFailureReason()
        }
      m.asynchRequests.delete(currId.toStr())
      return out
    end if
  end if
  return invalid
end function


' --------------------------------------------------------
' .channelStoreGoToAPP(pluginID)
' --------------------------------------------------------
function adriseUtils_channelStoreGoToApp(pluginID)
  x = m.deviceInfo.ipAddresses
  for each i in x
      ipAddr =  x[i]
  end for

  '' See the ECP document examples for how to obtain your plugin ID
  url = "http://"+ ipAddr +":8060/launch/11?contentID="+ pluginID
  bodyString = ""
  ' print "roku url: "; url
  port = CreateObject("roMessagePort")
  request = createObject("roUrlTransfer")
  request.setPort(port)
  request.setUrl(url)
  response = request.asyncPostFromString(bodyString)
  while true
    msg = wait(0, port)
    if type(msg) = "roUrlEvent"
      if msg.getInt() = 1 then
        ' print "=adRise=: Response code: "; msg.GetResponseCode()
        if msg.GetResponseCode() = 404
          response = invalid
        else
          response = msg.getString()
        end if
        exit while
      end if
    end if
  end while
  return response
end function

' --------------------------------------------------------
' .trackEvent(adUnit, eventTypeStr, eventVal, val2)
' --------------------------------------------------------
function adriseUtils_trackEvent(evt)
  settings = m.getSettings()

  time = CreateObject("roDateTime")

  startMS = 1000 * (60 * (60 * time.GetHours() + time.GetMinutes()) + time.GetSeconds()) + time.getMilliseconds()

  ' ------------AdUnit Events------------------
  if evt.trackType = "click" then
    For Each trackUrl in evt.adUnit.clickTrack
      trackUrl = strReplace(trackUrl, "[", "")
      trackUrl = strReplace(trackUrl, "]", "")
      asyncId = m.sendAsyncRequest(trackUrl, evt.port, "trackClick")
    end for
  else if evt.trackType = "imp" then
    For Each trackUrl in evt.adUnit.impTrack
      trackUrl = strReplace(trackUrl, "[", "")
      trackUrl = strReplace(trackUrl, "]", "")
      asyncId = m.sendAsyncRequest(trackUrl, evt.port, "trackImp")
    end for

    ' counter = 0
    ' while counter < 4
    '   For Each trackUrl in evt.adUnit.impTrack
    '     trackUrl = strReplace(trackUrl, "[", "")
    '     trackUrl = strReplace(trackUrl, "]", "")
    '     if(evt.port = invalid)
    '       asyncId = m.sendAsyncRequest(trackUrl, invalid, "trackImp")
    '     else
    '       asyncId = m.sendAsyncRequest(trackUrl, evt.port, "trackImp")
    '     end if

    '       '//////////////////////////////////////////////
    '       msg = wait(0, evt.port)
    '       print "MESSAGE TYPE "; type(msg)
    '       response = m.getAsyncResponse(msg, 0)

    '       print "-----------------------------------------------------------------------"
    '       print "RESPONSE "; response
            
    '         time.Mark()
    '         responseMS = 1000 * (60 * (60 * time.GetHours() + time.GetMinutes()) + time.GetSeconds()) + time.getMilliseconds()
    '         print "TIME TO RESPONSE "; responseMS - startMS; " milliseconds"
    '       print "-----------------------------------------------------------------------"

    '       '//////////////////////////////////////////////
        
    '   end for
    '   counter = counter + 1
    ' end while

  else if evt.trackType = "viewthru" then
    For Each trackUrl in evt.adUnit.viewthru[evt.adPercentage]
      trackUrl = strReplace(trackUrl, "[", "")
      trackUrl = strReplace(trackUrl, "]", "")
      evt.adUnit.viewthru[evt.adPercentage] = "" ' making sure it doesn't get fired again
      asyncId = m.sendAsyncRequest(trackUrl, evt.port, "trackViewThru")
    end for

  'event tracking for non ad events
  else if evt.trackType <> invalid and m.deviceInfo.firmwareVersion > 3.01 then
    trackData = m.getTrackData(evt.trackType, evt.value, evt.ctx, evt.extraCtx)

    trackingDataToSendJSON = FormatJson(trackData)

    'url as String, port, name = "" as String, reqType = invalid, isHttps = false, body = invalid, headers = invalid
    asyncId = m.sendAuthAsyncRequest(settings.userEventUrl, evt.port, "track" + evt.trackType, "POST", true, trackingDataToSendJSON, invalid)
  end if

end function

' --------------------------------------------------------
' .getTrackingTags (xml_tags)
' --------------------------------------------------------
function adriseUtils_getTrackingTags(xml_tags)
  ret = []
  count = 0
  For Each item in xml_tags
      ret[count] = item.GetText()
      count = count + 1
  next
  return ret
end function

' --------------------------------------------------------
' .showImageOnCanvas(image, canvas, options)
' --------------------------------------------------------
function adriseUtils_showImageOnCanvas(image, canvas, options)
  print "image file: " ; image
  if image = ""
    print "image is empty"
  end if

  if image = invalid
      print "image is invalid"
  end if

  z = 20
  cMode = "Source"
  targetRect = {
      x: 0
      y: 30
      w: m.deviceInfo.displayWidth
      h: m.deviceInfo.displayHeight
    }
  if options <> invalid
    print "sioc mode: " ; options.mode
    if options.z <> invalid
      z = options.z
    end if

    if options.h <> invalid
      targetRect.h = options.h
    end if

    if options.cMode <> invalid
      cMode = options.cMode
    end if
  end if

  canvas.SetLayer(z, {
    Url: image
    TargetRect: targetRect
    CompositionMode: cMode
    })
end function

' ******************************************************
'  .showAdLoadingLayer
' ******************************************************
function adriseUtils_showAdLoadingLayer (canvas, displaySize, secondsLeft, count, totalAds, background, fontColor, loadingImageUrl, appid)
   background = {
    Color: background
  }
  loadingImage = {
    Url: loadingImageUrl
    TargetRect: {
      x: Int( displaySize.w / 2 ) - Int( 336 / 2 ),
      y: Int( displaySize.h / 2 ) - Int( 210 / 2 ),
      w: 336,
      h: 210
    }
  }

  sec = secondsLeft
  min = int(sec/60)
  sec = sec - (min*60)
  if type(sec) = "Float"
    sec = int(sec)
  end if
  
  if (sec < 10)
      str_sec = "0" + sec.ToStr()
  else
      str_sec = sec.ToStr()
  end if


  loadingText = {
    Text: "Your program will begin in 0" + min.ToStr() + ":" + str_sec,
    TextAttrs: {
        Font: "Medium"
        VAlign: "Bottom"
        Color: fontColor
    },
    TargetRect: {
        x: loadingImage.TargetRect.x - 125,
        y: loadingImage.TargetRect.y + 250,
        w: loadingImage.TargetRect.w + 250,
        h: 30
    }
  }
  adsByAdriseText = {
    Text: "Ads by adRise",
    TextAttrs: {
        Font: "small",
        VAlign: "Bottom",
        Color: fontColor,
    },
    TargetRect: {
        x: loadingImage.TargetRect.x - 125,
        y: loadingImage.TargetRect.y + 290,
        w: loadingImage.TargetRect.w + 250,
        h: 30
    }
  }

  if appid = "tubitv"
    adsByAdriseText.Text = ""
  end if

  if totalAds > 1
    loadingText.Text = "Ad " + count.ToStr() + " of " + totalAds.ToStr() + ": " + loadingText.Text
  end if
  canvas.SetLayer(2, [background, loadingImage, loadingText, adsByAdriseText])
end function

' ******************************************************
' ******************************************************
function adriseUtils_showErrorMessage (background, fontColor, loadingImageUrl, message)
  canvas = CreateObject("roImageCanvas")
  port = CreateObject("roMessagePort")
  canvas.SetMessagePort(port)
  background = {
    Color: background
  }
  loadingImage = {
    Url: loadingImageUrl
    TargetRect: {
      x: Int( m.deviceInfo.displayWidth / 2 ) - Int( 336 / 2 ),
      y: Int( m.deviceInfo.displayHeight / 2 ) - Int( 210 / 2 ),
      w: 336,
      h: 210
    }
  }
  print "message " + message

  loadingText = {
    Text: message
    TextAttrs: {
        Font: "Medium"
        VAlign: "Bottom"
        Color: fontColor
    },
    TargetRect: {
        x: loadingImage.TargetRect.x - 125
        y: loadingImage.TargetRect.y + 250
        w: loadingImage.TargetRect.w + 250
        h: 30
    }
  }
  canvas.SetLayer(2, [background, loadingImage, loadingText])
  canvas.Show()
  canvas.AddButton(1, "ok")
  while(true)
     msg = wait(0,port)
     if type(msg) = "roImageCanvasEvent" then
      if msg.isButtonPressed()
        button = msg.GetIndex()
        if (button = 1)
          return true
        end if
      end if
     end if
   end while
   return true
end function


'function adriseUtils_getTrackData(eventType, contentId = 0, progressPercent = 0, playerPosition = 0, deepLinkSource = "", errorMessage = "")
function adriseUtils_getTrackData(eventType, value=0, ctx=invalid, extraCtx=invalid)
  authInfo = m.getAuthInfo()
  if authInfo <> invalid and authInfo.userId <> invalid
    userID = authInfo.userId
  else
    userID = 0
  end if

  eventTypes = {
    startApp: {
      value: m.deviceInfo.userAgent + " " + m.deviceInfo.model
      key: "active"
      ctx: m.deviceInfo.model
    }
    pageLoad: {
      value: value
      key: "page_load"
    }
    navigate: {
      value: value
      key: "navigate_to_page"
      ctx: ctx
    }
    navigateInPage: {
      value: value
      key: "navigate_within_page"
      ctx: ctx
    }    
    videoPlay: {
      value: value
      key: "start_video"
      ctx: ctx
      extraCtx: extraCtx
    }
    resumeAfterAds: {
      value: value
      key: "resume_after_break"
      ctx: ctx
    }
    playProgress: {
      value: value
      key: "play_progress"
      ctx: ctx
      extraCtx: extraCtx
    }
    seek: {
      value: value
      key: "seek"
      ctx: ctx      
    }
    pauseToggle: {
      value: value
      key: "pause_toggle"
      ctx: ctx      
    }
    subtitles: {
      value: value
      key: "subtitles_toggle"
      ctx: ctx
    }    
    deepLink: {
      value: "deeplink"
      key: "referred"
      ctx: ctx
      extraCtx: extraCtx
    }
    addBookmark: {
      value: value
      key: "add_bookmark"
      ctx: ctx
    }
    deleteBookmark: {
      value: value
      key: "remove_bookmark"
    }
    registerFail:{
      key: "register_device_fail"
      value: value
    }
    registerSuccess:{
      key: "register_device_success"
      value: value
    }
    search:{
      value: value
      key: "search"
      ctx: "search_dialog"
    }
  }

  trackData = CreateObject("roAssociativeArray")
  trackData.SetModeCaseSensitive()
  trackData.AddReplace("app_id", m.appName + "-roku")
  trackData.AddReplace("value", eventTypes[eventType].value)
  trackData.AddReplace("key", eventTypes[eventType].key)
  if eventTypes[eventType].ctx <> invalid
    trackData.AddReplace("ctx", eventTypes[eventType].ctx)
  end if
  if eventTypes[eventType].extraCtx <> invalid
    trackData.AddReplace("extra_ctx", eventTypes[eventType].extraCtx)
  end if
  trackData.AddReplace("user_id", userID)
  trackData.AddReplace("device_id", m.deviceInfo.deviceId)
  trackData.AddReplace("client_version", m.deviceInfo.clientVersion)
  'trackData looks like:
  ' trackData = {
  '   app : "tubitv-roku",
  '   value : eventTypes[eventType].value
  '   key : eventTypes[eventType].key
  '   ctx : eventTypes[eventType].ctx
  '   extra_ctx: eventTypes[eventType].extraCtx
  '   userID : userID
  '   deviceID : m.deviceInfo.deviceId
  ' }.SetModeCaseSensitive()
  return trackData
end function


function adriseUtils_sluggify(preSlug as string)
  'lowercase everything
  slug = LCase(preSlug)

  'remove any leading/trailing white space
  slug = slug.trim()

  'replace spaces with underscore
  while slug.Instr(0, "  ") >= 0
    slug.Replace("  ", " ")
  end while
  slug = slug.Replace(" ", "_")

  'replace special characters
  slug = slug.Replace("&", "and")
  slug = slug.Replace("-", "_")
  slug = slug.Replace("ñ", "n")
  slug = slug.Replace("á", "a")
  slug = slug.Replace("é", "e")
  slug = slug.Replace("í", "i")
  slug = slug.Replace("ó", "o")
  slug = slug.Replace("ú", "u")

  'remove any characters that aren't lower case letters, numbers or underscore
  regX = createObject("roRegex", "", "i")
  slugTokens = regX.split(slug)
  finalSlug = ""
  for i=0 to slugTokens.count()-1 step 1
    char = slugTokens[i]
    if (Asc(char) >= 48 and Asc(char) <= 57) or (Asc(char) >= 97 and Asc(char) <= 122) or Asc(char) = 95
      finalSlug = finalSlug + char
    end if
  end for

  return finalSlug
end function


function adriseUtils_getDeviceInfo()
  di = CreateObject("roDeviceInfo")

  firmware = di.GetVersion() '034.08E01185A' string
  firmwareVersion = Val(Mid(firmware, 3, 4)) '4.08'  float
  firmwareVersionMajor = Val(Mid(firmware, 3, 1))  '4'  integer
  firmwareVersionMinor = Val(Mid(firmware, 5, 2))  '8'  integer 
  firmwareBuild = Mid(firmware, 9, 4) '01185'  string

  if firmwareVersion >= 6.01 and not di.IsAdIdTrackingDisabled()
      deviceAdId = di.GetAdvertisingId()
  else
    deviceAdId = invalid
  end if

  if firmwareVersion >= 4.3
    countryCode = di.GetCountryCode()
  else
    countryCode = invalid
  end if

  '256MB models that will be limited by cp.maxContent
  lowMemoryModels = {
    "2400X": true  ' LT (2011)
    "2450X": true  ' LT (2012)
    "2500X": true  ' HD
    "3000X": true  ' 2 HD
    "3050X": true  ' 2 XD
    "3100X": true  ' 2 XS
    "3400X": true  ' MHL Stick
    "3420X": true  ' MHL Stick 
  }

  if lowMemoryModels[di.GetModel()] <> invalid
    lowMemory = true
  else
    lowMemory = false
  end if


  'get client version from manifest
  clientVersionNums = ["", "", ""]

  manifest = ReadASCIIFile("pkg:/manifest")
  lines = manifest.Tokenize(Chr(10))
  for each line in lines
    props = line.Tokenize("=")
    if props[0] = "major_version"
      clientVersionNums[0] = props[1]

    else if props[0] = "minor_version"
      clientVersionNums[1] = props[1]

    else if props[0] = "build_version"
      clientVersionNums[2] = props[1]
    end if
  end for

  clientVersion = ""
  for i=0 to clientVersionNums.count()-1
    clientVersion = clientVersion + clientVersionNums[i] + "."
  end for
  clientVersion = clientVersion + "oldui.local"

  userAgent = "Roku/DVP-" + firmwareVersionMajor.toStr() + "." + firmwareVersionMinor.toStr() + " (" + firmware + ")"

  return {
    deviceId: di.GetDeviceUniqueId()
    deviceAdId: di.GetAdvertisingId()
    isAdIdTrackingDisabled: di.IsAdIdTrackingDisabled()
    ipAddresses: di.GetIPAddrs() 'array of network interface ip addresses (normally will only contain 1 element)
    firmwareVersion: firmwareVersion
    firmwareBuild: firmwareBuild
    userAgent: userAgent
    userAgentPlusModel: userAgent + " " + di.GetModel()
    model: di.GetModel()
    displayType: di.GetDisplayType()
    displayMode: di.GetDisplayMode()
    aspectRatio: di.GetDisplayAspectRatio()
    displaySize: di.GetDisplaySize()
    displayWidth: di.GetDisplaySize().w
    displayHeight: di.GetDisplaySize().h
    captionsMode: di.GetCaptionsMode()
    countryCode: countryCode ' will be invalid if old version of firmware
    lowMemory: lowMemory
    clientVersion: clientVersion
    language: di.GetCurrentLocale().Left(2)
  }
end function