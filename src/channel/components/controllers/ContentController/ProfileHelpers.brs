' @constants: assocArray, constants as set in Constants.brs
Function showProfileSelectorScreen(constants, profiles = invalid, disableBack = false)
  tubiLog("ProgileHelpers.showProfileSelectorScreen")

  showHideLogo(m.constants.logoType.tubi)
  displayDefaultBackground()

  profileSelectorScreen = CreateObject("roSGNode", "ProfileSelectorScreen")
  profileSelectorScreen.id = constants.ui.screenIds.profileSelectorScreen
  profileSelectorScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
  profileSelectorScreen.observeFieldScoped("componentInteractionInfo", "onComponentInteractionInfoChange")
  profileSelectorScreen.observeFieldScoped("transportVoiceResponse", "onTransportVoiceResponse")
  profileSelectorScreen.observeFieldScoped("profileSelected", "onProfileSelected")
  profileSelectorScreen.disableBack = disableBack
  profileSelectorScreen.isStackable = true
  profileSelectorScreen.screenLevel = constants.ui.screenLevels.signInScreen

  profileSelectorScreen.shouldFocusWhenPushed = m.top.fadeInContentController
  'fetch new profiles if provided profiles is invalid or empty.
  if profiles = invalid OR profiles.count() = 0
    profiles = m.tubiAuthUpdate.getAllProfilesAuthInfo()
  end if

  if profiles = invalid OR getUserProfileCount(profiles) = 0
    startChannelFromAppLoad()
  else
    menuContent = getProfilesListContent(profiles)
    pCount = menuContent.getChildCount()
    if pCount > 0 'at least one profile is present
      if isKidsUIOn() <> true
        'append add account item
        addProfileItem = createObject("roSGNode", "ContentNode")
        addProfileItem.id = "add_profile"
        addProfileItem.HDPosterUrl = "pkg:/images/add_profile.png"
        addProfileItem.title = "+"
        addProfileItem.shortDescriptionLine1 = getTranslation("add_account")
        addProfileItem.addField("addFreeIcon", "boolean", false)
        addProfileItem.addFreeIcon = true
        addProfileItem.shortDescriptionLine2 = getTranslation("screenSideNav_add_account_description")
        menuContent.appendChild(addProfileItem)
      end if
      profileSelectorScreen.content = menuContent

      shouldSendPageLoadEvent = true
      if profileSelectorScreen.contentReady = false
        'First batch of Contents are not ready. So send the pageloadEvent after onContentReady()
        shouldSendPageLoadEvent = false
        showHideSpinner(true)
      else
        showHideSpinner(false)
      end if

      pushScreen(profileSelectorScreen, false, shouldSendPageLoadEvent)
    else
      startChannelFromAppLoad()
    end if
  end if



End Function


Function getProfilesListContent(profiles, excludeKids = false)
  menuContent = createObject("roSGNode", "ContentNode")
  for each profile in profiles
    item = profiles[profile]
    excludeProfile = false

    if profile = "guest"
      excludeProfile = true 'exclude the guest profile
    else if excludeKids = true
      excludeProfile = (isNonEmptyString(item.parentId) = true) 'exclude the kids profile
    end if

    if excludeProfile = false
      menuItem = createObject("roSGNode", "ContentNode")
      menuItem.id = profile
      menuItem.HDPosterUrl = item.avatarUrl
      ' Unfortunatly kids profiles will have only name and not first name.
      if isNonEmptyString(item.firstName) = true
        menuItem.title = item.firstName.left(1)
      else if isNonEmptyString(item.name) = true
        menuItem.title = item.name.left(1)
      end if

      menuItem.shortDescriptionLine1 = item.name
      menuItem.addField("hasPin", "boolean", false)
      menuItem.hasPin = item.hasPin
      menuItem.addField("isKidsAccount", "boolean", false)
      menuItem.isKidsAccount = (isNonEmptyString(item.parentId) = true)
      menuContent.appendChild(menuItem)
    end if
  end for
  return menuContent
End Function


Function onProfileSelected(msg)
  profileSelected = msg.getData()
  parentScreen = msg.getRoSGNode()
  parentScreenType = ""

  if parentScreen <> invalid
    parentScreenType = parentScreen.getSubtype()
  end if

  handleBeforeProfileSelection(parentScreenType)

  sendAccountSelectionEvent(profileSelected, parentScreenType)

  if profileSelected = "add_profile"
    showAddProfileScreen()
  else if profileSelected = "guest"

    if parentScreen <> invalid AND parentScreen.getSubtype() = "ProfileSelectorScreen"
      handleGuestProfileSelection()
    else
      handleProfileSelectionViaGate(profileSelected)
    end if
  else

    if parentScreen <> invalid AND parentScreen.getSubtype() = "ProfileSelectorScreen"
      handleRegularProfileSelection(profileSelected)
    else
      handleProfileSelectionViaGate(profileSelected)
    end if

  end if

End Function


