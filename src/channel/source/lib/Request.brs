Function TubiRequest(settings = {mode: "production",CharlesProxyEnabled: false })
  return {
    configMode: settings.mode
    charlesProxyEnabled: settings.charlesProxyEnabled
    charlesProxyUrl:settings.charlesProxyUrl
    createAsync: createAsyncHTTPRequest
    start: tubihttp_start
    handleEvent: tubihttp_handleEvent
    hasData: tubihttp_hasData
    runSynchronous: tubihttp_runSynchronous
    cancel: tubihttp_cancel
    isHttps: tubihttp_isHttps_
    addParamsToUrl: tubihttp_addParamsToUrl_
    getLocale: tubihttp_getLocale_ 
    passThroughCharlesProxy: tubihttp_passThroughCharlesProxy 
    removeCharlesProxy: tubihttp_removeCharlesProxy

  }
End Function



''''''''''''''''''''''''
' createAsyncHTTPRequest() - helper to create an async request
'
' url - The URL (with or without query params) to request
' name (optional) - a human readable name for the request, to track in logs
' options (optional) - options to tune the behavior of the request
'         valid Options:
'               method - HTTP method as string: GET, PUT, POST, PATCH, DELETE, or OPTIONS
'               params - assoc array of URL query params
'               body - PUT or POST body as string
'               headers - assoc array of headers and their values
'
Function createAsyncHTTPRequest(url as String, name = "" as String, options={} as Object) as Object
  deviceInfo = CreateObject("roDeviceInfo")

  ' sanitize
  validRequestTypes = {
    POST: true
    GET: true
    DELETE: true
    PUT: true
    PATCH: true
    OPTIONS: true
  }
  mergedOptions = {
    method: "GET"
    params: {}
    body: ""
    headers: {}
    retries: 3
  }

  for each o in mergedOptions
    if options[o] <> invalid then mergedOptions[o] = options[o]
    if o = "method" then
      mergedOptions.method = UCase(mergedOptions.method)
      if validRequestTypes.DoesExist(mergedOptions.method) = false then
        mergedOptions.method = "GET"
      end if
    end if
    if o = "headers"
      if mergedOptions[o].DoesExist("Content-Type") = false
        if options.method <> invalid
          if UCase(options.method) = "POST" or UCase(options.method) = "PUT" or UCase(options.method) = "PATCH"
            mergedOptions[o].Append({"Content-Type": "application/json"})
          end if
        end if
      end if
      if mergedOptions[o].DoesExist("Accept-Language") = false
        mergedOptions[o].Append({"Accept-Language": m.getLocale()})
      end if
    end if
    
  end for

  o = {
    ' public
    isHttps: m.isHttps(url) ' boolean, not member function
    url: m.passThroughCharlesProxy(url)
    start: m.start
    handleEvent: m.handleEvent
    hasData: m.hasData
    runSynchronous: m.runSynchronous
    cancel: m.cancel
    name: name  ' human-friendly name for the request
    response: invalid
    uuid: deviceInfo.GetRandomUUID()  ' since this object is not 1-to-1 with roUrlTransfer
                                      ' instance, we create our own unique id, helpful for
                                      ' cancellations

    ' private
    addParamsToUrl_: m.addParamsToUrl
    urltransfer: invalid
    klass: "TubiAsyncHTTPRequest"   ' Just a sentinel for verification by Request Queue
    configMode: m.configMode
    charlesProxyEnabled: m.charlesProxyEnabled
    charlesProxyUrl: m.charlesProxyUrl
    passThroughCharlesProxy: m.passThroughCharlesProxy
  }
  o.Append(mergedOptions)
  return o
End Function


