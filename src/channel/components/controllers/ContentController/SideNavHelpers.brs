Function initSideNav()
  tubiLog("SideNavHelpers.initSideNav")
  '//::NOTE:: this assumes a couple of things:
  '//         1) this is only called once at the launch of the app, and
  '//         2) all of the menu items start out being visible and this function informs the sideNav component which menu items should be hidden
  m.SideNav.observeFieldScoped("itemSelectedId", "onSideNavItemSelected")
  m.SideNav.observeFieldScoped("navigateWithinPageInfo", "onSideNavNavigateWithinPageInfoChanged")

  m.SideNav.createMenuItems = true

  ' display Espanol, TV, Movies menu items only if the countryCode is US
  if m.constants.deviceInfo.countryCode <> "US"
    '//Tell the sideNav to stop displaying the Espanol menu item
    m.SideNav.displayEspanol = false
    '//Tell the sideNav to stop displaying the channel menu item
    m.SideNav.displayChannels = false
  end if

  ' Display the Kids menu items only if the feature is allowed
  if m.kidsModeFeatureOn <> true
    m.SideNav.displayKids = false
  end if

  if isKidsModeEnabledByParentalControls() = true
    m.SideNav.kidsItemTurnedOn = false
  end if

  if isParentalControlsAdultLevel() <> true
    m.SideNav.espanolItemTurnedOn = false
  end if

  if isParentalControlsAdultLevel() <> true
    m.SideNav.linearEPGItemTurnedOn = false
  end if

  'set the initial value for the sign in item string
  setSideNavSignedInItem(m.global.authInfo)
End Function


Function refreshHomeScreenSideNav()
  isTopNavRemovalExperiementEnabled = getExperimentResource("roku_remove_top_nav", "roku_remove_top_nav_v1", false).enabled

  ' Refresh side nav items so their side navs are properly being displayed
  if isParentalControlsAdultLevel() <> true OR isKidsUIOn() = true
    m.SideNav.espanolItemTurnedOn = false
    if isTopNavRemovalExperiementEnabled = true
      m.SideNav.linearEPGItemTurnedOn = false
    end if
  else
    m.SideNav.espanolItemTurnedOn = true
    if isTopNavRemovalExperiementEnabled = true
      m.SideNav.linearEPGItemTurnedOn = true
    end if
  end if
End Function


'put the side nav back into a default state (ie. closed and focused on home)
Function resetSideNav(shouldTrackComponentInteraction = true)
  hideNavMenu(shouldTrackComponentInteraction)
  focusCurrentScreen()
  homeId = m.constants.ui.sideNavIds.home
  focusSideNavOption(homeId)
End Function


' @sID: string: one of the menu item ids. A list of ids can be found in constants.ui.sideNavIds
Function focusSideNavOption(sID)
  if isNonEmptyString(sID) AND m.constants.ui.sideNavIds[sID] <> invalid
    m.SideNav.itemRequested = sID '//set itemRequested so the focus is on the proper button in the sideNav
  end if
End Function


'tell the side nav to move the selected option (denoted by a stationary gray menu selector)
Function updateSideNavSelected(sideNavButtonId)
  m.SideNav.selectedItemRequested = sideNavButtonId
End Function


' Is the side nav open and in focus
Function isSideNavActive() as Boolean
  return (m.SideNav.isInFocusChain() = true AND m.SideNav.opened = true)
End Function


' Change the appearance of the side nav sign in item when the user data has changed
' @authInfo: AA, authInfo as stored on m.global.authInfo
Function setSideNavSignedInItem(authInfo)
  tubiLog("SideNavHelpers.setSideNavSignedInItem")
  sName = getTranslation("menu_signIn")

  if isLoggedInUser(authInfo)
    '//User is signed in
    sName = ""
    if authInfo.firstName <> invalid
      sName = authInfo.firstName
    else if authInfo.name <> invalid
      sName = authInfo.name
    end if
    sName = getTranslation("menu_signedIn", { name: sName })
  end if
  m.SideNav.stringSignIn = sName
End Function


' Add the current screen's pageOneof info to the sideNav's navigateWithinPageInfo before sending the navigateWithinPageInfo analytic
Function onSideNavNavigateWithinPageInfoChanged()
  navigateWithinPageInfo = m.SideNav.navigateWithinPageInfo
  currentScreen = getCurrentScreen()

  if currentScreen <> invalid AND currentScreen.trackingPageInfo <> invalid
    navigateWithinPageInfo.pageOneof = m.Tracking.getAnalyticsPage(currentScreen.trackingPageInfo.pageType, currentScreen.trackingPageInfo.pageValues)
    sendNavigateWithinPageInfo(navigateWithinPageInfo)
  end if
