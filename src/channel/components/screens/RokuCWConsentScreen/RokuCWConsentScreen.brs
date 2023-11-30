Function init()
  topRef = m.top
  m.constants = getConstantsFromGlobal()

  m.tubiTrackingInfo = TubiTrackingInfo(m.constants)

  topRef.id = m.constants.ui.screenIds.rokuContinueWatchingConsentScreen
  topRef.screenLevel = m.constants.ui.screenLevels.rokuContinueWatchingConsentScreen

  topRef.observeFieldScoped("focusedChild", "onScreenFocusChange")
  m.heading = topRef.findNode("heading")
  m.subheading = topRef.findNode("subheading")
  m.buttonList = topRef.findNode("buttonList")
  m.buttonList.observeFieldScoped("itemSelected", "onItemSelectedChange")
  m.buttonList.observeFieldScoped("itemFocused", "onItemFocusedChange")
  m.buttonList.muteAudioGuide = true

  m.heading.text = getTranslation("roku_cw_consent_screen_heading")
  m.subheading.text = getTranslation("roku_cw_consent_screen_sub_heading")

  readAudioGuideText(m.heading.text)
  readAudioGuideText(m.subheading.text, false)

  buttonList = CreateObject("roSGNode", "ContentNode")
  buttons = [
    {
      id: m.constants.ui.rokuCWConsentActionButtonIds.accept
      title: getTranslation("accept_now_button_label")
    }
    {
      id: m.constants.ui.rokuCWConsentActionButtonIds.reject
      title: getTranslation("maybe_later_button_label")
    }
  ]
  buttonList.update(buttons, true)

  m.buttonList.content = buttonList

  ' Setting background.
  background = topRef.findNode("background")
  background.uri = m.constants.ui.uris.marketingBackground

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if

  onThemeChange()
  
  topRef.trackingPageInfo = {
    pageType: "onboarding_page"
    pageValues: {
      name: "continue_watching_consent"
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
    m.buttonList.setFocus(true)
  end if
End Function


Function onItemSelectedChange(msg)
  itemSelected = msg.getData()
  buttonSelected = m.buttonList.content.getChild(itemSelected).id

  buttonValue = "REJECT_CW_CONSENT"
  if buttonSelected = m.constants.ui.rokuCWConsentActionButtonIds.accept
    buttonValue = "ACCEPT_CW_CONSENT"
  end if

  componentValues = {
    button_type: "TEXT"
    button_value: buttonValue
  }

  trackingPageInfo = m.top.trackingPageInfo
  pageOneof = m.tubiTrackingInfo.getAnalyticsPage(trackingPageInfo.pagetype, trackingPageInfo.pageValues)
  componentOneof = m.tubiTrackingInfo.getAnalyticsComponent("button_component", componentValues)

  m.top.componentInteractionInfo =  {
    pageOneof: pageOneof
    componentOneof: componentOneof
    user_interaction: "CONFIRM"
  }

  m.top.buttonSelected = buttonSelected
End Function


Function onItemFocusedChange(msg)
  itemFocused = msg.getData()
  buttonLabel = m.buttonList.content.getChild(itemFocused).title
  readAudioGuideText(buttonLabel, false)
End Function


Function onKeyEvent(key As String, press As Boolean) as Boolean 
  if press AND key = "back"
    m.top.backButtonSelected = true
    return true
  end if
  return false
End Function
