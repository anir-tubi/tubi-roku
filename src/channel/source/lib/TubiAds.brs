Function TubiAds (constants, log, request, requestQueue, auth, tracking, adContentType)
  'Add Support for Roku Advertising Framework
  roAdFramework = Roku_Ads()

  'set the preferences for the Roku Advertising Framework so we never use their ad server if our server returns no ads
  'set to 0 retries - 1 max request, even if there are no ads returned from our server
  roAdFramework.setAdPrefs(false, 1)
  if m.enableInPodStitching = true then
    roAdFramework.enableInPodStitching(true)
  end if

  'turn on Nielsen DAR API for the Roku Advertising Framework
  'this is mutually exclusive with Roku's own Global Audience Measurement API,
  'meaning only one audience measurement API can run at a time.
  roAdFramework.enableNielsenDAR(true)

  'set the Nielsen application id for Tubi TV
  roAdFramework.setNielsenAppId(constants.thirdParty.nielsen.rafToken)

  'turn on debug output for RAF
  roAdFramework.setDebugOutput(false)
  if constants.settings.mode = "qa" or constants.settings.mode = "staging"
    roAdFramework.setDebugOutput(true)
  end if

  'a port used for sending logging requests
  adLoggingPort = CreateObject("roMessagePort")

  if adContentType <> "hls" and adContentType <> "mp4"
    adContentType = "mp4"  ' safety fallback
  end if

  return {
    ' dependencies
    constants: constants
    auth: auth
    request: request
    log: log
    tracking: tracking

    ' private
    updateYouboraOptions: tubiAds_updateYouboraOptions
    requestQueue: requestQueue.create(adLoggingPort)
    roAdFramework: roAdFramework
    allAdUnitsList:[]
    totalAdBreakAds: 0
    commercialDuration : 0
    adPlaybackPos: 0
    isInteracting: false
    _: rodash()
    adContentType: adContentType  ' "hls" or "mp4"

    ' public
    reset: tubiAds_reset
    getAdsListViaRoku: tubiAds_getAdsListViaRoku
    hasAds: tubiAds_hasAds
    showCommercialBreakViaRoku: tubiAds_showCommercialBreakViaRoku
    cacheAdsList: tubiAds_cacheAdsList
    getCachedAdsList: tubiAds_getCachedAdsList
    getResumingPlayAds: tubiAds_getResumingPlayAds
    populateUrlRainmaker: tubiAds_populateUrlRainmaker
    getRainmakerParams: tubiAds_getRainmakerParams
    adBufferingCallback: tubiAds_adBufferingCallback
    adTrackingCallback: tubiAds_adTrackingCallback
    trackUserEvent: tubiAds_trackUserEvent
    getNielsenSessionId: tubiAds_getNielsenSessionId
    getNielsenStreamId: tubiAds_getNielsenStreamId
    getMd5Hash: tubiAds_getMd5Hash
    appMode: "DEFAULT_MODE"
  }
End Function


' returns a set of ad helper functions that can be used outside of TubiAds without invoking RAF
Function TubiAdsLimited(constants, auth)

  return {
    constants: constants
    auth: auth
    adContentType: "mp4"
    appMode: "DEFAULT_MODE"

    getRainmakerParams: tubiAds_getRainmakerParams
    getRainmakerParamsForLinear: tubiAds_getRainmakerParamsForLinear
    getNielsenPingRequestInfo: tubiAds_getNielsenPingRequestInfo
    getNielsenSessionId: tubiAds_getNielsenSessionId
    getNielsenStreamId: tubiAds_getNielsenStreamId
    getMd5Hash: tubiAds_getMd5Hash
  }
End Function