Function sendAccountSelectionEvent(profileSelected, parentScreenType)
  trackingPage = ""

  if isNonEmptyString(parentScreenType) = true AND isNonEmptyString(profileSelected) = true
    if parentScreenType = "ProfileSelectorScreen"
      trackingPage = "account_selection_page"
    else
      trackingPage = "home_page"
    end if

    ' send account_selection_event
    if isNonEmptyString(trackingPage) = true AND profileSelected <> "add_profile"

      profileAuthInfo = m.tubiAuthUpdate.getProfileAuthInfo(profileSelected)
      if isNonEmptyString(profileAuthInfo.userId) = true
        selectedUserId = profileAuthInfo.userId.toInt()
      else
        selectedUserId = 0
      end if

      trackingEvent = {
        type: "account_selection"
        values: {
          pageOneof: m.Tracking.getAnalyticsPage(trackingPage, {})
          selected_user_id: selectedUserId
        }
      }
      m.trackingLoggingTask.trackEvent = trackingEvent
    end if
  end if

End Function


Function handleProfileSelectionViaGate(profileSelected)
  authInfo = m.tubiAuthUpdate.getAuthInfo()
  profileAuthInfo = m.tubiAuthUpdate.getProfileAuthInfo(profileSelected)
  if authInfo.tubiId <> profileAuthInfo.tubiId

    userSwitchAction = getUserSwitchAction(authInfo, profileAuthInfo)
    sourceProfile = pickSourceProfileForPWScreen(authInfo, profileAuthInfo)

    if userSwitchAction = "passwordGate" AND shouldShowPWScreenToExitKidsMode(sourceProfile.tubiId) = true
      showPasswordValidateScreen(authInfo, profileAuthInfo, onPasswordValidateSubmitted)
    else if userSwitchAction = "pinGate"
      processKidsPinGate(authInfo, profileAuthInfo)
    else if userSwitchAction = "ageGate" AND needsToShowAgeVerificationScreen() = true
      showAgeVerificationScreenAtKidsModeExit(m.uiMode)
    else if userSwitchAction = "signInPasswordGate" AND shouldShowPWScreenToExitKidsMode(sourceProfile.tubiId) = true
      showPasswordValidateScreen(authInfo, profileAuthInfo, onEmailPasswordValidateSubmitted)
    else if userSwitchAction = "NotAllowed"
      'do nothing here
    else
      if profileSelected = "guest"
        handleGuestProfileSelection()
      else
        handleRegularProfileSelection(profileSelected)
      end if
    end if
  else
    focusCurrentScreen()
  end if
End Function


Function handleGuestProfileSelection()

  ' Check if guest profile exists in registry
  guestProfileAuth = m.tubiAuthUpdate.getProfileAuthInfo("guest")

  if guestProfileAuth.count() > 0
    if m.getAuthOperationInProgress = false then
      m.getAuthOperationInProgress = true
      m.tubiAuthUpdate.copyProfileToMainAuth("guest")
      m.tubiAuthUpdate.initOrUpdateAuthInfo(onUpdatedAuthRetrieved, false)
      setUiModeForProfileSelected(guestProfileAuth)
      clearGlobalUserData()
      removeEPGFavoritesOnSignOut()
      resetUserServerPersistentData()
      updateConsentAndServerPersistentData()
    end if
  else
    ' Setting focus to spinner before calling logout(), which triggers the home screen to refresh and gain focus.
    m.spinner.visible = true
    m.spinner.setFocus(true)
    logout(updateConsentAndServerPersistentData)
  end if

End Function


Function handleRegularProfileSelection(profileId)
  profileAuth = m.tubiAuthUpdate.getProfileAuthInfo(profileId)

  if profileAuth.count() > 0 AND profileId <> invalid
    if m.getAuthOperationInProgress = false then
      m.getAuthOperationInProgress = true
      m.tubiAuthUpdate.copyProfileToMainAuth(profileId)
      m.tubiAuthUpdate.initOrUpdateAuthInfo(onUpdatedAuthRetrieved, false)
    end if

    authInfo = m.tubiAuthUpdate.getAuthInfo()
    if authInfo.tubiId = profileAuth.tubiId
      onSwitchProfileSuccess(authInfo)
    end if
  else
    handleGuestProfileSelection()
  end if
End Function


Function onSwitchProfileSuccess(authInfo)

  m.spinner.visible = true
  m.spinner.setFocus(true)
  setSideNavForProfileSelected(authInfo)
  setUiModeForProfileSelected(authInfo)

  resetUserServerPersistentData()

  if isNonEmptyString(authInfo.parentId) = true
    callback = refreshForKidsProfile
  else
    callback = refreshConsent
  end if

  clearglobalUserData()
  removeEPGFavoritesOnSignOut()
  getUserInfo(callback)
  showWelcomeProfileToast(authInfo)

End Function


Function refreshForKidsProfile()
  refreshUserServerPersistentData(onPostSignInAuthInfoUpdated)
  handleUpdatedAuth()
End Function


Function showAddProfileScreen()
  hideNavMenu(false)
  stopAllVideoPlayers()
  if getUserProfileCount() >= m.constants.ui.maxProfileCount
    showAccountLimitReachedModal()
  else
    showEmailScreenWithProfileSelection()
  end if

End Function


Function showAccountLimitReachedModal()
  title = getTranslation("dialog_account_limit_reached_title")
  message = getTranslation("dialog_account_limit_reached_description")

  currentScreen = getCurrentScreen()
  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: "INFORMATION" 'DialogType enum
      pageOneof: m.Tracking.getAnalyticsPage(currentScreen.trackingPageInfo.pageType, currentScreen.trackingPageInfo.pageValues)
      dialog_action: "SHOW"
      dialog_sub_type: "account_limit_reached"
    }
  }
  buttons = [getTranslation("dialog_button_close")]
  showSimpleInstantResumableModal(title, message, buttons, dialogEvent, m.trackingLoggingTask)
