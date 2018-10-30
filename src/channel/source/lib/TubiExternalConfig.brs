Function TubiExternalConfig(request as Object, constants as Object) as Object
  return{
    request: request
    constants: constants

    'default values should just be a simple key/value associative array
    defaultValues: {
      mux_enabled: false
    }

    ' public methods
    init: tubiExternalConfig_init

    ' private methods
    getConfigs: tubiExternalConfig_getConfigs_
    storeConfigs: tubiExternalConfig_storeConfigs_
  }
End Function


Function tubiExternalConfig_init()
  configs = m.getConfigs()

  mergedConfig = {}
  mergedConfig.append(m.defaultValues)
  if configs <> invalid
    mergedConfig.append(configs)
  end if

  m.storeConfigs(mergedConfig)
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
  url = m.constants.urls.users.config
  options = {
    params: {
      "device_id": m.constants.deviceInfo.deviceId
    }
  }

  configRequest = m.request.createAsync(url, "getExternalConfigs", options)
  res = configRequest.runSynchronous()

  configs = invalid
  if res <> invalid
    configs = ParseJson(res)
  end if

  return configs  'can return invalid
End Function


' @configs: assocArray, configs as sent from the UAPI and json parsed
Function tubiExternalConfig_storeConfigs_(configs)
  m.constants.externalConfig.info = configs
End Function
