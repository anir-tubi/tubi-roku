' Show the homescreen, whether existing in the screen pool already or creating a new one
'
' @constants: assocArray, constants as set in Constants.brs and updated in the hotpatch
' @authInfo: assocArray, normally set by m.global.authInfo
Function showHomeScreen(constants, authInfo)
  tubiLog("HomeScreenHelpers.showHomeScreen")
  homeScreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
  if homeScreen <> invalid
    pushScreen(homeScreen, true, true)
  else
    homeScreen = CreateObject("roSGNode", "HomeScreen")
    homeScreen.observeFieldScoped("backgroundUriList", "homeScreenBackgroundUpdated")
    homeScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")

    homeScreen.observeFieldScoped("contentSelected", "onContentSelected")
    homeScreen.observeFieldScoped("firstPosterLoaded", "onFirstPosterLoaded")

    homeScreen.id = constants.ui.screenIds.homeScreen
    homeScreen.signedIn = (authInfo <> invalid)
    homeScreen.loadAllCategories = true
    
    setInScreenCache(homeScreen)
    'this is the first screen so no need for navigate_to_page tracking.
    'page_load tracking will happen when content is received.
    pushScreen(homeScreen, false, false)
  end if
End Function


' Show the detail screen for the selected content
Function onContentSelected(msg)
  tubiLog("ContentController.onContentSelected")
  content = msg.getData()
  homeScreen = msg.getRoSGNode()
  m.autoplayContext = homeScreen.currCategoryId

  if content.type = "channel"
    showChannelScreen(content, "HOME")
  else
    showDetailScreen(content)
  end if
End Function

