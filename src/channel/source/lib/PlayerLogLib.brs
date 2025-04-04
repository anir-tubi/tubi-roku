' This file is used to send playerlogs. Please refer to the document below for details on all events:
' Document - https://www.notion.so/tubi/RFC-Player-Analytics-Event-v1-0-b8bee0eb69d14cc891baf8e907635f2f
' 
'@constants: assocArray, constants as set in Constants.brs
'@tracking: assocArray, a request queue as returned by TubiRequestQueue().create(), default as invalid 
'
Function PlayerLogLib(constants, tracking)
  deviceInfo = CreateObject("roDeviceInfo")

  return {
    constants: constants
    tracking: tracking
    deviceInfo: deviceInfo
    playerLogTrackId: deviceInfo.GetRandomUUID() 'unique TrackId used in all events
    trackingLoggingTask: getGlobalAA().global.trackingLoggingTask

    '//player fields
    playerLoadTime: -1 'used in playerSetupPerformance event
    playerSetupTime: -1 'used in playerSetupPerformance event
    hasErrorModalShown: false 'used in playerPageExit event
    playerPositionWhenAdsCompleted: 0 'used to set the playerStage basd on position of the video
    playerStage: "IDLE" 'used in playerPageExit event
    playerFeedback: "" 'used in playerPageExit event
    lastStartStep: "UNKNOWN" 'used in qualityOfService event

    streamBitrate: 0 'the current bitrate being used for streaming, used in userFeedback event
    measuredBitrate: 0 'actual bitrate that is being measured at the network level, used in userFeedback

    singleSeekThreshold: 3600000 'threshold of single seek duration in milliseconds 
    singleBufferingThreshold: 3600000 'threshold of single buffering duration in milliseconds 

    '//video fields
    content: invalid 'node which hols the content information, used in various events
    
    'The contentStartPerformance event should be triggered in the following situations: when the content starts or resumes playback, and after each AdPod. 
    'The variable m.isVideoPlayed helps determine when to trigger this event. 
    'If isVideoPlayed is set to false, it indicates that the contentStartPerformance event has not been fired during the current playback session. 
    'If isVideoPlayed is true, it means the event has already been triggered for this session.
    isVideoPlayed: false

    isTrailer: false 'No player logs are sent for trailer
    isSeeking: false 'used in userFeedback event
    videoState: "" 'various events are fired based on videoState
    videoId: "" 'used used in various events
    videoCodecType: "" 'used in various events, possible values are H264, H265
    videoResolution: "" 'used in ContentStartupPerformance event, possible values are 2160, 1080, 720
    videoResourceType: "" 'used in various events, possible values are dash_widevine_psshv0, dash_playready_psshv0, dash, hlsv6, hlsv3
    hdcpVersion: "" 'used in qualityOfService event
    cdn: "" 'used in qualityOfService event
    videoPosition: -1 'used in various calculations and events like contentStartupPerformance
    contentCount: 0 'used in playerPageExit event
    isFromAutoplay: false 'used in contentStart event
    contentFirstFrameDuration: -1 'used in qualityOfService event
    resumeCount: 0 'used in qualityOfService event
    errorCode: 0 'used in qualityOfService event
    firstErrorCode: 0 'used in qualityOfService event
    breakOffCount: 0 'used in qualityOfService event
    videoBufferingCount: 0 'used in qualityOfService event
    totalBufferingDuration: 0 'used in qualityOfService event
    isTotalBufferingDurationExceededLimit: false 'limit is 3600000ms(singleBufferingThreshold), used in qualityOfService event
    seekCount: 0 'used in qualityOfService event
    totalSeekDuration: 0 'used in qualityOfService event
    isSeekExceededLimit: false 'limit is 3600000ms(singleSeekThreshold), used in qualityOfService event
    totalViewTime: 0 'used in qualityOfService event
    totalContentResumeFirstFrameDuration: 0 'used in qualityOfService event
    totalSegSize: 0 'used in qualityOfService event
    totalDownloadDuration: 0 'used in qualityOfService event
    totalSegDuration: 0 'used in qualityOfService event
    isAutoResolution: false 'used in qualityOfService event  
    duration: 0 'used in userFeedback event
    captions: [] 'used in find the index of selected caption for userFeedback event
    captionsIndex: 0 'used in userFeedback event
    isContinueWatching: false 'used in userFeedback event
    errorCodeList: [] 'used in userFeedback event

    '//ad fields
    adBufferTime: -1 'used in adStartupPerformance event

    'The m.adState will update automatically with any changes in the VideoPlayer's ad state. The possible values include: "ready," "init," "fetching," "adsPending," "adsPlaying," "adsClosed," "noAds," and "adsCompleted."
    'Additionally, m.adState will reset to an empty string "" immediately after the combination of "adsCompleted" state and the ContentStartup performance event.
    'This variable is only meant for Content playback events.
    adState: ""

    adType: "preroll" 'Possible values are preroll, midroll, seek. It helps to set playerStage etc
    isAd: false 'used in qualityOfService event
    totalAdDurationPerTitle: 0 'used in adPodComplete event
    failedAdCountPerTitle: 0 'used in adPodComplete event
    adStartupFailureCount: 0 'used in qualityOfService event
    adReBuffer: 0 'used in qualityOfService event
    totalAdFirstFrameDuration: 0 'used in qualityOfService event
    adStartupFailureCount: 0 'used in qualityOfService event
    failedAdCount: 0 'used in qualityOfService event
    adCount: 0 'used in qualityOfService event
    latestAdPodStartupResult: {} 'used in userFeedback event

    '//timers
    playerSetupTimer: CreateObject("roTimespan") 'helps to calculate playerSetupTime for playerSetupPerformance event
    adBufferTimer: CreateObject("roTimespan") 'helps to calculate adBufferTime for adStartupPerformance event
    videoBufferingTimer: invalid 'used to calculate bufferingTime, helps for qualityOfService event. This needs be initialized only when mid-buffering starts
    firstFrameTimerForContentStart: CreateObject("roTimeSpan") 'used to calculate contentFirstFrameDuration
    firstFrameTimerForContentStartAfterMidroll: CreateObject("roTimeSpan") 'used to calculate totalContentResumeFirstFrameDuration
    seekingTimer: CreateObject("roTimespan") 'helps to calculate seeking duration for userFeedback event

    '//public methods

    'video
    setVideoControl: playerLogLib_setVideoControl
    setVideoState: playerLogLib_setVideoState
    setVideoContent: playerLogLib_setVideoContent
    setVideoPosition: playerLogLib_setVideoPosition
    setErrorCode: playerLogLib_setErrorCode
    setBreakOffError: playerLogLib_setBreakOffError
    setVideoBufferingStartTime: playerLogLib_setVideoBufferingStartTime
    setVideoBufferingEndTime: playerLogLib_setVideoBufferingEndTime
    setSeekEndPosition: playerLogLib_setSeekEndPosition
    setDownloadedSegmentData: playerLogLib_setDownloadedSegmentData
    setIsSeeking: playerLogLib_setIsSeeking

    'player
    setPlayerInitialization: playerLogLib_setPlayerInitialization
    setPlayerStage: playerLogLib_setPlayerStage
    setPlayerSetupEndTime: playerLogLib_setPlayerSetupEndTime
    setErrorModal: playerLogLib_setErrorModal
    setPlayerFeedback: playerLogLib_setPlayerFeedback
    setPlaybackSource: playerLogLib_setPlaybackSource
    setLastStartStep: playerLogLib_setLastStartStep
    setStreamInfo: playerLogLib_setStreamInfo
    setUserFeedback: playerLogLib_setUserFeedback
    setCaptions: playerLogLib_setCaptions
    getCaptionsList: playerLogLib_getCaptionsList
    updateCaptionIndex: playerLogLib_updateCaptionIndex

    'ad
    setIsAd: playerLogLib_setIsAd
    setAdState: playerLogLib_setAdState
    setAdType: playerLogLib_setAdType
    setAdBufferStartTime: playerLogLib_setAdBufferStartTime
    resetAdMetrics: playerLogLib_resetAdMetrics
    incrementAdReBuffer: playerLogLib_incrementAdReBuffer
    setAdCount: playerLogLib_setAdCount
    setAdStartupFailureCount: playerLogLib_setAdStartupFailureCount
    setAdPodStartupResult: playerLogLib_setAdPodStartupResult

    'public functions which fire events
    fireCuepointFilledEvent: playerLogLib_fireCuepointFilledEvent
    fireAdStartEvent: playerLogLib_fireAdStartEvent
    fireAdCompleteEvent: playerLogLib_fireAdCompleteEvent
    fireAdDiscontinueEvent: playerLogLib_fireAdDiscontinueEvent
    fireAdPodCompleteEvent: playerLogLib_fireAdPodCompleteEvent
    fireQualityOfServiceEvent: playerLogLib_fireQualityOfServiceEvent
    firePlayerPageExitEvent: playerLogLib_firePlayerPageExitEvent
    fireAdStartupPerformanceEvent: playerLogLib_fireAdStartupPerformanceEvent
    fireAdMissedEvent: playerLogLib_fireAdMissedEvent
    setAdPodStart: playerLogLib_setAdPodStart

    '//private methods

    setPlayerSetupStartTime: playerLogLib_setPlayerSetupStartTime
    setPlayerLoadTime: playerLogLib_setPlayerLoadTime
    setFirstFrameForContentStart: playerLogLib_setFirstFrameForContentStart
    setFirstFrameForContentStartAfterMidRoll: playerLogLib_setFirstFrameForContentStartAfterMidRoll
    updateSingleAdInfo: playerLogLib_updateSingleAdInfo

    'private functions which fire events
    firePlayerSetupPerformanceEvent: playerLogLib_firePlayerSetupPerformanceEvent
    fireContentStartupPerformanceEvent: playerLogLib_fireContentStartupPerformanceEvent
    fireContentStartEvent: playerLogLib_fireContentStartEvent
    fireVideoResourceFallbackEvent: playerLogLib_fireVideoResourceFallbackEvent

    'reset
    resetAdState: playerLogLib_resetAdState
    resetQoSAttributes: playerLogLib_resetQoSAttributes
    resetTrackId: playerLogLib_resetTrackId

    sendEvent: playerLogLib_sendEvent
  }