End Function


Function handleBeforeProfileSelection(parentScreenType)

  if parentScreenType = "ProfileSelectorScreen"
    stopAllVideoPlayers()
    hideNavMenu(false)
    if m.callbackAfterSignIn = invalid
      m.callbackAfterSignIn = refreshScreenAndContentAfterSignIn
    end if

  else if parentScreenType = "SideNav"
    m.callbackAfterSignIn = onSideNavSignInCompleted
    stopAllVideoPlayers()
    hideNavMenu(false)
  end if
End Function


Function stopAllVideoPlayers()
  ' Calling stop on all the player to be on safer side.
  stopVideoPreview()

  if isLinearPlayerLoadingOrPlaying() = true
    stopLinearVideoContent()
  end if

  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.videoPlayerScreen)
  stopVideoContent(videoPlayer)

End Function


Function updateConsentAndServerPersistentData()
  getConsentAfterSignOut()
  getServerPersistentData()
End Function


Function showKidsAccountSetupScreen(signInInfo, parentProfileInfo)
  kidsAccountSetupScreen = createObject("roSGNode", "KidsAccountSetupScreen")
  kidsAccountSetupScreen.id = m.constants.ui.screenIds.kidsAccountSetupScreen
  kidsAccountSetupScreen.signInInfo = signInInfo
  kidsAccountSetupScreen.parentProfile = parentProfileInfo

  kidsAccountSetupScreen.observeFieldScoped("startWatchBtnSeleted", "onKidsAccountSetupContinueSelected")
  kidsAccountSetupScreen.observeFieldScoped("backButtonSelected", "onKidsAccountSetupContinueSelected")
  kidsAccountSetupScreen.observeFieldScoped("backgroundUriList", "onScreenBackgroundUpdated")
  pushScreen(kidsAccountSetupScreen, true, true)
End Function


Function onKidsAccountSetupContinueSelected()
  onActivationSuccess()
  registerEvent = {
    type: "register"
    values: {
      progress: "CLICKED_REGISTER"
    }
  }

  m.trackingLoggingTask.trackEvent = registerEvent

End Function


Function showParentalControlPinInputScreen(signInInfo)
  parentalControlPinInputScreen = createObject("roSGNode", "ParentalControlPinInputScreen")
  parentalControlPinInputScreen.id = m.constants.ui.screenIds.parentalControlPinInputScreen
  parentalControlPinInputScreen.screenLevel = m.constants.ui.screenLevels.ageGateScreen
  parentalControlPinInputScreen.signInInfo = signInInfo
  parentalControlPinInputScreen.observeFieldScoped("pinSubmitted", "onPinSubmittedForKidsAccount")
  parentalControlPinInputScreen.observeFieldScoped("backButtonPressed", "onBackButtonPressed")
  parentalControlPinInputScreen.observeFieldScoped("backgroundUriList", "onScreenBackgroundUpdated")
  parentalControlPinInputScreen.mode = "add_pin"
  pushScreen(parentalControlPinInputScreen, true, true)
End Function


Function onPinSubmittedForKidsAccount(msg)
  parentalControlPinInputScreen = msg.getRoSGNode()
  isPinSubmitted = msg.getData()

  if isPinSubmitted = true
    signInInfo = parentalControlPinInputScreen.signInInfo
    'send register event

    registerEvent = {
      type: "register"
      values: {
        progress: "COMPLETED_PIN"
      }
    }

    m.trackingLoggingTask.trackEvent = registerEvent

    verifyKidsAtSignup(signInInfo)
  end if
End Function


Function verifyKidsAtSignup(signInInfo)

  if signInInfo <> invalid AND isNumber(signInInfo.parental_rating_v2) AND (isNonEmptyString(signInInfo.name) = true OR isNonEmptyString(signInInfo.firstName) = true)
    options = {}

    name = signInInfo.firstName

    if isNonEmptyString(signInInfo.name) = true
      name = signInInfo.name
    end if

    options.body = {
      platform: m.constants.platform
      device_id: m.constants.deviceInfo.deviceId
      name: name
      parental_rating_v2: signInInfo.parental_rating_v2
    }
    if signInInfo.pinSubmitted <> invalid
      options.body["pin"] = signInInfo.pinSubmitted
    end if

    'This is because backend wants us to send only selected parent's token. Remember to delete it after successfull kid signup
    if isUserInMultiAccount() = true AND signInInfo.parentProfileId <> invalid
      profileId = signInInfo.parentProfileId
      m.tubiAuthUpdate.copyProfileToMainAuth(profileId)
    end if

    requestInfo = m.userDeviceApi.signUpReqInfoForKids(options)
    m.makeRequest({
      url: requestInfo.url
      requestType: m.constants.reqNames.signUpForKids
      options: requestInfo.options
      successCallback: onSignUpForKidsResponse
      errorCallback: onAgeNotVerifiedAtSignup 'TODO Check For 422, 451, 400, and GDPR etc
      responseType: "assocarray"
      signInInfo: signInInfo
      analyticsScreenId: m.constants.ui.screenIds.signUpAgeVerificationScreen
    })
  else
    ' not expected to ever happen, so punt and start the app normally if it does
    runControllerStartSequenceAsAgeNotVerified()
  end if


