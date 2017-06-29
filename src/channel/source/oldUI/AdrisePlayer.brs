' --------------------------------------------------------
'  AdrisePlayer
'  appId: string, required.
'  pubId: string, required.  Will be overwritten by pubId in video, if
'     it exists
'  background: string, optional, color of background, defaults to empty string
'  fontColor: string, optional, color of text, defaults to empty string
'  loadingUrl: string, optional, filename of loading image, defaults to empty string
'  cp: contentProvider object
'THIS IS CURRENTLY NOT USED... AdrisePlayerInternal is called directly from AdriseApp
function AdrisePlayer (appId as String, pubId as String, background = "" as String, fontColor = "" as String, loadingUrl = "" as String, loadingBackground = "")
    return AdrisePlayerInternal ({
      appId: appId
      pubId : pubId
      background : background
      fontColor : fontColor
      loadingUrl : loadingUrl
      loadingBackground: loadingBackground
      subscription: false
      contentType: "hls"
      pingFrequency: 10
      utils: AdriseUtils(appId)
    })
end function

function AdrisePlayerInternal(config)
  displaySize = config.utils.deviceInfo.displaySize
  if config.utils.deviceInfo.displayType = "HDTV"
    definition = "hd"
  else
    definition = "sd"
  end if

  version = config.utils.deviceInfo.firmwareVersion
  major = Int(version)
  if major = 3
    contentType = "mp4"
  else
    contentType = "hls"
  end if

  'a single message port used whenever a video or ad is playing
  'in order to make sure we delete async url objects, we need to make sure we always use this port
  playerPort = CreateObject("roMessagePort")

  return {
    ' failCount : 0
    appId: config.appId
    pubId : config.pubId
    background : config.background
    fontColor : config.fontColor
    loadingUrl : config.loadingUrl
    loadingBackground: config.loadingBackground
    subscription: config.subscription
    contentType: contentType
    displaySize : displaySize
    definition : definition
    pingFrequency: config.pingFrequency
    playerPort: playerPort
    resumePlayAdsList: invalid
    useCustomPlayer: true

    ' ads module
    ads : AdriseAds(config.utils, playerPort)

    utils: config.utils

    'stores the request ids everytime we make a call to add a new position for previously viewed/history content
    previouslyViewedReqIds: {}

    ' public methods
    playVideo: AdrisePlayer_playVideo
    getPubId: function()
        return m.pubId
      end function

    ' private methods
    showSpanOfContentVideoNew: AdrisePlayer_showSpanOfContentVideoNew
    paintToCanvas: AdrisePlayer_paintToCanvas
    getTransportRects: AdrisePlayer_getTransportRects
    getPauseRect: AdrisePlayer_getPauseRect
    getTransportTime: AdrisePlayer_getTransportTime
    handleVideoFailure: AdrisePlayer_handleVideoFailure
    savePreviouslyViewedUpdate: AdrisePlayer_savePreviouslyViewedUpdate
    cancelInstantReplay: AdrisePlayer_cancelInstantReplay
  }
end function

