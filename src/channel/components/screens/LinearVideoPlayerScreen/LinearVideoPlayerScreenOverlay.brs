Function init()
  m.constants = getConstantsFromGlobal()
  m.Tracking = TubiTrackingInfo(m.constants)
  m.top.observeFieldScoped("showOverlay", "onShowOverlay")
  m.top.observeFieldScoped("hideOverlay", "onHideOverlay")
  m.top.observeFieldScoped("closedCaptioningItems", "onClosedCaptionListUpdated")

  m.OverlayParent = m.top.findNode("OverlayParent")
  m.OverlayContentArea = m.top.findNode("overlayContentArea")
  m.clock = m.top.findNode("clock")

  m.EPG = m.top.findNode("EPG")
  m.EPG.EPGChannelPlayMode = m.constants.EPGChannelPlayMode.playItemOnFocus
  m.EPG.observeField("linearChannelFocusedUpdated", "onChannelFocused")
  m.EPG.observeField("linearChannelToPlayUpdated", "onLinearChannelToPlayChanged")
  m.EPGHorizontalSlide = m.top.findNode("EPGHorizontalSlide")
  m.EPGHorizontalSlide.translation = [m.constants.ui.translations.marginX, 0]
  m.EPGSpinner = m.top.findNode("EPGSpinner")
  m.infoPanel = m.top.findNode("infoPanel")
  m.EPGError = m.top.findNode("EPGError")
  m.EPGError.text = getTranslation("error_noGetChannelGuide_description")
  m.sideNav = m.top.findNode("sideNav")
  m.sideNav.observeFieldScoped("focusedButtonID", "onSideNavFocusChange")
  m.sideNav.observeFieldScoped("selectedButtonID", "onSideNavSelectChange")
  m.top.observeField("updateTimeGridContent", "onTimeContentChange")
  m.top.observeField("timeGridContentLoading", "onTimeGridContentLoadingChange")

  'category list
  m.containerMarkupGrid = m.top.findNode("containerMarkupGrid")
  m.containerMarkupGrid.observeFieldScoped("itemSelected", "onCategoryItemSelected")
  m.containerMarkupGrid.observeFieldScoped("itemFocused", "onCategoryItemFocused")
  m.containerMarkupGrid.observeFieldScoped("focusedChild", "onCategoryGridFocusChange")
  m.EPG.observeField("focusedChild", "onEPGTimeGridFocusChange")
  m.top.observeField("containersList", "onContainersListChanged")

  m.epgCategoriesVariant = "none"
  epgCategoriesExperiment = getStatsigExperimentResource("roku_linear_epg_categories", "roku_linear_epg_categories_v1", false)
  if epgCategoriesExperiment <> invalid AND epgCategoriesExperiment.variant <> invalid
    m.epgCategoriesVariant = epgCategoriesExperiment.variant
  end if

  '//Closed Captioning Nodes
  m.closedCaptioningGroup = m.top.findNode("closedCaptioningGroup")
  m.closedCaptioningButtonList = m.top.findNode("closedCaptioningButtonList")
  m.closedCaptioningButtonList.observeFieldScoped("rowItemSelected", "onCCContentSelected")
  m.closedCaptioningButtonList.observeFieldScoped("rowItemFocused", "onCCContentFocused")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.EPGError, typographyConstants.ids.bodyLargeStrong)

  theme = getThemeFromGlobal()
  if theme <> invalid
    m.closedCaptioningButtonList.focusBitmapBlendColor = theme.focusedColor
    m.closedCaptioningButtonList.focusFootprintBlendColor = theme.neutralColor2
    if m.containerMarkupGrid <> invalid
      m.containerMarkupGrid.focusBitmapBlendColor = theme.focusedColor
      m.containerMarkupGrid.focusFootprintBlendColor = theme.neutralColor
    end if
  end if

  ' Track last focused category for NavigateWithinPageEvent scroll detection
  m.lastCategoryFocusedIndex = invalid
  m.categoryGridScrollingTimer = CreateObject("roSGNode", "Timer")
  m.categoryGridScrollingTimer.duration = m.constants.timers.epgGridScrollingSettleDuration
  m.categoryGridScrollingTimer.repeat = false
  m.categoryGridScrollingTimer.observeFieldScoped("fire", "onCategoryGridScrollingComplete")
  m.middleNavFocusedContainerId = invalid

  '//It is best not to check the visible state of a UI element as it may be in a transitionary state. So m.bEPGVisible is used to know what is the intention of the EPG visible state.
  '//if the EPG is visible, then bEPGVisible is true. If the closed captioning is visible (and the EPG is not), then bEPGVisible is false. If there are more than 2 states, then this boolean will need to be changed to a different kind of variable
  m.bEPGVisible = true
  m.nDelaySeconds = 1
  m.originalEPGTranslation = m.EPGHorizontalSlide.translation
  m.slideOutEPGTranslation = [390, m.EPGHorizontalSlide.translation[1]]
  resetUI(false)
  m.firstTimeEPGLaunched = true 'm.firstTimeEPGLaunched is a flag to avoid jumping to the content 'currently playing' causing epg to trigger stop video and refetch the channel.
