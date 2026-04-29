Function init()
  m.header = m.top.findNode("pageHeader")
  m.subHeader = m.top.findNode("PageSubHeader")
  m.digit1 = m.top.findNode("digit1")
  m.digit2 = m.top.findNode("digit2")
  m.digit3 = m.top.findNode("digit3")
  m.digit4 = m.top.findNode("digit4")
  m.digit5 = m.top.findNode("digit5")
  m.digit6 = m.top.findNode("digit6")
  m.digit1Poster = m.top.findNode("digit1Poster")
  m.digit2Poster = m.top.findNode("digit2Poster")
  m.digit3Poster = m.top.findNode("digit3Poster")
  m.digit4Poster = m.top.findNode("digit4Poster")
  m.digit5Poster = m.top.findNode("digit5Poster")
  m.digit6Poster = m.top.findNode("digit6Poster")
  m.digit1bg = m.top.findNode("digit1bg")
  m.digit2bg = m.top.findNode("digit2bg")
  m.digit3bg = m.top.findNode("digit3bg")
  m.digit4bg = m.top.findNode("digit4bg")
  m.digit5bg = m.top.findNode("digit5bg")
  m.digit6bg = m.top.findNode("digit6bg")
  m.errorMessage = m.top.findNode("errorMessage")
  m.buttonLayout = m.top.findNode("buttonLayout")

  m.errorMessage.text = getTranslation("otpScreen_error_otp_mismatch")
  m.constants = getConstantsFromGlobal()

  m.continueButton = m.top.findNode("continueButton")
  m.continueButton.text = getTranslation("dialog_button_continue")

  m.useDifferentEmailButton = m.top.findNode("useDifferentEmailButton")
  m.useDifferentEmailButton.text = getTranslation("otpScreen_use_different_email_button_label")


  m.otpResendButton = m.top.findNode("resendOTPButton")
  m.otpResendButton.text = getTranslation("otpScreen_resend_otp_button_label")

  m.header.text = getTranslation("otpScreen_header")

  m.numberPad = m.top.findNode("NumberPad")
  m.numberPad.observeField("text", "onKeyboardTextChanged")
  m.backButtonPoster = m.top.findNode("BackButtonPoster")

  m.top.observeFieldScoped("focusedChild", "onComponentFocusChanged")
  m.top.observeFieldScoped("otpError", "onOtpErrorChange")
  m.top.observeFieldScoped("email", "onEmailChange")

  m.continueButton.observeFieldScoped("selected", "onContinueButtonSelected")
  m.useDifferentEmailButton.observeFieldScoped("selected", "onUseDifferentEmailButtonSelected")
  m.otpResendButton.observeFieldScoped("selected", "onOtpResendButtonSelected")

  'default tracking page info
  m.top.trackingPageInfo = {
    pageType: "auth_page"
    pageValues: {
      auth_action: "ACTIVATION"
    }
  }

  m.backgroundUriList = []

  m.top.instantResumeAction = m.constants.instantResumeActions.restartApp

  typographyConstants = getTypographyConstants()
  m.bodySmallFontSize = typographyConstants.typographyAA[typographyConstants.ids.bodySmall].fontSize
  m.bodyMediumFontSize = typographyConstants.typographyAA[typographyConstants.ids.bodyMedium].fontSize
  setTypographyOfLabel(m.header, typographyConstants.ids.headerLarge)
  setTypographyOfLabel(m.digit1, typographyConstants.ids.bodyLargeStrong)
  setTypographyOfLabel(m.digit2, typographyConstants.ids.bodyLargeStrong)
  setTypographyOfLabel(m.digit3, typographyConstants.ids.bodyLargeStrong)
  setTypographyOfLabel(m.digit4, typographyConstants.ids.bodyLargeStrong)
  setTypographyOfLabel(m.digit5, typographyConstants.ids.bodyLargeStrong)
  setTypographyOfLabel(m.digit6, typographyConstants.ids.bodyLargeStrong)
  setTypographyOfLabel(m.continueButton, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.useDifferentEmailButton, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.otpResendButton, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.errorMessage, typographyConstants.ids.bodySmall)

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if

  onThemeChange()

  m.digitIndex = 0
  m.digit1Poster.visible = true
  m.digit1bg.visible = true
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  m.header.color = theme.primaryTextColor

  typographyConstants = getTypographyConstants()
  drawingStyles = {}
  drawingStyles["defaultStyle"] = getTypographyOfMultiStyleLabel(typographyConstants.ids.bodyMedium, theme.secondaryTextColor)
  drawingStyles["emailStyle"] = getTypographyOfMultiStyleLabel(typographyConstants.ids.bodyMedium, theme.focusedColor)
  m.subHeader.drawingStyles = drawingStyles
  updateSubHeaderText(m.top.email)

  m.digit1Poster.blendColor = theme.focusedColor
  m.digit2Poster.blendColor = theme.focusedColor
  m.digit3Poster.blendColor = theme.focusedColor
  m.digit4Poster.blendColor = theme.focusedColor
  m.digit5Poster.blendColor = theme.focusedColor
  m.digit6Poster.blendColor = theme.focusedColor
  m.digit1bg.blendColor = theme.primaryTextColor
  m.digit2bg.blendColor = theme.primaryTextColor
  m.digit3bg.blendColor = theme.primaryTextColor
  m.digit4bg.blendColor = theme.primaryTextColor
  m.digit5bg.blendColor = theme.primaryTextColor
  m.digit6bg.blendColor = theme.primaryTextColor
  m.errorMessage.color = theme.cautionColor
