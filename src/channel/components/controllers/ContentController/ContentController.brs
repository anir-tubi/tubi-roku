Function init()
  tubiLog(" ")
  tubiLog("Init Scenegraph----------------")
  'first things first, observe the live tv content field which comes from the main thread
  m.top.observeField("onNowContent", "onOnNowContent")


  ' save a global reference to the fetch task for nodes to access
  m.metadataFetchTask = m.top.findNode("MetadataFetchTask")
  m.global.addField("metadataFetchTask", "node", false)
  m.global.metadataFetchTask = m.metadataFetchTask

  m.trackingLoggingTask = m.top.findNode("TrackingLoggingTask")
  m.global.addField("trackingLoggingTask", "node", false)
  m.global.trackingLoggingTask = m.trackingLoggingTask
  m.trackingLoggingTask.observeField("ready", "onTrackingLoggingReady")
  m.global.trackingLoggingTask.control = "RUN"
  
  m.background = m.top.findNode("ContentBackground")
  m.background.color = m.global.constants.ui.colors.backgroundColor

  m.backgroundGroup = m.top.findNode("BackgroundGroup")

  m.global.addField("bookmarkIds", "assocarray", false)
  m.global.addField("historyIds", "assocarray", false)
  m.global.addField("bookmarkOrder", "stringarray", false)
  m.global.addField("historyOrder", "stringarray", false)
  m.global.bookmarkIds = {series: {}, videos: {}} 'these are set in handleInitialBookmarks(), once a user has logged in
  m.global.historyIds = {series: {}, videos: {}}  'these are set in handleInitialHistory(), once a user has logged in
  m.global.bookmarkOrder = []  'this are set in handleInitialBookmarks(), once a user has logged in
  m.global.historyOrder = []  'this are set in handleInitialHistory(), once a user has logged in

  m.metadataFetchTask.observeField("ready", "onMetadataTaskReady")
  m.global.metadataFetchTask.control = "RUN"

  m.authTask = m.top.findNode("AuthTask")
  m.authTask.observeField("authInfo", "onAuthInfoReceived")
  m.authInfoReceived = false
  m.authTask.functionName = "execGetAuthInfo"
  m.authTask.control = "RUN"

  m.top.observeField("deepLinkContent", "onDeepLinkContentReceived")
  m.top.observeField("playerInfo", "onPlayerInfo")

  m.logOutTask = m.top.findNode("LogOutTask")

  m.enteredFromDeepLink = false 'used to determine back button behavior in screen stack
  m.ScreenStack = m.top.findNode("ScreenStack")
  initScreenStack(m.ScreenStack, startOnNow)

  m.videoPlayer = m.top.findNode("VideoPlayer")

  m.autohideTimer = m.top.findNode("AutohideTimer")
  m.autohideTimer.observeField("fire", "onAutohide")
End Function


Function onAutohide()
  tubiLog("ContentController.onAutohide")
  fadeTime = 3.0  ' default
  if m.autohideTimer.fadeTime <> invalid then fadeTime = m.autohideTimer.fadeTime
  m.autohideAnimation = fade(m.ScreenStack, "out", fadeTime)

  if m.autohideTimer.focusVideo = invalid or m.autohideTimer.focusVideo = true
    'the user has gone into the onnow player experience
    m.videoPlayer.setFocus(true)
    m.videoPlayer.observeField("backButtonPressed", "unAutohide")
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

  'the user is bringing back the on now home UI after returning from the on now player experience
  if m.autohideTimer.focusVideo = true
    videoPicker = m.VideoPlayer.findNode("VideoPicker")
    m.trackingLoggingTask.trackEvent = {
      trackType: "navigate"
      value: "/on_now/" + m.VideoPlayer.playlist.slug + "/1/" + videoPicker.contentFocused.toStr()
      ctx: "/home/1/cat/" + m.VideoPlayer.playlist.slug + "/1/" + videoPicker.contentFocused.toStr()
    }
  end if

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
  if m.trackingLoggingTask.ready = true
    m.trackingLoggingTask.unobserveField("ready")
    
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
  if m.metadataFetchTask.ready and m.authInfoReceived and m.trackingLoggingTask.ready then
    if m.top.deepLinkContent <> invalid then
      tubiLog("ContentController detected deep link request")
      ' we were asked to deep link into a content item. Go to it
      ' whether we were logged in or not.
      onDeepLinkContentReceived()
      m.top.deepLinkContent = invalid  ' reset it so when we come back through here on state change, we don't follow deep links again
    else if m.authTask.authInfo = invalid then
      startSignIn()
    else if m.top.onNowContent <> invalid
      startOnNow()
    end if
  end if
