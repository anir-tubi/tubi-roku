Function init()
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("skipSignInOption", "setButtonContent")
  m.top.observeField("simpleRegisterScreen", "onSimpleRegister")
  m.Buttons = m.top.findNode("Buttons")
  m.Buttons.setFocus(true)
  m.Buttons.observeField("itemSelected", "onButtonSelected")
  m.RegistrationCode = m.top.findNode("RegistrationCode")
  m.RegistrationCode1 = m.top.findNode("RegistrationCode1")
  m.RegistrationCode2 = m.top.findNode("RegistrationCode2")
  m.RegistrationCode3 = m.top.findNode("RegistrationCode3")
  m.RegistrationCode4 = m.top.findNode("RegistrationCode4")
  m.RegistrationCode5 = m.top.findNode("RegistrationCode5")
  m.RegistrationCode6 = m.top.findNode("RegistrationCode6")
  setButtonContent()
  onSimpleRegister()


  if m.global.constants.deviceInfo.scaledUi = true then
    m.top.findNode("RegistrationPoster1").uri = "pkg:/images/hd/menu-button.9.png"
    m.top.findNode("RegistrationPoster2").uri = "pkg:/images/hd/menu-button.9.png"
    m.top.findNode("RegistrationPoster3").uri = "pkg:/images/hd/menu-button.9.png"
    m.top.findNode("RegistrationPoster4").uri = "pkg:/images/hd/menu-button.9.png"
    m.top.findNode("RegistrationPoster5").uri = "pkg:/images/hd/menu-button.9.png"
    m.top.findNode("RegistrationPoster6").uri = "pkg:/images/hd/menu-button.9.png"
  end if

End Function


Function onSimpleRegister()
  if m.top.simpleRegisterScreen
    m.top.findNode("SimpleRegistrationGroup").visible = true
    m.top.findNode("VerboseRegistrationGroup").visible = false
    m.Buttons.translation = [m.Buttons.translation[0], 746]
  else
    m.top.findNode("SimpleRegistrationGroup").visible = false
    m.top.findNode("VerboseRegistrationGroup").visible = true
    m.Buttons.translation = [m.Buttons.translation[0], 776]
  end if
End Function

''''''''''''''''''''''''
' setButtonContent
'
Function setButtonContent()
  content = CreateObject("roSGNode", "ContentNode")
  refresh = content.createChild("ContentNode")
  refresh.id = "refresh"
  refresh.title = "Refresh Code"
  if not m.top.skipSignInOption then
    signIn = content.createChild("ContentNode")
    signIn.id = "sign-in"
    signIn.title = "Sign in via Email"
    ' Layout set for 2 buttons
    m.Buttons.translation = [437, m.Buttons.translation[1]]
    m.Buttons.itemSpacing = [86, 0]
    m.Buttons.numColumns = 2
  else
    m.Buttons.translation= [720, m.Buttons.translation[1]]
    m.Buttons.itemSpacings = [0,0]
  end if
  m.Buttons.content = content
End Function

''''''''''''''''''''''''''
' onScreenFocusChange
'
' Set the focus on the button group
Function onScreenFocusChange()
  tubiLog("RegisterInstructionsScreen.onScreenFocusChange")
  if m.top.hasFocus() then
    m.Buttons.setFocus(true)
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
  button = m.Buttons.content.getChild(m.Buttons.itemSelected)
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
  m.RegistrationCode1.text = m.RegCodeTask.code.Mid(0,1)
  m.RegistrationCode2.text = m.RegCodeTask.code.Mid(1,1)
  m.RegistrationCode3.text = m.RegCodeTask.code.Mid(2,1)
  m.RegistrationCode4.text = m.RegCodeTask.code.Mid(3,1)
  m.RegistrationCode5.text = m.RegCodeTask.code.Mid(4,1)
  m.RegistrationCode6.text = m.RegCodeTask.code.Mid(5,1)
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
  m.Buttons.setFocus(true)
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
  m.RegistrationCode1.text = "-"
  m.RegistrationCode2.text = "-"
  m.RegistrationCode3.text = "-"
  m.RegistrationCode4.text = "-"
  m.RegistrationCode5.text = "-"
  m.RegistrationCode6.text = "-"
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