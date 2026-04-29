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
    epgScreen.observeFieldScoped("channelGridScrollingStatus", "onEPGScrollingStatusChange")
    epgScreen.observeFieldScoped("categoryGridScrollingStatus", "onEPGScrollingStatusChange")
    epgScreen.observeFieldScoped("refreshEPGScreenVideoPlay", "onRefreshEPGScreenVideoPlay")
    epgScreen.observeFieldScoped("epgScreenOkPressed", "onEPGScreenOKPressed")
    epgScreen.observeFieldScoped("epgBannerSelected", "onEpgBannerSelected")
    epgScreen.observeFieldScoped("channelIdSelected", "onChannelSelected")
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

  getStatsigExperimentResource("roku_epg_shift", "roku_epg_shift_v1", true)

  pushScreen(epgScreen, true, shouldSendPageLoadEvent)

End Function


'//Refresh the content and the enabling of the top nav of the epg screen
Function refreshEPGScreen(epgScreen)
  tubiLog("EPGScreenHelpers.refreshEPGscreen")
  if epgScreen <> invalid
    epgScreen.signedIn = isLoggedInUser()

    epgChannelList = getFromContentCache(m.constants.ui.contentIds.timeGridContent)
    needsFetch = (epgChannelList = invalid OR (epgChannelList <> invalid AND shouldRefresh(epgChannelList.getChild(0)) = true))

    if needsFetch = true
      setEPGScreenLoading(epgScreen)
      if isLoggedInUser() = true
        fetchEPGScreenChannelsWithBatch(epgScreen)
      else
        fetchEPGScreenChannels(epgScreen, m.constants.ui.contentMode.epgScreen)
      end if
    else if epgChannelList <> invalid
      epgScreen.timeGridContent = epgChannelList
      if epgChannelList.containersList <> invalid
        epgScreen.containersList = epgChannelList.containersList
      end if
      setTimeGridContentLoadingToComplete(epgScreen)
    end if
  end if
End Function


' Fire EPG + getContentRating as batch; single callback merges when both are back (no race/merge-state)
Function fetchEPGScreenChannelsWithBatch(epgScreen)
  tubiLog("EPGScreenHelpers.fetchEPGScreenChannelsWithBatch")

  epgScreen.unobserveFieldScoped("contentReady")
  epgScreen.observeFieldScoped("contentReady", "onEPGscreenContentReady")

  m.epgBatchRequestorId = epgScreen.id
  m.epgFetchUniqueId = "epgLikedBatch_epg"

  likedReqInfo = m.userDeviceApi.getContentRating("linear", m.constants.ui.likeDislikeStates.liked)
  likedReqInfo.append({
    id: "epgLikedBatch_liked"
    requestType: m.constants.reqNames.getContentRating
    responseType: "assocarray"
  })

  epgContainerInfo = m.tensorapi.getEPGChannelidsReqInfo(m.constants.ui.contentMode.epgScreen)
  epgReqInfo = {
    id: m.epgFetchUniqueId
    url: epgContainerInfo.url
    options: epgContainerInfo.options
    requestType: m.constants.reqNames.getEPGChannelIds
    responseType: "node"
    requestorID: epgScreen.id
    isSignedInUser: isLoggedInUser()
    analyticsScreenId: epgScreen.id
  }

  epgScreen.timeGridContentLoading = true
  epgScreen.timeGridContent = invalid

  m.makeBatchRequest({
    requests: [likedReqInfo, epgReqInfo]
    successCallback: onEPGAndLikedBatchComplete
    errorCallback: onEPGAndLikedBatchError
    responseType: "assocarray"
  })
End Function


