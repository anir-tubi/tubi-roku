
' Depends on NodeHelper mixin

' Start autohide, optionally setting a timeout.  For immediately hiding the UI and showing video,
' call this with a timeout of zero
' @timeout Timeout in seconds before autohiding the UI, or 0 to hide it immediately
' @focusVideo Set focus to the video player node after autohide
Function autohideStart(timeout=10, focusVideo=true, fadeTime=3.0)
  if m.NodeHelpers = invalid then m.NodeHelpers = TubiNodeHelpers()
  
  timer = m.NodeHelpers.rootNode().findNode("AutohideTimer")
  if timer <> invalid
    if not timer.hasField("focusVideo") then timer.addField("focusVideo", "boolean", false)
    if not timer.hasField("fadeTime") then timer.addField("fadeTime", "float", false)
    timer.focusVideo = focusVideo
    timer.fadeTime = fadeTime
    timer.duration = timeout
    timer.control = "start"
  end if
End Function

Function autohideCancel()
  if m.NodeHelpers = invalid then m.NodeHelpers = TubiNodeHelpers()
  timer = m.NodeHelpers.rootNode().findNode("AutohideTimer")
  if timer <> invalid
    timer.control = "stop"
  end if
End Function