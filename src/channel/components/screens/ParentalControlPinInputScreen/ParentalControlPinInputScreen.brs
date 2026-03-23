Function init()
  m.header = m.top.findNode("PageHeader")
  m.subHeader = m.top.findNode("PageSubHeader")
  m.topHeader = m.top.findNode("TopPageHeader")
  m.digit1 = m.top.findNode("digit1")
  m.digit2 = m.top.findNode("digit2")
  m.digit3 = m.top.findNode("digit3")
  m.digit4 = m.top.findNode("digit4")
  m.digit1Poster = m.top.findNode("digit1Poster")
  m.digit2Poster = m.top.findNode("digit2Poster")
  m.digit3Poster = m.top.findNode("digit3Poster")
  m.digit4Poster = m.top.findNode("digit4Poster")
  m.digit1bg = m.top.findNode("digit1bg")
  m.digit2bg = m.top.findNode("digit2bg")
  m.digit3bg = m.top.findNode("digit3bg")
  m.digit4bg = m.top.findNode("digit4bg")
  m.errorMessage = m.top.findNode("errorMessage")
  m.buttonLayout = m.top.findNode("buttonLayout")
  m.skipButtonLegalText = m.top.findNode("skipButtonLegalText")
  m.skipButtonLegalText.text = getTranslation("ParentalControlPinInputScreen_skip_button_legal_label", { url: "https://tubitv.com/help-center/App-Features-and-Settings/articles/42331260335643" })
  m.skipButtonLegalText.visible = true

  m.errorMessage.text = getTranslation("screenSettings_parentalPassword_error_pin_mismatch")
  m.constants = getConstantsFromGlobal()

  m.continueButton = m.top.findNode("continueButton")
  m.continueButton.text = getTranslation("dialog_button_continue")

  m.multiPurposeButton = m.top.findNode("multiPurposeButton")
  m.multiPurposeButton.text = getTranslation("ParentalControlPinInputScreen_skip_button_label")

  m.header.text = getTranslation("ParentalControlPinPad_header")
  m.topHeader.text = getTranslation("kidsAgeSelection_top_header")
  m.subHeader.text = getTranslation("ParentalControlPinPad_sub_header")

  m.numberPad = m.top.findNode("NumberPad")
  m.numberPad.observeField("text", "onKeyboardTextChanged")
  m.backButtonPoster = m.top.findNode("BackButtonPoster")

  m.top.observeFieldScoped("focusedChild", "onComponentFocusChanged")
  m.continueButton.observeFieldScoped("selected", "onContinueButtonSelected")
  m.multiPurposeButton.observeFieldScoped("selected", "onMultiPurposeButtonSelected")
  m.top.observeFieldScoped("mode", "onModeChange")
  m.top.observeFieldScoped("pinError", "onPinErrorChange")

  'default tracking page info
  m.top.trackingPageInfo = {
    pageType: "pin_page"
    pageValues: {
      pin_action: "ENTER_PIN"
    }
  }

  m.backgroundUriList = []

  m.top.instantResumeAction = m.constants.instantResumeActions.restartApp

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.header, typographyConstants.ids.headerLarge)
  setTypographyOfLabel(m.topHeader, typographyConstants.ids.bodyLargeStrong)
  setTypographyOfLabel(m.subHeader, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.digit1, typographyConstants.ids.bodyLargeStrong)
  setTypographyOfLabel(m.digit2, typographyConstants.ids.bodyLargeStrong)
  setTypographyOfLabel(m.digit3, typographyConstants.ids.bodyLargeStrong)
  setTypographyOfLabel(m.digit4, typographyConstants.ids.bodyLargeStrong)
  setTypographyOfLabel(m.continueButton, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.multiPurposeButton, typographyConstants.ids.bodyMediumStrong)
  setTypographyOfLabel(m.errorMessage, typographyConstants.ids.bodySmall)
  setTypographyOfLabel(m.skipButtonLegalText, typographyConstants.ids.bodySmall)

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if

  onThemeChange()

  m.digitIndex = 0
  m.digit1Poster.visible = true
  m.digit1bg.visible = false
  m.pinSubmitted = "0000"
  m.pinConfirmed = false
  m.getPinConfirmed = false
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  m.header.color = theme.primaryTextColor
  m.topHeader.color = theme.primaryTextColor
  m.subHeader.color = theme.secondaryTextColor
  m.digit1Poster.blendColor = theme.focusedColor
  m.digit2Poster.blendColor = theme.focusedColor
  m.digit3Poster.blendColor = theme.focusedColor
  m.digit4Poster.blendColor = theme.focusedColor
  m.digit1bg.blendColor = theme.primaryTextColor
  m.digit2bg.blendColor = theme.primaryTextColor
  m.digit3bg.blendColor = theme.primaryTextColor
  m.digit4bg.blendColor = theme.primaryTextColor
  m.errorMessage.color = theme.cautionColor
  m.skipButtonLegalText.color = theme.secondaryTextColor
