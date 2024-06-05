Library "Roku_Ads.brs"

Function init()
  m.top.functionName = "execAdsSSAITask"
  m.top.control = "RUN"
  m.pollUrl = ""
  ' indicates whether yospace or apollo ssai been used.
  m.ssaiUsed = "yospace"
  ' indicates if the current stream is displaying ads
  m.isPlayingAds = false
  ' Below field is currently not used anywhere outside the file so not exposing it as interface field.
  ' Will add interface field when we have a use case.
  ' indicates if the current stream is displaying filler video because there are no ads to play
  m.isPlayingAdFiller = false
End Function


Function execAdsSSAITask()
  m.constants = getConstantsFromGlobal()

  'a port used for sending requests
  m.ssaiPort = CreateObject("roMessagePort")
  m.request = TubiRequest(m.constants.settings)
  requestQueueLib = TubiRequestQueue()
  m.requestQueue = requestQueueLib.create(m.ssaiPort)

  auth = TubiAuth(m.constants, m.request)
  userConsentsOptOutStatus = m.top.userConsentsOptOutStatus
  m.tracking = TubiTracking(m.constants, m.request, auth, userConsentsOptOutStatus)
  gdpr = isGDPR(m.constants)
  m.adLib = TubiAds(m.constants, m.request, requestQueueLib, auth, m.tracking, "mp4", m.top.tcfString, userConsentsOptOutStatus, gdpr)
  m.raf = m.adLib.roAdFramework

  ' used to determine when to poll for ads
  m.timeSpan = CreateObject("roTimespan")
  m.pollFrequency = 3000 'in ms

  ' indicates if the video player is playing the video in a full screen or not
  m.videoIsFullscreen = false

  ' used to keep track of which ad in the ad break/pod is currently being played in the stream.
  ' will contain an AA of as single ad as extracted from the parsed VAST response from yospace/apollo.
  m.currentAdInPod = invalid

  ' used to keep track of the playback position within each ad. This is needed because ads can
  ' have multiple segments, but ID3 tags only give us the position within a single segment.
  m.positionWithinAd = 0

  ' ad pod as returned by raf.getAds()[0]
  ' see https://developer.roku.com/en-gb/docs/developer-program/advertising/integrating-roku-advertising-framework.md#ad-structure
  m.adPod = {}

  ' the playback position at the last time an event was fired due to an update on the id3Tags field
  ' If x amount of playback has occurred since the last tag, it can be assumed that we are no longer
  ' playing ads and the ad state should be reset. Protects against the event for the final id3 tag
  ' of an ad break not being recorded.
  m.positionAtLastId3 = -1

  ' store the last known video position, needed for various calculations
  m.videoPosition = -1

  ' holds the state of which impressions have been sent for a given ad.
  ' Only one key is ever expected to be held in the AA at any given time.
  ' The yospace/apollo structure is as follows:
  ' {
  '   <<ssaiAdId>>: {
  '                       "0percent": <<boolean>>
  '                       "25percent": <<boolean>>
  '                       "50percent": <<boolean>>
  '                       "75percent": <<boolean>>
  '                       "100percent": <<boolean>>
  '                    }
  ' }
  '

  m.pixelRecordForAd = {}

  runSSAILoop(m.ssaiPort)
End Function


