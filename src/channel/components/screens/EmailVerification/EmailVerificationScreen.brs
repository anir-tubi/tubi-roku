Function init()
  tubiLog("EmailVerificationScreen.init")
  m.trackingLoggingTask = getFieldFromGlobal("trackingLoggingTask")
  m.constants = getConstantsFromGlobal()
  m.Tracking = TubiTrackingInfo(m.constants)

  m.resendVerificationEmailCount = 0

  m.top.observeFieldScoped("focusedChild", "onScreenFocusChange")

  m.pageHeading = m.top.findNode("pageHeading")
  m.pageHeading.text = getTranslation("check_email_inbox")

  m.email = m.top.findNode("email")
  m.pageSubHeading = m.top.findNode("pageSubHeading")
  m.pageSubHeading2 = m.top.findNode("pageSubHeading2")

  m.top.trackingPageInfo = {
    pageType: "login_page"
    pageValues: {
      choice: "LINK"
    }
  }

  m.pageSubHeading.text = getTranslation("forgotPassword_screen_instant_subheading")
  m.pageSubHeading2.text = getTranslation("forgotPassword_screen_instant_subheading2")

  m.resendBtn = m.top.findNode("resendBtn")
  m.resendBtn.text = getTranslation("forgotPassword_screen_btn_resend")
  m.resendBtn.observeFieldScoped("selected", "onResendInstantLinkSelected")

  m.changeEmailBtn = m.top.findNode("changeEmailBtn")
  m.changeEmailBtn.text = getTranslation("forgotPassword_screen_btn_different_email")
  m.changeEmailBtn.observeFieldScoped("selected", "onChangeEmailSelected")

  m.continueBtn = m.top.findNode("continueBtn")
  m.continueBtn.text = getTranslation("continueAsGuest_button")
  m.continueBtn.observeFieldScoped("selected", "onChangeEmailSelected")

  m.buttonGroup = m.top.findNode("buttonGroup")


  m.top.screenLevel = m.constants.ui.screenLevels.signInScreen

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.pageHeading, typographyConstants.ids.headerLarge)
  setTypographyOfLabel(m.pageSubHeading, typographyConstants.ids.bodyLarge)
  setTypographyOfLabel(m.email, typographyConstants.ids.subheaderMedium)
  setTypographyOfLabel(m.pageSubHeading2, typographyConstants.ids.bodyMedium)

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
    m.email.color = theme.primaryTextColor
    m.changeEmailBtn.color = theme.backgroundColorLight2
    m.resendBtn.color = theme.backgroundColorLight2
    m.continueBtn.color = theme.backgroundColorLight2
  end if
End Function


Function onScreenFocusChange()
  tubiLog("EmailVerificationScreen.onScreenFocusChange")
  ' force a background update
  m.top.backgroundUriList = []

  if m.top.hasFocus() = true

    if m.top.isMajorEventDay = true
      m.continueBtn.visible = true
      m.resendBtn.visible = false
      m.resendBtn.scale = [0, 0]

      m.pageSubHeading2.text = m.pageSubHeading2.text + Chr(10) + getTranslation("havent_received_email") 
    else
      m.resendBtn.visible = true
      m.continueBtn.visible = false
      m.continueBtn.scale = [0, 0]
    end if
    m.buttonGroup.setFocus(true)
  end if
End Function


' The changeEmail button was clicked, let the helper know about this.
Function onChangeEmailSelected()
  m.top.selectedDifferentEmail = true
End Function


' The resendInstantLink button was clicked, let the helper know about this.
Function onResendInstantLinkSelected()
  tubiLog("EmailVerificationScreen.onResendInstantLinkSelected")
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
  tubiLog("EmailVerificationScreen.onResendVerificationLinkSelected")
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
    showSimpleInstantResumableModal(title, message, buttons, dialogEvent, m.trackingLoggingTask, onTooManyAttemptsCallback)
  else
    m.top.resendVerificationLink = true
    m.resendBtn.setFocus(true)
  end if
End Function


Function onResendVerificationCancelSelected()
  tubiLog("EmailVerificationScreen.onResendVerificationCancelSelected")
  m.resendBtn.setFocus(true)
End Function


Function onTooManyAttemptsCallback()
  tubiLog("EmailVerificationScreen.onTooManyAttemptsCallback")
  m.resendBtn.setFocus(true)
End Function


Function onKeyEvent(key As String, press As Boolean) as Boolean
  if press AND key = "back"
    m.top.backButtonSelected = true
    return true
  end if

  return false
End Function
