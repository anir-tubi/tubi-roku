' Show the VOD detail screen for the selected content.
' @content, associative array, the content item to show.
' @playbackSource, associative array, the playback source for the content.
' @successCb, roFunction, callback to be run on success
' @errorCb, roFunction, callback to be run on error
Function showVodDetailScreen(inputContent, playbackSource, successCb = invalid, errorCb = invalid) as Void
  tubiLog("VodDetailScreenHelpers.showVodDetailScreen")
  showHideLogoBasedOnUiMode()

  if inputContent <> invalid
    ' Prevent creating a duplicate VodDetailScreen if one already exists for this content
    existingScreen = getDetailScreenFromStackWithId(m.constants.ui.screenIds.vodDetailScreen, inputContent.id)
    if existingScreen <> invalid then return

    ' we make changes to the content from this point forward. If we don't clone, changes will be propagated to the original content in home or search screen.
    content = inputContent.clone(true)
    applyVodDetailContentSotSignalsPerDetailScreenExperiment(content, true)
    screen = CreateObject("roSGNode", "VodDetailScreen")
    screen.observeFieldScoped("componentInteractionInfo", "onComponentInteractionInfoChange")
    screen.observeFieldScoped("backButtonPressed", "onDetailBackButtonPressedChange")
    screen.observeFieldScoped("openSideNav", "onOpenSideNavChange")
    screen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
    screen.observeFieldScoped("selectedRelatedContentTrigger", "onVodDetailSelectedRelatedContentTriggerChange")
    screen.observeFieldScoped("ctaSelectedButtonId", "onVodDetailCtaSelectedButtonIdChange")
    screen.observeFieldScoped("focusedSeason", "onFocusedSeasonChange")
    screen.observeFieldScoped("selectedSection", "onVodDetailSelectedSectionChange")
    screen.observeFieldScoped("playSelectedEpisode", "onPlaySelectedEpisodeChange")
    screen.observeFieldScoped("shouldPauseVideoPreview", "onVodDetailShouldPauseVideoPreviewChange")
    screen.observeFieldScoped("backgroundUriList", "onVodDetailBackgroundUriListChange")
    screen.observeFieldScoped("refreshContent", "onVodDetailRefreshContent")
    screen.observeFieldScoped("refreshRelatedContent", "onVodDetailRefreshRelatedContent")
    screen.id = m.constants.ui.screenIds.vodDetailScreen
    screen.shouldFocusWhenPushed = m.top.fadeInContentController
    screen.playbackSource = playbackSource
    screen.userSignedIn = isLoggedInUser()
    screen.isInKidsMode = isKidsUIOn()
    screen.selectedSideNavId = m.SideNav.itemCurrentId
    screen.content = content
    ' This gives a smooth transition when coming from deeplink.
    if content.isSubType("DeeplinkContentNode") = false
      screen.contentUpdated = true
    end if
    screen.trackingPageInfo = getDetailScreenAnalyticsPageInfo(content, m.constants)
    screen.shouldTrackViewableImpressionEvent = (isUserInAdultsMode() = true AND isKidsUIOn() = false)

    pushScreen(screen, true, true)

    m.showVodDetailScreenCallback = {
      "success": successCb
      "error": errorCb
    }

    updatePreviewPlayerToCondensedView()
    previewState = getVideoPreviewState()
    isPreviewActive = (previewState = "playing" OR previewState = "buffering")
    isPreviewForThisContent = isPreviewActive AND getVideoPreviewContentId() = content.id
    if isPreviewForThisContent = true
      if m.videoPreviewPlayer <> invalid
        m.videoPreviewPlayer.videoPlayerType = "BANNER"
        m.videoPreviewPlayer.isDetailScreen = true
        setPageInfoForVideoPreview(screen.trackingPageInfo)
      end if
    else if isPreviewActive = true AND content.videoPreviewUrl <> ""
      startVideoPreview(content, screen.trackingPageInfo)
      ' startVideoPreview resets isDetailScreen to false, so we must set it after
      if m.videoPreviewPlayer <> invalid
        m.videoPreviewPlayer.videoPlayerType = "BANNER"
        m.videoPreviewPlayer.isDetailScreen = true
      end if
    else if m.lowVramPreviewVariant = "detail_screen_only" AND isVideoPreviewOn() = true AND content.videoPreviewUrl <> ""
      startVideoPreview(content, screen.trackingPageInfo)
      ' startVideoPreview resets isDetailScreen to false, so we must set it after
      if m.videoPreviewPlayer <> invalid
        m.videoPreviewPlayer.videoPlayerType = "BANNER"
        m.videoPreviewPlayer.isDetailScreen = true
      end if
    end if

    onVodDetailBackgroundUriListChange()

    v5Experiment = getStatsigExperimentResource("", "roku_content_details_v5", false)
    isPerformanceEnhanced = (v5Experiment <> invalid AND v5Experiment.variant = "performance_enhanced")
    screen.isPerformanceEnhanced = isPerformanceEnhanced

    if isPerformanceEnhanced = true
      m.relatedContentDebounceTimer = CreateObject("roSGNode", "Timer")
      m.relatedContentDebounceTimer.duration = 2
      m.relatedContentDebounceTimer.repeat = false
      m.relatedContentDebounceTimer.observeFieldScoped("fire", "onRelatedContentDebounceTimerFired")
      m.relatedContentDebounceTimer.control = "start"
    else
      getYouMayAlsoLikeContent(content)
    end if

    if content.type = m.constants.ui.contentTypes.series
      screen.wasContentFetchCompleted = false
      if isPerformanceEnhanced = true
        getSingleContentFromServer(content, onGetSeasonListFallbackSuccess, onGetSeasonListFallbackError)
      else
        getSeasonList(content.id, onGetSeasonListSuccess, onGetSeasonListError)
      end if
    else
      ' During deep-link use case we already have the complete content node, so we can skip the fetch.
      screen.wasContentFetchCompleted = content.hasVideoResources
      if content.hasVideoResources <> true
        getSingleContentFromServer(content, onGetVodContentSuccess, onGetVodContentError)
      else
        onGetVodContentSuccess(content)
        ' YMAL API does not return channel data. Fetch channelId async and refresh button list only.
        if isAA(playbackSource) = true AND playbackSource.srcForAds = m.constants.player.playbackOrigin.ymal
          getSingleContentFromServer(content, onGetVodContentChannelInfoSuccess, sub(_error)
          end sub)
        end if
      end if
    end if
    if screen.wasContentFetchCompleted = false
      showHideSpinner(true)
    end if

  end if
End Function


' Handles background URI list change in VOD detail screen
' Updates background info based on new URI list
Function onVodDetailBackgroundUriListChange()
  screen = getDetailScreenFromStackWithId(m.constants.ui.screenIds.vodDetailScreen)
  if screen <> invalid AND screen.content <> invalid AND isNonEmptyArray(screen.content.backgrounds) = true
    updateVodDetailBackground(screen.content)
  end if
End Function


' Content is stale after returning from suspend or background — re-fetch from API
Function onVodDetailRefreshContent(msg)
  screen = msg.getRoSGNode()
  if screen <> invalid AND screen.content <> invalid
    getSingleContentFromServer(screen.content, onGetVodContentSuccess, onGetVodContentError)
  end if
End Function


' Related content is stale — re-fetch "You May Also Like" content
Function onVodDetailRefreshRelatedContent(msg)
  screen = msg.getRoSGNode()
  if screen <> invalid AND screen.content <> invalid
    screen.relatedContent = invalid
    getYouMayAlsoLikeContent(screen.content)
  end if
End Function


' Updates background info based on content backgrounds
' Preserves cinematic background type if already set, otherwise uses spotlight
' @param content - Content node containing backgrounds array
Function updateVodDetailBackground(content)
  if isNode(content) AND isNonEmptyArray(content.backgrounds) = true
    backgroundType = m.constants.ui.backgroundTypes.topright
    m.backgroundGroup.backgroundInfo = {
      type: backgroundType
      uriList: content.backgrounds
    }
  end if
End Function


' Handles section tab change in VOD detail screen
' Fetches related content when "More Like This" tab is selected if not already loaded
' @param msg - roSGNodeEvent containing the selected section ID
Function onVodDetailSelectedSectionChange(msg)
  tubiLog("VodDetailScreenHelpers.onVodDetailSelectedSectionChange")
  selectedSection = msg.getData()
  screen = msg.getRoSGNode()
  if selectedSection = "moreLikeThis" AND screen.relatedContent = invalid
    getYouMayAlsoLikeContent(screen.content)
  end if
End Function


