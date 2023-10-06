Function init()
  tubiLog("")
  tubiLog("Init Scenegraph----------------")
  m._ = rodash()

  m.constants = getConstantsFromGlobal()

  ' Timer to find last time the app restarted
  m.lastAppRestartTimer = CreateObject("roTimespan")

  ' Timer to find last time the app suspended
  m.appSuspendTimer = CreateObject("roTimespan")

  '//When ContentController initializes, clear all translations and reset translations in case the
  ' remote component translations are different from the local translations.
  initTranslations()

  m.mainTask = createObject("roSGNode", "MainTask") ' initiate MainTask
  m.mainTask.observeFieldScoped("isHdmiStatusOk", "onIsHdmiStatusOkChange")
  m.mainTask.observeFieldScoped("screensaverTimeout", "onScreensaverTimeoutChange") ' Declared in ScreensaverHelpers.brs
  m.mainTask.observeFieldScoped("lowMemoryEventInfo", "onLowMemoryEventInfoChange")


  generalTask = createObject("roSGNode", "ControllerGeneralTask") ' initiate GeneralTask

  ' Initiate GeneralTaskModule by passing caller context.
  ' Calling GeneralTaskModule() will append methods to the local m.
  ' DO NOT overwrite m variable methods/properties which belongs to GeneralTaskModule.
  GeneralTaskModule(m, generalTask)

  m.Request = TubiRequest(m.constants.settings)
  Auth = TubiAuth(m.constants, m.Request)
  m.NodeHelpers = TubiNodeHelpers()
  apiUtilsLib = ApiUtils(m.constants)
  m.Bookmarks = TubiBookmarks(m.constants)
  m.Tracking = TubiTracking(m.constants, m.Request, Auth)
  experiments = TubiExperiments(m.constants)
  m.cmsApi = CmsApi(m.constants, m.Request, Auth, apiUtilsLib, experiments)
  m.userDeviceApi = UserDeviceApi(m.constants, apiUtilsLib)
  m.tensorapi = TensorApi(m.constants, m.Request, Auth)
  m.rainmakerApi = RainmakerApi(m.constants)
  m.pubSub = TubiPubSub(m)

  m.background = m.top.findNode("ContentBackground")
  m.SponsorBground = m.top.findNode("SponsorshipBackgroundGroup")

  m.uiGroup = m.top.findNode("uiGroup")
  m.contentGroup = m.top.findNode("ContentGroup")
  m.SideNav = m.top.findNode("SideNav")

  m.videoPreviewPlayer = m.top.findNode("videoPreviewPlayer")
  if getExperimentResource("roku_screensaver", "roku_screensaver_v2", false).enabled = true then
    m.videoPreviewPlayer.disableScreensaver = true
  end if

  m.LinearPlayerGroup = m.top.findNode("LinearPlayerGroup")
  m.LinearPlayerGroupAboveScreenStack = m.top.findNode("LinearPlayerGroupAboveScreenStack")
  m.LinearCountdownTimer = m.top.findNode("LinearCountdownTimer")

  m.backgroundGroup = m.top.findNode("BackgroundGroup")
  m.logoGroup = m.top.findNode("logoGroup")
  m.logo = m.logoGroup.findNode("tubiLogo")
  m.logoKids = m.logoGroup.findNode("tubiKidsLogo")
  m.logoEspanol = m.logoGroup.findNode("tubiEspanolLogo")
  m.logoFIFA = m.logoGroup.findNode("tubiFIFALogo")
  m.clock = m.top.findNode("clock")
  m.spinner = m.top.findNode("ContentControllerSpinner")
  m.tubiToast = m.top.findNode("tubiToast")
  m.LinearVideoPlayerSpinner = m.top.findNode("LinearVideoPlayerSpinner")
  m.playerFullscreenCountdownTimer = m.top.findNode("PlayerFullscreenCountdownTimer")
  m.resumeAllowedTimer = m.top.findNode("ResumeAllowedTimer")
  m.screensaverTimer = m.top.findNode("screensaverTimer")
  m.screensaverTimer.observeFieldScoped("fire", "onScreensaverTimerFired") ' Declared in ScreensaverHelpers.brs

  m.screenStack = m.top.findNode("ScreenStack")
  m.screenStack.observeFieldScoped("isEmpty", "onScreenStackEmpty")
  m.screenStack.observeFieldScoped("currentUpdated", "onScreenChange")

  ' the screen cache holds the top level screens in memory so they are not recreated and reloaded unnecessarily
  m.cache = TubiCache(m.NodeHelpers, m.constants.ui.cacheableScreenIds, m.constants.ui.permanentlyCachedContentIds)

  ' This is an associative array that keeps track of when pixels are sent out when sponsored containers are displayed. The pixels should only be sent once per page load.
  m.sentSponsorPixels = {}

  ' Keep track of when a user starts a path to watch a video that is contained in a sponsored container. This ID will be passed to rainmaker for an ad request and be used to play a sponsored preroll ad
  m.videoSponsorExposureId = ""

  'This is will bind EPG channel api call with all related EPG program calls. Any program calls returned because of previous epg channel list will be discarded.
  m.epgFetchUniqueId = 0

  'This is used only within the very first session to keep track if user has already seen the welcome registration modal, so that welcome reg modal is not shown multiple times.
  m.hasRegModalBeenShownWithinNewUserSession = false

  'This variable will keep track of whether user has seen the LiveTV modal within the session
  m.shouldShowLinearEducationModal = false 'remove this variable if roku_linear_epg_education_modal_over_homegrid does not get graduated.

  ' Set up global services
  m.metadataFetchTask = m.top.findNode("MetadataFetchTask")
  m.global.addField("metadataFetchTask", "node", false)
  m.global.metadataFetchTask = m.metadataFetchTask

  m.trackingLoggingTask = m.top.findNode("TrackingLoggingTask")
  m.global.addField("trackingLoggingTask", "node", false)
  m.global.trackingLoggingTask = m.trackingLoggingTask

  ' initialize states needed for various parts of kids mode
  m.kidsModeFeatureOn = false 'Should the kids Mode feature be made available for the user to interact with
  if m.constants.deviceInfo.countryCode <> invalid AND isKidsModeAvailableByCountry() = true
    m.kidsModeFeatureOn = true
  end if

  ' TODO: Once MetadataFetchTask functionality is refactored to use the GeneralTask remove uiMode from m.global
  m.global.addField("uiMode", "string", false)
  setUiMode(m.constants.ui.modes.standard)
  theme = getThemeFromGlobal()
  if theme <> invalid
    m.background.color = theme.backgroundColor
  end if

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
  'this variable is used to stop unnecessary execution of the entire showHideLogo function when content been focused.
  m.logoType = m.constants.logoType.tubi

  m.defaultBackgroundUri = m.constants.ui.uris.defaultBackground
  m.marketingBackgroundUri = m.constants.ui.uris.marketingBackground

  ' Global state
  m.global.addField("bookmarkIds", "node", false)
  m.global.bookmarkIds = CreateObject("roSGNode", "BookmarkContentNode")
  m.global.addField("historyIds", "node", false)
  m.global.historyIds = CreateObject("roSGNode", "HistoryContentNode")
  m.global.addField("likeIds", "node", false)
  m.global.likeIds = CreateObject("roSGNode", "LikeContentNode")
  m.global.addField("linearLikeIds", "node", false)
  m.global.linearLikeIds = CreateObject("roSGNode", "LikeContentNode")


  m.global.addField("authInfo", "assocarray", false)
  m.global.authInfo = invalid ' indicates not logged in

  ' isNewUser global variable is needed to show/hide onboarding, signup button on detail screen
  ' isNewUser will be set to true, if there is entry on firstVisit registry. Otherwise false
  m.global.addField("isNewUser", "boolean", false)
  m.global.isNewUser = false

  ' checking the firstVisit in registry and setting the isNewUser global based on it
  if Auth.getFirstVisit() = -1
    m.global.isNewUser = true
    Auth.setFirstVisit()
  end if

  m.authInfoReceived = false 'is the auth info returned from the registry
  m.authInfoRefreshed = true 'is the auth info refreshed after receiving a deeplink with a refresh token
  m.ageVerificationComplete = false 'has the user verified their age?
  m.getServerPersistentDataComplete = false 'did we finish fetching serverPersistentData. either user/device based on user logged in status.
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

  ' holds state so we don't fire the app load beacon more than once
  m.appLoadedBeaconFired = false

  m.trackingLoggingTask.trackEvent = {
    trackType: "startApp"
  }

  ' Holds the value for user/device level settings. For ex: isVideoPreviewOn  or Selected Audio track.
  m.pub_serverPersistentData = createObject("roSGNode", "ServerPersistentData")

  ' Braze Task and Braze helper instance.
  m.brazeTask = invalid
  m.braze = invalid

  ' For now we will support only one message queue. If at all we need to more flexible will add in future.
  ' For now we are queuing message if the user is in parental controls / kids mode or if there is screen in process of loading.
  ' Used for braze integration.
  m.queuedInAppMessage = invalid

  ' Status of user consent check will be used for GDPR. If user consent is required and not given then we will present the user with consent screen.
  m.isConsentCheckComplete = false
  ' Holds information related to individual consents and also other GDPR related values like privacy center flags.
  ' Sample data. {"consentRequired": true, [{"key": "behavioral_advertising","subtitle": "Tubi may use your information to make inferences and predict your potential areas of interest.","title": "Targeted Advertising","value": "required", "isRequired": true}]}
  m.consentSettings = {}

  m.rokuContinueWatchingApi = RokuContinueWatchingApi(m.constants)
