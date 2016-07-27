Function testCreateAsyncHTTPReqeust(t As Object)
  request = createAsyncHTTPRequest("http://localhost/")
  t.assertNotInvalid(request)
End Function

Function testStartWithPort(t As Object)
  request = createAsyncHTTPRequest("http://localhost/")
  port = CreateObject("roMessagePort")
  t.assertTrue(request.start(port))
End Function

Function testStartWithUrlTransfer(t As Object)
  request = createAsyncHTTPRequest("http://localhost/")
  urltransfer = CreateObject("roUrlTransfer")
  t.assertTrue(request.start(urltransfer))
End Function

Function testCancel(t As Object)
  request = createAsyncHTTPRequest("http://localhost/")
  urltransfer = CreateObject("roUrlTransfer")
  t.assertTrue(request.start(urltransfer))
  request.cancel()
End Function

Function testHandleEvent(t As Object)
  request = createAsyncHTTPRequest("http://127.0.0.1:65535/", "", { retries: 0 })
  port = CreateObject("roMessagePort")
  t.assertTrue(request.start(port))
  msg = wait(1000, port)
  t.assertNotInvalid(msg)
  response = request.handleEvent(msg)
  t.assertNotInvalid(response)
End Function

Function testAddParamsToUrl(t As Object)
  request = createAsyncHTTPRequest("http://localhost/")
  request.urltransfer = CreateObject("roUrlTransfer")

  testCases = [
    ' URL                     Params        Expected Result
    [ "http://aaa/",          {},           "http://aaa/" ]
    [ "http://bbb/",          { a: 1 },     "http://bbb/?a=1" ]
    [ "http://ccc/?a=1",      { b: 2 },     "http://ccc/?a=1&b=2" ],
    [ "http://ddd/?a=1&",     { b: 2 },     "http://ddd/?a=1&b=2" ],
    [ "http://eee/",          { y: 1, z: 2 },     "http://eee/?y=1&z=2" ],
  ]
  for each test in testCases
    t.assertEqual(request.addParamsToUrl_(test[0], test[1]), test[2])
  end for
End Function

Function testIsHttps(t As Object)
  request = createAsyncHTTPRequest("http://localhost/")
  t.assertFalse(request.isHttps)
  request = createAsyncHTTPRequest("https://localhost/")
  t.assertTrue(request.isHttps)
End Function

Function testMethods(t As Object)
  port = CreateObject("roMessagePort")
  server = createTestServer(65534)
  server.SetMessagePort(port)

  ' Go through each method, verifying from the server side that the method in the request is correct
  for each method in [ "GET", "PUT", "POST", "PATCH", "DELETE" ]
    request = createAsyncHTTPRequest("http://127.0.0.1:65534/", "", { method: method })
    request.start(port)
    while true
      msg = wait(500, port)
      if type(msg) = "roSocketEvent" then
        connection = server.accept()
        buffer = connection.receiveStr(512)
        t.assertEqual(Left(buffer, method.Len()), method)
        exit while
      else if type(msg) = invalid
        t.fail()
      end if
    end while
  end for
  
End Function

Function createTestServer(tcpPort As Integer)
  server = CreateObject("roStreamSocket")
  address = CreateObject("roSocketAddress")
  address.setPort(tcpPort)
  server.setAddress(address)
  server.notifyReadable(true)
  server.listen(4)
  return server
End Function

