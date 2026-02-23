Function init()
  m.top.id = "ContentController"

  tubiLog("")
  tubiLog("Init Scenegraph----------------")
  m._ = rodash()

  m.constants = getConstants()
  startupArgs = m.top.getScene().startupArgs
  m.constants = addConstantsFromStartupArgs(startupArgs, m.constants)
  m.global.constants = m.constants
  m.global.theme = m.constants.ui.themes.default

  m.performanceMetricsTracker = PerformanceMetricsTracker()
  m.performanceMetricsTracker.startAppLaunchMetricTiming("time_to_first_tile_focus")

  m.currentlyLoadingScreens = []

  ' We need to create the general task in order to load our base dependencies (like experiments, remote config, etc.) but we will need to update the general task after the base dependencies are loaded.
  generalTask = createObject("roSGNode", "ControllerGeneralTask") ' initiate GeneralTask
  observeUpdateAuth(generalTask)
  observeLogoutAndRestartApp(generalTask)

  ' Initiate GeneralTaskModule by passing caller context.
  m.generalTaskModule = {}
  GeneralTaskModule(m.generalTaskModule, generalTask)
  ' Appends generalTaskModule to controller m for backward compatibility.
  m.append(m.generalTaskModule)

  ' Should be created after GeneralTaskModule has run as TubiAuthUpdate will verify that the GeneralTaskModule is available
  m.tubiAuthUpdate = TubiAuthUpdate(m.constants)
  m.global.addField("generalTask", "node", false)
  m.global.generalTask = generalTask

  m.deeplinkContent = invalid

  ' Used to know if we are already getting auth and want to avoid running multiple requests at the same time
  m.getAuthOperationInProgress = false

  ' Used to know when the startupArgs have been handled so we know if we can proceed
  m.startupArgsHandled = false

  m.top.observeFieldScoped("startupArgs", "onStartupArgs")

  m.isExternalConfigReady = false ' Used to know when external config has been loaded so we know if we can proceed
  ' TODO: CLEAN UP THE CODE LATER. REMOVING POPPER FOR SUBMISSION.
  m.isExperimentsConfigReady = true ' Used to know when experiments have been loaded so we know if we can proceed
  m.isStatsigConfigReady = false ' Used to know when Statsig experiments have been loaded so we know if we can proceed
  m.soTStaticConfigComplete = false ' Used to know when the SoT static config has been loaded so we know if we can proceed
  m.startupDelayComplete = false

  ' Holds the callback method value which will be called once the initial get consent request is completed.
  m.onGetConsentCompletionCallback = invalid

  ' Used to know if the profile migration has been completedd. Profile migration happens if user is in multi account
  'experiment to create first profile or we already have profiles.
  m.profileMigrationComplete = false

  ' Holds the instance of one trust sdk. Creating m scope variable so that we do not have to access the instance from global.
  ' Since One trust sdk access m.global.OTsdk within it's codebase we need to update the m.global.OTsdk to have the sdk instance.
  ' The reason why we are also storing it's reference in m scope for better performance since we access the sdk instance a lot of items during the app session.
  m.oneTrust = invalid


  ' Used to keep track of the number of times the user has visited the multi account experiment.
  m.multiAccountVisitCount = 0

  m.global.addField("statsigExposureInfo", "assocarray", false)
  m.global.observeFieldScoped("statsigExposureInfo", "onStatsigExposureInfoChange")

  retrieveClientErrorConfig(retrieveClientErrorConfigSuccessCallbackTriggerRetrieveInitialAuthInfo, retrieveClientErrorConfigErrorCallbackTriggerRetrieveInitialAuthInfo)

  'playerStats is used in TestingAidPanel which shows/hides the player stats overlay in VideoplayerScreen
  m.global.addField("showPlayerStats", "boolean", false)

  ' Holds true or false based on if app suspend is in progress
  m.isApplicationSuspendInProgress = false

  m.top.getScene().observeFieldScoped("focusedChild", "onSceneFocusedChildChanged")

  ' Holds the paginated content in queue to be appended to the screen.
  m.paginatedContentQueue = invalid
End Function


Function onSceneFocusedChildChanged()
  if m.top.getScene().isInFocusChain() = false then
    ' Have to use a timer as trying to set right away fails to set properly
    m.sceneLooseFocusTimer = createObject("roSGNode", "Timer")
    m.sceneLooseFocusTimespan = createObject("roTimespan")
    m.sceneLooseFocusTimer.duration = 5
    m.sceneLooseFocusTimer.observeFieldScoped("fire", "onSceneLooseFocusTimerFired")
    m.sceneLooseFocusTimer.control = "start"
    tubiLog("ContentController.onSceneFocusedChildChanged - Scene lost focus, starting timer")
  else if m.sceneLooseFocusTimer <> invalid then
    m.sceneLooseFocusTimer.control = "stop"

    if m.sceneLooseFocusTimespan.totalMilliseconds() > 10 then
      onSceneLooseFocusTimerFired()
    end if

    m.sceneLooseFocusTimer = invalid
    m.sceneLooseFocusTimespan = invalid
  end if
End Function


Function onSceneLooseFocusTimerFired()
  m.sceneLooseFocusTimer = invalid
  screen = getCurrentScreen()
  if screen <> invalid AND m.top.getScene().isInFocusChain() = false then
    ' Go ahead and log so we can keep track of how often this happens
    currentScreenSubtype = screen.subtype()
    currentScreenId = screen.id

    message = {
      "message": "Roku scene lost focus. Attempting to restore focus."
      "currentScreenSubtype": currentScreenSubtype
      "currentScreenId": currentScreenId
      "timeFocusWasLost": m.sceneLooseFocusTimespan.totalMilliseconds()
    }

    if currentScreenId = "videoPlayerScreen" then
      message["adState"] = screen.adState
      message["state"] = screen.state
    end if

    logInfo(message, "clientInfo", "scene-lost-focus", 0.1)

    screen.setFocus(true)
  end if
End Function


' This will load the rest of our modules and UI after the base dependencies are loaded
Function addControllerUi()
  '//When ContentController initializes, set translations
  initTranslations()

  m.uiGroup = m.top.findNode("uiGroup")
  ' We need to add all of the UI that was in ContentController before but is now housed in ContentControllerUI. See ContentControllerUI.xml for more details.
  ' We're pulling out all of the children of ContentControllerUI and appending them to the uiGroup to avoid having a different node structure than before.
  children = createObject("roSgNode", "ContentControllerUI").getChildren(-1, 0)
  m.uiGroup.appendChildren(children)

  ' Timer to find last time the app restarted
  m.lastAppRestartTimer = CreateObject("roTimespan")

  ' Timer to find last time the app suspended
  m.appSuspendTimer = CreateObject("roTimespan")

  m.mainTask = createObject("roSGNode", "MainTask") ' initiate MainTask
  m.mainTask.observeFieldScoped("isHdmiStatusOk", "onIsHdmiStatusOkChange")

  ' Holds the value for user/device level settings. For ex: isVideoPreviewOn  or Selected Audio track.
  m.pub_serverPersistentData = createObject("roSGNode", "ServerPersistentData")

  m.Request = TubiRequest(m.constants.settings)
  m.NodeHelpers = TubiNodeHelpers()
  apiUtilsLib = ApiUtils(m.constants, m.pub_serverPersistentData)
  m.Bookmarks = TubiBookmarks(m.constants)
  m.Tracking = TubiTracking(m.constants, m.tubiAuthUpdate)
  experimentsInfo = getExperimentsInfoFromGlobal()
  experiments = TubiExperiments(experimentsInfo)
  statSigExperimentsInfo = getStatsigExperimentsInfoFromGlobal()
  experimentsInterface = StatsigExperimentsInterface(statSigExperimentsInfo)
  m.cmsApi = CmsApi(m.constants, apiUtilsLib, experiments, experimentsInterface)
  m.userDeviceApi = UserDeviceApi(m.constants, apiUtilsLib)
  m.tensorapi = TensorApi(m.constants, m.pub_serverPersistentData)
  m.rainmakerApi = RainmakerApi(m.constants)
  m.pubSub = TubiPubSub(m)

  m.background = m.top.findNode("ContentBackground")
  m.SponsorBground = m.top.findNode("SponsorshipBackgroundGroup")
  m.SponsorFooter = m.top.findNode("SponsorshipFooterGroup")

  m.contentGroup = m.top.findNode("ContentGroup")
  m.SideNav = m.top.findNode("SideNav")

  m.backgroundVideoPreviewPlayerContainer = m.top.findNode("backgroundVideoPreviewPlayerContainer")
  m.inlineVideoPreviewPlayerContainer = m.top.findNode("inlineVideoPreviewPlayerContainer")

  ' Check reusable video node experiment to determine which player to use
  reusableVideoNodeExperiment = getStatsigExperimentResource("reusable_video_node", "reusable_video_node_v1", true)
  isReusableVideoNodeEnabled = (reusableVideoNodeExperiment <> invalid AND reusableVideoNodeExperiment.enabled)

  ' Create video preview player dynamically based on experiment
  if isReusableVideoNodeEnabled = true
    ' Create and add ReusablePreviewPlayer
    m.videoPreviewPlayer = CreateObject("roSGNode", "ReusablePreviewPlayer")
  else
    ' Create and add VideoPreviewPlayer
    m.videoPreviewPlayer = CreateObject("roSGNode", "VideoPreviewPlayer")
  end if
  m.videoPreviewPlayer.id = "videoPreviewPlayer"
  m.backgroundVideoPreviewPlayerContainer.appendChild(m.videoPreviewPlayer)

  m.inlinePreviewFocusIndicator = m.top.findNode("inlinePreviewFocusIndicator")
  m.inlineVideoMetadataOverlay = m.top.findNode("inlineVideoMetadataOverlay")
  m.autoStartPreviewToPlaybackTimer = createObject("roSGNode", "CircularCounter")
  m.autoStartPreviewToPlaybackTimer.id = "autoStartPreviewToPlaybackTimer"
  m.autoStartPreviewToPlaybackTimer.opacity = 0.0
  m.contentGroup.appendChild(m.autoStartPreviewToPlaybackTimer)

  ' Video tiles experiment related node.
  ' Holds the poster for the video tile that is in transit.That is in case of user scrolling down next container poster vs previous container poster when scrolling up.
  m.inTransitInlineVideoMetadataOverlay = m.top.findNode("inTransitInlineVideoMetadataOverlay")
  m.videoTileOverlayGroup = m.top.findNode("videoTileOverlayGroup")
  experiment = getStatsigExperimentResource("", "roku_video_tiles_1_9", false)
  videoTilesListTranslation = m.constants.ui.videoTilesListTranslation
  ' Using clipping rect to ensure that when scrolling up the video tile gets clipped along with the rest of the row list tiles
  m.videoTileOverlayGroup.clippingRect = [videoTilesListTranslation[0], videoTilesListTranslation[1], 1920, 1080]
  m.videoTileOverlayGroup.translation = [videoTilesListTranslation[0], -6]

  ' Not ideal but this is simpler and being it is for experiment purpose and we will remove using this approach to override constants when experiment is removed.
  if experiment <> invalid AND isAA(experiment.enabled_screens) = true
    m.constants.ui.videoTilesEligibleScreenIds = experiment.enabled_screens
  end if

  m.queuedVideoTilePreview = false

  m.inlinePreviewPlayerFadeAnimation = invalid

  m.videoPreviewDebounce = CreateObject("roSGNode", "Timer")
  m.videoPreviewDebounce.duration = m.constants.player.videoPreviewDelayTimes.videoTiles
  m.videoPreviewDebounce.observeFieldScoped("fire", "startDebouncedVideoPreview")

  updateVideoTileSize()

  m.LinearPlayerGroup = m.top.findNode("LinearPlayerGroup")
  m.LinearPlayerGroupAboveScreenStack = m.top.findNode("LinearPlayerGroupAboveScreenStack")

  m.backgroundGroup = m.top.findNode("BackgroundGroup")
  m.logoGroup = m.top.findNode("logoGroup")
  m.logo = m.logoGroup.findNode("tubiLogo")
  m.logoKids = m.logoGroup.findNode("tubiKidsLogo")
  m.logoEspanol = m.logoGroup.findNode("tubiEspanolLogo")
  m.presentedByGroup = m.logoGroup.findNode("presentedByGroup")
  m.presentedByLabel = m.presentedByGroup.findNode("presentedByLabel")
  m.typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.presentedByLabel, m.typographyConstants.ids.bodyExtraSmallStrong)
  m.presentedByImage = m.presentedByGroup.findNode("presentedByImage")
  m.clock = m.top.findNode("clock")
  m.spinner = m.top.findNode("ContentControllerSpinner")
  m.tubiToast = m.top.findNode("tubiToast")
  m.LinearVideoPlayerSpinner = m.top.findNode("LinearVideoPlayerSpinner")
  m.playerFullscreenCountdownTimer = m.top.findNode("PlayerFullscreenCountdownTimer")
  m.resumeAllowedTimer = m.top.findNode("ResumeAllowedTimer")

  m.screenStackGroup = m.top.findNode("ScreenStackGroup")
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


  m.trackingLoggingTask = CreateObject("roSGNode", "TrackingLoggingTask")
  observeUpdateAuth(m.trackingLoggingTask)
  observeLogoutAndRestartApp(m.trackingLoggingTask)

  m.global.addField("trackingLoggingTask", "node", false)
  m.global.trackingLoggingTask = m.trackingLoggingTask

  ' initialize states needed for various parts of kids mode
  m.kidsModeFeatureOn = getExternalConfigValueFromGlobal("enable_kidsmode", false) 'Should the kids Mode feature be made available for the user to interact with

  setUiMode(m.constants.ui.modes.standard)
  theme = getThemeFromGlobal()
  if theme <> invalid
    m.background.color = theme.backgroundColor
    m.presentedByLabel.color = theme.primaryTextColor
    m.inlinePreviewFocusIndicator.blendColor = theme.focusedColor
  end if

  m.top.observeFieldScoped("focusedChild", "onComponentFocus")

  'initialize linearScreenAfterFn. This function is executed after fadeInController
  'in case fadeInContentController is still playing when we tried to play linear content which will result in playback error.
  m.linearScreenAfterFn = invalid

  m.mainTask.observeFieldScoped("roInputInfo", "onInputInfoReceived")

  if m.top.fadeInContentController = true then
    onFadeInContentController()
  else
    m.top.observeFieldScoped("fadeInContentController", "onFadeInContentController")
  end if

  m.top.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")

  m.top.observeFieldScoped("customSuspend", "onCustomSuspend")
  m.top.observeFieldScoped("customResume", "onCustomResume")

  'this variable is used to stop unnecessary execution of the entire showHideLogo function when content been focused.
  m.logoType = m.constants.logoType.tubi

  ' Global state
  m.global.addField("bookmarkIds", "node", false)
  m.global.bookmarkIds = CreateObject("roSGNode", "BookmarkContentNode")
  m.global.addField("historyIds", "node", false)
  m.global.historyIds = CreateObject("roSGNode", "HistoryContentNode")
  m.global.addField("historyUpdated", "boolean", true)
  m.global.addField("likeIds", "node", false)
  m.global.likeIds = CreateObject("roSGNode", "LikeContentNode")

  ' isNewUser global variable is needed to show/hide onboarding, signup button on detail screen
  ' isNewUser will be set to true, if there is entry on firstVisit registry. Otherwise false
  m.global.addField("isNewUser", "boolean", false)
  m.global.isNewUser = false

  ' checking the firstVisit in registry and setting the isNewUser global based on it
  if getFirstVisit() = -1
    m.global.isNewUser = true
    setFirstVisit()
  end if

  m.authInfoNeedsRefreshing = false 'does the auth info need to be refreshed after receiving a deeplink with a refresh token
  m.ageVerificationComplete = false 'has the user verified their age?
  m.getServerPersistentDataComplete = false 'did we finish fetching serverPersistentData. either user/device based on user logged in status.

  ' used to keep state if we went through the process to refresh auth after receiving a transfer token from
  ' a mobile device deeplink. Used to determine if we should show a toast message or not.
  m.authInfoRefreshed = false

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

  ' Below boolean flag is used in registration flow, which indicates whether we need to display the roku continue watching consent screen.
  ' will be set to true if the user is in US and is in the experiment control group.
  m.shouldShowRokuCWConsentScreen = false

  ' Below boolean flag is used to check if the user is in multi account experiment and they have profiles
  m.isUserInMultiAccount = false

  ' During registration flow if the user is eligible to be shown the roku continue watching consent screen.
  ' Below variable will hold the method that needs to be called after user either accepts or reject continue watching consent.
  m.callbackAfterRokuCWConsent = invalid

  ' Used to keep track of if a video player is currently in the "stopping" state and we thus need to queue commands to all video nodes
  m.isVideoPlayerStopping = false

  ' Used to store the currently queued Video node command. Contents should either be invalid or should be an AA containing both
  ' "videoPlayerNode" which is the node for the video player and "command" which is the string we will pass to the control field of the videoPlayerNode node.
  m.queuedVideoPlayerCommand = invalid

  ' Used to store the password for a short period to allow not having to re-enter the password when changing parental controls
  m.passwordCache = invalid

  ' Format of data that should be set on viewableImpressionEventInfo
  ' {
  '   containerId: "" Contains the id of the row where the tile was displayed. ex: comedy etc.
  '   itemInfo: {
  '     row: 1 - Vertical position within a container, 1-based index
  '     col: 1 - Horizontal position within a container, 1-based index
  '     duration: 2000 - Total duration the tile was visible in milliseconds
  '     content_labels: {} - ContentLabels structure with metadata_labels, metadata, markers, poster_labels
  '   }
  '   screenId: "" - Contains id of the screen where the tile is displayed.
  '   screenTrackingInfo: Format: { pageType: "home_page", pageValues: {} }
  '   personalizationId: ""
  m.global.addField("viewableImpressionEventInfo", "assocarray", false)
  m.global.observeFieldScoped("viewableImpressionEventInfo", "onViewableImpressionEventInfoChange")

  ' Holds information related to queued viewable impression event info.
  ' Holds information related to all the program tiles that have been displayed to user and is in viewable area for more than 1 sec.
  m.viewableImpressionEvents = {
    containers: {} ' Contains a mapping of different tile with container id as a key. Each item inside the container will hold value matching format mentioned in the field m.global.viewableImpressionEventInfo above.
    pageOneof: invalid ' Contains value returned from getAnalyticsPage for the screen where tile is displayed . ex: {"home_page": {"content_mode": "CONTENT_MODE_MOVIE"}}
    personalizationId: "" ' Contains the value of personalization_id returned from backend home screen api call.
    screenId: "" ' Contains id of screen where the tile is visible. Possible values are from constants.ui.screenIds
  }

  ' Holds queued pivot impression events (similar to viewableImpressionEvents but for pivot items).
  ' Uses components/utility_tiles structure instead of containers/contents.
  m.pivotImpressionEvents = {
    utilityTiles: [] ' Array of utility tile impression data: { id, row, col, duration, dwell_time }
    pageOneof: invalid
    personalizationId: ""
    screenId: ""
  }

  m.sendImpressionEventTimer = CreateObject("roSGNode", "Timer")
  m.sendImpressionEventTimer.duration = 10
  m.sendImpressionEventTimer.observeFieldScoped("fire", "sendImpressionEvent")

  ' Used to know if we need to load the fox video player component library at the appropriate time.
  m.isFoxPlayerLoadRequired = true

  ' Stores a reference to the fox provided video player interface node
  m.foxRpfInstance = invalid

  ' Store the current fox player ad break that is being played. To allow us to be able remove ad breaks as they are completed to make our logic easier
  m.currentFoxPlayerAdBreak = invalid

  ' The position we last sent fox player progress from
  m.lastSentFoxPlayerProgressPosition = 0

  m.foxPlayerPositionSidelinedStarted = -1

  m.foxPlayerContinueWatchingNextSendPosition = rnd(getExternalConfigValueFromGlobal("special_event_continue_watching_init_jitter", 180))

  m.foxPlayerEndSlateCloseDelay = rnd(getExternalConfigValueFromGlobal("special_event_redirect_homepage_jitter", 300)) ' 5 minute default

  ' The listing that is currently being played with the fox video player stored or invalid if no content is being played
  m.foxPlayerCurrentListing = invalid

  ' We delay closing the fox video player when the end slate appears so we need to use store the timer for this on m to keep it alive
  m.foxPlayerEndSlateCloseDelayTimer = invalid

  ' Holds the fox listing api response.
  m.foxListingEndpointResponse = invalid

  ' The following fields are needed as a part of getUserInfo
  m.getHistoryIdsResponseReceived = false ' Have we received a response for history ids call (success or failure)
  m.getQueueIdsResponseReceived = false ' Have we received a response for getQueueIds call (success or failure)
  m.getUserPreferencesRateTitleLikedResponseReceived = false ' Have we received a response for getUserPreferencesRateTitleLiked call (success or failure)
  m.getUserPreferencesRateTitleDislikedResponseReceived = false ' Have we received a response for getUserPreferencesRateTitleDisliked call (success or failure)
  m.getUserInfoCallback = invalid ' Callback that will be fired after all required calls from getUserInfo have been completed

  ' This needs to go last as this will immediately call runControllerStartSequence if not logged in and we want all the initial state to be setup before this happens
  getUserInfo(onStartupAuthInfoReceived)

  getStatsigExperimentResource("", "roku_no_layer_experiment", true)
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


