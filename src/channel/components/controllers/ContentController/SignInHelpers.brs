''''''''''''''''''''''''
' startSignIn
'
' Defer to the sign-in controller for sign in experience
' @callbackAfterSignIn: function, the function to run after the signIn process is complete.
Function startSignIn(callbackAfterSignIn=invalid)

  tubiLog("SignInHelpers.startSignIn")
  
  m.callbackAfterSignIn = callbackAfterSignIn
  
  showActivationScreen()

End Function


' showRFIScreen is used to display the Request For Information modal
Function showRFIScreen()
  tubiLog("SignInHelpers.showRFIScreen")
  currentScreen = currentScreen()
  
  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: "ACTIVATION"
      pageOneof: m.Tracking.getAnalyticsPage(currentScreen.trackingPageInfo.pageType, currentScreen.trackingPageInfo.pageValues)
      dialog_action: "SHOW"
      dialog_sub_type: "email-prefill"
    }
  }
  m.trackingLoggingTask.trackEvent = dialogEvent

  if m.billing = invalid
    m.billing = CreateObject("roSGNode", "ChannelStore")
  end if
  m.billing.observeFieldScoped("userData", "onUserData")
  m.billing.requestedUserData = "email, firstName, lastName"
  m.billing.command = "getUserData"
  
End Function


' onUserData is the callback triggered when ChannelStore returns userData
Function onUserData()
  tubiLog("SignInHelpers.onUserData")
  currentScreen = currentScreen()
  m.billing.unobserveFieldScoped("userData")
  
  if m.billing.userData <> invalid

    dialogEvent = {
      type: "dialog"
      values: {
        dialog_type: "ACTIVATION"
        pageOneof: m.Tracking.getAnalyticsPage(currentScreen.trackingPageInfo.pageType, currentScreen.trackingPageInfo.pageValues)
        dialog_action: "ACCEPT_DELIBERATE"
        dialog_sub_type: "email-prefill"
      }
    }
    m.trackingLoggingTask.trackEvent = dialogEvent
    
    checkEmailExists()

  else

    dialogEvent = {
      type: "dialog"
      values: {
        dialog_type: "ACTIVATION"
        pageOneof: m.Tracking.getAnalyticsPage(currentScreen.trackingPageInfo.pageType, currentScreen.trackingPageInfo.pageValues)
        dialog_action: "DISMISS_DELIBERATE"
        dialog_sub_type: "email-prefill"
      }
    }
    m.trackingLoggingTask.trackEvent = dialogEvent
    showActivationScreen()
  end if
  
End Function


Function checkEmailExists()

  options = {}
  options.params = {
    email: m.billing.userData.email
  }
   
  requestInfo = m.userDeviceApi.emailExistsReqInfo(options)
  m.makeRequest({
    url: requestInfo.url
    requestType: m.constants.reqNames.emailExists
    options: requestInfo.options
    successCallback: onEmailExistsResponse
    errorCallback: onEmailExistsError
    responseType: "assocarray"
  })
  
End Function


' onEmailExistsResponse is the callback triggered when the emailExists API responds successfully
' @response : assocarray, the response of emailExists API in the form of AA
Function onEmailExistsResponse(response)

  email = m.billing.userData.email
  if response <> invalid and response.taken = true
    showExistingAccountFoundModal(email)
  else
    showSignUpScreen(email)
  end if

End Function


' onEmailExistsError is the callback triggered when the emailExists API fails
' @error : roSGNode, the error response of emailExists API in the form of AA
Function onEmailExistsError(error)

  accountEvent = {
    type: "account"
    values: {
      manip: "REGISTER_DEVICE"
      current: "EMAIL"
      message: "email-exists-error"
      status: "FAIL"
    }
  }
  m.trackingLoggingTask.trackEvent = accountEvent
  
  currentScreen = currentScreen()
  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: "ACTIVATION"
      pageOneof: m.Tracking.getAnalyticsPage(currentScreen.trackingPageInfo.pageType, currentScreen.trackingPageInfo.pageValues)
      dialog_action: "SHOW"
      dialog_sub_type: "email-exists-error"
    }
  }
    
  title =  getTranslation("dialog_defaultError_title")
  message = getTranslation("could_not_verify_email") + ". " + getTranslation("dialog_defaultError_description")
  buttons = [getTranslation("dialog_button_tryAgain"), getTranslation("dialog_button_cancel")]
  showSimpleModal(title, message, buttons, dialogEvent, m.trackingLoggingTask, checkEmailExists)

End Function


