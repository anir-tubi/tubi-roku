g = getGlobalAA()

print "hot patch 2: Subscription apps"

san = g.app.settings.shortAppName


g.app.player.temp = g.app.player.playVideo

g.app.player.playVideo  = function (episode)
    episode.SwitchingStrategy="full-adaptation"
    return m.temp(episode)
end function

deviceInfo = CreateObject("roDeviceInfo")
version = deviceInfo.GetVersion()
major = Mid(version, 3, 1)
if major = "3"
  g.app.cp.setContentType("mp4")
  g.app.player.contentType = "mp4"
end if

g.app.cp.urls = {
		  getPlaylists: g.app.cp.server + "/v2/app.php?id=" + g.app.cp.shortAppName + "&platform=roku&format=xml&content-type=" + g.app.cp.contentType + "&video-fields=title&sdk=5.0"
		  getVideo: g.app.cp.server + "/v2/video.php?app-id=" + g.app.cp.shortAppName + "&platform=roku&content-type=" + g.app.cp.contentType + "&format=xml&id="
		  getVideos: g.app.cp.server + "/v2/videos.php?app-id=" + g.app.cp.shortAppName + "&platform=roku&content-type=" + g.app.cp.contentType + "&format=xml&id="
		}


g.app.utils.cancelAsyncRequest = function(id) as Object
  which = m.asynchRequests[str(id)]
  if which <> invalid
    which.AsyncCancel()
    print "cancelled async " ; id
    m.asynchRequests.delete(str(id))
  else
    print "failed to cancelled async " ; id
  end if
end function

