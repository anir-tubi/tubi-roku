'''''''''''''''''''''
' playLinearVideoContent
'
' Helper Function for onResume and onPlay to launch content
' @content: TubiContentNode, the content to be played
' @bMinimized: boolean, Should the player be playing in its minmized state on the homescreen? If false, then it will be at fullscreen.
Function playLinearVideoContent(content, bMinimized = true, sContainerID = "")
  tubiLog("LinearVideoPlayerScreenHelpers.playLinearVideoContent")
  ' we make changes to the content from this point forward. If we don't clone, those changes will initialize
  ' a variety of unexpected and unwanted callbacks, as the passed in content potentially exists on a number
  ' of fields that are being observed (for instance: HomeScreen.contentFocused)
  content = content.clone(true)

  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
  
  bTellPlayerToPlay = true
  if videoPlayer = invalid
    videoPlayer = CreateObject("roSGNode", "LinearVideoPlayerScreen")
    videoPlayer.id = m.constants.ui.screenIds.linearVideoPlayerScreen
    ' onVideoPlayerVisibleChange exists in ContentController
    m.top.observeField("liveNewsChannelGuideResponse", "onLiveNewsChannelGuideContentResponse")
    videoPlayer.observeFieldScoped("visible", "onLinearVideoPlayerVisibleFullscreenChange")
    videoPlayer.observeFieldScoped("refreshChannels", "onChannelsRequested")
    videoPlayer.observeFieldScoped("fullscreen", "onLinearVideoPlayerVisibleFullscreenChange")
    videoPlayer.observeFieldScoped("userDisplayingChannelGuide", "onChannelGuideVisibleStateChangedByUser")
    videoPlayer.observeFieldScoped("channelSelected", "onNewChannelSelected")
    videoPlayer.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
    initVideoTracking(videoPlayer) 'initializeYoubora. Regular and linear video players share tracking functions, which are found in VideoHelpers
    setInScreenCache(videoPlayer)
  end if
  unObserveAllStateDependentLinearVideoPlayerFields(videoPlayer) 
  
  if content <> invalid
    videoPlayer.analyticsMode = "normal"

    ' set general observers for all content
    videoPlayer.observeFieldScoped("sendVideoTrackingStart", "onVideoTrackingStart")
  end if

  ' it's necessary to push the screen after the content has been set on the videoPlayer component,
  ' so NavigateToPage and PageLoad events contain the necessary content id information
  if bMinimized = false 
    maximizeLinearPlayer(content)
  else 
    '//play at minimized state
    showHideLinearVideoPlayerSpinner(true)
    animateLinearVideoPlayerToMinState(0, false)
  end if

  if isLinearPlayerPlayingThisContent(content) = false
    if content <> invalid
      videoPlayer.content = content
      videoPlayer.updateContent = true
    end if

    ' this is not the same instance of the task that is used by the linear video player
    ' this is just a temp task to handle adding the params to the video url,
    ' and will be removed later.
    ' Setting content on the adsSsaiTask will set a series of asynchronous events in action that need
    ' to occur in order to prepare the linear stream:
    ' 1) add the rainmaker parameters to the stream url - YoSpace will make calls to rainmaker in order to
    '    to stitch the ads and needs the rainmaker parameters to make the rainamaker requests
    ' 2) fetch the response from the hls manifest and parse out the YoSpace "analtyics url" which is the url
    '    that will be used to poll for ads
    ' 3) compose the final stream url from the "analytics url" and the original stream url found in the
    '    matrix/homescreen response
    ' 4) pass the content with the updated stream url to the linear video player
    if m.adsSsaiTask <> invalid
      m.adsSsaiTask.unobserveFieldScoped("videoResourcesWithAdParams")
      m.adsSsaiTask.exit = true
      m.adsSsaiTask = invalid
    end if
    if m.linearManifestRequest <> invalid
      m.cancelRequest(m.linearManifestRequest)
      m.linearManifestRequest = invalid
    end if
    m.adsSsaiTask = CreateObject("roSGNode", "AdsSSAITask")
    m.adsSsaiTask.id = "tempAdsSsaiTask"

    ' adsSsaiTask will update the videoResource url with rainmaker params when it receives content
    m.adsSsaiTask.observeFieldScoped("videoResourcesWithAdParams", "onAdParamsAddedToVideoUrl")
    m.adsSsaiTask.content = content
    m.adsSsaiTask.updateContent = true
  end if
End Function


Function getCurrentLinearContent()
  content = invalid
  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)

  if videoPlayer <> invalid
    content = videoPlayer.content
  end if
  return content
End Function


' display the linear video player at the max state
Function maximizeLinearPlayer(content)
  tubiLog("LinearVideoPlayerScreenHelpers.maximizeLinearPlayer")
  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)

  if videoPlayer <> invalid and videoPlayer.content <> invalid
    if currentScreen() = invalid or currentScreen().id <> m.constants.ui.screenIds.linearVideoPlayerScreen
      pushScreen(videoPlayer, true, true)
    end if
    bAnimate = false
    if isLinearPlayerPlayingThisContent(content) = true
      '//If the video is already playing then animate it view in case it is being displayed on the homscreen in a corner
      bAnimate = true
    end if

    videoPlayer.unobserveFieldScoped("state")
    videoPlayer.unobserveFieldScoped("backButtonPressed")
    videoPlayer.observeFieldScoped("state", "onLinearVideoPlayerState")
    videoPlayer.observeFieldScoped("backButtonPressed", "onLinearVideoPlayerBackPressed")
  
    if videoPlayer.fullscreen = false
      '//stop the background artwork from transitioning and from displaying while player is in fullscreen
      m.backgroundGroup.backgroundInfo = {
        type: m.constants.ui.backgroundTypes.linear
        uriList: []
      }
      m.backgroundGroup.posterVisible = true 
      showHideLinearVideoPlayerSpinner(false)
      
      repositionLinearVideoPlayerToMaxState(bAnimate)
    end if

  end if
End Function


Function isLinearPlayerPlayingThisContent(content)
  bPlaying = false
  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
  if content <> invalid and videoPlayer <> invalid and videoPlayer.content <> invalid
    if videoPlayer.content.id = content.id and videoPlayer.state = "playing"
      bPlaying = true
    end if
  end if
  return bPlaying
End Function


Function onAdParamsAddedToVideoUrl(msg)
  tubiLog("LinearVideoPlayerScreenHelpers.onAdParamsAddedToVideoUrl")
  adsSsaiTask = msg.getRoSGNode()
  content = adsSsaiTask.content  'this content has the videoResources with the url with the ads params appended to it
  content.videoResources = msg.getData()
  
  ' don't completely clean up ads task here because we may use it again in the case where the manifest
  ' response does not provide an ad poll url
  adsSsaiTask.unobserveFieldScoped("videoResourcesWithAdParams")

  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
  if videoPlayer <> invalid
    streamUrl = getLiveUrlFromResources(content)
    if streamUrl <> invalid
      ' store the content on videoPlayer so it can be retrieved after the manifest is fetched
      videoPlayer.content = content
      getLiveStreamManifest(streamUrl)
    else
      ' no stream url so show an error
      showLinearPlayerError()
    end if
  end if
End Function


Function getLiveStreamManifest(streamUrl)
  tubiLog("LinearVideoPlayerScreenHelpers.getLiveStreamManifest")
  liveManifestReqType = m.constants.reqNames.getLiveManifest

  if isString(streamUrl)
    streamUrl = streamUrl.trim()
  end if

  m.linearManifestRequest = m.makeRequest(liveManifestReqType, streamUrl, invalid, onLiveStreamManifestResponse, onManifestError, "assocarray")
End Function


Function onLiveStreamManifestResponse(response)
  tubiLog("LinearVideoPlayerScreenHelpers.onLiveStreamManifestResponse")

  if response <> invalid and isString(response.res)
    ' find the analytics url
    ' ("analytics url" is the YoSpace name for the url that will be polled for ad responses)
    pollUrl = invalid
    lines = response.res.split(chr(10))
    for each line in lines
      if line.Instr("#EXT-X-YOSPACE-ANALYTICS-URL") = 0
        ' Extract the value of the analytics URL
        pollUrl = right(line, len(line) - 29)

        ' Strip surrounding quotes characters if present
        if (left(pollUrl, 1) = chr(34))
          pollUrl = mid(pollUrl, 2, len(pollUrl) - 2)
        end if

        exit for
      end if
    end for

    videoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)

    content = invalid
    if videoPlayer.content <> invalid
      content = videoPlayer.content
    end if

    if pollUrl <> invalid or (pollUrl = invalid and m.constants.ui.liveNewsNoAdsIds[content.id] <> invalid)
      ' TODO: We do not want to maintain the m.constants.ui.liveNewsNoAdsIds map, so remove
      ' any references to it after we find out how often this happens, or get
      ' the backend to inform us of which linear content has ads.

      ' we have a valid poll url or we are not expecting one, so play content

      ' piece together the modified playback url
      ' The url that will be used for the video stream must be built from the original url returned by the API
      ' and from the "analytics url"/ad polling url. For more info, please see:
      ' https://docs.google.com/document/d/14Ovs4KzV0iwloKtILjSZhQxT2NcGdGCm80MIMvB9EfE
      originalUrl = invalid

      modifiedUrl = ""
      if content <> invalid and content.videoResources <> invalid
        videoResources = content.videoResources
        newVideoResources = []

        for each resource in videoResources
          newResource = resource
          if resource.type = m.constants.player.drmTypes.hlsv3
            if resource.url <> invalid
              ' For linear content that is serving ads via YoSpace, the video resource that is used to fetch
              ' the manifest actually redirects through a Tubi "manifest server" and to a YoSpace server
              ' to get the manifest response. When reconstructing the YoSpace manifest url to include the
              ' session id, we need to use the original YoSpace stream url and not the video resource url
              ' provided by UAPI. We get the original YoSpace stream url from the "location" header since
              ' it is a redirect.
              if response.headers <> invalid and response.headers.location <> invalid
                originalUrl = response.headers.location
              else 
                originalUrl = resource.url
              end if

              modifiedUrl = constructModifiedLinearVideoUrl(originalUrl, pollUrl)
              newResource.url = modifiedUrl
            end if
          end if

          newVideoResources.push(newResource)
        end for

        content.videoResources = newVideoResources
      end if

      videoPlayer.content = content
      videoPlayer.updateContent = true
      videoPlayer.pollUrl = pollUrl
      videoPlayer.control = "play"
    else if pollUrl = invalid and m.constants.ui.liveNewsNoAdsIds[content.id] = invalid
      ' TODO: We do not want to maintain the m.constants.ui.liveNewsNoAdsIds map, so remove
      ' any references to it after we find out how often this happens, or get
      ' the backend to inform us of which linear content has ads.

      if m.adsSsaiTask.manifestAttempts < 3
        ' we didn't get a poll url but the content is expected to have ads, so we can retry fetching
        ' the manifest as long as we are beneath the max retry attempts limit.
        m.adsSsaiTask.manifestAttempts += 1
        streamUrl = getLiveUrlFromResources(content)
        getLiveStreamManifest(streamUrl)
      else
        ' we've maxed out the allowed retries but still no poll url, so trigger an
        ' error via the videoPlayer and log an error.
        videoPlayer.control = "error"

        streamUrl = ""
        for each line in lines
          if line.left(8) = "https://"
            streamUrl = line
            exit for
          end if
        end for

        logMsg = {
          content_id: content.id
          stream_url: streamUrl
        }
        logMsg = FormatJson(logMsg)
        tubiLog(logMsg, "error", "videoLoad", "no-yospace-analytics-url")
      end if
    end if
  end if
End Function


Function onManifestError(error)
  tubiLog("LinearVideoPlayerScreenHelpers.onManifestError")
  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
  if videoPlayer <> invalid
    if videoPlayer.fullscreen = true
      code = invalid
      if error <> invalid
        code = error.code
      end if
      showLinearPlayerError("", code)
    else
      reactToLinearVideoPlayerErrorStateInNonFullscreenState()
    end if
  end if
End Function


Function constructModifiedLinearVideoUrl(originalUrl, pollUrl)
  modifiedUrl = originalUrl
  if isString(originalUrl) and isString(pollUrl)
    pollUrl = pollUrl.trim()
    pollUrlParts = getUrlParts(pollUrl, ";")
    originalUrl = originalUrl.trim()
    originalUrlParts = getUrlParts(originalUrl)
    if pollUrlParts <> invalid and originalUrlParts <> invalid
      protocol = pollUrlParts.protocol
      host = pollUrlParts.host
      path = originalUrlParts.path
      session = pollUrlParts.paramsWithSeparator
      params = originalUrlParts.paramsWithSeparator
      modifiedUrl = protocol + host + path + session + params
    end if
  end if

  return modifiedUrl
End Function


Function getLiveUrlFromResources(content)
  streamUrl = invalid

  if content <> invalid
    for each resource in content.videoResources
      if resource.type = m.constants.player.drmTypes.hlsv3
        streamUrl = resource.url
        exit for
      end if
    end for
  end if

  return streamUrl
End Function


' showHideLinearVideoPlayerSpinner - shows/hides the LinearVideoPlayer loading spinner
' 
'@visible : boolean - should the spinner be visible
Function showHideLinearVideoPlayerSpinner(bVisible)
  m.LinearVideoPlayerSpinner.visible = bVisible
End Function


Function stopAndHideLinearVideoPlayer()
  tubiLog("LinearVideoPlayerScreenHelpers.stopAndHideLinearVideoPlayer")  
  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
  if videoPlayer <> invalid
    '//reset and Hide the loading indicator.
    showHideLinearVideoPlayerSpinner(false)
    m.backgroundGroup.posterVisible = true
    stopLinearVideoContent()
    unObserveAllStateDependentLinearVideoPlayerFields(videoPlayer)
    videoPlayer.visible = false
  end if
End Function


Function unObserveAllStateDependentLinearVideoPlayerFields(videoPlayer)
  tubiLog("LinearVideoPlayerScreenHelpers.unObserveAllStateDependentLinearVideoPlayerFields") 
  if videoPlayer <> invalid
    videoPlayer.unobserveFieldScoped("backButtonPressed")
    videoPlayer.unobserveFieldScoped("state")
    videoPlayer.unobserveFieldScoped("sendVideoTrackingStart")
  end if
End Function


Function repositionLinearVideoPlayerToMaxState(bAnimate)
  tubiLog("LinearVideoPlayerScreenHelpers.repositionLinearVideoPlayerToMaxState") 
  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
  if videoPlayer <> invalid
    videoPlayer.fullscreen = true
    nDuration = 0
    if bAnimate = true
      nDuration = .5
    end if 
    resizeToLocation(videoPlayer, 1920, 1080, [0,0], nDuration)
  end if
End Function



Function animateLinearVideoPlayerToMinState(nDuration = .25, bVisible = true)
  '//Add video player to LinearPlayerGroup

  tubiLog("LinearVideoPlayerScreenHelpers.animateLinearVideoPlayerToMinState")  
  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
  if videoPlayer <> invalid
    videoPlayer.fullscreen = false
    videoPlayer.unobserveFieldScoped("state")
    videoPlayer.observeFieldScoped("state", "onLinearVideoPlayerStateWhileInMinState")
    m.LinearPlayerGroup.appendChild(videoPlayer)

    resizeToLocation(videoPlayer, m.constants.ui.imageSizes.linearVideoPlayer_minimizedDimension[0], m.constants.ui.imageSizes.linearVideoPlayer_minimizedDimension[1], m.constants.ui.imageTranslations.linearVideoPlayer_minimizedTranslation, nDuration)
    videoPlayer.visible = bVisible
  end if
End Function


Function onLinearVideoPlayerStateWhileInMinState(msg)
  videoPlayer = msg.getRoSGNode()
  if videoPlayer <> invalid
    tubiLog("LinearVideoPlayerScreenHelpers.onLinearVideoPlayerStateWhileInMinState state = " + msg.GetData())
    state = msg.GetData()
    if state = "error" or state = "finished"
      reactToLinearVideoPlayerErrorStateInNonFullscreenState()
    else if state = "playing"
      '//Once the video player has loaded, then display video player
      showHideLinearVideoPlayerSpinner(false)
      startCountdownTimer()
      videoPlayer.visible = true
      m.backgroundGroup.posterVisible = false
    end if
  end if
End Function


' When either the fullscreen or visible states change of the linear video player, then this event handler is called
Function onLinearVideoPlayerVisibleFullscreenChange(msg)
  tubiLog("ContentController.onLinearVideoPlayerVisibleFullscreenChange")
  videoPlayer = msg.getRoSGNode()
  bVisible = videoPlayer.visible
  bFullScreen = videoPlayer.fullscreen
  if bVisible = true and bFullScreen = false
    m.SideNav.visible = true
    m.logoGroup.visible = false
  else if bVisible = false and bFullScreen = false
    m.SideNav.visible = true
    m.logoGroup.visible = true
  else
    m.SideNav.visible = false
    m.logoGroup.visible = false
  end if 
End Function


Function onLinearVideoPlayerState(msg)
  tubiLog("LinearVideoPlayerScreenHelpers.onLinearVideoPlayerState")
  videoPlayer = msg.getRoSGNode()
  if videoPlayer <> invalid
    tubiLog("LinearVideoPlayerScreenHelpers.onLinearVideoPlayerState state = " + msg.GetData())
    state = msg.GetData()
    if state = "error"
      showLinearPlayerError(videoPlayer.errorMsg, videoPlayer.videoErrorCode)
    else if state = "playing"
      showHideLinearVideoPlayerSpinner(false)
    else if state = "finished"
      '//Assume a finished video stream is an error
      showLinearPlayerError()
    end if
  end if
End Function


Function onLinearVideoPlayerBackPressed()
  tubiLog("LinearVideoPlayerScreenHelpers.onLinearVideoPlayerBackPressed")
  returnToPreviousScreenFromLinearVideo(true)
End Function


' Go back to the main window. Either stop the video or continue playing it. If the video continues to play, then animate it down to the corner of the screen.
Function returnToPreviousScreenFromLinearVideo(bContinueToPlay = true)
  tubiLog("LinearVideoPlayerScreenHelpers.returnToPreviousScreenFromLinearVideo")
  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
  if videoPlayer <> invalid
    videoPlayer.unobserveFieldScoped("backButtonPressed")
    videoPlayer.unobserveFieldScoped("state")
    if bContinueToPlay = false
      stopAndHideLinearVideoPlayer()
      homescreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
      setHomeScreenBackground(homescreen)
    end if
  end if

  currentScreen = currentScreen()
  if currentScreen <> invalid and currentScreen.id = m.constants.ui.screenIds.linearVideoPlayerScreen
    if bContinueToPlay = true
      popScreen(true, true)
      '//animate the video player into the corner
      animateLinearVideoPlayerToMinState()
    else
      ' remove the video player screen to reveal the home screen
      popScreen(true, true)
    end if
  end if
End Function


' Stop the linear video player
Function stopLinearVideoContent()
  tubiLog("LinearVideoPlayerScreenHelpers.stopLinearVideoContent")
  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
  if videoPlayer <> invalid
    videoPlayer.unobserveFieldScoped("sendVideoTrackingStart")
    videoTrackingStop() 'stops youbora tracking
    videoPlayer.control = "stop"
  end if
  '//cancel any asynchronous tasks/requests that may cause the video to play if they are left to continue
  if m.adsSsaiTask <> invalid
    m.adsSsaiTask.unobserveFieldScoped("videoResourcesWithAdParams")
  end if
  if m.linearManifestRequest <> invalid
    m.cancelRequest(m.linearManifestRequest)
    m.linearManifestRequest = invalid
  end if
End Function



'''''''''''''''''''
' showLinearPlayerError
'
' @error_message: string, an error message that will be displayed to the user
' @errorCode: integer, the video player error code (usually a negative number)
Function showLinearPlayerError(error_message = "", errorCode = invalid)
  tubiLog("LinearVideoPlayerScreenHelpers.showLinearPlayerError")

  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
  if videoPlayer <> invalid
    returnToPreviousScreenFromLinearVideo(false)
    errorMessage = getTranslation("videoPlayer_error_failed_description")
    if error_message <> invalid and error_message <> "" 
      errorMessage = error_message
    end if

    ' reset the video player state in case an error occurs during the next attempt at playing a video
    videoPlayer.state = ""

    if errorCode = invalid
      errorCode = ""
    end if
    userErrorCode = getUserFacingErrorCode(m.constants.errors.context.linearPlayerScreen, m.constants.errors.subtypes.playerPlaybackError, errorCode.toStr())

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

    showErrorModal(modalInfo, onRetryLinearPlayerError, invalid)
    stopLinearVideoContent() '//In case the video is still playing
  end if
End Function


Function reactToLinearVideoPlayerErrorStateInNonFullscreenState()
  tubiLog("LinearVideoPlayerScreenHelpers.reactToLinearVideoPlayerErrorStateInNonFullscreenState")
  '//if player receives error or finished state while minimized, then hide the player.
  ' We don't show an error modal when in non full screen mode since users didn't explicitly select
  ' to start playback. If an error occurs heres, not showing an error modal allows users to continue navigating.
  stopAndHideLinearVideoPlayer()
  homescreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
  setHomeScreenBackground(homescreen)
End Function


' When the user purposely opens or closes the channel guide (userDisplayingChannelGuide), then this handler will be called.
Function onChannelGuideVisibleStateChangedByUser(msg)
  tubiLog("LinearVideoPlayerScreenHelpers.onChannelGuideVisibleStateChangedByUser")
  bChannelGuideVisible = msg.getData() 

  event = invalid
  pageType = ""
  pageValues = {}
  screen = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)

  if screen <> invalid and screen.trackingPageInfo <> invalid and screen.trackingComponentInfo <> invalid and screen.trackingComponentInfo.componentValues <> invalid
    pageType = screen.trackingPageInfo.pageType
    pageValues = screen.trackingPageInfo.pageValues

    componentInfo = screen.trackingComponentInfo.componentValues

    toggle = ""
    if bChannelGuideVisible = true
      toggle = "TOGGLE_ON"
    else
      toggle = "TOGGLE_OFF"
    end if

    event = {
      type: "component_interaction"
      values: {
        pageOneof: m.Tracking.getAnalyticsPage(pageType, pageValues)
        componentOneof: m.Tracking.getAnalyticsComponent(screen.trackingComponentInfo.componentType, componentInfo)
        user_interaction: toggle
      }
    }

    m.trackingLoggingTask.trackEvent = event
  end if
End Function 

' A new channel is selected from the channel guide. Start playing that new channel
Function onNewChannelSelected(msg)
  tubiLog("LinearVideoPlayerScreenHelpers.onNewChannelSelected")
  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
  channel = msg.getData() 
  if videoPlayer <> invalid
    if channel <> invalid and channel.videoResources <> invalid
      oldTrackingPageInfo = videoPlayer.trackingPageInfo
      trackingComponentInfo = videoPlayer.trackingComponentInfo
      stopLinearVideoContent()
      playLinearVideoContent(channel, false)
      newTrackingPageInfo = videoPlayer.trackingPageInfo
      screenTrackingNavigate(oldTrackingPageInfo, newTrackingPageInfo, trackingComponentInfo)

      '//Tell the homescreen to focus on the same channel so when the user backs out, the channel that is playing is the same one that is in focus
      '//   Note: since the video channel guide and the homescreen's live news container are loaded independently from each other, we cannot assume they are in sync 
      jumpToHomescreenContentByID(channel.id, videoPlayer.content.parentId)
    else
      '//Incorrect data, display an error
      showLinearPlayerError()
    end if
  end if
End Function


' When the player requests the channels info, then get it and supply it to the video player
Function onChannelsRequested()
  tubiLog("LinearVideoPlayerScreenHelpers.onChannelsRequested")
  reqName = m.constants.reqNames.getHomescreen
  responseHandler = "liveNewsChannelGuideResponse"
  options = {
    params: {
      contentMode: m.constants.ui.contentMode.news
      limit: 200
    }
  }
  m.metadataFetchTask.request = m.metadataFetchTaskDTO.createRequest("homescreen", m.top, responseHandler, reqName, invalid, false, options)
End Function


Function onLiveNewsChannelGuideContentResponse()
  tubiLog("LinearVideoPlayerScreenHelpers.onLiveNewsChannelGuideContentResponse")
  rawResponse = m.top.liveNewsChannelGuideResponse
  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
  if videoPlayer <> invalid
    if rawResponse.response <> invalid then
      response = rawResponse.response

      if response.code >= 200 and response.code < 300 and rawResponse.convertedMetadata.getChildCount() > 0 then
        videoPlayer.channelsContent = rawResponse.convertedMetadata
      else
        '//Only show an error modal if the channel guide is still visible
        if videoPlayer.displayingChannelGuide = true
          errorMessage = getTranslation("channelGuide_error_fetchContent_description")
          errorCode = getUserFacingErrorCode(m.constants.errors.context.linearPlayerScreen, m.constants.errors.subtypes.fetchError, response.code)

          dialogEvent = {
            type: "dialog"
            values: {
              dialog_type: "NETWORK_ERROR"
              pageOneof: m.Tracking.getAnalyticsPage("", {})  'TODO: Add the linear video player page
              dialog_action: "SHOW"
              dialog_sub_type: errorCode
            }
          }

          modalInfo = {
            message: getErrorMessage(errorMessage, errorCode)
            openTrackEvent: dialogEvent
            trackingTask: m.trackingLoggingTask
          }

          showErrorModal(modalInfo, onChannelsRequested, invalid, closeLinearVideoPlayerTransport, invalid)
        end if
      end if
    end if
  end if
End Function

Function closeLinearVideoPlayerTransport()
  tubiLog("LinearVideoPlayerScreenHelpers.closeLinearVideoPlayerTransport")
  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
  if videoPlayer <> invalid
    videoPlayer.closeTransport = true
  end if
End Function 


Function onRetryLinearPlayerError()
  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
  if videoPlayer <> invalid
    content = videoPlayer.content
    stopLinearVideoContent()
    playLinearVideoContent(content, false)
  end if
End Function