'a set of helper functions that facilitate sending and receiving "Continue Watching"/history and "My Queue"/bookmarks
'info to the server (UAPI at the time of writing this comment)
Function TubiBookmarks(request as Object, auth as Object, constants as Object, nodeHelpers as Object, apiUtils as Object) as Object

  defaultValues = {
    request: request
    auth: auth
    constants: constants
    nodeHelpers: nodeHelpers

    'public methods
    addBookmarkReq: tubiBookmarks_addBookmarkReq
    removeBookmarkReq: tubiBookmarks_removeBookmarkReq
    addHistoryReq: tubiBookmarks_getAddHistoryRequestInfo
    addHistoryLocally: tubiBookmarks_addHistoryLocally
    removeHistoryReq: tubiBookmarks_removeHistoryReq
    removeHistoryLocally: tubiBookmarks_removeHistoryLocally
    getInitialBookmarksReq: tubiBookmarks_getInitialBookmarksReq
    getInitialHistoryReq: tubiBookmarks_getInitialHistoryReq
    handleInitialBookmarks: tubiBookmarks_handleInitialBookmarks
    handleInitialHistory: tubiBookmarks_handleInitialHistory
    getUserInfoReq: tubiBookmarks_getUserInfoReq
    handleUserInfo: tubiBookmarks_handleUserInfo
    updateParentalRatingReq: tubiBookmarks_updateParentalRatingReq

    'private methods
    createBookmarksRequest: tubiBookmarks_createBookmarksRequest_
    createHistoryRequest: tubiBookmarks_createHistoryRequest_
    isLoggedInUser: tubiBookmarks_isLoggedInUser
  }

  tubiBookmarks = {}
  tubiBookmarks.append(apiUtils)
  tubiBookmarks.append(defaultValues)
  return tubiBookmarks

End Function


'returns a request object that can be used to add a bookmark to the server
'@content: can be a content node from scene graph or a content object from the main thread - expect either a video/movie or episode, no series
'     send either the video or the episode as the content, not the parent series
' @bKidsMode: boolean Are we in kids mode (and parental controls is not set to kids)?
Function tubiBookmarks_addBookmarkReq(content as Object, bKidsMode = false as Boolean) as Object
  bookmarkReq = invalid
  if content <> invalid
    'translate internal content type to UAPI content type
    if content["type"] = m.constants.ui.contentTypes.video
      bookmarkReq = m.createBookmarksRequest(content.id, "add", m.constants.uapiContentTypes.movie, bKidsMode)
    else if content["type"] = m.constants.ui.contentTypes.series
      bookmarkReq = m.createBookmarksRequest(content.id, "add", m.constants.uapiContentTypes.series, bKidsMode)
    else
      tubiLog("ERROR: Can't bookmark content that isn't a video or series")
    end if
  end if
  return bookmarkReq
End Function


'returns a request object that can be used to remove a bookmark from the server
'@content: can be a content node from scene graph or a content object from the main thread - expect videos/movies or episodes, no series
' @bKidsMode: boolean Are we in kids mode (and parental controls is not set to kids)?
Function tubiBookmarks_removeBookmarkReq(content as Object, bKidsMode = false as Boolean) as Object
  bookmarkReq = invalid
  if content <> invalid and content.id <> invalid and content.bookmarkId <> invalid
    bookmarkReq = m.createBookmarksRequest(content.bookmarkId, "delete", "", bKidsMode)
  else
    tubiLog("bookmark id not found")
  end if
  return bookmarkReq
End Function


'returns a request object that can be used to add or delete the bookmark from the server, or invalid
'@id: stringified content id of series or video that we are adding/deleting
  'if add, @id should be the contentId
  'if delete @id should be the 'bookmark server id'
'@action: string (should be "add" or "delete")
'@contentType: string (should be "series" or "movie") - not necessary for deletes
'@bKidsMode: boolean Are we in kids mode (and parental controls is not set to kids)?
'@port: roMessagePort that will be used to listen for the async response - probably the port defined in detailsPage.show()
Function tubiBookmarks_createBookmarksRequest_(id as String, action as String, contentType = "" as String, bKidsMode = false as Boolean) as Object
  authInfo = m.auth.getAuthInfo()  'from registry
  if m.isLoggedInUser(authInfo) = false
    return invalid
  end if

  bodyJson = invalid
  url = m.constants.urls.userDevice.queues

  if action = "add"
    verb = m.constants.reqTypes.post
    body = {
      user_id: authInfo.userId
      content_id: id
      content_type: contentType
    }
    bodyJson = FormatJson(body)

  else if action = "delete"
    verb = m.constants.reqTypes.del
    url = url + "/" + id
  else
    return invalid
  end if

  options = {
    method: verb
    params: {
      platform: m.constants.platform
    }
  }
  options.params["isKidsMode"] = bKidsMode

  if bodyJson <> invalid
    options.body = bodyJson
  end if

  bookmarkReq = m.auth.createAuthRequest(url, action+"Bookmark", options)

  return bookmarkReq
