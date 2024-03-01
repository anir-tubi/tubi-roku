'@sFocusID : string, the item which will be opened in settings screen
'@screenLevel : integer, this helps for screen hierarchy when pushing the screen in stack
'@sPageSource : string, this helps from where settings screen page is called
Function showSettingsScreen(sFocusID = "", screenLevel = 0, sPageSource = "")
  tubiLog("SettingsScreenHelpers.showSettingsScreen")
  m.settingsScreen = CreateObject("roSGNode", "SettingsScreen")
  m.settingsScreen.id = m.constants.ui.screenIds.settingsScreen
  m.settingsScreen.uiMode = m.uiMode
  ' Passing in the saved isVideoPreviewOn.
  m.settingsScreen.isVideoPreviewOn = m.pub_serverPersistentData.isVideoPreviewOn
  m.settingsScreen.isAllowedToManageConsent = isUserAllowedToManageConsent()
  m.settingsScreen.consentSettings = m.consentSettings

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
  m.settingsScreen.observeFieldScoped("showDeviceModal", "onShowDeviceModal")
  m.settingsScreen.observeFieldScoped("showExitModal", "onShowExitModal")
  m.settingsScreen.observeFieldScoped("backButtonPressed", "onSettingsBackPressed")
  m.settingsScreen.observeFieldScoped("autoPreviewSettingSelected", "onAutoPreviewSettingSelected")
  m.settingsScreen.observeFieldScoped("didUserSelectSaveAndRestart", "saveUpdatedConsentPreferences")
  m.settingsScreen.observeFieldScoped("selectedConsent", "onSelectedConsentChange")
  m.settingsScreen.observeFieldScoped("selectedQrCodeSectionInfo", "onSelectedQrCodeSectionInfoChanged")
  m.settingsScreen.observeFieldScoped("shouldRequestDsarQrCode", "requestDsarQrCode")
  if m.constants.settings.mode = "qa" OR  m.constants.settings.mode = "dev" 'this is for extra protection not to restart the app
    m.settingsScreen.observeFieldScoped("appRestartRequested", "onAppRestartRequested")
  end if

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
  aaSignIn = {
    signedIn: false
    name: ""
    email: ""
  }

  authInfo = getFieldFromGlobal("authInfo")

  if isLoggedInUser(authInfo) = true

    if authInfo <> invalid
      aaSignIn.signedIn = true
      aaSignIn.email = authInfo.email
      if isNonEmptyString(authInfo.firstName) = true AND isNonEmptyString(authInfo.lastName) = true
        sName = authInfo.firstName + " " + authInfo.lastName
      else
        sName = authInfo.name
      end if
      aaSignIn.name = sName
    end if

  end if

  m.settingsScreen.signInInfo = aaSignIn
End Function


Function setAuthInfoValue(attribute, value) as boolean
  bSuccess = false
  authInfo = getFieldFromGlobal("authInfo")
  if isLoggedInUser(authInfo) = true
    authInfo[attribute] = value
    m.global.authInfo = authInfo
    bSuccess = true
  end if
  return bSuccess
End Function


Function getNowSeconds() as integer
  nowDate = CreateObject("roDateTime")
  return nowDate.AsSeconds()
End Function


Function onSettingsSignOutSelected()
  tubiLog("SettingsScreenHelpers.onSettingsSignOutSelected")
  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: "INFORMATION" 'DialogType enum - TODO use a "SIGN_OUT" type when it becomes available in protos
      pageOneof: m.Tracking.getAnalyticsPage("account_page", {account_page_type: "PARENTAL"})  'settings_page doesn't exist in protos
      dialog_action: "SHOW"
      dialog_sub_type: "sign-out-settings"
    }
  }
  showSignOutModal(dialogEvent, m.trackingLoggingTask, onSignOutModalSelected)
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
  setSettingsScreenSignInInfo()
  m.authInfoReceived = false
  if m.authTask <> invalid
    m.authTask.unobserveFieldScoped("authInfo")
  end if
  m.authTask = CreateObject("roSGNode", "AuthTask")
  m.authTask.observeFieldScoped("authInfo", "onSignOutCompleted")
  m.authTask.functionName = "execSignOut"
  m.authTask.control = "RUN"

  m.NodeHelpers.removeAllChildren(m.global.bookmarkIds)
  m.NodeHelpers.removeAllChildren(m.global.historyIds)
  m.NodeHelpers.removeAllChildren(m.global.likeIds)
  m.NodeHelpers.removeAllChildren(m.global.linearLikeIds)

  m.spinner.visible = true
  m.spinner.setFocus(true)
