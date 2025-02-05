' This file is used to send playerlogs. Please refer to the document below for details on all events:
' Document - https://www.notion.so/tubi/RFC-Player-Analytics-Event-v1-0-b8bee0eb69d14cc891baf8e907635f2f
' 
'@constants: assocArray, constants as set in Constants.brs
'@requestQueue: assocArray, a request queue as returned by TubiRequestQueue().create(), default as invalid 
'@logger: AA, TubiLogger returned as associative array, default as invalid 
'
Function PlayerLogLib(constants, requestQueue = invalid, logger = invalid)
  deviceInfo = CreateObject("roDeviceInfo")
  globalNode = getGlobalAA().global 'bs:disable-line 1140 LINT1001

  'We are initializing the PlayerLogLib from VideoPlayer and TubiAds, and we want to use the same trackId for a single playback session. 
  'Therefore, we are setting it as global.
  if globalNode = invalid
    return invalid
  else if globalNode.playerLogTrackId = invalid
    globalNode.update({
      playerLogTrackId: deviceInfo.GetRandomUUID()
    }, true)
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

    videoPosition: -1
    contentCount: 0
    hasErrorModalShown: false
    failedAdCount: 0
    totalAdDuration: 0

    playerPositionWhenAdsCompleted: 0
    playerStage: "IDLE"
    playerFeedback: ""

    isFromAutoplay: false

    'public methods

    'video
    setVideoControl: playerloglib_setVideoControl
    setVideoState: playerloglib_setVideoState
    setPlayerStage: playerloglib_setPlayerStage
    setVideoContent: playerloglib_setVideoContent
    setVideoPosition: playerloglib_setVideoPosition

    'player
    setPlayerLoadTime: playerloglib_setPlayerLoadTime
    setPlayerSetupStartTime: playerloglib_setPlayerSetupStartTime
    setPlayerSetupEndTime: playerloglib_setPlayerSetupEndTime
    setErrorModal: playerloglib_setErrorModal
    setPlayerFeedback: playerloglib_setPlayerFeedback
    setPlaybackSource: playerloglib_setPlaybackSource

    'ad
    setAdCtx: playerloglib_setAdCtx
    setAdState: playerloglib_setAdState
    setAdType: playerloglib_setAdType
    setAdBufferStartTime: playerloglib_setAdBufferStartTime
    setAdBufferEndTime: playerloglib_setAdBufferEndTime
    resetAdMetrics: playerloglib_resetAdMetrics

    fireCuepointFilledEvent: playerloglib_fireCuepointFilledEvent
    fireAdStartEvent: playerloglib_fireAdStartEvent
    fireAdCompleteEvent: playerloglib_fireAdCompleteEvent
    fireAdDiscontinueEvent: playerloglib_fireAdDiscontinueEvent
    fireAdPodCompleteEvent: playerloglib_fireAdPodCompleteEvent

    'private methods
    getTrackId: playerloglib_getTrackId
    resetTrackId: playerloglib_resetTrackId
    resetAdState: playerloglib_resetAdState
    resetPlayerStage: playerloglib_resetPlayerStage

    setFirstFrameForContentStart: playerloglib_setFirstFrameForContentStart
    firePlayerSetupPerformanceEvent: playerloglib_firePlayerSetupPerformanceEvent
    fireContentStartupPerformanceEvent: playerloglib_fireContentStartupPerformanceEvent
    fireAdStartupPerformanceEvent: playerloglib_fireAdStartupPerformanceEvent
    firePlayerPageExitEvent: playerloglib_firePlayerPageExitEvent
    updateSingleAdInfo: playerloglib_updateSingleAdInfo
    sendEvent: playerloglib_sendEvent

    fireContentStartEvent: playerloglib_fireContentStartEvent
    fireVideoResourceFallbackEvent: playerloglib_fireVideoResourceFallbackEvent
  }
End Function 


