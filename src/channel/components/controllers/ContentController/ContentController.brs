Function init()
  tubiLog(" ")
  tubiLog("Init Scenegraph----------------")
  'first things first, observe the live tv content field which comes from the main thread
  m.top.observeFieldScoped("onNowContent", "onOnNowContent")
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

  m.global.addField("bookmarkIds", "node", false)
  m.global.addField("historyIds", "node", false)

  m.metadataFetchTask.observeFieldScoped("ready", "onMetadataTaskReady")
  m.global.metadataFetchTask.control = "RUN"

  m.authTask = m.top.findNode("AuthTask")
  m.authTask.observeFieldScoped("authInfo", "onAuthInfoReceived")
  m.authInfoReceived = false
  m.authTask.functionName = "execInitializeUserData"
  
  m.authTask.control = "RUN"

  m.top.observeFieldScoped("deepLinkContent", "onDeepLinkContentReceived")
  m.deepLinkEvaluated = false  'indicates if the contentController has recognized that we entered from a deeplink or not

  m.logOutTask = m.top.findNode("LogOutTask")

  m.enteredFromDeepLink = false 'used to determine back button behavior in screen stack
  m.ScreenStack = m.top.findNode("ContentScreenStack")
  initScreenStack(m.ScreenStack, onScreenStackEmpty)

  m.videoPlayer = m.top.findNode("VideoPlayer")

  m.autohideTimer = m.top.findNode("AutohideTimer")
  m.autohideTimer.observeFieldScoped("fire", "onAutohide")

  m.appLoadStopwatch = CreateObject("roTimespan")

  m.detailScreenContent = invalid
  m.detailScreen2dIndex = [0, 0] 'stores the [season, episode] position

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
    ' only remove the last item if we have a valid callback
    m.exitModal = showExitAppModal("onExitAppModalButtonSelected")
  end if
End Function


''''''''''''''''''''''
' onExitAppModalButtonSelected
'
' handles the response of a user who has been presented an exit app modal
Function onExitAppModalButtonSelected()
  result = getModalResult(m.exitModal)

  if result = 0
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

  m.exitModal = closeModal(m.exitModal)   'set to invalid
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
        showDetailScreen(m.top.deepLinkContent)

      else if m.authTask.authInfo = invalid then
        tubiLog("ContentController ask user to sign in")
        startSignIn(false)
      else if m.constants.ui.onnow.on = false or m.top.onNowContent <> invalid
        startOnNow()
      end if
    end if
  end if
End Function


'''''''''''''''''''''''
' onAuthInfoReceived
'
'
Function onAuthInfoReceived()
  tubiLog("ContentController.onAuthInfoReceived")
  if m.authTask.authInfo = invalid
    ' user is logged out, so initialize empty bookmarks and history
    m.global.bookmarkIds = CreateObject("roSGNode", "BookmarkContentNode")
    m.global.historyIds = CreateObject("roSGNode", "HistoryContentNode")
  else
    if m.authTask.bookmarks = invalid then
      m.global.bookmarkIds = CreateObject("roSGNode", "BookmarkContentNode")
    else
      m.global.bookmarkIds = m.authTask.bookmarks
    end if
    if m.authTask.history = invalid then
      m.global.historyIds = CreateObject("roSGNode", "HistoryContentNode")
    else
      m.global.historyIds = m.authTask.history
    end if
  end if
  m.authInfoReceived = true
  startUserExperience()
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
  m.SignIn.observeFieldScoped("guestPass", "onSignInComplete")
  m.SignIn.observeFieldScoped("signedIn", "onSignInComplete")
  m.SignIn.observeFieldScoped("registered", "onSignInComplete")
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

  ' flush the screenstack in any case where the user has successfully
  ' gone through the sign-in.  If they 'back' out of it, the screen
  ' stack will stay intact and this function will not be called
  while currentScreen() <> invalid
    popScreen(true)
  end while

  m.backgroundGroup.enterFromSignIn = true

  if m.SignIn.guestPass then
    ' start the 'On Now' experience right away
    startOnNow()
  else
    ' retrieve the credentials on the AuthTask before starting the UI. This reduces jank.
    m.authTask.functionName = "execInitializeUserData"
    m.authTask.control = "RUN"
  end if

  removeSignInController()
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
  m.SignIn.unobserveFieldScoped("guestPass")
  m.SignIn.unobserveFieldScoped("signedIn")
  m.SignIn.unobserveFieldScoped("registered")
  m.SignIn.unobserveFieldScoped("backPressed")
  m.top.removeChild(m.SignIn)
  m.SignIn = invalid
  if currentScreen() <> invalid then currentScreen().setFocus(true)