' ----------------------------------------------
'  m.hasAds()
' Call to see if an ad preload found some ads to play
'
' @allAdUnitsList: array, an array of adUnitListContainer AAs with the form
'                  [
'                     {
'                        type: ""
'                        adUnitsList: [
'                          {
'                             viewed: currentAdUnitsList[0].viewed
'                             renderSequence: m._.cond(episode.nowPos > 0, "midroll", "preroll")
'                             duration: currentAdUnitsList[0].duration
'                             renderTime: currentAdUnitsList[0].renderTime
'                             ads: []
'                          }
'                        ]
'                     }
'                   ]
'
' ----------------------------------------------
Function tubiAds_hasAds(allAdUnitsList)
  hasAds = false
  if allAdUnitsList <> invalid and allAdUnitsList.count() > 0
    firstAdUnitsListContainer = m.allAdUnitsList[0]
    if firstAdUnitsListContainer.adUnitsList <> invalid and firstAdUnitsListContainer.adUnitsList.count() > 0
      adUnitsList = firstAdUnitsListContainer.adUnitsList[0]
      if adUnitsList.ads <> invalid and adUnitsList.ads.count() > 0
        hasAds = true
      end if
    end if
  end if

  return hasAds
End Function

' ----------------------------------------------
'  m.reset()
'
'  call when starting a content video to
'  clear everything out
' ----------------------------------------------
Function tubiAds_reset()
  m.allAdUnitsList = []
  m.commercialDuration = 0
  m.containerNode = invalid
  m.adPlaybackPos = 0
  m.isInteracting = false
End Function


' ----------------------------------------------
' cacheAdsList
'
' cache an ads list for an ad break - typically occurs 4-7 seconds before an ad break actually runs
' we keep the most recently cached ad break at m.lastAdsList
' ----------------------------------------------
Function tubiAds_cacheAdsList(episode, breakPos)
  if(m.lastAdsList = invalid or m.lastAdsList.breakPos <> breakPos or m.lastAdsList.cid <> episode.adrise_contentId)
    m.getAdsListViaRoku(episode, breakPos)

    list = invalid
    if m.hasAds(m.allAdUnitsList) = true
      list = m.allAdUnitsList
    end if

    m.lastAdsList = {
      cid: episode.id
      breakPos: breakPos
      list: list
    }
  end if
End Function

' ----------------------------------------------
' getCachedAdsList
' ----------------------------------------------
Function tubiAds_getCachedAdsList(episode, breakPos)
  if m.lastAdsList <> invalid and episode.id = m.lastAdsList.cid and breakPos = m.lastAdsList.breakPos
    return m.lastAdsList.list
  end if
  return invalid
End Function


' ----------------------------------------------
' populateUrlRainmaker
'
' create the url needed to make ad calls using the rainmaker API
' For API details, please see https://tubitv.atlassian.net/wiki/spaces/EC/pages/863273074/Rainmaker+-+Request+Parameters
' ----------------------------------------------
' @episode: node, TubiContentNode for a video (movie or episode)
' @breakPos: integer, the preroll or midroll playback position at which the break occurs
Function tubiAds_populateUrlRainmaker(episode, breakPos = 0) As String
  params = m.getRainmakerParams(episode, breakPos)
  baseUrl = m.constants.urls.adsBaseUrlRainmaker + m.constants.analyticsPlatform
  paramAddedUrl = m.request.addParamsToUrl(baseUrl, params)
  return m.request.passThroughCharlesProxy(paramAddedUrl)
End Function