'''''''''''''''''''''''
' start - Prep the roUrlTransfer object and initiate the request
'
' urltransfer_or_messageport - a roUrlTransfer or roMessagePort object; 
'
'     If roUrlTransfer is passed, the object is used to execute the request and events
'     send to the roMessagePort already associated with the roUrlTransfer object.
'
'     If roMessagePort is passed, a roUrlTransfer object is allocated and 
'     events will be sent to the roMessagePort provided.
'
Function tubihttp_start(urltransfer_or_messageport As Object) As Boolean
  isRetry = false
  if m.urltransfer <> invalid
    isRetry = true
  end if

  if type(urltransfer_or_messageport) = "roUrlTransfer" then
    ' use default assigned port
    m.urltransfer = urltransfer_or_messageport
  else if type(urltransfer_or_messageport) = "roMessagePort" then
    m.urltransfer = CreateObject("roURLTransfer")
    m.urltransfer.SetPort(urltransfer_or_messageport)
  else
    return false
  end if

  if m.params.Count() > 0  and isRetry = false then
    fullUrl = m.addParamsToUrl_(m.url, m.params) 
    fulProxyUrl = m.passThroughCharlesProxy(fullUrl)
    m.urltransfer.SetUrl(fulProxyUrl)  
    m.url = fulProxyUrl
  else
    m.urltransfer.SetUrl(m.url)
  end if

  m.urltransfer.EnableEncodings(true)
  if m.isHttps then
    m.urltransfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
  end if

  m.urltransfer.setHeaders(m.headers)
  m.urltransfer.setRequest(m.method)

  ' print output for qa to test
  if m.configMode = "qa" or m.configMode = "staging" 
    tubiLog("sending a " + m.method + " request to " + m.url)  
    print m.body
  end if

  if (m.configMode <> "production") and m.charlesProxyEnabled
    m.urltransfer.enablePeerVerification(false)
    m.urltransfer.enableHostVerification(false)
  end if

  ' Start the request
  if m.method = "POST" or m.method = "PUT" or m.method = "PATCH"
    if m.urltransfer.AsyncPostFromString(m.body) = false
      tubiLog(m.method + " request failed. " + url)
      return false
    end if
  else
    if m.urltransfer.AsyncGetToString() = false
      tubiLog(m.method + " request failed. " + url)
      return false
    end if
  end if

  return true
End Function


'''''''''''''''''''''''
' runSynchronous - starts, waits for, and handles the response for a synchronous style request
'   @timeout: integer, the max amount of time to wait for a response
'
' returns just the data of the response, not the code or fail reason
'
Function tubihttp_runSynchronous(timeout = 5 as Integer) As Object
  timer = CreateObject("roTimespan")
  res = invalid
  msgPort = CreateObject("roMessagePort")

  'prevent m.start() from running if we've already made the request previously
  didStart = false
  if m.urltransfer = invalid
    didStart = m.start(msgPort)
  end if

  if didStart = true
    while true
      msg = wait(100, msgPort)
      request = m.handleEvent(msg)

      if request <> invalid
        if request.response <> invalid and request.response.data <> invalid and request.response.data.len() > 0
          res = request.response.data
          exit while
        else if request.response.code < 200 or request.response.code >= 400
          exit while
        end if
      end if

      if timer.totalMilliseconds() > (timeout * 1000)
        exit while
      end if
    end while
  end if

  return res
End Function



'''''''''''''''''''''''
' handleEvent - ingest a received message.  If the message is not
'               relevant to this request, return invalid.  If there is a
'               response available, it is returned. Requests will be
'               retried on failures.
'
' message - the roUrlEvent received on the caller's roMessagePort
'
Function tubihttp_handleEvent(message As Object) As Object
  ' perhaps .start() was not called yet
  if m.urltransfer = invalid
    return invalid
  end if
    
  ' handle retries
  if type(message) = "roUrlEvent" then
    if message.GetSourceIdentity() = m.urltransfer.GetIdentity() then
      if message.GetInt() = 1 then 
        ' 1. Check success or failure?
        code = message.GetResponseCode()

        'server said our auth token was not valid
        if m.authInfo <> invalid and code = 403 and m.retries > 0
          newAuthInfo = m.refreshAuthToken(m.authInfo, 100)
          if newAuthInfo <> invalid
            'replace any necessary new auth info in the headers and try again
            authHeaders = m.getAuthHeaders(newAuthInfo.accessToken)
            
            if authHeaders <> invalid
              for each header in authHeaders
                m.headers[header] = authHeaders[header]
              end for
              
              m.retries = m.retries - 1
              m.start(m.urltransfer)
            end if

          else  ' refreshing the auth token failed so just attach the response info and finish
            m.response = {
              headers: message.GetResponseHeaders()
              code: code
              data: message.GetString()
              failReason: message.GetFailureReason()
            }
            m.urltransfer = invalid ' release reference in case this will be reused
            return m
          end if

        else if code < 0 and m.retries > 0 then
          m.retries = m.retries - 1    
          m.start(m.urltransfer) ' fire off the request again
        else
          ' Here on success or on retry limit
          m.response = {
            headers: message.GetResponseHeaders()
            code: code
            data: message.GetString()
            failReason: message.GetFailureReason()
            name: m.name
          }

          ' print response info for qa team
          if (m.configMode = "qa" or m.configMode = "staging")
            if Left(m.name, 5) = "track"
              print "received "; code; " for "; m.name
              print m.response.data
            end if
          end if

          m.urltransfer = invalid ' release reference in case this will be reused
          return m
        end if
      else
        ' only 1 is valid?  Here for future-proofing
      end if
    else
      ' some other request is served by the same message port?  Ignore it
    end if
  else
    ' ignore other types of events, so this can be used idempotently in a caller's message loop
  end if

  return invalid
End Function


'''''''''''''''''''''''
' hasData
'
' small helper to check if the request has returned data and can be acted on
Function tubihttp_hasData() as Boolean
  if m.response <> invalid and m.response.data <> invalid and m.response.data.len() > 0
    return true
  end if

  return false
