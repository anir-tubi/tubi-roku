'''''''''''''''''''''
' playVideoContent
'
' Helper function for onResume and onPlay to launch content
Function playVideoContent(content As Object, autoplayType As String, position=invalid As Dynamic)
  if content <> invalid
    if content.isTrailer
      m.videoPlayer.analyticsMode = "trailer"
      m.videoPlayer.observeFieldScoped("skipTrailer", "onSkipTrailer")
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
      m.videoPlayer.observeFieldScoped("sendVideoTrackingStart", "onVideoTrackingStart")
      m.videoPlayer.observeFieldScoped("goToNext", "onGoToNext")
      m.videoPlayer.enableAds = true
      if m.top.deepLinkContent <> invalid
        m.videoPlayer.deeplinkSource = m.top.deepLinkContent.source
      end if
      ' preload autoplay content;  We don't observe 'error' or 'response' fields
      ' since they will be evaluated at the creditsCuepoint callback
      if m.upNextTask = invalid
        ' m.upNextTask can't just be overwritten, or else it creates two UpNextTasks.
        ' When m.upNextTask.control = "RUN" happens if it was overwritten, the task's functionName
        ' actually runs for each of the tasks that had been ever been assigned to m.upNextTask.
        ' This becomes an issue if a user selects play multiple times.
        m.upNextTask = CreateObject("roSGNode", "UpNextTask")
      end if
      request = {}
      request.contentId = content.id
      if m.autoplayContext <> invalid
        request.categoryId = m.autoplayContext
      end if
      m.upNextTask.request = request
      m.upNextTask.control = "RUN"
    end if
    m.videoPlayer.observeFieldScoped("state", "onVideoPlayerState")
    m.videoPlayer.observeFieldScoped("backButtonPressed", "onVideoPlayerBackPressed")
    m.videoPlayer.visible = true
    m.videoPlayer.setFocus(true)
  
    ' Clone the content so we don't have listeners affecting it
    parent = CreateObject("roSGNode", "TubiContentNode")
    localContent = content.clone(false)
    if position <> invalid
      localContent.nowPos = position
    end if
    parent.appendChild(localContent)
    m.videoPlayer.playlist = parent
    m.videoPlayer.loopPlaylist = false
    m.videoPlayer.seekPlaylist = [0, localContent.nowPos]
    m.ScreenStack.visible = false

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
  if m.videoPlayer.creditsPosition > 0 and m.upNextTask <> invalid and m.upNextTask.response <> invalid and m.upNextTask.request <> invalid and currentContent <> invalid and m.upNextTask.request.contentId = currentContent.id
    if m.upNextTask.response.getChildCount() > 0
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
  end if
End Function


' This happens if the "next video" button has been pressed on the player transport
Function onGoToNext()
  nextContent = m.upNextTask.response.getChild(0)
  oldContent = m.videoPlayer.content

  nextContent = addSeriesTitle(nextContent, oldContent)
  stopVideoContent(m.constants.player.playerResults.completed, false)
  playVideoContent(nextContent, "none") 'TODO: FIND OUT IF THIS COUNTS AS AUTOPLAY?
End Function


' @nextContent: roSGNode, the content node representing the content that will be played next
' @ autoplayType: string, "deliberate" or "automatic", refers to if the up next content was selected or is auto playing
Function playUpNextContent(nextContent, autoplayType)
  oldContent = m.videoPlayer.content
  content = addSeriesTitle(nextContent, oldContent)
  stopVideoContent(m.constants.player.playerResults.completed, false)
  playVideoContent(content, autoplayType)
  popScreen(false) ' pop the up next screen off the screen stack
  m.upNextScreen.unobserveFieldScoped("contentSelected")
  m.upNextScreen.unobserveFieldScoped("timeout")
  m.upNextScreen.unobserveFieldScoped("backPressed")
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
  m.upNextScreen = invalid
  popScreen(false) 'pop the up next screen off the screen stack
  if m.videoPlayer.state = "finished"
    ' up next was dismissed but playback had already finished
    returnToDetailScreenFromVideo(m.constants.player.playerResults.completed)
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
    stopVideoContent(m.constants.player.playerResults.failed, true)
    errorMessage = m.constants.player.playerResults.failed
    if m.videoPlayer.errorMsg <> ""
      errorMessage = m.videoPlayer.errorMsg
    end if
    m.videoPlayer.errorMessage = ""
    showPlayerError(errorMessage)
  else if state = "finished"
    ' If trailer, play the feature
    finishedContent = m.videoPlayer.playlist.getChild(m.videoPlayer.playlistIndex)
    if finishedContent.isTrailer
      content = getDetailScreenContent()
      if content <> invalid then
        stopVideoContent(m.constants.player.playerResults.completed, false)
        playVideoContent(content, "none", 0)  ' always start at zero here
      else
        ' just show the current screen on the screen stack
        stopVideoContent(m.constants.player.playerResults.completed, true)
      end if

    ' If not a trailer, look for UpNext content to play
    else
      if m.upNextScreen <> invalid and currentScreen().isSameNode(m.upNextScreen)
        tubiLog("Ignoring video state 'finished' while UpNextScreen is visible")
      else if m.upNextTask <> invalid and m.upNextTask.response <> invalid and m.upNextTask.response.getChild(0) <> invalid
        'this happens if the video plays all the way to the end and does an autoplay
        nextContent = m.upNextTask.response.getChild(0)
        oldContent = m.videoPlayer.content

        nextContent = addSeriesTitle(nextContent, oldContent)
        stopVideoContent(m.constants.player.playerResults.completed, false)
        playVideoContent(nextContent, "automatic")
      else
        returnToDetailScreenFromVideo(m.constants.player.playerResults.completed)
      end if
    end if
  end if
End Function


Function onVideoPlayerBackPressed()
  tubiLog("VideoHelpers.onVideoPlayerBackPressed")
  returnToDetailScreenFromVideo(m.constants.player.playerResults.closed)
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
Function returnToDetailScreenFromVideo(result)
  stopVideoContent(result, true)
  ' get updated content, to be used to reload or re-populate details screen
  content = m.videoPlayer.playlist.getChild(m.videoPlayer.playlistIndex) 'this always returns a video - sometimes an episode
  m.top.deepLinkContent = invalid
  if content <> invalid
    if content.isTrailer
      ' Action 5
      content = getDetailScreenContent()
    else if content.parentType = m.constants.ui.contentTypes.series
      ' Action 3
      currentEpisodeId = content.id
      content = getDetailScreenContent()
      if content <> invalid
        content.currentEpisodeId = currentEpisodeId
      end if
    else if content.id <> invalid and getDetailScreenContent() <> invalid and getDetailScreenContent().id <> invalid and content.id = getDetailScreenContent().id  ' no autoplay - same content as already on detail screen
      ' Action 1
      content = getDetailScreenContent()
    end if
  end if

  'reload or re-populate the screen as necessary
  if currentScreen() <> invalid and currentScreen().subType() = "DetailScreen"
    if currentScreen().content <> invalid and currentScreen().content.id = content.id
      '//So the detailed page does not have a refresh issue, pass the local resume number before the backend communicates.
      nResumePoint = m.videoPlayer.historyPosition '//The problem with this is that if the backend comes back with a different number than the local number then there is still a screen redraw issue: i.e. user watches only 2 seconds of a video. The local number is 2 seconds and displays the resume button, but the backend determines that 2 seconds is not enough to warrant a resume button and returns 0 as the resume point.

      if nResumePoint < m.constants.player.historyFrequency or (m.videoPlayer.creditsPosition > 0 and nResumePoint > m.videoPlayer.creditsPosition)
        '//If the video is either at the very beginning or at the very end, then it should pass the local resume point as 0
        nResumePoint = 0
      end if
      ' Action 1, 3, 5 - same content so just re-populate screen with any updates
      populateDetailScreen(currentScreen(), content, true, nResumePoint)
    else
      ' Action 2 - new content so tear down the screen and rebuild it
      popScreen(false)
      showDetailScreen(content)
    end if
  else
    ' This is a safety, but no code paths actually lead here currently 2.5.111
    showDetailScreen(content)
  end if
End Function


' Stop the video player and optionally return to the screen stack
Function stopVideoContent(playerResult, showScreenStack)
  tubiLog("VideoHelpers.stopVideoContent")
  videoTrackingStop()
  m.videoPlayer.unobserveFieldScoped("backButtonPressed")
  m.videoPlayer.unobserveFieldScoped("state")
  m.videoPlayer.unobserveFieldScoped("skipTrailer")
  m.videoPlayer.unobserveFieldScoped("historyPosition")
  m.videoPlayer.unobserveFieldScoped("creditsPosition")
  m.videoPlayer.unobserveFieldScoped("sendVideoTrackingStart")
  m.videoPlayer.unobserveFieldScoped("goToNext")
  m.videoPlayer.deeplinkSource = ""
  m.videoPlayer.control = "stop"
  playerInfo = {}
  playerInfo.nowPos = m.videoPlayer.historyPosition
  playerInfo.result = playerResult
  if m.updateHistoryTask.historyResult <> invalid
    playerInfo.historyId = m.updateHistoryTask.historyResult.historyId
    playerInfo.parentHistoryId = m.updateHistoryTask.historyResult.parentHistoryId
  end if
  tubiLog("stopVideoContent: nowPos = " + playerInfo.nowPos.toStr())
  if playerInfo.historyId <> invalid and playerInfo.historyId <> "" then
    tubiLog("stopVideoContent: historyId = " + playerInfo.historyId.toStr())
  end if
  if playerInfo.parentHistoryId <> invalid and playerInfo.parentHistoryId <> "" then
    tubiLog("stopVideoContent: parentHistoryId = " + playerInfo.parentHistoryId.toStr())
  end if

  stoppedContent = m.videoPlayer.content
  if stoppedContent <> invalid and stoppedContent.isTrailer = true
    m.trackingLoggingTask.trackEvent({
      type: "finish_trailer"
      values: {
        video_id: stoppedContent.id.toInt()
        end_position: playerInfo.nowPos
        reason: "DETECTED"  'Reason enum
      }
    })
  end if

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
  stopVideoContent(m.constants.player.playerResults.completed, false)
  playVideoContent(getDetailScreenContent(), "none")
End Function


'''''''''''''''''''
' onPlayerError
'
Function showPlayerError(errorMessage As String)
  tubiLog("VideoHelpers.showPlayerError")
  showErrorModal(0, errorMessage, onRetryPlayerError, [], onCancelPlayerError, [])
  videoId = 0
  if m.videoPlayer <> invalid and m.videoPlayer.content <> invalid and m.videoPlayer.content.id <> invalid
    videoId = m.videoPlayer.content.id.toInt()
  end if
  m.trackingLoggingTask.trackEvent = {
    type: "dialog"
    values: {
      dialog_type: "WARNING" 'DialogType enum
      pageOneof: m.Tracking.getAnalyticsPage("video_page", {video_id: videoId})
    }
  }
End Function


Function onRetryPlayerError()
  ' reset the video player state in case trying to resume causes an error again
  m.videoPlayer.state = ""
  ' try to resume the video from the last checkpoint
  screen = currentScreen()
  if screen.isSubtype("DetailScreen") = true
    resumeHelper(screen)
  end if
End Function


Function onCancelPlayerError()
  ' reset the video player state in case an error occurs during the next attempt at playing a video
  m.videoPlayer.state = ""

  top = currentScreen()
  if top <> invalid then
    top.setFocus(true)
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