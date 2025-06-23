' This file is used to send playerlogs. Please refer to the document below for details on all events:
' Document - https://www.notion.so/tubi/RFC-Player-Analytics-Event-v1-0-b8bee0eb69d14cc891baf8e907635f2f
' Protos - https://github.com/adRise/protos/tree/master/tubi/analytics/v3/player_analytics_event
' 
'@constants: assocArray, constants as set in Constants.brs
'@tracking: assocArray, a request queue as returned by TubiRequestQueue().create(), default as invalid 
'
Function LivePlayerLogLib(constants, tracking)
  deviceInfo = CreateObject("roDeviceInfo")

  return {
    constants: constants
    tracking: tracking
    deviceInfo: deviceInfo
    playerLogTrackId: deviceInfo.GetRandomUUID() 'unique TrackId used in all events
    trackingLoggingTask: getGlobalAA().global.trackingLoggingTask

    '//timers
    firstFrameTimerForContentStart: CreateObject("roTimeSpan") 'used to calculate contentFirstFrameDuration
    videoBufferingTimer: invalid 'used to calculate bufferingTime, helps for QoS event. This needs be initialized only when mid-buffering starts

    'ad
    totalCount: 0
    totalAdsDuration: 0
    adCount: 0

    '//video fields
    content: invalid 'node which hols the content information, used in various events
    videoState: "" 'various events are fired based on videoState
    videoId: "" 'used used in various events
    videoCodecType: "" 'used in various events, possible values are H264, H265
    videoResolution: "" 'used in ContentStartupPerformance event, possible values are 2160, 1080, 720
    videoResourceType: "" 'used in various events, possible values are dash_widevine_psshv0, dash_playready_psshv0, dash, hlsv6, hlsv3
    hdcpVersion: "" 'used in qualityOfService event
    ssaiVersion: constants.player.linear.ssaiVersion.unknown 'used in qualityOfService event
    videoPosition: -1 'used in various calculations and events like contentStartupPerformance
    duration: 0 'used in userFeedback event
    playerType: constants.player.linear.player_type_unspecified
    manifestLoadedTime: 0
    playerFeedback: "" 'used in playerPageExit event
    lastStartStep: "UNKNOWN"
    isVideoPlayed: false
    errorCode: 0 'used in QoS / playerPageExit event
    firstErrorCode: 0 'used in QoS / playerPageExit event
    hasErrorModalShown: false 'used in playerPageExit event
    cdn: "" 'used in QoS / playerPageExit event
    totalViewTime: 0 'used in QoS event
    isBuffering: false 'used in playerPageExit event

    'used to calculate download_frag_bitrate & download_speed in QoS event
    totalSegSize: 0
    totalAudioSegDuration: 0
    totalVideoSegDuration: 0
    totalDownloadDuration: 0

    contentFirstFrameDuration: -1 'used in Qos event
    breakOffCount: 0 'used in QoS event
    videoBufferingCount: 0 'used in QoS event
    totalBufferingDuration: 0 'used in QoS event
    singleBufferingThreshold: 3600000 'threshold of single buffering duration in milliseconds 

    'video
    setFirstFrameForContentStart: playerLogLib_setFirstFrameForLiveContentStart
    setVideoContent: playerLogLib_setLiveVideoContent
    setVideoControl: playerLogLib_setLiveVideoControl
    setVideoState: playerLogLib_setLiveVideoState
    setVideoPosition: playerLogLib_setLiveVideoPosition
    setManifestLoadedTime: playerLogLib_setLiveManifestLoadedTime
    setErrorCode: playerLogLib_setLiveErrorCode
    setBreakOffError: playerLogLib_setLiveBreakOffError
    setErrorModal: playerLogLib_setLiveErrorModal
    setDownloadedSegmentData: playerLogLib_setLiveDownloadedSegmentData
    setCDN: playerLogLib_setLiveCDN

    'player
    setPlayerType: playerLogLib_setLivePlayerType
    setLastStartStep: playerLogLib_setLiveLastStartStep

    setVideoBufferingStartTime: playerLogLib_setLiveVideoBufferingStartTime
    setVideoBufferingEndTime: playerLogLib_setLiveVideoBufferingEndTime

    fireContentStartupPerformanceEvent: playerLogLib_fireLiveContentStartupPerformanceEvent
    fireContentStartEvent: playerLogLib_fireLiveContentStartEvent
    fireAdStartEvent: playerLogLib_fireLiveAdStartEvent
    fireAdCompleteEvent: playerLogLib_fireLiveAdCompleteEvent
    fireAdPodCompleteEvent: playerLogLib_fireLiveAdPodCompleteEvent
    fireQualityOfServiceEvent: playerLogLib_fireLiveQualityOfServiceEvent
    firePlayerPageExitEvent: playerLogLib_fireLivePlayerPageExitEvent

    'private
    resetAttributes: playerLogLib_resetAttributes
    sendEvent: playerLogLib_sendLiveEvent
  }
