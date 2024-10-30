Function init()
  tubiLog("DetailScreenEpisodeOverlay.init")
  m.constants = getConstantsFromGlobal()
  m.Tracking = TubiTrackingInfo(m.constants)
  m.title = m.top.findNode("Title")
  m.NodeHelpers = TubiNodeHelpers()

  m.ymalEpisodesRowLabel = m.top.findNode("ymalEpisodesRowLabel")
  ymalEpisodesRowLabelContent = m.top.findNode("ymalEpisodesRowLabelContent")
  ymalEpisodesRowLabelContent.title = getTranslation("screenDetails_button_episodes_more")

  m.episodeList = m.top.findNode("EpisodeList")
  m.episodeList.rowItemSize = [m.constants.ui.imageSizes.largeLandscape]
  m.episodeList.itemSize = [1836, m.constants.ui.imageSizes.largeLandscape[1] + 196]
  m.episodeList.observeFieldScoped("rowItemSelected", "onEpisodeSelected")
  m.episodeList.observeFieldScoped("rowItemFocused", "onEpisodeFocused")

  m.seasonMenu = m.top.findNode("SeasonMenu")
  m.seasonMenu.observeFieldScoped("itemSelected", "onSeasonItemSelected")

  m.top.observeFieldScoped("updateContent", "onContentChange")
  m.top.observeFieldScoped("focusedChild", "onScreenFocusChange")
  m.top.observeFieldScoped("transportVoiceRequest", "onTransportVoiceRequest")

  m.defaultMenuWidth = m.seasonMenu.itemSize[0]

  ' there might be a case where the season menu is has more seasons that can fit on the screen, so we need to set the clipping rect while keeping numColumns = 8 but 9th item visible.
  m.seasonMenu.itemClippingRect = {
    height: 60.0
    width: 1732.0
    x: 0.0
    y: 0.0
  }

  theme = getThemeFromGlobal()

  if theme <> invalid
    m.episodeList.focusBitmapBlendColor = theme.focusedColor
    m.seasonMenu.focusFootprintBlendColor = theme.neutralColor2
    m.seasonMenu.focusBitmapBlendColor = theme.focusedColor
  end if

  'set initial tracking values
  m.top.trackingPageInfo = {
    pageType: "episode_video_list_page"
    pageValues: {
      series_id: 0
    }
  }

  m.top.handlesTransportVoiceRequests = true

  ' When the DetailScreenEpisodeOverlay gains focus, focus is then placed on m.episodeList, which then triggers onEpisodeFocused(). At this point in time, m.episodeList.hasFocus() is true.
  ' m.episodeListFocused can be used to differentiate between onEpisodeFocused() occurring due to the focus changing between
  ' items on the episodeList, or due to the episodeList gaining focus when focus is given to the EpisodesOverlay.
  m.episodeListFocused = false
  m.seasonListFocused = false

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.title, typographyConstants.ids.headerSmall)
End Function


Function onScreenFocusChange()
  tubiLog("DetailScreenEpisodeOverlay.onScreenFocusChange")
  if m.top.hasFocus() = true
    m.title.opacity = 1 '//Animate ?
    m.seasonMenu.opacity = 1 '//Animate ?
    m.ymalEpisodesRowLabel.opacity = 0 '//Animate?
    m.episodeList.setFocus(true)
  else if m.top.isInFocusChain() = false
    m.title.opacity = 0
    m.seasonMenu.opacity = 0
    m.ymalEpisodesRowLabel.opacity = 1
    m.episodeListFocused = false
    m.seasonListFocused = false
  end if
End Function


' @selection: Array, 2D array with [row, column], episode selected
Function getEpisodeContent(selection As Object) As Object
  episodeContent = m.episodeList.content
  if episodeContent <> invalid AND episodeContent.getChild(0) <> invalid AND isArray(selection) =  true
    return episodeContent.getChild(0).getChild(selection[1])
  end if

  return invalid
End Function


Function onContentChange()
  tubiLog("DetailScreenEpisodeOverlay.onContentChange")
  content = m.top.content

  if content <> invalid
    m.title.text = content.title
    m.parentId = content.id
    updatedEpisodeList(content)
    updateSeasonMenu(content)

    if m.top.relatedContent <> invalid
      onRelatedUpdated()
    else
      m.top.observeFieldScoped("relatedContent", "onRelatedUpdated")
    end if
  end if
