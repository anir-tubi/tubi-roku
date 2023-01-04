'General long running task which handles the api request & response, success and error callbacks
Function init()
  m.port = createObject("roMessagePort")
  m.top.observeField("request", m.port)
  m.top.observeField("batchRequest", m.port)
  m.top.observeField("cancel", m.port)
  m.constants = getConstantsFromGlobal()
  ' We store a local copy of the translations so we don't have to do a rendezvous each time we request a translation during parsing
  m.translationAA = getFieldFromGlobal("translationAA")
  m.top.functionName = "listen"
  m.top.control = "run"
End Function


' listen
'
' this task listens for new request in port and makes api request & response calls
Function listen()
  tubiLog("GeneralTask.listen loop started")
  m.nodeHelpers = TubiNodeHelpers()

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
  m.backedOffJobs = {}
  createParsingCallbacks()

  m.requestModule = Request(m.constants.settings)
  m.auth = TubiAuth(m.constants, m.requestModule)
  m.authInfo = invalid

  while (true)
    msg = wait(200, m.port)
    if type(msg) = "roSGNodeEvent" then
      if msg.getField() = "request" then
        reqInfo = msg.getData()
        makeApiRequest(reqInfo, invalid)
      else if msg.getField() = "batchRequest"
        batchInfo = msg.getData()
        if batchInfo <> invalid then
          makeBatchApiRequests(batchInfo)
        end if
      else if msg.getField() = "cancel" then
        reqInfo = msg.getData()
        if reqInfo <> invalid then
          cancelRequests(reqInfo)
        end if
      end if
    else if type(msg) = "roUrlEvent" then
      processResponse(msg)
    end if

    for each requestId in m.backedOffJobs
      obj = m.backedOffJobs[requestId]
      if obj.timespan.totalMilliseconds() > obj.backoffDuration then
        job = obj.job
        makeApiRequest(job.reqInfo, job.batchInfo)
        m.backedOffJobs.delete(requestId)
      end if
    end for
  end while
End Function


' makeApiRequest
'
' this method creates TubiRequest Object and start the api request
' @reqInfo: AA that was created by generalTask_makeRequest
' @batchInfo: AA, contains information needed to make the request. See generalTask_makeBatchRequest for more info.
Function makeApiRequest(reqInfo, batchInfo = invalid) as Boolean
  if reqInfo <> invalid
    requestType = reqInfo.requestType
    url = reqInfo.url

    options = reqInfo.options
    if options = invalid
      options = {}
    end if

    m.authInfo = m.auth.getAuthInfo()
    if m.authInfo <> invalid AND m.authInfo.accessToken <> invalid
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

    if urlTransfer <> invalid AND reqSent = true
      id = urlTransfer.getIdentity().toStr()

      m.jobStore[id] = {
        reqInfo: reqInfo
        tubiReq: tubiReq
        batchInfo: batchInfo
      }
      return true
    else
      return false
    end if
  else
    return false
  end if
End Function


