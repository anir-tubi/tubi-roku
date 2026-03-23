''''''''''''''''''''''''
' startSignIn
'
' Defer to the sign-in controller for sign in experience
' @callbackAfterSignIn: function, the function to run after the signIn process is complete.
' @callbackAfterSignInParams: AA of parameters to be passed to callback function after sign In.
Function startSignIn(callbackAfterSignIn = invalid, callbackAfterSignInParams = invalid)

  tubiLog("SignInHelpers.startSignIn")

  stopVideoPreview()

  ' setting the default callback that occurs after a user signs in
  if callbackAfterSignIn = invalid
    callbackAfterSignIn = onSideNavSignInCompleted
  end if

  m.callbackAfterSignIn = callbackAfterSignIn
  m.callbackAfterSignInParams = callbackAfterSignInParams

  if isUserInMultiAccount() = true
    showProfileSelectorScreen(m.constants)
  else
    showRFIScreen()
  end if


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
    dialogSubType = "email-prefill"

    ' RFI screen is showing only if the channelStore node is stored in m variable
    m.billing = CreateObject("roSGNode", "ChannelStore")
    m.billing.observeFieldScoped("userData", "onRfiUserData")
    requestedUserData = "email, firstname, lastname, gender"

    if m.pub_serverPersistentData <> invalid AND m.pub_serverPersistentData.hasPreviouslyRegistered = true
      info = CreateObject("roSGNode", "ContentNode")
      info.addFields({ context: "signin" })
      m.billing.requestedUserDataInfo = info
      requestedUserData = "email"
      dialogSubType = "email-prefill-return"
    end if

    m.billing.requestedUserData = requestedUserData
    m.billing.command = "getUserData"

    if currentScreen <> invalid
      dialogEvent = {
        type: "dialog"
        values: {
          dialog_type: "REGISTRATION"
          pageOneof: m.Tracking.getAnalyticsPage(currentScreen.trackingPageInfo.pageType, currentScreen.trackingPageInfo.pageValues)
          dialog_action: "SHOW"
          dialog_sub_type: dialogSubType
        }
      }
      fireUserTrackingEvent(dialogEvent)
    end if

  end if
End Function


' onRfiUserData is the callback triggered when ChannelStore returns userData via
' the firmware RFI (request for information) modal
Function onRfiUserData(msg)
  tubiLog("SignInHelpers.onRfiUserData")

  m.billing = invalid ' making m.billing as invalid to avoid using it another places

  currentScreen = getCurrentScreen()

  dialogSubType = "email-prefill"
  if m.pub_serverPersistentData <> invalid AND m.pub_serverPersistentData.hasPreviouslyRegistered = true
    dialogSubType = "email-prefill-return"
  end if

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
        dialog_sub_type: dialogSubType
      }
    }
    fireUserTrackingEvent(dialogEvent)

    input = {}
    '//userdata comes from https://developer.roku.com/en-gb/docs/references/scenegraph/control-nodes/channelstore.md#getuserdata
    input.firstName = billing.userData.firstName
    input.lastName = billing.userData.lastName
    input.gender = billing.userData.gender
    input.birth = billing.userData.birth
    input.state = billing.userData.state
    input.email = billing.userData.email
    m.RFIProvidedEmail = billing.userData.email
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
        dialog_sub_type: dialogSubType
      }
    }
    fireUserTrackingEvent(dialogEvent)
    showEmailScreen()
  end if

  ' Stopping the preview once the sign in process is initiated.
  stopVideoPreview()

End Function


' onEmailInputContinueSelected callback triggers when user clicks continue button from Manual Email Input screen
Function onEmailInputContinueSelected(evt)
  TubiLog("SignInHelpers.onEmailInputContinueSelected")
  screen = evt.getRoSGNode() 'emailInputScreen

  if screen.getSubtype() = "EmailInputOrAddKidsScreen" AND screen.accountTypeSelected <> invalid AND screen.accountTypeSelected = "kids"
    showNameInputScreen(screen)
  else
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
  end if

End Function


'//The cancel operation was selected in the forgotPassword modal
Function onForgotPasswordDialogCancelSelected()
  TubiLog("SignInHelpers.onForgotPasswordDialogCancelSelected")

  currentScreen = getCurrentScreen()
  if currentScreen <> invalid AND currentScreen.getSubtype() = "SignInScreen"
    currentScreen.setFocusToKeyboard = true
  end if
End Function


'//The "forgot password" button in the modal was clicked
Function onForgotPasswordDialogButtonSelected()
  TubiLog("SignInHelpers.onForgotPasswordDialogButtonSelected")

  if getExternalConfigValueFromGlobal("auth_magic_link_enabled", true) = true
    displayForgotPasswordProcessingScreen()
  else
    showSignInSignUpErrorScreen("signIn", invalid, false)
  end if
End Function


