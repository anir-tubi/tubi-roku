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
Function getSingleContentFromServer(content=invalid)
  tubiLog("DetailScreenHelpers.getSingleContentFromServer")
  if content = invalid then
    contentAndIndex = m.detailScreenContent.peek()
    content = contentAndIndex.content
  end if

  if content <> invalid then 
    if m.refreshTask <> invalid
      m.refreshTask.unobserveField("response")
      m.refreshTask.unobserveField("error")
    end if

    request = {
      contentId: content.id
    }
    if (m.constants.ui.detailScreen.enableRelatedContent = invalid and getExperimentValue("UserNamespace", "related_content") = 1) or m.constants.ui.detailScreen.enableRelatedContent = true
      request.getRelated = true
    end if
    m.refreshTask = CreateObject("roSGNode", "DetailMetadataTask")
    m.refreshTask.request = request

    m.refreshTask.observeField("response", "onSingleContentResponse")
    m.refreshTask.observeField("error", "onSingleContentError")
    m.refreshTask.control = "RUN"
  end if
End Function


Function onSingleContentResponse(msg) As Void
  tubiLog("DetailScreenHelpers.onSingleContentResponse")

  ' Replace the top of the detail screen content stack with the refreshed content
  refreshedContent = msg.GetData()
  oldContentAndIndex = m.detailScreenContent.pop()
  oldContent = oldContentAndIndex.content
  contentAndIndex = {
    content: refreshedContent
    series2dIndex: oldContentAndIndex.series2dIndex
    sourceTrackingUri: oldContentAndIndex.sourceTrackingUri
  }
  m.detailScreenContent.push(contentAndIndex)

  m.refreshTask.unobserveField("response")
  m.refreshTask.unobserveField("error")
  m.refreshTask = invalid

  afterFn = invalid  ' the function to execute once we've sorted the detail screen out
  if m.enteredFromDeepLink = true and m.top.deepLinkContent <> invalid
    if m.top.deepLinkContent.deeplinkType = "series"
      '  refreshedContent.id:       series id
      '  refreshedContent.seriesId: invalid
      '  refreshedContent.type:     series
      '  m.deepLinkContent.deepLinkType: series
      contentAndIndex.series2dIndex = [0,0]

    else if (m.top.deepLinkContent.deeplinkType = "season" or m.top.deepLinkContent.deeplinkType = "episode") and refreshedContent.type = m.constants.ui.contentTypes.video
      '  refreshedContent.id =       episode id
      '  refreshedContent.seriesId = series id
      '  refreshedContent.type =     video
      '  m.deepLinkContent.deepLinkType = seaason | episode

      ' deeplink sent us an episode id, so here, we have full info for an episode, but we need full info for a series
      emptySeriesNode = CreateObject("roSGNode", "TubiContentNode")
      emptySeriesNode.type = m.constants.ui.contentTypes.series
      emptySeriesNode.id = refreshedContent.seriesId
      getSingleContentFromServer(emptySeriesNode)
      return
    else if m.top.deepLinkContent.deeplinkType = "season" and refreshedContent.type = m.constants.ui.contentTypes.series
      '  refreshedContent.id =       series id
      '  refreshedContent.seriesId = invalid
      '  refreshedContent.type =     series
      '  m.deepLinkContent.deepLinkType = season

      ' we've now received the full series info, so we can build the relevant screens
      contentAndIndex.series2dIndex = findEpisode2dIndex(m.top.deepLinkContent.id, refreshedContent)
      afterFn = onEpisodeList
    else if m.top.deepLinkContent.deeplinkType = "episode" and refreshedContent.type = m.constants.ui.contentTypes.series
      '  refreshedContent.id =       series id
      '  refreshedContent.seriesId = invalid
      '  refreshedContent.type =     series
      '  m.deepLinkContent.deepLinkType = episode

      ' we now have the full series info for episode deeplinks
      contentAndIndex.series2dIndex = findEpisode2dIndex(m.top.deepLinkContent.id, refreshedContent)
      'determine if we need to resume or play from start the deeplinked episode
      if m.top.deepLinkContent.nowPos <> invalid and m.top.deepLinkContent.nowPos > 0
        episode = getEpisodeContent(contentAndIndex.series2dIndex, refreshedContent)
        episode.nowPos = m.top.deepLinkContent.nowPos
        afterFn = onResume
      else
        afterFn = onPlay
      end if
    else if m.top.deepLinkContent.deeplinkType = "movie"
      'determine if we need to resume or play from start the deeplinked movie
      if m.top.deepLinkContent.nowPos <> invalid and m.top.deepLinkContent.nowPos > 0
        refreshedContent.nowPos = m.top.deepLinkContent.nowPos
        afterFn = onResume
      else
        afterFn = onPlay
      end if
    else
      'start the channel normally in case of issues
      m.enteredFromDeepLink = false
      startOnNow()
      return
    end if
  else
    ' Find a default episode to land on, in case no specific episode requested from deep link
    if refreshedContent.type = m.constants.ui.contentTypes.series and contentAndIndex.series2dIndex[0] = -1
      if oldContent <> invalid and oldContent.type = m.constants.ui.contentTypes.video 
        ' a specific episode was requested by id
        contentAndIndex.series2dIndex = findEpisode2dIndex(oldContent.id, refreshedContent)
      else
        ' first see if there was a specific episode id we wanted
        history = m.global.historyIds.findNode(refreshedContent.id)
        if history <> invalid
          contentAndIndex.series2dIndex = findEpisode2dIndex(history.currentEpisodeId, refreshedContent)
        else
          contentAndIndex.series2dIndex = [0,0]
        end if
      end if
    else if refreshedContent.type = m.constants.ui.contentTypes.video and refreshedContent.seriesId <> invalid and refreshedContent.seriesId <> ""
      ' Case here of having an episode outside of a series (probably from autoplay)
      emptySeriesNode = CreateObject("roSGNode", "TubiContentNode")
      emptySeriesNode.type = m.constants.ui.contentTypes.series
      emptySeriesNode.id = refreshedContent.seriesId
      getSingleContentFromServer(emptySeriesNode)
      return
    end if
  end if

  ' showDetailScreen defers navigation tracking for refreshed content or deep links, so do it here
  m.detailScreen.trackingUri = populateDetailTrackingUri(refreshedContent, getEpisodeContent(contentAndIndex.series2dIndex, refreshedContent))
  if contentAndIndex.sourceTrackingUri <> invalid
    screenTrackingNavigate(contentAndIndex.sourceTrackingUri, m.detailScreen.trackingUri)
  end if
  screenTrackingLoad(m.detailScreen.trackingUri)

  populateDetailScreen(contentAndIndex)
  if afterFn <> invalid
    afterFn()
  end if
