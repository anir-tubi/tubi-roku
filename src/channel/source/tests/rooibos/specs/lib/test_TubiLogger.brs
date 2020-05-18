Function TestSuite_TubiLogger()
  this = BaseTestSuite()
  this.name = "TubiLoggerTestSuite"
  this.addTest("getLogPrintout", testCase_tubiLogger_getLogPrintout)
  this.addTest("buildLogInfo", testCase_tubiLogger_buildLogInfo)
  this.addTest("getLoggingRequest", testCase_tubiLogger_getLoggingRequest)
  this.addTest("sendLogging", testCase_tubiLogger_sendLogging)
  return this
End Function


Function testCase_tubiLogger_getLogPrintout()
  constants = getConstants()
  request = TubiRequest()
  auth = TubiAuth(constants, request)
  log = TubiLogger(constants, request, auth)
  level1 = "warn"
  subtype1 = "some_warn_message"
  message1 = "something kinda went wrong"
  logPrintout1 = log.getLogPrintout(level1, subtype1, message1)
  result = m.assertTrue(type(logPrintout1) = "String")
  result += m.assertTrue(logPrintout1.Instr(0, UCase(level1)) >= 0)
  result += m.assertTrue(logPrintout1.Instr(0, subtype1) >= 0)
  result += m.assertTrue(logPrintout1.Instr(0, message1) >= 0)
  level2 = "warn"
  subtype2 = "second_warn_message"
  message2 = "another thing went wrong"
  logPrintout2 = log.getLogPrintout(level2, subtype2)
  result += m.assertTrue(type(logPrintout2) = "String")
  result += m.assertTrue(logPrintout2.Instr(0, UCase(level2)) >= 0)
  result += m.assertTrue(logPrintout2.Instr(0, subtype2) >= 0)
  result += m.assertTrue(logPrintout2.Instr(0, message2) < 0)
  level3 = "warn"
  subtype3 = "third_warn_message"
  message3 = "last thing went wrong"
  logPrintout3 = log.getLogPrintout(level3)
  result += m.assertTrue(type(logPrintout3) = "String")
  result += m.assertTrue(logPrintout3.Instr(0, UCase(level3)) >= 0)
  result += m.assertTrue(logPrintout3.Instr(0, subtype3) < 0)
  result += m.assertTrue(logPrintout3.Instr(0, message3) < 0)
  return result
End Function


Function testCase_tubiLogger_buildLogInfo()
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
  result = m.assertNotInvalid(logInfo1)
  result += m.assertNotInvalid(logInfo1.level)
  result += m.assertNotInvalid(logInfo1.subtype)
  result += m.assertNotInvalid(logInfo1.message)
  result += m.assertNotInvalid(logInfo1["type"])

  'test in case that subtype is empty string
  message2 = "i have a debug log to build"
  serverType2 = "CLIENT:DEBUG"
  subtype2 = ""
  level2 = "debug"

  logInfo2 = log.buildLogInfo(message2, serverType2, subtype2, level2)
  result += m.assertNotInvalid(logInfo2)
  result += m.assertNotInvalid(logInfo2.level)
  result += m.assertNotInvalid(logInfo2.subtype)
  result += m.assertNotInvalid(logInfo2.message)
  result += m.assertNotInvalid(logInfo2["type"])
  result += m.assertEqual(logInfo2.subtype, "client_generic")
  return result
End Function


Function testCase_tubiLogger_getLoggingRequest()
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
  result = m.assertNotInvalid(logRequest)
  result += m.assertEqual(logRequest.url, constants.urls.datascience.logging)
  result += m.assertTrue(type(logRequest.body) = "String")
  result += m.assertTrue(logRequest.body.len() > 0)
  logRequestBody = ParseJson(logRequest.body)
  result += m.assertNotInvalid(logRequestBody["app_id"])
  result += m.assertNotInvalid(logRequestBody.platform)
  result += m.assertNotInvalid(logRequestBody["device_id"])
  result += m.assertNotInvalid(logRequestBody.ua)
  result += m.assertNotInvalid(logRequestBody.version)
  result += m.assertNotInvalid(logRequestBody.message)
  result += m.assertNotInvalid(logRequestBody.level)
  result += m.assertNotInvalid(logRequestBody.subtype)
  result += m.assertNotInvalid(logRequestBody["type"])
  result += m.assertEqual(logRequest.method, constants.reqTypes.post)
  return result