End Function 


'@adType: String, possible values are "preroll", "seek", "midroll"
'
Function playerLogLib_setAdType(adType = "preroll")
  if isNonEmptyString(adType) = true AND (adType = "preroll" OR adType = "seek" OR adType = "midroll")
    m.adType = adType
  else
    m.adType = "preroll"
  end if
End Function


'@videoState: String, possible values are "buffering", "playing", "paused", "stopping", "stopped", "finished", "error", "none"
'
Function playerLogLib_setVideoState(videoState = "")
  if isNonEmptyString(videoState) = true
    m.videoState = videoState
  else
    m.videoState = ""
  end if

  if m.videoState = "buffering"

    if m.isVideoPlayed = true
      m.videoBufferingTimer = CreateObject("roTimespan")
      m.videoBufferingTimer.mark()
    end if
  else if m.videoState = "playing"

    if m.isVideoPlayed = true AND m.videoBufferingTimer <> invalid
      videoBufferingDuration = m.videoBufferingTimer.totalMilliseconds()
      m.setVideoBufferingEndTime(videoBufferingDuration)
      m.videoBufferingTimer = invalid
    end if

    if m.adState = "adsCompleted"
      if m.adType = "midroll" OR m.adType = "seek"
        isPreroll = false
        m.resumeCount += 1
        m.totalContentResumeFirstFrameDuration += m.firstFrameTimerForContentStartAfterMidroll.totalMilliseconds()
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
        m.setLastStartStep("VIEWED_FIRST_FRAME")
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
Function playerLogLib_setPlayerStage(playerStage = "IDLE")
  if isNonEmptyString(playerStage) = true
    m.playerStage = playerStage
  end if
End Function


'setAdState updates the adState and playerStage. It also updates the value of playerPositionWhenAdsCompleted with videoposition
'
'@adState: String, possible values are "ready", "init", "fetching", "adsPending", "adsPlaying", "adsClosed", "noAds", "adsCompleted"
'
Function playerLogLib_setAdState(adState = "")
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
      m.setFirstFrameForContentStartAfterMidroll()
    end if
  end if

  if m.adState = "init" OR m.adState = "noAds" OR m.adState = "adsCompleted"
    m.setFirstFrameForContentStart()
  end if
