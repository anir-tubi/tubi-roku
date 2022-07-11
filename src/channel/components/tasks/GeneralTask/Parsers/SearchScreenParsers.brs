' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseDefaultSearchSuccess(fullResponse, reqInfo)
  metadataTranslate = TubiMetadataTranslate(m.constants)

  parsedResponse = fullResponse.data
  fullJson = fullResponse.fullJson

  orientation = m.constants.ui.gridItemTypes.portrait
  bFullData = true
  contentMode = invalid

  if reqInfo <> invalid and reqInfo.options <> invalid

    options = reqInfo.options
    if options <> invalid and options.params <> invalid
      contentMode = options.params.contentMode
    end if

  end if

  convertedMetadata = metadataTranslate.translateContainer(parsedResponse, fullJson, orientation, bFullData, contentMode)

  return convertedMetadata
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @_reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseSearchAPISuccess(fullResponse, _reqInfo)
  metadataTranslate = TubiMetadataTranslate(m.constants)
  parsedResponse = fullResponse.data
  convertedMetadata = metadataTranslate.translate(parsedResponse)
  return convertedMetadata
End Function
