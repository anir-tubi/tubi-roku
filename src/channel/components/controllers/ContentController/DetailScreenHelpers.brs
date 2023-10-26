
'''''''''''''''''''''
' showDetailScreen
'
' @content: roSGNode, a content node for a single pieces of content, might be a video or top level series
' @sendTrackingOnResponse: boolean, set to true if the content needs to be fetched and NavigateToPageEvent and
'                                   PlayProgressEvent analytics should be sent after fetching info from the backend.
' @successCb: roFunction, a callback to run upon successful fetching of single content metadata
' @errorCb: roFunction, a callback to run upon error while fetching of single content metadata
' @playbackSource: associative Array, format : srcForAnalytic - this value is used for sending analytics;
'                                                   valid values are "automatic", "deliberate", "unknown" or "previews"
'                                               srcForAds - used for rainmaker request
'                                                    valid values are "deeplink" , "ap_auto", "ap_select", "container", "ymal", "search", "epg", "unknown"

'                                               playbackContainer - if srcForAds = container, then playbackContainer is set to the id of the container that was the source, otherwise not used.
'@pageOriginDetails: associative Array, format: pageOrigin - from which screen we landed on the detail screen
'                                                            any valid screen id is accepted
'                                               functionName - from which function we landed on the detail screen
'                                                              any valid function is accepted
''//::TODO:: Remove pageOrigin once we fixed sending invalid component interaction events- added this for debugging purpose
Function showDetailScreen(content, sendTrackingOnResponse = true, successCb = invalid, errorCb = invalid, playbackSource = {"srcForAnalytic":"unknown","srcForAds":"unknown"}, pageOriginDetails = {})
  tubiLog("DetailScreenHelpers.showDetailScreen")
  if content <> invalid
    detailScreen = CreateObject("roSGNode", "DetailScreen")
    detailScreen.id = m.constants.ui.screenIds.detailScreen
    detailScreen.trackingLoadStartTime = Uptime(0)
    detailScreen.shouldFocusWhenPushed = m.top.fadeInContentController
    detailScreen.playbackSource = playbackSource
    detailScreen.observeFieldScoped("playSelected", "onPlay")
    detailScreen.observeFieldScoped("resumeSelected", "onResume")
    detailScreen.observeFieldScoped("likeSelected", "onLikeSelected")
    detailScreen.observeFieldScoped("dislikeSelected", "onDislikeSelected")
    detailScreen.observeFieldScoped("removeLikeSelected", "onRemoveLike")
    detailScreen.observeFieldScoped("removeDislikeSelected", "onRemoveDislike")
    detailScreen.observeFieldScoped("watchTrailerSelected", "onWatchTrailer")
    detailScreen.observeFieldScoped("episodeListSelected", "onEpisodeList")
    detailScreen.observeFieldScoped("fullDescriptionSelected", "onDescriptionSelected")
    detailScreen.observeFieldScoped("addToQueueSelected", "onAddToQueueSelected")
    detailScreen.observeFieldScoped("removeFromQueueSelected", "onRemoveFromQueueSelected")
    detailScreen.observeFieldScoped("removeFromHistorySelected", "onRemoveFromHistorySelected")
    detailScreen.observeFieldScoped("backButtonPressed", "onDetailBackPressed")
    detailScreen.observeFieldScoped("relatedContentSelected", "onRelatedContentSelected")
    detailScreen.observeFieldScoped("backgroundUriList", "onDetailBackgroundChange")
    detailScreen.observeFieldScoped("channelSelected", "onDetailScreenChannelSelected")
    detailScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
    detailScreen.observeFieldScoped("refreshContent", "onRefreshContentSignal")
    detailScreen.observeFieldScoped("refreshRelatedContent", "onRefreshRelatedContentSignal")
    detailScreen.observeFieldScoped("transportVoiceResponse", "onTransportVoiceResponse")
    detailScreen.observeFieldScoped("relatedContentToPlay", "onRelatedContentToPlay")
    detailScreen.observeFieldScoped("stopVideoPreview", "onStopVideoPreview")
    detailScreen.observeFieldScoped("signUpButtonSelected", "onSignUpButtonSelected")
    detailScreen.observeFieldScoped("componentInteractionInfo", "onComponentInteractionInfoChange")
    ' // REMOVE BELOW CODE ONCE FIFA WORLD CUP IS DONE
    detailScreen.observeFieldScoped("seeAllGamesSelected", "onSeeAllGamesSelected")
    ' Update tracking info - have to set the whole AA, can't update only a portion on the AA field
    detailScreen.trackingPageInfo = getDetailScreenAnalyticsPageInfo(content, m.constants)

    if isVideoPreviewOn() = true
      previewState = getVideoPreviewStateForThisContent(content)
      if previewState = "buffering" or previewState = "playing"
        setPageInfoForVideoPreview(detailScreen.trackingPageInfo) ' this will help to trigger analytics
      else
        previewState = getVideoPreviewState()
        if previewState <> "stopped" AND previewState <> "finished" ' this means video not stopped/finished for previous content, so we need to stop it
          stopVideoPreview()
        end if

      end if

    end if


    ' m.actionType variable is used for setting a callback function after successful a data fetch retry in the case where
    ' users select a menu button from the detail screen, but the original data fetch was unsuccessful. In this way,
    ' the action will happen automatically after the successful retry.
    m.actionType = invalid

    ' detailScreenAfterFn callback which will be triggered after fetching data from backend
    m.detailScreenAfterFn = invalid

    ' m.isScreenLoaded will be changed to true once the metadata is populated
    m.isScreenLoaded = false

    detailScreen.isVideoPreviewOn = m.pub_serverPersistentData.isVideoPreviewOn
    m.pubSub.subscribe("pub_serverPersistentData.isVideoPreviewOn", detailScreen, "isVideoPreviewOn")

    ' Setting the content on the detail screen here prior to getting a response back from server with full info,
    ' so that it may be used for analytics in the case of failing to fetch the full info from the server.
    ' We expect to overwrite this in populateDetailScreen() which occurs after the full info has been fetched from the /content API
    detailScreen.content = content

    detailScreen.pageOriginDetails = pageOriginDetails

    ' waiting to populate the details screen for series until after we fetch episode data
    if m.deepLinkContent <> invalid or content.type = m.constants.ui.contentTypes.series or (content.type = m.constants.ui.contentTypes.video AND content.seriesId <> invalid AND content.seriesId <> "")
      detailScreen.isLoading = true
    else if successCb <> invalid
      detailScreen.isLoading = true
    else
      populateDetailScreen(detailScreen, content, true)
      detailScreen.isLoading = true '//1st set to true before setting to false. For some reason setting it to false by itself does not get registered, even if he isLoading field's alwaysNotify property is set to true
      detailScreen.isLoading = false
    end if

    ' checking if the series content node exists in the content cache prior to fetching the content
    seriesContent = invalid
    if content.type = m.constants.ui.contentTypes.series
      'if roku_registration_vs_tvt_lock_rated_content exp is true then do not use the cached content because needsLogin info might not be accurate.
      if getExperimentResource("roku_registration_vs_tvt_lock_rated_content", "roku_registration_vs_tvt_lock_rated_content_v1", false).enabled <> true
        seriesContent = getFromContentCache(content.id)
      end if
    end if

    ' don't send tracking in case of series until we resolve series episode and send tracking if we already populate the detail screen to avoid wrong order of events
    if sendTrackingOnResponse = true
      if m.isScreenLoaded = true OR seriesContent <> invalid
        pushScreen(detailScreen, true, true)
      else
        pushScreen(detailScreen, true, false)
      end if
    else
      pushScreen(detailScreen, false, false)
    end if

    ' determine the appropriate fetch callbacks based on the passed in parameters
    successCallback = onSingleContentResponseWithTracking
    errorCallback = onSingleContentErrorWithTracking
    if sendTrackingOnResponse = false OR seriesContent <> invalid OR m.isScreenLoaded = true
      successCallback = onSingleContentResponseWithoutTracking
      errorCallback = onSingleContentErrorWithoutTracking
    end if

    'NOTE: SuccessCb and ErrorCb should handle analytics tracking.
    if successCb <> invalid
      successCallback = successCb
    end if

    if errorCb <> invalid
      errorCallback = errorCb
    end if

    if content.type = m.constants.ui.contentTypes.series
      if seriesContent <> invalid
        'we already have the series content in the cache and don't need to fetch it, so we can just call the successCallback
        successCallback(seriesContent)
      else
        getSingleContentFromServer(content, successCallback, errorCallback)
      end if

    else
      getSingleContentFromServer(content, successCallback, errorCallback)
    end if

    getRelatedContent(content)
  else
    ' TODO: Refer to logs to determine if it's necessary to show a modal in this instance informing the user to press the back
    ' back button. We shouldn't end up with an invalid content, but as of 11/25/18 there are crash logs
    ' that indicate it might be possible that getDetailScreenContent() as called by ContentController.returnToDetailScreenFromVideo()
    ' may return invalid, which may get passed to this function as the content argument.
    message = "DetailScreenHelpers.showDetailScreen, content is invalid"
    tubiLog(message, "warn", "clientWarn", "showdetailscreen-invalid-content")
  end if
End Function


' @screen: roSGNode, a node with subtype BaseScreen
' @returns: boolean, true if the passed in parameter is a detail screen, false otherwise
Function isDetailScreen(screen)
  return (type(screen) = "roSGNode" AND screen.isSubType("DetailScreen") = true)
End Function


Function onDetailBackgroundChange(msg)
  tubiLog("DetailScreenHelpers.onDetailBackgroundChange")
  detailScreen = msg.getRoSGNode()
  if detailScreen.isInFocusChain()
    if isVideoPreviewOn() = true
      previewState = getVideoPreviewState()
      if previewState <> "playing"
        m.backgroundGroup.backgroundInfo = {
          type: m.constants.ui.backgroundTypes.topright
          uriList: detailScreen.backgroundUriList
        }
      end if
    else
      m.backgroundGroup.backgroundInfo = {
        type: m.constants.ui.backgroundTypes.topright
        uriList: detailScreen.backgroundUriList
      }
    end if
  end if
End Function


Function onDetailScreenChannelSelected(msg)
  detailScreen = msg.getRoSGNode()
  if detailScreen.content <> invalid
    channelNode = CreateObject("roSGNode", "CategoryContentNode")
    channelNode.id = detailScreen.content.channelId
    channelNode.type = m.constants.ui.contentTypes.channel

    ' Set the tracking component of the item that was selected so it can be accessed as part of the navigateToPage event
    detailScreen.trackingComponentInfo = {
      componentType: "detail_menu_component" 'doesn't actually exist in protos currently
      componentValues: {}
    }

    showCategoryDetailsScreen(channelNode)
  end if
End Function


'detail screen has told us that the content or related content is out of cache window, so refresh
Function onRefreshContentSignal(msg)
  detailScreen = msg.getRoSGNode()
  refreshDetailScreenContent(detailScreen)
End Function


Function refreshDetailScreenContent(detailScreen)
  getSingleContentFromServer(detailScreen.content, onSingleContentResponseWithoutTracking, onSingleContentErrorWithoutTracking)
End Function


'when the content should be refreshed, make getRelatedContent to display the YMAL in detail screen
Function onRefreshRelatedContentSignal(msg)
  detailScreen = msg.getRoSGNode()
  detailScreen.showRelatedContent = false
  getRelatedContent(detailScreen.content)
End Function


'''''''''''''''''''''
' populateDetailScreen
'
'Populates the detail screen's state from a content node
'@detailScreen, roSGNode, a DetailScreen component to be populated
'@content: tubiContentNode, the content of the screen
'@shouldResetButtonIndex: boolean, helps to reset the focus index of menu items
'@nSavedPosition: integer, The number representing the resume point of the video
'@pageOriginDetails: AssocArray, From which screen and which function we populate on the detail screen
''//::TODO:: Remove pageOrigin once we fixed sending invalid component interaction events- added this for debugging purpose
Function populateDetailScreen(detailScreen, content, shouldResetButtonIndex = false, nSavedPosition = -1, pageOriginDetails = {})
  tubiLog("DetailScreenHelpers.populateDetailScreen")
  'initialize default background - will be overwritten later in most cases
  backgroundUriList = [m.defaultBackgroundUri]

  if isDetailScreen(detailScreen) = true AND type(content) = "roSGNode"
    'hide the spinner
    detailScreen.isLoading = false

    ' don't show related content if the user is in any of the kids modes
    detailScreen.showRelated = not isKidsUIOn()

    ' don't allow add to/remove from my list if the user is age gated
    if m.uiMode = m.constants.ui.modes.kidsAgeGate
      detailScreen.disableBookmarks = true
    end if

    'update detail screen state via the input interface
    detailScreen.selectedContentType = content.type
    hasVideoresources = content.hasVideoresources
    airDatetime = content.airDatetime
    info = getAvailabilityTypeBadgeAndMatchTimeValues(airDatetime, hasVideoresources)
    matchTime = info.matchTime
    badgeText = info.badgeText
    availabilityType = info.availabilityType
    detailScreen.availabilityType = availabilityType

    detailScreen.pageOriginDetails = pageOriginDetails

    detailScreen.hasTrailer = (content.hasTrailer = true)

    bookmark = getBookmark(content.id)
    history = getHistory(content.id)
    isHistory = (history <> invalid)
    like = getLike(content.id)
    isSignedInUser = isLoggedInUser()

    if isSignedInUser = false AND history <> invalid
      '//if user is signed out but has history of current item, make sure it has been less than guest user resume limit,
      '//   because beyond that time we are restricted legally from showing data of signed out users.

      if isGreaterThanGuestResumePeriod(history) = true
        history = invalid
      else
        '//Listen to and start the timer since a guest user has content with history
        m.resumeAllowedTimer.unobserveFieldScoped("fire")
        m.resumeAllowedTimer.observeFieldScoped("fire", "onResumeAllowedTimerFired")
        if m.resumeAllowedTimer.control <> "start"
          '//There may be multiple detail screens in the stack so the timer may already be started
          m.resumeAllowedTimer.control = "start"
        end if
      end if
    end if

    episode = getEpisodeContent(content)
    episodeHistory = invalid

    lineOneData = {}
    lineTwoData = {}

    if content.type = m.constants.ui.contentTypes.series
      detailScreen.mode = m.constants.ui.infoPanelModes.series
      if episode <> invalid
        if history <> invalid
          '//if there is no history, then there is no episode history either
          episodeHistory = getHistory(episode.id)
        end if

        detailScreen.episodeTitle = episode.title
      end if

      lineOneData.type = m.constants.ui.contentTypes.series
      lineOneData.seasons = content.totalCount
      lineTwoData.genres = content.genres
      detailScreen.isSeries = true
    else if content.type = m.constants.ui.contentTypes.sportsEvent
      detailScreen.mode = m.constants.ui.infoPanelModes.sportsEvent
      lineOneData.badgeText = badgeText
      lineOneData.hoursOfAiring = matchTime
      lineTwoData.roundGroupInfo = content.roundGroupInfo
    else
      detailScreen.mode = m.constants.ui.infoPanelModes.movie
      lineTwoData.genres = content.genres
    end if

    if isKidsUIOn() = true
      detailScreen.isInKidsMode = true
    else
      detailScreen.isInKidsMode = false

      ' send the exposure event only if not in kids, since the like/dislike button is not shown in kids
      getExperimentResource("roku_notforme_dislike", "roku_notforme_dislike_v2")
    end if

    if episode <> invalid
      stateSource = episode
    else
      stateSource = content
    end if

    lineOneData.length = stateSource.length
    lineOneData.rating = stateSource.rating

    rating = UCase(stateSource.rating)
    if (rating = "R" OR rating = "TV-MA" OR rating = "TV-14" OR rating = "NC-17" OR rating = "NR") AND m.constants.deviceinfo.countrycode = "US"
      getExperimentResource("roku_registration_vs_tvt_lock_rated_content", "roku_registration_vs_tvt_lock_rated_content_v1")
    end if

    lineOneData.releaseDate = content.releaseDate
    lineOneData.descriptorCode = content.descriptorCode
    lineOneData.partnerLogoUri = content.inlineLogoUri

    if content.highestRendition = m.constants.serverValues.tensorVideoRenditions.fourK
      lineOneData.has4k = true
    end if

    if episode <> invalid AND (episode.hasSubtitles = true OR m._.empty(episode.subtitleTracks) = false)
      lineOneData.hasCC = true
    else if content <> invalid AND (content.type = m.constants.ui.contentTypes.video OR content.type = m.constants.ui.contentTypes.sportsEvent) AND (content.hasSubtitles = true OR m._.empty(content.subtitleTracks) = false)
      lineOneData.hasCC = true
    else
      lineOneData.hasCC = false
    end if

    if content.availabilityEnds <> invalid AND content.availabilityEnds <> ""
      lineOneData.availabilityEnds = content.availabilityEnds
    else if episode <> invalid AND episode.availabilityEnds <> invalid
      lineOneData.availabilityEnds = episode.availabilityEnds
    end if

    detailScreen.title = content.title
    detailScreen.description = stateSource.description
    detailScreen.lineOneData = lineOneData
    detailScreen.lineTwoData = lineTwoData
    detailScreen.directors = stateSource.directors
    detailScreen.starring = stateSource.actors
    detailScreen.reminderIsSet = (availabilityType = "upcoming" AND bookmark <> invalid)
    detailScreen.needsLoginHint = (content.needsLogin = true AND isLoggedInUser() = false) ' because we do not repull the content after signed in.
    detailScreen.infoPanelVisible = true

    setIsBookmark(detailScreen, (bookmark <> invalid))
    sLikedState = ""
    if like <> invalid
      sLikedState = like.state
    end if

    detailScreen.likeDislikeState = sLikedState

    '//right now in kids mode, there are no channels showing up, so hardcode it so the channel's button doesn't show
    detailScreen.isChannelItem = (content.channelId <> invalid AND content.channelId <> "" AND isKidsUIOn() = false)
    detailScreen.stringChannelButton = getTranslation("screenDetails_button_gotoChannel", {channel: content.channelName})
    detailScreen.length = stateSource.length 'needed to compute the resume bar on the resume button

    nResumePoint = 0
    if content.type = m.constants.ui.contentTypes.series AND episodeHistory <> invalid AND episodeHistory.nowPos > 0
      nResumePoint = episodeHistory.nowPos
    else if history <> invalid AND history.nowPos > 0 AND (content.type = m.constants.ui.contentTypes.sportsEvent OR content.type = m.constants.ui.contentTypes.video)
      nResumePoint = history.nowPos
    end if

    if nResumePoint < m.constants.player.historyFrequency1Min
      '//make sure the resume point is at least the client side constant minimum
      nResumePoint = 0
    end if

    if nSavedPosition >= m.constants.player.historyFrequency1Min AND isSignedInUser = true
      '//nSavedPosition is only used for signed in users and ignored for guest users.
      '//If the saved position is passed as greater than the constant historyFrequency, then use that number instead.
      '//This parameter was put in place to display the updated resume point before having to wait to backend to confirm that the resume point is correct
      nResumePoint = nSavedPosition
    end if

    setIsHistory(detailScreen, isHistory)

    detailScreen.resumePoint = nResumePoint

    'tell the detail screen/info panel to vertically center the info panel
    detailScreen.calculateInfoHeight = true

    if detailScreen.relatedContent = invalid
      '//Only change the related content if it hasn't already been loaded. If we try to reload the related content, then the thumbnails may not display due to (probably) a firmware issue
      detailScreen.relatedContent = content.relatedContent
    end if

    'update the background images for the detail screen
    if content.backgrounds <> invalid AND content.backgrounds.count() > 0
      backgroundUriList = content.backgrounds
    end if

    detailScreen.backgroundUriList = backgroundUriList

    ' update button strings based on various state, ie. if user is logged in, content is locked, etc.
    if isNonEmptyString(availabilityType) = true AND availabilityType = m.constants.ui.contentTimings.upcoming
      if isSignedInUser = false
        detailScreen.stringQueueButton = getTranslation("screenDetails_button_sign_in_to_set_reminder")
      else
        detailScreen.stringQueueButton = getTranslation("screenDetails_button_set_reminder")
      end if

      detailScreen.stringNoQueueButton = getTranslation("screenDetails_button_remove_reminder")
    end if

    if isSignedInUser = false
      if content.needsLogin = true
        detailScreen.stringPlayButton = getTranslation("registration_signIn_to_play_button") + ";" + getTranslation("registration_signup_button_free")
        detailScreen.removeSignupButton = true 'No need to have signIn to Play button and signUp to save button together.
      else
        detailScreen.stringSignUpButton = getTranslation("registration_signup_button") + ";" + getTranslation("registration_signup_button_free")
      end if
    end if

    'update tracking info - have to set the whole AA, can't update only a portion on the AA field.
    'it is necessary to update trackingPageInfo here so that the correct pageInfo is stored in the case where a deeplink has an
    'episode content id, but the detail screen content will ultimately be a series content node. Updating here occurs when the
    'full content has been returned from the /contents API.
    detailScreen.trackingPageInfo = getDetailScreenAnalyticsPageInfo(content, m.constants)
    detailScreen.content = content

    if shouldResetButtonIndex = true
      detailScreen.jumpToItem = 0
    end if
  end if

  m.isScreenLoaded = true
