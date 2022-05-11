'@TestSuite [StringUtils] StringUtils.brs

'@Setup
Function StringUtilsSetup()
End Function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in StringUtils.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test padString unit tests
Function stringUtils_padString_test()
  ' since we use this for transport time, test with time values
  for i=0 to 60
    padded = padString(stri(i), 2, "0")
    m.AssertEqual(padded.len(), 2)
  end for

  ' string already longer than pad length
  m.AssertEqual(padString("aaa", 2, "0"), "aaa")

  ' empty pad string
  m.AssertEqual(padString("bbb", 2, ""), "bbb")

  ' pad string > 1 character
  m.AssertEqual(padString("bbb", 7, "0123"), "0123bbb")
  m.AssertEqual(padString("bbb", 8, "0123"), "30123bbb")

  ' example from function
  m.AssertEqual(padString("12345", 8, "0"), "00012345")
End Function


'@Test padStringLeft unit tests
Function stringUtils_padStringLeft_test()
  ' since we use this for transport time, test with time values
  for i = 0 to 60
    padded = padStringLeft(stri(i), "0", 2)
    m.AssertEqual(padded.len(), 2)
  end for

  ' string already longer than pad length
  m.AssertEqual(padStringLeft("aaa", "0", 2), "aaa")

  ' empty pad string
  m.AssertEqual(padStringLeft("bbb", "", 2), "bbb")

  ' pad string > 1 character
  m.AssertEqual(padStringLeft("bbb", "0123", 7), "0123bbb")
  m.AssertEqual(padStringLeft("bbb", "0123", 8), "01230123bbb")

  ' example from function
  m.AssertEqual(padStringLeft("12345", "0", 8), "00012345")
End Function



'@Test formatLengthAsTimestamp unit tests
Function stringUtils_formatLengthAsTimestamp_test()
  m.AssertEqual(formatLengthAsTimestamp(invalid), "")
  m.AssertEqual(formatLengthAsTimestamp(0), "")
  for i=1 to 7250
    formatted = formatLengthAsTimestamp(i)
    m.AssertNotEqual(formatted, "")
    m.AssertTrue(formatted.len() > 6)
  end for
End Function


'@Test formatLengthAsEnglish unit tests
Function stringUtils_formatLengthAsEnglish_test()
  m.AssertEqual(formatLengthAsEnglish(invalid), "")
  m.AssertEqual(formatLengthAsEnglish(60), "1 min")
  m.AssertEqual(formatLengthAsEnglish(123.45), "2 min")
  m.AssertEqual(formatLengthAsEnglish(3610), "1 h")
  m.AssertEqual(formatLengthAsEnglish(3660), "1 h 1 min")
End Function


'@Test capitalize unit tests
Function stringUtils_capitalize_test()
  m.AssertEqual(capitalize("lowercase"), "Lowercase")
  m.AssertEqual(capitalize("UPPERCASE"), "Uppercase")
  m.AssertEqual(capitalize("MiXeDcAsE"), "Mixedcase")
  m.AssertEqual(capitalize("12345"), "12345")
End Function