End Function


' resets the m.adState to empty string
Function playerLogLib_resetAdState()
  m.adState = ""
End Function


'setFirstFrameForContentStart marks the roTimeSpan
Function playerLogLib_setFirstFrameForContentStart()
  m.firstFrameTimerForContentStart.mark()
End Function


'setFirstFrameForContentStartAfterMidroll marks the roTimeSpan, which helps to calculate the duration of FirstFrameForContentStartAfterMidroll
Function playerLogLib_setFirstFrameForContentStartAfterMidroll()
  m.firstFrameTimerForContentStartAfterMidroll.mark()
End Function


'@videoControl: String, possible values are "play", "stop", "pause", "resume", "replay", "prebuffer", "skipcontent", "none" 
'
Function playerLogLib_setVideoControl(videoControl = "")
  if isNonEmptyString(videoControl) = true
    if videoControl = "play"
      m.isVideoPlayed = false 'reset isVideoPlayed for every new playback session
    end if
  end if
End Function


'@content: roSGNode, a TubiContentNode holds the video related information
'
Function playerLogLib_setVideoContent(content = invalid)
  if type(content) = "roSGNode"
    m.content = content
    m.videoId = m.content.id

    if isNonEmptyString(m.content.codec) = true
      codec = UCase(m.content.codec)
      m.videoCodecType = m.constants.player.videoCodecType[codec]
    else
      m.videoCodecType = m.constants.player.videoCodecType["UNKNOWN"]
    end if

    if isNonEmptyString(m.content.resolution) = true
      resolution = UCase(m.content.resolution)
      m.videoResolution = m.constants.player.videoResolution[resolution]
    else
      m.videoResolution = m.constants.player.videoResolution["UNKNOWN"]
    end if

    if isNonEmptyString(m.content.drmType) = true
      drmType = UCase(m.content.drmType)
      m.videoResourceType = m.constants.player.videoResourceType[drmType]
    else
      m.videoResourceType = m.constants.player.videoResourceType["UNKNOWN"]
    end if

    if isNonEmptyString(m.content.hdcpVersion) = true
      hdcpVersion = UCase(m.content.hdcpVersion)
      m.hdcpVersion = m.constants.player.hdcpVersion[hdcpVersion]
    else
      m.hdcpVersion = m.constants.player.hdcpVersion["UNKNOWN"]
    end if

    if isBoolean(m.content.isTrailer) = true
      m.isTrailer = m.content.isTrailer
    else
      m.isTrailer = true
    end if

    m.isContinueWatching = (m.content.nowPos > 0)
    m.duration = m.content.length
    url = m.content.url
    m.cdn = ""

    if isNonEmptyString(url) = true
      if url.InStr("fastly") > 0
        m.cdn = "fastly"
      else if url.InStr("cloudfront") > 0
        m.cdn = "cloudfront"
      else if url.InStr("akamai") > 0
        m.cdn = "akamai"
      end if
    end if
  else
    m.content = invalid
    m.videoId = ""
    m.videoCodecType = ""
    m.videoResolution = ""
    m.videoResourceType = ""
    m.hdcpVersion = ""
    m.cdn = ""
    m.isContinueWatching = false
    m.duration = 0
    m.isTrailer = true
  end if
End Function


'setVideoPosition updates the playerPosition to m variable
'@playerPosition: integer, position of the playback
'
Function playerLogLib_setVideoPosition(playerPosition = -1)
  if isNumber(playerPosition) = true AND isNumber(m.playerPositionWhenAdsCompleted) = true
    m.videoPosition = playerPosition
    m.totalViewTime += 1

    'After 60 seconds to playback, the playerStage is set as IN_STREAM. the lastStartStep is set as PLAY_STARTED
    if playerPosition - m.playerPositionWhenAdsCompleted >= 60
      if m.playerStage <> "IN_STREAM"
        m.setPlayerStage("IN_STREAM")
      end if

      if m.lastStartStep <> "PLAY_STARTED"
        m.setLastStartStep("PLAY_STARTED")
      end if
    end if

  else
    m.videoPosition = -1
  end if
End Function


'setPlayerInitialization resets TrackId, updates playerStage, playerFeedback, playerLoadTime, playerSetupStartTime
'
Function playerLogLib_setPlayerInitialization(playerLoadTime = -1)
  m.resetTrackId()
  m.setPlayerStage("IDLE")
  m.setPlayerFeedback("")
  m.setPlayerLoadTime(playerLoadTime)
  m.setPlayerSetupStartTime()
End Function


'setPlayerLoadTime updates the playerLoadTime to m variable
'@playerLoadTime: integer, load time of the player
'
Function playerLogLib_setPlayerLoadTime(playerLoadTime = -1)
  if isNumber(playerLoadTime) = true
    m.playerLoadTime = playerLoadTime
  else
    m.playerLoadTime = -1
  end if
End Function


' Player Setup Performance event will be triggered once player is configured, 
' It will calculate the duration cost from the user pressing play/resume button to player setup
'
Function playerLogLib_firePlayerSetupPerformanceEvent()
  eventBase = {
    track_id: ""
    video_id: ""
    page_loaded_time: ""
    player_setup_time: ""
  }

  data = {
    track_id: m.playerLogTrackId
    video_id: m.videoId
    page_loaded_time: m.playerLoadTime
    player_setup_time: m.playerSetupTime
  }
  m.sendEvent(data, "player_setup_performance", eventBase)

  m.playerLoadTime = -1
  m.playerSetupTime = -1
End Function


' playerLogLib_sendEvent helps to send the event to backend through trackingLoggingTask
'
'@data: assocarray, the payload that needs to be sent
'@subType: String, it is eventType
'@eventbase: assocArray, a list of fields for each message as defined in this file (which should match the protos specs on the server)
Function playerLogLib_sendEvent(data = {} as Dynamic, subType = "" as String, eventBase = {})
  'Do not send player events for trailers
  if m.isTrailer = false
    eventInfo = m.tracking.populateMessage(subType, data, eventBase)

    if eventInfo <> invalid
      eventValues =  eventInfo[subType]

      if isAA(eventValues) = true
        trackData = m.tracking.getPlayerAnalyticsEvent(subType, eventValues)
    
        if m.trackingLoggingTask = invalid then
          m.trackingLoggingTask = getGlobalAA().global.trackingLoggingTask
        end if
    
        if m.trackingLoggingTask <> invalid then
          m.trackingLoggingTask.trackPlayerEvent = trackData
        end if
      end if
    end if
  end if
