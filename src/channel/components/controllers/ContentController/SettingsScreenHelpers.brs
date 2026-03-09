'@sFocusID : string, the item which will be opened in settings screen
'@screenLevel : integer, this helps for screen hierarchy when pushing the screen in stack
Function showSettingsScreen(sFocusID = "", screenLevel = 0)
  tubiLog("SettingsScreenHelpers.showSettingsScreen")
  m.settingsScreen = CreateObject("roSGNode", "SettingsScreen")
  m.settingsScreen.id = m.constants.ui.screenIds.settingsScreen
  m.settingsScreen.uiMode = m.uiMode
  m.settingsScreen.isUserInMultiAccount = isUserInMultiAccount()
  ' Passing in the saved isVideoPreviewOn.
  m.settingsScreen.isVideoPreviewOn = m.pub_serverPersistentData.isVideoPreviewOn
  m.settingsScreen.isAutoPlayTimerOn = isAutoPlayTimerOn()
  m.settingsScreen.isAllowedToManageConsent = isUserAllowedToManageConsent()
  m.settingsScreen.consentSettings = m.consentSettings

  m.pubSub.subscribe("pub_serverPersistentData.isVideoPreviewOn", m.settingsScreen, "isVideoPreviewOn")
  m.pubSub.subscribe("pub_serverPersistentData.isAutoPlayTimerOn", m.settingsScreen, "isAutoPlayTimerOn")

  ' This observer must be set before setSettingsScreenSignInInfo is called to trigger initial field change
  m.settingsScreen.observeFieldScoped("fetchUserSettings", "onFetchUserSettingsChanged")
  setSettingsScreenSignInInfo()
  m.settingsScreen.actionAfterActivation = ""
  m.settingsScreen.observeFieldScoped("signOutSelected", "onSettingsSignOutSelected")
  m.settingsScreen.observeFieldScoped("signInSelected", "onSettingsSignInSelected")
  m.settingsScreen.observeFieldScoped("parentalSettingSelected", "onParentalSettingSelected")
  m.settingsScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
  m.settingsScreen.observeFieldScoped("componentInteractionInfo", "onComponentInteractionInfoChange")
  m.settingsScreen.observeFieldScoped("backgroundUriList", "onSettingsBackgroundChange")
  m.settingsScreen.observeFieldScoped("showExitModal", "onShowExitModal")
  m.settingsScreen.observeFieldScoped("backButtonPressed", "onSettingsBackPressed")
  m.settingsScreen.observeFieldScoped("autoPreviewSettingSelected", "onAutoPreviewSettingSelected")
  m.settingsScreen.observeFieldScoped("didUserSelectSaveAndRestart", "saveUpdatedConsentPreferences")
  m.settingsScreen.observeFieldScoped("didUserSelectManagePrivacySettingsButton", "onDidUserSelectManagePrivacySettingsButton")
  m.settingsScreen.observeFieldScoped("selectedConsent", "onSelectedConsentChange")
  m.settingsScreen.observeFieldScoped("selectedQrCodeSectionInfo", "onSelectedQrCodeSectionInfoChanged")
  m.settingsScreen.observeFieldScoped("fetchStatsigExperiments", "onFetchStatsigExperimentsRequested")
  m.settingsScreen.observeFieldScoped("experimentGroupSelected", "onExperimentGroupSelected")
  if m.constants.settings.mode = "qa" OR m.constants.settings.mode = "dev" OR m.constants.settings.mode = "staging" 'this is for extra protection not to restart the app
    m.settingsScreen.observeFieldScoped("appRestartRequested", "onAppRestartRequested")
  end if

  m.settingsScreen.observeFieldScoped("autoPlayTimerSettingSelected", "onAutoPlayTimerSettingSelected")
  m.settingsScreen.observeFieldScoped("pinUpdateBtnSelected", "onForgotPinSelected")

  if screenLevel <> 0
    m.settingsScreen.screenLevel = screenLevel
  end if

  pushScreen(m.settingsScreen, true, true)

  if sFocusID <> ""
    '//If a particular settings button should be in focus
    m.settingsScreen.itemRequested = sFocusID
  end if
End Function


Function setSettingsScreenSignInInfo()
  if m.settingsScreen <> invalid
    aaSignIn = {
      signedIn: false
      name: ""
      email: ""
      avatarUrl: ""
      parentalRating: 3
      parentId: ""
    }

    authInfo = m.tubiAuthUpdate.getAuthInfo()
    if isLoggedInUser(authInfo) = true
      tubiId = authInfo.tubiId
      aaSignIn.signedIn = true
      aaSignIn.avatarUrl = authInfo.avatarUrl
      aaSignIn.email = m.pub_serverPersistentData.email
      aaSignIn.parentalRating = m.pub_serverPersistentData.parentalRating
      aaSignIn.hasPin = authInfo.hasPin
      if isNonEmptyString(authInfo.firstName) = true AND isNonEmptyString(authInfo.lastName) = true
        sName = authInfo.firstName + " " + authInfo.lastName
      else
        sName = authInfo.name
      end if

      if authInfo.parentId <> invalid
        aaSignIn.parentId = authInfo.parentId
      end if

      aaSignIn.name = sName

      profiles = m.tubiAuthUpdate.getAllProfilesAuthInfo()
      if profiles.count() > 1
        linkedAccounts = {}

        for each id in profiles
          profile = profiles[id]
          if profile.parentId = tubiId
            linkedKidsAccount = {}
            if isNonEmptyString(profile.avatarUrl) = true
              linkedKidsAccount.avatarUrl = profile.avatarUrl
            else
              linkedKidsAccount.avatarUrl = ""
            end if

            if isNonEmptyString(profile.firstName) = true
              sName = profile.firstName
            else
              sName = profile.name
            end if
            linkedKidsAccount.name = sName

            if isNonEmptyString(profile.parentalRating) = true
              linkedKidsAccount.parentalRating = profile.parentalRating.toInt()
            else
              linkedKidsAccount.parentalRating = profile.parentalRating
            end if
            if isNonEmptyString(profile.tubiId) = true
              linkedAccounts[profile.tubiId] = linkedKidsAccount
            end if

          end if
        end for
        aaSignIn.linkedAccounts = linkedAccounts
      end if
    end if

    aaSignIn.parentalRating = m.pub_serverPersistentData.parentalRating

    m.settingsScreen.signInInfo = aaSignIn
  end if
