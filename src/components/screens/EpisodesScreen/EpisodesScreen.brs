Function init()
  tubiLog("EpisodesScreen.init")
  m.Info = m.top.findNode("InfoPanel")
  m.Menu = m.top.findNode("Menu")
  m.Hero = m.top.findNode("HeroBackground")
  m.EpisodeGrid = m.top.findNode("EpisodeGrid")
  m.Menu.observeField("itemFocused", "onSeasonChange")
  m.top.observeField("content", "onContentChange")
  m.EpisodeGrid.observeField("itemSelected", "onEpisodeSelected")
  m.EpisodeGrid.observeField("itemFocused", "onEpisodeFocused")
  m.defaultHeroUri = "pkg:/images/grid-default-blurred.jpg"
End Function

Function onSeasonChange()
  tubiLog("EpisodesScreen.onSeasonChange")
  setSeasonInfo(m.Menu.itemFocused)
  m.EpisodeGrid.content = m.top.content.getChild(m.Menu.itemFocused) ' season children will be shown in grid
End Function

Function onEpisodeSelected()
  tubiLog("EpisodesScreen.onEpisodeSelected")
  m.top.episodeSelected = [ m.Menu.itemFocused, m.EpisodeGrid.itemSelected ]
End Function

Function onEpisodeFocused()
  tubiLog("EpisodesScreen.onEpisodeSelected")
  if m.EpisodeGrid.isInFocusChain() then 
    
    m.Info.mode = "episode"
    infoPanelContent = CreateObject("roSGNode", "TubiContentNode")   
    episode = m.EpisodeGrid.content.getChild(m.EpisodeGrid.itemFocused)
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
    m.Info.content = infoPanelContent
  end if
End Function

Function setSeasonInfo(season As Integer)
  ' Display the series description when the season is being selected
  seasonContent = m.top.content.getChild(season)   ' season
  infoContent = CreateObject("roSGNode", "TubiContentNode")
  infoContent.setFields(seasonContent.getFields())
  infoContent.description = m.top.content.description ' series description
  infoContent.totalCount = seasonContent.getChildCount()
  m.Info.mode = "season"
  m.Info.content = infoContent
End Function

Function onContentChange()
  tubiLog("EpisodesScreen.onContentChange")

  ' The Scrolling list will be the seasons, the grid will be the episodes
  m.Menu.content = m.top.content
  setSeasonInfo(0)
  m.EpisodeGrid.content = m.top.content.getChild(0) ' season children will be shown in grid
  if m.top.content.backgrounds <> invalid and m.top.content.backgrounds.count() > 0 then 
    m.Hero.uri = m.top.content.backgrounds[0]
  else
    m.Hero.uri = m.defaultHeroUri
  end if

  ' Set visibility and focus
  m.EpisodeGrid.visible = true
  m.Menu.visible = true
  if m.top.isInFocusChain() then m.Menu.setFocus(true)
End Function

''''''''''''''''''''
' onKeyEvent
'
Function onKeyEvent(key As String, press As Boolean) As Boolean
  tubiLog("EpisodesScreen.onKeyEvent")
  if press then
    if key = "right" and m.Menu.isInFocusChain() then
      m.EpisodeGrid.setFocus(true)
      return true
    else if key = "left" and m.EpisodeGrid.isInFocusChain() then
      m.Menu.setFocus(true)
      return true
    else if (key = "down" or key = "up") and m.EpisodeGrid.isInFocusChain() then
      m.Menu.setFocus(true)
      if key = "up" then m.Menu.animateToItem = m.Menu.itemFocused - 1
      if key = "down" then m.Menu.animateToItem = m.Menu.itemFocused + 1
      return true
    end if
  end if

  return false
End Function

