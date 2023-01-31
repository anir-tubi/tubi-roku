' is the home screen's top nav enabled
Function isTopNavHomeScreenEnabled()
  bReturn = false

  if m.constants.deviceInfo.countryCode <> invalid AND UCase(m.constants.deviceInfo.countryCode) = "US"
    if isKidsUIOn() = false
      bReturn = true
    end if
  end if

  return bReturn
End Function


Function onTopNavItemSelected(msg)
  tubiLog("TopNavHelpers.onTopNavItemSelected")
  content = msg.getData()
  screen = msg.getRoSGNode()
  handleTopNavItemSelected(content, screen, false)
End Function


Function onTopNavBackItemSelected(msg)
  tubiLog("TopNavHelpers.onTopNavBackItemSelected")
  content = msg.getData()
  screen = msg.getRoSGNode()
  handleTopNavItemSelected(content, screen, true)
End Function


' @topNavItem: roSGNode, the content node representing the top nav item that was selected
' @screen: roSGNode, the screen that the top nav is a child of
' @isFocusRetainedOnTopNav: boolean, pass true if focus should be returned to top nav after a selection.
'                                    This typically happens if the user presses back from the top nav
Function handleTopNavItemSelected(topNavItem, screen, isFocusRetainedOnTopNav = false)
  if topNavItem <> invalid AND screen <> invalid
    if screen.trackingPageInfo <> invalid
      '//Dispatch a selection component_interaction analytic event when a top nav item is selected
      navComponent = {
        top_nav_section : m.Tracking.sideNavPageMap[topNavItem.id]
      }
      pageOneof = m.Tracking.getAnalyticsPage(screen.trackingPageInfo.pagetype, screen.trackingPageInfo.pageValues)
      event = {
        type : "component_interaction"
        values : {
          pageOneof : pageOneof
          componentOneof : m.Tracking.getAnalyticsComponent("top_nav_component", navComponent)
          user_interaction : "CONFIRM"
        }
      }
      m.trackingLoggingTask.trackEvent = event
    end if

    componentToFocus = ""
    if isFocusRetainedOnTopNav = true
      if isAnEpgScreen(screen) = true
        componentToFocus = m.constants.ui.EPGscreen.focusItems.topNav
      else if isTournamentScreen(screen) = true
        componentToFocus = m.constants.ui.tournamentScreen.focusItems.topNav
      else
        componentToFocus = m.constants.ui.homescreen.focusItems.topNav
      end if
    end if

    if m.constants.ui.screenIdToSideNavId[screen.id] <> topNavItem.id
      if topNavItem.id = m.constants.ui.sideNavIds.movies
        ' Fixes logo not showing up after returning from EPG
        showHideLogoBasedOnUiMode()
        showMoviesScreen(componentToFocus)
      else if topNavItem.id = m.constants.ui.sideNavIds.tv
        ' Fixes logo not showing up after returning from EPG
        showHideLogoBasedOnUiMode()
        showTVScreen(componentToFocus)
      else if topNavItem.id = m.constants.ui.sideNavIds.home
        ' Fixes logo not showing up after returning from EPG
        showHideLogoBasedOnUiMode()
        showDefaultHomeScreen(componentToFocus)
      else if topNavItem.id = m.constants.ui.sideNavIds.espanol
        showEspanolScreen(componentToFocus)
      else if topNavItem.id = m.constants.ui.sideNavIds.channels
        showChannelListScreen(m.constants, m.constants.ui.terms.menu)
      else if topNavItem.id = m.constants.ui.sideNavIds.Categories
        showCategoryListScreen(m.constants, m.constants.ui.terms.menu)
      else if topNavItem.id = m.constants.ui.sideNavIds.search
        showSearchScreen()
      else if topNavItem.id = m.constants.ui.sideNavIds.linearEPG
        showDefaultEPGScreen(componentToFocus)
      else if topNavItem.id = m.constants.ui.sideNavIds.tournament
        showTournamentScreen(m.constants, componentToFocus)
      end if
    else
      ' If the user selected a top nav item that is associated with the current screen,
      ' then simply close the top nav
      if screen.subType() = "HomeScreen"
        screen.componentToFocus = m.constants.ui.homescreen.focusItems.contentGrid

        ' if we don't set focus to false here, and one the top nav already has focus
        ' (so screen.isInFocusChain() = true), then screen.setFocus(true) will not
        ' set focus on the screen, which needs to happen for the appropriate focus
        ' logic to occur in the screen.
        screen.setFocus(false)
        screen.setFocus(true)
      else if isAnEpgScreen(screen) = true
        screen.componentToFocus = m.constants.ui.epgScreen.focusItems.epgTimeGrid
        screen.setFocus(false)
        screen.setFocus(true)
      else if isTournamentScreen(screen) = true
        if screen.isPreTournament = true
          screen.componentToFocus = m.constants.ui.tournamentScreen.focusItems.epgTimeGrid
        else
          screen.componentToFocus = m.constants.ui.tournamentScreen.focusItems.categoryGridList
        end if
        screen.setFocus(false)
        screen.setFocus(true)
      end if
    end if

    currentScreen = getCurrentScreen()

    if currentScreen.id <> screen.id AND screen.hasField("jumpToRowItem") = true
      if isAnEpgScreen(screen) = true
        if getExperimentResource("roku_linear_epg_position", "roku_linear_epg_position_v1", false).enabled <> true
          screen.jumpToRowItem = [0, 0]
        end if
      else
        screen.jumpToRowItem = [0, 0] '//reset original homescreen so it is set back to the origin content item.
      end if
    end if
  end if
