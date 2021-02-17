Function init()
  m.trackingLoggingTask = m.global.trackingLoggingTask
  m.constants = m.global.constants
  m.theme = m.global.theme
  
  m.top.observeFieldScoped("retrySignUp", "onRetrySignUp")
  m.top.observeField("focusedChild", "onScreenFocusChange")
  
  m.pageHeading = m.top.findNode("pageHeading")
  m.pageHeading.text = getTranslation("signUp_screen_heading")
  
  m.pageSubheading = m.top.findNode("pageSubheading")
  m.pageSubheading.text = getTranslation("metadata_continueWatching_notSignedIn_container_description")
  
  m.passwordValidationMsg = m.top.findNode("passwordValidationMsg")
  m.passwordValidationMsg.text = getTranslation("signUp_screen_password_validation")
  
  m.continueBtn = m.top.findNode("continueBtn")
  m.continueBtn.text = getTranslation("dialog_button_continue")
  m.continueBtn.observeFieldScoped("selected", "onContinueButtonSelected")
  
  m.existingAccLabel = m.top.findNode("existingAccLabel")
  m.existingAccLabel.text = getTranslation("already_having_account_text")
  
  m.signInBtn = m.top.findNode("signInBtn")
  m.signInBtn.text = getTranslation("dialog_button_signIn")
  m.signInBtn.observeFieldScoped("selected", "onSignInButtonSelected")
  
  m.termsBtn = m.top.findNode("termsBtn")
  m.termsBtn.text = getTranslation("screenSettings_menu_tos")
  m.termsBtn.observeFieldScoped("selected", "onTermsButtonSelected")
  
  m.ppBtn = m.top.findNode("ppBtn")
  m.ppBtn.text = getTranslation("screenSettings_menu_privacyPolicy")
  m.ppBtn.observeFieldScoped("selected", "onPrivacyPolicyButtonSelected")
  
  m.donotsellMyInfoBtn = m.top.findNode("donotsellMyInfoBtn")
  m.donotsellMyInfoBtn.text = getTranslation("screenSettings_menu_doNotSellPolicy")
  m.donotsellMyInfoBtn.observeFieldScoped("selected", "onDoNotSellMyInfoButtonSelected")
  
  m.keyboardGrp = m.top.findNode("keyboardGrp")
  
  m.keyboard = m.top.findNode("Keyboard")
  m.keyboard.showTextEditBox = false
  m.keyboard.focusedKeyColor = m.constants.ui.colors.keyboardFocusedText
  m.keyboard.focusBitmapUri = m.theme.keyboard_focused_key
  
  m.back = m.top.findNode("back")
  m.back.text = getTranslation("linearVideoPlayer_buttonBack")
  m.back.observeFieldScoped("selected", "onBackButtonSelected")
  
  m.showHidePassword = m.top.findNode("showHidePassword")
  m.showHidePassword.text = getTranslation("screenSettings_parentalPassword_button_show")
  m.showHidePassword.observeFieldScoped("selected", "onShowHideButtonSelected")
  
  m.continue = m.top.findNode("continue")
  m.continue.text = getTranslation("dialog_button_continue")
  m.continue.observeFieldScoped("selected", "onContinueButtonSelected")
  
  m.checkmark_circle = m.top.findNode("checkmark_circle")
  
  m.password = m.top.findNode("password")
  m.password.hint = getTranslation("signUp_password_hint")
  m.password.observeFieldScoped("selected", "onPasswordButtonSelected")
  
  'set initial tracking values
  m.top.trackingPageInfo = {
    pageType: "register_page"
    pageValues: {
      auth_method: "EMAIL"
    }
  }
  
  m.top.isStackable = true
  m.top.screenLevel = m.constants.ui.screenLevels.signUpScreen
  
End Function


Function onScreenFocusChange()

  tubiLog("SignUpScreen.onScreenFocusChange")
  if m.top.hasFocus() then
    m.password.setFocus(true)
  end if
  
End Function


Function onRetrySignUp()
  m.top.signUpSelected = {password : m.password.text}
End Function


Function onContinueButtonSelected(evt)

  buttonSelected = evt.getData()
  if buttonSelected = true
    if isPasswordValid() = true
      m.passwordValidationMsg.text = "" 
      m.passwordValidationMsg.color = "0xF0F1F5"
      m.passwordValidationMsg.opacity = 0.64
      m.top.signUpSelected = {password : m.password.text}
    else
      m.passwordValidationMsg.text = getTranslation("password_length_validation")
      m.passwordValidationMsg.color = "0xEB9C00"
      m.passwordValidationMsg.opacity = 1.0    
    end if  
  end if
  
End Function


Function onSignInButtonSelected(evt)

  buttonSelected = evt.getData()
  if buttonSelected = true
    m.top.signInSelected = true
  end if

End Function


Function onTermsButtonSelected(evt)

  buttonSelected = evt.getData()
  if buttonSelected = true
    m.top.staticPageSelected = "TermsOfServiceButton"
  end if

End Function


Function onPrivacyPolicyButtonSelected(evt)

  buttonSelected = evt.getData()
  if buttonSelected = true
    m.top.staticPageSelected = "PrivacyPolicyButton"
  end if

End Function


Function onDoNotSellMyInfoButtonSelected(evt)

  buttonSelected = evt.getData()
  if buttonSelected = true
    m.top.staticPageSelected = "DoNotSellPolicyButton"
  end if

