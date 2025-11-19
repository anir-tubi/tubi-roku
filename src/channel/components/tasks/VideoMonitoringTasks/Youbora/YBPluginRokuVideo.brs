' ********** Copyright 2023 Nice People At Work.  All Rights Reserved. **********

Library "Roku_Ads.brs"

sub init()
  YouboraLog("YBPluginRokuVideo.brs - init", "YBPluginRokuVideo")
end sub

sub startMonitoring()

  m.pluginName = "RokuVideo"
  m.pluginVersion = "6.6.14-" + m.pluginName

  ' Let's cache the segment used on the bitrate to access less to it
  m.bitrateSegment = invalid
  ' Cache the streamInfo too, to use with throughtput and resource
  m.streamInfo = invalid
  ' Summ of all downloaded chunks
  m.totalBytes = 0
  ' Last chunk's position, mainly to avoid adding a repeated chunk
  m.lastChunkSeqNum = -1
  ' Last playhead value
  m.lastPlayhead = 0
  m.lastPlayheadReported = 0

  if m.top.videoplayer <> invalid
    m.top.videoplayer.observeFieldScoped("state", m.port)
    m.top.videoplayer.observeFieldScoped("bufferingStatus", m.port)
    m.top.videoplayer.observeFieldScoped("downloadedSegment", m.port)
    m.productAnalytics.adapterAfterSet()
  else
    m.top.observeFieldScoped("videoplayer", m.port)
  end if

  m.top.observeFieldScoped("taskState", m.port)
  'm.top.ObserveField("taskState", "_taskListener")

  ' Notify monitoring startup
  m.top.monitoring = true
  m.needsPlayer = true
end sub

Function getParamsVideoError()
  try
    params = { "msg": m.top.videoplayer.errorMsg, "errorCode": m.top.videoplayer.errorCode.ToStr() }
    if m.top.videoplayer.errorStr <> invalid
      errormd = m.top.videoplayer.errorStr
      if m.top.videoplayer.errorinfo <> invalid
        if m.top.videoplayer.errorInfo.clipid <> invalid then errormd += ",clip_id:" + m.top.videoplayer.errorInfo.clipid.ToStr()
        if m.top.videoplayer.errorInfo.ignored <> invalid then errormd += ",ignored:" + m.top.videoplayer.errorInfo.ignored.ToStr()
        if m.top.videoplayer.errorInfo.source <> invalid then errormd += ",source:" + m.top.videoplayer.errorInfo.source
        if m.top.videoplayer.errorInfo.category <> invalid then errormd += ",category:" + m.top.videoplayer.errorInfo.category
      end if
      params["metadata"] = errormd
    end if
    return params
  catch e
    YouboraLog("[Youbora error]: " + e, "YBPluginRokuVideo")
    return {}
  end try
End Function

'This method can be overwritten to control retry scenarios, to keep them in one view
'so its important to keep it unmodified calling only 'error' to avoid side effects
sub onVideoError()
  eventHandler("error", getParamsVideoError())
end sub

'This method can be overwritten to control retry scenarios, to keep them in one view
'so its important to keep it unmodified calling only 'stop' to avoid side effects
sub onStopVideo()
  eventHandler("stop")
end sub

sub updatePlayer (player as Object, unobserveGlobalScope as Boolean)
  try
    if m.top.videoplayer <> invalid
      if unobserveGlobalScope = true
        m.top.videoplayer.unobserveField("state")
        m.top.videoplayer.unobserveField("bufferingStatus")
        m.top.videoplayer.unobserveField("downloadedSegment")
      else
        m.top.videoplayer.unobserveFieldScoped("state")
        m.top.videoplayer.unobserveFieldScoped("bufferingStatus")
        m.top.videoplayer.unobserveFieldScoped("downloadedSegment")
      end if
      m.top.videoplayer = invalid
      m.productAnalytics.adapterBeforeRemove()
    end if

    if player <> invalid
      m.top.videoplayer = player
      m.needsPlayer = false
      m.top.unobserveFieldScoped("videoplayer")
      setNewPlayer()
    else
      m.top.observeFieldScoped("videoplayer", m.port)
      m.needsPlayer = false
    end if
  catch e
    YouboraLog("Exception updating new player: " + e.message, "YBPluginRokuVideo")
  end try