End Function


'@content: roSGNode, a TubiContentNode
'@successCallback: roFunction, a callback to be run when the response is successfully returned from the backend
'@errorCallback: roFunction, a callback to be run when an error occurs while fetching the content from the backend
Function getSingleContentFromServer(content, successCallback, errorCallback)
  tubiLog("DetailScreenHelpers.getSingleContentFromServer")
  if content <> invalid
    singleRequestInfo = m.cmsApi.createSingleContentReqInfo(content.id, true, shouldKidsModeBeSentToServer())
    m.makeRequest({
      url: singleRequestInfo.url
      requestType: m.constants.reqNames.getSingleContent
      options: singleRequestInfo.options
      successCallback: successCallback
      errorCallback: errorCallback
      responseType: "node"
      isSignedInUser: isLoggedInUser()
    })
  end if
End Function


'wrapper around getSingleContentFromServer for use as a callback in the error modal
'@params: 4 index array containing params that should be passed to getSingleContentFromServer()
Function getSingleContentFromServerRetry(params)
  if type(params) = "roArray" AND params.count() = 4
    if type(params[3]) = "roSGNode" AND params[3].subtype() = "DetailScreen"
      params[3].isLoading = true
    end if

    getSingleContentFromServer(params[0], params[1], params[2])
  end if
End Function


Function onSingleContentResponseWithTracking(singleContent)
  setInContentCache(singleContent, m.constants.ui.screenIds.detailScreen) ' adding the series content node into the content cache
  handleSingleContentResponse(singleContent, true)
End Function


