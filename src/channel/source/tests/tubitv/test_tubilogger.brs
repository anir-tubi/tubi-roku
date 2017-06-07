Function testGetLogPrintout(t As Object)
  constants = getConstants()
  request = TubiRequest()
  auth = TubiAuth(constants, request)
  log = TubiLogger(constants, request, auth)

  level1 = "warn"
  subtype1 = "some_warn_message"
  message1 = "something kinda went wrong"

  logPrintout1 = log.getLogPrintout(level1, subtype1, message1)
  t.assertTrue(type(logPrintout1) = "String")
  t.assertTrue(logPrintout1.Instr(0, UCase(level1)) >= 0)
  t.assertTrue(logPrintout1.Instr(0, subtype1) >= 0)
  t.assertTrue(logPrintout1.Instr(0, message1) >= 0)


  level2 = "warn"
  subtype2 = "second_warn_message"
  message2 = "another thing went wrong"

  logPrintout2 = log.getLogPrintout(level2, subtype2)
  t.assertTrue(type(logPrintout2) = "String")
  t.assertTrue(logPrintout2.Instr(0, UCase(level2)) >= 0)
  t.assertTrue(logPrintout2.Instr(0, subtype2) >= 0)
  t.assertTrue(logPrintout2.Instr(0, message2) < 0)


  level3 = "warn"
  subtype3 = "third_warn_message"
  message3 = "last thing went wrong"

  logPrintout3 = log.getLogPrintout(level3)
  t.assertTrue(type(logPrintout3) = "String")
  t.assertTrue(logPrintout3.Instr(0, UCase(level3)) >= 0)
  t.assertTrue(logPrintout3.Instr(0, subtype3) < 0)
  t.assertTrue(logPrintout3.Instr(0, message3) < 0)

End Function


Function testBuildLogInfo(t as Object)
  constants = getConstants()
  request = TubiRequest()
  auth = TubiAuth(constants, request)
  log = TubiLogger(constants, request, auth)

  'test normal use
  message1 = "i have an info log to build"
  serverType1 = "CLIENT:INFO"
  subtype1 = "passing_message"
  level1 = "info"

  logInfo1 = log.buildLogInfo(message1, serverType1, subtype1, level1)
  t.assertNotInvalid(logInfo1)
  t.assertNotInvalid(logInfo1.level)
  t.assertNotInvalid(logInfo1.subtype)
  t.assertNotInvalid(logInfo1.message)
  t.assertNotInvalid(logInfo1["type"])

  'test in case that subtype is empty string
  message2 = "i have a debug log to build"
  serverType2 = "CLIENT:DEBUG"
  subtype2 = ""
  level2 = "debug"

  logInfo2 = log.buildLogInfo(message2, serverType2, subtype2, level2)
  t.assertNotInvalid(logInfo2)
  t.assertNotInvalid(logInfo2.level)
  t.assertNotInvalid(logInfo2.subtype)
  t.assertNotInvalid(logInfo2.message)
  t.assertNotInvalid(logInfo2["type"])
  t.assertEqual(logInfo2.subtype, "client_generic")

End Function


Function testGetLoggingRequest(t as Object)
  constants = getConstants()
  request = TubiRequest()
  auth = TubiAuth(constants, request)
  log = TubiLogger(constants, request, auth)

  message = "super important message to log"
  serverType = "API:ERROR"
  subtype = "403_code"
  level = "error"

  logInfo = log.buildLogInfo(message, serverType, subtype, level)
  logRequest = log.getLoggingRequest(logInfo)

  t.assertNotInvalid(logRequest)
  t.assertEqual(logRequest.url, constants.urls.datascience.logging)
  t.assertTrue(type(logRequest.body) = "String")
  t.assertTrue(logRequest.body.len() > 0)

  logRequestBody = ParseJson(logRequest.body)
  t.assertNotInvalid(logRequestBody["app_id"])
  t.assertNotInvalid(logRequestBody.platform)
  t.assertNotInvalid(logRequestBody["device_id"])
  t.assertNotInvalid(logRequestBody.ua)
  t.assertNotInvalid(logRequestBody.version)
  t.assertNotInvalid(logRequestBody.message)
  t.assertNotInvalid(logRequestBody.level)
  t.assertNotInvalid(logRequestBody.subtype)
  t.assertNotInvalid(logRequestBody["type"])

  t.assertEqual(logRequest.method, constants.reqTypes.post)
End Function



