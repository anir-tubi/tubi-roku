'@TestSuite [LivePlayerLogLib] LivePlayerLogLib.brs

'@Setup
Function LivePlayerLogLibSetup()
  constants = getConstants()
  auth = TubiAuth(constants)
  request = TubiRequest(constants.settings)
  tracking = TubiTracking(constants, auth, {}, request)
  m.playerLogLib = LivePlayerLogLib(constants, tracking)
  m.playerLogLib.sendEvent = sendLiveEvent
End Function


Function sendLiveEvent(data = {} as Dynamic, subType = "" as String, eventBase = {})
  eventInfo = m.tracking.populateMessage(subType, data, eventBase)
  eventValues = eventInfo[subType]
  trackData = m.tracking.getPlayerAnalyticsEvent(subType, eventValues)
  m.trackingLoggingTask = CreateObject("roSGNode", "TrackingLoggingTask")
  m.trackingLoggingTask.trackPlayerEvent = trackData
End Function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in PlayerLogLib.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test setVideoControl unit tests
Function playerLogLib_setLiveVideoControl_test()
  m.playerLogLib.setVideoControl("play")
  isVideoPlayed = m.playerLogLib.isVideoPlayed
  m.assertEqual(isVideoPlayed, false)

  videoControlStatePreviously = m.playerLogLib.isVideoPlayed
  m.playerLogLib.setVideoControl("stop")
  isVideoPlayed = m.playerLogLib.isVideoPlayed
  m.assertEqual(videoControlStatePreviously, isVideoPlayed)

  videoControlStatePreviously = m.playerLogLib.isVideoPlayed
  m.playerLogLib.setVideoControl("")
  isVideoPlayed = m.playerLogLib.isVideoPlayed
  m.assertEqual(videoControlStatePreviously, isVideoPlayed)

  videoControlStatePreviously = m.playerLogLib.isVideoPlayed
  m.playerLogLib.setVideoControl(2)
  isVideoPlayed = m.playerLogLib.isVideoPlayed
  m.assertEqual(videoControlStatePreviously, isVideoPlayed)

  videoControlStatePreviously = m.playerLogLib.isVideoPlayed
  m.playerLogLib.setVideoControl(invalid)
  isVideoPlayed = m.playerLogLib.isVideoPlayed
  m.assertEqual(isVideoPlayed, videoControlStatePreviously)
End Function


'@Test setLiveVideoContent unit tests
Function playerLogLib_setLiveVideoContent_test()
  content = CreateObject("roSGNode", "TubiContentNode")
  content.id = "testId"
  content.codec = "H265"
  content.resolution = "1080p"
  content.drmType = "hlsv3"
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
  m.assertEqual(drmType, "hlsv3")

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


'@Test setLiveVideoPosition unit tests
Function playerLogLib_setLiveVideoPosition_test()
  m.playerLogLib.setVideoPosition(120)
  playerPosition = m.playerLogLib.videoPosition
  m.assertEqual(playerPosition, 120)

  m.playerLogLib.setVideoPosition("")
  playerPosition = m.playerLogLib.videoPosition
  m.assertEqual(playerPosition, -1)

  m.playerLogLib.setVideoPosition(invalid)
  playerPosition = m.playerLogLib.videoPosition
  m.assertEqual(playerPosition, -1)
End Function


'@Test setLiveErrorModal unit tests
Function playerLogLib_setLiveErrorModal_test()
  m.playerLogLib.setErrorModal(true)
  hasErroModalShown = m.playerLogLib.hasErrorModalShown
  m.assertEqual(hasErroModalShown, true)

  m.playerLogLib.setErrorModal(false)
  hasErroModalShown = m.playerLogLib.hasErrorModalShown
  m.assertEqual(hasErroModalShown, false)

  m.playerLogLib.setErrorModal()
  hasErroModalShown = m.playerLogLib.hasErrorModalShown
  m.assertEqual(hasErroModalShown, false)

  m.playerLogLib.setErrorModal(1)
  hasErroModalShown = m.playerLogLib.hasErrorModalShown
  m.assertEqual(hasErroModalShown, false)

  m.playerLogLib.setErrorModal(invalid)
  hasErroModalShown = m.playerLogLib.hasErrorModalShown
  m.assertEqual(hasErroModalShown, false)
End Function


'@Test resetAdMetrics unit tests
Function playerLogLib_resetAttributes_test()
  m.playerLogLib.resetAttributes()
  m.assertEqual(m.playerLogLib.contentFirstFrameDuration, -1)
  m.assertEqual(m.playerLogLib.lastStartStep, "UNKNOWN")
  m.assertEqual(m.playerLogLib.errorCode, 0)
  m.assertEqual(m.playerLogLib.firstErrorCode, 0)
  m.assertEqual(m.playerLogLib.breakOffCount, 0)
  m.assertEqual(m.playerLogLib.videoBufferingCount, 0)
  m.assertEqual(m.playerLogLib.totalBufferingDuration, 0)
  m.assertEqual(m.playerLogLib.totalViewTime, 0)
  m.assertEqual(m.playerLogLib.isAd, false)
  m.assertEqual(m.playerLogLib.adCount, 0)
  m.assertEqual(m.playerLogLib.cdn, "")
  m.assertEqual(m.playerLogLib.isVideoPlayed, false)
  m.assertEqual(m.playerLogLib.hasErrorModalShown, false)
End Function


'@Test setLiveLastStartStep unit tests
Function playerloglib_setLiveLastStartStep_test()
  m.playerLogLib.setLastStartStep("PLAY_STARTED")
  lastStartStep = m.playerLogLib.lastStartStep
  m.assertEqual(lastStartStep, "PLAY_STARTED")

  m.playerLogLib.setLastStartStep("")
  lastStartStep = m.playerLogLib.lastStartStep
  m.assertEqual(lastStartStep, "PLAY_STARTED")

  m.playerLogLib.setLastStartStep()
  lastStartStep = m.playerLogLib.lastStartStep
  m.assertEqual(lastStartStep, "UNKNOWN")
End Function

