Function init()
  tubiLog("TopNav.init")
  theme = getThemeFromGlobal()
  if m.global <> invalid
    m.global.observeFieldScoped("theme", "onThemeChange")
  end if

  m.Menu = m.top.findNode("TopNavMenu")
  m.MenuBground = m.top.findNode("TopNavMenuBground")

  m.constants = getConstantsFromGlobal()
  Request = TubiRequest(m.constants.settings)
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)

  if theme <> invalid
    m.colors = {
      white: theme.unfocusedColor
      lightGray: theme.secondaryTextColor
      darkGray: theme.backgroundColor
      orange: theme.highlightedTextColor
    }
  end if

  m.top.observeFieldScoped("focusedChild", "onFocusChange")
  m.top.observeFieldScoped("jumpToID", "onJumpIDChange")
  m.top.observeFieldScoped("uiState", "onUiStateChange")
  m.top.observeFieldScoped("contentUpdated", "onContentUpdated")
  m.top.observeFieldScoped("selectedId", "onSelectedIdChange")

  m.Menu.numRows = 1
  m.Menu.translation = [12,12]
  if m.colors <> invalid
    m.MenuBground.blendColor = m.colors.lightGray
    m.Menu.focusFootprintBlendColor = m.colors.white
  end if

  m.Menu.observeFieldScoped("itemSelected", "onItemSelected")
  m.Menu.observeFieldScoped("itemFocused", "onItemFocused")

  ' local state to determine if a menu item was selected, which causes a jumpToItem to
  ' reset the proper focus on the top nav right before it loses focus (in case a user has
  ' scrolled off of the default top nav item for the page). The jumpToItem will trigger
  ' an onItemFocused() callback which will attempt to send a navigateToPage event which we
  ' don't want and can prevent by checking this value.
  m.isResetting = false
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.colors = {
      white: theme.unfocusedColor
      lightGray: theme.secondaryTextColor
      darkGray: theme.backgroundColor
      orange: theme.highlightedTextColor
    }
    
    m.MenuBground.blendColor = m.colors.lightGray
    setUiState(m.top.uiState)
  end if
End Function


' Draw the navigational items in the top nav. Do not call this in the init() function as it may slow the app down as the content is loading
Function onContentUpdated()
  tubiLog("TopNav.onContentUpdated")
  theme = getThemeFromGlobal()
  if theme <> invalid
    m.Menu.focusBitmapBlendColor = theme.focusedColor
  end if

  ' HARDCODED:: nButtonPadding is the total horizontal padding of the buttons to ensure
  ' MenuBground is the proper width. Since this cannot be determined easily programatically,
  ' we are hardcoding the number here.
  nButtonPadding = 2
  nMenuOutsideSpacing = m.Menu.translation[0]
  aItemWidths = []
  nBgroundWidth = nMenuOutsideSpacing
  nMenuItems = m.top.content.getChildCount()

  selectedWasSet = false
  for i = 0 to nMenuItems - 1
    menuItem = m.top.content.getChild(i)

    if menuItem.id = m.top.selectedId
      menuItem.selected = true
      selectedWasSet = true
      m.top.selectedIndex = i
    end if
    
    if m.colors <> invalid
      if m.top.uiState = "unfocusedFar"
        menuItem.selectedItemColor = m.colors.white
      else if m.top.uiState = "unfocusedNear"
        menuItem.selectedItemColor = m.colors.darkGray
      else if m.top.uiState = "focused"
        menuItem.selectedItemColor = m.colors.orange
      end if
    end if

    itemWidth = getItemWidth(menuItem)
    aItemWidths.push(itemWidth)

    if i <= nMenuItems - 2 'Do not append the pad for last button
      nBgroundWidth += aItemWidths[aItemWidths.Count()-1] + nButtonPadding
    end if
  end for

  ' if no item was set as the selected item, default to first item
  if selectedWasSet = false
    firstItem = m.top.content.getChild(0)
    firstItem.selected = true
    m.top.selectedIndex = 0
  end if

  nBgroundWidth += aItemWidths[aItemWidths.Count()-1] + nMenuOutsideSpacing - nButtonPadding 'No need of padding for last item and columnspacing
  m.MenuBground.width = nBgroundWidth

  m.Menu.columnWidths = aItemWidths
  m.Menu.itemSize = [nBgroundWidth, m.Menu.itemSize[1]]
  m.Menu.content = m.top.content
End Function


' get the width of the content item as it would display in the top nav
' @contentItem: roSGNode, the contentNode that we want the width of
Function getItemWidth(contentItem)
  '//component is a temporary component used to determine the width of the the topNav button
  component = CreateObject("roSGNode", "TopNavItem")
  component.itemContent = contentItem
  itemWidth = component.boundingRect.width

  ' Component is no longer needed. In an attempt to to get component to get garbage collected
  ' remove its content, which is being used after this function
  component.itemContent = invalid

  return itemWidth
End Function


