' Initializes the reusable preview player component
' Sets up member variables, observers, and reparents the global video node
Function init()
  m.constants = getConstantsFromGlobal()
  m.tracking = TubiTrackingInfo(m.constants)
  m.nodeHelpers = TubiNodeHelpers()

  ' Video configuration constants
  m.VIDEO_NOTIFICATION_INTERVAL = 1.0
  m.VIDEO_CGMS = "3"
  m.VIDEO_POSITION_BUFFER = 5 ' Seconds from end to clamp seek
  m.VIEW_TIME_LOG_THRESHOLD = 15000

  m.playerPosition = 0
  m.lastPingTime = 0
  m.analyticsInterval = m.constants.player.pingFrequency

  ' Track previous and current page info for analytics transitions
  m.previousPageInfo = {
    pageType: "home_page"
    pageValues: {}
  }

  m.currentPageInfo = {
    pageType: "home_page"
    pageValues: {}
  }

  ' Video state: "stop", "play", "pause", "prebuffer"
  m.videoState = "stop"

  ' Reference to the shared video node - will be reparented from m.global.appVideoNode
  m.video = invalid

  ' Set up observers for interface fields
  topRef = m.top
  topRef.observeFieldScoped("pageInfoForAnalytics", "onPageInfoUpdatedForAnalytics")
  topRef.observeFieldScoped("updateContent", "onContentChange")
  topRef.observeFieldScoped("control", "onControlChange")
  topRef.observeFieldScoped("seekTo", "onSeekToChange")
  topRef.observeFieldScoped("width", "onWidthChange")
  topRef.observeFieldScoped("height", "onHeightChange")
End Function


' Re-parents m.global.appVideoNode to this component and sets up observers
Function reParentVideoNode() as Void
  ' Get the global video node
  if m.global.appVideoNode <> invalid
    m.video = m.global.appVideoNode

    ' Clean up any existing observers before reparenting
    m.nodeHelpers.unObserveAll(m.video)

    ' Re-parent it to this component
    m.top.appendChild(m.video)

    ' Configure video node properties
    m.video.update({
      enableUI: false
      enableTrickPlay: false
      cgms: m.VIDEO_CGMS
      notificationInterval: m.VIDEO_NOTIFICATION_INTERVAL
      visible: true
      width: m.top.width
      height: m.top.height
    }, true)

    ' Set up observers for video node fields
    m.video.observeFieldScoped("position", "onVideoPositionChange")
    m.video.observeFieldScoped("state", "onVideoStateChange")
    m.video.observeFieldScoped("duration", "onVideoDurationChange")
    m.video.observeFieldScoped("bufferingStatus", "onVideoBufferingStatusChange")
  end if
End Function


' Handles width changes - updates video node dimensions
' @param msg - Message containing the new width value
Function onWidthChange(msg) as Void
  if m.video = invalid then return

  m.video.width = msg.getData()
End Function


' Handles height changes - updates video node dimensions
' @param msg - Message containing the new height value
Function onHeightChange(msg) as Void
  if m.video = invalid then return

  m.video.height = msg.getData()
End Function


' Forwards video position to interface and handles analytics
' @param msg - Message containing the current video position
Function onVideoPositionChange(msg) as Void
  try
    position = msg.getData()
    m.top.position = position
    m.playerPosition = position

    ' Analytics - fire progress events at intervals
    if m.playerPosition >= m.lastPingTime + m.analyticsInterval
      previewProgressEvent = getPreviewProgressEvent(m.currentPageInfo, "onVideoPositionChange")
      if previewProgressEvent <> invalid
        trackEvent(previewProgressEvent)
        m.lastPingTime = m.playerPosition
      end if
    end if
  catch e
    logError(FormatJSON({ error: e.message }), "videoPosition", "position-change-error", 1)
  end try
End Function


