Function init()
  m.ButtonGroup = m.top.findNode("SignInOrGuestButtons")
  m.Slogan = m.top.findNode("Slogan")
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.ButtonGroup.observeField("itemSelected", "onButtonSelected")
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
  if m.top.hasFocus() then
    m.ButtonGroup.setFocus(true)
    m.Slogan.runCrossfade = true
  else if not m.top.isInFocusChain()
    m.Slogan.runCrossfade = false
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
