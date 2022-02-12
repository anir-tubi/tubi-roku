' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @requestNode: roSGNode, a RequestNode instance containing info needed to make the request
Function parseGenericSuccess(fullResponse, requestNode)
  return fullResponse.data
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @requestNode: roSGNode, a RequestNode instance containing info needed to make the request
Function parseGenericError(fullResponse, requestNode)
  return {
    code: getErrorCodeFromResponse(fullResponse)
  }
End Function