Function onSingleContentResponseWithoutTracking(singleContent)
  setInContentCache(singleContent, m.constants.ui.screenIds.detailScreen) ' adding the series content node into the content cache.
  handleSingleContentResponse(singleContent, false)
End Function


' @refreshedContent: ContentNode, a contentNode for a single piece of content, can be video or series
' @sendTracking: boolean, indicates if NavigateToPage and PageLoad events should be triggered from this function
Function handleSingleContentResponse(refreshedContent, sendTracking = true) As Void
  tubiLog("DetailScreenHelpers.handleSingleContentResponse")
  detailScreen = getTopDetailScreenFromStack()

  if detailScreen <> invalid AND detailScreen.content.id = refreshedContent.id
    detailScreen.contentFetchError = false

    ' Replace the top of the detail screen content stack with the refreshed content
    oldContent = detailScreen.content

    history = getHistory(refreshedContent.id)
    ' Find a default episode to land on, in case no specific episode requested.
    ' NOTE: If the series is a daily, recurring series then we always want to go to the most recent
    if refreshedContent.type = m.constants.ui.contentTypes.series AND refreshedContent.currentEpisodeId = "" AND refreshedContent.isRecurring = false
      if oldContent <> invalid AND oldContent.type = m.constants.ui.contentTypes.video
        ' a specific episode was requested by id
        refreshedContent.currentEpisodeId = oldContent.id
      else
        ' first see if there was a specific episode id we wanted
        if history <> invalid
          refreshedContent.currentEpisodeId = history.currentEpisodeId
        else
          refreshedContent.currentEpisodeId = ""
        end if

      end if

    else if refreshedContent.type = m.constants.ui.contentTypes.video AND refreshedContent.seriesId <> invalid AND refreshedContent.seriesId <> ""
      ' Case here of having an episode outside of a series (probably from autoplay)
      emptySeriesNode = CreateObject("roSGNode", "TubiContentNode")
      emptySeriesNode.type = m.constants.ui.contentTypes.series
      emptySeriesNode.id = refreshedContent.seriesId

      successCallback = onSingleContentResponseWithTracking
      errorCallback = onSingleContentErrorWithTracking
      if sendTracking = false
        successCallback = onSingleContentResponseWithoutTracking
        errorCallback = onSingleContentErrorWithoutTracking
      end if

      getSingleContentFromServer(emptySeriesNode, successCallback, errorCallback)
      return
    end if

    pageOriginDetails = {
      "pageOrigin": m.constants.ui.screenIds.detailScreen
      "functionName": "handleSingleContentResponse"
    }
    populateDetailScreen(detailScreen, refreshedContent, false, -1, pageOriginDetails)

    sendDetailScreenPageLoadEvent(detailScreen, refreshedContent, sendTracking)

    afterFn = invalid
    if m.actionType <> invalid
      afterFn = m.actionType
      m.actionType = invalid
    end if

    if afterFn <> invalid
      handleDetailScreenAfterFn(detailScreen, afterFn)
    end if

  end if

End Function


'if there is any afterfun has been passed to detail page execute that function
'@detailScreen, roSGNode, a DetailScreen component to be populated
'@afterFn: callback which will be triggered after fetching data from backend
Function handleDetailScreenAfterFn(detailScreen, afterFn)
  ' making sure the app launch animation logo is completed before invoking playHelper/resumeHelper
  if m.top.fadeInContentController = true or afterFn = episodesHelper
    if afterFn <> invalid
      afterFn(detailScreen)
    end if

  else
    m.detailScreenAfterFn = afterFn
  end if
End Function

'Send pageLoad event for detail screen after content has been fetched.
'@detailScreen, roSGNode, a DetailScreen component to be populated
'@refreshedContent, roSGNode, detail content
'@sendTracking, boolean, to control whether to send Navigation and pageload events.
'                       (In case of deeplink, we insert the detail page on screenstack and we do not need to send Navigate to page or pageload event)
Function sendDetailScreenPageLoadEvent(detailScreen, refreshedContent, sendTracking = true)
  tubilog("DetailScreenHelpers.sendDetailScreenPageLoadEvent")

  if sendTracking = true
    loadTime = 0
    if refreshedContent.type = m.constants.ui.contentTypes.series
      loadTime = Int((Uptime(0) - detailScreen.trackingLoadStartTime) * 1000) 'in ms
    end if

    screenTrackingLoad(detailScreen.trackingPageInfo, loadTime)
  end if
End Function


Function onSingleContentErrorWithTracking(error)
  handleSingleContentError(error, onSingleContentResponseWithTracking, onSingleContentErrorWithTracking)
End Function


Function onSingleContentErrorWithoutTracking(error)
  handleSingleContentError(error, onSingleContentResponseWithoutTracking, onSingleContentErrorWithoutTracking)
End Function


' @onRetrySuccessCallback: roFunction, a callback to be run when the response is successfully returned from the backend on a retry
' @onRetryErrorCallback: roFunction, a callback to be run when an error occurs while fetching the content from the backend on a retry
Function handleSingleContentError(error, onRetrySuccessCallback, onRetryErrorCallback)
  tubiLog("DetailScreenHelpers.handleSingleContentError")
  detailScreen = getTopDetailScreenFromStack()
  message = ""

  if detailScreen <> invalid AND m.isScreenLoaded = false
    pageOriginDetails = {
      "pageOrigin": m.constants.ui.screenIds.detailScreen
      "functionName": "handleSingleContentError"
    }
    populateDetailScreen(detailScreen, detailScreen.content, false, -1, pageOriginDetails)
  end if

  if detailScreen <> invalid AND detailScreen.isInFocusChain() = true
    content = getDetailScreenContent(detailScreen)

    ' set up the error modal dialog
    errorCode = getUserFacingErrorCode(m.constants.errors.context.videoDetailScreen, m.constants.errors.subtypes.fetchError, error.code)
    dialogEvent = getDetailScreenDialogAnalyticEvent(content, "NETWORK_ERROR", errorCode, m.constants)

    modalInfo = {
      message: getErrorMessage(message, errorCode)
      openTrackEvent: dialogEvent
      trackingTask: m.trackingLoggingTask
    }

    getSingleContentRetryParams = [
      content
      onRetrySuccessCallback
      onRetryErrorCallback
      detailScreen
    ]

    ' Adding a check to see if backend returned 404, which means that the content id is invalid and backend could not find
    ' a matching entry. In which case showing retry button in modal will not be of any use, since retrying again will end up in the same error modal.
    ' Which will result in a endless loop of app showing user with retry again modal.
    ' Since if the content id is invalid is there no way user to recover with retry.
    if error <> invalid AND isInteger(error.code) = true AND error.code = 404
      showErrorModal(modalInfo, invalid, invalid, onCloseErrorModal)
    else
      showErrorModal(modalInfo, getSingleContentFromServerRetry, getSingleContentRetryParams)
    end if
    detailScreen.isLoading = false

    sendDetailScreenErrorAnalytics(detailScreen)
  end if

  if detailScreen <> invalid
    ' holds state info about if there was an error in retrieving the content for this page.
    ' Is used to prevent multiple navigate_to_page and page_load events if a user ties to
    ' reload content from the error modal.
    detailScreen.contentFetchError = true
  end if
End Function


Function getRelatedContent(content, callback = handleRelatedResponse)
  ' get related (You May Also Like) content along with metadata for the content
  ' (but not if in any of the kids modes, since it won't be displayed)
  if content <> invalid AND isKidsUIOn() = false
    relatedRequestInfo = m.cmsApi.createRelatedContentReqInfo(content.id, shouldKidsModeBeSentToServer())
    m.makeRequest({
      url: relatedRequestInfo.url
      requestType: m.constants.reqNames.getRelatedContent
      options: relatedRequestInfo.options
      successCallback: callback
      responseType: "node"
      silenceCallbackWarnings: true
      contentId: content.id
      isSignedInUser: isLoggedInUser()
    })
  end if
End Function


Function handleRelatedResponse(relatedContent)

  if relatedContent <> invalid
    for i = 0 to m.screenStack.getChildCount() - 1
      screen = m.screenStack.getChild(i)
      if screen.subType() = "DetailScreen" AND screen.content <> invalid AND screen.content.id = relatedContent.id

        'After AutoPlay or refresh required and when pressing back from Player to detail screen
        'related content(YMAL) thumbnails are not loading. Resetting relatedContent node fixes the issue.
        screen.relatedContent = invalid
        screen.relatedContent = relatedContent
      end if
    end for
  end if
End Function


'@episodeId: String, episode content Id
'@contentNode: Node, a TubiContentNode, expected to be used only on series content nodes
Function findEpisode2dIndex(episodeId, contentNode)
  if episodeId <> invalid
    for i = 0 to contentNode.getChildCount() - 1
      season = contentNode.getChild(i)
      for j = 0 to season.getChildCount() - 1
        episode = season.getChild(j)
        if episode.id = episodeId then
          tubiLog("Episode is [" + stri(i) + "," + stri(j) + "]")
          return [i, j]
        end if

      end for
    end for
  end if

  return [0, 0]
End Function



' @currentItemFocused: array, current episode index
' @contentNode: Node, a TubiContentNode, expected to be used only on series content nodes
'
' @returns: 2D array, [season, episode] which comes after current episode.
'   for example, if currentItemFocused = [3,2], this function will return [3,3] if second episode is not the last episode in season 3
'   or [4,0] if there is a season 4 and second episode is last episode in season 3.
Function findNextEpisode2dIndex(currentItemFocused, contentNode)
  if contentNode <> invalid AND currentItemFocused <> invalid AND currentItemFocused.count() = 2
    seasonIndex = currentItemFocused[0]
    episodeIndex = currentItemFocused[1]

    if (episodeIndex + 1) < contentNode.getChild(seasonIndex).getChildCount()
      return [seasonIndex, episodeIndex + 1]
    else if (seasonIndex + 1) < contentNode.getChildCount()
      return [seasonIndex + 1, 0]
    end if

  end if
  return [0, 0]
End Function


' @currentItemFocused: array, current episode 2D index
' @seriesContent: Node, a TubiContentNode filled with content meta data for a series.
'
' @returns: 2D array, [season, episode] representing the first episode that is not watched to completion
' which is after the episode represented by the currentItemFocused array
Function findNextEpisode(currentItemFocused, seriesContent)
  nextEpisode = [0, 0] ' initialize next episode to be first episode

  if seriesContent <> invalid AND currentItemFocused <> invalid AND currentItemFocused.count() = 2

    nextEpisode = findNextEpisode2dIndex(currentItemFocused, seriesContent)
    seasonIndex = nextEpisode[0]
    episodeIndex = nextEpisode[1]
    currentSeasonIndex = -1
    currentEpisodeIndex = -1
    historyIds = getFieldFromGlobal("historyIds") ' get the history to avoid accessing m.global every time
    if historyIds <> invalid
      for i = seasonIndex to seriesContent.getChildCount() - 1
        currentSeasonIndex = i
        season = seriesContent.getChild(i)
        for j = episodeIndex to season.getChildCount() - 1
          currentEpisodeIndex = j
          item = seriesContent.getChild(i).getChild(j)
          history = historyIds.findNode(item.id)

          if history <> invalid AND history.nowPos <> invalid AND history.nowPos <> 0
            nowPos = history.nowPos
          else
            nowPos = 0
          end if

          if item.creditCuePoints <> invalid AND item.creditCuePoints.postlude <> invalid AND nowPos < item.creditCuePoints.postlude then
            return [i, j] ' first unwatched episode next to currently watched episode
          end if

        end for
        'bs:disable-next-line LINT1005
        episodeIndex = 0 'next season, so start from beginning
      end for

      'if we ran out of all the episodes, return first episode as next episode
      seasonsTopIndex = seriesContent.getChildCount() - 1
      episodesTopIndex = seriesContent.getChild(seasonsTopIndex).getChildCount() - 1
      if currentSeasonIndex = seasonsTopIndex AND currentEpisodeIndex = episodesTopIndex then
        nextEpisode = [0, 0]
      end if

    end if
  end if

  return nextEpisode
