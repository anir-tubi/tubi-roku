' Show the epg Screen
' @constants: assocArray, constants as set in Constants.brs 
' @screenID: string, What kind of epgScreen do you wish to make: regular, movies, or TV
' @componentToFocus: string, one of the values in constants.ui.epgscreen.focusItems
Function showEPGScreen(constants, screenID = "", componentToFocus = "")
  tubiLog("EPGScreenHelpers.showEPGScreen")
  if isNonEmptyString(screenID) <> true
    screenID = constants.ui.screenIds.epgScreen
  end if
  hideTubiLogo()

  epgScreen = getFromScreenCache(screenID)
  if epgScreen <> invalid
    ' this is required for setting focus to epgscreen after activation/signout
    epgScreen.shouldFocusWhenPushed = m.top.fadeInContentController
    changeEPGScreenBackground(epgScreen) ' ensure background of the epg screen is used immediatly instead of previous screen's background
    shouldSendPageLoadEvent = true
    if epgScreen.contentReady = false
      'First batch of Contents are not ready. So send the pageloadEvent after onContentReady()
      shouldSendPageLoadEvent = false
      showHideSpinner(true)
    else
      showHideSpinner(false)
    end if

    ' set which component to focus on once the screen gains focus
    if componentToFocus = m.constants.ui.epgScreen.focusItems.topNav
      epgScreen.componentToFocus = m.constants.ui.epgScreen.focusItems.topNav
    else
      epgScreen.componentToFocus = m.constants.ui.epgScreen.focusItems.epgTimeGrid
    end if
    epgscreen.refreshTopNav = true
    pushScreen(epgScreen, true, shouldSendPageLoadEvent)
  else
    displayDefaultBackground()  ' clear background from previous screens until epgscreen loads
    showHideSpinner(true)
    epgScreen = CreateObject("roSGNode", "EPGScreen")
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
    m.playerFullscreenCountdownTimer.unobserveFieldScoped("fire") '//Stop lsitenting to timer before listing to it in case a previous screen started the timer
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

    pushScreen(epgScreen, true, true)
  end if
  m.totalNumEPGBatches = 0 ' good practice to initialize m. scope variable in init functions
End Function


'//Refresh the content and the enabling of the top nav of the epg screen
Function refreshEPGScreen(epgscreen)
  tubiLog("EPGScreenHelpers.refreshEPGscreen")
  mode = ""
  epgChannelList = invalid
  if epgscreen.id = m.constants.ui.screenIds.sportsEPGScreen
    mode = m.constants.ui.contentMode.sportsEPGScreen
    epgscreen.topNavSelectedId = m.constants.ui.sideNavIds.sports
  else if epgscreen.id = m.constants.ui.screenIds.newsEPGScreen
    mode = m.constants.ui.contentMode.newsEPGScreen
    epgscreen.topNavSelectedId = m.constants.ui.sideNavIds.news
  else if epgscreen.id = m.constants.ui.screenIds.linearEPG
    mode = m.constants.ui.contentMode.epgScreen
    epgscreen.topNavSelectedId = m.constants.ui.sideNavIds.linearEPG
    epgChannelList  = getFromContentCache(m.constants.ui.contentIds.timeGridContent)
  else 
    mode = m.constants.ui.contentMode.epgScreen
    epgChannelList  = getFromContentCache(m.constants.ui.contentIds.timeGridContent)
  end if
  
  if epgChannelList = invalid or (epgChannelList <> invalid and shouldRefresh(epgChannelList.getChild(0)) = true)'There is no cached contents
    setEPGScreenLoading(epgScreen)
    fetchEPGScreenChannels(epgScreen, mode)
  else if epgChannelList <> invalid 
    epgscreen.timeGridContent = epgChannelList
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
' @param mode: String, The mode that will dictate that what kind of channels will be gathered for the EPG: i.e. all, sports, news
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


Function fetchEPGChannel(screen, channelID)
  cachedChannel = invalid
  cachedAllChannels = getFromContentCache(m.constants.ui.contentIds.timeGridContent)

  if cachedAllChannels <> invalid and cachedAllChannels.count() > 0 and shouldRefresh(cachedAllChannels.getChild(0)) = false
    '//go thru the channels and find the desired channel
    for i = 0 to cachedAllChannels.count()
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
    instantResponse.requestorID = screen.id
    instantResponse.appendChild(cachedChannel)
    onEPGChannelProgramSuccess(instantResponse, false)
  else
      '//call the API to get new channel data
      channelListIDs = [channelID]
      epgProgramInfo = m.tensorapi.getEPGProgramReqInfo(channelListIDs)
      m.makeRequest({
        url : epgProgramInfo.url
        requestType : m.constants.reqNames.getEPGPrograms
        options : epgProgramInfo.options
        successCallback : onEPGChannelProgramSuccess
        errorCallback : onEPGChannelProgramError
        responseType : "node"
        storeInCacheUponSuccess: true
        requestorID : screen.id
      })
  end if

