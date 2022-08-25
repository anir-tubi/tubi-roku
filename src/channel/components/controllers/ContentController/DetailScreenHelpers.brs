
'''''''''''''''''''''
' showDetailScreen
'
' @content: roSGNode, a content node for a single pieces of content, might be a video or top level series
' @sendTrackingOnResponse: boolean, set to true if the content needs to be fetched and NavigateToPageEvent and
'                                   PlayProgressEvent analytics should be sent after fetching info from the backend.
' @successCb: roFunction, a callback to run upon successful fetching of single content metadata
' @errorCb: roFunction, a callback to run upon error while fetching of single content metadata
' @playbackSource: string, valid values are "automatic", "deliberate", "unknown" or "previews"
Function showDetailScreen(content, sendTrackingOnResponse = true, successCb = invalid, errorCb = invalid, playbackSource = "unknown")
  tubiLog("DetailScreenHelpers.showDetailScreen")
  if content <> invalid
    detailScreen = CreateObject("roSGNode", "DetailScreen")
    detailScreen.id = m.constants.ui.screenIds.detailScreen
    detailScreen.trackingLoadStartTime = Uptime(0)
    detailScreen.shouldFocusWhenPushed = m.top.fadeInContentController
    detailScreen.playbackSource = playbackSource
    detailScreen.observeFieldScoped("toggleOnButtonValue", "onDetailScreenButtonToggleOn")
    detailScreen.observeFieldScoped("toggleOffButtonValue", "onDetailScreenButtonToggleOff")
    detailScreen.observeFieldScoped("confirmButtonValue", "onDetailScreenButtonConfirm")
    detailScreen.observeFieldScoped("playSelected", "onPlay")
    detailScreen.observeFieldScoped("resumeSelected", "onResume")
    detailScreen.observeFieldScoped("likeSelected", "onLike")
    detailScreen.observeFieldScoped("dislikeSelected", "onDislike")
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
    detailScreen.observeFieldScoped("relatedContentToPlay", "onContentToPlay")
    detailScreen.observeFieldScoped("stopVideoPreview", "onStopVideoPreview")
    detailScreen.observeFieldScoped("signUpButtonSelected", "onSignUpButtonSelected")

    if getExperimentResource("roku_video_preview", "roku_video_preview_v2", false).enabled = true
      previewState = getVideoPreviewStateForThisContent(content)
      if previewState = "buffering" or previewState = "playing"
        pageType = "video_page"
        if content.type = m.constants.ui.contentTypes.series
          pageType = "series_detail_page"
        end if
        setPageTypeForVideoPreview(pageType) ' this will help to trigger analytics
      else
        previewState = getVideoPreviewState()
        if previewState <> "stopped" and previewState <> "finished" ' this means video not stopped/finished for previous content, so we need to stop it
          stopVideoPreview()
        end if
      end if
    end if


    ' m.actionType variable is used for setting a callback function after successful a data fetch retry in the case where
    ' users select a menu button from the detail screen, but the origial data fetch was unsuccessful. In this way,
    ' the action will happen automatically after the successful retry.
    m.actionType = invalid

    ' detailScreenAfterFn callback which will be triggered after fetching data from backend
    m.detailScreenAfterFn = invalid

    ' m.isScreenLoaded will be changed to true once the metadata is populated
    m.isScreenLoaded = false

    ' Update tracking info - have to set the whole AA, can't update only a portion on the AA field
    detailScreen.trackingPageInfo = getDetailScreenAnalyticsPageInfo(content, m.constants)

    setDetailStrings(detailScreen)

    ' Setting the content on the detail screen here prior to getting a response back from server with full info,
    ' so that it may be used for analytics in the case of failing to fetch the full info from the server.
    ' We expect to overwrite this in populateDetailScreen() which occurs after the full info has been fetched from the /content API
    detailScreen.content = content

    ' waiting to populate the details screen for series until after we fetch episode data
    if m.deepLinkContent <> invalid or content.type = m.constants.ui.contentTypes.series or (content.type = m.constants.ui.contentTypes.video and content.seriesId <> invalid and content.seriesId <> "")
      detailScreen.isLoading = true
    else if successCb <> invalid
      detailScreen.isLoading = true
    else
      populateDetailScreen(detailScreen, content, true)
      detailScreen.isLoading = true '//1st set to true before settng to false. For some reason setting it to false by itself does not get registered, even if he isLoading field's alwaysNotify property is set to true
      detailScreen.isLoading = false
    end if

    pushScreen(detailScreen, false, false) ' don't send tracking until we resolve series episode

    ' determine the appropriate fetch callbacks based on the passed in parameters
    successCallback = onSingleContentResponseWithTracking
    errorCallback = onSingleContentErrorWithTracking
    if sendTrackingOnResponse = false
      successCallback = onSingleContentResponseWithoutTracking
      errorCallback = onSingleContentErrorWithoutTracking
    end if

    'NOTE: SuceessCb and ErrorCb should handle analytics tracking.
    if successCb <> invalid
      successCallback = successCb
    end if

    if errorCb <> invalid
      errorCallback = errorCb
    end if

    ' checking if the series content node exists in the content cache prior to fetching the content
    if content.type = m.constants.ui.contentTypes.series
      seriesContent  = getFromContentCache(content.id)
      if seriesContent <> invalid
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
  return (type(screen) = "roSGNode" and screen.isSubType("DetailScreen") = true)
End Function


Function setDetailStrings(screen)
  screen.stringQueueButton = getTranslation("screenDetails_button_queue")
  screen.stringNoQueueButton = getTranslation("screenDetails_button_NoQueue")
  screen.stringNoHistoryButton = getTranslation("screenDetails_button_noHistory")
  screen.stringSignUpButton = getTranslation("registration_signup_button") + ";" + getTranslation("registration_signup_button_free")
End Function


Function onDetailBackgroundChange(msg)
  tubiLog("DetailScreenHelpers.onDetailBackgroundChange")
  detailScreen = msg.getRoSGNode()
  if detailScreen.isInFocusChain()

    if getExperimentResource("roku_video_preview", "roku_video_preview_v2", false).enabled = true
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
Function populateDetailScreen(detailScreen, content, shouldResetButtonIndex = false, nSavedPosition = -1)
  tubiLog("DetailScreenHelpers.populateDetailScreen")
  'initialize default background - will be overwritten later in most cases
  backgroundUriList = [m.defaultBackgroundUri]
  if isDetailScreen(detailScreen) = true and type(content) = "roSGNode"
    'hide the spinner
    detailScreen.isLoading = false

    lineOneData = {}

    ' don't show related content if the user is in any of the kids modes
    detailScreen.showRelated = not isKidsUIOn()

    ' don't allow add to/remove from my list if the user is age gated
    if m.uiMode = m.constants.ui.modes.kidsAgeGate
      detailScreen.disableBookmarks = true
    end if

    'update detail screen state via the input interface
    detailScreen.title = content.title
    detailScreen.genres = content.genres

    if content.hasTrailer = true
      detailScreen.hasTrailer = true
    end if

    bookmark = getBookmark(content.id)
    history = getHistory(content.id)
    like = getLike(content.id)

    if isLoggedInUser() = false and history <> invalid
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
    if content.type = m.constants.ui.contentTypes.series
      if episode <> invalid
        if history <> invalid
          '//if there is no history, then there is no episode history either
          episodeHistory = getHistory(episode.id)
        end if
        detailScreen.episodeTitle = episode.title
      end if

      lineOneData.type = m.constants.ui.contentTypes.series
      lineOneData.seasons = content.totalCount
      detailScreen.isSeries = true
      detailScreen.mode = m.constants.ui.infoPanelModes.series
    else
      detailScreen.mode = m.constants.ui.infoPanelModes.movie
    end if
    if isKidsUIOn() = true
      detailScreen.isInKidsMode = true
    else
      detailScreen.isInKidsMode = false
    end if
    if episode <> invalid
      stateSource = episode
    else
      stateSource = content
    end if

    lineOneData.length = stateSource.length
    lineOneData.rating = stateSource.rating
    lineOneData.releaseDate = content.releaseDate
    lineOneData.partnerLogoUri = content.inlineLogoUri

    if episode <> invalid and (episode.hasSubtitles = true or not m._.empty(episode.subtitleTracks))
      lineOneData.hasCC = true
    else if content <> invalid and content.type = m.constants.ui.contentTypes.video and (content.hasSubtitles = true or not m._.empty(content.subtitleTracks))
      lineOneData.hasCC = true
    else
      lineOneData.hasCC = false
    end if

    lineOneData.descriptorCode = content.descriptorCode

    if content.availabilityEnds <> invalid and content.availabilityEnds <> ""
      lineOneData.availabilityEnds = content.availabilityEnds
    else if episode <> invalid and episode.availabilityEnds <> invalid
      lineOneData.availabilityEnds = episode.availabilityEnds
    end if

    detailScreen.lineOneData = lineOneData

    detailScreen.description = stateSource.description
    detailScreen.directors = stateSource.directors
    detailScreen.starring = stateSource.actors

    setIsBookmark(detailScreen, (bookmark <> invalid))
    sLikedState = ""
    if like <> invalid
      sLikedState = like.state
    end if
    detailScreen.likeDislikeState = sLikedState

    '//right now in kids mode, there are no channels showing up, so hardcode it so the channel's button doesn't show
    detailScreen.isChannelItem = (content.channelId <> invalid and content.channelId <> "" and isKidsUIOn() = false)
    detailScreen.stringChannelButton = getTranslation("screenDetails_button_gotoChannel", {channel: content.channelName})
    detailScreen.length = stateSource.length 'needed to compute the resume bar on the resume button

    nResumePoint = 0
    if content.type = m.constants.ui.contentTypes.series and episodeHistory <> invalid and episodeHistory.nowPos > 0
      nResumePoint = episodeHistory.nowPos
    else if content.type = m.constants.ui.contentTypes.video and history <> invalid and history.nowPos > 0
      nResumePoint = history.nowPos
    end if
    if nResumePoint < m.constants.player.historyFrequency
      '//make sure the resume point is at least the client side constant minimum
      nResumePoint = 0
    end if

    if nSavedPosition >= m.constants.player.historyFrequency and isLoggedInUser() = true
      '//nSavedPosition is only used for signed in users and ignored for guest users.
      '//If the saved position is passed as greater than the constant historyFrequency, then use that number instead.
      '//This parameter was put in place to display the updated resume point before having to wait to backend to confirm that the resume point is correct
      nResumePoint = nSavedPosition
    end if

    if nResumePoint >= m.constants.player.historyFrequency
      setIsHistory(detailScreen, true)
    else 
      setIsHistory(detailScreen, false)
    end if
    
    detailScreen.resumePoint = nResumePoint

    'tell the detail screen/info panel to vertically center the info panel
    detailScreen.calculateInfoHeight = true

    if detailScreen.relatedContent = invalid
      '//Only change the related content if it hasn't alreeady been loaded. If we try to reload the related content, then the thunbnails may not display due to (porobably) a firmware issue
      detailScreen.relatedContent = content.relatedContent
    end if

    'update the background images for the detail screen
    if content.backgrounds <> invalid and content.backgrounds.count() > 0
      backgroundUriList = content.backgrounds
    end if

    detailScreen.backgroundUriList = backgroundUriList

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
    singleRequestInfo = m.cmsApi.singleContentReqInfo(content.id, true, shouldKidsModeBeSentToServer())
    m.makeRequest({
      url: singleRequestInfo.url
      requestType: m.constants.reqNames.getSingleContent
      options: singleRequestInfo.options
      successCallback: successCallback
      errorCallback: errorCallback
      responseType: "node"
    })
  end if
End Function


'wrapper around getSingleContentFromServer for use as a callback in the error modal
'@params: 4 index array containing params that should be passed to getSingleContentFromServer()
Function getSingleContentFromServerRetry(params)
  if type(params) = "roArray" and params.count() = 4
    if type(params[3]) = "roSGNode" and params[3].subtype() = "DetailScreen"
      params[3].isLoading = true
    end if
    getSingleContentFromServer(params[0], params[1], params[2])
  end if
End Function


Function onSingleContentResponseWithTracking(singleContent)
  setInContentCache(singleContent) ' adding the series content node into the content cache
  handleSingleContentResponse(singleContent, true)
End Function


Function onSingleContentResponseWithoutTracking(singleContent)
  setInContentCache(singleContent) ' adding the series content node into the content cache.
  handleSingleContentResponse(singleContent, false)
End Function


' @refreshedContent: ContentNode, a contentNode for a single piece of content, can be video or series
' @sendTracking: boolean, indicates if NavigateToPage and PageLoad events should be triggered from this function
Function handleSingleContentResponse(refreshedContent, sendTracking = true) As Void
  tubiLog("DetailScreenHelpers.handleSingleContentResponse")
  detailScreen = getTopDetailScreenFromStack()

  if detailScreen <> invalid and detailScreen.content.id = refreshedContent.id
    detailScreen.contentFetchError = false

    ' Replace the top of the detail screen content stack with the refreshed content
    oldContent = detailScreen.content

    history = getHistory(refreshedContent.id)
    ' Find a default episode to land on, in case no specific episode requested.
    ' NOTE: If the series is a daily, recurring series then we always want to go to the most recent
    if refreshedContent.type = m.constants.ui.contentTypes.series and refreshedContent.currentEpisodeId = "" and refreshedContent.isRecurring = false
      if oldContent <> invalid and oldContent.type = m.constants.ui.contentTypes.video
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
    else if refreshedContent.type = m.constants.ui.contentTypes.video and refreshedContent.seriesId <> invalid and refreshedContent.seriesId <> ""
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

    populateDetailScreen(detailScreen, refreshedContent)

    sendDetailScreenNavigateAndLoadEvent(detailScreen, refreshedContent, sendTracking)

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

'Send NavigateToPage event and pageLoad event for detail screen after content has been fetched.
'@detailScreen, roSGNode, a DetailScreen component to be populated
'@refreshedContent, roSGNode, detail content
'@sendTracking, boolean, to control whether to send Navigation and pageload events.
'                       (In case of deeplink, we insert the detail page on screenstack and we do not need to send Navigate to page or pageload event)
Function sendDetailScreenNavigateAndLoadEvent(detailScreen, refreshedContent, sendTracking = true)
  tubilog("DeeplinkHelpers.sendDetailScreenNavigateAndLoadEvent")

  if sendTracking = true
    loadTime = 0
    if refreshedContent.type = m.constants.ui.contentTypes.series
      loadTime = Int((Uptime(0) - detailScreen.trackingLoadStartTime) * 1000) 'in ms
    end if
    oldScreen = getHiddenScreen(1) 'we already pushed the details screen, so the previous screen is 1 screen below the top screen/details screen
    if oldScreen <> invalid
      screenTrackingNavigate(oldScreen.trackingPageInfo, detailScreen.trackingPageInfo, oldScreen.trackingComponentInfo)
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

  if detailScreen <> invalid and m.isScreenLoaded = false
    populateDetailScreen(detailScreen, detailScreen.content)
  end if

  if detailScreen <> invalid and detailScreen.isInFocusChain() = true
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

    showErrorModal(modalInfo, getSingleContentFromServerRetry, getSingleContentRetryParams)
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


Function getRelatedContent(content)
  ' get related (You May Also Like) content along with metadata for the content
  ' (but not if in any of the kids modes, since it won't be displayed)
  if content <> invalid and isKidsUIOn() = false
    relatedRequestInfo = m.cmsApi.relatedContentReqInfo(content.id, shouldKidsModeBeSentToServer())
    m.makeRequest({
      url: relatedRequestInfo.url
      requestType: m.constants.reqNames.getRelatedContent
      options: relatedRequestInfo.options
      successCallback: handleRelatedResponse
      responseType: "node"
      silenceCallbackWarnings: true
      contentId: content.id
    })
  end if
End Function


Function handleRelatedResponse(relatedContent)
  detailScreen = getTopDetailScreenFromStack()
  if detailScreen <> invalid and relatedContent <> invalid
    if detailScreen.content.id = relatedContent.id
      'After AutoPlay or refresh required and when pressing back from Player to detail screen
      'related content(YMAL) thumbnails are not loading. Resetting relatedContent node fixes the issue.
      detailScreen.relatedContent = invalid
      detailScreen.relatedContent = relatedContent
    end if
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
  if contentNode <> invalid and currentItemFocused <> invalid and currentItemFocused.count() = 2
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

  if seriesContent <> invalid and currentItemFocused <> invalid and currentItemFocused.count() = 2

    nextEpisode = findNextEpisode2dIndex(currentItemFocused, seriesContent)
    seasonIndex = nextEpisode[0]
    episodeIndex = nextEpisode[1]
    historyIds = getFieldFromGlobal("historyIds") ' get the history to avoid accessing m.global every time
    if historyIds <> invalid
      for i = seasonIndex to seriesContent.getChildCount() - 1
        season = seriesContent.getChild(i)
        for j = episodeIndex to season.getChildCount() - 1

          item = seriesContent.getchild(i).getChild(j)
          history = historyIds.findNode(item.id)

          if history <> invalid and history.nowPos <> invalid and history.nowPos <> 0
            nowPos = history.nowPos
          else
            nowPos = 0
          end if

          if item.creditsCuePoints <> invalid and item.creditsCuePoints.postlude <> invalid and nowPos < item.creditsCuePoints.postlude then
            return [i, j] ' first unwatched episode next to currently watched episode
          end if
        end for
        'bs:disable-next-line LINT1005
        episodeIndex = 0 'next season, so start from beginning
      end for


      'if we ran out of all the episodes, return first episode as next episode
      if i = seriesContent.getChildCount() - 1 and j = seriesContent.getChild(i).getChildCount() - 1
        nextEpisode = [0, 0]
      end if
    end if
  end if
  return nextEpisode
End Function



' returns episode detail as node, if episode detail not present it returns invalid
Function getEpisodeDetail(content)
  if content <> invalid
    if content.currentEpisodeId <> invalid and content.currentEpisodeId <> ""
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
    if content.currentEpisodeId <> invalid and content.currentEpisodeId <> ""
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
  if content <> invalid and content.type = m.constants.ui.contentTypes.series
    episode = getEpisodeContent(content)
  end if
  return episode
End Function


' Helper to deduce the content, video or episode, to play or resume
Function getDetailScreenContent(screen = invalid)
  if screen = invalid
    screen = getTopDetailScreenFromStack()
  end if

  if screen <> invalid and screen.subType() = "DetailScreen" and screen.content <> invalid
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
      dialogEvent = getDetailScreenDialogAnalyticEvent(content, "ADD_TO_QUEUE", "sign-in-bookmark", m.constants)

      title = getTranslation("screenDetails_error_addQueue_title")
      if content.type = m.constants.ui.contentTypes.series
        message = getTranslation("screenDetails_error_addQueueSeries_description")
      else
        message = getTranslation("screenDetails_error_addQueueMovie_description")
      end if
      buttons = [getTranslation("dialog_button_continue"), getTranslation("dialog_button_cancel")]
      showSimpleInstantResumableModal(title, message, buttons, dialogEvent, m.trackingLoggingTask, addToQueueSignInSelected)
    else if detailScreen <> invalid and detailScreen.isWaitingForServerResponse <> true
      detailScreen.stringQueueButton = getTranslation("screenDetails_button_queueNow")

      authInfo = getFieldFromGlobal("authInfo")
      userId = 0
      if authInfo <> invalid and authInfo.userId <> invalid
        userId = authInfo.userId.toInt()
      end if
      contentType = ""
      if detailScreen.content <> invalid and detailScreen.content["type"] = m.constants.ui.contentTypes.video
        contentType = m.constants.uapiContentTypes.movie
      else if detailScreen.content <> invalid and detailScreen.content["type"] = m.constants.ui.contentTypes.series
        contentType = m.constants.uapiContentTypes.series
      end if

      addToQueueReq = m.userDeviceApi.addToQueueReqInfo(userId, detailScreen.content.id, contentType)

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
  if type(params) = "roArray" and params.count() = 1
    onAddToQueue(params[0])
  end if
End Function


' bookmarkFailed triggered when bookmark fails for some reason
' @detailScreen: roSGNode, detail screen node
' @addBookmarkResult: assocarray, contains bookmarkId & response code
Function bookmarkFailed(detailScreen, addBookmarkResult)

  detailScreen.stringQueueButton = getTranslation("screenDetails_button_queue")
  content = getDetailScreenContent(detailScreen)

  responseCode = -1234
  if addBookmarkResult <> invalid
    responseCode = addBookmarkResult.code
  end if

  ' set up the error modal dialog
  errorCode = getUserFacingErrorCode(m.constants.errors.context.videoDetailScreen, m.constants.errors.subtypes.addBookmarkError, responseCode)
  dialogEvent = getDetailScreenDialogAnalyticEvent(content, "ADD_TO_QUEUE", errorCode, m.constants)
  if content.type = m.constants.ui.contentTypes.series
    message = getTranslation("screenDetails_error_queueSeries_description")
  else
    message = getTranslation("screenDetails_error_queueMovie_description")
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

      title = "Content"
      if isNonEmptyString(detailScreen.title) = true
        title = detailScreen.title
      end if
      description = title + " has been added to the List"

      showSimpleInstantResumableModal("Success", description, [], dialogEvent, m.trackingLoggingTask)

      ' re-fetch homescreen content when user signedIn
      homeScreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
      if homeScreen <> invalid
        fetchHomescreen(homeScreen)
      end if

      tubiLog("Got bookmarkId " + bookmarkId + " for content " + detailScreen.content.id)
      if response <> invalid and response.parsedresponse <> invalid and detailScreen.content.id.toInt() = response.parsedresponse.content_id
        setIsBookmark(detailScreen, true)
      end if

      sendBookmarkAnalytics(detailScreen.content, "ADD_TO_QUEUE", m.Tracking, m.trackingLoggingTask, m.constants)
      onHistoryQueueChange(m.constants.ui.categoryIds.queue)
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
      if hiddenScreen <> invalid and hiddenScreen.id = m.constants.ui.screenIds.detailScreen
        detailScreen = hiddenScreen
        bDetailScreenExistsInStack = true

        history = getHistory(detailScreen.content.id)

        if history <> invalid
          '//if user is signed out but has history of current item, make sure it has been less than guest user resume limit,
          '//   because beyond that time we are restricted legally from showing data of signed out users.

          if isGreaterThanGuestResumePeriod(history) = true
            '//Call populateDetailScreen() which will remove the resume button for any guest users that have content that has history over a day old
            populateDetailScreen(detailScreen, detailScreen.content)
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
  detailScreen.stringQueueButton = getTranslation("screenDetails_button_queue")
  detailScreen.stringNoQueueButton = getTranslation("screenDetails_button_noQueue")

  detailScreen.isBookmark = isBookmark
End Function


Function setIsHistory(detailScreen, isHistory)
  'reset the value in the case that remove from history button was pressed and title is currently "Removing..."
  detailScreen.stringNoHistoryButton = getTranslation("screenDetails_button_noHistory")
  detailScreen.isHistory = isHistory
End Function


Function onRemoveFromQueueSelected(msg)
  tubiLog("DetailScreenHelpers.onRemoveFromQueueSelected")
  detailScreen = msg.getRoSGNode()
  onRemoveFromQueue(detailScreen)
End Function


Function onRemoveFromQueue(detailScreen)
  tubiLog("DetailScreenHelpers.onRemoveFromQueue")
  if detailScreen <> invalid and detailScreen.isWaitingForServerResponse <> true
    content = detailScreen.content.clone(false)
    bookmark = m.global.bookmarkIds.findNode(content.id)
    if bookmark <> invalid
      detailScreen.stringQueueButton = getTranslation("screenDetails_button_removing")

      removeFromQueueReq = m.userDeviceApi.removeFromQueueReqInfo(bookmark.bookmarkId)

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
  if type(params) = "roArray" and params.count() = 1
    onRemoveFromQueue(params[0])
  end if
End Function


'''''''''''
' onLike
'
' Observer that is called when the like button is selected
Function onLike(msg)
  tubiLog("DetailScreenHelpers.onLike")
  detailScreen = msg.getRoSGNode()
  updateLikeDislike(detailScreen, m.constants.ui.likeDislikeActions.like)