End Function


Function onSignUpForKidsResponse(response)
  if response <> invalid
    isUsrInMultiAccount = isUserInMultiAccount()
    parentTubiId = response.parent_tubi_id
    parentProfileInfo = m.tubiAuthUpdate.getAuthInfo()
    m.tubiAuthUpdate.deleteAuthInfo() 'this is needed because we copied the parent's auth

    m.tubiAuthUpdate.handleRegistration(response, isUsrInMultiAccount)

    hasPin = (response.parent_has_pin = true)


    if isNonEmptyString(parentTubiId) = true
      ' update the local authInfo for the kids account
      m.tubiAuthUpdate.createOrUpdateProfileAuth(parentTubiId, { haspin: hasPin })
    end if

    accountEvent = {
      type: "account"
      values: {
        manip: "SIGNUP_KID"
        message: "SUCCESS"
        current: "EMAIL"
        status: "SUCCESS"
      }
    }

    m.trackingLoggingTask.trackEvent = accountEvent

    showKidsAccountSetupScreen(response, parentProfileInfo)
  end if
End Function


Function onAgeSelectedAtSignUpForKids(msg)
  ageVerificationScreen = msg.getRoSGNode()
  signInInfo = ageVerificationScreen.signInInfo

  registerEvent = {
    type: "register"
    values: {
      progress: "COMPLETED_CONTENT_SETTING"
    }
  }

  m.trackingLoggingTask.trackEvent = registerEvent

  hasPin = false
  if signInInfo <> invalid
    hasPin = signInInfo.hasPin
  end if

  if hasPin = true
    verifyKidsAtSignup(signInInfo)
  else
    showParentalControlPinInputScreen(signInInfo)
  end if

End Function


Function processKidsPinGate(authInfo, profileAuthInfo)
  'This means that user is a Kid and trying to switch to a regular profile. We need to PIN gate the user.
  parentId = authInfo.parentId
  if parentId <> invalid
    parentAuthInfo = m.tubiAuthUpdate.getProfileAuthInfo(parentId)
    if parentAuthInfo.count() > 0
      if (isBoolean(parentAuthInfo.hasPin) = true AND parentAuthInfo.hasPin = true) OR (isString(parentAuthInfo.hasPin) AND parentAuthInfo.hasPin = "true")
        verifyParentalControlPin(parentAuthInfo, profileAuthInfo)
      else
        profileSelected = profileAuthInfo.tubiId
        handleRegularProfileSelection(profileSelected)
      end if
    end if
  end if
End Function


Function verifyParentalControlPin(parentAuthInfo, profileAuthInfo)
  pinVerifyScreen = createObject("roSGNode", "ParentalControlPinInputScreen")
  pinVerifyScreen.signInInfo = profileAuthInfo
  pinVerifyScreen.observeFieldScoped("pinSubmitted", "onVerifyPintoExitKids")
  pinVerifyScreen.observeFieldScoped("backButtonPressed", "onBackButtonPressed")
  pinVerifyScreen.observeFieldScoped("forgotPinSelected", "onForgotPinSelected")
  pinVerifyScreen.observeFieldScoped("backgroundUriList", "onScreenBackgroundUpdated")
  pinVerifyScreen.mode = "enter_pin"
  pushScreen(pinVerifyScreen, true, true)

End Function


Function onVerifyPintoExitKids(msg)
  pinVerifyScreen = msg.getRoSGNode()
  pinSubmitted = pinVerifyScreen.text

  requestInfo = m.userDeviceApi.validatePinReqInfoForKidsAccount(pinSubmitted)
  m.makeRequest({
    url: requestInfo.url
    requestType: m.constants.reqNames.validatePin
    options: requestInfo.options
    successCallback: onPinValidateSuccess
    errorCallback: onPinValidateError
    responseType: "assocarray"
  })
End Function


Function onPinValidateSuccess(response)
  tubiLog("ProfileHelpers.onPinValidateSuccess")
  screen = getCurrentScreen()

  if response <> invalid AND response.valid = true AND screen.getSubtype() = "ParentalControlPinInputScreen"
    profileId = "guest"
    profileAuthInfo = screen.signInInfo
    if profileAuthInfo <> invalid AND isNonEmptyString(profileAuthInfo.tubiId) = true
      profileId = profileAuthInfo.tubiId
    end if

    if profileId = "guest"
      handleGuestProfileSelection()
    else
      handleRegularProfileSelection(profileId)
    end if
  else
    onPinValidateError()
  end if

End Function


Function onPinValidateError(error = invalid)
  tubiLog("ProfileHelpers.onPinValidateError")
  parentalControlPinInputScreen = getCurrentScreen()

  if parentalControlPinInputScreen.getSubtype() = "ParentalControlPinInputScreen"
    if error <> invalid 'to handle special cases like too many failed attemps for PIN
      parentalControlPinInputScreen.errorCode = error.code
    else
      parentalControlPinInputScreen.errorCode = 0
    end if

    parentalControlPinInputScreen.pinError = true
  end if
End Function



