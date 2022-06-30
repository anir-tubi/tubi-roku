'@TestSuite [TubiBookmarks] TubiBookmarks.brs

'@Setup
Function TubiBookmarksSetup()

  constants = getConstants()
  request = TubiRequest()
  nodeHelpers = TubiNodeHelpers()

  unauthorized = tubiBookmarks_mockAuth_Unauthorized_testHelper(constants, request)
  utils = ApiUtils(constants)

  m.unauthorizedBM = TubiBookmarks(request, unauthorized, constants, nodeHelpers, utils)

  authorized = tubiBookmarks_mockAuth_Authorized_testHelper(constants, request)
  m.authorizedBM = TubiBookmarks(request, authorized, constants, nodeHelpers, utils)

  m.videoContent = CreateObject("roSGNode", "TubiContentNode")
  m.videoContent.type = "video"

  m.movieContent = CreateObject("roSGNode", "TubiContentNode")
  m.movieContent.type = "movie"

  m.seriesContent = CreateObject("roSGNode", "TubiContentNode")
  m.seriesContent.type = "series"

  m.episodeContent = CreateObject("roSGNode", "TubiContentNode")
  m.episodeContent.type = "episode"

  m.historyUrl = constants.urls.userDevice.history
  m.deviceId = constants.deviceInfo.deviceId
  m.appName = constants.appName
  m.platform = constants.platform

End Function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in TubiBookmarks.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


' set up global fields
Function tubiBookmarks_setupGlobalFields_testHelper()

  m.global.addField("bookmarkIds", "node", false)
  m.global.bookmarkIds = CreateObject("roSGNode", "BookmarkContentNode")

  m.global.addField("historyIds", "node", false)
  m.global.historyIds = CreateObject("roSGNode", "HistoryContentNode")

  m.global.addField("likeIds", "node", false)
  m.global.likeIds = CreateObject("roSGNode", "LikeContentNode")

End Function


' Mock for when a user is not logged in
Function tubiBookmarks_mockAuth_Unauthorized_testHelper(constants, request)
  auth = TubiAuth(constants, request)
  auth.getAuthInfo = Function() As Object
    return invalid
  End Function
  return auth
End Function


' Mock for when a user is authenticatd
Function tubiBookmarks_mockAuth_Authorized_testHelper(constants, request)
  auth = TubiAuth(constants, request)
  auth.getAuthInfo = Function() As Object
      return {
        accessToken: "1617181920212223242526"
        refreshToken: "123456789101112131415"
        expireTime: 1472745278
        userId: "121212"
      }
    End Function
  return auth
End Function


'@Test addBookmarkReqUnauthorized unit tests
Function tubiBookmarks_addBookmarkReqUnauthorized_test()
  BM = m.unauthorizedBM
  content = m.videoContent
  content.id = "321221"
  content.title = "We Are Young"
  req = BM.addBookmarkReq(content)
  m.assertInvalid(req)
End Function


'@Test addBookmarkReqMovie unit tests
Function tubiBookmarks_addBookmarkReqMovie_test()
  BM = m.authorizedBM
  content = m.videoContent
  content.id = "321221"
  content.title = "We Are Young"
  req = BM.addBookmarkReq(content)
  m.assertNotInvalid(req)
End Function


'@Test addBookmarkReqSeries unit tests
Function tubiBookmarks_addBookmarkReqSeries_test()
  BM = m.authorizedBM
  content = m.seriesContent
  content.id = "01079"
  content.title = "S02:E05 - You, I'll Be Following"
  req = BM.addBookmarkReq(content)
  m.assertNotInvalid(req)
End Function


'@Test addBookmarkReqEpisodeWithParent unit tests
Function tubiBookmarks_addBookmarkReqEpisodeWithParent_test()
  BM = m.authorizedBM
  content = m.videoContent
  content.id = "302800"
  content.title = "S02:E05 - You, I'll Be Following"
  content.parentId = "01079"
  req = BM.addBookmarkReq(content)
  m.assertNotInvalid(req)
