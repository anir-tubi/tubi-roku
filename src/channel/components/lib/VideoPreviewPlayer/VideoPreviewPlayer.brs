Function init()
  tubiLog("VideoPreview.init")

  m.constants = getConstantsFromGlobal()

  m.tubiTrackingInfo = TubiTrackingInfo(m.constants)

  m.playerPosition = 0
  m.lastPingTime = 0

  m.analyticsInterval = m.constants.player.pingFrequency

  ' The analytics event needs to be tracked during transition between home screen & detail screen,
  ' so maintaining pageTypes for previous screen & current screen
  m.previousPageInfo = { pagetype: "home_page" }
  m.currentPageInfo = { pagetype: "home_page" }

  m.Video = m.top.findNode("VideoNode") ' reference in case we change from extending Video to extending Group
  m.Video.observeField("position", "onVideoPositionChange")
  m.Video.observeField("state", "onVideoStateChange")
  if getExperimentResource("roku_async_stop", "roku_async_stop_v4", false).enabled = true then
    m.Video.asyncStopSemantics = true
  end if

  m.top.observeField("pageInfoForAnalytics", "onPageInfoUpdatedForAnalytics")
  m.top.observeField("updateContent", "onContentChange")
  m.top.observeField("control", "onControlChange")
  m.top.observeField("seekTo", "onSeekToChange")
  ' Creating a local variable to hold the video playback state so that we can avoid rare conditions where video node state
  ' does not update on time.
  ' Allowed values are "stop", "play", "pause", "prebuffer"
  m.videoState = "stop"
End Function


Function onPageInfoUpdatedForAnalytics(msg)
  pageInfo = msg.GetData()
  if pageInfo <> invalid
    m.previousPageInfo = m.currentPageInfo
    m.currentPageInfo = pageInfo

    if m.previousPageInfo.pagetype <> m.currentPageInfo.pagetype
      previewProgressEvent = getPreviewProgressEvent(m.previousPageInfo, "onPageInfoUpdatedForAnalytics")
      if previewProgressEvent <> invalid
        trackEvent(previewProgressEvent)
        m.lastPingTime = m.playerPosition
      end if
    end if
  end if
End Function


' plays the video
Function playContent()
  m.Video.visible = true
  m.videoState = "play"
  m.top.state = "playing" ' The player takes a little while to start playing. If we don't update the state here then setVideoPreviewAfterFocus will try to stop the video and then play it again even though it is the same content
  m.Video.control = "play"

  m.lastPingTime = 0
  m.playerPosition = 0

  if m.Video.content.id <> invalid

    startPreviewEvent = {
      type: "start_preview"
      values: {
        video_id: m.Video.content.id.toInt()
        is_fullscreen: false
        video_player: "BANNER"
        pageOneof: m.tubiTrackingInfo.getAnalyticsPage(m.currentPageInfo.pageType, m.currentPageInfo.pageValues)
      }
    }
    trackEvent(startPreviewEvent)
  end if

End Function


Function onContentChange() as Void
  m.top.state = ""
  if m.top.content <> invalid
    prepareToStartVideo(m.top.content)
  end if
End Function


Function onControlChange()
  if m.video.content <> invalid
    if m.top.control = "play"
      playContent()
    else if m.top.control = "pause"
      pauseContent()
    else if m.top.control = "resume"
      resumeContent()
    else if m.top.control = "stop"
      stopContent()
    end if
  end if

End Function


'Occurs when m.Video.state changes (not when m.top.state changes)
Function onVideoStateChange(msg)
  state = msg.GetData()
  'Adding below block to consider 'm.videoState' as single source of truth for the video state instead of directly accessing 'state' interface
  if state = "buffering"
    m.videoState = state
  else if state = "playing"
    m.videoState = "play"
  end if

  if state = "finished"
    finishPreviewEvent = getFinishPreviewEvent(true)
    trackEvent(finishPreviewEvent)
    m.top.content = invalid
    m.videoState = "stop"
  else if state = "stopped" then
    ' If Roku stops the video node instead of us (when application is backgrounded as one example) then the state does not get updated without this
    m.videoState = "stop"
  else if state = "error"
    content = m.video.content
    errorInfo = getPlaybackErrorInfo(m.video.position, m.video.streamInfo, m.video.errorCode, m.video.errorMsg, content)
    jsonErrorInfo = FormatJSON(errorInfo)
    tubiLog(jsonErrorInfo, "error", "videoPlayback", "video-preview-playback", 0.1)

    errorInfo.type = m.constants.errors.type.videoError + " " + m.video.errorCode.toStr()
    errorInfo.name = m.constants.errors.message.videoPreview
    ' sending the logs to sentry sdk
    tubiException(errorInfo, "error", 0.1)
    m.videoState = "stop"
  end if

  if state = "stopped" OR state = "finished" OR state = "error" OR state = "paused" then
    m.top.timestampOfLastVideoPlayback = createObject("roDateTime").asSeconds()
  else if state = "buffering" OR state = "playing" then
    m.top.timestampOfLastVideoPlayback = -1
  end if

  m.top.state = state
