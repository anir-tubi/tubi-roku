print "Hot Patch 8"

settings = m.app.utils.getSettings()

'themesFolder = "http://cdn.adrise.com/hotpatches/roku/themes/"

' theme = {
'   GridScreenLogoHD: themesFolder + "narrow_banner_HD.png"
'   GridScreenLogoSD: themesFolder + "narrow_banner_SD.png"
'   ' GridScreenDescriptionImageHD: themesFolder + "bubble-hd.png"
'   ' GridScreenDescriptionImageSD: themesFolder + "red_call_out_HD.png"
'   TallBannerHD: themesFolder + "wide_banner_HD.png"
'   TallBannerSD: themesFolder + "wide_banner_SD.png"
'   OverhangLogoHD: themesFolder + "wide_banner_HD.png"
'   OverhangLogoSD: themesFolder + "wide_banner_SD.png"
'   GridScreenBackgroundColor: "#000000"
'   BackgroundColor: "#000000"
' }



m.app.player.ads.isRokuAdFrameworkOn = false

if m.app.settings.shortAppName = "tubitv"
  
  'use to change the theme (the theme details are above), ie. headers and background colors
  ' m.app.utils.appManager.setTheme(theme)

  'remove rental option for tubitv
  m.app.settings.allowRentals = false

  m.app.linearTv.showLinearTv = true
  m.app.cp.showLinearTv = true

  m.app.linearTv.sdposterurl = "http://cdn.adrise.com/hotpatches/roku/LinearTV-beta-SD.jpg"
  m.app.linearTv.hdposterurl = "http://cdn.adrise.com/hotpatches/roku/LinearTV-beta-HD.jpg"

  m.app.linearTv.newLinearEpisodes = [
    {
      id: "283899",
      title: "Fire on the Amazon"
    },
    {
      id: "268528",
      title: "Lucky Numbers"
    },
    {
      id: "289849",
      title: "Solitary Man"
    },
    {
      id: "268515",
      title: "Crocodile Dundee in Los Angeles"
    },
    {
      id: "292018",
      title: "Capitalism: A Love Story"
    },
    {
      id: "273562",
      title: "Frankie and Johnny"
    },
    {
      id: "289827",
      title: "Mad Money"
    },
    {
      id: "283932",
      title: "Hellboy: Sword of Storms"
    },
    {
      id: "268532",
      title: "Masters of the Universe"
    },
    {
      id: "289781",
      title: "After Life"
    },
    {
      id: "289780",
      title: "According to Greta"
    },
    {
      id: "289828",
      title: "Maximum Conviction"
    },
    {
      id: "268533",
      title: "A Mighty Heart"
    }
]

  'the below format can be used to target live tv schedule to a specific date
  'get the current date
  ' date = CreateObject("roDateTime")
  ' date.ToLocalTime()
  ' formattedDate = date.AsDateString("short-date")

  ' if formattedDate = "10/24/15"
  '   m.app.linearTv.hdposterurl = "http://192.168.1.31:8080/rokuHotpatches/LinearTV-horror-HD.png"
  '   m.app.linearTv.sdposterurl = "http://192.168.1.31:8080/rokuHotpatches/LinearTV-horror-SD.png"

  '   m.app.linearTv.newLinearEpisodes = [
  '     {
  '       id: "282413",
  '       title: "George A. Romero's Day of the Dead"
  '     },
  '     {
  '       id: "284006",
  '       title: "The Terror Experiment"
  '     },
  '     {
  '       id: "241962",
  '       title: "Gangsters, Guns, and Zombies"
  '     },
  '     {
  '       id: "15585",
  '       title: "Aaah! Zombies!!!"
  '     },
  '     {
  '       id: "51147",
  '       title: "Toxic Zombies"
  '     },
  '     {
  '       id: "241969",
  '       title: "Outpost: Black Sun"
  '     },
  '     {
  '       id: "51151",
  '       title: "Zombie Brigade"
  '     },
  '     {
  '       id: "12682",
  '       title: "Zombie Undead"
  '     },
  '     {
  '       id: "289782",
  '       title: "All Souls Day"
  '      }
  '   ]
  ' end if  

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
end if

