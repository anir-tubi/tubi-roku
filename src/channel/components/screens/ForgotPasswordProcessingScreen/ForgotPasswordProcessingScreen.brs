Function init()
  m.trackingLoggingTask = getFieldFromGlobal("trackingLoggingTask")
  m.constants = getConstantsFromGlobal()
  Request = TubiRequest(m.constants.settings)
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)
  
  '//keep a count of how many times the user attempts to resend a verification email. After a few times, present a modal to the user that their spam folder should be checked. Hopefully this will limit how many times a verification email is sent
  m.resendVerificationEmailCount = 0

  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("isInstantPassword", "onInstantChange")

  m.pageHeading = m.top.findNode("pageHeading")
  m.pageHeading.text = getTranslation("forgotPassword_screen_heading")

  m.email = m.top.findNode("email")
  m.pageSubHeading = m.top.findNode("pageSubHeading")
  m.pageSubHeading2 = m.top.findNode("pageSubHeading2")

  m.buttonGroup = m.top.findNode("buttonGroup")

  'set initial tracking values
  m.top.trackingPageInfo = {
    pageType: "login_page"
    pageValues: {
      choice: "LINK"
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
    m.pageHeading.color = theme.primaryTextColor
    m.pageSubHeading.color = theme.primaryTextColor
    m.pageSubHeading2.color = theme.primaryTextColor
    m.email.color = theme.focused2Color

    if m.returnBtn <> invalid
      m.returnBtn.color = theme.backgroundColorLight2
    end if

    if m.changeEmailBtn <> invalid
      m.changeEmailBtn.color = theme.backgroundColorLight2
    end if
    
    if m.resend <> invalid
      m.resend.color = theme.backgroundColorLight2
    end if

  end if
End Function


Function onScreenFocusChange()

  tubiLog("SignInScreen.onScreenFocusChange")
  ' force a background update
  m.top.backgroundUriList = m.backgroundUriList

End Function


Function onInstantChange(msg)
  TubiLog("ForgotPasswordProcessingScreen.onInstantChange")

  isInstantPassword = msg.getData()
  if isInstantPassword = true
    m.pageSubHeading.text = getTranslation("forgotPassword_screen_instant_subheading")
    m.pageSubHeading2.text = getTranslation("forgotPassword_screen_instant_subheading2")

    m.resendBtn = CreateObject("roSGNode", "SimpleButton")
    m.resendBtn.id = "resendBtn"
    m.resendBtn.text = getTranslation("forgotPassword_screen_btn_resend")
    m.resendBtn.observeFieldScoped("selected", "onResendInstantLinkSelected")


    m.buttonGroup.appendChild(m.resendBtn)

  else
    m.pageSubHeading.text = getTranslation("forgotPassword_screen_noInstant_subheading")
    m.pageSubHeading2.text = getTranslation("forgotPassword_screen_noInstant_subheading2")


    m.returnBtn = CreateObject("roSGNode", "SimpleButton")
    m.returnBtn.id = "returnBtn"
    m.returnBtn.text = getTranslation("forgotPassword_screen_btn_return")
    m.returnBtn.observeFieldScoped("selected", "onReturnSignInSelected")
    m.buttonGroup.appendChild(m.returnBtn)

  end if

  m.changeEmailBtn = CreateObject("roSGNode", "SimpleButton")
  m.changeEmailBtn.id = "changeEmailBtn"
  m.changeEmailBtn.text = getTranslation("forgotPassword_screen_btn_different_email")
  m.changeEmailBtn.observeFieldScoped("selected", "onChangeEmailSelected")
  m.buttonGroup.appendChild(m.changeEmailBtn)

  m.buttonGroup.getChild(0).setFocus(true)

  onThemeChange()
End Function


' The changeEmail button was clicked, let the helper know about this.
Function onChangeEmailSelected()
  '//::TODO::roku_registration_signin_password_reset_v2 - this can be changed to an alias if the experiment is graduated.
  m.top.selectedDifferentEmail = true
End Function 


' The returnToSignIn button was clicked, let the helper know about this.
Function onReturnSignInSelected()
  '//::TODO::roku_registration_signin_password_reset_v2 - this can be changed to an alias if the experiment is graduated.
  m.top.signInSelected = true
End Function 


' The resendInstantLink button was clicked, let the helper know about this.
Function onResendInstantLinkSelected()

  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: "LOGIN_REQUEST"
      pageOneof:  m.Tracking.getAnalyticsPage("login_page", {"choice": "LINK"})
      dialog_action: "SHOW"
      dialog_sub_type: "resend_link"
    }
  }
  title = getTranslation("dialog_exitApp_title")
  message = getTranslation("dialog_email_verification_email_already_sent") + Chr(10) + m.email.text + Chr(10) + getTranslation("dialog_email_verification_check_spam")
  buttons = [getTranslation("dialog_button_resend_verification_link"), getTranslation("dialog_button_cancel")]
  showSimpleInstantResumableModal(title, message, buttons, dialogEvent, m.trackingLoggingTask, onResendVerificationLinkSelected, onResendVerificationCancelSelected)
 
End Function 


Function onResendVerificationLinkSelected()
  tubiLog("ForgotPasswordProcessingScreen.onResendVerificationLinkSelected")
  m.resendVerificationEmailCount = m.resendVerificationEmailCount + 1
  if m.resendVerificationEmailCount = 3
    m.resendVerificationEmailCount = 0
    dialogEvent = {
      type: "dialog"
      values: {
        dialog_type: "LOGIN_REQUEST"
        pageOneof:  m.Tracking.getAnalyticsPage("login_page", {"choice": "LINK"})
        dialog_action: "SHOW"
        dialog_sub_type: "many_attempts"
      }
    }

    title = getTranslation("dialog_button_attempts_title")
    message = getTranslation("dialog_button_multiple_emails_sent") + Chr(10) + m.email.text +  Chr(10) + getTranslation("dialog_email_verification_check_spam")
    buttons = [getTranslation("dialog_button_close")]
    showSimpleInstantResumableModal(title, message, buttons, dialogEvent, m.trackingLoggingTask, onTooManyAttemptsCallback, onTooManyAttemptsCallback)
  else
    m.top.resendVerificationLink = true
    m.resendBtn.setFocus(true)
  end if
End Function


Function onResendVerificationCancelSelected()
  tubiLog("ForgotPasswordProcessingScreen.onResendVerificationCancelSelected")
  m.resendBtn.setFocus(true)
End Function


Function onTooManyAttemptsCallback()
  tubiLog("ForgotPasswordProcessingScreen.onTooManyAttemptsCallback")
  m.resendBtn.setFocus(true)
End Function


Function onKeyEvent(key As String, press As Boolean) as Boolean 
  handled = false
  if press
    if key = "back"
      handled = true
      m.top.backButtonSelected = true
    else if key = "down"
      if m.buttonGroup.getChildCount() > 1 AND m.buttonGroup.getChild(0).hasFocus() = true
        handled = true
        m.buttonGroup.getChild(1).setFocus(true)
      end if
    else if key = "up"
      if m.buttonGroup.getChildCount() > 1 AND m.buttonGroup.getChild(1).hasFocus() = true
        handled = true
        m.buttonGroup.getChild(0).setFocus(true)
      end if
    end if

    return handled
  end if
  return false
End Function