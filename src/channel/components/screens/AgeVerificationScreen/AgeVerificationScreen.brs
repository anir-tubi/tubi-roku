Function init()
  m.constants = getConstantsFromGlobal()
  m.Header = m.top.findNode("AgeVerificationPageHeader")
  m.SubHeader = m.top.findNode("AgeVerificationPageSubHeader")
  m.NumberPad = m.top.findNode("AgeVerificationNumberpad")
  m.StartButton = m.top.findNode("AgeVerificationStartButton")
  m.DateInfo = m.top.findNode("AgeVerificationDateInfo")
  m.YearEntryFront = m.top.findNode("AgeVerificationYearEntryFront")
  m.YearEntryBack = m.top.findNode("AgeVerificationYearEntryBack")
  m.YearBackground = m.top.findNode("AgeVerificationYearBg")
  m.YearLabel = m.top.findNode("AgeVerificationYear")
  m.Prompt = m.top.findNode("AgeVerificationErrorPrompt")
  m.bornYear = m.top.findNode("AgeVerificationYearText")
  m.infoLabel = m.top.findNode("AgeVerificationInfoLabel")

  m.Header.text = getTranslation("screenAgeVerification_header")
  m.SubHeader.text = getTranslation("screenAgeVerification_sub_header")
  m.StartButton.text = getTranslation("screenAgeVerification_keypad_button")
  m.YearEntryFront.text = getTranslation("screenAgeVerification_yyyy")
  m.YearEntryBack.text = getTranslation("screenAgeVerification_yyyy")
  m.YearLabel.text = getTranslation("screenAgeVerification_year")
  m.Prompt.text = getTranslation("screenAgeVerification_error_prompt")
  m.bornYear.text = getTranslation("screenAgeVerification_born_year")
  m.infoLabel.text = getTranslation("why_ask_age_description")

  m.yearLetter = m.YearEntryFront.text.Left(1)

  ' m.warningDisplayedCount helps to track how many time warning message is displayed when user enters year of birth
  m.warningDisplayedCount = 0

  m.top.trackingPageInfo = {
    pageType: "age_gate_page"
    pageValues: {}
  }

  m.top.screenLevel = m.constants.ui.screenLevels.ageGateScreen

  m.top.observeField("focusedChild", "onComponentFocusChanged")
  m.NumberPad.observeField("text", "onNumberPadTextChanged")
  m.NumberPad.observeField("audioGuideText", "onAudioGuideTextChanged")
  m.top.observeFieldScoped("ageSubmitted", "onAgeSubmittedChanged")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.Header, typographyConstants.ids.headerMedium)
  setTypographyOfLabel(m.SubHeader, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.bornYear, typographyConstants.ids.headerMedium)
  setTypographyOfLabel(m.YearEntryBack, typographyConstants.ids.headerLarge)
  setTypographyOfLabel(m.YearEntryFront, typographyConstants.ids.headerLarge)
  setTypographyOfLabel(m.YearLabel, typographyConstants.ids.bodyMedium)
  setTypographyOfLabel(m.Prompt, typographyConstants.ids.bodySmall)
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
    m.SubHeader.color = theme.secondaryTextColor
    m.Header.color = theme.primaryTextColor
    m.bornYear.color = theme.primaryTextColor
    m.YearEntryBack.color = theme.secondaryTextColor
    m.StartButton.color = theme.backgroundColorLight2
    m.Header.color = theme.primaryTextColor
    
    m.YearLabel.color = theme.primaryTextColor
    m.infoLabel.color = theme.primaryTextColor
    m.YearEntryFront.color = theme.textDarkColor
    m.YearEntryBack.color = theme.textDarkColor
    m.Prompt.color = theme.focused2Color
  end if
End Function


Function onComponentFocusChanged()
  if m.top.hasFocus()
    ' force a background update
    audioGuideText = m.Header.text + m.SubHeader.text
    readAudioGuideText(audioGuideText)
    m.top.backgroundUriList = []
    m.NumberPad.setFocus(true)
  end if
End Function


