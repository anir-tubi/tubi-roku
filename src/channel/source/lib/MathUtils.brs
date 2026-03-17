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
Function maxValue(a as Dynamic, b as Dynamic) as Dynamic
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


' minValue function is used to get the min value of two values
' @a : integer|float, the first value
' @b : integer|float, the second value
' returns value as integer|float; or invalid if one of the inputs is not valid numeric type
Function minValue(a as Dynamic, b as Dynamic) as Dynamic
  ' Return invalid to indicate that the inputs are not valid numeric types
  if isNumber(a) = false OR isNumber(b) = false
    return invalid
  end if

  if a < b
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

  if valueType = "roFloat" OR valueType = "Float" OR valueType = "roDouble" OR valueType = "Double"
    if FIX(value) <> value
      result = Int(value) + 1
    else
      result = Int(value)
    end if
  else if valueType = "roInteger" OR valueType = "roInt" OR valueType = "Integer"
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
  if valueType = "roFloat" OR valueType = "Float" OR valueType = "roDouble" OR valueType = "Double"
    if value <> 0
      result = Int(value)
    end if
  else if valueType = "roInteger" OR valueType = "roInt" OR valueType = "Integer"
    result = value
  end if
  return result

End Function


' maxVal function is used to get the maximum value of two values
' @a : float/double/integer, the first value
' @b : float/double/integer, the second value
' returns maximum value
Function maxVal(a as Dynamic, b as Dynamic) as Dynamic
  if a > b
    return a
  else
    return b
  end if
End Function


' getNumber is used to get a number from the value, or a fallback
' @value : dynamic, the value we want to get the number from
' @fallback : integer, the fallback value if the value is not a number
' returns value as dynamic
Function getNumber(value as Dynamic, fallback = 0) as Dynamic
  if isNumber(value) = true
    return value
  else
    return fallback
  end if
End Function


' Returns the same width if already divisible by 3,
' otherwise rounds up to the next multiple of 3.
Function ensureDivisibleBy3(width as Integer) as Integer
  if width < 0 then return 0
  remainder = width mod 3
  if remainder = 0 then
    return width
  else
    return width + (3 - remainder)
  end if
End Function


' Converts seconds to time left string.
' @seconds: Integer, the seconds to convert
' @returns: String, the time left string
Function convertSecondsToTimeLeftString(seconds as Integer) as String
  formattedString = ""

  if seconds <> invalid
    hourValue = Int(seconds / 3600)
    minuteValue = ((Int(seconds / 60) mod 60) + 1).toStr()

    if hourValue > 0
      formattedString = getTranslation("h_m_left", { "hour": hourValue.toStr(), "minutes": minuteValue })
    else
      formattedString = getTranslation("m_left", { "minutes": minuteValue })
    end if
  end if

  return formattedString
End Function
