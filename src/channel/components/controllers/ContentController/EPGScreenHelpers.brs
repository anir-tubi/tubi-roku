' Show the epg Screen
' @constants: assocArray, constants as set in Constants.brs
' @screenID: string, What kind of epgScreen do you wish to make: regular, movies, or TV
Function showEPGScreen(constants, screenID = "")
  tubiLog("EPGScreenHelpers.showEPGScreen")
  if isNonEmptyString(screenID) <> true
    screenID = constants.ui.screenIds.epgScreen
  end if
  showHideLogo(m.constants.logoType.hide)

  epgScreen = getFromScreenCache(screenID)
  if epgScreen <> invalid
    ' this is required for setting focus to epgscreen after activation/signout
    epgScreen.shouldFocusWhenPushed = m.top.fadeInContentController
    changeEPGScreenBackground(epgScreen) ' ensure background of the epg screen is used immediately instead of previous screen's background
    epgScreen.signedIn = isLoggedInUser()

  else
    displayDefaultBackground() ' clear background from previous screens until epgscreen loads
    showHideSpinner(true)

    epgScreen = CreateObject("roSGNode", "EPGHomeScreen")
    epgScreen.observeFieldScoped("backgroundUriList", "onEPGScreenBackgroundChange")
    epgScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
    epgScreen.observeFieldScoped("programGuideNavigateWithinPageInfo", "onNavigateWithinPageInfoChange")
    epgScreen.observeFieldScoped("programGuidecomponentInteractionInfo", "onComponentInteractionInfoChange")
    epgScreen.observeFieldScoped("transportVoiceResponse", "onTransportVoiceResponse")
    epgScreen.observeFieldScoped("loadAllChannels", "onLoadAllEPGChannels")
    epgScreen.observeFieldScoped("scrollingStatus", "onEPGScrollingStatusChange")
    epgScreen.observeFieldScoped("refreshEPGScreenVideoPlay", "onRefreshEPGScreenVideoPlay")
    epgScreen.observeFieldScoped("epgScreenOkPressed", "onEPGScreenOKPressed")
    epgScreen.signedIn = isLoggedInUser()

    m.playerFullscreenCountdownTimer.unobserveFieldScoped("fire") '//Stop listening to timer before listing to it in case a previous screen started the timer
    m.playerFullscreenCountdownTimer.observeFieldScoped("fire", "onFullscreenCountdown")

    epgScreen.shouldFocusWhenPushed = m.top.fadeInContentController


    epgScreen.id = screenID

    refreshEPGScreen(epgScreen)

    setInScreenCache(epgScreen)

  end if

  shouldSendPageLoadEvent = true
  if epgScreen.contentReady = false
    'First batch of Contents are not ready. So send the pageloadEvent after onContentReady()
    shouldSendPageLoadEvent = false
    showHideSpinner(true)
  else
    showHideSpinner(false)
  end if

  pushScreen(epgScreen, true, shouldSendPageLoadEvent)

End Function


'//Refresh the content and the enabling of the top nav of the epg screen
Function refreshEPGScreen(epgScreen)
  tubiLog("EPGScreenHelpers.refreshEPGscreen")
  mode = m.constants.ui.contentMode.epgScreen
  epgScreen.signedIn = isLoggedInUser()
  epgChannelList = getFromContentCache(m.constants.ui.contentIds.timeGridContent)


  if epgChannelList = invalid OR (epgChannelList <> invalid AND shouldRefresh(epgChannelList.getChild(0)) = true)'There is no cached contents
    setEPGScreenLoading(epgScreen)
    fetchEPGScreenChannels(epgScreen, mode)
  else if epgChannelList <> invalid
    epgScreen.timeGridContent = epgChannelList
    setTimeGridContentLoadingToComplete(epgScreen)
  end if
End Function


