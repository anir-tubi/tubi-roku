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
  m.top.observeField("batchRequest", m.port)
  m.top.observeField("cancel", m.port)
  m.constants = getConstantsFromGlobal()
  m.nodeHelpers = TubiNodeHelpers()

  m.timespan = CreateObject("roTimeSpan")
  m.timespan.mark()
  m.epoch = m.timespan.TotalMilliseconds()
  m.totalConversionTime = 0

  ' Ready the translator
  experiments = TubiExperiments(m.constants)
  m.metadataTranslate = TubiMetadataTranslate(m.constants, experiments)

  ' batchStore helps to store containers responses as batches
  m.batchStore = {}
  ' batch store will look like below after receiving response for a batch
  ' m.batchStore - eg.
       '{
          '416eb945-81ba-45b8-9cd8-c11056666b43:  '{  
                                                    '09a35019-4120-45ef-bd3d-51effcc1340b: <Component: roAssociativeArray>
                                                    '12c696be-b2b1-4617-8b68-20fe912cea9a: <Component: roAssociativeArray>
                                                    '6e32aecc-b2af-41ce-ba23-d02678619fa8: <Component: roAssociativeArray>
                                                    '6f5ed7be-c97c-4086-80e7-be5c3c870849: <Component: roAssociativeArray>
                                                    '70ef677a-8b06-49fa-bf82-c15b63a5c6dc: <Component: roAssociativeArray>
                                                    '79276deb-7de3-4f77-a708-979abe533800: <Component: roAssociativeArray>
                                                    '7b2599df-7ac0-49ce-b3d6-e750b15289f2: <Component: roAssociativeArray>
                                                    '8e922927-27bd-4b90-bf9d-ec23c3da3bae: <Component: roAssociativeArray>
                                                    'c5b9facd-67de-4e7f-aa1e-d4325cb9ec7d: <Component: roAssociativeArray>
                                                    'fa915219-1db3-446c-aa9d-1c5af09c7704: <Component: roAssociativeArray>
                                                  '}
      '}

  m.jobStore = {}
  m.requestTypes = {}
  createParsingCallbacks()
  
  m.requestModule = Request(m.constants.settings)
  m.auth = TubiAuth(m.constants, m.requestModule)
  m.authInfo = invalid

  while (true)
    msg = wait(0, m.port)
    if type(msg) = "roSGNodeEvent"
      if msg.getField() = "request"

        requestNode = msg.getData()

        if requestNode <> invalid and isEmptyField(requestNode.response) and isEmptyField(requestNode.error)
          m.top.request = invalid 'reset the request field so no changes to the requestNode cause the following logic to run again 
          makeApiRequest(requestNode, invalid)
        end if

      else if msg.getField() = "batchRequest"
        
        requestNode = msg.getData()

        if requestNode <> invalid
          m.top.batchRequest = invalid 'reset the request field so no changes to the requestNode cause the following logic to run again 
          makeBatchApiRequests(requestNode)
        end if 

      else if msg.getField() = "cancel"

        requestNode = msg.getData()
          
        if requestNode <> invalid
          m.top.cancel = invalid 'reset the request field so no changes to the requestNode cause the following logic to run again 
          cancelRequests(requestNode)
        end if 

      end if       

    else if type(msg) = "roUrlEvent"
      processResponse(msg)  
    end if  
  end while

End Function


' makeApiRequest
' 
' this method creates TubiRequest Object and start the api request
' @requestNode : roSGNode, requestNode is ContentNode
' @batchNode : roSGNode, batchNode is TubiRequest() Object for batchRequest. it will be invalid for single request
Function makeApiRequest(requestNode, batchNode = invalid) as Boolean 
  requestId = requestNode.id
  input = requestNode.input 'grab a local copy of inputs to prevent subsequent rendezvous's

  if input <> invalid
    requestType = input.requestType
    url = input.url

    options = input.options
    if options = invalid
      options = {}
    end if

    m.authInfo = m.auth.getAuthInfo()
    if m.authInfo <> invalid and m.authInfo.accessToken <> invalid
      if m.constants.reqNames.acceptsTubiAuth[requestType] = true
        headers = m.auth.getAuthHeaders(m.authInfo.accessToken)
        if headers <> invalid
          if options.headers = invalid
            options.headers = {}
          end if
          options.headers.append(headers)
        end if
      end if
    end if  

    tubiReq = m.requestModule.createAsync(url, requestType, options)
    reqSent = tubiReq.start(m.port)

    urlTransfer = tubiReq.urlTransfer

    if urlTransfer <> invalid and reqSent = true
      id = stri(urlTransfer.getIdentity()).trim()

      m.jobStore[id] = {
        requestNode: requestNode
        tubiReq: tubiReq
        batchNode: batchNode
      }
      return true
    else  
      return false
    end if
  else
    return false
  end if

End Function


' @batchNode : roSGNode, batchNode is ContentNode and requests are children
Function makeBatchApiRequests(batchNode) As Void
  batchCount = batchNode.getChildCount()

  batchResponseAccumulator = {}
  batchResponseOrder = []
  batchId = batchNode.id

  for i=0 to batchCount-1
    singleRequestNode = batchNode.getChild(i)
    reqSent = makeApiRequest(singleRequestNode, batchNode)

    if reqSent = true
      ' Create a list of expected responses for the batch that will be
      ' used to verify if all the responses for the batch have been returned.
      requestId = singleRequestNode.id
      batchResponseOrder.push(requestId)
      batchResponseAccumulator[requestId] = invalid
    end if
  end for

  m.batchStore[batchId] = {
    responseAccumulator: batchResponseAccumulator
    responseOrder: batchResponseOrder
  }
End Function 


' processResponse
'
' it does basic parsing the api response and send to appropriate parsing callbacks for further parsing, and send back the parsed data to the response field.
' @msg : roUrlEvent, response object from api
Function processResponse(msg)
  id = stri(msg.GetSourceIdentity()).trim()
  job = m.jobStore[id]

  if job <> invalid

    requestNode = job.requestNode

    requestInput = requestNode.input
    requestType = requestInput.requestType
    callbackTypes = m.requestTypes[requestType]

    result = job.tubiReq.handleEvent(msg)
    retries = requestNode.retries

    if result <> invalid and result.response <> invalid 

      if callbackTypes <> invalid

        code = result.response.code

        if code >= 200 and code < 400

          processSuccessResponse(result, callbackTypes, job)

        else if (code = 403 or code = 401) and m.constants.reqNames.acceptsTubiAuth[requestType] = true
          if retries > 0
            ' request could not be authed by backend so attempt to refresh the auth token and try again
            timeout = 100
            if m.authInfo <> invalid and m.authInfo.userId <> invalid
              newAuthInfo = m.auth.refreshAuthToken(m.authInfo, timeout)
            else
              newAuthInfo = m.auth.refreshAnonymousToken(m.authInfo, timeout)
            end if

            if newAuthInfo <> invalid
              handleBackoff(requestNode, retries) 'pause before retry to relieve pressure on the backend
              makeApiRequest(job.requestNode, job.batchNode)
            else
              processErrorReponse(result, callbackTypes, job)
            end if
          else
            processErrorReponse(result, callbackTypes, job)
          end if
        else
          if retries > 0
            handleBackoff(requestNode, retries) 'pause before retry to relieve pressure on the backend
            makeApiRequest(job.requestNode, job.batchNode)
          else
            processErrorReponse(result, callbackTypes, job)
          end if
        end if

        m.jobStore.delete(id) ' delete the job from assocarray after the response is sent to avoid memory leak 

      end if
    end if

  end if
End Function


' @result : assocarray, this is the request handleEvent AA with response
' @callbackTypes : assocarray, it holds parseError & parseSuccess callbacks
' @job : assocarray, job as held in m.jobStore. Keys include:
'                    requestNode: roSGNode, RequestNode for the specific request
'                    tubiReq: AA, as returned from Request().createAsync()
'                    batchnode: roSGNode, parent RequestNode for the batch of individual Request Nodes
'                               (invalid for single request, valid for batch request)
Function processSuccessResponse(result, callbackTypes, job)

  responseFromServer = result.response
  responseHeaders = responseFromServer.headers
  serializationParseError = false

  if responseHeaders <> invalid
    if responseHeaders["Content-Type"] = "application/json"
      fullJson = responseFromServer.data
      parsedJson = parseJson(responseFromServer.data)

      if parsedJson <> invalid
        ' only update result in the case of not an error, so we can pass the original result
        ' info to processErrorResponse in the case of an error
        result.response.fullJson = fullJson
        result.response.data = parsedJson
      else
        serializationParseError = true
      end if
    else if responseHeaders["Content-Type"] = "application/xml"
      ' we can write xml parsing functionality here if/when necessary
    else if responseHeaders["Content-Type"] = invalid
      ' fallback, try parsing JSON in case no responseHeaders were set (most likely an
      ' ovesight by the backend service)
      fullJson = responseFromServer.data
      parsedJson = parseJson(responseFromServer.data)

      if parsedJson <> invalid
        ' only update result in the case of not an error, so we can pass the original result
        ' info into the parser function in case of an error.
        result.response.data = parsedJson
      end if

      ' don't set serializationParseError = true here, assume that the success parser function
      ' knows how to handle the original non json response.
    end if
  end if

  if serializationParseError = true
    ' even though we got success response headers, the response could not be parsed from
    ' JSON/XML, so we should treat it as an error
    processErrorReponse(result, callbackTypes, job)
  else
    parserCallback = callbackTypes.parseSuccess

    ' some requests may not require handling of the response and and therefore may not
    ' have a parseSuccess callback.
    if parserCallback <> invalid

      output = parserCallback(result.response, job.requestNode)

      ' this block will execute only for batch responses
      if job.batchNode <> invalid and job.batchNode.id <> invalid

        accumulateBatchResponse(job, output)

      else

        job.requestNode.response = output

      end if

    else
      job.requestNode.response = invalid
    end if
  end if

End Function


'accumulateBatchResponse, invokes callbacks for batch response and sets responses
'
' @job : assocarray, job as held in m.jobStore. Keys include:
'                    requestNode: roSGNode, RequestNode for the specific request
'                    tubiReq: AA, as returned from Request().createAsync()
'                    batchnode: roSGNode, parent RequestNode for the batch of individual Request Nodes
' @parsedResponse: any, the response value after it has been run through the appropriate
'                       success or error parser
'
' Side effect sends the batch with responses back to the render thread if all responses have been returned
Function accumulateBatchResponse(job, parsedResponse)
  if job = invalid or job.batchNode = invalid or job.requestNode = invalid
    return invalid
  end if

  requestId = job.requestNode.id
  batchId = job.batchNode.id
  batch = m.batchStore[batchId]

  if batch <> invalid and batch.responseAccumulator <> invalid and batch.responseOrder <> invalid
    batchResponseAccumulator = batch.responseAccumulator
    batchOrder = batch.responseOrder

    if parsedResponse <> invalid
      ' store the response on the accumulator
      batchResponseAccumulator[requestId] = parsedResponse
    else
      ' in case the parsedResponse is invalid, we need to store some indication in the
      ' batchResponseAccumulator that a response was received, but we can't use invalid
      ' as invalid is used to indicate that no response was received for a specific request id.
      ' So use an empty string
      batchResponseAccumulator[requestId] = ""
    end if

    ' check if we have received all the responses
    expected = batchResponseAccumulator.count()
    completed = 0
    for each reqId in batchResponseAccumulator
      if batchResponseAccumulator[reqId] <> invalid
        completed = completed + 1
      end if
    end for

    if expected = completed
      ' there is a response (valid or error) for each of the requests in the batch,
      ' so return the entire batch of responses back to the render thread

      ' TODO: allow custom batch response collations, like the parser functions for the
      ' individual request types, but at the batch level. This would allow us to include
      ' input information from the original batch node into the batch response.

      batchResponseType = job.batchNode.input.responseType

      if batchResponseType = "node"
        batchResponse = CreateObject("roSGNode", "ContentNode")

        for each reqId in batchOrder
          storedResponse = batchResponseAccumulator[reqId]

          ' any error responses such that the error parsers return AAs
          ' (or anything that is not a node) will not be returned to the render
          ' thread as part of the batch
          if type(storedResponse) = "roSGNode"
            batchResponse.appendChild(storedResponse)
          end if
        end for

      else if batchResponseType = "assocarray"
        ' batchResponseAccumulator is already an AA, so no need to re-arrange anything
        batchResponse = batchResponseAccumulator

      else if m.nodeHelpers.getArrayInterfaceTypes()[batchResponseType] = true
        ' batch response type is one of the various field array types
        batchResponse = []

        for each reqId in batchOrder
          storedResponse = batchResponseAccumulator[reqId]
          batchResponse.push(storedResponse)
        end for
      else
        ' This is not expected to happen, as the batchResponseType is expected to be defaulted
        ' to "assocarray" when the batch node is created in GeneralTaskModule.brs
        ' However, in case the batchResponseType is somehow an unexpected value, add a default value for safety.
        batchResponse = ""
      end if

      job.batchNode.response = batchResponse
      m.batchStore.delete(batchId)
    end if
  end if
End Function


'processErrorReponse, triggers when api fails
'
' @result : assocarray, this is the request handleEvent AA with response
' @callbackTypes : assocarray, it holds parseerror & parsesuccess callbacks
' @job : assocarray, it has requestNode, tubiReq, batchnode(invalid for single request, valid for batch request)
'
Function processErrorReponse(result, callbackTypes, job)

  ' end result of parsedResponse type may vary depending on API response format
  responseFromServer = result.response
  responseHeaders = responseFromServer.headers

  if responseHeaders <> invalid and responseHeaders["Content-Type"] = "application/json"
    responseFromServer.data = parseJson(result.response.data)
  end if

  parserCallback = callbackTypes.parseError

  ' some requests might not require error handling, and therefore may not have a parseError callback
  if parserCallback <> invalid
    output = parserCallback(result.response, job.requestNode)

    ' this block will execute only for batch responses
    if job.batchNode <> invalid and job.batchNode.id <> invalid
      accumulateBatchResponse(job, output)
    else
      job.requestNode.error = output
    end if
  else
    job.requestNode.response = invalid
  end if

End function


'''''''''''''''''''''''
' cancelRequests
' 
' this method cancels the outstanding requests on the same screen
' @requestNode : roSGNode, requestNode is ContentNode created at GeneralTaskModule
Function cancelRequests(requestNode) As Void

  tubiLog("GeneralTask.cancelRequests")

  requestId = requestNode.id
  for each job in m.jobStore
    child = m.jobStore[job]
    if child <> invalid and child.requestnode <> invalid and child.tubiReq <> invalid
      if child.requestnode.id = requestId
        child.tubiReq.cancel()
        exit for
      end if
    end if
  end for

End Function


' Helper function to handle the sleep before retrying a request
'
' @requestNode: roSGNode, a request node as created by GeneralTaskModule().constructRequestNode()
' @retries: integer, the number of remaining retries for a request/request node
'
' side effects: updates the retries and pause fields of the passed in requestNode
Function handleBackoff(requestNode, retries)
  backoffFactor = requestNode.backoffFactor
  pause = requestNode.pause

  sleep(pause) ' making some delay for retry request

  pause = pause * backoffFactor
  requestNode.pause = pause
  requestNode.retries = retries - 1
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
  else if (type(fieldValue) = "Integer" or type(fieldValue) = "roInt" or type(fieldValue) = "roInteger") and fieldValue = 0
    fieldIsEmpty = true
  end if

  return fieldIsEmpty
End Function