' --------------------------------------------------------
'  .playVideo(episode as Object, contentId as String = invalid))
'   play a whole video, with ads
'
'    contentId is optional
'    if not provided, episode should have a member "adrise_contentId"
'
'   Return value:
'    COMPLETED means it completed (indicating the caller can go
'      ahead play the next video automatically)
'    CLOSED means it was stopped explicitly
' --------------------------------------------------------
function AdrisePlayer_playVideo(episode as Object)

  'updates the episode with a new url right before a video is about to play
  'this should prevent a user from running up against an expired DRM token in most cases
  episode = GetGlobalAA().app.cp.getUpdatedUrlForEpisode(episode)

  episode.SwitchingStrategy="full-adaptation"

  if m.definition = "sd"
      episode.isHD = false
      episode.hdBranded = false
      if episode.streams <> invalid
        for each stream in episode.streams
          stream.quality = false
        end for
      end if
  end if

  m.ads.reset()
  episode.nowPos = 0
  m.lastPingTime = 0
  m.shouldResetPing = false


  'get the state of the app - ie. where is the player coming from? linear TV? bookmarks? previously viewed?
  m.linearTvOn = GetGlobalAA().app.linearTV.linearTvOn

  'send tracking event that the video started playing
  vidOrSeries = "video"
  if episode.isParentSeries = true
    vidOrSeries = "series"
  end if

  if episode.playStart <> invalid
    episode.nowPos = episode.playStart
  end if

  deviceInfo = CreateObject("roDeviceInfo")
  globalCaptions = deviceInfo.GetCaptionsMode()

  m.utils.trackEvent({
    trackType: "videoPlay"
    value: episode.id
    ctx: episode.nowPos
    extraCtx: {
      subtitles: globalCaptions = "On"
      livetv: m.linearTvOn
    }
    port: m.playerPort
  })

  ' set up a video ad
  canvas = CreateObject("roImageCanvas")
  canvas.SetMessagePort(m.playerPort)
  canvas.SetLayer(1, {color: "#000000"})
  canvas.Show()

  if m.subscription = false
    if episode.pubId <> invalid and episode.pubId <> ""
      m.pubId = episode.pubId
    end if

    'make a synchrynous call to get cuepoints, if any
    cuepoints = m.ads.getCuepoints(episode)

    'otherwise if the user is starting from beginning or resuming on a cue point, show ads
    'attempt to get list of ads and play them for preroll
    if m.ads.isRokuAdFrameworkOn = true
      m.ads.getAdsListViaRoku(episode, m)
      status = m.ads.showCommercialBreakViaRoku(canvas, m)
    else
      videoAdsList = m.ads.getAdsList(episode, m)
      status = m.ads.showCommercialBreak(canvas, videoAdsList, m)
    end if

    if status = "CLOSED"
      canvas.close()
      return "CLOSED"
    end if
  end if


  ' if the pre-roll ad completed without the user closing it explicitly,
  ' (or there was no pre-roll because it is a subscription app), play the content
  while true

    m.utils.trackEvent({
      trackType: "resumeAfterAds"
      value: episode.nowPos
      ctx: episode.id
      port: m.playerPort
    })
    
    status = m.showSpanOfContentVideoNew(episode)

    while status = "FAILED"
      failHandlerStatus = m.handleVideoFailure(episode)
      if failHandlerStatus = "CLOSE"
        canvas.close()
        return "CLOSE"
      else if failHandlerStatus = "IGNORE"
        exit while
      else
        status = failHandlerStatus
        exit while
      end if
    end while

    'if STOPFORCOMMERCIAL we already have a validated cached ads list, so run the ads in the cache
    if status = "STOPFORCOMMERCIAL"
      Sleep(500) ' to ensure proper playback of the midroll

      canvas.SetMessagePort(m.playerPort)
      canvas.SetLayer(1, {color: "#000000"})
      canvas.Show()

      'get list of ads and play them
      if m.ads.isRokuAdFrameworkOn = true
        status = m.ads.showCommercialBreakViaRoku(canvas, m)
      else
        videoAdsList = m.ads.getCachedAdsList(episode)
        status = m.ads.showCommercialBreak(canvas, videoAdsList, m)
      end if

      if status = "CLOSED"
        canvas.close()
        return "CLOSED"
      end if

    'if RESUMEPLAY, means we are resuming play after pausing or seeking/scrubbing
    'we have already made a call to get a list of ads to play and stored them in m.resumePlayAdsList, so just run them
    else if status = "RESUMEPLAY"
      if m.ads.isRokuAdFrameworkOn = true
        status = m.ads.showCommercialBreakViaRoku(canvas, m)
      else
        status = m.ads.showCommercialBreak(canvas, m.resumePlayAdsList, m)
      end if

      if status = "CLOSED"
        canvas.close()
        return "CLOSED"
      end if

    else
      canvas.close()
      return status
    end if
  end while
end function

