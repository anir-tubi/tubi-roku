Function init()
  m.constants = getConstantsFromGlobal()
  topRef = m.top

  m.grid = topRef.findNode("grid")
  m.title = topRef.findNode("title")
  m.grid.itemSize = m.constants.ui.imageSizes.largePoster
  topRef.observeFieldScoped("contentUpdated", "onContentUpdated")
  topRef.observeFieldScoped("focusedChild", "onFocusedChildChange")
  m.grid.observeFieldScoped("itemSelected", "onItemSelected")
  m.grid.observeFieldScoped("itemFocused", "onItemFocused")

  m.header = topRef.findNode("header")

  content = createObject("roSGNode", "ContentNode")
  content.title = getTranslation("screenDetails_relatedTitles")
  m.header.content = content

  m.global.observeFieldScoped("theme", "onThemeChange")
  onThemeChange()

  m.tracking = TubiTrackingInfo(m.constants)

  typographyConstants = getTypographyConstants()
  setTypographyOfLabel(m.title, typographyConstants.ids.bodyMedium)

  m.previousFocusedContent = invalid

  ' Used to determine if navigate_within_page events should be sent. Only send when the Related content row already
  ' has focus, not when it gains focus.
  m.isRelatedFocused = false
End Function


Function onFocusedChildChange()
  if m.top.hasFocus() = true
    m.grid.setFocus(true)
  else if m.top.isInFocusChain() <> true
    m.isRelatedFocused = false
  end if
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.grid.focusBitmapBlendColor = theme.focusedColor
    m.title.color = theme.primaryTextColor
  end if
End Function

Function onScreenFocusChange()
  if m.top.hasFocus() = true
    m.liveEventsContainer.setFocus(true)
  end if

  content = m.top.content
  if content <> invalid
    m.top.backgroundUriList = content.backgrounds
  end if
End Function


Function onContentUpdated()
  relatedContent = m.top.content
  if relatedContent <> invalid AND relatedContent.getChildCount() > 0
    m.grid.visible = true
    m.header.visible = true
    m.grid.numColumns = relatedContent.getChildCount()
    m.grid.jumpToItem = m.grid.itemFocused

    m.grid.update({
      parentScreenId: m.top.parentScreenId
      parentScreenTrackingPageInfo: m.top.trackingPageInfo
      personalizationId: relatedContent.personalizationId
      shouldTrackViewableImpressionEvent: m.top.shouldTrackViewableImpressionEvent
    }, true)
  end if
End Function


Function onItemSelected()
  if m.grid.content <> invalid
    itemSelected = m.grid.itemSelected
    selectedContent = m.grid.content.getChild(itemSelected)

    col = itemSelected + 1
    row = 1

    m.top.trackingComponentInfo = {
      componentType: "related_component"
      componentValues: {
        content_tile: m.Tracking.getAnalyticsTile(selectedContent, col, row)
      }
    }

    m.top.selectedContent = selectedContent
  end if
End Function


Function onItemFocused()
  if m.grid.content <> invalid
    itemFocused = m.grid.itemFocused
    focusedContent = m.grid.content.getChild(itemFocused)
    if focusedContent <> invalid
      m.title.text = focusedContent.title
    end if

    col = itemFocused + 1
    row = 1
    pageInfo = m.top.trackingPageInfo

    if m.isRelatedFocused = true
      m.top.navigateWithinPageInfo = {
        pageOneof: m.Tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
        componentOneof: m.Tracking.getAnalyticsComponent("related_component", m.previousFocusedContent)
        means_of_navigation: "BUTTON"
        vertical_location: row
        horizontal_location: col
      }

      m.previousFocusedContent = {
        content_tile: m.Tracking.getAnalyticsTile(focusedContent, col, row)
      }
    end if

    m.isRelatedFocused = true
    m.top.focusedContent = focusedContent
  end if
End Function