End Function


' The Content Startup Performance event will be triggered when playback starts or resumes after pre-roll and midroll ads, as well as in cases with no pre-roll.
' It will collect performance information for the startup including details such as manifest, playlist, loadtime etc
' Note: It will not be triggered after regular buffering events.
'
' @isFromPreroll: boolean, tells whether the content started after pre-roll
' @isAfterAd: boolean, tells whether the content started after any ad
'
Function playerLogLib_fireContentStartupPerformanceEvent(isFromPreroll, isAfterAd)
  firstFrameTime = m.firstFrameTimerForContentStart.totalMilliseconds()

  'contentFirstFrameDuration will be set only once per playback session
  if m.contentFirstFrameDuration = -1
    m.contentFirstFrameDuration = firstFrameTime
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

  eventBase = {
    track_id: ""
    video_id: ""
    video_resource_type: ""
    video_codec_type: ""
    current_video_resolution: ""
    start_position: ""
    is_after_ad: ""
    is_from_preroll: ""
    first_frame_time: ""
  }

  data = {
    track_id: m.playerLogTrackId
    video_id: m.videoId
    video_resource_type: m.videoResourceType
    video_codec_type: m.videoCodecType
    current_video_resolution: m.videoResolution
    start_position: startPosition
    is_after_ad: isAfterAd
    is_from_preroll: isFromPreroll
    first_frame_time: firstFrameTime
  }

  m.sendEvent(data, "content_startup_performance", eventBase)
End Function


'setPlayerSetupStartTime marks the roTimeSpan
Function playerLogLib_setPlayerSetupStartTime()
  m.playerSetupTimer.mark()
End Function


'setPlayerSetupEndTime calculates the total time taken to setup player and triggers PlayerSetupPerformance event
Function playerLogLib_setPlayerSetupEndTime()
  m.playerSetupTime = m.playerSetupTimer.totalMilliseconds()
  m.firePlayerSetupPerformanceEvent()
End Function


'setErrorModal helps to identify whether any error modal is displayed while exiting the player 
Function playerLogLib_setErrorModal(hasErrorModalShown = false)
  if isBoolean(hasErrorModalShown) = true
    m.hasErrorModalShown = hasErrorModalShown
  end if
End Function


'setPlaybackSource sets the value for isFromAutoplay which helps to identify whether video playing through autoplay or not
Function playerLogLib_setPlaybackSource(playbackSource = {})
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
'@playerFeedback: string, the user selected feedback from player overlay, default is empty
Function playerLogLib_setPlayerFeedback(playerFeedback = "")
  if isString(playerFeedback) = true
    m.playerFeedback = playerFeedback
  end if
End Function


'setAdBufferStartTime marks the roTimeSpan
Function playerLogLib_setAdBufferStartTime()
  m.adBufferTimer.mark()
End Function


'The fireCuepointFilledEvent event will be triggered when player receives rainmaker response with ads.
'
'@cuepointInfo: assocarray, contains  ad_count, cuepoint
Function playerLogLib_fireCuepointFilledEvent(cuepointInfo)
  eventBase = {
    track_id: ""
    video_id: ""
    position: ""
    request_position: ""
    position_deviation: ""
    cue_point: ""
    ad_response_time: ""
    is_preroll: ""
    ad_count: ""
    message: ""
  }

  if isAA(cuepointInfo) = true
    cuepointInfo["track_id"] = m.playerLogTrackId
    cuepointInfo["video_id"] = m.videoId
    m.sendEvent(cuepointInfo, "cue_point_filled", eventBase)
  end if
End Function


'resets the trackId by generating new trackId from roDeviceInfo and sets to m scope
Function playerLogLib_resetTrackId()
  m.playerLogTrackId = m.deviceInfo.GetRandomUUID()
End Function


'The PlayerPageExit Event will be triggered when user exits/close the player.
'
'@playerExitInfo: assocarray, contains ad_counts, is_ad, is_buffering
Function playerLogLib_firePlayerPageExitEvent(playerExitInfo)
  eventBase = {
    track_id: ""
    feedback: ""
    has_error_modal: ""
    content_counts: ""
    ad_counts: ""
    is_ad: ""
    is_buffering: ""
    stage: ""
    cause: ""
    doubts: ""
    content_duration: ""
    current_position: ""
    message: ""
  }

  if isAA(playerExitInfo) = true
    playerExitInfo["track_id"] = m.playerLogTrackId
    playerExitInfo["has_error_modal"] = m.hasErrorModalShown
    playerExitInfo["content_counts"] = m.contentCount
    playerExitInfo["stage"] = m.playerStage
  
    if isNonEmptyString(m.playerFeedback) = true
      playerExitInfo["feedback"] = m.playerFeedback
    end if
  
    m.sendEvent(playerExitInfo, "player_page_exit", eventBase)
  end if

  m.hasErrorModalShown = false
  m.contentCount = 0
  m.playerStage = "IDLE"
  m.playerFeedback = ""
End Function


' The Content Start event will be triggered when playback starts or resumes after pre-roll and midroll ads, as well as in cases with no pre-roll.
' It will collect content information for the startup including details such as start_position, video information etc
' Note: It will not be triggered after regular buffering events.
'
' @isFromPreroll: boolean, tells whether the content started after pre-roll
' @isAfterAd: boolean, tells whether the content started after any ad
'
Function playerLogLib_fireContentStartEvent(isFromPreroll, isAfterAd)
  startPosition = -1 'default
  playerPosition = m.videoPosition

  if playerPosition > -1
    startPosition = playerPosition
  else if isNode(m.content) = true and isNumber(m.content.nowPos) = true
    startPosition = m.content.nowPos
  end if

  eventBase = {
    track_id: ""
    video_id: ""
    video_resource_type: ""
    video_codec_type: ""
    start_position: ""
    is_after_ad: ""
    is_from_preroll: ""
    is_from_autoplay: ""
  }

  data = {
    track_id: m.playerLogTrackId
    video_id: m.videoId
    video_resource_type: m.videoResourceType
    video_codec_type: m.videoCodecType
    start_position: startPosition
    is_after_ad: isAfterAd
    is_from_preroll: isFromPreroll
    is_from_autoplay: m.isFromAutoplay
  }

  m.sendEvent(data, "content_start", eventBase)