' returns an assocArray of all parameters that should be sent to rainmaker
' @content: node, TubiContentNode for a video (movie or episode)
' @breakPos: integer, the preroll or midroll playback position at which the break occurs
Function tubiAds_getRainmakerParams(content, breakPos = 0)
  params = {
    content_id: content.id
    pub_id: content.pubId
    now_pos: breakPos.ToStr()
    content_type: m.adContentType
    device_id: m.constants.deviceInfo.deviceId
    model: m.constants.deviceInfo.model
    app_id: m.constants.settings.shortAppName
    language: m.constants.deviceInfo.language
    coppa_enabled: (m.appMode = "KIDS_MODE")
    app_mode: m.appMode
    client_version: m.constants.deviceInfo.clientVersion
    nsid: m.getNielsenSessionId(m.constants)

    ' the dubug parameter must be set to 1 in order to use the following "limit" parameters for testing
    ' limit_to_campaign_id: 0   'only allow ads with that particular campaign id through the pre-qual filters
    ' limit_to_lineitem_id: 0   'only allow ads with that particular line item id through the pre-qual filters
    ' limit_to_creative_id: 0   'only allow ads with that particular campaign id through the pre-qual filters
    ' debug: 0    'set to 1 in order to use the "limit" parameters above
  }

  '//send sponored exposure value if the user call this video from a spnsored contaner.
  if content.videoSponsorExposureId <> invalid and content.videoSponsorExposureId <> ""
    params["spon_exp"] = content.videoSponsorExposureId
  end if

  ' add Roku Advertiser Id (RIDA) to ad call url
  if m.constants.deviceInfo.deviceAdId <> invalid
    params["adv_id"] = m.constants.deviceInfo.deviceAdId
  end if

  if m.constants.deviceInfo.isAdIdTrackingDisabled = true
    params["opt_out"] = "true"
  else
    params["opt_out"] = "false"
  end if

  'add TubiTV user/registration id to ad call url
  authInfo = m.auth.getAuthInfo()
  if authInfo <> invalid and authInfo.userId <> invalid
    params["user_id"] = authInfo.userId
  end if

  return params
End Function


Function tubiAds_getRainmakerParamsForLinear(content)
  params = m.getRainmakerParams(content, 0)
  params.platform = m.constants.analyticsPlatform
  params.delete("coppa_enabled")
  params.delete("nsid")

  ' not needed for rainmaker, but the yo.ac=true parameter informs yospace
  ' that we are doing client side ad pixel reporting and is necessary
  params["yo.ac"] = true
  return params
End Function


