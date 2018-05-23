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

'Occurs when m.Video.state changes (not when m.top.state changes)
Function onVideoStateChange(msg)
  tubiLog("VideoPlayer.onVideoStateChange")
  state = msg.GetData()
  if (state = "finished" or state = "error") and m.VideoState = "play"
    if state = "error"
      content = currentPlaylistContent()
      errorInfo = getPlaybackErrorInfo(m.Video, content)
      tubiLog(FormatJSON(errorInfo), "error", "videoPlayback", "video-playback")
    end if

    ' hide "finished" and "error" states if we are advancing the playlist
    if not advancePlaylist()
      if state = "error"
        m.top.errorMsg = "There was an issue with video playback."
      end if
      m.top.state = state
    end if
  else
    m.top.state = state
  end if

  ' Track buffering time.  We need to track 2 pieces of data:
  '   1) previous state "buffering"?: boolean (since we log at end of buffering)
  '   2) duration of "buffering" state: time
  ' We use m.bufferingTimespan for both these data by allowing it to be 'invalid' when
  ' not tracking buffering state.
  if state = "buffering"
    if m.Video.streamInfo <> invalid and m.Video.streamInfo.isUnderrun = true
      content = currentPlaylistContent()
      messageInfo = getBufferMessageInfo(0, m.Video, content)
      tubiLog(FormatJSON(messageInfo), "warn", "videoBuffer", "rebuffer-start")
      m.bufferingTimespan = CreateObject("roTimespan")
    end if
  else
    ' only send buffering time if we reached playing state, otherwise
    ' the user may have just backed out of it or an error occurred
    if m.bufferingTimespan <> invalid and state = "playing" then
      ' TODO(Chris): Remove this check once the logging server can handle loads
      ' for every buffering event.  For now we just log underruns
      if m.Video <> invalid and m.Video.streamInfo.isUnderrun then
        content = currentPlaylistContent()
        messageInfo = getBufferMessageInfo(m.bufferingTimespan.TotalMilliseconds(), m.Video, content)
        tubiLog(FormatJSON(messageInfo), "warn", "videoBuffer", "REBUFFERING")  'REBUFFERING is a legacy message style. It should be treated as rebuffer-end
      end if
    end if
    m.bufferingTimespan = invalid
  end if

  ' Loading page visibility
  if state = "playing" or state = "paused" or m.top.isDocked then
    m.Loading.visible = false
    m.Spinner.visible = false
  else
    m.Loading.visible = true
    m.Spinner.visible = true
  end if
End Function

Function onDownloadedSegment(msg)
  tubiLog("VideoPlaylist.onDownloadedSegment")
  dlsegment = msg.getData()
  if dlsegment <> invalid and dlsegment.status <> 0
    content = currentPlaylistContent()
    errorInfo = getDownloadErrorInfo(dlsegment, m.Video, content)
    tubiLog(FormatJSON(errorInfo), "error", "videoPlayback", "video-download")
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
    if m.refreshTask <> invalid
      m.refreshTask.unobserveField("response")
      m.refreshTask.unobserveField("error")
    end if
    m.refreshTask = CreateObject("roSGNode", "DetailMetadataTask")
    request = {
      contentId: content.id
      getThumbnails: true
    }
    m.refreshTask.request = request
    m.refreshTask.observeField("response", "onRefreshResponse")
    m.refreshTask.observeField("error", "onRefreshError")
    m.refreshTask.control = "RUN"
    m.VideoState = "refresh"
  end if
End Function

Function onRefreshResponse(msg)
  tubiLog("VideoPlayer.onRefreshResponse")
  refreshedContent = msg.GetData()
  refreshTask = msg.getRoSGNode()
  playlistContent = currentPlaylistContent()
  if refreshedContent.id = playlistContent.id
    ' While the refresh content may not hold all the information we need (e.g. isLiveTV), it's
    ' only used for the stream urls and subtitle urls really and should be ok here without merging
    ' fields from the original content.
    mergedFields = ["isLiveTV", "isTrailer", "nowPos", "parentType", "parentTitle"]
    for each f in mergedFields
      refreshedContent.setField(f, playlistContent.getField(f))
    end for

    ' In the case that we are attempting to watch a trailer, overwrite the video urls of the refreshed content
    ' with the trailer urls
    if playlistContent.isTrailer and not m._.empty(refreshedContent.trailerUrls)
      refreshedContent.url = refreshedContent.trailerUrls[0]
      refreshedContent.subtitleTracks = []
      refreshedContent.subtitleConfig = invalid
    end if

    m.top.content = refreshedContent
    if m.VideoState = "refresh" then
      playContent()
    end if
  end if