End Function 


'setFirstFrameForLiveContentStart marks the roTimeSpan
Function playerLogLib_setFirstFrameForLiveContentStart()
  m.firstFrameTimerForContentStart.mark()
End Function


'@content: roSGNode, a TubiContentNode holds the video related information
'
Function playerLogLib_setLiveVideoContent(content = invalid)
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
      m.hdcpVersion = m.constants.player.hdcpVersion["hdcp_unknown"]
    end if

    videoResources = m.content.videoResources
    ssaiVersionStr = ""

    for each resources in videoResources
      for each resource in resources
        if resource <> invalid AND resource.ssaiversion <> invalid
          ssaiVersionStr = resource.ssaiversion
          exit for
        end if
        exit for
      end for
    end for

    if isNonEmptyString(ssaiVersionStr) = true
      m.ssaiVersion = m.constants.player.linear.ssaiVersion[lcase(ssaiVersionStr)]
    else
      m.ssaiVersion = m.constants.player.linear.ssaiVersion.unknown
    end if
  else
    m.content = invalid
    m.videoId = ""
    m.videoCodecType = ""
    m.videoResolution = ""
    m.videoResourceType = ""
    m.hdcpVersion = ""
    m.ssaiVersion = m.constants.player.linear.ssaiVersion.unknown
  end if
End Function


'@videoControl: String, possible values are "play", "stop", "pause", "resume", "replay", "prebuffer", "skipcontent", "none" 
'
Function playerLogLib_setLiveVideoControl(videoControl = "")
  if isNonEmptyString(videoControl) = true
    if videoControl = "play"
      m.resetAttributes()
    end if
  end if
End Function


'@isFullScreen: boolean, possible values are true / false
'
Function playerLogLib_setLivePlayerType(isFullScreen = false)
  if isBoolean(isFullScreen) = true
    m.playerType = m.constants.player.linear.player_type_default
  else
    m.playerType = m.constants.player.linear.player_type_banner
  end if
End Function


'@videoState: String, possible values are "buffering", "playing", "paused", "stopping", "stopped", "finished", "error", "none"
'
Function playerLogLib_setLiveVideoState(videoState = "")
  if isNonEmptyString(videoState) = true
    m.videoState = videoState
  else
    m.videoState = ""
  end if

  if m.videoState = "buffering"

    if m.isVideoPlayed = true
      m.isBuffering = true
      m.setVideoBufferingStartTime()
    else
      m.isBuffering = false  
    end if

  else if m.videoState = "playing"
    m.isBuffering = false

    if m.isVideoPlayed = true AND m.videoBufferingTimer <> invalid
      videoBufferingDuration = m.videoBufferingTimer.totalMilliseconds()
      m.setVideoBufferingEndTime(videoBufferingDuration)
      m.videoBufferingTimer = invalid
    end if

    if m.isVideoPlayed = false
      'Triggers the ContentStartupPerformance & ContentStart when playback begins without an ad having been played beforehand.
      m.setLastStartStep("VIEWED_FIRST_FRAME")
      m.fireContentStartupPerformanceEvent()
      m.fireContentStartEvent()
    end if  
    m.isVideoPlayed = true

  else if m.videoState = "stopped" OR m.videoState = "finished"
    m.isBuffering = false
    m.isVideoPlayed = false 'reset isVideoPlayed for every new playback session
  end if
End Function