End Function


'''''''''''''''''''''''''
' onVideoPositionChange
'
Function onVideoPositionChange(msg)
  m.playerPosition = msg.GetData()

  ' Analytics
  if m.playerPosition >= m.lastPingTime + m.analyticsInterval
    previewProgressEvent = getPreviewProgressEvent(m.currentPageInfo, "onVideoPositionChange")
    if previewProgressEvent <> invalid
      trackEvent(previewProgressEvent)
      m.lastPingTime = m.playerPosition
    end if
  end if

End Function


' Helper function to update content to node and prebuffer before playing the video
' @content: ContentNode, it contains videopreviewUrl, streamFormat & id for playback
Function prepareToStartVideo(content)
  m.Video.content = invalid
  m.Video.content = content
End Function


' resumes the video
Function resumeContent()
  if m.videoState = "pause"
    m.videoState = "play"
    m.Video.control = "resume"
  end if
End Function


'pauseContent triggers when focus moves to sidenav or top nav,
Function pauseContent()
  'when video preview is buffering, the video preview getting played even though we set control as pause(assuming it is firmware issue).
  'so forcing the video preview to stop when it is buffering. Also added alwaysNotify to the video node control field.
  'added this check to avoid playing content once the buffering is completed when focus is on sidenav/topnav
  if m.videoState = "buffering"
    m.videoState = "stop"
    getExperimentResource("roku_async_stop", "roku_async_stop_v4", true)
    m.Video.control = "stop"
  else if m.videoState = "play"
    m.videoState = "pause"
    m.Video.control = "pause"
  end if
End Function


' stops the video
Function stopContent()
  if m.videoState <> "stop" AND m.Video.state <> "stopped" then
    if m.Video.content.id <> invalid AND m.playerPosition > 0
      finishPreviewEvent = getFinishPreviewEvent()
      trackEvent(finishPreviewEvent)
    end if

    getExperimentResource("roku_async_stop", "roku_async_stop_v4", true)
    m.Video.control = "stop"
  end if
  m.videoState = "stop"
  m.top.content = invalid
End Function


' Helper function for sending analytics event
' @event: assocarray, it contains type & values for the event
Function trackEvent(event as Object)
  trackingLoggingTask = getFieldFromGlobal("trackingLoggingTask")
  if trackingLoggingTask <> invalid AND event <> invalid then
    trackingLoggingTask.trackEvent = event
  end if
End Function


' @pageInfo: assocarray, value can be { pagetype: "home_page", pagevalues: {}}
' @callSource: string, temporary param used for debugging large playProgressEvents, should be removed after issue is fixed.
Function getPreviewProgressEvent(pageInfo, callSource)
  previewProgressEvent = invalid

  if m.playerPosition > m.lastPingTime AND m.videoState = "play"
    viewTime = Int((m.playerPosition - m.lastPingTime) * 1000) 'ms

    previewProgressEvent = {
      type: "preview_play_progress"
      values: {
        video_id: m.Video.content.id.toInt()
        position: Int(m.playerPosition * 1000) 'ms
        view_time: viewTime
        video_player: "BANNER"
        pageOneof: m.tubiTrackingInfo.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
      }
    }


    '//TODO:: Below block is added for debugging large viewtime issue. It can be removed when there are no (or very less) large viewtime(>=15000) in preview play_progress event by verifying the datadog logs.
    'Note: This is client bug and we made a possible fix.
    if viewTime >= 15000
      videoInfo = {}
      videoInfo.playerState = m.Video.state
      videoInfo.videoId = m.Video.content.id.toInt()
      videoInfo.viewTime = viewTime
      videoInfo.playerPosition = m.playerPosition
      videoInfo.lastPingTime = m.lastPingTime
      videoInfo.callSource = callSource
      tubiLog(FormatJSON(videoInfo), "info", "videoInfo", "preview-view-time-exceeds")
    end if

  end if

  return previewProgressEvent

