''''''''''''''''''''''''
' startSignIn
'
' Defer to the sign-in controller for sign in experience
' @callbackAfterSignIn: function, the function to run after the signIn process is complete.
' @callbackAfterSignInParams: AA of parameters to be passed to callback function after sign In.
Function startSignIn(callbackAfterSignIn=invalid , callbackAfterSignInParams = invalid)

  tubiLog("SignInHelpers.startSignIn")

  ' setting the default callback that occurs after a user signs in
  if callbackAfterSignIn = invalid
    callbackAfterSignIn = onSideNavSignInCompleted
  end if

  m.callbackAfterSignIn = callbackAfterSignIn
  m.callbackAfterSignInParams = callbackAfterSignInParams
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

  if mode <> "production" AND isNonEmptyString(settingsEmail) = true AND isNonEmptyString(settingsPassword) = true
    hideNavMenu()
    signUserIn(settingsEmail, settingsPassword)
  else if mode <> "production" AND suitest = true AND automaticActivation = true
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
    m.billing.observeFieldScoped("userData", "onRfiUserData")
    m.billing.requestedUserData = "email, firstName, lastName, gender"
    m.billing.command = "getUserData"
  end if
End Function


' onRfiUserData is the callback triggered when ChannelStore returns userData via
' the firmware RFI (request for information) modal
Function onRfiUserData(msg)
  tubiLog("SignInHelpers.onRfiUserData")

  m.billing = invalid ' making m.billing as invalid to avoid using it another places

  currentScreen = getCurrentScreen()

  billing = msg.getRoSGNode()
  if billing <> invalid
    billing.unobserveFieldScoped("userData")
  end if

  if billing <> invalid AND billing.userData <> invalid

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

    input = {}
    '//userdata comes from https://developer.roku.com/en-gb/docs/references/scenegraph/control-nodes/channelstore.md#getuserdata
    input.firstName = billing.userData.firstName
    input.lastName = billing.userData.lastName
    input.gender = billing.userData.gender
    input.birth = billing.userData.birth
    input.state = billing.userData.state
    input.email = billing.userData.email
    input.emailType = "pre_fill"

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


' onEmailInputContinueSelected callback triggers when user clicks continue button from Manual Email Input screen
Function onEmailInputContinueSelected(evt)
  TubiLog("SignInHelpers.onEmailInputContinueSelected")
  screen = evt.getRoSGNode() 'emailInputScreen
  email = screen.email

  if isEmailValid(email) = true
    input = {
      email: email
      emailType: "manual"
    }

    checkEmailExists(input)
  else
    screen.isEmailValid = false
    ' re-setting focus on the screen is necessary to re-set voiceEnabled on the keyboard
    screen.setFocus(false)
    screen.setFocus(true)
  end if

End Function


'//The cancel operation was selected in the forgotPassword modal
Function onForgotPasswordDialogCancelSelected()
  TubiLog("SignInHelpers.onForgotPasswordDialogCancelSelected")

  currentScreen = getCurrentScreen()
  if currentScreen <> invalid AND currentScreen.getSubtype() = "SignInScreen"
    currentScreen.setFocusToKeyboard = true
  end if
End function


'//The "forgot password" button in the modal was clicked
Function onForgotPasswordDialogButtonSelected()
  TubiLog("SignInHelpers.onForgotPasswordDialogButtonSelected")

  displayForgotPasswordProcessingScreen()
End Function


' When the user selects the "Forgot Password" button on the sign in screen
Function onForgotPasswordButtonSelected()
  displayForgotPasswordProcessingScreen()
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
  onStopAndClearEmailVerificationTimer()

  if m.signUpToSaveProgressCancelledCallback <> invalid
    signUpToSaveProgressCancelledCallback = m.signUpToSaveProgressCancelledCallback
    m.signUpToSaveProgressCancelledCallback = invalid
    signUpToSaveProgressCancelledCallback()
  end if
End Function


' checkEmailExists function invokes API to check whether email already exits in Tubi
' @input : assocarray, will contain email(user's email) & emailType(manual/pre_fill)
Function checkEmailExists(input)

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
    rawInput: input
  })

End Function


