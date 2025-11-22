' Provides a spot to put code shared between StarterController and ContentController to avoid them getting out of sync
Function retrieveClientErrorConfig(successCallback = retrieveClientErrorConfigSuccessCallback, errorCallback = retrieveClientErrorConfigErrorCallback)
  m.performanceMetricsTracker.startAppLaunchMetricTiming("client_error_config_request")
  ' If the global field is not set then we need to add it.
  if getClientErrorConfigFromGlobal(invalid) = invalid
    m.global.update({
      "clientErrorConfig": {}
    }, true)
  end if

  m.makeRequest({
    url: m.constants.urls.clientErrorConfigEndpoint
    requestType: m.constants.reqNames.generic
    successCallback: successCallback
    errorCallback: errorCallback
    responseType: "assocarray"
    retries: 0
  })
End Function


Function retrieveClientErrorConfigSuccessCallback(response)
  if response <> invalid
    clientErrorConfig = response
  else
    tubiLog("Received invalid client error config. Falling back to built in version")
    clientErrorConfig = getLocalClientErrorConfig()
  end if

  updateAndConvertClientErrorConfig(clientErrorConfig)
End Function


Function retrieveClientErrorConfigErrorCallback(_response)
  tubiLog("Error retrieving remote client error config. Falling back to built in version")
  clientErrorConfig = getLocalClientErrorConfig()
  updateAndConvertClientErrorConfig(clientErrorConfig)
End Function


' Standardized spot to convert and update the client error config to make sure everything is in sync and formatted properly
Function updateAndConvertClientErrorConfig(clientErrorConfig)
  clientErrorConfig = convertClientErrorConfig(clientErrorConfig)
  m.updateGeneralTaskClientErrorConfig(clientErrorConfig)
  m.global.clientErrorConfig = clientErrorConfig
  m.performanceMetricsTracker.endAppLaunchMetricTiming("client_error_config_request")
End Function


Function retrieveClientErrorConfigSuccessCallbackTriggerRetrieveInitialAuthInfo(response)
  retrieveClientErrorConfigSuccessCallback(response)
  retrieveInitialAuthInfo()
End Function


Function retrieveClientErrorConfigErrorCallbackTriggerRetrieveInitialAuthInfo(response)
  retrieveClientErrorConfigErrorCallback(response)
  retrieveInitialAuthInfo()
End Function


Function retrieveInitialAuthInfo()
  TubiLog("retrieveInitialAuthInfo")
  m.tubiAuthUpdate.initOrUpdateAuthInfo(onInitialAuthInfoRetrieved)
End Function


Function onInitialAuthInfoRetrieved()
  TubiLog("onInitialAuthInfoRetrieved")
  ' Auth will be required first in the future but for now we aren't changing that flow so just load the other dependencies
  sendRequestForExternalConfig()
End Function


' Performs network request to get experiments and external config.
Function sendRequestForExperiments()
  TubiLog("sendRequestForExperiments")
  m.performanceMetricsTracker.startAppLaunchMetricTiming("experiments_request")
  constants = m.constants

  if m.constants.settings.mode = "qa" AND m.constants.settings.disableExperiments = true then
    m.global.experimentsInfo = {}
  end if

  ' Check if we already got our experiments
  if getExperimentsInfoFromGlobal() <> invalid OR isMajorEventDay() = true then
    m.isExperimentsConfigReady = true
    runControllerStartSequence()
    m.performanceMetricsTracker.endAppLaunchMetricTiming("experiments_request")
  else
    experiments = TubiExperiments({})
    experimentsRequestInfo = experiments.getNamespaceRequestInfo(constants)
    if experimentsRequestInfo <> invalid
      experimentsRequestInfo.successCallback = onExperimentsRequestSuccess
      experimentsRequestInfo.errorCallback = onExperimentsRequestFailure
      experimentsRequestInfo.timeoutInMilliSec = 5000
      m.makeRequest(experimentsRequestInfo)
    else
      ' If there are no namespaces then skip the request.
      m.isExperimentsConfigReady = true
    end if
  end if
End Function


Function sendRequestForExternalConfig()
  TubiLog("sendRequestForExternalConfig")
  m.performanceMetricsTracker.startAppLaunchMetricTiming("external_config_request")

  constants = m.constants
  externalConfig = TubiExternalConfig(constants)

  config = getExternalConfigInfoFromGlobal(invalid)
  if config <> invalid then
    ' m.global.constants gets replaced after restarting the application. If we still have the external config then the values that are copied over from externalConfig into constants will not be present after calling restartApp().
    updateConstantsValuesFromExternalConfig(config)
    m.isExternalConfigReady = true
    runControllerStartSequence()
    m.performanceMetricsTracker.endAppLaunchMetricTiming("external_config_request")
  else
    externalConfigRequestInfo = externalConfig.getConfigsRequestInfo()
    externalConfigRequestInfo.successCallback = onExternalConfigRequestSuccess
    externalConfigRequestInfo.errorCallback = onExternalConfigRequestFailure
    externalConfigRequestInfo.timeoutInMilliSec = 5000
    m.makeRequest(externalConfigRequestInfo)
  end if
