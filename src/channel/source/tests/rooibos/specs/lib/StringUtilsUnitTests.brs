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
End Function