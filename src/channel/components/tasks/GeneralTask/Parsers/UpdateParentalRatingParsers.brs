' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @requestNode: roSGNode, a RequestNode instance containing info needed to make the request
Function parseUpdateParentalRatingSuccess(fullResponse, requestNode)
  return {
    requestInput: requestNode.input
    parsedResponse: fullResponse.data
  }
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_requestNode: roSGNode, a RequestNode instance containing info needed to make the request
Function parseUpdateParentalRatingError(fullResponse, _requestNode)
  return {
    code: fullResponse.code
  }
End Function
