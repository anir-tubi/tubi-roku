Function init()
  tubiLog("EpisodesScreen.init")
  m.Info = m.top.findNode("InfoPanel")
  
  m.top.observeField("content", "onContentChange")
  m.top.observeField("seasonFocused", "onSeasonFocused")
  m.top.observeField("episodeToFocus", "onEpisodeToFocus")
  m.top.observeField("focusedChild", "onScreenFocusChange")

  m.SeasonRows = m.top.findNode("SeasonRows")
  m.SeasonRows.observeField("itemFocused", "onSeasonChangeGrid")
  m.SeasonRows.observeField("preItemFocused", "onPreSeasonRowChange")

  m.Menu = m.top.findNode("EpisodeMenu")
  m.Menu.observeField("itemFocused", "onSeasonChangeMenu")
  m.Menu.observeField("preItemFocused", "onPreMenuChange")
  m.Menu.observeField("itemSelected", "onMenuItemSelected")


  m.defaultHeroUri = "pkg:/images/art-blur-background.png"
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

  m.EpisodeGrid = m.SeasonRows.findNode("Items").getChild(m.top.seasonFocused)  'should be a SeasonContentGrid.xml component

  if m.EpisodeGrid <> invalid then 
    m.EpisodeGrid.observeField("itemSelected", "onEpisodeSelected")
    m.EpisodeGrid.observeField("itemFocused", "onEpisodeFocused")
    if m.Menu.hasFocus() <> true
      m.EpisodeGrid.setFocus(true)
    end if
  end if

End Function



Function onEpisodeToFocus()
  tubiLog("EpisodesScreen.onEpisodeToFocus")

  'gives focus and observes the appropriate EpisodeGrid
  m.top.seasonFocused = m.top.episodeToFocus[0]

  'animate the season rows and season menu to the appropriate position
  m.Menu.animateToItem = m.top.episodeToFocus[0]
  m.SeasonRows.animateToItem = m.top.episodeToFocus[0]
  
  'm.EpisodeGrid hasn't necessarily been updated by onSeasonFocused() running (as a result of setting m.top.seasonFocused)
  'so we need to find the appropriate episode grid (SeasonContentGrid) component to set itemToFocus on
  episodeGridToFocus = m.SeasonRows.findNode("Items").getChild(m.top.episodeToFocus[0])

  if episodeGridToFocus <> invalid
    episodeGridToFocus.itemToFocus = [m.top.episodeToFocus[1], 0]
  end if
  
  'set the appropriate episode info in the info panel
  onEpisodeFocused()
End Function



Function onEpisodeSelected()
  tubiLog("EpisodesScreen.onEpisodeSelected")
  m.top.episodeSelected = [ m.Menu.itemFocused, m.EpisodeGrid.cursorIndex ]
End Function

Function onEpisodeFocused()
  tubiLog("EpisodesScreen.onEpisodeSelected")
  if m.EpisodeGrid.isInFocusChain() then 
    
    m.Info.mode = "episode"
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
    infoPanelContent = clone(episode)
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
  infoContent = clone(seasonContent)
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

  'set info panel
  setSeasonInfo(0)

  'set backgrounds
  if m.top.content.backgrounds <> invalid and m.top.content.backgrounds.count() > 0 then 
    m.top.backgroundUriList = m.top.content.backgrounds
  else
    m.top.backgroundUriList = [m.defaultHeroUri]
  end if


  ' Set visibility and component focus
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
    else if (key = "left") and m.SeasonRows.isInFocusChain() then
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
  if m.global.constants.deviceInfo.limitedNewUi
    m.SeasonRows.translation = [85,m.SeasonRows.translation[1]]
    m.Menu.translation = [-375,m.Menu.translation[1]]
  else
    slideTo(m.SeasonRows, [85,m.SeasonRows.translation[1]], 0.5)
    slideTo(m.Menu, [-375,m.Menu.translation[1]], 0.5)
  end if
End Function


''''''''''''''''''''
' focusMenu
'
Function focusMenu()
  m.Menu.setFocus(true)
  if m.global.constants.deviceInfo.limitedNewUi
    m.SeasonRows.translation = [525,m.SeasonRows.translation[1]]
    m.Menu.translation = [65,m.Menu.translation[1]]
  else
    slideTo(m.SeasonRows, [525,m.SeasonRows.translation[1]], 0.5)
    slideTo(m.Menu, [65,m.Menu.translation[1]], 0.5)
  end if
End Function