End Function


' onFadeInContentController callback will be triggered once the launch animation logo got finished
Function onFadeInContentController()
  tubiLog("ContentController.onFadeInContentController")
  fadeInUiGroup = customFadeIn(m.uiGroup, 2, 0.5)
  if fadeInUiGroup <> invalid
    fadeInUiGroup.observeFieldScoped("state", "onUiGroupFadeStateChange")
  else
    m.top.removeStartUpScreens = true
  end if

  currentScreen = getCurrentScreen()
  'if m.linearScreenAfterFn is set in that case execute linearScreenAfterFn
  if m.linearScreenAfterFn <> invalid
    m.linearScreenAfterFn()
    m.linearScreenAfterFn = invalid
  else if currentScreen <> invalid AND currentScreen.isInFocusChain() = false

    ' isDialogOpenAtStartup will be true if top screen is one of the dialogScreens.
    ' focus currentScreen only if the upgradeModal is closed or disabled

    isDialogOpenAtStartup = false
    for i = 0 to m.top.getChildCount() - 1
      screen = m.top.getChild(i)

      if screen.isSubtype("BaseDialogScreen") = true
        isDialogOpenAtStartup = true
        exit for
      end if

    end for

    if isDialogOpenAtStartup = false
      currentScreen.setFocus(true)
    end if

    if currentScreen.id = "detailScreen" AND m.detailScreenAfterFn <> invalid
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
  showSimpleInstantResumableModal(title, message, buttons, dialogEvent, m.trackingLoggingTask, onMaturePlayWarningSignInModalButtonSelected)
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
Function onMaturePlayWarningSignInModalButtonSelected()
  startSignIn(onMatureContentWarningSignInCompleted)
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
  tubilog("ContentController.openSideNavFromButton")
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

  if press then
    ' for autohide support, bring the UI back on any keypress
    if key = "back"
      if m.enteredFromDeepLink = true
        m.enteredFromDeepLink = false
      end if

      ' Adding a check to see if the user has completed consent flow.
      ' if not then showing exit dialog since we have not loaded any screens since it is pre-requiste for loading home screen.
      currentScreen = getCurrentScreen()
      if currentScreen <> invalid AND currentScreen.id = m.constants.ui.screenIds.consentScreen
        displayExitModal(currentScreen.trackingPageInfo)
      else if m.SideNav.opened = false
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
          if newTopScreen <> invalid
            if newTopScreen.hasField("enabled") then
              newTopScreen.enabled = true
            end if

            if newTopScreen.id = m.constants.ui.screenIds.espanolScreen
              setUiMode(m.constants.ui.modes.latino)
            end if

            sideNavId = m.constants.ui.screenIdToTopNavId[newTopScreen.id]
            if sideNavId <> invalid
              focusSideNavOption(sideNavId)
            end if
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
            ' which will be set in fireAppLoadBeacon() if the beacon hasn't fired yet
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
      if key = "left" AND m.screenStack.isInFocusChain() = true
        if m.sideNav.visible = true
          '//The LEFT Key has been pressed, now display menu and focus on menu
          openSideNavFromButton() '//"BUTTON_LEFT"
          bReacted = true
        end if
      else if (key = "right" OR key = "left") AND isSideNavActive() = true
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
  if m.top.hasFocus() = true then
    ' If this is called outside the if it will get called every focus change in the entire application so moving in here
    tubiLog("ContentController.onComponentFocus")
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
    m.logoGroup.visible = false
  else
    m.logoGroup.visible = true
  end if
End Function


