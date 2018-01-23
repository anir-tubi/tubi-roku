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
  tubiLog("DetailScreenHelpers.getSeriesContent")
  if content = invalid then content = m.detailScreenContent

  if content <> invalid then 
    if m.refreshTask <> invalid
      m.refreshTask.unobserveField("response")
      m.refreshTask.unobserveField("error")
    end if
    m.refreshTask = CreateObject("roSGNode", "DetailMetadataTask")
    m.refreshTask.contentFragment = content
    m.refreshTask.observeField("response", "onSingleContentResponse")
    m.refreshTask.observeField("error", "onSingleContentError")
    m.refreshTask.control = "RUN"
  end if
End Function


Function onSingleContentResponse(msg) As Void
  tubiLog("DetailScreenHelpers.onSeriesContentResponse")
  'refreshedContent should hold all the series info that is needed for the detail screen to function
  refreshedContent = msg.GetData()
  m.detailScreenContent = refreshedContent

  m.refreshTask.unobserveField("response")
  m.refreshTask.unobserveField("error")
  m.refreshTask = invalid

  afterFn = invalid  ' the function to execute once we've sorted the detail screen out
  if m.enteredFromDeepLink = true and m.top.deepLinkContent <> invalid
    if m.top.deepLinkContent.deeplinkType = "series"
      m.detailScreen2dIndex = [0,0]
    else if (m.top.deepLinkContent.deeplinkType = "season" or m.top.deepLinkContent.deeplinkType = "episode") and m.detailScreenContent.type = m.constants.ui.contentTypes.video
      ' deeplink sent us an episode id, so here, we have full info for an episode, but we need full info for a series
      emptySeriesNode = CreateObject("roSGNode", "TubiContentNode")
      emptySeriesNode.type = m.constants.ui.contentTypes.series
      emptySeriesNode.id = m.detailScreenContent.seriesId
      getSingleContentFromServer(emptySeriesNode)
      return
    else if m.top.deepLinkContent.deeplinkType = "season" and m.detailScreenContent.type = m.constants.ui.contentTypes.series
      ' we've now received the full series info, so we can build the relevant screens
      m.detailScreen2dIndex = findEpisode2dIndex(m.top.deepLinkContent.id, m.detailScreenContent)  ' this will find the episode if deep link was episode id, or [0,0] if it was series id
      afterFn = onEpisodeList
    else if m.top.deepLinkContent.deeplinkType = "episode" and m.detailScreenContent.type = m.constants.ui.contentTypes.series
      ' we now have the full series info for episode deeplinks
      m.detailScreen2dIndex = findEpisode2dIndex(m.top.deepLinkContent.id, m.detailScreenContent)  ' this will find the episode if deep link was episode id, or [0,0] if it was series id

      'determine if we need to resume or play from start the deeplinked episode
      if m.top.deepLinkContent.nowPos <> invalid and m.top.deepLinkContent.nowPos > 0
        episode = getEpisodeContent(m.detailScreen2dIndex, m.detailScreenContent)
        episode.nowPos = m.top.deepLinkContent.nowPos
        afterFn = onResume
      else
        afterFn = onPlay
      end if
    else if m.top.deepLinkContent.deeplinkType = "movie"
      'determine if we need to resume or play from start the deeplinked movie
      if m.top.deepLinkContent.nowPos <> invalid and m.top.deepLinkContent.nowPos > 0
        m.detailScreenContent.nowPos = m.top.deepLinkContent.nowPos
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
    if m.detailScreenContent.type = m.constants.ui.contentTypes.series and m.detailScreen2dIndex[0] = -1
      history = m.global.historyIds.findNode(m.detailScreenContent.id)
      if history <> invalid
        m.detailScreen2dIndex = findEpisode2dIndex(history.currentEpisodeId, m.detailScreenContent)
      else
        m.detailScreen2dIndex = [0,0]
      end if
    end if
  end if

  ' showDetailScreen defers navigation tracking for refreshed content or deep links, so do it here
  m.detailScreen.trackingUri = populateDetailTrackingUri(m.detailScreenContent, getEpisodeContent(m.detailScreen2dIndex, m.detailScreenContent))
  if previousScreen() <> invalid
    screenTrackingNavigate(previousScreen(), m.detailScreen)
  end if
  screenTrackingLoad(m.detailScreen)

  populateDetailScreen(m.detailScreenContent)
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
  if m.detailScreenContent <> invalid then
    if m.detailScreenContent.type = m.constants.ui.contentTypes.video then
      videoToPlay = m.detailScreenContent
    else
      videoToPlay = getEpisodeContent(m.detailScreen2dIndex, m.detailScreenContent)
    end if
  end if
  return videoToPlay
End Function


Function onAddToQueueSelected()
  tubiLog("DetailScreenHelpers.addToQueue")
  if m.authTask.authInfo = invalid
    signInMessage = "You must be signed in, in order to add a title to your queue."
    m.signInModal = showSignInModal("onSignInModalButtonSelected", signInMessage)
  else if m.detailScreen.isWaitingForServerResponse <> true
    m.detailScreen.addToQueueTitle = "Adding..."
    m.AuthTask.functionName = "addToQueue"
    m.AuthTask.content = m.detailScreenContent
    m.AuthTask.observeField("bookmarkId", "onBookmarked")
    m.AuthTask.control = "RUN"
    m.detailScreen.isWaitingForServerResponse = true
  end if