End Function


Function getNowSeconds() as Integer
  nowDate = CreateObject("roDateTime")
  return nowDate.AsSeconds()
End Function


Function onSettingsSignOutSelected()
  tubiLog("SettingsScreenHelpers.onSettingsSignOutSelected")

  if isUserInMultiAccount() = false
    pageInfo = m.Tracking.getAnalyticsPage("account_page", { account_page_type: "PARENTAL" })

    dialogEvent = {
      type: "dialog"
      values: {
        dialog_type: "INFORMATION" 'DialogType enum - TODO use a "SIGN_OUT" type when it becomes available in protos
        pageOneof: pageInfo 'settings_page doesn't exist in protos
        dialog_action: "SHOW"
        dialog_sub_type: "sign-out-settings"
      }
    }
    showSignOutModal(dialogEvent, m.trackingLoggingTask, onSignOutModalSelected)
  else
    pageInfo = m.Tracking.getAnalyticsPage("account_page", { account_page_type: "ACCOUNT" })

    dialogEvent = {
      type: "dialog"
      values: {
        dialog_type: "SIGN_OUT" 'DialogType enum - TODO use a "SIGN_OUT" type when it becomes available in protos
        pageOneof: pageInfo 'settings_page doesn't exist in protos
        dialog_action: "SHOW"
        dialog_sub_type: "sign-out"
      }
    }
    showSignOutProfileWithKidsModal(dialogEvent, m.trackingLoggingTask, onSignOutProfileSelected)
    'Send ComponentInteractionEvent
    button_component = {
      button_type: "TEXT"
      button_value: "SIGN_OUT"
    }
    componentInteractionInfo = {
      pageOneof: pageInfo
      componentOneof: m.Tracking.getAnalyticsComponent("button_component", button_component)
      user_interaction: "CONFIRM"
    }

    sendcomponentInteractionInfo(componentInteractionInfo)
  end if
End Function


Function onSettingsBackgroundChange()
  tubiLog("SettingsScreenHelpers.onSettingsBackgroundChange")
  m.backgroundGroup.backgroundInfo = {
    type: getBackgroundType(m.settingsScreen.backgroundUriList)
    uriList: m.settingsScreen.backgroundUriList
  }
End Function


' Log the user out
Function onSignOutModalSelected()
  tubiLog("SettingsScreenHelpers.onSignOutModalSelected")
  requestInfo = m.userDeviceApi.createPostLogoutReqInfo()
  m.makeRequest({
    url: requestInfo.url
    options: requestInfo.options
    requestType: m.constants.reqNames.postLogout
    silenceCallbackWarnings: true
  })
  setSettingsScreenSignInInfo()

  ' Setting focus to spinner before calling logout(), which triggers the home screen to refresh and gain focus.
  m.spinner.visible = true
  m.spinner.setFocus(true)

  logout(onSignOutCompleted)

  clearGlobalUserData()
End Function


Function onSignOutProfileSelected()

  requestInfo = m.userDeviceApi.createPostLogoutReqInfo()
  m.makeRequest({
    url: requestInfo.url
    options: requestInfo.options
    requestType: m.constants.reqNames.postLogout
    silenceCallbackWarnings: true
  })
  setSettingsScreenSignInInfo()

  ' Setting focus to spinner before calling logout(), which triggers the home screen to refresh and gain focus.
  m.spinner.visible = true
  m.spinner.setFocus(true)

  signOutCurrentProfile(onLogOutProfileCompleted)

End Function


'this function will handle things when user selects a autoplayvideoPreview choice
Function onAutoPreviewSettingSelected()
  tubiLog("SettingsScreenHelpers.onAutoPreviewSettingSelected")
  userInteraction = ""
  if isLoggedInUser() = true
    if m.settingsScreen.autoPreviewSettingSelected = 0
      choice = true
      userInteraction = "TOGGLE_ON"
    else
      choice = false
      userInteraction = "TOGGLE_OFF"
    end if

    saveServerPersistentData({
      "isVideoPreviewOn": choice
    })

    m.settingsScreen.autoPreviewItemUpdated = m.settingsScreen.autoPreviewSettingSelected

    'Send ComponentInteractionEvent
    leftSideNavComponent = {
      left_nav_section: "ACCOUNT"
    }
    pageInfo = {
      pageType: "account_page"
      pageValues: {
        account_page_type: "VIDEO_PREVIEW"
      }
    }
    componentInteractionInfo = getComponentInteractionInfo(userInteraction, pageInfo, "left_side_nav_component", leftSideNavComponent)
    sendComponentInteractionInfo(componentInteractionInfo)
  else
    title = getTranslation("dialog_signIn_title")
    message = getTranslation("screenSettings_error_signInAutoplayPreview_description")
    buttons = [getTranslation("dialog_button_signIn"), getTranslation("dialog_button_cancel")]

    showSignInRequiredModal(title, message, buttons, m.settingsScreen, "sign-in-videopreview", m.Tracking, m.trackingLoggingTask, onSignInModalSelectedViaAutoplayPreview)
  end if

End Function