End Function


Function onDislike(msg)
  tubiLog("DetailScreenHelpers.onDislike")
  detailScreen = msg.getRoSGNode()
  updateLikeDislike(detailScreen, m.constants.ui.likeDislikeActions.dislike)
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
  if type(params) = "roArray" and params.count() = 2
    updateLikeDislike(params[0], params[1])
  end if
End Function


' @param sRating, String: The like/dislike rating that the content like state should be changed. Or is the remove enum that will indicate the removal of the like/dislike state. The possible values are all under m.constants.ui.likeDislikeActions
Function updateLikeDislike(detailScreen, sRatingChange)
  if detailScreen <> invalid and detailScreen.isWaitingForServerResponse <> true
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
  if requestBody <> invalid and type(requestBody.data) = "roArray"
    returnedContentId = requestBody.data[0]
    sReturnedAction = requestBody.action
    m.Bookmarks.updateLikesLocally(returnedContentId, sReturnedAction, m.global)

    '//Tell Detail Screen how to react to user interacting with the like/dislike button
    if detailScreen <> invalid and detailScreen.content <> invalid
      if detailScreen.content.id <> invalid and returnedContentId <> invalid and returnedContentId = detailScreen.content.id
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
  detailScreen.likeDislikeState = sLikedState
End Function


