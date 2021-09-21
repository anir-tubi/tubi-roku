' For the AgeVerificationScreen helpers, a system of functions and callbacks, each for a specific flow,
' is used instead of keeping state on m. The tradeoff is that following the logic while reading is a
' little more difficult, but in return we theoretically get better maintainability and extensability.
' For example, if we want to update one flow, we don't have to worry about how the changes affect the
' other flows. With that in mind, the flows are "diagrammed" below:
'
' Flow 1) Needs age verification during SignIn
'   showAgeVerificationScreenAtSignIn() ->
'   showAgeVerificationScreen() ->
'   onAgeSubmittedAtSignIn() ->
'   verifyAgeAtSignIn() ->
'   verifyAge() -> one of
'     onAgeVerifiedAtSignIn() ->
'       onAgeVerified()
'     onAgeNotVerifiedAtSignIn() ->
'       onAgeNotVerified()
'
' Flow 2) Signed in user, needs age verification at channel launch if they do not have birthdate
'   showAgeVerificationScreenAtStartup() ->
'   showAgeVerificationScreen() ->
'   onAgeSubmittedAtStartup() ->
'   verifyAgeAtStartup() ->
'   verifyAge() -> one of
'     onAgeVerifiedAtStartup() ->
'       onAgeVerified()
'     onAgeNotVerifiedAtStartup() ->
'       onAgeNotVerified()
'
' Flow 3) Needs age verification during signUp
'   showAgeVerificationScreenAtSignUp() ->
'   showAgeVerificationScreen() ->
'   onAgeSubmittedAtSignUp() ->
'   verifyAgeAtSignUp()


' Occurs after a user signs in, but the user does not have a valid age associated with their account yet.
' @signInInfo: assocarray(email,firstName) default set to invalid. eg - (test@tubi.tv, test)
Function showAgeVerificationScreenAtSignIn(signInInfo = invalid as object)
  tubiLog("AgeVerificationScreenHelpers.showAgeVerificationScreenAtSignIn")
  showAgeVerificationScreen(onAgeSubmittedAtSignIn, signInInfo)
End Function


' Occurs for signedIn user when launching app and user does not have a valid age associated with their account yet.
' @signInInfo: assocarray(email,firstName) default set to invalid. eg - (test@tubi.tv, test)
Function showAgeVerificationScreenAtStartup(signInInfo = invalid as object)
  tubiLog("AgeVerificationScreenHelpers.showAgeVerificationScreenAtStartup")
  showAgeVerificationScreen(onAgeSubmittedAtStartUp, signInInfo)

  ' Roku requires a beacon to be fired before and after any user interaction screens prior
  ' to the home page being shown
  m.top.signalBeacon("AppDialogInitiate")
End Function


' Occurs during user signs up
' @signInInfo: assocarray(email,firstName,emailType) default set to invalid. eg - (test@tubi.tv, test, 'manual/pre_fill')
Function showAgeVerificationScreenAtSignUp(signInInfo = invalid as object)
  tubiLog("AgeVerificationScreenHelpers.showAgeVerificationScreenAtSignUp")
  showAgeVerificationScreen(onAgeSubmittedAtSignUp, signInInfo)
End Function


Function onAgeSubmittedAtSignIn(msg)
  onAgeSubmitted(msg, verifyAgeAtSignIn)
End Function


Function onAgeSubmittedAtStartup(msg)
  onAgeSubmitted(msg, verifyAgeAtStartup)
End Function


Function onAgeSubmittedAtSignUp(msg)
  onAgeSubmitted(msg, verifyAgeAtSignup)
End Function


Function verifyAgeAtSignIn(birthdate)
  verifyAge(birthdate, onAgeVerifiedAtSignIn, onAgeNotVerifiedAtSignIn)
End Function


Function verifyAgeAtStartup(birthdate)
  verifyAge(birthdate, onAgeVerifiedAtStartup, onAgeNotVerifiedAtStartup)
End Function


Function verifyAgeAtSignupWrapper(info)
  signInInfo = info.signInInfo
  birthdate = info.birthdate
  verifyAgeAtSignup(signInInfo, birthdate)
End Function


