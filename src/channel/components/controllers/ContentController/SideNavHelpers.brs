Function initSideNav()
  m.SideNav.observeFieldScoped("itemSelectedId", "onSideNavItemSelected")
  m.SideNav.observeFieldScoped("navigateWithinPageInfo", "onSideNavNavigateWithinPageInfoChanged")

  m.sSideNavItemSelectedId = invalid
  m.sSideNavCurrentScreen = invalid

  m.SideNav.createMenuItems = true

  ' display Espanol, TV, Movies menu items only if the countryCode is US
  if m.constants.deviceInfo.countryCode <> "US"
    '//Tell the sideNav to stop displaying the Espanol menu item
    m.SideNav.displayEspanol = false
    '//Tell the sideNav to stop displaying the movies/TV menu items
    m.SideNav.displayMoviesTV = false
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

  ' stop displaying some side nav items if the top nav is being displayed
  if isTopNavHomeScreenEnabled() = true
    '//Tell the sideNav to stop displaying the Espanol menu item
    ' m.SideNav.displayEspanol = false
    '//Tell the sideNav to stop displaying the movies/TV menu items
    m.SideNav.displayMoviesTV = false
  end if

  'set the initial value for the sign in item string
  setSideNavSignedInItem(m.global.authInfo)
End Function


'put the side nav back into a default state (ie. closed and focused on home)
Function resetSideNav(shouldTrackComponentInteraction = true)
  hideNavMenu(shouldTrackComponentInteraction)
  homeId = m.constants.ui.sideNavIds.home
  focusSideNavOption(homeId)
End Function


' @sID: string: one of the menu item ids. A list of ids can be found in constants.ui.sideNavIds
Function focusSideNavOption(sID)
  '//::TODO:: there should be a check that a valid ID was passed. For right now assume sID is valid and correct.
  m.SideNav.itemRequested = sID '//set itemRequested so the focus is on the proper button in the sideNav
End Function


'tell the side nav to move the selected option (denoted by a stationary gray menu selector)
Function updateSideNavSelected(sideNavButtonId)
  m.SideNav.selectedItemRequested = sideNavButtonId
End Function


' Is the side nav open and in focus
Function isSideNavActive() as Boolean
  return (m.SideNav.isInFocusChain() = true and m.SideNav.opened = true)
End Function


' Change the appearance of the side nav sign in item when the user data has changed
' @authInfo: AA, authInfo as stored on m.global.authInfo
Function setSideNavSignedInItem(authInfo)
  tubiLog("SideNavHelpers.setSideNavSignedInItem")
  sName = getTranslation("menu_signIn")

  if authInfo <> invalid
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

  if currentScreen <> invalid and currentScreen.trackingPageInfo <> invalid  
    navigateWithinPageInfo.pageOneof = m.Tracking.getAnalyticsPage(currentScreen.trackingPageInfo.pageType, currentScreen.trackingPageInfo.pageValues)
    sendNavigateWithinPageInfo(navigateWithinPageInfo)
  end if
End Function