' Forwards video state to interface and handles state transitions
' @param msg - Message containing the current video state
Function onVideoStateChange(msg) as Void
  state = msg.getData()
  m.top.playerState = state

  ' Update internal video state based on current state
  if state = "buffering"
    m.videoState = "buffering"
  else if state = "playing"
    m.video.visible = true
    m.videoState = "play"
    ' Fire start_preview event only on initial play (position = 0)
    if m.video.position = 0
      fireStartPreviewEvent()
    end if
  else if state = "finished"
    ' Track finish event before stopping
    finishPreviewEvent = getFinishPreviewEvent(true)
    if finishPreviewEvent <> invalid
      trackEvent(finishPreviewEvent)
    end if
    m.top.content = invalid
    m.videoState = "stop"
  else if state = "stopped"
    m.videoState = "stop"
  else if state = "error"
    handleVideoError()
    m.videoState = "stop"
  end if

  ' Update timestamp based on playback state
  isStoppedState = (state = "stopped" OR state = "finished" OR state = "error" OR state = "paused")
  isActiveState = (state = "buffering" OR state = "playing")

  if isStoppedState
    m.top.timestampOfLastVideoPlayback = createObject("roDateTime").asSeconds()
  else if isActiveState
    m.top.timestampOfLastVideoPlayback = -1
  end if

  m.top.state = state
End Function


' Forwards video duration to interface
' @param msg - Message containing the video duration
Function onVideoDurationChange(msg) as Void
  m.top.duration = msg.getData()
End Function


' Forwards video bufferingStatus to interface
' @param msg - Message containing the buffering status
Function onVideoBufferingStatusChange(msg) as Void
  m.top.bufferingStatus = msg.getData()
End Function


' Handles video errors and logs error information
' Collects player states if multiple video node error detected
Function handleVideoError() as Void
  content = m.video.content
  allNodes = m.top.getAll()
  playerStates = {}

  if checkIfMultipleVideoNodeError(m.video.errorMsg) = true
    for each node in allNodes
      if node.isSubtype("Video")
        parent = node.getParent()
        if parent <> invalid AND parent.id <> invalid
          id = parent.id
          playerStates[id] = node.state
        end if
      end if
    end for
  end if

  errorInfo = getPlaybackErrorInfo(m.video.position, m.video.streamInfo, m.video.errorCode, m.video.errorMsg, content)
  errorInfo.playerStates = playerStates
  jsonErrorInfo = FormatJSON(errorInfo)
  logError(jsonErrorInfo, "videoPlayback", "video-preview-playback", 1)
End Function


' Handles page info updates for analytics
' Fires preview progress event when page type changes
Function onPageInfoUpdatedForAnalytics(msg) as Void
  pageInfo = msg.GetData()
  if pageInfo <> invalid
    m.previousPageInfo = m.currentPageInfo
    m.previousPageInfo.pageOneInfo = getAnalyticsPageInfo(m.previousPageInfo)

    m.currentPageInfo = pageInfo
    m.currentPageInfo.pageOneInfo = getAnalyticsPageInfo(m.currentPageInfo)

    if m.previousPageInfo.pageType <> m.currentPageInfo.pageType
      previewProgressEvent = getPreviewProgressEvent(m.previousPageInfo, "onPageInfoUpdatedForAnalytics")
      if previewProgressEvent <> invalid
        trackEvent(previewProgressEvent)
        m.lastPingTime = m.playerPosition
      end if
    end if
  end if
End Function


' Handles content changes
' Prepares video for playback when new content is set
Function onContentChange() as Void
  m.top.state = ""
  if m.top.content <> invalid
    prepareToStartVideo(m.top.content)
  end if
End Function


' Handles control changes (play, pause, resume, stop, prebuffer)
' Routes control commands to appropriate functions
Function onControlChange() as Void
  if m.video <> invalid AND m.video.content <> invalid
    if m.top.control = "play"
      playContent()
    else if m.top.control = "pause"
      pauseContent()
    else if m.top.control = "resume"
      resumeContent()
    else if m.top.control = "stop"
      stopContent()
    else if m.top.control = "prebuffer"
      m.video.control = "prebuffer"
    end if
  end if
End Function


