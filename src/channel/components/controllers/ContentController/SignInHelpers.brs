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
  currentScreen = getCurrentScreen()
  
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
  currentScreen = getCurrentScreen()
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
  
  currentScreen = getCurrentScreen()
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

  currentScreen = getCurrentScreen()
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
  m.sSideNavCurrentScreen = getCurrentScreen()
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
  m.sSideNavCurrentScreen = getCurrentScreen()
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
  m.sSideNavCurrentScreen = getCurrentScreen()
  displayDefaultBackground()

End Function


' onStaticPageSelected callback is triggered when user selects static links on signUp/signIn screens
Function onStaticPageSelected(evt)

  staticPageSelected = evt.getData()
  ' sending static page name(ToS/PP/DoNotSellMyInfo) & screen level
  currentScreen = getCurrentScreen()
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
  
  currentScreen = getCurrentScreen()
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

  currentScreen = getCurrentScreen()
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

  currentScreen = getCurrentScreen()
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

  currentScreen = getCurrentScreen()
  if currentScreen <> invalid and currentScreen.getSubtype() =  "SignInScreen"
    currentScreen.resetFocus = true
  end if

End Function


Function getActivationCodeScreen()
  screen = invalid
  currentScreen = getCurrentScreen()
  if currentScreen <> invalid and currentScreen.getSubtype() =  "ActivationCodeScreen"
    screen = currentScreen
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
  m.authTask.observeFieldScoped("authInfo", "onPostSignInAuthInfoUpdated") 
  m.authTask.functionName = "execInitializeUserData"
  m.authTask.control = "RUN"
  m.spinner.visible = true
  m.spinner.setFocus(true)
  
  'we remove the activation screen after auth info has been received
End Function


Function onPostSignInAuthInfoUpdated()
  tubiLog("SignInHelpers.onPostSignInAuthInfoUpdated")
  authInfo = handleUpdatedAuth()
  if shouldShowAgeGate() and authInfo.hasAge <> true
    m.spinner.visible = false
    showAgeVerificationScreenAfterSignIn()
  else if m.callbackAfterSignIn <> invalid
    callbackAfterSignIn = m.callbackAfterSignIn
    m.callbackAfterSignIn = invalid ' setting to invalid to avoid callbacks
    callbackAfterSignIn()
  else
    ' this should not happen but restart the channel in case it somehow does
    restartChannel()
  end if
End Function


' onSideNavSignInCompleted occurs when a user signs out or user signs in from the side nav or from settings side nav
Function onSideNavSignInCompleted()
  tubiLog("SignInHelpers.onSideNavSignInCompleted")

  ' set the mode before any changes are done to the UI 
  setUiModeFromState()
  
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

  setContentToRefreshAllPersonalizedScreens()

  refreshAllDetailScreens()
  setSideNavSignedInItem(m.global.authInfo)
      
  ' this happens when a user signs out or user signs in from the side nav or from settings side nav
  restartChannel()

End Function


Function onSignOutCompleted()
  tubiLog("SignInHelpers.onSignOutCompleted")
  authInfo = handleUpdatedAuth()

  ' set the mode before any changes are done to the UI
  setUiMode(m.constants.ui.modes.standard)

  setContentToRefreshAllPersonalizedScreens()
  setSideNavSignedInItem(authInfo)
      
  ' this happens when a user signs out or user signs in from the side nav or from settings side nav
  restartChannel()
End Function


' Is called only at app startup
Function onStartupAuthInfoReceived()
  tubiLog("SignInHelpers.onStartupAuthInfoReceived")
  handleUpdatedAuth()
  startUserExperience()
End Function


