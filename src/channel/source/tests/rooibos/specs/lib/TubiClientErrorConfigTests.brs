'@TestSuite TubiClientErrorConfig.brs

'@BeforeEach
Function tubiClientErrorConfig_beforeEach()
  getGlobalAA().constants = getConstants()
End Function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in TubiClientErrorConfig.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test convertClientErrorConfig unit tests
Function convertClientErrorConfig_test()
  input = getLocalClientErrorConfig()
  m.assertNotInvalid(input.default)
  m.assertNotInvalid(input.conditions)
  m.assertNotInvalid(input.services)

  result = convertClientErrorConfig(input)

  m.assertNotInvalid(result.default)
  m.assertNotInvalid(result.conditions)
  m.assertInvalid(result.services)
End Function

'@Test clientErrorConfigCheckIfShouldRetryAfter unit tests

' Uses default.400 config. Should not retry
'@Params [ "", "", "400", "", 0, -1 ]

' Uses default.401 config. Should retry
'@Params [ "", "", "401", "", 0, 0 ]

' Uses conditions.user_not_found config. Should not retry
'@Params [ "", "", "401", "user_not_found", 0, -1 ]

' Uses conditions.expired_token config. Should retry
'@Params [ "", "", "403", "expired_token", 0, 0 ]

' Uses conditions.expired_token config. Testing for case insensitivity Should retry
'@Params [ "", "", "403", "EXPIRED_TOKEN", 0, 0 ]

' Uses conditions.expired_token config. Should not retry because we have used up our max retries
'@Params [ "", "", "403", "expired_token", 1, -1 ]

' Uses url specific config. Should not retry
'@Params [ "https://uapi.staging-public.tubi.io/datascience/logging", "POST", "500", "", 0, -1 ]

' Uses url specific config testing lower case. Should not retry
'@Params [ "https://uapi.staging-public.tubi.io/datascience/logging", "post", "500", "", 0, -1 ]

' Test exponential retry strategy first retry
'@Params [ "", "", "800", "", 0, 1500 ]

' Test exponential retry strategy second retry
'@Params [ "", "", "800", "", 1, 3000 ]

' Test exponential retry strategy third retry
'@Params [ "", "", "800", "", 2, 6000 ]
Function clientErrorConfigCheckIfShouldRetryAfter_test(url, method, statusCode, responseCode, retriesAttempted, expectedResult)
  clientErrorConfig = convertClientErrorConfig(getLocalClientErrorConfig())

  ' Removing jitter to make it easier to test
  clientErrorConfig.retry_strategies.exp_backoff.retry_jitter_ratio = 0

  responseHeaders = {}
  responseBody = ""
  if responseCode <> "" then
    responseHeaders["Content-Type"] = "application/json"

    responseBody = formatJson({
      code: responseCode
    })
  end if

  actualResult = clientErrorConfigCheckIfShouldRetryAfter(clientErrorConfig, url, method, statusCode, responseHeaders, responseBody, retriesAttempted)

  m.assertEqual(actualResult.retryAfter, expectedResult)
End Function