End Function


'this function will handle things when user selects a autoplayvideoPreview choice
Function onAutoPreviewSettingSelected()
  tubiLog("SettingsScreenHelpers.onAutoPreviewSettingSelected")
  userInteraction = ""
  if m.settingsScreen.signInInfo <> invalid AND m.settingsScreen.signInInfo.signedIn = true
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
    componentInteractionInfo = {
      pageOneof: m.Tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
      componentOneof: m.Tracking.getAnalyticsComponent("left_side_nav_component", leftSideNavComponent)
      user_interaction: userInteraction
    }
    sendComponentInteractionInfo(componentInteractionInfo)
  else
    pageInfo = m.settingsScreen.trackingPageInfo
    dialogEvent = {
      type: "dialog"
      values: {
        dialog_type: "SIGNIN_REQUIRED"
        pageOneof: m.Tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
        dialog_action: "SHOW"
        dialog_sub_type: "sign-in-videopreview"
      }
    }

    title = getTranslation("dialog_signIn_title")
    message = getTranslation("screenSettings_error_signInAutoplayPreview_description")
    buttons = [getTranslation("dialog_button_signIn"), getTranslation("dialog_button_cancel")]
    showSimpleInstantResumableModal(title, message, buttons, dialogEvent, m.trackingLoggingTask, onSignInModalSelectedViaAutoplayPreview)
  end if

End Function


Function onParentalSettingSelected()
  tubiLog("SettingsScreenHelpers.onParentalSettingSelected")
  parentalSetting = m.settingsScreen.parentalSettingSelected
  if m.settingsScreen.signInInfo <> invalid AND m.settingsScreen.signInInfo.signedIn = true
    m.settingsScreen.actionAfterActivation = ""
    authInfo = getFieldFromGlobal("authInfo")
    if isLoggedInUser(authInfo) AND parentalSetting <> authInfo.parentalrating
      ' parental settings have been updated
      nNowDate = getNowSeconds()
      nSavedSeconds = 0
      if authInfo.secondsOfSavedPassword <> invalid
        nSavedSeconds = authInfo.secondsOfSavedPassword
      end if

      'If the loggedIn user doesn't setup password
      if authInfo.hasPassword <> true
        pageInfo = m.settingsScreen.trackingPageInfo

        dialogEvent =  {
          type: "dialog"
          values: {
          dialog_type: "PASSWORD_REQUIRED"   'DialogType enum
          pageOneof: m.Tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
          dialog_action: "SHOW"
          dialog_sub_type: "parental-updated-" + m.settingsScreen.parentalSettingSelected.toStr()
          }
        }

        msg1 = getTranslation("screenSettings_parentalPassword_setup_new_password") + ":" + chr(10)
        msg2 = getTranslation("screenSettings_parentalPassword_visit_webBrowser") +chr(10)
        msg3 = getTranslation("screenSettings_parentalPassword_email") +  m.settingsScreen.signInInfo.email + chr(10)
        msg4 = getTranslation("screenSettings_parentalPassword_set_new_Password")

        message = msg1 + msg2 + msg3 + msg4
        buttons = [getTranslation("screenSettings_parentalPassword_know_my_Password"), getTranslation("dialog_button_close")]

        showSimpleModal("Password Required", message, buttons, dialogEvent, m.trackingLoggingTask, showConfirmPasswordScreen, invalid)
      else
        if authInfo.passwordText <> invalid AND (nNowDate - nSavedSeconds) < 300
          tubiLog("SettingsScreenHelpers.onParentalSettingSelected(), use saved password")
          '//if there is a saved password, was it submitted within the last 5 minutes (300 seconds), if so, then use that password
          onPasswordConfirm()
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


