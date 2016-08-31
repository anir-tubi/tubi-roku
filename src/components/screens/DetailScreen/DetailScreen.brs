Function init()
  m.Info = m.top.findNode("InfoPanel")
  m.Hero = m.top.findNode("HeroBackground")
  m.Menu = m.top.findNode("Menu")
  m.top.observeField("content", "onContentChange")
  m.top.observeField("shortContent", "onShortContentChange")
  m.Menu.observeField("itemSelected", "onMenuItemSelected")
  m.defaultHeroUri = "pkg:/images/background-not-on-selection.png"

  m.ResumeMenuItem = m.top.findNode("ResumeMenuItem")
  m.PlayMenuItem = m.top.findNode("PlayMenuItem")
  m.EpisodesMenuItem = m.top.findNode("EpisodesMenuItem")
  m.AddQueueMenuItem = m.top.findNode("AddQueueMenuItem")
  m.RemoveQueueMenuItem = m.top.findNode("RemoveQueueMenuItem")
  m.RemoveHistoryMenuItem = m.top.findNode("RemoveHistoryMenuItem")

  ' The [season, episode] index when the content type is "series"
  m.episodeSelection = [0,0]
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
    else
      m.Info.mode = "movie"
      m.Info.content = m.top.content
    end if
  else if m.top.content.type = "series"

    ' Set the episode selection appropriately
    if m.top.shortContent.id <> m.top.content.id then
      tubiLog("Finding episode " + m.top.shortContent.id + " in series " + m.top.content.id)
      ' arrived here from an episode link
      for i=0 to m.top.content.getChildCount()-1
        season = m.top.content.getChild(i)
        for j=0 to season.getChildCount()-1
          episode = season.getChild(j)
          if episode.id = m.top.shortContent.id then
            tubiLog("Episode is [" + stri(i) + "," + stri(j) + "]")
            m.episodeSelection = [i,j]
          end if
        end for
      end for
    endif

    'TODO(Chris): Also check if there was a resume we can apply

    m.Info.mode = "series"
    ' clone the content object since we want the SERIES title & description, but the EPISODE details
    infoPanelContent = CreateObject("roSGNode", "TubiContentNode")   
    episode = getEpisodeContent(m.episodeSelection)
    episode_title = ""
    if episode = invalid then
      ' something failed, try to get the first season-episode
      m.episodeSelection = [0,0]
      episode = getEpisodeContent(m.episodeSelection)
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
    m.Hero.uri = m.top.content.backgrounds[0]
  else
    m.Hero.uri = m.defaultHeroUri
  end if
  setMenuItems()
End Function


''''''''''''''''''''''
' getEpisodeContent
Function getEpisodeContent(selection As Object) As Object
  series = m.top.content.getChild(m.episodeSelection[0])
  if series <> invalid then
    episode = series.getChild(m.episodeSelection[1])
    if episode <> invalid then return episode
  end if
  return invalid
End Function


''''''''''''''''''''''''
' onShortContentChange
'
' Seed for content received, retrieve the full content details
Function onShortContentChange()
  if m.top.shortContent <> invalid then loadContentDetails(m.top.shortContent)
End Function


''''''''''''''''''''''
' setMenuItems
'
' Add appropriate menu items for the selection
Function setMenuItems()
  tubiLog("DetailScreen.setMenuItems")
  menuItems = CreateObject("roSGNode", "ContentNode")
  
  'TODO(Chris): Add resume button here when applicable, format text as needed for series
  menuItems.appendChild(m.ResumeMenuItem)

  if m.top.content.type = "video" then
    menuItems.appendChild(m.PlayMenuItem)
  else if m.top.content.type = "series" then
    menuItems.appendChildren([
      m.PlayMenuItem
      m.EpisodesMenuItem 
    ])
  end if

  'TODO(Chris): Change this to 'Remove' if already in queue
  menuItems.appendChild(m.AddQueueMenuItem)

  'TODO(Chris): Remove this if item is not in users history
  menuItems.appendChild(m.RemoveHistoryMenuItem)

  m.Menu.content = menuItems
  m.Menu.visible = "true"
  m.Menu.setFocus(true)
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
      if m.top.content.type = "series" then
        m.top.resumeContent = getEpisodeContent(m.episodeSelection)
      else
        m.top.resumeContent = m.top.content
      end if
    else if selection.id = "PlayMenuItem" then
      if m.top.content.type = "series" then
        content = getEpisodeContent(m.episodeSelection)
      else
        content = m.top.content
      end if
      ' TODO: Reset not just the local resume position but also where it persists
      m.top.playContent = content
    else if selection.id = "EpisodesMenuItem"
      showEpisodes()
    else if selection.id = "AddQueueMenuItem" then
      'TODO(Chris): Add queue management here
    else if selection.id = "RemoveQueueMenuItem" then
      'TODO(Chris): Add queue management here
    else if selection.id = "RemoveHistoyMenuItem" then
      'TODO(Chris): Add history management here
    end if
  end if
End Function


''''''''''''''''''''
' showEpisodes
'
Function showEpisodes()
  m.episodesScreen = m.top.createChild("EpisodesScreen")
  m.episodesScreen.content = m.top.content
  m.episodesScreen.observeField("episodeSelected", "onEpisodeSelected")
  m.episodesScreen.setFocus(true)
End Function


'''''''''''''''''''''
' onEpisodeSelected
'
' Play the episode.  
' TODO(Chris): Or show the details screen for the specific episode?
Function onEpisodeSelected()
  tubiLog("DetailScreen.onEpisodeSelected")
  m.episodeSelection = m.episodesScreen.episodeSelected
  closeEpisodesScreen()
  onContentChange() ' Info panel and menu items all need updating here
End Function


''''''''''''''''''''
' closeEpisodesScreen
'
Function closeEpisodesScreen()
  if m.episodesScreen <> invalid then
    m.episodesScreen.unobserveField("episodeSelected")
    m.top.removeChild(m.episodesScreen)
    m.episodesScreen = invalid
    m.Menu.setFocus(true)
  end if
End Function


'''''''''''''''''''''''''''
' loadContentDetails
'
'
Function loadContentDetails(content)
  tubiLog("DetailScreen.loadDetails")
  settings = m.global.constants.settings
  urlBase = m.global.constants.urls.cms.urlBase
  platform = m.global.constants.platform
  deviceInfo = m.global.constants.deviceInfo

  ' expect that the content here was the bootstrapped content from category list
  contentId = content.id

  if content.type = "series" then
    contentId = "0" + contentId
  end if

  request = {
    url: urlBase + "/content?app_id=" + settings.shortAppName + "&platform=" + platform + "&content_id=" + contentId
    node: m.top
    field: "content"
    options: {}
    name: "getSingleContent"    
  }
  m.global.metadataFetchTask.request = request
End Function


'''''''''''''''''''''''''
' onKeyEvent
'
Function onKeyEvent(key As String, press As Boolean) As Boolean
  if press and key = "back" and m.episodesScreen <> invalid then
    closeEpisodesScreen()
    return true
  end if
  return false 
End Function
