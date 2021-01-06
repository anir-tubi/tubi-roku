'General long running task which handles the api request & response, success and error callbacks
Function init()
  m.top.functionName = "listen"
  m.top.control = "run"
End Function


' listen
' 
' this task listens for new request in port and makes api request & response calls 
Function listen()
  tubiLog("GeneralTask.listenloop started")
  m.port = createObject("roMessagePort")
  m.top.observeField("request", m.port)
  m.constants = getConstantsFromGlobal()

  m.jobStore = {}
  m.requestTypes = {}
  createParsingCallbacks()
  
  requestModule = TubiRequest(m.constants.settings.mode)
  authModule = TubiAuth(m.constants, requestModule)

  while (true)
    msg = wait(0, m.port)
    if type(msg) = "roSGNodeEvent"
      if msg.getField() = "request"
        requestNode = msg.getData()

        'reset the request field so no changes to the requestNode cause the following logic to run again 
        m.top.request = invalid

        if requestNode <> invalid and isEmptyField(requestNode.response) and isEmptyField(requestNode.error)
          makeApiRequest(requestNode, requestModule, authModule)
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

  m.requestTypes = {}

  ' sprites
  m.requestTypes[m.constants.reqNames.getThumbnails] = {
    parseSuccess: parseVideoScreenSpritesSuccess
  }

  ' up next / autoplay
  m.requestTypes[m.constants.reqNames.getUpNextContent] = {
    parseSuccess: parseVideoScreenUpNextSuccess
    parseError: parseVideoScreenUpNextError
  }

  ' live manifest
  m.requestTypes[m.constants.reqNames.getLiveManifest] = {
    parseSuccess: parseLiveVideoManifestSuccess
    parseError: parseLiveVideoManifestError
  }

End Function


' makeApiRequest
' 
' this method creates TubiRequest Object and start the api request
' @requestNode : roSGNode, requestNode is ContentNode
' @requestModule : AA, requestModule is TubiRequest() Object
' @authModule : AA, authModule is TubiAuth() Object
Function makeApiRequest(requestNode, requestModule, authModule) as Boolean
  tubiLog("GeneralTask.makeApiRequest")
  requestType = requestNode.input.requestType
  url = requestNode.input.url

  options = requestNode.input.options
  if options = invalid
    options = {}
  end if
  
  ' m.auth.createAuthRequest() returns invalid if the user is not logged in
  tubiReq = authModule.createAuthRequest(url, requestType, options)
  if tubiReq = invalid
    tubiReq = requestModule.createAsync(url, requestType, options)
  end if
  reqSent = tubiReq.start(m.port)
  
  urlTransfer = tubiReq.urlTransfer
  
  if urlTransfer <> invalid and reqSent = true
    id = stri(urlTransfer.getIdentity()).trim()
    m.jobStore[id] = {"requestNode" : requestNode, "tubiReq" : tubiReq}
  end if
  
  return true
  
End Function


' processResponse
'
' it does basic parsing the api response and send to appropriate parsing callbacks for further parsing, and send back the parsed data to the response field.
' @msg : roUrlEvent, response object from api
Function processResponse(msg)
  id = stri(msg.GetSourceIdentity()).trim()
  job = m.jobStore[id]

  if job <> invalid

    callbackTypes = m.requestTypes[job.requestNode.input.requestType]
    result = job.tubiReq.handleEvent(msg)

    if result <> invalid and result.response <> invalid and callbackTypes <> invalid

      responseHeaders = result.response.headers

      if result.response.code >= 200 and result.response.code < 400

        response = result.response
        if responseHeaders <> invalid and responseHeaders["Content-Type"] = "application/json"
          response.data = parseJson(result.response.data)
        else if responseHeaders <> invalid and responseHeaders["Content-Type"] = "application/xml"
          ' we can write xml parsing functionality here if/when necessary
        end if

        parserCallback = callbackTypes.parseSuccess
        job.requestNode.response = parserCallback(response, job.requestNode)

      else

        ' end result of parsedResponse type may vary depending on API response format
        response = result.response
        if responseHeaders <> invalid and responseHeaders["Content-Type"] = "application/json"
          response.data = parseJson(result.response.data)
        end if

        parserCallback = callbackTypes.parseError

        ' some requests might not require error handling, and therefore may not have a parseError callback
        if parserCallback <> invalid
          job.requestNode.error = parserCallback(response, job.requestNode)
        else
          job.requestNode.error = invalid
        end if

      end if

    end if

  end if

End Function


Function isEmptyField(fieldValue)
  fieldIsEmpty = false

  if fieldValue = invalid
    fieldIsEmpty = true
  else if (type(fieldValue) = "roArray" or type(fieldValue) = "roAssociativeArray") and fieldValue.count() = 0
    fieldIsEmpty = true
  else if type(fieldValue) = "roSGNode" and fieldValue.getChildCount() = 0
    fieldIsEmpty = true
  else if (type(fieldValue) = "String" or type(fieldValue) = "roString") and fieldValue = ""
    fieldIsEmpty = true
  end if

  return fieldIsEmpty
End Function