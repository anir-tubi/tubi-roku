Function init()
  tubiLog("EPGHomeScreen.init")
  m.constants = getConstantsFromGlobal()
  m.Tracking = TubiTrackingInfo(m.constants)

  m.PageGroup = m.top.findNode("PageGroup")
  m.PageGroup.translation = [m.constants.ui.translations.marginX, 0]

  'infoPanel
  m.infoPanelParent = m.top.findNode("InfoPanelParent")
  m.infoPanel = m.top.findNode("InfoPanel")

  'category list
  m.containerMarkupGrid = m.top.findNode("containerMarkupGrid")
  m.containerMarkupGrid.observeFieldScoped("itemSelected", "onCategoryItemSelected")
  m.containerMarkupGrid.observeFieldScoped("itemFocused", "onCategoryItemFocused")
  m.containerMarkupGrid.observeFieldScoped("focusedChild", "onCategoryGridFocusChange")

  ' Track if user is actively navigating to prevent unwanted video playback
  m.isUserNavigating = false

  ' Track last focused category for NavigateWithinPageEvent scroll detection
  m.lastCategoryFocusedIndex = invalid

  'clock
  m.clock = m.top.findNode("clock")

  'epgTimeGrid
  m.epgTimeGrid = m.top.findNode("programGuide")
  m.epgTimeGrid.observeField("linearChannelFocusedUpdated", "onLinearChannelFocused")
  m.epgTimeGrid.observeField("linearChannelToPlayUpdated", "onLinearChannelToPlay")
  m.epgTimeGrid.observeField("okPressed", "onEPGTimegridOKPressed")
  m.epgTimeGrid.observeField("currFocusRow", "onCurrFocusRowChange")
  m.epgTimeGrid.observeField("isBackgroundImagesChanges", "isOnBackgroundImagesChange")
  m.epgTimeGrid.observeField("scrollingStatus", "onProgramGridScrollingStatus")
  m.epgTimeGrid.observeField("focusedChild", "onEPGTimeGridFocusChange")
  ' In this mode epg will expose the channel to Play only when uses presses/say "OK" or "PLAY"
  m.epgTimeGrid.EPGChannelPlayMode = m.constants.EPGChannelPlayMode.playItemOnSelect

  ' EPGFullMode is set to true so that epg has 4 rows as per epg design
  m.epgTimeGrid.EPGFullMode = true
  ' EPG Screen has requirement to start the videoplay as soon as it becomes visible. So play the first focused content, m.firstTime will be used.
  m.firstTime = true

  handleEPGCategoriesVisibility()

  'm.top
  m.top.screenLevel = m.constants.ui.screenLevels.epgScreen
  m.top.shouldShowSideNav = true
  m.top.observeField("updateTimeGridContent", "onTimeContentChange")
  m.top.observeField("containersList", "onContainersListChanged")
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("transportVoiceRequest", "onTransportVoiceRequest")
  m.top.observeField("id", "onIDChange")
  m.top.observeField("visible", "onVisibleChange")
  m.top.backgroundUriList = []
  m.top.handlesTransportVoiceRequests = true
  m.top.trackingPageInfo = {
    pageType: "linear_browse_page"
    pageValues: {}
  }
  m.epgTimeGrid.trackingPageInfo = m.top.trackingPageInfo
  'ChannelRefreshTimer
  m.channelRefreshTimer = m.top.findNode("channelRefreshTimer")
  'If channelRefreshTimer needs to be different than categoryContentRefreshTimeout then we need to add a constant
  m.channelRefreshTimer.duration = m.constants.timers.categoryContentRefreshTimeout
  m.channelRefreshTimer.observeField("fire", "onTimeGridRefreshTimer")
  m.channelRefreshTimer.control = "start"
End Function

Function onVisibleChange()
  if m.top.visible = true
    m.clock.control = "start"
  else
    m.clock.control = "stop"
  end if
End Function

