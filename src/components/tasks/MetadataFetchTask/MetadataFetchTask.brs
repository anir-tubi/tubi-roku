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
  m.queue = createHTTPRequestQueue(m.port)
  m.top.observeField("request", m.port)
  m.constants = m.global.constants   ' this should grab a thread-local copy

  ' Signal that we're ready for requests
  m.top.ready = true

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

  httpRequest = createAsyncHTTPRequest(metadataRequest.url, metadataRequest.name, metadataRequest.options)
  if httpRequest = invalid then
    tubiLog("MetadataFetchTask.beginRequest: createAsyncHTTPRequest returned invalid")
    return
  end if

  ' store some context in the request object
  httpRequest.node = metadataRequest.node
  httpRequest.field = metadataRequest.field

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
    ' double check that we have our context
    if handledRequest.node <> invalid and handledRequest.field <> invalid and handledRequest.response <> invalid then
      tubiLog("MetadataFetchTask.handleResponse setting response field " + handledRequest.field)
      handledRequest.node[handledRequest.field] = convertToContentMetadata(handledRequest.response.data)
    end if
  end if
End Function

' TODO(Chris): Capture this somewhere else if we use it in other places than this task node
Function convertToContentMetadata(data) As Object
  parsed = ParseJSON(data)
  if parsed = invalid then
    tubiLog("MetadataFetchTask.convertToContentMetadata failed to parse JSON response")
    return invalid
  end if

  parentNode = translateMetadata(parsed)
   
  return parentNode
End Function