' ----------------------------------------------
'  m.getAdsListViaRoku(episode, breakPos)
' ----------------------------------------------
' @episode: node, TubiContentNode for a video (movie or episode)
' @breakPos: integer, the preroll or midroll playback position at which the break occurs
Function tubiAds_getAdsListViaRoku(episode, breakPos)
  m.allAdUnitsList = []

  nielsenGenres = "" 'nielsenGenres may be set as an array of strigs later
  nielsenProgramId = ""

  authInfo = m.auth.getAuthInfo()

  ' don't pass content information for child directed content if the user is not logged in
  if episode.isCdc = false or (authInfo <> invalid and authInfo.userId <> invalid)
    nielsenGenres = ["GV"] 'default Nielsen genre in case backend didn't associate any with this content

    'set the content genre (as stated in RAF documentation for Nielsen functionality)
    if episode.rokuGenres <> invalid and episode.rokuGenres.count() > 0
      nielsenGenres = episode.rokuGenres
    end if

    'set the program id/title (as stated in RAF documentation for Nielsen functionality)
    if episode.parentType = m.constants.ui.contentTypes.series and episode.parentTitle <> invalid
      nielsenProgramId = episode.parentTitle
    else if episode.title <> invalid
      nielsenProgramId = episode.title
    end if
  end if

  m.roAdFramework.setNielsenGenre(nielsenGenres)
  m.roAdFramework.setNielsenProgramId(nielsenProgramId)

  'get the url for making the ad call
  rainmakerVastUrl = m.populateUrlRainmaker(episode, breakPos)

  adFetchTimer = createObject("roTimeSpan")
  currentAdUnitsList = invalid

  ' RAF has a hard 5 second cutoff for download time.
  ' We make the network request to rainmaker ourselves to work around this.
  tubiReq = m.request.createAsync(rainmakerVastUrl)
  port = createObject("roMessagePort")
  if tubiReq.start(port) = true then
    timeout = 10000 ' in milliseconds
    msg = wait(timeout, port)
    if type(msg) = "roUrlEvent" then
      responseCode = msg.getResponseCode()
      if responseCode >= 200 AND responseCode < 400 then
        ' If we got a valid result write it to tmp and then have RAF read it from there
        rainmakerResponse = msg.getString()
        localRafVastUrl = "tmp:/local_raf_vast.xml"
        if writeAsciiFile(localRafVastUrl, rainmakerResponse) = true then
          m.roAdFramework.setAdUrl(localRafVastUrl)
          'get the array of ad units back from the Roku Advertising Framework(RAF)
          'adUnits are called adPods in RAF documentation
          currentAdUnitsList = m.roAdFramework.getAds()
        else
          tubiLog("Failed to write local vast response to " + localRafVastUrl)
        end if
        deleteFile(localRafVastUrl)
      end if
    end if
  end if
  timeToFetch = adFetchTimer.totalMilliseconds()

  'log ad fetch errors
  if currentAdUnitsList = invalid
    timeToFetchMessage = {
      message: "RAF got no response"
      call_duration: timeToFetch
      raf_version: m.roAdFramework.getLibVersion()
      ad_url: rainmakerVastUrl
    }
    m.log.error(FormatJSON(timeToFetchMessage), "adError", "no-ad-response", m.requestQueue)
  end if

  'check to see if the ad server returns an ad that can be used by RAF or needs to use our ad SDK
  'traditional version of xml is in the clickThrough property/clickThrough VAST tag
  'traditional is used if adId of the first ad object in the first ad pod is set equal to 'default'
  if currentAdUnitsList <> invalid and currentAdUnitsList.count() > 0 and currentAdUnitsList[0] <> invalid and currentAdUnitsList[0].ads <> invalid and currentAdUnitsList[0].ads.count() > 0
    adUnitType = "" 'keeps track of what kind adUnitsList/adPod is currently being built by the for loop - can be "adrise" or "roku"

    'set up the duration for use by the adRise pre ad splash screen
    if currentAdUnitsList[0].duration <> invalid and currentAdUnitsList[0].duration > 0
        m.commercialDuration = m.commercialDuration + currentAdUnitsList[0].duration
    end if

    adUnitsListContainer = {
      type: ""
      adUnitsList: []
    }

    'save the total number of ads in the adbreak before we (potentially) start breaking them up into different ad unit lists
    m.totalAdBreakAds = currentAdUnitsList[0].ads.count()

    for each adUnit in currentAdUnitsList[0].ads

      if adUnit.adId <> invalid
        if m.constants.settings.mode = "qa" or m.constants.settings.mode = "staging"
          print "AD ID "; adUnit.adId; " "; adUnit.creativeAdId
        end if

        if adUnit.adId <> "empty"
          'if adUnitType is different from the last adUnitType (meaning a new adUnitsListContainer is needed)
          'push the last adUnitsListContainer to m.allAdUnitsList, otherwise we will just add to the last adUnitsListContainer
          'set up the adContainer for roku type if needed
          if adUnitType <> "roku"
            if adUnitsListContainer.type <> "" 'means we've already built at least one adUnitsListContainer
              m.allAdUnitsList.push(adUnitsListContainer)
            end if
            adUnitType = "roku"
            adUnitsListContainer = {
              type: adUnitType
              adUnitsList: [
                {
                  viewed: currentAdUnitsList[0].viewed
                  renderSequence: m._.cond(episode.nowPos > 0, "midroll", "preroll")
                  duration: currentAdUnitsList[0].duration
                  renderTime: currentAdUnitsList[0].renderTime
                  ads: []
                }
              ]
            }
          end if

          'make sure we have the appropriate stream format. if stream format is mp4, but file is an HLS, the ad won't play
          for each stream in adUnit.streams
            if stream.url <> invalid and right(stream.url, 4) = "m3u8"
              adUnit.streamFormat = "hls"
            end if
          end for

          ' allow sending pixels via charles
          if m.constants.settings.mode <> "production"
            for each pixel in adUnit.tracking
              pixel.url = m.request.passThroughCharlesProxy(pixel.url)
            end for
          end if

          'add the roku ad unit to the adUnitsList in the current adUnitsListContainer
          adUnitsListContainer.adUnitsList[0].ads.push(adUnit)

          'add the duration to m.CommercialDuration for use in adRise pre ad splash screens (in case there are any)
          if currentAdUnitsList[0].duration = invalid or currentAdUnitsList[0].duration <= 0
            m.commercialDuration = m.commercialDuration + adUnit.duration
          end if
        end if
      end if
    end for

    m.allAdUnitsList.push(adUnitsListContainer) 'push the last adUnitsListContainer
    return m.allAdUnitsList
  else
    return invalid
  end if
