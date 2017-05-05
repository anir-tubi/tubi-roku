Function init()
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("signedIn", "onSignedInChange")
  m.ToolsMenu = m.top.findNode("ToolsMenu")
  m.OnNow = m.top.findNode("OnNow")
  m.CategoryScreen = m.top.findNode("CategoryScreen")
  m.CategoryScreen.observeField("backgroundUriList", "onCategoryBackgroundChange")
  m.CategoryScreen.observeField("contentSelected", "onCategoryContentSelected")
  m.focusTarget = m.OnNow
End Function


''''''''''''''''''''
' onScreenFocusChange
'
Function onScreenFocusChange() As Void
  tubiLog("HomeScreen.onScreenFocusChange " + focusState(m.top))
  if m.top.isInFocusChain()
    if m.top.hasFocus() then
      m.focusTarget.setFocus(true)
    end if
  end if
End Function


Function onSignedInChange()
  tubiLog("HomeScreen.onSignedInChange")
  m.ToolsMenu.signedIn = m.top.signedIn
  m.CategoryScreen.signedIn = m.top.signedIn
End Function


Function onKeyEvent(key As String, press As Boolean) As Boolean
  tubiLog("HomeScreen.onKeyEvent key = " + key)
  m.lastKeyEvent = Uptime(0)

  if press then
    if key = "back" then
      if m.OnNow.isInFocusChain() then
        'send the back button press to the screen stack (for category screen and sign in/search list)
        showCategoryScreen()
        m.OnNow.control = "dock"
        return true
      else if m.CategoryScreen.isInFocusChain() then
        ' first back button closes docked player, second press shows category menu, third invokes the exit dialog
        if m.OnNow.control = "dock" then
          ' we haven't closed the player yet
          m.OnNow.control = "stop"
          m.CategoryScreen.dockedVideoFrameVisible = false
          return true
        else if not m.CategoryScreen.categoryMenuVisible
          m.CategoryScreen.categoryMenuVisible = true
          return true
        end if
      end if
    else if key = "up"
      if m.OnNow.isInFocusChain() then
        slideFade(m.ToolsMenu, "above", "in", 0.4)
        slideFade(m.OnNow, "below", "out", 0.4)
        m.OnNow.control = "stop"
        m.ToolsMenu.findNode("ToolsMenu").setFocus(true)
        m.top.backgroundUriList = m.ToolsMenu.backgroundUriList
        m.focusTarget = m.ToolsMenu
        return true
      else if m.CategoryScreen.isInFocusChain() then  ' must be category screen focus
        slideFade(m.OnNow, "above", "in", 0.4)
        animate(m.CategoryScreen, m.CategoryScreen.translation, [0, 392], 0.2, 1.0, 0.4)
        m.CategoryScreen.infoVisible = false
        m.CategoryScreen.categoryMenuVisible = false
        m.OnNow.setFocus(true)
        m.OnNow.control = "play"
        m.focusTarget = m.OnNow
        return true
      end if
    else if key = "down"
      if m.ToolsMenu.isInFocusChain() then
        slideFade(m.ToolsMenu, "above", "out", 0.4)
        slideFade(m.OnNow, "below", "in", 0.4)
        m.OnNow.setFocus(true)
        m.OnNow.control = "play"
        m.focusTarget = m.OnNow
        return true
      else if m.OnNow.isInFocusChain() then
        showCategoryScreen()
        m.OnNow.control = "dock"
        m.CategoryScreen.dockedVideoFrameVisible = true
        return true
      end if
    end if
  end if

End Function

Function showCategoryScreen()
  if m.OnNow.isInFocusChain() then
    slideFade(m.OnNow, "above", "out", 0.4)
    animate(m.CategoryScreen, m.CategoryScreen.translation, [0, 0], 1.0, 1.0, 0.4)
    m.CategoryScreen.infoVisible = true
    m.CategoryScreen.setFocus(true)
    m.top.backgroundUriList = m.CategoryScreen.backgroundUriList
    m.focusTarget = m.CategoryScreen
  end if
End Function

Function onCategoryBackgroundChange()
  tubiLog("HomeScreen.onCategoryBackgroundChange")
  if m.CategoryScreen.isInFocusChain() then m.top.backgroundUriList = m.CategoryScreen.backgroundUriList
End Function

Function onCategoryContentSelected()
  tubiLog("HomeScreen.onCategoryContentSelected")
  m.OnNow.control = "stop"  ' make sure we always stop the video before detail screen shows
  m.CategoryScreen.dockedVideoFrameVisible = false
End Function

