' This file is used to send playerlogs. Please refer to the document below for details on all events:
' Document - https://www.notion.so/tubi/RFC-Player-Analytics-Event-v1-0-b8bee0eb69d14cc891baf8e907635f2f
' 
'@constants: assocArray, constants as set in Constants.brs
'@requestQueue: assocArray, a request queue as returned by TubiRequestQueue().create(), default as invalid 
'@logger: AA, TubiLogger returned as associative array, default as invalid 
'
Function PlayerLogLib(constants, requestQueue = invalid, logger = invalid)
  deviceInfo = CreateObject("roDeviceInfo")
  globalNode = getGlobal() 'bs:disable-line 1140 LINT1001

  'We are initializing the PlayerLogLib from VideoPlayer and TubiAds, and we want to use the same trackId for a single playback session. 
  'Therefore, we are setting it as global.
  if globalNode = invalid
    globalNode = {playerLogTrackId: deviceInfo.GetRandomUUID()}
  else if globalNode.playerLogTrackId = invalid
    globalNode.addField("playerLogTrackId", "string", false)
    globalNode.playerLogTrackId = deviceInfo.GetRandomUUID()
  end if

  return {
    constants: constants
    requestQueue: requestQueue
    logger: logger
    deviceInfo: deviceInfo
    globalNode: globalNode

    'The contentStartPerformance event should be triggered in the following situations: when the content starts or resumes playback, and after each AdPod. 
    'The variable m.isVideoPlayed helps determine when to trigger this event. 
    'If isVideoPlayed is set to false, it indicates that the contentStartPerformance event has not been fired during the current playback session. 
    'If isVideoPlayed is true, it means the event has already been triggered for this session.
    isVideoPlayed: false

    content: invalid
    adCtx: {}

    playerLoadTime: -1
    playerSetupTimer: invalid
    playerSetupTime: -1

    adBufferTimer: invalid
    adBufferTime: -1

    'The m.adState will update automatically with any changes in the VideoPlayer's ad state. The possible values include: "ready," "init," "fetching," "adsPending," "adsPlaying," "adsClosed," "noAds," and "adsCompleted."
    'Additionally, m.adState will reset to an empty string "" immediately after the combination of "adsCompleted" state and the ContentStartup performance event.
    'This variable is only meant for Content playback events.
    adState: ""

    adType: "preroll"
    videoState: ""
    videoId: ""
    videoCodecType: ""
    videoResolution: ""
    videoResourceType: ""
    playerPosition: -1

    'public methods
    setVideoControl: playerloglib_setVideoControl
    setVideoState: playerloglib_setVideoState
    setAdState: playerloglib_setAdState
    setAdType: playerloglib_setAdType
    setVideoContent: playerloglib_setVideoContent
    setVideoPosition: playerloglib_setVideoPosition
    setPlayerLoadTime: playerloglib_setPlayerLoadTime
    setPlayerSetupStartTime: playerloglib_setPlayerSetupStartTime
    setPlayerSetupEndTime: playerloglib_setPlayerSetupEndTime
    setAdBufferStartTime: playerloglib_setAdBufferStartTime
    setAdBufferEndTime: playerloglib_setAdBufferEndTime
    setAdCtx: playerloglib_setAdCtx

    'private methods
    resetAdState: playerloglib_resetAdState
    setFirstFrameForContentStart: playerloglib_setFirstFrameForContentStart
    firePlayerSetupPerformanceEvent: playerloglib_firePlayerSetupPerformanceEvent
    fireContentStartupPerformanceEvent: playerloglib_fireContentStartupPerformanceEvent
    fireAdStartupPerformanceEvent: playerloglib_fireAdStartupPerformanceEvent
    sendEvent: playerloglib_sendEvent
    getTrackId: playerloglib_getTrackId
    resetTrackId: playerloglib_resetTrackId
  }
End Function 


'@adType: String, possible values are "preroll", "midroll"
'
Function playerloglib_setAdType(adType = "preroll")
  if isNonEmptyString(adType) = true AND (adType = "preroll" OR adType = "midroll")
    m.adType = adType
  else
    m.adType = "preroll"
  end if
End Function


