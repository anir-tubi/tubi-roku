Function init()
  tubiLog(" ")
  tubiLog("Init Scenegraph----------------")
  m._ = rodash()
  
  ' sentStartUpEvents variable used for sending active event, hdcp info
  m.sentStartUpEvents = false

  ' TODO Remove sendOnBoardingControlEvent and its references once the OnBoarding experiment is done
  m.sendOnBoardingControlEvent = false
  ' skipLandingScreen variable is used to show/hide the landing screens. This variable is set to true/false based on user loggedin(or not) and lastOnBoardingVisit registry (TubiAuth)
  m.skipLandingScreen = true
  ' skipOnBoardingScreen variable is used to show/hide the onBoarding screens. This variable is set to true/false based on user loggedin(or not) and lastOnBoardingVisit registry (TubiAuth)
  m.skipOnBoardingScreen = true

  m.constants = m.global.constants
  
  generalTask = CreateObject("roSGNode", "GeneralTask")  ' initiate GeneralTask
  ' Initiate GeneralTaskModule by passing caller context.
  ' Calling GeneralTaskModule() will append methods to the local m.
  ' DO NOT overwrite m variable methods/properties which belongs to GeneralTaskModule.
  GeneralTaskModule(m, generalTask)

  '//When ContentController initializes, clear all trandslations in case this is contained in a remote component. 
  clearTranslations()

  Request = TubiRequest(m.constants.settings.mode)
  Auth = TubiAuth(m.constants, Request)
  m.NodeHelpers = TubiNodeHelpers()
  m.Bookmarks = TubiBookmarks(Request, Auth, m.constants, m.NodeHelpers)
  m.Tracking = TubiTracking(m.constants, Request, Auth)
  m.metadataFetchTaskDTO = MetadataFetchTaskDTO()
  m.cmsApi = CmsApi(m.constants, Request, Auth)

  ' initialize states needed for various parts of kids mode
  m.kidsModeEnabled = false  'is the kids mode UI visible
  m.kidsModeFeatureOn = false   'Should the kids Mode feature be made available for the user to interact with
  if m.constants.deviceInfo.countryCode <> invalid and (UCase(m.constants.deviceInfo.countryCode) = "US" or UCase(m.constants.deviceInfo.countryCode) = "CA")
    m.kidsModeFeatureOn = true
  end if
  m.latinoModeEnabled = false

  m.top.observeFieldScoped("focusedChild", "onComponentFocus")
  m.top.observeFieldScoped("reloadUserCategoriesResponse", "onReloadUserCategoriesResponse")

  m.deeplinkContent = invalid
  m.startupArgsReceived = false
  m.top.observeFieldScoped("startupArgs", "onStartupArgs")
  m.top.observeFieldScoped("roInputInfo", "onInputInfoReceived")
  m.top.observeFieldScoped("fadeInContentController", "onFadeInContentController")
  
  ' Set up global services
  m.metadataFetchTask = m.top.findNode("MetadataFetchTask")
  m.global.addField("metadataFetchTask", "node", false)
  m.global.metadataFetchTask = m.metadataFetchTask

  m.trackingLoggingTask = m.top.findNode("TrackingLoggingTask")
  m.global.addField("trackingLoggingTask", "node", false)
  m.global.trackingLoggingTask = m.trackingLoggingTask

  m.LinearPlayerGroup = m.top.findNode("LinearPlayerGroup")
  
  m.background = m.top.findNode("ContentBackground")
  m.background.color = m.constants.ui.colors.backgroundColor

  m.uiGroup = m.top.findNode("uiGroup")
  m.contentGroup = m.top.findNode("ContentGroup")

  m.backgroundGroup = m.top.findNode("BackgroundGroup")
  m.logoGroup = m.top.findNode("logoGroup")
  m.logo = m.logoGroup.findNode("tubiLogo")
  m.logoKids = m.logoGroup.findNode("tubiKidsLogo")
  m.logoEspanol = m.logoGroup.findNode("tubiEspanolLogo")
  
  ' sponsorGroup will be shown only for Espanol screen
  m.sponsorGroup = m.top.findNode("sponsorGroup")
  m.sponsorPrefixText = m.sponsorGroup.findNode("sponsorPrefixText")
  m.sponsorLogo = m.sponsorGroup.findNode("sponsorLogo")
  
  if m.constants.deviceInfo.language = "es"
    m.logoKids.uri = "pkg:/images/locale/es_ES/logo-kids-white-large.png"
    m.logoKids.width = 259
    m.logoKids.translation = [1576,m.logoKids.translation[1]]
  end if
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

  ' indicates if we are building the app in a deep link state
  ' is set to true when a deeplink occurs, and set back to false after the deeplink has been handled
  ' (for example the video has been backed out of, or there was an error fetching deeplink metadata)
  m.enteredFromDeepLink = false

  ' indicates if we are in the process of handling an input event deeplink.
  m.handlingDeeplinkInputEvent = false

  ' used to save the current screen's trackingPageInfo when we received a deeplink roInputEvent, so that when
  ' we add the video player to the screen stack, we know what screen was being navigated from.
  ' This is needed because when a roInput deeplink event is observed, we create a new details screen for
  ' the content. But, if at that point in time, a video player screen is the top most screen in the screen
  ' stack, it will be removed and we won't be able to send a proper NavigateToPageEvent.
  m.currentPageInfoAtDeeplinkInputEvent = invalid

  m.screenStack = m.top.findNode("ScreenStack")
  m.screenStack.observeFieldScoped("isEmpty", "onScreenStackEmpty")
  m.screenStack.observeFieldScoped("current", "onScreenChange")

  ' the screen cache holds the top level screens in memory so they are not recreated and reloaded unecessarily
  m.screenCache = {}

  m.SideNav = m.top.findNode("SideNav")
  initSideNav()
  
  m.spinner = m.top.findNode("ContentControllerSpinner")
  m.LinearVideoPlayerSpinner = m.top.findNode("LinearVideoPlayerSpinner")

  m.inactivityTimer = m.top.findNode("InactivityTimer")
  m.inactivityTimer.observeFieldScoped("fire", "onInactivityTimer")
  m.inactivityTimer.control = "start"


  m.playerFullscreenCountdownTimer = m.top.findNode("PlayerFullscreenCountdownTimer")
  
  m.appLoadStopwatch = CreateObject("roTimespan")

  ' Set to the category id when content is launched from category screen,
  ' or set to invalid elsewhere
  m.autoplayContext = invalid

  m.lastUserActivity = Uptime(0)  ' arbitrary marker when user last pressed a remote key

  m._ = rodash()

  ' holds state so we don't fire the app load beacon more than once
  m.appLoadedBeaconFired = false
  
  ' holds state so we don't fire the intial home screen PageLoad analytics more than once
  ' Initial page load can be at app launch, or after a deep link
  m.initialHomeScreenLoadFired = false
  
  m.trackingLoggingTask.trackEvent = {
    trackType: "startApp"
  }
