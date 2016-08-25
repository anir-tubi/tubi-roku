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
    if content["type"] = m.constants.ui.contentTypes.video
      contentType = m.constants.uapiContentTypes.movie
    end if


    idToServe = content.id
    if idToServe <> invalid

      'if episodes was passed in, we need to get the id of the parent series since we don't bookmarks series
      if content.parentId <> invalid
        idToServe = content.parentId
        contentType = m.constants.uapiContentTypes.series
      end if

      bookmarkReq = m.createBookmarksRequest(idToServe, "add", contentType)
    end if
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
    if content.parentId <> invalid
      idToCheck = content.parentId
    end if
    
    'get the "bookmark server id" that is expected by the API to delete the bookmark on the server
    'the "bookmark server id" is returned to us from the server when we add the bookmark or get all bookmarks
    idToServe = invalid
    if bookmarkIdList <> invalid
      idToServe = bookmarkIdList[idToCheck]
    end if

    if idToServe <> invalid
      bookmarkReq = m.createBookmarksRequest(idToServe, "delete")
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
  if authInfo.accessToken = invalid
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


    if idToServe <> invalid
      contentType = m.constants.uapiContentTypes.movie
      if parentId <> invalid
        contentType = m.constants.uapiContentTypes.episode
      end if

      historyReq = m.createHistoryRequest(idToServe, parentId, position, "add", contentType)
    end if
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

    'set the episode's parent id as the id to check for the "history server id", since when we remove a history,
    'we remove the whole series not just the episode
    if content.parentId <> invalid
      idToCheck = content.parentId 
    end if

    idToServe = historyIdList[idToCheck]

    if idToServe <> invalid
      'translate internal content types to UAPI content types
      contentType = m.constants.uapiContentTypes.movie
      if content.parentId <> invalid
        contentType = m.constants.uapiContentTypes.episode
      end if

      historyReq = m.createHistoryRequest(idToServe, invalid, invalid, "delete")
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
function tubiBookmarks_createHistoryRequest_(id as String, parentId as Dynamic, position as Integer, action as String, contentType = "" as String) as Object
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



function tubiBookmarks_getInitialBookmarksReq() as Object
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

  return initialBookmarkReq
end function


function tubiBookmarks_getInitialHistoryReq() as Object
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

  return initialHistoryReq
end function


'returns a request to use to get the full data for all bookmarked content
'@basicsFromServer: string, the unparsed data returned from the server after making a call to the request created by m.getInitialBookmarksReq()
function tubiBookmarks_getFullBookmarksReq(basicsFromServer as String) as Object
  fullBookmarksReq = m.getFullBookmarkOrHistory(basicsFromServer, "Bookmarks")

  return fullBookmarksReq
end function



'returns a request to use to get the full data for all content stored in a user's history
'@basicsFromServer: string, the unparsed data returned from the server after making a call to the request created by m.getInitialHistoryReq()
function tubiBookmarks_getFullHistoryReq(basicsFromServer as String) as Object
  fullHistoryReq = m.getFullBookmarkOrHistory(basicsFromServer, "History")
  
  return fullHistoryReq
end function



'@basicsFromServer: string, the unparsed data returned from the server after making a call to the
'   request created by m.getInitialHistoryReq() or m.getInitialBookmarksReq()
'@playlistType: string, just an identifier, not used in any logic. Typically would expect either "Bookmarks" or "History"
function tubiBookmarks_getFullBookmarkOrHistory_(basicsFromServer as String, playlistType as String) as Object
  if basicsFromServer <> invalid and basicsFromServer.len() > 0
    basicsFromServer = ParseJson(basicsFromServer)
  else
    return invalid
  end if

  fullReq = invalid

  if basicsFromServer <> invalid
    if basicsFromServer.total_count <> invalid and basicsFromServer.total_count > 0
      basicItems = basicsFromServer.items '[]'

      if basicItems <> invalid
        ids = ""
        
        for each item in basicItems

          if item.content_type = "series"
            id = "0" + item.content_id.toStr()
            ids = ids + "," + id
          else if item.content_type = "movie" or item.content_type = "video"
            id = item.content_id.toStr()
            ids = ids + "," + id
          end if
        end for
        
        ids = Right(ids, ids.len()-1)

        url = m.constants.urls.cms.contents

        options = {
          method: m.constants.reqTypes.get
          headers: m.constants.headers.json
          params: {
            platform: m.constants.platform
            "content_ids": ids
            "page_enabled": false
            fields: "*(id,type,title,duration,ratings,description,year,posterarts,subtitles,lang,url,publisher_id,actors,directors,tags,children,credit_cuepoints)"
          }
        }

        fullReq = m.request.createAsync(url, "getFull" + playlistType, options)
      end if

    end if
  end if

  return fullReq
end function

