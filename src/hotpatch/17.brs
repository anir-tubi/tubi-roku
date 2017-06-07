print "Hot Patch 17"

m.global.utils.constants.settings.allowAfterHours = true

' m.global.utils.constants.idsToLog = {
'   "YY00G1976937": true
' }

'correct the client version sent to the active tracking event when using remote components
if m.global.utils.constants.externalConfig.info.remote_components = 1
  m.global.utils.constants.deviceInfo.clientVersion = m.global.utils.constants.deviceInfo.clientVersion.Replace("local", "remote")
end if

'determine the appropriate remote components to use if server remote config says to allow On Now
print "hotpatch on now config = "; m.global.utils.constants.externalConfig.info.roku_onnow
if m.global.utils.constants.externalConfig.info.roku_onnow = 1
  m.global.utils.constants.settings.remoteComponentsUrl = "http://cdn.adrise.com/hotpatches/roku/components/tubitv_remote_components_2_2_7.pkg"
  ' m.global.utils.constants.settings.remoteComponentsUrl = "http://192.168.1.180:8080/rokuHotpatches/components/tubitv_remote_components_2_2_6.pkg"

else
  'need to run the old remote components - without on now
  m.global.utils.constants.settings.remoteComponentsUrl = "http://cdn.adrise.com/hotpatches/roku/components/tubitv_remote_components.pkg"

  'set up all of tubi player
  playerPort = CreateObject("roMessagePort")
  m.global.player = {
    utils: m.global.utils
    constants: m.global.utils.constants
    pingFrequency: m.global.utils.constants.player.pingFrequency
    playerPort: playerPort
    playerRequestQueue: m.global.utils.requestQueue.create(playerPort)
    resumePlayAdsList: invalid

    ' ads module
    ads : m.global.adShim.ads

    'stores the request ids everytime we make a call to add a new position for previously viewed/history content
    previouslyViewedReqIds: {}
  }



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
m.global.player.playVideo = Function(episode as Object)

  'updates the episode with a new url right before a video is about to play
  'this should prevent a user from running up against an expired DRM token in most cases
  ' episode = GetGlobalAA().app.cp.getUpdatedUrlForEpisode(episode)

  episode.SwitchingStrategy="full-adaptation"

  if m.constants.deviceInfo.definition = "sd"
      episode.isHD = false
      episode.hdBranded = false
      if episode.streams <> invalid
        for each stream in episode.streams
          stream.quality = false
        end for
      end if
  end if

  m.ads.reset()
  m.lastPingTime = 0
  m.shouldResetPing = false


  'get the state of the app - ie. where is the player coming from? linear TV? bookmarks? previously viewed?
  ' m.linearTvOn = GetGlobalAA().app.linearTV.linearTvOn

  'send tracking event that the video started playing
  vidOrSeries = "video"
  if episode.isParentSeries = true
    vidOrSeries = "series"
  end if

  if episode.nowPos <> invalid
    episode.playStart = episode.nowPos
  end if

  deviceInfo = CreateObject("roDeviceInfo")
  globalCaptions = deviceInfo.GetCaptionsMode()

  m.utils.tracking.trackUserEvent({
    trackType: "videoPlay"
    value: episode.id
    ctx: episode.nowPos
    extraCtx: {
      subtitles: globalCaptions = "On"
      livetv: m.linearTvOn
    }
    requestQ: m.playerRequestQueue
  })

  ' set up a video ad
  canvas = CreateObject("roImageCanvas")
  canvas.SetMessagePort(m.playerPort)
  canvas.SetLayer(1, {color: "#000000"})
  canvas.Show()

  'make a synchrynous call to get cuepoints, if any
  cuepoints = m.ads.getCuepoints(episode)

  'otherwise if the user is starting from beginning or resuming on a cue point, show ads
  'attempt to get list of ads and play them for preroll
  if m.ads.isRokuAdFrameworkOn = true
    m.ads.getAdsListViaRoku(episode)
    status = m.ads.showCommercialBreakViaRoku(canvas)
  else
    videoAdsList = m.ads.getAdsList(episode)
    status = m.ads.showCommercialBreak(canvas, videoAdsList) 'videoAdsList can be invalid
  end if

  if status = m.constants.player.playerResults.closed
    canvas.close()
    return m.constants.player.playerResults.closed
  end if


  ' if the pre-roll ad completed without the user closing it explicitly,
  ' (or there was no pre-roll because it is a subscription app), play the content
  while true

    m.utils.tracking.trackUserEvent({
      trackType: "resumeAfterAds"
      value: episode.nowPos
      ctx: episode.id
      requestQ: m.playerRequestQueue
    })
    
    status = m.showSpanOfContentVideoNew(episode)

    ' return to scene graph if player failed
    if status = m.constants.player.playerResults.failed
      canvas.close()
      return status
    end if

    'if STOPFORCOMMERCIAL we already have a validated cached ads list, so run the ads in the cache
    if status = m.constants.player.playerResults.commercial
      Sleep(500) ' to ensure proper playback of the midroll

      canvas.SetMessagePort(m.playerPort)
      canvas.SetLayer(1, {color: "#000000"})
      canvas.Show()

      'get list of ads and play them
      if m.ads.isRokuAdFrameworkOn = true
        status = m.ads.showCommercialBreakViaRoku(canvas)
      else
        videoAdsList = m.ads.getCachedAdsList(episode)
        status = m.ads.showCommercialBreak(canvas, videoAdsList)
      end if

      if status = m.constants.player.playerResults.closed
        canvas.close()
        return m.constants.player.playerResults.closed
      end if

    'if RESUMEPLAY, means we are resuming play after pausing or seeking/scrubbing
    'we have already made a call to get a list of ads to play and stored them in m.resumePlayAdsList, so just run them
    else if status = m.constants.player.playerResults.resumePlay
      if m.ads.isRokuAdFrameworkOn = true
        status = m.ads.showCommercialBreakViaRoku(canvas)
      else
        status = m.ads.showCommercialBreak(canvas, m.resumePlayAdsList)
      end if

      if status = m.constants.player.playerResults.closed
        canvas.close()
        return status
      end if

    else
      canvas.close()
      return status
    end if
  end while
