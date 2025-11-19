'@TestSuite [ArrayUtils] ArrayUtils.brs

'@Setup
Function ArrayUtilsSetup()
End Function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in ArrayUtils.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test insertItemIntoArray unit tests
Function arrayUtils_insertItemIntoArray_test()

  expectedResult = ["1", "2", "3", "4", "5"]
  array = ["1", "2", "4", "5"]
  newArray = insertItemIntoArray(array, "3", 2)
  m.assertEqual(expectedResult, newArray)

  expectedResult = ["0", "1", "2", "3", "4", "5"]
  array = ["1", "2", "3", "4", "5"]
  newArray = insertItemIntoArray(array, "0", 0)
  m.assertEqual(expectedResult, newArray)

  expectedResult = ["1", "2", "3", "4", "5", "6"]
  array = ["1", "2", "3", "4", "5"]
  newArray = insertItemIntoArray(array, "6", 5)
  m.assertEqual(expectedResult, newArray)

  expectedResult = ["1", "2", "3", "4", "5", "6"]
  array = ["1", "2", "3", "4", "5"]
  newArray = insertItemIntoArray(array, "6", 13)
  m.assertEqual(expectedResult, newArray)

End Function


'@Test arrayIncludes unit tests
Function arrayUtils_arrayIncludes_test()
  m.assertEqual(arrayIncludes(["1", "2", "3"], "1"), true)
  m.assertEqual(arrayIncludes(["1", "2", "3"], "4"), false)
End Function