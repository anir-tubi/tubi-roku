' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseGenericSuccess(fullResponse, _reqInfo)
  return fullResponse.data
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseGenericError(fullResponse, _reqInfo)
  return {
    code: getErrorCodeFromResponse(fullResponse)
  }
End Function
