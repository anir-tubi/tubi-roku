' Video Tile Helper Functions
' Contains all methods related to video tile functionality including:
' - Focus management
' - Metadata overlay handling
' - Video preview controls
' - Background updates
' - Container pagination


' Sets up all video tiles-related observers for a screen
' This is a reusable helper that should be called when initializing any video tiles-enabled screen
'
' @param screen roSGNode - The screen node to set up observers on
Function setupVideoTilesObservers(screen) as Void
  if screen <> invalid
    screen.observeFieldScoped("rowCurrFocusColumn", "onRowCurrFocusColumnChange")
    screen.observeFieldScoped("listCurrFocusRow", "onRowCurrFocusRowChange")
    screen.observeFieldScoped("listHasFocus", "onListHasFocusChange")
    screen.observeFieldScoped("listScrollDirection", "onListScrollDirectionChange")
    screen.observeFieldScoped("listScrollingStatus", "onListScrollingStatusChange")
    screen.observeFieldScoped("currentFocusedItemBoundingRect", "onRowListTranslationChange")
    screen.observeFieldScoped("rowListTranslation", "onRowListTranslationChange")
  end if
End Function


' Handles pagination response for video tile containers
' Appends additional content items to the currently focused row in the featured row list
'
' @param response roSGNode - Server response containing additional content items to append
Function onVideoTilesListMoreItemsSuccess(response) as Void
  homeScreen = getCurrentScreen()
  if homeScreen <> invalid AND homeScreen.content <> invalid AND isNode(response) = true AND homeScreen.listCurrFocusRow <> invalid
    appendContentToCategory(response, homeScreen.content)
  end if
End Function


' Updates the in-transit video metadata overlay during scrolling
' Determines the focused item and updates the tile overlay accordingly
' Called when user scrolls vertically through rows
Function updateInTransitVideoMetadataOverlay() as Void
  screen = getCurrentScreen()
  if screen = invalid OR isNode(screen.content) = false
    return
  end if

  currFocusRow = screen.listCurrFocusRow
  category = screen.content.getChild(currFocusRow)
  columnFocused = getValidatedColumnIndex(screen, category)

  updateVideoTileOnFocusChange(currFocusRow, columnFocused, screen)
End Function


' Gets a validated column index from screen or category focus
' Returns 0 if invalid or negative values are found
'
' @param screen roSGNode - The current screen node
' @param category roSGNode - The category node (can be invalid)
' @return integer - Validated column index (minimum 0)
Function getValidatedColumnIndex(screen, category) as Integer
  columnFocused = 0

  if screen.listScrollDirection = "left" OR screen.listScrollDirection = "right"
    columnFocused = Cint(screen.rowCurrFocusColumn)
  else
    if category <> invalid AND isNumber(category.focusIndex) = true AND category.focusIndex > 0
      columnFocused = category.focusIndex
    end if
  end if

  return columnFocused
End Function


' Handles horizontal scrolling through video tile columns
' Updates metadata overlay, triggers lazy loading, and tracks performance metrics
' Called when user navigates left/right through items in a row
Function onRowCurrFocusColumnChange() as Void
  tubiLog("VideoTileHelper.onRowCurrFocusColumnChange")

  ' Reset animation states and stop timers
  m.inlineVideoMetadataOverlay.skipAnimation = false
  m.videoPreviewDebounce.control = "stop"
  fade(m.autoStartPreviewToPlaybackTimer, "out", 0.3)
  stopCountdownTimer()

  screen = getCurrentScreen()
  if screen = invalid
    return
  end if

  m.performanceMetricsTracker.startMetricTiming("horizontal_scroll_performance")

  ' Ensure valid column index
  columnFocused = screen.rowCurrFocusColumn
  if isNumber(columnFocused) = false OR columnFocused < 0
    columnFocused = 0
  end if

  rowFocused = screen.listCurrFocusRow
  updateVideoTileOnFocusChange(rowFocused, columnFocused, screen)

  ' Trigger lazy loading for next batch of items
  if isNumber(columnFocused) = true AND isNumber(rowFocused) = true AND screen.content <> invalid AND screen.isSubType("HomeScreen") = true
    category = screen.content.getChild(rowFocused)
    makeContainerRequest(category, columnFocused, screen, onVideoTilesListMoreItemsSuccess)
  end if

  ' End performance tracking when scroll completes
  if columnFocused = Fix(columnFocused)
    m.performanceMetricsTracker.endMetricTiming("horizontal_scroll_performance", { column: columnFocused, row: rowFocused, screen: screen.id })
  end if
