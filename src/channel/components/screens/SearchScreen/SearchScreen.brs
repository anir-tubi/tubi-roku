Function init()
  tubiLog("SearchScreen.init")

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

  ' While we aren't loading a seeded "Trending Searches", set the text to focus color
  m.SearchText.color = m.global.constants.ui.colors.focused ' default is white when no search term is entered
  m.UpdatingMessageText.color = m.global.constants.ui.searchUpdatingText

  m.defaultHeroUri = "pkg:/images/art-blur-background.png"

  m.metadataFetchTaskDTO = MetadataFetchTaskDTO()

  if m.global.constants.deviceInfo.scaledUi = true then
    m.ResultGrid.focusBitmapUri = "pkg:/images/selector-hd.9.png"
  end if


  m.top.backgroundUriList = [m.defaultHeroUri]
End Function


Function onSearchResultsReceived()
  tubiLog("SearchScreen.onSearchResultsReceived")
  response = m.top.searchResponse.response
  if response.code >= 200 and response.code < 300 then 
    m.UpdatingMessage.visible = false
    m.top.content = m.top.searchResponse.convertedMetadata
    if m.top.searchResponse.convertedMetadata <> invalid and m.top.searchResponse.convertedMetadata.getChildCount() > 0 then
      m.ResultGrid.visible = true
      m.NoResultsMessage.visible = false
    else
      m.ResultGrid.visible = false
      m.NoResultsMessage.visible = true
    end if
  else
    'TODO(Chris): Show error modal here
      testLog("Search results returned " + stri(response.code))
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
    if selectedContent <> invalid
      m.top.contentSelected = selectedContent
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
  if m.Keyboard.text <> invalid and m.Keyboard.text.len() > 0 then
    loadSearchResults()
  else
    ' if the text was empty, clear out any existing results
    m.top.content = invalid
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
    m.InfoPanel.content = focusedContent
    if focusedContent <> invalid and focusedContent.backgrounds <> invalid and focusedContent.backgrounds.count() > 0 then
      m.top.backgroundUriList = focusedContent.backgrounds
    else
      m.top.backgroundUriList = [m.defaultHeroUri]
    end if
  end if
End Function


'''''''''''''''''''''''
' onKeyEvent
'
Function onKeyEvent(key As String, press As Boolean) As Boolean
  tubiLog("SearchScreen.onKeyEvent")
  if press then
    ' Only focus on content grid if animation is not in process, and if there is actually content there
    if key = "down" and m.Keyboard.isInFocusChain() and m.TextEntryAnimation.state = "stopped" and m.top.content <> invalid and m.top.content.getChildCount() > 0 then
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
  m.TranslationInterpolator.keyValue = [[85,545],[85,315]]
  m.SearchText.font.size = 67
  keyboardRect = m.Keyboard.boundingRect()
  m.InfoPanelOpacityInterpolator.keyValue = [1.0, 0.0]
  m.SearchHintOpacityInterpolator.keyValue = [0.5, 0.0]
  m.KeyboardInterpolator.keyValue = [m.Keyboard.translation, [0, 65]]
  m.TextEntryAnimation.observeField("state", "endFocusKeyboard")
  m.TextEntryAnimation.control = "start"
  m.ResultGrid.setFocus(false)
End Function


''''''''''''''''''''''''''
' endFocusKeyboard
'
' Finalize focus and visibility after the animation
Function endFocusKeyboard()
  if m.TextEntryAnimation.state = "stopped" then
    m.TextEntryAnimation.unobserveField("state")
    m.Cursor.visible = true
    m.Keyboard.setFocus(true)
  end if
End Function


'''''''''''''''''''''
' loadSearchResults
'
Function loadSearchResults()
  tubiLog("SearchScreen.loadSearchResults")
  constants = m.global.constants
  url = constants.urls.cms.urlBase + "/search"
  options = {
    params: {
      "app_id": constants.settings.shortAppName
      "platform": constants.platform
      "search": m.SearchText.text
    }
  }
  ' cancel any in-flight requests
  m.global.metadataFetchTask.cancel = m.metadataFetchTaskDTO.createCancel(invalid, m.top, "searchResponse")
  m.global.metadataFetchTask.request = m.metadataFetchTaskDTO.createRequest("search", m.top, "searchResponse", url, constants.reqNames.searchAPI, options)

  m.UpdatingMessage.visible = true
  if constants.deviceInfo.limitedNewUi = true
    m.UpdatingSpinner.visible = false
  end if
End Function
