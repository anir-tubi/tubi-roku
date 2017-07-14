Function init()
  m.Info = m.top.findNode("InfoPanel")
  m.Hero = m.top.findNode("HeroBackground")
  m.Menu = m.top.findNode("Menu")
  m.AuthTask = m.top.findNode("AuthTask")
  m.top.observeField("content", "onContentChange")
  m.top.observeField("shortContent", "onShortContentChange")
  m.top.observeField("signedIn", "onSignedInChange")
  m.top.observeField("contentDetailResponse", "onContentReceived")
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("episodeSelection", "onEpisodeSelectionChange")
  m.Menu.observeField("itemSelected", "onMenuItemSelected")
  m.defaultHeroUri = "pkg:/images/grid-default-blurred.jpg"

  m.ResumeMenuItem = m.top.findNode("ResumeMenuItem")
  m.PlayMenuItem = m.top.findNode("PlayMenuItem")
  m.EpisodesMenuItem = m.top.findNode("EpisodesMenuItem")
  m.AddQueueMenuItem = m.top.findNode("AddQueueMenuItem")
  m.RemoveQueueMenuItem = m.top.findNode("RemoveQueueMenuItem")
  m.RemoveHistoryMenuItem = m.top.findNode("RemoveHistoryMenuItem")
  m.WatchTrailerMenuItem = m.top.findNode("WatchTrailerMenuItem")

  m.isWaitingForServerResponse = false
End Function

Function onScreenFocusChange()
  tubiLog("DetailScreen.onScreenFocusChange")
  if m.top.hasFocus() then
    ' defaulted to screen, move to a subcomponent
    m.Menu.setFocus(true)
  end if
End Function

Function onContentReceived()
  tubiLog("DetailScreen.onContentReceived")
  response = m.top.contentDetailResponse.response
  if response.code >= 200 and response.code < 300 then
    fullContent = m.top.contentDetailResponse.convertedMetadata
    deeplinkType = m.top.shortContent.deeplinkType
    
    'we got the response for an episode, but we need the whole series due to deeplink requirements
    'fullContent.parentId will be empty string for the series response even if  m.top.shortContent.deeplinkType = "season"
    if (deeplinkType = "season" or deeplinkType = "episode") and fullContent.parentId <> ""
      seriesContent = CreateObject("roSGNode", "TubiContentNode")
      seriesContent.id = fullContent.parentId
      seriesContent.type = "series"
      loadContentDetails(seriesContent)

    else
      m.top.content = fullContent
    end if

  else
    'TODO(Chris): Show error modal here
    testLog("Content detail returned " + stri(response.code))
    showErrorModal(response.code, response.failReason, retryContentDetail, cancelContentDetail)
  end if
End Function

' Trigger reload via shortContent field
Function retryContentDetail()
  m.top.shortContent = m.top.shortContent
End Function

' If we can't get content, nothing else to do but exit
Function cancelContentDetail()
  m.top.itemFailed = true
End Function


'''''''''''''''''''
' onContentChange
'
' Full content description has arrived
Function onContentChange() As Void
  tubiLog("DetailScreen.onContentChange")
  if m.top.content.type = "video"
    'auto start deep link content if it's a video
    if m.top.deepLinkHandled = false and m.top.shortContent.deeplinkType = "movie"
      m.top.playSelected = true
    end if
    drawSubComponents()
  else if m.top.content.type = "series"
     'don't call drawSubComponents() here since it will run when m.top.episodeSelection is set

    ' Deep link gave us the episode id we need to seek to
    if m.top.deepLinkHandled = false and m.top.shortContent.deeplinkType = "season"
      tubiLog("Finding episode " + m.top.shortContent.id + " in series " + m.top.content.id)
      m.top.episodeSelection = findEpisodeInSeries(m.top.shortContent.id)

      'tell the controller to open the episode selection page
      m.top.episodeListSelected = true

    else if m.top.deepLinkHandled = false and m.top.shortContent.deeplinkType = "episode"
      tubiLog("Finding episode " + m.top.shortContent.id + " in series " + m.top.content.id)
      m.top.episodeSelection = findEpisodeInSeries(m.top.shortContent.id)
      m.top.playSelected = true

    else
      episodeSelection = [0,0]
      if m.global.historyIds <> invalid then
        history = m.global.historyIds.findNode(m.top.content.id)
        if history <> invalid and history.currentEpisodeId <> invalid and history.currentEpisodeId <> "" then
          tubiLog("Finding current episode " + history.currentEpisodeId + " in series " + m.top.content.id)
          episodeSelection = findEpisodeInSeries(history.currentEpisodeId)
        end if
      end if
      m.top.episodeSelection = episodeSelection
    endif
  end if
