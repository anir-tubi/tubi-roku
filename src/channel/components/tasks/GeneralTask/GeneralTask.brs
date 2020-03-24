'General long running task which handles the api request & response, success and error callbacks
Function init()

  m.port = createObject("roMessagePort")
  m.top.observeField("request", m.port)
  
  m.top.functionName = "listen"
  m.top.control = "run"
  
End Function


' listen
' 
' this task listens for new request in port and makes api request & response calls 
Function listen()
  tubiLog("GeneralTask.listenloop started")
  
  ' Guarantee that we have a task thread local copy of constants before proceeding.
  ' It might be possible that grabbing m.global across the thread boundary could time out or fail
  while true
    m.constants = m.global.getField("constants")   ' this should grab a thread-local copy
    if m.constants <> invalid then
      exit while
    end if
    tubiLog("WARNING: Rendezvous failed for constants in GeneralTask")
  end while

  m.jobQueue = {}
  m.requestTypes = {}
  createParsingCallbacks()
  
  requestModule = TubiRequest(m.constants.settings.mode)

  while (true)
    msg = wait(0, m.port)
    if type(msg) = "roSGNodeEvent"
      if msg.getField() = "request"
      
        requestNode = msg.getData()
        if (requestNode.response = invalid and requestNode.error = invalid)
          makeApiRequest(requestNode, requestModule)
        end if
        
      end if
    else if type(msg) = "roUrlEvent"
      processResponse(msg)  
    end if  
  end while

End Function


' createParsingCallbacks
' 
' sets requestTypes with various success and error callbacks
' add new assocarray (api requestType key & value) into m.requestTypes to handle new api parsing
Function createParsingCallbacks()

  m.requestTypes = {
    "getHomeScreen": {
      "parseSuccess": parseHomescreenSuccess
      "parseError": parseHomescreenError
    }
  }  

End Function


' makeApiRequest
' 
' this method creates TubiRequest Object and start the api request
' @requestNode : roSGNode, requestNode is ContentNode
' @requestModule : AA, requestModule is TubiRequest Object
Function makeApiRequest(requestNode as Object, requestModule as Object) as Boolean

  requestType = requestNode.input.requestType
  url = requestNode.input.url
  options = requestNode.input.options
  
  tubiReq = requestModule.createAsync(url, requestType, options) 
  reqSent = tubiReq.start(m.port)
  
  urlTransfer = tubiReq.urlTransfer
  
  if urlTransfer <> invalid and reqSent = true
    id = stri(urlTransfer.getIdentity()).trim()
    m.jobQueue[id] = {"requestNode" : requestNode, "tubiReq" : tubiReq}
  end if
  
  return true
  
End Function


' processResponse
'
' it does basic parsing the api response and send to appropriate parsing callbacks for further parsing, and send back the parsed data to the response field.
' @msg : roUrlEvent, response object from api
Function processResponse(msg as Object)

    id = stri(msg.GetSourceIdentity()).trim()
    job = m.jobQueue[id]
    
    if job <> invalid
      
      callbackTypes = m.requestTypes[job.requestNode.input.requestType]
      result = job.tubiReq.handleEvent(msg)
      parsedResponse = invalid
      
      if result <> invalid and result.response <> invalid and callbackTypes <> invalid
      
        responseHeaders = result.response.headers
        
        if result.response.code >= 200 and result.response.code < 400
        
          if responseHeaders <> invalid and responseHeaders["Content-Type"] = "application/json"
            parsedResponse = parseJson(result.response.data)
          else if responseHeaders <> invalid and responseHeaders["Content-Type"] = "application/xml"
            ' we can write xml parsing functionality here and uncomment above 2 lines
          else 
            parsedResponse = result.response.data  
          end if
          
          parserCallback = callbackTypes.parseSuccess
          job.requestNode.response = parserCallback(parsedResponse)
          
        else
          
          parsedResponse = result.response
          parserCallback = callbackTypes.parseError
          job.requestNode.error = parserCallback(parsedResponse) 
                   
        end if 
      
      end if   
        
    end if
    
End Function