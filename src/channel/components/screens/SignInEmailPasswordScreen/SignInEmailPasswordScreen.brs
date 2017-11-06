Function init()
  m.EmailTextBox = m.top.findNode("EmailTextBox")
  m.EmailTextBoxFocus = m.top.findNode("EmailTextBoxFocus")
  m.PasswordTextBox = m.top.findNode("PasswordTextBox")
  m.PasswordTextBoxFocus = m.top.findNode("PasswordTextBoxFocus")
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.SignInButton = m.top.findNode("SignInButton")
  m.SignInButtonFocus = m.top.findNode("SignInButtonFocus")
  m.SignInButtonDisabledFocus = m.top.findNode("SignInButtonDisabledFocus")
  m.Keyboard = m.top.findNode("Keyboard")
  m.Keyboard.observeField("text", "onKeyboardTextChanged")
  m.KeyboardAnimation = m.top.findNode("KeyboardAnimation")
  m.KeyboardInterpolator = m.top.findNode("KeyboardTranslationInterpolator")

  if m.global.constants.deviceInfo.scaledUi = true then
    m.EmailTextBoxFocus.uri = "pkg:/images/selector-hd.9.png"
    m.PasswordTextBoxFocus.uri = "pkg:/images/selector-hd.9.png"
    m.SignInButtonFocus.uri = "pkg:/images/menu-focus-hd.9.png"
    m.SignInButtonDisabledFocus.uri = "pkg:/images/menu-disabled-focus-hd.9.png"
  end if
End Function

''''''''''''''''''''''
' onScreenFocusChange
'
' Set focus and apply form element colors
Function onScreenFocusChange()
  tubiLog("SignInEmailPasswordScreen.onScreenFocusChange")
  if m.top.hasFocus() then
    if m.Keyboard.visible = true
      m.Keyboard.setFocus(true)
    else
      m.EmailTextBoxFocus.visible = true
      m.PasswordTextBoxFocus.visible = false
      m.FocusedTextBox = m.EmailTextBox
      m.EmailTextBox.setFocus(false)
      startShowKeyboard()
    end if
  end if
  setColors()
End Function


''''''''''''''''''''''
' startShowKeyboard
'
' Start animating the keyboard into view
Function startShowKeyboard()
  tubiLog("SignInEmailPasswordScreen.startShowKeyboard")
  m.Keyboard.text = m.FocusedTextBox.text  ' seed the keyboard with the existing textbox text
  m.Keyboard.visible = true
  m.KeyboardInterpolator.keyValue = [m.Keyboard.translation, [0, 0]]
  m.KeyboardAnimation.observeField("state", "endShowKeyboard")
  m.KeyboardAnimation.control = "start"
End Function


''''''''''''''''''''''
' endShowKeyboard
'
' Set the focus once the animation has ended
Function endShowKeyboard()
  tubiLog("SignInEmailPasswordScreen.endShowKeyboard")
  if m.KeyboardAnimation.state = "stopped" then
    m.KeyboardAnimation.unobserveField("state")
    m.Keyboard.setFocus(true)
  end if
End Function


''''''''''''''''''''''
' startHideKeyboard
'
' Start animating the keyboard off the top of the screen
Function startHideKeyboard()
  tubiLog("SignInEmailPasswordScreen.startHideKeyboard")
  keyboardRect = m.Keyboard.boundingRect()
  m.KeyboardInterpolator.keyValue = [[0,0], [0, -keyboardRect.height]]
  m.KeyboardAnimation.observeField("state", "endHideKeyboard")
  m.KeyboardAnimation.control = "start"
  m.Keyboard.setFocus(false)
End Function


'''''''''''''''''''''''
' endHideKeyboard
'
' Set focus and visibility after keyboard is off screen
Function endHideKeyboard()
  tubiLog("SignInEmailPasswordScreen.endHideKeyboard")
  if m.KeyboardAnimation.state = "stopped" then
    m.KeyboardAnimation.unobserveField("state")
    m.FocusedTextBox = m.EmailTextBox
    m.EmailTextBox.setFocus(true)
    m.EmailTextBoxFocus.visible = true
    m.Keyboard.visible = false
  end if
End Function


'''''''''''''''''''''''
' onKeyboardTextChange
'
' Pass the keyboard component's text on to the focused text box
Function onKeyboardTextChanged()
  tubiLog("SignInEmailPasswordScreen.onKeyboardTextChanged")
  m.FocusedTextBox.text = m.Keyboard.text
  setColors()
End Function


