' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseGetExternalConfigSuccess(fullResponse, _reqInfo)
  config = invalid
  data = fullResponse.data
  if isAA(data) = true
    config = data
    externalConfig = TubiExternalConfig(m.constants)

    config.blocked_analytics_events_mapping = externalConfig.parseBlockedAnalyticsEvents(config.blocked_analytics_events_mapping)

    ' Convert blocked_analytics_events to aa. ["blocked_analytics_events"] to {"blocked_analytics_events": true}
    ' So that we do not have to loop through during firing of analytics events.

    eventsAA = {}
    if type(config.blocked_analytics_events) = "roArray"
      for each eventKey in config.blocked_analytics_events
        eventsAA[eventKey] = true
      end for
    end if

    config.blocked_analytics_events = eventsAA

  end if

  return config
End Function
