Function init()
  m.constants = getConstantsFromGlobal()

  m.top.observeFieldScoped("focusedChild", "onScreenFocusChange")
  m.top.observeFieldScoped("isEmailValid", "onIsEmailValidChange")

  m.pageHeading = m.top.findNode("pageHeading")
  m.pageHeading.text = getTranslation("email_screen_heading")

  m.emailTextEditBox = m.top.findNode("emailTextEditBox")
  m.emailTextEditBox.maxTextLength = 100

  m.emailValidationMsg = m.top.findNode("emailValidationMsg")
  m.emailValidationMsg.text = getTranslation("invalid_email_title")

  readAudioGuideText(m.pageHeading.text)

  m.keyboard = m.top.findNode("Keyboard")
  m.keyboard.textEditBox.opacity = 0.00001
  m.keyboard.textEditBox.maxTextLength = 100
  m.keyboard.domain = "email"

  'This will save the last focused key of the keyboard used to enable the roku default audioguide after screen components read.
  m.keyFocused = ""

  'This will disable the default roku screen reader for customKeyboard to read screen heading which are not read by roku default screen reader.
  m.keyboard.muteAudioGuide = true
  m.keyboard.observeFieldScoped("keyGrid", "onKeyGridChange")

  m.keyboard.palette = handleKeyboardColors()

  m.back = m.top.findNode("back")
  m.back.text = getTranslation("linearVideoPlayer_buttonBack")

  m.continue = m.top.findNode("continue")
  m.continue.text = getTranslation("dialog_button_continue")
  m.continue.observeFieldScoped("selected", "onContinueButtonSelected")

  m.privacyDisclaimer = m.top.findNode("privacyDisclaimer")
  externalConfig = m.constants.externalConfig.info
  params = {
    "privacy_policy_url": externalConfig.privacy_policy_url,
    "terms_of_use_url": externalConfig.terms_of_use_url
  }
  m.privacyDisclaimer.text = getTranslation("privacy_disclaimer", params)

  m.keyboard.textEditBox.observeFieldScoped("focusedChild", "onKeyboardTextEditBoxFocusedChildChange")

  m.keyboard.textEditBox.observeFieldScoped("cursorPosition", "onKeyboardTextEditBoxCursorPositionChange")

  m.top.instantResumeAction = m.constants.instantResumeActions.startChannel

  'set initial tracking values
  m.top.trackingPageInfo = {
    pageType: "register_page"
    pageValues: {
      auth_method: "EMAIL"
    }
  }

  m.top.isStackable = true
  m.top.screenLevel = m.constants.ui.screenLevels.emailInputScreen

  m.backgroundUriList = []

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.pageHeading, typographyConstants.ids.headerLarge)
  setTypographyOfLabel(m.emailValidationMsg, typographyConstants.ids.bodySmallStrong)
  setTypographyOfLabel(m.privacyDisclaimer, typographyConstants.ids.bodySmall)

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
    m.back.color = theme.backgroundColorLight
    m.continue.color = theme.backgroundColorLight
    m.emailValidationMsg.color = theme.cautionColor
    m.pageHeading.color = theme.primaryTextColor

    paletteColors = m.keyboard.palette.colors
    paletteColors.FocusItemColor = theme.focusedTextColor
    paletteColors.FocusColor = theme.focusedColor
    m.keyboard.palette.colors = paletteColors

    m.privacyDisclaimer.color = theme.secondaryTextColor
  end if
End Function


Function onScreenFocusChange()
  tubiLog("EmailInputScreen.onScreenFocusChange")
  if m.top.hasFocus() then
    m.emailTextEditBox.active = true
    m.keyboard.unobserveFieldScoped("text")
    m.keyboard.observeFieldScoped("text", "onKeyboardTextChanged")

    ' force a background update
    m.top.backgroundUriList = m.backgroundUriList

    m.Keyboard.textEditBox.voiceEnabled = true
    m.keyboard.keyGrid.setFocus(true)
  end if

  if m.top.isInFocusChain() = false
    m.emailTextEditBox.active = false
    m.keyboard.unobserveFieldScoped("text")
    m.Keyboard.textEditBox.voiceEnabled = false
  end if
