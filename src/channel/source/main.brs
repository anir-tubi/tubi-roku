'The Main function serves to run any remote config and experiment API calls and then choose the appropriate UI
Function Main(startupArgs)
  m.appStartTime = UpTime(0)
  m.startupArgs = startupArgs
  handleRegistryOperations(startupArgs)

  ' this version of constants will be the constants that are part of the submitted build (or the side loaded build)
  ' and only exist in the main brightscript thread.
  ' constants will be reset in remote components for scene graph
  constants = getConstants()
  constants = addConstantsFromStartupArgs(startupArgs, constants)

  port = CreateObject("roMessagePort")
  m.queue = TubiRequestQueue().create(port)
  request = TubiRequest(constants.settings)
  auth = TubiAuth(constants, request)
  sentryInfo = Sentry(constants, auth)
  log = TubiLogger(constants, request, auth, sentryInfo)

  logCrashesOnStartup(m.startupArgs, log, constants)

  ' permaScreen is a permanent screen that exists even when the screen created by runChannel()
  ' is closed. The presence of the permaScreen prevents the app from closing if screen.close()
  ' is called within runChannel(), due to the undocumented and apparent requirement that there
  ' is always at least one screen that on which .show() has been called and has not been closed.
  permaScreen = CreateObject("roSGScreen")
  permaScreen.CreateScene("BackgroundScene")
  permaScreen.show()

  while runChannel(constants, log, request, auth) = true
  end while
End Function


