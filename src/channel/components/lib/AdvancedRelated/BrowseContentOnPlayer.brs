Function init()
  m.constants = getConstantsFromGlobal()
  m.tracking = TubiTrackingInfo(m.constants)
  m._ = rodash()
  m.info = m.top.findNode("Info")
  m.ymalGroup = m.top.findNode("YmalGroup")
  m.ymalRow = m.top.findNode("YmalRow")

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

  m.ymalGroupShowAnimation = invalid

  m.ymalXYPositionWhenHidden = [0,0]
  m.ymalXYPositionWhenOpen = [0,-432]

  ' Used to determine if navigate_within_page events should be sent. Only send when the Related content row already
  ' has focus, not when it gains focus.
  m.isRelatedFocused = false

  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.categoryGridList.focusBitmapBlendColor = theme.focusedColor
  end if
End Function


Function onComponentFocus()
  if m.top.hasFocus()
    m.categoryGridList.focusedPosition = [0,0]
    m.categoryGridList.setFocus(true)
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

  if content.highestRendition = m.constants.serverValues.tensorVideoRenditions.fourK
    lineOneData.has4k = true
  end if

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
  infoNode.directors = content.directors
  infoNode.starring = content.actors
  infoNode.needsLogin = (content.needsLogin = true)

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

  if m.ymalGroup.opacity < 1.0
    m.ymalGroupShowAnimation = slideFade(m.ymalGroup, "below", "in", 0.6)
  end if
End Function


Function onHideRelated(msg)
  ' we need to stop ymalGroupShowAnimation which shows YmalGroup, because ymalGroupShowAnimation duration is set as 0.6 and
  ' ymalGroup may reappear even after we hide ymalGroup as the animation state is still be running
  if m.ymalGroupShowAnimation <> invalid AND m.ymalGroupShowAnimation.state = "running"
    m.ymalGroupShowAnimation.control = "stop"
  end if

  if m.ymalGroup.opacity > 0
    hideInfoPanel()
    fade(m.ymalRow, "out", 0.2, 0, 0.2)
    slideFade(m.ymalGroup, "below", "out", 0.6)
  end if
End Function


Function onOpenRelated()
  if m.ymalRow.opacity < 1.0
    fade(m.ymalRow, "in", 0.2, 0, 1.0)
  end if

  showInfoPanel()
  slideTo(m.ymalGroup, m.ymalXYPositionWhenOpen, 0.6)
End Function


Function onCloseRelated()
  if m.ymalRow.opacity = 1.0
    fade(m.ymalRow, "out", 0.2, 0, 0.2)
  end if

  hideInfoPanel()
  slideTo(m.ymalGroup, m.ymalXYPositionWhenHidden, 0.6)
End Function


Function onShowRelatedInFullScreen()
  m.ymalGroup.translation = m.ymalXYPositionWhenOpen
  fade(m.ymalGroup, "in", 0.6)
  fade(m.ymalRow, "in", 0.2, 0, 1.0)
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
