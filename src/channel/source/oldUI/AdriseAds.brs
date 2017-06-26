function AdriseAds (utils, playerPort)

  'Add Support for Roku Advertising Framework
  roAdFramework = Roku_Ads()
  
  'set the preferences for the Roku Advertising Framework so we never use their ad server if our server returns no ads
  'and max 2 retries if there is no ads returned from our server
  roAdFramework.setAdPrefs(false, 2)
  
  'turn Nielsen DAR on for the Roku Advertising Framework
  roAdFramework.enableNielsenDAR(true)

  'set the Nielsen application id for Tubi TV
  roAdFramework.setNielsenAppId("PC60BD376-8551-4688-BEF4-E8B45A39D4C7")

  'turn on debug output for RAF
  roAdFramework.setDebugOutput(false)


  return {
    roAdFramework: roAdFramework
    ' isRokuAdFrameworkOn: false 'use to turn Roku Ad Framework on or off
    isRokuAdFrameworkOn: true

    allAdUnitsList:[]
    totalAdBreakAds: 0
    adUnitsList: [] 'used when Roku Ad Framework is turned off
    midrolls : []
    commercialDuration : 0
    videoAdErrorCount: 0
    lastAdFailed: false

    'the same message port that the player uses, this port will be used for view through = 100 ad pixels, as well as ad failure tracking pixels
    'each ad will have it's own port for ad video events like video start and video end as well as impression and view through < 100 ad pixels
    'this should minimize the number of roUrlTransfer objects stored in memory at any given time, as well as allow the various ports to listen
    'for any async responses that we expect back
    playerPort: playerPort

    ' baseUrl: "http://ads.adrise1.tv/" 'use to avoid getting ads during testing
    baseUrl: "http://ads.adrise.tv/"

    ' methods
	  reset: adriseAds_reset
    getCommaDelimitedMidrolls: adriseAds_getCommaDelimitedMidrolls
    getAdsList: adriseAds_getAdsList
	  getAdsListViaRoku: adriseAds_getAdsListViaRoku
    getAdUnitsListTraditional: adriseAds_getAdUnitsListTraditional
	  getAdUnitFromXml: adriseAds_getAdUnitFromXml
    getCompanionOverlay: adriseAds_getCompanionOverlay
    cacheAdsList: adriseAds_cacheAdsList
    getCachedAdsList: adriseAds_getCachedAdsList
    showVideoAd: adriseAds_showVideoAd
    showCommercialBreak: adriseAds_showCommercialBreak
    showCommercialBreakViaRoku: adriseAds_showCommercialBreakViaRoku
    checkForCommercialBreak: adriseAds_checkForCommercialBreak
    getCuePoints: adriseAds_getCuepoints
    populateUrl: adriseAds_populateUrl
    getResumingPlayAds: adriseAds_getResumingPlayAds

    ' innovid irolls
    showInnovidAd : adriseAds_showInnovidAd,

	  ' selectable ad items
	  selectableAds: AdriseSelectableAds(utils)

    createSkippableAd: createSkippableAd
    skippableOverlay: invalid

	  adIsLexusInteractive: function(adUnit)
      return false
    end function

    currentAdUnit: {}

	  utils: utils
	  doTest: true
  }
end function

' ----------------------------------------------
'  m.reset()
'  call when starting a content video to
'  clear everything out
' ----------------------------------------------
function adriseAds_reset()
  m.allAdUnitsList = []
  m.midrolls = []
  m.videoAdErrorCount = 0
  m.commercialDuration = 0
  m.lastAdFailed = false
end function

'create an array of midrolls from a comma delimited string of midrolls - for ex. "100,300,600,850"
function adriseAds_getCommaDelimitedMidrolls(midrollsString)
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


'cache an ads list for an ad break - typically occurs 4-7 seconds before an ad break actually runs
'we keep the most recently cached ad break at m.lastAdsList
function adriseAds_cacheAdsList(episode, breakPos, playerSettings)
	if(m.lastAdsList = invalid or m.lastAdsList.breakPos <> breakPos or m.lastAdsList.cid <> episode.adrise_contentId) 
    tmp = episode.nowPos
    episode.nowPos = breakPos

    if m.isRokuAdFrameworkOn = true
      m.getAdsListViaRoku(episode, playerSettings)
      res = m.allAdUnitsList
    else
      res = m.getAdsList(episode, playerSettings)
    end if

    if res.count() = 0
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

function adriseAds_getCachedAdsList(episode)
  if m.lastAdsList <> invalid and episode.id = m.lastAdsList.cid and episode.nowPos = m.lastAdsList.breakPos
    return m.lastAdsList.list
  end if
  return invalid
end function

