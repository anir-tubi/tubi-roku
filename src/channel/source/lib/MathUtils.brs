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