Function verifyAgeAtSignup(signInInfo, birthdate)

  if hasValidSignUpCredentials(birthdate, signInInfo) = true ' triggers when user signs up

    deviceInfo = CreateObject("roDeviceInfo")
    randomUUID = right(deviceInfo.GetRandomUUID(), 12) ' taking only 12 characters from right since GetRandomUUID() length is more

    usedEmailAsFirstName = false
    if signInInfo.emailType = "manual"
      usedEmailAsFirstName = true
    end if

    options = {}
    options.body = {
      platform: m.constants.platform  
      device_id: m.constants.deviceInfo.deviceId
      credentials: {
        email: signInInfo.email
        password: randomUUID 'used dummy password - user can change it by using forgot password
        gender: ""
        first_name: signInInfo.firstName
        last_name: ""
        birthday: birthdate
        email_type: signInInfo.emailType
        used_email_as_first_name: usedEmailAsFirstName
      }
    }
    
    requestInfo = m.userDeviceApi.signUpReqInfo(options)
    m.makeRequest({
      url: requestInfo.url
      requestType: m.constants.reqNames.signUp
      options: requestInfo.options
      successCallback: onSignUpResponse
      errorCallback: onAgeNotVerifiedAtSignup
      responseType: "assocarray"
      signInInfo: signInInfo
      birthdate: birthdate
    })
  else
    ' not expected to ever happen, so punt and start the app normally if it does
    startUserExperienceAsAgeNotVerified()
  end if

End Function


' @age: integer, the age as returned by the backend
Function onAgeVerifiedAtSignIn(age)
  tubiLog("AgeVerificationScreenHelpers.onAgeVerifiedAtSignIn")
  patchSignedInUserAge()
  onAgeVerified(age)
  callbackAfterSignIn = m.callbackAfterSignIn
  m.callbackAfterSignIn = invalid ' setting to invalid to avoid future callbacks
  callbackAfterSignIn()
End Function


' Functionality that occurs after the age verification screen is shown to the user when
' starting the app, and the age has been verified by the backend
' @age: integer, the age as returned by the backend
Function onAgeVerifiedAtStartup(age)
  tubiLog("AgeVerificationScreenHelpers.onAgeVerifiedAtStartup")
  patchSignedInUserAge()
  onAgeVerified(age)
  m.ageVerificationComplete = true

  ' Roku requires a beacon to be fired before and after any user interaction screens prior
  ' to the home page being shown
  ' Fire for successful age verified at startup.
  m.top.signalBeacon("AppDialogComplete")

  startUserExperience()
End Function


Function onAgeNotVerifiedAtSignIn(err)
  if err <> invalid and err.code <> invalid
    if err.code = 422 or err.code = 451
      handle_422_451_error(restartChannelAfterAgeVerification) ' happens when user enters age less than 13
    else
      handleNetworkError(err, verifyAgeAtSignIn, startUserExperienceAsAgeNotVerified) ' happens when ther is network failure or some backend issue
    end if
  end if  
End Function


Function onAgeNotVerifiedAtStartup(err)
  if err <> invalid and err.code <> invalid
    if err.code = 422 or err.code = 451
      handle_422_451_error(restartChannelAfterAgeVerificationOnStartUp) ' happens when user enters age less than 13
    else
      handleNetworkError(err, verifyAgeAtStartUp, startUserExperienceAsAgeNotVerifiedOnStartUp) ' happens when ther is network failure or some backend issue
    end if
  end if
End Function


Function onAgeNotVerifiedAtSignup(err)
  if err <> invalid and err.code <> invalid
    if err.code = 422 or err.code = 451
      handle_422_451_error(restartChannelAfterAgeVerification) ' happens when user enters age less than 13
    else if err.code = 403
      handle_403_error() ' happens when user enters invalid email domain
    else
      handleNetworkErrorOnSignUp(err) ' happens when ther is network failure or some backend issue
    end if
  end if  
End Function


' some network or API issue
' show generic "oops an error occurred" modal and allow users to retry/cancel
Function handleNetworkError(err, tryAgainCallback, cancelCallback)

  birthdate = ""
  if err.requestNode <> invalid and err.requestNode.input <> invalid 
    inputData = err.requestNode.input
    if inputData.birthdate <> invalid
      birthdate = inputData.birthdate
    end if
  end if

  screen = getCurrentScreen()
  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: "NETWORK_ERROR" 'DialogType enum
      pageOneof: m.Tracking.getAnalyticsPage(screen.trackingPageInfo.pageType, screen.trackingPageInfo.pageValues)
      dialog_action: "SHOW"
      dialog_sub_type: "age-verification-err"
    }
  }

  modalInfo = {
    message: getTranslation("screenAgeVerification_network_issue")
    openTrackEvent: dialogEvent
    trackingTask: m.trackingLoggingTask
  }

  buttons = [getTranslation("dialog_button_tryAgain"), getTranslation("dialog_button_cancel")]
  showErrorModal(modalInfo, tryAgainCallback, birthdate, cancelCallback, invalid, buttons)
  
