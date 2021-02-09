'''''''''''''''''''''
' playVideoContent
'
' Helper function for onResume and onPlay to launch content
' @content: TubiContentNode, the content to be played, can be a movie, episode, or trailer
' @autoplayType: string, valid values are "automatic", "deliberate", or "none"
' @position: integer, the position from which to start video playback
function playVideoContent(content, autoplayType = "none", position = 0)
  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.videoPlayerScreen)

  if videoPlayer = invalid
    videoPlayer = CreateObject("roSGNode", "VideoPlayerScreen")
    videoPlayer.id = m.constants.ui.screenIds.videoPlayerScreen
    ' onVideoPlayerVisibleChange exists in ContentController
    videoPlayer.observeFieldScoped("visible", "onVideoPlayerVisibleChange")
    videoPlayer.observeFieldScoped("transportVoiceResponse", "onTransportVoiceResponse")
    initVideoTracking(videoPlayer) 'initializeYoubora
    setInScreenCache(videoPlayer)
  end if

  ' m.upNextRequest can be checked to determine if a request to fetch up next / autoplay content has
  ' already been made for the currently playing content. This is important in the case where a user
  ' might select the go to next button while the request is in flight from the player reaching the
  ' creditsCuePoint.
  ' m.upNextRequest is set to invalid when playContent() is called so that only one request to fetch
  ' the up next content is made per video session.
  m.upNextRequest = invalid

  ' when receiving up next content from the API, m.receivedGoToNextPressed is used to determine
  ' if the videoPlayer's go to next button was pressed prior to receiving the up next content, and if so,
  ' indicates we should immediately autoplay the next video
  m.receivedGoToNextPressed = false

  if m.kidsModeEnabled = true
    videoPlayer.appMode = "KIDS_MODE"
  else if m.latinoModeEnabled = true
    videoPlayer.appMode = "LATINO_MODE"
  else
    videoPlayer.appMode = "DEFAULT_MODE"
  end if  

  if content <> invalid
    if content.isTrailer
      videoPlayer.analyticsMode = "trailer"
      videoPlayer.observeFieldScoped("skipTrailer", "onSkipTrailer")
      videoPlayer.observeFieldScoped("goToNext", "onSkipTrailer")
      videoPlayer.enableAds = false
    else
      videoPlayer.analyticsMode = "normal"
      if autoplayType = "automatic"
        videoPlayer.analyticsMode = "autoplay-automatic"
      else if autoplayType = "deliberate"
        videoPlayer.analyticsMode = "autoplay-deliberate"
      end if

      ' set observers for non trailer content
      videoPlayer.observeFieldScoped("historyPosition", "onEpisodePosition")
      videoPlayer.observeFieldScoped("goToNext", "onGoToNext")
      videoPlayer.observeFieldScoped("upNextCuepointReached", "onUpNextCuepointReached")
      videoPlayer.observeFieldScoped("upNextContentToAutoplay", "onUpNextContentToAutoplay")
      videoPlayer.observeFieldScoped("upNextNavigateWithinPageInfo", "onNavigateWithinPageInfoChange")
      videoPlayer.observeFieldScoped("segBitrate", "onSegBitrateChange")

      videoPlayer.enableAds = true
      if m.constants.settings.suitest = true or m.constants.settings.noAds = true
        videoPlayer.enableAds = false
      end if
    end if

    ' by default setting sprites to invalid
    videoPlayer.sprites = invalid
    ' get sprites / seek preview images
    getSprites(content)

    '//Stop the background artwork from transitioning
    m.backgroundGroup.backgroundInfo = {
      type: m.constants.ui.backgroundTypes.fullScreen
      uriList: []
    }

    ' set general observers for all content (including trailers)
    videoPlayer.observeFieldScoped("state", "onVideoPlayerState")
    videoPlayer.observeFieldScoped("backButtonPressed", "onVideoPlayerBackPressed")
    videoPlayer.observeFieldScoped("sendVideoTrackingStart", "onVideoTrackingStart")

    creditsCuepoint = content.creditscuepoint
    videoLength = content.length

    if position >= creditsCuepoint or (videoLength - position) <= 5
      position = 0
    end if
    content.nowPos = position

    videoPlayer.content = content
    videoPlayer.updateContent = true

    ' necessary in the case of deeplinks - only fires once per session
    fireAppLoadBeacon()

    ' For position history tracking
    m.updateHistoryTask.historyResult = invalid
    m.updateHistoryTask.content = content
  end if

  ' it's necessary to push the screen after the content has been set on the videoPlayer component,
  ' so NavigateToPage and PageLoad events contain the necessary content id information
  if currentScreen() = invalid or currentScreen().id <> m.constants.ui.screenIds.videoPlayerScreen
    if m.enteredFromDeepLink = true
      pushScreen(videoPlayer, false, true)
    else if m.handlingDeeplinkInputEvent = true
      ' send custom navigateToPage event, since a details screen was added to the screen stack but the user
      ' never saw it, we want to navigate from the screen under the most recently added details screen.
      screenTrackingNavigate(m.currentPageInfoAtDeeplinkInputEvent, videoPlayer.trackingPageInfo)
      pushScreen(videoPlayer, false, true)
      m.currentScreenAtDeeplinkInputEvent = invalid
    else
      pushScreen(videoPlayer, true, true)
    end if
  end if

  videoPlayer.control = "play"
end function


''''''''''''''''''''''
' onEpisodePosition
'
' Update the resume position
' This function triggers when the video stops as well as when videoPlayer.historyPosition is updated
function onEpisodePosition()
  tubiLog("VideoHelpers.onEpisodePosition")

  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.videoPlayerScreen)
  if videoPlayer <> invalid
    ' Don't send history updates to the server if the user hasn't watched at least a certain amount of video
    history = m.global.historyIds.findNode(m.updateHistoryTask.content.id)
    if history <> invalid or videoPlayer.historyPosition >= m.constants.player.historyFrequency
      ' Only run a new task if the previous task is done.  Priority of resume states is
      ' pretty low and we don't mind losing a few.
      if m.updateHistoryTask.state <> "RUN"
        m.updateHistoryTask.nowPos = videoPlayer.historyPosition
        m.updateHistoryTask.control = "RUN"
      end if
    end if
  end if