End Function


Function onSideNavItemSelected()
  tubiLog("SideNavHelpers.onSideNavItemSelected")
  itemSelectedId = m.SideNav.itemSelectedId
  itemSelected = m.SideNav.itemSelected
  authInfo = m.global.authInfo
  currentScreenNow = getCurrentScreen()

  ' TODO: Once top nav ids and side nav ids are separated we can directly set the
  ' screenIdToSideNavId map in constants to point multiple screen ids (home, movies, tv)
  ' to a single side nav id and we will not need a function like getSideNavIdAssociatedWithScreen()
  currentScreenSideNavId = getSideNavIdAssociatedWithScreen(currentScreenNow)
  if currentScreenSideNavId <> itemSelectedId
    '// If a new screen is to be called, then collapse the side nav and remember which side nav button was last clicked
    bNewScreenCalledSuccess = false

    if isVideoPreviewOn() = true
      ' stop the video preview when user selects any item from sidenav
      stopVideoPreview()
    end if

    ' set appropriate analytics component on the page being navigated from so NavigateToPageEvent
    ' contains all the requisite information -  NOTE: this analytic does not get reported when the user presses the sideNav button associated with the current screen
    sideNavComponentValues = {
      left_nav_section: m.Tracking.sideNavPageMap[itemSelectedId]
    }
    if currentScreenNow.hasField("reset") = true
      '//reset the previous current screen
      currentScreenNow.reset = true
    end if

    currentScreenNow.trackingComponentInfo = {
      componentType: "left_side_nav_component"
      componentValues: sideNavComponentValues
    }

    if itemSelectedId = m.constants.ui.sideNavIds.profile
      if isKidsUIOn() <> true
        setUiMode(m.constants.ui.modes.standard)
      end if

      if authInfo = invalid or (authInfo <> invalid AND authInfo.userId = invalid)
        '//if user is not signed in, then bring up the sign on page; otherwise, don't do anything
        startSignIn(onSideNavSignInCompleted)
        bNewScreenCalledSuccess = false ' setting bNewScreenCalledSuccess as false to keep the sidenav open when RFI modal is displayed. This is to avoid focus issue.
      else
        '//Bring user to the settings page and select the signout option
        showSettingsScreen("SignInOutButton")
        bNewScreenCalledSuccess = true
      end if
    else if itemSelectedId = m.constants.ui.sideNavIds.kidsMode
      if itemSelected.turnedOn = true
        '//If the parental control settings are not set to kids, then this action is not limited
        '// aka this mode is not locked down and can be easily exited without a parent's intervention

        if isKidsUIOn() = true
          if needsToShowAgeVerificationScreen() = true then
            showAgeVerificationScreenAtKidsModeExit(m.uiMode)
          else
            disableKidsModeFromSideNav()
          end if
        else
          dialogEvent = {
            type: "dialog"
            values: {
              dialog_type: "ENTER_KIDS_MODE"
              pageOneof: m.Tracking.getAnalyticsPage(currentScreenNow.trackingPageInfo.pageType, currentScreenNow.trackingPageInfo.pageValues)
              dialog_action: "ACCEPT_DELIBERATE"
              dialog_sub_type: "enter-kids-mode"
            }
          }
          m.trackingLoggingTask.trackEvent = dialogEvent
          enableKidsModeFromSideNav()
        end if
      else
        if isKidsUIOn() = true
          '// this mode is locked down and a child need's a parent's intervention to exit the mode

          dialogEvent = {
            type: "dialog"
            values: {
              dialog_type: "EXIT_KIDS_MODE"
              pageOneof: m.Tracking.getAnalyticsPage(currentScreenNow.trackingPageInfo.pageType, currentScreenNow.trackingPageInfo.pageValues)
              dialog_action: "SHOW"
              dialog_sub_type: "exit-kids-parental"
            }
          }

          sTitle = getTranslation("dialog_kidsExit_title")
          sDescription = getTranslation("dialog_kidsExitLimited_description")
          showSimpleInstantResumableModal(sTitle, sDescription, [getTranslation("dialog_button_settings"), getTranslation("dialog_button_cancel")], dialogEvent, m.trackingLoggingTask, onKidsModeSettingsCall)
        else
          '//This use case should never happen. If the user has parental controls set to kids, then that instantly turns on kids mode,
          '//   so there will never be an enter kids mode mode when parental controls is turned to kids.
        end if

      end if
    else if itemSelectedId = m.constants.ui.sideNavIds.search
      '//display the search
      if isKidsUIOn() <> true
        setUiMode(m.constants.ui.modes.standard)
      end if

      showSearchScreen()
      bNewScreenCalledSuccess = true
    else if itemSelectedId = m.constants.ui.sideNavIds.home
      if isKidsUIOn() <> true
        setUiMode(m.constants.ui.modes.standard)
      end if

      showHomeScreen(m.constants, authInfo)
      bNewScreenCalledSuccess = true
    else if itemSelectedId = m.constants.ui.sideNavIds.channels
      if isKidsUIOn() = true
        bNewScreenCalledSuccess = false
        displayMenuItemDisabled(m.constants.ui.sideNavIds.channels)
      else
        setUiMode(m.constants.ui.modes.standard)
        showChannelListScreen(m.constants)
        bNewScreenCalledSuccess = true
      end if
    else if itemSelectedId = m.constants.ui.sideNavIds.categories
      if isKidsUIOn() <> true
        setUiMode(m.constants.ui.modes.standard)
      end if

      showCategoryListScreen(m.constants)
      bNewScreenCalledSuccess = true
    else if itemSelectedId = m.constants.ui.sideNavIds.espanol
      if isKidsUIOn() = true
        bNewScreenCalledSuccess = false
        displayMenuItemDisabled(m.constants.ui.sideNavIds.espanol)
      else if isParentalControlsAdultLevel() = false
        bNewScreenCalledSuccess = false
        displayMenuItemDisabled(m.constants.ui.sideNavIds.espanol, "teens")
      else
        setUiMode(m.constants.ui.modes.latino)
        showEspanolScreen()
        bNewScreenCalledSuccess = true
      end if
    else if itemSelectedId = m.constants.ui.sideNavIds.myList
      if isKidsUIOn() <> true
        setUiMode(m.constants.ui.modes.standard)
      end if

      showMyStuffScreen()
      bNewScreenCalledSuccess = true
    else if itemSelectedId = m.constants.ui.homeScreenTopNavIds.movies
      if isKidsUIOn() = true
        bNewScreenCalledSuccess = false
        displayMenuItemDisabled(m.constants.ui.homeScreenTopNavIds.movies)
      else if isParentalControlsAdultLevel() = false
        bNewScreenCalledSuccess = false
        displayMenuItemDisabled(m.constants.ui.homeScreenTopNavIds.movies, "teens")
      else
        showMoviesScreen()
        bNewScreenCalledSuccess = true
      end if
    else if itemSelectedId = m.constants.ui.homeScreenTopNavIds.tv
      if isKidsUIOn() = true
        bNewScreenCalledSuccess = false
        displayMenuItemDisabled(m.constants.ui.homeScreenTopNavIds.tv)
      else if isParentalControlsAdultLevel() = false
        bNewScreenCalledSuccess = false
        displayMenuItemDisabled(m.constants.ui.homeScreenTopNavIds.tv, "teens")
      else
        showTVScreen()
        bNewScreenCalledSuccess = true
      end if
    else if itemSelectedId = m.constants.ui.homeScreenTopNavIds.linearEPG
      if isKidsUIOn() = true
        bNewScreenCalledSuccess = false
        displayMenuItemDisabled(m.constants.ui.homeScreenTopNavIds.linearEPG)
      else if isParentalControlsAdultLevel() = false
        bNewScreenCalledSuccess = false
        displayMenuItemDisabled(m.constants.ui.homeScreenTopNavIds.linearEPG, "teens")
      else
        showDefaultEPGScreen()
        bNewScreenCalledSuccess = true
      end if
    else if itemSelectedId = m.constants.ui.sideNavIds.settings
      if isKidsUIOn() <> true
        setUiMode(m.constants.ui.modes.standard)
      end if

      homeScreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
      if homeScreen <> invalid
        '//ensure the homescreen is enabled again since when the user backs out of the settings page, he will be returned to the home screen
        homeScreen.enabled = true
      end if
      showSettingsScreen()
      bNewScreenCalledSuccess = true
    else if itemSelectedId = m.constants.ui.sideNavIds.exit
      topScreen = getCurrentScreen()
      displayExitModal(topScreen.trackingPageInfo)
      bNewScreenCalledSuccess = false
    end if

    if bNewScreenCalledSuccess = true
      hideNavMenu(false)
    end if
  else
    '//if currentScreen no longer = the screen that
    '//same item was selected, do nothing other than closing the menu
    hideNavMenu(false)
    focusCurrentScreen()
  end if

  '//Dispatch what side nav button was selected. Do this after the app has reacted to the side nav selection and the current screen has had a chance to change based on the side nav selection
  if currentScreenNow <> invalid
    interactionEvent = getSideNavInteractionEvent(currentScreenNow, m.Tracking, "confirm")

    m.trackingLoggingTask.trackEvent = interactionEvent
  end if
