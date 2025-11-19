'@TestSuite [Request] Request.brs

'@Setup
Function RequestSetup()
  m.request = TubiRequest().createAsync("http://localhost/")
  m.port = CreateObject("roMessagePort")
End Function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in Request.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test createAsync unit tests
Function request_createAsync_test()
  m.assertNotInvalid(m.request)
End Function


'@Test startWithPort unit tests
Function request_startWithPort_test()
  m.assertTrue(m.request.start(m.port))
End Function


'@Test startWithUrlTransfer unit tests
Function request_startWithUrlTransfer_test()
  urltransfer = CreateObject("roUrlTransfer")
  m.assertTrue(m.request.start(urltransfer))
End Function


'@Test cancel unit tests
Function request_cancel_test()
  urltransfer = CreateObject("roUrlTransfer")
  m.assertTrue(m.request.start(urltransfer))
  m.request.cancel()
  ' sets urltransfer to invalid after cancelling it
  m.assertInvalid(m.request.urltransfer)
End Function


'@Test handleEvent unit tests
Function request_handleEvent_test()
  request = TubiRequest().createAsync("http://127.0.0.1:65535/", "", { retries: 0 })
  port = CreateObject("roMessagePort")
  m.assertTrue(request.start(port))
  msg = wait(1000, port)
  m.assertNotInvalid(msg)
  response = request.handleEvent(msg)
  m.assertNotInvalid(response)
End Function


'@Test addParamsToUrlAsModuleFunction unit tests
Function request_addParamsToUrlAsModuleFunction_test()
  ' Verify that we don't need to use the createAsync factory method in order to use this function
  module = TubiRequest()
  m.assertEqual(module.addParamsToUrl("http://adrise.tv/", { uid: 0 }), "http://adrise.tv/?uid=0")
End Function


'@Test addParamsToUrl unit tests
'@Params [ "http://aaa/",          invalid,         "http://aaa/" ]
'@Params [ "http://aaa/",          {},              "http://aaa/" ]
'@Params [ "http://bbb/",          { a: 1 },        "http://bbb/?a=1" ]
'@Params [ "http://bbb/",          { "a": 1 },      "http://bbb/?a=1" ]
'@Params [ "http://bbb/",          { " a": 1 },     "http://bbb/?a=1" ]
'@Params [ "http://bbb/",          { "a": 1.2 },    "http://bbb/?a=1.2" ]
'@Params [ "http://bbb/",          { "a": "1" },    "http://bbb/?a=1" ]
'@Params [ "http://bbb/",          { "a": invalid },"http://bbb/?a=" ]
'@Params [ "http://bbb/",          { invalid: 0 },  "http://bbb/?invalid=0" ]
'@Params [ "http://eee/",          { y: 1, z: 2 },  "http://eee/?y=1&z=2" ]
'@Params [ "http://eee/",          { "a": [1, 2, 3], "b": 4 }, "http://eee/?a%5B%5D=1&a%5B%5D=2&a%5B%5D=3&b=4" ]
'@Params [ "http://adrise.tv",        { a: 1 },     "http://adrise.tv?a=1" ]
'@Params [ "http://adrise.tv/",       { b: 1 },     "http://adrise.tv/?b=1" ]
'@Params [ "http://adrise.tv/?x",     { c: 1 },     "http://adrise.tv/?x&c=1" ]
'@Params [ "http://adrise.tv/?x&",    { d: 1 },     "http://adrise.tv/?x&d=1" ]
'@Params [ "http://adrise.tv/?x=",    { e: 1 },     "http://adrise.tv/?x=&e=1" ]
'@Params [ "http://adrise.tv/?x=&",   { f: 1 },     "http://adrise.tv/?x=&f=1" ]
'@Params [ "http://adrise.tv/?x=1",   { g: 1 },     "http://adrise.tv/?x=1&g=1" ]
'@Params [ "http://adrise.tv/?x=1&",  { h: 1 },     "http://adrise.tv/?x=1&h=1" ]
Function request_addParamsToUrl_test(url, params, expectedResult)
  request = TubiRequest().createAsync("http://localhost/")
  m.assertEqual(request.addParamsToUrl_(url, params), expectedResult)
End Function

'@Test passThroughCharlesProxyAsModuleFunction_test unit tests
Function request_passThroughCharlesProxyAsModuleFunction_test()
  module = TubiRequest({ mode: "dev", CharlesProxyEnabled: true, charlesProxyUrl: "http://192.168.68.57:8888" })
  m.assertEqual(module.passThroughCharlesProxy("http://adrise.tv/"), "http://192.168.68.57:8888/;http://adrise.tv/")
End Function