Function onScreenFocusChange()
  tubiLog("EPGHomeScreen.onScreenFocusChange")
  if m.top.hasFocus() = true
    ' since epg main content node does not have valid Until, just findout the validUntil from first child
    ' This check might be necessary if user stay onsidenav for very long time.
    if m.epgTimeGrid.content <> invalid AND shouldRefresh(m.epgTimeGrid.content.getChild(0)) = true
      m.top.loadAllchannels = true
    end if

    setFocusOnEpgTimeGrid()

    m.top.shouldFocusWhenPushed = true

  else if m.top.isInFocusChain() = false
    m.top.refreshEPGScreenVideoPlay = true
    fadeInContentArea()
    ' Don't hide containerMarkupGrid once it's visible
  end if

End Function


Function onCategoryItemFocused(msg)
  tubiLog("EPGHomeScreen.onCategoryItemFocused")
  itemFocused = msg.getData()

  ' User is navigating in category menu, prevent video playback
  m.isUserNavigating = true

  ' Set scrolling status when category grid is being scrolled (stops timer)
  ' Similar to program grid's scrollingStatus - set true when scrolling
  m.top.categoryGridScrollingStatus = true

  ' Cancel existing timer if any
  if m.categoryGridScrollingTimer <> invalid
    m.categoryGridScrollingTimer.control = "stop"
    m.categoryGridScrollingTimer.unobserveFieldScoped("fire")
    m.categoryGridScrollingTimer = invalid
  end if

  ' Create timer to reset scrolling status after scrolling stops (similar to program grid)
  timer = CreateObject("roSGNode", "Timer")
  timer.duration = 0.3
  timer.repeat = false
  timer.observeFieldScoped("fire", "onCategoryGridScrollingComplete")
  timer.control = "start"
  m.categoryGridScrollingTimer = timer

  if itemFocused <> invalid AND m.containerMarkupGrid.content <> invalid
    ' MarkupGrid returns [row, col] array
    itemIndex = invalid
    if isNonEmptyArray(itemFocused) = true AND itemFocused.count() = 2
      row = itemFocused[0]
      col = itemFocused[1]
      itemIndex = row * m.containerMarkupGrid.numColumns + col
      focusedContainerItem = m.containerMarkupGrid.content.getChild(itemIndex)
    else if isNumber(itemFocused) = true
      ' Fallback for single index
      itemIndex = itemFocused
      focusedContainerItem = m.containerMarkupGrid.content.getChild(itemFocused)
    end if

    if focusedContainerItem <> invalid
      ' Send NavigateWithinPageEvent for scroll within categories (SCROLL)
      if itemIndex <> invalid AND m.lastCategoryFocusedIndex <> invalid AND m.lastCategoryFocusedIndex <> itemIndex
        sendEPGCategoryScrollNavigateWithinPageEvent(m.lastCategoryFocusedIndex, itemIndex)
      end if
      m.lastCategoryFocusedIndex = itemIndex

      containerId = focusedContainerItem.containerId
      categoryName = focusedContainerItem.title

      ' Update headerText with category name
      if categoryName <> invalid AND categoryName <> "" AND m.epgTimeGrid <> invalid
        headerText = m.epgTimeGrid.findNode("headerText")
        if headerText <> invalid
          headerText.text = categoryName
        end if
      end if

      if containerId <> invalid AND containerId <> ""
        ' Find the first channel with matching parentId in timeGridContent
        if m.top.timeGridContent <> invalid
          for i = 0 to m.top.timeGridContent.getChildCount() - 1
            channel = m.top.timeGridContent.getChild(i)
            if channel <> invalid AND channel.parentId <> invalid AND channel.parentId = containerId
              ' Jump to this channel using jumpToRowItemByID
              ' Format: [channelId, containerId]
              m.top.jumpToRowItemByID = [channel.id, containerId]
              tubiLog("EPGHomeScreen.onCategoryItemFocused: Jumping to channel " + channel.id + " in container " + containerId)

              ' Reset navigation flag after jump completes (allow video playback after navigation settles)
              resetNavigationFlag(800)
              exit for
            end if
          end for
        end if
      end if
    end if
  end if
End Function


