Function testCreateHTTPRequestQueue(t As Object)
  t.assertNotInvalid(createHTTPRequestQueue(CreateObject("roMessagePort")))
End Function

Function testPushRequest(t As Object)
  q = createHTTPRequestQueue(CreateObject("roMessagePort"))
  request = createAsyncHTTPRequest("http://localhost/")
  id = q.pushRequest(request)
  t.assertEqual(q.Count(), 1)
End Function

Function testClear(t As Object)
  q = createHTTPRequestQueue(CreateObject("roMessagePort"))
  request = createAsyncHTTPRequest("http://localhost/")
  q.pushRequest(request)
  q.clear()
  t.assertEqual(q.Count(), 0)
End Function

Function testMaxSize(t As Object)
  q = createHTTPRequestQueue(CreateObject("roMessagePort"), 1)
  r1 = createAsyncHTTPRequest("http://localhost/")
  confirm1 = q.pushRequest(r1)
  t.assertEqual(q.Count(), 1)

  r2 = createAsyncHTTPRequest("http://localhost/")
  confirm2 = q.pushRequest(r2)
  t.assertInvalid(confirm2)
  t.assertEqual(q.Count(), 1)

  q.clear()
  t.assertEqual(q.Count(), 0)

  confirm2 = q.pushRequest(r2)
  t.assertNotInvalid(confirm2)
  t.assertEqual(q.Count(), 1)
  
End Function

Function testQueueHandleEvent(t As Object)
  port = CreateObject("roMessagePort")
  q = createHTTPRequestQueue(port)
  request = createAsyncHTTPRequest("http://127.0.0.1:65535/", "", { retries: 0 })
  q.pushRequest(request)

  msg = wait(1000, port)
  t.assertNotInvalid(msg)
  response = q.handleEvent(msg)
  t.assertNotInvalid(response)
End Function

Function testTimeout(t As Object)
  ' t = 0
  port = CreateObject("roMessagePort")
  q = createHTTPRequestQueue(port, 10, 1)
  request = createAsyncHTTPRequest("http://127.0.0.1:65535/")
  q.pushRequest(request)
  t.assertEqual(q.Count(), 1)
  sleep(500)

  ' t = 1
  request = createAsyncHTTPRequest("http://127.0.0.1:65535/")
  q.pushRequest(request)
  t.assertEqual(q.Count(), 2)
  sleep(1000)

  ' t = 3
  t.assertEqual(q.Count(), 1)
  sleep(1000)

  ' t = 4
  t.assertEqual(q.Count(), 0)
End Function