Function fetchEPGScreenChannels(screen, mode = "")
  tubiLog("EPGScreenHelpers.fetchEPGScreenChannels")

  screen.trackingLoadStartTime = UpTime(0)

  screen.unobserveFieldScoped("contentReady")
  screen.observeFieldScoped("contentReady", "onEPGscreenContentReady")
  fetchEPGChannels(screen, mode)
End Function


' @param screen: roSGNode, Screen that is fetching and is hosting the EPG Channels: i.e. epgScreen, Linear Video Player Screen
' @param mode: String, The mode that will dictate that what kind of channels will be gathered for the EPG: i.e. all, sports, news, entertainment
Function fetchEPGChannels(screen, mode = "tubitv_us_linear")
  epgContainerInfo = m.tensorapi.getEPGChannelidsReqInfo(mode)

  screen.timeGridContentLoading = true
  screen.timeGridContent = invalid 'a fresh start
  isSignedIn = isLoggedInUser()

  channelRequest = m.makeRequest({
    url: epgContainerInfo.url
    requestType: m.constants.reqNames.getEPGChannelIds
    options: epgContainerInfo.options
    successCallback: onEpgChannelListResponse
    errorCallback: onEpgError 'if there is no program list then there wont be any programs to pull.
    responseType: "node"
    requestorID: screen.ID
    isSignedInUser: isSignedIn
  })

  ' Store the unique ID associated with channel request to identify the program requests created using response from above api call.
  ' If there any EPG program calls returned which does not belong to current epgFetchUniqueId, will be discarded.
  m.epgFetchUniqueId = channelRequest.id

End Function


Function fetchEPGChannel(screenId, channelID, successCallback, errorCallback)
  cachedChannel = invalid
  cachedAllChannels = getFromContentCache(m.constants.ui.contentIds.timeGridContent)

  if cachedAllChannels <> invalid AND cachedAllChannels.getChildCount() > 0 AND shouldRefresh(cachedAllChannels.getChild(0)) = false
    '//go thru the channels and find the desired channel
    for i = 0 to cachedAllChannels.getChildCount() - 1
      cachedChannelTemp = cachedAllChannels.getChild(i)
      if cachedChannelTemp.id = channelID
        if shouldRefresh(cachedChannelTemp) = false
          '//Just in case the logic to determine the freshness of the AllChannels data is different from the Channel data,
          '//(at the time of writing this code, the logic should be the same - aka all channels have the same freshness),
          '//we should check to see if channel data within the AllChannels data is fresh.
          cachedChannel = cachedChannelTemp
        end if
        exit for '//found the desired channel, now exit the for loop
      end if
    end for
  end if

  if cachedChannel = invalid
    '//If the channel data was not found in the AllChannels data, then see if the channel data is available in the cache
    cachedChannelTemp = getFromContentCache(channelID)
    if shouldRefresh(cachedChannel) = false
      '//make sure the data is fresh
      cachedChannel = cachedChannelTemp
    end if
  end if

  if cachedChannel <> invalid
    '//The channel data has been cached, so call the success callback immediately.
    instantResponse = CreateObject("roSGNode", "ContentNode")
    instantResponse.addField("requestorID", "string", false)
    instantResponse.requestorID = screenId
    '//TODO: Think about better logic of just getting data from Cached Channel. But for now, if we are using contentNode,
    ' we need to clone the original channel which is present in Cache. Otherwise, just appending/replacing the node will reparent the node and next time
    'when Cache has been used, it will be missing the channel which was already reparented.
    clonedCachedChannel = cachedChannel.clone(true)
    instantResponse.appendChild(clonedCachedChannel)
    successCallback(instantResponse, false)
  else
    '//call the API to get new channel data
    channelListIDs = [channelID]
    isSignedIn = isLoggedInUser()
    epgProgramInfo = m.tensorapi.getEPGProgramReqInfo(channelListIDs)
    m.makeRequest({
      url: epgProgramInfo.url
      requestType: m.constants.reqNames.getEPGPrograms
      options: epgProgramInfo.options
      successCallback: successCallback
      errorCallback: errorCallback
      responseType: "node"
      storeInCacheUponSuccess: true
      requestorID: screenId
      isSignedInUser: isSignedIn
    })
  end if