End Function


Function onComponentFocusChanged()
  if m.top.hasFocus()
    ' force a background update
    audioGuideText = m.header.text + " " + getTranslation("otpScreen_sub_heading") + " " + m.top.email
    readAudioGuideText(audioGuideText)
    m.top.backgroundUriList = m.backgroundUriList
    m.numberPad.setFocus(true)
  end if
End Function


Function onKeyboardTextChanged(msg)

  nDigits = m.numberPad.text.len()

  if nDigits = 0
    m.digit1.text = ""
    m.digit1Poster.visible = true
    m.digit2Poster.visible = false
    m.digit3Poster.visible = false
    m.digit4Poster.visible = false
    m.digit5Poster.visible = false
    m.digit6Poster.visible = false
  else if nDigits > 6
    m.numberPad.text = m.numberPad.text.left(6)
    nDigits = 6
  else
    for i = 1 to nDigits
      if nDigits <= 6
        sDigit = "digit" + i.toStr()
        sDigitPoster = sDigit + "Poster"
        m[sDigit].text = m.numberPad.text.mid(i - 1, 1)
        m[sDigitPoster].visible = false

        for j = 1 to 6
          sDigit = "digit" + j.toStr()
          sDigitPoster = sDigit + "Poster"
          if j > nDigits
            m[sDigit].text = ""
            if j = nDigits + 1
              m[sDigitPoster].visible = true
            else
              m[sDigitPoster].visible = false
            end if
          else if j < nDigits
            m[sDigitPoster].visible = false
          end if
        end for

      end if
    end for

  end if

  if nDigits = 6
    m.continueButton.setFocus(true)
  end if
End Function


Function onKeyEvent(key as String, press as Boolean) as Boolean
  handled = true
  if press = false then
    return false
  end if

  if key = "down"
    if m.numberPad.isInFocusChain() = true
      m.continueButton.setFocus(true)
      readAudioGuideText(m.continueButton.text)
    else if m.continueButton.isInFocusChain() = true
      m.otpResendButton.setFocus(true)
      readAudioGuideText(m.otpResendButton.text)
    else if m.otpResendButton.isInFocusChain() = true
      m.useDifferentEmailButton.setFocus(true)
      readAudioGuideText(m.useDifferentEmailButton.text)
    end if
  else if key = "up"
    if m.useDifferentEmailButton.hasFocus() = true
      m.otpResendButton.setFocus(true)
      readAudioGuideText(m.otpResendButton.text)
    else if m.otpResendButton.hasFocus() = true
      m.continueButton.setFocus(true)
      readAudioGuideText(m.continueButton.text)
    else if m.continueButton.hasFocus() = true
      m.numberPad.setFocus(true)
    end if
  else if key = "back"

    handled = false

  end if

  return handled

End Function


Function onContinueButtonSelected(msg)
  isButtonSelected = msg.getData()
  if isButtonSelected = true

    otpSubmitted = m.numberPad.text
    setOtpSubmitted(otpSubmitted)
  end if
End Function


Function setOtpSubmitted(otpSubmitted)
  signInInfo = {
    otp: otpSubmitted
    email: m.top.email
  }
  rfiSignInInfo = getOriginalRfiSignInInfo()
  if rfiSignInInfo <> invalid
    signInInfo.rfiSignInInfo = rfiSignInInfo
  end if

  m.top.signInInfo = signInInfo
  m.top.otpSubmitted = true
  m.continueButton.unobserveFieldScoped("selected")

