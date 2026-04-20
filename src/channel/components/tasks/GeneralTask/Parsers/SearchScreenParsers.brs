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

  includeExplore = (reqInfo <> invalid AND reqInfo.includeExplore = true)
  filterCreatorAppsFromRawResponse(parsedResponse, includeExplore)
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


' Removes CREATOR and optionally EXPLORE app entries from the raw search API response before translation.
' @param parsedResponse - raw AA from the V3 search API JSON
' @param includeExplore - boolean, when false removes EXPLORE apps (hub config missing or dates invalid)
Function filterCreatorAppsFromRawResponse(parsedResponse, includeExplore = true) as Void
  apps = parsedResponse.apps
  if isNonEmptyAA(apps) <> true
    return
  end if

  filterCreator = true
  if m.statSigExperiments <> invalid AND m.statSigExperiments.getExperimentResource("roku_search_creator_tile", "roku_search_creator_tile_v1").enabled = true
    filterCreator = false
  end if

  for each appId in apps.keys()
    app = apps[appId]
    if isAA(app) = true AND isNonEmptyString(app.type) = true
      appType = LCase(app.type)
      if filterCreator = true AND appType = m.constants.ui.appTypes.creator
        apps.delete(appId)
      else if includeExplore = false AND appType = m.constants.ui.appTypes.explore
        apps.delete(appId)
      end if
    end if
  end for
End Function
