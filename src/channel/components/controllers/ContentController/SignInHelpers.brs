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
  onStopAndClearEmailVerificationTimer()
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
    parsedresponse = response.parsedresponse
    requestInput = response.requestInput

    if parsedresponse <> invalid AND requestInput <> invalid
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

      if parsedresponse.taken = true
        '//user's email address exists in Tubi servers, so user can sign into their Tubi account
        dateTime = createObject("roDateTime")
        dateTime.fromISO8601String(m.constants.time.magicLinkStartDate)
        magicLinkStartDate = dateTime.asSeconds()

        dateTime.fromISO8601String(m.constants.time.magicLinkEndDate)
        magicLinkEndDate = dateTime.asSeconds()

        currentUnixTime = getCurrentUTCTimeWithOffset(m.constants)

        ' Can only use magic link when Roku allows us to
        if currentUnixTime >= magicLinkStartDate AND currentUnixTime <= magicLinkEndDate then
          showEmailVerificationScreen(email)
          m.email = email
          createMagicLinkRequest(email)
        else
          showSignInScreen(rawInput)
        end if
      else
        '//user's email address does not exist in Tubi servers, so sign user up with a new Tubi account
        m.authInfoReceived = false
        signUpCredentials = {}
        signUpCredentials.email = email
        signUpCredentials.emailType = emailType
        signUpCredentials.gender = gender
        signUpCredentials.lastName = lastName
        if isNonEmptyString(firstName) = true
          signUpCredentials.firstName = firstName
        else
          '//if first name does not exist, (i.e. when the user manually enters their email address),
          '// then use the 1st part of the email address
          signUpCredentials.firstName = Left(email.split("@")[0], 20) ' limiting by 20 characters for the firstname field
        end if
        showAgeVerificationScreenAtSignUp(signUpCredentials)
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
  signInScreen.observeFieldScoped("emailSelected", "onSignInScreenEmailSelected")
  signInScreen.observeFieldScoped("staticPageSelected", "onStaticPageSelected")
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
  emailScreen.id = m.constants.ui.screenIds.emailScreen
  emailScreen.observeFieldScoped("continueSelected", "onEmailInputContinueSelected")
  emailScreen.observeFieldScoped("backButtonSelected", "onEmailInputBackButtonSelected")
  emailScreen.observeFieldScoped("backgroundUriList", "onScreenBackgroundUpdated")
  pushScreen(emailScreen, true, true)
End Function


Function onBackgroundScreenUpdated(msg)
  TubiLog("SignInHelpers.onBackgroundScreenUpdated")
  screen = msg.getRoSGNode()
  if screen <> invalid
    m.backgroundGroup.backgroundInfo = {
      type: getBackgroundtype(screen.backgroundUriList)
      uriList: screen.backgroundUriList
    }
  end if
End Function


' onStaticPageSelected callback is triggered when user selects static links on signUp/signIn screens
Function onStaticPageSelected(evt)

  staticPageSelected = evt.getData()
  ' sending static page name(ToS/PP/DoNotSellMyInfo) & screen level
  currentScreen = getCurrentScreen()
  pageSource = ""
  if currentScreen <> invalid AND currentScreen.getSubtype() = "SignInScreen"
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
  if currentScreen <> invalid AND currentScreen.getSubtype() =  "SignInScreen"
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

  else if m.callbackAfterSignIn <> invalid
    callbackAfterSignIn = m.callbackAfterSignIn
    m.callbackAfterSignIn = invalid ' setting to invalid to avoid future callbacks

    if m.callbackAfterSignInParams <> invalid
      callbackAfterSignInParams = m.callbackAfterSignInParams
      m.callbackAfterSignInParams = invalid
      callbackAfterSignIn(callbackAfterSignInParams)
    else
      callbackAfterSignIn()
    end if

  else
    ' this should not happen but start the channel in case it somehow does
    startChannel()
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
  startChannel()

End Function


