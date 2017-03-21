Function init()
  m.Video = m.top.findNode("TrailerVideo")
  m.Video.observeField("state", "onVideoStateChange")
  m.Pause = m.top.findNode("PauseOverlay")
  m.top.observeField("content", "onContentChange")
End Function


Function onContentChange()
  if m.top.content <> invalid then
    m.Video.control = "play"
  end if
End Function


Function onVideoStateChange()
  if m.Video.state = "playing"
    m.Video.visible = true
    m.top.findNode("TrailerLoadingSpinner").visible = false
  else if m.Video.state = "error" or m.Video.state = "finished" then
    m.top.trailerFinished = true
  end if
End Function


Function onKeyEvent(key As String, press As Boolean)
  if press and key = "play" then
    if m.Video.state = "playing" then
      m.Video.control = "pause"
      m.Pause.visible = true
    else if m.Video.state = "paused" then
      m.Video.control = "resume"
      m.Pause.visible = false
    end if
    return true
  end if
  return false
End Function