End Function


' Returns the original Roku account sign-in info (rfiSignInInfo), avoiding nested re-wrapping.
' On the first OTP cycle m.top.signInInfo is itself the raw Roku data; on subsequent
' cycles its rfiSignInInfo field already holds the raw Roku data and must be preserved as-is.
Function getOriginalRfiSignInInfo() as Dynamic
  existingInfo = m.top.signInInfo
  if isAA(existingInfo) = false
    return invalid
  end if

  if isAA(existingInfo.rfiSignInInfo) = true
    return existingInfo.rfiSignInInfo
  end if
  return existingInfo
End Function


Function clearNumberPad()
  m.numberPad.text = ""
  m.digit1.text = ""
  m.digit2.text = ""
  m.digit3.text = ""
  m.digit4.text = ""
  m.digit5.text = ""
  m.digit6.text = ""
  m.digit1Poster.visible = true
  m.digit2Poster.visible = false
  m.digit3Poster.visible = false
  m.digit4Poster.visible = false
  m.digit5Poster.visible = false
  m.digit6Poster.visible = false
  m.numberPad.setFocus(true)
End Function


Function onOtpErrorChange(msg)
  errorResponse = msg.getData()
  if isAA(errorResponse) = true
    otpError = ""
    if isString(errorResponse.error) = true
      errorObj = parseJson(errorResponse.error)
      if isAA(errorObj) = true AND errorObj.code <> invalid
        otpError = errorObj.code
      end if
    else if isAA(errorResponse.error) = true
      otpError = errorResponse.error.code
    end if

    if otpError = "INVALID_OTP"
      m.errorMessage.text = getTranslation("otpScreen_error_otp_mismatch")
    else if otpError = "OTP_EXPIRED"
      m.errorMessage.text = getTranslation("otpScreen_error_otp_expired")
    else if otpError = "RATE_LIMITED" OR otpError = "TOO_MANY_ATTEMPTS"
      m.errorMessage.text = getTranslation("otpScreen_error_too_many_attempts")
    else
      m.errorMessage.text = getTranslation("otpScreen_error_unknown")
    end if

    showOtpErrorMessage(true)

    m.continueButton.observeFieldScoped("selected", "onContinueButtonSelected")
  end if
End Function


Function showOtpErrorMessage(otpError)
  if otpError = true
    m.errorMessage.visible = true
  else
    m.errorMessage.visible = false
  end if
  clearNumberPad()

End Function


Function onUseDifferentEmailButtonSelected(msg)
  m.top.userSelectedDifferentEmail = msg.getData()
End Function


Function onOtpResendButtonSelected(msg)
  isButtonSelected = msg.getData()
  if isButtonSelected = true
    clearNumberPad()
    m.errorMessage.visible = false
    m.otpResendButton.fontSize = m.bodySmallFontSize
    m.otpResendButton.text = getTranslation("otpScreen_resend_otp_sent_label")
    m.resendTimer = createObject("roSGNode", "Timer")
    m.resendTimer.duration = 3
    m.resendTimer.observeFieldScoped("fire", "onResendTimerFired")
    m.resendTimer.control = "start"

    signInInfo = {
      email: m.top.email
    }
    rfiSignInInfo = getOriginalRfiSignInInfo()
    if rfiSignInInfo <> invalid
      signInInfo.rfiSignInInfo = rfiSignInInfo
    end if

    m.top.signInInfo = signInInfo

    m.otpResendButton.unobserveFieldScoped("selected")
    m.continueButton.observeFieldScoped("selected", "onContinueButtonSelected")
    m.top.resendOTP = isButtonSelected
  end if

End Function


Function onEmailChange(msg)
  email = msg.getData()
  updateSubHeaderText(email)
End Function


Function updateSubHeaderText(email)
  subHeadingText = getTranslation("otpScreen_sub_heading")
  m.subHeader.text = Substitute("<defaultStyle>{0} </defaultStyle><emailStyle>{1}</emailStyle>", subHeadingText, email)
End Function


Function onResendTimerFired(msg)
  m.otpResendButton.text = getTranslation("otpScreen_resend_otp_button_label")
  m.otpResendButton.fontSize = m.bodyMediumFontSize
  m.otpResendButton.observeFieldScoped("selected", "onOtpResendButtonSelected")
  m.resendTimer.control = "stop"
  m.resendTimer.unobserveFieldScoped("fire")
  m.resendTimer = invalid
End Function