' Batch success: both EPG and getContentRating returned; merge liked into EPG and apply
Function onEPGAndLikedBatchComplete(batchResponse)
  tubiLog("EPGScreenHelpers.onEPGAndLikedBatchComplete")

  likedResponse = invalid
  if batchResponse <> invalid AND batchResponse["epgLikedBatch_liked"] <> invalid
    likedResponse = batchResponse["epgLikedBatch_liked"]
  end if

  epgResponse = invalid
  if batchResponse <> invalid AND batchResponse["epgLikedBatch_epg"] <> invalid
    epgResponse = batchResponse["epgLikedBatch_epg"]
  end if

  if likedResponse <> invalid AND likedResponse.nodes <> invalid AND likedResponse.nodes.count() > 0
    ' EPG channel favorites — Will remove if we don't graduate roku_epg_favorites_v1 experiment
    m.likedContainer = {
      "name": getTranslation("epg_favorites"),
      "contents": [],
      "container_id": "favorite_channels",
      "container_slug": "favorite_channels"
    }
    for each item in likedResponse.nodes
      m.likedContainer.contents.push(item.id)
    end for
  end if

  if epgResponse <> invalid AND isNode(epgResponse) = false
    onEpgError(epgResponse)
  else if epgResponse = invalid
    onEpgError({ requestorID: m.epgBatchRequestorId })
  else
    applyEpgChannelListToScreen(epgResponse)
  end if
End Function


Function onEPGAndLikedBatchError(_error)
  tubiLog("EPGScreenHelpers.onEPGAndLikedBatchError")
  onEpgError({ requestorID: m.epgBatchRequestorId })
End Function


' EPG channel favorites — Will remove if we don't graduate roku_epg_favorites_v1 experiment.
Function mergeLikedChannelsIntoEpgResponse(response)
  if m.likedContainer <> invalid AND m.likedContainer.contents <> invalid AND m.likedContainer.contents.count() > 0
    insertPosition = 0
    favoritesTitle = getTranslation("epg_favorites")

    for i = m.likedContainer.contents.count() - 1 to 0 step -1
      likedId = m.likedContainer.contents[i]
      channel = findChannelInContentById(response, likedId)
      if channel <> invalid
        if channel.hasField("isFavorite") = false
          channel.addField("isFavorite", "bool", false)
        end if
        channel.isFavorite = true
        favoriteChannel = channel.clone(true)
        favoriteChannel.parentTitle = favoritesTitle
        favoriteChannel.parentId = "favorite_channels"
        favoriteChannel.isFavorite = true
        response.insertChild(favoriteChannel, 0)
        insertPosition = insertPosition + 1
      end if
    end for

    if insertPosition > 0
      if response.containersList = invalid
        response.addField("containersList", "node", false)
        response.containersList = CreateObject("roSGNode", "ContentNode")
      end if

      containerNode = CreateObject("roSGNode", "ContentNode")
      containerNode.title = favoritesTitle
      containerNode.addField("containerId", "string", false)
      containerNode.containerId = "favorite_channels"
      response.containersList.insertChild(containerNode, 0)
    end if
  end if
End Function


Function findChannelInContentById(contentNode, channelId)
  if contentNode = invalid
    return invalid
  end if

  idStr = channelId.toStr()
  for i = 0 to contentNode.getChildCount() - 1
    ch = contentNode.getChild(i)
    if ch <> invalid AND ch.id <> invalid AND ch.id.toStr() = idStr
      return ch
    end if
  end for

  return invalid
End Function


' EPG channel favorites — Will remove if we don't graduate roku_epg_favorites_v1 experiment.
Function isLinearChannelLiked(channelId) as Boolean
  if channelId = invalid OR m.likedContainer = invalid OR m.likedContainer.contents = invalid
    return false
  end if
  idStr = channelId.toStr()
  for each likedId in m.likedContainer.contents
    if likedId <> invalid AND likedId.toStr() = idStr
      return true
    end if
  end for
  return false
End Function


' EPG channel favorites — Will remove if we don't graduate roku_epg_favorites_v1 experiment.
Function updateLikedContainerForLinear(channelId, action)
  if m.likedContainer <> invalid AND m.likedContainer.contents <> invalid AND channelId <> invalid
    idStr = channelId.toStr()
    if action = m.constants.ui.likeDislikeActions.like
      isLikedContent = false
      for each likedId in m.likedContainer.contents
        if likedId <> invalid AND likedId.toStr() = idStr
          isLikedContent = true
          exit for
        end if
      end for
      if isLikedContent = false
        m.likedContainer.contents.push(channelId)
      end if
    else if action = m.constants.ui.likeDislikeActions.removeLike
      likedContentCount = m.likedContainer.contents.count() - 1
      while likedContentCount >= 0
        lid = m.likedContainer.contents[likedContentCount]
        if lid <> invalid AND lid.toStr() = idStr
          m.likedContainer.contents.delete(likedContentCount)
          exit while
        end if
        likedContentCount = likedContentCount - 1
      end while
    end if
  end if
