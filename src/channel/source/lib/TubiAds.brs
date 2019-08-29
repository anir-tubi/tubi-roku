function TubiAds (constants, log, request, requestQueue, auth, tracking, adContentType)
  'Add Support for Roku Advertising Framework
  roAdFramework = Roku_Ads()

  'set the preferences for the Roku Advertising Framework so we never use their ad server if our server returns no ads
  'set to 0 retries - 1 max request, even if there are no ads returned from our server
  roAdFramework.setAdPrefs(false, 1)
  
  'turn Nielsen DAR on for the Roku Advertising Framework
  roAdFramework.enableNielsenDAR(true)

  'set the Nielsen application id for Tubi TV
  roAdFramework.setNielsenAppId("PB8C78BDD-9B1B-4020-B4DD-AE7917C0F396")

  'turn on debug output for RAF
  roAdFramework.setDebugOutput(false)

  'a port used for sending logging requests
  adLoggingPort = CreateObject("roMessagePort")

  if adContentType <> "hls" and adContentType <> "mp4"
    adContenType = "mp4"  ' safety fallback
  end if

  return {
    ' dependencies
    constants: constants
    auth: auth
    request: request
    log: log
    tracking: tracking

    ' private
    enhanceCtx: tubiAds_enhanceCtx
    requestQueue: requestQueue.create(adLoggingPort)
    roAdFramework: roAdFramework
    allAdUnitsList:[]
    totalAdBreakAds: 0
    midrolls : []
    commercialDuration : 0
    lastAdFailed: false
    adPlaybackPos: 0
    isInteracting: false
    _: rodash()
    adContentType: adContentType  ' "hls" or "mp4"

    ' public
    reset: tubiAds_reset
    getCuePointsReq: tubiAds_getCuepointsReq
    parseCuePoints: tubiAds_parseCuepoints
    getAdsListViaRoku: tubiAds_getAdsListViaRoku
    hasAds: tubiAds_hasAds
    showCommercialBreakViaRoku: tubiAds_showCommercialBreakViaRoku
    cacheAdsList: tubiAds_cacheAdsList
    getCachedAdsList: tubiAds_getCachedAdsList
    getResumingPlayAds: tubiAds_getResumingPlayAds
    getCommaDelimitedMidrolls: tubiAds_getCommaDelimitedMidrolls
    populateUrlAdrise: tubiAds_populateUrlAdrise
    populateUrlRainmaker: tubiAds_populateUrlRainmaker
    adBufferingCallback: tubiAds_adBufferingCallback
    adTrackingCallback: tubiAds_adTrackingCallback
  }
end function

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
function tubiAds_hasAds(allAdUnitsList)
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
end function

' ----------------------------------------------
'  m.reset()
'
'  call when starting a content video to
'  clear everything out
' ----------------------------------------------
function tubiAds_reset()
  m.allAdUnitsList = []
  m.midrolls = []
  m.commercialDuration = 0
  m.lastAdFailed = false
  m.containerNode = invalid
  m.adPlaybackPos = 0
  m.isInteracting = false
end function


' ----------------------------------------------
' getCommaDelimitedMidrolls
'
' create an array of midrolls from a comma delimited string of midrolls - for ex. "100,300,600,850"
' ----------------------------------------------
function tubiAds_getCommaDelimitedMidrolls(midrollsString)
  midrolls = []
  splitter = CreateObject("roRegex", ",", "")
  midrollsTimes = splitter.Split(midrollsString)
  if midrollsTimes.count() > 0
    for each midroll in midrollsTimes
      midrolls.push(midroll.toInt())
    end for
  end if
  return midrolls
end function


' ----------------------------------------------
' cacheAdsList
'
' cache an ads list for an ad break - typically occurs 4-7 seconds before an ad break actually runs
' we keep the most recently cached ad break at m.lastAdsList
' ----------------------------------------------
function tubiAds_cacheAdsList(episode, breakPos)
  if(m.lastAdsList = invalid or m.lastAdsList.breakPos <> breakPos or m.lastAdsList.cid <> episode.adrise_contentId) 
    tmp = episode.nowPos
    episode.nowPos = breakPos

    m.getAdsListViaRoku(episode)

    list = invalid
    if m.hasAds(m.allAdUnitsList) = true
      list = m.allAdUnitsList
    end if

    episode.nowPos = tmp
    
    m.lastAdsList = {
      cid: episode.id
      breakPos: breakPos
      list: list
    }
  end if
