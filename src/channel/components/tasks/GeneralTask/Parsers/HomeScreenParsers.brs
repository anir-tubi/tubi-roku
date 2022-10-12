' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseHomeScreenContentSuccess(fullResponse, reqInfo)
  experiments = TubiExperiments(m.constants)
  translate = TubiMetadataTranslate(m.constants, experiments)
  parsedResponse = fullResponse.data

  contentMode = invalid
  isKidsMode = invalid

  uiMode = "standard"

  if reqInfo <> invalid AND reqInfo.options <> invalid

    options = reqInfo.options
    if options <> invalid AND options.params <> invalid
      contentMode = options.params.contentMode

      if contentMode = invalid
        contentMode = options.params.content_mode
      end if

      isKidsMode = options.params.isKidsMode
    end if

    uiMode = reqInfo.uiMode

  end if

  isSignedInUser = false
  if reqInfo <> invalid
    isSignedInUser = reqInfo.isSignedInUser
  end if

  convertedMetadata = translate.translateFIFAHomescreen(parsedResponse, contentMode, isKidsMode, uiMode, isSignedInUser)

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

  isSignedInUser = false

  if reqInfo <> invalid
    isSignedInUser = reqInfo.isSignedInUser

    options = reqInfo.options
    if options <> invalid AND options.params <> invalid
      contentMode = options.params.contentMode
    end if
  end if


  convertedMetadata = translate.translateContainerForHomeScreen(parsedResponse, fullJson, orientation, bFullData, contentMode, isSignedInUser)
  return convertedMetadata  'may return an empty container
End Function
