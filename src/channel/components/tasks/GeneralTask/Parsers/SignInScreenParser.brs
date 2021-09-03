' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @requestNode: roSGNode, a RequestNode instance containing info needed to make the request
Function parseEmailExistsSuccess(fullResponse, requestNode)
  parsedResponse = fullResponse.data
  return {
    requestInput: requestNode.input
    parsedResponse: fullResponse.data
  }
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @requestNode: roSGNode, a RequestNode instance containing info needed to make the request
Function parseEmailExistsError(fullResponse, requestNode)
 return {
  requestInput: requestNode.input
  code: fullResponse.code
}
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @requestNode: roSGNode, a RequestNode instance containing info needed to make the request
'side effects... overwrites the old authInfo in the registry with the new authInfo
Function parseSignUpSuccess(fullResponse, requestNode)
  parsedResponse = fullResponse.data
  parsedResponse.authType = "EMAIL"  'used for subsequent analytics requests
  requestModule = TubiRequest(m.constants.settings)
  authModule = TubiAuth(m.constants, requestModule)
  authModule.handleRegistration(parsedResponse)
  return parsedResponse
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @requestNode: roSGNode, a RequestNode instance containing info needed to make the request
Function parseSignUpError(fullResponse, requestNode)
  return {
    requestNode: requestNode
    code: fullResponse.code
  }
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @requestNode: roSGNode, a RequestNode instance containing info needed to make the request
'side effects... overwrites the old authInfo in the registry with the new authInfo
Function parseSignInSuccess(fullResponse, requestNode)
  parsedResponse = fullResponse.data
  parsedResponse.authType = "EMAIL"  'used for subsequent analytics requests
  requestModule = TubiRequest(m.constants.settings)
  authModule = TubiAuth(m.constants, requestModule)
  authModule.handleRegistration(parsedResponse)
  return parsedResponse
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @requestNode: roSGNode, a RequestNode instance containing info needed to make the request
Function parseSignInError(fullResponse, requestNode)
  return {
    requestInput: requestNode.input
    code: fullResponse.code
  }
End Function