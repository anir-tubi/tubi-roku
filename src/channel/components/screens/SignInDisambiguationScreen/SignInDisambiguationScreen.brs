Function init()
  m.ButtonGroup = m.top.findNode("SignInOrGuestButtons")
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.ButtonGroup.observeField("itemSelected", "onButtonSelected")

  content = CreateObject("roSGNode", "ContentNode")
  content.url = m.global.constants.urls.splashVideoUrl
  content.streamformat="hls"

  m.Video = m.top.findNode("VideoBackground") 
  m.Video.content = content
  m.Video.control = "play"
  m.Video.observeField("state", "onVideoStateChange")

  m.Slogan = m.top.findNode("Slogan")
  m.Slogan.texts =  [
    "The largest collection of free movies and TV shows (with ads)."
    "Classic hits from US film studios and TV broadcasters, always free!"
    "Register to watch on all devices" 
  ]
End Function


'''''''''''''''''''''
' onVideoStateChange
'
' Report video state changes while it's playing
Function onVideoStateChange()
  tubiLog("Video state = " + m.Video.state)
End Function


''''''''''''''''''''''
' onScreenFocusChange
'
' If screen is out of focus, no need to play the video
'
' NOTE: Explicitly setting the video node visibility here gets around
'       a bug in 7.5.0 beta (build 4053-17) which leaves the video visible on top of all other screens
Function onScreenFocusChange()
  tubiLog("SignInDisambiguationScreen.onScreenFocusChange")
  if m.top.isInFocusChain() then
    m.Video.visible = true
    if m.Video.state = "paused" then
      m.Video.control = "resume"
    else if m.Video.state <> "playing" then
      m.Video.control = "play"
    end if  
    if m.top.hasFocus() then
      m.ButtonGroup.setFocus(true)
    end if
  else
    m.Video.control = "pause"
    m.Video.visible = false
  end if
End Function


''''''''''''''''''''''
' onButtonSelected
'
' Handle buttons selected
Function onButtonSelected()
  tubiLog("SignInDisambiguationScreen.onButtonSelected")
  button = m.ButtonGroup.content.getChild(m.ButtonGroup.itemSelected)
  if button.id = "signin" then
    m.top.signInButtonSelected = true
  else if button.id = "guestpass" then
    m.top.guestPassButtonSelected = true
  end if
End Function