Function onCategoryGridFocusChange(msg)
  tubiLog("EPGHomeScreen.onCategoryGridFocusChange")
  ' Show focus ring only when MarkupGrid has focus
  if m.containerMarkupGrid <> invalid
    if m.containerMarkupGrid.hasFocus() = true
      m.containerMarkupGrid.drawFocusFeedback = true
    else
      m.containerMarkupGrid.drawFocusFeedback = false
      ' Reset scrolling status when category grid loses focus
      m.top.categoryGridScrollingStatus = false
      ' Cancel timer when losing focus
      if m.categoryGridScrollingTimer <> invalid
        m.categoryGridScrollingTimer.control = "stop"
        m.categoryGridScrollingTimer.unobserveFieldScoped("fire")
        m.categoryGridScrollingTimer = invalid
      end if
    end if
  end if
End Function


Function onCategoryGridScrollingComplete(msg)
  ' Reset scrolling status when category grid scrolling stops (similar to program grid)
  m.top.categoryGridScrollingStatus = false
  if m.categoryGridScrollingTimer <> invalid
    m.categoryGridScrollingTimer.control = "stop"
    m.categoryGridScrollingTimer.unobserveFieldScoped("fire")
    m.categoryGridScrollingTimer = invalid
  end if
End Function


' Send NavigateWithinPageEvent when user scrolls within jump navigation categories (up/down)
Function sendEPGCategoryScrollNavigateWithinPageEvent(fromIndex, toIndex)
  if m.containerMarkupGrid <> invalid AND m.containerMarkupGrid.content <> invalid
    fromContainer = m.containerMarkupGrid.content.getChild(fromIndex)
    toContainer = m.containerMarkupGrid.content.getChild(toIndex)
    if fromContainer <> invalid AND toContainer <> invalid
      fromContainerId = fromContainer.containerId
      toContainerId = toContainer.containerId
      toVerticalPos = toIndex + 1
      utilityTileFrom = {}
      if fromContainerId <> invalid
        utilityTileFrom = { id: fromContainerId, row: fromIndex + 1, col: 1 }
      end if
      utilityTileTo = {}
      if toContainerId <> invalid
        utilityTileTo = { id: toContainerId, row: toVerticalPos, col: 1 }
      end if
      fromComponentValues = {
        category_row: 1
        category_col: fromIndex + 1
        utility_tile: utilityTileFrom
      }
      toComponentValues = {
        category_row: 1
        category_col: toVerticalPos
        utility_tile: utilityTileTo
      }
      pageType = "linear_browse_page"
      pageValues = {}
      if m.top.trackingPageInfo <> invalid
        if m.top.trackingPageInfo.pagetype <> invalid then pageType = m.top.trackingPageInfo.pagetype
        if m.top.trackingPageInfo.pageValues <> invalid then pageValues = m.top.trackingPageInfo.pageValues
      end if
      navigateWithinPageInfo = {
        pageOneof: m.Tracking.getAnalyticsPage(pageType, pageValues)
        componentOneof: m.Tracking.getAnalyticsComponent("channel_guide_component", fromComponentValues)
        dest_componentOneof: m.Tracking.getAnalyticsDestinationComponent("dest_channel_guide_component", toComponentValues)
        means_of_navigation: "SCROLL"
        horizontal_location: 1
        vertical_location: toVerticalPos
      }
      m.top.navigateWithinPageInfo = navigateWithinPageInfo
    end if
  end if
End Function