' onEmailExistsResponse is the callback triggered when the emailExists API responds successfully
' @response : assocarray, the response of emailExists API in the form of AA
Function onEmailExistsResponse(response)
  TubiLog("SignInHelpers.onEmailExistsResponse")
  hideNavMenu()

  if response <> invalid
    parsedResponse = response.parsedResponse
    requestInput = response.requestInput

    if parsedResponse <> invalid AND requestInput <> invalid
      rawInput = requestInput.rawInput

      gender = ""
      firstName = ""
      lastName = ""
      email = ""
      emailType = ""
      if isAA(rawInput) = true
        if rawInput.gender <> invalid
          gender = rawInput.gender
        end if
        if rawInput.firstName <> invalid
          firstName = rawInput.firstName
        end if
        if rawInput.lastName <> invalid
          lastName = rawInput.lastName
        end if
        if rawInput.email <> invalid
          email = rawInput.email
        end if
        if rawInput.emailType <> invalid
          emailType = rawInput.emailType
        end if
      end if

      emailScreen = invalid
      screen = getCurrentScreen()
      if screen <> invalid AND screen.isSubType("EmailInputScreen") = true
        emailScreen = screen
      end if

      if parsedResponse.taken = true
        if emailScreen <> invalid
          emailScreen.isEmailValid = true
        end if

        m.email = email
        showSignInScreen(rawInput)
      else
        if parsedResponse.code = "AVAILABLE"
          '//user's email address does not exist in Tubi servers, so sign user up with a new Tubi account
          m.authInfoReceived = false
          signUpCredentials = {}
          signUpCredentials.email = email
          signUpCredentials.emailType = emailType
          signUpCredentials.gender = gender

          if isNonEmptyString(firstName) = false
            '//if first name does not exist, (i.e. when the user manually enters their email address),
            '// then use the 1st part of the email address
            emailSplitArr = email.split("@")
            emailSplitArrayCount = emailSplitArr.Count()

            '// If user enters email as somename@domain.com, then it takes firstName as "somename"
            if emailSplitArrayCount = 2
              firstName = emailSplitArr[0]
            '// If user enters email with multiple "@" symbol, eg. some@name@domain.com, so@me@name@domain.com etc
            '// then also it takes firstName as "somename"
            else if emailSplitArrayCount > 2
              for i = 0 to emailSplitArrayCount - 2
                firstName += emailSplitArr[i]
              end for
            end if
          end if

          ' Removing below special characters from firstName/lastName fields as it is not accepted in backend.
          regex = CreateObject("roRegex", "[<>&,`'!@$%()=+{}[\]\""]", "")  '" quote comment to aid in syntax highlighting
          firstName = regex.replaceAll(firstName, "")
          lastName = regex.replaceAll(lastName, "")

          signUpCredentials.firstName = Left(firstName, 20) ' limiting by 20 characters for the firstname field
          signUpCredentials.lastName = lastName

          if emailScreen <> invalid
            emailScreen.isEmailValid = true
          end if

          showAgeVerificationScreenAtSignUp(signUpCredentials)
        else if parsedResponse.code = "INVALID_FORMAT"
          ' user's email address is not acceptable. Could be valid from a semantic point of view,
          ' but might be blocked by backend due to known spam domain

          ' show email screen if top screen not email screen
          if screen = invalid OR screen.isSubType("EmailInputScreen") <> true
            emailScreen = showEmailScreen()
          else
            ' re-setting focus on the screen is necessary to re-set voiceEnabled on the keyboard
            emailScreen.setFocus(false)
            emailScreen.setFocus(true)
          end if

          ' tell email screen to show not valid email message
          emailScreen.isEmailValid = false
        end if
      end if
    end if
  end if
End Function


' onEmailExistsError is the callback triggered when the emailExists API fails
' @errorResponse : roSGNode, the error response (code, requestInput) of emailExists API in the form of AA
Function onEmailExistsError(errorResponse)
  TubiLog("SignInHelpers.onEmailExistsError")
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

  if simpleModalInfo <> invalid AND simpleModalInfo.buttonInfo <> invalid AND simpleModalInfo.buttonInfo[0] <> invalid
    simpleModalInfo.buttonInfo[0].callbackParams = requestInput.rawInput
  end if

  showModal(simpleModalInfo.modalInfo, simpleModalInfo.buttonInfo)
End Function


' showSignInScreen is used to display signIn screen
' @userInput : AssociativeArray,  (an associative array that contains at least email and possibly other data from the user's Roku profile)
Function showSignInScreen(userInput)
  signInScreen = CreateObject("roSGNode", "SignInScreen")
  signInScreen.id = m.constants.ui.screenIds.signInScreen
  signInScreen.username = userInput.email
  signInScreen.signInInfo = userInput
  signInScreen.observeFieldScoped("signInSelected", "onSignInSelected")
  signInScreen.observeFieldScoped("forgotPasswordSelected", "onForgotPasswordButtonSelected")
  signInScreen.observeFieldScoped("emailSelected", "onSignInScreenEmailSelected")
  signInScreen.observeFieldScoped("backgroundUriList", "onScreenBackgroundUpdated")
  pushScreen(signInScreen, true, true)
End Function


' onSignInScreenEmailSelected callback triggers when user selects the email text box
Function onSignInScreenEmailSelected()
  showEmailScreen()
End Function


' showEmailScreen is used to display Email screen for entering new email for signup
Function showEmailScreen()

  onStopAndClearEmailVerificationTimer()
  emailScreen = CreateObject("roSGNode", "EmailInputScreen")
  emailScreen.id = m.constants.ui.screenIds.emailInputScreen
  emailScreen.observeFieldScoped("continueSelected", "onEmailInputContinueSelected")
  emailScreen.observeFieldScoped("backButtonSelected", "onEmailInputBackButtonSelected")
  emailScreen.observeFieldScoped("backgroundUriList", "onScreenBackgroundUpdated")
  pushScreen(emailScreen, true, true)
  return emailScreen
End Function


Function onBackgroundScreenUpdated(msg)
  TubiLog("SignInHelpers.onBackgroundScreenUpdated")
  screen = msg.getRoSGNode()
  if screen <> invalid
    m.backgroundGroup.backgroundInfo = {
      type: getBackgroundType(screen.backgroundUriList)
      uriList: screen.backgroundUriList
    }
  end if
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

  ' Conditions to be met.
  ' Is the user in US.
  ' Is the user allowed to manage consent that is teen and above.
  if isDeviceInUS() = true AND isUserAllowedToManageConsent() = true
    m.shouldShowRokuCWConsentScreen = true
  else
    m.shouldShowRokuCWConsentScreen = false
  end if

  onActivationSuccess()
End Function


' onSignInSelected callback is triggered when user selects continue button on SignIn Screen
' @evt : roSGNodeEvent, it contains password
Function onSignInSelected(evt)
  tubiLog("SignInHelpers.onSignInSelected")
  signInSelected = evt.getData()
  email = signInSelected.email
  password = signInSelected.password
  signUserIn(email, password, signInSelected.rfiSignInInfo)
End Function


