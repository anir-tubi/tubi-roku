' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseCategoryDetailsSuccess(fullResponse, _reqInfo)
  translate = TubiMetadataTranslate(m.constants)

  parsedResponse = fullResponse.data
  fullJson = fullResponse.fullJson

  convertedMetadata = translate.translateCategoryDetails(parsedResponse, fullJson)
  return convertedMetadata  'may return an empty container
End Function
