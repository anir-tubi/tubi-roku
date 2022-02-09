Function init()
  m.constants = m.global.constants
  Request = TubiRequest(m.constants.settings)
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)

  m.top.observeFieldScoped("focusedChild", "onFocusChange")
  m.top.observeFieldScoped("stringSignIn", "onSignInChange")
  m.top.observeFieldScoped("displayEspanol", "onEspanolDisplayChanged")
  m.top.observeFieldScoped("displayLinearTV", "onLinearTVDisplayChanged")
  m.top.observeFieldScoped("displayLinearEPG","onLinearEPGDisplayChanged")
  m.top.observeFieldScoped("displayMoviesTV", "onMovieTVDisplayChanged")
  m.top.observeFieldScoped("displayChannels", "onChannelsDisplayChanged")
  m.top.observeFieldScoped("displaySignIn", "onSignInDisplayChanged")
  m.top.observeFieldScoped("displayKids", "onKidsDisplayChanged")
  m.top.observeFieldScoped("espanolItemTurnedOn", "onEspanolItemTurnedOnChanged")
  m.top.observeFieldScoped("kidsItemTurnedOn", "onKidsItemTurnedOnChanged")
  m.top.observeFieldScoped("linearEPGTurnedOn", "onLinearEPGTurnedOnChanged")
  m.top.observeFieldScoped("uiMode", "onUiModeChanged")
  m.top.observeFieldScoped("opened", "onOpenedChanged")
  m.top.observeFieldScoped("itemRequested", "onItemRequested")
  m.top.observeFieldScoped("selectedItemRequested", "onSelectedItemRequested")
  m.top.observeFieldScoped("createMenuItems", "onCreateMenuItems")
  m.ItemGroups = m.top.findNode("itemGroups")
  m.MainContent = m.top.findNode("MainContent")
  m.MainContentSelect = m.top.findNode("MainContent-select")
  m.sideNavBackground = m.top.findNode("sideNavBackground")
End Function


Function setMenuItems(menuItems)

  menuItemCount = menuItems.Count()
  for i = 0 to menuItemCount-1
    setMainContentSelect(menuItems[i])
    setMainContent(menuItems[i])
  end for
  
End Function


Function setMainContentSelect(item)

  contentNode = CreateObject("roSGNode", "SideNavContentNode")
  contentNode.id = item + "-select"
  m[item + "ContentSelect"] = contentNode
  m.MainContentSelect.appendChild(contentNode)
  
End function


Function setMainContent(item)

  contentNode = CreateObject("roSGNode", "SideNavContentNode")
  contentNode.id = item
  if item = m.constants.ui.sideNavIds.kidsMode
    contentNode.title = getTranslation("menu_kids")
    contentNode.iconUrl = "pkg:/images/sideNavKids.png"
  else if item = m.constants.ui.sideNavIds.search
    contentNode.title = getTranslation("menu_search")
    contentNode.iconUrl = "pkg:/images/sideNavSearch.png"
  else if item = m.constants.ui.sideNavIds.home
    contentNode.title = getTranslation("menu_home")
    contentNode.iconUrl = "pkg:/images/sideNavHome.png"
  else if item = m.constants.ui.sideNavIds.movies
    contentNode.title = getTranslation("menu_movies")
    contentNode.iconUrl = "pkg:/images/sideNavMovies.png"
  else if item = m.constants.ui.sideNavIds.tv
    contentNode.title = getTranslation("menu_tv")
    contentNode.iconUrl = "pkg:/images/sideNavTV.png"
  else if item = m.constants.ui.sideNavIds.espanol
    contentNode.title = "Español"
    contentNode.iconUrl = "pkg:/images/sideNavEspanol.png"
  else if item = m.constants.ui.sideNavIds.linearEPG
    contentNode.title = getTranslation("menu_livetv")
    contentNode.iconUrl = "pkg:/images/sideNavLinearTV.png"
  else if item = m.constants.ui.sideNavIds.myList
    contentNode.title = getTranslation("menu_mylist")
    contentNode.iconUrl = "pkg:/images/sideNavMyList.png"    
  else if item = m.constants.ui.sideNavIds.categories
    contentNode.title = getTranslation("menu_categories")
    contentNode.iconUrl = "pkg:/images/sideNavCategories.png"
  else if item = m.constants.ui.sideNavIds.channels
    contentNode.title = getTranslation("menu_channels")
    contentNode.iconUrl = "pkg:/images/sideNavChannels.png"
  else if item = m.constants.ui.sideNavIds.profile
    contentNode.title = getTranslation("menu_signIn")
    contentNode.iconUrl = "pkg:/images/sideNavProfile.png"
  else if item = m.constants.ui.sideNavIds.settings
    contentNode.title = getTranslation("menu_settings")
    contentNode.iconUrl = "pkg:/images/sideNavSettings.png"
  else if item = m.constants.ui.sideNavIds.exit
    contentNode.title = getTranslation("menu_exit")
    contentNode.iconUrl = "pkg:/images/sideNavExit.png"
  end if
  m[item + "Content"] = contentNode
  
  m.MainContent.appendChild(contentNode)

