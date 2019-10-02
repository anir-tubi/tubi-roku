Function init()
  m.constants = m.global.constants
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.SubmitButton = m.top.findNode("SubmitButton")
  m.SubmitButtonFocus = m.top.findNode("SubmitButtonFocus")
  m.SubmitButtonDisabledFocus = m.top.findNode("SubmitButtonDisabledFocus")
  m.PasswordButton = m.top.findNode("PasswordButtonFocus")
  m.PasswordButtonFocus = m.top.findNode("PasswordButtonFocus")
  m.PasswordButtonDisabledFocus = m.top.findNode("PasswordButtonDisabledFocus")
  m.PasswordButtonLabel = m.top.findNode("PasswordButtonLabel")
  m.Keyboard = m.top.findNode("Keyboard")
  m.Keyboard.textEditBox.secureMode = true
  setPasswordButtonLabel()
  m.Keyboard.observeField("text", "onKeyboardTextChanged")
  m.KeyboardAnimation = m.top.findNode("KeyboardAnimation")
  m.KeyboardInterpolator = m.top.findNode("KeyboardTranslationInterpolator")

  m.theme = m.global.theme
  m.SubmitButtonFocus.blendColor = m.theme.focused
  m.PasswordButtonFocus.blendColor = m.theme.focused
  m.Keyboard.focusedKeyColor = m.constants.ui.colors.keyboardFocusedText
  m.Keyboard.focusBitmapUri = m.theme.keyboard_focused_key

  if m.global.constants.deviceInfo.scaledUi = true then
    m.SubmitButtonFocus.uri = "pkg:/images/menu-focus-hd.9.png"
    m.SubmitButtonDisabledFocus.uri = "pkg:/images/menu-disabled-focus-hd.9.png"
    m.PasswordButtonFocus.uri = "pkg:/images/menu-focus-hd.9.png"
    m.PasswordButtonDisabledFocus.uri = "pkg:/images/menu-disabled-focus-hd.9.png"
  end if

  'set initial tracking values
  m.top.trackingPageInfo = {
    pageType: "auth_page"
    pageValues: {
      auth_action: "PASSWORD_CONFIRMATION"
    }
  }

  m.top.screenLevel = m.constants.ui.screenLevels.comfirmPasswordScreen
End Function


''''''''''''''''''''''
' togglePasswordVisibility
'
' toggle between being able to see the password and not.
Function togglePasswordVisibility()
  textEditBox = m.Keyboard.textEditBox
  if textEditBox.secureMode = true
    textEditBox.secureMode = false
  else
    textEditBox.secureMode = true
  end if
  setPasswordButtonLabel()
End Function


''''''''''''''''''''''
' setPasswordButtonLabel
'
' Set the password display button based on the state of the password obfuscation 
Function setPasswordButtonLabel()
  if m.Keyboard.textEditBox.secureMode = false
    m.PasswordButtonLabel.text = "Hide Password"
  else
    m.PasswordButtonLabel.text = "Show Password"
  end if
End Function

''''''''''''''''''''''
' onScreenFocusChange
'
' Set focus and apply form element colors
Function onScreenFocusChange()
  tubiLog("ConfirmPasswordScreen.onScreenFocusChange")
  if m.top.isInFocusChain() and m.top.hasFocus() then
    m.Keyboard.setFocus(true)
  end if
  setColors()
End Function

'''''''''''''''''''''''
' onKeyboardTextChange
'
' Pass the keyboard component's text on to the focused text box
Function onKeyboardTextChanged()
  tubiLog("ConfirmPasswordScreen.onKeyboardTextChanged")
  setColors()
End Function

''''''''''''''''''''''
' setColors
'
' Set the appropriate form element colors based on focus and
' state of the text. 
Function setColors()

  'Sign in button
  m.SubmitButtonDisabledFocus.visible = false
  m.SubmitButtonFocus.visible = false
  m.PasswordButtonDisabledFocus.visible = false
  m.PasswordButtonFocus.visible = false
  if m.SubmitButton.isInFocusChain()
    if m.Keyboard.text <> "" then 
      m.SubmitButtonFocus.visible = true
    else
      m.SubmitButtonDisabledFocus.visible = true
    end if
  end if
  if m.PasswordButton.isInFocusChain()
    if m.Keyboard.text <> "" then
      m.PasswordButtonFocus.visible = true
    else
      m.PasswordButtonDisabledFocus.visible = true
    end if
  end if
End Function


'''''''''''''''''''''''''
' onKeyEvent
'
Function onKeyEvent(key As String, press As Boolean) As Boolean
  tubiLog("ConfirmPasswordScreen.onKeyEvent")
  result = false
  if press then
    if key = "down" then
      if m.Keyboard.isInFocusChain() then
        m.SubmitButton.setFocus(true)
        result = true
      else if m.SubmitButton.isInFocusChain() then
        m.PasswordButton.setFocus(true)
        result = true
      end if
    else if key = "up" 
      if m.PasswordButton.isInFocusChain() then
        m.SubmitButton.setFocus(true)
        result = true
      else if m.SubmitButton.isInFocusChain() then
        m.Keyboard.setFocus(true)
        result = true
      end if
    else if key = "OK" then
      if m.SubmitButton.hasFocus() and m.SubmitButtonFocus.visible = true then
        m.top.submitSelected = true
        result = true
      else if m.PasswordButton.hasFocus() and m.PasswordButtonFocus.visible = true then
        togglePasswordVisibility()
      end if
    end if
  end if
  setColors()
  return result
End Function
