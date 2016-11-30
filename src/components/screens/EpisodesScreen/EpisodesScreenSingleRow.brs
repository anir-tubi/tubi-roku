Function init()
  tubiLog("EpisodesScreen.init")
  m.Info = m.top.findNode("InfoPanel")
  
  m.top.observeField("content", "onContentChange")
  m.top.observeField("seasonFocused", "onSeasonFocused")
  m.top.observeField("focusedChild", "onScreenFocusChange")

  m.SeasonRows = m.top.findNode("SeasonRows")
  m.SeasonRows.observeField("itemFocused", "onSeasonChangeGrid")
  m.SeasonRows.observeField("preItemFocused", "onPreSeasonRowChange")

  m.Menu = m.top.findNode("EpisodeMenu")
  m.Menu.observeField("itemFocused", "onSeasonChangeMenu")
  m.Menu.observeField("preItemFocused", "onPreMenuChange")
  m.Menu.observeField("itemSelected", "onMenuItemSelected")


  m.defaultHeroUri = "pkg:/images/grid-default-blurred.jpg"
End Function


Function onScreenFocusChange()
  tubiLog("EpisodesScreen.onScreenFocusChange")
  if m.top.hasFocus() then
    ' defaulted to screen, move to a subcomponent
    m.EpisodeGrid.setFocus(true)
  end if
End Function


Function onSeasonChangeGrid()
  m.top.seasonFocused = m.SeasonRows.itemFocused
End Function


Function onSeasonChangeMenu()
  m.top.seasonFocused = m.Menu.itemFocused
End Function


'If season is changed from either the season menu or the seasons/episodes grid it will trigger this function via m.top.seasonFocused
Function onSeasonFocused()
  tubiLog("EpisodesScreen.onSeasonFocused")
  setSeasonInfo(m.top.seasonFocused)

  m.top.categoryFocused = m.SeasonRows.itemFocused
  ' Stop listening to old episode grid
  if m.EpisodeGrid <> invalid then
    m.EpisodeGrid.unobserveField("itemSelected")
    m.EpisodeGrid.unobserveField("itemFocused")
  end if

  m.EpisodeGrid = m.SeasonRows.findNode("Items").getChild(m.top.seasonFocused)

  if m.EpisodeGrid <> invalid then 
    m.EpisodeGrid.observeField("itemSelected", "onEpisodeSelected")
    m.EpisodeGrid.observeField("itemFocused", "onEpisodeFocused")
    if m.Menu.hasFocus() <> true
      m.EpisodeGrid.setFocus(true)
    end if
  end if

End Function


Function onEpisodeSelected()
  tubiLog("EpisodesScreen.onEpisodeSelected")
  m.top.episodeSelected = [ m.Menu.itemFocused, m.EpisodeGrid.cursorIndex ]
End Function

Function onEpisodeFocused()
  tubiLog("EpisodesScreen.onEpisodeSelected")
  if m.EpisodeGrid.isInFocusChain() then 
    
    m.Info.mode = "episode"
    infoPanelContent = CreateObject("roSGNode", "TubiContentNode")   
    episode = m.EpisodeGrid.itemFocused
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


' When season rows grid updates season, we need to sync the menu
Function onPreSeasonRowChange()
  if m.Menu.preItemFocused <> m.SeasonRows.preItemFocused
    tubiLog("onPreSeaonsRowChange")
    m.Menu.animateToItem = m.SeasonRows.preItemFocused
  end if
End Function


'When menu updates season, we need to sync the season rows grid
Function onPreMenuChange() As Void
  if m.SeasonRows.preItemFocused <> m.Menu.preItemFocused
    tubiLog("onPreMenuChange")
    m.SeasonRows.animateToItem = m.Menu.preItemFocused
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

  m.SeasonRows.content = m.top.content
  m.Menu.content = m.top.content
  
  m.EpisodeGrid = m.SeasonRows.findNode("Items").getChild(0)
  m.EpisodeGrid.observeField("itemSelected", "onEpisodeSelected")
  m.EpisodeGrid.observeField("itemFocused", "onEpisodeFocused")

  setSeasonInfo(0)
  if m.top.content.backgrounds <> invalid and m.top.content.backgrounds.count() > 0 then 
    m.top.backgroundUriList = m.top.content.backgrounds
  else
    m.top.backgroundUriList = [m.defaultHeroUri]
  end if


  ' Set visibility and focus
  m.SeasonRows.visible = true
  m.Menu.visible = true
  if m.top.isInFocusChain() then m.SeasonRows.setFocus(true)
End Function


''''''''''''''''''''
' onKeyEvent
'
Function onKeyEvent(key As String, press As Boolean) As Boolean
  tubiLog("EpisodesScreen.onKeyEvent" + key)
  if press then
    if key = "right" and m.Menu.isInFocusChain() then
      focusGrid()
      return true
    else if (key = "left" or key = "back") and m.SeasonRows.isInFocusChain() then
      focusMenu()
      return true
    end if
  end if

  return false
End Function


''''''''''''''''''''
' onMenuItemSelected
'
Function onMenuItemSelected()
  focusGrid()
End Function


''''''''''''''''''''
' focusGrid
'
Function focusGrid()
  m.EpisodeGrid.setFocus(true)
  slideTo(m.SeasonRows, [85,m.SeasonRows.translation[1]], 0.5)
  slideTo(m.Menu, [-375,m.Menu.translation[1]], 0.5)
End Function


''''''''''''''''''''
' focusMenu
'
Function focusMenu()
  m.Menu.setFocus(true)
  slideTo(m.SeasonRows, [525,m.SeasonRows.translation[1]], 0.5)
  slideTo(m.Menu, [65,m.Menu.translation[1]], 0.5)
End Function