Function onItemSelected()
  tubiLog("TopNav.onItemSelected")
  menuItem = m.Menu.content.getChild(m.Menu.itemSelected)

  if menuItem <> invalid
    if m.top.doesSelectionNavigate = false
      ' update which item looks like it is selected,
      ' no need to jumpToID since the item is already focused
      updateSelectedItem(menuItem.id)
    else
      ' jump the focus back to the default item so the top nav is in the default state
      ' when the page containing this top nav is navigated to again.
      selectedItemId = getSelectedItemId()
      if selectedItemId <> ""
        m.isResetting = true
        jumpToID(selectedItemId)
      end if
    end if

    ' when the screen stacker changes the page, it will use trackingComponentInfo to dispatch
    ' a 'NavigateToPageEvent'
    selectedSection = m.Tracking.sideNavPageMap[menuItem.id]
    values = {
      top_nav_section: selectedSection
    }
    m.top.trackingComponentInfo = {
      componentType: "top_nav_component"
      componentValues: values
    }

    m.top.selected = menuItem

    ' set to invalid so any changes that might occur to the menuItem node don't re-trigger callbacks
    m.top.selected = invalid
  end if
End Function


Function onItemFocused()
  tubiLog("TopNav.onItemFocused")
  itemFocused = m.Menu.itemFocused
  item = m.Menu.content.getChild(m.Menu.itemFocused)
  focusedID = m.Tracking.sideNavPageMap[item.id]

  newTopNavFocusedButton = {
    top_nav_section: focusedID
  }

  navigateWithinPageInfo = invalid

  ' set NavigateWithinPageInfo state values as appropriate
  if m.oldTopNavFocusedButton <> invalid AND m.oldTopNavFocusedButton.top_nav_section <> newTopNavFocusedButton.top_nav_section
    ' If oldTopNavFocusedButton exists and is not the same as the newTopNavFocusedButton,
    ' then the user is focusing from another topNav section
    navigateWithinPageInfo = buildNavigateWithinPageInfo(itemFocused, m.top.trackingPageInfo, newTopNavFocusedButton, "scroll_focus")
  else if m.oldTopNavFocusedButton = invalid
    '//If oldTopNavFocusedButton does not exist, then the user got to the top nav from a button press
    navigateWithinPageInfo = buildNavigateWithinPageInfo(itemFocused, m.top.trackingPageInfo, newTopNavFocusedButton, "gain_focus")
  else
    ' the old and new buttons are the same, indicating no navigating is actually happening,
    ' so don't send any NavigateWithinPageEvents
  end if

  '//When the user focuses on the top nav, then trigger a navigate_within_page event in ContentController
  if m.top.handlingFocusFromOtherTopNavBackButton <> true AND m.top.losingFocusToComponentOnSamePage <> true AND m.top.losingFocusToExternalComponent <> true AND m.isResetting <> true
    if navigateWithinPageInfo <> invalid
      m.top.navigateWithinPageInfo = navigateWithinPageInfo
    end if
  end if

  m.oldTopNavFocusedButton = newTopNavFocusedButton

  if m.isResetting = true
    m.isResetting = false
  end if
End Function


Function onJumpIDChange(msg)
  tubiLog("TopNav.onJumpIDChange")
  id = msg.getData()

  if id <> invalid AND id <> ""
    jumpToId(id)
  end if
End Function


' @id: string, the id for the top nav item to be jumped to
Function jumpToId(id)
  nJumpToItem = -1

  if isNonEmptyString(id)
    content = m.Menu.content
    if content <> invalid
      for i=0 to content.getChildCount()-1
        child = content.getChild(i)
        if id = child.id
          nJumpToItem = i
          exit for
        end if
      end for

      if nJumpToItem >= 0
        '//Jump to the item with the same ID that is associated with m.top.jumpToID
        m.Menu.jumpToItem = nJumpToItem
      end if
    end if
  end if
End Function


Function onFocusChange()
  tubiLog("TopNav.onFocusChange")
  if m.top.hasFocus()
    m.oldTopNavFocusedButton = invalid
    m.Menu.setFocus(true)
  end if
End Function


Function onUiStateChange(msg)
  tubiLog("TopNav.onUiStateChange")
  uiState = msg.getData()

  setUiState(uiState)
End Function


Function setUiState(uiState)
  tubiLog("TopNav.setUiState")
  if isNonEmptyString(uiState)
    if uiState = "focused"
      setFocusedVisuals()
    else if uiState = "unfocusedNear"
      setUnfocusedNearVisuals()
    else if uiState = "unfocusedFar"
      setUnfocusedFarVisuals()
    end if
  end if

  selectedItemId = getSelectedItemId()
  if selectedItemId <> ""
    jumpToID(selectedItemId)
  end if
End Function


Function setFocusedVisuals()
  tubiLog("TopNav.setFocusedVisuals")
  if m.colors <> invalid
    m.Menu.focusFootprintBlendColor = m.colors.orange
    setSelectedItemColorOnMenuItems(m.colors.orange)
  end if

  ' account for any animations that may be in process on the menu
  stopAnimation(m.menuFade)

  'fade in the Menu back to fully opaque white labels.
  m.menuFade = fade(m.Menu, "in", .4, 0.0, 1)
End Function