End Function


Function onChannelFocused()
  tubiLog("LinearVideoPlayerScreenOverlay.onChannelFocused")
  m.top.reactedToKeyPresss = true
  populateInfoPanel(m.EPG.linearChannelFocused)
End Function


'@contentNode: program content node
Function populateInfoPanel(contentNode)
  tubiLog("LinearVideoPlayerScreenOverlay.populateInfoPanel")
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
      lineOneData.descriptorCode = contentNode.descriptors.join(", ") ' ::TODO:: When when we get real values into TAGS
    end if

    m.InfoPanel.lineOneData = lineOneData
    m.InfoPanel.description = contentNode.description

    ' Always set needsLogin = false for linear content in infoPanel
    m.InfoPanel.needsLogin = false
  end if

  m.InfoPanel.calculateHeight = true
End Function


Function onLinearChannelToPlayChanged(msg)
  tubiLog("LinearVideoPlayerScreenOverlay.onLinearChannelToPlayChanged")

  selectedChannelUpdated = msg.getData()
  if selectedChannelUpdated = true
    selectedChannel = m.EPG.linearChannelToPlay
    if selectedChannel <> invalid AND m.firstTimeEPGLaunched <> true
      m.top.linearChannelToPlay = selectedChannel
      m.top.linearChannelToPlayUpdated = true
    end if

    if m.firstTimeEPGLaunched = true
      m.firstTimeEPGLaunched = false
    end if
  end if
End Function


Function onSideNavFocusChange()
  tubiLog("LinearVideoPlayerScreenOverlay.onSideNavFocusChange")
  m.top.reactedToKeyPresss = true
End Function


Function onSideNavSelectChange()
  tubilog("LinearVideoPlayerScreenOverlay.onSideNavSelectChange")
  userInteraction = "CONFIRM"
  selectedLinearSideNavId = ""
  if m.sideNav.selectedButtonID = m.constants.ui.linearSideNavIds.subtitles
    selectedLinearSideNavId = m.constants.ui.linearSideNavIds.subtitles
    setComponentInteractionForSideNavInVideoPlayerOverLay(userInteraction, selectedLinearSideNavId)
    displayClosedCaptioningMenu()
  else if m.sideNav.selectedButtonID = m.constants.ui.linearSideNavIds.epg
    selectedLinearSideNavId = m.constants.ui.linearSideNavIds.epg
    setComponentInteractionForSideNavInVideoPlayerOverLay(userInteraction, selectedLinearSideNavId)
    hideOverlay()
    m.top.navigateToEPGScreen = true
  end if
  m.top.reactedToKeyPresss = true
End Function


Function onShowOverlay()
  if m.top.isDisplaying = false
    displayOverlay(m.top.displayWithDelay)
  end if
End Function


Function onHideOverlay()
  if m.firstTimeEPGLaunched = true
    'EPG is still loading, so keep the overlay with spinning  wheel
  else if m.top.isDisplaying = true
    hideOverlay()
  end if
End Function


Function onCCContentFocused()
  tubiLog("LinearVideoPlayerScreenOverlay.onCCContentFocused")
  '//When the closed captioning layer is focused, make sure to update reactedToKeyPresss so the transport overlay does not automatically hide
  m.top.reactedToKeyPresss = true
