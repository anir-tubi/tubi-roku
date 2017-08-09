print "Hot Patch 2.2.oldui"


'Turn off Live TV
m.app.linearTV.showLinearTV = false
m.app.cp.showLinearTV = false

' Disallow SMS for activation
m.app.registerScreen.allowSMS = false

'add protection to the url generating function in order to fix crashes as seen in roku's crash repoport UI
m.app.player.ads.populateUrl = function(episode, playerSettings)
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
    else
      'send debug log in the case that there is no appId on playerSettings
      message = "No app id as string in the player settings"
      message = m.addLogIdentifier(message, episode)
      m.utils.log.warn(m.playerPort, "clientWarn", "missing-appId", message)
    end if

    if type(playerSettings.pubId) = "String" or type(playerSettings.pubId) = "roString"
      pubId = "&pubid=" + playerSettings.pubId
    else
      'send debug log in the case that there is no pubId on playerSettings
      message = "No pub id as string in the player settings"
      message = m.addLogIdentifier(message, episode)
      m.utils.log.warn(m.playerPort, "clientWarn", "missing-pubId", message)
    end if

    if type(playerSettings.contentType) = "String" or type(playerSettings.contentType) = "roString"
      contentType = "&content-type=" + playerSettings.contentType
    else
      'send debug log in the case that there is no contentType on playerSettings
      message = "No content type as string in the player settings"
      message = m.addLogIdentifier(message, episode)
      m.utils.log.warn(m.playerPort, "clientWarn", "missing-contentType", message)
    end if
  else
    'send debug log in the case that there is no player settings
    message = "No player settings in oldUI ads.populateUrl()"
    message = m.addLogIdentifier(message, episode)
    m.utils.log.warn(m.playerPort, "clientWarn", "missing-playerSettings", message)
  end if

  cid = ""
  nowPos = "&nowpos=0"
  if episode <> invalid
    if type(episode.id) = "String" or type(episode.id) = "roString"
      cid = "&cid=" + episode.id
    else
      'send debug log in the case that there is no id on episode
      message = "No id as string on the video"
      message = m.addLogIdentifier(message, episode)
      m.utils.log.warn(m.playerPort, "clientWarn", "missing-cid", message)
    end if

    if type(episode.nowPos) = "roFloat" or type(episode.nowPos) = "roInteger"
      nowPos = "&nowpos=" + Int(episode.nowPos).ToStr()
    else
      'send debug log in the case that the episode wasn't sent to ads
      message = "No nowPos as float or integer on the video"
      message = m.addLogIdentifier(message, episode)
      m.utils.log.warn(m.playerPort, "clientWarn", "missing-nowPos", message)
    end if
  else
    'send debug log in the case that the episode wasn't sent to ads
    message = "No video sent to ads.populateUrl()"
    message = m.addLogIdentifier(message, episode)
    m.utils.log.warn(m.playerPort, "clientWarn", "missing-video", message)
  end if

  'create the url to be used for ad calls'
  url = m.baseUrl + "?platform=roku" + appId + adSdk + cid + nowPos + model + deviceId + optOut + urlAdId + urlTubiId + pubId + contentType + isLinear + "&_=" + RND(1000000000000).ToStr()

  return url
end function


m.app.player.ads.addLogIdentifier = Function(message, episode)
  if episode <> invalid
    if type(episode.id) = "String" or type(episode.id) = "roString"
      message = message + " for video with id = " + episode.id
    else if episode.title <> invalid and episode.title.len() > 0
      message = message + " for video with title = " + episode.title
    else if episode.description <> invalid and episode.description.len() > 0
      message = message + " for video with description = " + episode.description
    end if
  else
    message = message + " and no video info was sent to ad player."
  end if

  return message
End Function



'don't let users leave the app by pressing back from the sign in screen
m.app.registerScreen.show = function(regWall = "")
    
  'necessary when calling the show() method from detail screen
  '(ie. for registration walls)
  if m.res = invalid
    m = GetGlobalAA().app.registerScreen
  end if


  g = GetGlobalAA()

  m.canvas = CreateObject("roImageCanvas")
  port = CreateObject("roMessagePort")

  m.canvas.SetMessagePort(port)

  'sets state on m and returns the layers array
  layers = m.setupInitialScreen()

  'change the background for any registration walls
  if regWall = "premiere"
    layers[0].Url = "pkg:/images/oldUI/" + m.res + "/bg_premiere_wall.jpg"
  end if

  m.canvas.SetLayer(0, layers)
  m.paint()

  m.canvas.Show()
  m.utils.trackEvent({
    trackType: "pageLoad"
    value: "/deviceregistration"
    port: port
  })

  while(true)
    msg = wait(30, port)

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

    if type(msg) = "roUrlEvent"
      respObj = m.utils.getAsyncResponse(msg, 0)

    else if type(msg) = "roImageCanvasEvent"
      if msg.isRemoteKeyPressed()
        index = msg.GetIndex()

        'show initial "skip/ok" screen if appropriate
        if(m.isInitialScreen = true)


          if (index = 0) ' back
            m.canvas.close()
            m.canvas = invalid
            return true
          else if (index = 6) ' ok button on remote
            if(m.col = 0) 'selected OK button on screen
              if m.allowSMS <> invalid and m.allowSMS = false
                m.utils.trackEvent({
                  trackType: "navigate"
                  value: "/deviceregistration/code"
                  ctx: "/deviceregistration/"
                  port: port
                })

                sleep(300) 'pause just for a tiny bit to show the button turn color
                isRegistered = m.webRegister()

                print "shutting web register screen and isRegistered = "; isRegistered
                if isRegistered = true
                  m.isComplete = true
                  m.canvas.close()
                end if
              else
                loadingImage = {
                  Url: "pkg:/images/oldUI/" + m.res + "/bg_entry.jpg"
                  TargetRect: m.getRect("bg", 0)
                  compositionMode: "Source"
                }
                layers = [loadingImage]
                m.canvas.SetLayer(0, layers)
                m.isInitialScreen = false
                m.row = 1
                m.col = 1
                m.pressedItem = invalid

                m.utils.trackEvent({
                  trackType: "navigate"
                  value: "/deviceregistration/sms"
                  ctx: "/deviceregistration/"
                  port: port
                })

                m.utils.trackEvent({
                  trackType: "pageLoad"
                  value: "/deviceregistration/sms"
                  port: port
                })

                m.paint()
              end if
            else 'selected No Thanks button
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

        'enter phone number screen
        else
          if (index = 0) ' back
            layers = m.setupInitialScreen()
            m.canvas.SetLayer(0, layers)

            m.utils.trackEvent({
              trackType: "navigate"
              value: "/deviceregistration/"
              ctx: "/deviceregistration/sms"
              port: port
            })

            m.utils.trackEvent({
              trackType: "pageLoad"
              value: "/deviceregistration/"
              port: port
            })

            m.paint()

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
              m.utils.trackEvent({
                trackType: "navigate"
                value: "/deviceregistration/code"
                ctx: "/deviceregistration/sms"
                port: port
              })

              sleep(300) 'pause just for a tiny bit to show the button turn color
              isRegistered = m.webRegister()
              
              print "shutting web register screen and isRegistered = "; isRegistered
              if isRegistered = true
                m.isComplete = true
                m.canvas.close()
              end if
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