Function onSideNavItemSelected()
  itemSelectedId = m.SideNav.itemSelectedId
  itemSelected = m.SideNav.itemSelected
  authInfo = m.global.authInfo
  bSameScreen = false
  currentScreenNow = getCurrentScreen()
  if m.sSideNavCurrentScreen <> invalid and currentScreenNow <> invalid
    '//check if we are viewing the same screen. If not but sSideNavItemSelectedId is still the same as the input, then user navigated away from root page
    if (m.sSideNavCurrentScreen.subtype() = currentScreenNow.subtype() and m.sSideNavCurrentScreen.id = currentScreenNow.id and itemSelectedId <> m.constants.ui.sideNavIds.profile) then bSameScreen = true
  end if

  if m.sSideNavItemSelectedId <> itemSelectedId or bSameScreen = false
    '// If a new screen is to be called, then collapse the side nav and remember which side nav button was last clicked
    bNewScreenCalledSuccess = false
    
    ' set appropriate analytics component on the page being navigated from so NavigateToPageEvent
    ' contains all the requisite information -  NOTE: this analytic does not get reported when the user presses the sideNav button associated with the current screen
    sideNavComponentValues = {
      left_nav_section: m.Tracking.sideNavPageMap[itemSelectedId]
    }
    currentScreenNow.trackingComponentInfo = {
      componentType: "left_side_nav_component"
      componentValues: sideNavComponentValues
    }

    if itemSelectedId = m.constants.ui.sideNavIds.profile
      if isKidsUIOn() <> true
        setUiMode(m.constants.ui.modes.standard)
      end if
      
      if authInfo = invalid
        '//if user is not signed in, then bring up the sign on page; otherwise, don't do anything
        startSignIn()
        bNewScreenCalledSuccess = true
      else
        '//Bring user to the settings page and select the signout option
        showSettingsScreen("SignInOutButton")
        bNewScreenCalledSuccess = true
      end if
    else if itemSelectedId = m.constants.ui.sideNavIds.kidsMode
      sTitle = ""
      sDescription = ""
      if itemSelected.turnedOn = true
        '//If the parental control settings are not set to kids, then this action is not limited
        '// aka this mode is not locked down and can be easily exited without a parent's intervention

        if isKidsUIOn() = true
          dialogEvent = {
            type: "dialog"
            values: {
              dialog_type: "EXIT_KIDS_MODE"
              pageOneof: m.Tracking.getAnalyticsPage(currentScreenNow.trackingPageInfo.pageType, currentScreenNow.trackingPageInfo.pageValues)
              dialog_action: "SHOW"
              dialog_sub_type: "exit-kids-mode"
            }
          }

          sTitle = getTranslation("dialog_kidsExit_title")
          sDescription = getTranslation("dialog_kidsExit_description")
          '//::TODO::locale - should we 1st check if there is an error specifc OK/cancel button? If, not then should we get the generic ok/cancel button string?
          showSimpleModal(sTitle, sDescription, [getTranslation("dialog_kidsExit_button_ok"), getTranslation("dialog_button_cancel")], dialogEvent, m.trackingLoggingTask, disableKidsModeFromSideNav)
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
          showSimpleModal(sTitle, sDescription, [getTranslation("dialog_button_settings"), getTranslation("dialog_button_cancel")], dialogEvent, m.trackingLoggingTask, onKidsModeSettingsCall)
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

      showSearchScreen(m.constants)
      bNewScreenCalledSuccess = true
    else if itemSelectedId = m.constants.ui.sideNavIds.home
      if isKidsUIOn() <> true
        setUiMode(m.constants.ui.modes.standard)
      end if

      topScreen = getCurrentScreen()
      if isTopNavHomeScreenEnabled() = false
        ' if the topnav (experiment) is not enabled, then check if the current screen is not the home screen before proceeding
        '//::TODO::TopNav - get rid of this part of the IF condition once the topnav experiment is successful and complete.
        if topScreen.id <> m.constants.ui.screenIds.homeScreen
          '//if this is the homescreen, then just close the sidenav. no need to call showHomeScreen()
          showHomeScreen(m.constants, authInfo) 
        end if
      else if isCurrentScreenHomeScreen() = false or topScreen.id = m.constants.ui.screenIds.espanolScreen
        '//Don't open the homescreen if the current screen is already a homescreen type. Just need to close the side nav.
        '//::TODO::TopNav - for now, exclude the espanol screen because the spanish screen is still in the side nav for now.
        showHomeScreen(m.constants, authInfo) 
      end if

      bNewScreenCalledSuccess = true
    else if itemSelectedId = m.constants.ui.sideNavIds.channels
      if isKidsUIOn() = true
        bNewScreenCalledSuccess = false
        displayMenuItemDisabled(m.constants.ui.sideNavIds.channels)
      else
        setUiMode(m.constants.ui.modes.standard)
        showChannelListScreen(m.constants, m.constants.ui.terms.menu)
        bNewScreenCalledSuccess = true
      end if
    else if itemSelectedId = m.constants.ui.sideNavIds.categories
      if isKidsUIOn() <> true
        setUiMode(m.constants.ui.modes.standard)
      end if

      showCategoryListScreen(m.constants, m.constants.ui.terms.menu)
      bNewScreenCalledSuccess = true
    else if itemSelectedId = m.constants.ui.sideNavIds.movies
      if isKidsUIOn() = true
        bNewScreenCalledSuccess = false
        displayMenuItemDisabled(m.constants.ui.sideNavIds.movies)
      else
        setUiMode(m.constants.ui.modes.standard)
        showHideSpinner(true)
        showMoviesScreen()
        bNewScreenCalledSuccess = true
      end if
    else if itemSelectedId = m.constants.ui.sideNavIds.tv
      if isKidsUIOn() = true
        bNewScreenCalledSuccess = false
        displayMenuItemDisabled(m.constants.ui.sideNavIds.tv)
      else
        setUiMode(m.constants.ui.modes.standard)
        showHideSpinner(true)
        showTVScreen()
        bNewScreenCalledSuccess = true
      end if
    else if itemSelectedId = m.constants.ui.sideNavIds.espanol
      if isKidsUIOn() = true
        bNewScreenCalledSuccess = false
        displayMenuItemDisabled(m.constants.ui.sideNavIds.espanol)
      else if isParentalControlsAdultLevel() = false
        bNewScreenCalledSuccess = false
        displayMenuItemDisabled(m.constants.ui.sideNavIds.espanol, "teens")        
      else
        setUiMode(m.constants.ui.modes.latino)
        showHideSpinner(true)
        showEspanolScreen()
        bNewScreenCalledSuccess = true
      end if  
    else if itemSelectedId = m.constants.ui.sideNavIds.mylist
      hideNavMenu(false)
      if isKidsUIOn() <> true
        setUiMode(m.constants.ui.modes.standard)
      end if

      contentNode = CreateObject("roSGNode", "CategoryContentNode")
      contentNode.id = m.constants.ui.categoryIds.queue
      showChannelScreen(contentNode, "MENU")
      bNewScreenCalledSuccess = true
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
      m.sSideNavItemSelectedId = itemSelectedId
      m.sSideNavCurrentScreen = getCurrentScreen()
    end if
  else
    '//if currentScreen no longer = the screen that
    '//same item was selected, do nothing other than closing the menu
    hideNavMenu(false)
  end if