End Function



' returns episode detail as node, if episode detail not present it returns invalid
Function getEpisodeDetail(content)
  if content <> invalid
    if content.currentEpisodeId <> invalid AND content.currentEpisodeId <> ""
      return content.findNode(content.currentEpisodeId)
    else
      season = content.getChild(0)
      if season <> invalid
        ' return a default if no match
        return season.getChild(0)
      end if

    end if
  end if

  return invalid
End Function

' Given a content node that may be a series or a video, return the appropriate video to play.
' This may just be returning the video that is passed in (in the case of a movie).
' @content: roSGNode, a movie or series content node
Function getEpisodeContent(content)
  episode = invalid

  if content <> invalid
    if content.currentEpisodeId <> invalid AND content.currentEpisodeId <> ""
      episode = content.findNode(content.currentEpisodeId)
    end if

    if episode = invalid
      season = content.getChild(0)
      if season <> invalid
        ' return a default if no match
        episode = season.getChild(0)
      end if

    end if
  end if

  if episode <> invalid
    return episode
  else
    return content
  end if

End Function


' given a content node, return invalid for movie, or the metadata for the episode to be displayed on the details screen
' @content: tubiContentNode - video or series
Function getCurrentEpisode(content)
  episode = invalid
  if content <> invalid AND content.type = m.constants.ui.contentTypes.series
    episode = getEpisodeContent(content)
  end if

  return episode
End Function


' Helper to deduce the content, video or episode, to play or resume
Function getDetailScreenContent(screen = invalid)
  if screen = invalid
    screen = getTopDetailScreenFromStack()
  end if

  if screen <> invalid AND screen.subType() = "DetailScreen" AND screen.content <> invalid
    return screen.content
  else
    return invalid
  end if
End Function


Function getTopDetailScreenFromStack()
  detailScreen = invalid
  screenStackDepth = 0
  while detailScreen = invalid
    hiddenScreen = getHiddenScreen(screenStackDepth)
    if hiddenScreen = invalid
      ' we are outside of the screen stack depth so there are no more hidden screens
      exit while
    else if hiddenScreen.id = m.constants.ui.screenIds.detailScreen
      detailScreen = hiddenScreen
    else
      screenStackDepth += 1
    end if

  end while

  return detailScreen
End Function


Function onAddToQueueSelected(msg)
  tubiLog("DetailScreenHelpers.onAddToQueueSelected")
  detailScreen = msg.getRoSGNode()
  onAddToQueue(detailScreen)
End Function


Function onAddToQueue(detailScreen, callBackAfterSignIn = invalid)
  tubiLog("DetailScreenHelpers.onAddToQueue")

  if detailScreen.getSubtype() = "DetailScreen"
    if isLoggedInUser() = false

      content = getDetailScreenContent(detailScreen)


      title = getTranslation("screenDetails_error_addQueue_title")
      dialogType = "ADD_TO_QUEUE"
      dialogSubType = "sign-in-bookmark"
      if content.type = m.constants.ui.contentTypes.series
        message = getTranslation("screenDetails_error_addQueueSeries_description")
      else if detailScreen.availabilityType = m.constants.ui.contentTimings.upcoming
        dialogType = "SIGNIN_REQUIRED"
        dialogSubType = "set_reminder"
        message = getTranslation("screenDetails_error_setReminderSports_description")
      else if detailScreen.availabilityType = m.constants.ui.contentTimings.replay
        message = getTranslation("screenDetails_error_addQueueSports_description")
      else
        message = getTranslation("screenDetails_error_addQueueMovie_description")
      end if

      dialogEvent = getDetailScreenDialogAnalyticEvent(content, dialogType, dialogSubType, m.constants)

      buttons = [getTranslation("dialog_button_continue"), getTranslation("dialog_button_cancel")]
      showSimpleInstantResumableModal(title, message, buttons, dialogEvent, m.trackingLoggingTask, addToQueueSignInSelected)
    else if detailScreen.isWaitingForServerResponse <> true
      detailScreen.stringQueueButton = getTranslation("screenDetails_button_queueNow")

      authInfo = getFieldFromGlobal("authInfo")
      userId = 0
      if authInfo <> invalid AND authInfo.userId <> invalid
        userId = authInfo.userId.toInt()
      end if

      contentType = ""
      typeOfQueue = m.constants.userQueueType.watchLater
      content = detailScreen.content
      if detailScreen.availabilityType = m.constants.ui.contentTimings.upcoming
        setComponentInteractionEventForReminder(detailScreen, true)
        typeOfQueue = m.constants.userQueueType.remindMe
      else
        typeOfQueue = m.constants.userQueueType.watchLater
      end if

      if content.type = m.constants.ui.contentTypes.video
        contentType = m.constants.uapiContentTypes.movie
      else if content <> invalid and isNonEmptyString(content.type) = true
        contentType = content.type
      end if

      addToQueueReq = m.userDeviceApi.addToQueueReqInfo(userId, detailScreen.content.id, contentType, typeOfQueue)

      callBackSuccessFunction = callBackAfterSignIn
      if callBackSuccessFunction = invalid
        callBackSuccessFunction = addToQueueSuccessResponse
      end if

      m.makeRequest({
        url: addToQueueReq.url
        requestType: m.constants.reqNames.postToQueue
        options: addToQueueReq.options
        successCallback: callBackSuccessFunction
        errorCallback: addToQueueErrorResponse
        responseType: "assocarray"
      })
      detailScreen.isWaitingForServerResponse = true

    end if

  end if
End Function


Function addToQueueSignInSelected()
  startSignIn(onQueueAfterSignIn)
End Function


'Wraps onAddToQueueSelected in the case of an error modal and a user attempting to retry adding the content to their queue
Function onAddToQueueRetry(params)
  if type(params) = "roArray" AND params.count() = 1
    onAddToQueue(params[0])
  end if
End Function


' bookmarkFailed triggered when bookmark fails for some reason
' @detailScreen: roSGNode, detail screen node
' @addBookmarkResult: assocarray, contains bookmarkId & response code
Function bookmarkFailed(detailScreen, addBookmarkResult)

  content = getDetailScreenContent(detailScreen)
  responseCode = -1234
  if addBookmarkResult <> invalid
    responseCode = addBookmarkResult.code
  end if

  ' set up the error modal dialog
  errorCode = getUserFacingErrorCode(m.constants.errors.context.videoDetailScreen, m.constants.errors.subtypes.addBookmarkError, responseCode)
  message = ""
  if detailScreen.availabilityType = m.constants.ui.contentTimings.upcoming
    dialogEvent = getDetailScreenDialogAnalyticEvent(content, "SET_REMINDER", errorCode, m.constants)

    if isLoggedInUser() = false
      detailScreen.stringQueueButton = getTranslation("screenDetails_button_sign_in_to_set_reminder")
    else
      detailScreen.stringQueueButton = getTranslation("screenDetails_button_set_reminder")
    end if

    message = getTranslation("screenDetails_error_noQueueUpcoming_description")
  else
    dialogEvent = getDetailScreenDialogAnalyticEvent(content, "ADD_TO_QUEUE", errorCode, m.constants)
    detailScreen.stringQueueButton = getTranslation("screenDetails_button_queue")
    if content.type = m.constants.ui.contentTypes.series
      message = getTranslation("screenDetails_error_queueSeries_description")
    else if content.type = m.constants.ui.contentTypes.movie
      message = getTranslation("screenDetails_error_queueMovie_description")
    else if detailScreen.availabilityType = m.constants.ui.contentTimings.replay
      message = getTranslation("screenDetails_error_noQueueReplay_description")
    end if

  end if
  title = getTranslation("error_tryAgain_title")

  modalInfo = {
    title: title
    message: getErrorMessage(message, errorCode)
    openTrackEvent: dialogEvent
    trackingTask: m.trackingLoggingTask
  }

  addToQueueRetryParams = [
    detailScreen
  ]

  showErrorModal(modalInfo, onAddToQueueRetry, addToQueueRetryParams)

End Function


''''''''''''''''''
' onBookmarkedAfterSignIn callback gets triggered when guest user completing signIn process
' while adding queue via detail screen
Function onBookmarkedAfterSignIn(response)
  detailScreen = getTopDetailScreenFromStack()
  detailScreen.isWaitingForServerResponse = false

  if response <> invalid
    bookmarkId = response.id

    if bookmarkId <> invalid
      content = getDetailScreenContent(detailScreen)
      dialogEvent = getDetailScreenDialogAnalyticEvent(content, "ADD_TO_QUEUE", "add-queue-success", m.constants)

      title = getTranslation("screenDetails_queue_content_added_to_list_description")
      if isNonEmptyString(detailScreen.title) = true
        title = detailScreen.title
      end if
      if detailScreen.availabilityType <> invalid and detailScreen.availabilityType = m.constants.ui.contentTimings.upcoming
        description = getTranslation("screenDetails_queue_added_to_reminder_list_description", {"upcomingTitle": title})
      else
        description = getTranslation("screenDetails_queue_added_to_list_description", {"contentTitle": title})
      end if

      showSimpleInstantResumableModal("Success", description, [], dialogEvent, m.trackingLoggingTask)

      ' re-fetch homescreen content when user signedIn
      homeScreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
      if homeScreen <> invalid
        fetchHomescreen(homeScreen)
      end if

      if response <> invalid AND response.parsedresponse <> invalid AND detailScreen.content.id.toInt() = response.parsedresponse.content_id
        setIsBookmark(detailScreen, true)
      end if

      sendBookmarkAnalytics(detailScreen.content, "ADD_TO_QUEUE", m.Tracking, m.trackingLoggingTask, m.constants)
      handleQueueChange()
    end if

  end if

End Function


Function isGreaterThanGuestResumePeriod(history)
  bGreaterThan = false
  if history <> invalid
    n24HoursInSeconds = 24 * 60 * 60 '//24hr * 60min/hr * 60sec/min = the period is 1 day/24 hours
    nowDate = CreateObject("roDateTime")
    nNowSeconds = nowDate.AsSeconds()
    bGreaterThan = ((history.lastSaved + n24HoursInSeconds) < nNowSeconds)
  end if

  return bGreaterThan
End Function


