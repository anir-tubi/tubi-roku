Function init()
  tubiLog("")
  tubiLog("Init Scenegraph----------------")
  m._ = rodash()

  m.constants = m.global.constants

  m.contentExperienceMode = m.constants.ui.contentExperienceModes.standard

  ' Timer to find last time the app restarted
  m.lastAppRestartTimer = CreateObject("roTimespan")

  ' Timer to find last time the app suspended
  m.appSuspendTimer = CreateObject("roTimespan")

  generalTask = CreateObject("roSGNode", "GeneralTask") ' initiate GeneralTask
  ' Initiate GeneralTaskModule by passing caller context.
  ' Calling GeneralTaskModule() will append methods to the local m.
  ' DO NOT overwrite m variable methods/properties which belongs to GeneralTaskModule.
  GeneralTaskModule(m, generalTask)

  '//When ContentController initializes, clear all trandslations in case this is contained in a remote component.
  clearTranslations()

  m.Request = TubiRequest(m.constants.settings)
  Auth = TubiAuth(m.constants, m.Request)
  m.NodeHelpers = TubiNodeHelpers()
  apiUtils = ApiUtils(m.constants)
  m.Bookmarks = TubiBookmarks(m.Request, Auth, m.constants, m.NodeHelpers, apiUtils)
  m.Tracking = TubiTracking(m.constants, m.Request, Auth)
  m.cmsApi = CmsApi(m.constants, m.Request, Auth, apiUtils)
  m.userDeviceApi = UserDeviceApi(m.constants, apiUtils)
  m.tensorapi = TensorApi(m.constants, m.Request, Auth)

  m.background = m.top.findNode("ContentBackground")
  m.background.color = m.constants.ui.colors.backgroundColor
  m.SponsorBground = m.top.findNode("SponsorshipBackgroundGroup")

  m.uiGroup = m.top.findNode("uiGroup")
  m.contentGroup = m.top.findNode("ContentGroup")
  m.SideNav = m.top.findNode("SideNav")

  m.VideoPreviewGroup = m.top.findNode("VideoPreviewGroup")

  m.LinearPlayerGroup = m.top.findNode("LinearPlayerGroup")
  m.LinearPlayerGroupAboveScreenStack = m.top.findNode("LinearPlayerGroupAboveScreenStack")
  m.LinearCountdownTimer = m.top.findNode("LinearCountdownTimer")

  m.backgroundGroup = m.top.findNode("BackgroundGroup")
  m.logoGroup = m.top.findNode("logoGroup")
  m.logo = m.logoGroup.findNode("tubiLogo")
  m.logoKids = m.logoGroup.findNode("tubiKidsLogo")
  m.logoEspanol = m.logoGroup.findNode("tubiEspanolLogo")
  m.experienceLogo = m.logoGroup.findNode("experienceLogo")
  m.clock = m.top.findNode("clock")
  m.spinner = m.top.findNode("ContentControllerSpinner")
  m.LinearVideoPlayerSpinner = m.top.findNode("LinearVideoPlayerSpinner")
  m.playerFullscreenCountdownTimer = m.top.findNode("PlayerFullscreenCountdownTimer")
  m.resumeAllowedTimer = m.top.findNode("ResumeAllowedTimer")

  m.screenStack = m.top.findNode("ScreenStack")
  m.screenStack.observeFieldScoped("isEmpty", "onScreenStackEmpty")
  m.screenStack.observeFieldScoped("current", "onScreenChange")

  ' the screen cache holds the top level screens in memory so they are not recreated and reloaded unecessarily
  m.cache = TubiCache(m.NodeHelpers, m.constants.ui.cacheableScreenIds, m.constants.ui.permanentlyCachedContentIds)

  ' This is an associative array that keeps track of when pixels are sent out when sponsored containers are displayed. The pixels should only be sent once per page load.
  m.sentSponsorPixels = {}

  ' Keep track of when a user starts a path to watch a video that is contained in a sponsored container. This ID will be passed to rainmaker for an ad request and be used to play a sponsored preroll ad
  m.videoSponsorExposureId = ""

  ' Set up global services
  m.metadataFetchTask = m.top.findNode("MetadataFetchTask")
  m.global.addField("metadataFetchTask", "node", false)
  m.global.metadataFetchTask = m.metadataFetchTask

  m.trackingLoggingTask = m.top.findNode("TrackingLoggingTask")
  m.global.addField("trackingLoggingTask", "node", false)
  m.global.trackingLoggingTask = m.trackingLoggingTask

  ' initialize states needed for various parts of kids mode
  m.kidsModeFeatureOn = false 'Should the kids Mode feature be made available for the user to interact with
  if m.constants.deviceInfo.countryCode <> invalid and (UCase(m.constants.deviceInfo.countryCode) = "US" or UCase(m.constants.deviceInfo.countryCode) = "CA")
    m.kidsModeFeatureOn = true
  end if

  ' TODO: Once MetadataFetchTask functionality is refactored to use the GeneralTask remove uiMode from m.global
  m.global.addField("uiMode", "string", false)
  setUiMode(m.constants.ui.modes.standard)

  m.top.observeFieldScoped("focusedChild", "onComponentFocus")

  'initialize linearScreenAfterFn. This function is executed after fadeInController
  'in case fadeInContentController is still playing when we tried to play linear content which will result in playback error.
  m.linearScreenAfterFn = invalid

  m.deeplinkContent = invalid
  m.startupArgsReceived = false
  m.top.observeFieldScoped("startupArgs", "onStartupArgs")
  m.top.observeFieldScoped("roInputInfo", "onInputInfoReceived")
  m.top.observeFieldScoped("fadeInContentController", "onFadeInContentController")
  m.top.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")

  m.top.observeFieldScoped("customSuspend", "onCustomSuspend")
  m.top.observeFieldScoped("customResume", "onCustomResume")

  if m.constants.deviceInfo.language = "es"
    m.logoKids.uri = "pkg:/images/locale/es_ES/logo-kids-white-large.png"
    m.logoKids.width = 259
    m.logoKids.translation = [1566, m.logoKids.translation[1]]
  end if
  m.defaultBackgroundUri = m.constants.ui.uris.defaultBackground

  m.marketingBackgroundUri = m.constants.ui.uris.marketingBackground

  'This variable has been used to keep track of user's choice on autoplay. Without maintaining this variable, we might have to access m.global everytime
  m.isAutoplayVideoPreviewOn = true 'True by default

  ' Global state
  m.global.addField("bookmarkIds", "node", false)
  m.global.bookmarkIds = CreateObject("roSGNode", "BookmarkContentNode")
  m.global.addField("historyIds", "node", false)
  m.global.historyIds = CreateObject("roSGNode", "HistoryContentNode")

  m.global.addField("authInfo", "assocarray", false)
  m.global.authInfo = invalid ' indicates not logged in

  m.authInfoReceived = false 'is the auth info returned from the registry
  m.authInfoRefreshed = true 'is the auth info refreshed after receiving a deeplink with a refresh token
  m.ageVerificationComplete = false 'has the user verified their age?
  m.authTask = CreateObject("roSGNode", "AuthTask")
  m.authTask.observeFieldScoped("authInfo", "onStartupAuthInfoReceived")
  m.authTask.functionName = "execInitializeUserData"
  m.authTask.control = "RUN"

  ' For queue and history management from detail screen
  m.userTask = CreateObject("roSGNode", "AuthTask")

  m.logOutTask = m.top.findNode("LogOutTask")

  ' indicates if we are building the app in a deep link state
  ' is set to true when a deeplink occurs, and set back to false after the deeplink has been handled
  ' (for example the video has been backed out of, or there was an error fetching deeplink metadata)
  m.enteredFromDeepLink = false

  ' Set to the category id when content is launched from category screen,
  ' or set to invalid elsewhere
  m.autoplayContext = invalid

  m.lastUserActivity = Uptime(0) ' arbitrary marker when user last pressed a remote key

  ' holds state so we don't fire the app load beacon more than once
  m.appLoadedBeaconFired = false

  m.trackingLoggingTask.trackEvent = {
    trackType: "startApp"
  }

  epgExperimentResource = getExperimentResource("roku_linear_epg", "roku_linear_epg_v5", false)
  if epgExperimentResource.enabled = true
    if epgExperimentResource.update_homescreen = true
      m.LinearVideoPlayerSpinner.translation = [447, 660]
    end if

    'this variable is used to decide when to let the user interact with EPG TimeGrid after content has been either assinged first time or refreshed after validUntil/refetch due to errors.
    'currently, user is allowed to interact with EPG as soon as first batch is retrived and EPG content has been updated.
    'Once the LinearVideoplayer integrates with EPGScreen, then we need to revisit the logic of when to let the user interact with EPG TimeGrid due to jumpTO channel requirement and Channel might be fetched to focus on.
    m.updateEPGTimeGrid = true
  end if