End Function


Function displayMenuItemDisabled(sMenuItemID, parental="")
  currentScreenNow = getCurrentScreen()
  sTitle = getTranslation("dialog_errorOops_title")
  sDialogSubTypeValue = ""
  if sMenuItemID = m.constants.ui.sideNavIds.channels
    sTitle = getTranslation("dialog_channelsDisabled_title")
    sDialogSubTypeValue = "kids-mode-channels"
  else if sMenuItemID = m.constants.ui.sideNavIds.movies
    sTitle = getTranslation("dialog_moviesDisabled_title")
    sDialogSubTypeValue = "kids-mode-movies"
  else if sMenuItemID = m.constants.ui.sideNavIds.tv
    sTitle = getTranslation("dialog_tvDisabled_title")
    sDialogSubTypeValue = "kids-mode-tv"
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
  showSimpleModal(sTitle, sDescription, [], dialogEvent, m.trackingLoggingTask)

  ' reset the selected item indicator in the side nav to the current screen, since selecting search will set it to search
  sideNavId = m.constants.ui.screenIdToSideNavId[currentScreenNow.id]
  updateSideNavSelected(sideNavId)
End Function


Function enableKidsModeFromSideNav()
  setUiMode(m.constants.ui.modes.kids)
  refreshScreenAfterParentalChanges()
  displayDefaultBackground()

  ' setting up an AA instead of having a very long if statement that checks against each
  ' of the screen ids below
  nonAvailableKidsScreens = {}
  nonAvailableKidsScreens[m.constants.ui.screenIds.searchScreen] = true
  nonAvailableKidsScreens[m.constants.ui.screenIds.channelListScreen] = true
  nonAvailableKidsScreens[m.constants.ui.screenIds.movieScreen] = true
  nonAvailableKidsScreens[m.constants.ui.screenIds.tvScreen] = true
  nonAvailableKidsScreens[m.constants.ui.screenIds.espanolScreen] = true

  screen = getCurrentScreen()
  if screen <> invalid and nonAvailableKidsScreens[screen.id] = true
    '//If the current screen is one of the pages that should be disabled during kids mode,
    ' then take user to homescreen
    showDefaultHomeScreen()
  else if screen.id = m.constants.ui.screenIds.homeScreen = true
    '//If current screen is already the homescreen, then ensure the topNav is at the correct visible state
    screen.enableTopNav = isTopNavHomeScreenEnabled()
  end if

  homeSideNavID = m.constants.ui.screenIdToSideNavId[m.constants.ui.screenIds.homeScreen]
  focusSideNavOption(homeSideNavID)