End Function


'fireVideoResourceFallbackEvent will be fired when player decides to fallback
'
'resourceInfo: assocarray, contains failedType(possible values are CODEC/DRM), currentResource(failed) & nextResource(fallback) which is needed for sending event
Function playerLogLib_fireVideoResourceFallbackEvent(resourceInfo)
  eventBase = {
    track_id: ""
    video_id: ""
    type: ""
    failed_video_resource_type: ""
    failed_video_codec_type: ""
    failed_hdcp_version: ""
    failed_max_video_resolution: ""
    failed_url: ""
    fallback_video_resource_type: ""
    fallback_video_codec_type: ""
    fallback_hdcp_version: ""
    fallback_max_video_resolution: ""
    fallback_url: ""
    message: ""
  }

  if isAA(resourceInfo) = true
    resourceInfo["track_id"] = m.playerLogTrackId
    resourceInfo["video_id"] = m.videoId
    m.sendEvent(resourceInfo, "fallback", eventBase)
  end if
End Function


'The Ad Startup Performance event will be triggered when Ad starts.
'It helps to monitor slow start of Ads 
'
'@adCtx: assocArray: holds ad related information (eg. adCount, adIndex, adServer, duration etc.,)
Function playerLogLib_fireAdStartupPerformanceEvent(adCtx = {})
  eventBase = {
    track_id: ""
    ad_id: ""
    url: ""
    is_preroll: ""
    ad_index: ""
    ad_count: ""
    duration: ""
    first_frame_time: ""
    frag_loaded_time: ""
    variant_loaded_time: ""
    manifest_loaded_time: ""
    preloaded: ""
    message: ""
  }

  if adCtx <> invalid AND adCtx.ad <> invalid
    m.adBufferTime = m.adBufferTimer.totalMilliseconds()
    adStartupPerformanceInfo = m.updateSingleAdInfo(adCtx)
    m.totalAdFirstFrameDuration += m.adBufferTime
    adStartupPerformanceInfo["first_frame_time"] = m.adBufferTime
    m.sendEvent(adStartupPerformanceInfo, "ad_startup_performance", eventBase)
  end if
End Function


'The Ad Pod Start event will be triggered when Ad Pod Starts.
'
'@adCtx: assocarray, contains ad information
Function playerLogLib_setAdPodStart(adCtx = {})
  m.resetAdMetrics()

  if isAA(adCtx) = true AND isNumber(adCtx.adCount) = true
    m.setAdCount(adCtx.adCount)
  else
    m.setAdCount(0)
  end if
End Function


'The Ad Start event will be triggered when Ad starts.
'
'@adCtx: assocarray, contains ad information
Function playerLogLib_fireAdStartEvent(adCtx = {})
  eventBase = {
    track_id: ""
    video_id: ""
    ad_id: ""
    url: ""
    is_preroll: ""
    ad_index: ""
    ad_count: ""
    duration: ""
    message: ""
  }

  if isAA(adCtx) = true
    adStartInfo = m.updateSingleAdInfo(adCtx)
    adStartInfo["video_id"] = m.videoId
    m.sendEvent(adStartInfo, "ad_start", eventBase)   
  end if
End Function


'The Ad Complete event will be triggered when Ad ends.
'
'@adCtx: assocarray, contains ad information
Function playerLogLib_fireAdCompleteEvent(adCtx = {})
  eventBase = {
    track_id: ""
    video_id: ""
    ad_id: ""
    url: ""
    is_preroll: ""
    ad_index: ""
    ad_count: ""
    duration: ""
    play_time_exclude_pause_time: ""
    message: ""
  }

  if isAA(adCtx) = true
    m.totalAdDurationPerTitle += adCtx.duration

    adCompleteInfo = m.updateSingleAdInfo(adCtx)
    adCompleteInfo["video_id"] = m.videoId
    m.sendEvent(adCompleteInfo, "ad_complete", eventBase)   
  end if
End Function


'The Ad Discontinue event will be triggered when Ad Error/Ad Stall.
'
'@adCtx: assocarray, contains ad information
Function playerLogLib_fireAdDiscontinueEvent(adCtx = {})
  m.failedAdCountPerTitle += 1
  m.totalAdDurationPerTitle += adCtx.duration

  eventBase = {
    track_id: ""
    video_id: ""
    ad_id: ""
    url: ""
    is_preroll: ""
    ad_index: ""
    ad_count: ""
    duration: ""
    reason: ""
    ad_position: ""
    message: ""
  }

  if isAA(adCtx) = true
    adDiscontinueInfo = m.updateSingleAdInfo(adCtx)

    adPosition = 0
    if adCtx.time <> invalid
      adPosition = adCtx.time
    end if

    adDiscontinueInfo["ad_position"] = adPosition
    adDiscontinueInfo["video_id"] = m.videoId
    adDiscontinueInfo["reason"] = "error"
    m.sendEvent(adDiscontinueInfo, "ad_discontinue", eventBase)   
  end if

  'this is used in quality of service event 
  m.failedAdCount += 1
End Function


'The Ad Pod complete event will be triggered when all Ads in ad pod are finished
'
'@adCtx: assocarray, contains video_id
Function playerLogLib_fireAdPodCompleteEvent(adCtx = {})
  eventBase = {
    track_id: ""
    video_id: ""
    ad_count: ""
    successful_count: ""
    failed_count: ""
    total_ads_duration: ""
    play_time_exclude_pause_time: ""
    is_preroll: ""
    message: ""
  }

  adCount = adCtx.adCount
  adPodCompleteInfo = {}
  adPodCompleteInfo["track_id"] = m.playerLogTrackId
  adPodCompleteInfo["ad_count"] = adCount
  adPodCompleteInfo["successful_count"] = adCount - m.failedAdCountPerTitle
  adPodCompleteInfo["failed_count"] = m.failedAdCountPerTitle
  adPodCompleteInfo["is_preroll"] = (adCtx.rendersequence = "preroll")
  adPodCompleteInfo["video_id"] = m.videoId
  adPodCompleteInfo["total_ads_duration"] = Round(m.totalAdDurationPerTitle)
  m.sendEvent(adPodCompleteInfo, "ad_pod_complete", eventBase)