Function onAutoPlayTimerSettingSelected(msg)
  tubiLog("SettingsScreenHelpers.onAutoPlayTimerSettingSelected")
  autoPlayTimerSettingSelected = msg.getData()
  userInteraction = ""

  choice = true
  if autoPlayTimerSettingSelected = 0
    choice = true
    userInteraction = "TOGGLE_ON"
  else if autoPlayTimerSettingSelected = 1
    choice = false
    userInteraction = "TOGGLE_OFF"
  end if

  if isLoggedInUser() = true

    if autoPlayTimerSettingSelected = 0 OR autoPlayTimerSettingSelected = 1
      saveAutoPlayNextVideoChoiceToServerPersistentData(choice)
    end if
  else
    title = getTranslation("dialog_signIn_title")
    message = getTranslation("screenSettings_error_signInAutoplayControls_description")
    buttons = [getTranslation("dialog_button_signIn"), getTranslation("dialog_button_cancel")]

    showSignInRequiredModal(title, message, buttons, m.settingsScreen, "sign-in-autoplay", m.Tracking, m.trackingLoggingTask, onSignInModalSelectedViaAutoplayNextVideo)
  end if

  'Send ComponentInteractionEvent
  leftSideNavComponent = {
    left_nav_section: "ACCOUNT"
  }
  pageInfo = {
    pageType: "account_page"
    pageValues: {
      account_page_type: "VIDEO_PREVIEW"
    }
  }
  componentInteractionInfo = getComponentInteractionInfo(userInteraction, pageInfo, "left_side_nav_component", leftSideNavComponent)
  if autoPlayTimerSettingSelected = 0 OR autoPlayTimerSettingSelected = 1
    sendComponentInteractionInfo(componentInteractionInfo)
  end if
End Function


Function updatePin(signInInfo)
  if signInInfo <> invalid
    m.pcPinInputScreen = createObject("roSGNode", "ParentalControlPinInputScreen")
    m.pcPinInputScreen.signInInfo = signInInfo
    m.pcPinInputScreen.mode = "edit_pin"
    m.pcPinInputScreen.observeFieldScoped("pinSubmitted", "onPinCreateOrEditForKidsAccount")
    m.pcPinInputScreen.observeFieldScoped("backgroundUriList", "onScreenBackgroundUpdated")

    if (isNonEmptyString(signInInfo.hasPin) = true AND signInInfo.hasPin = "true") OR (signInInfo.hasPin = true)
      pinAction = "EDIT_PIN"
    else
      pinAction = "CREATE_PIN"
    end if

    trackingPageInfo = {
      pageType: "pin_page"
      pageValues: {
        pin_action: pinAction
      }
    }
    m.pcPinInputScreen.trackingPageInfo = trackingPageInfo

    pushScreen(m.pcPinInputScreen, true, true)
  end if
End Function


Function onPinCreateOrEditForKidsAccount(msg)

  currentAuthInfo = m.tubiAuthUpdate.getAuthInfo()
  isKidsAccount = isKidsProfile(currentAuthInfo)

  if isKidsAccount = true
    authInfo = m.tubiAuthUpdate.getProfileAuthInfo(currentAuthInfo.parentId)
  else
    authInfo = currentAuthInfo
  end if

  if isLoggedInUser(authInfo) = true AND isUserInMultiAccount() = true
    sTubiId = authInfo.tubiId
    signInInfo = m.pcPinInputScreen.signInInfo
    if signInInfo <> invalid AND signInInfo.pinSubmitted <> invalid AND signInInfo.password <> invalid
      ' update the local authInfo for the kids account
      m.tubiAuthUpdate.createOrUpdateProfileAuth(sTubiId, { haspin: true })

      pinSettingsInfo = m.userDeviceApi.updatePinReqInfoForKidsAccount(signInInfo.password, signInInfo.pinSubmitted)

      m.makeRequest({
        url: pinSettingsInfo.url
        requestType: m.constants.reqNames.postPinUpdateForKids
        successCallback: onPinUpdateSuccess
        options: pinSettingsInfo.options
        responseType: "assocarray"
        errorCallback: onPinUpdateError
      })

    end if

  end if
End Function


'@choice: boolean, true for on and false for off.
Function saveAutoPlayNextVideoChoiceToServerPersistentData(choice)
  saveServerPersistentData({
    "isAutoPlayTimerOn": choice
  }, "device")
End Function


