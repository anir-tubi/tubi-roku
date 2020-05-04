Function initSideNav()
  m.SideNav.unobserveFieldScoped("itemSelectedId")
  m.SideNav.observeFieldScoped("itemSelectedId", "onSideNavItemSelected")
  m.global.unobserveFieldScoped("authInfo")
  m.global.observeFieldScoped("authInfo", "onSideNavSignedIn")
  m.sSideNavItemSelectedId = invalid
  m.sSideNavCurrentScreen = invalid

  if m.kidsModeFeatureOn = false
    m.SideNav.kidsModeValues = {
      on: false,
      featureOn: m.kidsModeFeatureOn
    }
  end if
  
  bFeatureMovieTVAllowed = false
  if m.constants.deviceInfo.countryCode <> invalid and (m.constants.deviceInfo.countryCode = "US")
    bFeatureMovieTVAllowed = true
  end if

  bFeatureChannelsAllowed = false
  if m.constants.deviceInfo.countryCode <> invalid and (m.constants.deviceInfo.countryCode = "US")
     bFeatureChannelsAllowed = true
  end if

  if bFeatureMovieTVAllowed = false
    '//Tell the sideNav to stop displaying the movies/TV menu items
    m.SideNav.displayMoviesTV = false 
  end if

  if bFeatureChannelsAllowed = false
    '//Tell the sideNav to stop displaying the channel menu item
    m.SideNav.displayChannels = false 
  end if

  '//set the SideNav Strings by calling onSideNavSignedIn()
  onSideNavSignedIn()
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


' Change the appearance of some side nav elements when the user data has changed
Function onSideNavSignedIn()
  tubiLog("onSideNavSignedIn")
  sName = getTranslation("menu_signIn")

  authInfo = m.global.authInfo
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


Function setKidsModeInSideNav(isEnabled = true)
  bLimited = false
  if isEnabled = true
    sIconTitle = getTranslation("menu_exitKids")
  else
    sIconTitle = getTranslation("menu_kids")
  end if
  if isKidsModeEnabledByParentalControls() = true
    '// the user is set with kids permissions, so instruct the side nav to not allow the kids mode button to do everything it can
    bLimited = true
    sIconTitle = getTranslation("menu_exitKids")
  end if

  m.SideNav.kidsModeValues = {
    featureOn: m.kidsModeFeatureOn,
    on: isEnabled
    grayedOut: bLimited,
    title: sIconTitle
  }
End Function


