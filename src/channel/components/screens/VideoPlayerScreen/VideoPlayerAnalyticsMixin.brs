' VideoPlayerAnalyticsMixin.brs
' Analytics functions extracted from VideoPlayerScreen.brs for better code organization
' These functions handle all analytics events for the video player


' Helper function to prevent tracking events being sent for trailers
Function trackEvent(event as Object)
  allowedTrailerEvents = {
    "start_trailer": true
    "trailer_play_progress": true
    "finish_trailer": true
  }

  if m.top.isTrailer = false OR allowedTrailerEvents[event.type] = true
    appendContentUserContextValues(event.values, m.top.content, m.top.isAdultParentalLevel)
    m.global.trackingLoggingTask.trackEvent = event
  end if
End Function


' Helper function to prevent historyPosition being sent during trailers
Function historyPosition(position)
  if m.top.isTrailer = false
    ' round the position up/down based on 0.5 rule.
    ' this is necessary since isAtPosition() is returning true if the decimal is greater than 0.5.
    ' If we do not round here, and a user exits the video player during ad playback, the history would be
    ' stored always rounding down, but the ad check is done while rounding up over 0.5. So, if a user then
    ' resumes playback, the ad call sends the position as 1 second less than the midroll cuepoint, and
    ' no ads are returned, when they should be returned.
    position = round(position)
    m.top.historyPosition = position
    m.lastSavedPosition = position
  end if
End Function


' updates the lastPingTime
' @position: int, this is video position
Function updateLastPingTime(position)
  m.lastPingTime = position
End Function


Function fireStartVideoOrTrailerEvent()

  'start_video user event analytics
  if m.top.isTrailer = true
    'set up tracking for trailer
    trackEvent({
      type: "start_trailer"
      values: {
        video_id: m.Video.content.id.toInt()
        is_fullscreen: true
      }
    })
  else
    'set up tracking for normal playback
    playbackSource = m.top.playbackSource
    isLiveTv = false
    isFullScreen = true
    isEmbedded = false

    hasSubtitles = false
    if m.Video.globalCaptionMode = "On" AND m.Video.content.hasSubtitles = true
      hasSubtitles = true
    end if

    resourceType = "VIDEO_RESOURCE_TYPE_UNKNOWN"
    if m.Video.content.drmType = m.constants.player.drmTypes.dashWidevine
      resourceType = "VIDEO_RESOURCE_TYPE_DASH_WIDEVINE"
    else if m.Video.content.drmType = m.constants.player.drmTypes.dashPlayready
      resourceType = "VIDEO_RESOURCE_TYPE_DASH_PLAYREADY"
    else if m.Video.content.drmType = m.constants.player.drmTypes.dash
      resourceType = "VIDEO_RESOURCE_TYPE_DASH"
    else if m.Video.content.drmType = m.constants.player.drmTypes.hlsv6
      resourceType = "VIDEO_RESOURCE_TYPE_HLSV6"
    else if m.Video.content.drmType = m.constants.player.drmTypes.hlsv3
      resourceType = "VIDEO_RESOURCE_TYPE_HLSV3"
    end if

    codeType = "VIDEO_CODEC_UNKNOWN"
    if isNonEmptyString(m.Video.content.codec) = true
      codeType = "VIDEO_CODEC_" + m.Video.content.codec
    end if

    resolution = "VIDEO_RESOLUTION_UNKNOWN"
    if isNonEmptyString(m.Video.content.resolution) = true
      resolution = "VIDEO_RESOLUTION_" + m.Video.content.resolution + "P"
    end if

    startPosition = Int(m.playerPosition * 1000)
    if startPosition < 0
      startPosition = 0 'reset the player position to 0 since we do not know why
    end if

    trackEvent({
      type: "start_video"
      values: {
        video_id: m.Video.content.id.toInt()
        start_position: startPosition
        current_cdn: "" 'not possible for Roku client
        has_subtitles: hasSubtitles 'the video player will show subtitles at start
        is_livetv: isLiveTv
        is_embedded: isEmbedded
        is_fullscreen: isFullScreen
        playback_source: playbackSource.srcForAnalytic
        video_player: "DEFAULT"
        video_resource_type: resourceType
        video_resource_url: m.Video.content.URL
        video_codec_type: codeType
        video_resolution: resolution
        audio_language: UCase(m.currentAudioLanguage)
        subtitle_language: UCase(m.currentSubtitleLanguage)
      }
    })
  end if

End Function