g.app.serverLinker = function(utils, player, settings)
    o =  {
      utils: utils
      settings: settings
      player: player
    }

    ' ping the account and get a status (new, pending, or subscribed)
    ' show the connect dialog if status is new (which will prompt going to site and entering pin code)
    ' return value is ignored
    o.connectToAccount = function (showDialogIfNotSubscribed)
        print "connect to account"

        sec = CreateObject("roRegistrySection", "Default")
        list = sec.GetKeyList()
        numEntries = list.count()
        if(numEntries = 0)
          timeNow = CreateObject("roDateTime")
          timeNow.Mark()
          regWrite("installtime", str(int(timeNow.asSeconds()/(60*60))))
        end if

        if m.settings.vezoSubscription = true or m.settings.allowVezoSubscription = true
          if(numEntries = 0)
            forceLink = "&forceLink=true"
          else
            forceLink = ""
          end if

          resp = m.utils.getTextFile(m.settings.vezoServer + "/getVezoAppStatus?deviceId=roku_" + m.utils.deviceId + "&appName=" + m.settings.shortAppName + forceLink, "getVezoCode")
          print "get code"
          print resp
          out = m.getCode(resp)
          print out
          while out.mode <> "subscribed" and out.mode <> "cancelled"
            if out.mode = "new"
              print "connect dialog"
              if (showDialogIfNotSubscribed)
                out = m.showConnectDialog(out.code)
              else
                return true
              end if

            else if out.mode = "pending"
              print "subscribe prompt"

              if (showDialogIfNotSubscribed)
                if m.showSubscribePrompt() = true
                  return true
                end if
              else
                return true
              end if

              resp = m.utils.getTextFile(m.settings.vezoServer + "/getVezoAppStatus?deviceId=roku_" + m.utils.deviceId + "&appName=" + m.settings.shortAppName, "getVezoCode")
              print "get code again"
              print resp
              out = m.getCode(resp)
            else if out.mode = "cancelled"
              return true
            end if
          end while
        end if

        if(out.mode = "subscribed")
          m.player.subscription = true
          m.settings.allowRentals = false
          print "subscribed!"
        end if
        return true
    end function

    ' given a text response, determine if it is pending, subscribed, or new.  If new, get the pin code
    ' returns an object with a mode, possibly a code, and possibly a time that it started pending
    o.getCode = function (response)
        r1 = CreateObject("roRegex", "\n", "")
        r2 = CreateObject("roRegex", ",", "")
        a = r1.Split(response)
        num = a.count()
        print "num strings " ; num
        if(num > 0)
          o = r2.Split(a[num-1])
          len = o.count()

          out = { mode: o[0] }

          print
          print out

          if(out.mode = "new")
            out.code = o[1]
            print " is new "
            return out
          end if

          if(out.mode = "pending")
            print " is pending "
            out.time = o[1]
            return out
          end if

          return out
        end if
        return { mode: "pending", time: "1440" }
      end function

    ' show a dialog that prompts for you to subscribe.
    ' if you press ok, it will check for a subscription, and exit if so
    ' returning true will cause it to exit to the grid
    o.showSubscribePrompt = Function ()
        canvas = CreateObject("roImageCanvas")
        port = CreateObject("roMessagePort")
        canvas.SetMessagePort(port)
        deviceInfo = CreateObject("roDeviceInfo")
        displaySize = deviceInfo.GetDisplaySize()
        background = {
          Color: m.settings.adrise_bg
        }
        loadingImage = {
          Url: m.settings.adrise_loadingurl
          TargetRect: {
            x: Int( displaySize.w / 2 ) - Int( 336 / 2 ),
            y: Int( displaySize.h / 6 ),
            w: 336,
            h: 210
          }
        }
        loadingText = {
          TextAttrs: {
              Font: "Medium"
              VAlign: "Bottom"
              Color: m.settings.adrise_fontcolor
          },
          TargetRect: {
              x: Int(displaySize.w * .15)
              y: Int(displaySize.h * .71)
              w: Int(displaySize.w * .7)
              h: 30
          }
        }
        if m.settings.allowVezoSubscription = true
          loadingText.Text = "This device is linked to your account, but you still need to subscribe to this channel to watch the videos ad free.  Please subscribe by going to Vezo.tv on your computer, tablet or smartphone, then press ok.  To skip the linking process and watch the channel with ads, press cancel."
        else
          loadingText.Text ="This device is linked to your account, but you still need to subscribe to this channel to watch the videos.  Please subscribe by going to Vezo.tv on your computer, tablet or smartphone, then press ok on your Roku remote."
        end if

        canvas.SetLayer(2, [background, loadingImage, loadingText])
        canvas.Show()
        canvas.AddButton(1, "ok")
        if m.settings.allowVezoSubscription = true
          canvas.AddButton(2, "cancel")
        end if
        while(true)
           msg = wait(0,port)
           if type(msg) = "roImageCanvasEvent" then
            if msg.isButtonPressed()
              button = msg.GetIndex()
              if (button = 1)
                print "ok button pressed!"
                resp = m.utils.getTextFile(m.settings.vezoServer + "/getVezoAppStatus?deviceId=roku_" + m.utils.deviceId + "&appName=" + m.settings.shortAppName, "getVezoCode 2")
                out = m.getCode(resp)
                print "got code"
                print out
                if out.mode = "subscribed"
                  m.player.subscription = true
                  m.settings.allowRentals = false
                  print "subscribed"
                  return true
                else
                  m.utils.showErrorMessage (m.settings.adrise_bg, m.settings.adrise_fontcolor, m.settings.adrise_loadingurl, "You are not yet subscribed.")
                  print "show not yet subscribed dialog"
                end if
              end if

              if (button = 2)
                '	print "fake subscribed!"
                ' m.player.subscription = true
                return true
              end if
            end if
           end if
         end while
         return false
      end function

    o.showConnectDialog = Function (code)
      port = CreateObject("roMessagePort")
      screen = CreateObject("roCodeRegistrationScreen")
      screen.SetMessagePort(port)
      screen.AddFocalText("Want to skip ads?", "spacing-dense")
      screen.AddFocalText(" ", "spacing-dense")
      screen.AddFocalText("Sign in to http://vezo.tv", "spacing-dense")
      screen.AddFocalText("Enter the code below to link your Roku", "spacing-dense")
      screen.AddFocalText("Subscribe to this channel for $4.99/mo.", "spacing-dense")
      screen.AddFocalText(" ", "spacing-dense")
      screen.AddFocalText("This app will auto-refresh after you link this device", "spacing-dense")
      screen.SetRegistrationCode("retrieving code...")
      screen.AddButton(0, "Get a new code")

      if m.settings.allowVezoSubscription = true
        screen.AddButton(1, "Skip this step and watch with ads")
      end if

      screen.Show()

      screen.SetRegistrationCode(code)

      url = m.settings.vezoServer + "/linkToVezo?deviceId=roku_" + m.utils.deviceId  + "&appName=" + m.settings.shortAppName
      print "Link to Vezo (polling)"
      print url
      print "start poll"

      asyncId = m.utils.sendAsyncRequest(url, port, "linkPoll")
      print asyncId
      while true
        msg = wait(1000, port)
        print "get async resp " ; asyncId
        respObj = m.utils.getAsyncResponse(msg, 0)

        if(respObj <> invalid)
          print "polling response: "
          print respObj.data
          out = m.getCode(respObj.data)
          if out.mode = "pending"
            return  out
          else if out.mode = "subscribed"
            m.player.subscription = true
            m.settings.allowRentals = false
            print "subscribed!"
            return out
          end if
          print "restart poll"
          asyncId = m.utils.sendAsyncRequest(url, port, "linkPoll")
          print asyncId
        end if

        if type(msg) = "roCodeRegistrationScreenEvent"
          print "roCodeRegistrationScreenEvent"
          if msg.isScreenClosed()
              print "cancelled"
              m.utils.cancelAsyncRequest(asyncId)
              return {mode: "cancelled"}
          else if msg.isButtonPressed()
            button = msg.GetIndex()
            if (button = 1)
              print "cancelled"
              m.utils.cancelAsyncRequest(asyncId)
              return {mode: "cancelled"}
            else if (button = 0)
              print "get code again"
              resp = m.utils.getTextFile(m.settings.vezoServer + "/getVezoAppStatus?deviceId=roku_" + m.utils.deviceId + "&appName=" + m.settings.shortAppName, "getVezoCode")
              print "get app status response (2): "
              print resp

              out = m.getCode(resp)
              print "done getting code" ; out
              if out.mode = "new"
                screen.SetRegistrationCode(out.code)
              else if out.mode = "pending"
                m.utils.cancelAsyncRequest(asyncId)
                return out
              else if out.mode = "subscribed"
                m.player.subscription = true
                m.settings.allowRentals = false
                print "subscribed!"
                m.utils.cancelAsyncRequest(asyncId)
               return out
              end if
            end if
          end if
        end if
      end while
      print "returning"
      return  {mode: "new"}
     End Function

    return o

