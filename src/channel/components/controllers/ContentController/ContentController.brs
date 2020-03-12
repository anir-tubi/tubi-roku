Function init()
  tubiLog(" ")
  tubiLog("Init Scenegraph----------------")
  m._ = rodash()

  m.constants = m.global.constants
  
  ' initiate GeneralTaskHelper by passing caller context
  ' DO NOT overwrite m variable methods/properties which belongs to GeneralTaskHelper
  'GeneralTaskHelper(m)
  ' initiate GeneralTask
  'm.generalTask = CreateObject("roSGNode", "GeneralTask")
  'initiateHomeData()

  Request = TubiRequest()
  Auth = TubiAuth(m.constants, Request)
  m.NodeHelpers = TubiNodeHelpers()
  m.Bookmarks = TubiBookmarks(Request, Auth, m.constants, m.NodeHelpers)
  m.Tracking = TubiTracking(m.constants, Request, Auth)
  m.metadataFetchTaskDTO = MetadataFetchTaskDTO()

  ' initialize states needed for various parts of kids mode
  m.kidsModeEnabled = false  'is the kids mode UI visible
  m.kidsModeFeatureOn = false   'Should the kids Mode feature be made available for the user to interact with
  if m.constants.deviceInfo.countryCode <> invalid and (UCase(m.constants.deviceInfo.countryCode) = "US" or UCase(m.constants.deviceInfo.countryCode) = "CA")
    m.kidsModeFeatureOn = true
  end if

  m.top.observeFieldScoped("focusedChild", "onComponentFocus")
  m.top.observeFieldScoped("reloadUserCategoriesResponse", "onReloadUserCategoriesResponse")

  m.deeplinkContent = invalid
  m.startupArgsReceived = false
  m.top.observeFieldScoped("startupArgs", "onStartupArgs")
  m.top.observeFieldScoped("roInputInfo", "onInputInfoReceived")

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
  m.logoGroup = m.top.findNode("logoGroup")
  m.logo = m.logoGroup.findNode("tubiLogo")
  m.logoKids = m.logoGroup.findNode("tubiKidsLogo")
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
  m.global.observeFieldScoped("authInfo", "onAuthInfoChanged")
  m.authInfo = m.global.authInfo '//Local version of m.global.authInfo. This way we are sure we always have access to authInfo

  m.authInfoReceived = false    'is the auth info returned from the registry
  m.authInfoRefreshed = true    'is the auth info refreshed after receiving a deeplink with a refresh token
  m.authTask = CreateObject("roSGNode", "AuthTask")
  m.authTask.observeFieldScoped("authInfo", "onAuthInfoReceived")
  m.authTask.functionName = "execInitializeUserData"
  m.authTask.control = "RUN"

  ' history updates during video playback
  m.updateHistoryTask = CreateObject("roSGNode", "AuthTask")
  m.updateHistoryTask.functionName = "updateHistory"

  ' For queue and history management from detail screen
  m.userTask = CreateObject("roSGNode", "AuthTask")

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

  ' holds state so we don't fire the app load beacon more than once
  m.appLoadedBeaconFired = false

  initVideoTracking()
  m.trackingLoggingTask.trackEvent = {
    trackType: "startApp"
  }
End Function


' initiateHomeData
' constructs requestType, url, params and responseType for api request and invokes makeTaskRequest helper
Function initiateHomeData()

  requestType = m.constants.api.requestTypes.homeScreen
  url = "https://uapi.adrise.tv/matrix/homescreen"
  options = {
    params: {
      "user_id" : "46466412",
      "device_id": "2366ec6e-7e5e-58e4-96e1-da33e5fb0f73",
      "app_id" : "tubitv",
      "includeempty" : "true",
      "isKidsMode" : "false",
      "expand": "1",
      "limit": "12",
      "platform": "roku"
    },
    method: "GET"  
  }
  responseType = "node"
  
  ' all params are mandatory
  m.makeTaskRequest(requestType, url, options, m.generalTask, onHomeSuccessResponse, onHomeErrorResponse, responseType)

End Function


