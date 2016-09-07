' --------------------------------------------------------
'  TubiPlayer
function TubiPlayer(utils)

  'a single message port used whenever a video or ad is playing
  'in order to make sure we delete async url objects, we need to make sure we always use this port
  playerPort = CreateObject("roMessagePort")
  playerRequestQueue = utils.requestQueue.create(playerPort)

  return {
    utils: utils
    constants: utils.constants
    pingFrequency: utils.constants.player.pingFrequency
    playerPort: playerPort
    playerRequestQueue: playerRequestQueue
    resumePlayAdsList: invalid

    ' ads module
    ads : TubiAds(utils, playerRequestQueue)

    'stores the request ids everytime we make a call to add a new position for previously viewed/history content
    previouslyViewedReqIds: {}

    ' public methods
    playVideo: AdrisePlayer_playVideo

    ' private methods
    showSpanOfContentVideoNew: AdrisePlayer_showSpanOfContentVideoNew
    paintToCanvas: AdrisePlayer_paintToCanvas
    getTransportRects: AdrisePlayer_getTransportRects
    getPauseRect: AdrisePlayer_getPauseRect
    getTransportTime: AdrisePlayer_getTransportTime
    handleVideoFailure: AdrisePlayer_handleVideoFailure
    savePreviouslyViewedUpdate: AdrisePlayer_savePreviouslyViewedUpdate
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
  episode.nowPos = 0
  m.lastPingTime = 0
  m.shouldResetPing = false


  'get the state of the app - ie. where is the player coming from? linear TV? bookmarks? previously viewed?
  ' m.linearTvOn = GetGlobalAA().app.linearTV.linearTvOn

  'send tracking event that the video started playing
  vidOrSeries = "video"
  if episode.isParentSeries = true
    vidOrSeries = "series"
  end if

  if episode.playStart <> invalid
    episode.nowPos = episode.playStart
  end if

  m.utils.tracking.trackEvent({
    trackType: "videoPlay"
    value: episode.id
    ctx: episode.nowPos
    extraCtx: {
      subtitles: episode.showSubtitles
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

    m.utils.tracking.trackEvent({
      trackType: "resumeAfterAds"
      value: episode.nowPos
      ctx: episode.id
      requestQ: m.playerRequestQueue
    })
    
    status = m.showSpanOfContentVideoNew(episode)

    while status = m.constants.player.playerResults.failed
      failHandlerStatus = m.handleVideoFailure(episode)
      if failHandlerStatus = m.constants.player.playerResults.closed
        canvas.close()
        return m.constants.player.playerResults.closed
      else if failHandlerStatus = m.constants.player.playerResults.ignore
        exit while
      else
        status = failHandlerStatus
        exit while
      end if
    end while

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
    return m.constants.player.playerResults.completed
  end if

  m.canvas = CreateObject("roImageCanvas")
  player = CreateObject("roVideoPlayer")

  m.canvas.SetMessagePort(m.playerPort)
  player.SetMessagePort(m.playerPort)

  'put the canvas on the screen - the canvas is the container for the player
  m.canvas.show()

  'get the size as an assocArray of the imageCanvas, aka the screen
  targetRect = m.canvas.GetCanvasRect()

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
  captions.showSubtitle(episode.showSubtitles)

  'object that will help us determine how long we've been scrubbing for
  scrubTimer = CreateObject("roTimespan")
  
  'holds the state of the player
  playerStates = {
    loadProgress: 0
    isTransportShowing: false
    isPaused: false
    isScrubbing: false
    maxScrub: 7
    scrubAmount: 0
    scrubMultiplier: 0
    totalScrubTime: 0
    scrubToPoint: 0
    scrubPercent: 0
    nowPos: 0
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

    m.global.utils.tracking.trackEvent({
      trackType: "playProgress"
      ctx: episode.id
      value: playerStates.nowPos
      extraCtx: {interval: playerStates.nowPos - m.global.player.lastPingTime}
      requestQ: m.global.player.playerRequestQueue
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

    m.global.player.shouldResetPing = true

    m.global.utils.tracking.trackEvent({
      trackType: "seek"
      ctx: episode.id
      value: playerStates.nowPos
      requestQ: m.global.player.playerRequestQueue
    })
    
    'when resuming to play after ending scrubbing, we need to ask the ad server if there are any ads
    'getResumingPlayAds will store ads in either m.global.player.resumePlayAdsList or m.global.player.ads.allAdUnitsList
    'depending on if RAF is off or on
    shouldBreak = m.global.player.ads.getResumingPlayAds(episode, m.global.player)
    if shouldBreak = true
      return shouldBreak
    end if

    player.Seek(playerStates.scrubToPoint * 1000)
    playerStates.isTransportShowing = false
    playerStates.isPaused = false
    playerStates.isScrubbing = false
    playerStates.scrubAmount = 0
    playerStates.totalScrubTime = 0
    playerStates.scrubToPoint = 0


    return shouldBreak 'false
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

        errorMsg = "video with id: " + episode.id + "failed. Segment Url: " + msg.getInfo().url + " Stream Bitrate: " + msg.getInfo().streamBitrate.toStr() + " Measured Bitrate: " + msg.getInfo().measuredBitrate.toStr()  +  " Error Index " + msg.getIndex().toStr() +  " : " + msg.getMessage()
        ' m.utils.log.error(m.playerPort, "video-fail", errorMsg)
        TubiLog("video fail")

        m.canvas.close()
        return m.constants.player.playerResults.failed
      end if

      'log any re-buffers that user might encounter
      if msg.isStreamStarted()
        if msg.getInfo().isUnderrun = true
          warningMsg = "Video buffered mid stream. Segment Url: " + msg.getInfo().url + " Stream Bitrate: " + msg.getInfo().streamBitrate.toStr() + " Measured Bitrate: " + msg.getInfo().measuredBitrate.toStr()
          ' m.utils.log.warn(m.playerPort, "video-rebuffer",  warningMsg)
          TubiLog("video rebuffer")
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

          m.utils.tracking.trackEvent(playProgressEvent)

          m.lastPingTime = playerStates.nowPos
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
          m.canvas.close()
          return m.constants.player.playerResults.closed
        end if
        
        'left button or rewind
        if msg.GetIndex() = 4 or msg.GetIndex() = 8
          if playerStates.isScrubbing = false
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
                return m.constants.player.playerResults.resumePlay
              end if
            else
              'updates the screen with the new amount of scrubbing
              m.paintToCanvas(progressPercent, playerStates, episode)
            end if
          end if
        end if
  
        'right button or fast forward
        if msg.GetIndex() = 5 or msg.GetIndex() = 9
          if playerStates.isScrubbing = false
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
                return m.constants.player.playerResults.resumePlay
              end if
            else
              'updates the screen with the new amount of scrubbing
              m.paintToCanvas(progressPercent, playerStates, episode)
            end if
          end if
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
              return m.constants.player.playerResults.resumePlay
            end if

          'show the transport overlay while continuing the show
          else if playerStates.isTransportShowing = false
            playerStates.isTransportShowing = true
            m.paintToCanvas(progressPercent, playerStates, episode)

          'close the transport overlay while continuing the show
          else
            playerStates.isTransportShowing = false
            if playerStates.isPaused = true
            
              m.utils.tracking.trackEvent({
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

        '* button
        if msg.GetIndex() = 10
          ' playerStates.isPaused = true
          ' player.pause()
          
          ' 'show a dialog that will let users turn on/off captions
          ' if GetGlobalAA().app.detailScreen.showCaptionsDialog(episode) = true
          '   captions.showSubtitle(true)
          
          ' else
          '   captions.showSubtitle(false)
          ' end if
          ' playerStates.isPaused = false
          ' player.resume()
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
              return m.constants.player.playerResults.resumePlay
            end if

          'if not scrubbing, 
          else
            'and not paused, then pause the show and show the transport overlay
            if playerStates.isPaused = false
              playerStates.isTransportShowing = true
              playerStates.isPaused = true
              player.pause()
              m.paintToCanvas(progressPercent, playerStates, episode)

              m.utils.tracking.trackEvent({
                trackType: "pauseToggle"
                ctx: episode.id
                value: "paused"
                requestQ: m.playerRequestQueue
              })

            'if not scrubbing but paused, resume the show and remove the transport overlay
            'but first check if we should play a set of ads
            else
              m.utils.tracking.trackEvent({
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
      handled = m.playerRequestQueue.handleEvent(msg)

      respObj = invalid
      if handled <> invalid and handled.response <> invalid and handled.response.data.len() > 0
        respObj = handled.response.data
      end if

      'TODO: BRYAN, refactor when doing queue and view history  
      ' if respObj <> invalid and m.previouslyViewedReqIds[respObj.id.toStr()] <> invalid
      '   'we know we have a response from updating previously viewed - so update the previouslyViewedServerId where necessary
      '   'this is necessary to make the "Remove from History" button work on the details page
      '   if respObj.data <> invalid and respObj.data.len() > 0
      '     addPreviouslyViewedResponse = parseJson(respObj.data)
      '     if addPreviouslyViewedResponse.content_type <> invalid

      '       if addPreviouslyViewedResponse.content_type = "series"
      '         m.cp.userPlaylistSeries[addPreviouslyViewedResponse.content_id.toStr()].previouslyViewedServerId = addPreviouslyViewedResponse.id
      '       else if addPreviouslyViewedResponse.content_type = "movie"
      '         m.cp.userPlaylistVideos[addPreviouslyViewedResponse.content_id.toStr()].previouslyViewedServerId = addPreviouslyViewedResponse.id
      '       end if

      '     end if
      '   end if

      '   'since we already got a response for this request id, we don't need to store the id anymore
      '   m.previouslyViewedReqIds.delete(respObj.id.toStr())
      ' end if
    end if
  end while

end function

function AdrisePlayer_paintToCanvas(progressPercent, playerStates, episode)

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

  dialog.SetText("If problem persists, please visit adrise.tv/support")
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

function AdrisePlayer_savePreviouslyViewedUpdate(episode, nowPos)

  'only do the following if the user is logged in
  authInfo = m.utils.auth.getAuthInfo()
  if authInfo.accessToken <> invalid
  
    newHistoryReq = m.utils.bookmarks.addHistoryReq(episode, nowPos)
    m.playerRequestQueue.pushRequest(newHistoryReq)
  end if

end function