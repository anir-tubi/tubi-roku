
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
  NODEHELPERS = TubiNodeHelpers()
  BM = TubiBookmarks(REQUEST, AUTH, constants, NODEHELPERS)
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
  NODEHELPERS = TubiNodeHelpers()
  BM = TubiBookmarks(REQUEST, AUTH, constants, NODEHELPERS)
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
  NODEHELPERS = TubiNodeHelpers()
  BM = TubiBookmarks(REQUEST, AUTH, constants, NODEHELPERS)
  content = CreateObject("roSGNode", "TubiContentNode")
  content.type = "series"
  content.id = "01079"
  content.title = "S02:E05 - You, I'll Be Following"
  req = BM.addBookmarkReq(content)
  t.assertNotInvalid(req)
End Function

Function testAddBookmarkReqEpisodeWithParent(t As Object)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = mockAuth_Authorized(constants, REQUEST)
  NODEHELPERS = TubiNodeHelpers()
  BM = TubiBookmarks(REQUEST, AUTH, constants, NODEHELPERS)
  content = CreateObject("roSGNode", "TubiContentNode")
  content.type = "video"
  content.id = "302800"
  content.title = "S02:E05 - You, I'll Be Following"
  content.parentId = "01079"
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
  NODEHELPERS = TubiNodeHelpers()
  BM = TubiBookmarks(REQUEST, AUTH, constants, NODEHELPERS)
  content = CreateObject("roSGNode", "TubiContentNode")
  content.type = "series"
  content.id = "01079"
  content.title = "S02:E05 - You, I'll Be Following"
  content.bookmarkId = "AABBCCDD"
  req = BM.removeBookmarkReq(content)
  t.assertNotInvalid(req)
End Function


''''''''''''''''
' addHistoryReq
''''''''''''''''

Function xtestAddHistoryReqVideo(t As Object)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = mockAuth_Authorized(constants, REQUEST)
  NODEHELPERS = TubiNodeHelpers()
  BM = TubiBookmarks(REQUEST, AUTH, constants, NODEHELPERS)
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
  NODEHELPERS = TubiNodeHelpers()
  BM = TubiBookmarks(REQUEST, AUTH, constants, NODEHELPERS)
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
  NODEHELPERS = TubiNodeHelpers()
  BM = TubiBookmarks(REQUEST, AUTH, constants, NODEHELPERS)
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
  NODEHELPERS = TubiNodeHelpers()
  BM = TubiBookmarks(REQUEST, AUTH, constants, NODEHELPERS)
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

Function testGetInitialBookmarksReqSignedOut(t As Object)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = mockAuth_Unauthorized(constants, REQUEST)
  NODEHELPERS = TubiNodeHelpers()
  BM = TubiBookmarks(REQUEST, AUTH, constants, NODEHELPERS)
  req = BM.getInitialBookmarksReq("1234")
  t.assertInvalid(req)
End Function

Function testGetInitialBookmarksReqSignedIn(t As Object)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = mockAuth_Authorized(constants, REQUEST)
  NODEHELPERS = TubiNodeHelpers()
  BM = TubiBookmarks(REQUEST, AUTH, constants, NODEHELPERS)
  req = BM.getInitialBookmarksReq("1234")
  t.assertNotInvalid(req)
End Function

Function testGetInitialHistoryReqSignedOut(t As Object)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = mockAuth_Unauthorized(constants, REQUEST)
  NODEHELPERS = TubiNodeHelpers()
  BM = TubiBookmarks(REQUEST, AUTH, constants, NODEHELPERS)
  req = BM.getInitialHistoryReq("1234")
  t.assertInvalid(req)
End Function

Function testGetInitialHistoryReqSignedIn(t As Object)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = mockAuth_Authorized(constants, REQUEST)
  NODEHELPERS = TubiNodeHelpers()
  BM = TubiBookmarks(REQUEST, AUTH, constants, NODEHELPERS)
  req = BM.getInitialHistoryReq("1234")
  t.assertNotInvalid(req)
End Function

