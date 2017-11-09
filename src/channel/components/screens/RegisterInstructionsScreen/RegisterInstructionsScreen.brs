Function init()
  m.ButtonGroup = m.top.findNode("RefreshButtons")
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.ButtonGroup.setFocus(true)
  m.ButtonGroup.observeField("itemSelected", "onButtonSelected")
  m.RegistrationCode = m.top.findNode("RegistrationCode")
End Function


''''''''''''''''''''''''''
' onScreenFocusChange
'
' Set the focus on the button group
Function onScreenFocusChange()
  tubiLog("RegisterInstructionsScreen.onScreenFocusChange")
  if m.top.hasFocus() then
    m.ButtonGroup.setFocus(true)
    ' do this here so if a user navigates away from this
    ' screen but it is reused later, we always have a fresh
    ' code and full timeout period.
    getRegistrationCode()
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


'''''''''''''''''''''''''
' onRegTaskError
'
' An error was recorded by the registrationCodeTask so let the user know
Function onRegTaskError(evt)
  if evt.getData() = "expire"
    title = "Activation Code Expired"
    message = "We're sorry, but the activation code expired before your device was successfully linked."
  else if evt.getData() = "poll"
    title = "Connection Error During Activation"
    message = "We're sorry, but we could not connect with the server to see if you registered your device."
  else if evt.getData() = "code"
    title = "Connection Error During Registration"
    message = "We're sorry, but there was an error while receiving the code from the server."
  else
    title = "Activation Code Error"
    message = "We're sorry, but an activation code error occurred."
  end if
  m.errorDialog = m.top.createChild("ModalDialogScreen")
  m.errorDialog.title = title
  m.errorDialog.message = message
  m.errorDialog.buttons = ["Try again", "Skip"]
  m.errorDialog.observeField("buttonSelected", "onErrorButtonPress")
  m.errorDialog.setFocus(true)
End Function


'''''''''''''''''''''''''
' onErrorButtonPress
'
' Respond the user selecting a button on the error modal
Function onErrorButtonPress(evt)
  buttonSelected = evt.getData()
  m.ButtonGroup.setFocus(true)
  m.top.removeChild(m.errorDialog)
  m.errorDialog.unobserveField("buttonSelected")
  if buttonSelected = 0
    'try again
    getRegistrationCode()
  else
    'leave the screen and go to homepage
    m.RegCodeTask.cancel = true
    m.top.skipButtonPressed = true
  end if
End Function


'''''''''''''''''''''''
' getRegistrationCode
'
Function getRegistrationCode()
  tubiLog("RegisterInstructionsScreen.getRegistrationCode")
  m.RegistrationCode.text = "------"
  if m.RegCodeTask <> invalid then
    m.RegCodeTask.unobserveField("code")
    m.RegCodeTask.unobserveField("response")
    m.RegCodeTask.unobserveField("error")
    m.RegCodeTask.cancel = true  ' tell the thread to exit
  end if
  m.RegCodeTask = CreateObject("roSGNode", "RegistrationCodeTask")
  m.RegCodeTask.observeField("code", "onCodeChange")
  m.RegCodeTask.observeField("response", "onRegistrationResponse")
  m.RegCodeTask.observeField("error", "onRegTaskError")
  m.RegCodeTask.control = "RUN"
End Function


Function onKeyEvent(key As String, press As Boolean)
  if press
    if key = "back"
      'leaving page so stop polling
      m.RegCodeTask.cancel = true

      m.global.trackingLoggingTask.trackEvent = {
        trackType: "registerFail"
        value: "user-cancel"
      }
      return false
    end if
  end if
End Function