Function onLikeChangedError(parsedReturn)
  tubiLog("DetailScreenHelpers.onLikeChangedError")
  code = parsedReturn.code
  returnedContentId = invalid
  returnedAction = invalid
  if parsedReturn.action <> invalid and parsedReturn.data <> invalid and parsedReturn.data.Count() > 0
    returnedContentId = parsedReturn.data[0]
    returnedAction = parsedReturn.action
  end if

  detailScreen = getTopDetailScreenFromStack()

  if detailScreen <> invalid and detailScreen.content <> invalid
    '//return the likeDislike button to the way it was before trying to unsuccessfully set the like/dislike
    currentScreen = getCurrentScreen()
    if currentScreen <> invalid and currentScreen.id = detailScreen.id
      detailScreen.isWaitingForServerResponse = false

      '//set back to the previous like state before the failed attempt
      sPreviousLikeState = getLike(detailScreen.id)
      setDetailScreenLikeDislikeStateFromLikeAction(detailScreen, sPreviousLikeState)

      '//Make sure the current screen is associated with the detail screen that caused the error
      if code <> invalid and detailScreen.content.id <> invalid and returnedContentId <> invalid and returnedContentId = detailScreen.content.id
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
  if detailScreen <> invalid and detailScreen.isWaitingForServerResponse <> true and detailScreen.content <> invalid
    contentId = detailScreen.content.id
    history = getHistory(contentId)

    authInfo = getFieldFromGlobal("authInfo")

    isLoggedInUser = isLoggedInUser(authInfo)

    if isLoggedInUser = true and  history <> invalid and isNonEmptyString(history.historyId) = true
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
  if type(params) = "roArray" and params.count() = 1
    onRemoveFromHistory(params[0])
  end if