' Send NavigateWithinPageEvent when user moves from category to channel (right/confirm)
Function sendEPGCategoryToChannelNavigateWithinPageEvent()
  if m.containerMarkupGrid <> invalid AND m.containerMarkupGrid.content <> invalid
    itemFocused = m.containerMarkupGrid.itemFocused
    if itemFocused <> invalid
      itemIndex = invalid
      if isNonEmptyArray(itemFocused) = true AND itemFocused.count() = 2
        itemIndex = itemFocused[0] * m.containerMarkupGrid.numColumns + itemFocused[1]
      else if isNumber(itemFocused) = true
        itemIndex = itemFocused
      end if
      if itemIndex <> invalid
        focusedContainer = m.containerMarkupGrid.content.getChild(itemIndex)
        if focusedContainer <> invalid
          containerId = focusedContainer.containerId
          verticalPos = itemIndex + 1
          channelComponentValues = {
            category_row: 1
            category_col: verticalPos
            utility_tile: {}
          }
          if containerId <> invalid
            channelComponentValues.utility_tile = { id: containerId, row: verticalPos, col: 1 }
          end if
          channelRow = 1
          channelCol = 1
          contentTile = {}
          if m.top.timeGridContent <> invalid AND containerId <> invalid
            for i = 0 to m.top.timeGridContent.getChildCount() - 1
              channel = m.top.timeGridContent.getChild(i)
              if channel <> invalid AND channel.parentId = containerId
                channelRow = i + 1
                if channel.getChildCount() > 0
                  program = channel.getChild(0)
                  contentTile = m.Tracking.getAnalyticsTile(program, 1, channelRow)
                end if
                exit for
              end if
            end for
          end if
          pageType = "linear_browse_page"
          pageValues = {}
          if m.top.trackingPageInfo <> invalid
            if m.top.trackingPageInfo.pagetype <> invalid then pageType = m.top.trackingPageInfo.pagetype
            if m.top.trackingPageInfo.pageValues <> invalid then pageValues = m.top.trackingPageInfo.pageValues
          end if
          navigateWithinPageInfo = {
            pageOneof: m.Tracking.getAnalyticsPage(pageType, pageValues)
            componentOneof: m.Tracking.getAnalyticsComponent("channel_guide_component", channelComponentValues)
            dest_componentOneof: m.Tracking.getAnalyticsDestinationComponent("dest_epg_component", { content_tile: contentTile, category_slug: containerId })
            means_of_navigation: "BUTTON"
            horizontal_location: channelCol
            vertical_location: channelRow
          }
          m.top.navigateWithinPageInfo = navigateWithinPageInfo
        end if
      end if
    end if
  end if
End Function


' Send NavigateWithinPageEvent when user moves from channel to category (left)
Function sendEPGChannelToCategoryNavigateWithinPageEvent()
  if m.containerMarkupGrid <> invalid AND m.containerMarkupGrid.content <> invalid
    programFocused = m.epgTimeGrid.linearChannelFocused
    if programFocused <> invalid
      channel = programFocused.getParent()
      if channel <> invalid
        containerId = channel.parentId
        if containerId <> invalid
          contentTile = m.Tracking.getAnalyticsTile(programFocused, 1, 1)
          destContainerIndex = -1
          for i = 0 to m.containerMarkupGrid.content.getChildCount() - 1
            c = m.containerMarkupGrid.content.getChild(i)
            if c <> invalid AND c.containerId = containerId
              destContainerIndex = i
              exit for
            end if
          end for
          if destContainerIndex >= 0
            verticalPos = destContainerIndex + 1
            destComponentValues = {
              category_row: 1
              category_col: verticalPos
              utility_tile: { id: containerId, row: verticalPos, col: 1 }
            }
            pageType = "linear_browse_page"
            pageValues = {}
            if m.top.trackingPageInfo <> invalid
              if m.top.trackingPageInfo.pagetype <> invalid then pageType = m.top.trackingPageInfo.pagetype
              if m.top.trackingPageInfo.pageValues <> invalid then pageValues = m.top.trackingPageInfo.pageValues
            end if
            navigateWithinPageInfo = {
              pageOneof: m.Tracking.getAnalyticsPage(pageType, pageValues)
              componentOneof: m.Tracking.getAnalyticsComponent("epg_component", { content_tile: contentTile, category_slug: containerId })
              dest_componentOneof: m.Tracking.getAnalyticsDestinationComponent("dest_channel_guide_component", destComponentValues)
              means_of_navigation: "BUTTON"
              horizontal_location: 1
              vertical_location: verticalPos
            }
            m.top.navigateWithinPageInfo = navigateWithinPageInfo
          end if
        end if
      end if
    end if
  end if
End Function


