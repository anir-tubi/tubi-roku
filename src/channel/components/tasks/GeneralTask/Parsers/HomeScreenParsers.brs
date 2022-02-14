' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @requestNode: roSGNode, a RequestNode instance containing info needed to make the request
Function parseHomeScreenContentSuccess(fullResponse, requestNode)

  experiments = TubiExperiments(m.constants)
  translate = TubiMetadataTranslate(m.constants, experiments)
  parsedResponse = fullResponse.data

  contentMode = invalid
  isKidsMode = invalid
  input = requestNode.input

  authInfo = invalid
  uiMode = "standard"

  if input <> invalid and input.options <> invalid

    options = input.options
    if options <> invalid and options.params <> invalid
      contentMode = options.params.contentMode

      if contentMode = invalid
        contentMode = options.params.content_mode
      end if

      isKidsMode = options.params.isKidsMode
    end if

    authInfo = input.authInfo
    uiMode = input.uiMode

  end if 

  convertedMetadata = translate.translateHomescreen(parsedResponse, contentMode, authInfo, isKidsMode, uiMode)

  return convertedMetadata
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @requestNode: roSGNode, a RequestNode instance containing info needed to make the request
Function parseCategoryContentSuccess(fullResponse, requestNode)

  experiments = TubiExperiments(m.constants)
  translate = TubiMetadataTranslate(m.constants, experiments)

  parsedResponse = fullResponse.data
  fullJson = fullResponse.fullJson

  orientation = ""
  bFullData = false
  contentMode = "homeScreen"

  requestInput = requestNode.input
  if requestInput <> invalid and requestInput.options <> invalid

    options = requestInput.options
    if options <> invalid and options.params <> invalid
      contentMode = options.params.contentMode
    end if

  end if

  convertedMetadata = translate.translateContainer(parsedResponse, fullJson, orientation, bFullData, contentMode)
  return convertedMetadata  'may return an empty container

End Function