' @rfiSignInInfo: AssociativeArray - A record of the Roku account's signin info: i.e. email, firstname, gender, etc.
Function signUserIn(email, password, rfiSignInInfo = invalid)
  if isAA(rfiSignInInfo) = false then
    rfiSignInInfo = {}
  end if

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

  processTokenToGenerateTokenDebugInfo()

  m.makeRequest({
    url: requestInfo.url
    requestType: m.constants.reqNames.signIn
    options: requestInfo.options
    successCallback: onSignInResponse
    errorCallback: onSignInError
    responseType: "assocarray"
    email: email
    rfiSignInInfo: rfiSignInInfo
  })
End Function


' onSignInResponse callback is triggered when the sign In is success
' @response: assocarray or invalid, the response of signIn API in the form of AA or invalid if called from onQueryStatusOfMagicLinkResponse
Function onSignInResponse(response)
  m.trackingLoggingTask.trackEvent = {
    type: "account"
    values: {
      manip: "SIGNIN"
      current: "EMAIL"
      status: "SUCCESS"
    }
  }

  rfiSignInInfo = invalid
  requestInput = invalid

  if response <> invalid then
    requestInput = response.requestInput
    rfiSignInInfo = requestInput.rfiSignInInfo
  end if

  ' If email address used to sign in matches the Roku email address then go ahead and backfill their name and gender info
  if isAA(rfiSignInInfo) = true AND isAA(requestInput) = true AND rfiSignInInfo.email = requestInput.email then
    fieldsToUpdate = {}
    gender = rfiSignInInfo.gender
    if isNonEmptyString(gender) = true then
      gender = UCase(gender)
      if gender <> "MALE" AND gender <> "FEMALE"
        gender = "OTHER"
      end if
      fieldsToUpdate["gender"] = gender
    end if

    if isNonEmptyString(rfiSignInInfo.firstName) = true then
      fieldsToUpdate["first_name"] = rfiSignInInfo.firstName
      fieldsToUpdate["temporary_name"] = false
    end if

    if isNonEmptyString(rfiSignInInfo.lastName) = true then
      fieldsToUpdate["last_name"] = rfiSignInInfo.lastName
    end if

    if fieldsToUpdate.count() > 0 then
      patchSettingsInfo = m.userDeviceApi.patchSettingsInfo({
        body: fieldsToUpdate
      })

      m.makeRequest({
        url: patchSettingsInfo.url
        requestType: m.constants.reqNames.patchUserSettings
        options: patchSettingsInfo.options
        responseType: "assocarray"
        silenceCallbackWarnings: true
      })
    end if
  end if

  '//::TODO::roku_registration_gender_data - once the user is signed in, then call an API to ensure
  '//   the Roku saved info (i.e. gender, first name, etc) are saved using the following API
  '//   https://docs.tubi.io/api_docs/account#operations-User-patch-user-settings,
  '//
  '//   Is there a problem if the user saved something different in the Roku accont as compared to Tubi account?
  '//   For example, what if the user has the two accounts. In the Roku account, he is known as Thomas, and
  '//   in the Tubi account, he set his name to be his nickname, Tommy. So everytime we signs into his Roku app, it
  '//   changes his name to Thomas. The user changes his name in Tubi.tv, but again everytime he signs into the Roku app,
  '//   his name changes - very frustrating.
  '//   Maybe things like names and gender only changes if that info is not present in Tubi but is present in the Account info?
  '//   i.e. isNonEmptyString(_response.first_name) = false, isNonEmptyString(_response.gender) = false


  ' signInScreen = getFromScreenCache(m.constants.ui.screenIds.signInScreen)
  ' rokuUserInfo = signInScreen.signInInfo
  ' if rokuUserInfo <> invalid
  '   genderSend = ""
  '   firstNameSend = ""
  '   lastNameSend = ""
  '   if isNonEmptyString(rokuUserInfo.gender) = true AND isNonEmptyString(_response.gender) = false
  '     '//Roku account has gender info, but the Tubi account does not
  '     genderSend = rokuUserInfo.gender
  '   end if
  '   if isNonEmptyString(rokuUserInfo.firstName) = true AND isNonEmptyString(_response.first_name) = false
  '     '//Roku account has first name info, but the Tubi account does not
  '     firstNameSend = rokuUserInfo.firstName
  '   end if
  '   if isNonEmptyString(rokuUserInfo.lastName) = true AND isNonEmptyString(_response.last_name) = false
  '     '//Roku account has last name info, but the Tubi account does not
  '     lastNameSend = rokuUserInfo.lastName
  '   end if

  '   if isNonEmptyString(lastNameSend) OR isNonEmptyString(firstNameSend) OR isNonEmptyString(lastNameSend)
  '     '//if any of the data in not empty then send the data that is not empty using the following API
  '     '//   https://docs.tubi.io/api_docs/account#operations-User-patch-user-settings,
  '   end if
  ' end if

  onActivationSuccess()

End Function


