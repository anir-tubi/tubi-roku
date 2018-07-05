Function testPadString(t)
  ' since we use this for transport time, test with time values
  for i=0 to 60 
    result = padString(stri(i), 2, "0")
    t.assertEqual(result.len(), 2)
  end for

  ' string already longer than pad length
  t.assertEqual(padString("aaa", 2, "0"), "aaa")

  ' empty pad string
  t.assertEqual(padString("bbb", 2, ""), "bbb")

  ' pad string > 1 character
  t.assertEqual(padString("bbb", 7, "0123"), "0123bbb")
  t.assertEqual(padString("bbb", 8, "0123"), "30123bbb")
End Function

Function testFormatLengthAsTimestamp(t)
  t.assertEqual(formatLengthAsTimestamp(invalid), "")
  t.assertEqual(formatLengthAsTimestamp(0), "")
  for i=1 to 7250
    result = formatLengthAsTimestamp(i)
    t.assertNotEqual(result, "")
    t.assertTrue(result.len() > 6)
  end for
End Function