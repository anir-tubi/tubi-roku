'a set of helper functions that facilitate sending and receiving "Continue Watching"/history and "My Queue"/bookmarks
'info to the server (UAPI at the time of writing this comment)
Function TubiBookmarksForAuthTask(request as Object, auth as Object, constants as Object, nodeHelpers as Object, apiUtils as Object) as Object
  defaultValues = {
    request: request
    auth: auth
    constants: constants
    nodeHelpers: nodeHelpers

    'public methods
    addHistoryLocally: tubiBookmarks_addHistoryLocally
    updateLikesLocally: tubiBookmarks_updateLikesLocally
    addLinearLikeLocally: tubiBookmarks_addLinearLikeLocally
    removeLinearLikeLocally: tubiBookmarks_removeLinearLikeLocally
    getInitialBookmarksReq: tubiBookmarks_getInitialBookmarksReq
    getInitialHistoryReq: tubiBookmarks_getInitialHistoryReq
    getInitialLikeReq: tubiBookmarks_getInitialLikeReq
    handleInitialBookmarks: tubiBookmarks_handleInitialBookmarks
    handleInitialHistory: tubiBookmarks_handleInitialHistory
    handleInitialLikes: tubiBookmarks_handleInitialLikes
    getUserInfoReq: tubiBookmarks_getUserInfoReq
    handleUserInfo: tubiBookmarks_handleUserInfo

    'private methods
    isLoggedInUser: tubiBookmarks_isLoggedInUser
  }

  tubiBookmarks = {}
  tubiBookmarks.append(apiUtils)
  tubiBookmarks.append(defaultValues)

  return tubiBookmarks
End Function


' Creates queue/bookmark/my list and history/continue watching functionality for use in general task parsers
Function TubiBookmarks(constants)
  return {
    constants: constants

    'public methods
    translateQueueIds: tubiBookmarks_translateQueueIds
    translateHistoryIds: tubiBookmarks_translateHistoryIds
    addHistoryLocally: tubiBookmarks_addHistoryLocally
    updateLikesLocally: tubiBookmarks_updateLikesLocally
    addLinearLikeLocally: tubiBookmarks_addLinearLikeLocally
    removeLinearLikeLocally: tubiBookmarks_removeLinearLikeLocally
  }
End Function



'saves the resume point locally and does not communicate to the backend.
' @content: can be a content node from scene graph or a content object from the main thread - expect either a video/movie or episode, no series
' @position: position where user left off of video
' @global: The global object to be used to save the data
Function tubiBookmarks_addHistoryLocally(content as Object, position as Integer, global = invalid)
  if content <> invalid AND global <> invalid AND global.historyIds <> invalid

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

        if isNonEmptyString(content.historyId) = true
          childNode.historyId = content.historyId
        end if
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

      if isNonEmptyString(content.historyId) = true
        historyNode.historyId = content.historyId
      end if
    end if
  end if
End Function


' @param contentId, String: the ID of the title to change it's liking
' @param sRatingAction, String: The Action enum to alter the like state of the provided content ID. The possible values are all under m.constants.ui.likeDislikeActions
Function tubiBookmarks_updateLikesLocally(contentId as String, sRatingAction as String, global = invalid)
  if contentId <> invalid AND global <> invalid AND global.likeIds <> invalid
    likeNode = getLike(contentId) 'bs:disable-line 1001 LINT1001

    sState = ""
    if sRatingAction = m.constants.ui.likeDislikeActions.like
      sState = m.constants.ui.likeDislikeStates.liked
    else if sRatingAction = m.constants.ui.likeDislikeActions.dislike
      sState = m.constants.ui.likeDislikeStates.disliked
    end if

    if sState = ""
        '//remove the like
        if likeNode <> invalid
          global.likeIds.removeChild(likeNode)
        end if
    else
      '//update or add the like
      if likeNode = invalid
        likeNode = global.likeIds.createChild("LikeContentNode")
        likeNode.id = contentId
      end if
      likeNode.state = sState
    end if
  end if
End Function


' @param contentId, String: Liked Channel's ID
' @global: The global object is passed here to avoid rendezvous
Function tubiBookmarks_addLinearLikeLocally(contentId as string, global = invalid)

  if contentId <> invalid AND global <> invalid AND global.linearLikeIds <> invalid

    linearLikeNode = getLinearLike(contentId) 'bs:disable-line 1001 LINT1001

    '// save the linearChannel been liked
    if linearLikeNode = invalid
      linearLikeNode = global.linearLikeIds.createChild("LikeContentNode")
      linearLikeNode.id = contentId
    end if

    linearLikeNode.state = m.constants.ui.likeDislikeStates.liked

  end if