End Function


Function onCCContentSelected(msg)
  tubiLog("LinearVideoPlayerScreenOverlay.onCCContentSelected")
  list = msg.getRoSGNode()
  item = msg.getData()

  hideOverlay()
  ccItemContent = list.content.getChild(item[0]).getChild(item[1])
  if ccItemContent.trackname <> invalid AND ccItemContent.trackname <> ""
    if ccItemContent.trackname = "off"
      m.top.closedCaptioningSelectedLanguage = ""
    else
      m.top.closedCaptioningSelectedLanguage = ccItemContent.trackname
    end if
  end if
End Function


Function onClosedCaptionListUpdated()
  root = m.top.closedCaptioningItems
  if root <> invalid
    '//Display the side nav in case it had been previously hidden
    m.sideNav.visible = true

    m.closedCaptioningButtonList.content = root
    centerClosedCaptioning()

  else
    '//Hide the side nav since there are no close captions
    m.sideNav.visible = false
  end if

End Function


Function centerClosedCaptioning()
  nSpacing = m.closedCaptioningButtonList.rowItemSpacing[0][0]
  nItemWidth = m.closedCaptioningButtonList.rowItemSize[0][0]
  nItems = m.closedCaptioningButtonList.content.getChild(0).getChildCount()
  nListWidth = (nItems * nItemWidth) + ((nItems - 1) * nSpacing)

  nCenterPointX = (1920 - nListWidth) / 2
  m.closedCaptioningButtonList.translation = [nCenterPointX, m.closedCaptioningButtonList.translation[1]]
End Function


Function onContainersListChanged(msg)
  tubiLog("LinearVideoPlayerScreenOverlay.onContainersListChanged")
  containersList = msg.getData()

  if containersList <> invalid AND m.containerMarkupGrid <> invalid
    if m.epgCategoriesVariant <> "none"
      m.containerMarkupGrid.content = containersList
      m.containerMarkupGrid.visible = false
    else
      m.containerMarkupGrid.content = invalid
      m.containerMarkupGrid.visible = false
    end if

    if m.EPG <> invalid
      m.EPG.channelGridFocusable = (m.epgCategoriesVariant = "categories_with_favorites")
      m.EPG.categoriesMenuVisible = (m.epgCategoriesVariant <> "none")
    end if
  end if
End Function


Function onCategoryItemFocused(msg)
  tubiLog("LinearVideoPlayerScreenOverlay.onCategoryItemFocused")
  itemFocused = msg.getData()
  m.top.reactedToKeyPresss = true

  m.top.categoryGridScrollingStatus = true

  ' Debounce: stop cancels any pending fire; start begins a new delay so "scrolling complete"
  ' runs only after focus stays on one item for the full settle duration.
  m.categoryGridScrollingTimer.control = "stop"
  m.categoryGridScrollingTimer.control = "start"

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
      if itemIndex <> invalid AND m.lastCategoryFocusedIndex <> invalid AND m.lastCategoryFocusedIndex <> itemIndex
        sendOverlayCategoryScrollNavigateWithinPageEvent(m.lastCategoryFocusedIndex, itemIndex)
      end if
      m.lastCategoryFocusedIndex = itemIndex

      containerId = focusedContainerItem.containerId
      categoryName = focusedContainerItem.title

      ' Update headerText with category name
      if categoryName <> invalid AND categoryName <> "" AND m.EPG <> invalid
        headerText = m.EPG.findNode("headerText")
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
              ' Jump to this channel using jumpToLinearChannelID
              ' Format: [channelId, containerId]
              m.EPG.jumpToLinearChannelID = [channel.id, containerId]
              tubiLog("LinearVideoPlayerScreenOverlay.onCategoryItemFocused: Jumping to channel " + channel.id + " in container " + containerId)
              exit for
            end if
          end for
        end if
      end if
    end if
  end if
End Function


