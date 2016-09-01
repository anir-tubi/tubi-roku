Function init()
  m.top.functionName = "fetchLoop"
End Function


'''''''''''''''''''''''''
' fetchLoop
'
' "main" loop of the task thread, watches for requests on
' the "request" field
'
Function fetchLoop()
  tubiLog("MetadataFetchTask.fetchLoop started")
  m.port = CreateObject("roMessagePort")
  m.queue = TubiRequestQueue().create(m.port)
  m.top.observeField("request", m.port)
  m.constants = m.global.constants   ' this should grab a thread-local copy
  m.timespan = CreateObject("roTimeSpan")
  m.timespan.mark()
  m.epoch = m.timespan.TotalMilliseconds()

  ' Signal that we're ready for requests
  m.top.ready = true

  'when the request field for the metadata task field is updated, the event is heard in this loop
  'and beginRequest() is called
  while true
    msg = wait(0, m.port)
    if type(msg) = "roSGNodeEvent" then
      if msg.GetField() = "request" then
        tubiLog("Received roSGNodeEvent for field " + msg.GetField())
        beginRequest(msg.GetData())
      end if
    else if type(msg) = "roUrlEvent" then
      handleResponse(msg)
    end if
  end while
End Function


'''''''''''''''''''''''''
' beginRequest
'
' process an incoming for metadata
'
Function beginRequest(metadataRequest) As Void
  if metadataRequest.node = invalid or type(metadataRequest.node) <> "roSGNode" then
    tubiLog("MetadataFetchTask.beginRequest: invalid 'node' argument")
    return
  end if

  if metadataRequest.field = invalid or metadataRequest.field = "" then
    tubiLog("MetadataFetchTask.beginRequest: invalid 'field' argument")
    return
  end if

  httpRequest = TubiRequest().createAsync(metadataRequest.url, metadataRequest.name, metadataRequest.options)
  if httpRequest = invalid then
    tubiLog("MetadataFetchTask.beginRequest: createAsyncHTTPRequest returned invalid")
    return
  end if

  ' store some context in the request object
  httpRequest.node = metadataRequest.node
  httpRequest.field = metadataRequest.field
  httpRequest.request_start_time = m.timespan.TotalMilliseconds()

  m.queue.pushRequest(httpRequest)
End Function


'''''''''''''''''''''''''
' handleResponse
'
' route an incoming metadata response to the node which requested it
'
Function handleResponse(message)
  tubiLog("MetadataFetchTask.handleResponse")
  handledRequest = m.queue.handleEvent(message)

  ' invalid can be returned if request is being retried
  if handledRequest <> invalid then
    handledRequest.request_end_time = m.timespan.TotalMilliseconds()
    ' double check that we have our context
    if handledRequest.node <> invalid and handledRequest.field <> invalid and handledRequest.response <> invalid then
      tubiLog("MetadataFetchTask.handleResponse setting response field " + handledRequest.field)
      tubiLog("MetadataFetchTask request duration = " + tostr(handledRequest.request_end_time - handledRequest.request_start_time))

      'indicates a request from the details screen. this request needs to be handled slightly differently
      if handledRequest.name = "getSingleContent"
        convertedMetadata = convertDetailsMetadata(handledRequest.response.data)
      else
        convertedMetadata = convertToContentMetadata(handledRequest.response.data)
      end if
      handledRequest.convert_end_time = m.timespan.TotalMilliseconds()
      tubiLog("MetadataFetchTask convert duration = " + tostr(handledRequest.convert_end_time - handledRequest.request_end_time))
      handledRequest.node[handledRequest.field] = convertedMetadata
    end if
  end if
End Function


'convert the server response to meta data node as expected by the details screen
Function convertDetailsMetadata(data As String) As Object
  parsed = ParseJSON(data)
  if parsed = invalid then
    tubiLog("MetadataFetchTask.convertDetailsMetadata failed to parse JSON response")
    return invalid
  end if

  parentNode = translateDetailsMetadata(parsed)
  
  return parentNode
End Function


' TODO(Chris): Capture this somewhere else if we use it in other places than this task node
Function convertToContentMetadata(data As String) As Object
  parsed = ParseJSON(data)
  if parsed = invalid then
    tubiLog("MetadataFetchTask.convertToContentMetadata failed to parse JSON response")
    return invalid
  end if

  parentNode = translateMetadata(parsed)
  
  return parentNode
End Function
