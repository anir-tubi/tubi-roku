
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
  content.id = "01079"
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
  BM = TubiBookmarks(REQUEST, AUTH, constants)
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

Function testGetInitialBookmarksReqSignedOut(t As Object)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = mockAuth_Unauthorized(constants, REQUEST)
  BM = TubiBookmarks(REQUEST, AUTH, constants)
  req = BM.getInitialBookmarksReq("1234")
  t.assertInvalid(req)
End Function

Function testGetInitialBookmarksReqSignedIn(t As Object)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = mockAuth_Authorized(constants, REQUEST)
  BM = TubiBookmarks(REQUEST, AUTH, constants)
  req = BM.getInitialBookmarksReq("1234")
  t.assertNotInvalid(req)
End Function

Function testGetInitialHistoryReqSignedOut(t As Object)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = mockAuth_Unauthorized(constants, REQUEST)
  BM = TubiBookmarks(REQUEST, AUTH, constants)
  req = BM.getInitialHistoryReq("1234")
  t.assertInvalid(req)
End Function

Function testGetInitialHistoryReqSignedIn(t As Object)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = mockAuth_Authorized(constants, REQUEST)
  BM = TubiBookmarks(REQUEST, AUTH, constants)
  req = BM.getInitialHistoryReq("1234")
  t.assertNotInvalid(req)
End Function

Function xtestHandleInitialBookmarks(t As Object)
  'TODO(Chris)
End Function

Function xtestHandleInitialHistory(t As Object)
  'TODO(Chris)
End Function

''''''''''''''
' updateNowPos
'
' Permutations:
'   signed in vs. signed out - playerInfo.historyId will be empty or invalid for signed out
'   movie vs. episode () - episode will have playerInfo.parentHistoryId
'   new vs. existing - historyIds{}/historyOrder[] will already contain a matching entry for existing
''''''''''''''

Function testUpdateNowPosSignedInMovieNew(t As Object)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = mockAuth_Authorized(constants, REQUEST)
  BM = TubiBookmarks(REQUEST, AUTH, constants)
  historyIds = CreateObject("roSGNode", "TubiContentNode")
  content = CreateObject("roSGNode", "TubiContentNode")
  content.type = "video"
  content.id = "321221"
  content.title = "We Are Young"
  playerInfo = {
    nowPos: 145
    historyId: "AABBCCDDEEFFGG"
  }
  result = BM.updateNowPos(content, playerInfo, historyIds)
  t.assertEqual(result.getChildCount(), 1)
  t.assertEqual(result.getChild(0).id, "321221")
  t.assertEqual(result.getChild(0).type, constants.ui.contentTypes.video)
  t.assertEqual(result.getChild(0).historyId, "AABBCCDDEEFFGG")
  t.assertEqual(result.getChild(0).nowPos, 145)
End Function

Function testUpdateNowPosSignedInEpisodeNew(t As Object)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = mockAuth_Authorized(constants, REQUEST)
  BM = TubiBookmarks(REQUEST, AUTH, constants)
  historyIds = CreateObject("roSGNode", "TubiContentNode")
  content = CreateObject("roSGNode", "TubiContentNode")
  content.type = "video"
  content.id = "302800"
  content.title = "S02:E05 - You, I'll Be Following"
  content.parentId = "1079"
  playerInfo = {
    nowPos: 145
    historyId: "AABBCCDDEEFFGG"
    parentHistoryId: "TTUUVVWWXXYYZZ"
  }
  result = BM.updateNowPos(content, playerInfo, historyIds)
  t.assertEqual(result.getChildCount(), 1)
  t.assertEqual(result.getChild(0).id, "1079")
  t.assertEqual(result.getChild(0).type, constants.ui.contentTypes.series)
  t.assertEqual(result.getChild(0).historyId, "TTUUVVWWXXYYZZ")
  t.assertEqual(result.getChild(0).currentEpisodeId, "302800")
  t.assertEqual(result.getChild(0).getChildCount(), 1)
  t.assertEqual(result.getChild(0).getChild(0).id, "302800")
  t.assertEqual(result.getChild(0).getChild(0).historyId, "AABBCCDDEEFFGG")
  t.assertEqual(result.getChild(0).getChild(0).nowPos, 145)