Function onCategoryItemSelected(msg)
  tubiLog("LinearVideoPlayerScreenOverlay.onCategoryItemSelected")
  m.top.reactedToKeyPresss = true
  selectedContainerId = getCategoryContainerIdFromMarkupGrid(m.containerMarkupGrid, msg.getData())
  if isNonEmptyString(selectedContainerId) = true
    sendLinearVideoOverlayMiddleNavComponentInteractionForContainerId(m.top, m.Tracking, selectedContainerId, "CONFIRM")
  end if
End Function


Function sendOverlayCategoryScrollNavigateWithinPageEvent(lastFocusedIndex, focusedIndex)
  if m.containerMarkupGrid <> invalid AND m.containerMarkupGrid.content <> invalid AND m.top.currentLinearVideoContent <> invalid
    fromContainer = m.containerMarkupGrid.content.getChild(lastFocusedIndex)
    toContainer = m.containerMarkupGrid.content.getChild(focusedIndex)
    if fromContainer <> invalid AND toContainer <> invalid
      fromContainerId = fromContainer.containerId
      toContainerId = toContainer.containerId
      toVerticalPos = focusedIndex + 1
      utilityTileFrom = {}
      if fromContainerId <> invalid
        utilityTileFrom = { id: fromContainerId, row: lastFocusedIndex + 1, col: 1 }
      end if
      utilityTileTo = {}
      if toContainerId <> invalid
        utilityTileTo = { id: toContainerId, row: toVerticalPos, col: 1 }
      end if
      fromComponentValues = {
        category_row: 1
        category_col: lastFocusedIndex + 1
        utility_tile: utilityTileFrom
      }
      toComponentValues = {
        category_row: 1
        category_col: toVerticalPos
        utility_tile: utilityTileTo
      }
      pageValues = { video_id: m.top.currentLinearVideoContent.id.toInt() }
      destMiddleNavValues = getMiddleNavDestinationValuesForContainerId(m.Tracking, toContainerId)
      destComponentType = "dest_middle_nav_component"
      destComponentValues = destMiddleNavValues
      if destMiddleNavValues.count() = 0
        destComponentType = "dest_channel_guide_component"
        destComponentValues = toComponentValues
      end if
      navigateWithinPageInfo = {
        pageOneof: m.Tracking.getAnalyticsPage("video_player_page", pageValues)
        componentOneof: m.Tracking.getAnalyticsComponent("epg_component", fromComponentValues)
        dest_componentOneof: m.Tracking.getAnalyticsDestinationComponent(destComponentType, destComponentValues)
        means_of_navigation: "SCROLL"
        horizontal_location: 1
        vertical_location: toVerticalPos
      }
      m.top.linearOverlayCategoryNavigateWithinPageInfo = navigateWithinPageInfo
    end if
  end if
End Function


Function sendOverlayCategoryToChannelNavigateWithinPageEvent()
  if m.containerMarkupGrid <> invalid AND m.containerMarkupGrid.content <> invalid AND m.top.currentLinearVideoContent <> invalid
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
          pageValues = { video_id: m.top.currentLinearVideoContent.id.toInt() }
          destMiddleNavValues = getMiddleNavDestinationValuesForContainerId(m.Tracking, containerId)
          destComponentType = "dest_middle_nav_component"
          destComponentValues = destMiddleNavValues
          if destMiddleNavValues.count() = 0
            destComponentType = "dest_epg_component"
            destComponentValues = { content_tile: contentTile, category_slug: containerId }
          end if
          navigateWithinPageInfo = {
            pageOneof: m.Tracking.getAnalyticsPage("video_player_page", pageValues)
            componentOneof: m.Tracking.getAnalyticsComponent("epg_component", channelComponentValues)
            dest_componentOneof: m.Tracking.getAnalyticsDestinationComponent(destComponentType, destComponentValues)
            means_of_navigation: "BUTTON"
            horizontal_location: channelCol
            vertical_location: channelRow
          }
          m.top.linearOverlayCategoryNavigateWithinPageInfo = navigateWithinPageInfo
        end if
      end if
    end if
  end if
End Function


