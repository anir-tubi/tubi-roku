' Thin wrapper for the old UAPI user_device requests and the new account API requests
Function UserDeviceApi(constants, apiUtils)

  defaultValues = {
    ' dependencies
    constants: constants

    ' public
    emailExistsReqInfo: userDeviceApi_emailExistsReqInfo
    signUpReqInfo: userDeviceApi_signUpReqInfo
    signInReqInfo: userDeviceApi_signInReqInfo
    deviceRegisterInfo: userDeviceApi_deviceRegisterInfo
    checkBirthdayInfo: userDeviceApi_checkBirthdayInfo
    patchSettingsInfo: userDeviceApi_patchSettingsInfo
    patchAutoplayPreviewSettingInfo: userDeviceApi_patchAutoplayPreviewSettingInfo
    magicLink: userDeviceApi_magicLink
    queryStatusOfMagicLink: userDeviceApi_queryStatusOfMagicLink
  }

  userDeviceApi = {}
  userDeviceApi.append(apiUtils)
  userDeviceApi.append(defaultValues)
  return userDeviceApi

End Function


''''''''''''''''''''''
'emailExistsReqInfo()
'
Function userDeviceApi_emailExistsReqInfo(passedOptions = {})
  url = m.constants.urls.account.emailExists
  options = m.getCommonOptions()
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
  headers = {}
  headers.append(m.constants.headers.commonUapi)
  body = FormatJSON(passedOptions.body)
  options["method"] = m.constants.reqTypes.post
  options["body"] = body
  options["headers"] = headers
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
  headers = {}
  headers.append(m.constants.headers.commonUapi)
  options["method"] = m.constants.reqTypes.post
  options["body"] = body
  options["headers"] = headers
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
  headers = {}
  headers.append(m.constants.headers.commonUapi)
  body = FormatJSON(body)
  options["method"] = m.constants.reqTypes.post
  options["body"] = body
  options["headers"] = headers

  return {
    url: url
    options: options
  }
End Function


Function userDeviceApi_checkBirthdayInfo(userId)
  url = m.constants.urls.account.checkBirthday

  options = {
    params: {}
    headers: {}
  }
  options.params["user_id"] = userId
  options.headers.append(m.constants.headers.commonUapi)

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
  headers = {}
  headers.append(m.constants.headers.commonUapi)
  options["method"] = m.constants.reqTypes.patch
  options["headers"] = headers
  return {
    url: url
    options: options
  }
End Function


' @email : string,  (either taken from roku account or user entered email)
Function userDeviceApi_magicLink(email)
  url = m.constants.urls.account.magicLink
  headers = {}
  options = m.getCommonOptions()
  options.params["email"] = email
  options["method"] = m.constants.reqTypes.post
  return {
    url: url
    options: options
  }
End Function


'@uid: string, unique identifier generated through magicLink for each user
Function userDeviceApi_queryStatusOfMagicLink(uid)
  url = m.constants.urls.account.magicLink + "/" + uid
  headers = {}
  options = m.getCommonOptions()
  options["method"] = m.constants.reqTypes.get
  return {
    url: url
    options: options
  }
End Function


' @choice: boolean, user selection of Video preview on/off
'         true - video Preview on
'         flase - video preview off
Function userDeviceApi_patchAutoplayPreviewSettingInfo(choice)
  url = m.constants.urls.account.patchAutoplayPreview
  options = {}
  body = {enable_video_preview: choice}

  options["body"] = FormatJson(body)
  headers = {}
  headers.append(m.constants.headers.commonUapi)
  options["method"] = m.constants.reqTypes.patch
  options["headers"] = headers
  return {
    url: url
    options: options
  }

End Function
