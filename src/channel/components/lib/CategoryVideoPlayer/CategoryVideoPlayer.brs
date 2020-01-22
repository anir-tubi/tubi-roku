Function init()
  m.VideoPlayer = m.top.findNode("vitgVideoPlayer")

  ' save the last position of video playback in case a user returns to the video
  m.top.nowPos = 0

  ' keep track of how much video playback time has elapsed since last trailer_play_progress event was fired
  m.playProgressCounter = 0

  m.videoStartAttempted = false

  m.top.observeField("hasFocus", "onFocusChange")
  m.top.observeField("videoUrl", "onVideoUrlChange")
  m.VideoPlayer.observeField("position", "onVideoPositionChange")
  m.VideoPlayer.observeField("state", "onVideoStateChange")
  m.VideoPlayer.observeField("bufferingStatus", "onVideoBufferChange")
End Function


Function onFocusChange()
  if m.top.hasFocus = true
    ' vitg video player is gaining focus
    if m.VideoPlayer.content <> invalid
      m.VideoPlayer.seek = m.top.resumePos
      m.VideoPlayer.control = "prebuffer"
    end if
  else
    ' vitg video player is losing focus
    if m.VideoPlayer.state <> "stopped"
      stopVideo()
    end if
  end if
End Function


Function onVideoUrlChange()
  content = CreateObject("roSGNode", "ContentNode")
  content.url = m.top.videoUrl
  m.VideoPlayer.content = content
End Function


Function onVideoPositionChange(msg)
  ' set currentPos as milliseconds and integer because doing float math leads to incosistent rounding
  ' which throws analytics off slightly
  currentPos = Int(msg.getData() * 1000) 'ms

  if currentPos < m.top.nowPos
    ' can happen if the last m.top.nowPos was not at the start of an HLS segment,
    ' and the user navigated away, and then back to the vitg content.
    m.top.nowPos = currentPos
  end if
  
  m.playProgressCounter = calculatePlayProgressCounter(m.playProgressCounter, currentPos, m.top.nowPos)

  if m.playProgressCounter >= 10000
    sendTrailerPlayProgressEvent(m.global.trackingLoggingTask, m.top.trailerId, currentPos, m.playProgressCounter)
    m.playProgressCounter = 0   'reset the playProgressCounter
  end if

  m.top.nowPos = currentPos
End Function


Function onVideoStateChange(msg)
  state = msg.getData()
  if state = "finished"
    stopVideo()
  end if
End Function


Function onVideoBufferChange()
  bufferPct = m.VideoPlayer.bufferingStatus
  ' when prebuffering, from observation, the buffer percentage never seems to go above 33%
  if bufferPct <> invalid and bufferPct.percentage >= 33 and m.videoStartAttempted = false
    startVideo()
  end if
End Function


Function startVideo()
  m.VideoPlayer.control = "play"
  m.VideoPlayer.visible = true
  m.videoStartAttempted = true

  sendTrailerStartEvent(m.global.trackingLoggingTask, m.top.trailerId)
End Function


Function stopVideo()
  m.videoStartAttempted = false
  m.VideoPlayer.visible = false
  m.VideoPlayer.control = "stop"

  ' set currentPos as milliseconds and integer because doing float math leads to incosistent rounding
  ' which throws analytics off slightly
  currentPos = Int(m.VideoPlayer.position * 1000)
  m.playProgressCounter = calculatePlayProgressCounter(m.playProgressCounter, currentPos, m.top.nowPos)
  m.top.nowPos = currentPos

  if m.playProgressCounter > 0
    sendTrailerPlayProgressEvent(m.global.trackingLoggingTask, m.top.trailerId, m.top.nowPos, m.playProgressCounter)
    m.playProgressCounter = 0   'reset the playProgressCounter
  end if

  sendTrailerFinishEvent(m.global.trackingLoggingTask, m.top.trailerId, m.VideoPlayer.position)
End Function


Function calculatePlayProgressCounter(playProgressCounter, currentPos, previousPos)
  return playProgressCounter + (currentPos - previousPos)   'expect always positive for vitg
End Function


Function sendTrailerStartEvent(trackingTask, trailerId)
  startTrailerEvent = {
    type: "start_trailer"
    values: {
      video_id: trailerId.toInt()   'the content id of the trailer
      is_fullscreen: false
      video_player: "VIDEO_IN_GRID"
    }
  }
  trackingTask.trackEvent = startTrailerEvent
End Function


Function sendTrailerPlayProgressEvent(trackingTask, trailerId, position, viewTime)
  trailerPlayProgressEvent = {
    type: "trailer_play_progress"
    values: {
      video_id: trailerId.toInt()
      position: position  'in ms
      view_time: viewTime  'in ms
      video_player: "VIDEO_IN_GRID"
    }
  }
  trackingTask.trackEvent = trailerPlayProgressEvent
End Function


Function sendTrailerFinishEvent(trackingTask, trailerId, position)
  finishTrailerEvent = {
    type: "finish_trailer"
    values: {
      video_id: trailerId.toInt()   'the content id of the trailer
      end_position: position * 1000
    }
  }
  trackingTask.trackEvent = finishTrailerEvent
End Function