End Function


'''''''''''''''''''''''
' startCategoryScreen
'
' On either app start (if user is signed in) or after the sign in
' flow is complete, create and show the category screen.
Function startCategoryScreen()
  m.categoryScreen = CreateObject("roSGNode", "CategoryScreen")
  m.categoryScreen.observeField("contentSelected", "onContentSelected")
  m.categoryScreen.observeField("searchSelected", "onSearchSelected")
  m.categoryScreen.observeField("signInSelected", "onSignInSelected")
  m.categoryScreen.observeField("signOutSelected", "onSignOutSelected")
  m.categoryScreen.observeField("aboutSelected", "onAboutSelected")
  m.categoryScreen.observeField("privacySelected", "onPrivacySelected")
  m.categoryScreen.observeField("backgroundUriList", "onGridBackgroundChange")
  m.categoryScreen.signedIn = (m.authTask.authInfo <> invalid)
  pushScreen(m.categoryScreen)
End Function


'''''''''''''''''''''''
' onAuthInfoReceived
'
'
Function onAuthInfoReceived()
  tubiLog("ContentController.onAuthInfoReceived")
  m.authInfoReceived = true
  startUserExperience()
End Function


'''''''''''''''''''''''
' onOnNowContent
'
Function onOnNowContent()
  tubiLog("ContentController.onOnNowContent")
  m.top.unobserveField("onNowContent")
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
    m.metadataFetchTask.unobserveField("ready")
    startUserExperience()
  end if
End Function


''''''''''''''''''''''''
' startSignIn
'
' Defer to the sign-in controller for sign in experience
Function startSignIn()
  tubiLog("ContentController.startSignIn")
  m.SignIn = m.top.createChild("SignInController")
  m.SignIn.observeField("guestPass", "onSignInComplete")
  m.SignIn.observeField("signedIn", "onSignInComplete")
  m.SignIn.observeField("registered", "onSignInComplete")
  m.SignIn.observeField("exitApp", "onSignInExitApp")
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
    popScreen()
  end while

  if m.SignIn.guestPass then
    ' start the 'On Now' experience right away
    startOnNow()
  else
    ' retrieve the credentials on the AuthTask before starting the UI. This reduces jank.
    m.authTask.functionName = "execGetAuthInfo"
    m.authTask.control = "RUN"
  end if

  m.SignIn.unobserveField("guestPass")
  m.SignIn.unobserveField("signedIn")
  m.SignIn.unobserveField("registered")
  m.top.removeChild(m.SignIn)
  m.SignIn = invalid
End Function


'''''''''''''''''''''''''
' onSignInExitApp
'
' The sign-in controller says the user wants to exit the app so tell the main thread we want to exit
Function onSignInExitApp()
  m.top.exitApp = true
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
  if m.categoryScreen <> invalid then m.categoryScreen.dirtyUserCategories = true
End Function


''''''''''''''''''''
' onSearchSelected
'
' Show the search screen
Function onSearchSelected()
  tubiLog("ContentController.onSearchSelected")
  m.searchScreen = CreateObject("roSGNode", "SearchScreen")
  m.searchScreen.observeField("contentSelected", "onContentSelected")
  m.searchScreen.observeField("backgroundUriList", "onSearchBackgroundChange")
  pushScreen(m.searchScreen)
End Function


''''''''''''''''''''
' onSignInSelected
'
' Launch the Sign In experience
Function onSignInSelected()
  tubiLog("ContentController.onSignInSelected")
  startSignIn()

  'preloads the unblurred background so when we hit the category screen
  'we can just start the timer for countdown to transition to the blurred background
  m.backgroundGroup.enterFromSignIn = true
End Function

''''''''''''''''''''
' onSignOutSelected
'
' Log the user out, update screens
Function onSignOutSelected()
  tubiLog("ContentController.onSignOutSelected")
  ' flush the screenstack in any case where the user has successfully
  ' gone through the sign-in.  If they 'back' out of it, the screen
  ' stack will stay intact and this function will not be called
  while currentScreen() <> invalid
    popScreen()
  end while
  m.categoryScreen = invalid
  m.AuthTask.functionName = "execSignOut"
  m.AuthTask.control = "RUN"
End Function

''''''''''''''''''''
' onAboutSelected
'
' Show the about screen
Function onAboutSelected()
  tubiLog("ContentController.onAboutSelected")
  m.aboutScreen = CreateObject("roSGNode", "ModalDialogScreen")
  m.aboutScreen.title = "About Tubi TV"
  message = "(C) 2016 Tubi TV" + Chr(10) ' + Chr(13)
  message = message + "All rights reserved." + Chr(10) '+ Chr(13)
  message = message + "Tubi TV related marks are trademarks of Tubi TV, an adRise Company."
  m.aboutScreen.message = message
  m.aboutScreen.buttons = ["Close"]
  m.aboutScreen.observeField("buttonSelected", "onCloseModal")
  pushModal(m.aboutScreen)
End Function


'''''''''''''''''''
' onCloseModal
'
' Dismiss a modal dialog
Function onCloseModal()
  tubiLog("ContentController.onCloseAbout")
  popScreen()
  m.aboutScreen = invalid
End Function


Function onPrivacySelected()
  tubiLog("ContentController.onPrivacySelecte")
  m.privacyText = CreateObject("roSGNode", "ModalDialogScreen")
  m.privacyText.title = "Tubi TV Privacy Policy"
  m.privacyText.scrollable = true
  'm.privacyText.message = legal
  m.privacyText.buttons = ["Close"]
  m.privacyText.observeField("buttonSelected", "onCloseModal")
  pushModal(m.privacyText)
  m.privacyRequestTask = CreateObject("roSGNOde", "SimpleRequestTask")
  m.privacyRequestTask.uri = m.global.constants.urls.privacyUrl 
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
    playVideoContent(content)
  else
    tubiLog("ERROR: Resume selected but content is invalid")
  end if
End Function


Function startOnNow()
  tubiLog("ContentController.startOnNow")
  ' meta-screen, really just to allow screenstack to function.  we interact
  ' with the child groups directly instead of the parent group
  m.homeScreen = CreateObject("roSGNode", "homeScreen")
  m.homeScreen.observeField("backgroundUriList", "onNowStopped")

  m.toolsMenu = m.homeScreen.findNode("ToolsMenu")
  m.toolsMenu.observeField("searchSelected", "onSearchSelected")
  m.toolsMenu.observeField("signInSelected", "onSignInSelected")
  m.toolsMenu.observeField("signOutSelected", "onSignOutSelected")
  m.toolsMenu.observeField("aboutSelected", "onAboutSelected")
  m.toolsMenu.observeField("privacySelected", "onPrivacySelected")
  m.toolsMenu.observeField("backgroundUriList", "onStopLiveTV")

  m.onNow = m.homeScreen.findNode("OnNow")
  m.onNow.control = "play"

  m.categoryScreen = m.homeScreen.findNode("CategoryScreen")
  m.categoryScreen.observeField("contentSelected", "onContentSelected")

  m.homeScreen.signedIn = (m.authTask.authInfo <> invalid)

  ' If experiment calls for OnNow, set the content
  if getExperimentValue("UserNamespace", "roku_on_now") = 1
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
  pushScreen(m.homeScreen)
End Function

Function onNowStopped()
  tubiLog("ContentController.onNowStopped")
  m.backgroundGroup.backgroundUriList = m.homeScreen.backgroundUriList
  m.backgroundGroup.newBackgroundType = "grid"
End Function


'''''''''''''''''''''
' playVideoContent
'
' Helper function for onResume and onPlay to launch content
Function playVideoContent(content As Object)
  m.videoPlayer.visible = true
  m.videoPlayer.analyticsMode = "normal"
  m.videoPlayer.observeField("state", "onEpisodeFinished")
  m.videoPlayer.observeField("historyPosition", "onEpisodePosition")
  m.videoPlayer.observeField("backButtonPressed", "onEpisodeFinished")
  m.videoPlayer.setFocus(true)
  
  ' Clone the content so we don't have listeners affecting it
  parent = CreateObject("roSGNode", "TubiContentNode")
  localContent = clone(content)
  parent.appendChild(localContent)

  m.videoPlayer.playlist = parent
  m.videoPlayer.enableAds = true
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
    if msg.getData() = "error" then playerInfo.result = m.global.constants.player.playerResults.failed 
    if msg.getData() = "finished" then playerInfo.result = m.global.constants.player.playerResults.completed
    endEpisode = true
  else if msg.getField() = "backButtonPressed" then
    print "Back button pressed"
    playerInfo.result = m.global.constants.player.playerResults.closed
    endEpisode = true
  end if
  if endEpisode then
    m.videoPlayer.unobserveField("backButtonPressed")
    m.videoPlayer.unobserveField("state")
    m.videoPlayer.unobserveField("historyPosition")
    m.videoPlayer.visible = false
    m.videoPlayer.control = "stop"

    playerInfo.nowPos = m.videoPlayer.historyPosition
    if m.authtask.historyResult <> invalid
      playerInfo.historyId = m.authtask.historyResult.historyId
      playerInfo.parentHistoryId = m.authtask.historyResult.parentHistoryId
    end if

    m.ScreenStack.visible = true
    currentScreen().setFocus(true)

    ' trigger onPlayerInfo callback for remainder of logic
    m.top.playerInfo = playerInfo
  end if