End Function


'saves the resume point locally and does not communicate to the backend.
' @content: can be a content node from scene graph or a content object from the main thread - expect either a video/movie or episode, no series
' @position: position where user left off of video
' @global: The global object to be used to save the data
Function tubiBookmarks_addHistoryLocally(content as Object, position as Integer, global = invalid)
  if content <> invalid and global <> invalid and global.historyIds <> invalid

    nowDate = CreateObject("roDateTime")
    nLastSaved = nowDate.AsSeconds()
    if content.parentType = m.constants.uapiContentTypes.series
      '//if this TV content
      if content.parentId <> invalid

        historyNode = getHistory(content.parentId) 'bs:disable-line 1001 LINT1001

        if historyNode = invalid
          historyNode = global.historyIds.createChild("HistoryContentNode")
        end if
        historyNode.id = content.parentId
        historyNode.type = m.constants.uapiContentTypes.series
        historyNode.currentEpisodeId = content.id
        historyNode.lastSaved = nLastSaved

        childNode = historyNode.findNode(content.id)
        if childNode = invalid
          childNode = historyNode.createChild("HistoryContentNode")
        end if

        childNode.id = content.id
        childNode.lastSaved = nLastSaved
        childNode.nowPos = position
        childNode.type = content.type
        childNode.historyId = content.id
      end if
    else
      '//else if this movie content

      historyNode = getHistory(content.id) 'bs:disable-line 1001 LINT1001

      if historyNode = invalid
        historyNode = global.historyIds.createChild("HistoryContentNode")
      end if
      historyNode.id = content.id
      historyNode.lastSaved = nLastSaved
      historyNode.nowPos = position
      historyNode.type = content.type
      historyNode.historyId = content.id
    end if
  end if
End Function


' @content: roSGNode, content of Video Player
' @nowPos : integer, video position in seconds
' @bKidsMode : boolean, kids mode can be true/false
'
' returns url & options for making API request
'
Function tubiBookmarks_getAddHistoryRequestInfo(content as Object, nowPos as Integer, bKidsMode = false as Boolean) as Object

  authInfo = m.auth.getAuthInfo()
  if m.isLoggedInUser(authInfo) = false
    return invalid
  end if

  url = m.constants.urls.userDevice.history

  body = {
    content_id: content.id
    position: nowPos
    device_id: m.constants.deviceInfo.deviceId
    user_id: authInfo.userid.toInt()
  }

  contentType = m.constants.uapiContentTypes.movie
  parentId = content.parentId

  'set the parentId to an integer or invalid as needed (expect to receive it as a string which is not compatible with API)
  if type(parentId) = "string" or type(parentId) = "roString"
    if parentId.len() = 0
      body.parent_id = invalid    'is ok if parentId is invalid (ie. for movies)
    else
      body.parent_id = parentId.toInt()
      contentType = m.constants.uapiContentTypes.episode
    end if
  else if type(parentId) = "integer" or type(parentId) = "roInt"
    body.parent_id = parentId
    contentType = m.constants.uapiContentTypes.episode
  else
    body.parent_id = invalid
  end if

  body.content_type = contentType

  options = m.getCommonOptions()
  options.params["isKidsMode"] = bKidsMode
  options["body"] = FormatJSON(body)
  options["method"] = m.constants.reqTypes.post

  return {
    url: url
    options: options
  }

End Function


'returns a request object that can be used to remove a history from the server
' @content: can be a content node from scene graph or a content object from the main thread - expect either a video/movie or episode, no series
' @bKidsMode: boolean Are we in kids mode (and parental controls is not set to kids)?
Function tubiBookmarks_removeHistoryReq(content as Object, bKidsMode = false as Boolean) as Object
  historyReq = invalid
  if content <> invalid and content.historyId <> invalid then
    historyReq = m.createHistoryRequest(content.historyId, invalid, 0, "delete", "", bKidsMode)
  end if
  return historyReq
End Function


