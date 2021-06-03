Function init()
  m.constants = m.global.constants
  m.WhyButton = m.top.findNode("AgeVerificationWhyButton")
  m.Header = m.top.findNode("AgeVerificationPageHeader")
  m.SubHeader = m.top.findNode("AgeVerificationPageSubHeader")
  m.NumberPad = m.top.findNode("AgeVerificationNumberpad")
  m.StartButton = m.top.findNode("AgeVerificationStartButton")
  m.DateInfo = m.top.findNode("AgeVericationDateInfo")
  m.MonthEntryFront = m.top.findNode("AgeVerificationMonthEntryFront")
  m.MonthEntryBack = m.top.findNode("AgeVerificationMonthEntryBack")
  m.MonthBackground = m.top.findNode("AgeVerificationMonthBg")
  m.DayEntryFront = m.top.findNode("AgeVerificationDayEntryFront")
  m.DayEntryBack = m.top.findNode("AgeVerificationDayEntryBack")
  m.DayBackground = m.top.findNode("AgeVerificationDayBg")
  m.YearEntryFront = m.top.findNode("AgeVerificationYearEntryFront")
  m.YearEntryBack = m.top.findNode("AgeVerificationYearEntryBack")
  m.YearBackground = m.top.findNode("AgeVerificationYearBg")
  m.MonthLabel = m.top.findNode("AgeVerificationMonth")
  m.DayLabel = m.top.findNode("AgeVerificationDay")
  m.YearLabel = m.top.findNode("AgeVerificationYear")
  m.Tip = m.top.findNode("AgeVericationDateTip")
  m.Prompt = m.top.findNode("AgeVericationErrorPrompt")

  m.WhyButton.text = getTranslation("dialog_why_ask_age_title")
  m.Header.text = getTranslation("screenAgeVerification_header")
  m.SubHeader.text = getTranslation("screenAgeVerification_sub_header")
  m.StartButton.text = getTranslation("screenAgeVerification_keypad_button")
  m.MonthEntryFront.text = getTranslation("screenAgeVerification_mm")
  m.MonthEntryBack.text = getTranslation("screenAgeVerification_mm")
  m.DayEntryFront.text = getTranslation("screenAgeVerification_dd")
  m.DayEntryBack.text = getTranslation("screenAgeVerification_dd")
  m.YearEntryFront.text = getTranslation("screenAgeVerification_yyyy")
  m.YearEntryBack.text = getTranslation("screenAgeVerification_yyyy")
  m.MonthLabel.text = getTranslation("screenAgeVerification_month")
  m.DayLabel.text = getTranslation("screenAgeVerification_day")
  m.YearLabel.text = getTranslation("screenAgeVerification_year")
  m.Tip.text = getTranslation("screenAgeVerification_tip")
  m.Prompt.text = getTranslation("screenAgeVerification_error_prompt")

  m.monthLetter = m.MonthEntryFront.text.Left(1)
  m.dayLetter = m.DayEntryFront.text.Left(1)
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
  m.WhyButton.observeField("selected", "onWhyButtonSelected")
  m.NumberPad.observeField("buttonSelected", "onNumberPadButtonSelected")
End Function


Function onComponentFocusChanged()
  if m.top.hasFocus()
    m.NumberPad.setFocus(true)
  end if
End Function


Function centerTips()
  dateBoundingRect = m.DateInfo.boundingRect()
  dateCenter = (dateBoundingRect.width / 2) + dateBoundingRect.x

  tipWidth = m.Tip.boundingRect().width
  tipX = dateCenter - (tipWidth / 2)
  m.Tip.translation = [tipX, m.Tip.translation[1]]

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
      if m.date.len() = 3 or m.date.len() = 6
        ' remove the "-" as well as the date number if necessary
        amountToRemove = 2
      end if
      newDateLen = m.date.len() - amountToRemove
      m.date = m.date.Left(newDateLen)
      m.Prompt.visible = false
    end if
  else
    selectedInt = selected.toInt()
    if m.date.len() = 0 and selectedInt > 1
      ' add the leading "0" for the user for Feb - Sep
      m.date += "0" + selected + "-"
      m.Prompt.visible = false
    else if m.date.len() = 1 and checkValidMonth(m.date + selected) = false
      m.Prompt.visible = true
    else if m.date.len() = 3 and ((m.date.Right(2).toInt() = 2 and selectedInt > 2) or selectedInt > 3)
      ' add the leading "0" for dates beyond 30/31 or beyond 29 in February
      m.date += "0" + selected + "-"
      m.Prompt.visible = false
    else if m.date.len() = 4 and checkValidMonthDate(m.date, selected) = false
      ' don't allow dates that don't exist within the month
      m.Prompt.visible = true
    else if m.date.len() = 6 and selectedInt <> 1 and selectedInt <> 2
      ' do nothing, don't allow millenia unless they are 1xxx or 2xxx
      m.Prompt.visible = true
    else if m.date.len() = 7 and m.date.Right(1).toInt() = 1 and selectedInt <> 9
      ' do nothing, don't allow centuries that are not 19xx if millenium is 1xxx
      m.Prompt.visible = true
    else if m.date.len() = 7 and m.date.Right(1).toInt() = 2 and checkValidCentury(m.date.Right(1).toInt(), selectedInt) = false
      ' do nothing, don't allow centuries greater than the current century if millenium is 2xxx
      m.Prompt.visible = true
    else if m.date.len() = 8 and m.date.Mid(6, 1).toInt() = 2 and checkValidDecade(m.date.Right(1).toInt(), selectedInt) = false
      ' do nothing, don't allow decades greater than the current decade if millenium is 2xxx
      m.Prompt.visible = true
    else if m.date.len() = 9 and checkValidDate(m.date, selected) = false
      m.Prompt.visible = true
    else if m.date.len() < 10
      ' only add more characters to the date if we don't have the whole date already
      m.date += selected

      if m.date.len() = 2 or m.date.len() = 5
        m.date += "-"
      end if

      m.Prompt.visible = false
    end if
  end if

  if m.date.len() = 10
    m.top.birthdate = formatBirthdateForBackend(m.date)
    m.StartButton.setFocus(true)
  end if

  refreshDateOnScreen(m.date)
  updateDateDecorations(m.date)
  ' showErrorTip()