' --------------------------------------------------------
' .showSpanOfContentVideoNew(episode As Object)
'   shows a span of video content (i.e. not the ad)
'
' starts playing video (at episode.PlayStart, in seconds)
'
' returns when the next ad break occurs, based on
'   m.ads.commercialBreakArray
'
' Return value:
'   COMPLETED means it played to the end (or is not a valid episode)
'   STOPFORCOMMERCIAL means it stopped so we can play the next commercial set
'   CLOSED means screen was explicitly closed normally
'   FAILED means a video error occurred
'
' Side effects:
'  Will write to, or delete, the registry entry associated with this video to keep
'   track of resume time (using episode.adrise_contentId as the registry key)
'  Calls m.ads.checkForCommercialBreak() to determine if we have to play commercial
'   (which can reads and can modify m.ads.commercialBreakArray,
'   and which will set episode.playStart so the video will start at the
'   correct start point following the commercial)
' --------------------------------------------------------
function AdrisePlayer_showSpanOfContentVideoNew(episode As Object)
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

function AdrisePlayer_paintToCanvas(progressPercent, playerStates, episode)

  'set the folders for the transport buttons - assume HD and test for SD
  display = "720"
  if playerStates.displayWidth = 720
    display = "480"
  end if

  'each layer on the screen is represented by an array - we will iterate over all the layers to add them to the screen
  'if you need more layers, add more arrays to the layers array
  layers = [[], [], []]

  'let the user know the video is loading
  if progressPercent < 100  'Video is currently buffering
    'adds the black background to the text
    layers[0].Push({
        Color: "#FF000000"
        TargetRect: m.canvas.GetCanvasRect()
    })
    'adds the load progress text to the screen
    if episode.isparentseries <> invalid and episode.isparentseries = true and episode.parentTitle <> invalid
      titleToShow = episode.parentTitle + " - " + episode.title
    else
      titleToShow = episode.title
    end if

    layers[1].Push({
        Text: "Loading..." + progressPercent.tostr() + "% " + chr(10) + titleToShow
        TargetRect: m.canvas.GetCanvasRect()
    })

  'if the transport overlay is supposed to be showing, build it and show it  
  else if playerStates.isTransportShowing = true
    scrubText = str(playerStates.scrubMultiplier) + "x"

    'semi transparent black overlay over the video
    layers[0].push({
      Color: "#27000000" 'approximately 85% transparent black overlay #27000000 #80000000 = 50% transparency
      TargetRect: m.canvas.GetCanvasRect()
      CompositionMode: "Source"
    })
    'empty position bar at the bottom of the screen representing full duration of video
    layers[1].push({
      Color: "#FFFFFFFF"
      TargetRect: m.getTransportRects(m.canvas.GetCanvasRect(), playerStates).outer
    })
    'filled position bar at the bottom of the screen representing current position of video relative to duration
    layers[2].push({
      Color: "#FFFF9934"
      TargetRect: m.getTransportRects(m.canvas.GetCanvasRect(), playerStates).inner
    })

    'the current position in the bottom left of the screen
    layers[1].push({
      Text: m.getTransportTime(playerStates.nowPos)
      TextAttrs: {
        Color: "#FFFFFFFF"
        HAlign: "Left"
        VAlign: "Top"
        Font: "Small"
      }
      TargetRect: m.getTransportRects(m.canvas.GetCanvasRect(), playerStates).nowPos
    })

    'the total duration of the content in the bottom left of the screen
    layers[1].push({
      Text: " / " + m.getTransportTime(episode.length)
      TextAttrs: {
        Color: "#FFFFFFFF"
        HAlign: "Left"
        VAlign: "Top"
        Font: "Small"
      }
      TargetRect: m.getTransportRects(m.canvas.GetCanvasRect(), playerStates).duration
    })

    'the title of the content above the transport bar
    layers[1].push({
      Text: episode.title
      TextAttrs: {
        Color: "#FFFFFFFF"
        HAlign: "Left"
        VAlign: "Top"
        ' Font: "Large"
      }
      TargetRect: m.getTransportRects(m.canvas.GetCanvasRect(), playerStates).title
    })

    'the rewind button below the transport bar
    rewindUrl = "pkg:/images/oldUI/" + display + "/transport/rw.png"    'looks like pkg:/720/transport/rw.png
    if playerStates.scrubAmount < 0
      rewindUrl = "pkg:/images/oldUI/" + display + "/transport/rw_orange.png"
    end if
    layers[1].Push({
      Url: rewindUrl
      TargetRect: m.getTransportRects(m.canvas.GetCanvasRect(), playerStates).rewind
    })

    'the fast forward button below the transport bar
    forwardUrl = "pkg:/images/oldUI/" + display + "/transport/ff.png"
    if playerStates.scrubAmount > 0
      forwardUrl = "pkg:/images/oldUI/" + display + "/transport/ff_orange.png"
    end if
    layers[1].Push({
      Url: forwardUrl
      TargetRect: m.getTransportRects(m.canvas.GetCanvasRect(), playerStates).fastforward
    })

    'the star button below the transport bar
    layers[1].Push({
      Url: "pkg:/images/oldUI/" + display + "/transport/star.png"
      TargetRect: m.getTransportRects(m.canvas.GetCanvasRect(), playerStates).star
    })

    'if we are not paused (no scrubbing, no pause) show the pause button on the transport menu
    if playerStates.isPaused = false
      'the pause button below the transport bar
      layers[1].Push({
        Url: "pkg:/images/oldUI/" + display + "/transport/pause_small.png"
        TargetRect: m.getTransportRects(m.canvas.GetCanvasRect(), playerStates).pause
      }) 
    
    'if we are paused, show the play button on the transport menu
    else
      'the play button below the transport bar
      layers[1].Push({
        Url: "pkg:/images/oldUI/" + display + "/transport/play.png"
        TargetRect: m.getTransportRects(m.canvas.GetCanvasRect(), playerStates).play
      })
    end if

    'if we are scrubbing show the scrub speed
    if playerStates.isScrubbing = true and playerStates.scrubMultiplier <> invalid
      ' speed at which we are scrubbing (eg. 4x, 8x, etc.)
      layers[1].push({
        Text: scrubText
        TextAttrs: {font: "huge"}
        TargetRect: m.canvas.GetCanvasRect()
      })

    'if not scrubbing then we must be just paused
    else if playerStates.isScrubbing = false and playerStates.isPaused = true
      'add the paused symbol to the screen
      layers[1].Push({
        ' Url: "pkg:/720/transport/pause_big_orange.png"
        Url: "pkg:/images/oldUI/" + display + "/transport/pause_big.png"
        TargetRect: m.getPauseRect(m.canvas.GetCanvasRect())
      })
    end if

  'the video is playing
  else
    'add the video to the screen. technically there is a fully transparent overlay over the video.'
    layers[0].Push({
      Color: "#00000000"
      TargetRect: m.canvas.GetCanvasRect()
      CompositionMode: "Source"
    })
  end if

  for i=0 to layers.count()-1 step 1
    m.canvas.SetLayer(i+1, layers[i])
  end for
