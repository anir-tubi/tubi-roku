Function init()
  tubiLog(" ")
  tubiLog("Init Scenegraph----------------")
  m._ = rodash()
  m.constants = m.global.constants
  Request = TubiRequest()
  Auth = TubiAuth(m.constants, Request)
  m.NodeHelpers = TubiNodeHelpers()
  m.Bookmarks = TubiBookmarks(Request, Auth, m.constants, m.NodeHelpers)
  m.Tracking = TubiTracking(m.constants, Request, Auth)

  'first things first, observe the live tv content field which comes from the main thread
  m.top.observeFieldScoped("onNowContent", "onOnNowContent")
  m.top.observeField("focusedChild", "onComponentFocus")
  m.onNowReceived = false

  ' Set up global services
  m.metadataFetchTask = m.top.findNode("MetadataFetchTask")
  m.global.addField("metadataFetchTask", "node", false)
  m.global.metadataFetchTask = m.metadataFetchTask

  m.trackingLoggingTask = m.top.findNode("TrackingLoggingTask")
  m.global.addField("trackingLoggingTask", "node", false)
  m.global.trackingLoggingTask = m.trackingLoggingTask
  
  m.background = m.top.findNode("ContentBackground")
  m.background.color = m.constants.ui.colors.backgroundColor

  m.rootTabGroup = m.top.findNode("RootTabGroup")
  m.rootTabGroup.observeField("currentViewId", "onRootTabTransitioned")
  m.contentGroup = m.top.findNode("ContentGroup")

  m.backgroundGroup = m.top.findNode("BackgroundGroup")
  m.defaultBackgroundUri = m.constants.ui.uris.defaultBackground

  ' Global state
  m.global.addField("bookmarkIds", "node", false)
  m.global.bookmarkIds = CreateObject("roSGNode", "BookmarkContentNode")
  m.global.addField("historyIds", "node", false)
  m.global.historyIds = CreateObject("roSGNode", "HistoryContentNode")

  ' NOTE: global authInfo is mostly a formality since TubiAuth currently reads values from the registry, so
  '       places that need authInfo don't need to reference m.global.
  m.global.addField("authInfo", "assocarray", false)
  m.global.authInfo = invalid  ' indicates not logged in

  m.authInfoReceived = false
  m.authTask = CreateObject("roSGNode", "AuthTask")
  m.authTask.observeFieldScoped("authInfo", "onAuthInfoReceived")
  m.authTask.functionName = "execInitializeUserData"
  m.authTask.control = "RUN"

  ' history updates during video playback
  m.updateHistoryTask = CreateObject("roSGNode", "AuthTask")
  m.updateHistoryTask.functionName = "updateHistory"

  ' For queue and history management from detail screen
  m.userTask = CreateObject("roSGNode", "AuthTask")

  m.top.observeFieldScoped("deepLinkContent", "onDeepLinkContentReceived")
  m.deepLinkEvaluated = false  'indicates if the contentController has recognized that we entered from a deeplink or not

  m.logOutTask = m.top.findNode("LogOutTask")

  m.enteredFromDeepLink = false 'used to determine back button behavior in screen stack
  m.ScreenStack = m.top.findNode("ContentScreenStack")
  initScreenStack(m.ScreenStack, onScreenStackEmpty)

  m.videoPlayer = m.top.findNode("VideoPlayer")

  m.autohideTimer = m.top.findNode("AutohideTimer")
  m.autohideTimer.observeFieldScoped("fire", "onAutohide")
  m.spinner = m.top.findNode("ContentControllerSpinner")

  m.inactivityTimer = m.top.findNode("InactivityTimer")
  m.inactivityTimer.observeFieldScoped("fire", "onInactivityTimer")
  m.inactivityTimer.control = "start"

  m.appLoadStopwatch = CreateObject("roTimespan")

  ' Set to the category id when content is launched from category screen,
  ' or set to invalid elsewhere
  m.autoplayContext = invalid


  m.lastUserActivity = Uptime(0)  ' arbitrary marker when user last pressed a remote key

  m._ = rodash()

  initVideoTracking()
  m.trackingLoggingTask.trackEvent = {
    trackType: "startApp"
  }