' @batchInfo: AA, contains information needed to make the request. See generalTask_makeBatchRequest for more info.
Function makeBatchApiRequests(batchInfo)
  batchResponseAccumulator = {}
  batchResponseOrder = []
  batchId = batchInfo.id

  requests = batchInfo.requests
  for each reqInfo in requests
    reqSent = makeApiRequest(reqInfo, batchInfo)

    if reqSent = true
      ' Create a list of expected responses for the batch that will be
      ' used to verify if all the responses for the batch have been returned.
      requestId = reqInfo.id
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
  id = msg.GetSourceIdentity().toStr()
  job = m.jobStore[id]

  if job <> invalid

    reqInfo = job.reqInfo
    requestType = reqInfo.requestType
    callbackTypes = m.requestTypes[requestType]

    result = job.tubiReq.handleEvent(msg)
    retries = reqInfo.retries

    if result <> invalid AND result.response <> invalid

      if callbackTypes <> invalid
        canRetry4xxCodes = {
          "401": true  ' not authorized, get a new auth token and try again
          "403": true  ' forbidden, get a new auth token and try again
          "408": true  ' request timed out, might not time out next time
        }

        code = result.response.code

        if code >= 200 AND code < 400
          processSuccessResponse(result, callbackTypes, job)
        else if code >= 400 AND code < 500 AND canRetry4xxCodes[code.toStr()] <> true
          ' error expected to remain error on retry so don't bother retrying
          processErrorResponse(result, callbackTypes, job)
        else if (code = 403 OR code = 401) AND m.constants.reqNames.acceptsTubiAuth[requestType] = true
          if retries > 0
            ' request could not be authed by backend so attempt to refresh the auth token and try again
            timeout = 100
            if m.authInfo <> invalid AND m.authInfo.userId <> invalid
              newAuthInfo = m.auth.refreshAuthToken(m.authInfo, timeout)
            else
              newAuthInfo = m.auth.refreshAnonymousToken(m.authInfo, timeout)
            end if

            if newAuthInfo <> invalid
              handleBackoff(result, job, retries) 'pause before retry to relieve pressure on the backend
            else
              processErrorResponse(result, callbackTypes, job)
            end if
          else
            processErrorResponse(result, callbackTypes, job)
          end if
        else
          if retries > 0
            handleBackoff(result, job, retries) 'pause before retry to relieve pressure on the backend
          else
            processErrorResponse(result, callbackTypes, job)
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
'                    reqInfo: AA, info as passed in from generalTask_makeRequest for the specific request
'                    tubiReq: AA, as returned from Request().createAsync()
'                    batchInfo: AA, contains information needed to make the request. See generalTask_makeBatchRequest for more info.
'                               (invalid for single request, valid for batch request)
Function processSuccessResponse(result, callbackTypes, job)

  responseFromServer = result.response
  responseHeaders = responseFromServer.headers
  serializationParseError = false

  if responseHeaders <> invalid
    if responseHeaders["Content-Type"] = invalid
      ' fallback, try parsing JSON in case no responseHeaders were set (most likely an
      ' oversight by the backend service)
      fullJson = responseFromServer.data
      parsedJson = invalid
      if fullJson <> invalid AND fullJson <> ""
        parsedJson = parseJson(responseFromServer.data)
      end if

      if parsedJson <> invalid
        ' only update result in the case of not an error, so we can pass the original result
        ' info into the parser function in case of an error.
        result.response.data = parsedJson
      end if

      ' don't set serializationParseError = true here, assume that the success parser function
      ' knows how to handle the original non json response.
    else if Instr(1, responseHeaders["Content-Type"], "application/json") > 0
      fullJson = responseFromServer.data
      parsedJson = invalid
      if fullJson <> invalid AND fullJson <> ""
        parsedJson = parseJson(responseFromServer.data)
      end if

      if parsedJson <> invalid
        ' only update result in the case of not an error, so we can pass the original result
        ' info to processErrorResponse in the case of an error
        result.response.fullJson = fullJson
        result.response.data = parsedJson
      else
        serializationParseError = true
      end if
    else if Instr(1, responseHeaders["Content-Type"], "application/xml") > 0
      ' we can write xml parsing functionality here if/when necessary
    end if
  end if

  if serializationParseError = true
    ' even though we got success response headers, the response could not be parsed from
    ' JSON/XML, so we should treat it as an error
    processErrorResponse(result, callbackTypes, job)
  else
    parserCallback = callbackTypes.parseSuccess

    ' some requests may not require handling of the response and and therefore may not
    ' have a parseSuccess callback.
    if parserCallback <> invalid
      output = parserCallback(result.response, job.reqInfo)

      ' this block will execute only for batch responses
      if job.batchInfo <> invalid AND job.batchInfo.id <> invalid
        accumulateBatchResponse(job, output)
      else
        job.reqInfo.callbackNode.response = output
      end if
    else
      ' Default responseType is string so we send back an empty string to at least let someone know the request succeeded
      job.reqInfo.callbackNode.response = ""
    end if
  end if

End Function


'accumulateBatchResponse, invokes callbacks for batch response and sets responses
'
' @job : assocarray, job as held in m.jobStore. Keys include:
'                    reqInfo: AA, info passed in for request as part of either generalTask_makeRequest or generalTask_makeBatchRequest containing info needed to make the request
'                    tubiReq: AA, as returned from Request().createAsync()
'                    batchInfo: AA, contains information needed to make the request. See generalTask_makeBatchRequest for more info.
' @parsedResponse: any, the response value after it has been run through the appropriate
'                       success or error parser
'
' Side effect sends the batch with responses back to the render thread if all responses have been returned
Function accumulateBatchResponse(job, parsedResponse) as Void
  if job = invalid or job.reqInfo = invalid or job.batchInfo = invalid
    return
  end if

  requestId = job.reqInfo.id
  batchId = job.batchInfo.id
  batch = m.batchStore[batchId]

  if batch <> invalid AND batch.responseAccumulator <> invalid AND batch.responseOrder <> invalid
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

      batchResponseType = job.batchInfo.responseType
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

      job.batchInfo.callbackNode.response = batchResponse
      m.batchStore.delete(batchId)
    end if
  end if
