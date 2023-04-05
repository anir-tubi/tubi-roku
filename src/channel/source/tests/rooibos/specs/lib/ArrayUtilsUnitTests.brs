'@TestSuite [ArrayUtils] ArrayUtils.brs

'@Setup
Function ArrayUtilsSetup()
End Function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in ArrayUtils.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test insertItemIntoArray unit tests
Function arrayUtils_insertItemIntoArray_test()

  expectedResult = ["1","2","3","4","5"]
  array = ["1","2","4","5"]
  newArray = insertItemIntoArray(array, "3", 2)
  m.assertEqual(expectedResult, newArray)

End Function