' Play progress events should occur at the following instances
' a user watches for 10s
' an ad break starts
' a user begins a "seek" functionality (skip 10s, hop 30s, ff/rew, jump to beginning)
' a user selects to "jump to next video"
'
' @callSource: string, temporary param used for debugging large playProgressEvents,
'              should be removed after issue is fixed.
Function getPlayProgressEvent(callSource = "")
  playProgressEvent = invalid
  if m.playerPosition > m.lastPingTime

    viewTime = Int((m.playerPosition - m.lastPingTime) * 1000) 'ms

    playProgressEvent = {
      type: "play_progress"
      values: {
        video_id: m.Video.content.id.toInt()
        position: Int(m.playerPosition * 1000) 'ms - without Int(), can return scientific notation, causing API error
        view_time: viewTime
        video_player: "DEFAULT"
      }
    }

    ''//::TODO:: Remove this block once the play_progress viewtime value exceeds 15000 issue fixed - added this for debugging purpose
    if viewTime >= 15000
      adState = m.top.adState
      videoInfo = {}
      videoInfo.adState = adState
      videoInfo.viewTime = viewTime.tostr()
      videoInfo.videoState = m.VideoState
      videoInfo.playerPosition = m.playerPosition
      videoInfo.previousPlayerPosition = m.previousPlayerPosition
      videoInfo.callSource = callSource
      videoInfo.previousCallSource = m.previousPlayProgressCallSource
      videoInfo.positionArr = m.positionArr
      logInfo(FormatJSON(videoInfo), "videoInfo", "view-time-exceeds")
    end if

    ' resetting m.positionArr everytime play progress event gets fires
    m.positionArr = []

    if m.top.isTrailer = true
      playProgressEvent.type = "trailer_play_progress"
    else
      playProgressEvent.values.playback_source = m.top.playbackSource.srcForAnalytic
    end if

    'nominal_speed will be added to the Connection message, rather than the PlayProgressEvent message,
    'but is still sent via this interface
    if m.Video.streamInfo <> invalid AND m.Video.streamInfo.measuredBitrate <> invalid
      'measuredBitrate appears to be reported in bits despite the documentation that it is kibibits
      measuredBitrate = Int(m.Video.streamInfo.measuredBitrate / 1000000) 'dividing by 10^6

      if measuredBitrate >= 0
        playProgressEvent.values.nominal_speed = measuredBitrate
      end if
    end if
  end if

  m.previousPlayProgressCallSource = callSource
  return playProgressEvent
End Function


'Determine the reason for the missed ad event
'@reason: string, possible values are autoPlay, exitDuringPlayback, exitBeforeResponse, exitBeforePlayback, exitAfterCuePointPassed
'
Function sendAdMissedEvent(reason)
  adMissedInfo = {
    reason: reason
    position: Int(m.playerPosition) * 1000 'ms
    cue_point: Int(m.top.adPosition) * 1000 'ms
  }

  if isAA(m.filledAdData) = true

    if m.filledAdData.adResponseTime <> invalid AND m.filledAdData.adResponseTime <> -1
      adMissedInfo.response_time = m.filledAdData.adResponseTime * 1000 'ms
    end if

    if m.filledAdData.adCount <> invalid AND m.filledAdData.adCount > 0
      adMissedInfo.ad_count = m.filledAdData.adCount
    end if

    if m.filledAdData.totalAdsDuration <> invalid AND m.filledAdData.totalAdsDuration > 0
      adMissedInfo.total_ads_duration = Int(m.filledAdData.totalAdsDuration) * 1000 'ms
    end if

  end if

  if isNonEmptyArray(m.positionArr) = true
    sPositionArr = []

    for each arr in m.positionArr
      sPositionArr.push(arr.toStr())
    end for

    adMissedInfo.message_map = { playerPositionArr: sPositionArr.join(",") }
  end if
  updatePlayerLogLib(m.playerLogLib, "fireAdMissedEvent", adMissedInfo)
End Function


Function fireBrowseWhileWatchingPlaybackSessionEndEvent()
  if m.playerLogLib <> invalid AND m.playerLogLib.didUserSeeBwwPeek = true
    isSeries = m.top.content <> invalid AND m.top.content.parentType = "series"
    playbackSource = m.playerLogLib.playbackSource
    isFromDeeplink = false
    if isAA(playbackSource) = true
      srcForAds = playbackSource.srcForAds
      isFromDeeplink = (srcForAds = m.constants.player.playbackOrigin.deeplink)
    end if
    data = {
      "openCount": m.playerLogLib.bwwOpenCount
      "didConvert": m.playerLogLib.bwwDidConvert
      "isSeries": isSeries
      "isDeeplink": isFromDeeplink
    }

    logInfo(FormatJson(data), "videoInfo", "browseWhileWatchingPlaybackSessionEnd")
  end if
End Function