' These are the basic actions taken after the user has signed in
' returns the AuthInfo
Function handleUpdatedAuth()
  ' AuthInfo may be invalid if authTask failed to log the user in
  authInfo = m.authTask.authInfo
  if shouldShowAgeGate()
    m.guestUserHasAgeInfo = m.authTask.guestUserHasAgeInfo
  end if
  m.global.authInfo = authInfo

  ' These will be empty parent nodes (no children) if user is not authenticated
  m.global.bookmarkIds = m.authTask.bookmarks
  m.global.historyIds = m.authTask.history
  m.authInfoReceived = true
  m.authTask.unobserveFieldScoped("authInfo")
  m.authTask = invalid

  setSideNavSignedInItem(authInfo)

  return authInfo
End Function



' onQueueAfterSignIn - occurs after activation success via AddtoMyList on Details page
Function onQueueAfterSignIn()
  tubiLog("SignInHelpers.onQueueAfterSignIn")

  ' setContentToRefresh is not required for homescreen as we are fetching homescreen content
  ' right after adding into queue when onBookmarkedAfterSignIn() is called.
  ' We need to enforce that content is added to queue first, before re-fetching the homescreen.
  setContentToRefreshAllPersonalizedScreens(false)

  m.spinner.visible = false

  currentScreen = getCurrentScreen()
  if currentScreen <> invalid and poppableScreenSubtypes[currentScreen.getSubtype()] = true
    popScreen(true, true)
    currentScreen = getCurrentScreen()
  end if

  if currentScreen <> invalid and currentScreen.getSubtype() = "DetailScreen"
    onAddToQueue(currentScreen, onBookmarkedAfterSignIn)
  end if

End Function


' onCWRowAfterSignIn - occurs after activation success via CWRow on homescreen
Function onCWRowAfterSignIn()
  tubiLog("SignInHelpers.onCWRowAfterSignIn")

  setContentToRefreshAllPersonalizedScreens()

  restartChannel()
End Function


' onParentalControlAfterSignIn - occurs after activation success via Parental Control
Function onParentalControlAfterSignIn()
  tubiLog("SignInHelpers.onParentalControlAfterSignIn")

  poppableScreenSubtypes = {
    "ActivationCodeScreen": true
    "SignInScreen": true
    "SignUpScreen": true
    "AgeVerificationScreen": true
  }

  currentScreen = getCurrentScreen()
  if currentScreen <> invalid and poppableScreenSubtypes[currentScreen.getSubtype()] = true
    popScreen(true, true)
    currentScreen = getCurrentScreen()
  end if
  
  m.spinner.visible = false
  
  setContentToRefreshAllPersonalizedScreens()

  if currentScreen <> invalid and currentScreen.getSubtype() = "SettingsScreen"
    setSettingsScreenSignInInfo()
    currentScreen.setFocus(true)
  end if
  
End Function


' onSideNavMyListAfterSignIn - occurs after activation success via sidenav MyList
Function onSideNavMyListAfterSignIn()
  tubiLog("SignInHelpers.onSideNavMyListAfterSignIn")

  currentScreen = getCurrentScreen()
  if currentScreen <> invalid and (currentScreen.getSubtype() = "ActivationCodeScreen" or currentScreen.getSubtype() = "SignInScreen" or currentScreen.getSubtype() = "SignUpScreen")
    popScreen(true, true)
    currentScreen = getCurrentScreen()
  end if
  
  m.spinner.visible = false

  if currentScreen <> invalid and currentScreen.id = "channelDetailScreen" and currentScreen.categoryId = m.constants.ui.categoryIds.queue
    ' this happens when user logs in via channelDetailScreen (queue/mylist)
    content = CreateObject("roSGNode", "CategoryContentNode")
    content.id = m.constants.ui.categoryIds.queue
    getChannelFromServer(currentScreen, content)
    setContentToRefreshAllPersonalizedScreens()
  else
    ' don't expect this to happen, keeping here as a fallback mechanism
    restartChannel()
  end if
End Function


' After the user clicks on the Sign In Menu item and then signs in, then this function should be called to display the home screen
Function onSignInAfterInitialContentScreen()
  reloadDefaultHomeScreenContent()
  showDefaultHomeScreen()
End Function