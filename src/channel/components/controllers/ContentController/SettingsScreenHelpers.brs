'@sFocusID : string, the item which will be opened in settings screen
'@screenLevel : integer, this helps for screen hierarchy when pushing the screen in stack 
'@sPageSource : string, this helps from where settings screen page is called
Function showSettingsScreen(sFocusID = "", screenLevel = 0, sPageSource = "")
  tubiLog("SettingsScreenHelpers.showSettingsScreen")
  m.settingsScreen = CreateObject("roSGNode", "SettingsScreen")
  m.settingsScreen.id = m.constants.ui.screenIds.settingsScreen
  m.settingsScreen.callingPage = sPageSource
  m.settingsScreen.uiMode = m.uiMode
  setSettingsScreenSignInInfo()
  m.settingsScreen.actionAfterActivation = ""
  m.settingsScreen.observeFieldScoped("signOutSelected", "onSettingsSignOutSelected")
  m.settingsScreen.observeFieldScoped("signInSelected", "onSettingsSignInSelected")
  m.settingsScreen.observeFieldScoped("parentalSettingSelected", "onParentalSettingSelected")
  m.settingsScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
  m.settingsScreen.observeFieldScoped("backgroundUriList", "onSettingsBackgroundChange")
  m.settingsScreen.observeFieldScoped("showDeviceModal", "onShowDeviceModal")
  m.settingsScreen.observeFieldScoped("backButtonPressed", "onSettingsBackPressed")
  
  if screenLevel <> 0
    m.settingsScreen.screenLevel = screenLevel
  end if

  pushScreen(m.settingsScreen, true, true)
  
  if sFocusID <> ""
    '//If a particular settings button should be in focus
    m.settingsScreen.itemRequested = sFocusID
  end if
End Function


Function getRatingStrings(nRatingIndex)
  sRatingsReturn = ""
  countryCode = m.constants.deviceInfo.countryCode
  
  aRatings = m.constants.ui.ratings[countryCode]

  if aRatings = invalid
    aRatings = m.constants.ui.ratings["US"]
  end if

  if aRatings <> invalid and aRatings[nRatingIndex] <> invalid
    sRatingsReturn = aRatings[nRatingIndex]
  end if
  return sRatingsReturn 
End Function


Function setSettingsScreenSignInInfo()
  aaSignIn = {signedIn: false
    name: invalid
    email: invalid
  }

  if m.global.authInfo <> invalid
    authInfo = m.global.authInfo
    aaSignIn.signedIn = true
    aaSignIn.email = authInfo.email
    sName = ""
    if authInfo.firstName <> invalid and authInfo.lastName <> invalid
      sName = authInfo.firstName + " " + authInfo.lastName
    else
      sName = authInfo.name
    end if
    
    aaSignIn.name = sName
  end if

  m.settingsScreen.signInInfo = aaSignIn
End Function


Function setAuthInfoValue(attribute, value) as boolean
  bSuccess = false
  if m.global.authInfo <> invalid
    authInfo = m.global.authInfo
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
    type: getBackgroundtype(m.settingsScreen.backgroundUriList)
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

  m.spinner.visible = true
  m.spinner.setFocus(true)
End Function


Function onSettingsSignInSelected()
  tubiLog("SettingsScreenHelpers.onSettingsSignInSelected")
  m.settingsScreen.actionAfterActivation = ""
  startSignIn()
End Function


'//When exiting the ConfirmPasswordScreen, make sure some event handlers are no longer listened to
Function onConfirmPasswordScreenVisible(msg)
  tubiLog("SettingsScreenHelper.onConfirmPasswordScreenVisible")
  confirmPasswordScreen = msg.getRoSGNode()
  '//if we don't stop listening to this "result" field, then it may cause an error window to appear if/when
  '//   the request returns a negative response.
  if confirmPasswordScreen <> invalid and confirmPasswordScreen.visible = false and m.parentalSettingUpdateTask <> invalid
    m.parentalSettingUpdateTask.unobserveField("result")
  end if
End Function