Function sendOverlayChannelToCategoryNavigateWithinPageEvent()
  if m.containerMarkupGrid <> invalid AND m.containerMarkupGrid.content <> invalid AND m.top.currentLinearVideoContent <> invalid
    programFocused = m.EPG.linearChannelFocused
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
            pageValues = { video_id: m.top.currentLinearVideoContent.id.toInt() }
            destMiddleNavValues = getMiddleNavDestinationValuesForContainerId(m.Tracking, containerId)
            destComponentType = "dest_middle_nav_component"
            destComponentValuesForNav = destMiddleNavValues
            if destMiddleNavValues.count() = 0
              destComponentType = "dest_channel_guide_component"
              destComponentValuesForNav = destComponentValues
            end if
            navigateWithinPageInfo = {
              pageOneof: m.Tracking.getAnalyticsPage("video_player_page", pageValues)
              componentOneof: m.Tracking.getAnalyticsComponent("epg_component", { content_tile: contentTile, category_slug: containerId })
              dest_componentOneof: m.Tracking.getAnalyticsDestinationComponent(destComponentType, destComponentValuesForNav)
              means_of_navigation: "BUTTON"
              horizontal_location: 1
              vertical_location: verticalPos
            }
            m.top.linearOverlayCategoryNavigateWithinPageInfo = navigateWithinPageInfo
          end if
        end if
      end if
    end if
  end if
End Function


Function onCategoryGridFocusChange(msg)
  tubiLog("LinearVideoPlayerScreenOverlay.onCategoryGridFocusChange")
  ' Show focus ring only when MarkupGrid has focus
  if m.containerMarkupGrid <> invalid
    if m.containerMarkupGrid.hasFocus() = true
      m.containerMarkupGrid.drawFocusFeedback = true
      if m.middleNavFocusedContainerId = invalid
        focusedContainerId = getCategoryContainerIdFromMarkupGrid(m.containerMarkupGrid, invalid)
        if isNonEmptyString(focusedContainerId) = true
          sendLinearVideoOverlayMiddleNavComponentInteractionForContainerId(m.top, m.Tracking, focusedContainerId, "TOGGLE_ON")
          m.middleNavFocusedContainerId = focusedContainerId
        end if
      end if
    else
      m.containerMarkupGrid.drawFocusFeedback = false
      if m.middleNavFocusedContainerId <> invalid
        sendLinearVideoOverlayMiddleNavComponentInteractionForContainerId(m.top, m.Tracking, m.middleNavFocusedContainerId, "TOGGLE_OFF")
        m.middleNavFocusedContainerId = invalid
      end if

      onCategoryGridScrollingComplete()
    end if
  end if
End Function


Function onCategoryGridScrollingComplete()
  m.top.categoryGridScrollingStatus = false
  m.categoryGridScrollingTimer.control = "stop"
End Function


Function onEPGTimeGridFocusChange(msg)
  tubiLog("LinearVideoPlayerScreenOverlay.onEPGTimeGridFocusChange")
  ' Show category pills only when experiment is not control (same as EPGHomeScreen)
  if m.containerMarkupGrid <> invalid AND m.epgCategoriesVariant <> "none"
    if m.EPG.hasFocus() = true OR m.EPG.isInFocusChain() = true
      if m.containerMarkupGrid.content <> invalid AND m.containerMarkupGrid.content.getChildCount() > 0
        m.containerMarkupGrid.visible = true
      end if
    end if
  end if
End Function


Function displayOverlay(bDelay = false)
  tubiLog("LinearVideoPlayerScreenOverlay.displayOverlay")
  '//open the the overlay
  if m.animationHide <> invalid
    m.animationHide.unobserveField("state")
    m.animationHide.control = "stop"
  end if
  m.clock.control = "start"
  m.top.isDisplaying = true
  jumpEPGToCurrentPlayingVideo(true)
  m.EPG.setFocus(true)
  nDelaySeconds = 0
  if bDelay = true
    nDelaySeconds = m.nDelaySeconds
  end if

  fade(m.OverlayParent, "in", m.top.animationDuration, nDelaySeconds)
  m.animationDisplay = slideFade(m.OverlayContentArea, "below", "in", m.top.animationDuration, nDelaySeconds)
  if m.animationDisplay <> invalid
    m.animationDisplay.observeField("state", "onDisplayAnimationStopped")
  end if
End Function