End Function


Function onSingleContentError(msg)
  error = msg.GetData()
  tubiLog("DetailScreenHelpers.onSingleContentError")
  m.refreshTask.unobserveField("response")
  m.refreshTask.unobserveField("error")
  m.refreshTask = invalid
  message = "Could not retrieve content information from server."
  showErrorModal(error.code, message, getSingleContentFromServer, cancelGetSingleContent)
End Function

Function cancelGetSingleContent()
  'if there is an error while attempting to get metadata for a deeplink content,
  ' launch the category screen
  if m.enteredFromDeepLink
    m.enteredFromDeepLink = false
    startOnNow()
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


' @episode2dIndex is a 2D array [x, y], such that x is the season index within the series, and y is the episode index within the season
' @contentNode series content node
Function getEpisodeContent(episode2dIndex As Object, contentNode As Object) As Object
  season = contentNode.getChild(episode2dIndex[0])
  if season <> invalid then
    episode = season.getChild(episode2dIndex[1])
    if episode <> invalid then return episode
  end if
  return invalid
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
    episode = getEpisodeContent(detailScreen2dIndex, content)
  end if
  return episode
End Function


' Helper to deduce the content, video or episode, to play or resume
Function getDetailScreenContent()
  videoToPlay = invalid
  contentAndIndex = m.detailScreenContent.peek()
  if contentAndIndex <> invalid and contentAndIndex.content <> invalid then
    if contentAndIndex.content.type = m.constants.ui.contentTypes.video then
      videoToPlay = contentAndIndex.content
    else
      videoToPlay = getEpisodeContent(contentAndIndex.series2dIndex, contentAndIndex.content)
    end if
  end if
  return videoToPlay
End Function


