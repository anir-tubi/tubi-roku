Function init()
  m.trackingLoggingTask = getFieldFromGlobal("trackingLoggingTask")
  m.constants = getConstantsFromGlobal()

  m.top.observeFieldScoped("setFocusToKeyboard", "onSetFocusToKeyboard")
  m.top.observeFieldScoped("setFocusToPassword", "onSetFocusToPassword")
  m.top.observeField("focusedChild", "onScreenFocusChange")

  m.pageHeading = m.top.findNode("pageHeading")
  m.pageHeading.text = getTranslation("signIn_screen_heading")

  m.pageSubHeading = m.top.findNode("pageSubHeading")
  m.pageSubHeading.text = getTranslation("signIn_screen_subheading")

  m.passwordValidationMsg = m.top.findNode("passwordValidationMsg")
  m.passwordValidationMsg.text = getTranslation("signIn_screen_enter_password")

  m.buttonsGroup = m.top.findNode("buttonsGroup")

  m.continueBtn = m.top.findNode("continueBtn")
  m.continueBtn.text = getTranslation("dialog_button_continue")

  m.newPasswordLayout = m.top.findNode("newPasswordLayout")
  m.newPasswordLabel = m.top.findNode("newPasswordLabel")
  m.newPasswordLabel.text = getTranslation("new_password_text")

  m.newPasswordLink = m.top.findNode("newPasswordLink")
  m.newPasswordLink.text = getTranslation("new_password_link")

  bDisplayForgotPasswordButton = (getExperimentResource("roku_registration_signin_password_reset", "roku_registration_signin_password_reset_v2", true).enabled = true)
  
  m.forgotPasswordBtn = invalid  
  if bDisplayForgotPasswordButton = true
    '//::TODO::roku_registration_signin_password_reset_v2 - if experiment is graduated, then set the button in the XML and remove everything related to newPasswordLayout
    m.forgotPasswordBtn = CreateObject("roSGNode", "SimpleButton")
    m.forgotPasswordBtn.id = "forgotPasswordBtn"
    m.forgotPasswordBtn.text = getTranslation("dialog_button_forgot_password")

    m.buttonsGroup.insertChild(m.forgotPasswordBtn, 1)
    m.forgotPasswordBtn.observeFieldScoped("selected", "onForgotPasswordButtonSelected")
    m.buttonsGroup.removeChild(m.newPasswordLayout)
  end if

  m.keyboard = m.top.findNode("passwordEntryKeyboard")
  m.voiceKeyboard = m.keyboard.findNode("Keyboard")
  m.keyboard.observeFieldScoped("audioGuideText", "onAudioGuideTextChanged")

  m.password = m.top.findNode("password")
  m.password.hint = getTranslation("signIn_password_hint")
  m.password.observeFieldScoped("selected", "onPasswordButtonSelected")

  m.email = m.top.findNode("email")
  m.email.hint = getTranslation("signIn_email_hint")
  m.email.observeFieldScoped("selected", "onEmailSelected")

  'emailHasFocus is used to store the state of whether or not the email text entry field has been focused.
  'We need to store this state, and can't simply rely on m.email.isInFocusChain() because when user starts using microphone,
  'the email entry text field loses focus and keyboard gains the focus.
  m.emailHasFocus = false

  m.top.instantResumeAction = m.constants.instantResumeActions.startChannel

  'set initial tracking values
  m.top.trackingPageInfo = {
    pageType: "login_page"
    pageValues: {
      choice: "EMAIL"
    }
  }


  m.top.isStackable = true
  m.top.screenLevel = m.constants.ui.screenLevels.signInScreen
  m.backgroundUriList = [m.constants.ui.uris.marketingBackground]

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.newPasswordLabel.color = theme.primaryTextColor
    m.pageHeading.color = theme.primaryTextColor
    m.pageSubHeading.color = theme.primaryTextColor
    m.newPasswordLink.color = theme.primaryTextColor
    m.passwordValidationMsg.color = theme.cautionColor
    m.continueBtn.color = theme.backgroundColorLight2
    if m.forgotPasswordBtn <> invalid
      m.forgotPasswordBtn.color = theme.backgroundColorLight2
    end if
  end if
End Function