end function

function AdrisePlayer_getTransportRects(canvasRect, playerStates)
  'set the width and height of the transport bar as percentages fo the screen width and height
  transportWidthPercent = 0.85
  transportHeightPercent = 0.013

  'sets the dimensions and placement of the white background for the progress bar
  outerX = int((canvasRect.w / 2) - (transportWidthPercent * canvasRect.w /2))
  outerY = int(0.85 * canvasRect.h)
  outerW = int(transportWidthPercent * canvasRect.w)
  outerH = int(transportHeightPercent * canvasRect.h)

  fullDurationWidth = int(transportWidthPercent * canvasRect.w)

  'sets the dimensions and placement of the orange progress bar
  innerX = outerX
  innerY = outerY
  innerW = int(playerStates.scrubPercent * fullDurationWidth)
  innerH = outerH

  'set a minimum width for innerW to 1. If innerW = 0, the orange bar seems to be infinitely long
  if innerW = 0
    innerW = 1
  end if

  'timeBoxPercent is a percentage compared to the width of the transport bar
  nowPosBoxPercent = 0.09
  durationBoxPercent = 0.2
  
  'sets the dimension and placement of the timer in the bottom left area of the screen
  nowPosX = outerX
  nowPosY = outerY + int(0.05 * canvasRect.h)
  nowPosW = int(nowPosBoxPercent * outerW)
  nowPosH = 3 * outerH

  'sets the dimension and placement of the total duration of the video
  'this is done separately from the timer because as the timer changes the duration would bounce around due to the different widths of the number characters
  durationX = outerX + nowPosW + int(0.005 * outerW)
  durationY = nowPosY
  durationW = int(durationBoxPercent * outerW)
  durationH = nowPosH


  'sets the dimension and placement of the title of the video
  titleX = outerX
  titleY = outerY - int(0.08 * canvasRect.h)
  titleW = outerW
  titleH = 3 * outerH

  'all buttons are the same height so lets make a variable
  buttonHeight = 0.0403

  'sets the percentage from the edges of the transport bar that the fast forward and rewind buttons will be placed
  arrowPercent = 0.33

  'sets the dimension and placement of rewind arrows - expect a file with dimenions 39 x 29 px
  rewindX = outerX + int(arrowPercent * outerW)
  rewindY = nowPosY
  rewindW = int(0.030 * canvasRect.w)
  rewindH = int(buttonHeight * canvasRect.h)

  'sets the dimension and placement of fast forward arrows - expect a file with dimenions 39 x 29 px
  fastforwardX = outerX + int((1 - arrowPercent) * outerW) - int(0.04 * canvasRect.w)
  fastforwardY = nowPosY
  fastforwardW = int(0.030 * canvasRect.w)
  fastforwardH = int(buttonHeight * canvasRect.h)

  'sets the dimension and placement of the star button - expect a file with dimensions 27 X 29
  starX = outerX + outerW - int(0.026 * canvasRect.w)
  starY = nowPosY
  starW = int(0.021 * canvasRect.w)
  starH = int(buttonHeight * canvasRect.h)

  'sets the dimension and placement of the play button - expect a file with dimensions 24 x 29
  playX = int((canvasRect.w - (0.023 * canvasRect.w)) / 2)
  playY = nowPosY
  playW = int(0.019 * canvasRect.w)
  playH = int(buttonHeight * canvasRect.h)

  'sets the dimension and placement of the play button - expect a file with dimensions 30 x 29
  pauseX = int((canvasRect.w - (0.028 * canvasRect.w)) / 2)
  pauseY = nowPosY
  pauseW = int(0.023 * canvasRect.w)
  pauseH = int(buttonHeight * canvasRect.h)

  'make any changes necessary for SD environment
  if playerStates.displayWidth = 720
    buttonHeight = 0.0417

    durationX = outerX + nowPosW + int(0.030 * outerW)
    
    rewindW = int(0.035 * canvasRect.w)
    rewindH = int(buttonHeight * canvasRect.h)

    fastforwardW = int(0.035 * canvasRect.w)
    fastforwardH = int(buttonHeight * canvasRect.h)

    starW = int(0.025 * canvasRect.w)
    starH = int(buttonHeight * canvasRect.h)

    playW = int(0.022 * canvasRect.w)
    playH = int(buttonHeight * canvasRect.h)

    pauseW = int(0.022 * canvasRect.w)
    pauseH = int(buttonHeight * canvasRect.h)
  end if



  return {
    outer: {
      x: outerX
      y: outerY
      w: outerW
      h: outerH
    }
    inner: {
      x: innerX
      y: innerY
      w: innerW
      h: innerH
    }
    nowPos: {
      x: nowPosX
      y: nowPosY
      w: nowPosW
      h: nowPosH
    }
    duration: {
      x: durationX
      y: durationY
      w: durationW
      h: durationH
    }
    title: {
      x: titleX
      y: titleY
      w: titleW
      h: titleH
    }
    rewind: {
      x: rewindX
      y: rewindY
      w: rewindW
      h: rewindH
    }
    fastforward: {
      x: fastforwardX
      y: fastforwardY
      w: fastforwardW
      h: fastforwardH
    }
    star: {
      x: starX
      y: starY
      w: starW
      h: starH
    }    
    play: {
      x: playX
      y: playY
      w: playW
      h: playH
    }
    pause: {
      x: pauseX
      y: pauseY
      w: pauseW
      h: pauseH
    }    
  }
