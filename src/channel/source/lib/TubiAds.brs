Function TubiAds(constants, request, requestQueue, auth, tracking, adContentType, tcfString = invalid, userConsentsOptOutStatus = invalid, isGDPR = false)
  'Add Support for Roku Advertising Framework
  roAdFramework = Roku_Ads()

  'set the preferences for the Roku Advertising Framework so we never use their ad server if our server returns no ads
  'set to 0 retries - 1 max request, even if there are no ads returned from our server
  roAdFramework.setAdPrefs(false, 1)

  'turn on Nielsen DAR API for the Roku Advertising Framework
  'this is mutually exclusive with Roku's own Global Audience Measurement API,
  'meaning only one audience measurement API can run at a time.
  roAdFramework.enableNielsenDAR(true)

  'set the Nielsen application id for Tubi TV
  roAdFramework.setNielsenAppId(constants.thirdParty.nielsen.rafToken)

  'turn off debug output for RAF
  roAdFramework.setDebugOutput(false)

  roAdFramework.enableAdMeasurements(true)

  #if consoleLoggingEnabled
    if constants.settings.mode = "qa" or constants.settings.mode = "staging"
      roAdFramework.setDebugOutput(true)
    end if
  #end if

  'a port used for sending logging requests
  adMessagePort = CreateObject("roMessagePort")
  requestQueue = requestQueue.create(adMessagePort)

  if adContentType <> "hls" AND adContentType <> "mp4"
    adContentType = "mp4"  ' safety fallback
  end if

  if isFunction(roAdFramework.setLimitAdTracking) = true AND userConsentsOptOutStatus <> invalid then
    userPersonalAdOptOutStatus = userConsentsOptOutStatus[constants.consentKeys.personalization]
    if userPersonalAdOptOutStatus <> invalid
      roAdFramework.setLimitAdTracking(userPersonalAdOptOutStatus)
    end if
  end if

  return {
    ' dependencies
    constants: constants
    auth: auth
    request: request
    tracking: tracking

    ' private
    updateYouboraOptions: tubiAds_updateYouboraOptions
    parseOutNotUsedAdPodPixels: tubiAds_parseOutNotUsedAdPodPixels
    requestQueue: requestQueue
    allAdUnitsList: []
    totalAdBreakAds: 0
    commercialDuration : 0
    totalAdDurationInCurrentPod: 0
    adPlaybackPos: 0
    isInteracting: false
    _: rodash()
    adContentType: adContentType  ' "hls" or "mp4"
    breakPos: 0
    googleAppSession: invalid ' Google's GAMUtils appsession or invalid
    googleContentSession: invalid ' Google's GAMUtils contentSession or invalid
    shouldSendGoogleBeacons: false ' Let's us know if during a given ad pod we should send beacons to Google or not
    createRAFStructure: tubiAds_createRAFStructure
    adResponseTime: -1
    totalAdBreakAdsPerSession: 0

    ' public
    roAdFramework: roAdFramework
    reset: tubiAds_reset
    getAdsListViaRoku: tubiAds_getAdsListViaRoku
    getAdsListViaTubi: tubiAds_getAdsListViaTubi
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
    sendNotUsedAdPodPixels: tubiAds_sendNotUsedAdPodPixels
    retrieveAds: tubiAds_retrieveAds
    replaceMacro: tubiAds_replaceMacro
    setLimitAdTracking: tubiAds_setLimitAdTracking

    appMode: "DEFAULT_MODE"
    notUsedAdPodPixels: {} ' List of pixels for the current ad pod that should be sent if playback is stopped before we get an impression for that ad
    tcfString: tcfString ' IAB TC String, currently stored in m.global.IABTCF_TCString from one trust sdk.
    userConsentsOptOutStatus: userConsentsOptOutStatus ' assoc array of consent to purpose key mapping. ex: {"functional": true, "analytics": true}
    isGDPR: isGDPR
    adMessagePort: adMessagePort
  }
End Function