end function

if san = "tubitv"
g.app.gridScreen.app = m.app

'-------------------------------
g.app.gridScreen.show = function (selItem, cp, gridStyle)
  rokuGridScreen = CreateObject("roGridScreen")
	msgPort = CreateObject("roMessagePort")
	rokuGridScreen.SetMessagePort(msgPort)
  rokuGridScreen.SetDisplayMode("scale-to-fill")
	rokuGridScreen.SetGridStyle(gridStyle)
	m.initGrid(rokuGridScreen, cp)
	m.utils.portWaitStarting(msgPort)
	isShown = false

  offset = m.showToolsRow(rokuGridScreen)
  offset = 1
  selItem.listIndex = selItem.listIndex+offset

	rowNum = 0
  while true
    playlist = cp.getPlaylist(rowNum)

    if playlist = invalid
      if cp.errorMessage <> invalid
         rokuGridScreen.Close()
         return false
      end if
      if isShown = false
        if selItem.listIndex > rowNum - offset
          selItem.listIndex = rowNum - offset
          rokuGridScreen.SetFocusedListItem(selItem.listIndex, selItem.itemIndex)
        end if
        rokuGridScreen.Show()
        if gridStyle = "two-row-flat-landscape-custom"
          rokuGridScreen.SetDescriptionVisible(false)
        end if
        isShown = true
      end if
      exit while
    else
      colNum = 0
      episodes = []

      while true
        episode = cp.getEpisodeInPlaylist(playlist, colNum)
        if episode = invalid
          exit while
        else
          episodes.push(episode)
        end if
        colNum = colNum + 1
      end while

      if episodes.count() > 0
        rokuGridScreen.SetContentList(rowNum+offset, episodes)
      end if
      ' stop early if user selects something or exits
      status = m.checkForInput(selItem, msgPort, 10)

      if status = "selected"
        rokuGridScreen.Close()
        return true
      else if status = "exit"
        rokuGridScreen.Close()
        return false
      end if
    end if

    if rowNum = selItem.listIndex
      rokuGridScreen.SetFocusedListItem(selItem.listIndex, selItem.itemIndex)
    end if

    if isShown = false  and rowNum >= selItem.listIndex
      rokuGridScreen.Show()
      if gridStyle = "two-row-flat-landscape-custom"
        rokuGridScreen.SetDescriptionVisible(false)
      end if
      isShown = true
    end if

    rowNum = rowNum + 1
  end while

  'introScreen = IntroScreen(m.utils)
  'playlist = cp.getPlaylist(0)
  'episode = cp.getEpisodeInPlaylist(playlist, 1)
  'ShowVarSimple(episode, "asdf")
  'introScreen.showVideo(episode)

	' loop till user selects something or exits
	while true
    status = m.checkForInput (selItem, msgPort, 0)
    if status = "exit"
        return false
    else if status = "selected"
      rokuGridScreen.Close()
      return true
    end if
	end while