End Function


' onFadeInContentController callback will be triggered once the launch animation logo got finished
Function onFadeInContentController()

  fadeInUiGroup = customFadeIn(m.uiGroup, 2, 0.5)
  fadeInUiGroup.observeField("state", "onUiGroupFadeStateChange")

  currentScreen = currentScreen()
  if currentScreen <> invalid and currentScreen.isInFocusChain() = false
  
    ' isUpgradeModalOpened will be true if constants.showUpgradeAlert is true
    ' focus currentscreen only if the upgradeModal is closed or disabled
    
    isUpgradeModalOpened = false
    for i=0 to m.top.getChildCount()-1
      screen = m.top.getChild(i)
      if screen.subType() = "ModalDialogScreen"
        isUpgradeModalOpened = true
        exit for
      end if
    end for
    if isUpgradeModalOpened = false
      currentScreen.setFocus(true)
    end if
  
    if currentScreen.id = "detailScreen" and m.detailScreenAfterFn <> invalid
      m.detailScreenAfterFn(currentScreen)
      m.detailScreenAfterFn = invalid
    end if    
  end if

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



'Display a warning that the user needs to be registered in order to see certain content
'@param dialogSubtype: String, Indicate to analytics how this function is being called so it is easier to track things.
'@param pageInfo: assocArray, this will populate the analytic event's pageOneof property
Function displayMaturePlayWarning(dialogSubtype, pageInfo)
  dialogEvent = getDialogAnalyticEvent("SIGNIN_REQUIRED", dialogSubtype, pageInfo)

  title =  getTranslation("error_matureContent_title")
  message = getTranslation("error_mustBeSignedIn_description")
  buttons = [getTranslation("dialog_button_continue"), getTranslation("dialog_button_cancel")]
  showSimpleModal(title, message, buttons, dialogEvent, m.trackingLoggingTask, onSignInModalButtonSelected)