' onSignInError callback is triggered when the sign In is failed
' @errorResponse : assocarray, the error response of signIn API in the form of AA
Function onSignInError(errorResponse)
  ' Checking if the reason for error is invalid token and the error message is Token type does not match.
  ' Reason we are checking the message because we get same error code for all token related errors.
  ' Sample error response: {"code":"INVALID_TOKEN","message":"Token type does not match"}
  if isAA(errorResponse.error) = true AND errorResponse.error.message = "Token type does not match"
    screenIds = getScreenIdsFromStack()

    eventInfo = {

      ' Active BreadCrumb. Useful to figure from where is the user trying to login. Side Menu / Details screen.
      screensInStack: screenIds.join(",")

      ' Trying to figure out how long the session was running. Trying to figure new session or an active session.
      appStartTime: m.top.appStartTime

      ' Token debug info.
      tokenDebugInfo: m.tokenDebugInfo
    }

    tubiLog(FormatJSON(eventInfo), "error", "apiError", "token-mismatch-error")
  end if
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

  dialogEvent.values.dialog_type = "FORGOT_PASSWORD"
  dialogEvent.values.dialog_sub_type = "forgot-password"

  title =  getTranslation("invalid_oops_password_title")
  invalidPasswordDesc = getTranslation("invalid_oops_password_description")
  message = invalidPasswordDesc + chr(10) + requestInput.email
  buttons = [getTranslation("dialog_button_forgot_password"), getTranslation("retry")]
  showSimpleInstantResumableModal(title, message, buttons, dialogEvent, m.trackingLoggingTask, onForgotPasswordDialogButtonSelected, onForgotPasswordDialogCancelSelected)

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

  getUserInfo(refreshConsent)

  m.spinner.visible = true
  m.spinner.setFocus(true)

  'we remove the activation screen after auth info has been received
End Function


Function refreshConsent()
  handleUpdatedAuth()
  getConsent(showConsentScreenOrRefreshServerPersistentData)
End Function


Function showConsentScreenOrRefreshServerPersistentData()
  if isUserConsentRequired() = true
    showConsentScreen(refreshServerPersistentDataAfterSignIn)
  else
    refreshServerPersistentDataAfterSignIn()
  end if
end function


Function refreshServerPersistentDataAfterSignIn()
  getServerPersistentData(onPostSignInAuthInfoUpdated)
End Function


Function onPostSignInAuthInfoUpdated()
  tubiLog("SignInHelpers.onPostSignInAuthInfoUpdated")
  authInfo = getFieldFromGlobal("authInfo")

  if (shouldShowAgeGate() AND authInfo <> invalid AND authInfo.hasAge <> true)
    m.spinner.visible = false
    signInInfo = invalid

    if authInfo <> invalid
      signInInfo = {}
      signInInfo.email  = authInfo.email
      signInInfo.firstname = authInfo.firstname
      signInInfo.gender = authInfo.gender
    end if
    showAgeVerificationScreenAtSignIn(signInInfo)
  else if m.shouldShowRokuCWConsentScreen = true
    m.shouldShowRokuCWConsentScreen = false
    if m.callbackAfterSignIn <> invalid
      showRokuCWConsentScreen(executeCallbackAfterSignIn)
    else
      showRokuCWConsentScreen(startChannel)
    end if
    saveServerPersistentData({
      "lastRokuCwConsentPromptShownAt": createObject("roDateTime").asSeconds()
    })
  else if m.callbackAfterSignIn <> invalid
    executeCallbackAfterSignIn()
  else
    ' this should not happen but start the channel in case it somehow does
    startChannel()
  end if

  setBrazeUserData(authInfo)

  if authInfo <> invalid AND authInfo.userId <> invalid
    brazeMergeUsers(authInfo.userId)
  end if
End Function


Function executeCallbackAfterSignIn()
  callbackAfterSignIn = m.callbackAfterSignIn
  m.callbackAfterSignIn = invalid ' setting to invalid to avoid future callbacks

  if m.callbackAfterSignInParams <> invalid
    callbackAfterSignInParams = m.callbackAfterSignInParams
    m.callbackAfterSignInParams = invalid
    callbackAfterSignIn(callbackAfterSignInParams)
  else
    callbackAfterSignIn()
  end if
End Function


' onSideNavSignInCompleted occurs when a user signs out or user signs in from the side nav or from settings side nav
Function onSideNavSignInCompleted()
  tubiLog("SignInHelpers.onSideNavSignInCompleted")

  ' set the mode before any changes are done to the UI
  refreshUiAfterSignIn()

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
  startChannel()
End Function


Function onMatureContentWarningSignInCompleted()
  tubiLog("SignInHelpers.onMatureContentWarningSignInCompleted")
  refreshUiAfterSignIn()
  setContentToRefreshAllPersonalizedScreens(false)

  currentScreen = popScreenAfterSignInProcess()
  m.spinner.visible = false

  if currentScreen <> invalid AND (currentScreen.getSubtype() = "DetailScreen" OR currentScreen.getSubtype() = "DetailScreenHoriz")
    refreshAllDetailScreens()
    currentScreen.jumpToItem = 0
  end if
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

  saveLocalServerPresistantData([{
    "isVideoPreviewOn": true
  }])
  getConsentAfterSignOut()
  getServerPersistentData()
End Function


Function getConsentAfterSignOut()
  handleUpdatedAuth()
  getConsent(showConsentScreenOrRefreshServerPersistentDataAfterSignOut)
End Function


Function showConsentScreenOrRefreshServerPersistentDataAfterSignOut()
  if isUserConsentRequired() = true
    showConsentScreen(onPostSignOutServerPersistentDataRefresh)
  else
    onPostSignOutServerPersistentDataRefresh()
  end if
end function


Function onPostSignOutServerPersistentDataRefresh()
  authInfo = getFieldFromGlobal("authInfo")
  ' set the mode before any changes are done to the UI
  setUiMode(m.constants.ui.modes.standard)

  setContentToRefreshAllPersonalizedScreens()
  setSideNavSignedInItem(authInfo)
  'clear the linearVideoplayer so that locked content will not get played.
  stopAndHideLinearVideoPlayer()
  startChannel()
  setBrazeUserData(authInfo)
End Function


' Is called only at app startup
Function onStartupAuthInfoReceived()
  tubiLog("SignInHelpers.onStartupAuthInfoReceived")
  handleUpdatedAuth()
  startUserExperience()
End Function