End Function


Function fetchEPGScreenChannels(screen, mode = "")
  tubiLog("EPGScreenHelpers.fetchEPGScreenChannels")

  screen.unobserveFieldScoped("contentReady")
  screen.observeFieldScoped("contentReady", "onEPGscreenContentReady")
  fetchEPGChannels(screen, mode)
End Function


' @param screen: roSGNode, Screen that is fetching and is hosting the EPG Channels: i.e. epgScreen, Linear Video Player Screen
' @param mode: String, The mode that will dictate that what kind of channels will be gathered for the EPG
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
    analyticsScreenId: screen.ID
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
      analyticsScreenId: screenId
    })
  end if

End Function


Function onEpgChannelListResponse(response)
  tubiLog("EPGScreenHelpers.onEpgChannelListResponse")
  if response <> invalid AND response.requestorID <> invalid
    screen = getFromScreenCache(response.requestorID)
    if screen = invalid
      screen = getCurrentScreen()
    end if

    if screen.id = response.requestorID AND m.epgFetchUniqueId = response.fetchId
      applyEpgChannelListToScreen(response)
    end if
  end if
End Function


' @param response - roSGNode, translated EPG channel list with requestorID
Function applyEpgChannelListToScreen(response)
  isEpgFavoritesExperimentEnabled = getStatsigExperimentResource("roku_epg_favorites", "roku_epg_favorites_v1", false).enabled = true

  if isEpgFavoritesExperimentEnabled = true
    ' EPG channel favorites — Will remove if we don't graduate roku_epg_favorites_v1 experiment.
    mergeLikedChannelsIntoEpgResponse(response)
  end if

  screen = getFromScreenCache(response.requestorID)
  if screen = invalid
    screen = getCurrentScreen()
  end if

  if screen <> invalid
    screen.timeGridContent = response

    if response.containersList <> invalid
      screen.containersList = response.containersList
    end if

    if isEpgFavoritesExperimentEnabled = true AND isLoggedInUser() = true AND screen.timeGridContent <> invalid
      ' EPG channel favorites — Will remove if we don't graduate roku_epg_favorites_v1 experiment.
      childCount = screen.timeGridContent.getChildCount()
      for i = 0 to childCount - 1
        channel = screen.timeGridContent.getChild(i)
        if channel <> invalid AND channel.id <> invalid AND isLinearChannelLiked(channel.id) = true
          if channel.hasField("isFavorite") = false
            channel.addField("isFavorite", "bool", false)
          end if
          channel.isFavorite = true
        end if
      end for
    end if

    setInContentCache(screen.timeGridContent, m.constants.ui.screenIds.linearVideoPlayerScreen)
    nFetchInBatch = 10

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
                m.uniqueChannelIdsList.push(epgChannel.id)
              end if
            end if

            if index + j < upIndex
              epgChannel = response.getChild(index + j)
              if channelListAA[epgChannel.id] <> true
                channelListAA[epgChannel.id] = true
                m.uniqueChannelIdsList.push(epgChannel.id)
              end if
            end if
          end for

          exit for
        end if
      end for
    else
      for i = 0 to response.getChildCount() - 1
        epgChannel = response.getChild(i)
        if channelListAA[epgChannel.id] <> true
          channelListAA[epgChannel.id] = true
          m.uniqueChannelIdsList.push(epgChannel.id)
        end if
      end for
    end if
    totalNumChannels = m.uniqueChannelIdsList.Count()

    if totalNumChannels > 0
      makeEPGProgramCalls(response.requestorID, nFetchInBatch)
    else
      onEPGError(response)
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
      analyticsScreenId: m.constants.ui.screenIds.epgScreen
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
      if contentToPlay.needsLogin = true AND isLoggedInUser() = false AND getStatsigExperimentResource("roku_linear_reg_gate", "roku_linear_reg_gate_v1_1").enabled = true
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


