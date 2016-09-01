'a set of hepler functions that facilitate sending and receiving "Continue Watching"/history and "My Queue"/bookmarks
'info to the server (UAPI at the time of writing this comment)
Function TubiBookmarks(request as Object, auth as Object, constants as Object) as Object

  return {
    request: request
    auth: auth
    constants: constants

    'public methods
    addBookmarkReq: tubiBookmarks_addBookmarkReq
    removeBookmarkReq: tubiBookmarks_removeBookmarkReq
    addHistoryReq: tubiBookmarks_addHistoryReq
    removeHistoryReq: tubiBookmarks_removeHistoryReq
    getInitialBookmarksReq: tubiBookmarks_getInitialBookmarksReq
    getInitialHistoryReq: tubiBookmarks_getInitialHistoryReq
    getFullBookmarksReq: tubiBookmarks_getFullBookmarksReq
    getFullHistoryReq: tubiBookmarks_getFullHistoryReq
    handleInitialBookmarks: tubiBookmarks_handleInitialBookmarks
    handleInitialHistory: tubiBookmarks_handleInitialHistory

    'private methods
    createBookmarksRequest: tubiBookmarks_createBookmarksRequest_
    createHistoryRequest: tubiBookmarks_createHistoryRequest_
    getFullBookmarkOrHistory: tubiBookmarks_getFullBookmarkOrHistory_
  }
End Function


'returns a request object that can be used to add a bookmark to the server
'@content: can be a content node from scene graph or a content object from the main thread - expect either a video/movie or episode, no series
'     send either the video or the episode as the content, not the parent series
function tubiBookmarks_addBookmarkReq(content as Object) as Object
  bookmarkReq = invalid

  if content <> invalid
    'translate internal content type to UAPI content type
    contentType = invalid
    idToServe = content.id
    if content["type"] = m.constants.ui.contentTypes.video
      contentType = m.constants.uapiContentTypes.movie
      'if episodes was passed in, we need to get the id of the parent series since we don't bookmarks series
      if content.parentId <> invalid and content.parentId <> ""
        idToServe = content.parentId
        contentType = m.constants.uapiContentTypes.series
      end if
    else if content["type"] = m.constants.ui.contentTypes.series
      contentType = m.constants.uapiContentTypes.series
    else
      tubiLog("ERROR: Can't bookmark content that isn't a video, series, or episode")
      return invalid
    end if

    bookmarkReq = m.createBookmarksRequest(idToServe, "add", contentType)
  end if

  return bookmarkReq
end function


'returns a request object that can be used to remove a bookmark from the server
'@content: can be a content node from scene graph or a content object from the main thread - expect videos/movies or episodes, no series
'@bookmarkIdList: assocArray, {contentId: bookmarkId, ...}
function tubiBookmarks_removeBookmarkReq(content as Object, bookmarkIdList as Object) as Object
  bookmarkReq = invalid

  if content <> invalid and content.id <> invalid
    idToCheck = content.id
    
    'if episodes was passed in, we need to get the id of the parent series since we don't bookmarks series
    idToServe = content.bookmarkId
    if content.parentId <> invalid and content.parentId <> ""
      idToCheck = content.parentId
    end if

    if bookmarkIdList <> invalid then
      idToServe = bookmarkIdList.videos[idToCheck]
      if idToServe = invalid then
        idToServe = bookmarkIdList.series[idToCheck]
      end if
    end if
    
    if idToServe <> invalid
      bookmarkReq = m.createBookmarksRequest(idToServe, "delete")
    else
      tubiLog("idToServe was invalid, not found in bookmarkIdList")
    end if
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
    parentId = content.parentId 'is ok if parentId is invalid (ie. for movies)

    if content["type"] = m.constants.ui.contentTypes.video
      contentType = m.constants.uapiContentTypes.movie
      if parentId <> invalid and parentId <> ""
         contentType = m.constants.uapiContentTypes.episode
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
'@historyIdList: assocArray, {contentId: historyId, ...}
function tubiBookmarks_removeHistoryReq(content as Object, historyIdList as Object) as Object
  historyReq = invalid

  if content <> invalid
    idToCheck = content.id

    idToServe = content.historyId

    'set the episode's parent id as the id to check for the "history server id", since when we remove a history,
    'we remove the whole series not just the episode
    if content.parentId <> invalid and content.parentId <> ""
      idToCheck = content.parentId 
      
      if historyIdList <> invalid
        idToServe = historyIdList.series[idToCheck].serverId
      end if
    end if

    if idToServe <> invalid then
      historyReq = m.createHistoryRequest(idToServe, invalid, 0, "delete")
    end if
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
  authInfo = m.auth.getAuthInfo()  'from memory
  if authInfo.accessToken = invalid
    return invalid
  end if
  
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

  return historyReq
end function


'@localId: string, a string used to identify req when a response is received
function tubiBookmarks_getInitialBookmarksReq(localId) as Object
  authInfo = m.auth.getAuthInfo()  'from registry

  'if the user is not logged in (aka doesn't have an accessToken in local memory),
  'then don't get any bookmarks
  if authInfo.accessToken = invalid
    return invalid
  end if

  url = m.constants.urls.users.queues

  options = {
    method: m.constants.reqTypes.get
    params: {
      "page_enabled": false
    }
  }

  initialBookmarkReq = m.auth.createAuthRequest(url, "getInitialBookmarks", options)
  initialBookmarkReq.localId = localId

  return initialBookmarkReq
end function


