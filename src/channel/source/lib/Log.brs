Function TubiLogger(constants, request, auth, sentry = invalid)
  return {
    request: request
    auth: auth
    constants: constants
    sentry: sentry

    'server types are determined by specifically allowed strings that populate the 'type' field in the API
    'printed is part of what will be printed to the console
    logConsts: {
      debug: {
        name: "debug"
        serverType: {
          apiDebug: "API:DEBUG"
          clientDebug: "CLIENT:DEBUG"
          videoDebug: "VIDEO:DEBUG"
          adDebug: "AD:DEBUG"
        }
      }
      error: {
        name: "error"
        serverType: {
          apiError: "API:ERROR"
          apiBadResponse: "API:BAD_RESPONSE"
          videoPlayback: "VIDEO:PLAYBACK"
          videoLoad: "VIDEO:LOAD"
          videoBuffer: "VIDEO:BUFFER"
          adError: "AD:ERROR"
        }
      }
      info: {
        name: "info"
        serverType: {
          apiInfo: "API:INFO"
          clientInfo: "CLIENT:INFO"
          videoInfo: "VIDEO:INFO"
          adInfo: "AD:INFO"
        }
      }
      warn: {
        name: "warn"
        serverType: {
          apiSlow: "API:SLOW"
          apiTimeout: "API:TIMEOUT"
          clientMemory: "CLIENT:MEMORY"
          clientCpu: "CLIENT:CPU"
          clientDisk: "CLIENT:DISK"
          adTimeout: "AD:TIMEOUT"
          adBadResponse: "AD:BAD_RESPONSE"
        }
      }
    }

    'public methods
    debug: tubiLog_debug
    error: tubiLog_error
    info: tubiLog_info
    warn: tubiLog_warn
    exception: tubiLog_exception

    'private methods
    printLogInfo: tubiLog_printLogInfo_
    buildLogInfo: tubiLog_buildLogInfo_
    sendLogging: tubiLog_sendLogging_
    getLoggingRequest: tubiLog_getLoggingRequest_
    sendSentryLogging: tubiLog_sendSentryLogging_
    getLogPrintout: tubiLog_getLogPrintout_
  }
End Function


'--------------------------------------------------------------------------------
'--------------------------------------------------------------------------------
'the following 4 functions can be used with just a message in case of only wanting to log to the console
'however, anything worthy of warn or error severity should be sent to the server (ie. fill all the parameters for warn and error)

'debug will only send logging to the server if the device id is in m.idsToLog
Function tubiLog_debug(message = "" as String, serverTypeName = "" as String, subtype = "" as String, queue = invalid as Object, samplePercent = 1.0 as Float)
  logInfo = m.buildLogInfo(message, m.logConsts.debug.serverType[serverTypeName], subtype, m.logConsts.debug.name)
  m.printLogInfo(logInfo.level, logInfo.subtype, logInfo.message)
  if isSampled(samplePercent) = true
    m.sendLogging(logInfo, queue)
  end if
End Function


Function tubiLog_info(message = "" as String, serverTypeName = "" as String, subtype = "" as String, queue = invalid as Object, samplePercent = 1.0 as Float)
  logInfo = m.buildLogInfo(message, m.logConsts.info.serverType[serverTypeName], subtype, m.logConsts.info.name)
  m.printLogInfo(logInfo.level, logInfo.subtype, logInfo.message)
  if isSampled(samplePercent) = true
    m.sendLogging(logInfo, queue)
  end if
End Function


Function tubiLog_error(message = "" as String, serverTypeName = "" as String, subtype = "" as String, queue = invalid as Object, samplePercent = 1.0 as Float)
  logInfo = m.buildLogInfo(message, m.logConsts.error.serverType[serverTypeName], subtype, m.logConsts.error.name)
  m.printLogInfo(logInfo.level, logInfo.subtype, logInfo.message)
  if isSampled(samplePercent) = true
    m.sendLogging(logInfo, queue)
  end if
End Function


Function tubiLog_warn(message = "" as String, serverTypeName = "" as String, subtype = "" as String, queue = invalid as Object, samplePercent = 1.0 as Float)
  logInfo = m.buildLogInfo(message, m.logConsts.warn.serverType[serverTypeName], subtype, m.logConsts.warn.name)
  m.printLogInfo(logInfo.level, logInfo.subtype, logInfo.message)
  if isSampled(samplePercent) = true
    m.sendLogging(logInfo, queue)
  end if
End Function