'@Test getUrlParts unit tests
Function stringUtils_getUrlParts_test()
  goodUrl = "https://lnc-wttg-fox-aws.tubi.video/some/location/index.m3u8?now_pos=0&model=3600X&video_id=553679&app_id=tubitv&platform=ROKU&app_mode=DEFAULT_MODE&yo.ac=true&user_id=104216&language=en&device_id=5S4629143722&content_type=mp4&opt_out=1&adv_id=e85365f8-e632-510f-bd8a-6352696879ca&pub_id=0a2ada522f8db273c200b95eee98d316"
  badUrl1 = "https//lnc-wttg-fox-aws.tubi.video/index.m3u8?now_pos=0&model=3600X&video_id=553679&app_id=tubitv&platform=ROKU&app_mode=DEFAULT_MODE&yo.ac=true&user_id=104216&language=en&device_id=5S4629143722&content_type=mp4&opt_out=1&adv_id=e85365f8-e632-510f-bd8a-6352696879ca&pub_id=0a2ada522f8db273c200b95eee98d316"
  badUrl2 = "https:/lnc-wttg-fox-aws.tubi.video/index.m3u8?now_pos=0&model=3600X&video_id=553679&app_id=tubitv&platform=ROKU&app_mode=DEFAULT_MODE&yo.ac=true&user_id=104216&language=en&device_id=5S4629143722&content_type=mp4&opt_out=1&adv_id=e85365f8-e632-510f-bd8a-6352696879ca&pub_id=0a2ada522f8db273c200b95eee98d316"
  badUrl3 = ""
  badUrl4 = 12
  badUrl5 = "://"

  m.assertInvalid(getUrlParts(badUrl1))
  m.assertInvalid(getUrlParts(badUrl2))
  m.assertInvalid(getUrlParts(badUrl3))
  m.assertInvalid(getUrlParts(badUrl4))
  m.assertInvalid(getUrlParts(badUrl5))

  urlParts = getUrlParts(goodUrl)
  m.assertNotInvalid(urlParts)
  m.assertNotInvalid(urlParts.protocol)
  m.assertNotInvalid(urlParts.host)
  m.assertNotInvalid(urlParts.path)
  m.assertNotInvalid(urlParts.params)
  m.assertNotInvalid(urlParts.paramsWithSeparator)
  m.assertEqual(urlParts.protocol, "https://")
  m.assertEqual(urlParts.host, "lnc-wttg-fox-aws.tubi.video")
  m.assertEqual(urlParts.path, "/some/location/index.m3u8")
  m.assertEqual(urlParts.params, "now_pos=0&model=3600X&video_id=553679&app_id=tubitv&platform=ROKU&app_mode=DEFAULT_MODE&yo.ac=true&user_id=104216&language=en&device_id=5S4629143722&content_type=mp4&opt_out=1&adv_id=e85365f8-e632-510f-bd8a-6352696879ca&pub_id=0a2ada522f8db273c200b95eee98d316")
  m.assertEqual(urlParts.paramsWithSeparator, "?now_pos=0&model=3600X&video_id=553679&app_id=tubitv&platform=ROKU&app_mode=DEFAULT_MODE&yo.ac=true&user_id=104216&language=en&device_id=5S4629143722&content_type=mp4&opt_out=1&adv_id=e85365f8-e632-510f-bd8a-6352696879ca&pub_id=0a2ada522f8db273c200b95eee98d316")

  paramsAA = urlParts.paramsAA
  m.assertEqual(paramsAA["now_pos"], "0")
  m.assertEqual(paramsAA["model"], "3600X")
  m.assertEqual(paramsAA["video_id"], "553679")
  m.assertEqual(paramsAA["platform"], "ROKU")
  m.assertEqual(paramsAA["app_mode"], "DEFAULT_MODE")
  m.assertEqual(paramsAA["yo.ac"], "true")
  m.assertEqual(paramsAA["user_id"], "104216")
  m.assertEqual(paramsAA["language"], "en")
  m.assertEqual(paramsAA["device_id"], "5S4629143722")
  m.assertEqual(paramsAA["content_type"], "mp4")
  m.assertEqual(paramsAA["opt_out"], "1")
  m.assertEqual(paramsAA["pub_id"], "0a2ada522f8db273c200b95eee98d316")
  m.assertEqual(paramsAA["adv_id"], "e85365f8-e632-510f-bd8a-6352696879ca")

End Function


'@Test replaceURLParameter unit tests
Function stringUtils_replaceURLParameter_test()
  goodUrl1 = "http://www.tubi.tv?cb=1234"
  goodUrl2 = "http://www.tubi.tv?param1=abc&cb=1234"
  goodUrl3 = "http://www.tubi.tv"
  badUrl1 = ""
  badUrl2 = 12
  badUrl3 = "://"

  convertedURL_good1 = replaceURLParameter(goodUrl1, "cb", "XYZ")
  convertedURL_good2 = replaceURLParameter(goodUrl2, "cb", "XYZ")
  convertedURL_good3 = replaceURLParameter(goodUrl3, "cb", "XYZ")
  convertedURL_bad1 = replaceURLParameter(badUrl1, "cb", "XYZ")
  convertedURL_bad2 = replaceURLParameter(badUrl2, "cb", "XYZ")
  convertedURL_bad3 = replaceURLParameter(badUrl3, "cb", "XYZ")

  m.assertNotInvalid(convertedURL_good1)
  m.assertNotInvalid(convertedURL_good2)

  '//double check that the good URLs contain the new value for the 'cb' param
  m.assertTrue(convertedURL_good1.Instr("cb=XYZ") >= 0)
  m.assertTrue(convertedURL_good2.Instr("cb=XYZ") >= 0)


  '//the following URLs do not have the "cb" param so it is expected to return the same "URL" as what was put in
  m.assertEqual(goodUrl3, convertedURL_good3)
  m.assertEqual(badUrl1, convertedURL_bad1)
  m.assertEqual(badUrl2, convertedURL_bad2)
  m.assertEqual(badUrl3, convertedURL_bad3)