end sub

Function onBufferingStatusChanged(bufferStatus) as Void

  if bufferStatus <> invalid
    isBuffer = bufferStatus["isUnderrun"]
    if isBuffer = true
      if m.viewManager.isSeeking = true

        YouboraLog("Converting seek to buffer...", "YBPluginRokuVideo")

        m.viewManager.isSeeking = false
        m.viewManager.isBuffering = true

        m.viewManager.chronoBuffer.startTime = m.viewManager.chronoSeek.startTime
        m.viewManager.chronoBuffer.stopTime = invalid

        m.viewManager.chronoSeek.stop()

      else
        eventHandler("resume")
        eventHandler("buffering")
      end if
    end if
  end if

End Function

sub processPlayerState(newState as String)

  YouboraLog("Player state: " + newState, "YBPluginRokuVideo")

  try
    if newState = "buffering"
      if m.viewManager.isStartSent = false
        eventHandler("play")
      else
        if isSeekEventEnabled() then
          if m.viewManager.isPaused = true
            eventHandler("resume")
            eventHandler("seeking")
          else
            isSeekByPlayhead = false

            try
              if isPlayheadJumpEnabled() AND m.lastPlayheadReported <> invalid AND m.lastPlayheadReported > 0 AND m.lastPlayhead <> invalid AND m.lastPlayhead > 0
                time = CreateObject("roDateTime")
                currentTime = time.AsSeconds()
                diffTimes = Abs(currentTime - m.lastPlayheadReported)
                diffPlayhead = Abs(getPlayhead() - m.lastPlayhead)
                if diffPlayhead > maxVal(5, (diffTimes * 2))
                  isSeekByPlayhead = true
                end if
              end if
            catch e
              YouboraLog("Exception detecting seek event by playhead jump: " + e.message, "YBPluginRokuVideo")
            end try

            if isSeekByPlayhead
              YouboraLog("Seek detected by playhead jump", "YBPluginRokuVideo")
              eventHandler("seeking")
            else
              eventHandler("buffering")
            end if
          end if
        else
          eventHandler("buffering")
        end if
      end if
    else if newState = "playing"
      'if m.viewManager.isStartSent = true
      if m.viewManager.isJoinSent = false
        eventHandler("join")
      else if m.viewManager.isPaused = true
        eventHandler("resume")
      end if

      if m.viewManager.isBuffering = true
        eventHandler("buffered")
      else if m.viewManager.isSeeking = true
        eventHandler("seeked")
      end if
      'endif
    else if newState = "stopped"
      'Sometimes when playing an HLS Live stream, the Video player
      'enters the "stopped" state while buffering.
      '
      'Here we check for the control property of the video player
      'and close the view only if it is stop. This avoids sending
      'false stop events.
      ' if m.top.videoplayer.control = "stop" AND m.viewManager.isShowingAds = false
      '     'eventHandler("stop")
      ' else
      '     YouboraLog("Ignoring 'stopped' state; Video.control is not 'stop'")
      ' endif
    else if newState = "error"
      onVideoError()
    else if newState = "paused"
      eventHandler("pause")
    else if newState = "finished"
      m.viewManager.isFinished = true
      if m.top.videoplayer.control = "stop"
        onStopVideo()
      else
        YouboraLog("Ignoring 'stopped' state; Video.control is not 'stop'", "YBPluginRokuVideo")
      end if
    end if
  catch e
    YouboraLog("Exception managing player state: " + e.message, "YBPluginRokuVideo")
  end try
end sub

Function maxVal(a as Dynamic, b as Dynamic) as Dynamic
  if a > b
    return a
  else
    return b
  end if
End Function