End Function


' onFadeInContentController callback will be triggered once the launch animation logo got finished
Function onFadeInContentController()
  tubiLog("ContentController.onFadeInContentController")
  fadeInUiGroup = customFadeIn(m.uiGroup, 2, 0.5)
  fadeInUiGroup.observeField("state", "onUiGroupFadeStateChange")

  currentScreen = getCurrentScreen()
  'if m.linearScreenAfterFn is set in that case execute linearScreenAfterFn
  if m.linearScreenAfterFn <> invalid
    m.linearScreenAfterFn()
    m.linearScreenAfterFn = invalid
  else if currentScreen <> invalid and currentScreen.isInFocusChain() = false

    ' isUpgradeModalOpened will be true if constants.showUpgradeAlert is true
    ' focus currentScreen only if the upgradeModal is closed or disabled

    isUpgradeModalOpened = false
    for i = 0 to m.top.getChildCount() - 1
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
      dialog_type: "EXIT" 'DialogType enum
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

  title = getTranslation("error_matureContent_title")
  message = getTranslation("error_mustBeSignedIn_description")
  buttons = [getTranslation("dialog_button_continue"), getTranslation("dialog_button_cancel")]
  showSimpleInstantResumableModal(title, message, buttons, dialogEvent, m.trackingLoggingTask, onSignInModalButtonSelected)
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


' triggered when signIn button is selected when opening MyList from Sidenav
Function onSignInModalSelectedViaSideNavMyList()
  startSignIn(onSideNavMyListAfterSignIn)
End Function


' handles the response of a user who has been presented a sign in modal
Function onSignInModalButtonSelected()
  startSignIn(onSideNavSignInCompleted)
End Function


' triggered when signIn button is selected while updating Parental Control
Function onSignInModalSelectedViaParentalControl()
  startSignIn(onParentalControlAfterSignIn)
End Function


'triggered when signIn button is selected while updating video preview options
Function onSignInModalSelectedViaAutoplayPreview()
  startSignIn(onAutoplayPreviewAfterSignIn)
End Function


' Call this function when the left or back buttons are pressed and the side nav should be opened.
Function openSideNavFromButton()
  '//reset videoSponsorExposureId when the side nav is opened
  m.videoSponsorExposureId = ""
  displayNavMenu(true)
End Function


'''''''''''''''''''''''
' onKeyEvent
'
' Back pressed on detail screen should close it
Function onKeyEvent(key as String, press as Boolean) as Boolean
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
          openSideNavFromButton() '//"BUTTON_BACK"
        else if m.screenStack.getChildCount() > 1
          oldTopScreen = getCurrentScreen()
          if oldTopScreen.id = m.constants.ui.screenIds.espanolScreen
            ' exiting the espanol experience, so update the uiMode which will be referenced
            ' in subsequent function calls in order to display the correct UI.
            setUiMode(m.constants.ui.modes.standard)
          end if

          popScreen(true, true)

          newTopScreen = getCurrentScreen()
          if newTopScreen.id = m.constants.ui.screenIds.espanolScreen
            setUiMode(m.constants.ui.modes.latino)
          end if

          sideNavId = m.constants.ui.screenIdToSideNavId[newTopScreen.id]
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
        ' Side nav is opened, so pop the screen on back button press to reveal the screen below.
        ' The screen below will always be the home screen, if the side nav is open.
        if m.screenStack.getChildCount() > 1
          oldTopScreen = getCurrentScreen()
          if oldTopScreen.id = m.constants.ui.screenIds.espanolScreen
            ' exiting the espanol experience, so update the uiMode which will be referenced
            ' in subsequent function calls in order to display the correct UI.
            setUiMode(m.constants.ui.modes.standard)
          end if
          popScreen(true, true)
          newTopScreen = getCurrentScreen()

          sideNavId = m.constants.ui.screenIdToSideNavId[newTopScreen.id]
          if sideNavId <> invalid
            focusSideNavOption(sideNavId)
            m.SideNav.setFocus(true)
          else
            hideNavMenu(false)
            focusCurrentScreen()
          end if
        else
          topScreen = getCurrentScreen()
          if topScreen.id <> m.constants.ui.screenIds.homeScreen
            '//make sure the last screen in the stack is the homescreen.
            '//If it isn't this this might have happened b/c of coming from a non home screen triggered by the initial content screen.
            '//pop the screen, which will trigger the stack to load the homescreen by
            ' triggering a restart of the app via onScreenStackEmpty()
            ' PageLoad event will be sent by fireAppLoadBeacon() when home page finishes loading
            popScreen(true, false)
            ' reset appStartTime so that the home screen load event will have the correct loadTime value
            ' which will be set in fireAppLoadBeacon() if the beacon hasn';t fired yet
            m.top.appStartTime = Int(Uptime(0))
            m.deeplinkContent = invalid
          else
            displayExitModal(topScreen.trackingPageInfo)
          end if
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
          openSideNavFromButton() '//"BUTTON_LEFT"
          bReacted = true
        end if
      else if (key = "right" or key = "left") and isSideNavActive() = true
        '//The RIGHT Key has been pressed, now hide the menu
        hideNavMenu(true)
        focusCurrentScreen()
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
    else if getCurrentScreen() <> invalid
      getCurrentScreen().setFocus(true)
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


''''''''''''''''''''''
' onExitAppModalButtonSelected
'
' handles the response of a user who has been presented an exit app modal
Function onExitAppModalButtonSelected()
  sendNielsenPing(m.constants.thirdParty.nielsen.pingTypes.sessionEnd, invalid, setExitAppWrapper, setExitAppWrapper)
