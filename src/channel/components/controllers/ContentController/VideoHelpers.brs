'''''''''''''''''''''
' playVideoContent
'
' Helper function for onResume and onPlay to launch content
' @content: TubiContentNode, the content to be played, can be a movie, episode, or trailer
' @playbackSource: associative Array, format : srcForAnalytic - this value is used for sending analytics;
'                                                   valid values are "automatic", "deliberate", "unknown" or "previews"
'                                               srcForAds - used for rainmaker request
'                                                    valid values are "deeplink" , "ap_auto", "ap_select", "container", "ymal", "search", "epg", "unknown"

'                                               playbackContainer - if srcForAds = container, then playbackContainer is set to the id of the container that was the source, otherwise not used.

' @position: integer, the position from which to start video playback
Function playVideoContent(content, playbackSource = {"srcForAnalytic": "unknown", "srcForAds": "unknown"}, position = 0)
  tubiLog("VideoHelpers.playVideoContent")
  if content <> invalid and (content.needsLogin = true AND isLoggedInUser() = false) 'Check for user sign in status because we do not refetch the content and so it will not pass through metadata translate process.
    callbackAfterSignInParams = {"content": content, "playbackSource": playbackSource, "position": position}
    startSignIn(AfterSignInPlayLockedContent, callbackAfterSignInParams)
  else
  videoPlayer = setupVideoPlayer(content, playbackSource, position)

  currentScreen = getCurrentScreen()

  if currentScreen = invalid or currentScreen.id <> m.constants.ui.screenIds.videoPlayerScreen
    if m.enteredFromDeepLink = true
      ' if the user has been age gated during the deeplink process, a modal will be shown.
      ' We need to remove the modal so it is not overlaying the video.
      modal = getTopModal()
      if modal <> invalid AND (modal.isSubtype("ModalDialogScreen") OR modal.subType() = "MultiStyleDialogScreen") AND modal.isInFocusChain() = true
        closeModal(modal)
      end if

      pushScreen(videoPlayer, false, true)
    else
      pushScreen(videoPlayer, true, true)
    end if
  end if

  '//send a copy of the videoSponsorExposureId to the videoPlayer
  videoPlayer.videoSponsorExposureId = m.videoSponsorExposureId
  videoPlayer.control = "play"
  updateRokuContinueWatchingInfo(content, position)
end if
End Function



' Called when a user uses voice controls to play or presses the play button from a content screen,
' such that the detail screen is "skipped" and the NavigateToPageEvent should contain information
' about the screen where the navigation occurred and navigating to the video player screen.
' @content: roSGNode, the content node of the content to be played
' @nowPos: integer, the position from which the video playback should be resumed
' @currentTrackingPageInfo: assocArray, trackingPageInfo of the screen being navigated from
' @trackingComponentInfo: assocArray, trackingComponentInfo of the component being navigated from
Function playVideoContentWhileSkippingDetailScreen(content, nowPos, currentTrackingPageInfo, trackingComponentInfo = invalid, playbackSource = {"srcForAnalytic": "unknown", "srcForAds": "unknown"})
  if content <> invalid and content.needsLogin = true
    callbackAfterSignInParams = {"content": content, "nowPos": nowPos, "currentTrackingPageInfo": currentTrackingPageInfo, "trackingComponentInfo": trackingComponentInfo, "playbackSource": playbackSource}
    startSignIn(AfterSignInPlayLockedContentWhileSkippingDetailScreen, callbackAfterSignInParams)
  else
    videoPlayer = setupVideoPlayer(content, playbackSource, nowPos)

    ' send custom navigateToPage event, since a details screen was added to the screen stack but the user
    ' never saw it, we want to navigate from the screen under the most recently added details screen.
    if currentTrackingPageInfo <> invalid AND isNonEmptyString(currentTrackingPageInfo.pageType)
      ' but only send the navigateToPage event if there is a page to navigate from
      screenTrackingNavigate(currentTrackingPageInfo, videoPlayer.trackingPageInfo, trackingComponentInfo)
    end if

    if getCurrentScreen() = invalid or getCurrentScreen().id <> m.constants.ui.screenIds.videoPlayerScreen
      pushScreen(videoPlayer, false, true)
    end if

    '//send a copy of the videoSponsorExposureId to the videoPlayer
    videoPlayer.videoSponsorExposureId = m.videoSponsorExposureId
    videoPlayer.control = "play"
    updateRokuContinueWatchingInfo(content, nowPos)
  end if
End Function


' Helper function for onResume and onPlay to launch content
' @content: TubiContentNode, the content to be played, can be a movie, episode, or trailer
' @playbackSource: associative Array, format : srcForAnalytic - this value is used for sending analytics;
'                                                   valid values are "automatic", "deliberate", "unknown" or "previews"
'                                               srcForAds - used for rainmaker request
'                                                    valid values are "deeplink" , "ap_auto", "ap_select", "container", "ymal", "search", "epg", "unknown"

'                                               playbackContainer - if srcForAds = container, then playbackContainer is set to the id of the container that was the source, otherwise not used.
' @position: integer, the position from which to start video playback
Function setupVideoPlayer(content, playbackSource = {"srcForAnalytic": "unknown", "srcForAds": "unknown"}, position = 0)
  ' Limit to devices with 512Mb RAM as those are the most likely to crash from exceeding the memory limit during playback.
  if m.constants.deviceInfo.lowVram = true
    updateScreenCacheOnPlayback(m.constants.ui.screenIds.VideoPlayerScreen)
  end if

  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.videoPlayerScreen)

  if videoPlayer = invalid
    videoPlayer = CreateObject("roSGNode", "VideoPlayerScreen")
    videoPlayer.id = m.constants.ui.screenIds.videoPlayerScreen
    ' onVideoPlayerVisibleChange exists in ContentController
    videoPlayer.observeFieldScoped("visible", "onVideoPlayerVisibleChange")
    videoPlayer.observeFieldScoped("transportVoiceResponse", "onTransportVoiceResponse")
    videoPlayer.observeFieldScoped("getPauseAd", "onGetPauseAd")
    videoPlayer.observeFieldScoped("sendPauseAdPixel", "onSendPauseAdPixel")
    videoPlayer.observeFieldScoped("audioTrackSettings", "onAudioTrackSettingsChange")
    videoPlayer.observeFieldScoped("relatedContentToPlay", "onPlayerRelatedContentToPlay")
    initVideoTracking(videoPlayer) 'initializeYoubora
    setInScreenCache(videoPlayer)

    if getExperimentResource("roku_screensaver", "roku_screensaver_v2", false).enabled = true then
      videoPlayer.disableScreensaver = true
    end if
  end if

  ' Passing current user selected track.
  ' Moving it out so that we always pass the updated value even when screen is obtained from cache.
  if m.pub_serverPersistentData <> invalid
    videoPlayer.preferredAudioTrack = m.pub_serverPersistentData.audioTrack
  end if

  videoPlayer.relatedContent = invalid

  stopVideoPreviewIfPlaying() 'stop videopreview just in case it is playing

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

  if isKidsUIOn() = true
    videoPlayer.appMode = "KIDS_MODE"
  else if m.uiMode = m.constants.ui.modes.latino
    videoPlayer.appMode = "LATINO_MODE"
  else
    videoPlayer.appMode = "DEFAULT_MODE"
  end if

  ' resetting to default value
  videoPlayer.isTrailer = false

  if content <> invalid
    if content.isTrailer
      videoPlayer.isTrailer = true
      videoPlayer.observeFieldScoped("skipTrailer", "onSkipTrailer")
      videoPlayer.observeFieldScoped("goToNext", "onSkipTrailer")
      videoPlayer.enableAds = false
    else
      videoPlayer.playbackSource = {
        "srcForAnalytic": m.constants.player.playbackSource.unknown
        "srcForAds": playbackSource.srcForAds
        "playbackContainer": playbackSource.playbackContainer
      }

      if playbackSource.srcForAnalytic = "automatic"
        videoPlayer.playbackSource = {
          "srcForAnalytic": m.constants.player.playbackSource.autoplayAutomatic
          "srcForAds": m.constants.player.playbackOrigin.autoplay_auto
        }
      else if playbackSource.srcForAnalytic = "deliberate"
        videoPlayer.playbackSource = {
          "srcForAnalytic": m.constants.player.playbackSource.autoplayDeliberate
          "srcForAds": m.constants.player.playbackOrigin.autoplay_select
        }
      else if playbackSource.srcForAnalytic = "previews"
        videoPlayer.playbackSource = {
          "srcForAnalytic": m.constants.player.playbackSource.videoPreviews
          "srcForAds": playbackSource.srcForAds
          "playbackContainer": playbackSource.playbackContainer
        }
      end if

      if content.adParam = invalid
        content.addField("adParam", "assocarray", false)
      end if

      if position > 0
        playbackSource["resumeFrom"] = "stop"
      end if

      'set content origin and contaierID for rainmaker before playing. Setting it withing the content will help with rendezvous.
      content.adParam = playbackSource

      ' set observers for non trailer content
      videoPlayer.observeFieldScoped("historyPosition", "onEpisodePosition")
      videoPlayer.observeFieldScoped("goToNext", "onGoToNext")
      videoPlayer.observeFieldScoped("upNextCuepointReached", "onUpNextCuepointReached")
      videoPlayer.observeFieldScoped("upNextContentToAutoplay", "onUpNextContentToAutoplay")
      videoPlayer.observeFieldScoped("upNextNavigateWithinPageInfo", "onNavigateWithinPageInfoChange")
      videoPlayer.observeFieldScoped("relatedNavigateWithinPageInfo", "onNavigateWithinPageInfoChange")
      videoPlayer.observeFieldScoped("segInfo", "onSegInfoChange")

      videoPlayer.enableAds = true
      if m.constants.settings.noAds = true
        videoPlayer.enableAds = false
      end if

      sendNielsenPing(m.constants.thirdParty.nielsen.pingTypes.streamStart, content)

      if getExperimentResource("roku_browse_while_watching_ymal", "roku_browse_while_watching_ymal_v1", false).enabled = true
        getRelatedContent(content, handleRelatedResponseInVideoPlayer)
      end if
    end if

    ' by default setting sprites to invalid
    videoPlayer.sprites = invalid
    ' get sprites / seek preview images
    getSprites(content)

    '//Stop the background artwork from transitioning
    m.backgroundGroup.shouldRotateBackgrounds = false

    ' set general observers for all content (including trailers)
    videoPlayer.observeFieldScoped("state", "onVideoPlayerState")
    videoPlayer.observeFieldScoped("backButtonPressed", "onVideoPlayerBackPressed")
    videoPlayer.observeFieldScoped("sendVideoTrackingStart", "onVideoTrackingStart")

    if (content.creditCuePoints <> invalid AND content.creditCuePoints.postlude <> invalid AND position >= content.creditCuePoints.postlude)
      position = 0
    else if content.length - position <= 5
      position = 0
    end if

    content.nowPos = position

    ' Adding logging if the program does not have title.
    ' Below logging is a approach to capture more logs to see if we have content title missing for any programs.
    if isNonEmptyString(content.title) = false
      videoInfo = {}
      videoInfo.callSource = videoPlayer.playbackSource
      videoInfo.contentId = content.id
      tubiLog(FormatJSON(videoInfo), "info", "videoInfo", "video-title-undefined")
    end if

    videoPlayer.userConsentsOptOutStatus = getConsentsOptOutStatus()
    videoPlayer.didUserOptOutOfPersonalizedAdvertising = getConsentOptOutStatusByKey(m.constants.consentKeys.personalization)
    videoPlayer.content = content
    videoPlayer.updateContent = true

    ' necessary in the case of deeplinks - only fires once per session
    fireAppLoadBeacon()

  end if

  return videoPlayer
End Function


''''''''''''''''''''''
' onEpisodePosition
'
' Update the resume position
' This function triggers when the video stops as well as when videoPlayer.historyPosition is updated
Function onEpisodePosition(msg)
  tubiLog("VideoHelpers.onEpisodePosition")
  videoPlayer = msg.getRoSGNode()

  if videoPlayer <> invalid
    videoContent = videoPlayer.content
    nowPos = videoPlayer.historyPosition
    updateHistory(videoContent, nowPos)
  end if