End Function


Function onHistoryRemovedSuccess(_response) As Void
  tubiLog("DetailScreenHelpers.onHistoryRemoved")
  detailScreen = getTopDetailScreenFromStack()
  detailScreen.isWaitingForServerResponse = false
  setIsHistory(detailScreen, false)
  sendBookmarkAnalytics(detailScreen.content, "REMOVE_FROM_CONTINUE_WATCHING", m.Tracking, m.trackingLoggingTask, m.constants)
  onHistoryQueueChange(m.constants.ui.categoryIds.history)

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
  if detailScreen <> invalid and detailScreen.relatedContent <> invalid
    content = detailScreen.relatedContent.getChild(detailScreen.relatedContentSelected)
  end if

  if content <> invalid
    '//reset videoSponsorExposureId when going to a new detail screen
    m.videoSponsorExposureId = ""
    showDetailScreen(content, true)
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
    showEpisodeScreenWithNavigationTracking(detailScreen.content)
  end if
End Function


Function onSignUpButtonSelected(msg)
  tubiLog("DetailScreenHelper.onSignUpButtonSelected")
  setComponentInteractionEventForSignUp(msg.getRoSGNode())
  startSignIn(onRegistrationProcessCompletedOnDetailsScreen)
End function


'@screen, screen info after selecting signUp button
Function setComponentInteractionEventForSignUp(screen)
  tubiLog("DetailScreenHelper.setComponentInteractionEventForSignUp")
  componentValues = {
    button_type: "TEXT"
    button_value: "SIGNUP_TO_SAVE_PROGRESS" 'Button value is always upper case and concatinated by "_"
  }
  pageInfo = screen.trackingPageInfo
  componentInteractionInfo = {
    pageOneof: m.Tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
    componentOneof: m.Tracking.getAnalyticsComponent("button_component", componentValues)
    user_interaction: "CONFIRM"
  }
  sendComponentInteractionInfo(componentInteractionInfo)
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
  showEpisodeScreenWithoutNavigationTracking(screen.content)