'Remove the local version copy of the resume position for a particular video.
Function tubiBookmarks_removeHistoryLocally(content as Object, global)
  if content <> invalid

    historyNode = getHistory(content.id) 'bs:disable-line 1001 LINT1001

    if historyNode <> invalid
      global.historyIds.removeChild(historyNode)
    end if
  end if
End Function


'returns a request object that can be used to add or delete the history from the server, or invalid
'@id: stringified content id of series or video that we are adding/deleting
  'if add, @id should be the contentId
  'if delete @id should be the 'previously viewed server id
'@parentId: stringified content id of the parent series id for an episode - should be invalid for deletes or adding movies
'@position: int(player positino or nowPos in seconds) - should be invalid for deletes
'@action: string (should be "add" or "delete")
'@contentType: string (should be "series" or "movie") - not necessary for deletes
'@bKidsMode: boolean Are we in kids mode (and parental controls is not set to kids)?
'@port: roMessagePort that will be used to listen for the async response - probably the port defined in detailsPage.show()
Function tubiBookmarks_createHistoryRequest_(id as String, parentId as Dynamic, position as Dynamic, action as String, contentType = "" as String, bKidsMode = false as Boolean) as Object
  authInfo = m.auth.getAuthInfo()
  if m.isLoggedInUser(authInfo) = false
    return invalid
  end if

  body = {
    content_id: id
    content_type: contentType
    position: position
    device_id: m.constants.deviceInfo.deviceId
  }
  if authInfo <> invalid
    body.user_id = authInfo.userId.toInt()
  end if
  if parentId <> invalid
    body.parent_id = parentId
  end if
  bodyJson = FormatJson(body)

  url = m.constants.urls.userDevice.history

  if action = "add"
    verb = m.constants.reqTypes.post
  else if action = "delete"
    bodyJson = invalid
    verb = m.constants.reqTypes.del
    url = url + "/" + id
  else
    return invalid
  end if

  options = {
    method: verb
    params: {
      platform: m.constants.platform
    }
  }

  options.params["isKidsMode"] = bKidsMode

  if bodyJson <> invalid
    options.body = bodyJson
  end if

  historyReq = m.auth.createAuthRequest(url, action+"History", options)
  if historyReq = invalid
    historyReq = m.Request.createAsync(url, action+"History", options)
  end if

  return historyReq
End Function


'@localId: string, a string used to identify req when a response is received
Function tubiBookmarks_getInitialBookmarksReq(localId) as Object
  authInfo = m.auth.getAuthInfo()  'from registry

  'if the user is not logged in (aka doesn't have an accessToken in local memory),
  'then don't get any bookmarks
  if m.isLoggedInUser(authInfo) = false
    return invalid
  end if

  url = m.constants.urls.userDevice.queues

  options = {
    method: m.constants.reqTypes.get
    params: {
      platform: m.constants.platform
      "page_enabled": false
    }
  }

  initialBookmarkReq = m.auth.createAuthRequest(url, "getInitialBookmarks", options)
  if initialBookmarkReq <> invalid then
    initialBookmarkReq.localId = localId
  end if

  return initialBookmarkReq
End Function


'@localId: string, a string used to identify req when a response is received
Function tubiBookmarks_getInitialHistoryReq(localId) as Object
  authInfo = m.auth.getAuthInfo()  'from registry

  'if the user is not logged in (aka doesn't have an accessToken in local memory),
  'then don't get any history
  if m.isLoggedInUser(authInfo) = false
    return invalid
  end if

  url = m.constants.urls.userDevice.history

  options = {
    method: m.constants.reqTypes.get
    params: {
      "page_enabled": false
      platform: m.constants.platform
      "deviceId": m.constants.deviceInfo.deviceId
    }
  }

  initialHistoryReq = m.auth.createAuthRequest(url, "getInitialHistory", options)
  'auth.createAuthRequest() returns invalid if user is not logged in
  if initialHistoryReq = invalid
    initialHistoryReq = m.request.createAsync(url, "getInitialHistory", options)
  end if

  if initialHistoryReq <> invalid then
    initialHistoryReq.localId = localId
  end if

  return initialHistoryReq
End Function


'@initialBookmarks: string, JSON server response when making the first call to UAPI to get a user's basic bookmark info
'returns bookmarkIds ordered node tree with series having episode children
Function tubiBookmarks_handleInitialBookmarks(initialBookmarks)
  bookmarkIds = CreateObject("roSGNode", "BookmarkContentNode")
  parsedInitialBookmarks = ParseJson(initialBookmarks)
  if parsedInitialBookmarks <> Invalid
    for each bookmark in parsedInitialBookmarks.items
      child = bookmarkIds.createChild("BookmarkContentNode")
      child.id = bookmark.content_id.toStr()
      child.bookmarkId = bookmark.id
      if bookmark.content_type = m.constants.uapiContentTypes.movie
        child.type = m.constants.ui.contentTypes.video
      else if bookmark.content_type = m.constants.uapiContentTypes.series
        child.id = "0" + child.id
        child.type = m.constants.ui.contentTypes.series
      end if
    end for
  end if
  return bookmarkIds