End Function


Function onEpisodeSelected(msg)
  itemSelected = msg.getData()
  handleEpisodeSelected(itemSelected)
End Function


' @itemSelected: Array, 2D array with [row, column] (as output from episodeList.rowitemSelected)
Function handleEpisodeSelected(itemSelected)
  episode = getEpisodeContent(itemSelected)

  if episode <> invalid
    if episode.parentId = m.parentId
      m.top.episodeToPlay = episode
      m.top.episodeSelected = itemSelected
    else
      m.top.relatedContentToPlay = episode
      m.top.relatedContentToPlayUpdated = true
    end if
  end if
End Function


Function onKeyEvent(key As String, press As Boolean) As Boolean
  if press then
    if key = "play"
      if m.episodeList.isInFocusChain() = true
        handleEpisodeSelected(m.episodeList.rowItemFocused)
        return true
      else if m.seasonMenu.isInFocusChain() = true
        return true
      end if

    else if key = "up" AND m.episodeList.isInFocusChain() = true
      focusMenu()
      return true
    else if key = "down" AND m.seasonMenu.isInFocusChain() = true
      focusGrid()
      return true
    end if
  end if

  return false
End Function


Function onSeasonItemSelected(msg)
  itemSelected = msg.getData()

  if itemSelected <> invalid AND itemSelected >= 0 AND m.seasonMenu.content <> invalid AND m.episodeList.content <> invalid
    ' if a seson item is selected, then jump to the first episode of that season
    if itemSelected = 0
      m.episodeList.jumpToRowItem = [0, 0]
    else
      numEpisodes = 0
      for i = 0 to itemSelected - 1
        row = m.seasonMenu.content.GetChild(i)
        numEpisodes = numEpisodes + row.NumEpisodes
      end for

      m.episodeList.jumpToRowItem = [0, numEpisodes]

    end if
  end if
  ' TODO : If in future, we need to track the season change, then we can add the tracking code here.
End Function


Function focusGrid()
  if m.episodeList.isInFocusChain() <> true
    m.episodeList.setFocus(true)
  end if
End Function


Function focusMenu()
  m.seasonMenu.setFocus(true)
End Function


Function getEpisodeVideoListTrackingPage(series)
  values = {
    series_id: 0
  }

  if isNonEmptyString(series.id) = true
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


Function onRelatedUpdated()
  relatedContent = m.top.relatedContent

  if relatedContent <> invalid AND relatedContent.getChildCount() > 0
    m.top.unObserveFieldScoped("relatedContent")

    ' update the season menu
    menuContent = m.seasonMenu.content
    if menuContent <> invalid

      seasonItem = createObject("roSGNode", "ContentNode")
      seasonItem.title = getTranslation("screenDetails_relatedTitles")
      seasonItem.NumEpisodes = relatedContent.getChildCount()

      colWidths = []
      colWidths.append(m.seasonMenu.columnWidths)

      width = getWidthOfText(seasonItem)
      colWidths.push(width)

      menuContent.appendChild(seasonItem)

      m.seasonMenu.content = invalid
      m.seasonMenu.update({"columnWidths": colWidths, "content": menuContent})
    end if

    'update the episode list with ymal movie list
    episodeList = m.episodeList.content

    if episodeList <> invalid

      for j = 0 to relatedContent.getChildCount() - 1
        item = relatedContent.getChild(j).clone(true)
        episodeList.getChild(0).appendChild(item)
      end for

      m.episodeList.content = episodeList
    end if
  end if
End Function


Function getWidthOfText(seasonItem)
  tempMenuItem = CreateObject("roSGNode", "DetailHorizSeasonItem")
  tempMenuItem.itemContent = seasonItem
  potentialWidth = tempMenuItem.calculatedTextWidth

  if potentialWidth > m.defaultMenuWidth
    width = potentialWidth
  else
    width = m.defaultMenuWidth
  end if

  return width
End Function


