'The Main function serves to run any remote config and experiment API calls and then choose the appropriate UI
Function Main(startupArgs)
  ' this version of constants will be the constants that are part of the submitted build (or the side loaded build)
  ' and only exist in the main brightscript thread.
  ' constants will be reset in remote components for scene graph
  constants = getConstants()
  request = TubiRequest()
  auth = TubiAuth(constants, request)
  log = TubiLogger(constants, request, auth)
  externalConfig = TubiExternalConfig(request, constants)
  experiments = TubiExperiments(constants)

  if startupArgs.ComponentTest <> invalid and startupArgs.ComponentTest <> ""
    ' This will block indefinitely
    ComponentTest(startupArgs.ComponentTest)
  end if

  externalConfigValues = externalConfig.init()
  experimentValues = experiments.init(request)

  logCrashesOnStartup(startupArgs, log, constants)
  runChannel(startupArgs, constants, log, externalConfigValues, experimentValues)
End Function


Function runChannel(startupArgs, constants, log, externalConfigValues, experimentValues) As Void
  ' Load scene graph
  port = CreateObject("roMessagePort")
  input = CreateObject("roInput")
  input.SetMessagePort(port)
  screen = CreateObject("roSGScreen")
  screen.SetMessagePort(port)
  controller = invalid

  ' start the scene graph UI 
  tubiScene = screen.CreateScene("TubiScene")
  sgGlobal = screen.getGlobalNode()
  sgGlobal.addField("constants", "assocarray", false)
  sgGlobal.addField("theme", "assocarray", false)

  'setting constants here is just to get the scene up and running.
  'Global constants will be overwritten with constants pulled from starterController that are the most recent version of constants
  sgGlobal.setField("constants", constants)
  screen.show()

  'run SceneGraph tests if in test mode
  if constants.settings.mode = "test"
    Runner = TestRunner()
    Runner.SetTestsDirectory("pkg:/source/tests")
    Runner.logger.SetVerbosity(2)
    Runner.Run()
    return
  end if

  'this is the packaged constants - the submitted constants
  if constants.starterComponents <> false
    retries = 0
    maxRetries = 5
    backoffFactor = 1.5
    initialBackoff = 1000 'ms
    pause = initialBackoff

    print "attempting to load TubiStarterLibrary "; constants.settings.starterComponentsUrl
    starterLibrary = tubiScene.findNode("TubiStarterLibrary")
    starterLibrary.observeField("loadStatus", port)
    libraryBeingFetched = starterLibrary
    componentsLoaded = false
    starterLibrary.uri = constants.settings.starterComponentsUrl ' kicks off fetch of starter components
    componentTimer = CreateObject("roTimespan")
  else
    'only expect this to happen when side loading/testing
    constants.experiments.info = experimentValues
    constants.externalConfig.info = externalConfigValues
    sgGlobal.setField("constants", constants)
    sgGlobal.setField("theme", constants.ui.themes.default)
    controller = loadPackagedComponents(tubiScene, port, startupArgs)
    componentsLoaded = true
    componentTimer = invalid
  end if

  while true
    msg = wait(200, port)
    msgType = type(msg)

    if msgType = "roInputEvent"
      if controller <> invalid and msg.GetInfo() <> invalid
        inputInfo = msg.GetInfo()
        if inputInfo.type = invalid
          'deeplink info doesn't have a "type" field, so we add one in order to easily differentiate input behavior later
          inputInfo.type = "deeplink"
        end if
        controller.roInputInfo = inputInfo
      end if
    else if msgType = "roSGScreenEvent"
      print "got a screen event "; msg.isScreenClosed()
      if msg.isScreenClosed()
        return
      end if

    else if msgType = "roSGNodeEvent"
      tubiLog("main() got roSGNodeEvent for " + msg.GetField())
      if msg.GetField() = "exitApp"
        if msg.GetData() = true
          return
        end if
      else if msg.GetField() = "loadStatus"
        'starter components or remote components load status update
        print "loadStatus = "; msg.getData()
        if msg.getData() = "ready"
          if msg.GetRoSGNode().id = "TubiStarterLibrary"
            starterController = tubiScene.createChild("TubiStarterLibrary:StarterController")
            starterController.observeField("useRemoteComponents", port)
            starterController.observeField("remoteComponentsUrl", port)
            starterController.externalConfigValues = externalConfigValues
            starterController.experimentValues = experimentValues
            starterController.remoteComponents = constants.remoteComponents
            starterController.setField("getUrl", true)
            retries = 0
            pause = initialBackoff
          else if msg.GetRoSGNode().id = "TubiRemoteLibrary"
            componentsLoaded = true
            controller = tubiScene.createChild("TubiRemoteLibrary:ContentController")
            controller.id = "ContentController"
            controller.setField("externalConfigValues", externalConfigValues)
            controller.setField("experimentValues", experimentValues)
            controller.observeField("exitApp", port)
            controller.startupArgs = startupArgs
          end if
        else if msg.getData() = "loading"
          print msg.GetRoSGNode().id + " status is loading"
        else if msg.getData() = "failed"
          if retries < maxRetries
            retries += 1
            componentLibrary = msg.GetRoSGNode()
            print componentLibrary.id; " failed to load due to API error, attempting retry #"; retries
            pause = pause * backoffFactor
            sleep(pause)
            resetComponentLibrary(componentLibrary, tubiScene, port)
          else
            showComponentsFailedToLoadError(msg, log, screen, constants)
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
          loadPackagedComponents(tubiScene, port, startupArgs)
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
        remoteLibrary.observeField("loadStatus", port)
        remoteLibrary.uri = msg.getData()
      end if
    end if

    ' handle starterComponents and remoteComponents timeouts
    if componentsLoaded = false and componentTimer <> invalid and componentTimer.totalMilliseconds() > 30000
      if retries < maxRetries
        retries += 1
        componentTimer.mark()
        print libraryBeingFetched.id; " failed to load due to timeout, attempting retry #"; retries
        pause = pause * backoffFactor
        sleep(pause)
        resetComponentLibrary(libraryBeingFetched, tubiScene, port)
      else
        showComponentsTimedOutError(libraryBeingFetched, log, screen, constants)
      end if
    end if
  end while