End Function


' Callback triggered once the experiments request is successful.
Function onExperimentsRequestSuccess(experimentsInfo)
  TubiLog("onExperimentsRequestSuccess")
  m.global.experimentsInfo = experimentsInfo
  m.isExperimentsConfigReady = true
  m.updateGeneralTaskExperimentsInfo(experimentsInfo)

  ' Statsig experiments are now initialized in parallel with Tubi experiments
  runControllerStartSequence()
  m.performanceMetricsTracker.endAppLaunchMetricTiming("experiments_request")
End Function


' Initialize Statsig experiments using encapsulated StatsigExperiments
Function initializeStatsigExperiments()
  tubiLog("initializeStatsigExperiments")
  m.performanceMetricsTracker.startAppLaunchMetricTiming("statsig_initialization_request")
  m.statsigExperiments = StatsigExperiments(m.constants)

  if m.global.hasField("statsigExperimentsInfo") = false
    m.global.addField("statsigExperimentsInfo", "assocarray", false)
  end if

  if m.statsigExperiments <> invalid
    m.statsigExperiments.initialize(onStatsigInitializationSuccess, onStatsigInitializationError)
  else
    m.performanceMetricsTracker.endAppLaunchMetricTiming("statsig_initialization_request")
    TubiLog("Failed to create StatsigExperiments instance")
    'Mark isStatsigConfigReady as ready and continue startup sequence
    m.isStatsigConfigReady = true
    runControllerStartSequence()
  end if
End Function


' Callback triggered if the experiment request fails.
Function onExperimentsRequestFailure(_responses)
  TubiLog("onExperimentsRequestFailure")
  ' Continue using the local defaults.
  m.isExperimentsConfigReady = true

  ' Statsig experiments are now initialized in parallel with Tubi experiments
  runControllerStartSequence()
  m.performanceMetricsTracker.endAppLaunchMetricTiming("experiments_request")
End Function


' Callback triggered once the config request is successful.
Function onExternalConfigRequestSuccess(config)
  TubiLog("onExternalConfigRequestSuccess")

  if config = invalid then
    TubiLog("onExternalConfigRequestSuccess: Invalid config received")
    config = {}
  end if

  externalConfigOverrides = getExternalConfigOverrides()
  if externalConfigOverrides <> invalid then
    config.append(externalConfigOverrides)
  end if

  m.global.externalConfigInfo = config
  updateConstantsValuesFromExternalConfig(config)

  if isAA(config.blocked_analytics_events_mapping) = true
    ' Storing the value of blocked analytics event to registry as a fallback in future if the external config call fails.
    RegWrite("blocked_analytics_events_mapping", FormatJson(config.blocked_analytics_events_mapping), m.constants.registrySectionIDs.fallbacks)
  end if

  m.isExternalConfigReady = true
  m.performanceMetricsTracker.endAppLaunchMetricTiming("external_config_request")
  sendRequestForExperiments()
  initializeStatsigExperiments()
  retrieveSoTStaticConfig()
End Function


' Callback triggered once the config request is fails.
Function onExternalConfigRequestFailure(_error)
  TubiLog("onExperimentsRequestFailure")

  config = {}

  ' Reading the fallback data if present from the registry and setting it to constants.
  blockedEventsList = RegRead("blocked_analytics_events_mapping", m.constants.registrySectionIDs.fallbacks)
  if blockedEventsList <> invalid
    blockedEventsList = ParseJson(blockedEventsList)
    if isAA(blockedEventsList) = true
      config = {
        "blocked_analytics_events_mapping": blockedEventsList
      }
    end if
  end if

  externalConfigOverrides = getExternalConfigOverrides()
  if externalConfigOverrides <> invalid then
    config.append(externalConfigOverrides)
  end if

  m.global.externalConfigInfo = config
  updateConstantsValuesFromExternalConfig(config)

  m.isExternalConfigReady = true
  m.performanceMetricsTracker.endAppLaunchMetricTiming("external_config_request")
  sendRequestForExperiments()
  initializeStatsigExperiments()
  retrieveSoTStaticConfig()
End Function


