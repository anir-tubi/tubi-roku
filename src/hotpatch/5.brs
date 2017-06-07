print "hot patch 5"


deviceInfo = CreateObject( "roDeviceInfo")

version = deviceInfo.GetVersion()

major = Mid(version, 3, 1)

if major = "3"
  m.app.cp.setContentType("mp4")
  m.app.player.contentType = "mp4"
else
  m.app.cp.setContentType("hls")
  m.app.player.contentType = "hls"
end if

settings = m.app.utils.getSettings()

if m.app.settings.shortAppName = "premiere" or m.app.settings.shortAppName = "g-connect" or m.app.settings.shortAppName = "shout-factory"
  m.app.settings.newThumbnailStrategy  = true
end if

'create a message screen that will appear when the app loads, before the grid screen shows
'used for apps that are shutting down or no longer adding content
'headerText is string
'paragraphs is an array of paragraph text strings
'buttons is an array of button objects in the form
'{
' buttonText: "string of button text",
' buttonType: "string of button type"
'}
'acceptable button types are "continue", "deepLink" - deepLink will deeplink to TubiTv
m.app.showPreMessage = function(headerText, paragraphs, buttons)
  port = CreateObject("roMessagePort")
  preMessageScreen = CreateObject("roParagraphScreen")
  preMessageScreen.SetMessagePort(port)

  'add header
  ' preMessageScreen.addHeaderText(headerText)
  preMessageScreen.addHeaderText("Horoscopes on The Astrologer will no longer")
  preMessageScreen.addHeaderText("be updated")
  
  'add paragraphs
  for each paragraph in paragraphs
    preMessageScreen.addParagraph(paragraph)
  end for

  'add buttons'
  buttonId = 1
  for each button in buttons
    preMessageScreen.addButton(buttonId, button.buttonText)
    buttonId = buttonId + 1
  end for

  'make the screen usable or 'live'
  preMessageScreen.show()

  while true
    msg = Wait(0, port)
    if type(msg) = "roParagraphScreenEvent"
      if msg.isButtonPressed()
        index = msg.GetIndex() - 1 'subtract one to match index in buttons array that was passed in
        buttonType = buttons[index].buttonType
        
        if buttonType = "deepLink"
          contentID = "41468" 'Tubi Tv content ID
          
          'get IP address
          di = CreateObject("roDeviceInfo")
          x = di.GetIPAddrs()
          for each i in x
            ipAddr =  x[i]
          end for

          'get all apps on device in the form of xml object
          xfer = CreateObject("roURLTransfer")
          getAppsUrl = "http://" + ipAddr + ":8060/query/apps"
          xfer.SetURL(getAppsUrl)
          res = xfer.GetToString() 'should return xml

          'set the deep link url
          if ipAddr <> invalid
            'default if tubitv does not exist on device
            externalLink = "http://" + ipAddr + ":8060/launch/11?contentID=" + contentID

            'if tubitv already on device
            xml = CreateObject("roXMLElement")
            if xml.Parse(res)
              for each child in xml.GetBody()
                  if child.GetName() = "app" and child.GetAttributes().id = contentID
                    externalLink = "http://" + ipAddr + ":8060/launch/" + contentID
                    exit for
                  endif
              end for
            end if 
          end if

          'make call to deep link
          xfer.SetURL(externalLink)
          result = xfer.PostFromString("")

          'close the screen and exit
          preMessageScreen.close()
          return true
        else 'buttonType = "continue"
          'close the screen and exit
          preMessageScreen.close()
          return true 
        end if
        exit while
      end if
    end if
  end while
  
  return false
end function

'app specific updates
if m.app.settings.shortAppName = "the-astrologer"
  astrologerHeaderText = "Horoscopes on The Astrologer will no longer be updated."
  astrologerParagraphs = ["Download Tubi TV to watch FREE TV and movies"]
  astologerButtons = [
    {
      buttonText: "Continue to The Astrologer"
      buttonType: "continue"
    },
    {
      buttonText: "Click to download Tubi TV",
      buttonType: "deepLink"
    },
  ]
  m.app.showPreMessage(astrologerHeaderText, astrologerParagraphs, astologerButtons)
end if

if m.app.settings.shortAppName = "hasbro"
  m.app.settings.allowVezoSubscription = true
end if

if m.app.settings.shortAppName = "tubitv"
  m.app.cp.urls = {
      getPlaylists: "http://cms.adrise.com/v2/app.php?id=" + settings.shortAppName + "&platform=roku&format=xml&content-type=" + m.app.cp.contentType + "&video-fields=title&sdk=5.0"
      getVideo: "http://cms.adrise.com/v2/video.php?app-id=" + settings.shortAppName + "&platform=roku&content-type=" + m.app.cp.contentType + "&format=xml&id="
      getVideos: "http://cms.adrise.com/v2/videos.php?app-id=" + settings.shortAppName + "&platform=roku&content-type=" + m.app.cp.contentType + "&format=xml&id="
    }
