'''''''''''''''''''''
' playVideoContent
'
' Helper function for onResume and onPlay to launch content
Function playVideoContent(content As Object, autoplayType As String, position=0 As Integer)

  m.videoPlayer.shouldMakeNextRequest = true
  if m.upNextTask <> invalid
    m.upNextTask.response = invalid
  end if

  if content <> invalid
    if content.isTrailer
      m.videoPlayer.analyticsMode = "trailer"
      m.videoPlayer.observeFieldScoped("skipTrailer", "onSkipTrailer")
      m.videoPlayer.observeFieldScoped("goToNext", "onSkipTrailer")
      m.videoPlayer.enableAds = false
      m.upNextTask = invalid
    else
      m.videoPlayer.analyticsMode = "normal"
      if autoplayType = "automatic"
        m.videoPlayer.analyticsMode = "autoplay-automatic"
      else if autoplayType = "deliberate"
        m.videoPlayer.analyticsMode = "autoplay-deliberate"
      end if

      m.videoPlayer.observeFieldScoped("historyPosition", "onEpisodePosition")
      m.videoPlayer.observeFieldScoped("creditsPosition", "onEpisodeCredits")
      m.videoPlayer.observeFieldScoped("goToNext", "onGoToNext")
      m.videoPlayer.observeFieldScoped("fetchNextContent", "onFetchNextContent")

      m.videoPlayer.enableAds = true
      if m.constants.settings.suitest = true or m.constants.settings.noAds = true
        m.videoPlayer.enableAds = false
      end if
    end if

    '//Stop the background artwork from transitioning 
    m.backgroundGroup.backgroundInfo = {
      type: m.constants.ui.backgroundTypes.fullScreen
      uriList: []
    }
    m.videoPlayer.observeFieldScoped("state", "onVideoPlayerState")
    m.videoPlayer.observeFieldScoped("backButtonPressed", "onVideoPlayerBackPressed")
    m.videoPlayer.observeFieldScoped("sendVideoTrackingStart", "onVideoTrackingStart")
    m.videoPlayer.visible = true
    m.videoPlayer.setFocus(true)
  
    ' Clone the content so we don't have listeners affecting it
    parent = CreateObject("roSGNode", "TubiContentNode")
    localContent = content.clone(false)
    
    creditsCuepoint = localContent.creditscuepoint
    videoLength = localContent.length
    
    if position >= creditsCuepoint or (videoLength - position) <= 5
      position = 0
    end if
    localContent.nowPos = position

    parent.appendChild(localContent)
    m.videoPlayer.playlist = parent
    m.videoPlayer.loopPlaylist = false
    m.videoPlayer.seekPlaylist = [0, localContent.nowPos]
    m.ScreenStack.visible = false

    fireAppLoadBeacon()

    ' For position history tracking
    m.updateHistoryTask.historyResult = invalid
    m.updateHistoryTask.content = localContent
  end if
End Function


''''''''''''''''''''''
' onEpisodePosition
'
' Update the resume position
' This function triggers when the video stops as well as when m.videoPlayer.historyPosition is updated
Function onEpisodePosition()
  tubiLog("VideoHelpers.onEpisodePosition")
  ' Don't send history updates to the server if the user hasn't watched at least a certain amount of video
  history = m.global.historyIds.findNode(m.updateHistoryTask.content.id)
  if history <> invalid or m.videoPlayer.historyPosition > m.constants.player.historyFrequency
    ' Only run a new task if the previous task is done.  Priority of resume states is
    ' pretty low and we don't mind losing a few.
    if m.updateHistoryTask.state <> "RUN"   
      m.updateHistoryTask.nowPos = m.videoPlayer.historyPosition
      m.updateHistoryTask.control = "RUN"
    end if
  end if
End Function