End Function


' setExitWrapper wraps setExitApp() and is used when the app should close after some call to
' the m.makeRequest() has completed (like sending an end session ping to Nielsen).
' The @response param is not used but will be set by the generalTaskModule,
' and as such is necessary.
'
' @_response: string or assocArray, string if request was succesful, AA if request errored.
Function setExitAppWrapper(_response)
  setExitApp()
End Function


Function setExitApp()
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
    authInfo = m.global.authInfo
    if authInfo = invalid or (authInfo <> invalid and authInfo.userId = invalid)
      ' we only need to refresh if the user is currently signed out
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
  else if shouldShowAgeGate() = true and m.ageVerificationComplete <> true
    ' check if we have age information for the user
    if isLoggedInUser() = true
      authInfo = m.global.authInfo
      if authInfo.hasAge <> true
        ' the user is a signed in user who has not been age verified, we should:
        ' 1) check if the backend has an age for the user
        ' 2) if not, show the age verification screen
        ' 3) upon getting a valid birthdate for the user, PATCH the user record on the backend
        checkBirthdayInfo = m.userDeviceApi.checkBirthdayInfo(authInfo.userId)
        m.makeRequest({
          url: checkBirthdayInfo.url
          requestType: m.constants.reqNames.checkBirthdayInfo
          options: checkBirthdayInfo.options
          successCallback: onBirthdayCheckSuccess
          errorCallback: onBirthdayCheckError
          responseType: "assocarray"
        })
      else
        ' the user is a signed in user who has been age verfied, so set m.ageVerificationComplete = true
        ' and recursively call this function so we can move past the m.ageVerificationComplete check
        m.ageVerificationComplete = true
        startUserExperience()
      end if
    else
      ' the user is a guest user, and we are not age gating guest users at app launch,
      ' so set m.ageVerificationComplete = true and recursively call this
      ' Function so we can move past the m.ageVerificationComplete check.
      m.ageVerificationComplete = true
      startUserExperience()
    end if
  else
    ' All of the above checked values are true, so we are ready to start the channel UI

    ' initSideNav must run after m.global.trackingLoggingTask is set in case there are any experiments
    ' within the side nav component that rely on trackingLoggingTask to send exposure events.
    ' initSideNav relies on m.kidsModeFeatureOn being set, so run after m.kidsModeFeatureOn is set.
    ' initSideNav also relies on m.global.authInfo being set in order to run isParentalControlsAdultLevel
    initSideNav()

    showContentGroup()

    ' Since we're ready to start the channel, make sure the loading spinner is hidden
    root = m.top.getScene()
    if root <> invalid
      sceneSpinner = root.findNode("LoadingSpinner")
      if sceneSpinner <> invalid then
        sceneSpinner.visible = false 'the spinner in the scene component
      end if
    end if

    m.spinner.visible = false ' the spinner in the contentController component
    sendHdcpLog()
    sendNielsenPing(m.constants.thirdParty.nielsen.pingTypes.sessionStart)

    setUiModeFromState()

    if m.enteredFromDeepLink = true
      tubiLog("ContentController detected deep link request")
      ' we were asked to deep link into a content item. Go to it
      ' whether we were logged in or not.
      handleDeeplink()
    else if shouldDisplayInitialContentScreen() = true
      ' Display the initial content screen to the user so they can choose the proper experience.
      displayInitialContentScreen()
      showUpgradeModal(m.constants.showUpgradeAlert, m.Tracking, m.trackingLoggingTask) 'show as necessary
    else
      startChannel()
      showUpgradeModal(m.constants.showUpgradeAlert, m.Tracking, m.trackingLoggingTask) 'show as necessary
    end if

  end if
End Function


' Contain the logic to determine if the Initial Content Screen should be displayed.
Function shouldDisplayInitialContentScreen()
  bDisplay = false
  if m.constants.deviceInfo.countryCode = "US" and isParentalControlsAdultLevel() = true and m.uiMode <> m.constants.ui.modes.kidsAgeGate
    ' Do not display this screen if they are outside of the US or are going to display kids mode or parental control is set to anything other than the adult level
    ' Also skip this screen if the user is coming from a deeplink
    bDisplay = true
  end if
  return bDisplay
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
    tubiLog(hdcpVersion, "info", "clientInfo", "hdcp-version") 'send info to server
  end if

End Function


' is triggered when the args that are passed to main, are passed into the SG thread to the contentController.
' this is one of the pre-requisites to starting the SG user experience.
Function onStartupArgs()
  m.deeplinkContent = invalid
  if m.top.startUpArgs <> invalid and (m.top.startUpArgs.contentID <> invalid or m.top.startUpArgs.page <> invalid)
    m.deeplinkContent = createDeeplinkContentFromStartupArgs(m.top.startUpArgs)
  end if

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
  inputInfo = m.top.roInputInfo
  if inputInfo <> invalid
    if inputInfo.type = "deeplink"
      handleInputDeeplink(inputInfo)
    else if inputInfo.type = "transport"
      currentScreen = getCurrentScreen()

      if currentScreen <> invalid and currentScreen.hasField("handlesTransportVoiceRequests") and currentScreen.handlesTransportVoiceRequests = true
        currentScreen.transportVoiceRequest = inputInfo
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


