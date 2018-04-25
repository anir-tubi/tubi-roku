Function init()
  tubiLog(" ")
  tubiLog("Init Scenegraph----------------")
  'first things first, observe the live tv content field which comes from the main thread
  m.top.observeFieldScoped("onNowContent", "onOnNowContent")
  m.top.observeField("focusedChild", "onComponentFocus")
  m.onNowReceived = false

  m.constants = m.global.constants
  m.metadataTranslate = TubiMetadataTranslate(m.constants)


  ' save a global reference to the fetch task for nodes to access
  m.metadataFetchTask = m.top.findNode("MetadataFetchTask")
  m.global.addField("metadataFetchTask", "node", false)
  m.global.metadataFetchTask = m.metadataFetchTask

  m.trackingLoggingTask = m.top.findNode("TrackingLoggingTask")
  m.global.addField("trackingLoggingTask", "node", false)
  m.global.trackingLoggingTask = m.trackingLoggingTask
  m.trackingLoggingTask.observeFieldScoped("ready", "onTrackingLoggingReady")
  m.global.trackingLoggingTask.control = "RUN"
  
  m.background = m.top.findNode("ContentBackground")
  m.background.color = m.constants.ui.colors.backgroundColor

  m.backgroundGroup = m.top.findNode("BackgroundGroup")
  m.defaultBackgroundUri = m.constants.ui.uris.defaultBackground

  ' Global state
  m.global.addField("bookmarkIds", "node", false)
  m.global.bookmarkIds = CreateObject("roSGNode", "BookmarkContentNode")
  m.global.addField("historyIds", "node", false)
  m.global.historyIds = CreateObject("roSGNode", "HistoryContentNode")
  m.global.observeField("bookmarkIds", "onBookmarkIdsUpdate")
  m.global.observeField("historyIds", "onHistoryIdsUpdate")

  ' NOTE: global authInfo is mostly a formality since TubiAuth currently reads values from the registry, so
  '       places that need authInfo don't need to reference m.global.
  m.global.addField("authInfo", "assocarray", false)
  m.global.authInfo = invalid  ' indicates not logged in

  m.metadataFetchTask.observeFieldScoped("ready", "onMetadataTaskReady")
  m.global.metadataFetchTask.control = "RUN"

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

  ' Array of detail screen content for it to behave as a virtual stack.
  ' Each entry is:
  ' {
  '   content: <content which populates the detail screen fields>
  '   series2dIndex: <season:episode pair as a 2d integer array, only applicable for series content>
  '   sourceTrackingUri: <tracking URI for each screen>
  ' }
  '
  ' screen2dIndex may be set by:
  '   (a) history currentEpisodeId if user is signed in and series is in history
  '   (b) selection chosen from episode screen
  '   (c) autoplay advancement
  '   (d) default [0,0] when no history or not signed in
  m.detailScreenContent = []

  ' Set to the category id when content is launched from category screen,
  ' or set to invalid elsewhere
  m.autoplayContext = invalid


  m.lastUserActivity = Uptime(0)  ' arbitrary marker when user last pressed a remote key

  ' These values will be set from experiments in the trackingLoggingReady callback
  ' since the trackingLoggingTask is not yet ready and is needed to send exposure events
  ' We only show the sign in prompt message once per session for signed-out users
  m.promptSignInOnGuestPlay = false
  m.skipSignInOnLaunch = false
  m.singleFeaturePoster = false

  m._ = rodash()
End Function

Function onScreenStackEmpty()
  ' if we went straight to detail screen for a deep link, launch the home screen.
  ' After we have entered the home screen, ignore back button presses
  if m.enteredFromDeepLink
    popScreen()  ' remove the last screen, probably detail screen
    m.enteredFromDeepLink = false
    startOnNow()
  else
    showExitAppModal("onExitAppModalButtonSelected")
  end if
End Function

Function onComponentFocus()
  if m.top.isInFocusChain() and m.top.hasFocus()
    if m.videoPlayer.visible = true
      m.videoPlayer.setFocus(true)
    else if currentScreen() <> invalid
      currentScreen().setFocus(true)
    end if
  end if
End Function