End Function


Function onComponentFocusChanged()
  if m.top.hasFocus()
    ' force a background update
    audioGuideText = m.topHeader.text + m.header.text + m.subHeader.text
    readAudioGuideText(audioGuideText)
    m.top.backgroundUriList = []
    m.numberPad.setFocus(true)
  end if
End Function


Function onKeyboardTextChanged(msg)

  nDigits = m.numberPad.text.len()

  if nDigits = 0
    m.digit1.text = ""
    m.digit1Poster.visible = true
  else if nDigits > 4
    m.numberPad.text = m.numberPad.text.left(4)
    nDigits = 4
  else
    for i = 1 to nDigits
      if nDigits <= 4
        sDigit = "digit" + i.toStr()
        sDigitPoster = sDigit + "Poster"
        m[sDigit].text = m.numberPad.text.mid(i - 1, 1)
        m[sDigitPoster].visible = true

        for j = 1 to 4
          sDigit = "digit" + j.toStr()
          sDigitPoster = sDigit + "Poster"
          if j > nDigits

            m[sDigit].text = ""
            m[sDigitPoster].visible = false
          else if j < nDigits
            m[sDigit].text = "."
            m[sDigitPoster].visible = true
          end if
        end for

      end if
    end for

  end if

  if nDigits = 4
    m.pinSubmitted = m.numberPad.text
    m.digit4.text = "."
    m.continueButton.setFocus(true)
    readAudioGuideText(m.continueButton.text)
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
    else if m.continueButton.isInFocusChain() = true AND m.multiPurposeButton.visible = true
      m.multiPurposeButton.setFocus(true)
      readAudioGuideText(m.multiPurposeButton.text)
    end if
  else if key = "up"
    if m.multiPurposeButton.visible = true AND m.multiPurposeButton.hasFocus() = true
      m.continueButton.setFocus(true)
      readAudioGuideText(m.continueButton.text)
    else if m.continueButton.hasFocus() = true
      m.numberPad.setFocus(true)
    end if
  else if key = "back"
    if m.backButtonPoster.visible = true
      if m.top.mode = "confirm_pin"
        m.pinConfirmed = false
        m.pinNeedsConfirmation = invalid
        m.top.mode = "edit_pin"
        clearNumberPad()
        showPinErrorMessage(false)
        handled = true
      else
        handled = false
      end if
    end if
  end if

  return handled

End Function


Function onContinueButtonSelected(msg)
  isButtonSelected = msg.getData()
  if isButtonSelected = true

    pinSubmitted = ""
    len = m.numberPad.text.len()
    if len = 4
      pinSubmitted = m.numberPad.text

      if m.getPinConfirmed = true AND m.pinConfirmed = false
        if m.pinNeedsConfirmation = invalid
          m.pinNeedsConfirmation = pinSubmitted
          m.top.mode = "confirm_pin"
          clearNumberPad()
        else
          comparePin(m.pinNeedsConfirmation, pinSubmitted)
        end if
      else
        setPinSubmitted(pinSubmitted)
      end if
    end if
  end if
End Function


Function setPinSubmitted(pinSubmitted)
  signInInfo = m.top.signInInfo
  if signInInfo <> invalid
    signInInfo["pinSubmitted"] = pinSubmitted
    m.top.signInInfo = signInInfo
    m.top.pinSubmitted = true
  end if
End Function


