Function init()
  m.top.functionName = "execInitializeUserData"
End Function

'''''''''
' Synchronously load auth info, followed by loading of user categories (if user is logged in)
Function execInitializeUserData()
  tubiLog("AuthTask.execInitializeUserData")
  constants = m.global.constants
  Request = TubiRequest()
  Auth = TubiAuth(constants, Request)
  Bookmarks = TubiBookmarks(Request, Auth, constants)
  authInfo = Auth.getAuthInfo()
  queuePort = CreateObject("roMessagePort")
  queue = TubiRequestQueue().create(queuePort)
  localBookmarkReqId = "bookmark"
  localHistoryReqId = "history"

  initialBookmarksReq = Bookmarks.getInitialBookmarksReq(localBookmarkReqId)
  if initialBookmarksReq <> invalid then
    queue.pushRequest(initialBookmarksReq)
  else
    m.top.bookmarks = invalid
  end if

  initialHistoryReq = Bookmarks.getInitialHistoryReq(localHistoryReqId)
  if initialHistoryReq <> invalid then
    queue.pushRequest(initialHistoryReq)
  else
    m.top.history = invalid
  end if

  while queue.count() > 0
    msg = wait(0, queuePort)
    handledReq = queue.handleEvent(msg)
    if handledReq <> invalid
      print "*** execInitializeUserData: "; handledReq.localId; " returned "; handledReq.response.code
      if handledReq.response <> invalid and handledReq.response.code >= 200 and handledReq.response.code < 300 and handledReq.hasData() = true
        if handledReq.localId = localBookmarkReqId
          m.top.bookmarks = Bookmarks.handleInitialBookmarks(handledReq.response.data)
        else if handledReq.localId = localHistoryReqId
          m.top.history = Bookmarks.handleInitialHistory(handledReq.response.data)
        end if
      end if
    end if
  end while
  m.top.authInfo = authInfo  ' set last so that it can be used as a trigger 
End Function

Function execSignOut()
  tubiLog("AuthTask.execSignOut")
  constants = m.global.constants 'single thread-local reference to avoid thread rendevue
  Request = TubiRequest()
  Auth = TubiAuth(constants, Request)
  Auth.logout()
  m.top.authInfo = invalid
End Function

Function addToQueue()
  tubiLog("AuthTask.addToQueue")
  Request = TubiRequest()
  Auth = TubiAuth(m.global.constants, Request)
  Bookmarks = TubiBookmarks(Request, Auth, m.global.constants)
  request = Bookmarks.addBookmarkReq(m.top.content)
  port = CreateObject("roMessagePort")
  if request <> invalid then
    request.start(port)

    while true
      msg = wait(0, port)
      result = request.handleEvent(msg)
      if result <> invalid then
        tubiLog("addBookmarkReq returned " + tostr(result.response.code))
        parsed = ParseJSON(result.response.data)
        if parsed <> invalid then
          m.top.bookmarkId = parsed.id
          tubiLog("addBookmark received bookmarkId " + tostr(parsed.id))
        else
          tubiLog("addBookmark failed to parse response")
          m.top.bookmarkId = invalid
        end if
        exit while
      end if
    end while
  else
    tubiLog("addBookmarkReq returned invalid")
    m.top.bookmarkId = ""
  end if
  tubiLog("EXIT AuthTask.addToQueue")
End Function

Function removeFromQueue()
  tubiLog("AuthTask.removeFromQueue")
  Request = TubiRequest()
  Auth = TubiAuth(m.global.constants, Request)
  Bookmarks = TubiBookmarks(Request, Auth, m.global.constants)

  tubiLog("Removing bookmark id " + m.top.content.bookmarkId + " for content " + m.top.content.id)
  request = Bookmarks.removeBookmarkReq(m.top.content)
  port = CreateObject("roMessagePort")
  if request <> invalid then
    request.start(port)
    while true
      msg = wait(0, port)
      result = request.handleEvent(msg)
      if result <> invalid then
        if result.response.code >= 200 and result.response.code < 300
          tubiLog("removeBookmarkReq received " + tostr(result.response.code))
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
  Request = TubiRequest()
  Auth = TubiAuth(m.global.constants, Request)
  Bookmarks = TubiBookmarks(Request, Auth, m.global.constants)

  tubiLog("Removing content " + m.top.content.id + " from history")
  request = Bookmarks.removeHistoryReq(m.top.content)
  port = CreateObject("roMessagePort")
  if request <> invalid then
    request.start(port)
    while true
      msg = wait(0, port)
      result = request.handleEvent(msg)
      if result <> invalid then
        if result.response.code >= 200 and result.response.code < 300
          tubiLog("removeHistoryReq received " + tostr(result.response.code))
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
  tubiLog("EXIT AuthTask.removeFromHistory")
End Function

Function updateHistory()
  tubiLog("AuthTask.updateHistory")
  Request = TubiRequest()
  Auth = TubiAuth(m.global.constants, Request)
  Bookmarks = TubiBookmarks(Request, Auth, m.global.constants)

  'only do the following if the user is logged in
  if m.top.content <> invalid and m.top.authInfo <> invalid and m.top.authInfo.accessToken <> invalid
    tubiLog("Adding content " + m.top.content.id + " from history at position " + stri(m.top.nowPos))
    newHistoryReq = Bookmarks.addHistoryReq(m.top.content, m.top.nowPos)
    result = newHistoryReq.runSynchronous()  ' timeout default is 5 seconds
    historyResult = {}

    if result <> invalid then
      parsedResp = parseJson(result)

      'check if we have the response for a history API call
      if parsedResp <> invalid and parsedResp.id <> invalid
        if parsedResp.episodes <> invalid and type(parsedResp.episodes) = "roArray" and parsedResp.episodes.count() > 0
          historyResult.historyId = parsedResp.episodes[0].id
          historyResult.parentHistoryId = parsedResp.id
        else
          historyResult.historyId = parsedResp.id
        end if
      end if
    end if
    m.top.historyResult = historyResult  ' with result
    tubiLog("EXIT AuthTask.updateHistory")
  end if
End Function