Function showExistingAccountFoundModal(email)

  currentScreen = currentScreen()
  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: "ACTIVATION"
      pageOneof: m.Tracking.getAnalyticsPage(currentScreen.trackingPageInfo.pageType, currentScreen.trackingPageInfo.pageValues)
      dialog_action: "SHOW"
      dialog_sub_type: "prefill-existing"
    }
  }
  title =  getTranslation("existing_account_found_title")
  message = email + " " + getTranslation("existing_account_found_description")
  buttons = [getTranslation("dialog_button_signIn")]
  showSimpleModal(title, message, buttons, dialogEvent, m.trackingLoggingTask, showSignInScreen, invalid)
  m.sSideNavCurrentScreen = currentScreen
  displayDefaultBackground()  

End Function


' showActivationScreen is used  to display ActivationCodeScreen screen
Function showActivationScreen()

  activationCodeScreen = CreateObject("roSGNode", "ActivationCodeScreen")
  activationCodeScreen.observeFieldScoped("activationSuccess", "onActivationSuccess")
  activationCodeScreen.observeFieldScoped("errorType", "onRegTaskError")
  pushScreen(activationCodeScreen, true, true)
  m.sSideNavCurrentScreen = currentScreen()
  displayDefaultBackground()
  
End Function


' showSignInScreen is used to display signIn screen
Function showSignInScreen()
  email = m.billing.userData.email

  signInScreen = CreateObject("roSGNode", "SignInScreen")
  signInScreen.id = m.constants.ui.screenIds.signInScreen
  signInScreen.username = email
  signInScreen.observeFieldScoped("signInSelected", "onSignInSelected")
  signInScreen.observeFieldScoped("staticPageSelected", "onStaticPageSelected")
  pushScreen(signInScreen, true, true)
  m.sSideNavCurrentScreen = currentScreen()
  displayDefaultBackground()

End Function


' showSignUpScreen is used to display signUp screen
' @email : string, email of the user which is associated on their roku account
Function showSignUpScreen(email)

  signUpScreen = CreateObject("roSGNode", "SignUpScreen")
  signUpScreen.id = m.constants.ui.screenIds.signUpScreen
  signUpScreen.username = email
  signUpScreen.observeFieldScoped("signUpSelected", "onSignUpSelected")
  signUpScreen.observeFieldScoped("signInSelected", "showActivationScreen")
  signUpScreen.observeFieldScoped("staticPageSelected", "onStaticPageSelected")
  pushScreen(signUpScreen, true, true)
  m.sSideNavCurrentScreen = currentScreen()
  displayDefaultBackground()

End Function


' onStaticPageSelected callback is triggered when user selects static links on signUp/signIn screens
Function onStaticPageSelected(evt)

  staticPageSelected = evt.getData()
  ' sending static page name(ToS/PP/DoNotSellMyInfo) & screen level
  currentScreen = currentScreen()
  pageSource = ""
  if currentScreen <> invalid and currentScreen.getSubtype() = "SignUpScreen"
    pageSource = m.constants.ui.screenIds.signUpScreen
  else if currentScreen <> invalid and currentScreen.getSubtype() = "SignInScreen"
    pageSource = m.constants.ui.screenIds.signInScreen
  end if
  showSettingsScreen(staticPageSelected, 150, pageSource)

End Function


' onSignUpSelected callback is triggered when user selects continue button on SignUp Screen
' @evt : roSGNodeEvent, it contains password
Function onSignUpSelected(evt)

  signUpSelected = evt.getData()
  
  options = {}
  options.body = {
    platform: m.constants.platform  
    device_id: m.constants.deviceInfo.deviceId
    credentials: {
      email: m.billing.userData.email
      password: signUpSelected.password
      gender: ""
      first_name: m.billing.userData.firstname
      last_name: m.billing.userData.lastname
      birthday: ""
    }
  }
  
  requestInfo = m.userDeviceApi.signUpReqInfo(options)
  m.makeRequest({
    url: requestInfo.url
    requestType: m.constants.reqNames.signUp
    options: requestInfo.options
    successCallback: onSignUpResponse
    errorCallback: onSignUpError
    responseType: "assocarray"
  })
    
End Function


' onSignUpResponse callback is triggered when the sign up is success
' @response : assocarray, the response of signUp API in the form of AA
Function onSignUpResponse(response)

  m.trackingLoggingTask.trackEvent = {
    type: "account"
    values: {
      manip: "SIGNUP"
      current: "EMAIL"
      status: "SUCCESS"
    }
  }
  onActivationSuccess()

