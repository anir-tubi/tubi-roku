print "Hot Patch 7 check"

settings = m.app.utils.getSettings()

if m.app.settings.shortAppName = "tubitv"
  m.app.player.ads.isRokuAdFrameworkOn = false

  m.app.linearTv.showLinearTv = true
  m.app.cp.showLinearTv = true

  m.app.linearTv.newLinearEpisodes = [
    {
      id: "249566",
      title: "Outnumbered - S01:E03"
    },
    {
      id: "276120",
      title: "The Smoke - S01:E03"
    },
    {
      id: "177689",
      title: "The Palace - S01:E03"
    },
    {
      id: "144159",
      title: "Space 1999 - S01:E03"
    },
    {
      id: "226826",
      title: "Whose Line is it Anyway? - S07:EP03"
    },
    {
      id: "226853",
      title: "I Love Money - S01:E01"
    },
    {
      id: "244950",
      title: "The Worst Week of my Life - S01:E03"
    },
    {
      id: "103546",
      title: "Top Boy - S01:E03"
    },
    {
      id: "149116",
      title: "Black Books - S02:E01"
    },
    {
      id: "185678",
      title: "City Homicide - S01:04"
    },
    {
      id: "157746",
      title: "Killers Behind Bars - S02:E03"
    },
    {
      id: "225341",
      title: "Charm School - S01:E02"
    },
    {
      id: "249567",
      title: "Outnumbered - S01:E04"
    },
    {
      id: "276121",
      title: "The Smoke - S01:E04"
    },
    {
      id: "177690",
      title: "The Palace - S01:E04"
    },
    {
      id: "144160",
      title: "Space 1999 - S01:E04"
    },
    {
      id: "226827",
      title: "Whose Line is it Anyway? - S07:EP04"
    },
    {
      id: "226854",
      title: "I Love Money - S01:E02 "
    },
    {
      id: "244951",
      title: "The Worst Week of my Life - S01:E04"
    },
    {
      id: "103547",
      title: "Top Boy - S01:E04"
    },
    {
      id: "149117",
      title: "Black Books - S02:E02"
    },
    {
      id: "185681",
      title: "City Homicide - S01:05"
    },
    {
      id: "157744",
      title: "Killers Behind Bars - S02:E04"
    },
    {
      id: "225342",
      title: "Charm School - S01:E03"
    },
    {
      id: "249568",
      title: "Outnumbered - S01:E05"
    },
    {
      id: "276122",
      title: "The Smoke - S01:E05"
    },
    {
      id: "177691",
      title: "The Palace - S01:E05"
    },
    {
      id: "144161",
      title: "Space 1999 - S01:E06"
    },
    {
      id: "226828",
      title: "Whose Line is it Anyway? - S07:EP06"
    },
    {
      id: "226855",
      title: "I Love Money - S01:E03"
    },
    {
      id: "244952",
      title: "The Worst Week of my Life - S01:E05"
    },
    {
      id: "149115",
      title: "Black Books - S01:E06"
    },
    {
      id: "186448",
      title: "City Homicide - S01:03"
    },
    {
      id: "157745",
      title: "Killers Behind Bars - S02:E01"
    },
    {
      id: "225658",
      title: "Charm School - S01:E01"
    }
  ]



  m.app.linearTv.linearEpisodes.Append(m.app.linearTv.newLinearEpisodes)

  ' m.app.linearTv.linearEpisodes.Append(m.app.linearTv.newLinearEpisodes)

  ' ' set Registration Wall
  ' m.app.cp.isRegWall = true
  ' premiereRegWallContent = [
  '   268533,
  '   268544,
  '   268563,
  '   269529,
  '   278532,
  '   278538,
  '   268504,
  '   268557,
  '   273558,
  '   273559,
  '   273579,
  '   268506,
  '   273560,
  '   273580,
  '   268510,
  '   268511,
  '   268558,
  '   268539,
  '   268512,
  '   268513,
  '   273561,
  '   268514,
  '   268515,
  '   268516,
  '   273562,
  '   273564,
  '   273566,
  '   268519,
  '   273567,
  '   278539,
  '   273568,
  '   268520,
  '   268546,
  '   268521,
  '   268522,
  '   278534,
  '   268523,
  '   278535,
  '   273565,
  '   268524,
  '   278536,
  '   268525,
  '   268526,
  '   268528,
  '   268529,
  '   268530,
  '   268531,
  '   268532,
  '   268534,
  '   268535,
  '   278537,
  '   268536,
  '   268507,
  '   268508,
  '   268509,
  '   268541,
  '   268561,
  '   268543,
  '   268545,
  '   268564,
  '   268548,
  '   278533,
  '   268517,
  '   268518,
  '   268559,
  '   278666,
  '   278667,
  '   268527,
  '   268560,
  '   268537,
  '   268538,
  '   268540,
  '   268542,
  '   268562,
  '   268547,
  '   268549,
  '   268565,
  '   268550,
  '   268551,
  '   278540,
  '   268552,
  '   278541,
  '   268553,
  '   268554,
  '   268555,
  '   269939,
  '   269940,
  '   269941,
  '   269942,
  '   269943,
  '   269532,
  '   268556,
  '   268566,
  '   269533,
  '   278542
  ' ]
  
  ' for each id in premiereRegWallContent
  '   m.app.cp.regWallContent.SetEntry(id, "premiere")
  ' end for

  'fixes the bug where there are more and more ads shown each ad break
  'remove this when next update is pushed through
  m.app.player.ads.getAdsListViaRoku = function(episode, playerSettings)
    m.allAdUnitsList = []

    'get the url for making the ad call
    url = m.populateUrl(episode, playerSettings)
    
    ' url = "http://ads.adrise.tv/?advid=&appid=hasbro&cid=113671&content-type=mp4&tubitvid=&deviceid=test&nowpos=1000&platform=roku&pubid=c039af8e770106abae773cba0b95e171&sdk=raf_vast&zid=test"

    'set the preferences for the Roku Advertising Framework so we never use their ad server if our server returns no ads
    'and max 2 retries if there is no ads returned from our server
    m.roAdFramework.setAdPrefs(false, 2)

    'set the url for the Roku Advertising Framework
    m.roAdFramework.setAdUrl(url)

    'get the array of ad units back from the Roku Advertising Framework(RAF)
    'adUnits are called adPods in RAF documentation
    currentAdUnitsList = m.roAdFramework.getAds()

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
      for each adUnit in currentAdUnitsList[0].ads
        if adUnit.adId <> invalid
          
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
          
          'the ad server had no ads to return so sent us just the midroll times'
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
  
end if
