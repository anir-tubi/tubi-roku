'The Main function serves to initiate the application
Function Main(startupArgs)
  m.appStartTime = UpTime(0)
  m.startupArgs = startupArgs

  handleRegistryOperations(startupArgs)

  ' this version of constants will be the constants that are part of the submitted build (or the side loaded build)
  ' and only exist in the main brightscript thread.
  ' constants will be reset in remote components for scene graph
  constants = getConstants()

  port = CreateObject("roMessagePort")
  m.queue = TubiRequestQueue().create(port)
  requestInstance = TubiRequest(constants.settings)
  auth = TubiAuth(constants)
  sentryInfo = Sentry(constants, auth)
  log = TubiLogger(constants, requestInstance, auth, sentryInfo)

  logCrashesOnStartup(m.startupArgs, log, constants)

  ' permaScreen is a permanent screen that exists even when the screen created by runChannel()
  ' is closed. The presence of the permaScreen prevents the app from closing if screen.close()
  ' is called within runChannel(), due to the undocumented and apparent requirement that there
  ' is always at least one screen that on which .show() has been called and has not been closed.
  permaScreen = createObject("roSGScreen")
  permaScreen.createScene("BackgroundScene")
  permaScreen.show()

  while runChannel(constants, log, requestInstance) = true
  end while
End Function


' @constants: assocArray, constants as returned by getConstants()
' @log: assocArray, an instance of the log module as returned by TubiLog()
' @request: assocArray, an instance of the request module as returned by TubiRequest()
'
' returns: boolean, true if the app should be restarted, false if the app should be closed
Function runChannel(constants, log, requestInstance)
  startupArgs = {}
  if m.startupArgs <> invalid
    startupArgs.append(m.startupArgs)
  end if
  m.startupArgs = invalid

  ' Load scene graph
  port = CreateObject("roMessagePort")
  screen = CreateObject("roSGScreen")
  screen.SetMessagePort(port)

  ' start the scene graph UI
  tubiScene = screen.CreateScene("TubiScene")

  screen.show()

  tubiScene.observeField("exitApp", port)
  tubiScene.observeField("disableInstantResume", port)
  tubiScene.observeField("rokuContinueWatchingRequestInfo", port)
  tubiScene.observeField("sendLogToServer", port)
  tubiScene.observeField("enableSystemLogTypes", port)

  if constants.settings.injectRtaOnDeviceComponent = true then
    m.odc = createObject("roSGNode", "RTA_OnDeviceComponent") 'bs:disable-line 1128
  end if

  'add RALE for dev builds - children can not be added to tubiScene until after screen.show has run
  if constants.settings.mode = "dev" AND constants.settings.raleEnabled = true
    tubiScene.createChild("TrackerTask")
  end if
  ' Used to add required node creation needed for RALE component during vscode build
  ' vscode_rale_tracker_entry

  ' Used to add required node creation needed for RDB component during vscode build
  ' vscode_rdb_on_device_component_entry

  'run SceneGraph tests if in test mode
  if constants.settings.mode = "test" then
    if (type(Rooibos__Init) = "Function") then Rooibos__Init() 'bs:disable-line 1001 1140 LINT1001

    localHostUri = constants.settings.localHostUri
    url = localHostUri + "/unit_tests_completed"
    urlTransfer = createObject("roUrlTransfer")
    urlTransfer.setUrl(url)
    urlTransfer.getToString()
    return false
  end if

  tubiScene.setFields({
    "startupArgs": startupArgs
    "appStartTime": m.appStartTime
  })

  ' Setting constants separate to make sure it gets triggered last
  tubiScene.baseChannelConstants = constants

  sysLog = invalid

  while true
    msg = wait(0, port)
    msgType = type(msg)

    if msgType = "roSGNodeEvent"
      field = msg.getField()
      tubiLog("main() got roSGNodeEvent for " + field)
      if field = "exitApp"
        if msg.GetData() = true
          return false
        end if
      else if field = "disableInstantResume"
        if msg.GetData() = true
          contentController = tubiScene.findNode("ContentController")
          if contentController.customResume <> invalid
            m.startupArgs = contentController.customResume.launchParams
          end if
          screen.close() ' destroys the current scene as we need to relaunch the app from beginning
          return true
        end if
      else if field = "rokuContinueWatchingRequestInfo"
        info = msg.getData()
        updateRokuContinueWatchingInfo(requestInstance, info)
      else if field = "sendLogToServer" then
        sendLogToServer(msg.getData(), log)
      else if field = "enableSystemLogTypes" then
        if sysLog = invalid then
          sysLog = CreateObject("roSystemLog")
          sysLog.setMessagePort(port)
        end if

        logTypes = msg.getData()
        for each logType in logTypes
          sysLog.enableType(logType)
        end for
      end if
    else if msgType = "roSystemLogEvent" then
      systemLogEvent = msg.getInfo()

      ' We need to convert over the roDateTime as that can't cross the thread barrier
      systemLogEvent.Datetime = systemLogEvent.Datetime.toISOString("milliseconds")

      tubiScene.systemLogEvent = systemLogEvent
    end if
  end while
  return false
