' Show the search screen
Function showSearchScreen(constants)
  tubiLog("SearchScreenHelpers.onSearchSelected")
  searchScreen = CreateObject("roSGNode", "SearchScreen")
  searchScreen.observeFieldScoped("contentSelected", "onSearchContentSelected")
  searchScreen.observeFieldScoped("backgroundUriList", "onSearchBackgroundChange")
  searchScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
  searchScreen.observeFieldScoped("searchText", "onSearchTextChanged")
  searchScreen.observeFieldScoped("transportVoiceResponse", "onTransportVoiceResponse")
  searchScreen.observeFieldScoped("contentToPlay", "onContentToPlay")

  searchScreen.id = m.constants.ui.screenIds.searchScreen
  searchScreen.kidsModeEnabled = isKidsUIOn()
  searchScreen.backgroundUriList = [m.defaultBackgroundUri]
  searchScreen.searchText = "" '//Set searchText to "" to initiate the search screen and load the default "search results"

  pushScreen(searchScreen, true, true)
  return searchScreen
End Function


Function onSearchContentSelected(msg)
  tubiLog("SearchScreenHelpers.onSearchContentSelected")
  m.autoplayContext = invalid
  searchScreen = msg.getRoSGNode()
  showDetailScreen(searchScreen.contentSelected, true)
End Function


'''''''''''''''''''''
' onSearchTextChanged
'
' The search Text has changed so c  reate a request object for the search and hand the request to the metaDataFetchTask which will actually make the request
Function onSearchTextChanged(msg)
  tubiLog("SearchScreenHelpers.onSearchTextChanged")
  ' cancel any in-flight requests
  searchScreen = msg.getRoSGNode()
  searchText = searchScreen.searchText
  bSearchNonDefaultResults = (searchText <> invalid and Len(searchText) > 0)

  if m.currentSearchScreenRequestNode <> invalid
    m.cancelRequest(m.currentSearchScreenRequestNode) 
  end if

  kidsMode = shouldKidsModeBeSentToServer()
  
  if bSearchNonDefaultResults = true

    searchReqInfo = m.CmsApi.searchReqInfo(searchText, kidsMode)
    m.currentSearchScreenRequestNode = m.makeRequest({
      url: searchReqInfo.url
      requestType: m.constants.reqNames.getSearchScreen
      options: searchReqInfo.options
      successCallback: onSearchSuccessResponse
      errorCallback: onSearchErrorResponse
      responseType: "node"
    }) 

    m.trackingLoggingTask.trackEvent = {
      type: "search"
      values: {
        query: Left(searchText, 256)
        search_type: "PAGE" 'SearchType enum
      }
    }
  else 

    categoryReqInfo = m.CmsApi.categoryReqInfo(m.constants.ui.categoryIds.featured, m.constants.reqNames.getSearchDefault, kidsMode)
    m.currentSearchScreenRequestNode = m.makeRequest({
      url: categoryReqInfo.url
      requestType: m.constants.reqNames.getSearchDefault
      options: categoryReqInfo.options
      successCallback: onSearchDefaultSuccessResponse
      errorCallback: onSearchDefaultErrorResponse
      responseType: "node"
    }) 

  end if
End Function


Function getSearchScreen()
  screen = invalid
  searchScreen = getCurrentScreen()
  if searchScreen <> invalid and searchScreen.id = m.constants.ui.screenIds.searchScreen
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
  if searchScreen <> invalid and response <> invalid
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
  if searchScreen <> invalid and result <> invalid
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
  if searchScreen <> invalid and response <> invalid
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
  if searchScreen <> invalid and result <> invalid
    searchScreen.content = invalid
    searchScreen.contentUpdated = true
  end if
End Function