End Function


Function onCreateMenuItems()

  m.mainItems = m.top.findNode("mainItems")
  m.mainItemsSelected = m.top.findNode("mainItemsSelected")
  
  if getExperimentResource("roku_linear_epg", "roku_linear_epg_v1", false).enabled = true
    menuItems = [
      m.constants.ui.sideNavIds.profile
      m.constants.ui.sideNavIds.kidsMode
      m.constants.ui.sideNavIds.search
      m.constants.ui.sideNavIds.linearEPG
      m.constants.ui.sideNavIds.home
      m.constants.ui.sideNavIds.movies
      m.constants.ui.sideNavIds.tv
      m.constants.ui.sideNavIds.myList
      m.constants.ui.sideNavIds.categories
      m.constants.ui.sideNavIds.channels
      m.constants.ui.sideNavIds.espanol
      m.constants.ui.sideNavIds.settings
      m.constants.ui.sideNavIds.exit
    ]
  else
    menuItems = [
    m.constants.ui.sideNavIds.profile
    m.constants.ui.sideNavIds.kidsMode
    m.constants.ui.sideNavIds.search
    m.constants.ui.sideNavIds.home
    m.constants.ui.sideNavIds.movies
    m.constants.ui.sideNavIds.tv
    m.constants.ui.sideNavIds.myList
    m.constants.ui.sideNavIds.categories
    m.constants.ui.sideNavIds.channels
    m.constants.ui.sideNavIds.espanol
    m.constants.ui.sideNavIds.settings
    m.constants.ui.sideNavIds.exit
  ]
  end if  

  ' Creates roSGNode dynamically
  setMenuItems(menuItems)  

  '// This is the item to focus on when the sidenav opens. This implies that this was the last item (that has an associated screen) selected 
  m.itemSelectedRemembered = invalid

  m.mainItemsSelected.focusBitmapBlendColor = m.constants.ui.colors.selectedListItem
  m.mainItemsSelected.focusFootprintBlendColor = m.constants.ui.colors.selectedListItem

  m.mainItems.numRows = 12
  m.mainItemsSelected.numRows = 12
  m.mainItems.itemSpacing = [0,24]
  m.mainItemsSelected.itemSpacing = [0,24]
  m.mainItems.itemSize = [397,60]
  m.mainItemsSelected.itemSize = [397,60]
  m.itemGroups.translation = [0,40]
  m.mainItems.wrapDividerBitmapUri = ""
  m.mainItemsSelected.wrapDividerBitmapUri = ""
  m.mainItems.wrapDividerHeight = 0
  m.mainItemsSelected.wrapDividerHeight = 0

  initList(m.mainItems)

  '//Inititate the default view
  onOpenedChanged()
  '//::TODO::SIDENAV set the width of the items of the lists dynamically to the width of m.top.width, plus some spacing
  '//::TODO::SIDENAV - set all references to sideNav IDs to be called from Constants: i.e. m.constants.ui.sideNavIds.home. 
  '//   To do this, set content in brs instead of xml?

End Function


' SideNav has been told there has been a change to the user's sign in status and that it should change 
'   how the signin menu item appears by using the passed message data.
Function onSignInChange(message)
  if m.profileContent <> invalid
    m.profileContent.title = m.top.stringSignIn
  end if
End Function


' Initialize the passed markupList
Function initList(list)
  list.observeFieldScoped("itemSelected", "onItemSelect")
  list.observeFieldScoped("focusedChild", "onListFocusChange")
  list.observeFieldScoped("itemFocused", "onItemFocused")
  setListFocusedBlendColor(list)
  setDrawFocusFeedback(list)
End Function


Function setListFocusedBlendColor(list)
  if list <> invalid
    list.focusBitmapBlendColor = m.global.theme.focused
  end if
End Function


Function onFocusChange()
  if m.top.isInFocusChain() = true
    if m.top.hasFocus() = true
      '//set the focus on the last selected item
      if m.listItemSelected <> invalid
        list = m.top.findNode(m.listItemSelected.list)
        list.jumpToItem = m.listItemSelected.index
        list.setFocus(true)
      end if
    end if
  end if