'@adType: String, possible values are "preroll", "seek", "midroll"
'
Function playerloglib_setAdType(adType = "preroll")
  if isNonEmptyString(adType) = true AND (adType = "preroll" OR adType = "seek" OR adType = "midroll")
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
      if m.adType = "midroll" OR m.adType = "seek"
        isPreroll = false
      else
        isPreroll = true
        m.contentCount += 1 'increment the contentCount for every new title starts
      end if
      ' Triggers the ContentStartupPerformance & ContentStart after each AdPod - preroll & midroll
      m.fireContentStartupPerformanceEvent(isPreroll, true)
      m.fireContentStartEvent(isPreroll, true)
      m.resetAdState()
    else
      if m.isVideoPlayed = false
        'Triggers the ContentStartupPerformance & ContentStart when playback begins without an ad having been played beforehand.
        m.setPlayerStage("EARLY_START")
        m.contentCount += 1 'increment the contentCount for every new title starts
        m.fireContentStartupPerformanceEvent(false, false)
        m.fireContentStartEvent(false, false)
      end if  
    end if
    m.isVideoPlayed = true
  else if m.videoState = "finished"
    m.isVideoPlayed = false 'reset isVideoPlayed for every new playback session
  end if

End Function


'setPlayerStage sets value to m.playerStage and updates playerPositionWhenAdsCompleted when m.adState is adsCompleted
'
'@playerStage: String, possible values are IDLE, READY, BEFORE_PREROLL, PREROLL, AFTER_PREROLL, EARLY_START, IN_STREAM, BEFORE_MIDROLL, MIDROLL, AFTER_MIDROLL, DRM_FALLBACK, NONE. Default is IDLE
'
Function playerloglib_setPlayerStage(playerStage = "IDLE")
  if isNonEmptyString(playerStage) = true
    m.playerStage = playerStage
  end if
End Function


'setAdState updates the adState and playerStage. It also updates the value of playerPositionWhenAdsCompleted with videoposition
'
'@adState: String, possible values are "ready", "init", "fetching", "adsPending", "adsPlaying", "adsClosed", "noAds", "adsCompleted"
'
Function playerloglib_setAdState(adState = "")
  if isNonEmptyString(adState) = true
    m.adState = adState
  else
    m.adState = ""
  end if

  if m.adState = "adsPending"
    if m.adType = "preroll"  
      m.setPlayerStage("BEFORE_PREROLL")
    else
      m.setPlayerStage("BEFORE_MIDROLL") 
    end if
  else if m.adState = "adsPlaying"
    if m.adType = "preroll"  
      m.setPlayerStage("PREROLL")
    else
      m.setPlayerStage("MIDROLL") 
    end if
  else if m.adState = "adsCompleted"

    playerPosition = m.videoPosition
    if playerPosition = -1
      m.playerPositionWhenAdsCompleted = 0
    else
      m.playerPositionWhenAdsCompleted = playerPosition
    end if

    if m.adType = "preroll"  
      m.setPlayerStage("AFTER_PREROLL")
    else
      m.setPlayerStage("AFTER_MIDROLL") 
    end if
  end if

  if m.adState = "init" OR m.adState = "noAds" OR m.adState = "adsCompleted"
    m.setFirstFrameForContentStart()
  end if
End Function


' resets the m.adState to empty string
Function playerloglib_resetAdState()
  m.adState = ""
End Function


' resets the m.playerStage to default which is "IDLE" string
Function playerloglib_resetPlayerStage()
  m.playerStage = "IDLE"
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
  if isNumber(playerPosition) = true AND isNumber(m.playerPositionWhenAdsCompleted) = true
    m.videoPosition = playerPosition

    'After 60 seconds to playback, the playerStage is considered as IN_STREAM
    if m.playerStage <> "IN_STREAM" AND isNumber(m.playerPositionWhenAdsCompleted) = true AND (playerPosition - m.playerPositionWhenAdsCompleted) >= 60
      m.setPlayerStage("IN_STREAM")
    end if

  else
    m.videoPosition = -1
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
  playerPosition = m.videoPosition

  if playerPosition > -1
    startPosition = playerPosition
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


'setErrorModal helps to identify whether any error modal is displayed while exiting the player 
Function playerloglib_setErrorModal(hasErrorModalShown = false)
  if isBoolean(hasErrorModalShown) = true
    m.hasErrorModalShown = hasErrorModalShown
  end if
End Function


'setPlaybackSource sets the value for isFromAutoplay which helps to identify whether video playing through autoplay or not
Function playerloglib_setPlaybackSource(playbackSource = {})
  m.isFromAutoplay = false

  if isAA(playbackSource) = true
    srcForAds = playbackSource.srcForAds

    if srcForAds = "ap_select" OR srcForAds = "ap_auto"
      m.isFromAutoplay = true
    end if
  end if