Function onEpisodeCredits()
  tubiLog("VideoHelpers.onEpisodeCredits")
  ' Verify that the UpNextTask has a response and it matches the currently playing content
  currentContent = m.videoPlayer.playlist.getChild(m.videoPlayer.playlistIndex)
  if m.upNextTask <> invalid and m.upNextTask.response <> invalid and m.upNextTask.request <> invalid and currentContent <> invalid and m.upNextTask.request.contentId = currentContent.id
    if m.videoPlayer.creditsPosition > 0 and m.upNextTask.response.getChildCount() > 0
      if m.upNextScreen <> invalid
        m.upNextScreen.unobserveFieldScoped("contentSelected")
        m.upNextScreen.unobserveFieldScoped("backPressed")
        m.upNextScreen.unobserveFieldScoped("timeout")
        m.upNextScreen.unobserveFieldScoped("navigateWithinPageInfo")
        m.upNextScreen = invalid
      end if
      m.upNextScreen = CreateObject("roSGNode", "UpNextScreen")
      m.upNextScreen.observeFieldScoped("contentSelected", "onUpNextContentSelected")
      m.upNextScreen.observeFieldScoped("backPressed", "onUpNextBackPressed")
      m.upNextScreen.observeFieldScoped("timeout", "onUpNextTimeout")
      m.upNextScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
      m.upNextScreen.videoId = m.videoPlayer.content.id
      m.upNextScreen.content = m.upNextTask.response
      pushScreen(m.upNextScreen, false, false)
      m.ScreenStack.visible = true

      m.trackingLoggingTask.trackEvent = {
        type: "auto_play"
        values: {
          video_id: m.videoPlayer.content.id.toInt()
          auto_play_action: "SHOW" 'AutoPlayAction enum
        }
      }
    end if
  else
    m.videoPlayer.creditsPosition = 0   
  end if
End Function


' This happens if the "next video" button has been pressed on the player transport
Function onGoToNext()

  if m.upNextTask <> invalid and m.upNextTask.response <> invalid and m.upNextTask.response.getChild(0) <> invalid
    nextContent = m.upNextTask.response.getChild(0)
    oldContent = m.videoPlayer.content

    nextContent = addSeriesTitle(nextContent, oldContent)
    stopVideoContent(false)
    playVideoContent(nextContent, "none") 'TODO: FIND OUT IF THIS COUNTS AS AUTOPLAY?
  else if m.videoPlayer.shouldMakeNextRequest = true
    onFetchNextContent()
  else
    returnToDetailScreenFromVideo()
  end if
    
End Function


' @nextContent: roSGNode, the content node representing the content that will be played next
' @ autoplayType: string, "deliberate" or "automatic", refers to if the up next content was selected or is auto playing
Function playUpNextContent(nextContent, autoplayType)
  tubiLog("VideoHelpers.playUpNextContent")
  oldContent = m.videoPlayer.content
  content = addSeriesTitle(nextContent, oldContent)
  stopVideoContent(false)
  popScreen(false) ' pop the up next screen off the screen stack
  playVideoContent(content, autoplayType)
  if m.upNextScreen <> invalid
    m.upNextScreen.unobserveFieldScoped("contentSelected")
    m.upNextScreen.unobserveFieldScoped("timeout")
    m.upNextScreen.unobserveFieldScoped("backPressed")
  end if
  m.upNextScreen = invalid
End Function


Function onUpNextTimeout()
  tubiLog("VideoHelpers.onUpNextTimeout")
  playUpNextContent(m.upNextScreen.contentFocused, "automatic")
End Function


' Triggered by either a button press or by timer expiration
Function onUpNextContentSelected()
  tubiLog("VideoHelpers.onUpNextContentSelected")
  playUpNextContent(m.upNextScreen.contentSelected, "deliberate")
  m.lastUserActivity = Uptime(0)
End Function


Function onUpNextBackPressed()
  tubiLog("VideoHelpers.onUpNextBackPressed")
  ' remove the screen and put focus back on the video player transport
  m.upNextScreen.unobserveFieldScoped("contentSelected")
  m.upNextScreen.unobserveFieldScoped("backPressed")
  focusedVideo = invalid
  if m.upNextScreen <> invalid 
    focusedVideo = m.upNextScreen.contentFocused
  end if
  m.upNextScreen = invalid
  popScreen(false) 'pop the up next screen off the screen stack
  if m.videoPlayer.state = "finished"
    ' up next was dismissed but playback had already finished
    if focusedVideo <> invalid
      '//go to next upNext video that was last focused
      playUpNextContent(focusedVideo, "automatic")
    else
      returnToDetailScreenFromVideo()
    end if
  else
    m.ScreenStack.visible = false
    m.videoPlayer.setFocus(true)
  end if
  m.lastUserActivity = Uptime(0)
    m.trackingLoggingTask.trackEvent = {
    type: "auto_play"
    values: {
      video_id: m.videoPlayer.content.id.toInt()
      auto_play_action: "DISMISS" 'AutoPlayAction enum
    }
  }
