
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
  historyIds = {
    series: {}
    videos: {}
  }
  historyOrder = []
  content = CreateObject("roSGNode", "TubiContentNode")
  content.type = "video"
  content.id = "321221"
  content.title = "We Are Young"
  playerInfo = {
    nowPos: 145
    historyId: "AABBCCDDEEFFGG"
  }
  result = BM.updateNowPos(content, playerInfo, historyIds, historyOrder)
  
  t.assertEqual(result.historyOrder.count(), 1)
  t.assertEqual(result.historyOrder[0], "321221")
  t.assertEqual(result.historyIds.series.count(), 0)
  t.assertEqual(result.historyIds.videos.count(), 1)
  t.assertEqual(result.historyIds.videos["321221"].serverId, "AABBCCDDEEFFGG")
  t.assertEqual(result.historyIds.videos["321221"].position, 145)
End Function

Function testUpdateNowPosSignedInEpisodeNew(t As Object)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = mockAuth_Authorized(constants, REQUEST)
  BM = TubiBookmarks(REQUEST, AUTH, constants)
  historyIds = {
    series: {}
    videos: {}
  }
  historyOrder = []
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
  result = BM.updateNowPos(content, playerInfo, historyIds, historyOrder)
  
  t.assertEqual(result.historyOrder.count(), 1)
  t.assertEqual(result.historyOrder[0], "01079")
  t.assertEqual(result.historyIds.series.count(), 1)
  t.assertEqual(result.historyIds.series["1079"].serverId, "TTUUVVWWXXYYZZ")
  t.assertEqual(result.historyIds.series["1079"].currentEpisodeId, "302800")
  t.assertEqual(result.historyIds.videos.count(), 1)
  t.assertEqual(result.historyIds.videos["302800"].serverId, "AABBCCDDEEFFGG")
  t.assertEqual(result.historyIds.videos["302800"].position, 145)
End Function

Function testUpdateNowPosSignedOutMovieNew(t As Object)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = mockAuth_Unauthorized(constants, REQUEST)
  BM = TubiBookmarks(REQUEST, AUTH, constants)
  historyIds = {
    series: {}
    videos: {}
  }
  historyOrder = []
  content = CreateObject("roSGNode", "TubiContentNode")
  content.type = "video"
  content.id = "321221"
  content.title = "We Are Young"
  playerInfo = {
    nowPos: 145
  }
  result = BM.updateNowPos(content, playerInfo, historyIds, historyOrder)
  
  t.assertEqual(result.historyOrder.count(), 1)
  t.assertEqual(result.historyOrder[0], "321221")
  t.assertEqual(result.historyIds.series.count(), 0)
  t.assertEqual(result.historyIds.videos.count(), 1)
  t.assertInvalid(result.historyIds.videos["321221"].serverId)
  t.assertEqual(result.historyIds.videos["321221"].position, 145)
End Function

Function testUpdateNowPosSignedOutEpisodeNew(t As Object)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = mockAuth_Unauthorized(constants, REQUEST)
  BM = TubiBookmarks(REQUEST, AUTH, constants)
  historyIds = {
    series: {}
    videos: {}
  }
  historyOrder = []
  content = CreateObject("roSGNode", "TubiContentNode")
  content.type = "video"
  content.id = "302800"
  content.title = "S02:E05 - You, I'll Be Following"
  content.parentId = "1079"
  playerInfo = {
    nowPos: 145
  }
  result = BM.updateNowPos(content, playerInfo, historyIds, historyOrder)
  
  t.assertEqual(result.historyOrder.count(), 1)
  t.assertEqual(result.historyOrder[0], "01079")
  t.assertEqual(result.historyIds.series.count(), 1)
  t.assertInvalid(result.historyIds.series["1079"].serverId)
  t.assertEqual(result.historyIds.series["1079"].currentEpisodeId, "302800")
  t.assertEqual(result.historyIds.videos.count(), 1)
  t.assertInvalid(result.historyIds.videos["302800"].serverId)
  t.assertEqual(result.historyIds.videos["302800"].position, 145)
End Function

