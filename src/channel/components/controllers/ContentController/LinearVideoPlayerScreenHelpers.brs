'''''''''''''''''''''
' playLinearVideoContent
'
' Helper function for onResume and onPlay to launch content
' @content: TubiContentNode, the content to be played
' @bMinimized: boolean, Should the player be playing in its minimized state on the homescreen? If false, then it will be at fullscreen.
' @sAssociatedScreenID: String, Often times the screen right before the linear video player screen is displayed has a close association. Keep a record of the ID associated with the associated screen.
' @bAllowTransportToAppear: Boolean, Should the EPG Overlay appear automatically when video starts to play and goes fullscreen?
Function playLinearVideoContent(content, bMinimized = true, sAssociatedScreenID = "", bAllowTransportToAppear = false)
  if content <> invalid
    tubiLog("LinearVideoPlayerScreenHelpers.playLinearVideoContent")

    ' we make changes to the content from this point forward. If we don't clone, those changes will initialize
    ' a variety of unexpected and unwanted callbacks, as the passed in content potentially exists on a number
    ' of fields that are being observed (for instance: HomeScreen.contentFocused)
    clonedContent = content.clone(true)
    if clonedContent.needsLogin = true AND isLoggedInUser() = false  'Check for user signed In status because we do not refetch the content and so it will not pass through metadata translate process.
      if bMinimized = false
        callbackAfterSignInParams = {"content": content, "bMinimized": false, "sAssociatedScreenID": clonedContent.associatedScreenID, "bAllowTransportToAppear": bAllowTransportToAppear}
        startSignIn(afterSignInPlayLockedLinearContent, callbackAfterSignInParams)
      end if
    else 'Content is not locked so just play the content

      videoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)

      if videoPlayer = invalid
        videoPlayer = CreateObject("roSGNode", "LinearVideoPlayerScreen")
        videoPlayer.observeFieldScoped("navigateToEPGScreen", "onLinearVideoPlayerRequestingTVGuide")
        videoPlayer.id = m.constants.ui.screenIds.linearVideoPlayerScreen

        ' onVideoPlayerVisibleChange exists in ContentController
        videoPlayer.observeFieldScoped("visible", "onLinearVideoPlayerVisibleFullscreenChange")
        videoPlayer.observeFieldScoped("fullscreen", "onLinearVideoPlayerVisibleFullscreenChange")
        videoPlayer.observeFieldScoped("channelSelectedUpdated", "onLinearChannelSelectedFromGuide")
        videoPlayer.observeFieldScoped("linearOverlayNavigateWithinPageInfo", "onNavigateWithinPageInfoChange")
        videoPlayer.observeFieldScoped("linearOverlayComponentInteractionInfo", "onComponentInteractionInfoChange")
        videoPlayer.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")

        initVideoTracking(videoPlayer) 'initializeYoubora. Regular and linear video players share tracking functions, which are found in VideoHelpers
        setInScreenCache(videoPlayer)
      end if

      screen = getFromScreenCache(sAssociatedScreenID)
      if screen <> invalid
        videoPlayer.trackingPageContext = screen.trackingPageInfo
      end if

      unObserveAllStateDependentLinearVideoPlayerFields(videoPlayer)
      videoPlayer.associatedScreenID = sAssociatedScreenID
      videoPlayer.allowTransportToAppear = bAllowTransportToAppear

      ' set general observers for all content
      videoPlayer.observeFieldScoped("sendVideoTrackingStart", "onVideoTrackingStart")
      if videoPlayer.visible = false
        videoPlayer.visible = true
      end if
      ' it's necessary to push the screen after the content has been set on the videoPlayer component,
      ' so NavigateToPage and PageLoad events contain the necessary content id information

      bLinearPlayerPlayingThisContent = isLinearPlayerPlayingThisContent(clonedContent)
      if bLinearPlayerPlayingThisContent = false
        videoPlayer.originalContent = content
        videoPlayer.content = clonedContent
        videoPlayer.updateContent = true
      end if

      if bMinimized = false
        maximizeLinearPlayer(clonedContent)
      else
        '//play at minimized state
        showHideLinearVideoPlayerSpinner(true)
        videoPlayer.loading = true
        animateLinearVideoPlayerToMinState(0, false)
      end if

      if bLinearPlayerPlayingThisContent = false
        ' In order to prepare the linear stream, a number of actions need to be taken
        ' 1) add the rainmaker parameters to the stream url - YoSpace will make calls to rainmaker in order to
        '    to stitch the ads and needs the rainmaker parameters to make the rainmaker requests
        ' 2) fetch the response from the hls manifest and parse out the YoSpace "analytics url" which is the url
        '    that will be used to poll for ads
        ' 3) compose the final stream url from the "analytics url" and the original stream url found in the
        '    matrix/homescreen response
        ' 4) pass the content with the updated stream url to the linear video player

        ' add ad params to video urls
        updatedVideoResources = getUpdatedLinearVideoResources(clonedContent)
        clonedContent.videoResources = updatedVideoResources

        streamUrl = getLiveUrlFromResources(clonedContent)
        if streamUrl <> invalid
          ' store the content on videoPlayer so it can be retrieved after the manifest is fetched
          videoPlayer.content = clonedContent
          getLiveStreamManifest(streamUrl)
        else
          ' no stream url so show an error
          reactToLinearVideoPlayerErrorState()
        end if
      end if
    end if
  end if
End Function


' The Linear Video Screen has indicated that the EPG Screen should be displayed now.
Function onLinearVideoPlayerRequestingTVGuide()
  currentScreen = getCurrentScreen()
  if currentScreen <> invalid AND currentScreen.id = m.constants.ui.screenIds.linearVideoPlayerScreen AND currentScreen.content <> invalid
    if currentScreen.associatedScreenID = m.constants.ui.screenIds.epgScreen
      '//If the previous screen was the EPGScreen then simply back out of the player using the following function
      returnToPreviousScreenFromLinearVideo()
    else
      '//If the previous screen was not the EPG Screen, then load epg screen and jump to the current playing video
      channelId = currentScreen.content.id

      showDefaultEPGScreen()
      epgScreen = getFromScreenCache(m.constants.ui.screenIds.epgScreen)
      animateLinearVideoPlayerToMinState()

      cachedAllEPGChannels = getFromContentCache(m.constants.ui.contentIds.timeGridContent)
      isEPGDataPrecached = (cachedAllEPGChannels <> invalid AND cachedAllEPGChannels.getChildCount() > 0 AND shouldRefresh(cachedAllEPGChannels.getChild(0)) = false)
      if isEPGDataPrecached = true
        '//If the EPG data has not already been cached, then there is no need to try to jumpToRow now. This will happen once the data loads
        epgScreen.jumpToRowItemByID = [channelId, ""]
      end if

      '//Focus side nav to EPG option
      sEPGSideNavID = m.constants.ui.screenIdToSideNavId[m.constants.ui.screenIds.epgScreen]
      focusSideNavOption(sEPGSideNavID)

      '//Set EPGScreen background to ensure the epgScreen appears properly: i.e. background gradient is displayed, proper bground is displayed upon sideNav focus
      m.backgroundGroup.backgroundInfo = {
        type : m.constants.ui.backgroundTypes.epg
        uriList : currentScreen.content.backgrounds
      }
    end if
  end if
End Function


Function getUpdatedLinearVideoResources(content)
  auth = TubiAuth(m.constants, m.Request)
  adLib = TubiAdsLimited(m.constants, auth)

  ' add the ad parameters for the content. Back end will forward these parameters to YoSpace
  ' so that YoSpace can have them when YoSpace makes ad requests for SSAI
  adParams = adLib.getRainmakerParamsForLinear(content)

  newVideoResources = []
  newResource = invalid

  if content <> invalid AND content.videoResources <> invalid
    for each resources in content.videoResources
      for each resource in resources
        if resource.type = m.constants.player.drmTypes.hlsv3
          if resource.url <> invalid
            newResources = []
            newResource = resource
            newResource.url = m.request.addParamsToUrl(newResource.url, adParams)
            newResources.push(newResource)
            newVideoResources.push(newResources)
          end if
          exit for
        end if
      end for
      if newResource <> invalid
        exit for
      end if
    end for
  end if

  ' pass the updated url back through output interface so video helpers can proceed with playing the video
  return newVideoResources
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

  if videoPlayer <> invalid AND videoPlayer.content <> invalid
    if getCurrentScreen() = invalid or getCurrentScreen().id <> m.constants.ui.screenIds.linearVideoPlayerScreen
      pushScreen(videoPlayer, true, true)
    end if
    bAnimate = false
    if isLinearPlayerPlayingThisContent(content) = true
      '//If the video is already playing then animate it view in case it is being displayed on the homescreen in a corner
      bAnimate = true
    end if

    videoPlayer.unobserveFieldScoped("state")
    videoPlayer.unobserveFieldScoped("backButtonPressed")
    videoPlayer.observeFieldScoped("state", "onLinearVideoPlayerState")
    videoPlayer.observeFieldScoped("backButtonPressed", "onLinearVideoPlayerBackPressed")

    if videoPlayer.fullscreen = false
      '//stop the background artwork from transitioning and from displaying while player is in fullscreen. We can't use shouldRotateBackgrounds because we still need the gradients from backgroundGroup
      sBackgroundType = m.constants.ui.backgroundTypes.epg
      m.backgroundGroup.backgroundInfo = {
        type: sBackgroundType
        uriList: []
      }

      videoPlayer.trackingPageContext = videoPlayer.trackingPageInfo
      m.backgroundGroup.posterVisible = true
      showHideLinearVideoPlayerSpinner(false)
      videoPlayer.loading = false
      getDataForTimeGrid()
      repositionLinearVideoPlayerToMaxState(bAnimate)
    end if

  end if
End Function


Function getDataForTimeGrid()
  tubilog("LinearVideoPlayerScreenHelpers.getDataForTimeGrid")
  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
  epgChannelList  = getFromContentCache(m.constants.ui.contentIds.timeGridContent)
  if videoPlayer <> invalid
    if epgChannelList = invalid or (epgChannelList <> invalid AND shouldRefresh(epgChannelList.getChild(0)) = true) 'There is no cached contents
      fetchEPGScreenChannels(videoPlayer)
    else if epgChannelList <> invalid
      videoPlayer.timeGridContent = epgChannelList
      videoPlayer.updateTimeGridContent = true
      videoPlayer.timeGridContentLoading = false
    end if
  end if
End Function


Function isLinearPlayerPlayingThisContent(content)
  bPlaying = false
  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
  if content <> invalid AND videoPlayer <> invalid AND videoPlayer.content <> invalid
    if videoPlayer.content.id = content.id AND videoPlayer.state = "playing"
      bPlaying = true
    end if
  end if

  return bPlaying
End Function


Function isLinearPlayerPlaying()
  bPlaying = false
  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
  if videoPlayer <> invalid AND videoPlayer.state = "playing"
    bPlaying = true
  end if

  return bPlaying
End Function


Function isLinearPlayerLoading()
  bLoading = false
  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
  if videoPlayer <> invalid
    bLoading = videoPlayer.loading
  end if

  return bLoading
End Function


Function getLiveStreamManifest(streamUrl)
  tubiLog("LinearVideoPlayerScreenHelpers.getLiveStreamManifest")
  liveManifestReqType = m.constants.reqNames.getLiveManifest

  if isString(streamUrl)
    streamUrl = streamUrl.trim()
  end if

  m.linearManifestRequest = m.makeRequest({
    url: streamUrl
    requestType: liveManifestReqType
    successCallback: onLiveStreamManifestResponse
    errorCallback: onManifestError
    responseType: "assocarray"
  })
End Function


Function onLiveStreamManifestResponse(response)
  tubiLog("LinearVideoPlayerScreenHelpers.onLiveStreamManifestResponse")

  if response <> invalid AND isString(response.res)
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

    ' piece together the modified playback url
    ' The url that will be used for the video stream must be built from the original url returned by the API
    ' and from the "analytics url"/ad polling url. For more info, please see:
    ' https://docs.google.com/document/d/14Ovs4KzV0iwloKtILjSZhQxT2NcGdGCm80MIMvB9EfE
    originalUrl = invalid

    modifiedUrl = ""
    if content <> invalid AND content.videoResources <> invalid
      videoResources = content.videoResources

      ' Eventhough LIVE has only hlsv3 contents, we are keeping newVideoResources as 2 dimensional array of arrays like VOD to make it consistent.
      ' Also in future, we may have HEVC/4k/DRM support for LIVE as well. At that time, we need minor updates to 2 dimensional array with CODEC grouping.
      newVideoResources = []

      for each resources in videoResources
        for each resource in resources
          newResources = []
          newResource = resource
          if resource.type = m.constants.player.drmTypes.hlsv3
            if resource.url <> invalid
              ' For linear content that is serving ads via YoSpace, the video resource that is used to fetch
              ' the manifest actually redirects through a Tubi "manifest server" and to a YoSpace server
              ' to get the manifest response. When reconstructing the YoSpace manifest url to include the
              ' session id, we need to use the original YoSpace stream url and not the video resource url
              ' provided by UAPI. We get the original YoSpace stream url from the "location" header since
              ' it is a redirect.
              if response.headers <> invalid AND response.headers.location <> invalid
                originalUrl = m.request.removeCharlesProxy(response.headers.location) ' Remove Charles proxy appended by Charles rule for clean redirect.
              else
                originalUrl = resource.url
              end if
              modifiedUrl = constructModifiedLinearVideoUrl(originalUrl, pollUrl)
              newResource.url = m.request.passThroughCharlesProxy(modifiedUrl)
            end if
          end if

          newResources.push(newResource)
          newVideoResources.push(newResources)
        end for
      end for

      content.videoResources = newVideoResources
    end if

    videoPlayer.content = content
    videoPlayer.updateContent = true
    videoPlayer.pollUrl = pollUrl
    videoPlayer.control = "play"
  end if
End Function


Function onManifestError(error)
  tubiLog("LinearVideoPlayerScreenHelpers.onManifestError")
  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
  if videoPlayer <> invalid
    code = invalid
    if error <> invalid
      code = error.code
    end if
    reactToLinearVideoPlayerErrorState("", code)
  end if
End Function


Function constructModifiedLinearVideoUrl(originalUrl, pollUrl)
  modifiedUrl = originalUrl
  if isString(originalUrl) AND isString(pollUrl)
    pollUrl = pollUrl.trim()
    pollUrlParts = getUrlParts(pollUrl, ";")
    originalUrl = originalUrl.trim()
    originalUrlParts = getUrlParts(originalUrl)
    if pollUrlParts <> invalid AND originalUrlParts <> invalid
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
    for each resources in content.videoResources
      for each resource in resources
        if resource.type = m.constants.player.drmTypes.hlsv3
          streamUrl = resource.url
          exit for
        end if
      end for
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
    videoPlayer.loading = false
    m.backgroundGroup.posterVisible = true
    stopLinearVideoContent()
    unObserveAllStateDependentLinearVideoPlayerFields(videoPlayer)
    videoPlayer.visible = false
    videoPlayer.content = invalid
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
      nDuration = .6
    end if

    clearMinimizedLinearPlayerAnimation()
    resizeToLocation(videoPlayer, 1920, 1080, [0,0], nDuration)
  end if
End Function


Function animateLinearVideoPlayerToMinState(nDuration = .25, bVisible = true)
  '//Add video player to LinearPlayerGroup

  tubiLog("LinearVideoPlayerScreenHelpers.animateLinearVideoPlayerToMinState")
  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
  if videoPlayer <> invalid

    screen = getFromScreenCache(videoPlayer.associatedScreenID)
    if screen <> invalid
      videoPlayer.trackingPageContext = screen.trackingPageInfo
    end if

    if videoPlayer.fullscreen <> false
      videoPlayer.fullscreen = false
    end if

    videoPlayer.unobserveFieldScoped("state")
    videoPlayer.observeFieldScoped("state", "onLinearVideoPlayerStateWhileInMinState")

    linearPlayerParentGroup = m.LinearPlayerGroup

    nWidth = m.constants.ui.imageSizes.epgLinearVideoPlayerOnEPGScreen_minimizedDimension[0]
    nHeight = m.constants.ui.imageSizes.epgLinearVideoPlayerOnEPGScreen_minimizedDimension[1]
    nPosition = m.constants.ui.imageTranslations.epgLinearVideoPlayerOnEPGScreen_minimizedTranslation
    m.LinearVideoPlayerSpinner.translation = [1260, 320]


    linearPlayerParentGroup.appendChild(videoPlayer)

    clearMinimizedLinearPlayerAnimation()
    m.animationMinimizedLinearPlayer = resizeToLocation(videoPlayer, nWidth, nHeight, nPosition, nDuration)
    if nDuration > 0 AND m.animationMinimizedLinearPlayer <> invalid
      m.animationMinimizedLinearPlayer.observeField("state", "onLinearPlayerMinimizedComplete")
    else
      '//If the animation is instant (and/or this is on a limited UI device), then call the animation-complete function immediately
      displayLinearPlayerProgrammingDataOnHomescreen()
    end if
    videoPlayer.visible = bVisible
  end if
End Function


' The player is done getting to the minimized state
Function onLinearPlayerMinimizedComplete(msg)
  if msg.getData() = "stopped"
    displayLinearPlayerProgrammingDataOnHomescreen()
  end if
End Function


Function clearMinimizedLinearPlayerAnimation()
  if m.animationMinimizedLinearPlayer <> invalid
    m.animationMinimizedLinearPlayer.unobserveField("state")
  end if
  m.animationMinimizedLinearPlayer = invalid
End Function


' Display the programming data for the video player, but only do this on the homescreen
Function displayLinearPlayerProgrammingDataOnHomescreen()
  currentScreen = getCurrentScreen()
  if currentScreen <> invalid AND currentScreen.subType() = "HomeScreen"
    clearMinimizedLinearPlayerAnimation()
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
      videoPlayer.loading = false

      displayLinearPlayerProgrammingDataOnHomescreen()
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
  if bFullScreen = false
    m.SideNav.visible = true
    if bVisible = false
      '//Is the video player no longer visible and not in fullscreen? i.e. the news container is no longer in focus
      m.logoGroup.visible = true
      m.clock.visible = false
    end if
  else
    '//Is the video player in fullscreen?
    m.SideNav.visible = false
    m.logoGroup.visible = false
    m.clock.visible = false
  end if
End Function


Function onLinearVideoPlayerState(msg)
  tubiLog("LinearVideoPlayerScreenHelpers.onLinearVideoPlayerState")
  videoPlayer = msg.getRoSGNode()
  if videoPlayer <> invalid
    tubiLog("LinearVideoPlayerScreenHelpers.onLinearVideoPlayerState state = " + msg.GetData())
    state = msg.GetData()
    if state = "error"
      reactToLinearVideoPlayerErrorState(videoPlayer.errorMsg, videoPlayer.videoErrorCode)
    else if state = "playing"
      showHideLinearVideoPlayerSpinner(false)
      videoPlayer.loading = false
    else if state = "finished"
      '//Assume a finished video stream is an error
      reactToLinearVideoPlayerErrorState()
    end if
  end if
End Function


Function onLinearVideoPlayerBackPressed()
  tubiLog("LinearVideoPlayerScreenHelpers.onLinearVideoPlayerBackPressed")
  returnToPreviousScreenFromLinearVideo(true)
End Function


' Go back to the main window. Either stop the video or continue playing it.
' If the video continues to play, then animate it down to the corner of the screen.
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

  currentScreen = getCurrentScreen()
  if currentScreen <> invalid AND currentScreen.id = m.constants.ui.screenIds.linearVideoPlayerScreen
    if bContinueToPlay = true
      ' sports epg screen, news epg screen, or entertainment epg screen might not have the contentID. So search for content ID and handle the back logic
      sBackScreenID = currentScreen.associatedScreenID
      if isAnEPGScreenID(sBackScreenID) = true
        handleBackToEPGScreen(videoPlayer.originalContent, sBackScreenID)

        '//animate the video player into the corner
        animateLinearVideoPlayerToMinState()
      else if sBackScreenID = m.constants.ui.screenIds.epgScreen
        jumpToParentScreenContentByID(videoPlayer.content.id, "", sBackScreenID)
        popScreen(true, true)

        '//animate the video player into the corner
        animateLinearVideoPlayerToMinState()
      else if sBackScreenID = m.constants.ui.screenIds.searchScreen
        popScreen(true, true)
        stopAndHideLinearVideoPlayer()
      else
        if m.enteredFromDeeplink = true
          jumpToParentScreenContentByID(videoPlayer.content.id, "", sBackScreenID)
        end if
        popScreen(true, true)

        '//animate the video player into the corner
        animateLinearVideoPlayerToMinState()
      end if
    else
      ' remove the video player screen to reveal the home screen/epg Screen
      popScreen(true, true)
    end if
  end if
End Function


' Stop the linear video player
Function stopLinearVideoContent()
  tubiLog("LinearVideoPlayerScreenHelpers.stopLinearVideoContent")
  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
  if videoPlayer <> invalid
    '//reset and Hide the loading indicator.
    showHideLinearVideoPlayerSpinner(false)
    videoPlayer.loading = false
    videoPlayer.unobserveFieldScoped("sendVideoTrackingStart")
    videoTrackingStop() 'stops youbora tracking
    videoPlayer.control = "stop"
    videoPlayer.visible = false
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
' reactToLinearVideoPlayerErrorState
'
' @error_message: string, an error message that will be displayed to the user
' @errorCode: integer, the video player error code (usually a negative number)
Function reactToLinearVideoPlayerErrorState(error_message = "", errorCode = invalid)
  tubiLog("LinearVideoPlayerScreenHelpers.showLinearPlayerError")
  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
  if videoPlayer <> invalid AND videoPlayer.fullscreen = true
    returnToPreviousScreenFromLinearVideo(false)
    errorMessage = getTranslation("videoPlayer_error_failed_description")
    if error_message <> invalid AND error_message <> ""
      errorMessage = error_message
    end if

    ' reset the video player state in case an error occurs during the next attempt at playing a video
    videoPlayer.state = ""

    if errorCode = invalid
      errorCode = ""
    end if
    userErrorCode = getUserFacingErrorCode(m.constants.errors.context.linearPlayerScreen, m.constants.errors.subtypes.playerPlaybackError, errorCode.toStr())

    videoId = 0
    if videoPlayer <> invalid AND videoPlayer.content <> invalid AND videoPlayer.content.id <> invalid
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
    'in case of error retrieving the player content, then stop the countdown timer and stop the video player. That way, focus on stay on the current content but not automatically try to play the error content.
    if isAnEPGScreenID(videoPlayer.associatedScreenID) = true
      showErrorModal(modalInfo, onRetryLinearPlayerError, invalid, resetEPGScreenContent, invalid)
    else
      showErrorModal(modalInfo, onRetryLinearPlayerError, invalid)
    end if

    stopLinearVideoContent() '//In case the video is still playing
  else
    '//If in mimimum mode, do not show error modal but instead error out gracefully
    reactToLinearVideoPlayerErrorStateInNonFullscreenState()
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


' A new channel is selected from the channel guide. Start playing that new channel
Function onLinearChannelSelectedFromGuide(msg)
  tubiLog("LinearVideoPlayerScreenHelpers.onLinearChannelSelectedFromGuide")
  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
  channel = videoPlayer.channelSelected

  'this flag is used to differentiate whether a channel is always played or only played if it is different than whats already playing.
  ' In case of EPG we do not want to attempt to play the channel which is already playing full screen.
  playProvidedChannel = true
  if videoPlayer <> invalid
    if channel <> invalid AND channel.videoResources <> invalid
      if isLinearPlayerPlayingThisContent(channel) = true
        playProvidedChannel = false
      end if

      if playProvidedChannel = true
        oldTrackingPageInfo = videoPlayer.trackingPageInfo
        trackingComponentInfo = videoPlayer.trackingComponentInfo
        stopLinearVideoContent()
        playLinearVideoContent(channel, false, videoPlayer.associatedScreenID, videoPlayer.allowTransportToAppear)
        newTrackingPageInfo = videoPlayer.trackingPageInfo
        screenTrackingNavigate(oldTrackingPageInfo, newTrackingPageInfo, trackingComponentInfo)

        if videoPlayer.associatedScreenID <> invalid AND videoPlayer.associatedScreenID <> ""
          '//Tell the homescreen to focus on the same channel so when the user backs out, the channel that is playing is the same one that is in focus
          '//   Note: since the video channel guide and the homescreen's live TV container are loaded independently from each other, we cannot assume they are in sync
          sContainerID = ""
          if videoPlayer.associatedScreenID = m.constants.ui.screenIds.homeScreen
            sContainerID = videoPlayer.content.parentId
            jumpToParentScreenContentByID(channel.id, sContainerID, videoPlayer.associatedScreenID)
          end if
        end if
      end if
    else
      '//Incorrect data, display an error
      reactToLinearVideoPlayerErrorState()
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
    playLinearVideoContent(content, false, videoPlayer.associatedScreenID, videoPlayer.allowTransportToAppear)
  end if
End Function


Function handleBackToEPGScreen(content, screenId)
  if content <> invalid
    contentId = content.id
    isContentPresent = doesEpgScreenHaveContent(contentId,screenId)
    'if Content is not present in sports, news, or entertainment screen, then go back to 'all epg' screen.
    if isContentPresent = false
      jumpToParentScreenContentByID(contentId, "", m.constants.ui.screenIds.EPGScreen)
      showDefaultEPGScreen()
    else
      ' if content is present, then go back to sports/news/entertainment screen
      jumpToParentScreenContentByID(contentId, "", screenId)
      popScreen(true, true)
    end if
  end if
End Function


'searches the contentId in timegrid content of screen with screenId.
'@param contentId: string content Id to search
'@param screenId: string Id of the screen to be searched for timeGridContent
Function doesEpgScreenHaveContent(contentId, screenId) as boolean
  screen = getFromScreenCache(screenId)
  isContentPresent = false
  if isAnEPGScreen(screen) = true AND screen.timeGridContent <> invalid
    for i = 0 to screen.timeGridContent.getChildCount() - 1
      if screen.timeGridContent.getChild(i).id = contentId
        isContentPresent = true
        exit for
      end if
    end for
  end if
  return isContentPresent
End Function
