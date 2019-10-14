Function initSideNav()
  m.SideNav.unobserveFieldScoped("itemSelectedId")
  m.SideNav.observeFieldScoped("itemSelectedId", "onSideNavItemSelected")
  m.global.unobserveFieldScoped("authInfo")
  m.global.observeFieldScoped("authInfo", "onSideNavSignedIn")
  m.sSideNavItemSelectedId = invalid
  m.sSideNavCurrentScreen  = invalid
  onSideNavSignedIn()
  if m.kidsModeFeatureOn = false
    m.SideNav.kidsModeValues = {
      on: false, 
      featureOn: m.kidsModeFeatureOn
    }
  end if
End Function


'put the side nav back into a default state (ie. closed and focused on home)
Function resetSideNav(shouldTrackComponentInteraction = true)
  hideNavMenu(shouldTrackComponentInteraction)
  homeId = m.constants.ui.sideNavIds.home
  focusSideNavOption(homeId)
End Function


' @sID: string: one of the menu item ids. A list of ids can be found in constants.ui.sideNavIds
Function focusSideNavOption(sID)
  m.SideNav.itemRequested = sID
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
  sName = ""
  authInfo = m.global.authInfo
  if authInfo <> invalid
    sGreeting = "Hi "
    if authInfo.firstName <> invalid
      sName = sGreeting + authInfo.firstName
    else if authInfo.name <> invalid
      sName = sGreeting + authInfo.name
    end if
  end if
  m.SideNav.userName = sName
End Function


Function setKidsModeInSideNav(isEnabled = true)
  bLimited = false
  if isEnabled = true
    sIconTitle = m.constants.ui.terms.sideNav.kidsModeEnabled 
  else
    sIconTitle = m.constants.ui.terms.sideNav.kidsModeDisabled 
  end if

  if isKidsModeEnabledByParentalControls() = true
    '// the user is set with kids permissions, so instruct the side nav to not allow the kids mode button to do everything it can
    bLimited = true
    sIconTitle = m.constants.ui.terms.sideNav.kidsModeEnabled 
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
  if m.sSideNavCurrentScreen  <> invalid and currentScreenNow <> invalid
    '//check if we are viewing the same screen. If not but sSideNavItemSelectedId is still the same as the input, then user navigated away from root page
    if (m.sSideNavCurrentScreen.subtype() = currentScreenNow.subtype()) then bSameScreen = true
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

          sTitle = "Exit Kids"
          sDescription = "Do you have permission from your parents to leave Tubi Kids? If you exit you will see titles rated PG-13 and above."
          showSimpleModal(sTitle, sDescription, ["Exit Kids", "Cancel"], dialogEvent, m.trackingLoggingTask, onKidsModeExit)
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

          dialogEvent = {
            type: "dialog"
            values: {
              dialog_type: "INFORMATION" 'DialogType enum  TODO: change to "EXIT_KIDS_MODE" when it is available in protos
              pageOneof: m.Tracking.getAnalyticsPage(currentScreenNow.trackingPageInfo.pageType, currentScreenNow.trackingPageInfo.pageValues)
              dialog_action: "SHOW"
              dialog_sub_type: "exit-kids-parental"
            }
          }

          sTitle = "Exit Kids"
          sDescription = "To exit Kids, please update your parental controls in account settings."
          showSimpleModal(sTitle, sDescription, ["Go To Settings", "Cancel"], dialogEvent, m.trackingLoggingTask, onKidsModeSettingsCall)
        else 
          '//This use case should never happen. If the user has parental controls set to kids, then that instantly turns on kids mode,
          '//   so there will never be an enter kids mode mode when parental controls is turned to kids.
        end if

      end if
    else if itemSelectedId = m.constants.ui.sideNavIds.search
      '//display the search
      if m.kidsModeEnabled = true
        bNewScreenCalledSuccess = false

        dialogEvent = {
          type: "dialog"
          values: {
            dialog_type: "INFORMATION" 'DialogType enum  TODO: change to "EXIT_KIDS_MODE" when it is available in protos
            pageOneof: m.Tracking.getAnalyticsPage(currentScreenNow.trackingPageInfo.pageType, currentScreenNow.trackingPageInfo.pageValues)
            dialog_action: "SHOW"
            dialog_sub_type: "kids-mode-search"
          }
        }

        sTitle = "Search Disabled"
        sDescription = "Please exit Tubi Kids to use this feature."
        showSimpleModal(sTitle, sDescription, [], dialogEvent, m.trackingLoggingTask)

        ' reset the selected item indicator in the side nav to the current screen, since selecting search will set it to search
        sideNavId = m.constants.ui.screenIdToSideNavId[currentScreenNow.id]
        updateSideNavSelected(sideNavId)
      else 
        showSearchScreen(m.constants)
        bNewScreenCalledSuccess = true
      end if
    else if itemSelectedId = m.constants.ui.sideNavIds.home
      showHomeScreen(m.constants, authInfo)
      bNewScreenCalledSuccess = true
    else if itemSelectedId = m.constants.ui.sideNavIds.channels
      if m.kidsModeEnabled = true
        bNewScreenCalledSuccess = false

        dialogEvent = {
          type: "dialog"
          values: {
            dialog_type: "INFORMATION" 'DialogType enum  TODO: change to "EXIT_KIDS_MODE" when it is available in protos
            pageOneof: m.Tracking.getAnalyticsPage(currentScreenNow.trackingPageInfo.pageType, currentScreenNow.trackingPageInfo.pageValues)
            dialog_action: "SHOW"
            dialog_sub_type: "kids-mode-channels"
          }
        }

        sTitle = "Channels Disabled"
        sDescription = "Please exit Tubi Kids to use this feature."
        showSimpleModal(sTitle, sDescription, [], dialogEvent, m.trackingLoggingTask)

        ' reset the selected item indicator in the side nav to the current screen, since selecting search will set it to search
        sideNavId = m.constants.ui.screenIdToSideNavId[currentScreenNow.id]
        updateSideNavSelected(sideNavId)
      else
        showChannelListScreen(m.constants, "MENU")
        bNewScreenCalledSuccess = true
      end if
    else if itemSelectedId = m.constants.ui.sideNavIds.categories
      showCategoryListScreen(m.constants, "MENU")
      bNewScreenCalledSuccess = true
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
      m.sSideNavCurrentScreen  = currentScreen()
    end if
  else
    '//if currentScreen no longer = the screen that
    '//same item was selected, do nothing other than closing the menu
    hideNavMenu(false)
  end if
End Function


Function enableKidsModeFromSideNav(bEnable = true)
  saveKidsModeToMemory(bEnable)
  enableKidsModeUI(bEnable)
  refreshScreenAfterParentalChanges()
  screen = currentScreen()
  
  if bEnable = true
    if screen <> invalid and (screen.id = m.constants.ui.screenIds.searchScreen or screen.id = m.constants.ui.screenIds.channelListScreen)
      '//If the current screen is one of the pages that should be disabled during kids mode, then take user to homescreen    
      showHomeScreen(m.constants, m.authInfo)

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
    m.SideNav.opened = true
    if m.nOriginalSideNavX = invalid
      m.nOriginalSideNavX = m.SideNav.translation[0]
    end if
    if m.nOriginalScreenStackX = invalid
      m.nOriginalScreenStackX = m.ScreenStack.translation[0]
    end if

    slideTo(m.SideNav, [0, m.SideNav.translation[1]], .2)
    slideTo(m.ScreenStack, [m.nOriginalScreenStackX + m.SideNav.width, m.ScreenStack.translation[1]], .2)

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
    m.SideNav.opened = false
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