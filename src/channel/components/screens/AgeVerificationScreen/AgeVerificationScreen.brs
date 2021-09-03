Function init()
  m.constants = m.global.constants
  m.Header = m.top.findNode("AgeVerificationPageHeader")
  m.SubHeader = m.top.findNode("AgeVerificationPageSubHeader")
  m.NumberPad = m.top.findNode("AgeVerificationNumberpad")
  m.StartButton = m.top.findNode("AgeVerificationStartButton")
  m.DateInfo = m.top.findNode("AgeVericationDateInfo")
  m.YearEntryFront = m.top.findNode("AgeVerificationYearEntryFront")
  m.YearEntryBack = m.top.findNode("AgeVerificationYearEntryBack")
  m.YearBackground = m.top.findNode("AgeVerificationYearBg")
  m.YearLabel = m.top.findNode("AgeVerificationYear")
  m.Prompt = m.top.findNode("AgeVericationErrorPrompt")
  m.bornYear = m.top.findNode("AgeVerificationYearText")
  m.infoLabel = m.top.findNode("AgeVericationInfoLabel")

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

  ' m.date will have the format "12-09-2021"
  m.date = ""

  ' Center the tip text and error prompt text on the date info display
  ' need to know the language translation before we can center properly
  centerTips()

  m.top.trackingPageInfo = {
    pageType: "age_gate_page"
    pageValues: {}
  }

  m.top.screenLevel = m.constants.ui.screenLevels.ageGateScreen

  m.top.observeField("focusedChild", "onComponentFocusChanged")
  m.top.observeField("signInInfo", "onSignInInfo")
  m.NumberPad.observeField("buttonSelected", "onNumberPadButtonSelected")
End Function


Function onSignInInfo(msg)

  signInInfo = msg.getData()
  if signInInfo <> invalid
    firstname = signInInfo.firstname
    if firstname <> invalid and firstname <> ""
      m.Header.text = getTranslation("screenAgeVerification_header", {firstname: firstname})
    end if
  end if  

End Function


Function onComponentFocusChanged()
  if m.top.hasFocus()
    m.NumberPad.setFocus(true)
  end if
End Function


Function centerTips()
  dateBoundingRect = m.DateInfo.boundingRect()
  dateCenter = (dateBoundingRect.width / 2) + dateBoundingRect.x

  promptWidth = m.Prompt.boundingRect().width
  promptX = dateCenter - (promptWidth / 2)
  m.Prompt.translation = [promptX, m.Prompt.translation[1]]
End Function


Function onNumberPadButtonSelected(msg)
  selected = msg.getData()
  if selected = "back"
    ' remove the last character
    if m.date.len() > 0
      amountToRemove = 1
      newDateLen = m.date.len() - amountToRemove
      m.date = m.date.Left(newDateLen)
      m.Prompt.visible = false
    end if
  else
    selectedInt = selected.toInt()

    if m.date.len() = 0 and selectedInt <> 1 and selectedInt <> 2
      m.Prompt.visible = true
    else if m.date.len() = 1 and m.date.Right(1).toInt() = 1 and selectedInt <> 9
      ' do nothing, don't allow centuries that are not 19xx if millenium is 1xxx
      m.Prompt.visible = true
    else if m.date.len() = 1 and m.date.Right(1).toInt() = 2 and checkValidCentury(m.date.Right(1).toInt(), selectedInt) = false
      ' do nothing, don't allow centuries greater than the current century if millenium is 2xxx
      m.Prompt.visible = true
    else if m.date.len() = 2 and m.date.Mid(6, 1).toInt() = 2 and checkValidDecade(m.date.Right(1).toInt(), selectedInt) = false
      ' do nothing, don't allow decades greater than the current decade if millenium is 2xxx
      m.Prompt.visible = true
    else if m.date.len() = 3 and checkValidYear(m.date + selected) = false
      m.Prompt.visible = true
    else if m.date.len() < 4
      ' only add more characters to the date if we don't have the whole date already
      m.date += selected
      m.Prompt.visible = false
    end if
  end if

  if m.date.len() = 4
    m.top.birthdate = m.date + "-01-01"  ' since backend expects birthday in date format(YYYY-MM-DD), we are appending dummy month & day
    m.StartButton.setFocus(true)
  end if

  refreshDateOnScreen(m.date)
  updateDateDecorations(m.date)
  ' showErrorTip()
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
  else
    m.YearEntryFront.text = year
    m.YearEntryBack.text = year
  end if
End Function


Function updateDateDecorations(date)
  decorateYear()
End Function


Function decorateYear()
  stopAllAnimations()

  ' fade in the year if necessary
  if m.YearEntryFront.opacity < 1 then m.yearEntryFade = fade(m.YearEntryFront, "in", 0.3)
  if m.YearBackground.opacity < 1 then m.yearBgFade = fade(m.YearBackground, "in", 0.3)

End Function


Function stopAllAnimations()
  if m.yearEntryFade <> invalid and m.yearEntryFade.state <> "stopped" then m.yearEntryFade.control = "stop"
  if m.yearBgFade <> invalid and m.yearBgFade.state <> "stopped" then m.yearBgFade.control = "stop"
End Function


' @key: string, the name of the key pressed, as defined by Roku
' @press: boolean, true for press down event, false for key release event
Function onKeyEvent(key, press) as Boolean
  if press = true
    if key = "back"
      if m.global.authInfo <> invalid
        m.top.backButtonPressed = true
      else
        return false  
      end if
    else
      if key = "down"
        if m.date.len() = 4 and m.NumberPad.isInFocusChain() = true
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


' @submittedMillenium: integer, single digit representation of millenium. For the year 2019,
'                                submittedMillenium should be 2.
' @submittedCentury: integer, single digit representation of century. For the year 2019,
'                             submittedCentury should be 0.
Function checkValidCentury(submittedMillenium, submittedCentury)
  dateTime = createObject("roDateTime")
  currentYear = dateTime.getYear()

  currentCentury = (currentYear MOD 1000) \ 100 * 100
  ' (2021 MOD 1000) \ 100 * 100 = 0
  ' (2221 MOD 1000) \ 100 * 100 = 200

  currentMillenium = currentYear \ 1000 * 1000

  if submittedMillenium * 1000 = currentMillenium and (submittedCentury * 100) > currentCentury
    ' only check if the submitted century is greater than current century if the submitted millenium
    ' is equal to the current millenium. If the submitted millenium is a previous millenium, then
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

  if submittedCentury * 100 = currentCentury and (submittedDecade * 10) > currentDecade
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


' @year: integer, ex: 2000
Function isLeapYear(year)
  if year MOD 4 <> 0
    return false
  else if year MOD 100 = 0 and year MOD 400 <> 0
    return false
  end if
  return true
End Function