' When the user selects the "Forgot Password" button on the sign in screen
Function onForgotPasswordButtonSelected()
  if getExternalConfigValueFromGlobal("auth_magic_link_enabled", true) = true
    displayForgotPasswordProcessingScreen()
  else
    showSignInSignUpErrorScreen("signIn", invalid, false)
  end if
End Function


' onEmailInputBackButtonSelected callback triggers when user clicks back button from Email Input screen
Function onEmailInputBackButtonSelected()

  event = {
    type: "account"
    values: {
      manip: "SIGNUP"
      current: "EMAIL"
      status: "FAIL"
      message: "user-cancel"
    }
  }
  fireUserTrackingEvent(event)
  popScreen(true, true)
  onStopAndClearEmailVerificationTimer()

  if isUserInMultiAccount() = true
    setUIModeFromState()
  end if

  if m.signUpToSaveProgressCancelledCallback <> invalid
    signUpToSaveProgressCancelledCallback = m.signUpToSaveProgressCancelledCallback
    m.signUpToSaveProgressCancelledCallback = invalid
    signUpToSaveProgressCancelledCallback()
  end if
End Function


Function onNameInputBackButtonSelected()
  popScreen(true, true)
End Function


Function onNameInputContinueSelected(evt)
  screen = evt.getRoSGNode()
  signInInfo = screen.signInInfo
  accountTypeSelected = screen.accountTypeSelected

  registerEvent = {
    type: "register"
    values: {
      progress: "COMPLETED_NAME"
    }
  }
  m.trackingLoggingTask.trackEvent = registerEvent

  if accountTypeSelected <> invalid AND accountTypeSelected = "kids"
    showAgeVerificationScreenAtSignUpForKids(signInInfo)
  else
    showAgeVerificationScreenAtSignUp(signInInfo)
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
    analyticsScreenId: m.constants.ui.screenIds.signInScreen
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
      if screen <> invalid AND (screen.isSubType("EmailInputScreen") = true OR screen.isSubType("EmailInputOrAddKidsScreen") = true)
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
          signUpCredentials = {}
          signUpCredentials.email = email
          signUpCredentials.emailType = emailType
          signUpCredentials.gender = gender

          if isUserInMultiAccount() = false
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
            regex = CreateObject("roRegex", "[<>&,`'!@$%()=+{}[\]\""]", "") '" quote comment to aid in syntax highlighting
            firstName = regex.replaceAll(firstName, "")
            lastName = regex.replaceAll(lastName, "")

            signUpCredentials.firstName = Left(firstName, 20) ' limiting by 20 characters for the firstname field
            signUpCredentials.lastName = lastName

            if emailScreen <> invalid
              emailScreen.isEmailValid = true
            end if

            showAgeVerificationScreenAtSignUp(signUpCredentials)
          else 'user is in multi account
            if emailScreen <> invalid
              emailScreen.isEmailValid = true
              emailScreen.signInInfo = signUpCredentials
            end if

            showNameInputScreen(emailScreen)
          end if
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


' showEmailVerificationScreen will send verification email to the roku account or
' user entered email if user choose different email.
' once user verified their email, it will redirect to the appropriate screen.
' If the user doesn't receive verification link, they can select resend verification.

' @email : string,  (either taken from roku account or user entered email)
Function showEmailVerificationScreen(email)
  tubiLog("SignInHelpers.showEmailVerificationScreen")
  emailVerificationScreen = CreateObject("roSGNode", "EmailVerificationScreen")
  emailVerificationScreen.id = m.constants.ui.screenIds.emailVerificationScreen
  emailVerificationScreen.email = email
  emailVerificationScreen.isMajorEventDay = isMajorEventDay()
  emailVerificationScreen.observeFieldScoped("selectedDifferentEmail", "showEmailScreen")
  emailVerificationScreen.observeFieldScoped("backButtonSelected", "onEmailVerificationScreenBackButtonSelected")
  emailVerificationScreen.observeFieldScoped("resendVerificationLink", "onResendVerificationLink")
  emailVerificationScreen.observeFieldScoped("continueButtonSelected", "onEmailVerificationScreenContinueAsGuestUserButtonSelected")
  pushScreen(emailVerificationScreen, true, true)
  displayDefaultBackground()
End Function


