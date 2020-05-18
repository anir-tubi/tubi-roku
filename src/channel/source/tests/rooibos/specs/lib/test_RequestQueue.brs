Function TestSuite_TubiRequestQueue()
  this = BaseTestSuite()
  this.Name = "TubiRequestQueueTestSuite"
  this.addTest("create", testCase_tubiRequestQueue_create)
  this.addTest("pushRequest", testCase_tubiRequestQueue_pushRequest)
  this.addTest("cancelRequest",testCase_tubiRequestQueue_cancelRequest)
  this.addTest("clear", testCase_tubiRequestQueue_clear)
  this.addTest("maxSize", testCase_tubiRequestQueue_maxSize)
  this.addTest("handleEvent", testCase_tubiRequestQueue_handleEvent)
  this.addTest("timeout", testCase_tubiRequestQueue_timeout)
  return this
End Function

Function testCase_tubiRequestQueue_create()
  return m.assertNotInvalid(TubiRequestQueue().create(CreateObject("roMessagePort")))
End Function

Function testCase_tubiRequestQueue_pushRequest()
  q = TubiRequestQueue().create(CreateObject("roMessagePort"))
  request = TubiRequest().createAsync("http://localhost/")
  id = q.pushRequest(request)
  return m.assertEqual(q.Count(), 1)
End Function

Function testCase_tubiRequestQueue_cancelRequest()
  q = TubiRequestQueue().create(CreateObject("roMessagePort"))
  request = TubiRequest().createAsync("http://localhost/")
  id = q.pushRequest(request)
  result = m.assertEqual(q.Count(), 1)
  q.cancelRequest(request)
  result += m.assertEqual(q.Count(), 0)
  return result
End Function

Function testCase_tubiRequestQueue_clear()
  q = TubiRequestQueue().create(CreateObject("roMessagePort"))
  request = TubiRequest().createAsync("http://localhost/")
  q.pushRequest(request)
  q.clear()
  return m.assertEqual(q.Count(), 0)
End Function

Function testCase_tubiRequestQueue_maxSize()
  q = TubiRequestQueue().create(CreateObject("roMessagePort"), 1)
  r1 = TubiRequest().createAsync("http://localhost/")
  result = ""

  confirm1 = q.pushRequest(r1)
  result += m.assertEqual(q.Count(), 1)

  r2 = TubiRequest().createAsync("http://localhost/")
  confirm2 = q.pushRequest(r2)
  result += m.assertInvalid(confirm2)
  result += m.assertEqual(q.Count(), 1)

  q.clear()
  result += m.assertEqual(q.Count(), 0)

  confirm2 = q.pushRequest(r2)
  result += m.assertNotInvalid(confirm2)
  result += m.assertEqual(q.Count(), 1)
  return result
End Function

Function testCase_tubiRequestQueue_handleEvent()
  port = CreateObject("roMessagePort")
  q = TubiRequestQueue().create(port)
  request = TubiRequest().createAsync("http://127.0.0.1:65535/", "", { retries: 0 })
  q.pushRequest(request)
  msg = wait(1000, port)
  result = m.assertNotInvalid(msg)
  response = q.handleEvent(msg)
  result += m.assertNotInvalid(response)
  return result
End Function

Function testCase_tubiRequestQueue_timeout()
  ' t = 0
  port = CreateObject("roMessagePort")
  q = TubiRequestQueue().create(port, 10, 3)
  request = TubiRequest().createAsync("http://127.0.0.1:65535/")
  q.pushRequest(request)
  result = m.assertEqual(q.Count(), 1)
  sleep(2000)

  ' t = 1
  request = TubiRequest().createAsync("http://127.0.0.1:65535/")
  q.pushRequest(request)
  result += m.assertEqual(q.Count(), 2)
  sleep(2000)

  ' t = 3
  result += m.assertEqual(q.Count(), 1)
  sleep(2000)

  ' t = 4
  result += m.assertEqual(q.Count(), 0)
  return result
End Function
