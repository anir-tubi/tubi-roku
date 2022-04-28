Function testFunctionLib()
  return {
    testFunction1: tubi_testFunction1
    testFunction2: tubi_testFunction2
    testFunction3: tubi_testFunction3
  }
End Function

Function tubi_testFunction1()
  return invalid
End Function


Function tubi_testFunction2(things)
  return invalid
End Function


Function tubi_testFunction3(things)
  return things
End Function