End Function


Function refreshDateOnScreen(date)
  dateParts = date.split("-")
  month = dateParts[0]
  day = dateParts[1]
  year = dateParts[2]

  ' update the month values
  if month = invalid or month.len() = 0
    m.MonthEntryFront.text = m.monthLetter + m.monthLetter
    m.MonthEntryBack.text = m.monthLetter + m.monthLetter
  else if month.len() = 1
    m.MonthEntryFront.text = month + m.monthLetter
    m.MonthEntryBack.text = month + m.monthLetter
  else
    m.MonthEntryFront.text = month
    m.MonthEntryBack.text = month
  end if

  ' update the day values
  if day = invalid or day.len() = 0
    m.DayEntryFront.text = m.dayLetter + m.dayLetter
    m.DayEntryBack.text = m.dayLetter + m.dayLetter
  else if day.len() = 1
    m.DayEntryFront.text = day + m.dayLetter
    m.DayEntryBack.text = day + m.dayLetter
  else
    m.DayEntryFront.text = day
    m.DayEntryBack.text = day
  end if

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


Function formatBirthdateForBackend(date)
  dateParts = date.split("-")
  month = dateParts[0]
  day = dateParts[1]
  year = dateParts[2]

  return [
    year
    month
    day
  ].join("-")
End Function


Function updateDateDecorations(date)
  if date.len() < 2
    decorateMonth()
  else if date.len() > 2 and date.len() < 6
    decorateDay()
  else
    decorateYear()
  end if
End Function


Function decorateMonth()
  stopAllAnimations()

  ' fade in the month if necessary
  if m.MonthEntryFront.opacity < 1 then m.monthEntryFade = fade(m.MonthEntryFront, "in", 0.3)
  if m.MonthBackground.opacity < 1 then m.monthBgFade = fade(m.MonthBackground, "in", 0.3)

' fade out the day and year if necessary
  if m.DayEntryFront.opacity > 0 then m.dayEntryFade = fade(m.DayEntryFront, "out", 0.3)
  if m.DayBackground.opacity > 0 then m.dayBgFade = fade(m.DayBackground, "out", 0.3)
  if m.YearEntryFront.opacity > 0 then m.yearEntryFade = fade(m.YearEntryFront, "out", 0.3)
  if m.YearBackground.opacity > 0 then m.yearBgFade = fade(m.YearBackground, "out", 0.3)
End Function


Function decorateDay()
  stopAllAnimations()

  ' fade in the day if necessary
  if m.DayEntryFront.opacity < 1 then m.dayEntryFade = fade(m.DayEntryFront, "in", 0.3)
  if m.DayBackground.opacity < 1 then m.dayBgFade = fade(m.DayBackground, "in", 0.3)

  ' fade out the month and year if necessary
  if m.MonthEntryFront.opacity > 0 then m.monthEntryFade = fade(m.MonthEntryFront, "out", 0.3)
  if m.MonthBackground.opacity > 0 then m.monthBgFade = fade(m.MonthBackground, "out", 0.3)
  if m.YearEntryFront.opacity > 0 then m.yearEntryFade = fade(m.YearEntryFront, "out", 0.3)
  if m.YearBackground.opacity > 0 then m.yearBgFade = fade(m.YearBackground, "out", 0.3)
End Function