End Function


' Updates video tile metadata overlay when focus changes
' Coordinates background updates, video preview state, and metadata display
' Main orchestrator for video tile focus behavior
'
' @param rowFocused integer - Row index of the focused item
' @param columnFocused integer - Column index of the focused item
' @param screen roSGNode - The screen node containing the featured row content
Function updateVideoTileOnFocusChange(rowFocused, columnFocused, screen) as Void
  isVideoTileEnabled = isVideoTileEnabledScreen()
  ' Only process if the user is a screen or mode where video tiles are enabled.
  if isVideoTileEnabled = false return
  ' Extract focused content information
  gridItemType = ""
  contentFocused = invalid
  if screen.content <> invalid AND rowFocused <> invalid
    category = screen.content.getChild(rowFocused)
    if category <> invalid
      gridItemType = category.gridItemType
      contentFocused = category.getChild(columnFocused)
    end if
  end if

  if gridItemType = m.constants.ui.gridItemTypes.skinAd return

  ' Update background only on home screen
  if isVideoTileEnabledScreen() = true
    updateVideoTileScreenBackground(contentFocused, screen)
  end if

  ' Handle video preview and metadata overlay
  if screen <> invalid AND screen.content <> invalid
    isVideoTileEnabled = contentFocused <> invalid AND isVideoTileEnabledContainer(gridItemType)
    if isVideoTileEnabled = true
      pauseVideoPreviewAndShowPoster()
    else
      pauseVideoPreview()
    end if
    setInlineVideoMetadataOverlay(screen.content, columnFocused, rowFocused)
  end if
End Function


' Pauses video preview and displays poster for smoother scrolling
' Hides video player, fades out preview, and manages linear player state
' Improves scrolling performance by reducing video processing during navigation
Function pauseVideoPreviewAndShowPoster() as Void
  tubiLog("VideoTileHelper.pauseVideoPreviewAndShowPoster")

  ' Fade out and pause video preview if visible
  if m.inlineVideoPreviewPlayerContainer.opacity = 1
    videoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
    if videoPlayer <> invalid
      videoPlayer.visible = false
    end if

    m.inlinePreviewPlayerFadeAnimation = fade(m.videoPreviewPlayer, "out", 0.3)

    if getVideoPreviewState() = "playing"
      pauseVideoPreview()
    end if
  end if

  ' Handle linear player state
  screen = getCurrentScreen()
  isLinearPlayerPlaying = isLinearPlayerLoadingOrPlaying()

  if screen <> invalid AND screen.contentFocused <> invalid
    updatePlayerLayoutBasedOnFocusedContent(screen.contentFocused)
  end if

  if isLinearPlayerPlaying = true
    stopAndHideLinearVideoPlayer()
  end if

  ' Control visibility during vertical scrolling
  isVerticalScroll = screen.listScrollDirection = "up" OR screen.listScrollDirection = "down"
  if isVerticalScroll = true
    m.inlineVideoPreviewPlayerContainer.opacity = 0
  else
    m.inlineVideoPreviewPlayerContainer.opacity = 1
  end if
End Function


' Starts debounced video preview for focused video tile
' Handles both regular content and linear content with autoplay
' Triggered after debounce delay to avoid excessive preview starts
Function startDebouncedVideoPreview() as Void
  m.queuedVideoTilePreview = false
  screen = getCurrentScreen()

  if isVideoTileEnabledScreen() = false
    return
  end if

  if screen.listHasFocus = true
    handleListVideoPreview(screen)
  else
    handleNonListVideoPreview(screen)
  end if
End Function


' Handles video preview when featured row list has focus
' Manages countdown timer and linear player state
'
' @param screen roSGNode - The current screen node
Function handleListVideoPreview(screen) as Void
  stopCountdownTimer()

  if isLinearPlayerLoadingOrPlaying() = true
    stopAndHideLinearVideoPlayer()
  end if

  if screen.content = invalid OR screen.contentFocused = invalid
    return
  end if

  content = screen.contentFocused
  state = getVideoPreviewState()

  ' Only start preview if content changed or not playing
  if getVideoPreviewContentId() <> content.id OR state = "stopped"
    if content.type = m.constants.ui.categoryTypes.linear AND m.constants.deviceInfo.isAutoPlayEnabled = true
      playLinearInlineGridView(content, screen)
    else
      componentTrackingInfo = getCategoryComponentTrackingInfo(screen)
      setVideoPreviewAfterFocus(content, screen.trackingPageInfo, componentTrackingInfo)
    end if
  end if
