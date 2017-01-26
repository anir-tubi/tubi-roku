Function testCreateAsyncHTTPReqeust(t As Object)
  request = TubiRequest().createAsync("http://localhost/")
  t.assertNotInvalid(request)
End Function

Function testStartWithPort(t As Object)
  request = TubiRequest().createAsync("http://localhost/")
  port = CreateObject("roMessagePort")
  t.assertTrue(request.start(port))
End Function

Function testStartWithUrlTransfer(t As Object)
  request = TubiRequest().createAsync("http://localhost/")
  urltransfer = CreateObject("roUrlTransfer")
  t.assertTrue(request.start(urltransfer))
End Function

Function testCancel(t As Object)
  request = TubiRequest().createAsync("http://localhost/")
  urltransfer = CreateObject("roUrlTransfer")
  t.assertTrue(request.start(urltransfer))
  request.cancel()
  ' sets urltransfer to invalid after cancelling it
  t.assertInvalid(request.urltransfer)
End Function

Function testHandleEvent(t As Object)
  request = TubiRequest().createAsync("http://127.0.0.1:65535/", "", { retries: 0 })
  port = CreateObject("roMessagePort")
  t.assertTrue(request.start(port))
  msg = wait(1000, port)
  t.assertNotInvalid(msg)
  response = request.handleEvent(msg)
  t.assertNotInvalid(response)
End Function

Function testAddParamsToUrlAsModuleFunction(t As Object)
  ' Verify that we don't need to use the createAsync factory method in order to use this function
  module = TubiRequest()
  t.assertEqual( module.addParamsToUrl("http://adrise.tv/", { uid: 0}), "http://adrise.tv/?uid=0")
End Function

Function testAddParamsToUrl(t As Object)
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
    [ "http://eee/",          { y: 1, z: 2 },  "http://eee/?y=1&z=2" ],

    ' Test handling of query string existence in base url
    [ "http://adrise.tv",        { a: 1 },     "http://adrise.tv?a=1" ],
    [ "http://adrise.tv/",       { b: 1 },     "http://adrise.tv/?b=1" ],
    [ "http://adrise.tv/?x",     { c: 1 },     "http://adrise.tv/?x&c=1" ],
    [ "http://adrise.tv/?x&",    { d: 1 },     "http://adrise.tv/?x&d=1" ],
    [ "http://adrise.tv/?x=",    { e: 1 },     "http://adrise.tv/?x=&e=1" ],
    [ "http://adrise.tv/?x=&",   { f: 1 },     "http://adrise.tv/?x=&f=1" ],
    [ "http://adrise.tv/?x=1",   { g: 1 },     "http://adrise.tv/?x=1&g=1" ],
    [ "http://adrise.tv/?x=1&",  { h: 1 },     "http://adrise.tv/?x=1&h=1" ],
  ]

  for each test in testCases
    t.assertEqual( request.addParamsToUrl_(test[0], test[1]), test[2])
  end for
End Function

Function testIsHttps(t As Object)
  request = TubiRequest().createAsync("http://localhost/")
  t.assertFalse(request.isHttps)
  request = TubiRequest().createAsync("https://localhost/")
  t.assertTrue(request.isHttps)
End Function

Function testMethods(t As Object)
  port = CreateObject("roMessagePort")
  server = createTestServer(65534)
  server.SetMessagePort(port)

  ' Go through each method, verifying from the server side that the method in the request is correct
  for each method in [ "GET", "PUT", "POST", "PATCH", "DELETE" ]
    request = TubiRequest().createAsync("http://127.0.0.1:65534/", "", { method: method })
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

