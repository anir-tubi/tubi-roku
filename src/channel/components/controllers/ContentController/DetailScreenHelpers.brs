
'''''''''''''''''''''
' showDetailScreen
'
' @content: roSGNode, a content node for a single pieces of content, might be a video or top level series
' @sendTrackingOnResponse: boolean, set to true if the content needs to be fetched and NavigateToPageEvent and 
'                                   PlayProgressEvent analytics should be sent after fetching info from the backend.
Function showDetailScreen(content, sendTrackingOnResponse = true)
  tubiLog("DetailScreenHelpers.showDetailScreen")
  
  if content <> invalid
    detailScreen = CreateObject("roSGNode", "DetailScreen")
    detailScreen.id = m.constants.ui.screenIds.detailScreen
    detailScreen.trackingLoadStartTime = Uptime(0)
    detailScreen.shouldFocusWhenPushed = m.top.fadeInContentController
    detailScreen.observeFieldScoped("playSelected", "onPlay")
    detailScreen.observeFieldScoped("resumeSelected", "onResume")
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
    detailScreen.kidsModeEnabled = m.kidsModeEnabled
    setDetailStrings(detailScreen)

    ' Setting the content on the detail screen here prior to getting a response back from server with full info,
    ' so that it may be used for analytics in the case of failing to fetch the full info from the server.
    ' We expect to overwrite this in populateDetailScreen() which occurs after the full info has been fetched from the /content API
    detailScreen.content = content

    ' waiting to populate the details screen for series until after we fetch episode data
    if m.deepLinkContent <> invalid or content.type = m.constants.ui.contentTypes.series or (content.type = m.constants.ui.contentTypes.video and content.seriesId <> invalid and content.seriesId <> "")
      detailScreen.isLoading = true
    else
      populateDetailScreen(detailScreen, content, true)
    end if
    
    pushScreen(detailScreen, false, false)  ' don't send tracking until we resolve series episode
    getSingleContentFromServer(detailScreen, content, sendTrackingOnResponse)
  else
    ' TODO: Refer to logs to determine if it's necessary to show a modal in this instance informing the user to press the back
    ' back button. We shouldn't end up with an invalid content, but as of 11/25/18 there are crash logs
    ' that indicate it might be possible that getDetailScreenContent() as called by ContentController.returnToDetailScreenFromVideo()
    ' may return invalid, which may get passed to this function as the content argument.  
    message = "DetailScreenHelpers.showDetailScreen, content is invalid"
    tubiLog(message, "warn", "clientWarn", "showdetailscreen-invalid-content")
  end if
End Function

Function setDetailStrings(screen)
  screen.stringQueueButton = getTranslation("screenDetails_button_queue")
  screen.stringNoQueueButton = getTranslation("screenDetails_button_NoQueue")
  screen.stringNoHistoryButton = getTranslation("screenDetails_button_noHistory")
End Function

Function onDetailBackgroundChange(msg)
  tubiLog("DetailScreenHelpers.onDetailBackgroundChange")
  detailScreen = msg.getRoSGNode()
  if detailScreen.isInFocusChain()
    m.backgroundGroup.backgroundInfo = {
      type: m.constants.ui.backgroundTypes.fullScreen
      uriList: detailScreen.backgroundUriList
    }
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
      componentType: "detail_menu_component"    'doesn't actually exist in protos currently
      componentValues: {}
    }

    showChannelScreen(channelNode)
  end if
End Function


'detail screen has told us that the content or related content is out of cache window, so refresh
Function onRefreshContentSignal(msg)
  detailScreen = msg.getRoSGNode()
  getSingleContentFromServer(detailScreen, detailScreen.content, false)
End Function


'''''''''''''''''''''
' populateDetailScreen
'
'Populates the detail screen's state from a content node
'@detailScreen, roSGNode, a DetailScreen component to be populated
'@content: tubiContentNode, the content of the screen
'@shouldResetButtonIndex: boolean, helps to reset the focus index of menu items 
'@nSavedPosition: integer, The number representing the resume point of the video
Function populateDetailScreen(detailScreen, content, shouldResetButtonIndex=false, nSavedPosition = -1, bNewData=false)
  tubiLog("DetailScreenHelpers.populateDetailScreen")
  'initialize default background - will be overwritten later in most cases
  backgroundUriList = [m.defaultBackgroundUri]
  if type(detailScreen) = "roSGNode" and detailScreen.isSubType("DetailScreen") and type(content) = "roSGNode"
    'hide the spinner
    detailScreen.isLoading = false
    lineOneData = {}

    'update detail screen state via the input interface
    detailScreen.title = content.title
    detailScreen.genres = content.genres

    if content.hasTrailer = true
      detailScreen.hasTrailer = true
    end if

    bookmark = m.global.bookmarkIds.findNode(content.id)
    history = m.global.historyIds.findNode(content.id)

    episode = getEpisodeContent(content)
    episodeHistory = invalid
    if content.type = m.constants.ui.contentTypes.series
      if episode <> invalid
        episodeHistory = m.global.historyIds.findNode(episode.id)
        detailScreen.episodeTitle = episode.title
      end if

      lineOneData.type = m.constants.ui.contentTypes.series  
      lineOneData.seasons =  content.totalCount
      detailScreen.isSeries = true
      detailScreen.mode = "series"
    else
      detailScreen.isSeries = false
      detailScreen.mode = "movie"
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
    setIsHistory(detailScreen, (history <> invalid))
    '//::TODO:: HARDCODE:: right now in kids mode, there are no channels showing up, so hardcode it so the channel's button doesn't show
    detailScreen.isChannelItem = (content.channelId <> invalid and content.channelId <> "" and m.kidsModeEnabled = false)
    detailScreen.stringChannelButton = getTranslation("screenDetails_button_gotoChannel", {channel: content.channelName})
    detailScreen.length = stateSource.length  'needed to compute the resume bar on the resume button

    nResumePoint = 0
    if content.type = m.constants.ui.contentTypes.series and episodeHistory <> invalid and episodeHistory.nowPos > 0
      nResumePoint = episodeHistory.nowPos
    else if content.type = m.constants.ui.contentTypes.video and history <> invalid and history.nowPos > 0
      nResumePoint = history.nowPos
    end if

    if nSavedPosition >= 0
      '//If the saved position is passed as greater than 0 than use that number instead.
      '//This parameter was put in place to display the updated resume point before having to wait to backend to confirm that the resume point is correct
      nResumePoint = nSavedPosition
      if nSavedPosition > 0
        setIsHistory(detailScreen, true)
      end if
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
  end if

  detailScreen.backgroundUriList = backgroundUriList
  m.backgroundGroup.backgroundInfo = {
    type: m.constants.ui.backgroundTypes.fullScreen
    uriList: backgroundUriList
  }

  'update tracking info - have to set the whole AA, can't update only a portion on the AA field.
  'it is necessary to update trackingPageInfo here so that the correct pageInfo is stored in the case where a deeplink has an
  'episode content id, but the detail screen content will ultimately be a series content node. Updating here occurs when the
  'full content has been returned from the /contents API.
  detailScreen.trackingPageInfo = getDetailScreenAnalyticsPageInfo(content, m.constants)
  detailScreen.content = content
  
  if shouldResetButtonIndex = true
    detailScreen.jumpToItem = 0
  end if
  
  m.isScreenLoaded = true