' @constants: assocArray, constants as returned by getConstants()
' @log: assocArray, an instance of the log module as returned by TubiLog()
' @request: assocArray, an instance of the request module as returned by TubiRequest()
' @auth: assocArray, an instance of the Auth module as returned by TubiAuth()
'
' returns: boolean, true if the app should be restarted, false if the app should be closed
Function runChannel(constants, log, request, auth)
  startupArgs = {}
  startupArgs.append(m.startupArgs)
  m.startupArgs = invalid

  ' Load scene graph
  port = CreateObject("roMessagePort")
  input = CreateObject("roInput")
  input.SetMessagePort(port)
  screen = CreateObject("roSGScreen")
  screen.SetMessagePort(port)
  controller = invalid

  input.enableTransportEvents()

  ' start the scene graph UI
  tubiScene = screen.CreateScene("TubiScene")
  tubiScene.allowBackgroundTask = true
  sgGlobal = screen.getGlobalNode()
  sgGlobal.addField("constants", "assocarray", false)
  sgGlobal.addField("theme", "assocarray", false)

  'setting constants here is just to get the scene up and running.
  'Global constants will be overwritten with constants pulled from starterController that are the most recent version of constants
  sgGlobal.setField("constants", constants)
  'set a default theme
  sgGlobal.setField("theme", constants.ui.themes.default)

  screen.show()

  if constants.settings.injectRtaOnDeviceComponent = true then
    m.odc = createObject("roSGNode", "RTA_OnDeviceComponent") 'bs:disable-line 1128
  end if

  'add RALE for dev builds - children can not be added to tubiScene until after screen.show has run
  if constants <> invalid AND constants.settings <> invalid AND constants.settings.mode = "dev" AND constants.settings.raleEnabled = true
    tubiScene.createChild("TrackerTask")
  end if
  ' Used to add required node creation needed for RALE component during vscode build
  ' vscode_rale_tracker_entry

  ' Used to add required node creation needed for RDB component during vscode build
  ' vscode_rdb_on_device_component_entry

  'run SceneGraph tests if in test mode
  if constants.settings.mode = "test"
    sgGlobal.setField("theme", constants.ui.themes.default) 'set theme for testing purposes
    if (type(Rooibos__Init) = "Function") then Rooibos__Init() 'bs:disable-line 1001 LINT1001

    localHostUri = constants.settings.localHostUri
    url = localHostUri + "/unit_tests_completed"
    urlTransfer = createObject("roUrlTransfer")
    urlTransfer.setUrl(url)
    urlTransfer.getToString()
    return false
  end if

  ' execute suitest library only if the mode is qa & suitest attribute enabled in qa config yml
  if constants.thirdParty.suiteTest.enabled = true AND constants.settings.mode = "qa"
    SuitestLibrary = createObject("roSGNode", "SuitestLibrary") 'bs:disable-line 1128
    SuitestLibrary.app_id = constants.thirdParty.suiteTest.app_id
    tubiScene.InsertChild(SuitestLibrary, 0)
  end if

  retries = 0
  maxRetries = 5
  backoffFactor = 1.5
  initialBackoff = 1000 'ms
  pause = initialBackoff
  libraryBeingFetched = invalid

  'this is the packaged constants - the submitted constants
  if constants.settings.useStarterComponents <> false
    '//TODO remove setRemoteConfigAndExperimentsOnConstants from here after exp : roku_new_cdn. Starter component will load the config and experiment tasks.
    constants = setRemoteConfigAndExperimentsOnConstants(request, constants)
    starterLibrary = tubiScene.findNode("TubiStarterLibrary")
    starterLibrary.observeField("loadStatus", port)
    libraryBeingFetched = starterLibrary
    componentsLoaded = false

    starterLibUrl = constants.settings.starterComponentsUrl

    if constants.experiments <> invalid AND constants.experiments.info <> invalid
      experiments = TubiExperiments(constants)

      if experiments <> invalid
        if experiments.getExperimentResource("roku_new_cdn", "roku_new_cdn_v1").enabled = true
          starterLibUrl = constants.settings.rcdnStarterComponentsUrl
        end if

        cdnExposureEventInfo = experiments.getExperimentTracking("roku_new_cdn", "roku_new_cdn_v1")

        if cdnExposureEventInfo <> invalid
          trackingLib = TubiTracking(constants, request, auth)

          if trackingLib <> invalid  'trackingLib may not be invalid, but just in case.
            trackingLib.trackUserEvent(cdnExposureEventInfo.type, cdnExposureEventInfo.values, m.queue)
          end if

        end if

      end if
    end if

    print "attempting to load TubiStarterLibrary "; starterLibUrl

    starterLibrary.uri =  starterLibUrl ' kicks off fetch of starter components
    componentTimer = CreateObject("roTimespan")
  else
    'only expect this else block to happen when side loading/testing
    'setting experiment values and external config will normally happen in StarterController when using starter components
    constants = setRemoteConfigAndExperimentsOnConstants(request, constants)

    sgGlobal.setField("constants", constants)
    sgGlobal.setField("theme", constants.ui.themes.default)
    controller = loadPackagedComponents(tubiScene, port, startupArgs)
    controller.fadeInContentController = true
    componentsLoaded = true
    componentTimer = invalid
  end if

  while true
    msg = wait(200, port)
    msgType = type(msg)

    if msgType = "roInputEvent"
      if controller <> invalid AND msg.GetInfo() <> invalid
        inputInfo = msg.GetInfo()
        if inputInfo.rale = invalid
          ' We don't want to handle rale events in our deeplinking code
          if inputInfo.type = invalid
            'deeplink info doesn't have a "type" field, so we add one in order to easily differentiate input behavior later
            inputInfo.type = "deeplink"
          end if
          controller.roInputInfo = inputInfo
        end if
      end if
    else if msgType = "roSGScreenEvent"
      ' documentation indicates a roSGSCreenEvent occurs when screen.close() is called, but trial
      ' and error testing suggests that the roSGScreenEvent never gets fired.
      ' do nothing for now - closing the screen does not necessarily mean we want to close the app.
    else if msgType = "roSGNodeEvent"
      tubiLog("main() got roSGNodeEvent for " + msg.GetField())
      if msg.GetField() = "exitApp"
        if msg.GetData() = true
          return false
        end if
      else if msg.GetField() = "disableInstantResume"
        if msg.GetData() = true
          contentController = tubiScene.findNode("ContentController")
          if contentController.customResume <> invalid
            m.startupArgs = contentController.customResume.launchParams
          end if
          screen.close() ' destroys the current scene as we need to relaunch the app from beginning
          return true
        end if
      else if msg.GetField() = "transportVoiceResponse"
        result = msg.getData()
        response = result.response
        if response = invalid
          response = "unhandled"
        end if
        if result.id <> invalid
          input.EventResponse({id: result.id, status: response})
        end if
      else if msg.GetField() = "loadStatus"
        'starter components or remote components load status update
        print "loadStatus = "; msg.getData()
        if msg.getData() = "ready"
          if msg.GetRoSGNode().id = "suitest"
            suitestIL = CreateObject("roSGNode", "SuitestInstrumentationLib:main")
            suitestIL.SetField("app_id", constants.thirdParty.suiteTest.app_id)
          else if msg.GetRoSGNode().id = "TubiStarterLibrary"
            starterController = tubiScene.createChild("TubiStarterLibrary:StarterController")
            if starterController <> invalid
              starterController.id = "StarterController"
              starterController.observeField("useRemoteComponents", port)
              starterController.observeField("remoteComponentsUrl", port)
              starterController.observeField("fadeOutCustomSplash", port)
              starterController.observeField("fadeInRemoteComponent", port)
              starterController.setField("getUrl", true)
              pause = initialBackoff
            else
              return showComponentsFailedToLoadError(msg, log, screen, constants)
            end if
          else if msg.GetRoSGNode().id = "TubiRemoteLibrary"
            componentsLoaded = true
            controller = tubiScene.createChild("TubiRemoteLibrary:ContentController")
            if controller <> invalid
              controller.id = "ContentController"
              controller.observeField("exitApp", port)
              controller.observeField("transportVoiceResponse", port)
              controller.observeField("removeStartUpScreens", port)
              controller.observeField("disableInstantResume", port)
              controller.observeField("rokuContinueWatchingRequestInfo", port)
              controller.appStartTime = m.appStartTime
              controller.startupArgs = startupArgs

              starterController = tubiScene.findNode("StarterController")
              if starterController <> invalid AND starterController.fadeInRemoteComponent = true AND controller.fadeInContentController <> true
                starterController.unobserveField("fadeInRemoteComponent")
                tubiScene.fadeOutSpinner = true
                controller.fadeInContentController = true
              end if
            else
              return showComponentsFailedToLoadError(msg, log, screen, constants)
            end if
          end if
        else if msg.getData() = "loading"
          print msg.GetRoSGNode().id + " status is loading"
        else if msg.getData() = "failed"
          if msg.GetRoSGNode().id = "suitest"
            print "Suitest component library failed to download"
          else if retries < maxRetries
            retries += 1
            componentLibrary = msg.GetRoSGNode()
            print componentLibrary.id; " failed to load due to API error, attempting retry #"; retries
            pause = pause * backoffFactor
            sleep(pause)
            resetComponentLibrary(componentLibrary, tubiScene, port)
          else if retries = maxRetries

            if initSubmittedChannel(request, constants, screen, tubiScene, port, startupArgs) = true

              message = libraryBeingFetched.id + " failed to load due to API error. Loading packed components"

              messageInfo = {
                message: message
                model: constants.deviceInfo.model
                name: libraryBeingFetched.id
                type: constants.errors.type.loadFailed
              }

              'send error info to sentry
              log.exception(messageInfo, "warn", m.queue, 0.1)

              'send error info to client logs
              log.error(FormatJSON(messageInfo), "apiError", "RO-1-300", m.queue, 1.0)

              componentsLoaded = true
              componentTimer = invalid
            else
              return showComponentsFailedToLoadError(msg, log, screen, constants)
            end if
          else
            return showComponentsFailedToLoadError(msg, log, screen, constants)
          end if
        end if
      else if msg.GetField() = "useRemoteComponents"
        'starter components may indicate not to use remote components
        if msg.getData() = false
          tubiLog("using packaged components")
          starterController = msg.GetRoSGNode()
          starterController.unobserveField("remoteComponentsUrl")
          starterController.unobserveField("useRemoteComponents")

          if starterController.newBuildConstants <> invalid
            sgGlobal.setField("constants", starterController.newBuildConstants)
            sgGlobal.setField("theme", starterController.newBuildConstants.ui.themes.default)
          end if

          componentsLoaded = true
          controller = loadPackagedComponents(tubiScene, port, startupArgs)
        end if
      else if msg.GetField() = "remoteComponentsUrl"
        print "got the remoteComponentsUrl "; msg.getData()
        'starter components have indicated the url to use for remote components
        starterController = msg.GetRoSGNode()
        starterController.unobserveField("remoteComponentsUrl")
        starterController.unobserveField("useRemoteComponents")

        if starterController.newBuildConstants <> invalid
          sgGlobal.setField("constants", starterController.newBuildConstants)
          sgGlobal.setField("theme", starterController.newBuildConstants.ui.themes.default)
        end if

        remoteLibrary = tubiScene.findNode("TubiRemoteLibrary")
        libraryBeingFetched = remoteLibrary
        componentTimer.mark()
        retries = 0
        remoteLibrary.observeField("loadStatus", port)
        remoteLibrary.uri = msg.getData()
      else if msg.GetField() = "fadeOutCustomSplash"
        starterController = msg.GetRoSGNode()
        starterController.unobserveField("fadeOutCustomSplash")
        tubiScene.fadeOutCustomSplash = true
      else if msg.GetField() = "fadeInRemoteComponent"
        starterController = msg.GetRoSGNode()
        contentController = tubiScene.findNode("ContentController")
        if contentController <> invalid AND contentController.fadeInContentController <> true
          starterController.unobserveField("fadeInRemoteComponent")
          tubiScene.fadeOutSpinner = true
          contentController.fadeInContentController = true
        end if
      else if msg.GetField() = "removeStartUpScreens"
        contentController = msg.GetRoSGNode()
        contentController.unobserveField("removeStartUpScreens")
        starterController = tubiScene.findNode("StarterController")
        tubiScene.fadeOutCustomSplash = true
        if starterController <> invalid
          starterController.removeStartUpScreens = true
        end if
      else if msg.getField() = "rokuContinueWatchingRequestInfo"
        info = msg.getData()
        updateRokuContinueWatchingInfo(request, info)
      end if
    end if

    ' handle starterComponents and remoteComponents timeouts
    if libraryBeingFetched <> invalid AND componentsLoaded = false AND componentTimer <> invalid AND componentTimer.totalMilliseconds() > 30000
      if retries < maxRetries
        retries += 1
        componentTimer.mark()
        print libraryBeingFetched.id; " failed to load due to timeout, attempting retry #"; retries
        pause = pause * backoffFactor
        sleep(pause)
        resetComponentLibrary(libraryBeingFetched, tubiScene, port)
      else if retries = maxRetries
        if initSubmittedChannel(request, constants, screen, tubiScene, port, startupArgs) = true
          message = libraryBeingFetched.id + " failed to load due to timeout. Loading Packed Components"
          messageInfo = {
            message: message
            model: constants.deviceInfo.model
            name: libraryBeingFetched.id
            type: constants.errors.type.loadFailed
          }
          'Send error info to sentry
          log.exception(messageInfo, "warn", m.queue, 0.1)

          'Send error info to clientLog
          log.warn(FormatJSON(messageInfo), "apiTimeout", "RO-1-300", m.queue, 1)

          componentsLoaded = true 'bs:disable-line 1001 LINT1005
          componentTimer = invalid 'bs:disable-line 1001 LINT1005
        else
          return showComponentsTimedOutError(libraryBeingFetched, log, screen, constants)
        end if
      else
        return showComponentsTimedOutError(libraryBeingFetched, log, screen, constants)
      end if
    end if
  end while
  return false
