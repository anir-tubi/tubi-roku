Function init()
  tubiLog(" ")
  tubiLog("Init Scenegraph----------------")
  ' save a global reference to the fetch task for nodes to access
  m.metadataFetchTask = m.top.findNode("MetadataFetchTask")
  m.global.addField("metadataFetchTask", "node", false)
  m.global.metadataFetchTask = m.metadataFetchTask

  m.singleRow = true

  m.trackingTask = m.top.findNode("TrackingTask")
  m.global.addField("trackingTask", "node", false)
  m.global.trackingTask = m.trackingTask
  m.trackingTask.observeField("ready", "onTrackingReady")
  m.global.trackingTask.control = "RUN"
  
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
  m.authTask.control = "RUN"

  if m.global.constants.settings.isFBApplicationDetectionOn then
    ' We don't need to know the state of this for our app to proceed, just start it
    m.fbapplicationDetectionTask = m.top.findNode("FBApplicationDetectionTask")
    m.fbapplicationDetectionTask.control = "RUN"
  end if

  m.top.observeField("itemDetail", "onItemDetailChange")
  m.top.observeField("playerInfo", "onPlayerInfo")

  m.logOutTask = m.top.findNode("LogOutTask")

  initScreenStack(m.top.findNode("ScreenStack"))
End Function


