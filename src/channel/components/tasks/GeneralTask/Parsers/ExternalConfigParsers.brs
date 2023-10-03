' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseGetExternalConfigSuccess(fullResponse, _reqInfo)
  config = invalid
  data = fullResponse.data
  if isAA(data) = true
    config = data
    externalConfig = TubiExternalConfig(m.request, m.constants)

    config.blocked_analytics_events = externalConfig.parseBlockedAnaylticsEvents(config.blocked_analytics_events)
  end if

  return config
End Function