End Function


Function loadPackagedComponents(scene, port, startupArgs)
  controller = scene.createChild("ContentController")
  controller.id = "ContentController"
  controller.observeField("exitApp", port)
  controller.observeField("rokuContinueWatchingRequestInfo", port)
  controller.observeField("transportVoiceResponse", port)
  controller.observeField("removeStartUpScreens", port)
  controller.observeField("disableInstantResume", port)
  controller.appStartTime = m.appStartTime
  controller.startupArgs = startupArgs
  return controller
End Function


'removes the componentLibrary from the scene, and creates a new componentLibrary with the same id and same url
'as the removed componentLibrary. This will kick off a new request to the url for the remote library.
Function resetComponentLibrary(componentLibrary, scene, port)
  componentId = componentLibrary.id
  componentUri = componentLibrary.uri

  nodeHelpers = TubiNodeHelpers()
  componentLibraryTubiScene = nodeHelpers.getChildById(scene, componentId)
  componentLibraryTubiScene.unobserveField("loadStatus")
  scene.removeChild(componentLibraryTubiScene)

  newComponentLibrary = scene.createChild("ComponentLibrary")
  newComponentLibrary.observeField("loadStatus", port)
  newComponentLibrary.id = componentId
  newComponentLibrary.uri = componentUri
