Function init()
  m.constants = getConstantsFromGlobal()

  m.password = m.top.findNode("password")
  m.password.hint = getTranslation("signIn_password_hint")

  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.keyboard = m.top.findNode("passwordEntryKeyboard")
  m.voiceKeyboard = m.keyboard.findNode("Keyboard")
  m.keyboard.observeFieldScoped("text", "onKeyboardTextChanged")
  m.keyboard.observeFieldScoped("buttonSelected", "onButtonSelected")

  'set initial tracking values
  m.top.trackingPageInfo = {
    pageType: "auth_page"
    pageValues: {
      auth_action: "PASSWORD_CONFIRMATION"
    }
  }

  m.top.screenLevel = m.constants.ui.screenLevels.confirmPasswordScreen

  m.backgroundUriList = [m.constants.ui.uris.marketingBackground]
End Function


''''''''''''''''''''''
' onScreenFocusChange
' Set focus and apply form element colors
Function onScreenFocusChange()
  tubiLog("ConfirmPasswordScreen.onScreenFocusChange")
  if m.top.hasFocus()
    ' force a background update
    m.top.backgroundUriList = m.backgroundUriList
    m.Keyboard.setFocus(true)
    m.voiceKeyboard.textEditBox.voiceEnabled = true
    if m.constants.settings.mode <> "production" and m.constants.settings.password <> invalid
      m.keyboard.text = m.constants.settings.password
      m.password.text = m.constants.settings.password
    end if
  end if
  
  if m.top.isInFocusChain() = false
    m.voiceKeyboard.textEditBox.voiceEnabled = false
    m.keyboard.unobserveFieldScoped("text")
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


 Function onKeyboardTextChanged()
  tubiLog("ConfirmPasswordScreen.onKeyboardTextChanged")
  m.password.text = m.keyboard.text
 End Function