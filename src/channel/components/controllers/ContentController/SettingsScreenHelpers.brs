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
  m.settingsScreen.observeField("signOutSelected", "onSettingsSignOutSelected")
  m.settingsScreen.observeField("signInSelected", "onSettingsSignInSelected")
  m.settingsScreen.observeField("parentalSettingSelected", "onParentalSettingSelected")
  m.settingsScreen.observeField("remoteParentalSetting", "onRemoteParentalSetting")
  pushScreen(m.settingsScreen)
End Function

Function onSettingsSignOutSelected()
  tubiLog("SettingsScreenHelpers.onSettingsSignOutSelected")
  showSignOutModal("onSignOutModalSelected")
End Function

Function onSettingsSignInSelected()
  tubiLog("SettingsScreenHelpers.onSettingsSignInSelected")
  startSignIn(true)
End Function


Function onParentalSettingSelected(msg)
  tubiLog("SettingsScreenHelpers.onParentalSettingSelected")
  parentalSetting = msg.GetData()
  if m.settingsScreen.signedIn = true
    m.confirmPasswordScreen = CreateObject("roSGNode", "ConfirmPasswordScreen")
    m.confirmPasswordScreen.message = "Enter your password to" + Chr(10) + "change parental rating"
    m.confirmPasswordScreen.buttonText = "Submit"
    m.confirmPasswordScreen.isLoading = false
    m.confirmPasswordScreen.observeField("submitSelected", "onPasswordConfirm")
    pushScreen(m.confirmPasswordScreen)
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