' Returns the appropriate profile to use as name source based on auth type
' @param authInfo - Current user's auth info
' @param profileAuthInfo - Target profile's auth info
Function pickSourceProfileForPWScreen(authInfo, profileAuthInfo)

  if isKidsProfile(authInfo) = true
    return profileAuthInfo
  else if isLoggedInUser(authInfo) = true
    return authInfo
  end if
  return profileAuthInfo
End Function


Function showPasswordValidateScreen(authInfo, profileAuthInfo, successCallback = invalid)
  m.confirmPasswordScreen = CreateObject("roSGNode", "ConfirmPasswordScreen")

  nameSource = pickSourceProfileForPWScreen(authInfo, profileAuthInfo)
  name = nameSource.name

  if isNonEmptyString(name) = false
    name = nameSource.firstName
  end if

  m.confirmPasswordScreen.message = getTranslation("passwordScreen_account_enter_title", { "name": name })
  m.confirmPasswordScreen.setUp = getTranslation("screenSettings_parentalPassword_setup_new_password") + ","
  m.confirmPasswordScreen.visit = getTranslation("screenSettings_parentalPassword_visit_link")

  m.confirmPasswordScreen.profileSelected = profileAuthInfo
  m.confirmPasswordScreen.isLoading = false

  if successCallback = onEmailPasswordValidateSubmitted
    m.confirmPasswordScreen.observeFieldScoped("submitSelected", "onEmailPasswordValidateSubmitted")
  else if successCallback = onPasswordValidateKidsModeExit
    m.confirmPasswordScreen.observeFieldScoped("submitSelected", "onPasswordValidateKidsModeExit")
  else if successCallback = onPasswordValidateForPinUpdate
    m.confirmPasswordScreen.message = getTranslation("screenSettings_pinPassword_title")
    m.confirmPasswordScreen.observeFieldScoped("submitSelected", "onPasswordValidateForPinUpdate")
  else
    m.confirmPasswordScreen.observeFieldScoped("submitSelected", "onPasswordValidateSubmitted")
  end if

  m.confirmPasswordScreen.observeFieldScoped("backPressed", "onSettingsBackPressed")
  m.confirmPasswordScreen.observeFieldScoped("backgroundUriList", "onScreenBackgroundUpdated")
  pushScreen(m.confirmPasswordScreen)
End Function


Function onPasswordValidateSubmitted(msg)
  passwordValidateScreen = msg.getRoSGNode()
  if passwordValidateScreen <> invalid
    password = passwordValidateScreen.passwordText

    if isNonEmptyString(password) = true

      requestInfo = m.userDeviceApi.passwordValidateRegInfo(password)
      m.makeRequest({
        url: requestInfo.url
        requestType: m.constants.reqNames.validatePassword
        options: requestInfo.options
        successCallback: onPasswordValidateSuccess
        errorCallback: onPasswordValidateError
        responseType: "assocarray"
      })
    end if
  end if

End Function


Function onPasswordValidateForPinUpdate(msg = invalid)
  passwordValidateScreen = msg.getRoSGNode()
  if passwordValidateScreen <> invalid
    password = passwordValidateScreen.passwordText

    if isNonEmptyString(password) = true

      requestInfo = m.userDeviceApi.passwordValidateRegInfo(password)
      m.makeRequest({
        url: requestInfo.url
        requestType: m.constants.reqNames.validatePassword
        options: requestInfo.options
        successCallback: onPasswordConfirmForPinUpdate
        errorCallback: onPasswordValidateError
        responseType: "assocarray"
      })
    end if
  end if
End Function


Function onPasswordValidateKidsModeExit(msg)

  passwordValidateScreen = msg.getRoSGNode()
  if passwordValidateScreen <> invalid
    password = passwordValidateScreen.passwordText

    if isNonEmptyString(password) = true

      requestInfo = m.userDeviceApi.passwordValidateRegInfo(password)
      m.makeRequest({
        url: requestInfo.url
        requestType: m.constants.reqNames.validatePassword
        options: requestInfo.options
        successCallback: onPasswordValidateKidsModeExitSuccess
        errorCallback: onPasswordValidateError
        responseType: "assocarray"
      })
    end if
  end if
End Function


Function onPasswordValidateSuccess(response)
  if response <> invalid AND response.valid = true AND isConfirmPasswordScreen() = true
    profileId = "guest"
    profileAuthInfo = m.confirmPasswordScreen.profileSelected
    if profileAuthInfo <> invalid AND isNonEmptyString(profileAuthInfo.tubiId) = true
      profileId = profileAuthInfo.tubiId
    end if

    currentAuthInfo = m.tubiAuthUpdate.getAuthInfo()
    updatePasswordExpiryTimeForProfile(currentAuthInfo)

    if profileId = "guest"
      handleGuestProfileSelection()
    else
      handleRegularProfileSelection(profileId)
    end if
  end if

End Function


Function onPasswordValidateKidsModeExitSuccess(response)
  if response <> invalid AND response.valid = true AND isConfirmPasswordScreen() = true
    disableKidsModeFromSideNav()
    authInfo = m.tubiAuthUpdate.getAuthInfo()
    updatePasswordExpiryTimeForProfile(authInfo)
  else
    onPasswordValidateError(response)
  end if
End Function


