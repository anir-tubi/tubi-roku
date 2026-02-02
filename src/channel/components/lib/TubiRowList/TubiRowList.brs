Function init()
  m.constants = getConstantsFromGlobal()
  m.tracking = TubiTracking(m.constants, TubiAuth(m.constants))
  m.nodeHelpers = TubiNodeHelpers()

  m.previouslyFocusedRowItemIndex = invalid

  m.top.observeFieldScoped("content", "onContentChanged")
  m.top.observeFieldScoped("contentSupplied", "onContentSuppliedChanged")

  m.top.observeFieldScoped("rowItemFocused", "onRowItemFocusedChanged")

  ' Hooking into existing row item selected event
  m.top.observeFieldScoped("rowItemSelected", "onRowItemSelectedChanged")

  m.top.itemComponentName = "StarterGridItem"
  m.top.rowTitleComponentName = "TubiRowListRowTitleComponent"

  m.currentlyFocusedRowContent = invalid

  m.top.focusBitmapUri = "pkg:/images/selectorRoundedCorners-$$RES$$.9.png"
  m.top.focusFootprintBitmapUri = "pkg:/images/selectorRoundedCorners-$$RES$$.9.png"
  m.top.focusFootprintBlendColor = "#00000000"
  m.top.rowFocusAnimationStyle = "fixedFocus"
  m.top.vertFocusAnimationStyle = "fixedFocus"

  m.global.observeFieldScoped("theme", "onThemeChange")
  onThemeChange()
End Function


Function onContentChanged(msg) as Void
  ' Verifying content is valid
  content = msg.getData()
  if content = invalid then
    return
  end if

  ' Need to iterate through each row and add a field to indicate if the row title is focused before we create the row title component
  for i = 0 to m.top.content.getChildCount() - 1
    rowContent = m.top.content.getChild(i)
    if rowContent.relatedTo <> invalid then
      rowContent.addField("isRowFocused", "boolean", true)
    end if
  end for
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.top.focusBitmapBlendColor = theme.focusedColor
  end if
End Function


Function onContentSuppliedChanged(msg)
  ' TODO : handle content supplied change
End Function


Function getRowContent(rowIndex)
  if m.top.content <> invalid then
    return m.top.content.getChild(rowIndex)
  end if

  return invalid
End Function

' Handles when the focused row item changes. Can be called by observer and by us directly.
Function onRowItemFocusedChanged(msg) as Void
  if msg <> invalid then
    rowItemFocused = msg.getData()
  else
    rowItemFocused = m.top.rowItemFocused
  end if

  if isNonEmptyArray(rowItemFocused) = false then
    return
  end if

  if m.previouslyFocusedRowItemIndex <> invalid then
    if rowItemFocused[0] = m.previouslyFocusedRowItemIndex[0] AND rowItemFocused[1] = m.previouslyFocusedRowItemIndex[1] then
      ' No change in focused item
      return
    end if
  end if

  trackingPageInfo = m.top.trackingPageInfo
  if trackingPageInfo = invalid OR trackingPageInfo.pageType = invalid then
    return
  end if

  rowContent = getRowContent(rowItemFocused[0])
  if rowContent = invalid then
    return
  end if

  if rowContent.isRowFocused = true then
    ' Row title is focused, don't send analytics for row item focus change. Further we need to unset trackingComponentInfo as we do not want to have a component if row was what was selected
    m.top.trackingComponentInfo = invalid
    return
  end if

  itemContent = rowContent.getChild(rowItemFocused[1])
  if itemContent = invalid then
    return
  end if

  analyticRow = rowItemFocused[0] + 1
  analyticCol = rowItemFocused[1] + 1

  componentValues = {
    "category_slug": rowContent.slug
    "category_row": analyticRow
    "content_tile": m.tracking.getAnalyticsTile(itemContent, analyticCol)
  }

  if m.previousAnalyticsComponentValues <> invalid then
    m.top.navigateWithinPageInfo = {
      "pageOneof": m.tracking.getAnalyticsPage(trackingPageInfo.pageType, trackingPageInfo.pageValues)
      "componentOneof": m.tracking.getAnalyticsComponent("category_component", m.previousAnalyticsComponentValues)
      "dest_componentOneof": m.tracking.getAnalyticsDestinationComponent("dest_category_component", componentValues)
      "means_of_navigation": "BUTTON"
      "vertical_location": analyticRow
      "horizontal_location": analyticCol
    }
  end if

  m.top.trackingComponentInfo = {
    "componentType": "category_component"
    "componentValues": componentValues
  }

  m.previousAnalyticsComponentValues = componentValues
  m.previouslyFocusedRowItemIndex = rowItemFocused
End Function


Function onRowItemSelectedChanged(msg)
  ' In the case row item content was selected, just pass through the selected index
  m.top.selectedContentIndex = msg.getData()
End Function


Function onKeyEvent(key as String, press as Boolean) as Boolean
  if press = false then
    return false
  end if

  handled = false

  if key = "left" OR key = "right" then
    ' consume left and right keys if a row title is focused
    if m.currentlyFocusedRowContent <> invalid then
      return true
    end if
  else if key = "OK" then
    if m.currentlyFocusedRowContent <> invalid then
      ' We don't want to allow OK to propagate when a row title is focused as row content is actually still what is "focused"
      m.top.selectedContentIndex = [m.top.itemFocused]
      return true
    end if
  else if key = "up" OR key = "down" then
    rowContent = invalid

    previouslyFocusedRowContent = m.currentlyFocusedRowContent
    m.currentlyFocusedRowContent = invalid

    if key = "down" then
      if previouslyFocusedRowContent <> invalid then
        handled = true
      else
        rowContent = getRowContent(m.top.itemFocused + 1)
      end if
    else if key = "up" then
      rowContent = getRowContent(m.top.itemFocused)
    end if

    if rowContent <> invalid AND rowContent.hasField("isRowFocused") = true then
      if rowContent.isRowFocused <> true then
        m.currentlyFocusedRowContent = rowContent
        rowContent.isRowFocused = true

        ' In both cases we have handle the key press but in the case of down we need to animate to the next row
        if key = "down" then
          m.top.animateToItem = m.top.itemFocused + 1
        end if

        handled = true
      end if
    end if

    if previouslyFocusedRowContent <> invalid then
      previouslyFocusedRowContent.isRowFocused = false

      ' Now that row item is focused we need to trigger navigate within page event
      onRowItemFocusedChanged(invalid)
    end if

    m.top.drawFocusFeedback = (m.currentlyFocusedRowContent = invalid)
  else if key = "play" then
    ' Don't want to propagate play key if a row title is focused
    if m.currentlyFocusedRowContent = invalid then
      m.top.playContentIndex = m.top.rowItemFocused
    end if

    return true
  end if

  return handled
End Function
