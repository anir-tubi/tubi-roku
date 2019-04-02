Function init()
  tubiLog("SearchScreen.init")
  m._ = rodash()
  m.constants = m.global.constants
  Request = TubiRequest()
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)

  m.Keyboard = m.top.findNode("Keyboard")
  m.Keyboard.observeField("text", "onKeyboardTextChanged")
  m.SearchText = m.top.findNode("SearchText")
  m.ResultGrid = m.top.findNode("ResultGrid")
  m.ResultGrid.observeField("itemSelected", "onResultSelected")
  m.ResultGrid.observeField("itemFocused", "onItemFocused")
  m.NoResultsMessage = m.top.findNode("NoResultsMessage")
  m.Cursor = m.top.findNode("Cursor")
  m.InfoPanel = m.top.findNode("SearchInfoPanel")
  m.UpdatingMessage = m.top.findNode("UpdatingMessage")
  m.UpdatingMessageText = m.UpdatingMessage.findNode("SearchUpdatingText")
  m.UpdatingSpinner = m.UpdatingMessage.findNode("SearchSpinner")

  m.TextEntryAnimation = m.top.findNode("TextEntryAnimation")
  m.TranslationInterpolator = m.top.findNode("TextEntryTranslationInterpolator")
  m.ScaleInterpolator = m.top.findNode("TextEntryScaleInterpolator")
  m.KeyboardInterpolator = m.top.findNode("KeyboardTranslationInterpolator")
  m.InfoPanelOpacityInterpolator = m.top.findNode("InfoPanelOpacityInterpolator")
  m.SearchHintOpacityInterpolator = m.top.findNode("SearchHintOpacityInterpolator")

  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("searchResponse", "onSearchResultsReceived")
  m.top.observeField("signedIn", "onSignedInChange")

  ' While we aren't loading a seeded "Trending Searches", set the text to focus color
  m.SearchText.color = m.global.constants.ui.colors.focused ' default is white when no search term is entered
  m.UpdatingMessageText.color = m.global.constants.ui.searchUpdatingText

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

  loadSearchResults(true)'//load the default search results
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
  response = m.top.searchResponse.response
  if response.code >= 200 and response.code < 300 then 
    m.ResultGrid.content = m.top.searchResponse.convertedMetadata
    if m.top.searchResponse.convertedMetadata <> invalid and m.top.searchResponse.convertedMetadata.getChildCount() > 0 then
      if response.name = m.constants.reqNames.getSearchDefault
        '//display special text when the default search is displaying 
        m.SearchText.text = "Trending Searches"
        m.SearchText.color = m.global.constants.ui.colors.titleHeader
        m.Cursor.visible = false
        '//::TODO:: set Number of results textfield to = "Popular titles this week"
      end if
      m.ResultGrid.visible = true
      m.NoResultsMessage.visible = false
    else
      m.ResultGrid.visible = false
      m.NoResultsMessage.visible = true
    end if
  else
    'TODO(Chris): Show error modal here
  end if
End Function

'''''''''''''''''''''''''
' onScreenFocusChange
'
' On focus set to screen, push focus on keyboard or grid
Function onScreenFocusChange()
  if m.top.hasFocus() then
    if m.InfoPanel.opacity = 0.0 then
      m.Keyboard.setFocus(true)
    else
      m.ResultGrid.setFocus(true)
    end if
  end if
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
    end if
  end if
End Function


''''''''''''''''''''''''''
' onKeyboardTextChanged
'
' Launch a search when the keyboard text has changed
Function onKeyboardTextChanged()
  tubiLog("SearchScreen.onSearchTextChanged " + m.Keyboard.text)
  m.SearchText.text = m.Keyboard.text
  m.SearchText.color = m.global.constants.ui.colors.focused  
  if m.Keyboard.text <> invalid and m.Keyboard.text.len() > 0 then
    m.Cursor.visible = true
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
    populateInfoPanel(focusedContent)

    if focusedContent <> invalid and focusedContent.backgrounds <> invalid and focusedContent.backgrounds.count() > 0 then
      m.top.backgroundUriList = focusedContent.backgrounds
    else
      m.top.backgroundUriList = [m.defaultHeroUri]
    end if

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


