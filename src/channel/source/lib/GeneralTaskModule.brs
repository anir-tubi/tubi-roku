' GeneralTaskModule 
'
' module for creating RequestNode and interacting with GeneralTask 
' @context : m variable of caller context is passed as param
' module will be appended back to caller context (because some of the private methods are going to accessed using caller context)
Function GeneralTaskModule(context, generalTask)

  module = {
    ' public
    makeRequest: generalTask_makeRequest
    
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
' @requestType : String, name of the request api, for example "getHomescreen". Can be found in constants.reqNames
' @url : String, url of the request api
' @options : AA, options as expected by TubiRequest().createAsync. (For example: method, params, body, headers)
' @successCallback : Function, the function that the render thread will run upon receiving a successful response
' @errorCallback : Function, the function that the render thread will run upon receiving an error response
' @responseType : String, type of the response data, corresponds to a valid roSGNode field type (eg. "node"/"assocarray"/"string"/"boolean" etc)
Function generalTask_makeRequest(requestType, url, options, successCallback, errorCallback, responseType)

  roDeviceInfo = CreateObject("roDeviceInfo")
  randomId = roDeviceInfo.GetRandomUUID()

  requestNode = CreateObject("roSGNode", "RequestNode")
  requestNode.id = randomId
  
  requestNode.addField("response", responseType, false)
  requestNode.observeField("response", "successCallbackWrapper")

  requestNode.addField("error", "assocarray", false)
  requestNode.observeField("error", "errorCallbackWrapper")
  
  m.storeGeneralTaskCallbacks(requestNode, successCallback, errorCallback)
  
  requestNode.input = {"requestType" : requestType, "url" : url, "options" : options}
  m.generalTask.request = requestNode
  
  return requestNode

End Function


' successCallbackWrapper
' 
' this callback gets invoked once the value is set in response field of RequestNode
' @msg : roSGNodeEvent, will have RequestNode
Function successCallbackWrapper(msg)

  requestNode = msg.getRoSGNode()
  response = requestNode.response
  m.unobserveGeneralTaskFields(requestNode)
  callback = m.getGeneralTaskSuccessCallback(requestNode)
  callback(response)

End Function


' error callback wrapper 
'
' this callback gets invoked once the value is set in error field of RequestNode
' @msg : roSGNodeEvent, will have RequestNode
Function errorCallbackWrapper(msg)

  requestNode = msg.getRoSGNode()
  error = requestNode.error
  m.unobserveGeneralTaskFields(requestNode)
  callback = m.getGeneralTaskErrorCallback(requestNode)

  if callback <> invalid
    callback(error)
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

  callback = m.generalTaskCallbacks[requestNode.id].successCallback
  m.generalTaskCallbacks.delete(requestNode.id)
  return callback

End Function


' generalTask_getErrorCallback
'
' @requestNode : ContentNode, it has have input, response, error fields
' returns callback method from m.generalTaskCallbacks array and deletes entry.
Function generalTask_getErrorCallback(requestNode)

  callback = m.generalTaskCallbacks[requestNode.id].errorCallback
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

End Function