''''''''''''''''''''''
' onExitAppModalButtonSelected
'
' handles the response of a user who has been presented an exit app modal
Function onExitAppModalButtonSelected()
  sendNielsenPing(m.constants.thirdParty.nielsen.pingTypes.sessionEnd, invalid, setExitAppWrapper, setExitAppWrapper)
  m.trackingLoggingTask.trackEvent = {
    type: "exit"
    values: {}
  }
End Function


' setExitWrapper wraps setExitApp() and is used when the app should close after some call to
' the m.makeRequest() has completed (like sending an end session ping to Nielsen).
' The @response param is not used but will be set by the generalTaskModule,
' and as such is necessary.
'
' @_response: string or assocArray, string if request was successful, AA if request errored.
Function setExitAppWrapper(_response)
  setExitApp()
End Function


Function setExitApp()
  m.top.exitApp = true
End Function


' This function is used to get rid of unused items in the registry due to removal features, unused experiments, etc.
' Each line that removes a registry item should include the date of when the the line is suspected to be included in production.
' We can remove the lines as they get stale. At times this function will not have any lines, but we can still include a call to the
' function for future reference.
Function cleanRegistry()
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
  cleanRegistry()

  if m.authInfoReceived <> true
    ' checks if the initial auth info has been pulled from the registry
  else if m.startupArgsReceived <> true
    ' checks if the startupArgs have been received from main thread
  else if m.authInfoRefreshed <> true
    ' checks if auth info has been received after a deeplink from external tubi device (iOS) supplied a refresh token
    ' if m.authInfoReceived is false, it means that a refresh token has been supplied
    authInfo = m.global.authInfo
    if authInfo = invalid OR (authInfo <> invalid AND authInfo.userId = invalid)
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
  else if m.getServerPersistentDataComplete <> true
    getServerPersistentData(startUserExperience)
  else if m.isConsentCheckComplete <> true
    getConsent(onInitialGetConsentRequestComplete)
  else if shouldShowAgeGate() = true AND m.ageVerificationComplete <> true
    ' check if we have age information for the user
    if isLoggedInUser() = true
      authInfo = m.global.authInfo
      if authInfo.hasAge <> true
        ' the user is a signed in user who has not been age verified, we should:
        ' 1) check if the backend has an age for the user
        ' 2) if not, show the age verification screen
        ' 3) upon getting a valid birthdate for the user, PATCH the user record on the backend
        checkBirthdayInfo = m.userDeviceApi.checkBirthdayInfo()
        m.makeRequest({
          url: checkBirthdayInfo.url
          requestType: m.constants.reqNames.checkBirthdayInfo
          options: checkBirthdayInfo.options
          successCallback: onBirthdayCheckSuccess
          errorCallback: onBirthdayCheckError
          responseType: "assocarray"
        })
      else
        ' the user is a signed in user who has been age verified, so set m.ageVerificationComplete = true
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

    showContentGroupAndHideSpinner()

    sendNielsenPing(m.constants.thirdParty.nielsen.pingTypes.sessionStart)
    sendDeviceLog()

    setUiModeFromState()

    ' If new user, save the preference secondSessionLinearNotWatched as true to indicate they have not watched the liveTV yet.
    if isNewUser() = true
      saveServerPersistentData({
        "secondSessionLinearNotWatched": true
      }, "device")
    else if m.pub_serverPersistentData.secondSessionLinearNotWatched = true
      m.shouldShowLinearEducationModal = true
    end if

    if m.enteredFromDeepLink = true
      tubiLog("ContentController detected deep link request")
      ' we were asked to deep link into a content item. Go to it
      ' whether we were logged in or not.
      handleDeeplink()
    else
      startChannelFromAppLoad()
    end if

    if getConsentOptOutStatusByKey(m.constants.consentKeys.marketing) = false
      configureBrazeAndInitializeTask()
    end if
  end if
End Function



' sendDeviceLog will check deviceInfo and send device-info to logging API
Function sendDeviceLog()

  deviceInfo = {
    isVideoPreviewOn: (isVideoPreviewOn() = true)
  }
  tubiLog(FormatJSON(deviceInfo), "info", "clientInfo", "device-info", 0.1) 'send info to server

End Function


' is triggered when the args that are passed to main, are passed into the SG thread to the contentController.
' this is one of the pre-requisites to starting the SG user experience.
Function onStartupArgs()
  m.deeplinkContent = invalid
  startupArgs = m.top.startupArgs
  if startupArgs <> invalid then
    m.deeplinkContent = createDeeplinkContentFromStartupArgs(startupArgs)
    utmCampaignConfig = generateUtmCampaignConfig(startupArgs)
    m.cmsApi.setUtmCampaignConfig(utmCampaignConfig)
  end if

  externalAuthInfo = getExternalAuthInfoFromStartupArgs(startupArgs)

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

      if currentScreen <> invalid AND currentScreen.hasField("handlesTransportVoiceRequests") AND currentScreen.handlesTransportVoiceRequests = true
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

  if args.refreshToken <> invalid AND args.userId <> invalid AND args.deviceId <> invalid AND args.entry <> invalid
    if args.refreshToken.unescape() <> "" AND args.userId.unescape() <> "" AND args.userId.unescape() <> "0" AND args.deviceId.unescape() <> ""
      if Lcase(args.entry) = "iphone" OR Lcase(args.entry) = "ipad" OR Lcase(args.entry) = "ios" OR Lcase(args.entry) = "android"
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


' called when a user's My List/Bookmarks/Queue is updated
Function handleQueueChange()
  if isLoggedInUser() = true
    ' make request to get bookmarks/queue ids
    getQueueIds(onQueueRefresh)

    ' update My List containers on various home screens
    setDirtyUserCategories(m.constants.ui.categoryIds.queue)

    '//when queue changes, then indicate that the myStuff screen should reload
    setContentToRefresh(m.constants.ui.screenIds.myStuffScreen)
  end if
End Function


' called when a user's History is updated
Function handleHistoryChange()
  if isLoggedInUser() = true
    ' make request to get history/continue watching ids
    getHistoryIds(onHistoryRefresh)

    ' update Continue Watching containers on various home screens
    setDirtyUserCategories(m.constants.ui.categoryIds.history)

    '//when history changes, then indicate that the myStuff screen should reload
    setContentToRefresh(m.constants.ui.screenIds.myStuffScreen)
  end if
End Function


Function getQueueIds(successCallback = invalid)
  reqInfo = m.userDeviceApi.getQueueReqInfo()
  m.makeRequest({
    requestType: m.constants.reqNames.getQueue
    url: reqInfo.url
    options: reqInfo.options
    successCallback: successCallback
    responseType: "node"
    silenceCallbackWarnings: true
  })
End Function


Function getHistoryIds(successCallback = invalid)
  reqInfo = m.userDeviceApi.getHistoryReqInfo()
  m.makeRequest({
    requestType: m.constants.reqNames.getHistory
    url: reqInfo.url
    options: reqInfo.options
    successCallback: successCallback
    responseType: "node"
    silenceCallbackWarnings: true
  })
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
    categoryReqInfo = m.CmsApi.createCategoryReqInfo(categoryId, isKidsMode, options, invalid, m.constants.ui.screenIds.homeScreen)

    m.makeRequest({
      url: categoryReqInfo.url
      requestType: reqName
      options: categoryReqInfo.options
      successCallback: onReloadUserCategoriesResponse
      errorCallback: onErrorReloadUserCategories
      responseType: "node"
      id: categoryId
      isSignedInUser: isLoggedInUser()
      screenId: m.constants.ui.screenIds.homeScreen
      uiMode: m.uiMode
    })

    '//Apply the movie, TV, and Espanol filters if those screens exist
    if movieScreen <> invalid
      optionMovie = {}
      movieParams = {}
      movieParams["content_mode"] = m.constants.ui.contentMode.movie
      optionMovie.params = movieParams

      categoryReqInfo = m.CmsApi.createCategoryReqInfo(categoryId, isKidsMode, optionMovie, invalid, m.constants.ui.screenIds.homeScreen)

      m.makeRequest({
        url: categoryReqInfo.url
        requestType: reqName
        options: categoryReqInfo.options
        successCallback: onReloadUserCategoriesResponseInMovieScreen
        errorCallback: onErrorReloadUserCategoriesInMovieScreen
        responseType: "node"
        id: categoryId
        isSignedInUser: isLoggedInUser()
        screenId: m.constants.ui.screenIds.movieScreen
        uiMode: m.uiMode
      })
    end if

    if tvScreen <> invalid
      optionTV = {}
      tvParams = {}
      tvParams["content_mode"] = m.constants.ui.contentMode.tv
      optionTV.params = tvParams

      categoryReqInfo = m.CmsApi.createCategoryReqInfo(categoryId, isKidsMode, optionTV, invalid, m.constants.ui.screenIds.homeScreen)

      m.makeRequest({
        url: categoryReqInfo.url
        requestType: reqName
        options: categoryReqInfo.options
        successCallback: onReloadUserCategoriesResponseInTVScreen
        errorCallback: onErrorReloadUserCategoriesInTVScreen
        responseType: "node"
        id: categoryId
        isSignedInUser: isLoggedInUser()
        screenId: m.constants.ui.screenIds.tvScreen
        uiMode: m.uiMode
      })
    end if

    if espanolScreen <> invalid
      optionEspanol = {}
      esParams = {}

      esParams["content_mode"] = m.constants.ui.contentMode.latino
      optionEspanol.params = esParams

      categoryReqInfo = m.CmsApi.createCategoryReqInfo(categoryId, isKidsMode, optionEspanol, m.constants.ui.screenIds.homeScreen)

      m.makeRequest({
        url: categoryReqInfo.url
        requestType: reqName
        options: categoryReqInfo.options
        successCallback: onReloadUserCategoriesResponseInEspanolScreen
        errorCallback: onErrorReloadUserCategoriesInEspanolScreen
        responseType: "node"
        id: categoryId
        isSignedInUser: isLoggedInUser()
        screenId: m.constants.ui.screenIds.espanolScreen
        uiMode: m.uiMode
      })
    end if

    ' needed in case the image sizes on the homescreen are different than the image sizes
    ' on the categoryDetailsScreen. We don't want to add large homescreen images sizes to the
    ' content on the categoryDetailsScreen.
    if isCategoryDetailScreenInStack(categoryId) = true
      optionCategoryDetail = {
        params: {
          content_mode: ""
        }
      }
      categoryReqInfo = m.CmsApi.createCategoryReqInfo(categoryId, isKidsMode, optionCategoryDetail)

      m.makeRequest({
        url: categoryReqInfo.url
        requestType: reqName
        options: categoryReqInfo.options
        successCallback: onReloadUserCategoriesResponseInCategoryDetailScreen
        errorCallback: onErrorReloadUserCategoriesInCategoryDetailScreen
        responseType: "node"
        id: categoryId
        isSignedInUser: isLoggedInUser()
        screenId: m.constants.ui.screenIds.categoryDetailsScreen
        uiMode: m.uiMode
      })
    end if
  end if
End Function


Function onReloadUserCategoriesResponse(handledRequest)
  tubiLog("ContentController.onReloadUserCategoriesResponse")

  ' update the main home screen with the updated user category
  onReloadUserCategoriesInHomeScreen(handledRequest)

  ' inform the category list screen of the updated user category
  categoryListScreen = getFromScreenCache(m.constants.ui.screenIds.categoryListScreen)
  if categoryListScreen <> invalid
    categoryListScreen.reloadUserCategoriesResponse = handledRequest
  end if

End Function


Function onReloadUserCategoriesResponseInCategoryDetailScreen(handledRequest)
  tubiLog("ContentController.onReloadUserCategoriesResponseInCategoryDetailScreen")

  ' inform the category details screen for the specific user category of the update user category content
  if handledRequest <> invalid
    refreshStackedUserScreenWithChangedCategory(handledRequest.id)
  end if
End Function


Function onErrorReloadUserCategoriesInCategoryDetailScreen(response)
  tubiLog("ContentController.onErrorReloadUserCategoriesInCategoryDetailScreen")
  onReloadUserCategoriesInHomeScreen(response, m.constants.ui.screenIds.categoryDetailsScreen)
End Function


' @queueIds: roSGNode, a parent node with children nodes. Each child node representing an item in the user's queue.
Function onQueueRefresh(queueIds)
  tubiLog("ContentController.onQueueRefresh")
  m.global.bookmarkIds = queueIds
  refreshAllDetailScreens()
End Function


' @historyIds: roSGNode, a parent node with children nodes. Each child node representing an item in the user's history.
Function onHistoryRefresh(historyIds)
  tubiLog("ContentController.onHistoryRefresh")
  m.global.historyIds = historyIds
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
    if m.global.theme = invalid OR m.global.theme.id <> m.constants.ui.themeIDs.default
      m.global.theme = m.constants.ui.themes.default
    end if

    m.sideNav.uiMode = mode
    m.backgroundGroup.kidsMode = false
    m.trackingLoggingTask.analyticsAppMode = "DEFAULT_MODE"
    showHideLogo(m.constants.logoType.tubi)

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
    if m.global.theme = invalid OR m.global.theme.id <> m.constants.ui.themeIDs.default
      m.global.theme = m.constants.ui.themes.default
    end if
    m.sideNav.uiMode = mode
    m.backgroundGroup.kidsMode = false
    m.trackingLoggingTask.analyticsAppMode = "LATINO_MODE"
    showHideLogo(m.constants.logoType.tubiEspanol)
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
  if aPixelURLs <> invalid AND aPixelURLs.Count() > 0
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
    if m.guestUserHasAgeInfo.hasAge = false AND m.guestUserHasAgeInfo.expired = false then
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
    if m.global.theme = invalid OR m.global.theme.id <> m.constants.ui.themeIDs.kidsMode
      m.global.theme = m.constants.ui.themes.kidsMode
    end if
    showHideLogo(m.constants.logoType.tubiKids)
    m.backgroundGroup.kidsMode = true
    m.trackingLoggingTask.analyticsAppMode = "KIDS_MODE"
    tellScreensIfKidsModeBeSentToServer()
  end if
End Function


' What boolean value should be sent to the UAPI backend in terms of kids mode?
Function shouldKidsModeBeSentToServer()
  if m.uiMode = m.constants.ui.modes.kids AND isKidsModeEnabledByParentalControls() = false
    return true
  else if m.uiMode = m.constants.ui.modes.kidsAgeGate
    return true
  end if

  return false
End Function


' Tell some screens of the kidsMode value. This is to ensure that any calls to the backend are sending the proper kids mode state
' This should be done when a screen is created or when kids mode state changes
' This only needs to be done for screens that are cached and kidsMode is set upon initiation of the screen and never anytime else.
Function tellScreensIfKidsModeBeSentToServer()
  bKidsMode = shouldKidsModeBeSentToServer()
  homeScreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
  if homeScreen <> invalid
    homeScreen.shouldKidsModeBeSentToServer = bKidsMode
  end if
End Function


Function isKidsUIOn()
  if m.uiMode = m.constants.ui.modes.kids OR m.uiMode = m.constants.ui.modes.kidsAgeGate OR m.uiMode = m.constants.ui.modes.kidsParental
    return true
  end if
  return false
End Function


Function isKidsModeEnabledByParentalControls() as Boolean
  tubiLog("ContentController.isKidsModeEnabledByParentalControls")
  bEnabled = false

  if isLoggedInUser() = true
    authInfo = m.global.authInfo
    if authInfo.parentalrating <> invalid AND authInfo.parentalrating < 2
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

    if authInfo.parentalrating = invalid OR authInfo.parentalrating <> 3
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

    if authInfo.parentalrating = invalid OR authInfo.parentalrating = 2
      bEnabled = true
    end if

  end if

  return bEnabled
End Function


Function refreshAllDetailScreens()
  ' Refresh all detail screens so they have proper history that's been loaded or unloaded
  isUserSigedIn = isLoggedInUser()

  for i = 0 to m.screenStack.getChildCount() - 1
    screen = m.screenStack.getChild(i)

    if screen.subType() = "DetailScreen"
      content = screen.content 'No need to re fetch the content, just re populate the screen content
      populateDetailScreen(screen, content)

      if isUserSigedIn = true
        screen.removeSignupButton = true
        setDetailStrings(screen, content)
      end if

      screen.isWaitingForServerResponse = false
    end if
  end for
End Function


' Content for a category details screen has been updated.
' Any screen that is displaying this category should be updated.
' @sCategoryID: string, the category id we are searching for in the stack
Function refreshStackedUserScreenWithChangedCategory(sCategoryID)
  ' Tell the screen that contains the category associated with the passed ID to refresh the next time is is on screen by setting the validUntil variable to 0
  for i = 0 to m.screenStack.getChildCount() - 1
    screen = m.screenStack.getChild(i)
    if screen <> invalid AND screen.isSubType("CategoryDetailsScreen")
      content = screen.content
      if content <> invalid AND content.id = sCategoryID
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
  startChannel()
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
  if isString(sScreenID) = true AND sScreenID <> ""
    currentScreen = getCurrentScreen()
    deleteFromScreenCache(sScreenID)

    '//Take user to previous screen
    if currentScreen <> invalid AND currentScreen.id = sScreenID
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
' @content: roSGNode, content node that needs to be cached.
' @screenId: string, the id of the screen whose is requesting to save the content.
Function setInContentCache(content, screenId)
  return m.cache.setInContentCache(content, screenId)
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
    if screen.content <> invalid AND screen.content.validUntil <> invalid
      screen.content.validUntil = 0
      return true
    else if (isAnEpgScreen(screen) = true OR screen.id = m.constants.ui.screenIds.linearVideoPlayerScreen)
      timeGridContent = screen.timeGridContent
      if timeGridContent <> invalid
        timeGridContentChild = timeGridContent.getChild(0)
        if timeGridContentChild <> invalid AND timeGridContentChild.validUntil <> invalid
          screen.timeGridContent.getChild(0).validUntil = 0
          return true
        end if
      end if
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
  setContentToRefresh(m.constants.ui.screenIds.channelListScreen)
  setContentToRefresh(m.constants.ui.screenIds.categoryListScreen)
  setContentToRefresh(m.constants.ui.screenIds.epgScreen)
  setContentToRefresh(m.constants.ui.screenIds.linearVideoPlayerScreen)
  setContentToRefresh(m.constants.ui.screenIds.myStuffScreen)
  setContentToRefresh(m.constants.ui.screenIds.tournamentScreen)

  searchScreen = getScreenFromStackById(m.constants.ui.screenIds.searchScreen)
  if searchScreen <> invalid
    ' calling updateSearchContentNode to removes the Lock icon from search result posters once user sign-in.
    updateSearchContentNode(searchScreen)
  end if

  timeGridContent = getFromContentCache(m.constants.ui.contentIds.timeGridContent)
  if timeGridContent <> invalid AND timeGridContent.getChild(0) <> invalid AND timeGridContent.getChild(0).validUntil <> invalid
    timeGridContent.getChild(0).validUntil = 0
  end if

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


Function onVideoContentScreenBackgroundUpdated(msg)
  tubiLog("ContentController.onVideoContentScreenBackgroundUpdated")
  screen = msg.getRoSGNode()
  setVideoContentScreenBackground(screen)
End Function


' Is the current screen a home screen?
Function isCurrentScreenHomeScreen()
  bReturn = getCurrentScreen() <> invalid AND getCurrentScreen().isSubType("HomeScreen")
  return bReturn
End Function


'Is the current Screen a epg Screen?
Function isCurrentScreenEPGScreen()
  bReturn = getCurrentScreen() <> invalid AND getCurrentScreen().isSubType("EPGScreen")
  return bReturn
End Function


Function setVideoContentScreenBackground(screen)
  currentScreen = getCurrentScreen()
  if screen <> invalid AND currentScreen <> invalid AND screen.id = currentScreen.id
    contentType = invalid
    if screen.contentFocused <> invalid
      contentType = screen.contentFocused.type
    end if
    videoPreviewState = getVideoPreviewState()
    if videoPreviewState = "playing" OR videoPreviewState = "paused"

      m.backgroundGroup.backgroundInfo = {
        type: m.constants.ui.backgroundTypes.epg
        uriList: [] ' setting uriList as empty, because don't need to rotate the background poster when video preview is playing. We can't use shouldRotateBackgrounds because we still need the gradients from backgroundGroup
      }
    else
      m.backgroundGroup.backgroundInfo = {
        type: getBackgroundType(screen.backgroundUriList, contentType)
        uriList: screen.backgroundUriList
      }
    end if
  end if
End Function


Function onSponsorshipBackgroundChanged(msg)
  screenWithSponsorship = msg.getRoSGNode()
  currentScreen = getCurrentScreen() 'gets the top screen in the screen stack
  if currentScreen <> invalid AND currentScreen.isSameNode(screenWithSponsorship)
    setSponsorshipBackground(msg.getData())
  end if
End Function


' @url: string, The URL of the Sponsorship Background
Function setSponsorshipBackground(url)
  m.SponsorBground.uri = url
End Function


Function onEpisodeBackgroundChange(msg)
  TubiLog("ContentController.onEpisodeBackgroundChange")
  episodeScreen = msg.getRoSGNode()
  m.backgroundGroup.backgroundInfo = {
    type: getBackgroundType(episodeScreen.backgroundUriList)
    uriList: episodeScreen.backgroundUriList
  }
End Function


Function onSearchBackgroundChange(msg)
  TubiLog("ContentController.onSearchBackgroundChange")
  searchScreen = msg.getRoSGNode()
  m.backgroundGroup.backgroundInfo = {
    type: getBackgroundType(searchScreen.backgroundUriList)
    uriList: searchScreen.backgroundUriList
  }
End Function


Function onCategoryScreenBackgroundChange(msg)
  TubiLog("ContentController.onCategoryScreenBackgroundChange")
  categoryDetailsScreen = msg.getRoSGNode()
  m.backgroundGroup.backgroundInfo = {
    type: getBackgroundType(categoryDetailsScreen.backgroundUriList)
    uriList: categoryDetailsScreen.backgroundUriList
  }
End Function

Function displayDefaultBackground()
  TubiLog("ContentController.displayDefaultBackground")
  m.backgroundGroup.backgroundInfo = {
    type: getBackgroundType([m.defaultBackgroundUri])
    uriList: [m.defaultBackgroundUri]
  }
End Function


Function onScreenBackgroundUpdated(msg)
  TubiLog("ContentController.onScreenBackgroundUpdated")
  screen = msg.getRoSGNode()

  if screen <> invalid
    m.backgroundGroup.backgroundInfo = {
      type: getBackgroundType(screen.backgroundUriList)
      uriList: screen.backgroundUriList
    }
  end if
End Function


Function onLandingScreenBackgroundChange(msg)
  TubiLog("ContentController.onLandingScreenBackgroundChange")
  landingScreen = msg.getRoSGNode()
  if landingScreen <> invalid
    m.backgroundGroup.backgroundInfo = {
      type: m.constants.ui.backgroundTypes.rightScreen
      uriList: landingScreen.backgroundUriList
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
  tubiLog(FormatJSON(messageInfo), "info", "clientInfo", "time-to-load", 0.1) 'send info to server
End Function


'''''''''''''''''''''''
' getBackgroundtype
'
' Helper function to get the background type depending on if passed in uri list is using the default image
' @backgroundUriList, array of uris
' @contentType, String - depending on the focused on content, it will determine the background type
Function getBackgroundType(backgroundUriList, contentType = "")

  backgroundType = m.constants.ui.backgroundTypes.topRight
  if backgroundUriList <> invalid
    if backgroundUriList[0] = m.defaultBackgroundUri
      backgroundType = m.constants.ui.backgroundTypes.fullScreen
    else if backgroundUriList[0] = m.marketingBackgroundUri
      backgroundType = m.constants.ui.backgroundTypes.marketingScreen
    else if contentType = m.constants.ui.contentTypes.linear OR contentType = m.constants.ui.contentTypes.epg
      backgroundType = m.constants.ui.backgroundTypes.epg
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