'fix tracking for play percentages
m.app.utils.trackEvent = function(evt)
  print "track event - hotpatch"
  time = CreateObject("roDateTime")

  startMS = 1000 * (60 * (60 * time.GetHours() + time.GetMinutes()) + time.GetSeconds()) + time.getMilliseconds()

  ' ------------AdUnit Events------------------
  if evt.trackType = "click" then
    For Each trackUrl in evt.adUnit.clickTrack
      trackUrl = strReplace(trackUrl, "[", "")
      trackUrl = strReplace(trackUrl, "]", "")
      asyncId = m.sendAsyncRequest(trackUrl, invalid, "trackClick")
    end for
  else if evt.trackType = "imp" then
    For Each trackUrl in evt.adUnit.impTrack
      trackUrl = strReplace(trackUrl, "[", "")
      trackUrl = strReplace(trackUrl, "]", "")
      if(evt.port = invalid)
        asyncId = m.sendAsyncRequest(trackUrl, invalid, "trackImp")
      else
        asyncId = m.sendAsyncRequest(trackUrl, evt.port, "trackImp")
      end if
    end for

  else if evt.trackType = "viewthru" then
    For Each trackUrl in evt.adUnit.viewthru[evt.adPercentage]
      trackUrl = strReplace(trackUrl, "[", "")
      trackUrl = strReplace(trackUrl, "]", "")
      evt.adUnit.viewthru[evt.adPercentage] = "" ' making sure it doesn't get fired again
      asyncId = m.sendAsyncRequest(trackUrl, invalid, "trackViewThru") ' + str(evt.adPercentage))
    end for
  'event tracking for non ad events
  else if evt.trackType <> invalid and m.deviceInfo.firmwareVersion > 3.01 then
    trackData = m.getTrackData(evt.trackType, evt.contentId, evt.progressPercent, evt.playerPosition, evt.deepLinkSource, evt.errorMessage)
    m.trackingDataToSend.push(trackData)

    if (evt.trackType <> "playProgress" and evt.trackType <> "linearPlayProgress") or m.trackingDataToSend.count() >= 5
      trackingDataToSendJSON = FormatJson(m.trackingDataToSend)
      trackDataToSendJSONEncoded = urlEncode(trackingDataToSendJSON)

      ' trackUrl = "http://tb.tu-int.com/extEvent?events=" + trackDataToSendJSONEncoded   'staging tracking server
      trackUrl = "http://cms.adrise.com/extEvent?events=" + trackDataToSendJSONEncoded    'production tracking server

      'for testing linear tv crashes only
        linearTrackTime = CreateObject("roDateTime")
        linearTrackTime.ToLocalTime()
        localTime = linearTrackTime.GetHours().toStr() + ":" + linearTrackTime.GetMinutes().toStr() + ":" + linearTrackTime.GetSeconds().toStr()

      '--------------------------'

      ' print "-------------TRACK URL-------------"
      ' print trackUrl; + " : " + localTime
      asyncId = m.sendAsyncRequest(trackUrl, invalid, "track" + evt.trackType)
      m.trackingDataToSend = []
    end if

  end if

  m.logEvent(evt)
  m.doGoogleAnalytics(evt)

end function