''''''''''''''''''''''
' setColors
'
' Set the appropriate form element colors based on focus and
' state of the text. 
Function setColors()
  m.EmailTextBox.color = m.global.constants.ui.colors.unselectedEntryBox
  m.EmailTextBox.textColor = m.global.constants.ui.colors.unselectedEntryText
  if m.EmailTextBox.text = "" then
    m.EmailTextBox.textOpacity = 0.5
  else
    m.EmailTextBox.textOpacity = 1.0
  end if

  m.PasswordTextBox.color = m.global.constants.ui.colors.unselectedEntryBox
  m.PasswordTextBox.textColor = m.global.constants.ui.colors.unselectedEntryText
  if m.PasswordTextBox.text = "" then
    m.PasswordTextBox.textOpacity = 0.5
  else
    m.PasswordTextBox.textOpacity = 1.0
  end if

  if m.Keyboard.isInFocusChain() and m.FocusedTextBox <> invalid then
    m.FocusedTextBox.color = m.global.constants.ui.colors.selectedEntryBox
    m.FocusedTextBox.textColor = m.global.constants.ui.colors.selectedEntryText
    m.FocusedTextBox.textOpacity = 1.0
  end if

  'Sign in button
  m.SignInButtonDisabledFocus.visible = false
  m.SignInButtonFocus.visible = false
  if m.SignInButton.isInFocusChain()
    if m.PasswordTextBox.text <> "" and m.EmailTextBox.text <> "" then
      m.SignInButtonFocus.visible = true
    else
      m.SignInButtonDisabledFocus.visible = true
    end if
  end if
End Function


'''''''''''''''''''''''''
' onKeyEvent
'
Function onKeyEvent(key As String, press As Boolean) As Boolean
  tubiLog("SignInEmailPasswordScreen.onKeyEvent")
  result = false
  if press then
    if key = "down" then
      if m.Keyboard.isInFocusChain() then
        startHideKeyboard()
        result = true
      else if m.EmailTextBox.isInFocusChain() then
        m.PasswordTextBox.setFocus(true)
        m.EmailTextBoxFocus.visible = false
        m.PasswordTextBoxFocus.visible = true
        result = true
      else if m.PasswordTextBox.isInFocusChain() then
        m.SignInButton.setFocus(true)
        m.PasswordTextBoxFocus.visible = false
        result = true
      end if
    else if key = "up" 
      if m.SignInButton.isInFocusChain() then
        m.PasswordTextBox.setFocus(true)
        m.PasswordTextBoxFocus.visible = true
        result = true
      else if m.PasswordTextBox.isInFocusChain() then
        m.PasswordTextBoxFocus.visible = false
        m.EmailTextBox.setFocus(true)
        m.EmailTextBoxFocus.visible = true
        result = true
      else if m.EmailTextBox.isInFocusChain() then
        m.FocusedTextBox = m.EmailTextBox
        m.EmailTextBoxFocus.visible = false
        m.EmailTextBox.setFocus(false)
        startShowKeyboard()
        result = true
      end if
    else if key = "OK" then
      if m.EmailTextBox.hasFocus() then
        m.FocusedTextBox = m.EmailTextBox
        m.EmailTextBoxFocus.visible = false
        m.EmailTextBox.setFocus(false)
        startShowKeyboard()
        result = true
      else if m.PasswordTextBox.hasFocus() then
        m.FocusedTextBox = m.PasswordTextBox
        m.PasswordTextBoxFocus.visible = false
        m.PasswordTextBox.setFocus(false)
        startShowKeyboard()
        result = true
      else if m.SignInButton.hasFocus() and m.SignInButtonFocus.visible = true then
        if m.SignIn = invalid then
          ' only sign-in if button is enabled and task isn't running
          signIn()
          result = true
        end if
      end if
    else if key = "back" then
      if m.Keyboard.isInFocusChain() then
        startHideKeyboard()
        result = true
      end if
    end if
  end if
  setColors()
  return result
End Function


'''''''''''''''''''''''''
' signIn
' 
' Start the sign-in task
Function signIn()
  tubiLog("SignInEmailPasswordScreen.signIn")
  m.SignIn = m.top.createChild("SignInTask")
  m.SignIn.email = m.EmailTextBox.text
  m.SignIn.password = m.PasswordTextBox.text
  m.SignIn.observeField("response", "onSignInResult")
  m.SignIn.control = "RUN"

  m.Spinner = m.top.findNode("SpinnerShade")
  m.SpinnerAnimation = m.top.findNode("SpinnerAnimation")
  m.Spinner.visible = true
  m.SpinnerAnimation.control = "start"
End Function


'''''''''''''''''''''''''
' onSignInResult
'
' Handle a sign in response from the task
Function onSignInResult()
  tubiLog("SignInEmailPasswordScreen.onSignInResult")
  m.SignIn.unobserveField("response")
  m.Spinner.visible = false
  m.SpinnerAnimation.control = "stop"

  if m.SignIn.response.code <> invalid and m.SignIn.response.code = 200 then
    m.top.signInResult = true
  else
    m.top.signInResult = false
  end if
  m.SignIn = invalid  ' free the task
End Function


'''''''''''''''''''''''''
' onCloseError
'
' Close the error dialog
Function onCloseError()
  m.top.removeChild(m.Dialog)
  m.Dialog.unobserveField("buttonSelected")
  m.Dialog = invalid
  m.EmailTextBox.setFocus(true)
End Function