' show modal to inform the user that app is not latest version due to error in downloading starter or remote components
Function showPackedVersionLoadedModal(trackingLib, trackingTask)
  buttons = [getTranslation("dialog_button_ok")]

  userErrorCode = getUserFacingErrorCode("1", "300","" )

  title = getTranslation("dialog_defaultError_title")

  template = {"errCode":  userErrorCode}
  message = getTranslation("component_library_failed", template)

  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: "NETWORK_ERROR" 'DialogType enum
      pageOneof: trackingLib.getAnalyticsPage("home_page", {content_mode: "CONTENT_MODE_UNKNOWN"})
      dialog_action: "SHOW"
      dialog_sub_type: "component-lib-failed"
    }
  }
  showSimpleModal(title, message, buttons, dialogEvent, trackingTask)

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
  return (UCase(m.constants.deviceInfo.countryCode) = "US" OR UCase(m.constants.deviceInfo.countryCode) = "CA")
End Function


Function isKidsModeAvailableByCountry()
  countryCode = UCase(m.constants.deviceInfo.countryCode)
  availableCountries = {
    "US": true
    "CA": true
    "NZ": true
  }
  return (availableCountries.doesExist(countryCode) = true)
End Function


Function isDeviceInUS()
  return UCase(m.constants.deviceInfo.countryCode) = "US"
