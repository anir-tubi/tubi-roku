Function init()
  m.top.observeField("focusedChild", "onFocus")
  m.Disambiguation = CreateObject("roSGNode", "SignInDisambiguationScreen")
  m.Disambiguation.setFocus(true)
  m.Disambiguation.observeField("signInButtonSelected", "onDisambiguationSignIn")
  m.Disambiguation.observeField("guestPassButtonSelected", "onDisambiguationGuestPass")
  m.Background = m.top.findNode("SignInBackground")
  m.Background.color = m.global.constants.ui.colors.backgroundColor

  initScreenStack(m.top.findNode("ScreenStack"))
  pushScreen(m.Disambiguation)
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


'''''''''''''''''''''''''''''
' onDisambiguationSignIn
'
' User chose to sign in, display the sign-in/register screen
Function onDisambiguationSignIn()
  tubiLog("SignInController.onDisambiguationSignIn")
  m.SignInRegister = CreateObject("roSGNode", "SignInRegisterScreen")
  m.SignInRegister.observeField("signInButtonSelected", "onSignIn")
  m.SignInRegister.observeField("registerButtonSelected", "onRegister")
  pushScreen(m.SignInRegister)
End Function


'''''''''''''''''''''''''''''
' onDisambiguationGuestPass
' 
' User chose a guest pass, prompt them once more with a feature list
Function onDisambiguationGuestPass()
  tubiLog("SignInController.onDisambiguationGuestPass")
  m.ContinueAsGuest = CreateObject("roSGNode", "ContinueAsGuestScreen")
  m.ContinueAsGuest.observeField("signInButtonSelected", "onContinueSignIn")
  m.ContinueAsGuest.observeField("guestPassButtonSelected", "onContinueGuestPass")
  pushScreen(m.ContinueAsGuest)
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
  m.SignInRegister = CreateObject("roSGNode", "SignInRegisterScreen")
  m.SignInRegister.observeField("signInButtonSelected", "onSignIn")
  m.SignInRegister.observeField("registerButtonSelected", "onRegister")
  pushScreen(m.SignInRegister)
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