End Function


'@screen: roSGNode, a detail screen node
'@content: roSGNode, a TubiContentNode
'@trackOnResponse: boolean, indicates if NavigateToPage and PageLoadTracking should occur when the response is received
Function getSingleContentFromServer(screen, content, trackOnResponse)
  tubiLog("DetailScreenHelpers.getSingleContentFromServer")
  if content <> invalid
    request = {
      contentId: content.id
      getRelated: false
      kidsMode: shouldKidsModeBeSentToServer()
      getContent: true
    }

    ' get related (You May Also Like) content along with metadata for the content
    if content.relatedContent = invalid
      request.getRelated = true
    end if

    callbackName = "onSingleContentResponseWithTracking"
    errorCallbackName = "onSingleContentErrorWithTracking"
    if trackOnResponse = false
      callbackName = "onSingleContentResponseWithoutTracking"
      errorCallbackName = "onSingleContentErrorWithoutTracking"
    end if

    refreshTask = CreateObject("roSGNode", "DetailMetadataTask")
    refreshTask.request = request
    refreshTask.addField("target", "node", false)
    refreshTask.target = screen
    screen.addField("task", "node", false)
    screen.task = refreshTask
    refreshTask.observeField("response", callbackName)
    refreshTask.observeField("error", errorCallbackName)
    refreshTask.control = "RUN"
  end if
End Function