end function

function AdrisePlayer_getPauseRect(canvasRect)
  'expect an image that is exactly 55 x 83 pixels
  'using percentages to render image - will render correctly on 1280w x 720h screens

  return {
    x: int(0.479 * canvasRect.w)
    y: int(0.442 * canvasRect.h)
    w: int(0.043 * canvasRect.w)
    h: int(0.115 * canvasRect.h)
  }
end function


'builds the string that will display the time under the transport bar when a video is paused
function AdrisePlayer_getTransportTime(seconds)

  'helper function to create a string that looks like 00:32:17 from 1937 seconds
  'expects seconds to be an integer, not a string
  secondsToHours = function(seconds)
    
    'helper function to prepend 0s if needed
    prependZeros = function(str)
      while str.len() < 2
        str = "0" + str
      end while

      return str
    end function

    'get the number of hours, minutes, and remaining seconds
    hours = int(seconds/3600)
    minutes = int((seconds - hours * 3600) / 60)
    seconds = int(seconds - hours * 3600 - minutes * 60)

    'turn the values from above into strings
    hours = prependZeros(hours.toStr())
    minutes = prependZeros(minutes.toStr())
    seconds = prependZeros(seconds.toStr())

    return hours + ":" + minutes + ":" + seconds
  end function

  'should return string in the format of 00:12:14
  return secondsToHours(seconds)