End Function



'''''''''''''''''''''''
' onContentSelected
'
' Show the detail screen for the selected content
Function onContentSelected(msg As Object)
  tubiLog("ContentController.onContentSelected")
  content = msg.GetData()  
  showDetailScreen(content)
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
  m.searchScreen.observeFieldScoped("contentSelected", "onContentSelected")
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

''''''''''''''''''''
' onSignOutSelected
'
' Log the user out, update screens
Function onSignOutSelected()
  tubiLog("ContentController.onSignOutSelected")
  m.signOutModal = showSignOutModal("onSignOutModalSelected")
End Function


''''''''''''''''''''
' onSignOutModalSelected
'
' Log the user out, update screens
Function onSignOutModalSelected()
  tubiLog("ContentController.onSignOutModalSelected")
  modalResult = getModalResult(m.signOutModal)

  'do the sign out stuff if confirmed
  if modalResult = 0
    ' flush the screenstack in any case where the user has successfully
    ' gone through the sign-in.  If they 'back' out of it, the screen
    ' stack will stay intact and this function will not be called
    while currentScreen() <> invalid
      popScreen(true)
    end while
    m.categoryScreen = invalid
    m.AuthTask.functionName = "execSignOut"
    m.AuthTask.control = "RUN"
  end if

  focusedScreen = currentScreen()
  if focusedScreen <> invalid
    focusedScreen.setFocus(true)
  end if
  m.signOutModal = closeModal(m.signOutModal)   'set to invalid
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
  ' try to resume the video from the last checkpoint
  onResume()
End Function

Function onCancelPlayerError()
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
    content.nowPos = 0 'reset the start position
    playVideoContent(content)
  else
    tubiLog("ERROR: Play selected but content is invalid")
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
    ' find the position in global history
    history = m.global.historyIds.findNode(content.id)
    if history <> invalid then content.nowPos = history.nowPos
    playVideoContent(content)
  else
    tubiLog("ERROR: Resume selected but content is invalid")
  end if
End Function


Function startOnNow()
  tubiLog("ContentController.startOnNow")
  m.appLoadStopwatch.mark()
  ' meta-screen, really just to allow screenstack to function.  we interact
  ' with the child groups directly instead of the parent group
  m.homeScreen = CreateObject("roSGNode", "homeScreen")
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

  m.homeScreen.signedIn = (m.authTask.authInfo <> invalid)

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
  m.backgroundGroup.backgroundUriList = m.homeScreen.backgroundUriList

  'change the background type to fullscreen if new background uri list is default
  m.backgroundGroup.newBackgroundType = getBackgroundtype(m.backgroundGroup.backgroundUriList)
End Function


'''''''''''''''''''''
' playVideoContent
'
' Helper function for onResume and onPlay to launch content
Function playVideoContent(content As Object)
  m.videoPlayer.visible = true
  if content.isTrailer
    m.videoPlayer.analyticsMode = "trailer"
    m.videoPlayer.observeFieldScoped("state", "onTrailerFinished")
    m.videoPlayer.observeFieldScoped("backButtonPressed", "onTrailerFinished")
    m.videoPlayer.observeFieldScoped("skipTrailer", "onTrailerFinished")
    m.videoPlayer.enableAds = false
  else
    m.videoPlayer.analyticsMode = "normal"
    m.videoPlayer.observeFieldScoped("state", "onEpisodeFinished")
    m.videoPlayer.observeFieldScoped("historyPosition", "onEpisodePosition")
    m.videoPlayer.observeFieldScoped("backButtonPressed", "onEpisodeFinished")
    m.videoPlayer.enableAds = true
  end if

  m.videoPlayer.setFocus(true)
  
  ' Clone the content so we don't have listeners affecting it
  parent = CreateObject("roSGNode", "TubiContentNode")
  localContent = clone(content)
  parent.appendChild(localContent)

  m.videoPlayer.playlist = parent
  m.videoPlayer.loopPlaylist = false
  m.videoPlayer.seekPlaylist = [0, localContent.nowPos]
  m.ScreenStack.visible = false

  ' For position history tracking
  m.authTask.content = localContent
