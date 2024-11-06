Function TubiExternalConfig(constants as Object) as Object
  return {
    constants: constants

    'default values should just be a simple key/value associative array
    defaultValues: {
      youbora_enabled: 0
    }

    ' public methods
    getConfigsRequestInfo: tubiExternalConfig_getConfigsRequestInfo
    parseBlockedAnalyticsEvents: tubiExternalConfig_parseBlockedAnalyticsEvents
  }
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
  options.headers.append(constants.headers.tubiPlatform)

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
      configs.blocked_analytics_events_mapping = m.parseBlockedAnalyticsEvents(configs.blocked_analytics_events_mapping)
    end if
  end if

  return configs
End Function


' @blockedAnalyticsEvents: assocarray, {"essential": ["active"], "analytics": ["auto_play"]}
Function tubiExternalConfig_parseBlockedAnalyticsEvents(blockedAnalyticsEvents)
  ' Converting to blocked_analytics_events_mapping from {"essential": ["active"], "analytics": ["auto_play"]} to {"active": "essential", "ad_click": "analytics"}.
  blockedAnalyticsEventsAA = {}
  if type(blockedAnalyticsEvents) = "roAssociativeArray"
    for each consentKey in blockedAnalyticsEvents
      for each event in blockedAnalyticsEvents[consentKey]
        blockedAnalyticsEventsAA[event] = consentKey
      end for
    end for
  end if

  return blockedAnalyticsEventsAA
End Function
