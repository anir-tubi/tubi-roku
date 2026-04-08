' Show the search screen
Function showSearchScreen(shouldShowSideNav = true)
  tubiLog("SearchScreenHelpers.onSearchSelected")
  searchScreen = CreateObject("roSGNode", "SearchScreen")
  searchScreen.observeFieldScoped("contentSelected", "onSearchContentSelected")
  searchScreen.observeFieldScoped("backgroundUriList", "onSearchBackgroundChange")
  searchScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
  searchScreen.observeFieldScoped("componentInteractionInfo", "onComponentInteractionInfoChange")
  searchScreen.observeFieldScoped("autoCompleteSearchText", "onAutoCompleteSearchTextChanged")
  searchScreen.observeFieldScoped("searchText", "onSearchTextChanged")
  searchScreen.observeFieldScoped("transportVoiceResponse", "onTransportVoiceResponse")
  searchScreen.observeFieldScoped("contentToPlay", "onSearchContentToPlay")

  searchScreen.isUserEligibleForTrendingSearchContents = (isUserInAdultsMode() = true AND isDeviceInUS() = true AND isKidsUIOn() = false)

  if isOneTrustConsentEnabled() = false
    searchScreen.isKidsModeAvailable = true
  end if

  searchScreen.id = m.constants.ui.screenIds.searchScreen
  searchScreen.searchText = "" '//Set searchText to "" to initiate the search screen and load the default "search results"

  searchScreen.shouldTrackViewableImpressionEvent = (isUserInAdultsMode() = true AND isKidsUIOn() = false)
  searchScreen.shouldShowSideNav = shouldShowSideNav

  pushScreen(searchScreen, true, true)
  return searchScreen
End Function


Function onSearchContentSelected(msg)
  tubiLog("SearchScreenHelpers.onSearchContentSelected")
  m.autoplayContext = invalid

  screen = msg.getRoSGNode()
  content = msg.getData()
  playbackSource = {
    "srcForAnalytic": m.constants.player.playbackSource.unknown
    "srcForAds": m.constants.player.playbackOrigin.search
  }

  processUserContentSelection(content, screen, playbackSource)
End Function


Function onSearchContentToPlay(msg)
  screen = msg.getRoSGNode()
  content = msg.getData()

  playbackSource = {
    "srcForAnalytic": m.constants.player.playbackSource.unknown
    "srcForAds": m.constants.player.playbackOrigin.search
  }

  processUserPlayAction(content, screen, playbackSource)
End Function


'''''''''''''''''''''
' onAutoCompleteSearchTextChanged
'
' The user has selected an item from the autocomplete suggestion list.
' Perform a search for the text associated with this item.
Function onAutoCompleteSearchTextChanged(msg)
  tubiLog("SearchScreenHelpers.onAutoCompleteSearchTextChanged")
  searchScreen = msg.getRoSGNode()
  searchText = msg.getData()
  if isNonEmptyString(searchText) = true AND searchScreen.autocompleteContent <> invalid AND isNonEmptyString(searchScreen.autocompleteContent.id) = true
    '//Send analytics that an autocomplete suggestion was selected
    componentValues = {
      search_suggestion: searchText
    }
    componentInteractionInfo = getComponentInteractionInfo("CONFIRM", searchScreen.trackingPageInfo, "search_suggestions_component", componentValues)
    sendComponentInteractionInfo(componentInteractionInfo)

    '//Call backend to get search results on the autocomplete suggestion that was selected
    searchFromScreen(searchText, searchScreen.autocompleteContent.id)
  end if
End Function


'''''''''''''''''''''
' onSearchTextChanged
'
' The search Text has changed so create a request object for the search and hand the request to the metaDataFetchTask which will actually make the request
Function onSearchTextChanged(msg)
  tubiLog("SearchScreenHelpers.onSearchTextChanged")
  ' cancel any in-flight requests
  searchScreen = msg.getRoSGNode()
  searchText = searchScreen.searchText
  searchFromScreen(searchText, invalid, searchScreen.inputDeviceLastUsedForSearch)
