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
  m.metadataFetchTaskDTO = MetadataFetchTaskDTO()

  m.top.observeFieldScoped("focusedChild", "onComponentFocus")
  m.top.observeField("reloadUserCategoriesResponse", "onReloadUserCategoriesResponse")

  ' Set up global services
  m.metadataFetchTask = m.top.findNode("MetadataFetchTask")
  m.global.addField("metadataFetchTask", "node", false)
  m.global.metadataFetchTask = m.metadataFetchTask

  m.trackingLoggingTask = m.top.findNode("TrackingLoggingTask")
  m.global.addField("trackingLoggingTask", "node", false)
  m.global.trackingLoggingTask = m.trackingLoggingTask
  
  m.background = m.top.findNode("ContentBackground")
  m.background.color = m.constants.ui.colors.backgroundColor

  m.contentGroup = m.top.findNode("ContentGroup")

  m.backgroundGroup = m.top.findNode("BackgroundGroup")
  m.logo = m.top.findNode("tubiLogo")
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

  m.top.observeFieldScoped("deepLinkTrigger", "onDeepLinkContentReceived")
  m.deepLinkEvaluated = false  'indicates if the contentController has recognized that we entered from a deeplink or not

  m.logOutTask = m.top.findNode("LogOutTask")

  m.enteredFromDeepLink = false 'used to determine back button behavior in screen stack

  m.screenStack = m.top.findNode("ScreenStack")
  m.screenStack.observeFieldScoped("isEmpty", "onScreenStackEmpty")
  m.screenStack.observeFieldScoped("current", "onScreenChange")

  ' the screen cache holds the top level screens in memory so they are not recreated and reloaded unecessarily
  m.screenCache = {}

  m.SideNav = m.top.findNode("SideNav")
  initSideNav()

  m.videoPlayer = m.top.findNode("VideoPlayer")
  m.videoPlayer.observeFieldScoped("visible", "onVideoPlayerVisibleChange")
  
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


Function displayExitModule()
  showExitAppModal("onExitAppModalButtonSelected")
  m.trackingLoggingTask.trackEvent = {
    type: "dialog"
    values: {
      dialog_type: "INFORMATION"   'DialogType enum
      pageOneof: m.Tracking.getAnalyticsPage("home_page", {})
    }
  }
End Function