End Function


' Handles video preview for ad content when featured list doesn't have focus
' Only processes carousel and spotlight ad types
'
' @param screen roSGNode - The current screen node
Function handleNonListVideoPreview(screen) as Void
  focusedContent = screen.contentFocused
  if focusedContent = invalid
    return
  end if

  isAdContent = focusedContent.type = m.constants.ui.contentTypes.adRowlistCarousel OR focusedContent.type = m.constants.ui.contentTypes.adRowlistSpotlight
  if isAdContent = true
    componentTrackingInfo = getCategoryComponentTrackingInfo(screen)
    setVideoPreviewAfterFocus(focusedContent, screen.trackingPageInfo, componentTrackingInfo)
  end if
End Function


' Sets inline video metadata overlay for current and next predicted row
' Updates overlay content, logo, and visibility based on scroll direction
' Includes predictive loading for smoother vertical scrolling experience
'
' @param content roSGNode - The row content node containing all categories
' @param columnFocused integer - Column index of focused item
' @param rowFocused integer - Row index of focused item
Function setInlineVideoMetadataOverlay(content, columnFocused, rowFocused) as Void
  ' Validate and normalize indices
  columnFocused = normalizeIndex(columnFocused)
  rowFocused = normalizeIndex(rowFocused)

  ' Update current row metadata
  updateCurrentRowMetadata(content, columnFocused, rowFocused)

  ' Update predicted next row metadata (for smoother scrolling)
  screen = getCurrentScreen()
  isHorizontalScroll = screen.listScrollDirection = "left" OR screen.listScrollDirection = "right"

  if isHorizontalScroll = false
    updatePredictedRowMetadata(content, rowFocused, screen)
  end if
End Function


' Normalizes an index to ensure it's a valid positive integer
'
' @param index dynamic - Index value to normalize
' @return integer - Normalized index (minimum 0)
Function normalizeIndex(index) as Integer
  if isNumber(index) = false OR index < 0
    return 0
  end if
  return CInt(index)
End Function


' Updates metadata overlay for currently focused item
'
' @param content roSGNode - Row content
' @param columnFocused integer - Column index
' @param rowFocused integer - Row index
Function updateCurrentRowMetadata(content, columnFocused, rowFocused) as Void
  currCategory = content.getChild(rowFocused)
  if currCategory = invalid
    return
  end if

  itemContent = currCategory.getChild(columnFocused)
  if itemContent <> invalid
    m.inlineVideoMetadataOverlay.itemContent = itemContent
    m.inlineVideoGridTitleLogo.itemContent = itemContent
  end if

  m.inlineVideoMetadataOverlay.visible = true
  m.inlineVideoGridTitleLogo.visible = true
End Function


' Updates in-transit metadata overlay for predicted next row
' Provides smoother scrolling by pre-loading next row's metadata
'
' @param content roSGNode - Row content
' @param rowFocused integer - Current row index
' @param screen roSGNode - Current screen node
Function updatePredictedRowMetadata(content, rowFocused, screen) as Void
  ' Determine next row based on scroll direction
  nextRow = 1
  if screen.listScrollDirection = "down"
    nextRow = rowFocused + 1
  else if rowFocused > 0 AND screen.listScrollDirection = "up"
    nextRow = rowFocused - 1
  end if

  nextCategory = content.getChild(nextRow)
  if nextCategory = invalid
    return
  end if

  ' Get column index from category's preserved focus
  columnFocused = normalizeIndex(nextCategory.focusIndex)

  ' Show in-transit overlay only for video tile enabled containers
  isVideoTileEnabled = isVideoTileEnabledContainer(nextCategory.gridItemType)
  m.inTransitInlineVideoMetadataOverlay.visible = (isVideoTileEnabled = true)

  if isVideoTileEnabled = true
    inTransitItemContent = nextCategory.getChild(columnFocused)
    m.inTransitInlineVideoMetadataOverlay.itemContent = inTransitItemContent
  end if
End Function


' Plays linear content in inline grid view
' Sets up playback source and starts linear video playback
'
' @param content roSGNode - The linear content to play
' @param screen roSGNode - The screen node (parameter unused but kept for signature consistency)
Function playLinearInlineGridView(content, screen) as Void
  screen = getCurrentScreen()

  if isVideoTileEnabledScreen() = false
    return
  end if

  stopLinearVideoContent()
  playbackSource = {
    "srcForAnalytic": m.constants.player.playbackSource.unknown
    "srcForAds": m.constants.player.playbackOrigin.container
    "playbackContainer": screen.currCategoryId
  }
  playLinearVideoContent(content, true, screen.id, true, playbackSource)