Function onScreenFocusChange()

  tubiLog("SignInScreen.onScreenFocusChange")
  ' force a background update
  m.top.backgroundUriList = m.backgroundUriList
  if m.top.hasFocus() then
    ' To avoid sending out multiple requests when continue button is clicked multiple times.
    ' We will unobserving the click after sending request. To handle cases where error happens and screen is refocused.
    ' unobserving it as a pre-caution to avoid multiple observers being attached.
    m.continueBtn.unobserveFieldScoped("selected")
    m.continueBtn.observeFieldScoped("selected", "onContinueButtonSelected")
    m.keyboard.observeFieldScoped("text", "onKeyboardTextChanged")
    m.keyboard.unobserveFieldScoped("buttonSelected")
    m.keyboard.observeFieldScoped("buttonSelected", "onButtonSelected")
    m.keyboard.voiceEnabled = true
    if m.email.text = "" 'if email field is empty when screen gains focus, then setting focus to email field
      setFocusToComponent(m.email)
      m.emailHasFocus = true
    else
      setFocusToComponent(m.password)
      m.emailHasFocus = false
    end if

  end if

  if m.top.isInFocusChain() = false
    m.keyboard.voiceEnabled = false
    m.keyboard.unobserveFieldScoped("text")
  end if

  'When user start using microphone, even though email has focus and setting m.emailHasFocus to true, it  changes
  'to m.emailHasFocus to false and email loses the focus and focus goes to keyboard. So, setting m.emailHasFocus to false only when
  'email is not in focusChain and focusedChild is not passwordEntryKeyboard.
  if m.email.isInFocusChain() = false AND m.top.focusedChild <> invalid AND m.top.focusedChild.id <> "passwordEntryKeyboard"
    m.emailHasFocus = false
  end if

End Function


Function setFocusToComponent(focusTarget)
  if focusTarget <> invalid
    topHasFocus = m.top.hasFocus()
    focusTarget.setFocus(true)
    audioGuideText = ""

    'Avoid screen reader for keyboard as we already handling in passwordentrykeyboard.
    if isRokuAudioGuideEnabled() = true AND focusTarget.id <> "passwordEntryKeyboard"
      if topHasFocus = true
        audioGuideText = m.pageHeading.text + " " + m.pageSubHeading.text
        if m.email.text = ""
          audioGuideText = audioGuideText + " " + m.constants.audioGuideHints.emailOkHint
        else
          audioGuideText = audioGuideText + " " + m.passwordValidationMsg.text
        end if

        audioGuideText = audioGuideText + " " + m.newPasswordLabel.text + m.newPasswordLink.text
      else if focusTarget.id = "password" AND isNonEmptyString(focusTarget.text) = false
        audioGuideText = m.passwordValidationMsg.text
      else
        audioGuideText = focusTarget.text
      end if

      readAudioGuideText(audioGuideText)
    end if
  end if
End Function


Function onEmailSelected(msg)
  isSelected = msg.getData()
  if isSelected = true
    ' we must set voiceEnabled = false here because if we rely on isInFocusChain() in
    ' onScreenFocusChange(), voiceEnabled is not set to false until after voiceEnabled is set to true
    ' on the EmailInputScreen, which prevents voiceEnabled is getting to true
    ' on the EmailInputScreen.
    m.keyboard.voiceEnabled = false
  end if
End Function


Function onContinueButtonSelected(evt)
  isButtonSelected = evt.getData()
  if isButtonSelected = true
    proceedPasswordValidation()
  end if

End Function


Function onForgotPasswordButtonSelected(evt)
  tubiLog("SignInScreen.onForgotPasswordButtonSelected")
  m.top.forgotPasswordSelected = true
End Function


Function onPasswordButtonSelected(evt)

  isButtonSelected = evt.getData()
  if isButtonSelected = true
    resetPasswordValidation()
    hideButtons()
    showKeyboard()
    setFocusToComponent(m.keyboard)
  end if

End Function


Function onSetFocusToKeyboard(evt)

  bSetFocusToKeyboard = evt.getData()
  if bSetFocusToKeyboard = true
    clearPassword()
    resetPasswordValidation()
    hideButtons()
    showKeyboard()
    setFocusToComponent(m.keyboard)
  end if

End Function


Function onSetFocusToPassword(evt)

  bSetFocusToPassword = evt.getData()
  if bSetFocusToPassword = true
    clearPassword()
    updatePasswordValidation()
    hideKeyboard()
    showButtons()
    setFocusToComponent(m.password)
    m.emailHasFocus = false 
  end if

