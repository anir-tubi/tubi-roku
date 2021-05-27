'@TestSuite [MathUtils] MathUtils.brs 

'@Setup
Function MathUtilsSetup()
End Function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests functions in MathUtils.brs
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


'@Test round unit tests
Function mathUtils_round_test()

  ' round value test with value 0
  roundedPosition = round(0)
  m.assertNotInvalid(roundedPosition)
  m.AssertEqual(roundedPosition, 0)
  
  ' round value test less than 0.5
  roundedPosition = round(0.2)
  m.assertNotInvalid(roundedPosition)
  m.AssertEqual(roundedPosition, 0)

  ' round value test with value 0.5
  roundedPosition = round(0.5)
  m.assertNotInvalid(roundedPosition)
  m.AssertEqual(roundedPosition, 1)
  
  ' round value test greater than 0.5
  roundedPosition = round(0.9)
  m.assertNotInvalid(roundedPosition)
  m.AssertEqual(roundedPosition, 1)
  
  ' round value test with value 1
  roundedPosition = round(1)
  m.assertNotInvalid(roundedPosition)
  m.AssertEqual(roundedPosition, 1)
    
End Function