Function onTransportVoiceResponse(msg)
  transportVoiceResponse = msg.getData()
  m.top.transportVoiceResponse = transportVoiceResponse
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
    if m.authTask.authInfoRefreshed <> invalid
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
  if isLoggedInUser() = true
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

    isKidsMode = shouldKidsModeBeSentToServer()
    reqName = m.constants.reqNames.getCategory

    options = {}
    params = {}
    ' content_mode is mandatory param and its value needs to be passed as empty for fetching homescreen content
    params["content_mode"] = ""
    options.params = params
    categoryReqInfo = m.CmsApi.categoryReqInfo(categoryId, isKidsMode, options)

    m.makeRequest({
      url: categoryReqInfo.url
      requestType: reqName
      options: categoryReqInfo.options
      successCallback: onReloadUserCategoriesResponse
      errorCallback: onErrorReloadUserCategories
      responseType: "node"
      id: categoryId
    })

    '//Apply the movie, TV, and Espanol filters if those screens exist
    if movieScreen <> invalid
      optionMovie = {}
      movieParams = {}
      movieParams["content_mode"] = m.constants.ui.contentMode.movie
      optionMovie.params = movieParams

      categoryReqInfo = m.CmsApi.categoryReqInfo(categoryId, isKidsMode, optionMovie)

      m.makeRequest({
        url: categoryReqInfo.url
        requestType: reqName
        options: categoryReqInfo.options
        successCallback: onReloadUserCategoriesResponseInMovieScreen
        errorCallback: onErrorReloadUserCategoriesInMovieScreen
        responseType: "node"
        id: categoryId
      })
    end if

    if tvScreen <> invalid
      optionTV = {}
      tvParams = {}
      tvParams["content_mode"] = m.constants.ui.contentMode.tv
      optionTV.params = tvParams

      categoryReqInfo = m.CmsApi.categoryReqInfo(categoryId, isKidsMode, optionTV)

      m.makeRequest({
        url: categoryReqInfo.url
        requestType: reqName
        options: categoryReqInfo.options
        successCallback: onReloadUserCategoriesResponseInTVScreen
        errorCallback: onErrorReloadUserCategoriesInTVScreen
        responseType: "node"
        id: categoryId
      })
    end if

    if espanolScreen <> invalid
      optionEspanol = {}
      esParams = {}

      esParams["content_mode"] = m.constants.ui.contentMode.latino
      optionEspanol.params = esParams

      categoryReqInfo = m.CmsApi.categoryReqInfo(categoryId, isKidsMode, optionEspanol)

      m.makeRequest({
        url: categoryReqInfo.url
        requestType: reqName
        options: categoryReqInfo.options
        successCallback: onReloadUserCategoriesResponseInEspanolScreen
        errorCallback: onErrorReloadUserCategoriesInEspanolScreen
        responseType: "node"
        id: categoryId
      })
    end if
  end if
End Function


Function onReloadUserCategoriesResponse(handledRequest)
  tubiLog("ContentController.onReloadUserCategoriesResponse")

  ' update the main home screen with the updated user category
  onReloadUserCategoriesInHomeScreen(handledRequest)

  ' inform the category list screen of the udpated user category
  categoryListScreen = getFromScreenCache(m.constants.ui.screenIds.categoryListScreen)
  if categoryListScreen <> invalid
    categoryListScreen.reloadUserCategoriesResponse = handledRequest
  end if

  ' inform the category details screen for the specific user category of the update user category content
  if handledRequest <> invalid
    refreshStackedUserScreenWithChangedCategory(handledRequest.id)
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


' @mode: string, one of the modes at constants.ui.modes
Function setUiMode(mode)
  TubiLog("ContentController.setUiMode: " + mode)
  if mode = m.constants.ui.modes.standard
    'standard
    m.uiMode = mode

    ' must set global theme prior to setting m.sideNav.uiMode, since the sideNav update
    ' depends on the global theme.
    if m.global.theme = invalid or m.global.theme.id <> m.constants.ui.themeIDs.default
      m.global.theme = m.constants.ui.themes.default
    end if

    m.sideNav.uiMode = mode
    m.backgroundGroup.kidsMode = false
    m.trackingLoggingTask.analyticsAppMode = "DEFAULT_MODE"

    hideKidsLogo()
    hideEspanolLogo()
    showTubiLogo()
  else if mode = m.constants.ui.modes.kids
    'kids
    if m.kidsModeFeatureOn
      m.uiMode = mode
      setCommonKidsModeElements()
      m.sideNav.uiMode = mode
    end if
  else if mode = m.constants.ui.modes.kidsAgeGate
    'kids mode due to age gating
    if m.kidsModeFeatureOn
      m.uiMode = mode
      setCommonKidsModeElements()
      m.sideNav.uiMode = mode
    end if
  else if mode = m.constants.ui.modes.kidsParental
    ' kids mode due to parental controls
    if m.kidsModeFeatureOn
      m.uiMode = mode
      setCommonKidsModeElements()
      m.sideNav.uiMode = mode
    end if
  else if mode = m.constants.ui.modes.latino
    'latino
    m.uiMode = mode
    if m.global.theme = invalid or m.global.theme.id <> m.constants.ui.themeIDs.default
      m.global.theme = m.constants.ui.themes.default
    end if
    m.sideNav.uiMode = mode
    m.backgroundGroup.kidsMode = false
    m.trackingLoggingTask.analyticsAppMode = "LATINO_MODE"
    hideTubiLogo()
    hideKidsLogo()
    showEspanolLogo()
  end if

  ' How to access uiMode:
  ' m.uiMode can be accessed directly in the controller context;
  ' screens and child components of screens should have uiMode passed down to them from the controller context;
  ' GeneralTask parsers can have uiMode passed as a custom field on the AA passed to makeRequest()
  ' Until MetadataFetch task can be replaced by the GeneralTask, MetadataFetchTask must access uiMode via a global
  m.global.uiMode = m.uiMode

  tellScreensIfKidsModeBeSentToServer()
End Function


'@aPixelURLs: The array of pixel URLs that log when a sponsored container has been seen
Function sendSponsorPixels(aPixelURLs)
  tubiLog("ContentController.sendSponsorPixels")
  if aPixelURLs <> invalid and aPixelURLs.Count() > 0
    for each pixelURL in aPixelURLs
      '//the sStringToReplace is the agreed upon string that the backend will set to the param that is used for cachebusting.
      '//a cache busting string must be created within the Roku client and replace the sStringToReplace.
      sStringToReplace = "(ADRISE:CB)"
      sCacheBuster = createCacheBusterString()
      newPixelURL = pixelURL.replace(sStringToReplace, sCacheBuster)
      encodedUrl = newPixelURL.EncodeUri()

      if isNonEmptyString(encodedUrl)
        m.makeRequest({
          url: encodedUrl
          requestType: m.constants.reqNames.sponsorPixel
          responseType: "assocarray"
          silenceCallbackWarnings: true
        })
      end if
    end for
  end if
End Function


