' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseCategoryListSuccess(fullResponse, reqInfo)
  parsedResponse = fullResponse.data

  isChannels = false

  if reqInfo <> invalid AND reqInfo.screenId <> invalid
    screenId = reqInfo.screenId

    if screenId = m.constants.ui.screenIds.channelListScreen
      isChannels = true
    end if
  end if

  categoriesListContent = m.metadataTranslate.translateCategoriesListScreen(parsedResponse, isChannels)

  return categoriesListContent
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseCategoryListError(fullResponse, reqInfo)
  screenId = ""

  if reqInfo.screenId <> invalid
    screenId = reqInfo.screenId
  end if

  return {
    code: getErrorCodeFromResponse(fullResponse)
    screenId: screenId
  }
End Function