end function


function onGoToNext(msg)
  tubiLog("VideoHelpers.onGoToNext")
  goToNext = msg.getData()
  if goToNext = true
    m.receivedGoToNextPressed = true
    videoPlayer = msg.getRoSGNode()
    if videoPlayer <> invalid
      ' if there is already valid up next content, play it
      if videoPlayer.upNextContent <> invalid
        nextContent = videoPlayer.upNextContent.getChild(0)
        oldContent = videoPlayer.content

        nextContent = addSeriesTitle(nextContent, oldContent)
        if nextContent <> invalid
          if nextContent.validUntil >= Uptime(0)
            ' the up next content has expired, so fetch new content
            m.upNextRequest = fetchUpNextContent(videoPlayer)
          else
            ' the up next content is good to go, so play it
            playUpNextContent(nextContent, "none")
          end if
        else
          returnToDetailScreenFromVideo()
        end if
      else if m.upNextRequest = invalid
        m.upNextRequest = fetchUpNextContent(videoPlayer)
      end if
    else
      returnToDetailScreenFromVideo()
    end if
  end if
end function


' @nextContent: roSGNode, the content node representing the content that will be played next
' @ autoplayType: string, "deliberate", "automatic" or "none", refers to if the up next content was selected or is auto playing
function playUpNextContent(nextContent, autoplayType)
  tubiLog("VideoHelpers.playUpNextContent")
  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.videoPlayerScreen)

  if videoPlayer <> invalid
    oldContent = videoPlayer.content
    content = addSeriesTitle(nextContent, oldContent)
    stopVideoContent(videoPlayer)

    ' for analytics purposes, simulate navigating to a new video player page
    ' (which normally happens when pushing a screen to the screen stack)
    ' since we are not tearing down and re-creating the video player
    oldTrackingPageInfo = videoPlayer.trackingPageInfo
    newTrackingPageInfo = videoPlayer.trackingPageInfo
    newTrackingPageInfo.pageValues = {
      video_id: nextContent.id.toInt()
    }
    screenTrackingNavigate(oldTrackingPageInfo, newTrackingPageInfo, videoPlayer.trackingComponentInfo)

    ' populate the detail screen with the new content while the video is showing so when the user
    ' exits, it's already populated and there is no visible screen re-render. Assume this is only necessary
    ' for movies, as series only autoplay into the same series for now.
    if oldContent.parentType <> m.constants.ui.contentTypes.series
      emptyMovieNode = CreateObject("roSGNode", "TubiContentNode")
      emptyMovieNode.type = m.constants.ui.contentTypes.video
      emptyMovieNode.id = nextContent.id
      detailScreen = getTopDetailScreenFromStack()
      getSingleContentFromServer(detailScreen, emptyMovieNode, false)
    end if

    playVideoContent(content, autoplayType)
  end if