End Function


Function displayMenuItemDisabled(sMenuItemID, parental = "")
  currentScreenNow = getCurrentScreen()
  sTitle = getTranslation("dialog_errorOops_title")
  sDialogSubTypeValue = ""
  if sMenuItemID = m.constants.ui.sideNavIds.channels
    sTitle = getTranslation("dialog_channelsDisabled_title")
    sDialogSubTypeValue = "kids-mode-channels"
    '//::TODO:: Because movies, tv shows, espanol, and live TV are displayed in the top nav, then no need to have code to show a dialog window for these options
    '//         Get rid of this code and any supporting code in this file once it has been determined that top nav is here to stay. Once it has been decided to have the topNav on FireTV
  else if sMenuItemID = m.constants.ui.sideNavIds.espanol
    sTitle = getTranslation("dialog_espanolDisabled_title")
    sDialogSubTypeValue = "kids-mode-espanol"
  end if

  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: "EXIT_KIDS_MODE"
      pageOneof: m.Tracking.getAnalyticsPage(currentScreenNow.trackingPageInfo.pageType, currentScreenNow.trackingPageInfo.pageValues)
      dialog_action: "SHOW"
      dialog_sub_type: sDialogSubTypeValue
    }
  }

  if parental = "teens"
    sDescription = getTranslation("dialog_sideNavItemDisabled_Parental_description")
  else
    sDescription = getTranslation("dialog_sideNavItemDisabled_description")
  end if
  showSimpleInstantResumableModal(sTitle, sDescription, [], dialogEvent, m.trackingLoggingTask)

  ' reset the selected item indicator in the side nav to the current screen, since selecting search will set it to search
  sideNavId = m.constants.ui.screenIdToSideNavId[currentScreenNow.id]
  updateSideNavSelected(sideNavId)
