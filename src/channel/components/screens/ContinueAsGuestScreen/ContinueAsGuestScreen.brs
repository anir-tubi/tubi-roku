Function init()
  m.ButtonGroup = m.top.findNode("SignInOrGuestButtons")
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.ButtonGroup.setFocus(true)
  m.ButtonGroup.observeField("itemSelected", "onButtonSelected")
End Function

Function onScreenFocusChange()
  tubiLog("SignInDisambiguationScreen.onScreenFocusChange")
  if m.top.hasFocus() then
    m.ButtonGroup.setFocus(true)
  end if
End Function

Function onButtonSelected()
  tubiLog("SignInDisambiguationScreen.onButtonSelected")
  button = m.ButtonGroup.content.getChild(m.ButtonGroup.itemSelected)
  if button.id = "signin" then
    m.top.signInButtonSelected = true
  else if button.id = "guestpass" then
    m.top.guestPassButtonSelected = true
  end if
End Function