end function

' ----------------------------------------------
' getCachedAdsList
' ----------------------------------------------
function tubiAds_getCachedAdsList(episode, breakPos)
  if m.lastAdsList <> invalid and episode.id = m.lastAdsList.cid and breakPos = m.lastAdsList.breakPos
    return m.lastAdsList.list
  end if
  return invalid
end function



' ----------------------------------------------
' populateUrlAdrise
'
' create the url needed to make ad calls
' ----------------------------------------------
function tubiAds_populateUrlAdrise(episode) As String

  'create the url to be used for ad calls'
  params = {
    "platform": "roku"
    "appid": m.constants.settings.shortAppName
    "cid": episode.id
    "nowpos": episode.nowpos.ToStr()
    "model": m.constants.deviceInfo.model
    "deviceid": m.constants.deviceInfo.deviceId
    "pubid": episode.pubId
    "content-type": m.adContentType
    "roku-v": m.constants.deviceInfo.clientVersion
    "m-language": m.constants.deviceInfo.language
    "_": RND(1000000000000).ToStr()
  }

  ' add Roku Advertiser Id (RIDA) to ad call url
  if m.constants.deviceInfo.deviceAdId <> invalid
    params["advid"] = m.constants.deviceInfo.deviceAdId
  end if

  if m.constants.deviceInfo.isAdIdTrackingDisabled = true
    params["opt-out"] = "1"
  else
    params["opt-out"] = "0"
  end if

  'add TubiTV user/registration id to ad call url
  authInfo = m.auth.getAuthInfo()
  if authInfo <> invalid and authInfo.userId <> invalid
    params["tubitvid"] = authInfo.userId
  end if

  'add if Linear/Live TV is on or off to ad call url
  'TODO: Bryan, uncomment when linear/live tv is added
  ' if GetGlobalAA().app.linearTV.linearTvOn = true
  '   params["linear"] = "1"
  ' end if

  params["sdk"] = "raf_vast"
  return m.request.addParamsToUrl(m.constants.urls.adsBaseUrl, params)
end function


' ----------------------------------------------
' populateUrlRainmaker
'
' create the url needed to make ad calls using the rainmaker API
' For API details, please see https://tubitv.atlassian.net/wiki/spaces/EC/pages/863273074/Rainmaker+-+Request+Parameters
' ----------------------------------------------
function tubiAds_populateUrlRainmaker(episode) As String
  'create the url to be used for ad calls'
  params = {
    video_id: episode.id
    pub_id: episode.pubId
    now_pos: episode.nowpos.ToStr()
    content_type: m.adContentType
    device_id: m.constants.deviceInfo.deviceId
    model: m.constants.deviceInfo.model
    app_id: m.constants.settings.shortAppName
    language: m.constants.deviceInfo.language

    ' the dubug parameter must be set to 1 in order to use the following "limit" parameters for testing
    ' limit_to_campaign_id: 0   'only allow ads with that particular campaign id through the pre-qual filters
    ' limit_to_lineitem_id: 0   'only allow ads with that particular line item id through the pre-qual filters
    ' limit_to_creative_id: 0   'only allow ads with that particular campaign id through the pre-qual filters
    ' debug: 0    'set to 1 in order to use the "limit" parameters above
  }

  ' add Roku Advertiser Id (RIDA) to ad call url
  if m.constants.deviceInfo.deviceAdId <> invalid
    params["adv_id"] = m.constants.deviceInfo.deviceAdId
  end if

  if m.constants.deviceInfo.isAdIdTrackingDisabled = true
    params["opt_out"] = "1"
  else
    params["opt_out"] = "0"
  end if

  'add TubiTV user/registration id to ad call url
  authInfo = m.auth.getAuthInfo()
  if authInfo <> invalid and authInfo.userId <> invalid
    params["user_id"] = authInfo.userId
  end if

  return m.request.addParamsToUrl(m.constants.urls.adsBaseUrlRainmaker, params)
end function


