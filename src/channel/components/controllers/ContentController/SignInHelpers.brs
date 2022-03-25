''''''''''''''''''''''''
' startSignIn
'
' Defer to the sign-in controller for sign in experience
' @callbackAfterSignIn: function, the function to run after the signIn process is complete.
Function startSignIn(callbackAfterSignIn=invalid)

  tubiLog("SignInHelpers.startSignIn")

  ' setting the default callback that occurs after a user signs in
  if callbackAfterSignIn = invalid
    callbackAfterSignIn = onSideNavSignInCompleted
  end if

  m.callbackAfterSignIn = callbackAfterSignIn
  showRFIScreen()

End Function


' showRFIScreen is used to display the Request For Information modal
Function showRFIScreen()
  tubiLog("SignInHelpers.showRFIScreen")

  suitest = m.constants.settings.suitest
  automaticActivation = m.constants.settings.automaticActivation
  settingsEmail = m.constants.settings.email
  settingsPassword = m.constants.settings.password
  mode = m.constants.settings.mode

  if mode <> "production" and isNonEmptyString(settingsEmail) = true and isNonEmptyString(settingsPassword) = true
    hideNavMenu()
    signUserIn(settingsEmail, settingsPassword)
  else if mode <> "production" and suitest = true and automaticActivation = true
    hideNavMenu()
    signUserUpForQAAutomation()
  else
    ' This is the path expected to be taken in production
    currentScreen = getCurrentScreen()

    if currentScreen <> invalid
      dialogEvent = {
        type: "dialog"
        values: {
          dialog_type: "REGISTRATION"
          pageOneof: m.Tracking.getAnalyticsPage(currentScreen.trackingPageInfo.pageType, currentScreen.trackingPageInfo.pageValues)
          dialog_action: "SHOW"
          dialog_sub_type: "email-prefill"
        }
      }
      m.trackingLoggingTask.trackEvent = dialogEvent
    end if

    ' RFI screen is showing only if the channelStore node is stored in m variable
    m.billing = CreateObject("roSGNode", "ChannelStore")
    m.billing.observeFieldScoped("userData", "onUserData")
    m.billing.requestedUserData = "email, firstName, lastName"
    m.billing.command = "getUserData"
  end if
End Function


' onUserData is the callback triggered when ChannelStore returns userData
Function onUserData(msg)
  tubiLog("SignInHelpers.onUserData")

  m.billing = invalid ' making m.billing as invalid to avoid using it another places

  currentScreen = getCurrentScreen()

  billing = msg.getRoSGNode()
  if billing <> invalid
    billing.unobserveFieldScoped("userData")
  end if

  if billing <> invalid and billing.userData <> invalid

    dialogEvent = {
      type: "dialog"
      values: {
        dialog_type: "REGISTRATION"
        pageOneof: m.Tracking.getAnalyticsPage(currentScreen.trackingPageInfo.pageType, currentScreen.trackingPageInfo.pageValues)
        dialog_action: "ACCEPT_DELIBERATE"
        dialog_sub_type: "email-prefill"
      }
    }
    m.trackingLoggingTask.trackEvent = dialogEvent

    email =  billing.userData.email
    input = {
      email : email
      emailType : "pre_fill"
    }
    checkEmailExists(input)

  else

    hideNavMenu(false)

    dialogEvent = {
      type: "dialog"
      values: {
        dialog_type: "REGISTRATION"
        pageOneof: m.Tracking.getAnalyticsPage(currentScreen.trackingPageInfo.pageType, currentScreen.trackingPageInfo.pageValues)
        dialog_action: "DISMISS_DELIBERATE"
        dialog_sub_type: "email-prefill"
      }
    }
    m.trackingLoggingTask.trackEvent = dialogEvent
    showEmailScreen()
  end if

End Function


' onEmailInputContinueSelected callback triggers when user clicks continue button from Email Input screen
Function onEmailInputContinueSelected(evt)

  screen =  evt.getRoSGNode()
  input = {
    email : screen.email
    emailType : "manual"
  }
  checkEmailExists(input)

End Function