End Function


' ----------------------------------------------
' showCommercialBreakViaRoku
'
' containerNode is any empty Group node under which RAF will create a child video node of its own, and
' remove it on completion of showAds()
' ----------------------------------------------
Function tubiAds_showCommercialBreakViaRoku(containerNode, controlNode)
  ' ShowVariable(m.allAdUnitsList, "ALL AD UNITS LIST", 4)
  scene = containerNode.getScene()
  m.youboraTask = scene.findNode("Youbora")  'created in ContentController.initVideoTracking

  if m.hasAds(m.allAdUnitsList) = true
    currentAdPosition = 1
    for each adUnitsListContainer in m.allAdUnitsList
      if adUnitsListContainer.adUnitsList <> invalid and adUnitsListContainer.adUnitsList.count() > 0
        if adUnitsListContainer.type <> invalid and adUnitsListContainer.type = "roku"

          'create the object that will populate the "Ad 1/5" text overlay in RAF
          screenCount = {
            start: currentAdPosition
            total: m.totalAdBreakAds
          }

          m.containerNode = containerNode
          m.containerNode.visible = false
          ' controlnode has progress bar
          m.controlnode = controlNode

          ' This should happen before any buffering.  We set this here because
          ' interactive ads don't have buffering callbacks and we don't want the
          ' loading bar to sit empty and look like nothing is happening.  It will
          ' also trigger the ads messaging to appear.
          m.controlNode.adProgress = 1
          m.controlNode.displayAdLoadingMessage = true

          ' Setting this is REQUIRED in order for setAdBufferRenderCallback to
          ' trigger callbacks.  The empty second argument just suppresses
          ' any ad buffering visual.
          m.roAdFramework.setAdBufferScreenLayer(2, [{}])
          ' Simple shim to make a global-scope callback into a module-scoped method call
          m.roAdFramework.setAdBufferRenderCallback(function(_m, eventType, ctx)
            ads = getGlobalAA().tubiAds
            ads.adBufferingCallback(eventType, ctx)
          end function, {}, 0)
          m.roAdFramework.setTrackingCallback(function(_m, eventType, ctx)
            ads = getGlobalAA().tubiAds
            ads.adTrackingCallback(eventType, ctx)
          end function, {})
          isCompleted = m.roAdFramework.showAds(adUnitsListContainer.adUnitsList[0], screenCount, containerNode)

          ' This will hide the buffering messaging and reset the progress bar
          ' before the video loading takes over status
          m.controlNode.adProgress = 0
          m.controlNode.displayAdLoadingMessage = false
          m.containerNode.visible = false
          m.containerNode = invalid
          m.controlNode = invalid

          if isCompleted = false
            tubilog("RAF ads not completed")
            return m.constants.player.playerResults.closed
          end if
          currentAdPosition = currentAdPosition + adUnitsListContainer.adUnitsList.count()
        end if
      end if
    end for
  end if

  return m.constants.player.playerResults.completed
End Function


' ----------------------------------------------
' getResumingPlayAds
'
' this function is to be called when resuming back to play after the player has stopped
' (usually due to the user pressing play or the user fast forwarding or rewinding). This function
' will make a call to the ads server and if it gets ads, store them in an appropriate place
' returns true if there are ads and false if there are no ads (aka the player can resume playing immediately without closing the player)
' SIDE EFFECT: updates the resumePlayAdsList property on the player object that is passed in
' (expect that the player object will be the main video player for the channel)
' ----------------------------------------------
Function tubiAds_getResumingPlayAds(episode, position)

  m.getAdsListViaRoku(episode, position)
  return m.hasAds(m.allAdUnitsList)
End Function