End Function


'processErrorResponse, triggers when api fails
'
' @result : assocarray, this is the request handleEvent AA with response
' @callbackTypes : assocarray, it holds parseerror & parsesuccess callbacks
' @job : assocarray, it has reqInfo, tubiReq, batchInfo(invalid for single request, valid for batch request)
'
Function processErrorResponse(result, callbackTypes, job)
  ' end result of parsedResponse type may vary depending on API response format
  responseFromServer = result.response
  responseHeaders = responseFromServer.headers

  if responseHeaders <> invalid AND responseHeaders["Content-Type"] = "application/json"
    responseFromServer.data = parseJson(result.response.data)
  end if

  parserCallback = callbackTypes.parseError

  sendApiErrorLog(responseFromServer)

  ' some requests might not require error handling, and therefore may not have a parseError callback
  if parserCallback <> invalid
    output = parserCallback(result.response, job.reqInfo)

    ' this block will execute only for batch responses
    if job.batchInfo <> invalid AND job.batchInfo.id <> invalid
      accumulateBatchResponse(job, output)
    else
      job.reqInfo.callbackNode.error = output
    end if
  else
    job.reqInfo.callbackNode.response = invalid
  end if

End function


'''''''''''''''''''''''
' cancelRequests
'
' this method cancels the outstanding requests on the same screen
' @reqInfo: AA that was created by generalTask_makeRequest
Function cancelRequests(reqInfo) As Void
  tubiLog("GeneralTask.cancelRequests")

  requestId = reqInfo.id
  for each key in m.jobStore
    job = m.jobStore[key]
    if job <> invalid AND job.reqInfo <> invalid AND job.tubiReq <> invalid
      if job.reqInfo.id = requestId
        job.tubiReq.cancel()
        exit for
      end if
    end if
  end for
  m.backedOffJobs.delete(requestId)
End Function


' Helper function to setup logic to store the job before retrying after the requested amount of time has passed
'
' @result : assocarray, this is the request handleEvent AA with response
' @job: AssocArray, the job for this request as created in makeApiRequest
' @retries: integer, the number of remaining retries for a request/request node
'
' side effects: updates the retries and pause fields of the passed in reqInfo
Function handleBackoff(result, job, retries)
  sendApiErrorLog(result.response)
  reqInfo = job.reqInfo
  backoffFactor = reqInfo.backoffFactor
  backoffDuration = reqInfo.pause * backoffFactor
  reqInfo.pause = backoffDuration
  reqInfo.retries = retries - 1
  m.backedOffJobs[reqInfo.id] = {
    "timespan": createObject("roTimespan")
    "job": job
    "backoffDuration": backoffDuration
  }
End Function


' @responseFromServer: assocarray, this is the response field on the AA returned by request.handleAA()
Function sendApiErrorLog(responseFromServer)

  errorInfo = {
    name: responseFromServer.name
    failReason: responseFromServer.failReason
    code: responseFromServer.code
  }

  jsonErrorInfo = FormatJSON(errorInfo)
  ' sending error logs to uapi
  tubiLog(jsonErrorInfo, "error", "apiError", responseFromServer.name, 0.1)
  ' sending error logs to sentry sdk
  tubiException(jsonErrorInfo, "error", 0.1)

End Function


Function isEmptyField(fieldValue)
  fieldIsEmpty = false

  if fieldValue = invalid
    fieldIsEmpty = true
  else if (type(fieldValue) = "roArray" or type(fieldValue) = "roAssociativeArray") AND fieldValue.count() = 0
    fieldIsEmpty = true
  else if type(fieldValue) = "roSGNode" AND fieldValue.getChildCount() = 0
    fieldIsEmpty = true
  else if (type(fieldValue) = "String" or type(fieldValue) = "roString") AND fieldValue = ""
    fieldIsEmpty = true
  else if (type(fieldValue) = "Integer" or type(fieldValue) = "roInt" or type(fieldValue) = "roInteger") AND fieldValue = 0
    fieldIsEmpty = true
  end if

  return fieldIsEmpty
End Function
