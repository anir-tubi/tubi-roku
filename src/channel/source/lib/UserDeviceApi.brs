' Thin wrapper for the old UAPI user_device requests and the new account API requests
Function UserDeviceApi(constants)
  return {
    ' dependencies
    constants: constants

    ' public
    emailExistsReqInfo: userDeviceApi_emailExistsReqInfo
    signUpReqInfo: userDeviceApi_signUpReqInfo
    signInReqInfo: userDeviceApi_signInReqInfo
    deviceRegisterInfo: userDeviceApi_deviceRegisterInfo
    checkBirthdayInfo: userDeviceApi_checkBirthdayInfo
    patchSettingsInfo: userDeviceApi_patchSettingsInfo

    ' private
    commonOptions: userDeviceApi_commonOptions
  }
End Function


' returns a set of common params within an options AA that are used by all UAPI endpoints
Function userDeviceApi_commonOptions()
  return {
    params: {
      "app_id": m.constants.settings.shortAppName
      "platform": m.constants.platform
      "device_id": m.constants.deviceInfo.deviceId
    }
  }
End Function


''''''''''''''''''''''
'emailExistsReqInfo()
'
Function userDeviceApi_emailExistsReqInfo(passedOptions = {})
  url = m.constants.urls.account.emailExists
  options = m.commonOptions()
  if passedOptions.params <> invalid
    options.params["email"] = passedOptions.params.email
  end if
  return {
    url: url
    options: options
  }
End Function


''''''''''''''''''''''
'signUpReqInfo()
'
Function userDeviceApi_signUpReqInfo(passedOptions = {})
  url = m.constants.urls.users.signup
  options = {}
  body = FormatJSON(passedOptions.body)
  options["method"] = m.constants.reqTypes.post
  options["body"] = body
  return {
    url: url
    options: options
  }
End Function


''''''''''''''''''''''
'signInReqInfo()
'
Function userDeviceApi_signInReqInfo(passedOptions = {})
  url = m.constants.urls.account.login
  options = {}
  body = FormatJSON(passedOptions.body)
  options["method"] = m.constants.reqTypes.post
  options["body"] = body
  return {
    url: url
    options: options
  }
End Function


' send a POST with a birthdate, get back an age
' 422 HTTP response code means user is below the minimum allowed age in the US (COPPA)
' 451 HTTP response code means user is below the minimum allowed age for some international reason
'
' @birthdate: string, date formatted as "YYYY-MM-DD"
Function userDeviceApi_deviceRegisterInfo(birthdate)
  url = m.constants.urls.account.deviceRegister
  options = {}
  body = {
    platform: m.constants.platform
    device_id: m.constants.deviceInfo.deviceId
    birthday: birthdate
  }
  body = FormatJSON(body)
  options["method"] = m.constants.reqTypes.post
  options["body"] = body

  return {
    url: url
    options: options
  }
End Function


Function userDeviceApi_checkBirthdayInfo(userId)
  url = m.constants.urls.account.checkBirthday

  options = {
    params: {}
  }
  options.params["user_id"] = userId

  return {
    url: url
    options: options
  }
End Function


' @userId: string, the user id as told by the backend
' @passedOptions: AA, options to be passed to TubiRequest().createAsync. The value for the "body"
'                     key must be an AA (which will be turned into a JSON string)
Function userDeviceApi_patchSettingsInfo(userId, passedOptions)
  url = m.constants.urls.users.settings + "/" + userId + "/settings"

  options = passedOptions

  if passedOptions <> invalid and type(passedOptions.body) = "roAssociativeArray"
    options["body"] = FormatJSON(passedOptions.body)
  end if

  options["method"] = m.constants.reqTypes.patch

  return {
    url: url
    options: options
  }
End Function