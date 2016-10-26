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

End Function

Function onScreenFocusChange()
  tubiLog("DetailScreen.onScreenFocusChange")
  if m.top.hasFocus() then
    ' defaulted to screen, move to a subcomponent
    m.Menu.setFocus(true)
  end if
End Function

Function onContentReceived()
  response = m.top.contentDetailResponse.response
  if response.code >= 200 and response.code < 300 then 
    m.top.content = m.top.contentDetailResponse.convertedMetadata
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
  m.top.setFocus(true)
End Function


'''''''''''''''''''
' onContentChange
'
' Full content description has arrived
Function onContentChange() As Void
  tubiLog("DetailScreen.onContentChange")
  if m.top.content.type = "video"
    ' Special case here.  If this video is an episode of a series, load the full series content
    if m.top.content.seriesId <> invalid and m.top.content.seriesId <> "" then
      tubiLog("DetailScreen detected episode, loading full series")
      seriesContent = CreateObject("roSGNode", "TubiContentNode")
      seriesContent.id = m.top.content.seriesId
      seriesContent.type = "series"
      loadContentDetails(seriesContent)
      return
    end if
  else if m.top.content.type = "series"

    ' Deep link gave us only the episode, seek to it
    if m.top.shortContent.id <> m.top.content.id then
      tubiLog("Finding episode " + m.top.shortContent.id + " in series " + m.top.content.id)
      ' arrived here from an episode link
      m.top.episodeSelection = findEpisodeInSeries(m.top.shortContent.id)
    else if m.top.content.currentEpisodeId <> invalid and m.top.content.currentEpisodeId <> "" then
      tubiLog("Finding current episode " + m.top.shortContent.id + " in series " + m.top.content.id)
      m.top.episodeSelection = findEpisodeInSeries(m.top.content.currentEpisodeId)
    endif
  end if

  drawSubComponents()
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
  if m.top.content.type = "video"
    m.Info.mode = "movie"
    m.Info.content = m.top.content
  else if m.top.content.type = "series"
    m.Info.mode = "series"
    ' clone the content object since we want the SERIES title & description, but the EPISODE details
    infoPanelContent = CreateObject("roSGNode", "TubiContentNode")   
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
    infoPanelContent.setFields(episode.getFields())
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
  series = m.top.content.getChild(m.top.episodeSelection[0])
  if series <> invalid then
    episode = series.getChild(m.top.episodeSelection[1])
    if episode <> invalid then return episode
  end if
  return invalid
End Function


