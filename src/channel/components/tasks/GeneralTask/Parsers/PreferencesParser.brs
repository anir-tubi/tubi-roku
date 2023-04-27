' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseGetPreferences(fullResponse, _reqInfo)
  preferences = {}
  data = fullResponse.data
  if isAA(data) = true
    preferenceKeyMap = m.constants.preferenceKeys

    for each frontendKey in preferenceKeyMap
      backendKey = preferenceKeyMap[frontendKey]
      if data[backendKey] <> invalid
        preferences[frontendKey] = data[preferenceKeyMap[frontendKey]]
      end if
    end for

  end if

  return preferences
End Function
