
'''''''''''''''''''''
' showDetailScreen
'
' @content: roSGNode, a content node for a single pieces of content, might be a video or top level series
' @sourceTrackingUri: the uri of the previous screen for tracking
' @detailScreen: in case we are reloading and existing screen rather than creating a new one
Function showDetailScreen(content, sourceTrackingUri)
  tubiLog("DetailScreenHelpers.showDetailScreen")

  detailScreen = CreateObject("roSGNode", "DetailScreen")
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

  if m.top.deepLinkContent <> invalid or content.type = m.constants.ui.contentTypes.series or (content.type = m.constants.ui.contentTypes.video and content.seriesId <> invalid and content.seriesId <> "")
    detailScreen.isLoading = true
  else
    detailScreen.trackingUri = populateDetailTrackingUri(content, invalid)
    populateDetailScreen(detailScreen, content, true)
  end if

  pushScreen(detailScreen, false)  ' don't send tracking until we resolve series episode
  getSingleContentFromServer(detailScreen, content, sourceTrackingUri)
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
    showChannelScreen(channelNode, detailScreen.trackingUri)
  end if
End Function

'''''''''''''''''''''
' populateDetailScreen
'
'Populates the detail screen's state from a content node
'@content: tubiContentNode
Function populateDetailScreen(detailScreen, content, resetButtonIndex=false)
  tubiLog("DetailScreenHelpers.populateDetailScreen")
  if type(detailScreen) = "roSGNode" and detailScreen.isSubType("DetailScreen") and type(content) = "roSGNode"
    'hide the spinner
    wasLoading = detailScreen.isLoading
    detailScreen.isLoading = false

    'update detail screen state via the input interface
    detailScreen.title = content.title
    detailScreen.releaseDate = content.releaseDate
    detailScreen.genres = content.genres
    detailScreen.hasTrailer = content.hasTrailer

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

    detailScreen.length = stateSource.length
    detailScreen.rating = stateSource.rating
    detailScreen.description = stateSource.description
    detailScreen.directors = stateSource.directors
    detailScreen.starring = stateSource.actors

    if episode <> invalid and (episode.hasSubtitles = true or not m._.empty(episode.subtitleTracks))
      detailScreen.hasCC = true
    else if content <> invalid and content.type = m.constants.ui.contentTypes.video and (content.hasSubtitles = true or not m._.empty(content.subtitleTracks))
      detailScreen.hasCC = true
    else
      detailScreen.hasCC = false
    end if

    detailScreen.isBookmark = (bookmark <> invalid)
    detailScreen.isHistory = (history <> invalid)
    detailScreen.isChannelItem = (content.channelId <> invalid and content.channelId <> "")

    detailScreen.inlineLogoUri = content.inlineLogoUri
    detailScreen.channelName = content.channelName

    if content.type = m.constants.ui.contentTypes.series and episodeHistory <> invalid and episodeHistory.nowPos > 0
      detailScreen.resumePoint = episodeHistory.nowPos
    else if content.type = m.constants.ui.contentTypes.video and history <> invalid and history.nowPos > 0
      detailScreen.resumePoint = history.nowPos
    else
      detailScreen.resumePoint = 0
    end if

    'tell the detail screen/info panel to vertically center the info panel
    detailScreen.calculateInfoHeight = true

    detailScreen.relatedContent = content.relatedContent

    if wasLoading or resetButtonIndex
      detailScreen.jumpToItem = 0
    end if

    'update the background images for the detail screen
    if content.backgrounds <> invalid and content.backgrounds.count() > 0
      backgroundUriList = content.backgrounds
    else
      backgroundUriList = [m.defaultBackgroundUri]
    end if
    detailScreen.backgroundUriList = backgroundUriList
    m.backgroundGroup.backgroundInfo = {
      type: m.constants.ui.backgroundTypes.fullScreen
      uriList: backgroundUriList
    }
    detailScreen.content = content
  end if
End Function





' @uriType: string, represents the type of uri expected
' @content: roSGNode, a TubiContentNode
Function populateDetailTrackingUri(content as Object, episode) As String
  trackUri = ""

  'set the details screen tracking URI
  if content["type"] = m.global.constants.ui.contentTypes.series
    trackUri = "/series/"

    if content.id <> invalid
      ' trim leading "0" off series id
      trackUri = trackUri + Mid(content.id, 2)

      'get the episode id
      if episode <> invalid and episode.id <> invalid and type(episode.id) = "roString"
        trackUri = trackUri + "/" + episode.id
      end if
    end if

  else if content["type"] = m.constants.ui.contentTypes.video
    trackUri = "/video/"
    if content.id <> invalid
      trackUri = trackUri + content.id
    end if
  end if

  if trackUri = "" then trackUri = "defaultUri"
  return trackUri
End Function