'fix live tv in the case where some videos are out of window
m.app.handleItemPicked = Function(playlist, listIndex, itemIndex, source)
  settings = m.utils.getSettings()
  episode = m.cp.getEpisodeInPlaylist(playlist, itemIndex)

  if episode.type = "tubiLogin" or episode.type = "bookmarks"
    authInfo = m.utils.getAuthInfo()
    if (authInfo.accessToken = invalid)
      'user wants to log in
      
      m.utils.trackEvent({
        trackType: "navigate"
        value: "/deviceregistration"
        ctx: "/home/cat/" + m.utils.sluggify(playlist.name)
        port: m.registerScreen.registerPort
      })

      m.registerScreen.show()

      'if the user has successfully logged in, lets see if we need to do a one time sync
      authInfo = m.utils.getAuthInfo()
      if authInfo.accessToken <> invalid
        m.utils.oneTimeBookmarkSync()
        m.utils.oneTimePreviouslyViewedSync()
        'since we are removing the bookmarks button, we need to reset the itemIndex
        itemIndex = 0
      end if

    'bookmarks button is only shown if the user is logged out already
    'so this else block should never run if bookmarks is selected
    else
      'user wants to log out - send logout to server - listen for response - if ok, delete auth info locally
      logoutPort = CreateObject("roMessagePort")
      logoutUrl = m.settings.logoutUrl
      logoutBody = {
        user_id: authInfo.userId
        device_id: m.utils.deviceInfo.deviceId
        platform: "roku"
      }
      logoutBodyJson = FormatJson(logoutBody)
      logoutHeaders = m.utils.getAuthHeaders(authInfo.refreshToken)
      logoutReqId = m.utils.sendAsyncRequest(logoutUrl, logoutPort, "logout", "POST", true, logoutBodyJson, logoutHeaders)

      while true
        msg = wait(0, logoutPort)
        if type(msg) = "roUrlEvent"
          logoutRes = m.utils.getAsyncResponse(msg, 0)
          print logoutRes
          if logoutRes <> invalid and logoutRes.data <> invalid and logoutRes.data.len() = 0
            'remove local storage of auth tokens
            m.utils.deleteAuthInfo()
            
            'remove local bookmarks and previously viewed info - so that we won't build those categories after logout
            m.cp.bookmarkIds = []
            m.cp.previouslyViewedIds = []

            m.cp.userPlaylists[settings.bookmarkRegistry].episodes = []
            m.cp.userPlaylists[settings.previouslyViewedRegistry].episodes = []

            m.cp.userPlaylistVideos = {}
            m.cp.userPlaylistSeries = {}

            'set state so we know if we need to add the user playlists rows if the user logs back in
            m.gridScreen.isShownAfterLogin = false

            exit while
          end if
        end if
      end while
    end if
  else if episode.type = "vezo"
    m.serverLink.connectToAccount(true)
    if(m.player.subscription)
      m.utils.showErrorMessage (m.utils.getSettings().adrise_bg, m.utils.getSettings().adrise_fontcolor, m.utils.getSettings().adrise_loadingurl, "You are subscribed to " + m.utils.getSettings().appName)
    end if
  else if episode.type = "search" 'load a search screen
    
    m.utils.trackEvent({
      trackType: "navigate"
      value: "/search"
      ctx: "/home/cat/" + m.utils.sluggify(playlist.name)
      port: m.searchScreen.searchPort
    })  
    
    m.searchScreen.show()
  else if episode.type = "linear" 'play linear tv
    'get episode content for linear episodes
    linearPlaylist = m.linearTv.getLinearPlaylist()
    m.cp.getAllEpisodesForPlaylistFromServer(linearPlaylist, "gridscreen")

    'remove any content that might be out of window
    validEpisodes = []
    for each episode in linearPlaylist.episodes
      if episode.id <> invalid and episode.streams <> invalid and episode.streams[0] <> invalid
        validEpisodes.push(episode)
      end if
    end for
    linearPlaylist.episodes = validEpisodes

    'determine correct episode and correct start time
    initialEpisodeInfo = m.linearTv.getCurrentEpisode(linearPlaylist)

    'make sure we have episodes to play
    if initialEpisodeInfo.initialEpisodeIndex <> invalid
      episodeCounter = initialEpisodeInfo.initialEpisodeIndex
      startTime = initialEpisodeInfo.startTime
      linearPlaylist.episodes[episodeCounter].playStart = startTime  'sets start time of first episode to play

      'set linearTvOn status to true
      m.linearTv.linearTvOn = true

      'play video
      maxIndex = m.cp.getPlaylistLength(linearPlaylist) - 1

      'tell the player to treat this first video (only) as one that is being resumed (ie. not starting from very beginning)
      linearPlaylist.episodes[episodeCounter].isResumed = true
      
      while true
        ret = m.player.playVideo(linearPlaylist.episodes[episodeCounter])

        'play next video in linear tv cue
        if ret <> "CLOSED"
          if episodeCounter < maxIndex
            episodeCounter = episodeCounter + 1
          else if episodeCounter = maxIndex
            episodeCounter = 0
          else
            exit while
          end if

          newEpisode = m.cp.getEpisodeInPlaylist(playlist, episodeCounter)
          if newEpisode <> invalid
            episode = newEpisode
            episode.PlayStart = 0
          end if
        else
          'set linearTvOn status to false and leave linear tv
          m.linearTv.linearTvOn = false
          exit while
        end if
      end while
    else
      'Add some messaging so the user knows there is no Live TV content for them.
    end if

  else if episode.type = "policy"
    m.policyScreen.show()

  else if episode.type = "video"   'episode is a movie
    ' does this app have you go through a details screen?
    if m.utils.getSettings().show_details_screen
      context = "/home/" + (listIndex + 1).toStr() + "/cat/" + m.utils.sluggify(playlist.name) + "/1/" + (itemIndex + 1).toStr()
      if source = "episodeListScreen"
        context = "/series/episodelist"
        if episode.parentId <> invalid
          context = context + "/" + episode.parentId
        end if
      end if
      m.utils.trackEvent({
        trackType: "navigate"
        value: "/video/" + episode.id
        ctx: context
        port: m.detailScreen.detailsPort
      })

      itemIndex = m.detailScreen.show(episode, playlist, itemIndex)
    else
      while episode <> invalid
        episode.PlayStart = 0
        if m.player.playVideo(episode) = "CLOSED"
          exit while
        end if
        episode = m.cp.getEpisodeInPlaylist(playlist, itemIndex+1)
        if episode <> invalid
          itemIndex = itemIndex + 1
        end if
      end while
    end if

  else   'episode is a series
    if episode.playlist <> invalid
      if (m.cp.autoplayData = invalid)

        m.utils.trackEvent({
          trackType: "navigate"
          value: "/series/episodelist/" + episode.id
          ctx: "/home/" + (listIndex + 1).toStr() + "/cat/" + m.utils.sluggify(playlist.name) + "/1/" + (itemIndex + 1).toStr()
          port: m.episodeListScreen.episodePort
        })      
      
        m.episodeListScreen.show(episode)

      else if m.cp.autoplayIsSeries = true
        'm.cp.autoplayIsSeries = true if deeplinking occurred with the mediaType="series" parameter
        m.episodeListScreen.autoPlay(episode, m.cp.autoplayData.path[2], m.cp.autoplayData.path[3], m.cp.autoplayIsSeries)
      else
        'm.cp.autoplayIsSeason = true if deeplinking occurred with the mediaType="season" parameter
        m.episodeListScreen.autoPlay(episode, m.cp.autoplayData.path[2], m.cp.autoplayData.path[3], m.cp.autoplayIsSeason)
      end if
    end if
  end if
  return itemIndex
