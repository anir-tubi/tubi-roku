' Initializes the Episode List Container component
' Sets up node references, observers, constants, and episode grid configuration
' Initializes local cache for episodes by season
Function init()
  topRef = m.top
  m.typographyConstants = getTypographyConstants()
  m.constants = getConstantsFromGlobal()
  m.tracking = TubiTrackingInfo(m.constants)
  m.header = topRef.findNode("header")
  m.seasonButtonsList = topRef.findNode("seasonButtonsList")
  m.episodeGrid = topRef.findNode("episodeGrid")

  m.header.text = getTranslation("button_episodes")
  setTypographyOfLabel(m.header, m.typographyConstants.ids.subheaderMedium)
  m.seasonButtonsList.translation = [0, 56]

  m.episodeGrid.itemSize = m.constants.ui.imageSizes.largeLandscape
  ' size = m.constants.ui.episodeGrid.itemSize
  ' m.episodeGrid.itemClippingRect = [0, 0, 1920, size[1]]
  m.episodeGrid.itemClippingRect = [0, 0, 1920, 520]


  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()

  topRef.observeFieldScoped("seasonList", "onSeasonListChange")
  topRef.observeFieldScoped("episodes", "onEpisodesChange")
  m.seasonButtonsList.observeFieldScoped("rowItemFocused", "onSeasonButtonFocusedChange")
  m.episodeGrid.observeFieldScoped("itemSelected", "onEpisodeSelectedChange")
  m.episodeGrid.observeFieldScoped("itemFocused", "onEpisodeFocusedChange")
  topRef.observeFieldScoped("isCreatorContent", "onIsCreatorContentChange")
  topRef.observeFieldScoped("showSeasonSelector", "onShowSeasonSelectorChange")
  topRef.observeFieldScoped("showHeader", "onShowHeaderChange")

  ' Local copy of episodes by season. re-using in case user switches back and forth between seasons.
  m.episodesBySeason = {}

  ' Default to episodeGrid (index 2) instead of the first focusable child (seasonButtonsList).
  ' Use focusedIndex rather than jumpToIndex to avoid stealing focus during init.
  m.top.focusedIndex = 2
End Function


' Updates header title based on whether content is creator content
' Creator content shows "Episodes and More", regular content shows "Episodes"
Function onIsCreatorContentChange(msg)
  isCreator = msg.getData()
  if isCreator = true
    m.header.text = getTranslation("screenDetails_button_episodes_container")
  else
    m.header.text = getTranslation("button_episodes")
  end if
End Function


' Handles season selector visibility changes
' Adjusts episode grid position based on whether season selector is shown
' @param msg - Message containing boolean for season selector visibility
Function onShowSeasonSelectorChange(msg)
  showSeasonSelector = msg.getData()
  m.seasonButtonsList.visible = showSeasonSelector
  updateEpisodeGridTranslation(showSeasonSelector)
End Function


' Handles header visibility changes
' When hidden, moves season buttons to [0,0] so their bounds subsume the header's bounds
' @param msg - Message containing boolean for header visibility
Function onShowHeaderChange(msg)
  showHeader = msg.getData()
  m.header.visible = showHeader
  if showHeader = true
    m.seasonButtonsList.translation = [0, 56]
  else
    m.seasonButtonsList.translation = [0, 0]
  end if
  updateEpisodeGridTranslation(m.seasonButtonsList.visible)
End Function


' Updates the episode grid translation based on header and season selector visibility
' @param showSeasonSelector - Boolean, whether the season selector is visible
Function updateEpisodeGridTranslation(showSeasonSelector as Boolean) as Void
  headerOffset = 0
  if m.header.visible = true then headerOffset = 56

  if showSeasonSelector = true
    m.episodeGrid.translation = [0, headerOffset + 141]
  else
    m.episodeGrid.translation = [0, headerOffset - 3]
  end if
End Function


' Handles theme changes and applies colors
' @param msg - Optional message containing theme data
Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.theme = theme
    m.header.color = theme.primaryTextColor
    m.episodeGrid.focusBitmapBlendColor = theme.focusedColor
  end if
