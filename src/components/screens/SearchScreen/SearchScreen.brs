Function init()
  tubiLog("SearchScreen.init")

  m.Keyboard = m.top.findNode("Keyboard")
  m.Keyboard.observeField("text", "onKeyboardTextChanged")
  m.SearchText = m.top.findNode("SearchText")
  m.ResultGrid = m.top.findNode("ResultGrid")
  m.ResultGrid.observeField("itemSelected", "onResultSelected")
  m.ResultGrid.observeField("itemFocused", "onItemFocused")
  m.Cursor = m.top.findNode("Cursor")
  m.InfoPanel = m.top.findNode("InfoPanel")

  m.TextEntryAnimation = m.top.findNode("TextEntryAnimation")
  m.TranslationInterpolator = m.top.findNode("TextEntryTranslationInterpolator")
  m.ScaleInterpolator = m.top.findNode("TextEntryScaleInterpolator")
  m.KeyboardInterpolator = m.top.findNode("KeyboardTranslationInterpolator")
  m.InfoPanelOpacityInterpolator = m.top.findNode("InfoPanelOpacityInterpolator")
  m.SearchHintOpacityInterpolator = m.top.findNode("SearchHintOpacityInterpolator")

  m.top.observeField("focusedChild", "onScreenFocusChange")

  ' While we aren't loading a seeded "Trending Searches", set the text to focus color
  m.SearchText.color = m.global.constants.ui.colors.focused ' default is white when no search term is entered
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
  selectedItem = m.ResultGrid.content.getChild(m.ResultGrid.itemSelected)
  m.top.contentSelected = selectedItem
End Function


''''''''''''''''''''''''''
' onKeyboardTextChanged
'
' Launch a search when the keyboard text has changed
Function onKeyboardTextChanged()
  tubiLog("SearchScreen.onSearchTextChanged")
  m.SearchText.text = m.Keyboard.text  
  loadSearchResults()
End Function


'''''''''''''''''''''
' onItemFocused
'
' Update the info panel when a result item is focused
Function onItemFocused()
  m.InfoPanel.content = m.ResultGrid.content.getChild(m.ResultGrid.itemFocused)
End Function


'''''''''''''''''''''''
' onKeyEvent
'
Function onKeyEvent(key As String, press As Boolean) As Boolean
  tubiLog("SearchScreen.onKeyEvent")
  if press then
    ' Only focus on content grid if animation is not in process, and if there is actually content there
    if key = "down" and m.Keyboard.isInFocusChain() and m.TextEntryAnimation.state = "stopped" and m.top.content.getChildCount() > 0 then
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
  m.TranslationInterpolator.keyValue = [[85,315],[85,151]]
  m.SearchText.font.size = 33
  m.Cursor.visible = false
  keyboardRect = m.Keyboard.boundingRect()
  m.InfoPanelOpacityInterpolator.keyValue = [0.0, 1.0]
  m.SearchHintOpacityInterpolator.keyValue = [0.0, 1.0]
  m.KeyboardInterpolator.keyValue = [[0,0], [0, -keyboardRect.height]]
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
  m.TranslationInterpolator.keyValue = [[85,151],[85,315]]
  m.SearchText.font.size = 67
  keyboardRect = m.Keyboard.boundingRect()
  m.InfoPanelOpacityInterpolator.keyValue = [1.0, 0.0]
  m.SearchHintOpacityInterpolator.keyValue = [1.0, 0.0]
  m.KeyboardInterpolator.keyValue = [m.Keyboard.translation, [0, 0]]
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
  settings = m.global.constants.settings
  urlBase = m.global.constants.urls.cms.urlBase
  platform = m.global.constants.platform
  deviceInfo = m.global.constants.deviceInfo

  request = {
    url: urlBase + "/search"
    node: m.top
    field: "content"
    options: {
      params: {
        app_id: settings.shortAppName
        platform: platform
        search: m.SearchText.text
      }
    }
    name: "searchAPI"    
  }
  m.global.metadataFetchTask.request = request
End Function
