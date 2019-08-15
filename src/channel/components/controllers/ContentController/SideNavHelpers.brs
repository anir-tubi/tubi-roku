Function initSideNav()
  m.SideNav.observeFieldScoped("itemSelected", "onSideNavItemSelected")
  m.global.observeFieldScoped("authInfo", "onSideNavSignedIn")
  m.sSideNavItemSelected = invalid
  m.sSideNavCurrentScreen  = invalid
  onSideNavSignedIn()
End Function

Function focusSideNavOption(sID)
  m.SideNav.itemRequested = sID
End Function


' Is the side nav open and in focus
Function isSideNavActive() as Boolean
  return (m.SideNav.isInFocusChain() = true and m.SideNav.opened = true)
End Function 

' Change the appearance of some side nav elements when the user data has changed
Function onSideNavSignedIn()
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

Function inFullKidsMode() as Boolean
  bFull = true
  authInfo = m.global.authInfo
  if authInfo <> invalid
    if authInfo.parentalrating < 2
      '//parental controls is set to kids state so Kids Mode is limited
      bFull = false
    end if
  end if
  return bFull
End Function

Function setKidsModeInSideNav()

  bKidsModeOn = isKidsModeEnabled()
  bLimited = false
  if bKidsModeOn = true
    sIconTitle = m.constants.ui.terms.sideNav.kidsModeEnabled 
  else
    sIconTitle = m.constants.ui.terms.sideNav.kidsModeDisabled 
  end if
  authInfo = m.global.authInfo
  if authInfo <> invalid
    if inFullKidsMode() = false
      bLimited = true
      sIconTitle = m.constants.ui.terms.sideNav.kidsModeEnabled 
    end if
  end if
  
  m.SideNav.kidsModeValues = {
    grayedOut: bLimited, 
    title: sIconTitle
  }
End Function


Function onSideNavItemSelected()
  itemSelected = m.SideNav.itemSelected
  authInfo = m.global.authInfo
  bSameScreen = false
  currentScreenNow = currentScreen()
  if m.sSideNavCurrentScreen  <> invalid and currentScreenNow <> invalid
    '//check if we are viewing the same screen. If not but sSideNavItemSelected is still the same as the input, then user navigated away from root page     
    if (m.sSideNavCurrentScreen.subtype() = currentScreenNow.subtype()) then bSameScreen = true
  end if

  if m.sSideNavItemSelected <> itemSelected or bSameScreen = false
    '// If a new screen is to be called, then collapse the side nav and remember which side nav button was last clicked
    bNewScreenCalledSuccess = false 
    if itemSelected = m.constants.ui.sideNavIds.profile
      if authInfo = invalid
        '//if user is not signed in, then bring up the sign on page; otherwise, don't do anything
        startSignIn(true)
        bNewScreenCalledSuccess = true
      else
        '//Bring user to the settings page and select the signout option
        showSettingsScreen("SignInOutButton")
        bNewScreenCalledSuccess = true
      end if
    else if itemSelected = m.constants.ui.sideNavIds.kidsMode
      bModeOn = isKidsModeEnabled()
      sTitle = ""
      sDescription = ""
      if inFullKidsMode() = true
        '//If we are in full kids mode: aka parental control settings are not set to kids
        
        if bModeOn = true
          bNewScreenCalledSuccess = false
          sTitle = "Exit Kids"
          sDescription = "Exit Kids to see titles rated PG-13 and above."
          errorObj = createErrorObject(m.constants.errors.context.kidsMode, "", sDescription, "", sTitle, false)
          showErrorModal(errorObj, onKidsModeErrorExit, [], invalid, [], ["Exit Kids", "Cancel"])
        else 
          bNewScreenCalledSuccess = false 
          enableKidsModeFromSideNav()
          hideNavMenu(false)
        end if
      else 
        '//User is set as a kid, so they are not allowed to change the kids mode, so instead show them an error modal
        
        if bModeOn = true
          bNewScreenCalledSuccess = false
          sTitle = "Exit Kids"
          sDescription = "To exit Kids, please update your parental controls in account settings."
          errorObj = createErrorObject(m.constants.errors.context.kidsMode, "", sDescription, "", sTitle, false)
          showErrorModal(errorObj, onKidsModeErrorSettingsCall, [], invalid, [], ["Go To Settings", "Cancel"])
        else 
          '//This use case should never happen. If the user has parental controls set to kids, then that instantly turns on kids mode,
          '//   so there will never be an enter kids mode mode when parental controls is turned to kids.
        end if

      end if
    else if itemSelected = m.constants.ui.sideNavIds.search
      '//display the search
      showSearchScreen(m.constants)
      bNewScreenCalledSuccess = true
    else if itemSelected = m.constants.ui.sideNavIds.home
      showHomeScreen(m.constants, authInfo)
      bNewScreenCalledSuccess = true
    else if itemSelected = m.constants.ui.sideNavIds.channels
      showChannelListScreen(m.constants, "MENU")
      bNewScreenCalledSuccess = true
    else if itemSelected = m.constants.ui.sideNavIds.categories
      showCategoryListScreen(m.constants, "MENU")
      bNewScreenCalledSuccess = true
    else if itemSelected = m.constants.ui.sideNavIds.settings
      homeScreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
      if homeScreen <> invalid
        '//ensure the homescreen is enabled again since when the user backs out of the settings page, he will be returned to the home screen
        homeScreen.enabled = true
      end if
      showSettingsScreen()
      bNewScreenCalledSuccess = true
    else if itemSelected = m.constants.ui.sideNavIds.exit
      displayExitModule()
      bNewScreenCalledSuccess = false
    end if

    if bNewScreenCalledSuccess = true
      hideNavMenu(false)
      m.sSideNavItemSelected = itemSelected
      m.sSideNavCurrentScreen  = currentScreen()
    end if
  else
    '//if currentScreen no longer = the screen that
    '//same item was selected, do nothing other than closing the menu
    hideNavMenu(false)
  end if
End Function

Function enableKidsModeFromSideNav(bEnable = true)
  enableKidsMode(bEnable)
  '//refresh all cached screens once the kids mode has changed. 
    refreshScreenAfterParentalChanges()
End Function

' The user selected to view the setttings screen from the kids mode limited error screen.
Function onKidsModeErrorSettingsCall()
  hideNavMenu(false)
  showSettingsScreen()
End Function

Function onKidsModeErrorExit()
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