'create the url needed to make ad calls
function adriseAds_populateUrl(episode, playerSettings)
  settings = m.utils.getSettings()

  deviceId = "&deviceid=" + m.utils.deviceInfo.deviceId
  model = "&model=" + m.utils.deviceInfo.model

  ' add Roku Advertiser Id (RIDA) to ad call url  
  urlAdId = ""
  if m.utils.deviceInfo.deviceAdId <> invalid
    urlAdId = "&advid=" + m.utils.deviceInfo.deviceAdId
  end if

  optOut = "&opt-out=0"
  if m.utils.deviceInfo.isAdIdTrackingDisabled = true
    optOut = "&opt-out=1"
  end if

  'add TubiTV user/registration id to ad call url
  urlTubiId = ""
  userData = m.utils.getUserData()
  if userData <> invalid and userData.token <> invalid
    urlTubiId = "&tubitvid=" + userData.token
  end if

  'add if Linear/Live TV is on or off to ad call url
  isLinear = ""
  if GetGlobalAA().app.linearTV.linearTvOn = true
    isLinear = "&linear=1"
  end if

  'select the ad sdk
  adSdk = "&sdk=5.0_video"
  if m.isRokuAdFrameworkOn = true
    adSdk = "&sdk=raf_vast"
  end if

  appId = "&appid=" + settings.shortAppName
  pubId = "&pubid=" + settings.pubId  'default pub id from settings
  contentType = "&content-type=hls"
  if playerSettings <> invalid
    if type(playerSettings.appId) = "String" or type(playerSettings.appId) = "roString"
      appId = "&appid=" + playerSettings.appId
    end if

    if type(playerSettings.pubId) = "String" or type(playerSettings.pubId) = "roString"
      pubId = "&pubid=" + playerSettings.pubId
    end if

    if type(playerSettings.contentType) = "String" or type(playerSettings.contentType) = "roString"
      contentType = "&content-type=" + playerSettings.contentType
    end if
  end if

  cid = ""
  nowPos = "&nowpos=0"
  if episode <> invalid
    if type(episode.id) = "String" or type(episode.id) = "roString"
      cid = "&cid=" + episode.id
    end if

    if type(episode.nowPos) = "roFloat" or type(episode.nowPos) = "roInteger"
      nowPos = "&nowpos=" + Int(episode.nowPos).ToStr()
    end if
  end if

  'create the url to be used for ad calls'
  url = m.baseUrl + "?platform=roku" + appId + adSdk + cid + nowPos + model + deviceId + optOut + urlAdId + urlTubiId + pubId + contentType + isLinear + "&_=" + RND(1000000000000).ToStr()

  return url
end function

' ----------------------------------------------
'  m.getAdsListViaRoku(episode, playerSettings)
' ----------------------------------------------
function adriseAds_getAdsListViaRoku(episode, playerSettings)
  m.allAdUnitsList = []

  'set the content length (as stated in RAF documentation for Nielsen functionality)
  if episode.length <> invalid
    m.roAdFramework.setContentLength(episode.length)
  else
    m.roAdFramework.setContentLength()
  end if

  'set the content genre (as stated in RAF documentation for Nielsen functionality)
  if episode.nielsenGenre <> invalid
    m.roAdFramework.setNielsenGenre(episode.nielsenGenre)
  end if

  'set the program id/title (as stated in RAF documentation for Nielsen functionality)
  if episode.isParentSeries = true
    m.roAdFramework.setNielsenProgramId(episode.parentTitle)
  else
    m.roAdFramework.setNielsenProgramId(episode.title)
  end if

  'get the url for making the ad call
  url = m.populateUrl(episode, playerSettings)
  ' url = "http://ads.adrise.tv/test/hardcoded-response.php?n=8"


  'set the url for the Roku Advertising Framework
  m.roAdFramework.setAdUrl(url)

  'get the array of ad units back from the Roku Advertising Framework(RAF)
  'adUnits are called adPods in RAF documentation
  currentAdUnitsList = m.roAdFramework.getAds()

  ' ShowVarSimple(currentAdUnitsList, "Ad Unit List")

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
        
        'if the adUnit contains an ad that needs to use the adRise Ad SDK
        if adUnit.adId = "default"
          'if adUnitType is different from the last adUnitType (meaning a new adUnitsListContainer is needed)
          'push the last adUnitsListContainer to m.allAdUnitsList, otherwise we will just add to the last adUnitsListContainer
          'set up the adContainer for adrise type if needed
          if adUnitType <> "adrise"
            if adUnitsListContainer.type <> "" 'means we've already built at least one adUnitsListContainer
              m.allAdUnitsList.push(adUnitsListContainer)
            end if
            adUnitType = "adrise"
            adUnitsListContainer = {
              type: adUnitType
              adUnitsList: []
            }
          end if
          
          'get the adrise adUnit object from the xml passed through the ClickThrough tag
          'and push it to the adUnitsList in the adUnitsListContainer'
          traditionalAdXmlString = adUnit.clickThrough
          adriseAdUnitsList = m.getAdUnitsListTraditional(episode, playerSettings, traditionalAdXmlString) 'in most cases this should return back an adUnitsList with one adUnit it it'
          
          'add duration to m.commercialDuration
          for each adUnit in adriseAdUnitsList
            if adUnit.duration <> invalid
              m.commercialDuration = m.commercialDuration + Val(adUnit.duration)
            end if
          end for

          if adriseAdUnitsList <> invalid and adriseAdUnitsList.count() > 0
            adUnitsListContainer.adUnitsList.append(adriseAdUnitsList)
          else
            print "no ad units returned via ClickThrough"
            if m.midrolls.count() = 0 or (m.midrolls.count() = 1 and m.lastAdFailed = true)
              'set the default midroll if something went wrong with the traditional ad XML and there were no midrolls already
              m.midrolls = [episode.nowpos + 300]
              m.lastAdFailed = true
            end if
          end if
        
        'the ad server had no ads to return so sends us just the midroll times'
        else if adUnit.adId = "empty"
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
                  renderSequence: currentAdUnitsList[0].renderSequence
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