Function onSideNavItemSelected()
  itemSelectedId = m.SideNav.itemSelectedId
  itemSelected = m.SideNav.itemSelected
  authInfo = m.global.authInfo
  bSameScreen = false
  currentScreenNow = currentScreen()
  if m.sSideNavCurrentScreen <> invalid and currentScreenNow <> invalid
    '//check if we are viewing the same screen. If not but sSideNavItemSelectedId is still the same as the input, then user navigated away from root page
    if (m.sSideNavCurrentScreen.subtype() = currentScreenNow.subtype() and m.sSideNavCurrentScreen.id = currentScreenNow.id) then bSameScreen = true
  end if

  if m.sSideNavItemSelectedId <> itemSelectedId or bSameScreen = false
    '// If a new screen is to be called, then collapse the side nav and remember which side nav button was last clicked
    bNewScreenCalledSuccess = false
    if itemSelectedId = m.constants.ui.sideNavIds.profile
      if authInfo = invalid
        '//if user is not signed in, then bring up the sign on page; otherwise, don't do anything
        startSignIn(true)
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

        if m.kidsModeEnabled = true
          dialogEvent = {
            type: "dialog"
            values: {
              dialog_type: "INFORMATION" 'DialogType enum  TODO: change to "KIDS_MODE" when it is available in protos
              pageOneof: m.Tracking.getAnalyticsPage(currentScreenNow.trackingPageInfo.pageType, currentScreenNow.trackingPageInfo.pageValues)
              dialog_action: "SHOW"
              dialog_sub_type: "exit-kids-mode"
            }
          }

          sTitle = getTranslation("dialog_kidsExit_title")
          sDescription = getTranslation("dialog_kidsExit_description")
          '//::TODO::locale - should we 1st check if there is an error specifc OK/cancel button? If, not then should we get the generic ok/cancel button string?
          showSimpleModal(sTitle, sDescription, [getTranslation("dialog_kidsExit_button_ok"), getTranslation("dialog_button_cancel")], dialogEvent, m.trackingLoggingTask, onKidsModeExit)
        else
          dialogEvent = {
            type: "dialog"
            values: {
              dialog_type: "INFORMATION" 'DialogType enum  TODO: change to "KIDS_MODE" when it is available in protos
              pageOneof: m.Tracking.getAnalyticsPage(currentScreenNow.trackingPageInfo.pageType, currentScreenNow.trackingPageInfo.pageValues)
              dialog_action: "ACCEPT_DELIBERATE"
              dialog_sub_type: "enter-kids-mode"
            }
          }
          m.trackingLoggingTask.trackEvent = dialogEvent
          enableKidsModeFromSideNav()
        end if
      else
        if m.kidsModeEnabled = true
          '// this mode is locked down and a child need's a parent's intervention to exit the mode

          dialogEvent = {
            type: "dialog"
            values: {
              dialog_type: "INFORMATION" 'DialogType enum  TODO: change to "EXIT_KIDS_MODE" when it is available in protos
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
      showSearchScreen(m.constants)
      bNewScreenCalledSuccess = true
    else if itemSelectedId = m.constants.ui.sideNavIds.home
      showHomeScreen(m.constants, authInfo)
      bNewScreenCalledSuccess = true
    else if itemSelectedId = m.constants.ui.sideNavIds.channels
      if m.kidsModeEnabled = true
        bNewScreenCalledSuccess = false
        displayMenuItemDisabled(m.constants.ui.sideNavIds.channels)
      else
        showChannelListScreen(m.constants, m.constants.ui.terms.menu)
        bNewScreenCalledSuccess = true
      end if
    else if itemSelectedId = m.constants.ui.sideNavIds.categories
      showCategoryListScreen(m.constants, m.constants.ui.terms.menu)
      bNewScreenCalledSuccess = true
    else if itemSelectedId = m.constants.ui.sideNavIds.movies
      if m.kidsModeEnabled = true
        bNewScreenCalledSuccess = false
        displayMenuItemDisabled(m.constants.ui.sideNavIds.movies)
      else
        showMoviesScreen()
        bNewScreenCalledSuccess = true
      end if
    else if itemSelectedId = m.constants.ui.sideNavIds.tv
      if m.kidsModeEnabled = true
        bNewScreenCalledSuccess = false
        displayMenuItemDisabled(m.constants.ui.sideNavIds.tv)
      else
        showTVScreen()
        bNewScreenCalledSuccess = true
      end if
    else if itemSelectedId = m.constants.ui.sideNavIds.settings
      homeScreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
      if homeScreen <> invalid
        '//ensure the homescreen is enabled again since when the user backs out of the settings page, he will be returned to the home screen
        homeScreen.enabled = true
      end if
      showSettingsScreen()
      bNewScreenCalledSuccess = true
    else if itemSelectedId = m.constants.ui.sideNavIds.exit
      topScreen = currentScreen()
      displayExitModal(topScreen.trackingPageInfo)
      bNewScreenCalledSuccess = false
    end if

    if bNewScreenCalledSuccess = true
      hideNavMenu(false)
      m.sSideNavItemSelectedId = itemSelectedId
      m.sSideNavCurrentScreen = currentScreen()
    end if
  else
    '//if currentScreen no longer = the screen that
    '//same item was selected, do nothing other than closing the menu
    hideNavMenu(false)
  end if
End Function


Function displayMenuItemDisabled(sMenuItemID)
  currentScreenNow = currentScreen()
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
  end if

  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: "INFORMATION" 'DialogType enum  TODO: change to "EXIT_KIDS_MODE" when it is available in protos
      pageOneof: m.Tracking.getAnalyticsPage(currentScreenNow.trackingPageInfo.pageType, currentScreenNow.trackingPageInfo.pageValues)
      dialog_action: "SHOW"
      dialog_sub_type: sDialogSubTypeValue
    }
  }

  sDescription = getTranslation("dialog_sideNavItemDisabled_description") 
  showSimpleModal(sTitle, sDescription, [], dialogEvent, m.trackingLoggingTask)

  ' reset the selected item indicator in the side nav to the current screen, since selecting search will set it to search
  sideNavId = m.constants.ui.screenIdToSideNavId[currentScreenNow.id]
  updateSideNavSelected(sideNavId)
End Function


Function enableKidsModeFromSideNav(bEnable = true)
  enableKidsModeUI(bEnable)
  refreshScreenAfterParentalChanges()
  screen = currentScreen()

  if bEnable = true
    if screen <> invalid and (screen.id = m.constants.ui.screenIds.searchScreen or screen.id = m.constants.ui.screenIds.channelListScreen or screen.id = m.constants.ui.screenIds.movieScreen or screen.id = m.constants.ui.screenIds.tvScreen)
      '//If the current screen is one of the pages that should be disabled during kids mode, then take user to homescreen    
      showHomeScreen(m.constants, m.global.authInfo)

      homeSideNavID = m.constants.ui.screenIdToSideNavId[m.constants.ui.screenIds.homeScreen]
      focusSideNavOption(homeSideNavID)
    end if
  end if
End Function


' The user selected to view the settings screen from the exit kids mode with parental controls on modal.
Function onKidsModeSettingsCall()
  hideNavMenu(false)
  showSettingsScreen()
End Function


'@param b: Boolean, Says what the Function is. Should the sideNav be set to open? If set to false, then the opposite happens, the side nav closes.
Function openSideNav(b = true)
  m.SideNav.opened = b
  if b = false
    topScreen = currentScreen()
    sideNavId = m.constants.ui.screenIdToSideNavId[topScreen.id]
    itemSelectedId = m.SideNav.itemSelectedId
    if itemSelectedId = m.constants.ui.sideNavIds.kidsMode and sideNavId <> invalid
      '//if the sidenav has been closed and the kidsNav had been last selected; it is currently in focus,
      '//   then change the focus to the option relating to the current screen
      focusSideNavOption(sideNavId)
    end if
  end if
End Function

Function onKidsModeExit()
  enableKidsModeFromSideNav(false)
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

    leftSideNavComponent = {
      left_nav_section: trackingLib.sideNavPageMap[screen.id]
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

    if getExperimentResource("roku2", "roku_safe_area").enabled = true
      slideTo(m.ScreenStack, [273, m.ScreenStack.translation[1]], .2)
    else 
      slideTo(m.ScreenStack, [m.nOriginalScreenStackX + m.SideNav.width, m.ScreenStack.translation[1]], .2)
    end if

    topScreen = currentScreen()
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

    topScreen = currentScreen()
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