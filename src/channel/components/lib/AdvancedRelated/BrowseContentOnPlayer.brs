Function init()
  m.constants = getConstantsFromGlobal()
  m.tracking = TubiTrackingInfo(m.constants)
  m._ = rodash()
  m.info = m.top.findNode("Info")
  m.browseWhileWatchingGroup = m.top.findNode("BrowseWhileWatchingGroup")
  m.browseWhileWatchingRow = m.top.findNode("BrowseWhileWatchingRow")

  m.categoryGridList = m.top.findNode("CategoryGridList")
  m.categoryGridList.observeFieldScoped("itemSelected", "onGridItemSelected")
  m.categoryGridList.observeFieldScoped("itemFocused", "onGridFocusChange")

  m.top.observeFieldScoped("updateContent", "onContentChange")
  m.top.observeFieldScoped("focusedChild", "onComponentFocus")
  m.top.observeFieldScoped("showInfoPanel", "onShowInfoPanel")
  m.top.observeFieldScoped("show", "onShowRelated")
  m.top.observeFieldScoped("hide", "onHideRelated")
  m.top.observeFieldScoped("open", "onOpenRelated")
  m.top.observeFieldScoped("close", "onCloseRelated")
  m.top.observeFieldScoped("showInFullScreen", "onShowRelatedInFullScreen")

  m.browseWhileWatchingGroupShowAnimation = invalid

  m.browseWhileWatchingXYPositionWhenHidden = [0,0]
  m.browseWhileWatchingXYPositionWhenOpen = [0,-432]

  ' Used to determine if navigate_within_page events should be sent. Only send when the Related content row already
  ' has focus, not when it gains focus.
  m.isRelatedFocused = false
  m.signedIn = isLoggedInUser() ' Initial value
End Function


Function onComponentFocus()
  if m.top.hasFocus()
    m.signedIn = isLoggedInUser() 'everytime the component gets focus, check if user is signed in
    m.categoryGridList.setFocus(true)
    m.categoryGridList.jumpToRowItem = [0,0]
    if m.info.opacity = 0
      fade(m.info, "in", 0.4)
    end if
  else if m.top.isInFocusChain() <> true
    m.isRelatedFocused = false
    m.categoryGridList.setFocus(false)
  end if
End Function


Function onContentChange()
  content = m.top.content

  if content <> invalid
    m.categoryGridList.content = content
    m.categoryGridList.contentUpdated = true
  end if
End Function


Function updateInfoPanel(infoNode, content)
  infoNode.title = content.title

  lineOneData = {}
  if content.type = m.constants.ui.contentTypes.series
    lineOneData.type = m.constants.ui.contentTypes.series
  end if
  lineOneData.releaseDate = content.releaseDate
  lineOneData.length = content.length
  lineOneData.hasCC = (content.hasSubtitles = true OR m._.empty(content.subtitleTracks) = false)
  lineOneData.hasAudioDescription = content.hasAudioDescription

  lineOneData.has4k = (content.resolution = "2160")

  if content.availabilityEnds <> invalid
    lineOneData.availabilityEnds = content.availabilityEnds
  end if

  lineOneData.descriptorCode = content.descriptorCode
  lineOneData.rating = content.rating
  lineOneData.partnerLogoUri = content.inlineLogoUri

  lineTwoData = {
    genres: content.genres
  }

  infoNode.lineOneData = lineOneData
  infoNode.lineTwoData = lineTwoData
  infoNode.description = content.description

  if content.needsLogin = true AND m.signedIn = false 'do not use isSignedInUser() here, it uses m.global and not ideal to access m.global for each item focus
    infoNode.loginReason = content.loginReason
    infoNode.needsLogin = true
  else
    infoNode.needsLogin = false
  end if

  ' always have to do this
  infoNode.calculateHeight = true

End Function


Function showInfoPanel()
  if m.info.opacity = 0
    fade(m.info, "in", 0.4)
  end if
End Function


Function hideInfoPanel()
  if m.info.opacity > 0
    fade(m.info, "out", 0.2)
  end if
End Function


Function onShowRelated()
  'This is required when during app foreground
  if m.categoryGridList.content <> invalid
    m.categoryGridList.contentUpdated = true
  end if

  if m.browseWhileWatchingGroup.opacity < 1.0
    m.browseWhileWatchingGroupShowAnimation = slideFade(m.browseWhileWatchingGroup, "below", "in", 0.6)
  end if
End Function


Function onHideRelated(msg)
  ' we need to stop browseWhileWatchingGroupShowAnimation which shows browseWhileWatchingGroup, because browseWhileWatchingGroupShowAnimation duration is set as 0.6 and
  ' browseWhileWatchingGroup may reappear even after we hide browseWhileWatchingGroup as the animation state is still be running
  if m.browseWhileWatchingGroupShowAnimation <> invalid AND m.browseWhileWatchingGroupShowAnimation.state = "running"
    m.browseWhileWatchingGroupShowAnimation.control = "stop"
  end if

  if m.browseWhileWatchingGroup.opacity > 0
    hideInfoPanel()
    fade(m.browseWhileWatchingRow, "out", 0.2, 0, 0.2)
    slideFade(m.browseWhileWatchingGroup, "below", "out", 0.6)
  end if