end function


' Triggered by either a button press or by timer expiration of the up next / autoplay ui
' Is also triggered when resetting videoPlayer.upNextContentToAutoplay = invalid prior to video playback.
function onUpNextContentToAutoplay(msg)
  upNextContentToAutoplay = msg.getData()

  if upNextContentToAutoplay <> invalid
    tubiLog("VideoHelpers.onUpNextContentToAutoplay")
    videoPlayer = msg.getRoSGNode()
    playUpNextContent(upNextContentToAutoplay, videoPlayer.autoplayMode)
  end if
end function


function onVideoPlayerState(msg)
  tubiLog("VideoHelpers.onVideoPlayerState")
  videoPlayer = msg.getRoSGNode()
  if videoPlayer <> invalid
    tubiLog("VideoHelpers.onVideoPlayerState state = " + msg.GetData())
    state = msg.GetData()
    if state = "error"
      stopVideoContent(videoPlayer)
      videoPlayer.errorMsg = ""

      currentScreen = currentScreen()
      if currentScreen <> invalid and currentScreen.id = m.constants.ui.screenIds.videoPlayerScreen
        popScreen(true, true)
      end if

      '//adding the onscreen error should happen after the popScreen() call so that the error modal keeps the focus
      errorMessage = getTranslation("videoPlayer_error_failed_description")
      if videoPlayer.errorMsg <> ""
        errorMessage = videoPlayer.errorMsg
      end if
      showPlayerError(errorMessage, videoPlayer.videoErrorCode)
    else if state = "finished"
      finishedContent = videoPlayer.content
      if finishedContent.isTrailer
        returnToDetailScreenFromVideo()
      else if videoPlayer.upNextContentToAutoplay <> invalid
        ' the video ended while the autoplay UI was still present, now autoplay the chosen video
        ' or autoplay the video that was focused when the timer expired
        playUpNextContent(videoPlayer.upNextContentToAutoplay, videoPlayer.autoplayMode)
      else if videoPlayer.upNextContent <> invalid
        ' the video ended after the autoplay UI was dismissed, so autoplay the first content in
        ' the autoplay "container"
        autoplayContent = videoPlayer.upNextContent.getChild(0)
        if autoplayContent <> invalid
          playUpNextContent(autoplayContent, videoPlayer.autoplayMode)
        else
          returnToDetailScreenFromVideo()
        end if
      else
        ' there was no autoplay content, so return to details screen
        returnToDetailScreenFromVideo()
      end if
    end if
  end if
end function


function onVideoPlayerBackPressed()
  tubiLog("VideoHelpers.onVideoPlayerBackPressed")
  returnToDetailScreenFromVideo()
end function


