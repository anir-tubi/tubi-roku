'@TestSuite [GeneralTaskModule] GeneralTaskModule.brs 

'@Setup
Function GeneralTaskModuleSetup()

  generalTask = CreateObject("roSGNode", "GeneralTask")
  GeneralTaskModule(m, generalTask)
   
End function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in GeneralTaskModule.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test makeRequest unit tests
Function generalTaskModule_makeRequest_test()

  requestType = "getThumbnails"
  requestUrl = "https://uapi.adrise.tv/cms/content/458275/thumbnail_sprites"
  
  options = {}
  options.params = {
    app_id: "tubitv"
    device_id: "2366ec6e-7e5e-58e4-96e1-da33e5fb0f73"
    platform: "roku"
    type: "5x"
  }
  
  successCallback = onSuccessCallbackTest
  errorCallback = onErrorCallbackTest
  responseType = "node"
  
  requestNode = m.makeRequest(requestType, requestUrl, options, successCallback, errorCallback, responseType)
  
  m.assertNotInvalid(requestNode)
  
  ' checks requestNode[:id]
  m.assertNotEmpty(requestNode.id)
  expectedUUIDCount = 36
  requestNodeUUIDCount = Len(requestNode.id)
  m.assertEqual(expectedUUIDCount, requestNodeUUIDCount)
  
  ' checks response field
  hasResponseField = requestNode.hasField("response")
  m.assertTrue(hasResponseField)
  responseType = requestNode.getFieldType("response")
  m.assertEqual(responseType, "node")
  
  ' checks error field
  hasErrorField = requestNode.hasField("error")
  m.assertTrue(hasErrorField) 
  
  ' checks input field
  input = requestNode.input
  m.assertEqual(requestType, input.requestType)
  m.assertEqual(requestUrl, input.url)
  m.assertEqual(options.params.app_id, input.options.params.app_id)
  m.assertEqual(options.params.device_id, input.options.params.device_id)
  m.assertEqual(options.params.platform, input.options.params.platform)
  m.assertEqual(options.params.type, input.options.params.type)

End Function


'@Test getGeneralTaskSuccessCallback unit tests
Function generalTaskModule_getGeneralTaskSuccessCallback_test()

  requestNode = CreateObject("roSGNode", "RequestNode")
  requestNode.id = "12345"  
  
  successCallback = onSuccessCallbackTest
  errorCallback = onErrorCallbackTest
  m.storeGeneralTaskCallbacks(requestNode, successCallback, errorCallback)

  requestNode = CreateObject("roSGNode", "RequestNode")
  requestNode.id = "12345"
  callback = m.getGeneralTaskSuccessCallback(requestNode)
  m.assertNotInvalid(callback)
  m.assertEqual(callback, onSuccessCallbackTest)
  
  requestNode = CreateObject("roSGNode", "RequestNode")
  requestNode.id = "56789"
  callback = m.getGeneralTaskSuccessCallback(requestNode)  
  m.assertInvalid(callback)

End Function


'@Test getGeneralTaskErrorCallback unit tests
Function generalTaskModule_getGeneralTaskErrorCallback_test()

  requestNode = CreateObject("roSGNode", "RequestNode")
  requestNode.id = "12345" 
  successCallback = onSuccessCallbackTest
  errorCallback = onErrorCallbackTest
  m.storeGeneralTaskCallbacks(requestNode, successCallback, errorCallback)

  requestNode = CreateObject("roSGNode", "RequestNode")
  requestNode.id = "12345" 
  callback = m.getGeneralTaskErrorCallback(requestNode)
  m.assertNotInvalid(callback)
  m.assertEqual(callback, onErrorCallbackTest)
  
  requestNode = CreateObject("roSGNode", "RequestNode")
  requestNode.id = "56789" 
  callback = m.getGeneralTaskErrorCallback(requestNode)  
  m.assertInvalid(callback)

End Function


'@Test storeGeneralTaskCallbacks unit tests
Function generalTaskModule_storeGeneralTaskCallbacks_test()

  requestNode = CreateObject("roSGNode", "RequestNode")
  requestNode.id = "12345" 
  successCallback = onSuccessCallbackTest
  errorCallback = onErrorCallbackTest
  callbacks = m.storeGeneralTaskCallbacks(requestNode, successCallback, errorCallback)
  
  m.assertNotInvalid(callbacks)
  m.assertEqual(callbacks.successCallback, onSuccessCallbackTest)
  m.assertEqual(callbacks.errorCallback, onErrorCallbackTest)

End Function


' dummy success callback function
Function onSuccessCallbackTest()

End Function


' dummy error callback function
Function onErrorCallbackTest()

End Function