'wrapper around getSingleContentFromServer for use as a callback in the error modal
'@params: 2 index array containing params that should be passed to getSingleContentFromServer()
Function getSingleContentFromServerRetry(params)
  if type(params) = "roArray" and params.count() = 3
    params[0].isLoading = true
    getSingleContentFromServer(params[0], params[1], params[2])
  end if
End Function


Function onSingleContentResponseWithTracking(msg)
  handleSingleContentResponse(msg, true)
End Function


Function onSingleContentResponseWithoutTracking(msg)
  handleSingleContentResponse(msg, false)
End Function


' @withTracking: boolean, indicates if NavigateToPage and PageLoad events should be triggered from this function
Function handleSingleContentResponse(msg, sendTracking = true) As Void
  tubiLog("DetailScreenHelpers.handleSingleContentResponse")
  task = msg.getRoSGNode()
  detailScreen = task.target
  detailScreen.contentFetchError = false
  detailScreen.task = invalid

  task.unobserveField("response")
  task.unobserveField("error")

  ' Replace the top of the detail screen content stack with the refreshed content
  refreshedContent = msg.GetData()
  oldContent = detailScreen.content
  afterFn = invalid  ' the Function to execute once we've sorted the detail screen out
  history = m.global.historyIds.findNode(refreshedContent.id)

  if m.deepLinkContent <> invalid
    if m.deepLinkContent.nowPos = 0 and history <> invalid and history.nowPos > 0
     ' Use the deeplink content's history to resume a deeplinked video if a resumeTime parameter wasn't sent in as part of the deeplink
      m.deepLinkContent.nowPos = history.nowPos
    end if

    if m.deepLinkContent.deeplinkType = "series" and refreshedContent.type = m.constants.ui.contentTypes.series
      '  refreshedContent.id:       series id
      '  refreshedContent.seriesId: invalid
      '  refreshedContent.type:     series
      '  m.deepLinkContent.deepLinkType: series

      ' As of spring 2018 (firmware 8.1), "series" media types are valid and
      ' will have a content id of an episode, not the series.  Roku states that
      ' the episode id is NOT what should be played, rather we are allowed
      ' to choose the most appropriate episode and automatically start playback.
      ' Here we use the history to choose an episode or just default to the first one.
      afterFn = playHelper
      if history <> invalid
        refreshedContent.currentEpisodeId = history.currentEpisodeId
        episode = getEpisodeContent(refreshedContent)
        episodeHistory = invalid
        if episode <> invalid
          episodeHistory = m.global.historyIds.findNode(episode.id)
        end if
        if episodeHistory <> invalid and episodeHistory.nowPos > 0
          afterFn = resumeHelper
        end if
      else
        refreshedContent.currentEpisodeId = ""
      end if
      
      if m.enteredFromDeepLink = true
        ' m.enteredFromDeepLink will be set to false when the video is played
        sendDeeplinkAnalytics(m.deepLinkContent, refreshedContent, "video", m.Tracking, m.trackingLoggingTask, m.constants)
      end if
    else if (m.deepLinkContent.deeplinkType = "season" or m.deepLinkContent.deeplinkType = "episode" or m.deepLinkContent.deeplinkType = "series") and refreshedContent.type = m.constants.ui.contentTypes.video
      '  refreshedContent.id =       episode id
      '  refreshedContent.seriesId = series id
      '  refreshedContent.type =     video
      '  m.deepLinkContent.deepLinkType = season | episode | series

      ' deeplink sent us an episode id, so here, we have full info for an episode, but we need full info for a series
      ' don't send deeplink analytics here, we will send it once we get the refreshedContent (response from getSingleContentFromServer())
      emptySeriesNode = CreateObject("roSGNode", "TubiContentNode")
      emptySeriesNode.type = m.constants.ui.contentTypes.series
      emptySeriesNode.id = refreshedContent.seriesId
      getSingleContentFromServer(detailScreen, emptySeriesNode, false)
      return
    else if m.deepLinkContent.deeplinkType = "season" and refreshedContent.type = m.constants.ui.contentTypes.series
      '  refreshedContent.id =       series id
      '  refreshedContent.seriesId = invalid
      '  refreshedContent.type =     series
      '  m.deepLinkContent.deepLinkType = season

      ' we've now received the full series info, so we can build the relevant screens
      refreshedContent.currentEpisodeId = m.deepLinkContent.id
      ' when deeplinkType = "season", deeplinkContent.id should be an episode id. We want to send tracking with the series id.
      m.deepLinkContent.id = refreshedContent.id
      afterFn = episodesHelper

      if m.enteredFromDeepLink = true
        sendDeeplinkAnalytics(m.deepLinkContent, refreshedContent, "episodeList", m.Tracking, m.trackingLoggingTask, m.constants)
        m.enteredFromDeepLink = false
      end if
    else if m.deepLinkContent.deeplinkType = "episode" and refreshedContent.type = m.constants.ui.contentTypes.series
      '  refreshedContent.id =       series id
      '  refreshedContent.seriesId = invalid
      '  refreshedContent.type =     series
      '  m.deepLinkContent.deepLinkType = episode

      ' we now have the full series info for episode deeplinks
      refreshedContent.currentEpisodeId = m.deepLinkContent.id
      'determine if we need to resume or play from start the deeplinked episode
      if m.deepLinkContent.nowPos <> invalid and m.deepLinkContent.nowPos > 0
        episode = getEpisodeContent(refreshedContent)
        episode.nowPos = m.deepLinkContent.nowPos
        afterFn = resumeHelper
      else
        afterFn = playHelper
      end if

      if m.enteredFromDeepLink = true
        ' m.enteredFromDeepLink will be set to false when the video is played
        sendDeeplinkAnalytics(m.deepLinkContent, refreshedContent, "video", m.Tracking, m.trackingLoggingTask, m.constants)
      end if
    else if m.deepLinkContent.deeplinkType = "movie"
      'determine if we need to resume or play from start the deeplinked movie
      if m.deepLinkContent.nowPos <> invalid and m.deepLinkContent.nowPos > 0
        refreshedContent.nowPos = m.deepLinkContent.nowPos
        afterFn = resumeHelper
      else
        afterFn = playHelper
      end if

      if m.enteredFromDeepLink = true
        ' m.enteredFromDeepLink will be set to false when the video is played
        sendDeeplinkAnalytics(m.deepLinkContent, refreshedContent, "video", m.Tracking, m.trackingLoggingTask, m.constants)
      end if
    else
      'start the channel normally in case of issues
      'handle deeplinking tracking when landing on category/home screen
      if m.enteredFromDeepLink = true
        sendDeeplinkAnalytics(m.deepLinkContent, refreshedContent, "home", m.Tracking, m.trackingLoggingTask, m.constants)
        m.enteredFromDeepLink = false
      end if
      m.deepLinkContent = invalid
      startChannel()
      return
    end if
  else
    ' Find a default episode to land on, in case no specific episode requested from deep link
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
      getSingleContentFromServer(detailScreen, emptySeriesNode, sendTracking)
      return
    end if
    
    if afterFn = invalid
      afterFn = m.actionType
    end if
    m.actionType = invalid
    
  end if
  populateDetailScreen(detailScreen, refreshedContent)  

  loadTime = 0
  if refreshedContent.type = m.constants.ui.contentTypes.series
    loadTime = Int((Uptime(0) - detailScreen.trackingLoadStartTime) * 1000)  'in ms
  end if

  if sendTracking = true
    oldScreen = getHiddenScreen(1)  'we already pushed the details screen, so the previous screen is 1 screen below the top screen/details screen
    if oldScreen <> invalid
      screenTrackingNavigate(oldScreen.trackingPageInfo, detailScreen.trackingPageInfo, oldScreen.trackingComponentInfo)
    end if
    screenTrackingLoad(detailScreen.trackingPageInfo, loadTime)
  end if

  ' making sure the app launch animation logo is completed before invoking playHelper/resumeHelper
  if m.top.fadeInContentController = true or afterFn = episodesHelper
    if afterFn <> invalid
      afterFn(detailScreen)
    end if
  else
    m.detailScreenAfterFn = afterFn    
  end if