' Success callback for VOD content fetch
' Updates screen with fetched content and triggers playback if skip detail screen was requested
' @param content - Content node returned from API
Function onGetVodContentSuccess(content)
  tubiLog("VodDetailScreenHelpers.onGetVodContentSuccess")
  screen = getDetailScreenFromStackWithId(m.constants.ui.screenIds.vodDetailScreen, content.id)
  if screen <> invalid
    ' Content API does not seem to return sotInfo, so we are copying it from the screen content.
    ' This way if we are displaying SOT in home screen, it will be displayed in the detail screen as well.
    ' TODO: Remove this once Content API returns sotInfo.
    if screen.content <> invalid
      content.sotInfo = screen.content.sotInfo
    end if
    applyVodDetailContentSotSignalsPerDetailScreenExperiment(content)
    screen.content = content
    screen.contentUpdated = true
    screen.wasContentFetchCompleted = true
    updateVodDetailBackground(content)
    showHideSpinner(false)

    executeVodDetailSuccessCallback(content, screen.playbackSource, screen.episodes)
  end if
End Function


' Lightweight callback for async channel info fetch from YMAL navigation.
' Copies only channel fields onto existing screen content and refreshes the button list.
Function onGetVodContentChannelInfoSuccess(content)
  tubiLog("VodDetailScreenHelpers.onGetVodContentChannelInfoSuccess")
  screen = getDetailScreenFromStackWithId(m.constants.ui.screenIds.vodDetailScreen, content.id)
  if screen <> invalid AND screen.content <> invalid AND isNonEmptyString(content.channelId)
    screen.content.update({
      channelId: content.channelId
      channelName: content.channelName
      channelLogoShort: content.channelLogoShort
      inlineLogoUri: content.inlineLogoUri
    }, true)
    screen.shouldRefreshButtonList = true
  end if
End Function


' Error callback for VOD content fetch failure
' Shows error modal with retry option (except for 404 errors)
' @param error - Error response from API
Function onGetVodContentError(error)
  tubiLog("VodDetailScreenHelpers.onGetVodContentError")
  screen = getDetailScreenFromStackWithId(m.constants.ui.screenIds.vodDetailScreen)
  if screen <> invalid AND screen.getSubtype() = "VodDetailScreen"
    screen.wasContentFetchCompleted = true
    showHideSpinner(false)

    content = screen.content
    ' set up the error modal dialog
    errorCode = getUserFacingErrorCode(m.constants.errors.context.videoDetailScreen, m.constants.errors.subtypes.fetchError, error.code)
    dialogEvent = getDetailScreenDialogAnalyticEvent(content, "NETWORK_ERROR", errorCode, m.constants)

    modalInfo = {
      message: getErrorMessage("", errorCode)
      openTrackEvent: dialogEvent
      trackingTask: m.trackingLoggingTask
    }

    playbackSource = screen.playbackSource
    ' 404 errors are not retryable - content ID is invalid
    ' Showing retry button would result in an endless loop
    if error <> invalid AND isInteger(error.code) = true AND error.code = 404 AND (isAA(playbackSource) = false OR playbackSource.srcForAds = m.constants.player.playbackOrigin.deeplink)
      showErrorModal(modalInfo, invalid, invalid, onCloseErrorModal)
    else
      showErrorModal(modalInfo, onGetVodContentRetry)
    end if
  end if
End Function


' Retry callback for VOD content fetch
' Re-attempts to fetch content from server
Function onGetVodContentRetry()
  tubiLog("VodDetailScreenHelpers.onGetVodContentRetry")
  screen = getDetailScreenFromStackWithId(m.constants.ui.screenIds.vodDetailScreen)
  if screen <> invalid AND screen.getSubtype() = "VodDetailScreen"
    content = screen.content
    showHideSpinner(true)
    if content <> invalid
      getSingleContentFromServer(content, onGetVodContentSuccess, onGetVodContentError)
    end if
  end if
End Function


' Handles selection of related content item
' Navigates to detail screen of selected related content with appropriate tracking source
' @param msg - roSGNodeEvent containing the pressed key
Function onVodDetailSelectedRelatedContentTriggerChange(msg) as Void
  tubiLog("VodDetailScreenHelpers.onVodDetailSelectedRelatedContentTriggerChange")
  screen = msg.getRoSGNode()
  pressedKey = msg.getData()
  if screen <> invalid AND screen.id = m.constants.ui.screenIds.vodDetailScreen
    content = screen.selectedRelatedContent
    if content <> invalid
      playbackSource = {
        "srcForAnalytic": m.constants.player.playbackOrigin.ymal
        "srcForAds": m.constants.player.playbackOrigin.ymal
      }

      stopVideoPreview()
      successCb = invalid
      if pressedKey = "play"
        sendButtonComponentInteractionEvent("PLAY", "IMAGE", "CONFIRM", screen)
        successCb = skipDetailScreen
      else
        sendButtonComponentInteractionEvent("OK", "IMAGE", "CONFIRM", screen)
      end if
      showVodDetailScreen(content, playbackSource, successCb)
    end if
  end if
End Function


' Gets the playable content from a screen node
' Determines the correct content to play based on screen content and history
' For series, returns the appropriate episode; for movies, returns the content as-is
' @param screen - VOD detail screen node
' @return Content node to play (episode for series, original content otherwise)
Function getPlayableContent(screen) as Object
  tubiLog("VodDetailScreenHelpers.getPlayableContent")
  content = screen.content
  history = getHistory(content.id)

  ' For series, get the playable episode based on history
  if content.type = m.constants.ui.contentTypes.series
    return getPlayableEpisode(screen.episodes, history)
  end if

  return content
End Function


' Gets the appropriate history for content, retrieving episode-specific history for series
' For series with episode history, returns the specific episode history node
' For movies or series without episode history, returns the content history
' @param content - Content node (movie or series)
' @return History node (episode history for series with currentEpisodeId, otherwise content history)
Function getContentHistory(content as Object) as Object
  tubiLog("VodDetailScreenHelpers.getContentHistory")
  history = getHistory(content.id)

  if content.type = m.constants.ui.contentTypes.series
    if history <> invalid AND isNonEmptyString(history.currentEpisodeId)
      history = m.nodeHelpers.getChildById(history, history.currentEpisodeId)
    end if
  end if

  return history
End Function

' Success callback for episodes content fetch
Function onVodEpisodesContentSuccess(content)
  showHideSpinner(false)
  screen = getDetailScreenFromStackWithId(m.constants.ui.screenIds.vodDetailScreen, content.id)
  if screen <> invalid
    showEpisodeScreenWithNavigationTracking(content, screen.playbackSource)
  end if
End Function

' Error callback for episodes content fetch
Function onVodEpisodesContentError(error)
  tubiLog("VodDetailScreenHelpers.onVodEpisodesContentError: " + formatJson(error))
  showHideSpinner(false)
End Function


' Handles CTA button selections on VOD detail screen
' Routes button actions like play, resume, add to queue, like/dislike, sign in, etc.
' Waits for content fetch completion before processing if necessary
' @param msg - roSGNodeEvent containing the selected button ID
Function onVodDetailCtaSelectedButtonIdChange(msg) as Void
  tubiLog("VodDetailScreenHelpers.onVodDetailCtaSelectedButtonIdChange")
  screen = msg.getRoSGNode()
  if screen <> invalid AND screen.content <> invalid AND isNonEmptyString(screen.ctaSelectedButtonId)
    id = screen.ctaSelectedButtonId

    ' Since we are loading details screen async for better UX and time to load.
    ' If the content fetch is not complete, we will not be able to play the content.
    screen.unobserveFieldScoped("wasContentFetchCompleted")
    if screen.wasContentFetchCompleted = false
      showHideSpinner(true)
      screen.observeFieldScoped("wasContentFetchCompleted", "onVodDetailCtaSelectedButtonIdChange")
      return
    end if

    content = screen.content
    screenContent = content
    ' Handle resume action
    history = getHistory(content.id)
    if content.type = m.constants.ui.contentTypes.series
      content = getPlayableEpisode(screen.episodes, history)

      if history <> invalid AND isNonEmptyString(history.currentEpisodeId)
        history = m.nodeHelpers.getChildById(history, history.currentEpisodeId)
      end if
    end if

    if id = "play" OR id = "startFromBeginning"
      playVideoContent(content, screen.playbackSource, 0)
    else if id = "resume"
      nowPos = 0
      if history <> invalid AND history.nowPos > 0
        nowPos = history.nowPos
      end if
      playVideoContent(content, screen.playbackSource, nowPos)
    else if id = "watchTrailer"
      trailer = createTrailerContent(screenContent)
      if trailer <> invalid
        playVideoContent(trailer, screen.playbackSource)
      else
        tubiLog("VodDetailScreenHelpers: Cannot play trailer - invalid trailerInfo")
      end if
    else if id = "signIn"
      startSignIn(refreshVodDetailScreenAfterSignIn)
    else if id = "addToQueue"
      ' Using screen.content to account for both movie and series content.
      addContentToMyList(screen.content)
    else if id = "removeFromQueue"
      ' Using screen.content to account for both movie and series content.
      removeContentFromMyList(screen.content)
    else if id = "like" OR id = "dislike"
      if isLoggedInUser() = true
        action = getLikeDislikeAction(screenContent, id)
        likeDislikeContent(screenContent, action, screen.trackingPageInfo)
      else
        ' User needs to sign in before liking/disliking
        ' ctaSelectedButtonId is already set on screen when button is selected
        startSignIn(onLikeDislikeAfterSignInVodDetail)
      end if
    else if id = "gotoChannel"
      showChannelDetailsScreen(screenContent.channelId)
    else if id = "creator"
      if screenContent.creatorTensorApp <> invalid
        if lcase(screenContent.creatorTensorApp.type) <> m.constants.ui.appTypes.creator
          showPivotDetailScreen(screenContent.creatorTensorApp)
        else
          showCollectionScreen(screenContent.creatorTensorApp.id)
        end if
      end if
    else if id = "removeFromHistory"
      removeHistoryFromVodDetailScreen(screenContent)
    else if id = "episodes"
      showHideSpinner(true)
      getSingleContentFromServer(screenContent, onVodEpisodesContentSuccess, onVodEpisodesContentError)
    end if
  end if