End Function


Function onWatchTrailer()
  tubiLog("ContentController.onWatchTrailer")
  content = getDetailScreenContent()
  if content <> invalid then
    playlist = CreateObject("roSGNode", "TubiContentNode")
    trailerContent = playlist.createChild("TubiContentNode")
    if content.id <> invalid
      trailerContent.id = content.id
    end if
    trailerContent.url = content.trailerUrls[0]
    trailerContent.streamformat="hls"
    trailerContent.nowPos = 0
    trailerContent.isTrailer = true

    m.videoPlayer.visible = true
    m.videoPlayer.analyticsMode = "trailer"
    m.videoPlayer.observeField("state", "onTrailerFinished")
    m.videoPlayer.observeField("backButtonPressed", "onTrailerFinished")
    m.videoPlayer.observeField("skipTrailer", "onTrailerFinished")
    m.videoPlayer.setFocus(true)
    m.videoPlayer.playlist = playlist
    m.videoPlayer.enableAds = false
    m.videoPlayer.loopPlaylist = "false"
    m.videoPlayer.control = "play"
    m.ScreenStack.visible = false
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
    m.videoPlayer.unobserveField("backButtonPressed")
    m.videoPlayer.unobserveField("skipTrailer")
    m.videoPlayer.unobserveField("state")
    m.videoPlayer.observeField("state", "onTrailerStopped")
    m.videoPlayer.control = "stop"
  end if

  if endTrailer then
    m.videoPlayer.unobserveField("backButtonPressed")
    m.videoPlayer.unobserveField("skipTrailer")
    m.videoPlayer.unobserveField("state")
    m.videoPlayer.visible = false
    m.videoPlayer.control = "stop"
    m.ScreenStack.visible = true
    currentScreen().setFocus(true)
  end if
