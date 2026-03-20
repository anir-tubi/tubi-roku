Function TubiLogger(constants, requestInstance, auth, sentryInstance = invalid)
  return {
    request: requestInstance
    auth: auth
    constants: constants
    sentry: sentryInstance

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
          performanceMetrics: "PERFORMANCE_METRICS"
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
    isLoggingAllowed: tubiLog_isLoggingAllowed
    isSampled: tubiLog_isSampled
    getClientLogEvent: tubiLog_getClientLogEvent
    normalizeMessageMapForBatch: tubiLog_normalizeMessageMapForBatch
    populateMessage: tubiLog_populateMessage

    ' private methods to delete after purple carpet event
    isNowWithinTimePeriod: tubiLog_isNowWithinTimePeriod
    isIso8601String: tubiLog_isIso8601String
  }
End Function


'--------------------------------------------------------------------------------
'--------------------------------------------------------------------------------
'the following 4 functions can be used with just a message in case of only wanting to log to the console
'however, anything worthy of warn or error severity should be sent to the server (ie. fill all the parameters for warn and error)

'debug will only send logging to the server if the device id is in m.idsToLog
Function tubiLog_debug(message = "" as Dynamic, serverTypeName = "" as String, subtype = "" as String, queue = invalid as Object, samplePercent = 1.0 as Float)
  logInfoAA = m.buildLogInfo(message, m.logConsts.debug.serverType[serverTypeName], subtype, m.logConsts.debug.name)
  m.printLogInfo(logInfoAA.level, logInfoAA.subtype, logInfoAA.message)
  if m.isLoggingAllowed() = true AND m.isSampled(samplePercent) = true
    m.sendLogging(logInfoAA, queue)
  end if
End Function


Function tubiLog_info(message = "" as Dynamic, serverTypeName = "" as String, subtype = "" as String, queue = invalid as Object, samplePercent = 1.0 as Float)
  logInfoAA = m.buildLogInfo(message, m.logConsts.info.serverType[serverTypeName], subtype, m.logConsts.info.name)
  m.printLogInfo(logInfoAA.level, logInfoAA.subtype, logInfoAA.message)
  if m.isLoggingAllowed() = true AND m.isSampled(samplePercent) = true
    m.sendLogging(logInfoAA, queue)
  end if
End Function


Function tubiLog_error(message = "" as Dynamic, serverTypeName = "" as String, subtype = "" as String, queue = invalid as Object, samplePercent = 1.0 as Float)
  logInfoAA = m.buildLogInfo(message, m.logConsts.error.serverType[serverTypeName], subtype, m.logConsts.error.name)
  m.printLogInfo(logInfoAA.level, logInfoAA.subtype, logInfoAA.message)
  if m.isLoggingAllowed() = true AND m.isSampled(samplePercent) = true
    m.sendLogging(logInfoAA, queue)
  end if
End Function


Function tubiLog_warn(message = "" as Dynamic, serverTypeName = "" as String, subtype = "" as String, queue = invalid as Object, samplePercent = 1.0 as Float)
  logInfoAA = m.buildLogInfo(message, m.logConsts.warn.serverType[serverTypeName], subtype, m.logConsts.warn.name)
  m.printLogInfo(logInfoAA.level, logInfoAA.subtype, logInfoAA.message)
  if m.isLoggingAllowed() = true AND m.isSampled(samplePercent) = true
    m.sendLogging(logInfoAA, queue)
  end if
End Function


'@message: string or roAssociativeArray, the message to be logged
'@level: string, (optional), possible log levels are "debug", "info", "warn", or "error"
'@queue: roAssociativeArray, object as created by RequestQueue()
'@samplePercent: float (optional), possible values are between 0 and 1. default is 1.0
Function tubiLog_exception(message = "" as Dynamic, level = "exception" as String, queue = invalid as Object, samplePercent = 1.0 as Float) as Void
  m.printLogInfo(level, "", message)

  if m.isSampled(samplePercent) = true AND m.sentry <> invalid
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
Function tubiLog_isSampled(samplePercent)
  ' send only sample percent logs to sentry sdk
  canLog = false

  if m.constants.settings.useLogSampling = false AND m.constants.settings.mode <> "production"
    canLog = true
  else if samplePercent = 1
    canLog = true
  else if samplePercent > 0
    fRandom = Rnd(0)
    if samplePercent > fRandom
      canLog = true
    end if
  end if

  return canLog
End Function