End Function


' Handles seasonList changes and creates season buttons
' @param msg - Optional message containing seasonList data
Function onSeasonListChange(msg = invalid) as Void
  topRef = m.top
  seasonList = topRef.seasonList

  ' Check if seasonButtonsList is valid before setting values
  if m.seasonButtonsList = invalid OR seasonList = invalid OR isAA(seasonList.seasons) = false then return

  ' There are some shows which have season number has years 2000, 2001, etc. We need to handle this case.
  ' Rather using bounding rect which is expensive just hardcoding a bigger size for the season buttons.
  seasonKeys = seasonList.seasons.keys()
  if seasonKeys <> invalid then
    recentSeason = seasonKeys[seasonKeys.count() - 1]
    if recentSeason.len() > 2 then
      m.seasonButtonsList.rowItemSize = [[240, 72]]
    end if
  end if

  m.top.focusedSeason = m.top.defaultSelectedSeason
  m.seasonButtonsList.content = seasonList.seasonSelectorContent
  jumpToIndex = findIndexFromSeasonList(m.top.defaultSelectedSeason)

  ' Only set jumpToRowItem if valid index found
  if jumpToIndex >= 0
    m.seasonButtonsList.jumpToRowItem = [0, jumpToIndex]
  end if
End Function


' Finds the index of a season in the season selector list
' Searches through season nodes to find matching season number
' @param seasonNumber - Integer or String, the season number to find
' @return Integer - Index of the season (or -1 if not found)
Function findIndexFromSeasonList(seasonNumber)
  seasonSelectorContent = m.top.seasonList.seasonSelectorContent
  if isNode(seasonSelectorContent)
    seasonNumbers = seasonSelectorContent.getChild(0)
    if seasonNumbers <> invalid
      for i = 0 to seasonNumbers.getChildCount() - 1
        seasonNode = seasonNumbers.getChild(i)
        if seasonNode.seasonNumber = seasonNumber.toStr()
          return i
        end if
      end for
    end if
  end if

  return -1
End Function


' Handles episodes changes and creates episode buttons
' @param msg - Optional message containing episodes data
Function onEpisodesChange(msg = invalid)
  episodes = msg.getData()
  handleEpisodesChange(episodes)
End Function


' Handles episode data changes and updates the episode grid
' Caches episodes by season, configures grid layout, and determines jump position
' Uses viewing history to automatically jump to the last watched episode
' @param episodes - Node containing episode data with titleSeason property
Function handleEpisodesChange(episodes)
  if episodes <> invalid AND episodes.getChildCount() > 0
    m.episodesBySeason[episodes.titleSeason] = episodes
    m.episodeGrid.content = episodes
    m.episodeGrid.numColumns = episodes.getChildCount()
    m.episodeGrid.jumpToItem = m.episodeGrid.itemFocused

    ' Normalize series ID and check for current episode to jump to
    seriesId = m.top.seriesId.toStr()
    if seriesId.startsWith("0") = false
      seriesId = "0" + seriesId
    end if

    history = getHistory(seriesId)
    seasonData = m.top.seasonList

    if history <> invalid AND seasonData <> invalid
      jumpIndex = getJumpToEpisodeIndex(history, seasonData)
      if jumpIndex >= 0
        m.episodeGrid.jumpToItem = jumpIndex
      end if
    end if
  end if
End Function


' Gets the episode index to jump to based on history
' @param history - Object, the history object
' @param seasonData - Object, the season data object
' @return Integer - Episode index to jump to, or -1 if not found
Function getJumpToEpisodeIndex(history, seasonData) as Integer
  if history = invalid OR history.currentEpisodeId = invalid then return -1

  currentEpisodeId = history.currentEpisodeId.toStr()
  currentEpisodeSeasonMap = seasonData.episodeSeasonMap[currentEpisodeId]
  if currentEpisodeSeasonMap = invalid then return -1

  seasonNum = currentEpisodeSeasonMap.seasonNum.toStr()
  episodeList = seasonData.seasons[seasonNum]
  if episodeList = invalid then return -1

  return getEpisodeIndexFromSeasonList(episodeList, currentEpisodeId)
