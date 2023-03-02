' GeneralTaskModule
'
' module for creating callback node and interacting with GeneralTask
' @context : m variable of caller context is passed as param
' module will be appended back to caller context (because some of the private methods are going to accessed using caller context)
Function GeneralTaskModule(context, generalTask)

  module = {
    ' public
    makeRequest: generalTask_makeRequest
    makeBatchRequest: generalTask_makeBatchRequest
    cancelRequest: generalTask_cancelRequest

    ' private
    generalTask: generalTask
    generalTaskCallbacks: {}
    verifyRequestInfo: generalTask_verifyRequestInfo
    addDefaultRequestValues: generalTask_addDefaultRequestValues
    constructCallbackNode: generalTask_constructCallbackNode
    constructBatchCallbackNode: generalTask_constructBatchCallbackNode
    getGeneralTaskSuccessCallback: generalTask_getSuccessCallback
    getGeneralTaskErrorCallback: generalTask_getErrorCallback
    storeGeneralTaskCallbacks: generalTask_storeCallbacks
    isValidBatchResponseType: generalTask_isValidBatchResponseType
  }

  ' required - this loop helps to check the GeneralTaskModule methods/properties with context methods/properties
  for each key in module
    if context.DoesExist(key)
       print ""
       print "**********************************************************"
       print "IMPORTANT WARNING - YOU ARE OVERWRITING THE EXISTING PROPERTIES/METHODS OF CONTEXT WITH GENERALTASK HELPER"
       print "CHANGE THE PROPERTY/METHOD NAME IN THE CONTEXT TO AVOID OVERWRITING"
       print "**********************************************************"
       print ""
    end if
  end for

  context.append(module)

End Function


' generalTask_constructBatchCallbackNode
'
' private method, which dynamically creates callback node with response & error
' @batchInfo: assocArray, contains information needed to make the request. Expected fields:
'   responseType: String, type of the response data, corresponds to a valid roSGNode field type (eg. "node"/"assocarray"/"string"/"boolean" etc)
Function generalTask_constructBatchCallbackNode(batchInfo = {})
  callbackNode = CreateObject("roSGNode", "Node")
  callbackNode.id = batchInfo.id

  successResponseType = batchInfo.responseType
  if batchInfo.successCallback = invalid or m.isValidBatchResponseType(successResponseType) <> true
    successResponseType = "assocarray"
  end if

  callbackNode.addField("response", successResponseType, true)
  callbackNode.observeFieldScoped("response", "successCallbackWrapper")

  callbackNode.addField("error", "assocarray", false)
  callbackNode.observeFieldScoped("error", "errorCallbackWrapper")

  return callbackNode
End Function


' generalTask_verifyRequestInfo
'
' private method, which verifies we have all of the things we need to successfully handle this request
' @reqInfo: AA, contains information needed to make the request. For list of fields expected look at generalTask_makeRequest @reqInfo documentation
Function generalTask_verifyRequestInfo(reqInfo = {})
  if type(reqInfo) <> "roAssociativeArray" then
    tubiLog("GeneralTask.verifyRequestInfo - request info not of valid type, no request made", "warn")
    return false
  else if isString(reqInfo.url) <> true then
    tubiLog("GeneralTask.verifyRequestInfo - no request url found, no request made", "warn")
    return false
  else if isString(reqInfo.requestType) <> true then
    tubiLog("GeneralTask.verifyRequestInfo - no request type found, no request made", "warn")
    return false
  end if

  if reqInfo.silenceCallbackWarnings <> true then
    reqName = reqInfo.name
    if isString(reqName) = false then
      reqName = "Unknown Request"
    end if

    if isFunction(reqInfo.successCallback) = false then
      tubiLog("No success callback found for request with name " + reqName, "warn")
    end if

    if isFunction(reqInfo.errorCallback) = false then
      tubiLog("No error callback found for request with name " + reqName, "warn")
    end if
  end if

  return true
End Function


' Adds default values that were not passed in the reqInfo and returns it
Function generalTask_addDefaultRequestValues(reqInfo = {})
  if isInteger(reqInfo.retries) = false then
    reqInfo.retries = 3
  end if

  if isNumber(reqInfo.backoffFactor) = false then
    reqInfo.backoffFactor = 2.0
  end if

  if isInteger(reqInfo.pause) = false then
    reqInfo.pause = 500
  end if

  return reqInfo
End Function


