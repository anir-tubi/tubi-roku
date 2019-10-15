''''''''''''''''''''''''
' startSignIn
'
' Defer to the sign-in controller for sign in experience
Function startSignIn(skipDisambiguation)
  tubiLog("SignInHelpers.startSignIn")
  activationCodeScreen = CreateObject("roSGNode", "ActivationCodeScreen")
  activationCodeScreen.observeFieldScoped("activationSuccess", "onActivationSuccess")
  activationCodeScreen.observeFieldScoped("skipButtonPressed", "onActivationSkipped")
  pushScreen(activationCodeScreen, true, true)

  displayDefaultBackground()
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


' Auth Info refreshed. Occurs at app start up and occurs when a user signs in or out.
Function onAuthInfoReceived()
  tubiLog("SignInHelpers.onAuthInfoReceived")
  ' AuthInfo may be invalid if authTask failed to log the user in
  m.global.authInfo = m.authTask.authInfo
  ' These will be empty parent nodes (no children) if user is not authenticated
  m.global.bookmarkIds = m.authTask.bookmarks
  m.global.historyIds = m.authTask.history

  registryKidsMode = false
  if m.authTask.kidsMode <> invalid and m.authTask.kidsMode.kidsEnabled <> invalid
    registryKidsMode = m.authTask.kidsMode.kidsEnabled
  end if

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
    if screen <> invalid
      m.backgroundGroup.backgroundInfo = {
        type: getBackgroundtype(screen.backgroundUriList)
        uriList: screen.backgroundUriList
      }
    end if
  end if
  
  setDirtyUserCategories(m.constants.ui.categoryIds.queue)
  setDirtyUserCategories(m.constants.ui.categoryIds.history)
  setContentToRefresh(m.constants.ui.screenIds.channelListScreen)
  setContentToRefresh(m.constants.ui.screenIds.categoryListScreen)
  refreshAllDetailScreens()
  m.spinner.visible = false

  homeScreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
  if currentScreen() = invalid
    ' this happens on app start up or when a user signs out
    if homeScreen <> invalid
      'expect homeScreen to not be invalid only when a user signs out
      homeScreen.loadAllCategories = true
    end if
    startUserExperience(registryKidsMode)
  else if currentScreen() <> invalid and currentScreen().getSubtype() = "DetailScreen"
    ' this happens if a user logs in after attempting to add to queue
    if homeScreen <> invalid
      homeScreen.loadAllCategories = true
    end if
    currentScreen().setFocus(true)
  else
    ' this happens when a user signs in from the side nav or settings page
    if homeScreen <> invalid
      homeScreen.loadAllCategories = true
    end if
    startUserExperience(registryKidsMode)
  end if
End Function


Function onActivationSkipped()
  popScreen(true)
End Function