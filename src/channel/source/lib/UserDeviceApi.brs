' Thin wrapper for UserDevice API requests.  Collected here to facilitate easy
' integration tests
Function UserDeviceApi(constants, request, auth)
  return {
    ' dependencies
    constants: constants
    request_: request
    auth_: auth

    ' public
    emailExistsReqInfo: userDeviceApi_emailExistsReqInfo
    signUpReqInfo: userDeviceApi_signUpReqInfo
    signInReqInfo: userDeviceApi_signInReqInfo

    ' private
    commonOptions: userDeviceApi_commonOptions
    createAuthRequest: userDeviceApi_createAuthRequest
  }
End Function


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
  options["method"] = "POST"
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
  options["method"] = "POST"
  options["body"] = body
  return {
    url: url
    options: options
  }
End Function


'''''''''''''''''''''
' create an auth request if user is logged in, otherwise use a normal request
Function userDeviceApi_createAuthRequest(url, reqName, options)
  request = m.auth_.createAuthRequest(url, reqName, options)
  if request = invalid
    request = m.request_.createAsync(url, reqName, options)
  end if
  return request
End Function