End Function


Function searchFromScreen(searchText, personalizationID = invalid, inputDevice = "")
  bSearchNonDefaultResults = (searchText <> invalid AND Len(searchText) > 0)

  if m.currentSearchScreenRequestInfo <> invalid
    m.cancelRequest(m.currentSearchScreenRequestInfo)
  end if

  if m.currentAutocompleteSearchScreenRequestInfo <> invalid
    m.cancelRequest(m.currentAutocompleteSearchScreenRequestInfo)
  end if

  kidsMode = shouldKidsModeBeSentToServer()

  if bSearchNonDefaultResults = true
    includeLinear = isUserInAdultsMode() = true AND isKidsUIOn() = false
    getStatsigExperimentResource("roku_search_creator_tile", "roku_search_creator_tile_v1", true)
    if isNonEmptyString(inputDevice) = false
      ' assume the input device is remote unless specified otherwise.
      inputDevice = m.constants.inputDevices.remote
    end if
    searchReqInfo = m.CmsApi.createSearchReqInfo(searchText, kidsMode, personalizationID, includeLinear)
    m.currentSearchScreenRequestInfo = m.makeRequest({
      url: searchReqInfo.url
      requestType: m.constants.reqNames.getSearchScreen
      options: searchReqInfo.options
      successCallback: onSearchSuccessResponse
      errorCallback: onSearchErrorResponse
      responseType: "node"
      screenId: m.constants.ui.screenIds.searchScreen
      isSignedInUser: isLoggedInUser()
      searchText: searchText
      inputDevice: inputDevice
      analyticsScreenId: m.constants.ui.screenIds.searchScreen
    })

    if isKidsUIOn() = false AND getExperimentResource("roku_search_autocomplete", "roku_search_autocomplete_v3", true).enabled = true
      autocompleteReqInfo = m.CmsApi.createAutocompleteReqInfo(searchText)
      m.currentAutocompleteSearchScreenRequestInfo = m.makeRequest({
        url: autocompleteReqInfo.url
        requestType: m.constants.reqNames.getAutocomplete
        options: autocompleteReqInfo.options
        successCallback: onAutocompleteSuccessResponse
        silenceCallbackWarnings: true
        responseType: "assocarray"
        analyticsScreenId: m.constants.ui.screenIds.searchScreen
      })
    end if

  else
    categoryId = m.constants.ui.categoryIds.featured
    requestOptions = {}

    if isUserInAdultsMode() = true AND isDeviceInUS() = true AND isKidsUIOn() = false
      categoryId = m.constants.ui.categoryIds.topSearched
    end if

    categoryReqInfo = m.CmsApi.createCategoryReqInfo(categoryId, kidsMode, requestOptions)
    m.makeRequest({
      url: categoryReqInfo.url
      requestType: m.constants.reqNames.getSearchDefault
      options: categoryReqInfo.options
      successCallback: onSearchDefaultSuccessResponse
      errorCallback: onSearchDefaultErrorResponse
      responseType: "node"
      screenId: m.constants.ui.screenIds.searchScreen
      isSignedInUser: isLoggedInUser()
      analyticsScreenId: m.constants.ui.screenIds.searchScreen
    })

  end if
End Function


Function getSearchScreen()
  screen = invalid
  searchScreen = getCurrentScreen()
  if searchScreen <> invalid AND searchScreen.id = m.constants.ui.screenIds.searchScreen
    screen = searchScreen
  end if
  return screen
End Function


