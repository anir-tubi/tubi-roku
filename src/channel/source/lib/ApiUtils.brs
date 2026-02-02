' Thin wrapper for CMS API requests.  Collected here to facilitate easy
' integration tests
' @constants: assocarray Instance of constants.
' @pubServerPersistentData: assocarray Holds the value for user/device level settings.
Function ApiUtils(constants, pubServerPersistentData) as Object

  return {
    ' dependencies
    constants: constants
    pubServerPersistentData: pubServerPersistentData

    ' public
    getCommonOptions: apiUtils_getCommonOptions
    getPlatform: apiUtils_getPlatform
  }

End Function

' Gets the platform value from constants
' @return: string The platform value (e.g., "roku", "telstra")
Function apiUtils_getPlatform()
  return m.constants.platform
End Function

' @appendFailSafeHeaders: boolean Pass true if we want to append fail safe parameters.
Function apiUtils_getCommonOptions(appendFailSafeHeaders = false)

  headers = {}
  ' appending in this style is necessary to prevent m.constants.headers.commonUapi from being
  ' mutated by potential later appends, since assoc arrays are passed by reference.
  headers.append(m.constants.headers.commonUapi)

  if appendFailSafeHeaders = true
    if m.pubServerPersistentData <> invalid AND m.pubServerPersistentData.parentalRating <> invalid
      headers["X-TUBI-RATING"] = m.constants.serverValues.parentalControls[m.pubServerPersistentData.parentalRating]
    end if

    headers.append(m.constants.headers.tubiPlatform)
  end if

  if m.constants.settings.enableFailSafe = true
    headers.append(m.constants.headers.triggerFailSafe)
  end if

  options = {
    params: {
      "platform": m.constants.platform
      "device_id": m.constants.deviceInfo.deviceId
    }
    headers: headers
  }
  return options

End Function