Function isConfirmPasswordScreen() as boolean
  '//Is the current screen the confirmPasswordScreen?
  screen = getCurrentScreen()
  b = (m.confirmPasswordScreen <> invalid AND m.confirmPasswordScreen.subType() = screen.subType())
  return b
End Function


Function onPasswordConfirm(msg = invalid)
  tubiLog("SettingsScreenHelper.onPasswordConfirm")
  authInfo = getFieldFromGlobal("authInfo")
  sPassword = ""
  if msg <> invalid
    confirmPasswordScreen = msg.getRoSGNode()
    sPassword = confirmPasswordScreen.passwordText
    confirmPasswordScreen.isLoading = true
  else
    '//if not coming from the password screen, then coming from a saved password within the last few minutes
    sPassword = authInfo.passwordText
    if authInfo.secondsOfSavedPassword = invalid or authInfo.secondsOfSavedPassword <= 0
      setAuthInfoValue("secondsOfSavedPassword", getNowSeconds())
    end if
  end if

  if isLoggedInUser(authInfo)
    parentalRatingReq = m.userDeviceApi.updateParentalRatingReqInfo(m.settingsScreen.parentalSettingSelected, sPassword)

    m.makeRequest({
      url: parentalRatingReq.url
      requestType: m.constants.reqNames.updateParentalRating
      options: parentalRatingReq.options
      successCallback: updateParentalSettingsSuccessResponse
      errorCallback: updateParentalSettingsErrorResponse
      responseType: "assocarray"
      password: sPassword
    })
  end if


End Function


' After the parental settings have changed then the content of certain screens should be refreshed
' Also used after kids mode is enabled or disabled
Function refreshScreenAfterParentalChanges()
  tubiLog("SettingsScreenHelpers.refreshScreenAfterParentalChanges")
  homeScreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
  if homeScreen <> invalid
    authInfo = getFieldFromGlobal("authInfo")
    if isLoggedInUser(authInfo) AND authInfo.parentalrating <> invalid
      homeScreen.parentalRating = authInfo.parentalrating
    end if
    fetchHomescreen(homeScreen)
  end if

  setContentToRefresh(m.constants.ui.screenIds.tvScreen)
  setContentToRefresh(m.constants.ui.screenIds.movieScreen)
  setContentToRefresh(m.constants.ui.screenIds.espanolScreen)
  setContentToRefresh(m.constants.ui.screenIds.channelListScreen)
  setContentToRefresh(m.constants.ui.screenIds.categoryListScreen)
  setContentToRefresh(m.constants.ui.screenIds.epgScreen)
  setContentToRefresh(m.constants.ui.screenIds.myStuffScreen)

  refreshAllHomeScreenTopNav()

  refreshHomeScreenSideNav()

  screen = getCurrentScreen()
  if screen <> invalid
    if screen.id = m.constants.ui.screenIds.searchScreen
      screen.kidsModeEnabled = isKidsUIOn()
      screen.signedIn = true
    else if screen.id = m.constants.ui.screenIds.channelListScreen or screen.id = m.constants.ui.screenIds.categoryListScreen
      refreshGridScreen(screen)
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


