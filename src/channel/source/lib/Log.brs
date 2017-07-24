Function TubiLogger(constants, request, auth)
  return {
    request: request
    auth: auth
    constants: constants

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
          clientWarn: "CLIENT:WARN"
          adTimeout: "AD:TIMEOUT"
          adBadResponse: "AD:BAD_RESPONSE"
          videoBuffer: "VIDEO:BUFFER"
        }
      }
    }     

    'public methods
    debug: tubiLog_debug
    error: tubiLog_error
    info: tubiLog_info
    warn: tubiLog_warn

    'private methods
    buildLogInfo: tubiLog_buildLogInfo_
    sendLogging: tubiLog_sendLogging_
    getLoggingRequest: tubiLog_getLoggingRequest_
    getLogPrintout: tubiLog_getLogPrintout_

  }
End Function


''''''''''''''''''''
' tubiLog
'
' Wrapper for logging.  Only used by scenegraph, and only sends to server if the trackingLoggingTask is ready
' By default prints to console
' @message: string, the message to be logged
' @level: string, (optional), the type of debug, must be one of "debug", "error", "info", "warn"
' @subtype: string, (optional), a small string used to differentiate log messages (required by logging API)
' @serverTypeName: string, (semi optional - required for sending log to server), a string that must exist in one of the server types in logConsts, (required by logging API)
Function tubiLog(message="" as String, level="debug" as String, serverTypeName="" as String, subtype="" as String) as Void
  if level <> "error" and level <> "info" and level <> "warn"
    level = "debug"
  end if

  if message <> ""
    if serverTypeName = ""
      'if we can't send this to the server anyways, no need to involve the trackingLogging task, so just print to the console
      print tubiLog_getLogPrintout_(level, subtype, message)

    else if m.global <> invalid and  m.global.trackingLoggingTask <> invalid
      m.global.trackingLoggingTask.logMsg = {
        message: message
        serverTypeName: serverTypeName
        subtype: subtype
        level: level
      }
    
    else
      'if the trackingLoggingTask is not ready, just print to the console
      print tubiLog_getLogPrintout_(level, subtype, message)
    end if
  end if
End Function


''''''''''''''''''''
' testLog
'
' Logging specifically targeted at automated tests.  These log
' statements should not be reformatted without also changing
' the black box tests which rely upon them.
Function testLog(what as String) as Void
  print "TEST: " + what
End Function



'--------------------------------------------------------------------------------
'--------------------------------------------------------------------------------
'the following 4 functions can be used with just a message in case of only wanting to log to the console
'however, anything worthy of warn or error severity should be sent to the server (ie. fill all the parameters for warn and error)

'debug will only send logging to the server if the device id is in m.idsToLog
function tubiLog_debug(message="" as String, serverTypeName="" as String, subtype="" as String, queue=invalid as Object)
  logInfo = m.buildLogInfo(message, m.logConsts.debug.serverType[serverTypeName], subtype, m.logConsts.debug.name)
  m.sendLogging(logInfo, queue)
end function


function tubiLog_info(message="" as String, serverTypeName="" as String, subtype="" as String, queue=invalid as Object)
  logInfo = m.buildLogInfo(message, m.logConsts.info.serverType[serverTypeName], subtype, m.logConsts.info.name)
  m.sendLogging(logInfo, queue)  
end function


function tubiLog_error(message="" as String, serverTypeName="" as String, subtype="" as String, queue=invalid as Object)
  logInfo = m.buildLogInfo(message, m.logConsts.error.serverType[serverTypeName], subtype, m.logConsts.error.name)
  m.sendLogging(logInfo, queue)  
end function


function tubiLog_warn(message="" as String, serverTypeName="" as String, subtype="" as String, queue=invalid as Object)
  logInfo = m.buildLogInfo(message, m.logConsts.warn.serverType[serverTypeName], subtype, m.logConsts.warn.name)
  m.sendLogging(logInfo, queue)  
end function

'--------------------------------------------------------------------------------
'--------------------------------------------------------------------------------



function tubiLog_buildLogInfo_(message as String, serverType as Dynamic, subtype as String, level as String)
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
end function


'sends the logging info to the server by creating a logging request and adding the loggging request to the passed in request queue
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
function tubiLog_sendLogging_(logInfo as Object, queue as Object)
  if logInfo <> invalid and logInfo.count() > 0
    'print all log messages to console
    if logInfo.message <> ""
      print m.getLogPrintout(logInfo.level, logInfo.subtype, logInfo.message)

      if logInfo["type"] <> invalid and logInfo.level <> "" and logInfo.subtype <> "" and queue <> invalid
        'don't send debug or info statements unless the user id is in m.constants.idsToLog
        if m.constants.idsToLog.DoesExist(m.constants.deviceInfo.deviceId) or logInfo.level = m.logConsts.warn.name or logInfo.level = m.logConsts.error.name or logInfo.level = m.logConsts.info.name
          loggingRequest = m.getLoggingRequest(logInfo)
          return queue.pushRequest(loggingRequest)
        end if 
      end if
    end if
  end if
  return invalid
end function


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
  if m.auth.getAuthInfo() <> invalid and m.auth.getAuthInfo().userId <> invalid
    loggingReqBody["user_id"] = m.auth.getAuthInfo().userId.ToInt()
  end if

  reqOptions = {
    body: FormatJson(loggingReqBody)
    method: m.constants.reqTypes.post
    retries: 0
  }
  url = m.constants.urls.datascience.logging

  loggingRequest = m.request.createAsync(url, "scenegraphLog " + logInfo.level, reqOptions)
  
  return loggingRequest
End Function


'Builds the full log string that will be printed to the console
'@level: string, (optional), a log level, one of "debug", "info", "warn", or "error"
'@subtype: string, (optional), a small string used to differentiate log messages
'@message: string, the message to be logged
Function tubiLog_getLogPrintout_(level="" as String, subtype="" as String, message="" as String)
  printLevel = {
    debug: "DEBUG"
    error: "ERROR"
    info: "INFO"
    warn: "WARN"
  }
  
  printout = "LOG "

  if level <> "" and printLevel[level] <> invalid
    printout = printout + printLevel[level] + " "
  end if

  if subtype <> ""
    printout = printout + "(" + subtype + ") "
  end if

  if message <> ""
    printout = printout + ": " + message
  end if

  return printout
End Function