End Function

' -------------------------------
' checks for the user either:
'  1. exiting the grid rokuGridScreen (such as with back button or home button), or
'  2. selecting a video
' Returns 'exit' for case 1, or 'selected' for case 2.
' If time is 0, will wait forever for user input, if time is a value
'  in milliseconds, will return quickly with empty string if nothing happened
' if it returns 'selected', the selItem will be populated with correct
'  values
g.app.gridScreen.checkForInput = function (selItem, msgPort, time)
  msg = wait(time, msgPort)
  if msg <> invalid
	  m.utils.setContext("gridScreen", selItem)
    m.utils.globalMessageHandler(msg)
    if type(msg) = "roGridScreenEvent"
      if msg.isScreenClosed()
        return "exit"
      else if msg.isListItemSelected()
        'if m.utils.getSubscription()
        '  offset = 0
        'else
          offset = 1
        'end if

        selItem.listIndex = msg.GetIndex()-offset
        selItem.itemIndex = msg.GetData()
        if selItem.listIndex <> -1 or selItem.itemIndex <> 1
          return "selected"
        end if
      else if msg.isListItemFocused()
        itemIndex = msg.GetData()

      end if
    end if
  end if
  return ""
end function

'---------------------------------
g.app.gridScreen.showToolsRow = function (rokuGridScreen)
  isSubscribed = m.utils.getSubscription()

  item1 = {
    sdposterurl: "http://cdn.adrise.com/hotpatches/roku/watch-adfree-portrait2.jpg"
    hdposterurl: "http://cdn.adrise.com/hotpatches/roku/watch-adfree-portrait2.jpg"
    title: "Want to skip ads?"
    description: "Click here to learn more"
    }
  if isSubscribed = true
    globals = GetGlobalAA()
    app = globals.app
    item1.title = "You are subscribed to " + app.settings.appName
    item1.description = "Visit http://vezo.tv to manage your subscriptions"
  end if

  item2 = {
    sdposterurl: "http://cdn.adrise.com/hotpatches/roku/help-portrait.jpg"
    hdposterurl: "http://cdn.adrise.com/hotpatches/roku/help-portrait.jpg"
    title: "Support"
    description: "Please visit http://vezo.tv or email support@vezo.tv"
    }
  rokuGridScreen.SetContentList(0, [item1, item2])
  return 1 ' offset (currently always 1, if 0, will have no top row)
end function

' -------------------------------
g.app.gridScreen.initGrid = function (rokuGridScreen as Object, cp as Object)

 '' why?

  'if m.utils.getSubscription()
  '  offset = 0
  '  names = []
  'else

    names = ["Tools"]


    rokuGridScreen.SetContentList(0, names)
    offset = m.showToolsRow(rokuGridScreen)
  'end if
  rowNum = 0
	while true
    playlist = cp.getPlaylist(rowNum)
    if playlist <> invalid
        names.push(playlist.name)
    else
      exit while
    end if
    rowNum = rowNum + 1
  end while
  rokuGridScreen.SetupLists(rowNum+offset)
  rokuGridScreen.SetListNames(names)
end function