Function onParentalSettingSelected()
  tubiLog("SettingsScreenHelpers.onParentalSettingSelected")
  parentalSetting = m.settingsScreen.parentalSettingSelected
  if m.settingsScreen.signInInfo <> invalid AND m.settingsScreen.signInInfo.signedIn = true
    m.settingsScreen.actionAfterActivation = ""

    currentRating = m.pub_serverPersistentData.parentalRating
    isChangePCRating = true

    if isUserInMultiAccount() = true

      if isNonEmptyString(m.settingsScreen.pcChangeRequestId) = true AND m.settingsScreen.signInInfo.linkedAccounts <> invalid
        kid = m.settingsScreen.signInInfo.linkedAccounts[m.settingsScreen.pcChangeRequestId]
        if kid <> invalid
          currentRating = kid.parentalRating
        end if
      end if
      isChangePCRating = (getPCV2Mapping(parentalSetting) <> getPCV2Mapping(currentRating))
    else
      isChangePCRating = (currentRating <> parentalSetting)
    end if

    authInfo = m.tubiAuthUpdate.getAuthInfo()
    if isLoggedInUser(authInfo) = true AND isChangePCRating = true then
      ' parental settings have been updated
      nNowDate = getNowSeconds()
      nSavedSeconds = 0
      if m.passwordCache <> invalid AND m.passwordCache.currentTime <> invalid then
        nSavedSeconds = m.passwordCache.currentTime
      end if

      'If the loggedIn user doesn't setup password
      if m.pub_serverPersistentData.hasPassword <> true
        pageInfo = m.settingsScreen.trackingPageInfo

        dialogEvent = {
          type: "dialog"
          values: {
            dialog_type: "PASSWORD_REQUIRED" 'DialogType enum
            pageOneof: m.Tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
            dialog_action: "SHOW"
            dialog_sub_type: "parental-updated-" + m.settingsScreen.parentalSettingSelected.toStr()
          }
        }

        msg1 = getTranslation("screenSettings_parentalPassword_setup_new_password") + ":" + chr(10)
        msg2 = getTranslation("screenSettings_parentalPassword_visit_webBrowser") + chr(10)

        emailInfo = ""
        if m.settingsScreen.signInInfo.email <> invalid
          emailInfo = m.settingsScreen.signInInfo.email
        end if

        msg3 = getTranslation("screenSettings_parentalPassword_email") + emailInfo + chr(10)
        msg4 = getTranslation("screenSettings_parentalPassword_set_new_Password")

        message = msg1 + msg2 + msg3 + msg4
        buttons = [getTranslation("screenSettings_parentalPassword_know_my_Password"), getTranslation("dialog_button_close")]

        showSimpleModal("Password Required", message, buttons, dialogEvent, m.trackingLoggingTask, showConfirmPasswordScreen, invalid)
      else
        if m.passwordCache <> invalid AND m.passwordCache.password <> invalid AND (nNowDate - nSavedSeconds) < 300
          tubiLog("SettingsScreenHelpers.onParentalSettingSelected(), use saved password")
          '//if there is a saved password, was it submitted within the last 5 minutes (300 seconds), if so, then use that password
          onPasswordConfirm()
        else if isUserInMultiAccount() = true
          if getPCV2Mapping(parentalSetting) < getPCV2Mapping(currentRating)
            onPasswordConfirm()
          else
            showConfirmPasswordScreen()
          end if
        else
          showConfirmPasswordScreen()
        end if
      end if
    end if
  else
    ' user is signed out, show a modal informing the user they need to sign in to use parental controls
    m.settingsScreen.actionAfterActivation = "ParentalControl"
    pageInfo = m.settingsScreen.trackingPageInfo
    dialogEvent = {
      type: "dialog"
      values: {
        dialog_type: "SIGNIN_REQUIRED"
        pageOneof: m.Tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
        dialog_action: "SHOW"
        dialog_sub_type: "sign-in-parental"
      }
    }

    title = getTranslation("dialog_signIn_title")
    message = getTranslation("screenSettings_error_signInParental_description")
    buttons = [getTranslation("dialog_button_signIn"), getTranslation("dialog_button_cancel")]
    showSimpleInstantResumableModal(title, message, buttons, dialogEvent, m.trackingLoggingTask, onSignInModalSelectedViaParentalControl)
  end if
End Function


Function isConfirmPasswordScreen() as Boolean
  '//Is the current screen the confirmPasswordScreen?
  screen = getCurrentScreen()
  b = (m.confirmPasswordScreen <> invalid AND m.confirmPasswordScreen.subType() = screen.subType())
  return b
End Function


Function onPasswordConfirm(msg = invalid)
  tubiLog("SettingsScreenHelper.onPasswordConfirm")
  sPassword = ""
  if msg <> invalid
    confirmPasswordScreen = msg.getRoSGNode()
    sPassword = confirmPasswordScreen.passwordText
    confirmPasswordScreen.isLoading = true
  else if m.passwordCache <> invalid then
    '//if not coming from the password screen, then coming from a saved password within the last few minutes
    sPassword = m.passwordCache.password
  end if

  authInfo = m.tubiAuthUpdate.getAuthInfo()
  if isLoggedInUser(authInfo) = true
    useV2ParentalRating = false
    isUpdateForKidsAccount = false
    sName = ""
    sTubiId = ""

    if isUserInMultiAccount() = true
      useV2ParentalRating = true

      pcChangeRequestId = m.settingsScreen.pcChangeRequestId
      if pcChangeRequestId <> invalid
        signInInfo = m.settingsScreen.signInInfo
        if signInInfo <> invalid AND signInInfo.linkedAccounts <> invalid
          linkedAccounts = signInInfo.linkedAccounts

          for each item in linkedAccounts
            account = linkedAccounts[item]
            if item = pcChangeRequestId
              sName = account.name
              sTubiId = item
              isUpdateForKidsAccount = true
              exit for
            end if
          end for
        end if
      end if
    end if

    if isUpdateForKidsAccount = true
      patchSettingsInfo = m.userDeviceApi.updateParentalRatingReqInfoForKidsAccount(m.settingsScreen.parentalSettingSelected, sPassword, sName, sTubiId)

      m.makeRequest({
        url: patchSettingsInfo.url
        requestType: m.constants.reqNames.patchKidsParentalRating
        options: patchSettingsInfo.options
        successCallback: refreshAuthTokenAfterPCChangeForKidsAccount
        errorCallback: updateParentalSettingsErrorResponse
        responseType: "assocarray"
        password: sPassword
      })

    else
      parentalRatingReq = m.userDeviceApi.updateParentalRatingReqInfo(m.settingsScreen.parentalSettingSelected, sPassword, useV2ParentalRating)
      m.makeRequest({
        url: parentalRatingReq.url
        requestType: m.constants.reqNames.updateParentalRating
        options: parentalRatingReq.options
        successCallback: refreshAuthTokenAfterParentalControlsChange
        errorCallback: updateParentalSettingsErrorResponse
        responseType: "assocarray"
        password: sPassword
      })
    end if

  end if
End Function


