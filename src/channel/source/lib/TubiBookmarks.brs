'a set of hepler functions that facilitate sending and receiving "Continue Watching"/history and "My Queue"/bookmarks
'info to the server (UAPI at the time of writing this comment)
Function TubiBookmarks(request as Object, auth as Object, constants as Object, nodeHelpers as Object) as Object
  return {
    request: request
    auth: auth
    constants: constants
    nodeHelpers: nodeHelpers

    'public methods
    addBookmarkReq: tubiBookmarks_addBookmarkReq
    removeBookmarkReq: tubiBookmarks_removeBookmarkReq
    addHistoryReq: tubiBookmarks_addHistoryReq
    removeHistoryReq: tubiBookmarks_removeHistoryReq
    getInitialBookmarksReq: tubiBookmarks_getInitialBookmarksReq
    getInitialHistoryReq: tubiBookmarks_getInitialHistoryReq
    handleInitialBookmarks: tubiBookmarks_handleInitialBookmarks
    handleInitialHistory: tubiBookmarks_handleInitialHistory

    'private methods
    createBookmarksRequest: tubiBookmarks_createBookmarksRequest_
    createHistoryRequest: tubiBookmarks_createHistoryRequest_
  }
End Function


'returns a request object that can be used to add a bookmark to the server
'@content: can be a content node from scene graph or a content object from the main thread - expect either a video/movie or episode, no series
'     send either the video or the episode as the content, not the parent series
function tubiBookmarks_addBookmarkReq(content as Object) as Object
  bookmarkReq = invalid
  if content <> invalid
    'translate internal content type to UAPI content type
    if content["type"] = m.constants.ui.contentTypes.video
      bookmarkReq = m.createBookmarksRequest(content.id, "add", m.constants.uapiContentTypes.movie)
    else if content["type"] = m.constants.ui.contentTypes.series
      bookmarkReq = m.createBookmarksRequest(content.id, "add", m.constants.uapiContentTypes.series)
    else
      tubiLog("ERROR: Can't bookmark content that isn't a video or series")
    end if
  end if
  return bookmarkReq
end function


'returns a request object that can be used to remove a bookmark from the server
'@content: can be a content node from scene graph or a content object from the main thread - expect videos/movies or episodes, no series
function tubiBookmarks_removeBookmarkReq(content as Object) as Object
  bookmarkReq = invalid
  if content <> invalid and content.id <> invalid and content.bookmarkId <> invalid
    bookmarkReq = m.createBookmarksRequest(content.bookmarkId, "delete")
  else
    tubiLog("bookmark id not found")
  end if
  return bookmarkReq
end function


'returns a request object that can be used to add or delete the bookmark from the server, or invalid
'@id: stringified content id of series or video that we are adding/deleting
  'if add, @id should be the contentId
  'if delete @id should be the 'bookmark server id'
'@action: string (should be "add" or "delete")
'@contentType: string (should be "series" or "movie") - not necessary for deletes
'@port: roMessagePort that will be used to listen for the async response - probably the port defined in detailsPage.show()
function tubiBookmarks_createBookmarksRequest_(id as String, action as String, contentType = "" as String) as Object
  authInfo = m.auth.getAuthInfo()  'from registry
  if authInfo = invalid or authInfo.accessToken = invalid
    return invalid
  end if

  bodyJson = invalid
  url = m.constants.urls.users.queues

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
  }

  if bodyJson <> invalid
    options.body = bodyJson
  end if

  bookmarkReq = m.auth.createAuthRequest(url, action+"Bookmark", options)    
  
  return bookmarkReq
end function

'returns a request object that can be used to add a history to the server
'@content: can be a content node from scene graph or a content object from the main thread - expect either a video/movie or episode, no series
function tubiBookmarks_addHistoryReq(content as Object, position as Integer) as Object
  historyReq = invalid

  if content <> invalid
    idToServe = content.id
    parentId = content.parentId

    if content["type"] = m.constants.ui.contentTypes.video
      contentType = m.constants.uapiContentTypes.movie

      'set the parentId to an intenger or invalid as needed (expect to receive it as a string which is not compatible with API)
      if type(parentId) = "string" or type(parentId) = "roString"
        if parentId.len() = 0
          parentId = invalid    'is ok if parentId is invalid (ie. for movies)
        else
          parentId = parentId.toInt()          
          contentType = m.constants.uapiContentTypes.episode
        end if
      end if

    else
      ' can't have history for a series, only episodes and movies
      return invalid
    end if

    historyReq = m.createHistoryRequest(idToServe, parentId, position, "add", contentType)
  end if

  return historyReq