'@message: string or roAssociativeArray, the message to be logged
'@level: string, (optional), possible log levels are "debug", "info", "warn", or "error"
'@queue: roAssociativeArray, object as created by RequestQueue()
'@samplePercent: float (optional), possible values are between 0 and 1. default is 1.0
Function tubiLog_exception(message = "" as Dynamic, level = "exception" as String, queue = invalid as Object, samplePercent = 1.0 as Float) as void
  m.printLogInfo(level, "", message)

  if isSampled(samplePercent) = true AND m.sentry <> invalid
    tubiToSentry = {}
    tubiToSentry[m.logConsts.error.name] = "error"
    tubiToSentry[m.logConsts.warn.name] = "warning"
    tubiToSentry[m.logConsts.info.name] = "info"
    m.sendSentryLogging(message, tubiToSentry[level], queue)
  end if
End Function


' isSampled function invokes Rnd(0) to find the random number between given range, based on this the logs will be sent to server
' @samplePercent: float (optional), possible values are between 0 and 1. default is 1.0
' returns boolean
Function isSampled(samplePercent)
  ' send only sample percent logs to sentry sdk
  canLog = false
  if samplePercent = 1
    canLog = true
  else if samplePercent > 0
    fRandom = Rnd(0)
    if samplePercent > fRandom
      canLog = true
    end if
  end if
  return canLog
End Function


' prints the log on console based
'@level: string, (optional), possible log levels are "debug", "info", "warn", or "error"
'@subtype: string, (optional), a small string used to differentiate log messages
'@message: string or roAssociativeArray, the message to be logged
Function tubiLog_printLogInfo_(level as String, subType as String, message as Dynamic)
  if type(message) = "roAssociativeArray"
    message = FormatJson(message)
  end if
  ' user has set consoleLoggingEnabled to true in their dev.yml/qa.yml
  #if consoleLoggingEnabled
    print tubiLog_getLogPrintout_(level, subtype, message)
  #end if
End Function


Function tubiLog_buildLogInfo_(message as String, serverType as Dynamic, subtype as String, level as String) as Object
  if subtype = ""
    subtype = "client_generic"
  end if

  logInfo = {
    level: level
    subtype: subtype
    message: message
  }

  'serverType may be invalid
  logInfo["type"] = serverType

  return logInfo
End Function


'sends the logging info to the server by creating a logging request and adding the logging request to the passed in request queue
'@logInfo: roAssociativeArray ie.
'  logInfo = {
'    level: "error"
'    subtype: "video-failure"
'    message: "Video with id: 1234 failed to play"
'    type: "CLIENT:ERROR"
'  }
'  logInfo.type may be invalid
'@queue: roAssociativeArray, object as created by RequestQueue()
'
'returns invalid if the log was only printed to the console
Function tubiLog_sendLogging_(logInfo as Object, queue as Object)
  if logInfo <> invalid AND logInfo.count() > 0
    if logInfo.message <> "" AND m.constants <> invalid

      if logInfo["type"] <> invalid AND logInfo.level <> "" AND logInfo.subtype <> "" AND queue <> invalid
        'don't send debug or info statements unless the user id is in m.constants.idsToLog
        if m.constants.idsToLog.DoesExist(m.constants.deviceInfo.deviceId) or logInfo.level = m.logConsts.warn.name or logInfo.level = m.logConsts.error.name or logInfo.level = m.logConsts.info.name
          loggingRequest = m.getLoggingRequest(logInfo)
          return queue.pushRequest(loggingRequest)
        end if
      end if
    end if
  end if
  return invalid
End Function


'uses Request().createAsync() to build a request that is ready to be sent to the sentry API
'@message: string or roAssociativeArray, the message to be logged
'@level: string, (optional), possible log levels are "debug", "info", "warn", or "error"
'@queue: roAssociativeArray, object as created by RequestQueue()
'
'returns invalid if the log was only printed to the console, else requestObject
Function tubiLog_sendSentryLogging_(message = "" as Dynamic, level = "info" as String, queue = invalid as Object)
  reqInfo = m.sentry.getReqInfo(message, level)

  if reqInfo = invalid OR queue = invalid
    return invalid
  end if

  url = reqInfo.url
  reqOptions = reqInfo.reqOptions
  sentryRequest = m.request.createAsync(url, "scenegraphException " + level, reqOptions)
  return queue.pushRequest(sentryRequest)
End Function