' returns a set of ad helper functions that can be used outside of TubiAds without invoking RAF
Function TubiAdsLimited(constants, auth, tcfString = invalid, userConsentsOptOutStatus = invalid, isGDPR = false)

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
    replaceMacro: tubiAds_replaceMacro
    tcfString: tcfString ' IAB TC String, currently stored in m.global.IABTCF_TCString from one trust sdk.
    userConsentsOptOutStatus: userConsentsOptOutStatus ' assoc array of consent to purpose key mapping. ex: {"functional": true, "analytics": true}
    isGDPR: isGDPR
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
  if allAdUnitsList <> invalid AND allAdUnitsList.count() > 0
    firstAdUnitsListContainer = m.allAdUnitsList[0]
    if firstAdUnitsListContainer.adUnitsList <> invalid AND firstAdUnitsListContainer.adUnitsList.count() > 0
      adUnitsList = firstAdUnitsListContainer.adUnitsList[0]
      if adUnitsList.ads <> invalid AND adUnitsList.ads.count() > 0
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
  ' resets m.notUsedAdPodPixels after sending current pixels
  m.sendNotUsedAdPodPixels("exit_pre_pod")
  m.allAdUnitsList = []
  m.commercialDuration = 0
  m.containerNode = invalid
  m.adPlaybackPos = 0
  m.isInteracting = false
  m.breakPos = 0
  m.totalAdDurationInCurrentPod = 0
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
  if m.lastAdsList <> invalid AND episode.id = m.lastAdsList.cid AND breakPos = m.lastAdsList.breakPos
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
  return paramAddedUrl
End Function


' returns an assocArray of all parameters that should be sent to rainmaker
' @content: node, TubiContentNode for a video (movie or episode)
' @breakPos: float, the preroll or midroll playback position at which the break occurs
Function tubiAds_getRainmakerParams(content, breakPos = 0)
  'rounding the float to integer as rainmaker will accept only integer format
  roundedBreakPos = round(breakPos)
  ' Converting it to integer since we need to pass numeric boolean.
  gdpr = 0
  if m.isGDPR = true 'bs:disable-line 1001 LINT1001
    gdpr = 1
  end if

  params = {
    content_id: content.id
    pub_id: content.pubId
    now_pos: roundedBreakPos.ToStr()
    content_type: m.adContentType
    device_id: m.constants.deviceInfo.deviceId
    model: m.constants.deviceInfo.model
    app_id: m.constants.settings.shortAppName
    language: m.constants.deviceInfo.language
    app_mode: m.appMode
    client_version: m.constants.deviceInfo.clientVersion
    nsid: m.getNielsenSessionId(m.constants)
    os: m.constants.deviceInfo.operatingSystem
    os_version: m.constants.deviceInfo.firmwareVersion

    ' the debug parameter must be set to 1 in order to use the following "limit" parameters for testing
    ' limit_to_campaign_id: 0   'only allow ads with that particular campaign id through the pre-qual filters
    ' limit_to_lineitem_id: 0   'only allow ads with that particular line item id through the pre-qual filters
    ' limit_to_creative_id: 0   'only allow ads with that particular campaign id through the pre-qual filters
    ' debug: 0    'set to 1 in order to use the "limit" parameters above
    gdpr: gdpr
  }

  '//send sponsored exposure value if the user call this video from a sponsored container.
  if content.videoSponsorExposureId <> invalid AND content.videoSponsorExposureId <> ""
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

 if content.adParam <> invalid AND isNonEmptyString(content.adParam.resumeFrom) = true
    params["resume_from"] = content.adParam.resumeFrom
  end if

  'add TubiTV user/registration id to ad call url
  authInfo = m.auth.getAuthInfo()
  if authInfo <> invalid AND authInfo.userId <> invalid
    params["user_id"] = authInfo.userId
  end if

  origin =  m.constants.player.playbackOrigin.unknown

  if content.adParam <> invalid
    if content.adParam.srcForAds <> invalid
      origin = content.adParam.srcForAds
    end if

    playbackContainer = content.adParam.playbackContainer

    if isNonEmptyString(playbackContainer)
      params["container_id"] = playbackContainer
    end if
  end if

  params["origin"] = origin

  if gdpr = 1
    consentKeys = m.constants.consentKeys

    ' 1 when the user has not opted-out of the analytics tubi purpose.
    analyticsConsentStatus = 1
    if m.userConsentsOptOutStatus[consentKeys.analytics] = true
      analyticsConsentStatus = 0
    end if

    ' 1 when the user has not opted-out of the personalized advertising tubi purpose.
    personalizedAdsConsentStatus = 1
    if m.userConsentsOptOutStatus[consentKeys.personalization] = true
      personalizedAdsConsentStatus = 0
    end if

    params["gdpr_analytics"] = analyticsConsentStatus
    params["gdpr_personalized_ads"] = personalizedAdsConsentStatus
  end if

  return params
End Function


Function tubiAds_getRainmakerParamsForLinear(content)
  params = m.getRainmakerParams(content, 0)
  params.platform = m.constants.analyticsPlatform
  params.delete("nsid")

  return params
End Function


