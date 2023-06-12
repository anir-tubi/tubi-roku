Function init()
  m.constants = getConstantsFromGlobal()

  m.password = m.top.findNode("password")
  m.password.hint = getTranslation("signIn_password_hint")

  m.top.observeField("focusedChild", "onScreenFocusChange")

  m.keyboard = m.top.findNode("passwordEntryKeyboard")
  m.keyboard.observeFieldScoped("buttonSelected", "onButtonSelected")

  'This field is used to know whether screen componenets are read or not before the focused keyboard keys started announcing.
  m.isScreenAudioGuideRead = false

  m.keyboard.observeFieldScoped("audioGuideText", "onAudioGuideTextChanged")

  'set initial tracking values
  m.top.trackingPageInfo = {
    pageType: "auth_page"
    pageValues: {
      auth_action: "PASSWORD_CONFIRMATION"
    }
  }

  m.top.screenLevel = m.constants.ui.screenLevels.confirmPasswordScreen
  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    m.theme  = msg.getData()
  else
    m.theme  = getThemeFromGlobal()
  end if
  
  setPasswordColor()
End Function


Function setPasswordColor()
  if m.theme <> invalid
    if isNonEmptyString(m.password.text) = true
      m.password.color = m.theme.primaryTextColor
    else
      '//if the textbox contains no user entered password and is revealing the hint text, then display text in a different color than the normal default color
      m.password.color = m.theme.backgroundColorLight2
    end if
  end if
End Function


''''''''''''''''''''''
' onScreenFocusChange
' Set focus and apply form element colors
Function onScreenFocusChange()
  tubiLog("ConfirmPasswordScreen.onScreenFocusChange")
  if m.top.hasFocus()
    ' force a background update
    m.keyboard.observeFieldScoped("text", "onKeyboardTextChanged")
    m.top.backgroundUriList = m.backgroundUriList

    m.keyboard.setFocus(true)
    m.keyboard.voiceEnabled = true
    if m.constants.settings.mode <> "production" and m.constants.settings.password <> invalid
      m.keyboard.text = m.constants.settings.password
      m.password.text = m.constants.settings.password
    end if
  end if
  
  if m.top.isInFocusChain() = false
    m.keyboard.voiceEnabled = false
    m.keyboard.unobserveFieldScoped("text")
  end if
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
    m.top.submitSelected = true
  else if buttonSelected = "back"
    m.top.backPressed = true
  else if buttonSelected = "up"
    'DO nothing
  end if
End Function


Function onKeyEvent(key As String, press As Boolean) As Boolean
  tubiLog("ConfirmPasswordScreen.onKeyEvent")
  if key = "OK"
    m.password.text = m.keyboard.text
    setPasswordColor()
  else if key = "back"
    m.top.backPressed = true
  end if
  return press
End Function


Function onKeyboardTextChanged()
  tubiLog("ConfirmPasswordScreen.onKeyboardTextChanged")
  m.password.text = m.keyboard.text
  setPasswordColor()
End Function


Function onAudioGuideTextChanged(msg)
  audioGuideText = msg.getData()
  if isNonEmptyString(audioGuideText) = true

    if m.isScreenAudioGuideRead = false
      message = getTranslation("screenSettings_parentalPassword_title")
      subMessage = getTranslation("screenSettings_parentalPassword_subtitle")
      setUp = getTranslation("screenSettings_parentalPassword_setup_new_password") + ","
      visit = getTranslation("screenSettings_parentalPassword_visit_link")

      screenAudioGuideText = message + "" + subMessage + " " + setUp + " " + visit
      audioGuideText = screenAudioGuideText + audioGuideText
      m.isScreenAudioGuideRead = true
    end if

    readAudioGuideText(audioGuideText)
  end if
End Function