' Retrieves the external config overrides from the registry.
' @returns: The external config overrides from the registry. If the registry value is not set or is not a string, then invalid is returned.
Function getExternalConfigOverrides()
  overrides = regReadAll(m.constants.registrySectionIDs.overrides)
  if isString(overrides.externalConfig) = true then
    return parseJson(overrides.externalConfig)
  end if

  return invalid
End Function


Function updateConstantsValuesFromExternalConfig(config)
  if config <> invalid then
    if config.country <> invalid AND config.country <> ""
      m.constants.deviceInfo.countryCode = UCase(config.country)
    end if

    if config.youbora <> invalid
      if config.youbora.vod = 1 OR config.youbora.vod = true
        m.constants.settings.youboraEnabledVod = true
      end if

      if config.youbora.linear = 1 OR config.youbora.linear = true
        m.constants.settings.youboraEnabledLinear = true
      end if

      if config.youbora.preview = 1 OR config.youbora.preview = true
        m.constants.settings.youboraEnabledPreview = true
      end if

      if config.youbora.trailer = 1 OR config.youbora.trailer = true
        m.constants.settings.youboraEnabledTrailer = true
      end if
    end if

    'Client log disabled by the remote config
    clientLogsEnabled = config.client_log_enabled
    if clientLogsEnabled = 0 OR clientLogsEnabled = false
      m.constants.settings.clientLogsEnabled = false
    end if

    'realtime metric disabled by the remote config
    realtimeMetricsEnabled = config.realtime_metric_enabled
    if realtimeMetricsEnabled = 0 OR realtimeMetricsEnabled = false
      m.constants.settings.realtimeMetricsEnabled = false
    end if

    ' Since we're modifying constants here we need to push up the changes to the global copy
    m.global.constants = m.constants
    m.updateGeneralTaskConstants(m.constants)
  end if
End Function


' Observes updateAuth field on the passed in node
' @taskNode: The Task node that we will observe the updateAuth field on.
Function observeUpdateAuth(taskNode)
  if taskNode = invalid OR taskNode.isSubType("Task") = false then
    tubiLog("Task node not passed in to observeUpdateAuth")
  else
    TubiLog("observeUpdateAuth " + taskNode.subtype())
    taskNode.observeFieldScoped("updateAuth", "onUpdateAuthChange")
  end if
End Function


' Observes logoutAndRestartApp field on the passed in node
' @taskNode: The Task node that we will observe the logoutAndRestartApp field on.
Function observeLogoutAndRestartApp(taskNode)
  if taskNode = invalid OR taskNode.isSubType("Task") = false then
    tubiLog("Task node not passed in to observeLogoutAndRestartApp")
  else
    TubiLog("observeLogoutAndRestartApp")
    taskNode.observeFieldScoped("logoutAndRestartApp", "logoutAndRestartApp")
  end if
End Function


Function onUpdateAuthChange()
  if m.getAuthOperationInProgress = false then
    m.getAuthOperationInProgress = true
    TubiLog("onUpdateAuthChange")
    m.tubiAuthUpdate.initOrUpdateAuthInfo(onUpdatedAuthRetrieved, true)
  end if
End Function


Function onUpdatedAuthRetrieved()
  TubiLog("onUpdatedAuthRetrieved")
  m.getAuthOperationInProgress = false
  nodes = getAuthUpdatedNodesList()
  for each node in nodes
    node.authUpdated = true
  end for

  handleUpdatedAuth()
End Function


' Helper function to log a user out of the app by calling the TubiAuthUpdate.logout function but also setting the getAuthOperationInProgress flag to true to prevent duplicate auth requests.
Function logout(callback = invalid)
  m.getAuthOperationInProgress = true

  m.tubiAuthUpdate.logout(onUpdatedAuthRetrieved)

  if isFunction(callback)
    callback()
  end if
End Function


' @returns: boolean, true if the current time is during a major event, false if not
Function isMajorEventDay()
  majorEventStart = getExternalConfigValueFromGlobal("major_event_failsafe_start", m.constants.configHubFallbacks.majorEventStart)
  majorEventEnd = getExternalConfigValueFromGlobal("major_event_failsafe_end", m.constants.configHubFallbacks.majorEventEnd)
  return isNowWithinTimePeriod(majorEventStart, majorEventEnd)
End Function


' This function is used to retrieve the soTStaticConfig from the tensor api.
Function retrieveSoTStaticConfig()
  m.performanceMetricsTracker.startAppLaunchMetricTiming("sot_static_config_request")
  m.makeRequest({
    url: m.constants.urls.tensor.SoTStaticConfig
    requestType: m.constants.reqNames.getSoTStaticConfig
    successCallback: retrieveSoTStaticConfigSuccessCallback
    errorCallback: retrieveSoTStaticConfigErrorCallback
    responseType: "assocarray"
    timeoutInMilliSec: 5000
  })
