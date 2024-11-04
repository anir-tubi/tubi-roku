Function init()
  topRef = m.top
  m.constants = getConstantsFromGlobal()
  topRef.observeFieldScoped("focusedChild", "onScreenFocusChange")
  topRef.observeFieldScoped("action", "onActionChange")
  
  m.heading = topRef.findNode("heading")
  m.subheading = topRef.findNode("subheading")
  m.continueBtn = topRef.findNode("continueBtn")
  m.continueBtn.text = getTranslation("reg_continue_as_guest_button_title")

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.heading, typographyConstants.ids.headerMedium)
  setTypographyOfLabel(m.subheading, typographyConstants.ids.bodyLarge)

  onThemeChange()

  m.top.backgroundUriList = []
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.heading.color = theme.primaryTextColor
    m.subheading.color = theme.secondaryTextColor
  end if
End Function


Function onScreenFocusChange()
  if m.top.hasFocus() = true
    m.continueBtn.setFocus(true)
  end if
End Function


Function onActionChange(msg)
  action = msg.getData()
  majorEventStart = getExternalConfigValueFromGlobal("major_event_start", m.constants.configHubFallbacks.majorEventStart)
  majorEventEnd = getExternalConfigValueFromGlobal("major_event_end", m.constants.configHubFallbacks.majorEventEnd)
  isMajorEventDay = isNowWithinTimePeriod(majorEventStart, majorEventEnd)

  if action = "signIn"
    headingKey = "sign_in_error_screen_heading"

    if isMajorEventDay = true
      subheadingKey = "sign_in_error_screen__purple_carpet_day_subheading"
      trackingPageValue = "sign_in_error_2"
    else
      subheadingKey = "sign_in_error_screen__default_subheading"
      trackingPageValue = "sign_in_error_1"
    end if

  else
    headingKey = "sign_up_error_screen_heading"

    if isMajorEventDay = true
      subheadingKey = "sign_up_error_screen__purple_carpet_day_subheading"
      trackingPageValue = "sign_up_error_2"
    else
      subheadingKey = "sign_up_error_screen__default_subheading"
      trackingPageValue = "sign_up_error_1"
    end if

  end if

  m.heading.text = getTranslation(headingKey)
  m.subheading.text = getTranslation(subheadingKey)

  m.top.trackingPageInfo = {
    pageType: "static_page"
    pageValues: {
      name: trackingPageValue
    }
  }
End Function


' @key: string, the name of the key pressed, as defined by Roku
' @press: boolean, true for press down event, false for key release event
Function onKeyEvent(key, press) as Boolean
  if press = true AND key = "back"
    m.top.continueButtonSelected = true
    return true
  end if

  return false
End Function