function adriseAds_getAdUnitsListTraditional(episode, playerSettings, traditionalAdXmlString)

  'replace HTLM encoding of special characters with actual characters (ie. &lt; becomes < )
  traditionalAdXmlString = traditionalAdXmlString.Replace("&lt;", "<")
  traditionalAdXmlString = traditionalAdXmlString.Replace("&gt;", ">")
  traditionalAdXmlString = traditionalAdXmlString.Replace("&quot;", ">")
  traditionalAdXmlString = traditionalAdXmlString.Replace("&#91", "[")
  traditionalAdXmlString = traditionalAdXmlString.Replace("&#93", "]")

  xml = CreateObject("roXMLElement")

  ' make sure that the xml pulled from the clickThrough RAF XML doc is valid and useable
  if not xml.Parse(traditionalAdXmlString) or xml.GetName() <> "feed" or islist(xml.GetBody()) = false
    m.utils.log.info(playerSettings.playerPort, "apiBad", "no-ads-in-xml", "error with traditional ad xml - nothing returned")
    print ""
    return []
  end if

  adUnitsList = []

  chosenAdIndex = -1
  adOptions = xml.ad_options

  '<<<<<<<<<< USED FOR SELECTABLE ADS >>>>>>>>>>>>>>'
  if(adOptions.count() > 1)
    chosenAdIndex = m.selectableAds.getUserChoice(adOptions, xml.metadata.duration.getText().toInt(), playerSettings)
  end if
  '<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>'

  if (chosenAdIndex = -1)
    chosenAdIndex = xml.metadata.default.getText().toInt()
  end if

  'set the duration for use in the pre-ad splash screens
  m.commercialDuration = adOptions[chosenAdIndex].ad_duration.GetText().toInt()

  'add the midroll times if using traditional ad XML. Ideally, this should only happen on prerolls
  'However if there is only 1 midroll and the last ad failed, it means a default midroll time of nowpos + 300 was previously used
  if m.midrolls.count() = 0 or (m.midrolls.count() = 1 and m.lastAdFailed = true)
    midrolls = []
    for each breakpoint in adOptions[chosenAdIndex].break.position
      bpi = breakpoint.getText().toInt()
      midrolls.push(bpi)
    end for
    m.midrolls = midrolls

    'just used for printing midroll times
    for i=0 to m.midrolls.count()-1 step +1
       breakpoint = m.midrolls[i]
       ' print "breakpoint " i ; " " ; breakpoint
    end for
  end if

  'create the list of ad units that will play in this ad break
  ads = adOptions[chosenAdIndex].ads.ad
  if ads.count() > 0 'prevent app from crashing if there is an error in ad xml where ads tag is empty
    for each adXml in ads
      adUnit = m.getAdUnitFromXml(adXml)
      if(adUnit <> invalid)
        adUnitsList.push(adUnit)
      end if
    end for
  end if

  return adUnitsList
end function

'The old way of getting ads. Only to be used if we turn off Roku Advertising Framework
function adriseAds_getAdsList(episode, playerSettings)
  url = m.populateUrl(episode, playerSettings)

  playerSettings.lastAdUrl = url
  adResponse = m.utils.getTextFile(url, "getAdsList")

  adUnitsList = m.getAdUnitsListTraditional(episode, playerSettings, adResponse)

  return adUnitsList
end function

'parse the ad response xml into a brightscript object that we can use
function adriseAds_getAdUnitFromXml(adXml)
    streams = []

    if adXml.media.renditions <> invalid
      renditions = adXml.media.renditions.rendition
      for each rendition in renditions
        if StrToI(ValidStr(rendition.video_height)) > 720
          definition = "hd"
        else
          definition = "sd"
        end if

        streams.push({
            url: rendition.url.getText()
            bitrate: StrToI(rendition.video_bitrate_kbs.getText())
            format: adXml.media.streamformat.getText()
            quality: definition
        })
      end for
    end if

    viewthru = []
    viewthru[0]  = m.utils.getTrackingTags(adXml.media.trackingevents.tracking_0)
    viewthru[25] = m.utils.getTrackingTags(adXml.media.trackingevents.tracking_25)
    viewthru[50] = m.utils.getTrackingTags(adXml.media.trackingevents.tracking_50)
    viewthru[75] = m.utils.getTrackingTags(adXml.media.trackingevents.tracking_75)
    viewthru[100]= m.utils.getTrackingTags(adXml.media.trackingevents.tracking_100)

    adUnit = {
      streams : streams
      viewthru: viewthru
      adType : "video"

      id : adXml.ad_id.GetText()
      contentType : adXml.contentType.GetText()
      shortDescriptionLine1 : adXml.title.GetText()
      shortDescriptionLine2 : ""
      description : adXml.synopsis.GetText()
      rating : adXml.rating.GetText()
      genres : adXml.genres.GetText()
      starRating : adXml.starrating.GetText()
      categories : ""
      title : adXml.title.GetText()
      runtime : adXml.runtime.GetText()

      ' these are actually part of <adXml sdImg= "" hdImg=""/>
      sDPosterUrl : adXml@sdImg
      hDPosterUrl : adXml@hdImg

      impTrack : m.utils.getTrackingTags(adXml.imptracking)

      clickTrack : m.utils.getTrackingTags(adXml.clicktracking)

      duration : adXml.media.duration.GetText()
      pluginID : adXml.media.pluginID.GetText()

      streamQualities : adXml.media.streamQuality.GetText()
      streamBitrates : [0]
      streamFormat : adXml.media.streamFormat.GetText()
      srt : ""
      minBandwidth : 20
      currentOption : 0
      totalOptions : 0
      adIsSkippable: false
      adIsSelectable: false
    }

    'Determine if there are any type of companion ads running
    if adXml.companion_ad.GetAttributes().type <> invalid
      m.utils.log.info(m.playerPort, "clientInfo", "companion-ad", "THERE IS A COMPANION AD")
      companionAttributes = adXml.companion_ad.GetAttributes()

      'if the companion ad is Brightline, add Brightline information for companion ads to adUnit object.
      'Only run Brightline companion ads if there is a companion ad ID
      if companionAttributes.type = "brightline"
        if (adXml.companion_ad.companion_id.GetText() <> "")
          adUnit.companionOverlay = m.getCompanionOverlay(adXml)
          adUnit.positionPoints = {
            lastSavedPos: 0
            positionPercentage: 0
            statusInterval: 0
          }
          adUnit.isBrightline = true
        end if

      else if companionAttributes.type = "iroll"
        adUnit.companionOverlay = m.getCompanionOverlay(adXml)
        if adUnit.companionOverlay.url <> invalid
          adUnit.isIroll = true
        end if
      
      'If ad is skippable, change the adIsSkippable property of the adUnit to true
      else if companionAttributes.type = "skippable"
        adUnit.adIsSkippable = true
      
      'If the add is selectable change the adIsSelectable property of the adUnit to true
      else if companionAttributes.type = "selectable"
        adUnit.adIsSelectable = true
      end if

    else if adXml.companion_ad.bookmark.GetText().len() > 0
      adUnit.companionOverlay = m.getCompanionOverlay(adXml)
      if adUnit.companionOverlay.bookmarkId <> invalid
        adUnit.isHouseAd = true
      end if
    end if

    'check if there are any bookmarkable house ads
    ' if (adXml.companion_ad.cli)

    
    if (adXml.interactivebar <> invalid)
      adUnit.adBar = []
      for each option in adXml.interactivebar.option
        adUnit.totalOptions = adUnit.totalOptions + 1
        urls = []
        for each pixel in option.url
          urls.push(pixel.getText())
        end for
        adUnit.adBar.push({
            img : option.img.GetText()
            urls : urls
          })
      end for

      adUnit.adbarThanksImage = adXml.interactivebar.thanks.img.GetText()
    end if
    return adUnit
