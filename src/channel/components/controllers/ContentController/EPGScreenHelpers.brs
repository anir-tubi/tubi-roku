' Show the epg Screen
' @constants: assocArray, constants as set in Constants.brs
' @screenID: string, What kind of epgScreen do you wish to make: regular, movies, or TV
' @componentToFocus: string, one of the values in constants.ui.epgscreen.focusItems
Function showEPGScreen(constants, screenID = "", componentToFocus = "")
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

    ' set which component to focus on once the screen gains focus
    if componentToFocus = m.constants.ui.epgScreen.focusItems.topNav
      epgScreen.componentToFocus = m.constants.ui.epgScreen.focusItems.topNav
    else
      epgScreen.componentToFocus = m.constants.ui.epgScreen.focusItems.epgTimeGrid
    end if

  else
    displayDefaultBackground()  ' clear background from previous screens until epgscreen loads
    showHideSpinner(true)

    epgScreen = CreateObject("roSGNode", "EPGHomeScreen")
    epgScreen.observeFieldScoped("backgroundUriList", "onEPGScreenBackgroundChange")
    epgScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
    epgScreen.observeFieldScoped("programGuideNavigateWithinPageInfo", "onNavigateWithinPageInfoChange")
    epgScreen.observeFieldScoped("programGuidecomponentInteractionInfo", "onComponentInteractionInfoChange")
    epgScreen.observeFieldScoped("transportVoiceResponse", "onTransportVoiceResponse")
    epgScreen.observeFieldScoped("topNavItemSelected", "onTopNavItemSelected")
    epgScreen.observeFieldScoped("topNavBackItemSelected", "onTopNavBackItemSelected")
    epgScreen.observeFieldScoped("loadAllChannels", "onLoadAllEPGChannels")
    epgScreen.observeFieldScoped("scrollingStatus", "onEPGScrollingStatusChange")
    epgScreen.observeFieldScoped("topNavToggled", "onScreenTopNavToggled")
    epgScreen.observeFieldScoped("refreshEPGScreenVideoPlay", "onRefreshEPGScreenVideoPlay")
    epgScreen.observeFieldScoped("epgScreenOkPressed", "onEPGScreenOKPressed")
    epgScreen.signedIn = isLoggedInUser()

    m.playerFullscreenCountdownTimer.unobserveFieldScoped("fire") '//Stop listening to timer before listing to it in case a previous screen started the timer
    m.playerFullscreenCountdownTimer.observeFieldScoped("fire", "onFullscreenCountdown")

    epgScreen.shouldFocusWhenPushed = m.top.fadeInContentController

    epgScreen.backgroundUriList = [m.defaultBackgroundUri]

    epgScreen.id = screenID

    epgScreen.refreshTopNav = true
    refreshEPGScreen(epgScreen)

    setInScreenCache(epgScreen)

    ' set which component to focus on once the screen gains focus
    if componentToFocus = m.constants.ui.epgScreen.focusItems.topNav
      epgScreen.componentToFocus = m.constants.ui.epgScreen.focusItems.topNav
    else
      epgScreen.componentToFocus = m.constants.ui.epgScreen.focusItems.epgTimeGrid
    end if
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

  if screenID = m.constants.ui.screenIds.epgScreen
    epgScreen.topNavSelectedId = m.constants.ui.sideNavIds.linearEPG
  end if

  m.totalNumEPGBatches = 0 ' good practice to initialize m. scope variable in init functions
End Function


'//Refresh the content and the enabling of the top nav of the epg screen
Function refreshEPGScreen(epgScreen)
  tubiLog("EPGScreenHelpers.refreshEPGscreen")
  mode = m.constants.ui.contentMode.epgScreen
  epgScreen.topNavSelectedId = m.constants.ui.sideNavIds.linearEPG
  epgScreen.signedIn = isLoggedInUser()
  epgChannelList  = getFromContentCache(m.constants.ui.contentIds.timeGridContent)


  if epgChannelList = invalid or (epgChannelList <> invalid AND shouldRefresh(epgChannelList.getChild(0)) = true)'There is no cached contents
    setEPGScreenLoading(epgScreen)
    fetchEPGScreenChannels(epgScreen, mode)
  else if epgChannelList <> invalid
    epgScreen.timeGridContent = epgChannelList
    setTimeGridContentLoadingToComplete(epgScreen)
  end if
End Function


Function fetchEPGScreenChannels(screen, mode="")
  tubiLog("EPGScreenHelpers.fetchEPGScreenChannels")

  screen.trackingLoadStartTime = UpTime(0)
  m.totalNumEPGBatches = 0

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
  m.makeRequest({
    url : epgContainerInfo.url
    requestType : m.constants.reqNames.getEPGChannelIds
    options : epgContainerInfo.options
    successCallback : onEpgChannelListResponse
    errorCallback : onEpgError 'if there is no program list then there wont be any programs to pull.
    responseType : "node"
    requestorID : screen.ID
  })
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
        url : epgProgramInfo.url
        requestType : m.constants.reqNames.getEPGPrograms
        options : epgProgramInfo.options
        successCallback : successCallback
        errorCallback : errorCallback
        responseType : "node"
        storeInCacheUponSuccess: true
        requestorID : screenId
        isSignedInUser: isSignedIn
      })
  end if