' setUIModeFromState should only be used when we don't know what the uiMode should be.
' Typically this should only be when a signed in user has opened the app (don't know if they
' should be in age gated kids mode or parental controls kids mode) or when a user completes the
' sign in process (don't know if the user should be in parental control kids mode).
Function setUiModeFromState()
  tubiLog("ContentController.setUiModeFromState")
  modeSet = false
  if isKidsModeEnabledByParentalControls() = true
    setUiMode(m.constants.ui.modes.kidsParental)
    modeSet = true
  else if shouldShowAgeGate() = true then
    if m.guestUserHasAgeInfo = invalid then
      m.guestUserHasAgeInfo = TubiAuth(m.constants, m.Request).getGuestUserHasAgeInfo()
    end if

    ' Have to make sure we check expired as well as default state will always have hasAge = false
    if m.guestUserHasAgeInfo.hasAge = false and m.guestUserHasAgeInfo.expired = false then
      setUiMode(m.constants.ui.modes.kidsAgeGate)
      modeSet = true
    end if
  end if

  if modeSet = false then
    setUiMode(m.constants.ui.modes.standard)
  end if
End Function


' a helper function to update the UI to a "kids mode" and which should only be
' called from within setUiMode()
Function setCommonKidsModeElements()
  if m.kidsModeFeatureOn
    if m.global.theme = invalid or m.global.theme.id <> m.constants.ui.themeIDs.kidsMode
      m.global.theme = m.constants.ui.themes.kidsMode
    end if

    hideTubiLogo()
    hideEspanolLogo()
    showKidsLogo()
    m.backgroundGroup.kidsMode = true
    m.trackingLoggingTask.analyticsAppMode = "KIDS_MODE"
    tellScreensIfKidsModeBeSentToServer()

    if isICTSExperimentEnabled(true) = true
      '//change the side nav options if the experiment variant is enabled
      m.SideNav.displayKids = true
      m.SideNav.displayContentExperience = false
    end if
  end if
End Function


' What boolean value should be sent to the UAPI backend in terms of kids mode?
Function shouldKidsModeBeSentToServer()
  if m.uiMode = m.constants.ui.modes.kids and isKidsModeEnabledByParentalControls() = false
    return true
  else if m.uiMode = m.constants.ui.modes.kidsAgeGate
    return true
  end if

  return false
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


Function isKidsUIOn()
  if m.uiMode = m.constants.ui.modes.kids or m.uiMode = m.constants.ui.modes.kidsAgeGate or m.uiMode = m.constants.ui.modes.kidsParental
    return true
  end if
  return false
End Function


Function showTubiLogo()

  m.logo.visible = true

End Function


Function hideTubiLogo()

  m.logo.visible = false

End Function


Function showKidsLogo()
  if isICTSExperimentEnabled(true) = true
    showExperienceLogo(m.constants.ui.contentExperienceModes.kids)
  else
    m.logoKids.visible = true
  end if
End Function


Function hideKidsLogo()
  if isICTSExperimentEnabled() = true
    hideExperienceLogo()
  else
    m.logoKids.visible = false
  end if
End Function


Function showEspanolLogo()
  if isICTSExperimentEnabled(true) = true
    showExperienceLogo(m.constants.ui.contentExperienceModes.espanol)
  else
    m.logoEspanol.visible = true
  end if
End Function


Function hideEspanolLogo()
  if isICTSExperimentEnabled() = true
    hideExperienceLogo()
  else
    m.logoEspanol.visible = false
  end if
End Function


'@experienceId: string - identifier of which experience logo to show. one of constants.ui.contentExperienceModes
Function showExperienceLogo(experienceId)
  modes = m.constants.ui.contentExperienceModes
  if isICTSExperimentEnabled(true) = true and experienceId <> modes.standard and experienceId <> modes.liveTV
    m.experienceLogo.experienceId = experienceId
    m.experienceLogo.visible = true
  else
    m.experienceLogo.visible = false
  end if
End Function


Function hideExperienceLogo()
  m.experienceLogo.visible = false
End Function


Function isKidsModeEnabledByParentalControls() as Boolean
  tubiLog("ContentController.isKidsModeEnabledByParentalControls")
  bEnabled = false

  if isLoggedInUser() = true
    authInfo = m.global.authInfo
    if authInfo.parentalrating <> invalid and authInfo.parentalrating < 2
      bEnabled = true
    end if
  end if
  return bEnabled
End Function


Function isParentalControlsAdultLevel() as Boolean
  tubiLog("ContentController.isParentalControlsAdultLevel")
  bEnabled = true

  if isLoggedInUser() = true

    authInfo = m.global.authInfo

    if authInfo.parentalrating = invalid or authInfo.parentalrating <> 3
      bEnabled = false
    end if

  end if

  return bEnabled
End Function


Function isParentalControlsTeensLevel() as Boolean
  tubiLog("ContentController.isParentalControlsTeensLevel")
  bEnabled = false

  if isLoggedInUser() = true

    authInfo = m.global.authInfo

    if authInfo.parentalrating = invalid or authInfo.parentalrating = 2
      bEnabled = true
    end if

  end if

  return bEnabled
End Function


Function refreshAllDetailScreens()
  ' Refresh all detail screens so they have proper history that's been loaded or unloaded
  for i = 0 to m.screenStack.getChildCount() - 1
    screen = m.screenStack.getChild(i)
    if screen.subType() = "DetailScreen"
      populateDetailScreen(screen, screen.content)
    end if
  end for
End Function


' Content for a category details screen has been updated.
' Any screen that is displaying this category should be updated.
' @sCategoryID: string, the category id we are searching for in the stack
Function refreshStackedUserScreenWithChangedCategory(sCategoryID)
  ' Tell the screen that contains the categroy associated with the passed ID to refresh the next time is is on screen by setting the validUntil variable to 0
  for i = 0 to m.screenStack.getChildCount() - 1
    screen = m.screenStack.getChild(i)
    if screen <> invalid and screen.isSubType("CategoryDetailsScreen")
      content = screen.content
      if content <> invalid and content.id = sCategoryID
        screen.content.validUntil = 0
      end if
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


' Makes the contentGroup (including the screen stack) on the screen visible which indicates the user
' has started the channel, so also send the ActiveEvent.
' Should only happen once per channel launch
Function showContentGroup()
  if m.contentGroup.visible = false
    m.contentGroup.visible = true
    m.trackingLoggingTask.trackEvent = {
      type: "active"
      values: {}
    }
  end if
End Function


Function startChannel()
  tubiLog("ContentController.startChannel")
  focusSideNavOption(m.constants.ui.sideNavIds.home)
  showDefaultHomeScreen()
End Function