end Function



m.app.player.showSpanOfContentVideoNew = Function(episode As Object)
  if type(episode) <> "roAssociativeArray"
    print "invalid data passed to showVideoScreen"
    return "COMPLETED"
  end if

  m.canvas = CreateObject("roImageCanvas")
  player = CreateObject("roVideoPlayer")

  m.canvas.SetMessagePort(m.playerPort)
  player.SetMessagePort(m.playerPort)

  'put the canvas on the screen - the canvas is the container for the player
  m.canvas.show()

  'set how often the player gives info on play progress (in seconds)
  player.SetPositionNotificationPeriod(1)
  
  'add the video to the player
  player.SetContentList([episode])

  'set up the subtitles/captions renderer
  captions = player.getCaptionRenderer()
  captions.SetScreen(m.canvas)
  captions.SetMode(1)
  captions.SetMessagePort(m.playerPort)
  

  'show the subtitles if the episode says we should
  deviceInfo = CreateObject("roDeviceInfo")
  globalCaptions = deviceInfo.GetCaptionsMode()
  if globalCaptions = "On"
    captions.showSubtitle(true)
  else
    captions.showSubtitle(false)
  end if

  'object that will help us determine how long we've been scrubbing for
  scrubTimer = CreateObject("roTimespan")
  
  'holds the state of the player
  playerStates = {
    loadProgress: 0
    isTransportShowing: false
    isPaused: false
    isInHopMode: false
    isScrubbing: false
    nowPosAtScrub: 0
    maxScrub: 7
    scrubAmount: 0
    scrubMultiplier: 0
    totalScrubTime: 0
    scrubToPoint: 0
    scrubPercent: 0
    nowPos: 0
    replayEnd: 0
    displayWidth: m.utils.deviceInfo.displayWidth
    lastsavedPosition: episode.nowPos
  }

  'globally scoped function to do the necessary tasks related to start scrubbing
  startScrub = function(player, scrubTimer, playerStates, episode)
    playerStates.isTransportShowing = true
    playerStates.isPaused = true
    playerStates.isScrubbing = true
    playerStates.scrubStartPos = playerStates.nowPos
    player.pause()
    scrubTimer.Mark() 'set the time we start scrubbing

    m.app.utils.trackEvent({
      trackType: "playProgress"
      ctx: episode.id
      value: playerStates.nowPos
      extraCtx: {interval: playerStates.nowPos - m.app.player.lastPingTime}
      port: m.app.player.playerPort
    })
  end function


  'globally scoped function to do the necessary tasks related to end of scrubbing/re-start video
  endScrub = function(player, playerStates, episode)
    playerStates.scrubToPoint = playerStates.scrubStartPos + playerStates.totalScrubTime
    
    'prevents the user from rewinding past the beginning of the video or fast forwarding past the end of the video
    if playerStates.scrubToPoint >= episode.length
      playerStates.scrubToPoint = episode.length - 4
    end if
    if playerStates.scrubToPoint < 0
      playerStates.scrubToPoint = 0
    end if
    playerStates.nowPos = Int(playerStates.scrubToPoint)
    episode.nowPos = playerStates.nowPos
    episode.playStart = playerStates.nowPos

    m.app.player.shouldResetPing = true

    m.app.utils.trackEvent({
      trackType: "seek"
      ctx: episode.id
      value: playerStates.nowPos
      port: m.playerPort
    })
    
    'when resuming to play after ending fast forward, we need to ask the ad server if there are any ads
    'getResumingPlayAds will store ads in either m.app.player.resumePlayAdsList or m.app.player.ads.allAdUnitsList
    'depending on if RAF is off or on
    if playerStates.isInHopMode = false
      if playerStates.nowPos > playerStates.nowPosAtScrub
        shouldBreak = m.app.player.ads.getResumingPlayAds(episode, m.app.player)
        if shouldBreak = true
          return true
        end if
      end if

      player.Seek(playerStates.scrubToPoint * 1000)
      playerStates.isTransportShowing = false
      playerStates.isPaused = false
      playerStates.nowPosAtScrub = 0
    end if

    playerStates.isScrubbing = false
    playerStates.scrubAmount = 0
    playerStates.totalScrubTime = 0
    playerStates.scrubToPoint = 0

    return false
  end function  
  'scrubbing amount can be from -3 to 3, not including 0 (-3 is max rewind, 3 is max fast forward)
  'each strength needs a specific multiplier, of how fast we move through the video while scrubbing
  'can be 2x, 4x, 6x

  'start the playing of the video
  player.play()

  'instantiate progressPercent
  progressPercent = 0

  while true
    'total scrub time is the number of ms we have moved forward or backwards since scrubbing began.
    if playerStates.isTransportShowing = true

      'scrubbing will always have the transport showing so this will always run if scrubbing
      if playerStates.isScrubbing = true
        playerStates.totalScrubTime = playerStates.totalScrubTime + scrubTimer.TotalMilliseconds() * playerStates.scrubMultiplier / 1000
        playerStates.scrubToPoint = playerStates.scrubStartPos + playerStates.totalScrubTime

        'prevents the time in the bottom left of the screen from going negative or going above length of video
        if playerStates.scrubToPoint >= episode.length
          playerStates.scrubToPoint = episode.length
        end if
        if playerStates.scrubToPoint < 0
          playerStates.scrubToPoint = 0
        end if

        playerStates.nowPos = playerStates.scrubToPoint
        scrubTimer.Mark()
      end if
      
      'update the transport overlay with new time and progress on the bar
      playerStates.scrubPercent = 1
      if episode.length > 0
        playerStates.scrubPercent = playerStates.nowPos / episode.length 'updates the transport bar percent filled
      end if

      m.paintToCanvas(progressPercent, playerStates, episode)
    end if

    msg = wait(200, m.playerPort)

    if type(msg) = "roVideoPlayerEvent"
      'log an error if the video fails to play
      if msg.isRequestFailed()

        if episode <> invalid and episode.id <> invalid
          errorMsg = "video with id: " + episode.id + " failed. Error Index " + msg.getIndex().toStr() +  " : " + msg.getMessage()
        else
          errorMsg = "video has no id and likely no video url. Error Index " + msg.getIndex().toStr() +  " : " + msg.getMessage()
        end if
        m.utils.log.error(m.playerPort, "videoPlayback", "video-fail", errorMsg)

        m.canvas.close()
        return "FAILED"
      end if

      'log any re-buffers that user might encounter
      if msg.isStreamStarted()
        if msg.getInfo().isUnderrun = true
          warningMsg = "Video with id: " + episode.id + " buffered mid stream. Segment Url: " + msg.getInfo().url + " Stream Bitrate: " + msg.getInfo().streamBitrate.toStr() + " Measured Bitrate: " + msg.getInfo().measuredBitrate.toStr()
          m.utils.log.warn(m.playerPort, "videoBuffer", "video-rebuffer",  warningMsg)
        end if
      end if

      'if event is that the video content has reached the end
      if msg.isFullResult()
        m.canvas.close()
        return "COMPLETED"
      end if

      'if the player sends an event updating the position withing the movie (it should be set to fire every second)
      'then store the position in the movie that the player has played to
      if msg.isPlaybackPosition()
        playerStates.nowPos = msg.GetIndex()

        'when ending sync, the video restarts at the last 10 second interval. 
        'the code below will reset our last ping time to be in line with the actual nowPos
        if m.shouldResetPing = true
          m.lastPingTime = playerStates.nowPos
          m.shouldResetPing = false
        end if

        'if the nowPos has changed by more than 60 seconds since the last time we saved nowPos to memory, save again
        'this should give the user a reasonably correct place to resume if they hit the home button or the app crashes
        'otherwise we are saving the most recent position when ads play or they back out of the player
        if msg.GetIndex() > playerStates.lastsavedPosition + 60 or msg.GetIndex() < playerStates.lastsavedPosition - 60
          m.savePreviouslyViewedUpdate(episode, playerStates.nowPos)          
          playerStates.lastsavedPosition = playerStates.nowPos
        end if

        'checks if there is a commercial break about to occur (4 to 7 seconds before a cue point)
        'if there is, caches an appropriate set of ads for the ad break depending on which framework is being used
        'if a breakPos is returned, it means that we should play an ad that has previously been cached so we stop for commercial
        breakPos = m.ads.checkForCommercialBreak(playerStates.nowPos, episode, m)
        if breakPos <> -1
          episode.nowPos = breakPos
          episode.playStart = breakPos
          list = m.ads.getCachedAdsList(episode)
          if list <> invalid
            'save the last position to memory
            m.savePreviouslyViewedUpdate(episode, playerStates.nowPos)

            'tell the video player we are stopping and going to play a set of ads
            m.canvas.close()
            return "STOPFORCOMMERCIAL"
          end if
        end if

        'sends a play progress tracking event if enough time has elapsed
        if playerStates.nowPos >= m.lastPingTime + m.pingFrequency
          playProgressEvent = {
            trackType: "playProgress"
            ctx: episode.id
            value: playerStates.nowPos
            port: m.playerPort
          }

          if m.linearTvOn = true
            playProgressEvent.extraCtx = {
              URI: "home/livetv/roku"
            }
          end if

          m.utils.trackEvent(playProgressEvent)

          m.lastPingTime = playerStates.nowPos
        end if

        'turns the captions off if instant replay captions have been activated and 30s has elapsed
        if playerStates.replayEnd > 0 and playerStates.nowPos > playerStates.replayEnd
          m.cancelInstantReplay(playerStates, captions)
        end if
      end if

      'show a loading screen while the video buffers
      if msg.isStatusMessage() and msg.GetMessage() = "startup progress"
        playerStates.isPaused = false
        progressPercent = msg.GetIndex() / 10
        if playerStates.loadProgress <> progressPercent
          playerStates.loadProgress = progressPercent
          m.paintToCanvas(progressPercent, playerStates, episode)
        end if
      end if

    'listens if we need to update the subtitles/captions
    else if type(msg) = "roCaptionRendererEvent"
      if msg.isCaptionUpdateRequest()
        player.clear(&h00)
        captions.UpdateCaption()
      end if


    else if type(msg) = "roImageCanvasEvent"
      if msg.isScreenClosed()
        ' This is only relevant when the user exits the channel.  From testing, I
        ' found that this event fires before the VM is shut down which is just
        ' enough time to fix the global caption state.
        m.cancelInstantReplay(playerStates, captions)

      'the user pressed a button on the remote
      else if msg.isRemoteKeyPressed()
        'back button
        if msg.GetIndex() = 0
          'close the screen
          m.canvas.close()
          'save the last position to memory
          m.savePreviouslyViewedUpdate(episode, playerStates.nowPos)
          m.canvas.close()
          m.cancelInstantReplay(playerStates, captions)
          return "CLOSED"
        end if
        
        'rewind
        if msg.GetIndex() = 8
          if playerStates.isInHopMode = true
            playerStates.isInHopMode = false
          end if

          if playerStates.isScrubbing = false
            playerStates.nowPosAtScrub = playerStates.nowPos
            m.cancelInstantReplay(playerStates, captions)
            startScrub(player, scrubTimer, playerStates, episode)
          end if
          'update the speed of scrubbing with max ff or rw at 6
          if playerStates.scrubAmount > (playerStates.maxScrub * -1)
            playerStates.scrubAmount = playerStates.scrubAmount - 1

            if playerStates.scrubAmount < 0
              playerStates.scrubMultiplier = -2 ^ (-1 * playerStates.scrubAmount)
            else if playerStates.scrubAmount > 0
              playerStates.scrubMultiplier = 2 ^ playerStates.scrubAmount
            end if

            'happens if after rewinding, user then hits fast forward to slow down back to play
            if playerStates.scrubAmount = 0
              shouldBreak = endScrub(player, playerStates, episode)
              if shouldBreak = true
                episode.nowPos = playerStates.nowPos
                episode.playStart = playerStates.nowPos
                m.canvas.close()
                return "RESUMEPLAY"
              end if
            else
              'updates the screen with the new amount of scrubbing
              m.paintToCanvas(progressPercent, playerStates, episode)
            end if
          end if
        end if
  
        'fast forward
        if msg.GetIndex() = 9
          if playerStates.isInHopMode = true
            playerStates.isInHopMode = false
          end if

          if playerStates.isScrubbing = false
            playerStates.nowPosAtScrub = playerStates.nowPos
            m.cancelInstantReplay(playerStates, captions)
            startScrub(player, scrubTimer, playerStates, episode)
          end if
          'update the speed of scrubbing with max ff or rw at 6
          if playerStates.scrubAmount < playerStates.maxScrub
            playerStates.scrubAmount = playerStates.scrubAmount + 1

            if playerStates.scrubAmount < 0
              playerStates.scrubMultiplier = -2 ^ (-1 * playerStates.scrubAmount)
            else if playerStates.scrubAmount > 0
              playerStates.scrubMultiplier = 2 ^ playerStates.scrubAmount
            end if

            'happens if after rewinding, user then hits fast forward to slow down back to play
            if playerStates.scrubAmount = 0
              shouldBreak = endScrub(player, playerStates, episode)
              if shouldBreak = true
                episode.nowPos = playerStates.nowPos
                episode.playStart = playerStates.nowPos
                m.canvas.close()
                return "RESUMEPLAY"
              end if
            else
              'updates the screen with the new amount of scrubbing
              m.paintToCanvas(progressPercent, playerStates, episode)
            end if
          end if
        end if

        'left/right buttons: 10 second hop back/forth
        if msg.GetIndex() = 4 or msg.GetIndex() = 5
          m.cancelInstantReplay(playerStates, captions)
          playerStates.isInHopMode = true
          if playerStates.nowPosAtScrub = 0
            playerStates.nowPosAtScrub = playerStates.nowPos
          end if

          'if user is fast forwarding or rewinding stop the scrub
          if playerStates.isScrubbing = true
            shouldBreak = endScrub(player, playerStates, episode)
            if shouldBreak = true
              episode.nowPos = playerStates.nowPos
              episode.playStart = playerStates.nowPos
              m.canvas.close()
              return "RESUMEPLAY"
            end if

          'if the user is in normal playback mode then show the transport
          else
            if playerStates.isTransportShowing = false
              playerStates.isTransportShowing = true
            end if

            playerStates.isPaused = true
            player.pause()
          end if

          if msg.GetIndex() = 4
            'hop back
            if playerStates.nowPos - 10 < 0
               playerStates.nowPos = 0
            else
              playerStates.nowPos = playerStates.nowPos - 10
            end if
          else
            'hop forward
            if playerStates.nowPos + 10 > episode.length - 5
               playerStates.nowPos = episode.length - 5
            else
              playerStates.nowPos = playerStates.nowPos + 10
            end if
          end if

          episode.nowPos = playerStates.nowPos
          episode.playStart = playerStates.nowPos

          m.paintToCanvas(progressPercent, playerStates, episode)
        end if

        'ok/select
        if msg.GetIndex() = 6

          'if user is fast forwarding or rewinding stop the scrub and resume playing
          if playerStates.isScrubbing = true
            shouldBreak = endScrub(player, playerStates, episode)
            if shouldBreak = true
              episode.nowPos = playerStates.nowPos
              episode.playStart = playerStates.nowPos
              m.canvas.close()
              return "RESUMEPLAY"
            end if

          'hop to the position the user has chosen and close the transport
          else if playerStates.isInHopMode = true
            'if result of hopping is ultimately advancing the nowPos, test for ads
            print "now pos "; playerStates.nowPos; " > now pos at scrub "; playerStates.nowPosAtScrub
            if playerStates.nowPos > playerStates.nowPosAtScrub
              shouldBreak = m.ads.getResumingPlayAds(episode, m)
              if shouldBreak = true
                episode.nowPos = playerStates.nowPos
                episode.playStart = playerStates.nowPos
                m.canvas.close()
                return "RESUMEPLAY"
              end if
            end if
            playerStates.nowPosAtScrub = 0
            playerStates.isPaused = false
            playerStates.isInHopMode = false
            playerStates.isTransportShowing = false
            player.seek(playerStates.nowPos * 1000)
            m.paintToCanvas(progressPercent, playerStates, episode)

          'show the transport overlay while continuing the show
          else if playerStates.isTransportShowing = false
            playerStates.isTransportShowing = true
            m.paintToCanvas(progressPercent, playerStates, episode)

          'close the transport overlay while continuing the show
          else
            playerStates.isTransportShowing = false
            if playerStates.isPaused = true
            
              m.utils.trackEvent({
                trackType: "pauseToggle"
                ctx: episode.id
                value: "resumed"
                port: m.playerPort
              })

              playerStates.isPaused = false
              player.resume()
            end if
            
            m.paintToCanvas(progressPercent, playerStates, episode)
          end if
        end if

        'instant replay button
        if msg.GetIndex() = 7
          globalCaptions = deviceInfo.GetCaptionsMode()
          'stop any active scrubbing before jumping back due to instant replay button
          if playerStates.isScrubbing = true
            shouldBreak = endScrub(player, playerStates, episode)
            if shouldBreak = true
              episode.nowPos = playerStates.nowPos
              episode.playStart = playerStates.nowPos
              m.canvas.close()
              return "RESUMEPLAY"
            end if
          end if

          'jump back 30s in the video - only if the video has started playing (ie. ignore during loading)
          if playerStates.loadProgress = 100
            if playerStates.nowPos - 30 < 0
              playerStates.nowPos = 0
            else
              playerStates.nowPos = playerStates.nowPos - 30
            end if
            episode.nowPos = playerStates.nowPos
            player.Seek(playerStates.nowPos * 1000)

            'set up captions for 30s if the user has instant replay captions set globally
            if globalCaptions = "Instant replay"
              captions.showSubtitle(true)
              ' For RokuTV: The showSubtitle call is ignored if global caption state is not "on", so
              ' a temporary change has to be made at the global "device" level, then switched back later.
              deviceInfo.SetCaptionsMode("On")
              playerStates.replayEnd = playerStates.nowPos + 30
            end if

            if playerStates.isTransportShowing = true
              playerStates.isTransportShowing = false
              m.paintToCanvas(progressPercent, playerStates, episode)
            end if
          end if
        end if

        '* button
        if msg.GetIndex() = 10
          playerStates.isPaused = true
          player.pause()
          
          'show a dialog that will let users turn on/off captions
          m.cancelInstantReplay(playerStates, captions)  ' set up the caption dialog by interrupting any instant replay captions
          if GetGlobalAA().app.detailScreen.showCaptionsDialog(episode) = "On"
            captions.showSubtitle(true)
          else
            captions.showSubtitle(false)
          end if
          playerStates.isPaused = false
          player.resume()
        end if

        'play/pause button
        if msg.GetIndex() = 13
          'if scrubbing, stop the scrubbing and resume the show
          if playerStates.isScrubbing = true
            shouldBreak = endScrub(player, playerStates, episode)
            if shouldBreak = true
              episode.nowPos = playerStates.nowPos
              episode.playStart = playerStates.nowPos
              m.canvas.close()
              return "RESUMEPLAY"
            end if

          'hop to the position the user has chosen and close the transport
          else if playerStates.isInHopMode = true
            'if result of hopping is ultimately advancing the nowPos, test for ads
            if playerStates.nowPos > playerStates.nowPosAtScrub
              shouldBreak = m.ads.getResumingPlayAds(episode, m)
              if shouldBreak = true
                episode.nowPos = playerStates.nowPos
                episode.playStart = playerStates.nowPos
                m.canvas.close()
                return "RESUMEPLAY"
              end if
            end if

            playerStates.nowPosAtScrub = 0
            playerStates.isPaused = false
            playerStates.isInHopMode = false
            playerStates.isTransportShowing = false
            player.seek(playerStates.nowPos * 1000)
            m.paintToCanvas(progressPercent, playerStates, episode)

          'if not scrubbing or hopping
          else
            'and not paused, then pause the show and show the transport overlay
            if playerStates.isPaused = false
              playerStates.isTransportShowing = true
              playerStates.isPaused = true
              player.pause()
              m.paintToCanvas(progressPercent, playerStates, episode)

              m.utils.trackEvent({
                trackType: "pauseToggle"
                ctx: episode.id
                value: "paused"
                port: m.playerPort
              })

            'if not scrubbing but paused, resume the show and remove the transport overlay
            'but first check if we should play a set of ads
            else
              m.utils.trackEvent({
                trackType: "pauseToggle"
                ctx: episode.id
                value: "resumed"
                port: m.playerPort
              })
                
              playerStates.isTransportShowing = false
              playerStates.isPaused = false
              player.resume()
              m.paintToCanvas(progressPercent, playerStates, episode)
  
            end if
          end if
        end if
      end if

    'handle any async responses (usually responses to playProgress and other user events, or responses to addHistory calls
    'but can be a response to outstanding ad pixel calls)
    else if type(msg) = "roUrlEvent"
      respObj = m.utils.getAsyncResponse(msg, 0)
  
      if m.previouslyViewedReqIds[respObj.id.toStr()] <> invalid
        'we know we have a response from updating previously viewed - so update the previouslyViewedServerId where necessary
        'this is necessary to make the "Remove from History" button work on the details page
        if respObj.data <> invalid and respObj.data.len() > 0
          addPreviouslyViewedResponse = parseJson(respObj.data)
          if addPreviouslyViewedResponse.content_type <> invalid

            if addPreviouslyViewedResponse.content_type = "series"
              if m.cp.userPlaylistSeries[addPreviouslyViewedResponse.content_id.toStr()] <> invalid
                m.cp.userPlaylistSeries[addPreviouslyViewedResponse.content_id.toStr()].previouslyViewedServerId = addPreviouslyViewedResponse.id
              end if
            else if addPreviouslyViewedResponse.content_type = "movie"
              if m.cp.userPlaylistVideos[addPreviouslyViewedResponse.content_id.toStr()] <> invalid
                m.cp.userPlaylistVideos[addPreviouslyViewedResponse.content_id.toStr()].previouslyViewedServerId = addPreviouslyViewedResponse.id
              end if
            end if

          end if
        end if

        'since we already got a response for this request id, we don't need to store the id anymore
        m.previouslyViewedReqIds.delete(respObj.id.toStr())
      end if
    end if
  end while

