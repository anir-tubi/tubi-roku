' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseGetServerPersistentData(fullResponse, _reqInfo)
  serverPersistentData = {}
  data = fullResponse.data

  if isAA(data) = true
    serverPersistentDataKeyMap = m.constants.serverPersistentDataKeys

    for each frontendKey in serverPersistentDataKeyMap
      backendKey = serverPersistentDataKeyMap[frontendKey]
      if data[backendKey] <> invalid
        serverPersistentData[frontendKey] = data[serverPersistentDataKeyMap[frontendKey]]
      end if
    end for

  end if

  return serverPersistentData
End Function
