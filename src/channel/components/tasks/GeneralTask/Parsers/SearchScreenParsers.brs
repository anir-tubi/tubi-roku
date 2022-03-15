' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @requestNode: roSGNode, a RequestNode instance containing info needed to make the request
Function parseDefaultSearchSuccess(fullResponse, requestNode)

  metadataTranslate = TubiMetadataTranslate(m.constants)

  parsedResponse = fullResponse.data
  fullJson = fullResponse.fullJson

  orientation = m.constants.ui.gridItemTypes.portrait
  bFullData = true
  contentMode = invalid

  requestInput = requestNode.input
  if requestInput <> invalid and requestInput.options <> invalid

    options = requestInput.options
    if options <> invalid and options.params <> invalid
      contentMode = options.params.contentMode
    end if

  end if

  convertedMetadata = metadataTranslate.translateContainer(parsedResponse, fullJson, orientation, bFullData, contentMode)

  return convertedMetadata

End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_requestedNode: roSGNode, a RequestNode instance containing info needed to make the request
Function parseSearchAPISuccess(fullResponse, _requestNode)

  metadataTranslate = TubiMetadataTranslate(m.constants)
  parsedResponse = fullResponse.data
  convertedMetadata = metadataTranslate.translate(parsedResponse)
  return convertedMetadata

End Function