End Function



Function onEpgChannelListResponse(response)
  tubiLog("EPGScreenHelpers.onEpgChannelListResponse")
  'check if this is the epgScreen for which response was meant to be.
  if response <> invalid AND response.requestorID <> invalid
    screen = getFromScreenCache(response.requestorID)
    if screen = invalid
      screen = getCurrentScreen()
    end if

    if screen.id = response.requestorID AND m.epgFetchUniqueId = response.fetchId

      screen.timeGridContent = response
      ' Storing it under linear video player screen so that we clear it when we remove linear player screen from cache.
      setInContentCache(screen.timeGridContent, m.constants.ui.screenIds.linearVideoPlayerScreen)
      nFetchInBatch = 10
      ' If jump_to certain channel(contentIdToFocusOnLoadComplete) has been requested after the load is complete, then start with fetching that channel + 5 up + 5 down channels from v2/epg API response.
      ' This way, we can render the epg as soon as the first batch is in and then load the rest of the epg.
      ' This happens on deeplink and epg overlay on the channel selected from the home-screen.
      ' If no jump_to channel(contentIdToFocusOnLoadComplete) has been specified, then just load from the first to last channel(else part)

      ' uniqueChannelIdsList: array of channelIds that are unique and are in the order by which the channels need to be fetched from the epg/programming API.
      ' ChannelListAA: a temporary AA, is used to remove the duplicate channel IDs so that we do not have to fetch the same channel twice.
      ' using both channelListAA and uniqueChannelIdsList duplicates are removed without affecting the order that channel-programs need to be fetched.

      ' logic explanation:
      ' lets say v2/epg api returned channels Id list: [567888,567889,567890,567891,567892,567889,567893,567889]
      ' EPG will be rendered as [567888,567889,567890,567891,567892,567889,567893,567889] 567888 as first, 567889 as second and 567889 as last, and so on.
      ' if contentIdToFocusOnLoadComplete = 567892 then
      '     channelListAA list is only used to check if channel-Id has been already added to the uniqueIdlist or not.
      '     uniqueChannelIdsList=[567892, 567891, 567889, 567890, 567893,567888]

      channelListAA = {}
      index = 0
      m.uniqueChannelIdsList = []

      if isNonEmptyString(screen.contentIdToFocusOnLoadComplete) = true
        for i = 0 to response.getChildCount() - 1
          epgChannel = response.getChild(i)

          if epgChannel.id = screen.contentIdToFocusOnLoadComplete
            index = i
            channelListAA[epgChannel.id] = true
            m.uniqueChannelIdsList[0] = epgChannel.id

            upIndex = response.getChildCount()
            for j = 1 to upIndex
              if index - j >= 0
                epgChannel = response.getChild(index - j)
                if channelListAA[epgChannel.id] <> true
                  channelListAA[epgChannel.id] = true
                  m.uniqueChannelIdsList.push(epgChannel.id) ' store it Array to preserve the order of the original list from the server.
                end if
              end if

              if index + j < upIndex
                epgChannel = response.getChild(index + j)
                if channelListAA[epgChannel.id] <> true
                  channelListAA[epgChannel.id] = true
                  m.uniqueChannelIdsList.push(epgChannel.id) ' store it Array to preserve the order of the original list from the server.
                end if
              end if
            end for

            exit for
          end if
        end for
      else
        for i = 0 to response.getChildCount() - 1 'If no jump_to channel has been specified, then just load from first to last channel(epg screen)
          epgChannel = response.getChild(i)
          if channelListAA[epgChannel.id] <> true
            channelListAA[epgChannel.id] = true
            m.uniqueChannelIdsList.push(epgChannel.id) ' store it Array to preserve the order of the original list from the server.
          end if
        end for
      end if
      totalNumChannels = m.uniqueChannelIdsList.Count()

      if totalNumChannels <= 0
        onEPGError(response)
      end if
      ' make api request for first 10 visible channels. Then rest will be fetched after we receive programs for first 10 channels
      makeEPGProgramCalls(response.requestorID, nFetchInBatch)

    end if
  end if
