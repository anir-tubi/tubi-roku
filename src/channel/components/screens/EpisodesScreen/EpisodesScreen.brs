Function init()
  tubiLog("EpisodesScreen.init")
  m.constants = m.global.constants
  Request = TubiRequest(m.constants.settings)
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)
  m.Info = m.top.findNode("InfoPanel")
  m.RowList = m.top.findNode("RowList")

  if getExperimentResource("roku_safe_zone", "roku_safe_zone_restart_v2", false).enabled = true
    m.Info.translation = [192,133]
    m.RowList.translation = [192,570]
    m.top.findNode("leftChevron").translation = [90,528]
    m.RowList.rowItemSize = [m.constants.ui.safezoneImageSizes.landscape]
    m.RowList.itemSize = [1835,318]
  end if
  m.top.observeField("updateContent", "onContentChange")
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("transportVoiceRequest", "onTransportVoiceRequest")

  m.RowList.observeField("rowItemSelected", "onEpisodeSelected")
  m.RowList.observeField("rowItemFocused", "onEpisodeFocused")
  m.Menu = m.top.findNode("EpisodeMenu")
  m.Menu.observeField("itemFocused", "onSeasonChangeMenu")
  m.Menu.observeField("rowScrollFocused", "onMenuScrollFocused")
  m.defaultHeroUri = "pkg:/images/art-blur-background.png"

  if m.global.constants.deviceInfo.scaledUi = true then
    m.RowList.focusBitmapUri = "pkg:/images/selector-hd.9.png"
  end if
  m.RowList.focusBitmapBlendColor = m.global.theme.focused

  'set initial tracking values
  m.top.trackingPageInfo = {
    pageType: "episode_video_list_page"
    pageValues: {
      series_id: 0
    }
  }

  m.top.handlesTransportVoiceRequests = true

  ' When the screen comes in to focus, onEpisodeFocused() triggers. At this point in time, m.RowList.hasFocus() is true.
  ' m.gridIsFocused can be used to differentiate between onEpisodeFocused() occurring due to the focus changing between
  ' items on the RowList, or due to the RowList gaining focus when focus is given to the EpisodesScreen.
  m.gridIsFocused = false
  m.listIsFocused = false

  m.top.screenLevel = m.constants.ui.screenLevels.episodeScreen
End Function


Function onScreenFocusChange()
  tubiLog("EpisodesScreen.onScreenFocusChange")
  if m.top.hasFocus() then
    'an extra set focus is necessary due to a bug in the roku Rowlist component that offsets the cursor in error
    m.RowList.setFocus(true)
    m.gridIsFocused = false
    m.RowList.setFocus(false)
    m.gridIsFocused = false
    m.RowList.setFocus(true)
  else if m.top.isInFocusChain() = false
    m.gridIsFocused = false 
    m.listIsFocused = false
  end if
End Function


Function onSeasonChangeMenu()
  tubiLog("EpisodesScreen.onSeasonChangeMenu")
  if m.Menu.isInFocusChain() and m.Menu.itemFocused <> invalid then
    setSeasonInfo(m.Menu.itemFocused)

    if m.listIsFocused = true
      seriesDetailPage = getEpisodeVideoListPage(m.top.content)

      m.top.navigateWithinPageInfo = {
        pageOneof: m.Tracking.getAnalyticsPage(seriesDetailPage.type, seriesDetailPage.values)
        componentOneof: m.Tracking.getAnalyticsComponent("seasons_component", {}) 'seasons_component doesn't exist in protos
        means_of_navigation: "BUTTON"  'MeansOfNavigation enum
        vertical_location: m.Menu.itemFocused + 1  '1 based index
        vertical_location_mode: "INDEX"  'LocationMode enum
        horizontal_location: 1
        horizontal_location_mode: "INDEX"  'LocationMode enum
      }
    end if
  end if
  m.gridIsFocused = false
  m.listIsFocused = true
End Function


