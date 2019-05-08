Function init()
  tubiLog("SearchScreen.init")
  m._ = rodash()
  m.constants = m.global.constants
  Request = TubiRequest()
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)
  
  m.spinner = m.top.findNode("spinner")
  m.Keyboard = m.top.findNode("Keyboard")
  m.Keyboard.textEditBox.maxTextLength = 100
  '//::TODO:: there looks like there is a bug when setting a custom focus color background. The focius color is not the right size. 
  '//   When this is fixed in a firmware, we should use a custom focus background color
  '//m.keyboard.focusedKeyColor = m.global.constants.ui.colors.keyboardFocusedText
  m.keyboard.focusedKeyColor = "0x000000FF" '//Set the focus color to black when using the default key background color because there is a bug when the backspace key is not visible
  '//m.keyboard.focusBitmapUri = "pkg:/images/keyboard_search_focused_key.9.png"
  m.keyboard.observeField("text", "onKeyboardTextChanged")

  m.SearchText = m.top.findNode("SearchText")
  m.ResultGrid = m.top.findNode("ResultGrid")
  m.ResultGrid.observeField("itemSelected", "onResultSelected")
  m.ResultGrid.observeField("itemFocused", "onItemFocused")
  
  m.NoResultsMessage = m.top.findNode("NoResultsMessage")
  m.NoResultsMessage.color = m.constants.ui.colors.primaryText

  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("searchResponse", "onSearchResultsReceived")
  m.top.observeField("signedIn", "onSignedInChange")
  m.top.observeField("visible", "onVisible")

  m.SearchText.color = m.global.constants.ui.colors.titleHeader

  m.defaultHeroUri = "pkg:/images/art-blur-background.png"

  m.metadataFetchTaskDTO = MetadataFetchTaskDTO()

  if m.constants.deviceInfo.scaledUi = true then
    m.ResultGrid.focusBitmapUri = "pkg:/images/selector-hd.9.png"
  end if

  m.top.backgroundUriList = [m.defaultHeroUri]

  'set initial tracking values
  m.top.trackingPageInfo = {
    pageType: "search_page"
    pageValues: {}
  }

  ' Used to determine if navigate_within_page events should be sent. Only send when the content grid already
  ' has focus, not when it gains focus.
  m.gridHasFocus = false
  ' Used to know if the grid was in focus when user returns from the detailed screen
  m.bViewedSearchSubPage = false

  loadSearchResults(true)'//load the default search results
End Function


'''''''''''''''''''''''''
' displayLoading
'
' Display the loading spinner or not
Function displayLoading(b = true)
  m.spinner.visible = b
End Function

Function onVisible()
  if m.top.visible = true
    m.top.backgroundUriList = [m.defaultHeroUri]
  end if
End Function

'''''''''''''''''''''''''
' onScreenFocusChange
'
' On focus set to screen, push focus on keyboard or grid.
' This is used when the search screen regains focus after coming back from the details page.
Function onScreenFocusChange()
  if m.top.hasFocus() then
    if m.bViewedSearchSubPage = true
      m.bViewedSearchSubPage = false
      m.ResultGrid.setFocus(true)
    end if
  end if
End Function

' This may filter results based on parental controls so send it again on auth change
Function onSignedInChange()
  tubiLog("SearchScreen.onSignedInChange")
  if m.Keyboard.text <> invalid and m.Keyboard.text.len() > 0 then
    loadSearchResults()
  end if
End Function

Function onSearchResultsReceived()
  tubiLog("SearchScreen.onSearchResultsReceived")
  displayLoading(false)
  response = m.top.searchResponse.response
  if response.code >= 200 and response.code < 300 then 
    m.ResultGrid.content = invalid '//reset content everytime so in case the new results = previous results, then the contemt can refresh. Without refr4eshing content, then the content may appear blank
    m.ResultGrid.content = m.top.searchResponse.convertedMetadata
    if m.top.searchResponse.convertedMetadata <> invalid and m.top.searchResponse.convertedMetadata.getChildCount() > 0 then
      if response.name = m.constants.reqNames.getSearchDefault
        '//display special text when the default search is displaying 
        m.SearchText.text = "Search for movies, TV shows, and people"
      end if
      m.ResultGrid.visible = true
      m.NoResultsMessage.visible = false
    else
      displayNoResults()
    end if
  else
    displayNoResults()
  end if
End Function

Function displayNoResults()
  m.ResultGrid.visible = false
  m.NoResultsMessage.visible = true
  message = "We couldn't find results for "
  message +=  "'" + m.SearchText.text + "'" 
  message += chr(10) 
  message += "Please try again"
  m.NoResultsMessage.text = message
End Function