End Function


'This function is to read the first focused keys in the keyboard as we disable the default screen reader for keyboard initially
'to read the screen components and later we enable roku default screen reader for keyboard.
'NOTE: hardcoded values are to match the default keyboard.
Function onKeyGridChange(msg)
  keyGrid = msg.getData()
  if isNonEmptyString(m.keyFocused) = true AND m.keyboard.muteAudioGuide = true

    if keyGrid.keyFocused = "a"
      audioGuideText = keyGrid.keyFocused + " " + "alpha"
    else
      audioGuideText = keyGrid.keyFocused + " " + m.constants.audioGuideHints.buttonHint
    end if

    readAudioGuideText(audioGuideText, false)

    'This is to read the screen text and suspend the kepboard default audio guide until focus moved to next key.
    if m.keyFocused <> keyGrid.keyFocused
      m.keyboard.muteAudioGuide = false
      m.keyboard.unObserveFieldScoped("keyGrid")
    end if
  end if

  m.keyFocused = keyGrid.keyFocused
End Function


Function onKeyboardTextEditBoxFocusedChildChange()
  tubiLog("EmailInputScreen.onKeyboardTextEditBoxFocusedChildChange")
  ' Don't allow textEditBox to take focus since we're not showing it
  if m.keyboard.textEditBox.hasFocus()
    m.keyboard.keyGrid.setFocus(true)
  end if
End Function


Function onKeyboardTextEditBoxCursorPositionChange(msg)
  m.emailTextEditBox.cursorPosition = msg.getData()
End Function


Function onKeyboardTextChanged()
  m.emailTextEditBox.text = m.keyboard.text
End Function


'Handling when app is focusing on an invisible textbox that is built into the keyboard
Function onTextEditBoxFocused()
  m.Keyboard.setFocus(true)
End Function


' onContinueButtonSelected callback triggers when user selects continue button
Function onContinueButtonSelected(evt)

  isButtonSelected = evt.getData()
  if isButtonSelected = true
    m.top.email = m.emailTextEditBox.text
    ' we must set voiceEnabled = false here because if we rely on isInFocusChain() in
    ' onScreenFocusChange(), voiceEnabled is not set to false until after voiceEnabled is set to true
    ' on the SignInScreen, which prevents voiceEnabled is getting to true
    ' on the SignInScreen.
    m.keyboard.textEditBox.voiceEnabled = false
    m.top.continueSelected = true
  end if
End Function


Function onIsEmailValidChange(msg)
  isEmailValid = msg.getData()

  if isEmailValid = true
    fade(m.emailValidationMsg, "out", 0.3)
  else
    fade(m.emailValidationMsg, "in", 0.3)
  end if
End Function


Function onKeyEvent(key As String, press As Boolean) as Boolean

  if key = "OK"
    m.emailTextEditBox.text = m.keyboard.text
  end if

  handled = true
  if press = false then
    return false
  else
    if key = "back"
      m.top.backButtonSelected = true

    else if key = "down"
      if m.keyboard.isInFocusChain() = true
        m.continue.setFocus(true)
        readAudioGuideText(m.continue.text)
      end if

    else if key = "up"

      if m.continue.hasFocus() = true
        m.keyboard.setFocus(true)
      else if m.back.hasFocus() = true
        m.keyboard.setFocus(true)
      end if

    else if key = "right"

      if m.back.hasFocus() = true
        m.continue.setFocus(true)
        readAudioGuideText(m.continue.text)
      end if

    else if key = "left"
      if m.continue.hasFocus() = true
        m.back.setFocus(true)
        readAudioGuideText(m.back.text)
      end if

    end if
    return handled
  end if

End Function