End Function



Function onEpgChannelListResponse(response)
  tubiLog("EPGScreenHelpers.onEpgChannelListResponse")
  'check if this is the epgScreen for which response was meant to be.
  currentScreen = getCurrentScreen()
  if response <> invalid and currentScreen <> invalid and response.requestorID <> invalid and response.requestorID = currentScreen.id
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

      m.makeRequest({
        url : epgProgramInfo.url
        requestType : m.constants.reqNames.getEPGPrograms
        options : epgProgramInfo.options
        successCallback : onEPGProgramSuccess
        errorCallback : onEpgProgramError
        responseType : "node"
        requestorID : response.requestorID
      })
      completedChannels = completedChannels + nFetchInBatch
      remainingChannels = totalNumChannels - completedChannels
      m.totalNumEPGBatches = m.totalNumEPGBatches + 1 ' keep track of number of batches.
    end while
  end if
End Function


'This function calls appendOrAddTimeGridNewContents function which inturn adds or appends the batch data recieved to EPG TimeGrid.
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
          bSet = setInContentCache(channelData)
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
  if screen <> invalid and screen.id = response.requestorID and response.contentId <> invalid and screen.timeGridContent <> invalid  
    'response.contentID will have list of comma separated contentIDs for which the reponse was requested.
    'remove each of the channel Ids from TimeGrid which does not have any channel/program information. Please note that at this point, this node is an empty row on TimeGrid.
    contentIDList = response.contentId.Tokenize(",")
    for each content in contentIDList      
        i = m.NodeHelpers.getChildIndexById(screen.timeGridContent, content)
        screen.timeGridContent.removeChildIndex(i)
    end for

    if screen.timeGridContent <> invalid and screen.timeGridContent.getChildCount() > 0
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
  if screen <> invalid and response <> invalid and screen.id = response.requestorID 
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
  
  if response <> invalid and epgscreen.timeGridContent <> invalid
    for i = 0 to response.getChildCount() - 1
      if response.getChild(i) <> invalid
        newNode = response.getChild(i).clone(true)
        oldNodeIndex = m.NodeHelpers.getChildIndexById(epgscreen.timeGridContent, newNode.id)
  
        if oldNodeIndex = -1
          epgscreen.timeGridContent.appendChild(newNode)
        else 
          if epgscreen.timeGridContent.getChild(oldNodeIndex) <> invalid 
            containerName = epgscreen.timeGridContent.getChild(oldNodeIndex).containerName
            newNode.parentTitle = containerName
          end if
          epgscreen.timeGridContent.replaceChild(newNode, oldNodeIndex)
        end if
      end if
    end for
  end if
End Function


Function onEPGScreenOKPressed(msg)
  tubiLog("EPGScreenHelpers.onEPGScreenOKPressed")
  currentScreen = getCurrentScreen()
  stopCountdownTimer() 'stop previous counter
  
  if currentScreen <> invalid and isAnEpgScreen(currentScreen)
    contentToPlay = currentScreen.LinearChannelToPlay
    if contentToPlay <> invalid 
      startPlayVideo = true
      linearVideoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
      if linearVideoPlayer <> invalid and linearVideoPlayer.content <> invalid
        if linearVideoPlayer.content.id = contentToPlay.id and linearVideoPlayer.state = "playing"
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


'This function will handle the minimized video player on EPG Screen
' refreshEPGScreenVideoPlay = true  - Close the Video player since EPGScreen/EPG component lost focus (sideNav or topNav)
' refreshEPGScreenVideoPlay = false, there are two possibilities 
' 1) epgScreen returning back from full video screen. Keep the video as it is.
' 2) epgScreen:EPG component is gaining focus from side/topNav. In this case restart the video.

Function onRefreshEPGScreenVideoPlay(msg)
  tubiLog("EPGScreenHelpers.onRefreshEPGScreenVideoPlay")
  refreshEPGScreenVideoPlay = msg.getData()
  epgScreen = msg.getRoSGNode()
  currentScreen = getCurrentScreen()
  screenID = currentScreen.id
  if screenID = m.constants.ui.screenIds.linearVideoPlayerScreen
    'do nothing. Linear screen is taken over.
  else if refreshEPGScreenVideoPlay = true
    m.backgroundGroup.posterVisible = true
    stopCountdownTimer()
    epgscreen.fullScreenCountdown = -1
    stopAndHideLinearVideoPlayer()
  else 'from FullScreen video
    linearVideoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
    changeEPGScreenBackground(epgscreen)
    if linearVideoPlayer <> invalid and linearVideoPlayer.state = "playing"
      m.backgroundGroup.posterVisible = false
      
      startCountdownTimer()
    else ' from top/side Nav
      m.backgroundGroup.posterVisible = true

      if currentScreen <> invalid and isAnEpgScreen(currentScreen) and currentScreen.linearChannelToPlay <> invalid
        playLinearVideoContent(currentScreen.linearChannelToPlay, true, CurrentScreen.id)
      end if
    end if
  end if

