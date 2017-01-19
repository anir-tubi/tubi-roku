function AdriseLogging (utils)
  return {
    utils: utils
    idsToLog: {}

    logConsts: {
      debug: {
        name: "debug"
        printed: "DEBUG"
        server: "CLIENT:DEBUG"
      }
      error: {
        name: "error"
        printed: "ERROR"
        server: "CLIENT:ERROR"
      }
      info: {
        name: "info"
        printed: "INFO"
        server: "CLIENT:INFO"
      }
      warn: {
        name: "warn"
        printed: "WARN"
        server: "CLIENT:WARN"
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
function adriseLogging_debug(port, subtype as string, message as string)
  options = m.buildOptions(subtype, message, m.logConsts.debug.name, m.logConsts.debug.server, m.logConsts.debug.printed)
  m.sendLogging(port, options)
end function


function adriseLogging_error(port, subtype, message)
  options = m.buildOptions(subtype, message,m.logConsts.error.name, m.logConsts.error.server, m.logConsts.error.printed)
  m.sendLogging(port, options)  
end function


function adriseLogging_info(port, subtype, message)
  options = m.buildOptions(subtype, message, m.logConsts.info.name, m.logConsts.info.server, m.logConsts.info.printed)
  m.sendLogging(port, options)  
end function


function adriseLogging_warn(port, subtype, message)
  options = m.buildOptions(subtype, message, m.logConsts.warn.name, m.logConsts.warn.server, m.logConsts.warn.printed)
  m.sendLogging(port, options)  
end function


function adriseLogging_buildOptions(subtype, message, level, serverType, printed)
  options = {
    level: level
    subtype: subtype
    message: message
    printed: printed
  }
  options["type"] = serverType

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