End Function


' When the top nav gains or loses focus, then send analytics
Function onScreenTopNavToggled(msg)
  tubiLog("TopNavHelpers.onScreenTopNavToggled")
  topNavToggled = msg.getData()
  screen = msg.getRoSGNode()
  if topNavToggled = true
    user_interaction = "TOGGLE_ON"
  else
    user_interaction = "TOGGLE_OFF"
  end if

  focusedNavId = m.constants.ui.screenIdToSideNavId[screen.id]
  navComponent = {
    top_nav_section : m.Tracking.sideNavPageMap[focusedNavId]
  }

  event = {
    type : "component_interaction"
    values : {
      pageOneof : m.Tracking.getAnalyticsPage(screen.trackingPageInfo.pagetype, screen.trackingPageInfo.pageValues)
      componentOneof : m.Tracking.getAnalyticsComponent("top_nav_component", navComponent)
      user_interaction : user_interaction
    }
  }
  m.trackingLoggingTask.trackEvent = event
End Function


' report an analytic event that user is opening the sidenav by
' navigating from the top nav to the side nav
'
' @screen: roSGNode, a screen component
' @sideNav: roSGNode, a SideNav component
Function onNavigatedFromTopNavToSideNav(msg)
  tubiLog("TopNavHelpers.onNavigatedFromTopNavToSideNav")
  screen = msg.getRoSGNode()
  if screen <> invalid AND m.sideNav <> invalid
    sendTopNavToSideNavNavigationEvent(screen, m.sidenav)
  end if
End Function


Function sendTopNavToSideNavNavigationEvent(screen, sideNav)
  if screen <> invalid AND sideNav <> invalid
    focusedNavId = m.constants.ui.screenIdToSideNavId[screen.id]
    buttonID = m.Tracking.sideNavPageMap[focusedNavId]

    '//Both the side and top navs should have the same HOME button ID
    destComponent = {
      left_nav_section: buttonID
    }
    component = {
      top_nav_section: buttonID
    }

    pageOneof = {}
    if screen.trackingPageInfo <> invalid
      pageOneof = m.Tracking.getAnalyticsPage(screen.trackingPageInfo.pageType, screen.trackingPageInfo.pageValues)
    end if

    row = sideNav.focusedPosition + 1
    col = 1

    m.top.navigateWithinPageInfo = {
      pageOneof: pageOneof
      componentOneof: m.Tracking.getAnalyticsComponent("top_nav_component", component)
      means_of_navigation: "BUTTON"  'MeansOfNavigation enum
      dest_componentOneof: m.Tracking.getAnalyticsDestinationComponent("dest_left_side_nav_component", destComponent)
      vertical_location: row  '//The row location of the top nav
      vertical_location_mode: "INDEX"  'LocationMode enum
      horizontal_location: col  '//The column location of the top nav
      horizontal_location_mode: "INDEX"  'LocationMode enum
    }
  end if
End Function


Function refreshAllHomeScreenTopNav()
' Refresh all home screens so their top navs are properly being displayed
  for i = 0 to m.screenStack.getChildCount() - 1
    screen = m.screenStack.getChild(i)
    if screen.subType() = "HomeScreen"
      refreshHomescreenTopNav(screen)
    end if
  end for
End Function
