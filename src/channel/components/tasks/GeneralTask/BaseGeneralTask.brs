'General long running task which handles the api request & response, success and error callbacks
Function init()
  m.port = createObject("roMessagePort")
  ' Setting up observers for the request and batch request fields.
  m.top.observeField("request", m.port)
  m.top.observeField("batchRequest", m.port)
  m.top.observeField("cancel", m.port)
  m.top.observeField("newClientErrorConfig", m.port)
  m.top.observeField("newConstants", m.port)
  m.top.observeField("newExperimentsInfo", m.port)
  m.top.observeField("newSoTStaticConfig", m.port)
  m.top.observeField("newStatSigExperiments", m.port)
  m.constants = getConstantsFromGlobal()

  ' Used to know how we should handle error cases on network requests
  m.clientErrorConfig = {}

  ' In order to be able to update the experiments without having pass it down manually we need an existing AA that we can just update the keys on
  m.experimentsInfo = {}

  ' In order to be able to update the statSigExperiments without having pass it down manually we need an existing AA that we can just update the keys on
  m.statSigExperimentsInfo = {}

  ' In order to be able to update the soTStaticConfig without having pass it down manually we need an existing AA that we can just update the keys on
  m.soTStaticConfig = {}

  ' Creating a scope variable that will be overridden by each sub task
  m.requestTypes = {}

  ' We store a local copy of the translations so we don't have to do a rendezvous each time we request a translation during parsing
  m.translationAA = getFieldFromGlobal("translationAA")

  m.top.functionName = "listen"
  m.top.control = "run"
End Function


' listen
'
' this task listens for new request in port and makes api request & response calls
Function listen()
  tubiLog("BaseGeneralTask.listen loop started")

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
  m.backedOffJobs = {}
  m.requestTypes = {}

  instantiateLibs()

  ' calling method to register parsing callbacks
  registerParsingCallbacks()

  ' Calling register parsing callback which will be overridden by every sub tasks.

  m.requestModule = Request(m.constants.settings)
  m.auth = TubiAuth(m.constants)
  nTimeout = 0 'We do not need to execute timeout processing logic every time while loop is executed (200ms). This counter is used to control the timeout logic execution to every third time.

  while (true)
    msg = wait(200, m.port)
    if type(msg) = "roSGNodeEvent" then
      field = msg.getField()
      if field = "request" then
        reqInfo = msg.getData()
        makeApiRequest(reqInfo, invalid)
      else if field = "batchRequest"
        batchInfo = msg.getData()
        if batchInfo <> invalid then
          makeBatchApiRequests(batchInfo)
        end if
      else if field = "cancel" then
        reqInfo = msg.getData()
        if reqInfo <> invalid then
          cancelRequests(reqInfo)
        end if
      else if field = "newClientErrorConfig" then
        clientErrorConfig = msg.getData()
        if clientErrorConfig <> invalid then
          m.clientErrorConfig = clientErrorConfig
        end if
      else if field = "newConstants" then
        constants = msg.getData()

        ' Instead of trying to track down all the spots constants might be used we are keeping the AA reference and just replacing the keys to update all to use the same data
        for each key in m.constants
          if constants[key] = invalid
            m.constants[key].delete()
          end if
        end for

        m.constants.append(constants)
      else if field = "newExperimentsInfo" then
        experimentsInfo = msg.getData()

        ' Instead of trying to track down all the spots experimentsInfo might be used we are keeping the AA reference and just replacing the keys to update all to use the same data
        for each key in m.experimentsInfo
          if experimentsInfo[key] = invalid
            m.experimentsInfo[key].delete()
          end if
        end for

        m.experimentsInfo.append(experimentsInfo)
      else if field = "newSoTStaticConfig"
        soTStaticConfig = msg.getData()
        for each key in m.soTStaticConfig
          if soTStaticConfig[key] = invalid
            m.soTStaticConfig.delete(key)
          end if
        end for

        m.soTStaticConfig.append(soTStaticConfig)
      else if field = "newStatSigExperiments" then
        statSigExperiments = msg.getData()

        ' Instead of trying to track down all the spots experimentsInfo might be used we are keeping the AA reference and just replacing the keys to update all to use the same data
        for each key in m.statSigExperimentsInfo
          if statSigExperiments[key] = invalid
            m.statSigExperimentsInfo.delete(key)
          end if
        end for

        m.statSigExperimentsInfo.append(statSigExperiments)
      else
        conditionallyProcessAuthUpdatedMessage(msg)
      end if
    else if type(msg) = "roUrlEvent" then
      processResponse(msg)
    end if

    for each requestId in m.backedOffJobs
      backedOffJob = m.backedOffJobs[requestId]

      if backedOffJob.timespan.totalMilliseconds() > backedOffJob.backoffDuration then
        job = backedOffJob.job
        requestType = job.reqInfo.requestType
        if m.waitingForUpdatedAuthInfo = false OR m.constants.reqNames.acceptsTubiAuth[requestType] <> true then
          makeApiRequest(job.reqInfo, job.batchInfo)
          m.backedOffJobs.delete(requestId)
        end if
      end if
    end for

    nTimeout = nTimeout + 1
    if nTimeout >= 3
      nTimeout = 0 'bs:disable-line 1001 Lint1005
      for each requestId in m.jobStore
        job = m.jobStore[requestId]
        reqInfo = job.reqInfo

        if job.startTime.totalMilliseconds() > reqInfo.timeoutInMilliSec
          retries = reqInfo.retries
          m.jobStore.delete(requestId)

          if job.tubiReq <> invalid
            job.tubiReq.cancel() ' To avoid the danger of api showing up later than timeout
          end if

          if reqInfo.retriesAttempted = invalid then
            reqInfo.retriesAttempted = 0
          end if

          if retries > 0 AND reqInfo.retriesAttempted < retries then
            retryAfter = clientErrorConfigCheckIfShouldRetryAfter(m.clientErrorConfig, reqInfo.url, job.tubiReq.method, "-1236", {}, invalid, reqInfo.retriesAttempted)
            if retryAfter = -1 then
              processTimeoutError(job)
            else
              reqInfo.retriesAttempted = reqInfo.retriesAttempted + 1
              makeApiRequest(reqInfo, job.batchInfo) 'make api request because they have already waited for timeout
            end if
          else
            processTimeoutError(job)
          end if
        end if
      end for
    end if

  end while