End Function


' onSignUpError callback is triggered when the sign up is failed
' @error : assocarray, the error response of signUp API in the form of AA
Function onSignUpError(error)

  tubiLog("SignUpHelpers.onSignUpError")
  accountEvent = {
    type: "account"
    values: {
      manip: "SIGNUP"
      message: "signup-failed"
      current: "EMAIL"
      status: "FAIL"
    }
  }
  
  m.trackingLoggingTask.trackEvent = accountEvent
  
  currentScreen = currentScreen()
  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: "ACTIVATION"
      pageOneof: m.Tracking.getAnalyticsPage(currentScreen.trackingPageInfo.pageType, currentScreen.trackingPageInfo.pageValues)
      dialog_action: "SHOW"
      dialog_sub_type: "signup-failed"
    }
  }
  
  title =  getTranslation("dialog_defaultError_title")
  message = getTranslation("could_not_verify_email") + ". " + getTranslation("dialog_defaultError_description")
  buttons = [getTranslation("dialog_button_tryAgain"), getTranslation("dialog_button_cancel")]
  showSimpleModal(title, message, buttons, dialogEvent, m.trackingLoggingTask, retrySignUp)

End Function


Function retrySignUp()

  currentScreen = currentScreen()
  if currentScreen <> invalid and currentScreen.getSubtype() =  "SignUpScreen"
    currentScreen.retrySignUp = true
  end if

End Function


' onSignInSelected callback is triggered when user selects continue button on SignIn Screen
' @evt : roSGNodeEvent, it contains password
Function onSignInSelected(evt)

  signInSelected = evt.getData()
  
  options = {}
  options.body = {
    platform: m.constants.platform  
    device_id: m.constants.deviceInfo.deviceId
    type: "email"
    credentials: {
      email: m.billing.userData.email
      password: signInSelected.password
    }
  }
  
  requestInfo = m.userDeviceApi.signInReqInfo(options)
  m.makeRequest({
    url: requestInfo.url
    requestType: m.constants.reqNames.signIn
    options: requestInfo.options
    successCallback: onSignInResponse
    errorCallback: onSignInError
    responseType: "assocarray"
  })  

End Function


' onSignInResponse callback is triggered when the sign In is success
' @response : assocarray, the response of signIn API in the form of AA
Function onSignInResponse(response)

  m.trackingLoggingTask.trackEvent = {
    type: "account"
    values: {
      manip: "SIGNIN"
      current: "EMAIL"
      status: "SUCCESS"
    }
  }
  onActivationSuccess()

End Function


' onSignInError callback is triggered when the sign In is failed
' @error : assocarray, the error response of signIn API in the form of AA
Function onSignInError(error)

  accountEvent = {
    type: "account"
    values: {
      manip: "SIGNIN"
      status: "FAIL"
      message: "invalid_password"
      current: "EMAIL"
    }
  }
  
  m.trackingLoggingTask.trackEvent = accountEvent

  currentScreen = currentScreen()
  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: "ACTIVATION"
      pageOneof: m.Tracking.getAnalyticsPage(currentScreen.trackingPageInfo.pageType, currentScreen.trackingPageInfo.pageValues)
      dialog_action: "SHOW"
      dialog_sub_type: "invalid_password"
    }
  }

  title =  getTranslation("invalid_password_title")
  invalidPasswordDesc = getTranslation("enter_password_dialog_description")
  forgotPasswordDesc = getTranslation("forgot_password_text") + " " + getTranslation("forgot_password_link")
  message = invalidPasswordDesc + chr(10) + m.billing.userData.email + chr(10) +  chr(10) + forgotPasswordDesc
  buttons = [getTranslation("re-enter_password_button")]
  showSimpleModal(title, message, buttons, dialogEvent, m.trackingLoggingTask, onReEnterPasswordSelected, onReEnterPasswordSelected)

End Function


' onReEnterPasswordSelected callback is triggered when user selects Re-Enter password button on invalid password modal
Function onReEnterPasswordSelected()

  currentScreen = currentScreen()
  if currentScreen <> invalid and currentScreen.getSubtype() =  "SignInScreen"
    currentScreen.resetFocus = true
  end if

End Function


Function getActivationCodeScreen()
  screen = invalid
  if currentScreen() <> invalid and currentScreen().getSubtype() =  "ActivationCodeScreen"
    screen = currentScreen()
  end if

  return screen
End Function