' generalTask_constructCallbackNode
'
' private method, which dynamically creates callback node with response & error fields
' @reqInfo: assocArray, contains information needed to make the request. Expected fields:
'   url (required): String, url of the request api
'   requestType (required): String, name of the request api, for example "getHomescreen".
'                           Can be found in constants.reqNames
'   options: AA, options as expected by TubiRequest().createAsync. (For example: method, params, body, headers)
'   successCallback: Function, the function that the render thread will run upon receiving a successful response
'   errorCallback: Function, the function that the render thread will run upon receiving an error response
'   responseType: String, type of the response data, corresponds to a valid roSGNode field type (eg. "node"/"assocarray"/"string"/"boolean" etc)
'   silenceCallbackWarnings: boolean, if no callbacks are provided, prevents warning logs to the console
'                            Use for 'fire and forget' requests like analytics, etc.
Function generalTask_constructCallbackNode(reqInfo = {})
  callbackNode = CreateObject("roSGNode", "Node")
  callbackNode.id = reqInfo.id

  successResponseType = reqInfo.responseType

  if reqInfo.successCallback = invalid then
    if isString(successResponseType) = true AND successResponseType <> "string" then
      tubiLog("GeneralTask.constructCallbackNode - no callback specified. Forcing responseType to string instead of " + successResponseType, "warn")
    end if
    ' In GeneralTask.brs, if there is no parser associated with the reqInfo.requestType (such as for
    ' "fire and forget" requests), the generalTask will set an empty string on the callbackNode's
    ' response field, in order to trigger the success callback observer in GeneralTaskModule.brs
    ' so as to cleanup the callback object stored on m.generalTaskCallbacks[ID].
    ' We need to make sure the successResponseType is a string so the observer will get triggered properly.
    successResponseType = "string"
  end if

  if isString(successResponseType) <> true then
    tubiLog("GeneralTask.constructCallbackNode - no response type found, defaulting to string", "warn")
    successResponseType = "string"
  end if

  callbackNode.addField("response", successResponseType, true)
  callbackNode.observeFieldScoped("response", "successCallbackWrapper")

  callbackNode.addField("error", "assocarray", false)
  callbackNode.observeFieldScoped("error", "errorCallbackWrapper")

  return callbackNode
End Function


' generalTask_makeRequest
'
' public method, which dynamically creates callback node with response & error fields and sets request field of GeneralTask
' @reqInfo: assocArray, contains information needed to make the request. Expected fields:
'   url (required): String, url of the request api
'   requestType (required): String, name of the request api, for example "getHomescreen".
'                           Can be found in constants.reqNames
'   options: AA, options as expected by TubiRequest().createAsync. (For example: method, params, body, headers)
'   successCallback: Function, the function that the render thread will run upon receiving a successful response
'   errorCallback: Function, the function that the render thread will run upon receiving an error response
'   responseType: String, type of the response data, corresponds to a valid roSGNode field type (eg. "node"/"assocarray"/"string"/"boolean" etc)
'   silenceCallbackWarnings: boolean, if no callbacks are provided, prevents warning logs to the console
'                            Use for 'fire and forget' requests like analytics, etc.
'   retries: Integer, tells how many times the api should retry if is fails, overwrites the default number set in addDefaultRequestValues
'   backoffFactor: Float, API Retry request will be made after a delay. this delay logic is decided based on backoffFactor & pause fields. backoffFactor is a multiplier value where total backoff time = backoffFactor * pause, overwrites the default number set in addDefaultRequestValues
'   pause: Integer, api retry will happen after a sleep of below mentioned time in milliseconds, overwrites the default number set in addDefaultRequestValues

'   Additional custom fields can be added to @reqInfo. The GeneralTask parser functions will have access to the reqInfo, allowing
'   information to be passed from the original makeRequest call, all the way through to callbacks.
'   In this way, the callbacks can have some context about what happened to trigger them.
'
Function generalTask_makeRequest(reqInfo = {})
  if m.verifyRequestInfo(reqInfo) = false then
    return invalid
  end if

  reqInfo.id = createObject("roDeviceInfo").getRandomUUID()

  callbackNode = m.constructCallbackNode(reqInfo)
  reqInfo.callbackNode = callbackNode

  m.storeGeneralTaskCallbacks(reqInfo)
  reqInfo.delete("successCallback")
  reqInfo.delete("errorCallback")

  reqInfo = m.addDefaultRequestValues(reqInfo)
  m.generalTask.request = reqInfo

  return reqInfo
End Function