end function


function adriseAds_showCommercialBreakViaRoku(canvas, playerSettings)
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

          isCompleted = m.roAdFramework.showAds(adUnitsListContainer.adUnitsList, screenCount)
          m.roadframework.mediator.util.xfers = []

          if isCompleted = false
            print "RAF ads not completed"
            return "CLOSED"
          end if
          currentAdPosition = currentAdPosition + adUnitsListContainer.adUnitsList.count()
        else if adUnitsListContainer.type <> invalid and adUnitsListContainer.type = "adrise"
          status = m.showCommercialBreak(canvas, adUnitsListContainer.adUnitsList, playerSettings)
          if status = "CLOSED"
            return status
          end if
          currentAdPosition = currentAdPosition + adUnitsListContainer.adUnitsList.count()
        end if
      end if
    end for
  end if
  
  return "COMPLETED"
end function


' ----------------------------------------------
' showCommercialBreak(canvas, videoAdsArray, playerSettings)
'
' calls showVideoAd in a loop
' returns:
' COMPLETED or CLOSED
'
' ----------------------------------------------
function adriseAds_showCommercialBreak(canvas, videoAdsArray, playerSettings)
  status = "COMPLETED"

  adDetails = {
    totalAds : videoAdsArray.Count()
    secondsLeft : m.commercialDuration
    adCounter : 0
  }

  adCounter = 0
  while adCounter < videoAdsArray.Count()
    adDetails.adCounter = adDetails.adCounter + 1
    
      status = m.showVideoAd(canvas, videoAdsArray[adCounter], adDetails, playerSettings)

    if status = "CLOSED"
      return status
    end if

    adDetails.secondsLeft = adDetails.secondsLeft - videoAdsArray[adCounter].Duration.toInt()

    if status = "COMPLETED"
      adCounter = adCounter + 1
    else
      canvas.Close()
      exit while
    end if
  end while

  return status
end function