Function onParentalSettingSelected(msg)
  tubiLog("SettingsScreenHelpers.onParentalSettingSelected")
  parentalSetting = msg.GetData()
  if m.settingsScreen.signInInfo <> invalid and m.settingsScreen.signInInfo.signedIn = true
    m.settingsScreen.actionAfterActivation = ""
    if m.global.authInfo <> invalid and parentalSetting <> m.global.authInfo.parentalrating
      ' parental settings have been updated
      nNowDate = getNowSeconds()
      nSavedSeconds = 0
      if m.global.authInfo.secondsOfSavedPassword <> invalid
        nSavedSeconds = m.global.authInfo.secondsOfSavedPassword
      end if

      if m.global.authInfo.passwordText <> invalid and (nNowDate - nSavedSeconds) < 300
        tubiLog("SettingsScreenHelpers.onParentalSettingSelected(), use saved password")
        '//if there is a saved password, was it submitted within the last 5 minutes (300 seconds), if so, then use that password
        onPasswordConfirm()
      else
        m.confirmPasswordScreen = CreateObject("roSGNode", "ConfirmPasswordScreen")
        m.confirmPasswordScreen.message = getTranslation("screenSettings_parentalPassword_title")
        m.confirmPasswordScreen.subMessage = getTranslation("screenSettings_parentalPassword_subtitle")
        m.confirmPasswordScreen.buttonText = getTranslation("dialog_button_submit")
        m.confirmPasswordScreen.isLoading = false
        m.confirmPasswordScreen.observeField("visible", "onConfirmPasswordScreenVisible")
        m.confirmPasswordScreen.observeField("submitSelected", "onPasswordConfirm")
        pushScreen(m.confirmPasswordScreen)
      end if
    end if
  else
    ' user is signed out, show a modal informing the user they need to sign in to use parental controls
    m.settingsScreen.actionAfterActivation = "ParentalControl"
    pageInfo = m.settingsScreen.trackingPageInfo
    dialogEvent = {
      type: "dialog"
      values: {
        dialog_type: "INFORMATION" 'DialogType enum  TODO: Change this to a PARENTAL_CONTROLS dialogType once it exists in protos
        pageOneof: m.Tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
        dialog_action: "SHOW"
        dialog_sub_type: "sign-in-parental"
      }
    }

    title = getTranslation("dialog_signIn_title")
    message = getTranslation("screenSettings_error_signInParental_description")
    buttons = [getTranslation("dialog_button_signIn"), getTranslation("dialog_button_cancel")]
    showSimpleModal(title, message, buttons, dialogEvent, m.trackingLoggingTask, onSignInModalSelectedViaParentalControl)
  end if
End Function


Function isConfirmPasswordScreen() as boolean
  '//Is the current screen the confirmPasswordScreen?
  screen = getCurrentScreen()
  b = (m.confirmPasswordScreen <> invalid and m.confirmPasswordScreen.subType() = screen.subType())
  return b
End Function


Function onPasswordConfirm(msg = invalid)
  tubiLog("SettingsScreenHelper.onPasswordConfirm")
  if msg <> invalid
    confirmPasswordScreen = msg.getRoSGNode()
    sPassword = confirmPasswordScreen.passwordText
    confirmPasswordScreen.addFields({task: m.parentalSettingUpdateTask})
    confirmPasswordScreen.isLoading = true
  else
    '//if not coming from the password screen, then coming from a saved password within the last few minutes
    sPassword = m.global.authInfo.passwordText
    if m.global.authInfo.secondsOfSavedPassword = invalid or m.global.authInfo.secondsOfSavedPassword <= 0
      setAuthInfoValue("secondsOfSavedPassword", getNowSeconds())
    end if
  end if
  m.parentalSettingUpdateTask = CreateObject("roSGNode", "AuthTask")
  m.parentalSettingUpdateTask.functionName = "updateParentalSetting"
  m.parentalSettingUpdateTask.password = sPassword
  m.parentalSettingUpdateTask.parentalSetting = m.settingsScreen.parentalSettingSelected
  m.parentalSettingUpdateTask.observeField("result", "onParentalSettingComplete")
  m.parentalSettingUpdateTask.control = "RUN"
End Function