Function clearNumberPad()

  m.numberPad.text = ""
  m.digit1.text = ""
  m.digit2.text = ""
  m.digit3.text = ""
  m.digit4.text = ""
  m.numberPad.setFocus(true)
End Function


Function comparePin(pin1, pin2)
  if pin1 = pin2
    m.pinConfirmed = true
    setPinSubmitted(pin2)
    showPinErrorMessage(false)
  else
    m.pinConfirmed = false
    m.top.mode = "confirm_pin"
    showPinErrorMessage(true)
  end if
End Function


Function onModeChange(msg = invalid)
  if msg <> invalid
    mode = msg.getData()
    setMode(mode)
  end if
End Function


Function setMode(mode)
  if mode = "edit_pin"
    m.header.text = getTranslation("screenSettings_parentalPassword_create_new_pin")
    m.continueButton.text = getTranslation("dialog_button_continue")
    m.top.screenLevel = m.constants.ui.screenLevels.confirmpasswordscreen
    m.multiPurposeButton.visible = false
    m.buttonLayout.removeChild(m.skipButtonLegalText)
    m.backButtonPoster.visible = true
    m.getPinConfirmed = true
  else if mode = "confirm_pin"
    m.header.text = getTranslation("screenSettings_parentalPassword_confirm_pin")
    m.continueButton.text = getTranslation("button_text_updatePin")
    m.top.screenLevel = m.constants.ui.screenLevels.confirmpasswordscreen
    m.multiPurposeButton.visible = false
    m.buttonLayout.removeChild(m.skipButtonLegalText)
    m.backButtonPoster.visible = true
    m.getPinConfirmed = true
  else if mode = "enter_pin"
    m.header.text = getTranslation("ParentalControlPinInputScreen_enter_pin_header")
    m.continueButton.text = getTranslation("dialog_button_continue")
    m.top.screenLevel = m.constants.ui.screenLevels.confirmpasswordscreen
    m.multiPurposeButton.text = getTranslation("ParentalControlPinInputScreen_forgot_pin_button_label")
    m.multiPurposeButton.visible = true
    m.buttonLayout.removeChild(m.skipButtonLegalText)
    m.backButtonPoster.visible = true
    m.getPinConfirmed = false
  else
    m.header.text = getTranslation("screenSettings_parentalPassword_create_new_pin")
    m.continueButton.text = getTranslation("dialog_button_continue")
    m.top.screenLevel = m.constants.ui.screenLevels.ageGateScreen
    if m.skipButtonLegalText.getParent() = invalid
      m.buttonLayout.insertChild(m.skipButtonLegalText, 1)
    end if
    m.multiPurposeButton.text = getTranslation("ParentalControlPinInputScreen_skip_button_label")
    m.multiPurposeButton.visible = true
    m.backButtonPoster.visible = false
    m.getPinConfirmed = false
  end if
End Function


Function onPinErrorChange(msg)
  if msg.getData() = true
    if m.top.errorCode = 429 'speical case for failed too many times
      m.errorMessage.text = getTranslation("parental_pin_failed_too_many_times_error_message")
    else
      m.errorMessage.text = getTranslation("screenSettings_parentalPassword_error_pin_mismatch")
    end if

    showPinErrorMessage(true)
  end if
End Function


Function showPinErrorMessage(pinError)
  if pinError = true
    m.errorMessage.visible = true
  else
    m.errorMessage.visible = false
  end if
  clearNumberPad()

End Function


Function onMultiPurposeButtonSelected(msg)
  isButtonSelected = msg.getRoSGNode()

  if isButtonSelected <> invalid AND isButtonSelected.id = "multiPurposeButton"
    if isButtonSelected.text = getTranslation("ParentalControlPinInputScreen_skip_button_label")
      onSkipButtonSelected(msg)
    else if isButtonSelected.text = getTranslation("ParentalControlPinInputScreen_forgot_pin_button_label")
      m.top.forgotPinSelected = true
    end if
  end if
End Function


Function onSkipButtonSelected(msg)

  isButtonSelected = msg.getData()
  if isButtonSelected = true
    pinSubmitted = ""
    setPinSubmitted(pinSubmitted)
  end if

End Function