'triggered when signIn button is selected while updating auto play next video from auto play controls in the setting
Function onSignInModalSelectedViaAutoplayNextVideo()
  startSignIn(onAutoplayNextVideoAfterSignIn)
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
      ' if not then showing exit dialog since we have not loaded any screens since it is pre-requisite for loading home screen.
      currentScreen = getCurrentScreen()
      if currentScreen <> invalid AND currentScreen.id = m.constants.ui.screenIds.consentScreen
        displayExitModal(currentScreen.trackingPageInfo)
      else if m.SideNav.opened = true AND currentScreen <> invalid AND currentScreen.id = m.constants.ui.screenIds.vodDetailScreen
        hideNavMenu(true)
        focusCurrentScreen()
        return true
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

            sideNavId = m.constants.ui.screenIdToSideNavId[newTopScreen.id]
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
          m.top.getScene().appStartTime = Int(Uptime(0))
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
            m.top.getScene().appStartTime = Int(Uptime(0))
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
        currentScreen = getCurrentScreen()
        if currentScreen <> invalid AND currentScreen.hasField("sideNavFocusedPosition") = true
          currentScreen.sideNavFocusedPosition = m.SideNav.focusedPosition
          currentScreen.sideNavLeftNavSection = m.Tracking.sideNavPageMap[m.SideNav.itemCurrentId]
        end if
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
    manageChildFocus()
  end if
End Function


' We are breaking out the internal logic of onComponentFocus so that we can directly call it to work around a bug encountered during auth refactor. Call this to focus the appropriate child. Currently either the side nav or the current screen.
Function manageChildFocus()
  tubiLog("ContentController.manageChildFocus")
  if m.SideNav.opened = true
    displayNavMenu()
  else if getCurrentScreen() <> invalid
    getCurrentScreen().setFocus(true)
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
  m.top.getScene().exitApp = true
End Function


' This function is used to get rid of unused items in the registry due to removal features, unused experiments, etc.
' Each line that removes a registry item should include the date of when the the line is suspected to be included in production.
' We can remove the lines as they get stale. At times this function will not have any lines, but we can still include a call to the
' function for future reference.
Function cleanRegistry()
End Function


'''''''''''''''''''''''''
' runControllerStartSequence
'
' We need to gather information from various places. As callbacks fire when these different infos arrive,
' they all set some state on m and call runControllerStartSequence(). When all the information has arrived, as verified
' by the first checks in the function, then the function performs it's functionality to start the channel.
'
' IMPORTANT: this function should only be called as part of the initial start up process, it
'            should not be called in an effort to "restart the app".
Function runControllerStartSequence()
  tubiLog("ContentController.runControllerStartSequence")
  cleanRegistry()
  if m.isExternalConfigReady <> true OR m.isExperimentsConfigReady <> true OR m.isStatsigConfigReady <> true then
    ' Wait for external config, experiments config, and Statsig config to be ready before proceeding
    tubiLog("Waiting for configs - External: " + m.isExternalConfigReady.toStr() + ", Experiments: " + m.isExperimentsConfigReady.toStr() + ", Statsig: " + m.isStatsigConfigReady.toStr())
  else if m.uiGroup = invalid then
    m.performanceMetricsTracker.startAppLaunchMetricTiming("start_app_ui_load_after_configs")
    ' checks if the controller's UI has been added as children
    addControllerUi()
    ' checks if the startupArgs have been received from main thread
  else if m.startUpArgsHandled <> true
    ' checks if the logic has been run on the startupArgs.
    ' This is handled separately from onStartupArgs() because we
    ' cannot proceed with the logic in handleStartUpArgs() until the logic
    ' in addControllerUi() is run due to m.cmsApi needing to be set before
    ' calling handleStartupArgs()
    handleStartUpArgs()
  else if m.authInfoNeedsRefreshing = true
    ' External refresh token was passed in (ie. from mobile) and we are waiting for the network request with the updated auth info to proceed
  else if m.profileMigrationComplete <> true
    performProfileMigration()
    ' wait till we trasfer the user to the new profile
  else if m.isConsentCheckComplete <> true
    ' Below logic handles the use case where in the previous session if the user entered a age less than 18.
    ' and the user is in gdpr country. During the start up flow we are checking if the user is in gdpr country.
    ' then we are checking the if user hasage is false which means the age entered is not adult and he received a age gate error in previous session.
    ' since we have 24 hour lock here we are checking if the user is re-entering the app within the 24 hr lock expires.
    ' If he is within 24 hour lock window we will present the age gate error screen.
    ' If it has been past 24 hour lock window then we will continue as if a new guest user is launching the application.
    ' since backend clears the consent when user receives age gate error user will be presented with consent screen after 24 hours.
    if isOneTrustConsentEnabled() = true
      if m.guestUserHasAgeInfo = invalid then
        m.guestUserHasAgeInfo = getGuestUserHasAgeInfo()
      end if

      ' Have to make sure we check expired as well as default state will always have hasAge = false
      if m.guestUserHasAgeInfo.hasAge = false AND m.guestUserHasAgeInfo.expired = false then
        showGDPRAgeGateErrorScreen()
      else
        ' Makes an api request to get latest consent.
        getConsent(onInitialGetConsentRequestComplete)
      end if
    else
      getConsent(onInitialGetConsentRequestComplete)
    end if
  else if m.getServerPersistentDataComplete <> true
    getServerPersistentData(runControllerStartSequence)
  else if shouldShowAgeGate() = true AND m.ageVerificationComplete <> true
    authInfo = m.tubiAuthUpdate.getAuthInfo()
    ' check if we have age information for the user
    if isLoggedInUser(authInfo) = true
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
        runControllerStartSequence()
      end if
    else
      ' the user is a guest user, and we are not age gating guest users at app launch,
      ' so set m.ageVerificationComplete = true and recursively call this
      ' Function so we can move past the m.ageVerificationComplete check.
      m.ageVerificationComplete = true
      runControllerStartSequence()
    end if
  else if m.soTStaticConfigComplete = false
    ' Wait until the SoT static config is complete before proceeding.
    ' This is required because we call runControllerStartSequence() from the success or failure callback of the SoT static config request.
    ' If for some reason request is delayed and completes after all the other conditions are true then we will load the home / side nav.
    ' After which it will again try to load side nav and try to attach observers twice.
  else if m.startupDelayComplete = false then
    m.startupDelayComplete = true

    delaySeconds = getStatsigExperimentResource("roku_start_up_performance_test", "roku_start_up_performance_test_v1", true).delaySeconds

    if delaySeconds > 0 then
      timer = m.top.createChild("Timer")
      timer.observeFieldScoped("fire", "onStartupDelayTimerFired")
      timer.duration = delaySeconds
      timer.control = "start"
    else
      runControllerStartSequence()
    end if
  else
    m.performanceMetricsTracker.endAppLaunchMetricTiming("start_app_ui_load_after_configs")
    ' All of the above checked values are true, so we are ready to start the channel UI
    ' initSideNav must run after m.global.trackingLoggingTask is set in case there are any experiments
    ' within the side nav component that rely on trackingLoggingTask to send exposure events.
    ' initSideNav relies on m.kidsModeFeatureOn being set, so run after m.kidsModeFeatureOn is set.
    ' initSideNav also relies on registry auth info being set in order to run isParentalControlsAdultLevel
    initSideNav()

    showContentGroupAndHideSpinner()

    if m.authInfoRefreshed = true
      showToastAfterAuthRefreshFromMobile()
      m.authInfoRefreshed = false
    end if

    sendNielsenPing(m.constants.thirdParty.nielsen.pingTypes.sessionStart)
    sendDeviceEnvironmentSettingsLog()

    setUiModeAndLoadContent()
  end if