Function runSSAILoop(ssaiPort)
  tubiLog("AdsSSAITask.runSSAILoop")
  m.top.observeField("pollUrlAA", ssaiPort)
  m.top.observeField("videoPosition", ssaiPort)
  m.top.observeField("id3Tags", ssaiPort)
  m.top.observeField("contentUpdated", ssaiPort)
  m.top.observeField("playbackStopped", ssaiPort)
  m.top.observeFieldScoped("userConsentsOptOutStatus", ssaiPort)
  m.top.observeField("exit", ssaiPort)

  while true
    msg = wait(0, ssaiPort)

    if type(msg) = "roSGNodeEvent"
      messageField = msg.getField()
      if messageField = "pollUrlAA"
        onPollUrlChange(msg)
      else if messageField = "videoPosition"
        onVideoPosition(msg)
      else if messageField = "id3Tags"
        onTags(msg)
      else if messageField = "videoIsFullscreen"
        m.videoIsFullscreen = msg.getData()
      else if messageField = "userConsentsOptOutStatus"
        userConsentsOptOutStatus = msg.getData()
        m.tracking.userConsentsOptOutStatus = userConsentsOptOutStatus
        m.adLib.userConsentsOptOutStatus = userConsentsOptOutStatus
        m.adLib.setLimitAdTracking(userConsentsOptOutStatus[m.constants.consentKeys.personalization])
      else if messageField = "tcfString"
        m.adLib.tcfString = msg.getData()
      else if messageField = "playbackStopped"
        if isArray(m.adPod.ads) = true then
          notUsedAction = "exit_mid_pod"
          if m.adPod.ads.count() = m.adLib.notUsedAdPodPixels.count() then
            ' If notUsedAdPodPixels count equals total ad pod count then we haven't played any at all so user exited before ad playback started
            notUsedAction = "exit_pre_pod"
          end if
          ' Resets m.adLib.notUsedAdPodPixels as well
          m.adLib.sendNotUsedAdPodPixels(notUsedAction)
        end if
        onPlaybackStopped()
      else if messageField = "exit"
        ' send ad analytics events if necessary when the user exits playback
        if m.isPlayingAds = true
          sendFinishAdAnalytics(m.currentAdInPod, "DELIBERATE")
        end if

        ssaiPort = invalid
        m.top.control = "STOP"
        exit while
      end if
    end if
  end while
End Function


' occurs when a new linear channel has been selected by the user.
Function onPollUrlChange(msg)
  tubiLog("AdsSSAITask.onPollUrlChange")
  pollUrlAA = msg.getData()

  if isAA(pollUrlAA) = true
    m.pollUrl = pollUrlAA.pollUrl
    m.ssaiUsed = pollUrlAA.ssaiUsed

    ' old ad state may persist if a user changes channels in the middle of an ad, so reset ad state
    ' once we get a new poll url (can be invalid for certain channels that do not have ads yet),
    ' which indicates a new stream is starting.
    resetAdState()

    if m.pollUrl <> invalid
      pollForAds(m.pollUrl)
    end if
  end if
End Function


Function pollForAds(url)
  if isNonEmptyString(url) = true AND m.isPlayingAds <> true AND m.isPlayingAdFiller <> true then
    ' Retrieves ads and also sets m.notUsedAdPodPixels
    adPods = m.adLib.retrieveAds(url, m.ssaiUsed)
    if adPods <> invalid AND adPods.count() > 0
      if adPods[0].ads <> invalid
        m.adPod = adPods[0]

        ' parse out the YoSpace/apollo ad video id
        for i = 0 to m.adPod.ads.count() - 1
          ad = m.adPod.ads[i]

          if m.ssaiUsed = "yospace"
            adIdSplit = ad.adId.split("_YO_")
          else
            adIdSplit = ad.adId.split("_AP_")
          end if

          if adIdSplit.count() > 1
            ad.adId = adIdSplit[0]
            ad.ssaiId = adIdSplit[1]
          end if

          ' add the sequence of the ad within the pod for future reference
          ad.sequence = i + 1
        end for
      end if
    end if
  end if

  m.timeSpan.mark()
End Function


Function onVideoPosition(msg)
  ' poll for ads if necessary
  if m.timeSpan.totalMilliseconds() >= m.pollFrequency
    pollForAds(m.pollUrl)
  end if

  position = msg.getData()

  if m.positionAtLastId3 >= 0 AND position > m.positionAtLastId3 + 60
    ' no id3 have been sent in over 1 minute of playback, so reset ad state as safety in case
    ' the id3 tag for the final segment of the final ad was not observed, and ad state was
    ' not reset as expected
    resetAdState()
  end if

  m.videoPosition = position
End Function