Function decorateYear()
  stopAllAnimations()

  ' fade in the year if necessary
  if m.YearEntryFront.opacity < 1 then m.yearEntryFade = fade(m.YearEntryFront, "in", 0.3)
  if m.YearBackground.opacity < 1 then m.yearBgFade = fade(m.YearBackground, "in", 0.3)

  ' fade out the month and day if necessary
  if m.MonthEntryFront.opacity > 0 then m.monthEntryFade = fade(m.MonthEntryFront, "out", 0.3)
  if m.MonthBackground.opacity > 0 then m.monthBgFade = fade(m.MonthBackground, "out", 0.3)
  if m.DayEntryFront.opacity > 0 then m.dayEntryFade = fade(m.DayEntryFront, "out", 0.3)
  if m.DayBackground.opacity > 0 then m.dayBgFade = fade(m.DayBackground, "out", 0.3)
End Function


Function stopAllAnimations()
  if m.monthEntryFade <> invalid and m.monthEntryFade.state <> "stopped" then m.monthEntryFade.control = "stop"
  if m.monthBgFade <> invalid and m.monthBgFade.state <> "stopped" then m.monthBgFade.control = "stop"

  if m.dayEntryFade <> invalid and m.dayEntryFade.state <> "stopped" then m.dayEntryFade.control = "stop"
  if m.dayBgFade <> invalid and m.dayBgFade.state <> "stopped" then m.dayBgFade.control = "stop"

  if m.yearEntryFade <> invalid and m.yearEntryFade.state <> "stopped" then m.yearEntryFade.control = "stop"
  if m.yearBgFade <> invalid and m.yearBgFade.state <> "stopped" then m.yearBgFade.control = "stop"
End Function


' @key: string, the name of the key pressed, as defined by Roku
' @press: boolean, true for press down event, false for key release event
Function onKeyEvent(key, press) as Boolean
  if press = true
    if key = "back"
      m.top.backButtonPressed = true
    else
      if key = "down"
        if m.WhyButton.hasFocus()
          m.NumberPad.setFocus(true)
        else if m.date.len() = 10 and m.NumberPad.isInFocusChain() = true
          m.StartButton.setFocus(true)
        end if
      else if key = "up"
        if m.StartButton.isInFocusChain() = true
          m.NumberPad.setFocus(true)
        else if m.NumberPad.isInFocusChain() = true
          m.WhyButton.setFocus(true)
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


' @submittedMonth: string, month representation as a number (ie. "01" = January, "05" = May, etc.)
Function checkValidMonth(submittedMonth)
  if submittedMonth.toInt() > 12 or submittedMonth.toInt() < 1
    ' don't allow months over 12 or a "00" month
    return false
  end if

  return true
End Function


' @submittedMonthDate: string, 2 digit month, 1 digit day, Format should be "MM-D", ie "04-0"
' @submittedDay: string, single digit representation of last character in a 2 character day. For
'                          example, if the MM-DD is 12-25, the submittedDay should be "5".
Function checkValidMonthDate(submittedMonthDate, submittedDay)
  submittedDateParts = submittedMonthDate.split("-")
  submittedMonth = submittedDateParts[0]
  submittedDay = (submittedDateParts[1] + submittedDay).toInt()

  ' months with 31 days
  longMonths = {}
  longMonths["1"] = true
  longMonths["3"] = true
  longMonths["5"] = true
  longMonths["7"] = true
  longMonths["8"] = true
  longMonths["10"] = true
  longMonths["12"] = true

  if submittedDay > 31 or submittedDay < 1
    return false
  else if submittedDay = 31 and longMonths[submittedMonth] = invalid
    ' don't allow a user to input 31 for the day if there are less than 31 days in the month (ie. 4/31/00)
    return false
  else if submittedMonth = "2" and submittedDay > 29
    return false
  end if
End Function


' @submittedDate: string, 2 digit month, 2 digit day, and first 3 digits of the year.
'                         Format should be "MM-DD-YYY", ie "04-01-198"
' @submittedYear: string, single digit representation of year. For the year 2019,
'                             submittedYear should be "9".
Function checkValidDate(submittedDate, submittedYear)
  submittedDateParts = submittedDate.split("-")

  if submittedDateParts.count() = 3
    submittedMonth = submittedDateParts[0].toInt()
    submittedDay = submittedDateParts[1].toInt()
    submittedYear = (submittedDateParts[2] + submittedYear).toInt()


    dateTime = createObject("roDateTime")
    currentYear = dateTime.getYear()
    currentMonth = dateTime.getMonth()
    currentDay = dateTime.getDayOfMonth()

    ' don't allow future years/month/dates
    if submittedYear > currentYear
      return false
    else if currentYear = submittedYear
      if submittedMonth > currentMonth
        return false
      else if submittedMonth = currentMonth and submittedDay > currentDay
        return false
      end if
    end if

    ' don't allow leap year dates if it is not a leap year
    if submittedMonth = 2 and submittedDay = 29
      return isLeapYear(submittedYear)
    end if
  else
    return false
  end if

  return true
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