End Function


'''''''''''''''''''''''
' cancel
'
Function tubihttp_cancel()
  if m.urltransfer <> invalid then
    m.urltransfer.AsyncCancel()
    m.urltransfer = invalid
  end if
End Function

'''''''''''''''''''''''
' isHttps
'
'Check if url is "https" prefixed
Function tubihttp_isHttps_(url As String)
  if Left(UCase(url), 5) = "HTTPS" then
    return true
  else
    return false
  end if
End Function


'''''''''''''''''''''''
' tubihttp_getLocale_ - helper function to get the device locale that we should send to the server
'
Function tubihttp_getLocale_() as String
  di = CreateObject("roDeviceInfo")
  locale = di.GetCurrentLocale()
  if locale <> invalid 
    locale = locale.replace("_", "-")
  else
    locale = "en-US"
  end if
  return locale
End Function

'''''''''''''''''''''''
' addParamsToUrl - helper function to construct the full url
'
' NOTE: Don't use 'm' references in here so that we can use it as a module function
Function tubihttp_addParamsToUrl_(url As String, params As Object) As String
  if params = invalid or params.Count() = 0 then return url

  ' allow a dangling '?' or '&' in the base url, e.g. "http://something.net/?"
  '         Example                  Case
  '             ...net                2
  '             ...net/               2
  '             ...net/?              1
  '             ...net/?x             3
  '             ...net/?x=            3
  '             ...net/?x=&           1
  '             ...net/?x=1           3
  '             ...net/?x=1&          1
  if url.Right(1) = "&" or url.Right(1) = "?" then
    separator = ""
  else if url.Instr("?") = -1
    separator = "?"
  else
    separator = "&"
  end if

  for each p in params
    key = p.toStr().trim()

    ' Normalize all params to an array for simpler handling
    if type(params[p]) = "roArray"
      key = key + "[]"
      values = params[p]
    else
      values = [params[p]]
    end if

    for each value in values
      if value = invalid then 
        value = ""  ' don't send any string literal "invalid"
      end if
      value = value.toStr().trim()
      url = url + separator + key.EncodeUriComponent() + "=" + value.EncodeUriComponent()
      separator = "&"
    end for
  end for

  return url
End Function

Function tubihttp_passThroughCharlesProxy(url as String) as string
  proxyedurl = url
  if m.charlesProxyEnabled
    if m.configMode <> "production" and m.charlesProxyUrl <> ""
      reg_exp = CreateObject("roRegex", "^(http|https)://", "")
      checkurlAA = reg_exp.Split(url)
      if checkurlAA[1] <> invalid and Len(checkurlAA[1]) > 0 and url.instr(m.charlesProxyUrl) = -1
        proxyedurl = m.charlesProxyUrl + "/;;" + url
      end if
    end if
  end if
  return proxyedurl
End Function


Function tubihttp_removeCharlesProxy(proxyedurl as String) as String
  returnUrl = proxyedurl
  if m.charlesProxyEnabled
    if m.configMode <> "production" and proxyedurl <> "" and m.charlesProxyUrl <> ""
      proxyAddress = m.charlesProxyUrl + "/;;"
      returnUrl = proxyedurl.Replace(proxyAddress, "")
    end if
  end if
  return returnUrl
End Function