Function onMatureContentWarningSignInCompleted()
  tubiLog("SignInHelpers.onMatureContentWarningSignInCompleted")

  setContentToRefreshAllPersonalizedScreens(false)

  currentScreen = popScreenAfterSignInProcess()
  m.spinner.visible = false

  if currentScreen <> invalid AND currentScreen.getSubtype() = "DetailScreen"
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
  authInfo = handleUpdatedAuth()

  ' set the mode before any changes are done to the UI
  setUiMode(m.constants.ui.modes.standard)

  setContentToRefreshAllPersonalizedScreens()
  setSideNavSignedInItem(authInfo)
  'clear the linearVideoplayer so that locked content will not get played.
  stopAndHideLinearVideoPlayer()
  startChannel()
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
  m.global.likeIds = m.authTask.likes
  m.authInfoReceived = true
  m.authTask.unobserveFieldScoped("authInfo")
  m.authTask = invalid

  setSideNavSignedInItem(authInfo)

  'set the autoplayVideoPreview on/off based on user global settings.
  setAutoplayVideoPreviewFromGlobal(authInfo)

  return authInfo
End Function



' onQueueAfterSignIn - occurs after activation success via Add to My List on Details page
Function onQueueAfterSignIn()
  tubiLog("SignInHelpers.onQueueAfterSignIn")

  ' setContentToRefresh is not required for homescreen as we are fetching homescreen content
  ' right after adding into queue when onBookmarkedAfterSignIn() is called.
  ' We need to enforce that content is added to queue first, before re-fetching the homescreen.
  setContentToRefreshAllPersonalizedScreens(false)

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

  setContentToRefreshAllPersonalizedScreens()

  currentScreen = popScreenAfterSignInProcess()
  m.spinner.visible = false

  if currentScreen <> invalid and currentScreen.getSubtype() = "DetailScreen"
    currentScreen.removeSignupButton = true
    currentScreen.jumpToItem = 0
    onLike(currentScreen)
    'refresh the detail screen in case the newly signed in user has any progress with the current content
    refreshDetailScreenContent(currentScreen)
  end if
End Function


' onDislikeAfterSignIn - occurs after activation success via Dislike Button on Details page
Function onDislikeAfterSignIn()
  tubiLog("SignInHelpers.onDislikeAfterSignIn")

  setContentToRefreshAllPersonalizedScreens()

  currentScreen = popScreenAfterSignInProcess()
  m.spinner.visible = false

  if currentScreen <> invalid and currentScreen.getSubtype() = "DetailScreen"
    currentScreen.removeSignupButton = true
    currentScreen.jumpToItem = 0
    onDislike(currentScreen)
    'refresh the detail screen in case the newly signed in user has any progress with the current content
    refreshDetailScreenContent(currentScreen)
  end if
End Function


' onCWRowAfterSignIn - occurs after activation success via CWRow on homescreen
Function onCWRowAfterSignIn()
  tubiLog("SignInHelpers.onCWRowAfterSignIn")

  setUiModeFromState()

  setContentToRefreshAllPersonalizedScreens()

  startChannel()
End Function


Function onRegistrationProcessCompletedOnDetailsScreen()
  tubiLog("SignInHelpers.onRegistrationProcessCompletedOnDetailsScreen")
  setContentToRefreshAllPersonalizedScreens(true)

  currentScreen = popScreenAfterSignInProcess()
  m.spinner.visible = false
  refreshAllDetailScreens()

  if currentScreen <> invalid and currentScreen.getSubtype() = "DetailScreen"
    currentScreen.jumpToItem = 0
    currentScreen.setfocus(true)
  end if
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

  currentScreen = popScreenAfterSignInProcess()
  m.spinner.visible = false

  if currentScreen <> invalid AND currentScreen.getSubtype() = "SettingsScreen"
    setSettingsScreenSignInInfo()
    currentScreen.setFocus(true)
  end if

  onAutoPreviewSettingSelected()

End Function


' After the user clicks on the Sign In Menu item and then signs in, then this function should be called to display the home screen
Function onSignInAfterInitialContentScreen()
  reloadDefaultHomeScreenContent()
  showDefaultHomeScreen()
End Function