'@localId: string, a string used to identify req when a response is received
function tubiBookmarks_getInitialHistoryReq(localId) as Object
  authInfo = m.auth.getAuthInfo()  'from registry

  'if the user is not logged in (aka doesn't have an accessToken in local memory),
  'then don't get any history items
  if authInfo.accessToken = invalid
    return invalid
  end if

  url = m.constants.urls.users.history

  options = {
    method: m.constants.reqTypes.get
    params: {
      "page_enabled": false
    }
  }

  initialHistoryReq = m.auth.createAuthRequest(url, "getInitialHistory", options)
  initialHistoryReq.localId = localId

  return initialHistoryReq
end function


'returns a request to use to get the full data for all bookmarked content
'@orderList: array, an array (typically stored on content controller) that has the order of all content in the user's bookmarks
'                each item in the array looks like:
'                           {
'                             cid: contentId
'                             type: contentType ("series" or "movie")
'                           }
function tubiBookmarks_getFullBookmarksReq(orderList as Object) as Object
  fullBookmarksReq = m.getFullBookmarkOrHistory(orderList, "Bookmarks")

  return fullBookmarksReq
end function



'returns a request to use to get the full data for all content stored in a user's history
'@orderList: array, an array (typically stored on content controller) that has the order of all content in the user's history
'                each item in the array looks like:
'                           {
'                             cid: contentId
'                             type: contentType ("series" or "movie")
'                           }
function tubiBookmarks_getFullHistoryReq(orderList as Object) as Object
  fullHistoryReq = m.getFullBookmarkOrHistory(orderList, "History")
  
  return fullHistoryReq
end function



'@orderList: array of assocArrays, an array that contains basic information returned from the initial call to get bookmarks or history and 
'                 retains the order of the contents
'@playlistType: string, just an identifier, not used in any logic. Typically would expect either "Bookmarks" or "History"
'
'returns an object that contains all the content for a metadataTaskThread, except the node and field properties (to be added after this function returns)
function tubiBookmarks_getFullBookmarkOrHistory_(orderList as Object, playlistType as String) as Object

  fullReq = invalid

  ids = ""
  for each item in orderList
    if type(item) = "roString" or type(item) = "String"
      ids = ids + "," + item
    end if
  end for
  
  ids = Right(ids, ids.len()-1)

  fullReq = {
    url: m.constants.urls.cms.contents
    name: "getFull" + playlistType
    options: {
      method: m.constants.reqTypes.get
      headers: m.constants.headers.json
      params: {
        platform: m.constants.platform
        "content_ids": ids
        "page_enabled": false
        fields: "*(id,type,title,duration,ratings,description,year,posterarts,subtitles,lang,url,publisher_id,actors,directors,tags,children,credit_cuepoints)"
      }
    }
  }

  return fullReq
end function


'@initialBookmarks: string, JSON server response when making the first call to UAPI to get a user's basic bookmark info
'returns an object with 2 keys, bookmarkIds and bookmarkOrder
'   bookmarkIds: assocArray, a map of contentIds to server bookmarksIds
'   bookmarkOrder: an array of contentIds (series have pre-pended 0), that keeps the order of bookmarks as returned from the server
function tubiBookmarks_handleInitialBookmarks(initialBookmarks)
  parsedInitialBookmarks = ParseJson(initialBookmarks)

  bookmarkOrder = []

  bookmarkIds = {
    'each videos and series assocArray should look like:
    '{contentId: bookmarkServerId, ...}
    videos: {}
    series: {}
  }

  for each bookmark in parsedInitialBookmarks.items
    if bookmark.content_type = m.constants.uapiContentTypes.movie
      bookmarkIds.videos[bookmark.content_id.toStr()] = bookmark.id

      bookmarkOrder.push(bookmark.content_id.toStr())

    else if bookmark.content_type = m.constants.uapiContentTypes.series
      bookmarkIds.series[bookmark.content_id.toStr()] = bookmark.id

      bookmarkOrder.push("0" + bookmark.content_id.toStr())
    end if
  end for

  return {
    bookmarkOrder: bookmarkOrder
    bookmarkIds: bookmarkIds
  }

end function



'@initialHistory: string, JSON server response when making the first call to UAPI to get a user's basic bookmark info
'returns an object with 2 keys, historyIds and historyOrder
'   historyIds: assocArray, a map of contentIds to server historysIds
'   historyOrder: an array of contentIds (series have pre-pended 0), that keeps the order of history as returned from the server
function tubiBookmarks_handleInitialHistory(initialHistory)
  parsedInitialHistory = ParseJson(initialHistory)
    'parse the initial bookmark response and create a list of bookmark server ids that will persist in the content controller
    parsedInitialHistory = ParseJson(initialHistory)

    historyOrder = []

    historyIds = {
      'each videos and series assocArray should look like:
      '{contentId: {
      '   serverId: historyServerId
      '   position: 365
      '  }
      '}
      videos: {}
      series: {}
    }

    for each history in parsedInitialHistory.items
      if history.content_type = m.constants.uapiContentTypes.movie
        historyIds.videos[history.content_id.toStr()] = {
          serverId: history.id
          position: history.position
        }

        historyOrder.push(history.content_id.toStr())

      else if history.content_type = m.constants.uapiContentTypes.series
        historyIds.series[history.content_id.toStr()] = {
          serverId: history.id
          currentEpisodeId: history.episodes[history.position].content_id.toStr()
        }

        for each episode in history.episodes
          historyIds.videos[episode.content_id.toStr()] = {
            serverId: episode.id
            position: episode.position
          }
        end for

        historyOrder.push("0" + history.content_id.toStr())

      end if
    end for

    return {
      historyOrder: historyOrder
      historyIds: historyIds
    }

end function
