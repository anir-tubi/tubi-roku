Function TubiExternalConfig(request as Object, constants as Object) as Object
  return{
    request: request
    constants: constants

    'default values should just be a simple key/value associative array
    defaultValues: {
      youbora_enabled: 0
    }

    ' public methods
    init: tubiExternalConfig_init
    getConfigsRequest: tubiExternalConfig_getConfigsRequest
    parseConfigs: tubiExternalConfig_parseConfigs
    getConfigsRequestInfo: tubiExternalConfig_getConfigsRequestInfo

    ' private methods
    getConfigs: tubiExternalConfig_getConfigs_
    storeConfigs: tubiExternalConfig_storeConfigs_
  }
End Function


' Synchronously requests the configs and places them on constants.
Function tubiExternalConfig_init()
  configs = m.getConfigs()

  mergedConfig = {}
  mergedConfig.append(m.defaultValues)
  if configs <> invalid
    mergedConfig.append(configs)
  end if

  m.storeConfigs(mergedConfig, m.constants)
  return mergedConfig
End Function


' Example JSON response from the service:
'
' {
'   "livetv": false,
'   "intro_landscape_hibpr": "http://c12.adrise.tv/v2/sources/content-owners/adrise-no-ads/325254/v20169072053-1920x1080-2413k.mp4",
'   "intro_landscape_lowbpr": "http://c12.adrise.tv/v2/sources/content-owners/adrise-no-ads/325254/v20169072053-1920x1080-341k.mp4",
'   "intro_portrait_hibpr": "http://c12.adrise.tv/v2/sources/content-owners/adrise-no-ads/325255/v20169072050-1080x1920-2624k.mp4",
'   "intro_portrait_lowbpr": "http://c12.adrise.tv/v2/sources/content-owners/adrise-no-ads/325255/v20169072050-1080x1920-335k.mp4"
' }
'
Function tubiExternalConfig_getConfigs_()
  configRequest = m.getConfigsRequest(m.request, m.constants)
  res = configRequest.runSynchronous()
  configs = m.parseConfigs(res)
  return configs  'can return invalid
End Function


' @configs: assocArray, configs as sent from the UAPI and json parsed
' @constants: assocArray, constants
' @sideEffect: updates the constants AA that is passed into the function by adding an AA on
'              constants.externalConfig.info and updating the value at constants.deviceInfo.countryCode
'              with the value from remote configs (as determined by Maxmind on the backend)
Function tubiExternalConfig_storeConfigs_(configs, constants)
  constants.externalConfig.info = configs

  if constants.deviceInfo <> invalid AND configs <> invalid AND configs.country <> invalid
    constants.deviceInfo.countryCode = UCase(configs.country)
  end if

  return constants
End Function



Function tubiExternalConfig_getConfigsRequest(request, constants)
  requestInfo = m.getConfigsRequestInfo(constants)

  return request.createAsync(requestInfo.url, requestInfo.requestType, requestInfo.options)
End Function


' Returns of assoc array containing info related to get config request.
Function tubiExternalConfig_getConfigsRequestInfo(constants)
  options = {
    params: {
      "device_id": constants.deviceInfo.deviceId
    }
    headers:{}
  }
  options.headers.append(constants.headers.commonUapi)

  return {
    url: constants.urls.configHub.config
    requestType: constants.reqNames.getExternalConfigs
    responseType: "assocarray"
    options: options
  }
End Function


' @responseData: string, the JSON object returned by req.runSynchronous() or req.response.data
Function tubiExternalConfig_parseConfigs(responseData)
  configs = invalid
  if responseData <> invalid
    configs = ParseJson(responseData)
    if type(configs) = "roAssociativeArray"
      ' Converting to blocked_analytics_events from ["start_ad", "ad_click"] to {"start_ad": true, "ad_click": true}.
      blockedAnalyticsEvents = configs.blocked_analytics_events
      blockedAnalyticsEventsAA = {}

      for each event in blockedAnalyticsEvents
        blockedAnalyticsEventsAA[event] = true
      end for

      configs.blocked_analytics_events = blockedAnalyticsEventsAA
    end if

  end if

  return configs
End Function