End Function


'processTimeoutError, mimics when api timeouts
' @job : assocarray, it has reqInfo, tubiReq, batchInfo(invalid for single request, valid for batch request)
'
Function processTimeoutError(job)

  if job.reqInfo <> invalid
    requestType = job.reqInfo.requestType
    callbackTypes = m.requestTypes[requestType]

    if callbackTypes <> invalid

      ' there might be some issue with internet access
      errCode = -1236

      result = {
        response: {
          "code": errCode
          "name": requestType
          "failReason": "Timeout.Response unknown"
          "url": job.reqInfo.url
        }
      }

      processErrorResponse(result, callbackTypes, job)
    end if
  end if

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

    isValidAuthInfoAvailable = true

    if m.constants.reqNames.acceptsTubiAuth[requestType] = true then
      if m.waitingForUpdatedAuthInfo = true
        ' If we are waiting for updated auth info then we don't want to send the request yet
        isValidAuthInfoAvailable = false
      else
        authInfo = m.auth.getAuthInfo()
        ' It is expected that the authInfo should never be invalid when accessed here. It is possible that the token is expired but for simplicity we send the request and when we get the 403 response we will retry after updating the auth info. This allows for a simpler process and more consistent behavior.
        if authInfo <> invalid AND authInfo.accessToken <> invalid AND m.auth.checkIfAuthExpired(authInfo) = false then

          ' We are proactively retrieving updated auth info if it expires in the next ten minutes
          if m.auth.checkIfAuthExpired(authInfo, 60 * 10) = true then
            getUpdatedAuth()
          end if

          headers = m.auth.getAuthHeaders(authInfo.accessToken)
          if headers <> invalid
            if options.headers = invalid
              options.headers = {}
            end if
            options.headers.append(headers)
          end if
        else
          isValidAuthInfoAvailable = false
        end if
      end if
    end if

    tubiReq = m.requestModule.createAsync(url, requestType, options)

    job = {
      startTime: createObject("roTimespan")
      reqInfo: reqInfo
      tubiReq: tubiReq
      batchInfo: batchInfo
    }

    ' If valid auth info isn't available then we want to request updated auth info and hold off the request until we get it
    if isValidAuthInfoAvailable = false then
      getUpdatedAuth()
      handleBackoff(invalid, job, 0)
      return true
    else
      reqSent = tubiReq.start(m.port)

      urlTransfer = tubiReq.urlTransfer

      if urlTransfer <> invalid AND reqSent = true
        id = urlTransfer.getIdentity().toStr()

        m.jobStore[id] = job
        return true
      else
        return false
      end if
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
      if callbackTypes = invalid then
        tubiLog("BaseGeneralTask: Could not load callbackTypes for requestType: " + requestType, "warn")
      else
        code = result.response.code

        if code >= 200 AND code < 400
          processSuccessResponse(result, callbackTypes, job)
        else
          if reqInfo.retriesAttempted = invalid then
            reqInfo.retriesAttempted = 0
          end if

          ' First check if we are limited by retries on our request side
          if reqInfo.retriesAttempted >= retries then
            processErrorResponse(result, callbackTypes, job)
          else
            ' Next check against client error config to see if we should retry
            retryAfter = clientErrorConfigCheckIfShouldRetryAfter(m.clientErrorConfig, reqInfo.url, result.method, code.toStr(), result.response.headers, result.response.data, reqInfo.retriesAttempted)

            ' If we are told not to then process the error
            if retryAfter = -1 then
              processErrorResponse(result, callbackTypes, job)
            else
              handleBackoff(result, job, retryAfter)
            end if
          end if
        end if
      end if
      m.jobStore.delete(id) ' delete the job from assocarray after the response is sent to avoid memory leak
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
    try
      parserCallback = callbackTypes.parseSuccess

      ' some requests may not require handling of the response and therefore may not
      ' have a parseSuccess callback.
      if parserCallback <> invalid
        if callbackTypes.passRawResponse = true
          result.responseHeaders = responseHeaders
          output = parserCallback(result, job.reqInfo)
        else
          output = parserCallback(result.response, job.reqInfo)
        end if

        ' this block will execute only for batch responses
        if job.batchInfo <> invalid AND job.batchInfo.id <> invalid
          accumulateBatchResponse(job, output)
        else if job.reqInfo <> invalid AND job.reqInfo.silenceCallbackWarnings = true
          ' In case of fire and forget requests, we don't care about the output.
          job.reqInfo.callbackNode.response = output
        else
          ' Adding a check if parser output type does not match expected type for callback field as if it does not match then we can get stuck in the bootstrap flow
          expectedType = job.reqInfo.callbackNode.getFieldType("response")
          outputTypeMatches = true

          if expectedType = "associativearray" then
            if isAA(output) = false then
              outputTypeMatches = false
              if isString(output) = true then
                output = parseJSON(output)
                if isAA(output) = true then
                  message = {
                    "expectedType": expectedType
                    "outputType": type(output)
                    "url": result.url
                    "responseCode": result.response.code
                  }

                  ' If the output does not match the expected type then we should log an error
                  logInfo(message, "clientInfo", "parser-json-aa-conversion", 1)

                  outputTypeMatches = true
                end if
              end if
            end if
          else if expectedType = "string" then
            if isString(output) = false then
              outputTypeMatches = false
            end if
          else if expectedType = "node" then
            if isNode(output) = false then
              outputTypeMatches = false
            end if
          else if expectedType = "array" then
            if isArray(output) = false then
              outputTypeMatches = false
            end if
          else
            tubiLog("BaseGeneralTask.processSuccessResponse: Unchecked type: " + expectedType)
          end if

          if outputTypeMatches = true then
            ' If the output matches the expected type then we can set it as the response
            job.reqInfo.callbackNode.response = output
          else
            message = {
              "expectedType": expectedType
              "outputType": type(output)
              "url": result.url
              "responseCode": result.response.code
            }

            ' If the output does not match the expected type then we should log an error
            logInfo(message, "clientInfo", "parser-output-type-mismatch", 1)

            processErrorResponse(result, callbackTypes, job)
          end if
        end if
      else
        ' Default responseType is string so we send back an empty string to at least let someone know the request succeeded
        job.reqInfo.callbackNode.response = ""
      end if
    catch e
      if m.constants.settings.mode <> "production"
        throw e
      else
        message = {
          "url": result.url
          "responseCode": result.response.code
        }

        message.append(e)

        logInfo(message, "clientInfo", "caught-crash", 1)
        processErrorResponse(result, callbackTypes, job)
      end if
    end try
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
  if job = invalid OR job.reqInfo = invalid OR job.batchInfo = invalid
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

      else if getArrayInterfaceTypes()[batchResponseType] = true
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
  tubiLog("BaseGeneralTask.processErrorResponse")
  ' end result of parsedResponse type may vary depending on API response format
  responseFromServer = result.response
  responseHeaders = responseFromServer.headers

  if responseHeaders <> invalid AND responseHeaders["Content-Type"] = "application/json" AND isString(result.response.data) = true then
    responseFromServer.data = parseJson(result.response.data)
  end if

  parserCallback = invalid

  if callbackTypes <> invalid
    parserCallback = callbackTypes.parseError
  end if

  sendApiErrorLog(result)

  ' some requests might not require error handling, and therefore may not have a parseError callback
  if parserCallback <> invalid then
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