End Function


' @param requestorID: String, Id for the requesting screen - epgScreen, Linear Video Player Screen
' @param nFetchInBatch: integer, number of channels to be fetched in one single api call
Function makeEPGProgramCalls(requestorID, nFetchInBatch = 10)
  remainingChannels = m.uniqueChannelIdsList.Count()
  if remainingChannels > 0
    if remainingChannels <= nFetchInBatch
      nFetchInBatch = remainingChannels
    end if

    channelListIDs = []
    for i = 0 to nFetchInBatch - 1
      epgChannel = m.uniqueChannelIdsList.shift()
      channelListIDs.push(epgChannel) ' [613683,613761,....]
    end for

    epgProgramInfo = m.tensorapi.getEPGProgramReqInfo(channelListIDs)
    isSignedIn = isLoggedInUser()

    m.makeRequest({
      url: epgProgramInfo.url
      requestType: m.constants.reqNames.getEPGPrograms
      options: epgProgramInfo.options
      successCallback: onEPGProgramSuccess
      errorCallback: onEpgProgramError
      responseType: "node"
      requestorID: requestorID
      fetchId: m.epgFetchUniqueId
      isSignedInUser: isSignedIn
    })
  end if

End Function


'This function calls appendOrAddTimeGridNewContents function which inturn adds or appends the batch data received to EPG TimeGrid.
'@response: roSGNode, The response contains program info for a set of channel
Function onEPGProgramSuccess(response)
  tubiLog("EPGScreenHelpers.onEPGProgramSuccess")
  screen = getFromScreenCache(response.requestorID)

  if screen = invalid
    screen = getCurrentScreen()
  end if

  'Discard the response if it is intended for different screen And also if there any EPG program calls returned which does not belong to current epgFetchUniqueId, will be discarded.
  if response.requestorID = screen.id AND m.epgFetchUniqueId = response.fetchId
    appendOrAddTimeGridNewContents(response, screen)

    if screen.timeGridContentLoading = true
      setTimeGridContentLoadingToComplete(screen)
    end if

    toBeFetchedChannelCount = m.uniqueChannelIdsList.count()

    if toBeFetchedChannelCount = 0
      ' Storing it under linear video player screen so that we clear it when we remove linear player screen from cache.
      setInContentCache(screen.timeGridContent, m.constants.ui.screenIds.linearVideoPlayerScreen)
    else if toBeFetchedChannelCount > 0
      makeEPGProgramCalls(response.requestorID)
    end if

  end if
End Function


' This function is used for batch of channels
Function onEpgProgramError(response)
  tubiLog("EPGScreenHelpers.onEpgProgramError ")
  screen = getCurrentScreen()
  'Check if the screen which requested the program info is the current Screen and user not moved away from this Screen. (especially in case of request timeout or slow internet cases)
  if screen <> invalid AND response <> invalid AND screen.id = response.requestorID AND m.epgFetchUniqueId = response.fetchId AND response.contentId <> invalid AND screen.timeGridContent <> invalid
    if screen.timeGridContent.getChildCount() > 0
      'Since a batch of programs errored out, set the validUntil to 0 so that next time, content will refetch.
      screen.timeGridContent.getChild(0).validUntil = 0
    end if

    toBeFetchedChannelCount = m.uniqueChannelIdsList.count()

    ' if all the responses for Channel information errored out then timeGrid will not have any content.
    if screen.timeGridContent.getChildCount() = 0
      onEPGError(response)
    else if toBeFetchedChannelCount = 0 ' all the batches are over and there are channels in the list, show whatever has been fetched successfully.
      setTimeGridContentLoadingToComplete(screen)
    else if toBeFetchedChannelCount > 0 'a batch of programs has errored out. So make rest of the api calls
      makeEPGProgramCalls(response.requestorID)
    end if
  end if
