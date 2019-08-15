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


Function onSideNavItemSelected()
  itemSelected = m.SideNav.itemSelected
  authInfo = m.global.authInfo
  bSameScreen = false
  currentScreenNow = currentScreen()
  if m.sSideNavCurrentScreen  <> invalid and currentScreenNow <> invalid
    '//check if we are viewing the same screen. If not but sSideNavItemSelected is still the same as the input, then user navigated away from root page     
    if (m.sSideNavCurrentScreen.subtype() = currentScreenNow.subtype()) then bSameScreen = true
  end if

  if m.sSideNavItemSelected <> itemSelected or bSameScreen = false or itemSelected = "exit"
    bSuccess = false

'//::TODO::SIDENAV - (SHOW DESIGNERS as this might be a good bug) only root pages should display the menu. Listen to the stack and hide menu when when more than one screen is in stack. Also ensure the left button does not animate the sidenav for subPages
    if itemSelected = m.constants.ui.sideNavIds.profile
      if authInfo = invalid
        '//if user is not signed in, then bring up the sign on page; otherwise, don't do anything
        startSignIn(true)
        bSuccess = true
      else
        '//Bring user to the settings page and select the signout option
        showSettingsScreen("SignInOutButton")
        bSuccess = true
      end if
    else if itemSelected = m.constants.ui.sideNavIds.search
      '//display the search
      showSearchScreen(m.constants)
      bSuccess = true
    else if itemSelected = m.constants.ui.sideNavIds.home
      showHomeScreen(m.constants, authInfo)
      bSuccess = true
    else if itemSelected = m.constants.ui.sideNavIds.channels
      showChannelListScreen(m.constants, "MENU")
      bSuccess = true
    else if itemSelected = m.constants.ui.sideNavIds.categories
      showCategoryListScreen(m.constants, "MENU")
      bSuccess = true
    else if itemSelected = m.constants.ui.sideNavIds.settings
      homeScreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
      if homeScreen <> invalid
        '//ensure the homescreen is enabled again since when the user backs out of the settings page, he will be returned to the home screen
        homeScreen.enabled = true
      end if
      showSettingsScreen()
      bSuccess = true
    else if itemSelected = m.constants.ui.sideNavIds.exit
      displayExitModule()
      bSuccess = true
    end if

    if bSuccess = true
      if itemSelected <> m.constants.ui.sideNavIds.exit
        hideNavMenu(false)
      end if
      m.sSideNavItemSelected = itemSelected
      m.sSideNavCurrentScreen  = currentScreen()
    end if
  else
    '//if currentScreen no longer = the screen that
    '//same item was selected, do nothing other than closing the menu
    hideNavMenu(false)
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