' This function converts the associative array into RAF Structure
' @adInfo: assocArray, Ad information retrieved from API response
Function tubiAds_createRAFStructure(adInfo)
  currentAdUnitsList = []
  stream = []
  trackingPixels = []

  if isAA(adInfo) = true
    adId = adInfo.ad_id
    media = adInfo.media

    streamUrl = ""
    duration = 0
    trackingEvents = {}

    if isAA(media) = true
      streamUrl = media.streamurl
      duration = media.duration

      if isAA(media.trackingevents) = true
        trackingEvents = media.trackingevents
      end if
    end if

    streamAA = {
      id: adInfo.id
      mimetype: "video/mp4"
      provider: ""
      url: streamUrl
    }
    stream.push(streamAA)

    'Error tracking event
    error = adInfo.error
    if isNonEmptyString(error) = true
      tracking = {}
      tracking["event"] = "Error"
      tracking["triggered"] = false
      tracking["url"] = replaceCachebusterMacro(error)
      trackingPixels.push(tracking)
    end if

    'Impression tracking event
    impTracking = adInfo.imptracking

    if isNonEmptyArray(impTracking) = true
      for each pixelUrl in impTracking
        tracking = {}
        tracking["event"] = "Impression"
        tracking["triggered"] = false
        tracking["url"] = replaceCachebusterMacro(pixelUrl)
        tracking["time"] = 0
        trackingPixels.push(tracking)
      end for
    end if

    trackingEventKeys = trackingEvents.Keys()
    'Impression/FirstQuartile/Midpoint/ThirdQuartile/Complete tracking event

    for each key in trackingEventKeys
      pixelType = ""
      pixelUrl = trackingEvents[key][0]
      pixelValue = key.split("_")[1]

      if pixelValue <> invalid
        iPixelPercent = pixelValue.toInt()
        time = 0

        if iPixelPercent = 0
          pixelType = "Impression"
          time = 0
        else if iPixelPercent = 25
          pixelType = "FirstQuartile"
          time = duration * 0.25
        else if iPixelPercent = 50
          pixelType = "Midpoint"
          time = duration * 0.50
        else if iPixelPercent = 75
          pixelType = "ThirdQuartile"
          time = duration * 0.75
        else if iPixelPercent = 100
          pixelType = "Complete"
          time = duration
        end if

        tracking = {}
        tracking["event"] = pixelType
        tracking["triggered"] = false
        tracking["url"] = replaceCachebusterMacro(pixelUrl)
        tracking["time"] = time

        if isNonEmptyString(pixelType) = true
          trackingPixels.push(tracking)
        end if
      end if
    end for

    ads = []
    adUnit = {
      adid: adId
      adserver: "Tubi"
      creativeadid: adId
      duration: duration
      streamformat: "mp4"
      streams: stream
      tracking: trackingPixels
    }
    ads.push(adUnit)

    currentAdUnitsList[0] = {
      ads: ads
      duration: duration
      rendersequence: "preroll"
      rendertime: 0
      tracking: trackingPixels
      viewed: false
    }
  end if

  return currentAdUnitsList
End Function


'//the sStringToReplace is the agreed upon string that the backend will set to the param that is used for cachebusting.
'//a cache busting string must be created within the Roku client and replace the sStringToReplace.
'@pixelURL: String, pixel urls needs to be updated
Function replaceCachebusterMacro(pixelURL as String)
  sStringToReplace = "(ADRISE:CB)"
  sCacheBuster = createCacheBusterString()
  newPixelURL = pixelURL.replace(sStringToReplace, sCacheBuster)
  encodedUrl = ""

  if isNonEmptyString(newPixelURL) = true
    encodedUrl = newPixelURL.EncodeUri()
  end if

  return encodedUrl
End function