End Function


' Controls visibility of video tile overlay group based on screen state
' Manages experiment flags, kids mode, and fade animations
'
' @param duration integer - Fade animation duration in seconds (default: 0)
Function updateInlineVideoMetadataOverlayVisibility(duration = 0) as Void
  tubiLog("VideoTileHelper.updateInlineVideoMetadataOverlayVisibility")
  screen = getCurrentScreen()

  if screen = invalid
    return
  end if

  isVideoTileEnabled = isVideoTileEnabledScreen() AND screen.content <> invalid
  m.videoTileOverlayGroup.visible = isVideoTileEnabled

  ' Handle video tiles experiment visibility
  if isVideoTileEnabled = true AND screen.content <> invalid
    handleHomeScreenOverlayVisibility(screen)
  else
    handleNonHomeScreenOverlayVisibility(screen, duration)
  end if

  ' Hide auto-start timer when video tiles are not enabled
  if isVideoTileEnabled = false
    fade(m.autoStartPreviewToPlaybackTimer, "out", 0.3)
  end if
End Function


' Handles overlay visibility when on home screen
'
' @param screen roSGNode - Current screen node
Function handleHomeScreenOverlayVisibility(screen) as Void
  content = screen.contentFocused
  if getVideoPreviewStateForThisContent(content) <> "playing"
    m.inlineVideoMetadataOverlay.showContentPoster = true
  end if
End Function


' Handles overlay visibility when not on home screen
'
' @param screen roSGNode - Current screen node
' @param duration integer - Fade duration
Function handleNonHomeScreenOverlayVisibility(screen, duration) as Void
  ' Show/hide large preview poster based on skin ad focus
  if screen <> invalid AND screen.lastFocusedList <> "skinAdRow"
    fade(m.inlineVideoPreviewPlayerContainer, "out", duration, 0.1)
  else
    fade(m.inlineVideoPreviewPlayerContainer, "in", duration)
  end if
End Function


' Updates video tile translation position during scroll
' Synchronizes overlay position with featured row list translation
' Prevents flickering by managing opacity during scroll transitions
'
' @param msg roSGNode - Message object containing screen and translation data
Function onRowListTranslationChange(msg) as Void
  tubiLog("VideoTileHelper.onRowListTranslationChange")
  screen = msg.getRoSGNode()
  translation = screen.rowListTranslation

  if translation = invalid
    return
  end if

  ' NOTE: Magic number 52 is the default Y offset for the focused item bounding rect
  rectY = getValidRectY(screen, 52)
  isVerticalScroll = arrayIncludes(["down", "up"], screen.listScrollDirection)

  ' Update main inline video preview container position
  updateInlineVideoPreviewPosition(screen, translation, rectY, isVerticalScroll)

  ' Update in-transit metadata overlay position (vertical scroll only)
  if isVerticalScroll = true
    updateInTransitOverlayPosition(screen, translation)
  end if
End Function


' Gets valid rect Y position from screen's bounding rect
'
' @param screen roSGNode - Current screen node
' @param defaultValue integer - Default Y value if bounding rect is invalid
' @return integer - Valid rect Y position
Function getValidRectY(screen, defaultValue as Integer) as Integer
  if isNonEmptyAA(screen.currentFocusedItemBoundingRect) AND screen.currentFocusedItemBoundingRect.y <> 0
    return screen.currentFocusedItemBoundingRect.y
  end if
  return defaultValue
End Function


' Updates inline video preview container position during scroll
'
' @param screen roSGNode - Current screen node
' @param translation array - Translation coordinates [x, y]
' @param rectY integer - Y position from bounding rect
' @param isVerticalScroll boolean - Whether scrolling vertically
Function updateInlineVideoPreviewPosition(screen, translation, rectY, isVerticalScroll) as Void
  if isNumber(rectY) = false
    return
  end if

  inlineVideoPreviewPlayerContainer = m.inlineVideoPreviewPlayerContainer.translation

  ' Prevent flickering when vertical scroll stops
  if isVerticalScroll = true AND screen.listScrollingStatus = false
    m.inlineVideoPreviewPlayerContainer.opacity = 0
  end if

  m.inlineVideoPreviewPlayerContainer.translation = [inlineVideoPreviewPlayerContainer[0], translation[1] + rectY]
  m.inlineVideoPreviewPlayerContainer.opacity = 1
End Function