End Function


''''''''''''''''''''''
' onEpisodePosition
'
' Update the resume position
Function onEpisodePosition()
  tubiLog("ContentController.onEpisodePosition")
  ' Only run a new task if the previous task is done.  Priority of resume states is
  ' pretty low and we don't mind losing a few.
  if m.authTask.state <> "RUN" then
    m.authTask.nowPos = m.videoPlayer.historyPosition
    m.authTask.functionName = "updateHistory"
    m.authTask.control = "RUN"
  end if
End Function


'''''''''''''''''''''''
' onEpisodeFinished
'
' A series episode or feature film has finished playing
Function onEpisodeFinished(msg As Object)
  tubiLog("ContentController.onEpisodeFinished")
  endEpisode = false
  playerInfo = {}
  if msg.getField() = "state" and (msg.getData() = "error" or msg.getData() = "finished") then
    print "Episode finished"
    if msg.getData() = "error" then playerInfo.result = m.constants.player.playerResults.failed 
    if msg.getData() = "finished" then playerInfo.result = m.constants.player.playerResults.completed
    endEpisode = true
  else if msg.getField() = "backButtonPressed" then
    print "Back button pressed"
    playerInfo.result = m.constants.player.playerResults.closed
    endEpisode = true
  end if
  if endEpisode then
    onEpisodePosition()
    m.videoPlayer.unobserveFieldScoped("backButtonPressed")
    m.videoPlayer.unobserveFieldScoped("state")
    m.videoPlayer.unobserveFieldScoped("historyPosition")
    m.videoPlayer.deeplinkSource = ""
    m.videoPlayer.visible = false
    m.videoPlayer.control = "stop"

    playerInfo.nowPos = m.videoPlayer.historyPosition
    if m.authtask.historyResult <> invalid
      playerInfo.historyId = m.authtask.historyResult.historyId
      playerInfo.parentHistoryId = m.authtask.historyResult.parentHistoryId
    end if

    m.ScreenStack.visible = true
    currentScreen().setFocus(true)

    onPlayerInfo(playerInfo)
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

    playVideoContent(trailerContent)
  end if
End Function


Function onTrailerFinished(msg As Object)
  tubiLog("ContentController.onTrailerFinished")
  endTrailer = false
  if msg.getField() = "state"
    if msg.getData() = "error" or msg.getData() = "finished" then
      print "Trailer finished"
      endTrailer = true
    end if

  else if msg.getField() = "backButtonPressed" then
    print "Back button pressed"
    endTrailer = true

  else if msg.getField() = "skipTrailer"
    print "Trailer skipped"  'now we need to play the main video
    m.videoPlayer.unobserveFieldScoped("backButtonPressed")
    m.videoPlayer.unobserveFieldScoped("skipTrailer")
    m.videoPlayer.unobserveFieldScoped("state")
    m.videoPlayer.control = "stop"
    content = getDetailScreenContent()
    playVideoContent(content)
  end if

  if endTrailer then
    m.videoPlayer.unobserveFieldScoped("backButtonPressed")
    m.videoPlayer.unobserveFieldScoped("skipTrailer")
    m.videoPlayer.unobserveFieldScoped("state")
    m.videoPlayer.visible = false
    m.videoPlayer.control = "stop"
    m.ScreenStack.visible = true
    currentScreen().setFocus(true)
  end if