End Function

Function onScreenStackEmpty()
  tubiLog("ContentController.onScreenStackEmpty")
  ' if we went straight to detail screen for a deep link, launch the home screen.
  ' After we have entered the home screen, ignore back button presses
  if m.enteredFromDeepLink
    popScreen()  ' remove the last screen, probably detail screen
    m.enteredFromDeepLink = false
    startOnNow()
  else
    showExitAppModal("onExitAppModalButtonSelected")
    m.trackingLoggingTask.trackEvent = {
      type: "dialog"
      values: {
        dialog_type: "INFORMATION"   'DialogType enum
        pageOneof: m.Tracking.getAnalyticsPage("home_page", {})
      }
    }
  end if
End Function

Function onComponentFocus()
  tubiLog("ContentController.onComponentFocus")
  if m.top.isInFocusChain() and m.top.hasFocus()
    if m.videoPlayer.visible = true
      m.videoPlayer.setFocus(true)
    else if currentScreen() <> invalid
      currentScreen().setFocus(true)
    end if
  end if
End Function


Function inStillWatchingExperimentWindow()
  time = CreateObject("roDateTime")
  seconds = time.AsSeconds()
  experimentStartTime = m.constants.timers.stillWatchingExperimentStart
  experimentEndTime   = m.constants.timers.stillWatchingExperimentEnd
  if seconds > experimentStartTime and seconds < experimentEndTime
    return true
  else
    return false
  end if
End Function

Function shouldStopOnStillWatchingTimeout()
  if m.constants.player.stillWatchingStopOnTimeout = invalid
    return inStillWatchingExperimentWindow()
  else
    return (m.constants.player.stillWatchingStopOnTimeout = true)
  end if
End Function


Function stillWatchingExperimentAnalyticsValue()
  if m.constants.player.stillWatchingStopOnTimeout = invalid
    if inStillWatchingExperimentWindow() = true
      return "still_watching_24"
    end if
  end if
  return "still_watching"
End Function


Function onInactivityTimer()
  now = Uptime(0)
  if (now - m.lastUserActivity > m.constants.timers.stillWatchingTimeout) and m.videoPlayer.visible = true
    if m.inactivityModal = invalid
      ' Don't invoke this during an ad break or while upNext is visible.  Also if it's just been paused leave it.
      if m.videoPlayer.adState <> "adsplaying" and m.videoPlayer.state = "playing" and m.upNextScreen = invalid
        m.videoPlayer.control = "pause"
        m.inactivityModal = showModal("Are you still watching?", "", ["Yes", "No"], "onInactivityButton", false)
        m.inactivityModal.observeField("exitButton", "onInactivityClose")

        'should indicate the still watching dialog was shown
        m.trackingLoggingTask.trackEvent = {
          type: "auto_play"
          values: {
            video_id: m.videoPlayer.content.id.toInt()  'DialogType enum
            auto_play_action: "STILL_WATCHING"
          }
        }
        m.trackingLoggingTask.trackEvent = {
          type: "dialog"
          values: {
            dialog_type: "INFORMATION"   'DialogType enum
            pageOneof: m.Tracking.getAnalyticsPage("video_player_page", {})  'there is no page representation for the video player in protos currently
          }
        }
      end if
    else if (now - m.lastUserActivity - m.constants.timers.stillWatchingTimeout) > m.constants.timers.stillWatchingDismissTimeout
      closeInactivityModal()
      if shouldStopOnStillWatchingTimeout() = true
        returnToDetailScreenFromVideo(m.constants.player.playerResults.closed)
      else
        m.videoPlayer.control = "resume"
      end if

      ' should indicate the still watching dialog timed out without any user interaction
      m.trackingLoggingTask.trackEvent = {
        type: "auto_play"
        values: {
          video_id: m.videoPlayer.content.id.toInt()  'DialogType enum
          auto_play_action: "STILL_WATCHING"
        }
      }
    end if
  end if
End Function


