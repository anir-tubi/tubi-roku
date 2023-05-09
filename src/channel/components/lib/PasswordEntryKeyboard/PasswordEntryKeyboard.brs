Function init()
  m.constants = m.global.constants
  theme = getThemeFromGlobal()
  m.passwordMode = true
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


Function onKeyEvent(key As String, press As Boolean) as Boolean
  handled = true
  if press

    if key = "down"
      if m.keyboard.isInFocusChain() = true
        sPreviouslyFocusedKey = m.keyboard.focusedChild.keyFocused
        if sPreviouslyFocusedKey <> invalid AND m.aLeftLowerKeys[sPreviouslyFocusedKey] = true
          '//if the key focus is on the lower left of the keyboard, then set focus on the back button
          m.back.setFocus(true)
        else if sPreviouslyFocusedKey <> invalid AND m.aRightLowerKeys[sPreviouslyFocusedKey] = true
          '//if the key focus is on the lower right of the keyboard, then set focus on the showHidePassword button
          m.showHidePassword.setFocus(true)
        else
          m.continue.setFocus(true)
        end if
      end if

    else if key = "up"
      if m.continue.hasFocus() = true
        m.keyboard.setFocus(true)
      else if m.showHidePassword.hasFocus() = true
        m.keyboard.setFocus(true)
      else if m.back.hasFocus() = true
        m.keyboard.setFocus(true)
      else if m.top.isInFocusChain() = true
        m.top.buttonSelected = "up"
      end if

    else if key = "right"

      if m.back.hasFocus() = true
        m.continue.setFocus(true)
      else if m.continue.hasFocus() = true
        m.showHidePassword.setFocus(true)
      end if

    else if key = "left"

      if m.continue.hasFocus() = true
        m.back.setFocus(true)
      else if m.showHidePassword.hasFocus() = true
        m.continue.setFocus(true)
      end if
    else if key = "back"
        handled = false
    end if

    return handled
  end if
  return false
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
  if m.top.hasFocus()
    m.keyboard.keyGrid.setFocus(true)
  end if
End Function


Function onVoiceEnabledChange(msg)
  m.keyboard.textEditBox.voiceEnabled = msg.getData()
End Function