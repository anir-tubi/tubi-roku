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


' Success making changes to the like/dislike settings
Function parseContentRateSuccess(fullResponse, requestNode)
  returnResponse = {}
  if requestNode <> invalid and requestNode.input <> invalid and requestNode.input.options <> invalid and requestNode.input.options.body <> invalid
    returnResponse = requestNode.input.options.body
  end if
  
  return returnResponse
End Function


' Error making changes to the like/dislike settings
Function parseContentRateError(fullResponse, requestNode)
  returnParsed = {}
  if requestNode <> invalid and requestNode.input <> invalid and requestNode.input.options <> invalid and requestNode.input.options.body <> invalid
    returnParsed = parseJSON(requestNode.input.options.body)
  end if
  if fullResponse <> invalid and fullResponse.code <> invalid
    returnParsed.code = fullResponse.code
  end if
  
  return returnParsed
End Function