Function onTags(msg)
  tags = msg.getData()

  if m.ssaiUsed = "apollo"
    parseApolloId3(tags)
  else
    parseYoSpaceId3(tags)
  end if
End function


Function parseYoSpaceId3(tags)
  ' decipher tags
  id3s = yoSpaceId3s()
  if (tags.Count() = 6) then
    for each tag in tags
      if (len(tag) = 4) then
        hex = tags[tag]
        parsed = ""

        for i = 3 to len(hex) step 2
          pair = mid(hex, i, 2)
          parsed = parsed + chr(val(pair, 16))
        end for

        id3s.setTag(tag, parsed)
      end if
    end for

    m.positionAtLastId3 = m.videoPosition
  end if

  ssaiIdFromTag = id3s.getId()

  if m.currentAdInPod = invalid OR m.currentAdInPod.ssaiId <> ssaiIdFromTag
    ' the id3 tag is for a different ad than what we have stored currently,
    ' so update state for the new ad
    m.currentAdInPod = getAdFromSsaiAdId(ssaiIdFromTag, m.adPod)
    m.positionWithinAd = 0
  end if

  if id3s.currentSegment() = 1 AND id3s.getType() = "start"
    ' we are at the very beginning of an ad video
    if m.currentAdInPod <> invalid
      updateNowPlaying("ad")
      ' send "Impression" ad pixels and StartAdEvent analytics
      handleStartAdTracking()
    else
      updateNowPlaying("filler")

    end if
  else if id3s.getType() = "start"
    ' we are at the start of a segment, but not the first segment an ad video
    if m.currentAdInPod <> invalid
      updateNowPlaying("ad")

      ' handle mid quartile tracking - will also send unsent pixels for earlier points in the ad
      handleMidPixels(m.positionWithinAd)
    else
      updateNowPlaying("filler")
    end if
  else if id3s.getType() = "end" AND id3s.currentSegment() = id3s.totalSegments()
    ' we are at the very end of an ad

    if m.currentAdInPod <> invalid
      ' send "Complete" ad pixels and FinishAdEvent analytics
      handleFinishAdTrackingOnComplete()

      if isLastAdInPod(ssaiIdFromTag, m.adPod) = true
        ' we've reached the last segment in the last ad of the pod, so reset ad state
        resetAdState()
      end if
    else
      ' we've reached the end of an ad filler video
      resetAdState()
    end if
  else if id3s.getType() = "end"
    ' end of the segment, but there are still additional segments in the ad
    m.positionWithinAd += id3s.getPosition()

    ' fire any quartile or midpoint pixels as necessary
    if m.currentAdInPod <> invalid
      handleMidPixels(m.positionWithinAd)
    else
      ' filler ads can be stopped at the end of any segment, not only when the final segment in the filler
      ' video concludes. This means we need to set isPlayingAdFiller false after each filler segment ends
      ' as we don't know if the next segment will be filler video. We will set isPlayingAdFiller back to true
      ' at the start of the next segment, if it is a filler video segment.
        updateNowPlaying("content")
    end if
  else if id3s.getType() = "middle"
    ' At a middle point of a segment (there can be multiple middle points per segment).
    ' fire any quartile or midpoint pixels as necessary
    if m.currentAdInPod <> invalid
      updateNowPlaying("ad")
      position = m.positionWithinAd + id3s.getPosition()
      handleMidPixels(position)
    else
      updateNowPlaying("filler")
    end if
  end if
End Function