' ----------------------------------------------
'  m.showVideoAd(canvas, adUnit, adDetails, playerSettings)
'
' returns "COMPLETED" or "CLOSED"
' ----------------------------------------------
function adriseAds_showVideoAd(canvas, adUnit, adDetails, playerSettings)
  settings = m.utils.getSettings()
  m.currentAdUnit = adUnit

  ' print "AD UNIT------------------ : "
  ' print adUnit
  ' print "----------------------------"

  if type(adUnit) <> "roAssociativeArray"
    houseAdDialog.close()
    canvas.close()
    return "COMPLETED"
  end if


  'canvas used for ad pre load screen and skippable ads
  canvas = CreateObject("roImageCanvas")
  adPort = CreateObject("roMessagePort")
  canvas.SetMessagePort(adPort)


  ' set up some messaging to display while the ad buffers
  m.utils.showAdLoadingLayer(canvas, playerSettings.displaySize, adDetails.secondsLeft, adDetails.adCounter, adDetails.totalAds, playerSettings.background, playerSettings.fontColor, playerSettings.loadingurl, playerSettings.appid)
  canvas.Show()

  
  'handle any special (interactive) ad cases
  if m.adIsLexusInteractive(adUnit)
    la = m.lexusAd(adUnit)
    la.setUpCanvas(true)
    la.paintCanvas()
    return la.doEventLoop()
  end if

  status = "COMPLETED"
  
  'check if ad is Brightline companion overlay type by checking if companionOverlay property exists
  'since Brighltine throws errors on 3.1 firmware, only serve Brightline ads on greater than 3.1 firmware
  version = m.utils.deviceInfo.firmwareVersion
  major = Int(version)
  
  if adUnit.isBrightline = true
    ip = BL_InteractivePreroll()

    ip.Append({
      onVideoPlayerStreamStarted: adriseAds_brightlineOnStartWrapper
      onVideoPlayerFullResult: adriseAds_brightlineOnCompleteWrapper
      onVideoPlayerPlaybackPosition: adriseAds_brightlineOnPositionWrapper
      onVideoPlayerPartialResult: adriseAds_brightlineOnExitWrapper
    })
    ip.initialize(adUnit)

    while true
      if m.currentAdUnit.status <> invalid
        status = m.currentAdUnit.status
        exit while
      end if 
    end while

    return status

  'check if ad is an Innovid iroll ad and if so, run it instead of using our normal player
  else if adUnit.isIroll = true then
    return m.showInnovidAd( adUnit )
  
  end if
  

  ' print "show video ad"
  ' ShowVarSimple(adUnit, "ad")


  player = CreateObject("roVideoPlayer")
  player.SetMessagePort(adPort)
  player.SetDestinationRect(canvas.GetCanvasRect())
  player.SetPositionNotificationPeriod(1)

  houseAdDialog = CreateObject("roMessageDialog")
  houseAdDialog.SetMessagePort(adPort)
  houseAdDialog.AddButton(0, "Ok")


  m.utils.trackEvent({
    trackType:  "imp"
    adUnit: adUnit
    port: adPort
    })
  player.AddContent(adUnit)

  player.Play()
  print "play ad start"

  lastSavedPos   = 0
  positionPercentage = 0
  statusInterval = adUnit.Duration.toInt() / 4

  showImageOptions = {
    z: 10
    cMode: "Source_over"
    h: 80
  }

  'create the overlay for a skippable ad if necessary
  if adUnit.adIsSkippable = true
    m.skippableOverlay = m.createSkippableAd(canvas, m.utils)
  end if

  while true
    currOption = adUnit.currentOption
    msg = wait(0, adPort)

    'handle any async responses (usually responses to ad pixel calls)
    'respObj is not used anywhere here since we don't care about the ad pixel responses
    'but calling getAsyncResponse is necessary to prevent memory leaks, so don't remove!!!
    if type(msg) = "roUrlEvent"
      respObj = m.utils.getAsyncResponse(msg, 0)
    end if

    if type(msg) = "roImageCanvasEvent"
      if (msg.isRemoteKeyPressed())
        i = msg.GetIndex()
        print "remote key pressed "  ; i
        if (i = 13)
          print "Pressed play"
        else if (i = 8)
          print "Pressed rewind"
        else if (i = 9)
          print "Pressed fast forward"
        else if (i = 6)
          print "Pressed select"

          'if ok is pressed during a skippable ad, after the skip time has elapsed
          if adUnit.adIsSkippable = true
            if m.skippableOverlay <> invalid and m.skippableOverlay.time >= m.skippableOverlay.skipTime
              status = "COMPLETED"
              print "skipped ad"

              'send tracking for skipped ad
              if adUnit.totalOptions > 0
                currOption = 0 'always set currOption = 0 for skippable ads

                'send the appropriate amount of tracking pixels depending on the XML structure
                if adUnit.adBar[currOption].urls <> invalid
                  numUrls = adUnit.adBar[currOption].urls.count()
                  print "adUnit.adBar[currOption].urls "; type(adUnit.adBar[currOption].urls)
                  for each url in adUnit.adBar[currOption].urls
                    m.utils.sendAsyncRequest(url, invalid, "adSelectMultiple")
                  end for
                else if adUnit.adBar[currOption].url <> invalid
                  m.utils.sendAsyncRequest(adUnit.adBar[currOption].url, invalid, "adSelectSingle")
                end if

              end if
              exit while
            end if
          end if

          if adUnit.adIsSelectable = true
            if adUnit.totalOptions > 0
              filename = adUnit.adbarThanksImage + "?" + RND(10000000).ToStr()
              showImageOptions.mode = "1"
              m.utils.showImageOnCanvas(filename, canvas, showImageOptions)
              canvas.Show()

              ' multiple urls
              if adUnit.adBar[currOption].urls <> invalid
                numUrls = adUnit.adBar[currOption].urls.count()
                print "adUnit.adBar[currOption].urls "; type(adUnit.adBar[currOption].urls)
                for each url in adUnit.adBar[currOption].urls
                  m.utils.sendAsyncRequest(url, invalid, "adSelectMultiple")
                end for
              else if adUnit.adBar[currOption].url <> invalid
                m.utils.sendAsyncRequest(adUnit.adBar[currOption].url, invalid, "adSelectSingle")
              end if

              ' disable future interactions:
              adUnit.totalOptions = 0
            end if
            m.selectableAds.handleAdClick(adUnit)
          end if

          if adUnit.isHouseAd = true
            authInfo = m.utils.getAuthInfo()
            if authInfo.accessToken <> invalid
              if adUnit.companionOverlay.bookmarkId <> invalid and adUnit.companionOverlay.bookmarkType <> invalid
                cp = GetGlobalAA().app.cp
                bookmarkContent = cp.getContentFromLocalPlaylists(adUnit.companionOverlay.bookmarkId, adUnit.companionOverlay.bookmarkType)

                if bookmarkContent <> invalid and bookmarkContent.id <> invalid
                  bookmarkContent.isBookmark = true
                  
                  'if house ad content is already bookmarked, remove it locally so we can add it to the front of the bookmarks list again
                  for i=0 to cp.userPlaylists[settings.bookmarkRegistry].episodes.count()-1
                    checkingBookmark = cp.userPlaylists.bookmarks.episodes[i]
                    if checkingBookmark.id <> invalid and checkingBookmark.id = bookmarkContent.id and checkingBookmark["type"] = bookmarkContent["type"]
                      cp.userPlaylists.bookmarks.episodes.delete(i)
                      exit for
                    end if
                  end for


                  serverType = "movie"
                  userPlaylistStore = "userPlaylistVideos"
                  if adUnit.companionOverlay.bookmarkType = "series"
                    serverType = "series"
                    userPlaylistStore = "userPlaylistSeries"
                  end if
                  
                  'add the bookmark to the local store and populate the bookmarks playlist
                  cp[userPlaylistStore][bookmarkContent.id] = bookmarkContent
                  cp.userPlaylists.bookmarks.episodes.unshift(cp[userPlaylistStore][bookmarkContent.id])

                  'add the bookmark to the server
                  bookmarkReqId = m.utils.updateBookmarks(bookmarkContent.id, "add", serverType, GetGlobalAA().app.detailScreen.detailsPort)
                  GetGlobalAA().app.detailScreen.addBookmarkReqIds[bookmarkReqId.toStr()] = true

                  houseAdDialog.updateText(bookmarkContent.title + " has been added to your queue.")
                  m.utils.log.info(adPort, "clientInfo", "house-ad-bookmark-success", "Bookmark added from house ad for content id " + bookmarkContent.id)
                  
                else
                  houseAdDialog.updateText("Sorry, we could not update your bookmark")
                  m.utils.log.warn(adPort, "clientWarn", "house-ad-bookmark-fail", "Could not ad bookmark from house ad due to not finding content")
                end if
              
              else
                houseAdDialog.updateText("Sorry, we could not update your bookmark")
                m.utils.log.warn(adPort, "clientWarn", "house-ad-bookmark-fail", "Could not ad bookmark from house ad due to incomplete data")
              end if
            
            else
              houseAdDialog.updateText("You must be logged in to add content to your queue.")
              m.utils.log.info(adPort, "clientInfo", "house-ad-bookmark-fail", "Bookmark not added because user not logged in")

            end if
            houseAdDialog.show()
          end if

        else if (i = 4 or i = 5) ' left or right
          if adUnit.adIsSelectable
            if (adUnit.totalOptions > 0)
              if i = 4
                currOption = currOption-1
              else if i = 5
                currOption = currOption+1
              end if
              if (currOption < adUnit.totalOptions and currOption >= 0)
                filename = adUnit.adBar[currOption].img + "?" + RND(10000000).ToStr()
                showImageOptions.mode = "2"
                m.utils.showImageOnCanvas(filename, canvas, showImageOptions)
                canvas.Show()
                adUnit.currentOption = currOption
              end if
            end if
          end if

        else if (i = 2 or i = 0)
          ' Pressed Up
          player.Stop()
          houseAdDialog.close()
          canvas.close()
          status = "CLOSED"
          return status
        else if (i = 3)
          print "Pressed down"
        end if
      else if (msg.isScreenClosed())
        houseAdDialog.close()
        canvas.close()
        return status
      end if
    else if type(msg) = "roVideoPlayerEvent"
      if msg.isStreamStarted()

      else if msg.isStatusMessage() and msg.getMessage() = "startup progress"
         'm.paintCanvas()
          ' print "loading progress " ; (msg.GetIndex() / 10)

      '---------------------------------
      else if msg.isFullResult()
        if (m.videoAdErrorCount = 0)
          if (positionPercentage >= 75)
            m.utils.trackEvent({
              trackType: "viewthru"
              adUnit: adUnit
              adPercentage: 100
              port: m.playerPort
            })
            houseAdDialog.close()
            canvas.close()
          end if
          exit while
        end if

      '---------------------------------
      else if msg.isPlaybackPosition()
        nowpos = msg.GetIndex()

        if nowpos = 0
          canvas.SetLayer(9, {TargetRect: {x: 0, y: 0, w: 0, h: 0}, CompositionMode: "Source"})

          if m.skippableOverlay <> invalid
            m.skippableOverlay.setup()
          end if

          m.utils.trackEvent({
            trackType: "viewthru"
            adUnit: adUnit
            adPercentage: positionPercentage
            port: m.playerPort
            })
        else if nowpos > 0
          if m.skippableOverlay <> invalid
            m.skippableOverlay.update(nowpos)
          end if

          if adUnit.totalOptions > 0 and adUnit.adBar[currOption].img <> ""
            filename = adUnit.adBar[currOption].img + "?" + RND(10000000).ToStr()
            canvas.SetLayer(10, {Url: filename, TargetRect: {x: 0 , y: 30, w: playerSettings.displaySize.w, h: 80}, CompositionMode: "Source_over" })
            canvas.Show()
          end if
          if abs(nowpos - lastSavedPos) >= statusInterval and positionPercentage < 75
            lastSavedPos = nowpos
            positionPercentage = positionPercentage + 25
            if (positionPercentage < 100)
              m.utils.trackEvent({
                adUnit: adUnit
                trackType: "viewthru"
                adPercentage: positionPercentage
                port: adPort
              })
            end if
          end if

        end if
      '---------------------------------
      else if msg.isPartialResult()
        print "isPartialResult"
        status = "COMPLETED"
        exit while

      '---------------------------------
      else if msg.isRequestFailed()
        print "Video(AD) request failure: "; msg.GetIndex(); " " msg.GetData(); " " msg.GetMessage(); " " msg.GetType()
        if (m.videoAdErrorCount < 2)
          m.videoAdErrorCount = m.videoAdErrorCount + 1
          player = CreateObject("roVideoPlayer")
          player.SetMessagePort(adPort)
          player.SetDestinationRect(canvas.GetCanvasRect())
          player.SetPositionNotificationPeriod(1)
          player.AddContent(adUnit)
          player.Play()
        else
          errorVal = "no url"
          if adUnit.streams.count() <> 0 and type(adUnit.streams[0]) = "roString"
            errorVal = adUnit.streams[0].url
          else if adUnit.companionOverlay <> invalid and adUnit.companionOverlay.url <> invalid
            errorVal = adUnit.companionOverlay.url
          end if

          errorMsg = "Video(AD) request failure on ad id: " + adUnit.id + "error index: " + msg.GetIndex() + " data: " + msg.GetData() +  " message: " + msg.GetMessage() +  " error type: " +  msg.GetType() + " ad url: " + errorVal
          m.utils.log.error(m.playerPort, "adError", "ad-video-failure", errorMsg)

          m.videoAdErrorCount = 0
          exit while
        end if

      '---------------------------------
      else if msg.isStatusMessage()
        if msg.GetMessage() = "start of play"
          ' once the video starts, clear out the canvas so it doesn't cover the video
          canvas.ClearLayer(2)
          canvas.SetLayer(1, {color: "#00000000", CompositionMode: "Source"})
          canvas.Show()
        end if
      end if

    else if type(msg) = "roMessageDialogEvent"
      if msg.isButtonPressed() and msg.GetIndex() = 0
        houseAdDialog.close()
      end if
    end if
  end while

  player.Stop()
  houseAdDialog.close()
  canvas.close()
  return status
