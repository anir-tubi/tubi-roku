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
End Function

''''''''''''''''''''''
' onScreenFocusChange
'
' Set focus and apply form element colors
Function onScreenFocusChange()
  tubiLog("SignInEmailPasswordScreen.onScreenFocusChange")
  if m.top.hasFocus() then
    m.EmailTextBox.setFocus(true)
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
  end if

  'Sign In button
  m.SignInButtonDisabledFocus.visible = false
  m.SignInButtonFocus.visible = false
  if m.PasswordTextBox.text <> "" and m.EmailTextBox.text <> "" then
    m.SignInButton.opacity = 1.0
    if m.SignInButton.isInFocusChain() then m.SignInButtonFocus.visible = true
  else
    m.SignInButton.opacity = 0.5
    if m.SignInButton.isInFocusChain() then m.SignInButtonDisabledFocus.visible = true
  end if
End Function


'''''''''''''''''''''''''
' onKeyEvent
'
Function onKeyEvent(key As String, press As Boolean) As Boolean
  tubiLog("SignInEmailPasswordScreen.onKeyEvent")
  if press then
    if key = "down" then
      if m.Keyboard.isInFocusChain() then
        startHideKeyboard()
        return true
      else if m.EmailTextBox.isInFocusChain() then
        m.PasswordTextBox.setFocus(true)
        m.EmailTextBoxFocus.visible = false
        m.PasswordTextBoxFocus.visible = true
        return true
      else if m.PasswordTextBox.isInFocusChain() then
        m.SignInButton.setFocus(true)
        m.PasswordTextBoxFocus.visible = false
        return true
      end if
    else if key = "up" 
      if m.SignInButton.isInFocusChain() then
        m.PasswordTextBox.setFocus(true)
        m.PasswordTextBoxFocus.visible = true
        return true
      else if m.PasswordTextBox.isInFocusChain() then
        m.PasswordTextBoxFocus.visible = false
        m.EmailTextBox.setFocus(true)
        m.EmailTextBoxFocus.visible = true
        return true
      end if
    else if key = "OK" then
      if m.EmailTextBox.hasFocus() then
        m.FocusedTextBox = m.EmailTextBox
        m.EmailTextBoxFocus.visible = false
        m.EmailTextBox.setFocus(false)
        startShowKeyboard()
        return true
      else if m.PasswordTextBox.hasFocus() then
        m.FocusedTextBox = m.PasswordTextBox
        m.PasswordTextBoxFocus.visible = false
        m.PasswordTextBox.setFocus(false)
        startShowKeyboard()
        return true
      else if m.SignInButton.hasFocus()
        signIn()
        return true
      end if
    end if
  end if
  return false
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
' Handle a sign in response from the task, showing an
' error or setting 'signInSuccess' field on success.
Function onSignInResult()
  tubiLog("SignInEmailPasswordScreen.onSignInResult")
  m.SignIn.unobserveField("response")
  m.Spinner.visible = false
  m.SpinnerAnimation.control = "stop"
  if m.SignIn.response.code <> invalid and m.SignIn.response.code = 200 then
    'TODO(Chris): persist credentials, or let the library do it
    m.top.signInSuccess = true
  else
    'TODO(Chris): show failure dialog
    m.Dialog = m.top.createChild("ModalDialogScreen")
    m.Dialog.title = "Sign In Failed"
    m.Dialog.message = "The email and password combination you provided is not valid."
    m.Dialog.buttons = ["Try again"]
    m.Dialog.observeField("buttonSelected", "onCloseError")
    m.Dialog.setFocus(true)
  end if
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