'''''''''''''''''''''''
' onKeyEvent
'
Function onKeyEvent(key As String, press As Boolean) As Boolean
  tubiLog("SearchScreen.onKeyEvent")
  if press then
    ' Only focus on content grid if animation is not in process, and if there is actually content there
    if key = "down" and m.Keyboard.isInFocusChain() and m.TextEntryAnimation.state = "stopped" and m.ResultGrid.content <> invalid and m.ResultGrid.content.getChildCount() > 0 then
      startFocusResultGrid()
      return true
    else if key = "up" and m.ResultGrid.isInFocusChain() and m.TextEntryAnimation.state = "stopped" then
      startFocusKeyboard()
      return true
    end if
  end if
  return false
End Function


''''''''''''''''''''''
' startFocusResultGrid
'
' Animate the keyboard off screen, show the info panel, and focus on the content grid
Function startFocusResultGrid()
  tubiLog("SearchScreen.startFocusResultGrid")
  m.TranslationInterpolator.keyValue = [[85,315],[85,545]]
  m.SearchText.font.size = 34
  m.Cursor.visible = false
  keyboardRect = m.Keyboard.boundingRect()
  m.InfoPanelOpacityInterpolator.keyValue = [0.0, 1.0]
  m.SearchHintOpacityInterpolator.keyValue = [0.0, 0.5]
  m.KeyboardInterpolator.keyValue = [m.Keyboard.translation, [0, -keyboardRect.height]]
  m.TextEntryAnimation.observeField("state", "endFocusResultGrid")
  m.TextEntryAnimation.control = "start"
  m.Keyboard.setFocus(false)
End Function


'''''''''''''''''''''
' endFocusResultGrid
'
' Finalize focus and visibility after the animation
Function endFocusResultGrid()
  tubiLog("SearchScreen.endFocusResultGrid")
  if m.TextEntryAnimation.state = "stopped" then
    m.TextEntryAnimation.unobserveField("state")
    m.ResultGrid.setFocus(true)
  end if
End Function


''''''''''''''''''''''''''
' startFocusKeyboard
'
' Hide the info panel and bring back the keyboard
Function startFocusKeyboard()
  resetMetaData()
  m.TranslationInterpolator.keyValue = [[85,545],[85,315]]
  m.SearchText.font.size = 67
  keyboardRect = m.Keyboard.boundingRect()
  m.InfoPanelOpacityInterpolator.keyValue = [1.0, 0.0]
  m.SearchHintOpacityInterpolator.keyValue = [0.5, 0.0]
  m.KeyboardInterpolator.keyValue = [m.Keyboard.translation, [0, 65]]
  m.TextEntryAnimation.observeField("state", "endFocusKeyboard")
  m.TextEntryAnimation.control = "start"
  m.ResultGrid.setFocus(false)
  m.gridHasFocus = false
End Function


''''''''''''''''''''''''''
' endFocusKeyboard
'
' Finalize focus and visibility after the animation
Function endFocusKeyboard()
  if m.TextEntryAnimation.state = "stopped" then
    m.TextEntryAnimation.unobserveField("state")
    m.Keyboard.setFocus(true)
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

  if m.constants.deviceInfo.limitedUi = true
    m.UpdatingSpinner.visible = false
  end if
End Function

'''''''''''''''''''''
' resetMetaData
'
Function resetMetaData()
  m.top.backgroundUriList = [m.defaultHeroUri]
  populateInfoPanel(invalid)
End Function

'''''''''''''''''''''
' populateInfoPanel
'
Function populateInfoPanel(focusedContent)
  if focusedContent <> invalid
    m.InfoPanel.title = focusedContent.title
    m.InfoPanel.genres = focusedContent.genres
    m.InfoPanel.description = focusedContent.description
    info = {}
    info.releaseDate = focusedContent.releaseDate
    info.length = focusedContent.length
    info.rating = focusedContent.rating
    if (focusedContent.hasSubtitles or not m._.empty(focusedContent.subtitleTracks))
      info.hasCC = true
    else
      info.hasCC = false
    end if

    m.InfoPanel.lineOneData = info
    m.InfoPanel.calculateHeight = true
  else 
    m.InfoPanel.title = ""
    m.InfoPanel.genres = []
    m.InfoPanel.description = ""
    m.InfoPanel.lineOneData = {}
  end if
End Function


Function getTrackingComponentInfo(itemIndex, numColumns, contentNode, trackingLib)
  if trackingLib <> invalid
    column = (1 + itemIndex) MOD numColumns
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