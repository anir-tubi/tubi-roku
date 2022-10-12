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

  if reqInfo <> invalid AND reqInfo.options <> invalid

    options = reqInfo.options
    if options <> invalid AND options.params <> invalid
      contentMode = options.params.contentMode
    end if

  end if

  convertedMetadata = metadataTranslate.translateContainer(parsedResponse, fullJson, orientation, bFullData, contentMode)

  return convertedMetadata
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseSearchAPISuccess(fullResponse, reqInfo)
  metadataTranslate = TubiMetadataTranslate(m.constants)
  parsedResponse = fullResponse.data

  isSignedInUser = false
  if reqInfo <> invalid
    isSignedInUser = reqInfo.isSignedInUser
  end if

  convertedMetadata = metadataTranslate.translate(parsedResponse, isSignedInUser)
  return convertedMetadata
End Function