Function parseApolloId3(tags)
  tubiLog("AdsSSAITask.parseApolloId3")
  id3s = apolloId3s()
  ' tubi ID3 tags are coming in batch of 4 or 5 and tags will have 4 letters like TPOS, TSEQ etc
  if (tags.Count() >= 4) then
    for each tag in tags
      if (len(tag) = 4) then
        value = tags[tag]
        id3s.setTag(tag, value)
      end if
    end for

    m.positionAtLastId3 = m.videoPosition
  end if

  ssaiIdFromTag = id3s.getId()

  if m.currentAdInPod = invalid OR m.currentAdInPod.ssaiId <> ssaiIdFromTag
    ' the id3 tag is for a different ad than what we have stored currently,
    ' so update state for the new ad
    m.currentAdInPod = getAdFromSsaiAdId(ssaiIdFromTag, m.adPod)
  end if

  ' adPercent retrieved from AdInfo related ID3 tags. The valus represent ad completion in percentage - 0, 25, 50, 75 and 100
  adPercent = id3s.getAdPercent()
  adType = id3s.getAdType()

  if id3s.currentSegment() > 0
    if m.currentAdInPod <> invalid AND adType = "a"
      updateNowPlaying("ad")
    else if adType = "f"
      updateNowPlaying("filler")
    end if

  else if adPercent = 0
    if m.currentAdInPod <> invalid AND adType = "a"
      'setting the playing ads and filler status because we are not sure if the position tag will come first or the segment tag.
      updateNowPlaying("ad")

      handleStartAdTracking()
    else if adType = "f"
      updateNowPlaying("filler")
    end if

  else if adPercent = 25 OR adPercent = 50 OR adPercent = 75
    if m.currentAdInPod <> invalid AND adType = "a"
      updateNowPlaying("ad")

      handleMidApolloPixels(adPercent)
    else if adType = "f"
      updateNowPlaying("filler")
    end if
  else if adPercent = 100
    ' we are at the very end of an ad
    if m.currentAdInPod <> invalid AND adType = "a"
      ' send "Complete" ad pixels and FinishAdEvent analytics
      handleFinishAdTrackingOnComplete()

      'we are end of an ad pod
      if isLastAdInPod(ssaiIdFromTag, m.adPod) = true
        resetAdState()
      end if
    else if adType = "f"
      ' we've reached the end of an ad filler video
      resetAdState()
    end if

  end if

End Function


Function onPlaybackStopped()
  tubiLog("AdsSSAITask.onPlaybackStopped")
  if m.isPlayingAds = true AND m.currentAdInPod <> invalid
    ' log the number of impressions not fired for the ad break that is playing
    ' when the playback stops
    remainingAds = 0
    if haveStoredAds(m.adPod) = true AND m.currentAdInPod <> invalid
      remainingAds = m.adPod.ads.count() - m.currentAdInPod.sequence
    end if

    if remainingAds > 0
      contentId = ""
      if m.top.content <> invalid
        contentId = m.top.content.id
      end if

      logMsg = {
        content_id: contentId
        expected_missed_impressions: remainingAds
        ad_poll_url: m.pollUrl
      }
      logMsg = FormatJson(logMsg)
      tubiLog(logMsg, "info", "clientInfo", "linear-missed-impressions")
    end if
  end if
End Function


Function resetAdState()
  ' reset task level values
  m.positionWithinAd = 0
  updateNowPlaying("content")
  m.currentAdInPod = invalid 'will be populated with an ad AA taken from the ad pod parsed from the VAST response'
  m.adPod = {}
  m.positionAtLastId3 = -1
  m.pixelRecordForAd = {}
End Function


' @ad: assocArray, an ad as extracted from the ad pod AA created by RAF when parsing the VAST response
Function handleStartAdTracking()
  if m.currentAdInPod <> invalid

    ssaiAdId = m.currentAdInPod.ssaiId


    if m.pixelRecordForAd[ssaiAdId] = invalid
      ' add the pixel record state for the new ad
      newPixelRecord = getNewPixelRecord()
      m.pixelRecordForAd = formatPixelRecordForAd(ssaiAdId, newPixelRecord)
    end if

    pixelRecord = m.pixelRecordForAd[ssaiAdId]

    fireCurrentAndPreviousPixels(m.currentAdInPod, pixelRecord, 0)

    ' send StartAdEvent tracking
    analyticsCtx = getAnalyticsCtx(m.currentAdInPod, m.adPod.ads.count())

    ' Clear out notUsed pixel for the current ad since we sent an impression
    m.adLib.notUsedAdPodPixels.delete(m.currentAdInPod.sequence.toStr())

    startAdValues = {
      ad_started: m.tracking.getAnalyticsAd(analyticsCtx)  'Ad
      video_id: m.top.content.id
      exit_type: "AUTO" 'Reason enum
      is_fullscreen: m.videoIsFullscreen
    }

    m.tracking.trackUserEvent("start_ad", startAdValues, m.requestQueue)
  end if
