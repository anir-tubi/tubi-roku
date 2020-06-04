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