End Function


' handles the response of a user who has been presented a sign in modal on the details screen
Function onSignInModalButtonSelected()
  buttonSelected = getModalResult(m.signInModal)

  m.signInModal = closeModal(m.signInModal)   'set to invalid
  if buttonSelected = 0 then
    onSignInSelected()
  else
    m.detailScreen.setFocus(true)
  end if
End Function


''''''''''''''''''
' onBookmarked

Function onBookmarked() As Void
  tubiLog("DetailScreenHelpers.onBookmarked")
  m.AuthTask.unobserveField("bookmarkId")

  if m.AuthTask.bookmarkId = invalid then
    code = -1
    reason = "Unknown"
    tubiLog("addToQueue returned " + stri(code))
    m.detailScreen.isWaitingForServerResponse = false
    showErrorModal(code, reason, onAddToQueueSelected, cancelHistoryQueueChange)
    return
  end if

  tubiLog("Got bookmarkId " + m.AuthTask.bookmarkId + " for content " + m.detailScreenContent.id)

  ' TODO(Chris): Move management of this global list off to a library
  ' or task
  newBookmark = CreateObject("roSGNode", "BookmarkContentNode")
  newBookmark.id = m.detailScreenContent.id
  newBookmark.type = m.detailScreenContent.type
  newBookmark.bookmarkId = m.AuthTask.bookmarkId
  m.global.bookmarkIds.insertChild(newBookmark, 0)
  m.detailScreen.isBookmark = true
  m.detailScreen.isWaitingForServerResponse = false

  'user tracking
  m.global.trackingLoggingTask.trackEvent = {
    trackType: "addBookmark"
    value: m.detailScreenContent.id
    ctx: m.top.trackingUri
  }

  onHistoryQueueChange()
End Function


Function onRemoveFromQueueSelected()
  tubiLog("DetailScreenHelpers.onRemoveFromQueueSelected")
  if m.detailScreen.isWaitingForServerResponse <> true
    m.detailScreen.removeQueueTitle = "Removing..."
    m.AuthTask.functionName = "removeFromQueue"
    content = clone(m.detailScreenContent)
    bookmark = m.global.bookmarkIds.findNode(content.id)
    content.bookmarkId = bookmark.bookmarkId
    m.AuthTask.content = content
    m.AuthTask.observeField("result", "onBookmarkRemoved")
    m.AuthTask.control = "RUN"
    m.detailScreen.isWaitingForServerResponse = true
  end if
End Function


Function onBookmarkRemoved() As Void
  tubiLog("DetailScreenHelpers.onBookmarkRemoved")
  m.AuthTask.unobserveField("result")

  if m.AuthTask.result = invalid or m.AuthTask.result.response.code <> 204 then
    if m.AuthTask.result <> invalid
      code = m.AuthTask.result.response.code
      reason = m.AuthTask.result.response.failReason
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
  bookmarkNode = m.global.bookmarkIds.findNode(m.detailScreenContent.id)
  if bookmarkNode <> invalid then m.global.bookmarkIds.removeChild(bookmarkNode)
  m.detailScreen.isBookmark = false

  'user tracking
  m.global.trackingLoggingTask.trackEvent = {
    trackType: "deleteBookmark"
    value: m.detailScreenContent.id
  }

  onHistoryQueueChange()
End Function


Function onRemoveFromHistorySelected()
  tubiLog("DetailScreenHelpers.onRemoveFromHistorySelected")
  if m.detailScreen.isWaitingForServerResponse <> true
    m.detailScreen.removeHistoryTitle = "Removing..."
    m.AuthTask.functionName = "removeFromHistory"
    content = clone(m.detailScreenContent)
    history = m.global.historyIds.findNode(m.detailScreenContent.id)

    if history <> invalid and history.historyId <> invalid
      content.historyId = history.historyId
      m.AuthTask.content = content
      m.AuthTask.observeField("result", "onHistoryRemoved")
      m.AuthTask.control = "RUN"
      m.detailScreen.isWaitingForServerResponse = true
    end if
  end if
End Function


Function onHistoryRemoved() As Void
  tubiLog("DetailScreenHelpers.onHistoryRemoved")
  m.AuthTask.unobserveField("result")

  if m.AuthTask.result = invalid or m.AuthTask.result.response.code <> 204 then
    if m.AuthTask.result <> invalid
      code = m.AuthTask.result.response.code
      reason = m.AuthTask.result.response.failReason
    else
      code = -1
      reason = "Unknown"
    end if
    tubiLog("removeFromHistory returned " + stri(code))
    showErrorModal(code, reason, onRemoveFromHistorySelected, cancelHistoryQueueChange)
    return
  end if

  m.detailScreen.isWaitingForServerResponse = false
  historyNode = m.global.historyIds.findNode(m.detailScreenContent.id)
  if historyNode <> invalid then m.global.historyIds.removeChild(historyNode)
  m.detailScreen.isHistory = false

  onHistoryQueueChange()
End Function


Function cancelHistoryQueueChange()
  m.detailScreen.isWaitingForServerResponse = false
End Function