' onEmailInputBackButtonSelected callback triggers when user clicks back button from Email Input screen
Function onEmailInputBackButtonSelected()

  m.trackingLoggingTask.trackEvent = {
    type: "account"
    values: {
      manip: "SIGNUP"
      current: "EMAIL"
      status: "FAIL"
      message: "user-cancel"
    }
  }
  popScreen(true, true)

End Function


' checkEmailExists function invokes API to check whether email already exits in Tubi
' @input : assocarray, will contain email(user's email) & emailType(manual/pre_fill)
Function checkEmailExists(input)

  email = input.email
  emailType = input.emailType

  options = {}
  options.params = {
    email: input.email
  }

  requestInfo = m.userDeviceApi.emailExistsReqInfo(options)
  m.makeRequest({
    url: requestInfo.url
    requestType: m.constants.reqNames.emailExists
    options: requestInfo.options
    successCallback: onEmailExistsResponse
    errorCallback: onEmailExistsError
    responseType: "assocarray"
    email: email
    emailType : emailType
  })

End Function


' onEmailExistsResponse is the callback triggered when the emailExists API responds successfully
' @response : assocarray, the response of emailExists API in the form of AA
Function onEmailExistsResponse(response)

  hideNavMenu()

  if response <> invalid
    parsedresponse = response.parsedresponse
    requestInput = response.requestInput

    if parsedresponse <> invalid and requestInput <> invalid
      if parsedresponse.taken = true
        showSignInScreen(requestInput.email)
      else
        m.authInfoReceived = false
        signUpCredentials = {}
        signUpCredentials.email =  requestInput.email
        signUpCredentials.emailType = requestInput.emailType
        signUpCredentials.firstName = Left(requestInput.email.split("@")[0], 20) ' limiting by 20 characters for the firstname field
        showAgeVerificationScreenAtSignUp(signUpCredentials)
      end if
    end if
  end if

End Function


' onEmailExistsError is the callback triggered when the emailExists API fails
' @errorResponse : roSGNode, the error response (code, requestInput) of emailExists API in the form of AA
Function onEmailExistsError(errorResponse)

  requestInput = errorResponse.requestInput

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
      dialog_type: "REGISTRATION"
      pageOneof: m.Tracking.getAnalyticsPage(currentScreen.trackingPageInfo.pageType, currentScreen.trackingPageInfo.pageValues)
      dialog_action: "SHOW"
      dialog_sub_type: "email-exists-error"
    }
  }

  title =  getTranslation("dialog_defaultError_title")
  message = getTranslation("could_not_verify_email") + ". " + getTranslation("dialog_defaultError_description")
  buttons = [getTranslation("dialog_button_tryAgain"), getTranslation("dialog_button_cancel")]
  simpleModalInfo = getSimpleModalInfo(title, message, buttons, dialogEvent, m.trackingLoggingTask, checkEmailExists, invalid, m.constants.instantResumeActions.restartApp)

  if simpleModalInfo <> invalid and simpleModalInfo.buttonInfo <> invalid and simpleModalInfo.buttonInfo[0] <> invalid
    simpleModalInfo.buttonInfo[0].callbackParams = {
      email : requestInput.email,
      emailType : requestInput.emailType
    }
  end if
  showModal(simpleModalInfo.modalInfo, simpleModalInfo.buttonInfo)
End Function


' showSignInScreen is used to display signIn screen
' @email : string,  (either taken from roku account or user entered email)
Function showSignInScreen(email)
  signInScreen = CreateObject("roSGNode", "SignInScreen")
  signInScreen.id = m.constants.ui.screenIds.signInScreen
  signInScreen.username = email
  signInScreen.observeFieldScoped("signInSelected", "onSignInSelected")
  signInScreen.observeFieldScoped("emailSelected", "onSignInScreenEmailSelected")
  signInScreen.observeFieldScoped("staticPageSelected", "onStaticPageSelected")
  pushScreen(signInScreen, true, true)
  displayDefaultBackground()
End Function


' onSignInScreenEmailSelected callback triggers when user selects the email text box
Function onSignInScreenEmailSelected()

  showEmailScreen()

End Function


