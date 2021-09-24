Function init()
  m.constants  = getConstantsFromGlobal()
  theme = getThemeFromGlobal()
  
  Request = TubiRequest(m.constants.settings)
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)

  m.top.trackingPageInfo = {
    pageType: "onboarding_page"
    pageValues: {
                  page_sequence: -1
                  name: "ContentTypeSelection"
                }
  }

  m.bSignedInUser = (m.global.authInfo <> invalid)
  m.Title = m.top.findNode("title")
  m.SubTitle = m.top.findNode("subtitle")


  m.SkipButton = m.top.findNode("skipButton")
  m.SkipButton.text = getTranslation("dialog_button_skip")

  m.InitialContentMenuBground = m.top.findNode("InitialContentMenuBground")
  m.InitialContentMenu = m.top.findNode("InitialContentMenu")
  m.InitialContentProfileMenuItemBground = m.top.findNode("InitialContentProfileMenuItemBground")
  m.InitialContentMenu.focusBitmapBlendColor = theme.focused
  m.top.observeFieldScoped("animateIntoView", "onAnimateIntoView")
  m.InitialContentMenu.observeField("itemSelected", "onItemSelected")
  m.InitialContentMenu.observeField("itemFocused", "onItemFocused")
  m.SkipButton.observeField("selected", "onSkipBtnSelected")
  m.SkipButton.observeField("focusedChild", "onItemFocused")
  m.screenReady = false '//When the screen 1st starts up, the screen is disabled
End Function


' animate the screen when the page 1st loads 
Function onAnimateIntoView()
  
  rowNode = CreateObject("roSGNode", "ContentNode")
  menuTreamentOption = getExperimentResource("roku_initial_content_type_selector_icts", "roku_initial_content_type_selector_icts_v3", false).icts_menu_option

  if menuTreamentOption = "movies_tv_combined"
    setMainContent(m.constants.ui.sideNavIds.home, rowNode)
    setMainContent(m.constants.ui.sideNavIds.linearTV, rowNode)
    setMainContent(m.constants.ui.sideNavIds.espanol, rowNode)
    setMainContent(m.constants.ui.sideNavIds.kidsMode, rowNode)
  else if menuTreamentOption = "no_espanol"
    setMainContent(m.constants.ui.sideNavIds.home, rowNode)
    setMainContent(m.constants.ui.sideNavIds.linearTV, rowNode) 
    setMainContent(m.constants.ui.sideNavIds.kidsMode, rowNode)
  else if menuTreamentOption = "movies_tv_separate"
    setMainContent(m.constants.ui.sideNavIds.movies, rowNode)
    setMainContent(m.constants.ui.sideNavIds.tv, rowNode)
    setMainContent(m.constants.ui.sideNavIds.linearTV, rowNode)
    setMainContent(m.constants.ui.sideNavIds.espanol, rowNode)
    setMainContent(m.constants.ui.sideNavIds.kidsMode, rowNode)
  end if
  numOfMenuItems = rowNode.getChildCount()
  nSpacing = m.InitialContentMenu.columnSpacings[0]
  aColumnSpacings = []
  for i = 1 to numOfMenuItems - 1
    aColumnSpacings.push(nSpacing)
  end for
  nMenuWidth = m.InitialContentMenu.itemSize[0] * numOfMenuItems + (nSpacing * (numOfMenuItems-1))
  nMenuWidthWithoutProfile = nMenuWidth

  m.Title.text = getTranslation("screenInitialContent_title")
  if m.bSignedInUser = true
    m.SubTitle.text = getTranslation("screenInitialContent_subtitle_signedIn")
  else
    m.SubTitle.text = getTranslation("screenInitialContent_subtitle_signedOut")
  end if

  nInitialContentMenuBgroundPadding = 96
  m.InitialContentMenu.columnSpacings = aColumnSpacings
  m.InitialContentMenu.numColumns = numOfMenuItems
  m.InitialContentMenu.content = rowNode
  nInitialContentMenuX = (1920 - nMenuWidth)/2

  '//Place the horizontal location of the profile button background
  '//   Menu x Position + the width of the menu w/o the profile button + 60 pixels from the last menu item before the profile menu item
  nInitialContentProfileMenuItemBgroundX = nInitialContentMenuX + nMenuWidthWithoutProfile + 60

  m.InitialContentMenu.translation = [ nInitialContentMenuX, m.InitialContentMenu.translation[1]]
  m.InitialContentProfileMenuItemBground.translation = [nInitialContentProfileMenuItemBgroundX, m.InitialContentProfileMenuItemBground.translation[1]]

  m.InitialContentMenuBground.width = nMenuWidth + (nInitialContentMenuBgroundPadding*2)
  m.InitialContentMenuBground.translation = [(1920 - m.InitialContentMenuBground.width)/2 , m.InitialContentMenuBground.translation[1]]


  
  if m.constants.deviceInfo.limitedUi = false
    fade(m.InitialContentMenuBground, "in", .5, .5)
    slideFade(m.Title, "above", "in", .5, 0, 50)
    slideFade(m.SubTitle, "above", "in", .5, .2, 50)
    slideFade(m.SkipButton, "above", "in", .5, .75, 50)
    fade(m.InitialContentProfileMenuItemBground, "in", .5, .75)
    m.FocusDelayTimer = m.top.findNode("FocusDelayTimer")
    m.FocusDelayTimer.duration = .75
    m.FocusDelayTimer.observeFieldScoped("fire", "onFocusDelayTimer")
    m.FocusDelayTimer.control = "start"
  else
    '//If low spec device, then skip animation
    m.InitialContentMenuBground.opacity = 1
    m.InitialContentProfileMenuItemBground.opacity = 1
    m.Title.opacity = 1
    m.SubTitle.opacity = 1
    m.SkipButton.opacity = 1
    onFocusDelayTimer()
  end if
