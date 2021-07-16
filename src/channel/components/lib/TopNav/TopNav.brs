Function init()
  tubiLog("TopNav.init")
  
  m.Menu = m.top.findNode("TopNavMenu")
  m.MenuBground = m.top.findNode("TopNavMenuBground")
  m.MenuBgroundParent = m.top.findNode("TopNavMenuBgroundParent")
  m.FarAwayFromFocusIndicator = m.top.findNode("farAwayFromFocusIndicator")
  m.constants = m.global.constants

  Request = TubiRequest(m.constants.settings)
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)

  m.top.observeFieldScoped("focusedChild", "onFocusChange")
  m.top.observeFieldScoped("jumpToID", "onJumpIDChange")
  m.top.observeFieldScoped("farAwayFromFocus", "onFarAwayFromFocusChange")
  m.top.observeFieldScoped("refresh", "onRefreshChange")

  m.Menu.numRows = 1

  if m.constants <> invalid and m.constants.deviceInfo.scaledUi = true
    m.Menu.focusBitmapUri = "pkg://images/menu-focus-hd.9.png"
    m.MenuBground.uri = "pkg://images/menu-focus-hd.9.png"
  end if

  m.Menu.observeField("itemSelected", "onItemSelected")
  m.Menu.observeField("itemFocused", "onItemFocused")
  setFocusVisualProperties() ' initialize the focus look of the topNav
End Function


Function onRefreshChange()
  if m.top.refresh = true
    draw()
  end if
End Function


' Draw the navigational items in the top nav. Do not call this in the init() function as it may slow the app down as the content is loading
Function draw()
  m.Menu.focusBitmapBlendColor = m.global.theme.focused
  rowNode = CreateObject("roSGNode", "ContentNode")
  nMenuOutsideSpacing = m.Menu.translation[0]
  aItemWidths = []
  nBgroundWidth = nMenuOutsideSpacing
  nButtonPadding = 2 '::HARDCODED:: this is the total horizontal padding of the buttons to ensure MenuBground is the proper width. Since this cannot be determined easily programatically, we afre hardcoding the number here. 
  setMainContent(m.constants.ui.sideNavIds.home, rowNode, aItemWidths)
  nBgroundWidth += aItemWidths[aItemWidths.Count()-1] + nButtonPadding + getColumnSpacing(0)
  setMainContent(m.constants.ui.sideNavIds.movies, rowNode, aItemWidths) 
  nBgroundWidth += aItemWidths[aItemWidths.Count()-1] + nButtonPadding + getColumnSpacing(1)
  setMainContent(m.constants.ui.sideNavIds.tv, rowNode, aItemWidths)
  
  if m.top.isNewsAllowed = true
    nBgroundWidth += aItemWidths[aItemWidths.Count()-1] + nButtonPadding + getColumnSpacing(2)
    setMainContent(m.constants.ui.sideNavIds.news, rowNode, aItemWidths)
  end if
  
  nBgroundWidth += aItemWidths[aItemWidths.Count()-1] + nButtonPadding + nMenuOutsideSpacing

  m.MenuBground.width = nBgroundWidth

  m.Menu.columnWidths = aItemWidths
  m.Menu.itemSize = [nBgroundWidth, m.Menu.itemSize[1]]
  m.Menu.content = rowNode
End Function



' Get the column spacing (to the right) for the column number that is passed
Function getColumnSpacing(nColumn)
  spacing = -1
  if nColumn < m.Menu.columnSpacings.Count() - 1
    spacing = m.Menu.columnSpacings[nColumn]
  end if
  if spacing < 0
    spacing = m.Menu.itemSpacing[0]
  end if
  if spacing < 0
    '//The default spacing should be 0
    spacing = 0
  end if
  return spacing
End Function


' Set the ContentNode of one topNav button and add it to the passed parentNode
' @itemID - string, The ID of the propsed top nav button 
' @parentNode - The node to which the new button info will be added
' @aItemWidths - array, An array that is used to keep track of the width of the new top nav button
Function setMainContent(itemID, parentNode, aItemWidths)
  contentNode = CreateObject("roSGNode", "TopNavContentNode")
  contentNode.id = itemID
  bSuccess = false

  if itemID = m.constants.ui.sideNavIds.home
    contentNode.title = getTranslation("menu_recommended")
    bSuccess = true
  else if itemID = m.constants.ui.sideNavIds.movies
    contentNode.title = getTranslation("menu_movies")
    bSuccess = true
  else if itemID = m.constants.ui.sideNavIds.tv
    contentNode.title = getTranslation("menu_tv")
    bSuccess = true
  else if itemID = m.constants.ui.sideNavIds.news
    if getExperimentResource("roku_live_tv_name_experiment", "roku_live_tv_name_experiment_v1", true).enabled = false
      '//::TODO:: liveTV - if the experiment is successful, then add a new sideNavIds that corresponds to liveTV. 
      '//::TODO:: liveTV - if the experiment is successful, are the analytics affected? Do they need to say live_tv instead of news? 
      contentNode.title = getTranslation("menu_news")
    else
      contentNode.title = getTranslation("menu_livetv")
    end if
    bSuccess = true
  else if itemID = m.constants.ui.sideNavIds.espanol
    contentNode.title = "Español"
    bSuccess = true
  end if

  if bSuccess = true
    '//component is a temporary component used to determine the width of the the topNav button
    component = CreateObject("roSGNode", "TopNavItem")
    component.itemContent = contentNode
    aItemWidths.push(component.boundingRect.width)
    parentNode.appendChild(contentNode)

    component.itemContent = invalid '//Component is no longer needed. In an attempt to to get component to get garbage collected remove its content, which is being used after this function
  end if

