'''''''''''''''''''
' formatLengthAsTimestamp
'
' take a float or integer length in seconds, transform to timestamp "HH:MM:SS".
'TODO(Chris): Move this to common library
Function formatLengthAsTimestamp(length As Dynamic) As String
  if type(length) = "roFloat" or type(length) = "Double" then length = Int(length)
  if (type(length) = "Integer" or type(length) = "roInteger") and length > 0 then
    hours = length \ 3600
    minutes = (length mod 3600) \ 60
    seconds = length mod 60
    result = stri(hours) + ":" + padString(stri(minutes), 2, "0") + ":" + padString(stri(seconds), 2, "0")
    return result
  else
    return ""
  end if
End Function


'''''''''''''''''''
' formatLengthAsEnglish
'
' take an integer length in seconds and give it an English descriptions like "1 h 36 min"
'TODO(Chris): Move this to common library
Function formatLengthAsEnglish(length As Dynamic) As String
  if type(length) = "roFloat" or type(length) = "Double" then length = Int(length)
  if type(length) = "Integer" or type(length) = "roInteger"
    hours = length \ 3600
    minutes = (length mod 3600) \ 60
    seconds = length mod 60
    result = ""
    if hours = 0 and minutes = 0 then
      result = stri(seconds).trim() + " sec"
    else
      if hours > 0 then result = stri(hours).trim() + " h "
      result  = result + stri(minutes).trim() + " min"
    end if
    return result
  else
    return ""
  end if
End Function


'''''''''''''''''''
' padString
' 
' simple left padding of a string with a given character
' Example: padString('12345', 8, '0') => '00012345'
'
'TODO(Chris): Move this to common library
Function padString(s As String, width As Integer, c as String)
  result = s.trim()
  while result.len() < width
    difference = width - result.len()
    result = right(c, difference) + result
  end while
  return result
End Function


'''''''''''''''''''
' joinStringArray
'
' Join strings together, using 'c' as a separator
' Example: joinStringArray(['a','b','c'],'-') => "a-b-c"
'TODO(Chris): Move this to common library
Function joinStringArray(a As Object, c As String)
  result = ""
  if a.count() > 0 then result = a[0]
  for i=1 to a.count() - 1
    result = result + c + a[i]
  end for
  return result
End Function


''''''''''
' capitalize
'
' Make the first letter uppercase, the reset lowercase
Function capitalize(s As String)
  if s.len() > 0 then
    return Ucase(Left(s, 1)) + LCase(Right(s, s.len() - 1))
  else
    return ""
  end if
End Function