'''''''''''''''''''''''''
' onRegTaskError
'
' An error was recorded by the registrationCodeTask so let the user know
Function onRegTaskError(evt)

  sSubtypeCode = ""

  sEventName = evt.getData()
  if sEventName = "expire"
    title = getTranslation("dialog_signIn_activationCodeExpired_title")
    message = getTranslation("dialog_signIn_activationCodeExpired_description")
    sSubtypeCode = m.constants.errors.subtypes.expireError
  else if sEventName = "poll"
    title = getTranslation("error_signIn_connectionError_title")
    message = getTranslation("error_signIn_connectionError_description")
    sSubtypeCode = m.constants.errors.subtypes.networkError
  else if sEventName = "code"
    title = getTranslation("error_signIn_connectionErrorFetch_title")
    message = getTranslation("error_signIn_connectionErrorFetch_description")
    sSubtypeCode = m.constants.errors.subtypes.fetchError
  else
    title = getTranslation("error_signIn_activationCodeGeneral_title")
    message = getTranslation("error_signIn_activationCodeGeneral_description")
  end if
  
  userErrorCode = getUserFacingErrorCode(m.constants.errors.context.activateScreen, sSubtypeCode)
  
  authPageValues = {
    auth_action:  "ACTIVATION"  'Action enum
  }
  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: "REGISTRATION"
      pageOneof: m.Tracking.getAnalyticsPage("auth_page", authPageValues)
      dialog_action: "SHOW"
      dialog_sub_type: userErrorCode
    }
  }

  modalInfo = {
    title: title
    message: getErrorMessage(message, userErrorCode)
    openTrackEvent: dialogEvent
    trackingTask: m.trackingLoggingTask
  }
  showErrorModal(modalInfo, onErrorButtonTryAgainPress, invalid, onErrorButtonCancelPress, invalid, [getTranslation("dialog_button_tryAgain"), getTranslation("dialog_button_skip")])
End Function


'''''''''''''''''''''''''
' onErrorButtonCancelPress
'
' Respond the user selecting the cancel button on the error modal
Function onErrorButtonCancelPress()
  screen = getActivationCodeScreen()
  if screen <> invalid
    screen.getActivationCode = false
  end if
  popScreen(true, true)
End Function


'''''''''''''''''''''''''
' onErrorButtonTryAgainPress
'
' Respond the user selecting the try again button on the error modal
Function onErrorButtonTryAgainPress()
  screen = getActivationCodeScreen()
  if screen <> invalid
    screen.getActivationCode = true
  end if
End Function


'''''''''''''''''''''''''
' onActivationSuccess
'
' The sign-in flow has ended, do what comes next
Function onActivationSuccess()

  tubiLog("SignInHelpers.onActivationSuccess")
 ' retrieve the credentials on the AuthTask before starting the UI. This reduces jank.
  m.authInfoReceived = false
  if m.authTask <> invalid
    m.authTask.unobserveFieldScoped("authInfo")
  end if
  m.authTask = CreateObject("roSGNode", "AuthTask")
  
  callbackStr = convertFunctionToString(m.callbackAfterSignIn)
  if callbackStr <> ""
    m.authTask.observeFieldScoped("authInfo", callbackStr)
  else
    m.authTask.observeFieldScoped("authInfo", "onSideNavSignInSelected")
  end if
  
  m.callbackAfterSignIn = invalid ' setting to invalid to avoid callbacks
  
  m.authTask.functionName = "execInitializeUserData"
  m.authTask.control = "RUN"
  m.spinner.visible = true
  m.spinner.setFocus(true)
  
  'we remove the activation screen after auth info has been received
End Function


