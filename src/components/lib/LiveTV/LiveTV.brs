Function init()

  m.Poster = m.top.findNode("DVDPoster")
  m.Info = m.top.findNode("Info")

  m.WelcomeUI = m.top.findNode("WelcomeUI")
  m.WatchOrTuneMenu = m.top.findNode("WatchOrTuneMenu")
  m.WatchOrTuneMenu.observeField("itemSelected", "onMenuItemSelected")

  m.top.observeField("content", "onContentChange")
  m.top.observeField("focusedChild", "onComponentFocusChange")
End Function

Function onComponentFocusChange()
  if m.top.isInFocusChain() and m.top.hasFocus() then
    m.WatchOrTuneMenu.setFocus(true)
  end if
End Function


'''''''''''''''''''''''''''
' drawCurrentEpisode
'
'
'
Function drawCurrentEpisode() As Void
  tubiLog("LiveTV.drawCurrentEpisode")
  if m.top.content <> invalid then
    channel = m.top.content.getChild(m.top.content.liveTVCursor[0])
    if channel <> invalid then
      episode = channel.getChild(m.top.content.liveTVCursor[1])
      if episode <> invalid then
        m.Poster.uri = episode.hdgridposterurl
        m.Info.content = episode
        return
      end if
    end if
  end if
  m.Poster.uri = ""
  m.Info.content = invalid
End Function


'''''''''''''''''''''''
' onMenuItemSelected
'
'
Function onMenuItemSelected()
  tubiLog("LiveTV.onMenuItemSelected")
  button = m.WatchOrTuneMenu.content.getChild(m.WatchOrTuneMenu.itemSelected)
  if button.id = "watchnow" then
    m.top.watchNowSelected = true
  end if
  if button.id = "allchannels" then
    m.top.allChannelsSelected = true
  end if
End Function

Function onContentChange()
  tubiLog("LiveTV.onContentChange")
  drawCurrentEpisode()
End Function