End Function


Function clearPassword()

  m.keyboard.text = ""
  m.password.text = ""

End Function


Function isPasswordValid()

  isValid = false
  if Len(m.keyboard.text) > 0
    isValid = true
  end if
  return isValid

End Function


Function resetPasswordValidation()
  theme = getThemeFromGlobal()
  if theme <> invalid
    m.passwordValidationMsg.color = theme.secondaryTextColor
  end if
End Function


Function updatePasswordValidation()
  theme = getThemeFromGlobal()
  passwordLength = Len(m.keyboard.text)
  if theme <> invalid
    if passwordLength > 0
      m.passwordValidationMsg.color = theme.secondaryTextColor
    else
      m.passwordValidationMsg.color = theme.cautionColor
    end if
  end if

End Function


Function showKeyboard()
  slideTo(m.keyboard, [0,550], 1.0)

End Function


Function hideButtons()
  fade(m.buttonsGroup, "out", 0.6)

End Function


Function hideKeyboard()
  slideTo(m.keyboard, [0,1080], 1.0)
  m.continueBtn.visible = true

End Function


Function showButtons()

  fade(m.buttonsGroup, "in", 0.6, 0.4)

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
    m.keyboard.unobserveFieldScoped("buttonSelected")
    proceedPasswordValidation()
  else if buttonSelected = "back" or buttonSelected = "up"
    updatePasswordValidation()
    hideKeyboard()
    showButtons()
    setFocusToComponent(m.password)
    m.emailHasFocus = false
  end if

End Function


Function proceedPasswordValidation()

    updatePasswordValidation()
    if isPasswordValid() = true
      m.top.signInSelected = {
        password : m.password.text
        email : m.email.text
      }
      m.continueBtn.unobserveFieldScoped("selected")
    end if
End Function


Function onKeyboardTextChanged()
  tubiLog("SignInScreen.onKeyboardTextChanged")
  if m.keyboard.isInFocusChain() = true AND m.emailHasFocus = false
    m.password.selected = true
    m.password.text = m.keyboard.text
  else if m.emailHasFocus = true
    m.keyboard.voiceEnabled = false
    m.top.emailSelected = true
  end if
 End Function


 Function onAudioGuideTextChanged(msg)
  audioGuideText = msg.getData()
  if isNonEmptyString(audioGuideText) = true
    readAudioGuideText(audioGuideText)
  end if
 End Function


 Function onKeyEvent(key As String, press As Boolean) as Boolean
 if key = "OK"
   m.password.text = m.keyboard.text
 end if

 bDisplayForgotPasswordButton = (getExperimentResource("roku_registration_signin_password_reset", "roku_registration_signin_password_reset_v2", false).enabled = true)
         
 handled = true
 if press
   if key = "back"

     if m.keyboard.isInFocusChain() = true 
       updatePasswordValidation()
       hideKeyboard()
       showButtons()
       setFocusToComponent(m.password)
       m.emailHasFocus = false
     else
       m.trackingLoggingTask.trackEvent = {
         type: "account"
         values: {
           manip: "SIGNIN"
           current: "EMAIL"
           status: "FAIL"
           message: "user-cancel"
         }
       }
       handled = false
     end if

   else if key = "down"

     if m.email.hasFocus() = true
       setFocusToComponent(m.password)
       m.emailHasFocus = false
     else if m.password.hasFocus() = true
       setFocusToComponent(m.continueBtn)
     else if m.continueBtn.hasFocus() = true
       if bDisplayForgotPasswordButton = true
         setFocusToComponent(m.forgotPasswordBtn)
       end if
     end if

   else if key = "up"

     if m.password.hasFocus() = true
       setFocusToComponent(m.email)
       m.emailHasFocus = true
     else if m.continueBtn.hasFocus() = true
       setFocusToComponent(m.password)
       m.emailHasFocus = false
     else if m.forgotPasswordBtn <> invalid AND m.forgotPasswordBtn.hasFocus() = true
       setFocusToComponent(m.continueBtn)
     else if m.keyboard.isInFocusChain() = true
       updatePasswordValidation()
       hideKeyboard()
       showButtons()
       setFocusToComponent(m.password)
       m.emailHasFocus = false
     end if
   end if

   return handled
 end if
 return false
End Function