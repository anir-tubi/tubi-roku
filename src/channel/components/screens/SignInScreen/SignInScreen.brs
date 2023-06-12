Function init()
  m.trackingLoggingTask = m.global.trackingLoggingTask
  m.constants = m.global.constants

  m.top.observeFieldScoped("resetFocus", "onResetFocus")
  m.top.observeField("focusedChild", "onScreenFocusChange")

  m.pageHeading = m.top.findNode("pageHeading")
  m.pageHeading.text = getTranslation("signIn_screen_heading")

  m.pageSubHeading = m.top.findNode("pageSubHeading")
  m.pageSubHeading.text = getTranslation("signIn_screen_subheading")

  m.passwordValidationMsg = m.top.findNode("passwordValidationMsg")
  m.passwordValidationMsg.text = getTranslation("signIn_screen_enter_password")

  m.continueBtn = m.top.findNode("continueBtn")
  m.continueBtn.text = getTranslation("dialog_button_continue")
  m.continueBtn.observeFieldScoped("selected", "onContinueButtonSelected")

  m.newPasswordLabel = m.top.findNode("newPasswordLabel")
  m.newPasswordLabel.text = getTranslation("new_password_text")

  m.newPasswordLink = m.top.findNode("newPasswordLink")
  m.newPasswordLink.text = getTranslation("new_password_link")

  m.termsBtn = m.top.findNode("termsBtn")
  m.termsBtn.text = getTranslation("screenSettings_menu_tos")
  m.termsBtn.observeFieldScoped("selected", "onTermsButtonSelected")

  m.ppBtn = m.top.findNode("ppBtn")
  m.ppBtn.text = getTranslation("screenSettings_menu_privacyPolicy")
  m.ppBtn.observeFieldScoped("selected", "onPrivacyPolicyButtonSelected")

  m.yourPrivacyChoicesBtn = m.top.findNode("YourPrivacyChoicesButton")
  m.yourPrivacyChoicesBtn.text = getTranslation("screenSettings_menu_yourPrivacyChoices")
  m.yourPrivacyChoicesBtn.observeFieldScoped("selected", "onYourPrvacyChoicesButtonSelected")

  m.keyboard = m.top.findNode("passwordEntryKeyboard")
  m.voiceKeyboard = m.keyboard.findNode("Keyboard")
  m.keyboard.observeFieldScoped("audioGuideText", "onAudioGuideTextChanged")
  m.keyboard.observeFieldScoped("buttonSelected", "onButtonSelected")

  m.buttonsGroup = m.top.findNode("buttonsGroup")

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
    m.termsBtn.color = theme.backgroundColor
    m.ppBtn.color = theme.backgroundColor
    m.yourPrivacyChoicesBtn.color = theme.backgroundColor
  end if
End Function


Function onScreenFocusChange()

  tubiLog("SignInScreen.onScreenFocusChange")
  ' force a background update
  m.top.backgroundUriList = m.backgroundUriList
  if m.top.hasFocus() then
    m.keyboard.observeFieldScoped("text", "onKeyboardTextChanged")
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


Function onTermsButtonSelected(evt)

  isButtonSelected = evt.getData()
  if isButtonSelected = true
    m.top.staticPageSelected = "TermsOfServiceButton"
  end if

End Function


Function onPrivacyPolicyButtonSelected(evt)

  isButtonSelected = evt.getData()
  if isButtonSelected = true
    m.top.staticPageSelected = "PrivacyPolicyButton"
  end if

End Function


Function onYourPrvacyChoicesButtonSelected(evt)

  isButtonSelected = evt.getData()
  if isButtonSelected = true
    m.top.staticPageSelected = "YourPrivacyChoicesButton"
  end if

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


Function onResetFocus(evt)

  resetFocus = evt.getData()
  if resetFocus = true
    clearPassword()
    resetPasswordValidation()
    hideButtons()
    showKeyboard()
    setFocusToComponent(m.keyboard)
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


Function onKeyEvent(key As String, press As Boolean) as Boolean

  if key = "OK"
    m.password.text = m.keyboard.text
  end if

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
        setFocusToComponent(m.termsBtn)
      end if

    else if key = "up"

      if m.password.hasFocus() = true
        setFocusToComponent(m.email)
        m.emailHasFocus = true
      else if m.continueBtn.hasFocus() = true
        setFocusToComponent(m.password)
        m.emailHasFocus = false
      else if m.termsBtn.hasFocus() = true
        setFocusToComponent( m.continueBtn)
      else if m.ppBtn.hasFocus() = true
        setFocusToComponent(m.continueBtn)
      else if m.yourPrivacyChoicesBtn.hasFocus() = true
        setFocusToComponent(m.continueBtn)
      else if m.keyboard.isInFocusChain() = true
        updatePasswordValidation()
        hideKeyboard()
        showButtons()
        setFocusToComponent(m.password)
        m.emailHasFocus = false
      end if

    else if key = "right"

      if m.termsBtn.hasFocus() = true
        setFocusToComponent(m.ppBtn)
      else if m.ppBtn.hasFocus() = true
        setFocusToComponent(m.yourPrivacyChoicesBtn)
      end if

    else if key = "left"

      if m.yourPrivacyChoicesBtn.hasFocus() = true
        setFocusToComponent(m.ppBtn)
      else if m.ppBtn.hasFocus() = true
        setFocusToComponent(m.termsBtn)
      end if

    end if

    return handled
  end if
  return false
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