End Function


' Refreshes VOD detail screen after user signs in
' Updates user signed-in state, refreshes UI and marks personalized screens for refresh
Function refreshVodDetailScreenAfterSignIn()
  tubiLog("VodDetailScreenHelpers.refreshVodDetailScreenAfterSignIn")
  popScreenAfterSignInProcess()
  screen = getDetailScreenFromStackWithId(m.constants.ui.screenIds.vodDetailScreen)
  if screen <> invalid
    screen.userSignedIn = isLoggedInUser()
  end if
  showContentGroupAndHideSpinner()
  refreshUiAfterSignIn()
  setContentToRefreshAllPersonalizedScreens(true)
End Function


' Gets the playable episode from content based on history
' Returns the episode from history if available, otherwise returns first episode
' @param content - Content node containing episodes
' @param history - Optional history object with currentEpisodeId
' @return Episode content node or invalid
Function getPlayableEpisode(content, history = invalid)
  if content <> invalid
    if history <> invalid AND isNonEmptyString(history.currentEpisodeId)
      episode = m.nodeHelpers.getChildById(content, history.currentEpisodeId)
      if episode <> invalid then return episode
    end if
    return content.getChild(0)
  end if

  return invalid
End Function


' Success callback for related content request
' Updates the VOD detail screen with fetched related content
' @param relatedContent - Content node containing related titles
Function onGetRelatedContentSuccess(relatedContent)
  tubiLog("VodDetailScreenHelpers.onGetRelatedContentSuccess")
  if relatedContent <> invalid
    screen = getDetailScreenFromStackWithId(m.constants.ui.screenIds.vodDetailScreen, relatedContent.id)
    if screen <> invalid
      screen.relatedContent = relatedContent
      screen.relatedContentUpdated = true
    end if
  end if
End Function


' Fetches season list with episodes for a series
' @contentId: string, the ID of the series
' @successCallback: roFunction, callback to be run on success
' @errorCallback: roFunction, callback to be run on error
Function getSeasonList(contentId, successCallback, errorCallback)
  tubiLog("VodDetailScreenHelpers.getSeasonList")
  ' Fetch first season, first page with 10 episodes
  seasonRequestInfo = m.CmsApi.createGetSeasonListBySeriesIdReqInfo(contentId, shouldKidsModeBeSentToServer(), { seriesId: contentId })
  m.makeRequest({
    url: seasonRequestInfo.url
    requestType: m.constants.reqNames.getSeasonListBySeriesId
    options: seasonRequestInfo.options
    successCallback: successCallback
    errorCallback: errorCallback
    responseType: "assocarray"
    isSignedInUser: isLoggedInUser()
    seasonLabel: getTranslation("screenDetails_season_label")
    analyticsScreenId: getLogPageScreenIdForContentType(m.constants, m.constants.ui.contentTypes.series)
  })
End Function


' Success callback for season list request
' @seasonData: roSGNode, the season data content node
Function onGetSeasonListSuccess(seasonData)
  tubiLog("VodDetailScreenHelpers.onGetSeasonListSuccess")
  if seasonData <> invalid AND seasonData.seasonSelectorContent <> invalid
    seriesId = seasonData.seriesId
    screen = getDetailScreenFromStackWithId(m.constants.ui.screenIds.vodDetailScreen, seriesId)
    if screen <> invalid
      seasonNum = resolveSeasonNum(seriesId, seasonData)

      if seasonNum <> invalid
        episodeList = seasonData.seasons[seasonNum]
        if episodeList <> invalid
          pageSizeInSeason = episodeList.count()
          screen.defaultSelectedSeason = seasonNum
          screen.seasonList = seasonData
          getSeriesEpisodes(seriesId, seasonNum, 1, pageSizeInSeason)
        end if
      else
        ' episodes_by_season was present but empty (seasons AA is blank), so
        ' resolveSeasonNum() returned invalid — this is the coming soon series path.
        ' Fall back to singleContent (/api/v2/content) to get the full series node,
        ' including availabilityStarts, which is not present on the homescreen stub.
        if screen.content <> invalid
          getSingleContentFromServer(screen.content, onGetSeasonListFallbackSuccess, onGetSeasonListFallbackError)
        else
          showHideSpinner(false)
        end if
      end if
    end if
  end if
End Function


' Resolves the season number to display for a series
' Priority: deeplink episode -> history episode -> first available season
' @param seriesId - The series content ID
' @param seasonData - AA with episodeSeasonMap and seasonSelectorContent
' @return String season number or invalid if none found
Function resolveSeasonNum(seriesId, seasonData) as Object
  if seasonData = invalid then return invalid

  history = getHistory(seriesId)

  ' 1. Deeplink episode takes priority
  if m.deeplinkContent <> invalid AND m.deeplinkContent.deeplinkType = "episode"
    deeplinkEpisodeId = m.deeplinkContent.id
    if deeplinkEpisodeId <> invalid AND seasonData.episodeSeasonMap <> invalid
      deeplinkSeasonMap = seasonData.episodeSeasonMap[deeplinkEpisodeId.toStr()]
      if deeplinkSeasonMap <> invalid
        return deeplinkSeasonMap.seasonNum.toStr()
      end if
    end if
  end if

  ' 2. Fall back to history-based season selection
  if history <> invalid AND history.currentEpisodeId <> invalid AND seasonData.episodeSeasonMap <> invalid
    currentEpisodeId = history.currentEpisodeId.toStr()
    currentEpisodeSeasonMap = seasonData.episodeSeasonMap[currentEpisodeId]
    if currentEpisodeSeasonMap <> invalid
      return currentEpisodeSeasonMap.seasonNum.toStr()
    end if
  end if

  ' 3. Fall back to first season
  if isNode(seasonData.seasonSelectorContent)
    seasonNode = seasonData.seasonSelectorContent.getChild(0)
    if seasonNode <> invalid
      firstSeasonItem = seasonNode.getChild(0)
      if firstSeasonItem <> invalid
        return firstSeasonItem.seasonNumber
      end if
    end if
  end if

  return invalid
End Function


' Error callback for season list request
' Falls back to content API to fetch series with all episodes
' @error: object, error information
Function onGetSeasonListError(error)
  logError(formatJson(error), "vodDetail", "season-list-error", 0.1)

  screen = getDetailScreenFromStackWithId(m.constants.ui.screenIds.vodDetailScreen)
  if screen <> invalid AND screen.content <> invalid
    getSingleContentFromServer(screen.content, onGetSeasonListFallbackSuccess, onGetSeasonListFallbackError)
  else
    showHideSpinner(false)
  end if
End Function


