' RelatedLandscape - Landscape BWW row for video player
' Shows "You Might Also Like" row with landscape poster items


Function init() as Void
  m.constants = getConstantsFromGlobal()
  m.Tracking = TubiTrackingInfo(m.constants)
  m._ = rodash()
  topRef = m.top

  m.landscapeRowGroup = topRef.findNode("landscapeRowGroup")
  m.landscapeRow = topRef.findNode("landscapeRow")
  m.rowTitle = topRef.findNode("rowTitle")
  m.landscapeGrid = topRef.findNode("landscapeGrid")

  m.rowTitle.text = getTranslation("screenDetails_relatedTitles")

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.rowTitle, typographyConstants.ids.subheaderMedium)

  topRef.observeFieldScoped("content", "onContentChange")
  topRef.observeFieldScoped("updateContent", "onContentChange")
  topRef.observeFieldScoped("focusedChild", "onComponentFocus")
  topRef.observeFieldScoped("show", "onShowRelated")
  topRef.observeFieldScoped("hide", "onHideRelated")
  topRef.observeFieldScoped("open", "onOpenRelated")
  topRef.observeFieldScoped("close", "onCloseRelated")
  topRef.observeFieldScoped("showInFullScreen", "onShowRelatedInFullScreen")
  topRef.observeFieldScoped("jumpToItem", "onJumpToItem")

  m.landscapeGrid.observeFieldScoped("itemSelected", "onItemSelected")
  m.landscapeGrid.observeFieldScoped("itemFocused", "onItemFocused")
  m.landscapeGrid.observeFieldScoped("focusedChild", "onGridFocusChange")

  m.global.observeFieldScoped("theme", "onThemeChange")
  onThemeChange()

  m.rowShowAnimation = invalid
  m.previousFocusedContent = invalid
  m.isRelatedFocused = false
  m.gridHasFocus = false

  ' Positions for show/hide animations
  m.rowXYPositionWhenHidden = [0, 0]
  m.rowXYPositionWhenOpen = [0, -536]
End Function


Function onThemeChange(msg = invalid) as Void
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.rowTitle.color = theme.primaryTextColor
  end if
End Function


Function onComponentFocus() as Void
  if m.top.hasFocus()
    m.landscapeGrid.setFocus(true)
  else if m.top.isInFocusChain() <> true
    m.isRelatedFocused = false
  end if
End Function


' Tracks when the grid gains or loses focus
Function onGridFocusChange() as Void
  gridHasFocus = m.landscapeGrid.hasFocus() OR m.landscapeGrid.isInFocusChain()
  if m.gridHasFocus <> gridHasFocus
    m.gridHasFocus = gridHasFocus
    m.landscapeGrid.update({ gridHasFocus: gridHasFocus }, true)
  end if
End Function


Function onContentChange() as Void
  content = m.top.content
  if content <> invalid AND content.getChildCount() > 0
    m.landscapeGrid.content = content
    m.landscapeGrid.numColumns = content.getChildCount()
    m.landscapeGrid.visible = true
  end if
End Function


Function onJumpToItem() as Void
  jumpIndex = m.top.jumpToItem
  if jumpIndex <> invalid AND jumpIndex >= 0
    m.landscapeGrid.jumpToItem = jumpIndex
  end if
End Function


Function onItemSelected() as Void
  if m.landscapeGrid.content <> invalid
    itemIndex = m.landscapeGrid.itemSelected
    if itemIndex >= 0
      selectedItem = m.landscapeGrid.content.getChild(itemIndex)
      if selectedItem <> invalid
        m.top.selectedRelatedContentItem = selectedItem
      end if
    end if
  end if
End Function


Function onItemFocused() as Void
  if m.landscapeGrid.content <> invalid
    itemFocused = m.landscapeGrid.itemFocused
    focusedContent = m.landscapeGrid.content.getChild(itemFocused)
    if focusedContent = invalid then return

    col = itemFocused + 1
    row = 1

    ' Send navigate within page tracking
    if m.previousFocusedContent <> invalid AND m.isRelatedFocused = true
      pageInfo = { pageType: m.top.associatedPageName, pageValues: {} }
      m.top.navigateWithinPageInfo = {
        pageOneof: m.Tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
        componentOneof: m.Tracking.getAnalyticsComponent("related_component", m.previousFocusedContent)
        means_of_navigation: "SCROLL"
        vertical_location: row
        horizontal_location: col
      }
    end if

    m.previousFocusedContent = {
      content_tile: m.Tracking.getAnalyticsTile(focusedContent, col, row)
    }

    m.top.trackingComponentInfo = {
      type: "related_component"
      values: m.previousFocusedContent
    }

    m.isRelatedFocused = true
    m.top.focusedContent = focusedContent
  end if
End Function


Function onShowRelated() as Void
  if m.landscapeRowGroup.opacity < 1.0
    m.rowShowAnimation = slideFade(m.landscapeRowGroup, "below", "in", 0.6)
  end if
End Function


Function onHideRelated() as Void
  ' Stop any running show animation
  if m.rowShowAnimation <> invalid AND m.rowShowAnimation.state = "running"
    m.rowShowAnimation.control = "stop"
  end if

  if m.landscapeRowGroup.opacity > 0
    fade(m.landscapeRow, "out", 0.2, 0, 0.2)
    slideFade(m.landscapeRowGroup, "below", "out", 0.6)
  end if
End Function


Function onOpenRelated() as Void
  if m.landscapeRow.opacity < 1.0
    fade(m.landscapeRow, "in", 0.2, 0, 1.0)
  end if
  slideTo(m.landscapeRowGroup, m.rowXYPositionWhenOpen, 0.6)
End Function


Function onCloseRelated() as Void
  if m.landscapeRow.opacity = 1.0
    fade(m.landscapeRow, "out", 0.2, 0, 0.2)
  end if
  slideTo(m.landscapeRowGroup, m.rowXYPositionWhenHidden, 0.6)
End Function


Function onShowRelatedInFullScreen() as Void
  m.landscapeRowGroup.translation = m.rowXYPositionWhenOpen
  fade(m.landscapeRowGroup, "in", 0.6)
  fade(m.landscapeRow, "in", 0.2, 0, 1.0)
End Function


Function onKeyEvent(key as String, press as Boolean) as Boolean
  ' When the row is focused and user presses fastforward or rewind,
  ' close the row and handle the key press in playback
  if key = "fastforward" OR key = "rewind"
    m.top.keyPress = key
    return true
  end if
  return false
End Function