End Function


Function onStartupDelayTimerFired(msg)
  timer = msg.getRoSGNode()
  timer.getParent().removeChild(timer)

  runControllerStartSequence()
End Function


Function setUiModeAndLoadContent()
  setUiModeFromState()
  if m.enteredFromDeepLink = true
    tubiLog("ContentController detected deep link request")
    ' we were asked to deep link into a content item. Go to it
    ' whether we were logged in or not.
    handleDeeplink()
  else if isUserInMultiAccount() = true AND m.uiMode <> m.constants.ui.modes.kidsAgeGate
    authInfo = m.tubiAuthUpdate.getAuthInfo()


    handleRegularProfileSelection(authInfo.tubiId)

  else
    startChannelFromAppLoad()
  end if

  if getConsentOptOutStatusByKey(m.constants.consentKeys.marketing) = false
    configureBrazeAndInitializeTask()
  end if
End Function


' sendDeviceEnvironmentSettingsLog will check deviceInfo and send device-info to logging API
Function sendDeviceEnvironmentSettingsLog()
  deviceInfo = CreateObject("roDeviceInfo")
  drmInfo = deviceInfo.GetDrmInfoEx()
  model = deviceInfo.GetModel()
  modelType = deviceInfo.GetModelType()
  videoMode = deviceInfo.GetVideoMode().toInt()
  isHevcCompatible = (deviceInfo.CanDecodeVideo({ Codec: "hevc" }).result = true)

  deviceInfo = {
    isVideoPreviewOn: (isVideoPreviewOn() = true)
    isAutoPlayTimerOn: (isAutoPlayTimerOn() = true)
    autoPlay: m.constants.deviceInfo.isAutoplayEnabled
    drmInfo: drmInfo
    model: model
    modelType: modelType
    videoMode: videoMode
    isHevcCompatible: isHevcCompatible
  }
  logInfo(FormatJSON(deviceInfo), "clientInfo", "device-info", 0.2) 'send info to server

End Function


Function handleStartUpArgs()
  startupArgs = m.top.getScene().startupArgs
  if startupArgs <> invalid then
    m.deeplinkContent = createDeeplinkContentFromStartupArgs(startupArgs)
    utmCampaignConfig = generateUtmCampaignConfig(startupArgs)
    m.cmsApi.setUtmCampaignConfig(utmCampaignConfig)

    if m.constants.settings.mode <> "production" AND startupArgs.lastExitOrTerminationReason = "EXIT_BRIGHTSCRIPT_CRASH" then
      RegDeleteSection("experimentOverrides")
    end if

    if startupArgs.lastExitInfo <> invalid then
      sendLastExitInfoExperimentsClientLog(startupArgs.lastExitInfo)
    end if
  end if

  ' First see if the user is logged in. If they are then we don't use the external auth info.
  authInfo = m.tubiAuthUpdate.getAuthInfo()
  if isLoggedInUser(authInfo) <> true AND isUserInMultiAccount() = false
    ' checks if auth info has been received after a deeplink from external tubi device (iOS) supplied a refresh token
    externalAuthInfo = getExternalAuthInfoFromStartupArgs(startupArgs)
    ' Next make sure we have valid external auth info
    if externalAuthInfo <> invalid
      ' If so we want to let runControllerStartSequence know that it shouldn't continue until we have the updated auth info
      m.authInfoNeedsRefreshing = true

      m.tubiAuthUpdate.transferRefreshToken(externalAuthInfo, onAuthInfoRefreshed)
    end if
  else if isUserInMultiAccount() = true
    if startupArgs.tubiId <> invalid AND startupArgs.tubiId.unescape() <> "" AND startupArgs.tubiId.unescape() <> "0"
      tubiId = startupArgs.tubiId.unescape()
      if m.tubiAuthUpdate.getProfileAuthInfo(tubiId).count() > 0 'user already exists in the registry, so switch
        m.tubiAuthUpdate.copyProfileToMainAuth(tubiId)
      else
        externalAuthInfo = getExternalAuthInfoWithTubiIdFromStartupArgs(startupArgs)
        if externalAuthInfo <> invalid
          m.authInfoNeedsRefreshing = true
          m.tubiAuthUpdate.transferRefreshToken(externalAuthInfo, onAuthInfoRefreshed)
        end if
      end if
    end if

  end if

  ' Overriding deeplinkContent for external control source to invalid to avoid error dialog.
  ' This specifically covers a use case where roku uses it during automation testing for certification.
  ' The main purpose of this deep-linking is launching the application.
  if m.deeplinkContent <> invalid AND m.deeplinkContent.source = "deeplink-test" AND isNonEmptyString(m.deeplinkContent.type) = false AND isNonEmptyString(m.deeplinkContent.deeplinkType) = false
    m.deeplinkContent = invalid
  end if

  if m.deeplinkContent <> invalid
    m.enteredFromDeepLink = true
  end if

  m.startUpArgsHandled = true
  runControllerStartSequence()
End Function


Function onInputInfoReceived(msg)
  inputInfo = msg.getData()

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
  m.mainTask.transportVoiceResponse = transportVoiceResponse
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


'@args: assocArray, the startupArgs passed into main when the channel starts
Function getExternalAuthInfoWithTubiIdFromStartupArgs(args)
  ' deeplinks coming from ios or android devices need to be authenticated
  externalAuthInfo = invalid

  if args.refreshToken <> invalid AND args.userId <> invalid AND args.tubiId <> invalid AND args.deviceId <> invalid AND args.entry <> invalid
    if args.refreshToken.unescape() <> "" AND args.userId.unescape() <> "" AND args.userId.unescape() <> "0" AND args.tubiId.unescape() <> "" AND args.tubiId.unescape() <> "0" AND args.deviceId.unescape() <> ""
      if Lcase(args.entry) = "iphone" OR Lcase(args.entry) = "ipad" OR Lcase(args.entry) = "ios" OR Lcase(args.entry) = "android"
        externalAuthInfo = {
          platform: args.entry
          externalDeviceId: args.deviceId.unescape()
          externalRefreshToken: args.refreshToken.unescape()
          userId: args.userId.unescape()
          tubiId: args.tubiId.unescape()
          isUserInMultiAccount: true
        }
      end if
    end if
  end if

  return externalAuthInfo
End Function


' auth info has been added/refreshed after a deeplink from a "casting" device that contained a refreshToken
Function onAuthInfoRefreshed()
  tubiLog("ContentController.onAuthInfoRefreshed")
  m.authInfoNeedsRefreshing = false
  m.authInfoRefreshed = true

  status = "FAIL"
  authInfo = m.tubiAuthUpdate.getAuthInfo()

  if isAA(authInfo) = true AND authInfo.authType = "MOBILE_APP"
    status = "SUCCESS"
  end if


  ' send account analytics event signifying that auth info was transferred from another (mobile) device
  m.trackingLoggingTask.trackEvent = {
    type: "account"
    values: {
      manip: "SIGNIN"
      current: "MOBILE_APP"
      linked: ""
      user_type: ""
      message: ""
      status: status
    }
  }

  refreshUserInfoAndRunControllerStartSequence()
End Function


' called when the app calls an endpoint which reports an error due to the fact that the signed in user's account does not exist anymore.
'   This may be because when the app started, the user's accont existed. However, at some point while the app was still open, the user's account
'   was deleted. For example, the user or someone in the same household of the user went to the tubi website to delete the account.
Function onSignedInUserNotExistError(error)
  tubiLog("ContentController.onSignedInUserNotExistError")
  screen = getCurrentScreen()
  '//If a signed-in user is no longer exists and a video screen is not visible, then sign out user and set app to guest mode
  if screen.id <> m.constants.ui.screenIds.videoPlayerScreen AND screen.id <> m.constants.ui.screenIds.linearVideoPlayerScreen
    onSignOutModalSelected()
  end if
End Function


' called when a user's My List/Bookmarks/Queue is updated
Function handleQueueChange()
  if isLoggedInUser() = true AND isMajorEventDay() = false
    ' make request to get bookmarks/queue ids
    getQueueIds(onQueueRefresh)

    ' update My List containers on various screens
    setDirtyUserCategories(m.constants.ui.categoryIds.queue)
  end if
End Function


' called when a user's History is updated
Function handleHistoryChange()
  if isLoggedInUser() = true AND isMajorEventDay() = false
    ' make request to get history/continue watching ids
    getHistoryIds(onHistoryRefresh)

    ' update Continue Watching containers on various screens
    setDirtyUserCategories(m.constants.ui.categoryIds.history)
  end if
End Function


Function getQueueIds(successCallback, errorCallback = invalid)
  reqInfo = m.userDeviceApi.getQueueReqInfo()
  m.makeRequest({
    requestType: m.constants.reqNames.getQueue
    url: reqInfo.url
    options: reqInfo.options
    successCallback: successCallback
    errorCallback: errorCallback
    responseType: "node"
    silenceCallbackWarnings: true
  })
End Function


Function getHistoryIds(successCallback, errorCallback = invalid)
  reqInfo = m.userDeviceApi.getHistoryReqInfo()
  m.makeRequest({
    requestType: m.constants.reqNames.getHistory
    url: reqInfo.url
    options: reqInfo.options
    successCallback: successCallback
    errorCallback: errorCallback
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
    myStuffScreen = getFromScreenCache(m.constants.ui.screenIds.myStuffScreen)

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
      silenceCallbackWarnings: true
      responseType: "node"
      id: categoryId
      isSignedInUser: isLoggedInUser()
      screenId: m.constants.ui.screenIds.homeScreen
      uiMode: m.uiMode
    })

    '//Apply the movie, TV, myStuff, and Espanol filters if those screens exist
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
        silenceCallbackWarnings: true
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
        responseType: "node"
        silenceCallbackWarnings: true
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
        silenceCallbackWarnings: true
        responseType: "node"
        id: categoryId
        isSignedInUser: isLoggedInUser()
        screenId: m.constants.ui.screenIds.espanolScreen
        uiMode: m.uiMode
      })
    end if


    if myStuffScreen <> invalid
      optionMyStuff = {
        params: {}
      }
      myStuffImageParamTypes = [
        "poster"
        "hero"
      ]
      categoryReqInfo = m.CmsApi.createCategoryReqInfo(categoryId, isKidsMode, optionMyStuff, myStuffImageParamTypes)
      reqName = m.constants.reqNames.getMyStuffContainers
      m.makeRequest({
        url: categoryReqInfo.url
        requestType: reqName
        options: categoryReqInfo.options
        successCallback: onReloadUserCategoriesResponseInMyStuffScreen
        errorCallback: onErrorReloadUserCategoriesInMyStuffScreen
        responseType: "node"
        isSignedInUser: isLoggedInUser()
      })
    end if
  end if
End Function


Function onReloadUserCategoriesResponse(handledRequest)
  tubiLog("ContentController.onReloadUserCategoriesResponse")

  ' update the main home screen with the updated user category
  onReloadUserCategoriesInHomeScreen(handledRequest)

  categoryListScreen = getFromScreenCache(m.constants.ui.screenIds.categoryPanelListScreen)
  if categoryListScreen <> invalid
    categoryListScreen.reloadUserCategoriesResponse = handledRequest
  end if

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

  ' IMPROVEMENT could probably get rid of
  refreshAllDetailScreens()
  m.global.historyUpdated = true
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
    if m.kidsModeFeatureOn = true
      m.uiMode = mode
      setCommonKidsModeElements()
      m.sideNav.uiMode = mode
    end if
  else if mode = m.constants.ui.modes.kidsProfile
    'kids profile
    if m.kidsModeFeatureOn = true
      m.uiMode = mode
      setCommonKidsModeElements()
      m.sideNav.uiMode = mode
    end if
  else if mode = m.constants.ui.modes.kidsAgeGate
    'kids mode due to age gating
    if m.kidsModeFeatureOn = true
      m.uiMode = mode
      setCommonKidsModeElements()
      m.sideNav.uiMode = mode
    end if
  else if mode = m.constants.ui.modes.kidsParental
    ' kids mode due to parental controls
    if m.kidsModeFeatureOn = true
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

  tellScreensIfKidsModeBeSentToServer()
End Function


