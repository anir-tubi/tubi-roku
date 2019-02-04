Function init()
  m.constants = m.global.constants
  m.NodeHelpers = TubiNodeHelpers()
  Request = TubiRequest()
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)

  m.top.observeField("focusedChild", "onFocus")
  m.top.observeField("show", "onShow")
  m.ScreenStack = m.top.findNode("SignInScreenStack")
  if m.constants.deviceInfo.limitedUi = false
    m.ScreenStack.transition = "cascade"
  else
    m.ScreenStack.transition = "visible"
  end if

  initScreenStack(m.ScreenStack, onScreenStackEmpty)
End Function


''''''''''''''''''''''''''
' onFocus
'
' Set the focus to the top screen
Function onFocus()
  if m.top.hasFocus() and currentScreen() <> invalid then
    currentScreen().setFocus(true)
  end if
End Function


Function onScreenStackEmpty()
  tubiLog("SignInController.onScreenStackEmpty")
  m.top.backPressed = true
End Function


''''''''''''''''
' onShow
'
' Start the sign-in experience. Do it here instead of init() so
' that the caller can configure the first screen.
Function onShow()
  if m.top.skipDisambiguationScreen = true then
    onRegister()
  else
    m.Disambiguation = CreateObject("roSGNode", "SignInDisambiguationScreen")
    m.Disambiguation.observeField("signInButtonSelected", "onRegister")
    m.Disambiguation.observeField("guestPassButtonSelected", "onDisambiguationGuestPass")
    pushScreen(m.Disambiguation, true, true)
  end if
End Function


'''''''''''''''''''''''''''''
' onDisambiguationGuestPass
' 
' User chose a guest pass
Function onDisambiguationGuestPass()
  m.top.state = "guest"
End Function


'''''''''''''''''''''''''''''
' onContinueGuestPass
'
' User really wants a guest pass, set a field so the parent can show content
Function onContinueGuestPass()
  tubiLog("SignInController.onContinueGuestPass")
    m.top.state = "guest"
End Function


'''''''''''''''''''''''''''''
' onRegister
'
' User wants to register (or sign-in) via the web site
Function onRegister()
  tubiLog("SignInController.onRegister")
  m.RegisterInstructions = CreateObject("roSGNode", "RegisterInstructionsScreen")
  m.RegisterInstructions.observeField("registerSuccess", "onRegisterSuccess")
  m.RegisterInstructions.observeField("skipButtonPressed", "onContinueGuestPass")

  shouldTrackNavigate = true
  if currentScreen() = invalid and m.top.sourceScreen <> invalid
    'do the navigate_to_page here instead of from within push screen, because the screen stack does not have the previous screens info
    'as it belongs to the contentController's screen stack
    shouldTrackNavigate = false
    screenTrackingNavigate(m.top.sourceScreen.trackingPageInfo, m.RegisterInstructions.trackingPageInfo, m.top.sourceScreen.trackingComponentInfo)
  end if

  pushScreen(m.RegisterInstructions, shouldTrackNavigate, true)
End Function


'''''''''''''''''''''''''''''
' onRegisterSuccess
'
' User has successfully registered, set a field to redirect to content
Function onRegisterSuccess()
  tubiLog("SignInController.onRegisterSuccess")
  m.top.state = "registered"
End Function