g.app.runApp = function ()
  m.settings.vezoSubscription = false
  m.settings.allowVezoSubscription = true
  m.settings.vezoServer = "http://vezo.tv" ' 192.168.1.200"

  ' show the graphic/logo
	graphic = showGraphic(m.settings.adrise_fontcolor, m.settings.adrise_bg, m.settings.adrise_loadingurl, m.settings.loadingBackgroundImage)

  serverLink = m.serverLinker(m.utils, m.player, m.settings)

  serverLink.connectToAccount(false)

  'if linkStatus = "ok"
    ' this object persists for the life of the program, and always
    '  points to the item in the grid that is currently focused or will
    '  be focused next time the grid displays.
    m.selectedItem = {
      listIndex: 1
      itemIndex: 2
    }

    if m.settings.GridStyle = "Flat-Movie"
      m.selectedItem.listIndex = 0
    else if m.settings.GridStyle = "two-row-flat-landscape-custom"
      m.selectedItem.listIndex = 0
      m.selectedItem.itemIndex = 0
    end if
    ' do we have a video to auto-play?
    'autoPlayVideoId = m.crossAppPromotion.checkForAutoPlay(m.settings.appName)

    autoPlayVideoId = invalid
    if (autoPlayVideoId <> invalid)
      m.episode = m.cp.getEpisodeFromServer(autoPlayVideoId)
      if m.episode <> invalid
        m.cp.getRenditionsForEpisode(m.episode)
        m.episode.PlayStart = 0
        m.player.playVideo(m.episode)
      end if
    end if

     m.utils.trackEvent({
        trackType: "StartApp"
      })

    ' GridScreen.show() returns true if it wants us to show the detail screen, using
    '  the values that are now in 'selectedItem' (as well as using the stuff in
    '  'content' that it populated).
    ' Note: we would prefer not have to recreate the gridscreen each time, but
    ' old devices have an issue with ads playing when the grid screen still exists
    while m.gridScreen.show(m.selectedItem, m.cp, m.settings.GridStyle) = true
      if(m.selectedItem.listIndex = -1)
        serverLink.connectToAccount(true)
        if(m.player.subscription)
          m.utils.showErrorMessage (m.settings.adrise_bg, m.settings.adrise_fontcolor, m.settings.adrise_loadingurl, "You are subscribed to " + m.settings.appName)
        end if
      else
        playlist = m.cp.getPlaylist(m.selectedItem.listIndex)
        m.selectedItem.itemIndex = m.handleItemPicked(playlist, m.selectedItem.itemIndex)
      end if
    end while

    if m.cp.errorMessage <> invalid
      print "message > " ; m.cp.errorMessage
      m.utils.showErrorMessage (m.settings.adrise_bg, m.settings.adrise_fontcolor, m.settings.adrise_loadingurl, m.cp.errorMessage)
    end if
 ' end if

   m.utils.trackEvent({
        trackType: "ExitApp"
      })
  hideGraphic(graphic)
end function


'------------------------------------------------------------------
g.app.detailScreen.show = function(episode, playlist, itemIndex)
	port = CreateObject("roMessagePort")

  maxIndex = m.cp.getPlaylistLength(playlist) - 1

	screen = CreateObject("roSpringboardScreen")
	screen.SetBreadcrumbText("", playlist.name)
	screen.SetDescriptionStyle("movie")
	screen.SetPosterStyle(m.settings.SetPosterStyle)
	screen.SetStaticRatingEnabled(false)
	screen.SetMessagePort(port)

	m.utils.portWaitStarting(port)

	showRentButton = (m.settings.allowRentals=true)
	m.update(screen, episode, showRentButton)
	screen.Show()
  while true
		msg = wait(0, port)
		m.utils.setContext("detailScreen", playlist, itemIndex)
	  m.utils.globalMessageHandler(msg)
		if type(msg) = "roSpringboardScreenEvent"

      if msg.isScreenClosed()

        exit while
      else if msg.isButtonPressed()
        button = msg.GetIndex()
        episode.PlayStart = 0
        if button = 1 or button = 2
          if button = 2 ' resume playing
            PlayStart = RegRead(episode.id)
            if PlayStart <> invalid then
              episode.PlayStart = PlayStart.ToInt()
            end if
          end if

          ' play till end of playlist
          while true
            m.cp.GetRenditionsForEpisode(episode)
            ret = m.player.playVideo(episode)
            if (ret <> "CLOSED" and itemIndex < maxIndex)
              itemIndex = itemIndex + 1
              episode = m.cp.getEpisodeInPlaylist(playlist, itemIndex)
              episode.PlayStart = 0
              m.update(screen, episode, showRentButton)
            else
              ' return itemIndex
              exit while
            end if
          end while
          m.updateButtons(screen, episode, showRentButton)
        else if button = 3
          m.showRentDialog(episode)
        else if button = 4
          m.showCaptionsDialog(episode)

        else if button = 5
          globals = GetGlobalAA()
          app = globals.app
          serverLink = app.serverLinker(m.utils, m.player, m.settings)
          serverLink.connectToAccount(true)
          m.updateButtons(screen, episode, (showRentButton and m.player.subscription = true))
          if(m.player.subscription = true)
            m.utils.showErrorMessage (m.settings.adrise_bg, m.settings.adrise_fontcolor, m.settings.adrise_loadingurl, "You are subscribed to " + m.settings.appName)
          end if
        end if
      else if msg.isRemoteKeyPressed()
        button = msg.GetIndex()
        if button = 4 or button = 5
          itemIndex = m.moveForwardBackward(itemIndex, maxIndex, (button = 5))
          episode = m.cp.getEpisodeInPlaylist(playlist, itemIndex)
          m.update(screen, episode, showRentButton)
        else
          ' print msg
        end if
      end if
    else
    ' print "test"
    end if

  end while
  return itemIndex