End Function


Function disableKidsModeFromSideNav()
  setUiMode(m.constants.ui.modes.standard)
  refreshScreenAfterParentalChanges()
  displayDefaultBackground()
  homeSideNavID = m.constants.ui.screenIdToSideNavId[m.constants.ui.screenIds.homeScreen]
  focusSideNavOption(homeSideNavID)
  screen = getCurrentScreen()

  if screen.id = m.constants.ui.screenIds.homeScreen = true
    '//If current screen is already the homescreen, then ensure the topNav is at the correct visible state
    screen.enableTopNav = isTopNavHomeScreenEnabled()
  end if
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
    if itemSelectedId = m.constants.ui.sideNavIds.kidsMode and sideNavId <> invalid
      '//if the sidenav has been closed and the kidsNav had been last selected; it is currently in focus,
      '//   then change the focus to the option relating to the current screen
      focusSideNavOption(sideNavId)
    end if
  end if
End Function


' @screen: roSGNode, the current screen
' @trackingLib: assocArray, TubiTracking module
' @offOrOn: string, "off" or "on", dictates the toggle type
Function getSideNavInteractionEvent(screen, trackingLib, offOrOn)
  event = invalid
  pageType = ""
  pageValues = {}

  if screen <> invalid and screen.trackingPageInfo <> invalid
    pageType = screen.trackingPageInfo.pageType
    pageValues = screen.trackingPageInfo.pageValues

    focusedSideNavId = m.SideNav.itemCurrentId
    leftSideNavComponent = {
      left_nav_section: trackingLib.sideNavPageMap[focusedSideNavId]
    }

    toggle = ""
    if offOrOn = "on"
      toggle = "TOGGLE_ON"
    else if offOrOn = "off"
      toggle = "TOGGLE_OFF"
    end if

    event = {
      type: "component_interaction"
      values: {
        pageOneof: m.Tracking.getAnalyticsPage(pageType, pageValues)
        componentOneof: m.Tracking.getAnalyticsComponent("left_side_nav_component", leftSideNavComponent)
        user_interaction: toggle
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
    if m.nOriginalSideNavX = invalid
      m.nOriginalSideNavX = m.SideNav.translation[0]
    end if
    if m.nOriginalScreenStackX = invalid
      m.nOriginalScreenStackX = m.ScreenStack.translation[0]
    end if

    slideTo(m.SideNav, [0, m.SideNav.translation[1]], .2)
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
    focusCurrentScreen() '//This will set the current focus back to the screenstack items

    slideTo(m.SideNav, [m.nOriginalSideNavX, m.SideNav.translation[1]], .3)
    slideTo(m.ScreenStack, [m.nOriginalScreenStackX, m.ScreenStack.translation[1]], .3)

    topScreen = getCurrentScreen()
    if topScreen <> invalid
      topScreen.enabled = true

      'set up analytics for unfocusing side nav component
      pageType = ""
      pageValues = {}
      if topScreen.trackingPageInfo <> invalid
        pageType = topScreen.trackingPageInfo.pageType
        pageValues = topScreen.trackingPageInfo.pageValues
      end if

      if shouldTrackComponentInteraction = true
        interactionEvent = getSideNavInteractionEvent(topScreen, m.Tracking, "off")
        m.trackingLoggingTask.trackEvent = interactionEvent
      end if
    end if
  end if
End Function