End Function


'setPlayerFeedback helps to identify whether user has sent any player feedback
'
'@playerFeedback: string, the user selected feedback from player overlay
Function playerloglib_setPlayerFeedback(playerFeedback)
  if isNonEmptyString(playerFeedback) = true
    m.playerFeedback = playerFeedback
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


'The fireCuepointFilledEvent event will be triggered when player receives rainmaker response with ads.
'
'@cuepointInfo: assocarray, contains  ad_count, cuepoint
Function playerloglib_fireCuepointFilledEvent(cuepointInfo)
  if isAA(cuepointInfo) = true
    cuepointInfo["track_id"] = m.getTrackId()
    message = FormatJSON(cuepointInfo)
    m.sendEvent(message, "cuePointFilled", m.logger, m.requestQueue)
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


'The PlayerPageExit Event will be triggered when user exits/close the player.
'
'@playerExitInfo: assocarray, contains ad_counts, is_ad, is_buffering
Function playerloglib_firePlayerPageExitEvent(playerExitInfo)
  if isAA(playerExitInfo) = true
    playerExitInfo["track_id"] = m.getTrackId()
    playerExitInfo["has_error_modal"] = m.hasErrorModalShown
    playerExitInfo["content_counts"] = m.contentCount
    playerExitInfo["stage"] = m.playerStage
  
    if isNonEmptyString(m.playerFeedback) = true
      playerExitInfo["feedback"] = m.playerFeedback
    end if
  
    message = FormatJSON(playerExitInfo)
    m.sendEvent(message, "playerPageExit", m.logger, m.requestQueue)
  end if

  m.hasErrorModalShown = false
  m.contentCount = 0
  m.playerFeedback = ""
  m.resetAdMetrics()
  m.resetPlayerStage()
  m.resetTrackId() 'resets trackId once playback session ends, so that next time it uses new trackId
End Function


' The Content Start event will be triggered when playback starts or resumes after pre-roll and midroll ads, as well as in cases with no pre-roll.
' It will collect content information for the startup including details such as start_position, video information etc
' Note: It will not be triggered after regular buffering events.
'
' @isFromPreroll: boolean, tells whether the content started after pre-roll
' @isAfterAd: boolean, tells whether the content started after any ad
'
Function playerloglib_fireContentStartEvent(isFromPreroll, isAfterAd)
  startPosition = -1 'default
  playerPosition = m.videoPosition

  if playerPosition > -1
    startPosition = playerPosition
  else if isNode(m.content) = true and isNumber(m.content.nowPos) = true
    startPosition = m.content.nowPos
  end if

  data = {
    track_id: m.getTrackId()
    video_id: m.videoId
    video_resource_type: m.videoResourceType
    video_codec_type: m.videoCodecType
    start_position: startPosition
    is_after_ad: isAfterAd
    is_from_preroll: isFromPreroll
    is_from_autoplay: m.isFromAutoplay
  }

  message = FormatJSON(data)
  m.sendEvent(message, "contentStart", m.logger, m.requestQueue)
End Function


'fireVideoResourceFallbackEvent will be fired when player decides to fallback
'
'resourceInfo: assocarray, contains failedType(possible values are CODEC/DRM), currentResource(failed) & nextResource(fallback) which is needed for sending event
Function playerloglib_fireVideoResourceFallbackEvent(resourceInfo)
  if isAA(resourceInfo) = true
    resourceInfo["track_id"] = m.getTrackId()
    resourceInfo["video_id"] = m.videoId
    message = FormatJSON(resourceInfo)
    m.sendEvent(message, "fallback", m.logger, m.requestQueue)
  end if
End Function


'The Ad Startup Performance event will be triggered when Ad starts.
'It helps to monitor slow start of Ads 
Function playerloglib_fireAdStartupPerformanceEvent()
  adCtx = m.adCtx
  adStartupPerformanceInfo = {}

  if adCtx <> invalid AND adCtx.ad <> invalid
    m.updateSingleAdInfo(adStartupPerformanceInfo, adCtx)
    adStartupPerformanceInfo["first_frame_time"] = m.adBufferTime
    message = FormatJSON(adStartupPerformanceInfo)
    m.sendEvent(message, "adStartupPerformance", m.logger, m.requestQueue)
  end if