End Function


'@Test removeBookmarkReq unit tests
Function tubiBookmarks_removeBookmarkReq_test()
  BM = m.authorizedBM
  content = m.seriesContent
  content.id = "01079"
  content.title = "S02:E05 - You, I'll Be Following"
  content.bookmarkId = "AABBCCDD"
  req = BM.removeBookmarkReq(content)
  m.assertNotInvalid(req)
End Function


'@Test a successful attempt at calling removeHistoryLocally unit test
Function tubiBookmarks_removeBookmarkLocallySuccessful_test()

  tubiBookmarks_setupGlobalFields_testHelper()

  BM = m.authorizedBM
  content = m.videoContent
  content.id = "321221"
  content.title = "We Are Young"

  nPositionToSave = 300
  BM.addHistoryLocally(content, nPositionToSave, m.global)
  historyNode = m.global.historyIds.findNode(content.id)
  '//1) Test that the content has been successfully been added
  m.assertEqual(historyNode.nowPos, nPositionToSave)


  BM.removeHistoryLocally(content, m.global)
  historyNode = m.global.historyIds.findNode(content.id)
  '//2) The content should have been successfully been removed, so history should be invalid
  m.assertInvalid(historyNode)
  '//::TODO::like - add like test to this and other unit test functions if like/dislike experiment gets approved - (or immediately after like/dislike experiment launches)
End Function


'@Test addHistoryLocally unit tests
Function tubiBookmarks_addBookmarkLocallySuccessful_test()

  tubiBookmarks_setupGlobalFields_testHelper()

  BM = m.authorizedBM
  content = m.videoContent
  content.id = "321221"
  content.title = "We Are Young"
  nPositionToSave = 300
  BM.addHistoryLocally(content, nPositionToSave, m.global)

  historyNode = m.global.historyIds.findNode(content.id)
  '//The content should have been successfully been added, so history should be valid
  m.assertNotInvalid(historyNode)
  m.assertEqual(historyNode.nowPos, nPositionToSave)
End Function


'@Test addHistoryLocally unit tests for an episode
Function tubiBookmarks_addBookmarkLocallySuccessfulForEpisode_test()

  tubiBookmarks_setupGlobalFields_testHelper()

  BM = m.authorizedBM
  content = m.seriesContent
  content.id = "302800"
  content.title = "S02:E05 - You, I'll Be Following"
  content.parentId = "01079"
  content.parentType = BM.constants.uapiContentTypes.series

  nPositionToSave = 300
  BM.addHistoryLocally(content, nPositionToSave, m.global)

  historyNode = m.global.historyIds.findNode(content.id)
  '//The content should have been successfully been added, so history should be valid
  m.assertNotInvalid(historyNode)
  m.assertEqual(historyNode.nowPos, nPositionToSave)
End Function


'@Test addHistoryReqVideo_ParentIdAsInvalid unit tests
Function tubiBookmarks_addHistoryReqVideo_ParentIdAsInvalid_test()
  BM = m.authorizedBM
  content = m.movieContent
  content.id = "321221"
  content.title = "We Are Young"
  content.parentId = invalid
  req = BM.addHistoryReq(content, 1478)

  m.assertNotInvalid(req)
  m.assertNotInvalid(req.url)
  m.assertEqual(m.historyUrl, req.url)

  options = req.options
  m.assertNotInvalid(options)

  body = ParseJson(options.body)
  m.assertEqual(content.id, body.content_id)
  m.assertEqual(content.type, body.content_type)
  m.assertEqual(m.deviceId, body.device_id)
  m.assertInvalid(body.parent_id)

  userId = BM.auth.getAuthInfo().userid
  m.assertEqual(userId.toInt(), body.user_id)
  m.assertEqual(1478, body["position"])

  headers = options.headers

  clientVersion = BM.constants.deviceInfo.clientVersion

  m.assertEqual(headers["x-client-version"], clientVersion)
  m.assertEqual(headers["x-client-platform"], "roku")

  m.assertEqual(options.params.device_id, m.deviceId)
  m.assertEqual(options.params.app_id, m.appName)
  m.assertEqual(options.params.isKidsMode, false)
  m.assertEqual(options.params.platform, m.platform)