' Handles focused season change
' When content was fetched via Content API (seasonChildIndexMap present), builds
' episodes locally. Otherwise falls back to the Episodes API call.
' @msg: object, the message containing the focused season
Function onFocusedSeasonChange(msg)
  tubiLog("VodDetailScreenHelpers.onFocusedSeasonChange")
  focusedSeason = msg.getData()
  screen = msg.getRoSGNode()
  if screen <> invalid AND screen.content <> invalid AND focusedSeason <> invalid AND focusedSeason <> screen.defaultSelectedSeason AND screen.seasonList <> invalid
    seasonNum = focusedSeason.toStr()

    if screen.seasonList.seasonChildIndexMap <> invalid
      seasonEpisodes = buildSeasonEpisodesNode(screen.content, seasonNum, screen.seasonList.seasonChildIndexMap)
      if seasonEpisodes <> invalid
        screen.episodes = seasonEpisodes
      end if
    else
      seasons = screen.seasonList.seasons
      if seasons <> invalid AND seasons[seasonNum] <> invalid
        totalEpisodes = seasons[seasonNum].count()
        getSeriesEpisodes(screen.content.id, focusedSeason, 1, totalEpisodes)
      end if
    end if
  end if
End Function


' Fetches series episodes by season with pagination
' @seriesId: string, the ID of the series
' @season: integer, the season number (default: 1)
' @pageInSeason: integer, the page number within the season (default: 1)
' @pageSizeInSeason: integer, the number of episodes per page (default: 10)
Function getSeriesEpisodes(seriesId, season = 1, pageInSeason = 1, pageSizeInSeason = 10)
  tubiLog("VodDetailScreenHelpers.getSeriesEpisodes")
  if seriesId <> invalid AND seriesId <> ""
    episodesRequestInfo = m.CmsApi.createSeriesEpisodesBySeasonReqInfo(seriesId, season, pageInSeason, pageSizeInSeason, true, shouldKidsModeBeSentToServer())
    getStatsigExperimentResource("", "roku_content_v3_endpoints", true)

    m.makeRequest({
      url: episodesRequestInfo.url
      requestType: m.constants.reqNames.getSeriesEpisodesBySeason
      options: episodesRequestInfo.options
      successCallback: onGetSeriesEpisodesSuccess
      errorCallback: onGetSeriesEpisodesError
      responseType: "assocarray"
      isSignedInUser: isLoggedInUser()
      analyticsScreenId: getLogPageScreenIdForContentType(m.constants, m.constants.ui.contentTypes.series)
    })
  end if
End Function


' Success callback for series episodes request
' @episodes: roSGNode, the episodes content node
Function onGetSeriesEpisodesSuccess(response)
  tubiLog("VodDetailScreenHelpers.onGetSeriesEpisodesSuccess")
  if response <> invalid
    seasonNode = response.seasonNode
    content = response.content
    screen = getDetailScreenFromStackWithId(m.constants.ui.screenIds.vodDetailScreen, seasonNode.id)
    if screen <> invalid AND screen.content <> invalid AND content <> invalid
      ' Since SOT info is present only at home screen, we are copying it to the detail screen content.
      content.sotInfo = screen.content.sotInfo
      applyVodDetailContentSotSignalsPerDetailScreenExperiment(content)
      screen.content.update(content, true)
      screen.episodes = seasonNode
      screen.contentUpdated = true
      screen.wasContentFetchCompleted = true
      updateVodDetailBackground(screen.content)
      executeVodDetailSuccessCallback(screen.content, screen.playbackSource, seasonNode)
    end if
  end if
  showHideSpinner(false)
End Function


' Error callback for series episodes request
' @error: object, error information
Function onGetSeriesEpisodesError(error)
  tubiLog("VodDetailScreenHelpers.onGetSeriesEpisodesError: " + formatJson(error))
  screen = getDetailScreenFromStackWithId(m.constants.ui.screenIds.vodDetailScreen)
  if screen <> invalid
    screen.wasContentFetchCompleted = true
  end if
  showHideSpinner(false)
End Function


' Creates a trailer content node from the main content
' Copies relevant properties from the main content to the trailer content
' @param content - The main content node containing trailer information
' @return TubiContentNode configured for trailer playback, or invalid if no valid trailer info
Function createTrailerContent(content as Object) as Object
  tubiLog("VodDetailScreenHelpers.createTrailerContent")
  if content = invalid OR content.trailerInfo = invalid then return invalid

  ' Cache trailerInfo reference to avoid repeated property lookups
  trailerInfo = content.trailerInfo

  ' Validate that trailerInfo has required fields
  if not isNonEmptyString(trailerInfo.url) OR not isNonEmptyString(trailerInfo.streamFormat) OR trailerInfo.id = invalid
    return invalid
  end if

  trailerContent = CreateObject("roSGNode", "TubiContentNode")

  ' Build all properties in a single object for efficient batch update
  properties = {
    nowPos: 0
    availabilityStarts: content.availabilityStarts
    isTrailer: true
    isCdc: content.isCdc
    url: trailerInfo.url
    streamFormat: trailerInfo.streamFormat
    id: trailerInfo.id
    subtitleTracks: []
    subtitleConfig: invalid
    rating: content.rating
    descriptorCode: content.descriptorCode
    descriptors: content.descriptors
    descriptorDescription: content.descriptorDescription
    type: content.type
    needsLogin: content.needsLogin
    loginReason: content.loginReason
    title: getTranslation("videoPlayer_trailerTitle", { title: content.title })
  }

  ' Apply all properties in a single batch update
  trailerContent.update(properties, true)

  return trailerContent
End Function


' Adds content (movie or series) to user's watch later queue
' Shows sign-in dialog if user is not logged in, otherwise sends API request
' @param content - Content node to add to queue
Function addContentToMyList(content) as Void
  tubiLog("VodDetailScreenHelpers.addContentToMyList")
  if isLoggedInUser() = false
    title = getTranslation("screenDetails_error_addQueue_title")
    if content <> invalid AND content.type = m.constants.ui.contentTypes.series
      message = getTranslation("screenDetails_error_addQueueSeries_description")
    else
      message = getTranslation("screenDetails_error_addQueueMovie_description")
    end if

    dialogEvent = getDetailScreenDialogAnalyticEvent(content, "ADD_TO_QUEUE", "sign-in-bookmark", m.constants)
    buttons = [getTranslation("dialog_button_continue"), getTranslation("dialog_button_cancel")]

    callback = sub()
      startSignIn(addContentToMyListAfterSignIn)
    end sub
    showSimpleInstantResumableModal(title, message, buttons, dialogEvent, m.trackingLoggingTask, callback)
  else
    queueType = m.constants.userQueueType.watchLater

    if content.type = m.constants.ui.contentTypes.video
      contentType = m.constants.uapiContentTypes.movie
    else
      contentType = content.type
    end if

    addToQueueReq = m.userDeviceApi.addToQueueReqInfo(content.id, contentType, queueType)
    m.makeRequest({
      url: addToQueueReq.url
      requestType: m.constants.reqNames.postToQueue
      options: addToQueueReq.options
      successCallback: onAddContentToMyListSuccess
      errorCallback: onAddContentToMyListError
      responseType: "assocarray"
      analyticsScreenId: getLogPageScreenIdForContentType(m.constants, content.type)
    })
  end if
End Function


' Success callback for add to queue request
' Updates local bookmark state, refreshes button list and sends analytics
' @param response - API response containing content_id
Function onAddContentToMyListSuccess(response)
  tubiLog("VodDetailScreenHelpers.onAddContentToMyListSuccess")
  if response <> invalid AND response.content_id <> invalid
    contentId = getContentIdFromQueueResponse(response)
    screen = getDetailScreenFromStackWithId(m.constants.ui.screenIds.vodDetailScreen, contentId)
    if screen <> invalid AND screen.content <> invalid
      content = screen.content
      updateBookmarkLocally(content, true)
      handleQueueChange()
      sendVodDetailBookmarkAnalytics(content, "ADD_TO_QUEUE", screen.trackingPageInfo)
      screen.shouldRefreshButtonList = true
    end if
  end if
End Function


' Error callback for add to queue request failure
' Shows appropriate error message based on content type
' @param error - Error response from API
Function onAddContentToMyListError(error) as Void
  tubiLog("VodDetailScreenHelpers.onAddContentToMyListError")
  screen = getDetailScreenFromStackWithId(m.constants.ui.screenIds.vodDetailScreen)
  content = invalid
  if screen <> invalid then content = screen.content

  translationKey = "screenDetails_error_queueMovie_description"
  if content <> invalid AND content.type = m.constants.ui.contentTypes.series
    translationKey = "screenDetails_error_queueSeries_description"
  end if

  handleVodDetailButtonError(error, "ADD_TO_MY_LIST", translationKey, m.constants.errors.subtypes.addBookmarkError)
End Function