Function onPasswordConfirmForPinUpdate(response = invalid)
  sPassword = ""
  if response <> invalid AND response.valid = true AND isConfirmPasswordScreen() = true
    sPassword = m.confirmPasswordScreen.passwordText
    m.confirmPasswordScreen.isLoading = true
    m.passwordCache = {
      password: sPassword
      currentTime: getNowSeconds()
    }
  else if m.passwordCache <> invalid then
    '//if not coming from the password screen, then coming from a saved password within the last few minutes
    sPassword = m.passwordCache.password
  end if

  if isNonEmptyString(sPassword) = true
    signInInfo = {
      password: sPassword
    }
    updatePin(signInInfo)
  else if isConfirmPasswordScreen() = true
    onPasswordValidateError(response)
  end if


End Function


Function refreshUIAfterParentalControlsChange()
  tubiLog("SettingsScreenHelper.refreshUIAfterParentalControlsChange")
  if m.confirmPasswordScreen <> invalid then
    m.confirmPasswordScreen.isLoading = false
  end if

  showHideSpinner(false)
  if isConfirmPasswordScreen() = true
    popScreen(true, true)
  end if


  '//Update menu so it appears updated. This is only needed if the password has been saved locally and was not entered immediately from the password screen
  m.settingsScreen.parentalSettingUpdated = true
  pcSelected = m.settingsScreen.parentalSettingSelected
  if pcSelected < 2 OR pcSelected = 4 OR pcSelected = 5
    setUiMode(m.constants.ui.modes.kidsParental)
  else
    '//turn off kids mode (if it is on) when switching to teens and greater
    '// Also, disable the manual version of kids mode if the user had previously enabled kids mode manually
    if isKidsUIOn() = true
      setUiMode(m.constants.ui.modes.standard)
    end if
  end if

  ' If the parental controls was changed to adults.
  if isUserInAdultsMode() = true AND isKidsUIOn() = false
    getConsent(onConsentRefreshAfterParentalControlsChange)
  else
    refreshScreenAfterParentalChanges()
  end if

  if isUserInMultiAccount() = true
    m.settingsScreen.uiMode = m.uiMode
  end if

  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: "SIGNIN_REQUIRED"
      pageOneof: m.Tracking.getAnalyticsPage(m.settingsScreen.trackingPageInfo.pageType, m.settingsScreen.trackingPageInfo.pageValues)
      dialog_action: "SHOW"
      dialog_sub_type: "parental-updated-" + m.settingsScreen.parentalSettingSelected.toStr()
    }
  }

  parentalSetting = m.settingsScreen.parentalSettingSelected
  sMessageID = ""
  message = ""
  if isUserInMultiAccount() = true
    if type(parentalSetting) = "roInt"
      sMessageID = "screenSettings_error_parentalChanges_description_multi_account_group" + parentalSetting.toStr()
    end if

    if sMessageID = ""
      sMessageID = "screenSettings_error_parentalChanges_description_multi_account_default"
    end if

    title = getTranslation("screenSettings_error_parentalChanges_multi_account")
  else
    if type(parentalSetting) = "roInt"
      sMessageID = "screenSettings_error_parentalChanges_description_group" + parentalSetting.toStr()
    end if
    if sMessageID = ""
      sMessageID = "screenSettings_error_parentalChanges_description_default"
    end if

    title = getTranslation("screenSettings_error_parentalChanges")
  end if

  message = getTranslation(sMessageID)
  showSimpleInstantResumableModal(title, message, [], dialogEvent, m.trackingLoggingTask)

End Function



Function refreshUIAfterPCChangeForKidsAccount()
  tubiLog("SettingsScreenHelper.refreshUIAfterPCChangeForKidsAccount")
  if m.confirmPasswordScreen <> invalid then
    m.confirmPasswordScreen.isLoading = false
  end if

  showHideSpinner(false)
  if isConfirmPasswordScreen() = true
    popScreen(true, true)
  end if

  'update the local signInInfo for the kids account after patch request
  setSettingsScreenSignInInfo()
End Function


' After the parental settings have changed then the content of certain screens should be refreshed
' Also used after kids mode is enabled or disabled
Function refreshScreenAfterParentalChanges()
  tubiLog("SettingsScreenHelpers.refreshScreenAfterParentalChanges")
  ' We are resetting the grid position to top because when we change modes the content of home screen is totally different.
  ' So placing user back to the position which he was when in other modes like placing user down the 10th position when he switches from adult to kids
  ' we should not be placing user at 10th row but start user at the top of the grid.
  resetCategoryGridPosition()
  homeScreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
  if homeScreen <> invalid then
    fetchHomescreen(homeScreen)
  end if

  setContentToRefresh(m.constants.ui.screenIds.tvScreen)
  setContentToRefresh(m.constants.ui.screenIds.movieScreen)
  setContentToRefresh(m.constants.ui.screenIds.espanolScreen)
  setContentToRefresh(m.constants.ui.screenIds.channelListScreen)
  setContentToRefresh(m.constants.ui.screenIds.categoryPanelListScreen)
  setContentToRefresh(m.constants.ui.screenIds.epgScreen)
  setContentToRefresh(m.constants.ui.screenIds.myStuffScreen)

  refreshHomeScreenSideNav()

  screen = getCurrentScreen()
  if screen <> invalid
    if screen.id = m.constants.ui.screenIds.searchScreen
      screen.isKidsModeAvailable = isKidsUIOn()
      screen.signedIn = true
    else if screen.id = m.constants.ui.screenIds.categoryPanelListScreen
      ' Deleting the screen content cache to avoid showing the old content.
      ' Since category filters shown in different parental modes are totally different.
      ' For ex: In kids mode recommended filter is not available.
      ' If we try to retain old filters and try to refresh them it will result in 404s.
      ' Deleting the screen will result in a fresh load of the screen.
      deleteFromScreenCache(screen.id)
    else if screen.id = m.constants.ui.screenIds.settingsScreen
      ' Updating the value after parentalControls had been changed.
      m.settingsScreen.isAllowedToManageConsent = isUserAllowedToManageConsent()
    end if
  end if

  ' Since we are queuing braze in app messages when the application is in parental control mode less than teen
  ' when the user updates parental rating trying to re-process messages.
  ' We are going to process any queued messages.
  processQueuedInAppMessage()
