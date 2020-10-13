Library "Roku_Ads.brs"

Function init()
  m.top.functionName = "execAdsSSAITask"
  m.top.control = "RUN"
End Function


Function execAdsSSAITask()
  m.constants = m.global.constants

  'a port used for sending requests
  m.ssaiPort = CreateObject("roMessagePort")
  m.request = TubiRequest(m.constants.settings.mode)
  requestQueueLib = TubiRequestQueue()
  m.requestQueue = requestQueueLib.create(m.ssaiPort)

  auth = TubiAuth(m.constants, m.request)
  m.tracking = TubiTracking(m.constants, m.request, auth)

  log = TubiLogger(m.constants, m.request, auth)
  m.adLib = TubiAds(m.constants, log, m.request, requestQueueLib, auth, m.tracking, "mp4")
  m.raf = m.adLib.roAdFramework

  ' used to determine when to poll for ads
  m.timeSpan = CreateObject("roTimespan")
  m.pollFrequency = 3000 'in ms

  ' indicates if the video player is playing the video in a full screen or not
  m.videoIsFullscreen = false

  ' indicates if the current stream is displaying ads
  m.top.isPlayingAds = false

  ' indicates if the current stream is displaying filler video because there are no ads to play
  m.top.isPlayingAdFiller = false

  ' used to keep track of which ad in the ad break/pod is currently being played in the stream
  m.currentAdInPod = -1

  ' used to keep track of the playback position within each ad. This is needed because ads can
  ' have multiple segments, but ID3 tags only give us the position within a sinlge segment.
  m.positionWithinAd = 0

  ' ad pod as returned by raf.getAds()[0]
  ' see https://developer.roku.com/en-gb/docs/developer-program/advertising/integrating-roku-advertising-framework.md#ad-structure
  m.adPod = {}
  
  runSSAILoop(constants, m.ssaiPort)
End Function


Function runSSAILoop(constants, ssaiPort)
  tubiLog("AdsSSAITask.runSSAILoop")
  m.top.observeField("pollUrl", ssaiPort)
  m.top.observeField("videoPosition", ssaiPort)
  m.top.observeField("id3Tags", ssaiPort)
  m.top.observeField("contentUpdated", ssaiPort)
  m.top.observeField("exit", ssaiPort)

  ' in the case that content is set on the task before it is ready, run the content callback
  if m.top.content <> invalid
    onContentUpdated(m.top.content)
  end if

  while true
    msg = wait(0, ssaiPort)

    if type(msg) = "roSGNodeEvent"
      if msg.getField() = "pollUrl"
        onPollUrlChange(msg)
      else if msg.getField() = "videoPosition"
        onVideoPosition(msg)
      else if msg.getField() = "id3Tags"
        onTags(msg)
      else if msg.getField() = "updateContent"
        content = m.top.content
        onContentUpdated(content)
      else if msg.getField() = "videoIsFullscreen"
        m.videoIsFullscreen = msg.getData()
      else if msg.getField() = "exit"
        ' send ad analytics events if necessary when the user exits playback
        if m.top.isPlayingAds = true
          if m.adPod <> invalid and m.adPod.ads <> invalid and m.adPod.ads[m.currentAdInPod] <> invalid
            ad = m.adPod.ads[m.currentAdInPod]
            sendFinishAdAnalytics(ad, "DELIBERATE")
          end if
        end if

        ssaiPort = invalid
        m.top.control = "STOP"
        exit while
      end if
    end if
  end while
End Function


Function onPollUrlChange(msg)
  tubiLog("AdsSSAITask.onPollUrlChange")
  pollUrl = msg.getData()
  if pollUrl <> invalid
    pollForAds(pollUrl)
  end if
End Function


Function pollForAds(url)
  if m.top.isPlayingAds <> true and m.top.isPlayingAdFiller <> true and url <> invalid and url <> ""
    m.raf.setAdUrl(url)
    adPods = m.raf.getAds()

    if adPods <> invalid and adPods.count() > 0
      if adPods[0].ads <> invalid
        m.adPod = adPods[0]

        ' parse out the YoSpace ad video id
        for each ad in m.adPod.ads
          adIdSplit = ad.adId.split("_YO_")
          if adIdSplit.count() > 1
            ad.adId = adIdSplit[0]
            ad.yospaceId = adIdSplit[1]
          end if
        end for
      end if
    end if
  end if

  m.timeSpan.mark()