End Function


Function findEpisodeInSeries(episodeId As String)
  for i=0 to m.top.content.getChildCount()-1
    season = m.top.content.getChild(i)
    for j=0 to season.getChildCount()-1
      episode = season.getChild(j)
      if episode.id = episodeId then
        tubiLog("Episode is [" + stri(i) + "," + stri(j) + "]")
        return [i,j]
      end if
    end for
  end for
  return [0,0]
End Function


'''''''''''''''''''''''
' drawSubComponents
'
' Decouple from onContentChange since episode selection also needs this
Function drawSubComponents()
  tubiLog("DetailScreen.drawSubComponents")
  if m.top.content.type = "video"
    m.Info.mode = "movie"
    m.Info.content = m.top.content
  else if m.top.content.type = "series"
    m.Info.mode = "series"
    ' clone the content object since we want the SERIES title & description, but the EPISODE details
    episode = getEpisodeContent(m.top.episodeSelection)
    episode_title = ""
    if episode = invalid then
      ' something failed, try to get the first season-episode
      m.top.episodeSelection = [0,0]
      episode = getEpisodeContent(m.top.episodeSelection)
      if episode = invalid then
        ' Protect against a series with empty season/episode content
        episode = m.top.content
      end if
    end if
    infoPanelContent = clone(episode)
    infoPanelContent.episode_title = episode.title
    infoPanelContent.title = m.top.content.title
    infoPanelContent.description = m.top.content.description
    m.Info.content = infoPanelContent
  end if

  if m.top.content.backgrounds <> invalid and m.top.content.backgrounds.count() > 0 then
    m.top.backgroundUriList = m.top.content.backgrounds
  else
    m.top.backgroundUriList = [m.defaultHeroUri]
  end if

  setMenuItems()
End Function



''''''''''''''''''''''
' onSignedInChange
'
Function onSignedInChange()
  setMenuItems()
End Function

