'@SGNode Test_VideoPlayer
'@TestSuite [VideoPlayerHelpers] VideoPlayerHelpers in VideoPlayer.brs

'@Setup
Function VideoPlayerSetup()
  m.mockVideo = createObject("roSGNode", "Group")
  m.mockVideo.addField("state", "string", false)
End Function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests video video player helpers in VideoPlayer.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test isActiveVideoState unit test
Function isActiveVideoState_test()
  video = m.mockVideo  'overwrite actual video node
  video.state = "none"
    videoState = "play"
    m.AssertTrue(isActiveVideoState(videoState, video))

    videoState = "pause"
    m.AssertTrue(isActiveVideoState(videoState, video))

    videoState = "rew"
    m.AssertTrue(isActiveVideoState(videoState, video))

    videoState = "ffw"
    m.AssertTrue(isActiveVideoState(videoState, video))

    videoState = "stop"
    m.AssertFalse(isActiveVideoState(videoState, video))

    videoState = "refresh"
    m.AssertFalse(isActiveVideoState(videoState, video))

    videoState = "skip"
    m.AssertTrue(isActiveVideoState(videoState, video))

  video.state = "buffering"
    videoState = "play"
    m.AssertFalse(isActiveVideoState(videoState, video))

    videoState = "pause"
    m.AssertFalse(isActiveVideoState(videoState, video))

    videoState = "rew"
    m.AssertFalse(isActiveVideoState(videoState, video))

    videoState = "ffw"
    m.AssertFalse(isActiveVideoState(videoState, video))

    videoState = "stop"
    m.AssertFalse(isActiveVideoState(videoState, video))

    videoState = "refresh"
    m.AssertFalse(isActiveVideoState(videoState, video))

    videoState = "skip"
    m.AssertFalse(isActiveVideoState(videoState, video))

  video.state = "playing"
    videoState = "play"
    m.AssertTrue(isActiveVideoState(videoState, video))

    videoState = "pause"
    m.AssertTrue(isActiveVideoState(videoState, video))

    videoState = "rew"
    m.AssertTrue(isActiveVideoState(videoState, video))

    videoState = "ffw"
    m.AssertTrue(isActiveVideoState(videoState, video))

    videoState = "stop"
    m.AssertFalse(isActiveVideoState(videoState, video))

    videoState = "refresh"
    m.AssertFalse(isActiveVideoState(videoState, video))

    videoState = "skip"
    m.AssertTrue(isActiveVideoState(videoState, video))

  video.state = "paused"
    videoState = "play"
    m.AssertTrue(isActiveVideoState(videoState, video))

    videoState = "pause"
    m.AssertTrue(isActiveVideoState(videoState, video))

    videoState = "rew"
    m.AssertTrue(isActiveVideoState(videoState, video))

    videoState = "ffw"
    m.AssertTrue(isActiveVideoState(videoState, video))

    videoState = "stop"
    m.AssertFalse(isActiveVideoState(videoState, video))

    videoState = "refresh"
    m.AssertFalse(isActiveVideoState(videoState, video))

    videoState = "skip"
    m.AssertTrue(isActiveVideoState(videoState, video))

  video.state = "stopped"
    videoState = "play"
    m.AssertFalse(isActiveVideoState(videoState, video))

    videoState = "pause"
    m.AssertFalse(isActiveVideoState(videoState, video))

    videoState = "rew"
    m.AssertFalse(isActiveVideoState(videoState, video))

    videoState = "ffw"
    m.AssertFalse(isActiveVideoState(videoState, video))

    videoState = "stop"
    m.AssertFalse(isActiveVideoState(videoState, video))

    videoState = "refresh"
    m.AssertFalse(isActiveVideoState(videoState, video))

    videoState = "skip"
    m.AssertFalse(isActiveVideoState(videoState, video))

  video.state = "finished"
    videoState = "play"
    m.AssertTrue(isActiveVideoState(videoState, video))

    videoState = "pause"
    m.AssertTrue(isActiveVideoState(videoState, video))

    videoState = "rew"
    m.AssertTrue(isActiveVideoState(videoState, video))

    videoState = "ffw"
    m.AssertTrue(isActiveVideoState(videoState, video))

    videoState = "stop"
    m.AssertFalse(isActiveVideoState(videoState, video))

    videoState = "refresh"
    m.AssertFalse(isActiveVideoState(videoState, video))

    videoState = "skip"
    m.AssertTrue(isActiveVideoState(videoState, video))

  video.state = "error"
    videoState = "play"
    m.AssertTrue(isActiveVideoState(videoState, video))

    videoState = "pause"
    m.AssertTrue(isActiveVideoState(videoState, video))

    videoState = "rew"
    m.AssertTrue(isActiveVideoState(videoState, video))

    videoState = "ffw"
    m.AssertTrue(isActiveVideoState(videoState, video))

    videoState = "stop"
    m.AssertFalse(isActiveVideoState(videoState, video))

    videoState = "refresh"
    m.AssertFalse(isActiveVideoState(videoState, video))

    videoState = "skip"
    m.AssertTrue(isActiveVideoState(videoState, video))
End Function



'@Test isButtonPressAllowed unit test
Function isButtonPressAllowed_test()
  video = m.mockVideo

  video.state = "playing"
  videoState = "play"
  GetGlobalAA().Menu.visible = false
  m.AssertTrue(isButtonPressAllowed("OK", videoState, video))

  video.state = "stopped"
  videoState = "play"
  m.AssertFalse(isButtonPressAllowed("OK", videoState, video))
End Function
