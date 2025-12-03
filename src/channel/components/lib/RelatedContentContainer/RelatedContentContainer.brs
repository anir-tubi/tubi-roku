' Initializes the RelatedContentContainer component
' Sets up node references, observers, theme, tracking, and typography
Function init()
  m.constants = getConstantsFromGlobal()
  topRef = m.top

  m.grid = topRef.findNode("grid")
  m.title = topRef.findNode("title")
  m.contentGroup = topRef.findNode("contentGroup")
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

  m.top.focusable = true
End Function


' Handles focus changes on the component
' Sets focus to the grid when component gains focus
' Resets related focus flag when component loses focus chain
Function onFocusedChildChange()
  if m.top.hasFocus() = true
    m.grid.setFocus(true)
  else if m.top.isInFocusChain() <> true
    m.isRelatedFocused = false
  end if
End Function


' Handles theme changes and applies theme colors
' @param msg - Optional message containing theme data
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


' Handles content updates for the related content container
' Configures grid layout and updates tracking information
Function onContentUpdated()
  relatedContent = m.top.content
  if relatedContent <> invalid AND relatedContent.getChildCount() > 0
    m.grid.visible = true
    m.header.visible = m.top.variant <> "portraitWithMetadata"
    m.grid.numColumns = relatedContent.getChildCount()
    m.grid.jumpToItem = m.grid.itemFocused

    m.grid.update({
      parentScreenId: m.top.parentScreenId
      parentScreenTrackingPageInfo: m.top.trackingPageInfo
      personalizationId: relatedContent.personalizationId
      shouldTrackViewableImpressionEvent: m.top.shouldTrackViewableImpressionEvent
    }, true)

    if m.top.variant = "portraitWithMetadata"
      if m.tileMetadata = invalid
        setupPortraitWithMetadata()
      end if
      content = relatedContent.getChild(0)
      m.tileMetadata.itemContent = content
    end if
  end if
End Function


' Configures the component for portrait with metadata variant
' Hides header and title, adjusts grid positioning and size
' Creates and appends tile metadata component
Function setupPortraitWithMetadata() as Void
  m.header.visible = false
  m.title.visible = false
  m.grid.translation = [0, 0]
  m.tileMetadata = createObject("roSGNode", "ExpandedTileMetadata")
  m.tileMetadata.update({
    id: "ymalTileMetadata",
    variant: "portraitWithMetadata"
    descriptionWidth: 1056
    translation: [0, 414]
  })
  m.top.appendChild(m.tileMetadata)
End Function


' Handles item selection in the grid
' Updates tracking information and sets selected content
Function onItemSelected()
  if m.grid.content <> invalid
    itemSelected = m.grid.itemSelected
    m.top.selectedContent = m.grid.content.getChild(itemSelected)
  end if
End Function


' Handles item focus changes in the grid
' Updates title, tracking information, and tile metadata
' Sends navigate within page tracking events when already focused
Function onItemFocused() as Void
  if m.grid.content <> invalid
    itemFocused = m.grid.itemFocused
    focusedContent = m.grid.content.getChild(itemFocused)
    if focusedContent = invalid then return

    m.title.text = focusedContent.title

    col = itemFocused + 1
    row = 1
    pageInfo = m.top.trackingPageInfo

    if m.previousFocusedContent <> invalid
      m.top.navigateWithinPageInfo = {
        pageOneof: m.tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
        componentOneof: m.tracking.getAnalyticsComponent("related_component", m.previousFocusedContent)
        means_of_navigation: "SCROLL"
        vertical_location: row
        horizontal_location: col
      }
    end if

    m.previousFocusedContent = {
      content_tile: m.tracking.getAnalyticsTile(focusedContent, col, row)
    }

    m.top.trackingContext = {
      type: "related_component"
      values: m.previousFocusedContent
    }

    m.isRelatedFocused = true
    m.top.focusedContent = focusedContent
    if m.tileMetadata <> invalid
      m.tileMetadata.itemContent = focusedContent
    end if
  end if
End Function