End Function

' @adPercent - ad percent completion. value are 0, 25, 50, 75 and 100
Function handleMidApolloPixels(adPercent)
  ad = m.currentAdInPod

  if ad <> invalid
    ssaiAdId = ad.ssaiId

    if m.pixelRecordForAd[ssaiAdId] = invalid
      ' it would be unexpected to reach a quartile playback point within an ad and
      ' still not have the accurate pixel record, but could potentially happen if previous
      ' pixels didn't get fired due to missing id3 tags
      newPixelRecord = getNewPixelRecord()
      m.pixelRecordForAd = formatPixelRecordForAd(ssaiAdId, newPixelRecord)
    end if

    pixelRecord = m.pixelRecordForAd[ssaiAdId]

    quartile = adPercent / 100

    fireCurrentAndPreviousPixels(ad, pixelRecord, quartile)
  end if
End Function


Function handleMidPixels(position)
  ad = m.currentAdInPod

  if ad <> invalid
    ssaiAdId = ad.ssaiId

    if m.pixelRecordForAd[ssaiAdId] = invalid
      ' it would be unexpected to reach a quartile playback point within an ad and
      ' still not have the accurate pixel record, but could potentially happen if previous
      ' pixels didn't get fired due to missing id3 tags
      newPixelRecord = getNewPixelRecord()
      m.pixelRecordForAd = formatPixelRecordForAd(ssaiAdId, newPixelRecord)
    end if

    pixelRecord = m.pixelRecordForAd[ssaiAdId]

    quartile = 0
    if ad.duration <> invalid
      if position >= ad.duration * (1/4) AND position < ad.duration * (1/2)
        quartile = 0.25
      else if position >= ad.duration * (1/2) AND position < ad.duration * (3/4)
        quartile = 0.5
      else if position >= ad.duration * (3/4) AND position < ad.duration
        quartile = 0.75
      end if
    end if

    fireCurrentAndPreviousPixels(ad, pixelRecord, quartile)
  end if
End Function


Function handleFinishAdTrackingOnComplete()
  if m.currentAdInPod <> invalid

    ssaiAdId = m.currentAdInPod.ssaiId

    if m.pixelRecordForAd[ssaiAdId] = invalid
      ' it would be unexpected to reach the end of an ad and still not have the accurate
      ' pixel record, but could potentially happen if previous pixels didn't get fired
      ' due to missing id3 tags
      newPixelRecord = getNewPixelRecord()
      m.pixelRecordForAd = formatPixelRecordForAd(ssaiAdId, newPixelRecord)
    end if

    pixelRecord = m.pixelRecordForAd[ssaiAdId]

    ' send 4th quartile/completed ad pixels and any previous pixels from the ad that were not fired
    fireCurrentAndPreviousPixels(m.currentAdInPod, pixelRecord, 1.0)

    ' send FinishAdEvent tracking
    sendFinishAdAnalytics(m.currentAdInPod)
  end if
End Function


' Fires any pixels that were not fired up to and including the pixels for the maxQuartile.
' For instance, if 0% pixels were not fired and maxQuartile is 0.25, fireCurrentAndPreviousPixels()
' will fire both the 0% pixels and the 25% pixels. Checks are performed to make sure we don't
' send the same pixel multiple times.
'
' @ad: assocArray, an ad as returned by RAF.getAds()[0].ads[0]
' @pixelRecord: assocArray, an AA in the format returned by getNewPixelRecord()
' @maxQuartile: float, one of the following accepted values: 0, 0.25, 0.5, 0.75, 1.0
Function fireCurrentAndPreviousPixels(ad, pixelRecord, maxQuartile)
  quartiles = [
    0
    0.25
    0.5
    0.75
    1.0
  ]

  if isNumber(maxQuartile) = true
    if maxQuartile = 0 or maxQuartile = 0.25 or maxQuartile = 0.5 or maxQuartile = 0.75 or maxQuartile = 1.0
      for each quartile in quartiles
        if checkPixelRecord(pixelRecord, quartile) = false
          firePixels(ad, pixelRecord, quartile)
        end if

        if quartile = maxQuartile
          exit for
        end if
      end for
    end if
  end if