' These are the basic actions taken after the user has signed in
Function handleUpdatedAuth()
  ' AuthInfo may be invalid if authTask failed to log the user in
  authInfo = m.authTask.authInfo
  if shouldShowAgeGate()
    m.guestUserHasAgeInfo = m.authTask.guestUserHasAgeInfo
  end if
  m.global.authInfo = authInfo

  ' These will be empty parent nodes (no children) if user is not authenticated
  m.authInfoReceived = true
  m.authTask.unobserveFieldScoped("authInfo")
  m.authTask = invalid

  setSideNavSignedInItem(authInfo)
End Function



' onQueueAfterSignIn - occurs after activation success via Add to My List on Details page
Function onQueueAfterSignIn()
  tubiLog("SignInHelpers.onQueueAfterSignIn")
  refreshUiAfterSignIn()

  ' setContentToRefresh is not required for homescreen as we are fetching homescreen content
  ' right after adding into queue when onBookmarkedAfterSignIn() is called.
  ' We need to enforce that content is added to queue first, before re-fetching the homescreen.
  setContentToRefreshAllPersonalizedScreens(false)

  currentScreen = popScreenAfterSignInProcess()
  m.spinner.visible = false

  if currentScreen <> invalid AND (currentScreen.getSubtype() = "DetailScreen" OR currentScreen.getSubtype() = "DetailScreenHoriz")
    currentScreen.removeSignupButton = true
    currentScreen.jumpToItem = 0
    onAddToQueue(currentScreen, onBookmarkedAfterSignIn)
  end if

End Function


' onLikeAfterSignIn - occurs after activation success via Like Button on Details page
Function onLikeAfterSignIn()
  tubiLog("SignInHelpers.onLikeAfterSignIn")
  refreshUiAfterSignIn()
  setContentToRefreshAllPersonalizedScreens()

  currentScreen = popScreenAfterSignInProcess()
  m.spinner.visible = false

  if currentScreen <> invalid and (currentScreen.getSubtype() = "DetailScreen" OR currentScreen.getSubtype() = "DetailScreenHoriz")
    currentScreen.removeSignupButton = true
    currentScreen.jumpToItem = 0
    onLike(currentScreen)
    'refresh the detail screen in case the newly signed in user has any progress with the current content
    refreshDetailScreenContent(currentScreen)
    currentScreen.refreshRelatedContent = true
  end if
End Function


' onDislikeAfterSignIn - occurs after activation success via Dislike Button on Details page
Function onDislikeAfterSignIn()
  tubiLog("SignInHelpers.onDislikeAfterSignIn")
  refreshUiAfterSignIn()
  setContentToRefreshAllPersonalizedScreens()

  currentScreen = popScreenAfterSignInProcess()
  m.spinner.visible = false

  if currentScreen <> invalid and (currentScreen.getSubtype() = "DetailScreen" OR currentScreen.getSubtype() = "DetailScreenHoriz")
    currentScreen.removeSignupButton = true
    currentScreen.jumpToItem = 0
    onDislike(currentScreen)
    'refresh the detail screen in case the newly signed in user has any progress with the current content
    refreshDetailScreenContent(currentScreen)
    currentScreen.refreshRelatedContent = true
  end if
End Function


' onCWRowAfterSignIn - occurs after activation success via CWRow on homescreen
Function onCWRowAfterSignIn()
  tubiLog("SignInHelpers.onCWRowAfterSignIn")

  refreshUiAfterSignIn()

  setContentToRefreshAllPersonalizedScreens()

  startChannel()
End Function


Function onRegistrationProcessCompletedOnDetailsScreen()
  tubiLog("SignInHelpers.onRegistrationProcessCompletedOnDetailsScreen")
  refreshUiAfterSignIn()
  setContentToRefreshAllPersonalizedScreens(true)

  currentScreen = popScreenAfterSignInProcess()
  m.spinner.visible = false
  refreshAllDetailScreens()

  if currentScreen <> invalid and (currentScreen.getSubtype() = "DetailScreen" OR currentScreen.getSubtype() = "DetailScreenHoriz")
    currentScreen.jumpToItem = 0
    currentScreen.setfocus(true)
    currentScreen.refreshRelatedContent = true
  end if
End Function


Function onRegistrationProcessCompletedOnMyStuffScreen()
  tubiLog("SignInHelpers.onRegistrationProcessCompletedOnMyStuffScreen")
  setContentToRefreshAllPersonalizedScreens(true)

  currentScreen = popScreenAfterSignInProcess()
  m.spinner.visible = false

  if currentScreen <> invalid AND currentScreen.getSubtype() = "MyStuffScreen"
    currentScreen.signedIn = true
    currentScreen.setfocus(true)
    refreshContentSignalForMyStuffScreen(currentScreen)
  end if
End Function


Function onRegistrationProcessCompletedOnPlayerBackPress()
  tubiLog("SignInHelpers.onRegistrationProcessCompletedOnPlayerScreen")
  refreshUiAfterSignIn()
  setContentToRefreshAllPersonalizedScreens(true)
  popScreenAfterSignInProcess()
  m.spinner.visible = false
  returnToDetailScreenFromVideo()
End Function