' Callback to add content to queue after successful sign-in
' Refreshes screen state and triggers add to queue flow
Function addContentToMyListAfterSignIn()
  tubiLog("VodDetailScreenHelpers.addContentToMyListAfterSignIn")
  screen = getDetailScreenFromStackWithId(m.constants.ui.screenIds.vodDetailScreen)
  if screen <> invalid
    refreshVodDetailScreenAfterSignIn()
    addContentToMyList(screen.content)
  end if
End Function


' Removes content from user's watch later queue
' Sends API request to remove content using bookmark ID
' @param content - Content node to remove from queue
Function removeContentFromMyList(content)
  tubiLog("VodDetailScreenHelpers.removeContentFromMyList")
  bookmark = getBookmark(content.id)
  if bookmark <> invalid
    if content.type = m.constants.ui.contentTypes.video
      contentType = m.constants.uapiContentTypes.movie
    else
      contentType = content.type
    end if

    removeFromQueueReq = m.userDeviceApi.removeFromQueueReqInfo(bookmark.bookmarkId, content.id, contentType)

    m.makeRequest({
      url: removeFromQueueReq.url
      requestType: m.constants.reqNames.deleteFromQueue
      options: removeFromQueueReq.options
      successCallback: onRemoveContentFromMyListSuccess
      errorCallback: onRemoveContentFromMyListError
      responseType: "assocarray"
      analyticsScreenId: getLogPageScreenIdForContentType(m.constants, content.type)
    })
  end if
End Function


' Success callback for remove from queue request
' Updates local bookmark state, refreshes button list and sends analytics
' @param response - API response containing content_id
Function onRemoveContentFromMyListSuccess(response)
  tubiLog("VodDetailScreenHelpers.onRemoveContentFromMyListSuccess")
  if response <> invalid AND response.content_id <> invalid
    contentId = getContentIdFromQueueResponse(response)
    screen = getDetailScreenFromStackWithId(m.constants.ui.screenIds.vodDetailScreen, contentId)
    if screen <> invalid AND screen.content <> invalid
      content = screen.content
      updateBookmarkLocally(content, false)
      sendVodDetailBookmarkAnalytics(content, "REMOVE_FROM_QUEUE", screen.trackingPageInfo)
      handleQueueChange()
      screen.shouldRefreshButtonList = true
    end if
  end if
End Function


' Extracts and formats content ID from queue API response
' Adds leading "0" prefix for series content if not present
' @param response - API response containing content_id and content_type
' @return Formatted content ID string
Function getContentIdFromQueueResponse(response)
  tubiLog("VodDetailScreenHelpers.getContentIdFromQueueResponse")
  contentId = response.content_id.toStr()
  if response.content_type = m.constants.ui.contentTypes.series AND contentId.startsWith("0") = false
    contentId = "0" + contentId
  end if
  return contentId
End Function


' Error callback for remove from queue request failure
' Shows appropriate error message based on content type
' @param error - Error response from API
Function onRemoveContentFromMyListError(error) as Void
  tubiLog("VodDetailScreenHelpers.onRemoveContentFromMyListError")
  screen = getDetailScreenFromStackWithId(m.constants.ui.screenIds.vodDetailScreen)
  content = invalid
  if screen <> invalid then content = screen.content

  translationKey = "screenDetails_error_noQueueMovie_description"
  if content <> invalid AND content.type = m.constants.ui.contentTypes.series
    translationKey = "screenDetails_error_noQueueSeries_description"
  end if

  handleVodDetailButtonError(error, "REMOVE_FROM_MY_LIST", translationKey, m.constants.errors.subtypes.removeBookmarkError)
End Function


' Handles like/dislike action for content
' Sends API request to update content rating and tracks analytics event
' @param content - Content node to rate
' @param action - Like action (like, dislike, removeLike, removeDislike)
' @param trackingPageInfo - Tracking page information for analytics
Function likeDislikeContent(content, action, trackingPageInfo)
  tubiLog("VodDetailScreenHelpers.likeDislikeContent")
  updateLikeDislikeRequestInfo = m.userDeviceApi.setContentRating(content.id, action)
  likeDislikeActions = m.constants.ui.likeDislikeActions
  eventType = {}
  eventType[likeDislikeActions.like] = "LIKE"
  eventType[likeDislikeActions.dislike] = "DISLIKE"
  eventType[likeDislikeActions.removeLike] = "UNDO_LIKE"
  eventType[likeDislikeActions.removeDislike] = "UNDO_DISLIKE"

  sendVodDetailLikeSelectAnalytics(content, trackingPageInfo, eventType[action])

  m.makeRequest({
    url: updateLikeDislikeRequestInfo.url
    requestType: m.constants.reqNames.setContentRating
    options: updateLikeDislikeRequestInfo.options
    successCallback: onContentLikeDislikeChangedSuccess
    errorCallback: onContentLikeDislikeChangedError
    responseType: "assocarray"
    analyticsScreenId: getLogPageScreenIdForContentType(m.constants, content.type)
  })
End Function


' Success callback for like/dislike request
' Updates local like state, refreshes button list and updates screen state
' @param response - API response containing content ID and action
Function onContentLikeDislikeChangedSuccess(response)
  tubiLog("VodDetailScreenHelpers.onContentLikeDislikeChangedSuccess")
  if response <> invalid AND type(response.data) = "roArray"
    contentId = response.data[0]
    action = response.action
    m.Bookmarks.updateLikesLocally(contentId, action, m.global)
    screen = getDetailScreenFromStackWithId(m.constants.ui.screenIds.vodDetailScreen, contentId)
    if screen <> invalid AND screen.content <> invalid
      setVodDetailLikeDislikeState(screen, action)
      screen.shouldRefreshButtonList = true
    end if
  end if
End Function


' Error callback for like/dislike request failure
' Logs error details for debugging
' @param error - Error response from API
Function onContentLikeDislikeChangedError(error)
  tubiLog("VodDetailScreenHelpers.onContentLikeDislikeChangedError: " + formatJson(error))
End Function


' Determines the like/dislike action based on current like state and button ID
' @param content - Content node to check like state for
' @param buttonId - String, button ID ("like" or "dislike")
' @return String - Action from constants.ui.likeDislikeActions
Function getLikeDislikeAction(content, buttonId as String) as String
  tubiLog("VodDetailScreenHelpers.getLikeDislikeAction")
  like = getLike(content.id)
  if like <> invalid
    if like.state = "liked"
      if buttonId = "like"
        return m.constants.ui.likeDislikeActions.removeLike
      else
        ' Switching from like to dislike
        return m.constants.ui.likeDislikeActions.dislike
      end if
    else
      ' like.state = "disliked"
      if buttonId = "dislike"
        return m.constants.ui.likeDislikeActions.removeDislike
      else
        ' Switching from dislike to like
        return m.constants.ui.likeDislikeActions.like
      end if
    end if
  else
    return m.constants.ui.likeDislikeActions[buttonId]
  end if
End Function


' Callback executed after successful sign-in when user wanted to like/dislike content on VOD detail screen
' Uses screen.ctaSelectedButtonId to determine which action to execute
Function onLikeDislikeAfterSignInVodDetail()
  tubiLog("VodDetailScreenHelpers.onLikeDislikeAfterSignInVodDetail")
  refreshVodDetailScreenAfterSignIn()
  screen = getDetailScreenFromStackWithId(m.constants.ui.screenIds.vodDetailScreen)
  if screen <> invalid AND screen.content <> invalid AND isNonEmptyString(screen.ctaSelectedButtonId)
    ' Get the button ID that was selected (either "like" or "dislike")
    buttonId = screen.ctaSelectedButtonId
    if buttonId = "like" OR buttonId = "dislike"
      action = getLikeDislikeAction(screen.content, buttonId)
      likeDislikeContent(screen.content, action, screen.trackingPageInfo)
    end if
  end if
End Function


' Translates a like/dislike action into a like/dislike state
' @param action - The like action from constants.ui.likeDislikeActions
' @return The liked state from constants.ui.likeDislikeStates, or empty string
Function translateLikeActionToState(action as String) as Dynamic
  tubiLog("VodDetailScreenHelpers.translateLikeActionToState")
  ' Map action to state using associative array for O(1) lookup
  likeDislikeActions = m.constants.ui.likeDislikeActions
  likeDislikeStates = m.constants.ui.likeDislikeStates
  actionToStateMap = {}
  actionToStateMap[likeDislikeActions.like] = likeDislikeStates.liked
  actionToStateMap[likeDislikeActions.dislike] = likeDislikeStates.disliked

  if actionToStateMap.doesExist(action)
    return actionToStateMap[action]
  else
    return invalid
  end if
End Function


