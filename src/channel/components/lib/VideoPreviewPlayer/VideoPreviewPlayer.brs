Function init()
  tubiLog("VideoPreview.init")

  m.constants = getConstantsFromGlobal()

  m.playerPosition = 0
  m.lastPingTime = 0

  m.analyticsInterval = m.constants.player.pingFrequency

  ' The analytics event needs to be tracked during transition between home screen & detail screen,
  ' so maintaining pageTypes for previous screen & current screen
  m.previousPageType= "home_page"
  m.currentPageType= "home_page"

  m.Video = m.top.findNode("VideoNode")  ' reference in case we change from extending Video to extending Group
  m.Video.observeField("position", "onVideoPositionChange")
  m.Video.observeField("state", "onVideoStateChange")

  m.top.observeField("pageTypeForAnalytics", "onPageTypeUpdatedForAnalytics")
  m.top.observeField("updateContent", "onContentChange")
  m.top.observeField("control", "onControlChange")

End Function


Function onPageTypeUpdatedForAnalytics(msg)

  pageType = msg.GetData()
  m.previousPageType = m.currentPageType
  m.currentPageType = pageType

  if m.previousPageType <> m.currentPageType
    previewProgressEvent = getPreviewProgressEvent(m.previousPageType)
    if previewProgressEvent <> invalid
      trackEvent(previewProgressEvent)
      m.lastPingTime = m.playerPosition
    end if
  end if

End Function


' plays the video
Function playContent()
  m.Video.control = "play"
  m.lastPingTime = 0

  if m.Video.content.id <> invalid

    startPreviewEvent = {
      type: "start_preview"
      values: {
        video_id: m.Video.content.id.toInt()
        is_fullscreen: false
        video_player: "BANNER"
        page_type: m.currentPageType
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
  else if state = "error"
    content = m.video.content
    errorInfo = getPlaybackErrorInfo(m.video.position, m.video.streamInfo, m.video.errorCode, m.video.errorMsg, content)
    tubiLog(FormatJSON(errorInfo), "error", "videoPlayback", "video-preview-playback")
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
    previewProgressEvent = getPreviewProgressEvent(m.currentPageType)
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
    m.Video.control = "prebuffer"
  end if
End Function


' resumes the video
Function resumeContent()
  if m.Video.state = "paused"
    m.Video.control = "resume"
  end if
End Function


' pauses the video
Function pauseContent()
  if m.Video.state = "playing"
    m.Video.control = "pause"
  else if m.Video.state = "buffering" ' added this check to avoid playing content once the buffering is completed when focus is on sidenav/topnav
    m.Video.control = "stop"
  end if
End Function


' stops the video
Function stopContent()

  if m.Video.state <> "stopped" AND m.Video.state <> "finished"
    if m.Video.content.id <> invalid
      finishPreviewEvent = getFinishPreviewEvent()
      trackEvent(finishPreviewEvent)
    end if
    m.Video.control = "stop"
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


' @pageType: string, value can be home_page/video_page/series_detail_page
Function getPreviewProgressEvent(pageType)

  previewProgressEvent = invalid
  if m.playerPosition > m.lastPingTime AND m.Video.state = "playing"

    viewTime = Int((m.playerPosition - m.lastPingTime) * 1000) 'ms

    previewProgressEvent = {
      type: "preview_play_progress"
      values: {
        video_id: m.Video.content.id.toInt()
        position: Int(m.playerPosition * 1000) 'ms
        view_time: viewTime
        video_player: "BANNER"
        page_type: pageType
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
      page_type: m.currentPageType
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