' This function is used to retrieve ads for linear and VOD
' @adsUrl: string, The url that is used to retrieve the ads. This url is already decorated with rainmaker params.
' @adInsertionMethod: string, Defines how we will be inserting ads in the stream. Values are "yospace", "apollo" or "csai".
Function tubiAds_retrieveAds(adsUrl, adInsertionMethod)
  currentAdUnitsList = invalid

  videoHeight = m.constants.deviceInfo.videoMode.toInt()
  if videoHeight = 2160 then
    videoWidth = 3840
  else if videoHeight = 1080 then
    videoWidth = 1920
  else if videoHeight = 720 then
    videoWidth = 1280
  else if videoHeight = 480 then
    videoWidth = 720
  else
    videoWidth = -1
    videoHeight = -1
  end if


  requestOptions = {}
  requestOptions.headers = {}

  if adInsertionMethod = "csai" then
    if m.googleAppSession = invalid then
      m.googleAppSession = newAppSession()
    end if
    m.googleContentSession = m.googleAppSession.newContentSession({
      "adWillAutoPlay": false
      "adWillPlayMuted": false
      "continuousPlayback": true
      "directedForChildOrUnknownAge": false
      "iconsSupported": false
      "publisherProvidedId": "" ' Required as the fallback is a boolean and it will crash otherwise
      "raf": m.roAdFramework
      "videoHeight": videoHeight
      "videoWidth": videoWidth
      "storageAllowed": (m.constants.deviceInfo.isAdIdTrackingDisabled = false)
      "supportedApiFrameworks": []
      "skippablesSupported": false
    })

    givn = m.googleContentSession.getGIVN()
    requestOptions.headers["x-tubi-paln"] = givn
  end if

  if m.isGDPR = true 'bs:disable-line 1001 LINT1001
    requestOptions.headers["X-Tubi-TCF-String"] = m.tcfString
  end if

  ' RAF has a hard 5 second cutoff for download time.
  ' We make the network request to rainmaker ourselves to work around this.
  tubiReq = m.request.createAsync(adsUrl, "adsRequest", requestOptions)

  port = createObject("roMessagePort")
  if tubiReq.start(port) = true then
    timeout = 10000 ' in milliseconds
    msg = wait(timeout, port)
    if type(msg) = "roUrlEvent" then
      responseCode = msg.getResponseCode()
      if responseCode >= 200 AND responseCode < 400 then
        ' If our request was successful and it contains the x-tubi-send-google-beacons header then we should send beacons to Google
        responseHeaders = msg.getResponseHeaders()
        if responseHeaders["x-tubi-send-google-beacons"] <> invalid then
          m.shouldSendGoogleBeacons = true
        end if

        ' If we got a valid result write it to tmp and then have RAF read it from there
        rainmakerResponse = msg.getString()
        localRafVastUrl = "tmp:/local_raf_vast.xml"
        if writeAsciiFile(localRafVastUrl, rainmakerResponse) = true then
          notUsedAdPodPixels = m.parseOutNotUsedAdPodPixels(rainmakerResponse)
          ' Need to check that count is greater than zero as linear will keep polling even after receiving the upcoming ads which would then override the existing notUsed pixels
          if notUsedAdPodPixels.count() > 0 then
            m.notUsedAdPodPixels = notUsedAdPodPixels
          end if

          m.roAdFramework.setAdUrl(localRafVastUrl)
          'get the array of ad units back from the Roku Advertising Framework(RAF)
          'adUnits are called adPods in RAF documentation
          currentAdUnitsList = m.roAdFramework.getAds()
        else
          tubiLog("Failed to write local vast response to " + localRafVastUrl)
        end if

        deleteFile(localRafVastUrl)
      else
        code = responseCode.tostr()
        if code = "404" AND adInsertionMethod = "apollo"
          ' apollo pollUrl sends 404 if there are no ads, hence its not an error that we want report.
        else
          errorInfo = {
            code: code
            message: "RAF bad response"
            raf_version: m.roAdFramework.getLibVersion()
            ad_url: adsUrl
            deviceId: m.constants.deviceInfo.deviceId
          }
          jsonErrorInfo = FormatJSON(errorInfo)
          ' sending error logs to uapi
          tubiLog(jsonErrorInfo, "warn", "adBadResponse", "ad-bad-response", 0.1)

          errorInfo.type = m.constants.errors.type.adError + " " + responseCode.tostr()
          errorInfo.name = m.constants.errors.message.badResponse
          ' sending error logs to sentry sdk
          tubiException(errorInfo, "warn", 0.1)
        end if
      end if
    end if
  end if
  return currentAdUnitsList
End Function