' The Content Startup Performance event will be triggered when playback starts
' It will collect performance information for the startup including details such as manifest, playlist, loadtime etc
' Note: It will not be triggered after regular buffering events.
'
Function playerLogLib_fireLiveContentStartupPerformanceEvent()
  firstFrameTime = m.firstFrameTimerForContentStart.totalMilliseconds()

  'contentFirstFrameDuration will be set only once per playback session
  if m.contentFirstFrameDuration = -1
    m.contentFirstFrameDuration = firstFrameTime
  end if

  eventBase = {
    device_id: ""
    platform: m.constants.platform
    version: m.constants.deviceInfo.clientVersion
    log_version: m.constants.player.analyticsVersion
    track_id: ""
    video_id: ""
    video_resource_type: ""
    video_codec_type: ""
    manifest_loaded_time: ""
    first_frame_time: ""
    player_type: ""
    ssai_version: ""
    current_video_resolution: ""
    network_type: ""
  }

  data = {
    device_id: m.constants.deviceInfo.deviceId
    platform: m.constants.platform
    version: m.constants.deviceInfo.clientVersion
    log_version: m.constants.player.analyticsVersion
    track_id: m.playerLogTrackId
    video_id: m.videoId
    video_resource_type: m.videoResourceType
    video_codec_type: m.videoCodecType
    manifest_loaded_time: m.manifestLoadedTime
    first_frame_time: firstFrameTime
    player_type: m.playerType
    ssai_version: m.ssaiVersion
    current_video_resolution: m.videoResolution
    network_type: createObject("roDeviceInfo").getConnectionType()
  }

  m.sendEvent(data, "live_content_startup_performance", eventBase)
End Function


' The Content Start event will be triggered when playback starts or resumes after pre-roll and midroll ads, as well as in cases with no pre-roll.
' It will collect content information for the startup including details such as start_position, video information etc
' Note: It will not be triggered after regular buffering events.
'
Function playerLogLib_fireLiveContentStartEvent()
  eventBase = {
    device_id: ""
    platform: ""
    version: ""
    log_version: ""
    track_id: ""
    video_id: ""
    video_resource_type: ""
    video_codec_type: ""
    current_video_resolution: ""
    player_type: ""
    ssai_version: ""
    network_type: ""
  }

  data = {
    device_id: m.constants.deviceInfo.deviceId
    platform: m.constants.platform
    version: m.constants.deviceInfo.clientVersion
    log_version: m.constants.player.analyticsVersion
    track_id: m.playerLogTrackId
    video_id: m.videoId
    video_resource_type: m.videoResourceType
    video_codec_type: m.videoCodecType
    current_video_resolution: m.videoResolution
    player_type: m.playerType
    ssai_version: m.ssaiVersion
    network_type: createObject("roDeviceInfo").getConnectionType()
  }

  m.sendEvent(data, "live_content_start", eventBase)
End Function


'The Ad Start event will be triggered when Ad starts.
'
'@adInfo: assocarray, contains ad information
Function playerLogLib_fireLiveAdStartEvent(adInfo)
  m.adCount += 1

  eventBase = {
    device_id: ""
    platform: ""
    version: ""
    log_version: ""
    track_id: ""
    video_id: ""
    ad_id: ""
    url: ""
    ad_index: ""
    ad_count: ""
    duration: ""
    ssai_version: ""
    player_type: ""
  }

  if isAA(adInfo) = true
    adInfo.device_id = m.constants.deviceInfo.deviceId
    adInfo.platform = m.constants.platform
    adInfo.version = m.constants.deviceInfo.clientVersion
    adInfo.log_version = m.constants.player.analyticsVersion
    adInfo.track_id = m.playerLogTrackId
    adInfo.video_id = m.videoId
    adInfo.player_type = m.playerType
  end if

  m.sendEvent(adInfo, "live_ad_start", eventBase)
End Function


'The Ad Complete event will be triggered when Ad Completes.
'
'@adInfo: assocarray, contains ad information
Function playerLogLib_fireLiveAdCompleteEvent(adInfo)
  eventBase = {
    device_id: ""
    platform: ""
    version: ""
    log_version: ""
    track_id: ""
    video_id: ""
    ad_id: ""
    url: ""
    ad_index: ""
    ad_count: ""
    duration: ""
    ssai_version: ""
    player_type: ""
  }

  if isAA(adInfo) = true
    adInfo.device_id = m.constants.deviceInfo.deviceId
    adInfo.platform = m.constants.platform
    adInfo.version = m.constants.deviceInfo.clientVersion
    adInfo.log_version = m.constants.player.analyticsVersion
    adInfo.track_id = m.playerLogTrackId
    adInfo.video_id = m.videoId
    adInfo.player_type = m.playerType
  end if

  m.sendEvent(adInfo, "live_ad_complete", eventBase)
