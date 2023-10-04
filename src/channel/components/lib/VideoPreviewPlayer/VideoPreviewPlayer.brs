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

  m.Video = m.top.findNode("VideoNode")  ' reference in case we change from extending Video to extending Group
  m.Video.observeField("position", "onVideoPositionChange")
  m.Video.observeField("state", "onVideoStateChange")

  m.top.observeField("pageInfoForAnalytics", "onPageInfoUpdatedForAnalytics")
  m.top.observeField("updateContent", "onContentChange")
  m.top.observeField("control", "onControlChange")
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
      previewProgressEvent = getPreviewProgressEvent(m.previousPageInfo)
      if previewProgressEvent <> invalid
        trackEvent(previewProgressEvent)
        m.lastPingTime = m.playerPosition
      end if
    end if
  end if
End Function


' plays the video
Function playContent()
  m.videoState = "play"
  m.Video.control = "play"
  m.lastPingTime = 0

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


Function onContentChange() As Void
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
  if state = "finished"
    finishPreviewEvent = getFinishPreviewEvent(true)
    trackEvent(finishPreviewEvent)
    m.top.content = invalid
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
    previewProgressEvent = getPreviewProgressEvent(m.currentPageInfo)
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
  if type(content) = "roSGNode"
    m.Video.content = content
    m.videoState = "prebuffer"
    m.Video.control = "prebuffer"
  end if
End Function


' resumes the video
Function resumeContent()
  if m.videoState = "pause"
    m.videoState = "play"
    m.Video.control = "resume"
  end if
End Function


' pauses the video
Function pauseContent()
  if m.videoState = "play"
    m.videoState = "pause"
    m.Video.control = "pause"
  else if m.videoState <> "stop" ' added this check to avoid playing content once the buffering is completed when focus is on sidenav/topnav
    m.videoState = "stop"
    m.Video.control = "stop"
  end if
End Function


' stops the video
Function stopContent()
  if m.videoState <> "stop"
    if m.Video.content.id <> invalid AND m.playerPosition > 0
      finishPreviewEvent = getFinishPreviewEvent()
      trackEvent(finishPreviewEvent)
    end if
    m.Video.control = "stop"
    m.videoState = "stop"
  end if
  m.top.content = invalid
End Function


' Helper function for sending analytics event
' @event: assocarray, it contains type & values for the event
Function trackEvent(event as object)
  trackingLoggingTask = getFieldFromGlobal("trackingLoggingTask")
  if trackingLoggingTask <> invalid
    trackingLoggingTask.trackEvent = event
  end if
End Function


' @pageInfo: assocarray, value can be { pagetype: "home_page", pagevalues: {}}
Function getPreviewProgressEvent(pageInfo)

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

  end if

  return previewProgressEvent

End Function


'set hasCompleted to true when user watches the entire video preview, otherwise set it to false.
Function getFinishPreviewEvent(hasCompleted = false)

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
  if type(url) = "roString" or type(url) = "String"
    position = url.Instr(Chr(63)) 'checks for the position of the "?" in the url string
    if position > -1
      cutUrl = url.Left(position)
    else
      cutUrl = url
    end if
  end if
  return cutUrl
End Function
