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


' roundUp function is used to round the value up
' eg. if the value is 3.1, then it rounds to 4
' @value : float, the value we want to round up
' returns value as Integer
Function roundUp(value)
  
  if value = 0
    return Int(value)
  else
    return Int(value) + 1
  end if
  
End Function


' roundDown function is used to round the value down
' eg. if the value is 3.9, then it rounds to 3
' @value : float, the value we want to round down
' returns value as Integer
Function roundDown(value)

  return Int(value)
  
End Function