End Function


Function onTrailerStopped()
  if m.videoPlayer.state = "stopped"
    m.videoPlayer.unobserveField("state")
    content = getDetailScreenContent()
    playVideoContent(content)
  end if
End Function


Function onEpisodeList()
  m.episodesScreen = CreateObject("roSGNode", "EpisodesScreen")
  m.episodesScreen.content = m.detailScreen.content
  m.episodesScreen.observeField("episodeSelected", "onEpisodeSelected")
  m.episodesScreen.observeField("backgroundUriList", "onEpisodeBackgroundChange")

  if m.episodesScreen.content <> invalid and m.episodesScreen.content.id <> invalid
    m.episodesScreen.trackingUri = m.episodesScreen.trackingUri + m.episodesScreen.content.id
  end if

  m.episodesScreen.episodeToFocus = m.detailScreen.episodeSelection   'episodeToFocus should be [seasonIndex, episodeIndex]
  
  pushScreen(m.episodesScreen)
End Function


Function onEpisodeSelected()
  m.detailScreen.episodeSelection = m.episodesScreen.episodeSelected
  popScreen()
  m.episodesScreen = invalid

  ' Autoplay the selected episode
  onResume()
End Function


' Helper to deduce the content, video or episode, to play or resume
Function getDetailScreenContent()
  content = invalid
  if m.detailScreen.content <> invalid then
    if m.detailScreen.content.type = m.global.constants.ui.contentTypes.video then
      content = m.detailScreen.content
    else
      selection = m.detailScreen.episodeSelection
      series = m.detailScreen.content.getChild(selection[0])
      if series <> invalid then
        episode = series.getChild(selection[1])
        if episode <> invalid then
          content = episode
        end if
      end if
    end if
  end if
  return content
