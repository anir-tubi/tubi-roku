' For the AgeVerificationScreen helpers, a system of functions and callbacks, each for a specific flow,
' is used instead of keeping state on m. The tradeoff is that following the logic while reading is a
' little more difficult, but in return we theoretically get better maintainability and extensability.
' For example, if we want to update one flow, we don't have to worry about how the changes affect the
' other flows. With that in mind, the flows are "diagrammed" below:
'
' Flow 1) Guest user, needs age verification at channel launch
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
' Flow 2) Signed in user, needs age verification at channel launch
'   showAgeVerificationScreenAtStartupSignedIn() ->
'   showAgeVerificationScreen() ->
'   onAgeSubmittedAtStartupSignedIn() ->
'   verifyAgeAtStartupSignedIn() ->
'   verifyAge() -> one of
'     onAgeVerifiedAtStartupSignedIn() ->
'       onAgeVerifiedAtStartup()->
'       onAgeVerified()
'     onAgeNotVerifiedAtStartupSignedIn() ->
'       onAgeNotVerified()
'
' Flow 3) Guest user, needs age verification after signing out
'   showAgeVerificationScreenAtInteraction() ->
'   showAgeVerificationScreen() ->
'   onAgeSubmittedAtInteraction() ->
'   verifyAgeAtInteraction() ->
'   verifyAge() -> one of
'     onAgeVerifiedAtInteraction() ->
'       onAgeVerified()
'     onAgeNotVerifiedAtInteraction() ->
'       onAgeNotVerified()


Function showAgeVerificationScreenAtStartup()
  tubiLog("AgeVerificationScreenHelpers.showAgeVerificationScreenAtStartup")
  showAgeVerificationScreen(onAgeSubmittedAtStartup)

  ' Roku requires a beacon to be fired before and after any user interaction screens prior
  ' to the home page being shown
  m.top.signalBeacon("AppDialogInitiate")
End Function


Function showAgeVerificationScreenAtStartupSignedIn()
  tubiLog("AgeVerificationScreenHelpers.showAgeVerificationScreenAtStartupSignedIn")
  showAgeVerificationScreen(onAgeSubmittedAtStartupSignedIn)

  ' Roku requires a beacon to be fired before and after any user interaction screens prior
  ' to the home page being shown
  m.top.signalBeacon("AppDialogInitiate")
End Function


' TODO: Determine if this flow is still relevant after updates to COPPA
' Occurs when a user signs out
Function showAgeVerificationScreenAtInteraction()
  tubiLog("AgeVerificationScreenHelpers.showAgeVerificationScreenAtInteraction")
  showAgeVerificationScreen(onAgeSubmittedAtInteraction)
End Function


' Occurs after a user signs in, but the user does not have a valid age associated with their account yet.
Function showAgeVerificationScreenAfterSignIn()
  tubiLog("AgeVerificationScreenHelpers.showAgeVerificationScreenAfterSignIn")
  showAgeVerificationScreen(onAgeSubmittedAfterSignIn)
End Function


Function showAgeVerificationScreen(ageSubmittedCallback)
  callbackString = convertFunctionToString(ageSubmittedCallback)
  ageVerificationScreen = CreateObject("roSGNode", "AgeVerificationScreen")
  ageVerificationScreen.id = m.constants.ui.screenIds.ageVerificationScreen
  ageVerificationScreen.backgroundUriList = [m.defaultBackgroundUri]
  ageVerificationScreen.observeFieldScoped("ageSubmitted", callbackString)
  ageVerificationScreen.observeFieldScoped("whyButtonSelected", "onWhyButtonSelected")
  ageVerificationScreen.observeFieldScoped("backButtonPressed", "onBackButtonPressed")
  displayDefaultBackground()
  pushScreen(ageVerificationScreen, true, true)
End Function


Function onAgeSubmittedAtStartup(msg)
  onAgeSubmitted(msg, verifyAgeAtStartup)
End Function


Function onAgeSubmittedAtStartupSignedIn(msg)
  onAgeSubmitted(msg, verifyAgeAtStartupSignedIn)
End Function


Function onAgeSubmittedAtInteraction(msg)
  onAgeSubmitted(msg, verifyAgeAtInteraction)
End Function


Function onAgeSubmittedAfterSignIn(msg)
  onAgeSubmitted(msg, verifyAgeAfterSignIn)
End Function


' @msg: roSGNodeEvent, taken from observing ageVerificationScreen.ageSubmitted
' @verifyAgeCallback: function, a wrapper function around verifyAge (ie. verifyAgeAtStartup)
Function onAgeSubmitted(msg, verifyAgeCallback)
  tubiLog("AgeVerificationScreenHelpers.onAgeSubmitted")
  ageVerificationScreen = msg.getRoSGNode()
  birthdate = ageVerificationScreen.birthdate

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

  verifyAgeCallback(birthdate)
End Function


Function verifyAgeAtStartup(birthdate)
  verifyAge(birthdate, onAgeVerifiedAtStartup, onAgeNotVerifiedAtStartup)
End Function


Function verifyAgeAtStartupSignedIn(birthdate)
  verifyAge(birthdate, onAgeVerifiedAtStartupSignedIn, onAgeNotVerifiedAtStartupSignedIn)
End Function


Function verifyAgeAtInteraction(birthdate)
  verifyAge(birthdate, onAgeVerifiedAtInteraction, onAgeNotVerifiedAtInteraction)
End Function


Function verifyAgeAfterSignIn(birthdate)
  verifyAge(birthdate, onAgeVerifiedAfterSignIn, onAgeNotVerifiedAfterSignIn)