End Function


Function onItemSelected()
  tubiLog("TopNav.onItemSelected")
  selected = m.Menu.content.getChild(m.Menu.itemSelected)


  ' when the screen stacker changes the page, it will use trackingComponentInfo to dispatch a ‘NavigateToPageEvent' 
  selectedID = m.Tracking.sideNavPageMap[selected.id]
  values = {
    top_nav_section: selectedID
  }
  m.top.trackingComponentInfo = {
    componentType: "top_nav_component"
    componentValues: values
  }

  m.top.selected = selected
End Function 


Function onItemFocused()
  tubiLog("TopNav.onItemFocused")
  '//When the user focuses on the top nav, then trigger a navigate_within_page event in ContentController
  
  itemFocused = m.Menu.itemFocused
  item = m.Menu.content.getChild(m.Menu.itemFocused)

  pageType = ""
  if m.top.containerTrackingPageInfo <> invalid and m.top.containerTrackingPageInfo.pagetype <> invalid
    pageType = m.top.containerTrackingPageInfo.pagetype
  end if
  pageValues = {}
  if m.top.containerTrackingPageInfo <> invalid and m.top.containerTrackingPageInfo.pageValues <> invalid
    pageValues = m.top.containerTrackingPageInfo.pageValues
  end if

  navigateWithinPageInfo = {
    pageOneof: m.Tracking.getAnalyticsPage(pageType, pageValues)
  }

  row = 1
  col = 1 + itemFocused
  navigateWithinPageInfo.vertical_location = row '1 based index
  navigateWithinPageInfo.vertical_location_mode = "INDEX"  'LocationMode enum
  navigateWithinPageInfo.horizontal_location = col
  navigateWithinPageInfo.horizontal_location_mode =  "INDEX"  'LocationMode enum
  
  focusedID = m.Tracking.sideNavPageMap[item.id]
  newTopNavFocusedButton = {
    top_nav_section: focusedID
  }

  if m.oldTopNavFocusedButton <> invalid
    '//If oldTopNavFocusedButton exists, then the user is focusing from another topNav section
    navigateWithinPageInfo.means_of_navigation = "SCROLL"
    navigateWithinPageInfo.componentOneof = m.Tracking.getAnalyticsComponent("top_nav_component", m.oldTopNavFocusedButton)
  else
    '//If oldTopNavFocusedButton does not exist, then the user got to the top nav from a button press
    navigateWithinPageInfo.dest_componentOneof = m.Tracking.getAnalyticsDestinationComponent("dest_top_nav_component", newTopNavFocusedButton)
    navigateWithinPageInfo.means_of_navigation = "BUTTON"
  end if

  m.top.navigateWithinPageInfo = navigateWithinPageInfo

  '//set oldTopNavFocusedButton 
  m.oldTopNavFocusedButton = newTopNavFocusedButton

End Function


Function onJumpIDChange()
  tubiLog("TopNav.onJumpIDChange")
  if m.top.jumpToID <> invalid and m.top.jumpToID <> ""
    nJumpToItem = -1
    content = m.Menu.content
    if content = invalid 
      draw()
    end if

    content = m.Menu.content
    if content <> invalid
      for i=0 to content.getChildCount()-1
        child = content.getChild(i)
        if m.top.jumpToID = child.id
          child.selected = true
          nJumpToItem = i
        else 
          child.selected = false
        end if
      end for

      if nJumpToItem >= 0
        '//Jump to the item with the same ID that is associated with m.top.jumpToID
        m.Menu.jumpToItem = nJumpToItem
      end if
    end if
  end if
End Function


' When it is indicated that the topNav is far away from or close to the focus, then make visible adjustments to the top Nav
Function onFarAwayFromFocusChange()
  if m.top.farAwayFromFocus = true
    fade(m.FarAwayFromFocusIndicator, "in", .4)
    fade(m.MenuBgroundParent, "out", .4)
  else
    fade(m.FarAwayFromFocusIndicator, "out", .4)
    fade(m.MenuBgroundParent, "in", .4)
  end if
End Function


Function onFocusChange()
  tubiLog("TopNav.onFocusChange")
  setFocusVisualProperties()
End Function


Function setFocusVisualProperties()
  if m.top.hasFocus() = true
    '// The Top Nav is in focus
    m.top.farAwayFromFocus = false
    m.Menu.setFocus(true)
    m.MenuBground.blendColor = "0xF0F1F5FF"
    m.MenuBground.opacity = 1
  else if m.top.isInFocusChain() = false
    '// The Top Nav is no longer in focus
    m.MenuBground.blendColor = "0x9699A3FF"
    m.MenuBground.opacity = .16

    onJumpIDChange()
    m.oldTopNavFocusedButton = invalid
  end if
End Function