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
' padStringLeft
' input:  @originalString: String, used to display
'         @minLength: Integer, minimum number of characters returned from this function
'         @padString: String, will be prepended
' return: result with paddedstring with more than minimum width
'
' pad the provided string with padString(gernally spaces) to length provided.
' PadStringLeft differes from padString only when padString + originalstring > minLenth
' padStringLeft("bbb", "0123", 8) = "01230123bbb"
' padString("bbb", 8, "0123") = "30123bbb"

Function padStringLeft(originalString, padString, minLength) as string
  originalString = originalString.Trim()
  while originalString.Len() < minLength
    originalString = padString + originalString
  end while
  return originalString
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


' Helper function that breaks down a url into its component parts
' @url: string, a url
' @paramsAA: AA, An associative array that comntaines the param names as the keys and the corresponding values as strings
' @paramsSeparator: string, a character used to define the start of parameters (typically "?")
'
' returns an AA with the following keys:
' protocol: "https://"
' host: "www.tubi.tv"
' path: "/movies/544337/the_monuments_men"
' params: "start=true&lang=EN"
' paramsAA: "{start:"true", lang: 'EN'}"
' paramsWithSeparator: "?start=true&lang=EN"
' or returns invalid if not a url
Function getUrlParts(url, paramsSeparator = "?")
  parts = {
    protocol: ""
    host: ""
    path: ""
    params: ""
    paramsAA: {}
    paramsWithSeparator: ""
  }

  ' simple checks for valid url
  if isString(url) = false or Instr(0, url, "://") = 0 or Instr(0, url, "://") = 1
    return invalid
  end if

  urlSplit = url.split(paramsSeparator)
  if urlSplit[1] <> invalid
    parts.paramsWithSeparator = paramsSeparator + urlSplit[1]
    params = urlSplit[1]
    parts.params = params

    '//Place the query name/value pairs into a convenient paramsAA AA
    '//::TODO:: make non-string values so they are not strings: booleans, numbers, etc
    aQueryNameValuePair = params.Split("&")
    for each queryPair in aQueryNameValuePair
      aQueryParamValue = queryPair.Split("=")
      parts.paramsAA[aQueryParamValue[0]] = aQueryParamValue[1]
    end for

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


' Change the param value of the provided param name with the provided value with the provided URL
' @url: string, The URL to change
' @paramToReplace: string, The query param name that its value should be changed
' @replacementValue: string, The value that should be the new value of the provided param
Function replaceURLParameter(url, paramToReplace, replacementValue)
  sReplacementURL = url
  if isString(url) = true and isString(paramToReplace) = true and isString(replacementValue) = true
    re = CreateObject("roRegex", "[\\?&]" + paramToReplace + "=([^&#]*)", "i")
    aMatches = re.Match(url)
    if aMatches.Count() > 0
      '//place replacement string into the URL
      match = aMatches[0]
      sDelimiter = match.mid(0, 1)
      sNewParamValuePair = sDelimiter + paramToReplace + "=" + replacementValue
      sReplacementURL = url.replace(match, sNewParamValuePair)
    else
      '// The paramToReplace is not in the URL, do nothing.
      '// In the future, we could append the param to the URL. But for right now, it is unnecessary.
    end if
  end if

  return sReplacementURL
End Function


' Create a unique string.
Function createCacheBusterString()
  dateTime = createObject("roDateTime")
  seconds = dateTime.AsSeconds()
  sSeconds = StrI(seconds).trim()
  nRandom = Rnd(seconds)
  sRandom = StrI(nRandom).trim()

  '//The 1st part of the string includes the number of seconds from epoch time, followed by a "-",
  '// followed by a random number between 0 to the epoch time number
  sCacheBuster = sSeconds + "-" + sRandom
  return sCacheBuster
End Function


' The function whose name we want to extract
' @func: function, the function whose name we want to extract
Function convertFunctionToString(func)

  functionStr = ""
  if type(func) = "roFunction" or type(func) = "Function"
    functionStr = func.ToStr().Replace("Function: ","")
  end if
  return functionStr

End Function


'******************************************************
'@param {date} dateTime - the date object that is used to get the time
'@param {boolean} bIncludeSpaceSeparator - Should the time and the "AM" or "PM" strings be separated by a space?
'
'returns AM/PM appended time format
'******************************************************

Function GetAMPMTimeString(dateTime, bIncludeSpaceSeparator = true) as string
  if dateTime.GetHours() - 12 >= 0
    amPM = "PM"
  else
    amPM = "AM"
  end if
  hourValue = dateTime.getHours() mod 12
  if hourValue = 0
    hourValue = "12"
  else
    hourValue = StrI(hourValue).Trim()
  end if

  minuteValue = padStringLeft(dateTime.GetMinutes().toStr(), "0", 2)

  sSpaceSeparator = " "
  if bIncludeSpaceSeparator = false
    sSpaceSeparator = ""
  end if

  return hourValue + ":" + minuteValue + sSpaceSeparator + amPm

End Function


' @str: string, the value to be checked for being a string and not being an empty string
Function isNonEmptyString(str)
  if isString(str) and str <> ""
    return true
  end if
  return false
End Function


' buildQueryString is used to contruct the query params in canonical form
'
' @params : assocarray where key/value pairs will be turned into a query parameter string
'
' returns query in String like "key1=value1&key2=value2"
Function buildQueryString(params)

  queryString = ""
  index = 0

  if params <> invalid
    for each item in params.Items()
      paramAdded = false

      if FindMemberFunction(item.value, "toStr") <> invalid
        queryString = queryString + item.key + "=" + item.value.tostr()
        paramAdded = true
      end if

      index = index + 1
      if index <> params.count() and paramAdded = true
        queryString = queryString + "&"
      end if

    end for
  end if

  return queryString

End Function