' showEmailScreen is used to display Email screen for entering new email for signup
Function showEmailScreen()

  emailScreen = CreateObject("roSGNode", "EmailInputScreen")
  emailScreen.id = m.constants.ui.screenIds.emailScreen
  emailScreen.observeFieldScoped("continueSelected", "onEmailInputContinueSelected")
  emailScreen.observeFieldScoped("backButtonSelected", "onEmailInputBackButtonSelected")
  pushScreen(emailScreen, true, true)
  displayDefaultBackground()

End Function


' onStaticPageSelected callback is triggered when user selects static links on signUp/signIn screens
Function onStaticPageSelected(evt)

  staticPageSelected = evt.getData()
  ' sending static page name(ToS/PP/DoNotSellMyInfo) & screen level
  currentScreen = getCurrentScreen()
  pageSource = ""
  if currentScreen <> invalid and currentScreen.getSubtype() = "SignInScreen"
    pageSource = m.constants.ui.screenIds.signInScreen
  end if
  showSettingsScreen(staticPageSelected, 150, pageSource)

End Function


' onSignUpResponse callback is triggered when the sign up is success
' @_response: the response of signUp API in the form of AA
Function onSignUpResponse(_response)

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


' onSignInSelected callback is triggered when user selects continue button on SignIn Screen
' @evt : roSGNodeEvent, it contains password
Function onSignInSelected(evt)
  tubiLog("SignInHelpers.onSignInSelected")
  signInSelected = evt.getData()
  email = signInSelected.email
  password = signInSelected.password
  signUserIn(email, password)
End Function


Function signUserIn(email, password)
  options = {}
  options.body = {
    platform: m.constants.platform
    device_id: m.constants.deviceInfo.deviceId
    type: "email"
    credentials: {
      email: email
      password: password
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
    email: email
    emailType : password
  })
End Function


' onSignInResponse callback is triggered when the sign In is success
' @_response: assocarray, the response of signIn API in the form of AA
Function onSignInResponse(_response)

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
' @errorResponse : assocarray, the error response of signIn API in the form of AA
Function onSignInError(errorResponse)

  requestInput = errorResponse.requestInput

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
      dialog_type: "SIGNIN_ERROR"
      pageOneof: m.Tracking.getAnalyticsPage(currentScreen.trackingPageInfo.pageType, currentScreen.trackingPageInfo.pageValues)
      dialog_action: "SHOW"
      dialog_sub_type: "invalid_password"
    }
  }

  title =  getTranslation("invalid_password_title")
  invalidPasswordDesc = getTranslation("enter_password_dialog_description")
  forgotPasswordDesc = getTranslation("forgot_password_text") + " " + getTranslation("forgot_password_link")
  message = invalidPasswordDesc + chr(10) + requestInput.email + chr(10) +  chr(10) + forgotPasswordDesc
  buttons = [getTranslation("re-enter_password_button")]
  showSimpleInstantResumableModal(title, message, buttons, dialogEvent, m.trackingLoggingTask, onReEnterPasswordSelected, onReEnterPasswordSelected)

End Function


' onReEnterPasswordSelected callback is triggered when user selects Re-Enter password button on invalid password modal
Function onReEnterPasswordSelected()

  currentScreen = getCurrentScreen()
  if currentScreen <> invalid and currentScreen.getSubtype() =  "SignInScreen"
    currentScreen.resetFocus = true
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
  if (shouldShowAgeGate() and authInfo.hasAge <> true)
    m.spinner.visible = false
    signInInfo = invalid
    if authInfo <> invalid
      signInInfo = {}
      signInInfo.email  = authInfo.email
      signInInfo.firstname = authInfo.firstname
    end if
    showAgeVerificationScreenAtSignIn(signInInfo)
  else if m.callbackAfterSignIn <> invalid
    callbackAfterSignIn = m.callbackAfterSignIn
    m.callbackAfterSignIn = invalid ' setting to invalid to avoid future callbacks
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

  m.trackingLoggingTask.trackEvent = {
    type: "account"
    values: {
      manip: "SIGNOUT"
      current: "EMAIL"
      status: "SUCCESS"
    }
  }
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

  currentScreen = popScreenAfterSignInProcess()
  m.spinner.visible = false

  if currentScreen <> invalid and currentScreen.getSubtype() = "DetailScreen"
    onAddToQueue(currentScreen, onBookmarkedAfterSignIn)
  end if

End Function