' onEmailExistsError is the callback triggered when the emailExists API fails
' @errorResponse : roSGNode, the error response (code, requestInput) of emailExists API in the form of AA
Function onEmailExistsError(errorResponse)
  TubiLog("SignInHelpers.onEmailExistsError")
  accountEvent = {
    type: "account"
    values: {
      manip: "REGISTER_DEVICE"
      current: "EMAIL"
      message: "email-exists-error"
      status: "FAIL"
    }
  }
  fireUserTrackingEvent(accountEvent)
  if shouldShowSignInSignUpErrorPage(errorResponse) = true
    showSignInSignUpErrorScreen("signIn", invalid, false)
  else
    requestInput = errorResponse.requestInput
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

    title = getTranslation("dialog_defaultError_title")
    message = getTranslation("could_not_verify_email") + ". " + getTranslation("dialog_defaultError_description")
    buttons = [getTranslation("dialog_button_tryAgain"), getTranslation("dialog_button_cancel")]
    simpleModalInfo = getSimpleModalInfo(title, message, buttons, dialogEvent, m.trackingLoggingTask, checkEmailExists, invalid, m.constants.instantResumeActions.restartApp)

    if simpleModalInfo <> invalid AND simpleModalInfo.buttonInfo <> invalid AND simpleModalInfo.buttonInfo[0] <> invalid
      simpleModalInfo.buttonInfo[0].callbackParams = requestInput.rawInput
    end if

    showModal(simpleModalInfo.modalInfo, simpleModalInfo.buttonInfo)
  end if
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


Function showNameInputScreen(screen)
  nameScreen = CreateObject("roSGNode", "NameInputScreen")
  nameScreen.id = m.constants.ui.screenIds.nameInputScreen
  if screen <> invalid
    nameScreen.email = screen.email
    nameScreen.hasPin = screen.hasPin
    nameScreen.parentProfileId = screen.parentProfileId
    if screen.accountTypeSelected <> invalid
      nameScreen.accountTypeSelected = screen.accountTypeSelected
    end if
  end if
  nameScreen.observeFieldScoped("continueSelected", "onNameInputContinueSelected")
  nameScreen.observeFieldScoped("backButtonSelected", "onNameInputBackButtonSelected")
  nameScreen.observeFieldScoped("backgroundUriList", "onScreenBackgroundUpdated")
  pushScreen(nameScreen, true, true)
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


Function showEmailScreenWithProfileSelection()
  emailScreen = CreateObject("roSGNode", "EmailInputOrAddKidsScreen")
  emailScreen.id = m.constants.ui.screenIds.emailInputScreen
  profiles = m.tubiAuthUpdate.getAllProfilesAuthInfo()
  emailScreen.profiles = getProfilesListContent(profiles, true)
  emailScreen.observeFieldScoped("continueSelected", "onEmailInputContinueSelected")
  emailScreen.observeFieldScoped("backButtonSelected", "onEmailInputBackButtonSelected")
  emailScreen.observeFieldScoped("backgroundUriList", "onScreenBackgroundUpdated")
  emailScreen.observeFieldScoped("accountTypeSelected", "onAccountTypeSelected")
  emailScreen.observeFieldScoped("componentInteractionInfo", "onComponentInteractionInfoChange")
  pushScreen(emailScreen, true, true)
  return emailScreen
End Function

Function onAccountTypeSelected(msg)
  accType = msg.getData()
  if accType <> invalid AND accType = "kids"
    setUiMode(m.constants.ui.modes.kidsProfile)
  else
    setUiMode(m.constants.ui.modes.standard)
  end if
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
Function onSignUpResponse(response)
  isUsrInMultiAccount = isUserInMultiAccount()
  m.tubiAuthUpdate.handleRegistration(response, isUsrInMultiAccount)

  event = {
    type: "account"
    values: {
      manip: "SIGNUP"
      current: "EMAIL"
      status: "SUCCESS"
    }
  }
  fireUserTrackingEvent(event)

  ' Conditions to be met.
  ' Is the user in US.
  ' Is the user allowed to manage consent that is teen and above.
  if isDeviceInUS() = true AND isUserAllowedToManageConsent() = true AND isMajorEventDay() = false
    m.shouldShowRokuCWConsentScreen = true
  else
    m.shouldShowRokuCWConsentScreen = false
  end if

  onActivationSuccess()
  showWelcomeProfileToast()
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
Function signUserIn(email, password, rfiSignInInfo = invalid, successCallback = invalid, errorCallback = invalid)
  if isAA(rfiSignInInfo) = false then
    rfiSignInInfo = {}
  end if

  if successCallback = invalid then
    successCallback = onSignInResponse
  end if
  if errorCallback = invalid then
    errorCallback = onSignInError
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

  m.makeRequest({
    url: requestInfo.url
    requestType: m.constants.reqNames.signIn
    options: requestInfo.options
    successCallback: successCallback
    errorCallback: errorCallback
    responseType: "assocarray"
    email: email
    rfiSignInInfo: rfiSignInInfo
    analyticsScreenId: m.constants.ui.screenIds.signInScreen
  })
End Function


