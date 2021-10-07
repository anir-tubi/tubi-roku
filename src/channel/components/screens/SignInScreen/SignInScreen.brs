Function init()
  m.trackingLoggingTask = m.global.trackingLoggingTask
  m.constants = m.global.constants
  m.theme = m.global.theme
  
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
  
  m.password = m.top.findNode("password")
  m.password.hint = getTranslation("signIn_password_hint")
  m.password.observeFieldScoped("selected", "onPasswordButtonSelected")

  m.email = m.top.findNode("email")
  m.email.hint = getTranslation("signIn_email_hint")

  'set initial tracking values
  m.top.trackingPageInfo = {
    pageType: "login_page"
    pageValues: {
      choice: "EMAIL"
    }
  }
  
  m.top.isStackable = true
  m.top.screenLevel = m.constants.ui.screenLevels.signInScreen

End Function


Function onScreenFocusChange()

  tubiLog("SignInScreen.onScreenFocusChange")
  if m.top.hasFocus() then
    if m.email.text = "" 'if email field is empty when screen gains focus, then setting focus to email field
      m.email.setFocus(true)
    else
      m.password.setFocus(true)
    end if
  end if
  
End Function


Function onContinueButtonSelected(evt)

  isButtonSelected = evt.getData()
  if isButtonSelected = true
    updatePasswordValidation()
    if isPasswordValid() = true
      m.top.signInSelected = {
        password : m.password.text, 
        email : m.email.text
      }
    end if  
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


Function onDoNotSellMyInfoButtonSelected(evt)

  isButtonSelected = evt.getData()
  if isButtonSelected = true
    m.top.staticPageSelected = "DoNotSellPolicyButton"
  end if

End Function


Function onBackButtonSelected(evt)

  isButtonSelected = evt.getData()
  if isButtonSelected = true
    updatePasswordValidation()  
    hideKeyboard()
    m.password.setFocus(true)
  end if      

End Function


Function onShowHideButtonSelected(evt)

  isButtonSelected = evt.getData()
  toggleShowHidePassword()

End Function


Function onPasswordButtonSelected(evt)

  isButtonSelected = evt.getData()
  if isButtonSelected = true
    resetPasswordValidation()
    showKeyboard()
    m.keyboard.setFocus(true)
  end if      

End Function


Function onResetFocus(evt)

  resetFocus = evt.getData()
  if resetFocus = true
    clearPassword()
    resetPasswordValidation()
    showKeyboard()  
    m.keyboard.setFocus(true)
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

  m.passwordValidationMsg.color = "0xF0F1F5"
  m.passwordValidationMsg.opacity = 0.64 

End Function


Function updatePasswordValidation()

  passwordLength = Len(m.keyboard.text)
  if passwordLength > 0
    m.passwordValidationMsg.color = "0xF0F1F5"
    m.passwordValidationMsg.opacity = 0.64    
  else
    m.passwordValidationMsg.color = "0xEB9C00"
    m.passwordValidationMsg.opacity = 1.0    
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

  if key = "OK"
    m.password.text = m.keyboard.text
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
        m.password.setFocus(true)
      else if m.password.hasFocus() = true
        m.continueBtn.setFocus(true)
      else if m.continueBtn.hasFocus() = true
        m.termsBtn.setFocus(true) 
      else if m.keyboard.isInFocusChain() = true
        m.continue.setFocus(true)
      end if  
    
    else if key = "up"
    
      if m.password.hasFocus() = true
        m.email.setFocus(true)
      else if m.continueBtn.hasFocus() = true
        m.password.setFocus(true)
      else if m.termsBtn.hasFocus() = true
        m.continueBtn.setFocus(true) 
      else if m.ppBtn.hasFocus() = true
        m.continueBtn.setFocus(true)
      else if m.donotsellMyInfoBtn.hasFocus() = true
        m.continueBtn.setFocus(true)
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