End Function


Function loadPackagedComponents(scene, port, startupArgs)
  controller = scene.createChild("ContentController")
  controller.id = "ContentController"
  controller.observeField("exitApp", port)
  controller.startupArgs = startupArgs
  return controller
End Function


'removes the componentLibrary from the scene, and creates a new componentLibrary with the same id and same url
'as the removed componentLibrary. This will kick off a new request to the url for the remote library.
Function resetComponentLibrary(componentLibrary, scene, port)
  componentLibrary.unobserveField("loadStatus")
  componentId = componentLibrary.id
  componentUri = componentLibrary.uri
  scene.removeChild(componentLibrary)

  newComponentLibrary = scene.createChild("ComponentLibrary")
  newComponentLibrary.id = componentId
  newComponentLibrary.uri = componentUri
  newComponentLibrary.observeField("loadStatus", port)
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
    message: message
    loadStatus: "timeout"
    url: library.uri
  }
  errorPort = CreateObject("roMessagePort")
  log.exception("error", error)
  showStartupErrorDialog(screen, constants)
End Function


Function showComponentsFailedToLoadError(msg, log, screen, constants)
  print msg.GetRoSGNode().id + " status is failed"
  error = {
    message: msg.GetRoSGNode().id + " failed to load"
    loadStatus: msg.getData()
    url: msg.GetRoSGNode().uri
  }
  errorPort = CreateObject("roMessagePort")
  log.exception("error", error)
  showStartupErrorDialog(screen, constants)
End Function


Function showStartupErrorDialog(screen, constants)
  port = CreateObject("roMessagePort")

  sgGlobal = screen.getGlobalNode()
  sgGlobal.setField("theme", constants.ui.themes.default)

  scene = screen.GetScene()
  controller = scene.CreateChild("ErrorController")

  errorObj = {}
  errorObj.contextCode = constants.errors.context.homeScreen 
  errorObj.subtypeCode = constants.errors.subtypes.networkError
  errorObj.title = "Connection Error"

  message = "There may be an issue with your network connection, or with Tubi's server. "
  message += "Please check your network connection and try again."
  message += chr(10)
  errorObj.message = message
  
  controller.observeField("buttonSelected", port)
  controller.error = {
    info: errorObj
    buttonText: "Exit"
  }

  while(true)
    msg = wait(0, port)
    msgType = type(msg)
    if msgType <> invalid then exit while
  end while

  screen.close()
End Function


Function logCrashesOnStartup(args, log, constants)
  ' These are reasons we don't care about
  reasonBlacklist = {
    "EXIT_UNKNOWN":         "EXIT_UNKNOWN"        ' default exit reason
    "EXIT_POWER_MODE":      "EXIT_POWER_MODE"
    "EXIT_DIAL_DELETE":     "EXIT_DIAL_DELETE"
    "EXIT_IDLE_AUTO_EXIT":  "EXIT_IDLE_AUTO_EXIT"
  }

  reason = args.lastExitOrTerminationReason
  if reason <> invalid and reasonBlacklist[reason] = invalid
    messageInfo = {
      message: "Crash detected on previous run"
      reason: reason
      model: constants.deviceInfo.model
    }
    errorPort = CreateObject("roMessagePort")
    log.exception("warn", messageInfo)
  end if
End Function