Function testUpdateNowPosSignedInMovieExisting(t As Object)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = mockAuth_Authorized(constants, REQUEST)
  BM = TubiBookmarks(REQUEST, AUTH, constants)
  historyIds = {
    series: {}
    videos: {
      "321221": {
        nowPos: 10
        serverId: "AABBCCDDEEFFGG"
      }
    }
  }
  historyOrder = ["321221"]
  content = CreateObject("roSGNode", "TubiContentNode")
  content.type = "video"
  content.id = "321221"
  content.title = "We Are Young"
  playerInfo = {
    nowPos: 145
    historyId: "AABBCCDDEEFFGG"
  }
  result = BM.updateNowPos(content, playerInfo, historyIds, historyOrder)
  
  t.assertEqual(result.historyOrder.count(), 1)
  t.assertEqual(result.historyOrder[0], "321221")
  t.assertEqual(result.historyIds.series.count(), 0)
  t.assertEqual(result.historyIds.videos.count(), 1)
  t.assertEqual(result.historyIds.videos["321221"].serverId, "AABBCCDDEEFFGG")
  t.assertEqual(result.historyIds.videos["321221"].position, 145)
End Function

Function testUpdateNowPosSignedInEpisodeExisting(t As Object)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = mockAuth_Authorized(constants, REQUEST)
  BM = TubiBookmarks(REQUEST, AUTH, constants)
  historyIds = {
    series: {
      "1079": {
        serverId: "TTUUVVWWXXYYZZ"
        currentEpisodeId: "302800"
      }
    }
    videos: {
      "302800": {
        serverId: "AABBCCDDEEFFGG"
        nowPos: 15
      }
    }
  }
  historyOrder = ["01079"]
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
  result = BM.updateNowPos(content, playerInfo, historyIds, historyOrder)
  
  t.assertEqual(result.historyOrder.count(), 1)
  t.assertEqual(result.historyOrder[0], "01079")
  t.assertEqual(result.historyIds.series.count(), 1)
  t.assertEqual(result.historyIds.series["1079"].serverId, "TTUUVVWWXXYYZZ")
  t.assertEqual(result.historyIds.series["1079"].currentEpisodeId, "302800")
  t.assertEqual(result.historyIds.videos.count(), 1)
  t.assertEqual(result.historyIds.videos["302800"].serverId, "AABBCCDDEEFFGG")
  t.assertEqual(result.historyIds.videos["302800"].position, 145)
End Function

Function testUpdateNowPosSignedOutMovieExisting(t As Object)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = mockAuth_Unauthorized(constants, REQUEST)
  BM = TubiBookmarks(REQUEST, AUTH, constants)
  historyIds = {
    series: {}
    videos: {
      "321221": {
        nowPos: 10
        serverId: invalid
      }
    }
  }
  historyOrder = ["321221"]
  content = CreateObject("roSGNode", "TubiContentNode")
  content.type = "video"
  content.id = "321221"
  content.title = "We Are Young"
  playerInfo = {
    nowPos: 145
  }
  result = BM.updateNowPos(content, playerInfo, historyIds, historyOrder)
  
  t.assertEqual(result.historyOrder.count(), 1)
  t.assertEqual(result.historyOrder[0], "321221")
  t.assertEqual(result.historyIds.series.count(), 0)
  t.assertEqual(result.historyIds.videos.count(), 1)
  t.assertInvalid(result.historyIds.videos["321221"].serverId)
  t.assertEqual(result.historyIds.videos["321221"].position, 145)
End Function

Function testUpdateNowPosSignedOutEpisodeExisting(t As Object)
  constants = getConstants()
  REQUEST = TubiRequest()
  AUTH = mockAuth_Unauthorized(constants, REQUEST)
  BM = TubiBookmarks(REQUEST, AUTH, constants)
  historyIds = {
    series: {
      "1079": {
        serverId: invalid
        currentEpisodeId: "302800"
      }
    }
    videos: {
      "302800": {
        serverId: invalid
        nowPos: 15
      }
    }
  }
  historyOrder = ["01079"]
  content = CreateObject("roSGNode", "TubiContentNode")
  content.type = "video"
  content.id = "302800"
  content.title = "S02:E05 - You, I'll Be Following"
  content.parentId = "1079"
  playerInfo = {
    nowPos: 145
  }
  result = BM.updateNowPos(content, playerInfo, historyIds, historyOrder)
  
  t.assertEqual(result.historyOrder.count(), 1)
  t.assertEqual(result.historyOrder[0], "01079")
  t.assertEqual(result.historyIds.series.count(), 1)
  t.assertInvalid(result.historyIds.series["1079"].serverId)
  t.assertEqual(result.historyIds.series["1079"].currentEpisodeId, "302800")
  t.assertEqual(result.historyIds.videos.count(), 1)
  t.assertInvalid(result.historyIds.videos["302800"].serverId)
  t.assertEqual(result.historyIds.videos["302800"].position, 145)
End Function

Function xtestUpdateNowPosInvalidHistoryIds(t As Object)
End Function

Function xtestUpdateNowPosInvalidHistoryOrder(t As Object)
End Function

Function xtestUpdateNowPosInvalidPlayerInfo(t As Object)
End Function