' After the parental settings have changes then the content of certain screens should be refreshed
' Also used after kids mode is enabled or disabled
Function refreshScreenAfterParentalChanges()
  tubiLog("SettingsScreenHelpers.refreshScreenAfterParentalChanges")
  homeScreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
  if homeScreen <> invalid
    if m.global.authInfo <> invalid and m.global.authInfo.parentalrating <> invalid
      homeScreen.parentalRating = m.global.authInfo.parentalrating
    end if
    refreshHomescreen(homescreen)
  end if

  setContentToRefresh(m.constants.ui.screenIds.tvScreen) 
  setContentToRefresh(m.constants.ui.screenIds.movieScreen) 
  setContentToRefresh(m.constants.ui.screenIds.espanolScreen) 
  setContentToRefresh(m.constants.ui.screenIds.channelListScreen) 
  setContentToRefresh(m.constants.ui.screenIds.categoryListScreen)

  if isTopNavHomeScreenEnabled() = true
    '//go thru the stack and tell any homescreens to update their topNavs
    refreshAllHomeScreenTopNav()
  end if


  screen = getCurrentScreen()
  if screen <> invalid
    if screen.id = m.constants.ui.screenIds.searchScreen
      screen.kidsModeEnabled = isKidsUIOn()
      screen.signedIn = true
    else if screen.id = m.constants.ui.screenIds.channelListScreen or screen.id = m.constants.ui.screenIds.categoryListScreen
      refreshGridScreen(screen)
    end if
  end if
End Function


Function onParentalSettingComplete(msg)
  tubiLog("SettingsScreenHelper.onParentalSettingComplete")
  task = msg.GetRoSGNode()
  result = msg.GetData()
  m.confirmPasswordScreen.isLoading = false
  if result <> invalid
    setAuthInfoValue("parentalrating", m.settingsScreen.parentalSettingSelected)
    if isConfirmPasswordScreen() = true
      '//If ConfirmPasswordScreen visible, then pop the Screen and save the password
      popScreen(true, true) ' remove the ConfirmPasswordScreen

      setAuthInfoValue("passwordText", m.parentalSettingUpdateTask.password)
      setAuthInfoValue("secondsOfSavedPassword", getNowSeconds())
    else
      '//Update menu so it appears updated. This is only needed if the password has been saved locally and was not entered immediately from the password screeen
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

    refreshScreenAfterParentalChanges()

    dialogEvent = {
      type: "dialog"
      values: {
        dialog_type: "INFORMATION" 'DialogType enum  TODO: change to "PARENTAL_CONTROLS" when it is available in protos
        pageOneof: m.Tracking.getAnalyticsPage(m.settingsScreen.trackingPageInfo.pageType, m.settingsScreen.trackingPageInfo.pageValues)
        dialog_action: "SHOW"
        dialog_sub_type: "parental-updated-" + m.settingsScreen.parentalSettingSelected.toStr()
      }
    }

    parentalSetting = m.settingsScreen.parentalSettingSelected
    sMessageID = ""
    sRatings = ""
    if type(parentalSetting) = "roInt"
      sMessageID = "screenSettings_error_parentalChanges_description_group" + parentalSetting.toStr()
      sRatings = getRatingStrings(parentalSetting)
    end if
    if sMessageID = ""
      sMessageID = "screenSettings_error_parentalChanges_description_default"
    end if

    title = getTranslation("screenSettings_error_parentalChanges")
    message = getTranslation(sMessageID, {ratings: sRatings})
    showSimpleModal(title, message, [], dialogEvent, m.trackingLoggingTask)
  else
    if isConfirmPasswordScreen() = true
      setAuthInfoValue("secondsOfSavedPassword", 0)

      pageInfo = m.settingsScreen.trackingPageInfo
      dialogEvent = {
        type: "dialog"
        values: {
          dialog_type: "INFORMATION" 'DialogType enum  TODO: Change this to a PARENTAL_CONTROLS dialogType once it exists in protos
          pageOneof: m.Tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
          dialog_action: "SHOW"
          dialog_sub_type: "parental-controls-failure"
        }
      }

      title = getTranslation("screenSettings_error_parentalFailedChange_title")
      message = getTranslation("screenSettings_error_parentalFailedChange_description")
      buttons = [getTranslation("dialog_button_ok")]

      showSimpleModal(title, message, buttons, dialogEvent, m.trackingLoggingTask)
    else if m.global.authInfo.secondsOfSavedPassword <> invalid and m.global.authInfo.secondsOfSavedPassword > 0
      '//if not showing ConfirmPasswordScreen and showing parentalControls panel AND this came from a saved password,
      '//   then display the ConfirmPasswordScreen instead of error message
      msgParentalControls = m.settingsScreen.parentalSettingSelected
      setAuthInfoValue("secondsOfSavedPassword", 0)
      onParentalSettingSelected(msgParentalControls)
    end if
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


Function onSettingsBackPressed()
  onKeyEvent("back", true)
  onKeyEvent("back", false)
End Function