End Function


' Hide the espanol item if this is called
Function onEspanolDisplayChanged()
  if m.top.displayEspanol = false
    '//Remove espanol if those items should be hidden. For right now, don't worry about turning it back on
    removeEspanol()
    verticallyCenterSideNav()
  end if
End Function


' Hide the live TV item if this is called
Function onLinearTVDisplayChanged()
  if m.top.displayLinearTV = false
    '//Remove line TV if those items should be hidden. For right now, don't worry about turning it back on
    removeLinearTV()
    verticallyCenterSideNav()
  end if
End Function


'Hide the linear EPG
Function onLinearEPGDisplayChanged()
  if m.top.displayLinearEPG = false
    '//Remove line TV if those items should be hidden. For right now, don't worry about turning it back on
    removeLinearEPG()
    verticallyCenterSideNav()
  end if
End Function


' Hide the movies/tv items if this is called
Function onMovieTVDisplayChanged()
  if m.top.displayMoviesTV = false
    ' Remove movies/tv if those items should be hidden.
    ' For right now, don't worry about turning it back on.
    removeMovies()
    removeTv()
    verticallyCenterSideNav()
  end if
End Function


' Hide the Channels item if this is called
Function onChannelsDisplayChanged()
  if m.top.displayChannels = false
    '//Remove Channels if that item should be hidden. For right now, don't worry about turning it back on
    removeChannels()
    verticallyCenterSideNav()
  end if
End Function


' Hide the Channels item if this is called
Function onSignInDisplayChanged()
  if m.top.displaySignIn = false
    ' Remove Sign In if that item should be hidden.
    ' For right now, don't worry about turning it back on.
    removeProfile()
    verticallyCenterSideNav()
  end if
End Function


Function onKidsDisplayChanged()
  if m.top.displayKids = false
    ' Remove Kids if that item should be hidden.
    ' For right now, don't worry about turning it back on.
    removeKids()
    verticallyCenterSideNav()
  end if
End Function


Function onEspanolItemTurnedOnChanged()
  if m.espanolContent <> invalid
    m.espanolContent.turnedOn = m.top.espanolTurnedOn
  end if
End Function


Function onLinearEPGTurnedOnChanged()
  if mod.linearEPGContent <> invalid
    m.linearEPGContent.turnedOn = m.top.linearEPGTurnedOn
  end if
End Function



Function onKidsItemTurnedOnChanged()
  if m.kidsModeContent <> invalid
    m.kidsModeContent.turnedOn = m.top.kidsItemTurnedOn
  end if
End Function


Function onUiModeChanged()
  if m.top.uiMode = m.constants.ui.modes.kids
    ' kids
    setCommonSideNavKidsValues()
  else if m.top.uiMode = m.constants.ui.modes.kidsParental
    ' kids mode due to parental controls
    setCommonSideNavKidsValues()
    if m.kidsModeContent <> invalid
      m.kidsModeContent.turnedOn = false
    end if
  else if m.top.uiMode = m.constants.ui.modes.kidsAgeGate
    ' kids mode due to age gating
    removeProfile()
    removeKids()
    removeMovies()
    removeTv()
    removeChannels()
    removeEspanol()
    removeLinearTV()
    removeLinearEPG()
    removeMyList()
    verticallyCenterSideNav()
    m.sideNavBackground.uri = m.constants.ui.uris.sideNavBackground_kidsMode
  else if m.top.uiMode = m.constants.ui.modes.latino
    ' latino - nothing should change
    if m.channelsContent <> invalid then m.channelsContent.turnedOn = true
    if m.moviesContent <> invalid then m.moviesContent.turnedOn = true
    if m.tvContent <> invalid then m.tvContent.turnedOn = true
    if m.espanolContent <> invalid then m.espanolContent.turnedOn = true
    if m.linearTVContent <> invalid then m.linearTVContent.turnedOn = true
    if m.linearEPGContent <> invalid then m.linearEPGContent.turnedOn = true
    if m.kidsModeContent <> invalid then m.kidsModeContent.title = getTranslation("menu_kids")
    m.sideNavBackground.uri = ""
  else if m.top.uiMode = m.constants.ui.modes.standard
    ' standard
    if m.channelsContent <> invalid then m.channelsContent.turnedOn = true
    if m.moviesContent <> invalid then m.moviesContent.turnedOn = true
    if m.tvContent <> invalid then m.tvContent.turnedOn = true
    if m.espanolContent <> invalid then m.espanolContent.turnedOn = true
    if m.linearTVContent <> invalid then m.linearTVContent.turnedOn = true
    if m.linearEPGContent <> invalid then m.linearEPGContent.turnedOn = true
    if m.kidsModeContent <> invalid
      m.kidsModeContent.turnedOn = true
      m.kidsModeContent.title = getTranslation("menu_kids")
    end if
    m.sideNavBackground.uri = ""
  end if

  ' change the color of the focus indicator(s) as necessary
  setListFocusedBlendColor(m.mainItems)
