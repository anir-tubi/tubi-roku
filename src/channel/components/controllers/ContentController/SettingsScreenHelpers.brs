Function showSettingsScreen()
  tubiLog("SettingsScreenHelpers.showSettingsScreen")
  m.settingsScreen = CreateObject("roSGNode", "SettingsScreen")
  if m.global.authInfo <> invalid
    authInfo = m.global.authInfo
    m.settingsScreen.signedIn = true
    if authInfo.firstName <> invalid and authInfo.lastName <> invalid
      m.settingsScreen.name = authInfo.firstName + " " + authInfo.lastName
    else
      m.settingsScreen.name = authInfo.name
    end if
    m.settingsScreen.email = authInfo.email
    m.settingsScreen.parentalSetting = authInfo.parentalrating
  else
    m.settingsScreen.signedIn = false
    m.settingsScreen.parentalSetting = 3  ' Default to most permissive
  end if
  m.settingsScreen.observeFieldScoped("signOutSelected", "onSettingsSignOutSelected")
  m.settingsScreen.observeFieldScoped("signInSelected", "onSettingsSignInSelected")
  m.settingsScreen.observeFieldScoped("parentalSettingSelected", "onParentalSettingSelected")
  m.settingsScreen.observeFieldScoped("remoteParentalSetting", "onRemoteParentalSetting")
  m.settingsScreen.observeFieldScoped("remoteParentalSetting", "onRemoteParentalSetting")
  m.settingsScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")

  m.settingsScreen.trackingPageInfo = {
    pageType: "settings_page"   ' placeholder, does not currently exist in protos
    pageValues: {}
  }
  pushScreen(m.settingsScreen, true, true)
End Function


Function onSettingsSignOutSelected()
  tubiLog("SettingsScreenHelpers.onSettingsSignOutSelected")
  showSignOutModal("onSignOutModalSelected")
  m.trackingLoggingTask.trackEvent = {
    type: "dialog"
    values: {
      dialog_type: "INFORMATION" 'DialogType enum
      pageOneof: m.Tracking.getAnalyticsPage("settings_page", {})  'settings_page doesn't exist in protos
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


Function onParentalSettingSelected(msg)
  tubiLog("SettingsScreenHelpers.onParentalSettingSelected")
  parentalSetting = msg.GetData()
  if m.settingsScreen.signedIn = true
    if m.global.authInfo <> invalid and parentalSetting <> m.global.authInfo.parentalrating
      m.confirmPasswordScreen = CreateObject("roSGNode", "ConfirmPasswordScreen")
      m.confirmPasswordScreen.message = "Enter your password to" + Chr(10) + "change parental rating"
      m.confirmPasswordScreen.buttonText = "Submit"
      m.confirmPasswordScreen.isLoading = false
      m.confirmPasswordScreen.observeField("submitSelected", "onPasswordConfirm")
      pushScreen(m.confirmPasswordScreen)
    end if
  else
    title = "Please Sign In"
    message = "You must be signed in to adjust parental controls"
    buttons = ["Sign in", "Cancel"]
    showModal(title, message, buttons, "onSignInModalButtonSelected")
  end if
End Function

Function onPasswordConfirm(msg)
  tubiLog("SettingsScreenHelper.onPasswordConfirm")
  confirmPasswordScreen = msg.getRoSGNode()
  parentalSettingUpdateTask = CreateObject("roSGNode", "AuthTask")
  parentalSettingUpdateTask.functionName = "updateParentalSetting"
  parentalSettingUpdateTask.password = confirmPasswordScreen.passwordText
  parentalSettingUpdateTask.parentalSetting = m.settingsScreen.parentalSettingSelected
  parentalSettingUpdateTask.observeField("result", "onParentalSettingComplete")
  parentalSettingUpdateTask.control = "RUN"
  m.confirmPasswordScreen.addFields({task: parentalSettingUpdateTask})
  confirmPasswordScreen.isLoading = true
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
    m.settingsScreen.parentalSetting = m.settingsScreen.parentalSettingSelected
    popScreen() ' remove the ConfirmPasswordScreen
'    m.global.authInfo = m.authTask.authInfo ' This new token contains the parental controls setting
    if m.categoryScreen <> invalid
      m.categoryScreen.loadAllCategories = true
    end if
  else
    title = "Update Failed"
    message = "Failed to update parental control settings.  Please try re-entering your password."
    buttons = ["OK"]
    showModal(title, message, buttons, "")
  end if
End Function