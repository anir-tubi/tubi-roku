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
Function tubiExternalConfig_storeConfigs_(configs, constants)
  constants.externalConfig.info = configs
  return constants
End Function



Function tubiExternalConfig_getConfigsRequest(request, constants)
  url = constants.urls.userDevice.config
  options = {
    params: {
      "device_id": constants.deviceInfo.deviceId
    }
    headers:{}
  }
  options.headers.append(constants.headers.commonUapi)

  return request.createAsync(url, "getExternalConfigs", options)
End Function


' @responseData: string, the JSON object returned by req.runSynchrounous() or req.response.data
Function tubiExternalConfig_parseConfigs(responseData)
  configs = invalid
  if responseData <> invalid
    configs = ParseJson(responseData)
  end if

  return configs
End Function