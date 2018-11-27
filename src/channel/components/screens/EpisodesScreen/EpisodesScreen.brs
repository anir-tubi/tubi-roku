Function init()
  tubiLog("EpisodesScreen.init")
  m.Info = m.top.findNode("InfoPanel")
  m.top.observeField("content", "onContentChange")
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.RowList = m.top.findNode("RowList")
  m.RowList.observeField("rowItemSelected", "onEpisodeSelected")
  m.RowList.observeField("rowItemFocused", "onEpisodeFocused")
  m.Menu = m.top.findNode("EpisodeMenu")
  m.Menu.observeField("itemFocused", "onSeasonChangeMenu")
  m.Menu.observeField("rowScrollFocused", "onMenuScrollFocused")
  m.defaultHeroUri = "pkg:/images/art-blur-background.png"

  if m.global.constants.deviceInfo.scaledUi = true then
    m.RowList.focusBitmapUri = "pkg:/images/selector-hd.9.png"
  end if
End Function


Function onScreenFocusChange()
  tubiLog("EpisodesScreen.onScreenFocusChange")
  if m.top.hasFocus() then
    m.RowList.setFocus(true)

    'an extra set focus is necessary due to a bug in the roku Rowlist component that offsets the cursor in error
    m.RowList.setFocus(false)
    m.RowList.setFocus(true)
  end if
End Function

Function onSeasonChangeMenu()
  tubiLog("EpisodesScreen.onSeasonChangeMenu")
  if m.Menu.isInFocusChain() then
    setSeasonInfo(m.Menu.itemFocused)
  end if
End Function

Function onEpisodeFocused()
  tubiLog("EpisodesScreen.onEpisodeFocused")
  if m.RowList.isInFocusChain() then
    episode = getEpisodeContent(m.RowList.rowItemFocused)
    if episode <> invalid then
      m.Info.mode = "episode"
      m.Info.title = m.top.content.title
      m.Info.episodeTitle = episode.title
      m.Info.description = episode.description
      m.Info.calculateHeight = true
    end if
    season = m.top.content.getChild(m.RowList.rowItemFocused[0])
    if season <> invalid then
      season.focusIndex = m.RowList.rowItemFocused[1]
    end if
    m.Menu.jumpToItem = m.RowList.rowItemFocused[0]
  end if
End Function

''''''''''''''''''''''
' getEpisodeContent
'
Function getEpisodeContent(selection As Object) As Object
  if m.top.content <> invalid then
    season = m.top.content.getChild(selection[0])
    if season <> invalid then
      episode = season.getChild(selection[1])
      if episode <> invalid then return episode
    end if
  end if
  return invalid
End Function


'When menu updates season, we need to sync the season rows grid
Function onMenuScrollFocused() As Void
  if m.RowList.preItemFocused <> m.Menu.rowScrollFocused
    tubiLog("EpisodeScreen.onMenuScrollFocused")
    m.RowList.animateToItem = m.Menu.rowScrollFocused
  end if
End Function


Function setSeasonInfo(season As Integer)
  ' Display the series description when the season is being selected
  seasonContent = m.top.content.getChild(season)   ' season
  m.Info.title = seasonContent.title
  m.Info.seasonEpisodeCount = seasonContent.getChildCount()
  m.Info.description = m.top.content.description ' series description
  m.Info.mode = "season"
  m.Info.calculateHeight = true
End Function


Function onContentChange()
  tubiLog("EpisodesScreen.onContentChange")

  m.RowList.content = m.top.content
  m.Menu.content = m.top.content

  'set backgrounds
  if m.top.content.backgrounds <> invalid and m.top.content.backgrounds.count() > 0 then 
    m.top.backgroundUriList = m.top.content.backgrounds
  else
    m.top.backgroundUriList = [m.defaultHeroUri]
  end if

  if m.top.isInFocusChain() then
    focusGrid()
  end if
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
    else if (key = "left") and m.RowList.isInFocusChain() then
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
  m.RowList.setFocus(true)
  if m.global.constants.deviceInfo.limitedUi
    m.RowList.translation = [85,m.RowList.translation[1]]
    m.Menu.translation = [-425,m.Menu.translation[1]]
  else
    slideTo(m.RowList, [85,m.RowList.translation[1]], 0.5)
    slideTo(m.Menu, [-425,m.Menu.translation[1]], 0.5)
  end if
End Function


''''''''''''''''''''
' focusMenu
'
Function focusMenu()
  m.Menu.animateToItem = m.RowList.currFocusRow
  m.Menu.setFocus(true)
  if m.global.constants.deviceInfo.limitedUi
    m.RowList.translation = [525,m.RowList.translation[1]]
    m.Menu.translation = [65,m.Menu.translation[1]]
  else
    slideTo(m.RowList, [525,m.RowList.translation[1]], 0.5)
    slideTo(m.Menu, [65,m.Menu.translation[1]], 0.5)
  end if
End Function