End Function


'@Test createCacheBusterString unit tests
Function stringUtils_createCacheBusterString_test()
  aRandomStrings = {}
  '//get a number of unique strings from the function and test their uniqueness
  for i=0 to 20
    sUnique = createCacheBusterString()

    '//Test that the string is a valid string
    m.assertTrue(isString(sUnique))

    '//Test the the unique string has not already been created
    m.assertInvalid(aRandomStrings[sUnique])

    '//Add the unique string to the Associative Array
    aRandomStrings[sUnique] = true
  end for
End Function


'@Test convertFunctionToString unit tests
Function stringUtils_convertFunctionToString_test()

  functionStr = convertFunctionToString(loadPackagedComponents)
  m.assertNotInvalid(functionStr)
  m.assertEqual(LCASE(functionStr), LCASE("loadPackagedComponents"))

  functionStr = convertFunctionToString("loadPackagedComponents")
  m.assertNotInvalid(functionStr)
  m.assertEqual(functionStr, "")

End Function


'@Test GetAMPMTimeString unit tests
Function stringUtils_GetAMPMTimeString_test()
  dt = CreateObject("roDateTime")
  dt.FromSeconds(1635811870)
  m.AssertEqual(GetAMPMTimeString(dt),"12:11 AM")
  m.AssertEqual(GetAMPMTimeString(dt, false),"12:11AM")

  dt.fromSeconds(1636171870)
  m.AssertEqual(GetAMPMTimeString(dt), "4:11 AM")

  dt.fromSeconds(1636891870)
  m.AssertEqual(GetAMPMTimeString(dt), "12:11 PM")

  dt.fromSeconds(1635961560)
  m.AssertEqual(GetAMPMTimeString(dt), "5:46 PM")

  dt.fromSeconds(1635908400)
  m.AssertEqual(GetAMPMTimeString(dt), "3:00 AM")

  dt.fromSeconds(1635966300)
  m.AssertEqual(GetAMPMTimeString(dt), "7:05 PM")
End Function


'@Test isNonEmptyString unit tests
Function stringUtils_isNonEmptyString_test()
  testValue1 = 12 'test a simple non string
  isString1 = isNonEmptyString(testValue1)

  testValue2 = {} 'test an object non string
  isString2 = isNonEmptyString(testValue2)

  testValue3 = "" 'test an empty string
  isString3 = isNonEmptyString(testValue3)

  testValue4 = "someString" 'test a non empty string
  isString4 = isNonEmptyString(testValue4)

  m.assertFalse(isString1)
  m.assertFalse(isString2)
  m.assertFalse(isString3)
  m.assertTrue(isString4)
End Function


'@Test buildQueryString unit tests
Function stringUtils_buildQueryString_test()
  ' test happy values
  params = {
    "X-Tubi-Algorithm": "TUBI-HMAC-SHA256"
    "X-Tubi-Date": "20211213T184228Z"
    "X-Tubi-Expires": "60"
  }
  expectedResult = "X-Tubi-Algorithm=TUBI-HMAC-SHA256&X-Tubi-Date=20211213T184228Z&X-Tubi-Expires=60"
  queryString = buildQueryString(params)
  m.assertEqual(expectedResult, queryString)

  ' test no params
  params = {}
  expectedResult = ""
  queryString = buildQueryString(params)
  m.assertEqual(expectedResult, queryString)

  ' test values that are not strings and/or don't convert to string
  params = {
    "int": 45
    "aa": {
      "does": "notexist"
    }
    "string": "test"
  }
  expectedResult = "int=45&string=test"
  queryString = buildQueryString(params)
  m.assertEqual(expectedResult, queryString)

  ' test a single param
  params = {
    "X-Tubi-Expires": "60"
  }
  expectedResult = "X-Tubi-Expires=60"
  queryString = buildQueryString(params)
  m.assertEqual(expectedResult, queryString)
End Function