End Function


Function trailerHelper(screen)
  content = screen.content

  if content <> invalid then
    bMature = isMatureRating(content)
    if isLoggedInUser() = false and bMature = true
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

      trailerContent.streamformat = "hls"
      trailerContent.nowPos = 0
      trailerContent.isTrailer = true

      if content.hasTrailer and content.trailerInfo <> invalid and content.trailerInfo.url <> invalid
        trailerContent.url = content.trailerInfo.url
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

  if task <> invalid and task.subType() = "DetailMetadataTask"
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

  if content <> invalid and content.type <> invalid
    if content.type = "series"
      episodeDetail = getEpisodeDetail(screen.content)
      if episodeDetail <> invalid and episodeDetail.url <> invalid and Len(episodeDetail.url) > 0
        if episodeDetail.validUntil <> invalid and episodeDetail.validUntil >= UpTime(0)
          bReturn = true
        end if
      end if
    else if content.type = "video" and content.url <> invalid and Len(content.url) > 0
      if content.validUntil <> invalid and content.validUntil >= UpTime(0)
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
  resumeVideoDetailScreen(detailScreen)
End Function


' @detailScreen: roSGNode, detail screen node
' @playbackSource: string, valid values are "automatic", "deliberate", "previews" or "unknown"
Function resumeVideoDetailScreen(detailScreen, playbackSource = "unknown")
  tubiLog("DetailScreenHelpers.resumeVideoDetailScreen")
  if detailScreen <> invalid and isFetchingInProgress(detailScreen) <> true
    detailScreen.playbackSource = playbackSource
    if isPlayable(detailScreen) = true
      resumeHelper(detailScreen)
    else
      m.actionType = resumeHelper
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
  playVideoDetailScreen(detailScreen)