' onParentalControlAfterSignIn - occurs after activation success via Parental Control
Function onParentalControlAfterSignIn()
  tubiLog("SignInHelpers.onParentalControlAfterSignIn")

  currentScreen = popScreenAfterSignInProcess()
  m.spinner.visible = false

  setContentToRefreshAllPersonalizedScreens()

  if currentScreen <> invalid AND currentScreen.getSubtype() = "SettingsScreen"
    setSettingsScreenSignInInfo()
    currentScreen.setFocus(true)

    '//before signing in, the user selected a new parental setting, so take user to parental change screen
    refreshUiAfterSignIn()  '//in case the user cancels out of the confirm password screen, ensure the mode matches with the newly signed in user's saved mode
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

  if currentScreen <> invalid AND currentScreen.id = m.constants.ui.screenIds.categoryDetailsScreen AND currentScreen.categoryId = m.constants.ui.categoryIds.queue
    ' this happens when user logs in via categoryDetailsScreen (queue/mylist)
    content = CreateObject("roSGNode", "CategoryContentNode")
    content.id = m.constants.ui.categoryIds.queue
    fetchCategoryDetails(content)
    setContentToRefreshAllPersonalizedScreens()
  else
    ' don't expect this to happen, keeping here as a fallback mechanism
    startChannel()
  end if
End Function


' onAutoplayPreviewAfterSignIn - occurs after signin success via autoplay preview
Function onAutoplayPreviewAfterSignIn()
  tubiLog("SignInHelpers.onAutoplayPreviewAfterSignIn")

  refreshUiAfterSignIn()
  currentScreen = popScreenAfterSignInProcess()
  m.spinner.visible = false

  if currentScreen <> invalid AND currentScreen.getSubtype() = "SettingsScreen"
    setSettingsScreenSignInInfo()
    currentScreen.setFocus(true)
  end if

  onAutoPreviewSettingSelected()
End Function


Function popScreenAfterSignInProcess()
  firstPopScreenTrackingInfo = invalid

  poppableScreenSubtypes = {
    "SignInScreen": true
    "EmailInputScreen": true
    "AgeVerificationScreen": true
    "SignUpAgeVerificationScreen": true
    "ForgotPasswordProcessingScreen": true
    "ConsentScreen": true
    "ManagePreferencesScreen": true
    "RokuCWConsentScreen": true
  }

  count = m.screenStack.getChildCount()-1
  for i = count to 0 step -1
    screen = m.screenStack.getChild(i)
    if screen <> invalid AND poppableScreenSubtypes[screen.getSubtype()] = true

      'Taking the page info of first screen that is being popped to send the navigatePage info.
      if firstPopScreenTrackingInfo = invalid
        firstPopScreenTrackingInfo = screen.trackingPageInfo
      end if

      popScreen(false, false)
    else
      exit for
    end if
  end for

  currentScreen = getCurrentScreen()

  'Send page load and navigate to page events after sign in/ signup process completed
  currentScreenPageInfo = currentScreen.trackingPageInfo
  if firstPopScreenTrackingInfo <> invalid
    screenTrackingNavigate(firstPopScreenTrackingInfo, currentScreenPageInfo)
  end if
  screenTrackingLoad(currentScreenPageInfo)

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


Function onMagicLinkResponse(response)
  tubiLog("SignInHelpers.onMagicLinkResponse")
  currentScreen = getCurrentScreen()
  if response <> invalid
    if currentScreen.id = m.constants.ui.screenIds.forgotPasswordProcessingScreen
      currentScreen.uid = response.uid
      m.emailVerificationTimer = m.top.createChild("Timer")
      m.emailVerificationTimer.repeat = false
      m.emailVerificationTimer.duration = 2
      m.emailVerificationTimer.observeFieldScoped("fire", "onEmailVerificationTimerFired")
      m.emailVerificationTimer.control = "start"
    end if
  end if
End Function


Function onMagicLinkError(errorResponse)
  tubiLog("SignInHelpers.onMagicLinkError")
  contextCode = m.constants.errors.context.forgotPasswordProcessingScreen
  errorCode = getUserFacingErrorCode(contextCode, m.constants.errors.subtypes.networkError, errorResponse.code)
  errorMessage = getTranslation("dialog_magicLink_error_description")
  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: "LOGIN_REQUEST" 'DialogType enum
      pageOneof: m.Tracking.getAnalyticsPage("login_page", {"choice": "LINK"})
      dialog_action: "SHOW"
      dialog_sub_type: "magiclink_server_err"
    }
  }

  modalInfo = {
    title: getTranslation("dialog_defaultError_title")
    message:getErrorMessage(errorMessage, errorCode)
    openTrackEvent: dialogEvent
    trackingTask: m.trackingLoggingTask
  }

  showErrorModal(modalInfo, invalid, invalid, onOkButtonClickedOnMagicLinkError, invalid, [getTranslation("dialog_button_ok")])
End Function


Function onEmailVerificationTimerFired()
  tubiLog("SignInHelpers.onEmailVerificationTimerFired")
  'Make Request
  uid = ""
  currentScreen = getCurrentScreen()
  if currentScreen.id = m.constants.ui.screenIds.forgotPasswordProcessingScreen
    uid = currentScreen.uid
    requestInfo = m.userDeviceApi.queryStatusOfMagicLink(uid)
    m.makeRequest({
      url: requestInfo.url
      requestType: m.constants.reqNames.queryStatusOfMagicLink
      options: requestInfo.options
      successCallback: onQueryStatusOfMagicLinkResponse
      errorCallback: onQueryStatusOfMagicLinkError
      responseType: "assocarray"
    })
  end if
End Function


Function onQueryStatusOfMagicLinkResponse(response)
  tubiLog("SignInHelpers.onQueryStatusOfMagicLinkResponse")
  currentScreen = getCurrentScreen()
  if currentScreen.id = m.constants.ui.screenIds.forgotPasswordProcessingScreen
    if response <> invalid AND response.status = "PENDING"
      currentScreen.queryResponseError = 0
      m.emailVerificationTimer.control = "start"
    else if response <> invalid AND response.access_token <> invalid
      onStopAndClearEmailVerificationTimer()
      Auth = TubiAuth(m.constants, m.Request)
      Auth.handleRegistration(response)
      onSignInResponse(invalid)
    end if
  end if