Function onEpisodeFocused()
  tubiLog("EpisodesScreen.onEpisodeFocused")
  if m.RowList.isInFocusChain() then
    episode = getEpisodeContent(m.RowList.rowItemFocused)
    if episode <> invalid then
    
      content = m.top.content
    
      m.Info.mode = m.constants.ui.infoPanelModes.episode
      m.Info.title = content.title
      m.Info.episodeTitle = episode.title
      m.Info.description = episode.description
      
      lineOneData = {}
      lineOneData.releaseDate = content.releaseDate
      lineOneData.length = episode.length
      
      if episode <> invalid and (episode.hasSubtitles = true or episode.subtitleTracks.Count() > 0)
        lineOneData.hasCC = true
      else if content <> invalid and content.type = m.constants.ui.contentTypes.video and (content.hasSubtitles = true or content.subtitleTracks.Count() > 0)
        lineOneData.hasCC = true
      else
        lineOneData.hasCC = false
      end if
      
      lineOneData.descriptorCode = episode.descriptorCode

      if content.availabilityEnds <> invalid and content.availabilityEnds <> ""
        lineOneData.availabilityEnds = content.availabilityEnds
      else if episode <> invalid and episode.availabilityEnds <> invalid
        lineOneData.availabilityEnds = episode.availabilityEnds
      end if
    
      lineOneData.rating = episode.rating
      lineOneData.partnerLogoUri = episode.inlineLogoUri

      m.Info.lineOneData = lineOneData
      m.Info.titleLogoUri = episode.titleLogoUri
      m.Info.genres = episode.genres
      m.Info.width = 1140   
      m.Info.calculateHeight = true   
      
    end if
    season = m.top.content.getChild(m.RowList.rowItemFocused[0])
    if season <> invalid then
      season.focusIndex = m.RowList.rowItemFocused[1]
    end if

    ' trigger navigate_within_page events in ContentController
    rowItem = m.RowList.rowItemFocused
    if m.gridIsFocused = true and (rowItem[0] <> m.oldRowItemFocused[0] or rowItem[1] <> m.oldRowItemFocused[1])
      row = m.RowList.rowItemFocused[0] + 1
      col = m.RowList.rowItemFocused[1] + 1

      episodeListComponent = {}
      if m.oldRowItemFocused <> invalid
        oldRow = m.oldRowItemFocused[0] + 1
        oldCol = m.oldRowItemFocused[1] + 1
        oldEpisode = getEpisodeContent(m.oldRowItemFocused)
        episodeListComponent = {
          content_tile: m.Tracking.getAnalyticsTile(oldEpisode, oldCol, oldRow)
        }
      end if

      seriesDetailPage = getEpisodeVideoListPage(m.top.content)

      m.top.navigateWithinPageInfo = {
        pageOneof: m.Tracking.getAnalyticsPage(seriesDetailPage.type, seriesDetailPage.values)
        componentOneof: m.Tracking.getAnalyticsComponent("episode_video_list_component", episodeListComponent)
        means_of_navigation: "BUTTON"  'MeansOfNavigation enum
        vertical_location: row  '1 based index
        vertical_location_mode: "INDEX"  'LocationMode enum
        horizontal_location: col
        horizontal_location_mode: "INDEX"  'LocationMode enum
      }
    end if

    m.oldRowItemFocused = rowItem
    m.Menu.jumpToItem = m.RowList.rowItemFocused[0]
    m.gridIsFocused = true
    m.listIsFocused = false
  end if
End Function


Function onEpisodeSelected()
  handleEpisodeSelected(m.RowList.rowItemSelected)
End Function


