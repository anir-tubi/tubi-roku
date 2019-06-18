Function init()
  m.constants = m.global.constants
  m.PasswordTextBox = m.top.findNode("PasswordTextBox")
  m.PasswordTextBoxFocus = m.top.findNode("PasswordTextBoxFocus")
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.SubmitButton = m.top.findNode("SubmitButton")
  m.SubmitButtonFocus = m.top.findNode("SubmitButtonFocus")
  m.SubmitButtonDisabledFocus = m.top.findNode("SubmitButtonDisabledFocus")
  m.Keyboard = m.top.findNode("Keyboard")
  m.Keyboard.observeField("text", "onKeyboardTextChanged")
  m.KeyboardAnimation = m.top.findNode("KeyboardAnimation")
  m.KeyboardInterpolator = m.top.findNode("KeyboardTranslationInterpolator")

  m.colors = m.constants.ui.colors

  if m.global.constants.deviceInfo.scaledUi = true then
    m.PasswordTextBoxFocus.uri = "pkg:/images/selector-hd.9.png"
    m.PasswordTextBoxFocus.translation = [-4,-4]
    m.SubmitButtonFocus.uri = "pkg:/images/menu-focus-hd.9.png"
    m.SubmitButtonDisabledFocus.uri = "pkg:/images/menu-disabled-focus-hd.9.png"
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
  m.PasswordTextBox.text = m.Keyboard.text
  setColors()
End Function

''''''''''''''''''''''
' setColors
'
' Set the appropriate form element colors based on focus and
' state of the text. 
Function setColors()
  m.PasswordTextBox.color = m.colors.unselectedEntryBox
  m.PasswordTextBox.textColor = m.colors.unselectedEntryText
  if m.PasswordTextBox.text = "" then
    m.PasswordTextBox.textOpacity = 0.5
  else
    m.PasswordTextBox.textOpacity = 1.0
  end if

  if m.Keyboard.isInFocusChain() and m.PasswordTextBox <> invalid then
    m.PasswordTextBox.color = m.colors.selectedEntryBox
    m.PasswordTextBox.textColor = m.colors.selectedEntryText
    m.PasswordTextBox.textOpacity = 1.0
  end if

  'Sign in button
  m.SubmitButtonDisabledFocus.visible = false
  m.SubmitButtonFocus.visible = false
  if m.SubmitButton.isInFocusChain()
    if m.PasswordTextBox.text <> "" then
      m.SubmitButtonFocus.visible = true
    else
      m.SubmitButtonDisabledFocus.visible = true
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
      end if
    else if key = "up" 
      if m.SubmitButton.isInFocusChain() then
        m.Keyboard.setFocus(true)
        result = true
      end if
    else if key = "OK" then
      if m.SubmitButton.hasFocus() and m.SubmitButtonFocus.visible = true then
        m.top.submitSelected = true
        result = true
      end if
    end if
  end if
  setColors()
  return result
End Function
