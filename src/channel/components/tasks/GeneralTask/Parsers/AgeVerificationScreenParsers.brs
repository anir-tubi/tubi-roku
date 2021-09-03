' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @requestNode: roSGNode, a RequestNode instance containing info needed to make the request
Function parseAgeVerificationScreenDeviceRegistrationSuccess(fullResponse, requestNode)
  age = -1
  parsedResponse = fullResponse.data
  if parsedResponse <> invalid and parsedResponse.age <> invalid
    age = parsedResponse.age
  end if
  return age
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @requestNode: roSGNode, a RequestNode instance containing info needed to make the request
Function parseAgeVerificationScreenDeviceRegistrationError(fullResponse, requestNode)

  ' default code
  errCode = -1234
  
  if fullResponse <> invalid and fullResponse.code <> invalid
    ' HTTP or Curl code
    errCode = fullResponse.code
  end if

  birthdate = ""
  if requestNode.input <> invalid and requestNode.input.birthdate <> invalid
    birthdate = requestNode.input.birthdate
  end if

  return {
    code: errCode
    birthdate: birthdate
  }
End Function


Function parseAgeVerificationScreenCheckBirthdaySuccess(fullResponse, requestNode)
  parsedResponse = fullResponse.data

  res = {}
  if parsedResponse <> invalid and parsedResponse.has_age <> invalid
    res.hasAge = parsedResponse.has_age
  end if

  return res
End Function


Function parseAgeVerificationScreenCheckBirthdayError(fullResponse, requestNode)
  errCode = -1234
  if fullResponse <> invalid and fullResponse.code <> invalid
    ' HTTP or Curl code
    errCode = fullResponse.code
  end if

  return {
    code: errCode
  }
End Function