' Stop the video player and refresh detail screen with the relevant content
'
' Use cases:                                                Actions:
'   - Exit video player movie                                 : 1 - redraw detail screen with existing detail content to update resume position; preserve related items
'   - Exit video player movie after autoplay                  : 2 - redraw detail screen with autoplayed content from video player; fetch new related items
'   - Exit video player series episode                        : 3 - redraw detail screen with existing detail content to updated resume positions; preserve related items
'   - Exit video player series after autoplay in same series  : 4 - redraw detail screen with autoplayed episode metadata, but maintain series content; preserve related items
'   - Exit video player series after autoplay to new series   : 5 - redraw detail screen with new fetched seried metadata; fetch new related items
'   - Exit video player trailer                               : 6 - use existing detail screen, no need to redraw any info
'   - Deep link: exit video player movie                      : 1 - redraw detail screen with existing detail content to update resume position; preserve related items
'   - Deep link: exit video player movie after autoplay       : 2 - redraw detail screen with autoplayed content from video player; fetch new related items
'   - Deep link: Exit video player series                     : 3 - redraw detail screen with existing detail content to updated resume positions; preserve related items
'   - Deep link: Exit video player series after autoplay      : 4 - redraw detail screen with autoplayed episode metadata, but maintain series content; preserve related items
function returnToDetailScreenFromVideo()
  tubiLog("VideoHelpers.returnToDetailScreenFromVideo")
  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.videoPlayerScreen)

  if videoPlayer <> invalid
    stopVideoContent(videoPlayer)

    ' get the top most detail screen
    detailScreen = getTopDetailScreenFromStack()

    videoContent = videoPlayer.content 'always a video, can be movie or episode
    detailContent = detailScreen.content 'can be movie or series

    ' So the detailed page does not have a refresh issue, pass the local resume number before the backend communicates.
    ' The problem with this is that if the backend comes back with a different number than the local
    ' number then there is still a screen redraw issue: i.e. user watches only 2 seconds of a video.
    ' The local number is 2 seconds and displays the resume button, but the backend determines that 2
    ' seconds is not enough to warrant a resume button and returns 0 as the resume point.
    nResumePoint = videoPlayer.historyPosition

    if nResumePoint < m.constants.player.historyFrequency or (videoContent.creditscuepoint > 0 and nResumePoint > videoContent.creditscuepoint)
      '//If the video is either at the very beginning or at the very end, then it should pass the local resume point as 0
      nResumePoint = 0
    end if

    ' Do the appropriate action based on the cases as described in the Function definition comments
    if videoContent.parentType = m.constants.ui.contentTypes.series
      ' Video player was playing a series episode
      if videoContent.parentId <> detailContent.id
        ' Case 5
        ' Autoplayed into a new series, so fetch new series,
        ' repopulate the existing detail screen when the new series metadata is returned
        emptySeriesNode = CreateObject("roSGNode", "TubiContentNode")
        emptySeriesNode.type = m.constants.ui.contentTypes.series
        emptySeriesNode.id = videoContent.parentId
        getSingleContentFromServer(detailScreen, emptySeriesNode, false)

        ' TODO: repopulate the episode screen if necessary after the fetch for the new series
        ' Currently the upNext API does not autoplay into new series, so this functionality was punted for now.
      else
        ' Case 3 and 4
        ' Still in the same series - possibly autoplayed, or possibly same episode
        ' update some info in the detail screen content and repopulate with that content
        detailContent.currentEpisodeId = videoContent.id
        populateDetailScreen(detailScreen, detailContent, false, nResumePoint)

        ' Repopulate the episodes screen if it is the screen under the video player screen in the call stack
        hiddenScreen = getHiddenScreen(1)
        if hiddenScreen.id = m.constants.ui.screenIds.episodeScreen
          '//::TODO:: ensure signed in users see the episode screen progress bars when coming back from video player.
          episodesScreen = hiddenScreen
          episodesScreen.content = detailContent
          episodesScreen.updateContent = true
          episodesScreen.episodeToFocus = findEpisode2dIndex(detailContent.currentEpisodeId, detailContent)
        end if
      end if
    else if videoContent.isTrailer = true
      ' Case 6, no need to do anything
    else
      ' Video player was playing a movie
      if videoContent.id <> detailContent.id
        ' Case 2
        ' Movie autoplayed into another movie.
        ' The above id check is not expected to pass, as we populate the detail screen with the autoplayed
        ' content when autoplay playback occurs (up next ui or go to next button pressed).
        ' In the case that something went wrong with the fetch repopulate the detail screen with the
        ' video player content. Even though the upNext API, which provided the video player with the movie
        ' metadata, provides all the info needed to populate the details screen, it does not provide the
        ' related content. So, populate the detail screen for an immediate re-render, and then re-fetch
        ' the new content (including the related content). Detail screen will be updated a 2nd time when
        ' fetched content is returned
        populateDetailScreen(detailScreen, videoContent)
        emptyMovieNode = CreateObject("roSGNode", "TubiContentNode")
        emptyMovieNode.type = m.constants.ui.contentTypes.video
        emptyMovieNode.id = videoContent.id
        getSingleContentFromServer(detailScreen, emptyMovieNode, false)
      else
        ' Case 1
        ' Returning to the detail screen for the same movie as was started, no autoplay
        ' Just repopulate the detail screen with the same content
        populateDetailScreen(detailScreen, detailContent, false, nResumePoint)
      end if
    end if
  end if

  ' remove the video player screen to reveal the details screen (or episodes list screen)
  currentScreen = currentScreen()
  if currentScreen <> invalid and currentScreen.id = m.constants.ui.screenIds.videoPlayerScreen
    popScreen(true, true)
  end if