' Handles EPG banner selection - navigates to the banner's associated content
' Fires ComponentInteractionEvent (top_nav_component + CONFIRM) and sets
' trackingComponentInfo so the subsequent NavigateToPageEvent has correct context.
' @param msg - Message containing the banner data (game_id, image, start_time, end_time)
Function onEpgBannerSelected(msg) as Void
  bannerData = msg.getData()
  if bannerData = invalid OR isNonEmptyString(bannerData.game_id) = false then return

  epgScreen = getCurrentScreen()
  if epgScreen <> invalid AND epgScreen.trackingPageInfo <> invalid
    pageOneof = m.Tracking.getAnalyticsPage(epgScreen.trackingPageInfo.pageType, epgScreen.trackingPageInfo.pageValues)
    componentOneof = m.Tracking.getAnalyticsComponent("top_nav_component", {})

    fireUserTrackingEvent({
      type: "component_interaction"
      values: {
        pageOneof: pageOneof
        componentOneof: componentOneof
        user_interaction: "CONFIRM"
      }
    })

    epgScreen.trackingComponentInfo = {
      componentType: "top_nav_component"
      componentValues: {}
    }
  end if

  getSingleContentFromServer({ id: bannerData.game_id }, onEpgBannerContentSuccess, onEpgBannerContentError)
End Function


' Handles successful content fetch for EPG banner selection
' Plays the event live if currently airing, otherwise shows the linear detail screen
Function onEpgBannerContentSuccess(content) as Void
  if content = invalid OR isAA(content.scheduleData) = false
    return
  end if

  scheduleData = content.scheduleData
  if isNonEmptyString(scheduleData.startTime) AND (isLoggedInUser() = true OR content.needsLogin = false)
    isEventLive = isLessThanOrEqualToCurrentTime(scheduleData.startTime) AND isGreaterThanCurrentTime(scheduleData.endTime)
    if isEventLive = true
      playerType = scheduleData.playerType
      if playerType = m.constants.ui.playerTypes.fox
        playLinearVideoWithFoxPlayer(content)
      else
        playerLinearChannel(content)
      end if
      return
    end if
  end if

  playbackSource = {
    "srcForAnalytic": m.constants.player.playbackSource.unknown
    "srcForAds": m.constants.player.playbackOrigin.epg
  }
  showLinearDetailScreen(content, playbackSource)
End Function


' Handles error when fetching EPG banner content - shows a default error modal
Function onEpgBannerContentError(error) as Void
  modalInfo = {
    message: getErrorMessage(getTranslation("dialog_errorOops_title"), invalid)
    trackingTask: m.trackingLoggingTask
  }
  showErrorModal(modalInfo)
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

  isScrolling = (scrollingStatus = true OR screen.channelGridScrollingStatus = true OR screen.categoryGridScrollingStatus = true)

  if isScrolling = true
    stopCountdownTimer()
    screen.fullscreenCountdown = -1
  else if screen.linearChannelToPlay <> invalid
    ' Only resume timer if none of the grids are scrolling
    if screen.scrollingStatus <> true AND screen.channelGridScrollingStatus <> true AND screen.categoryGridScrollingStatus <> true
      linearVideoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
      if linearVideoPlayer <> invalid AND linearVideoPlayer.state = "playing"
        startCountdownTimer()
      end if
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


' EPG channel favorites — Will remove if we don't graduate roku_epg_favorites_v1 experiment.
Function onChannelSelected(msg)
  screen = msg.getRoSgNode()
  contentId = msg.getData()
  handleChannelSelectedForFavorites(screen, contentId)
End Function


