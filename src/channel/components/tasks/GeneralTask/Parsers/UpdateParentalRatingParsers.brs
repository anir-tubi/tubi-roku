' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseUpdateParentalRatingSuccess(fullResponse, reqInfo)
  return {
    requestInput: reqInfo
    parsedResponse: fullResponse.data
  }
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseUpdateParentalRatingError(fullResponse, _reqInfo)
  return {
    code: fullResponse.code
  }
End Function