End Function


Function onEpgError(response)
  tubiLog("EPGScreenHelpers.onEpgError")
  screen = getCurrentScreen()
  showHideSpinner(false)
  code = 0
  'check if this error is meant for current Screen.
  if screen <> invalid AND response <> invalid AND screen.id = response.requestorID
    screen.timeGridContent = invalid
    setTimeGridContentLoadingToComplete(screen)

    if isAnEpgScreen(screen) = true
      '//Only display a error modal if this is an EPG Screen. An error message (on a non-EPGScreen) may display in a non-modal way based on
      '// both timeGridContent & updateTimeGridContent are invalid
      popScreen(false, false)

      'delete the screen from the screen cache so that the next time the user attempts to load the page, the page will be loaded
      'from scratch again. Otherwise an empty page will load and content will never be fetched.
      deleteFromScreenCache(screen.id)

      errorMessage = getTranslation("channelGuide_error_fetchContent_description")

      code = response.code
      errorCode = getUserFacingErrorCode(m.constants.errors.context.epgScreen, m.constants.errors.subtypes.fetchError, code)
      dialogEvent = {
        type: "dialog"
        values: {
          dialog_type: "NETWORK_ERROR"
          pageOneof: m.Tracking.getAnalyticsPage("linear_browse_page", {})
          dialog_action: "SHOW"
          dialog_sub_type: errorCode
        }
      }

      modalInfo = {
        message: getErrorMessage(errorMessage, errorCode)
        openTrackEvent: dialogEvent
        trackingTask: m.trackingLoggingTask
      }

      showErrorModal(modalInfo)
    end if
  end if
End Function


Function appendOrAddTimeGridNewContents(response, epgScreen)
  tubiLog("EPGScreenHelpers.appendOrAddTimeGridNewContents")

  if response <> invalid AND epgScreen.timeGridContent <> invalid
    for i = 0 to response.getChildCount() - 1
      if response.getChild(i) <> invalid
        newNodeid = response.getChild(i).id

        indices = m.NodeHelpers.getChildIndicesById(epgScreen.timeGridContent, newNodeid)
        loopCount = indices.Count()
        for each oldNodeIndex in indices
          if loopCount > 1 'if indices.count() > 1, it means there are duplicate channels in the timegrid, so clone the repsonse content to copy it over.
            newNode = response.getChild(i).clone(true)
          else
            newNode = response.getChild(i)
          end if

          oldNode = epgScreen.timeGridContent.getChild(oldNodeIndex)

          if oldNode <> invalid AND newNode <> invalid
            if oldNode.state = "partial" 'if state of programming node is partial that means channel info is serving as program node and so real programs can replace it.
              oldNode.removeChildIndex(0)
            end if
            for j = newNode.getChildCount() - 1 to 0 step -1
              newNode.getChild(0).reparent(oldNode, false)
            end for

          end if
        end for
      end if
    end for
  end if
End Function


Function onEPGScreenOKPressed()
  tubiLog("EPGScreenHelpers.onEPGScreenOKPressed")
  currentScreen = getCurrentScreen()
  stopCountdownTimer() 'stop previous counter

  if currentScreen <> invalid AND isAnEpgScreen(currentScreen)
    contentToPlay = currentScreen.LinearChannelToPlay
    if contentToPlay <> invalid
      if contentToPlay.needsLogin = true AND getStatsigExperimentResource("roku_linear_reg_gate", "roku_linear_reg_gate_v1").enabled = true
        showLinearPlayerSignInModal(contentToPlay)
      else
        startPlayVideo = true
        linearVideoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
        if linearVideoPlayer <> invalid AND linearVideoPlayer.content <> invalid
          if linearVideoPlayer.content.id = contentToPlay.id AND linearVideoPlayer.state = "playing"
            'do not Re-play same content
            startPlayVideo = false
          end if
        end if

        if startPlayVideo = true
          'If player is currently not playing the current content,
          'tell player to load and play the video associated with the selected item
          stopCountdownTimer() 'stop previous counter
          stopLinearVideoContent()
          playbackSource = {
            "srcForAnalytic": m.constants.player.playbackSource.unknown
            "srcForAds": m.constants.player.playbackOrigin.epg
            "playbackContainer": contentToPlay.parentId
          }
          playLinearVideoContent(contentToPlay, false, currentScreen.id, false, playbackSource)
        else
          stopCountdownTimer()
          maximizeLinearPlayer(contentToPlay)
        end if
      end if
    end if
  end if