' returns true if config hub says we can send logs AND is not a major event day
Function tubiLog_isLoggingAllowed()
  if m.constants <> invalid AND m.constants.settings <> invalid
    clientLogsEnabled = m.constants.settings.clientLogsEnabled
    logsEnableType = type(clientLogsEnabled)

    if (logsEnableType = "Boolean" OR logsEnableType = "roBoolean") AND clientLogsEnabled = true
      if m.isNowWithinTimePeriod(m.constants.configHubFallbacks.majorEventStart, m.constants.configHubFallbacks.majorEventEnd) = false
        return true
      end if
    end if
  end if

  return false
End Function


' Gets log level value (initialized lazily on first access)
' Since consoleLoggingLevel is a compile-time constant, it won't change during runtime
Function tubiLog_getLogLevel_() as Integer
  #if consoleLoggingEnabled
    if m.configuredLogLevel = invalid
      m.configuredLogLevel = 0

      appInfo = CreateObject("roAppInfo")
      logLevel = appInfo.GetValue("consoleLoggingLevel")

      if logLevel <> invalid AND logLevel <> ""
        logLevelInt = logLevel.toInt()
        if logLevelInt <> invalid AND logLevelInt >= 0 AND logLevelInt <= 3
          m.configuredLogLevel = logLevelInt
        end if
      end if
    end if

    return m.configuredLogLevel
  #else
    return -1
  #end if
End Function


' Checks if a log level should be printed based on the configured consoleLoggingLevel
' @level: string, the log level ("debug", "info", "warn", or "error")
' @returns: boolean, true if the log should be printed
Function tubiLog_shouldPrintLog_(level as String) as Boolean
  #if consoleLoggingEnabled
    logLevelsMap = {
      debug: 0
      info: 1
      warn: 2
      error: 3
    }

    if logLevelsMap[level] = invalid
      return true ' defaulting to true if the level is unknown or not set
    end if

    return logLevelsMap[level] >= tubiLog_getLogLevel_()
  #else
    return false
  #end if
End Function


' prints the log on console based
'@level: string, (optional), possible log levels are "debug", "info", "warn", or "error"
'@subtype: string, (optional), a small string used to differentiate log messages
'@message: string or roAssociativeArray, the message to be logged
Function tubiLog_printLogInfo_(level as String, subType as String, message as Dynamic)
  #if consoleLoggingEnabled
    if tubiLog_shouldPrintLog_(level) = true
      if type(message) = "roAssociativeArray"
        message = FormatJson(message)
      end if

      ' user has set consoleLoggingEnabled to true in their dev.yml/qa.yml
      print tubiLog_getLogPrintout_(level, subType, message)
    end if
  #end if
End Function


Function tubiLog_buildLogInfo_(message as Dynamic, serverType as Dynamic, subtype as String, level as String) as Object
  if subtype = ""
    subtype = "client_generic"
  end if

  messageMap = invalid
  if type(message) = "roAssociativeArray" then
    messageMap = message
    message = FormatJson(message)
  end if

  logInfoAA = {
    level: level
    subtype: subtype
    message: message
  }

  if messageMap <> invalid then
    logInfoAA["message_map"] = messageMap
  end if

  'serverType may be invalid
  logInfoAA["type"] = serverType

  return logInfoAA
End Function


'sends the logging info to the server by creating a logging request and adding the logging request to the passed in request queue
'@logInfoAA: roAssociativeArray ie.
'  logInfoAA = {
'    level: "error"
'    subtype: "video-failure"
'    message: "Video with id: 1234 failed to play"
'    message_map: {}
'    type: "CLIENT:ERROR"
'  }
'  logInfo.type may be invalid
'@queue: roAssociativeArray, object as created by RequestQueue()
'
'returns invalid if the log was only printed to the console
Function tubiLog_sendLogging_(logInfoAA as Object, queue as Object)
  if logInfoAA <> invalid AND logInfoAA.count() > 0
    if logInfoAA.message <> "" AND m.constants <> invalid

      if logInfoAA["type"] <> invalid AND logInfoAA.level <> "" AND logInfoAA.subtype <> "" AND queue <> invalid
        'don't send debug or info statements unless the user id is in m.constants.idsToLog
        if m.constants.idsToLog.DoesExist(m.constants.deviceInfo.deviceId) OR logInfoAA.level = m.logConsts.warn.name OR logInfoAA.level = m.logConsts.error.name OR logInfoAA.level = m.logConsts.info.name
          loggingRequest = m.getLoggingRequest(logInfoAA)
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
'@logInfoAA: associativeArray, a logInfo object as returned by m.buildLogInfo()
Function tubiLog_getLoggingRequest_(logInfoAA as Object) as Object
  body = m.getClientLogEvent(logInfoAA)
  reqOptions = {
    body: FormatJson(body)
    method: m.constants.reqTypes.post
    headers: m.constants.headers.commonUapi
    retries: 0
  }

  loggingRequest = m.request.createAsync(m.constants.urls.analyticsV3.sendEvent, "client_log_" + logInfoAA.level, reqOptions)

  return loggingRequest