End Function


Function onFocusDelayTimer()
  m.InitialContentMenu.setFocus(true)
  m.screenReady = true
End Function


' Set the ContentNode of one menu button of this screen and add it to the passed parentNode
' @itemID - string, The ID of the propsed menu button 
' @parentNode - The node to which the new button info will be added
Function setMainContent(itemID, parentNode)
  contentNode = CreateObject("roSGNode", "ContentNode")
  contentNode.id = itemID
  bSuccess = false

  if itemID = m.constants.ui.sideNavIds.home
    contentNode.title = getTranslation("menu_movies_and_tv")
    contentNode.hdgridposterurl = "pkg:/images/icon-movies-large.png"
    bSuccess = true
  else if itemID = m.constants.ui.sideNavIds.linearTV
    contentNode.title = getTranslation("menu_livetv")
    contentNode.hdgridposterurl = "pkg:/images/icon-linearTV-large.png"
    bSuccess = true
  else if itemID = m.constants.ui.sideNavIds.kidsMode
    contentNode.title = getTranslation("menu_kids")
    contentNode.hdgridposterurl = "pkg:/images/icon-kids-large.png"
    bSuccess = true
  else if itemID = m.constants.ui.sideNavIds.espanol
    contentNode.title = "Español"
    contentNode.hdgridposterurl = "pkg:/images/icon-espanol-large.png"
    bSuccess = true
  else if itemID = m.constants.ui.sideNavIds.profile
    contentNode.title = getTranslation("menu_signIn")
    contentNode.hdgridposterurl = "pkg:/images/icon-profile-large.png"
    bSuccess = true
  else if itemID = m.constants.ui.sideNavIds.Movies
    contentNode.title = getTranslation("menu_movies")
    contentNode.hdgridposterurl = "pkg:/images/sideNavMovies.png"
    bSuccess = true
  else if itemID = m.constants.ui.sideNavIds.tv
    contentNode.title = getTranslation("menu_tv")
    contentNode.hdgridposterurl = "pkg:/images/sideNavTV.png"
    bSuccess = true
  end if

  if bSuccess = true 
    parentNode.appendChild(contentNode)
  end if

End Function


Function onItemSelected()
  item = m.InitialContentMenu.itemSelected
  contentItem = m.InitialContentMenu.content.getChild(item)
  
  setActionableItemSelected(contentItem.id)
End Function


Function onItemFocused()
  row = 1
  col = 1
  sButtonID = invalid
  if m.InitialContentMenu.hasFocus() = true
    itemFocused = m.InitialContentMenu.itemFocused
    col = itemFocused + 1
    id = m.InitialContentMenu.content.getChild(itemFocused).id
    sButtonID = m.Tracking.sideNavPageMap[id]

    if m.previousFocusedButton <> invalid and m.previousFocusedButton.top_nav_section <> invalid and m.previousFocusedButton.top_nav_section <> sButtonID and sButtonID <> invalid
      '//::NOTE:: the top_nav_component is used for the navigateWithinPageInfo event of the initial content screen
      ' this triggers a navigate_within_page event in ContentController
      m.top.navigateWithinPageInfo = {
        pageOneof: m.Tracking.getAnalyticsPage(m.top.trackingPageInfo.pageType, m.top.trackingPageInfo.pageValues)
        componentOneof: m.Tracking.getAnalyticsComponent("top_nav_component", m.previousFocusedButton)
        means_of_navigation: "SCROLL"  'MeansOfNavigation enum 
      
        vertical_location: row  '//The row location of the side nav
        vertical_location_mode: "INDEX"  'LocationMode enum
        horizontal_location: col  '//The column location of the side nav
        horizontal_location_mode: "INDEX"  'LocationMode enum
      }
    end if
  else 
    '// if m.SkipButton.hasFocus() = true
    '//this else statement does nothing but to inform the developer that 
    '//analytics is purposely not being sent for the focus of or from the skip button
  end if

  m.previousFocusedButton = {
    top_nav_section: sButtonID
  }
End Function


Function onSkipBtnSelected()
  setActionableItemSelected("skip")
End Function


Function setActionableItemSelected(sID)
  m.top.actionableItemSelected = sID
End Function




Function onKeyEvent(key, press) as boolean
  if press and m.screenReady = true
    if key = "back"
      setActionableItemSelected(m.constants.ui.keyIds.back)
      return true
    else if key = "down" and m.SkipButton.visible = true and m.InitialContentMenu.hasFocus() = true
      m.SkipButton.setFocus(true)
      return true
    else if key = "up" and m.SkipButton.visible = true and m.SkipButton.hasFocus() = true
      m.InitialContentMenu.setFocus(true)
      return true
    end if
  end if

  return false
End Function