'''''''''''''''''''''''
' onKeyEvent
'
' Back pressed on detail screen should close it
Function onKeyEvent(key As String, press As Boolean)
  tubiLog("ContentController.onKeyEvent key = " + key)
  if m.lastUserActivity <> invalid
    m.lastUserActivity = Uptime(0)
  end if
  if press then
    ' for autohide support, bring the UI back on any keypress
    if m.screenStack.opacity < 1.0 and type(unAutohide) = "Function"
      unAutohide()
      return true
    else if key = "back"
      if m.enteredFromDeepLink = true
        if m.screenStack.getChildCount() > 1
          popScreen(true)
        else
          ' remove the last screen, probably detail screen,
          ' this should trigger a restart of the app via onScreenStackEmpty()
          popScreen(false)
          m.enteredFromDeepLink = false
        end if
      else if m.SideNav.opened = false
        if m.SideNav.visible = true
          displayNavMenu(true)
        else if m.screenStack.getChildCount() > 1
          popScreen()
          topScreen = currentScreen()
          sideNavId = m.constants.ui.screenIdToSideNavId[topScreen.id]
          if sideNavId <> invalid
            focusSideNavOption(sideNavId)
          end if
        end if
      else if m.SideNav.opened = true
        if m.screenStack.getChildCount() > 1
          '//Most likely this condition only happens when user is on the homescreen
          '//::TODO::SIDENAV - add the condition when the count() = 1 but the screen is not the homescreen. 
          '//     Show display homescreen. This happens for root activation screen.
          popScreen()
          topScreen = currentScreen()
          sideNavId = m.constants.ui.screenIdToSideNavId[topScreen.id]
          if sideNavId <> invalid
            focusSideNavOption(sideNavId)
            m.SideNav.setFocus(true)
          else 
            hideNavMenu(false)
          end if
        else
          displayExitModule()
        end if
      end if
      ' Always consume back button, otherwise it will cause the app to exit
      return true
    else 
      '//react to the left/right/up/down keys
      bReacted = false
      if key = "left" and m.screenStack.isInFocusChain() = true
        if m.sideNav.visible = true
          '//The LEFT Key has been pressed, now display menu and focus on menu
          displayNavMenu(true)
          bReacted = true
        end if
      else if (key = "right" or key = "left") and isSideNavActive() = true
        '//The RIGHT Key has been pressed, now hide the menu
        hideNavMenu(true)
        bReacted = true
      end if
      return bReacted
    end if
  end if
  return false
End Function

Function onComponentFocus()
  tubiLog("ContentController.onComponentFocus")
  if m.top.isInFocusChain() and m.top.hasFocus()
    if m.videoPlayer.visible = true
      m.videoPlayer.setFocus(true)
    else if m.SideNav.opened = true
      displayNavMenu()
    else if currentScreen() <> invalid
      currentScreen().setFocus(true)
    end if
  end if
End Function

Function onVideoPlayerVisibleChange()
  if m.videoPlayer.visible = true
    m.SideNav.visible = false
    m.logo.visible = false
  else
    m.SideNav.visible = true
    m.logo.visible = true
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

        contentId = 0
        if m.videoPlayer.content <> invalid and m.videoPlayer.content.id <> invalid and m.videoPlayer.content.id <> ""
          contentId = m.videoPlayer.content.id.toInt()
        end if
        m.trackingLoggingTask.trackEvent = {
          type: "dialog"
          values: {
            dialog_type: "INFORMATION"   'DialogType enum
            pageOneof: m.Tracking.getAnalyticsPage("video_page", {video_id: contentId})
          }
        }
      end if
    else if (now - m.lastUserActivity - m.constants.timers.stillWatchingTimeout) > m.constants.timers.stillWatchingDismissTimeout
      closeInactivityModal()
      if shouldStopOnStillWatchingTimeout() = true
        returnToDetailScreenFromVideo()
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
End Function


Function onInactivityButton()
  tubiLog("ContentController.onInactivityButton")
  button = m.inactivityModal.buttonSelected
  closeInactivityModal()
  if button = 0
    m.videoPlayer.control = "resume"
  else
    returnToDetailScreenFromVideo()
  end if
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
    if m.SideNav.opened = true
      m.SideNav.setFocus(true)
    else if focusedScreen <> invalid
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
  if m.autohideTimer.fadeTime <> invalid
    fadeTime = m.autohideTimer.fadeTime
  end if

  m.autohideAnimation = fade(m.screenStack, "out", fadeTime)

  if m.autohideTimer.focusVideo = invalid or m.autohideTimer.focusVideo = true
    'the user has entered the video player auto initialize experience
    m.videoPlayer.setFocus(true)
    m.videoPlayer.observeFieldScoped("backButtonPressed", "unAutohide")
    m.videoPlayer.showTransport = true
  else
    m.top.setFocus(true)  'key presses go to the screen stack
  end if
End Function


Function unAutohide()
  tubiLog("ContentController.unAutohide")
  if m.autohideAnimation <> invalid then m.autohideAnimation.control = "stop"

  m.screenStack.visible = true
  m.autohideAnimation = fade(m.screenStack, "in", 0.5)
  currentScreen().setFocus(true)
  m.videoPlayer.enableAds = false
  m.videoPlayer.showTransport = false
End Function


'''''''''''''''''''''''''
' startUserExperience
'
' Only once we have a metadata task ready AND the user's login status
' will we launch the UI
Function startUserExperience()
  tubiLog("ContentController.startUserExperience")
  if m.authInfoReceived and m.deepLinkEvaluated then
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
      m.enteredFromDeepLink = true
      m.contentGroup.visible = true
      showDetailScreen(m.top.deepLinkContent)
    else
      startChannel()
    end if
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
      
    setDirtyUserCategories(categoryId)
  end if
End Function


''''''''''''''''''''''''''''
' setDirtyUserCategories
'
' if one of the user categories is showing, reload it
Function setDirtyUserCategories(categoryId)
  tubiLog("ContentController.setDirtyUserCategories")

  if categoryId <> invalid
    homeScreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
    if homeScreen <> invalid
      '// this will get the homescreen to display a spinner
      homeScreen.reloadingContent = true  
    end if

    'this will be an auth request if the user is logged in
    'auth request creation happens in metadataFetchTask
    'auth request will add the userId param
    reqName = m.constants.reqNames.getCategory
    m.global.metadataFetchTask.request = m.metadataFetchTaskDTO.createRequest(categoryId, m.top, "reloadUserCategoriesResponse", reqName)

  end if
