'@TestSuite [GeneralTaskModule] GeneralTaskModule.brs

'@Setup
Function GeneralTaskModuleSetup()
  generalTask = CreateObject("roSGNode", "BaseGeneralTask")
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

  reqInfo = m.makeRequest({
    requestType: requestType
    url: requestUrl
    options: options
    successCallback: successCallback
    errorCallback: errorCallback
    responseType: responseType
  })

  m.assertNotInvalid(reqInfo)

  ' checks reqInfo[:id]
  m.assertNotEmpty(reqInfo.id)
  expectedUUIDCount = 36
  reqInfoUUIDCount = Len(reqInfo.id)
  m.assertEqual(expectedUUIDCount, reqInfoUUIDCount)

  ' checks response field
  callbackNode = reqInfo.callbackNode
  hasResponseField = callbackNode.hasField("response")
  m.assertTrue(hasResponseField)
  responseType = callbackNode.getFieldType("response")
  m.assertEqual(responseType, "node")

  ' checks error field
  hasErrorField = callbackNode.hasField("error")
  m.assertTrue(hasErrorField)

  ' checks input field
  m.assertEqual(requestType, reqInfo.requestType)
  m.assertEqual(requestUrl, reqInfo.url)
  m.assertEqual(options.params.app_id, reqInfo.options.params.app_id)
  m.assertEqual(options.params.device_id, reqInfo.options.params.device_id)
  m.assertEqual(options.params.platform, reqInfo.options.params.platform)
  m.assertEqual(options.params.type, reqInfo.options.params.type)

End Function


'@Test getGeneralTaskSuccessCallback unit tests
Function generalTaskModule_getGeneralTaskSuccessCallback_test()

  reqInfo = {}
  reqInfo.id = "12345"

  reqInfo.successCallback = onSuccessCallbackTest
  reqInfo.errorCallback = onErrorCallbackTest
  m.storeGeneralTaskCallbacks(reqInfo)

  reqInfo = {}
  reqInfo.id = "12345"
  callback = m.getGeneralTaskSuccessCallback(reqInfo)
  m.assertNotInvalid(callback)
  m.assertEqual(callback, onSuccessCallbackTest)

  reqInfo = {}
  reqInfo.id = "56789"
  callback = m.getGeneralTaskSuccessCallback(reqInfo)
  m.assertInvalid(callback)

End Function


'@Test getGeneralTaskErrorCallback unit tests
Function generalTaskModule_getGeneralTaskErrorCallback_test()

  reqInfo = {}
  reqInfo.id = "12345"
  reqInfo.successCallback = onSuccessCallbackTest
  reqInfo.errorCallback = onErrorCallbackTest
  m.storeGeneralTaskCallbacks(reqInfo)

  reqInfo = {}
  reqInfo.id = "12345"
  callback = m.getGeneralTaskErrorCallback(reqInfo)
  m.assertNotInvalid(callback)
  m.assertEqual(callback, onErrorCallbackTest)

  reqInfo = {}
  reqInfo.id = "56789"
  callback = m.getGeneralTaskErrorCallback(reqInfo)
  m.assertInvalid(callback)

End Function


'@Test storeGeneralTaskCallbacks unit tests
Function generalTaskModule_storeGeneralTaskCallbacks_test()

  reqInfo = {}
  reqInfo.id = "12345"
  reqInfo.successCallback = onSuccessCallbackTest
  reqInfo.errorCallback = onErrorCallbackTest
  callbacks = m.storeGeneralTaskCallbacks(reqInfo)

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


'@Test getArrayInterfaceTypes unit tests
Function generalTaskModule_getArrayInterfaceTypes_test()
  arrayInterfaceTypes = getArrayInterfaceTypes()
  m.AssertNotInvalid(arrayInterfaceTypes.floatarray)
  m.AssertNotInvalid(arrayInterfaceTypes.intarray)
  m.AssertNotInvalid(arrayInterfaceTypes.boolarray)
  m.AssertNotInvalid(arrayInterfaceTypes.stringarray)
  m.AssertNotInvalid(arrayInterfaceTypes.vector2darray)
  m.AssertNotInvalid(arrayInterfaceTypes.colorarray)
  m.AssertNotInvalid(arrayInterfaceTypes.timearray)
  m.AssertNotInvalid(arrayInterfaceTypes.nodearray)
  m.AssertNotInvalid(arrayInterfaceTypes.array)
  m.AssertInvalid(arrayInterfaceTypes.otherarray)
  m.AssertInvalid(arrayInterfaceTypes.node)
  m.AssertInvalid(arrayInterfaceTypes.string)
  m.AssertInvalid(arrayInterfaceTypes.boolean)
End Function