End Function


' @detailScreen: roSGNode, detail screen node
' @playbackSource: string, valid values are "automatic", "deliberate", "previews" or "unknown"
Function playVideoDetailScreen(detailScreen, playbackSource = "unknown")
  tubiLog("DetailScreenHelpers.playVideoDetailScreen")
  if detailScreen <> invalid and isFetchingInProgress(detailScreen) <> true
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
  if content <> invalid and content.rating <> invalid
    sRating = UCase(content.rating)
    aRatings = m.constants.ui.matureRatings[m.constants.deviceInfo.countryCode]
    if aRatings <> invalid and aRatings.Count() > 0
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
  if episode <> invalid and screen.isLoading <> true then
    bMature = isMatureRating(episode)
    if isLoggedInUser() = false and bMature = true
      '//if user is a guest and is trying to play content geared for only adults, then ask them to register
      dialogSubtype = "mature-play"
      if m.deepLinkContent <> invalid
        '//this is a deeplink so, indicate that the warning originatated from a deeplink
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


Function resumeHelper(detailScreen)
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
  if isLoggedInUser() = false and bMature = true
    '//if user is a guest and is trying to play content geared for only adults, then ask them to register dialogSubtype = "mature-play"
    dialogSubtype = "mature-resume"
    if m.deepLinkContent <> invalid
      '//this is a deeplink so, indicate that the warning originatated from a deeplink
      dialogSubtype = "mature-resume-deep"
    end if
    displayDetailScreenMaturePlayWarning(episode, dialogSubtype)
  else
    nowPos = 0
    ' using nowPos that was passed in with deeplink, when playback initiated via deeplink
    if m.deeplinkContent <> invalid and episode.nowPos > 0
      nowPos = episode.nowPos
    else
      ' find the position in global history
      history = getHistory(episode.id)

      if history <> invalid and history.nowPos > 0
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
  subScreen = getHiddenScreen(1)

  trackingPageInfo = {}
  trackingComponentInfo = {}
  if subScreen <> invalid
    trackingPageInfo = subScreen.trackingPageInfo
    trackingComponentInfo = subScreen.trackingComponentInfo
  end if

  detailScreen = getTopDetailScreenFromStack()
  if detailScreen <> invalid
    populateDetailScreen(detailScreen, refreshedContent)
    if refreshedContent.type = m.constants.ui.contentTypes.series and refreshedContent.currentEpisodeId = "" and refreshedContent.isRecurring = false
      ' first see if there was a specific episode id we wanted
      history = getHistory(refreshedContent.id)
      if history <> invalid
        refreshedContent.currentEpisodeId = history.currentEpisodeId
      end if
    end if

    episode = getEpisodeContent(refreshedContent)

    if episode <> invalid
      if m.enteredFromDeepLink = true and m.deeplinkContent <> invalid
        sendDeeplinkAnalytics(m.deeplinkContent, episode, m.constants.deeplinks.entryPoints.video, m.Tracking, m.trackingLoggingTask, m.constants)
      end if
      nowPos = processResume(episode)
      if m.top.fadeInContentController = true
        if nowPos >= 0
          playVideoContentWhileSkippingDetailScreen(episode, nowPos, trackingPageInfo, trackingComponentInfo, detailScreen.playbackSource)
        end if
      else
        if nowPos > 0
          m.detailScreenAfterFn = resumeHelper
        else
          m.detailScreenAfterFn = playHelper
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
  if type(content) = "roSGNode" and content.isSubtype("ContentNode") = true
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
' @sLikeEventEnum: string, one of the valid event strngs as defined in events.protos -> enum ExplicitInteraction
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