' Event Handler for when to check if guest user has reached the time limit to see the history of the current video.
Function onResumeAllowedTimerFired()
  if isLoggedInUser() = false
    detailScreen = invalid
    screenStackDepth = 0
    bDetailScreenExistsInStack = false

    '//Go thru the entire stack to find detailScreens
    while getHiddenScreen(screenStackDepth) <> invalid
      hiddenScreen = getHiddenScreen(screenStackDepth)
      if hiddenScreen <> invalid AND hiddenScreen.id = m.constants.ui.screenIds.detailScreen
        detailScreen = hiddenScreen
        bDetailScreenExistsInStack = true

        history = getHistory(detailScreen.content.id)

        if history <> invalid
          '//if user is signed out but has history of current item, make sure it has been less than guest user resume limit,
          '//   because beyond that time we are restricted legally from showing data of signed out users.

          if isGreaterThanGuestResumePeriod(history) = true
            '//Call populateDetailScreen() which will remove the resume button for any guest users that have content that has history over a day old
            pageOriginDetails = {
              "pageOrigin": m.constants.ui.screenIds.detailScreen
              "functionName": "onResumeAllowedTimerFired"
            }
            populateDetailScreen(detailScreen, detailScreen.content, false, -1, pageOriginDetails)
          end if

        end if
      end if
      screenStackDepth += 1
    end while

    if bDetailScreenExistsInStack = false
      '//The detail screen is no longer in the stack so no need for the timer anymore
      m.resumeAllowedTimer.unobserveFieldScoped("fire")
      m.resumeAllowedTimer.control = "stop"
    end if

  else
    '//User is signed in and is no longer a guest so cancel timer
    m.resumeAllowedTimer.unobserveFieldScoped("fire")
    m.resumeAllowedTimer.control = "stop"
  end if

End Function


Function setIsBookmark(detailScreen, isBookmark)
  'reset the value in the case that add to queue button was pressed and the button title is currently "Adding..."
  availabilityType = detailScreen.availabilityType
  if availabilityType <> invalid AND availabilityType = m.constants.ui.contentTimings.upcoming then

    if isLoggedInUser() = false
      detailScreen.stringQueueButton = getTranslation("screenDetails_button_sign_in_to_set_reminder")
    else
      detailScreen.stringQueueButton = getTranslation("screenDetails_button_set_reminder")
    end if

    detailScreen.stringNoQueueButton = getTranslation("screenDetails_button_remove_reminder")
  else
    detailScreen.stringQueueButton = getTranslation("screenDetails_button_queue")
    detailScreen.stringNoQueueButton = getTranslation("screenDetails_button_noQueue")
  end if

  detailScreen.isBookmark = isBookmark
End Function


Function setIsHistory(detailScreen, isHistory)
  'reset the value in the case that remove from history button was pressed and title is currently "Removing..."
  detailScreen.stringNoHistoryButton = getTranslation("screenDetails_button_noHistory")


  if detailScreen.content <> invalid AND detailScreen.content.needsLogin = true AND isLoggedInUser() = false
    detailScreen.stringPlayButton = getTranslation("registration_signIn_to_play_button") + ";" + getTranslation("registration_signup_button_free")
  else if isHistory = true
    detailScreen.stringPlayButton = getTranslation("screenDetails_button_startOver")
  else
    detailScreen.stringPlayButton = getTranslation("screenDetails_button_play")
  end if

  detailScreen.isHistory = isHistory
End Function


Function onRemoveFromQueueSelected(msg)
  tubiLog("DetailScreenHelpers.onRemoveFromQueueSelected")
  detailScreen = msg.getRoSGNode()
  onRemoveFromQueue(detailScreen)
End Function


Function onRemoveFromQueue(detailScreen)
  tubiLog("DetailScreenHelpers.onRemoveFromQueue")
  if detailScreen <> invalid AND detailScreen.isWaitingForServerResponse <> true
    content = detailScreen.content.clone(false)
    bookmark = m.global.bookmarkIds.findNode(content.id)
    if bookmark <> invalid
      detailScreen.stringQueueButton = getTranslation("screenDetails_button_removing")

      contentType = ""

      if content.type = m.constants.ui.contentTypes.video
        contentType = m.constants.uapiContentTypes.movie
      else if content.type = m.constants.ui.contentTypes.sportsEvent
        if detailScreen.availabilityType = m.constants.ui.contentTimings.upcoming
          setComponentInteractionEventForReminder(detailScreen, false)
        end if
        contentType = m.constants.uapiContentTypes.sportsEvent
      else
        contentType = content.type
      end if

      removeFromQueueReq = m.userDeviceApi.removeFromQueueReqInfo(bookmark.bookmarkId, content.id, contentType)

      m.makeRequest({
        url: removeFromQueueReq.url
        requestType: m.constants.reqNames.deleteFromQueue
        options: removeFromQueueReq.options
        successCallback: removeFromQueueSuccessResponse
        errorCallback: removeFromQueueErrorResponse
        responseType: "string"
      })

      detailScreen.isWaitingForServerResponse = true
    else
      tubiLog("bookmark id not found")
    end if

  end if
End Function


'Wraps onAddToQueueSelected in the case of an error modal and a user attempting to retry removing the content from their queue
Function onRemoveFromQueueRetry(params)
  if type(params) = "roArray" AND params.count() = 1
    onRemoveFromQueue(params[0])
  end if
End Function


' @param bLike: Boolean, Did the user like the video? true = liked; false = disliked
Function signInAndLike(bLike = true)
  if bLike = true
    startSignIn(onLikeAfterSignIn)
  else
    startSignIn(onDislikeAfterSignIn)
  end if
End Function


'''''''''''
' onLikeSelected
'
' Observer that is called when the like button is selected
Function onLikeSelected(msg)
  tubiLog("DetailScreenHelpers.onLikeSelected")
  detailScreen = msg.getRoSGNode()
  onLike(detailScreen)
End Function


Function onLike(detailScreen)
  tubiLog("DetailScreenHelpers.onLike")
  if isLoggedInUser() = true
    updateLikeDislike(detailScreen, m.constants.ui.likeDislikeActions.like)
  else
    signInAndLike(true)
  end if
End Function


'''''''''''
' onDislikeSelected
'
' Observer that is called when the dislike button is selected
Function onDislikeSelected(msg)
  tubiLog("DetailScreenHelpers.onDislikeSelected")
  detailScreen = msg.getRoSGNode()
  onDislike(detailScreen)
End Function


Function onDislike(detailScreen)
  tubiLog("DetailScreenHelpers.onDislike")
  if isLoggedInUser() = true
    updateLikeDislike(detailScreen, m.constants.ui.likeDislikeActions.dislike)
  else
    signInAndLike(false)
  end if
End Function


Function onRemoveLike(msg)
  tubiLog("DetailScreenHelpers.onRemoveLike")
  detailScreen = msg.getRoSGNode()
  updateLikeDislike(detailScreen, m.constants.ui.likeDislikeActions.removeLike)
End Function


Function onRemoveDislike(msg)
  tubiLog("DetailScreenHelpers.onRemoveDislike")
  detailScreen = msg.getRoSGNode()
  updateLikeDislike(detailScreen, m.constants.ui.likeDislikeActions.removeDislike)
End Function


'When there is an error, this function used by the user to try the operation again
' @param params, Array: The 1st element is the detailscreen and the 2nd element should be the returnedAction of the failed likeDislike rating action: @see the parameters match updateLikeDislike()
Function onLikeDislikeRetry(params)
  tubiLog("DetailScreenHelpers.onLikeDislikeRetry")
  if type(params) = "roArray" AND params.count() = 2
    updateLikeDislike(params[0], params[1])
  end if
End Function


' @param sRating, String: The like/dislike rating that the content like state should be changed. Or is the remove enum that will indicate the removal of the like/dislike state. The possible values are all under m.constants.ui.likeDislikeActions
Function updateLikeDislike(detailScreen, sRatingChange)
  if detailScreen <> invalid AND detailScreen.isWaitingForServerResponse <> true
    detailScreen.isWaitingForServerResponse = true

    '//While the backend is setting the rating, change the like state to changing
    detailScreen.likeDislikeState = m.constants.ui.likeDislikeStates.changing
    updateLikeDislikeRequestInfo = m.userDeviceApi.setContentRating(detailScreen.content.id, sRatingChange)

    '//Send Analytics of user interaction with the like/dislike button
    sAnalyticsEventType = ""
    if sRatingChange = m.constants.ui.likeDislikeActions.like
      sAnalyticsEventType = "LIKE"
    else if sRatingChange = m.constants.ui.likeDislikeActions.dislike
      sAnalyticsEventType = "DISLIKE"
    else if sRatingChange = m.constants.ui.likeDislikeActions.removeLike
      sAnalyticsEventType = "UNDO_LIKE"
    else if sRatingChange = m.constants.ui.likeDislikeActions.removeDislike
      sAnalyticsEventType = "UNDO_DISLIKE"
    end if

    sendLikeSelectAnalytics(detailScreen, sAnalyticsEventType)

    m.makeRequest({
      url: updateLikeDislikeRequestInfo.url
      requestType: m.constants.reqNames.setContentRating
      options: updateLikeDislikeRequestInfo.options
      successCallback: onLikeChangedSuccess
      errorCallback: onLIkeChangedError
      responseType: "assocarray"
    })
  end if
End Function


Function onLikeChangedSuccess(requestBody)
  tubiLog("DetailScreenHelpers.onLikeChangedSuccess")
  detailScreen = getTopDetailScreenFromStack()
  if requestBody <> invalid AND type(requestBody.data) = "roArray"
    returnedContentId = requestBody.data[0]
    sReturnedAction = requestBody.action
    m.Bookmarks.updateLikesLocally(returnedContentId, sReturnedAction, m.global)

    '//Tell Detail Screen how to react to user interacting with the like/dislike button
    if detailScreen <> invalid AND detailScreen.content <> invalid
      if detailScreen.content.id <> invalid AND returnedContentId <> invalid AND returnedContentId = detailScreen.content.id
        '//if the returned server call is associated with the the current video title, then proceed
        '//Proceed to take the proper action based on the action requested
        detailScreen.isWaitingForServerResponse = false
        setDetailScreenLikeDislikeStateFromLikeAction(detailScreen, sReturnedAction)
      end if

    end if
  end if
End Function


' Translate the like/dislike action into a like/dislike state.
' @param sLikeAction, String: The like action. The possible options are available in constants.ui.likeDislikeActions
' @return The Liked state. The possible options are available in constants.ui.likeDislikeStates
Function translateLikeActionToLikeState(sLikeAction)
  sState = ""
  if sLikeAction = m.constants.ui.likeDislikeActions.like
    sState = m.constants.ui.likeDislikeStates.liked
  else if sLikeAction = m.constants.ui.likeDislikeActions.dislike
    sState = m.constants.ui.likeDislikeStates.disliked
  end if

  return sState
End Function


' @param sLikeAction: String, the like action constant for the user of the current title: like, dislike, or "". The like/dislike states are defined in constants.ui.likeDislikeActions
Function setDetailScreenLikeDislikeStateFromLikeAction(detailScreen, sLikeAction)
  sLikedState = translateLikeActionToLikeState(sLikeAction)

  canShowLikeDisLikeToast = (UCase(m.constants.deviceInfo.countryCode) = "US" AND isKidsUIOn() = false)
  if isNonEmptyString(sLikedState) = true AND canShowLikeDisLikeToast = true
    dialogSubType = sLikedState + "_title"
    if sLikedState = m.constants.ui.likeDislikeStates.liked AND m.pub_serverPersistentData.isLikeToastNotificationShown = false

      saveServerPersistentData({
        "isLikeToastNotificationShown": true
      }, "device")

      message = getTranslation("detail_screen_like_toast_message")
      headerText = getTranslation("detail_screen_like_disLike_toast_header")

      toastInfo = {
        message: message
        selfDestructTimer: 5
        imageUri: "pkg:/images/icon_like_toast.webp"
        headerText: headerText
      }

      dialogEventInfo = {
        type: "dialog"
        values: {
          dialog_type: "TOAST"
          pageOneof: m.Tracking.getAnalyticsPage(detailScreen.trackingPageInfo.pageType, detailScreen.trackingPageInfo.pageValues)
          dialog_action: "SHOW"
          dialog_sub_type: dialogSubType
        }
      }

      showToast(toastInfo, true, dialogEventInfo)

    else if sLikedState = m.constants.ui.likeDislikeStates.disliked AND m.pub_serverPersistentData.isDisLikeToastNotificationShown = false

      saveServerPersistentData({
        "isDisLikeToastNotificationShown": true
      }, "device")

      message = getTranslation("detail_screen_disLike_toast_message")
      headerText = getTranslation("detail_screen_like_disLike_toast_header")

      toastInfo = {
        message: message
        selfDestructTimer: 5
        imageUri: "pkg:/images/icon_dislike_toast.webp"
        headerText: headerText
      }

      dialogEventInfo = {
        type: "dialog"
        values: {
          dialog_type: "TOAST"
          pageOneof: m.Tracking.getAnalyticsPage(detailScreen.trackingPageInfo.pageType, detailScreen.trackingPageInfo.pageValues)
          dialog_action: "SHOW"
          dialog_sub_type: dialogSubType
        }
      }

      showToast(toastInfo, true, dialogEventInfo)

    end if
  end if

  detailScreen.likeDislikeState = sLikedState
