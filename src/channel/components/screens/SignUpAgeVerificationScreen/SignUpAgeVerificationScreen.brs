Function init()
  m.constants = getConstantsFromGlobal()
  m.Header = m.top.findNode("AgeVerificationPageHeader")
  m.SubHeader = m.top.findNode("AgeVerificationPageSubHeader")
  m.NumberPad = m.top.findNode("AgeVerificationNumberpad")
  m.StartButton = m.top.findNode("AgeVerificationStartButton")
  m.AgePrefixLabel = m.top.findNode("AgeVerificationAgePrefixLabel")
  m.AgePostfixLabel = m.top.findNode("AgeVerificationAgePostfixLabel")
  m.AgeEntry = m.top.findNode("AgeVerificationAgeEntry")
  m.AgeBackground = m.top.findNode("AgeVerificationAgeBg")
  m.ErrorPrompt = m.top.findNode("AgeVerificationErrorPrompt")
  m.AgeWarningPrompt = m.top.findNode("AgeWarningPrompt")
  m.AgeErrorPrompt = m.top.findNode("AgeErrorPrompt")
  m.infoLabel = m.top.findNode("AgeVerificationInfoLabel")

  m.Header.text = getTranslation("screenAgeVerification_header")
  m.StartButton.text = getTranslation("screenAgeVerification_keypad_button")
  m.ErrorPrompt.text = getTranslation("screenAgeVerification_error_prompt")
  m.AgeWarningPrompt.text = getTranslation("screenAgeVerification_warning_prompt")
  m.AgeErrorPrompt.text = getTranslation("screenSignUpAgeVerification_error_prompt_age")
  m.AgePrefixLabel.text = getTranslation("screenSignUpAgeVerification_request_age_prefix")
  m.AgePostfixLabel.text = getTranslation("screenSignUpAgeVerification_request_age_postfix")
  m.infoLabel.text = getTranslation("why_ask_age_description")

  m.SubHeader.text = getTranslation("screenSignUpAgeVerification_sub_header_age")

  ' m.warningDisplayedCount helps to track how many time warning message is displayed when user enters age
  m.warningDisplayedCount = 0

  m.top.trackingPageInfo = {
    pageType: "age_gate_page"
    pageValues: {}
  }

  m.top.screenLevel = m.constants.ui.screenLevels.ageGateScreen


  m.ErrorPrompt.color = m.constants.ui.colors.caution
  m.AgeErrorPrompt.color = m.constants.ui.colors.caution
  m.AgeWarningPrompt.color = m.constants.ui.colors.caution
  m.infoLabel.color = m.constants.ui.colors.primaryText
  m.Header.color = m.constants.ui.colors.primaryText
  m.AgePrefixLabel.color = m.constants.ui.colors.primaryText
  m.AgePostfixLabel.color = m.constants.ui.colors.primaryText
  m.SubHeader.color = m.constants.ui.colors.secondaryText
  m.StartButton.color = m.constants.ui.colors.backgroundColorLight2
  m.AgeEntry.color = m.constants.ui.colors.textDark

  m.backgroundUriList = [m.constants.ui.uris.marketingBackground]

  m.top.observeFieldScoped("focusedChild", "onComponentFocusChanged")
  m.NumberPad.observeFieldScoped("text", "onNumberPadTextChanged")
  m.StartButton.observeFieldScoped("selected", "onStartButtonSelected")
End Function


Function onComponentFocusChanged()
  if m.top.hasFocus()
    ' force a background update
    m.top.backgroundUriList = m.backgroundUriList
    m.NumberPad.setFocus(true)
  end if
End Function


Function onNumberPadTextChanged(msg)
  text = msg.getData()
  ' We don't handle our checks until a user actually clicks start watching just update the onscreen text
  ' Only allow a max of 3 digits
  if text.len() > 3 then
    text = text.left(3)
    ' Have to also set the numberpad to prevent getting out of sync
    m.NumberPad.text = text
  end if

  m.AgeEntry.text = text

End Function

' @year: String - year we are saying the user was born in
Function updateBirthdate(year)
  m.top.birthdate = year + "-12-31"  ' since backend expects birthday in date format(YYYY-MM-DD), we are appending dummy month & day
End Function


Function onStartButtonSelected()
  shouldSubmitAge = false
  age = m.NumberPad.text.toInt()
  ageLength = m.NumberPad.text.len()
  m.AgeEntry.text = m.NumberPad.text

  m.AgeErrorPrompt.visible = false
  m.AgeWarningPrompt.visible = false
  if age <= 1 then
    if ageLength > 0 then
      m.AgeErrorPrompt.visible = true
      m.NumberPad.setFocus(true)
      m.NumberPad.moveFocusToDelete = true
    end if
  else if age <= 4 AND m.warningDisplayedCount = 0 then
    m.AgeWarningPrompt.visible = true
    m.warningDisplayedCount += 1
    m.NumberPad.setFocus(true)
    m.NumberPad.moveFocusToDelete = true
  else if age > 125 then
    m.AgeErrorPrompt.visible = true
    m.NumberPad.setFocus(true)
    m.NumberPad.moveFocusToDelete = true
  else
    ' We have to remove one or someone who is 13 would be considered 12 other than the last day of the year
    year = getCurrentYear() - age - 1
    updateBirthdate(year.toStr())
    shouldSubmitAge = true
  end if

  if shouldSubmitAge = true then
    ' Want to reset the numberpad text on submit as the only time they will be coming back is if they were confirming their age and likely need to change it
    m.NumberPad.text = ""
    m.top.ageSubmitted = true
  end if
End Function


' @key: string, the name of the key pressed, as defined by Roku
' @press: boolean, true for press down event, false for key release event
Function onKeyEvent(key, press) as Boolean
  if press = true
    if key = "back"
      m.top.backButtonPressed = true
    else
      if key = "down"
        if m.NumberPad.text.isEmpty() = false then
          m.StartButton.setFocus(true)
        end if
      else if key = "up"
        if m.StartButton.isInFocusChain() = true
          m.NumberPad.setFocus(true)
        end if
      end if
    end if
  end if

  return true
End Function