End Function


Function onSingleContentErrorWithTracking(msg)
  handleSingleContentError(msg, true)
End Function


Function onSingleContentErrorWithoutTracking(msg)
  handleSingleContentError(msg, false)
End Function


' @trackOnResponse: boolean, if the retry is succesful, should NavigateToPage and PageLoad tracking occur
Function handleSingleContentError(msg, trackOnResponse)
  error = msg.GetData()
  task = msg.getRoSGNode()
  detailScreen = task.target
  detailScreen.task = invalid
  tubiLog("DetailScreenHelpers.onSingleContentError")
  
  if m.isScreenLoaded = false
    populateDetailScreen(detailScreen, detailScreen.content)
  end if

  content = invalid
  if task.request <> invalid 
    content = task.request.content
  end if
  task.unobserveField("response")
  task.unobserveField("error")
  task = invalid
  ' Roku requires that errors are not shown for invalid content ids when deep linking
  if m.enteredFromDeepLink = true
    m.enteredFromDeepLink = false
    popScreen(false, false)
    content = getDetailScreenContent(detailScreen)
    sendDeeplinkAnalytics(m.deepLinkContent, content, "home", m.Tracking, m.trackingLoggingTask, m.constants)
    m.deepLinkContent = invalid
    startChannel()
  else if m.deepLinkContent <> invalid
    ' we are in this block if there is a roInputEvent causing a deeplink (ie. voice control while the channel is open)
    ' In this case we should navigate back to the home page.
    sendDetailScreenErrorAnalytics(detailScreen)
    detailScreen = invalid  'release reference to the detailScreen as it is no longer needed
    m.deepLinkContent = invalid
    startChannel()
  else if detailScreen.isInFocusChain() = true
    message = getTranslation("screenDetails_error_getContent_description")
    content = getDetailScreenContent(detailScreen)
  
    ' set up the error modal dialog
    errorCode = getUserFacingErrorCode(m.constants.errors.context.videoDetailScreen, m.constants.errors.subtypes.fetchError, error.code)
    dialogEvent = getDetailScreenDialogAnalyticEvent(content, "NETWORK_ERROR", errorCode, m.constants)

    modalInfo = {
      message: getErrorMessage(message, errorCode)
      openTrackEvent: dialogEvent
      trackingTask: m.trackingLoggingTask
    }

    getSingleContentParams = [
      detailScreen
      content
      trackOnResponse
    ]

    showErrorModal(modalInfo, getSingleContentFromServerRetry, getSingleContentParams)
    detailScreen.isLoading = false

    sendDetailScreenErrorAnalytics(detailScreen)
  end if

  if detailScreen <> invalid
    detailScreen.contentFetchError = true
  end if
