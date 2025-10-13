' Statsig Lib using GeneralTaskModule for HTTP requests
' @constants: assocArray, constants as set in Constants.brs
'
Function StatsigLib(constants) as Object
  return {
    constants: constants
    user: {}

    ' Public methods
    initialize: statsigLib_initialize
    logExposure: statsigLib_logExposure
    createUser: statsigLib_createUser

    ' Private methods
    makeStatsigRequest: statsigLib_makeStatsigRequest
    getCommonHeaders: statsigLib_getCommonHeaders
    getCurrentTime: statsigLib_getCurrentTime
    isEmptyAssocArray: statsigLib_isEmptyAssocArray
  }
End Function


' Initialize Statsig with user creation and get namespaces & experiments
'
Function statsigLib_initialize(successCallback = invalid, errorCallback = invalid)
  if m.isEmptyAssocArray(m.user) then
    m.createUser()
  end if

  requestBody = {
    user: m.user
  }

  options = {
    method: "POST"
    headers: m.getCommonHeaders()
    body: FormatJson(requestBody)
  }

  reqInfo = {
    url: m.constants.urls.statsig.initialize
    requestType: m.constants.reqNames.statsigInitialize
    options: options
    successCallback: successCallback
    errorCallback: errorCallback
    responseType: "assocarray"
    timeoutInMilliSec: m.constants.thirdParty.statsig.timeout
    retries: m.constants.thirdParty.statsig.retryCount
  }

  m.makeStatsigRequest(reqInfo)
End Function


Function statsigLib_logExposure(exposureData = {})
  if m.isEmptyAssocArray(m.user) then
    m.createUser()
  end if

  exposureData["user"] = m.user
  requestBody = {
    exposures: [exposureData]
  }

  options = {
    method: "POST"
    headers: m.getCommonHeaders()
    body: FormatJson(requestBody)
  }

  reqInfo = {
    url: m.constants.urls.statsig.logCustomExposure
    requestType: m.constants.reqNames.statsigExposure
    options: options
    responseType: "string"
    silenceCallbackWarnings: true
    timeoutInMilliSec: m.constants.thirdParty.statsig.timeout
    retries: m.constants.thirdParty.statsig.retryCount
  }

  m.makeStatsigRequest(reqInfo)
End Function


' Make HTTP request using GenstateralTaskModule
Function statsigLib_makeStatsigRequest(reqInfo)
  makeRequest = getGlobalAA().makeRequest

  if makeRequest <> invalid then
    makeRequest(reqInfo)
  end if
End Function


' Get common headers for Statsig API requests
Function statsigLib_getCommonHeaders()
  return {
    "Content-Type": "application/json"
    "STATSIG-API-KEY": m.constants.thirdParty.statsig.clientApiKey
    "STATSIG-CLIENT-TIME": m.getCurrentTime().toStr()
    "Accept": "application/json"
    "User-Agent": m.constants.deviceInfo.userAgent
  }
End Function


' Get current time in milliseconds since Unix epoch
Function statsigLib_getCurrentTime()
  result = "{0}.{1}"
  time = CreateObject("roDateTime")
  time.toLocalTime()
  result = Substitute(result, time.ToISOString(), time.getMilliseconds().toStr())
  return result
End Function


' Create and store a Statsig user object
Function statsigLib_createUser()
  deviceInfo = m.constants.deviceInfo

  user = {
    "userAgent": deviceInfo.userAgent
    "country": deviceInfo.countryCode
    "locale": deviceInfo.locale
    "appVersion": deviceInfo.clientVersion
    "statsigEnvironment": m.constants.thirdParty.statsig.environment
    "ip": ""
    "userID": ""
    "custom": {}
    "customIDs": {}
  }

  custom = {
    "deviceModel": deviceInfo.model
    "operatingSystem": deviceInfo.operatingSystem
    "firmwareVersion": deviceInfo.firmwareVersion
    "displayResolution": deviceInfo.displayWidth.toStr() + "x" + deviceInfo.displayHeight.toStr()
    "platform": m.constants.platform
    "isLowVram": deviceInfo.lowVram
    "isLimitedUi": deviceInfo.limitedUi
  }

  displayProperties = deviceInfo.displayProperties
  if displayProperties <> invalid AND displayProperties.width <> invalid AND displayProperties.height <> invalid
    custom.screenSize = {
      "width": displayProperties.width.toStr()
      "height": displayProperties.height.toStr()
    }
  end if

  user.custom = custom

  customIDs = {
    "device_id": deviceInfo.deviceId
  }
  user["customIDs"] = customIDs

  m.user = user
End Function


' Helper function to check if an associative array is empty
Function statsigLib_isEmptyAssocArray(assocArray)
  if assocArray = invalid then return true
  if type(assocArray) <> "roAssociativeArray" then return true
  return assocArray.count() = 0
End Function