' Plays the video
Function playContent() as Void
  if m.video = invalid then return

  m.videoState = "play"
  m.top.state = "playing"
  m.video.control = "play"

  m.lastPingTime = 0
  m.playerPosition = 0
End Function


' Resumes video playback
' Only resumes if video is currently paused
Function resumeContent() as Void
  if m.video = invalid then return
  if m.videoState <> "pause" then return

  m.videoState = "play"
  m.video.control = "resume"
End Function


' Pauses video playback
' Forces stop instead of pause when buffering (firmware workaround)
Function pauseContent() as Void
  if m.video = invalid then return

  ' When buffering, force stop instead of pause (firmware issue workaround)
  if m.videoState = "buffering"
    m.videoState = "stop"
    m.video.control = "stop"
  else if m.videoState = "play"
    m.videoState = "pause"
    m.video.control = "pause"
  end if
End Function


' Stops video playback
' Fires finish preview event if content was playing
Function stopContent() as Void
  if m.video = invalid then return

  if m.videoState <> "stop" AND m.video.state <> "stopped"
    if m.video.content <> invalid AND m.video.content.id <> invalid AND m.playerPosition > 0
      finishPreviewEvent = getFinishPreviewEvent()
      if finishPreviewEvent <> invalid
        trackEvent(finishPreviewEvent)
      end if
    end if

    m.video.control = "stop"
  end if

  m.videoState = "stop"
  m.top.content = invalid
End Function


' Prepares video content for playback
' @param content - ContentNode with video information
Function prepareToStartVideo(content) as Void
  ' Ensure video node is reparented before setting content
  if m.video = invalid OR m.video.getParent() = invalid OR m.video.getParent().id <> m.top.id
    reParentVideoNode()
  end if

  if m.video = invalid then return

  m.video.content = invalid
  m.top.duration = -1
  m.video.content = content
End Function


' Seeks to a specific position in the video
' @param position - Target position in seconds
' @return Integer - Clamped position value
Function jumpToPosition(position) as Integer
  if m.video = invalid then return position

  ' Clamp position to valid range
  if position > (m.video.duration - m.VIDEO_POSITION_BUFFER)
    position = m.video.duration - m.VIDEO_POSITION_BUFFER
  else if position < 0
    position = 0
  end if

  previewProgressEvent = getPreviewProgressEvent(m.currentPageInfo, "jumpToPosition")
  if previewProgressEvent <> invalid
    trackEvent(previewProgressEvent)
  end if

  m.video.seek = position
  m.lastPingTime = position

  return position
End Function


' Handles seek requests
' @param msg - Message containing the target position
Function onSeekToChange(msg) as Void
  position = msg.getData()
  jumpToPosition(position)
End Function


' Checks if error is a multiple video node error
' @param errorMsg - Error message to check
' @return Boolean - True if multiple video node error
Function checkIfMultipleVideoNodeError(errorMsg) as Boolean
  return isNonEmptyString(errorMsg) = true AND LCase(errorMsg) = "player: only one playing instance supported."
End Function


' ═══════════════════════════════════════════════════════════════════════════════
' ANALYTICS FUNCTIONS
' ═══════════════════════════════════════════════════════════════════════════════
' This section contains all analytics-related functions for preview video tracking.
' Includes helper functions for data extraction and event creation/tracking.


' Gets video ID from current video content
' @return Integer - Video ID or 0 if invalid
Function getVideoId() as Integer
  if m.video = invalid OR m.video.content = invalid then return 0

  videoContent = m.video.content
  if isNonEmptyString(videoContent.id) = true
    return videoContent.id.toInt()
  end if

  return 0
End Function


' Gets preview ID from current video content
' @return String - Preview ID or empty string if invalid
Function getPreviewId() as String
  if m.video = invalid OR m.video.content = invalid then return ""
  return m.video.content.previewId
End Function