'''''''''''''''''''''''
' onResultSelected
'
' Handle content grid item selected
Function onResultSelected()
  tubiLog("SearchScreen.onResultSelected")
  if m.ResultGrid.content <> invalid
    selectedContent = m.ResultGrid.content.getChild(m.ResultGrid.itemSelected)
    m.top.trackingComponentInfo = getTrackingComponentInfo(m.ResultGrid.itemSelected, m.ResultGrid.numColumns, selectedContent, m.Tracking)

    if selectedContent <> invalid
      m.top.trackingPageInfo = {
        pageType: "search_page"
        pageValues: {
          query: Left(m.Keyboard.text, 256)
        }
      }
      m.top.contentSelected = selectedContent
      m.gridHasFocus = false
      m.bViewedSearchSubPage = true
    end if
  end if
End Function


''''''''''''''''''''''''''
' onKeyboardTextChanged
'
' Launch a search when the keyboard text has changed
Function onKeyboardTextChanged()
  tubiLog("SearchScreen.onSearchTextChanged " + m.Keyboard.text)

  '//display spinner
  displayLoading()
  '//hide previous content
  m.ResultGrid.visible = false
  m.NoResultsMessage.visible = false

  sKeyboardText = m.Keyboard.text
  m.SearchText.text = LCase(sKeyboardText)
  if sKeyboardText <> invalid and sKeyboardText.trim().len() > 0 then
    loadSearchResults() 
  else
    '//if the search text was empty, clear out any existing results and display the default search results
    loadSearchResults(true)
  end if
End Function


'''''''''''''''''''''
' onItemFocused
'
' Update the info panel when a result item is focused
Function onItemFocused()
  tubiLog("SearchScreen.onItemFocused")
  if m.ResultGrid.content <> invalid
    focusedContent = m.ResultGrid.content.getChild(m.ResultGrid.itemFocused)

    ' Set up the info that the ContentController uses to send navigate_within_page events.
    ' Don't change m.top.navigateWithinPageInfo if the focused content hasn't changed
    ' (protects against re-setting when the focus is set upon returning to search page from details page)
    if m.gridHasFocus = true and m.ResultGrid.itemFocused <> invalid

      searchComponent = invalid
      if m.ResultGrid.numColumns <> invalid
        searchComponent = getTrackingComponentInfo(m.ResultGrid.itemFocused, m.ResultGrid.numColumns, focusedContent, m.Tracking)
      end if

      if searchComponent <> invalid
        navigateWithinPageInfo = {
          pageOneof: m.Tracking.getAnalyticsPage("search_page", {query: Left(m.Keyboard.text, 256)})
          componentOneof: m.Tracking.getAnalyticsComponent(m.oldSearchComponent.componentType, m.oldSearchComponent.componentValues)
          means_of_navigation: "BUTTON"  'MeansOfNavigation enum
          vertical_location_mode: "INDEX"  'LocationMode enum
          horizontal_location_mode: "INDEX"  'LocationMode enum
        }

        if searchComponent.componentValues <> invalid and searchComponent.componentValues.content_tile <> invalid
          navigateWithinPageInfo.vertical_location = searchComponent.componentValues.content_tile.row
          navigateWithinPageInfo.horizontal_location = searchComponent.componentValues.content_tile.col
        end if

        m.top.navigateWithinPageInfo = navigateWithinPageInfo
        m.oldSearchComponent = searchComponent
      end if
    else if m.gridHasFocus = false and m.ResultGrid.itemFocused <> invalid
      'the search grid is gaining focus, so we don't send navigate_within_page events at this time. Instead we just cache information
      'for the next time we send a navigate_within_page event (when the user navigates the search grid)
      m.oldSearchComponent = getTrackingComponentInfo(m.ResultGrid.itemFocused, m.ResultGrid.numColumns, focusedContent, m.Tracking)
    end if
    m.gridHasFocus = true
  end if
End Function



'''''''''''''''''''''
' loadSearchResults
'
' Create a request object for the search and hand the request to the metaDataFetchTask which will actually make the request
Function loadSearchResults(bDefaultResults = false)
  tubiLog("SearchScreen.loadSearchResults")
  searchText = m.Keyboard.text
  ' cancel any in-flight requests
  m.global.metadataFetchTask.cancel = m.metadataFetchTaskDTO.createCancel(invalid, m.top, "searchResponse")

  if bDefaultResults = false
    m.global.metadataFetchTask.request = m.metadataFetchTaskDTO.createRequest("search", m.top, "searchResponse", m.constants.reqNames.searchAPI, searchText)
    m.global.trackingLoggingTask.trackEvent = {
      type: "search"
      values: {
        query: Left(searchText, 256)
        search_type: "PAGE" 'SearchType enum
      }
    }
  else 
    m.global.metadataFetchTask.request = m.metadataFetchTaskDTO.createRequest("featured", m.top, "searchResponse", m.constants.reqNames.getSearchDefault)
  end if

End Function


Function getTrackingComponentInfo(itemIndex, numColumns, contentNode, trackingLib)
  if trackingLib <> invalid
    column = 1 + (itemIndex MOD numColumns)
    row = 1 + (itemIndex \ numColumns)

    return {
      componentType: "search_result_component"
      componentValues: {
        content_tile: trackingLib.getAnalyticsTile(contentNode, column, row)
      }
    }
  end if

  return invalid
End Function

'''''''''''''''''''''''
' onKeyEvent
'
Function onKeyEvent(key As String, press As Boolean) As Boolean
  tubiLog("SearchScreen.onKeyEvent")
  if press then
    ' Only focus on content grid if animation is not in process, and if there is actually content there
    if key = "right" and m.Keyboard.isInFocusChain() and m.ResultGrid.content <> invalid and m.ResultGrid.content.getChildCount() > 0 then
      m.ResultGrid.setFocus(true)
      m.gridHasFocus = true 
      return true
    else if key = "left" and m.ResultGrid.isInFocusChain() then
      m.Keyboard.setFocus(true)
      m.gridHasFocus = false
      return true
    else if key = "back" and m.ResultGrid.isInFocusChain() then
      '//when the user hits BACK, then set the keyboard to focus
      '//jump to left most visible thumbnail in the grid
      nFocused = m.ResultGrid.itemFocused
      nColumns = m.ResultGrid.numColumns
      nJumpTo = Int(nFocused/nColumns) * nColumns

      m.ResultGrid.jumpToItem = nJumpTo
      m.Keyboard.setFocus(true)
      m.gridHasFocus = false
      return true
    end if
  end if
  return false
End Function