End Function


Function onEpisodeList()
  tubiLog("ContentController.onEpisodeList")
  m.episodesScreen = CreateObject("roSGNode", "EpisodesScreen")
  m.episodesScreen.content = m.detailScreenContent
  m.episodesScreen.observeFieldScoped("episodeSelected", "onEpisodeSelected")
  m.episodesScreen.observeFieldScoped("backgroundUriList", "onEpisodeBackgroundChange")

  if m.episodesScreen.content <> invalid and m.episodesScreen.content.id <> invalid
    contentId = Mid(m.episodesScreen.content.id, 2)  ' trim leading "0" off series id
    m.episodesScreen.trackingUri = m.episodesScreen.trackingUri + contentId
  end if

  m.episodesScreen.episodeToFocus = m.detailScreen2dIndex   'episodeToFocus should be [seasonIndex, episodeIndex]
  
  pushScreen(m.episodesScreen, true)
End Function


Function onEpisodeSelected()
  m.detailScreen.episodeSelection = m.episodesScreen.episodeSelected
  popScreen(true)
  m.episodesScreen = invalid

  ' Autoplay the selected episode
  onResume()
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
' onPlayerInfo
'
' Called when video playback is done
' Expect:
' playerInfo = {
'   result           - m.constants.player.playerResults value
'   nowPos           - integer seconds where playback stopped
'   historyId        - history id if stored at the server
'   parentHistoryId  - history id for series if historyId is valid and content is episodic
' }
'
Function onPlayerInfo(playerInfo) As Void
  tubiLog("onPlayerInfo: nowPos = " + playerInfo.nowPos.toStr())
  if playerInfo.historyId <> invalid and playerInfo.historyId <> "" then
    tubiLog("onPlayerInfo: historyId = " + playerInfo.historyId.toStr())
  end if
  if playerInfo.parentHistoryId <> invalid and playerInfo.parentHistoryId <> "" then
    tubiLog("onPlayerInfo: parentHistoryId = " + playerInfo.parentHistoryId.toStr())
  end if
  content = m.videoPlayer.playlist.getChild(m.videoPlayer.playlistIndex)

  Request = TubiRequest()
  Auth = TubiAuth(m.constants, Request)
  Bookmarks = TubiBookmarks(Request, Auth, m.constants)

  'update the nowPos in the global historyIds store
  m.global.historyIds = Bookmarks.updateNowPos(content, playerInfo, m.global.historyIds)

  'update the detailScreen UI with the resume point
  if m.detailScreen <> invalid
    m.detailScreen.resumePoint = playerInfo.nowPos
  end if

  'make sure the remove from history button is present on the details screen if necessary
  if m.authTask.authInfo <> invalid and m.global.historyIds.findNode(content.id) <> invalid
    m.detailScreen.isHistory = true
  end if

  if playerInfo.result = m.constants.player.playerResults.failed then
    showPlayerError(playerInfo.result)
    return
  end if

  if playerInfo.result = m.constants.player.playerResults.completed

    ' autoplay feature
    lastContent = m.detailScreenContent

    ' find the next episode in a series
    if lastContent <> invalid and lastContent.type = m.constants.ui.contentTypes.series then
      tubiLog("Autoplay: Series")

      nextEpisode2dIndex = invalid
      selection = m.detailScreen2dIndex  '2d array
      season = m.detailScreenContent.getChild(selection[0])

      if season <> invalid
        if season.getChild(selection[1] + 1) <> invalid
          nextEpisode2dIndex = [selection[0], selection[1] + 1]

        else
          nextSeason = m.detailScreenContent.getChild(selection[0] + 1)
          if nextSeason <> invalid and nextSeason.getChild(0) <> invalid
            nextEpisode2dIndex = [selection[0] + 1, 0]
          end if
        end if
      end if      

      if nextEpisode2dIndex <> invalid
        m.detailScreen2dIndex = nextEpisode2dIndex  'must be set for onPlay() to grab the next episode

        'update the current episode to be the next episode for the series history
        nextEpisode = getEpisodeContent(nextEpisode2dIndex, lastContent)
        m.global.historyIds = Bookmarks.updateNowPos(nextEpisode, {}, m.global.historyIds)

        populateDetailScreen(lastContent)
        onPlay()
        return
      end if

    ' find the next movie in a category
    else if lastContent <> invalid and lastContent.type = m.constants.ui.contentTypes.video then
      ' NOTE: be careful here in case of deep links, where the
      ' last title launched was not related to a category on 
      ' the category screen.  In that case we'll just skip
      ' autoplay.
      tubiLog("Autoplay: Movie")

      ' TODO(Chris): this is terribly unpleasant, looking into the categoryscreen's internal data structure
      parent = invalid
      if m.categoryScreen.cachedContent <> invalid
        parent = m.categoryScreen.cachedContent.getChild(m.categoryScreen.cursorPosition[0])
      end if
      if parent <> invalid and parent.type = m.constants.ui.contentTypes.category then
        for i=0 to parent.getChildCount()-1
          child = parent.getChild(i)
          if child.id = m.detailScreenContent.id then
            if parent.getChild(i+1) <> invalid
              nextContent = m.metadataTranslate.getContentFromCategoryJson(parent, i+1)
              if nextContent <> invalid then
                ' set the detail screen to focus on the next movie.
                m.detailScreenContent = nextContent
                populateDetailScreen(nextContent)
                m.categoryScreen.jumpToRowItem = [m.categoryScreen.cursorPosition[0], m.categoryScreen.cursorPosition[1]+1]
                onPlay()
                return
              end if
            end if
          end if
        end for
      end if
    end if
  end if

  if m.categoryScreen <> invalid then 
    m.categoryScreen.dirtyUserCategories = true
  end if

