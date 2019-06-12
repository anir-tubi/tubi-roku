
'''''''''''''''''''''
' showDetailScreen
'
' @content: roSGNode, a content node for a single pieces of content, might be a video or top level series
Function showDetailScreen(content)
  tubiLog("DetailScreenHelpers.showDetailScreen")
  if content <> invalid
    detailScreen = CreateObject("roSGNode", "DetailScreen")
    detailScreen.trackingLoadStartTime = Uptime(0)
    detailScreen.observeFieldScoped("playSelected", "onPlay")
    detailScreen.observeFieldScoped("resumeSelected", "onResume")
    detailScreen.observeFieldScoped("watchTrailerSelected", "onWatchTrailer")
    detailScreen.observeFieldScoped("episodeListSelected", "onEpisodeList")
    detailScreen.observeFieldScoped("addToQueueSelected", "onAddToQueueSelected")
    detailScreen.observeFieldScoped("removeFromQueueSelected", "onRemoveFromQueueSelected")
    detailScreen.observeFieldScoped("removeFromHistorySelected", "onRemoveFromHistorySelected")
    detailScreen.observeFieldScoped("itemFailed", "onDetailItemFailed")
    detailScreen.observeFieldScoped("backButtonPressed", "onDetailBackPressed")
    detailScreen.observeFieldScoped("relatedContentSelected", "onRelatedContentSelected")
    detailScreen.observeFieldScoped("backgroundUriList", "onDetailBackgroundChange")
    detailScreen.observeFieldScoped("channelSelected", "onDetailScreenChannelSelected")
    detailScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
    detailScreen.observeFieldScoped("refreshContent", "onRefreshContentSignal")
    m.refreshingDetailCache = false

    if m.top.deepLinkContent <> invalid or content.type = m.constants.ui.contentTypes.series or (content.type = m.constants.ui.contentTypes.video and content.seriesId <> invalid and content.seriesId <> "")
      detailScreen.isLoading = true
    else
      populateDetailScreen(detailScreen, content, true)
    end if
  
    pushScreen(detailScreen, false, false)  ' don't send tracking until we resolve series episode
    getSingleContentFromServer(detailScreen, content)
  else
    ' TODO: Refer to logs to determine if it's necessary to show a modal in this instance informing the user to press the back
    ' back button. We shouldn't end up with an invalid content, but as of 11/25/18 there are crash logs
    ' that indicate it might be possible that getDetailScreenContent() as called by ContentController.returnToDetailScreenFromVideo()
    ' may return invalid, which may get passed to this function as the content argument.  
    message = "DetailScreenHelpers.showDetailScreen, content is invalid"
    tubiLog(message, "warn", "clientWarn", "showdetailscreen-invalid-content")
  end if
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
  m.refreshingDetailCache = true
  getSingleContentFromServer(detailScreen, detailScreen.content)
End Function


'''''''''''''''''''''
' populateDetailScreen
'
'Populates the detail screen's state from a content node
'@content: tubiContentNode
Function populateDetailScreen(detailScreen, content, resetButtonIndex=false, nSavedPosition = -1)
  tubiLog("DetailScreenHelpers.populateDetailScreen")
  'initialize default background - will be overwritten later in most cases
  backgroundUriList = [m.defaultBackgroundUri]


  if type(detailScreen) = "roSGNode" and detailScreen.isSubType("DetailScreen") and type(content) = "roSGNode"
    'hide the spinner
    wasLoading = detailScreen.isLoading
    detailScreen.isLoading = false

    'update detail screen state via the input interface
    detailScreen.title = content.title
    detailScreen.genres = content.genres

    if content.hasTrailer = true
      if getExperimentValue("RokuNamespace", "roku_trailers") = "on"
        detailScreen.hasTrailer = content.hasTrailer
      else
        detailScreen.hasTrailer = false
      end if
    else
      detailScreen.hasTrailer = false
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

    lineOneData = {}
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
    if content.availabilityEnds <> invalid
      lineOneData.availabilityEnds = content.availabilityEnds
    end if
    detailScreen.lineOneData = lineOneData

    detailScreen.description = stateSource.description
    detailScreen.directors = stateSource.directors
    detailScreen.starring = stateSource.actors

    detailScreen.isBookmark = (bookmark <> invalid)
    detailScreen.isHistory = (history <> invalid)
    detailScreen.isChannelItem = (content.channelId <> invalid and content.channelId <> "")
    detailScreen.channelName = content.channelName
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
        detailScreen.isHistory = true
      end if
    end if
    detailScreen.resumePoint = nResumePoint

    'tell the detail screen/info panel to vertically center the info panel
    detailScreen.calculateInfoHeight = true

    detailScreen.relatedContent = content.relatedContent

    if wasLoading or resetButtonIndex
      detailScreen.jumpToItem = 0
    end if

    'update the background images for the detail screen
    if content.backgrounds <> invalid and content.backgrounds.count() > 0
      backgroundUriList = content.backgrounds
    end if

    detailScreen.content = content
  end if

  detailScreen.backgroundUriList = backgroundUriList
  m.backgroundGroup.backgroundInfo = {
    type: m.constants.ui.backgroundTypes.fullScreen
    uriList: backgroundUriList
  }

  'update tracking info - have to set the whole AA, can't update only a portion on the AA field
  detailScreen.trackingPageInfo = {
    pageType: "video_page"
    pageValues: {
      video_id: stateSource.id.toInt()
    }
  }
  detailScreen.content = content