End Function


Function enableKidsModeFromSideNav()
  setUiMode(m.constants.ui.modes.kids)
  refreshScreenAfterParentalChanges()
  displayDefaultBackground()
  showDefaultHomeScreen()
  homeSideNavID = m.constants.ui.screenIdToSideNavId[m.constants.ui.screenIds.homeScreen]
  focusSideNavOption(homeSideNavID)
End Function


Function disableKidsModeFromSideNav()
  setUiMode(m.constants.ui.modes.standard)
  refreshScreenAfterParentalChanges()

  showDefaultHomeScreen()
  homeSideNavID = m.constants.ui.screenIdToSideNavId[m.constants.ui.screenIds.homeScreen]
  focusSideNavOption(homeSideNavID)

  ' Since we are queuing braze in app messages when the application is in kids mode when the user exits kids mode
  ' We are going to process any queued messages.
  processQueuedInAppMessage()
End Function


' The user selected to view the settings screen from the exit kids mode with parental controls on modal.
Function onKidsModeSettingsCall()
  hideNavMenu(false)
  showSettingsScreen()
End Function


'@param b: Boolean, setting to true opens the side nav, setting to false closes the side nav.
Function openSideNav(b = true)
  m.SideNav.opened = b
  if b = false
    topScreen = getCurrentScreen()
    sideNavId = m.constants.ui.screenIdToSideNavId[topScreen.id]
    itemSelectedId = m.SideNav.itemSelectedId
    if itemSelectedId = m.constants.ui.sideNavIds.kidsMode AND sideNavId <> invalid
      '//if the sidenav has been closed and the kidsNav had been last selected; it is currently in focus,
      '//   then change the focus to the option relating to the current screen
      focusSideNavOption(sideNavId)
    end if
  end if
End Function