End Function


'''''''''''''''''''''
' onDeepLinkContentReceived
'
' Show the detail screen for the content id that was deeplinked to
Function onDeepLinkContentReceived()
  tubiLog("onDeepLinkContentReceived")
  if m.metadataFetchTask.ready and m.authInfoReceived and m.top.deepLinkContent <> invalid then
    'TODO(Chris): Supplement this content with history & queue status once we have it
    testLog("Deep link contentId = " + m.top.deepLinkContent.id)
    testLog("Deep link type = " + m.top.deepLinkContent.type)
    m.enteredFromDeepLink = true
    showDetailScreen(m.top.deepLinkContent)
  end if
End Function


'''''''''''''''''''''
' onPlayerInfo
'
' Is called when the nowPos is updated from the player
Function onPlayerInfo() As Void
  playerInfo = m.top.playerInfo
  tubiLog("onPlayerInfo: nowPos = " + playerInfo.nowPos.toStr())
  if playerInfo.historyId <> invalid and playerInfo.historyId <> "" then
    tubiLog("onPlayerInfo: historyId = " + playerInfo.historyId.toStr())
  end if
  if playerInfo.parentHistoryId <> invalid and playerInfo.parentHistoryId <> "" then
    tubiLog("onPlayerInfo: parentHistoryId = " + playerInfo.parentHistoryId.toStr())
  end if
  content = m.videoPlayer.playlist.getChild(m.videoPlayer.playlistIndex)

  constants = m.global.constants
  Request = TubiRequest()
  Auth = TubiAuth(constants, Request)
  Bookmarks = TubiBookmarks(Request, Auth, constants)

  'update the nowPos in the global historyIds store
  newHistory = Bookmarks.updateNowPos(content, playerInfo, m.global.historyIds, m.global.historyOrder)
  m.global.historyIds = newHistory.historyIds
  m.global.historyOrder = newHistory.historyOrder

  if playerInfo.result = m.global.constants.player.playerResults.failed then
    showPlayerError(playerInfo.result)
    return
  end if

  if playerInfo.result = constants.player.playerResults.completed

    ' autoplay feature
    lastContent = m.detailScreen.content

    ' find the next episode in a series
    if lastContent <> invalid and lastContent.type = m.global.constants.ui.contentTypes.series then
      tubiLog("Autoplay: Series")

      nextEpisode = invalid
      selection = m.detailScreen.episodeSelection  '2d array
      season = m.detailScreen.content.getChild(selection[0])

      if season <> invalid
        if season.getChild(selection[1] + 1) <> invalid
          nextEpisode = [selection[0], selection[1] + 1]

        else
          nextSeason = m.detailScreen.content.getChild(selection[0] + 1)
          if nextSeason <> invalid and nextSeason.getChild(0) <> invalid
            nextEpisode = [selection[0] + 1, 0]
          end if
        end if
      end if      

      if nextEpisode <> invalid
        m.detailScreen.episodeSelection = nextEpisode
        onPlay()
        return
      end if

    ' find the next movie in a category
    else if lastContent <> invalid and lastContent.type = m.global.constants.ui.contentTypes.video then
      ' NOTE: be careful here in case of deep links, where the
      ' last title launched was not related to a category on 
      ' the category screen.  In that case we'll just skip
      ' autoplay.
      '
      ' NOTE2: m.top.playContent comes from the detailscreen,
      '        so we map it back to the categoryscreen via 'shortContent'
      tubiLog("Autoplay: Movie")
      parent = m.detailScreen.shortContent.getParent()
      if parent <> invalid and parent.type = m.global.constants.ui.contentTypes.category then
        for i=0 to parent.getChildCount()-1
          child = parent.getChild(i)
          if child.isSameNode(m.detailScreen.shortContent) then
            nextContent = parent.getChild(i+1)
            if nextContent <> invalid then
              ' set the detail screen to focus on the next movie. Note that this will take some 
              ' time to populate so we don't use it for launching the player
              m.detailScreen.observeField("content", "onAutoplayContentReady")
              m.detailScreen.shortContent = nextContent
              return
            end if
          end if
        end for
      end if
    end if
  end if

  ' no autoplay available, so force a details screen reload to get nowPos and history id set
  if m.detailScreen <> invalid
    ' Because of a race condition, earlier detail screen won't redraw itself if we just show it,
    ' so we rebuild it new.  This may lose the episode selection, but it might be set by currentEpisode
    ' from the service
    content = m.detailScreen.shortContent 
    popScreen()
    showDetailScreen(content)
  end if

  if m.categoryScreen <> invalid then 
    m.categoryScreen.dirtyUserCategories = true
  end if