End Function


'@screen: roSGNode, a detail screen node
'@content: roSGNode, a TubiContentNode
Function getSingleContentFromServer(screen, content)
  tubiLog("DetailScreenHelpers.getSingleContentFromServer")
  if content <> invalid then
    request = {
      contentId: content.id
      getRelated: true
      getContent: true
      content: content
    }

    refreshTask = CreateObject("roSGNode", "DetailMetadataTask")
    refreshTask.request = request
    refreshTask.addField("target", "node", false)
    refreshTask.target = screen
    screen.addField("task", "node", false)
    screen.task = refreshTask
    refreshTask.observeField("response", "onSingleContentResponse")
    refreshTask.observeField("error", "onSingleContentError")
    refreshTask.control = "RUN"
  end if
End Function

'wrapper around getSingleContentFromServer for use as a callback in the error modal
'@params: 2 index array containing params that should be passed to getSingleContentFromServer()
Function getSingleContentFromServerRetry(params)
  if type(params) = "roArray" and params.count() = 2
    m.refreshingDetailCache = false
    getSingleContentFromServer(params[0], params[1])
  end if
End Function


Function onSingleContentResponse(msg) As Void
  tubiLog("DetailScreenHelpers.onSingleContentResponse")
  task = msg.getRoSGNode()
  detailScreen = task.target

  task.unobserveField("response")
  task.unobserveField("error")

  ' Replace the top of the detail screen content stack with the refreshed content
  refreshedContent = msg.GetData()
  oldContent = detailScreen.content
  afterFn = invalid  ' the Function to execute once we've sorted the detail screen out
  history = m.global.historyIds.findNode(refreshedContent.id)

  if m.enteredFromDeepLink = true and m.top.deepLinkContent <> invalid
    if history <> invalid and history.nowPos > 0
     '//Use the history deeplink to resume a deeplinked video 
      m.top.deepLinkContent.nowPos = history.nowPos
    end if

    if m.top.deepLinkContent.deeplinkType = "series" and refreshedContent.type = m.constants.ui.contentTypes.series
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
      sendDeeplinkAnalytics(m.top.deepLinkContent, "video", m.Tracking, m.trackingLoggingTask)
    else if (m.top.deepLinkContent.deeplinkType = "season" or m.top.deepLinkContent.deeplinkType = "episode" or m.top.deepLinkContent.deeplinkType = "series") and refreshedContent.type = m.constants.ui.contentTypes.video
      '  refreshedContent.id =       episode id
      '  refreshedContent.seriesId = series id
      '  refreshedContent.type =     video
      '  m.deepLinkContent.deepLinkType = season | episode | series

      ' deeplink sent us an episode id, so here, we have full info for an episode, but we need full info for a series
      ' don't send deeplink analytics here, we will send it once we get the refreshedContent (response from getSingleContentFromServer())
      emptySeriesNode = CreateObject("roSGNode", "TubiContentNode")
      emptySeriesNode.type = m.constants.ui.contentTypes.series
      emptySeriesNode.id = refreshedContent.seriesId
      getSingleContentFromServer(detailScreen, emptySeriesNode)
      return
    else if m.top.deepLinkContent.deeplinkType = "season" and refreshedContent.type = m.constants.ui.contentTypes.series
      '  refreshedContent.id =       series id
      '  refreshedContent.seriesId = invalid
      '  refreshedContent.type =     series
      '  m.deepLinkContent.deepLinkType = season

      ' we've now received the full series info, so we can build the relevant screens
      refreshedContent.currentEpisodeId = m.top.deepLinkContent.id
      ' when deeplinkType = "season", deeplinkContent.id should be an episode id. We want to send tracking with the series id.
      m.top.deepLinkContent.id = refreshedContent.id
      afterFn = episodesHelper
      sendDeeplinkAnalytics(m.top.deepLinkContent, "episodeList", m.Tracking, m.trackingLoggingTask)
    else if m.top.deepLinkContent.deeplinkType = "episode" and refreshedContent.type = m.constants.ui.contentTypes.series
      '  refreshedContent.id =       series id
      '  refreshedContent.seriesId = invalid
      '  refreshedContent.type =     series
      '  m.deepLinkContent.deepLinkType = episode

      ' we now have the full series info for episode deeplinks
      refreshedContent.currentEpisodeId = m.top.deepLinkContent.id
      'determine if we need to resume or play from start the deeplinked episode
      if m.top.deepLinkContent.nowPos <> invalid and m.top.deepLinkContent.nowPos > 0
        episode = getEpisodeContent(refreshedContent)
        episode.nowPos = m.top.deepLinkContent.nowPos
        afterFn = resumeHelper
      else
        afterFn = playHelper
      end if
      sendDeeplinkAnalytics(m.top.deepLinkContent, "video", m.Tracking, m.trackingLoggingTask)
    else if m.top.deepLinkContent.deeplinkType = "movie"
      'determine if we need to resume or play from start the deeplinked movie
      if m.top.deepLinkContent.nowPos <> invalid and m.top.deepLinkContent.nowPos > 0
        refreshedContent.nowPos = m.top.deepLinkContent.nowPos
        afterFn = resumeHelper
      else
        afterFn = playHelper
      end if
      sendDeeplinkAnalytics(m.top.deepLinkContent, "video", m.Tracking, m.trackingLoggingTask)
    else
      'start the channel normally in case of issues
      'handle deeplinking tracking when landing on category/home screen
      m.enteredFromDeepLink = false
      sendDeeplinkAnalytics(m.top.deepLinkContent, "home", m.Tracking, m.trackingLoggingTask)
      startOnNow()
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
      getSingleContentFromServer(detailScreen, emptySeriesNode)
      return
    end if
  end if

  populateDetailScreen(detailScreen, refreshedContent)

  loadTime = 0
  if refreshedContent.type = m.constants.ui.contentTypes.series
    loadTime = Int((Uptime(0) - detailScreen.trackingLoadStartTime) * 1000)  'in ms
  end if

  if m.enteredFromDeepLink = false and m.refreshingDetailCache = false
    oldScreen = getHiddenScreen(1)  'we already pushed the details screen, so the previous screen is 1 screen below the top screen/details screen
    if oldScreen <> invalid
      screenTrackingNavigate(oldScreen.trackingPageInfo, detailScreen.trackingPageInfo, oldScreen.trackingComponentInfo)
    end if
    screenTrackingLoad(detailScreen.trackingPageInfo, loadTime)
  end if

  if m.refreshingDetailCache = true
    m.refreshingDetailCache = false
  end if

  if afterFn <> invalid
    afterFn(detailScreen)
  end if
