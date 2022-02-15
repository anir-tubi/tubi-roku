' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @requestNode: roSGNode, a RequestNode instance containing info needed to make the request
Function parseEPGChannelIdsSuccess(fullResponse, requestNode)
  translate = TubiMetadataTranslate(m.constants)

  parsedResponse = fullResponse.data
  epgChannelIdsResponse = translate.translateEPGChannelIds(parsedResponse, requestNode.input.requestorID)
  return epgChannelIdsResponse
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @requestNode: roSGNode, a RequestNode instance containing info needed to make the request
Function parseEPGChannelIdsError(fullResponse, requestNode)
  return {
    code: getErrorCodeFromResponse(fullResponse)
    requestorID : requestNode.input.requestorID
  }
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to Array already
' @requestNode: roSGNode, a RequestNode instance containing info needed to make the request
Function parseEPGProgramsSuccess(fullResponse, requestNode)
  translate = TubiMetadataTranslate(m.constants)
  parsedResponse = fullResponse.data
  epgProgramsResponse = translate.translateEPGPrograms(parsedResponse, requestNode.input.requestorID )
  return epgProgramsResponse
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @requestNode: roSGNode, a RequestNode instance containing info needed to make the request
Function parseEPGProgramsError(fullResponse, requestNode)
  if requestNode.input.options <> invalid and requestNode.input.options.params <> invalid
    contentId = requestNode.input.options.params.content_id
  end if
  return {
    code: getErrorCodeFromResponse(fullResponse)
    requestorID : requestNode.input.requestorID
    contentID : contentId
  }
End Function