' onCWRowAfterSignIn - occurs after activation success via CWRow on homescreen
Function onCWRowAfterSignIn()
  tubiLog("SignInHelpers.onCWRowAfterSignIn")

  setUiModeFromState()

  setContentToRefreshAllPersonalizedScreens()

  restartChannel()
End Function


Function onRegistrationProcessCompletedOnDetailsScreen()
  tubiLog("SignInHelpers.onRegistrationProcessCompletedOnDetailsScreen")
  setContentToRefreshAllPersonalizedScreens(false)

  currentScreen = popScreenAfterSignInProcess()
  m.spinner.visible = false

  if currentScreen <> invalid and currentScreen.getSubtype() = "DetailScreen"
    currentScreen.removeSignupButton = true
    currentScreen.refreshContent = true
    if currentScreen.isInFocusChain() = true
      currentScreen.setFocus(true)
    end if
  end if
End Function

' onParentalControlAfterSignIn - occurs after activation success via Parental Control
Function onParentalControlAfterSignIn()
  tubiLog("SignInHelpers.onParentalControlAfterSignIn")

  currentScreen = popScreenAfterSignInProcess()
  m.spinner.visible = false

  setContentToRefreshAllPersonalizedScreens()

  if currentScreen <> invalid and currentScreen.getSubtype() = "SettingsScreen"
    setSettingsScreenSignInInfo()
    currentScreen.setFocus(true)

    '//before signing in, the user selected a new parental setting, so take user to parental change screen
    setUiModeFromState()  '//in case the user cancels out of the confirm password screen, ensure the mode matches with the newly signed in user's saved mode
    onParentalSettingSelected()


    '//After the user signs in, display a modal so user knows they also need to enter their password to finish changing the parental control settings
    sTitle = getTranslation("dialog_parentalPassword_title")
    sDescription = getTranslation("dialog_parentalPassword_description")
    dialogEvent = {
      type: "dialog"
      values: {
        dialog_type: "SIGNIN_REQUIRED"
        pageOneof: m.Tracking.getAnalyticsPage(currentScreen.trackingPageInfo.pageType, currentScreen.trackingPageInfo.pageValues)
        dialog_action: "SHOW"
        dialog_sub_type: "password-request"
      }
    }
    showSimpleModal(sTitle, sDescription, [], dialogEvent, m.trackingLoggingTask)
  end if

End Function


' onSideNavMyListAfterSignIn - occurs after activation success via sidenav MyList
Function onSideNavMyListAfterSignIn()
  tubiLog("SignInHelpers.onSideNavMyListAfterSignIn")

  currentScreen = popScreenAfterSignInProcess()
  m.spinner.visible = false

  if currentScreen <> invalid and currentScreen.id = m.constants.ui.screenIds.categoryDetailsScreen and currentScreen.categoryId = m.constants.ui.categoryIds.queue
    ' this happens when user logs in via categoryDetailsScreen (queue/mylist)
    content = CreateObject("roSGNode", "CategoryContentNode")
    content.id = m.constants.ui.categoryIds.queue
    fetchCategoryDetails(content)
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


Function popScreenAfterSignInProcess()
  poppableScreenSubtypes = {
    "SignInScreen": true
    "SignUpScreen": true
    "EmailInputScreen": true
    "AgeVerificationScreen": true
  }

  count = m.screenStack.getChildCount()-1
  for i = count to 0 step -1
    screen = m.screenStack.getChild(i)
    if screen <> invalid and poppableScreenSubtypes[screen.getSubtype()] = true
      popScreen(false, false)
    else
      exit for
    end if
  end for
  currentScreen = getCurrentScreen()

  return currentScreen
End Function


Function signUserUpForQAAutomation()
  m.authInfoReceived = false
  dateTime = CreateObject("roDateTime")
  secondsFromEpoch = dateTime.AsSeconds()

  signInInfo = {
    email: "build_roku_" + secondsFromEpoch.ToStr() + "@tubi.tv"
    emailType: "manual"
    firstName:  "Automation"
    automation: true ' setting automation as true, so password will be set to 111111 during signup
  }
  birthdate = "2000-01-01"
  verifyAgeAtSignup(signInInfo, birthdate)
End Function