''''''''''''''''''''''
' getEpisodeContent
'
Function getEpisodeContent(selection As Object) As Object
  season = m.top.content.getChild(m.top.episodeSelection[0])
  if season <> invalid then
    episode = season.getChild(m.top.episodeSelection[1])
    if episode <> invalid then return episode
  end if
  return invalid
End Function


''''''''''''''''''''''''
' onShortContentChange
'
' Seed for content received, retrieve the full content details
Function onShortContentChange()
  tubiLog("DetailScreen.onShortContentChange")  
  if m.top.shortContent <> invalid
    loadContentDetails(m.top.shortContent)

    'set the tracking URI
    trackUri = invalid
    content = m.top.shortContent
    if content["type"] = m.global.constants.ui.contentTypes.series
      trackUri = "/series/"

      if content.id <> invalid
        ' trim leading "0" off series id
        trackUri = trackUri + Mid(content.id, 2)

        if m.global.historyIds <> invalid then
          history = m.global.historyIds.findNode(content.id)
          if history <> invalid and history.currentEpisodeId <> invalid and history.currentEpisodeId.len() > 0
            trackUri = trackUri + "/" + history.currentEpisodeId
          end if
        end if
      end if

    else if content["type"] = m.global.constants.ui.contentTypes.video
      trackUri = "/video/"
      
      if content.id <> invalid
        trackUri = trackUri + content.id
      end if
    end if

    if trackUri <> invalid then m.top.trackingUri = trackUri
  end if
End Function


''''''''''''''''''''''
' setMenuItems
'
' Add appropriate menu items for the selection
Function setMenuItems() As Void
  tubiLog("DetailScreen.setMenuItems")

  ' if content is not set, don't show a menu
  if m.top.content = invalid then 
    return
  end if

  menuItems = CreateObject("roSGNode", "ContentNode")

  if m.top.content.type = "video" then
    focusedContent = m.top.content
  else if m.top.content.type = "series" then
    focusedContent = m.top.content
    season = m.top.content.getChild(m.top.episodeSelection[0])
    if season <> invalid then
      episode = season.getChild(m.top.episodeSelection[1])
      if episode <> invalid then
        focusedContent = episode
      end if
    end if
  end if

  history = invalid
  bookmark = invalid
  if m.global.historyids <> invalid then
    ' history should always deal with videos (movies or episodes)
    history = m.global.historyIds.findNode(focusedContent.id)
  end if
  if m.global.bookmarkIds <> invalid then
    ' bookmarks always deal with movie or series, not episodes
    bookmark = m.global.bookmarkIds.findNode(m.top.content.id)
  end if

  if history <> invalid and history.nowPos <> invalid and history.nowPos <> 0 then
    m.ResumeMenuItem.length = focusedContent.length
    m.ResumeMenuItem.playstart = history.nowPos
    menuItems.appendChild(m.ResumeMenuItem)
  end if

  menuItems.appendChild(m.PlayMenuItem)

  if m.top.content.trailerUrls <> invalid and m.top.content.trailerUrls.count() > 0 then
    menuItems.appendChild(m.WatchTrailerMenuItem)
  end if

  if m.top.content.type = "series" then
    menuItems.appendChild(m.EpisodesMenuItem)
  end if

  ' bookmarks follow series or movie, so don't use focusedContent here
  if m.top.signedIn = true and bookmark <> invalid and bookmark.bookmarkId <> "" then
    menuItems.appendChild(m.RemoveQueueMenuItem)
    m.RemoveQueueMenuItem.title = "Remove from queue"
  else 
    menuItems.appendChild(m.AddQueueMenuItem)
    m.AddQueueMenuItem.title = "Add to queue"  ' reset this for the next time it shows
  end if

  ' history will be set on the series if any of the episodes have history, so look at m.top.content
  if history <> invalid then
    menuItems.appendChild(m.RemoveHistoryMenuItem)
    m.RemoveHistoryMenuItem.title = "Remove from history"
  end if

  m.Menu.content = menuItems
  m.Menu.visible = true
  if m.top.hasFocus() then m.Menu.setFocus(true)

  'set the position menu cursor to be stationary if there are more than 4 menu items
  tempMenuItem = CreateObject("roSGNode", m.Menu.itemComponentName) 'should be a DetailMenuItem.xml component
  itemsPerMenu = m.Menu.height \ tempMenuItem.height

  if m.Menu.content.getChildCount() > itemsPerMenu
    m.Menu.scrollHeight = (m.Menu.height \ itemsPerMenu)
  end if
  
  m.isWaitingForServerResponse = false
End Function


''''''''''''''''''''''''
' onMenuItemSelected
'
Function onMenuItemSelected()
  tubiLog("DetailScreen.onMenuItemSelected")

  selection = m.Menu.content.getChild(m.Menu.itemSelected)
  if selection <> invalid then
    print "Menu item selected: " + selection.title

    if selection.id = "ResumeMenuItem" then
      m.top.resumeSelected = true
    else if selection.id = "PlayMenuItem" then
      m.top.playSelected = true
    else if selection.id = "WatchTrailerMenuItem" then
      m.top.watchTrailerSelected = true
    else if selection.id = "EpisodesMenuItem"
      m.top.episodeListSelected = true
    else if selection.id = "AddQueueMenuItem" then
      if m.top.signedIn = true then
        'TODO(Chris): bookmark the content and update 'shortContent' which is owned by the controller
        addToQueue()
      else
        m.Dialog = m.top.createChild("ModalDialogScreen")
        m.Dialog.title = "Sign in to add to your queue"
        m.Dialog.message = "You must be signed in in order to add a title to your queue."
        m.Dialog.buttons = ["Sign In or Register", "Cancel"]
        m.Dialog.observeField("buttonSelected", "onDialogButton")
        m.Dialog.setFocus(true)
      end if
    else if selection.id = "RemoveQueueMenuItem" then
      removeFromQueue()
    else if selection.id = "RemoveHistoryMenuItem" then
      removeFromHistory()
    end if
  end if