' wraps startChannel but forces an age gate if the user is signed out
Function restartChannel()
  tubiLog("ContentController.restartChannel")

  if shouldDisplayInitialContentScreen() = true
    displayInitialContentScreen()
  else
    startChannel()
  end if
End Function


Function restartChannelAfterAgeVerification()
  tubiLog("ContentController.restartChannelAfterAgeVerification")
  restartChannel()
  reloadDefaultHomeScreenContent()
End Function


' a wrapper for the screen cache getter - can overwrite screens in the cache if the passed in screen has
' the same id as a screen already existing in the screen cache
'
' @screen: roSGNode, a screen node
' returns true or false depending if the screen was successfully set
Function setInScreenCache(screen)
  return m.cache.setInScreenCache(screen)
End Function


' a wrapper for the screen cache setter - getting does not remove the screen from the cache
'
' @screenId: string, the id of the screen that is to be retrieved
' returns the screen node or invalid if no screens were found with the passed in id
Function getFromScreenCache(screenId)
  return m.cache.getFromScreenCache(screenId)
End Function


' a wrapper for the screen cache deleter - we may need to remove screens from the cache in the case of content loading errors
' returns true if the screen was successfully deleted, otherwise returns false
'
' @screenId: string, the id of the screen that is to be removed
Function deleteFromScreenCache(screenId)
  return m.cache.deleteFromScreenCache(screenId)
End Function


' Destroy the screen (from cache) that is associated with the passeed sScreenID param.
' If the screen is the current screen, then go back to the previous screen
' @sScreenID: String, The ID associated with the screen to be destroyed
Function destroyScreen(sScreenID)
  if isString(sScreenID) = true and sScreenID <> ""
    currentScreen = getCurrentScreen()
    deleteFromScreenCache(sScreenID)

    '//Take user to previous screen
    if currentScreen <> invalid and currentScreen.id = sScreenID
      popScreen(true, false)

      ' focus the side nav selection that corresponds to the new to screen
      newCurrentScreen = getCurrentScreen()
      if newCurrentScreen <> invalid
        sideNavId = m.constants.ui.screenIdToSideNavId[newCurrentScreen.id]
        focusSideNavOption(sideNavId)
      end if
    end if

  end if
End Function


' a wrapper for emptying the screen cache
Function emptyScreenCache()
  return m.cache.emptyScreenCache()
End Function


'a wrapper for setting a content in cache
Function setInContentCache(content)
  return m.cache.setInContentCache(content)
End Function


'a wrapper for getting a content from cache
'@contentId: String, The constants.ui.contentIds associated with content.
Function getFromContentCache(contentId)
  return m.cache.getFromContentCache(contentId)
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


' @shouldRefetchHomescreen: boolean, do not refresh homescreen if set to false
Function setContentToRefreshAllPersonalizedScreens(shouldRefetchHomescreen = true)
  tubiLog("ContentController.setContentToRefreshAllPersonalizedScreens")
  if shouldRefetchHomescreen = true
    homescreenId = m.constants.ui.screenIds.homeScreen
    homescreen = getFromScreenCache(homescreenId)

    ' set the homescreen content to refresh immediately if it's the top screen or if it's not
    ' the top screen, so that it can load in the background and be ready for consumption when
    ' the user next lands on the homescreen
    if homescreen <> invalid
      fetchHomescreen(homescreen)
    end if
  end if

  ' set the content of other screens to refresh once they gain focus
  setContentToRefresh(m.constants.ui.screenIds.tvScreen)
  setContentToRefresh(m.constants.ui.screenIds.movieScreen)
  setContentToRefresh(m.constants.ui.screenIds.espanolScreen)
  setContentToRefresh(m.constants.ui.screenIds.bestKnownScreen)
  setContentToRefresh(m.constants.ui.screenIds.nostalgiaScreen)
  setContentToRefresh(m.constants.ui.screenIds.channelListScreen)
  setContentToRefresh(m.constants.ui.screenIds.categoryListScreen)
  setContentToRefresh(m.constants.ui.screenIds.epgScreen)
  setContentToRefresh(m.constants.ui.screenIds.sportsEPGScreen)
  setContentToRefresh(m.constants.ui.screenIds.newsEPGScreen)
  setContentToRefresh(m.constants.ui.screenIds.entertainmentEPGScreen)
End Function


' Callback for when a navigateWithinPageInfo has been updated - sends the navigate_within_page event
Function onNavigateWithinPageInfoChange(msg)
  navigateWithinPageInfo = msg.getData()
  sendNavigateWithinPageInfo(navigateWithinPageInfo)
End Function


Function sendNavigateWithinPageInfo(navigateWithinPageInfo)
  if navigateWithinPageInfo <> invalid
    m.trackingLoggingTask.trackEvent = {
      type: "navigate_within_page"
      values: navigateWithinPageInfo
    }
  end if
End Function


' Callback for when a componentInteractionInfo has been updated - sends the component_interaction event
Function onComponentInteractionInfoChange(msg)
  componentInteractionInfo = msg.getData()
  sendcomponentInteractionInfo(componentInteractionInfo)
End Function


Function sendcomponentInteractionInfo(componentInteractionInfo)
  if componentInteractionInfo <> invalid
    m.trackingLoggingTask.trackEvent = {
      type: "component_interaction"
      values: componentInteractionInfo
    }
  end if
End Function


Function homeScreenBackgroundUpdated(msg)
  tubiLog("ContentController.homeScreenBackgroundUpdated")
  homeScreen = msg.getRoSGNode()
  setHomeScreenBackground(homeScreen)
End Function


' Is the current screen a home screen?
Function isCurrentScreenHomeScreen()
  bReturn = getCurrentScreen() <> invalid and getCurrentScreen().isSubType("HomeScreen")
  return bReturn
End Function


'Is the current Screen a epg Screen?
Function isCurrentScreenEPGScreen()
  bReturn = getCurrentScreen() <> invalid and getCurrentScreen().isSubType("EPGScreen")
  return bReturn
End Function


Function setHomeScreenBackground(homeScreen)
  if homeScreen <> invalid and isCurrentScreenHomeScreen() = true
    contentType = invalid
    if homeScreen.contentFocused <> invalid
      contentType = homeScreen.contentFocused.type
    end if
    videoPreviewState = getVideoPreviewState()
    if videoPreviewState = "playing" or videoPreviewState = "paused"

      m.backgroundGroup.backgroundInfo = {
        type: m.constants.ui.backgroundTypes.epg
        uriList: [] ' setting uriList as empty, because don't need to rotate the background poster when video preview is playing
      }
    else
      m.backgroundGroup.backgroundInfo = {
        type: getBackgroundtype(homeScreen.backgroundUriList, contentType)
        uriList: homeScreen.backgroundUriList
      }
    end if
  end if
End Function