' onSideNavSignInSelected occurs when a user signs out or user signs in from the side nav or from settings side nav
Function onSideNavSignInSelected()
  tubiLog("SignInHelpers.onSideNavSignInSelected")
  ' AuthInfo may be invalid if authTask failed to log the user in
  m.global.authInfo = m.authTask.authInfo
  ' These will be empty parent nodes (no children) if user is not authenticated
  m.global.bookmarkIds = m.authTask.bookmarks
  m.global.historyIds = m.authTask.history

  m.authInfoReceived = true
  m.authTask.unobserveFieldScoped("authInfo")
  m.authTask = invalid

  ' if a user has just signed in, the default behavior is turn off kids mode UI
  ' if kids mode UI should be visible due to parenal controls, it will be turned on
  ' subsequently (most likely by startChannel())
  enableKidsModeUI(false)

  ' Here we notify screens that may exist, though we try to keep context
  '
  ' Transitions:
  '   signed in -> guest:
  '   guest -> signed in
  '
  '  Auth listeners:
  '    HomeScreen/CategoryScreen - load categories which are filtered by user auth
  '
  '  Bookmark/Queue listeners
  '    HomeScreen/CategoryScreen - user categories will be dirty
  '    DetailScreen - just history/bookmarks
  '    EpisodeScreen - history

  setDirtyUserCategories(m.constants.ui.categoryIds.queue)
  setDirtyUserCategories(m.constants.ui.categoryIds.history)
  setContentToRefresh(m.constants.ui.screenIds.tvScreen) 
  setContentToRefresh(m.constants.ui.screenIds.movieScreen) 
  setContentToRefresh(m.constants.ui.screenIds.espanolScreen)
  setContentToRefresh(m.constants.ui.screenIds.channelListScreen)
  setContentToRefresh(m.constants.ui.screenIds.categoryListScreen)

  refreshAllDetailScreens()

  homeScreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
  if homeScreen <> invalid
    homeScreen.loadAllCategories = true
  end if
      
  ' this happens when a user signs out or user signs in from the side nav or from settings side nav
  restartChannel()
  
End Function


' Is called only at app startup
Function onStartupAuthInfoReceived()
  tubiLog("SignInHelpers.onStartupAuthInfoReceived")
  ' AuthInfo may be invalid if authTask failed to log the user in
  m.global.authInfo = m.authTask.authInfo
  ' These will be empty parent nodes (no children) if user is not authenticated
  m.global.bookmarkIds = m.authTask.bookmarks
  m.global.historyIds = m.authTask.history

  m.authInfoReceived = true
  m.authTask.unobserveFieldScoped("authInfo")
  m.authTask = invalid

  startUserExperience()
End Function


' onQueueAfterSignIn - occurs after activation success via AddtoMyList
Function onQueueAfterSignIn()
  tubiLog("SignInHelpers.onQueueAfterSignIn")
  ' AuthInfo may be invalid if authTask failed to log the user in
  m.global.authInfo = m.authTask.authInfo
  ' These will be empty parent nodes (no children) if user is not authenticated
  m.global.bookmarkIds = m.authTask.bookmarks
  m.global.historyIds = m.authTask.history

  m.authTask.unobserveFieldScoped("authInfo")
  m.authTask = invalid

  ' setContentToRefresh is not required for homescreen as we are  fetching homescreen content right after adding into queue
  setContentToRefresh(m.constants.ui.screenIds.tvScreen) 
  setContentToRefresh(m.constants.ui.screenIds.movieScreen) 
  setContentToRefresh(m.constants.ui.screenIds.espanolScreen)
  setContentToRefresh(m.constants.ui.screenIds.channelListScreen)
  setContentToRefresh(m.constants.ui.screenIds.categoryListScreen)

  currentScreen = currentScreen()
  if currentScreen <> invalid and (currentScreen.getSubtype() =  "ActivationCodeScreen" or currentScreen.getSubtype() = "SignInScreen" or currentScreen.getSubtype() = "SignUpScreen")
    popScreen(true, true)
    currentScreen = currentScreen()
  end if
  
  m.spinner.visible = false

  if currentScreen <> invalid and currentScreen.getSubtype() = "DetailScreen"
    onAddToQueue(currentScreen, onBookmarkedAfterSignIn)
  else
    restartChannel()
  end if
  
End Function


' onParentalControlAfterSignIn - occurs after activation success via Parental Control
Function onParentalControlAfterSignIn()
  tubiLog("SignInHelpers.onParentalControlAfterSignIn")
  ' AuthInfo may be invalid if authTask failed to log the user in
  m.global.authInfo = m.authTask.authInfo
  ' These will be empty parent nodes (no children) if user is not authenticated
  m.global.bookmarkIds = m.authTask.bookmarks
  m.global.historyIds = m.authTask.history

  m.authTask.unobserveFieldScoped("authInfo")
  m.authTask = invalid

  currentScreen = currentScreen()
  if currentScreen <> invalid and (currentScreen.getSubtype() =  "ActivationCodeScreen" or currentScreen.getSubtype() = "SignInScreen" or currentScreen.getSubtype() = "SignUpScreen")
    popScreen(true, true)
    currentScreen = currentScreen()
  end if
  
  m.spinner.visible = false

  homeScreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
  if homeScreen <> invalid
    homeScreen.loadAllCategories = true
  end if

  if currentScreen <> invalid and currentScreen.getSubtype() = "SettingsScreen"
    setSignInInfo()
    currentScreen.setFocus(true)
  else
    restartChannel()
  end if
  
End Function