End Function


Function onVideoPlayerState(msg)
  tubiLog("VideoHelpers.onVideoPlayerState state = " + msg.GetData())
  state = msg.GetData()
  if state = "error"
    stopVideoContent(true)
    errorMessage = getTranslation("videoPlayer_error_failed_description")
    if m.videoPlayer.errorMsg <> ""
      errorMessage = m.videoPlayer.errorMsg
    end if
    m.videoPlayer.errorMsg = ""
    showPlayerError(errorMessage, m.videoPlayer.videoErrorCode)
  else if state = "finished"
    ' If trailer, play the feature
    finishedContent = m.videoPlayer.playlist.getChild(m.videoPlayer.playlistIndex)
    if finishedContent.isTrailer
      returnToDetailScreenFromVideo()

    ' If not a trailer, look for UpNext content to play
    else
      if m.upNextScreen <> invalid and currentScreen().isSameNode(m.upNextScreen)
        tubiLog("Ignoring video state 'finished' while UpNextScreen is visible")
      else if m.upNextTask <> invalid and m.upNextTask.response <> invalid and m.upNextTask.response.getChild(0) <> invalid
        'this happens if the video plays all the way to the end and does an autoplay
        nextContent = m.upNextTask.response.getChild(0)
        oldContent = m.videoPlayer.content

        nextContent = addSeriesTitle(nextContent, oldContent)
        stopVideoContent(false)
        playVideoContent(nextContent, "automatic")
      else
        returnToDetailScreenFromVideo()
      end if
    end if
  end if
End Function


Function onVideoPlayerBackPressed()
  tubiLog("VideoHelpers.onVideoPlayerBackPressed")
  returnToDetailScreenFromVideo()
End Function


