' Adrise:ott-roku project DSN: https://f8edcfe8baf140b4b91b46dfb8af9a19:acdf43f7c38a47f1ab85583035ff1798@sentry.io/1377102

' Atrributes documented at https://docs.sentry.io/development/sdk-dev/attributes/
'
'
' This should *roughly* follow guidance at https://docs.sentry.io/development/sdk-dev/unified-api/,
' but seeing as this is not public, we can omit huge chunks of features there.
'
' For clean architecture, there shouldn't be reference to m.global or external
' stores for various values in here.  Anything specific to the app and its
' context values should be passed into the contructor.
'
'


''''''''''''''''''''''
' constructor
'
' @attributes: Single-level assocarray with attributes defined by Sentry
' @context: nested assocarray with context interfaces defined by Sentry
Function Sentry(dsn, attributes=invalid, context=invalid)

  di = CreateObject("roDeviceInfo")

  ' default constants for contexts
  defaultEvent = {
    ' required attributes
    "event_id": ""
    "timestamp": ""
    "platform": "other"   ' must be one of Sentry's enum values
    "sdk": {
      "name": "roku"
      "version": "1.0"  ' arbitrary, but required.  match it to the sentry_client value in auth header
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

  if type(dsn) = "String" or type(dsn) = "roString"
    dsn = sentry_parseDsn(dsn)
  else
    dsn = sentry_parseDsn("")
  end if
  print "Sentry client initialized with DSN: "; dsn

  return {
    ' public
    captureMessage: sentry_captureMessage

    ' private
    _dsn: dsn
    _SEVERITIES: sentry_severities()
    _getUrl: sentry_getUrl
    _parseDsn: sentry_parseDsn
    _sendEvent: sentry_sendEvent
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
    "protocol":  result[1]
    "publicKey": result[2]
    "secretKey": result[3]
    "host":      result[4]
    "port":      result[5]
    "project":   result[6]
  }
End Function

''''''''''''''''''
' getUrl
'
Function sentry_getUrl()
  url = m._dsn.protocol + "://" + m._dsn.host
  if m._dsn.port <> invalid and m._dsn.port <> ""
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
    "fatal":    "fatal"
    "error":    "error"
    "warning":  "warning"
    "log":      "log"
    "info":     "info"
    "debug":    "debug"
    "critical": "critical"
  }
End Function


''''''''''''''''''
' captureMessage
'
' @message - String or Assocarray with a field 'message'.  If assocarray, all
'            other fields will be captured as extra info.
Function sentry_captureMessage(message, level="info") as Void
  if type(message) <> "roString" and type(message) <> "String" and type(message) <> "roAssociativeArray"
    return
  end if

  ' Default to Info
  if type(level) <> "roString" and type(level) <> "String"
    level = m._SEVERITIES.info
  else if m._SEVERITIES.DoesExist(LCase(level)) = false
    level = m._SEVERITIES.info
  end if

  ' Create a new cloned object
  event = {}
  sentry_deepAppend(event, m._defaultEvent)
  event["event_id"] = m._generateEventId()
  event["timestamp"] = CreateObject("roDateTime").ToISOString()
  event["level"] = LCase(level)

  if type(message) = "roAssociativeArray"
    event["message"] = message["message"]
    extra = {}
    extra.append(message)
    extra.delete("message")
    event["extra"] = extra
  else
    event["message"] = message
  end if

  m._sendEvent(event)
End Function


''''''''''''''''''
' sendEvent
'
Function sentry_sendEvent(event)

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

  url = m._getUrl()

  port = CreateObject("roMessagePort")
  urltransfer = CreateObject("roURLTransfer")
  urltransfer.SetPort(port)
  urltransfer.SetUrl(url)
  urltransfer.SetRequest("POST")
  urltransfer.EnableEncodings(true)
  urltransfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
  urltransfer.SetHeaders({
    "Content-type": "application/json"
    "X-Sentry-Auth": authString
  })
  urltransfer.RetainBodyOnError(true)
  body = FormatJson(event)
  urltransfer.AsyncPostFromString(body)
  wait(0, port)
End Function


''''''''''''''''''
' generateEventId
'
' Genearate a Sentry-compliant id: UUID with hyphens removed
Function sentry_generateEventId()
  uuid = Box(CreateObject("roDeviceInfo").GetRandomUUID())
  shortuuid = uuid.Replace("-","")
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
  if type(a) <> "roAssociativeArray" or type(b) <> "roAssociativeArray"
    return a
  end if

  for each key in b
    if a.DoesExist(key) and type(a[key]) = "roAssociativeArray" and type(b[key]) = "roAssociativeArray"
      sentry_deepAppend(a[key], b[key])
    else
      ' if not an assocarray, we overwrite a's entry with b's value
      a[key] = b[key]
    end if
  end for
  return a
End Function