End Function




Function onRefreshEPGScreenVideoPlay(msg)
  tubiLog("EPGScreenHelpers.onRefreshEPGScreenVideoPlay")
  refreshVideoPlay = msg.getData()
  epgScreen = msg.getRoSGNode()

  refreshEPGScreenVideoPlay(refreshVideoPlay, epgScreen)

End Function


'This function will handle the minimized video player on EPG Screen
' refreshVideoPlay = true  - Close the Video player since EPGScreen/EPG component lost focus (sideNav)
' refreshVideoPlay = false, there are two possibilities
'   1) epgScreen returning back from full video screen. Keep the video as it is, and make sure the video screen and focused channel are the same.
'   2) epgScreen:EPG component is gaining focus from sidenav. In this case restart the video.
'@epgScreen = node, Screen node
Function refreshEPGScreenVideoPlay(refreshVideoPlay, epgScreen)
  currentScreen = getCurrentScreen()
  screenID = currentScreen.id
  if screenID = m.constants.ui.screenIds.linearVideoPlayerScreen
    'do nothing. Linear screen is taken over.
  else if refreshVideoPlay = true
    m.backgroundGroup.posterVisible = true
    stopCountdownTimer()
    epgScreen.fullScreenCountdown = -1
    stopAndHideLinearVideoPlayer()
  else 'from FullScreen video
    linearVideoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)


    if linearVideoPlayer <> invalid AND linearVideoPlayer.state = "playing"
      if epgScreen.timeGridContent = invalid AND epgScreen.timeGridContentLoading = false
        'Anytime Video is playing and epgScreen is empty, then refresh the epgScreen.  This situation might happen when
        'when we play content directly from deeplink and epgScreen still does not have content if user presses backbutton.
        refreshEPGScreen(epgScreen)
        changeEPGScreenBackground(epgScreen)
        m.backgroundGroup.posterVisible = false
        startCountdownTimer()
      else
        changeEPGScreenBackground(epgScreen)
        m.backgroundGroup.posterVisible = false

        '//if the linear player is playing a video and it does not match with the current focus, then change focus to that of the playing video
        focusedChannel = epgScreen.linearChannelFocused
        if focusedChannel <> invalid AND focusedChannel.id <> invalid AND linearVideoPlayer.content <> invalid AND isLinearPlayerPlayingThisContent(focusedChannel) = false
          channelId = linearVideoPlayer.content.id
          epgScreen.jumpToRowItemByID = [channelId, ""]
        end if

        startCountdownTimer()
      end if
    else ' from top/side Nav
      changeEPGScreenBackground(epgScreen)
      m.backgroundGroup.posterVisible = true

      if currentScreen <> invalid AND isAnEpgScreen(currentScreen) AND currentScreen.linearChannelToPlay <> invalid
        contentToPlay = currentScreen.linearChannelToPlay

        playbackSource = {
          "srcForAnalytic": m.constants.player.playbackSource.unknown
          "srcForAds": m.constants.player.playbackOrigin.epg
          "playbackContainer": contentToPlay.parentId
        }
        playLinearVideoContent(contentToPlay, true, currentScreen.id, false, playbackSource)
      end if
    end if
  end if

End Function


Function showDefaultEPGScreen()
  tubiLog("EPGScreenHelpers.showDefaultEPGScreen")
  showEPGScreen(m.constants, m.constants.ui.screenIds.epgScreen)
End Function