'fixes bug where ads with duration exactly divisible by 4 wouldn't show 75% and 100% pixels
m.app.player.ads.showVideoAd = function(canvas, adUnit, adDetails, playerSettings)
  m.currentAdUnit = adUnit

  ' print "AD UNIT------------------ : "
  ' print adUnit
  ' print "----------------------------"

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
  
  if (m.adIsBrightlineCompanionAd(adUnit) and major <> 3)
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
        print status 
        status = m.currentAdUnit.status
        exit while
      end if 
    end while

    return status
  end if
  

  ' print "show video ad"
  ' ShowVarSimple(adUnit, "ad")

  print "ad unit total options "; adUnit.totalOptions


  port = CreateObject("roMessagePort")
  canvas = CreateObject("roImageCanvas")
  canvas.SetMessagePort(port)

  m.utils.portWaitStarting(port)

  if type(adUnit) <> "roAssociativeArray"
    canvas.close()
    return "COMPLETED"
  end if

  player = CreateObject("roVideoPlayer")
  ' be sure to use the same message port for both the canvas and the player
  player.SetMessagePort(canvas.GetMessagePort())
  player.SetDestinationRect(canvas.GetCanvasRect())
  player.SetPositionNotificationPeriod(1)

  ' set up some messaging to display while the pre-roll buffers
  m.utils.showAdLoadingLayer(canvas, playerSettings.displaySize, adDetails.secondsLeft, adDetails.adCounter, adDetails.totalAds, playerSettings.background, playerSettings.fontColor, playerSettings.loadingurl, playerSettings.appid)
  canvas.Show()

  m.utils.trackEvent({
    trackType:  "imp"
    adUnit: adUnit
    port: port
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
    msg = wait(0, canvas.GetMessagePort())
    respObj = m.utils.getAsyncResponse(msg, 0)

    result = m.preprocessAdMessage(msg, adUnit, canvas, player, port, positionPercentage)
    if(result <> invalid)
      return result
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
          canvas.close()
          status = "CLOSED"
          return status
        else if (i = 3)
          print "Pressed down"
        end if
      else if (msg.isScreenClosed())
        canvas.close()
        return status
      end if
    else if type(msg) = "roVideoPlayerEvent"
      if msg.isStreamStarted()
        print "stream started"

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
            })
            canvas.close()
          end if
          exit while
        end if

      '---------------------------------
      else if msg.isPlaybackPosition()
        nowpos = msg.GetIndex()

        m.utils.globalMessageHandler(msg)
        if nowpos = 0
          canvas.SetLayer(9, {TargetRect: {x: 0, y: 0, w: 0, h: 0}, CompositionMode: "Source"})

          if m.skippableOverlay <> invalid
            m.skippableOverlay.setup()
          end if

          m.utils.trackEvent({
            trackType: "viewthru"
            adUnit: adUnit
            adPercentage: positionPercentage
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
                })
            end if
          end if

        end if
      '---------------------------------
      else if msg.isPartialResult()
        print "isPartialResult"
        status = "COMPLETED"
        print "partial"
        exit while

      '---------------------------------
      else if msg.isRequestFailed()
        print "Video(AD) request failure: "; msg.GetIndex(); " " msg.GetData(); " " msg.GetMessage(); " " msg.GetType()
        if (m.videoAdErrorCount < 2)
          m.videoAdErrorCount = m.videoAdErrorCount + 1
          player = CreateObject("roVideoPlayer")
          ' be sure to use the same message port for both the canvas and the player
          player.SetMessagePort(canvas.GetMessagePort())
          player.SetDestinationRect(canvas.GetCanvasRect())
          player.SetPositionNotificationPeriod(1)
          player.AddContent(adUnit)
          player.Play()
        else
          m.utils.trackEvent({
            trackType: "adFailure"
            value: adUnit.streams[0].url 'the ad url
            ctx: msg.GetMessage()
          })
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
    end if
  end while

  player.Stop()
  canvas.close()
  return status
end function


'update the getAllEpisodesForPlaylistFromServer call to work with updated api
m.app.cp.getChildItem = function(playlist as Object, itemIndex as Integer) as Object
  if playlist.haveAllEpisodes = invalid
    m.getAllEpisodesForPlaylistFromServer(playlist, "gridscreen")
  end if

  if itemIndex < playlist.episodes.count()
    episode = playlist.episodes[itemIndex]
    return episode
  else
    return invalid
  end if
end function
m.app.cp.getEpisodeInPlaylist = m.app.cp.getChildItem


'update the getPlaylistFromXmlObj call to work with updated api'
m.app.cp.getAllPlaylistsFromServer = function()
  xml = m.utils.getXml(m.urls.getPlaylists, "getApp_v2")

  if xml = invalid or xml.GetName() <> "app"
    return false
  end if

  m.playlists = []
  errorMessage = xml.errormessage.getText()
  if errorMessage <> ""
    m.errorMessage = errorMessage
  else
    if GetGlobalAA().app.gridscreen.rowOffset <> invalid
      rowOffset = GetGlobalAA().app.gridscreen.rowOffset
    else
      rowOffset = 0
    end if
    m.playlistCounter = 0
    for each child in xml.children.level
      m.path[0] = m.playlistCounter + rowOffset

      m.playlists.push(m.getPlaylistFromXmlObj(child, m.imageSize, 1, "gridscreen"))
      m.playlistCounter = m.playlistCounter + 1
    end for
  end if
end function

