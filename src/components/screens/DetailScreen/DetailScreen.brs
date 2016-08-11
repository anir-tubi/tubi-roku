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

Function onContentChange()
  tubiLog("DetailScreen.onContentChange")
  
  'TODO(Chris): If type is "season", resolve which episode to focus on, change the Info.mode to "episode"

  if m.top.content.type = "video"
    m.Info.mode = "movie"
    m.Info.content = m.top.content
  else if m.top.content.type = "series"
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
    infoPanelContent.addField("episode_title", "string", false)
    infoPanelContent.episode_title = episode.title
    infoPanelContent.title = m.top.content.title
    infoPanelContent.description = m.top.content.description
    m.Info.content = infoPanelContent
  end if
  if m.top.content.backgrounds <> invalid and m.top.content.backgrounds.count() > 0 then
    m.Hero.uri = m.top.content.backgrounds[0]
  else if m.top.content.heros <> invalid and m.top.content.heros.count() > 0 then 
    m.Hero.uri = m.top.content.heros[0]
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

Function onShortContentChange()
  if m.top.shortContent <> invalid then loadContentDetails()
End Function

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

Function onMenuItemSelected()
  tubiLog("DetailScreen.onMenuItemSelected")

  selectedItem = m.Menu.content.getChild(m.Menu.itemSelected)
  if selectedItem <> invalid then
    selection = selectedItem.id
    print "Menu item selected: " + selection

    if selection = "resume" then
      m.top.resumeSelected = true
    else if selection = "play" then
      m.top.playSelected = true
    else if selection = "episodes" then
      m.top.episodesSelected = true
    else if selection = "addQueue" then
    else if selection = "removeQueue" then
    else if selection = "removeHistory" then
    end if
  end if
End Function

Function loadContentDetails()
  tubiLog("DetailScreen.loadDetails")
  settings = m.global.constants.settings
  urlBase = m.global.constants.urls.contents.urlBase
  platform = m.global.constants.platform
  deviceInfo = m.global.constants.deviceInfo

  ' expect that the content here was the bootstrapped content from category list
  contentId = m.top.shortContent.id

  if m.top.shortContent.type = "series" then
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