Function onAddToQueueSelected()
  tubiLog("DetailScreenHelpers.addToQueue")
  if m.global.authInfo = invalid
    title = "Please Sign In"
    message = "You must be signed in, in order to add a title to your queue."
    buttons = ["Sign in or Register", "Cancel"]
    showModal(title, message, buttons, "onSignInModalButtonSelected")
  else if m.detailScreen.isWaitingForServerResponse <> true
    contentAndIndex = m.detailScreenContent.peek()
    if contentAndIndex <> invalid and contentAndIndex.content <> invalid
      m.detailScreen.addToQueueTitle = "Adding..."
      if m.userTask <> invalid
        unobserveAllScoped(m.userTask)
      end if
      m.userTask = CreateObject("roSGNode", "AuthTask")
      m.userTask.functionName = "addToQueue"
      m.userTask.content = contentAndIndex.content
      m.userTask.observeField("bookmarkId", "onBookmarked")
      m.userTask.control = "RUN"
      m.detailScreen.isWaitingForServerResponse = true
    end if
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

Function onBookmarked() As Void
  tubiLog("DetailScreenHelpers.onBookmarked")
  bookmarkId = m.userTask.bookmarkId
  m.userTask.unobserveFieldScoped("bookmarkId")
  m.userTask = invalid

  if bookmarkId = invalid then
    code = -1
    reason = "Unknown"
    tubiLog("addToQueue returned " + stri(code))
    m.detailScreen.isWaitingForServerResponse = false
    showErrorModal(code, reason, onAddToQueueSelected, cancelHistoryQueueChange)
    return
  end if

  contentAndIndex = m.detailScreenContent.peek()
  if contentAndIndex <> invalid and contentAndIndex.content <> invalid
    tubiLog("Got bookmarkId " + bookmarkId + " for content " + contentAndIndex.content.id)

    ' TODO(Chris): Move management of this global list off to a library
    ' or task
    newBookmark = CreateObject("roSGNode", "BookmarkContentNode")
    newBookmark.id = contentAndIndex.content.id
    newBookmark.type = contentAndIndex.content.type
    newBookmark.bookmarkId = bookmarkId
    m.global.bookmarkIds = immutableInsertChild(m.global.bookmarkIds, newBookmark, 0)
    m.detailScreen.isBookmark = true
    m.detailScreen.isWaitingForServerResponse = false

    'user tracking
    m.global.trackingLoggingTask.trackEvent = {
      trackType: "addBookmark"
      value: contentAndIndex.content.id
      ctx: m.top.trackingUri
    }
  end if
  onHistoryQueueChange()
End Function


Function onRemoveFromQueueSelected()
  tubiLog("DetailScreenHelpers.onRemoveFromQueueSelected")
  if m.detailScreen.isWaitingForServerResponse <> true
    contentAndIndex = m.detailScreenContent.peek()
    if contentAndIndex <> invalid and contentAndIndex.content <> invalid
      m.detailScreen.removeQueueTitle = "Removing..."
      if m.userTask <> invalid
        unobserveAllScoped(m.userTask)
      end if
      m.userTask = CreateObject("roSGNode", "AuthTask")
      m.userTask.functionName = "removeFromQueue"
      content = clone(contentAndIndex.content)
      bookmark = m.global.bookmarkIds.findNode(content.id)
      content.bookmarkId = bookmark.bookmarkId
      m.userTask.content = content
      m.userTask.observeFieldScoped("result", "onBookmarkRemoved")
      m.userTask.control = "RUN"
      m.detailScreen.isWaitingForServerResponse = true
    end if
  end if
End Function


Function onBookmarkRemoved() As Void
  tubiLog("DetailScreenHelpers.onBookmarkRemoved")
  result = m.userTask.result
  m.userTask.unobserveField("result")
  m.userTask = invalid

  if result = invalid or result.response.code <> 204 then
    if result <> invalid
      code = result.response.code
      reason = result.response.failReason
    else
      code = -1
      reason = "Unknown"
    end if
    tubiLog("removeFromQueue returned " + stri(code))
    m.detailScreen.isWaitingForServerResponse = false
    showErrorModal(code, reason, onRemoveFromQueueSelected, cancelHistoryQueueChange)
    return
  end if

  m.detailScreen.isWaitingForServerResponse = false
  contentAndIndex = m.detailScreenContent.peek()
  if contentAndIndex <> invalid and contentAndIndex.content <> invalid
    content = contentAndIndex.content
    bookmarkNode = m.global.bookmarkIds.findNode(content.id)
    if bookmarkNode <> invalid then
      m.global.bookmarkIds = immutableRemoveChild(m.global.bookmarkIds, bookmarkNode)
    end if
    m.detailScreen.isBookmark = false

    'user tracking
    m.global.trackingLoggingTask.trackEvent = {
      trackType: "deleteBookmark"
      value: content.id
    }
  end if
  onHistoryQueueChange()