'update to work with updated api (landscape gridscreen images)'
m.app.cp.getPlaylistFromXmlObj = function(obj, imageSize, depth, source)
  title = ValidStr(obj.title.getText())
  videosIdString = ""
  items = []
  videos = {}
  children = obj.children.getChildElements()
  count = 0
  
  for each child in children  'child = level or video for a row/category/playlist
    'add linear TV content if necessary
    if m.playlistCounter = 0 and count = 2 and depth = 1 and m.showLinearTV = true and m.linearTvAdded = false
      linearItem = {
        type : "linear"
        title: "Live TV (beta)"
        description: "Tubi TV brings you TV programmed for you. Just sit back and enjoy." + chr(10) + chr(10) + "Send us your feedback:" + chr(10) + "support@tubitv.com"
        shortDescriptionLine1 : "Live TV (beta)"
        sdposterurl: GetGlobalAA().app.linearTv.sdposterurl
        hdposterurl: GetGlobalAA().app.linearTv.hdposterurl
      }
      items.push(linearItem)
      m.linearTvAdded = true
      count = count + 1
    end if

    id = child.id.getText()

    if child.getName() = "video"
      item = {
        type : "video"
        title: child.title.getText()
        id: id
        adrise_contentId: id
        position: count
      }

      videos[id] = item
      videosIdString = videosIdString + "," + id
      items.push({})
      
      'set up autoplay for videos (from deeplinking usually or maybe from search screen)
      if(id = m.autoplayId and m.autoplayIsSeries = false)
        p = []
        for i=0 to depth-1 step +1
          p[i] = m.path[i]
        end for
        p.push(count)
        m.autoplayData = { item: item, path: p, depth: depth }
        m.autoplayId = invalid
        print "have autoplay---------------------"
      end if

    else 'child.getName() = 'level' -> means it is a series
      thumbUrl = invalid
      settings = m.utils.getSettings()
      if settings.GridStyle = "two-row-flat-landscape-custom"
        if child.posterartUrl <> invalid
          thumbUrl = child.posterartUrl.getText()
        end if
      else
        if child.thumbnailUrl <> invalid
          thumbUrl = child.thumbnailUrl.getText()
        end if
      end if

      m.path[depth] = count

      item = {
        type : "level"
        title: child.title.getText()
        description: child.description.getText()
        shortDescriptionLine1 : child.title.getText()
        'shortDescriptionLine2 : child.description.getText()
        hdposterurl: thumbUrl
        sdPosterURL: thumbUrl
        playlist: m.getPlaylistFromXmlObj(child, imageSize, depth+1, source)
      }

      items.push(item)

      'set up autoplay for series (from deeplinking usually or maybe from search screen)
      if(id = m.autoplayId and m.autoplayIsSeries = true)
        p = []
        for i=0 to depth-1 step +1
          p[i] = m.path[i]
        end for
        p.push(count)
        m.autoplayData = { item: item, path: p, depth: depth }
        m.autoplayId = invalid
        print "have autoplay---------------------"
      end if

    end if
    count = count + 1
  end for

  'remove the leading comma in videosIdString
  videosIdString = videosIdString.mid(1)

  return {
    name: obj.title.getText()
    depth: depth
    videosPrelim: videos
    episodes: items
    videosIdString: videosIdString
  }
end function

'update to work with updated api (landscape gridscreen images)'
m.app.cp.getAllEpisodesForPlaylistFromServer = function(playlist, source)
  