' ----------------------------------------------
'  m.getAdsListViaRoku(episode, breakPos)
' ----------------------------------------------
' @episode: node, TubiContentNode for a video (movie or episode)
' @breakPos: integer, the preroll or midroll playback position at which the break occurs
Function tubiAds_getAdsListViaRoku(episode, breakPos)
  m.allAdUnitsList = []

  authInfo = m.auth.getAuthInfo()

  ' Storing the breakPos in m scope so that we can use it override the render sequence sent to youbora plugin.
  m.breakPos = breakPos

  ' don't pass content information for child directed content if the user is not logged in
  if episode.isCdc = false OR (authInfo <> invalid AND authInfo.userId <> invalid)
    genres = []
    if isNonEmptyArray(episode.genres) = true then
      tubiToRokuGenreMap = {
        "Action": "Action"
        "Adventure": "Adventure"
        "Animation": "Animated"
        "Anime": "Anime"
        "Biography": "Biography"
        "Comedy": "Comedy"
        "Crime": "Crime"
        "Documentary": "Documentary"
        "Drama": "Drama"
        "Entertainment": "Entertainment"
        "Fantasy": "Fantasy"
        "Game Show": "Gaming"
        "History": "History"
        "Horror": "Horror"
        "Music": "Music"
        "Musical": "Musicals"
        "Mystery": "Mystery"
        "Science & Nature": "Nature"
        "Reality": "Reality"
        "Romance": "Romance"
        "Sci-Fi": "Science fiction"
        "News": "News"
        "Sport": "Sports"
        "Talk Show": "Talk"
        "Thriller": "Thriller"
        "War": "War"
        "Western": "Western"
      }

      for each genre in episode.genres
        if tubiToRokuGenreMap[genre] <> invalid then
          genres.push(tubiToRokuGenreMap[genre])
        end if
      end for
    end if

    isChildDirected = (episode.isCdc = true)
    m.roAdFramework.setContentGenre(genres.join(","), isChildDirected)

    ' We are not sending setContentId because our contract does not require it.

    if isNumber(episode.length) = true then
      m.roAdFramework.setContentLength(Int(episode.length))
    end if
  end if

  m.adResponseTime = -1
  'get the url for making the ad call
  rainmakerVastUrl = m.populateUrlRainmaker(episode, breakPos)
  adFetchTimer = createObject("roTimeSpan")
  currentAdUnitsList = m.retrieveAds(rainmakerVastUrl, "csai")
  timeToFetch = adFetchTimer.totalMilliseconds()
  m.adResponseTime = timeToFetch

  'log ad fetch errors
  if currentAdUnitsList = invalid
    timeToFetchMessage = {
      message: "RAF got no response"
      call_duration: timeToFetch
      raf_version: m.roAdFramework.getLibVersion()
      ad_url: rainmakerVastUrl
      device_id: m.constants.deviceInfo.deviceId
    }
    jsonTimeToFetchMessage = FormatJSON(timeToFetchMessage)
    ' sending error logs to uapi
    tubiLog(jsonTimeToFetchMessage, "error", "adError", "no-ad-response", 0.1)

    timeToFetchMessage.type = m.constants.errors.type.adError
    timeToFetchMessage.name = m.constants.errors.message.noResponse
    ' sending error logs to sentry sdk
    tubiException(timeToFetchMessage, "error", 0.1)
  end if

  'check to see if the ad server returns an ad that can be used by RAF or needs to use our ad SDK
  'traditional version of xml is in the clickThrough property/clickThrough VAST tag
  'traditional is used if adId of the first ad object in the first ad pod is set equal to 'default'
  if currentAdUnitsList <> invalid AND currentAdUnitsList.count() > 0 AND currentAdUnitsList[0] <> invalid AND currentAdUnitsList[0].ads <> invalid AND currentAdUnitsList[0].ads.count() > 0
    adUnitType = "" 'keeps track of what kind adUnitsList/adPod is currently being built by the for loop - can be "adrise" or "roku"

    'set up the duration for use by the adRise pre ad splash screen
    if currentAdUnitsList[0].duration <> invalid AND currentAdUnitsList[0].duration > 0
        m.commercialDuration = m.commercialDuration + currentAdUnitsList[0].duration
    end if

    adUnitsListContainer = {
      type: ""
      adUnitsList: []
    }

    'save the total number of ads in the ad break before we (potentially) start breaking them up into different ad unit lists
    m.totalAdBreakAds = currentAdUnitsList[0].ads.count()


    m.totalAdDurationInCurrentPod = 0
    for each adUnit in currentAdUnitsList[0].ads

      if adUnit.adId <> invalid
        if m.constants.settings.mode = "qa" or m.constants.settings.mode = "staging"
          print "AD ID "; adUnit.adId; " "; adUnit.creativeAdId
        end if

        m.totalAdDurationInCurrentPod = m.totalAdDurationInCurrentPod + adUnit.duration

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
                  renderSequence: m._.cond(breakPos > 0, "midroll", "preroll")
                  duration: currentAdUnitsList[0].duration
                  renderTime: currentAdUnitsList[0].renderTime
                  ads: []
                }
              ]
            }
          end if

          'make sure we have the appropriate stream format. if stream format is mp4, but file is an HLS, the ad won't play
          for each stream in adUnit.streams
            if stream.url <> invalid AND right(stream.url, 4) = "m3u8"
              adUnit.streamFormat = "hls"
            end if
          end for

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