Function setUnfocusedNearVisuals()
  tubiLog("TopNav.setUnfocusedNearVisuals")
  if m.colors <> invalid
    m.Menu.focusFootprintBlendColor = m.colors.white
    setSelectedItemColorOnMenuItems(m.colors.darkGray)
  end if

  ' account for any animations that may be in process on the menu
  stopAnimation(m.menuFade)

  'fade in the Menu back to fully opaque white labels.
  m.menuFade = fade(m.Menu, "in", .4, 0.0, 1)
End Function


Function setUnfocusedFarVisuals()
  tubiLog("TopNav.setUnfocusedFarVisuals")
  theme = getThemeFromGlobal()
  if theme <> invalid
    m.Menu.focusFootprintBlendColor = theme.neutralColor
  end if

  ' account for any animations that may be in process on the menu
  stopAnimation(m.menuFade)

  ' fade out the Menu to make labels 64% opacity (give a gray look)
  m.menuFade = fade(m.Menu, "out", 0.4, 0.0, 0.64)

  setSelectedItemColorOnMenuItems(theme.primaryTextColor)
End Function


' @color: string: color represented like "0xFFFFFFFF"
Function setSelectedItemColorOnMenuItems(color)
  content = m.Menu.content
  if content <> invalid
    for i = 0 to content.getChildCount() - 1
      child = content.getChild(i)
      child.selectedItemColor = color
    end for
  end if
End Function


Function onSelectedIdChange(msg)
  selectedId = msg.getData()
  if isNonEmptyString(selectedId)
    m.top.id = m.top.id + "-" + selectedId
  end if
  updateSelectedItem(selectedId)
End Function


' updates which item in the top nav should be treated as selected
Function updateSelectedItem(itemId)
  if isNonEmptyString(itemId) AND m.Menu.content <> invalid
    for i = 0 to m.Menu.content.getChildCount() -1
      menuItem = m.Menu.content.getChild(i)
      if menuItem.id = itemId
        menuItem.selected = true
        m.top.selectedIndex = i
      else
        menuItem.selected = false
      end if
    end for
  end if
End Function


' returns the first menu item with .selected = true.
' Theoretically, there should only ever be exactly one menu item with .selected = true at any given time.
Function getSelectedItemId()
  if m.Menu.content <> invalid
    for i = 0 to m.Menu.content.getChildCount() -1
      menuItem = m.Menu.content.getChild(i)
      if menuItem.selected = true
        return menuItem.id
      end if
    end for
  end if
  return ""
End Function


Function onKeyEvent(key, press) as Boolean
  tubiLog("TopNav.onKeyEvent")
  if press = true
    if key = "back"
      selectedItemId = getSelectedItemId()
      if m.Menu.content <> invalid
        firstChild = m.Menu.content.getChild(0)
        if firstChild <> invalid AND selectedItemId <> firstChild.id
          ' only set backItemSelected if the currently selected item is not the first item
          m.top.backItemSelected = firstChild
          m.top.backItemSelected = invalid
          return true
        end if
      end if
    end if
  end if
  return false
End Function


' @itemFocused: integer, the index of the focused top nav item, 0 based
' @trackingPageInfo: assocArray, as found on m.top.trackingPageInfo
' @newTopNavFocusedButton: assocArray, has single key, value pair such that
'                          key = "top_nav_section", value = <<id of the focused menu item>>
' @focusChange: string, one of the following values, corresponding to the type of focus change
'                       leading to the NavigateWithinPageEvent. "scroll_focus", "gain_focus"
'
' @returns: assocArray, that can be used as the eventValues to build a "navigate_within_page_event"
'                       with TubiTracking.trackUserEvent()
Function buildNavigateWithinPageInfo(itemFocused, trackingPageInfo, newTopNavFocusedButton, focusChange)
  pageType = ""
  if trackingPageInfo <> invalid AND trackingPageInfo.pagetype <> invalid
    pageType = trackingPageInfo.pagetype
  end if

  pageValues = {}
  if trackingPageInfo <> invalid AND trackingPageInfo.pageValues <> invalid
    pageValues = trackingPageInfo.pageValues
  end if

  navigateWithinPageInfo = {
    pageOneof: m.Tracking.getAnalyticsPage(pageType, pageValues)
  }

  row = 1
  col = 1 + itemFocused
  navigateWithinPageInfo.vertical_location = row '1 based index
  navigateWithinPageInfo.vertical_location_mode = "INDEX"  'LocationMode enum
  navigateWithinPageInfo.horizontal_location = col
  navigateWithinPageInfo.horizontal_location_mode = "INDEX"  'LocationMode enum

  if focusChange = "scroll_focus"
    navigateWithinPageInfo.means_of_navigation = "SCROLL"
    navigateWithinPageInfo.componentOneof = m.Tracking.getAnalyticsComponent("top_nav_component", m.oldTopNavFocusedButton)
  else if focusChange = "gain_focus"
    navigateWithinPageInfo.means_of_navigation = "BUTTON"
    navigateWithinPageInfo.dest_componentOneof = m.Tracking.getAnalyticsDestinationComponent("dest_top_nav_component", newTopNavFocusedButton)
  end if

  return navigateWithinPageInfo
End Function
