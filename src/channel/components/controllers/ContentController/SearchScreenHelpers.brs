' Show the search screen
Function showSearchScreen(constants)
  tubiLog("SearchScreenHelpers.onSearchSelected")
  searchScreen = CreateObject("roSGNode", "SearchScreen")
  searchScreen.observeFieldScoped("contentSelected", "onSearchContentSelected")
  searchScreen.observeFieldScoped("backgroundUriList", "onSearchBackgroundChange")
  searchScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
  searchScreen.observeFieldScoped("searchText", "onSearchTextChanged")
  m.top.observeField("searchResponse", "onSearchResultsReceived")


  searchScreen.id = m.constants.ui.screenIds.searchScreen
  searchScreen.kidsModeEnabled = m.kidsModeEnabled
  searchScreen.backgroundUriList = [m.defaultBackgroundUri]
  searchScreen.searchText = "" '//Set searchText to "" to initiate the search screen and load the default "search results"

  pushScreen(searchScreen, true, true)
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
  m.metadataFetchTask.cancel = m.metadataFetchTaskDTO.createCancel(invalid, searchScreen, "searchResponse")

  if bSearchNonDefaultResults = true
    m.metadataFetchTask.request = m.metadataFetchTaskDTO.createRequest("search", m.top, "searchResponse", m.constants.reqNames.searchAPI, searchText, shouldKidsModeBeSentToServer())
    m.trackingLoggingTask.trackEvent = {
      type: "search"
      values: {
        query: Left(searchText, 256)
        search_type: "PAGE" 'SearchType enum
      }
    }
  else 
    m.metadataFetchTask.request = m.metadataFetchTaskDTO.createRequest("featured", m.top, "searchResponse", m.constants.reqNames.getSearchDefault, invalid, shouldKidsModeBeSentToServer())
  end if
End Function


Function getSearchScreen()
  screen = invalid
  searchScreen = currentScreen()
  if searchScreen <> invalid and searchScreen.id = m.constants.ui.screenIds.searchScreen
    screen = searchScreen
  end if
  return screen
End Function


'''''''''''''''''''''
' onSearchResultsReceived
'
' This is the function to react to the Search API response
Function onSearchResultsReceived()
  tubiLog("SearchScreenHelpers.onSearchResultsReceived")
  searchScreen = getSearchScreen()
  if searchScreen <> invalid and m.top.searchResponse <> invalid
    response = m.top.searchResponse.response
    if response.code >= 200 and response.code < 300 then 
      content = m.top.searchResponse.convertedMetadata
      content.isDefaultSearchResults = (response.name = m.constants.reqNames.getSearchDefault)
      searchScreen.content = content
    else
      searchScreen.content = invalid
    end if
    searchScreen.contentUpdated = true
  end if
End Function