End Function


' @library: roSGNode: a ComponentLibrary node, either the TubiStarterLibrary or TubiRemoteLibrary
Function showComponentsTimedOutError(library, log, screen, constants)
  libraryId = ""
  if library <> invalid
    libraryId = library.id
  end if

  message = "Fetching " + libraryId + " timed out"
  print message
  error = {
    type: constants.errors.type.timedOut
    name: libraryId
    message: message
    loadStatus: "timeout"
    url: library.uri
  }
  log.exception(error, "error", m.queue, 0.1)
  return showStartupErrorDialog(screen, constants)
End Function


Function showComponentsFailedToLoadError(msg, log, screen, constants)
  message = msg.GetRoSGNode().id + " failed to load"
  print message
  error = {
    type: constants.errors.type.loadFailed
    name: msg.GetRoSGNode().id
    message: message
    loadStatus: msg.getData()
    url: msg.GetRoSGNode().uri
  }
  log.exception(error, "error", m.queue, 0.1)
  return showStartupErrorDialog(screen, constants)
End Function


Function showStartupErrorDialog(screen, constants)
  port = CreateObject("roMessagePort")

  sgGlobal = screen.getGlobalNode()
  sgGlobal.setField("theme", constants.ui.themes.default)

  scene = screen.GetScene()

  ' the following while loop is necessary because roku crash logs indicate that
  ' scene.CreateChild("ErrorController") can inexplicably return invalid at times.
  controllerCreated = false
  attempts = 0
  while controllerCreated = false AND attempts < 100
    controller = scene.CreateChild("ErrorController")

    if controller <> invalid
      controller.observeField("buttonSelected", port)
      controller.connectionError = true
      controllerCreated = true
    end if

    attempts += 1
  end while

  if controllerCreated = true
    while(true)
      msg = wait(0, port)
      msgType = type(msg)
      if msgType <> invalid then exit while
    end while
  end if

  screen.close()
  return false