'uses Request().createAsync() to build a request that is ready to be sent to the logging API
'@logInfo: associativeArray, a logInfo object as returned by m.buildLogInfo()
Function tubiLog_getLoggingRequest_(logInfo as Object) as Object
  loggingReqBody = {
    app_id: m.constants.appName
    platform: m.constants.platform
    device_id: m.constants.deviceInfo.deviceId
    ua: m.constants.deviceInfo.userAgentModel
    version: m.constants.deviceInfo.clientVersion
  }
  loggingReqBody.append(logInfo)

  loggingReqBody["user_id"] = 0

  authInfo = m.auth.getAuthInfo()
  if authInfo <> invalid AND authInfo.userId <> invalid
    loggingReqBody["user_id"] = authInfo.userId.ToInt()
  end if

  reqOptions = {
    body: FormatJson(loggingReqBody)
    method: m.constants.reqTypes.post
    headers: {}
    retries: 0
  }
  reqOptions.headers.append(m.constants.headers.commonUapi)
  url = m.constants.urls.datascience.logging

  loggingRequest = m.request.createAsync(url, "scenegraphLog " + logInfo.level, reqOptions)

  return loggingRequest
End Function


'Builds the full log string that will be printed to the console
'@level: string, (optional), possible log levels are "debug", "info", "warn", or "error"
'@subtype: string, (optional), a small string used to differentiate log messages
'@message: string, the message to be logged
Function tubiLog_getLogPrintout_(level = "" as String, subtype = "" as String, message = "" as String)
  printLevel = {
    debug: "DEBUG"
    error: "ERROR"
    info: "INFO"
    warn: "WARN"
  }

  printout = "LOG "

  if level <> "" AND printLevel[level] <> invalid
    printout = printout + printLevel[level] + " "
  end if

  if subtype <> ""
    printout = printout + "(" + subtype + ") "
  end if

  #if consoleLoggingIncludeTimestamp
    lpad = Function (value, padLength = 2, padCharacter = "0")
      value = value.toStr()
      while value.len() < padLength
        value = padCharacter + value
      end while
      return value
    End Function

    date = createObject("roDateTime")
    printout += lpad(date.getHours()) + ":" + lpad(date.getMinutes()) + ":" + lpad(date.getSeconds()) + "." + lpad(date.getMilliseconds(), 3)
  #end if
  if message <> ""
    printout = printout + ": " + message
  end if

  return printout
End Function


'*******************************************************************************
'
' Public functions (not TubiLogger member functions) meant to run in SceneGraph
' main thread which has access to the global logging node.
'
'*******************************************************************************


''''''''''''''''''''
' tubiLog
'
' Wrapper for logging.  Only used by scenegraph, and only sends to server if the trackingLoggingTask is ready
' By default prints to console
' @logType: "exception" or "log"
' @message: string or roAssociativeArray, the message to be logged
' @level: string, (optional), the type of debug, must be one of "debug", "error", "info", "warn"
' @serverTypeName: string, (semi optional - required for sending log to server), a string that must exist in one of the server types in logConsts, (required by logging API)
' @subtype: string, (optional), a small string used to differentiate log messages (required by logging API)
' @samplePercent: float (optional), possible values are between 0 and 1. default is 1.0
' 1 means send log always, 0 means don't send log
Function tubiLog_helper(logType, message = "" as Dynamic, level = "debug" as String, serverTypeName = "" as String, subtype = "" as String, samplePercent = 1.0 as Float) as Void

  if level <> "error" and level <> "info" and level <> "warn"
    level = "debug"
  end if

  if type(message) = "roString" OR type(message) = "String" OR type(message) = "roAssociativeArray"
    if m.global <> invalid AND m.global.trackingLoggingTask <> invalid
      if logType = "exception" ' sentry
        m.global.trackingLoggingTask.logException = {
          message: message
          level: level
          samplePercent: samplePercent
        }
      else
        if serverTypeName <> "" ' logging uapi
          m.global.trackingLoggingTask.logMsg = {
            message: message
            serverTypeName: serverTypeName
            subtype: subtype
            level: level
            samplePercent: samplePercent
          }
        else
          ' tubiLog_printLogInfo_ is to print console log when tubiLog() is triggered with only message param.
          tubiLog_printLogInfo_(level, subtype, message)
        end if
      end if
    else
      ' tubiLog_printLogInfo_ is to print console log when tubiLog() is triggered with only message param.
      tubiLog_printLogInfo_(level, subtype, message)
    end if
  end if

End Function


Function tubiException(message = "" as Dynamic, level = "error" as String, samplePercent = 1.0 as Float) as Void
  tubiLog_helper("exception", message, level, "", "", samplePercent)
End Function


Function tubiLog(message = "" as Dynamic, level = "debug" as String, serverTypeName = "" as String, subtype = "" as String, samplePercent = 1.0 as Float) as Void
  tubiLog_helper("log", message, level, serverTypeName, subtype, samplePercent)
End Function