end if

m.app.player.ads.positionPoints = invalid

'fix brightline percentage pixel reporting
m.app.player.ads.getAdUnitFromXml = function(adXml)
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
  }

  'Adding Brightline information for companion ads to adUnit object.
  'Only run Brightline companion ads if there is a companion ad ID
  if (not adXml.companion_ad.companion_id.GetText() = "")
    adUnit.companionOverlay = adriseAds_getCompanionOverlay(adXml)
    adUnit.positionPoints = {
      lastSavedPos: 0
      positionPercentage: 0
      statusInterval: 0
    }
  end if

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

'Brightline Start Position Ad "Pixel"
m.app.player.ads.brightlineOnPosition = function(roVideoPlayerEvent)
  globalUtils = GetGlobalAA().app.utils
  adUnit = GetGlobalAA().app.player.ads.currentAdUnit
  statusInterval = adUnit.Duration.toInt() / 4
  lastSavedPos = adUnit.positionPoints.lastSavedPos
  positionPercentage = adUnit.positionPoints.positionPercentage
  nowPos = roVideoPlayerEvent.GetIndex()

  if nowPos = 0
    globalUtils.trackEvent({
      adUnit: adUnit
      trackType: "viewthru"
      adPercentage: positionPercentage
    })
  else if abs(nowPos - lastSavedPos) > statusInterval and positionPercentage < 75
    adUnit.positionPoints.lastSavedPos = nowpos
    adUnit.positionPoints.positionPercentage = positionPercentage + 25
    positionPercentage = positionPercentage + 25
    if (positionPercentage < 100)
      globalUtils.trackEvent({
          adUnit: adUnit
          trackType: "viewthru"
          adPercentage: positionPercentage
        })
    end if
  end if    
end function

m.app.player.ads.showVideoAd = function(canvas, adUnit, adDetails, playerSettings)
  m.currentAdUnit = adUnit

  if m.adIsLexusInteractive(adUnit)
    la = m.lexusAd(adUnit)
    la.setUpCanvas(true)
    la.paintCanvas()
    return la.doEventLoop()
  end if

  status = "COMPLETED"

  'check if ad is Brightline companion overlay type by checking if companionOverlay property exists
  'since Brighltine throws errors on 3.1 firmware, only serve Brightline ads on greater than 3.1 firmware
  di = CreateObject("roDeviceInfo")
  rokuFirmware = di.GetVersion()
  major = Int(Val(Mid(rokuFirmware, 3, 4)))
  
  if (m.adIsBrightlineCompanionAd(adUnit) and major <> 3)
    ip = BL_InteractivePreroll()

    ip.Append({
      onVideoPlayerStreamStarted: adriseAds_brightlineOnStartWrapper
      onVideoPlayerFullResult: adriseAds_brightlineOnCompleteWrapper
      onVideoPlayerPlaybackPosition: GetGlobalAA().app.player.ads.brightlineOnPosition
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
  

  print "show video ad"
  'ShowVarSimple(adUnit, "ad")


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

  m.utils.showAdLoadingLayer(canvas, playerSettings.displaySize, adDetails.secondsLeft, adDetails.adCounter, adDetails.totalAds, playerSettings.background, playerSettings.fontColor, playerSettings.loadingurl)
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

  if m.adIsSkippable(adUnit)
    m.skippable = m.createSkippableAd(canvas)
  else
    m.skippable = invalid
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

          if m.skippable <> invalid and m.skippable.time >= m.skippable.skipTime
            status = "COMPLETED"
            print "skipped ad"
            exit while
          end if

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
        else if (i = 4 or i = 5) ' left or right
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
          print "loading progress " ; (msg.GetIndex() / 10)

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

          if m.skippable <> invalid
            m.skippable.setup()
          end if

          m.utils.trackEvent({
            trackType: "viewthru"
            adUnit: adUnit
            adPercentage: positionPercentage
            })
        else if nowpos > 0
          if m.skippable <> invalid
            m.skippable.update(nowpos)
          end if

          if adUnit.totalOptions > 0 and adUnit.adBar[currOption].img <> ""
            filename = adUnit.adBar[currOption].img + "?" + RND(10000000).ToStr()
            canvas.SetLayer(10, {Url: filename, TargetRect: {x: 0 , y: 30, w: playerSettings.displaySize.w, h: 80}, CompositionMode: "Source_over" })
            canvas.Show()
          end if
          if abs(nowpos - lastSavedPos) > statusInterval and positionPercentage < 75
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
        print "Video request failure: "; msg.GetIndex(); " " msg.GetData(); " " msg.GetMessage(); " " msg.GetType()
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
          m.utils.reportError(adUnit, "ad video failed")
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