End Function


Function onVideoPosition(msg)
  position = msg.getData()

  ' poll for ads if necessary
  if m.timeSpan.totalMilliseconds() >= m.pollFrequency
    pollForAds(m.top.pollUrl)
  end if
End Function


Function onTags(msg)
  tags = msg.getData()
  
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
  end if

  yospaceIdFromTag = id3s.getId()

  if id3s.currentSegment() = 1 and id3s.getType() = "start"
    ' we are at the very beginning of the ad video - update ad tracking state
    ' but only if there is ad metadata to report on.
    if m.adPod <> invalid and m.adPod.ads <> invalid and m.adPod.ads.count() > 0
      m.top.isPlayingAds = true
      m.currentAdInPod += 1
      ' send "Impression" ad pixels and StartAdEvent analytics
      handleStartAdTracking(yospaceIdFromTag)
    else
      m.top.isPlayingAdFiller = true
    end if
  else if id3s.getType() = "start"
    ' we are at the start of a segment, but not the start of an ad video
    if m.adPod = invalid or m.adPod.ads = invalid or m.adPod.ads.count() = 0
      ' if playing ad filler, we set m.top.isPlayingAdFiller to false when a segment ends regardless if it
      ' is the end of the ad filler video or not. Therefore we need to set it back to true each time
      ' a segment starts.
      m.top.isPlayingAdFiller = true
    end if
  else if id3s.getType() = "end" and id3s.currentSegment() = id3s.totalSegments()
    ' we are at the very end of the ad
    
    ' send "Complete" ad pixels and FinishAdEvent analytics
    handleFinishAdTrackingOnComplete(yospaceIdFromTag)

    ' reset position for next ad in the pod
    m.positionWithinAd = 0

    ' determine if we need to reset our ad state
    if m.adPod = invalid or m.adPod.ads = invalid or m.adPod.ads.count() = 0
      ' no ad metadata returned, so reset the ad state because we can't tell from the current id3 tag
      ' how many ads are in the ad pod. Additional ads may continue to play in the stream.
      resetAdState()
    else if m.adPod <> invalid and m.adPod.ads <> invalid and m.currentAdInPod = m.adPod.ads.count() - 1
      ' we've reached the last segment in the last ad of the pod, so reset ad state
      resetAdState()
    end if
  else if id3s.getType() = "end"
    ' end of the segment, but there are still additional segments in the ad
    m.positionWithinAd += id3s.getPosition()

    ' fire any quartile or midpoint pixels as necessary
    if m.adPod <> invalid and m.adPod.ads <> invalid and m.adPod.ads[m.currentAdInPod] <> invalid
      ad = m.adPod.ads[m.currentAdInPod]
      fireMidPixels(ad, m.positionWithinAd, yospaceIdFromTag)
    end if
  else
    ' At the beginning of the segment, but not the first segment in the add.
    ' Or at a middle point of the segment.
    ' fire any quartile or midpoint pixels as necessary
    if m.adPod <> invalid and m.adPod.ads <> invalid and m.adPod.ads[m.currentAdInPod] <> invalid
      ad = m.adPod.ads[m.currentAdInPod]
      position = m.positionWithinAd + id3s.getPosition()
      fireMidPixels(ad, position, yospaceIdFromTag)
    end if
  end if
End Function


Function onContentUpdated(content)
  tubiLog("AdsSSAITask.onContentUpdated")

  ' add the ad parameters for the content. Back end will forward these parameters to YoSpace
  ' so that YoSpace can have them when YoSpace makes ad requests for SSAI
  adParams = m.adLib.getRainmakerParams(content)
  adParams.platform = m.constants.analyticsPlatform
  adParams.delete("coppa_enabled")
  
  ' not needed for rainmaker, but the yo.ac=true parameter informs yospace
  ' that we are doing client side ad pixel reporting and is necessary
  adParams["yo.ac"] = true
  
  newResource = {}
  
  if content.videoResources <> invalid 
    for each resource in content.videoResources
      if resource.type = m.constants.player.drmTypes.hlsv3
        if resource.url <> invalid
          newResource = resource
          newResource.url = m.request.addParamsToUrl(newResource.url, adParams)
        end if
        exit for
      end if
    end for
  end if

  ' pass the updated url back through output interface so video helpers can proceed with playing the video
  newResources = [newResource]
  m.top.videoResourcesWithAdParams = newResources

  ' set metadata on RAF
  m.raf.setContentGenre("")
  m.raf.setContentId(content.id)