End Function


Function tubiLog_getClientLogEvent(eventValues) as Object
  eventBase = {
    log_type: ""
    log_subtype: ""
    level: ""
    video_id: ""
    message: ""
    message_map: {}
  }

  if eventValues.type <> invalid
    eventValues.log_type = eventValues.type
  end if

  if eventValues.subtype <> invalid
    eventValues.log_subtype = eventValues.subtype
  end if

  message_map = {}
  if eventValues.message_map <> invalid
    message_map = eventValues.message_map
  end if

  ' Extract batch event_payloads for batch path; message_map is left intact
  batchPayloads = invalid
  if message_map["event_payloads"] <> invalid AND type(message_map["event_payloads"]) = "roArray"
    arr = message_map["event_payloads"]
    if arr.count() > 0
      batchPayloads = arr
    end if
  end if

  deviceInfo = m.constants.deviceInfo

  message_map.append({
    "model": deviceInfo.model
    "rokuCountryCode": deviceInfo.rokuCountryCode
    "firmwareVersion": deviceInfo.firmwareVersion
  })

  ' Remove any properties that are invalid as that will cause the request to be rejected on the backend. Also try to convert any non-string values to strings if possible
  propertiesToDelete = []

  ' Count of properties that were invalid. Want to keep track of this to not throw in the case only these values are being removed
  invalidPropertiesCount = 0
  for each key in message_map
    value = message_map[key]
    if value = invalid
      invalidPropertiesCount++
      propertiesToDelete.push(key)
    end if

    valueType = type(value)
    if (valueType <> "String") AND (valueType <> "roString") then
      ' Preserve roAssociativeArray/roArray only for batch path (message_map not sent; we use normalizeMessageMapForBatch per payload).
      ' Non-batch: backend MessageMapEntry expects string values only, so remove or convert non-strings.
      if batchPayloads <> invalid AND (valueType = "roAssociativeArray" OR valueType = "roArray") then
        ' Leave as-is; batch path uses extracted batchPayloads and normalized payloads, not this message_map
      else if getInterface(value, "ifToStr") <> invalid then
        message_map[key] = value.toStr()
      else
        propertiesToDelete.push(key)
      end if
    end if
  end for

  propertiesToDeleteCount = propertiesToDelete.count()
  if propertiesToDeleteCount > 0 AND m.constants.settings.mode = "dev" AND propertiesToDeleteCount <> invalidPropertiesCount then
    throw "TubiLogger.getClientLogEvent: Removed invalid properties from message_map: " + FormatJson(propertiesToDelete)
  end if

  for each key in propertiesToDelete
    message_map.delete(key)
  end for

  eventValues.message_map = message_map

  authInfo = m.auth.getAuthInfo()
  userId = 0
  if authInfo <> invalid AND authInfo.userId <> invalid
    userId = authInfo.userId.toInt()
  end if

  ' Batch path: combine multiple payloads into one request with full envelope per payload
  ' Backend MessageMapEntry expects string values only; nested objects (e.g. tags) are serialized to JSON string
  if batchPayloads <> invalid
    eventPayloads = []
    for each payload in batchPayloads
      if type(payload) = "roAssociativeArray"
        messageMapForPayload = m.normalizeMessageMapForBatch(payload)
        eventId = CreateObject("roDeviceInfo").GetRandomUUID()
        time = CreateObject("roDateTime")
        timestamp = time.ToISOString("milliseconds")
        clientLogEvent = {
          device_id: m.constants.deviceInfo.deviceId
          platform: m.constants.analyticsPlatform
          user_id: userId
          client_common: {
            event_id: eventId
            event_timestamp: timestamp
          }
          version: m.constants.deviceInfo.clientVersion
          app_id: m.constants.appName
          log_type: eventValues.log_type
          log_subtype: eventValues.log_subtype
          level: eventValues.level
          message_map: messageMapForPayload
        }
        eventPayloads.push(clientLogEvent)
      end if
    end for
    if eventPayloads.count() > 0
      return {
        "event_name": "client_logs"
        "event_payloads": eventPayloads
      }
    end if
  end if

  eventInfo = m.populateMessage("client_logs", eventValues, eventBase)

  eventId = CreateObject("roDeviceInfo").GetRandomUUID()
  time = CreateObject("roDateTime")
  timestamp = time.ToISOString("milliseconds")

  clientLogEvent = {
    device_id: m.constants.deviceInfo.deviceId
    platform: m.constants.analyticsPlatform
    user_id: userId
    client_common: {
      event_id: eventId
      event_timestamp: timestamp
    }
    version: m.constants.deviceInfo.clientVersion
    app_id: m.constants.appName
  }

  ' Appending the event data.
  if eventInfo.client_logs <> invalid
    clientLogEvent.append(eventInfo.client_logs)
  end if

  return {
    "event_name": "client_logs"
    "event_payloads": [clientLogEvent]
  }
