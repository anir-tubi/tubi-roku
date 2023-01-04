' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseCategoryMyStuffContentSuccess(fullResponse, reqInfo)
  tubiLog("CategoryMyStuffScreenParsers.parseCategoryMyStuffContentSuccess")
  experiments = TubiExperiments(m.constants)
  translate = TubiMetadataTranslate(m.constants, experiments)
  parsedResponse = fullResponse.data
  fullJson = fullResponse.fullJson

  orientation = ""
  container = parsedResponse.container
  contents = parsedResponse.contents
  if contents.Count() > 0
    if container.id = m.constants.ui.categoryIds.history
      '//if this is the continue watching container, then ensure the orientation is landscape
      orientation = m.constants.ui.gridItemTypes.landscapeLarge
    end if
    
    bFullData = false
    contentMode = m.constants.ui.contentMode.homescreen
  
    if reqInfo <> invalid
      options = reqInfo.options
      if options <> invalid AND options.params <> invalid
        contentMode = options.params.contentMode
      end if
    end if
  
    isSignedInUser = false
    if reqInfo <> invalid
      isSignedInUser = reqInfo.isSignedInUser
    end if

    convertedMetadata = translate.translateContainer(parsedResponse, fullJson, orientation, bFullData, contentMode, m.constants.ui.screenIds.myStuffScreen, isSignedInUser)
  else
    convertedMetadata = translate.translateEmptyMyStuffContainer(parsedResponse)
  end if

  
  return convertedMetadata  'may return an empty container
End Function