Function updateParentalSettingsSuccessResponse(response)
  tubiLog("SettingsScreenHelper.updateParentalSettingsSuccessResponse")
  m.confirmPasswordScreen.isLoading = false

  if response <> invalid
    setAuthInfoValue("parentalrating", m.settingsScreen.parentalSettingSelected)
    if isConfirmPasswordScreen() = true
      '//If ConfirmPasswordScreen visible, then pop the Screen and save the password
      popScreen(true, true) ' remove the ConfirmPasswordScreen

      setAuthInfoValue("passwordText", response.requestInput.password)
      setAuthInfoValue("secondsOfSavedPassword", getNowSeconds())
    else
      '//Update menu so it appears updated. This is only needed if the password has been saved locally and was not entered immediately from the password screen
      m.settingsScreen.parentalSettingUpdated = true
    end if

    if m.settingsScreen.parentalSettingSelected < 2
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
    if type(parentalSetting) = "roInt"
      sMessageID = "screenSettings_error_parentalChanges_description_group" + parentalSetting.toStr()
    end if
    if sMessageID = ""
      sMessageID = "screenSettings_error_parentalChanges_description_default"
    end if

    title = getTranslation("screenSettings_error_parentalChanges")
    message = getTranslation(sMessageID)
    showSimpleInstantResumableModal(title, message, [], dialogEvent, m.trackingLoggingTask)
  end if
End Function


Function onConsentRefreshAfterParentalControlsChange()
  ' If user has already provided consent then skipping the show consent screen and updating the settings screen.
  if m.consentSettings <> invalid AND m.consentSettings.consentRequired = true
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
  authInfo = getFieldFromGlobal("authInfo")

  if isConfirmPasswordScreen() = true
    m.confirmPasswordScreen.isLoading = false
    setAuthInfoValue("secondsOfSavedPassword", 0)

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
  else if authInfo <> invalid AND authInfo.secondsOfSavedPassword <> invalid AND authInfo.secondsOfSavedPassword > 0
    '//if not showing ConfirmPasswordScreen and showing parentalControls panel AND this came from a saved password,
    '//   then display the ConfirmPasswordScreen instead of error message
    setAuthInfoValue("secondsOfSavedPassword", 0)
    onParentalSettingSelected()
  end if
End Function


Function onShowDeviceModal()
  tubiLog("AboutScreen.showFullDeviceId")

  deviceId = m.constants.deviceInfo.deviceId
  pageInfo = m.settingsScreen.trackingPageInfo
  dialogEvent = {
    type: "dialog"
    values: {
    dialog_type: "INFORMATION"
    pageOneof: m.Tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
    dialog_action: "SHOW"
    dialog_sub_type: "device-id"
    }
  }
  showInfoModal(getTranslation("screenSettings_fullDeviceID"), deviceId, dialogEvent, m.trackingLoggingTask)

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
  if m.constants.settings.mode = "qa" OR  m.constants.settings.mode = "dev" 'this is for extra protection not to restart the app
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

    componentInteractionEvent =  {
      pageOneof: pageOneof
      componentOneof: componentOneof
      user_interaction: userInteractionValue
    }

    sendComponentInteractionInfo(componentInteractionEvent)

    if isGdpr(m.constants) = false
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
  getUserSettingsRequest = m.userDeviceApi.createUserSettingsGeneralTaskReqInfo(onSettingsScreenGetUserSettingsSuccess, onSettingsScreenGetUserSettingsError)
  m.makeRequest(getUserSettingsRequest)
End Function


Function onSettingsScreenGetUserSettingsSuccess(userSettings)
    m.settingsScreen.userSettings = userSettings
End Function


Function onSettingsScreenGetUserSettingsError(error)
  ' IMPROVEMENT decide how to handle
End Function


Function requestDsarQrCode()
  m.settingsScreen.dsarQrCodeUri = ""
  requestInfo = m.userDeviceApi.createGetDsarQrCodeReqInfo()
  m.makeRequest({
    url: requestInfo.url
    requestType: requestInfo.requestType
    successCallback: onGetDsarQrCodeRequestSuccess
    responseType: "assocarray"
    silenceCallbackWarnings: true
  })
End Function


Function onGetDsarQrCodeRequestSuccess(response)
  if response <> invalid AND response.image_in_base64 <> invalid
    imageData = response.image_in_base64
    uri = "tmp:/dsarQrCode.png"
    ba = CreateObject("roByteArray")
    ba.fromBase64String(imageData)
    ba.writeFile(uri)
    m.settingsScreen.dsarQrCodeUri = uri
  end if
End Function
