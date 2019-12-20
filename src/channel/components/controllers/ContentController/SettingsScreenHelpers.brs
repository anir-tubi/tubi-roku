function showSettingsScreen(sFocusID = "")
  tubiLog("SettingsScreenHelpers.showSettingsScreen")
  m.settingsScreen = CreateObject("roSGNode", "SettingsScreen")
  m.settingsScreen.id = m.constants.ui.screenIds.settingsScreen
  if m.global.authInfo <> invalid
    m.settingsScreen.signedIn = true
    setUserInfo()
  else
    m.settingsScreen.signedIn = false
    m.settingsScreen.parentalSetting = 3  ' Default to most permissive
  end if
  m.settingsScreen.observeFieldScoped("signedIn", "OnSignedIn")
  m.settingsScreen.observeFieldScoped("signOutSelected", "onSettingsSignOutSelected")
  m.settingsScreen.observeFieldScoped("signInSelected", "onSettingsSignInSelected")
  m.settingsScreen.observeFieldScoped("parentalSettingSelected", "onParentalSettingSelected")
  m.settingsScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
  m.settingsScreen.observeFieldScoped("backgroundUriList", "onSettingsBackgroundChange")
  m.settingsScreen.observeFieldScoped("showDeviceModal", "onShowDeviceModal")

  pushScreen(m.settingsScreen, true, true)
  
  if sFocusID <> ""
    '//If a particular settings button should be in focus
    m.settingsScreen.itemRequested = sFocusID
  end if
end function


function OnSignedIn()
  setUserInfo()
end function


function setUserInfo()
  if m.global.authInfo <> invalid
    authInfo = m.global.authInfo
    if authInfo.firstName <> invalid and authInfo.lastName <> invalid
      m.settingsScreen.name = authInfo.firstName + " " + authInfo.lastName
    else
      m.settingsScreen.name = authInfo.name
    end if
    m.settingsScreen.email = authInfo.email
    m.settingsScreen.parentalSettingUpdated = authInfo.parentalrating
  end if
end function


function setAuthInfoValue(attribute, value) as boolean
  bSuccess = false
  if m.global.authInfo <> invalid
    authInfo = m.global.authInfo
    authInfo[attribute] = value
    m.global.authInfo = authInfo
    bSuccess = true
  end if
  return bSuccess
end function


function getNowSeconds() as integer
  nowDate = CreateObject("roDateTime")
  return nowDate.AsSeconds()
end function


function onSettingsSignOutSelected()
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
end function


Function onSettingsBackgroundChange()
  tubiLog("SettingsScreenHelpers.onSettingsBackgroundChange")
  m.backgroundGroup.backgroundInfo = {
    type: getBackgroundtype(m.settingsScreen.backgroundUriList)
    uriList: m.settingsScreen.backgroundUriList
  }
End Function


' Log the user out, update screens
function onSignOutModalSelected()
  tubiLog("SettingsScreenHelpers.onSignOutModalSelected")
  ' flush the screenstack in any case where the user has successfully
  ' gone through the sign-in.  If they 'back' out of it, the screen
  ' stack will stay intact and this function will not be called
  clearScreenStack()

  m.authInfoReceived = false
  if m.authTask <> invalid
    m.authTask.unobserveFieldScoped("onAuthInfoReceived")
  end if
  m.authTask = CreateObject("roSGNode", "AuthTask")
  m.authTask.observeFieldScoped("authInfo", "onAuthInfoReceived")
  m.authTask.functionName = "execSignOut"
  m.authTask.control = "RUN"

  m.spinner.visible = true
  m.spinner.setFocus(true)
end function


function onSettingsSignInSelected()
  tubiLog("SettingsScreenHelpers.onSettingsSignInSelected")
  startSignIn(true)
end function