Function onInactivityClose()
  tubiLog("ContentController.onInactivityButton")
  closeInactivityModal()
  m.videoPlayer.control = "resume"
  m.trackingLoggingTask.trackEvent = {
    trackType: "generic"
    value: stillWatchingExperimentAnalyticsValue()
    ' Interpret a "back" button press as a 'yes'
    ctx: "still_watching_yes"
  }
End Function


Function onInactivityButton()
  tubiLog("ContentController.onInactivityButton")
  button = m.inactivityModal.buttonSelected
  closeInactivityModal()
  if button = 0
    m.videoPlayer.control = "resume"
    ctx = "still_watching_yes"
  else
    returnToDetailScreenFromVideo(m.constants.player.playerResults.closed)
    ctx = "still_watching_no"
  end if
  m.trackingLoggingTask.trackEvent = {
    trackType: "generic"
    value: stillWatchingExperimentAnalyticsValue()
    ctx: ctx
  }
End Function


Function closeInactivityModal()
  tubiLog("ContentController.closeInactivityModal")
  closeModal(m.inactivityModal)
  m.inactivityModal = invalid
  ' Just reset it here for now.  Requirements are to dismiss the modal, not
  ' to take any action like stop playback
  m.lastUserActivity = Uptime(0)
  m.inactivityTimer.control = "stop"  ' enforces just showing the inactivity modal once
End Function


''''''''''''''''''''''
' onExitAppModalButtonSelected
'
' handles the response of a user who has been presented an exit app modal
Function onExitAppModalButtonSelected(msg)
  if msg.getData() = 0
    'exit the app
    m.top.exitApp = true  'm is the context of the screen stack's parent controller
  else
    'return to the last screen
    focusedScreen = currentScreen()
    if focusedScreen <> invalid
      focusedScreen.setFocus(true)
    ' if screen stack was empty, this was a modal over top of the sign in controller
    else if m.SignIn <> invalid
      m.SignIn.setFocus(true)
    end if
  end if
End Function


Function onAutohide()
  tubiLog("ContentController.onAutohide")
  fadeTime = 3.0  ' default
  if m.autohideTimer.fadeTime <> invalid then fadeTime = m.autohideTimer.fadeTime
  m.autohideAnimation = fade(m.ScreenStack, "out", fadeTime)

  if m.autohideTimer.focusVideo = invalid or m.autohideTimer.focusVideo = true
    'the user has gone into the onnow player experience
    m.videoPlayer.setFocus(true)
    m.videoPlayer.observeFieldScoped("backButtonPressed", "unAutohide")
    m.videoPlayer.showTransport = true
  else
    currentScreen().setFocus(false)

    'if autohiding the on now overlay after autoplay - we want the player to treat the user as engaged for analytics purposes
    if m.videoPlayer.analyticsMode = "onnow-autoplay"
      m.videoPlayer.analyticsMode = "onnow-engaged"
    end if

    m.top.setFocus(true)  'key presses go to the screen stack
  end if
End Function

Function unAutohide()
  tubiLog("ContentController.unAutohide")
  if m.autohideAnimation <> invalid then m.autohideAnimation.control = "stop"

  m.ScreenStack.visible = true
  m.autohideAnimation = fade(m.ScreenStack, "in", 0.5)
  currentScreen().setFocus(true)
  m.videoPlayer.enableAds = false
  m.videoPlayer.showTransport = false
End Function

Function showUI(key)
  unAutohide()
  if key = "back" then m.homeScreen.showCategoryScreen = true
End Function


'''''''''''''''''''''''''
' startUserExperience
'
' Only once we have a metadata task ready AND the user's login status
' will we launch the UI
Function startUserExperience()
  tubiLog("ContentController.startUserExperience")
  if m.authInfoReceived and m.deepLinkEvaluated then
    if m.constants.ui.onnow.on = false or (m.constants.ui.onnow.on = true and m.onNowReceived)

      ' Since we're ready to start the channel, make sure the loading spinner is hidden
      root = m.top.getScene()
      if root <> invalid
        spinner = root.findNode("LoadingSpinner")
        if spinner <> invalid then
          spinner.visible = false
        end if
      end if
      ' In any of the auth transitions, this spinner might be visible
      m.spinner.visible = false
      if m.top.deepLinkContent <> invalid then
        tubiLog("ContentController detected deep link request")
        ' we were asked to deep link into a content item. Go to it
        ' whether we were logged in or not.
        testLog("Deep link contentId = " + m.top.deepLinkContent.id)
        testLog("Deep link type = " + m.top.deepLinkContent.type)
        m.enteredFromDeepLink = true
        m.rootTabGroup.show = m.contentGroup.id
        showDetailScreen(m.top.deepLinkContent)
      else if m.constants.ui.onnow.on = false or m.top.onNowContent <> invalid
        m.rootTabGroup.show = m.contentGroup.id
        startOnNow()
      end if
    end if
  end if
End Function


'''''''''''''''''''''''
' onOnNowContent
'
Function onOnNowContent()
  tubiLog("ContentController.onOnNowContent")
  m.top.unobserveFieldScoped("onNowContent")
  m.onNowReceived = true
  startUserExperience()