End Function


Function shouldShowAgeGate()
  if isDeviceInUSorCA() <> true
    return false
  else if m.constants.settings.mode <> "production" AND m.constants.settings.skipAgeGate = true
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
    m.trackingLoggingTask.trackEvent = {
      type: "inactive"
      values: {}
    }
    m.appSuspendTimer.Mark()
    currentScreen = getCurrentScreen()
    ' if the current screen is videoplayer, return to detail screen so that it will update historyPosition AND remove video screen from stack AND show previous screen from stack
    if currentScreen <> invalid AND currentScreen.id = m.constants.ui.screenIds.videoPlayerScreen
      currentScreen.sendPendingPauseAdPixel = true
      ' don't send analytics event when user presses "home" button during playback, so sending param as false.
      returnToDetailScreenFromVideo(false, false)
    else if currentScreen <> invalid AND currentScreen.id = m.constants.ui.screenIds.categoryDetailsScreen
      ' if current screen is categoryDetailsScreen, instant resume action is to start the channel from the homescreen (not a full channel restart).
      ' Remove the parent screen from the cache so that it is reloaded if a user navigates back to it in order to prevent a UX bug such that the cached screen
      ' is displayed but nothing is displayed on the screen.
      deleteFromScreenCache(m.constants.ui.screenIds.channelListScreen)
      deleteFromScreenCache(m.constants.ui.screenIds.categoryListScreen)
    else
      ' if the focus is on live TV row, stop the playback
      linearVideoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
      if linearVideoPlayer <> invalid
        closeLinearVideoPlayerTransport()
        linearVideoPlayer.control = "stop"
      end if
    end if

    screensaverScreen = getScreensaverScreen()
    if screensaverScreen <> invalid then
      closeScreensaverScreen()
    end if

    'Modals with type errorDialog should made invisible and app should restarted on app relaunch.
    'Modals with type actionDialog should be closed and app should resume from the current screen
    modal = getTopModal()
    if modal <> invalid
      if modal.instantResumeAction = m.constants.instantResumeActions.restartApp
        'making visible = false to avoid showing error modal while app on relaunch
        modal.visible = false
      else if modal.instantResumeAction = m.constants.instantResumeActions.closeDialog OR modal.instantResumeAction = m.constants.instantResumeActions.startChannel
        closeModal(modal)
        if currentScreen <> invalid
          currentScreen.setFocus(true)
        end if
      end if
    end if

    ' When resuming from suspending the app, Roku force restores the currFocus row back to the state that existed at the time of suspending the app.
    ' This force restore happens after we set the focus appropriately using jumpToItem which rendering our jumpToItem action useless.
    ' To work around this firmware behavior, we set the focus to the home menu item at the time of suspend so that when the app resumes, the Roku behavior will focus the correct side nav menu item. (Refreshing of home screen content will happen during resume that is inside onCustomResume method.)
    if currentScreen <> invalid AND currentScreen.instantResumeAction = m.constants.instantResumeActions.startChannel
      focusSideNavOption(m.constants.ui.sideNavIds.home)
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
  bRestartApp = false
  bStartChannel = false

  if args <> invalid
    customResumeLaunchParams = args.launchParams
    lastSuspendOrResumeReason = args.lastSuspendOrResumeReason
  end if
  currentScreen = getCurrentScreen()
  if lastSuspendOrResumeReason = "home" AND customResumeLaunchParams <> invalid
    ' User coming back to app via instant resume is considered as returning user
    m.global.isNewUser = false

    lastAppSuspendInSecs = m.appSuspendTimer.TotalSeconds()
    lastAppRestartInDays = m.lastAppRestartTimer.TotalSeconds() / 24 / 60 / 60

    if m.Request = invalid
      m.Request = TubiRequest(m.constants.settings)
    end if

    if (customResumeLaunchParams.contentId <> invalid AND customResumeLaunchParams.mediaType <> invalid) OR customResumeLaunchParams.page <> invalid
      ' if resuming due to a deeplink, restart the app. Deeplinking into a non standard state creates
      ' lots of edge cases, so for consistency, restarting the app is easiest.
      bRestartApp = true
    else
      if isLoggedInUser() = false AND (lastAppSuspendInSecs > m.constants.timers.coppaFailTimeout OR lastAppRestartInDays >= 4)
        ' For guest users, if the time between last suspend and current resume is more than 24 hours,
        ' disable Instant Resume & relaunch app from scratch.
        ' Also every 4 days once the app restarts in order to get starter/remote components
        bRestartApp = true
      else if isLoggedInUser() = true AND (lastAppRestartInDays >= 4)
        ' For loggedIn users, every 4 days once the app will be restarted as it needs to fetch starter/remote components
        bRestartApp = true
      else if m.top.isComponentLibFailedToLoad = true
        bRestartApp = true
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
            bRestartApp = true
          else if modal.instantResumeAction = m.constants.instantResumeActions.startChannel
            'calling startChannel() instead of restartChannel() since restartChannel() can land a user on the ICTS screen, but we only want users to land on the home screen
            bStartChannel = true
          end if
        else if currentScreen <> invalid
          if currentScreen.instantResumeAction = m.constants.instantResumeActions.restartApp
            bRestartApp = true
          else if currentScreen.instantResumeAction = m.constants.instantResumeActions.startChannel
            'calling startChannel() instead of restartChannel() since restartChannel() can land a user on the ICTS screen, but we only want users to land on the home screen
            bStartChannel = true
          else
            sendNielsenPing(m.constants.thirdParty.nielsen.pingTypes.sessionStart)
            resumeApp()
          end if
        else
          'Unknown state, backup solution to restart app.
          bRestartApp = true
        end if
      end if
    end if

    m.mainTask.request = {
      "type": "updateScreensaverTimeout"
    }
  else if lastSuspendOrResumeReason = "screensaver"
    ' Do nothing, but leave this as a place holder.
    ' The app will resume as normal for the screensaver.
  end if


  '// If the resume app action is to restart the app or start the channel, then 1st see if the previously played linear video can be played (if one exists)
  if bRestartApp = true
    restartAppFromInstantResume()
  else if bStartChannel = true
    startChannelFromInstantResume()
  else
    if currentScreen <> invalid AND currentScreen.id = m.constants.ui.screenIds.episodeScreen
      currentScreen.updateContent = true
    end if
  end if