End Function

Function onReloadUserCategoriesResponse(msg)
  handledRequest = msg.getData()
  homeScreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
  if homeScreen <> invalid
      homeScreen.reloadUserCategoriesResponse = handledRequest  
  end if
  categoryListScreen = getFromScreenCache(m.constants.ui.screenIds.categoryListScreen)
  if categoryListScreen <> invalid
      categoryListScreen.reloadUserCategoriesResponse = handledRequest  
  end if
  refreshStackedUserScreen(handledRequest.id)
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
  for i=0 to m.screenStack.getChildCount()-1
    screen = m.screenStack.getChild(i)
    if screen.subType() = "DetailScreen"
      populateDetailScreen(screen, screen.content, true)
    end if
  end for
End Function

Function refreshStackedUserScreen(sScreenID)
  ' Tell the screen associated with the passed ID to refresh the next time is is on screen by setting the validUntil variable to 0 
  for i=0 to m.screenStack.getChildCount()-1
    screen = m.screenStack.getChild(i)
    if screen.content <> invalid and screen.content.getChildCount() > 0 and screen.content.getChild(0).id  = sScreenID
      screen.content.getChild(0).validUntil = 0
    end if
  end for
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


Function startChannel()
  tubiLog("ContentController.startChannel")
  m.contentGroup.visible = true
  m.appLoadStopwatch.mark()
  showHomeScreen(m.constants, m.global.authInfo)
  focusSideNavOption(m.constants.ui.sideNavIds.home)
End Function


' a setter for the screen cache - can overwrite screens in the cache if the passed in screen has
' the same id as a screen already existing in the screen cache
'
' @screen: roSGNode, a screen node
' returns true or false depending if the screen was successfully set
Function setInScreenCache(screen)
  if screen <> invalid and screen.id <> invalid and m.constants.ui.cacheableScreenIds[screen.id] = true
    m.screenCache[screen.id] = screen
    return true
  end if
  return false
End Function


' a getter for the screen cache - getting does not remove the screen from the cache
'
' @screenId: string, the id of the screen that is to be retrieved
' returns the screen node or invalid if no screens were found with the passed in id
Function getFromScreenCache(screenId)
  if type(screenId) = "String" or type(screenId) = "roString"
    return m.screenCache[screenId] 
  end if
  return invalid
End Function

' This will tell the screen to update its content the next time the screen is displayed 
' @sID: string, the ID of the screen whose content should be marked to be refreshed
Function setContentToRefresh(sID)
  screen = getFromScreenCache(sID)
  if screen <> invalid
    if screen.content <> invalid and screen.content.validUntil <> invalid
      screen.content.validUntil = 0
      return true
    end if
  end if
  return false
End Function 

Function displayNavMenu(shouldTrackComponentInteraction = true)
  bSideNavOpened = m.SideNav.opened
  m.SideNav.setFocus(true)
  if bSideNavOpened = false
    m.SideNav.opened = true
    if m.nOriginalSideNavX = invalid
      m.nOriginalSideNavX = m.SideNav.translation[0] 
    end if 
    if m.nOriginalScreenStackX = invalid
      m.nOriginalScreenStackX = m.ScreenStack.translation[0] 
    end if

    slideTo(m.SideNav, [0, m.SideNav.translation[1]], .2)
    slideTo(m.ScreenStack, [m.nOriginalScreenStackX + m.SideNav.width, m.ScreenStack.translation[1]], .2)

    topScreen = currentScreen()
    if topScreen <> invalid
      topScreen.enabled = false

      if shouldTrackComponentInteraction = true
        interactionEvent = getSideNavInteractionEvent(topScreen, m.Tracking, "on")
        m.trackingLoggingTask.trackEvent = interactionEvent
      end if
    end if
  end if
End Function


