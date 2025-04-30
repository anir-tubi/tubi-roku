'''''''''''''''''''
' formatLengthAsTimestamp
'
' take a float or integer length in seconds, transform to timestamp "HH:MM:SS".
Function formatLengthAsTimestamp(length As Dynamic) As String
  if type(length) = "Float" OR type(length) = "roFloat" OR type(length) = "Double" then length = Int(length)
  if (type(length) = "Integer" OR type(length) = "roInteger") AND length > 0 then
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
' formatLengthAsTimestampWithoutHours
'
' take a float or integer length in seconds, transform to timestamp "MM:SS".
Function formatLengthAsTimestampWithoutHours(length As Dynamic) As String
  if type(length) = "roFloat" OR type(length) = "Double" then length = Int(length)
  if (type(length) = "Integer" OR type(length) = "roInteger") AND length > 0 then
    minutes = length \ 60
    seconds = length mod 60
    result = padString(stri(minutes), 2, "0") + ":" + padString(stri(seconds), 2, "0")
    return result
  else
    return ""
  end if
End Function


' formatLengthAsMinsAndSecs
'
' take a float or integer length in seconds, transform to timestamp "MM:SS".
' if the length is >= 3600, then it will return as "HH:MM:SS"
Function formatLengthasMinsAndSecs(length As Dynamic) As String
  if type(length) = "Float" OR type(length) = "roFloat" OR type(length) = "Double" then length = Int(length)
  if (type(length) = "Integer" OR type(length) = "roInteger") AND length >= 0 then
    minutes = (length mod 3600) \ 60
    seconds = length mod 60
    result = padString(stri(minutes), 2, "0") + ":" + padString(stri(seconds), 2, "0")
    return result
  else
    return ""
  end if
End Function


''''''''''''''''''''''
' formatLengthAsHourAndMins
'
' take a float or integer length in seconds, transform to 'x hours y min'

Function formatLengthAsHourAndMins(length As Dynamic) As String
  if type(length) = "roFloat" OR type(length) = "Double" then length = Int(length)

  if (type(length) = "Integer" OR type(length) = "roInteger") AND length > 0 then
    hours = length \ 3600
    minutes = (length mod 3600) \ 60

    result = ""
    if hours > 0
      result = stri(hours).trim() + " hr "
    end if

    if minutes > 0
      result = result + stri(minutes).trim() + " min"
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
' pad the provided string with padString(generally spaces) to length provided.
' PadStringLeft differences from padString only when padString + originalstring > minLength
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
' @paramsAA: AA, An associative array that contains the param names as the keys and the corresponding values as strings
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
  if isString(url) = false OR Instr(0, url, "://") = 0 OR Instr(0, url, "://") = 1
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
' @addIfDoesNotExist: boolean, Set this to true if you wish to not only replace a param, but to add the param if the param does not exist in the URL's query string
Function replaceURLParameter(url, paramToReplace, replacementValue, addIfDoesNotExist = false)
  sReplacementURL = url
  if isString(url) = true AND url <> "" AND isString(paramToReplace) = true AND isString(replacementValue) = true
    re = CreateObject("roRegex", "[\\?&]" + paramToReplace + "=([^&#]*)", "i")
    aMatches = re.Match(url)
    if aMatches.Count() > 0
      '//place replacement string into the URL
      match = aMatches[0]
      sDelimiter = match.mid(0, 1)
      sNewParamValuePair = sDelimiter + paramToReplace + "=" + replacementValue
      sReplacementURL = url.replace(match, sNewParamValuePair)
    else if addIfDoesNotExist = true
      '// The paramToReplace is not in the URL, check the value of addIfDoesNotExist to see if we should still add it to the query list
      sConnector = "&"
      if Instr(1, url, "?") <= 0
        '//if the URL does not contain a "?", then use the "?" instead of the "&" to add the param/value pair to the URL
        sConnector = "?"
      end if

      sReplacementURL = url + sConnector + paramToReplace + "=" + replacementValue
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
  if type(func) = "roFunction" OR type(func) = "Function"
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
    amPm = "PM"
  else
    amPm = "AM"
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
  if isString(str) AND str <> ""
    return true
  end if
  return false
End Function


' buildQueryString is used to construct the query params in canonical form
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
      if index <> params.count() AND paramAdded = true
        queryString = queryString + "&"
      end if

    end for
  end if

  return queryString

End Function


' @email: string, an email address to check for validity
' @returns: boolean,  true if the email passes a trivial email validation check, false otherwise.
'                     Additional, better validation will occur on the backend.
Function isEmailValid(email)
  emailPattern = CreateObject("roRegex", "[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}", "i")

  return emailPattern.IsMatch(email)
End Function
