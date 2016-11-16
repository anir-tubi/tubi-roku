Function init()
  m.top.functionName = "execGetAuthInfo"
End Function

Function execGetAuthInfo()
  tubiLog("AuthTask.execGetAuthInfo")
  constants = m.global.constants
  Request = TubiRequest()
  Auth = TubiAuth(constants, Request)
  m.top.authInfo = Auth.getAuthInfo()
End Function

Function execSignOut()
  tubiLog("AuthTask.execSignOut")
  constants = m.global.constants 'single thread-local reference to avoid thread rendevue
  Request = TubiRequest()
  Auth = TubiAuth(constants, Request)
  Auth.logout()
  m.top.authInfo = invalid
End Function

Function getInitialUserCategories()
  tubiLog("AuthTask.getUserCategories")
  constants = m.global.constants
  Request = TubiRequest()
  Auth = TubiAuth(constants, Request)
  Bookmarks = TubiBookmarks(Request, Auth, constants)

  queuePort = CreateObject("roMessagePort")
  Queue = TubiRequestQueue()
  queue = Queue.create(queuePort)

  localBookmarkReqId = "bookmark"
  localHistoryReqId = "history"

  initialBookmarksReq = Bookmarks.getInitialBookmarksReq(localBookmarkReqId)
  if initialBookmarksReq <> invalid then queue.pushRequest(initialBookmarksReq)

  initialHistoryReq = Bookmarks.getInitialHistoryReq(localHistoryReqId)
  if initialHistoryReq <> invalid then queue.pushRequest(initialHistoryReq)

  if queue.count() > 0 then

    while true
      msg = wait(0, queuePort)
      handledReq = queue.handleEvent(msg)

      if handledReq <> invalid
        if handledReq.response <> invalid and handledReq.response.code >= 200 and handledReq.response.code < 300 and handledReq.hasData() = true
          if handledReq.localId = localBookmarkReqId
            m.top.initialBookmarks = handledReq.response.data
          else if handledReq.localId = localHistoryReqId
            m.top.initialHistory = handledReq.response.data
          end if
        end if
      end if

      'once we've received all our initial responses, shut down this loop
      if queue.count() = 0
        exit while
      end if
    end while
  end if

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
  request = Bookmarks.removeBookmarkReq(m.top.content, m.global.bookmarkIds)
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
  tubiLog("AuthTask.removeFromQueue")
  Request = TubiRequest()
  Auth = TubiAuth(m.global.constants, Request)
  Bookmarks = TubiBookmarks(Request, Auth, m.global.constants)

  tubiLog("Removing content " + m.top.content.id + " from history")
  request = Bookmarks.removeHistoryReq(m.top.content, m.global.historyIds)
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