End Function


' some network or API issue
' show generic "oops an error occurred" modal and allow users to retry/cancel
Function handleNetworkErrorOnSignUp(err)

  signInInfo = {}
  birthdate = ""

  if err.requestNode <> invalid and err.requestNode.input <> invalid 
    inputData = err.requestNode.input
    if inputData.signInInfo <> invalid
      signInInfo = inputData.signInInfo
    end if
    if inputData.birthdate <> invalid
      birthdate = inputData.birthdate
    end if
  end if

  screen = getCurrentScreen()
  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: "NETWORK_ERROR" 'DialogType enum
      pageOneof: m.Tracking.getAnalyticsPage(screen.trackingPageInfo.pageType, screen.trackingPageInfo.pageValues)
      dialog_action: "SHOW"
      dialog_sub_type: "signup-failed"
    }
  }

  modalInfo = {
    message: getTranslation("screenAgeVerification_network_issue")
    openTrackEvent: dialogEvent
    trackingTask: m.trackingLoggingTask
  }

  verifyAgeAtSignupParams = {}
  verifyAgeAtSignupParams.signInInfo = signInInfo
  verifyAgeAtSignupParams.birthdate = birthdate

  cancelSignUpButton = getTranslation("dialog_button_cancel") + " " + getTranslation("dialog_button_signUp")
  buttons = [getTranslation("dialog_button_tryAgain"), cancelSignUpButton]

  showErrorModal(modalInfo, verifyAgeAtSignupWrapper, verifyAgeAtSignupParams, startUserExperienceAsAgeNotVerified, invalid, buttons)
End Function


' triggered when user enters age less than 13 on agegate screen
Function handle_422_451_error(callback)

  Request = TubiRequest(m.constants.settings)
  Auth = TubiAuth(m.constants, Request)

  ' 422: the user is not old enough to use Tubi except in kids mode according to COPPA (US only)
  ' 451: the user is not old enough to use Tubi except in kids mode for some international reasons
  m.guestUserHasAgeInfo = Auth.setGuestUserHasAgeInfo(false)
  Auth.logout()
  m.global.authInfo = invalid
  callback() ' redirecting to kidsMode before showing enterKidsMode modal, so that user will be aware what the experience will be

  currentScreen = getCurrentScreen()
  if m.uiMode = m.constants.ui.modes.kidsAgeGate
    title = getTranslation("dialog_kidsWelcome_title")
    message = getTranslation("dialog_kidsWelcomeAgeGate_description")
    dialogEvent = {
      type: "dialog"
      values: {
        dialog_type: "ENTER_KIDS_MODE" 'DialogType enum
        pageOneof: m.Tracking.getAnalyticsPage(currentScreen.trackingPageInfo.pageType, currentScreen.trackingPageInfo.pageValues)
        dialog_action: "SHOW"
        dialog_sub_type: "welcome-age-gate"
      }
    }
    showSimpleModal(title, message, [], dialogEvent, m.trackingLoggingTask)
  end if

End Function


' this happens during signup flow, if users enters invalid email domain
Function handle_403_error()

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

  popScreen(false, false) ' removing ageGate screen as user has to enter valid email 

  currentScreen = getCurrentScreen()
  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: "SIGNUP_ERROR"
      pageOneof: m.Tracking.getAnalyticsPage(currentScreen.trackingPageInfo.pageType, currentScreen.trackingPageInfo.pageValues)
      dialog_action: "SHOW"
      dialog_sub_type: "signup-failed"
    }
  }

  title =  getTranslation("dialog_defaultError_title")
  message = getTranslation("could_not_verify_email") + ". " + getTranslation("dialog_defaultError_description")
  buttons = [getTranslation("dialog_button_ok")]
  showSimpleModal(title, message, buttons, dialogEvent, m.trackingLoggingTask, invalid)

End Function


' showAgeVerificationScreen is used to display create AgeVerificationScreen and display
Function showAgeVerificationScreen(ageSubmittedCallback, signInInfo = invalid as object)
  callbackString = convertFunctionToString(ageSubmittedCallback)
  ageVerificationScreen = CreateObject("roSGNode", "AgeVerificationScreen")
  ageVerificationScreen.id = m.constants.ui.screenIds.ageVerificationScreen
  ageVerificationScreen.backgroundUriList = [m.defaultBackgroundUri]
  ageVerificationScreen.signInInfo = signInInfo
  ageVerificationScreen.observeFieldScoped("ageSubmitted", callbackString)
  ageVerificationScreen.observeFieldScoped("backButtonPressed", "onBackButtonPressed")
  displayDefaultBackground()
  pushScreen(ageVerificationScreen, true, true)