End Function


' @ad: assocArray, an ad as returned by RAF.getAds()[0].ads[0]
' @pixelRecord: assocArray, an AA in the format returned by getNewPixelRecord()
' @quartile: float, one of the following accepted values: 0, 0.25, 0.5, 0.75, 1.0
Function firePixels(ad, pixelRecord, quartile)
  if isNumber(quartile) = true AND isAA(ad) = true
    ctx = invalid

    if quartile = 0
      ctx = {
        type: "Impression"
      }
    else if quartile = 0.25
      ctx = {
        type: "FirstQuartile"
      }
    else if quartile = 0.50
      ctx = {
        type: "Midpoint"
      }
    else if quartile = 0.75
      ctx = {
        type: "ThirdQuartile"
      }
    else if quartile = 1.0
      ctx = {
        type: "Complete"
      }
    end if

    if ctx <> invalid
      ' update the sent pixel state so we don't attempt to resend pixels later
      if ad.ssaiId <> invalid
        pixelRecord = markPixelsAsSent(pixelRecord, quartile)

        m.pixelRecordForAd = formatPixelRecordForAd(ad.ssaiId, pixelRecord)
      end if

      m.raf.fireTrackingEvents(ad, ctx)
    end if
  end if
End Function


' @ad: assocArray, an ad as returned by RAF.getAds()[0].ads[0]
' @exitType: string, one of the valid exit types from protos
Function sendFinishAdAnalytics(ad, exitType = "AUTO")
  if m.adPod <> invalid AND m.adPod.ads <> invalid

    ' send FinishAdEvent tracking
    analyticsCtx = getAnalyticsCtx(ad, m.adPod.ads.count())
    finishAdValues = {
      ad_finished: m.tracking.getAnalyticsAd(analyticsCtx)  'Ad
      video_id: m.top.content.id
      exit_type: exitType 'Reason enum
    }
    m.tracking.trackUserEvent("finish_ad", finishAdValues, m.requestQueue)
  end if
End Function


' Helper to populate the analyticsCtx that will get passed to m.tracking.getAnalyticsAd()
' The returned analyticsCtx should have the same format as the ctx that RAF passes to the
' TubiAds.adTrackingCallback(), plus the amended pieces that are added in TubiAds.enhanceCtx()
' ctx.adIndex
' ctx.adCount
' ctx.ad
' ctx.ad.adId
' ctx.ad.creativeId
' ctx.ad.creativeAdId
' ctx.ad.streams[0].url
' ctx.ad.adVideoId
' ctx.ad.duration
'
' @ad: assocArray, an ad as returned by RAF.getAds()[0].ads[0]
' @podCount: integer, the number of ads within the ad pod
Function getAnalyticsCtx(ad, podCount)
  ' Currently RAF does not parse and store the id attribute of the MediaFile tag in the VAST response.
  ' We do not expect to be able to send the adVideoId until RAF begins parsing it.
  if ad.streams <> invalid AND ad.streams[0] <> invalid
    ad.adVideoId = ad.streams[0].id
  end if

  analyticsCtx = {
    adIndex: ad.sequence
    adCount: podCount
    ad: ad
  }

  return analyticsCtx
End Function


' @ssaiAdId: string, a yospace/apollo ad id taken from the VAST response or id3 tag
' @adPod: array, an array of ads AAs as parsed by VAST
Function getAdFromssaiAdId(ssaiAdId, adPod)
  if isAA(adPod) = true AND isArray(adPod.ads) = true
    ' iterate over each ad in pod until ssaiAdId is found
    for each ad in adPod.ads
      if ad.ssaiId = ssaiAdId
        return ad
      end if
    end for
  end if

  return invalid