End Function


Function refreshAuthTokenAfterPCChangeForKidsAccount(response)
  if response <> invalid
    if isConfirmPasswordScreen() = true
      m.passwordCache = {
        password: response.requestInput.password
        currentTime: getNowSeconds()
      }
    else
      showHideSpinner(true)
    end if


    'update the local authInfo for the kids account
    sTubiId = response.parsedresponse.tubi_id
    parentalRating = response.parsedresponse.parental_rating_v2
    if parentalRating <> invalid AND isNonEmptyString(sTubiId) = true
      m.tubiAuthUpdate.createOrUpdateProfileAuth(sTubiId, { parentalRating: parentalRating })
    end if
    m.tubiAuthUpdate.initOrUpdateAuthInfo(refreshUIAfterPCChangeForKidsAccount, true)

  end if
End Function






Function refreshAuthTokenAfterParentalControlsChange(response)
  if response <> invalid
    saveLocalServerPersistentData([{ parentalRating: m.settingsScreen.parentalSettingSelected }])
    if isConfirmPasswordScreen() = true
      m.passwordCache = {
        password: response.requestInput.password
        currentTime: getNowSeconds()
      }
    else
      showHideSpinner(true)
    end if
    m.tubiAuthUpdate.initOrUpdateAuthInfo(refreshUIAfterParentalControlsChange, true)

  end if
End Function





Function onConsentRefreshAfterParentalControlsChange()
  ' If user has already provided consent then skipping the show consent screen and updating the settings screen.
  if isUserConsentRequired() = true
    showConsentScreen(refreshScreenAfterConsentAndParentalChange)
  else
    refreshScreenAfterParentalChanges()
  end if
End Function


Function refreshScreenAfterConsentAndParentalChange()
  ' Removing the consent screen from stack and refreshing the settings screen.
  popScreen(true, true)
  refreshScreenAfterParentalChanges()
End Function


Function updateParentalSettingsErrorResponse(_error)
  tubiLog("SettingsScreenHelper.updateParentalSettingsErrorResponse")

  if isConfirmPasswordScreen() = true
    m.confirmPasswordScreen.isLoading = false
    m.passwordCache = invalid

    pageInfo = m.settingsScreen.trackingPageInfo
    dialogEvent = {
      type: "dialog"
      values: {
        dialog_type: "SIGNIN_REQUIRED"
        pageOneof: m.Tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
        dialog_action: "SHOW"
        dialog_sub_type: "parental-controls-failure"
      }
    }

    title = getTranslation("screenSettings_error_parentalFailedChange_title")
    message = getTranslation("screenSettings_error_parentalFailedChange_description")
    buttons = [getTranslation("dialog_button_ok")]

    showSimpleInstantResumableModal(title, message, buttons, dialogEvent, m.trackingLoggingTask)
  else
    if m.passwordCache <> invalid then
      '//if not showing ConfirmPasswordScreen and showing parentalControls panel AND this came from a saved password,
      '//   then display the ConfirmPasswordScreen instead of error message
      m.passwordCache = invalid
      onParentalSettingSelected()
    end if
  end if
End Function


Function onShowExitModal()
  tubiLog("SettingsScreenHelper.onShowExitModal")
  topScreen = getCurrentScreen()
  displayExitModal(topScreen.trackingPageInfo)
End Function


Function onSettingsBackPressed()
  onKeyEvent("back", true)
  onKeyEvent("back", false)
End Function


Function showConfirmPasswordScreen()
  m.confirmPasswordScreen = CreateObject("roSGNode", "ConfirmPasswordScreen")
  m.confirmPasswordScreen.message = getTranslation("screenSettings_parentalPassword_title")
  m.confirmPasswordScreen.setUp = getTranslation("screenSettings_parentalPassword_setup_new_password") + ","
  m.confirmPasswordScreen.visit = getTranslation("screenSettings_parentalPassword_visit_link")
  m.confirmPasswordScreen.isLoading = false
  m.confirmPasswordScreen.observeField("submitSelected", "onPasswordConfirm")
  m.confirmPasswordScreen.observeField("backPressed", "onSettingsBackPressed")
  m.confirmPasswordScreen.observeFieldScoped("backgroundUriList", "onScreenBackgroundUpdated")
  pushScreen(m.confirmPasswordScreen)
End Function


Function onSettingsSignInSelected()
  tubiLog("SettingsScreenHelpers.onSettingsSignInSelected")
  m.settingsScreen.actionAfterActivation = ""
  startSignIn(onSideNavSignInCompleted)
End Function


Function onAppRestartRequested()
  tubilog("SettingsScreenHelpers.onAppRestartRequested")
  if m.constants.settings.mode = "qa" OR m.constants.settings.mode = "dev" OR m.constants.settings.mode = "staging" 'this is for extra protection not to restart the app
    restartApp()
  end if
End Function


Function saveUpdatedConsentPreferences()
  selectedConsents = m.settingsScreen.newConsentPreferences

  ' As per requirement we want to restart the application whenever user updates any consent so that it is taken into consideration immediately.
  setConsent(selectedConsents, restartApp)
End Function


