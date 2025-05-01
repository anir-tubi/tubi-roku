' round function is used to round the value up/down based on 0.5 rule.
' if the value is less than 0.5, then it rounds down
' if the value is 0.5 or greater, then it rounds up
' @value : float, the value we want to round up/down
' returns value as Integer
Function round(value)

  wholeNum = Int(value)
  remainder = value - wholeNum
  if remainder >= 0.5
    value = wholeNum + 1
  else
    value = wholeNum
  end if
  
  return Int(value)
  
End Function

' maxValue function is used to get the max value of two values
' @a : dynamic, the first value
' @b : dynamic, the second value
' returns value as dynamic; or invalid if one of the inputs is not valid numeric type
Function maxValue(a as dynamic, b as dynamic) as dynamic
  ' Return invalid to indicate that the inputs are not valid numeric types
  if isNumber(a) = false
    return invalid
  else if isNumber(b) = false
    return invalid
  end if
  
  if a > b
      return a
  else
      return b
  end if
End Function


' roundUp function is used to round the value up
' eg. if the value is 3.1, then it rounds to 4
' @value : float/double/integer, the value we want to round up
' if the value is not in above type, it will return 0
' if the value is negative, it will roundup (eg. for -2.5, it will return -2)
' returns value as Integer
Function roundUp(value)
  result = 0
  valueType = type(value)

  if valueType = "roFloat" or valueType = "Float" or valueType= "roDouble" or valueType= "Double"
    if FIX(value) <> value
      result = Int(value) + 1
    else
      result = Int(value)
    end if
  else if valueType = "roInteger" or valueType = "roInt" or valueType = "Integer"  
    result = value
  end if

  return result
End Function


' roundDown function is used to round the value down,
' eg. if the value is 3.9, then it rounds to 3
' @value : float/double/integer, the value we want to round down
' if the value is not in above type, it will return 0
' if the value is negative, it will rounddown (eg. for -2.5, it will return -3)
' returns value as Integer
Function roundDown(value)

  result = 0
  valueType = type(value)
  if valueType = "roFloat" or valueType = "Float" or valueType= "roDouble" or valueType= "Double"
    if value <> 0 
      result = Int(value)
    end if
  else if valueType = "roInteger" or valueType = "roInt" or valueType = "Integer"  
    result = value
  end if
  return result
  
End Function


' maxVal function is used to get the maximum value of two values
' @a : float/double/integer, the first value
' @b : float/double/integer, the second value
' returns maximum value
Function maxVal(a as dynamic, b as dynamic) as dynamic
  if a > b
      return a
  else
      return b
  end if
End Function