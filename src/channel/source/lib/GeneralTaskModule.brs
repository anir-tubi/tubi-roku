' GeneralTaskModule 
'
' module for creating RequestNode and interacting with GeneralTask 
' @context : m variable of caller context is passed as param
' module will be appended back to caller context (because some of the private methods are going to accessed using caller context)
Function GeneralTaskModule(context, generalTask)

  module = {
    ' public
    makeRequest: generalTask_makeRequest
    cancelRequest: generalTask_cancelRequest
    
    ' private
    generalTask: generalTask
    generalTaskCallbacks: {} 
    getGeneralTaskSuccessCallback: generalTask_getSuccessCallback
    getGeneralTaskErrorCallback: generalTask_getErrorCallback
    unobserveGeneralTaskFields: generalTask_unobserveFields
    storeGeneralTaskCallbacks: generalTask_storeCallbacks
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


' generalTask_makeRequest
'
' public method, which dynamically creates RequestNode with response & error fields and sets request field of Task Node
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
'
' returns an instance of a RequestNode
' Function generalTask_makeRequest(requestType, url, options, successCallback, errorCallback, responseType)
Function generalTask_makeRequest(reqInfo = {})
  if type(reqInfo) <> "roAssociativeArray"
    tubiLog("GeneralTask.makeRequest - request info not of valid type, no request made", "warn")
    return invalid
  else if isString(reqInfo.url) <> true
    tubiLog("GeneralTask.makeRequest - no request url found, no request made", "warn")
    return invalid
  else if isString(reqInfo.requestType) <> true
    tubiLog("GeneralTask.makeRequest - no request type found, no request made", "warn")
    return invalid
  else if isString(reqInfo.responseType) <> true
    tubiLog("GeneralTask.makeRequest - no response type found, defaulting to string", "warn")
    reqInfo.responseType = "string"
  end if

  roDeviceInfo = CreateObject("roDeviceInfo")
  randomId = roDeviceInfo.GetRandomUUID()

  requestNode = CreateObject("roSGNode", "RequestNode")
  requestNode.id = randomId
  
  requestNode.addField("response", reqInfo.responseType, false)
  requestNode.observeField("response", "successCallbackWrapper")

  requestNode.addField("error", "assocarray", false)
  requestNode.observeField("error", "errorCallbackWrapper")
  
  successCallback = reqInfo.successCallback
  errorCallback = reqInfo.errorCallback
  m.storeGeneralTaskCallbacks(requestNode, successCallback, errorCallback)

  reqInput = reqInfo
  reqInput.delete("successCallback")
  reqInput.delete("errorCallback")
  
  requestNode.input = reqInput
  m.generalTask.request = requestNode
  
  return requestNode
End Function


' successCallbackWrapper
' 
' this callback gets invoked once the value is set in response field of RequestNode
' @msg : roSGNodeEvent, will have RequestNode
Function successCallbackWrapper(msg)

  requestNode = msg.getRoSGNode()
  requestNode.status = "success"
  response = requestNode.response
  m.unobserveGeneralTaskFields(requestNode)
  callback = m.getGeneralTaskSuccessCallback(requestNode)
  
  if callback <> invalid
    callback(response)
  else if requestNode.input.silenceCallbackWarnings <> true
    reqName = "Unknown Request"
    if requestNode <> invalid and requestNode.input <> invalid and isString(requestNode.input.name)
      reqName = requestNode.input.name
    end if
    tubiLog("No success callback found for request with name " + reqName, "warn")
  end if

End Function


' error callback wrapper 
'
' this callback gets invoked once the value is set in error field of RequestNode
' @msg : roSGNodeEvent, will have RequestNode
Function errorCallbackWrapper(msg)

  requestNode = msg.getRoSGNode()
  requestNode.status = "error"
  error = requestNode.error
  m.unobserveGeneralTaskFields(requestNode)
  callback = m.getGeneralTaskErrorCallback(requestNode)

  if callback <> invalid
    callback(error)
  else if requestNode.input.silenceCallbackWarnings <> true
    reqName = "Unknown Request"
    if requestNode <> invalid and requestNode.input <> invalid and isString(requestNode.input.name)
      reqName = requestNode.input.name
    end if
    tubiLog("No success callback found for request with name " + reqName, "warn")
  end if

End Function


' generalTask_cancelRequest
' 
' If the request is no longer needed, then this function will unobserve the relevant fields on the RequestNode and no callbacks will be called. The actual request may still return a response, but we will no longer do anything upon receiving the response.
' This should only be used as a public function.
' @requestNode : RequestNode, the node that should be canceled
Function generalTask_cancelRequest(requestNode)
  if requestNode <> invalid
    requestNode.status = "canceled"
    m.unobserveGeneralTaskFields(requestNode)
  end if 
End Function


' generalTask_unobserveFields 
'
' will unobserve both response & error fields from RequestNode
' @requestNode : ContentNode, will have input, response, error fields
Function generalTask_unobserveFields(requestNode)

  requestNode.unobserveField("response")
  requestNode.unobserveField("error")

End Function


' generalTask_getSuccessCallback 
' 
' @requestNode : ContentNode, it has input, response, error fields
' returns callback method from m.generalTaskCallbacks array and deletes entry.
Function generalTask_getSuccessCallback(requestNode)

  callback = invalid
  if m.generalTaskCallbacks[requestNode.id] <> invalid
    callback = m.generalTaskCallbacks[requestNode.id].successCallback
  end if
  m.generalTaskCallbacks.delete(requestNode.id)
  return callback

End Function


' generalTask_getErrorCallback
'
' @requestNode : ContentNode, it has have input, response, error fields
' returns callback method from m.generalTaskCallbacks array and deletes entry.
Function generalTask_getErrorCallback(requestNode)

  callback = invalid
  if m.generalTaskCallbacks[requestNode.id] <> invalid
    callback = m.generalTaskCallbacks[requestNode.id].errorCallback
  end if
  m.generalTaskCallbacks.delete(requestNode.id)
  return callback

End Function


' generalTask_storeCallbacks 
' 
' this method stores success and error callbacks in m.generalTaskCallbacks array
Function generalTask_storeCallbacks(requestNode, successCallback, errorCallback)
  
  callbacks = {}
  callbacks.successCallback = successCallback
  callbacks.errorCallback = errorCallback
  m.generalTaskCallbacks[requestNode.id] = callbacks
  return callbacks

End Function