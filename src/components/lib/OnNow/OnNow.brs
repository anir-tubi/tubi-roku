Function init()
  m.onNowOverlay = m.top.findNode("onNowOverlay")
  m.onNowOverlay.observeField("contentSelected", "onOverlayContentSelected")
  m.onNowOverlay.observeField("contentFocused", "onOverlayContentFocused")
  m.top.observeField("content", "onContentChange")
  m.top.observeField("focusedChild", "onComponentFocusChange")
  m.top.observeField("control", "onControlChange")
  m.DebounceTimer = m.top.findNode("Debounce")
  m.DebounceTimer.observeField("fire", "onDebounceDone")
  m.Unavailable = m.top.findNode("Unavailable")
  m.playlistInfo = [] 'a store for each playlist with each element having the following form: {contentIndex: 0, nowPos: 0}
  m.playlistIndex = 0
  m.autohideSeconds = 3
  m.internalState = "stop"
  m.adSuppressionDuration = 5 * 60  ' seconds until ads start showing
  m.adSuppressionExpire = 0 'Uptime(0) + m.adSuppressionDuration
End Function

Function autohideWhenPlaying()
  if m.videoPlayer <> invalid and m.videoPlayer.state = "playing"
    autohideStart(m.autohideSeconds, false, 3.0)
  end if
End Function

Function onComponentFocusChange()
  tubiLog("OnNow.onComponentFocusChange " + focusState(m.top))
  if m.top.isInFocusChain() and m.top.hasFocus() then
    m.adSuppressionExpire = 0
    m.onNowOverlay.setFocus(true)
    autohideWhenPlaying()
  end if
End Function

Function onControlChange()
  tubiLog("OnNow.onControlChange control = " + m.top.control + " state = " + m.internalState)
  m.adSuppressionExpire = 0
  if m.videoPlayer <> invalid then m.videoPlayer.enableAds = false
  if m.top.control = "play"
    if m.internalState = "stop" then showOnNow()
    dockVideo(false)
    autohideWhenPlaying()
  else if m.top.control = "stop"
    hideOnNow()
    dockVideo(false)
    autohideCancel()
  else if m.top.control = "dock"
    if m.internalState = "stop" then showOnNow()
    dockVideo(true)
    autohideCancel()
  end if
  m.internalState = m.top.control
End Function

Function onContentChange()
  tubiLog("OnNow.onContentChange")
  m.adSuppressionExpire = 0
  if m.top.content = invalid then
    m.Unavailable.visible = true
    m.onNowOverlay.visible = false
  else
    m.Unavailable.visible = false
    m.onNowOverlay.visible = true

    'we need to store the last known position of a playlist/channel so that when a user changes playlists,
    'we can start the appropriate video at the appropriate time
    for i=0 to m.top.content.getChildCount()-1
      playlistCursor = {
        contentIndex: 0
        nowPos: 0
      }
      if i = m.top.content.liveTVCursor[0]
        playlistCursor.contentIndex = m.top.content.liveTVCursor[1]
        playlistCursor.nowPos = m.top.content.liveTVCursor[2]
      end if
      m.playlistInfo.push(playlistCursor)
    end for

    'pull out the cursor from the content node holding the playlists
    'we will listen to changes in playlistIndex and contentIndex to indicate when the UI has updated
    m.playlistIndex = m.top.content.liveTVCursor[0]
    m.onNowOverlay.content = m.top.content.getChild(m.playlistIndex)
    m.onNowOverlay.jumpToIndex = m.playlistInfo[m.playlistIndex].contentindex
    if m.videoPlayer = invalid
      m.videoPlayer = rootNode().findNode("VideoPlayer")
    end if

    ' This will cause the last control to be applied appropriately
    if m.top.control = "play" then showOnNow()
  end if
End Function