End Function


Function logCrashesOnStartup(args, log, constants)
  ' These are reasons we don't care about
  reasonBlacklist = {
    "EXIT_UNKNOWN": true ' default exit reason
    "EXIT_POWER_MODE": true
    "EXIT_DIAL_DELETE": true
    "EXIT_IDLE_AUTO_EXIT": true
    "EXIT_AM_LOWRESOURCE": true ' exited in the background because foreground application needed more memory
    "EXIT_SETTINGS_UPDATE": true ' User changed setting like their resolution which caused application to close
    "EXIT_USER_NAV": true ' User pressed home button to exit application
  }

  reason = args.lastExitOrTerminationReason
  if reason <> invalid AND reasonBlacklist[reason] <> true
    messageInfo = {
      message: constants.errors.type.crashOnPreviousRun
      model: constants.deviceInfo.model
      name: reason
      type: constants.errors.type.crashOnPreviousRun
    }
    log.exception(messageInfo, "warn", m.queue, 1)
  end if
End Function


Function handleRegistryOperations(startupArgs)
  if startupArgs.clearRegistry = "true" OR startupArgs.setRegistry <> invalid then
    isDev = createObject("roAppInfo").IsDev()
    expectedPassword = "499zsaHvENIYuEiVPMMa3S5w"
    hasCorrectPassword = (startupArgs.password = expectedPassword)

    if isDev = true OR hasCorrectPassword = true then
      registry = createObject("roRegistry")

      if startupArgs.clearRegistry = "true" then
        sections = registry.getSectionList()
        for each section in sections
          registry.delete(section)
        end for
        print "REGISTRY CLEARED"
      end if

      if startupArgs.setRegistry <> invalid then
        json = startupArgs.setRegistry
        sections = parseJson(json)
        for each section in sections
          registrySection = createObject("roRegistrySection", section)
          registrySection.writeMulti(sections[section])
        end for
        print "REGISTRY SET"
      end if

      registry.flush()
    end if
  end if