'//When exiting the ConfirmPasswordScreen, make sure some event handlers are no longer listened to
function onConfirmPasswordScreenVisible(msg)
  tubiLog("SettingsScreenHelper.onConfirmPasswordScreenVisible")
  confirmPasswordScreen = msg.getRoSGNode()
  '//if we don't stop listening to this "result" field, then it may cause an error window to appear if/when
  '//   the request returns a negative response.
  if confirmPasswordScreen <> invalid and confirmPasswordScreen.visible = false and m.parentalSettingUpdateTask <> invalid
    m.parentalSettingUpdateTask.unobserveField("result")
  end if
end function


function onParentalSettingSelected(msg)
  tubiLog("SettingsScreenHelpers.onParentalSettingSelected")
  parentalSetting = msg.GetData()
  if m.settingsScreen.signedIn = true
    if m.global.authInfo <> invalid and parentalSetting <> m.global.authInfo.parentalrating
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
        m.confirmPasswordScreen.message = "Enter your password"
        m.confirmPasswordScreen.subMessage = "to update parental controls"
        m.confirmPasswordScreen.buttonText = "Submit"
        m.confirmPasswordScreen.isLoading = false
        m.confirmPasswordScreen.observeField("visible", "onConfirmPasswordScreenVisible")
        m.confirmPasswordScreen.observeField("submitSelected", "onPasswordConfirm")
        pushScreen(m.confirmPasswordScreen)
      end if
    end if
  else
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

    title = "Please Sign In"
    message = "You must be signed in to adjust parental controls"
    buttons = ["Sign in", "Cancel"]
    showSimpleModal(title, message, buttons, dialogEvent, m.trackingLoggingTask, onSignInModalButtonSelected)
  end if
end function


function isConfirmPasswordScreen() as boolean
  '//Is the current screen the confirmPasswordScreen?
  screen = currentScreen()
  b = (m.confirmPasswordScreen <> invalid and m.confirmPasswordScreen.subType() = screen.subType())
  return b
end function


function onPasswordConfirm(msg = invalid)
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
end function


' After the parental settings have changes then the content of certain screens should be refreshed
Function refreshScreenAfterParentalChanges()
  tubiLog("SettingsScreenHelpers.refreshScreenAfterParentalChanges")
  homeScreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
  if homeScreen <> invalid
    homeScreen.loadAllCategories = true
  end if
  setContentToRefresh(m.constants.ui.screenIds.channelListScreen) 
  setContentToRefresh(m.constants.ui.screenIds.categoryListScreen)

  screen = currentScreen()
  if screen <> invalid
    if screen.id = m.constants.ui.screenIds.searchScreen
      screen.kidsModeEnabled = m.kidsModeEnabled
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
      popScreen() ' remove the ConfirmPasswordScreen

      setAuthInfoValue("passwordText", m.parentalSettingUpdateTask.password)
      setAuthInfoValue("secondsOfSavedPassword", getNowSeconds())
    else
      '//Update menu so it appears updated. This is only needed if the password has been saved locally and was not entered immediately from the password screeen
      m.settingsScreen.parentalSettingUpdated = true
    end if

    if m.settingsScreen.parentalSettingSelected < 2
      enableKidsModeUI(true)
    else
      '//turn off kids mode (if it is on) when switching to teens and greater
      '// Also, disable the manual version of kids mode if the user had previously enabled kids mode manually
      if m.kidsModeFeatureOn = true
        saveKidsModeToMemory(false)
        enableKidsModeUI(false)
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
    parentalDescription = ""
    if type(parentalSetting) = "roInt" and m.constants.ui.parentalControls.descriptions[parentalSetting] <> invalid
      parentalChoice = m.constants.ui.parentalControls.descriptions[parentalSetting]
      parentalDescription += " to "
      parentalDescription += parentalChoice
    end if

    title = "Parental Controls Settings Change"
    message = "Parental controls setting is changed" + parentalDescription + ". Parental controls will be password protected after 5 minutes."
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

      title = "Update Failed"
      message = "Failed to update parental control settings.  Please try re-entering your password."
      buttons = ["OK"]

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
  showInfoModal("Full Device ID", deviceId, dialogEvent, m.trackingLoggingTask)    

End Function