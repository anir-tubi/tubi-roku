' Show the search screen
Function showSearchScreen(constants)
  tubiLog("SearchScreenHelpers.onSearchSelected")
  searchScreen = CreateObject("roSGNode", "SearchScreen")
  searchScreen.observeFieldScoped("contentSelected", "onSearchContentSelected")
  searchScreen.observeFieldScoped("backgroundUriList", "onSearchBackgroundChange")
  searchScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")

  searchScreen.id = m.constants.ui.screenIds.searchScreen
  searchScreen.kidsModeEnabled = isKidsModeEnabled()
  searchScreen.backgroundUriList = [constants.ui.uris.defaultBackground]

  pushScreen(searchScreen, true, true)
End Function


Function onSearchContentSelected(msg)
  tubiLog("SearchScreenHelpers.onSearchContentSelected")
  m.autoplayContext = invalid
  searchScreen = msg.getRoSGNode()
  showDetailScreen(searchScreen.contentSelected)
End Function