Function hideOverlay()
  tubiLog("LinearVideoPlayerScreenOverlay.hideOverlay")
  '//close the the overlay
  if m.animationDisplay <> invalid
    m.animationDisplay.unobserveField("state")
    m.animationDisplay.control = "stop"
  end if
  m.top.isDisplaying = false

  m.clock.control = "stop"
  fade(m.OverlayParent, "out", m.top.animationDuration)
  m.animationHide = slideFade(m.OverlayContentArea, "below", "out", m.top.animationDuration)
  if m.animationHide <> invalid
    m.animationHide.observeField("state", "onHideAnimationStopped")
  end if
End Function


Function onDisplayAnimationStopped()
  if m.animationDisplay.state = "stopped"
    m.animationDisplay.unobserveField("state")
    m.animationDisplay = invalid
  end if
End Function


Function onHideAnimationStopped()
  tubiLog("LinearVideoPlayerScreenOverlay.onHideAnimationStopped")
  if m.animationHide.state = "stopped"
    m.animationHide.unobserveField("state")
    m.animationHide = invalid
    resetUI(false)
  end if
End Function


Function onTimeContentChange()
  tubiLog("LinearVideoPlayerScreenOverlay.onTimeContentChanged")
  if m.top.updateTimeGridContent = true
    if m.top.timeGridContent <> invalid
      ' Clear then set to force ProgramGuide to re-render when content structure changes (e.g. favorites removed on sign out)
      m.EPG.content = invalid
      m.EPG.content = m.top.timeGridContent
      m.EPG.contentUpdated = true
      m.EPGError.visible = false
      jumpEPGToCurrentPlayingVideo()
    else
      '//display inline error message
      m.EPGError.visible = true
      hideOverlay()
    end if
  end if
End Function


Function onTimeGridContentLoadingChange()
  tubiLog("LinearVideoPlayerScreenOverlay.onTimeGridContentLoadingChange")
  if m.top.timeGridContentLoading = true
    '//indicate that the EPG is loading
    m.EPGSpinner.visible = true
    m.EPGError.visible = false
    m.InfoPanel.visible = false
    m.EPG.visible = false
    m.top.timeGridContent = invalid
    m.EPG.content = m.top.timeGridContent
  else
    m.EPGSpinner.visible = false
    m.EPG.visible = true
    if m.top.timeGridContent <> invalid
      m.InfoPanel.visible = true
    else
      m.InfoPanel.visible = false
    end if

  end if
End Function




' Update the EPG so the focused item is that of the playing video.
Function jumpEPGToCurrentPlayingVideo(shouldSendComponentInteractionEvent = false)
  tubiLog("LinearVideoPlayerScreenOverlay.jumpEPGToCurrentPlayingVideo")
  if m.top.currentLinearVideoContent <> invalid AND m.EPG.contentUpdated = true
    ' second element of the array is not used in case of EPG. So, hardcoded to empty string.

    m.EPG.trackingPageInfo = {
      pageType: "video_player_page"
      pageValues: { video_id: m.top.currentLinearVideoContent.id.toInt() }
    }
    if shouldSendComponentInteractionEvent = true
      m.EPG.shouldSendComponentInteractionEventOnJumpToLinearChannelId = true
    end if

    if m.top.getPArent().associatedScreenId = m.constants.ui.screenIds.homeScreen
      jumpToEPGCategory = ""
    else
      jumpToEPGCategory = m.top.currentLinearVideoContent.parentId
    end if

    m.EPG.jumpToLinearChannelID = [m.top.currentLinearVideoContent.id, jumpToEPGCategory]
  end if
End Function


' reset the overlay back to the original state
Function resetUI(bAnimated = true)
  tubiLog("LinearVideoPlayerScreenOverlay.resetUI")
  m.sideNav.setOpenState = "closed"
  if m.bEPGVisible = true
    if bAnimated = true
      slideTo(m.EPGHorizontalSlide, m.originalEPGTranslation, m.top.animationDuration)
    else
      m.EPGHorizontalSlide.translation = m.originalEPGTranslation
    end if
  else
    hideClosedCaptioningMenu(bAnimated)
    m.EPGHorizontalSlide.translation = m.originalEPGTranslation
  end if
End Function