End Function


''''''''''''''''''''''''
' startSignIn
'
' Defer to the sign-in controller for sign in experience
Function startSignIn(skipDisambiguation)
  tubiLog("ContentController.startSignIn")
  m.SignIn = CreateObject("roSGNode", "SignInController")
  m.SignIn.id = "SignInController"  ' needs to be valid for navigation group
  m.SignIn.skipDisambiguationScreen = skipDisambiguation
  m.SignIn.visible = false
  m.SignIn.observeFieldScoped("state", "onSignInComplete")
  m.SignIn.observeFieldScoped("backPressed", "onSignInBackPressed")
  m.rootTabGroup.addView = m.SignIn
  m.rootTabGroup.show = m.SignIn.id

  if currentScreen() <> invalid
    m.SignIn.sourceScreen = currentScreen()
  end if

  m.SignIn.show = true
  m.SignIn.setFocus(true)
End Function


'''''''''''''''''''''''''
' onSignInComplete
'
' The sign-in flow has ended, do what comes next
Function onSignInComplete()
  tubiLog("ContentController.onSignInComplete")

  if m.SignIn.state = "guest" then
    ' If user signed out, always start at home screen
    clearScreenStack(true)
    startOnNow()
  else
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
  end if

  m.rootTabGroup.show = m.contentGroup.id
End Function

' Auth Info refreshed AFTER app is already running
Function onAuthInfoReceived()
  tubiLog("ContentController.onAuthInfoReceived")
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


'''''''''''''''''''''''''
' onSignInBackPressed
'
' The sign-in controller captured a back button press at the top of the screen stack
Function onSignInBackPressed()
  tubiLog("ContentController.onSignInBackPressed")
  ' If we loaded the sign-in experience from the tools menu or Add To Queue button, keep
  ' the context.  We detect this by looking at whether the ContentController's screen stack
  ' is empty or not.
  if currentScreen() <> invalid
    m.rootTabGroup.show = m.contentGroup.id
  else if m.constants.ui.signIn.backExitsSignIn = true
    m.exitModal = showExitAppModal("onExitAppModalButtonSelected")
    m.trackingLoggingTask.trackEvent = {
      type: "dialog"
      values: {
        dialog_type: "INFORMATION"   'DialogType enum
        pageOneof: m.Tracking.getAnalyticsPage("auth_page", {auth_action: "ACTIVATION"})
      }
    }
  end if
End Function