'----------------------------------------------
'  m.getAdsListViaTubi(episode, breakPos)
' ----------------------------------------------
' @content: node, TubiContentNode for a content
Function tubiAds_getAdsListViaTubi(content)
  m.allAdUnitsList = []
  adInfo = content.adInfo
  currentAdUnitsList = invalid

  if isAA(adInfo) = true
    currentAdUnitsList = m.createRAFStructure(adInfo)
  end if

  'check to see if the ad server returns an ad that can be used by RAF or needs to use our ad SDK
  'traditional version of xml is in the clickThrough property/clickThrough VAST tag
  'traditional is used if adId of the first ad object in the first ad pod is set equal to 'default'
  if currentAdUnitsList <> invalid AND currentAdUnitsList.count() > 0 AND currentAdUnitsList[0] <> invalid AND currentAdUnitsList[0].ads <> invalid AND currentAdUnitsList[0].ads.count() > 0
    adUnitType = "" 'keeps track of what kind adUnitsList/adPod is currently being built by the for loop - can be "adrise" or "roku"

    'set up the duration for use by the adRise pre ad splash screen
    if currentAdUnitsList[0].duration <> invalid AND currentAdUnitsList[0].duration > 0
        m.commercialDuration = m.commercialDuration + currentAdUnitsList[0].duration
    end if

    adUnitsListContainer = {
      type: ""
      adUnitsList: []
    }

    'save the total number of ads in the ad break before we (potentially) start breaking them up into different ad unit lists
    m.totalAdBreakAds = currentAdUnitsList[0].ads.count()
    m.totalAdDurationInCurrentPod = 0
    for each adUnit in currentAdUnitsList[0].ads

      if adUnit.adId <> invalid
        if m.constants.settings.mode = "qa" or m.constants.settings.mode = "staging"
          print "AD ID "; adUnit.adId; " "; adUnit.creativeAdId
        end if

        if adUnit.adId <> invalid
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
                  renderSequence: "preroll"
                  duration: currentAdUnitsList[0].duration
                  renderTime: currentAdUnitsList[0].renderTime
                  ads: []
                }
              ]
            }
          end if

          'make sure we have the appropriate stream format. if stream format is mp4, but file is an HLS, the ad won't play
          for each stream in adUnit.streams
            if stream.url <> invalid AND right(stream.url, 4) = "m3u8"
              adUnit.streamFormat = "hls"
            end if
          end for

          'add the roku ad unit to the adUnitsList in the current adUnitsListContainer
          adUnitsListContainer.adUnitsList[0].ads.push(adUnit)

          'add the duration to m.CommercialDuration for use in adRise pre ad splash screens (in case there are any)
          if currentAdUnitsList[0].duration = invalid or currentAdUnitsList[0].duration <= 0
            m.commercialDuration = m.commercialDuration + adUnit.duration
          end if

          if isNumber(adUnit.duration) = true
            m.totalAdDurationInCurrentPod = m.totalAdDurationInCurrentPod + adUnit.duration
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
      if adUnitsListContainer.adUnitsList <> invalid AND adUnitsListContainer.adUnitsList.count() > 0
        if adUnitsListContainer.type <> invalid AND adUnitsListContainer.type = "roku"

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

          if m.controlNode.hasField("displayAdLoadingMessage") = true
            m.controlNode.displayAdLoadingMessage = true
          end if

          ' Setting this is REQUIRED in order for setAdBufferRenderCallback to
          ' trigger callbacks.  The empty second argument just suppresses
          ' any ad buffering visual.
          m.roAdFramework.setAdBufferScreenLayer(2, [{}])
          ' Simple shim to make a global-scope callback into a module-scoped method call
          m.roAdFramework.setAdBufferRenderCallback(function(_m, eventType, ctx)
            ads = getGlobalAA().tubiAds
            ads.adBufferingCallback(eventType, ctx)
          end function, {}, 0)

          ctx = {}
          m.roAdFramework.setTrackingCallback(function(ctx, eventType, rafCtx)
            ads = getGlobalAA().tubiAds
            ctx.append(rafCtx)
            ads.adTrackingCallback(eventType, ctx)
          end function, ctx)

          adPod = adUnitsListContainer.adUnitsList[0]
          isCompleted = m.roAdFramework.showAds(adPod, screenCount, containerNode)

          ' This will hide the buffering messaging and reset the progress bar
          ' before the video loading takes over status
          m.controlNode.adProgress = 0

          if m.controlNode.hasField("displayAdLoadingMessage") = true
            m.controlNode.displayAdLoadingMessage = false
          end if

          m.containerNode.visible = false
          m.containerNode = invalid
          m.controlNode = invalid

          if isCompleted = false
            tubilog("RAF ads not completed")

            notUsedAction = "exit_mid_pod"
            if adPod.ads.count() = m.notUsedAdPodPixels.count() then
              ' If notUsedAdPodPixels count equals total ad pod count then we haven't played any at all so user exited before ad playback started
              notUsedAction = "exit_pre_pod"
            end if
            ' resets m.notUsedAdPodPixels after sending current pixels
            m.sendNotUsedAdPodPixels(notUsedAction)

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
' this function is to be called when resuming back to play after a user has fast forwarded. This function
' will make a call to the ads server and if it gets ads, store them in an appropriate place
' returns true if there are ads and false if there are no ads (aka the player can resume playing immediately without closing the player)
' SIDE EFFECT: updates the resumePlayAdsList property on the player object that is passed in
' (expect that the player object will be the main video player for the channel)
' ----------------------------------------------
Function tubiAds_getResumingPlayAds(episode, position)
  ' resets m.notUsedAdPodPixels after sending current pixels
  m.sendNotUsedAdPodPixels("ffwd")
  m.getAdsListViaRoku(episode, position)
  return m.hasAds(m.allAdUnitsList)
