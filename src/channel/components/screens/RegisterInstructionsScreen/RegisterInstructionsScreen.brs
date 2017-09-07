Function init()
  m.ButtonGroup = m.top.findNode("RefreshButtons")
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.ButtonGroup.setFocus(true)
  m.ButtonGroup.observeField("itemSelected", "onButtonSelected")
  m.RegistrationCode = m.top.findNode("RegistrationCode")
  m.exitedScreen = false
  getRegistrationCode()
End Function


''''''''''''''''''''''''''
' onScreenFocusChange
'
' Set the focus on the button group
Function onScreenFocusChange()
  tubiLog("RegisterInstructionsScreen.onScreenFocusChange")
  if m.top.hasFocus() then
    m.exitedScreen = false
    m.ButtonGroup.setFocus(true)
  end if
End Function


'''''''''''''''''''''''''
' onButtonSelected
'
' Handle Refresh button selected
Function onButtonSelected()
  tubiLog("RegisterInstructionsScreen.onButtonSelected")
  button = m.ButtonGroup.content.getChild(m.ButtonGroup.itemSelected)
  if button.id = "refresh" then
    getRegistrationCode()
  else if button.id = "sign-in" then
    m.top.signInButtonPressed = true
    m.RegCodeTask.cancel = true
    m.exitedScreen = true
  end if
End Function


'''''''''''''''''''''
' onCodeChange
'
' Display the new registration code
Function onCodeChange()
  m.RegistrationCode.text = m.RegCodeTask.code
End Function


'''''''''''''''''''''''''
' onRegistrationResponse
'
' Registration polling received a response, watch for it to be successful
Function onRegistrationResponse()
  if m.RegCodeTask.response <> invalid and m.RegCodeTask.response.status = "registered" then
    m.top.registerSuccess = true
  end if
End Function


'''''''''''''''''''''''
' onRegTaskStateChange
'
' This may be called if 
'    a) The polling expiration was reached
'    b) An API error was encountered
Function onRegTaskStateChange()
  tubiLog("RegisterInstructionsScreen.onRegTaskStateChange; state = " + m.RegCodeTask.state)
  if m.RegCodeTask.state = "stop" then
    if (m.RegCodeTask.response = invalid or m.RegCodeTask.response.status <> "registered") and not m.exitedScreen then
      'Just retry the reg code
      getRegistrationCode()
    end if
  end if
End Function


'''''''''''''''''''''''
' getRegistrationCode
'
' TODO(Chris): Cancel outstanding threads polling when this screen closes.  This will happen
' when the user presses "back" button and re-enters this screen
Function getRegistrationCode()
  tubiLog("RegisterInstructionsScreen.getRegistrationCode")
  m.RegistrationCode.text = "------"
  if m.RegCodeTask <> invalid then
    m.top.removeChild(m.RegCodeTask)
    m.RegCodeTask.unobserveField("code")
    m.RegCodeTask.unobserveField("response")
    m.RegCodeTask.unobserveField("state")
    m.RegCodeTask.cancel = true  ' tell the thread to exit
  end if
  m.RegCodeTask = m.top.createChild("RegistrationCodeTask")
  m.RegCodeTask.observeField("code", "onCodeChange")
  m.RegCodeTask.observeField("response", "onRegistrationResponse")
  m.RegCodeTask.observeField("state", "onRegTaskStateChange")
  m.RegCodeTask.control = "RUN"
End Function


Function onKeyEvent(key As String, press As Boolean)
  if press
    if key = "back"
      'leaving page so stop polling
      m.RegCodeTask.cancel = true
      m.exitedScreen = true
      return false
    end if
  end if
End Function