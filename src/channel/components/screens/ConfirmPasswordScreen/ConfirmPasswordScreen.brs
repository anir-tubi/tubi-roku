Function init()
  m.constants = m.global.constants
  
  m.password = m.top.findNode("password")
  m.password.hint = getTranslation("signIn_password_hint")

  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.keyboard = m.top.findNode("passwordEntryKeyboard")
  m.keyboard.observeFieldScoped("buttonSelected", "onButtonSelected")

  'set initial tracking values
  m.top.trackingPageInfo = {
    pageType: "auth_page"
    pageValues: {
      auth_action: "PASSWORD_CONFIRMATION"
    }
  }

  m.top.screenLevel = m.constants.ui.screenLevels.confirmPasswordScreen
End Function


''''''''''''''''''''''
' onScreenFocusChange
' Set focus and apply form element colors
Function onScreenFocusChange()
  tubiLog("ConfirmPasswordScreen.onScreenFocusChange")
  if m.top.hasFocus()
    m.Keyboard.setFocus(true)
  end if
End Function


'Observer for button selected option(back, continue and showHidePassword)
Function onButtonSelected(evt)
  buttonSelected = evt.getData()
  if buttonSelected = "showHidePassword"
    if m.password.passwordMode = true
      m.password.passwordMode = false
    else if m.password.passwordMode = false
      m.password.passwordMode = true
    end if
  else if buttonSelected = "continue"
    m.top.submitSelected = true
  else if buttonSelected = "back"
    m.top.backPressed = true
  else if buttonSelected = "up"
    'DO nothing
  end if 
End Function


Function onKeyEvent(key As String, press As Boolean) As Boolean
tubiLog("ConfirmPasswordScreen.onKeyEvent")
  if key = "OK"
    m.password.text = m.keyboard.text
  else if key = "back"
    m.top.backPressed = true
  end if
  return press
 End Function