' ----------------------------------------------
' adBufferingCallback
'
' callback during RAF buffering. Will not be called if enableInPodStitching(true)
Function tubiAds_adBufferingCallback(eventType, ctx)
  ' We need to hide the raf container while we're buffering and show it again when buffering ends
  if eventType = "BufferingStart" AND ctx.adIndex > 1 then
    ' Avoiding a rendezvous by only doing on adIndex greater than 1 since we already hide the raf container there
    ' RebufferingStart will handle any subsequent buffer event during ad playback, including when adIndex = 1.
    m.containerNode.visible = false
  else if eventType = "ReBufferingStart" then
    m.containerNode.visible = false
  else if eventType = "BufferingEnd" OR eventType = "ReBufferingEnd" then
    m.containerNode.visible = true
  end if

  if ctx.progress <> invalid
    m.controlNode.adProgress = ctx.progress
  end if
End Function


' ------------------------------------
' adTrackingCallback
'
' callback during RAF ad display
Function tubiAds_adTrackingCallback(eventType, ctx)
  impressionCount = invalid
  youboraOptions = invalid

  if eventType <> invalid
    if ctx <> invalid
      '//make a subset of ctx and set it to m.controlNode.adTrackingObject
      adTrackingObject = {}
      if ctx.adcount <> invalid
        adTrackingObject.adcount = ctx.adcount
      end if
      if ctx.adindex <> invalid
        adTrackingObject.adindex = ctx.adindex
      end if
      if ctx.duration <> invalid
        adTrackingObject.duration = ctx.duration
      end if
      if ctx.rendersequence <> invalid
        adTrackingObject.rendersequence = ctx.rendersequence
      end if
      if ctx.type <> invalid
        adTrackingObject.type = ctx.type
      end if
      if m.controlNode <> invalid
        m.controlNode.adTrackingObject = adTrackingObject
      end if
    end if

    ' We have do the second check for start event because for Innovid interactive ads our Impression code block won't get called because m.adPlaybackPos is already 1. In other words, the position callback where ctx.time = 1 occurs prior to the Impression event for Innovid interactive ads.
    if (eventType = "Impression" and m.isInteracting <> true and m.adPlaybackPos = 0) OR (eventType = "Start" AND ctx.ad.adSystem.instr("Innovid") >= 0) then
      if getGlobalAA().enableInPodStitching = true then
        ' Storing ad context to work around RAF stitched ads bug that causes complete event to have data for next ad or invalid if it is the last ad
        if ctx.duration <> invalid AND ctx.ad <> invalid then
          m._lastContextWithValidDurationAndAdInfo = ctx
        end if
      else
        ' Without setting RAF container back to visible here interactive ads will not show because tubiAds_adBufferingCallback never gets called
        ' Not needed when stitched ads are enabled as AdStateChange properly gets called in that case
        m.containerNode.visible = true
      end if

      'Impression events fire when ads start, but also when a user begins interacting with an interactive ad
      startAdEvent = {
        ad_started: m.tracking.getAnalyticsAd(ctx)
        video_id: m.controlNode.content.id.toInt()
        start_position: 0
        is_fullscreen: true
      }
      m.trackUserEvent("start_ad", startAdEvent, m.requestQueue)

      impressionCount = 0
      for i=0 to ctx.ad.tracking.count()-1
        if ctx.ad.tracking[i].event = "Impression"
          impressionCount += 1
        end if
      end for
      youboraOptions = m.updateYouboraOptions(m.youboraTask, ctx, impressionCount)
    else if eventType = "Complete" or eventType = "Close"
      'Close events fire when a user backs out of an ad, or when a user backs out of the interactive portion of an ad
      if eventType = "Close" and m.isInteracting = true
        clickAdEvent = {
          ad_clicked: m.tracking.getAnalyticsAd(ctx)
          video_id: m.controlNode.content.id.toInt()
          position: m.adPlaybackPos
          ad_interaction: "CLOSE"
        }
        m.trackUserEvent("ad_click", clickAdEvent, m.requestQueue)
      else
        endPosition = invalid
        if eventType = "Complete"
            replacementCtx = m._lastContextWithValidDurationAndAdInfo
            m.delete("_lastContextWithValidDurationAndAdInfo")

          ' TODO When enableInPodStitching(true) is set the ad index is off which causes the wrong information or no information to be passed in ctx. We can pull these from the last position update for now until Roku fixes RAF to correctly return this. This was last tested in RAF version 3.0026. We can retest in the future once the next version comes out


          ' Do some basic verification to make sure this is for the same ad and pod
          if ctx.adServer = replacementCtx.adServer AND ctx.adCount = replacementCtx.adCount then
            ' Replace the information trying to match the expected ctx exactly as it normally would be
            ctxType = ctx.type
            ctx = replacementCtx
            ctx.delete("time")
            ctx.type = ctxType
          end if

          endPosition = ctx.duration
          ' Send exposure after first ad finishes in a multi ad break
          ' NOTE the complete event for the first ad actually has adIndex as 2 #roku :|
          if isFunction(getExperimentResource)  'bs:disable-line LINT1001
            if ctx.adCount <> invalid AND ctx.adCount > 1 AND ctx.adIndex <> invalid and ctx.adIndex = 2 then
              'bs:disable-next-line 1001 LINT1001
              getExperimentResource("roku_in_pod_stitching", "roku_in_pod_stitching_v1", true)
            end if
          end if
        else if eventType = "Close"
          endPosition = m.adPlaybackPos
        end if

        m.adPlaybackPos = 0
        if endPosition = invalid
          '//ensure a valid value is used. This may not happen during a close event.
          endPosition = 0
        end if

        finishAdEvent = {
          ad_finished: m.tracking.getAnalyticsAd(ctx)
          video_id: m.controlNode.content.id.toInt()
          end_position: endPosition * 1000
          reason: "DETECTED"
        }
        m.trackUserEvent("finish_ad", finishAdEvent, m.requestQueue)
        youboraOptions = m.updateYouboraOptions(m.youboraTask, ctx, impressionCount)
      end if
      m.isInteracting = false
    else if eventType = "AcceptInvitation"
      clickAdEvent = {
        ad_clicked: m.tracking.getAnalyticsAd(ctx)
        video_id: m.controlNode.content.id.toInt()
        position: m.adPlaybackPos
        ad_interaction: "OPEN"
      }
      m.trackUserEvent("ad_click", clickAdEvent, m.requestQueue)
      m.isInteracting = true
    else if eventType = "AdStateChange" then
      ' enableInPodStitching(true) makes this get called and tubiAds_adBufferingCallback not get called
      if ctx.state = "playing" then
        m.containerNode.visible = true '//Display ad
      else if ctx.state = "buffering" then
        m.containerNode.visible = false ' Hide ad while buffering
      end if
    end if
  else
    if ctx <> invalid then
      ' eventType is invalid when an event fires signaling that one second of ad playback has ocurred
      if ctx.time <> invalid then
        m.adPlaybackPos = ctx.time
      end if

      if ctx.duration <> invalid AND ctx.ad <> invalid then
        m._lastContextWithValidDurationAndAdInfo = ctx
      end if
    end if
  end if

  if m.youboraTask <> invalid
    if youboraOptions <> invalid
      m.youboraTask.options = youboraOptions
    end if
    m.youboraTask.adevent = ctx
  end if
