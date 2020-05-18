Function TestSuite_StringUtils()
  this = BaseTestSuite()
  this.Name = "StringUtilsTestSuite"
  this.addTest("padString", testCase_stringUtils_padString)
  this.addTest("formatLengthAsTimestamp", testCase_stringUtils_formatLengthAsTimestamp)
  this.addTest("formatLengthAsEnglish", testCase_stringUtils_formatLengthAsEnglish)
  this.addTest("capitalize", testCase_stringUtils_capitalize)
  return this
End Function

Function testCase_stringUtils_padString()
  result = ""
  ' since we use this for transport time, test with time values
  for i=0 to 60 
    padded = padString(stri(i), 2, "0")
    result = result + m.assertEqual(padded.len(), 2)
  end for

  ' string already longer than pad length
  result += m.assertEqual(padString("aaa", 2, "0"), "aaa")

  ' empty pad string
  result += m.assertEqual(padString("bbb", 2, ""), "bbb")

  ' pad string > 1 character
  result += m.assertEqual(padString("bbb", 7, "0123"), "0123bbb")
  result += m.assertEqual(padString("bbb", 8, "0123"), "30123bbb")
  return result
End Function

Function testCase_stringUtils_FormatLengthAsTimestamp()
  result = ""
  result += m.assertEqual(formatLengthAsTimestamp(invalid), "")
  result += m.assertEqual(formatLengthAsTimestamp(0), "")
  for i=1 to 7250
    formatted = formatLengthAsTimestamp(i)
    result += m.assertNotEqual(formatted, "")
    result += m.assertTrue(formatted.len() > 6)
  end for
  return result
End Function 

Function testCase_stringUtils_formatLengthAsEnglish()
  result = ""
  result += m.assertEqual(formatLengthAsEnglish(invalid), "")
  result += m.assertEqual(formatLengthAsEnglish(60), "1 min")
  result += m.assertEqual(formatLengthAsEnglish(123.45), "2 min")
  result += m.assertEqual(formatLengthAsEnglish(3610), "1 h 0 min")
  return result
End Function

Function testCase_stringUtils_capitalize()
  result = ""
  result += m.assertEqual(capitalize("lowercase"), "Lowercase")
  result += m.assertEqual(capitalize("UPPERCASE"), "Uppercase")
  result += m.assertEqual(capitalize("MiXeDcAsE"), "Mixedcase")
  result += m.assertEqual(capitalize("12345"), "12345")
  return result
End Function