'''''''''''''''''''''''
' onContentSelected
'
' Show the detail screen for the selected content
Function onContentSelected()
  tubiLog("ContentController.onContentSelected")
  content = m.categoryScreen.contentSelected
  m.autoplayContext = m.categoryScreen.currCategoryId

  if content.type = "channel"
    showChannelScreen(content)
  else
    showDetailScreen(content)
  end if
End Function


''''''''''''''''''''
' onHistoryQueueChange
'
' @categoryId: string, the categoryId/containerId of the category we will refresh
Function onHistoryQueueChange(categoryId)
  tubiLog("ContentController.onHistoryQueueChange")
  if m.global.authInfo <> invalid or m.constants.ui.users.guestHistory = true
    if m.authTask <> invalid
      m.authTask.unobserveFieldScoped("authInfo")
    end if
    ' TODO Bryan: only get the history/queue ids of the categoryIds instead of both every time
    m.authTask = CreateObject("roSGNode", "AuthTask")
    m.authTask.observeFieldScoped("authInfo", "onHistoryQueueRefresh")
    m.authTask.functionName = "execInitializeUserData"
    m.authTask.control = "RUN"
    if m.categoryScreen <> invalid then m.categoryScreen.dirtyUserCategories = categoryId
  end if
End Function

Function onHistoryQueueRefresh()
  tubiLog("ContentController.onHistoryQueueRefresh")
  m.authTask.unobserveFieldScoped("authInfo")
  ' These will be empty parent nodes (no children) if user is not authenticated
  m.global.bookmarkIds = m.authTask.bookmarks
  m.global.historyIds = m.authTask.history
  refreshAllDetailScreens()
End Function

Function refreshAllDetailScreens()
  ' Refresh all detail screens so they have proper history that's been loaded or unloaded
  for i=0 to m.ScreenStack_.getChildCount()-1
    screen = m.ScreenStack_.getChild(i)
    if screen.subType() = "DetailScreen"
      populateDetailScreen(screen, screen.content, true)
    end if
  end for
End Function


Function onSearchContentSelected()
  tubiLog("ContentController.onSearchContentSelected")
  m.autoplayContext = invalid
  showDetailScreen(m.searchScreen.contentSelected)
End Function


'''''''''''''''''''
' onCloseModal
'
' Dismiss a modal dialog
Function onCloseModal()
  tubiLog("ContentController.onCloseAbout")
  popScreen(true)
  m.aboutScreen = invalid
End Function


Function startOnNow()
  tubiLog("ContentController.startOnNow")
  m.appLoadStopwatch.mark()
  ' meta-screen, really just to allow screenstack to function.  we interact
  ' with the child groups directly instead of the parent group
  m.homeScreen = CreateObject("roSGNode", "HomeScreen")
  m.homeScreen.observeFieldScoped("backgroundUriList", "homeScreenBackgroundUpdated")
  m.homeScreen.observeFieldScoped("navigateBetweenHomescreens", "onNavigateBetweeenHomescreens")
  m.homeScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
  m.homeScreen.observeFieldScoped("toolsMenuSelected", "onHomeScreenToolsMenuSelected")

  m.onNow = m.homeScreen.findNode("OnNow")
  m.onNow.control = "play"

  m.categoryScreen = m.homeScreen.findNode("CategoryScreen")
  m.categoryScreen.observeFieldScoped("contentSelected", "onContentSelected")
  m.categoryScreen.observeFieldScoped("firstPosterLoaded", "onFirstPosterLoaded")

  m.homeScreen.signedIn = (m.global.authInfo <> invalid)
  m.categoryScreen.loadAllCategories = true

  ' If experiment calls for OnNow, set the content. Don't ever do OnNow
  ' for low-spec devices
  if not m.constants.deviceInfo.limitedUi and getExperimentValue("UserNamespace", "roku_on_now") = 1 and not m.constants.ui.onNow.disableOnNow
    m.constants.ui.onnow.on = true
    m.onNow.content = m.top.onNowContent
    m.onNow.visible = true
    m.categoryScreen.onNowHintVisible = true
    m.categoryScreen.searchSignOutHintVisible = false
  else
    m.onNow.content = invalid
    m.onNow.visible = false
    m.homeScreen.showCategoryScreen = true
    m.categoryScreen.onNowHintVisible = false
    m.categoryScreen.searchSignOutHintVisible = true
  end if
  m.rootTabGroup.show = m.contentGroup.id
  'this is the first screen so no need for navigate_to_page tracking.
  'page_load tracking will happen when content is received.
  pushScreen(m.homeScreen, false, false)
End Function


Function homeScreenBackgroundUpdated()
  tubiLog("ContentController.homeScreenBackgroundUpdated")
  m.backgroundGroup.backgroundInfo = {
    type: getBackgroundtype(m.homeScreen.backgroundUriList)
    uriList: m.homeScreen.backgroundUriList
  }
End Function

Function onHomeScreenToolsMenuSelected()
  tubiLog("ContentController.onHomeScreenToolsMenuSelected")
  showToolsMenu()
End Function

' navigate_to_page and page_load for transitions between the tools page and the category page (and any other pages on Homescreen)
Function onNavigateBetweeenHomescreens()
  screenTrackingNavigate(m.HomeScreen.oldTrackingPageInfo, m.HomeScreen.trackingPageInfo, invalid)
  screenTrackingLoad(m.Homescreen.trackingPageInfo, 0)
End Function


Function onRootTabTransitioned()
  tubiLog("ContentController.onRootTabTransitioned")
  ' We're here if the SignIn controller was navigated away from
  if m.SignIn <> invalid and m.rootTabGroup.currentViewId <> m.SignIn.id
    m.SignIn.unobserveFieldScoped("state")
    m.SignIn.unobserveFieldScoped("backPressed")
    m.rootTabGroup.removeView = m.SignIn.id
    m.SignIn = invalid
  end if
  if m.rootTabGroup.currentViewId = m.contentGroup.id
    if currentScreen() <> invalid then currentScreen().setFocus(true)
  end if
End Function


'''''''''''''''''''''
' onDeepLinkContentReceived
'
' Show the detail screen for the content id that was deeplinked to
Function onDeepLinkContentReceived()
  tubiLog("onDeepLinkContentReceived")
  m.deepLinkEvaluated = true
  m.top.unobserveFieldScoped("deepLinkContent")
  startUserExperience()
