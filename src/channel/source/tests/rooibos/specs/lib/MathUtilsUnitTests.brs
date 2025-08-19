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


'@Test maxValue unit tests
Function mathUtils_max_value_test()
  ' maxValue test with integers (positive)
  result = maxValue(5, 3)
  m.AssertEqual(result, 5)
  m.AssertTrue(isInt(result))

  ' maxValue test with integers (reverse order)
  result = maxValue(3, 5)
  m.AssertEqual(result, 5)
  m.AssertTrue(isInt(result))

  ' maxValue test with floats
  result = maxValue(3.14, 2.71)
  m.AssertEqual(result, 3.14)
  m.AssertTrue(isFloat(result) OR isDouble(result))

  ' maxValue test with mixed types (integer and float)
  result = maxValue(5, 4.9)
  m.AssertEqual(result, 5)
  m.AssertTrue(isInt(result))

  ' maxValue test with equal values
  result = maxValue(10, 10)
  m.AssertEqual(result, 10)
  m.AssertTrue(isInt(result))

  ' maxValue test with negative numbers
  result = maxValue(-1, -5)
  m.AssertEqual(result, -1)
  m.AssertTrue(isInt(result))

  ' maxValue test with zero and positive
  result = maxValue(0, 8)
  m.AssertEqual(result, 8)
  m.AssertTrue(isInt(result))

  ' maxValue test with invalid input (string)
  result = maxValue("2", 3)
  m.AssertInvalid(result) ' Expect invalid instead of 0

  ' maxValue test with invalid input (array)
  result = maxValue([1], 2)
  m.AssertInvalid(result) ' Expect invalid instead of 0

End Function


'@Test minValue unit tests
Function mathUtils_min_value_test()
  ' minValue test with integers (positive)
  result = minValue(5, 3)
  m.AssertEqual(result, 3)
  m.AssertTrue(isInt(result))
  ' minValue test with integers (reverse order)
  result = minValue(3, 5)
  m.AssertEqual(result, 3)
  m.AssertTrue(isInt(result))

  ' minValue test with floats
  result = minValue(3.14, 2.71)
  m.AssertEqual(result, 2.71)
  m.AssertTrue(isFloat(result) OR isDouble(result))

  ' minValue test with mixed types (integer and float)
  result = minValue(5, 4.9)
  m.AssertEqual(result, 4.9)

  ' minValue test with equal values
  result = minValue(10, 10)
  m.AssertEqual(result, 10)
  m.AssertTrue(isInt(result))

  ' minValue test with negative numbers
  result = minValue(-1, -5)
  m.AssertEqual(result, -5)
  m.AssertTrue(isInt(result))

  ' minValue test with zero and positive
  result = minValue(0, 8)
  m.AssertEqual(result, 0)
  m.AssertTrue(isInt(result))

  ' minValue test with invalid input (string)
  result = minValue("2", 3)
  m.AssertInvalid(result) ' Expect invalid instead of 0

  ' minValue test with invalid input (array)
  result = minValue([1], 2)
  m.AssertInvalid(result) ' Expect invalid instead of 0
End Function


'@Test round up unit tests
Function mathUtils_round_up_test()

  ' roundUp value test with value 0
  roundedPosition = roundUp(0)
  m.AssertEqual(roundedPosition, 0)
  m.AssertTrue(isInt(roundedPosition))

  ' roundUp value test with value 0.1
  roundedPosition = roundUp(0.1)
  m.AssertEqual(roundedPosition, 1)

  ' roundUp value test with value 0.9
  roundedPosition = roundUp(0.9)
  m.AssertEqual(roundedPosition, 1)

  ' roundUp value test with value 1
  roundedPosition = roundUp(1)
  m.AssertEqual(roundedPosition, 1)

  ' roundUp value test with value 2.0
  roundedPosition = roundUp(2.0)
  m.AssertEqual(roundedPosition, 2)

  ' roundUp value test with value -2.5
  roundedPosition = roundUp(-2.5)
  m.AssertEqual(roundedPosition, -2)

  ' roundUp value test with value "2.5"
  roundedPosition = roundUp("2.5")
  m.AssertEqual(roundedPosition, 0)

  ' roundUp value test with value [3.5]
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