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


'@Test round up unit tests
Function mathUtils_round_up_test()

  ' roundUp value test with value 0
  roundedPosition = roundUp(0)
  m.AssertEqual(roundedPosition, 0)
  
  ' roundUp value test with value 0.1
  roundedPosition = roundUp(0.1)
  m.AssertEqual(roundedPosition, 1)
  
  ' roundUp value test with value 0.9
  roundedPosition = roundUp(0.9)
  m.AssertEqual(roundedPosition, 1)
  
  ' roundUp value test with value 1
  roundedPosition = roundUp(1)
  m.AssertEqual(roundedPosition, 1)

  ' roundUp value test with value -2.5
  roundedPosition = roundUp(-2.5)
  m.AssertEqual(roundedPosition, -2)

  ' roundUp value test with value "2.5"
  roundedPosition = roundUp("2.5")
  m.AssertEqual(roundedPosition, 0)  

  ' roundUp value test with value [3.5
  roundedPosition = roundUp([3.5])
  m.AssertEqual(roundedPosition, 0) 
    
End Function


'@Test round down unit tests
Function mathUtils_round_down_test()

  ' roundDown value test with value 0
  roundedPosition = roundDown(0)
  m.AssertEqual(roundedPosition, 0)
  
  ' roundDown value test with value 0.1
  roundedPosition = roundDown(0.1)
  m.AssertEqual(roundedPosition, 0)

  ' roundDown value test with value 0.9
  roundedPosition = roundDown(0.9)
  m.AssertEqual(roundedPosition, 0)
  
  ' roundDown value test with value 1
  roundedPosition = roundDown(1)
  m.AssertEqual(roundedPosition, 1)

  ' roundDown value test with value -2.5
  roundedPosition = roundDown(-2.5)
  m.AssertEqual(roundedPosition, -3)

  ' roundDown value test with value "2.5"
  roundedPosition = roundDown("2.5")
  m.AssertEqual(roundedPosition, 0)  

  ' roundDown value test with value [3.5]
  roundedPosition = roundDown([3.5])
  m.AssertEqual(roundedPosition, 0)  
    
End Function