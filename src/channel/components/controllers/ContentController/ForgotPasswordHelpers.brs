' Display the the Forgot Password Processing Screen.
Function displayForgotPasswordProcessingScreen()
  TubiLog("ForgotPasswordHelpers.displayForgotPasswordProcessingScreen")

  currentScreen = getCurrentScreen()
  if currentScreen <> invalid AND currentScreen.getSubtype() = "SignInScreen"
    '//in case we go back to this screen via the screen stack, reset focus so it has the focus on the password textfield
    currentScreen.setFocusToPassword = true
  end if

  forgotPasswordProcessingScreen = CreateObject("roSGNode", "ForgotPasswordProcessingScreen")
  forgotPasswordProcessingScreen.id = m.constants.ui.screenIds.forgotPasswordProcessingScreen
  forgotPasswordProcessingScreen.username = m.email
  forgotPasswordProcessingScreen.observeFieldScoped("selectedDifferentEmail", "onForgotPasswordChangeEmailButtonSelected")
  forgotPasswordProcessingScreen.observeFieldScoped("signInSelected", "onForgotPasswordSignInButtonSelected")
  forgotPasswordProcessingScreen.observeFieldScoped("resendVerificationLink", "onResendVerificationLink")
  forgotPasswordProcessingScreen.observeFieldScoped("backButtonSelected", "onForgotPasswordBackButtonSelected")

  pushScreen(forgotPasswordProcessingScreen, true, true)

  '//send magic link
  createMagicLinkRequest(m.email)

End Function


'//When user presses the changeEmail button from the forgot password screen
Function onForgotPasswordChangeEmailButtonSelected()
  onStopAndClearEmailVerificationTimer()
  showEmailScreen()

  '//For analytics reasons, ensure the forgotPasswordScreen is not in the stack.
  '//This is also to ensure the proper screen is loaded when the user presses BACK from the emailScreen
  removeTopMostScreenWithIDFromStack(m.constants.ui.screenIds.forgotPasswordProcessingScreen)

End Function


'//When user presses the sign in button from the forgot password screen
Function onForgotPasswordSignInButtonSelected()
  onStopAndClearEmailVerificationTimer()
  popScreen()
End Function


'//When user presses the back button from the forgot password screen
Function onForgotPasswordBackButtonSelected()
  m.trackingLoggingTask.trackEvent = {
    type: "account"
    values: {
      manip: "CHANGEPW"
      current: "EMAIL"
      status: "FAIL"
      message: "user-cancel"
    }
  }

  onStopAndClearEmailVerificationTimer()
  popScreen()
End Function