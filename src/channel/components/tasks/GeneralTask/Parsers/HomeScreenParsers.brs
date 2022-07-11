' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseHomeScreenContentSuccess(fullResponse, reqInfo)
  experiments = TubiExperiments(m.constants)
  translate = TubiMetadataTranslate(m.constants, experiments)
  parsedResponse = fullResponse.data

  contentMode = invalid
  isKidsMode = invalid

  authInfo = invalid
  uiMode = "standard"

  if reqInfo <> invalid and reqInfo.options <> invalid

    options = reqInfo.options
    if options <> invalid and options.params <> invalid
      contentMode = options.params.contentMode

      if contentMode = invalid
        contentMode = options.params.content_mode
      end if

      isKidsMode = options.params.isKidsMode
    end if

    authInfo = reqInfo.authInfo
    uiMode = reqInfo.uiMode

  end if

  convertedMetadata = translate.translateHomescreen(parsedResponse, contentMode, authInfo, isKidsMode, uiMode)

  return convertedMetadata
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseCategoryContentSuccess(fullResponse, reqInfo)
  experiments = TubiExperiments(m.constants)
  translate = TubiMetadataTranslate(m.constants, experiments)

  parsedResponse = fullResponse.data
  fullJson = fullResponse.fullJson

  orientation = ""
  bFullData = false
  contentMode = "homeScreen"

  if reqInfo <> invalid
    options = reqInfo.options
    if options <> invalid and options.params <> invalid
      contentMode = options.params.contentMode
    end if
  end if

  convertedMetadata = translate.translateContainer(parsedResponse, fullJson, orientation, bFullData, contentMode)
  return convertedMetadata  'may return an empty container
End Function