' generalTask_makeBatchRequest
'
' public method, which dynamically creates callback node with response & error fields and sets batchRequest field of GeneralTask
'
' @batchInfo: assocArray, contains information needed to make the request. Expected fields:
'   successCallback: Function, the function that the render thread will run upon receiving a successful response
'   errorCallback: Function, the function that the render thread will run upon receiving an error response
'   responseType: String, type of the response data, corresponds to a valid roSGNode field type (eg. "node"/"assocarray"/"string"/"boolean" etc)
'   silenceCallbackWarnings: boolean, if no callbacks are provided, prevents warning logs to the console
'                            Use for 'fire and forget' requests like analytics, etc.
'   requests: Array of requests to be made. For list of fields expected look at generalTask_makeRequest @reqInfo documentation
'
' returns the final submitted batchInfo or invalid if something went wrong
Function generalTask_makeBatchRequest(batchInfo = {})
  if isAA(batchInfo) = false then
    tubiLog("GeneralTask.makeBatchRequest - request info not of valid type, no request made", "warn")
    return invalid
  else if isString(batchInfo.responseType) = false then
    tubiLog("GeneralTask.makeBatchRequest - no response type found, defaulting to assocarray", "warn")
    batchInfo.responseType = "assocarray"
  end if

  requests = batchInfo.requests
  if isArray(requests) = false then
    tubiLog("GeneralTask.makeBatchRequest - requests key was not an array", "warn")
    return invalid
  end if

  ' Going in reverse order to avoid index getting off if we have to remove a request
  for i = requests.count() - 1 to 0 step -1
    request = requests[i]
    request.silenceCallbackWarnings = true

    ' If verification fails go ahead and kick it out
    if m.verifyRequestInfo(requests[i]) = false then
      requests.delete(i)
    else
      ' Else add in the default values
      requests[i] = m.addDefaultRequestValues(requests[i])
    end if
  end for

  batchInfo.id = createObject("roDeviceInfo").getRandomUUID()

  callbackNode = m.constructBatchCallbackNode(batchInfo)
  batchInfo.callbackNode = callbackNode

  m.storeGeneralTaskCallbacks(batchInfo)
  batchInfo.delete("successCallback")
  batchInfo.delete("errorCallback")

  m.generalTask.batchRequest = batchInfo

  return batchInfo
End Function


' successCallbackWrapper
'
' this callback gets invoked once the value is set in response field of the callback node
' @msg : roSGNodeEvent, will have callback node
Function successCallbackWrapper(msg)
  callbackNode = msg.getRoSGNode()
  callback = m.getGeneralTaskSuccessCallback(callbackNode)

  if callback <> invalid then
    response = msg.getData()
    callback(response)
  end if
End Function


' error callback wrapper
'
' this callback gets invoked once the value is set in error field of the callback node
' @msg : roSGNodeEvent, will have callback node
Function errorCallbackWrapper(msg)
  callbackNode = msg.getRoSGNode()
  callback = m.getGeneralTaskErrorCallback(callbackNode)

  if callback <> invalid then
    error = msg.getData()
    callback(error)
  end if
End Function


' generalTask_cancelRequest
'
' If the request is no longer needed, then this function will send a request to the GeneralTask to cancel the request and remove the callbacks as well
' This should only be used as a public function.
' @reqInfo : AA, reqInfo to be cancelled
Function generalTask_cancelRequest(reqInfo)
  if reqInfo <> invalid then
    m.generalTaskCallbacks.delete(reqInfo.id)
    m.generalTask.cancel = reqInfo
  end if
End Function


' generalTask_getSuccessCallback
'
' @callbackNode: Node has id we use to match it up with the callback
' returns callback method from m.generalTaskCallbacks array and deletes entry.
Function generalTask_getSuccessCallback(callbackNode)
  callback = invalid
  if m.generalTaskCallbacks[callbackNode.id] <> invalid
    callback = m.generalTaskCallbacks[callbackNode.id].successCallback
  end if

  m.generalTaskCallbacks.delete(callbackNode.id)
  return callback
End Function


' generalTask_getErrorCallback
'
' @callbackNode: Node has id we use to match it up with the callback
' returns callback method from m.generalTaskCallbacks array and deletes entry.
Function generalTask_getErrorCallback(callbackNode)
  callback = invalid
  if m.generalTaskCallbacks[callbackNode.id] <> invalid
    callback = m.generalTaskCallbacks[callbackNode.id].errorCallback
  end if

  m.generalTaskCallbacks.delete(callbackNode.id)
  return callback
End Function


' generalTask_storeCallbacks
'
' this method stores success and error callbacks in m.generalTaskCallbacks array
Function generalTask_storeCallbacks(reqInfo)
  callbacks = {}
  callbacks.successCallback = reqInfo.successCallback
  callbacks.errorCallback = reqInfo.errorCallback
  m.generalTaskCallbacks[reqInfo.id] = callbacks
  return callbacks
End Function


' helper function to determine if the successResponseType is valid for a batch response.
Function generalTask_isValidBatchResponseType(responseType)
  if isString(responseType) = true then
    arrayTypes = getArrayInterfaceTypes()

    responseType = Lcase(responseType)
    if arrayTypes[responseType] <> invalid or responseType = "node" or responseType = "assocarray"
      return true
    end if
  end if

  return false
End Function


' returns an AA of all the interface types that are arrays (not including a single vector2D)
Function getArrayInterfaceTypes()
  return {
    "floatarray": true
    "intarray": true
    "boolarray": true
    "stringarray": true
    "vector2darray": true
    "colorarray": true
    "timearray": true
    "nodearray": true
    "array": true
  }
End Function
