Function TestSuite_TubiBookmarks()
  this = BaseTestSuite()
  this.name = "TubiBookmarksTestSuite"
  this.addTest("addBookmarkReq_unauthorized", testCase_tubiBookmarks_addBookmarkReqUnauthorized)
  this.addTest("addBookmarkReq_movie", testCase_tubiBookmarks_addBookmarkReqMovie)
  this.addTest("addBookmarkReq_series", testCase_tubiBookmarks_addBookmarkReqSeries)
  this.addTest("addBookmarkReq_episodeWithParent", testCase_tubiBookmarks_addBookmarkReqEpisodeWithParent)
  this.addTest("removeBookmarkReq", testCase_tubiBookmarks_removeBookmarkReq)
  this.addTest("addHistoryReq_video", testCase_tubiBookmarks_addHistoryReqVideo)
  this.addTest("addHistoryReq_episodeWithParent", testCase_tubiBookmarks_addHistoryReqEpisodeWithParent)
  this.addTest("addHistoryReq_episodeWithoutParent", testCase_tubiBookmarks_addHistoryReqEpisodeWithoutParent)
  this.addTest("addHistoryReq_series", testCase_tubiBookmarks_addHistoryReqSeries)
  this.addTest("getInitialBookmarksReq_signedOut", testCase_tubiBookmarks_getInitialBookmarksReqSignedOut)
  this.addTest("getInitialBookmarksReq_signedOut_guestHistoryEnabled", testCase_tubiBookmarks_getInitialHistoryReqSignedOutGuestHistoryEnabled)
  this.addTest("getInitialBookmarksReq_signedIn", testCase_tubiBookmarks_getInitialBookmarksReqSignedIn)
  this.addTest("getInitialHistoryReq_signedOut", testCase_tubiBookmarks_getInitialHistoryReqSignedOut)
  this.addTest("getInitialHistoryReq_signedIn", testCase_tubiBookmarks_getInitialHistoryReqSignedIn)
  this.addTest("handleInitialBookmarks", testCase_tubiBookmarks_handleInitialBookmarks)
  this.addTest("handleInitialHistory", testCase_tubiBookmarks_handleInitialHistory)
  return this
End Function