Function testHandleInitialBookmarks(t As Object)
  serverBookmarks = {
    "total_count": 2,
    "more": false,
    "items": [
      {
        "content_id": 321251,
        "content_type": "movie",
        "user_id": 3684839,
        "created_at": "2017-10-17T18:48:23.525Z",
        "updated_at": "2017-10-17T18:48:23.525Z",
        "id": "59e65077c97ab1787294c764"
      },
      {
        "content_id": 2071,
        "content_type": "series",
        "user_id": 3684839,
        "created_at": "2017-10-15T02:14:09.253Z",
        "updated_at": "2017-10-15T02:14:09.253Z",
        "id": "59e2c4719f86a9d9163cb17d"
      }
    ]
  }
  serverJson = FormatJson(serverBookmarks)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = mockAuth_Authorized(constants, REQUEST)
  NODEHELPERS = TubiNodeHelpers()
  BM = TubiBookmarks(REQUEST, AUTH, constants, NODEHELPERS)
  bookmarks = BM.handleInitialBookmarks(serverJson)
  t.assertNotInvalid(bookmarks)
  t.assertEqual(bookmarks.getChildCount(), 2)
  t.assertEqual(bookmarks.getChild(0).subType(), "BookmarkContentNode")
  t.assertEqual(bookmarks.getChild(0).id, "321251")
  t.assertEqual(bookmarks.getChild(0).type, "video")
  t.assertEqual(bookmarks.getChild(1).id, "02071")
  t.assertEqual(bookmarks.getChild(1).type, "series")
End Function

Function testHandleInitialHistory(t As Object)
  serverHistory = {
    "total_count": 2
    "more": false
    "items": [
      {
        "content_id": 334155
        "content_type": "movie"
        "user_id": 3684839
        "position": 229
        "state": "middle"
        "content_length": 0
        "updated_at": "2017-10-24T20:45:15.185Z"
        "created_at": "2017-01-10T20:09:58.780Z"
        "id": "58753f96da0d8f5191001f1b"
      },
      {
        "content_id": 1737
        "content_type": "series"
        "user_id": 3684839
        "position": 2
        "state": "opened"
        "updated_at": "2017-01-10T18:20:39.563Z"
        "episodes": [
          {
            "content_id": 325942
            "user_id": 3684839
            "position": 2720
            "state": "opened"
            "content_length": -1
            "id": "58236b43da0d8f51916fd020"
          },
          {
            "content_id": 325943
            "user_id": 3684839
            "position": 2730
            "state": "opened"
            "content_length": -1
            "id": "58236bacda0d8f51916fd0d9"
          },
          {
            "content_id": 325944
            "user_id": 3684839
            "position": 42
            "state": "opened"
            "content_length": -1
            "id": "58236bf7da0d8f51916fd14f"
          },
          {
            "content_id": 325949
            "user_id": 3684839
            "position": 2710
            "state": "opened"
            "content_length": -1
            "id": "58236d46da0d8f51916fd35f"
          }
        ],
        "created_at": "2016-11-09T18:32:12.645Z",
        "id": "58236bacda0d8f51916fd0da"
      },
    ]
  }
  serverJson = FormatJson(serverHistory)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = mockAuth_Authorized(constants, REQUEST)
  NODEHELPERS = TubiNodeHelpers()
  BM = TubiBookmarks(REQUEST, AUTH, constants, NODEHELPERS)
  history = BM.handleInitialHistory(serverJson)
  t.assertNotInvalid(history)
  t.assertEqual(history.getChildCount(), 2)
  t.assertEqual(history.getChild(0).subType(), "HistoryContentNode")
  t.assertEqual(history.getChild(0).id, "334155")
  t.assertEqual(history.getChild(0).historyId, "58753f96da0d8f5191001f1b")
  t.assertEqual(history.getChild(0).nowPos, 229)
  t.assertEqual(history.getChild(0).type, "video")
  t.assertEqual(history.getChild(1).id, "01737")
  t.assertEqual(history.getChild(1).currentEpisodeId, "325944")
  t.assertEqual(history.getChild(1).type, "series")
  t.assertEqual(history.getChild(1).getChildCount(), 4)
  t.assertEqual(history.getChild(1).getChild(0).id, "325942")
  t.assertEqual(history.getChild(1).getChild(0).historyId, "58236b43da0d8f51916fd020")
  t.assertEqual(history.getChild(1).getChild(0).nowPos, 2720)
  t.assertEqual(history.getChild(1).getChild(0).type, "video")
End Function