end function


' Stop the video player and optionally remove the video player from the screen stack
' @videoPlayer: roSGNode, a VideoPlayerScreen node
' removeVideoPlayerFromScreenStack: boolean, indicates if video player screen should be removed from screen stack
'                                   set to false for autoplay, true to return to detail screen/home screen/etc.
function stopVideoContent(videoPlayer)
  tubiLog("VideoHelpers.stopVideoContent")

  if videoPlayer <> invalid
    videoTrackingStop() 'stops youbora tracking

    videoPlayer.unobserveFieldScoped("backButtonPressed")
    videoPlayer.unobserveFieldScoped("state")
    videoPlayer.unobserveFieldScoped("skipTrailer")
    videoPlayer.unobserveFieldScoped("historyPosition")
    videoPlayer.unobserveFieldScoped("sendVideoTrackingStart")
    videoPlayer.unobserveFieldScoped("goToNext")
    videoPlayer.unobserveFieldScoped("upNextCuepointReached")
    videoPlayer.unobserveFieldScoped("upNextContentToAutoplay")
    videoPlayer.unobserveFieldScoped("upNextNavigateWithinPageInfo")
    videoPlayer.unobserveFieldScoped("segBitrate")

    ' reset the deep link state since we've handled it already at this point
    m.deepLinkContent = invalid
    m.enteredFromDeepLink = false
    m.currentScreenAtDeeplinkInputEvent = invalid
    m.handlingDeeplinkInputEvent = false

    videoPlayer.control = "stop"

    historyId = invalid
    parentHistoryId = invalid
    if m.updateHistoryTask.historyResult <> invalid
      historyId = m.updateHistoryTask.historyResult.historyId
      parentHistoryId = m.updateHistoryTask.historyResult.parentHistoryId
    end if

    nowPos = videoPlayer.historyPosition
    tubiLog("stopVideoContent: nowPos = " + nowPos.toStr())
    if historyId <> invalid and historyId <> "" then
      tubiLog("stopVideoContent: historyId = " + historyId.toStr())
    end if

    if parentHistoryId <> invalid and parentHistoryId <> "" then
      tubiLog("stopVideoContent: parentHistoryId = " + parentHistoryId.toStr())
    end if

    ' reload history
    onHistoryQueueChange(m.constants.ui.categoryIds.history)
  end if
end function


' can fire from videoPlayer.skipTrailer or videoPlayer.goToNext fields
' if a trailer is playing.
function onSkipTrailer(msg)
  tubiLog("VideoHelpers.onSkipTrailer")
  skipTrailer = msg.getData()
  if skipTrailer
    videoPlayer = getFromScreenCache(m.constants.ui.screenIds.videoPlayerScreen)
    if videoPlayer <> invalid
      stopVideoContent(videoPlayer)

      if getHiddenScreen() <> invalid and getHiddenScreen().id = m.constants.ui.screenIds.detailScreen
        detailScreen = getHiddenScreen()
        detailScreenContent = getDetailScreenContent(detailScreen)
        playVideoContent(detailScreenContent)
      end if
    end if
  end if
end function


'''''''''''''''''''
' onPlayerError
'
' @errorMessage: string, an error message that will be displayed to the user
' @errorCode: integer, the video player error code (usually a negative number)
function showPlayerError(errorMessage, errorCode)
  tubiLog("ContentController.showPlayerError")

  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.videoPlayerScreen)
  if videoPlayer <> invalid
    ' reset the video player state in case an error occurs during the next attempt at playing a video
    videoPlayer.state = ""

    if errorCode = invalid
      errorCode = ""
    end if
    userErrorCode = getUserFacingErrorCode(m.constants.errors.context.playerScreen, m.constants.errors.subtypes.playerPlaybackError, errorCode.toStr())

    videoId = 0
    if videoPlayer <> invalid and videoPlayer.content <> invalid and videoPlayer.content.id <> invalid
      videoId = videoPlayer.content.id.toInt()
    end if

    dialogEvent = {
      type: "dialog"
      values: {
        dialog_type: "PLAYER_ERROR"
        pageOneof: m.Tracking.getAnalyticsPage("video_page", { video_id: videoId })
        dialog_action: "SHOW"
        dialog_sub_type: userErrorCode
      }
    }

    modalInfo = {
      message: getErrorMessage(errorMessage, userErrorCode)
      openTrackEvent: dialogEvent
      trackingTask: m.trackingLoggingTask
    }

    showErrorModal(modalInfo, onRetryPlayerError, invalid)
  end if
