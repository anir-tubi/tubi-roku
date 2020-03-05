' GeneralTaskHelper 
'
' module for creating RequestNode and interacting with GeneralTask 
' @context : m variable of caller context is passed as param
' module will be appended back to caller context (because some of the private methods are going to accessed using caller context)
Function GeneralTaskHelper(context)

  module = {
    ' public
    makeTaskRequest: generalTask_makeTaskRequest
    
    ' private
    generalTaskCallbacks: {} 
    getGeneralTaskSuccessCallback: generalTask_getSuccessCallback
    getGeneralTaskErrorCallback: generalTask_getErrorCallback
    unobserveGeneralTaskFields: generalTask_unobserveFields
    storeGeneralTaskCallbacks: generalTask_storeCallbacks
  }
  
  ' required - this loop helps to check the GeneralTaskHelper methods/properties with context methods/properties
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


' generalTask_makeTaskRequest
'
' public method, which dynamically creates RequestNode with response & error fields and sets request field of Task Node
' @name : String, name of the request api
' @url : String, url of the request api
' @options : AA, options will have query params, method(request method)
' @task : Task, GeneralTask created instance
' @successCallback : Function, sucess callback method name
' @errorCallback : Function, error callback method name
' @responseType : String, type of the response (eg. node/AA/string etc)
Function generalTask_makeTaskRequest(requestType, url, options, task, successCallback, errorCallback, responseType)

  roDeviceInfo = CreateObject("roDeviceInfo")
  randomId = roDeviceInfo.GetRandomUUID()

  requestNode = CreateObject("roSGNode", "RequestNode")
  requestNode.id = randomId
  
  requestNode.addField("response", responseType, false)
  requestNode.observeField("response", "successCallbackWrapper")

  requestNode.addField("error", "node", false)
  requestNode.observeField("error", "errorCallbackWrapper")
  
  m.storeGeneralTaskCallbacks(requestNode, successCallback, errorCallback)
  
  requestNode.input = {"requestType" : requestType, "url" : url, "options" : options}
  task.request = requestNode
  
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
  callback(error)  

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