Function onDetailScreenButtonToggleOn(msg)
  tubilog("DetailScreenHelpers.onDetailScreenButtonToggleOn")
  analyticsButtonValue = msg.getData()
  detailScreen = msg.getRoSGNode()

  if analyticsButtonValue <> "" and isDetailScreen(detailScreen) = true
    sendDetailMenuFocusAnalytics(detailScreen, analyticsButtonValue, "TOGGLE_ON")
  end if
End Function


Function onDetailScreenButtonToggleOff(msg)
  tubilog("DetailScreenHelpers.onDetailScreenButtonToggleOff")
  analyticsButtonValue = msg.getData()
  detailScreen = msg.getRoSGNode()

  if analyticsButtonValue <> "" and isDetailScreen(detailScreen) = true
    sendDetailMenuFocusAnalytics(detailScreen, analyticsButtonValue, "TOGGLE_OFF")
  end if
End Function


Function onDetailScreenButtonConfirm(msg)
  tubilog("DetailScreenHelpers.onDetailScreenButtonConfirm")
  analyticsButtonValue = msg.getData()
  detailScreen = msg.getRoSGNode()

  if analyticsButtonValue <> "" and isDetailScreen(detailScreen) = true
    sendDetailMenuFocusAnalytics(detailScreen, analyticsButtonValue, "CONFIRM")
  end if
