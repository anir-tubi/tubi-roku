' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @requestNode: roSGNode, a RequestNode instance containing info needed to make the request
Function parseCategoryListSuccess(fullResponse, requestNode)

  experiments = TubiExperiments(m.constants)
  translate = TubiMetadataTranslate(m.constants, experiments)
  parsedResponse = fullResponse.data

  isChannels = false
  input = requestNode.input

  if input <> invalid and input.screenId <> invalid
    screenId = input.screenId

    if screenId = m.constants.ui.screenIds.channelListScreen
      isChannels = true
    end if
  end if 

  categoriesListContent = translate.translateCategoriesListScreen(parsedResponse, isChannels)

  return categoriesListContent
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @requestNode: roSGNode, a RequestNode instance containing info needed to make the request
Function parseCategoryListError(fullResponse, requestNode)
  screenId = ""
  input = requestNode.input

  if input.screenId <> invalid
    screenId = input.screenId
  end if

  return {
    code: getErrorCodeFromResponse(fullResponse)
    screenId: screenId
  }
End Function