' Gets page info for analytics from pageInfo object or current page
' @param pageInfo - Optional page info object
' @return Object - Analytics page info
Function getAnalyticsPageInfo(pageInfo = invalid) as Object
  if pageInfo <> invalid
    if pageInfo.pageOneInfo <> invalid
      return pageInfo.pageOneInfo
    else if pageInfo.pageType <> invalid
      return m.tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
    end if
  end if

  ' Default to current page info
  return m.tracking.getAnalyticsPage(m.currentPageInfo.pageType, m.currentPageInfo.pageValues)
End Function


' Creates base analytics event values common to all preview events
' Handles both regular video content and AdContentNode
' @return Object - Base event values with video_id or ad_id, preview_id, video_player
'                  Returns invalid if AdContentNode is missing required ad_id
Function getBaseEventValues() as Object
  if m.video = invalid then return invalid

  videoContent = m.video.content
  if videoContent = invalid then return invalid

  baseValues = {
    preview_id: getPreviewId()
    video_player: m.top.videoPlayerType
  }

  ' Handle AdContentNode vs regular content
  if videoContent.isSubType("AdContentNode") = true
    if isNonEmptyAA(videoContent.adInfo) = true AND isNonEmptyString(videoContent.adInfo.ad_id) = true
      baseValues.ad_id = videoContent.adInfo.ad_id.toInt()
    else
      ' ad_id is required for ad content nodes
      return invalid
    end if
  else
    baseValues.video_id = getVideoId()
  end if

  return baseValues
End Function


' Gets content tile for analytics from component info or video content
' Tries to extract from componentInfo first, then falls back to generating from video content
' @return Object - Content tile object or invalid
Function getContentTileForAnalytics() as Object
  contentTile = invalid
  componentInfo = m.top.componentInfoForAnalytics

  ' Try to get content tile from component info first
  if isAA(componentInfo) = true AND isAA(componentInfo.componentOneof) = true
    categoryComponent = componentInfo.componentOneof.category_component
    if categoryComponent <> invalid
      contentTile = categoryComponent.content_tile
    end if
  end if

  ' Fallback to generating content tile from video content
  if contentTile = invalid AND m.video <> invalid
    videoContent = m.video.content
    if videoContent <> invalid
      contentTile = m.tracking.getAnalyticsTile(videoContent, 1, 1)
    end if
  end if

  return contentTile
End Function


' Attaches component info to analytics event if available
' @param event - Event object to attach component info to
' @return Object - Event with component info attached
Function attachComponentInfoToEvent(event as Object) as Object
  if event = invalid then return invalid

  componentInfo = m.top.componentInfoForAnalytics
  if isAA(componentInfo) = true AND isAA(componentInfo.componentOneof) = true
    event.values.componentOneof = componentInfo.componentOneof
  end if

  return event
End Function


' Tracks an analytics event
' @param event - Event object to track
Function trackEvent(event as Object) as Void
  trackingLoggingTask = getFieldFromGlobal("trackingLoggingTask")
  if trackingLoggingTask <> invalid AND event <> invalid
    trackingLoggingTask.trackEvent = event
  end if
End Function


