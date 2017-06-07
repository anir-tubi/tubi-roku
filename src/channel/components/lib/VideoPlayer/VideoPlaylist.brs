''''''''''''''''''''''''
' PLAYLIST MANAGEMENT
''''''''''''''''''''''''

Function onPlaylistChange(msg) As Void
  tubiLog("VideoPlayer.onPlaylistChange")
  if msg.GetData() = invalid or msg.GetData().getChildCount() = 0 return
  
  m.top.playlistIndex = 0
  m.Video.control = "stop"
  m.VideoState = "stop"
  m.VideoPicker.content = m.top.playlist
End Function


' Use cases:
'  - same index vs. different index (refresh must happen for latter)
'  - playing vs. not playing (seek must be applied after video refreshes and plays)
'
Function onSeekPlaylist(msg) As Void
  tubiLog("VideoPlayer.onSeekPlaylist")
  if msg.GetData() = invalid or type(msg.GetData()) <> "roArray" or msg.GetData().count() <> 2 return

  newIndex = msg.GetData()
  if newIndex[0] >= m.top.playlist.getChildCount() then 
    newIndex = [0, 0]
  else if newIndex[0] < 0
    newIndex = [0, 0]
  end if
  tubiLog("VideoPlayer seeking to [" + stri(newIndex[0]) + "," + stri(newIndex[1]) + "]")

  m.top.playlistIndex = newIndex[0]
  m.Video.control = "stop"  ' refresh will start this when complete
  m.VideoState = "stop"
  refreshContent(newIndex[1])
End Function

Function currentPlaylistContent()
  if m.top.playlist <> invalid
    return m.top.playlist.getChild(m.top.playlistIndex)
  else
    return invalid
  end if
End Function

Function onVideoStateChange(msg)
  tubiLog("VideoPlayer.onVideoStateChange")
  state = msg.GetData()
  if (state = "finished" or state = "error") and m.VideoState = "play"
    ' hide "finished" and "error" states if we are advancing the playlist
    if not advancePlaylist() then m.top.state = state
  else
    m.top.state = state
  end if
End Function

Function advancePlaylist() As Boolean
  ' advance the playlist
  if m.top.playlist <> invalid
    newIndex = m.top.playlistIndex + 1
    if newIndex >= m.top.playlist.getChildCount()
      if m.top.loopPlaylist
        newIndex = 0
      else
        return false
      end if
    end if
    m.top.playlistIndex = newIndex
    refreshContent(0)
    return true
  else
    return false
  end if
End Function

''''''''''''''''''''''
' METADATA REFRESH
''''''''''''''''''''''

Function refreshContent(nowPos)
  tubiLog("VideoPlayer.refreshContent")
  content = currentPlaylistContent()

  if content <> invalid then 
    tubiLog("VideoPlayer current content id = " + content.id)
    if content.isTrailer
      m.top.content = content  ' don't need to refresh if this is a trailer
      playContent()
    else
      if m.refreshTask <> invalid
        m.refreshTask.unobserveField("response")
        m.refreshTask.unobserveField("error")
      end if
      m.refreshTask = CreateObject("roSGNode", "DetailMetadataTask")
      fragment = clone(content)
      fragment.nowPos = nowPos  ' we have to pass this along since it is relevant after the refresh, but may
                                ' have come from numerous places, e.g. m.top.seekPlaylist or advancePlaylist
      m.refreshTask.contentFragment = fragment
      m.refreshTask.observeField("response", "onRefreshResponse")
      m.refreshTask.observeField("error", "onRefreshError")
      m.refreshTask.control = "RUN"
      m.VideoState = "refresh"
    end if
  end if
End Function

Function onRefreshResponse(msg)
  tubiLog("VideoPlayer.onRefreshResponse")
  refreshedContent = msg.GetData()
  refreshTask = msg.getRoSGNode()
  playlistContent = refreshTask.contentFragment
  ' While the refresh content may not hold all the information we need (e.g. isLiveTV), it's
  ' only used for the stream urls and subtitle urls really and should be ok here without merging
  ' fields from the original content.
  mergedFields = ["isLiveTV", "isTrailer", "nowPos"]
  for each f in mergedFields
    refreshedContent.setField(f, playlistContent.getField(f))
  end for
  m.top.content = refreshedContent
  if m.VideoState = "refresh" then
    playContent()
  end if
End Function

Function onRefreshError(msg)
  tubiLog("VideoPlayer.onRefreshError")
  ' TODO: When do we shown an error vs. skip content and continue on?
  if m.VideoState = "refresh" or m.VideoState = "pause"
    advancePlaylist()
  end if
End Function

