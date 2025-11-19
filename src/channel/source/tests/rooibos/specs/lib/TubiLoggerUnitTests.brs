'@TestSuite [TubiLogger] Log.brs


'@Setup
Function TubiLoggerSetup()
  m.constants = getConstants()
  request = TubiRequest()
  auth = TubiAuth(m.constants)
  m.log = TubiLogger(m.constants, request, auth)
End Function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in Log.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test getLogPrintout unit tests
Function tubiLogger_getLogPrintout_test()
  log = m.log
  level1 = "warn"
  subtype1 = "some_warn_message"
  message1 = "something kinda went wrong"
  logPrintout1 = log.getLogPrintout(level1, subtype1, message1)
  m.assertTrue(type(logPrintout1) = "String")
  m.assertTrue(logPrintout1.Instr(0, UCase(level1)) >= 0)
  m.assertTrue(logPrintout1.Instr(0, subtype1) >= 0)
  m.assertTrue(logPrintout1.Instr(0, message1) >= 0)
  level2 = "warn"
  subtype2 = "second_warn_message"
  message2 = "another thing went wrong"
  logPrintout2 = log.getLogPrintout(level2, subtype2)
  m.assertTrue(type(logPrintout2) = "String")
  m.assertTrue(logPrintout2.Instr(0, UCase(level2)) >= 0)
  m.assertTrue(logPrintout2.Instr(0, subtype2) >= 0)
  m.assertTrue(logPrintout2.Instr(0, message2) < 0)
  level3 = "warn"
  subtype3 = "third_warn_message"
  message3 = "last thing went wrong"
  logPrintout3 = log.getLogPrintout(level3)
  m.assertTrue(type(logPrintout3) = "String")
  m.assertTrue(logPrintout3.Instr(0, UCase(level3)) >= 0)
  m.assertTrue(logPrintout3.Instr(0, subtype3) < 0)
  m.assertTrue(logPrintout3.Instr(0, message3) < 0)
End Function


'@Test buildLogInfo unit tests
Function tubiLogger_buildLogInfo_test()
  log = m.log

  'test normal use
  message1 = "i have an info log to build"
  serverType1 = "CLIENT:INFO"
  subtype1 = "passing_message"
  level1 = "info"
  logInfo1 = log.buildLogInfo(message1, serverType1, subtype1, level1)
  m.assertNotInvalid(logInfo1)
  m.assertNotInvalid(logInfo1.level)
  m.assertNotInvalid(logInfo1.subtype)
  m.assertNotInvalid(logInfo1.message)
  m.assertNotInvalid(logInfo1["type"])

  'test in case that subtype is empty string
  message2 = "i have a debug log to build"
  serverType2 = "CLIENT:DEBUG"
  subtype2 = ""
  level2 = "debug"

  logInfo2 = log.buildLogInfo(message2, serverType2, subtype2, level2)
  m.assertNotInvalid(logInfo2)
  m.assertNotInvalid(logInfo2.level)
  m.assertNotInvalid(logInfo2.subtype)
  m.assertNotInvalid(logInfo2.message)
  m.assertNotInvalid(logInfo2["type"])
  m.assertEqual(logInfo2.subtype, "client_generic")
End Function


'@Test getLoggingRequest unit tests
Function tubiLogger_getLoggingRequest_test()
  log = m.log
  constants = m.constants
  message = "super important message to log"
  serverType = "API:ERROR"
  subtype = "403_code"
  level = "error"
  logInfo = log.buildLogInfo(message, serverType, subtype, level)
  logRequest = log.getLoggingRequest(logInfo)
  m.assertNotInvalid(logRequest)
  m.assertEqual(logRequest.url, constants.urls.analyticsV3.sendEvent)
  m.assertTrue(type(logRequest.body) = "String")
  m.assertTrue(logRequest.body.len() > 0)
  logRequestBody = ParseJson(logRequest.body)
  eventPayLoad = logRequestBody["event_payloads"][0]
  m.assertNotInvalid(eventPayLoad["app_id"])
  m.assertNotInvalid(eventPayLoad.platform)
  m.assertNotInvalid(eventPayLoad["device_id"])
  m.assertNotInvalid(eventPayLoad.version)
  m.assertNotInvalid(eventPayLoad.message)
  m.assertNotInvalid(eventPayLoad.level)
  m.assertNotInvalid(eventPayLoad["log_subtype"])
  m.assertNotInvalid(eventPayLoad["log_type"])
  m.assertEqual(logRequest.method, constants.reqTypes.post)
End Function