End Function

Function onRefreshError(msg)
  tubiLog("VideoPlayer.onRefreshError")
  ' TODO: When do we shown an error vs. skip content and continue on?
  if m.VideoState = "refresh" or m.VideoState = "pause"
    advancePlaylist()
  end if
End Function


' Helper functions to create the error info to be sent as the message of error logs
Function getDownloadErrorInfo(downloadedSegment, videoNode, content)
  errorInfo = {
    video_id: ""
    video_url: ""
  }

  if downloadedSegment <> invalid
    errorInfo.error_code = downloadedSegment.status
    errorInfo.segment_sequence = downloadedSegment.SegSequence
    errorInfo.segment_url = downloadedSegment.SegUrl
    errorInfo.segment_download_duration = downloadedSegment.DownloadDuration
    errorInfo.segment_bitrate = downloadedSegment.BitrateBps
    errorInfo.segment_size = downloadedSegment.SegSize
  end if

  if content <> invalid then errorInfo.video_id = content.id
  if videoNode <> invalid and videoNode.streamInfo <> invalid
    errorInfo.video_url = videoNode.streamInfo.streamUrl
  end if

  return errorInfo
End Function


Function getBufferMessageInfo(ms, videoNode, content)
  messageInfo = {
    video_id: ""
    video_url: ""
  }

  ' timespan is invalid if we are sending a buffer start event
  if ms > 0
    messageInfo.buffer_time_ms = ms
  end if

  if videoNode <> invalid and videoNode.streamInfo <> invalid then
    messageInfo.stream_bitrate = videoNode.streamInfo.streamBitrate
    messageInfo.measured_bitrate = videoNode.streamInfo.measuredBitrate
    messageInfo.video_url = videoNode.streamInfo.streamUrl
  end if
  if content <> invalid then
    messageInfo.video_id = content.id
  end if
  return messageInfo
End Function


Function getPlaybackErrorInfo(videoNode, content)
  errorInfo = {
    video_id: ""
    video_url: ""
  }
  if videoNode <> invalid
    if videoNode.errorCode <> 0
      if videoNode.errorCode = -3
        errorInfo.error_message = "Server did not respond with hls segment. Potential 504 or 404. Following segment likely has issue."
        if videoNode.downloadedSegment <> invalid
          ' in the case of errorCode = -3, it likely means there was a 504 or 404 response from the server which ultimately was the source of the error.
          ' we get the last downloaded segment which is the last good segment instead of the current streaming segment, which may be several segments ahead of the bad segment.
          ' in this case, the segment causing the error is the segment AFTER the logged segment.
          errorInfo.segment_sequence = videoNode.downloadedSegment.Sequence
          errorInfo.segment_url = videoNode.downloadedSegment.SegUrl
          errorInfo.segment_bitrate = videoNode.downloadedSegment.BitrateBps
        end if
      else if videoNode.errorMsg <> invalid
        errorInfo.error_message = videoNode.errorMsg
        if videoNode.streamingSegment <> invalid
          ' videoNode.streamingSegment can be invalid when the server returns a 504, 404, etc.
          errorInfo.segment_url = videoNode.streamingSegment.segUrl
          errorInfo.segment_start_time = videoNode.streamingSegment.segStartTime
          errorInfo.segment_sequence = videoNode.streamingSegment.segSequence
          errorInfo.segment_bitrate = videoNode.streamingSegment.segBitrateBps
        end if
      end if
      errorInfo.error_code = videoNode.errorCode
    end if

    if content <> invalid then errorInfo.video_id = content.id

    if videoNode.streamInfo <> invalid then errorInfo.video_url = videoNode.streamInfo.streamUrl
  end if
  return errorInfo
End Function