End Function



' @componentToFocus: string, one of the values in constants.ui.epgScreen.focusItems
Function showDefaultEPGScreen(componentToFocus = "")
  tubiLog("EPGScreenHelpers.showDefaultEPGScreen")
  showEPGScreen(m.constants, m.constants.ui.screenIds.epgScreen, componentToFocus)
End Function


' @componentToFocus: string, one of the values in constants.ui.epgScreen.focusItems
Function showSportsEPGScreen(componentToFocus = "")
  tubiLog("EPGScreenHelpers.showSportsEPGScreen")
  showEPGScreen(m.constants, m.constants.ui.screenIds.sportsEPGScreen, componentToFocus)
End Function


' @componentToFocus: string, one of the values in constants.ui.epgScreen.focusItems
Function showNewsEPGScreen(componentToFocus = "")
  tubiLog("EPGScreenHelpers.showNewsEPGScreen")
  showEPGScreen(m.constants, m.constants.ui.screenIds.newsEPGScreen, componentToFocus)
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
    if linearVideoPlayer <> invalid and linearVideoPlayer.state = "playing"
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
  epgscreen = msg.getRoSGNode()
  epgScreen.unobserveFieldScoped("contentReady")
  showHideSpinner(false)

  '//Report the page_load analytics
  loadTime = Int((Uptime(0) - epgScreen.trackingLoadStartTime) * 1000) 'in ms
  screenTrackingLoad(epgScreen.trackingPageInfo, loadTime)
End Function


Function isAnEpgScreen(Screen)
  tubiLog("EPGScreenHelpers.isAnEpgScreen")
  return screen.isSubType("EPGScreen")
End Function


Function onEPGScreenBackgroundChange(msg)
  tubiLog("EPGScreenHelpers.onEPGScreenBackgroundChange")
  EPGScreen = msg.getRoSGNode()
  changeEPGScreenBackground(EPGScreen)
End Function


Function changeEPGScreenBackground(EPGScreen)
  if EPGScreen <> invalid and EPGScreen.backgroundUriList <> invalid
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
  if epgScreen <> invalid and isAnEpgScreen(epgScreen) = true
    epgscreen.fullScreenCountdown = -1
  end if
  stopAndHideLinearVideoPlayer()
End Function


Function setTimeGridContentLoadingToComplete(screen)
  tubiLog("EPGSCreenHelpers.setTimeGridContentLoading")
  checkAndFixDuplicates(screen)
  screen.updateTimeGridContent = true

  showHideSpinner(false) 
  screen.timeGridContentLoading = false 
End Function



'This function is cleanup after epgData all been fetched. 
'There might be 3 conditions that we need to handle before rendering.
'Duplicates - because getChildIndexById() function will return the first place where the channelId appears in parent, the duplicate ChannelId Nodes are left empty.  We need to copy the first channelInfo for duplicate channels Too.
'Invalids - just for some reason, if there is a invalid node on timeGridConent, we need to remove those(might never happen)
'EmptyContentNode - emptyContentNode will have channelID and ContainerName but without any information like ChannelName, video resources to play etc.  We need to remove empty nodes too.

Function checkAndFixDuplicates(screen)
  tubiLog("EPGSCreenHelpers.checkAndFixDuplicates")
  if screen.timeGridContent <> invalid and screen.timeGridContent.getchildCount() > 0 'just in case of error and no programs has been retrived
    for i = 0 to screen.timeGridContent.getchildCount() - 1
      itemTobeReplaced = screen.timeGridContent.getChild(i)
    
      if itemTobeReplaced = invalid 
        screen.timeGridContent.removeChildindex(i)
      else if itemTobeReplaced.channelName = invalid or itemTobeReplaced.channelName = ""
        'either channel is duplicate or no channel info available
        dupFound = false
        
        for j = 0 to screen.timeGridContent.getchildCount() - 1
          itemReplace = screen.timeGridContent.getChild(j)
          if itemTobeReplaced.id = itemReplace.id and itemReplace.channelName <> invalid and itemReplace.channelName <> ""
            containerName = itemTobeReplaced.containerName 'copy the container name because it will be different than its duplicate.
            dup = itemReplace.clone(true)
            dup.parentTitle = containerName
            screen.timeGridContent.replaceChild(dup, i)
            dupFound = true
            exit for
          end if
        end for
        ' //if no duplicates are found, then this is an empty node and should be removed.
        if dupFound = false
          screen.timeGridContent.removeChildindex(i)
        end if
      end if
    end for
  end if

End Function