end function


function onRetryPlayerError()
  ' try to resume the video from the last checkpoint
  screen = currentScreen()
  if screen.isSubtype("DetailScreen") = true
    if screen.watchTrailerSelected = true
      trailerHelper(screen)
    else
      resumeHelper(screen)
    end if
  end if
end function


' helper function for adding series title metadata to content returned from the up next API.
' @content: episode content node with metadata from the up next api
' @oldContent: episode content with full metadata, including parentType (usually from the player)
function addSeriesTitle(content, oldContent)
  if content.parentId <> invalid and oldContent.parentId <> invalid
    if oldContent.parentId <> "" and content.parentId = oldContent.parentId
      content.parentType = "series"
      content.parentTitle = oldContent.parentTitle
    end if
  end if

  return content
end function


function getSprites(content)
  if content <> invalid
    spritesReqInfo = m.cmsApi.thumbnailsReqInfo(content.id)
    m.makeRequest({
      url: spritesReqInfo.url
      requestType: m.constants.reqNames.getThumbnails
      options: spritesReqInfo.options
      successCallback: onSpritesResponse
      responseType: "node"
      silenceCallbackWarnings: true
    })
  end if
end function


function onSpritesResponse(sprites)
  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.videoPlayerScreen)
  if videoPlayer <> invalid
    videoPlayer.sprites = sprites
  end if
end function

function onUpNextCuepointReached(msg)
  videoPlayer = msg.getRoSGNode()
  if m.upNextRequest = invalid
    if videoPlayer.content <> invalid and videoPlayer.content.isTrailer = false
      m.upNextRequest = fetchUpNextContent(videoPlayer)
    end if
  end if
end function


function initVideoTracking(videoPlayer)
  if m.constants.thirdParty.youbora.enabled = true
    if videoPlayer <> invalid
      videoPlayer.observeFieldScoped("sendYouboraError", "onSendYouboraError")
      m.youboraTask = m.top.createChild("YBPluginRokuVideo")
      m.youboraTask.id = "Youbora"
      m.youboraTask.options = m.constants.thirdParty.youbora.config
      m.youboraTask.videoplayer = videoPlayer.findNode("VideoNode")
      m.global.addFields({ YouboraLogActive: m.constants.thirdParty.youbora.debug })
      m.youboraTask.control = "RUN"
    end if
  end if
end function


function onVideoTrackingStart(msg)
  tubiLog("VideoHelpers.onVideoTrackingStart")
  videoPlayer = msg.getRoSGNode()
  ' Youbora events
  if m.constants.thirdParty.youbora.enabled = true
    youboraConfig = m.constants.thirdParty.youbora.config

    if videoPlayer <> invalid and videoPlayer.content <> invalid
      youboraConfig["extraparam.1"] = videoPlayer.content.id
      youboraConfig["content.id"] = videoplayer.content.id
      
      playbackType = videoplayer.content.drmType
      youboraConfig["content.playbackType"] = playbackType
      
      if isString(playbackType)
        playbackTypeArray = playbackType.split("_")
        if playbackTypeArray[1] <> invalid
          youboraConfig["content.drm"] = playbackTypeArray[1]
        end if
      end if
      
      youboraConfig.tvShow = Mid(videoplayer.content.parentId, 2)
    end if

    if m.global.authInfo <> invalid
      youboraConfig.username = m.global.authInfo.userId
    end if

    if videoplayer.content.type = m.constants.ui.contentTypes.linear
      youboraConfig["content.isLive"] = true
    else 
      youboraConfig["content.isLive"] = false
    end if

    youboraConfig["content.transactionCode"] = m.constants.deviceInfo.deviceId
    youboraConfig["device.model"] = m.constants.deviceInfo.model
    youboraConfig["app.releaseVersion"] = m.constants.settings.version

    m.youboraTask.options = youboraConfig
    m.youboraTask.event = { handler: "play" }
  end if
end function


function videoTrackingStop()
  if m.constants.thirdParty.youbora.enabled = true
    m.youboraTask.event = { handler: "stop" }
  end if