End Function


'The Ad Pod Complete event will be triggered when all Ad Completes.
'
'@adInfo: assocarray, contains ad information
Function playerLogLib_fireLiveAdPodCompleteEvent(adInfo)
  eventBase = {
    device_id: ""
    platform: ""
    version: ""
    log_version: ""
    track_id: ""
    video_id: ""
    total_count: 0
    total_ads_duration: 0
    ssai_version: ""
    player_type: ""
  }

  if isAA(adInfo) = true
    adInfo.device_id = m.constants.deviceInfo.deviceId
    adInfo.platform = m.constants.platform
    adInfo.version = m.constants.deviceInfo.clientVersion
    adInfo.log_version = m.constants.player.analyticsVersion
    adInfo.track_id = m.playerLogTrackId
    adInfo.video_id = m.videoId
    adInfo.player_type = m.playerType
  end if

  m.sendEvent(adInfo, "live_ad_pod_complete", eventBase)
End Function


'setDownloadedSegmentData updated calculates the download_speed & download_frag_bitrate
'
'@downloadedSegment: assocarray, which contains segSize, downloadDuration, segDuration
Function playerLogLib_setLiveDownloadedSegmentData(downloadedSegment)
  if isAA(downloadedSegment) = true AND isNonEmptyString(m.cdn) = false
    segType = downloadedSegment.segType
    segUrl = downloadedSegment.segUrl

    if segType = 0 OR segType = 1 OR segType = 2
      m.totalSegSize += downloadedSegment.segSize 'in bytes
      m.totalDownloadDuration += downloadedSegment.downloadDuration 'in milliseconds

      if segType = 1 'audio for hlsv6
        m.totalAudioSegDuration += downloadedSegment.segDuration 'in milliseconds
      else if segType = 2 'video for hlsv6
        m.totalVideoSegDuration += downloadedSegment.segDuration 'in milliseconds
      else if segType = 0 'mux (video & audio) for hlsv3
        m.totalVideoSegDuration += downloadedSegment.segDuration 'in milliseconds
      end if
      m.setCDN(segUrl)
    end if
  end if
End Function


'
'@segUrl: string, segment url to identify the cdn
Function playerLogLib_setLiveCDN(segUrl = "")
  if isNonEmptyString(segUrl) = true
    if segUrl.InStr("fastly") > 0
      m.cdn = "fastly"
    else if segUrl.InStr("cloudfront") > 0
      m.cdn = "cloudfront"
    else if segUrl.InStr("akamai") > 0
      m.cdn = "akamai"
    end if
  end if
End Function


