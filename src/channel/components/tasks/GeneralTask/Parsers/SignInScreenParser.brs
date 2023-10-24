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
  parsedResponse.authType = "EMAIL"  'used for subsequent analytics requests
  requestModule = TubiRequest(m.constants.settings)
  authModule = TubiAuth(m.constants, requestModule)
  authModule.handleRegistration(parsedResponse)
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
  parsedResponse.authType = "EMAIL"  'used for subsequent analytics requests
  parsedResponse.requestInput = reqInfo
  requestModule = TubiRequest(m.constants.settings)
  authModule = TubiAuth(m.constants, requestModule)
  authModule.handleRegistration(parsedResponse)
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
  return fullResponse.code
End Function

' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
'side effects... overwrites the old authInfo in the registry with the new authInfo
Function parsequeryStatusOfMagicLinkSuccess(fullResponse, _reqInfo)
  return fullResponse.data
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parsequeryStatusOfMagicLinkError(fullResponse, _reqInfo)
  return fullResponse.code
End Function