' ----------------------------------------------
'  m.getAdsListViaRoku(episode)
' ----------------------------------------------
function tubiAds_getAdsListViaRoku(episode)
  m.allAdUnitsList = []

  'set the content length (as stated in RAF documentation for Nielsen functionality)
  if episode.length <> invalid
    m.roAdFramework.setContentLength(int(episode.length))
  else
    m.roAdFramework.setContentLength()
  end if

  'set the content genre (as stated in RAF documentation for Nielsen functionality)
  if episode.rokuGenres <> invalid and episode.rokuGenres.count() > 0
    isKids = false
    for each genre in episode.rokuGenres
      if genre = "Children" then isKids = true
    end for
    m.roAdFramework.setContentGenre(episode.rokuGenres, isKids)
  else
    m.roAdFramework.setContentGenre("")
  end if

  'set the program id/title (as stated in RAF documentation for Nielsen functionality)
  if episode.isParentSeries = true and episode.parentTitle <> invalid
    m.roAdFramework.setContentId(episode.parentTitle)
  else if episode.title <> invalid
    m.roAdFramework.setContentId(episode.title)
  else
    m.roAdFramework.setContentId("")
  end if

  'get the url for making the ad call
  url = ""
  if m.constants.externalConfig.info.rainmaker = true
    url = m.populateUrlRainmaker(episode)
  else
    url = m.populateUrlAdrise(episode)
  end if

  'set the url for the Roku Advertising Framework
  m.roAdFramework.setAdUrl(url)

  'get the array of ad units back from the Roku Advertising Framework(RAF)
  'adUnits are called adPods in RAF documentation
  adFetchTimer = CreateObject("roTimeSpan")
  currentAdUnitsList = m.roAdFramework.getAds()
  timeToFetch = adFetchTimer.totalMilliseconds()

  'log ad fetch errors
  if currentAdUnitsList = invalid
    timeToFetchMessage = {
      message: "RAF got no response"
      call_duration: timeToFetch
      raf_version: m.roAdFramework.getLibVersion()
      ad_url: url
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
        print "AD ID "; adUnit.adId; " "; adUnit.creativeAdId
        
        'the ad server had no ads to return so sends us just the midroll times'
        if adUnit.adId = "empty"
          if m.midrolls.count() = 0 or (m.midrolls.count() = 1 and m.lastAdFailed = true)
            m.midrolls = [] 'reset the midrolls array in case there was a previous default midroll
            if adUnit.clickThrough <> invalid
              ' Rainmaker response returns JSON in the ClickThrough tag, adRise response is a comma delimitted string of cuepoints
              adInfo = ParseJson(adUnit.clickThrough)
              if type(adInf) = "roAssociativeArray" and type(adInfo.breaks) = "roArray" and adInfo.breaks.count() > 0
                ' using the Rainmaker response since we were able to parse JSON in the clickThrough field
                m.midrolls = adInfo.breaks
              else
                ' using the adRise ad server still - this "else" block can be removed when moving to Rainmaker is complete
                m.midrolls = m.getCommaDelimitedMidrolls(adUnit.clickThrough)
              end if
            end if
          end if
        
        'if the adUnit contains an ad that needs to use the Roku Ad Framework'
        else
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

          'add the roku ad unit to the adUnitsList in the current adUnitsListContainer
          adUnitsListContainer.adUnitsList[0].ads.push(adUnit)

          'add the duration to m.CommercialDuration for use in adRise pre ad splash screens (in case there are any)
          if currentAdUnitsList[0].duration = invalid or currentAdUnitsList[0].duration <= 0
            m.commercialDuration = m.commercialDuration + adUnit.duration
          end if 
          
          'set the midrolls if midrolls haven't already been set by preroll or earlier midroll
          'midrolls are sent as comma delineated strings in the clickThrough property of the ads being sent
          if m.midrolls.count() = 0 or (m.midrolls.count() = 1 and m.lastAdFailed = true)
            m.midrolls = [] 'reset the midrolls array in case there was a previous default midroll
            if adUnit.clickThrough <> invalid
              ' Rainmaker response returns JSON in the ClickThrough tag, adRise response is a comma delimitted string of cuepoints
              adInfo = ParseJson(adUnit.clickThrough)
              if type(adInfo) = "roAssociativeArray" and type(adInfo.breaks) = "roArray" and adInfo.breaks.count() > 0
                ' using the Rainmaker response since we were able to parse JSON in the clickThrough field
                m.midrolls = adInfo.breaks
              else
                ' using the adRise ad server still - this "else" block can be removed when moving to Rainmaker is complete
                m.midrolls = m.getCommaDelimitedMidrolls(adUnit.clickThrough)
              end if
            end if
          end if
        end if
      end if
    end for

    m.allAdUnitsList.push(adUnitsListContainer) 'push the last adUnitsListContainer
    
    'if no midrolls times were found in any of the ads set the default midroll
    if m.midrolls.count() = 0 or (m.midrolls.count() = 1 and m.lastAdFailed = true)
      m.midrolls = [episode.nowpos + 300]
      m.lastAdFailed = true
    end if
  else
    'no ad units were returned so we need to set the default midroll
    print "no ad units returned"
    if m.midrolls.count() = 0 or (m.midrolls.count() = 1 and m.lastAdFailed = true)
      m.midrolls = [episode.nowpos + 300]
      m.lastAdFailed = true
    end if
  end if

  ' print "CURRENT MIDROLLS"
  ' print m.midrolls
end function


' ----------------------------------------------
' showCommercialBreakViaRoku
'
' containerNode is any empty Group node under which RAF will create a child video node of its own, and
' remove it on completion of showAds()
' ----------------------------------------------
function tubiAds_showCommercialBreakViaRoku(containerNode, controlNode)
  ' ShowVariable(m.allAdUnitsList, "ALL AD UNITS LIST", 4)
  scene = containerNode.getScene()
  m.youboraNode = scene.findNode("Youbora")

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
          m.controlNode.loadingMessage = "Your program will begin after these messages…"

          ' Setting this is REQUIRED in order for setAdBufferRenderCallback to
          ' trigger callbacks.  The empty second argument just suppresses
          ' any ad buffering visual.
          m.roAdFramework.setAdBufferScreenLayer(2, [{}])
          ' Simple shim to make a global-scope callback into a module-scoped method call
          m.roAdFramework.setAdBufferRenderCallback(function(m,e,c): m.adBufferingCallback(e,c): end function, m, 0)
          m.roAdFramework.setTrackingCallback(function(m,e,c): m.adTrackingCallback(e,c): end function, m)
          isCompleted = m.roAdFramework.showAds(adUnitsListContainer.adUnitsList[0], screenCount, containerNode)

          ' This will hide the buffering messaging and reset the progress bar
          ' before the video loading takes over status
          m.controlNode.adProgress = 0
          m.controlNode.loadingMessage = ""
          m.containerNode.visible = false
          m.containerNode = invalid
          m.controlNode = invalid

          '#####
          ' WORKAROUND FOR RAF MEMORY LEAK, still present in RAF 1.9
          if m.roadframework.mediator <> invalid and m.roadframework.mediator.util <> invalid and m.roadframework.mediator.util.xfers <> invalid then
            print "**** CLEARING " + stri(m.roadframework.mediator.util.xfers.count()) + " XFERS FROM RAF"
            m.roadframework.mediator.util.xfers = []
          end if
          '#####


          if isCompleted = false
            print "RAF ads not completed"
            return m.constants.player.playerResults.closed
          end if
          currentAdPosition = currentAdPosition + adUnitsListContainer.adUnitsList.count()
        end if
      end if
    end for
  end if
  
  return m.constants.player.playerResults.completed
end function


' ----------------------------------------------
' getCuepointsReq
'
' gets the cuepoints for the passed in episode and attach them to ads object
' ----------------------------------------------
function tubiAds_getCuepointsReq(episode)
  'get the cuepoints synchronously
  options = {
    params: {
      format: "json"
      pubid: episode.pubId
      platform: "roku"
      cid: episode.id
    }
  }
  return m.request.createAsync(m.constants.urls.cuepointsBaseUrl, "getCuePoints", options)
end function



' ----------------------------------------------
' parseCuepoints
'
' parse a cuepoints response
' side effect of setting cuepoints on m.midrolls
function tubiAds_parseCuepoints(cuepointsReq)
  if cuepointsReq <> invalid and cuepointsReq.response <> invalid and cuepointsReq.response.data <> invalid
    cuepoints = ParseJson(cuepointsReq.response.data)
    if type(cuepoints) = "roArray" and cuepoints.count() > 0
      m.midrolls = cuepoints
      return cuepoints
    end if
  end if
  return invalid
end function


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
function tubiAds_getResumingPlayAds(episode, player)
  m.getAdsListViaRoku(episode)
  return m.hasAds(m.allAdUnitsList)
end function

' ----------------------------------------------
' adBufferingCallback
'
' callback during RAF buffering
function tubiAds_adBufferingCallback(eventType, ctx)
  if ctx.progress <> invalid
    m.controlNode.adProgress = ctx.progress
  else
    m.containerNode.visible = false
  end if
end function


' ------------------------------------
' adTrackingCallback
'
' callback during RAF ad display
function tubiAds_adTrackingCallback(eventType, ctx)
  if eventType <> invalid
    if eventType = "Impression" and m.isInteracting <> true and m.adPlaybackPos = 0
      'Impression events fire when ads start, but also when a user begins interacting with an interactive ad
      ctx = m.enhanceCtx(ctx)
      startAdEvent = {
        ad_started: m.tracking.getAnalyticsAd(ctx)
        video_id: m.controlNode.content.id.toInt()
        start_position: 0
        is_fullscreen: true
      }
      m.tracking.trackUserEvent("start_ad", startAdEvent, m.requestQueue)
    else if eventType = "Complete" or eventType = "Close"
      'Close events fire when a user backs out of an ad, or when a user backs out of the interactive portion of an ad
      if eventType = "Close" and m.isInteracting = true
        ctx = m.enhanceCtx(ctx)
        clickAdEvent = {
          ad_clicked: m.tracking.getAnalyticsAd(ctx)
          video_id: m.controlNode.content.id.toInt()
          position: m.adPlaybackPos
          ad_interaction: "CLOSE"
        }
        m.tracking.trackUserEvent("ad_click", clickAdEvent, m.requestQueue)
      else
        if eventType = "Complete"
          endPosition = ctx.duration
        else if eventType = "Close"
          endPosition = m.adPlaybackPos
        end if

        m.adPlaybackPos = 0
        if endPosition = invalid
          '//ensure a valid value is used. This may not happen during a close event.
          endPosition = 0
        end if

        ctx = m.enhanceCtx(ctx)
        finishAdEvent = {
          ad_finished: m.tracking.getAnalyticsAd(ctx)
          video_id: m.controlNode.content.id.toInt()
          end_position: endPosition * 1000
          reason: "DETECTED"
        }
        m.tracking.trackUserEvent("finish_ad", finishAdEvent, m.requestQueue)
      end if
      m.isInteracting = false
    else if eventType = "Start"
      m.containerNode.visible = true
    else if eventType = "AcceptInvitation"
      ctx = m.enhanceCtx(ctx)
      clickAdEvent = {
        ad_clicked: m.tracking.getAnalyticsAd(ctx)
        video_id: m.controlNode.content.id.toInt()
        position: m.adPlaybackPos
        ad_interaction: "OPEN"
      }
      m.tracking.trackUserEvent("ad_click", clickAdEvent, m.requestQueue)
      m.isInteracting = true
    end if
  else
    ' eventType is invalid when an event fires signalling that one second of ad playback has ocurred
    if ctx.time <> invalid
      m.adPlaybackPos = ctx.time
    end if
  end if

  ' NPAW Youbora video plaback monitoring
  if m.youboraNode <> invalid
    m.youboraNode.adevent = ParseJson(FormatJson(ctx))
  end if
end function


Function tubiAds_enhanceCtx(ctx)
  if ctx.ad <> invalid and ctx.ad.clickThrough <> invalid
    adInfo = ParseJson(ctx.ad.clickThrough)
    if type(adInfo) = "roAssociativeArray"
      ctx.ad.parentId = adInfo.request_id
      ctx.ad.impressionId = adInfo.impression_id
      if adInfo.ad_video_id <> invalid
        ctx.ad.adVideoId = adInfo.ad_video_id.toStr()
      end if
    end if
  end if
  return ctx
End Function