End Function


Function setCommonSideNavKidsValues()
  if m.channelsContent <> invalid then m.channelsContent.turnedOn = false
  if m.moviesContent <> invalid then m.moviesContent.turnedOn = false
  if m.tvContent <> invalid then m.tvContent.turnedOn = false
  if m.espanolContent <> invalid then m.espanolContent.turnedOn = false
  if m.linearTVContent <> invalid then m.linearTVContent.turnedOn = false
  if m.linearEPGContent <> invalid then m.linearEPGContent.turnedOn = false
  if m.kidsModeContent <> invalid then m.kidsModeContent.title = getTranslation("menu_exitKids")
  m.sideNavBackground.uri = m.constants.ui.uris.sideNavBackground_kidsMode
End Function


Function removeProfile()
  if m.profileContent <> invalid
    m.MainContent.removeChild(m.profileContent)
  end if
  if m.profileContentSelect <> invalid
    m.MainContentSelect.removeChild(m.profileContentSelect)
  end if
End Function


Function removeKids()
  if m.kidsModeContent <> invalid
    m.MainContent.removeChild(m.kidsModeContent)
  end if
  if m.kidsModeContentSelect <> invalid
    m.MainContentSelect.removeChild(m.kidsModeContentSelect)
  end if
End Function


Function removeMovies()
  if m.moviesContent <> invalid
    m.MainContent.removeChild(m.moviesContent)
  end if
  if m.moviesContentSelect <> invalid
    m.MainContentSelect.removeChild(m.moviesContentSelect)
  end if
End Function


Function removeTv()
  if m.tvContent <> invalid
    m.MainContent.removeChild(m.tvContent)
  end if
  if m.tvContentSelect <> invalid
    m.MainContentSelect.removeChild(m.tvContentSelect)
  end if
End Function


Function removeChannels()
  if m.channelsContent <> invalid
    m.MainContent.removeChild(m.channelsContent)
  end if
  if m.channelsContentSelect <> invalid
    m.MainContentSelect.removeChild(m.channelsContentSelect)
  end if
End Function


Function removeEspanol()
  if m.espanolContent <> invalid
    m.MainContent.removeChild(m.espanolContent)
  end if
  if m.espanolContentSelect <> invalid
    m.MainContentSelect.removeChild(m.espanolContentSelect)
  end if
End Function


Function removeLinearTV()
  if m.linearTVContent <> invalid
    m.MainContent.removeChild(m.linearTVContent)
  end if
  if m.linearTVContentSelect <> invalid
    m.MainContentSelect.removeChild(m.linearTVContentSelect)
  end if
End Function


Function removeLinearEPG()
  if m.linearEPGContent <> invalid
    m.MainContent.removeChild(m.linearEPGContent)
  end if
  if m.linearEPGContentSelect <> invalid
    m.MainContentSelect.removeChild(m.linearEPGContentSelect)
  end if
End Function


Function removeMyList()
  if m.myListContent <> invalid
    m.MainContent.removeChild(m.myListContent)
  end if
  if m.myListContentSelect <> invalid
    m.MainContentSelect.removeChild(m.myListContentSelect)
  end if
End Function


' When the list gains/loses focus, then hide or display the focus indicator
Function onListFocusChange(msg)
  list = msg.getRoSGNode()
  setDrawFocusFeedback(msg.getRoSGNode())
End Function


' Control whether the focus indiocator is displayed or not based on if the list has focus
Function setDrawFocusFeedback(list)
  if list.isInFocusChain() = true
    list.drawFocusFeedback = true
  else
    list.drawFocusFeedback = false
  end if 
End Function


' When the user presses up or down, then change which list has focus
Function onKeyEvent(key, press) as Boolean
  if press = true
    if key = "up"
      return true
    else if key = "down"
      return true
    end if

    return false
  end if
End Function


