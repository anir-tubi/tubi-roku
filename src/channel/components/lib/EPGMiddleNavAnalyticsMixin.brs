' Shared EPG category pill / middle-nav analytics helpers for EPGHomeScreen and LinearVideoPlayerScreenOverlay.


' Maps a category container id to destination component values for middle-nav NavigateWithinPage events.
Function getMiddleNavDestinationValuesForContainerId(tracking, containerId as Dynamic) as Object
  destinationValues = {}
  if isNonEmptyString(containerId) = true
    containerToNavMap = tracking.getEPGContainerToNavSectionMap()
    if containerToNavMap <> invalid AND containerToNavMap[containerId] <> invalid
      destinationValues.middle_nav_section = containerToNavMap[containerId]
    end if
  end if

  return destinationValues
End Function


' Resolves category containerId from MarkupGrid focus coordinates.
' @param itemData - Row/col array, linear index, or invalid to use containerMarkupGrid.itemFocused
Function getCategoryContainerIdFromMarkupGrid(containerMarkupGrid, itemData = invalid) as Dynamic
  if containerMarkupGrid = invalid OR containerMarkupGrid.content = invalid
    return invalid
  end if

  coords = itemData
  if coords = invalid
    coords = containerMarkupGrid.itemFocused
  end if

  itemIndex = invalid
  if isNonEmptyArray(coords) = true AND coords.count() = 2
    itemIndex = coords[0] * containerMarkupGrid.numColumns + coords[1]
  else if isNumber(coords) = true AND coords >= 0
    itemIndex = coords
  end if

  if itemIndex = invalid
    return invalid
  end if

  containerItem = containerMarkupGrid.content.getChild(itemIndex)
  if containerItem = invalid OR isNonEmptyString(containerItem.containerId) = false
    return invalid
  end if

  return containerItem.containerId
End Function


' Page context for middle_nav ComponentInteraction on the linear browse (EPG) screen.
Function getEPGScreenMiddleNavAnalyticsPageContext(topRef) as Object
  pageType = "linear_browse_page"
  pageValues = {}
  if topRef.trackingPageInfo <> invalid
    if isNonEmptyString(topRef.trackingPageInfo.pageType) = true
      pageType = topRef.trackingPageInfo.pageType
    end if
    if topRef.trackingPageInfo.pageValues <> invalid then pageValues = topRef.trackingPageInfo.pageValues
  end if

  return { pageType: pageType, pageValues: pageValues }
End Function


' Page context for middle_nav ComponentInteraction on the in-player EPG overlay (must match video_player_page navigate events).
Function getLinearVideoOverlayMiddleNavAnalyticsPageContext(topRef) as Object
  pageValues = {}
  if topRef.currentLinearVideoContent <> invalid AND topRef.currentLinearVideoContent.id <> invalid
    pageValues = { video_id: topRef.currentLinearVideoContent.id.toInt() }
  end if

  return { pageType: "video_player_page", pageValues: pageValues }
End Function


' Builds programGuidecomponentInteractionInfo payload for middle_nav_component analytics.
Function buildMiddleNavComponentInteractionInfo(tracking, containerId as Dynamic, userInteraction as String, pageType as String, pageValues as Object) as Dynamic
  if isNonEmptyString(containerId) = false
    return invalid
  end if

  middleNavSection = "UNKNOWN"
  containerToNavMap = tracking.getEPGContainerToNavSectionMap()
  if containerToNavMap <> invalid AND containerToNavMap[containerId] <> invalid
    middleNavSection = containerToNavMap[containerId]
  end if

  return {
    pageOneof: tracking.getAnalyticsPage(pageType, pageValues)
    componentOneof: tracking.getAnalyticsComponent("middle_nav_component", { middle_nav_section: middleNavSection })
    user_interaction: userInteraction
  }
End Function


' Sends middle_nav ComponentInteraction for EPG home; page comes from trackingPageInfo.
Function sendEPGScreenMiddleNavComponentInteractionForContainerId(topRef, tracking, containerId as Dynamic, userInteraction as String) as Void
  pageContext = getEPGScreenMiddleNavAnalyticsPageContext(topRef)
  info = buildMiddleNavComponentInteractionInfo(tracking, containerId, userInteraction, pageContext.pageType, pageContext.pageValues)
  if info <> invalid
    topRef.programGuidecomponentInteractionInfo = info
  end if
End Function


' Sends middle_nav ComponentInteraction for linear video overlay; page is video_player_page with current video id.
Function sendLinearVideoOverlayMiddleNavComponentInteractionForContainerId(topRef, tracking, containerId as Dynamic, userInteraction as String) as Void
  pageContext = getLinearVideoOverlayMiddleNavAnalyticsPageContext(topRef)
  info = buildMiddleNavComponentInteractionInfo(tracking, containerId, userInteraction, pageContext.pageType, pageContext.pageValues)
  if info <> invalid
    topRef.programGuidecomponentInteractionInfo = info
  end if
End Function