Function onCategoryItemSelected(msg)
  tubiLog("EPGHomeScreen.onCategoryItemSelected")
  ' User is selecting a category, mark as navigating
  ' Jump logic is now handled in onCategoryItemFocused
  m.isUserNavigating = true
End Function


Function isOnBackgroundImagesChange(msg)
  backGroundImages = msg.getData()

  'When user is in roku_linear_reg_gate_v1_1 experiement, user will not play the content if needsLogIn = true, so we are just updating the backgroundImages.
  if backGroundImages = true AND getStatsigExperimentResource("roku_linear_reg_gate", "roku_linear_reg_gate_v1_1", false).enabled = true
    rowItemFocused = m.epgTimeGrid.rowItemFocused
    content = m.epgTimeGrid.content.getChild(rowItemFocused[0])
    m.top.backgroundUriList = determineBackgroundImage(content)
  end if
End Function


Function onLinearChannelFocused()
  tubiLog("EPGHomeScreen.onLinearChannelFocused")
  if m.epgTimeGrid <> invalid
    content = m.epgTimeGrid.linearChannelFocused
    if content <> invalid AND content.title <> invalid
      m.top.linearChannelFocused = content
      ' As per EPG requirement: if this is the first time content is focused after EPG started, then start playing the first content.
      ' all the other time, only selected content will get to play.
      ' if contentIdToFocusOnLoadComplete has been set, that would mean the content play has been requested from deeplink
      ' so do not play the first channel but play the focused channel.
      if m.firstTime = true AND m.top.contentIdToFocusOnLoadComplete = ""
        m.firstTime = false
        'TODO:: check if race condition happens.
        m.epgTimeGrid.setFocusedToPlay = true
        m.top.refreshEPGScreenVideoPlay = false
      else if m.top.contentIdToFocusOnLoadComplete <> ""
        m.firstTime = false
        contentIdToFocusOnLoadComplete = m.top.contentIdToFocusOnLoadComplete
        m.top.contentIdToFocusOnLoadComplete = ""
        m.top.jumpToRowItemByID = [contentIdToFocusOnLoadComplete, ""]
      end if
      populateInfoPanel(m.epgTimeGrid.linearChannelFocused)
    end if
  end if
End Function


'@contentNode: program content node
Function populateInfoPanel(contentNode)
  tubilog("EPGHomeScreen.populateInfoPanel")
  if contentNode <> invalid
    m.InfoPanel.mode = m.constants.ui.infoPanelModes.epg
    m.InfoPanel.title = contentNode.title
    m.InfoPanel.episodeTitle = contentNode.epgProgramTitle
    m.InfoPanel.width = 650
    m.InfoPanel.leftHeaderImageUri = contentNode.FHDPosterUrl

    lineOneData = {}
    lineOneData.hoursOfAiring = contentNode.hoursOfAiring
    lineOneData.rating = contentNode.rating
    lineOneData.hasCC = contentNode.hasSubtitles
    lineOneData.hasAudioDescription = contentNode.hasAudioDescription

    if contentNode.descriptors <> invalid AND contentNode.descriptors.Count() > 0
      lineOneData.descriptorCode = contentNode.descriptors.join(", ") ' To DO : When when we get real values into TAGS
    end if

    m.InfoPanel.lineOneData = lineOneData
    m.InfoPanel.description = contentNode.description

    ' Always set needsLogin = false for linear content in infoPanel
    m.InfoPanel.needsLogin = false

  end if

  m.InfoPanel.calculateHeight = true
End Function



Function onTimeContentChange()
  tubiLog("EPGHomeScreen.onTimeContentChange")
  if m.top.timeGridContent <> invalid
    ' Clear then set to force ProgramGuide to re-render when content structure changes (e.g. favorites removed on sign out)
    m.epgTimeGrid.content = invalid
    m.epgTimeGrid.content = m.top.timeGridContent
    m.epgTimeGrid.contentUpdated = true
    m.top.contentReady = true
    m.InfoPanel.visible = true

    getStatsigExperimentResource("roku_linear_epg_categories", "roku_linear_epg_categories_v1", true)
  end if