'@content: roSGNode, a TubiContentNode
Function getSingleContentFromServer(screen, content, sourceTrackingUri)
  tubiLog("DetailScreenHelpers.getSingleContentFromServer")
  if content <> invalid then 
    request = {
      contentId: content.id
      getRelated: true
      getContent: true
    }
    refreshTask = CreateObject("roSGNode", "DetailMetadataTask")
    refreshTask.request = request
    refreshTask.addField("target", "node", false)
    refreshTask.target = screen
    screen.addField("task", "node", false)
    screen.task = refreshTask
    screen.addField("sourceTrackingUri", "string", false)
    screen.sourceTrackingUri = sourceTrackingUri
    refreshTask.observeField("response", "onSingleContentResponse")
    refreshTask.observeField("error", "onSingleContentError")
    refreshTask.control = "RUN"
  end if
End Function

'wrapper around getSingleContentFromServer for use as a callback in the error modal
'@params: 3 index array containing params that should be passed to getSingleContentFromServer()
Function getSingleContentFromServerRetry(params)
  if type(params) = "roArray" and params.count() = 3
    getSingleContentFromServer(params[0], params[1], params[2])
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
  afterFn = invalid  ' the function to execute once we've sorted the detail screen out
  if m.enteredFromDeepLink = true and m.top.deepLinkContent <> invalid
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
      history = m.global.historyIds.findNode(refreshedContent.id)
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
    else if (m.top.deepLinkContent.deeplinkType = "season" or m.top.deepLinkContent.deeplinkType = "episode" or m.top.deepLinkContent.deeplinkType = "series") and refreshedContent.type = m.constants.ui.contentTypes.video
      '  refreshedContent.id =       episode id
      '  refreshedContent.seriesId = series id
      '  refreshedContent.type =     video
      '  m.deepLinkContent.deepLinkType = season | episode | series

      ' deeplink sent us an episode id, so here, we have full info for an episode, but we need full info for a series
      emptySeriesNode = CreateObject("roSGNode", "TubiContentNode")
      emptySeriesNode.type = m.constants.ui.contentTypes.series
      emptySeriesNode.id = refreshedContent.seriesId
      getSingleContentFromServer(detailScreen, emptySeriesNode, detailScreen.sourceTrackingUri)
      return
    else if m.top.deepLinkContent.deeplinkType = "season" and refreshedContent.type = m.constants.ui.contentTypes.series
      '  refreshedContent.id =       series id
      '  refreshedContent.seriesId = invalid
      '  refreshedContent.type =     series
      '  m.deepLinkContent.deepLinkType = season

      ' we've now received the full series info, so we can build the relevant screens
      refreshedContent.currentEpisodeId = m.top.deepLinkContent.id
      afterFn = episodesHelper
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
    else if m.top.deepLinkContent.deeplinkType = "movie"
      'determine if we need to resume or play from start the deeplinked movie
      if m.top.deepLinkContent.nowPos <> invalid and m.top.deepLinkContent.nowPos > 0
        refreshedContent.nowPos = m.top.deepLinkContent.nowPos
        afterFn = resumeHelper
      else
        afterFn = playHelper
      end if
    else
      'start the channel normally in case of issues
      m.enteredFromDeepLink = false
      startOnNow()
      return
    end if
  else
    ' Find a default episode to land on, in case no specific episode requested from deep link
    if refreshedContent.type = m.constants.ui.contentTypes.series and refreshedContent.currentEpisodeId = ""
      if oldContent <> invalid and oldContent.type = m.constants.ui.contentTypes.video 
        ' a specific episode was requested by id
        refreshedContent.currentEpisodeId = oldContent.id
      else
        ' first see if there was a specific episode id we wanted
        history = m.global.historyIds.findNode(refreshedContent.id)
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
      getSingleContentFromServer(detailScreen, emptySeriesNode, detailScreen.sourceTrackingUri)
      return
    end if
  end if

  ' showDetailScreen defers navigation tracking for refreshed content or deep links, so do it here
  detailScreen.trackingUri = populateDetailTrackingUri(refreshedContent, getEpisodeContent(refreshedContent))
  ' TODO(Chris): where do we get sourceTrackingUri from?
  if detailScreen.sourceTrackingUri <> invalid
    screenTrackingNavigate(detailScreen.sourceTrackingUri, detailScreen.trackingUri)
  end if
  screenTrackingLoad(detailScreen.trackingUri)

  populateDetailScreen(detailScreen, refreshedContent)
  if afterFn <> invalid
    afterFn(detailScreen)
  end if
End Function


Function onSingleContentError(msg)
  error = msg.GetData()
  task = msg.getRoSGNode()
  tubiLog("DetailScreenHelpers.onSingleContentError")
  task.unobserveField("response")
  task.unobserveField("error")
  task = invalid
  ' Roku requires that errors are not shown for invalid content ids when deep linking
  if m.enteredFromDeepLink = true
    m.enteredFromDeepLink = false
    popScreen()
    startOnNow()
  else
    message = "Could not retrieve content information from server."
    detailScreen = currentScreen()
    getSingleContentParams = [detailScreen, detailScreen.content, detailScreen.trackingUri]
    showErrorModal(error.code, message, getSingleContentFromServerRetry, getSingleContentParams)
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