Function onSelectedConsentChange(msg)
  selectedConsent = msg.getData()
  keys = selectedConsent.Keys()
  ' we expect only single key/value pair in selectedConsents. so accessing the 0th item as it has only one item.
  key = keys[0]
  value = selectedConsent[key]
  if value <> "required"
    userInteractionValue = "TOGGLE_ON"
    if value = "opted_out"
      userInteractionValue = "TOGGLE_OFF"
    end if

    ' As a safety check if we have a mapping value for the consent key if not falling back to backend key.
    buttonValue = m.Tracking.getConsentAnalyticValue(key)

    componentValues = {
      button_type: "TOGGLE"
      button_value: buttonValue
    }
    pageValues = {
      account_page_type: "PRIVACY_PREFERENCES"
    }
    pageOneof = m.Tracking.getAnalyticsPage("account_page", pageValues)
    componentOneof = m.Tracking.getAnalyticsComponent("button_component", componentValues)

    componentInteractionEvent = {
      pageOneof: pageOneof
      componentOneof: componentOneof
      user_interaction: userInteractionValue
    }

    sendComponentInteractionInfo(componentInteractionEvent)

    if isOneTrustConsentEnabled() = false
      body = {}
      body[key] = value
      setConsent(body)
      ' Updating the settings screen consent settings.
      m.settingsScreen.consentSettings = m.consentSettings
    end if

  else
    showRequiredPreferenceToast(key)
  end if
End Function


Function onSelectedQrCodeSectionInfoChanged(msg)
  data = msg.getData()
  message = getTranslation("privacy_preferences_qrcode_modal_subheading")
  buttons = [getTranslation("dialog_got_it")]

  ' TODO: Will add the analytics specs once finalized.
  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: ""
      pageOneof: {}
      dialog_action: "SHOW"
      dialog_sub_type: ""
    }
  }

  simpleModalInfo = getSimpleModalInfo(data.heading, message, buttons, dialogEvent, m.trackingLoggingTask)
  showModal(simpleModalInfo.modalInfo, simpleModalInfo.buttonInfo)
End Function


Function onFetchUserSettingsChanged()
  isMultiAccount = isUserInMultiAccount()
  getUserSettingsRequest = m.userDeviceApi.createUserSettingsGeneralTaskReqInfo(onSettingsScreenGetUserSettingsSuccess, onSettingsScreenGetUserSettingsError, isMultiAccount)
  m.makeRequest(getUserSettingsRequest)
End Function


Function onFetchStatsigExperimentsRequested()
  fetchStatsigExperiments()
End Function


Function onSettingsScreenGetUserSettingsSuccess(userSettings)
  m.settingsScreen.userSettings = userSettings
End Function


Function onSettingsScreenGetUserSettingsError(error)
  ' IMPROVEMENT decide how to handle
End Function


Function onDidUserSelectManagePrivacySettingsButton()
  if m.oneTrust <> invalid
    m.oneTrust.callFunc("showPreferenceCenterUI")
    m.oneTrust.eventlistener.unobserveFieldScoped("onHidePreferenceCenter")
    m.oneTrust.eventlistener.observeFieldScoped("onHidePreferenceCenter", "onPreferenceCenterClosed")
    m.oneTrust.eventlistener.observeFieldScoped("OTConsentUpdated", "onPreferencesUpdated")
  else
    ' Showing a default something went wrong error message with information to contact support.
    ' Since this a very rare edge case falling back to default.
    ' TODO: If we notice lot of support emails or comp lib failures we will revisit this.
    dialogEvent = {
      type: "dialog"
      values: {
        dialog_type: "PRIVACY_PREFERENCES" 'DialogType enum
        pageOneof: {}
        dialog_action: "SHOW"
        dialog_sub_type: "onetrust_load_fail"
      }
    }

    currentScreen = getCurrentScreen()
    if currentScreen.trackingPageInfo <> invalid
      dialogEvent.values.pageOneof = m.Tracking.getAnalyticsPage(currentScreen.trackingPageInfo.pageType, currentScreen.trackingPageInfo.pageValues)
    end if

    modalInfo = {
      title: getTranslation("dialog_defaultError_title")
      message: getTranslation("dialog_gdpr_manage_privacy_settings_error_description")
      openTrackEvent: dialogEvent
      trackingTask: m.trackingLoggingTask
    }

    showErrorModal(modalInfo)
  end if
End Function


Function onPreferenceCenterClosed()
  screen = getCurrentScreen()
  screen.setFocus(true)
End Function


Function onPreferencesUpdated()
  showRestartChannelAfterConsentUpdatedDialog()
End Function


Function showRestartChannelAfterConsentUpdatedDialog()
  buttonInfo = [
    {
      text: getTranslation("privacy_center_restart_channel")
      callback: restartApp
      shouldFocusParentBeforeCallback: false
    }
  ]
  currentScreen = getCurrentScreen()
  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: "INFORMATION"
      pageOneof: m.Tracking.getAnalyticsPage(currentScreen.trackingPageInfo.pageType, currentScreen.trackingPageInfo.pageValues)
      dialog_action: "SHOW"
      dialog_sub_type: "restart_on_consent"
    }
  }

  modalInfo = {
    title: getTranslation("save_consent_dialog_heading")
    message: getTranslation("save_consent_dialog_sub_heading")
    backButtonCallback: restartApp
    openTrackEvent: dialogEvent
    trackingTask: m.trackingLoggingTask
  }

  showModal(modalInfo, buttonInfo)
End Function