' EPG channel favorites — Will remove if we don't graduate roku_epg_favorites_v1 experiment.
' @param screen - EPGHomeScreen or LinearVideoPlayerScreen (has timeGridContent, containersList, channelIdSelected)
' @param contentId - channel id that was selected
Function handleChannelSelectedForFavorites(screen, contentId)
  if isLoggedInUser() = true
    if screen <> invalid AND contentId <> invalid
      if isLinearChannelLiked(contentId) = true
        action = m.constants.ui.likeDislikeActions.removeLike
      else
        action = m.constants.ui.likeDislikeActions.like
      end if

      handleAddRemoveFavorites(screen, action)
    end if
  else
    startSignIn(onChannelRatingUpdated)
  end if
End Function


' EPG channel favorites — Will remove if we don't graduate roku_epg_favorites_v1 experiment.
Function setEpgFavoriteOnMatchingChannels(screen, contentIdStr, isFavorite as Boolean) as Void
  if screen <> invalid AND screen.timeGridContent <> invalid AND isNonEmptyString(contentIdStr) = true
    i = 0
    childCount = screen.timeGridContent.getChildCount()
    while i < childCount
      channel = screen.timeGridContent.getChild(i)
      if channel <> invalid AND channel.id <> invalid AND channel.id.toStr() = contentIdStr
        if channel.hasField("isFavorite") = false
          channel.addField("isFavorite", "bool", false)
        end if
        channel.isFavorite = isFavorite
      end if
      i = i + 1
    end while
  end if
End Function


' EPG channel favorites — Will remove if we don't graduate roku_epg_favorites_v1 experiment.
' @param action - m.constants.ui.likeDislikeActions.like or removeLike
Function applyOptimisticEpgFavoriteState(screen, contentIdStr, action) as Void
  if isNonEmptyString(action) = true AND (action = m.constants.ui.likeDislikeActions.like OR action = m.constants.ui.likeDislikeActions.removeLike)
    setEpgFavoriteOnMatchingChannels(screen, contentIdStr, action = m.constants.ui.likeDislikeActions.like)
  end if
End Function


' EPG channel favorites — Will remove if we don't graduate roku_epg_favorites_v1 experiment.
Function revertOptimisticEpgFavoriteState(revertInfo) as Void
  if revertInfo <> invalid AND revertInfo.screen <> invalid AND isNonEmptyString(revertInfo.contentIdStr) = true AND isNonEmptyString(revertInfo.action) = true
    action = revertInfo.action
    if action = m.constants.ui.likeDislikeActions.like OR action = m.constants.ui.likeDislikeActions.removeLike
      optimisticFavorite = (action = m.constants.ui.likeDislikeActions.like)
      setEpgFavoriteOnMatchingChannels(revertInfo.screen, revertInfo.contentIdStr, not optimisticFavorite)
    end if
  end if
End Function


' EPG channel favorites — Will remove if we don't graduate roku_epg_favorites_v1 experiment.
Function handleAddRemoveFavorites(screen, likeDislike = "")
  if isNonEmptyString(likeDislike) = true
    sRatingChange = likeDislike
  else
    sRatingChange = m.constants.ui.likeDislikeActions.like
  end if

  contentIdStr = ""
  if screen <> invalid AND screen.channelIdSelected <> invalid
    contentIdStr = screen.channelIdSelected.toStr()
  end if

  m.optimisticFavoriteRevertInfo = {
    screen: screen
    contentIdStr: contentIdStr
    action: sRatingChange
  }
  applyOptimisticEpgFavoriteState(screen, contentIdStr, sRatingChange)

  updateLikeDislikeRequestInfo = m.userDeviceApi.setContentRating(screen.channelIdSelected, sRatingChange, "linear")

  m.makeRequest({
    url: updateLikeDislikeRequestInfo.url
    requestType: m.constants.reqNames.setContentRating
    options: updateLikeDislikeRequestInfo.options
    successCallback: onFavoritesAddRemoveSuccess
    errorCallback: onFavoritesAddRemoveFailure
    responseType: "assocarray"
  })

End Function