Function onSponsorshipBackgroundChanged(msg)
  setSponsorshipBackground(msg.getData())
End Function


' @url: string, The URL of the Sponsorship Background
Function setSponsorshipBackground(url)
  m.SponsorBground.uri = url
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


Function onCategoryScreenBackgroundChange(msg)
  TubiLog("ContentController.onCategoryScreenBackgroundChange")
  categoryDetailsScreen = msg.getRoSGNode()
  m.backgroundGroup.backgroundInfo = {
    type: getBackgroundtype(categoryDetailsScreen.backgroundUriList)
    uriList: categoryDetailsScreen.backgroundUriList
  }
End Function

Function displayDefaultBackground()
  TubiLog("ContentController.displayDefaultBackground")
  m.backgroundGroup.backgroundInfo = {
    type: getBackgroundtype([m.defaultBackgroundUri])
    uriList: [m.defaultBackgroundUri]
  }
End Function


Function onScreenBackgroundUpdated(msg)
  TubiLog("ContentController.onScreenBackgroundUpdated")
  screen = msg.getRoSGNode()
  if screen <> invalid
    m.backgroundGroup.backgroundInfo = {
      type: getBackgroundtype(screen.backgroundUriList)
      uriList: screen.backgroundUriList
    }
  end if
End Function


' fireAppLoadTimeEvent
'
' Fire off a log to a server so we can track how long it took since the app was started
Function fireAppLoadTimeEvent(loadTime)
  messageInfo = {
    loadtime: loadTime
    model: m.constants.deviceInfo.model
  }
  tubiLog(FormatJSON(messageInfo), "info", "clientInfo", "time-to-load") 'send info to server
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
    else if backgroundUriList[0] = m.marketingBackgroundUri
      backgroundType = m.constants.ui.backgroundTypes.marketingScreen
    else if contentType = m.constants.ui.contentTypes.linear
      backgroundType = m.constants.ui.backgroundTypes.linear
    else if contentType = m.constants.ui.contentTypes.epg
      backgroundType = m.constants.ui.backgroundTypes.epg
    else
      backgroundType = m.constants.ui.backgroundTypes.topRight
    end if
  end if
  return backgroundType
End Function