' Fetch experiments from Statsig Console API using bulk request approach
'
' Makes a batch of two parallel API requests to retrieve experiments:
' 1. All active and setup experiments
' 2. Abandoned/stopped experiments tagged with "ONGOING"
'
' The results are merged and displayed in the FeaturesPanel.
' Used by Testing Aid feature to display available experiments for override.
Function fetchStatsigExperiments() as Void
  batchRequests = []

  ' Request 1: All active and setup experiments
  activeRequest = {
    id: "activeExperiments"
    url: m.constants.urls.statsig.consoleExperiments
    requestType: m.constants.reqNames.fetchStatsigExperimentsActive
    options: {
      params: {
        "targetAppID": m.constants.thirdParty.statsig.targetAppId
        "status": "active,setup"
      }
      headers: {
        "STATSIG-API-KEY": m.constants.thirdParty.statsig.consoleApiKey
      }
    }
    responseType: "assocarray"
  }
  batchRequests.push(activeRequest)

  ' Request 2: Abandoned/stopped experiments with "ONGOING" tag
  pausedRequest = {
    id: "pausedRokuExperiments"
    url: m.constants.urls.statsig.consoleExperiments
    requestType: m.constants.reqNames.fetchStatsigExperimentsPaused
    options: {
      params: {
        "targetAppID": m.constants.thirdParty.statsig.targetAppId
        "status": "abandoned,experiment_stopped"
        "tags": "ONGOING"
      }
      headers: {
        "STATSIG-API-KEY": m.constants.thirdParty.statsig.consoleApiKey
      }
    }
    responseType: "assocarray"
  }
  batchRequests.push(pausedRequest)

  ' Execute batch request
  m.makeBatchRequest({
    requests: batchRequests
    successCallback: onFetchStatsigExperimentsSuccess
    errorCallback: onFetchStatsigExperimentsError
    responseType: "assocarray"
  })
End Function


' Handle successful experiments batch fetch
'
' Merges results from both API calls (active/setup and abandoned/stopped with ONGOING tag)
' into a single experiments list, sorts them alphabetically by name, and updates the SettingsScreen.
'
' @param response Associative array with keys: activeExperiments, pausedRokuExperiments
Function onFetchStatsigExperimentsSuccess(response) as Void
  if m.settingsScreen = invalid OR response = invalid then return

  ' Merge experiments from both sources
  mergedExperiments = []
  if response.activeExperiments <> invalid AND isNonEmptyArray(response.activeExperiments.data) then
    mergedExperiments.append(response.activeExperiments.data)
  end if
  if response.pausedRokuExperiments <> invalid AND isNonEmptyArray(response.pausedRokuExperiments.data) then
    mergedExperiments.append(response.pausedRokuExperiments.data)
  end if

  ' Sort experiments alphabetically by name (case-insensitive)
  mergedExperiments.sortBy("name", "i")

  ' Set merged result on settings screen
  m.settingsScreen.statsigExperiments = { data: mergedExperiments }
End Function


' Handle experiments fetch error
'
' Sets an error state on the SettingsScreen to display an error message
' in the FeaturesPanel when experiments cannot be loaded.
'
' @param error Error object from the failed API request
Function onFetchStatsigExperimentsError(error) as Void
  if m.settingsScreen = invalid then return

  m.settingsScreen.statsigExperiments = { error: true, message: "Failed to fetch experiments" }
End Function


' Handle experiment group/variant selection from FeaturesPanel
'
' Stores the complete selection data (experiment ID and group info) in the
' "experimentOverrides" registry section as JSON. This allows QA and developers
' to override experiment variants for testing purposes. Shows a restart dialog
' since experiment overrides require an app restart to take effect.
'
' @param msg Message object containing selection data with experimentId and group info
Function onExperimentGroupSelected(msg) as Void
  selectionData = msg.getData()

  ' Early return for invalid data
  if selectionData = invalid OR selectionData.experimentId = invalid OR selectionData.group = invalid then return

  ' Extract experiment details
  experimentId = selectionData.experimentId
  groupName = selectionData.group.name

  ' Store override in registry
  storeExperimentOverride(experimentId, selectionData)

  ' Show restart dialog to apply the experiment override
  showRestartAfterExperimentOverrideDialog(experimentId, groupName)
End Function


' Store experiment override in registry
'
' Saves the experiment selection data to the "experimentOverrides" registry section
' as a JSON string for persistence across app restarts.
'
' @param experimentId String The experiment ID to use as the registry key
' @param selectionData Object The complete selection data to store
Function storeExperimentOverride(experimentId as String, selectionData as Object) as Void
  ' Create/access the experimentOverrides registry section
  registrySection = CreateObject("roRegistrySection", "experimentOverrides")

  ' Serialize the entire selectionData object as JSON
  selectionDataJson = FormatJson(selectionData)
  registrySection.write(experimentId, selectionDataJson)
  registrySection.flush()
End Function


' Show restart dialog after experiment override is applied
'
' Displays a modal dialog informing the user that an experiment override
' has been applied and requires an app restart. Only "Restart Now" option
' is provided - no way to cancel or postpone the restart.
'
' @param experimentId String The ID of the experiment that was overridden
' @param groupName String The name of the selected group/variant
Function showRestartAfterExperimentOverrideDialog(experimentId as String, groupName as String) as Void
  if isNonEmptyString(experimentId) = false OR isNonEmptyString(groupName) = false then return

  buttonInfo = [
    {
      text: "Restart Now"
      callback: restartApp
      shouldFocusParentBeforeCallback: false
    }
  ]

  message = Substitute("Experiment override applied: {0} -> {1}{2}{2}Restart the app to apply changes.", experimentId, groupName, chr(10))

  modalInfo = {
    title: "Restart Required"
    message: message
    backButtonCallback: restartApp
  }

  showModal(modalInfo, buttonInfo)
End Function


Function getPCV2Mapping(parentalSetting as Integer) as Integer
  ' pcMap is mapping between the parental controls and how it is interpretted in multi account. This is a mapping from 4 PC values to 6 pc values
  '   "0": 1 ' younger Child
  '   "1": 2'older Child
  '   "2": 4 'teen
  '   "3": 5 'adult
  '   "4": 0 'youngest child
  '   "5": 3 'oldest child
  ' }

  pcMap = [1, 2, 4, 5, 0, 3]

  return pcMap[parentalSetting]

End Function
