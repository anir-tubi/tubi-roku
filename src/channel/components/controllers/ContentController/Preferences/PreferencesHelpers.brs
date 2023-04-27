Function getPreferences(onGetPreferencesCompletionCallback = invalid)
  m.onGetPreferencesCompletionCallback = onGetPreferencesCompletionCallback

  requestInfo = {}

  isUserSigedIn = isLoggedInUser()

  if isUserSigedIn = true
    requestInfo = m.userDeviceApi.createUserSettingsReqInfo()
  else
    requestInfo = m.userDeviceApi.createDeviceSettingsReqInfo()
  end if

  ' Makes a network request to either user or device settings based on user logged in status.
  m.makeRequest({
    url: requestInfo.url
    options: requestInfo.options
    requestType: m.constants.reqNames.getPreferences
    successCallback: onGetPreferencesComplete
    errorCallback: onGetPreferencesError
    responseType: "assocarray"
  })
End Function


Function onGetPreferencesComplete(preferences)
  ' Updates the node with the data from the parser.
  m.preferences.update(preferences)
  markRequestCompleteAndExecuteCallback()
End Function


' Callback triggered if the get preferences errors out.
Function onGetPreferencesError(_msg)
  ' In case of error we will continue using default or existing values incase it is a refresh request.
  markRequestCompleteAndExecuteCallback()
End Function


Function markRequestCompleteAndExecuteCallback()
  ' Marks the request was complete so that we can inform content controller that it is good to go.
  m.getPreferencesComplete = true
  if m.onGetPreferencesCompletionCallback <> invalid
    m.onGetPreferencesCompletionCallback()
    m.onGetPreferencesCompletionCallback = invalid
  end if
End Function


' preferences will be a assocarray. Ex: {"audioTrack": "", "isVideoPreviewOn": false}
Function savePreferences(preferences)
  ' Creating backend to front end key mapping so that we can use camelcase fields.
  preferenceKeys = m.constants.preferenceKeys
  
  mappedPreferences = {}

  ' Providing flexibility if we need to update multiple keys at once.
  for each key in preferences
    ' Making sure we allow only whitelisted keys as per above mapping.
    if preferenceKeys[key] <> invalid
      mappedPreferences[preferenceKeys[key]] = preferences[key]
    end if
  end for
  
  if mappedPreferences.count() > 0
    requestInfo = {}

    isUserSigedIn = isLoggedInUser()

    if isUserSigedIn = true
      requestInfo = m.userDeviceApi.createPatchUserSettingsReqInfo(mappedPreferences)
    else
      requestInfo = m.userDeviceApi.createPatchDeviceSettingsReqInfo(mappedPreferences)
    end if

    m.makeRequest({
      url: requestInfo.url
      requestType: m.constants.reqNames.patchPreferences
      options: requestInfo.options
      responseType: "assocarray"
      silenceCallbackWarnings: true
    })

    ' Updating the local copy with the new value.
    m.preferences.update(preferences)
  end if
End Function