'@aPixelURLs: The array of pixel URLs that log when a non-video-player, screen ad has been seen
Function sendAdPixels(aPixelURLs)
  tubiLog("ContentController.sendAdPixels")
  if isNonEmptyArray(aPixelURLs) = true
    for each pixelURL in aPixelURLs
      '//the sStringToReplace is the agreed upon string that the backend will set to the param that is used for cachebusting.
      '//a cache busting string must be created within the Roku client and replace the sStringToReplace.
      sStringToReplace = "(ADRISE:CB)"
      sCacheBuster = createCacheBusterString()
      newPixelURL = pixelURL.replace(sStringToReplace, sCacheBuster)

      if isNonEmptyString(newPixelURL) = true
        encodedUrl = newPixelURL.EncodeUri()

        m.makeRequest({
          url: encodedUrl
          requestType: m.constants.reqNames.generic
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
  if isUserInMultiAccount() = false
    if isKidsProfile() = true 'this is only to ensure that if statsig fails and active user was kids profile, then at least we have kids UI.
      setUiMode(m.constants.ui.modes.kidsProfile)
      modeSet = true
    else if isKidsModeEnabledByParentalControls() = true
      setUiMode(m.constants.ui.modes.kidsParental)
      modeSet = true
    else if shouldShowAgeGate() = true then
      if m.guestUserHasAgeInfo = invalid then
        m.guestUserHasAgeInfo = getGuestUserHasAgeInfo()
      end if

      ' Have to make sure we check expired as well as default state will always have hasAge = false
      if m.guestUserHasAgeInfo.hasAge = false AND m.guestUserHasAgeInfo.expired = false then
        setUiMode(m.constants.ui.modes.kidsAgeGate)
        modeSet = true
      end if

    end if
  else
    authInfo = m.tubiAuthUpdate.getAuthInfo()
    setUiModeForProfileSelected(authInfo)
    modeSet = true
  end if

  if modeSet = false then
    setUiMode(m.constants.ui.modes.standard)
  end if
End Function


' a helper function to update the UI to a "kids mode" and which should only be
' called from within setUiMode()
Function setCommonKidsModeElements()
  if m.kidsModeFeatureOn = true
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
  if m.uiMode = m.constants.ui.modes.kids OR m.uiMode = m.constants.ui.modes.kidsAgeGate OR m.uiMode = m.constants.ui.modes.kidsParental OR m.uiMode = m.constants.ui.modes.kidsProfile
    return true
  end if
  return false
End Function


Function isKidsModeEnabledByParentalControls() as Boolean
  tubiLog("ContentController.isKidsModeEnabledByParentalControls")
  bEnabled = false

  authInfo = m.tubiAuthUpdate.getAuthInfo()
  pcRating = m.pub_serverPersistentData.parentalRating
  if isLoggedInUser(authInfo) = true AND (pcRating < 2 OR pcRating = 4 OR pcRating = 5) then
    bEnabled = true
  end if
  return bEnabled
End Function


Function isKidsProfile(authInfo = invalid) as Boolean
  bEnabled = false
  if authInfo = invalid
    authInfo = m.tubiAuthUpdate.getAuthInfo()
  end if

  isKidsRating = false
  authPCRating = authInfo.parentalRating

  authPCStr = AnyToStringButNotInvalid(authPCRating)

  if authPCStr <> invalid AND authPCStr <> ""
    pcRating = authPCStr.toInt()

    if pcRating < 2 OR pcRating = 4 OR pcRating = 5
      isKidsRating = true
    end if
  end if

  if isLoggedInUser(authInfo) = true AND isKidsRating = true AND isNonEmptyString(authInfo.parentId) = true then
    bEnabled = true
  end if

  return bEnabled
End Function


Function isParentalControlsAdultLevel() as Boolean
  tubiLog("ContentController.isParentalControlsAdultLevel")
  bEnabled = true

  authInfo = m.tubiAuthUpdate.getAuthInfo()
  if isLoggedInUser(authInfo) = true AND m.pub_serverPersistentData.parentalRating <> 3 then
    bEnabled = false
  end if

  return bEnabled
End Function


Function isParentalControlsTeensLevel() as Boolean
  tubiLog("ContentController.isParentalControlsTeensLevel")
  bEnabled = false

  authInfo = m.tubiAuthUpdate.getAuthInfo()
  if isLoggedInUser(authInfo) = true
    if m.pub_serverPersistentData.parentalRating = 2
      bEnabled = true
    end if
  end if

  return bEnabled
End Function


Function refreshAllDetailScreens()

  for i = 0 to m.screenStack.getChildCount() - 1
    screen = m.screenStack.getChild(i)

    if screen.subType() = "DetailScreen"
      content = screen.content 'No need to re fetch the content, just re populate the screen content
      if isUserInMultiAccount() = true
        if screen.content <> invalid AND screen.content.validUntil <> invalid
          screen.content.validUntil = 0
        end if
      end if
      populateDetailScreen(screen, content, false, -1)
      resetRelatedContent(screen)
      screen.isWaitingForServerResponse = false
    else if screen.subType() = "EpisodesScreen"
      ' if user signs-In on episode screen, then to refresh the episode screen, We need to refresh the associated detail screen.
      ' refreshing the detail screen will ensure both detailscreen and episode screen gets refreshed to remove all registration gated related designs
      ' like lock icon on episodes, message on infopanel and sign-in-to-play button etc
      screen = getTopDetailScreenFromStack()
      refreshDetailScreenContent(screen)
      resetRelatedContent(screen)
    else if screen.subType() = "CategoryDetailsScreen"
      if screen.content <> invalid AND screen.content.validUntil <> invalid
        screen.content.validUntil = 0
      end if
    end if
  end for
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


' @screenId: string, the id of the screen shows content cache needs to be cleared.
Function deleteScreenContentCache(screenId)
  m.cache.deleteScreenContentCache(screenId)
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
  setContentToRefresh(m.constants.ui.screenIds.categoryPanelListScreen)
  setContentToRefresh(m.constants.ui.screenIds.epgScreen)
  setContentToRefresh(m.constants.ui.screenIds.linearVideoPlayerScreen)
  setContentToRefresh(m.constants.ui.screenIds.myStuffScreen)

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


Function onScreenPageErrorInfoChange(msg)
  screenPageErrorInfo = msg.getData()
  screen = msg.getRoSGNode()
  showErrorModal(screenPageErrorInfo)

  cleanupLoadingScreen(screen)
End Function


' Removes passed in screen from m.currentlyLoadingScreens if it exists and returns the timespan of the time it took to load
Function cleanupLoadingScreen(screen)
  ' Clear up the screen if it was still loading
  for i = 0 to m.currentlyLoadingScreens.count() - 1
    loadingScreen = m.currentlyLoadingScreens[i]
    timespan = loadingScreen.timespan
    if screen.isSameNode(loadingScreen.screen) = true
      m.currentlyLoadingScreens.delete(i)
      return timespan
    end if
  end for

  return invalid
End Function


Function sendNavigateWithinPageInfo(navigateWithinPageInfo)
  if navigateWithinPageInfo <> invalid
    event = {
      type: "navigate_within_page"
      values: navigateWithinPageInfo
    }
    fireUserTrackingEvent(event)
  end if
End Function


' Callback for when a componentInteractionInfo has been updated - sends the component_interaction event
Function onComponentInteractionInfoChange(msg)
  componentInteractionInfo = msg.getData()
  sendcomponentInteractionInfo(componentInteractionInfo)
End Function


Function sendcomponentInteractionInfo(componentInteractionInfo)
  if componentInteractionInfo <> invalid
    event = {
      type: "component_interaction"
      values: componentInteractionInfo
    }

    fireUserTrackingEvent(event)
  end if
End Function


Function onVideoContentScreenBackgroundUpdated(msg)
  tubiLog("ContentController.onVideoContentScreenBackgroundUpdated")
  screen = msg.getRoSGNode()
  updateVideoTileScreenBackground(screen.contentFocused, screen)
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


Function setVideoContentScreenBackground(screen, content = invalid)
  tubiLog("ContentController.setVideoContentScreenBackground")
  currentScreen = getCurrentScreen()
  if screen <> invalid AND currentScreen <> invalid AND screen.id = currentScreen.id AND (screen.contentFocused <> invalid OR content <> invalid)
    if content <> invalid
      contentFocused = content
    else
      contentFocused = screen.contentFocused
    end if
    contentType = contentFocused.type
    gridItemType = contentFocused.gridItemType
    videoPreviewState = getVideoPreviewState()

    isSkinAdRowContent = (isCurrentScreenHomeScreen() = true AND gridItemType = m.constants.ui.gridItemTypes.skinAd)
    isAdCarouselRowContent = gridItemType = m.constants.ui.gridItemTypes.adRowlistCarousel
    if contentFocused.gridItemType = m.constants.ui.gridItemTypes.liveEventSpotlight
      displayFullScreenVideoBackground(contentFocused)
    else if (videoPreviewState = "playing" OR videoPreviewState = "paused" OR videoPreviewState = "buffering" OR isVideoPreviewPlayQueued() = true) AND isSkinAdRowContent = false AND isAdCarouselRowContent = false
      m.backgroundGroup.backgroundInfo = {
        type: m.constants.ui.backgroundTypes.epg
        uriList: [] ' setting uriList as empty, because don't need to rotate the background poster when video preview is playing. We can't use shouldRotateBackgrounds because we still need the gradients from backgroundGroup
      }
    else if (videoPreviewState = "playing" OR videoPreviewState = "paused") AND isSkinAdRowContent = true

      m.backgroundGroup.backgroundInfo = {
        type: m.constants.ui.backgroundTypes.skinAd
        uriList: screen.backgroundUriList
      }
    else if (videoPreviewState = "playing" OR videoPreviewState = "paused") AND isAdCarouselRowContent = true

      m.backgroundGroup.backgroundInfo = {
        type: m.constants.ui.backgroundTypes.adRowlistCarousel
        uriList: screen.backgroundUriList
      }
    else
      backgroundUriList = screen.backgroundUriList
      if isNonEmptyArray(backgroundUriList) = false AND contentFocused <> invalid AND isNonEmptyArray(contentFocused.backgrounds) = true
        backgroundUriList = contentFocused.backgrounds
      end if
      if isSkinAdRowContent = true
        backgroundType = m.constants.ui.backgroundTypes.skinAd
      else if isAdCarouselRowContent = true
        backgroundType = m.constants.ui.backgroundTypes.adRowlistCarousel
      else
        backgroundType = getBackgroundType(backgroundUriList, contentType)
      end if
      m.backgroundGroup.backgroundInfo = {
        type: backgroundType
        uriList: backgroundUriList
      }
    end if
  else if screen <> invalid AND screen.backgroundUriList <> invalid AND screen.id = m.constants.ui.screenIds.myStuffScreen
    ' Else logic gets executed in case of my stuff guest user where we do not have a valid focused content.
    m.backgroundGroup.backgroundInfo = {
      type: m.constants.ui.backgroundTypes.topRight
      uriList: screen.backgroundUriList
    }
  end if
End Function


Function onSponsorshipBackgroundChanged(msg)
  tubiLog("ContentController.onSponsorshipBackgroundChanged")
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


' Setting a new background color. Usually this is not called unless there is a special case: i.e. sponsorship requiring different background color
' @sColor: string, The color that the background should be.
Function setBackgroundColor(sColor)
  m.backgroundGroup.circularMaskColor = sColor
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
    type: m.constants.ui.backgroundTypes.fullScreen
    uriList: []
  }
End Function


Function displayFullScreenVideoBackground(content)
  if isNode(content) = true AND isNonEmptyArray(content.backgrounds) = true then
    m.backgroundGroup.backgroundInfo = {
      type: m.constants.ui.backgroundTypes.spotlight
      uriList: content.backgrounds
    }
  else
    displayDefaultBackground()
  end if
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


' fireAppLoadTimeEvent
'
' Fire off a log to a server so we can track how long it took since the app was started
Function fireAppLoadTimeEvent(loadTime)
  messageInfo = {
    loadtime: loadTime
    model: m.constants.deviceInfo.model
  }
  logInfo(FormatJSON(messageInfo), "clientInfo", "time-to-load", 0.1) 'send info to server
End Function


'''''''''''''''''''''''
' getBackgroundtype
'
' Helper function to get the background type depending on if passed in uri list is using the default image
' @backgroundUriList, array of uris
' @contentType, String - depending on the focused on content, it will determine the background type
Function getBackgroundType(backgroundUriList, contentType = "")
  backgroundType = m.constants.ui.backgroundTypes.fullScreen

  ' backgroundUriList will only be empty when the background type is full screen, we do not expect it to be empty for topRight version of background.
  if isNonEmptyArray(backgroundUriList) = true
    if contentType = m.constants.ui.contentTypes.linear OR contentType = m.constants.ui.contentTypes.epg
      backgroundType = m.constants.ui.backgroundTypes.epg
    else if contentType = m.constants.ui.contentTypes.adRowlistSpotlight OR contentType = m.constants.ui.contentTypes.adRowlistCarousel
      backgroundType = m.constants.ui.backgroundTypes.adRowlistSpotlight
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
        pageOneof: trackingLib.getAnalyticsPage("home_page", { content_mode: "CONTENT_MODE_UNKNOWN" })
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

  userErrorCode = getUserFacingErrorCode("1", "300", "")

  title = getTranslation("dialog_defaultError_title")

  template = { "errCode": userErrorCode }
  message = getTranslation("component_library_failed", template)

  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: "NETWORK_ERROR" 'DialogType enum
      pageOneof: trackingLib.getAnalyticsPage("home_page", { content_mode: "CONTENT_MODE_UNKNOWN" })
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
  loadTime = currentTime - m.top.getScene().appStartTime

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
  m.isApplicationSuspendInProgress = true
  customSuspendArgs = msg.getData()

  ' Firing any viewable impression if present in queue.
  sendImpressionEvent()

  ' Setting to false as a safety in case we have missed a spot where we needed to reset to false.
  ' This way they just have to background the app instead of totally restarting it to get video playing again.
  m.isVideoPlayerStopping = false

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
      returnToDetailScreenFromVideo(false, false, "home")
    else if currentScreen <> invalid AND (currentScreen.id = m.constants.ui.screenIds.categoryDetailsScreen OR currentScreen.id = m.constants.ui.screenIds.categoryPanelListScreen)
      ' if current screen is categoryDetailsScreen, instant resume action is to start the channel from the homescreen (not a full channel restart).
      ' Remove the parent screen from the cache so that it is reloaded if a user navigates back to it in order to prevent a UX bug such that the cached screen
      ' is displayed but nothing is displayed on the screen.
      deleteFromScreenCache(m.constants.ui.screenIds.channelListScreen)
      deleteFromScreenCache(m.constants.ui.screenIds.categoryPanelListScreen)
    else
      ' if the focus is on live TV row, stop the playback
      linearVideoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
      if linearVideoPlayer <> invalid
        closeLinearVideoPlayerTransport()
        linearVideoPlayer.control = "stop"
      end if

      ' This is needed to avoid having to use alwaysnotify on featuredListHasFocus and when app is suspended it does not fire focus change event on home screen.
      if currentScreen <> invalid
        currentScreen.listHasFocus = false
      end if
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

    ' If any of the one trust screens were open we are force closing them.
    ' We have 2 OT Screens OTBanner(Initial Consent Screen) and OTPreferenceCenter which is opened when users clicks view privacy settings from settings screen.
    ' If the OTBanner screen was open then we do not have any Tubi Screens opened yet and currentScreen will be invalid which will result in application restart as a part of logic inside onCustomResume method.
    ' If OTPreferenceCenter was open that means user is in Settings Screen and Settings screen has instantResumeAction: "startChannel" which will cause the focus to be reset to home by logic below.
    oneTrustViews = m.top.findNode("OneTrustViews")
    if oneTrustViews <> invalid
      m.NodeHelpers.removeAllChildren(oneTrustViews)
    end if

    closeFoxVideoPlayer()

    ' Since linear screens are time sensitive the content might not be available at the time of resume.
    if currentScreen <> invalid AND currentScreen.id = m.constants.ui.screenIds.linearDetailScreen
      popScreen(false, false)
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
  m.isApplicationSuspendInProgress = false
  args = msg.getData()

  lastSuspendOrResumeReason = invalid
  customResumeLaunchParams = invalid
  bRestartApp = false
  bStartChannel = false
  shouldResumeChannel = false

  if args <> invalid
    customResumeLaunchParams = args.launchParams
    lastSuspendOrResumeReason = args.lastSuspendOrResumeReason
    if isAA(customResumeLaunchParams) = true AND customResumeLaunchParams.clearRegistry <> invalid OR customResumeLaunchParams.setRegistry <> invalid then
      ' If the application is already running and we want to mess with the registry then we close the application to allow the registry code to be centralized in one spot.
      setExitApp()
    end if
  end if
  currentScreen = getCurrentScreen()
  if lastSuspendOrResumeReason = "home" AND customResumeLaunchParams <> invalid
    ' User coming back to app via instant resume is considered as returning user
    m.global.isNewUser = false

    lastAppSuspendInSecs = m.appSuspendTimer.TotalSeconds()
    lastAppRestartInDays = m.lastAppRestartTimer.TotalSeconds() / 24 / 60 / 60

    retrieveClientErrorConfig()

    if RegRead("applicationRestartRequired", m.constants.registrySectionIDs.settingsOverride) = "true" then
      RegDelete("applicationRestartRequired", m.constants.registrySectionIDs.settingsOverride)
      bRestartApp = true
    else if (customResumeLaunchParams.contentId <> invalid AND customResumeLaunchParams.mediaType <> invalid) OR customResumeLaunchParams.page <> invalid
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
          else if currentScreen.id = m.constants.ui.screenIds.eventDetailScreen AND currentScreen.inDisasterMode = true
            ' Force restarting the application in case user was in disaster mode when he pressed home.
            bRestartApp = true
          else if currentScreen.instantResumeAction = m.constants.instantResumeActions.startChannel
            'calling startChannel() instead of restartChannel() since restartChannel() can land a user on the ICTS screen, but we only want users to land on the home screen
            bStartChannel = true
          else
            sendNielsenPing(m.constants.thirdParty.nielsen.pingTypes.sessionStart)
            shouldResumeChannel = true
          end if
        else
          'Unknown state, backup solution to restart app.
          bRestartApp = true
        end if
      end if
    end if
  else if lastSuspendOrResumeReason = "screensaver"
    ' Do nothing, but leave this as a place holder.
    ' The app will resume as normal for the screensaver.
  end if

  ' If the current screen has a purple carpet container, initiate a request to refresh the container data.
  if currentScreen <> invalid AND isCurrentScreenHomeScreen() = true
    if currentScreen.content <> invalid AND shouldRefresh(currentScreen.content) = true
      bRestartApp = true
    end if
  end if

  '// If the resume app action is to restart the app or start the channel, then 1st see if the previously played linear video can be played (if one exists)
  if bRestartApp = true
    restartApp()
  else if bStartChannel = true
    startChannelFromInstantResume()
  else
    if shouldResumeChannel = true
      resumeApp()
    end if

    ' We are force updating the content on resume since doing it during suspend was resulting in roku not showing images.
    if currentScreen <> invalid AND currentScreen.id = m.constants.ui.screenIds.episodeScreen
      currentScreen.updateContent = true
    end if

  end if

  if bRestartApp = false
    ' We want to consider instant resume as a new braze session. So we are restarting braze session.
    restartBrazeSession()
  end if
End Function


' This is the fail safe startChannel function to be called if the previously played linear video could not be played
Function startChannelFromAppLoad()
  startChannel()

  ' this should only exist temporarily.
  ' TODO: Remove this toast if block after the dates below
  ' TODO: Additionally remove logic within TubiToast
  '       that handles the isStyled field, as it only exists for this
  '       one time toast message to show that the ToS have updated
  ' TODO: Additionally remove the StyledToastComponent

  toastStartTime = "2024-04-21 18:00:00.000" '11am PT
  toastEndTime = "2024-04-27 06:59:59.000" '11:59pm PT the day before
  if isNewUser() = false AND isNowWithinTimePeriod(toastStartTime, toastEndTime) = true
    toastInfo = {
      message: getTranslation("updated_terms_toast_message")
      headerText: getTranslation("updated_terms_toast_header")
      selfDestructTimer: 15
      isStyled: true
    }

    homepageInfo = {
      pageType: "home_page"
      pageValues: {
        content_mode: "CONTENT_MODE_UNKNOWN"
      }
    }
    dialogEventInfo = {
      type: "dialog"
      values: {
        dialog_type: "TOAST"
        pageOneof: m.Tracking.getAnalyticsPage(homepageInfo.pageType, homepageInfo.pageValues)
        dialog_action: "SHOW"
        dialog_sub_type: "updated_terms"
      }
    }
    showToast(toastInfo, true, dialogEventInfo)
  end if

  if m.top.isComponentLibFailedToLoad = true
    showPackedVersionLoadedModal(m.Tracking, m.trackingLoggingTask)
  end if

  showUpgradeModal(m.constants.showUpgradeAlert, m.Tracking, m.trackingLoggingTask) 'show as necessary
End Function


' This is the fail safe startChannel function to be called if the previously played linear video could not be played
Function startChannelFromInstantResume()
  sendNielsenPing(m.constants.thirdParty.nielsen.pingTypes.sessionStart)
  startChannel()
End Function


' restarts the app from beginning of the line in order to retrieve starter/remote components
Function restartApp()
  tubiLog("ContentController.restartApp")
  clearScreenStack()

  ' Forces the external config to be retrieved again on startup
  m.global.externalConfigInfo = invalid
  m.global.experimentsInfo = invalid
  m.global.statsigExperimentsInfo = invalid

  m.top.getScene().disableInstantResume = true
  m.mainTask.control = "done"
  m.trackingLoggingTask.control = "done"
  m.generalTask.control = "done"
End Function


' If we get a user not found then we need to logout the user and restart the application. Added param to allow to be used in cases that expect the callback to take a param.
Function logoutAndRestartApp(_ = invalid)
  logout(restartApp)
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
    if screen.id = m.constants.ui.screenIds.homeScreen OR isAnEpgScreen(screen) = true
      if screen.id = m.constants.ui.screenIds.homeScreen
        contentToPlay = screen.contentFocused
      else
        contentToPlay = screen.linearChannelToPlay
      end if

      if contentToPlay <> invalid AND contentToPlay.needsLogin = true
        'if Content is locked and do not show countDown.
        screen.fullscreenCountdown = -1
      else
        nCurrentCount = screen.fullscreenCountdown
        nNewCount = nCurrentCount - 1
        screen.fullscreenCountdown = nNewCount
        if nNewCount <= 0
          selectLinearContent(contentToPlay)
        end if

        if isVideoTileEnabledScreen() = true AND nNewCount > 0
          if nNewCount + 1 = m.constants.settings.linearFullscreenTimeout
            fade(m.autoStartPreviewToPlaybackTimer, "in", 0.1)
          end if
          renderAutoStartPlaybackFromPreviewCounter(contentToPlay, nNewCount + 1)
        else
          fade(m.autoStartPreviewToPlaybackTimer, "out", 0.1)
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
  Auth = TubiAuth(m.constants)
  tcfString = getTCFString()
  consentOptOutStatus = getConsentsOptOutStatus()
  gdpr = isOneTrustConsentEnabled()
  adLib = TubiAdsLimited(m.constants, Auth, tcfString, consentOptOutStatus, gdpr)
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
' @presentedByURL : string, a url of an image which represents someone sponsoring the app
' @presentedByText : string, a string to be displayed before the image representing the presentedByURL
Function showHideLogoBasedOnUiMode(presentedByURL = "", presentedByText = "")
  mode = m.uiMode

  if mode = m.constants.ui.modes.standard
    showHideLogo(m.constants.logoType.tubi, presentedByURL, presentedByText)
  else if mode = m.constants.ui.modes.kids OR mode = m.constants.ui.modes.kidsAgeGate OR mode = m.constants.ui.modes.kidsParental OR mode = m.constants.ui.modes.kidsProfile
    showHideLogo(m.constants.logoType.tubiKids, presentedByURL, presentedByText)
  else if mode = m.constants.ui.modes.latino
    showHideLogo(m.constants.logoType.tubiEspanol, presentedByURL, presentedByText)
  end if

End Function


' @logoType : string, one of the following from m.constants.ui.modes
' "tubi" =  show tubi logo,
' "tubi_kids" = show tubi kids logo,
' "tubi_espanol" = show espanol logo,
' "hide" = hide all logos
' @presentedByURL : string, a url of an image which represents someone sponsoring the app
' @presentedByText : string, a string to be displayed before the image representing the presentedByURL
Function showHideLogo(logoType, presentedByURL = "", presentedByText = "")

  if m.logoType <> logoType
    tubilog("ContentController.showHideLogo")

    if logoType = m.constants.logoType.hide
      m.logoEspanol.visible = false
      m.logoKids.visible = false
      m.logo.visible = false
      m.presentedByGroup.visible = false
    else
      if logoType = m.constants.logoType.tubiKids
        m.logoKids.visible = true
        m.logo.visible = false
        m.logoEspanol.visible = false
      else if logoType = m.constants.logoType.tubiEspanol
        m.logoEspanol.visible = true
        m.logoKids.visible = false
        m.logo.visible = false
      else 'default is tubi logo
        m.logo.visible = true
        m.logoEspanol.visible = false
        m.logoKids.visible = false
      end if

    end if

    m.logoType = logoType

  end if

  '//Display/hide sponsored info.
  '//Even if the logoType <> m.constants.logoType.hide, the presentedByGroup may need to be hidden.
  if isNonEmptyString(presentedByURL) = true
    m.presentedByGroup.visible = true
    m.presentedByImage.uri = presentedByURL + "?w=" + m.constants.ui.logoSizes.skinAds.homeScreen.width

    if isNonEmptyString(presentedByText) = true
      m.presentedByLabel.text = presentedByText
    else
      m.presentedByLabel.text = ""
    end if

    presentedByBoundingRect = m.presentedByGroup.boundingRect()
    presentedWidth = presentedByBoundingRect.width
    presentedHeight = presentedByBoundingRect.height
    logoWidth = m.logo.boundingRect().width
    ' 1865 = (screenWidth - right margin)
    x1 = (1865 - presentedWidth) + 24 + (presentedWidth / 2) ' 159 =  135 + 24
    m.presentedByGroup.translation = [x1, 33]
    m.logo.translation = [1865 - logoWidth, presentedHeight + 54]
  else
    m.presentedByGroup.visible = false
    m.logo.translation = [1731, 54]
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
        returnToDetailScreenFromVideo(false, true, "hdmi")
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


Function sendLastExitInfoExperimentsClientLog(lastExitInfo)
  tubiLog("ContentController.onLastExitInfoChange")
  messageMap = lastExitInfo
  messageMap["connectionType"] = createObject("roDeviceInfo").getConnectionType()
  getExperimentsInfoFromGlobal()

  experiments = getExperimentsInfoFromGlobal()
  if experiments <> invalid then
    experimentsMapped = {}

    for each experimentKey in experiments
      experiment = experiments[experimentKey]
      experimentsMapped[experimentKey] = experiment.resource
    end for
    messageMap["experiments"] = formatJson(experimentsMapped)
  end if

  logInfo(messageMap, "clientInfo", "last-exit-info-experiments")
End Function


' Screens can request to show a toast by assigning proper values to
' the toastInfo field.
Function onShowToastMessage(msg)
  toastInfo = msg.getData()
  showToast(toastInfo)
End Function


' showToast -  displays the message on screen like Android toast message.
' Toast width is based on message or title length whichever is lengthier.
'   max width = 642
'   min width = 444
'   max height = 176
'   min height = 112
'
'@toastInfo: assocArray, it contains below
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
Function showToast(toastInfo, shouldSendTracking = false, dialogEventInfo = {})
  m.tubiToast = m.top.findNode("tubiToast")
  if isAA(toastInfo) = true
    m.tubiToast.toastInfo = toastInfo
    m.tubiToast.show = true

    if shouldSendTracking = true AND dialogEventInfo.count() > 0
      m.trackingLoggingTask.trackEvent = dialogEventInfo
    end if
  end if
End Function


Function isVideoPreviewOn()
  if m.pub_serverPersistentData <> invalid
    return (isVideoPreviewEnabled() = true AND m.pub_serverPersistentData.isVideoPreviewOn = true)
  end if

  return false
End Function


Function isAutoPlayTimerOn()
  return (m.pub_serverPersistentData.isAutoPlayTimerOn = true)
End Function


' @userInteraction: string, user interaction values are TOGGLE_ON, TOGGLR_OFF and  CONFIRM.
' @pageInfo: assocarray, value can be { pagetype: "account_page", pagevalues: {}}
' @componentType: string, type of the component from getOneOf in tubiracking.
' @componentValue: assocarray, value of the component from from getOneOf in tubitracking.
Function getComponentInteractionInfo(userInteraction, pageInfo, componentType, componentValue)
  componentInteractionInfo = {
    pageOneof: m.Tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
    componentOneof: m.Tracking.getAnalyticsComponent(componentType, componentValue)
    user_interaction: userInteraction
  }

  return componentInteractionInfo
End Function


' Sends ComponentInteractionEvent for button interactions (OK/Play/Back/Left).
' buttonValue: "OK", "PLAY", "LEFT", or "BACK" depending on which button user pressed.
' buttonType: "TEXT", "IMAGE", or "UNKNOWN" based on how the button appears.
' userInteraction: "CONFIRM" for OK/Play/Left, "BACK" for Back key.
' screen: optional; if invalid, uses getCurrentScreen(). Must have trackingPageInfo (pageType, pageValues).
Function sendButtonComponentInteractionEvent(buttonValue as String, buttonType as String, userInteraction = "CONFIRM", screen = invalid) as Void
  if screen = invalid then screen = getCurrentScreen()
  if screen = invalid OR screen.trackingPageInfo = invalid OR isNonEmptyString(screen.trackingPageInfo.pageType) = false then return
  pageInfo = screen.trackingPageInfo
  componentValues = {
    button_type: buttonType
    button_value: buttonValue
  }
  componentInteractionInfo = getComponentInteractionInfo(userInteraction, pageInfo, "button_component", componentValues)
  sendcomponentInteractionInfo(componentInteractionInfo)
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
  tubiLog("ContentController.isUserInAdultsMode")
  adultsMode = true

  ' Checking gf the parental control is not in adults level.
  if isParentalControlsAdultLevel() = false
    adultsMode = false
  else if shouldShowAgeGate() = true then
    if m.guestUserHasAgeInfo = invalid then
      m.guestUserHasAgeInfo = getGuestUserHasAgeInfo()
    end if

    ' Have to make sure we check expired as well as default state will always have hasAge = false
    if m.guestUserHasAgeInfo.hasAge = false AND m.guestUserHasAgeInfo.expired = false then
      adultsMode = false
    end if
  end if

  return adultsMode
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
  ' We noticed that if braze responds quickly and our endpoints take time we ended up showing the braze modal before even home screen loaded.
  ' Moving it here allows the application to load required endpoints and also menu etc before we start braze.
  ' Configuring the braze sdk.
  configureBrazeSdk()
  ' Starting the braze task.
  m.brazeTask = CreateObject("roSGNode", "BrazeTask")
  ' Stopping the braze task until we know the user logged in status so that we can present non logged in user modal for logged in user.
  m.braze = getBrazeInstance(m.brazeTask)
  m.brazeTask.unobserveFieldScoped("BrazeInAppMessage")
  m.brazeTask.observeFieldScoped("BrazeInAppMessage", "onInAppMessageTriggered")
  authInfo = m.tubiAuthUpdate.getAuthInfo()
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
  m.top.getScene().rokuContinueWatchingRequestInfo = requestInfo
End Function


Function refreshUserInfoAndRunControllerStartSequence()
  isMultiAccount = isUserInMultiAccount()
  getUserSettingsRequest = m.userDeviceApi.createUserSettingsGeneralTaskReqInfo(onGetUserInfoSuccess, onGetUserInfoFailure, isMultiAccount)
  m.makeRequest(getUserSettingsRequest)
End Function


Function onGetUserInfoSuccess(userInfo)
  if userInfo <> invalid
    Auth = m.tubiAuthUpdate
    if userInfo.firstName <> invalid
      Auth.setAuthInfo("firstname", userInfo.firstName)
    end if

    if userInfo.lastName <> invalid
      Auth.setAuthInfo("lastname", userInfo.lastName)
    end if

    if userInfo.name <> invalid
      Auth.setAuthInfo("name", userInfo.name)
    end if

    if userInfo.hasAge <> invalid
      Auth.setAuthInfo("hasAge", userInfo.hasAge)
    end if

    if userInfo.userUuid <> invalid
      Auth.setAuthInfo("userUuid", userInfo.userUuid)
    end if

    if userInfo.avatarUrl <> invalid
      Auth.setAuthInfo("avatarUrl", userInfo.avatarUrl)
    end if

    if userInfo.hasPin <> invalid
      Auth.setAuthInfo("hasPin", userInfo.hasPin)
    end if

    if userInfo.tubiId <> invalid
      Auth.setAuthInfo("tubiId", userInfo.tubiId)
    end if

    if userInfo.email <> invalid
      Auth.setAuthInfo("email", userInfo.email)
    end if
  end if


  runControllerStartSequence()
End Function


Function onGetUserInfoFailure(_error)
  ' We can't call runControllerStartSequence directly because the error callback is expecting a function that takes a single parameter.
  runControllerStartSequence()
End Function

' We need to route commands to Video nodes through this function to allow us to queue them if one of our video nodes is currently stopping
' @videoPlayerNode: string, the component containing the Video player node (ie. VideoPlayerScreen, LinearVideoPlayerScreen, etc.)
' @command: string, the command being requested to be sent to the Video node's control field
Function sendVideoPlayerCommand(videoPlayerNode, command)
  if (command = "play" OR command = "prebuffer") AND m.isVideoPlayerStopping = true then
    m.queuedVideoPlayerCommand = {
      "videoPlayerNode": videoPlayerNode,
      "command": command
    }
  else
    videoPlayerNode.control = command
  end if
End Function



' This function helps keep track of each video player's state so that we can know when we enter the new "stopping" state caused by using asyncStopSemantics=true.
' If we receive certain commands during this time we will queue those. Once state changes to "stopped" we can then trigger the queued command if one exists
' @videoPlayerState: string, state output field from LinearVideoPlayerScreen, VideoPreviewPlayer or VideoPlayerScreen
Function trackVideoPlayerStoppingState(videoPlayerState)
  if videoPlayerState = "stopping" then
    m.isVideoPlayerStopping = true
  else if videoPlayerState = "stopped" then
    m.isVideoPlayerStopping = false
    if m.queuedVideoPlayerCommand <> invalid then
      videoPlayerNode = m.queuedVideoPlayerCommand.videoPlayerNode
      if videoPlayerNode <> invalid then
        videoPlayerNode.control = m.queuedVideoPlayerCommand.command
      end if

      m.queuedVideoPlayerCommand = invalid
    end if
  end if
End Function


' During video player stop on both the linear and VOD players we unobserve the video player state. We need to continue observing state until we get state=stopped due to our new async stop behavior
' @videoPlayer: node, Video node that we want to keep track of state on
Function waitForVideoPlayerStoppedState(videoPlayer)
  state = videoPlayer.state
  ' If state isn't stopped then we need to observe the videoPlayer state field
  if state <> "stopped" then
    ' We are intentionally using the nonscoped observer here to avoid having our observer be removed by other code executed by ContentController
    videoPlayer.unobserveField("state")
    videoPlayer.observeField("state", "waitForVideoPlayerStoppedStateCallback")
  else
    trackVideoPlayerStoppingState(state)
  end if
End Function


' Callback for waitForVideoPlayerStoppedState when state changes on the video player.
' Once state=stopped we will unobserve state.
Function waitForVideoPlayerStoppedStateCallback(msg)
  state = msg.getData()
  videoPlayer = msg.getRoSGNode()
  if state = "stopped" AND videoPlayer <> invalid then
    ' We are intentionally using the nonscoped unobserve here to match our nonscoped observer in waitForVideoPlayerStoppedState
    videoPlayer.unobserveField("state")
  end if
  trackVideoPlayerStoppingState(state)
End Function


' Used to get the current authInfo and update it with info from userSettings as well updating bookmarkIds, historyIds, likeIds on global
' @callback: Function, callback that will be called after all information has been retrieved
Function getUserInfo(callback)
  ' Set our callback for when everything is complete
  m.getUserInfoCallback = callback

  ' Reset our state to nothing being received yet
  m.getHistoryIdsResponseReceived = false
  m.getQueueIdsResponseReceived = false
  m.getUserPreferencesRateTitleLikedResponseReceived = false
  m.getUserPreferencesRateTitleDislikedResponseReceived = false

  authInfo = m.tubiAuthUpdate.getAuthInfo()
  if isLoggedInUser(authInfo) = true AND isMajorEventDay() = false
    getHistoryIds(getHistoryIdsSuccess, getHistoryIdsError)
    getQueueIds(getQueueIdsSuccess, getQueueIdsError)

    'for kids account there wont be like/dislike preferences.
    if isNonEmptyString(authInfo.parentId) = true then
      m.getUserPreferencesRateTitleLikedResponseReceived = true
      m.getUserPreferencesRateTitleDislikedResponseReceived = true
    else
      getUserInfoGetContentRatingTitleLiked()
      getUserInfoGetContentRatingTitleDisliked()
    end if
  else
    m.getHistoryIdsResponseReceived = true
    m.getQueueIdsResponseReceived = true
    m.getUserPreferencesRateTitleLikedResponseReceived = true
    m.getUserPreferencesRateTitleDislikedResponseReceived = true
    checkIfAllUserInfoReceived()
  end if
End Function


Function getHistoryIdsSuccess(historyIds)
  m.getHistoryIdsResponseReceived = true
  m.global.historyIds = historyIds
  checkIfAllUserInfoReceived()
End Function


Function getHistoryIdsError(error)
  m.getHistoryIdsResponseReceived = true
  checkIfAllUserInfoReceived()
End Function


Function getQueueIdsSuccess(queueIds)
  m.getQueueIdsResponseReceived = true
  m.global.bookmarkIds = queueIds
  checkIfAllUserInfoReceived()
End Function


Function getQueueIdsError(error)
  m.getQueueIdsResponseReceived = true
  checkIfAllUserInfoReceived()
End Function


Function getUserInfoGetContentRatingTitleLiked(nextPageId = invalid)
  reqInfo = m.userDeviceApi.getContentRating("title", m.constants.ui.likeDislikeStates.liked, nextPageId)
  reqInfo.append({
    "requestType": m.constants.reqNames.getContentRating
    "responseType": "assocarray"
    "successCallback": onGetUserInfoGetUserPreferencesRateTitleLikedSuccess
    "errorCallback": onGetUserInfoGetUserPreferencesRateTitleLikedError
  })
  m.makeRequest(reqInfo)
End Function


Function onGetUserInfoGetUserPreferencesRateTitleLikedSuccess(response)
  m.global.likeIds.appendChildren(response.nodes)
  if response.nextPageId <> invalid then
    getUserInfoGetContentRatingTitleLiked(response.nextPageId)
  else
    m.getUserPreferencesRateTitleLikedResponseReceived = true
    checkIfAllUserInfoReceived()
  end if
End Function


Function onGetUserInfoGetUserPreferencesRateTitleLikedError(error)
  m.getUserPreferencesRateTitleLikedResponseReceived = true
  checkIfAllUserInfoReceived()
End Function


Function getUserInfoGetContentRatingTitleDisliked(nextPageId = invalid)
  reqInfo = m.userDeviceApi.getContentRating("title", m.constants.ui.likeDislikeStates.disliked, nextPageId)
  reqInfo.append({
    "requestType": m.constants.reqNames.getContentRating
    "responseType": "assocarray"
    "successCallback": onGetUserInfoGetUserPreferencesRateTitleDislikedSuccess
    "errorCallback": onGetUserInfoGetUserPreferencesRateTitleDislikedError
  })
  m.makeRequest(reqInfo)
End Function


Function onGetUserInfoGetUserPreferencesRateTitleDislikedSuccess(response)
  m.global.likeIds.appendChildren(response.nodes)
  if response.nextPageId <> invalid then
    getUserInfoGetContentRatingTitleDisliked(response.nextPageId)
  else
    m.getUserPreferencesRateTitleDislikedResponseReceived = true
    checkIfAllUserInfoReceived()
  end if
End Function


Function onGetUserInfoGetUserPreferencesRateTitleDislikedError(error)
  m.getUserPreferencesRateTitleDislikedResponseReceived = true
  checkIfAllUserInfoReceived()
End Function


Function checkIfAllUserInfoReceived()
  if m.getHistoryIdsResponseReceived <> true then
    return false
  end if

  if m.getQueueIdsResponseReceived <> true then
    return false
  end if

  if m.getUserPreferencesRateTitleLikedResponseReceived <> true then
    return false
  end if

  if m.getUserPreferencesRateTitleDislikedResponseReceived <> true then
    return false
  end if

  getUserInfoCallback = m.getUserInfoCallback
  if getUserInfoCallback <> invalid then
    m.getUserInfoCallback = invalid
    getUserInfoCallback()
  end if

  return true
End Function


Function needsToShowAgeVerificationScreen()
  authInfo = m.tubiAuthUpdate.getAuthInfo()
  if isLoggedInUser(authInfo) = true
    if authInfo.hasAge = true then
      return false
    else if isNonEmptyString(authInfo.parentId) = true ' kids account, no need to show age gate
      return false
    end if
  else
    guestUserHasAgeInfo = getGuestUserHasAgeInfo()
    ' In the case that the user is logged in but there is no age information associated with the account, hasAge defaults to false.
    if guestUserHasAgeInfo.hasAge = true AND guestUserHasAgeInfo.expired <> true
      return false
    end if
  end if
  return true
End Function


' Provides a list of nodes that should be notified when the authInfo is updated. Called in onUpdatedAuthRetrieved()
Function getAuthUpdatedNodesList()
  nodes = [
    m.generalTask
  ]

  if m.trackingLoggingTask <> invalid then
    nodes.push(m.trackingLoggingTask)
  end if

  screens = getScreensInStack()
  for each screen in screens
    task = screen.task
    if task <> invalid then
      nodes.push(task)
    end if
  end for

  return nodes
End Function


' Registry related Functions


'reads device registry for firstVisit value
'returns firstVisit value if value is present, otherwise return -1
Function getFirstVisit()
  firstVisitRegSection = "visit"
  firstVisit = regRead("firstVisit", firstVisitRegSection)
  if firstVisit <> invalid
    firstVisit = firstVisit.toInt()
  else
    firstVisit = -1
  end if
  return firstVisit
End Function


'sets the first visit value (number of days since Unix epoch) in the device registry
'returns the number of days since Unix epoch
Function setFirstVisit()
  firstVisitRegSection = "visit"
  dateTime = createObject("roDateTime")
  secondsFromEpoch = dateTime.AsSeconds()
  daysFromEpoch = Int(secondsFromEpoch / 60 / 60 / 24)
  regWrite("firstVisit", daysFromEpoch.toStr(), firstVisitRegSection)
  return daysFromEpoch
End Function


Function getGuestUserHasAgeInfo()
  guestUserHasAgeRegSection = "has_age"
  hasAgeStored = regRead("ageInfo", guestUserHasAgeRegSection)
  if hasAgeStored <> invalid

    hasAgeStored = ParseJson(hasAgeStored)
    if hasAgeStored = invalid
      hasAgeStored = {
        hasAge: false
        expireTime: 0
      }
    end if

    dateTime = CreateObject("roDateTime")
    nowTime = dateTime.AsSeconds()

    hasAgeInfo = {
      hasAge: hasAgeStored.hasAge
      expired: true
    }

    if hasAgeStored.expireTime > nowTime
      hasAgeInfo.expired = false
    end if
  else
    hasAgeInfo = {
      hasAge: false
      expired: true
    }
  end if
  return hasAgeInfo
End Function


' @hasAge: boolean, true indicates that the backend has determined that this user is >= 13 years old
Function setGuestUserHasAgeInfo(hasAge)
  guestUserHasAgeRegSection = "has_age"
  if isBoolean(hasAge) = false
    hasAge = false
  end if

  dateTime = CreateObject("roDateTime")
  nowTime = dateTime.AsSeconds()

  'set the default expire time (ie. the user failed the age gate)
  hasAgeStored = {
    hasAge: hasAge
    expireTime: nowTime + m.constants.timers.coppaFailTimeout
  }

  if hasAge = true
    if isUserInMultiAccount() = true
      hasAgeStored.expireTime = nowTime + m.constants.timers.coppaFailTimeout
    else
      ' update with the expire time used if the user passed the age gate
      hasAgeStored.expireTime = nowTime + m.constants.timers.coppaPassTimeout
    end if
  end if

  hasAgeStoredJson = FormatJson(hasAgeStored)
  regWrite("ageInfo", hasAgeStoredJson, guestUserHasAgeRegSection)
  return hasAgeStored
End Function


Function deleteGuestUserHasAgeInfo()
  guestUserHasAgeRegSection = "has_age"
  regDelete("ageInfo", guestUserHasAgeRegSection)
End Function


Function onViewableImpressionEventInfoChange(msg)
  ' During navigation between pages onScreenChange get triggered well in advance before the rowlist items render tracking becomes none.
  ' We are checking in this if the screen is different from what is stored in m.viewableImpressionEvents then we fire the events.
  ' The sequence of events are when navigating between home to movies. Home Screen items tracking info becomes none for all items and then the movies screen becomes full.
  data = msg.getData()

  ' Branch by trackingType: pivot items use a separate aggregation path
  clientTrackingInfo = invalid
  if isAA(data) = true AND isAA(data.clientTrackingInfo) = true
    clientTrackingInfo = data.clientTrackingInfo
  end if

  if clientTrackingInfo <> invalid AND clientTrackingInfo.trackingType = "pivot"
    aggregatePivotImpression(data)
  else
    ' Existing tile impression logic — flush only if screen/personalization actually changed
    ' (not on the initial empty → set transition, since screenId starts as "")
    if (isNonEmptyString(m.viewableImpressionEvents.screenId) = true AND data.screenId <> m.viewableImpressionEvents.screenId) OR (isNonEmptyString(m.viewableImpressionEvents.personalizationId) = true AND data.personalizationId <> m.viewableImpressionEvents.personalizationId)
      ' After sending the events the m.viewableImpressionEvents will be reset.
      sendImpressionEvent()
    end if

    ' Using screenId check because screenId is only available if the tile is displayed in HomeScreen.
    ' We cannot use screen.isSubtype("HomeScreen") because when the user navigates from homescreen to detailscreen,
    ' we will get some events of homescreen tiles hidden after the current screen changes to details screen.
    if isNonEmptyString(data.screenId) = true
      containerId = data.containerId
      containers = m.viewableImpressionEvents.containers

      ' Checking if this the first tile for a particular row and then creating a entry in the map.
      if containers[containerId] = invalid
        containers[containerId] = {
          id: containerId
          contents: []
        }
      end if

      containers[containerId].contents.push(data.itemInfo)

      m.viewableImpressionEvents.containers = containers

      if isNonEmptyString(m.viewableImpressionEvents.screenId) = false
        trackingPageInfo = data.screenTrackingInfo
        m.viewableImpressionEvents.pageOneof = m.Tracking.getAnalyticsPage(trackingPageInfo.pageType, trackingPageInfo.pageValues)
        m.viewableImpressionEvents.personalizationId = data.personalizationId
        m.viewableImpressionEvents.screenId = data.screenId
      end if
    end if
  end if

  ' It is possible that viewable impression events from the homescreen may trigger this callback
  ' after the user has already left the homescreen, and after the sendImpressionEventTimer has been stopped.
  ' In this case, we need to restart the timer so that the viewable impression events will be sent.
  ' Because we are only restarting the sendImpressionEventTimer in sendImpressionEvent() if the user is still on the homescreen,
  ' it will prevent the timer from continuing to run when not needed.
  '  This logic will cover the use cases:
  ' 1. Where user navigated to different screen but we recieved viewable impression events.
  ' 2. It will also restart the timer if the user navigates back to home screen after navigating to video player or details screen.
  if m.sendImpressionEventTimer.control <> "start"
    m.sendImpressionEventTimer.control = "start"
  end if
End Function


Function sendImpressionEvent()
  if isMajorEventDay() = false
    ' Send tile impressions (containers-based format)
    if m.viewableImpressionEvents <> invalid AND m.viewableImpressionEvents.containers <> invalid AND m.viewableImpressionEvents.containers.count() > 0
      tubiLog("ContentController.sendImpressionEvent (tiles)")
      containers = []
      items = m.viewableImpressionEvents.containers.Items()
      for each item in items
        containers.push(item.value)
      end for

      sendImpressionBatch({
        pageOneOf: m.viewableImpressionEvents.pageOneof
        containers: containers
        personalization_id: m.viewableImpressionEvents.personalizationId
      })
    end if

    ' Send pivot impressions (components/utility_tiles format)
    if m.pivotImpressionEvents <> invalid AND m.pivotImpressionEvents.utilityTiles.count() > 0
      tubiLog("ContentController.sendImpressionEvent (pivots)")

      ' Use the first utility tile as the representative item inside collection_component.
      ' The proto requires CollectionComponent.item (utility_tile) to be set.
      firstTile = m.pivotImpressionEvents.utilityTiles[0]

      sendImpressionBatch({
        pageOneOf: m.pivotImpressionEvents.pageOneof
        components: [{
          id: "PIVOT"
          collection_component: {
            row: 1
            sub_type: "PIVOT"
            utility_tile: {
              id: firstTile.id
              row: firstTile.row
              col: firstTile.col
            }
          }
          utility_tiles: m.pivotImpressionEvents.utilityTiles
        }]
        personalization_id: m.pivotImpressionEvents.personalizationId
      })
    end if
  end if

  m.viewableImpressionEvents = {
    containers: {}
    pageOneof: invalid
    personalizationId: ""
    screenId: ""
  }

  m.pivotImpressionEvents = {
    utilityTiles: []
    pageOneof: invalid
    personalizationId: ""
    screenId: ""
  }

  startClientImpressionTimer()
End Function


' Sends a single viewable impression batch to the analytics endpoint
' @param eventValues - The impression payload (may contain containers or components)
Function sendImpressionBatch(eventValues as Object) as Void
  trackData = m.Tracking.getViewableImpressionEvent(eventValues)
  requestInfo = m.Tracking.createViewableImpressionTrackingReqInfo(trackData)

  m.makeRequest({
    url: requestInfo.url
    requestType: m.constants.reqNames.postViewableImpression
    options: requestInfo.options
    silenceCallbackWarnings: true
  })
End Function


' Aggregates a single pivot item impression into the pivot impression batch
' @param data - Impression data containing clientTrackingInfo with pivot-specific fields
Function aggregatePivotImpression(data) as Void
  if isNonEmptyString(data.screenId) = false then return

  clientInfo = data.clientTrackingInfo

  ' Flush only if screen/personalization actually changed from a previously set value
  ' (not on the initial empty → set transition, since screenId starts as "")
  if (isNonEmptyString(m.pivotImpressionEvents.screenId) = true AND data.screenId <> m.pivotImpressionEvents.screenId) OR (isNonEmptyString(m.pivotImpressionEvents.personalizationId) = true AND data.personalizationId <> m.pivotImpressionEvents.personalizationId)
    sendImpressionEvent()
  end if

  ' Add utility tile impression data
  m.pivotImpressionEvents.utilityTiles.push({
    id: clientInfo.pivotId
    row: 1
    col: clientInfo.col
    duration: clientInfo.duration
    dwell_time: clientInfo.dwell_time
  })

  ' Set page context on first pivot impression in this batch
  if isNonEmptyString(m.pivotImpressionEvents.screenId) = false
    trackingPageInfo = data.trackingPageInfo
    m.pivotImpressionEvents.pageOneof = m.Tracking.getAnalyticsPage(trackingPageInfo.pageType, trackingPageInfo.pageValues)
    m.pivotImpressionEvents.personalizationId = data.personalizationId
    m.pivotImpressionEvents.screenId = data.screenId
  end if
End Function


Function startClientImpressionTimer()
  m.sendImpressionEventTimer.control = "stop"

  currentScreen = getCurrentScreen()
  if currentScreen <> invalid AND currentScreen.hasField("shouldTrackViewableImpressionEvent") = true AND currentScreen.shouldTrackViewableImpressionEvent = true
    m.sendImpressionEventTimer.control = "start"
  end if
End Function


' Informs home screen to reset the position to top next time when it is recieves focus.
Function resetCategoryGridPosition()
  homeScreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
  if homeScreen <> invalid
    homeScreen.resetGridPosition = true
  end if
End Function


Function showToastAfterAuthRefreshFromMobile()
  authInfo = m.tubiAuthUpdate.getAuthInfo()

  if isLoggedInUser(authInfo) = true
    email = ""
    if m.pub_serverPersistentData.email <> invalid
      email = m.pub_serverPersistentData.email
    end if

    message = getTranslation("auth_refresh_welcome_message", { email: email })
    headerText = getTranslation("auth_refresh_welcome_header")

    toastInfo = {
      message: message
      selfDestructTimer: 7
      imageUri: "pkg:/images/sideNavAccountFilled.webp"
      headerText: headerText
    }

    showToast(toastInfo)
  end if
End Function

' @feature: string, translated string for the feature that is disabled. Ex: Search, My Stuff etc.
Function showFeatureDisabledToast(feature)
  langaugeSuffix = ""

  locale = getLocale()
  languageId = Left(locale, 2)

  if languageId <> "en"
    langaugeSuffix = "_" + languageId
  end if

  headerTextConfigKey = "major_event_failsafe_maintenance_header" + langaugeSuffix
  messageConfigKey = "major_event_failsafe_maintenance_subtext" + langaugeSuffix
  defaultFallback = getTranslation("disaster_mode_toast_heading")

  majorEventEnd = getExternalConfigValueFromGlobal("major_event_failsafe_end", m.constants.configHubFallbacks.majorEventEnd)

  ' Checking the event is happening on the same day as current day.
  isEventToday = isToday(majorEventEnd)

  majorEventEndDatetime = CreateObject("roDateTime")
  majorEventEndDatetime.FromISO8601String(majorEventEnd)
  majorEventEndDatetime.toLocalTime()
  formattedTime = UCase(localizedTimeString(majorEventEndDatetime))

  if isEventToday = false
    formattedTime = formattedTime + " " + LCase(getTranslation("tomorrow"))
  end if

  headerText = getExternalConfigValueFromGlobal(headerTextConfigKey, defaultFallback)
  headerText = headerText.replace("{feature}", feature)
  headerText = headerText.replace("{time}", formattedTime)

  message = getExternalConfigValueFromGlobal(messageConfigKey, "")
  message = message.replace("{feature}", feature)
  message = message.replace("{time}", formattedTime)

  showToast({
    "selfDestructTimer": 5
    "headerText": headerText
    "message": message
    "imageUri": "pkg:/images/feature-disabled-icon.webp"
  })
End Function


' Returns the size of the featured preivew player.
' @return: array, the size of the player
Function getFeaturedPlayerSize()
  featuredRowPoster = m.constants.ui.imageSizes.featuredRowPoster

  ' Adding 4px to the width and 10px to the height to account for the border and rounded corners.
  ' Since we cannot achieve the rounded corners for video player and the focus indicator has rounded corners.
  ' We are adjusting the size of the player so the edges are aligned beneath the focus indicator.
  playerSize = [featuredRowPoster[0] + 4, featuredRowPoster[1] + 10]

  return playerSize
End Function


' Checks if the aspect ratio is close to 16:9
' @param size: array, the size of the player
' @return: boolean, true if the aspect ratio is close to 16:9, false otherwise
Function isCloseTo16By9AspectRatio(size)
  tolerance = 0.05
  ' Calculate the actual aspect ratio
  actualRatio = size[0] / size[1]
  ' 16:9 aspect ratio = 1.777777...
  targetRatio = 16.0 / 9.0

  ' Calculate the difference as a percentage
  difference = Abs(actualRatio - targetRatio) / targetRatio

  ' Return true if within tolerance
  return difference <= tolerance
End Function


' Creating a wrapper function to append the additional context values to the event.values
Function fireUserTrackingEvent(event)
  ' TODO: For now only updating where it is required to limit the scope of the change.
  currentScreen = getCurrentScreen()
  if currentScreen <> invalid AND currentScreen.trackingPageInfo <> invalid AND currentScreen.trackingPageInfo.additionalContextValues <> invalid
    event.values.append(currentScreen.trackingPageInfo.additionalContextValues)
  end if

  m.trackingLoggingTask.trackEvent = event
End Function


Function checkIfUserIsAdultByParentalRatingAndBirthday()
  isAdult = true
  ' If the parental rating is not 3, the user is not an adult.
  if m.pub_serverPersistentData.parentalRating <> 3
    isAdult = false
  end if

  birthday = m.pub_serverPersistentData.birthday
  if isNonEmptyString(birthday) = true AND isAdult = true
    dateTime = CreateObject("roDateTime")
    ' Adding 00:00:00Z to the birthday string to make it a valid ISO-8601 string.
    dateTime.FromISO8601String(birthday + "T00:00:00Z")
    birthdaySeconds = dateTime.asSeconds()
    nowSeconds = CreateObject("roDateTime").asSeconds()
    age = convertSecondsToYears(nowSeconds - birthdaySeconds)
    if age < 18
      isAdult = false
    end if
  end if

  return isAdult
End Function


' Checks if the video preview is queued.
' @return: boolean, true if the video preview is queued, false otherwise
Function isVideoPreviewPlayQueued()
  queued = false
  if m.videoPreviewPlayer <> invalid AND m.queuedVideoPlayerCommand <> invalid AND m.videoPreviewPlayer.isSameNode(m.queuedVideoPlayerCommand.videoPlayerNode) = TRUE AND m.queuedVideoPlayerCommand.command = "play" then
    queued = true
  end if

  return queued
End Function


' Processes the user content selection.
' @content, roSGNode, the content item that the user selected.
' @screen, roSGNode, the screen that the user selected the content item from.
' @playbackSource, assocarray, the playback source for the content.
Function processUserContentSelection(content, screen, playbackSource = {}) as Void
  ' TODO @prajwalkshetty investigate way to not have this be required
  if screen.isInFocusChain() = false
    return
  end if
  contentType = content.type
  playerType = content.playerType
  if isAA(content.scheduleData)
    playerType = content.scheduleData.playerType
  end if
  sendButtonComponentInteractionEvent("OK", "IMAGE", "CONFIRM", screen)

  m.videoPreviewDebounce.control = "stop"
  if isNonEmptyString(content.actionId) = true
    if content.actionId = "signInWatch" OR content.actionId = "signInWatchLive"
      startSignIn(processUserContentSelectionAfterSignIn)
    else if content.actionId = "watchLive"
      if playerType = m.constants.ui.playerTypes.fox
        playLinearVideoWithFoxPlayer(content)
      else
        playerLinearChannel(content)
      end if
    else if content.actionId = "reminder"
      addOrRemoveReminderForEventContent(content)
    else if content.actionId <> "contentUnavailable"
      showLinearDetailScreen(content, playbackSource)
    end if
  else if contentType = m.constants.uapiContentTypes.channel
    stopVideoPreview()
    contentMode = ""
    if screen.contentMode <> m.constants.ui.contentMode.homescreen
      contentMode = screen.contentMode
    end if
    showCategoryDetailsScreen(content, true, contentMode)
  else if contentType = m.constants.ui.contentTypes.historySignedOutUser
    startSignIn(refreshScreenAndContentAfterSignIn)
  else if contentType = m.constants.ui.contentTypes.linear
    if content.needsLogin = true AND isLoggedInUser() = false AND getStatsigExperimentResource("roku_linear_reg_gate", "roku_linear_reg_gate_v1_1").enabled = true
      showLinearPlayerSignInModal(content)
    else
      selectLinearContent(content)
    end if
  else if contentType = m.constants.ui.contentTypes.skinAd
    playAdContent(content)
  else if content.scheduleData <> invalid
    showLinearDetailScreen(content, playbackSource)
  else
    showDetailScreen(content, true, invalid, invalid, playbackSource)
  end if
End Function


Function showLinearPlayerSignInModal(content)
  tubiLog("ContentController.showLinearPlayerSignInModal")

  if content <> invalid
    ' Get program name for the modal

    currentProgram = getCurrentLiveProgram(content)

    if currentProgram <> invalid
      programName = currentProgram.title
    else
      programName = content.title
    end if

    ' Create two-line title format:
    ' Line 1: "Register or Sign In to stream"
    ' Line 2: "{ProgramName}"
    titleLine1 = getTranslation("linear_player_signin_title") ' "Register or Sign In to stream"
    modalTitle = titleLine1 + Chr(10) + programName

    ' Modal message details
    message = getTranslation("linear_player_signin_subtitle") ' "No credit card required • FREE Forever"
    subMessage = getTranslation("linear_player_signin_description") ' "Please register or sign in to watch."

    buttons = [getTranslation("dialog_button_continue"), getTranslation("dialog_button_exit")]
    ' Get current screen for analytics
    currentScreen = getCurrentScreen()


    ' Store content reference for callbacks
    m.linearSignInModalContent = content

    ' Show the modal with two-line title
    showSignInRequiredModal(modalTitle, message, buttons, currentScreen, "linear-signin", m.Tracking, m.trackingLoggingTask, onLinearSignInModalContinue, true, subMessage)
  end if
End Function


'Callback when user selects "Continue" from linear sign-in modal
Function onLinearSignInModalContinue()
  tubiLog("ContentController.onLinearSignInModalContinue")

  if m.linearSignInModalContent <> invalid
    content = m.linearSignInModalContent

    ' Clear stored content
    m.linearSignInModalContent = invalid

    ' Start sign-in process, then redirect to linear content selection
    m.contentAfterSignIn = content
    startSignIn(onLinearSignInComplete)
  end if
End Function


' Callback after sign-in is complete for linear content
Function onLinearSignInComplete()
  tubiLog("ContentController.onLinearSignInComplete")

  if m.contentAfterSignIn <> invalid
    content = m.contentAfterSignIn
    m.contentAfterSignIn = invalid
    popScreenAfterSignInProcess()
    setContentToRefreshAllPersonalizedScreens(false)

    currentScreen = getCurrentScreen()

    playbackSource = {
      "srcForAnalytic": m.constants.player.playbackSource.unknown
      "srcForAds": m.constants.player.playbackOrigin.container
    }

    ' Now that user is signed in, select the linear content normally
    stopLinearVideoContent()
    playLinearVideoContent(content, false, currentScreen.id, true, playbackSource)
    showHideSpinner(false)
  end if
End Function



' Processes the user content selection.
' @content, roSGNode, the content item that the user selected.
' @screen, roSGNode, the screen that the user selected the content item from.
' @playbackSource, assocarray, the playback source for the content.
Function processUserPlayAction(content, screen, playbackSource = {}) as Void
  ' TODO @prajwalkshetty investigate way to not have this be required
  if screen.isInFocusChain() = false
    return
  end if
  contentType = content.type
  playerType = content.playerType
  if isAA(content.scheduleData)
    playerType = content.scheduleData.playerType
  end if
  sendButtonComponentInteractionEvent("PLAY", "IMAGE", "CONFIRM", screen)
  ' Since category panel list screen re-uses the method allowing it to play the content.
  if contentType = m.constants.uapiContentTypes.channel
    contentMode = ""
    if screen.contentMode <> m.constants.ui.contentMode.homescreen
      contentMode = screen.contentMode
    end if
    showCategoryDetailsScreen(content, true, contentMode)
  else if contentType = m.constants.ui.contentTypes.historySignedOutUser
    '//if a signed out user selects the continue watching row, then navigate him/her to the sign in screen
    startSignIn(refreshScreenAndContentAfterSignIn)
  else if contentType = m.constants.ui.contentTypes.skinAd
    playAdContent(content)
  else if isNonEmptyString(content.actionId) = true
    if content.actionId = "signInWatchLive"
      startSignIn(processUserContentSelectionAfterSignIn)
    else if content.actionId = "watchLive"
      if playerType = m.constants.ui.playerTypes.fox
        playLinearVideoWithFoxPlayer(content)
      else
        playerLinearChannel(content)
      end if
    end if
  else if content.scheduleData <> invalid
    showLinearDetailScreen(content, playbackSource)
  else if contentType = m.constants.ui.contentTypes.linear
    selectLinearContent(content)
  else
    showDetailScreen(content, false, skipDetailScreen, invalid, playbackSource)
  end if
End Function


Function processUserContentSelectionAfterSignIn()
  popScreenAfterSignInProcess()
  screen = getCurrentScreen()
  if screen <> invalid
    if screen.content <> invalid
      screen.content.needsLogin = (isLoggedInUser() = false)
    end if
    if screen.subtype() = "LinearDetailScreen"
      contentFocused = screen.content
    else
      contentFocused = screen.contentFocused
    end if

    if contentFocused <> invalid AND contentFocused.actionId <> "signInWatch" AND contentFocused.actionId <> "reminder"
      playerType = contentFocused.playerType
      if isAA(contentFocused.scheduleData)
        playerType = contentFocused.scheduleData.playerType
      end if
      if playerType = m.constants.ui.playerTypes.fox
        playLinearVideoWithFoxPlayer(contentFocused)
      else
        playerLinearChannel(contentFocused)
      end if
    end if
  end if
  showContentGroupAndHideSpinner()
  refreshUiAfterSignIn()
  setContentToRefreshAllPersonalizedScreens(true)
End Function


Function onStatsigExposureInfoChange(msg)
  data = msg.getData()
  sendStatsigExposureEvent(data)

  if m.constants.settings.mode <> "production"
    if data.experimentName <> invalid AND data.group <> invalid AND LCase(data.group) <> "control"
      showToast({
        "selfDestructTimer": 5
        "headerText": "Currently View Experiment: " + data.experimentName
        "message": "variant: " + data.group
      })
    end if
  end if
End Function


Function sendStatsigExposureEvent(exposureInfo)
  if exposureInfo <> invalid

    if m.statsigExperiments = invalid
      m.statsigExperiments = StatsigExperiments(m.constants)
    end if

    m.statsigExperiments.logExposure(exposureInfo)
  end if
End Function


Function onStartMigrateDefaultUserToNewProfileSuccess(userInfo)
  'create or update the profile metadata section
  if userInfo <> invalid
    Auth = m.tubiAuthUpdate

    authInfo = {}
    currentAuthInfo = Auth.getAuthInfo()
    authInfo.append(currentAuthInfo) 'append whats in the current auth for the new profile

    'save the auth info backup space in the registry so that we can use it if anything goes wrong.
    Auth.saveAuthInfoBackup(currentAuthInfo, "authbackup")

    if userInfo.firstName <> invalid
      authInfo.firstName = userInfo.firstName
    end if

    if userInfo.lastName <> invalid
      authInfo.lastName = userInfo.lastName
    end if

    if userInfo.name <> invalid
      authInfo.name = userInfo.name
    end if

    if userInfo.hasAge <> invalid
      authInfo.hasAge = userInfo.hasAge
    end if

    if userInfo.userUuid <> invalid
      authInfo.userUuid = userInfo.userUuid
    end if

    if userInfo.avatarUrl <> invalid
      authInfo.avatarUrl = userInfo.avatarUrl
    end if

    if userInfo.hasPin <> invalid
      authInfo.hasPin = userInfo.hasPin
    end if

    if userInfo.tubiId <> invalid
      authInfo.tubiId = userInfo.tubiId
    end if

    if userInfo.email <> invalid
      authInfo.email = userInfo.email
    end if

    Auth.createOrUpdateProfileAuth(userInfo.tubiId, authInfo)
    Auth.copyProfileToMainAuth(userInfo.tubiId)
    'create fake guest profile so that user has option to switch to guest.
    Auth.createOrUpdateProfileAuth("guest", { "name": "", })
  end if

  m.profileMigrationComplete = true
  runControllerStartSequence()
End Function


Function setNotMigratedDefaultState(error = invalid)
  m.profileMigrationComplete = true
  runControllerStartSequence()
End Function


Function performProfileMigration()
  TubiLog("performProfileMigration")
  auth = m.tubiAuthUpdate
  authInfo = auth.getAuthInfo()
  'if UK/AU and kids profile is selected, then copy the kids parent
  if m.enableMultipleAccounts = invalid
    m.enableMultipleAccounts = getExternalConfigValueFromGlobal("enable_multiple_accounts", false)
  end if

  ' if multi account not enabled from remote config, then swith off multi account feature
  if m.enableMultipleAccounts = false OR UCase(m.constants.deviceInfo.countryCode) <> "US"
    if isKidsProfile(authInfo) = true
      auth.copyProfileToMainAuth("guest")
    end if

    m.profileMigrationComplete = true
    runControllerStartSequence()
  else
    isSignedUser = isLoggedInUser(authInfo)
    profiles = auth.getAllProfilesAuthInfo()

    if profiles["guest"] <> invalid
      profileCount = profiles.count() - 1
    else
      profileCount = profiles.count()
    end if

    if getStatsigExperimentResource("roku_multi_account", "roku_multi_account_v0", false).variant <> "none" AND isSignedUser = true

      if authInfo.expireTime <> invalid AND profileCount = 0
        ' get the user info from settings api and patch with what we have already stored in the registry
        'use v2 parental rating from settings api since we are anyway going to migrate.
        requestInfo = m.userDeviceApi.createUserSettingsGeneralTaskReqInfo(onStartMigrateDefaultUserToNewProfileSuccess, setNotMigratedDefaultState, true)
        m.makeRequest(requestInfo)
      else
        setNotMigratedDefaultState()
      end if
    else
      setNotMigratedDefaultState()
    end if

    'send exposure event
    if isSignedUser = true OR profileCount > 0
      getStatsigExperimentResource("roku_multi_account", "roku_multi_account_v0", true)
    end if
  end if
End Function


Function shouldDisplayFullScreenVideoBackground(content)
  return content.gridItemType = m.constants.ui.gridItemTypes.liveEventSpotlight
End Function


Function playerLinearChannel(content)
  screenId = getCurrentScreen().id
  showHideSpinner(true)
  fetchEPGChannel(screenId, content.scheduleData.channelId, onLinearChannelFetchSuccess, onLinearChannelFetchError)
End Function


Function onLinearChannelFetchSuccess(response, _storeInCache = false)
  if isNode(response)
    content = response.getChild(0)
    if content <> invalid
      screenId = getCurrentScreen().id
      showHideSpinner(false)
      playLinearVideoContent(content, false, screenId, false, {})
    end if
  end if
End Function


Function onLinearChannelFetchError(response)
  ' For now just hiding the spinner and not showing the error modal.
  Tubilog("ContentController.onLinearChannelFetchError")
  showHideSpinner(false)
End Function


Function addConstantsFromStartupArgs(startupArgs, constants)
  isDev = createObject("roAppInfo").IsDev()
  if isDev = false OR startupArgs.constantsUpdates = invalid then
    return constants
  end if

  constantsUpdates = ParseJson(startupArgs.constantsUpdates)
  if constantsUpdates = invalid then
    constantsUpdates = {}
  end if

  for each keyPath in constantsUpdates
    currentLevel = constants
    keyPathParts = keyPath.tokenize(".")
    finalKeyPathPart = keyPathParts.pop()
    value = constantsUpdates[keyPath]
    for each keyPathPart in keyPathParts
      nextLevel = currentLevel[keyPathPart]
      ' If the next level does not exist then we need to add it
      if nextLevel = invalid then
        nextLevel = {}
        currentLevel[keyPathPart] = nextLevel
      end if
      currentLevel = nextLevel
    end for
    currentLevel[finalKeyPathPart] = value
  end for

  return constants
End Function


' Provides a common spot for creating a screen that will hook up common logic from BaseScreen
' @screenName: string, the name of the screen to create
' @return: roSGNode, the created screen
Function createScreen(screenName)
  screen = createObject("roSGNode", screenName)
  screen.observeFieldScoped("pageLoadComplete", "onScreenPageLoadCompleteChange")
  screen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
  screen.observeFieldScoped("pageErrorInfo", "onScreenPageErrorInfoChange")

  m.currentlyLoadingScreens.push({
    "screen": screen
    "timespan": createObject("roTimespan")
  })

  return screen
End Function


Function onScreenPageLoadCompleteChange(msg) as Void
  pageLoadComplete = msg.getData()

  if pageLoadComplete = false then
    return
  end if

  screen = msg.getRoSgNode()

  loadingTimespan = cleanupLoadingScreen(screen)

  if loadingTimespan <> invalid then
    ' IMPROVEMENT can add our own screen performance tracking here

    screenTrackingLoad(screen.trackingPageInfo, loadingTimespan.totalMilliseconds())
  end if

  showHideSpinner(false)
End Function
