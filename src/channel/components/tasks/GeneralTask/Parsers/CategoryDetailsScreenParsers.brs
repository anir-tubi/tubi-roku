' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @requestNode: roSGNode, a RequestNode instance containing info needed to make the request
Function parseCategoryDetailsSuccess(fullResponse, requestNode)
  translate = TubiMetadataTranslate(m.constants)

  parsedResponse = fullResponse.data
  fullJson = fullResponse.fullJson

  convertedMetadata = translate.translateCategoryDetails(parsedResponse, fullJson)
  return convertedMetadata  'may return an empty container
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @requestNode: roSGNode, a RequestNode instance containing info needed to make the request
Function parseCategoryDetailsError(fullResponse, requestNode)
  return {
    code: getErrorCodeFromResponse(fullResponse)
  }
End Function