Function onOpenedChanged()
  if m.top.opened = true
    '//display hidden items, profile, settings, exit. Set all buttons to full opacity
    
    if m.itemSelectedRemembered <> invalid
      list = m.top.findNode(m.itemSelectedRemembered.list)
      index = getIndexByID(list, m.itemSelectedRemembered.id)
      list.jumpToItem = index
      list.setFocus(true)
    end if

    fade(m.sideNavBackground, "in", 0.2)

    setContentActive(m.MainContent)
    m.mainItemsSelected.visible = true
  else
    fade(m.sideNavBackground, "out", 0.2)

    setContentActive(m.MainContent, false)
    m.mainItemsSelected.visible = false
    m.listItemSelected = invalid
    m.oldSideNavFocusedButton = invalid
  end if
End Function


Function refresh()
  onOpenedChanged()
End Function


Function setContentActive(content, bActive = true)
  for i = 0 to content.getChildCount()-1
    item = content.getChild(i)
    item.active = bActive
    if(m.itemSelectedRemembered <> invalid and m.itemSelectedRemembered.id = item.id)
      item.selected = true
    else 
      item.selected = false
    end if 
  end for
End Function


Function onItemRequested()
  if m.top.itemRequested <> invalid and m.top.itemRequested <> "" and (m.itemSelectedRemembered = invalid or m.top.itemRequested <> m.itemSelectedRemembered.id)
    '//Go thru the lists and select the option that matches the itemRequested
    nIndexMain = focusItemInList(m.mainItems, m.top.itemRequested)
  end if
End Function


Function onSelectedItemRequested()
  index = getIndexByID(m.mainItems, m.top.selectedItemRequested)
  m.mainItemsSelected.jumpToItem = index
End Function


Function getIndexByID(list, sID)
  content = list.content
  index = -1
  for i = 0 to content.getChildCount() - 1
    item = content.getChild(i)
    if item.id = sID 
      index = i
      exit for
    end if
  end for
  return index
End Function


Function focusItemInList(list, sID)
  index = getIndexByID(list, sID)
  if index >= 0
    list.jumpToItem = index
    m.top.focusedPosition = index
    if list.id = m.mainItems.id
      m.mainItemsSelected.jumpToItem = index
    end if
    m.listItemSelected = {
      list: list.id
      index: index
    }

    item = list.content.getChild(index)
    m.top.itemCurrentId = item.id

    if m.mainItems.id = list.id
      m.itemSelectedRemembered = {
        id: item.id,
        list: list.id
      }
    end if
  end if

  if index >= 0
    refresh()
  end if
  return index
End Function


Function onItemSelect(msg)
  list = msg.getRoSGNode()
  '//When an item is selected, then set a field so a Helper can perform the necessary action and close the menu if necessary 
  index = list.itemSelected
  item = list.content.getChild(index)
  m.listItemSelected = {
    list: list.id
    index: index
  }

  if list.id = m.mainItems.id
    m.mainItemsSelected.jumpToItem = index
  end if

  m.top.itemCurrentId = item.id
  if m.mainItems.id = list.id
    '//Only allow the middle list items to be remembered as they are the only ones with associated screens while the side nav is still visible 
    m.itemSelectedRemembered = {
      list: list.id
      id: item.id
    } 
  end if

  'make sure to set itemSelected before itemSelectedId because observers on 
  'itemSelectedId will trigger callbacks that require itemSelected to be set already
  m.top.itemSelected = item
  m.top.itemSelectedId = item.id
End Function


Function onItemFocused(msg)
  list = msg.getRoSGNode()
  index = list.itemSelected

  itemFocused = list.itemFocused
  item = list.content.getChild(itemFocused)

  ' trigger navigate_within_page events in ContentController
  pageType = m.Tracking.sideNavPageMap[item.id]
  
  if m.oldSideNavFocusedButton <> invalid and m.oldSideNavFocusedButton.left_nav_section <> pageType
    row = itemFocused + 1
    col = 1
    m.top.navigateWithinPageInfo = {
      componentOneof: m.Tracking.getAnalyticsComponent("left_side_nav_component", m.oldSideNavFocusedButton)
      means_of_navigation: "SCROLL"  'MeansOfNavigation enum 

      vertical_location: row  '//The row location of the side nav
      vertical_location_mode: "INDEX"  'LocationMode enum
      horizontal_location: col  '//The column location of the side nav
      horizontal_location_mode: "INDEX"  'LocationMode enum
    }
  end if

  m.oldSideNavFocusedButton = {
    left_nav_section: pageType
  }
  m.listItemSelected = {
    list: list.id
    index: index
  }
  m.top.focusedPosition = itemFocused
End Function


Function verticallyCenterSideNav()
  boundingRect = m.ItemGroups.boundingRect()
  sideNavHeight = boundingRect.height

  translationX = m.ItemGroups.translation[0]
  translationY = (1080 - sideNavHeight) / 2
  m.ItemGroups.translation = [translationX, translationY]
End Function