End Function


Function onSingleContentError(msg)
  error = msg.GetData()
  task = msg.getRoSGNode()
  tubiLog("DetailScreenHelpers.onSingleContentError")

  content = invalid
  if task.request <> invalid 
    content = task.request.content
  end if
  task.unobserveField("response")
  task.unobserveField("error")
  task = invalid
  detailScreen = currentScreen()
  ' Roku requires that errors are not shown for invalid content ids when deep linking
  if m.enteredFromDeepLink = true
    m.enteredFromDeepLink = false
    popScreen()
    sendDeeplinkAnalytics(m.top.deepLinkContent, "home", m.Tracking, m.trackingLoggingTask)
    startOnNow()
  else if m.refreshingDetailCache = true
    m.refreshingDetailCache = false
  else
    message = "Could not retrieve content information from server."
    if content = invalid 
      content = detailScreen.content
    end if
    getSingleContentParams = [detailScreen, content]
  
    errorObj = createErrorObject(m.global.constants.errors.context.videoDetailScreen, m.global.constants.errors.subtypes.fetchError, message, error.code)
    showErrorModal(errorObj, getSingleContentFromServerRetry, getSingleContentParams, onCloseErrorModal)

    ' Typically we would want to make a call to screenTrackingLoad() with success=false here to indicate to analytics that the page did not load;
    ' however, movie details screens do load, and episode details screens don't load, but we don't know the content id of the episode's video
    ' which means that our page information cannot be built properly and the call is squashed by back end validation. So we just don't send for now.

    content = getDetailScreenContent()
    sendDialogAnalytics(content, "WARNING", m.Tracking, m.trackingLoggingTask)
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


