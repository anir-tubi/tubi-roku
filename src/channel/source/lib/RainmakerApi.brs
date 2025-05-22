Function RainmakerApi(constants)
  defaultValues = {
    ' dependencies
    constants: constants
    ' public
    pauseAdsRequestInfo: rainmakerApi_pauseAdsRequestInfo
  }

  rainmakerApi = {}
  rainmakerApi.append(defaultValues)
  return rainmakerApi
End Function


'@content: contentNode of video player
'@nowPos: current position of video player
'@appMode: video player appMode eg. DEFAULT_MODE / KIDS_MODE / LATINO_MODE
Function rainmakerApi_pauseAdsRequestInfo(content as Object, nowPos as Integer, appMode = "DEFAULT_MODE") as Object
  url = m.constants.urls.pauseAdsUrl
  options = {}
  options.method = m.constants.reqTypes.get

  params = {
    content_id: content.id
    pub_id: content.pubId
    device_id: m.constants.deviceInfo.deviceId
    now_pos: nowPos
    app_id: m.constants.settings.shortAppName
    app_mode: appMode
    model: m.constants.deviceInfo.model
    language: m.constants.deviceInfo.language
    client_version: m.constants.deviceInfo.clientVersion
    os: m.constants.deviceInfo.operatingSystem
    os_version: m.constants.deviceInfo.firmwareVersion
    make: m.constants.deviceInfo.vendorName
  }

  if m.constants.deviceInfo.deviceAdId <> invalid
    params["adv_id"] = m.constants.deviceInfo.deviceAdId
  end if

  if m.constants.deviceInfo.isAdIdTrackingDisabled = true
    params["opt_out"] = "true"
  else
    params["opt_out"] = "false"
  end if

  options.params = params

  return {
    url: url
    options: options
  }
End Function