Function popScreenAfterSignInProcess()
  poppableScreenSubtypes = {
    "SignInScreen": true
    "EmailInputScreen": true
    "AgeVerificationScreen": true
    "SignUpAgeVerificationScreen": true
    "EmailVerificationScreen": true
  }

  count = m.screenStack.getChildCount()-1
  for i = count to 0 step -1
    screen = m.screenStack.getChild(i)
    if screen <> invalid AND poppableScreenSubtypes[screen.getSubtype()] = true
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


Function onMagicLinkResponse(response)
  tubiLog("SignInHelpers.onMagicLinkResponse")
  currentScreen = getCurrentScreen()
  if response <> invalid
    if currentScreen.id = m.constants.ui.screenIds.emailVerificationScreen
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

  errorCode = getUserFacingErrorCode(m.constants.errors.context.emailVerificationScreen, m.constants.errors.subtypes.networkError, errorResponse)
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


' showEmailVerificationScreen will send verification email to the roku account or
' user entered email if user choose different email.
' once user verified their email, it will redirect to the appropriate screen.
' If the user doesn't receive verification link, they can select resend verification.

' @email : string,  (either taken from roku account or user entered email)
Function showEmailVerificationScreen(email)
  tubiLog("SignInHelpers.showEmailVerificationScreen")
  emailVerificationScreen = CreateObject("roSGNode", "EmailVerificationScreen")
  emailVerificationScreen.id = m.constants.ui.screenIds.emailVerificationScreen
  emailVerificationScreen.username = email
  emailVerificationScreen.observeFieldScoped("selectedDifferentEmail", "showEmailScreen")
  emailVerificationScreen.observeFieldScoped("backButtonSelected", "onStopAndClearEmailVerificationTimer")
  emailVerificationScreen.observeFieldScoped("resendVerificationLink", "onResendVerificationLink")
  pushScreen(emailVerificationScreen, true, true)
  displayDefaultBackground()
End Function


Function onEmailVerificationTimerFired()
  tubiLog("SignInHelpers.onEmailVerificationTimerFired")
  'Make Request
  uid = ""
  currentScreen = getCurrentScreen()
  if currentScreen <> invalid AND currentScreen.id = m.constants.ui.screenIds.emailVerificationScreen
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
  if response <> invalid AND response.status = "PENDING"
    m.emailVerificationTimer.control = "start"
  else if response <> invalid AND response.access_token <> invalid
    onStopAndClearEmailVerificationTimer()
    Auth = TubiAuth(m.constants, m.Request)
    Auth.handleRegistration(response)
    onSignInResponse(invalid)
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
  if currentScreen.id = m.constants.ui.screenIds.emailVerificationScreen
    currentScreen.queryResponseError = currentScreen.queryResponseError + 1
    if currentScreen.queryResponseError > 3
      currentScreen.queryResponseError = 0
      errorCode = getUserFacingErrorCode(m.constants.errors.context.emailVerificationScreen, m.constants.errors.subtypes.expireError, errorResponse)
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
    email: email
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


Function afterSignInPlayLockedLinearContent(callbackAfterSignInParams)
  tubilog("SignInHelpers.afterSignInPlayLockedLinearContent")
  popScreenAfterSignInProcess()
  if callbackAfterSignInParams <> invalid
    playLinearVideoContent(callbackAfterSignInParams.content, callbackAfterSignInParams.bMinimized, callbackAfterSignInParams.AssociatedScreenID, callbackAfterSignInParams.bAllowTransportToAppear)
  end if
  showHideSpinner(false)
  setContentToRefreshAllPersonalizedScreens(true)
End Function


Function AfterSignInPlayLockedContent(callbackAfterSignInParams)
  tubilog("SignInHelpers.AfterSignInPlayLockedContent")

  popScreenAfterSignInProcess()

  if callbackAfterSignInParams <> invalid
    playVideoContent(callbackAfterSignInParams.content, callbackAfterSignInParams.playbackSource, callbackAfterSignInParams.position)
  end if
  refreshAllDetailScreens()
  setContentToRefreshAllPersonalizedScreens(true)
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