Function onPasswordValidateError(_error)

  if isConfirmPasswordScreen() = true
    m.confirmPasswordScreen.isLoading = false
    m.passwordCache = invalid

    currentScreen = getCurrentScreen()
    dialogEvent = {
      type: "dialog"
      values: {
        dialog_type: "PASSWORD_REQUIRED"
        pageOneof: m.Tracking.getAnalyticsPage(currentScreen.trackingPageInfo.pageType, currentScreen.trackingPageInfo.pageValues)
        dialog_action: "SHOW"
        dialog_sub_type: "invalid_password"
      }
    }

    title = getTranslation("invalid_oops_password_title")
    message = getTranslation("invalid_oops_password_description")
    buttons = [getTranslation("dialog_button_ok")]

    showSimpleInstantResumableModal(title, message, buttons, dialogEvent, m.trackingLoggingTask)

  else
    if m.passwordCache <> invalid
      m.passwordCache = invalid
    end if
  end if
End Function


Function onEmailPasswordValidateSubmitted(msg)
  passwordValidateScreen = msg.getRoSGNode()
  if passwordValidateScreen <> invalid
    password = passwordValidateScreen.passwordText
    profileAuthInfo = passwordValidateScreen.profileSelected
    email = invalid
    if isAA(profileAuthInfo) = true AND isNonEmptyString(profileAuthInfo.email) = true
      email = profileAuthInfo.email
    end if

    if isNonEmptyString(password) = true AND isNonEmptyString(email) = true
      signUserIn(email, password, invalid, onSignInToChangeProfileResponse)
    end if

  end if
End Function


' This is a complex function which maps the below table to the various switch requirements.
'  From ↓ Switch To →
'                           | Guest_Normal            | Guest_(Kids_Mode)           | Adult_Account            | Adult_Account(Kids_mode) | Kids_Account_(younger_or_same)     | Kids_Account_(older) | "Add_a_new_account:_Sign_In/_Sign_up
' |-------------------------|-------------------------|-----------------------------|--------------------------|--------------------------|---------------------------------   |----------------------|--------------------------------------------|
' | Guest_Normal            | -------                 | allowed                     | Allowed                  | No_Path                  | allowed                            | allowed              | allowed
' | Guest_(Kids_Mode)       | Age_gate                | -------                     | Age_gate                 | No_Path                  | Age_gate                           | Age_gate             | allowed
' | Guest_(Locked_Kids_Mode)| No_Path                 | -------                     | signInPasswordGate       | No_Path                  | allowed                            | allowed              | allowed
' | Adult_Account           | allowed                 | No_Path                     | allowed                  | allowed                  | allowed                            | allowed              | allowed
' | Adult_Account(Kids_mode)| passWordGate            | No_Path                     | passwordGate             | -------                  | allowed                            | PasswordGate         | allowed
' | Kids_Account_(younger)  | PIN,_if_enabled         | No_Path                     | PIN,_if_enabled          | No_Path                  | allowed                            | PIN,_if_enabled      | allowed
' | Kids_Account_(older)    | PIN,_if_enabled         | No_Path                     | PIN,_if_enabled          | No_Path                  | allowed                            | PIN,_if_enabled      | allowed
' | Adult Account(Kid pc)   | passWordGate            | No_Path                     | passwordGate             | No_path                  | allowed                            | PasswordGate         | allowed


Function getUserSwitchAction(authInfo, profileSelected)
  switchAction = "allowed"

  fromAccount = "adultAccount"
  if m.uiMode = m.constants.ui.modes.kidsAgeGate
    fromAccount = "ageGated"
  else if accountType(authInfo) = "guest"
    if m.uiMode = m.constants.ui.modes.kids'check for profile id may be here
      fromAccount = "guestkid"
    else
      fromAccount = "guest"
    end if
  else if accountType(authInfo) = "adult"
    if m.uiMode = m.constants.ui.modes.kids
      fromAccount = "adultInKidsMode"
    else if m.uiMode = m.constants.ui.modes.kidsParental
      fromAccount = "adultInKidsPC"
    else
      fromAccount = "adultAccount"
    end if
  else if accountType(authInfo) = "kid"
    fromAccount = "kidsAccount"
  end if


  switchToAccount = "adultAccount"
  if accountType(profileSelected) = "guest"
    switchToAccount = "guest"
  else if accountType(profileSelected) = "kid"
    switchToAccount = "kidsAccount"
  end if

  switchmap = {
    "guest-guest": "allowed",
    "guest-adultAccount": "allowed",
    "guest-kidsAccount": "allowed",
    "guestkid-guest": "ageGate",
    "guestkid-adultAccount": "ageGate",
    "guestkid-kidsAccount": "allowed",
    "ageGated-guest": "NotAllowed",
    "ageGated-adultAccount": "signInPasswordGate",
    "ageGated-kidsAccount": "allowed",
    "adultAccount-guest": "allowed",
    "adultAccount-adultAccount": "allowed",
    "adultAccount-kidsAccount": "allowed",
    "adultInKidsMode-guest": "passwordGate",
    "adultInKidsMode-adultAccount": "passwordGate",
    "adultInKidsMode-kidsAccount": "pcCheckPasswordGate",
    "kidsAccount-guest": "pinGate",
    "kidsAccount-kidsAccount": "pcCheckPinGate",
    "kidsAccount-adultAccount": "pcCheckPinGate",
    "adultInKidsPC-guest": "passwordGate",
    "adultInKidsPC-adultAccount": "pcCheckPasswordGate",
    "adultInKidsPC-kidsAccount": "pcCheckPasswordGate"
  }

  pcMap = {
    "0": 1 'younger child
    "1": 2 'older Child
    "2": 4'teen child
    "3": 5 'adult
    "4": 0 'youngest child
    "5": 3 'oldest child
  }

  key = fromAccount + "-" + switchToAccount

  if switchmap.doesExist(key) = true
    isAllowed = switchmap[key]
    if isAllowed = "pcCheckPasswordGate" OR isAllowed = "pcCheckPinGate"
      'check for PC ratings
      if isNonEmptyString(authInfo.parentalRating) = true AND isNonEmptyString(profileSelected.parentalRating) = true AND pcMap[authInfo.parentalRating] >= pcMap[profileSelected.parentalRating]
        switchAction = "allowed"
      else if isAllowed = "pcCheckPinGate"
        if checkIfPinSetByParent(authInfo) = true 'parent has a pin set
          switchAction = "pinGate"
        else
          switchAction = "allowed"
        end if
      else
        switchAction = "passwordGate"
      end if
    else if isAllowed = "pinGate"

      if checkIfPinSetByParent(authInfo) = true
        switchAction = "pinGate"
      else
        switchAction = "allowed"
      end if
    else if isAllowed = "signInPasswordGate"
      switchAction = "signInPasswordGate"
    else
      switchAction = isAllowed
    end if

  end if

  return switchAction