End Function


''''''''''''''''''''''
' updateHistory
'
' triggers backend API to bookmark video position
' @content: roSGNode, TubiContentNode
' @nowPos: integer, a playback position which will be passed to the history API
' @isFireAndForget: boolean, true to not handle the history response
'                            false to handle the history response (only needed when exiting playback)
Function updateHistory(content, nowPos, isFireAndForget = true)
  ' Don't send history updates to the server if the user hasn't watched at least a certain amount of video
  if nowPos >= m.constants.player.historyFrequency1Min AND isLoggedInUser() = true AND (content["type"] = m.constants.ui.contentTypes.video OR content["type"] = m.constants.ui.contentTypes.sportsEvent)
    postUserHistory = m.userDeviceApi.getAddHistoryRequestInfo(content, nowPos)

    if postUserHistory <> invalid
      successCallback = invalid
      inputContent = invalid
      inputNowPos = invalid

      if isFireAndForget = false
        successCallback = onHistorySuccess
        inputContent = content
        inputNowPos = nowPos
      end if

      m.makeRequest({
        url: postUserHistory.url
        requestType: m.constants.reqNames.postUserHistory
        options: postUserHistory.options
        successCallback: successCallback
        silenceCallbackWarnings: true
        responseType: "node"
        content: inputContent
        nowPos: inputNowPos
      })
    end if
  end if
End Function


' Wrapper around updateHistory which will ensure the response to the history POST request is handled
'
' @content: roSGNode, TubiContentNode
' @nowPos: integer, a playback position which will be passed to the history API
Function updateHistoryAndHandleResponse(content, nowPos)
  updateHistory(content, nowPos, false)
End Function


' onHistorySuccess
'
' triggers once the API responds for history API
Function onHistorySuccess(content)
  tubiLog("VideoHelpers.onHistorySuccess")

  if content <> invalid
    m.Bookmarks.addHistoryLocally(content, content.nowPos, m.global)
  end if

  ' reload history
  handleHistoryChange()
End Function


' updateHistoryLocally
'
' updates the history locally for signedIn user & guest user
Function updateHistoryLocally(content as object, position as integer)
  m.Bookmarks.addHistoryLocally(content, position, m.global)
End Function


Function onGoToNext(msg)
  tubiLog("VideoHelpers.onGoToNext")
  goToNext = msg.getData()
  if goToNext = true
    m.receivedGoToNextPressed = true
    videoPlayer = msg.getRoSGNode()
    if videoPlayer <> invalid

      oldContent = videoPlayer.content
      historyPosition = round(videoPlayer.position)

      if historyPosition > m.constants.player.historyFrequency1Min
        updateHistoryLocally(oldContent, historyPosition)
        updateHistoryAndHandleResponse(oldContent, historyPosition)
      end if

      ' if there is already valid up next content, play it
      if videoPlayer.upNextContent <> invalid
        nextContent = videoPlayer.upNextContent.getChild(0)

        nextContent = addSeriesTitle(nextContent, oldContent)
        if nextContent <> invalid
          if nextContent.validUntil >= Uptime(0)
            ' the up next content has expired, so fetch new content
            m.upNextRequest = fetchUpNextContent(videoPlayer)
          else
            if videoPlayer.autoplayMode = "automatic"
              srcForAd = m.constants.player.playbackOrigin.autoplay_auto
            else
              srcForAd = m.constants.player.playbackOrigin.autoplay_select
            end if
            ' the up next content is good to go, so play it
            playbackSource = {
              "srcForAnalytic": videoPlayer.autoplayMode
              "srcForAds": srcForAd
            }

            playUpNextContent(nextContent, playbackSource)
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
End Function


' @nextContent: roSGNode, the content node representing the content that will be played next
' @playbackSource: associative Array, format : srcForAnalytic - this value is used for sending analytics;
'                                                   valid values are "automatic", "deliberate", "unknown" or "previews"
'                                               srcForAds - used for rainmaker request
'                                                    valid values are "deeplink" , "ap_auto", "ap_select", "container", "ymal", "search", "epg", "unknown"

'                                               playbackContainer - if srcForAds = container, then playbackContainer is set to the id of the container that was the source, otherwise not used.

Function playUpNextContent(nextContent, playbackSource = {"srcForAnalytic": "unknown", "srcForAds": "unknown"})
  tubiLog("VideoHelpers.playUpNextContent")
  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.videoPlayerScreen)

  '//reset videoSponsorExposureId when playing a new video that is no longer in the same path as seeing the sponsored artwork
  m.videoSponsorExposureId = ""

  if videoPlayer <> invalid

    videoContent = videoPlayer.content
    if videoContent <> invalid AND videoContent.parentType = m.constants.ui.contentTypes.series
      detailScreen = getTopDetailScreenFromStack()
      if detailScreen <> invalid
        detailContent = detailScreen.content
        nResumePoint = videoPlayer.historyPosition
        itemFocused = findEpisode2dIndex(detailContent.currentEpisodeId, detailContent)
        updateNowPosForEpisode(detailContent, itemFocused, nResumePoint)
      end if
    end if

    oldContent = videoPlayer.content
    analyticId = 0
    content = invalid
    'A series can be included into the autoplaylist of a Movie.
    'In that case, exctract the episode info to play from nextContent
    if nextContent.type = m.constants.ui.contentTypes.series
      if nextContent.getChild(0) <> invalid AND nextContent.getChild(0).getchild(0) <> invalid
        content = nextContent.getChild(0).getchild(0)
        analyticId = content.id.toInt()
      end if
    else
      analyticId = nextContent.id.toInt()
      content = addSeriesTitle(nextContent, oldContent)
    end if

    stopVideoContent(videoPlayer)

    ' for analytics purposes, simulate navigating to a new video player page
    ' (which normally happens when pushing a screen to the screen stack)
    ' since we are not tearing down and re-creating the video player
    oldTrackingPageInfo = videoPlayer.trackingPageInfo
    newTrackingPageInfo = videoPlayer.trackingPageInfo
    newTrackingPageInfo.pageValues = {
      video_id: analyticId
    }
    screenTrackingNavigate(oldTrackingPageInfo, newTrackingPageInfo, videoPlayer.trackingComponentInfo)
    screenTrackingLoad(newTrackingPageInfo)

    ' populate the detail screen with the new content while the video is showing so when the user
    ' exits, it's already populated and there is no visible screen re-render. Assume this is only necessary
    ' for movies, as series only autoplay into the same series for now.
    if oldContent.parentType <> m.constants.ui.contentTypes.series
      if nextContent.type = m.constants.ui.contentTypes.series
        'this is not ideal but since we already have series content, we can do not want to refetch the series content.
        onAutoplaySingleContentResponse(nextContent)
      else
        emptyMovieNode = CreateObject("roSGNode", "TubiContentNode")
        emptyMovieNode.type = m.constants.ui.contentTypes.video
        emptyMovieNode.id = nextContent.id
        getSingleContentFromServer(emptyMovieNode, onAutoplaySingleContentResponse, onSingleContentErrorWithoutTracking)
      end if
    end if

    if nextContent.needsLogin = true AND isLoggedInUser() = false
      '//TODO : This code ensures that just in case a locked content present in upnext UI.
      ' There should not be any locked content under upnext UI which will affect the Autoplay TVT, so keep a client log.

      errorInfo = {
        video_id: content.id
        video_url: content.url
        error_message: "Locked content cannot be played"
        error_code: -1   ' is it even needed?
      }

      tubiLog(formatJson(errorInfo), "warn", "videoLoad", "r-rated-upnext", 0.1)

      returnToDetailScreenFromVideo()
    else
      playVideoContent(content, playbackSource)
    end if

  end if
End Function


' Triggered by either a button press or by timer expiration of the up next / autoplay ui
' Is also triggered when resetting videoPlayer.upNextContentToAutoplay = invalid prior to video playback.
Function onUpNextContentToAutoplay(msg)
  upNextContentToAutoplay = msg.getData()

  if upNextContentToAutoplay <> invalid
    tubiLog("VideoHelpers.onUpNextContentToAutoplay")
    videoPlayer = msg.getRoSGNode()
    if videoPlayer.autoplayMode = "automatic"
      srcForAd = m.constants.player.playbackOrigin.autoplay_auto
    else
      srcForAd = m.constants.player.playbackOrigin.autoplay_select
    end if
    playbackSource = {
      "srcForAnalytic": videoPlayer.autoplayMode
      "srcForAds": srcForAd
    }
    playUpNextContent(upNextContentToAutoplay, playbackSource)
  end if
End Function


Function onVideoPlayerState(msg)
  tubiLog("VideoHelpers.onVideoPlayerState")
  videoPlayer = msg.getRoSGNode()
  if videoPlayer <> invalid
    tubiLog("VideoHelpers.onVideoPlayerState state = " + msg.GetData())
    state = msg.GetData()
    if state = "error"
      stopVideoContent(videoPlayer)
      videoPlayer.errorMsg = ""

      videoContent = videoPlayer.content
      historyPosition = round(videoPlayer.position)

      if historyPosition > m.constants.player.historyFrequency1Min
        updateHistoryLocally(videoContent, historyPosition)
        updateHistoryAndHandleResponse(videoContent, historyPosition)
      end if

      currentScreen = getCurrentScreen()
      if currentScreen <> invalid AND currentScreen.id = m.constants.ui.screenIds.videoPlayerScreen
        popScreen(true, true)
      end if

      '//adding the onscreen error should happen after the popScreen() call so that the error modal keeps the focus
      errorMessage = getTranslation("videoPlayer_error_failed_description")
      if videoPlayer.errorMsg <> ""
        errorMessage = videoPlayer.errorMsg
      end if
      showPlayerError(errorMessage, videoPlayer.videoErrorCode)
    else if state = "finished"
      isAutoPlayOff = (isGDPR() = true AND (isKidsUIOn() = true OR isParentalControlsAdultLevel() = false))
      finishedContent = videoPlayer.content
      if finishedContent.isTrailer
        returnToDetailScreenFromVideo()
      else if videoPlayer.upNextContentToAutoplay <> invalid
        ' the video ended while the autoplay UI was still present, now autoplay the chosen video
        ' or autoplay the video that was focused when the timer expired
        if videoPlayer.autoplayMode = "automatic"
          srcForAd = m.constants.player.playbackOrigin.autoplay_auto
        else
          srcForAd = m.constants.player.playbackOrigin.autoplay_select
        end if
        playbackSource = {
          "srcForAnalytic": videoPlayer.autoplayMode
          "srcForAds": srcForAd
        }

        playUpNextContent(videoPlayer.upNextContentToAutoplay, playbackSource)
      else if videoPlayer.upNextContent <> invalid AND isAutoPlayOff = false
        ' the video ended after the autoplay UI was dismissed, so autoplay the first content in
        ' the autoplay "container"
        autoplayContent = videoPlayer.upNextContent.getChild(0)
        if autoplayContent <> invalid
          if videoPlayer.autoplayMode = "automatic"
            srcForAd = m.constants.player.playbackOrigin.autoplay_auto
          else
            srcForAd = m.constants.player.playbackOrigin.autoplay_select
          end if
          playbackSource = {
            "srcForAnalytic": videoPlayer.autoplayMode
            "srcForAds": srcForAd
          }
          playUpNextContent(autoplayContent, playbackSource)
        else
          returnToDetailScreenFromVideo()
        end if
      else
        ' there was no autoplay content, so return to details screen
        returnToDetailScreenFromVideo()
      end if
    end if
  end if
End Function


Function onGetPauseAd(msg)
  videoPlayer = msg.getRoSGNode()

  if videoPlayer <> invalid
    content = videoPlayer.content
    nowPos = videoPlayer.videoPositionForPauseAdRequest
    appMode = videoPlayer.appMode
    pauseAdsRequestInfo = m.rainmakerApi.pauseAdsRequestInfo(content, nowPos, appMode)

    if pauseAdsRequestInfo <> invalid
      m.makeRequest({
        url: pauseAdsRequestInfo.url
        requestType: m.constants.reqNames.getPauseAd
        options: pauseAdsRequestInfo.options
        successCallback: onPauseAdResponse
        silenceCallbackWarnings: true
        responseType: "node"
      })
    end if
  end if
End Function


Function onPauseAdResponse(response)
  videoPlayerScreen = getFromScreenCache(m.constants.ui.screenIds.videoPlayerScreen)

  if response <> invalid
    if videoPlayerScreen <> invalid
      videoPlayerScreen.pauseAdResponse = response
    else if isNonEmptyString(response.notUsedPixel) = true
      sendPauseAdPixel(response.notUsedPixel)
    end if
  end if

End Function


Function onVideoPlayerBackPressed()
  tubiLog("VideoHelpers.onVideoPlayerBackPressed")
  returnToDetailScreenFromVideo()
End Function


' Stop the video player and refresh detail screen with the relevant content
' @sendAnalyticsEvent: boolean, based on this parameter the pageload/navigate event will be fired during popScreen
' @shouldUpdateEpisodeScreenContent: boolean, based on this parameter we will decide if we need to refresh the episode list screen or not.
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
Function returnToDetailScreenFromVideo(sendAnalyticsEvent = true, shouldUpdateEpisodeScreenContent = true)
  tubiLog("VideoHelpers.returnToDetailScreenFromVideo")
  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.videoPlayerScreen)

  if videoPlayer <> invalid
    stopVideoContent(videoPlayer)

    pageOriginDetails = {
      "pageOrigin": m.constants.ui.screenIds.videoPlayerScreen
      "functionName": "returnToDetailScreenFromVideo"
    }

    ' get the top most detail screen
    detailScreen = getTopDetailScreenFromStack()

    videoContent = videoPlayer.content 'always a video, can be movie or episode

    detailContent = invalid
    if detailScreen <> invalid
      detailContent = detailScreen.content 'can be movie or series
    end if

    historyPosition = round(videoPlayer.position)

    detailScreenResumePosition = historyPosition

    isEndReached = (videoContent.creditCuePoints <> invalid AND videoContent.creditCuePoints.postlude <> invalid AND videoContent.creditCuePoints.postlude > 0 AND detailScreenResumePosition > videoContent.creditCuePoints.postlude)
    ' So the detailed page does not have a refresh issue, pass the local resume number before the backend communicates.
    ' The problem with this is that if the backend comes back with a different number than the local
    ' number then there is still a screen redraw issue: i.e. user watches only 2 seconds of a video.
    ' The local number is 2 seconds and displays the resume button, but the backend determines that 2
    ' seconds is not enough to warrant a resume button and returns 0 as the resume point.
    if detailScreenResumePosition < m.constants.player.historyFrequency1Min or (isEndReached = true AND detailContent <> invalid AND detailContent.type <> m.constants.ui.contentTypes.series)
      '//If the video is either at the very beginning or at the very end, then it should pass the local resume point as 0.
      ' if content type is series, we do not need to reset the resumepoint to 0 because it will lose the watch history. But in case of movies,
      ' if user watches till the end, we need to reset the resumepoint to 0.
      detailScreenResumePosition = 0
    end if

    ' Do the appropriate action based on the cases as described in the function definition comments
    if detailContent <> invalid AND videoContent.parentType = m.constants.ui.contentTypes.series
      ' Video player was playing a series episode
      if videoContent.parentId <> detailContent.id
        ' Case 5
        ' Autoplayed into a new series, so fetch new series,
        ' repopulate the existing detail screen when the new series metadata is returned
        emptySeriesNode = CreateObject("roSGNode", "TubiContentNode")
        emptySeriesNode.type = m.constants.ui.contentTypes.series
        emptySeriesNode.id = videoContent.parentId
        getSingleContentFromServer(emptySeriesNode, onSingleContentResponseWithoutTracking, onSingleContentErrorWithoutTracking)

        ' TODO: repopulate the episode screen if necessary after the fetch for the new series
        ' Currently the upNext API does not autoplay into new series, so this functionality was punted for now.
      else
        ' Case 3 and 4
        ' Still in the same series - possibly autoplayed, or possibly same episode

        'updating the history if user has watched more than historyFrequency or postlude reached
        if historyPosition > m.constants.player.historyFrequency1Min or isEndReached = true
          ' For SignedIn/guest user, update resume point to global variable
          updateHistoryLocally(videoContent, historyPosition)

          ' For SignedIn user, update resume point to backend.
          ' When the update history response's success callback  is triggered, it will overwrite
          ' whatever was set in the global history object by the previous call to updateHistoryLocally.
          ' We keep both calls in case there is an error when sending to the server, and also to
          ' avoid race conditions where the user could see the details screen before the history
          ' request resolves.
          updateHistoryAndHandleResponse(videoContent, historyPosition)
          updateRokuContinueWatchingInfo(videoContent, historyPosition)
        end if

        ' update some info in the detail screen content and repopulate with that content
        detailContent.currentEpisodeId = videoContent.id
        populateDetailScreen(detailScreen, detailContent, false, detailScreenResumePosition, pageOriginDetails)

        ' Repopulate the episodes screen if it is the screen under the video player screen in the call stack
        hiddenScreen = getHiddenScreen(1)
        if hiddenScreen.id = m.constants.ui.screenIds.episodeScreen
          '//::TODO:: ensure signed in users see the episode screen progress bars when coming back from video player.
          episodesScreen = hiddenScreen

          itemFocused = findEpisode2dIndex(detailContent.currentEpisodeId, detailContent)
          updateNowPosForEpisode(detailContent, itemFocused, historyPosition)

          episodesScreen.content = detailContent
          if shouldUpdateEpisodeScreenContent = true
            episodesScreen.updateContent = true
          end if
          'if end reached for an episode, then place focus on next episode.
          'if upnextContent is not present, then videoplayer will backout to previous screen.
          if isEndReached = true
            episodesScreen.episodeToFocus = findNextEpisode(itemFocused, detailContent)
          else
            episodesScreen.episodeToFocus = itemFocused
          end if
        end if
      end if
    else if videoContent.isTrailer = true
      ' Case 6, no need to do anything
    else if detailContent <> invalid
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
        populateDetailScreen(detailScreen, videoContent, false, -1, pageOriginDetails)
        emptyMovieNode = CreateObject("roSGNode", "TubiContentNode")
        emptyMovieNode.type = m.constants.ui.contentTypes.video
        emptyMovieNode.id = videoContent.id
        getSingleContentFromServer(emptyMovieNode, onSingleContentResponseWithoutTracking, onSingleContentErrorWithoutTracking)
      else
        ' Case 1
        ' Returning to the detail screen for the same movie as was started, no autoplay
        ' Just repopulate the detail screen with the same content
        'updating the history if user has watched more than historyFrequency or postlude reached
        if historyPosition > m.constants.player.historyFrequency1Min or isEndReached = true
          ' For SignedIn/guest user, update resume point to global variable.
          updateHistoryLocally(videoContent, historyPosition)

          ' For SignedIn user, update resume point to backend
          ' When the update history response's success callback  is triggered, it will overwrite
          ' whatever was set in the global history object by the previous call to updateHistoryLocally.
          ' We keep both calls in case there is an error when sending to the server, and also to
          ' avoid race conditions where the user could see the details screen before the history
          ' request resolves.
          updateHistoryAndHandleResponse(videoContent, historyPosition)
          updateRokuContinueWatchingInfo(videoContent, historyPosition)
        end if
        populateDetailScreen(detailScreen, detailContent, false, detailScreenResumePosition, pageOriginDetails)
      end if
    end if
  end if

  ' remove the video player screen to reveal the details screen (or episodes list screen)
  currentScreen = getCurrentScreen()
  if currentScreen <> invalid AND currentScreen.id = m.constants.ui.screenIds.videoPlayerScreen
    if sendAnalyticsEvent = true
      popScreen(true, true)
    else
      popScreen(false, false)
    end if
  end if
End Function


' Stop the video player and optionally remove the video player from the screen stack
' @videoPlayer: roSGNode, a VideoPlayerScreen node
' removeVideoPlayerFromScreenStack: boolean, indicates if video player screen should be removed from screen stack
'                                   set to false for autoplay, true to return to detail screen/home screen/etc.
Function stopVideoContent(videoPlayer)
  tubiLog("VideoHelpers.stopVideoContent")

  if videoPlayer <> invalid
    content = videoPlayer.content
    sendNielsenPing(m.constants.thirdParty.nielsen.pingTypes.streamEnd, content)
    videoTrackingStop() 'stops youbora tracking

    videoPlayer.unobserveFieldScoped("backButtonPressed")
    videoPlayer.unobserveFieldScoped("state")
    videoPlayer.unobserveFieldScoped("adTrackingObject")
    videoPlayer.unobserveFieldScoped("skipTrailer")
    videoPlayer.unobserveFieldScoped("historyPosition")
    videoPlayer.unobserveFieldScoped("sendVideoTrackingStart")
    videoPlayer.unobserveFieldScoped("goToNext")
    videoPlayer.unobserveFieldScoped("upNextCuepointReached")
    videoPlayer.unobserveFieldScoped("upNextContentToAutoplay")
    videoPlayer.unobserveFieldScoped("upNextNavigateWithinPageInfo")
    videoPlayer.unobserveFieldScoped("relatedNavigateWithinPageInfo")
    videoPlayer.unobserveFieldScoped("segInfo")

    ' reset the deep link state since we've handled it already at this point
    resetDeeplinkValues()

    videoPlayer.control = "stop"

  end if
End Function


' can fire from videoPlayer.skipTrailer or videoPlayer.goToNext fields
' if a trailer is playing.
Function onSkipTrailer(msg)
  tubiLog("VideoHelpers.onSkipTrailer")
  skipTrailer = msg.getData()
  if skipTrailer
    videoPlayer = getFromScreenCache(m.constants.ui.screenIds.videoPlayerScreen)
    if videoPlayer <> invalid
      stopVideoContent(videoPlayer)

      if getHiddenScreen() <> invalid AND getHiddenScreen().id = m.constants.ui.screenIds.detailScreen
        detailScreen = getHiddenScreen()
        detailScreenContent = getDetailScreenContent(detailScreen)
        playVideoContent(detailScreenContent)
      end if
    end if
  end if
End Function


'''''''''''''''''''
' onPlayerError
'
' @errorMessage: string, an error message that will be displayed to the user
' @errorCode: integer, the video player error code (usually a negative number)
Function showPlayerError(errorMessage, errorCode)
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
    if videoPlayer <> invalid AND videoPlayer.content <> invalid AND videoPlayer.content.id <> invalid
      videoId = videoPlayer.content.id.toInt()
    end if

    dialogEvent = {
      type: "dialog"
      values: {
        dialog_type: "PLAYER_ERROR"
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
  end if
End Function


Function onRetryPlayerError()
  ' try to resume the video from the last checkpoint
  screen = getCurrentScreen()
  if screen.isSubtype("DetailScreen") = true
    if screen.watchTrailerSelected = true
      trailerHelper(screen)
    else
      detailScreenResumeHelper(screen)
    end if
  end if
End Function


' helper function for adding series title metadata to content returned from the up next API.
' @content: episode content node with metadata from the up next api
' @oldContent: episode content with full metadata, including parentType (usually from the player)
Function addSeriesTitle(content, oldContent)
  if content.parentId <> invalid AND oldContent.parentId <> invalid
    if oldContent.parentId <> "" AND content.parentId = oldContent.parentId
      content.parentType = "series"
      content.parentTitle = oldContent.parentTitle
    end if
  end if

  return content
End Function


Function getSprites(content)
  if content <> invalid
    spritesReqInfo = m.cmsApi.createThumbnailsReqInfo(content.id)
    m.makeRequest({
      url: spritesReqInfo.url
      requestType: m.constants.reqNames.getThumbnails
      options: spritesReqInfo.options
      successCallback: onSpritesResponse
      responseType: "node"
      silenceCallbackWarnings: true
    })
  end if
End Function


Function onSpritesResponse(sprites)
  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.videoPlayerScreen)
  if videoPlayer <> invalid
    videoPlayer.sprites = sprites
  end if
End Function

Function onUpNextCuepointReached(msg)
  videoPlayer = msg.getRoSGNode()
  if m.upNextRequest = invalid
    if videoPlayer.content <> invalid AND videoPlayer.content.isTrailer = false
      m.upNextRequest = fetchUpNextContent(videoPlayer)
    end if
  end if
End Function


Function initVideoTracking(videoPlayer)
  if m.constants.settings.youboraEnabled = true
    if videoPlayer <> invalid
      'If we are switching from VOD to LIVE or LIVE to VOD, latest videoPlayerScreen's
      'sendYouboraError should be observed.
      videoPlayer.unobserveFieldScoped("sendYouboraError")
      videoPlayer.observeFieldScoped("sendYouboraError", "onSendYouboraError")
      if m.youboraTask = invalid
        m.youboraTask = m.top.createChild("YBPluginRokuVideo")
        m.youboraTask.id = "Youbora"
        m.youboraTask.options = m.constants.thirdParty.youbora.config
        m.global.addFields({YouboraLogActive: m.constants.settings.youboraDebugEnabled})
        m.youboraTask.control = "RUN"
      else
        'Setting m.youboraTask.taskState to "stop" triggers the youboraTask to
        'unobserve the VideoPlayer that is currently being observed in the youboraTask,
        'which enables it to accept the new videoPlayer node (that will be set below)
        'and re-observe the video node attributes.
        m.youboraTask.taskState = "stop"
      end if
      m.youboraTask.videoplayer = videoPlayer.findNode("VideoNode")
    end if
  end if
End Function


Function onVideoTrackingStart(msg)
  tubiLog("VideoHelpers.onVideoTrackingStart")
  videoPlayer = msg.getRoSGNode()
  ' Youbora events
  if m.constants.settings.youboraEnabled = true
    youboraConfig = m.constants.thirdParty.youbora.config

    if videoPlayer <> invalid AND videoPlayer.content <> invalid
      youboraConfig["extraparam.1"] = videoPlayer.content.id
      youboraConfig["content.id"] = videoPlayer.content.id

      playbackType = videoPlayer.content.drmType
      youboraConfig["content.playbackType"] = playbackType

      if isString(playbackType)
        playbackTypeArray = playbackType.split("_")
        if playbackTypeArray[1] <> invalid
          youboraConfig["content.drm"] = playbackTypeArray[1]
        end if
      end if

      youboraConfig.tvShow = Mid(videoPlayer.content.parentId, 2)
    end if

    if isLoggedInUser() = true
      youboraConfig.username = m.global.authInfo.userId
    end if

    if videoPlayer.content.type = m.constants.ui.contentTypes.linear
      youboraConfig["content.isLive"] = true
    else
      youboraConfig["content.isLive"] = false
    end if
    if isNonEmptyString(videoPlayer.content.titanVersionOrExperimentVersion) = true
      youboraConfig["content.customDimension.2"] = videoPlayer.content.titanVersionOrExperimentVersion
    end if
    youboraConfig["content.resource"] = videoPlayer.content.URL
    youboraConfig["device.model"] = m.constants.deviceInfo.model
    youboraConfig["device.id"] = m.constants.deviceInfo.deviceId
    youboraConfig["app.releaseVersion"] = m.constants.deviceInfo.clientVersion
    youboraConfig["content.encoding.videoCodec"] = videoPlayer.content.codec

    m.youboraTask.options = youboraConfig
    m.youboraTask.event = {handler: "play"}
  end if
End Function


Function videoTrackingStop()
  if m.constants.settings.youboraEnabled = true
    m.youboraTask.event = {handler: "stop"}
  end if
End Function


' We observe the VideoNode state change and when the state = "error", the call back chain of events
' eventually sets VideoNode.control = "stop". Due to an idiosyncrasy in Roku behavior, this prevents
' the Youbora plugin from observing the error state on the video node, and so, we must manually trigger
' the Youbora plugin with the error info.
Function onSendYouboraError(msg)
  videoPlayer = msg.getRoSGNode()
  if videoPlayer <> invalid
    m.youboraTask.event = {
      handler: "error"
      params: {
        "msg": videoPlayer.videoErrorMsg
        "errorCode": videoPlayer.videoErrorCode.ToStr()
      }
    }
  end if
End Function


' set up and make the request for Up Next / Autoplay content
' this should get invoked in response to the following scenarios
' 1) reaching the creditsCuePoint
' 2) seeking to a point beyond the creditsCuePoint
' 3) selecting the "go to next" or "advance" button on the transport
' @videoPlayer: roSGNode, the instance of the video player that contains the content for which the
'                         upNext request will be mad
' returns invalid if there is no videoPlayer or valid videoPlayerContent
Function fetchUpNextContent(videoPlayer)
  if videoPlayer <> invalid AND videoPlayer.content <> invalid AND videoPlayer.content.id.Len() > 0
    options = {
      params: {
        "content_id": videoPlayer.content.id
        "isKidsMode": shouldKidsModeBeSentToServer()
        "container_id": m.autoplayContext
        "mode": "nap"
      }
    }

    if videoPlayer.playbackSource <> invalid AND videoPlayer.playbackSource.srcForAnalytics = "automatic"
      options.params.mode = "ap"
    end if

    if m.autoplayContext = invalid
      options.params.delete("container_id")
    end if

    upNextReqInfo = m.cmsApi.createUpNextContentReqInfo(options)

    return m.makeRequest({
      requestType: m.constants.reqNames.getUpNextContent
      url: upNextReqInfo.url
      options: upNextReqInfo.options
      successCallback: onUpNextResponse
      errorCallback: onUpNextError
      responseType: "node"
      isSignedInUser: isLoggedInUser()
    })
  end if
  return invalid
End Function


Function onUpNextResponse(upNextContent)
  tubiLog("VideoHelpers.onUpNextResponse")
  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.videoPlayerScreen)

  if videoPlayer <> invalid
    if upNextContent <> invalid
      if m.receivedGoToNextPressed = true
        firstUpNextItem = upNextContent.getChild(0)
        if firstUpNextItem <> invalid
          if videoPlayer.autoplayMode = "automatic"
            srcForAd = m.constants.player.playbackOrigin.autoplay_auto
          else
            srcForAd = m.constants.player.playbackOrigin.autoplay_select
          end if

          playbackSource = {
            "srcForAnalytic": m.constants.player.playbackSource.unknown
            "srcForAds": srcForAd
          }

          playUpNextContent(firstUpNextItem, playbackSource)
        else
          returnToDetailScreenFromVideo()
        end if
      else if upNextContent.getChildCount() > 0
        videoPlayer.upNextContent = upNextContent
        isAutoPlayOff = (isGDPR() = true AND (isKidsUIOn() = true OR isParentalControlsAdultLevel() = false))
        videoPlayer.isAutoPlayOff = isAutoPlayOff
        videoPlayer.upNextUpdateContent = true
      else 'worst case there are no contents under upNextContent
        returnToDetailScreenFromVideo()
      end if
    end if
  else
    returnToDetailScreenFromVideo()
  end if
End Function

Function onUpNextError(_errorInfo)
  if m.receivedGoToNextPressed = true
    returnToDetailScreenFromVideo()
  end if
End Function


' Getting segment info from player and setting to Youbora Options
Function onSegInfoChange(msg)
  segInfo = msg.getData()
  if m.youboraTask <> invalid
    youboraOptions = m.youboraTask.options
    if youboraOptions <> invalid
       rendition = constructYouboraRendition(segInfo)
       if rendition <> invalid
         youboraOptions["content.rendition"] = rendition
         m.youboraTask.options = youboraOptions
       end if
    end if
  end if
End Function


' This method helps to construct rendition value based on segBitrate & UI resolution
' rendition format will be wxh@bitrate
Function constructYouboraRendition(segInfo)
  rendition = invalid
  if segInfo <> invalid
    segBitrate = segInfo.segBitrateBps
    if segBitrate <> invalid
      if segBitrate < 1000
        segBitrate = segBitrate.ToStr() + "bps"
      else if segBitrate < 1000000
        segBitrate = (segBitrate / 1000).ToStr() + "Kbps"
      else
        rendAux = segBitrate / 1000000.0 'Divide by mega
        rendAux = Cint(rendAux * 100) / 100.0
        segBitrate = rendAux.ToStr() + "Mbps"
      end if
      if segInfo.Width <> invalid AND segInfo.Height <> invalid then
        width = segInfo.Width.ToStr()
        height = segInfo.Height.ToStr()
      else
        width = m.constants.deviceInfo.displayWidth.ToStr()
        height = m.constants.deviceInfo.displayHeight.ToStr()
      end if
      rendition = width + "x" + height + chr(64) + segBitrate
    end if
  end if
  return rendition

End Function


' updateNowPosForEpisode updates the nowPos field of current episode so that it draws progressbar
' @detailContent: roSGNode, content node for detail screen
' @itemFocused: 2D array, currently focused indexes of season/episode
' @nResumePoint: Integer, history position for current episode
Function updateNowPosForEpisode(detailContent, itemFocused, nResumePoint)

  seasonIndex = itemFocused[0]
  episodeIndex = itemFocused[1]

  season = detailContent.getChild(seasonIndex)
  if season <> invalid
    episode = season.getChild(episodeIndex)
    if episode <> invalid
      episode.nowPos = nResumePoint 'updating current episode's nowPos to draw progressbar
    end if
  end if

End Function


Function onAudioTrackSettingsChange(msg)
  selectedAudioTrack = msg.getData()
  ' Making sure we only call update when necessary.
  currentAudioTrack = m.pub_serverPersistentData.audioTrack
  if (currentAudioTrack.language <> selectedAudioTrack.language) OR (currentAudioTrack.role <> selectedAudioTrack.role)
    saveServerPersistentData({
      "audioTrack": selectedAudioTrack
    })
  end if
End Function


Function onSendPauseAdPixel(msg)
  pixelUrl = msg.getData()
  sendPauseAdPixel(pixelUrl)
End Function


' fires the Pause Ad pixels
Function sendPauseAdPixel(pixelUrl)
  tubiLog("VideoHelpers.sendPauseAdPixel")

  if isNonEmptyString(pixelUrl)
    encodedUrl = pixelUrl.EncodeUri()
    m.makeRequest({
      url: encodedUrl
      requestType: m.constants.reqNames.postPauseAdPixel
      responseType: "string"
      silenceCallbackWarnings: true
    })
  end if
End Function


' @relatedContent: roSGNode, TubiContentNode
Function handleRelatedResponseInVideoPlayer(relatedContent)
  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.videoPlayerScreen)
  if videoPlayer <> invalid
    videoPlayer.relatedContent = relatedContent
    videoPlayer.updateRelatedContent = true
  end if
End Function


' @content: tubiContentNode, a content node representing a movie or episode or sports event.
' @position: integer, Playback position.
Function updateRokuContinueWatchingInfo(content, position)
  ' Only perform the operation if user is logged in and not opted out of the continueWatching consent.
  if content.isTrailer = false AND isLoggedInUser() = true AND getConsentOptOutStatusByKey(m.constants.consentKeys.continueWatching) = false then
    didReachEndOfVideo = false
    if content.creditCuePoints <> invalid AND position >= content.creditCuePoints.postlude
      didReachEndOfVideo = true
    end if

    ' Checking if we reached end of the program.
    if didReachEndOfVideo = true

      ' Checking if it is a series or else if it is movie then removing from continue watching.
      if content.parentType <> "series"
        deleteFromRokuContinueWatching(content)
      else
        detailScreen = getTopDetailScreenFromStack()
        if detailScreen <> invalid
          detailContent = detailScreen.content

          if detailContent.id = content.parentId
            currentEpisode2DIndex = findEpisode2dIndex(content.id, detailContent)
            nextEpisode2DIndex = findNextEpisode2dIndex(currentEpisode2DIndex, detailContent)

            ' Checking to make sure we are not at the end of the available episodes.
            if nextEpisode2DIndex[0] > 0 OR nextEpisode2DIndex[1] > 0
              ' Adding the next episode to the continue watching.
              nextEpisode = detailContent.getChild(nextEpisode2DIndex[0]).getChild(nextEpisode2DIndex[1])
              addOrUpdateRokuContinueWatchingInfo(nextEpisode, 0)
            else
              deleteFromRokuContinueWatching(content)
            end if
          else
            deleteFromRokuContinueWatching(content)
          end if

        end if
      end if
    else
      addOrUpdateRokuContinueWatchingInfo(content, position)
    end if
  end if
End Function


' @content: tubiContentNode, a content node representing a movie or episode or sports event.
' @position: integer, Playback position.
Function addOrUpdateRokuContinueWatchingInfo(content, position)
  item = {
    "contentId": content.id,
    "lastInteractionTime": createObject("roDateTime").asSeconds(),
    "position": position,
    "duration": content.length
  }
  if content.parentType = "series"
    item.contentId = content.seriesId
    item.episodeId = content.id
  end if
  body = {
    "items": [item]
  }
  requestInfo = m.rokuContinueWatchingApi.createUpdateContinueWatchingReqInfo(body)
  requestInfo.requestType = m.constants.reqNames.postRokuContinueWatching
  m.top.rokuContinueWatchingRequestInfo = requestInfo
End Function


' @content: tubiContentNode, a content node representing a movie or episode or sports event.
Function deleteFromRokuContinueWatching(content)
  item = {
    "contentId": content.id
  }
  if content.parentType = "series"
    item.contentId = content.seriesId
    item.episodeId = content.id
  end if
  body = {
    "items": [item]
  }
  requestInfo = m.rokuContinueWatchingApi.createDeleteContinueWatchingReqInfo(body)
  requestInfo.requestType = m.constants.reqNames.deleteRokuContinueWatching
  m.top.rokuContinueWatchingRequestInfo = requestInfo
End Function


Function onPlayerRelatedContentToPlay(msg)
  content = msg.getData()

  ' The episode information is not available for the selected series, so refetch required for series content type
  if content.type = m.constants.ui.contentTypes.series
    emptySeriesNode = CreateObject("roSGNode", "TubiContentNode")
    emptySeriesNode.type = m.constants.ui.contentTypes.series
    emptySeriesNode.id = content.id
    getSingleContentFromServer(emptySeriesNode, handleYMALSeriesContentSuccessResponse, handleYMALSeriesContentErrorResponse)
  else
    playbackSource = {
      "srcForAnalytic": m.constants.player.playbackSource.unknown
      "srcForAds": m.constants.player.playbackOrigin.ymal
    }
    playUpNextContent(content, playbackSource)
  end if
End Function


Function handleYMALSeriesContentSuccessResponse(content)
  playbackSource = {
    "srcForAnalytic": m.constants.player.playbackSource.unknown
    "srcForAds": m.constants.player.playbackOrigin.ymal
  }
  playUpNextContent(content, playbackSource)
End Function


Function handleYMALSeriesContentErrorResponse(error)
  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.videoPlayerScreen)
  content = invalid

  if videoPlayer <> invalid
    content = videoPlayer.relatedContentToPlay
  end if

  ' set up the error modal dialog
  errorCode = getUserFacingErrorCode(m.constants.errors.context.videoDetailScreen, m.constants.errors.subtypes.fetchError, error.code)
  dialogEvent = getDetailScreenDialogAnalyticEvent(content, "NETWORK_ERROR", errorCode, m.constants)

  message = ""
  modalInfo = {
    message: getErrorMessage(message, errorCode)
    openTrackEvent: dialogEvent
    trackingTask: m.trackingLoggingTask
  }

  showErrorModal(modalInfo, invalid, invalid, onCloseYMALContentFetchErrorModal)
End Function


Function onCloseYMALContentFetchErrorModal()

  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.videoPlayerScreen)
  if videoPlayer <> invalid
    videoPlayer.showYMALInFullScreen = true
  end if

End Function