' onSignInResponse callback is triggered when the sign In is success
' @response: assocarray or invalid, the response of signIn API in the form of AA or invalid if called from onQueryStatusOfMagicLinkResponse
Function onSignInResponse(response)
  isUsrInMultiAccount = isUserInMultiAccount()
  m.tubiAuthUpdate.handleRegistration(response, isUsrInMultiAccount)


  event = {
    type: "account"
    values: {
      manip: "SIGNIN"
      current: "EMAIL"
      status: "SUCCESS"
    }
  }
  fireUserTrackingEvent(event)

  rfiSignInInfo = invalid
  requestInput = invalid

  if response <> invalid then
    requestInput = response.requestInput
    if requestInput <> invalid then
      rfiSignInInfo = requestInput.rfiSignInInfo
    end if
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
        analyticsScreenId: m.constants.ui.screenIds.signInScreen
      })
    end if
  end if

  onActivationSuccess()
  showWelcomeProfileToast()
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

  fireUserTrackingEvent(accountEvent)

  if shouldShowSignInSignUpErrorPage(errorResponse) = true
    showSignInSignUpErrorScreen("signIn", invalid, false)
  else
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

    title = getTranslation("invalid_oops_password_title")
    invalidPasswordDesc = getTranslation("invalid_oops_password_description")
    message = invalidPasswordDesc + chr(10) + requestInput.email
    buttons = [getTranslation("dialog_button_forgot_password"), getTranslation("retry")]
    showSimpleInstantResumableModal(title, message, buttons, dialogEvent, m.trackingLoggingTask, onForgotPasswordDialogButtonSelected, onForgotPasswordDialogCancelSelected)
  end if
End Function


'''''''''''''''''''''''''
' onActivationSuccess
'
' The sign-in flow has ended, do what comes next
Function onActivationSuccess()
  tubiLog("SignInHelpers.onActivationSuccess")

  if m.RFIProvidedEmail <> invalid
    authInfo = m.tubiAuthUpdate.getAuthInfo()
    if authInfo <> invalid AND authInfo.email = m.RFIProvidedEmail
      m.RFIProvidedEmail = invalid 'clear the variable after we consumed it.
      saveServerPersistentData({
        "hasPreviouslyRegistered": true
      }, "device")
    end if
  end if

  getUserInfo(refreshConsent)

  m.spinner.visible = true
  m.spinner.setFocus(true)

  'we remove the activation screen after auth info has been received
End Function


Function refreshConsent()
  handleUpdatedAuth()
  if isUserInMultiAccount() = true AND isKidsProfile() = true

    refreshServerPersistentDataAfterSignIn()
  else
    getConsent(showConsentScreenOrRefreshServerPersistentData)
  end if
End Function


Function showConsentScreenOrRefreshServerPersistentData()
  if isUserConsentRequired() = true
    showConsentScreen(refreshServerPersistentDataAfterSignIn)
  else
    refreshServerPersistentDataAfterSignIn()
  end if
End Function


Function refreshServerPersistentDataAfterSignIn()
  getServerPersistentData(onPostSignInAuthInfoUpdated)
End Function


Function onPostSignInAuthInfoUpdated()
  tubiLog("SignInHelpers.onPostSignInAuthInfoUpdated")
  authInfo = m.tubiAuthUpdate.getAuthInfo()
  if (shouldShowAgeGate() AND authInfo <> invalid AND isLoggedInUser(authInfo) = true AND authInfo.hasAge <> true)
    m.spinner.visible = false
    signInInfo = invalid

    signInInfo = {}
    signInInfo.email = authInfo.email
    signInInfo.firstname = authInfo.firstname
    signInInfo.gender = authInfo.gender
    showAgeVerificationScreenAtSignIn(signInInfo)
  else if m.shouldShowRokuCWConsentScreen = true
    m.shouldShowRokuCWConsentScreen = false
    if m.callbackAfterSignIn <> invalid
      showRokuCWConsentScreen(executeCallbackAfterSignIn)
    else
      showRokuCWConsentScreen(startChannel)
    end if
  else if m.callbackAfterSignIn <> invalid
    executeCallbackAfterSignIn()
  else
    ' this should not happen but start the channel in case it somehow does
    startChannel()
  end if

  setBrazeUserData(authInfo)
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

  if isMajorEventDay() = false
    setDirtyUserCategories(m.constants.ui.categoryIds.queue)
    setDirtyUserCategories(m.constants.ui.categoryIds.history)
  end if

  setContentToRefreshAllPersonalizedScreens(true)

  refreshAllDetailScreens()
  authInfo = m.tubiAuthUpdate.getAuthInfo()
  setSideNavSignedInItem(authInfo)

  ' this happens when a user signs out or user signs in from the side nav or from settings side nav
  startChannel()
End Function


Function onMatureContentWarningSignInCompleted()
  tubiLog("SignInHelpers.onMatureContentWarningSignInCompleted")
  refreshUiAfterSignIn()
  setContentToRefreshAllPersonalizedScreens(true)

  currentScreen = popScreenAfterSignInProcess()
  m.spinner.visible = false

  if currentScreen <> invalid AND currentScreen.getSubtype() = "DetailScreen"
    refreshAllDetailScreens()
    currentScreen.jumpToItem = 0
  end if