End Function


'''''''''''''''''''''
' showDetailScreen
'
' @content: roSGNode, a content node for a single pieces of content, might be a video or top level series
Function showDetailScreen(content)
  if m.detailScreen = invalid
    m.detailScreen = CreateObject("roSGNode", "DetailScreen")
  end if

  'observe detail screen output interface
  m.detailScreen.observeFieldScoped("playSelected", "onPlay")
  m.detailScreen.observeFieldScoped("resumeSelected", "onResume")
  m.detailScreen.observeFieldScoped("watchTrailerSelected", "onWatchTrailer")
  m.detailScreen.observeFieldScoped("episodeListSelected", "onEpisodeList")
  m.detailScreen.observeFieldScoped("addToQueueSelected", "onAddToQueueSelected")
  m.detailScreen.observeFieldScoped("removeFromQueueSelected", "onRemoveFromQueueSelected")
  m.detailScreen.observeFieldScoped("removeFromHistorySelected", "onRemoveFromHistorySelected")
  m.detailScreen.observeFieldScoped("itemFailed", "onDetailItemFailed")

  m.detailScreenContent = content

  'set the detail screen tracking uri
  'this must happen before pushScreen so that pushScreen can send the analytics request with the proper URI
  episode = getCurrentEpisode(content)
  m.detailScreen.trackingUri = populateDetailTrackingUri(content, episode)
  pushScreen(m.detailScreen, true)

  if m.enteredFromDeeplink or content.type = m.constants.ui.contentTypes.series
    m.detailScreen.isLoading = true
    getSingleContentFromServer()
  else
    populateDetailScreen(content)
  end if
End Function


'''''''''''''''''''''
' populateDetailScreen
'
'Populates the detail screen's state from a content node
'@content: tubiContentNode
Function populateDetailScreen(content)
  'hide the spinner
  m.detailScreen.isLoading = false

  'update detail screen state via the input interface
  m.detailScreen.title = content.title
  m.detailScreen.releaseDate = content.releaseDate
  m.detailScreen.genres = content.genres
  m.detailScreen.hasTrailer = content.hasTrailer

  bookmark = m.global.bookmarkIds.findNode(content.id)
  history = m.global.historyIds.findNode(content.id)

  episode = getCurrentEpisode(content)
  episodeHistory = invalid
  if content.type = m.constants.ui.contentTypes.series
    m.detailScreen2dIndex = [0, 0]
    if history <> invalid
      m.detailScreen2dIndex = findEpisode2dIndex(history.currentEpisodeId, content)
    end if
    
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

  if episode <> invalid and episode.subtitleTracks <> invalid
    m.detailScreen.hasCC = true
  else if content.type = m.constants.ui.contentTypes.video and content <> invalid and content.subtitleTracks <> invalid
    m.detailScreen.hasCC = true
  else
    m.detailScreen.hasCC = false
  end if

  m.detailScreen.isBookmark = (bookmark <> invalid)
  m.detailScreen.isHistory = (history <> invalid and m.authTask.authInfo <> invalid)

  if content.type = m.constants.ui.contentTypes.series and episodeHistory <> invalid and episodeHistory.nowPos > 0
    m.detailScreen.resumePoint = episodeHistory.nowPos
  else if content.type = m.constants.ui.contentTypes.video and history <> invalid and history.nowPos > 0
    m.detailScreen.resumePoint = history.nowPos
  else
    m.detailScreen.resumePoint = 0
  end if

  'tell the detail screen/info panel to vertically center the info panel
  m.detailScreen.calculateInfoHeight = true

  m.detailScreen.animateToListItem = 0

  'update the background images for the detail screen
  if content.backgrounds <> invalid and content.backgrounds.count() > 0
    m.backgroundGroup.backgroundUriList = content.backgrounds
  else
    m.backgroundGroup.backgroundUriList = [m.defaultBackgroundUri]
  end if
  m.backgroundGroup.newBackgroundType = "fullscreen"