Function onLoadAllEPGChannels(msg)
  tubiLog("EPGScreenHelpers.onLoadAllEPGChannels")
  epgScreen = msg.getRoSGNode()
  refreshEPGscreen(epgScreen)
End Function


Function onEPGScrollingStatusChange(msg)
  tubiLog("EPGScreenHelpers.onEPGScrollingStatusChange ")
  scrollingStatus = msg.getData()
  screen = msg.getRoSGNode()
  if scrollingStatus = true
    stopCountdownTimer()
    screen.fullscreenCountdown = -1
  else if screen.linearChannelToPlay <> invalid
    linearVideoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
    if linearVideoPlayer <> invalid AND linearVideoPlayer.state = "playing"
      startCountdownTimer()
    end if
  end if
End Function


'//If the EPGscreen is loading, then display the default background
Function setEPGScreenLoading(epgScreen)
  tubiLog("EPGScreenHelpers: setEPGScreenLoading")
  if isAnEpgScreen(epgScreen) = true
    screen = getCurrentScreen()
    if screen = invalid OR screen.id = epgScreen.id
      showHideSpinner(true)
      displayDefaultBackground()
    end if
  end if
End Function


Function onEPGscreenContentReady(msg)
  tubiLog("EPGscreenHelpers.onEPGscreenContentReady ")
  'when user selects LiveTV on ICTS, we need to fire app start
  fireAppLoadBeacon()
  epgScreen = msg.getRoSGNode()
  epgScreen.unobserveFieldScoped("contentReady")
  showHideSpinner(false)

  '//Report the page_load analytics
  loadTime = Int((Uptime(0) - epgScreen.trackingLoadStartTime) * 1000) 'in ms
  screenTrackingLoad(epgScreen.trackingPageInfo, loadTime)
End Function


Function isAnEpgScreen(screen)
  tubiLog("EPGScreenHelpers.isAnEpgScreen")
  return screen.isSubType("EPGHomeScreen")
End Function


' Is the passed ID associated with an EPG Screen?
' @sID: string, the id of a screen component
Function isAnEPGScreenID(sID)
  tubiLog("EPGScreenHelpers.isAnEPGScreenID")
  return (sID = m.constants.ui.screenIds.epgScreen)
End Function


Function onEPGScreenBackgroundChange(msg)
  tubiLog("EPGScreenHelpers.onEPGScreenBackgroundChange")
  EPGScreen = msg.getRoSGNode()
  changeEPGScreenBackground(EPGScreen)
End Function


Function changeEPGScreenBackground(EPGScreen)
  if EPGScreen <> invalid AND EPGScreen.backgroundUriList <> invalid
    m.backgroundGroup.backgroundInfo = {
      type: getBackgroundType(EPGScreen.backgroundUriList, m.constants.ui.contentTypes.epg)
      uriList: EPGScreen.backgroundUriList
    }
  end if
End Function


Function resetEPGScreenContent()
  tubiLog("EPGSCreenHelpers.resetEPGScreenContent")
  stopCountdownTimer()
  epgScreen = getCurrentScreen()
  if epgScreen <> invalid AND isAnEpgScreen(epgScreen) = true
    epgScreen.fullScreenCountdown = -1
  end if
  stopAndHideLinearVideoPlayer()
  if epgScreen.timeGridContent = invalid
    ' Any time, due to player error EPGscreen has been presented (for example deeplink content is failed to play)
    ' and epgScreen.timeGridContent is still empty, in that case fetch/use cache
    refreshEPGScreen(epgScreen)
    m.backgroundGroup.posterVisible = false
  end if
End Function


Function setTimeGridContentLoadingToComplete(screen)
  tubiLog("EPGSCreenHelpers.setTimeGridContentLoading")
  screen.updateTimeGridContent = true
  screen.timeGridContentLoading = false
  showHideSpinner(false)
  if m.enteredFromDeepLink = true
    getDataForVideoPlayerTimeGrid()
  end if
  screen.contentIdToFocusOnLoadComplete = ""
End Function