end function

' ----------------------------------------------
' m.checkForCommercialBreak(nowpos, episode, playerSettings)
'
' returns break time if it's time to break for commercials, otherwise -1
' (break time should be close to nowpos)
' side effects:
'  will set the member of m.midrolls to -1
'  will set episode.playStart to the nowpos
' looks at:
'  m.midrolls
' modifies
'  m.midrolls
' ----------------------------------------------
function adriseAds_checkForCommercialBreak(nowpos, episode, playerSettings)
  if m.midrolls.count() > 0
    'iterate over each cue point
		for i=0 to m.midrolls.count()-1 step +1
			breakpoint = m.midrolls[i]
			if (breakpoint <> invalid)
        'if the player is 5 seconds before the cue point being iterated over
        'we will only make the ad call once (logic is in m.cacheAdsList)
          if(nowPos = breakpoint-5)
          'make a call to the server to get ads, and save ads in "cache" or memory
					m.cacheAdsList(episode, breakpoint, playerSettings)	
				end if

        'if the player is at the cue point being iterated and we haven't previously played this cuepoint
        'then return the cuepoint so the player can play an ad
				if nowpos = breakpoint
					'by setting the midroll time to -1000, you prevent the user from hitting that midroll again while
          'they are watching the content (for instance if the rewind to a point before a midroll they won't stumble on ads again)
					m.midrolls[i] = -1000
					return breakpoint
				end if
			end if
		end for
  end if
  return -1