'The QualityOfService event will be triggered when user changes the channel or exits the player
'
Function playerLogLib_fireLiveQualityOfServiceEvent()
  eventBase = {
    device_id: ""
    platform: ""
    version: ""
    log_version: ""
    track_id: ""
    cffd: ""
    last_ss: ""
    errc: ""
    first_errc: ""
    boc: ""
    bc: ""
    tbd: ""
    tvt: ""
    ad_ac: ""
    download_speed: ""
    cdn: ""
    resource_type: ""
    codec: ""
    content_id: ""
    download_frag_bitrate: ""
    ssai_version: ""
  }

  qualityOfServiceInfo = {}
  qualityOfServiceInfo["device_id"] = m.constants.deviceInfo.deviceId
  qualityOfServiceInfo["platform"] = m.constants.platform
  qualityOfServiceInfo["version"] = m.constants.deviceInfo.clientVersion
  qualityOfServiceInfo["log_version"] = m.constants.player.analyticsVersion
  qualityOfServiceInfo["track_id"] = m.playerLogTrackId
  qualityOfServiceInfo["content_id"] = m.videoId

  qualityOfServiceInfo["cffd"] = Round(m.contentFirstFrameDuration)
  qualityOfServiceInfo["last_ss"] = m.lastStartStep
  qualityOfServiceInfo["errc"] = Round(m.errorCode)
  qualityOfServiceInfo["first_errc"] = Round(m.firstErrorCode)
  qualityOfServiceInfo["boc"] = Round(m.breakOffCount)
  
  qualityOfServiceInfo["bc"] = Round(m.videoBufferingCount)
  qualityOfServiceInfo["tbd"] = Round(m.totalBufferingDuration)
  
  qualityOfServiceInfo["tvt"] = Round(m.totalViewTime) * 1000 'ms
  qualityOfServiceInfo["ad_ac"] = m.adCount
  qualityOfServiceInfo["ssai_version"] = m.ssaiVersion
  qualityOfServiceInfo["cdn"] = m.cdn

  'download_speed represents the download speed (in kbits/s) within a playback session. 
  'It is calculated by dividing the total size of downloaded fragments (total video fragments size + total audio fragments size) 
  'by the total fragment download duration.
  if m.totalSegSize > 0 AND m.totalDownloadDuration > 0
    downloadSpeed = (m.totalSegSize * 8 / 1000) / (m.totalDownloadDuration / 1000)
  else
    downloadSpeed = 0  
  end if
  qualityOfServiceInfo["download_speed"] = downloadSpeed

  'download_frag_bitrate represents the average playback bitrate (in kbits/s) within a playback session. 
  'It is calculated by dividing the total size of downloaded fragments (total video fragments size + total audio fragments size) 
  'by the total fragment duration(maximum of total video fragments duration and total audio fragments duration).
  downloadFragBitrate = 0

  if m.totalSegSize > 0 
    if m.totalAudioSegDuration > 0 AND m.totalVideoSegDuration > 0
      downloadFragBitrate = (m.totalSegSize * 8 / 1000) / (maxValue(m.totalAudioSegDuration, m.totalVideoSegDuration) / 1000)
    else if m.totalAudioSegDuration > 0
      downloadFragBitrate = (m.totalSegSize * 8 / 1000) / (m.totalAudioSegDuration / 1000)
    else if m.totalVideoSegDuration > 0
      downloadFragBitrate = (m.totalSegSize * 8 / 1000) / (m.totalVideoSegDuration / 1000)
    end if
  end if

  qualityOfServiceInfo["download_frag_bitrate"] = downloadFragBitrate

  m.sendEvent(qualityOfServiceInfo, "live_quality_of_services", eventBase)
End Function


'The PlayerPageExit event will be triggered when user changes the channel or exits the player
'
Function playerLogLib_fireLivePlayerPageExitEvent()
  eventBase = {
    device_id: ""
    platform: ""
    version: ""
    log_version: ""
    track_id: ""
    feedback: ""
    errc: 0
    first_errc: 0
    has_error_modal: ""
    is_buffering: ""
    resource_type: ""
    codec: ""
    player_type: ""
    ssai_version: ""
    last_ss: ""
    cdn: ""
  }

  playerExitInfo = {}
  playerExitInfo["device_id"] = m.constants.deviceInfo.deviceId
  playerExitInfo["platform"] = m.constants.platform
  playerExitInfo["version"] = m.constants.deviceInfo.clientVersion
  playerExitInfo["log_version"] = m.constants.player.analyticsVersion
  playerExitInfo["track_id"] = m.playerLogTrackId
  playerExitInfo["video_id"] = m.videoId
  playerExitInfo["resource_type"] = m.videoResourceType
  playerExitInfo["codec"] = m.videoCodecType
  playerExitInfo["player_type"] = m.playerType
  playerExitInfo["ssai_version"] = m.ssaiVersion
  playerExitInfo["cdn"] = m.cdn

  if isNonEmptyString(m.playerFeedback) = true
    playerExitInfo["feedback"] = m.playerFeedback
  end if

  playerExitInfo["is_buffering"] = m.isBuffering
  playerExitInfo["errc"] = Round(m.errorCode)
  playerExitInfo["first_errc"] = Round(m.firstErrorCode)
  playerExitInfo["has_error_modal"] = m.hasErrorModalShown
  playerExitInfo["last_ss"] = m.lastStartStep

  m.sendEvent(playerExitInfo, "live_player_page_exit", eventBase)

  m.hasErrorModalShown = false
  m.playerFeedback = ""
End Function


'setLiveVideoPosition updates the playerPosition to m variable
'@playerPosition: integer, position of the playback
'
Function playerLogLib_setLiveVideoPosition(playerPosition = -1)
  if isNumber(playerPosition) = true AND playerPosition > 0
    m.videoPosition = playerPosition

    if m.lastStartStep <> "UNKNOWN" OR m.lastStartStep <> "START_LOAD"
      m.totalViewTime += 1
    end if

    m.setLastStartStep("PLAY_STARTED")
  else
    m.videoPosition = -1
  end if