' Stop the video player and refresh detail screen with the relevant content
'
' Use cases:                                                Actions:
'   - Exit video player movie                              : 1 - redraw detail screen with existing detail content to preserve related items
'   - Exit video player movie after autoplay               : 2 - replace detail screen and fetch full content with related items
'   - Exit video player series                             : 3 - redraw detail screen with existing detail content to preserve related items, updating episode id
'   - Exit video player series after autoplay              : 3 - redraw detail screen with existing detail content to preserve related items, updating episode id
'   - Exit video player trailer                            : 5 - redraw detail screen with existing detail content to preserve related items
'   - Deep link: exit video player movie                   : 1 - redraw detail screen with existing detail content to preserve related items
'   - Deep link: exit video player movie after autoplay    : 2 - replace detail screen and fetch full content with related items
'   - Deep link: Exit video player series                  : 3 - redraw detail screen with existing detail content to preserve related items, updating episode id
'   - Deep link: Exit video player series after autoplay   : 3 - redraw detail screen with existing detail content to preserve related items, updating episode id
Function returnToDetailScreenFromVideo()
  stopVideoContent(true)
  curScreen = currentScreen()
  ' get updated content, to be used to reload or re-populate details screen
  content = m.videoPlayer.playlist.getChild(m.videoPlayer.playlistIndex) 'this always returns a video - sometimes an episode
  m.deepLinkContent = invalid
  if content <> invalid
    if content.isTrailer
      ' Action 5
      content = getDetailScreenContent()
    else if content.parentType = m.constants.ui.contentTypes.series
      ' Action 3
      currentEpisodeId = content.id

      if curScreen <> invalid and curScreen.id = m.constants.ui.screenIds.episodeScreen
        content = curScreen.content
      else
        content = getDetailScreenContent() 'can be invalid
      end if

      if content <> invalid
        content.currentEpisodeId = currentEpisodeId
      end if
    else if content.id <> invalid and getDetailScreenContent() <> invalid and getDetailScreenContent().id <> invalid and content.id = getDetailScreenContent().id  ' no autoplay - same content as already on detail screen
      ' Action 1
      content = getDetailScreenContent()
    end if
  end if

  'reload or re-populate the screen as necessary
  if curScreen <> invalid
    if curScreen.id = m.constants.ui.screenIds.detailScreen or curScreen.id = m.constants.ui.screenIds.episodeScreen
      ' find the detail screen
      detailScreen = invalid
      if curScreen.id = m.constants.ui.screenIds.episodeScreen
        ' update the episode screen if necessary
        episodeScreen = curScreen
        episodeScreen.content = content
        episodeScreen.updateContent = true
        episodeScreen.episodeToFocus = findEpisode2dIndex(content.currentEpisodeId, content)
        hiddenScreen = getHiddenScreen(1)
        if hiddenScreen <> invalid and hiddenScreen.id = m.constants.ui.screenIds.detailScreen
          detailScreen = hiddenScreen
        end if
      else if curScreen.id = m.constants.ui.screenIds.detailScreen
        detailScreen = curScreen
      end if

      if detailScreen <> invalid and detailScreen.content <> invalid and detailScreen.content.id = content.id
        '//So the detailed page does not have a refresh issue, pass the local resume number before the backend communicates.
        nResumePoint = m.videoPlayer.historyPosition '//The problem with this is that if the backend comes back with a different number than the local number then there is still a screen redraw issue: i.e. user watches only 2 seconds of a video. The local number is 2 seconds and displays the resume button, but the backend determines that 2 seconds is not enough to warrant a resume button and returns 0 as the resume point.

        if nResumePoint < m.constants.player.historyFrequency or (m.videoPlayer.creditsPosition > 0 and nResumePoint > m.videoPlayer.creditsPosition)
          '//If the video is either at the very beginning or at the very end, then it should pass the local resume point as 0
          nResumePoint = 0
        end if
        ' Action 1, 3, 5 - same content so just re-populate screen with any updates
        populateDetailScreen(curScreen, content, true, nResumePoint)
      else
        ' Action 2 - new content so tear down the details screen and rebuild it
        popScreen(false)
        showDetailScreen(content)
      end if
    else
      'this can happen in the edge case of where ad playback happens after the autoplay UI has started and a user backs out of the ad
      'leading to the UpNextScreen being at the top of the screen stack when the VideoPlayer.backButtonPressed field is triggered.
      curScreen.setFocus(true)
    end if
  end if
End Function


' Stop the video player and optionally return to the screen stack
Function stopVideoContent(showScreenStack)
  tubiLog("VideoHelpers.stopVideoContent")
  if m.upNextScreen <> invalid 
    m.upNextScreen.stopAutoPlayTimer = true
  end if
  videoTrackingStop()
  m.videoPlayer.unobserveFieldScoped("backButtonPressed")
  m.videoPlayer.unobserveFieldScoped("state")
  m.videoPlayer.unobserveFieldScoped("skipTrailer")
  m.videoPlayer.unobserveFieldScoped("historyPosition")
  m.videoPlayer.unobserveFieldScoped("creditsPosition")
  m.videoPlayer.unobserveFieldScoped("sendVideoTrackingStart")
  m.videoPlayer.unobserveFieldScoped("goToNext")
  m.videoPlayer.unobserveFieldScoped("fetchNextContent")
  m.videoPlayer.control = "stop"
  nowPos = m.videoPlayer.historyPosition

  historyId = invalid
  parentHistoryId = invalid
  if m.updateHistoryTask.historyResult <> invalid
    historyId = m.updateHistoryTask.historyResult.historyId
    parentHistoryId = m.updateHistoryTask.historyResult.parentHistoryId
  end if

  tubiLog("stopVideoContent: nowPos = " + nowPos.toStr())
  if historyId <> invalid and historyId <> "" then
    tubiLog("stopVideoContent: historyId = " + historyId.toStr())
  end if
  
  if parentHistoryId <> invalid and parentHistoryId <> "" then
    tubiLog("stopVideoContent: parentHistoryId = " + parentHistoryId.toStr())
  end if

  stoppedContent = m.videoPlayer.content

  ' reload history
  onHistoryQueueChange(m.constants.ui.categoryIds.history) 

  ' should only do this if not autoplaying another video
  if showScreenStack
    m.videoPlayer.visible = false
    m.ScreenStack.visible = true

    current = currentScreen()
    if current <> invalid
      current.setFocus(true)
    end if
  end if