end function


'gets the cuepoints for the passed in episode and attach them to ads object
function adriseAds_getCuepoints(episode)
  settings = m.utils.getSettings()

  'set default values for the pub id and episode id
  pubId = settings.pubid
  epId = "0"
  'set the url to get the cuepoints


  if episode <> invalid
    if type(episode.pubId) = "String" or type(episode.pubId) = "roString"
      pubId = episode.pubId
    end if
    
    if type(episode.id) = "String" or type(episode.id) = "roString"
      epId = episode.id
    end if
  end if

  cuepointUrl = settings.cuepointsUrlBase + "?format=json&pubid=" + pubId + "&platform=roku&cid=" + epId
  
  'get the cuepoints synchronously
  cuepointsJson = m.utils.getTextFile(cuepointUrl, "getCuePoints")

  'parse the returned JSON to a Brightscript object - should return an array
  cuepoints = ParseJson(cuepointsJson)

  if type(cuepoints) = "roArray" and cuepoints.count() > 0
    m.midrolls = cuepoints
    return cuepoints
  end if

  'return invalid by default
  return invalid
end function


'this function is to be called when resuming back to play after the player has stopped
'(usually due to the user pressing play or the user fast forwarding or rewinding). This function
'will make a call to the ads server and if it gets ads, store them in an appropriate place
'returns true if there are ads and false if there are no ads (aka the player can resume playing immediately without closing the player)
function adriseAds_getResumingPlayAds(episode, playerSettings)
  shouldBreak = false
  if m.isRokuAdFrameworkOn = true
    m.getAdsListViaRoku(episode, playerSettings)
    if m.allAdUnitsList.count() > 0
      shouldBreak = true
    end if
  else
    adsList = m.getAdsList(episode, playerSettings)
    if adsList.count() > 0
      playerSettings.resumePlayAdsList = adsList
      shouldBreak = true
    end if
  end if

  return shouldBreak
end function