End Function


Function onSignOutCompleted()
  tubiLog("SignInHelpers.onSignOutCompleted")

  event = {
    type: "account"
    values: {
      manip: "SIGNOUT"
      current: "EMAIL"
      status: "SUCCESS"
    }
  }
  fireUserTrackingEvent(event)

  saveLocalServerPersistentData([{
    "isVideoPreviewOn": true
    "isAutoPlayTimerOn": true
  }])

  ' Exit Kids mode if user was in Kids mode when signing out
  if isKidsUIOn() = true
    disableKidsModeFromSideNav()
  end if

  getConsentAfterSignOut()
  getServerPersistentData()
End Function


Function onLogOutProfileCompleted()
  tubiLog("SignInHelpers.onLogOutProfileCompleted")

  clearGlobalUserData()

  profiles = m.tubiAuthUpdate.getAllProfilesAuthInfo()

  if profiles["guest"] <> invalid
    profileCount = profiles.count() - 1
    profiles.delete("guest")
  else
    profileCount = profiles.count()
  end if

  if profileCount = 0
    m.sideNav.isUserInMultiAccount = false
    handleGuestProfileSelection()
  else if profileCount = 1
    m.sideNav.isUserInMultiAccount = false
    profileId = profiles.Keys()[0]
    handleRegularProfileSelection(profileId)
  else if profiles.count() > 1
    m.sideNav.isUserInMultiAccount = true
    showProfileSelectorScreen(m.constants, profiles, true)
  end if
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
End Function


Function onPostSignOutServerPersistentDataRefresh()
  tubiLog("SignInHelpers.onPostSignOutServerPersistentDataRefresh")
  authInfo = m.tubiAuthUpdate.getAuthInfo()

  if isUserInMultiAccount() = false
    if isKidsUIOn() = false
      setUiMode(m.constants.ui.modes.standard)
    end if
  else
    setUiModeForProfileSelected(authInfo)
  end if

  setContentToRefreshAllPersonalizedScreens()
  setSideNavSignedInItem(authInfo)
  refreshHomeScreenSideNav()

  'clear the linearVideoplayer so that locked content will not get played.
  stopAndHideLinearVideoPlayer()
  startChannel()
  setBrazeUserData(authInfo)
End Function


' Is called only at app startup
Function onStartupAuthInfoReceived()
  tubiLog("SignInHelpers.onStartupAuthInfoReceived")
  handleUpdatedAuth()
  runControllerStartSequence()
End Function


' These are the basic actions taken after the user has signed in
Function handleUpdatedAuth()
  ' AuthInfo may be invalid if authTask failed to log the user in
  if shouldShowAgeGate()
    m.guestUserHasAgeInfo = getGuestUserHasAgeInfo()
  end if

  authInfo = m.tubiAuthUpdate.getAuthInfo()

  setSideNavSignedInItem(authInfo)
End Function



' onQueueAfterSignIn - occurs after activation success via Add to My List on Details page
Function onQueueAfterSignIn()
  tubiLog("SignInHelpers.onQueueAfterSignIn")
  refreshUiAfterSignIn()
  if isUserInMultiAccount() = true AND isKidsUIOn() = true
    setContentToRefreshAllPersonalizedScreens() 'for kids profile, we need to refresh the homescreen.
  else

    ' setContentToRefresh is not required for homescreen as we are fetching homescreen content
    ' right after adding into queue when onBookmarkedAfterSignIn() is called.
    ' We need to enforce that content is added to queue first, before re-fetching the homescreen.
    setContentToRefreshAllPersonalizedScreens(false)
  end if

  currentScreen = popScreenAfterSignInProcess()
  m.spinner.visible = false

  if currentScreen <> invalid AND currentScreen.getSubtype() = "DetailScreen"
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

  if currentScreen <> invalid AND currentScreen.getSubtype() = "DetailScreen"
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

  if currentScreen <> invalid AND currentScreen.getSubtype() = "DetailScreen"
    currentScreen.removeSignupButton = true
    currentScreen.jumpToItem = 0
    onDislike(currentScreen)
    'refresh the detail screen in case the newly signed in user has any progress with the current content
    refreshDetailScreenContent(currentScreen)
    currentScreen.refreshRelatedContent = true
  end if
End Function


' refreshScreenAndContentAfterSignIn - occurs after activation success via CWRow on homescreen
Function refreshScreenAndContentAfterSignIn()
  tubiLog("SignInHelpers.refreshScreenAndContentAfterSignIn")

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

  if currentScreen <> invalid AND currentScreen.getSubtype() = "DetailScreen"
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
  returnToDetailScreenFromVideo(true, true, "registration")
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
    refreshUiAfterSignIn() '//in case the user cancels out of the confirm password screen, ensure the mode matches with the newly signed in user's saved mode
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


