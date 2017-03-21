Function init()
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("signedIn", "onSignedInChange")
  m.top.observeField("showEPG", "onShowEPG")
  m.top.observeField("liveTVContent", "onLiveTVContentChange")
  m.ToolsMenu = m.top.findNode("ToolsMenu")
  m.LiveTV = m.top.findNode("LiveTV")
  m.LiveTV.observeField("allChannelsSelected", "onAllChannelSelected")
  m.EPG = m.top.findNode("EPG")
  m.EPG.observeField("channelSelected", "onEPGChannelSelected")
  m.CategoryScreen = m.top.findNode("CategoryScreen")
  m.CategoryScreen.observeField("backgroundUriList", "onCategoryBackgroundChange")
  m.focusTarget = m.LiveTV

  m.Autohide = m.top.findNode("Autohide")
  m.Autohide.observeField("fire","onAutohide")
  m.hideAfter = 10
  m.lastKeyEvent = Uptime(0)
  m.Autohide.control = "start"

End Function

' Make sure these stay in sync
Function onLiveTVContentChange()
  m.EPG.content = m.LiveTV.content
  if m.LiveTV.isInFocusChain() then m.top.playLiveTV = true
End Function

Function onAllChannelSelected()
  showEPG()
End Function

''''''''''''''''''''''''
' onEPGChannelSelected
'
'
Function onEPGChannelSelected()
  tubiLog("LiveTVScreen.onEPGChannelSelected")
  ' set the current episode only if the channel has changed
  channelIndex = m.EPG.channelSelected
  if m.LiveTV.content.liveTVCursor[0] <> channelIndex then
    ' Relate the new channel position to the old channel position so they're in time-sync
    oldPlaylist = m.LiveTV.content.getChild(m.LiveTV.content.liveTVCursor[0])
    newPlaylist = m.LiveTV.content.getChild(channelIndex)
    oldCursor = [m.LiveTV.content.liveTVCursor[1], m.LiveTV.content.liveTVCursor[2]]
    oldPosition = playlistPositionFromEpisodicPosition(oldPlaylist, oldCursor)
    newCursor = episodicPositionFromPlaylistPosition(newPlaylist, oldPosition)
    newCursor.unshift(channelIndex)
    m.LiveTV.content.liveTVCursor = newCursor
    m.top.playLiveTV = true
  end if
  hideEPG()
  m.top.hideUI = true
End Function

Function onShowEPG()
  if m.top.showEPG then
    showEPG()
  else
    hideEPG()
  end if
End Function

Function showEPG()
  m.LiveTV.visible = false
  m.CategoryScreen.visible = false
  m.EPG.content = m.LiveTV.content
  m.EPG.visible = true
  m.focusTarget = m.EPG
  if m.top.isInFocusChain() then m.EPG.setFocus(true)
End Function

Function hideEPG()
  m.EPG.visible = false
  m.LiveTV.visible = true
  m.CategoryScreen.visible = true
  m.focusTarget = m.LiveTV
  if m.top.isInFocusChain() then m.LiveTV.setFocus(true)
End Function


''''''''''''''''''''
' onScreenFocusChange
'
Function onScreenFocusChange() As Void
  tubiLog("LiveTVScreen.onScreenFocusChange " + focusState(m.top))
  if m.top.isInFocusChain()
    if m.top.hasFocus() then
      m.focusTarget.setFocus(true)
    end if
    if m.LiveTV.visible then
      m.lastKeyEvent = Uptime(0)
      m.Autohide.control = "start"
    end if
  else
    m.Autohide.control = "stop"
  end if
End Function

Function onSignedInChange()
  tubiLog("LiveTVScreen.onSignedInChange")
  m.ToolsMenu.signedIn = m.top.signedIn
  m.CategoryScreen.signedIn = m.top.signedIn
End Function

Function onKeyEvent(key As String, press As Boolean) As Boolean
  tubiLog("LiveTVScreen.onKeyEvent key = " + key)
  m.lastKeyEvent = Uptime(0)

  if press then
    if key = "back" then
      if m.EPG.isInFocusChain() then
        hideEPG()
        m.top.hideUI = true
        return true
      else if m.LiveTV.isInFocusChain() then
        'send the back button press to the screen stack (for category screen and sign in/search list)
        showCategoryScreen()
        return true
      end if
    else if key = "up"
      if m.LiveTV.isInFocusChain() then
        slideFade(m.ToolsMenu, "above", "in", 0.4)
        slideFade(m.LiveTV, "below", "out", 0.4)
        m.ToolsMenu.findNode("ToolsMenu").setFocus(true)
        m.top.backgroundUriList = m.ToolsMenu.backgroundUriList
        m.focusTarget = m.ToolsMenu
        m.Autohide.control = "stop"
        return true
      else if m.CategoryScreen.isInFocusChain() then  ' must be category screen focus
        slideFade(m.LiveTV, "above", "in", 0.4)
        animate(m.CategoryScreen, m.CategoryScreen.translation, [0, 392], 0.2, 1.0, 0.4)
        m.CategoryScreen.infoVisible = false
        m.LiveTV.setFocus(true)
        'kick the event to start playback
        m.top.playLiveTV = true
        m.focusTarget = m.LiveTV
        m.Autohide.control = "start"
        return true
      end if
    else if key = "down"
      if m.ToolsMenu.isInFocusChain() then
        slideFade(m.ToolsMenu, "above", "out", 0.4)
        slideFade(m.LiveTV, "below", "in", 0.4)
        m.LiveTV.setFocus(true)
        m.top.playLiveTV = true
        m.focusTarget = m.LiveTV
        m.Autohide.control = "start"
        return true
      else if m.LiveTV.isInFocusChain() then
        showCategoryScreen()
        return true
      end if
    end if
  end if

End Function

Function showCategoryScreen()
  if m.LiveTV.isInFocusChain() then
    slideFade(m.LiveTV, "above", "out", 0.4)
    animate(m.CategoryScreen, m.CategoryScreen.translation, [0, 0], 1.0, 1.0, 0.4)
    m.CategoryScreen.infoVisible = true
    m.CategoryScreen.setFocus(true)
    m.top.backgroundUriList = m.CategoryScreen.backgroundUriList
    m.focusTarget = m.CategoryScreen
    m.Autohide.control = "stop"
  end if
End Function

Function onCategoryBackgroundChange()
  tubiLog("LiveTVScreen.onCategoryBackgroundChange")
  if m.CategoryScreen.isInFocusChain() then m.top.backgroundUriList = m.CategoryScreen.backgroundUriList
End Function

Function onAutohide()
  tubiLog("LiveTVScreen.onAutohide")
  if m.LiveTV.isInFocusChain() = true and (Uptime(0) - m.lastKeyEvent) > m.hideAfter then
    m.Autohide.control = "stop"
    hideEPG()
    m.top.hideUI = true
  end if
End Function