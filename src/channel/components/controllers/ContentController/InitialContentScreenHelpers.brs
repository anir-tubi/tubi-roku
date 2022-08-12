Function displayInitialContentScreen()
  tubiLog("InitialContentScreenHelpers.displayInitialContentScreen")

  showHideSpinner(false)

  screen = CreateObject("roSGNode", "InitialContentScreen")
  screen.id = m.constants.ui.screenIds.initialContentScreen
  screen.backgroundUriList = [m.defaultBackgroundUri]
  screen.screenLevel = m.constants.ui.screenLevels.initialContentScreen
  screen.observeFieldScoped("actionableItemSelected", "onActionableItemSelected")
  screen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
  screen.observeFieldScoped("backgroundUriList", "onScreenBackgroundUpdated")

  screen.backgroundUriList = [m.marketingBackgroundUri]

  pushScreen(screen, true, true)

  '//if the startup logo animation is done, then animate the screen into view. Otherwise, wait for the animation to be done.
  if m.top.removeStartUpScreens = true
    onStartupAnimationDone()
  else
    m.top.observeFieldScoped("removeStartUpScreens", "onStartupAnimationDone")
  end if

End Function


' If the startup logo animation is done, then animate this screen into view.
Function onStartupAnimationDone()
  screen = getCurrentScreen()
  if screen <> invalid and screen.id = m.constants.ui.screenIds.initialContentScreen
    screen.animateIntoView = true
  end if
End Function


' When the user selects an item from the initial content screen, then take action and display a new screen
Function onActionableItemSelected(msg)
  tubiLog("InitialContentScreenHelpers.onActionSelected")
  sSelectedID = msg.getData()
  screen = msg.getRoSGNode()

  sendInitialContentComponentInteractionEvent(sSelectedID, screen)
  displayFirstContentScreen(sSelectedID)
End Function


' Dispatch a component_interaction analytic event when an action item is selected
Function sendInitialContentComponentInteractionEvent(sSelectedID, screen)
  tubiLog("InitialContentScreenHelpers.sendInitialContentComponentInteractionEvent")
  navComponent = {
    top_nav_section: m.Tracking.sideNavPageMap[m.constants.ui.sideNavIds.home]
  }
  sUserInteraction = "CONFIRM"
  if sSelectedID = "skip"
    sUserInteraction = "SKIP"
  else if sSelectedID = m.constants.ui.keyIds.back
    sUserInteraction = "BACK"
  else
    '//skip and back do not have a navComponent/componentOneof. Just the buttons that link directly to pages do.
    navComponent = {
      top_nav_section: m.Tracking.sideNavPageMap[sSelectedID]
    }
  end if

  pageOneof = m.Tracking.getAnalyticsPage(screen.trackingPageInfo.pagetype, screen.trackingPageInfo.pageValues)
  event = {
    type: "component_interaction"
    values: {
      pageOneof: pageOneof
      user_interaction: sUserInteraction
    }
  }

  if navComponent <> invalid
    '//::NOTE:: The initial content screen repurposes the top_nav_component for the component_interaction event
    event.values.componentOneof = m.Tracking.getAnalyticsComponent("top_nav_component", navComponent)
  end if

  m.trackingLoggingTask.trackEvent = event
End Function

' @sSelectedID, id of the item that was selected on the ICTS. May be one of constants.ui.sideNavIds
Function displayFirstContentScreen(sSelectedID)
  tubiLog("InitialContentScreenHelpers.displayFirstContentScreen")

  sideNavIds = m.constants.ui.sideNavIds
  sideNavFocus = sideNavIds.home

  if sSelectedID = sideNavIds.linearEPG
    sideNavFocus = sideNavIds.home
    showDefaultEPGScreen()
  else if sSelectedID = sideNavIds.kidsMode
    sideNavFocus = sideNavIds.home
    setUiMode(m.constants.ui.modes.kids)
    refreshScreenAfterParentalChanges()
    showDefaultHomeScreen()
  else if sSelectedID = sideNavIds.espanol
    setUiMode(m.constants.ui.modes.latino)
    sideNavFocus = sideNavIds.espanol
    showEspanolScreen()
  else if sSelectedID = sideNavIds.profile
    setUiMode(m.constants.ui.modes.standard)
    startSignIn(onSignInAfterInitialContentScreen)
  else if sSelectedID = sideNavIds.movies
    setUiMode(m.constants.ui.modes.standard)
    showMoviesScreen()
  else if sSelectedID = sideNavIds.tv
    setUiMode(m.constants.ui.modes.standard)
    showTVScreen()
  else
    sideNavFocus = sideNavIds.home
    ' send the user to the default home page
    setUiMode(m.constants.ui.modes.standard)
    reloadDefaultHomeScreenContent()
    showDefaultHomeScreen()
  end if

  focusSideNavOption(sideNavFocus)
End Function
