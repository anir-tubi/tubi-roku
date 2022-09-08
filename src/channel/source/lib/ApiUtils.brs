' Thin wrapper for CMS API requests.  Collected here to facilitate easy
' integration tests
Function ApiUtils(constants) as Object

 return {
  ' dependencies
  constants: constants

  ' public
  getCommonOptions: apiUtils_getCommonOptions
 }

End Function


Function apiUtils_getCommonOptions()

  headers = {}
  ' appending in this style is neccessary to prevent m.constants.headers.commonUapi from being
  ' mutated by potential later appends, since assoc arrays are passed by reference.
  headers.append(m.constants.headers.commonUapi)

  options = {
    params: {
      "app_id": m.constants.settings.shortAppName
      "platform": m.constants.platform
      "device_id": m.constants.deviceInfo.deviceId
    }
    headers: headers
  }
  return options

End Function