' onAutoplayPreviewAfterSignIn - occurs after signin success via autoplay preview.
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


' onAutoplayNextVideoAfterSignIn - occurs after signin success via autoplay next video.
Function onAutoplayNextVideoAfterSignIn()
  tubiLog("SignInHelpers.onAutoplayNextVideoAfterSignIn")

  refreshUiAfterSignIn()
  currentScreen = popScreenAfterSignInProcess()
  m.spinner.visible = false

  if currentScreen <> invalid AND currentScreen.getSubtype() = "SettingsScreen"
    setSettingsScreenSignInInfo()
    currentScreen.setFocus(true)

    if currentScreen.autoPlayTimerSettingSelected = 0
      saveAutoPlayNextVideoChoiceToServerPersistentData(true)
    else if currentScreen.autoPlayTimerSettingSelected = 1
      saveAutoPlayNextVideoChoiceToServerPersistentData(false)
    end if

  end if

End Function


Function popScreenAfterSignInProcess()
  firstPopScreenTrackingInfo = invalid

  poppableScreenSubtypes = {
    "SignInScreen": true
    "EmailInputScreen": true
    "AgeVerificationScreen": true
    "SignUpAgeVerificationScreen": true
    "EmailVerificationScreen": true
    "ForgotPasswordProcessingScreen": true
    "ConsentScreen": true
    "ManagePreferencesScreen": true
    "RokuCWConsentScreen": true
    "SignInSignUpErrorScreen": true
    "ProfileSelectorScreen": true
    "NameInputScreen": true
    "KidsAgeSelectionScreen": true
    "EmailInputOrAddKidsScreen": true
    "ParentalControlPinInputScreen": true
    "KidsAccountSetupScreen": true
  }

  count = m.screenStack.getChildCount() - 1

  'Will remove this code after the experiment.
  settingsScreen = getScreenFromStackById(m.constants.ui.screenIds.settingsScreen)
  if settingsScreen <> invalid
    settingsScreen.isUserSignedInFromSettingScreen = true
  end if

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
  dateTime = CreateObject("roDateTime")
  secondsFromEpoch = dateTime.AsSeconds()

  signInInfo = {
    email: "build_roku_" + secondsFromEpoch.ToStr() + "@tubi.tv"
    emailType: "manual"
    firstName: "Automation"
    automation: true ' setting automation as true, so password will be set to 111111 during signup
  }
  birthdate = "2000-01-01"
  verifyAgeAtSignup(signInInfo, birthdate)
End Function


Function onMagicLinkResponse(response)
  tubiLog("SignInHelpers.onMagicLinkResponse")
  currentScreen = getCurrentScreen()

  if response <> invalid
    if currentScreen <> invalid AND (currentScreen.id = m.constants.ui.screenIds.emailVerificationScreen OR currentScreen.id = m.constants.ui.screenIds.forgotPasswordProcessingScreen)
      currentScreen.uid = response.uid
      m.emailVerificationTimer = CreateObject("roSGNode", "Timer")
      m.emailVerificationTimer.duration = 5
      m.emailVerificationTimer.observeFieldScoped("fire", "onEmailVerificationTimerFired")
      m.emailVerificationTimer.control = "start"
    end if
  end if
End Function


Function onMagicLinkError(errorResponse)
  tubiLog("SignInHelpers.onMagicLinkError")
  if shouldShowSignInSignUpErrorPage(errorResponse) = true
    showSignInSignUpErrorScreen("signIn", invalid, false)
  else
    contextCode = m.constants.errors.context.forgotPasswordProcessingScreen
    currentScreen = getCurrentScreen()

    if currentScreen <> invalid
      if currentScreen.hasField("failureReason") = true
        currentScreen.failureReason = "magiclink_server_err"
      end if

      if currentScreen.id = m.constants.ui.screenIds.emailVerificationScreen
        contextCode = m.constants.errors.context.emailVerificationScreen
      end if
    end if

    errorCode = getUserFacingErrorCode(contextCode, m.constants.errors.subtypes.networkError, errorResponse.code)
    errorMessage = getTranslation("dialog_magicLink_error_description")
    dialogEvent = {
      type: "dialog"
      values: {
        dialog_type: "LOGIN_REQUEST" 'DialogType enum
        pageOneof: m.Tracking.getAnalyticsPage("login_page", { "choice": "LINK" })
        dialog_action: "SHOW"
        dialog_sub_type: "magiclink_server_err"
      }
    }

    modalInfo = {
      title: getTranslation("dialog_defaultError_title")
      message: getErrorMessage(errorMessage, errorCode)
      openTrackEvent: dialogEvent
      trackingTask: m.trackingLoggingTask
    }

    showErrorModal(modalInfo, invalid, invalid, invalid, invalid, [getTranslation("dialog_button_ok")])
  end if
End Function