Function displayExitModal(trackingPageInfo)
  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: "EXIT"   'DialogType enum
      pageOneof: m.Tracking.getAnalyticsPage(trackingPageInfo.pageType, trackingPageInfo.pageValues)
      dialog_action: "SHOW"
      dialog_sub_type: ""
    }
  }
  showExitAppModal(dialogEvent, m.trackingLoggingTask, onExitAppModalButtonSelected)
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
        m.enteredFromDeepLink = false
      end if

      if m.SideNav.opened = false
        if m.SideNav.visible = true
          displayNavMenu(true)
        else if m.screenStack.getChildCount() > 1
          popScreen(true)
          topScreen = currentScreen()
          sideNavId = m.constants.ui.screenIdToSideNavId[topScreen.id]
          if sideNavId <> invalid
            focusSideNavOption(sideNavId)
          end if
        else
          ' remove the last screen, probably detail screen,
          ' this should trigger a restart of the app via onScreenStackEmpty()
          popScreen(false)
          m.deeplinkContent = invalid
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
          topScreen = currentScreen()
          displayExitModal(topScreen.trackingPageInfo)
        end if
      end if
      ' Always consume back button, otherwise it will cause the app to exit
      return true
    else if key = "OK"
      '//ensure this keypress is captured so the default Roku positive audio sound is played.
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
    m.logoGroup.visible = false
  else
    m.SideNav.visible = true
    m.logoGroup.visible = true
  end if 
End Function


Function onInactivityTimer()
  now = Uptime(0)
  ' don't do anything in this function for now
  ' but leave inactivity timer functionality in case it's needed in the future.
End Function


