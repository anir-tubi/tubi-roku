Function getServerPersistentData(onGetServerPersistentDataCompletionCallback = invalid)
  m.onGetServerPersistentDataCompletionCallback = onGetServerPersistentDataCompletionCallback
  isUserSigedIn = isLoggedInUser()

  if isUserSigedIn = true
    batchRequests = m.userDeviceApi.createUserAndDeviceSettingsBatchRequests()
    ' Makes a network request to both user and device settings if user loggedIn
    m.makeBatchRequest({
      requests: batchRequests
      successCallback: onGetBatchServerPersistentDataComplete
      errorCallback: onGetServerPersistentDataError
      responseType: "assocarray"
    })
  else
    requestInfo = m.userDeviceApi.createDeviceSettingsReqInfo()
    ' Makes a network request to device settings if user not logged in.
    m.makeRequest({
      url: requestInfo.url
      options: requestInfo.options
      requestType: m.constants.reqNames.getServerPersistentData
      successCallback: onGetServerPersistentDataComplete
      errorCallback: onGetServerPersistentDataError
      responseType: "assocarray"
    })
  end if

End Function


Function onGetBatchServerPersistentDataComplete(serverPersistentData)
  ' Updates the node with the data from the parser.
  updates = [
    serverPersistentData.deviceSettings
    serverPersistentData.userSettings
  ]
  saveLocalServerPresistantData(updates)
  markUserDeviceSettingsRequestCompleteAndExecuteCallback()
End Function


Function onGetServerPersistentDataComplete(serverPersistentData)
  ' Updates the node with the data from the parser.
  saveLocalServerPresistantData([serverPersistentData])
  markUserDeviceSettingsRequestCompleteAndExecuteCallback()
End Function


' Callback triggered if the get serverPersistentData errors out.
Function onGetServerPersistentDataError(_msg)
  ' In case of error we will continue using default or existing values incase it is a refresh request.
  markUserDeviceSettingsRequestCompleteAndExecuteCallback()
End Function


Function markUserDeviceSettingsRequestCompleteAndExecuteCallback()
  ' Marks the request was complete so that we can inform content controller that it is good to go.
  m.getServerPersistentDataComplete = true
  if m.onGetServerPersistentDataCompletionCallback <> invalid
    m.onGetServerPersistentDataCompletionCallback()
    m.onGetServerPersistentDataCompletionCallback = invalid
  end if
End Function


' @serverPersistentData: assocArray, settings/serverPersistentData that will be stored on the device/settings API. Ex: {"audioTrack": "", "isVideoPreviewOn": false}
' @saveInto: string, optional, determines if the device settings are stored at the device level or user level on the backend. Possible values are "device", "user".
Function saveServerPersistentData(serverPersistentData, saveInto = "")
  ' Creating backend to front end key mapping so that we can use camelcase fields.
  serverPersistentDataKeys = m.constants.serverPersistentDataKeys

  mappedPersistentData = {}

  ' Providing flexibility if we need to update multiple keys at once.
  for each key in serverPersistentData
    ' Making sure we allow only whitelisted keys as per above mapping.
    if serverPersistentDataKeys[key] <> invalid
      mappedPersistentData[serverPersistentDataKeys[key]] = serverPersistentData[key]
    end if
  end for

  if mappedPersistentData.count() > 0
    requestInfo = {}

    isUserSigedIn = isLoggedInUser()

    if isUserSigedIn = true AND saveInto <> "device"
      requestInfo = m.userDeviceApi.createPatchUserSettingsReqInfo(mappedPersistentData)
    else
      requestInfo = m.userDeviceApi.createPatchDeviceSettingsReqInfo(mappedPersistentData)
    end if

    m.makeRequest({
      url: requestInfo.url
      requestType: m.constants.reqNames.patchServerPersistentData
      options: requestInfo.options
      responseType: "assocarray"
      silenceCallbackWarnings: true
    })

    ' Updating the local copy with the new value.
    saveLocalServerPresistantData([serverPersistentData])
  end if
End Function


'@newServerPersistantData: array, structured as an array of assocarrays to update the local copy with new value.
  ' If array has 2 items
  ' [
  '    {
  '     isdisliketoastnotificationshown: true
  '     isliketoastnotificationshown: true
  '   }

  '   {
  '     isvideopreviewon: false
  '   }
  ' ]

  'If array has only 1 item

  ' [
  '   {
  '     isvideopreviewon: false
  '   }
  ' ]
Function saveLocalServerPresistantData(newServerPersistantData)

  for i = 0 to newServerPersistantData.count() - 1
    m.pub_serverPersistentData.update(newServerPersistantData[i])
  end for

  m.pubSub.publish("pub_serverPersistentData", m.pub_serverPersistentData)

End Function