Function onNumberPadTextChanged(msg)
  date = msg.getData()
  millennium = date.left(1).toInt()
  century = date.mid(1, 1).toInt()
  decade = date.mid(2, 1).toInt()
  dateLength = date.len()

  if dateLength = 1 AND millennium <> 1 AND millennium <> 2
    m.Prompt.visible = true
    m.NumberPad.text = ""
  else if dateLength = 2 AND millennium = 1 AND century <> 9
    ' don't allow centuries that are not 19xx if millennium is 1xxx
    m.Prompt.visible = true
    m.NumberPad.text = date.left(1)
    readAudioGuideText(m.NumberPad.text)
  else if dateLength = 2 AND millennium = 2 AND checkValidCentury(millennium, century) = false
    ' don't allow centuries greater than the current century if millennium is 2xxx
    m.Prompt.visible = true
    m.NumberPad.text = date.left(1)
    readAudioGuideText(m.NumberPad.text)
  else if dateLength = 3 AND millennium = 2 AND checkValidDecade(century, decade) = false
    ' don't allow decades greater than the current decade if millennium is 2xxx
    m.Prompt.visible = true
    m.NumberPad.text = date.left(2)
    readAudioGuideText(m.NumberPad.text)
  else if dateLength = 4 AND checkValidYear(date) = false
    ' don't allow future years/month/dates
    m.Prompt.visible = true
    m.NumberPad.text = date.left(3)
    readAudioGuideText(m.NumberPad.text)
  else
    m.Prompt.visible = false
    if dateLength = 4
      m.NumberPad.moveFocusToDelete = true
      m.top.birthdate = date + "-12-31"  ' since backend expects birthday in date format(YYYY-MM-DD), we are appending dummy month & day

      currentYear = createObject("roDateTime").getYear()
      if isUserToddler(date, currentYear) = true AND m.warningDisplayedCount = 0
        m.Prompt.text = getTranslation("screenAgeVerification_warning_prompt")
        readAudioGuideText(m.Prompt.text)
        m.Prompt.visible = true
        m.warningDisplayedCount += 1
      else if isUserNewBorn(date, currentYear) = true or isUserTooOld(date, currentYear) = true
        m.Prompt.text = getTranslation("screenAgeVerification_error_prompt")
        readAudioGuideText(m.Prompt.text)
        m.Prompt.visible = true
      else
        m.StartButton.setFocus(true)
        readAudioGuideText(m.StartButton.text)
      end if

    end if

    refreshDateOnScreen(date)
    updateDateDecorations()
  end if
End Function

Function onAgeSubmittedChanged()
  ' Want to reset the numberpad text on submit as the only time they will be coming back is if they were confirming their age and likely need to change it
    m.NumberPad.text = ""
End Function


' isUserToddler checks whether user's age is greater than 1 and less than or equal to 4 (age>1 and age<=4)
' @date: string, user entered year formatted as YYYY-MM-DD
' @currentYear: Integer, current year in YYYY format
Function isUserToddler(date, currentYear)

  if date.toInt() < (currentYear - 1) AND date.toInt() > (currentYear - 4)
    return true
  end if

  return false

End Function


' isUserNewBorn checks whether user's age is less than or equal to 1 (age <=1)
' @date: string, user entered year formatted as YYYY-MM-DD
' @currentYear: Integer, current year in YYYY format
Function isUserNewBorn(date, currentYear)

  if date.toInt() >= currentYear - 1
    return true
  end if

  return false

End Function


' isUserTooOld checks whether user's age is greather than 125 (age > 125)
' @date: string, user entered year formatted as YYYY-MM-DD
' @currentYear: Integer, current year in YYYY format
Function isUserTooOld(date, currentYear)

  if date.toInt() < currentYear - 125
    return true
  end if

  return false

End Function


Function refreshDateOnScreen(date)
  year = date

  ' update the year values
  if year = invalid or year.len() = 0
    m.YearEntryFront.text = m.yearLetter + m.yearLetter + m.yearLetter + m.yearLetter
    m.YearEntryBack.text = m.yearLetter + m.yearLetter + m.yearLetter + m.yearLetter
  else if year.len() = 1
    m.YearEntryFront.text = year + m.yearLetter + m.yearLetter + m.yearLetter
    m.YearEntryBack.text = year + m.yearLetter + m.yearLetter + m.yearLetter
  else if year.len() = 2
    m.YearEntryFront.text = year + m.yearLetter + m.yearLetter
    m.YearEntryBack.text = year + m.yearLetter + m.yearLetter
  else if year.len() = 3
    m.YearEntryFront.text = year + m.yearLetter
    m.YearEntryBack.text = year + m.yearLetter
  else if year.len() = 4
    m.YearEntryFront.text = year
    m.YearEntryBack.text = year
  end if