settings = m.utils.getSettings()

  if playlist.videosIdString = invalid or playlist.videosIdString = ""
    return invalid
  end if

  xml = m.utils.getXml(m.urls.getVideos + playlist.videosIdString, "getVideos_v2")

  defaultVideoPath = invalid
  defaultStaticPath = invalid

  splitter = CreateObject("roRegex", ",", "")
  if xml <> invalid and xml.video <> invalid
    for each videoDetails in xml.video
      xmlId =  videoDetails.id.getText()

      if xmlId <> invalid and xmlId <> "" and playlist.videosPrelim[xmlId] <> invalid
        if source = "gridscreen"
          if settings.GridStyle = "Flat-16x9" 'setting images for landscape styled grid screen
            if videoDetails.thumbnailUrl <> invalid
              thumbUrl = videoDetails.thumbnailUrl.getText()
            end if
            if videoDetails.thumbnailRatio <> invalid
              playlist.videosPrelim[xmlId].thumbnailRatio = val(videoDetails.thumbnailRatio.getText())
            end if
          else 'setting images for portait (Flat-Movie) styled grid screen and one funny app that uses 'two-row-flat-landscape-custom' style
            if videoDetails.posterartUrl <> invalid
              thumbUrl = videoDetails.posterartUrl.getText()
            end if
            if videoDetails.posterartRatio <> invalid
              playlist.videosPrelim[xmlId].thumbnailRatio = val(videoDetails.posterartRatio.getText())
            end if
          end if
        else if source = "episode" 'playlist is for episode list screen
          if videoDetails.thumbnailUrl <> invalid
            thumbUrl = videoDetails.thumbnailUrl.getText()
          end if
          if videoDetails.thumbnailRatio <> invalid
            playlist.videosPrelim[xmlId].thumbnailRatio = val(videoDetails.thumbnailRatio.getText())
          end if
        else if source = "search" 'playlist is for search screen
          if videoDetails.posterartUrl <> invalid
            thumbUrl = videoDetails.posterartUrl.getText()
          end if
          if videoDetails.posterartRatio <> invalid
            playlist.videosPrelim[xmlId].thumbnailRatio = val(videoDetails.posterartRatio.getText())
          end if            
        end if

        if defaultStaticPath <> invalid and not _isUrl(thumbUrl)
          thumbUrl = defaultStaticPath + thumbUrl
          playlist.videosPrelim[xmlId].defaultStaticPath = defaultStaticPath
        end if
        playlist.videosPrelim[xmlId].sdPosterURL = thumbUrl
        playlist.videosPrelim[xmlId].hdPosterURL = thumbUrl
        playlist.videosPrelim[xmlId].description = ValidStr(videoDetails.description.getText())

        playlist.videosPrelim[xmlId].longDescription = playlist.videosPrelim[xmlId].description
        playlist.videosPrelim[xmlId].shortDescriptionLine1 = playlist.videosPrelim[xmlId].title
        ' playlist.videosPrelim[xmlId].shortDescriptionLine2 = playlist.videosPrelim[xmlId].description
        url = videoDetails.url.getText()
        if defaultVideoPath <> invalid and not _isUrl(url)
          url = defaultVideoPath + url
        end if

        playlist.videosPrelim[xmlId].url = url

        if videoDetails.rating <> invalid
          playlist.videosPrelim[xmlId].rating = videoDetails.rating.getText()
        end if
        if videoDetails.language <> invalid
          playlist.videosPrelim[xmlId].language = videoDetails.language.getText()
        end if
        if videoDetails.country <> invalid
          playlist.videosPrelim[xmlId].country = videoDetails.country.getText()
        end if
        if videoDetails.director <> invalid
          playlist.videosPrelim[xmlId].director = videoDetails.director.getText()
        end if
        if videoDetails.starring <> invalid
          playlist.videosPrelim[xmlId].actors = splitter.Split(videoDetails.starring.getText())
        end if
        if videoDetails.publisherId <> invalid
          playlist.videosPrelim[xmlId].pubId = videoDetails.publisherId.getText()
        end if
        if videoDetails.releaseDate <> invalid
          playlist.videosPrelim[xmlId].releaseDate = videoDetails.year.getText()
        end if
        if videoDetails.rentalPrice <> invalid
          playlist.videosPrelim[xmlId].rentalPrice = ValidStr(videoDetails.rentalPrice.getText())
          if playlist.videosPrelim[xmlId].rentalPrice = ""
            playlist.videosPrelim[xmlId].rentalPrice = invalid
          end if
        end if

        playlist.videosPrelim[xmlId].length = Int(StrToI(ValidStr(videoDetails.duration.getText())))

        if (playlist.videosPrelim[xmlId].url.instr(1,".m3u8") > 1)
          playlist.videosPrelim[xmlId].streamFormat = "hls"
          playlist.videosPrelim[xmlId].streams = [{url: playlist.videosPrelim[xmlId].url}]
        else if (playlist.videosPrelim[xmlId].url.instr(1,".mp4") > 1)
          playlist.videosPrelim[xmlId].streamFormat = "mp4"
          playlist.videosPrelim[xmlId].streams = [{url: playlist.videosPrelim[xmlId].url}]
        end if

        subtitles = {
          languages: []
        }

        for each subtitle in videoDetails.subtitles.subtitle
          newSubtitle = {
            name: ValidStr(subtitle.language.getText())
            url: ValidStr(subtitle.url.getText())
          }
          if ValidStr(subtitle.default.getText()) = "1"
            subtitles.default = newSubtitle.name
            playlist.videosPrelim[xmlId].subtitleUrl = newSubtitle.url
          end if
          subtitles.languages.Push(newSubtitle)
        end for

        if subtitles.languages.count() <> 0
          playlist.videosPrelim[xmlId].subtitles = subtitles
        end if

        streams = []
        for each rendition in videoDetails.renditions.rendition
          if (rendition.video_container.getText() <> invalid)
            playlist.videosPrelim[xmlId].streamFormat = LCase(ValidStr(rendition.video_container.getText()))
          end if

          newStream = {
            url:  ValidStr(rendition.url.getText())
          }
          bitrate = StrToI(ValidStr(rendition.total_bitrate_kbs.getText()))
          if (bitrate > 0)
            newStream.bitrate = bitrate
          end if
          height = StrToI(ValidStr(rendition.video_height.getText()))
          ' m.isHD and
          if height > 480
            if height > 720
              playlist.videosPrelim[xmlId].fullHD = true
            end if
            playlist.videosPrelim[xmlId].isHD = true
            playlist.videosPrelim[xmlId].hdBranded = true
            newStream.quality = true
          end if
          streams.Push(newStream)
        end for
        if streams.count() <> 0
          playlist.videosPrelim[xmlId].streams = streams
        end if

        'Get Any Regwall Info as Defined in Hotpatch'
        if m.isRegWall = true
          idAsInteger = val(xmlId)
          if m.regWallContent[idAsInteger] <> invalid
            playlist.videosPrelim[xmlId].regWallType = m.regWallContent[idAsInteger]
          end if
        end if

        'add the video to the appropriate place in the episodes array
        playlist.episodes[playlist.videosPrelim[xmlId].position] = playlist.videosPrelim[xmlId]
      end if
    end for

    'delete the videosPrelim AssocArray from playlist AssocArray since it is no longer needed
    playlist.delete("videosPrelim")

    playlist.haveAllEpisodes = true
  end if
 end function