End Function


'@contentNode is a TubiContentNode, expected to be used only on series content nodes
Function findEpisode2dIndex(episodeId As String, contentNode As Object)
  if episodeId <> invalid
    for i=0 to contentNode.getChildCount()-1
      season = contentNode.getChild(i)
      for j=0 to season.getChildCount()-1
        episode = season.getChild(j)
        if episode.id = episodeId then
          tubiLog("Episode is [" + stri(i) + "," + stri(j) + "]")
          return [i,j]
        end if
      end for
    end for
  end if
  return [0,0]
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
  return content
End Function


' given a content node, return invalid for movie, or the metadata for the episode to be displayed on the details screen
' @content: tubiContentNode - video or series
Function getCurrentEpisode(content)
  episode = invalid
  if content <> invalid and content.type = m.constants.ui.contentTypes.series
    history = m.global.historyIds.findNode(content.id)
    detailScreen2dIndex = [0,0]
    if history <> invalid
      detailScreen2dIndex = findEpisode2dIndex(history.currentEpisodeId, content)
    end if
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
  screenStackDepth = 1
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


Function onAddToQueue(detailScreen)
  tubiLog("DetailScreenHelpers.onAddToQueue")
  if m.global.authInfo = invalid
   
    ' this will be used to trigger the callback function once the activation is completed via Detail Screen
    detailScreen.actionAfterActivation = "AddQueueMenuItem"
  
    content = getDetailScreenContent(detailScreen)
    dialogEvent = getDetailScreenDialogAnalyticEvent(content, "ADD_TO_QUEUE", "sign-in-bookmark", m.constants)

    title =  getTranslation("screenDetails_error_addQueue_title")
    if content.type = m.constants.ui.contentTypes.series
      message = getTranslation("screenDetails_error_addQueueSeries_description")
    else
      message = getTranslation("screenDetails_error_addQueueMovie_description")
    end if
    buttons = [getTranslation("dialog_button_continue"), getTranslation("dialog_button_cancel")]
    showSimpleModal(title, message, buttons, dialogEvent, m.trackingLoggingTask, onSignInModalButtonSelected)
  else if detailScreen <> invalid and detailScreen.isWaitingForServerResponse <> true
    detailScreen.stringQueueButton = getTranslation("screenDetails_button_queueNow")
    userTask = CreateObject("roSGNode", "AuthTask")
    userTask.functionName = "addToQueue"
    userTask.content = detailScreen.content
    userTask.isKidsMode = shouldKidsModeBeSentToServer()
    userTask.addField("target", "node", false)
    userTask.target = detailScreen
    detailScreen.addField("task", "node", false)
    detailScreen.task = userTask
    userTask.observeField("addBookmarkResult", "onBookmarked")
    userTask.control = "RUN"
    detailScreen.isWaitingForServerResponse = true
  end if
