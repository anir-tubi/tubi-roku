' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_requestedNode: roSGNode, a RequestNode instance containing info needed to make the request
Function parseGenericSuccess(fullResponse, _requestNode)
  return fullResponse.data
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_requestedNode: roSGNode, a RequestNode instance containing info needed to make the request
Function parseGenericError(fullResponse, _requestNode)
  return {
    code: getErrorCodeFromResponse(fullResponse)
  }
End Function