'update so getAllEpisodesForPlaylistFromServer works after api change
 m.app.episodeListScreen.show = function(playlist)
  ' showVarSimple(playlist, "playlist")
  if playlist.episodes[0].playlist.haveAllEpisodes <> true
    m.cp.getAllEpisodesForPlaylistFromServer(playlist, "episode")
  end if

  landscape = true

  port = CreateObject("roMessagePort")
  screen = CreateObject("roPosterScreen")
  'if appSettings.isLandscape = true

  thumbRatio = invalid

  if playlist.episodes.count() > 0
    if playlist.episodes[0].thumbnailRatio <> invalid
      thumbRatio = playlist.episodes[0].thumbnailRatio
    else if playlist.episodes[0].episodes <> invalid and playlist.episodes[0].episodes.count() > 0 and playlist.episodes[0].episodes[0].thumbnailRatio <> invalid
      thumbRatio = playlist.episodes[0].episodes[0].thumbnailRatio
    end if
  end if

  if thumbRatio = invalid or thumbRatio > 1
    screen.SetListStyle("flat-episodic-16x9")
  else
    screen.SetListStyle("flat-episodic-16x9")
  end if

  'truncate breadcrumb in top right corner to 24 characters. On partner apps it can cover the logo.
  breadCrumbName = Left(playlist.name, 24)
  screen.SetBreadcrumbEnabled(true)
  if m.utils.appName <> "tubitv"
    screen.SetBreadcrumbText(breadCrumbName, "")
  else
    screen.SetBreadcrumbText(playlist.name, "")
  end if

  screen.SetMessagePort(port)
  isTwoLevel = false

  child = m.cp.getChildItem(playlist, 0)
  if(child = invalid)
    return 0
  end if
  if child.playlist <> invalid
    m.set2Level(screen, 0, playlist)
    isTwoLevel = true
  else 'this should not happen if series are given seasons (all series should have at least 1 season)
    list = []
    for each item in playlist.episodes
      d = m.utils.getSavedContentData(item.id)
      if(d<>invalid and d.pos>30)
        item.BookmarkPosition = d.pos
      end if
      item.ShortDescriptionLine2 = item.description
      item.ShortDescriptionLine1 = item.title
      item.Categories = []
      list.Push(item)
      screen.SetContentList(list)
    end for
  end if
  screen.setFocusToFilterBanner(false)
  screen.Show()

  m.utils.portWaitStarting(port)

  listIndex = 0
  itemIndex = 0


  ' todo: eliminate some redundancy: make this happen between "setup" and "doEventHandling"
  ' if doing autoplay
  if m.autoplayItem1 <> invalid
    if m.autoplayItem2 <> invalid
      listIndex = m.autoplayItem1
      itemIndex =  m.autoplayItem2
      isTwoLevel = true
      m.set2Level(screen, listIndex, playlist)
      subList = m.cp.getChildItem(playlist, listIndex)
      episode = m.cp.getChildItem(subList.playlist, itemIndex)
      m.autoplayItem1 = invalid
      m.autoplayItem2 = invalid
      itemIndex = m.app.handleItemPicked(subList.playlist, itemIndex)
    else
      listIndex = invalid
      itemIndex =  m.autoplayItem1
      episode = m.cp.getChildItem(playlist, itemIndex)
      m.autoplayItem1 = invalid
      itemIndex = m.app.handleItemPicked(playlist, itemIndex)
    end if

    if listIndex <> invalid
      screen.setFocusedList(listIndex)
    end if
    screen.SetFocusedListItem(itemIndex)
    bypassFocusList = true
  else
    bypassFocusList = false
  end if

  while true
    msg = wait(0, port)
    m.utils.globalMessageHandler(msg)
    if type(msg) = "roPosterScreenEvent"
      if msg.isScreenClosed()
        return -1
      else if msg.isListFocused() 'user moved to a new season
        isTwoLevel = true
        listIndex = msg.getIndex()

        if playlist.episodes[listIndex].playlist.haveAllEpisodes <> true
          m.cp.getAllEpisodesForPlaylistFromServer(playlist.episodes[listIndex].playlist, "episode")
        end if
        eps = playlist.episodes[listIndex].playlist.episodes
        if eps <> invalid
          screen.SetContentList(eps)
          activeEpisode = m.getActiveEpisode(eps)
          if activeEpisode = -1
            activeEpisode = 0
          else if activeEpisode >= playlist.episodes.[listIndex].playlist.episodes.count()
            activeEpisode = 0
          end if
          screen.SetFocusedListItem(activeEpisode)
        end if
     '    if bypassFocusList = true
        '   bypassFocusList = false
      '     activeEpisode = m.getActiveEpisode(playlist.episodes)
      '     if activeEpisode <> -1
        '     screen.SetFocusedListItem(activeEpisode)
        '   end if
        ' else
      '     ' m.set2Level(screen, listIndex, playlist)
     '      activeEpisode = m.getActiveEpisode(playlist.episodes[listIndex].playlist.episodes)
     '      screen.SetFocusedListItem(activeEpisode)
        ' end if
      else if msg.isListItemSelected()
        itemIndex = msg.getIndex()
        if(isTwoLevel)
          subList = m.cp.getChildItem(playlist, listIndex)
          episode = m.cp.getChildItem(subList.playlist, itemIndex)
          itemIndex = m.app.handleItemPicked(subList.playlist, itemIndex)

          'after detail screen is closed (revealing episodeListScreen again), update progress bars
          eps = playlist.episodes[listIndex].playlist.episodes
          if eps <> invalid
            screen.SetContentList(eps)
            activeEpisode = m.getActiveEpisode(eps)
            if activeEpisode = -1
              activeEpisode = 0
            else if activeEpisode >= playlist.episodes.[listIndex].playlist.episodes.count()
              activeEpisode = 0
            end if
            screen.SetContentList(eps)
          end if

        else
          episode = m.cp.getChildItem(playlist, itemIndex)
          itemIndex = m.app.handleItemPicked(playlist, itemIndex)
        end if
        screen.SetFocusedListItem(itemIndex)
      end if
    end if
  end while