' MOCKS
''''''''''''''''
' Mock for when a user is not logged in
Function testHelper_tubiBookmarks_mockAuth_Unauthorized(constants, request)
  auth = TubiAuth(constants, request)
  auth.getAuthInfo = Function() As Object
    return invalid
  End Function
  return auth
End Function

' Mock for when a user is authenticatd
Function testHelper_tubiBookmarks_mockAuth_Authorized(constants, request)
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

Function testCase_tubiBookmarks_addBookmarkReqUnauthorized()
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = testHelper_tubiBookmarks_mockAuth_Unauthorized(constants, REQUEST)
  NODEHELPERS = TubiNodeHelpers()
  BM = TubiBookmarks(REQUEST, AUTH, constants, NODEHELPERS)
  content = CreateObject("roSGNode", "TubiContentNode")

  ' Type: Movie
  content.type = "video"
  content.id = "321221"
  content.title = "We Are Young"
  req = BM.addBookmarkReq(content)
  return m.assertInvalid(req)
End Function

Function testCase_tubiBookmarks_addBookmarkReqMovie()
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = testHelper_tubiBookmarks_mockAuth_Authorized(constants, REQUEST)
  NODEHELPERS = TubiNodeHelpers()
  BM = TubiBookmarks(REQUEST, AUTH, constants, NODEHELPERS)
  content = CreateObject("roSGNode", "TubiContentNode")
  content.type = "video"
  content.id = "321221"
  content.title = "We Are Young"
  req = BM.addBookmarkReq(content)
  return m.assertNotInvalid(req)
End Function

Function testCase_tubiBookmarks_addBookmarkReqSeries()
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = testHelper_tubiBookmarks_mockAuth_Authorized(constants, REQUEST)
  NODEHELPERS = TubiNodeHelpers()
  BM = TubiBookmarks(REQUEST, AUTH, constants, NODEHELPERS)
  content = CreateObject("roSGNode", "TubiContentNode")
  content.type = "series"
  content.id = "01079"
  content.title = "S02:E05 - You, I'll Be Following"
  req = BM.addBookmarkReq(content)
  return m.assertNotInvalid(req)
End Function

Function testCase_tubiBookmarks_addBookmarkReqEpisodeWithParent()
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = testHelper_tubiBookmarks_mockAuth_Authorized(constants, REQUEST)
  NODEHELPERS = TubiNodeHelpers()
  BM = TubiBookmarks(REQUEST, AUTH, constants, NODEHELPERS)
  content = CreateObject("roSGNode", "TubiContentNode")
  content.type = "video"
  content.id = "302800"
  content.title = "S02:E05 - You, I'll Be Following"
  content.parentId = "01079"
  req = BM.addBookmarkReq(content)
  return m.assertNotInvalid(req)
End Function

''''''''''''''''''''
' removeBookmarkReq
''''''''''''''''''''

Function testCase_tubiBookmarks_removeBookmarkReq()
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = testHelper_tubiBookmarks_mockAuth_Authorized(constants, REQUEST)
  NODEHELPERS = TubiNodeHelpers()
  BM = TubiBookmarks(REQUEST, AUTH, constants, NODEHELPERS)
  content = CreateObject("roSGNode", "TubiContentNode")
  content.type = "series"
  content.id = "01079"
  content.title = "S02:E05 - You, I'll Be Following"
  content.bookmarkId = "AABBCCDD"
  req = BM.removeBookmarkReq(content)
  return m.assertNotInvalid(req)
End Function


''''''''''''''''
' addHistoryReq
''''''''''''''''

Function testCase_tubiBookmarks_addHistoryReqVideo()
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = testHelper_tubiBookmarks_mockAuth_Authorized(constants, REQUEST)
  NODEHELPERS = TubiNodeHelpers()
  BM = TubiBookmarks(REQUEST, AUTH, constants, NODEHELPERS)
  content = CreateObject("roSGNode", "TubiContentNode")
  content.type = "video"
  content.id = "321221"
  content.title = "We Are Young"
  req = BM.addHistoryReq(content, 1478)
  return m.assertNotInvalid(req)
End Function

Function testCase_tubiBookmarks_addHistoryReqEpisodeWithParent()
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = testHelper_tubiBookmarks_mockAuth_Authorized(constants, REQUEST)
  NODEHELPERS = TubiNodeHelpers()
  BM = TubiBookmarks(REQUEST, AUTH, constants, NODEHELPERS)
  content = CreateObject("roSGNode", "TubiContentNode")
  content.type = "video"
  content.id = "302800"
  content.title = "S02:E05 - You, I'll Be Following"
  content.parentId = "1079"
  req = BM.addHistoryReq(content, 1478)
  return m.assertNotInvalid(req)
End Function

' For now, episodes without a parent reference will get sent to the server.  TODO(Chris): Check that server allows this
Function testCase_tubiBookmarks_addHistoryReqEpisodeWithoutParent()
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = testHelper_tubiBookmarks_mockAuth_Authorized(constants, REQUEST)
  NODEHELPERS = TubiNodeHelpers()
  BM = TubiBookmarks(REQUEST, AUTH, constants, NODEHELPERS)
  content = CreateObject("roSGNode", "TubiContentNode")
  content.type = "video"
  content.id = "302800"
  content.title = "S02:E05 - You, I'll Be Following"
  req = BM.addHistoryReq(content, 1478)
  return m.assertNotInvalid(req)
End Function

' we can only bookmark an episode or movie
Function testCase_tubiBookmarks_addHistoryReqSeries()
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = testHelper_tubiBookmarks_mockAuth_Authorized(constants, REQUEST)
  NODEHELPERS = TubiNodeHelpers()
  BM = TubiBookmarks(REQUEST, AUTH, constants, NODEHELPERS)
  content = CreateObject("roSGNode", "TubiContentNode")
  content.type = "series"
  content.id = "1079"
  content.title = "S02:E05 - You, I'll Be Following"
  req = BM.addHistoryReq(content, 1478)
  return m.assertInvalid(req)
End Function

Function testCase_tubiBookmarks_getInitialBookmarksReqSignedOut()
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = testHelper_tubiBookmarks_mockAuth_Unauthorized(constants, REQUEST)
  NODEHELPERS = TubiNodeHelpers()
  BM = TubiBookmarks(REQUEST, AUTH, constants, NODEHELPERS)
  req = BM.getInitialBookmarksReq("1234")
  return m.assertInvalid(req)
End Function

Function testCase_tubiBookmarks_getInitialBookmarksReqSignedIn()
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = testHelper_tubiBookmarks_mockAuth_Authorized(constants, REQUEST)
  NODEHELPERS = TubiNodeHelpers()
  BM = TubiBookmarks(REQUEST, AUTH, constants, NODEHELPERS)
  req = BM.getInitialBookmarksReq("1234")
  return m.assertNotInvalid(req)
End Function

Function testCase_tubiBookmarks_getInitialHistoryReqSignedOut()
  constants = getConstants()
  constants.ui.users.guestHistory = false
  REQUEST = TubiRequest()
  AUTH = testHelper_tubiBookmarks_mockAuth_Unauthorized(constants, REQUEST)
  NODEHELPERS = TubiNodeHelpers()
  BM = TubiBookmarks(REQUEST, AUTH, constants, NODEHELPERS)
  req = BM.getInitialHistoryReq("1234")
  return m.assertInvalid(req)
End Function

Function testCase_tubiBookmarks_getInitialHistoryReqSignedOutGuestHistoryEnabled()
  constants = getConstants()
  constants.ui.users.guestHistory = true
  REQUEST = TubiRequest()
  AUTH = testHelper_tubiBookmarks_mockAuth_Unauthorized(constants, REQUEST)
  NODEHELPERS = TubiNodeHelpers()
  BM = TubiBookmarks(REQUEST, AUTH, constants, NODEHELPERS)
  req = BM.getInitialHistoryReq("1234")
  return m.assertNotInvalid(req)
End Function

Function testCase_tubiBookmarks_getInitialHistoryReqSignedIn()
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = testHelper_tubiBookmarks_mockAuth_Authorized(constants, REQUEST)
  NODEHELPERS = TubiNodeHelpers()
  BM = TubiBookmarks(REQUEST, AUTH, constants, NODEHELPERS)
  req = BM.getInitialHistoryReq("1234")
  return m.assertNotInvalid(req)
End Function

Function testCase_tubiBookmarks_handleInitialBookmarks()
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
  AUTH = testHelper_tubiBookmarks_mockAuth_Authorized(constants, REQUEST)
  NODEHELPERS = TubiNodeHelpers()
  BM = TubiBookmarks(REQUEST, AUTH, constants, NODEHELPERS)
  bookmarks = BM.handleInitialBookmarks(serverJson)
  result = m.assertNotInvalid(bookmarks)
  result += m.assertEqual(bookmarks.getChildCount(), 2)
  result += m.assertEqual(bookmarks.getChild(0).subType(), "BookmarkContentNode")
  result += m.assertEqual(bookmarks.getChild(0).id, "321251")
  result += m.assertEqual(bookmarks.getChild(0).type, "video")
  result += m.assertEqual(bookmarks.getChild(1).id, "02071")
  result += m.assertEqual(bookmarks.getChild(1).type, "series")
  return result
End Function

Function testCase_tubiBookmarks_handleInitialHistory()
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
      }
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
          }
          {
            "content_id": 325943
            "user_id": 3684839
            "position": 2730
            "state": "opened"
            "content_length": -1
            "id": "58236bacda0d8f51916fd0d9"
          }
          {
            "content_id": 325944
            "user_id": 3684839
            "position": 42
            "state": "opened"
            "content_length": -1
            "id": "58236bf7da0d8f51916fd14f"
          }
          {
            "content_id": 325949
            "user_id": 3684839
            "position": 2710
            "state": "opened"
            "content_length": -1
            "id": "58236d46da0d8f51916fd35f"
          }
        ]
        "created_at": "2016-11-09T18:32:12.645Z"
        "id": "58236bacda0d8f51916fd0da"
      }
    ]
  }
  serverJson = FormatJson(serverHistory)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = testHelper_tubiBookmarks_mockAuth_Authorized(constants, REQUEST)
  NODEHELPERS = TubiNodeHelpers()
  BM = TubiBookmarks(REQUEST, AUTH, constants, NODEHELPERS)
  history = BM.handleInitialHistory(serverJson)
  result = m.assertNotInvalid(history)
  result += m.assertEqual(history.getChildCount(), 2)
  result += m.assertEqual(history.getChild(0).subType(), "HistoryContentNode")
  result += m.assertEqual(history.getChild(0).id, "334155")
  result += m.assertEqual(history.getChild(0).historyId, "58753f96da0d8f5191001f1b")
  result += m.assertEqual(history.getChild(0).nowPos, 229)
  result += m.assertEqual(history.getChild(0).type, "video")
  result += m.assertEqual(history.getChild(1).id, "01737")
  result += m.assertEqual(history.getChild(1).currentEpisodeId, "325944")
  result += m.assertEqual(history.getChild(1).type, "series")
  result += m.assertEqual(history.getChild(1).getChildCount(), 4)
  result += m.assertEqual(history.getChild(1).getChild(0).id, "325942")
  result += m.assertEqual(history.getChild(1).getChild(0).historyId, "58236b43da0d8f51916fd020")
  result += m.assertEqual(history.getChild(1).getChild(0).nowPos, 2720)
  result += m.assertEqual(history.getChild(1).getChild(0).type, "video")
  return result
End Function