End Function


'The updateSingleAdInfo will set the values for when Ad Start/Ad Ends/Ad Error/Ad Stall events.
'
'@adCtx: assocarray, contains ad related information
'
Function playerLogLib_updateSingleAdInfo(adCtx = {})
  if isAA(adCtx) = true
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

    'The ad framework returns the adIndex starting from 1, whereas the backend expects the index to start from 0.
    adIndex = adCtx.adIndex - 1

    adInfo = {}
    adInfo["track_id"] = m.playerLogTrackId
    adInfo["ad_id"] = adId
    adInfo["url"] = url
    adInfo["is_preroll"] = isPreroll
    adInfo["ad_index"] = adIndex
    adInfo["ad_count"] = adCtx.adCount
    adInfo["duration"] = Round(adCtx.duration)
    return adInfo
  else
    return {}
  end if
End Function


'resets the AdMetrics
Function playerLogLib_resetAdMetrics()
  m.failedAdCountPerTitle = 0
  m.totalAdDurationPerTitle = 0
End Function


'setLastStartStep sets value to m.lastStartStep. 
'START_LOAD represents player start load but has not shown first frame;
'IEWED_FIRST_FRAME represents viewed first frame;
'PLAY_STARTED represents first frame viewed and player position progressed normally.
'UNKNOWN represents player has not started load
'
'@lastStartStep: String, possible values are UNKNOWN, START_LOAD, VIEWED_FIRST_FRAME, PLAY_STARTED
'
Function playerLogLib_setLastStartStep(lastStartStep = "UNKNOWN")
  if isNonEmptyString(lastStartStep) = true
    m.lastStartStep = lastStartStep
  end if
End Function


'setIsAd sets value to m.isAd
'
'@isAd: boolean, used in events to identify whether the player is playing Ad or regular video 
'
Function playerLogLib_setIsAd(isAd = false)
  if isBoolean(isAd) = true
    m.isAd = isAd
  end if
End Function


'incrementAdReBuffer increments the value of adRebuffer by 1
'
Function playerLogLib_incrementAdReBuffer()
  m.adReBuffer += 1
End Function


'setAdCount sets the adCount value by checking ad playback
'
'@adCount: integer, number of ads actually played
Function playerLogLib_setAdCount(adCount)
  if isNumber(adCount) = true
    m.adCount += adCount
  end if
End Function


'setAdStartupFailureCount sets the AdStartupFailureCount value by checking ad playback
'
Function playerLogLib_setAdStartupFailureCount()
  m.adStartupFailureCount += 1
End Function


'setTotalAdDurationPerTitle sets the totalAdDurationPerTitle value by checking ad playback
'
Function playerLogLib_setTotalAdDurationPerTitle()
  m.totalAdDurationPerTitle += 1
End Function


'setErrorCode updates the video node's errorCode to m variable
'@errorCode: integer, video node's errorCode
'
Function playerLogLib_setErrorCode(errorCode)
  if isNumber(errorCode) = true
    m.errorCode = errorCode

    if m.errorCodeList.count() > 4
      m.errorCodeList.shift()
    end if
    m.errorCodeList.push(errorCode)

  else
    m.errorCode = 0
  end if
End Function


'setVideoBufferingStartTime marks the roTimeSpan
Function playerLogLib_setVideoBufferingStartTime()
  m.videoBufferingTimer.mark()
End Function


'setVideoBufferingEndTime calculates the total time buffering time of video
'
'@videoBufferingDuration: integer, this is the mid-buffering duration
Function playerLogLib_setVideoBufferingEndTime(videoBufferingDuration)
  'The valid buffering threshold is set to 50ms, as users are unlikely to notice a buffering screen for durations shorter than this.
  if isNumber(videoBufferingDuration) = true AND videoBufferingDuration > 50
    m.videoBufferingCount += 1

    if m.isTotalBufferingDurationExceededLimit = false
      if (videoBufferingDuration >= m.singleBufferingThreshold) OR (videoBufferingDuration + m.totalBufferingDuration) >= m.singleBufferingThreshold
        m.totalBufferingDuration = m.singleBufferingThreshold
        m.isTotalBufferingDurationExceededLimit = true
      else
        m.totalBufferingDuration += videoBufferingDuration
      end if
    end if
  end if
End Function


'setSeekEndPosition calculates the seek_count & total_seek_duration for Quality Of Service event
'
'@seekEndPosition: integer, this is the position where video resume after seek
Function playerLogLib_setSeekEndPosition(seekEndPosition)
  if isNumber(seekEndPosition) = true
    m.seekCount += 1
    m.isSeeking = false

    if m.videoPosition > -1 AND m.isSeekExceededLimit = false
      seekDuration = Abs(seekEndPosition - m.videoPosition)

      if seekDuration * 1000 >= m.singleSeekThreshold
        m.totalSeekDuration = m.singleSeekThreshold
        m.isSeekExceededLimit = True
      else
        m.totalSeekDuration += seekDuration
      end if
    end if  

  end if  
End Function


'setBreakOffError updates the video node's first errorCode to m variable and increments the breakOffCount
'
'@errorCode: integer, video node's first errorCode
Function playerLogLib_setBreakOffError(errorCode)
  if isNumber(errorCode) = true
    m.breakOffCount += 1

    if m.errorCodeList.count() > 4
      m.errorCodeList.shift()
    end if
    m.errorCodeList.push(errorCode)

    'firstErrorCode needs to be set only once
    if m.firstErrorCode = 0
      m.firstErrorCode = errorCode
    end if
  else
    m.firstErrorCode = 0
  end if
End Function


'setDownloadedSegmentData updated calculates the download_speed & download_frag_bitrate
'
'@downloadedSegment: assocarray, which contains segSize, downloadDuration, segDuration
Function playerLogLib_setDownloadedSegmentData(downloadedSegment)
  if isAA(downloadedSegment) = true
    m.totalSegSize += downloadedSegment.segSize
    m.totalDownloadDuration += downloadedSegment.downloadDuration
    m.totalSegDuration += downloadedSegment.segDuration
  end if