End Function


'''''''''''''''''''''
' onGridBackgroundChange
'
'
Function onGridBackgroundChange()
  TubiLog("ContentController.onGridBackgroundChange")
  m.backgroundGroup.backgroundUriList = m.categoryScreen.backgroundUriList

  'change the background type to fullscreen if new background uri list is default
  m.backgroundGroup.newBackgroundType = getBackgroundtype(m.backgroundGroup.backgroundUriList)
  print "NEW BACKGROUNDURI LIST "; m.backgroundGroup.backgroundUriList 
End Function


'''''''''''''''''''''
' onEpisodeBackgroundChange
'
'
Function onEpisodeBackgroundChange()
  TubiLog("ContentController.onEpisodeBackgroundChange")
  m.backgroundGroup.backgroundUriList = m.episodesScreen.backgroundUriList

  'change the background type to fullscreen if new background uri list is default 
  m.backgroundGroup.newBackgroundType = getBackgroundtype(m.backgroundGroup.backgroundUriList)
End Function


Function onSearchBackgroundChange()
  TubiLog("ContentController.onSearchBackgroundChange")
  m.backgroundGroup.backgroundUriList = m.searchScreen.backgroundUriList

  'change the background type to fullscreen if new background uri list is default 
  m.backgroundGroup.newBackgroundType = getBackgroundtype(m.backgroundGroup.backgroundUriList)
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
  if backgroundUriList[0] = m.defaultBackgroundUri
    return "fullscreen"
  else
    return "topright"
  end if
End Function