End Function


'''''''''''''''''''''
' onGridBackgroundChange
'
'
Function onGridBackgroundChange()
  TubiLog("ContentController.onGridBackgroundChange")
  m.backgroundGroup.backgroundInfo = {
    type: getBackgroundtype(m.categoryScreen.backgroundUriList)
    uriList: m.categoryScreen.backgroundUriList
  }
End Function


'''''''''''''''''''''
' onEpisodeBackgroundChange
'
'
Function onEpisodeBackgroundChange(msg)
  TubiLog("ContentController.onEpisodeBackgroundChange")
  screen = msg.getRoSGNode()
  m.backgroundGroup.backgroundInfo = {
    type: getBackgroundtype(screen.backgroundUriList)
    uriList: screen.backgroundUriList
  }
End Function


Function onSearchBackgroundChange()
  TubiLog("ContentController.onSearchBackgroundChange")
  m.backgroundGroup.backgroundInfo = {
    type: getBackgroundtype(m.searchScreen.backgroundUriList)
    uriList: m.searchScreen.backgroundUriList
  }
End Function

Function onChannelBackgroundChange(msg)
  TubiLog("ContentController.onChannelBackgroundChange")
  channelScreen = msg.getRoSGNode()
  m.backgroundGroup.backgroundInfo = {
    type: getBackgroundtype(channelScreen.backgroundUriList)
    uriList: channelScreen.backgroundUriList
  }
End Function


'''''''''''''''''''''''
' onDetailItemFailed
'
' Handle a detail screen failure to fetch detailed metadata.  This could be due
' to a title becoming unavailable, or a problem with a deep link.
Function onDetailItemFailed()
  tubiLog("ContentController.onDetailItemFailed")
  popScreen(true)

  ' If a deep-link occurred, we skipped category screen creation so create it here
  if currentScreen() = invalid then
    startOnNow()
  end if
End Function


'''''''''''''''''''''''
' onFirstPosterLoaded
'
' Info that the first poster in the first category has bubbled all the way up.
' Fire off a log to a server so we can track how long it took since the app was started, ie. StartOnNow() was called
Function onFirstPosterLoaded()
  loadTime = m.appLoadStopwatch.TotalMilliseconds()

  'send tracking event for initial home page load
  m.global.trackingLoggingTask.trackEvent = {
    type: "page_load"
    values: {
      pageOneof: m.Tracking.getAnalyticsPage("home_page", {})  'a valid page type (see PageLoadEvent in events.protos)
      load_time: loadTime
      status: "UNKNOWN_ACTION_STATUS"  'ActionStatus enum
    }
  }

  tubiLog("ContentController.onFirstPosterLoaded")  'write to console only
  messageInfo = {
    loadtime: loadTime
    model: m.constants.deviceInfo.model
  }
  tubiLog(FormatJSON(messageInfo), "info", "clientInfo", "time-to-load")   'send info to server
