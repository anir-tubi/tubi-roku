'@TestSuite [PlayerLogLib] PlayerLogLib.brs

'@Setup
Function PlayerLogLibSetup()
  constants = getConstants()
  m.playerLogLib = PlayerLogLib(constants)
End function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in PlayerLogLib.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test setAdType unit tests
Function playerLogLib_setAdType_test()
  m.playerLogLib.setAdType("midroll")
  adtype = m.playerLogLib.adtype
  m.assertEqual(adtype, "midroll")

  m.playerLogLib.setAdType("prerooll")
  adtype = m.playerLogLib.adtype
  m.assertEqual(adtype, "preroll")

  m.playerLogLib.setAdType(2)
  adtype = m.playerLogLib.adtype
  m.assertEqual(adtype, "preroll")

  m.playerLogLib.setAdType(invalid)
  adtype = m.playerLogLib.adtype
  m.assertEqual(adtype, "preroll")
End Function


'@Test setVideoState unit tests
Function playerLogLib_setVideoState_test()
  m.playerLogLib.setAdState("adsCompleted")
  adState = m.playerLogLib.adState
  m.assertEqual(adState, "adsCompleted")

  m.playerLogLib.setVideoState("playing")
  videoState = m.playerLogLib.videoState
  m.assertEqual(videoState, "playing")
  adState = m.playerLogLib.adState
  m.assertEqual(adState, "")
  isVideoPlayed = m.playerLogLib.isVideoPlayed
  m.assertEqual(isVideoPlayed, true)

  m.playerLogLib.setAdState("init")
  adState = m.playerLogLib.adState
  m.assertEqual(adState, "init")

  m.playerLogLib.setVideoState("playing")
  videoState = m.playerLogLib.videoState
  m.assertEqual(videoState, "playing")
  adState = m.playerLogLib.adState
  m.assertEqual(adState, "init")
  isVideoPlayed = m.playerLogLib.isVideoPlayed
  m.assertEqual(isVideoPlayed, true)

  m.playerLogLib.setVideoState("finished")
  isVideoPlayed = m.playerLogLib.isVideoPlayed
  m.assertEqual(isVideoPlayed, false)
  videoState = m.playerLogLib.videoState
  m.assertEqual(videoState, "finished")

  m.playerLogLib.setVideoState("stopped")
  isVideoPlayed = m.playerLogLib.isVideoPlayed
  m.assertEqual(isVideoPlayed, false)
  videoState = m.playerLogLib.videoState
  m.assertEqual(videoState, "stopped")

  m.playerLogLib.setVideoState("")
  isVideoPlayed = m.playerLogLib.isVideoPlayed
  m.assertEqual(isVideoPlayed, false)
  videoState = m.playerLogLib.videoState
  m.assertEqual(videoState, "")

  m.playerLogLib.setVideoState(2)
  isVideoPlayed = m.playerLogLib.isVideoPlayed
  m.assertEqual(isVideoPlayed, false)
  videoState = m.playerLogLib.videoState
  m.assertEqual(videoState, "")

  m.playerLogLib.setVideoState(invalid)
  isVideoPlayed = m.playerLogLib.isVideoPlayed
  m.assertEqual(isVideoPlayed, false)
  videoState = m.playerLogLib.videoState
  m.assertEqual(videoState, "")
End Function


'@Test setAdState unit tests
Function playerLogLib_setAdState_test()
  m.playerLogLib.setAdState("init")
  adState = m.playerLogLib.adState
  m.assertEqual(adState, "init")

  m.playerLogLib.setAdState("")
  adState = m.playerLogLib.adState
  m.assertEqual(adState, "")

  m.playerLogLib.setAdState(2)
  adState = m.playerLogLib.adState
  m.assertEqual(adState, "")

  m.playerLogLib.setAdState(invalid)
  adState = m.playerLogLib.adState
  m.assertEqual(adState, "")
End Function


'@Test resetAdState unit tests
Function playerLogLib_resetAdState_test()
  m.playerLogLib.resetAdState()
  adState = m.playerLogLib.adState
  m.assertEqual(adState, "")
End Function


'@Test setFirstFrameForContentStart unit tests
Function playerLogLib_setFirstFrameForContentStart_test()
  m.playerLogLib.setFirstFrameForContentStart()
  firstFrameTimerForContentStart = m.playerLogLib.firstFrameTimerForContentStart
  m.assertNotInvalid(firstFrameTimerForContentStart)
End Function


'@Test setVideoControl unit tests
Function playerLogLib_setVideoControl_test()
  trackId = m.global.playerLogTrackId

  m.playerLogLib.setVideoControl("play")
  isVideoPlayed = m.playerLogLib.isVideoPlayed
  m.assertEqual(isVideoPlayed, false)

  isVideoPlayedPreviously = m.playerLogLib.isVideoPlayed
  m.playerLogLib.setVideoControl("stop")
  isVideoPlayed = m.playerLogLib.isVideoPlayed
  m.assertEqual(isVideoPlayedPreviously, isVideoPlayed)
  m.assertNotEqual(trackId, m.global.playerLogTrackId)

  isVideoPlayedPreviously = m.playerLogLib.isVideoPlayed
  trackId = m.global.playerLogTrackId

  m.playerLogLib.setVideoControl("")
  m.assertEqual(isVideoPlayed, isVideoPlayedPreviously)
  m.assertEqual(trackId, m.global.playerLogTrackId)

  isVideoPlayedPreviously = m.playerLogLib.isVideoPlayed
  trackId = m.global.playerLogTrackId

  m.playerLogLib.setVideoControl(2)
  m.assertEqual(isVideoPlayed, isVideoPlayedPreviously)
  m.assertEqual(trackId, m.global.playerLogTrackId)

  isVideoPlayedPreviously = m.playerLogLib.isVideoPlayed
  trackId = m.global.playerLogTrackId

  m.playerLogLib.setVideoControl(invalid)
  m.assertEqual(isVideoPlayed, isVideoPlayedPreviously)
  m.assertEqual(trackId, m.global.playerLogTrackId)