End Function


Function onLikeChangedError(parsedReturn)
  tubiLog("DetailScreenHelpers.onLikeChangedError")
  code = parsedReturn.code
  returnedContentId = invalid
  returnedAction = invalid
  if parsedReturn.action <> invalid AND parsedReturn.data <> invalid AND parsedReturn.data.Count() > 0
    returnedContentId = parsedReturn.data[0]
    returnedAction = parsedReturn.action
  end if

  detailScreen = getTopDetailScreenFromStack()

  if detailScreen <> invalid AND detailScreen.content <> invalid
    '//return the likeDislike button to the way it was before trying to unsuccessfully set the like/dislike
    currentScreen = getCurrentScreen()
    if currentScreen <> invalid AND currentScreen.id = detailScreen.id
      detailScreen.isWaitingForServerResponse = false

      '//set back to the previous like state before the failed attempt
      sPreviousLikeState = getLike(detailScreen.id)
      setDetailScreenLikeDislikeStateFromLikeAction(detailScreen, sPreviousLikeState)

      '//Make sure the current screen is associated with the detail screen that caused the error
      if code <> invalid AND detailScreen.content.id <> invalid AND returnedContentId <> invalid AND returnedContentId = detailScreen.content.id
        sErrorSubtype = ""
        dialogEvent = ""
        sAnalyticsDialogType = "SERVER_ERROR"
        if returnedAction = m.constants.ui.likeDislikeActions.like
          sErrorSubtype = m.constants.errors.subtypes.ratingAddLikeError
          ' sAnalyticsDialogType = "LIKE" '//::TODO:: have backend provide a DialogType in protos that corresponds to failing to change a specific like action
        else if returnedAction = m.constants.ui.likeDislikeActions.dislike
          sErrorSubtype = m.constants.errors.subtypes.ratingAddDislikeError
          ' sAnalyticsDialogType = "DISLIKE" '//::TODO:: have backend provide a DialogType in protos that corresponds to failing to change a specific like action
        else if returnedAction = m.constants.ui.likeDislikeActions.removeLike
          sErrorSubtype = m.constants.errors.subtypes.ratingRemoveLikeError
          ' sAnalyticsDialogType = "UNDO_LIKE" '//::TODO:: have backend provide a DialogType in protos that corresponds to failing to change a specific like action
        else if returnedAction = m.constants.ui.likeDislikeActions.removeDislike
          sErrorSubtype = m.constants.errors.subtypes.ratingRemoveDislikeError
          ' sAnalyticsDialogType = "UNDO_DISLIKE" '//::TODO:: have backend provide a DialogType in protos that corresponds to failing to change a specific like action
        end if

        ' set up the error modal dialog
        errorCode = getUserFacingErrorCode(m.constants.errors.context.videoDetailScreen, sErrorSubtype, code)
        content = getDetailScreenContent(detailScreen)
        dialogEvent = getDetailScreenDialogAnalyticEvent(content, sAnalyticsDialogType, errorCode, m.constants)
        title = getTranslation("error_tryAgain_title")
        message = getTranslation("screenDetails_error_likeDislike_description")
        modalInfo = {
          title: title
          message: getErrorMessage(message, errorCode)
          openTrackEvent: dialogEvent
          trackingTask: m.trackingLoggingTask
        }
        showErrorModal(modalInfo, onLikeDislikeRetry, [detailScreen, returnedAction])
      end if

    end if

  end if
End Function


Function onRemoveFromHistorySelected(msg)
  tubiLog("DetailScreenHelpers.onRemoveFromHistorySelected")
  detailScreen = msg.getRoSGNode()
  onRemoveFromHistory(detailScreen)
End Function


Function onRemoveFromHistory(detailScreen)
  if detailScreen <> invalid AND detailScreen.isWaitingForServerResponse <> true AND detailScreen.content <> invalid
    contentId = detailScreen.content.id
    history = getHistory(contentId)

    authInfo = getFieldFromGlobal("authInfo")

    isLoggedInUser = isLoggedInUser(authInfo)

    if isLoggedInUser = true AND  history <> invalid AND isNonEmptyString(history.historyId) = true
      content = detailScreen.content.clone(false)
      detailScreen.stringNoHistoryButton = getTranslation("screenDetails_button_removing")
      content.historyId = history.historyId

      detailScreen.isWaitingForServerResponse = true

      requestInfo = m.userDeviceApi.deleteHistory(history.historyId)
      m.makeRequest({
        url: requestInfo.url
        requestType: m.constants.reqNames.deleteHistory
        options: requestInfo.options
        successCallback: onHistoryRemovedSuccess
        errorCallback: onHistoryRemovedError
        responseType: "boolean"
      })
    else if isLoggedInUser = false
      removeHistoryLocally(contentId)
      detailScreen.isWaitingForServerResponse = false
      setIsHistory(detailScreen, false)
    end if

  end if
End Function


'Wraps onRemoveFromHistorySelected in the case of an error modal and a user attempting to retry removing the content from their history
Function onRemoveFromHistoryRetry(params)
  if type(params) = "roArray" AND params.count() = 1
    onRemoveFromHistory(params[0])
  end if
End Function


Function onHistoryRemovedSuccess(_response) As Void
  tubiLog("DetailScreenHelpers.onHistoryRemoved")
  detailScreen = getTopDetailScreenFromStack()
  if detailScreen <> invalid
    setIsHistory(detailScreen, false)
    sendBookmarkAnalytics(detailScreen.content, "REMOVE_FROM_CONTINUE_WATCHING", m.Tracking, m.trackingLoggingTask, m.constants)
    handleHistoryChange()
  end if
End Function


Function onHistoryRemovedError(response)
  tubiLog("DetailScreenHelpers.onHistoryRemoved")
  detailScreen = getTopDetailScreenFromStack()
  detailScreen.isWaitingForServerResponse = false

  code = ""
  if response <> invalid
    code = response.code
  end if

  message = getTranslation("screenDetails_error_noHistory_description")
  content = getDetailScreenContent(detailScreen)

  ' set up the error modal dialog
  errorCode = getUserFacingErrorCode(m.constants.errors.context.videoDetailScreen, m.constants.errors.subtypes.removeHistoryError, code)
  dialogEvent = getDetailScreenDialogAnalyticEvent(content, "REMOVE_FROM_HISTORY", errorCode, m.constants)

  modalInfo = {
    message: getErrorMessage(message, errorCode)
    openTrackEvent: dialogEvent
    trackingTask: m.trackingLoggingTask
  }

  showErrorModal(modalInfo, onRemoveFromHistoryRetry, [detailScreen])
  setIsHistory(detailScreen, true)

End Function


Function onRelatedContentSelected(msg)
  detailScreen = msg.getRoSGNode()
  content = invalid
  if detailScreen <> invalid AND detailScreen.relatedContent <> invalid
    content = detailScreen.relatedContent.getChild(detailScreen.relatedContentSelected)
  end if

  if content <> invalid
    '//reset videoSponsorExposureId when going to a new detail screen
    m.videoSponsorExposureId = ""

    playbackSource = {
      "srcForAnalytic": m.constants.player.playbackSource.unknown
      "srcForAds": m.constants.player.playbackOrigin.ymal
    }

    pageOriginDetails = {
      "pageOrigin": m.constants.player.playbackOrigin.ymal
      "functionName": "onRelatedContentSelected"
    }

    showDetailScreen(content, true, invalid, invalid, playbackSource, pageOriginDetails)
  end if
End Function


Function onCloseErrorModal()
  '//exit the detail screen entirely since the content could not be gathered.
  onDetailBackPressed()
End Function


Function onDetailBackPressed()
  ' TODO(Chris): This is in terrible need of refactor. We shouldn't be calling this directly
  ' but we have to invoke the "empty stack" logic at this point.
  onKeyEvent("back", true)
  onKeyEvent("back", false)
End Function


Function onEpisodeList(msg)
  tubiLog("DetailScreenHelper.onEpisodeList")
  detailScreen = msg.getRoSGNode()

  episodeDetail = getEpisodeDetail(detailScreen.content)
  if episodeDetail = invalid
    m.actionType = episodesHelper
    detailScreen.isLoading = true
    getSingleContentFromServer(detailScreen.content, onSingleContentResponseWithoutTracking, onSingleContentErrorWithoutTracking)
  else
    showEpisodeScreenWithNavigationTracking(detailScreen.content, detailScreen.playbackSource)
  end if
End Function


Function onSignUpButtonSelected(msg)
  tubiLog("DetailScreenHelper.onSignUpButtonSelected")
  startSignIn(onRegistrationProcessCompletedOnDetailsScreen)
End function

' // REMOVE BELOW CODE ONCE FIFA WORLD CUP IS DONE
Function onSeeAllGamesSelected()
  tubiLog("DetailScreenHelper.onSeeAllGamesSelected")
  showTournamentScreen(m.constants)
End Function


Function onDescriptionSelected(msg)
  tubiLog("DetailScreenHelper.onDescriptionSelected")
  detailScreen = msg.getRoSGNode()
  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: "FULL_VIDEO_DESCRIPTION"
      pageOneof: m.Tracking.getAnalyticsPage("video_page", {video_id: detailScreen.content.id.toInt()})
      dialog_action: "SHOW" 'Action enum
      dialog_sub_type: "video-description" 'max 20 character string
    }
  }
  showDescriptionModal(detailScreen.description, dialogEvent, m.trackingLoggingTask)
End Function


Function episodesHelper(screen)
  showEpisodeScreenWithoutNavigationTracking(screen.content, screen.playbackSource)
End Function


Function trailerHelper(screen)
  content = screen.content

  if content <> invalid then
    bMature = isMatureRating(content)
    if isLoggedInUser() = false AND bMature = true
      '//if user is a guest and is trying to play content geared for only adults, then ask them to register
      dialogSubtype = "mature-trailer"
      displayDetailScreenMaturePlayWarning(content, dialogSubtype)
    else
      trailerContent = CreateObject("roSGNode", "TubiContentNode")
      if content.id <> invalid
        trailerContent.id = content.id
      end if

      if content.title <> invalid
        trailerContent.title = getTranslation("videoPlayer_trailerTitle", {title: content.title})
      end if

      trailerContent.nowPos = 0
      trailerContent.isTrailer = true

      if content.hasTrailer AND content.trailerInfo <> invalid AND content.trailerInfo.url <> invalid
        trailerContent.url = content.trailerInfo.url
        trailerContent.streamFormat = content.trailerInfo.streamFormat
        trailerContent.id = content.trailerInfo.id
        trailerContent.subtitleTracks = []
        trailerContent.subtitleConfig = invalid
        trailerContent.rating = content.rating
        trailerContent.descriptorCode = content.descriptorCode
        trailerContent.descriptors = content.descriptors
        trailerContent.descriptorDescription = content.descriptorDescription
      end if

      playVideoContent(trailerContent)
    end if
  end if