' Updates in-transit overlay position during vertical scroll
'
' @param screen roSGNode - Current screen node
' @param translation array - Translation coordinates [x, y]
Function updateInTransitOverlayPosition(screen, translation) as Void
  inTransitRect = screen.inTransitCurrentFocusedItemBoundingRect

  if inTransitRect = invalid
    return
  end if

  ' Handle zero Y position case
  if inTransitRect.y = 0
    if screen.listScrollingStatus = false
      m.inTransitInlineVideoMetadataOverlay.opacity = 0
    end if
    return
  end if

  ' NOTE: Magic numbers - 5 is Y offset, 165 is X position for in-transit overlay
  currentY = m.inTransitInlineVideoMetadataOverlay.translation[1]
  newY = translation[1] + inTransitRect.y + 5

  ' Show overlay during active scrolling, hide when stopped
  if screen.listScrollingStatus = true AND isNumber(inTransitRect.y) AND currentY <> newY
    m.inTransitInlineVideoMetadataOverlay.translation = [165, newY]
    m.inTransitInlineVideoMetadataOverlay.opacity = 1
  else
    m.inTransitInlineVideoMetadataOverlay.opacity = 0
  end if
End Function


' Checks if a container type supports video tiles
' Returns false for non-video-tile grid item types
'
' @param gridItemType string - The grid item type to check
' @return boolean - True if video tiles are enabled for this container
Function isVideoTileEnabledContainer(gridItemType) as Boolean
  return gridItemType = m.constants.ui.gridItemTypes.videoTile
End Function


' Determines if video tiles should be enabled for the current screen
' @return Boolean - true if video tiles should be enabled, false otherwise
Function isVideoTileEnabledScreen(screenId = "" as String) as Boolean
  ' If no screenId provided, get from current screen
  if screenId = ""
    currentScreen = getCurrentScreen()
    if currentScreen = invalid then return false
    screenId = currentScreen.id
  end if

  isInKidsMode = isKidsUIOn()

  ' Always enable video tiles on homeScreen in standard mode (not kids mode)
  if screenId = m.constants.ui.screenIds.homeScreen AND isInKidsMode = false
    return true
  end if

  ' For all eligible screens (home, tv, movies, espanol, my stuff), enable based on experiment
  ' Note: This includes homeScreen in kids mode
  if m.constants.ui.videoTilesEligibleScreenIds[screenId] = true
    return m.isUserInVideoTilesExperiment
  end if

  return false
End Function


' Updates screen background based on focused video tile content
' Shows full screen background for live events or ad content
' Falls back to default background for home screen
'
' @param content roSGNode - The focused content node
' @param screen roSGNode - The screen node
Function updateVideoTileScreenBackground(content, screen) as Void
  isVideoTileEnabled = isVideoTileEnabledScreen()
  shouldShowVideoBackground = isNode(content) = true AND (shouldDisplayFullScreenVideoBackground(content) OR arrayIncludes(m.constants.ui.adGridItemTypes, content.gridItemType) OR isVideoTileEnabled = false)

  if shouldShowVideoBackground = true
    setVideoContentScreenBackground(screen, content)
  else if isVideoTileEnabled = true
    displayDefaultBackground()
  end if
End Function


' Updates dimensions of video tile overlays and focus indicators
' Retrieves size from experiment config or falls back to constants
' Applies consistent padding to all overlay elements
'
' @param scrollingStatus boolean - Indicates if list is currently scrolling (unused but kept for signature)
Function updateVideoTileSize(scrollingStatus = false) as Void
  m.inlineVideoGridTitleLogo = m.top.findNode("inlineVideoGridTitleLogo")
  featuredRowPoster = m.constants.ui.imageSizes.featuredRowPoster

  ' NOTE: Magic numbers - 4 is padding for focus indicator, 12 is additional padding for outer focus ring
  focusIndicatorPadding = 4
  focusRingPadding = 12

  width = featuredRowPoster[0] + focusIndicatorPadding
  height = featuredRowPoster[1] + focusIndicatorPadding

  ' Apply dimensions to all overlay elements
  m.inlineVideoMetadataOverlay.width = width
  m.inlineVideoMetadataOverlay.height = height
  m.inlineVideoGridTitleLogo.width = width
  m.inlineVideoGridTitleLogo.height = height
  m.inTransitInlineVideoMetadataOverlay.width = width
  m.inTransitInlineVideoMetadataOverlay.height = height

  ' Focus indicator needs extra padding
  m.inlinePreviewFocusIndicator.width = width + focusRingPadding
  m.inlinePreviewFocusIndicator.height = height + focusRingPadding
End Function