End Function


' Returns a copy of payload with all values as strings for backend MessageMapEntry (no nested objects).
' Nested roAssociativeArray/roArray are serialized via FormatJson.
Function tubiLog_normalizeMessageMapForBatch(payload as Object) as Object
  result = {}
  for each key in payload
    value = payload[key]
    if value = invalid
      ' skip invalid
    else if type(value) = "String" OR type(value) = "roString"
      result[key] = value
    else if type(value) = "roAssociativeArray" OR type(value) = "roArray"
      result[key] = FormatJson(value)
    else if getInterface(value, "ifToStr") <> invalid
      result[key] = value.toStr()
    end if
  end for
  return result
End Function


Function tubiLog_populateMessage(messageType, messageValues, messageBase)
  if messageBase <> invalid
    message = {}
    messageFields = {}
    for each prop in messageValues
      'only allow values that exist on the messageBase (ie. the source of truth for the data format)
      if messageBase[prop] <> invalid
        value = messageValues[prop]
        if value <> invalid
          if type(value) <> "roAssociativeArray"
            value = value.toStr()
            if value <> ""
              messageFields.addReplace(prop, value)
            end if
          else
            messageFields.addReplace(prop, value)
          end if
        end if
      end if
    end for

    message.addReplace(messageType, messageFields)
    return message
  else
    return invalid
  end if
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
    lpad = Function(value, padLength = 2, padCharacter = "0")
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

  if level <> "error" AND level <> "info" AND level <> "warn"
    level = "debug"
  end if

  if type(message) = "roString" OR type(message) = "String" OR type(message) = "roAssociativeArray"
    globalTrackingLogging = invalid

    if logType = "exception" OR serverTypeName <> ""
      if m.trackingLoggingTask = invalid 'most of the caller already have m.trackingLoggingTask, so no need for global.

        if m.global <> invalid
          globalTrackingLogging = m.global.trackingLoggingTask
        end if
      else
        globalTrackingLogging = m.trackingLoggingTask
      end if
    end if

    if globalTrackingLogging <> invalid ' sentry
      if logType = "exception"
        globalTrackingLogging.logException = {
          message: message
          level: level
          samplePercent: samplePercent
        }
      else

        if serverTypeName <> "" ' logging uapi
          globalTrackingLogging.logMsg = {
            message: message
            serverTypeName: serverTypeName
            subtype: subtype
            level: level
            samplePercent: samplePercent
          }
        else
          tubiLog_printLogInfo_(level, subtype, message)
        end if

      end if
    else
      tubiLog_printLogInfo_(level, subtype, message)
    end if
  end if
End Function


Function tubiException(message = "" as Dynamic, level = "error" as String, samplePercent = 1.0 as Float) as Void
  tubiLog_helper("exception", message, level, "", "", samplePercent)
End Function


Function tubiLog(message = "" as Dynamic, level = "debug" as String) as Void
  tubiLog_helper("log", message, level)
End Function


' Note logDebug purposely can't send to a backend server. This is to allow optimization in our build process in the future
Function logDebug(message = "" as Dynamic, subtype = "" as String)
  #if consoleLoggingEnabled
    tubiLog_helper("log", message, "debug", "", subtype)
  #end if
End Function


Function logInfo(message = "" as Dynamic, serverTypeName = "" as String, subtype = "" as String, samplePercent = 1.0 as Float)
  tubiLog_helper("log", message, "info", serverTypeName, subtype, samplePercent)
End Function


Function logWarn(message = "" as Dynamic, serverTypeName = "" as String, subtype = "" as String, samplePercent = 1.0 as Float)
  tubiLog_helper("log", message, "warn", serverTypeName, subtype, samplePercent)
End Function


Function logError(message = "" as Dynamic, serverTypeName = "" as String, subtype = "" as String, samplePercent = 1.0 as Float)
  tubiLog_helper("log", message, "error", serverTypeName, subtype, samplePercent)
End Function


' Delete these time based functions that exist in TimeUtils.brs after the purple carpet event is over
' >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
' >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