Function hideNavMenu(shouldTrackComponentInteraction = true)
  if m.SideNav.opened = true
    m.SideNav.opened = false 
    focusCurrentScreen() '//This will set the current focus back to the screenstack items

    slideTo(m.SideNav, [m.nOriginalSideNavX, m.SideNav.translation[1]], .3)
    slideTo(m.ScreenStack, [m.nOriginalScreenStackX, m.ScreenStack.translation[1]], .3)

    topScreen = currentScreen()
    if topScreen <> invalid
      topScreen.enabled = true

      'set up analytics for unfocusing side nav component
      pageType = ""
      pageValues = {}
      if topScreen.trackingPageInfo <> invalid
        pageType = topScreen.trackingPageInfo.pageType
        pageValues = topScreen.trackingPageInfo.pageValues
      end if

      if shouldTrackComponentInteraction = true
        interactionEvent = getSideNavInteractionEvent(topScreen, m.Tracking, "off")
        m.trackingLoggingTask.trackEvent = interactionEvent
      end if
    end if
  end if
End Function


' Callback for when a navigateWithinPageInfo has been updated - sends the navigate_within_page event
Function onNavigateWithinPageInfoChange(msg)
  navigateWithinPageInfo = msg.getData()
  m.trackingLoggingTask.trackEvent = {
    type: "navigate_within_page"
    values: navigateWithinPageInfo
  }
End Function


'''''''''''''''''''''
' onDeepLinkContentReceived
'
' Show the detail screen for the content id that was deeplinked to
Function onDeepLinkContentReceived()
  tubiLog("onDeepLinkContentReceived")
  m.deepLinkEvaluated = true
  startUserExperience()
End Function


Function homeScreenBackgroundUpdated(msg)
  tubiLog("ContentController.homeScreenBackgroundUpdated")
  homeScreen = msg.getRoSGNode()
  if homeScreen <> invalid and currentScreen() <> invalid and currentScreen().isSubType("HomeScreen")
    m.backgroundGroup.backgroundInfo = {
      type: getBackgroundtype(homeScreen.backgroundUriList)
      uriList: homeScreen.backgroundUriList
    }
  end if
End Function


Function onEpisodeBackgroundChange(msg)
  TubiLog("ContentController.onEpisodeBackgroundChange")
  episodeScreen = msg.getRoSGNode()
  m.backgroundGroup.backgroundInfo = {
    type: getBackgroundtype(episodeScreen.backgroundUriList)
    uriList: episodeScreen.backgroundUriList
  }
End Function


Function onSearchBackgroundChange(msg)
  TubiLog("ContentController.onSearchBackgroundChange")
  searchScreen = msg.getRoSGNode()
  m.backgroundGroup.backgroundInfo = {
    type: getBackgroundtype(searchScreen.backgroundUriList)
    uriList: searchScreen.backgroundUriList
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



' onFirstPosterLoaded
'
' Info that the first poster in the first category has bubbled all the way up.
' Fire off a log to a server so we can track how long it took since the app was started, ie. startChannel() was called
Function onFirstPosterLoaded()
  loadTime = m.appLoadStopwatch.TotalMilliseconds()

  'send tracking event for initial home page load
  m.global.trackingLoggingTask.trackEvent = {
    type: "page_load"
    values: {
      pageOneof: m.Tracking.getAnalyticsPage("home_page", {})  'a valid page type (see PageLoadEvent in events.protos)
      load_time: loadTime
      status: "SUCCESS"  'ActionStatus enum
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
  if backgroundUriList <> invalid
    if backgroundUriList[0] = m.defaultBackgroundUri
      backgroundType = m.constants.ui.backgroundTypes.fullScreen
    else
      backgroundType = m.constants.ui.backgroundTypes.topRight
    end if
  end if
  return backgroundType
End Function


Function initVideoTracking()
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
  ' Youbora events
  if m.constants.thirdParty.youbora.enabled = true
    youboraConfig = m.constants.thirdParty.youbora.config

    if m.videoPlayer.content <> invalid
      youboraConfig["extraparam.1"] = m.videoPlayer.content.id
      youboraConfig["content.id"] = m.videoplayer.content.id
      youboraConfig.drm = m.videoplayer.content.drmType
      youboraConfig.tvShow = Mid(m.videoplayer.content.parentId, 2)
    end if

    if m.global.authInfo <> invalid
      youboraConfig.username = m.global.authInfo.userId
    end if

    youboraConfig["content.transactionCode"] = m.constants.deviceInfo.deviceId
    youboraConfig["device.model"] = m.constants.deviceInfo.model
    youboraConfig["app.releaseVersion"] = m.constants.settings.version

    m.youboraTask.options = youboraConfig
    m.youboraTask.event = {handler:"play"}
  end if
End Function


Function videoTrackingStop()
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