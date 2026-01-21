' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseEmailExistsSuccess(fullResponse, reqInfo)
  return {
    requestInput: reqInfo
    parsedResponse: fullResponse.data
  }
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseEmailExistsError(fullResponse, reqInfo)
  return {
    requestInput: reqInfo
    code: fullResponse.code
  }
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
'side effects... overwrites the old authInfo in the registry with the new authInfo
Function parseSignUpSuccess(fullResponse, _reqInfo)
  parsedResponse = fullResponse.data
  parsedResponse.authType = "EMAIL" 'used for subsequent analytics requests
  return parsedResponse
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
'side effects... overwrites the old authInfo in the registry with the new authInfo
Function parseSignUpSuccessForKids(fullResponse, reqInfo)
  parsedResponse = fullResponse.data
  parsedResponse.authType = "EMAIL" 'TODO: check while analytics dev. Not sure what this should be.
  parsedResponse.isKidsAccount = true
  parsedResponse.has_age = true
  'for kids we are sending first_name and backend is sending name!!
  if parsedResponse.name <> invalid AND parsedResponse.first_name = invalid
    parsedResponse["first_name"] = parsedResponse.name
  end if

  if isAA(reqInfo) = true AND reqInfo.signInInfo <> invalid
    if isNonEmptyString(reqInfo.signInInfo.pinSubmitted) = true
      parsedResponse["parent_has_pin"] = true 'indicates whether the parent is setting up a pin along with this request
    else if reqInfo.signInInfo.hasPin = true
      parsedResponse["parent_has_pin"] = true 'indicates whether the parent has set a pin for the kids account
    end if
  end if

  return parsedResponse
End Function



' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseSignUpError(fullResponse, reqInfo)
  return {
    reqInfo: reqInfo
    code: fullResponse.code
    info: fullResponse.data
  }
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
'side effects... overwrites the old authInfo in the registry with the new authInfo
Function parseSignInSuccess(fullResponse, reqInfo)
  parsedResponse = fullResponse.data
  parsedResponse.authType = "EMAIL" 'used for subsequent analytics requests
  parsedResponse.requestInput = reqInfo
  return parsedResponse
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseSignInError(fullResponse, reqInfo)
  return {
    requestInput: reqInfo
    code: fullResponse.code
    error: fullResponse.data
  }
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
'side effects... overwrites the old authInfo in the registry with the new authInfo
Function parseMagicLinkSuccess(fullResponse, _reqInfo)
  return fullResponse.data
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseMagicLinkError(fullResponse, _reqInfo)
  return {
    code: fullResponse.code
  }
End Function

' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
'side effects... overwrites the old authInfo in the registry with the new authInfo
Function parsequeryStatusOfMagicLinkSuccess(fullResponse, _reqInfo)
  parsedResponse = {}

  if isAA(fullResponse) = true
    parsedResponse = fullResponse.data

    if isAA(parsedResponse) = true
      parsedResponse.authType = "EMAIL" 'used for subsequent analytics requests
    end if
  end if

  return parsedResponse
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parsequeryStatusOfMagicLinkError(fullResponse, _reqInfo)
  return {
    code: fullResponse.code
  }
End Function