End Function


' This is the fail safe startChannel function to be called if the previously played linear video could not be played
Function startChannelFromAppLoad(response = invalid)
  startChannel()

  if m.top.isComponentLibFailedToLoad = true
    showPackedVersionLoadedModal(m.Tracking, m.trackingLoggingTask)
  end if

  showUpgradeModal(m.constants.showUpgradeAlert, m.Tracking, m.trackingLoggingTask) 'show as necessary
End Function


' This is the fail safe startChannel function to be called if the previously played linear video could not be played
Function startChannelFromInstantResume(response = invalid)
  sendNielsenPing(m.constants.thirdParty.nielsen.pingTypes.sessionStart)
  startChannel()
End Function


' This is the fail safe restartApp function to be called if the previously played linear video could not be played
Function restartAppFromInstantResume(response = invalid)
  restartApp()
End Function


' When the app loads or instantly resumes, then sometimes it will try to launch a previously played linear video. This function is used
' when the call to get the linear channel info is a success.
' @param successResponse, The response from the server
' @param _storeInCache, This secondary param is not used but it is required for a calback of fetchEPGChannel()
Function onSingleChannelFetchForLinearRelaunchSuccess(successResponse, _storeInCache = false)
  linearContent = invalid
  if successResponse <> invalid AND successResponse.getChildCount() > 0
    linearContent = successResponse.getChild(0)
    linearContent.deeplinktype = "linear"
  end if

  if linearContent <> invalid
    '//deeplink to the EPG SCreen, then launch the linear video player, and ensure the side nav displays the proper focus
    showDefaultEPGScreen()
    hideNavMenu(false) '//ensure the side nav is closed.
    playLinearVideoContent(linearContent, false, m.constants.ui.screenIds.epgScreen, true)

    '//Change the background to regular fullscreen so there isn't the normal corner linear video background for a moment
    m.backgroundGroup.backgroundInfo = {
      type : m.constants.ui.backgroundTypes.fullscreen
      uriList : []
    }

    focusSideNavOption(m.constants.ui.sideNavIds.home)
  else
    startChannelFromAppLoad()
  end if