'@Test passThroughCharlesProxy unit tests
'@Params [ "http://adrise.tv",          {mode: "dev", CharlesProxyEnabled: true, charlesProxyUrl:"http://192.168.68.57:8888"},           "http://192.168.68.57:8888/;http://adrise.tv" ]
'@Params [ "",                           {mode: "dev", CharlesProxyEnabled: true, charlesProxyUrl:"http://192.168.68.57:8888"},           "" ]
'@Params [ "http://adrise.tv",          {mode: "production", CharlesProxyEnabled: false, charlesProxyUrl:"http://192.168.68.57:8888"},    "http://adrise.tv" ]
'@Params [ "http://adrise.tv",          {mode: "dev", CharlesProxyEnabled: false, charlesProxyUrl:"http://192.168.68.57:8888"},          "http://adrise.tv" ]
'@Params [ "http://adrise.tv",          {mode: "dev", CharlesProxyEnabled: true, charlesProxyUrl:""},                                    "http://adrise.tv" ]
'@Params [ "http://adrise.tv",          {mode: "dev", CharlesProxyEnabled: false, charlesProxyUrl:""},                                   "http://adrise.tv" ]
Function request_passThroughCharlesProxy_test(url, settings, expectedResult)
  module = TubiRequest(settings)
  m.assertEqual(module.passThroughCharlesProxy(url), expectedResult)
End Function

'@Test removeCharlesProxyAsModuleFunction_test unit tests
Function request_removeCharlesProxyAsModuleFunction_test()
  module = TubiRequest({ mode: "dev", CharlesProxyEnabled: true, charlesProxyUrl: "http://192.168.68.57:8888" })
  m.assertEqual(module.removeCharlesProxy("http://192.168.68.57:8888/;http://adrise.tv/"), "http://adrise.tv/")
End Function

'@Test removeCharlesProxy unit tests
'@Params [ "http://192.168.68.57:8888/;http://adrise.tv",          {mode: "dev", CharlesProxyEnabled: true, charlesProxyUrl:"http://192.168.68.57:8888"},           "http://adrise.tv" ]
'@Params [ "",                                                      {mode: "dev", CharlesProxyEnabled: true, charlesProxyUrl:"http://192.168.68.57:8888"},           "" ]
'@Params [ "http://adrise.tv",                                      {mode: "production", CharlesProxyEnabled: true, charlesProxyUrl:"http://192.168.68.57:8888"},    "http://adrise.tv" ]
'@Params [ "http://adrise.tv",                                      {mode: "dev", CharlesProxyEnabled: false, charlesProxyUrl:"http://192.168.68.57:8888"},          "http://adrise.tv" ]
'@Params [ "http://adrise.tv",                                      {mode: "dev", CharlesProxyEnabled: true, charlesProxyUrl:""},                                    "http://adrise.tv" ]
'@Params [ "http://adrise.tv",                                      {mode: "dev", CharlesProxyEnabled: false, charlesProxyUrl:""},                                   "http://adrise.tv" ]
'@Params [ "http://192.168.68.57:8888/build/local/source/Settings.brs", {mode: "dev", CharlesProxyEnabled: true, charlesProxyUrl:"http://192.168.68.57:8888"},       "http://192.168.68.57:8888/build/local/source/Settings.brs" ]
Function request_removeCharlesProxy_test(url, settings, expectedResult)
  module = TubiRequest(settings)
  m.assertEqual(module.removeCharlesProxy(url), expectedResult)
End Function

'@Test isHttps unit tests
Function request_isHttps_test()
  request = TubiRequest().createAsync("http://localhost/")
  m.assertFalse(request.isHttps)
  request = TubiRequest().createAsync("https://localhost/")
  m.assertTrue(request.isHttps)
End Function


'@Test methods unit tests
Function request_methods_test()
  validMethods = ["GET", "PUT", "POST", "PATCH", "DELETE"]

  ' Go through each method, verifying from the server side that the method in the request is correct
  port = CreateObject("roMessagePort")
  server = request_createTestServer_testHelper(65534)
  server.SetMessagePort(port)
  for each method in validMethods
    request = TubiRequest().createAsync("http://127.0.0.1:65534/", "", { method: method })
    request.start(port)
    while true
      msg = wait(500, port)
      if type(msg) = "roSocketEvent" then
        connection = server.accept()
        buffer = connection.receiveStr(512)
        m.assertEqual(Left(buffer, method.Len()), method)
        exit while
      else if type(msg) = invalid
        m.fail("Timed out waiting for network request")
      end if
    end while
  end for
End Function


Function request_createTestServer_testHelper(tcpPort as Integer)
  server = CreateObject("roStreamSocket")
  address = CreateObject("roSocketAddress")
  address.setPort(tcpPort)
  server.setAddress(address)
  server.notifyReadable(true)
  server.listen(4)
  return server
End Function