' Updates the VOD detail screen like/dislike state and shows toast notification if applicable
' @param screen - The VOD detail screen node
' @param action - The like action that was performed
Function setVodDetailLikeDislikeState(screen as Object, action as String) as Void
  tubiLog("VodDetailScreenHelpers.setVodDetailLikeDislikeState")
  ' Show toast notification for US users (non-kids mode only)
  canShowToast = (UCase(m.constants.deviceInfo.countryCode) = "US" AND isKidsUIOn() = false)
  if canShowToast = true
    ' Translate action to state
    state = translateLikeActionToState(action)
    if state <> invalid
      showLikeDislikeToast(screen, state)
    end if
  end if
End Function


' Shows a toast notification for like or dislike action
' Only shows once per action type (persisted to device storage)
' @param screen - The detail screen for analytics tracking
' @param state - The like/dislike state (liked or disliked)
Function showLikeDislikeToast(screen as Object, state as String) as Void
  tubiLog("VodDetailScreenHelpers.showLikeDislikeToast")
  likeDislikeStates = m.constants.ui.likeDislikeStates
  dialogSubType = state + "_title"

  ' Determine toast configuration based on state
  if state = likeDislikeStates.liked
    persistenceKey = "isLikeToastNotificationShown"
    messageKey = "detail_screen_like_toast_message"
    iconUri = "pkg:/images/icon_like_toast.webp"
  else
    persistenceKey = "isDisLikeToastNotificationShown"
    messageKey = "detail_screen_disLike_toast_message"
    iconUri = "pkg:/images/icon_dislike_toast.webp"
  end if

  ' Check if toast has already been shown
  if m.pub_serverPersistentData[persistenceKey] = true
    return
  end if

  ' Mark toast as shown
  persistData = {}
  persistData[persistenceKey] = true
  saveServerPersistentData(persistData, "device")

  ' Build toast info
  toastInfo = {
    message: getTranslation(messageKey)
    headerText: getTranslation("detail_screen_like_disLike_toast_header")
    imageUri: iconUri
    selfDestructTimer: 5
  }

  ' Build dialog event for analytics
  dialogEventInfo = {
    type: "dialog"
    values: {
      dialog_type: "TOAST"
      pageOneof: m.Tracking.getAnalyticsPage(screen.trackingPageInfo.pageType, screen.trackingPageInfo.pageValues)
      dialog_action: "SHOW"
      dialog_sub_type: dialogSubType
    }
  }

  showToast(toastInfo, true, dialogEventInfo)
End Function


' Handles episode selection from episode list
' Plays selected episode with progress resume if available
' @param msg - roSGNodeEvent containing episode selected flag
Function onPlaySelectedEpisodeChange(msg) as Void
  tubiLog("VodDetailScreenHelpers.onPlaySelectedEpisodeChange")
  screen = msg.getRoSGNode()
  if screen <> invalid AND screen.id = m.constants.ui.screenIds.vodDetailScreen
    selectedEpisode = screen.selectedEpisode
    ' Set progress bar
    history = getHistory(selectedEpisode.id.toStr())
    nowPos = 0
    if history <> invalid AND isNumber(history.nowPos) = true
      nowPos = history.nowPos
    end if
    stopVideoPreview()
    playVideoContent(selectedEpisode, screen.playbackSource, nowPos)
  end if
End Function


' Shows channel details screen for a given channel ID
' Creates a channel content node and navigates to category details screen
' @param channelId - String ID of the channel to display
Function showChannelDetailsScreen(channelId)
  tubiLog("VodDetailScreenHelpers.showChannelDetailsScreen")
  channelNode = CreateObject("roSGNode", "CategoryContentNode")
  channelNode.id = channelId
  channelNode.type = m.constants.ui.contentTypes.channel

  showCategoryDetailsScreen(channelNode)
End Function


' Plays selected VOD content with appropriate resume position
' For series, gets playable episode based on history; for movies, plays directly
' @param content - Content node to play
' @param playbackSource - Playback source information for analytics
' @param episodes - Optional episodes list for series content
Function playSelectedVodContent(content, playbackSource, episodes = invalid)
  tubiLog("VodDetailScreenHelpers.playSelectedVodContent")

  isComingSoon = isComingSoonContent(content)
  '//Ensure content is not coming soon; otherwise do not play
  if isComingSoon = false
    history = getHistory(content.id)
    if content.type = m.constants.ui.contentTypes.series
      episode = invalid
      deeplinkEpisodeId = invalid

      ' Honor a specific episode ID (e.g. from episode deeplink) before falling back to history
      if isNonEmptyString(content.currentEpisodeId)
        deeplinkEpisodeId = content.currentEpisodeId
        episode = m.nodeHelpers.getChildById(episodes, deeplinkEpisodeId)
      end if

      if episode = invalid
        episode = getPlayableEpisode(episodes, history)
      end if

      content = episode

      if history <> invalid
        episodeIdForHistory = deeplinkEpisodeId
        if episodeIdForHistory = invalid AND isNonEmptyString(history.currentEpisodeId)
          episodeIdForHistory = history.currentEpisodeId
        end if
        if isNonEmptyString(episodeIdForHistory)
          history = m.nodeHelpers.getChildById(history, episodeIdForHistory)
        end if
      end if
    end if

    nowPos = 0
    if history <> invalid AND history.nowPos > 0
      nowPos = history.nowPos
    end if
    playVideoContent(content, playbackSource, nowPos)

    if playbackSource.srcForAnalytic = "previews"
      removeTopMostScreenWithIDFromStack(m.constants.ui.screenIds.vodDetailScreen)
      displayDefaultBackground()
    end if
  end if

End Function


' Executes the VOD detail screen success callback if defined
' Handles skip detail screen scenario by auto-playing content, or calls custom success callback
' @param content - Content node to pass to callback or play
' @param playbackSource - Playback source information for analytics
' @param episodes - Optional episodes list for series content (used when skipping detail screen)
Function executeVodDetailSuccessCallback(content, playbackSource, episodes = invalid) as Void

  if m.top.fadeInContentController = true
    ' send deep-link analytics if the content was deep-linked to this screen.
    if m.enteredFromDeepLink = true AND m.deeplinkContent <> invalid
      sendDeeplinkAnalytics(m.deeplinkContent, content, m.constants.deeplinks.entryPoints.video, m.Tracking, m.trackingLoggingTask, m.constants)
    end if

    successCb = m.showVodDetailScreenCallback.success
    if successCb = skipDetailScreen OR successCb = skipDetailScreenDeeplinkWrapper
      isComingSoon = isComingSoonContent(content)
      if content.policyMatch = false AND content.hasVideoResources = false AND isComingSoon = false
        resetDeeplinkValues()
        popScreen()
        return
      end if
      if isComingSoon = false
        playSelectedVodContent(content, playbackSource, episodes)
      end if
    else if successCb <> invalid
      successCb(content)
    end if
  else
    m.detailScreenAfterFn = startPlaybackAfterAnimationComplete
  end if
End Function


Function startPlaybackAfterAnimationComplete(screen)
  tubiLog("VodDetailScreenHelpers.startPlaybackAfterAnimationComplete")
  if screen <> invalid AND screen.content <> invalid
    executeVodDetailSuccessCallback(screen.content, screen.playbackSource, screen.episodes)
  end if
End Function


' Plays VOD content using playback parameters from the detail screen
' Retrieves playbackSource and episodes from the screen, then calls playSelectedVodContent
' @param content - Content node to play
Function playVodContentFromDetailScreen(content) as Void
  tubiLog("VodDetailScreenHelpers.playVodContentFromDetailScreen")
  if content = invalid return

  screen = getDetailScreenFromStackWithId(m.constants.ui.screenIds.vodDetailScreen, content.id)
  if screen <> invalid
    isComingSoon = isComingSoonContent(content)
    if isComingSoon = false
      playSelectedVodContent(content, screen.playbackSource, screen.episodes)
    end if
  end if
End Function


' Get analytics page oneof from tracking page info
' @trackingPageInfo: object, the page info for analytics
' @returns: object, the page oneof for analytics, or empty object if invalid
Function getAnalyticsPageOneof(trackingPageInfo) as Object
  tubiLog("VodDetailScreenHelpers.getAnalyticsPageOneof")
  pageOneof = {}
  if isAA(trackingPageInfo)
    pageOneof = m.Tracking.getAnalyticsPage(trackingPageInfo.pageType, trackingPageInfo.pageValues)
  end if
  return pageOneof
End Function