Function displayClosedCaptioningMenu()
  m.closedCaptioningButtonList.setFocus(true)
  m.closedCaptioningButtonList.setFocus(false) ' workaround for roku focus indicator bug
  m.closedCaptioningButtonList.setFocus(true) ' workaround for roku focus indicator bug
  m.sideNav.setOpenState = "openedAndNotInFocus"

  if m.bEPGVisible = true
    m.bEPGVisible = false

    ' preselect the caption option that the user currently has enabled
    nJumpTo = 0
    if m.closedCaptioningButtonList.content <> invalid AND m.closedCaptioningButtonList.content.getChildCount() > 0
      captions = m.closedCaptioningButtonList.content.getChild(0)
      for i = 0 to captions.getChildCount() - 1
        caption = captions.getChild(i)
        if caption.enabled = true
          nJumpTo = i
        end if
      end for
      m.closedCaptioningButtonList.jumpToRowItem = [0, nJumpTo]
    end if

    slideFade(m.EPG, "below", "out", m.top.animationDuration)
    slideFade(m.closedCaptioningGroup, "below", "in", m.top.animationDuration)
  end if
End Function


Function hideClosedCaptioningMenu(bAnimated = true)
  m.bEPGVisible = true
  nAnimationDuration = 0
  if bAnimated = true
    nAnimationDuration = m.top.animationDuration
  end if

  slideFade(m.closedCaptioningGroup, "below", "out", m.top.animationDuration)
  slideFade(m.EPG, "below", "in", nAnimationDuration)
End Function


Function goBackToEPGFromSideNav()
  m.EPG.setFocus(true)
  resetUI()
End Function


