Function init()
  topRef = m.top
  m.constants = getConstantsFromGlobal()
  m.tubiTrackingInfo = TubiTrackingInfo(m.constants)
  topRef.observeFieldScoped("focusedChild", "onScreenFocusChange")

  m.heading = topRef.findNode("heading")
  m.subheading = topRef.findNode("subheading")
  m.exitBtn = topRef.findNode("exitBtn")
  m.exitBtn.observeFieldScoped("selected", "onExitButtonSelected")

  m.heading.text = getTranslation("gdpr_age_gate_error_dialog_heading")
  m.subheading.text = getTranslation("gdpr_age_gate_error_dialog_sub_heading")
  m.exitBtn.text = getTranslation("gdpr_age_gate_error_dialog_exit_tubi")

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.heading, typographyConstants.ids.headerMedium)
  setTypographyOfLabel(m.subheading, typographyConstants.ids.bodyLarge)

  onThemeChange()

  topRef.trackingPageInfo = {
    pageType: "static_page"
    pageValues: {
      name: "age_gate_error_18"
    }
  }
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
    m.exitBtn.setFocus(true)
  end if
End Function


Function onExitButtonSelected()
  trackingPageInfo = m.top.trackingPageInfo
  componentValues = {
    button_type: "TEXT"
    button_value: "EXIT_TUBI"
  }
  pageOneof = m.tubiTrackingInfo.getAnalyticsPage(trackingPageInfo.pagetype, trackingPageInfo.pageValues)
  componentOneof = m.tubiTrackingInfo.getAnalyticsComponent("button_component", componentValues)

  m.top.componentInteractionInfo = {
    pageOneof: pageOneof
    componentOneof: componentOneof
    user_interaction: "CONFIRM"
  }

  m.top.exitButtonSelected = true
End Function


' @key: string, the name of the key pressed, as defined by Roku
' @press: boolean, true for press down event, false for key release event
Function onKeyEvent(key, press) as Boolean
  if press = true AND key = "back"
    m.top.backButtonPressed = true
    return true
  end if

  return false
End Function
