''''''''''''''''''''''''
' startSignIn
'
' Defer to the sign-in controller for sign in experience
Function startSignIn(skipDisambiguation)
  tubiLog("SignInHelpers.startSignIn")
  activationCodeScreen = CreateObject("roSGNode", "ActivationCodeScreen")
  activationCodeScreen.observeFieldScoped("activationSuccess", "onActivationSuccess")
  pushScreen(activationCodeScreen, true, true)

  m.backgroundGroup.backgroundInfo = {
    type: getBackgroundtype([m.defaultBackgroundUri])
    uriList: [m.defaultBackgroundUri]
  }
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
  m.authTask.observeFieldScoped("authInfo", "onAuthInfoReceived")
  m.authTask.functionName = "execInitializeUserData"
  m.authTask.control = "RUN"
  m.spinner.visible = true
  m.spinner.setFocus(true)

  'we remove the activation screen after auth info has been received
End Function


' Auth Info refreshed AFTER app is already running
Function onAuthInfoReceived()
  tubiLog("SignInHelpers.onAuthInfoReceived")
  ' AuthInfo may be invalid if authTask failed to log the user in
  m.global.authInfo = m.authTask.authInfo
  ' These will be empty parent nodes (no children) if user is not authenticated
  m.global.bookmarkIds = m.authTask.bookmarks
  m.global.historyIds = m.authTask.history

  m.authInfoReceived = true
  m.authTask.unobserveFieldScoped("authInfo")
  m.authTask = invalid

  ' Here we notify screens that may exist, though we try to keep context
  '
  ' Transitions:
  '   signed in -> guest:
  '   guest -> signed in
  '
  '  Auth listeners:
  '    HomeScreen/CategoryScreen - load categories which are filtered by user auth
  '    SearchScreen - results (may be) filtered by user auth
  '
  '  Bookmark/Queue listeners
  '    HomeScreen/CategoryScreen - user categories will be dirty
  '    DetailScreen - just history/bookmarks
  '    EpisodeScreen - history

  for i=0 to m.ScreenStack.getChildCount()-1
    screen = m.ScreenStack.getChild(i)
    if screen.hasField("signedIn")
      screen.signedIn = (m.global.authInfo <> invalid)
    end if
  end for

  'remove the activation code screen since it is no longer necessary
  if currentScreen() <> invalid and currentScreen().getSubtype() =  "ActivationCodeScreen"
    popScreen(true)

    screen = currentScreen()
    m.backgroundGroup.backgroundInfo = {
      type: getBackgroundtype(screen.backgroundUriList)
      uriList: screen.backgroundUriList
    }
  end if

  '//The m.rootTabGroup.show needs to be set AFTER the user has been set as signed in so the sign in page can properly be set as sign out
  m.rootTabGroup.show = m.contentGroup.id

  if m.categoryScreen <> invalid
    m.categoryScreen.dirtyUserCategories = m.constants.ui.categoryIds.queue
    m.categoryScreen.dirtyUserCategories = m.constants.ui.categoryIds.history
  end if
  refreshAllDetailScreens()
  m.spinner.visible = false
  if currentScreen() = invalid
    startUserExperience()
  else
    currentScreen().setFocus(true)
  end if
End Function