End Function


'set hasCompleted to true when user watches the entire video preview, otherwise set it to false.
Function getFinishPreviewEvent(hasCompleted = false)

  if m.Video.content = invalid OR m.Video.content.id = invalid then
    ' TODO remove after roku_async_stop_v4 experiment concludes
    errorInfo = {}

    if m.top.content <> invalid then
      errorInfo["topContentId"] = m.top.content.id
      errorInfo["topContentUrl"] = m.top.content.url
    end if

    if m.currentPageInfo <> invalid then
      errorInfo["currentPage"] = m.currentPageInfo.pagetype
    end if

    if m.previousPageInfo <> invalid then
      errorInfo["previousPage"] = m.previousPageInfo.pagetype
    end if

    errorInfo["videoState"] = m.videoState
    errorInfo["playerPosition"] = m.playerPosition
    errorInfo["playerErrorCode"] = m.Video.errorCode
    errorInfo["playerErrorStr"] = m.Video.errorStr
    errorInfo["playerState"] = m.Video.state
    errorInfo["playerControl"] = m.Video.control
    errorInfo["playerDuration"] = m.Video.duration

    tubiLog(FormatJSON(errorInfo), "info", "clientInfo", "device-info")
    return invalid
  end if

  finishPreviewEvent = {
    type: "finish_preview"
    values: {
      video_id: m.Video.content.id.toInt()
      end_position: Int(m.playerPosition * 1000) 'ms
      pageOneof: m.tubiTrackingInfo.getAnalyticsPage(m.currentPageInfo.pageType, m.currentPageInfo.pageValues)
      has_completed: hasCompleted
    }
  }
  return finishPreviewEvent

End Function


' gets playback error information
' @position: Double, position of video
' @streamInfo: assocarray, information about the video stream that is currently playing or buffering
' @errorCode: integer, the error code associated with the video play error set in the state field
' @errorMsg: string, an error message describing the video play error set in the state field
' @content: ContentNode, it contains videopreviewUrl, streamFormat & id for playback
Function getPlaybackErrorInfo(position, streamInfo, errorCode, errorMsg, content)
  errorInfo = {
    video_id: ""
    video_url: ""
  }
  if errorMsg <> invalid
    if errorCode = 0
      ' original network error message is to long:
      ' "Network error.  This could be caused by any of the following problems: (1) The server is down or unresponsive. (2) The server is unreachable. (3) There is a network setup issue on the client."
      errorInfo.error_message = "Network error"
    else
      errorInfo.error_message = errorMsg
    end if
  end if
  errorInfo.error_code = errorCode
  errorInfo.is_video_preview = true

  if content <> invalid then errorInfo.video_id = content.id

  if position > 0 AND streamInfo <> invalid
    errorInfo.video_url = removeExcessUrl(streamInfo.streamUrl)
  else if content <> invalid
    errorInfo.video_url = removeExcessUrl(content.url)
  end if

  return errorInfo
End Function


'Helper function that removes all characters after the ? in the url
Function removeExcessUrl(url)
  cutUrl = ""
  if type(url) = "roString" OR type(url) = "String"
    position = url.Instr(Chr(63)) 'checks for the position of the "?" in the url string
    if position > -1
      cutUrl = url.Left(position)
    else
      cutUrl = url
    end if
  end if
  return cutUrl
End Function


' Currently only used for automated testing but could be used in the future for other uses
Function jumpToPosition(position)
  'Don't let position be out of bounds of the duration of the video
  if position > (m.Video.duration - 5)
    position = m.Video.duration - 5
  else if position < 0
    position = 0
  end if

  previewProgressEvent = getPreviewProgressEvent(m.currentPageInfo, "jumpToPosition")
  if previewProgressEvent <> invalid
    trackEvent(previewProgressEvent)
  end if

  m.Video.seek = position

  m.lastPingTime = position

  return position
End Function


Function onSeekToChange(msg)
  position = msg.getData()
  jumpToPosition(position)
End Function