'get any companion overlay info that might be contained within a companion ad tag in the ad xml response
'@adXml: roXMLElement, should be the roXMLElement of the ad response (5.0_video has a companion_ad tag)
function adriseAds_getCompanionOverlay (adXml)
  companionOverlay = {}

  if type(adXml) = "roXMLElement"
    companionAd = adXml.companion_ad
    
    if companionAd.iframe_resource.GetText().len() > 0
      companionOverlay.url = companionAd.iframe_resource.GetText().trim()
    end if

    if companionAd.companion_id.GetText().len() > 0
      companionOverlay.id = companionAd.companion_id.GetText().trim()
    end if

    'for house ads, expect a bookmark tag to contain a uri that looks like "house/video/:videoId" or "house/series/:seriesId"
    if companionAd.bookmark.GetText().left(5) = "house"
      clickUri = companionAd.bookmark.GetText()
      uriSegments = clickUri.Tokenize("/")
      companionOverlay.bookmarkId = uriSegments[2]
      companionOverlay.bookmarkType = uriSegments[1]
    end if

    ' trackingevents = {}
    ' if companionAd.click_through_event <> invalid and companionAd.click_through_event.GetText() <> invalid
    '   trackingevents.CLICK = [companionAd.click_through_event.GetText().trim()]
    ' end if
    ' if companionAd.creative_view_tracking_event <> invalid and companionAd.creative_view_tracking_event.GetText() <> invalid
    '   trackingevents.CREATIVEVIEW = [companionAd.creative_view_tracking_event.GetText().trim()]
    ' end if

    ' companionOverlay.trackingevents = trackingevents
  end if

  return companionOverlay
end function


'creates the companion overlay object for Brightline ads
function adriseAds_brightlineOnStartWrapper (roVideoPlayerEvent)
  adriseAds_brightlineOnStart(roVideoPlayerEvent)
end function

function adriseAds_brightlineOnStart(roVideoPlayerEvent)
  print "BRIGHTLINE AD START EVENT"
  m.app.utils.trackEvent({
    trackType:  "imp"
    adUnit: m.app.player.ads.currentAdUnit
    port: m.app.player.ads.playerPort
  })
end function

function adriseAds_brightlineOnCompleteWrapper (roVideoPlayerEvent)
  adriseAds_brightlineOnComplete(roVideoPlayerEvent)
end function  

function adriseAds_brightlineOnComplete (roVideoPlayerEvent)
  print "BRIGHTLINE AD COMPLETE EVENT"
  m.app.player.ads.currentAdUnit.status = "COMPLETED"
  m.app.utils.trackEvent({
    trackType:  "viewthru"
    adUnit: m.app.player.ads.currentAdUnit
    adPercentage: 100
    port: m.app.player.ads.playerPort
  })
end function  

function adriseAds_brightlineOnPositionWrapper (roVideoPlayerEvent)
  adriseAds_brightlineOnPosition(roVideoPlayerEvent)
end function

function adriseAds_brightlineOnPosition (roVideoPlayerEvent)
  adUnit = m.app.player.ads.currentAdUnit
  statusInterval = adUnit.Duration.toInt() / 4
  lastSavedPos = adUnit.positionPoints.lastSavedPos
  positionPercentage = adUnit.positionPoints.positionPercentage
  nowPos = roVideoPlayerEvent.GetIndex()

  if nowPos = 0
    m.app.utils.trackEvent({
      adUnit: adUnit
      trackType: "viewthru"
      adPercentage: positionPercentage
      port: m.app.player.ads.playerPort
    })
  else if abs(nowPos - lastSavedPos) > statusInterval and positionPercentage < 75
    m.app.player.ads.currentAdUnit.positionPoints.lastSavedPos = nowpos
    m.app.player.ads.currentAdUnit.positionPoints.positionPercentage = positionPercentage + 25
    positionPercentage = positionPercentage + 25
    if (positionPercentage < 100)
      m.app.utils.trackEvent({
          adUnit: adUnit
          trackType: "viewthru"
          adPercentage: positionPercentage
          port: m.app.player.ads.playerPort
        })
    end if
  end if
end function

function adriseAds_brightlineOnExitWrapper (isExited)
  adriseAds_brightlineOnExit(isExited)
end function  

function adriseAds_brightlineOnExit (isExited)
  print "BRIGHTLINE AD EXITED EVENT"
  if (isExited = true)
    m.app.player.ads.currentAdUnit.status = "COMPLETED"
  else
    m.app.player.ads.currentAdUnit.status = "CLOSED"
  end if
end function


'sets up the functionality for Innovid iroll ads
function adriseAds_showInnovidAd(adUnit as Object) as String
  tag_      = adUnit.companionOverlay.url
  tracking_ = adRiseAds_innovidAd_fetchTracking(adUnit)
  handler_  = {
    status : "COMPLETED",
    handleRemoteKeyPressed : function(msg_, iroll_) as Object
      if msg_.GetIndex() <> 0 then
        return { doExit : false }
      end if

      m.status = "CLOSED"

      return { doExit : true }
    end function
  }

  iroll_ = INNOVID_iRoll()
  iroll_.show( tag_, tracking_ , handler_ )

  ' update status value
  m.currentAdUnit.status = handler_.status

  return handler_.status
end function

'parses the adUnit data structure for tracking pixels into a format that iroll functionality requires
function adRiseAds_innovidAd_fetchTracking(adUnit) as Object
  tracking_ = []

  ' playback position tracking
  if GetInterface(adUnit.viewThru, "ifArray") <> invalid then
    vpoints_ = [
      { name : "start",         pos :   0 },
      { name : "firstquartile", pos :  25 },
      { name : "midpoint",      pos :  50 },
      { name : "thirdquartile", pos :  75 },
      { name : "complete",      pos : 100 }
    ]

    for each _ in vpoints_
      if GetInterface(adUnit.viewThru[ _.pos ], "ifEnum") <> invalid then
        for each url_ in adUnit.viewThru[ _.pos ]
          tracking_.Push({ name : _.name, url : url_ })
        end for
      end if
    end for
  end if

  ' imp tracking
  if GetInterface(adUnit.impTrack, "ifEnum") <> invalid then
    for each url_ in adUnit.impTrack
      tracking_.Push({ name : "impression", url : url_ })
    end for
  end if

  return tracking_
end function

