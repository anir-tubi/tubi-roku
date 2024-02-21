Function showRokuCWConsentScreen(callback)
  m.callbackAfterRokuCWConsent = callback
  showContentGroupAndHideSpinner()
  displayDefaultBackground()
  screen = CreateObject("roSGNode", "RokuCWConsentScreen")
  pushScreen(screen, true, true)
  screen.observeFieldScoped("buttonSelected", "onRokuCWConsentActionButtonSelected")
  screen.observeFieldScoped("backButtonSelected", "onRokuCWConsentBackButtonSelected")
  screen.observeFieldScoped("componentInteractionInfo", "onComponentInteractionInfoChange")
  screen.setFocus(true)
End Function


Function onRokuCWConsentActionButtonSelected(msg)
  buttonSelected = msg.getData()

  if buttonSelected = m.constants.ui.rokuCWConsentActionButtonIds.accept
    body = {}
    body[m.constants.consentKeys.continueWatching] = "opted_in"
    setConsent(body)
  end if

  m.callbackAfterRokuCWConsent()
End Function


Function onRokuCWConsentBackButtonSelected()
  m.callbackAfterRokuCWConsent()
End Function