'@videoState: String, possible values are "buffering", "playing", "paused", "stopping", "stopped", "finished", "error", "none"
'
Function playerloglib_setVideoState(videoState = "")
  if isNonEmptyString(videoState) = true
    m.videoState = videoState
  else
    m.videoState = ""
  end if

  if m.videoState = "playing"

    if m.adState = "adsCompleted"
      isPreroll = true
      if m.adType = "midroll"
        isPreroll = false
      end if
      ' Triggers the ContentStartupPerformance after each AdPod - preroll & midroll
      m.fireContentStartupPerformanceEvent(isPreroll, true)
      m.resetAdState()
    else
      if m.isVideoPlayed = false
        'Triggers the ContentStartupPerformance when playback begins without an ad having been played beforehand.
        m.fireContentStartupPerformanceEvent(false, false)
      end if  
    end if
    m.isVideoPlayed = true
  else if m.videoState = "finished"
    m.isVideoPlayed = false 'reset isVideoPlayed for every new playback session
  end if

End Function


'@adState: String, possible values are "ready", "init", "fetching", "adsPending", "adsPlaying", "adsClosed", "noAds", "adsCompleted"
'
Function playerloglib_setAdState(adState = "")
  if isNonEmptyString(adState) = true
    m.adState = adState
  else
    m.adState = ""
  end if

  if m.adState = "init" OR m.adState = "noAds" OR m.adState = "adsCompleted"
    m.setFirstFrameForContentStart()
  end if
End Function


' resets the m.adState to empty string
Function playerloglib_resetAdState()
  m.adState = ""
End Function


'setFirstFrameForContentStart marks the roTimeSpan or creates new roTimeSpan Object if not available
Function playerloglib_setFirstFrameForContentStart()
  if m.firstFrameTimerForContentStart <> invalid
    m.firstFrameTimerForContentStart.mark()
  else
    m.firstFrameTimerForContentStart = CreateObject("roTimeSpan")
  end if
End Function


'@videoControl: String, possible values are "play", "stop", "pause", "resume", "replay", "prebuffer", "skipcontent", "none" 
'
Function playerloglib_setVideoControl(videoControl = "")
  if isNonEmptyString(videoControl) = true
    if videoControl = "play"
      m.isVideoPlayed = false 'reset isVideoPlayed for every new playback session
    else if videoControl = "stop"  
      m.resetTrackId() 'resets trackId once playback session ends, so that next time it uses new trackId
    end if
  end if
End Function


'@content: roSGNode, a TubiContentNode holds the video related information
'
Function playerloglib_setVideoContent(content = invalid)
  if type(content) = "roSGNode"
    m.content = content
    m.videoId = m.content.id
    m.videoCodecType = m.content.codec
    m.videoResolution = m.content.resolution
    m.videoResourceType = m.content.drmType
  else
    m.content = invalid
    m.videoId = ""
    m.videoCodecType = ""
    m.videoResolution = ""
    m.videoResourceType = ""
  end if
End Function


'setVideoPosition updates the playerPosition to m variable
'@playerPosition: integer, position of the playback
'
Function playerloglib_setVideoPosition(playerPosition = -1)
  if isNumber(playerPosition) = true
    m.playerPosition = playerPosition
  else
    m.playerPosition = -1
  end if
End Function


'setPlayerLoadTime updates the playerLoadTime to m variable
'@playerLoadTime: integer, load time of the player
'
Function playerloglib_setPlayerLoadTime(playerLoadTime = -1)
  if isNumber(playerLoadTime) = true
    m.playerLoadTime = playerLoadTime
  else
    m.playerLoadTime = -1
  end if
End Function


' Player Setup Performance event will be triggered once player is configured, 
' It will calculate the duration cost from the user pressing play/resume button to player setup
'
Function playerloglib_firePlayerSetupPerformanceEvent()
  data = {
    track_id: m.getTrackId()
    video_id: m.videoId
    page_loaded_time: m.playerLoadTime
    player_setup_time: m.playerSetupTime
  }

  message = FormatJSON(data)
  m.sendEvent(message, "playerSetupPerformance", m.logger, m.requestQueue)

  m.playerLoadTime = -1
  m.playerSetupTime = -1
End Function


' playerloglib_sendEvent helps to send the event to backend 
' ad-related events are using the logger instead of directly calling tubiLog(). This is because TubiAds is already in the task, and we want to avoid creating a new task, as tubiLog() initiates its own task.
' player-related events are using tubiLog() directly. Since the VideoPlayerScreen is not in the task, we cannot utilize the requestQueue object from the render thread. Therefore, we’re leveraging tubiLog(), which handles task creation automatically.
Function playerloglib_sendEvent(message = "" as Dynamic, subType = "" as String, logger = invalid, requestQueue = invalid)
  if logger <> invalid AND requestQueue <> invalid
    logger.info(message, "videoInfo", subType, requestQueue)
  else
    tubiLog(message, "info", "videoInfo", subType)
  end if
End Function


