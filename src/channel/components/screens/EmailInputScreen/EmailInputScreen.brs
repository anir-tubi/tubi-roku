Function init()
  m.constants = m.global.constants
  m.theme = m.global.theme

  m.top.observeField("focusedChild", "onScreenFocusChange")

  m.pageHeading = m.top.findNode("pageHeading")
  m.pageHeading.text = getTranslation("email_screen_heading")

  m.emailValidationMsg = m.top.findNode("emailValidationMsg")
  m.emailValidationMsg.text = getTranslation("invalid_email_title")

  m.email = m.top.findNode("email")

  m.keyboard = m.top.findNode("Keyboard")

  m.Keyboard.textEditBox.voiceEnabled = true
  m.keyboard.domain = "email"
  m.keyboard.textEditBox.visible = false
  m.Keyboard.textEditBox.maxTextLength = 100
  
  m.keyboard.observeFieldScoped("text", "onKeyboardTextChanged")

  m.keyboard.palette = handleKeyboardColors()

  m.back = m.top.findNode("back")
  m.back.text = getTranslation("linearVideoPlayer_buttonBack")

  m.continue = m.top.findNode("continue")
  m.continue.text = getTranslation("dialog_button_continue")
  m.continue.observeFieldScoped("selected", "onContinueButtonSelected")

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

  m.backgroundUriList = [m.constants.ui.uris.marketingBackground]

End Function


Function onScreenFocusChange()

  tubiLog("EmailInputScreen.onScreenFocusChange")
  if m.top.hasFocus() then
    ' force a background update
    m.Keyboard.textEditBox.voiceEnabled = true
    m.top.backgroundUriList = m.backgroundUriList
    m.keyboard.keyGrid.setFocus(true)
  end if
  if m.top.isInFocusChain() = false
    m.keyboard.unobserveFieldScoped("text")
    m.Keyboard.textEditBox.voiceEnabled = false
  end if

End Function


Function onKeyboardTextChanged()
  m.email.text = m.keyboard.text
End Function


'Handling when app is focusing on an invisible textbox that is built into the keyboard
Function onTextEditBoxFocused()
  m.Keyboard.setFocus(true)
End Function


' onContinueButtonSelected callback triggers when user selects continue button
Function onContinueButtonSelected(evt)

  isButtonSelected = evt.getData()
  if isButtonSelected = true
    if isEmailValid() = true
      fade(m.emailValidationMsg, "out", 0.3)
      m.top.email = m.email.text
      m.top.continueSelected = true
    else
      fade(m.emailValidationMsg, "in", 0.3)
    end if
  end if

End Function


Function isEmailValid()

  isValid = false
  email = m.email.text
  emailPattern = CreateObject("roRegex", "[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}", "i")
  if emailPattern.IsMatch(email)
    isValid = true
  end if
  return isValid

End Function


Function onKeyEvent(key As String, press As Boolean) as Boolean

  if key = "OK"
    m.email.text = m.keyboard.text
  end if

  handled = true
  if press

    if key = "back"
      m.top.backButtonSelected = true

    else if key = "down"

      if m.keyboard.isInFocusChain() = true
        m.continue.setFocus(true)
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
      end if

    else if key = "left"

      if m.continue.hasFocus() = true
        m.back.setFocus(true)
      end if

    end if
    return handled
  end if

End Function