End Function


Function onContainersListChanged(msg)
  tubiLog("EPGHomeScreen.onContainersListChanged")
  containersList = msg.getData()
  if containersList <> invalid AND m.containerMarkupGrid <> invalid
    handleEPGCategoriesVisibility()

    if m.epgCategoriesVariant <> "none"
      m.containerMarkupGrid.content = containersList

      m.containerMarkupGrid.visible = false
    else
      m.containerMarkupGrid.content = invalid
      m.containerMarkupGrid.visible = false
    end if

    ' Initialize theme for category grid focus styling
    if m.global <> invalid
      m.global.observeFieldScoped("theme", "onThemeChange")
    end if
    onThemeChange()
  end if
End Function


Function handleEPGCategoriesVisibility()
  m.epgCategoriesVariant = "none"
  epgCategoriesExperiment = getStatsigExperimentResource("roku_linear_epg_categories", "roku_linear_epg_categories_v1", false)
  if epgCategoriesExperiment <> invalid AND epgCategoriesExperiment.variant <> invalid
    m.epgCategoriesVariant = epgCategoriesExperiment.variant
  end if

  if m.epgTimeGrid <> invalid
    isCategoriesWithFavorites = (m.epgCategoriesVariant = "categories_with_favorites")
    m.epgTimeGrid.channelGridFocusable = isCategoriesWithFavorites
    m.epgTimeGrid.categoriesMenuVisible = (m.epgCategoriesVariant <> "none")
  end if
End Function


Function onThemeChange(msg = invalid)
  theme = getThemeFromGlobal()
  if theme <> invalid AND m.containerMarkupGrid <> invalid
    m.containerMarkupGrid.focusBitmapBlendColor = theme.focusedColor
    m.containerMarkupGrid.focusFootprintBlendColor = theme.neutralColor
  end if
End Function


Function onEPGTimeGridFocusChange(msg)
  tubiLog("EPGHomeScreen.onEPGTimeGridFocusChange")
  epgCategoriesVariant = "none"
  epgCategoriesExperiment = getStatsigExperimentResource("roku_linear_epg_categories", "roku_linear_epg_categories_v1", false)
  if epgCategoriesExperiment <> invalid AND epgCategoriesExperiment.variant <> invalid
    epgCategoriesVariant = epgCategoriesExperiment.variant
  end if

  if m.containerMarkupGrid <> invalid AND epgCategoriesVariant <> "none"
    if m.epgTimeGrid.hasFocus() = true OR m.epgTimeGrid.isInFocusChain() = true
      if m.containerMarkupGrid.content <> invalid AND m.containerMarkupGrid.content.getChildCount() > 0
        m.containerMarkupGrid.visible = true
      end if
    end if
  end if
End Function


Function onProgramGridScrollingStatus(msg)
  scrollingStatus = msg.getData()
  if scrollingStatus = true
    ' User is scrolling in ProgramGrid, prevent video playback
    m.isUserNavigating = true
  else
    ' User stopped scrolling, reset flag after delay
    resetNavigationFlag(300)
  end if
End Function


Function onLinearChannelToPlay(msg)
  tubiLog("EPGHomeScreen.onLinearChannelToPlay")
  linearChannelupdated = msg.getData()

  if linearChannelupdated = true AND m.isUserNavigating = false
    linearChannelToPlay = m.epgTimeGrid.linearChannelToPlay

    col = 1
    row = 1
    if m.epgTimeGrid <> invalid AND m.epgTimeGrid.rowItemFocused <> invalid AND m.epgTimeGrid.rowItemFocused.Count() > 0
      col = m.epgTimeGrid.rowItemFocused[1] + 1
      row = m.epgTimeGrid.rowItemFocused[0] + 1
    end if

    if linearChannelToPlay <> invalid
      m.top.trackingComponentInfo = {
        componentType: "epg_component"
        componentValues: {
          content_tile: m.Tracking.getAnalyticsTile(linearChannelToPlay, col, row)
          category_slug: linearChannelToPlay.parentId
        }
      }

      if m.top.linearChannelToPlay = invalid OR (m.top.linearChannelToPlay <> invalid AND linearChannelToPlay <> invalid AND m.top.linearChannelToPlay.id <> linearChannelToPlay.id)
        m.top.linearChannelToPlay = linearChannelToPlay
        m.top.backgroundUriList = determineBackgroundImage(linearChannelToPlay)
      end if
    end if
  end if

