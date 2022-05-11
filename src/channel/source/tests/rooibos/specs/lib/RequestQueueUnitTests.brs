'@TestSuite [TubiRequestQueue] RequestQueue.brs

'@Setup
Function TubiRequestQueueSetup()
  m.sLocalHostURL = "http://localhost/"
  m.sInvalidURL = "http://127.0.0.1:65535/"
End Function


'@BeforeEach
Function tubiRequestQueue_BeforeEach() as void
  m.request = TubiRequest().createAsync(m.sLocalHostURL)
  m.port = CreateObject("roMessagePort")
End Function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in RequestQueue.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test create unit tests
Function tubiRequestQueue_create_test()
  m.AssertNotInvalid(TubiRequestQueue().create(m.port))
End Function


'@Test pushRequest unit tests
Function tubiRequestQueue_pushRequest_test()
  q = TubiRequestQueue().create(m.port)
  q.pushRequest(m.request)
  m.AssertEqual(q.Count(), 1)
End Function


'@Test cancelRequest unit tests
Function tubiRequestQueue_cancelRequest_test()
  q = TubiRequestQueue().create(m.port)
  q.pushRequest(m.request)
  m.AssertEqual(q.Count(), 1)

  q.cancelRequest(m.request)
  m.AssertEqual(q.Count(), 0)
End Function


'@Test clear unit tests
Function tubiRequestQueue_clear_test()
  q = TubiRequestQueue().create(m.port)
  q.pushRequest(m.request)
  q.clear()
  m.AssertEqual(q.Count(), 0)
End Function


'@Test maxSize unit tests
Function tubiRequestQueue_maxSize_test()
  q = TubiRequestQueue().create(m.port, 1)
  r1 = m.request

  q.pushRequest(r1)
  m.AssertEqual(q.Count(), 1)

  r2 = TubiRequest().createAsync(m.sLocalHostURL)
  confirm2 = q.pushRequest(r2)
  m.AssertInvalid(confirm2)
  m.AssertEqual(q.Count(), 1)

  q.clear()
  m.AssertEqual(q.Count(), 0)

  confirm2 = q.pushRequest(r2)
  m.AssertNotInvalid(confirm2)
  m.AssertEqual(q.Count(), 1)
End Function


'@Test handleEvent unit tests
Function tubiRequestQueue_handleEvent_test()
  q = TubiRequestQueue().create(m.port)
  request = TubiRequest().createAsync(m.sInvalidURL, "", { retries: 0 })
  q.pushRequest(request)
  msg = wait(1000, m.port)
  m.AssertNotInvalid(msg)

  response = q.handleEvent(msg)
  m.AssertNotInvalid(response)
End Function


'@Test timeout unit tests
Function tubiRequestQueue_timeout_test()
  ' t = 0
  q = TubiRequestQueue().create(m.port, 10, 3)
  request = TubiRequest().createAsync(m.sInvalidURL)
  q.pushRequest(request)
  m.AssertEqual(q.Count(), 1)
  sleep(2000)

  ' t = 1
  request = TubiRequest().createAsync(m.sInvalidURL)
  q.pushRequest(request)
  m.AssertEqual(q.Count(), 2)
  sleep(2000)

  ' t = 3
  m.AssertEqual(q.Count(), 1)
  sleep(2000)

  ' t = 4
  m.AssertEqual(q.Count(), 0)
End Function