End Function

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
m.global.player.showSpanOfContentVideoNew = Function(episode As Object)
  if type(episode) <> "roAssociativeArray"
    print "invalid data passed to showVideoScreen"
    return m.constants.player.playerResults.completed
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

  'show the subtitles if the global captions setting says we should
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
    displayWidth: m.constants.deviceInfo.displayWidth
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

    m.global.utils.tracking.trackUserEvent({
      trackType: "playProgress"
      ctx: episode.id
      value: playerStates.nowPos
      extraCtx: {interval: playerStates.nowPos - m.global.player.lastPingTime}
      requestQ: m.global.player.playerRequestQueue
    })
  end function

  'globally scoped function to do the necessary tasks related to end of scrubbing/re-start video
  endScrub = function(player, playerStates, episode, captions)
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

    m.global.player.shouldResetPing = true

    m.global.utils.tracking.trackUserEvent({
      trackType: "seek"
      ctx: episode.id
      value: playerStates.nowPos
      requestQ: m.global.player.playerRequestQueue
    })
    
    'when resuming to play after fast forward, we need to ask the ad server if there are any ads
    'getResumingPlayAds will store ads in either m.global.player.resumePlayAdsList or m.global.player.ads.allAdUnitsList
    'depending on if RAF is off or on
    if playerStates.isInHopMode = false
      if playerStates.nowPos > playerStates.nowPosAtScrub
        shouldBreak = m.global.player.ads.getResumingPlayAds(episode, m.global.player)
        if shouldBreak = true
          return true
        end if
      end if
    end if

    if playerStates.isInHopMode = false
      player.Seek(playerStates.scrubToPoint * 1000)
      playerStates.isTransportShowing = false
      playerStates.isPaused = false
      playerStates.nowPosAtScrub = 0
    end if

    playerStates.isScrubbing = false
    playerStates.scrubAmount = 0
    playerStates.totalScrubTime = 0
    playerStates.scrubToPoint = 0

    deviceInfo = CreateObject("roDeviceInfo")
    globalCaptions = deviceInfo.GetCaptionsMode()
    if globalCaptions = "On"
      captions.showSubtitle(true)
    else
      captions.showSubtitle(false)
    end if

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

        errorMsg = "video with id: " + episode.id + "failed. Error Index " + msg.getIndex().toStr() +  " : " + msg.getMessage()
        m.utils.log.error(errorMsg, "videoPlayback", "video_segment_failure", m.playerRequestQueue)
        m.canvas.close()
        return m.constants.player.playerResults.failed
      end if

      'log any re-buffers that user might encounter
      if msg.isStreamStarted()
        if msg.getInfo().isUnderrun = true
          warningMsg = "Video buffered mid stream. Segment Url: " + msg.getInfo().url + " Stream Bitrate: " + msg.getInfo().streamBitrate.toStr() + " Measured Bitrate: " + msg.getInfo().measuredBitrate.toStr()
          m.utils.log.warn(warningMsg, "videoBuffer", "video_buffer", m.playerRequestQueue)
        end if
      end if

      'if event is that the video content has reached the end
      if msg.isFullResult()
        m.canvas.close()
        return m.constants.player.playerResults.completed
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
        breakPos = m.ads.checkForCommercialBreak(playerStates.nowPos, episode)
        if breakPos <> -1
          episode.nowPos = breakPos
          episode.playStart = breakPos
          list = m.ads.getCachedAdsList(episode)
          if list <> invalid
            'save the last position to memory
            m.savePreviouslyViewedUpdate(episode, playerStates.nowPos)

            'tell the video player we are stopping and going to play a set of ads
            m.canvas.close()
            return m.constants.player.playerResults.commercial
          end if
        end if

        'sends a play progress tracking event if enough time has elapsed
        if playerStates.nowPos >= m.lastPingTime + m.pingFrequency
          playProgressEvent = {
            trackType: "playProgress"
            ctx: episode.id
            value: playerStates.nowPos
            requestQ: m.playerRequestQueue
          }

          if m.linearTvOn = true
            playProgressEvent.extraCtx = {
              URI: "home/livetv/roku"
            }
          end if

          m.utils.tracking.trackUserEvent(playProgressEvent)

          m.lastPingTime = playerStates.nowPos
        end if

        'turns the captions off if instant replay captions have been activated and 30s has elapsed
        if playerStates.replayEnd > 0 and playerStates.nowPos > playerStates.replayEnd
          m.cancelInstantReplay(playerStates, deviceInfo.GetCaptionsMode(), captions)
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
      'the user pressed a button on the remote
      if msg.isRemoteKeyPressed()
      
        'back button
        if msg.GetIndex() = 0
          'close the screen
          m.canvas.close()
          'save the last position to memory
          m.savePreviouslyViewedUpdate(episode, playerStates.nowPos)
          episode.nowPos = playerStates.nowPos

          m.canvas.close()
          return m.constants.player.playerResults.closed
        end if

        'rewind
        if msg.GetIndex() = 8
          if playerStates.isInHopMode = true
            playerStates.isInHopMode = false
          end if

          if playerStates.isScrubbing = false
            playerStates.nowPosAtScrub = playerStates.nowPos
            m.cancelInstantReplay(playerStates, deviceInfo.GetCaptionsMode(), captions)
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
              shouldBreak = endScrub(player, playerStates, episode, captions)
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
            m.cancelInstantReplay(playerStates, deviceInfo.GetCaptionsMode(), captions)
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
              shouldBreak = endScrub(player, playerStates, episode, captions)
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
          playerStates.isInHopMode = true
          if playerStates.nowPosAtScrub = 0
            playerStates.nowPosAtScrub = playerStates.nowPos
          end if

          m.cancelInstantReplay(playerStates, deviceInfo.GetCaptionsMode(), captions)

          'if user is fast forwarding or rewinding stop the scrub
          if playerStates.isScrubbing = true
            shouldBreak = endScrub(player, playerStates, episode, captions)
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
            shouldBreak = endScrub(player, playerStates, episode, captions)
            if shouldBreak = true
              episode.nowPos = playerStates.nowPos
              episode.playStart = playerStates.nowPos
              m.canvas.close()
              return m.constants.player.playerResults.resumePlay
            end if

          'hop to the position the user has chosen and close the transport
          else if playerStates.isInHopMode = true
            globalCaptions = deviceInfo.GetCaptionsMode()
            if globalCaptions = "On"
              captions.showSubtitle(true)
            else
              captions.showSubtitle(false)
            end if

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

          'show the transport overlay while continuing the show
          else if playerStates.isTransportShowing = false
            playerStates.isTransportShowing = true
            m.paintToCanvas(progressPercent, playerStates, episode)

          'close the transport overlay while continuing the show
          else
            playerStates.isTransportShowing = false
            if playerStates.isPaused = true
            
              m.utils.tracking.trackUserEvent({
                trackType: "pauseToggle"
                ctx: episode.id
                value: "resumed"
                requestQ: m.playerRequestQueue
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
            shouldBreak = endScrub(player, playerStates, episode, captions)
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
          result = m.showCaptionsDialog(episode)
          captions.showSubtitle(result)
          playerStates.isPaused = false
          player.resume()
        end if

        'play/pause button
        if msg.GetIndex() = 13
          'if scrubbing, stop the scrubbing and resume the show
          if playerStates.isScrubbing = true
            shouldBreak = endScrub(player, playerStates, episode, captions)
            if shouldBreak = true
              episode.nowPos = playerStates.nowPos
              episode.playStart = playerStates.nowPos
              m.canvas.close()
              return m.constants.player.playerResults.resumePlay
            end if

          'hop to the position the user has chosen and close the transport
          else if playerStates.isInHopMode = true
            globalCaptions = deviceInfo.GetCaptionsMode()
            if globalCaptions = "On"
              captions.showSubtitle(true)
            else
              captions.showSubtitle(false)
            end if

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

          'if not scrubbing or hopping, 
          else
            'and not paused, then pause the show and show the transport overlay
            if playerStates.isPaused = false
              playerStates.isTransportShowing = true
              playerStates.isPaused = true
              player.pause()
              m.paintToCanvas(progressPercent, playerStates, episode)

              m.utils.tracking.trackUserEvent({
                trackType: "pauseToggle"
                ctx: episode.id
                value: "paused"
                requestQ: m.playerRequestQueue
              })

            'if not scrubbing but paused, resume the show and remove the transport overlay
            'but first check if we should play a set of ads
            else
              m.utils.tracking.trackUserEvent({
                trackType: "pauseToggle"
                ctx: episode.id
                value: "resumed"
                requestQ: m.playerRequestQueue
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
      handled = m.playerRequestQueue.handleEvent(msg)  'a request object that has been handled

      resp = invalid
      if handled <> invalid and handled.response <> invalid and handled.response.data.len() > 0
        resp = handled.response.data
        parsedResp = parseJson(resp)

        'check if we have the response for a history API call
        if parsedResp <> invalid and handled.url = m.constants.urls.users.history and parsedResp.id <> invalid
          if parsedResp.episodes <> invalid and type(parsedResp.episodes) = "roArray" and parsedResp.episodes.count() > 0
            episode.historyId = parsedResp.episodes[0].id
            episode.parentHistoryId = parsedResp.id
          else
            episode.historyId = parsedResp.id
          end if
        end if
      end if
    end if
  end while

End Function

m.global.player.paintToCanvas = Function(progressPercent, playerStates, episode)

  'display is used to select HD or SD sized transport buttons
  display = m.constants.deviceInfo.definition

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
    rewindUrl = m.constants.player.transportImages[display].rw
    if playerStates.scrubAmount < 0
      rewindUrl = m.constants.player.transportImages[display].rwOrange
    end if
    layers[1].Push({
      Url: rewindUrl
      TargetRect: m.getTransportRects(m.canvas.GetCanvasRect(), playerStates).rewind
    })

    'the fast forward button below the transport bar
    forwardUrl = m.constants.player.transportImages[display].ff
    if playerStates.scrubAmount > 0
      forwardUrl = m.constants.player.transportImages[display].ffOrange
    end if
    layers[1].Push({
      Url: forwardUrl
      TargetRect: m.getTransportRects(m.canvas.GetCanvasRect(), playerStates).fastforward
    })

    'the star button below the transport bar
    layers[1].Push({
      Url: m.constants.player.transportImages[display].star
      TargetRect: m.getTransportRects(m.canvas.GetCanvasRect(), playerStates).star
    })

    'if we are not paused (no scrubbing, no pause) show the pause button on the transport menu
    if playerStates.isPaused = false
      'the pause button below the transport bar
      layers[1].Push({
        Url: m.constants.player.transportImages[display].pauseSmall
        TargetRect: m.getTransportRects(m.canvas.GetCanvasRect(), playerStates).pause
      }) 
    
    'if we are paused, show the play button on the transport menu
    else
      'the play button below the transport bar
      layers[1].Push({
        Url: m.constants.player.transportImages[display].play
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
        Url: m.constants.player.transportImages[display].pauseBig
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
End Function

m.global.player.getTransportRects = Function(canvasRect, playerStates)
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
End Function

m.global.player.getPauseRect = Function(canvasRect)
  'expect an image that is exactly 55 x 83 pixels
  'using percentages to render image - will render correctly on 1280w x 720h screens

  return {
    x: int(0.479 * canvasRect.w)
    y: int(0.442 * canvasRect.h)
    w: int(0.043 * canvasRect.w)
    h: int(0.115 * canvasRect.h)
  }
End Function


'builds the string that will display the time under the transport bar when a video is paused
m.global.player.getTransportTime = Function(seconds)

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

End Function

'------------------------------------------------------------------
m.global.player.handleVideoFailure = function(episode)
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

  ' episode = GetGlobalAA().app.cp.getUpdatedUrlForEpisode(episode)

  m.utils.log.warn(m.playerPort, "playback-message-shown", "User was shown the video playback failed pop up message")

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
          status = m.showSpanOfContentVideoNew(episode)
          return status
        else if (button = 2)
          return m.constants.player.playerResults.ignore
        else if (button = 3)
          return m.constants.player.playerResults.closed
        end if
      end if

      if dlgMsg.isScreenClosed()
        return m.constants.player.playerResults.ignore
      end if
    end if
  end while
  return ""
end function


m.global.player.savePreviouslyViewedUpdate = Function(episode, nowPos)

  'only do the following if the user is logged in
  authInfo = m.utils.auth.getAuthInfo()
  if authInfo <> invalid and authInfo.accessToken <> invalid
  
    newHistoryReq = m.utils.bookmarks.addHistoryReq(episode, nowPos)
    m.playerRequestQueue.pushRequest(newHistoryReq)
  end if

End Function


'@episode: assocArray, a video object from that has been passed into the player
m.global.player.showCaptionsDialog = Function(episode as Object) as Boolean
  port = CreateObject("roMessagePort")
  dialog = CreateObject("roMessageDialog")
  dialog.SetMessagePort(port)
  deviceInfo = CreateObject("roDeviceInfo")

  dialog.SetTitle("Closed caption/audio configuration")

  ' default options
  languageOptions = []
  captionsOptions = []
  audioOptions = []
  ' default focus
  captionSelected = 0
  languageSelected = 0
  audioSelected = 0

  if episode.subtitleLanguages <> invalid and episode.subtitleUrls <> invalid
    captionsOptions = ["Off", "On", "Instant replay"]
    for i=0 to captionsOptions.count()-1
      print "Current caption mode = " + deviceInfo.GetCaptionsMode()
      if deviceInfo.GetCaptionsMode() = captionsOptions[i] then
        captionSelected = i
      end if
    end for

    for i=0 to episode.subtitleLanguages.count()-1
      languageOptions.push(episode.subtitleLanguages[i])
      if episode.subtitleUrl = episode.subtitleUrls[i] then
        languageSelected = i
      end if
    end for
  end if

  index = 0
  if captionsOptions.count() > 0 then
    dialog.AddButton(index, "Captions mode: <" + captionsOptions[captionSelected] + ">")
    index = index + 1
    if languageOptions.count() > 1 then
      dialog.AddButton(index, "Captions language: <" + languageOptions[languageSelected] + ">")
      index = index + 1
    end if
  else
    dialog.AddButton(index, "Caption not available")
    index = index + 1
  end if

  ' NOTE: there was never any support for audio track selection so we're just adding a placeholder
  ' here to mimic the system dialog
  dialog.AddButton(index, "Audio selection not available")
  dialog.AddButton(index+1, "OK")
  dialog.AddButton(index+2, "Cancel")
  dialog.EnableBackButton(true)
  dialog.EnableOverlay(true)
  dialog.Show()

  while true
    dlgMsg = wait(0, port)

    if type(dlgMsg) = "roMessageDialogEvent"
      if dlgMsg.isButtonPressed()
        buttonIndex = dlgMsg.GetIndex()

        if buttonIndex = 0 and captionsOptions.count() > 0 then
          captionSelected = captionSelected + 1
          if captionSelected >= captionsOptions.count() then captionSelected = 0
          dialog.UpdateButton(0, "Captions mode: <" + captionsOptions[captionSelected] + ">")
        else if buttonIndex = 1 and languageOptions.count() > 1 then
          languageSelected = languageSelected + 1
          if languageSelected >= languageOptions.count() then languageSelected = 0
          dialog.UpdateButton(1, "Captions language: <" + languageOptions[languageSelected] + ">")
        else if buttonIndex = 1 or (buttonIndex = 2 and languageOptions.count() > 1) then
          'ignore audio selection
        else if buttonIndex = 2 or (buttonIndex = 3 and languageOptions.count() > 1) then
          ' OK
          if captionsOptions.count() > 0 then
            print "Captions mode: " + captionsOptions[captionSelected]
            deviceInfo.SetCaptionsMode(captionsOptions[captionSelected])
            episode.subtitlesCurrent = episode.subtitleUrls[languageSelected]
            episode.subtitleUrl = episode.subtitleUrls[languageSelected]
          end if

          if captionsOptions.count() > 0 and captionsOptions[captionSelected] = "On" then
            episode.showSubtitles = true
            trackingFlag= "on"
          else
            episode.showSubtitles = false
            trackingFlag = "off"
          end if

          m.utils.tracking.trackUserEvent({
            trackType: "subtitles"
            ctx: episode.id
            value: trackingFlag
            requestQ: m.playerRequestQueue
          })
          exit while

        else
          ' Cancel
          exit while
        end if
      end if
      if dlgMsg.isScreenClosed() or dlgMsg.isButtonInfo() then
        exit while
      end if
    else
    end if
  end while
  return episode.showSubtitles
End Function


m.global.player.cancelInstantReplay = Function(playerStates, captionsMode, captions)
  'if the video was in an instant replay state, cancel the replay
  if playerStates.replayEnd > 0
    playerStates.replayEnd = 0

    'only turn off the captions if the user hasn't set captions for this specific video to on
    if captionsMode <> "On"
      captions.showSubtitle(false)
    end if
  end if
End Function































  m.global.channel.player = m.global.player

  m.global.channel.runChannel = Function(args, adShim, port)
    ' Load scene graph
    screen = CreateObject("roSGScreen")
    screen.setMessagePort(port)

    ' start the scene graph UI
    sgGlobal = screen.getGlobalNode()
    sgGlobal.addField("constants", "assocarray", false)
    sgGlobal.constants = m.constants 
    tubiScene = screen.CreateScene("TubiScene")
    screen.show()

    'flag to enable vs. disable remote components loading
    enableRemoteComponents = m.constants.externalConfig.info.remote_components

    if enableRemoteComponents = 1 then
      ' Dynamic Component Library loading
      remoteLibrary = tubiScene.findNode("TubiRemoteLibrary")

      print "TubiRemoteLibrary loading from " + m.constants.settings.remoteComponentsUrl
      ' NOTE: Dynamically setting uri here only works for HTTPS or signed packages.  HTTP will give loadStatus 'none'
      remoteLibrary.uri = m.constants.settings.remoteComponentsUrl
      print "TubiRemoteLibrary status is " + remoteLibrary.loadStatus

      componentTimer = CreateObject("roTimespan")
      'Listen for when the remote loading has completed
      while remoteLibrary.loadStatus <> "ready"
        msg = wait(1000, port)
        if type(msgType) = "roSGScreenEvent" and msg.isScreenClosed() then return 0

        loadStatus = remoteLibrary.loadStatus
        print "TubiRemoteLibrary status is " + loadStatus

        if componentTimer.totalMilliseconds() > m.constants.timers.remoteComponentTimeout then
          loadStatus = "failed"
        end if

        if loadStatus = "failed"
          showErrorDialog()
          return 0
        end if
      end while

      'change the client version so we tracking knows we are using the remote components
      m.constants.deviceInfo.clientVersion = m.constants.deviceInfo.clientVersion.Replace("local", "remote")

      controller = tubiScene.createChild("TubiRemoteLibrary:ContentController")
    else
      controller = tubiScene.createChild("ContentController")
    end if

    controller.observeField("playContent", port)
    controller.observeField("exitApp", port)

    m.deepLink(args, controller, m.tracking)

    while(true)
      msg = wait(0, port)
      msgType = type(msg)
      print "msgType "; msgType
      
      if msgType = "roSGScreenEvent"
        if msg.isScreenClosed() then return 0
      
      else if msgType = "roSGNodeEvent"
        node = msg.getNode()
        field = msg.getField()
        data = msg.getData()

        if field = "playContent"
          playerContent = data
          playerContent.stream = {url: playerContent.url}
          playerResult = m.player.playVideo(playerContent)

          'pass the new nowPos and historyId (if necessary) to scenegraph thread
          infoToPass = {
            nowPos: playerContent.nowPos
            result: playerResult
          }

          if playerContent.historyId <> invalid
            infoToPass.historyId = playerContent.historyId
          end if
          if playerContent.parentHistoryId <> invalid
            infoToPass.parentHistoryId = playerContent.parentHistoryId
          end if
          
          controller.playerInfo = infoToPass

        else if field = "exitApp"
          if msg.GetData() = true then return true
        end if 
      end if

    end while    
  End Function
end if
 