End Function


'@Test setVideoContent unit tests
Function playerLogLib_setVideoContent_test()
  content = CreateObject("roSGNode", "TubiContentNode")
  content.id = "testId"
  content.codec = "H265"
  content.resolution = "1080p"
  content.drmType = "widewine"
  m.playerLogLib.setVideoContent(content)

  content = m.playerLogLib.content
  m.assertNotInvalid(content)

  id = content.id
  m.assertEqual(id, "testId")

  codec = content.codec
  m.assertEqual(codec, "H265")

  resolution = content.resolution
  m.assertEqual(resolution, "1080p")

  drmType = content.drmType
  m.assertEqual(drmType, "widewine")

  m.playerLogLib.setVideoContent("")
  content = m.playerLogLib.content
  m.assertInvalid(content)

  m.playerLogLib.setVideoContent(2)
  content = m.playerLogLib.content
  m.assertInvalid(content)

  m.playerLogLib.setVideoContent(invalid)
  content = m.playerLogLib.content
  m.assertInvalid(content)
End Function


'@Test setVideoPosition unit tests
Function playerLogLib_setVideoPosition_test()
  m.playerLogLib.setVideoPosition(120)
  playerPosition = m.playerLogLib.playerPosition
  m.assertEqual(playerPosition, 120)

  m.playerLogLib.setVideoPosition("")
  playerPosition = m.playerLogLib.playerPosition
  m.assertEqual(playerPosition, -1)

  m.playerLogLib.setVideoPosition(invalid)
  playerPosition = m.playerLogLib.playerPosition
  m.assertEqual(playerPosition, -1)
End Function


'@Test setPlayerLoadTime unit tests
Function playerLogLib_setPlayerLoadTime_test()
  m.playerLogLib.setPlayerLoadTime(1000)
  playerLoadTime = m.playerLogLib.playerLoadTime
  m.assertEqual(playerLoadTime, 1000)

  m.playerLogLib.setPlayerLoadTime("")
  playerLoadTime = m.playerLogLib.playerLoadTime
  m.assertEqual(playerLoadTime, -1)

  m.playerLogLib.setPlayerLoadTime(invalid)
  playerLoadTime = m.playerLogLib.playerLoadTime
  m.assertEqual(playerLoadTime, -1)
End Function


'@Test firePlayerSetupPerformanceEvent unit tests
Function playerLogLib_firePlayerSetupPerformanceEvent_test()
  m.playerLogLib.firePlayerSetupPerformanceEvent()
  playerLoadTime = m.playerLogLib.playerLoadTime
  playerSetupTime = m.playerLogLib.playerSetupTime
  m.assertEqual(playerLoadTime, -1)
  m.assertEqual(playerSetupTime, -1)
End Function


'@Test setPlayerSetupStartTime unit tests
Function playerLogLib_setPlayerSetupStartTime_test()
  m.playerLogLib.setPlayerSetupStartTime()
  playerSetupTimer = m.playerLogLib.playerSetupTimer
  m.assertNotInvalid(playerSetupTimer)
End Function


'@Test setPlayerSetupEndTime unit tests
Function playerLogLib_setPlayerSetupEndTime_test()
  m.playerLogLib.setPlayerSetupEndTime()
  playerSetupTime = m.playerLogLib.playerSetupTime
  m.assertNotInvalid(playerSetupTime)
End Function


'@Test setAdBufferStartTime unit tests
Function playerLogLib_setAdBufferStartTime_test()
  m.playerLogLib.setAdBufferStartTime()
  adBufferTimer = m.playerLogLib.adBufferTimer
  m.assertNotInvalid(adBufferTimer)
End Function


'@Test setAdBufferEndTime unit tests
Function playerLogLib_setAdBufferEndTime_test()
  m.playerLogLib.setAdBufferEndTime()
  adBufferTime = m.playerLogLib.adBufferTime
  m.assertNotInvalid(adBufferTime)
End Function


'@Test setAdCtx unit tests
Function playerLogLib_setAdCtx_test()
  adAA = {
    adid: "5nJDDooAIM7Deyv7b5Dc"
  }

  adCtx = {
    ad: adAA
    adcount: 3
    adindex: 1
    adserver: "tmp:/local_raf_vast.xml"
    duration: 15.018
    rendersequence: "preroll"
    rendertime: 0
    type: "Impression"
  }

  m.playerLogLib.setAdCtx(adCtx)
  adCtx = m.playerLogLib.adCtx
  m.assertNotInvalid(adCtx)
  adindex = adCtx.adindex
  m.assertEqual(adindex, 1)

  m.playerLogLib.setAdCtx("")
  adCtx = m.playerLogLib.adCtx
  m.assertNotInvalid(adCtx)
  adindex = adCtx.adindex
  m.assertInvalid(adindex)

  m.playerLogLib.setAdCtx(2)
  adCtx = m.playerLogLib.adCtx
  m.assertNotInvalid(adCtx)
  adindex = adCtx.adindex
  m.assertInvalid(adindex)

  m.playerLogLib.setAdCtx(invalid)
  adCtx = m.playerLogLib.adCtx
  m.assertNotInvalid(adCtx)
  adindex = adCtx.adindex
  m.assertInvalid(adindex)
End Function
