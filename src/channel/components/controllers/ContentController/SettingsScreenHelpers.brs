Function showSettingsScreen()
  tubiLog("SettingsScreenHelpers.showSettingsScreen")
  m.settingsScreen = CreateObject("roSGNode", "SettingsScreen")
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
  m.settingsScreen.observeFieldScoped("remoteParentalSetting", "onRemoteParentalSetting")
  m.settingsScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")

  pushScreen(m.settingsScreen, true, true)
End Function

Function OnSignedIn()
  setUserInfo()
End Function

Function setUserInfo()
  if m.global.authInfo <> invalid
    authInfo = m.global.authInfo
    if authInfo.firstName <> invalid and authInfo.lastName <> invalid
      m.settingsScreen.name = authInfo.firstName + " " + authInfo.lastName
    else
      m.settingsScreen.name = authInfo.name
    end if
    m.settingsScreen.email = authInfo.email
    m.settingsScreen.parentalSetting = authInfo.parentalrating
  end if
End Function

Function setAuthInfoValue(attribute, value) as Boolean
  bSuccess = false
  if m.global.authInfo <> invalid
    authInfo = m.global.authInfo
    authInfo[attribute] = value
    m.global.authInfo = authInfo
    bSuccess = true
  end if
  return bSuccess
End Function

Function getNowSeconds() as Integer
  nowDate = CreateObject("roDateTime")
  return nowDate.AsSeconds()
End Function

Function onSettingsSignOutSelected()
  tubiLog("SettingsScreenHelpers.onSettingsSignOutSelected")
  showSignOutModal("onSignOutModalSelected")
  m.trackingLoggingTask.trackEvent = {
    type: "dialog"
    values: {
      dialog_type: "INFORMATION" 'DialogType enum
      pageOneof: m.Tracking.getAnalyticsPage("account_page", {account_page_type: "PARENTAL"})  'settings_page doesn't exist in protos
    }
  }
End Function


' Log the user out, update screens
Function onSignOutModalSelected(msg)
  tubiLog("ContentController.onSignOutModalSelected")

  'do the sign out stuff if confirmed
  if msg.getData() = 0
    ' flush the screenstack in any case where the user has successfully
    ' gone through the sign-in.  If they 'back' out of it, the screen
    ' stack will stay intact and this function will not be called
    clearScreenStack(false)

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
  end if
End Function


Function onSettingsSignInSelected()
  tubiLog("SettingsScreenHelpers.onSettingsSignInSelected")
  startSignIn(true)
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
  if m.settingsScreen.signedIn = true
    if m.global.authInfo <> invalid and parentalSetting <> m.global.authInfo.parentalrating
      nNowDate = getNowSeconds()
      nSavedSeconds = 0
      if m.global.authInfo.secondsOfSavedPassword <> invalid
        nSavedSeconds = m.global.authInfo.secondsOfSavedPassword
      end if
      if m.global.authInfo.passwordText <> invalid and (nNowDate - nSavedSeconds) < 900 
        tubiLog("SettingsScreenHelpers.onParentalSettingSelected(), use saved password")
        '//if there is a saved password, was it submitted within the last 15 minutes (900 seconds), if so, then use that password
        onPasswordConfirm()
      else
        m.confirmPasswordScreen = CreateObject("roSGNode", "ConfirmPasswordScreen")
        m.confirmPasswordScreen.message = "Enter your password to" + Chr(10) + "change parental rating"
        m.confirmPasswordScreen.buttonText = "Submit"
        m.confirmPasswordScreen.isLoading = false
        m.confirmPasswordScreen.observeField("visible", "onConfirmPasswordScreenVisible")
        m.confirmPasswordScreen.observeField("submitSelected", "onPasswordConfirm")
        pushScreen(m.confirmPasswordScreen)
      end if
    end if
  else
    title = "Please Sign In"
    message = "You must be signed in to adjust parental controls"
    buttons = ["Sign in", "Cancel"]
    showModal(title, message, buttons, "onSignInModalButtonSelected")
  end if
End function

Function isConfirmPasswordScreen() as Boolean
  '//Is the current screen the confirmPasswordScreen?
  screen = currentScreen()
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

' This is triggered once the remote setting has been received
Function onRemoteParentalSetting(msg)
  parentalSetting = msg.GetData()
  if m.global.authInfo <> invalid and parentalSetting <> m.global.authInfo.parentalrating
    ' if remote value doesn't match the local one, refresh the category screen
    if m.categoryScreen <> invalid
      m.categoryScreen.loadAllCategories = true
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
'    m.global.authInfo = m.authTask.authInfo ' This new token contains the parental controls setting
    if m.categoryScreen <> invalid
      m.categoryScreen.loadAllCategories = true
    end if
  else
    if isConfirmPasswordScreen() = true 
      setAuthInfoValue("secondsOfSavedPassword", 0)
      title = "Update Failed"
      message = "Failed to update parental control settings.  Please try re-entering your password."
      buttons = ["OK"]
      showModal(title, message, buttons, "")
    else if m.global.authInfo.secondsOfSavedPassword <> invalid and m.global.authInfo.secondsOfSavedPassword > 0
      '//if not showing ConfirmPasswordScreen and showing parentalControls panel AND this came from a saved password, 
      '//   then display the ConfirmPasswordScreen instead of error message
      msgParentalControls = m.settingsScreen.parentalSettingSelected
      setAuthInfoValue("secondsOfSavedPassword", 0)
      onParentalSettingSelected(msgParentalControls)
    end if
  end if
End Function