End Function


Function onBackButtonSelected(evt)

  buttonSelected = evt.getData()
  if buttonSelected = true
    updatePasswordValidation()  
    hideKeyboard()
    m.password.setFocus(true)
  end if      

End Function


Function onShowHideButtonSelected(evt)

  buttonSelected = evt.getData()
  toggleShowHidePassword()

End Function


Function onPasswordButtonSelected(evt)

  buttonSelected = evt.getData()
  if buttonSelected = true
    m.passwordValidationMsg.text = getTranslation("password_length_validation") 
    m.passwordValidationMsg.color = "0xF0F1F5"
    m.passwordValidationMsg.opacity = 0.64
    showKeyboard()
    m.keyboard.setFocus(true)
  end if      

End Function


Function isPasswordValid()

  isValid = false
  passwordLength = Len(m.keyboard.text)
  if passwordLength >= 6 and passwordLength <= 30
    isValid = true
  end if
  return isValid

End Function


Function updatePasswordValidation()

  passwordLength = Len(m.keyboard.text)
  m.passwordValidationMsg.color = "0xEB9C00"
  m.passwordValidationMsg.opacity = 1.0  
  
  if passwordLength >= 6 and passwordLength <= 30
    m.passwordValidationMsg.text = "" 
  else if passwordLength = 0
    m.passwordValidationMsg.text = getTranslation("signUp_screen_password_validation")
  else
    m.passwordValidationMsg.text = getTranslation("password_length_validation")
  end if
  
End Function


Function showKeyboard()

  slideTo(m.keyboardGrp, [0,550], 1.0)
  
End Function


Function hideKeyboard()

  slideTo(m.keyboardGrp, [0,1080], 1.0) 
  
End Function


Function toggleShowHidePassword()
  if m.password.passwordMode = true
    m.showHidePassword.text = getTranslation("screenSettings_parentalPassword_button_hide")
    m.password.passwordMode = false
  else
    m.showHidePassword.text = getTranslation("screenSettings_parentalPassword_button_show")
    m.password.passwordMode = true
  end if
End Function


Function onKeyEvent(key As String, press As Boolean) as Boolean

  passwordLength = Len(m.keyboard.text)
  if key = "OK"
    m.password.text = m.keyboard.text
    if passwordLength >= 6 and passwordLength <= 30
      m.passwordValidationMsg.visible = false
      m.checkmark_circle.visible = true
    else
      m.passwordValidationMsg.visible = true
      m.checkmark_circle.visible = false
    end if
  end if
  
  handled = true
  if press
  
    if key = "back"
    
      if m.keyboard.isInFocusChain() = true or m.continue.hasFocus() = true or m.showHidePassword.hasFocus() = true or m.back.hasFocus() = true
        updatePasswordValidation()
        hideKeyboard()
        m.password.setFocus(true)
      else
        m.trackingLoggingTask.trackEvent = {
          type: "account"
          values: {
            manip: "SIGNUP"
            current: "EMAIL"
            user_type: "UNKNOWN_USER_TYPE"
            status: "FAIL"
            message: "user-cancel"
          }
        }      
        handled = false
      end if
      
    else if key = "down"
    
      if m.password.hasFocus() = true
        m.password.highlight = false
        m.continueBtn.setFocus(true)
      else if m.continueBtn.hasFocus() = true
        m.signInBtn.setFocus(true)
      else if m.signInBtn.hasFocus() = true
        m.termsBtn.setFocus(true)
      else if m.keyboard.isInFocusChain() = true
        m.continue.setFocus(true)
      end if  
    
    else if key = "up"
    
      if m.continueBtn.hasFocus() = true
        m.password.setFocus(true)
      else if m.signInBtn.hasFocus() = true
        m.continueBtn.setFocus(true)
      else if m.termsBtn.hasFocus() = true
        m.signInBtn.setFocus(true)
      else if m.ppBtn.hasFocus() = true
        m.signInBtn.setFocus(true)
      else if m.donotsellMyInfoBtn.hasFocus() = true
        m.signInBtn.setFocus(true)
      else if m.continue.hasFocus() = true
        m.keyboard.setFocus(true)
      else if m.showHidePassword.hasFocus() = true
        m.keyboard.setFocus(true)
      else if m.back.hasFocus() = true
        m.keyboard.setFocus(true)
      else if m.keyboard.isInFocusChain() = true
        updatePasswordValidation()  
        hideKeyboard()
        m.password.setFocus(true)
      end if
        
    else if key = "right"
    
      if m.termsBtn.hasFocus() = true
        m.ppBtn.setFocus(true)
      else if m.ppBtn.hasFocus() = true
        m.donotsellMyInfoBtn.setFocus(true)
      else if m.back.hasFocus() = true
        m.continue.setFocus(true)
      else if m.continue.hasFocus() = true
        m.showHidePassword.setFocus(true)
      end if
      
    else if key = "left"
    
      if m.donotsellMyInfoBtn.hasFocus() = true
        m.ppBtn.setFocus(true)
      else if m.ppBtn.hasFocus() = true
        m.termsBtn.setFocus(true)
      else if m.continue.hasFocus() = true
        m.back.setFocus(true)
      else if m.showHidePassword.hasFocus() = true
        m.continue.setFocus(true)    
      end if  
         
    end if
    return handled
  end if
  
End Function