End Function


Function onSkipTrailer()
  tubiLog("VideoHelpers.onSkipTrailer")
  stopVideoContent(false)
  playVideoContent(getDetailScreenContent(), "none")
End Function


'''''''''''''''''''
' onPlayerError
'
' @errorMessage: string, an error message that will be displayed to the user
' @errorCode: integer, the video player error code (usually a negative number)
Function showPlayerError(errorMessage, errorCode)
  tubiLog("ContentController.showPlayerError")

  ' reset the video player state in case an error occurs during the next attempt at playing a video
  m.videoPlayer.state = ""

  if errorCode = invalid
    errorCode = ""
  end if
  userErrorCode = getUserFacingErrorCode(m.constants.errors.context.playerScreen, m.constants.errors.subtypes.playerPlaybackError, errorCode.toStr())

  videoId = 0
  if m.videoPlayer <> invalid and m.videoPlayer.content <> invalid and m.videoPlayer.content.id <> invalid
    videoId = m.videoPlayer.content.id.toInt()
  end if

  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: "WARNING" 'DialogType enum - TODO: Update this when a "PLAYER_ERROR" value becomes available in protos
      pageOneof: m.Tracking.getAnalyticsPage("video_page", {video_id: videoId})
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
End Function


Function onRetryPlayerError()
  ' try to resume the video from the last checkpoint
  screen = currentScreen()
  if screen.isSubtype("DetailScreen") = true
    resumeHelper(screen)
  end if
End Function


' helper function for adding series title metadata to content returned from the up next API.
' @content: episode content node with metadata from the up next api
' @oldContent: episode content with full metadata, including parentType (usually from the player)
Function addSeriesTitle(content, oldContent)
  if content.parentId <> invalid and oldContent.parentId <> invalid
    if oldContent.parentId <> "" and content.parentId = oldContent.parentId
      content.parentType = "series"
      content.parentTitle = oldContent.parentTitle
    end if
  end if

  return content
End Function


' this callback gets invoked when the fetchNextContent interface is set
' this method helps to invoke next autoplay content
Function onFetchNextContent()

  content = m.videoPlayer.content

  ' preload autoplay content;  We don't observe 'error' or 'response' fields
  ' since they will be evaluated at the creditsCuepoint callback
  if m.upNextTask = invalid
    ' m.upNextTask can't just be overwritten, or else it creates two UpNextTasks.
    ' When m.upNextTask.control = "RUN" happens if it was overwritten, the task's functionName
    ' actually runs for each of the tasks that had been ever been assigned to m.upNextTask.
    ' This becomes an issue if a user selects play multiple times.
    m.upNextTask = CreateObject("roSGNode", "UpNextTask")
    m.upNextTask.observeField("response", "onFetchResponseReceived")
  end if
  request = {}
  request.contentId = content.id
  if m.autoplayContext <> invalid
    request.categoryId = m.autoplayContext
  end if

  mode = "nap"
  if m.videoPlayer.analyticsMode = "autoplay-automatic"
    mode = "ap"
  end if
  request.mode = mode
  request.kidsMode = shouldKidsModeBeSentToServer()

  if m.videoPlayer.shouldMakeNextRequest = true
    m.videoPlayer.shouldMakeNextRequest = false
    m.upNextTask.request = request
    m.upNextTask.control = "RUN" 
  end if

End Function

' this callback gets invoked once the response output is set in UpNextTask
' this sets the shouldMakeNextRequest interface as true
Function onFetchResponseReceived()

  if m.upNextTask <> invalid and m.upNextTask.response <> invalid
    if m.videoPlayer.playNext = true
      onGoToNext()
    end if
  end if

End Function