End Function


Function sendLogToServer(contents, log)
  ' Check if contents is a valid associative array and has the required fields. message will be checked in the log module
  if contents <> invalid AND isString(contents.type) = true then
    ' Default samplePercent to 1
    samplePercent = 1
    if isNumber(contents.samplePercent) = true
      samplePercent = contents.samplePercent
    end if

    if contents.type = "exception" AND isString(contents.level) = true then
      log.exception(contents.message, contents.level, m.queue, samplePercent)
    else if log[contents.type] <> invalid AND isString(contents.serverTypeName) = true AND isString(contents.subtype) = true then
      log[contents.type](contents.message, contents.serverTypeName, contents.subtype, m.queue, samplePercent)
    else
      print "Log type '" + contents.type + "' not found in log module or did not have correct params"
    end if
  end if
End Function


Function logCrashesOnStartup(startupArgs, log, constants)
  reason = startupArgs.lastExitOrTerminationReason

  whitelist = {
    "EXIT_OUT_OF_MEMORY": true
    "EXIT_IDLE_AUTO_EXIT": false ' may eventually be interested in sending
    "EXIT_BRIGHTSCRIPT_CRASH": true
    "EXIT_BRIGHTSCRIPT_STOP": true
    "EXIT_BRIGHTSCRIPT_UNK_FUNC": true
    "EXIT_BRIGHTSCRIPT_TIMEOUT": true
    "EXIT_USER_KILL": true
    "EXIT_SYSTEM_KILL": true
    "EXIT_GRAPHICS_NOT_RELEASED": true
    "EXIT_DECODER_NOT_RELEASED": true
    "EXIT_RUNNING_AFTER_SUSPEND": true
    "EXIT_NOT_RESUMED": true
    "EXIT_SIGNAL_TIMEOUT": true
    "EXIT_APP_ERROR": true
    "EXIT_UNLOADED": true
    "EXIT_OS_UPDATE": true
    "EXIT_CHANNEL_UPDATE": true
    "EXIT_CHANNEL_RESTART": true
    "EXIT_CHANNEL_MEM_LIMIT_FG": true
    "EXIT_CHANNEL_MEM_LIMIT_BG": true
    "EXIT_SOFTFAIL": true
  }

  if reason <> invalid AND whitelist[reason] = true then
    appManager = createObject("roAppManager")

    ' Check if we can use the new method available in 13+ firmware
    if findMemberFunction(appManager, "getLastExitInfo") <> invalid then
      lastExitInfo = appManager.getLastExitInfo()

      ' We want to assign the lastExitInfo to ContentController's startupArgs to allow sending a request after the app has started to be able to send additional information such as experiments to client logs. Assigned by reference
      startupArgs.lastExitInfo = lastExitInfo

      baseMessageContents = {}
      baseMessageContents.append(lastExitInfo)

      baseMessageContents["connectionType"] = createObject("roDeviceInfo").getConnectionType()
      baseMessageContents["model"] = constants.deviceInfo.model

      clientLogsMessageContents = {}
      clientLogsMessageContents.append(baseMessageContents)

      log.info(clientLogsMessageContents, "clientInfo", "last-exit-info", m.queue, 1)

      sentryMessageContents = baseMessageContents
      sentryMessageContents.append({
        "name": reason
        "type": constants.errors.type.crashOnPreviousRun
      })
      log.exception(sentryMessageContents, "warn", m.queue, 1)
    else
      messageInfo = {
        message: constants.errors.type.crashOnPreviousRun
        model: constants.deviceInfo.model
        name: reason
        type: constants.errors.type.crashOnPreviousRun
      }
      log.exception(messageInfo, "warn", m.queue, 1)
    end if
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
        if sections = invalid then
          sections = {}
        end if

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


' Makes a request to update or delete roku continue watching info.
'
' @tubiRequest: assocArray, an instance of the request module as returned by TubiRequest()
' @requestInfo: assocArray, information related to the request like url,method and post body.
Function updateRokuContinueWatchingInfo(tubiRequestInstance, requestInfo)
  req = tubiRequestInstance.createAsync(requestInfo.url, requestInfo.requestType, requestInfo.options)
  m.queue.pushRequest(req)
End Function