End Function


'The fireQualityOfService event will be triggered when a playback session ends
'
'@qualityOfServiceInfo: assocarray
Function playerLogLib_fireQualityOfServiceEvent()
  eventBase = {
    track_id: ""
    cffd: ""
    rc: ""
    last_ss: ""
    errc: ""
    first_errc: ""
    boc: ""
    bc: ""
    tbd: ""
    sc: ""
    tsd: ""
    tvt: ""
    tcrffd: ""
    ad_ac: ""
    ad_sfc: ""
    ad_eac: ""
    ad_taffd: ""
    ad_bac: ""
    is_ad: ""
    download_speed: ""
    cdn: ""
    resource_type: ""
    hdcp: ""
    codec: ""
    content_id: ""
    message: ""
    download_frag_bitrate: ""
    ad_imp: ""
  }

  qualityOfServiceInfo = {}
  qualityOfServiceInfo["track_id"] = m.playerLogTrackId
  qualityOfServiceInfo["cffd"] = Round(m.contentFirstFrameDuration)
  qualityOfServiceInfo["rc"] = Round(m.resumeCount)
  qualityOfServiceInfo["last_ss"] = m.lastStartStep
  qualityOfServiceInfo["errc"] = Round(m.errorCode)
  qualityOfServiceInfo["first_errc"] = Round(m.firstErrorCode)
  qualityOfServiceInfo["boc"] = Round(m.breakOffCount)
  qualityOfServiceInfo["bc"] = Round(m.videoBufferingCount)
  qualityOfServiceInfo["tbd"] = Round(m.totalBufferingDuration)
  qualityOfServiceInfo["sc"] = Round(m.seekCount)
  qualityOfServiceInfo["tsd"] = Round(m.totalSeekDuration)
  qualityOfServiceInfo["tvt"] = Round(m.totalViewTime) * 1000 'ms
  qualityOfServiceInfo["tcrffd"] = Round(m.totalContentResumeFirstFrameDuration)
  qualityOfServiceInfo["ad_sfc"] = Round(m.adStartupFailureCount)
  qualityOfServiceInfo["ad_eac"] = Round(m.failedAdCount)
  qualityOfServiceInfo["ad_taffd"] = Round(m.totalAdFirstFrameDuration)
  qualityOfServiceInfo["ad_bac"] = Round(m.adReBuffer)
  qualityOfServiceInfo["is_ad"] = m.isAd
  qualityOfServiceInfo["ad_ac"] = m.adCount

  if m.totalSegSize > 0 AND m.totalDownloadDuration > 0
    downloadSpeed = m.totalSegSize / m.totalDownloadDuration
  else
    downloadSpeed = 0  
  end if
  qualityOfServiceInfo["download_speed"] = downloadSpeed

  if m.totalSegSize > 0 AND m.totalSegDuration > 0
    downloadFragBitrate = m.totalSegSize / m.totalSegDuration
  else
    downloadFragBitrate = 0  
  end if
  qualityOfServiceInfo["download_frag_bitrate"] = downloadFragBitrate

  qualityOfServiceInfo["cdn"] = m.cdn
  qualityOfServiceInfo["resource_type"] = m.videoResourceType
  qualityOfServiceInfo["hdcp"] = m.hdcpVersion
  qualityOfServiceInfo["codec"] = m.videoCodecType
  qualityOfServiceInfo["content_id"] = m.videoId

  m.sendEvent(qualityOfServiceInfo, "quality_of_services", eventBase)
  m.resetQoSAttributes()
End Function


'The resetQoSAttributes will reset all quality of service attributes to default
'
Function playerLogLib_resetQoSAttributes()
  m.contentFirstFrameDuration = -1
  m.resumeCount = 0
  m.lastStartStep = "UNKNOWN"
  m.errorCode = 0
  m.firstErrorCode = 0
  m.breakOffCount = 0
  m.videoBufferingCount = 0
  m.totalBufferingDuration = 0 
  m.totalSeekDuration = 0
  m.seekCount = 0
  m.isSeekExceededLimit = false
  m.totalViewTime = 0
  m.totalContentResumeFirstFrameDuration = 0
  m.adStartupFailureCount = 0
  m.failedAdCount = 0
  m.totalAdFirstFrameDuration = 0
  m.adReBuffer = 0
  m.isAd = false
  m.adCount = 0
  m.isTotalBufferingDurationExceededLimit = false
End Function


'setStreamInfo sets value to stream bitrate, measure bitrate
'
'@streamInfo: assocarray, Information about the video stream that is currently playing or buffering.
Function playerLogLib_setStreamInfo(streamInfo = {})
  if isAA(streamInfo) = true
    'if there is any change in the streamBitrate, we consider as Adaptive Bitrate
    m.isAutoResolution = (m.streamBitrate <> 0 AND m.streamBitrate <> streamInfo.streamBitrate)
    m.streamBitrate = streamInfo.streamBitrate
    m.measuredBitrate = streamInfo.measuredBitrate
  end if
End Function


