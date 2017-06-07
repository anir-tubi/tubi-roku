print "Hot Patch 10"

settings = m.app.utils.getSettings()

themesFolder = "http://cdn.adrise.com/hotpatches/roku/themes/"

theme = {
  GridScreenLogoHD: themesFolder + "LG-comedy-gridscreenHD.png"
  GridScreenLogoSD: themesFolder + "LG-comedy-gridscreenSD.png"
  ' GridScreenDescriptionImageHD: themesFolder + "bubble-hd.png"
  ' GridScreenDescriptionImageSD: themesFolder + "red_call_out_HD.png"
  TallBannerHD: themesFolder + "LG-comedy-detailsHD.png"
  TallBannerSD: themesFolder + "LG-comedy-detailsSD.png"
  OverhangLogoHD: themesFolder + "LG-comedy-detailsHD.png"
  OverhangLogoSD: themesFolder + "LG-comedy-detailsSD.png"
  GridScreenBackgroundColor: "#000000"
  BackgroundColor: "#000000"
}


m.app.player.ads.isRokuAdFrameworkOn = false
m.app.player.useCustomPlayer = true

if m.app.settings.shortAppName = "tubitv"
  
  'use to change the theme (the theme details are above), ie. headers and background colors
  m.app.utils.appManager.setTheme(theme)

  m.app.linearTv.showLinearTv = true
  m.app.cp.showLinearTv = true

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


  'Prevent ads from freezing when there is no content at the ad url
  m.app.player.ads.maxAdRetries = 2

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
          status = m.currentAdUnit.status
          exit while
        end if 
      end while

      return status
    end if

    print "ad unit total options "; adUnit.totalOptions


    canvas = CreateObject("roImageCanvas")
    adPort = CreateObject("roMessagePort")
    canvas.SetMessagePort(adPort)

    if type(adUnit) <> "roAssociativeArray"
      canvas.close()
      return "COMPLETED"
    end if

    player = CreateObject("roVideoPlayer")
    player.SetMessagePort(adPort)
    player.SetDestinationRect(canvas.GetCanvasRect())
    player.SetPositionNotificationPeriod(1)

    ' set up some messaging to display while the pre-roll buffers
    m.utils.showAdLoadingLayer(canvas, playerSettings.displaySize, adDetails.secondsLeft, adDetails.adCounter, adDetails.totalAds, playerSettings.background, playerSettings.fontColor, playerSettings.loadingurl, playerSettings.appid)
    canvas.Show()

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
        print "async response 4"
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
          'msg.isFullResult event fires when a msgisRequestFailed event fires and also when the video has finished playing
          print "full result event was received "; m.videoAdErrorCount; m.maxAdRetries
          
          'if we actually played through the whole video
          if (positionPercentage >= 75)
            m.utils.trackEvent({
              trackType: "viewthru"
              adUnit: adUnit
              adPercentage: 100
              port: m.playerPort
            })
            canvas.close()

            'need to reset in case there was a failure, but then the ad worked on retry
            m.videoAdErrorCount = 0
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
          if (m.videoAdErrorCount < m.maxAdRetries)
            m.videoAdErrorCount = m.videoAdErrorCount + 1
            player = CreateObject("roVideoPlayer")
            player.SetMessagePort(canvas.getMessagePort())
            player.SetDestinationRect(canvas.GetCanvasRect())
            player.SetPositionNotificationPeriod(1)
            player.AddContent(adUnit)
            player.Play()

          else
            'reset the ad error count since we are about to exit out of this ad
            m.videoAdErrorCount = 0
                    
            m.utils.trackEvent({
              trackType: "adFailure"
              value: adUnit.streams[0].url 'the ad url
              ctx: msg.GetMessage()
              port: m.playerPort
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
 


  '------------------------------------------------------------------
  'Update the registration process
  m.app.registerScreen.show = function(regWall = "")

    'necessary when calling the show() method from detail screen
    '(ie. for registration walls)
    if m.res = invalid
      m = GetGlobalAA().app.registerScreen
    end if

    m.isInitialScreen = true
    m.row = 5
    m.col = 1
    m.isComplete = false
    g = GetGlobalAA()

    m.canvas = CreateObject("roImageCanvas")
    port = CreateObject("roMessagePort")

    m.canvas.SetMessagePort(port)


    loadingImage = {
      Url: "pkg:/" + m.res + "/bg_initial.jpg"
      TargetRect: m.getRect("bg", 0)
      compositionMode: "Source"
    }

    'change the background for any registration walls
    if regWall = "premiere"
      loadingImage.Url = "pkg:/" + m.res + "/bg_premiere_wall.jpg"
    end if

    layers = [loadingImage]
    m.canvas.SetLayer(0, layers)

    ' layers = []
    m.paint()

    m.canvas.Show()

    while(true)
       msg = wait(30,port)

       if (m.pressedItem <> invalid)
          m.pressedItem.count = m.pressedItem.count -1
          if (m.pressedItem.count < 1)
            m.pressedItem = invalid
            m.paint()
          end if
       end if

       'r = g.app.utils.getAsyncResponse (msg, id)
       'if r <> invalid
       '  print "got id " ; id
       '  print r.data
       'end if
       if m.isComplete = true
        m.isComplete = false
        m.canvas = invalid
        m.pressedItem = invalid
        return true
       end if
       if type(msg) = "roImageCanvasEvent"
          if msg.isRemoteKeyPressed()
            index = msg.GetIndex()

            'show initial "skip/ok" screen if appropriate
            if(m.isInitialScreen = true)


              if (index = 0) ' back
                m.canvas.close()
                m.canvas = invalid
                return true
              else if (index = 6) ' ok
                if(m.col = 1) 'selected OK button
                  loadingImage = {
                    Url: "pkg:/" + m.res + "/bg_entry.jpg"
                    TargetRect: m.getRect("bg", 0)
                    compositionMode: "Source"
                  }
                  layers = [loadingImage]
                  m.canvas.SetLayer(0, layers)
                  m.isInitialScreen = false
                  m.row = 1
                  m.col = 1
                  m.pressedItem = invalid
                  m.paint()
                else 'selected SKIP button
                  m.canvas.close()
                  m.canvas = invalid
                  return true
                end if
              else if (index = 5 and m.col=0) ' right
                m.col = 1
              else if (index = 4 and m.col=1) ' left
                m.col = 0
              end if
              m.paint()

            else
              if (index = 0) ' back
                m.canvas.close()
                m.canvas = invalid
                return true
              else if (index = 6) ' ok
                m.pressedItem = {
                  row: m.row
                  col: m.col
                  count: 8
                }
                m.paint()
                if(m.row < 3)
                  m.addDigit(((m.row*3)+(m.col+1)))
                else if (m.row = 3 and m.col = 1)
                  m.addDigit(0)
                else if (m.row = 3 and m.col = 0)
                  m.deleteCharacter()
                else if  (m.row = 4 and m.col = 0)
                  m.cancel()
                else if  (m.row = 4 and m.col = 1)
                  m.submit()
                else if (m.row = 4 and m.col = 2) 'register with no phone
                  sleep(300) 'pause just for a tiny bit to show the button turn color
                  isRegistered = m.webRegister()
                  m.isComplete = true
                  m.canvas.close()
                end if
              else
                if (index = 5) ' right
                  m.col = m.col + 1
                else if (index = 2) ' up
                  m.row = m.row - 1
                else if (index = 4) ' left
                  m.col = m.col - 1
                else if (index = 3) ' down
                  m.row = m.row + 1
                end if

                'control for cases where user tries to move left or right out of the grid
                if m.col < 0
                  if m.row <> 4
                    m.col = 0
                  else
                    m.col = 2
                  end if
                else if m.col > 2
                  if m.row <> 4
                    m.col = 2
                  else
                    m.col = 0
                  end if
                end if

                'control for cases where user tries to move up or down out of the grid'
                if m.row > 4
                  m.row = 4
                else if m.row < 0
                  m.row = 0
                end if
                
                if((m.row = 3) and m.col = 2)
                  m.col = 1
                end if

              end if
              m.paint()
            end if
          end if
       end if
     end while
     m.canvas = invalid
    return true
  end function

  'url encode spaces and other characters that might end up in user event tracking urls (mainly category names)
  m.app.utils.trackEvent = function(evt)
    time = CreateObject("roDateTime")

    startMS = 1000 * (60 * (60 * time.GetHours() + time.GetMinutes()) + time.GetSeconds()) + time.getMilliseconds()

    ' ------------AdUnit Events------------------
    if evt.trackType = "click" then
      For Each trackUrl in evt.adUnit.clickTrack
        trackUrl = strReplace(trackUrl, "[", "")
        trackUrl = strReplace(trackUrl, "]", "")
        asyncId = m.sendAsyncRequest(trackUrl, evt.port, "trackClick")
      end for
    else if evt.trackType = "imp" then
      For Each trackUrl in evt.adUnit.impTrack
        trackUrl = strReplace(trackUrl, "[", "")
        trackUrl = strReplace(trackUrl, "]", "")
        asyncId = m.sendAsyncRequest(trackUrl, evt.port, "trackImp")
      end for

    else if evt.trackType = "viewthru" then
      For Each trackUrl in evt.adUnit.viewthru[evt.adPercentage]
        trackUrl = strReplace(trackUrl, "[", "")
        trackUrl = strReplace(trackUrl, "]", "")
        evt.adUnit.viewthru[evt.adPercentage] = "" ' making sure it doesn't get fired again
        asyncId = m.sendAsyncRequest(trackUrl, evt.port, "trackViewThru")
      end for

    'event tracking for non ad events
    else if evt.trackType <> invalid and m.deviceInfo.firmwareVersion > 3.01 then
      ' trackData = m.getTrackData(evt.trackType, evt.contentId, evt.progressPercent, evt.playerPosition, evt.deepLinkSource, evt.errorMessage)
      trackData = m.getTrackData(evt.trackType, evt.value, evt.ctx, evt.extraCtx)
      m.trackingDataToSend.push(trackData)

      if (evt.trackType <> "playProgress" and evt.trackType <> "linearPlayProgress") or m.trackingDataToSend.count() >= 5
        trackingDataToSendJSON = FormatJson(m.trackingDataToSend)

        escapeUrlObj = CreateObject("roUrlTransfer")
        trackDataToSendJSONEncoded = escapeUrlObj.Escape(trackingDataToSendJSON)

        ' trackUrl = "http://tb.tu-int.com/extEvent?events=" + trackDataToSendJSONEncoded   'staging tracking server
        trackUrl = "http://cms.adrise.com/extEvent?events=" + trackDataToSendJSONEncoded    'production tracking server

        asyncId = m.sendAsyncRequest(trackUrl, evt.port, "track" + evt.trackType)
        m.trackingDataToSend = []
      end if

    end if

  end function
end if