End Function


Function onWatchTrailer(msg)
  tubiLog("DetailScreenHelpers.onWatchTrailer")
  detailScreen = msg.getRoSGNode()

  content = getDetailScreenContent(detailScreen)
  if content <> invalid then
    if isFetchingInProgress(detailScreen) <> true
      if isPlayable(detailScreen) = true
        trailerHelper(detailScreen)
      else
        m.actionType = trailerHelper
        detailScreen.isLoading = true
        getSingleContentFromServer(detailScreen.content, onSingleContentResponseWithoutTracking, onSingleContentErrorWithoutTracking)
      end if

    end if
  end if
End Function


'''''''''''
' isFetchingInProgress
'
' Check whether any task running or not
Function isFetchingInProgress(screen) as Boolean

  bReturn = false
  task = screen.task

  if task <> invalid AND task.subType() = "DetailMetadataTask"
    bReturn = true
  end if

  return bReturn
End Function


'''''''''''
' isPlayable
'
' Check whether any url is present for movie and episode detail available for series
Function isPlayable(screen) as Boolean

  bReturn = false
  content = screen.content

  if content <> invalid AND content.type <> invalid
    if content.type = "series"
      episodeDetail = getEpisodeDetail(screen.content)
      if episodeDetail <> invalid AND episodeDetail.url <> invalid AND Len(episodeDetail.url) > 0
        if episodeDetail.validUntil <> invalid AND episodeDetail.validUntil >= UpTime(0)
          bReturn = true
        end if

      end if

    else if content.type = "video" AND content.url <> invalid AND Len(content.url) > 0
      if content.validUntil <> invalid AND content.validUntil >= UpTime(0)
        bReturn = true
      end if

    end if

  end if

  return bReturn
End Function


'''''''''''
' onResume
'
' Notify the main Brightscript thread to invoke the video player, resuming at the indicated location if data present
' if data not present, it invokes content api
Function onResume(msg)
  tubiLog("ContentController.onResume")
  detailScreen = msg.getRoSGNode()

  if detailScreen <> invalid
    resumeVideoDetailScreen(detailScreen, detailScreen.playbackSource)
  end if
End Function


' @detailScreen: roSGNode, detail screen node
' @playbackSource: associative Array, format : srcForAnalytic - this value is used for sending analytics;
'                                                   valid values are "automatic", "deliberate", "unknown" or "previews"
'                                               srcForAds - used for rainmaker request
'                                                    valid values are "deeplink" , "ap_auto", "ap_select", "container", "ymal", "search", "epg", "unknown"

'                                               playbackContainer - if srcForAds = container, then playbackContainer is set to the id of the container that was the source, otherwise not used.
Function resumeVideoDetailScreen(detailScreen, playbackSource = {"srcForAnalytic":"unknown", "srcForAds":"unknown"})
  tubiLog("DetailScreenHelpers.resumeVideoDetailScreen")
  if detailScreen <> invalid AND isFetchingInProgress(detailScreen) <> true
    detailScreen.playbackSource = playbackSource
    if isPlayable(detailScreen) = true
      detailScreenResumeHelper(detailScreen)
    else
      m.actionType = detailScreenResumeHelper
      detailScreen.isLoading = true
      getSingleContentFromServer(detailScreen.content, onSingleContentResponseWithoutTracking, onSingleContentErrorWithoutTracking)
    end if

  end if

End Function

'''''''''''
' onPlay
'
' Notify the main Brightscript thread to invoke the video player if data present
' if data not present, it invokes content api
Function onPlay(msg)
  tubiLog("DetailScreenHelpers.onPlay")
  detailScreen = msg.getRoSGNode()
  playVideoDetailScreen(detailScreen, detailScreen.playbackSource)

End Function


' @detailScreen: roSGNode, detail screen node
' @playbackSource: associative Array, format : srcForAnalytic - this value is used for sending analytics;
'                                                   valid values are "automatic", "deliberate", "unknown" or "previews"
'                                               srcForAds - used for rainmaker request
'                                                    valid values are "deeplink" , "ap_auto", "ap_select", "container", "ymal", "search", "epg", "unknown"

'                                               playbackContainer - if srcForAds = container, then playbackContainer is set to the id of the container that was the source, otherwise not used.

Function playVideoDetailScreen(detailScreen, playbackSource = {"srcForAnalytic":"unknown","srcForAds":"unknown"})
  tubiLog("DetailScreenHelpers.playVideoDetailScreen")
  if detailScreen <> invalid AND isFetchingInProgress(detailScreen) <> true
    detailScreen.playbackSource = playbackSource
    if isPlayable(detailScreen) = true
      playHelper(detailScreen)
    else
      m.actionType = playHelper
      detailScreen.isLoading = true
      getSingleContentFromServer(detailScreen.content, onSingleContentResponseWithoutTracking, onSingleContentErrorWithoutTracking)
    end if

  end if
End Function


'Is the rating of the content in the passed screen set for mature audience?
Function isMatureRating(content)
  if content <> invalid AND content.rating <> invalid
    sRating = UCase(content.rating)
    aRatings = m.constants.ui.matureRatings[m.constants.deviceInfo.countryCode]
    if aRatings <> invalid AND aRatings.Count() > 0
      for i = 0 to aRatings.Count() - 1
        if sRating = aRatings[i]
          return true
        end if

      end for

    end if

  end if

  return false
End Function


'Display a warning that the user needs to be registered in order to see certain content
'@param content, the video details
'@param dialogSubtype: String, Indicate to analytics how this function is being called so it is easier to track things.
Function displayDetailScreenMaturePlayWarning(content, dialogSubtype)
  pageInfo = getDetailScreenAnalyticsPageInfo(content, m.constants)
  displayMaturePlayWarning(dialogSubtype, pageInfo)
End Function


Function playHelper(screen)
  episode = getEpisodeContent(screen.content)
  if episode <> invalid AND screen.isLoading <> true then
    bMature = isMatureRating(episode)
    if isLoggedInUser() = false AND bMature = true
      '//if user is a guest and is trying to play content geared for only adults, then ask them to register
      dialogSubtype = "mature-play"
      if m.deepLinkContent <> invalid
        '//this is a deeplink so, indicate that the warning originated from a deeplink
        dialogSubtype = "mature-play-deep"
      end if
      displayDetailScreenMaturePlayWarning(episode, dialogSubtype)
    else
      playVideoContent(episode, screen.playbackSource)
    end if

  else
    tubiLog("ERROR: Play selected but content is invalid")
  end if
End Function


Function detailScreenResumeHelper(detailScreen)
  episode = getEpisodeContent(detailScreen.content)
  if episode <> invalid then
    nowPos = processResume(episode)
    if nowPos >= 0
      playVideoContent(episode, detailScreen.playbackSource, nowPos)
    end if

  else
    tubiLog("ERROR: Resume selected but content is invalid")
  end if
End Function


' @episode: roSGNode, ContentNode for a single video. May be a movie or a series episode.
'
' @return: integer, the position from which video playback should resume.
'                   PLEASE NOTE: A negative value indicates the content should not be played!
Function processResume(episode)
  bMature = isMatureRating(episode)
  nowPos = -1
  if isLoggedInUser() = false AND bMature = true
    '//if user is a guest and is trying to play content geared for only adults, then ask them to register dialogSubtype = "mature-play"
    dialogSubtype = "mature-resume"
    if m.deepLinkContent <> invalid
      '//this is a deeplink so, indicate that the warning originated from a deeplink
      dialogSubtype = "mature-resume-deep"
    end if

    displayDetailScreenMaturePlayWarning(episode, dialogSubtype)
  else
    nowPos = 0
    ' using nowPos that was passed in with deeplink, when playback initiated via deeplink
    if m.deeplinkContent <> invalid AND episode.nowPos > 0
      nowPos = episode.nowPos
    else
      ' find the position in global history
      history = getHistory(episode.id)

      if history <> invalid AND history.nowPos > 0
        nowPos = history.nowPos
      end if

    end if
  end if

  return nowPos
End Function


' A callback to be used after fetching the single content to immediately begin playback.
' Used when a user presses the "play" button on the homescreen, for instance.
' @refreshedContent: roSGNode, full metadata as received from the cms/content route
Function skipDetailScreen(refreshedContent)
  tubilog("detailScreenHelpers.skipDetailScreen")

  subScreen = getHiddenScreen(1)

  trackingPageInfo = {}
  trackingComponentInfo = {}
  if subScreen <> invalid
    trackingPageInfo = subScreen.trackingPageInfo
    trackingComponentInfo = subScreen.trackingComponentInfo
  end if

  detailScreen = getTopDetailScreenFromStack()
  if detailScreen <> invalid
    pageOriginDetails = {
      "pageOrigin": m.constants.ui.screenIds.detailScreen
      "functionName": "skipDetailScreen"
    }
    populateDetailScreen(detailScreen, refreshedContent, false, -1, pageOriginDetails)

    if refreshedContent.needsLogin = false AND detailScreen.availabilityType <> m.constants.ui.contentTimings.upcoming
      if refreshedContent.type = m.constants.ui.contentTypes.series AND refreshedContent.currentEpisodeId = "" AND refreshedContent.isRecurring = false
        ' first see if there was a specific episode id we wanted
        history = getHistory(refreshedContent.id)
        if history <> invalid
          refreshedContent.currentEpisodeId = history.currentEpisodeId
        end if
      end if

      episode = getEpisodeContent(refreshedContent)

      if episode <> invalid
        if m.enteredFromDeepLink = true AND m.deeplinkContent <> invalid
          sendDeeplinkAnalytics(m.deeplinkContent, episode, m.constants.deeplinks.entryPoints.video, m.Tracking, m.trackingLoggingTask, m.constants)
        end if

        nowPos = processResume(episode)
        if m.top.fadeInContentController = true
          if nowPos >= 0
            playVideoContentWhileSkippingDetailScreen(episode, nowPos, trackingPageInfo, trackingComponentInfo, detailScreen.playbackSource)
          end if
        else
          if nowPos > 0
            m.detailScreenAfterFn = detailScreenResumeHelper
          else
            m.detailScreenAfterFn = playHelper
          end if
        end if
      end if
    end if
  end if
End Function


' Organizes the information needed to create a "bookmark" tracking event and sends the information to the trackingTask which will
' actually send the event.
'
' @content: roSGNode, the content that is residing on the details page, can be a movie or series
' @operation: string, one of the valid operations as defined in events.protos -> Bookmarks -> enum Operation
' @trackingLib: associativeArray, an instance of TubiTracking()
' @trackingTask: roSGNode, an instance of the TrackingLoggingTask
Function sendBookmarkAnalytics(content, operation, trackingLib, trackingTask, constants)
  bookmarkAnalyticsEvent = {
    contentOneof: {}
    op: operation
    component: {} 'menu component not currently included in protos definition
  }
  if type(content) = "roSGNode" AND content.isSubtype("ContentNode") = true
    pageInfo = getDetailScreenAnalyticsPageInfo(content, constants)
    bookmarkAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
  end if

  if content.type = m.constants.ui.contentTypes.series
    seriesId = content.id
    if Left(content.id, 1) = "0"
      seriesId = Mid(content.id, 2)
    end if
    bookmarkAnalyticsEvent.contentOneof.series_id = seriesId.toInt()
  else if content.type = m.constants.ui.contentTypes.video
    bookmarkAnalyticsEvent.contentOneof.video_id = content.id.toInt()
  else if content.type = m.constants.ui.contentTypes.sportsEvent
    bookmarkAnalyticsEvent.contentOneof.video_id = content.id.toInt()
  end if

  trackingTask.trackEvent = {
    type: "bookmark"
    values: bookmarkAnalyticsEvent
  }