End Function



'@initialHistory: string, JSON server response when making the first call to UAPI to get a user's basic history info
'returns historyIds ordered node tree with series having episode children
Function tubiBookmarks_handleInitialHistory(initialHistory)
  historyIds = CreateObject("roSGNode", "HistoryContentNode")
  parsedInitialHistory = ParseJson(initialHistory)

  if parsedInitialHistory <> invalid then
    for each history in parsedInitialHistory.items
      child = historyIds.createChild("HistoryContentNode")
      child.id = history.content_id.toStr()
      if history.content_type = m.constants.uapiContentTypes.movie
        child.historyId = history.id
        child.nowPos = history.position
        child.type = m.constants.ui.contentTypes.video
      else if history.content_type = m.constants.uapiContentTypes.series
        child.id = "0" + child.id
        child.historyId = history.id
        child.type = m.constants.ui.contentTypes.series

        if history.episodes <> invalid and history.position <> invalid and history.episodes[history.position] <> invalid
          currentEpisode = history.episodes[history.position]
          if currentEpisode.content_id <> invalid
            child.currentEpisodeId = history.episodes[history.position].content_id.toStr()
          end if
        end if

        for each episode in history.episodes
          if episode.content_id <> invalid
            grandchild = child.createChild("HistoryContentNode")
            grandchild.id = episode.content_id.toStr()
            grandchild.historyId = episode.id
            grandchild.nowPos = episode.position
            grandchild.type = m.constants.ui.contentTypes.video
          end if
        end for
      end if
    end for
  end if

  return historyIds
End Function

Function tubiBookmarks_getUserInfoReq()
  authInfo = m.auth.getAuthInfo()
  if m.isLoggedInUser(authInfo) = false
    return invalid
  end if
  url = m.constants.urls.account.settings
  options = {
    params: {
      platform: m.constants.platform
    }
  }
  return m.auth.createAuthRequest(url, "getUserInfo", options)
End Function

Function tubiBookmarks_handleUserInfo(userInfo)
  result = {}
  parsed = ParseJson(userInfo)
  if parsed <> invalid
    if parsed.user_id <> invalid then         result.userId = parsed.user_id
    if parsed.facebook_id <> invalid then     result.facebookId = parsed.facebook_id
    if parsed.profile_pic <> invalid then     result.profilePic = parsed.profile_pic
    if parsed.gender <> invalid then          result.gender = parsed.gender
    if parsed.birthday <> invalid then        result.birthday = parsed.birthday
    if parsed.phone_number <> invalid then    result.phoneNumber = parsed.phone_number
    if parsed.is_confirmed <> invalid then    result.isConfirmed = parsed.is_confirmed
    if parsed.enabled <> invalid then         result.enabled = parsed.enabled
    if parsed.has_password <> invalid then    result.hasPassword = parsed.has_password
    if parsed.parental_rating <> invalid then result.parentalRating = parsed.parental_rating
    if parsed.enable_video_preview <> invalid then result.enableVideoPreview = parsed.enable_video_preview

    result.email = ""
    if parsed.email <> invalid
      result.email = parsed.email
    end if

    result.name = ""
    if parsed.name <> invalid
      result.name = parsed.name
    end if

    result.firstName = ""
    if parsed.first_name <> invalid
      result.firstName = parsed.first_name
    end if

    result.lastName = ""
    if parsed.last_name <> invalid
      result.lastName = parsed.last_name
    end if

  end if
  return result
End Function


Function tubiBookmarks_updateParentalRatingReq(newRating, password)
  authInfo = m.auth.getAuthInfo()
  if m.isLoggedInUser(authInfo) = false
    return invalid
  end if

  url = m.constants.urls.account.parentalRating
  body = {
    parental_rating: newRating
    password: password
  }
  options = {
    method: m.constants.reqTypes.put
    params: {
      platform: m.constants.platform
    }
    body: FormatJson(body)
  }
  return m.auth.createAuthRequest(url, "updateParentalRating", options)
End Function


Function tubiBookmarks_isLoggedInUser(authInfo)
  return (authInfo <> invalid and authInfo.userId <> invalid)
End Function