end function


'update getAllEpisodesForPlaylistFromServer so works after api change
m.app.episodeListScreen.set2Level = function(screen, listIndex, playlist)
  activeEpisode = 0

  listNames = []
  for each item in playlist.episodes
    listNames.push(item.title)
  end for

  screen.SetListNames(listNames)

  'find the appropriate season to start a user on
  while true
    if playlist.episodes[listIndex] <> invalid
      if playlist.episodes[listIndex].playlist.haveAllEpisodes <> true
        m.cp.getAllEpisodesForPlaylistFromServer(playlist.episodes[listIndex].playlist, "episode")
      end if
      eps = playlist.episodes[listIndex].playlist.episodes
      screen.SetContentList(eps)
      activeEpisode = m.getActiveEpisode(eps)

      if activeEpisode = -1
        exit while
      else if activeEpisode >= playlist.episodes.[listIndex].playlist.episodes.count()
        listIndex = listIndex + 1
      else
        screen.SetFocusedListItem(activeEpisode)
        screen.SetContentList(eps)
        exit while
      end if
    else
      listIndex = 0
      exit while
    end if
  end while

  'set the appropriate season
  'this will not have any effect if listIndex is equal to the currently focused list
  'this will trigger a roPosterEvent in EpisodeListScreen_show,
  'which will in turn find and set the appropriate episode to focus on
  screen.setFocusedList(listIndex)