Function showOnNow() As Void
  tubiLog("OnNow.showOnNow")
  if m.top.content = invalid then return
  m.videoPlayer.observeField("playlistIndex", "onVideoPlayerPlaylistIndexChange")
  m.videoPlayer.observeField("state", "onVideoPlayerState")
  playlist = m.top.content.getChild(m.playlistIndex)

  if playlist <> invalid
    m.videoPlayer.playlist = playlist
    m.videoPlayer.visible = true
    m.videoPlayer.enableAds = false  ' disable ads to start.  they'll go enabled once the user elects into live tv
    m.videoPlayer.enableTracking = true
    m.videoPlayer.seekPlaylist = [
      m.playlistInfo[m.playlistIndex].contentIndex
      m.playlistInfo[m.playlistIndex].nowPos
    ]
  end if
End Function

Function hideOnNow()
  tubiLog("OnNow.hideOnNow")
  if m.videoPlayer <> invalid
    'we don't want to observe these if the video player gets updated from the main category/detail screen view
    m.videoPlayer.control = "stop"
    m.videoPlayer.unobserveField("playlistIndex")
    m.videoPlayer.unobserveField("state")
    ' store the last position
    m.playlistInfo[m.playlistIndex].contentIndex = m.videoPlayer.playlistIndex
    m.playlistInfo[m.playlistIndex].nowPos = m.videoPlayer.position
    m.videoPlayer.visible = false
  end if
End Function

Function dockVideo(dock)
  tubiLog("OnNow.dockVideo")
  if m.videoPlayer <> invalid
    if dock
      m.videoPlayer.translation = [1405,151]
      m.videoPlayer.width = 430
      m.videoPlayer.height = 256
      m.videoPlayer.dock = true
    else
      m.videoPlayer.translation = [0,0]
      m.videoPlayer.width = 1920
      m.videoPlayer.height = 1080 
    end if
  end if
End Function

Function onKeyEvent(key, press)
  tubiLog("OnNow.onKeyEvent key = " + key)
  if press and key = "back"
    autohideStart(0, false, 0.5)  ' hide right away
    return true
  else
    autohideWhenPlaying()
  end if
  return false
End Function

'the onNowOverlay has changed which playlist/channel is selected
Function onOverlayContentSelected()
  tubiLog("OnNow.onOverlayContentSelected")
  autohideStart(0, true, 0.5)  ' hide right away
  m.adSuppressionExpire = Uptime(0) + m.adSuppressionDuration
End Function


'the onNowOverlay has changed which content in the playlist is focused
'or the player has begun autoplay of the next 
Function onOverlayContentFocused()
  tubiLog("OnNow.onOverlayContentFocused")
  index = m.onNowOverlay.contentFocused
  tubiLog("OnNow overlay contentFocused = " + stri(index))

  ' content changed, use start of new content
  m.playlistInfo[m.playlistIndex].contentIndex = index
  m.playlistInfo[m.playlistIndex].nowPos = 0

  'debounce the content selection button presses (from overlay) so we only start the video once the user stops clicking
  m.DebounceTimer.control = "start"  ' restarts if already running
End Function

'tell the on now overlay that the video player has changed the content in the playlist
Function onVideoPlayerPlaylistIndexChange()
  tubiLog("OnNow.onVideoPlayerPlaylistIndexChange")
  m.onNowOverlay.jumpToIndex = m.videoPlayer.playlistIndex
  if m.adSuppressionExpire <> 0 and m.adSuppressionExpire <= Uptime(0)
    tubiLog("Enabling ads for OnNow")
    m.videoPlayer.enableAds = true
  end if
End Function

Function onVideoPlayerState()
  if m.videoPlayer.state = "playing" and m.top.control = "play" then
    autohideWhenPlaying()
  else
    autohideCancel()
  end if
End Function

Function onDebounceDone()
  tubiLog("OnNow.onDebounceDone")
  index = m.playlistInfo[m.playlistIndex]
  m.videoPlayer.playlist = m.top.content.getChild(m.playlistIndex)
  m.videoPlayer.seekPlaylist = [index.contentIndex, index.nowPos]
End Function