End Function


'''''''''''''''''''''''
' cancelRequests
'
' this method cancels the outstanding requests on the same screen
' @reqInfo: AA that was created by generalTask_makeRequest
Function cancelRequests(reqInfo) as Void
  tubiLog("BaseGeneralTask.cancelRequests")

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


' Helper function to setup logic to store the job before retrying after the appropriate amount of time has passed.
' This can be used to store jobs waiting to be retried after the initial request fails.
' This can also be used to store jobs waiting to be sent while the auth/anonymous token is refreshed
'
' @result : assocarray, this is the request handleEvent AA with response or invalid if we haven't sent the request yet
' @job: AssocArray, the job for this request as created in makeApiRequest
' @backoffDuration: integer, the amount of time to wait before retrying the request. This should only be changed if we want to overwrite the default backoff duration or the backoff duration included as part of the request info
'
' side effects: updates the retriesAttempted and pause fields of the passed in reqInfo
Function handleBackoff(result, job, backoffDuration)
  tubiLog("BaseGeneralTask.handleBackoff")
  if result <> invalid then
    sendApiErrorLog(result)
  end if

  reqInfo = job.reqInfo

  reqInfo.pause = backoffDuration

  if reqInfo.retriesAttempted = invalid then
    reqInfo.retriesAttempted = 0
  end if

  reqInfo.retriesAttempted = reqInfo.retriesAttempted + 1

  m.backedOffJobs[reqInfo.id] = {
    "timespan": createObject("roTimespan")
    "job": job
    "backoffDuration": backoffDuration
  }
End Function


' @result: assocarray, this is the result field as AA returned by handleEvent()
Function sendApiErrorLog(result)

  responseFromServer = result.response

  errorInfo = {
    name: responseFromServer.name
    failReason: responseFromServer.failReason
    code: responseFromServer.code
    url: result.url
  }

  errorInfo = appendDnsInfo(responseFromServer, errorInfo)

  jsonErrorInfo = FormatJSON(errorInfo)
  ' sending error logs to uapi
  logError(jsonErrorInfo, "apiError", responseFromServer.name, 0.1)
End Function


Function appendDnsInfo(responseFromServer, errorInfo)
  if responseFromServer.dnsInfo <> invalid then
    errorInfo.append(responseFromServer.dnsInfo)
  end if

  return errorInfo
End Function


Function isEmptyField(fieldValue)
  fieldIsEmpty = false

  if fieldValue = invalid
    fieldIsEmpty = true
  else if (type(fieldValue) = "roArray" OR type(fieldValue) = "roAssociativeArray") AND fieldValue.count() = 0
    fieldIsEmpty = true
  else if type(fieldValue) = "roSGNode" AND fieldValue.getChildCount() = 0
    fieldIsEmpty = true
  else if (type(fieldValue) = "String" OR type(fieldValue) = "roString") AND fieldValue = ""
    fieldIsEmpty = true
  else if (type(fieldValue) = "Integer" OR type(fieldValue) = "roInt" OR type(fieldValue) = "roInteger") AND fieldValue = 0
    fieldIsEmpty = true
  end if

  return fieldIsEmpty
End Function



Function getErrorCodeFromResponse(fullResponse)
  ' default code
  errCode = -1235

  if fullResponse <> invalid AND fullResponse.code <> invalid
    if fullResponse.code >= 200 AND fullResponse.code < 400
      ' got a valid response code from the server, but there was some other issue with the response
      errCode = -1237
    else
      ' HTTP or Curl code
      errCode = fullResponse.code
    end if
  else
    deviceInfo = CreateObject("roDeviceInfo")
    if deviceInfo.GetLinkStatus() = false
      ' firmware thinks the device does not have internet access
      errCode = -1236
    end if
  end if

  return errCode
End Function


' Creating a default method which will be overridden by sub tasks.
Function registerParsingCallbacks()
  m.requestTypes = {}
End Function


' Called from the base general task listen method. Below overridden method will be used to register helpers/utilities.
Function instantiateLibs()
End Function


' Checks the backend response to see if backend returned a error code with expired token.
Function checkIfTokenExpiredOrInvalidError(response)
  if response <> invalid AND isNonEmptyString(response.data) = true
    parsedResponse = parseJson(response.data)
    if isAA(parsedResponse) = true AND (parsedResponse["code"] = m.constants.errors.codes.expiredToken OR parsedResponse["code"] = m.constants.errors.codes.invalidToken)
      return true
    end if
  end if

  return false
End Function


Function onAuthUpdatedFailure()
  ' If auth update failed we need to clear out any backed off jobs that were waiting for the updated auth info so the user can know the request failed if appropriate
  for each requestId in m.backedOffJobs
    job = m.backedOffJobs[requestId].job
    reqInfo = job.reqInfo
    requestType = reqInfo.requestType
    if m.constants.reqNames.acceptsTubiAuth[requestType] = true then
      callbackTypes = m.requestTypes[requestType]
      if callbackTypes <> invalid then
        errCode = -1238

        result = {
          response: {
            "code": errCode
            "name": requestType
            "failReason": "Auth update failed"
            "url": job.reqInfo.url
          }
        }

        processErrorResponse(result, callbackTypes, job)
      end if

      m.backedOffJobs.delete(requestId)
    end if
  end for
End Function