' Determines if the current time is within the passed in startTime and endTime, inclusive.
' IMPORTANT: The ISO-8601 strings of the params must match the formats documented at
' https://developer.roku.com/en-gb/docs/references/brightscript/interfaces/ifdatetime.md#fromiso8601stringdatestring-as-string-as-void
'
' @startTime: string, an ISO-8601 string representing the earliest time in the period, UTC time
' @endTime: string, an ISO-8601 string representing the latest time in the period, UTC time
Function tubiLog_isNowWithinTimePeriod(startTime, endTime)
  if m.isIso8601String(startTime) = true AND m.isIso8601String(endTime) = true
    dateTime = CreateObject("roDateTime")
    nowSeconds = dateTime.AsSeconds()

    dateTime.FromISO8601String(startTime)
    startSeconds = dateTime.AsSeconds()

    dateTime.FromISO8601String(endTime)
    endSeconds = dateTime.AsSeconds()

    if startSeconds <= nowSeconds AND endSeconds >= nowSeconds
      return true
    end if
  end if

  return false
End Function


' @strToCheck: string, hopefully an ISO-861 formatted string as recognized by Roku
'                      ie. in the format "2009-01-01 01:00:00.000" or "2009-01-01T01:00:00.000"
Function tubiLog_isIso8601String(strToCheck)
  ' check we have a string
  typeStrToCheck = type(strToCheck)
  if typeStrToCheck <> "roString" AND typeStrToCheck <> "String"
    return false
  end if

  ' Since Z indicates UTC, allowing Z at the end.
  ' Removing it from the end if present so that integer validation at line number 245 does not fail.
  if strToCheck.EndsWith("Z") = true
    strLen = strToCheck.len()
    strToCheck = strToCheck.left(strLen - 1)
  end if

  ' check we have the date and time parts
  dateTimeParts = strToCheck.split(" ")
  if dateTimeParts.count() <> 2
    dateTimeParts = strToCheck.split("T")
    if dateTimeParts.count() <> 2
      return false
    end if
  end if

  ' check the date part is formatted correctly
  date = dateTimeParts[0]
  dateParts = date.split("-")
  if dateParts.count() <> 3
    return false
  end if

  year = dateParts[0]
  month = dateParts[1]
  day = dateParts[2]

  if year.len() <> 4 OR month.len() <> 2 OR day.len() <> 2
    return false
  end if

  ' check that only digits were used. toInt() returns 0 if the string contains letters
  yearChars = year.split("")
  monthChars = month.split("")
  dayChars = day.split("")
  allDateChars = []
  allDateChars.append(yearChars)
  allDateChars.append(monthChars)
  allDateChars.append(dayChars)
  for each char in allDateChars
    asciiVal = Asc(char)
    if asciiVal < 48 OR asciiVal > 57
      return false
    end if
  end for

  if month.toInt() < 1 OR month.toInt() > 12
    return false
  end if

  if day.toInt() < 1 OR day.toInt() > 31
    return false
  end if

  ' check the time part is formatted correctly
  time = dateTimeParts[1]
  timeParts = time.split(":")
  if timeParts.count() <> 3
    return false
  end if

  hours = timeParts[0]
  minutes = timeParts[1]
  seconds = timeParts[2]

  hoursChars = hours.split("")
  minutesChars = minutes.split("")
  allTimeChars = []
  allTimeChars.append(hoursChars)
  allTimeChars.append(minutesChars)

  if hours.len() <> 2 OR minutes.len() <> 2
    return false
  end if

  if hours.toInt() < 0 OR hours.toInt() > 24
    return false
  end if

  if minutes.toInt() < 0 OR minutes.toInt() > 59
    return false
  end if

  ' check the seconds and milliseconds are formatted correctly
  secsAndMillis = seconds.split(".")
  if secsAndMillis.count() < 1 OR secsAndMillis.count() > 2
    return false
  end if

  secs = secsAndMillis[0]
  if secs.len() <> 2
    return false
  end if

  if secs.toInt() < 0 OR secs.toInt() > 59
    return false
  end if

  secondsChars = secs.split("")
  allTimeChars.append(secondsChars)

  if secsAndMillis.count() = 2
    milliseconds = secsAndMillis[1]
    millisecondsChars = milliseconds.split("")
    allTimeChars.append(millisecondsChars)
  end if

  ' check that only digits were used. toInt() returns 0 if the string contains letters
  for each char in allTimeChars
    asciiVal = Asc(char)
    if asciiVal < 48 OR asciiVal > 57
      return false
    end if
  end for

  return true
End Function
' >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
' >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