''''''''''''''''''''''''
' onShortContentChange
'
' Seed for content received, retrieve the full content details
Function onShortContentChange()
  if m.top.shortContent <> invalid
    loadContentDetails(m.top.shortContent)

    'set the tracking URI
    trackUri = invalid
    content = m.top.shortContent
    if content["type"] = m.global.constants.ui.contentTypes.series
      trackUri = "/series/"

      if content.id <> invalid
        trackUri = trackUri + content.id

        if content.currentEpisodeId <> invalid and content.currentEpisodeId.len() > 0
          trackUri = trackUri + "/" + content.currentEpisodeId
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
  else
    m.Menu.content = invalid
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

  if focusedContent.nowPos <> invalid and focusedContent.nowPos <> 0 then
    m.ResumeMenuItem.length = focusedContent.length
    m.ResumeMenuItem.playstart = focusedContent.nowPos
    menuItems.appendChild(m.ResumeMenuItem)
  end if

  menuItems.appendChild(m.PlayMenuItem)

  if m.top.content.type = "series" then
    menuItems.appendChild(m.EpisodesMenuItem)
  end if

  ' bookmarks follow series or movie, so don't use focusedContent here
  if m.top.signedIn = true and m.top.content.bookmarkId <> invalid and m.top.content.bookmarkId <> "" then
    menuItems.appendChild(m.RemoveQueueMenuItem)
  else 
    menuItems.appendChild(m.AddQueueMenuItem)
  end if

  ' history will be set on the series if any of the episodes have history, so look at m.top.content
  if m.top.content.historyId <> invalid and m.top.content.historyId <> "" then
    menuItems.appendChild(m.RemoveHistoryMenuItem)
  end if

  m.Menu.content = menuItems
  m.Menu.visible = true
  if m.top.hasFocus() then m.Menu.setFocus(true)
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
    else if selection.id = "EpisodesMenuItem"
      m.top.episodeListSelected = true
    else if selection.id = "AddQueueMenuItem" then
      if m.top.signedIn = true then
        'TODO(Chris): bookmark the content and update 'shortContent' which is owned by the controller
        addToQueue()
      else
        m.Dialog = m.top.createChild("ModalDialogScreen")
        m.Dialog.title = "Whoops!"
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

  ' expect that the content here was the bootstrapped content from category list
  contentId = content.id

  if content.type = "series" then
    contentId = "0" + contentId
  end if

  request = {
    url: url
    node: m.top
    field: "contentDetailResponse"
    options: {
      params: {
        "app_id": settings.shortAppName
        platform: platform
        "content_id": contentId
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
  m.AuthTask.functionName = "addToQueue"  
  m.AuthTask.content = m.top.content
  m.AuthTask.observeField("bookmarkId", "onBookmarked")
  m.AuthTask.control = "RUN"
End Function


'''''''''''''''''''
' onBookmarked
'
Function onBookmarked()
  tubiLog("DetailScreen.onBookmarked")
  'TODO(Chris): add bookmark id to global tree
  m.AuthTask.unobserveField("bookmarkId")

  tubiLog("Got bookmarkId " + m.AuthTask.bookmarkId + " for content " + m.top.content.id)

  ' TODO(Chris): Move management of this global list off to a library
  ' or task
  bookmarkIds = m.global.bookmarkIds
  if bookmarkIds <> invalid
    if m.top.shortContent.type = "series"
      tubiLog("Appending series to bookmarks")
      newSeries = {}
      newSeries[m.top.shortContent.id] = m.AuthTask.bookmarkId
      newSeries.append(bookmarkIds.series)
      videos = bookmarkIds.videos
      m.global.bookmarkIds = {
        series: newSeries
        videos: videos
      }
    else if m.top.shortContent.type = "video"
      newVideos = {}
      newVideos[m.top.shortContent.id] = m.AuthTask.bookmarkId
      newVideos.append(bookmarkIds.videos)
      series = bookmarkIds.series
      m.global.bookmarkIds = {
        series: series
        videos: newVideos
      }
    end if
  end if
  bookmarkOrder = m.global.bookmarkOrder
  if bookmarkOrder <> invalid
    if m.top.shortContent.type = "series" then
      newBookmarkOrder = ["0"+m.top.content.id]
    else
      newBookmarkOrder = [m.top.content.id]
    end if
    newBookmarkOrder.append(m.global.bookmarkOrder)
    m.global.bookmarkOrder = newBookmarkOrder
  end if
  ' force reload the content, which will clear all the history and nowPos
  m.top.shortContent = m.top.shortContent

  'user tracking
  m.global.trackingTask.trackEvent = {
    trackType: "addBookmark"
    value: m.top.content.id
    ctx: m.top.trackingUri
  }

  ' Notify the controller so that it can react
  m.top.addToQueueSelected = true
End Function


'''''''''''''''''''''
' removeFromQueue
'
' This is not ideal.  We have to remove from 3 places: local content node, 
' m.global bookmarks, and the server
Function removeFromQueue()
  tubiLog("DetailScreen.removeFromQueue")
  m.AuthTask.functionName = "removeFromQueue"  
  m.AuthTask.content = m.top.content
  m.AuthTask.observeField("result", "onBookmarkRemoved")
  m.AuthTask.control = "RUN"
  'TODO(Chris): show spinner
End Function

Function onBookmarkRemoved()
  tubiLog("DetailScreen.onBookmarkRemoved")
  'TODO(Chris): consume return values and handle errors here
  m.AuthTask.unobserveField("result")

  ' TODO(Chris): Move management of this global list off to a library
  ' or task
  bookmarkIds = m.global.bookmarkIds
  'remove the bookmark
  if bookmarkIds <> invalid
    if m.top.shortContent.type = "series"
      tubiLog("Removing series to bookmarks")
      newSeries = {}
      newSeries.append(bookmarkIds.series)
      newSeries.delete(m.top.shortContent.id)
      videos = bookmarkIds.videos
      m.global.bookmarkIds = {
        series: newSeries
        videos: videos
      }
    else if m.top.shortContent.type = "video"
      newVideos = {}
      newVideos.append(bookmarkIds.videos)
      newVideos.delete(m.top.shortContent.id)
      series = bookmarkIds.series
      m.global.bookmarkIds = {
        series: series
        videos: newVideos
      }
    end if
  end if
  bookmarkOrder = m.global.bookmarkOrder
  if bookmarkOrder <> invalid
    newBookmarkOrder = []
    newBookmarkOrder.append(bookmarkOrder)
    for i=0 to newBookmarkOrder.count()-1
      if m.top.shortContent.type = m.global.constants.ui.contentTypes.series and newBookmarkOrder[i] = "0"+m.top.shortContent.id then newBookmarkOrder.delete(i)
      if m.top.shortContent.type = m.global.constants.ui.contentTypes.video and newBookmarkOrder[i] = m.top.shortContent.id then newBookmarkOrder.delete(i)
    end for
    m.global.bookmarkOrder = newBookmarkOrder
  end if
  ' force reload the content, which will clear all the history and nowPos
  m.top.shortContent = m.top.shortContent

  'user tracking
  m.global.trackingTask.trackEvent = {
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
  m.AuthTask.functionName = "removeFromHistory"  
  m.AuthTask.content = m.top.content
  m.AuthTask.observeField("result", "onHistoryRemoved")
  m.AuthTask.control = "RUN"
End Function


Function onHistoryRemoved()
  tubiLog("DetailScreen.onHistoryRemoved")
  m.AuthTask.unobserveField("result")

  ' TODO(Chris): Move management of this global list off to a library
  ' or task
  historyIds = m.global.historyIds
  if historyIds <> invalid
    if m.top.shortContent.type = "series"
      if historyIds.series[m.top.shortContent.id] <> invalid
        newSeries = {}
        newSeries.append(historyIds.series)
        newSeries.delete(m.top.shortContent.id)
        videos = historyIds.videos
      end if
      ' remove episodes' nowPos
      newVideos = {}
      newVideos.append(historyIds.videos)
      for i=0 to m.top.content.getChildCount()-1
        season = m.top.content.getChild(i)
        for j=0 to season.getChildCount()-1
          episode = season.getChild(j)
          newVideos.delete(episode.id)
        end for
      end for
      m.global.historyIds = {
        series: newSeries
        videos: newVideos
      }

    else if m.top.shortContent.type = "video"
      if historyIds.videos[m.top.shortContent.id] <> invalid
        newVideos = {}
        newVideos.append(historyIds.videos)
        newVideos.delete(m.top.shortContent.id)
        series = historyIds.series
        m.global.historyIds = {
          series: series
          videos: newVideos
        }
      end if
    end if
  end if
  historyOrder = m.global.historyOrder
  if historyOrder <> invalid
    newHistoryOrder = []
    newHistoryOrder.append(historyOrder)

    for i=0 to newHistoryOrder.count()-1
      if m.top.shortContent.type = m.global.constants.ui.contentTypes.series and newHistoryOrder[i] = "0"+m.top.shortContent.id then newHistoryOrder.delete(i)
      if m.top.shortContent.type = m.global.constants.ui.contentTypes.video and newHistoryOrder[i] = m.top.shortContent.id then newHistoryOrder.delete(i)
    end for
    m.global.historyOrder = newHistoryOrder
  end if

  ' Notify the controller so that it can react
  m.top.removeFromHistorySelected = true

  ' force reload the content, which will clear all the history and nowPos
  m.top.shortContent = m.top.shortContent
End Function



