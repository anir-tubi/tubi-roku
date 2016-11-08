Function TubiExternalConfig(request as Object, constants as Object) as Object
  return{
    request: request
    constants: constants

    ' public methods
    init: tubiExternalConfig_init

    ' private methods
    getConfigs: tubiExternalConfig_getConfigs_
    storeConfigs: tubiExternalConfig_storeConfigs_
  }
End Function


Function tubiExternalConfig_init()
  configs = m.getConfigs()
  m.storeConfigs(configs)
End Function



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