End Function



Function onEpgChannelListResponse(response)
  tubiLog("EPGScreenHelpers.onEpgChannelListResponse")
  'check if this is the epgScreen for which response was meant to be.
  currentScreen = getCurrentScreen()
  if response <> invalid AND currentScreen <> invalid AND response.requestorID <> invalid AND response.requestorID = currentScreen.id
    currentScreen.timeGridContent = response
    nFetchInBatch = 10
    m.totalNumEPGBatches = 0
    totalNumChannels = response.getChildCount()
    remainingChannels = totalNumChannels
    completedChannels = 0
    if totalNumChannels <= 0
      onEPGError(response)
    end if
    while remainingChannels > 0
      if remainingChannels <= nFetchInBatch
        nFetchInBatch = remainingChannels
      end if
      loopEnd = nFetchInBatch + completedChannels
      channelListIDs = []
      for i = completedChannels to loopEnd - 1
        epgChannel = response.getChild(i)
        channelListIDs.push(epgChannel.id) ' [613683,613761,....]
      end for

      epgProgramInfo = m.tensorapi.getEPGProgramReqInfo(channelListIDs)
      isSignedIn = isLoggedInUser()

      m.makeRequest({
        url : epgProgramInfo.url
        requestType : m.constants.reqNames.getEPGPrograms
        options : epgProgramInfo.options
        successCallback : onEPGProgramSuccess
        errorCallback : onEpgProgramError
        responseType : "node"
        requestorID : response.requestorID
        isSignedInUser: isSignedIn
      })
      completedChannels = completedChannels + nFetchInBatch
      remainingChannels = totalNumChannels - completedChannels
      m.totalNumEPGBatches = m.totalNumEPGBatches + 1 ' keep track of number of batches.
    end while
  end if
End Function


'This function calls appendOrAddTimeGridNewContents function which inturn adds or appends the batch data received to EPG TimeGrid.
'@response: roSGNode, The response contains program info for a set of channel
Function onEPGProgramSuccess(response)
  tubiLog("EPGScreenHelpers.onEPGProgramSuccess")
  if response <> invalid
    m.totalNumEPGBatches = m.totalNumEPGBatches - 1 'reduce the totalNumEPGBatches
    screen = getFromScreenCache(response.requestorID)
    if screen = invalid
      screen = getCurrentScreen()
    end if
    if response.requestorID = screen.id
      appendOrAddTimeGridNewContents(response, screen)

      if  m.totalNumEPGBatches = 0
        setTimeGridContentLoadingToComplete(screen)
        setInContentCache(screen.timeGridContent)

      end if
    end if
  end if
End Function


' Successfully loaded the program data of one channel.
' This function is used for fetching the channel's program data for homeScreen.
Function onEPGChannelProgramSuccess(response, storeInCacheUponSuccess = true)
  tubiLog("EPGScreenHelpers.onEPGChannelProgramSuccess")
  if response <> invalid
    screen = getFromScreenCache(response.requestorID)
    if screen = invalid
      screen = getCurrentScreen()
    end if
    if response.requestorID = screen.id
      channelData = response.getChild(0)
      if channelData <> invalid
        if storeInCacheUponSuccess = true
          setInContentCache(channelData)
        end if
        screen.channelTimeGridContent = channelData
      end if
    end if
  end if
End Function



' Unsuccessfully loaded the program data of one channel
Function onEPGChannelProgramError(response)
  tubiLog("EPGScreenHelpers.onEPGChannelProgramError")
  if response <> invalid
    screen = getFromScreenCache(response.requestorID)
    if screen = invalid
      screen = getCurrentScreen()
    end if
    if response.requestorID = screen.id
      screen.channelTimeGridContent = invalid
    end if
  end if
End Function


