Function init()
  tubiLog("EmailVerificationScreen.init")
  m.constants = getConstantsFromGlobal()
  Request = TubiRequest(m.constants.settings)
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)
  m.resendVerificationEmailCount = 0

  m.trackingLoggingTask = getFieldFromGlobal("trackingLoggingTask")
  m.EmailVerificationMenu = m.top.findNode("EmailVerificationMenu")
  m.EmailVerificationMenu.focusBitmapBlendColor = getThemeFromGlobal().focused
  m.emailNotificationPoster = m.top.findNode("emailNotificationPoster")
  m.emailInboxText = m.top.findNode("emailInboxText")
  m.verificationLinkText = m.top.findNode("verificationLinkText")
  m.email = m.top.findNode("email")
  m.verificationHintText = m.top.findNode("verificationHintText")
  m.resendVerificationLinkButton = m.top.findNode("resendVerificationLinkButton")
  m.useDifferentEmailButton = m.top.findNode("useDifferentEmailButton")
  'setting the alignment of the item in the list to make the text center when no iconUrl and badge text.
  m.resendVerificationLinkButton.align = "center"
  m.useDifferentEmailButton.align = "center"

  m.EmailVerificationMenu.observeField("itemSelected", "onEmailVerificationMenuItemSelected")
  m.top.observeField("focusedChild", "onScreenFocusChange")
  setInitialStrings()
  m.top.trackingPageInfo = {
    pageType: "login_page"
    pageValues: {
      choice: "LINK"
    }
  }
  m.top.screenLevel = m.constants.ui.screenLevels.emailVerificationScreen
End Function


Function setInitialStrings()
  m.emailInboxText.text = getTranslation("check_email_inbox")
  m.verificationLinkText.text = getTranslation("click_on_verification_link")
  m.verificationHintText.text = getTranslation("screen_refresh_after_email_verification")
  m.resendVerificationLinkButton.title = getTranslation("screenEmailVerification_resend_verification_link")
  m.useDifferentEmailButton.title = getTranslation("screenEmailVerification_use_different_email")
End Function


Function onEmailVerificationMenuItemSelected(msg)
  tubiLog("EmailVerificationScreen.onEmailVerificationMenuItemSelected")
  itemSelected = msg.getData()
  selection = m.EmailVerificationMenu.content.getChild(itemSelected)
  if selection.id = "resendVerificationLinkButton"

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
  else if selection.id = "useDifferentEmailButton"
    'show the email input screen
    m.top.selectedDifferentEmail = true

  end if
End Function


Function onResendVerificationLinkSelected()
  tubiLog("EmailVerificationScreen.onResendVerificationLinkSelected")
  m.resendVerificationEmailCount = m.resendVerificationEmailCount + 1
  if m.resendVerificationEmailCount = 3
    m.resendVerificationEmailCount  = 0
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
    showSimpleInstantResumableModal(title, message, buttons, dialogEvent, m.trackingLoggingTask, invalid, onTooManyAttemptsCallback)
  else
    m.top.resendVerificationLink = true
    dialogEvent = {
      type: "dialog"
      values: {
        dialog_type: "LOGIN_REQUEST"
        pageOneof: m.Tracking.getAnalyticsPage("login_page", {"choice": "LINK"})
        dialog_action: "ACCEPT_DELIBERATE"
        dialog_sub_type: "resend_link"
      }
    }
    m.trackingLoggingTask.trackEvent = dialogEvent
  end if
End Function


Function onResendVerificationCancelSelected()
  tubiLog("EmailVerificationScreen.onResendVerificationCancelSelected")
  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: "LOGIN_REQUEST"
      pageOneof: m.Tracking.getAnalyticsPage("login_page", {"choice": "LINK"})
      dialog_action: "DISMISS_DELIBERATE"
      dialog_sub_type: "resend_link"
    }
  }
  m.trackingLoggingTask.trackEvent = dialogEvent

End Function


Function onTooManyAttemptsCallback()
  tubiLog("EmailVerificationScreen.onTooManyAttemptsCallback")
  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: "LOGIN_REQUEST"
      pageOneof: m.Tracking.getAnalyticsPage("login_page", {"choice": "LINK"})
      dialog_action: "DISMISS_DELIBERATE"
      dialog_sub_type: "many_attempts"
    }
  }
  m.trackingLoggingTask.trackEvent = dialogEvent
End Function


''''''''''''''''''''
' onScreenFocusChange
'
' Set focus back to button list if the
' screen has lost focus, usually due to another screen or dialog
' being shown.
Function onScreenFocusChange()
  tubiLog("EmailVerificationScreen.onScreenFocusChange")
  if m.top.hasFocus() = true
    m.EmailVerificationMenu.setFocus(true)
  end if
End Function


Function onKeyEvent(key As String, press As Boolean) as Boolean
  if press = true
    if key = "back"
      m.top.backButtonSelected = true
      return false
    end if
  end if
  return true
End Function