Function testSendLogging(t as Object)
  constants = getConstants()
  request = TubiRequest()
  auth = TubiAuth(constants, request)
  log = TubiLogger(constants, request, auth)
  port = CreateObject("roMessagePort")
  requestQueue = TubiRequestQueue().create(port, 0, 30)


  'custom pushRequest method so we don't fire the request and remove the request from the queue
  'once it is added in log.sendLogging()
  requestQueue.pushRequest = function(request)
    if request = invalid or request["klass"] <> "TubiAsyncHTTPRequest"
      tubiLog("Invalid object attempted to push to request queue")
      return invalid
    else
      ' push to queue only if there is room
      if m.maxSize = 0 or m.queue.Count() < m.maxSize then
        m.queue.Push(m.WrapRequest_(request))
        return request
      end if
    end if
    return invalid
  end function

  message = "super important message to log"
  subtype = "403_code"
  errorServerType = "API:ERROR"
  errorLevel = "error"
  
  'test a valid error log
  logInfo1 = log.buildLogInfo(message, errorServerType, subtype, errorLevel)
  logResult1 = log.sendLogging(logInfo1, requestQueue)

  t.assertNotInvalid(logResult1)
  t.assertTrue(requestQueue.queue.count() > 0)
  requestQueue.queue = []  'reset for next tests

  'test a log with no message
  logInfo2 = log.buildLogInfo("", errorServerType, subtype, errorLevel)
  logResult2 = log.sendLogging(logInfo2, requestQueue)

  t.assertInvalid(logResult2)
  t.assertTrue(requestQueue.queue.count() = 0)
  requestQueue.queue = []  'reset for next tests


  'test a log with an invalid serverType
  badServerType = invalid
  logInfo3 = log.buildLogInfo(message, badServerType, subtype, errorLevel)
  logResult3 = log.sendLogging(logInfo3, requestQueue)

  t.assertInvalid(logResult3)
  t.assertTrue(requestQueue.queue.count() = 0)
  requestQueue.queue = []  'reset for next tests


  'test with invalid queue
  logInfo4 = log.buildLogInfo(message, errorServerType, subtype, errorLevel)
  logResult4 = log.sendLogging(logInfo4, invalid)
  
  t.assertInvalid(logResult4)


  'test if log requests are sent for debug
  debugLevel = "debug"
  debugServerType = "CLIENT:DEBUG"
  logInfo5 = log.buildLogInfo(message, debugServerType, subtype, debugLevel)
  logResult5 = log.sendLogging(logInfo5, requestQueue)

  t.assertInvalid(logResult5)
  t.assertTrue(requestQueue.queue.count() = 0)
  requestQueue.queue = []  'reset for next tests


  'test if log requests are sent for debug when the device id is in constants.idsToSend
  constants.idsToLog.AddReplace(constants.deviceInfo.deviceId, true)
  logInfo6 = log.buildLogInfo(message, debugServerType, subtype, debugLevel)
  logResult6 = log.sendLogging(logInfo6, requestQueue)

  t.assertNotInvalid(logResult6)
  t.assertTrue(requestQueue.queue.count() > 0)
  requestQueue.queue = []  'reset for next tests
  constants.idsToLog = {}  'reset for next tests


  'test if log requests are sent for info
  infoLevel = "info"
  infoServerType = "CLIENT:INFO"
  logInfo7 = log.buildLogInfo(message, infoServerType, subtype, infoLevel)
  logResult7 = log.sendLogging(logInfo7, requestQueue)

  t.assertInvalid(logResult7)
  t.assertTrue(requestQueue.queue.count() = 0)
  requestQueue.queue = []  'reset for next tests


  'test if log requests are sent for info when the device id is in constants.idsToSend
  constants.idsToLog.AddReplace(constants.deviceInfo.deviceId, true)
  logInfo8 = log.buildLogInfo(message, infoServerType, subtype, infoLevel)
  logResult8 = log.sendLogging(logInfo8, requestQueue)

  t.assertNotInvalid(logResult8)
  t.assertTrue(requestQueue.queue.count() > 0)
  requestQueue.queue = []  'reset for next tests
  constants.idsToLog = {}  'reset for next tests


  'test a valid warn log
  warnLevel = "warn"
  warnServerType = "API:SLOW"
  logInfo9 = log.buildLogInfo(message, warnServerType, subtype, warnLevel)
  logResult9 = log.sendLogging(logInfo9, requestQueue)

  t.assertNotInvalid(logResult9)
  t.assertTrue(requestQueue.queue.count() > 0)
  requestQueue.queue = []  'reset for next tests

End Function



' Function testTubiLog(t as Object)
'   screen = CreateObject("roSGScreen")
'   scene = screen.CreateScene("Scene")
'   port = CreateObject("roMessagePort")
'   screen.SetMessagePort(port)
'   screen.Show()

'   loggingTask = scene.createChild("TrackingLoggingTask")
'   loggingTask.control = "RUN"

'   ' make sure the logging task is ready
'   timer = CreateObject("roTimeSpan")
'   while loggingTask.ready <> true
'     sleep(500)
'     if timer.TotalSeconds() > 5
'       exit while
'     end if
'   end while

'   'test that only logging a message does not trigger the process to send the log to the server
'   TubiLog("simpleLog")
'   t.assertInvalid(loggingTask.logMsg.message)
'   t.assertInvalid(loggingTask.logMsg.serverTypeName)
'   t.assertInvalid(loggingTask.logMsg.subtype)
'   t.assertInvalid(loggingTask.logMsg.level)


'   'test an ivalid log level is set to debug
'   message = "some loggable message"
'   level = "notcool"
'   serverTypeName = "VIDEO:NOTCOOL"
'   subType = "video_uncooled_itself"

'   TubiLog(message, level, serverTypeName, subtype)
'   t.assertNotInvalid(loggingTask.logMsg.message)
'   t.assertNotInvalid(loggingTask.logMsg.serverTypeName)
'   t.assertNotInvalid(loggingTask.logMsg.subtype)
'   t.assertNotInvalid(loggingTask.logMsg.level)
'   t.assertTrue(loggingTask.level = "debug")

' End Function