' This function is used for batch of channels
Function onEpgProgramError(response)
  tubiLog("EPGScreenHelpers.onEpgProgramError ")
  m.totalNumEPGBatches = m.totalNumEPGBatches - 1
  screen = getCurrentScreen()
  'Check if the screen which requested the program info is the current Screen and user not moved away from this Screen. (especially in case of request timeout or slow internet cases)
  if screen <> invalid AND screen.id = response.requestorID AND response.contentId <> invalid AND screen.timeGridContent <> invalid
    'response.contentID will have list of comma separated contentIDs for which the response was requested.
    'remove each of the channel Ids from TimeGrid which does not have any channel/program information. Please note that at this point, this node is an empty row on TimeGrid.
    contentIDList = response.contentId.Tokenize(",")
    for each content in contentIDList
      i = m.NodeHelpers.getChildIndexById(screen.timeGridContent, content)
      screen.timeGridContent.removeChildIndex(i)
    end for

    if screen.timeGridContent <> invalid AND screen.timeGridContent.getChildCount() > 0
      'Since a batch of programs errored out, set the validUntil to 0 so that next time, content will refetch.
      screen.timeGridContent.getChild(0).validUntil = 0
    end if

    ' if all the responses for Channel infomation errored out then timeGrid will not have any content.
    if screen.timeGridContent.getChildCount() = 0
      onEPGError(response)
    else if  m.totalNumEPGBatches = 0 ' all the batches are over and there are channels in the list, show whatever has been fetched successfully.
      setTimeGridContentLoadingToComplete(screen)
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
        type : "dialog"
        values : {
          dialog_type : "NETWORK_ERROR"
          pageOneof : m.Tracking.getAnalyticsPage("linear_browse_page", {})
          dialog_action : "SHOW"
          dialog_sub_type : errorCode
        }
      }

      modalInfo = {
        message : getErrorMessage(errorMessage, errorCode)
        openTrackEvent : dialogEvent
        trackingTask : m.trackingLoggingTask
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
        newId = response.getChild(i).id
        indices = m.NodeHelpers.getChildIndicesById(epgScreen.timeGridContent, newId)

        if indices.Count() <= 0
          newNode = response.getChild(i).clone(true)
          epgScreen.timeGridContent.appendChild(newNode)
        else
          for each oldNodeIndex in indices
            if epgScreen.timeGridContent.getChild(oldNodeIndex) <> invalid
              containerName = epgScreen.timeGridContent.getChild(oldNodeIndex).containerName 'containerName is present only in getChannelList api call.

              if containerName <> invalid AND containerName <> ""
                newNode = response.getChild(i).clone(true)
                newNode.parentTitle = containerName
                epgScreen.timeGridContent.replaceChild(newNode, oldNodeIndex)
              end if
            end if
          end for
        end if
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
        playLinearVideoContent(contentToPlay, false, currentScreen.id)
      else
        stopCountdownTimer()
        maximizeLinearPlayer(contentToPlay)
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
' refreshVideoPlay = true  - Close the Video player since EPGScreen/EPG component lost focus (sideNav or topNav)
' refreshVideoPlay = false, there are two possibilities
'   1) epgScreen returning back from full video screen. Keep the video as it is, and make sure the video screen and focused channel are the same.
'   2) epgScreen:EPG component is gaining focus from side/topNav. In this case restart the video.
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

    changeEPGScreenBackground(epgScreen)
    if linearVideoPlayer <> invalid AND linearVideoPlayer.state = "playing"
      if epgScreen.timeGridContent = invalid or epgScreen.timeGridContentLoading = true
        'Anytime Video is playing and epgScreen is empty, then refresh the epgScreen.  This situation might happen when
        'when we play content directly from deeplink and epgScreen still does not have content if user presses backbutton.
        refreshEPGScreen(epgScreen)
        m.backgroundGroup.posterVisible = false
        startCountdownTimer()
      else
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
      m.backgroundGroup.posterVisible = true

      if currentScreen <> invalid AND isAnEpgScreen(currentScreen) AND currentScreen.linearChannelToPlay <> invalid
        playLinearVideoContent(currentScreen.linearChannelToPlay, true, currentScreen.id)
      end if
    end if
  end if

End Function



' @componentToFocus: string, one of the values in constants.ui.epgScreen.focusItems
Function showDefaultEPGScreen(componentToFocus = "")
  tubiLog("EPGScreenHelpers.showDefaultEPGScreen")
  showEPGScreen(m.constants, m.constants.ui.screenIds.epgScreen, componentToFocus)
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
    if screen = invalid or screen.id = epgScreen.id
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
      type : getBackgroundtype(EPGScreen.backgroundUriList, m.constants.ui.contentTypes.epg)
      uriList : EPGScreen.backgroundUriList
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
  if epgScreen.timeGridContent = invalid or epgScreen.timeGridContentLoading = true
    ' Any time, due to player error EPGscreen has been presented (for example deeplink content is failed to play)
    ' and epgScreen.timeGridContent is still empty, in that case fetch/use cache
    refreshEPGScreen(epgScreen)
    m.backgroundGroup.posterVisible = false
  end if
End Function


Function setTimeGridContentLoadingToComplete(screen)
  tubiLog("EPGSCreenHelpers.setTimeGridContentLoading")
  cleanUpInvalidsInEPG(screen)
  screen.updateTimeGridContent = true
  screen.timeGridContentLoading = false
  showHideSpinner(false)
End Function



'This function is cleanup after epgData all been fetched.
'There might be 3 conditions that we need to handle before rendering.
'Invalids - just for some reason, if there is a invalid node on timeGridContent, we need to remove those(might never happen)
'EmptyContentNode - emptyContentNode will have channelID and ContainerName but without any information like ChannelName, video resources to play etc.  We need to remove empty nodes too.

Function cleanUpInvalidsInEPG(screen)
  tubiLog("EPGSCreenHelpers.cleanUpInvalidsInEPG")
  if screen.timeGridContent <> invalid AND screen.timeGridContent.getchildCount() > 0 'just in case of error and no programs has been retrived
    for i = 0 to screen.timeGridContent.getchildCount() - 1
      item = screen.timeGridContent.getChild(i)

      if item = invalid or (item <> invalid AND (item.channelName = invalid or item.channelName = ""))
        screen.timeGridContent.removeChildindex(i)
      end if
    end for
  end if

End Function
