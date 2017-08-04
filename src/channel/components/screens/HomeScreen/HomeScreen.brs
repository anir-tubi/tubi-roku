Function init()
  m.constants = m.global.constants
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("signedIn", "onSignedInChange")
  m.top.observeField("showCategoryScreen", "onShowCategoryScreen")
  m.HomeViews = m.top.findNode("HomeViews")
  m.ToolsMenu = m.top.findNode("ToolsMenu")
  m.OnNow = m.top.findNode("OnNow")
  m.CategoryScreen = m.top.findNode("CategoryScreen")
  m.TrackingLoggingTask = m.top.findNode("TrackingLoggingTask")

  m.CategoryScreen.observeField("backgroundUriList", "onCategoryBackgroundChange")
  m.CategoryScreen.observeField("contentSelected", "onCategoryContentSelected")

  m.ToolsMenu.observeField("trackingCount", "onTrackingCountChange")
  m.ToolsMenu.observeField("trackingUri", "onTrackingUriChange")
  m.OnNow.observeField("trackingCount", "onTrackingCountChange")
  m.OnNow.observeField("trackingUri", "onTrackingUriChange")
  m.CategoryScreen.observeField("trackingCount", "onTrackingCountChange")
  m.CategoryScreen.observeField("trackingUri", "onTrackingUriChange")

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
      if m.CategoryScreen.isInFocusChain() then
        ' first back button closes docked player, second press shows category menu, third invokes the exit dialog
        if m.top.onNowContent <> invalid and m.OnNow.control = "dock" then
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
        m.ToolsMenu.trackingCount = m.top.trackingCount
        m.OnNow.trackingUri = ""
        showTools(true)
        showOnNow(false, "below", false)
        m.ToolsMenu.findNode("ToolsMenu").setFocus(true)
        return true
      else if m.CategoryScreen.isInFocusChain() then  ' must be category screen focus
        showCategoryScreen(false)
        m.CategoryScreen.trackingUri = ""
        if m.top.onNowContent <> invalid then
          m.OnNow.trackingCount = m.top.trackingCount
          showOnNow(true, "above", false)
          m.OnNow.setFocus(true)
        else
          m.ToolsMenu.trackingCount = m.top.trackingCount
          showTools(true)
          m.ToolsMenu.findNode("ToolsMenu").setFocus(true)
        end if
        return true
      end if
    else if key = "down"
      if m.ToolsMenu.isInFocusChain() then
        showTools(false)
        m.ToolsMenu.trackingUri = ""
        if m.top.onNowContent <> invalid then
          m.OnNow.trackingCount = m.top.trackingCount
          showOnNow(true, "below", false)
          m.OnNow.setFocus(true)
        else
          m.CategoryScreen.trackingCount = m.top.trackingCount
          showCategoryScreen(true)
          m.CategoryScreen.setFocus(true)
        end if
        return true
      else if m.OnNow.isInFocusChain() then
        m.CategoryScreen.trackingCount = m.top.trackingCount
        m.OnNow.trackingUri = ""
        showCategoryScreen(true)
        showOnNow(false, "above", true)
        m.CategoryScreen.setFocus(true)
        return true
      end if
    end if
  end if

End Function

Function showTools(show)
  if show and not m.ToolsMenu.isInFocusChain()
    ' show
    slideFade(m.ToolsMenu, "above", "in", 0.4)
    m.top.backgroundUriList = m.ToolsMenu.backgroundUriList
    m.focusTarget = m.ToolsMenu
  else if not show and m.ToolsMenu.isInFocusChain()
    ' hide
    slideFade(m.ToolsMenu, "above", "out", 0.4)
  end if
End Function

Function showOnNow(show, direction, dock)
  if show and not m.OnNow.isInFocusChain()
    slideFade(m.OnNow, direction, "in", 0.4)
    m.OnNow.control = "play"
    m.focusTarget = m.OnNow
  else if not show and m.OnNow.isInFocusChain()
    slideFade(m.OnNow, direction, "out", 0.4)
    if dock
      m.OnNow.control = "dock"
      m.CategoryScreen.dockedVideoFrameVisible = true
    else
      m.OnNow.control = "stop"
      m.CategoryScreen.dockedVideoFrameVisible = false
    end if
  end if
End Function

Function showCategoryScreen(show)
  'set the rowPlaceholder value on the CategoryScreen so that keep the correct uri value for analytics
  'basically the number of "rows" that are above the category screen, like "On Now" and "Tools"
  catScreenIndex = getChildIndex(m.HomeViews, m.CategoryScreen)
  if catScreenIndex >= 0
    onNowVisible = 0
    if m.constants.ui.onnow.on = false
      onNowVisible = 1
    end if
    m.CategoryScreen.rowPlaceholder = catScreenIndex - onNowVisible
  end if

  if show and not m.CategoryScreen.isInFocusChain()
    animate(m.CategoryScreen, m.CategoryScreen.translation, [0, 0], 1.0, 1.0, 0.4)
    m.CategoryScreen.infoVisible = true
    m.top.backgroundUriList = m.CategoryScreen.backgroundUriList
    m.focusTarget = m.CategoryScreen
  else if not show and m.CategoryScreen.isInFocusChain()
    animate(m.CategoryScreen, m.CategoryScreen.translation, [0, 392], 0.2, 1.0, 0.4)
    m.CategoryScreen.infoVisible = false
    m.CategoryScreen.categoryMenuVisible = false
  end if
End Function

' callback for m.top.showCategoryScreen
Function onShowCategoryScreen()
  tubiLog("HomeScreen.onShowCategoryScreen")
  showCategoryScreen(true)
  if m.OnNow.isInFocusChain() then showOnNow(false, "above", true)
  if m.ToolsMenu.isInFocusChain() then showTools(false)
  m.CategoryScreen.setFocus(true)
End Function

Function onCategoryBackgroundChange()
  tubiLog("HomeScreen.onCategoryBackgroundChange")
  if m.CategoryScreen.isInFocusChain() then m.top.backgroundUriList = m.CategoryScreen.backgroundUriList
End Function

Function onCategoryContentSelected()
  tubiLog("HomeScreen.onCategoryContentSelected")
  if m.top.onNowContent <> invalid
    m.OnNow.control = "stop"  ' make sure we always stop the video before detail screen shows
    m.CategoryScreen.dockedVideoFrameVisible = false
  end if
End Function


'update the HomeScreen trackingCount based on changes to the focused child screen's trackingCount
Function onTrackingCountChange(evt)
  if evt.getData() <> invalid and evt.getRoSGNode().isInFocusChain()
    m.top.trackingCount = evt.getData()
  end if
End Function

Function onTrackingUriChange(evt)
  if evt.getData() <> invalid and evt.getRoSGNode().isInFocusChain()
    m.top.trackingUri = evt.getData()
  end if
End Function
