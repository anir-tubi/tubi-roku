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


' Info that the first poster in the first category has bubbled all the way up.
' Fire off a log to a server so we can track how long it took since the app was started, ie. startChannel() was called
Function onFirstPosterLoaded()
  loadTime = m.appLoadStopwatch.TotalMilliseconds()
  tubiLog("ContentController.onFirstPosterLoaded")  'write to console only
  homeScreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
  if homeScreen <> invalid
    homeScreen.unobserveFieldScoped("firstPosterLoaded")
  end if

  'send tracking event for initial home page load
  m.global.trackingLoggingTask.trackEvent = {
    type: "page_load"
    values: {
      pageOneof: m.Tracking.getAnalyticsPage("home_page", {})  'a valid page type (see PageLoadEvent in events.protos)
      load_time: loadTime
      status: "SUCCESS"  'ActionStatus enum
    }
  }

  messageInfo = {
    loadtime: loadTime
    model: m.constants.deviceInfo.model
  }
  tubiLog(FormatJSON(messageInfo), "info", "clientInfo", "time-to-load")   'send info to server
End Function