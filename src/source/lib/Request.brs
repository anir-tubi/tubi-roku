Function TubiRequest()
  return {
    createAsync: createAsyncHTTPRequest
    start: tubihttp_start
    handleEvent: tubihttp_handleEvent
    runSynchronous: tubihttp_runSynchronous
    cancel: tubihttp_cancel
    isHttps: tubihttp_isHttps_
    addParamsToUrl: tubihttp_addParamsToUrl_
  }
End Function





''''''''''''''''''''''''
' createAsyncHTTPRequest() - helper to create an async request
'
' url - The URL (with or without query params) to request
' name (optional) - a human readable name for the request, to track in logs
' options (optional) - options to tune the behavior of the request
'         valid Options:
'               method - HTTP method as string: GET, PUT, POST, PATCH, or DELETE
'               params - assoc array of URL query params
'               body - PUT or POST body as string
'               headers - assoc array of headers and their values
'
Function createAsyncHTTPRequest(url as String, name = "" as String, options={} as Object) as Object

  ' sanitize
  validRequestTypes = {
    POST: true
    GET: true
    DELETE: true
    PUT: true
    PATCH: true
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
        method = "GET"
      end if
    end if
  end for

  o = {
    ' public
    isHttps: m.isHttps(url) ' boolean, not member function
    url: url
    start: m.start
    handleEvent: m.handleEvent
    runSynchronous: m.runSynchronous
    cancel: m.cancel
    name: name  ' human-friendly name for the request
    response: invalid

    ' private
    addParamsToUrl_: m.addParamsToUrl
    urltransfer: invalid
    klass: "TubiAsyncHTTPRequest"   ' Just a sentinel for verification by Request Queue
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

  if type(urltransfer_or_messageport) = "roUrlTransfer" then
    ' use default assigned port
    m.urltransfer = urltransfer_or_messageport
  else if type(urltransfer_or_messageport) = "roMessagePort" then
    m.urltransfer = CreateObject("roURLTransfer")
    m.urltransfer.SetPort(urltransfer_or_messageport)
  else
    return false
  end if

  if m.params.Count() > 0 then
    m.urltransfer.SetUrl(m.addParamsToUrl_(m.url, m.params))
  else
    m.urltransfer.SetUrl(m.url)
  end if

  m.urltransfer.EnableEncodings(true)
  if m.isHttps then
    m.urltransfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
  end if
  for each h in m.headers
    m.urltransfer.addHeader(h, m.headers[h])
  end for
  m.urltransfer.setRequest(m.method)

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
' runSynchronous - starts, waits for, and handles the response for a synchrynous style request
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
      msg = wait(0, msgPort)
      request = m.handleEvent(msg)

      if request <> invalid and request.response <> invalid and request.response.data.len() > 0
        res = request.response.data
        exit while
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
  if m.urltransfer = invalid then 
    return invalid
  end if
    
  ' handle retries
  if type(message) = "roUrlEvent" then
    if message.GetSourceIdentity() = m.urltransfer.GetIdentity() then
      if message.GetInt() = 1 then 
        ' 1. Check success or failure?
        code = message.GetResponseCode()

        'server said our auth token was not valid
        if m.authInfo <> invalid and code = 403
          m.authInfo = m.refreshAuthToken(m.authInfo)

          'replace any necessary new auth info in the headers and try again
          authHeaders = m.getAuthHeaders(m.authInfo.accessToken)
          if authHeaders <> invalid
            for each header in authHeaders
              m.headers[header] = authHeaders[header]
            end for
          end if

          m.retries = m.retries - 1
          m.start(m.urltransfer)

        else if code < 0 and m.retries > 0 then
          m.retries = m.retries - 1    
          m.start(m.urltransfer) ' fire off the request again
        else
          ' Here on success or on retry limit
          m.response = {
            code: code
            data: message.GetString()
            failReason: message.GetFailureReason()
          }
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
' addParamsToUrl - helper function to construct the full url
'
' NOTE: This should only be used AFTER the urltransfer object has been set.
Function tubihttp_addParamsToUrl_(url As String, params As Object) As String
  if params = invalid or params.Count() = 0 then return url

  hasParams = url.Instr("?")
  if hasParams = -1
    url = url + "?"
  end if

  for each p in params
    if url.Right(1) <> "&" and url.Right(1) <> "?" then
      url = url + "&"
    end if
    url = url + m.urltransfer.Escape(tostr(p)) + "=" + m.urltransfer.Escape(tostr(params[p]))
  end for

  return url
End Function