'Overriden parent method
sub processMessage(msg, port)

  mt = type(msg)
  if mt = "roSGNodeEvent"
    if msg.getField() = "state" 'Player state
      state = msg.getData()
      processPlayerState(state)
    else if msg.getField() = "bufferingStatus"
      bufferStatus = msg.getData()
      onBufferingStatusChanged(bufferStatus)
    else if msg.getField() = "videoplayer" AND m.needsPlayer = true
      m.needsPlayer = false
      m.top.unobserveFieldScoped("videoplayer")
      setNewPlayer()
    else if msg.getField() = "updateplayer"
      try
        msg = msg.getData()
        unobserveGlobalScope = false
        if msg <> invalid AND msg.DoesExist("unobserveGlobalScope")
          unobserveGlobalScope = msg["unobserveGlobalScope"]
        end if
        if msg <> invalid AND msg.DoesExist("player")
          updatePlayer(msg["player"], unobserveGlobalScope)
        else
          updatePlayer(invalid, unobserveGlobalScope)
        end if
      catch e
        YouboraLog("Exception updating player object: " + e.message, "YBPluginRokuVideo")
      end try
    else if msg.getField() = "downloadedSegment"
      if m.viewManager.isJoinSent = false AND m.viewManager.isshowingads = false AND m.top.videoplayer.state = "playing"
        eventHandler("join")
      end if
      downloadedSegment = msg.getData()
      if downloadedSegment <> invalid
        if downloadedSegment.Status = 0 AND (downloadedSegment.SegType = 0 OR downloadedSegment.SegType = 1 OR downloadedSegment.SegType = 2) AND m.lastChunkSeqNum <> downloadedSegment.Sequence
          m.totalBytes = m.totalBytes + downloadedSegment.SegSize
        end if
      end if
    else if msg.getField() = "taskState"
      _taskListener(msg.getData())
    end if
  end if

end sub

sub setNewPlayer()
  try
    if m.top.videoplayer <> invalid
      m.top.videoplayer.observeFieldScoped("state", m.port)
      m.top.videoplayer.observeFieldScoped("bufferingStatus", m.port)
      m.top.videoplayer.observeFieldScoped("downloadedSegment", m.port)
      m.productAnalytics.adapterAfterSet()
    end if
  catch e
    YouboraLog("Exception adding player observers: " + e.message, "YBPluginRokuVideo")
  end try
end sub

'Info methods
Function getResource()

  resource = "unknown"

  try
    if m.contentUrl = invalid
      'Get it from the informed url by the client
      content = m.top.videoplayer.content
      if content <> invalid
        resource = content.URL
        m.contentUrl = resource
      end if
    else
      resource = m.contentUrl
    end if
  catch e
    YouboraLog("Exception on getResource method: " + e.message, "YBPluginRokuVideo")
  end try

  return resource

End Function

Function getParsedResource()

  resource = invalid

  try
    'This is only for segmented video transports (dash, hls)
    ssegment = m.top.videoplayer.streamingSegment
    if ssegment <> invalid
      resource = ssegment.segUrl
    end if
  catch e
    YouboraLog("Exception on getParsedResource method: " + e.message, "YBPluginRokuVideo")
  end try

  return resource

End Function

Function getMediaDuration()
  duration = 0

  try
    duration = m.top.videoplayer.duration

    if duration = invalid
      duration = 0
    end if
  catch e
    YouboraLog("Exception on getMediaDuration method: " + e.message, "YBPluginRokuVideo")
  end try

  return duration
End Function

sub updateLastPlayhead()
  try
    time = CreateObject("roDateTime")
    m.lastPlayhead = getPlayhead()
    m.lastPlayheadReported = time.AsSeconds()
  catch e
    YouboraLog("Exception setting last playhead value: " + e.message, "YBPluginRokuVideo")
  end try
end sub

Function getPlayhead()
  try
    if m.viewManager.isJoinSent = true
      return m.top.videoplayer.position
    else
      return 0
    end if
  catch e
    YouboraLog("Exception on getTitle method: " + e.message, "YBPluginRokuVideo")
  end try

  return 0
End Function

Function getTitle()
  title = invalid

  try
    content = m.top.videoplayer.content

    if content <> invalid
      title = content.TITLE
    else
      title = invalid
    end if
  catch e
    YouboraLog("Exception on getTitle method: " + e.message, "YBPluginRokuVideo")
  end try

  return title