End Function


Function tubiAds_updateYouboraOptions(youboraTask, ctx, impressionCount)
  youboraOptions = invalid

  if youboraTask <> invalid
    youboraOptions = youboraTask.options

    if ctx.ad <> invalid
      if ctx.ad.creativeAdId <> invalid and ctx.ad.creativeAdId <> ""
        youboraOptions["ad.extraparam.1"] = ctx.ad.creativeAdId
      end if

      if ctx.ad.streams <> invalid and ctx.ad.streams[0] <> invalid and ctx.ad.streams[0].id <> invalid
        youboraOptions["ad.extraparam.2"] = ctx.ad.streams[0].id
      end if

      if youboraOptions["ad.extraparam.1"] <> invalid and youboraOptions["ad.extraparam.2"] <> invalid
        youboraOptions["ad.extraparam.3"] = youboraOptions["ad.extraparam.1"] + "-" + youboraOptions["ad.extraparam.2"]
      end if

      if impressionCount <> invalid
        youboraOptions["ad.extraparam.4"] = impressionCount
      else
        youboraOptions.delete("ad.extraparam.4")
      end if
    end if
  end if

  return youboraOptions
End Function


' Wraps m.tracking.trackUserEvent() but adds the appropriate app mode value
Function tubiAds_trackUserEvent(eventType="", eventValues=invalid, requestQueue=invalid)
  if eventValues <> invalid
    eventValues.appMode = m.appMode
    m.tracking.trackUserEvent(eventType, eventValues, requestQueue)
  end if
