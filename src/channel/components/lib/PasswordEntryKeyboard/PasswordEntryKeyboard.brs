Function init()
  m.constants = getConstantsFromGlobal()
  theme = getThemeFromGlobal()
  m.passwordMode = true
  m.focusDelayTimer = m.top.findNode("focusDelayTimer")
  m.focusDelayTimer.observeFieldScoped("fire", "onFocusDelayTimerFired")

  m.back = m.top.findNode("back")
  m.back.text = getTranslation("linearVideoPlayer_buttonBack")
  m.back.observeFieldScoped("selected", "onButtonSelected")

  m.showHidePassword = m.top.findNode("showHidePassword")
  m.showHidePassword.text = getTranslation("screenSettings_parentalPassword_button_show")
  m.showHidePassword.observeFieldScoped("selected", "onButtonSelected")

  m.continue = m.top.findNode("continue")
  m.continue.text = getTranslation("dialog_button_continue")
  m.continue.observeFieldScoped("selected", "onButtonSelected")

  m.keyboard = m.top.findNode("Keyboard")
  m.keyboard.domain = "password"
  m.keyboard.textEditBox.opacity = 0.00001
  m.keyboard.palette = handleKeyboardColors()

  m.keyboard.observeFieldScoped("keyGrid", "onKeyGridChange")

  'This will save the last focused key of the keyboard used to enable the roku default audioguide after screen components read.
  m.keyFocused = ""

  '//Keep a record of keys that are on the lower line of the left side of the keyboard
  m.aLeftLowerKeys = {}
  m.aLeftLowerKeys["left"] =  true
  m.aLeftLowerKeys["right"] =  true

  '//Keep a record of keys that are on the lower line of the right side of the keyboard
  m.aRightLowerKeys = {}
  m.aRightLowerKeys["@"] =  true
  m.aRightLowerKeys["."] =  true
  m.aRightLowerKeys["0"] =  true
  m.aRightLowerKeys["accents"] =  true
  m.aRightLowerKeys["÷"] =  true
  m.aRightLowerKeys["±"] =  true
  m.aRightLowerKeys["–"] =  true
  m.aRightLowerKeys["—"] =  true
  m.aRightLowerKeys["‚"] =  true
  m.aRightLowerKeys["‰"] =  true
  m.aRightLowerKeys["ß"] =  true
  m.aRightLowerKeys["þ"] =  true
  m.aRightLowerKeys["Ž"] =  true
  m.aRightLowerKeys["Ð"] =  true
  m.aRightLowerKeys["Þ"] =  true

  m.top.observeFieldScoped("focusedChild", "onScreenFocusChange")
  m.top.observeFieldScoped("voiceEnabled", "onVoiceEnabledChange")
  m.keyboard.textEditBox.observeFieldScoped("focusedChild", "onTextEditBoxFocusedChildChange")

  if theme <> invalid
    m.back.color = theme.backgroundColorLight
    m.continue.color = theme.backgroundColorLight
    m.showHidePassword.color = theme.backgroundColorLight
  end if
End Function


Function onButtonSelected(evt)
  buttonSelected = evt.getRoSGNode()
  if buttonSelected.id = "showHidePassword"
      if m.passwordMode = true
          m.showHidePassword.text = getTranslation("screenSettings_parentalPassword_button_hide")
          m.passwordMode = false
        else
          m.showHidePassword.text = getTranslation("screenSettings_parentalPassword_button_show")
          m.passwordMode = true
        end if

        m.top.audioGuideText = m.showHidePassword.text
  end if

  m.top.buttonSelected = buttonSelected.id
End Function


Function onTextEditBoxFocusedChildChange()
  ' Don't allow textEditBox to take focus since we're not showing it
  if m.keyboard.textEditBox.hasFocus() = true
    m.keyboard.keyGrid.setFocus(true)
  end if
End Function


Function onScreenFocusChange()
  if m.top.hasFocus() = true

    'We are enabling and disabling the ROKU default audio guide for keyboard based on whether the
    'keyboard is focused when the screen gains focus.
    if m.top.shouldMuteAudioGuideWhenFocused = true
      m.keyboard.muteAudioGuide = false
    else
      m.keyboard.muteAudioGuide = true
    end if

    m.keyboard.keyGrid.setFocus(true)
  end if