end function

'------------------------------------------------------------------
function AdrisePlayer_handleVideoFailure(episode)
  dialog = CreateObject("roMessageDialog")
  dialog.SetMessagePort(m.playerPort)

  dialog.SetText("Video playback failed.")
  dialog.SetText("Would you like to try resuming?")

  dialog.SetText("If problem persists, please visit tubitv.com/support")
  dialog.AddButton(1, "Try resuming")
  dialog.AddButton(2, "Ignore error")
  dialog.AddButton(3, "Exit video")
  dialog.EnableBackButton(true)
  dialog.Show()

  episode = GetGlobalAA().app.cp.getUpdatedUrlForEpisode(episode)

  m.utils.log.warn(m.playerPort, "clientWarn", "playback-message-shown", "User was shown the video playback failed pop up message")

  while true
    dlgMsg = wait(0, m.playerPort)

    'handle any async responses (usually responses to playProgress and other user events,
    'but can be a response to outstanding ad pixel calls), unlikely to occur here, but just in case
    'respObj is not used anywhere here since we don't care about user event responses or ad pixel responses
    'but calling getAsyncResponse is necessary to prevent memory leaks, so don't remove!!!
    if type(dlgMsg) = "roUrlEvent"
      respObj = m.utils.getAsyncResponse(dlgMsg, 0)
    end if

    if type(dlgMsg) = "roMessageDialogEvent"
      if dlgMsg.isButtonPressed()
        button = dlgMsg.GetIndex()
        if (button = 1)
          episode.playStart = episode.nowPos
          if m.useCustomPlayer = false
            status = m.showSpanOfContentVideo(episode)
          else
            status = m.showSpanOfContentVideoNew(episode)
          end if
          return status
        else if (button = 2)
          return "IGNORE"
        else if (button = 3)
          return "CLOSE"
        end if
      end if

      if dlgMsg.isScreenClosed()
        return "IGNORE"
      end if
    end if
  end while
  return ""
end function