'@Test sendLogging unit tests
Function tubiLogger_sendLogging_test()
  log = m.log
  constants = m.constants
  port = CreateObject("roMessagePort")
  requestQueue = TubiRequestQueue().create(port, 0, 30)

  'custom pushRequest method so we don't fire the request and remove the request from the queue
  'once it is added in log.sendLogging()
  requestQueue.pushRequest = Function(request)
    if request = invalid OR request["klass"] <> "TubiAsyncHTTPRequest"
      tubiLog("Invalid object attempted to push to request queue")
      return invalid
    else
      ' push to queue only if there is room
      if m.maxSize = 0 OR m.queue.Count() < m.maxSize then
        m.queue.Push(m.WrapRequest_(request))
        return request
      end if
    end if
    return invalid
  End Function

  message = "super important message to log"
  subtype = "403_code"
  errorServerType = "API:ERROR"
  errorLevel = "error"

  'test a valid error log
  logInfo1 = log.buildLogInfo(message, errorServerType, subtype, errorLevel)
  logResult1 = log.sendLogging(logInfo1, requestQueue)
  m.assertNotInvalid(logResult1)
  m.assertTrue(requestQueue.queue.count() > 0)
  requestQueue.queue = [] 'reset for next tests

  'test a log with no message
  logInfo2 = log.buildLogInfo("", errorServerType, subtype, errorLevel)
  logResult2 = log.sendLogging(logInfo2, requestQueue)
  m.assertInvalid(logResult2)
  m.assertTrue(requestQueue.queue.count() = 0)
  requestQueue.queue = [] 'reset for next tests

  'test a log with an invalid serverType
  badServerType = invalid
  logInfo3 = log.buildLogInfo(message, badServerType, subtype, errorLevel)
  logResult3 = log.sendLogging(logInfo3, requestQueue)
  m.assertInvalid(logResult3)
  m.assertTrue(requestQueue.queue.count() = 0)
  requestQueue.queue = [] 'reset for next tests

  'test with invalid queue
  logInfo4 = log.buildLogInfo(message, errorServerType, subtype, errorLevel)
  logResult4 = log.sendLogging(logInfo4, invalid)
  m.assertInvalid(logResult4)

  'test if log requests are sent for debug
  debugLevel = "debug"
  debugServerType = "CLIENT:DEBUG"
  logInfo5 = log.buildLogInfo(message, debugServerType, subtype, debugLevel)
  logResult5 = log.sendLogging(logInfo5, requestQueue)
  m.assertInvalid(logResult5)
  m.assertTrue(requestQueue.queue.count() = 0)
  requestQueue.queue = [] 'reset for next tests

  'test if log requests are sent for debug when the device id is in constants.idsToSend
  constants.idsToLog.AddReplace(constants.deviceInfo.deviceId, true)
  logInfo6 = log.buildLogInfo(message, debugServerType, subtype, debugLevel)
  logResult6 = log.sendLogging(logInfo6, requestQueue)
  m.assertNotInvalid(logResult6)
  m.assertTrue(requestQueue.queue.count() > 0)
  requestQueue.queue = [] 'reset for next tests
  constants.idsToLog = {} 'reset for next tests

  'test if log requests are sent for info
  infoLevel = "info"
  infoServerType = "CLIENT:INFO"
  logInfo7 = log.buildLogInfo(message, infoServerType, subtype, infoLevel)
  logResult7 = log.sendLogging(logInfo7, requestQueue)
  m.assertNotInvalid(logResult7)
  m.assertTrue(requestQueue.queue.count() > 0)
  requestQueue.queue = [] 'reset for next tests
  constants.idsToLog = {} 'reset for next tests

  'test a valid warn log
  warnLevel = "warn"
  warnServerType = "API:SLOW"
  logInfo8 = log.buildLogInfo(message, warnServerType, subtype, warnLevel)
  logResult8 = log.sendLogging(logInfo8, requestQueue)
  m.assertNotInvalid(logResult8)
  m.assertTrue(requestQueue.queue.count() > 0)
  requestQueue.queue = [] 'reset for next tests
End Function


'@Test isLoggingAllowed unit tests
Function tubiLogger_isLoggingAllowed_test()
  log = m.log
  constants = m.constants
  constants.configHubFallbacks.majorEventStart = invalid
  constants.configHubFallbacks.majorEventEnd = invalid

  constants.settings.clientLogsEnabled = true
  isLoggingAllowed = log.isLoggingAllowed()
  m.assertTrue(isLoggingAllowed)

  constants.settings.clientLogsEnabled = false
  isLoggingAllowed = log.isLoggingAllowed()
  m.assertFalse(isLoggingAllowed)

  constants.settings.clientLogsEnabled = "abc"
  isLoggingAllowed = log.isLoggingAllowed()
  m.assertFalse(isLoggingAllowed)

  constants.settings.clientLogsEnabled = 123
  isLoggingAllowed = log.isLoggingAllowed()
  m.assertFalse(isLoggingAllowed)

  constants.settings.clientLogsEnabled = invalid
  isLoggingAllowed = log.isLoggingAllowed()
  m.assertFalse(isLoggingAllowed)
End Function