End Function

Function testCase_tubiLogger_sendLogging()
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
  result = m.assertNotInvalid(logResult1)
  result += m.assertTrue(requestQueue.queue.count() > 0)
  requestQueue.queue = []  'reset for next tests

  'test a log with no message
  logInfo2 = log.buildLogInfo("", errorServerType, subtype, errorLevel)
  logResult2 = log.sendLogging(logInfo2, requestQueue)
  result += m.assertInvalid(logResult2)
  result += m.assertTrue(requestQueue.queue.count() = 0)
  requestQueue.queue = []  'reset for next tests

  'test a log with an invalid serverType
  badServerType = invalid
  logInfo3 = log.buildLogInfo(message, badServerType, subtype, errorLevel)
  logResult3 = log.sendLogging(logInfo3, requestQueue)
  result += m.assertInvalid(logResult3)
  result += m.assertTrue(requestQueue.queue.count() = 0)
  requestQueue.queue = []  'reset for next tests

  'test with invalid queue
  logInfo4 = log.buildLogInfo(message, errorServerType, subtype, errorLevel)
  logResult4 = log.sendLogging(logInfo4, invalid)
  result += m.assertInvalid(logResult4)

  'test if log requests are sent for debug
  debugLevel = "debug"
  debugServerType = "CLIENT:DEBUG"
  logInfo5 = log.buildLogInfo(message, debugServerType, subtype, debugLevel)
  logResult5 = log.sendLogging(logInfo5, requestQueue)
  result += m.assertInvalid(logResult5)
  result += m.assertTrue(requestQueue.queue.count() = 0)
  requestQueue.queue = []  'reset for next tests

  'test if log requests are sent for debug when the device id is in constants.idsToSend
  constants.idsToLog.AddReplace(constants.deviceInfo.deviceId, true)
  logInfo6 = log.buildLogInfo(message, debugServerType, subtype, debugLevel)
  logResult6 = log.sendLogging(logInfo6, requestQueue)
  result += m.assertNotInvalid(logResult6)
  result += m.assertTrue(requestQueue.queue.count() > 0)
  requestQueue.queue = []  'reset for next tests
  constants.idsToLog = {}  'reset for next tests

  'test if log requests are sent for info
  infoLevel = "info"
  infoServerType = "CLIENT:INFO"
  logInfo7 = log.buildLogInfo(message, infoServerType, subtype, infoLevel)
  logResult7 = log.sendLogging(logInfo7, requestQueue)
  result += m.assertNotInvalid(logResult7)
  result += m.assertTrue(requestQueue.queue.count() > 0)
  requestQueue.queue = []  'reset for next tests
  constants.idsToLog = {}  'reset for next tests

  'test a valid warn log
  warnLevel = "warn"
  warnServerType = "API:SLOW"
  logInfo8 = log.buildLogInfo(message, warnServerType, subtype, warnLevel)
  logResult8 = log.sendLogging(logInfo8, requestQueue)
  result += m.assertNotInvalid(logResult8)
  result += m.assertTrue(requestQueue.queue.count() > 0)
  requestQueue.queue = []  'reset for next tests
  return result
End Function



' Function testTubiLog()
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
'   m.assertInvalid(loggingTask.logMsg.message)
'   m.assertInvalid(loggingTask.logMsg.serverTypeName)
'   m.assertInvalid(loggingTask.logMsg.subtype)
'   m.assertInvalid(loggingTask.logMsg.level)


'   'test an ivalid log level is set to debug
'   message = "some loggable message"
'   level = "notcool"
'   serverTypeName = "VIDEO:NOTCOOL"
'   subType = "video_uncooled_itself"

'   TubiLog(message, level, serverTypeName, subtype)
'   m.assertNotInvalid(loggingTask.logMsg.message)
'   m.assertNotInvalid(loggingTask.logMsg.serverTypeName)
'   m.assertNotInvalid(loggingTask.logMsg.subtype)
'   m.assertNotInvalid(loggingTask.logMsg.level)
'   m.assertTrue(loggingTask.level = "debug")

' End Function