' @screen: roSGNode, the current screen
' @trackingLib: assocArray, TubiTracking module
' @userInteraction: string, "off" or "on" or "confirm", dictates the user interaction type
Function getSideNavInteractionEvent(screen, trackingLib, userInteraction)
  event = invalid
  pageType = ""
  pageValues = {}

  if screen <> invalid AND screen.trackingPageInfo <> invalid
    pageType = screen.trackingPageInfo.pageType
    pageValues = screen.trackingPageInfo.pageValues

    userInteractionValue = ""
    sideNavId = ""
    if userInteraction = "on"
      userInteractionValue = "TOGGLE_ON"
      sideNavId = m.SideNav.itemCurrentId
    else if userInteraction = "off"
      userInteractionValue = "TOGGLE_OFF"
      sideNavId = m.SideNav.itemCurrentId
    else if userInteraction = "confirm"
      userInteractionValue = "CONFIRM"
      sideNavId = m.SideNav.itemSelectedId
    else
      '//This should never happen as long as userInteraction is set as one of the approved strings
      return event
    end if

    leftSideNavComponent = {
      left_nav_section: trackingLib.sideNavPageMap[sideNavId]
    }

    event = {
      type: "component_interaction"
      values: {
        pageOneof: m.Tracking.getAnalyticsPage(pageType, pageValues)
        componentOneof: m.Tracking.getAnalyticsComponent("left_side_nav_component", leftSideNavComponent)
        user_interaction: userInteractionValue
      }
    }
  end if
  return event
End Function



Function displayNavMenu(shouldTrackComponentInteraction = true)
  bSideNavOpened = m.SideNav.opened
  m.SideNav.setFocus(true)
  if bSideNavOpened = false
    openSideNav()
    if m.nOriginalScreenStackX = invalid
      m.nOriginalScreenStackX = m.ScreenStack.translation[0]
    end if

    slideTo(m.ScreenStack, [m.nOriginalScreenStackX + m.SideNav.width, m.ScreenStack.translation[1]], .2)

    topScreen = getCurrentScreen()
    if topScreen <> invalid
      topScreen.enabled = false

      if shouldTrackComponentInteraction = true
        interactionEvent = getSideNavInteractionEvent(topScreen, m.Tracking, "on")
        m.trackingLoggingTask.trackEvent = interactionEvent
      end if
    end if
  end if
End Function


Function hideNavMenu(shouldTrackComponentInteraction = true)
  if m.SideNav.opened = true
    openSideNav(false)

    slideTo(m.ScreenStack, [m.nOriginalScreenStackX, m.ScreenStack.translation[1]], .3)

    topScreen = getCurrentScreen()
    if topScreen <> invalid
      if topScreen.hasField("enabled")
        topScreen.enabled = true
      end if

      if shouldTrackComponentInteraction = true
        interactionEvent = getSideNavInteractionEvent(topScreen, m.Tracking, "off")
        m.trackingLoggingTask.trackEvent = interactionEvent
      end if

    end if
  end if
End Function


' @screen: roSGNode, a screen component, typically extending BaseScreen
'
' @returns: string, the side nav id associated with the passed in screen. For instance,
'                   because of the side nav, home, movies, and tv screens, are all associated with the
'                   "Home" side nav item. Settings screen is associated with the "Settings" side nav item.
Function getSideNavIdAssociatedWithScreen(screen)
  sideNavId = ""

  idsAssociatedWithHome = {}
  isTopNavRemoveExperiementEnabled = getExperimentResource("roku_remove_top_nav", "roku_remove_top_nav_v1", false).enabled

  if isTopNavRemoveExperiementEnabled = false
    idsAssociatedWithHome[m.constants.ui.screenIds.homeScreen] = true
    idsAssociatedWithHome[m.constants.ui.screenIds.movieScreen] = true
    idsAssociatedWithHome[m.constants.ui.screenIds.tvScreen] = true

    '//if the new EPG live TV option is in the homescreen top nav, not side nav
    idsAssociatedWithHome[m.constants.ui.screenIds.epgScreen] = true
  end if

  if screen.id <> invalid
    if idsAssociatedWithHome[screen.id] <> invalid
      sideNavId = m.constants.ui.sideNavIds.home
    else if m.constants.ui.screenIdToSideNavId[screen.id] <> invalid
      sideNavId = m.constants.ui.screenIdToSideNavId[screen.id]
    else if isTopNavRemoveExperiementEnabled = true AND m.constants.ui.screenIdToTopNavId[screen.id] <> invalid
      'We moved topNav items to the side nav as part of the roku_remove_top_nav_v1 experiement.
      'So we are checking any topnav id's associated with the screen to make sure to load the correct screen.
      sideNavId = m.constants.ui.screenIdToTopNavId[screen.id]
    end if
  end if

  return sideNavId
End Function