End Function


'Wraps onAddToQueueSelected in the case of an error modal and a user attempting to retry adding the content to their queue
Function onAddToQueueRetry(params)
  if type(params) = "roArray" and params.count() = 1
    onAddToQueue(params[0])
  end if
End Function


''''''''''''''''''
' onBookmarked

Function onBookmarked(msg) As Void
  tubiLog("DetailScreenHelpers.onBookmarked")
  task = msg.getRoSGNode()
  detailScreen = task.target
  addBookmarkResult = task.addBookmarkResult

  bookmarkId = ""
  if addBookmarkResult <> invalid
    bookmarkId = addBookmarkResult.bookmarkId
  end if

  task.unobserveFieldScoped("addBookmarkResult")
  detailScreen.task = invalid
  detailScreen.isWaitingForServerResponse = false
  if bookmarkId = invalid or bookmarkId = ""
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
    return
  else
  
    if detailScreen.actionAfterActivation = "AddQueueMenuItem"
      pageInfo = detailScreen.trackingPageInfo
      dialogEvent = {
      type: "dialog"
        values: {
        dialog_type: "ADD_TO_QUEUE"
        pageOneof: m.Tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
        dialog_action: "SHOW"
        dialog_sub_type: "add-queue-success"
        }
      }  
      title = "Content"
      if detailScreen.title <> invalid and detailScreen.title <> ""
        title = detailScreen.title
      end if
      description = title + " has been added to the List"
      
      showSimpleModal("Success", description, [], dialogEvent, m.trackingLoggingTask)
    end if  
    
  end if
  
  ' it resets the actionAfterActivation once the callback method is triggered
  detailScreen.actionAfterActivation = ""

  tubiLog("Got bookmarkId " + bookmarkId + " for content " + detailScreen.content.id)
  setIsBookmark(detailScreen, true)

  sendBookmarkAnalytics(detailScreen.content, "ADD_TO_QUEUE", m.Tracking, m.trackingLoggingTask, m.constants)
  onHistoryQueueChange(m.constants.ui.categoryIds.queue)
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
    detailScreen.stringQueueButton = getTranslation("screenDetails_button_removing")
    userTask = CreateObject("roSGNode", "AuthTask")
    userTask.functionName = "removeFromQueue"
    content = detailScreen.content.clone(false)
    bookmark = m.global.bookmarkIds.findNode(content.id)
    content.bookmarkId = bookmark.bookmarkId
    userTask.content = content
    userTask.isKidsMode = shouldKidsModeBeSentToServer()
    userTask.addField("target", "node", false)
    userTask.target = detailScreen
    detailScreen.addField("task", "node", false)
    detailScreen.task = userTask
    userTask.observeFieldScoped("result", "onBookmarkRemoved")
    userTask.control = "RUN"
    detailScreen.isWaitingForServerResponse = true
  end if
End Function


'Wraps onAddToQueueSelected in the case of an error modal and a user attempting to retry removing the content from their queue
Function onRemoveFromQueueRetry(params)
  if type(params) = "roArray" and params.count() = 1
    onRemoveFromQueue(params[0])
  end if
End Function


Function onBookmarkRemoved(msg) As Void
  tubiLog("DetailScreenHelpers.onBookmarkRemoved")
  task = msg.getRoSGNode()
  detailScreen = task.target
  result = task.result
  task.unobserveField("result")
  detailScreen.task = invalid
  detailScreen.isWaitingForServerResponse = false

  if result = invalid or result.response.code <> 204 then
    code = ""
    content = getDetailScreenContent(detailScreen)
    
    if content.type = m.constants.ui.contentTypes.series
      message = getTranslation("screenDetails_error_noQueueSeries_description")
    else
      message = getTranslation("screenDetails_error_noQueueMovie_description")
    end if

    if result <> invalid
      code = result.response.code
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
    return
  end if

  sendBookmarkAnalytics(detailScreen.content, "REMOVE_FROM_QUEUE", m.Tracking, m.trackingLoggingTask, m.constants)
  onHistoryQueueChange(m.constants.ui.categoryIds.queue)