Function onEmailVerificationTimerFired()
  tubiLog("SignInHelpers.onEmailVerificationTimerFired")
  'Make Request
  currentScreen = getCurrentScreen()

  if currentScreen <> invalid AND (currentScreen.id = m.constants.ui.screenIds.emailVerificationScreen OR currentScreen.id = m.constants.ui.screenIds.forgotPasswordProcessingScreen)
    uid = currentScreen.uid
    requestInfo = m.userDeviceApi.queryStatusOfMagicLink(uid)
    m.makeRequest({
      url: requestInfo.url
      requestType: m.constants.reqNames.queryStatusOfMagicLink
      options: requestInfo.options
      successCallback: onQueryStatusOfMagicLinkResponse
      errorCallback: onQueryStatusOfMagicLinkError
      responseType: "assocarray"
      analyticsScreenId: m.constants.ui.screenIds.signInScreen
    })
  end if
End Function


Function onQueryStatusOfMagicLinkResponse(response)
  tubiLog("SignInHelpers.onQueryStatusOfMagicLinkResponse")
  currentScreen = getCurrentScreen()

  if currentScreen <> invalid AND (currentScreen.id = m.constants.ui.screenIds.emailVerificationScreen OR currentScreen.id = m.constants.ui.screenIds.forgotPasswordProcessingScreen)
    if response <> invalid AND response.status = "PENDING"
      currentScreen.queryResponseError = 0
      m.emailVerificationTimer.control = "start"
    else if response <> invalid AND response.status = "EXPIRED"
      onStopAndClearEmailVerificationTimer()
      if isMajorEventDay() = true
        showSignInSignUpErrorScreen("signIn", invalid, false)
      else
        handleSignInFailure()
      end if
    else if response <> invalid AND response.access_token <> invalid
      onStopAndClearEmailVerificationTimer()
      onSignInResponse(response)
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


'//When user presses the back button from the email verification screen
Function onEmailVerificationScreenBackButtonSelected()
  failureReason = "user-cancel"
  currentScreen = getCurrentScreen()

  if currentScreen <> invalid AND currentScreen.id = m.constants.ui.screenIds.emailVerificationScreen AND isNonEmptyString(currentScreen.failureReason) = true
    failureReason = currentScreen.failureReason
  end if

  event = {
    type: "account"
    values: {
      manip: "SIGNIN"
      current: "EMAIL"
      status: "FAIL"
      message: failureReason
    }
  }
  fireUserTrackingEvent(event)

  onStopAndClearEmailVerificationTimer()
  popScreen()
End Function


Function handleSignInFailure(errorResponse = invalid)
  currentScreen = getCurrentScreen()
  contextCode = m.constants.errors.context.forgotPasswordProcessingScreen

  if currentScreen <> invalid
    if currentScreen.hasField("failureReason") = true
      currentScreen.failureReason = "link_expired"
    end if

    if currentScreen.id = m.constants.ui.screenIds.emailVerificationScreen
      contextCode = m.constants.errors.context.emailVerificationScreen
    end if
  end if

  errorMessage = getTranslation("dialog_uidExpiraionError_description")
  errorCode = ""

  if errorResponse <> invalid AND isNonEmptyString(errorResponse.code) = true
    errorCode = getUserFacingErrorCode(contextCode, m.constants.errors.subtypes.expireError, errorResponse.code)
    errorMessage = getErrorMessage(errorMessage, errorCode)
  end if

  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: "LOGIN_REQUEST" 'DialogType enum
      pageOneof: m.Tracking.getAnalyticsPage("login_page", { "choice": "LINK" })
      dialog_action: "SHOW"
      dialog_sub_type: "link_expired"
    }
  }

  modalInfo = {
    title: getTranslation("dialog_uidExpiraionError_title")
    message: errorMessage
    openTrackEvent: dialogEvent
    trackingTask: m.trackingLoggingTask
  }
  showErrorModal(modalInfo, invalid, invalid, invalid, invalid, [getTranslation("dialog_button_ok")])
End Function


Function onQueryStatusOfMagicLinkError(errorResponse)
  tubiLog("SignInHelpers.onQueryStatusOfMagicLinkError")
  currentScreen = getCurrentScreen()

  if currentScreen <> invalid AND (currentScreen.id = m.constants.ui.screenIds.emailVerificationScreen OR currentScreen.id = m.constants.ui.screenIds.forgotPasswordProcessingScreen)
    currentScreen.queryResponseError = currentScreen.queryResponseError + 1
    if currentScreen.queryResponseError > 3
      '//if an error has been set more than 3 times, then show error modal to user as the error is probably not a temporary network or server issue
      currentScreen.queryResponseError = 0
      if shouldShowSignInSignUpErrorPage(errorResponse) = true
        showSignInSignUpErrorScreen("signIn", invalid, false)
      else
        handleSignInFailure(errorResponse)
      end if
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
    analyticsScreenId: m.constants.ui.screenIds.signInScreen
  })