' Creates preview progress event for analytics
' @param pageInfo - Page information for tracking context
' @param callSource - Source function name for debugging
' @return Object - Preview progress event or invalid
Function getPreviewProgressEvent(pageInfo, callSource) as Object
  if m.video = invalid then return invalid
  if m.playerPosition <= m.lastPingTime OR m.videoState <> "play" then return invalid

  baseValues = getBaseEventValues()
  if baseValues = invalid then return invalid

  viewTime = Int((m.playerPosition - m.lastPingTime) * 1000)
  currentPosition = Int(m.playerPosition * 1000)
  videoId = getVideoId()

  ' Build event with base values
  previewProgressEvent = {
    type: "preview_play_progress"
    values: baseValues
  }

  ' Add progress-specific fields
  previewProgressEvent.values.position = currentPosition
  previewProgressEvent.values.view_time = viewTime
  previewProgressEvent.values.pageOneof = getAnalyticsPageInfo(pageInfo)

  ' Handle component info for analytics
  if m.top.isDetailScreen = true
    ' Detail screen needs preview_component wrapping
    contentTile = getContentTileForAnalytics()

    ' Wrap content tile in preview_component for detail screen
    if contentTile <> invalid
      previewComponent = m.tracking.getAnalyticsComponent("preview_component", {
        content_tile: contentTile
      })
      previewProgressEvent.values.componentOneof = previewComponent
    end if
  else
    ' Non-detail screen: use component info as-is
    componentInfo = m.top.componentInfoForAnalytics
    if isAA(componentInfo) = true AND isAA(componentInfo.componentOneof) = true
      previewProgressEvent.values.componentOneof = componentInfo.componentOneof
    end if
  end if

  ' Debug logging for large view times
  if viewTime >= m.VIEW_TIME_LOG_THRESHOLD
    videoInfo = {
      playerState: m.video.state
      videoId: videoId
      viewTime: viewTime
      playerPosition: m.playerPosition
      lastPingTime: m.lastPingTime
      callSource: callSource
    }
    logInfo(FormatJSON(videoInfo), "videoInfo", "preview-view-time-exceeds")
  end if

  return previewProgressEvent
End Function


' Creates finish preview event for analytics
' Handles both regular video content and AdContentNode (skinAd, adRowlistCarousel, adRowlistSpotlight)
' @param hasCompleted - Boolean indicating if video completed playback
' @return Object - Finish preview event or invalid
Function getFinishPreviewEvent(hasCompleted = false) as Object
  if m.video = invalid then return invalid

  videoContent = m.video.content
  if videoContent = invalid OR isNonEmptyString(videoContent.url) = false then return invalid

  baseValues = getBaseEventValues()
  if baseValues = invalid then return invalid

  finishPreviewEvent = {
    type: "finish_preview"
    values: baseValues
  }

  ' Add finish-specific fields
  finishPreviewEvent.values.end_position = Int(m.playerPosition * 1000)
  finishPreviewEvent.values.pageOneof = getAnalyticsPageInfo()
  finishPreviewEvent.values.has_completed = hasCompleted

  ' Attach component info and return
  return attachComponentInfoToEvent(finishPreviewEvent)
End Function


' Fires start preview analytics event
' Handles both regular video content and AdContentNode (skinAd, adRowlistCarousel, adRowlistSpotlight)
' Only fires when video starts playing from beginning
Function fireStartPreviewEvent() as Void
  if m.video = invalid then return

  videoContent = m.video.content
  if videoContent = invalid OR videoContent.id = invalid then return

  baseValues = getBaseEventValues()
  if baseValues = invalid then return

  startPreviewEvent = {
    type: "start_preview"
    values: baseValues
  }

  ' Add start-specific fields
  startPreviewEvent.values.is_fullscreen = false
  startPreviewEvent.values.pageOneof = getAnalyticsPageInfo()

  ' Attach component info and track event
  startPreviewEvent = attachComponentInfoToEvent(startPreviewEvent)
  if startPreviewEvent <> invalid
    trackEvent(startPreviewEvent)
  end if
End Function


' Creates playback error information object
' @param position - Video position when error occurred
' @param streamInfo - Stream information object
' @param errorCode - Roku error code
' @param errorMsg - Error message string
' @param content - Content node
' @return Object - Error information object
Function getPlaybackErrorInfo(position, streamInfo, errorCode, errorMsg, content) as Object
  errorInfo = {
    video_id: ""
    video_url: ""
  }

  if errorMsg <> invalid
    if errorCode = 0
      errorInfo.error_message = "Network error"
    else
      errorInfo.error_message = errorMsg
    end if
  end if

  errorInfo.error_code = errorCode
  errorInfo.is_video_preview = true

  if content <> invalid then errorInfo.video_id = content.id

  if position > 0 AND streamInfo <> invalid
    errorInfo.video_url = removeQueryParams(streamInfo.streamUrl)
  else if content <> invalid
    errorInfo.video_url = removeQueryParams(content.url)
  end if

  return errorInfo
End Function