End Function


'The Ad Start event will be triggered when Ad starts.
'
'@adStartInfo: assocarray, contains video_id
Function playerloglib_fireAdStartEvent(adStartInfo = {})
  adCtx = m.adCtx

  if adCtx <> invalid AND adCtx.ad <> invalid
    m.updateSingleAdInfo(adStartInfo, adCtx)
    message = FormatJSON(adStartInfo)
    m.sendEvent(message, "adStart", m.logger, m.requestQueue)
  end if
End Function


'The Ad Complete event will be triggered when Ad ends.
'
'@adCompleteInfo: assocarray, contains video_id
Function playerloglib_fireAdCompleteEvent(adCompleteInfo = {})
  adCtx = m.adCtx

  if adCtx <> invalid AND adCtx.ad <> invalid
    m.totalAdDuration += adCtx.duration
    m.updateSingleAdInfo(adCompleteInfo, adCtx)
    message = FormatJSON(adCompleteInfo)
    m.sendEvent(message, "adComplete", m.logger, m.requestQueue)
  end if
End Function


'The Ad Discontinue event will be triggered when Ad Error/Ad Stall.
'
'@adDiscontinueInfo: assocarray, contains video_id
Function playerloglib_fireAdDiscontinueEvent(adDiscontinueInfo = {})
  adCtx = m.adCtx
  m.failedAdCount += 1

  if adCtx <> invalid AND adCtx.ad <> invalid
    m.totalAdDuration += adCtx.duration
    m.updateSingleAdInfo(adDiscontinueInfo, adCtx)
    
    adPosition = 0
    if adCtx.time <> invalid
      adPosition = adCtx.time
    end if
    adDiscontinueInfo["ad_position"] = adPosition
    adDiscontinueInfo["reason"] = "error"

    message = FormatJSON(adDiscontinueInfo)
    m.sendEvent(message, "adDiscontinue", m.logger, m.requestQueue)
  end if
End Function


'The Ad Pod complete event will be triggered when all Ads in ad pod are finished
'
'@adPodCompleteInfo: assocarray, contains video_id
Function playerloglib_fireAdPodCompleteEvent(adPodCompleteInfo = {})
  adCtx = m.adCtx

  if adCtx <> invalid
    isPreroll = (adCtx.rendersequence = "preroll")
    adCount = adCtx.adCount

    adPodCompleteInfo["track_id"] = m.getTrackId()
    adPodCompleteInfo["ad_count"] = adCount
    adPodCompleteInfo["successful_count"] = adCount - m.failedAdCount
    adPodCompleteInfo["failed_count"] = m.failedAdCount
    adPodCompleteInfo["is_preroll"] = isPreroll
    adPodCompleteInfo["total_ads_duration"] = m.totalAdDuration

    message = FormatJSON(adPodCompleteInfo)
    m.sendEvent(message, "adPodComplete", m.logger, m.requestQueue)
  end if
End Function


'The updateSingleAdInfo will set the values for when Ad Start/Ad Ends/Ad Error/Ad Stall events.
'
'@adInfo: assocarray, contains video_id
'@adCtx: assocarray, contains ad related information
'
Function playerloglib_updateSingleAdInfo(adInfo = {}, adCtx = {})
  if isAA(adInfo) = true AND isAA(adCtx) = true
    ad = adCtx.ad
    isPreroll = (adCtx.rendersequence = "preroll")
    adId = ""
    url = ""

    if ad <> invalid
      adId = ad.adid
      if isNonEmptyArray(ad.streams) = true AND isNonEmptyString(ad.streams[0].url) = true
        url = ad.streams[0].url
      end if
    end if

    adInfo["track_id"] = m.getTrackId()
    adInfo["ad_id"] = adId
    adInfo["url"] = url
    adInfo["is_preroll"] = isPreroll
    adInfo["ad_index"] = adCtx.adIndex - 1
    adInfo["ad_count"] = adCtx.adCount
    adInfo["duration"] = adCtx.duration
    return adInfo
  else
    return {}
  end if
End Function


'resets the AdMetrics
Function playerloglib_resetAdMetrics()
  m.failedAdCount = 0
  m.totalAdDuration = 0
End Function
