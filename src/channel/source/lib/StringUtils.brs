'''''''''''''''''''
' formatLengthAsTimestamp
'
' take a float or integer length in seconds, transform to timestamp "HH:MM:SS".
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
' ::NOTE:: when calling this function, make sure the calling file is including TubiLanguageTranslate.brs as a dependency 
Function formatLengthAsEnglish(length As Dynamic) As String
  if type(length) = "roFloat" or type(length) = "Float" or type(length) = "Double" then
    length = Int(length)
  end if
  if type(length) = "Integer" or type(length) = "roInt"
    hours = length \ 3600
    minutes = (length mod 3600) \ 60
    seconds = length mod 60
    result = ""
    sTranslationID = invalid
    if hours = 0 and minutes = 0 then
      '//Display just seconds
      sTranslationID = "metadata_seconds" 
    else
      if hours > 0 and minutes > 0
        '//Display hours and minutes
        sTranslationID = "metadata_hoursAndMinutes" 
      else if hours > 0 
        '//Display just hours
        sTranslationID = "metadata_hours" 
      else
        '//Display just minutes
        sTranslationID = "metadata_minutes"
      end if
    end if

    if sTranslationID <> invalid
      aaParams = {
        hours: stri(hours).trim(), 
        minutes: stri(minutes).trim(), 
        seconds: stri(seconds).trim()
      }
      result = getTranslation(sTranslationID, aaParams) 
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
' input:  @s: String, used to display
'         @width: Integer, total number of characters returned from this function 
'         @c: String, will be prepended based on width
' return: result with padstring with specified width
' Example: padString('12345', 8, '0') => '00012345'
Function padString(s As String, width As Integer, c as String)
  result = s.trim()
  result_length = result.Len()
  if result_length < width
    difference = width - result_length
    prependText = right(String(difference, c), difference)
    result = prependText + result
  end if
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


' Helper function to determine if the value is a string
Function isString(value)
  return type(value) = "String" or type(value) = "roString"
End Function


' Helper function that breaks down a url into its component parts
' @url: string, a url
' @paramsSeparator: string, a character used to define the start of parameters (typically "?")
' 
' returns an AA with the following keys:
' protocol: "https://"
' host: "www.tubi.tv"
' path: "/movies/544337/the_monuments_men"
' params: "start=true&lang=EN"
' paramsWithSeparator: "?start=true&lang=EN"
' or returns invalid if not a url
Function getUrlParts(url, paramsSeparator = "?")
  parts = {
    protocol: ""
    host: ""
    path: ""
    params: ""
    paramsWithSeparator: ""
  }

  ' simple checks for valid url
  if isString(url) = false or Instr(0, url, "://") = 0 or Instr(0, url, "://") = 1
    return invalid
  end if

  urlSplit = url.split(paramsSeparator)
  if urlSplit[1] <> invalid
    parts.paramsWithSeparator = paramsSeparator + urlSplit[1]
    parts.params = urlSplit[1]
  end if

  chunks = urlSplit[0].split("/")

  if chunks[0].Right(1) = ":"
    parts.protocol = chunks[0] + "//"
  end if
  parts.host = chunks[2]

  path = "/"
  for i = 3 to chunks.count() - 1
    path += chunks[i]
    if i < chunks.count() - 1
      path += "/"
    end if
  end for
  parts.path = path

  return parts
End Function