' @itemSelected: Array, 2D array with [row, column] (as outpt from Rowlist.rowitemFocused or .rowItemSelected)
Function handleEpisodeSelected(itemSelected)
  'set the component info so it can be used in navigate_to_page event
  episode = getEpisodeContent(itemSelected)
  row = m.RowList.rowItemFocused[0] + 1
  col = m.RowList.rowItemFocused[1] + 1
  m.top.trackingComponentInfo = {
    componentType: "episode_video_list_component"
    componentValues: {
      content_tile: m.Tracking.getAnalyticsTile(episode, col, row)
    }
  }

  m.top.episodeSelected = itemSelected
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
  m.Info.mode = m.constants.ui.infoPanelModes.season
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
    if key = "play" and m.RowList.isInFocusChain() = true
      handleEpisodeSelected(m.Rowlist.rowItemFocused)
    else if key = "right" and m.Menu.isInFocusChain() then
      focusGrid()
      return true
    else if (key = "left") and m.RowList.isInFocusChain() then
      focusMenu()
      return true
    else if key = "left" then
      m.top.backButtonPressed = true
      return true
    end if
  end if

  return false
End Function


Function onTransportVoiceRequest(msg)
  inputInfo = msg.getData()
  command = ""
  if inputInfo <> invalid and inputInfo.command <> invalid
    command = inputInfo.command
  end if
  tubiLog("DetailScreen.onTransportVoiceRequest " + command)

  response = "unhandled"
  if m.RowList.isInFocusChain()
    if command = "play" or command = "ok"
      handleEpisodeSelected(m.Rowlist.rowItemFocused)
      response = "success"
    end if
  end if

  inputInfo.response = response
  m.top.transportVoiceResponse = inputInfo
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
  if m.Rowlist.isInFocusChain() <> true
    m.RowList.setFocus(true)
  end if
  if getExperimentResource("roku_safe_zone", "roku_safe_zone_restart_v2", false).enabled = true
    if m.global.constants.deviceInfo.limitedUi
      m.RowList.translation = [192, m.RowList.translation[1]]
      m.Menu.translation = [-450, m.Menu.translation[1]]
    else
      slideTo(m.RowList, [192, m.RowList.translation[1]], 0.5)
      slideTo(m.Menu, [-450, m.Menu.translation[1]], 0.5)
    end if
  else
    if m.global.constants.deviceInfo.limitedUi
      m.RowList.translation = [168, m.RowList.translation[1]]
      m.Menu.translation = [-425, m.Menu.translation[1]]
    else
      slideTo(m.RowList, [168, m.RowList.translation[1]], 0.5)
      slideTo(m.Menu, [-425, m.Menu.translation[1]], 0.5)
    end if
  end if
End Function


''''''''''''''''''''
' focusMenu
'
Function focusMenu()
  m.Menu.animateToItem = m.RowList.currFocusRow
  m.Menu.setFocus(true)
  if getExperimentResource("roku_safe_zone", "roku_safe_zone_restart_v2", false).enabled = true
    if m.global.constants.deviceInfo.limitedUi
      m.Menu.translation = [192, m.Menu.translation[1]]
      m.RowList.translation = [634, m.RowList.translation[1]]
    else
      slideTo(m.Menu, [192, m.Menu.translation[1]], 0.5)
      slideTo(m.RowList, [634, m.RowList.translation[1]], 0.5)
    end if
  else
    if m.global.constants.deviceInfo.limitedUi
      m.Menu.translation = [148, m.Menu.translation[1]]
      m.RowList.translation = [590, m.RowList.translation[1]]
    else
      slideTo(m.Menu, [148, m.Menu.translation[1]], 0.5)
      slideTo(m.RowList, [590, m.RowList.translation[1]], 0.5)
    end if
  end if
End Function


''''''''''''''''''''
' getEpisodeVideoListPage
'
' @episode: roSGNode, series content node (m.top.content)
Function getEpisodeVideoListPage(series)
  values = {
    series_id: 0
  }

  if series.id <> invalid and series.id <> ""
    seriesId = series.id
    if Left(series.id, 1) = "0"
      seriesId = Mid(series.id, 2).toInt()
    end if
    values.series_id = seriesId
  end if

  return {
    type: "episode_video_list_page"
    values: values
  }
End Function