' Given a content node that may be a series or a video, return the appropriate video to play.
' This may just be returning the video that is passed in (in the case of a movie).
' @contentNode content node
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
Function getDetailScreenContent()
  screen = currentScreen()
  if screen <> invalid and screen.content <> invalid
    return screen.content
  else
    return invalid
  end if
End Function


Function onAddToQueueSelected(msg)
  tubiLog("DetailScreenHelpers.onAddToQueueSelected")
  detailScreen = msg.getRoSGNode()
  onAddToQueue(detailScreen)
End Function


Function onAddToQueue(detailScreen)
  tubiLog("DetailScreenHelpers.onAddToQueue")
  if m.global.authInfo = invalid
    title = "Please Sign In"
    message = "You must be signed in to add a title to your queue."
    buttons = ["Sign in or Register", "Cancel"]
    showModal(title, message, buttons, "onSignInModalButtonSelected")
    content = getDetailScreenContent()
    sendDialogAnalytics(content, "INFORMATION", m.Tracking, m.trackingLoggingTask)
  else if detailScreen <> invalid and detailScreen.isWaitingForServerResponse <> true
    detailScreen.addToQueueTitle = "Adding..."
    userTask = CreateObject("roSGNode", "AuthTask")
    userTask.functionName = "addToQueue"
    userTask.content = detailScreen.content
    userTask.addField("target", "node", false)
    userTask.target = detailScreen
    detailScreen.addField("task", "node", false)
    detailScreen.task = userTask
    userTask.observeField("bookmarkId", "onBookmarked")
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


' handles the response of a user who has been presented a sign in modal on the details screen
Function onSignInModalButtonSelected(msg)
  if msg.getData() = 0
    onSignInSelected()
  end if
End Function


''''''''''''''''''
' onBookmarked

Function onBookmarked(msg) As Void
  tubiLog("DetailScreenHelpers.onBookmarked")
  task = msg.getRoSGNode()
  detailScreen = task.target
  bookmarkId = task.bookmarkId
  task.unobserveFieldScoped("bookmarkId")
  detailScreen.task = invalid
  if bookmarkId = invalid or bookmarkId = ""
    reason = "Unknown"
    detailScreen.isWaitingForServerResponse = false
    
    errorObj = createErrorObject(m.global.constants.errors.context.videoDetailScreen, m.global.constants.errors.subtypes.fetchError, reason)
    showErrorModal(errorObj, onAddToQueueSelected, [detailScreen], cancelHistoryQueueChange, [detailScreen, "addToQueueTitle", "Add to queue"])

    content = getDetailScreenContent()
    sendDialogAnalytics(content, "WARNING", m.Tracking, m.trackingLoggingTask)
    return
  end if

  tubiLog("Got bookmarkId " + bookmarkId + " for content " + detailScreen.content.id)
  detailScreen.isBookmark = true
  detailScreen.isWaitingForServerResponse = false

  sendBookmarkAnalytics(detailScreen.content, "ADD_TO_QUEUE", m.Tracking, m.trackingLoggingTask)
  onHistoryQueueChange(m.constants.ui.categoryIds.queue)
End Function


Function onRemoveFromQueueSelected(msg)
  tubiLog("DetailScreenHelpers.onRemoveFromQueueSelected")
  detailScreen = msg.getRoSGNode()
  onRemoveFromQueue(detailScreen)
End Function