End Function

Function testUpdateNowPosSignedOutMovieNew(t As Object)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = mockAuth_Unauthorized(constants, REQUEST)
  BM = TubiBookmarks(REQUEST, AUTH, constants)
  historyIds = CreateObject("roSGNode", "TubiContentNode")
  content = CreateObject("roSGNode", "TubiContentNode")
  content.type = "video"
  content.id = "321221"
  content.title = "We Are Young"
  playerInfo = {
    nowPos: 145
  }
  result = BM.updateNowPos(content, playerInfo, historyIds)
  t.assertEqual(result.getChildCount(), 1)
  t.assertEqual(result.getChild(0).id, "321221")
  t.assertEqual(result.getChild(0).type, constants.ui.contentTypes.video)
  t.assertEqual(result.getChild(0).historyId, "")
  t.assertEqual(result.getChild(0).nowPos, 145)
End Function

Function testUpdateNowPosSignedOutEpisodeNew(t As Object)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = mockAuth_Unauthorized(constants, REQUEST)
  BM = TubiBookmarks(REQUEST, AUTH, constants)
  historyIds = CreateObject("roSGNode", "TubiContentNode")
  content = CreateObject("roSGNode", "TubiContentNode")
  content.type = "video"
  content.id = "302800"
  content.title = "S02:E05 - You, I'll Be Following"
  content.parentId = "1079"
  playerInfo = {
    nowPos: 145
  }
  result = BM.updateNowPos(content, playerInfo, historyIds)
  t.assertEqual(result.getChildCount(), 1)
  t.assertEqual(result.getChild(0).id, "1079")
  t.assertEqual(result.getChild(0).type, constants.ui.contentTypes.series)
  t.assertEqual(result.getChild(0).historyId, "")
  t.assertEqual(result.getChild(0).currentEpisodeId, "302800")
  t.assertEqual(result.getChild(0).getChildCount(), 1)
  t.assertEqual(result.getChild(0).getChild(0).id, "302800")
  t.assertEqual(result.getChild(0).getChild(0).historyId, "")
  t.assertEqual(result.getChild(0).getChild(0).nowPos, 145)
End Function

Function testUpdateNowPosSignedInMovieExisting(t As Object)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = mockAuth_Authorized(constants, REQUEST)
  BM = TubiBookmarks(REQUEST, AUTH, constants)
  historyIds = CreateObject("roSGNode", "TubiContentNode")
  video = historyIds.createChild("TubiContentNode")
  video.id = "321221"
  video.type = "video"
  video.historyId = "AABBCCDDEEFFGG"
  video.nowPos = 10
  content = CreateObject("roSGNode", "TubiContentNode")
  content.type = "video"
  content.id = "321221"
  content.title = "We Are Young"
  playerInfo = {
    nowPos: 145
    historyId: "AABBCCDDEEFFGG"
  }
  result = BM.updateNowPos(content, playerInfo, historyIds)
  t.assertEqual(result.getChildCount(), 1)
  t.assertEqual(result.getChild(0).id, "321221")
  t.assertEqual(result.getChild(0).type, constants.ui.contentTypes.video)
  t.assertEqual(result.getChild(0).historyId, "AABBCCDDEEFFGG")
  t.assertEqual(result.getChild(0).nowPos, 145)
End Function