End Function


Function onRemoveFromHistorySelected(msg)
  tubiLog("DetailScreenHelpers.onRemoveFromHistorySelected")
  detailScreen = msg.getRoSGNode()
  onRemoveFromHistory(detailScreen)
End Function


Function onRemoveFromHistory(detailScreen)
  if detailScreen <> invalid and detailScreen.isWaitingForServerResponse <> true
    history = m.global.historyIds.findNode(detailScreen.content.id)
    if history <> invalid and history.historyId <> invalid
      content = detailScreen.content.clone(false)
      detailScreen.stringNoHistoryButton = getTranslation("screenDetails_button_removing")
      content.historyId = history.historyId
      if m.userTask <> invalid
        m.NodeHelpers.unobserveAllScoped(m.userTask)
      end if
      userTask = CreateObject("roSGNode", "AuthTask")
      userTask.functionName = "removeFromHistory"
      userTask.content = content
      userTask.isKidsMode = shouldKidsModeBeSentToServer()
      userTask.addField("target", "node", false)
      userTask.target = detailScreen
      detailScreen.addField("task", "node", false)
      detailScreen.task = userTask
      userTask.observeField("result", "onHistoryRemoved")
      userTask.control = "RUN"
      detailScreen.isWaitingForServerResponse = true
    end if
  end if
End Function


'Wraps onRemoveFromHistorySelected in the case of an error modal and a user attempting to retry removing the content from their history
Function onRemoveFromHistoryRetry(params)
  if type(params) = "roArray" and params.count() = 1
    onRemoveFromHistory(params[0])
  end if
End Function


Function onHistoryRemoved(msg) As Void
  tubiLog("DetailScreenHelpers.onHistoryRemoved")
  task = msg.getRoSGNode()
  detailScreen = task.target
  result = task.result
  task.unobserveField("result")
  detailScreen.task = invalid
  detailScreen.isWaitingForServerResponse = false

  if result = invalid or result.response.code <> 204 then
    code = ""
    message = getTranslation("screenDetails_error_noHistory_description")
    if result <> invalid
      code = result.response.code
    end if
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
    return
  end if
  
  setIsHistory(detailScreen, false)
  sendBookmarkAnalytics(detailScreen.content, "REMOVE_FROM_CONTINUE_WATCHING", m.Tracking, m.trackingLoggingTask, m.constants)
  onHistoryQueueChange(m.constants.ui.categoryIds.history)
End Function


Function onRelatedContentSelected(msg)
  detailScreen = msg.getRoSGNode()

  content = invalid
  if detailScreen <> invalid and detailScreen.content <> invalid and detailScreen.content.relatedContent <> invalid
    content = detailScreen.content.relatedContent.getChild(detailScreen.relatedContentSelected)
  end if

  if content <> invalid
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
  tubiLog("ContentController.onEpisodeList")
  detailScreen = msg.getRoSGNode()

  episodeDetail = getEpisodeDetail(detailScreen.content)
  if episodeDetail = invalid
    m.actionType = episodesHelper
    detailScreen.isLoading = true
    getSingleContentFromServer(detailScreen, detailScreen.content, false) 
  else 
    showEpisodeScreenWithNavigationTracking(detailScreen.content) 
  end if
End Function


Function onDescriptionSelected(msg)
  tubiLog("DetailScreenHelper.onDescriptionSelected")
  detailScreen = msg.getRoSGNode()
  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: "INFORMATION"  'TODO: Use the "VIDEO_DESCRIPTION" option when it is added to protos
      pageOneof: m.Tracking.getAnalyticsPage("video_page", {video_id: detailScreen.content.id.toInt()})
      dialog_action: "SHOW"  'Action enum
      dialog_sub_type: "video-description"  'max 20 character string
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
    if m.global.authInfo = invalid and bMature = true
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
        getSingleContentFromServer(detailScreen, detailScreen.content, false)
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
  content = screen.content
  
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
  task = screen.task
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

  if isFetchingInProgress(detailScreen) <> true
    if isPlayable(detailScreen) = true
      resumeHelper(detailScreen)      
    else
      m.actionType = resumeHelper
      detailScreen.isLoading = true
      getSingleContentFromServer(detailScreen, detailScreen.content, false)
    end if   
  end if
