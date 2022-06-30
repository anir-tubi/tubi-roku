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
  apiUtils = ApiUtils(constants)
  Bookmarks = TubiBookmarks(Request, Auth, constants, NodeHelpers, apiUtils)
  authInfo = Auth.getAuthInfo()

  getUserInfo = false
  if isLoggedInUser(authInfo)
    getUserInfo = true
  end if

  userCats = getInitialUserCategories(Bookmarks, true, true, getUserInfo, true)
  ' enhance the auth tokens with the user profile information
  if authInfo <> invalid and userCats.userInfo <> invalid
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
  constants = m.global.constants 'single thread-local reference to avoid thread rendevue
  Request = TubiRequest(constants.settings)
  Auth = TubiAuth(constants, Request)
  NodeHelpers = TubiNodeHelpers()

  Auth.logout()
  Auth.deleteGuestUserHasAgeInfo()

  apiUtils = ApiUtils(constants)
  Bookmarks = TubiBookmarks(Request, Auth, constants, NodeHelpers, apiUtils)

  userCats = getInitialUserCategories(Bookmarks, true, false, false, true)

  m.top.bookmarks = userCats.newBookmarks
  m.top.history = userCats.newHistory
  m.top.likes = userCats.newLikes
  m.top.guestUserHasAgeInfo = invalid
  m.top.authInfo = Auth.getAuthInfo()
End Function


Function addToQueue()
  tubiLog("AuthTask.addToQueue")
  constants = m.global.constants
  Request = TubiRequest(constants.settings)
  Auth = TubiAuth(constants, Request)
  NodeHelpers = TubiNodeHelpers()
  apiUtils = ApiUtils(constants)
  Bookmarks = TubiBookmarks(Request, Auth, constants, NodeHelpers, apiUtils)
  request = Bookmarks.addBookmarkReq(m.top.content, m.top.isKidsMode)
  port = CreateObject("roMessagePort")
  if request <> invalid then
    request.start(port)

    while true
      msg = wait(0, port)
      result = request.handleEvent(msg)
      if result <> invalid and result.response <> invalid
        parsed = ParseJSON(result.response.data)
        if parsed <> invalid then
          m.top.addBookmarkResult = {
            bookmarkId: parsed.id
            code: result.response.code
          }
          tubiLog("addBookmark received bookmarkId " + parsed.id.toStr())
        else
          tubiLog("addBookmark failed to parse response")
          m.top.addBookmarkResult = {
            bookmarkId: ""
            code: result.response.code
          }
        end if
        exit while
      end if
    end while
  else
    tubiLog("addBookmarkReq returned invalid")
    ' this should never happen
    m.top.addBookmarkResult = {
      bookmarkId: ""
      code: -1
    }
  end if
  tubiLog("EXIT AuthTask.addToQueue")
End Function


Function removeFromQueue()
  tubiLog("AuthTask.removeFromQueue")
  constants = m.global.constants
  Request = TubiRequest(constants.settings)
  Auth = TubiAuth(constants, Request)
  NodeHelpers = TubiNodeHelpers()
  apiUtils = ApiUtils(constants)
  Bookmarks = TubiBookmarks(Request, Auth, constants, NodeHelpers, apiUtils)

  tubiLog("Removing bookmark id " + m.top.content.bookmarkId + " for content " + m.top.content.id)
  request = Bookmarks.removeBookmarkReq(m.top.content, m.top.isKidsMode)
  port = CreateObject("roMessagePort")
  if request <> invalid then
    request.start(port)
    while true
      msg = wait(0, port)
      result = request.handleEvent(msg)
      if result <> invalid then
        if result.response.code >= 200 and result.response.code < 300
          tubiLog("removeBookmarkReq received " + result.response.code.toStr())
        else
          tubiLog("removeBookmark failed")
        end if
        m.top.result = result
        exit while
      end if
    end while
  else
    tubiLog("removeBookmarkReq returned invalid")
    m.top.result = invalid
  end if
  tubiLog("EXIT AuthTask.removeFromQueue")
End Function


Function removeFromHistory()
  tubiLog("AuthTask.removeFromHistory")
  constants = m.global.constants
  Request = TubiRequest(constants.settings)
  Auth = TubiAuth(constants, Request)
  NodeHelpers = TubiNodeHelpers()
  apiUtils = ApiUtils(constants)
  Bookmarks = TubiBookmarks(Request, Auth, constants, NodeHelpers, apiUtils)

  authInfo = auth.getAuthInfo()
  if isLoggedInUser(authInfo)
    '//Remove the resume position history for signed in users

    tubiLog("Removing content " + m.top.content.id + " from history")
    request = Bookmarks.removeHistoryReq(m.top.content, m.top.isKidsMode)
    port = CreateObject("roMessagePort")
    if request <> invalid then
      request.start(port)
      while true
        msg = wait(0, port)
        result = request.handleEvent(msg)
        if result <> invalid then
          if result.response.code >= 200 and result.response.code < 300
            tubiLog("removeHistoryReq received " + result.response.code.toStr())
          else
            tubiLog("removeBookmark failed")
          end if
          m.top.result = result
          exit while
        end if
      end while
    else
      tubiLog("removeHistoryReq returned invalid")
      m.top.result = invalid
    end if
  else
    '//Remove the resume position history for signed out users
    Bookmarks.removeHistoryLocally(m.top.content, m.global)

    tubiLog("User is signed out so removeHistoryReq is returning a successful response for locally removed history")
    '//removing the history locally should mimic the return of a backend call to remove history
    '//   this is so the calling code doesn't have to keep track if thr user is signed in or not.
    result = {
      response: {
        code: 204
      }
    }
    m.top.result = result
  end if
  tubiLog("EXIT AuthTask.removeFromHistory")
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
      if handledReq.response <> invalid and handledReq.response.code >= 200 and handledReq.response.code < 300 and handledReq.hasData() = true
        if handledReq.localId = localBookmarkReqId
          userCategories.newBookmarks = Bookmarks.handleInitialBookmarks(handledReq.response.data)
        else if handledReq.localId = localHistoryReqId
          userCategories.newHistory = Bookmarks.handleInitialHistory(handledReq.response.data)
        else if handledReq.localId = "userInfo"
          userCategories.userInfo = Bookmarks.handleUserInfo(handledReq.response.data)
        else if handledReq.localId = "like" or handledReq.localId = "dislike"
          bLiked = (handledReq.localId = "like")
          userLikes = Bookmarks.handleInitialLikes(handledReq.response.data, bLiked)

          if type(userCategories.newLikes) = "roSGNode" and userCategories.newLikes.getChildCount() > 0
            '//If newLikes already exists, then combine the other (like or disliked) array into one
            if type(userLikes.content) = "roSGNode" and userLikes.content.getChildCount() > 0
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
  apiUtils = ApiUtils(constants)
  Bookmarks = TubiBookmarks(Request, Auth, constants, NodeHelpers, apiUtils)
  authInfo = Auth.getAuthInfo()

  result = getInitialUserCategories(Bookmarks, false, false, true, false)
  if result <> invalid and result.userInfo <> invalid
    ' Just in case settings have changed, refresh the auth token
    Auth.refreshAuthToken(authInfo, 5)
    m.top.userInfo = result.userInfo
  else
    m.top.userInfo = invalid
  end if
End Function