End Function


Function afterSignInPlayLockedLinearContent(callbackAfterSignInParams = invalid)
  tubilog("SignInHelpers.afterSignInPlayLockedLinearContent")
  popScreenAfterSignInProcess()
  if callbackAfterSignInParams <> invalid
    playLinearVideoContent(callbackAfterSignInParams.content, callbackAfterSignInParams.bMinimized, callbackAfterSignInParams.AssociatedScreenID, callbackAfterSignInParams.bAllowTransportToAppear, callbackAfterSignInParams.playbackSource)
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


Function refreshUiAfterSignIn()
  setUiModeFromState()
  refreshHomeScreenSideNav()
End Function


' @param action: string, Possible values "signIn", "signUp"
' @param userInput: assocArray|invalid, Will contains user input data when the action is "signUp"
' @param wasRegistrationQueued: boolean, indicates if the registration was queued.
Function showSignInSignUpErrorScreen(action, userInput, wasRegistrationQueued = false)
  ' Force hiding the side nav in case the user click sign in from side nav and landed on this
  hideNavMenu(false)
  showContentGroupAndHideSpinner()
  displayDefaultBackground()
  screen = CreateObject("roSGNode", "SignInSignUpErrorScreen")
  screen.wasRegistrationQueued = wasRegistrationQueued
  screen.userInput = userInput
  screen.action = action
  pushScreen(screen, true, true)
  screen.observeFieldScoped("continueButtonSelected", "onSignUpSignInErrorScreenContinueAsGuestUserButtonSelected")
End Function


Function onSignUpSignInErrorScreenContinueAsGuestUserButtonSelected(msg)
  screen = msg.getRoSGNode()

  if isOneTrustConsentEnabled() = false AND (isAllowedByPassRegistration() = true OR screen.wasRegistrationQueued = true)
    currentTimeSeconds = CreateObject("roDateTime").AsSeconds()
    ' 12 hours.
    expiryTimeInSeconds = currentTimeSeconds + (12 * 3600)
    regWrite("expiryTime", expiryTimeInSeconds.toStr(), m.constants.registrySectionIDs.registrationByPass)

    currentScreen = msg.getRoSGNode()

    if currentScreen.action = "signUp"
      userInfo = FormatJson(currentScreen.userInput)
      regWrite("userInfo", userInfo, m.constants.registrySectionIDs.registrationByPass)
    end if
    setContentToRefreshAllPersonalizedScreens(true)
  end if

  currentScreen = popScreenAfterSignInProcess()
  m.spinner.visible = false
  refreshAllDetailScreens()
  focusSideNavOption(m.constants.ui.sideNavIds.home)
  if currentScreen <> invalid AND currentScreen.getSubtype() = "DetailScreen"
    currentScreen.jumpToItem = 0
    currentScreen.setfocus(true)
    currentScreen.refreshRelatedContent = true
  end if
End Function


Function isAllowedByPassRegistration()
  eventStart = getExternalConfigValueFromGlobal("special_event_onboarding_start_time", m.constants.configHubFallbacks.majorEventStart)
  eventEnd = getExternalConfigValueFromGlobal("special_event_onboarding_end_time", m.constants.configHubFallbacks.majorEventEnd)
  return isNowWithinTimePeriod(eventStart, eventEnd)
End Function


Function shouldShowSignInSignUpErrorPage(errorResponse)
  ' Checking for less than greater than 500, 429 and less than 200 to handle cases where error code is like -1236 which is returned when we have network error.
  if errorResponse <> invalid AND errorResponse.code <> invalid AND (errorResponse.code >= 500 OR errorResponse.code = 429 OR errorResponse.code < 200)
    wasRegistrationQueued = isAA(errorResponse.info) = true AND errorResponse.info.code = "ACCOUNT_PENDING_PROCESSING"
    if isAllowedByPassRegistration() = true OR wasRegistrationQueued = true
      return true
    end if
  end if

  return false
End Function


Function onEmailVerificationScreenContinueAsGuestUserButtonSelected(msg)
  currentTimeSeconds = CreateObject("roDateTime").AsSeconds()
  expiryTimeInSeconds = currentTimeSeconds + (12 * 3600)
  regWrite("expiryTime", expiryTimeInSeconds.toStr(), m.constants.registrySectionIDs.registrationByPass)

  setContentToRefreshAllPersonalizedScreens(true)
  currentScreen = popScreenAfterSignInProcess()
  m.spinner.visible = false
  refreshAllDetailScreens()
  focusSideNavOption(m.constants.ui.sideNavIds.home)
  if currentScreen <> invalid AND (currentScreen.getSubtype() = "DetailScreen" OR currentScreen.getSubtype() = "DetailScreenHoriz")
    currentScreen.jumpToItem = 0
    currentScreen.setfocus(true)
    currentScreen.refreshRelatedContent = true
  end if
End Function