End Function



' restarts the app from beginning of the line in order to retrieve starter/remote components
Function restartApp()
  tubiLog("ContentController.restartApp")
  clearScreenStack()
  m.top.disableInstantResume = true
  m.mainTask.control = "done"
  m.trackingLoggingTask.control = "done"
  m.generalTask.control = "done"
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
    else if isAnEPGScreen(currentScreen) = true
      ' if current Screen epg Screen,  It will start counting the remaining seconds and full videoscreen will take over when it reaches 0
      ' without content which will be a blank screen. To avoid it, stop the counter and refresh the EPGScreen videoplay
      stopCountdownTimer()
      refreshEPGScreenVideoPlay(false, currentScreen)
    else if isTournamentScreen(currentScreen) = true
      stopCountdownTimer()
      refreshTournamentScreenVideoPlay(false, currentScreen)
      currentScreen.setForceRefreshCategoryContainers = true
    end if

  end if


  ' when channel resumes,
  ' send page load event here only if the channel is not launched via deeplink
  ' because the page load event is handled & already happening during deeplink
  if m.deeplinkContent = invalid AND currentScreen <> invalid
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
    if screen.id = m.constants.ui.screenIds.homeScreen OR isAnEpgScreen(screen) = true OR isTournamentScreen(screen) = true
      if screen.id = m.constants.ui.screenIds.homeScreen
        contentToPlay = screen.contentFocused
      else
        contentToPlay = screen.linearChannelToPlay
      end if

      if contentToPlay <> invalid and contentToPlay.needsLogin = true
        'if Content is locked and do not show countDown.
        screen.fullscreenCountdown = -1
      else
        nCurrentCount = screen.fullscreenCountdown
        nNewCount = nCurrentCount - 1
        screen.fullscreenCountdown = nNewCount
        if nNewCount <= 0
          selectLinearContent(contentToPlay)
        end if
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


' show appropriate logo based on the app mode like kids, espanol, standard
Function showHideLogoBasedOnUiMode()
  mode = m.uiMode

  if mode = m.constants.ui.modes.standard
    showHideLogo(m.constants.logoType.tubi)
  else if mode = m.constants.ui.modes.kids OR mode = m.constants.ui.modes.kidsAgeGate OR mode = m.constants.ui.modes.kidsParental
    showHideLogo(m.constants.logoType.tubiKids)
  else if mode = m.constants.ui.modes.latino
    showHideLogo(m.constants.logoType.tubiEspanol)
  end if

End Function


' @logoType : string, one of the following from m.constants.ui.modes
          ' "tubi" =  show tubi logo,
          ' "tubi_kids" = show tubi kids logo,
          ' "tubi_espanol" = show espanol logo,
          ' "tubi_fifa" = show FIFA + tubi logo
          ' "hide" = hide all logos
Function showHideLogo(logoType)

  if m.logoType <> logoType
    tubilog("ContentController.showHideLogo")

    if logoType = m.constants.logoType.hide
      m.logoEspanol.visible = false
      m.logoKids.visible = false
      m.logo.visible = false
      m.logoFIFA.visible = false
    else
      if logoType = m.constants.logoType.tubiKids
        m.logoKids.visible = true
        m.logo.visible = false
        m.logoEspanol.visible = false
        m.logoFIFA.visible = false
      else if logoType = m.constants.logoType.tubiEspanol
        m.logoEspanol.visible = true
        m.logoKids.visible = false
        m.logo.visible = false
        m.logoFIFA.visible = false
      else if logoType = m.constants.logoType.tubiFifa
        m.logoEspanol.visible = false
        m.logoKids.visible = false
        m.logo.visible = false
        m.logoFIFA.visible = true
      else 'default is tubi logo
        m.logo.visible = true
        m.logoEspanol.visible = false
        m.logoKids.visible = false
        m.logoFIFA.visible = false
      end if
    end if

    m.logoType = logoType

  end if

End Function


Function onIsHdmiStatusOkChange(msg)
  isHdmiStatusOk = msg.getData()

  currentScreen = getCurrentScreen()
  if currentScreen <> invalid then
    currentScreenId = currentScreen.id
    screenIds = m.constants.ui.screenIds

    if currentScreenId = screenIds.detailScreen then
      if isHdmiStatusOk = true AND currentScreen.shouldResumePlayback = true then
        currentScreen.shouldResumePlayback = false
        detailScreenResumeHelper(currentScreen)
      end if
    else if currentScreenId = screenIds.episodeScreen then
      if isHdmiStatusOk = true AND currentScreen.shouldResumePlayback = true then
        currentScreen.shouldResumePlayback = false
        episodeScreenResumeHelper(currentScreen)
      end if
    else if currentScreenId = screenIds.videoPlayerScreen then
      state = currentScreen.state
      if state <> "finished" AND state <> "error" AND isHdmiStatusOk = false then
        returnToDetailScreenFromVideo(false)
        currentScreen = getCurrentScreen()
        currentScreen.shouldResumePlayback = true
      end if
    else
      linearVideoPlayerScreen = getFromScreenCache(screenIds.linearVideoPlayerScreen)
      if isNode(linearVideoPlayerScreen) = true then
        if isHdmiStatusOk = true then
          ' if the current screen is linearVideoPlayerScreen, then re-start the playback.
          ' We restart to make sure that the proper video start time is included in the manifest
          associatedScreenId = currentScreen.associatedScreenId
          originalLinearContent = currentScreen.originalContent
          playLinearVideoContent(originalLinearContent, false, associatedScreenId)
        else
          state = currentScreen.state
          if state <> "finished" AND state <> "error" then
            closeLinearVideoPlayerTransport()
            linearVideoPlayerScreen.control = "stop"
          end if
        end if
      end if
    end if
  end if