End Function


Function onVoiceEnabledChange(msg)
  m.keyboard.textEditBox.voiceEnabled = msg.getData()
End Function


'//When the timer is called, it means the user pressed the DOWN button. There should be slight delay in determining which 
'// button to go to next since there the keyboard has a slight delay in determining the key focus.
Function onFocusDelayTimerFired()
  if m.keyboard.isInFocusChain() = true
    sPreviouslyFocusedKey = m.keyboard.focusedChild.keyFocused
    if sPreviouslyFocusedKey <> invalid AND m.aLeftLowerKeys[sPreviouslyFocusedKey] = true
      '//if the key focus is on the lower left of the keyboard, then set focus on the back button
      setFocusToComponent(m.back)
    else if sPreviouslyFocusedKey <> invalid AND m.aRightLowerKeys[sPreviouslyFocusedKey] = true
      '//if the key focus is on the lower right of the keyboard, then set focus on the showHidePassword button
      setFocusToComponent(m.showHidePassword)
    else
      setFocusToComponent(m.continue)
    end if
  end if
End Function


Function onKeyEvent(key As String, press As Boolean) as Boolean
  handled = true
  if press
    m.focusDelayTimer.control = "stop"  '//whenever the key is pressed, then cancel the timer

    if key = "down"
      if m.keyboard.isInFocusChain() = true
        m.focusDelayTimer.control = "start"  '//cause a slight delay to determine where to go next since there is a slight delay for the keyboard to know which keyboard button is in focus
      end if

    else if key = "up"
      if m.continue.hasFocus() = true
        setFocusToComponent(m.keyboard)
      else if m.showHidePassword.hasFocus() = true
        setFocusToComponent(m.keyboard)
      else if m.back.hasFocus() = true
        setFocusToComponent(m.keyboard)
      else if m.top.isInFocusChain() = true
        m.top.buttonSelected = "up"
      end if

    else if key = "right"

      if m.back.hasFocus() = true
        setFocusToComponent(m.continue)
      else if m.continue.hasFocus() = true
        setFocusToComponent(m.showHidePassword)
      end if

    else if key = "left"

      if m.continue.hasFocus() = true
        setFocusToComponent(m.back)
      else if m.showHidePassword.hasFocus() = true
        setFocusToComponent(m.continue)
      end if
    else if key = "back"
        handled = false
    end if

    return handled
  end if
  return false
End Function


Function setFocusToComponent(focusTarget)
  if focusTarget <> invalid

    if focusTarget.id = m.keyboard.id
      'This will enable the default roku screen reader to read the focused keys in keyboard.
      m.keyboard.muteAudioGuide = false
      m.top.audioGuideText = ""
    else
      'This will disable the default roku screen reader to read the components which are not read by roku default screen reader.
      m.keyboard.muteAudioGuide = true
      m.top.audioGuideText = focusTarget.text
    end if
    
    focusTarget.setFocus(true)
  end if
End Function


'This function is to read the first focused keys in the keyboard as we disable the default screen reader for keyboard initially
'to read the screen components and later we enable roku default screen reader for keyboard and this is not required for some screens
'as keyboard gains focus only when we press ok on password field.
Function onKeyGridChange(msg)
  keyGrid = msg.getData()

  if isNonEmptyString(m.keyFocused) = true AND m.top.shouldMuteAudioGuideWhenFocused = false
    audioGuideText = ""
    if keyGrid.keyFocused = "a"
      audioGuideText = keyGrid.keyFocused + " " + "alpha"
    else
      audioGuideText = keyGrid.keyFocused +  " " + m.constants.audioGuideHints.buttonHint
    end if

    m.top.audioGuideText = audioGuideText

    'This is to read the screen text and suspend the kepboard default audio guide until focus moved to next key.
    if m.keyFocused <> keyGrid.keyFocused
      m.keyboard.muteAudioGuide = false
      m.keyboard.unObserveFieldScoped("keyGrid")
    end if
  end if

  m.keyFocused = keyGrid.keyFocused
End Function