'''''''''''''''''''''''''
' onTrackingReady
'
' Only once we have a metadata task ready AND the user's login status
' will we launch the UI
Function onTrackingReady()
  if m.trackingTask.ready = true
    m.trackingTask.unobserveField("ready")
    
    m.trackingTask.trackEvent = {
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
  if m.metadataFetchTask.ready and m.authInfoReceived and m.trackingTask.ready then
    if m.top.itemDetail <> invalid then
      tubiLog("ContentController detected deep link request")
      ' we were asked to deep link into a content item. Go to it
      ' whether we were logged in or not.  Make sure the category
      ' screen is loaded too
      startCategoryScreen()
      m.backgroundGroup.catScreenStart = true
      onItemDetailChange()
      'TODO(Chris): capture the 'back' button when the screen stack is empty so
      ' that we can show the category screen without haveing to preload it here
    else if m.authTask.authInfo = invalid then
      startSignIn()
    else
      startCategoryScreen()
      m.backgroundGroup.catScreenStart = true
      m.categoryScreen.signedIn = true
    end if
  end if
End Function


'''''''''''''''''''''''
' startCategoryScreen
'
' On either app start (if user is signed in) or after the sign in
' flow is complete, create and show the category screen.
Function startCategoryScreen()
  if m.singleRow = true
    m.categoryScreen = CreateObject("roSGNode", "CategoryScreenSingleRow")
  else
    m.categoryScreen = CreateObject("roSGNode", "CategoryScreen")
  end if

  m.categoryScreen.observeField("contentSelected", "onContentSelected")
  m.categoryScreen.observeField("searchSelected", "onSearchSelected")
  m.categoryScreen.observeField("signInSelected", "onSignInSelected")
  m.categoryScreen.observeField("signOutSelected", "onSignOutSelected")
  m.categoryScreen.observeField("aboutSelected", "onAboutSelected")
  m.categoryScreen.observeField("backgroundUriList", "onGridBackgroundChange")
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

  startCategoryScreen()
  m.backgroundGroup.catScreenStart = true  
  if m.SignIn.signedIn or m.SignIn.registered then
    m.categoryScreen.signedIn = true
  end if

  m.SignIn.unobserveField("guestPass")
  m.SignIn.unobserveField("signedIn")
  m.SignIn.unobserveField("registered")
  m.top.removeChild(m.SignIn)
  m.SignIn = invalid
End Function


'''''''''''''''''''''''
' onContentSelected
'
' Show the detail screen for the selected content
Function onContentSelected()
  tubiLog("ContentController.onContentSelected")
  top = currentScreen()
  
  if top <> invalid and top.contentSelected <> invalid then
    showDetailScreen(top.contentSelected)
  end if
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

  startCategoryScreen()
  m.backgroundGroup.catScreenStart = true
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
  m.aboutScreen.observeField("buttonSelected", "onCloseAbout")
  pushModal(m.aboutScreen)
End Function


'''''''''''''''''''
' onCloseAbout
'
' Dismiss the About modal
Function onCloseAbout()
  tubiLog("ContentController.onCloseAbout")
  popScreen()
  m.aboutScreen = invalid
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

    'TODO(Chris): For unauthenticated users, we need to reset any resume 
    ' position that might have been set.  Also, when we come back from
    ' playback, we want to redraw the detail screen to reflect the new
    ' resume position.

    ' Don't give main BRS a reference to the contentNode
    m.top.playContent = content.getFields()
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
    m.top.playContent = content.getFields()
  else
    tubiLog("ERROR: Resume selected but content is invalid")
  end if
End Function



Function onEpisodeList()
  if m.singleRow = true
    m.episodesScreen = CreateObject("roSGNode", "EpisodesScreenSingleRow")
  else
    m.episodesScreen = CreateObject("roSGNode", "EpisodesScreen")
  end if
  
  m.episodesScreen.content = m.detailScreen.content
  m.episodesScreen.observeField("episodeSelected", "onEpisodeSelected")
  m.episodesScreen.observeField("backgroundUriList", "onEpisodeBackgroundChange")

  if m.episodesScreen.content <> invalid and m.episodesScreen.content.id <> invalid
    m.episodesScreen.trackingUri = m.episodesScreen.trackingUri + m.episodesScreen.content.id
  end if
  
  pushScreen(m.episodesScreen)
End Function



Function onEpisodeSelected()
  m.detailScreen.episodeSelection = m.episodesScreen.episodeSelected
  popScreen()
  m.episodesScreen = invalid

  ' Autoplay the selected episode
  onResume()
End Function


'
' Helper to deduce the content, video or episode, to play or resume
Function getDetailScreenContent()
  content = invalid
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
  return content
End Function


'''''''''''''''''''''
' onItemDetailChange
'
' Show the detail screen for the content id
Function onItemDetailChange()
  tubiLog("onItemDetailChange")
  if m.metadataFetchTask.ready and m.authInfoReceived and m.top.itemDetail <> invalid then
    'TODO(Chris): Supplement this content with history & queue status once we have it
    testLog("Deep link contentId = " + m.top.itemDetail.id)
    testLog("Deep link type = " + m.top.itemDetail.type)
    showDetailScreen(m.top.itemDetail)
  end if
End Function


'''''''''''''''''''''
' onPlayerInfo
'
' Is called when the nowPos is updated from the player
Function onPlayerInfo()
  playerInfo = m.top.playerInfo
  tubiLog("onPlayerInfo: nowPos = " + playerInfo.nowPos.toStr())
  if playerInfo.historyId <> invalid and playerInfo.historyId <> "" then
    tubiLog("onPlayerInfo: historyId = " + playerInfo.historyId.toStr())
  end if
  if playerInfo.parentHistoryId <> invalid and playerInfo.parentHistoryId <> "" then
    tubiLog("onPlayerInfo: parentHistoryId = " + playerInfo.parentHistoryId.toStr())
  end if
  content = m.top.playContent

  constants = m.global.constants
  Request = TubiRequest()
  Auth = TubiAuth(constants, Request)
  Bookmarks = TubiBookmarks(Request, Auth, constants)

  'update the nowPos in the global historyIds store
  newHistory = Bookmarks.updateNowPos(content, playerInfo, m.global.historyIds, m.global.historyOrder)
  m.global.historyIds = newHistory.historyIds
  m.global.historyOrder = newHistory.historyOrder
  if m.categoryScreen <> invalid then m.categoryScreen.dirtyUserCategories = true

  if m.detailScreen <> invalid
    m.detailScreen.shortContent = m.detailScreen.shortContent ' force a reload to get nowPos and history id set
  end if

  if playerInfo.result = m.global.constants.player.playerResults.failed then
    showPlayerError(playerInfo.result)
  end if

  'TODO: BRYAN, advance the episode
End Function


'''''''''''''''''''''
' showDetailScreen
'
'
Function showDetailScreen(content)
  m.detailScreen = CreateObject("roSGNode", "DetailScreen")
  m.detailScreen.shortContent = content
  m.detailScreen.observeField("playSelected", "onPlay")
  m.detailScreen.observeField("resumeSelected", "onResume")
  m.detailScreen.observeField("episodeListSelected", "onEpisodeList")
  m.detailScreen.observeField("signInSelected", "onSignInSelected")
  m.detailScreen.observeField("addToQueueSelected", "onHistoryQueueChange")
  m.detailScreen.observeField("removeFromQueueSelected", "onHistoryQueueChange")
  m.detailScreen.observeField("removeFromHistorySelected", "onHistoryQueueChange")
  m.detailScreen.observeField("backgroundUriList", "onDetailBackgroundChange")
  m.detailScreen.signedIn = m.categoryScreen.signedIn
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