Function onRemoveFromQueue(detailScreen)
  tubiLog("DetailScreenHelpers.onRemoveFromQueue")
  if detailScreen <> invalid and detailScreen.isWaitingForServerResponse <> true
    detailScreen.removeQueueTitle = "Removing..."
    userTask = CreateObject("roSGNode", "AuthTask")
    userTask.functionName = "removeFromQueue"
    content = detailScreen.content.clone(false)
    bookmark = m.global.bookmarkIds.findNode(content.id)
    content.bookmarkId = bookmark.bookmarkId
    userTask.content = content
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
  if result = invalid or result.response.code <> 204 then
    code = ""
    reason = "Unknown"
    if result <> invalid
      code = result.response.code
      reason = result.response.failReason
    end if
    tubiLog("removeFromQueue returned ")
    detailScreen.isWaitingForServerResponse = false

    errorObj = createErrorObject(m.global.constants.errors.context.videoDetailScreen, m.global.constants.errors.subtypes.fetchError, reason, code)
    showErrorModal(errorObj, onRemoveFromQueueSelected, [detailScreen], cancelHistoryQueueChange, [detailScreen, "removeQueueTitle", "Remove from queue"])

    content = getDetailScreenContent()
    sendDialogAnalytics(content, "WARNING", m.Tracking, m.trackingLoggingTask)
    return
  end if

  detailScreen.isWaitingForServerResponse = false
  sendBookmarkAnalytics(detailScreen.content, "REMOVE_FROM_QUEUE", m.Tracking, m.trackingLoggingTask)
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
      detailScreen.removeHistoryTitle = "Removing..."
      content.historyId = history.historyId
      if m.userTask <> invalid
        m.NodeHelpers.unobserveAllScoped(m.userTask)
      end if
      userTask = CreateObject("roSGNode", "AuthTask")
      userTask.functionName = "removeFromHistory"
      userTask.content = content
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

  if result = invalid or result.response.code <> 204 then
    code = ""
    reason = "Unknown"
    if result <> invalid
      code = result.response.code
      reason = result.response.failReason
    end if
    tubiLog("removeFromHistory returned " + stri(code))
    
    errorObj = createErrorObject(m.global.constants.errors.context.videoDetailScreen, m.global.constants.errors.subtypes.fetchError, reason, code)
    showErrorModal(errorObj, onRemoveFromHistorySelected, [detailScreen], cancelHistoryQueueChange, [detailScreen, "removeHistoryTitle", "Remove from history"])

    content = getDetailScreenContent()
    sendDialogAnalytics(content, "WARNING", m.Tracking, m.trackingLoggingTask)
    return
  end if

  detailScreen.isWaitingForServerResponse = false
  detailScreen.isHistory = false
  sendBookmarkAnalytics(detailScreen.content, "REMOVE_FROM_CONTINUE_WATCHING", m.Tracking, m.trackingLoggingTask)
  onHistoryQueueChange(m.constants.ui.categoryIds.history)
End Function

'@params: roArray, contains a screen, a field, and a value to update a field on the screen.
'                  expect something like [detailScreen, "removeQueueTitle", "Remove From queue"]
Function cancelHistoryQueueChange(params)
  tubiLog("DetailScreenHelpers.cancelHistoryQueueChange")
  if type(params) = "roArray" and params.count() = 3
    detailScreen = params[0]
    detailScreen.isWaitingForServerResponse = false

    'update the details screen with the appropriate "Remove from queue", "Add to queue", etc. button
  end if
End Function


Function onRelatedContentSelected(msg)
  detailScreen = msg.getRoSGNode()
  content = detailScreen.content.relatedContent.getChild(detailScreen.relatedContentSelected)
  if content <> invalid
    showDetailScreen(content)
  end if
End Function

Function onCloseErrorModal()
  '//exit the detail screen entirely since the content could not be gathered.
  onDetailBackPressed()
End Function

Function onDetailBackPressed()
  ' TODO(Chris): This is in terrible need of refactor. We shouldn't be calling this directly
  ' but we have to invoke the "empty stack" logic at this point.

  m.refreshingDetailCache = false
  onKeyEvent("back", true)
End Function


Function onEpisodeList(msg)
  tubiLog("ContentController.onEpisodeList")
  detailScreen = msg.getRoSGNode()
  episodesHelper(detailScreen)
End Function


Function episodesHelper(screen)
  showEpisodeScreen(screen.content)
End Function


Function onWatchTrailer()
  tubiLog("ContentController.onWatchTrailer")
  content = getDetailScreenContent()
  if content <> invalid then
    trailerContent = CreateObject("roSGNode", "TubiContentNode")
    if content.id <> invalid
      trailerContent.id = content.id
    end if

    if content.title <> invalid
      trailerContent.title = "Trailer (" + content.title + ")"
    end if

    trailerContent.streamformat="hls"
    trailerContent.nowPos = 0
    trailerContent.isTrailer = true

    playVideoContent(trailerContent, "none")
  end if
End Function


'''''''''''
' onResume
'
' Notify the main Brightscript thread to invoke the video player, resuming at the indicated location
Function onResume(msg)
  tubiLog("ContentController.onResume")
  detailScreen = msg.getRoSGNode()
  resumeHelper(detailScreen)
End Function


'''''''''''
' onPlay
'
' Notify the main Brightscript thread to invoke the video player
Function onPlay(msg)
  tubiLog("ContentController.onPlay")
  detailScreen = msg.getRoSGNode()
  playHelper(detailScreen)
