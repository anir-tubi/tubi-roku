Function showToolsMenu()
  m.toolsMenu = CreateObject("roSGNode", "ToolsMenu")
  m.toolsMenu.observeFieldScoped("searchSelected", "onSearchSelected")
  m.toolsMenu.observeFieldScoped("signInSelected", "onSignInSelected")
  m.toolsMenu.observeFieldScoped("settingsSelected", "onSettingsSelected")
  m.toolsMenu.observeFieldScoped("exitSelected", "onExitSelected")
  m.toolsMenu.observeFieldScoped("backgroundUriList", "onToolsBackgroundChange")
  m.toolsMenu.observeFieldScoped("backButtonPressed", "onToolsBackButton")
  m.toolsMenu.signedIn = (m.global.authInfo <> invalid)
  pushScreen(m.toolsMenu, false)  ' Don't send page navagation since tools are
                                  ' categorized as "navigate_in_page"
End Function

''''''''''''''''''''
' onSearchSelected
'
' Show the search screen
Function onSearchSelected()
  tubiLog("ContentController.onSearchSelected")
  m.searchScreen = CreateObject("roSGNode", "SearchScreen")
  m.searchScreen.observeFieldScoped("contentSelected", "onSearchContentSelected")
  m.searchScreen.observeFieldScoped("backgroundUriList", "onSearchBackgroundChange")
  pushScreen(m.searchScreen, true)
End Function


''''''''''''''''''''
' onSignInSelected
'
' Launch the sign in experience
Function onSignInSelected()
  tubiLog("ContentController.onSignInSelected")
  startSignIn(true)
End Function

Function onSettingsSelected()
  tubiLog("ContentController.onSettingsSelected")
  showSettingsScreen()
End Function

Function onExitSelected()
  tubiLog("ContentController.onExitSelected")
  m.trackingLoggingTask.trackEvent = {
    trackType: "generic"
    value: "exit_button"
  }
  showExitAppModal("onExitAppModalButtonSelected")
End Function


Function onToolsBackgroundChange()
  tubiLog("ToolsMenuHelper.onToolsBackgroundChange")
  m.backgroundGroup.backgroundInfo = {
    type: getBackgroundtype(m.toolsMenu.backgroundUriList)
    uriList: m.toolsMenu.backgroundUriList
  }
End Function

Function onToolsBackButton()
  tubiLog("ToolsMenuHelper.onToolsBackButton")
  popScreen(false)
End Function