End Function


''''''''''''''''''''
' onDialogButton
'
Function onDialogButton()
  buttonSelected = m.Dialog.buttonSelected
  m.top.removeChild(m.Dialog)
  m.Dialog.unobserveField("buttonSelected")
  m.Dialog = invalid
  m.Menu.setFocus(true)
  if buttonSelected = 0 then
    m.top.signInSelected = true
  end if
End Function


'''''''''''''''''''''
' onEpisodeSelectionChange
'
' Show details for the selected episode
Function onEpisodeSelectionChange()
  tubiLog("DetailScreen.onEpisodeSelectionChange")
  tubiLog("Episode [" + stri(m.top.episodeSelection[0]) + "," + stri(m.top.episodeSelection[1]) + "] selected")
  drawSubComponents()
End Function


'''''''''''''''''''''''''''
' loadContentDetails
'
'
Function loadContentDetails(content)
  tubiLog("DetailScreen.loadDetails")
  settings = m.global.constants.settings
  url = m.global.constants.urls.cms.singleContent
  platform = m.global.constants.platform
  deviceInfo = m.global.constants.deviceInfo

  request = {
    url: url
    node: m.top
    field: "contentDetailResponse"
    options: {
      params: {
        "app_id": settings.shortAppName
        platform: platform
        "content_id": content.id
        ' "content_ids": contentId
        ' fields: "*(id,type,title,duration,ratings,description,year,posterarts,subtitles,lang,url,publisher_id,actors,directors,tags,children,credit_cuepoints)"
      }
    }
    name: "getSingleContent"
  }
  m.global.metadataFetchTask.request = request
End Function


Function addToQueue()
  tubiLog("DetailScreen.addToQueue")
  if m.isWaitingForServerResponse = false
    m.AuthTask.functionName = "addToQueue"
    m.AuthTask.content = m.top.content
    m.AuthTask.observeField("bookmarkId", "onBookmarked")
    m.AuthTask.control = "RUN"
    m.isWaitingForServerResponse = true
    m.AddQueueMenuItem.title = "Adding..."
  end if
End Function


'''''''''''''''''''
' onBookmarked
'
Function onBookmarked() As Void
  tubiLog("DetailScreen.onBookmarked")
  'TODO(Chris): add bookmark id to global tree
  m.AuthTask.unobserveField("bookmarkId")

  if m.AuthTask.bookmarkId = invalid then
    code = -1
    reason = "Unknown"
    tubiLog("addToQueue returned " + stri(code))
    m.isWaitingForServerResponse = false
    showErrorModal(code, reason, addToQueue, cancelHistoryQueueChange)
    return
  end if

  tubiLog("Got bookmarkId " + m.AuthTask.bookmarkId + " for content " + m.top.content.id)

  ' TODO(Chris): Move management of this global list off to a library
  ' or task

  ' if deep linked here, we may not have the bookmarks loaded.  Also, there is the chance
  ' of a race condition where bookmarks are in flight.
  if m.global.bookmarkIds <> invalid
    newBookmark = CreateObject("roSGNode", "TubiContentNode")
    newBookmark.id = m.top.content.id
    newBookmark.type = m.top.content.type
    newBookmark.bookmarkId = m.AuthTask.bookmarkId
    m.global.bookmarkIds.insertChild(newBookmark, 0)
  end if
  m.top.shortContent = m.top.shortContent

  'user tracking
  m.global.trackingLoggingTask.trackEvent = {
    trackType: "addBookmark"
    value: m.top.content.id
    ctx: m.top.trackingUri
  }

  ' Notify the controller so that it can react
  m.top.addToQueueSelected = true
