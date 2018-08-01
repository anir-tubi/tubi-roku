'The initializing test suite Function name must begin with the string "TestSuite_"
Function TestSuite_VideoPlayer_VideoPlayerHelpers() as Object
  ' Inherit your test suite from BaseTestSuite
  this = BaseTestSuite()
  
  ' Test suite name for log statistics
  this.Name = "TestSuite_VideoPlayer_VideoPlayerHelpers"
  
  ' Add tests to suite's tests collection
  ' Test cases should return the assert value
  this.addTest("TestCase_isActiveVideoState", TestCase_isActiveVideoState)
  this.addTest("TestCase_isButtonPressAllowed", TestCase_isButtonPressAllowed)
  
  return this
End Function


' Creates a group node with a "state" field and other video node fields as necessary
Function TestMock__VideoPlayerHelpers_MockVideoNode()
  mockVideo = createObject("roSGNode", "Group")
  mockVideo.addField("state", "string", false)
  return mockVideo
End Function


Function TestCase_isActiveVideoState()
  video = TestMock__VideoPlayerHelpers_MockVideoNode()  'overwrite actual video node
  video.state = "none"
    videoState = "play"
    test = m.assertTrue(isActiveVideoState(videoState, video))

    videoState = "pause"
    test += m.assertTrue(isActiveVideoState(videoState, video))
    
    videoState = "rew"
    test += m.assertTrue(isActiveVideoState(videoState, video))

    videoState = "ffw"
    test += m.assertTrue(isActiveVideoState(videoState, video))

    videoState = "stop"
    test += m.assertFalse(isActiveVideoState(videoState, video))

    videoState = "refresh"
    test += m.assertFalse(isActiveVideoState(videoState, video))

    videoState = "skip"
    test += m.assertTrue(isActiveVideoState(videoState, video))

  video.state = "buffering"
    videoState = "play"
    test += m.assertFalse(isActiveVideoState(videoState, video))

    videoState = "pause"
    test += m.assertFalse(isActiveVideoState(videoState, video))
    
    videoState = "rew"
    test += m.assertFalse(isActiveVideoState(videoState, video))

    videoState = "ffw"
    test += m.assertFalse(isActiveVideoState(videoState, video))

    videoState = "stop"
    test += m.assertFalse(isActiveVideoState(videoState, video))

    videoState = "refresh"
    test += m.assertFalse(isActiveVideoState(videoState, video))

    videoState = "skip"
    test += m.assertFalse(isActiveVideoState(videoState, video))
  
  video.state = "playing"
    videoState = "play"
    test += m.assertTrue(isActiveVideoState(videoState, video))

    videoState = "pause"
    test += m.assertTrue(isActiveVideoState(videoState, video))
    
    videoState = "rew"
    test += m.assertTrue(isActiveVideoState(videoState, video))

    videoState = "ffw"
    test += m.assertTrue(isActiveVideoState(videoState, video))

    videoState = "stop"
    test += m.assertFalse(isActiveVideoState(videoState, video))

    videoState = "refresh"
    test += m.assertFalse(isActiveVideoState(videoState, video))

    videoState = "skip"
    test += m.assertTrue(isActiveVideoState(videoState, video))
  
  video.state = "paused"
    videoState = "play"
    test += m.assertTrue(isActiveVideoState(videoState, video))

    videoState = "pause"
    test += m.assertTrue(isActiveVideoState(videoState, video))
    
    videoState = "rew"
    test += m.assertTrue(isActiveVideoState(videoState, video))

    videoState = "ffw"
    test += m.assertTrue(isActiveVideoState(videoState, video))

    videoState = "stop"
    test += m.assertFalse(isActiveVideoState(videoState, video))

    videoState = "refresh"
    test += m.assertFalse(isActiveVideoState(videoState, video))

    videoState = "skip"
    test += m.assertTrue(isActiveVideoState(videoState, video))
  
  video.state = "stopped"
    videoState = "play"
    test += m.assertFalse(isActiveVideoState(videoState, video))

    videoState = "pause"
    test += m.assertFalse(isActiveVideoState(videoState, video))
    
    videoState = "rew"
    test += m.assertFalse(isActiveVideoState(videoState, video))

    videoState = "ffw"
    test += m.assertFalse(isActiveVideoState(videoState, video))

    videoState = "stop"
    test += m.assertFalse(isActiveVideoState(videoState, video))

    videoState = "refresh"
    test += m.assertFalse(isActiveVideoState(videoState, video))

    videoState = "skip"
    test += m.assertFalse(isActiveVideoState(videoState, video))
  
  video.state = "finished"
    videoState = "play"
    test += m.assertTrue(isActiveVideoState(videoState, video))

    videoState = "pause"
    test += m.assertTrue(isActiveVideoState(videoState, video))
    
    videoState = "rew"
    test += m.assertTrue(isActiveVideoState(videoState, video))

    videoState = "ffw"
    test += m.assertTrue(isActiveVideoState(videoState, video))

    videoState = "stop"
    test += m.assertFalse(isActiveVideoState(videoState, video))

    videoState = "refresh"
    test += m.assertFalse(isActiveVideoState(videoState, video))

    videoState = "skip"
    test += m.assertTrue(isActiveVideoState(videoState, video))
  
  video.state = "error"
    videoState = "play"
    test += m.assertTrue(isActiveVideoState(videoState, video))

    videoState = "pause"
    test += m.assertTrue(isActiveVideoState(videoState, video))
    
    videoState = "rew"
    test += m.assertTrue(isActiveVideoState(videoState, video))

    videoState = "ffw"
    test += m.assertTrue(isActiveVideoState(videoState, video))

    videoState = "stop"
    test += m.assertFalse(isActiveVideoState(videoState, video))

    videoState = "refresh"
    test += m.assertFalse(isActiveVideoState(videoState, video))

    videoState = "skip"
    test += m.assertTrue(isActiveVideoState(videoState, video))

  return test
End Function



Function TestCase_isButtonPressAllowed()
  video = TestMock__VideoPlayerHelpers_MockVideoNode()

  video.state = "playing"
  videoState = "play"
  test = m.assertTrue(isButtonPressAllowed("OK", videoState, video))

  video.state = "stopped"
  videoState = "play"
  test += m.assertFalse(isButtonPressAllowed("OK", videoState, video))
  
  return test
End Function