End Function


Function updateDateDecorations()
  decorateYear()
End Function


Function decorateYear()
  stopAllAnimations()

  ' fade in the year if necessary
  if m.YearEntryFront.opacity < 1 then m.yearEntryFade = fade(m.YearEntryFront, "in", 0.3)
  if m.YearBackground.opacity < 1 then m.yearBgFade = fade(m.YearBackground, "in", 0.3)

End Function


Function stopAllAnimations()
  if m.yearEntryFade <> invalid AND m.yearEntryFade.state <> "stopped" then m.yearEntryFade.control = "stop"
  if m.yearBgFade <> invalid AND m.yearBgFade.state <> "stopped" then m.yearBgFade.control = "stop"
End Function


' @key: string, the name of the key pressed, as defined by Roku
' @press: boolean, true for press down event, false for key release event
Function onKeyEvent(key, press) as Boolean
  if press = true
    if key = "back"
      m.top.backButtonPressed = true
    else
      if key = "down"
        if m.NumberPad.text.len() = 4 AND m.NumberPad.isInFocusChain() = true AND m.Prompt.visible = false
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


' @submittedMillennium: integer, single digit representation of millennium. For the year 2019,
'                                submittedMillennium should be 2.
' @submittedCentury: integer, single digit representation of century. For the year 2019,
'                             submittedCentury should be 0.
Function checkValidCentury(submittedMillennium, submittedCentury)
  dateTime = createObject("roDateTime")
  currentYear = dateTime.getYear()

  currentCentury = (currentYear MOD 1000) \ 100 * 100
  ' (2021 MOD 1000) \ 100 * 100 = 0
  ' (2221 MOD 1000) \ 100 * 100 = 200

  currentMillennium = currentYear \ 1000 * 1000

  if submittedMillennium * 1000 = currentMillennium AND (submittedCentury * 100) > currentCentury
    ' only check if the submitted century is greater than current century if the submitted millennium
    ' is equal to the current millennium. If the submitted millennium is a previous millennium, then
    ' we could expect centuries of value greater than the current century value. (ie. the 9 in 1987
    ' is greater than the 0 in 2021 and should be allowed, but 29xx should not be allowed).
    return false
  end if

  return true
End Function


' @submittedCentury: integer, single digit representation of century. For the year 2019,
'                                submittedCentury should be 0.
' @submittedDecade: integer, single digit representation of decade. For the year 2019,
'                             submittedDecade should be 1.
Function checkValidDecade(submittedCentury, submittedDecade)
  dateTime = createObject("roDateTime")
  currentYear = dateTime.getYear()

  currentDecade = (currentYear MOD 100) \ 10 * 10
  ' (2021 MOD 100) \ 10 * 10 = 20
  ' (2019 MOD 100) \ 10 * 10 = 10

  currentCentury = (currentYear MOD 1000) \ 100 * 100

  if submittedCentury * 100 = currentCentury AND (submittedDecade * 10) > currentDecade
    ' only check if the submitted decade is greater than current decade if the submitted century
    ' is equal to the current century. If the submitted century is a previous century, then
    ' we could expect decades of value greater than the current decade value. (ie. the 8 in 1987
    ' is greater than the 2 in 2021 and should be allowed, but 208x should not be allowed).
    return false
  end if

  return true
End Function


' @submittedYear: string, four digit representation of year(YYYY). eg. 1986
Function checkValidYear(submittedYear)

  dateTime = createObject("roDateTime")
  currentYear = dateTime.getYear()

  ' don't allow future years/month/dates
  if submittedYear.toInt() > currentYear
    return false
  else
    return true
  end if

End Function


Function onAudioGuideTextChanged(msg)
  audioGuideText = msg.getData()
  if isNonEmptyString(audioGuideText) = true
    readAudioGuideText(audioGuideText)
  end if
End Function
