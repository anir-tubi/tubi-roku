Function init()
  m.top.functionName = "execInitializeUserData"
End Function


'''''''''
' Synchronously load auth info, followed by loading of user categories (if user is logged in)
Function execInitializeUserData()
  tubiLog("AuthTask.execInitializeUserData")
  constants = m.global.constants
  Request = TubiRequest(constants.settings)
  Auth = TubiAuth(constants, Request)
  NodeHelpers = TubiNodeHelpers()
  apiUtilsLib = ApiUtils(constants)
  Bookmarks = TubiBookmarks(Request, Auth, constants, NodeHelpers, apiUtilsLib)
  authInfo = Auth.getAuthInfo()

  getUserInfo = false
  if isLoggedInUser(authInfo)
    getUserInfo = true
  end if

  userCats = getInitialUserCategories(Bookmarks, true, true, getUserInfo, true)
  ' enhance the auth tokens with the user profile information
  if authInfo <> invalid AND userCats.userInfo <> invalid
    tempAuthInfo = userCats.userInfo
    ' append the locally stored authInfo onto the newly received user info from the server
    ' to keep the userId as a string
    tempAuthInfo.append(authInfo)
    authInfo = tempAuthInfo
  end if

  ' guest users who have recently failed the age gate, continue to be locked in Kids mode for the entire
  ' 24 hour duration. Guest users who have not failed the age gate delete any previous hasAge info which
  ' ensures that no age gate is shown.
  if authInfo = invalid
    guestUserHasAgeInfo = Auth.getGuestUserHasAgeInfo()
    if guestUserHasAgeInfo.expired = true
      Auth.deleteGuestUserHasAgeInfo()
      m.top.guestUserHasAgeInfo = invalid
    else
      m.top.guestUserHasAgeInfo = guestUserHasAgeInfo
    end if
  end if

  m.top.bookmarks = userCats.newBookmarks
  m.top.history = userCats.newHistory
  m.top.likes = userCats.newLikes

  m.top.authInfo = authInfo  ' set last so that it can be used as a trigger
End Function


Function execRefreshAuthInfo()
  tubiLog("AuthTask.execRefreshAuthInfo")
  constants = m.global.constants
  Request = TubiRequest(constants.settings)
  Auth = TubiAuth(constants, Request)
  newAuthInfo = invalid

  ' only transfer the refresh token and log the external user in
  ' if there is no one currently logged in on the roku
  if m.top.externalAuthInfo <> invalid
    'this runs synchronously
    newAuthInfo = Auth.transferRefreshToken(m.top.externalAuthInfo)
  end if

  m.top.authInfoRefreshed = newAuthInfo
End Function


Function execSignOut()
  tubiLog("AuthTask.execSignOut")
  constants = m.global.constants 'single thread-local reference to avoid thread rendezvous
  Request = TubiRequest(constants.settings)
  Auth = TubiAuth(constants, Request)
  NodeHelpers = TubiNodeHelpers()

  Auth.logout()
  Auth.deleteGuestUserHasAgeInfo()

  apiUtilsLib = ApiUtils(constants)
  Bookmarks = TubiBookmarks(Request, Auth, constants, NodeHelpers, apiUtilsLib)

  userCats = getInitialUserCategories(Bookmarks, true, false, false, true)

  m.top.bookmarks = userCats.newBookmarks
  m.top.history = userCats.newHistory
  m.top.likes = userCats.newLikes
  m.top.guestUserHasAgeInfo = invalid
  m.top.authInfo = Auth.getAuthInfo()
End Function


Function getInitialUserCategories(Bookmarks, getHistory=true, getBookmarks=false, getUserInfo=false, getLikes=false)
  queuePort = CreateObject("roMessagePort")
  queue = TubiRequestQueue().create(queuePort)
  localBookmarkReqId = "bookmark"
  localHistoryReqId = "history"
  localLikeReqId = "like"
  localDislikeReqId = "dislike"
  ' return empty containers if user is not authenticated or requests fail
  newBookmarks = CreateObject("roSGNode", "BookmarkContentNode")
  newHistory = CreateObject("roSGNode", "HistoryContentNode")
  newLikes = CreateObject("roSGNode", "LikeContentNode")
  userCategories = {
    newBookmarks: newBookmarks
    newHistory: newHistory
    newLikes: newLikes
  }

  if getUserInfo = true
    userInfoReq = Bookmarks.getUserInfoReq()
    if userInfoReq <> invalid
      userInfoReq.localId = "userInfo"
      queue.pushRequest(userInfoReq)
    end if
  end if

  if getBookmarks = true
    initialBookmarksReq = Bookmarks.getInitialBookmarksReq(localBookmarkReqId)
    if initialBookmarksReq <> invalid then
      queue.pushRequest(initialBookmarksReq)
    end if
  end if

  if getHistory = true
    initialHistoryReq = Bookmarks.getInitialHistoryReq(localHistoryReqId)
    if initialHistoryReq <> invalid then
      queue.pushRequest(initialHistoryReq)
    end if
  end if

  if getLikes = true
    initialLikeReq = Bookmarks.getInitialLikeReq(localLikeReqId, true)
    if initialLikeReq <> invalid then
      queue.pushRequest(initialLikeReq)
    end if
    initialDislikeReq = Bookmarks.getInitialLikeReq(localDislikeReqId, false)
    if initialDislikeReq <> invalid then
      queue.pushRequest(initialDislikeReq)
    end if
  end if

  while queue.count() > 0
    msg = wait(0, queuePort)
    handledReq = queue.handleEvent(msg)
    if handledReq <> invalid
      'tubilog("*** execInitializeUserData: " + AnyToStringButNotInvalid(handledReq.localId) + " returned " + AnyToStringButNotInvalid(handledReq.response.code))
      if handledReq.response <> invalid AND handledReq.response.code >= 200 AND handledReq.response.code < 300 AND handledReq.hasData() = true
        if handledReq.localId = localBookmarkReqId
          userCategories.newBookmarks = Bookmarks.handleInitialBookmarks(handledReq.response.data)
        else if handledReq.localId = localHistoryReqId
          userCategories.newHistory = Bookmarks.handleInitialHistory(handledReq.response.data)
        else if handledReq.localId = "userInfo"
          userCategories.userInfo = Bookmarks.handleUserInfo(handledReq.response.data)
        else if handledReq.localId = "like" or handledReq.localId = "dislike"
          bLiked = (handledReq.localId = "like")
          userLikes = Bookmarks.handleInitialLikes(handledReq.response.data, bLiked)

          if type(userCategories.newLikes) = "roSGNode" AND userCategories.newLikes.getChildCount() > 0
            '//If newLikes already exists, then combine the other (like or disliked) array into one
            if type(userLikes.content) = "roSGNode" AND userLikes.content.getChildCount() > 0
              userCategories.newLikes.appendChildren(userLikes.content.getChildren(-1,0))
            end if
          else
            userCategories.newLikes = userLikes.content
          end if

          '//Handle pagination
          if isNonEmptyString(userLikes.nextPageId) = true
            paginationLikeReq = Bookmarks.getInitialLikeReq(handledReq.localId, bLiked, userLikes.nextPageId)
            if paginationLikeReq <> invalid
              queue.pushRequest(paginationLikeReq)
            end if
          end if

        end if
      end if
    end if
  end while

  return userCategories
End Function


Function execGetUserInfo()
  tubiLog("AuthTask.getUserInfo")
  constants = m.global.constants
  Request = TubiRequest(constants.settings)
  Auth = TubiAuth(constants, Request)
  NodeHelpers = TubiNodeHelpers()
  apiUtilsLib = ApiUtils(constants)
  Bookmarks = TubiBookmarks(Request, Auth, constants, NodeHelpers, apiUtilsLib)
  authInfo = Auth.getAuthInfo()

  result = getInitialUserCategories(Bookmarks, false, false, true, false)
  if result <> invalid AND result.userInfo <> invalid
    ' Just in case settings have changed, refresh the auth token
    Auth.refreshAuthToken(authInfo, 5)
    m.top.userInfo = result.userInfo
  else
    m.top.userInfo = invalid
  end if
End Function