End Function


Function fireMidPixels(ad, position, yospaceIdFromTag)
  pixelType = invalid
  if ad.duration <> invalid
    if position >= ad.duration * (1/4) and position < ad.duration * (1/2)
      pixelType = "FirstQuartile"
    else if position >= ad.duration * (1/2) and position < ad.duration * (3/4)
      pixelType = "Midpoint"
    else if position >= ad.duration * (3/4) and position < ad.duration
      pixelType = "ThirdQuartile"
    end if
  end if

  ' TODO, don't attempt to fire tracking event multiple times for the same pixelType
  ' (ie. only fire for FirstQuartile once - even though RAF protects against it, we should too).
  if ad.yospaceId = yospaceIdFromTag
    if pixelType <> invalid
      ctx = {
        type: pixelType
      }
      m.raf.fireTrackingEvents(ad, ctx)
    end if
  end if
End Function


Function resetAdState()
  ' reset task level values
  m.positionWithinAd = 0
  m.top.isPlayingAds = false
  m.top.isPlayingAdFiller = false
  m.currentAdInPod = -1
  m.adPod = {}
End Function


Function handleStartAdTracking(yospaceIdFromTag)
  if m.adPod <> invalid and m.adPod.ads <> invalid and m.adPod.ads[m.currentAdInPod] <> invalid
    ad = m.adPod.ads[m.currentAdInPod]

    ' verify as much as possible that the tracking corresponds to the correct ad.
    ' the limitation is that the yospaceId is a video file id and multiple ads in a pod can potentially
    ' have the same video file id.
    if ad.yospaceId = yospaceIdFromTag
      ' send impression and start ad pixels
      ctx = {
        type: "Impression"
      }
      m.raf.fireTrackingEvents(ad, ctx)
    
      ' send StartAdEvent tracking
      oneBasedAdIndex = m.currentAdInPod + 1
      analyticsCtx = getAnalyticsCtx(ad, oneBasedAdIndex, m.adPod.ads.count())
      startAdValues = {
        ad_started: m.tracking.getAnalyticsAd(analyticsCtx)  'Ad
        video_id: m.top.content.id
        exit_type: "AUTO" 'Reason enum
        is_fullscreen: m.videoIsFullscreen
      }
      m.tracking.trackUserEvent("start_ad", startAdValues, m.requestQueue)
    end if
  end if
End Function


Function handleFinishAdTrackingOnComplete(yospaceIdFromTag)
  if m.adPod <> invalid and m.adPod.ads <> invalid and m.adPod.ads[m.currentAdInPod] <> invalid
    ad = m.adPod.ads[m.currentAdInPod]

    ' verify as much as possible that the tracking corresponds to the correct ad.
    ' the limitation is that the yospaceId is a video file id and multiple ads in a pod can potentially
    ' have the same video file id.
    if ad.yospaceId = yospaceIdFromTag
      ' send 4th quartile/completed ad pixels
      ctx = {
        type: "Complete"
      }
      m.raf.fireTrackingEvents(ad, ctx)

      ' send FinishAdEvent tracking
      sendFinishAdAnalytics()
    end if
  end if
End Function


Function sendFinishAdAnalytics(exitType = "AUTO")
  if m.adPod <> invalid and m.adPod.ads <> invalid and m.adPod.ads[m.currentAdInPod] <> invalid
    ad = m.adPod.ads[m.currentAdInPod]

    ' send FinishAdEvent tracking
    oneBasedAdIndex = m.currentAdInPod + 1
    analyticsCtx = getAnalyticsCtx(ad, oneBasedAdIndex, m.adPod.ads.count())
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
' TubiAds.adTrackingCallback(), plus the ammended pieces that are added in TubiAds.enhanceCtx()
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
' @index: integer, the position of the ad within the ad pod
' @podCount: integer, the number of ads within the ad pod
Function getAnalyticsCtx(ad, index, podCount)
  ' Currently RAF does not parse and store the id attribute of the MediaFile tag in the VAST response.
  ' We do not expect to be able to send the adVideoId until RAF begins parsing it.
  if ad.streams <> invalid and ad.streams[0] <> invalid
    ad.adVideoId = ad.streams[0].id
  end if

  analyticsCtx = {
    adIndex: index
    adCount: podCount
    ad: ad
  }

  return analyticsCtx
End Function