' Get content ID values for analytics (series_id or video_id)
' @content: roSGNode, the content node
' @returns: object, associative array with series_id or video_id
Function getContentIdForAnalytics(content) as Object
  tubiLog("VodDetailScreenHelpers.getContentIdForAnalytics")
  contentIdValues = {}

  if content <> invalid AND content.id <> invalid
    if content.type = m.constants.ui.contentTypes.series
      seriesId = content.id
      if seriesId.startsWith("0")
        seriesId = Mid(seriesId, 2)
      end if
      contentIdValues.series_id = seriesId.toInt()
    else
      contentIdValues.video_id = content.id.toInt()
    end if
  end if

  return contentIdValues
End Function


' Send bookmark analytics with content user context
' @content: roSGNode, the content that was bookmarked/unbookmarked
' @operation: string, the bookmark operation (ADD_TO_QUEUE or REMOVE_FROM_QUEUE)
' @trackingPageInfo: object, the page info for analytics
Function sendVodDetailBookmarkAnalytics(content, operation, trackingPageInfo) as Void
  tubiLog("VodDetailScreenHelpers.sendVodDetailBookmarkAnalytics")
  bookmarkAnalyticsEvent = {
    contentOneof: getContentIdForAnalytics(content)
    op: operation
    component: {}
    pageOneof: getAnalyticsPageOneof(trackingPageInfo)
  }

  ' Append content user context
  isAdultParentalLevel = checkIfUserIsAdultByParentalRatingAndBirthday()
  appendContentUserContextValues(bookmarkAnalyticsEvent, content, isAdultParentalLevel)

  m.trackingLoggingTask.trackEvent = {
    type: "bookmark"
    values: bookmarkAnalyticsEvent
  }
End Function


' Send like/dislike analytics with content user context
' @content: roSGNode, the content that was liked/disliked
' @trackingPageInfo: object, the page info for analytics
' @eventType: string, the event type (LIKE, DISLIKE, UNDO_LIKE, UNDO_DISLIKE)
Function sendVodDetailLikeSelectAnalytics(content, trackingPageInfo, eventType) as Void
  tubiLog("VodDetailScreenHelpers.sendVodDetailLikeSelectAnalytics")
  componentValues = getContentIdForAnalytics(content)
  targetOneof = m.Tracking.getAnalyticsComponent("content", componentValues)
  targetOneof.content.user_interaction = eventType

  explicitFeedbackEvent = {
    targetOneof: targetOneof
    pageOneof: getAnalyticsPageOneof(trackingPageInfo)
  }

  ' Append content user context
  isAdultParentalLevel = checkIfUserIsAdultByParentalRatingAndBirthday()
  appendContentUserContextValues(explicitFeedbackEvent, content, isAdultParentalLevel)

  m.trackingLoggingTask.trackEvent = {
    type: "explicit_feedback"
    values: explicitFeedbackEvent
  }
End Function


' Removes content from viewing history
' Shows disabled feature toast on major event days, otherwise sends delete history request
' @param content - Content node to remove from history
Function removeHistoryFromVodDetailScreen(content)
  tubiLog("VodDetailScreenHelpers.removeHistoryFromVodDetailScreen")
  history = getHistory(content.id)

  if history <> invalid
    requestInfo = m.userDeviceApi.deleteHistory(history.historyId)
    m.makeRequest({
      url: requestInfo.url
      requestType: m.constants.reqNames.deleteHistory
      options: requestInfo.options
      successCallback: onHistoryRemovedFromVodDetail
      errorCallback: onHistoryRemovedFromVodDetailError
      responseType: "boolean"
      analyticsScreenId: getLogPageScreenIdForContentType(m.constants, content.type)
    })
  end if
End Function


' Success callback for remove history request
' Updates local history cache and refreshes button list on detail screen
' @param response - API response containing content payload
Function onHistoryRemovedFromVodDetail(status) as Void
  tubiLog("VodDetailScreenHelpers.onHistoryRemovedFromVodDetail")
  if status
    ' Update local history cache
    handleHistoryChange()

    screen = getDetailScreenFromStackWithId(m.constants.ui.screenIds.vodDetailScreen)
    if screen <> invalid AND screen.id = m.constants.ui.screenIds.vodDetailScreen AND screen.content <> invalid
      removeHistoryLocally(screen.content.id)
      screen.shouldRefreshButtonList = true
    end if
  end if
End Function


' Error callback for remove history request failure
' Shows appropriate error message
' @param response - Error response from API
Function onHistoryRemovedFromVodDetailError(response) as Void
  tubiLog("VodDetailScreenHelpers.onHistoryRemovedFromVodDetailError")
  handleVodDetailButtonError(response, "REMOVE_FROM_HISTORY", "screenDetails_error_noHistory_description", m.constants.errors.subtypes.removeHistoryError)
End Function


' Generic error handler for VOD detail screen button operations
' @param response - The error response from the API
' @param componentName - The analytics component name (e.g., "REMOVE_FROM_HISTORY", "ADD_TO_MY_LIST")
' @param translationKey - The translation key for the error message
' @param errorSubtype - The error subtype from constants (e.g., m.constants.errors.subtypes.removeHistoryError)
Function handleVodDetailButtonError(response, componentName, translationKey, errorSubtype) as Void
  tubiLog("VodDetailScreenHelpers.handleVodDetailButtonError")
  code = ""
  if response <> invalid AND response.code <> invalid
    code = response.code
  end if

  message = getTranslation(translationKey)

  ' Set up the error modal dialog
  errorCode = getUserFacingErrorCode(m.constants.errors.context.videoDetailScreen, errorSubtype, code)

  dialogEvent = {
    component_name: componentName
    error_code: errorCode
  }

  modalInfo = {
    message: getErrorMessage(message, errorCode)
    openTrackEvent: dialogEvent
    trackingTask: m.trackingLoggingTask
  }

  showErrorModal(modalInfo, invalid, [])
End Function



' Handles side navigation open/close request from VOD detail screen
' Shows side navigation and triggers open animation if requested
' @param msg - roSGNodeEvent containing boolean indicating whether to open side nav
Function onOpenSideNavChange(msg)
  tubiLog("VodDetailScreenHelpers.onOpenSideNavChange")
  shouldOpenSideNav = msg.getData()
  m.SideNav.visible = shouldOpenSideNav
  if shouldOpenSideNav = true
    toggleScreenEnabledAndTrackSideNavEvent(false, "on", true)
    openSideNav()
  end if
End Function


' Refreshes VOD detail screen after playback ends
' Exits video player, updates history for logged-in users, and refreshes the detail screen
' Handles different scenarios: same content, series episode progression, or new content
' @param shouldSendAnalyticsEvent - Boolean indicating whether to send analytics on screen pop
' @param reason - String reason for exiting playback (for analytics)
Function refreshVodDetailScreenAfterPlayback(shouldSendAnalyticsEvent, reason) as Void
  tubiLog("VodDetailScreenHelpers.refreshVodDetailScreenAfterPlayback")
  ' remove the video player screen to reveal the details screen (or episodes list screen)
  videoPlayer = getCurrentScreen()
  videoContent = invalid
  isTrailer = false
  if videoPlayer <> invalid AND videoPlayer.id = m.constants.ui.screenIds.videoPlayerScreen
    stopVideoContent(videoPlayer)
    videoPlayer.exitReason = reason
    videoPlayer.exitPlayer = true
    videoContent = videoPlayer.content

    if videoContent <> invalid AND videoContent.isTrailer = true
      isTrailer = true
    end if

    if isLoggedInUser() = true AND isTrailer = false AND videoContent <> invalid
      historyPosition = round(videoPlayer.position)
      if historyPosition > m.constants.player.historyFrequency1Min
        updateHistoryLocally(videoContent, historyPosition)
        updateHistoryAndHandleResponse(videoContent, historyPosition)
        updateRokuContinueWatchingInfo(videoContent, historyPosition)
      else if videoContent.parentType = m.constants.ui.contentTypes.series AND videoContent.parentId <> invalid
        history = getHistory(videoContent.parentId)
        if history <> invalid AND history.currentEpisodeId <> videoContent.id
          updateHistoryLocally(videoContent, 0)
        end if
      end if
    end if
  end if
  popScreen(shouldSendAnalyticsEvent, shouldSendAnalyticsEvent)
  screen = getDetailScreenFromStackWithId(m.constants.ui.screenIds.vodDetailScreen)
  if screen <> invalid AND screen.content <> invalid AND videoContent <> invalid AND videoPlayer <> invalid AND isTrailer = false
    if screen.content.id = videoContent.id
      screen.shouldRefreshButtonList = true
    else if videoContent.parentType = m.constants.ui.contentTypes.series AND screen.content.id = videoContent.parentId
      screen.shouldRefreshScreen = true
    else if videoContent.type = m.constants.ui.contentTypes.video
      showVodDetailScreen(videoContent, videoPlayer.playbackSource)
      removeScreenFromStack(screen)
    end if

    if isAA(screen.playbackSource) = true AND screen.playbackSource.srcForAds = "deeplink"
      screen.focusRelatedContent = true
    end if
  end if