end function

g.app.detailScreen.origUpdateButtons = g.app.detailScreen.updateButtons

'------------------------------------------------------------------
g.app.detailScreen.updateButtons = function(screen, episode, showRentButton)
  m.origUpdateButtons (screen, episode, showRentButton)
  if(m.player.subscription <> true)
    screen.AddButton(5, "Subscribe to " + m.settings.appName)
  end if
end function

end if


g.app.player.ads.showVideoAd = function (canvas, adUnit, adDetails, playerSettings)
  if adUnit.id = "1453" or adUnit.id = "1455"
    return "COMPLETED"
  end if

  status = "COMPLETED"
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

  if(adUnit.id = "1311" or adUnit.id = "1452" or adUnit.id = "1451" or adUnit.id = "1450" or adUnit.id = "1449")
    m.skippable = m.loadSkippable(canvas)
  else
    m.skippable = invalid
  end if

  while true

    currOption = adUnit.currentOption
    msg = wait(0, canvas.GetMessagePort())

    'respObj = m.utils.getAsyncResponse(msg)

    'if(respObj <> invalid)
    '  ShowVarSimple(respObj, "async resp")
    'end if

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
            print "partial"
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
          ' show percentage of content video?
          player.Stop()
          canvas.close()
          status = "CLOSED"
          return status
        else if (i = 3)
          print "Pressed down"
        end if
      else if (msg.isScreenClosed())
        player.Stop()
        canvas.close()
        return status
      end if
    else if type(msg) = "roVideoPlayerEvent"
      if msg.isStreamStarted()
        print "stream started"

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

g.app.player.ads.loadSkippable = function (canvas)
    mode = CreateObject("roDeviceInfo").GetDisplayMode()
    res = "480px/"
    if mode = "720p"
      res = "720px/"
    end if

    rect = canvas.GetCanvasRect()
    o = {
        canvas: canvas
        textcolor: "#CCCCCC"
        fonts :     CreateObject("roFontRegistry")
        skipTime: 5
        time: 0
      }
    if mode = "720p"
      o.layout = {
         full: rect
          counter: { x: 947, y: 627, w: 250, h: 60 }
        }
      o.counterFont = o.fonts.get("Default", 18, 50, false)
      o.counterFont = o.fonts.get("Default", 25, 50, false)
    else
      o.layout = {
        full: rect
        counter :  { x : 512,  y : 351,  w : 40,  h : 40 }
      }
      o.counterFont = o.fonts.get("Default", 12, 50, false)
      o.counterFont = o.fonts.get("Default", 14, 50, false)
    end if

    '---------------------------
    o.setup = function ()
      m.canvas.AllowUpdates(false)
      m.canvas.Clear()
      m.canvas.SetLayer(0, [
        {
        Color: "#00000000",
        targetRect: m.layout.full
        compositionMode: "Source"
        }
      ])
      m.update(0)
      m.canvas.AllowUpdates(true)
    end function

    '---------------------------
    o.update = function (time)
      m.time = time
      list = []

      list.Push({
              Color: "#88FFFFFF",
              TargetRect: { x: m.layout.counter.x-1, y: m.layout.counter.y-1, w: m.layout.counter.w+2, h:  m.layout.counter.h+2 }
              compositionMode: "Source_over"
            })
      list.Push({
              Color: "#88000000",
              TargetRect: m.layout.counter
              compositionMode: "Source"
            })

      remaining = m.skipTime - m.time

      if remaining < 1
        list.Push({
              Text: "Press OK to skip this ad now"
              TargetRect: m.layout.counter
              TextAttrs: { halign: "HCenter", valign: "VCenter", font: m.counterFont, color: m.textcolor }
            })
       else
        list.Push({
              Text: "You may skip ad in " + remaining.tostr() + " seconds"
              TargetRect: m.layout.counter
              TextAttrs: { halign: "HCenter", valign: "VCenter", font: m.counterFont, color: m.textcolor }
            })
      end if
      m.canvas.SetLayer(1, list)
    end function
    return o

end function

'g.getLexusAdRectangles(true)
