' Statsig Lib using GeneralTaskModule for HTTP requests
' @params: context : assocArray, m context
'
Function StatsigLib(context = {}) as Object
  if context.makeRequest = invalid OR context.constants = invalid
    print "[StatsigLib] Make sure GeneralTaskModule has been initialized in the calling context for StatSig"
    return invalid
  end if

  return {
    constants: context.constants
    generalTaskContext: context
    user: invalid ' Store user internally

    ' Public API methods
    createUser: statsigLib_createUser
    initialize: statsigLib_initialize
    getConfig: statsigLib_getConfig
    logExposure: statsigLib_logExposure

    ' Private methods
    makeStatsigRequest: statsigLib_makeStatsigRequest
    getCommonHeaders: statsigLib_getCommonHeaders
    getCurrentTime: statsigLib_getCurrentTime
    log: statsigLib_log
  }
End Function


' Create and store a Statsig user object internally
' Usage: m.statsigLib.createUser(userId, { userType: "premium" })
Function statsigLib_createUser(userID = invalid, customAttributes = {})
  user = {
    userAgent: m.constants.deviceInfo.userAgent
    country: m.constants.deviceInfo.countryCode
    locale: m.constants.deviceInfo.locale
    appVersion: m.constants.deviceInfo.clientVersion
    statsigEnvironment: m.constants.thirdParty.statsig.environment
    ip: "" 'setting as empty to prevent Statsig from inferring the user IP address clients
    custom: {}
  }

  ' Add device-specific custom attributes
  user.custom.deviceModel = m.constants.deviceInfo.model
  user.custom.operatingSystem = m.constants.deviceInfo.operatingSystem
  user.custom.firmwareVersion = m.constants.deviceInfo.firmwareVersion
  user.custom.displayResolution = m.constants.deviceInfo.displayWidth.toStr() + "x" + m.constants.deviceInfo.displayHeight.toStr()
  user.custom.platform = m.constants.platform
  user.custom.isLowVram = m.constants.deviceInfo.lowVram
  user.custom.isLimitedUi = m.constants.deviceInfo.limitedUi
  user.custom.device_id = m.constants.deviceInfo.deviceId

  ' Add user ID if provided
  if userID <> invalid AND userID <> ""
    user.userID = userID
  else
    user.userID = m.constants.deviceInfo.deviceId
  end if

  ' Add any custom attributes
  if type(customAttributes) = "roAssociativeArray"
    for each key in customAttributes
      user.custom[key] = customAttributes[key]
    end for
  end if

  ' Store user internally
  m.user = user

  return user
End Function


' Initialize Statsig for the stored user and get feature gates/configs
' Usage: m.statsigLib.initialize(onStatsigInitSuccess, onStatsigInitError)
'
Function statsigLib_initialize(successCallback = invalid, errorCallback = invalid)
  if m.user = invalid
    m.log("[StatsigLib] Cannot initialize - no user created. Call createUser() first.")
    return invalid
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

  return m.makeStatsigRequest(reqInfo)
End Function


' Get a dynamic config for the stored user
' Usage: m.statsigLib.getConfig("roku_test_config", onTestConfigReceived, onConfigError)
'
Function statsigLib_getConfig(configName, successCallback = invalid, errorCallback = invalid)
  if m.user = invalid
    m.log("[StatsigLib] Cannot get config - no user created. Call createUser() first.")
    return invalid
  end if

  requestBody = {
    user: m.user
    "configName": configName
  }

  options = {
    method: "POST"
    headers: m.getCommonHeaders()
    body: FormatJson(requestBody)
  }

  reqInfo = {
    url: m.constants.urls.statsig.getConfig
    requestType: m.constants.reqNames.statsigGetConfig
    options: options
    successCallback: successCallback
    errorCallback: errorCallback
    responseType: "assocarray"
    timeoutInMilliSec: m.constants.thirdParty.statsig.timeout
    retries: m.constants.thirdParty.statsig.retryCount
  }

  return m.makeStatsigRequest(reqInfo)
End Function


' Log exposure events for A/B testing
' Usage:
' exposure = {
'   user: m.statsigLib.user ' or any user object
'   experimentName: "button_swap_experiment"
'   group: experimentGroup
' }
' m.statsigLib.logExposure([exposure])
'
Function statsigLib_logExposure(exposures, successCallback = invalid, errorCallback = invalid)
  requestBody = {
    exposures: exposures
  }

  options = {
    method: "POST"
    headers: m.getCommonHeaders()
    body: FormatJson(requestBody)
  }

  reqInfo = {
    url: m.constants.urls.statsig.logCustomExposure
    requestType: m.constants.reqNames.statsigLogExposure
    options: options
    successCallback: successCallback
    errorCallback: errorCallback
    responseType: "assocarray"
    timeoutInMilliSec: m.constants.thirdParty.statsig.timeout
    retries: 1
    silenceCallbackWarnings: true
  }

  return m.makeStatsigRequest(reqInfo)
End Function


' Make HTTP request using GeneralTaskModule
Function statsigLib_makeStatsigRequest(reqInfo)
  m.log("Making Statsig request: " + reqInfo.requestType + " to " + reqInfo.url)
  result = m.generalTaskContext.makeRequest(reqInfo)

  if result <> invalid
    m.log("Statsig request initiated successfully: " + reqInfo.requestType)
  else
    m.log("Failed to initiate Statsig request: " + reqInfo.requestType)
  end if

  return result
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


' Internal logging function
Function statsigLib_log(message)
  if m.constants.thirdParty.statsig.enableLogging = true
    tubiLog("[StatsigLib] " + message, "info")
  end if
End Function
