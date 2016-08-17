Function testCreateHTTPRequestQueue(t As Object)
  t.assertNotInvalid(TubiRequestQueue().create(CreateObject("roMessagePort")))
End Function

Function testPushRequest(t As Object)
  q = TubiRequestQueue().create(CreateObject("roMessagePort"))
  request = TubiRequest().createAsync("http://localhost/")
  id = q.pushRequest(request)
  t.assertEqual(q.Count(), 1)
End Function

Function testClear(t As Object)
  q = TubiRequestQueue().create(CreateObject("roMessagePort"))
  request = TubiRequest().createAsync("http://localhost/")
  q.pushRequest(request)
  q.clear()
  t.assertEqual(q.Count(), 0)
End Function

Function testMaxSize(t As Object)
  q = TubiRequestQueue().create(CreateObject("roMessagePort"), 1)
  r1 = TubiRequest().createAsync("http://localhost/")
  confirm1 = q.pushRequest(r1)
  t.assertEqual(q.Count(), 1)

  r2 = TubiRequest().createAsync("http://localhost/")
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
  q = TubiRequestQueue().create(port)
  request = TubiRequest().createAsync("http://127.0.0.1:65535/", "", { retries: 0 })
  q.pushRequest(request)

  msg = wait(1000, port)
  t.assertNotInvalid(msg)
  response = q.handleEvent(msg)
  t.assertNotInvalid(response)
End Function

Function testTimeout(t As Object)
  ' t = 0
  port = CreateObject("roMessagePort")
  q = TubiRequestQueue().create(port, 10, 1)
  request = TubiRequest().createAsync("http://127.0.0.1:65535/")
  q.pushRequest(request)
  t.assertEqual(q.Count(), 1)
  sleep(500)

  ' t = 1
  request = TubiRequest().createAsync("http://127.0.0.1:65535/")
  q.pushRequest(request)
  t.assertEqual(q.Count(), 2)
  sleep(1000)

  ' t = 3
  t.assertEqual(q.Count(), 1)
  sleep(1000)

  ' t = 4
  t.assertEqual(q.Count(), 0)
End Function