End Function


' @ssaiAdId: string, a ssai ad id taken from the VAST response or id3 tag
' @adPod: array, an array of ads AAs as parsed by VAST
Function isLastAdInPod(ssaiAdId, adPod)
  if haveStoredAds(adPod) = true
    ads = adPod.ads
    lastAdIndex = ads.count() - 1

    if lastAdIndex >= 0
      lastAd = ads[lastAdIndex]

      if lastAd.ssaiId = ssaiAdId
        return true
      end if
    end if
  end if

  return false
End Function


Function haveStoredAds(adPod)
  return adPod <> invalid AND adPod.ads <> invalid AND adPod.ads.count() > 0
End Function


' @pixelRecord: assocArray, an AA in the format returned by getNewPixelRecord()
' @quartile: float, one of the following accepted values: 0, 0.25, 0.5, 0.75, 1.0
' @returns: assocArray the pixelRecord AA that is passed in, with updated values
Function markPixelsAsSent(pixelRecord, quartile)
  if pixelRecord <> invalid AND isNumber(quartile) = true
    if quartile = 0 AND pixelRecord["0percent"] <> invalid
      pixelRecord["0percent"] = true
    else if quartile = 0.25 AND pixelRecord["25percent"] <> invalid
      pixelRecord["25percent"] = true
    else if quartile = 0.5 AND pixelRecord["50percent"] <> invalid
      pixelRecord["50percent"] = true
    else if quartile = 0.75 AND pixelRecord["75percent"] <> invalid
      pixelRecord["75percent"] = true
    else if quartile = 1.0 AND pixelRecord["100percent"] <> invalid
      pixelRecord["100percent"] = true
    end if
  end if

  return pixelRecord
End Function


' @returns: assocArray, keeps track if pixels for the various percentiles were sent yet
Function getNewPixelRecord()
  pixelRecord = {}
  pixelRecord["0percent"] = false
  pixelRecord["25percent"] = false
  pixelRecord["50percent"] = false
  pixelRecord["75percent"] = false
  pixelRecord["100percent"] = false

  return pixelRecord
End Function


' @pixelRecord: assocArray, an AA in the format returned by getNewPixelRecord()
' @quartile: float, one of the following accepted values: 0, 0.25, 0.5, 0.75, 1.0
' @returns: boolean, true if pixels for the passed in quartile have already been sent, false otherwise
Function checkPixelRecord(pixelRecord, quartile)
  if pixelRecord <> invalid AND isNumber(quartile) = true
    if quartile = 0
      return pixelRecord["0percent"]
    else if quartile = 0.25
      return pixelRecord["25percent"]
    else if quartile = 0.5
      return pixelRecord["50percent"]
    else if quartile = 0.75
      return pixelRecord["75percent"]
    else if quartile = 1.0
      return pixelRecord["100percent"]
    end if
  end if

  return false
End Function


' @ssaiAdId: string, a yospace/apollo adId taken from the VAST response or id3 tag
' @pixelRecord: assocArray, an AA in the format returned by getNewPixelRecord()
Function formatPixelRecordForAd(ssaiAdId, pixelRecord)
  pixelRecordForAd = {}

  if isAA(pixelRecord) = true AND isNonEmptyString(ssaiAdId) = true
    pixelRecordForAd[ssaiAdId] = pixelRecord
  end if

  return pixelRecordForAd
End Function


'@nowPlaying - string, what is currently playing. Values are ad = ad playing, content = channel content playing, filler = no ad just filler playing
Function updateNowPlaying(nowPlaying)
  if nowPlaying = "ad"
    m.isPlayingAds = true
    m.isPlayingAdFiller = false
  else if nowPlaying = "filler"
    m.isPlayingAdFiller = true
    m.isPlayingAds = false
  else if nowPlaying = "content"
    m.isPlayingAdFiller = false
    m.isPlayingAds = false
  end if

  m.top.nowPlaying = nowPlaying

End Function
