' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_requestedNode: roSGNode, a RequestNode instance containing info needed to make the request
Function parseDetailScreenSingleContentSuccess(fullResponse, _requestNode)
  translate = TubiMetadataTranslate(m.constants)
  parsedResponse = fullResponse.data
  updatedContent = CreateObject("roSGNode", "TubiContentNode")
  translate.translateRecursive(parsedResponse, updatedContent)
  return updatedContent
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @requestNode: roSGNode, a RequestNode instance containing info needed to make the request
Function parseDetailScreenRelatedContentSuccess(fullResponse, requestNode)
  translate = TubiMetadataTranslate(m.constants)
  parsedResponse = fullResponse.data
  relatedContent = translate.translateRelatedContent(parsedResponse)
  relatedContent.id = requestNode.input.contentId
  return relatedContent
End Function