End Function


' When OK has been pressed on EPG TimeGrid, maximize the player.
Function onEPGTimegridOKPressed()
  if m.top.linearChannelToPlay <> invalid AND m.epgTimeGrid.linearChannelFocused <> invalid AND m.epgTimeGrid.linearChannelFocused.id = m.top.linearChannelToPlay.id
    m.top.epgScreenOkPressed = true
  end if
End Function


Function onTransportVoiceRequest(msg)
  response = "unhandled"
  inputInfo = msg.getData()
  command = ""
  if inputInfo <> invalid AND inputInfo.command <> invalid
    command = inputInfo.command
  end if
  tubiLog("EPGHomeScreen.onTransportVoiceRequest " + command)

  if m.epgTimeGrid.isInFocusChain() = true
    if command = "play"
      handlePlayInput()
      response = "success"
    else if command = "ok"
      handlePlayInput()
      response = "success"
    end if
  end if

  inputInfo.response = response
  m.top.transportVoiceResponse = inputInfo
End Function


Function handlePlayInput()
  if m.epgTimeGrid.isInFocusChain() = true
    if m.epgTimeGrid.linearChannelFocused <> invalid
      m.epgTimeGrid.setFocusedToPlay = true
      'In EPG case both voice commands "play" and "ok" will play the content in full screen.
      onEPGTimegridOKPressed()
      m.top.trackingComponentInfo = getTrackingComponentInfoOfEPGGridList(m.epgTimeGrid.linearChannelFocused.getParent(), m.epgTimeGrid.rowItemfocused)
    end if
  end if
End Function



Function onKeyEvent(key as String, press as Boolean) as Boolean
  tubiLog("EPGHomeScreen.onKeyEvent")
  if press
    ' Track navigation keys to prevent unwanted video playback
    if key = "up" OR key = "down" OR key = "left" OR key = "right"
      m.isUserNavigating = true
      ' Reset navigation flag after a short delay
      resetNavigationFlag(500)
    end if

    if key = "play" AND m.epgTimeGrid.isInFocusChain() = true
      handlePlayInput()
      return true
    else if key = "back" OR key = "left"
      epgCategoriesVariant = "none"
      epgCategoriesExperiment = getStatsigExperimentResource("roku_linear_epg_categories", "roku_linear_epg_categories_v1", false)
      if epgCategoriesExperiment <> invalid AND epgCategoriesExperiment.variant <> invalid
        epgCategoriesVariant = epgCategoriesExperiment.variant
      end if
      if epgCategoriesVariant <> "none" AND m.epgTimeGrid.isInFocusChain() = true
        if m.containerMarkupGrid <> invalid AND m.containerMarkupGrid.content <> invalid AND m.containerMarkupGrid.content.getChildCount() > 0
          sendEPGChannelToCategoryNavigateWithinPageEvent()
          m.containerMarkupGrid.setFocus(true)
          return true
        end if
      end if
    else if key = "right"
      epgCategoriesVariant = "none"
      epgCategoriesExperiment = getStatsigExperimentResource("roku_linear_epg_categories", "roku_linear_epg_categories_v1", false)
      if epgCategoriesExperiment <> invalid AND epgCategoriesExperiment.variant <> invalid
        epgCategoriesVariant = epgCategoriesExperiment.variant
      end if
      if epgCategoriesVariant <> "none" AND m.containerMarkupGrid <> invalid AND m.containerMarkupGrid.hasFocus() = true
        sendEPGCategoryToChannelNavigateWithinPageEvent()
        m.epgTimeGrid.isChannelGridFocused = true
        m.epgTimeGrid.setFocus(true)
        return true
      end if
    end if
  end if
  return false
