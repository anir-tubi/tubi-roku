function AdriseLogging (utils)
  return {
    utils: utils
    idsToLog: {}

    logConsts: {
      debug: {
        name: "debug"
        printed: "DEBUG"
        logType: {
          clientDebug: "CLIENT:DEBUG"
          apiDebug: "API:DEBUG"
          videoDebug: "VIDEO:DEBUG"
          adDebug: "AD:DEBUG"
        }
      }

      error: {
        name: "error"
        printed: "ERROR"
        logType: {
          apiError: "API:ERROR"
          apiBad: "API:BAD_RESPONSE"
          videoPlayback: "VIDEO:PLAYBACK"
          videoLoad: "VIDEO:LOAD"
          adError: "AD:ERROR"
        }
      }

      info: {
        name: "info"
        printed: "INFO"
        logType: {
          clientInfo: "CLIENT:INFO"
          apiInfo: "API:INFO"
          videoInfo: "VIDEO:INFO"
          adInfo: "AD:INFO"
        }
      }

      warn: {
        name: "warn"
        printed: "WARN"
        logType: {
          apiSlow: "API:SLOW"
          apiTimeout: "API:TIMEOUT"
          adTimeout: "AD:TIMEOUT"
          adBadResponse: "AD:BAD_RESPONSE"
          videoBuffer: "VIDEO:BUFFER"
          clientWarn: "CLIENT:WARN"
        }
      }
    } 

    sendLogging: adriseLogging_sendLogging
    buildOptions: adriseLogging_buildOptions
    debug: adriseLogging_debug
    error: adriseLogging_error
    info: adriseLogging_info
    warn: adriseLogging_warn
  }
end function


'debug is used to track a specific user's device
'debug will only send logging if the device id is in m.idsToLog
function adriseLogging_debug(port, logType as string, subtype as string, message as string)
  options = m.buildOptions(subtype, message, m.logConsts.debug.name, m.logConsts.debug.logType[logType], m.logConsts.debug.printed)
  m.sendLogging(port, options)
end function


function adriseLogging_error(port, logType, subtype, message)
  options = m.buildOptions(subtype, message,m.logConsts.error.name, m.logConsts.error.logType[logType], m.logConsts.error.printed)
  m.sendLogging(port, options)  
end function


function adriseLogging_info(port, logType, subtype, message)
  options = m.buildOptions(subtype, message, m.logConsts.info.name, m.logConsts.info.logType[logType], m.logConsts.info.printed)
  m.sendLogging(port, options)  
end function


function adriseLogging_warn(port, logType, subtype, message)
  options = m.buildOptions(subtype, message, m.logConsts.warn.name, m.logConsts.warn.logType[logType], m.logConsts.warn.printed)
  m.sendLogging(port, options)  
end function


function adriseLogging_buildOptions(subtype, message, level, logType, printed)
  options = {
    level: level
    subtype: subtype
    message: message
    printed: printed
  }
  options["type"] = logType

  return options
end function


'sends the logging info to the server
'@port: roMessagePort
'@options: roAssociatedArray ie.
'  options = {
'    level: "error"
'    subtype: "video-failure"
'    message: "Video with id: 1234 failed to play"
'    type: "CLIENT:ERROR"
'  }
function adriseLogging_sendLogging(port, options)
  settings = m.utils.getSettings()


  if options <> invalid and options.count() > 0
    'print all log messages to console if we are in dev mode only
    if settings.mode = "dev" and options.message <> invalid and options.subtype <> invalid
      print "LOG " + options.printed + " (" + options.subtype + ") : " options.message

    'don't send debug statements unless the user id is in m.idsToLog
    else if type(port) = "roMessagePort" and options.level <> invalid and (m.idsToLog.DoesExist(m.utils.deviceInfo.deviceId) or options.level = m.logConsts.warn.name or options.level = m.logConsts.error.name)
      loggingInfo = {
        app_id: settings.shortAppName
        platform: "roku"
        device_id: m.utils.deviceInfo.deviceId
        ua: m.utils.deviceInfo.userAgentPlusModel
        version: m.utils.deviceInfo.clientVersion
      }

      options.delete("printed")
      loggingInfo.append(options)

      loggingInfo["user_id"] = 0
      if m.utils.getAuthInfo() <> invalid and m.utils.getAuthInfo().userId <> invalid
        loggingInfo["user_id"] = m.utils.getAuthInfo().userId
      end if

      url = settings.loggingUrl
      loggingJson = FormatJson(loggingInfo)

      'url as String, port, name = "" as String, reqType = invalid, isHttps = false, body = invalid, headers = invalid
      loggingId = m.utils.sendAsyncRequest(url, port, "sendLogging", "POST", true, loggingJson, invalid)
    end if
  end if
end function