End Function


Function onOpenRelated()
  if m.browseWhileWatchingRow.opacity < 1.0
    fade(m.browseWhileWatchingRow, "in", 0.2, 0, 1.0)
  end if

  showInfoPanel()
  slideTo(m.browseWhileWatchingGroup, m.browseWhileWatchingXYPositionWhenOpen, 0.6)
End Function


Function onCloseRelated()
  if m.browseWhileWatchingRow.opacity = 1.0
    fade(m.browseWhileWatchingRow, "out", 0.2, 0, 0.2)
  end if

  hideInfoPanel()
  slideTo(m.browseWhileWatchingGroup, m.browseWhileWatchingXYPositionWhenHidden, 0.6)
End Function


Function onShowRelatedInFullScreen()
  m.browseWhileWatchingGroup.translation = m.browseWhileWatchingXYPositionWhenOpen
  fade(m.browseWhileWatchingGroup, "in", 0.6)
  fade(m.browseWhileWatchingRow, "in", 0.2, 0, 1.0)
  showInfoPanel()
End Function


'''''''''''''''''''''
' onGridFocusChange
'
' On grid focus change, update the info panel
Function onGridFocusChange() as void
  content = m.categoryGridList.itemFocused

  if content <> invalid
    updateInfoPanel(m.info, content)
    oldFocusedContent = m.categoryGridList.oldItemFocused

    'Set up the navigateWithinPageInfo to send to ContentController via VideoPlayerScreen. Need for when categoryGridList or topNav are in focus
    oldAnalyticsRow = m.categoryGridList.oldCursorPosition[0] + 1
    oldAnalyticsCol = m.categoryGridList.oldCursorPosition[1] + 1
    newAnalyticsRow = m.categoryGridList.cursorPosition[0] + 1
    newAnalyticsCol = m.categoryGridList.cursorPosition[1] + 1
    pageName = m.top.associatedPageName

    if m.isRelatedFocused = true AND oldAnalyticsRow > 0 AND oldAnalyticsCol > 0
      if oldAnalyticsRow <> newAnalyticsRow OR oldAnalyticsCol <> newAnalyticsCol

        categoryComponentInfo = {}
        categoryComponentInfo["category_slug"] = m.categoryGridList.oldCategoryId
        categoryComponentInfo["category_row"] = oldAnalyticsRow
        'row is hardcoded to 1 in the line below because the row represents the row within the category_component, not within the grid
        'and the current design only has one row per category
        tile = m.tracking.getAnalyticsTile(oldFocusedContent, oldAnalyticsCol, 1)
        categoryComponentInfo["content_tile"] = tile

        m.top.navigateWithinPageInfo = {
          pageOneof: m.tracking.getAnalyticsPage(pageName, {video_id: content.id.toInt()})
          componentOneof: m.tracking.getAnalyticsComponent("category_component", categoryComponentInfo)
          means_of_navigation: "BUTTON" 'MeansOfNavigation enum
          vertical_location: newAnalyticsRow
          horizontal_location: newAnalyticsCol
        }
      end if
    end if

    m.isRelatedFocused = true
    ' this field helps to update last key press time & pauseAd timer
    m.top.isRelatedContentFocused = true
  end if

End Function


Function onGridItemSelected() as void
  if m.categoryGridList <> invalid
    selectedItem = m.categoryGridList.itemSelected
    handleItemSelected(selectedItem, m.top.selectedPosition)
  end if
End Function


' @item: roSGNode, TubiContentNode with metadata for an item in the grid
' @position: array, 2d array with [x,y] grid coordinate information
Function handleItemSelected(item, position)
  m.top.trackingComponentInfo = getTrackingComponentInfoOfCategoryGridList(item, position)

  if item <> invalid then
    m.top.selectedRelatedContentItem = item
    m.top.selectedRelatedContentItemUpdated = true
  end if
End Function


' @gridItem: roSGNode, TubiContentNode with metadata for an item in the grid
' @itemPosition: array, 2d array with [x,y] grid coordinate information
Function getTrackingComponentInfoOfCategoryGridList(gridItem, itemPosition)
  trackingComponentInfo = {}
  if gridItem <> invalid AND itemPosition <> invalid AND itemPosition.Count() = 2
    componentValues = {}
    componentValues["category_slug"] = m.top.currCategoryId
    componentValues["category_row"] = itemPosition[0] + 1 'all analytics are 1 based
    tile = m.tracking.getAnalyticsTile(gridItem, itemPosition[1] + 1)
    componentValues["content_tile"] = tile

    ' Set the tracking component of the gridItem that was passed so it can be accessed as part of the navigateToPage event
    trackingComponentInfo = {
      componentType: "category_component"
      componentValues: componentValues
    }
  end if

  return trackingComponentInfo
End Function