End Function

Function getIsLive()
  'This always returns false, so get rid of one call to a node
  return false
  ' content = m.top.videoplayer.content

  ' if content <> invalid
  '     live = content.Live
  ' else
  '     live = false
  ' endif

  ' return live
End Function

Function getThroughput()
  throughput = invalid

  try
    'This is only for roku >= 7.2
    m.streamInfo = m.top.videoplayer.streamInfo
    if m.streamInfo <> invalid
      throughput = m.streamInfo.measuredBitrate
    else
      throughput = invalid
    end if
  catch e
    YouboraLog("Exception on getThroughput method: " + e.message, "YBPluginRokuVideo")
  end try

  return throughput
End Function

Function getBitrate()
  'This is only for HLS and DASH
  br = -1

  try
    currentSegment = m.top.videoplayer.streamingSegment
    if currentSegment <> invalid AND currentSegment.segType <> 1 AND currentSegment.segType <> 3 'not audio or captions
      m.bitrateSegment = currentSegment
      br = m.bitrateSegment.segBitrateBps
    else if m.bitrateSegment <> invalid AND m.bitrateSegment.segType <> 1 AND m.bitrateSegment.segType <> 3 'not audio or captions
      'Get it from last cached bitrateSegment
      br = m.bitrateSegment.segBitrateBps
    else
      br = -1
    end if
  catch e
    YouboraLog("Exception on getBitrate method: " + e.message, "YBPluginRokuVideo")
    YouboraLog("Check if videoplayer exists: ", "YBPluginRokuVideo")
    YouboraLog(m.top.videoplayer, "YBPluginRokuVideo")
  end try

  return br
End Function

Function getRendition()
  'This is only for HLS and DASH
  rendition = invalid

  try
    currentSegment = m.top.videoplayer.streamingSegment
    if currentSegment <> invalid AND currentSegment.segType <> 1 AND currentSegment.segType <> 3 'not audio or captions
      m.bitrateSegment = currentSegment
      rendition = m.bitrateSegment.segBitrateBps
      if rendition < 1000
        rendition = rendition.ToStr() + "bps"
      else if rendition < 1000000
        rendition = (rendition / 1000).ToStr() + "Kbps"
      else
        rendAux = rendition / 1000000.0 'Divide by mega
        rendAux = Cint(rendAux * 100) / 100.0
        rendition = rendAux.ToStr() + "Mbps"
      end if
      width = m.bitrateSegment.width
      height = m.bitrateSegment.height
      if width <> invalid AND height <> invalid AND width <> 0 AND height <> 0
        rendition = width.ToStr() + "x" + height.ToStr() + "@" + rendition
      end if
    else
      rendition = invalid
    end if
  catch e
    YouboraLog("Exception on getRendition method: " + e.message, "YBPluginRokuVideo")
  end try

  return rendition
End Function

Function getTotalBytes()
  ' downloadedSegment = m.top.videoplayer.downloadedSegment
  ' if downloadedSegment <> invalid
  '     ?"download segment";downloadedSegment
  '     if downloadedSegment.Status = 0 AND (downloadedSegment.SegType = 1 OR downloadedSegment.SegType = 2) AND lastChunkSeqNum <> downloadedSegment.Sequence
  '         totalBytes = totalBytes + downloadedSegment.SegSize
  '     endif
  ' endif
  return m.totalBytes
End Function

Function getPlayrate()
  ret = 1

  try
    ret = m.top.videoplayer.playbackSpeed
    if m.viewManager.isPaused
      ret = 0
    end if
  catch e
    YouboraLog("Exception on getPlayrate method: " + e.message, "YBPluginRokuVideo")
  end try

  return ret
End Function

Function getPlayerVersion()
  return "Roku-Video"
End Function

sub _taskListener(taskState)
  if taskState = "stop"
    m.contentUrl = invalid
    m.top.monitoring = false
    m.viewManager.isFinished = false
    m.top.taskState = "" 'This is necessary since if the last reported state has been stop and is reported again it won't get notified, since the value hasn't changed
  end if
end sub