End Function


'''''''''''''''''''''''''
' onAutoplayContentReady
'
'
Function onAutoplayContentReady()
  tubiLog("ContentController.onAutoplayContentReady")
  onPlay()
  if m.detailScreen <> invalid then
    m.detailScreen.unobserveField("content")
  end if
End Function


'''''''''''''''''''''
' showDetailScreen
'
'
Function showDetailScreen(content)
  m.detailScreen = CreateObject("roSGNode", "DetailScreen")
  if m.top.deepLinkContent <> invalid
    m.detailScreen.deepLinkHandled = false
    m.top.deepLinkContent = invalid
  else
    m.detailScreen.deepLinkHandled = true
  end if

  m.detailScreen.shortContent = content
  m.detailScreen.observeField("playSelected", "onPlay")
  m.detailScreen.observeField("resumeSelected", "onResume")
  m.detailScreen.observeField("watchTrailerSelected", "onWatchTrailer")
  m.detailScreen.observeField("episodeListSelected", "onEpisodeList")
  m.detailScreen.observeField("signInSelected", "onSignInSelected")
  m.detailScreen.observeField("addToQueueSelected", "onHistoryQueueChange")
  m.detailScreen.observeField("removeFromQueueSelected", "onHistoryQueueChange")
  m.detailScreen.observeField("removeFromHistorySelected", "onHistoryQueueChange")
  m.detailScreen.observeField("backgroundUriList", "onDetailBackgroundChange")
  m.detailScreen.observeField("itemFailed", "onDetailItemFailed")
  m.detailScreen.signedIn = (m.authTask.authInfo <> invalid)
  pushScreen(m.detailScreen)
End Function


'''''''''''''''''''''
' onGridBackgroundChange
'
'
Function onGridBackgroundChange()
  TubiLog("ContentController.onGridBackgroundChange")
  m.backgroundGroup.backgroundUriList = m.categoryScreen.backgroundUriList
  m.backgroundGroup.newBackgroundType = "grid"
End Function


'''''''''''''''''''''
' onDetailBackgrounChange
'
'
Function onDetailBackgroundChange()
  TubiLog("ContentController.onDetailBackgroundChange")
  m.backgroundGroup.backgroundUriList = m.detailScreen.backgroundUriList
  m.backgroundGroup.newBackgroundType = "details"
End Function


'''''''''''''''''''''
' onEpisodeBackgroundChange
'
'
Function onEpisodeBackgroundChange()
  TubiLog("ContentController.onEpisodeBackgroundChange")
  m.backgroundGroup.backgroundUriList = m.episodesScreen.backgroundUriList
  m.backgroundGroup.newBackgroundType = "grid"
End Function


Function onSearchBackgroundChange()
  TubiLog("ContentController.onSearchBackgroundChange")
  m.backgroundGroup.backgroundUriList = m.searchScreen.backgroundUriList
  m.backgroundGroup.newBackgroundType = "grid"
End Function

'''''''''''''''''''''''
' onDetailItemFailed
'
' Handle a detail screen failure to fetch detailed metadata.  This could be due
' to a title becoming unavailable, or a problem with a deep link.
Function onDetailItemFailed()
  tubiLog("ContentController.onDetailItemFailed")
  popScreen()

  ' If a deep-link occurred, we skipped category screen creation so create it here
  if currentScreen() = invalid then
    startOnNow()
  end if
End Function