'setUserFeedback will be triggered when user selects any feedback on Player Feedback overlay
'
'@userfeedbackInfo: assocarray, which holds the feedback information
Function playerLogLib_setUserFeedback(userfeedbackInfo = {})
  eventBase = {
    track_id: ""
    feedback_issue: ""
    page_source: ""
    is_live: ""
    content_id: ""
    video_resource_type: ""
    video_resource_codec: ""
    video_resource_hdcp: ""
    video_resource_resolution: ""
    is_auto_resolution: ""
    position: ""
    bitrate_estimate: ""
    buffering: ""
    current_buffering_duration: ""
    seeking: ""
    current_seeking_duration: ""
    captions_index: ""
    captions_list: ""
    latest_startup_result: ""
    latest_ad_pod_startup_result: ""
    is_continue_watching: ""
    logged_in: ""
    bitrate: ""
    frame_rate: ""
    duration: ""
    message: ""
  }

  userfeedbackInfo["device_id"] = m.constants.deviceInfo.deviceId
  userfeedbackInfo["manufacturer"] = m.constants.deviceInfo.vendorName
  userfeedbackInfo["device_model"] = m.constants.deviceInfo.model
  userfeedbackInfo["os_version"] = m.constants.deviceInfo.firmwareVersion
  userfeedbackInfo["app_version"] = m.constants.deviceInfo.clientVersion
  userfeedbackInfo["content_id"] = m.videoId
  userfeedbackInfo["video_resource_type"] = m.videoResourceType
  userfeedbackInfo["video_resource_codec"] = m.videoCodecType
  userfeedbackInfo["video_resource_hdcp"] = m.hdcpVersion
  userfeedbackInfo["video_resource_resolution"] = m.videoResolution
  userfeedbackInfo["position"] = m.videoPosition
  userfeedbackInfo["captions_index"] = m.captionsIndex
  userfeedbackInfo["captions_list"] = m.getCaptionsList()
  userfeedbackInfo["is_continue_watching"] = m.isContinueWatching
  userfeedbackInfo["latest_error_code_list"] = m.errorCodeList
  userfeedbackInfo["seeking"] = m.isSeeking

  if m.isSeeking = true
    userfeedbackInfo["current_seeking_duration"] = m.seekingTimer.totalMilliseconds()
  else
    userfeedbackInfo["current_seeking_duration"] = 0
  end if

  userfeedbackInfo["latest_startup_result"] = m.lastStartStep
  userfeedbackInfo["duration"] = m.duration
  userfeedbackInfo["is_auto_resolution"] = m.isAutoResolution

  latestAdPodStartupResultsArray = []

  for each key in m.latestAdPodStartupResult
    latestAdPodStartupResultsArray.push(m.latestAdPodStartupResult[key])
  end for

  userfeedbackInfo["latest_ad_pod_startup_result"] = latestAdPodStartupResultsArray
  userfeedbackInfo["buffering"] = (m.videoState = "buffering")

  if m.videoBufferingTimer <> invalid
    videoBufferingDuration = m.videoBufferingTimer.totalMilliseconds()
    userfeedbackInfo["current_buffering_duration"] = videoBufferingDuration * 1000
  end if

  if m.measuredBitrate >= 1000
    userfeedbackInfo["bitrate_estimate"] = (m.measuredBitrate / 1000) 'kbps
  end if

  if m.streamBitrate >= 1000
    userfeedbackInfo["bitrate"] = (m.streamBitrate / 1000) 'kbps
  end if

  m.sendEvent(userfeedbackInfo, "user_feedback", eventBase)
End Function


'setIsSeeking sets value to m.isAd
'
'@isSeeking: boolean, used in events to detect whether the video is seeking 
'
Function playerLogLib_setIsSeeking(isSeeking = false)
  if isBoolean(isSeeking) = true
    m.isSeeking = isSeeking
    m.seekingTimer.mark()
  end if
End Function


'setCaptions sets value to captionsList based on available subtitle tracks
'
'@captions: array, list of subtitles for the title
Function playerLogLib_setCaptions(captions = [])
  if isNonEmptyArray(captions) = true
    m.captions = captions
  else
    m.captions = []
  end if
End Function


'getCaptionsList gets the list of caption's description based on available subtitle tracks. Eg. English, Spanish etc
'
Function playerLogLib_getCaptionsList()
  captionsList = ["Off"]

  for each caption in m.captions
    captionsList.push(caption.description)
  end for

  return captionsList
End Function


'updateCaptionIndex updates the Caption index based on selected track
'
'@subtitleTrack: string, selected subtitle track
Function playerLogLib_updateCaptionIndex(subtitleTrack = "")
  if isNonEmptyString(subtitleTrack) = true
    index = 1 'considering 0th position holds "Off", so starting the index from 1

    for each caption in m.captions
      if subtitleTrack = caption.trackName
        m.captionsIndex = index
        exit for
      end if
      index++
    end for
  else
    m.captionsIndex = 0
  end if  
End Function


'setAdPodStartupResult sets the latestAdPodStartupResult value by checking ad playback
'START_LOAD represents Ad start load but has not shown first frame
'VIEWED_FIRST_FRAME represents Ad viewed first frame
'PLAY_STARTED represents first frame viewed for Ad
'UNKNOWN represents Ad has not started load or failed
'
'@adCtx: assocarray, contains ad related information
Function playerLogLib_setAdPodStartupResult(adCtx = {})
  if isAA(adCtx) = true AND isAA(adCtx.ad) = true AND adCtx.ad.adId <> invalid
    adId = adCtx.ad.adId

    if adCtx.type = "AdPodStart"
      m.latestAdPodStartupResult = {}
    else if adCtx.type = "Impression"
      m.latestAdPodStartupResult[adId] = "VIEWED_FIRST_FRAME"
    else if adCtx.type = "Start"
      m.latestAdPodStartupResult[adId] = "PLAY_STARTED"
    else if adCtx.type = "Close"
      m.latestAdPodStartupResult[adId] = "START_LOAD"
    else if adCtx.type = "Error"
      m.latestAdPodStartupResult[adId] = "UNKNOWN"  
    end if
  end if
End Function


'The Ad Missed event will be triggered when any ad pod is missed to play due to 
'autoplay, exitBeforeResponse, exitBeforePlayback, exitDuringPlayback
'
'@adMissedInfo: assocarray, contains reason, response_time, ad_count, total_ads_duration, position, cue_point
Function playerLogLib_fireAdMissedEvent(adMissedInfo = {})
  eventBase = {
    device_id: ""
    platform: ""
    version: ""
    log_version: ""
    track_id: ""
    is_preroll: ""
    position: ""
    cue_point: ""
    ad_count: ""
    total_ads_duration: ""
    reason: ""
    response_time: ""
    video_id: ""
    message: ""
  }

  adMissedInfo["device_id"] = m.constants.deviceInfo.deviceId
  adMissedInfo["platform"] = m.constants.platform
  adMissedInfo["version"] = m.constants.deviceInfo.clientVersion
  adMissedInfo["log_version"] = m.constants.player.analyticsVersion
  adMissedInfo["track_id"] = m.playerLogTrackId
  adMissedInfo["video_id"] = m.videoId

  if m.adType = "preroll"
    isPreroll = true
  else
    isPreroll = false
  end if

  adMissedInfo.is_preroll = isPreroll
  m.sendEvent(adMissedInfo, "ad_missed", eventBase)
End Function