Function init()
  tubiLog("VideoPlayer.init")
  m.Transport = m.top.findNode("Transport")
  m.Video = m.top  ' reference in case we change from extending Video to extending Group
  m.Video.observeField("state", "onVideoStateChange")
  m.top.observeField("content", "onContentChange")
End Function

Function onContentChange()
  tubiLog("VideoPlayer.onContentChange")
  if m.Video.content <> invalid and m.Video.state <> "playing" then
    m.Video.control = "play"
  end if
End Function

Function onKeyEvent(key As String, press As Boolean)
  tubiLog("VideoPlayer.onKeyEvent key = " + key)
  if press 
    if key = "play" then
      if m.Video.state = "playing" then
        m.Video.control = "pause"
      else if m.Video.state = "paused" then
        m.Video.control = "resume"
      end if
    else if key = "back" then 
      m.top.backButtonPressed = true
    end if
  end if
  ' Consume all key presses
  return true
End Function