End Function


Function retrieveSoTStaticConfigSuccessCallback(staticConfig)
  if staticConfig <> invalid AND m.global <> invalid
    m.global.update({ "soTStaticConfig": staticConfig }, true)
    m.updateGeneralTaskSoTStaticConfig(staticConfig)
  end if

  setSoTStaticConfigComplete()
End Function


Function retrieveSoTStaticConfigErrorCallback(_error = invalid)
  setSoTStaticConfigComplete()
End Function

' Check : if this function can be removed. Calling runControllerStartSequence() here waits for SoT static config to be complete which
' increases the time to load the app. Since SoT is nice to have and not a blocker for the app to load, we can remove this function in the future.
Function setSoTStaticConfigComplete()
  m.soTStaticConfigComplete = true
  m.performanceMetricsTracker.endAppLaunchMetricTiming("sot_static_config_request")
  runControllerStartSequence()
End Function


' Statsig initialization success callback
' @successResponse: assocarray, response object from Statsig initialization
'
Function onStatsigInitializationSuccess(successResponse)
  ' Mark Statsig as ready
  m.isStatsigConfigReady = true

  ' Process the Statsig response through the StatsigExperiments instance
  if m.statsigExperiments <> invalid
    statsigExperimentsInfo = m.statsigExperiments.processStatsigResponse(successResponse)

    if m.constants.settings.mode <> "production"
      applyExperimentOverrides(statsigExperimentsInfo)
    end if

    m.global.statsigExperimentsInfo = statsigExperimentsInfo
    m.updateGeneralTaskStatSigExperiments(statsigExperimentsInfo)
    tubiLog("StatsigExperiments processed and stored globally")
  else
    tubiLog("Warning: StatsigExperiments instance not available for response processing")
  end if

  m.performanceMetricsTracker.endAppLaunchMetricTiming("statsig_initialization_request")
  runControllerStartSequence()
End Function


' Statsig initialization error callback
' @errorResponse: assocarray, error object from Statsig initialization
'
Function onStatsigInitializationError(errorResponse)
  ' Mark Statsig as ready (even though it failed) so app can continue
  m.isStatsigConfigReady = true

  ' Log detailed error information for debugging
  if errorResponse <> invalid
    if errorResponse.error <> invalid
      tubiLog("Statsig error details: " + errorResponse.error)
    end if
    if errorResponse.statusCode <> invalid
      tubiLog("Statsig HTTP status code: " + errorResponse.statusCode.toStr())
    end if
  end if

  m.performanceMetricsTracker.endAppLaunchMetricTiming("statsig_initialization_request")
  runControllerStartSequence()
End Function


' Apply experiment overrides from registry to Statsig experiments
' This allows QA/developers to manually override experiment variants via TestingAid panel
' Only applies in non-production modes for testing purposes
'
' @param statSigExperimentsInfo: assocarray, the Statsig experiments info object to modify
Function applyExperimentOverrides(statSigExperimentsInfo as Object) as Void
  ' Skip overrides in production mode for safety
  if m.constants.settings.mode = "production"
    return
  end if

  ' Read experiment overrides from registry (stored by TestingAid panel)
  experimentOverrides = RegReadAll("experimentOverrides")
  if not isAA(experimentOverrides)
    return
  end if

  ' Create Statsig interface to access hash and experiment methods
  experimentInterface = StatsigExperimentsInterface(statSigExperimentsInfo)

  ' Loop through each overridden experiment
  for each experimentId in experimentOverrides
    ' Parse the stored JSON override data
    experimentOverride = ParseJson(experimentOverrides[experimentId])
    if experimentOverride = invalid
      continue for ' Skip invalid JSON entries
    end if

    ' Hash the experiment ID to match Statsig's internal format
    hashedExperimentId = experimentInterface.getHashValue(experimentId)
    experiment = statSigExperimentsInfo[hashedExperimentId]

    ' If there is no entry add a new one
    if experiment = invalid then
      experiment = {}
      statSigExperimentsInfo[hashedExperimentId] = experiment
    end if

    if experiment <> invalid
      ' Extract group information from the override
      groupName = experimentOverride.group.name
      parameterValues = experimentOverride.group.parameterValues
      ruleId = experimentOverride.group.id + ":device_id:id_override"

      ' Override the experiment configuration with the selected group
      experiment.append({
        "groupName": groupName
        "config": {
          "group_name": groupName
          "value": parameterValues ' Parameter values for this variant
          "rule_id": ruleId ' Custom rule ID to identify overrides
          "group": experimentOverride.group.id ' Group ID for tracking
        }
      })
    end if
  end for
End Function