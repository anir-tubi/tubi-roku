Function init()
  m.top.observeField("focusedChild", "onFocus")
  m.top.observeField("show", "onShow")
  m.skipContinueScreen = m.global.constants.ui.signIn.skipContinueScreen
  m.skipSignInRegisterScreen = m.global.constants.ui.signIn.skipSignInRegisterScreen

  initScreenStack(m.top.findNode("SignInScreenStack"), onScreenStackEmpty)
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
    onDisambiguationSignIn()
  else
    m.Disambiguation = CreateObject("roSGNode", "SignInDisambiguationScreen")
    m.Disambiguation.observeField("signInButtonSelected", "onDisambiguationSignIn")
    m.Disambiguation.observeField("guestPassButtonSelected", "onDisambiguationGuestPass")
    pushScreen(m.Disambiguation)
  end if
End Function


'''''''''''''''''''''''''''''
' onDisambiguationSignIn
'
' User chose to sign in, display the sign-in/register screen
Function onDisambiguationSignIn()
  tubiLog("SignInController.onDisambiguationSignIn")
  if m.skipSignInRegisterScreen = true
    'just go straight to the web code registration screen
    onRegister()
  else
    m.SignInRegister = CreateObject("roSGNode", "SignInRegisterScreen")
    m.SignInRegister.observeField("signInButtonSelected", "onSignIn")
    m.SignInRegister.observeField("registerButtonSelected", "onRegister")
    pushScreen(m.SignInRegister)
  end if
End Function


'''''''''''''''''''''''''''''
' onDisambiguationGuestPass
' 
' User chose a guest pass, prompt them once more with a feature list
Function onDisambiguationGuestPass()
  ' if m.skipContinueScreen = true
  if getExperimentValue("UserNamespace", "roku_continue_screen") = 0
    m.top.guestPass = true
  else
    m.ContinueAsGuest = CreateObject("roSGNode", "ContinueAsGuestScreen")
    m.ContinueAsGuest.observeField("signInButtonSelected", "onContinueSignIn")
    m.ContinueAsGuest.observeField("guestPassButtonSelected", "onContinueGuestPass")
    pushScreen(m.ContinueAsGuest)
  end if
End Function


'''''''''''''''''''''''''''''
' onContinueGuestPass
'
' User really wants a guest pass, set a field so the parent can show content
Function onContinueGuestPass()
  tubiLog("SignInController.onContinueGuestPass")
  m.top.guestPass = true
End Function


'''''''''''''''''''''''''''''
' onContinueSignIn
'
' At continuation screen, user decided to log in after all
Function onContinueSignIn()
  tubiLog("SignInController.onContinueSignIn")
  if m.skipSignInRegisterScreen = true
    'just go straight to the web code registration screen
    onRegister()    
  else
    m.SignInRegister = CreateObject("roSGNode", "SignInRegisterScreen")
    m.SignInRegister.observeField("signInButtonSelected", "onSignIn")
    m.SignInRegister.observeField("registerButtonSelected", "onRegister")
    pushScreen(m.SignInRegister)
  end if
End Function


'''''''''''''''''''''''''''''
' onSignIn
'
' User wants to enter credentials to sign in
Function onSignIn()
  tubiLog("SignInController.onSignIn")
  m.EmailPasswordScreen = CreateObject("roSGNode", "SignInEmailPasswordScreen")
  m.EmailPasswordScreen.observeField("signInSuccess", "onSignInSuccess")
  pushScreen(m.EmailPasswordScreen)
End Function


'''''''''''''''''''''''''''''
' onRegister
'
' User wants to register (or sign-in) via the web site
Function onRegister()
  tubiLog("SignInController.onRegister")
  m.RegisterInstructions = CreateObject("roSGNode", "RegisterInstructionsScreen")
  m.RegisterInstructions.observeField("registerSuccess", "onRegisterSuccess")
  pushScreen(m.RegisterInstructions)
End Function


'''''''''''''''''''''''''''''
' onRegisterSuccess
'
' User has successfully registered, set a field to redirect to content
Function onRegisterSuccess()
  tubiLog("SignInController.onRegisterSuccess")
  m.top.registered = true
End Function

'''''''''''''''''''''''''''''
' onSignInSuccess
'
' User has successfully signed in, set a field to redirect to content
Function onSignInSuccess()
  tubiLog("SignInController.onSignInSuccess")
  m.top.signedIn = true
End Function