end function


'returns a request object that can be used to remove a history from the server
'@content: can be a content node from scene graph or a content object from the main thread - expect either a video/movie or episode, no series
function tubiBookmarks_removeHistoryReq(content as Object) as Object
  historyReq = invalid
  if content <> invalid and content.historyId <> invalid then
    historyReq = m.createHistoryRequest(content.historyId, invalid, 0, "delete")
  end if
  return historyReq
end function


'returns a request object that can be used to add or delete the history from the server, or invalid
'@id: stringified content id of series or video that we are adding/deleting
  'if add, @id should be the contentId
  'if delete @id should be the 'previously viewed server id
'@parentId: stringified content id of the parent series id for an episode - should be invalid for deletes or adding movies
'@position: int(player positino or nowPos in seconds) - should be invalid for deletes
'@action: string (should be "add" or "delete")
'@contentType: string (should be "series" or "movie") - not necessary for deletes
'@port: roMessagePort that will be used to listen for the async response - probably the port defined in detailsPage.show()
function tubiBookmarks_createHistoryRequest_(id as String, parentId as Dynamic, position as Dynamic, action as String, contentType = "" as String) as Object
  authInfo = m.auth.getAuthInfo()
  if authInfo = invalid and m.constants.ui.users.guestHistory <> true
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

  url = m.constants.urls.users.history
  
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
  }

  if bodyJson <> invalid
    options.body = bodyJson
  end if

  historyReq = m.auth.createAuthRequest(url, action+"History", options)
  if historyReq = invalid
    historyReq = m.Request.createAsync(url, action+"History", options)
  end if

  return historyReq
end function


'@localId: string, a string used to identify req when a response is received
function tubiBookmarks_getInitialBookmarksReq(localId) as Object
  authInfo = m.auth.getAuthInfo()  'from registry

  'if the user is not logged in (aka doesn't have an accessToken in local memory),
  'then don't get any bookmarks
  if authInfo = invalid or authInfo.accessToken = invalid
    return invalid
  end if

  url = m.constants.urls.users.queues

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
end function


'@localId: string, a string used to identify req when a response is received
function tubiBookmarks_getInitialHistoryReq(localId) as Object
  authInfo = m.auth.getAuthInfo()  'from registry

  'if the user is not logged in (aka doesn't have an accessToken in local memory),
  'then don't get any bookmarks
  if authInfo = invalid and m.constants.ui.users.guestHistory <> true
    return invalid
  end if

  url = m.constants.urls.users.history

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
end function


'@initialBookmarks: string, JSON server response when making the first call to UAPI to get a user's basic bookmark info
'returns bookmarkIds ordered node tree with series having episode children
function tubiBookmarks_handleInitialBookmarks(initialBookmarks)
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
end function



'@initialHistory: string, JSON server response when making the first call to UAPI to get a user's basic bookmark info
'returns historyIds ordered node tree with series having episode children
function tubiBookmarks_handleInitialHistory(initialHistory)
  historyIds = CreateObject("roSGNode", "HistoryContentNode")
  parsedInitialHistory = ParseJson(initialHistory)
  if parsedInitialHistory <> invalid then
    for each history in parsedInitialHistory.items
      child = historyIds.createChild("HistoryContentNode")
      child.id =         history.content_id.toStr()
      if history.content_type = m.constants.uapiContentTypes.movie
        child.historyId =  history.id
        child.nowPos =     history.position
        child.type =       m.constants.ui.contentTypes.video
      else if history.content_type = m.constants.uapiContentTypes.series
        child.id =                 "0" + child.id
        child.currentEpisodeId =   history.episodes[history.position].content_id.toStr()
        child.historyId =          history.id
        child.type =               m.constants.ui.contentTypes.series
        for each episode in history.episodes
          grandchild = child.createChild("HistoryContentNode")
          grandchild.id = episode.content_id.toStr()
          grandchild.historyId = episode.id
          grandchild.nowPos = episode.position
          grandchild.type = m.constants.ui.contentTypes.video
        end for
      end if
    end for
  end if
  return historyIds
end function