End Function


' Organizes the information needed to create a "dialog" tracking event and returns the created event AA
'
' @param dialogType: string, one of the valid operations as defined in events.protos -> DialogEvent -> enum DialogType
' @param dialogSubtype: string, a string limited to 20 characters, used to distinguish different dialogs from each other
' @param pageInfo: assocArray, this will populate the analytic event's pageOneof property
Function getDialogAnalyticEvent(dialogType, dialogSubtype, pageInfo)
  dialogAnalyticsEvent = {
    type: "dialog"
    values: {
      dialog_type: dialogType 'DialogType enum
      dialog_action: "SHOW"
      dialog_sub_type: dialogSubtype
    }
  }

  if pageInfo <> invalid
    dialogAnalyticsEvent.values.pageOneof = m.Tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
  end if

  return dialogAnalyticsEvent
End Function


' handles the response of a user who has been presented a sign in modal
Function onSignInModalButtonSelected()
  startSignIn(true)
End Function


'''''''''''''''''''''''
' onKeyEvent
'
' Back pressed on detail screen should close it
Function onKeyEvent(key As String, press As Boolean) as Boolean
  tubiLog("ContentController.onKeyEvent key = " + key)
  if m.lastUserActivity <> invalid
    m.lastUserActivity = Uptime(0)
  end if
  if press then
    ' for autohide support, bring the UI back on any keypress
    if key = "back"
      if m.enteredFromDeepLink = true
        m.enteredFromDeepLink = false
      end if

      if m.SideNav.opened = false
        if m.SideNav.visible = true
          displayNavMenu(true)
        else if m.screenStack.getChildCount() > 1
          popScreen(true, true)
          topScreen = currentScreen()
          sideNavId = m.constants.ui.screenIdToSideNavId[topScreen.id]
          if sideNavId <> invalid
            focusSideNavOption(sideNavId)
          end if
        else
          ' remove the last screen, probably detail screen,
          ' this should trigger a restart of the app via onScreenStackEmpty()
          ' PageLoad event will be sent by fireAppLoadBeacon() when home page finishes loading
          popScreen(true, false)
          ' reset appStartTime so that the home screen load event will have the correct loadTime value
          ' which will be set in fireAppLoadBeacon()
          m.top.appStartTime = Int(Uptime(0))
          m.deeplinkContent = invalid
        end if
      else if m.SideNav.opened = true
        if m.screenStack.getChildCount() > 1
          '//Most likely this condition only happens when user is on the homescreen
          '//::TODO::SIDENAV - add the condition when the count() = 1 but the screen is not the homescreen. 
          '//     Show display homescreen. This happens for root activation screen.
          popScreen(true, true)
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
    if m.SideNav.opened = true
      displayNavMenu()
    else if currentScreen() <> invalid
      currentScreen().setFocus(true)
    end if
  end if
End Function


Function onVideoPlayerVisibleChange(msg)
  tubiLog("ContentController.onVideoPlayerVisibleChange")
  videoPlayerVisible = msg.getData()
  if videoPlayerVisible = true
    m.SideNav.visible = false
    m.logoGroup.visible = false
  else
    m.SideNav.visible = true
    m.logoGroup.visible = true
  end if 
End Function



Function onInactivityTimer()
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


'''''''''''''''''''''''''
' startUserExperience
'
' We need to gather information from various places. As callbacks fire when these different infos arrive,
' they all set some state on m and call startUserExperience(). When all the information has arrived, as verified
' by the first checks in the function, then the function performs it's functionality to start the channel. 
'
Function startUserExperience()
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
    
    if m.sentStartUpEvents = false
      m.sentStartUpEvents = true
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
      sendHdcpLog() 
    end if

    ' In any of the auth transitions, this spinner might be visible
    'm.spinner.visible = false
    if m.enteredFromDeepLink = true then
      tubiLog("ContentController detected deep link request")
      ' we were asked to deep link into a content item. Go to it
      ' whether we were logged in or not.
      m.contentGroup.visible = true
      enableKidsModeUI(false) '//when deeplinking, exit out of kids mode because we cannot guarantee that the video is kid appropriate so the UI should not make the user think we're still in kids mode
      showDetailScreen(m.deeplinkContent, false)
    else if m.skipLandingScreen = false and m.global.authInfo = invalid
      ' display landingScreen only if skipLandingScreen is false and user is not loggedin
      m.contentGroup.visible = true
      m.skipLandingScreen = true
      ' sending experiment exposure event for roku_onboarding_registration
      getExperimentResource("roku", "roku_onboarding_registration")
      showLandingScreen()
    else if m.skipOnBoardingScreen = false and m.global.authInfo <> invalid
      ' display onBoarding screens only if the user is signedIn and previous screen was through Landing/Activation
      m.skipOnBoardingScreen = true
      showOnBoardingUnlimitedScreen()      
    else
      ' sending control experiment control event for roku_onboarding_registration
      if m.sendOnBoardingControlEvent = true and m.global.authInfo = invalid
        getExperimentResource("roku", "roku_onboarding_registration")
      end if
      startChannel()
      showUpgradeModal(m.constants.showUpgradeAlert, m.Tracking, m.trackingLoggingTask) 'show as necessary      
    end if
    
  end if
End Function


' sendHdcpLog will check HDCP link and send hdcp-version to logging API
Function sendHdcpLog()

  hdmiStatus = CreateObject("roHdmiStatus")
  
  if hdmiStatus <> invalid
    hdcpVersion = hdmiStatus.GetHdcpVersion()
    isActive = hdmiStatus.IsHdcpActive(hdcpVersion)
    if isActive = false
      hdcpVersion = "none"
    end if
    tubiLog(hdcpVersion, "info", "clientInfo", "hdcp-version")   'send info to server
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
      videoPlayer = getFromScreenCache(m.constants.ui.screenIds.videoPlayerScreen)
      stopVideoContent(videoPlayer) 'sets m.handlingDeeplinkInputEvent = false and m.deeplinkContent = invalid
      returnToPreviousScreenFromLinearVideo(false)

      if kidsModeAtStart = true
        ' remove all screens if in kids mode so that when backing out of the details screen,
        ' the home screen will be re-populated as expected
        shrinkScreenStack(0)
        emptyScreenCache()
      end if

      ' the following values will be used to save state and will be used in the process that
      ' is kicked off by showDetailScreen to load the detail screen and video player screen
      m.deeplinkContent = createDeeplinkContentFromStartupArgs(inputInfo)
      m.handlingDeeplinkInputEvent = true

      currentScreen = currentScreen()
      if currentScreen <> invalid
        m.currentPageInfoAtDeeplinkInputEvent = currentScreen.trackingPageInfo
      end if
      
      ' close any opened modal/pop-up when deeplinking via roInput
      for i=0 to m.top.getChildCount()-1
        screen = m.top.getChild(i)
        if screen.subType() = "ModalDialogScreen"
          closeModal(screen, "back")
        end if
      end for      

      showDetailScreen(m.deeplinkContent, false)
    else if inputInfo.type = "transport"
      videoPlayer = getFromScreenCache(m.constants.ui.screenIds.videoPlayerScreen)
      if videoPlayer <> invalid
        videoPlayer.transportVoiceRequest = inputInfo
      else
        if m.top.transportVoiceRequest <> invalid
          transportVoiceResponse = m.top.transportVoiceRequest
        else
          transportVoiceResponse = {}
        end if
        transportVoiceResponse.response = "unhandled"
        m.top.transportVoiceResponse = transportVoiceResponse
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
    if args.refreshToken.unescape() <> "" and args.userId.unescape() <> "" and args.userId.unescape() <> "0" and args.deviceId.unescape() <> ""
      if Lcase(args.entry) = "iphone" or Lcase(args.entry) = "ipad" or Lcase(args.entry) = "ios" or Lcase(args.entry) = "android"
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
    movieScreen = getFromScreenCache(m.constants.ui.screenIds.movieScreen)
    tvScreen = getFromScreenCache(m.constants.ui.screenIds.tvScreen)
    espanolScreen = getFromScreenCache(m.constants.ui.screenIds.espanolScreen)

    'this will be an auth request if the user is logged in
    'auth request creation happens in metadataFetchTask
    'auth request will add the userId param
    reqName = m.constants.reqNames.getCategory
    m.metadataFetchTask.request = m.metadataFetchTaskDTO.createRequest(categoryId, m.top, "reloadUserCategoriesResponse", reqName, invalid, shouldKidsModeBeSentToServer())

    '//Apply the movie, TV, and Espanol filters if those screens exist
    if movieScreen <> invalid
      optionMovie = {contentMode: m.constants.ui.contentMode.movie}
      m.metadataFetchTask.request = m.metadataFetchTaskDTO.createRequest(categoryId, m.top, "reloadMovieUserCategoriesResponse", reqName, invalid, shouldKidsModeBeSentToServer(), optionMovie)
    end if
    if tvScreen <> invalid
      optionTV = {contentMode: m.constants.ui.contentMode.tv}
      m.metadataFetchTask.request = m.metadataFetchTaskDTO.createRequest(categoryId, m.top, "reloadTVUserCategoriesResponse", reqName, invalid, shouldKidsModeBeSentToServer(), optionTV)
    end if
    if espanolScreen <> invalid
      optionEspanol = {contentMode: m.constants.ui.contentMode.latino}
      m.metadataFetchTask.request = m.metadataFetchTaskDTO.createRequest(categoryId, m.top, "reloadEspanolUserCategoriesResponse", reqName, invalid, shouldKidsModeBeSentToServer(), optionEspanol)
    end if    
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
  refreshStackedUserScreenWithChangedCategory(handledRequest.id)
End Function



Function onHistoryQueueRefresh()
  tubiLog("ContentController.onHistoryQueueRefresh")
  m.authTask.unobserveFieldScoped("authInfo")
  ' These will be empty parent nodes (no children) if user is not authenticated
  m.global.bookmarkIds = m.authTask.bookmarks
  m.global.historyIds = m.authTask.history
  refreshAllDetailScreens()
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

    '//display proper logo
    if bTurnOn = true
      m.logoKids.visible = true
      m.logo.visible = false
    else 
      m.logoKids.visible = false
      m.logo.visible = true
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
End Function


Function showTubiLogo()

  m.logo.visible = true

End Function


Function hideTubiLogo()

  m.logo.visible = false

End Function


Function showKidsLogo()

  m.logoKids.visible = true

End Function


Function hideKidsLogo()

  m.logoKids.visible = false

End Function


Function showEspanolLogo()

  m.logoEspanol.visible = true

End Function


Function hideEspanolLogo()

  m.logoEspanol.visible = false

End Function


Function showSponsorGroup()

  m.sponsorGroup.visible = true

End Function


Function hideSponsorGroup()

  m.sponsorGroup.visible = false

End Function


Function showLogo()

  if isKidsModeEnabledByParentalControls() = true or m.kidsModeEnabled = true 
    hideTubiLogo()
    hideEspanolLogo()
    hideSponsorGroup()
    showKidsLogo()
  else if m.latinoModeEnabled = true
    hideTubiLogo()
    hideKidsLogo()
    showEspanolLogo()
    showSponsorGroup()
  else
    hideKidsLogo()
    hideEspanolLogo()
    hideSponsorGroup()
    showTubiLogo()
  end if

End Function


' set sponsorLogo & sponsorPrefixText based on matrix response
Function setSponsorDetails(metadata)

  prefix_text = invalid
  sponsorLogo = invalid
  
  sponsor = metadata.sponsor
  if sponsor <> invalid
    prefix_text = sponsor.prefix_text
    sponsorLogo = sponsor.logo
  end if
  
  if prefix_text <> invalid and sponsorLogo <> invalid
    m.sponsorPrefixText.text = UCase(prefix_text)
    m.sponsorLogo.uri = sponsorLogo
  end if
  
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


Function isAdultModeEnabledByParentalControl() as Boolean
  tubiLog("ContentController.isAdultModeEnabledByParentalControl")
  bEnabled = true
  
  if m.global.authInfo <> invalid and m.global.authInfo.parentalrating <> invalid
    if m.global.authInfo.parentalrating = 3
      bEnabled = true
    else
      bEnabled = false
    end if
  end if
  return bEnabled
End Function


Function refreshAllDetailScreens()
  ' Refresh all detail screens so they have proper history that's been loaded or unloaded
  for i=0 to m.screenStack.getChildCount()-1
    screen = m.screenStack.getChild(i)
    if screen.subType() = "DetailScreen"
      populateDetailScreen(screen, screen.content)
    end if
  end for
End Function


' Content for a category has been updated. ANy screen that is displaying this category should be updated.
Function refreshStackedUserScreenWithChangedCategory(sCategoryID)
  ' Tell the screen that contains the categroy associated with the passed ID to refresh the next time is is on screen by setting the validUntil variable to 0 
  for i=0 to m.screenStack.getChildCount()-1
    screen = m.screenStack.getChild(i)
    if screen <> invalid and screen.content <> invalid and screen.content.getChildCount() > 0 and screen.content.getChild(0).id  = sCategoryID
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
  popScreen(true, true)
  m.aboutScreen = invalid
End Function


Function startChannel()
  tubiLog("ContentController.startChannel")
  m.contentGroup.visible = true
  m.appLoadStopwatch.mark()
  focusSideNavOption(m.constants.ui.sideNavIds.home)
  if isKidsModeEnabledByParentalControls() = true
    enableKidsModeUI(true)
  else
    enableKidsModeUI(false)
  end if
  showHomeScreen(m.constants, m.global.authInfo)
  shrinkScreenStack(1)
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
  setHomeScreenBackground(homeScreen)
End Function


Function setHomeScreenBackground(homeScreen)
  if homeScreen <> invalid and currentScreen() <> invalid and currentScreen().isSubType("HomeScreen")
    contentType = invalid
    if homeScreen.contentFocused <> invalid
      contentType = homeScreen.contentFocused.type
    end if
    m.backgroundGroup.backgroundInfo = {
      type: getBackgroundtype(homeScreen.backgroundUriList, contentType)
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
Function fireAppLoadTimeEvent(loadTime)
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
' @contentType, String - depending on the focused on content, it will determine the background type
Function getBackgroundtype(backgroundUriList, contentType = "")
  if backgroundUriList <> invalid
    if backgroundUriList[0] = m.defaultBackgroundUri
      backgroundType = m.constants.ui.backgroundTypes.fullScreen
    else if contentType = m.constants.ui.contentTypes.linear
      backgroundType = m.constants.ui.backgroundTypes.linear
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


' fires a beacon which roku uses to determine the app load time only once per session. See:
' https://developer.roku.com/en-gb/docs/developer-program/performance-guide/measuring-channel-performance.md
' 
' also fires a home screen page load event when the home screen is created due to no screens on the stack
' (this would happen in the case of deep links)
Function fireAppLoadBeacon()
  currentTime = Int(Uptime(0))
  loadTime = currentTime - m.top.appStartTime

  if m.appLoadedBeaconFired = false
    m.appLoadedBeaconFired = true
    fireAppLoadTimeEvent(loadTime)
    m.top.signalBeacon("AppLaunchComplete")
  end if

  'send tracking event for initial home page load
  currentScreen = currentScreen()
  if m.initialHomeScreenLoadFired = false and currentScreen.id = m.constants.ui.screenIds.homeScreen
    m.trackingLoggingTask.trackEvent = {
      type: "page_load"
      values: {
        pageOneof: m.Tracking.getAnalyticsPage("home_page", {})  'a valid page type (see PageLoadEvent in events.protos)
        load_time: loadTime
        status: "SUCCESS"  'ActionStatus enum
      }
    }
    m.initialHomeScreenLoadFired = true
  end if
End Function


' showHideSpinner - shows/hides the loading spinner/text
' 
'@visible : boolean - true/false
Function showHideSpinner(visible)

  m.spinner.visible = visible

End Function


Function onUiGroupFadeStateChange(msg)

  animationState = msg.getData()
  fadeInUiGroup = msg.getRoSGNode()
  if animationState = "stopped"
    fadeInUiGroup.unobserveField("state")
    m.top.removeStartUpScreens = true
  end if
  
End Function


Function customFadeIn(target, duration, delay)

  animationOptions = {
    easeFunction: "inCubic"
    opacity: 1
    duration: duration
    delay: delay
    allowOnLowSpecDevices: true
  }
  return animate(target, animationOptions)
  
End Function