End Function


' send out a call to analytics that a menu item has been focused or unfocused, or when the like/dislike menu has gained focus
' @param screen, the detail screen that is causing this analytics event
' @param sAnalyticsValue:String, The analytics string value that represent a menu item or menu being focused or unfocused
' @param sUserInteraction: The protos enum related to the user interaction
Function sendDetailMenuFocusAnalytics(screen, sAnalyticsValue, sUserInteraction)
  if sAnalyticsValue <> invalid and sAnalyticsValue <> ""
    componentInteractionEvent =  {
      pageOneof: {}
      componentOneof: {}
      user_interaction: sUserInteraction
    }

    pageInfo = screen.trackingPageInfo
    componentInteractionEvent.pageOneof = m.Tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)

    componentValues = {
      button_type: "TEXT"
      button_value: sAnalyticsValue
    }
    componentInteractionEvent.componentOneof = m.Tracking.getAnalyticsComponent("button_component", componentValues)


    m.trackingLoggingTask.trackEvent = {
      type: "component_interaction"
      values: componentInteractionEvent
    }
  end if
End Function


'send the navigateToPage and pageLoad analytics in the case of an error loading the details screen
Function sendDetailScreenErrorAnalytics(detailScreen)
  ' Handle navigate_to_page and page_load tracking for detail screen for error cases
  if detailScreen <> invalid and detailScreen.contentFetchError = false
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
  if type(content) = "roSGNode" and content.isSubtype("ContentNode") = true
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
  if content <> invalid and type(content.id) = "roString"
    if content.type = constants.ui.contentTypes.series
      pageInfo = {
        pageType: "series_detail_page"
        pageValues: {
          series_id: content.id.toInt()
        }
      }
    else if content.type = constants.ui.contentTypes.video
      pageInfo = {
        pageType: "video_page"
        pageValues: {
          video_id: content.id.toInt()
        }
      }
    end if
  end if
  return pageInfo
End Function


'make getRelatedContent call after autoplay to display the refreshed YMAL content
Function onAutoplaySingleContentResponse(refreshedContent)
  detailScreen = getTopDetailScreenFromStack()
  if refreshedContent <> invalid
    populateDetailScreen(detailScreen, refreshedContent)
    getRelatedContent(refreshedContent)
  end if
End Function


Function removeFromQueueSuccessResponse(_response)
  tubiLog("DetailScreenHelpers.removeFromQueueSuccessResponse")
  detailScreen = getTopDetailScreenFromStack()
  if detailScreen <> invalid
    detailScreen.isWaitingForServerResponse = false
    sendBookmarkAnalytics(detailScreen.content, "REMOVE_FROM_QUEUE", m.Tracking, m.trackingLoggingTask, m.constants)
  end if
  onHistoryQueueChange(m.constants.ui.categoryIds.queue)
End Function


Function removeFromQueueErrorResponse(error)
  tubiLog("DetailScreenHelpers.removeFromQueueErrorResponse")
  detailScreen = getTopDetailScreenFromStack()
  if detailScreen <> invalid
    detailScreen.isWaitingForServerResponse = false

    code = ""
    content = getDetailScreenContent(detailScreen)

    if content <> invalid and content.type = m.constants.ui.contentTypes.series
      message = getTranslation("screenDetails_error_noQueueSeries_description")
    else
      message = getTranslation("screenDetails_error_noQueueMovie_description")
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
    detailScreen.isWaitingForServerResponse = false

    if response <> invalid
      bookmarkId = response.id

      if bookmarkId <> invalid
        tubiLog("Got bookmarkId " + bookmarkId + " for content " + detailScreen.content.id)
        if response <> invalid and detailScreen.content.id.toInt() = response.content_id
          setIsBookmark(detailScreen, true)
        end if
        sendBookmarkAnalytics(detailScreen.content, "ADD_TO_QUEUE", m.Tracking, m.trackingLoggingTask, m.constants)
        onHistoryQueueChange(m.constants.ui.categoryIds.queue)
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
End Function
