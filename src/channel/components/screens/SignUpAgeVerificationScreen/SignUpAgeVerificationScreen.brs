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

  m.backgroundUriList = [m.constants.ui.uris.marketingBackground]

  m.top.observeFieldScoped("focusedChild", "onComponentFocusChanged")
  m.NumberPad.observeFieldScoped("text", "onNumberPadTextChanged")
  m.NumberPad.observeFieldScoped("audioGuideText", "onAudioGuideTextChanged")
  m.StartButton.observeFieldScoped("selected", "onStartButtonSelected")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.Header, typographyConstants.ids.headerMedium)
  setTypographyOfLabel(m.SubHeader, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.AgePrefixLabel, typographyConstants.ids.headerLarge)
  setTypographyOfLabel(m.AgeEntry, typographyConstants.ids.headerLarge)
  setTypographyOfLabel(m.AgePostfixLabel, typographyConstants.ids.headerLarge)
  setTypographyOfLabel(m.ErrorPrompt, typographyConstants.ids.bodySmall)
  setTypographyOfLabel(m.infoLabel, typographyConstants.ids.bodySmall)

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
    m.ErrorPrompt.color = theme.cautionColor
    m.AgeErrorPrompt.color = theme.cautionColor
    m.AgeWarningPrompt.color = theme.cautionColor
    m.infoLabel.color = theme.primaryTextColor
    m.Header.color = theme.primaryTextColor
    m.AgePrefixLabel.color = theme.primaryTextColor
    m.AgePostfixLabel.color = theme.primaryTextColor
    m.SubHeader.color = theme.secondaryTextColor
    m.StartButton.color = theme.backgroundColorLight2
    m.AgeEntry.color = theme.textDarkColor
  end if
End Function


Function onComponentFocusChanged()
  if m.top.hasFocus()
    ' force a background update
    audioGuideText = m.Header.text + " " + m.SubHeader.text + " " + m.infoLabel.text
    readAudioGuideText(audioGuideText)
    m.top.backgroundUriList = m.backgroundUriList
    m.NumberPad.setFocus(true)
  end if
End Function


Function onNumberPadTextChanged(msg)
  text = msg.getData()
  age = text.toInt()

  m.AgeErrorPrompt.visible = false
  if text = "0" then
    m.AgeErrorPrompt.visible = true
    text = ""
  else if age > 125
    m.AgeErrorPrompt.visible = true
    text = text.left(text.len() - 1)
  end if

' Have to also set the numberpad to prevent getting out of sync
  m.NumberPad.text = text
  m.AgeEntry.text = text
  readAudioGuideText(text)
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
          readAudioGuideText(m.StartButton.text)
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


Function onAudioGuideTextChanged(msg)
  audioGuideText = msg.getData()
  if isNonEmptyString(audioGuideText) = true
    readAudioGuideText(audioGuideText)
  end if
End Function