End Function


Function onStopAndClearEmailVerificationTimer()
  tubiLog("SignInHelpers.onStopAndClearEmailVerificationTimer")
  if m.emailVerificationTimer <> invalid
    m.emailVerificationTimer.control = "stop"
    m.emailVerificationTimer.unobserveFieldScoped("fire")
    m.top.removeChild(m.emailVerificationTimer)
  end if
End Function


Function onQueryStatusOfMagicLinkError(errorResponse)
  tubiLog("SignInHelpers.onQueryStatusOfMagicLinkError")
  currentScreen = getCurrentScreen()
  if currentScreen.id = m.constants.ui.screenIds.forgotPasswordProcessingScreen
    currentScreen.queryResponseError = currentScreen.queryResponseError + 1
    if currentScreen.queryResponseError > 3
      '//if an error has been set more than 3 times, then show error modal to user as the error is probably not a temporary network or server issue
      currentScreen.queryResponseError = 0

      contextCode = m.constants.errors.context.forgotPasswordProcessingScreen

      errorCode = getUserFacingErrorCode(contextCode, m.constants.errors.subtypes.expireError, errorResponse.code)
      errorMessage = getTranslation("dialog_uidExpiraionError_description")

      dialogEvent = {
        type: "dialog"
        values: {
          dialog_type: "LOGIN_REQUEST" 'DialogType enum
          pageOneof: m.Tracking.getAnalyticsPage("login_page", {"choice": "LINK"})
          dialog_action: "SHOW"
          dialog_sub_type: "link_expired"
        }
      }

      modalInfo = {
        title: getTranslation("dialog_uidExpiraionError_title")
        message:getErrorMessage(errorMessage, errorCode)
        openTrackEvent: dialogEvent
        trackingTask: m.trackingLoggingTask
      }
      showErrorModal(modalInfo, invalid, invalid, onOkButtonClickedOnLinkExpired, invalid, [getTranslation("dialog_button_ok")])
    else
      m.emailVerificationTimer.control = "start"
    end if
  end if
End Function


Function onResendVerificationLink()
  tubiLog("SignInHelpers.onResendVerificationLink")
  createMagicLinkRequest(m.email)
End Function


' @email : string,  (either taken from roku account or user entered email)
Function createMagicLinkRequest(email)
  requestInfo = m.userDeviceApi.magicLink(email)
  m.makeRequest({
    url: requestInfo.url
    requestType: m.constants.reqNames.magicLink
    options: requestInfo.options
    successCallback: onMagicLinkResponse
    errorCallback: onMagicLinkError
    responseType: "assocarray"
  })
End Function


Function onOkButtonClickedOnMagicLinkError()
  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: "LOGIN_REQUEST"
      pageOneof: m.Tracking.getAnalyticsPage("login_page", {"choice": "LINK"})
      dialog_action: "ACCEPT_DELIBERATE"
      dialog_sub_type: "magiclink_server_err"
    }
  }
  m.trackingLoggingTask.trackEvent = dialogEvent
End Function


Function onOkButtonClickedOnLinkExpired()
  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: "LOGIN_REQUEST"
      pageOneof: m.Tracking.getAnalyticsPage("login_page", {"choice": "LINK"})
      dialog_action: "ACCEPT_DELIBERATE"
      dialog_sub_type: "link_expired"
    }
  }
  m.trackingLoggingTask.trackEvent = dialogEvent
End Function


Function afterSignInPlayLockedLinearContent(callbackAfterSignInParams = invalid)
  tubilog("SignInHelpers.afterSignInPlayLockedLinearContent")
  popScreenAfterSignInProcess()
  if callbackAfterSignInParams <> invalid
    playLinearVideoContent(callbackAfterSignInParams.content, callbackAfterSignInParams.bMinimized, callbackAfterSignInParams.AssociatedScreenID, callbackAfterSignInParams.bAllowTransportToAppear, callbackAfterSignInParams.playbackSource )
  end if
  showHideSpinner(false)
  setContentToRefreshAllPersonalizedScreens(true)
End Function


Function AfterSignInPlayLockedContent(callbackAfterSignInParams)
  tubilog("SignInHelpers.AfterSignInPlayLockedContent")

  popScreenAfterSignInProcess()
  setContentToRefreshAllPersonalizedScreens(true)

  if callbackAfterSignInParams <> invalid
    playVideoContent(callbackAfterSignInParams.content, callbackAfterSignInParams.playbackSource, callbackAfterSignInParams.position)
  end if
  refreshAllDetailScreens()
  showHideSpinner(false)
End Function


Function AfterSignInPlayLockedContentWhileSkippingDetailScreen(params)
  tubilog("SignInHelpers.AfterSignInPlayLockedContentWhileSkippingDetailScreen")

  popScreenAfterSignInProcess()

  if params <> invalid
    playVideoContentWhileSkippingDetailScreen(params.content, params.nowPos, params.currentTrackingPageInfo, params.trackingComponentInfo, params.playbackSource)
  end if
  refreshAllDetailScreens()
  setContentToRefreshAllPersonalizedScreens(true)
  showHideSpinner(false)

End Function