End Function


' Screens can request to show a toast by assigning proper values to showToastMessage field.
Function onShowToastMessage(msg)
  toastMsg = msg.getData()
  showToast(toastMsg)
End Function


' showToast -  displays the message on screen like Android toast message.
' Toast width is based on message or title length whichever is lengthier.
'   max width = 642
'   min width = 444
'   max height = 176
'   min height = 112
'
'@toastMsg: assocArray, it contains below
  '{
    ' @message: string,  message to be displayed
    ' @headerText : string, title
    ' @imageUri: string, image to be displayed left side of message
    ' @selfDestructTimer: integer, number of seconds toast should be displayed
    ' @headerColor: colorstring for HeaderText
    ' @messageColor: colorString for message
    ' @backGroundColor : toast background color
    ' @imageWidth: interger, width of the image if imageUri is provided.
    ' @imageHeight: interger, height of the image if imageUri is provided.
  '}
' @shouldSendTracking: boolean, true if we are sending an event for toast message, otherwise false
' @dialogEventInfo: assocArray, contains the info necessary to send a dialog analytics event, has keys: "type" and "values"
Function showToast(toastMsg, shouldSendTracking = false, dialogEventInfo = {})
    m.tubiToast = m.top.findNode("tubiToast")
    if isAA(toastMsg) = true
      m.tubiToast.showToastMessage = toastMsg
      m.tubiToast.show = true

      if shouldSendTracking = true AND dialogEventInfo.count() > 0
        m.trackingLoggingTask.trackEvent = dialogEventInfo
      end if

    end if

End Function'


Function onLowMemoryEventInfoChange(msg)
  data = msg.getData()

  screenIds = getScreenIdsFromStack()

  ' Creating the info aa.
  eventInfo = {
    ' Total of number nodes cached in the tubi cache.
    "totalCachedNodes": m.cache.getCachedNodeCount()
    ' Total of number screens cached in the tubi cache. This number is different than number of screens in stack.
    "totalCachedScreens": m.cache.getCachedScreenCount()
    ' Total number of nodes at the scene level.
    "totalNodes": data.totalNodes
    ' Active BreadCrumb.
    "screensInStack": screenIds.join(",")
    ' How the user has been using the application.
    "upTime": data.upTime
    "type": m.constants.errors.type.lowMemoryWarning
    "name": m.constants.errors.message.lowMemoryWarning
  }

  ' Setting the samplePercent to 1 so that we send it always since we anyways send it only once per user.
  tubiException(eventInfo, "warn", 1)
End Function


Function isVideoPreviewOn()
  if m.pub_serverPersistentData <> invalid
    return (isVideoPreviewEnabled() = true AND m.pub_serverPersistentData.isVideoPreviewOn = true)
  end if

  return false
End Function


Function updateScreenCacheOnPlayback(currentVideoScreenID)
  screenIds = m.cache.getCachedScreenIds()
  linearVideoPlayerScreenId = m.constants.ui.screenIds.linearVideoPlayerScreen
  for each id in screenIds
    ' Do not delete any screen from cache if it is in stack.
    ' Delete Linear Player and cached content if we switch to VOD.

    ' Adding a check to avoid deleting current screen.
    if id <> currentVideoScreenID
      ' Cleaning up linearPlayerScreen when the user switches to VOD.
      if id = linearVideoPlayerScreenId
        ' This is needed specifically for Linear only since it works slightly different than screens.
        ' We have a copy of LinearVideoPlayerScreen outside of Screen Stack.
        animationContext = {
          parent: m.top
        }
        m.nodeHelpers.removeChildAtIndex(m.LinearPlayerGroup, 0, animationContext)
      end if
      ' Deleting screens from cache that are not in screen stack.
      if getScreenFromStackById(id) = invalid
        m.cache.deleteFromScreenCache(id)
      end if
    end if
  end for
End Function


Function showContentGroupAndHideSpinner()
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
End Function


' isUserInAdultsMode Returns true/false based on if the user is in adults mode based on parental controls and age info.
Function isUserInAdultsMode()
  tubiLog("ContentController.setUiModeFromState")
  isUserInAdultsMode = true

  ' Checking gf the parental control is not in adults level.
  if isParentalControlsAdultLevel() = false
    isUserInAdultsMode = false
  else if shouldShowAgeGate() = true then
    if m.guestUserHasAgeInfo = invalid then
      m.guestUserHasAgeInfo = TubiAuth(m.constants, m.Request).getGuestUserHasAgeInfo()
    end if

    ' Have to make sure we check expired as well as default state will always have hasAge = false
    if m.guestUserHasAgeInfo.hasAge = false AND m.guestUserHasAgeInfo.expired = false then
      isUserInAdultsMode = false
    end if
  end if

  return isUserInAdultsMode
End Function

' @key: string, key of the consent preference item. For ex: essential_functionality.
Function showRequiredPreferenceToast(key)
  consents = m.consentSettings.consents

  ' Finding matching preference key title.
  for each consent in consents
    if consent.key = key
      replacements = {
        preference: consent.title
      }
      message = getTranslation("required_preference_selected_toast_message", replacements)
      showToast({
        "selfDestructTimer": 5
        "headerText": getTranslation("required_preference_selected_toast_heading")
        "message": message
        "imageUri": "pkg:/images/consent-toast-icon.webp"
      })
      exit for
    end if
  end for
End Function


' Configures the braze sdk and initializes the braze task and stores the instance of braze sdk and braze task in m scope.
Function configureBrazeAndInitializeTask()
  ' Since braze starts sending request immediately as soon we create the task and we need to inform braze about logged in status.
  ' Delaying it until we complete the auth check. Also this prevents us from showing braze pop up on top of splash screen etc.
  ' We noticed that if braze respondes quickly and our endpoints take time we ended up showing the braze modal before even home screen loaded.
  ' Moving it here allows the application to load required endpoints and also menu etc before we start braze.
  ' Configuring the braze sdk.
  configureBrazeSdk()
  ' Starting the braze task.
  m.brazeTask = CreateObject("roSGNode", "BrazeTask")
  ' Stopping the braze task until we know the user logged in status so that we can present non logged in user modal for logged in user.
  m.braze = getBrazeInstance(m.brazeTask)
  m.brazeTask.unobserveFieldScoped("BrazeInAppMessage")
  m.brazeTask.observeFieldScoped("BrazeInAppMessage", "onInAppMessageTriggered")
  authInfo = getFieldFromGlobal("authInfo")
  setBrazeUserData(authInfo)
End Function


' Stops the braze task and invalidates all braze variable in m scope.
Function stopBrazeTask()
  if m.brazeTask <> invalid
    m.brazeTask.unobserveFieldScoped("BrazeInAppMessage")
    m.brazeTask.control = "STOP"
    m.brazeTask = invalid
    m.braze = invalid
  end if
End Function


' Delete all items from roku continue watching row.
Function clearRokuContinueWatching()
  requestInfo = m.rokuContinueWatchingApi.createClearContinueWatchingReqInfo()
  m.top.rokuContinueWatchingRequestInfo = requestInfo
End Function