End Function


' @param contentId, String: Disliked Channel's ID.
' @global: The global object is passed here to avoid rendezvous
Function tubiBookmarks_removeLinearLikeLocally(contentId as string, global = invalid)
  if contentId <> invalid AND global <> invalid AND global.linearLikeIds <> invalid

    linearLikeNode = getLinearLike(contentId) 'bs:disable-line 1001 LINT1001

    '//remove if linearChannel been disliked
    if linearLikeNode <> invalid
      global.linearLikeIds.removeChild(linearLikeNode)
    end if
  end if

End Function



'@localId: string, a string used to identify req when a response is received
Function tubiBookmarks_getInitialBookmarksReq(localId) as Object
  authInfo = m.auth.getAuthInfo()  'from registry

  'if the user is not logged in (aka doesn't have an accessToken in local memory),
  'then don't get any bookmarks
  if m.isLoggedInUser(authInfo) = false
    return invalid
  end if

  url = m.constants.urls.userQueues.queues

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

  url = m.constants.urls.lishi.viewHistory

  options = {
    method: m.constants.reqTypes.get
    params: {
      "page_enabled": false
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


'@param localId: string, a string used to identify req when a response is received
'@param bLiked: Boolean, Is this a "like" request? If not, it is a "dislike" request
'@param nextPageId: string, the paginated ID of the next page of likes/dislikes
'@param target: string "target" for VODs and "lienar" for linear contents
Function tubiBookmarks_getInitialLikeReq(localId, bLiked = true, nextPageId = "", target = "title") as Object
  authInfo = m.auth.getAuthInfo()  'from registry

  'if the user is not logged in (aka doesn't have an accessToken in local memory),
  'then don't get likes
  if m.isLoggedInUser(authInfo) = false
    return invalid
  end if

  url = m.constants.urls.account.contentRating
  sLikeType = "liked"
  if bLiked = false
    sLikeType = "disliked"
  end if

  options = {
    method: m.constants.reqTypes.get
    params: {
      "page_enabled": false
      target: target
      limit: 100
      type: sLikeType
      platform: m.constants.platform
      "deviceId": m.constants.deviceInfo.deviceId
    }
  }
  if nextPageId <> ""
    options.params.start = nextPageId
  end if

  initialReq = m.auth.createAuthRequest(url, "getInitialLikes", options)
  'auth.createAuthRequest() returns invalid if user is not logged in
  if initialReq = invalid
    initialReq = m.request.createAsync(url, "getInitialLikes", options)
  end if

  if initialReq <> invalid then
    initialReq.localId = localId
  end if

  return initialReq
End Function


'@initialBookmarks: string, JSON server response when making the first call to UAPI to get a user's basic bookmark info
'returns bookmarkIds ordered node tree with series having episode children
Function tubiBookmarks_handleInitialBookmarks(initialBookmarks)
  bookmarkIds = CreateObject("roSGNode", "BookmarkContentNode")
  parsedInitialBookmarks = ParseJson(initialBookmarks)
  if parsedInitialBookmarks <> Invalid
    for each bookmark in parsedInitialBookmarks.queues
      child = bookmarkIds.createChild("BookmarkContentNode")
      child.id = bookmark.content_id.toStr()
      child.bookmarkId = bookmark.id
      if bookmark.content_type = m.constants.uapiContentTypes.movie
        child.type = m.constants.ui.contentTypes.video
      else if bookmark.content_type = m.constants.uapiContentTypes.series
        child.id = "0" + child.id
        child.type = m.constants.ui.contentTypes.series
      else if bookmark.content_type = m.constants.uapiContentTypes.sportsEvent
        child.type = m.constants.ui.contentTypes.sportsEvent
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
      if history.content_type = m.constants.uapiContentTypes.movie OR history.content_type = m.constants.uapiContentTypes.sportsEvent
        child.historyId = history.id
        child.nowPos = history.position
        child.type = m.constants.ui.contentTypes.video
      else if history.content_type = m.constants.uapiContentTypes.series
        child.id = "0" + child.id
        child.historyId = history.id
        child.type = m.constants.ui.contentTypes.series

        if history.episodes <> invalid AND history.position <> invalid AND history.episodes[history.position] <> invalid
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


'@initialLikes: string, JSON server response when making the first call to UAPI to get a user's like history info
'returns likeIds ordered node tree
Function tubiBookmarks_handleInitialLikes(initialLikes, bLiked = true)
  returnParsed = {}
  itemIds = CreateObject("roSGNode", "LikeContentNode")
  parsedInitialData = ParseJson(initialLikes)
  if parsedInitialData <> invalid AND parsedInitialData.data <> invalid AND parsedInitialData.data.count() > 0
    for i = 0 to parsedInitialData.data.count() - 1
      child = itemIds.createChild("LikeContentNode")
      child.id = parsedInitialData.data[i]
      if bLiked = true
        child.state = m.constants.ui.likeDislikeStates.liked
      else
        child.state = m.constants.ui.likeDislikeStates.disliked
      end if
    end for
  end if
  returnParsed.content = itemIds
  returnParsed.nextPageId = parsedInitialData.next
  return returnParsed
End Function


Function tubiBookmarks_getUserInfoReq()
  authInfo = m.auth.getAuthInfo()
  if m.isLoggedInUser(authInfo) = false
    return invalid
  end if
  url = m.constants.urls.account.userSettings
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

    if parsed.parental_rating <> invalid
      result.parentalRating = parsed.parental_rating

      if isGDPR() = true 'bs:disable-line 1001 LINT1001

        'Setting Parental Control option to Older Kids for nz & uk region, if the parental option was selected as Teens from other region
        if parsed.parental_rating = 2
          result.parentalRating = 1
        end if
      end if
    end if

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


Function tubiBookmarks_isLoggedInUser(authInfo)
  return (authInfo <> invalid AND authInfo.userId <> invalid)
End Function


'@initialBookmarks: array, brightscript representation of backend's JSON response upon fetching a user's bookmarks/queue/MyList
'@returns: roSGNode, parent node with each child representing a content in the user's queue.
'                    Children nodes are ordered in the same order as returned by the backend.
Function tubiBookmarks_translateQueueIds(initialBookmarks)
  bookmarkIds = CreateObject("roSGNode", "BookmarkContentNode")

  if initialBookmarks <> invalid
    for each bookmark in initialBookmarks.queues
      if bookmark.content_id <> invalid
        child = bookmarkIds.createChild("BookmarkContentNode")
        childId = bookmark.content_id.toStr()
        child.bookmarkId = bookmark.id

        if bookmark.content_type = m.constants.uapiContentTypes.movie
          child.id = childId
          child.type = m.constants.ui.contentTypes.video
        else if bookmark.content_type = m.constants.uapiContentTypes.series
          child.id = "0" + childId
          child.type = m.constants.ui.contentTypes.series
        else if bookmark.content_type = m.constants.uapiContentTypes.sportsEvent
          child.id = childId
          child.type = m.constants.ui.contentTypes.sportsEvent
        end if
      end if
    end for
  end if

  return bookmarkIds
End Function


'@initialBookmarks: array, brightscript representation of backend's JSON response upon fetching a user's history/continue watching
'@returns: roSGNode, parent node with each child representing a content in the user's history.
'                    Series nodes have children representing episodes.
'                    Children nodes are ordered in the same order as returned by the backend.
Function tubiBookmarks_translateHistoryIds(initialHistory)
  historyIds = CreateObject("roSGNode", "HistoryContentNode")

  if initialHistory <> invalid then
    for each history in initialHistory.items
      if history.content_id <> invalid
        child = historyIds.createChild("HistoryContentNode")
        childId = history.content_id.toStr()
        if history.content_type = m.constants.uapiContentTypes.movie OR history.content_type = m.constants.uapiContentTypes.sportsEvent
          child.id = childId
          child.historyId = history.id
          child.nowPos = history.position
          child.type = m.constants.ui.contentTypes.video
        else if history.content_type = m.constants.uapiContentTypes.series
          child.id = "0" + childId
          child.historyId = history.id
          child.type = m.constants.ui.contentTypes.series

          if history.episodes <> invalid AND history.position <> invalid AND history.episodes[history.position] <> invalid
            currentEpisode = history.episodes[history.position]
            if currentEpisode.content_id <> invalid
              child.currentEpisodeId = currentEpisode.content_id.toStr()
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
      end if
    end for
  end if

  return historyIds
End Function