end function




' 'allow 5.0_video sdk to play skippable ads
' m.app.player.ads.getAdUnitFromXml = function(adXml)
'   streams = []

'   if adXml.media.renditions <> invalid
'     renditions = adXml.media.renditions.rendition
'     for each rendition in renditions
'       if StrToI(ValidStr(rendition.video_height)) > 720
'         definition = "hd"
'       else
'         definition = "sd"
'       end if

'       streams.push({
'           url: rendition.url.getText()
'           bitrate: StrToI(rendition.video_bitrate_kbs.getText())
'           format: adXml.media.streamformat.getText()
'           quality: definition
'       })
'     end for
'   end if

'   viewthru = []
'   viewthru[0]  = m.utils.getTrackingTags(adXml.media.trackingevents.tracking_0)
'   viewthru[25] = m.utils.getTrackingTags(adXml.media.trackingevents.tracking_25)
'   viewthru[50] = m.utils.getTrackingTags(adXml.media.trackingevents.tracking_50)
'   viewthru[75] = m.utils.getTrackingTags(adXml.media.trackingevents.tracking_75)
'   viewthru[100]= m.utils.getTrackingTags(adXml.media.trackingevents.tracking_100)

'   adUnit = {
'     streams : streams
'     viewthru: viewthru
'     adType : "video"

'     id : adXml.ad_id.GetText()
'     contentType : adXml.contentType.GetText()
'     shortDescriptionLine1 : adXml.title.GetText()
'     shortDescriptionLine2 : ""
'     description : adXml.synopsis.GetText()
'     rating : adXml.rating.GetText()
'     genres : adXml.genres.GetText()
'     starRating : adXml.starrating.GetText()
'     categories : ""
'     title : adXml.title.GetText()
'     runtime : adXml.runtime.GetText()

'     ' these are actually part of <adXml sdImg= "" hdImg=""/>
'     sDPosterUrl : adXml@sdImg
'     hDPosterUrl : adXml@hdImg

'     impTrack : m.utils.getTrackingTags(adXml.imptracking)

'     clickTrack : m.utils.getTrackingTags(adXml.clicktracking)

'     duration : adXml.media.duration.GetText()
'     pluginID : adXml.media.pluginID.GetText()

'     streamQualities : adXml.media.streamQuality.GetText()
'     streamBitrates : [0]
'     streamFormat : adXml.media.streamFormat.GetText()
'     srt : ""
'     minBandwidth : 20
'     currentOption : 0
'     totalOptions : 0
'     adIsSkippable: false
'     adIsSelectable: false
'   }

'   'Determine if there are any type of companion ads running
'   if adXml.companion_ad.GetAttributes().type <> invalid
'     print "THERE IS A COMPANION AD"
'     companionAttributes = adXml.companion_ad.GetAttributes()

'     'if the companion ad is Brightline, add Brightline information for companion ads to adUnit object.
'     'Only run Brightline companion ads if there is a companion ad ID
'     if companionAttributes.type = "brightline"
'       if (adXml.companion_ad.companion_id.GetText() <> "")
'         adUnit.companionOverlay = adriseAds_getCompanionOverlay(adXml)
'         adUnit.positionPoints = {
'           lastSavedPos: 0
'           positionPercentage: 0
'           statusInterval: 0
'         }
'       end if
    
'     'If ad is skippable, change the adIsSkippable property of the adUnit to true
'     else if companionAttributes.type = "skippable"
'       adUnit.adIsSkippable = true
    
'     'If the add is selectable change the adIsSelectable property of the adUnit to true
'     else if companionAttributes.type = "selectable"
'       adUnit.adIsSelectable = true
'     end if
'   end if
  
'   if (adXml.interactivebar <> invalid)
'     adUnit.adBar = []
'     for each option in adXml.interactivebar.option
'       adUnit.totalOptions = adUnit.totalOptions + 1
'       urls = []
'       for each pixel in option.url
'         urls.push(pixel.getText())
'       end for
'       adUnit.adBar.push({
'           img : option.img.GetText()
'           urls : urls
'         })
'     end for

'     adUnit.adbarThanksImage = adXml.interactivebar.thanks.img.GetText()
'   end if
'   return adUnit
' end function