' The Content Startup Performance event will be triggered when playback starts or resumes after pre-roll and midroll ads, as well as in cases with no pre-roll.
' It will collect performance information for the startup including details such as manifest, playlist, loadtime etc
' Note: It will not be triggered after regular buffering events.
'
' @isFromPreroll: boolean, tells whether the content started after pre-roll
' @isAfterAd: boolean, tells whether the content started after any ad
'
Function playerloglib_fireContentStartupPerformanceEvent(isFromPreroll, isAfterAd)
  firstFrameTime = -1 'default

  if m.firstFrameTimerForContentStart <> invalid
    firstFrameTime = m.firstFrameTimerForContentStart.totalMilliseconds()
  end if

  'These is no case where the isAfterAd=false and isFromPreroll=true,
  'So for extra safety, we are adding below block
  if isAfterAd = false
    isFromPreroll = false
  end if

  startPosition = -1 'default

  if m.playerPosition > -1
    startPosition = m.playerPosition
  else
    if m.content <> invalid
      startPosition = m.content.nowPos
    end if
  end if

  data = {
    track_id: m.getTrackId()
    video_id: m.videoId
    video_resource_type: m.videoResourceType
    video_codec_type: m.videoCodecType
    video_resolution: m.videoResolution
    start_position: startPosition
    is_after_ad: isAfterAd
    is_from_preroll: isFromPreroll
    first_frame_time: firstFrameTime
  }

  message = FormatJSON(data)
  m.sendEvent(message, "contentStartupPerformance", m.logger, m.requestQueue)
End Function


'setPlayerSetupStartTime marks the roTimeSpan or creates new roTimeSpan Object if not available
Function playerloglib_setPlayerSetupStartTime()
  if m.playerSetupTimer <> invalid
    m.playerSetupTimer.mark()
  else
    m.playerSetupTimer = CreateObject("roTimespan")
  end if
End Function


'setPlayerSetupEndTime calculates the total time taken to setup player and triggers PlayerSetupPerformance event
Function playerloglib_setPlayerSetupEndTime()
  if m.playerSetupTimer <> invalid
    m.playerSetupTime = m.playerSetupTimer.totalMilliseconds()
    m.firePlayerSetupPerformanceEvent()
  end if
End Function


'setAdBufferStartTime marks the roTimeSpan or creates new roTimeSpan Object if not available
Function playerloglib_setAdBufferStartTime()
  if m.adBufferTimer <> invalid
    m.adBufferTimer.mark()
  else
    m.adBufferTimer = CreateObject("roTimespan")
  end if
End Function


'setAdBufferEndTime calculates the buffer time of Ad and triggers AdStartupPerformance event
Function playerloglib_setAdBufferEndTime()
  if m.adBufferTimer <> invalid
    m.adBufferTime = m.adBufferTimer.totalMilliseconds()
    m.fireAdStartupPerformanceEvent()
  end if
End Function


'@adCtx: assocArray: holds ad related information (eg. adCount, adIndex, adServer, duration etc.,)
Function playerloglib_setAdCtx(adCtx = {})
  m.adCtx = {}

  if type(adCtx) = "roAssociativeArray"
    m.adCtx = adCtx
  end if
End Function


'The Ad Startup Performance event will be triggered when Ad starts.
'It helps to monitor slow start of Ads 
Function playerloglib_fireAdStartupPerformanceEvent()
  adCtx = m.adCtx

  if adCtx <> invalid AND adCtx.ad <> invalid
    ad = adCtx.ad

    url = ""
    if isArray(ad.streams) = true AND ad.streams[0] <> invalid
      if isString(ad.streams[0].url) = true
        url = ad.streams[0].url
      end if
    end if

    if adCtx.rendersequence = "preroll"
      isPreroll = true
    else
      isPreroll = false
    end if

    data = {
      track_id: m.getTrackId()
      ad_id: ad.adId
      url: url
      is_preroll: isPreroll
      ad_index: adCtx.adIndex
      ad_count: adCtx.adCount
      duration: adCtx.duration
      first_frame_time: m.adBufferTime
    }

    message = FormatJSON(data)
    m.sendEvent(message, "adStartupPerformance", m.logger, m.requestQueue)
  end if
End Function


'gets the trackId from global node, if not available then generate new trackId from roDeviceInfo
Function playerloglib_getTrackId()
  return m.globalNode.playerLogTrackId 
End Function


'resets the trackId by generating new trackId from roDeviceInfo and sets to global node
Function playerloglib_resetTrackId()
  m.globalNode.playerLogTrackId = m.deviceInfo.GetRandomUUID()
End Function
