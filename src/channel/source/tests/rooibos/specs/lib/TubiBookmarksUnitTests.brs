'@TestSuite [TubiBookmarks] TubiBookmarks.brs

'@Setup
Function TubiBookmarksSetup()

  constants = getConstants()

  m.authorizedBM = TubiBookmarks(constants)

  m.videoContent = CreateObject("roSGNode", "TubiContentNode")
  m.videoContent.type = "video"

  m.movieContent = CreateObject("roSGNode", "TubiContentNode")
  m.movieContent.type = "movie"

  m.seriesContent = CreateObject("roSGNode", "TubiContentNode")
  m.seriesContent.type = "series"

  m.episodeContent = CreateObject("roSGNode", "TubiContentNode")
  m.episodeContent.type = "episode"

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


'@Test updateLikesLocally unit tests
Function tubiBookmarks_updateLikesLocallySuccessful_test()

  tubiBookmarks_setupGlobalFields_testHelper()

  BM = m.authorizedBM
  content = m.seriesContent
  content.id = "0302800"
  BM.updateLikesLocally(content.id, BM.constants.ui.likeDislikeActions.like, m.global)

  likeNode = m.global.likeIds.findNode(content.id)
  '//The content should have been successfully been added, so like node should be valid
  m.assertNotInvalid(likeNode)
  m.assertEqual(likeNode.subType(), "LikeContentNode")
  m.assertEqual(likeNode.id, "0302800")
  m.assertEqual(likeNode.state, BM.constants.ui.likeDislikeStates.liked)
End Function