End Function


Function addConstantsFromStartupArgs(startupArgs, constants)
  isDev = createObject("roAppInfo").IsDev()
  if isDev = false OR startupArgs.constantsUpdates = invalid then
    return constants
  end if

  constantsUpdates = ParseJson(startupArgs.constantsUpdates)

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



' @request: assocArray, an instance of the request module as returned by TubiRequest()
' @constants: assocArray, constants as returned by getConstants(), this version of constants
'                         will be the constants that are part of the submitted build.
' @screen: node, app base screen
' @tubiScene: node, home scene node
' @port: port, used to create content controller
' startupArgs: assocArray, start up app arguments, used to create content controller
'
' returns: boolean, true if the app successfully loaded submitted version of the app,
'                   false if app can not fallback on submitted version
Function initSubmittedChannel(request, constants, screen, tubiScene, port, startupArgs)
  print "loading the packed components"

  constants = setRemoteConfigAndExperimentsOnConstants(request, constants)

  sgGlobal = screen.getGlobalNode()
  sgGlobal.setField("constants", constants)
  sgGlobal.setField("theme", constants.ui.themes.default)

  canFallback = true

  if constants <> invalid
    submittedAppVersion = "0.0.0"

    if constants.deviceInfo <> invalid
      submittedAppVersion =  constants.deviceInfo.clientversion
    end if

    ' Sometimes submitted version of the app might have bugs, legal issues or api changes which makes them not worthy of fallback.
    ' constants.externalConfig.info.fallback_blocked_versions will contain a list of submitted app versions that we should not fallback on.
    if constants.externalConfig <> invalid AND constants.externalConfig.info <> invalid AND constants.externalConfig.info.fallback_blocked_versions <> invalid
      for each version in constants.externalConfig.info.fallback_blocked_versions
        if version = submittedAppVersion
          canFallback = false
          exit for
        end if
      end for
    else if constants.externalConfig = invalid OR constants.externalConfig.info = invalid OR constants.externalConfig.info.fallback_blocked_versions = invalid  'externalConfig is missing. In this case, do not take risk of loading submitted version. Just show error modal.
      canFallback = false
    end if
  end if

  if canFallback = true
    nodeHelpers = TubiNodeHelpers()
    starterLibrary = nodeHelpers.getChildById(tubiScene, "starterLibrary")

    if starterLibrary <> invalid
      starterLibrary.unobserveField("loadStatus")
      tubiScene.removeChild(starterLibrary)
    end if

    remoteLibrary = nodeHelpers.getChildById(tubiScene, "TubiRemoteLibrary")

    if remoteLibrary <> invalid
      remoteLibrary.unobserveField("loadStatus")
      tubiScene.removeChild(remoteLibrary)
    end if

    controller = loadPackagedComponents(tubiScene, port, startupArgs)
    controller.fadeInContentController = true
    controller.isComponentLibFailedToLoad = true
    return true 'successully fallback
  else
    return false 'can not fallback on the current version as explicitly specified by external config.
  end if
End Function


' Makes requests for popper experiments and remote config and places the values on the constants
' As would happen in the starter controller.
'
' @request: assocArray, an instance of the request module as returned by TubiRequest()
' @constants: assocArray, constants as returned by getConstants(), this version of constants
'                         will be the constants that are part of the submitted build.
' @return: assocArray, passed in constants AA that has been updated with remote config and
'                      experiment values.
Function setRemoteConfigAndExperimentsOnConstants(request, constants)
  externalConfig = TubiExternalConfig(request, constants)
  externalConfig.init() 'sets external config values from server on constants
  experiments = TubiExperiments(constants)
  experiments.init(request) 'sets experiment values from server on constants

  return constants
End Function


' Makes a request to update or delete roku continue watching info.
'
' @tubiRequest: assocArray, an instance of the request module as returned by TubiRequest()
' @requestInfo: assocArray, information related to the request like url,method and post body.
Function updateRokuContinueWatchingInfo(tubiRequest, requestInfo)
  tubiRequest = tubiRequest.createAsync(requestInfo.url, requestInfo.requestType, requestInfo.options)
  m.queue.pushRequest(tubiRequest)
End Function