End Function


' ----------------------------------------------
' sendNotUsedAdPodPixels
'
' Used to centralize sending of notUsed ad pod pixels
' @notUsedAction string, reason that ad impression was not sent. One of exit_pre_pod | exit_mid_pod | ffwd
' SIDE EFFECT: resets m.notUsedAdPodPixels after sending current pixels
Function tubiAds_sendNotUsedAdPodPixels(notUsedAction)
  for each adId in m.notUsedAdPodPixels
    notUsedPixelUrl = m.replaceMacro(m.notUsedAdPodPixels[adId], "[TUBI:NOT_USED_ACTION]", notUsedAction)
    notUsedPixelReq = m.request.createAsync(notUsedPixelUrl)
    m.requestQueue.pushRequest(notUsedPixelReq)
  end for
  m.notUsedAdPodPixels = {}
End Function


Function tubiAds_parseOutNotUsedAdPodPixels(adResponse)
  notUsedAdPodPixels = {}
  xml = ParseXML(adResponse)
  if xml <> invalid
    for each ad in xml.ad
      adSequence = ad@sequence
      if isNonEmptyString(adSequence) = true then
        for each inline in ad.inline
          for each creatives in inline.creatives
            for each creative in creatives.creative
              for each linear in creative.linear
                for each trackingEvents in linear.trackingEvents
                  for each tracking in trackingEvents.tracking
                    event = tracking@event
                    if event = "notUsed" then
                      ' Need trim due to extra whitespace and unescape because of encoding returned from yospace
                      url = tracking.getText().trim().unescape()
                      notUsedAdPodPixels[adSequence] = url
                      exit for
                    end if
                  end for
                end for
              end for
            end for
          end for
        end for
      end if
    end for
  end if

  return notUsedAdPodPixels
End Function