' show an upgrade modal if constants says that we should
Function showUpgradeModal(shouldAlert, trackingLib, trackingTask)
  if shouldAlert = true
    title = getTranslation("dialog_updateVersion_title")
    message = getTranslation("dialog_updateVersion_description")

    buttons = [getTranslation("dialog_button_close")]

    dialogEvent = {
      type: "dialog"
      values: {
        dialog_type: "UPGRADE" 'DialogType enum
        pageOneof: trackingLib.getAnalyticsPage("home_page", {content_mode: "CONTENT_MODE_UNKNOWN"})
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


Function isDeviceInUSorCA()
  return (m.constants.deviceInfo.countryCode = "US" or m.constants.deviceInfo.countryCode = "CA")
End Function


Function shouldShowAgeGate()
  if isDeviceInUSorCA() <> true
    return false
  else if m.constants.settings.mode <> "production" and m.constants.settings.skipAgeGate = true
    return false
  end if

  return true
End Function


' onCustomSuspend will be triggered when user presses Home/Labeled channel key
' Checking appExit reason and starting the appSuspendTimer in order to validate during resumeHandler callback
Function onCustomSuspend(msg)
  tubiLog("ContentController.onCustomSuspend")
  customSuspendArgs = msg.getData()

  if customSuspendArgs.lastSuspendOrResumeReason = "home"
    sendNielsenPing(m.constants.thirdParty.nielsen.pingTypes.sessionEnd)
    m.appSuspendTimer.Mark()
    currentScreen = getCurrentScreen()
    ' if the current screen is videoplayer, return to detail screen so that it will update historyPosition and remove video screen from stack and show previous screen from stack
    if currentScreen <> invalid and currentScreen.id = m.constants.ui.screenIds.videoPlayerScreen
      ' don't send analytics event when user presses "home" button during playback, so sending param as false
      stopVideoContent(currentScreen)
      returnToDetailScreenFromVideo(false)
    else
      ' if the focus is on live TV row, stop the playback
      linearVideoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
      if linearVideoPlayer <> invalid
        linearVideoPlayer.closeTransport = true
        linearVideoPlayer.control = "stop"
      end if
    end if
    'Modals with type errorDialog should made invisible and app should restarted on app relaunch.
    'Modals with type actionDialog should be closed and app should resume from the current screen
    modal = getTopModal()
    if modal <> invalid
      if modal.instantResumeAction = m.constants.instantResumeActions.restartApp
        'making visible = false to avoid showing error modal while app on relaunch
        modal.visible = false
      else if modal.instantResumeAction = m.constants.instantResumeActions.closeDialog or modal.instantResumeAction = m.constants.instantResumeActions.startChannel
        closeModal(modal)
        if currentScreen <> invalid
          currentScreen.setFocus(true)
        end if
      end if
    end if
  end if
End Function


' onCustomResume will be triggered during Instant Resume
' For guest user,
' it will check lastAppSuspendInSecs,
' if the lastAppSuspendInSecs is more than 24hours, it removes all screens from stack & destroys scene and relaunches the app from beginning
' if the lastAppSuspendInSecs is equal/less than 24hours, it resumes app where the user left off or suspended.
' For LoggedIn user,
' it resumes app where the user left off or suspended.
' also it restarts app every 4 days to retrieve starter/remote components
Function onCustomResume(msg)
  tubiLog("ContentController.onCustomResume")
  args = msg.getData()

  lastSuspendOrResumeReason = invalid
  customResumeLaunchParams = invalid

  if args <> invalid
    customResumeLaunchParams = args.launchParams
    lastSuspendOrResumeReason = args.lastSuspendOrResumeReason
  end if

  if lastSuspendOrResumeReason = "home" and customResumeLaunchParams <> invalid
    currentScreen = getCurrentScreen()

    lastAppSuspendInSecs = m.appSuspendTimer.TotalSeconds()
    lastAppRestartInDays = m.lastAppRestartTimer.TotalSeconds() / 24 / 60 / 60

    if m.Request = invalid
      m.Request = TubiRequest(m.constants.settings)
    end if

    if (customResumeLaunchParams.contentId <> invalid and customResumeLaunchParams.mediaType <> invalid) or customResumeLaunchParams.page <> invalid
      ' if resuming due to a deeplink, restart the app. Deeplinking into a non standard state creates
      ' lots of edge cases, so for consistency, restarting the app is easiest.
      restartApp()
    else if isLoggedInUser() = false and (lastAppSuspendInSecs > m.constants.timers.coppaFailTimeout or lastAppRestartInDays >= 4)
      ' For guest users, if the time between last suspend and current resume is more than 24 hours,
      ' disable Instant Resume & relaunch app from scratch.
      ' Also every 4 days once the app restarts in order to get starter/remote components
      restartApp()
    else if isLoggedInUser() = true and lastAppRestartInDays >= 4
      ' For loggedIn users, every 4 days once the app will be restarted as it needs to fetch starter/remote components
      restartApp()
    else
      'Removes the RFIScreen
      if m.billing <> invalid
        m.billing.unobserveFieldScoped("userData")
        m.billing = invalid
      end if
      modal = getTopModal()
      ' Modal gets removed/hidden based on the instantResumeAction when the app was suspended.
      ' Modals that inform a user about an action have instantResumeAction = "closeDialog" and are
      ' removed while suspending the app. Modals that display errors have instantResumeActions of
      ' "restartApp" for which we set visibility to false in customSuspend and then restart the app
      ' during onCustomResume. Screens that have instantResumeAction of "startChannel" return the
      ' user to the homescreen during onCustomResume.
      ' Functionality that requires the app to restart is given precedence over functionality that
      ' starts the channel or resumes the app.

      if modal <> invalid
        if modal.instantResumeAction = m.constants.instantResumeActions.restartApp
          restartApp()
        else if modal.instantResumeAction = m.constants.instantResumeActions.startChannel
          sendNielsenPing(m.constants.thirdParty.nielsen.pingTypes.sessionStart)
          'calling startChannel() instead of restartChannel() since restartChannel() can land a user on the ICTS screen, but we only want users to land on the home screen
          startChannel()
        end if
      else if currentScreen <> invalid
        if currentScreen.instantResumeAction = m.constants.instantResumeActions.restartApp
          restartApp()
        else if (lastAppSuspendInSecs >= 1200 and currentScreen.id = m.constants.ui.screenIds.settingsScreen)
          sendNielsenPing(m.constants.thirdParty.nielsen.pingTypes.sessionStart)
          'user is on the settings page and returns to the app after 20 or more minutes then retun to the homescreen
          startChannel()
        else if currentScreen.instantResumeAction = m.constants.instantResumeActions.startChannel
          sendNielsenPing(m.constants.thirdParty.nielsen.pingTypes.sessionStart)
          'calling startChannel() instead of restartChannel() since restartChannel() can land a user on the ICTS screen, but we only want users to land on the home screen
          startChannel()
        else
          sendNielsenPing(m.constants.thirdParty.nielsen.pingTypes.sessionStart)
          resumeApp()
        end if
      else
        'Unknown state, backup solution to restart app.
        restartApp()
      end if
    end if
  else if lastSuspendOrResumeReason = "screensaver"
    ' Do nothing, but leave this as a place holder.
    ' The app will resume as normal for the screensaver.
  end if
End Function


' restarts the app from beginning of the line in order to retrieve starter/remote components
Function restartApp()
  tubiLog("ContentController.restartApp")
  clearScreenStack()
  m.top.disableInstantResume = true

End Function


' resumes the app where the user left off.
Function resumeApp()

  tubiLog("ContentController.resumeApp")
  m.deeplinkContent = invalid

  currentScreen = getCurrentScreen()
  if currentScreen <> invalid
    if currentScreen.id = "linearVideoPlayerScreen"
      ' if the current screen is linearVideoPlayerScreen, then re-start the playback.
      ' We restart to make sure that the proper video start time is included in the manifest
      associatedScreenId = currentScreen.associatedScreenId
      originalLinearContent = currentScreen.originalContent
      playLinearVideoContent(originalLinearContent, false, associatedScreenId)
    else if isAnEPGScreen(currentScreen)
      ' if current Screen epg Screen,  It will start counting the remaining seconds and full videoscreen will take over when it reaches 0
      ' without content which will be a blank screen. To avoit it,  stop the counter and refresh the EPGScreen videoplay
      stopCountdownTimer()
      currentScreen.refreshEPGScreenVideoPlay = false
    end if

  end if


  ' when channel resumes,
  ' send page load event here only if the channel is not launched via deeplink
  ' because the page load event is handled & already happening during deeplink
  if m.deeplinkContent = invalid and currentScreen <> invalid
    screenTrackingLoad(currentScreen.trackingPageInfo)
  end if

  ' send active event when channel resumes
  m.trackingLoggingTask.trackEvent = {
    type: "active"
    values: {
      resume: true
    }
  }

  ' send AppResumeComplete beacon when channel resumes
  myScene = m.top.getScene()
  myScene.signalBeacon("AppResumeComplete")

End Function


Function onFullscreenCountdown()
  tubiLog("ContentController.onFullscreenCountdown")
  screen = getCurrentScreen()
  if screen <> invalid
    if screen.id = m.constants.ui.screenIds.homeScreen or screen.id = m.constants.ui.screenIds.linearTVScreen
      if getExperimentResource("roku_linear_epg", "roku_linear_epg_v5", false).update_homescreen = true
        nCurrentCount = m.fullscreenCountdown
        nNewCount = nCurrentCount - 1
        setPlayerCountDownChange(nNewCount)
      else
        nCurrentCount = screen.fullscreenCountdown
        nNewCount = nCurrentCount - 1
        screen.fullscreenCountdown = nNewCount
      end if
      if nNewCount <= 0
        selectLinearContent(screen.contentFocused)
      end if
    else if isAnEpgScreen(screen) = true
      nCurrentCount = screen.fullscreenCountdown
      nNewCount = nCurrentCount - 1
      screen.fullscreenCountdown = nNewCount
      if nNewCount <= 0
        selectLinearContent(screen.linearChannelToPlay)
      end if
    end if
  end if
End Function


' Sends a ping request to Nielsen that a session or video playback has started or ended.
'
' @pingType: string, one of the following "start_session", "start_stream", "end_session", "end_stream"
' @content: roSGNode, a content node with an id. Only required when pingType = "start_stream" or "end_stream"
' @successCallback: roFunction, a callback to run after getting a successful network response
' @errorCallback: roFunction, a callback to run after getting an error network response
Function sendNielsenPing(pingType, content = invalid, successCallback = invalid, errorCallback = invalid)
  Auth = TubiAuth(m.constants, m.Request)
  adLib = TubiAdsLimited(m.constants, Auth)
  nielsenReqInfo = adLib.getNielsenPingRequestInfo(m.constants, pingType, content)

  m.makeRequest({
    url: nielsenReqInfo.url
    requestType: m.constants.reqNames.generic
    options: nielsenReqInfo.options
    successCallback: successCallback
    errorCallback: errorCallback
    silenceCallbackWarnings: true
    responseType: "string"
    retries: 0
  })
End Function