' @contentNode series content node
Function getEpisodeContent(content)
  if content <> invalid 
    if content.currentEpisodeId <> invalid and content.currentEpisodeId <> ""
      return content.findNode(content.currentEpisodeId)
    else
      series = content.getChild(0)
      if series <> invalid
        ' return a default if no match
        return series.getChild(0)
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
  tubiLog("DetailScreenHelpers.addToQueue")
  detailScreen = msg.getRoSGNode()
  if m.global.authInfo = invalid
    title = "Please Sign In"
    message = "You must be signed in, in order to add a title to your queue."
    buttons = ["Sign in or Register", "Cancel"]
    showModal(title, message, buttons, "onSignInModalButtonSelected")
  else if detailScreen.isWaitingForServerResponse <> true
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
  if bookmarkId = invalid then
    code = -1
    reason = "Unknown"
    tubiLog("addToQueue returned " + stri(code))
    detailScreen.isWaitingForServerResponse = false
    showErrorModal(code, reason, onAddToQueueSelected, [], cancelHistoryQueueChange, [])
    return
  end if

  tubiLog("Got bookmarkId " + bookmarkId + " for content " + detailScreen.content.id)
  detailScreen.isBookmark = true
  detailScreen.isWaitingForServerResponse = false

  'user tracking
  m.global.trackingLoggingTask.trackEvent = {
    trackType: "addBookmark"
    value: detailScreen.content.id
    ctx: m.top.trackingUri
  }
  onHistoryQueueChange(m.constants.ui.categoryIds.queue)
End Function


Function onRemoveFromQueueSelected(msg)
  tubiLog("DetailScreenHelpers.onRemoveFromQueueSelected")
  detailScreen = msg.getRoSGNode()
  if detailScreen.isWaitingForServerResponse <> true
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


Function onBookmarkRemoved(msg) As Void
  tubiLog("DetailScreenHelpers.onBookmarkRemoved")
  task = msg.getRoSGNode()
  detailScreen = task.target
  result = task.result
  task.unobserveField("result")
  detailScreen.task = invalid
  if result = invalid or result.response.code <> 204 then
    if result <> invalid
      code = result.response.code
      reason = result.response.failReason
    else
      code = -1
      reason = "Unknown"
    end if
    tubiLog("removeFromQueue returned " + stri(code))
    detailScreen.isWaitingForServerResponse = false
    showErrorModal(code, reason, onRemoveFromQueueSelected, [], cancelHistoryQueueChange, [])
    return
  end if

  detailScreen.isWaitingForServerResponse = false
  'user tracking
  m.global.trackingLoggingTask.trackEvent = {
    trackType: "deleteBookmark"
    value: detailScreen.content.id
  }
  onHistoryQueueChange(m.constants.ui.categoryIds.queue)
End Function


Function onRemoveFromHistorySelected(msg)
  tubiLog("DetailScreenHelpers.onRemoveFromHistorySelected")
  detailScreen = msg.getRoSGNode()
  if detailScreen.isWaitingForServerResponse <> true
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


Function onHistoryRemoved(msg) As Void
  tubiLog("DetailScreenHelpers.onHistoryRemoved")
  task = msg.getRoSGNode()
  detailScreen = task.target
  result = task.result
  task.unobserveField("result")
  detailScreen.task = invalid

  if result = invalid or result.response.code <> 204 then
    if result <> invalid
      code = result.response.code
      reason = result.response.failReason
    else
      code = -1
      reason = "Unknown"
    end if
    tubiLog("removeFromHistory returned " + stri(code))
    showErrorModal(code, reason, onRemoveFromHistorySelected, [], cancelHistoryQueueChange, [])
    return
  end if

  detailScreen.isWaitingForServerResponse = false
  detailScreen.isHistory = false
  onHistoryQueueChange(m.constants.ui.categoryIds.history)
End Function


Function cancelHistoryQueueChange()
  detailScreen = currentScreen()
  detailScreen.isWaitingForServerResponse = false
End Function


Function onRelatedContentSelected(msg)
  detailScreen = msg.getRoSGNode()
  content = detailScreen.content.relatedContent.getChild(detailScreen.relatedContentSelected)
  if content <> invalid
    sourceTrackingUri = detailScreen.trackingUri + "/related/" + detailScreen.relatedContentSelected.toStr()
    showDetailScreen(content, sourceTrackingUri)
  end if
End Function

Function onDetailBackPressed()
  ' TODO(Chris): This is in terrible need of refactor. We shouldn't be calling this directly
  ' but we have to invoke the "empty stack" logic at this point.
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
      playVideoContent(episode, false, 0)
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
    playVideoContent(episode, false, nowPos)
  else
    tubiLog("ERROR: Resume selected but content is invalid")
  end if
End Function

Function onPlaySignInModalButtonSelected(msg)
  if msg.getData() = 0
    onSignInSelected()
  else
    episode = getEpisodeContent(getDetailScreenContent())
    playVideoContent(episode, false, 0)
  end if
End Function