' ----------------------------------------------
' adBufferingCallback
'
' callback during RAF buffering
Function tubiAds_adBufferingCallback(eventType, ctx)
  ' We need to hide the raf container while we're buffering and show it again when buffering ends
  if eventType = "BufferingStart" AND ctx.adIndex > 1 then
    ' Avoiding a rendezvous by only doing on adIndex greater than 1 since we already hide the raf container there
    ' RebufferingStart will handle any subsequent buffer event during ad playback, including when adIndex = 1.
    m.containerNode.visible = false
  else if eventType = "ReBufferingStart" then
    ctx.eventType = "reBuffer"
    m.containerNode.visible = false
  else if eventType = "BufferingEnd" OR eventType = "ReBufferingEnd" then
    m.containerNode.visible = true
  end if

  if m.controlNode.hasField("adBufferingObject") = true
    m.controlNode.adBufferingObject = ctx
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
      if ctx.adCount <> invalid
        adTrackingObject.adCount = ctx.adCount
      end if
      if ctx.adIndex <> invalid
        adTrackingObject.adIndex = ctx.adIndex
      end if
      if ctx.duration <> invalid
        adTrackingObject.duration = ctx.duration
      end if
      if ctx.ad <> invalid
        adTrackingObject.ad = ctx.ad
      end if
      if ctx.rendertime <> invalid
        adTrackingObject.rendertime = ctx.rendertime
      end if

      ' Overriding the ads context to reset the sequence since ROKU does not have a way to figure out render sequence properly for VAST ad format.
      ' And it always falls back to preroll. We are basing the value based on the current position when the break occurred.
      renderSequence = "preroll"
      if m.breakPos > 0
        renderSequence = "midroll"
      end if

      ctx.renderSequence = renderSequence
      adTrackingObject.renderSequence = renderSequence

      if ctx.type <> invalid
        adTrackingObject.type = ctx.type
      end if

      if m.totalAdDurationInCurrentPod <> invalid
        adTrackingObject.totalAdDurationInCurrentPod = Int(m.totalAdDurationInCurrentPod)
      end if

      if m.controlNode <> invalid
        m.controlNode.adTrackingObject = adTrackingObject
      end if
    end if

    ' We have do the second check for start event because for Innovid interactive ads our Impression code block won't get called because m.adPlaybackPos is already 1. In other words, the position callback where ctx.time = 1 occurs prior to the Impression event for Innovid interactive ads.

    if (eventType = "Impression" AND m.isInteracting <> true AND m.adPlaybackPos = 0) OR (eventType = "Start" AND lCase(m.roAdFramework.getInteractiveAdFormat(ctx.ad).toStr()) = "iroll") then
      ' Without setting RAF container back to visible here interactive ads will not show because tubiAds_adBufferingCallback never gets called
      ' Not needed when stitched ads are enabled as AdStateChange properly gets called in that case
      m.containerNode.visible = true

      'Impression events fire when ads start, but also when a user begins interacting with an interactive ad
      startAdEvent = {
        ad_started: m.tracking.getAnalyticsAd(ctx)
        video_id: m.controlNode.content.id.toInt()
        start_position: 0
        is_fullscreen: true
      }

      if ctx.adIndex <> invalid then
        ' Clear out notUsed pixel for the current ad since we sent an impression
        m.notUsedAdPodPixels.delete(ctx.adIndex.toStr())
      end if

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
      if eventType = "Close" AND m.isInteracting = true
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
          endPosition = ctx.duration
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
    else if eventType = "Error" AND ctx <> invalid AND ctx.adIndex <> invalid then
      ' Clear out notUsed pixel for the current ad since RAF will fire the error pixel for this ad
      m.notUsedAdPodPixels.delete(ctx.adIndex.toStr())
    else if eventType = "Pause" then
      m.controlNode.timestampOfLastVideoPlayback = createObject("roDateTime").asSeconds()
    else if eventType = "Resume" then
      m.controlNode.timestampOfLastVideoPlayback = -1
    end if

    ' GAMUtils integration
    if m.shouldSendGoogleBeacons = true AND m.googleContentSession <> invalid then
      if eventType = "PodStart" then
        m.googleContentSession.sendStartedBeacon()
      else if eventType = "Close" OR eventType = "PodComplete" then
        m.googleContentSession.sendEndedBeacon()
        ' Google is using RAF to do the actual sending so we are good to clean up straight away
        m.googleContentSession = invalid
        m.shouldSendGoogleBeacons = false
      else if eventType = "Pause" OR eventType = "Resume" then
        ' Google wants us to send onKeyEvent responses but we never receive those because RAF consumes them but we can at least send play pause
        m.googleContentSession.sendAdTouchBeacon("play")
      end if
    end if
  else
    if ctx <> invalid then
      ' eventType is invalid when an event fires signaling that one second of ad playback has ocurred
      if ctx.time <> invalid then
        m.adPlaybackPos = ctx.time
      end if
    end if
  end if

  if m.shouldSendGoogleBeacons = true AND m.googleContentSession <> invalid then
    ' We want to poll any time we get an event including those without an eventType. GAMUtils will limit sending on its own
    m.googleContentSession.poll()
  end if

  if m.youboraTask <> invalid
    if youboraOptions <> invalid
      m.youboraTask.options = youboraOptions
    end if
    m.youboraTask.adEvent = ctx
  end if
End Function


Function tubiAds_updateYouboraOptions(youboraTask, ctx, impressionCount)
  youboraOptions = invalid

  if youboraTask <> invalid
    youboraOptions = youboraTask.options

    if ctx.ad <> invalid
      if ctx.ad.creativeAdId <> invalid AND ctx.ad.creativeAdId <> ""
        youboraOptions["ad.extraparam.1"] = ctx.ad.creativeAdId
      end if

      if ctx.ad.streams <> invalid AND ctx.ad.streams[0] <> invalid AND ctx.ad.streams[0].id <> invalid
        youboraOptions["ad.extraparam.2"] = ctx.ad.streams[0].id
      end if

      if youboraOptions["ad.extraparam.1"] <> invalid AND youboraOptions["ad.extraparam.2"] <> invalid
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
  if content <> invalid AND content.id <> ""
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


' @adUrl: string, the url for Ad
' @macro: string, macro string which needs to be replaced
' @newValue: string, the new value which will be used in the place of macro
'
' return: string, updated AdUrl
Function tubiAds_replaceMacro(adUrl, macro, newValue)
  newAdUrl = adUrl.trim().unescape().replace(macro, newValue)
  return newAdUrl
End Function


' Wrapper around RAF's setLimitAdTracking to only call if it exists for the version of RAF running on the device
' @enabled: boolean, Sets the ROKU_ADS_LIMIT_TRACKING URL parameter macro to be passed into beacons and ad requests to either 1 (true; ad targeting is disabled for the customer) or 0 (false; ad targeting is disabled for the customer).
Function tubiAds_setLimitAdTracking(enabled)
  if isFunction(m.roAdFramework.setLimitAdTracking) = true then
    m.roAdFramework.setLimitAdTracking(enabled)
  end if
End Function
