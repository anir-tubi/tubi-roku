Function TestSuite_Request()
  this = BaseTestSuite()
  this.Name = "RequestTestSuite"
  this.addTest("createAsync", testCase_request_createAsync)
  this.addTest("start_withPort", testCase_request_startWithPort)
  this.addTest("start_withUrlTransfer", testCase_request_startWithUrlTransfer)
  this.addTest("cancel", testCase_request_cancel)
  this.addTest("handleEvent", testCase_request_handleEvent)
  this.addTest("addParamsToUrl", testCase_request_addParamsToUrl)
  this.addTest("addParamsToUrl_asModuleFunction", testCase_request_addParamsToUrlAsModuleFunction)
  this.addTest("isHttps", testCase_request_isHttps)
  this.addTest("methods", testCase_request_methods)
  return this
End Function

Function testCase_request_createAsync()
  request = TubiRequest().createAsync("http://localhost/")
  return m.assertNotInvalid(request)
End Function

Function testCase_request_startWithPort()
  request = TubiRequest().createAsync("http://localhost/")
  port = CreateObject("roMessagePort")
  return m.assertTrue(request.start(port))
End Function

Function testCase_request_startWithUrlTransfer()
  request = TubiRequest().createAsync("http://localhost/")
  urltransfer = CreateObject("roUrlTransfer")
  return m.assertTrue(request.start(urltransfer))
End Function

Function testCase_request_cancel()
  request = TubiRequest().createAsync("http://localhost/")
  urltransfer = CreateObject("roUrlTransfer")
  result = m.assertTrue(request.start(urltransfer))
  request.cancel()
  ' sets urltransfer to invalid after cancelling it
  result += m.assertInvalid(request.urltransfer)
  return result
End Function

Function testCase_request_handleEvent()
  request = TubiRequest().createAsync("http://127.0.0.1:65535/", "", { retries: 0 })
  port = CreateObject("roMessagePort")
  result = m.assertTrue(request.start(port))
  msg = wait(1000, port)
  result += m.assertNotInvalid(msg)
  response = request.handleEvent(msg)
  result += m.assertNotInvalid(response)
  return result
End Function

Function testCase_request_addParamsToUrlAsModuleFunction()
  ' Verify that we don't need to use the createAsync factory method in order to use this function
  module = TubiRequest()
  return m.assertEqual( module.addParamsToUrl("http://adrise.tv/", { uid: 0}), "http://adrise.tv/?uid=0")
End Function

Function testCase_request_addParamsToUrl()
  request = TubiRequest().createAsync("http://localhost/")
  testCases = [
    ' URL                     Params        Expected Result
    
    ' Test various forms of params
    [ "http://aaa/",          invalid,         "http://aaa/" ]
    [ "http://aaa/",          {},              "http://aaa/" ]
    [ "http://bbb/",          { a: 1 },        "http://bbb/?a=1" ]
    [ "http://bbb/",          { "a": 1 },      "http://bbb/?a=1" ]
    [ "http://bbb/",          { " a": 1 },     "http://bbb/?a=1" ]
    [ "http://bbb/",          { "a": 1.2 },    "http://bbb/?a=1.2" ]
    [ "http://bbb/",          { "a": "1" },    "http://bbb/?a=1" ]
    [ "http://bbb/",          { "a": invalid },"http://bbb/?a=" ]
    [ "http://bbb/",          { invalid: 0 },  "http://bbb/?invalid=0" ]  ' this is funny... invalid is changed into a string by the compiler
    [ "http://eee/",          { y: 1, z: 2 },  "http://eee/?y=1&z=2" ]
    ' EncodeUriComponent() escapes the square brackets, which isn't necessary but is accepted at the service
    [ "http://eee/",          { "a": [1, 2, 3], "b": 4 }, "http://eee/?a%5B%5D=1&a%5B%5D=2&a%5B%5D=3&b=4" ]

    ' Test handling of query string existence in base url
    [ "http://adrise.tv",        { a: 1 },     "http://adrise.tv?a=1" ]
    [ "http://adrise.tv/",       { b: 1 },     "http://adrise.tv/?b=1" ]
    [ "http://adrise.tv/?x",     { c: 1 },     "http://adrise.tv/?x&c=1" ]
    [ "http://adrise.tv/?x&",    { d: 1 },     "http://adrise.tv/?x&d=1" ]
    [ "http://adrise.tv/?x=",    { e: 1 },     "http://adrise.tv/?x=&e=1" ]
    [ "http://adrise.tv/?x=&",   { f: 1 },     "http://adrise.tv/?x=&f=1" ]
    [ "http://adrise.tv/?x=1",   { g: 1 },     "http://adrise.tv/?x=1&g=1" ]
    [ "http://adrise.tv/?x=1&",  { h: 1 },     "http://adrise.tv/?x=1&h=1" ]
  ]

  result = ""
  for each test in testCases
    result += m.assertEqual( request.addParamsToUrl_(test[0], test[1]), test[2])
  end for
  return result
End Function

Function testCase_request_isHttps()
  request = TubiRequest().createAsync("http://localhost/")
  result = m.assertFalse(request.isHttps)
  request = TubiRequest().createAsync("https://localhost/")
  result += m.assertTrue(request.isHttps)
  return result
End Function

Function testCase_request_methods()
  result = ""
  validMethods = [ "GET", "PUT", "POST", "PATCH", "DELETE" ]

  ' Go through each method, verifying from the server side that the method in the request is correct
  port = CreateObject("roMessagePort")
  server = testHelper_request_createTestServer(65534)
  server.SetMessagePort(port)
  for each method in validMethods
    request = TubiRequest().createAsync("http://127.0.0.1:65534/", "", { method: method })
    request.start(port)
    while true
      msg = wait(500, port)
      if type(msg) = "roSocketEvent" then
        connection = server.accept()
        buffer = connection.receiveStr(512)
        result += m.assertEqual(Left(buffer, method.Len()), method)
        exit while
      else if type(msg) = invalid
        result += m.fail("Timed out waiting for network request")
      end if
    end while
  end for
  return result
End Function

Function testHelper_request_createTestServer(tcpPort As Integer)
  server = CreateObject("roStreamSocket")
  address = CreateObject("roSocketAddress")
  address.setPort(tcpPort)
  server.setAddress(address)
  server.notifyReadable(true)
  server.listen(4)
  return server
End Function

