' Show the search screen
Function showSearchScreen()
  tubiLog("SearchScreenHelpers.onSearchSelected")
  searchScreen = CreateObject("roSGNode", "SearchScreen")
  searchScreen.observeFieldScoped("contentSelected", "onSearchContentSelected")
  searchScreen.observeFieldScoped("backgroundUriList", "onSearchBackgroundChange")
  searchScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
  searchScreen.observeFieldScoped("searchText", "onSearchTextChanged")
  searchScreen.observeFieldScoped("transportVoiceResponse", "onTransportVoiceResponse")
  searchScreen.observeFieldScoped("contentToPlay", "onSearchContentToPlay")

  searchScreen.isUserEligibleForTrendingSearchBelowExperiment = (isUserInAdultsMode() = true AND isDeviceInUS() = true AND isKidsUIOn() = false)
  searchScreen.id = m.constants.ui.screenIds.searchScreen
  searchScreen.searchText = "" '//Set searchText to "" to initiate the search screen and load the default "search results"

  pushScreen(searchScreen, true, true)
  return searchScreen
End Function


Function onSearchContentSelected(msg)
  tubiLog("SearchScreenHelpers.onSearchContentSelected")
  m.autoplayContext = invalid
  searchScreen = msg.getRoSGNode()

  selectedContent = msg.getData()
  'Launch the full player if it's linear contnet otherwise launch details screen
  if selectedContent <> invalid AND selectedContent.type = m.constants.ui.contentTypes.linear
    playbackSource = {
      "srcForAnalytic": m.constants.player.playbackSource.unknown
      "srcForAds":m.constants.player.playbackOrigin.search
    }
    playLinearVideoContent(selectedContent, false, searchScreen.id, false, playbackSource)
  else
    playbackSource = {
      "srcForAnalytic": m.constants.player.playbackSource.unknown
      "srcForAds":m.constants.player.playbackOrigin.search
    }

    showDetailScreen(searchScreen.contentSelected, true, invalid, invalid, playbackSource)
  end if
End Function


Function onSearchContentToPlay(msg)
  searchScreen = msg.getRoSGNode()
  content = msg.getData()

  playbackSource = {
    "srcForAnalytic": m.constants.player.playbackSource.unknown
    "srcForAds":m.constants.player.playbackOrigin.search
  }

  if content <> invalid AND content.type = m.constants.ui.contentTypes.linear
    playLinearVideoContent(content, false, searchScreen.id, false, playbackSource)
  else
    showDetailScreen(content, false, skipDetailScreen, invalid, playbackSource)
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
  bSearchNonDefaultResults = (searchText <> invalid AND Len(searchText) > 0)

  if m.currentSearchScreenRequestInfo <> invalid
    m.cancelRequest(m.currentSearchScreenRequestInfo)
  end if

  kidsMode = shouldKidsModeBeSentToServer()

  if bSearchNonDefaultResults = true

    searchReqInfo = m.CmsApi.createSearchReqInfo(searchText, kidsMode)
    m.currentSearchScreenRequestInfo = m.makeRequest({
      url: searchReqInfo.url
      requestType: m.constants.reqNames.getSearchScreen
      options: searchReqInfo.options
      successCallback: onSearchSuccessResponse
      errorCallback: onSearchErrorResponse
      responseType: "node"
      screenId: m.constants.ui.screenIds.searchScreen
      isSignedInUser: isLoggedInUser()
    })

    m.trackingLoggingTask.trackEvent = {
      type: "search"
      values: {
        query: Left(searchText, 256)
        search_type: "PAGE" 'SearchType enum
      }
    }

  else
    categoryId = m.constants.ui.categoryIds.featured
    requestOptions = {}

    if isUserInAdultsMode() = true AND isDeviceInUS() = true AND isKidsUIOn() = false
      categoryId = m.constants.ui.categoryIds.topSearched
    end if

    categoryReqInfo = m.CmsApi.createCategoryReqInfo(categoryId, kidsMode, requestOptions)
    m.currentSearchScreenRequestInfo = m.makeRequest({
      url: categoryReqInfo.url
      requestType: m.constants.reqNames.getSearchDefault
      options: categoryReqInfo.options
      successCallback: onSearchDefaultSuccessResponse
      errorCallback: onSearchDefaultErrorResponse
      responseType: "node"
      screenId: m.constants.ui.screenIds.searchScreen
      isSignedInUser: isLoggedInUser()
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
    searchScreen.content = response
    searchScreen.contentUpdated = true
  end if
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
' onSearchDefaultSuccessResponse
'
' This is the function to react to the Search API response
Function onSearchDefaultSuccessResponse(response)
  tubiLog("SearchScreenHelpers.onSearchDefaultSuccessResponse")
  searchScreen = getSearchScreen()
  if searchScreen <> invalid AND response <> invalid
    response.isDefaultSearchResults = true
    searchScreen.content = response
    searchScreen.contentUpdated = true
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

  content = searchScreen.content
  if content <> invalid
    for i = 0 to content.getChildCount()-1
      content.getChild(i).needsLogin = false
    end for
    searchScreen.contentUpdated = true
  end if

End Function