End Function


Function resetNavigationFlag(delayMs = 500)
  ' Reset navigation flag after user stops navigating
  ' Cancel any existing timer first
  if m.navigationResetTimer <> invalid
    m.navigationResetTimer.control = "stop"
    m.navigationResetTimer.unobserveFieldScoped("fire")
    m.navigationResetTimer = invalid
  end if

  ' Create new timer to reset flag after delay
  timer = CreateObject("roSGNode", "Timer")
  timer.duration = delayMs / 1000.0
  timer.repeat = false
  timer.observeFieldScoped("fire", "onNavigationFlagReset")
  timer.control = "start"
  m.navigationResetTimer = timer
End Function


Function onNavigationFlagReset(msg)
  tubiLog("EPGHomeScreen.onNavigationFlagReset")
  m.isUserNavigating = false
  if m.navigationResetTimer <> invalid
    m.navigationResetTimer.control = "stop"
    m.navigationResetTimer.unobserveFieldScoped("fire")
    m.navigationResetTimer = invalid
  end if
End Function


Function setFocusOnEpgTimeGrid()
  tubiLog("EPGHomeScreen.setFocusOnEpgTimeGrid ")
  handleEPGCategoriesVisibility()

  m.epgTimeGrid.setFocusedToPlay = true

  fadeInContentArea()
  m.epgTimeGrid.setFocus(true)
  m.top.refreshEPGScreenVideoPlay = false

  if m.containerMarkupGrid <> invalid AND m.epgCategoriesVariant <> "none" AND m.containerMarkupGrid.content <> invalid AND m.containerMarkupGrid.content.getChildCount() > 0
    m.containerMarkupGrid.visible = true
  end if
End Function


Function onTimeGridRefreshTimer()
  tubiLog("EPGHomeScreen.onTimeGridRefreshTimer")
  m.top.loadAllChannels = true
End Function


Function onIDChange()
  '//Set the tracking based on the id of the homescreen
  '//::NOTE:: id should only be set after the instantiation of the HomeScreen, but before the screen is added to the stack
  newTrackingPageInfo = m.top.trackingPageInfo
  analyticsContentMode = m.Tracking.getAnalyticsHomePageContentMode(m.top.id)
  newTrackingPageInfo.pageValues = { content_mode: analyticsContentMode }

  m.top.trackingPageInfo = newTrackingPageInfo
End Function


' @timegridItem: roSGNode, TubiContentNode with metadata for an item in the grid
' @itemPosition: array, 2d array with [x,y] grid coordinate information
Function getTrackingComponentInfoOfEPGGridList(timegridItem, itemPosition)
  trackingComponentInfo = {}
  if timegridItem <> invalid AND itemPosition <> invalid AND itemPosition.Count() = 2
    componentValues = {}
    tile = m.Tracking.getAnalyticsTile(timegridItem, itemPosition[1] + 1)
    componentValues["content_tile"] = tile

    ' Set the tracking component of the timegridItem that was passed so it can be accessed as part of the navigateToPage event
    trackingComponentInfo = {
      componentType: "EPGComponent"
      componentValues: componentValues
    }
  end if

  return trackingComponentInfo
End Function


Function fadeOutContentArea()
  stopAnimation(m.gridFade)
  if m.epgTimeGrid.opacity > 0
    m.gridFade = fade(m.epgTimeGrid, "out", .4, 0.0, 0.4)
  end if

  stopAnimation(m.infoPanelFade)
  if m.InfoPanelParent.opacity > 0
    m.infoPanelFade = fade(m.InfoPanelParent, "out", .4, 0.0, 0.4)
  end if
End Function


Function fadeInContentArea()
  stopAnimation(m.gridFade)
  if m.epgTimeGrid.opacity < 1
    m.gridFade = fade(m.epgTimeGrid, "in", .4, 0.0, 1)
  end if

  stopAnimation(m.infoPanelFade)
  if m.InfoPanelParent.opacity < 1
    m.infoPanelFade = fade(m.InfoPanelParent, "in", .4, 0.0, 1)
  end if
End Function