Function testUpdateNowPosSignedInEpisodeExisting(t As Object)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = mockAuth_Authorized(constants, REQUEST)
  BM = TubiBookmarks(REQUEST, AUTH, constants)
  historyIds = CreateObject("roSGNode", "TubiContentNode")
  series = historyIds.createChild("TubiContentNode")
  series.id = "01079"
  series.type = "series"
  series.historyId = "TTUUVVWWXXYYZZ"
  series.currentEpisodeId = "302800"
  episode = series.createChild("TubiContentNode")
  episode.id = "302800"
  episode.type = "video"
  episode.historyId = "AABBCCDDEEFFGG"
  episode.nowPos = 15
  content = CreateObject("roSGNode", "TubiContentNode")
  content.type = "video"
  content.id = "302800"
  content.title = "S02:E05 - You, I'll Be Following"
  content.parentId = "1079"
  playerInfo = {
    nowPos: 145
    historyId: "AABBCCDDEEFFGG"
    parentHistoryId: "TTUUVVWWXXYYZZ"
  }


  result = BM.updateNowPos(content, playerInfo, historyIds)
  t.assertEqual(result.getChildCount(), 1)
  t.assertEqual(result.getChild(0).id, "01079")
  t.assertEqual(result.getChild(0).type, constants.ui.contentTypes.series)
  t.assertEqual(result.getChild(0).historyId, "TTUUVVWWXXYYZZ")
  t.assertEqual(result.getChild(0).currentEpisodeId, "302800")
  t.assertEqual(result.getChild(0).getChildCount(), 1)
  t.assertEqual(result.getChild(0).getChild(0).id, "302800")
  t.assertEqual(result.getChild(0).getChild(0).type, constants.ui.contentTypes.video)
  t.assertEqual(result.getChild(0).getChild(0).historyId, "AABBCCDDEEFFGG")
  t.assertEqual(result.getChild(0).getChild(0).nowPos, 145)
End Function

Function testUpdateNowPosSignedOutMovieExisting(t As Object)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = mockAuth_Unauthorized(constants, REQUEST)
  BM = TubiBookmarks(REQUEST, AUTH, constants)
  historyIds = CreateObject("roSGNode", "TubiContentNode")
  movie = historyIds.createChild("TubiContentNode")
  movie.id = "321221"
  movie.type = "video"
  movie.nowPos = 10
  content = CreateObject("roSGNode", "TubiContentNode")
  content.type = "video"
  content.id = "321221"
  content.title = "We Are Young"
  playerInfo = {
    nowPos: 145
  }
  result = BM.updateNowPos(content, playerInfo, historyIds)
  t.assertEqual(result.getChildCount(), 1)
  t.assertEqual(result.getChild(0).id, "321221")
  t.assertEqual(result.getChild(0).type, constants.ui.contentTypes.video)
  t.assertEqual(result.getChild(0).historyId, "")
  t.assertEqual(result.getChild(0).nowPos, 145)
End Function

Function testUpdateNowPosSignedOutEpisodeExisting(t As Object)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = mockAuth_Unauthorized(constants, REQUEST)
  BM = TubiBookmarks(REQUEST, AUTH, constants)
  historyIds = CreateObject("roSGNode", "TubiContentNode")
  series = historyIds.createChild("TubiContentNode")
  series.id = "01079"
  series.type = "series"
  series.currentEpisodeId = "302800"
  episode = series.createChild("TubiContentNode")
  episode.id = "302800"
  episode.type = "video"
  episode.nowPos = 15
  content = CreateObject("roSGNode", "TubiContentNode")
  content.type = "video"
  content.id = "302800"
  content.title = "S02:E05 - You, I'll Be Following"
  content.parentId = "1079"
  playerInfo = {
    nowPos: 145
  }
  result = BM.updateNowPos(content, playerInfo, historyIds)
  t.assertEqual(result.getChildCount(), 1)
  t.assertEqual(result.getChild(0).id, "01079")
  t.assertEqual(result.getChild(0).type, constants.ui.contentTypes.series)
  t.assertEqual(result.getChild(0).historyId, "")
  t.assertEqual(result.getChild(0).currentEpisodeId, "302800")
  t.assertEqual(result.getChild(0).getChildCount(), 1)
  t.assertEqual(result.getChild(0).getChild(0).id, "302800")
  t.assertEqual(result.getChild(0).getChild(0).historyId, "")
  t.assertEqual(result.getChild(0).getChild(0).nowPos, 145)
End Function

Function xtestUpdateNowPosInvalidHistoryIds(t As Object)
End Function

Function xtestUpdateNowPosInvalidHistoryOrder(t As Object)
End Function

Function xtestUpdateNowPosInvalidPlayerInfo(t As Object)
End Function
