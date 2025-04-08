' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseDefaultSearchSuccess(fullResponse, reqInfo)
  parsedResponse = fullResponse.data
  fullJson = fullResponse.fullJson

  orientation = m.constants.ui.gridItemTypes.portrait
  bFullData = true
  contentMode = invalid
  isSignedInUser = false
  screenId = m.constants.ui.screenIds.searchScreen

  if reqInfo <> invalid AND reqInfo.options <> invalid
    if reqInfo.isSignedInUser <> invalid
      isSignedInUser = reqInfo.isSignedInUser
    end if

    if reqInfo.screenId <> invalid
      screenId = reqInfo.screenId
    end if

    options = reqInfo.options
    if options <> invalid AND options.params <> invalid
      contentMode = options.params.contentMode
    end if

  end if

  convertedMetadata = m.metadataTranslate.translateContainer(parsedResponse, fullJson, orientation, bFullData, contentMode, screenId, isSignedInUser)

  parsedData = CreateObject("roSGNode", "SearchContentNode")
  parsedData.searchText = ""
  parsedData.isDefaultSearchResults = true
  parsedData.results = convertedMetadata
  return parsedData

End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseSearchAPISuccess(fullResponse, reqInfo)
  parsedResponse = fullResponse.data

  isSignedInUser = false
  if reqInfo <> invalid
    isSignedInUser = reqInfo.isSignedInUser
  end if

  convertedMetadata = m.metadataTranslate.translateSearchResults(parsedResponse, isSignedInUser)
  
  parsedData = CreateObject("roSGNode", "SearchContentNode")
  parsedData.searchText = reqInfo.searchText
  parsedData.inputDevice = reqInfo.inputDevice
  parsedData.results = convertedMetadata
  return parsedData
End Function


' @fullResponse: assocArray, as returned by Request.handleEvent, but with
'                            .data value converted from JSON to AA already
' @reqInfo: AA, info passed in for request as part of generalTask_makeRequest containing info needed to make the request
Function parseAutocompleteAPISuccess(fullResponse, reqInfo)
  parsedResponse = fullResponse.data

  aSuggestions = []
  aDataSuggestions = parsedResponse.suggestions
  if isNonEmptyArray(aDataSuggestions) = true
    for i = 0 to aDataSuggestions.count() - 1
      if isNonEmptyString(aDataSuggestions[i]) = true
        contentNode = CreateObject("roSGNode", "ContentNode")
        contentNode.title = aDataSuggestions[i]
        aSuggestions.push(contentNode)
      end if
    end for
  end if
  
  convertedMetadata = {
    id: parsedResponse.personalization_id
    suggestions: aSuggestions
  }
  return convertedMetadata
End Function