end function


' We observe the VideoNode state change and when the state = "error", the call back chain of events
' eventually sets VideoNode.control = "stop". Due to an idiosyncracy in Roku behavior, this prevents
' the Youbora plugin from observing the error state on the video node, and so, we must manually trigger
' the Youbora plugin with the error info.
function onSendYouboraError(msg)
  videoPlayer = msg.getRoSGNode()
  if videoPlayer <> invalid
    m.youboraTask.event = {
      handler: "error"
      params: {
        "msg": videoplayer.videoErrorMsg,
        "errorCode": videoplayer.videoErrorCode.ToStr()
      }
    }
  end if
end function


' set up and make the request for Up Next / Autoplay content
' this should get invoked in response to the following scenarios
' 1) reaching the creditsCuePoint
' 2) seeking to a point beyond the creditsCuePoint
' 3) selecting the "go to next" or "advance" button on the transport
' @videoPlayer: roSGNode, the instance of the video player that contains the content for which the
'                         upNext request will be mad
' returns invalid if there is no videoPlayer or valid videoPlayerContent
function fetchUpNextContent(videoPlayer)
  if videoPlayer <> invalid and videoPlayer.content <> invalid and videoPlayer.content.id.Len() > 0
    options = {
      params: {
        "isKidsMode": shouldKidsModeBeSentToServer()
        "container_id": m.autoplayContext
        "mode": "nap"
      }
    }

    if videoPlayer.analyticsMode = "autoplay-automatic"
      options.params.mode = "ap"
    end if

    if m.autoplayContext = invalid
      options.params.delete("container_id")
    end if

    upNextReqInfo = m.cmsApi.upNextContentRequestInfo(videoPlayer.content.id, options)

    return m.makeRequest({
      requestType: m.constants.reqNames.getUpNextContent
      url: upNextReqInfo.url
      options: upNextReqInfo.options
      successCallback: onUpNextResponse
      errorCallback: onUpNextError
      responseType: "node"
    })
  end if
  return invalid
end function


function onUpNextResponse(upNextContent)
  tubiLog("VideoHelpers.onUpNextResponse")
  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.videoPlayerScreen)

  if videoPlayer <> invalid
    if upNextContent <> invalid
      if m.receivedGoToNextPressed = true
        firstUpNextItem = upNextContent.getChild(0)
        if firstUpNextItem <> invalid
          playUpNextContent(firstUpNextItem, "none")
        else
          returnToDetailScreenFromVideo()
        end if
      else if upNextContent.getChildCount() > 0
        videoPlayer.upNextContent = upNextContent
        videoPlayer.upNextUpdateContent = true
      end if
    end if
  else
    returnToDetailScreenFromVideo()
  end if
end function


function onUpNextError(errorInfo)
  if m.receivedGoToNextPressed = true
    returnToDetailScreenFromVideo()
  end if
end function


function onTransportVoiceResponse(msg)
  transportVoiceResponse = msg.getData()
  m.top.transportVoiceResponse = transportVoiceResponse
end function


' Getting segment bitrate from player and setting to Youbora Options
Function onSegBitrateChange(msg)
  segBitrate = msg.getData()
  if m.youboraTask <> invalid
    youboraOptions = m.youboraTask.options
    if youboraOptions <> invalid 
       rendition = constructYouboraRendition(segBitrate)
       if rendition <> invalid
         youboraOptions["content.rendition"] = rendition
         m.youboraTask.options = youboraOptions
       end if
    end if
  end if
End Function


' This method helps to construct rendition value based on segBitrate & UI resolution
' rendition format will be wxh@bitrate
Function constructYouboraRendition(segBitrate)

  rendition = invalid
  if segBitrate <> invalid
    if segBitrate < 1000
      segBitrate = segBitrate.ToStr() + "bps"
    else if segBitrate < 1000000
      segBitrate = (segBitrate/1000).ToStr() + "Kbps"
    else
      rendAux = segBitrate / 1000000.0 'Divide by mega
      rendAux = Cint(rendAux * 100) / 100.0
      segBitrate = rendAux.ToStr() + "Mbps"
    end if
    width = m.constants.deviceInfo.displayWidth.ToStr()
    height = m.constants.deviceInfo.displayHeight.ToStr()
    rendition = width + "x" + height + chr(64) + segBitrate
  end if
  return rendition
  
End Function