End Function


'@Test addHistoryReqVideo_ParentIdAsEmpty unit tests
Function tubiBookmarks_addHistoryReqVideo_ParentIdAsEmpty_test()
  BM = m.authorizedBM
  content = m.movieContent
  content.id = "321221"
  content.title = "We Are Young"
  content.parentId = ""
  req = BM.addHistoryReq(content, 1478)

  m.assertNotInvalid(req)
  m.assertNotInvalid(req.url)
  m.assertEqual(m.historyUrl, req.url)

  options = req.options
  m.assertNotInvalid(options)

  body = ParseJson(options.body)
  m.assertEqual(content.id, body.content_id)
  m.assertEqual(content.type, body.content_type)
  m.assertEqual(m.deviceId, body.device_id)
  m.assertInvalid(body.parent_id)

  userId = BM.auth.getAuthInfo().userid
  m.assertEqual(userId.toInt(), body.user_id)
  m.assertEqual(1478, body["position"])

  headers = options.headers

  clientVersion = BM.constants.deviceInfo.clientVersion

  m.assertEqual(headers["x-client-version"], clientVersion)
  m.assertEqual(headers["x-client-platform"], "roku")

  m.assertEqual(options.params.device_id, m.deviceId)
  m.assertEqual(options.params.app_id, m.appName)
  m.assertEqual(options.params.isKidsMode, false)
  m.assertEqual(options.params.platform, m.platform)

End Function


'@Test addHistoryReqEpisodeParentIdAsString unit tests
Function tubiBookmarks_addHistoryReqEpisodeParentIdAsString_test()
  BM = m.authorizedBM
  content = m.episodeContent
  content.id = "302800"
  content.title = "S02:E05 - You, I'll Be Following"
  content.parentId = "1079"

  req = BM.addHistoryReq(content, 1478)

  m.assertNotInvalid(req)
  m.assertNotInvalid(req.url)
  m.assertEqual(m.historyUrl, req.url)

  options = req.options
  m.assertNotInvalid(options)

  body = ParseJson(options.body)
  m.assertEqual(content.id, body.content_id)
  m.assertEqual(content.type, body.content_type)
  m.assertEqual(m.deviceId, body.device_id)

  m.assertEqual(1079, body.parent_id)

  userId = BM.auth.getAuthInfo().userid
  m.assertEqual(userId.toInt(), body.user_id)
  m.assertEqual(1478, body["position"])

  headers = options.headers

  clientVersion = BM.constants.deviceInfo.clientVersion

  m.assertEqual(headers["x-client-version"], clientVersion)
  m.assertEqual(headers["x-client-platform"], "roku")

  m.assertEqual(options.params.device_id, m.deviceId)
  m.assertEqual(options.params.app_id, m.appName)
  m.assertEqual(options.params.isKidsMode, false)
  m.assertEqual(options.params.platform, m.platform)
End Function


'@Test addHistoryReqEpisodeParentIdAsInteger unit tests
Function tubiBookmarks_addHistoryReqEpisodeParentIdAsInteger_test()
  BM = m.authorizedBM
  content = m.episodeContent
  content.id = "302800"
  content.title = "S02:E05 - You, I'll Be Following"
  content.parentId = 1079

  req = BM.addHistoryReq(content, 1478)

  m.assertNotInvalid(req)
  m.assertNotInvalid(req.url)
  m.assertEqual(m.historyUrl, req.url)

  options = req.options
  m.assertNotInvalid(options)

  body = ParseJson(options.body)
  m.assertEqual(content.id, body.content_id)
  m.assertEqual(content.type, body.content_type)
  m.assertEqual(m.deviceId, body.device_id)

  m.assertEqual(1079, body.parent_id)

  userId = BM.auth.getAuthInfo().userid
  m.assertEqual(userId.toInt(), body.user_id)
  m.assertEqual(1478, body["position"])

  headers = options.headers

  clientVersion = BM.constants.deviceInfo.clientVersion

  m.assertEqual(headers["x-client-version"], clientVersion)
  m.assertEqual(headers["x-client-platform"], "roku")

  m.assertEqual(options.params.device_id, m.deviceId)
  m.assertEqual(options.params.app_id, m.appName)
  m.assertEqual(options.params.isKidsMode, false)
  m.assertEqual(options.params.platform, m.platform)