'''''''''''''''''''''
' onSearchSuccessResponse
'
' This is the function to react to the Search API response
Function onSearchSuccessResponse(response)
  tubiLog("SearchScreenHelpers.onSearchSuccessResponse")
  searchScreen = getSearchScreen()
  if searchScreen <> invalid AND response <> invalid
    filterComingSoonFromSearchResults(response)
    searchScreen.content = response

    pageValues = {
      query: Left(response.searchText, 256)
      search_type: "PAGE" 'SearchType enum
      personalization_id: response.results.personalizationId
      input_device: response.inputDevice
    }

    m.trackingLoggingTask.trackEvent = {
      type: "search"
      values: pageValues
    }

    searchScreen.contentUpdated = true
  end if
End Function


'''''''''''''''''''''
' onSearchDefaultSuccessResponse
'
' This is the function to react to the Search API response
Function onSearchDefaultSuccessResponse(response)
  tubiLog("SearchScreenHelpers.onSearchDefaultSuccessResponse")
  searchScreen = getSearchScreen()
  if searchScreen <> invalid AND response <> invalid
    prependEventHubTileToSearchResults(response)

    searchScreen.content = response
    searchScreen.contentUpdated = true
  end if
End Function


' Removes coming soon tiles from search results when the user is not in the coming soon experiment.
' The experiment tracking event fires automatically via getStatsigExperimentResource.
' @param response - SearchContentNode returned by the search API parser
Function filterComingSoonFromSearchResults(response) as Void
  results = response.results
  if results = invalid
    return
  end if

  for i = results.getChildCount() - 1 to 0 step -1
    child = results.getChild(i)
    bIsComingSoon = isComingSoonContent(child)
    if bIsComingSoon = true
      ' Passing true explicitly to fire the Statsig exposure event only when we know that the search results include coming soon content.
      experiment = getStatsigExperimentResource("roku_search_coming_soon", "roku_search_coming_soon_v1", true)
      if experiment.enabled = true
        ' Once we know that the search results include coming soon content and the experiment is enabled, we can return early.
        return
      end if

      results.removeChild(child)
    end if
  end for
End Function


'''''''''''''''''''''
' onSearchErrorResponse
'
' This is the function to react to the Search API error response
Function onSearchErrorResponse(result)
  tubiLog("SearchScreenHelpers.onSearchErrorResponse")
  searchScreen = getSearchScreen()
  if searchScreen <> invalid AND result <> invalid
    searchScreen.content = invalid
    searchScreen.contentUpdated = true
  end if
End Function


'''''''''''''''''''''
' onAutocompleteSuccessResponse
'
' This is the function to react to the Autocomplete API response
Function onAutocompleteSuccessResponse(response)
  tubiLog("SearchScreenHelpers.onAutocompleteSuccessResponse")
  searchScreen = getSearchScreen()
  if searchScreen <> invalid AND response <> invalid
    searchScreen.autocompleteContent = response
  end if
End Function


'''''''''''''''''''''
' onSearchDefaultErrorResponse
'
' This is the function to react to the Search API error response
Function onSearchDefaultErrorResponse(result)
  tubiLog("SearchScreenHelpers.onSearchDefaultErrorResponse")
  searchScreen = getSearchScreen()
  if searchScreen <> invalid AND result <> invalid
    searchScreen.content = invalid
    searchScreen.contentUpdated = true
  end if
End Function


'''''''''''''''''''''
' updateSearchContentNode function sets needsLogin to false for all nodes in search results. so lock icon will not be displayed.
'
' @screen: node, search screen
Function updateSearchContentNode(searchScreen)
  tubiLog("SearchScreenHelpers.updateSearchContentNode")
  content = searchScreen.content
  if content <> invalid
    for i = 0 to content.getChildCount() - 1
      content.getChild(i).needsLogin = false
    end for
    searchScreen.contentUpdated = true
  end if

End Function


' Prepends the event hub tile as the first search result on the default search screen.
' Uses bodyExtraSmallStrong typography for the title to match search result tile styling.
' @param response - The search API response containing a results ContentNode
Function prependEventHubTileToSearchResults(response) as Void
  if response.results = invalid then return

  eventHubTileAA = getEventHubTileAA("trending_search_entry")
  if eventHubTileAA = invalid then return

  eventHubTileAA.titleTypography = getTypographyConstants().ids.bodyExtraSmallStrong
  eventHubTileNode = CreateObject("roSGNode", "ContentNode")
  eventHubTileNode.update(eventHubTileAA, true)
  response.results.insertChild(eventHubTileNode, 0)
End Function