End Function


Function onRemoveFromHistorySelected()
  tubiLog("DetailScreenHelpers.onRemoveFromHistorySelected")
  if m.detailScreen.isWaitingForServerResponse <> true
    contentAndIndex = m.detailScreenContent.peek()
    if contentAndIndex <> invalid and contentAndIndex.content <> invalid
      history = m.global.historyIds.findNode(contentAndIndex.content.id)
      if history <> invalid and history.historyId <> invalid
        content = clone(contentAndIndex.content)
        m.detailScreen.removeHistoryTitle = "Removing..."
        content.historyId = history.historyId
        if m.userTask <> invalid
          unobserveAllScoped(m.userTask)
        end if
        m.userTask = CreateObject("roSGNode", "AuthTask")
        m.userTask.functionName = "removeFromHistory"
        m.userTask.content = content
        m.userTask.observeField("result", "onHistoryRemoved")
        m.userTask.control = "RUN"
        m.detailScreen.isWaitingForServerResponse = true
      end if
    end if
  end if
End Function


Function onHistoryRemoved() As Void
  tubiLog("DetailScreenHelpers.onHistoryRemoved")
  result = m.userTask.result
  m.userTask.unobserveField("result")
  m.userTask = invalid

  if result = invalid or result.response.code <> 204 then
    if result <> invalid
      code = result.response.code
      reason = result.response.failReason
    else
      code = -1
      reason = "Unknown"
    end if
    tubiLog("removeFromHistory returned " + stri(code))
    showErrorModal(code, reason, onRemoveFromHistorySelected, cancelHistoryQueueChange)
    return
  end if

  m.detailScreen.isWaitingForServerResponse = false
  contentAndIndex = m.detailScreenContent.peek()
  if contentAndIndex <> invalid and contentAndIndex.content <> invalid
    historyNode = m.global.historyIds.findNode(contentAndIndex.content.id)
    if historyNode <> invalid
      m.global.historyIds = immutableRemoveChild(m.global.historyIds, historyNode)
    end if
    m.detailScreen.isHistory = false
  end if
  onHistoryQueueChange()
End Function


Function cancelHistoryQueueChange()
  m.detailScreen.isWaitingForServerResponse = false
End Function


Function onRelatedContentSelected()
  contentAndIndex = m.detailScreenContent.peek()
  if contentAndIndex <> invalid and contentAndIndex.content <> invalid
    content = contentAndIndex.content.relatedContent.getChild(m.detailScreen.relatedContentSelected)
    if content <> invalid
      sourceTrackingUri = m.detailScreen.trackingUri + "/related/" + m.detailScreen.relatedContentSelected.toStr()
      showDetailScreen(content, sourceTrackingUri)
    end if
  end if
End Function


Function onDetailBackPressed()
  m.detailScreenContent.pop()
  ' cancel outstanding metadata fetches
  if m.refreshTask <> invalid
    m.refreshTask.unobserveField("response")
    m.refreshTask.unobserveField("error")
    m.refreshTask = invalid
  end if
  if m.detailScreenContent.count() > 0
    contentAndIndex = m.detailScreenContent.peek()
    if contentAndIndex <> invalid and contentAndIndex.content <> invalid
      oldTrackingUri = m.detailScreen.trackingUri
      m.detailScreen.trackingUri = populateDetailTrackingUri(contentAndIndex.content, getEpisodeContent(contentAndIndex.series2dIndex, contentAndIndex.content))
      screenTrackingNavigate(oldTrackingUri, m.detailScreen.trackingUri)
      screenTrackingLoad(m.detailScreen.trackingUri)
      populateDetailScreen(contentAndIndex)
    end if
  else
    ' TODO(Chris): This is in terrible need of refactor. We shouldn't be calling this directly
    ' but we have to invoke the "empty stack" logic at this point.
    onKeyEvent("back", true)
  end if
End Function