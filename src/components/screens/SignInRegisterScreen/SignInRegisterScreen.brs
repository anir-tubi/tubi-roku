Function init()
  m.ButtonGroup = m.top.findNode("SignInOrRegisterButtons")
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.ButtonGroup.setFocus(true)
  m.ButtonGroup.observeField("itemSelected", "onButtonSelected")
End Function


''''''''''''''''''''''
' onScreenFocusChange
'
' Set the right child element focus when screen focus changes
Function onScreenFocusChange()
  tubiLog("SignInDisambiguationScreen.onScreenFocusChange")
  if m.top.hasFocus() then
    m.ButtonGroup.setFocus(true)
  end if
End Function


''''''''''''''''''''''
' onButtonSelected
'
' Handle button selections
Function onButtonSelected()
  tubiLog("SignInDisambiguationScreen.onButtonSelected")
  button = m.ButtonGroup.content.getChild(m.ButtonGroup.itemSelected)
  if button.id = "signin" then
    m.top.signInButtonSelected = true
  else if button.id = "register" then
    m.top.registerButtonSelected = true
  end if
End Function
