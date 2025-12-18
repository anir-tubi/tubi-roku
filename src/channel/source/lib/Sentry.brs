' Adrise:ott-roku project DSN: https://f8edcfe8baf140b4b91b46dfb8af9a19:acdf43f7c38a47f1ab85583035ff1798@sentry.io/1377102

' Attributes documented at https://docs.sentry.io/development/sdk-dev/attributes/
'
' https://develop.sentry.dev/sdk/
'
' This should *roughly* follow guidance at https://docs.sentry.io/development/sdk-dev/unified-api/,
' but seeing as this is not public, we can omit huge chunks of features there.
'
' For clean architecture, there shouldn't be reference to m.global or external
' stores for various values in here.  Anything specific to the app and its
' context values should be passed into the constructor.
'
'


''''''''''''''''''''''
' constructor
'
' @attributes: Single-level assocarray with attributes defined by Sentry
' @auth: assocArray, an instance of the auth module as returned by TubiAuth()
Function Sentry(constants, auth)

  if constants.thirdParty.sentry = invalid
    return invalid
  end if

  dsn = constants.thirdParty.sentry.dsn
  environment = "staging"
  if constants.settings.mode = "production"
    environment = "production"
  end if

  ' sentry for remote error logging
  sentryAttributes = {
    "release": constants.deviceInfo.clientVersion
    "environment": environment
  }
  sentryContext = {
    "app": {
      "app_name": constants.appName
      "device_app_hash": constants.deviceInfo.deviceId
      "app_version": constants.deviceInfo.clientVersion
    }
  }
  if auth.getAuthInfo() <> invalid AND auth.getAuthInfo().userId <> invalid
    sentryContext["user"] = {}
    sentryContext["user"]["id"] = auth.getAuthInfo().userId.toStr()
  end if

  return initSentry(dsn, sentryAttributes, sentryContext)

End Function


' @dsn: string, sentry url
' @attributes: Single-level assocarray with attributes defined by Sentry
' @context: nested assocarray with context interfaces defined by Sentry
Function initSentry(dsn, attributes = invalid, context = invalid)

  di = CreateObject("roDeviceInfo")

  ' default constants for contexts
  defaultEvent = {
    ' required attributes
    "event_id": ""
    "timestamp": ""
    "platform": "other" ' must be one of Sentry's enum values
    "sdk": {
      "name": "roku"
      "version": "1.0" ' arbitrary, but required.  match it to the sentry_client value in auth header
    }
    "contexts": {
      "device": {
        "type": "device"
        "model": di.GetModel()
        "model_id": di.GetModelDisplayName()
        "timezone": di.GetTimeZone()
        "family": di.GetModelType()
      }
      "os": {
        "type": "os"
        "name": "roku"
        "version": di.GetOSVersion().major + "." + di.GetOSVersion().minor
      }
      "app": {
        "type": "app"
        "app_name": "" ' m.constants.appName
        "device_app_hash": "" ' m.constants.deviceInfo.deviceId
        "app_version": "" 'm.constants.deviceInfo.clientVersion
      }
    }
  }

  if type(attributes) = "roAssociativeArray"
    sentry_deepAppend(defaultEvent, attributes)
  end if
  if type(context) = "roAssociativeArray"
    sentry_deepAppend(defaultEvent.contexts, context)
  end if

  if type(dsn) = "String" OR type(dsn) = "roString"
    dsn = sentry_parseDsn(dsn)
  else
    dsn = sentry_parseDsn("")
  end if
  ' print "Sentry client initialized with DSN: "; dsn

  return {
    ' public
    getReqInfo: sentry_getReqInfo

    ' private
    _dsn: dsn
    _SEVERITIES: sentry_severities()
    _parseDsn: sentry_parseDsn
    _getHeader: sentry_getHeader
    _getUrl: sentry_getUrl
    _generateEventId: sentry_generateEventId
    _defaultEvent: defaultEvent
  }
End Function


''''''''''''''''''
' parseDsn
'
Function sentry_parseDsn(dsnString)
  ' See:
  '   https://docs.sentry.io/development/sdk-dev/overview/#parsing-the-dsn
  '   https://github.com/getsentry/sentry-javascript/blob/master/packages/core/src/dsn.ts#L7
  '

  regex = CreateObject("roRegex", "^(?:(\w+):)\/\/(?:(\w+)(?::(\w+))?@)([\w\.-]+)(?::(\d+))?\/(.+)", "i")
  result = regex.match(dsnString)
  if result.count() = 0
    print "ERROR: Failed to parse Sentry DSN"
  end if
  return {
    "protocol": result[1]
    "publicKey": result[2]
    "secretKey": result[3]
    "host": result[4]
    "port": result[5]
    "project": result[6]
  }
End Function


''''''''''''''''''
' getUrl
'
Function sentry_getUrl()
  url = m._dsn.protocol + "://" + m._dsn.host
  if m._dsn.port <> invalid AND m._dsn.port <> ""
    url += ":" + m._dsn.port
  end if
  url += "/api/" + m._dsn.project + "/store/"
  return url
End Function


''''''''''''''''''
' severities
'
Function sentry_severities()
  return {
    "fatal": "fatal"
    "error": "error"
    "warning": "warning"
    "log": "log"
    "info": "info"
    "debug": "debug"
    "critical": "critical"
  }
End Function


''''''''''''''''''
' getReqInfo
'
' @message - String or Assocarray with a field 'message'.  If assocarray, all
'            other fields will be captured as extra info.
'   example of fields inside message assocarray.
'     {
'        body: "{"content_id":"713116","content_type":"movie","type":"watch_later"}"
'        code: 404
'        failreason: "The requested URL returned error: 404"
'        headers: <Component: roAssociativeArray>
'        method: "POST"
'        name: "postToQueue"
'        type: "Api Error"
'        url: "https://user-queue.production-public.tubi.io/api/v3/queues"
'     }
'
' @level - string (optional), possible log levels are "debug", "info", "warn", or "error"
Function sentry_getReqInfo(message = "" as Dynamic, level = "info" as String) as Object
  if type(message) <> "roString" AND type(message) <> "String" AND type(message) <> "roAssociativeArray"
    return invalid
  end if

  ' Default to Info
  if type(level) <> "roString" AND type(level) <> "String"
    level = m._SEVERITIES.info
  else if m._SEVERITIES.DoesExist(LCase(level)) = false
    level = m._SEVERITIES.info
  end if

  ' Create a new cloned object
  event = {}
  sentry_deepAppend(event, m._defaultEvent)
  event["event_id"] = m._generateEventId()
  event["level"] = LCase(level)

  errorType = "Error"
  name = ""
  if type(message) = "roAssociativeArray"
    errorType = message.type
    name = message.name
    extra = {}
    extra.append(message)
    'removing name & type from additional info as it is present on heading/sub-heading
    extra.delete("name")
    extra.delete("type")
    ' extra values will be shown in additional info in sentry dashboard
    event["extra"] = extra

    if message.timestamp <> invalid then
      event["timestamp"] = message.timestamp
    end if
  else
    errorType = message
    name = message
    event["message"] = message
  end if

  if event["timestamp"] = invalid then
    event["timestamp"] = CreateObject("roDateTime").toISOString()
  end if

  if errorType = invalid OR errorType = ""
    errorType = "Error"
  end if

  values = {}
  values["type"] = errorType
  values["value"] = name
  event["exception"] = {
    "values": [values]
  }

  reqOptions = {
    body: FormatJson(event)
    method: "POST"
    headers: m._getHeader()
  }

  reqInfo = {
    url: m._getUrl()
    reqOptions: reqOptions
  }

  return reqInfo

End Function


''''''''''''''''''
' getHeader
'
Function sentry_getHeader()

  ' https://docs.sentry.io/development/sdk-dev/overview/#authentication
  auth = {
    "sentry_key": m._dsn.publicKey
    "sentry_version": "7"
    "sentry_client": "roku/1.0"
    "sentry_timestamp": CreateObject("roDateTime").AsSeconds().toStr()
    "sentry_secret": m._dsn.secretKey
  }
  authValues = []
  for each key in auth
    ' If m._dsn didn't have any of these values then omit them
    if auth[key] <> invalid
      authValues.push(key + "=" + auth[key].toStr())
    end if
  end for
  authString = "Sentry " + authValues.join(", ")

  header = {
    "Content-type": "application/json"
    "X-Sentry-Auth": authString
  }

  return header
End Function


''''''''''''''''''
' generateEventId
'
' Genearate a Sentry-compliant id: UUID with hyphens removed
Function sentry_generateEventId()
  uuid = Box(CreateObject("roDeviceInfo").GetRandomUUID())
  shortuuid = uuid.Replace("-", "")
  return shortuuid
End Function


''''''''''''''''''
' deepAppend
'
' Quick-n-dirty nested version of ifAssociativeArray.Append(). Recurses
' nested AssociativeArrays but treats other Objects (e.g. Arrays) same
' as simple types.
'
' Invoked as a static method, no references to 'm' here.
' DESTRUCTIVE: this modifies a
Function sentry_deepAppend(a, b)
  if type(a) <> "roAssociativeArray" OR type(b) <> "roAssociativeArray"
    return a
  end if

  for each key in b
    if a.DoesExist(key) AND type(a[key]) = "roAssociativeArray" AND type(b[key]) = "roAssociativeArray"
      sentry_deepAppend(a[key], b[key])
    else
      ' if not an assocarray, we overwrite a's entry with b's value
      a[key] = b[key]
    end if
  end for
  return a
End Function