End Function


' @msg: roSGNodeEvent, taken from observing ageVerificationScreen.ageSubmitted
' @verifyAgeCallback: function, a wrapper function around verifyAge (ie. verifyAgeAtStartup)
Function onAgeSubmitted(msg, verifyAgeCallback)
  tubiLog("AgeVerificationScreenHelpers.onAgeSubmitted")
  ageVerificationScreen = msg.getRoSGNode()
  birthdate = ageVerificationScreen.birthdate
  signInInfo = ageVerificationScreen.signInInfo

  ' send RequestForInfo analytics event
  selectorValues = {
    options: [birthdate]
    selections: [1]
    string_selector_type: "BIRTHDAY" 'StringSelectorComponent.type enum
    sub_type: "age-gate"
  }

  analyticsEvent = {
    type: "request_for_info"
    values: {
      request_for_info_action: "BIRTHDAY"
      prompt: "Enter your date of birth"
      selectorOneOf: m.Tracking.getAnalyticsSelector("string_selector", selectorValues)
    }
  }

  m.trackingLoggingTask.trackEvent = analyticsEvent

  if verifyAgeCallback <> invalid and verifyAgeCallback = verifyAgeAtSignup
    verifyAgeCallback(signInInfo, birthdate)
  else if verifyAgeCallback <> invalid
    verifyAgeCallback(birthdate)
  else
    ' not expected to ever happen, so punt and start the app normally if it does
    startUserExperienceAsAgeNotVerified()  
  end if

End Function


' @birthdate: string, birthdate with format "YYYY-MM-DD"
' @successCallback: function, the function to be called after the age has been verified by the backend.
'                             successCallback is passed an integer representing the age as returned
'                             by the backend.
' @errorCallback: function, the function to be called if an HTTP error code is returned by the backend
'                           while attempting to verify the age.
Function verifyAge(birthdate, successCallback, errorCallback)
  tubiLog("AgeVerificationScreenHelpers.verifyAge")

  if isString(birthdate) and birthdate <> "" 'triggers when signedIn user gives age information

    confirmBirthdateRequestInfo = m.UserDeviceApi.deviceRegisterInfo(birthdate)
    m.makeRequest({
      url: confirmBirthdateRequestInfo.url
      requestType: m.constants.reqNames.deviceRegister
      options: confirmBirthdateRequestInfo.options
      successCallback: successCallback
      errorCallback: errorCallback
      responseType: "integer"
      birthdate: birthdate  ' custom field to pass through to the callback
    })

  else
    ' not expected to ever happen, so punt and start the app normally if it does
    startUserExperienceAsAgeNotVerified()
  end if
End Function


' @birthdate: string, birthdate with format "YYYY-MM-DD"
' @signInInfo: assocarray, it contains email(String), firstname(String), signedIn(boolean), emailType(String) 
'
' returns: boolean
'  
Function hasValidSignUpCredentials(birthdate, signInInfo)

  isValid = false

  email = ""
  firstName = ""
  emailType = ""

  if signInInfo <> invalid
    email = signInInfo.email
    firstName = signInInfo.firstName
    emailType = signInInfo.emailType
  end if

  if isString(birthdate) and birthdate <> "" and email <> "" and firstName <> "" and emailType <> ""
    isValid = true
  end if

  return isValid

End Function


' @age: integer, the age as returned by the backend
Function onAgeVerified(age)
  tubiLog("AgeVerificationScreen.onAgeVerified")
  m.spinner.visible = true

  Request = TubiRequest(m.constants.settings)
  Auth = TubiAuth(m.constants, Request)

  if m.global.authInfo <> invalid and age >= m.constants.ui.ages.ageGate
    ' age verified for logged in user so update auth info
    updatedAuthInfo = Auth.updateAuthInfoWithAge(true)
    m.global.authInfo = updatedAuthInfo
  else if m.global.authInfo = invalid and age >= m.constants.ui.ages.ageGate
    ' age verified for guest user, so store age verification
    m.guestUserHasAgeInfo = Auth.setGuestUserHasAgeInfo(true)
  end if
End Function


Function restartChannelAfterAgeVerificationOnStartUp()

  ' Roku requires a beacon to be fired before and after any user interaction screens prior
  ' to the home page being shown.
  ' Fire for not age verified at startup.
  m.top.signalBeacon("AppDialogComplete")

  restartChannelAfterAgeVerification()