End Function


Function accountType(profile)
  accType = "adult"
  if isNonEmptyString(profile.tubiId) = false
    accType = "guest"
  else if isNonEmptyString(profile.parentId) = true
    accType = "kid"
  end if
  return accType
End Function


Function checkIfPinSetByParent(kidAuthInfo)
  if accountType(kidAuthInfo) = "kid"
    parentAuthInfo = m.tubiAuthUpdate.getProfileAuthInfo(kidAuthInfo.parentId)
    if parentAuthInfo.count() > 0
      if isBoolean(parentAuthInfo.hasPin) = true AND parentAuthInfo.hasPin = true
        return true
      else if isString(parentAuthInfo.hasPin) AND parentAuthInfo.hasPin = "true"
        return true
      end if
    end if
  end if
  return false
End Function


Function setUiModeForProfileSelected(profileAuthInfo)

  if isAA(profileAuthInfo) = true
    if isLoggedInUser(profileAuthInfo) = true 'signed in User
      pcRating = m.pub_serverPersistentData.parentalRating

      hasAge = AnyToStringButNotInvalid(profileAuthInfo.hasAge)

      if hasAge = "false" AND shouldShowAgeGate() = true 'age gated user Should never be one because we log them out. but just in case
        setUiMode(m.constants.ui.modes.kidsAgeGate)
      else if isNonEmptyString(profileAuthInfo.parentId) = false AND (pcRating <> invalid AND (pcRating < 2 OR pcRating = 4 OR pcRating = 5)) 'user has set content settings on themselves
        setUiMode(m.constants.ui.modes.kidsParental)
      else if isKidsProfile() = true 'kids account
        setUiMode(m.constants.ui.modes.kidsProfile)
      else
        setUiMode(m.constants.ui.modes.standard)
      end if
    else if isLoggedInUser(profileAuthInfo) = false 'guest

      if shouldShowAgeGate() = true
        if m.guestUserHasAgeInfo = invalid then
          m.guestUserHasAgeInfo = getGuestUserHasAgeInfo()
        end if

        ' Have to make sure we check expired as well as default state will always have hasAge = false
        if m.guestUserHasAgeInfo.hasAge = false AND m.guestUserHasAgeInfo.expired = false
          setUiMode(m.constants.ui.modes.kidsAgeGate)
        else
          setUiMode(m.constants.ui.modes.standard)
        end if
      else
        setUiMode(m.constants.ui.modes.standard)
      end if
    end if
  end if

End Function


Function onSignInToChangeProfileResponse(response)

  isUsrInMultiAccount = isUserInMultiAccount()
  dateTime = CreateObject("roDateTime")
  nowTime = dateTime.AsSeconds()

  passwordExpireTS = nowTime + m.constants.timers.coppaFailTimeout
  response["pwexpts"] = passwordExpireTS
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

  authInfo = m.tubiAuthUpdate.getAuthInfo()
  onSwitchProfileSuccess(authInfo)

End Function


Function setSideNavForProfileSelected(authInfo)
  m.sideNav.displayKids = (m.kidsModeFeatureOn = true)
End Function


Function showWelcomeProfileToast(authInfo = invalid)
  if isUserInMultiAccount() = true
    if authInfo = invalid
      authInfo = m.tubiAuthUpdate.getAuthInfo()
    end if

    name = authInfo.firstName
    if isNonEmptyString(name) = false
      name = authInfo.name
    end if

    if isNonEmptyString(name) = true
      headerText = getTranslation("new_account_welcome_header", { "name": name })
      profileInitial = Ucase(name.left(1))
      toastInfo = {
        message: ""
        selfDestructTimer: 5
        imageUri: authInfo.avatarUrl
        headerText: headerText
        profileInitial: profileInitial
      }

      showToast(toastInfo)
    end if
  end if

End Function