End Function


'''''''''''
' onPlay
'
' Notify the main Brightscript thread to invoke the video player if data present
' if data not present, it invokes content api
Function onPlay(msg)
  tubiLog("ContentController.onPlay")
  detailScreen = msg.getRoSGNode()

  if isFetchingInProgress(detailScreen) <> true
    if isPlayable(detailScreen) = true
      playHelper(detailScreen)      
    else
      m.actionType = playHelper
      detailScreen.isLoading = true
      getSingleContentFromServer(detailScreen, detailScreen.content, false)
    end if   
  end if
End Function


'Is the rating of the content in the passed screen set for mature audience? 
Function isMatureRating(content)
  if content <> invalid and content.rating <> invalid
    sRating = UCase(content.rating)
    aRatings = m.constants.ui.matureRatings[m.constants.deviceInfo.countryCode]
    if aRatings <> invalid and aRatings.Count() > 0
      for i=0 to aRatings.Count()-1
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
    if m.global.authInfo = invalid and bMature = true
      '//if user is a guest and is trying to play content geared for only adults, then ask them to register 
      dialogSubtype = "mature-play"
      if m.deepLinkContent <> invalid
        '//this is a deeplink so, indicate that the warning originatated from a deeplink
        dialogSubtype = "mature-play-deep"
      end if
      displayDetailScreenMaturePlayWarning(episode, dialogSubtype)
    else
      playVideoContent(episode)
    end if
  else
    tubiLog("ERROR: Play selected but content is invalid")
  end if
End Function


Function resumeHelper(detailScreen)
  episode = getEpisodeContent(detailScreen.content)
  if episode <> invalid then
    bMature = isMatureRating(episode)
    if m.global.authInfo = invalid and bMature = true
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
        history = m.global.historyIds.findNode(episode.id)
        if history <> invalid and history.nowPos > 0
          nowPos = history.nowPos
        end if
      end if
      playVideoContent(episode, "none", nowPos)
    end if
  else
    tubiLog("ERROR: Resume selected but content is invalid")
  end if
End Function


' Organizes the information needed to create a "referred" tracking event and sends the information to the trackingTask which will
' actually send the event.
'
' @deepLinkContent: roSGNode, a content node created by deeplink logic and passed to the content controller via m.deeplinkContent
' @refreshedContent: roSGNode, a content node containing full information from the /content API
' @entryPoint: string, indicates where the user will land after the deeplink, can be one of: "detail", "home", "episodeList", "video"
' @trackingLib: associativeArray, an instance of TubiTracking()
' @trackingTask: roSGNode, an instance of the TrackingLoggingTask
' @constants: associativeArray, m.constants
Function sendDeeplinkAnalytics(deepLinkContent, refreshedContent, entryPoint, trackingLib, trackingTask, constants)
  referredAnalyticsEvent = {
    referred_type: "DEEP_LINK"
    campaign: deepLinkContent.campaign
    source: deepLinkContent.source
    medium: deepLinkContent.medium
    source_device_id: deeplinkContent.sourceDeviceId
  }

  pageInfo = getDetailScreenAnalyticsPageInfo(refreshedContent, constants)

  if entryPoint = "detail"
    referredAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
  else if entryPoint = "home"
    referredAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage("home_page", {})
  else if entryPoint = "episodeList"
    if deepLinkContent <> invalid and type(deepLinkContent.id) = "roString"
      seriesId = deeplinkContent.id.toInt()
      referredAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage("episode_video_list_page", {series_id: seriesId})
    end if
  else if entryPoint = "video"
    referredAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
  end if

  trackingTask.trackEvent = {
    type: "referred"
    values: referredAnalyticsEvent
  }
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


'send the navigateToPage and pageLoad analytics in the case of an error loading the details screen
Function sendDetailScreenErrorAnalytics(detailScreen)
  ' Handle navigate_to_page and page_load tracking for detail screen for error cases
  if detailScreen <> invalid and detailScreen.contentFetchError = false
    oldScreen = getHiddenScreen(1)  'we already pushed the details screen, so the previous screen is 1 screen below the top screen/details screen
    if oldScreen <> invalid
      screenTrackingNavigate(oldScreen.trackingPageInfo, detailScreen.trackingPageInfo, oldScreen.trackingComponentInfo)
    end if
    loadTime = Int((Uptime(0) - detailScreen.trackingLoadStartTime) * 1000)  'in ms
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