' EPG channel favorites — Will remove if we don't graduate roku_epg_favorites_v1 experiment.
Function onFavoritesAddRemoveSuccess(requestBody)
  m.optimisticFavoriteRevertInfo = invalid

  if requestBody <> invalid AND type(requestBody.data) = "roArray"
    returnedContentId = requestBody.data[0]
    sReturnedAction = requestBody.action

    if returnedContentId <> invalid AND sReturnedAction <> invalid
      epgScreen = getCurrentScreen()
      isEpgOrLinearOverlay = (epgScreen <> invalid AND epgScreen.timeGridContent <> invalid AND (isAnEpgScreen(epgScreen) = true OR epgScreen.id = m.constants.ui.screenIds.linearVideoPlayerScreen))
      if isEpgOrLinearOverlay = true
        favoritesTitle = getTranslation("epg_favorites")
        ' Find channel and check if it's already in favorites
        ' Note: We need to check all channels because:
        ' 1. If adding first time, channel won't be in favorites (favoriteChannelIndex = -1)
        ' 2. We can't exit early until we've checked all channels to confirm it's not in favorites
        originalChannel = invalid
        favoriteChannelIndex = -1
        contentIdStr = returnedContentId.toStr()
        childCount = epgScreen.timeGridContent.getChildCount()

        for i = 0 to childCount - 1
          channel = epgScreen.timeGridContent.getChild(i)
          if channel <> invalid AND channel.id <> invalid AND channel.id.toStr() = contentIdStr
            parentId = channel.parentId
            if parentId = "favorite_channels"
              favoriteChannelIndex = i
            else
              if originalChannel = invalid
                originalChannel = channel
              end if
            end if
            if favoriteChannelIndex > -1 AND originalChannel <> invalid then
              exit for
            end if
          end if
        end for

        focusRestoreParentId = ""
        if originalChannel <> invalid AND originalChannel.hasField("parentId") = true AND isNonEmptyString(originalChannel.parentId) = true AND originalChannel.parentId <> "favorite_channels"
          focusRestoreParentId = originalChannel.parentId
        end if

        if sReturnedAction = m.constants.ui.likeDislikeActions.like
          if originalChannel <> invalid

            if epgScreen.hasField("containersList") = false
              epgScreen.addField("containersList", "node", false)
            end if
            if epgScreen.containersList = invalid
              epgScreen.containersList = CreateObject("roSGNode", "ContentNode")
            end if

            favoritesContainerExists = false
            if epgScreen.containersList.getChildCount() > 0
              firstContainer = epgScreen.containersList.getChild(0)
              if firstContainer <> invalid AND firstContainer.containerId = "favorite_channels"
                favoritesContainerExists = true
              end if
            end if

            if favoritesContainerExists = false
              containerNode = CreateObject("roSGNode", "ContentNode")
              containerNode.title = favoritesTitle
              containerNode.addField("containerId", "string", false)
              containerNode.containerId = "favorite_channels"
              epgScreen.containersList.insertChild(containerNode, 0)
            end if

            favoriteChannel = originalChannel.clone(true)
            favoriteChannel.parentTitle = favoritesTitle
            favoriteChannel.parentId = "favorite_channels"
            if favoriteChannel.hasField("isFavorite") = false
              favoriteChannel.addField("isFavorite", "bool", false)
            end if
            favoriteChannel.isFavorite = true
            epgScreen.timeGridContent.insertChild(favoriteChannel, 0)
          end if
        else if sReturnedAction = m.constants.ui.likeDislikeActions.removeLike
          epgScreen.timeGridContent.removeChildIndex(favoriteChannelIndex)
          if originalChannel <> invalid
            if originalChannel.hasField("isFavorite") = false
              originalChannel.addField("isFavorite", "bool", false)
            end if
            originalChannel.isFavorite = false
          end if
          ' Remove Favorites category from containersList when all favorite channels are removed
          if epgScreen.containersList <> invalid
            favoritesRemaining = false
            for j = 0 to epgScreen.timeGridContent.getChildCount() - 1
              channel = epgScreen.timeGridContent.getChild(j)
              if channel <> invalid AND channel.parentId = "favorite_channels"
                favoritesRemaining = true
                exit for
              end if
            end for
            if favoritesRemaining = false
              for k = epgScreen.containersList.getChildCount() - 1 to 0 step -1
                container = epgScreen.containersList.getChild(k)
                if container <> invalid AND container.containerId = "favorite_channels"
                  epgScreen.containersList.removeChildIndex(k)
                  exit for
                end if
              end for
            end if
          end if
        end if

        ' Keep likedContainer in sync (API persists; no global likeIds needed for EPG)
        if returnedContentId <> invalid
          updateLikedContainerForLinear(returnedContentId, sReturnedAction)
        end if

        ' Send BookmarkEvent for EPG favorites analytics (per analytics spec)
        sendEPGFavoriteBookmarkAnalytics(returnedContentId, sReturnedAction, epgScreen)

        epgScreen.updateTimeGridContent = true

        if isNonEmptyString(focusRestoreParentId) = true AND epgScreen.hasField("jumpToRowItemByID") = true
          epgScreen.jumpToRowItemByID = [returnedContentId, focusRestoreParentId]
        end if
      end if
    end if
  end if