End Function


' @constants: assocArray, constants as returned by getConstants()
' @pingType: string, one of the following "start_session", "start_stream", "end_session", "end_stream"
' @content: roSGNode, content node - only required for stream start and stream end pings
Function tubiAds_getNielsenPingRequestInfo(constants, pingType, content = invalid)
  sessionId = m.getNielsenSessionId(constants)

  pingValue = "0" 'default value for "start_session"
  streamId = ""
  if pingType = m.constants.thirdParty.nielsen.pingTypes.sessionStart
    pingValue = "0"
  else if pingType = m.constants.thirdParty.nielsen.pingTypes.streamStart
    pingValue = "1"
    streamId = m.getNielsenStreamId(constants, content)
  else if pingType = m.constants.thirdParty.nielsen.pingTypes.sessionEnd
    pingValue = "2"
  else if pingType = m.constants.thirdParty.nielsen.pingTypes.streamEnd
    pingValue = "3"
    streamId = m.getNielsenStreamId(constants, content)
  end if

  dateTime = CreateObject("roDateTime")
  nowTime = dateTime.AsSeconds()

  optOut = "1"
  if constants.deviceInfo.isAdIdTrackingDisabled = false
    optOut = "0"
  end if

  options = {
    params: {
      prd: "audit"
      apid: constants.thirdParty.nielsen.pingToken
      sessionid: sessionId
      pingtype: pingValue
      product: "dar"
      createtm: nowTime
      devid: constants.deviceInfo.deviceAdId
      uoo: optOut
      intid: constants.thirdParty.nielsen.intId
    }
    headers: {
      "Content-Type": "text/plain"
    }
  }

  if streamId <> ""
    options.params.streamid = streamId
  end if

  return {
    url: constants.urls.nielsenPing
    options: options
  }
End Function


' returns an md5 hash of the device id, RIDA, and firmware level ads info sharing opt in values,
' truncated to 16 characters.
Function tubiAds_getNielsenSessionId(constants)
  toHash = constants.deviceInfo.deviceId + constants.deviceInfo.deviceAdId + constants.deviceInfo.isAdIdTrackingDisabled.toStr()
  hashed = m.getMd5Hash(toHash)
  truncated = Left(hashed, 16)
  return truncated
End Function


' @constants: assocArray, constants as returned by getConstants()
' @content: roSGNode, a content node with an id
' @return: string an md5 hash of the device id and content id truncated to 16 characters
'          or an empty string if we can't get the content id
Function tubiAds_getNielsenStreamId(constants, content)
  streamId = ""
  if content <> invalid and content.id <> ""
    toHash = constants.deviceInfo.deviceId + content.id
    hashed = m.getMd5Hash(toHash)
    streamId = Left(hashed, 16)
  end if

  return streamId
End Function


' @strToHash: string, the string to be hashed
' @return: string, an md5 hash of the passed in value
Function tubiAds_getMd5Hash(strToHash)
  ba1 = CreateObject("roByteArray")
  ba1.FromAsciiString(strToHash)
  digest = CreateObject("roEVPDigest")
  digest.Setup("md5")
  return digest.Process(ba1)
End Function