Function onKeyEvent(key as String, press as Boolean) as Boolean
  bKeyReacted = false

  if m.top.isDisplaying = true AND press = true then
    tubiLog("LinearVideoPlayerScreenOverlay.onKeyEvent" + key)
    if key = "left"
      if m.EPG.isInFocusChain() = true
        '//if the EPG has focus, check if categories menu is visible first
        if m.epgCategoriesVariant <> "none" AND m.containerMarkupGrid <> invalid AND m.containerMarkupGrid.visible = true AND m.containerMarkupGrid.content <> invalid AND m.containerMarkupGrid.content.getChildCount() > 0
          ' Move focus to categories menu
          sendOverlayChannelToCategoryNavigateWithinPageEvent()
          m.containerMarkupGrid.setFocus(true)
          slideTo(m.EPGHorizontalSlide, m.originalEPGTranslation, m.top.animationDuration)
          m.sideNav.setOpenState = "openedAndNotInFocus"
          bKeyReacted = true
        else if m.sideNav.visible = true
          '//if categories is not visible, move focus to side nav
          slideTo(m.EPGHorizontalSlide, m.slideOutEPGTranslation, m.top.animationDuration)
          m.sideNav.setOpenState = "openedAndInFocus"
          m.sideNav.buttonToFocusID = m.constants.ui.linearSideNavIds.epg
          userInteraction = "TOGGLE_ON"
          setComponentInteractionForSideNavInVideoPlayerOverLay(userInteraction, m.sideNav.focusedButtonID)
          bKeyReacted = true
        end if
      else if m.epgCategoriesVariant <> "none" AND m.containerMarkupGrid <> invalid AND m.containerMarkupGrid.isInFocusChain() = true
        '//if the categories menu has focus, move focus to side nav
        if m.sideNav.visible = true
          slideTo(m.EPGHorizontalSlide, m.slideOutEPGTranslation, m.top.animationDuration)
          m.sideNav.setOpenState = "openedAndInFocus"
          m.sideNav.buttonToFocusID = m.constants.ui.linearSideNavIds.epg
          userInteraction = "TOGGLE_ON"
          setComponentInteractionForSideNavInVideoPlayerOverLay(userInteraction, m.sideNav.focusedButtonID)
          bKeyReacted = true
        end if
      else if m.closedCaptioningGroup.isInFocusChain() = true
        m.sideNav.setOpenState = "openedAndInFocus"
        m.sideNav.buttonToFocusID = m.constants.ui.linearSideNavIds.subtitles
        hideClosedCaptioningMenu() '//Hide the CC menu and display EPG again
        slideTo(m.EPGHorizontalSlide, m.slideOutEPGTranslation, m.top.animationDuration)
        bKeyReacted = true
      end if
    else if key = "right"
      if m.bEPGVisible = true AND m.EPG.isInFocusChain() = false
        ' Check if focus is on side nav or categories menu
        if m.epgCategoriesVariant <> "none" AND m.containerMarkupGrid <> invalid AND m.containerMarkupGrid.isInFocusChain() = true
          '//if the categories menu has focus, move focus to EPG
          sendOverlayCategoryToChannelNavigateWithinPageEvent()
          if m.EPG.channelGridFocusable = true
            m.EPG.isChannelGridFocused = true
          end if
          m.EPG.setFocus(true)
          slideTo(m.EPGHorizontalSlide, m.originalEPGTranslation, m.top.animationDuration)
          m.sideNav.setOpenState = "closed"
          userInteraction = "TOGGLE_OFF"
          setComponentInteractionForSideNavInVideoPlayerOverLay(userInteraction, m.sideNav.focusedButtonID)
          bKeyReacted = true
        else
          '//if the side nav has focus, move focus to categories menu (if visible) or EPG
          if m.epgCategoriesVariant <> "none" AND m.containerMarkupGrid <> invalid AND m.containerMarkupGrid.visible = true AND m.containerMarkupGrid.content <> invalid AND m.containerMarkupGrid.content.getChildCount() > 0
            m.containerMarkupGrid.setFocus(true)
            slideTo(m.EPGHorizontalSlide, m.originalEPGTranslation, m.top.animationDuration)
            m.sideNav.setOpenState = "closed"
            bKeyReacted = true
          else
            userInteraction = "TOGGLE_OFF"
            setComponentInteractionForSideNavInVideoPlayerOverLay(userInteraction, m.sideNav.focusedButtonID)
            goBackToEPGFromSideNav()
            bKeyReacted = true
          end if
        end if
      else if m.bEPGVisible = false AND m.closedCaptioningGroup.isInFocusChain() = false
        displayClosedCaptioningMenu()
        slideTo(m.EPGHorizontalSlide, m.slideOutEPGTranslation, m.top.animationDuration)
        bKeyReacted = true
      end if
    else if key = "back"
      if m.closedCaptioningGroup.isInFocusChain() = true
        m.sideNav.setOpenState = "openedAndInFocus"
        m.sideNav.buttonToFocusID = m.constants.ui.linearSideNavIds.subtitles
        hideClosedCaptioningMenu() '//Hide the CC menu and display EPG again
        bKeyReacted = true
      else if m.epgCategoriesVariant <> "none" AND m.containerMarkupGrid <> invalid AND m.containerMarkupGrid.isInFocusChain() = true
        '//if the categories menu has focus, move focus to EPG
        m.EPG.setFocus(true)
        slideTo(m.EPGHorizontalSlide, m.originalEPGTranslation, m.top.animationDuration)
        m.sideNav.setOpenState = "closed"
        bKeyReacted = true
      else if m.EPG.isInFocusChain() = false
        goBackToEPGFromSideNav()
      else
        hideOverlay()
      end if
      bKeyReacted = true
    end if
  end if

  if bKeyReacted = true
    m.top.reactedToKeyPresss = true
  end if

  return bKeyReacted
End Function


'@userInteraction: string, what type of userIntercation is performed: "Toggle_ON/Toggle_off"
'@sideNavItemId: string, what item is selected from the linearEPGSideNav in linearOverlay
Function setComponentInteractionForSideNavInVideoPlayerOverLay(userInteraction, sideNavItemId)
  componentValues = {}
  if sideNavItemId <> invalid
    componentValues = {
      left_nav_section: m.Tracking.linearSideNavPageMap[sideNavItemId]
    }
  end if
  pageValues = { video_id: m.top.currentLinearVideoContent.id.toInt() }

  componentInteractionInfo = {
    pageOneof: m.Tracking.getAnalyticsPage("video_player_page", pageValues)
    componentOneof: m.Tracking.getAnalyticsComponent("left_side_nav_component", componentValues)
    user_interaction: userInteraction
  }

  m.EPG.componentInteractionInfo = componentInteractionInfo
End Function