End Function


' EPG channel favorites — Will remove if we don't graduate roku_epg_favorites_v1 experiment.
Function onFavoritesAddRemoveFailure(error)
  revertOptimisticEpgFavoriteState(m.optimisticFavoriteRevertInfo)
  m.optimisticFavoriteRevertInfo = invalid
End Function


' EPG channel favorites — Will remove if we don't graduate roku_epg_favorites_v1 experiment.
Function revalidateEPGContentAfterLocalFavoritesAdd(epgScreen)
  if epgScreen <> invalid
    timeGridContent = epgScreen.timeGridContent
    if timeGridContent <> invalid
      firstChild = timeGridContent.getChild(0)
      if firstChild <> invalid
        if firstChild.hasField("validUntil") = false
          firstChild.addField("validUntil", "integer", false)
        end if
        firstChild.validUntil = Uptime(0) + m.constants.cacheTimes.epgscreen
      end if
    end if
  end if
End Function


' EPG channel favorites — Will remove if we don't graduate roku_epg_favorites_v1 experiment.
Function removeFavoritesFromContainersList(containersList)
  if containersList <> invalid
    k = containersList.getChildCount() - 1
    while k >= 0
      container = containersList.getChild(k)
      if container <> invalid AND container.containerId = "favorite_channels"
        containersList.removeChildIndex(k)
        exit while
      end if
      k = k - 1
    end while
  end if
End Function


' EPG channel favorites — Will remove if we don't graduate roku_epg_favorites_v1 experiment.
Function removeEPGFavoritesOnSignOut()
  tubiLog("EPGScreenHelpers.removeEPGFavoritesOnSignOut")

  m.likedContainer = {}
  deleteScreenContentCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
  deleteScreenContentCache(m.constants.ui.screenIds.epgScreen)
  deleteFromScreenCache(m.constants.ui.screenIds.epgScreen)
End Function


' EPG channel favorites — Will remove if we don't graduate roku_epg_favorites_v1 experiment.
' @channelId: dynamic, the channel id
' @operation: string, likeDislikeActions.like or removeLike
' @epgScreen: roSGNode, the EPG screen for tracking page info
Function sendEPGFavoriteBookmarkAnalytics(channelId, operation, epgScreen)
  if channelId <> invalid AND epgScreen <> invalid AND m.trackingLoggingTask <> invalid
    op = "ADD_TO_QUEUE"
    if operation = m.constants.ui.likeDislikeActions.removeLike
      op = "REMOVE_FROM_QUEUE"
    end if

    pageOneof = m.Tracking.getAnalyticsPage("linear_browse_page", {})
    if epgScreen.trackingPageInfo <> invalid
      pageOneof = m.Tracking.getAnalyticsPage(epgScreen.trackingPageInfo.pageType, epgScreen.trackingPageInfo.pageValues)
    end if

    videoId = 0
    if channelId <> invalid
      if type(channelId) = "roInt" OR type(channelId) = "Integer" OR type(channelId) = "LongInteger"
        videoId = channelId
      else
        videoId = channelId.toInt()
        if videoId = invalid
          videoId = 0
        end if
      end if
    end if

    m.trackingLoggingTask.trackEvent = {
      type: "bookmark"
      values: {
        contentOneof: { video_id: videoId }
        pageOneof: pageOneof
        op: op
      }
    }
  end if
End Function