Function afterDislikeSelectedFromUpNextUI(params)
  tubilog("SignInHelpers.afterLikeSelectedFromUpNextUI")
  setUiModeFromState()

  currentScreen = popScreenAfterSignInProcess()

  if currentScreen <> invalid AND currentScreen.getSubtype() = "VideoPlayerScreen"
    menuItem = params.menuItem
    likeDislikeState = params.likeDislikeState

    if menuItem = "LikeMenuItem"
      if likeDislikeState = m.constants.ui.likeDislikeStates.liked
        likeDislikeState = m.constants.ui.likeDislikeActions.removeLike
      else
        likeDislikeState = m.constants.ui.likeDislikeActions.like
      end if
    else if menuItem = "DislikeMenuItem"
      if likeDislikeState = m.constants.ui.likeDislikeStates.disliked
        likeDislikeState = m.constants.ui.likeDislikeActions.removeDislike
      else
        likeDislikeState = m.constants.ui.likeDislikeActions.dislike
      end if
    end if

    updateLikeDislikePlayer(currentScreen, likeDislikeState)
  end if

  refreshAllDetailScreens()
  setContentToRefreshAllPersonalizedScreens(true)
  showHideSpinner(false)
End Function


Function afterSignInLikeDislikeLinear(channelInfo)

  if channelInfo <> invalid
    setContentToRefreshAllPersonalizedScreens()
    popScreenAfterSignInProcess()
    showHideSpinner(false)
    showHideLogo(m.constants.logoType.hide) ' for epgScreen or linearVideoplayerscreen do not show any logo
    ' if user signIn on linearVideoplayer overlay then we need to pull fresh data because
    ' EPG overlay data is pulled only when videoplayer maximizes.
    currentScreen = getCurrentScreen()
    if currentScreen <> invalid AND currentScreen.id = m.constants.ui.screenIds.linearVideoPlayerScreen
      getDataForVideoPlayerTimeGrid()
    end if

    updateLikeDislikeLinear(channelInfo)
  end if

End Function


' processTokenToGenerateTokenDebugInfo method process the auth token and parses the JWT token to obtain debug information and store the debug info
' in a m scope variable m.tokenDebugInfo. m.tokenDebugInfo will be pass along in the debug logging request whenever we recieve token mismatch error.
Function processTokenToGenerateTokenDebugInfo()
  ' Processing the token before sending request. So that we can use this info if it fails.
  authInfo = getFieldFromGlobal("authInfo")
  ' Creating assoc array so that we append object as and when we have it.
  tokenDebugInfo = {}
  if authInfo <> invalid
    if authInfo.accessToken <> invalid
      parsedToken = parseJWTToken(authInfo.accessToken)

      if parsedToken <> invalid
        wasTokenExpired = checkIfTokenExpired(parsedToken.exp)
        tokenDebugInfo.append({
          ' is token valid
          wasGlobalAuthTokenExpired: (wasTokenExpired = true)

          ' the presence of user_id in the token indicates it is a auth token.
          wasValidUserIdPresentInGlobalAuthToken: isNonEmptyString(parsedToken.user_id)
        })
      end if

      tokenDebugInfo.append({
        ' is userid present in the authinfo. This helps us check if for some reason we are missing user id global auth info.
        wasValidUserIdPresentInGlobalAuthInfo: (authInfo.userId <> invalid)
      })
    end if
  end if

  Auth = TubiAuth(m.constants, m.Request)
  ' This reads token from registry not from global this will help us figure out if we are having difference in registry vs global.
  authInfo = Auth.getAuthInfoNoUpdate()

  if authInfo <> invalid
    if authInfo.accessToken <> invalid
      parsedToken = parseJWTToken(authInfo.accessToken)

      if parsedToken <> invalid
        wasTokenExpired = checkIfTokenExpired(parsedToken.exp)
        tokenDebugInfo.append({
          ' is token valid
          wasTokenInRegistryExpired: (wasTokenExpired = true)

          ' the presence of user_id in the token indicates it is a auth token.
          wasValidUserIdPresentInTokenInRegistry: isNonEmptyString(parsedToken.user_id)
        })
      end if

      tokenDebugInfo.append({
        ' is userid present in the authinfo. This helps us check if for some reason we are missing user id in registry.
        wasValidUserIdPresentInRegistryAuthInfo: authInfo.userId <> invalid
      })
    end if
  end if


  m.tokenDebugInfo = tokenDebugInfo
End Function


' @expireTime: integer, Holds the timestamp when the token will expire.
Function checkIfTokenExpired(expireTime)
  isExpired = true

  dateTime = CreateObject("roDateTime")
  timeInSecs = dateTime.asSeconds()

  if isInteger(expireTime) AND timeInSecs < expireTime
    isExpired = false
  end if

  return isExpired
End Function


' @param token: string, jwt token.
' @returns: assoc array, returns a assocarray which will contains info related to token ex: {"exp": 1701458827,"platform": "roku","type": 1,"user_id": 1}
Function parseJWTToken(token)
  parsedToken = invalid
  ' Contains 3 parts.
  ' First part contains type of encrption
  ' Second part is where we will get the token info.
  jwtTokenSplit = token.split(".")
  ' Checking the token is valid before proceeding.
  if jwtTokenSplit.count() = 3
    jwtBody = CreateObject("roByteArray")
    jwtBody.FromBase64String(base64UrlToBase64(jwtTokenSplit[1]))
    parsedToken = parseJSON(jwtBody.ToAsciiString())
  end if

  return parsedToken
End Function


' TODO: Remove the below method when we remove debug logging for token mismatch error.
' Converts base64Url to base64.
'
' @param base64Url: string, base64Url to convert to base64
Function base64UrlToBase64(base64Url)
  base64 = base64Url.replace("-", "+").replace("_","/")
  length = base64.len() mod 4

  ' Add required padding, optional in base64url
  if length < 3 then
    base64 = base64 + "=="
  else if length < 4 then
    base64 = base64 + "="
  end if

  return base64
End Function


Function refreshUiAfterSignIn()
  setUiModeFromState()
  refreshHomeScreenSideNav()
End Function