Function updateSeasonMenu(content)
  colWidths = []
  if content <> invalid
    seasonContentNode = createObject("roSGNode", "ContentNode")

    for i = 0 to content.getChildCount() - 1
      item = content.getChild(i)
      seasonItem = createObject("roSGNode", "ContentNode")
      seasonItem.title = item.title
      seasonItem.NumEpisodes = item.getChildCount()
      seasonContentNode.appendChild(seasonItem)
      width = getWidthOfText(seasonItem)
      colWidths.push(width)
    end for

    m.seasonMenu.update({"columnWidths": colWidths, content: seasonContentNode})
  end if
End Function


Function updatedEpisodeList(content)
  if content <> invalid
    rowContentNode = createObject("roSGNode", "ContentNode")
    seasonContentNode = createObject("roSGNode", "ContentNode")

    rowContentNode.appendChild(seasonContentNode)

    for i = 0 to content.getChildCount() - 1
      row = content.getChild(i)
      if row <> invalid
        seasonContentNode.title = row.title

        for j = 0 to row.getChildCount() - 1
          orgItem = row.getChild(j)
          if orgItem <> invalid
            item = orgItem.clone(true)
            seasonContentNode.appendChild(item)
          end if
        end for
      end if
    end for

    m.episodeList.content = rowContentNode
    jumpToCurrentEpisode(content.currentEpisodeId, rowContentNode)
  end if
End Function


Function onEpisodeFocused(msg)
  itemFocused = msg.getData()

  if isArray(itemFocused) = true
    episodeNum = itemFocused[1]

    'season episode index
    k = 0
    focusedContent = invalid
    episodeContent = m.episodeList.content
    if episodeContent <> invalid AND episodeContent.getChild(0) <> invalid AND episodeContent.getChild(0).getChildCount() > 0 AND episodeNum <> invalid
      focusedContent = episodeContent.getChild(0).getChild(episodeNum)
    end if

    'highlight the parent season for the focused episode
    if focusedContent <> invalid
      m.top.backgroundUriList = focusedContent.backgrounds
      m.top.relatedContentFocused = focusedContent

      for i = 0 to m.seasonMenu.content.getChildCount() - 1
        season = m.seasonMenu.content.getChild(i)
        k = k + season.NumEpisodes

        if k > episodeNum
          m.seasonMenu.jumpToItem = i
          exit for
        end if
      end for
    end if

    ' trigger navigate_within_page events in ContentController
    rowItem = m.episodeList.rowItemFocused

    if m.episodeListFocused = true AND (rowItem[0] <> m.oldRowItemFocused[0] OR rowItem[1] <> m.oldRowItemFocused[1])
      row = m.episodeList.rowItemFocused[0] + 1
      col = m.episodeList.rowItemFocused[1] + 1

      episodeListComponent = {}
      if m.oldRowItemFocused <> invalid
        oldRow = m.oldRowItemFocused[0] + 1
        oldCol = m.oldRowItemFocused[1] + 1
        oldEpisode = getEpisodeContent(m.oldRowItemFocused)
        episodeListComponent = {
          content_tile: m.Tracking.getAnalyticsTile(oldEpisode, oldCol, oldRow)
        }
      end if

      seriesDetailPage = getEpisodeVideoListTrackingPage(m.top.content)

      m.top.navigateWithinPageInfo = {
        pageOneof: m.Tracking.getAnalyticsPage(seriesDetailPage.type, seriesDetailPage.values)
        componentOneof: m.Tracking.getAnalyticsComponent("episode_video_list_component", episodeListComponent)
        means_of_navigation: "BUTTON" 'MeansOfNavigation enum
        vertical_location: row '1 based index
        horizontal_location: col
      }
    end if

    m.oldRowItemFocused = rowItem
    m.seasonListFocused = false
    m.episodeListFocused = true
  end if
End Function


Function jumpToCurrentEpisode(episodeId, contentNode)
  if episodeId <> invalid AND contentNode <> invalid
    row = contentNode.getChild(0)
    episodeToJump = m.NodeHelpers.getChildIndexById(row, episodeId)

    if episodeToJump > -1
      m.episodeList.jumpToRowItem = [0, episodeToJump]
    end if

  end if

End Function