End Function

Function cancelHistoryQueueChange()
  m.isWaitingForServerResponse = false
  setMenuItems()
End Function


'''''''''''''''''''''
' removeFromQueue
'
' This is not ideal.  We have to remove from 3 places: local content node, 
' m.global bookmarks, and the server
Function removeFromQueue()
  tubiLog("DetailScreen.removeFromQueue")
  if m.isWaitingForServerResponse = false
    m.AuthTask.functionName = "removeFromQueue"
    content = clone(m.top.content)
'#####
print "***** Removing content "; content.id; " from queue"
'#####
    if m.global.bookmarkIds <> invalid then
      bookmark = m.global.bookmarkIds.findNode(content.id)
      content.bookmarkId = bookmark.bookmarkId
'#####
print "***** Removing bookmark "; content.bookmarkId; " from queue"
'#####
    end if
    m.AuthTask.content = content
    m.AuthTask.observeField("result", "onBookmarkRemoved")
    m.AuthTask.control = "RUN"
    m.isWaitingForServerResponse = true
    m.RemoveQueueMenuItem.title = "Removing..."
  end if
End Function

Function onBookmarkRemoved() As Void
  tubiLog("DetailScreen.onBookmarkRemoved")
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
    m.isWaitingForServerResponse = false
    showErrorModal(code, reason, removeFromQueue, cancelHistoryQueueChange)
    return
  end if

  if m.global.bookmarkIds <> invalid
    bookmarkNode = m.global.bookmarkIds.findNode(m.top.content.id)
    if bookmarkNode <> invalid then m.global.bookmarkIds.removeChild(bookmarkNode)
  end if
  'TODO(Chris): remove this and rely on global bookmarkIds for rendering proper menu (rather than needing a fully-realized content rendered by metadatafetchtask)
  m.top.shortContent = m.top.shortContent

  'user tracking
  m.global.trackingLoggingTask.trackEvent = {
    trackType: "deleteBookmark"
    value: m.top.content.id
  }

  ' Notify the controller so that it can react
  m.top.removeFromQueueSelected = true
End Function

'''''''''''''''''''''''
' removeFromHistory
'
Function removeFromHistory()
  tubiLog("DetailScreen.removeFromHistory")
  if m.isWaitingForServerResponse = false
    m.AuthTask.functionName = "removeFromHistory"
    content = clone(m.top.content)
    if m.global.historyIds <> invalid then
      history = m.global.historyIds.findNode(m.top.content.id)
      content.historyId = history.historyId
    end if
    m.AuthTask.content = content
    m.AuthTask.observeField("result", "onHistoryRemoved")
    m.AuthTask.control = "RUN"
    m.isWaitingForServerResponse = true
    m.RemoveHistoryMenuItem.title = "Removing..."
  end if
End Function

Function onHistoryRemoved() As Void
  tubiLog("DetailScreen.onHistoryRemoved")
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
    m.isWaitingForServerResponse = false
    showErrorModal(code, reason, removeFromHistory, cancelHistoryQueueChange)
    return
  end if

  if m.global.historyIds <> invalid
    historyNode = m.global.historyIds.findNode(m.top.shortContent.id)
    if historyNode <> invalid
      m.global.historyIds.removeChild(historyNode)
    end if
  end if
  m.top.removeFromHistorySelected = true

  ' force reload the content, which will clear all the history and nowPos
  m.top.shortContent = m.top.shortContent
End Function


'''''''''''''''''''''''
' onKeyEvent
'
' Hijack any back button presses before they make it to the screen stack if we are waiting for a server
' response from any of add/remove queue/history so that we make sure the category screen can update with new user category content
Function onKeyEvent(key As String, press As Boolean)
  tubiLog("DetailScreen.onKeyEvent key = " + key)
  if press then
    if key = "back"
      if m.isWaitingForServerResponse = true
        return true
      end if
    end if
  end if

  return false
End Function


