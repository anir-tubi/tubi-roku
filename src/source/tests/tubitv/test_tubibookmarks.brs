
''''''''''''''''
' MOCKS
''''''''''''''''
' Mock for when a user is not logged in
Function mockAuth_Unauthorized(constants, request)
  auth = TubiAuth(constants, request)
  auth.getAuthInfo = Function() As Object
    return invalid
  End Function
  return auth
End Function

' Mock for when a user is authenticatd
Function mockAuth_Authorized(constants, request)
  auth = TubiAuth(constants, request)
  auth.getAuthInfo = Function() As Object
      return {
        accessToken: "1617181920212223242526"
        refreshToken: "123456789101112131415"
        expireTime: 1472745278
        userId: "TubiBookmarksTest"
      }
    End Function
  return auth
End Function


''''''''''''''''
' TESTS
''''''''''''''''


''''''''''''''''''
' addBookmarkReq
''''''''''''''''''

Function testAddBookmarkReqUnauthorized(t As Object)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = mockAuth_Unauthorized(constants, REQUEST)
  BM = TubiBookmarks(REQUEST, AUTH, constants)
  content = CreateObject("roSGNode", "TubiContentNode")

  ' Type: Movie
  content.type = "video"
  content.id = "321221"
  content.title = "We Are Young"
  req = BM.addBookmarkReq(content)
  t.assertInvalid(req)
End Function

Function testAddBookmarkReqMovie(t As Object)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = mockAuth_Authorized(constants, REQUEST)
  BM = TubiBookmarks(REQUEST, AUTH, constants)
  content = CreateObject("roSGNode", "TubiContentNode")
  content.type = "video"
  content.id = "321221"
  content.title = "We Are Young"
  req = BM.addBookmarkReq(content)
  t.assertNotInvalid(req)
End Function

Function testAddBookmarkReqSeries(t As Object)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = mockAuth_Authorized(constants, REQUEST)
  BM = TubiBookmarks(REQUEST, AUTH, constants)
  content = CreateObject("roSGNode", "TubiContentNode")
  content.type = "series"
  content.id = "1079"
  content.title = "S02:E05 - You, I'll Be Following"
  req = BM.addBookmarkReq(content)
  t.assertNotInvalid(req)
End Function

Function testAddBookmarkReqEpisodeWithParent(t As Object)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = mockAuth_Authorized(constants, REQUEST)
  BM = TubiBookmarks(REQUEST, AUTH, constants)
  content = CreateObject("roSGNode", "TubiContentNode")
  content.type = "video"
  content.id = "302800"
  content.title = "S02:E05 - You, I'll Be Following"
  content.parentId = "1079"
  req = BM.addBookmarkReq(content)
  t.assertNotInvalid(req)
End Function

''''''''''''''''''''
' removeBookmarkReq
''''''''''''''''''''

Function testRemoveBookmarkReq(t As Object)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = mockAuth_Authorized(constants, REQUEST)
  BM = TubiBookmarks(REQUEST, AUTH, constants)
  content = CreateObject("roSGNode", "TubiContentNode")
  content.type = "series"
  content.id = "1079"
  content.title = "S02:E05 - You, I'll Be Following"
  bookmarkList = { 
    videos: {}
    series: {
      "1079": "AABBCCDD"
    }
  }
  req = BM.removeBookmarkReq(content, bookmarkList)
  t.assertNotInvalid(req)
End Function


''''''''''''''''
' addHistoryReq
''''''''''''''''

Function xtestAddHistoryReqVideo(t As Object)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = mockAuth_Authorized(constants, REQUEST)
  BM = TubiBookmarks(REQUEST, AUTH, constants)
  content = CreateObject("roSGNode", "TubiContentNode")
  content.type = "video"
  content.id = "321221"
  content.title = "We Are Young"
  req = BM.addHistoryReq(content, 1478)
  t.assertNotInvalid(req)
End Function

Function xtestAddHistoryReqEpisodeWithParent(t As Object)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = mockAuth_Authorized(constants, REQUEST)
  BM = TubiBookmarks(REQUEST, AUTH, constants)
  content = CreateObject("roSGNode", "TubiContentNode")
  content.type = "video"
  content.id = "302800"
  content.title = "S02:E05 - You, I'll Be Following"
  content.parentId = "1079"
  req = BM.addHistoryReq(content, 1478)
  t.assertNotInvalid(req)
End Function

' For now, episodes without a parent reference will get sent to the server.  TODO(Chris): Check that server allows this
Function testAddHistoryReqEpisodeWithoutParent(t As Object)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = mockAuth_Authorized(constants, REQUEST)
  BM = TubiBookmarks(REQUEST, AUTH, constants)
  content = CreateObject("roSGNode", "TubiContentNode")
  content.type = "video"
  content.id = "302800"
  content.title = "S02:E05 - You, I'll Be Following"
  req = BM.addHistoryReq(content, 1478)
  t.assertNotInvalid(req)
End Function

' we can only bookmark an episode or movie
Function testAddHistoryReqSeries(t As Object)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = mockAuth_Authorized(constants, REQUEST)
  BM = TubiBookmarks(REQUEST, AUTH, constants)
  content = CreateObject("roSGNode", "TubiContentNode")
  content.type = "series"
  content.id = "1079"
  content.title = "S02:E05 - You, I'll Be Following"
  req = BM.addHistoryReq(content, 1478)
  t.assertInvalid(req)
End Function

''''''''''''''''
' removeHistoryReq
''''''''''''''''

Function xtestRemoveHistoryReq(t As Object)
  'TODO(Chris)
End Function

Function xtestGetInitialBookmarksReq(t As Object)
  'TODO(Chris)
End Function

Function xtestGetInitialHistoryReq(t As Object)
  'TODO(Chris)
End Function

Function xtestHandleInitialBookmarks(t As Object)
  'TODO(Chris)
End Function

Function xtestHandleInitialHistory(t As Object)
  'TODO(Chris)
End Function

