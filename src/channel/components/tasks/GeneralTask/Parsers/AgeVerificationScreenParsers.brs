' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseAgeVerificationScreenDeviceRegistrationSuccess(fullResponse, _reqInfo)
  age = -1
  parsedResponse = fullResponse.data
  if parsedResponse <> invalid and parsedResponse.age <> invalid
    age = parsedResponse.age
  end if
  return age
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseAgeVerificationScreenDeviceRegistrationError(fullResponse, reqInfo)
  ' default code
  errCode = -1234

  if fullResponse <> invalid and fullResponse.code <> invalid
    ' HTTP or Curl code
    errCode = fullResponse.code
  end if

  return {
    code: errCode
    reqInfo: reqInfo
  }
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseAgeVerificationScreenCheckBirthdaySuccess(fullResponse, _reqInfo)
  parsedResponse = fullResponse.data

  res = {}
  if parsedResponse <> invalid and parsedResponse.has_age <> invalid
    res.hasAge = parsedResponse.has_age
  end if

  return res
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseAgeVerificationScreenCheckBirthdayError(fullResponse, _reqInfo)
  errCode = -1234
  if fullResponse <> invalid and fullResponse.code <> invalid
    ' HTTP or Curl code
    errCode = fullResponse.code
  end if

  return {
    code: errCode
  }
End Function