End Function


'@manifestLoadedTime: integer, load time of manifest
'
Function playerLogLib_setLiveManifestLoadedTime(manifestLoadedTime = 0)
  if isNumber(manifestLoadedTime) = true
    m.manifestLoadedTime = manifestLoadedTime
  else
    m.manifestLoadedTime = 0
  end if
End Function


'setLastStartStep sets value to m.lastStartStep. 
'START_LOAD represents player start load but has not shown first frame;
'VIEWED_FIRST_FRAME represents viewed first frame;
'PLAY_STARTED represents first frame viewed and player position progressed normally.
'UNKNOWN represents player has not started load
'
'@lastStartStep: String, possible values are UNKNOWN, START_LOAD, VIEWED_FIRST_FRAME, PLAY_STARTED
'
Function playerLogLib_setLiveLastStartStep(lastStartStep = "UNKNOWN")
  if isNonEmptyString(lastStartStep) = true
    if lastStartStep = "START_LOAD"
      m.setFirstFrameForContentStart() 'mark the time from player start load to first frame rendered 
    end if
    m.lastStartStep = lastStartStep
  end if
End Function


'setErrorCode updates the video node's errorCode to m variable
'@errorCode: integer, video node's errorCode
'
Function playerLogLib_setLiveErrorCode(errorCode)
  if isNumber(errorCode) = true
    m.errorCode = errorCode
  else
    m.errorCode = 0
  end if
End Function


'setBreakOffError updates the video node's first errorCode to m variable and increments the breakOffCount
'
'@errorCode: integer, video node's first errorCode
Function playerLogLib_setLiveBreakOffError(errorCode)
  if isNumber(errorCode) = true
    m.breakOffCount += 1

    'firstErrorCode needs to be set only once
    if m.firstErrorCode = 0
      m.firstErrorCode = errorCode
    end if
  else
    m.firstErrorCode = 0
  end if
End Function


'setErrorModal helps to identify whether any error modal is displayed while exiting the player 
Function playerLogLib_setLiveErrorModal(hasErrorModalShown = false)
  if isBoolean(hasErrorModalShown) = true
    m.hasErrorModalShown = hasErrorModalShown
  end if
End Function


'The resetLiveQoSAttributes will reset all quality of service attributes to default
'
Function playerLogLib_resetAttributes()
  m.contentFirstFrameDuration = -1
  m.lastStartStep = "UNKNOWN"
  m.errorCode = 0
  m.firstErrorCode = 0
  m.breakOffCount = 0
  m.videoBufferingCount = 0
  m.totalBufferingDuration = 0 
  m.totalViewTime = 0
  m.isAd = false
  m.adCount = 0
  m.cdn = ""
  m.isVideoPlayed = false
  m.hasErrorModalShown = false
  m.totalSegSize = 0
  m.totalAudioSegDuration = 0
  m.totalVideoSegDuration = 0
  m.totalDownloadDuration = 0
End Function


'setVideoBufferingStartTime marks the roTimeSpan
Function playerLogLib_setLiveVideoBufferingStartTime()
  m.videoBufferingTimer = CreateObject("roTimespan")
  m.videoBufferingTimer.mark()
End Function


'setVideoBufferingEndTime calculates the total time buffering time of video
'
'@videoBufferingDuration: integer, this is the mid-buffering duration
Function playerLogLib_setLiveVideoBufferingEndTime(videoBufferingDuration)
  'The valid buffering threshold is set to 200ms, as users are unlikely to notice a buffering screen for durations shorter than this.
  if isNumber(videoBufferingDuration) = true AND videoBufferingDuration > 200
    m.videoBufferingCount += 1

    if (videoBufferingDuration >= m.singleBufferingThreshold)
      m.totalBufferingDuration += m.singleBufferingThreshold
    else
      m.totalBufferingDuration += videoBufferingDuration
    end if
  end if
End Function


' playerLogLib_sendLiveEvent helps to send the event to backend through trackingLoggingTask
'
'@data: assocarray, the payload that needs to be sent
'@subType: String, it is eventType
'@eventbase: assocArray, a list of fields for each message as defined in this file (which should match the protos specs on the server)
Function playerLogLib_sendLiveEvent(data = {} as Dynamic, subType = "" as String, eventBase = {})
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
End Function