Function onInactivityTimer()
  tubiLog("ContentController.onInactivityTimer")
  now = Uptime(0)
  if (now - m.lastUserActivity > m.constants.timers.stillWatchingTimeout) and m.videoPlayer.visible = true
    if m.inactivityModal = invalid
      ' Don't invoke this during an ad break or while upNext is visible.  Also if it's just been paused leave it.
      if m.videoPlayer.adState <> "adsplaying" and m.videoPlayer.state = "playing" and m.upNextScreen = invalid
        m.videoPlayer.control = "pause"
        m.inactivityModal = showModal("Are you still watching?", "", ["Yes", "No"], "onInactivityButton", false)
        m.inactivityModal.observeField("exitButton", "onInactivityClose")

        m.trackingLoggingTask.trackEvent = {
          trackType: "generic"
          value: "still_watching"
          ctx: "still_watching_shown"
        }
      end if
    else if (now - m.lastUserActivity - m.constants.timers.stillWatchingTimeout) > m.constants.timers.stillWatchingDismissTimeout
      closeInactivityModal()
      m.videoPlayer.control = "resume"
      m.trackingLoggingTask.trackEvent = {
        trackType: "generic"
        value: "still_watching"
        ctx: "still_watching_timeout"
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
    value: "still_watching"
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
    value: "still_watching"
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
' onTrackingLoggingReady
'
' Only once we have a metadata task ready AND the user's login status
' will we launch the UI
Function onTrackingLoggingReady()
  tubiLog("ContentController.onTrackingLoggingReady")
  if m.trackingLoggingTask.ready = true
    m.trackingLoggingTask.unobserveFieldScoped("ready")
    
    m.trackingLoggingTask.trackEvent = {
      trackType: "startApp"
    }

    if m.constants.ui.signIn.promptSignInOnGuestPlay <> invalid
      m.promptSignInOnGuestPlay = m.constants.ui.signIn.promptSignInOnGuestPlay
    else
      value = getExperimentValue("UserNamespace", "roku_sign_in")
      if value = 2 or value = 3
        m.promptSignInOnGuestPlay = true
      end if
    end if

    if m.constants.ui.signIn.skipSignInOnLaunch <> invalid
      m.skipSignInOnLaunch = m.constants.ui.signIn.skipSignInOnLaunch
    else
      value = getExperimentValue("UserNamespace", "roku_sign_in")
      if value = 0 or value = 2
        m.skipSignInOnLaunch = true
      end if
    end if

    startUserExperience()
  end if
End Function


'''''''''''''''''''''''''
' startUserExperience
'
' Only once we have a metadata task ready AND the user's login status
' will we launch the UI
Function startUserExperience()
  tubiLog("ContentController.startUserExperience")
  if m.metadataFetchTask.ready and m.authInfoReceived and m.trackingLoggingTask.ready and m.deepLinkEvaluated then
    if m.constants.ui.onnow.on = false or (m.constants.ui.onnow.on = true and m.onNowReceived)

      ' Since we're ready to start the channel, make sure the loading spinner is hidden
      root = rootNode()
      if root <> invalid
        spinner = root.findNode("LoadingSpinner")
        if spinner <> invalid then
          spinner.visible = false
        end if
      end if

      if m.top.deepLinkContent <> invalid then
        tubiLog("ContentController detected deep link request")
        ' we were asked to deep link into a content item. Go to it
        ' whether we were logged in or not.
        testLog("Deep link contentId = " + m.top.deepLinkContent.id)
        testLog("Deep link type = " + m.top.deepLinkContent.type)
        m.enteredFromDeepLink = true
        showDetailScreen(m.top.deepLinkContent, invalid)
      else if m.global.authInfo = invalid and m.skipSignInOnLaunch <> true
        tubiLog("ContentController ask user to sign in")
        startSignIn(false)
      else if m.constants.ui.onnow.on = false or m.top.onNowContent <> invalid
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


'''''''''''''''''''''''
' onMetadataTaskReady
'
' Load the categories once the metadata task thread is ready.  This
' may be much after the task state is change to "RUN".  The task itself
' takes a moment to initialize and get its observer ready to handle
' incoming metadata requests.
Function onMetadataTaskReady()
  tubiLog("ContentController.onMetadataTaskReady")

  if m.metadataFetchTask.ready = true then
    m.metadataFetchTask.unobserveFieldScoped("ready")
    startUserExperience()
  end if
End Function


''''''''''''''''''''''''
' startSignIn
'
' Defer to the sign-in controller for sign in experience
Function startSignIn(skipDisambiguation)
  tubiLog("ContentController.startSignIn")
  m.SignIn = m.top.createChild("SignInController")
  m.SignIn.skipDisambiguationScreen = skipDisambiguation
  m.SignIn.observeFieldScoped("state", "onSignInComplete")
  m.SignIn.observeFieldScoped("backPressed", "onSignInBackPressed")
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
    while currentScreen() <> invalid
      popScreen(true)
    end while
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

  removeSignInController()
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

  if m.homeScreen <> invalid
    m.homeScreen.signedIn = (m.global.authInfo <> invalid)
  end if
  if m.categoryScreen <> invalid
    m.categoryScreen.dirtyUserCategories = true
  end if
  if m.searchScreen <> invalid
    m.searchScreen.signedIn = (m.global.authInfo <> invalid)
  end if
  if m.detailScreen <> invalid and m.detailScreenContent.peek() <> invalid
    contentAndIndex = m.detailScreenContent.peek()
    populateDetailScreen(contentAndIndex, true)
  end if

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
    removeSignInController()
  else if m.constants.ui.signIn.backExitsSignIn = true
    m.exitModal = showExitAppModal("onExitAppModalButtonSelected")
  end if
End Function


Function removeSignInController()
  m.SignIn.unobserveFieldScoped("state")
  m.SignIn.unobserveFieldScoped("backPressed")
  m.top.removeChild(m.SignIn)
  m.SignIn = invalid
  if currentScreen() <> invalid then currentScreen().setFocus(true)
End Function



'''''''''''''''''''''''
' onContentSelected
'
' Show the detail screen for the selected content
Function onContentSelected()
  tubiLog("ContentController.onContentSelected")
  content = m.categoryScreen.contentSelected
  m.autoplayContext = m.categoryScreen.currCategoryId
  showDetailScreen(content, m.categoryScreen.trackingUri)
End Function


''''''''''''''''''''
' onHistoryQueueChange
'
'
Function onHistoryQueueChange()
  tubiLog("ContentController.onHistoryQueueChange")
  if m.categoryScreen <> invalid then m.categoryScreen.dirtyUserCategories = true
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

Function onSearchContentSelected()
  tubiLog("ContentController.onSearchContentSelected")
  m.autoplayContext = invalid
  showDetailScreen(m.searchScreen.contentSelected, m.searchScreen.trackingUri)
End Function


''''''''''''''''''''
' onSignInSelected
'
' Launch the sign in experience
Function onSignInSelected()
  tubiLog("ContentController.onSignInSelected")
  startSignIn(true)
End Function

''''''''''''''''''''
' onSignOutSelected
'
' Log the user out, update screens
Function onSignOutSelected()
  tubiLog("ContentController.onSignOutSelected")
  showSignOutModal("onSignOutModalSelected")
End Function


''''''''''''''''''''
' onSignOutModalSelected
'
' Log the user out, update screens
Function onSignOutModalSelected(msg)
  tubiLog("ContentController.onSignOutModalSelected")

  'do the sign out stuff if confirmed
  if msg.getData() = 0
    ' flush the screenstack in any case where the user has successfully
    ' gone through the sign-in.  If they 'back' out of it, the screen
    ' stack will stay intact and this function will not be called
    while currentScreen() <> invalid
      popScreen(true)
    end while

    m.authInfoReceived = false
    if m.authTask <> invalid
      m.authTask.unobserveFieldScoped("onAuthInfoReceived")
    end if
    m.authTask = CreateObject("roSGNode", "AuthTask")
    m.authTask.observeFieldScoped("authInfo", "onAuthInfoReceived")
    m.authTask.functionName = "execSignOut"
    m.authTask.control = "RUN"

    m.categoryScreen = invalid
    m.spinner.visible = true
    m.spinner.setFocus(true)
  end if
End Function

''''''''''''''''''''
' onAboutSelected
'
' Show the about screen
Function onAboutSelected()
  tubiLog("ContentController.onAboutSelected")
  m.aboutScreen = CreateObject("roSGNode", "ModalDialogScreen")
  m.aboutScreen.title = "About Tubi"
  message = "Version " + m.constants.settings.version.Replace("_",".") + Chr(10)
  message = message + Chr(10)
  message = message + Chr(169) + " 2017 Tubi, Inc. all rights reserved." + Chr(10) ' + Chr(13)
  message = message + "The Tubi wordmark and all related logotypes are trademarks of Tubi, Inc."
  m.aboutScreen.message = message
  m.aboutScreen.buttons = ["Close"]
  m.aboutScreen.observeFieldScoped("buttonSelected", "onCloseModal")
  pushModal(m.aboutScreen)
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


Function onPrivacySelected()
  tubiLog("ContentController.onPrivacySelecte")
  m.privacyText = CreateObject("roSGNode", "ModalDialogScreen")
  m.privacyText.title = "Tubi Privacy Policy"
  m.privacyText.scrollable = true
  'm.privacyText.message = legal
  m.privacyText.buttons = ["Close"]
  m.privacyText.observeFieldScoped("buttonSelected", "onCloseModal")
  pushModal(m.privacyText)
  m.privacyRequestTask = CreateObject("roSGNOde", "SimpleRequestTask")
  m.privacyRequestTask.uri = m.constants.urls.privacyUrl 
  m.privacyRequestTask.node = m.privacyText
  m.privacyRequestTask.field = "message"
  m.privacyRequestTask.control = "RUN"
End Function


'''''''''''''''''''
' onPlayerError
'
Function showPlayerError(errorMessage As String)
  tubiLog("ContentController.showPlayerError")
  showErrorModal(0, errorMessage, onRetryPlayerError, onCancelPlayerError)
End Function

Function onRetryPlayerError()
  ' reset the video player state in case trying to resume causes an error again
  m.videoPlayer.state = ""
  ' try to resume the video from the last checkpoint
  onResume()
End Function

Function onCancelPlayerError()
  ' reset the video player state in case an error occurs during the next attempt at playing a video
  m.videoPlayer.state = ""

  top = currentScreen()
  if top <> invalid then
    top.setFocus(true)
  end if
End Function


'''''''''''
' onPlay
'
' Notify the main Brightscript thread to invoke the video player
Function onPlay()
  tubiLog("ContentController.onPlay")
  content = getDetailScreenContent()
  if content <> invalid then
    if m.global.authInfo = invalid and m.promptSignInOnGuestPlay = true
      title = "Sign in for a better experience"
      message = "Sign in for free to save to your queue and sync with other devices"
      buttons = ["Sign in or Register", "Play Anyways"]
      showModal(title, message, buttons, "onPlaySignInModalButtonSelected")
      m.promptSignInOnGuestPlay = false  ' only show this once per session
    else
      playVideoContent(content, false, 0)
    end if
  else
    tubiLog("ERROR: Play selected but content is invalid")
  end if
End Function

Function onPlaySignInModalButtonSelected(msg)
  if msg.getData() = 0
    onSignInSelected()
  else
    content = getDetailScreenContent()
    playVideoContent(content, false, 0)
  end if
End Function


'''''''''''
' onResume
'
' Notify the main Brightscript thread to invoke the video player, resuming at the indicated location
Function onResume()
  tubiLog("ContentController.onResume")
  content = getDetailScreenContent()
  if content <> invalid then
    nowPos = invalid
    ' find the position in global history
    history = m.global.historyIds.findNode(content.id)
    if m.top.deepLinkContent = invalid or m.top.deepLinkContent.deepLinkType = "season" or m.top.deepLinkContent.deepLinkType = "series"
      if history <> invalid then
        nowPos = history.nowPos
      end if
    end if
    playVideoContent(content, false, nowPos)
  else
    tubiLog("ERROR: Resume selected but content is invalid")
  end if
End Function


Function startOnNow()
  tubiLog("ContentController.startOnNow")
  m.appLoadStopwatch.mark()
  ' meta-screen, really just to allow screenstack to function.  we interact
  ' with the child groups directly instead of the parent group
  m.homeScreen = CreateObject("roSGNode", "HomeScreen")
  m.homeScreen.observeFieldScoped("backgroundUriList", "homeScreenBackgroundUpdated")

  m.toolsMenu = m.homeScreen.findNode("ToolsMenu")
  m.toolsMenu.observeFieldScoped("searchSelected", "onSearchSelected")
  m.toolsMenu.observeFieldScoped("signInSelected", "onSignInSelected")
  m.toolsMenu.observeFieldScoped("signOutSelected", "onSignOutSelected")
  m.toolsMenu.observeFieldScoped("aboutSelected", "onAboutSelected")
  m.toolsMenu.observeFieldScoped("privacySelected", "onPrivacySelected")

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
  pushScreen(m.homeScreen, true)
End Function

Function homeScreenBackgroundUpdated()
  tubiLog("ContentController.homeScreenBackgroundUpdated")
  m.backgroundGroup.backgroundInfo = {
    type: getBackgroundtype(m.homeScreen.backgroundUriList)
    uriList: m.homeScreen.backgroundUriList
  }
End Function


'''''''''''''''''''''
' playVideoContent
'
' Helper function for onResume and onPlay to launch content
Function playVideoContent(content As Object, isAutoplay As Boolean, position=invalid As Dynamic)
  if content <> invalid
    if content.isTrailer
      m.videoPlayer.analyticsMode = "trailer"
      m.videoPlayer.observeFieldScoped("skipTrailer", "onSkipTrailer")
      m.videoPlayer.enableAds = false
      m.upNextTask = invalid
    else
      m.videoPlayer.analyticsMode = "normal"
      if isAutoplay = true
        m.videoPlayer.analyticsMode = "autoplay"
      end if
      m.videoPlayer.observeFieldScoped("historyPosition", "onEpisodePosition")
      m.videoPlayer.observeFieldScoped("creditsPosition", "onEpisodeCredits")
      m.videoPlayer.enableAds = true
      if m.top.deepLinkContent <> invalid
        m.videoPlayer.deeplinkSource = m.top.deepLinkContent.source
      end if
      ' preload autoplay content;  We don't observe 'error' or 'response' fields
      ' since they will be evaluated at the creditsCuepoint callback
      m.upNextTask = CreateObject("roSGNode", "UpNextTask")
      request = {}
      request.contentId = content.id
      if m.autoplayContext <> invalid
        request.categoryId = m.autoplayContext
      end if
      m.upNextTask.request = request
      m.upNextTask.control = "RUN"
    end if
    m.videoPlayer.observeFieldScoped("state", "onVideoPlayerState")
    m.videoPlayer.observeFieldScoped("backButtonPressed", "onVideoPlayerBackPressed")
    m.videoPlayer.visible = true
    m.videoPlayer.setFocus(true)
  
    ' Clone the content so we don't have listeners affecting it
    parent = CreateObject("roSGNode", "TubiContentNode")
    localContent = clone(content)
    if position <> invalid
      localContent.nowPos = position
    end if
    parent.appendChild(localContent)

    m.videoPlayer.playlist = parent
    m.videoPlayer.loopPlaylist = false
    m.videoPlayer.seekPlaylist = [0, localContent.nowPos]
    m.ScreenStack.visible = false

    ' For position history tracking
    m.updateHistoryTask.historyResult = invalid
    m.updateHistoryTask.content = localContent
  end if
End Function


''''''''''''''''''''''
' onEpisodePosition
'
' Update the resume position
' This function triggers when the video stops as well as when m.videoPlayer.historyPosition is updated
Function onEpisodePosition()
  tubiLog("ContentController.onEpisodePosition")
  ' Don't send history updates to the server if the user hasn't watched at least a certain amount of video
  history = m.global.historyIds.findNode(m.updateHistoryTask.content.id)
  if history <> invalid or m.videoPlayer.historyPosition > m.constants.player.historyFrequency
    ' Only run a new task if the previous task is done.  Priority of resume states is
    ' pretty low and we don't mind losing a few.
    if m.updateHistoryTask.state <> "RUN" then
      m.updateHistoryTask.nowPos = m.videoPlayer.historyPosition
      m.updateHistoryTask.control = "RUN"
    end if
  end if
End Function

Function onEpisodeCredits()
  tubiLog("ContentController.onEpisodeCredits")
  ' Verify that the UpNextTask has a response and it matches the currently playing content
  currentContent = m.videoPlayer.playlist.getChild(m.videoPlayer.playlistIndex)
  if m.upNextTask <> invalid and m.upNextTask.response <> invalid and m.upNextTask.request <> invalid and currentContent <> invalid and m.upNextTask.request.contentId = currentContent.id
    if m.upNextTask.response.getChildCount() > 0
      if m.upNextScreen <> invalid
        m.upNextScreen.unobserveField("contentSelected")
        m.upNextScreen.unobserveField("timeout")
        m.upNextScreen.unobserveField("backPressed")
        m.upNextScreen = invalid
      end if
      m.upNextScreen = CreateObject("roSGNode", "UpNextScreen")
      m.upNextScreen.observeField("contentSelected", "onUpNextContentSelected")
      m.upNextScreen.observeField("backPressed", "onUpNextBackPressed")
      m.upNextScreen.observeField("timeout", "onUpNextTimeout")
      m.upNextScreen.content = m.upNextTask.response
      pushScreen(m.upNextScreen, true)
      m.ScreenStack.visible = true
    end if
  end if
End Function

Function playUpNextContent(nextContent)
  oldContent = m.videoPlayer.content
  content = addSeriesTitle(nextContent, oldContent)
  stopVideoContent(m.constants.player.playerResults.completed, false)
  playVideoContent(content, true)
  popScreen()
  m.upNextScreen.unobserveField("contentSelected")
  m.upNextScreen.unobserveField("timeout")
  m.upNextScreen.unobserveField("backPressed")
  m.upNextScreen = invalid
End Function

Function onUpNextTimeout()
  tubiLog("ContentController.onUpNextTimeout")
  playUpNextContent(m.upNextScreen.contentFocused)
End Function

' Triggered by either a button press or by timer expiration
Function onUpNextContentSelected()
  tubiLog("ContentController.onUpNextContentSelected")
  playUpNextContent(m.upNextScreen.contentSelected)
  m.lastUserActivity = Uptime(0)
End Function

Function onUpNextBackPressed()
  tubiLog("ContentController.onUpNextBackPressed")
  ' remove the screen and put focus back on the video player transport
  m.upNextScreen.unobserveField("contentSelected")
  m.upNextScreen.unobserveField("backPressed")
  m.upNextScreen = invalid
  popScreen()
  if m.videoPlayer.state = "finished"
    ' up next was dismissed but playback had already finished
    returnToDetailScreenFromVideo(m.constants.player.playerResults.completed)
  else
    m.ScreenStack.visible = false
    m.videoPlayer.setFocus(true)
  end if
  m.lastUserActivity = Uptime(0)
End Function

Function onVideoPlayerState(msg)
  tubiLog("ContentController.onVideoPlayerState state = " + msg.GetData())
  state = msg.GetData()
  if state = "error"
    stopVideoContent(m.constants.player.playerResults.failed, true)
    errorMessage = m.constants.player.playerResults.failed
    if m.videoPlayer.errorMsg <> ""
      errorMessage = m.videoPlayer.errorMsg
    end if
    m.videoPlayer.errorMessage = ""
    showPlayerError(errorMessage)
  else if state = "finished"
    ' If trailer, play the feature
    finishedContent = m.videoPlayer.playlist.getChild(m.videoPlayer.playlistIndex)
    if finishedContent.isTrailer
      content = getDetailScreenContent()
      if content <> invalid then
        stopVideoContent(m.constants.player.playerResults.completed, false)
        playVideoContent(content, false, 0)  ' always start at zero here
      else
        ' just show the current screen on the screen stack
        stopVideoContent(m.constants.player.playerResults.completed, true)
      end if

    ' If not a trailer, look for UpNext content to play
    else
      if m.upNextScreen <> invalid and currentScreen().isSameNode(m.upNextScreen)
        tubiLog("Ignoring video state 'finished' while UpNextScreen is visible")
      else if m.upNextTask <> invalid and m.upNextTask.response <> invalid and m.upNextTask.response.getChild(0) <> invalid
        'this happens if the "next video" button has been pressed on the player transport
        nextContent = m.upNextTask.response.getChild(0)
        oldContent = m.videoPlayer.content

        nextContent = addSeriesTitle(nextContent, oldContent)
        stopVideoContent(m.constants.player.playerResults.completed, false)
        playVideoContent(nextContent, true)
      else
        returnToDetailScreenFromVideo(m.constants.player.playerResults.completed)
      end if
    end if
  end if
End Function

Function onVideoPlayerBackPressed()
  tubiLog("ContentController.onVideoPlayerBackPressed")
  returnToDetailScreenFromVideo(m.constants.player.playerResults.closed)
End Function

' Stop the video player and refresh detail screen with the relevant content
Function returnToDetailScreenFromVideo(result)
  stopVideoContent(result, true)
  content = m.videoPlayer.playlist.getChild(m.videoPlayer.playlistIndex)
  m.top.deepLinkContent = invalid
  if content.isTrailer
    content = getDetailScreenContent()
  end if
  ' Replace the entire detail screen content stack after video playback
  if currentScreen() <> invalid and currentScreen().isSameNode(m.detailScreen)
    m.detailScreenContent = []
  end if
  showDetailScreen(content, invalid)
End Function

' Stop the video player and optionally return to the screen stack
Function stopVideoContent(playerResult, showScreenStack)
  m.videoPlayer.unobserveFieldScoped("backButtonPressed")
  m.videoPlayer.unobserveFieldScoped("state")
  m.videoPlayer.unobserveFieldScoped("skipTrailer")
  m.videoPlayer.unobserveFieldScoped("historyPosition")
  m.videoPlayer.unobserveFieldScoped("creditsPosition")
  m.videoPlayer.deeplinkSource = ""
  m.videoPlayer.control = "stop"
  playerInfo = {}
  playerInfo.nowPos = m.videoPlayer.historyPosition
  playerInfo.result = playerResult
  if m.updateHistoryTask.historyResult <> invalid
    playerInfo.historyId = m.updateHistoryTask.historyResult.historyId
    playerInfo.parentHistoryId = m.updateHistoryTask.historyResult.parentHistoryId
  end if
  tubiLog("stopVideoContent: nowPos = " + playerInfo.nowPos.toStr())
  if playerInfo.historyId <> invalid and playerInfo.historyId <> "" then
    tubiLog("stopVideoContent: historyId = " + playerInfo.historyId.toStr())
  end if
  if playerInfo.parentHistoryId <> invalid and playerInfo.parentHistoryId <> "" then
    tubiLog("stopVideoContent: parentHistoryId = " + playerInfo.parentHistoryId.toStr())
  end if
  content = m.videoPlayer.playlist.getChild(m.videoPlayer.playlistIndex)

  Request = TubiRequest()
  Auth = TubiAuth(m.constants, Request)
  Bookmarks = TubiBookmarks(Request, Auth, m.constants)

  'update the nowPos in the global historyIds store
  if m.global.authInfo <> invalid and playerInfo.historyId <> invalid
    m.global.historyIds = Bookmarks.updateNowPos(content, playerInfo, m.global.historyIds)
  end if

  if m.categoryScreen <> invalid then 
    m.categoryScreen.dirtyUserCategories = true
  end if

  ' should only do this if not autoplaying another video
  if showScreenStack
    m.videoPlayer.visible = false
    m.ScreenStack.visible = true
    if currentScreen() <> invalid
      currentScreen().setFocus(true)
    end if
  end if
End Function


Function onWatchTrailer()
  tubiLog("ContentController.onWatchTrailer")
  content = getDetailScreenContent()
  if content <> invalid then
    trailerContent = CreateObject("roSGNode", "TubiContentNode")
    if content.id <> invalid
      trailerContent.id = content.id
    end if
    trailerContent.streamformat="hls"
    trailerContent.nowPos = 0
    trailerContent.isTrailer = true

    playVideoContent(trailerContent, false)
  end if
End Function

Function onSkipTrailer()
  tubiLog("ContentController.onSkipTrailer")
  stopVideoContent(m.constants.player.playerResults.completed, false)
  playVideoContent(getDetailScreenContent(), false)
End Function

Function onEpisodeList()
  tubiLog("ContentController.onEpisodeList")
  contentAndIndex = m.detailScreenContent.peek()
  if contentAndIndex <> invalid and contentAndIndex.content <> invalid
    m.episodesScreen = CreateObject("roSGNode", "EpisodesScreen")
    m.episodesScreen.content = contentAndIndex.content
    m.episodesScreen.observeFieldScoped("episodeSelected", "onEpisodeSelected")
    m.episodesScreen.observeFieldScoped("backgroundUriList", "onEpisodeBackgroundChange")

    if m.episodesScreen.content <> invalid and m.episodesScreen.content.id <> invalid
      contentId = Mid(m.episodesScreen.content.id, 2)  ' trim leading "0" off series id
      m.episodesScreen.trackingUri = m.episodesScreen.trackingUri + contentId
    end if

    m.episodesScreen.episodeToFocus = contentAndIndex.series2dIndex   'episodeToFocus should be [seasonIndex, episodeIndex]
  
    pushScreen(m.episodesScreen, true)
  end if
End Function


Function onEpisodeSelected()
  contentAndIndex = m.detailScreenContent.peek()
  if contentAndIndex <> invalid and contentAndIndex.content <> invalid
    contentAndIndex.series2dIndex = m.episodesScreen.episodeSelected
    popScreen(true)
    m.episodesScreen = invalid

    ' Autoplay the selected episode
    onResume()
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
' showDetailScreen
'
' @content: roSGNode, a content node for a single pieces of content, might be a video or top level series
Function showDetailScreen(content, sourceTrackingUri)
  if m.detailScreen = invalid
    m.detailScreen = CreateObject("roSGNode", "DetailScreen")
  end if

  ' ensure we have no observers before adding then below.
  ' TODO(CT): ScreenStack and observers set here are at odds with each other over
  '           managing observers.  Needs cleaning up.
  unobserveAllScoped(m.detailScreen)
  m.detailScreen.observeFieldScoped("playSelected", "onPlay")
  m.detailScreen.observeFieldScoped("resumeSelected", "onResume")
  m.detailScreen.observeFieldScoped("watchTrailerSelected", "onWatchTrailer")
  m.detailScreen.observeFieldScoped("episodeListSelected", "onEpisodeList")
  m.detailScreen.observeFieldScoped("addToQueueSelected", "onAddToQueueSelected")
  m.detailScreen.observeFieldScoped("removeFromQueueSelected", "onRemoveFromQueueSelected")
  m.detailScreen.observeFieldScoped("removeFromHistorySelected", "onRemoveFromHistorySelected")
  m.detailScreen.observeFieldScoped("itemFailed", "onDetailItemFailed")
  m.detailScreen.observeFieldScoped("backButtonPressed", "onDetailBackPressed")
  m.detailScreen.observeFieldScoped("relatedContentSelected", "onRelatedContentSelected")
  contentAndIndex = {
    content: content
    series2dIndex: [-1,-1]   'default, indicating that there was no specific episode requested
    sourceTrackingUri: sourceTrackingUri
  }
  m.detailScreenContent.push(contentAndIndex)
  if m.top.deepLinkContent <> invalid or content.type = m.constants.ui.contentTypes.series or (content.type = m.constants.ui.contentTypes.video and content.seriesId <> invalid and content.seriesId <> "")
    m.detailScreen.isLoading = true
  else
    m.detailScreen.trackingUri = populateDetailTrackingUri(content, invalid)
    populateDetailScreen(contentAndIndex, true)
  end if
  ' always fetch detail content so we get related items as well
  if currentScreen() = invalid or not currentScreen().isSameNode(m.detailScreen)
    pushScreen(m.detailScreen, false)  ' don't send tracking until we resolve series episode
  end if
  getSingleContentFromServer()
End Function


'''''''''''''''''''''
' populateDetailScreen
'
'Populates the detail screen's state from a content node
'@content: tubiContentNode
Function populateDetailScreen(contentAndIndex, resetButtonIndex=false)
  content = contentAndIndex.content
  'hide the spinner
  wasLoading = m.detailScreen.isLoading
  m.detailScreen.isLoading = false

  'update detail screen state via the input interface
  m.detailScreen.title = content.title
  m.detailScreen.releaseDate = content.releaseDate
  m.detailScreen.genres = content.genres
  m.detailScreen.hasTrailer = content.hasTrailer

  bookmark = m.global.bookmarkIds.findNode(content.id)
  history = m.global.historyIds.findNode(content.id)

  episode = getEpisodeContent(contentAndIndex.series2dIndex, content)
  episodeHistory = invalid
  if content.type = m.constants.ui.contentTypes.series
    if episode <> invalid
      episodeHistory = m.global.historyIds.findNode(episode.id)
      m.detailScreen.episodeTitle = episode.title
    end if

    m.detailScreen.isSeries = true
    m.detailScreen.mode = "series"
  else
    m.detailScreen.isSeries = false
    m.detailScreen.mode = "movie"
  end if

  if episode <> invalid
    stateSource = episode
  else
    stateSource = content
  end if

  m.detailScreen.length = stateSource.length
  m.detailScreen.rating = stateSource.rating
  m.detailScreen.description = stateSource.description
  m.detailScreen.directors = stateSource.directors
  m.detailScreen.starring = stateSource.actors

  if episode <> invalid and (episode.hasSubtitles = true or not m._.empty(episode.subtitleTracks))
    m.detailScreen.hasCC = true
  else if content <> invalid and content.type = m.constants.ui.contentTypes.video and (content.hasSubtitles = true or not m._.empty(content.subtitleTracks))
    m.detailScreen.hasCC = true
  else
    m.detailScreen.hasCC = false
  end if

  m.detailScreen.isBookmark = (bookmark <> invalid)
  m.detailScreen.isHistory = (history <> invalid)

  if content.type = m.constants.ui.contentTypes.series and episodeHistory <> invalid and episodeHistory.nowPos > 0
    m.detailScreen.resumePoint = episodeHistory.nowPos
  else if content.type = m.constants.ui.contentTypes.video and history <> invalid and history.nowPos > 0
    m.detailScreen.resumePoint = history.nowPos
  else
    m.detailScreen.resumePoint = 0
  end if

  'tell the detail screen/info panel to vertically center the info panel
  m.detailScreen.calculateInfoHeight = true

  m.detailScreen.relatedContent = content.relatedContent

  if wasLoading or resetButtonIndex
    m.detailScreen.jumpToItem = 0
  end if

  'update the background images for the detail screen
  if content.backgrounds <> invalid and content.backgrounds.count() > 0
    backgroundUriList = content.backgrounds
  else
    backgroundUriList = [m.defaultBackgroundUri]
  end if
  m.backgroundGroup.backgroundInfo = {
    type: m.constants.ui.backgroundTypes.fullScreen
    uriList: backgroundUriList
  }
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
Function onEpisodeBackgroundChange()
  TubiLog("ContentController.onEpisodeBackgroundChange")
  m.backgroundGroup.backgroundInfo = {
    type: getBackgroundtype(m.episodesScreen.backgroundUriList)
    uriList: m.episodesScreen.backgroundUriList
  }
End Function


Function onSearchBackgroundChange()
  TubiLog("ContentController.onSearchBackgroundChange")
  m.backgroundGroup.backgroundInfo = {
    type: getBackgroundtype(m.searchScreen.backgroundUriList)
    uriList: m.searchScreen.backgroundUriList
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
  tubiLog("ContentController.onFirstPosterLoaded")  'write to console only
  messageInfo = {
    loadtime: m.appLoadStopwatch.TotalMilliseconds()
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
  'get the singleFeaturePoster experiment value - but only one time
  if m.singleFeaturePoster = invalid
    if m.constants.ui.categoryScreen.singleFeaturePoster <> invalid
       m.singleFeaturePoster = m.constants.ui.categoryScreen.singleFeaturePoster
    else
      m.singleFeaturePoster = (getExperimentValue("UserNamespace", "roku_single_feature_poster") = 1)
    end if
  end if

  backgroundType = m.constants.ui.backgroundTypes.topRight
  if backgroundUriList[0] = m.defaultBackgroundUri
    backgroundType = m.constants.ui.backgroundTypes.fullScreen
  else
    if m.categoryScreen <> invalid and m.categoryScreen.isInFocusChain() and m.categoryScreen.cursorPosition[0] = 0 and m.singleFeaturePoster = true
      backgroundType = m.constants.ui.backgroundTypes.feature
    end if
  end if
  return backgroundType
End Function


' helper function for adding series title metadata to content returned from the up next API.
' @content: episode content node with metadata from the up next api
' @oldContent: episode content with full metadata, including parentType (usually from the player)
Function addSeriesTitle(content, oldContent)
  if content.parentId <> invalid and oldContent.parentId <> invalid
    if oldContent.parentId <> "" and content.parentId = oldContent.parentId
      content.parentType = "series"
      content.parentTitle = oldContent.parentTitle
    end if
  end if

  return content
End Function


'pass the boomarkIds as an AA to the metadatafetch task
Function onBookmarkIdsUpdate()
  tubiLog("ContentController.onBookmarkIdsUpdate")
  bookmarkIdsAA = convertNodesToIdsAA(m.global.bookmarkIds)
  m.metadataFetchTask.bookmarkIds = bookmarkIdsAA
End Function

'pass the historyIds as an AA to the metadatafetch task
Function onHistoryIdsUpdate()
  tubiLog("ContentController.onHistoryIdsUpdate")
  historyIdsAA = convertNodesToIdsAA(m.global.historyIds)
  m.metadataFetchTask.historyIds = historyIdsAA
End Function
