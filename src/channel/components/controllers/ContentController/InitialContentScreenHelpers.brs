Function displayInitialContentScreen()
  tubiLog("InitialContentScreenHelpers.displayInitialContentScreen")

  if isICTSExperimentEnabled(true) = true
    m.logoGroup.visible = false
  end if

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

' @sSelectedID, id of the item that was selected on the ICTS. May be one of constants.ui.sideNavIds or constants.ui.contentExperienceModes
Function displayFirstContentScreen(sSelectedID)
  tubiLog("InitialContentScreenHelpers.displayFirstContentScreen")

  contentExperienceModes = m.constants.ui.contentExperienceModes
  sideNavIds = m.constants.ui.sideNavIds
  sideNavFocus = sideNavIds.home
  if isICTSExperimentEnabled() = true
    sideNavFocus = sideNavIds.contentExperience
    ' Have to unhide the logo when we leave ICTS
    m.logoGroup.visible = true
  end if

  if sSelectedID = sideNavIds.linearTV
    m.contentExperienceMode = contentExperienceModes.liveTV
    epgExperiment = getExperimentResource("roku_linear_epg", "roku_linear_epg_v5", false)
    sideNavFocus = sideNavIds.home
    if epgExperiment.enabled = true
      showDefaultEPGScreen()
      if epgExperiment.side_nav = true
        sideNavFocus = sideNavIds.linearEPG
      end if
    else
      showLinearTVScreen()
    end if
  else if sSelectedID = sideNavIds.kidsMode
    sideNavFocus = sideNavIds.home
    m.contentExperienceMode = contentExperienceModes.kids
    setUiMode(m.constants.ui.modes.kids)
    refreshScreenAfterParentalChanges()
    showDefaultHomeScreen()
  else if sSelectedID = sideNavIds.espanol
    m.contentExperienceMode = contentExperienceModes.espanol
    setUiMode(m.constants.ui.modes.latino)
    if isICTSExperimentEnabled() = false
      sideNavFocus = sideNavIds.espanol
    end if
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
  else if sSelectedID = sideNavIds.bestKnown
    m.contentExperienceMode = contentExperienceModes.bestKnown
    setUiMode(m.constants.ui.modes.standard)
    showBestKnownScreen()
  else if sSelectedID = sideNavIds.nostalgia
    m.contentExperienceMode = contentExperienceModes.nostalgia
    setUiMode(m.constants.ui.modes.standard)
    showNostalgiaScreen()
  else
    sideNavFocus = sideNavIds.home
    m.contentExperienceMode = contentExperienceModes.standard
    ' send the user to the default home page
    setUiMode(m.constants.ui.modes.standard)
    reloadDefaultHomeScreenContent()
    showDefaultHomeScreen()
  end if

  focusSideNavOption(sideNavFocus)
End Function


Function isICTSExperimentEnabled(sendEvent = false)
  ictsExperiment = getExperimentResource("roku_icts_content_modes", "roku_icts_content_modes_v1", sendEvent)
  return ictsExperiment.enabled = true and m.constants.deviceInfo.countryCode = "US"
End Function
