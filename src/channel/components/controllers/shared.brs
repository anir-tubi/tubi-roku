' Provides a spot to put code shared between StarterController and ContentController to avoid them getting out of sync
Function retrieveClientErrorConfig(successCallback = retrieveClientErrorConfigSuccessCallback, errorCallback = retrieveClientErrorConfigErrorCallback)
  ' If the global field is not set then we need to add it.
  if getClientErrorConfigFromGlobal(invalid) = invalid
    m.global.update({
      "clientErrorConfig" : {}
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
    m.global.clientErrorConfig = response
  else
    tubiLog("Received invalid client error config. Falling back to built in version")
    m.global.clientErrorConfig = getLocalClientErrorConfig()
  end if
End Function


Function retrieveClientErrorConfigErrorCallback(_response)
  tubiLog("Error retrieving remote client error config. Falling back to built in version")
  m.global.clientErrorConfig = getLocalClientErrorConfig()
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
  sendRequestForExperimentsAndConfig()
End Function


' Performs network request to get experiments and external config.
Function sendRequestForExperimentsAndConfig()
  TubiLog("sendRequestForExperimentsAndConfig")
  constants = m.constants
  externalConfig = TubiExternalConfig(constants)

  ' Check if we already got our experiments
  if getExperimentsInfoFromGlobal() <> invalid
    m.isExperimentsConfigReady = true
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

  config = getExternalConfigInfoFromGlobal(invalid)
  if config <> invalid then
    ' m.global.constants gets replaced after restarting the application. If we still have the external config then the values that are copied over from externalConfig into constants will not be present after calling restartApp().
    updateConstantsValuesFromExternalConfig(config)
    m.isExternalConfigReady = true
    runControllerStartSequence()
  else
    externalConfigRequestInfo = externalConfig.getConfigsRequestInfo(constants)
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
  runControllerStartSequence()
End Function


' Callback triggered if the experiment request fails.
Function onExperimentsRequestFailure(_responses)
  TubiLog("onExperimentsRequestFailure")
  ' Continue using the local defaults.
  m.isExperimentsConfigReady = true
  runControllerStartSequence()
End Function


' Callback triggered once the config request is successful.
Function onExternalConfigRequestSuccess(config)
  TubiLog("onExternalConfigRequestSuccess")
  if config <> invalid
    m.global.externalConfigInfo = config
    updateConstantsValuesFromExternalConfig(config)

    if isAA(config.blocked_analytics_events_mapping) = true
      ' Storing the value of blocked analytics event to registry as a fallback in future if the external config call fails.
      RegWrite("blocked_analytics_events_mapping", FormatJson(config.blocked_analytics_events_mapping), m.constants.registrySectionIDs.fallbacks)
    end if

    m.global.externalConfigInfo = config

    ' Since we're modifying constants here we need to push up the changes to the global copy
    m.global.constants = m.constants
    m.updateGeneralTaskConstants(m.constants)
  end if
  m.isExternalConfigReady = true
  runControllerStartSequence()
End Function


' Callback triggered once the config request is fails.
Function onExternalConfigRequestFailure(_error)
  TubiLog("onExperimentsRequestFailure")
  ' Reading the fallback data if present from the registry and setting it to constants.
  blockedEventsList = RegRead("blocked_analytics_events_mapping", m.constants.registrySectionIDs.fallbacks)
  if blockedEventsList <> invalid
    blockedEventsList = ParseJson(blockedEventsList)
    if isAA(blockedEventsList) = true
      m.global.externalConfigInfo = {
        "blocked_analytics_events_mapping": blockedEventsList
      }
    end if
  end if

  m.isExternalConfigReady = true
  runControllerStartSequence()
End Function


Function updateConstantsValuesFromExternalConfig(config)
  if config <> invalid then
    if config.country <> invalid AND config.country <> ""
      m.constants.deviceInfo.countryCode = UCase(config.country)
    end if

    'Let youbora be enabled by the remote config
    youboraEnabled = config.youbora_enabled
    if youboraEnabled = true
      m.constants.settings.youboraEnabled = youboraEnabled
    end if

    'Let player log be enabled by the remote config
    playerLogEnabled = config.player_log_enabled
    if playerLogEnabled = true
      m.constants.settings.playerLogEnabled = playerLogEnabled
    end if

    ' Update the frequency we send playprogress events based on the remote config if available
    pingFrequency = getExternalConfigValueFromGlobal("playprogress_interval", m.constants.player.pingFrequency)
    if isNumber(pingFrequency) = true then
      m.constants.player.pingFrequency = pingFrequency
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
End Function


' Helper function to log a user out of the app by calling the TubiAuthUpdate.logout function but also setting the getAuthOperationInProgress flag to true to prevent duplicate auth requests.
Function logout(callback = invalid)
  m.getAuthOperationInProgress = true

  m.tubiAuthUpdate.logout(onUpdatedAuthRetrieved)

  if isFunction(callback)
    callback()
  end if
End Function