''''''''''''''''''''''
' onExitAppModalButtonSelected
'
' handles the response of a user who has been presented an exit app modal
Function onExitAppModalButtonSelected()
  m.top.exitApp = true
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
' We need to gather information from various places. As callbacks fire when these different infos arrive,
' they all set some state on m and call startUserExperience(). When all the information has arrived, as verified
' by the first checks in the function, then the function performs it's functionality to start the channel. 
'
' @registryKidsMode: boolean, the persisted value for kids mode set in the registry
Function startUserExperience(registryKidsMode = false)
  tubiLog("ContentController.startUserExperience")

  if m.authInfoReceived <> true
    ' checks if the initial auth info has been pulled from the registry
  else if m.startupArgsReceived <> true
    ' checks if the startupArgs have been received from main thread
  else if m.authInfoRefreshed <> true
    ' checks if auth info has been received after a deeplink from external tubi device (iOS) supplied a refresh token
    ' if m.authInfoReceived is false, it means that a refresh token has been supplied
    if m.global.authInfo <> invalid
      ' we only need to refresh is the user is currently signed out
      m.authTask = CreateObject("roSGNode", "AuthTask")
      m.authTask.observeFieldScoped("authInfoRefreshed", "onAuthInfoRefreshed")
      m.authTask.externalAuthInfo = getExternalAuthInfoFromStartupArgs(m.top.startUpArgs)
      m.authTask.functionName = "execRefreshAuthInfo"
      m.authTask.control = "RUN"
    else
      ' onAuthInfoRefreshed will update the value of m.authInfoRefreshed to true and re-call startUserExperience()
      ' which is necessary to proceed past this step if m.authInfoRefreshed was set to false, but the user was already signed in.
      onAuthInfoRefreshed()
    end if
  else
    ' All of the above checked values are true, so we are ready to start the channel UI
    m.trackingLoggingTask.trackEvent = {
      type: "active"
      values: {}
    }

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
    if m.enteredFromDeepLink = true then
      tubiLog("ContentController detected deep link request")
      ' we were asked to deep link into a content item. Go to it
      ' whether we were logged in or not.
      m.contentGroup.visible = true
      enableKidsModeUI(false) '//when deeplinking, exit out of kids mode because we cannot guarantee that the video is kid appropriate so the UI should not make the user think we're still in kids mode
      showDetailScreen(m.deeplinkContent)
    else
      startChannel(registryKidsMode)
      showUpgradeModal(m.constants.showUpgradeAlert, m.Tracking, m.trackingLoggingTask) 'show as necessary
    end if
  end if
End Function


' is triggered when the args that are passed to main, are passed into the SG thread to the contentController.
' this is one of the pre-requisites to starting the SG user experience.
Function onStartupArgs()
  m.deeplinkContent = createDeeplinkContentFromStartupArgs(m.top.startUpArgs)
  externalAuthInfo = getExternalAuthInfoFromStartupArgs(m.top.startUpArgs)

  if externalAuthInfo <> invalid
    m.authInfoRefreshed = false
  end if

  if m.deeplinkContent <> invalid
    m.enteredFromDeepLink = true
  end if

  m.startupArgsReceived = true
  startUserExperience()
End Function


Function onInputInfoReceived()
  if m.top.roInputInfo <> invalid
    inputInfo = m.top.roInputInfo
    
    if inputInfo.type = "deeplink"
      kidsModeAtStart = false
      if m.kidsModeEnabled = true
        kidsModeAtStart = true
      end if

      if kidsModeAtStart = true
        'turn off kids mode for input deeplinks (ie. voice commands)
        enableKidsModeUI(false)
      end if

      resetSideNav(false)
      m.deeplinkContent = createDeeplinkContentFromStartupArgs(inputInfo)
      stopVideoContent(true)
      showDetailScreen(m.deeplinkContent)

      if kidsModeAtStart = true
        ' remove all screens except the top most details screen if in kids mode so,
        ' that when backing out of the details screen, the home screen will be re-populated as expected
        shrinkScreenStack(1)
        emptyScreenCache()
      end if
    else if inputInfo.type = "transport"
      if m.videoPlayer.visible
        if (m.UpNextScreen = invalid or (m.UpNextScreen <> invalid and m.UpNextScreen.visible = false))
          m.videoPlayer.transportVoiceRequest = inputInfo
        end if
      end if
    end if
  end if
End Function


' Parse launch arguments for any deep linking.
' Returns a DeeplinkContentNode or invalid
' @args: assocArray, the args passed to main() at startup
'
' Feed: http://cms.adrise.com/roku/partnerSearch/xml
'
' ARGUMENTS TO ROKU MAIN():
'
' Non-deep link args and example values:
'   splashTime                      - "1600"
'   instant_on_run_mode             - "foreground"
'   lastExitOrTerminationReason     - "EXIT_UNKNOWN"
'   source                          - 'meta-search', 'external-control'
'
' Deep link args:
'   contentId    - string identifier
'   entry        - 'banner' or omitted for search source
'   mediaType    - "season", "series", "episode", "movie", "shortform", and "live"
'   entry        - string, custom parameter, used for tracking the source of deeplinks, passed to referred analytics events
'   deviceId     - string, custome paramater, the device id of the device sending the deeplink (used when mobile "casts" to roku)
'   resumeTime   - integer, custome paramater, the position from which a deeplink should resume (used when mobile "casts" to roku)
'   refreshToken - string, custome paramater, a token that can be used to refresh the auth token.
'                  Is used to transfer login info from a "casting" device to roku (used when mobile "casts" to roku)
'   userId       - integer, custome paramater, the user id of the user sending the deeplink (used when mobile "casts" to roku)
'
' deeplinks from iOS look like:
' http://192.168.20.31:8060/launch/41468?deviceId=E7E674A4%2D25DD%2D4B7A%2DBC67%2DB9AD1BAC7CC5&mediaType=movie&contentID=342067&resumeTime=0&userId=0&entry=iphone
' http://192.168.20.31:8060/launch/41468?mediaType=episode&entry=iphone&deviceId=E7E674A4%2D25DD%2D4B7A%2DBC67%2DB9AD1BAC7CC5&contentID=456881&userId=0&resumeTime=0
Function createDeeplinkContentFromStartupArgs(args)
  'handle/set up any deep linking that may have occurred
  if (args.contentId <> invalid)
    tubiLog("Deep Link detected for content id " + args.contentId)

    content = CreateObject("roSGNode", "DeeplinkContentNode")
    content.id = args.contentId

    ' default deep link source is no-source
    if args.source = invalid or m.constants.deeplinks[args.source] = invalid
      content.source = "no-source"
    else
      content.source = m.constants.deeplinks[args.source]  
    end if

    ' if there is a parameter called entry with a value, that is the source of the deep link
    ' typically entry = banner from the Roku banner ads ('entry' is a custom parameter)
    ' deep link urls with entry source should look like:
    ' contentID=18267&entry=banner
    if args.entry <> invalid
      content.source = args.entry
    end if

    ' the device id of the device deeplinking to roku. Might be an iOS or android device that is "casting" to roku.
    if args.deviceId <> invalid and args.deviceId.unescape() <> ""
      content.sourceDeviceId = args.deviceId.unescape()
    end if

    ' set up the resume time if we are deeplinking to a specific point in the video
    if args.resumeTime <> invalid
      content.nowPos = args.resumeTime.ToInt()
    end if

    ' if deep linked from Roku search it's possible that we are deep linking to a series, instead of actual video content
    ' deep links from search for series should like:
    ' contentID=335&mediaType=series
    '
    ' See full list of mediaType at https://sdkdocs.roku.com/display/sdkdoc/External+Control+Guide
    if args.mediaType = "series"
      content.type = "series"
      content.deeplinkType = "series"
    else if args.mediaType = "season"
      content.type = "series"
      content.deeplinkType = "season"
    else if args.mediaType = "movie"
      content.type = "video"
      content.deeplinkType = "movie"
    else if args.mediaType = "episode"
      content.type = "video"
      content.deeplinkType = "episode"
    end if

    ' remove any 0s that might be prepended to the content id
    if content.source = "search"
      prepend = "0"
      while prepend = "0"
        prepend = content.id
        if prepend = "0"
          length = content.id.len()
          content.id = content.id.right(length - 1)
        end if
      end while
    end if

    'see tubitv.atlassian.net/wiki/display/EC/Referrals
    content.medium = "partnership"
    if args.medium <> invalid
      content.medium = args.medium
    end if

    'see tubitv.atlassian.net/wiki/display/EC/Referrals
    content.campaign = "default-campaign"
    if args.campaign <> invalid
      content.campaign = args.campaign
    end if

    return content
  else
    return invalid
  end if
End Function


'@args: assocArray, the startupArgs passed into main when the channel starts
Function getExternalAuthInfoFromStartupArgs(args)
  ' deeplinks coming from ios or android devices need to be authenticated
  externalAuthInfo = invalid

  if args.refreshToken <> invalid and args.userId <> invalid and args.deviceId <> invalid and args.entry <> invalid
    if args.refreshToken.unescape() <> "" and args.userId.unescape() <> "" and args.deviceId.unescape() <> ""
      if args.entry = "iphone" or args.entry = "ipad" or args.entry = "ios" or args.entry = "android"

        externalAuthInfo = {
          platform: args.entry
          externalDeviceId: args.deviceId.unescape()
          externalRefreshToken: args.refreshToken.unescape()
          userId: args.userId.unescape()
        }
      end if
    end if
  end if

  return externalAuthInfo
End Function


' auth info has been added/refreshed after a deeplink from a "casting" device that contained a refreshToken
Function onAuthInfoRefreshed()
  tubiLog("ContentController.onAuthInfoRefreshed")
  if m.authTask <> invalid
    if m.authTask.authInfo <> invalid
      m.global.authInfo = m.authTask.authInfoRefreshed
    end if
    m.authTask.unobserveFieldScoped("authInfo")
    m.authTask = invalid
  end if
  m.authInfoRefreshed = true
  startUserExperience()
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

    'this will be an auth request if the user is logged in
    'auth request creation happens in metadataFetchTask
    'auth request will add the userId param
    reqName = m.constants.reqNames.getCategory
    m.metadataFetchTask.request = m.metadataFetchTaskDTO.createRequest(categoryId, m.top, "reloadUserCategoriesResponse", reqName, invalid, shouldKidsModeBeSentToServer())

    '//Apply the movie and TV filters
    optionMovie = {contentMode: m.constants.ui.contentMode.movie}
    m.metadataFetchTask.request = m.metadataFetchTaskDTO.createRequest(categoryId, m.top, "reloadMovieUserCategoriesResponse", reqName, invalid, shouldKidsModeBeSentToServer(), optionMovie)
    optionTV = {contentMode: m.constants.ui.contentMode.tv}
    m.metadataFetchTask.request = m.metadataFetchTaskDTO.createRequest(categoryId, m.top, "reloadTVUserCategoriesResponse", reqName, invalid, shouldKidsModeBeSentToServer(), optionTV)
  end if
End Function


Function onReloadUserCategoriesResponse(msg)
  tubiLog("ContentController.onReloadUserCategoriesResponse")
  handledRequest = msg.getData()
  onReloadUserCategoriesInHomeScreen(msg)
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
 
Function saveKidsModeToMemory(bTurnedOn)
  tubiLog("ContentController.saveKidsModeToMemory")
  if m.kidsModeRequest = invalid
    m.kidsModeRequest = CreateObject("roSGNode", "AuthTask")
    m.kidsModeRequest.functionName = "saveKidsModeToMemory"
  end if
  m.kidsModeRequest.isKidsMode = bTurnedOn
  m.kidsModeRequest.control = "RUN"
End Function


' What boolean value should be sent to the backend in terms of kids mode?
Function shouldKidsModeBeSentToServer()
  return m.kidsModeEnabled = true and isKidsModeEnabledByParentalControls() = false
End Function


' enable (or disable) the kids mode UI
Function enableKidsModeUI(bTurnOn = true)
  TubiLog("ContentController.enableKidsModeUI")
  if m.kidsModeFeatureOn = true
    if bTurnOn = true
      theme = m.constants.ui.themes.kidsMode
      m.global.theme = theme
    else
      theme = m.constants.ui.themes.default
      m.global.theme = theme
    end if
    m.kidsModeEnabled = bTurnOn 
    m.backgroundGroup.kidsMode = bTurnOn 
    setKidsModeInSideNav(bTurnOn)
    tellScreensIfKidsModeBeSentToServer()
    m.videoPlayer.kidsMode = bTurnOn

    '//display proper logo
    if bTurnOn = true
      m.logoKids.visible = true
      m.logo.visible = false
      m.trackingLoggingTask.analyticsAppMode = "KIDS_MODE"
    else 
      m.logoKids.visible = false
      m.logo.visible = true
      m.trackingLoggingTask.analyticsAppMode = "DEFAULT_MODE"
    end if
  else
    setKidsModeInSideNav(false)
  end if
End Function


' Tell some screens of the kidsMode value. This is to ensure that any calls to the backend are sending the proper kids mode state
' This should be done when a screen is created or when kids mode state changes
' This only needs to be done for screens that are cached and kidsMode is set upon initiatiation of the screen and never anytime else.
Function tellScreensIfKidsModeBeSentToServer()
  bKidsMode = shouldKidsModeBeSentToServer()
  homeScreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
  if homeScreen <> invalid
    homeScreen.shouldKidsModeBeSentToServer = bKidsMode
  end if
  m.videoPlayer.shouldKidsModeBeSentToServer = bKidsMode
End Function


Function isKidsModeEnabledByParentalControls() as Boolean
  tubiLog("ContentController.isKidsModeEnabledByParentalControls")
  bEnabled = false

  if m.global.authInfo <> invalid and m.global.authInfo.parentalrating <> invalid
    if m.global.authInfo.parentalrating < 2
      bEnabled = true
    end if
  end if
  return bEnabled
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
    if screen <> invalid and screen.content <> invalid and screen.content.getChildCount() > 0 and screen.content.getChild(0).id  = sScreenID
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


' @registryKidsMode: boolean, the persisted value for kids mode set in the registry
Function startChannel(registryKidsMode = false)
  tubiLog("ContentController.startChannel")
  m.contentGroup.visible = true
  m.appLoadStopwatch.mark()
  focusSideNavOption(m.constants.ui.sideNavIds.home)
  if isKidsModeEnabledByParentalControls() = true or registryKidsMode = true
    enableKidsModeUI(true)
  else
    enableKidsModeUI(false)
  end if
  showHomeScreen(m.constants, m.global.authInfo)
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


' a deleter for the screen cache - we may need to remove screens from the cache in the case of content loading errors
' returns true if the screen was successfully deleted, otherwise returns false
'
' @screenId: string, the id of the screen that is to be removed
Function deleteFromScreenCache(screenId)
  if type(screenId) = "String" or type(screenId) = "roString"
    return m.screenCache.delete(screenId)
  end if
  return false
End Function


Function emptyScreenCache()
  m.screenCache = {}
  return m.screenCache
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


' Callback for when a navigateWithinPageInfo has been updated - sends the navigate_within_page event
Function onNavigateWithinPageInfoChange(msg)
  navigateWithinPageInfo = msg.getData()
  m.trackingLoggingTask.trackEvent = {
    type: "navigate_within_page"
    values: navigateWithinPageInfo
  }
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

Function displayDefaultBackground()
  TubiLog("ContentController.displayDefaultBackground")
  m.backgroundGroup.backgroundInfo = {
    type: getBackgroundtype([m.defaultBackgroundUri])
    uriList: [m.defaultBackgroundUri]
  }
End Function


' fireAppLoadTimeEvent
'
' Fire off a log to a server so we can track how long it took since the app was started
Function fireAppLoadTimeEvent()

  currentTime = Int(Uptime(0))
  appStartTime = m.top.appStartTime
  loadTime = currentTime - appStartTime
  
  'send tracking event for initial home page load
  m.trackingLoggingTask.trackEvent = {
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


' show an upgrade modal if constants says that we should
Function showUpgradeModal(shouldAlert, trackingLib, trackingTask)
  if shouldAlert = true
    title  = getTranslation("dialog_updateVersion_title")
    message  = getTranslation("dialog_updateVersion_description")
    
    buttons = [getTranslation("dialog_button_close")]

    dialogEvent = {
      type: "dialog"
      values: {
        dialog_type: "UPGRADE"   'DialogType enum
        pageOneof: trackingLib.getAnalyticsPage("home_page", {})
        dialog_action: "SHOW"
        dialog_sub_type: ""
      }
    }
    showSimpleModal(title, message, buttons, dialogEvent, trackingTask)
  end if
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


' fires a beacon which roku uses to determine the app load time only once per session. See:
' https://developer.roku.com/en-gb/docs/developer-program/performance-guide/measuring-channel-performance.md
Function fireAppLoadBeacon()
  if m.appLoadedBeaconFired = false
    m.appLoadedBeaconFired = true
    fireAppLoadTimeEvent()
    m.top.signalBeacon("AppLaunchComplete")
  end if
End Function