function AdrisePlayer_savePreviouslyViewedUpdate(episode, nowPos)
  settings = m.utils.getSettings()
  if m.cp = invalid
    m.cp = GetGlobalAA().app.cp
  end if

  'set the appropriate info based on if it's a movie or episode
  parentId = invalid
  localUpdateId = episode.id
  contentType = "movie"
  userPlaylistsStore = "userPlaylistVideos"
  contentToStore = episode

  if episode.isParentSeries = true
    parentId = episode.parentId
    localUpdateId = parentId
    contentType = "episode"
    userPlaylistsStore = "userPlaylistSeries"
    contentToStore = m.cp.getContentFromLocalPlaylists(parentId, "series")
  end if


  'add the content to our local stores if it doesn't already exist
  if m.cp[userPlaylistsStore][localUpdateId] = invalid
    m.cp[userPlaylistsStore][localUpdateId] = contentToStore
  end if

  stopLoop = false
  'save the nowPos on our local stores so we can reference later
  if episode.isParentSeries = true
    'update the nowPos for the correct episode in the series
    parentInStore = m.cp[userPlaylistsStore][localUpdateId]
    if parentInStore <> invalid and parentInStore.playlist <> invalid and parentInStore.playlist.episodes <> invalid and parentInStore.playlist.episodes.count() > 0

      for i=0 to parentInStore.playlist.episodes.count()-1 step 1
        season = parentInStore.playlist.episodes[i]
        if season.playlist <> invalid and season.playlist.episodes <> invalid and season.playlist.episodes.count() > 0

          for j=0 to season.playlist.episodes.count()-1 step 1
            child = season.playlist.episodes[j]
            if child.id = episode.id
              'update the new previously viewed/history info locally
              child.nowPos = nowPos
              stopLoop = true
              exit for
            end if
          end for
        end if

        if stopLoop = true
          exit for
        end if
      end for
    end if

  else
    'update the nowPos for the current video
    m.cp[userPlaylistsStore][localUpdateId].nowPos = nowPos
  end if
  
  'only do the following if the user is logged in
  authInfo = m.utils.getAuthInfo()
  if authInfo.accessToken <> invalid
  
    'send the newest nowPos to the server. we will listen for the response in the main player port event loop
    addPreviouslyViewedReqId = m.utils.updatePreviouslyViewed(episode.id, parentId, nowPos, "add", contentType, m.playerPort)
    if addPreviouslyViewedReqId <> invalid
      m.previouslyViewedReqIds[addPreviouslyViewedReqId.toStr()] = true
    end if
    
    'updates both video and series
    m.cp[userPlaylistsStore][localUpdateId].isPreviouslyViewed = true

    'only add the content to the previouslyViewed episodes array if we've loaded the previously viewed category on the gridscreen already
    'this prevents the content from appearing twice in the case of deeplinking
    if m.cp.userPlaylists[settings.previouslyViewedRegistry] <> invalid and m.cp.userPlaylists[settings.previouslyViewedRegistry].isLoaded = true
      'add to the previouslyViewed episodes array so it will be included in the category on the gridscreen
      count = 0
      if m.cp.userPlaylists[settings.previouslyViewedRegistry] <> invalid and m.cp.userPlaylists[settings.previouslyViewedRegistry].episodes <> invalid
        for each previousEpisode in m.cp.userPlaylists[settings.previouslyViewedRegistry].episodes
          if previousEpisode <> invalid and previousEpisode.id = localUpdateId
            m.cp.userPlaylists[settings.previouslyViewedRegistry].episodes.delete(count) 'since we want to move it to the front of the list
            exit for
          end if
          count = count + 1
        end for
        m.cp.userPlaylists[settings.previouslyViewedRegistry].episodes.unshift(m.cp[userPlaylistsStore][localUpdateId])
      end if
    end if
  end if

end function


Function AdrisePlayer_cancelInstantReplay(playerStates, captions)
  'if the video was in an instant replay state, cancel the replay
  if playerStates.replayEnd > 0
    playerStates.replayEnd = 0

    ' replayEnd was only set if Instant replay was
    deviceInfo = CreateObject("roDeviceInfo")
    deviceInfo.SetCaptionMode("Instant replay")
    captions.showSubtitle(false)
  end if
End Function