End Function


' Organizes the information needed to create a "like/dislike" event when the user changes the like state of a content. The function
' sends the information to the trackingTask which will actually send the event.
'
' @screen: the detail screen
' @sLikeEventEnum: string, one of the valid event strings as defined in events.protos -> enum ExplicitInteraction
Function sendLikeSelectAnalytics(screen, sLikeEventEnum)
  tubiLog("DetailScreenHelper.sendLikeSelectAnalytics")

  explicitFeedbackEvent = {
    targetOneof: {}
    pageOneof: {}
  }

  pageInfo = screen.trackingPageInfo
  pageOneof = m.Tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)

  componentValues = {}

  content = screen.content
  if content.type = m.constants.ui.contentTypes.series
    seriesId = content.id
    '//if series, remove the "0" that was added in TubiMetadataTranslate
    if Left(content.id, 1) = "0"
      seriesId = Mid(content.id, 2)
    end if

    componentValues.series_id = seriesId.toInt()
  else if content.type = m.constants.ui.contentTypes.video
    componentValues.video_id = content.id.toInt()
  end if

  targetOneof = m.Tracking.getAnalyticsComponent("content", componentValues)
  targetOneof.content.user_interaction = sLikeEventEnum

  explicitFeedbackEvent.targetOneof = targetOneof
  explicitFeedbackEvent.pageOneof = pageOneof

  m.trackingLoggingTask.trackEvent = {
    type: "explicit_feedback"
    values: explicitFeedbackEvent
  }
End Function


'send the navigateToPage and pageLoad analytics in the case of an error loading the details screen
Function sendDetailScreenErrorAnalytics(detailScreen)
  ' Handle navigate_to_page and page_load tracking for detail screen for error cases
  if detailScreen <> invalid AND detailScreen.contentFetchError = false
    oldScreen = getHiddenScreen(1) 'we already pushed the details screen, so the previous screen is 1 screen below the top screen/details screen
    if oldScreen <> invalid
      screenTrackingNavigate(oldScreen.trackingPageInfo, detailScreen.trackingPageInfo, oldScreen.trackingComponentInfo)
    end if

    loadTime = Int((Uptime(0) - detailScreen.trackingLoadStartTime) * 1000) 'in ms
    screenTrackingLoad(detailScreen.trackingPageInfo, loadTime, false)
  end if
End Function


' Organizes the information needed to create a "dialog" tracking event and returns the created event AA
'
' @content: roSGNode, the content that is residing on the details page content field, can be a movie or series
' @dialogType: string, one of the valid operations as defined in events.protos -> DialogEvent -> enum DialogType
' @dialogSubtype: string, a string limited to 20 characters, used to distinguish different dialogs from each other
' @constants: assocArray, an instance of m.constants
Function getDetailScreenDialogAnalyticEvent(content, dialogType, dialogSubtype, constants)
  pageInfo = invalid
  if type(content) = "roSGNode" AND content.isSubtype("ContentNode") = true
    pageInfo = getDetailScreenAnalyticsPageInfo(content, constants)
  end if

  dialogAnalyticsEvent = getDialogAnalyticEvent(dialogType, dialogSubtype, pageInfo)

  return dialogAnalyticsEvent
End Function


' From an analytics point of view, the details screen can be a video_page or a series_detail_page depending if the content it
' it is displaying is a movie or an episode. This function returns an AA with pageType and pageValue keys that can be passed into
' m.Tracking.getAnalyticsPage(pageType, pageValues) to create the appropriate analytics page message, based on the content type.
' May also return invalid if the content parameter is not a ContentNode with values on appropriate fields.
'
' @content: roSGNode, the content that is residing on the details page content field, can be a movie or series
Function getDetailScreenAnalyticsPageInfo(content, constants)
  pageInfo = invalid
  airDateTime = content.airDatetime
  hasVideoResources = content.hasVideoResources

  info = getAvailabilityTypeBadgeAndMatchTimeValues(airDateTime, hasVideoResources)
  availabilityType = info.availabilityType

  if content <> invalid AND type(content.id) = "roString"
    if content.type = constants.ui.contentTypes.series
      if availabilityType = constants.ui.contentTimings.upcoming
        pageInfo = {
          pageType: "upcoming_content_page"
          pageValues: {
            series_id: content.id.toInt()
          }
        }
      else
        pageInfo = {
          pageType: "series_detail_page"
          pageValues: {
            series_id: content.id.toInt()
          }
        }
      end if
    else if content.type = constants.ui.contentTypes.video OR content.type = constants.ui.contentTypes.sportsEvent
      if availabilityType = constants.ui.contentTimings.upcoming
        pageInfo = {
          pageType: "upcoming_content_page"
          pageValues: {
            video_id: content.id.toInt()
          }
        }
      else
        pageInfo = {
          pageType: "video_page"
          pageValues: {
            video_id: content.id.toInt()
          }
        }
      end if
    end if

  end if

  return pageInfo
End Function


'make getRelatedContent call after autoplay to display the refreshed YMAL content
Function onAutoplaySingleContentResponse(refreshedContent)
  detailScreen = getTopDetailScreenFromStack()
  if refreshedContent <> invalid
    pageOriginDetails = {
      "pageOrigin": m.constants.ui.screenIds.detailScreen
      "functionName": "onAutoplaySingleContentResponse"
    }
    populateDetailScreen(detailScreen, refreshedContent, false, -1, pageOriginDetails)
    getRelatedContent(refreshedContent)
  end if
End Function


Function removeFromQueueSuccessResponse(_response)
  tubiLog("DetailScreenHelpers.removeFromQueueSuccessResponse")
  detailScreen = getTopDetailScreenFromStack()
  if detailScreen <> invalid
    sendBookmarkAnalytics(detailScreen.content, "REMOVE_FROM_QUEUE", m.Tracking, m.trackingLoggingTask, m.constants)
  end if

  handleQueueChange()
End Function


Function removeFromQueueErrorResponse(error)
  tubiLog("DetailScreenHelpers.removeFromQueueErrorResponse")
  detailScreen = getTopDetailScreenFromStack()
  if detailScreen <> invalid
    detailScreen.isWaitingForServerResponse = false

    code = ""
    content = getDetailScreenContent(detailScreen)

    message = getTranslation("screenDetails_error_noQueueMovie_description")
    if content <> invalid AND content.type = m.constants.ui.contentTypes.series
      message = getTranslation("screenDetails_error_noQueueSeries_description")
    else if content <> invalid AND detailScreen.availabilityType = m.constants.ui.contentTimings.upcoming
      message = getTranslation("screenDetails_error_noQueueUpcoming_description")
    else if content <> invalid AND detailScreen.availabilityType = m.constants.ui.contentTimings.replay
      message = getTranslation("screenDetails_error_noQueueReplay_description")
    end if

    if error <> invalid
      code = error.code
    end if

    detailScreen.stringQueueButton = getTranslation("screenDetails_button_noQueue")

    ' set up the error modal dialog
    errorCode = getUserFacingErrorCode(m.constants.errors.context.videoDetailScreen, m.constants.errors.subtypes.removeBookmarkError, code)
    dialogEvent = getDetailScreenDialogAnalyticEvent(content, "REMOVE_FROM_QUEUE", errorCode, m.constants)
    title = getTranslation("error_tryAgain_title")

    modalInfo = {
      title: title
      message: getErrorMessage(message, errorCode)
      openTrackEvent: dialogEvent
      trackingTask: m.trackingLoggingTask
    }

    showErrorModal(modalInfo, onRemoveFromQueueRetry, [detailScreen])
  end if
End Function


Function addToQueueSuccessResponse(response)
  tubiLog("DetailScreenHelpers.addToQueueSuccessResponse")
  detailScreen = getTopDetailScreenFromStack()

  if detailScreen <> invalid
    if response <> invalid
      bookmarkId = response.id

      if bookmarkId <> invalid
        sendBookmarkAnalytics(detailScreen.content, "ADD_TO_QUEUE", m.Tracking, m.trackingLoggingTask, m.constants)
        handleQueueChange()
      end if

    end if
  end if
End Function


Function addToQueueErrorResponse(error)
  tubiLog("DetailScreenHelpers.addToQueueErrorResponse")
  detailScreen = getTopDetailScreenFromStack()
  if detailScreen <> invalid
    detailScreen.isWaitingForServerResponse = false
    bookmarkFailed(detailScreen, error)
  end if
End function


' // REMOVE BELOW CODE ONCE FIFA WORLD CUP IS DONE
' @screen: node - screen node
' @isReminderSet: boolean, true = "TOGGLE_ON" ; false = "TOGGLE_OFF"
Function setComponentInteractionEventForReminder(screen, isReminderSet)
  tubiLog("DetailScreenHelpers.setComponentInteractionEventForReminder")

  componentValues = {
    video_id: screen.trackingPageInfo.pageValues.video_id
  }

  if isReminderSet = true
    userInteractionValue = "TOGGLE_ON"
  else
    userInteractionValue = "TOGGLE_OFF"
  end if

  pageOneof = m.Tracking.getAnalyticsPage(screen.trackingPageInfo.pagetype, screen.trackingPageInfo.pageValues)
  componentOneof = m.Tracking.getAnalyticsComponent("reminder_component", componentValues)

  componentInteractionEvent =  {
    pageOneof: pageOneof
    componentOneof: componentOneof
    user_interaction: userInteractionValue
  }
  m.trackingLoggingTask.trackEvent = {
    type: "component_interaction"
    values: componentInteractionEvent
  }
End Function


Function onRelatedContentToPlay(msg)
  content = msg.getData()
  playbackSource = {
    "srcForAnalytic": m.constants.player.playbackSource.unknown
    "srcForAds":m.constants.player.playbackOrigin.ymal
  }

  pageOriginDetails = {
    "pageOrigin": m.constants.player.playbackOrigin.ymal
    "functionName": "onRelatedContentToPlay"
  }
  showDetailScreen(content, false, skipDetailScreen, invalid, playbackSource, pageOriginDetails)
End Function


' Resets the related content on a details screen such that UX updates itself.
' Does not re-fetch related content, merely reparents the related content into a
' new category node to cause the UI refresh.
' Necessary after sign in/sign out, especially in the case of content being registration gated
'
' @detailScreen: roSGNode, an instance of a details screen
Function resetRelatedContent(detailScreen)
  if isNode(detailScreen) = true AND detailScreen.isSubtype("DetailScreen")
    relatedContent = detailScreen.relatedContent

    if isNode(relatedContent) = true
      relatedContentChildren = relatedContent.getChildren(-1, 0)
      refreshedRelatedContent = CreateObject("roSGNode", "CategoryContentNode")
      refreshedRelatedContent.appendChildren(relatedContentChildren)
      detailScreen.relatedContent = refreshedRelatedContent
    end if
  end if
End Function