End Function


Function startUserExperienceAsAgeNotVerifiedOnStartUp()
  m.authInfoReceived = true
  m.ageVerificationComplete = true
  m.spinner.visible = true

  ' Roku requires a beacon to be fired before and after any user interaction screens prior
  ' to the home page being shown.
  ' Fire for not age verified at startup.
  m.top.signalBeacon("AppDialogComplete")

  startUserExperience()
End Function


Function startUserExperienceAsAgeNotVerified()
  m.authInfoReceived = true
  m.ageVerificationComplete = true
  m.spinner.visible = true
  startUserExperience()
End Function


Function onBackButtonPressed(msg)
  ageVerificationScreen = msg.getRoSGNode()
  displayExitModal(ageVerificationScreen.trackingPageInfo)
End Function


Function onBirthdayCheckSuccess(hasAgeInfo)
  tubiLog("AgeVerificationScreenHelpers.onBirthdayCheckSuccess")
  
  if hasAgeInfo <> invalid and hasAgeInfo.hasAge = true
    Request = TubiRequest(m.constants.settings)
    Auth = TubiAuth(m.constants, Request)
    updatedAuthInfo = Auth.updateAuthInfoWithAge(true)
    m.global.authInfo = updatedAuthInfo

    if updatedAuthInfo.hasAge = true
      m.ageVerificationComplete = true
    end if

    startUserExperience()
  else

    signInInfo = {}
    authInfo = m.global.authInfo
    if authInfo <> invalid and authInfo.firstname <> invalid
      signInInfo.email  = authInfo.email
      signInInfo.firstname = authInfo.firstname
    end if

    showContentGroup()
    m.spinner.visible = false
    showAgeVerificationScreenAtStartup(signInInfo)
  end if
End Function


Function onBirthdayCheckError(errorInfo)
  tubiLog("AgeVerificationScreenHelpers.onBirthdayCheckError")
  if errorInfo <> invalid
    code = errorInfo.code
    Request = TubiRequest(m.constants.settings)
    Auth = TubiAuth(m.constants, Request)

    if code = 422 or code = 451
      ' 422 signifies the user has birthdate under age 13 (COPPA)
      ' 451 signifies the user is too young internationally
      ' logout the user and prepare them for age gated kids mode
      Auth.logout()
      m.global.authInfo = invalid
      Auth.setGuestUserHasAgeInfo(false)
      startUserExperience()
    else
      ' all other error codes, log the user out and show "couldn't log you in error message"
      Auth.logout()
      m.global.authInfo = invalid

      userErrorCode = getUserFacingErrorCode(12.toStr(), 100.toStr(), code.toStr())
      message = getTranslation("error_check_birthdate_description")

      ' there is no screen on the stack at this point, but the dialog event requires a screen,
      ' so stub a faux screen for tracking purposes
      tempAgeScreen = CreateObject("roSGNode", "AgeVerificationScreen")

      dialogEvent = {
        type: "dialog"
        values: {
          dialog_type: "NETWORK_ERROR" 'DialogType enum
          pageOneof: m.Tracking.getAnalyticsPage(tempAgeScreen.trackingPageInfo.pageType, tempAgeScreen.trackingPageInfo.pageValues)
          dialog_action: "SHOW"
          dialog_sub_type: userErrorCode
        }
      }

      title = getTranslation("dialog_errorOops_title")
      message = getErrorMessage(message, userErrorCode)

      showSimpleModal(title, message, [], dialogEvent, m.trackingLoggingTask, startUserExperience)
    end if
  end if
End Function


' For signed up users who didn't have a age associated with their account,
' once they have submitted an age and the age has been verified, we need to
' PATCH their account info with their birthdate
Function patchSignedInUserAge()
  birthdate = ""
  currentScreen = getCurrentScreen()
  if currentScreen <> invalid and currentScreen.id = "ageVerificationScreen"
    birthdate = currentScreen.birthdate
  end if

  if birthdate.len() = 10 'YYYY-MM-DD
    options = {
      body: {
        birthday: birthdate
      }
    }

    authInfo = m.global.authInfo
    if authInfo <> invalid and authInfo.userId <> invalid
      patchSettingsInfo = m.userDeviceApi.patchSettingsInfo(authInfo.userId, options)

      m.makeRequest({
        url: patchSettingsInfo.url
        requestType: m.constants.reqNames.patchUserSettings
        options: patchSettingsInfo.options
        responseType: "assocarray"
        silenceCallbackWarnings: true
      })
    end if
  end if
End Function