Function clearGlobalUserData()
  m.NodeHelpers.removeAllChildren(m.global.bookmarkIds)
  m.NodeHelpers.removeAllChildren(m.global.historyIds)
  m.NodeHelpers.removeAllChildren(m.global.likeIds)
End Function


Function onForgotPinSelected(msg)
  isForgotPin = msg.getData()
  if isForgotPin = true
    nNowDate = getNowSeconds()
    nSavedSeconds = 0

    if m.passwordCache <> invalid AND m.passwordCache.currentTime <> invalid then
      nSavedSeconds = m.passwordCache.currentTime
    end if

    if m.passwordCache <> invalid AND m.passwordCache.password <> invalid AND (nNowDate - nSavedSeconds) < 300
      onPasswordConfirmForPinUpdate()
    else
      authInfo = m.tubiAuthUpdate.getAuthInfo()

      if isKidsProfile(authInfo) = true
        parentAuthInfo = m.tubiAuthUpdate.getProfileAuthInfo(authInfo.parentId)
      else
        parentAuthInfo = authInfo
      end if

      showPasswordValidateScreen(authInfo, parentAuthInfo, onPasswordValidateForPinUpdate)
    end if
  end if

End Function


Function onPinUpdateSuccess(msg)
  tubiLog("ProfileHelpers.onPinUpdateSuccess")
  'refresh after patch request because we do not worry about the response here
  showHideSpinner(false)
  headerText = getTranslation("parental_pin_update_success_header")
  message = getTranslation("parental_pin_update_success_message")
  toastInfo = {
    message: message
    selfDestructTimer: 5
    imageUri: "pkg:/images/icon-checkmark.png"
    headerText: headerText
  }

  showToast(toastInfo)

  popScreenAfterSignInProcess()

End Function


Function onPinUpdateError(error)
  tubiLog("ProfileHelpers.onPinUpdateError")
  showHideSpinner(false)
  title = getTranslation("dialog_errorOops_title")
  message = getTranslation("parental_pin_update_error_message")

  buttons = [getTranslation("linearVideoPlayer_buttonBack")]
  currentScreen = getCurrentScreen()

  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: "NETWORK_ERROR" 'DialogType enum
      pageOneof: m.Tracking.getAnalyticsPage(currentScreen.trackingPageInfo.pageType, currentScreen.trackingPageInfo.pageValues)
      dialog_action: "SHOW"
      dialog_sub_type: "pin-update-error"
    }
  }
  showSimpleModal(title, message, buttons, dialogEvent, m.trackingLoggingTask, popScreenAfterSignInProcess)
End Function


' This error could be a request of following use cases "The email domain provided is invalid", "Email already exists", "The email domain provided is not supported at this time"
Function handleInvalidKidSignupError(errorCode)

  message = ""
  if errorCode <> invalid
    if errorCode = m.constants.errors.codes.duplicateKidName
      message = getTranslation("duplicate_kid_name_error_message")
    else if errorCode = m.constants.errors.codes.tooManyKids
      message = getTranslation("too_many_kids_error_message")
    else if errorCode = m.constants.errors.codes.invalidNameChars
      message = getTranslation("invalid_name_chars_error_message")
    end if
  end if

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
      dialog_type: "SIGNUP_ERROR"
      pageOneof: m.Tracking.getAnalyticsPage(currentScreen.trackingPageInfo.pageType, currentScreen.trackingPageInfo.pageValues)
      dialog_action: "SHOW"
      dialog_sub_type: "signup-failed"
    }
  }

  if message = ""
    message = getTranslation("could_not_verify_email") + ". " + getTranslation("dialog_defaultError_description")
  end if

  handlerFun = Function()
    popScreen(false, false)
    showAddProfileScreen()
  End Function

  title = getTranslation("dialog_defaultError_title")
  buttons = [getTranslation("dialog_button_ok")]
  showSimpleInstantResumableModal(title, message, buttons, dialogEvent, m.trackingLoggingTask, handlerFun)
End Function


Function updatePasswordExpiryTimeForProfile(profileAuthInfo)
  if profileAuthInfo <> invalid AND isNonEmptyString(profileAuthInfo.tubiId) = true AND profileAuthInfo.count() > 0
    dateTime = CreateObject("roDateTime")
    nowTime = dateTime.AsSeconds()

    passwordExpireTS = nowTime + m.constants.timers.coppaFailTimeout
    paswdExpTimeStamp = { "pwexpts": passwordExpireTS }

    m.tubiAuthUpdate.createOrUpdateProfileAuth(profileAuthInfo.tubiId, paswdExpTimeStamp)

  end if
End Function


Function shouldShowPWScreenToExitKidsMode(tubiId)
  if isNonEmptyString(tubiId) = true

    profileAuthInfo = m.tubiAuthUpdate.getProfileAuthInfo(tubiId)

    if profileAuthInfo <> invalid
      dateTime = CreateObject("roDateTime")
      nowTime = dateTime.AsSeconds()

      if isString(profileAuthInfo.pwExpTs) = true
        passwordExpireTS = profileAuthInfo.pwExpTs.toInt()
      else if isInteger(profileAuthInfo.pwExpTs) = true
        passwordExpireTS = profileAuthInfo.pwExpTs
      else
        passwordExpireTS = 0
      end if

      if passwordExpireTS > nowTime
        return false
      end if
    end if
  end if
  return true
End Function