End Function


'''''''''''''''''''''''
' getBackgroundtype
'
' Helper function to get the background type depending on if passed in uri list is using the default image
' @backgroundUriList, array of uris
Function getBackgroundtype(backgroundUriList)
  if backgroundUriList[0] = m.defaultBackgroundUri
    backgroundType = m.constants.ui.backgroundTypes.fullScreen
  else
    backgroundType = m.constants.ui.backgroundTypes.topRight
  end if
  return backgroundType
End Function



'''''''''''''''''''''''
' onNavigateWithinPageInfoChange
'
' Callback for when a navigateWithinPageInfo has been updated - sends the navigate_within_page event
Function onNavigateWithinPageInfoChange(msg)
  navigateWithinPageInfo = msg.getData()
  m.trackingLoggingTask.trackEvent = {
    type: "navigate_within_page"
    values: navigateWithinPageInfo
  }
End Function


Function initVideoTracking()
  ' mux in "components_reset" mode, meaning video node instance is long-lived
  if m.constants.thirdParty.mux.enabled = true
    m.muxTask = m.top.createChild("MuxTask")
    m.muxTask.id = "MuxTask"  ' so that video player can find it
    m.muxTask.video = m.videoPlayer.findNode("VideoNode")
    m.muxTask.config = m.constants.thirdParty.mux.config
    m.muxTask.control = "RUN"
  end if

  if m.constants.thirdParty.youbora.enabled = true
    m.videoPlayer.observeFieldScoped("sendYouboraError", "onSendYouboraError")
    m.youboraTask = m.top.createChild("YBPluginRokuVideo")
    m.youboraTask.id = "Youbora"
    m.youboraTask.options = m.constants.thirdParty.youbora.config
    m.youboraTask.videoplayer = m.videoPlayer.findNode("VideoNode")
    m.global.addFields({YouboraLogActive: m.constants.thirdParty.youbora.debug})
    m.youboraTask.control = "RUN"
  end if
End Function

Function onVideoTrackingStart()
  '  Mux events
  if m.constants.thirdParty.mux.enabled = true
    m.muxTask.view = "start"
  end if

  ' Youbora events
  if m.constants.thirdParty.youbora.enabled = true
    youboraConfig = m.constants.thirdParty.youbora.config

    if m.videoPlayer.content <> invalid
      youboraConfig["extraparam.1"] = m.videoPlayer.content.id
    end if

    if m.global.authInfo <> invalid
      youboraConfig.username = m.global.authInfo.userId
    end if

    youboraConfig["device.code"] = m.constants.deviceInfo.deviceId

    m.youboraTask.options = youboraConfig
    m.youboraTask.event = {handler:"play"}
  end if
End Function

Function videoTrackingStop()
  '  Mux events
  if m.constants.thirdParty.mux.enabled = true
    m.muxTask.view = "end"
  end if
  if m.constants.thirdParty.youbora.enabled = true
    m.youboraTask.event = {handler:"stop"}
  end if
End Function


' We observe the VideoNode state change and when the state = "error", the call back chain of events
' eventually sets VideoNode.control = "stop". Due to an idiosyncracy in Roku behavior, this prevents
' the Youbora plugin from observing the error state on the video node, and so, we must manually trigger
' the Youbora plugin with the error info.
Function onSendYouboraError()
  m.youboraTask.event = {
    handler: "error"
    params: {
      "msg": m.videoplayer.videoErrorMsg,
      "errorCode": m.videoplayer.videoErrorCode.ToStr()
    }
  }
End Function