end function


'Update text on web coder registration screen
m.app.registerScreen.webRegister = Function()
  settings = m.utils.getSettings()

  'create new regId to send to server as a unique id that will be stored in Roku's local memory if registration is completed
  'regId will be saved into into memory as "token"
  regId = m.utils.generateUuId()

  webRegPort = CreateObject("roMessagePort")

  'set up registation screen
  webRegScreen = CreateObject("roCodeRegistrationScreen")
  webRegScreen.SetMessagePort(webRegPort)

  webRegScreen.AddHeaderText("Steps to activate Tubi TV for Roku")
  webRegScreen.AddParagraph("1) Register or sign in on a computer or mobile device at tubitv.com/activate")
  webRegScreen.AddParagraph("2) When asked, enter the activation code below.")
  webRegScreen.AddParagraph(" ")
  webRegScreen.SetRegistrationCode("Retrieving code...")
  webRegScreen.AddParagraph(" ")
  webRegScreen.AddParagraph("3) This screen will automatically update after you enter the code.")
  webRegScreen.AddButton(2, "Get a new code")
  webRegScreen.AddButton(1, "Cancel")
  webRegScreen.Show()

  m.utils.trackEvent({
    trackType: "pageLoad"
    value: "/deviceregistration/code"
    port: webRegPort
  })

  'close the phone register screen since we will never return to it from this screen
  ' m.canvas.Close()

  'get code from server and add it to screen

  'start polling server to see if the user has added the code. If after polling begins, the user asks for a new code
  'stop the current polling async request and start a new async request to get the code.
  'until there is an error or the server responds that the user has registered, there should always be exactly one async request
  'waiting for a response (either getting code or polling to see if registration complete)

  webRegUrlGetCode = settings.regUrlBase + "/generate"
  webRegUrlGetConfirmation = settings.regUrlBase + "/status"

  regCode = invalid
  regId = invalid
  token = invalid
  identifier = invalid

  haveRegistrationCode = false

  pollCounter = 0
  timeSpan = CreateObject("roTimespan")

  while true
    if haveRegistrationCode = false 'then we need to attempt to get the response code
      getCodeBody = {
        device_id: m.utils.deviceInfo.deviceId
        platform: "roku"
      }
      if identifier <> invalid
        getCodeBody.identifier = identifier
      end if
      
      getCodeBodyJson = FormatJson(getCodeBody)

      getCodeHeaders = {
        "Content-Type": "application/json"
      }
      webRegAsyncId = m.utils.sendAsyncRequest(webRegUrlGetCode, webRegPort, "webRegistration", "POST", true, getCodeBodyJson, getCodeHeaders)
    else 'start polling
      pollBody = {
        device_id: m.utils.deviceInfo.deviceId
        platform: "roku"
        activation_token: token
      }
      pollJsonBody = FormatJson(pollBody)
      pollHeaders = {
        "Content-Type": "application/json"
      }
      webRegAsyncId = m.utils.sendAsyncRequest(webRegUrlGetConfirmation, webRegPort, "webConfirmationPoll", "POST", true, pollJsonBody, pollHeaders)
      timeSpan.Mark()
    end if

    if (webRegAsyncId <> 0)
      codeRetryCount = 0
    
      while true
        'keep running through this loop(listening for events) - if we are polling and 2 seconds have passed since the last poll
        'jump out of the inner while loop and make another polling call.
        if timeSpan.TotalMilliseconds() > 2000 and haveRegistrationCode = true
          exit while
        end if

        msg = wait(1000, webRegPort) 'listen for messages for 1 sec (either remote control input message or message indicating a response to the previous async call)
        'make sure the message is from the most recent async request
        'there can be race conditions, especially when asking for a new registration code
        if msg <> invalid
          if type(msg) = "roUrlEvent" and msg.GetFailureReason() <> "Cancelled" 'got response from server for async call
            if haveRegistrationCode = false 'means the current response is to a get code request
              getCodeResponse = m.utils.getAsyncResponse(msg, 0)
              ' if getCodeResponse <> invalid and getCodeResponse.data <> invalid and getCodeResponse.data.len() > 0 and getCodeResponse.responseCode = 200
              if getCodeResponse <> invalid and getCodeResponse.id = webRegAsyncId
                if getCodeResponse.data <> invalid and getCodeResponse.data.len() > 0
                  codeResponse = ParseJson(getCodeResponse.data)
                  regCode = codeResponse.activation_code 'code for a user to enter at tubitv.com/roku to complete registration
                  'only store the first regId that is created - any subsquent calls to get activation code will send new regIds - we don't want those
                  'regIds are known as tokens on the server and web code'                 
                  if regId = invalid
                    regId = codeResponse.activation_token 'regId should be a UUID - to be passed back to server as an identifier when polling
                  end if
                  webRegScreen.SetRegistrationCode(regCode) 'add code to the screen
                  token = regId
                  identifier = regCode
                  haveRegistrationCode = true
                  exit while
                
                'did not successfully get a code from the server - so retry
                else
                  if codeRetryCount <= 3
                    webRegAsyncId = m.utils.sendAsyncRequest(webRegUrlGetCode, webRegPort, "webRegistration", "POST", true, getCodeBodyJson, getCodeHeaders)
                    
                    m.utils.trackEvent({
                      trackType: "registerFail"
                      value: "bad-server-response-code"
                      port: webRegPort
                    })

                    codeRetryCount = codeRetryCount + 1
                  else
                    m.utils.trackEvent({
                      trackType: "navigate"
                      value: "/home"
                      ctx: "/deviceregistration/code"
                      port: webRegPort
                    })

                    m.showMessage("We're sorry", "Could not get code from server.")
                    webRegScreen.Close()
                    return false
                  end if
                end if
              end if
            else if haveRegistrationCode = true 'means the current response is to a get confirmation request (polling)
              registrationResponse = m.utils.getAsyncResponse(msg, 0)
              ' if registrationResponse <> invalid and registrationResponse.data <> invalid and registrationResponse.data.len() > 0 and registrationResponse.responseCode = 200
              if registrationResponse <> invalid and registrationResponse.id = webRegAsyncId
                if registrationResponse.data <> invalid and registrationResponse.data.len() > 0
                  registrationInfo = ParseJson(registrationResponse.data)

                  if registrationInfo.status = "pending"
                    'we get a response with no confirmation that user registered - so we're still waiting
                    pollCounter = pollCounter + 2
                    'if we've polled for 5 minutes stop polling
                    if pollCounter > 600
                      m.showMessage("We're sorry", "After checking for 10 minutes, we did not see you register.")
                      
                      m.utils.trackEvent({
                        trackType: "registerFail"
                        value: "code-user-timeout"
                        port: webRegPort
                      })                    
                      
                      m.utils.trackEvent({
                        trackType: "navigate"
                        value: "/home"
                        ctx: "/deviceregistration/code"
                        port: webRegPort
                      })
  
                      webRegScreen.Close()
                      return false
                    end if
                  else if registrationInfo.status = "registered"
                    'we get a response confirming the user registered so let the user know and exit the page
                    'store auth info in registry
                    authInfo = m.utils.formatAuthInfoFromServer(registrationInfo)
                    m.utils.saveAuthInfo(authInfo)

                    m.utils.trackEvent({
                      trackType: "registerSuccess"
                      value: "/deviceregistration/code"
                      port: webRegPort
                    })

                    'create a message box with a button for closing the box
                    'when user closes box, webRegScreen should close and bring users to the gridScreen
                    m.showMessage("Thank you", "You are now registered as " + registrationInfo.first_name + " " + registrationInfo.last_name + ".")

                    m.utils.trackEvent({
                      trackType: "navigate"
                      value: "/home"
                      ctx: "/deviceregistration/code"
                      port: webRegPort
                    })

                    webRegScreen.Close()
                    return true
                  end if


                else
                  'we get an error
                  print "there was an error while polling for response from web registration"
                  m.showMessage("We're sorry", "Registration wasn't able to be completed.")

                  m.utils.trackEvent({
                    trackType: "registerFail"
                    value: "bad-server-response-poll"
                    port: webRegPort
                  })

                  m.utils.trackEvent({
                    trackType: "navigate"
                    value: "/home"
                    ctx: "/deviceregistration/code"
                    port: webRegPort
                  })

                  webRegScreen.Close()
                  return false
                end if

              else if registrationResponse <> invalid and registrationResponse.id <> webRegAsyncId
                'we got a response from a user tracking event, so no need to do anything
                print "registration screen user event response"
              end if

            else 'something went horribly wrong
              print "haveRegistrationCode is not an expected type"
              m.showMessage("We're sorry", "Registration wasn't able to be completed...")
              m.utils.trackEvent({
                trackType: "registerFail"
                value: "unknown-error"
                port: webRegPort
              })

              m.utils.trackEvent({
                trackType: "navigate"
                value: "/home"
                ctx: "/deviceregistration/code"
                port: webRegPort
              })

              webRegScreen.Close()
              return false
            end if
          else if type(msg) = "roCodeRegistrationScreenEvent"
            if msg.GetIndex() = 0 or msg.GetIndex() = 1 'back button or cancel button pressed
              m.utils.cancelAsyncRequest(webRegAsyncId)
              
              m.utils.trackEvent({
                trackType: "registerFail"
                value: "user-cancel"
                port: webRegPort
              })

              m.utils.trackEvent({
                trackType: "navigate"
                value: "/home"
                ctx: "/deviceregistration/code"
                port: webRegPort
              })
              
              webRegScreen.Close()
              return false
            else if msg.GetIndex() = 2 'request for new code
              'only honor request for new codes if we are not in the process of getting a new code
              'if we try to get a new code, while waiting for the server to respond, the server gets confused and returns an error
              if haveRegistrationCode = true
                print "new web registration code was requested"
                haveRegistrationCode = false
                webRegScreen.SetRegistrationCode("Retrieving...")
                m.utils.cancelAsyncRequest(webRegAsyncId) 'get rid of any pending async get request before making another
                exit while
              end if
            else if msg.isScreenClosed() 'don't think this is necessary
              ' return false
            end if
          end if
        end if
      end while
    end if
  end while

end Function