End Function


' Debounced callback for fetching related content
' Fires after a delay to avoid competing with primary content API calls
Function onRelatedContentDebounceTimerFired()
  screen = getDetailScreenFromStackWithId(m.constants.ui.screenIds.vodDetailScreen)
  if screen <> invalid AND screen.content <> invalid AND screen.relatedContent = invalid
    getYouMayAlsoLikeContent(screen.content)
  end if
End Function


' Fetches "You May Also Like" related content for a given content item
' Makes API request to get recommended content and updates the detail screen on success
' @param content - Content node to get related content for
' @param limit - Optional limit for number of related items (default: 0 for no limit)
Function getYouMayAlsoLikeContent(content, limit = 0)
  tubiLog("VodDetailScreenHelpers.getYouMayAlsoLikeContent")
  if content <> invalid
    info = m.cmsApi.createRelatedContentReqInfo(content.id, shouldKidsModeBeSentToServer(), limit)
    m.makeRequest({
      url: info.url
      requestType: m.constants.reqNames.getRelatedContent
      options: info.options
      successCallback: onGetRelatedContentSuccess
      responseType: "node"
      silenceCallbackWarnings: true
      contentId: content.id
      isSignedInUser: isLoggedInUser()
      analyticsScreenId: getLogPageScreenIdForContentType(m.constants, content.type)
    })
  end if
End Function


Function onVodDetailShouldPauseVideoPreviewChange(msg)
  tubiLog("VodDetailScreenHelpers.onVodDetailShouldPauseVideoPreviewChange")
  shouldPause = msg.getData()

  if shouldPause = true
    pauseVideoPreview()
  else
    resumeVideoPreview()
  end if
End Function


' ============================================================================
' Season List API Fallback / Content API Approach
'
' The following functions fetch the full series content via
' getSingleContentFromServer and reconstruct the seasonList, episode map,
' and season selector from the content API response.
'
' Used in two scenarios:
' 1. Fallback when getSeasonList API fails (onGetSeasonListError)
' 2. Default approach when roku_content_details_v5.variant = "performance_enhanced",
'    replacing the Season List API + Episodes API flow with a single call
'
' Flow: getSingleContentFromServer
'       -> onGetSeasonListFallbackSuccess / onGetSeasonListFallbackError
' ============================================================================


' Success callback for content API fallback when season list request fails
' Builds seasonList from content children, determines the correct season via
' deeplink or history, and sets screen.episodes to the resolved season node
' @param content - Content node returned from content API with season/episode children
Function onGetSeasonListFallbackSuccess(content)
  tubiLog("VodDetailScreenHelpers.onGetSeasonListFallbackSuccess")
  if content <> invalid
    screen = getDetailScreenFromStackWithId(m.constants.ui.screenIds.vodDetailScreen, content.id)
    if screen <> invalid AND screen.content <> invalid
      content.sotInfo = screen.content.sotInfo
      applyVodDetailContentSotSignalsPerDetailScreenExperiment(content)
      screen.content = content

      seasonData = buildSeasonListFromContent(content)
      if seasonData <> invalid
        screen.seasonList = seasonData
        seasonNum = resolveSeasonNum(content.id, seasonData)

        if seasonNum <> invalid
          screen.defaultSelectedSeason = seasonNum

          firstSeasonEpisodes = buildSeasonEpisodesNode(content, seasonNum, seasonData.seasonChildIndexMap)
          if firstSeasonEpisodes <> invalid
            screen.episodes = firstSeasonEpisodes
          end if
        end if
      end if

      screen.contentUpdated = true
      screen.wasContentFetchCompleted = true
      updateVodDetailBackground(screen.content)
      executeVodDetailSuccessCallback(screen.content, screen.playbackSource, screen.episodes)
    end if
  end if
  showHideSpinner(false)
End Function


' Error callback when the content API fallback also fails
' Marks fetch as complete and hides spinner so the screen is not left loading
' @param error - Error response from API
Function onGetSeasonListFallbackError(error)
  tubiLog("VodDetailScreenHelpers.onGetSeasonListFallbackError: " + formatJson(error))
  screen = getDetailScreenFromStackWithId(m.constants.ui.screenIds.vodDetailScreen)
  if screen <> invalid
    screen.wasContentFetchCompleted = true
  end if
  showHideSpinner(false)
End Function


' Builds a seasonList structure from the content API response
' Uses seasonChild.id for the season number (strip "0" prefix added by translateRecursive)
' and episode.episodeNumber (mapped from episode_number in the content API response)
' @param content - Series content node with season children from content API
' @return AA with seriesId, seasons, episodeSeasonMap, seasonSelectorContent, seasonChildIndexMap
Function buildSeasonListFromContent(content) as Object
  if content = invalid OR content.getChildCount() = 0 then return invalid

  seasonLabel = getTranslation("screenDetails_season_label")
  seasons = {}
  episodeSeasonMap = {}
  seasonSelectorContent = CreateObject("roSGNode", "ContentNode")
  seasonNumbers = []
  seasonChildIndexMap = {}

  for i = 0 to content.getChildCount() - 1
    seasonChild = content.getChild(i)

    ' Season nodes get a "0" prefix in translateRecursive, strip it to get the actual season number
    seasonNum = seasonChild.id.mid(1)
    if seasonNum = "" then seasonNum = (i + 1).toStr()

    episodes = []

    episodeChildren = seasonChild.getChildren(-1, 0)
    epIndex = 1
    for each episode in episodeChildren
      if isNonEmptyString(episode.id)
        epNum = episode.episodeNumber
        if epNum = 0 then epNum = epIndex

        episodes.push({
          id: episode.id
          num: epNum
        })
        episodeSeasonMap[episode.id.toStr()] = {
          seasonNum: seasonNum
          episodeNum: epNum
        }
      end if
      epIndex = epIndex + 1
    end for

    seasonChildIndexMap[seasonNum] = i

    seasonNumbers.push({
      id: "season_" + seasonNum
      title: seasonLabel.replace("{seasonNumber}", seasonNum)
      seasonNumber: seasonNum
    })

    seasons[seasonNum] = episodes
  end for

  seasonSelectorContent.update({
    children: [{
      type: "ContentNode"
      children: seasonNumbers
    }]
  }, true)

  return {
    seriesId: content.id
    seasons: seasons
    episodeSeasonMap: episodeSeasonMap
    seasonSelectorContent: seasonSelectorContent
    seasonChildIndexMap: seasonChildIndexMap
  }
End Function


' Builds a season episodes ContentNode for a specific season from the content API response
' Uses seasonChildIndexMap to find the correct season child by actual season number
' @param content - Series content node with season children
' @param seasonNum - Season number string (actual, not index-based)
' @param seasonChildIndexMap - AA mapping season number to child index
' @return ContentNode with titleSeason set and episode children
Function buildSeasonEpisodesNode(content, seasonNum, seasonChildIndexMap) as Object
  if seasonChildIndexMap = invalid OR seasonChildIndexMap[seasonNum] = invalid then return invalid

  seasonIndex = seasonChildIndexMap[seasonNum]
  if seasonIndex < 0 OR seasonIndex >= content.getChildCount() then return invalid

  seasonChild = content.getChild(seasonIndex)
  if seasonChild = invalid OR seasonChild.getChildCount() = 0 then return invalid

  seasonNode = CreateObject("roSGNode", "ContentNode")
  seasonNode.id = content.id
  seasonNode.titleSeason = seasonNum
  seasonNode.appendChildren(seasonChild.getChildren(-1, 0))

  return seasonNode
End Function


Function applyVodDetailContentSotSignalsPerDetailScreenExperiment(content, sendExposureEvent = false) as Void
  if content <> invalid
    sotInfo = content.sotInfo

    if isAA(sotInfo) = true
      sotMetaDataTopLabels = sotInfo.sotMetaDataTopLabels
      sotMetaData = sotInfo.sotMetaData
      sotMarkers = sotInfo.sotMarkers
      statsigSendEvent = (sendExposureEvent = true AND (isNonEmptyArray(sotMetaDataTopLabels) = true OR isNonEmptyArray(sotMetaData) = true OR isAA(sotMarkers) = true))

      if getStatsigExperimentResource("roku_sot_reverse_ui_test_detail_screen", "roku_sot_reverse_ui_test_detail_screen_v1", statsigSendEvent).enabled = true
        content.sotInfo = invalid
      end if
    end if
  end if
End Function