End Function


' @birthdate: string, birthdate with format "YYYY-MM-DD"
' @successCallback: function, the function to be called after the age has been verified by the backend.
'                             successCallback is passed an integer representing the age as returned
'                             by the backend.
' @errorCallback: function, the function to be called if an HTTP error code is returned by the backend
'                           while attempting to verify the age.
Function verifyAge(birthdate, successCallback, errorCallback)
  tubiLog("AgeVerificationScreenHelpers.verifyAge")
  if isString(birthdate) and birthdate <> ""
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


' Functionality that occurs after the age verification screen is shown to the user when
' starting the app, and the age has been verified by the backend
' @age: integer, the age as returned by the backend
Function onAgeVerifiedAtStartup(age)
  tubiLog("AgeVerificationScreenHelpers.onAgeVerifiedAtStartup")
  onAgeVerified(age)
  m.ageVerificationComplete = true

  ' Roku requires a beacon to be fired before and after any user interaction screens prior
  ' to the home page being shown
  ' Fire for successful age verified at startup.
  m.top.signalBeacon("AppDialogComplete")

  startUserExperience()
End Function


Function onAgeVerifiedAtStartupSignedIn(age)
  tubiLog("AgeVerificationScreenHelpers.onAgeVerifiedAtStartupSignedIn")
  patchSignedInUserAge()
  onAgeVerifiedAtStartup(age)
End Function


' Functionality that occurs after the age verification screen is shown to the user based upon a
' user interaction (usally sign out), and the age has been verified by the backend
' @age: integer, the age as returned by the backend
Function onAgeVerifiedAtInteraction(age)
  onAgeVerified(age)
  restartChannelAfterAgeVerification()
End Function


Function onAgeVerifiedAfterSignIn(age)
  patchSignedInUserAge()
  onAgeVerified(age)
  callbackAfterSignIn = m.callbackAfterSignIn
  m.callbackAfterSignIn = invalid ' setting to invalid to avoid future callbacks
  callbackAfterSignIn()
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


Function onAgeNotVerifiedAtStartup(err)
  onAgeNotVerified(err, verifyAgeAtStartup, startUserExperienceAsAgeNotVerified)
End Function


Function onAgeNotVerifiedAtStartupSignedIn(err)
  onAgeNotVerified(err, verifyAgeAtStartupSignedIn, startUserExperienceAsAgeNotVerified)
End Function


Function onAgeNotVerifiedAtInteraction(err)
  onAgeNotVerified(err, verifyAgeAtInteraction, restartChannelAfterAgeVerification)
End Function


Function onAgeNotVerifiedAfterSignIn(err)
  onAgeNotVerified(err, verifyAgeAfterSignIn, restartChannelAfterAgeVerification)
End Function


' @err: assocArray: expected return value from parseAgeVerificationScreenDeviceRegistrationError()
'                   expected fields are: code and birthdate
' @tryAgainCallback: function, the function to be called in case a modal is shown and a user selects try again
' @continueCallback: function, the function to be called to either let the user startUserExperience() 
'                              or restartChannelAfterAgeVerification() as appropriate
Function onAgeNotVerified(err, tryAgainCallback, continueCallback)
  tubiLog("AgeVerificationScreenHelpers.onAgeNotVerified")
  if err <> invalid and err.code <> invalid
    Request = TubiRequest(m.constants.settings)
    Auth = TubiAuth(m.constants, Request)
    
    if err.code = 422 or err.code = 451
      ' 422: the user is not old enough to use Tubi except in kids mode according to COPPA (US only)
      ' 451: the user is not old enough to use Tubi except in kids mode for some international reasons
      m.guestUserHasAgeInfo = Auth.setGuestUserHasAgeInfo(false)
      Auth.logout()
      m.global.authInfo = invalid
      continueCallback()

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
    else
      ' some network or API issue
      ' show generic "oops an error occurred" modal and allow users to retry/cancel
      screen = getCurrentScreen()
      if screen.id = m.constants.ui.screenIds.ageVerificationScreen
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
        showErrorModal(modalInfo, tryAgainCallback, err.birthdate, continueCallback, invalid, buttons)
      else
        ' it's unexpected to not be on the age verification screen, so punt and just start the app
        continueCallback()
      end if
    end if
  end if
End Function


Function startUserExperienceAsAgeNotVerified()
  m.ageVerificationComplete = true
  m.spinner.visible = true

  ' Roku requires a beacon to be fired before and after any user interaction screens prior
  ' to the home page being shown.
  ' Fire for not age verified at startup.
  m.top.signalBeacon("AppDialogComplete")

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
    showContentGroup()
    m.spinner.visible = false
    showAgeVerificationScreenAtStartupSignedIn()
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


Function onWhyButtonSelected(msg)
  screen = msg.getRoSGNode()
  title = getTranslation("dialog_why_ask_age_title")
  message = getTranslation("dialog_why_ask_age_description")
  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: "BIRTHDAY"
      pageOneof: m.Tracking.getAnalyticsPage(screen.trackingPageInfo.pageType, screen.trackingPageInfo.pageValues)
      dialog_action: "SHOW"
      dialog_sub_type: "why-age-gate"
    }
  }
  showSimpleModal(title, message, [], dialogEvent, m.trackingLoggingTask)
End Function


' For signed up users who didn't have a age associated with their account,
' once they have submitted an age and the age has been verified, we need to
' PATCH their account info with their birthdate
Function patchSignedInUserAge()
  birthdate = ""
  currentScreen = getCurrentScreen()
  if currentScreen <> invalid and currentScreen.isSubtype("AgeVerificationScreen")
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