End Function


'@Test getInitialBookmarksReqSignedOut unit tests
Function tubiBookmarks_getInitialBookmarksReqSignedOut_test()
  BM = m.unauthorizedBM
  req = BM.getInitialBookmarksReq("1234")
  m.assertInvalid(req)
End Function


'@Test getInitialBookmarksReqSignedIn unit tests
Function tubiBookmarks_getInitialBookmarksReqSignedIn_test()
  BM = m.authorizedBM
  req = BM.getInitialBookmarksReq("1234")
  m.assertNotInvalid(req)
End Function


'@Test getInitialHistoryReqSignedOut unit tests
Function tubiBookmarks_getInitialHistoryReqSignedOut_test()
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = tubiBookmarks_mockAuth_Unauthorized_testHelper(constants, REQUEST)
  NODEHELPERS = TubiNodeHelpers()
  utils = ApiUtils(constants)
  BM = TubiBookmarks(REQUEST, AUTH, constants, NODEHELPERS, utils)
  req = BM.getInitialHistoryReq("1234")
  m.assertInvalid(req)
End Function



'@Test getInitialHistoryReqSignedIn unit tests
Function tubiBookmarks_getInitialHistoryReqSignedIn_test()
  BM = m.authorizedBM
  req = BM.getInitialHistoryReq("1234")
  m.assertNotInvalid(req)
End Function


'@Test handleInitialBookmarks unit tests
Function tubiBookmarks_handleInitialBookmarks_test()
  BM = m.authorizedBM
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
  bookmarks = BM.handleInitialBookmarks(serverJson)
  m.assertNotInvalid(bookmarks)
  m.assertEqual(bookmarks.getChildCount(), 2)
  m.assertEqual(bookmarks.getChild(0).subType(), "BookmarkContentNode")
  m.assertEqual(bookmarks.getChild(0).id, "321251")
  m.assertEqual(bookmarks.getChild(0).type, "video")
  m.assertEqual(bookmarks.getChild(1).id, "02071")
  m.assertEqual(bookmarks.getChild(1).type, "series")
End Function


'@Test handleInitialHistory unit tests
Function tubiBookmarks_handleInitialHistory_test()
  BM = m.authorizedBM
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
  history = BM.handleInitialHistory(serverJson)
  m.assertNotInvalid(history)
  m.assertEqual(history.getChildCount(), 2)
  m.assertEqual(history.getChild(0).subType(), "HistoryContentNode")
  m.assertEqual(history.getChild(0).id, "334155")
  m.assertEqual(history.getChild(0).historyId, "58753f96da0d8f5191001f1b")
  m.assertEqual(history.getChild(0).nowPos, 229)
  m.assertEqual(history.getChild(0).type, "video")
  m.assertEqual(history.getChild(1).id, "01737")
  m.assertEqual(history.getChild(1).currentEpisodeId, "325944")
  m.assertEqual(history.getChild(1).type, "series")
  m.assertEqual(history.getChild(1).getChildCount(), 4)
  m.assertEqual(history.getChild(1).getChild(0).id, "325942")
  m.assertEqual(history.getChild(1).getChild(0).historyId, "58236b43da0d8f51916fd020")
  m.assertEqual(history.getChild(1).getChild(0).nowPos, 2720)
  m.assertEqual(history.getChild(1).getChild(0).type, "video")
End Function