End Function

Function playHelper(screen)
  episode = getEpisodeContent(screen.content)
  if episode <> invalid then
    playVideoContent(episode, "none", 0)
  else
    tubiLog("ERROR: Play selected but content is invalid")
  end if
End Function


Function resumeHelper(detailScreen)
  episode = getEpisodeContent(detailScreen.content)
  if episode <> invalid then
    nowPos = invalid
    ' find the position in global history
    history = m.global.historyIds.findNode(episode.id)
    if m.top.deepLinkContent = invalid or m.top.deepLinkContent.deepLinkType = "season" or m.top.deepLinkContent.deepLinkType = "series"
      if history <> invalid then
        nowPos = history.nowPos
      end if
    end if
    playVideoContent(episode, "none", nowPos)
  else
    tubiLog("ERROR: Resume selected but content is invalid")
  end if
End Function


Function onPlaySignInModalButtonSelected(msg)
  if msg.getData() = 0
    onSignInSelected()
  else
    episode = getEpisodeContent(getDetailScreenContent())
    playVideoContent(episode, "none", 0)
  end if
End Function


' Organizes the information needed to create a "referred" tracking event and sends the information to the trackingTask which will
' actually send the event.
'
' @deepLinkContent: roSGNode, a content node created by deeplink logic and passed to the content controller via m.top.deeplinkContent
' @entryPoint: string, indicates where the user will land after the deeplink, can be one of: "detail", "home", "episodeList", "video"
' @trackingLib: associativeArray, an instance of TubiTracking()
' @trackingTask: roSGNode, an instance of the TrackingLoggingTask
Function sendDeeplinkAnalytics(deepLinkContent, entryPoint, trackingLib, trackingTask)
  referredAnalyticsEvent = {
    referred_type: "DEEP_LINK"
    campaign: deepLinkContent.campaign
    source: deepLinkContent.source
    medium: deepLinkContent.medium
  }
  if entryPoint = "detail"
    referredAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage("video_page", {video_id: deepLinkContent.id.toInt()})
  else if entryPoint = "home"
    referredAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage("home_page", {})
  else if entryPoint = "episodeList"
    seriesId = deeplinkContent.id
    if Left(deepLinkContent.id, 1) = "0"
      seriesId = Mid(deepLinkContent.id, 2)
    end if
    referredAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage("series_detail_page", {series_id: seriesId.toInt()})
  else if entryPoint = "video"
    referredAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage("video_page", {video_id: deepLinkContent.id.toInt()})
  end if

  trackingTask.trackEvent = {
    type: "referred"
    values: referredAnalyticsEvent
  }
End Function


' Organizes the information needed to create a "bookmark" tracking event and sends the information to the trackingTask which will
' actually send the event.
'
' @content: roSGNode, the content that is residing on the details page
' @operation: string, one of the valid operations as defined in events.protos -> Bookmarks -> enum Operation
' @trackingLib: associativeArray, an instance of TubiTracking()
' @trackingTask: roSGNode, an instance of the TrackingLoggingTask
Function sendBookmarkAnalytics(content, operation, trackingLib, trackingTask)
  bookmarkAnalyticsEvent = {
    contentOneof: {}
    op: operation
    component: {} 'menu component not currently included in protos definition
  }
  if type(content) = "roSGNode" and content.isSubtype("ContentNode") = true
    bookmarkAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage("video_page", {video_id: content.id.toInt()})
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


' Organizes the information needed to create a "dialog" tracking event and sends the information to the trackingTask which will
' actually send the event.
'
' @content: roSGNode, the content that is residing on the details page
' @dialogType: string, one of the valid operations as defined in events.protos -> DialogEvent -> enum DialogType
' @trackingLib: associativeArray, an instance of TubiTracking()
' @trackingTask: roSGNode, an instance of the TrackingLoggingTask
Function sendDialogAnalytics(content, dialogType, trackingLib, trackingTask)
  dialogAnalyticsEvent = {
    type: "dialog"
    values: {
      dialog_type: dialogType 'DialogType enum
    }
  }

  if type(content) = "roSGNode" and content.isSubtype("ContentNode") = true
    dialogAnalyticsEvent.values.pageOneof = trackingLib.getAnalyticsPage("video_page", {video_id: content.id.toInt()})
  end if

  trackingTask.trackEvent = dialogAnalyticsEvent
End Function