End Function


' Finds the index of an episode in a season's episode list
' @param episodeList - Array of episode objects with id and num properties
' @param episodeId - String or integer ID of the episode to find
' @return Integer index of the episode (0 if not found)
Function getEpisodeIndexFromSeasonList(episodeList, episodeId)
  if episodeList = invalid OR episodeId = invalid then return 0

  ' Convert once before loop for better performance
  episodeIdStr = episodeId.toStr()

  for i = 0 to episodeList.count() - 1
    episode = episodeList[i]
    if episode.id.toStr() = episodeIdStr
      return i ' Return immediately when found
    end if
  end for

  return 0
End Function


' Handles season button selection
' @param msg - Message containing focused item index
Function onSeasonButtonFocusedChange(msg)
  rowItemFocused = msg.getData()
  if m.seasonButtonsList.content <> invalid AND isNonEmptyArray(rowItemFocused)
    focusedIndex = rowItemFocused[1]
    seasonRow = m.seasonButtonsList.content.getChild(0)
    if seasonRow <> invalid
      focusedItem = seasonRow.getChild(focusedIndex)
      if focusedItem <> invalid AND focusedItem.seasonNumber <> invalid
        seasonNum = focusedItem.seasonNumber.toStr()
        ' Resetting the position when user focuses on a different season.
        if m.currentFocusedSeason <> seasonNum
          m.episodeGrid.itemFocused = 0
          m.currentFocusedSeason = seasonNum
        end if
        if m.episodesBySeason[seasonNum] <> invalid
          handleEpisodesChange(m.episodesBySeason[seasonNum])
        else
          m.top.focusedSeason = focusedItem.seasonNumber
        end if
      end if
    end if
  end if
End Function


' Sets the selected episode based on the provided item index
' @param itemIndex - The index of the episode to select
Function setSelectedEpisodeByIndex(itemIndex as Integer) as Void
  if m.episodeGrid.content <> invalid AND itemIndex >= 0
    selectedItem = m.episodeGrid.content.getChild(itemIndex)
    if selectedItem <> invalid
      m.top.selectedEpisode = selectedItem
      m.top.playSelectedEpisode = true
    end if
  end if
End Function


' Handles episode item selection from grid
' @param msg - Message containing selected item index
Function onEpisodeSelectedChange(msg)
  setSelectedEpisodeByIndex(msg.getData())
End Function


' Handles episode item focus changes in the grid
' Sends navigation tracking events when user moves between episodes
' @param msg - Message containing focused item index
Function onEpisodeFocusedChange(msg)
  itemFocused = msg.getData()
  if m.episodeGrid.content <> invalid AND itemFocused >= 0
    focusedItem = m.episodeGrid.content.getChild(itemFocused)
    if focusedItem <> invalid
      horizontalLocation = itemFocused + 1
      verticalLocation = 2
      pageInfo = m.top.trackingPageInfo

      m.top.navigateWithinPageInfo = {
        pageOneof: m.tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
        componentOneof: m.tracking.getAnalyticsComponent("episode_video_list_component", m.previousFocusedContent)
        means_of_navigation: "SCROLL"
        vertical_location: verticalLocation
        horizontal_location: horizontalLocation
      }

      m.previousFocusedContent = {
        content_tile: m.Tracking.getAnalyticsTile(focusedItem, horizontalLocation, verticalLocation)
      }

      m.top.trackingContext = {
        type: "episode_video_list_component"
        values: m.previousFocusedContent
      }
    end if
  end if
End Function


' Handles key events, specifically play button press
' Sets selectedEpisode using the currently focused item
' @param key - The key that was pressed
' @param press - Whether the key was pressed (true) or released (false)
' @return true if key was handled, false otherwise
Function onKeyEvent(key as String, press as Boolean) as Boolean
  if press = true AND key = "play"
    setSelectedEpisodeByIndex(m.episodeGrid.itemFocused)
    return true
  end if
  return parentOnKeyEvent(key, press)
End Function
