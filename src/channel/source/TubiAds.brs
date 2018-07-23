function TubiAds (utils)

  'Add Support for Roku Advertising Framework
  roAdFramework = Roku_Ads()
  
  'set the preferences for the Roku Advertising Framework so we never use their ad server if our server returns no ads
  'set to 0 retries - 1 max request, even if there are no ads returned from our server
  roAdFramework.setAdPrefs(false, 1)
  
  'turn Nielsen DAR on for the Roku Advertising Framework
  roAdFramework.enableNielsenDAR(true)

  'set the Nielsen application id for Tubi TV
  roAdFramework.setNielsenAppId("PC60BD376-8551-4688-BEF4-E8B45A39D4C7")

  'turn on debug output for RAF
  roAdFramework.setDebugOutput(false)

  'a port used for sending logging requests
  adLoggingPort = CreateObject("roMessagePort")

  return {
    utils: utils
    constants: utils.constants
    requestQueue: utils.requestQueue.create(adLoggingPort)
    roAdFramework: roAdFramework

    allAdUnitsList:[]
    totalAdBreakAds: 0
    midrolls : []
    commercialDuration : 0
    lastAdFailed: false

    ' methods
    reset: tubiAds_reset
    getCuePoints: tubiAds_getCuepoints
    getAdsListViaRoku: tubiAds_getAdsListViaRoku
    hasAds: tubiAds_hasAds
    showCommercialBreakViaRoku: tubiAds_showCommercialBreakViaRoku
    cacheAdsList: tubiAds_cacheAdsList
    getCachedAdsList: tubiAds_getCachedAdsList
    getResumingPlayAds: tubiAds_getResumingPlayAds
    getCommaDelimitedMidrolls: tubiAds_getCommaDelimitedMidrolls
    populateUrl: tubiAds_populateUrl
    _: rodash()
  }
end function

' ----------------------------------------------
'  m.hasAds()
' Call to see if an ad preload found some ads to play
' ----------------------------------------------
function tubiAds_hasAds()
  return (m.allAdUnitsList.count() > 0)
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
    res = m.allAdUnitsList
    if res <> invalid and res.count() = 0
      res = invalid
    end if

    episode.nowPos = tmp
    
    m.lastAdsList = {
      cid: episode.id
      breakPos: breakPos
      list: res
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
' populateUrl
'
' create the url needed to make ad calls
' ----------------------------------------------
function tubiAds_populateUrl(episode) As String

  'create the url to be used for ad calls'
  params = {
    "platform": "roku"
    "appid": m.constants.settings.shortAppName
    "cid": episode.id
    "nowpos": episode.nowpos.ToStr()
    "model": m.constants.deviceInfo.model
    "deviceid": m.constants.deviceInfo.deviceId
    "pubid": episode.pubId
    "content-type": "hls"
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
  authInfo = m.utils.auth.getAuthInfo()
  if authInfo <> invalid and authInfo.userId <> invalid
    params["tubitvid"] = authInfo.userId
  end if

  'add if Linear/Live TV is on or off to ad call url
  'TODO: Bryan, uncomment when linear/live tv is added
  ' if GetGlobalAA().app.linearTV.linearTvOn = true
  '   params["linear"] = "1"
  ' end if

  params["sdk"] = "raf_vast"

  return m.utils.request.addParamsToUrl(m.constants.urls.adsBaseUrl, params)
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
  url = m.populateUrl(episode)

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
    }
    m.utils.log.error(FormatJSON(timeToFetchMessage), "adError", "no-ad-response", m.requestQueue)
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
        print "AD ID "; adUnit.adId
        
        'the ad server had no ads to return so sends us just the midroll times'
        if adUnit.adId = "empty"
          if m.midrolls.count() = 0 or (m.midrolls.count() = 1 and m.lastAdFailed = true)
            m.midrolls = [] 'reset the midrolls array in case there was a previous default midroll
            if adUnit.clickThrough <> invalid
              m.midrolls = m.getCommaDelimitedMidrolls(adUnit.clickThrough)
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
              m.midrolls = m.getCommaDelimitedMidrolls(adUnit.clickThrough)
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
function tubiAds_showCommercialBreakViaRoku(containerNode)
  ' ShowVariable(m.allAdUnitsList, "ALL AD UNITS LIST", 4)
  if m.allAdUnitsList.count() > 0
    currentAdPosition = 1
    for each adUnitsListContainer in m.allAdUnitsList
      if adUnitsListContainer.adUnitsList <> invalid and adUnitsListContainer.adUnitsList.count() > 0
        if adUnitsListContainer.type <> invalid and adUnitsListContainer.type = "roku"

          'create the object that will populate the "Ad 1/5" text overlay in RAF
          screenCount = {
            start: currentAdPosition
            total: m.totalAdBreakAds
          }

          ' NOTE: Don't pass in containerNode, which currently has an intermittent crash on 2450X (Dec 2017, RAF 2.0314)
          isCompleted = m.roAdFramework.showAds(adUnitsListContainer.adUnitsList[0], screenCount)

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
' getCuePoints
'
' gets the cuepoints for the passed in episode and attach them to ads object
' ----------------------------------------------
function tubiAds_getCuepoints(episode)
  'get the cuepoints synchronously
  options = {
    params: {
      format: "json"
      pubid: episode.pubId
      platform: "roku"
      cid: episode.id
    }
  }
  cuepointsReq = m.utils.request.createAsync(m.constants.urls.cuepointsBaseUrl, "getCuePoints", options)
  cuepointsJson = cuepointsReq.runSynchronous(5)

  'parse the returned JSON to a Brightscript object - should return an array
  if cuepointsJson <> invalid
    cuepoints = ParseJson(cuepointsJson)
  end if

  if type(cuepoints) = "roArray" and cuepoints.count() > 0
    m.midrolls = cuepoints
    return cuepoints
  end if

  'return invalid by default
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
  return (m.allAdUnitsList.count() > 0)
end function
