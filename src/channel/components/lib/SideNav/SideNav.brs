Function init()
  m.constants = getConstantsFromGlobal()
  Request = TubiRequest(m.constants.settings)
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)

  m.top.observeFieldScoped("focusedChild", "onFocusChange")
  m.top.observeFieldScoped("stringSignIn", "onSignInChange")
  m.top.observeFieldScoped("displayEspanol", "onEspanolDisplayChanged")
  m.top.observeFieldScoped("displayMoviesTV", "onMovieTVDisplayChanged")
  m.top.observeFieldScoped("displayChannels", "onChannelsDisplayChanged")
  m.top.observeFieldScoped("displaySignIn", "onSignInDisplayChanged")
  m.top.observeFieldScoped("displayKids", "onKidsDisplayChanged")
  m.top.observeFieldScoped("espanolItemTurnedOn", "onEspanolItemTurnedOnChanged")
  m.top.observeFieldScoped("kidsItemTurnedOn", "onKidsItemTurnedOnChanged")
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


'@menuItems: stringarray array of the menu item ids we want to add
Function setMenuItems(menuItems)
  menuItemCount = menuItems.Count()

  for i = 0 to menuItemCount - 1
    m.MainContent.appendChild(createMainContent(menuItems[i]))
    m.MainContentSelect.appendChild(createMainContentSelect(menuItems[i]))
  end for

End Function

'@item: string id of the menu item
Function createMainContentSelect(item)

  contentNode = CreateObject("roSGNode", "SideNavContentNode")
  contentNode.id = item + "-select"
  m[item + "ContentSelect"] = contentNode

  return contentNode
End Function


Function createMainContent(item)

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
    contentNode.iconUrl = "pkg:/images/sideNavHome.webp"
  else if item = m.constants.ui.sideNavIds.movies
    contentNode.title = getTranslation("menu_movies")
    contentNode.iconUrl = "pkg:/images/sideNavMovies.png"
  else if item = m.constants.ui.sideNavIds.tv
    contentNode.title = getTranslation("menu_tv")
    contentNode.iconUrl = "pkg:/images/sideNavTV.png"
  else if item = m.constants.ui.sideNavIds.espanol
    contentNode.title = "Español"
    contentNode.iconUrl = "pkg:/images/sideNavEspanol.png"
  else if item = m.constants.ui.sideNavIds.myList
    contentNode.title = getTranslation("menu_mystuff")
    contentNode.shortDescriptionLine2 = getTranslation("text_new")
    contentNode.iconUrl = "pkg:/images/icon-add-to-queue.webp"
  else if item = m.constants.ui.sideNavIds.categories
    contentNode.title = getTranslation("menu_categories")
    contentNode.iconUrl = "pkg:/images/sideNavCategories.webp"
  else if item = m.constants.ui.sideNavIds.channels
    contentNode.title = getTranslation("menu_channels")
    contentNode.iconUrl = "pkg:/images/sideNavChannels.webp"
  else if item = m.constants.ui.sideNavIds.profile
    ' m.top.stringSignIn may have been set before SideNav.createMainContent() was called
    ' so use it if it exists
    contentNode.title = m.top.stringSignIn

    signTxt = getTranslation("menu_signIn")

    if contentNode.title = ""
      contentNode.title = signTxt
    end if

    if contentNode.title = signTxt 'if title is 'SignIn', that means, user has signed out=>set subtext also 'SignIn'
      contentNode.shortDescriptionLine1 = signTxt
      contentNode.ShortDescriptionLine2 = getTranslation("registration_signup_button_free")
    else
      contentNode.shortDescriptionLine1 = "" 'If title is not "SignIn" but something like 'hi user' then user has signedIn and no need to show subtext
      contentNode.ShortDescriptionLine2 = ""
    end if


    contentNode.iconUrl = "pkg:/images/icon-sign-in.webp"
  else if item = m.constants.ui.sideNavIds.settings
    contentNode.title = getTranslation("menu_settings")
    contentNode.iconUrl = "pkg:/images/sideNavSettings.webp"
  else if item = m.constants.ui.sideNavIds.exit
    contentNode.title = getTranslation("menu_exit")
    contentNode.iconUrl = "pkg:/images/sideNavExit.png"
  end if
  m[item + "Content"] = contentNode

  return contentNode

End Function


Function onCreateMenuItems()

  m.mainItems = m.top.findNode("mainItems")
  m.mainItemsSelected = m.top.findNode("mainItemsSelected")

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

  ' Creates roSGNode dynamically
  m.MenuItemIDs = menuItems
  setMenuItems(m.MenuItemIDs)

  '// This is the item to focus on when the sidenav opens. This implies that this was the last item (that has an associated screen) selected
  m.itemSelectedRemembered = invalid

  m.mainItems.numRows = 12
  m.mainItemsSelected.numRows = 12
  m.mainItems.itemSpacing = [0, 12]
  m.mainItemsSelected.itemSpacing = [0, 12]
  'this is to accommodate spanish signIn text + free Icon
  m.mainItemsOriginalItemSize = [438, 72]
  m.mainItems.itemSize = m.mainItemsOriginalItemSize
  m.mainItemsSelected.itemSize = m.mainItemsOriginalItemSize

  m.itemGroups.translation = [57, 40]
  m.mainItems.wrapDividerBitmapUri = ""
  m.mainItemsSelected.wrapDividerBitmapUri = ""
  m.mainItems.wrapDividerHeight = 0
  m.mainItemsSelected.wrapDividerHeight = 0

  initList(m.mainItems)

  '//Initiate the default view
  onOpenedChanged()

  if m.global <> invalid
    m.global.observeField("theme", "onThemeChange")
  end if
  onThemeChange()
End Function


Function onThemeChange(msg = invalid)
  if msg <> invalid
    theme = msg.getData()
  else
    theme = getThemeFromGlobal()
  end if

  if theme <> invalid
    m.mainItemsSelected.focusBitmapBlendColor = theme.neutralColor
    m.mainItemsSelected.focusFootprintBlendColor = theme.neutralColor
  end if
End Function


' SideNav has been told there has been a change to the user's sign in status and that it should change
'   how the signin menu item appears by using the passed message data.
Function onSignInChange()
  if m.profileContent <> invalid
    m.profileContent.title = m.top.stringSignIn
    signTxt = getTranslation("menu_signIn")
    if m.profileContent.title = signTxt
      m.profileContent.shortDescriptionLine1 = signTxt
      m.profileContent.shortDescriptionLine2 = getTranslation("registration_signup_button_free")
    else
      m.profileContent.shortDescriptionLine1 = ""
      m.profileContent.shortDescriptionLine2 = ""
    end if

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
    theme = getThemeFromGlobal()
    if theme <> invalid
      list.focusBitmapBlendColor = theme.focusedColor
    end if
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
    '//Remove espanol if those items should be hidden.
    removeEspanol()
    verticallyCenterSideNav()
  else
    ' Display the menu item if it should be displayed
    insertMenuItemInMenuLists(m.constants.ui.sideNavIds.espanol)
  end if
End Function


' Hide the movies/tv items if this is called
Function onMovieTVDisplayChanged()
  if m.top.displayMoviesTV = false
    ' Remove movies/tv if those items should be hidden.
    removeMovies()
    removeTv()
    verticallyCenterSideNav()
  else
    ' Display the menu items if they should be displayed
    insertMenuItemInMenuLists(m.constants.ui.sideNavIds.movies)
    insertMenuItemInMenuLists(m.constants.ui.sideNavIds.tv)
  end if
End Function


' Hide the Channels item if this is called
Function onChannelsDisplayChanged()
  if m.top.displayChannels = false
    '//Remove Channels if that item should be hidden.
    removeChannels()
    verticallyCenterSideNav()
  else
    ' Display the menu item if it should be displayed
    insertMenuItemInMenuLists(m.constants.ui.sideNavIds.channels)
  end if
End Function


' Hide the Channels item if this is called
Function onSignInDisplayChanged()
  if m.top.displaySignIn = false
    ' Remove Sign In if that item should be hidden.
    removeProfile()
    verticallyCenterSideNav()
  else
    ' Display the menu item if it should be displayed
    insertMenuItemInMenuLists(m.constants.ui.sideNavIds.profile)
  end if
End Function


Function onKidsDisplayChanged()
  if m.top.displayKids = false
    ' Remove Kids if that item should be hidden.
    removeKids()
    verticallyCenterSideNav()
  else
    ' Display the KidsMode menuy item if the item should be displayed
    insertMenuItemInMenuLists(m.constants.ui.sideNavIds.kidsMode)
  end if
End Function


' Insert the menu item associated with sMenuID into the m.MainContent and m.MainContentSelect menu lists in the order that the menu item belongs
' @sMenuID string one of constants.ui.sideNavIds for which we want to add if it does not already exist
Function insertMenuItemInMenuLists(sMenuID)
  nMenuItemOriginalIndex = getIndexOfMenuID(sMenuID)
  if nMenuItemOriginalIndex >= 0
    '//menuItem belongs in the menu list, so allowed to proceed to determine where the menu item actually belongs in the list in its current state
    nIndex = 0
    nMenuListCountUntil = m.MainContent.getChildCount() - 1
    for i = 0 to nMenuListCountUntil
      menuContentItem = m.MainContent.getChild(i)
      sMenuContentItemID = menuContentItem.Id
      if sMenuID = sMenuContentItemID
        '// The menu to be inserted to the menu is already in the menu. No need to do anything
        exit for
      else
        nTempMenuItemOriginalIndex = getIndexOfMenuID(sMenuContentItemID)
        '//Does the temporary, current menu item come before the main menu item that was passed to this function?
        bTempMenuItemComeBeforePassedMenuItem = (nTempMenuItemOriginalIndex < nMenuItemOriginalIndex)

        if bTempMenuItemComeBeforePassedMenuItem = false
          '// this is the index to insert the menuItem into the menu list
          nIndex = i
          exit for
        else if i = nMenuListCountUntil
          '//This is the last item
          nIndex = i
        end if
      end if
    end for

    menuItem = m[sMenuID + "Content"]
    if menuItem = invalid
      menuItem = createMainContent(sMenuID)
    end if

    menuItemSelect = m[sMenuID + "ContentSelect"]
    if menuItemSelect = invalid
      menuItemSelect = createMainContentSelect(sMenuID)
    end if

    '//Ensure the menu items match the active state of the other menu items
    menuItem.active = m.top.opened
    menuItemSelect.active = m.top.opened

    '//add the menu items at their proper locations
    m.MainContent.insertChild(menuItem, nIndex)
    m.MainContentSelect.insertChild(menuItemSelect, nIndex)
    verticallyCenterSideNav()
  end if
End Function


Function onEspanolItemTurnedOnChanged()
  if m.espanolContent <> invalid
    m.espanolContent.turnedOn = m.top.espanolTurnedOn
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
    removeMyList()
    verticallyCenterSideNav()
    m.sideNavBackground.uri = m.constants.ui.uris.sideNavBackground_kidsMode
  else if m.top.uiMode = m.constants.ui.modes.latino
    ' latino - nothing should change
    if m.channelsContent <> invalid then m.channelsContent.turnedOn = true
    if m.moviesContent <> invalid then m.moviesContent.turnedOn = true
    if m.tvContent <> invalid then m.tvContent.turnedOn = true
    if m.espanolContent <> invalid then m.espanolContent.turnedOn = true
    if m.kidsModeContent <> invalid then m.kidsModeContent.title = getTranslation("menu_kids")
    m.sideNavBackground.uri = ""
  else if m.top.uiMode = m.constants.ui.modes.standard
    ' standard
    if m.channelsContent <> invalid then m.channelsContent.turnedOn = true
    if m.moviesContent <> invalid then m.moviesContent.turnedOn = true
    if m.tvContent <> invalid then m.tvContent.turnedOn = true
    if m.espanolContent <> invalid then m.espanolContent.turnedOn = true
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
  if m.kidsModeContent <> invalid then m.kidsModeContent.title = getTranslation("menu_exitKids")
  m.sideNavBackground.uri = m.constants.ui.uris.sideNavBackground_kidsMode
End Function


Function removeProfile()
  if m.profileContent <> invalid
    m.MainContent.removeChild(m.profileContent)
    m.profileContent = invalid
  end if
  if m.profileContentSelect <> invalid
    m.MainContentSelect.removeChild(m.profileContentSelect)
    m.profileContentSelect = invalid
  end if
End Function


Function removeKids()
  if m.kidsModeContent <> invalid
    m.MainContent.removeChild(m.kidsModeContent)
    m.kidsModeContent = invalid
  end if
  if m.kidsModeContentSelect <> invalid
    m.MainContentSelect.removeChild(m.kidsModeContentSelect)
    m.kidsModeContentSelect = invalid
  end if
End Function


Function removeMovies()
  if m.moviesContent <> invalid
    m.MainContent.removeChild(m.moviesContent)
    m.moviesContent = invalid
  end if
  if m.moviesContentSelect <> invalid
    m.MainContentSelect.removeChild(m.moviesContentSelect)
    m.moviesContentSelect = invalid
  end if
End Function


Function removeTv()
  if m.tvContent <> invalid
    m.MainContent.removeChild(m.tvContent)
    m.tvContent = invalid
  end if
  if m.tvContentSelect <> invalid
    m.MainContentSelect.removeChild(m.tvContentSelect)
    m.tvContentSelect = invalid
  end if
End Function


Function removeChannels()
  if m.channelsContent <> invalid
    m.MainContent.removeChild(m.channelsContent)
    m.channelsContent = invalid
  end if
  if m.channelsContentSelect <> invalid
    m.MainContentSelect.removeChild(m.channelsContentSelect)
    m.channelsContentSelect = invalid
  end if
End Function


Function removeEspanol()
  if m.espanolContent <> invalid
    m.MainContent.removeChild(m.espanolContent)
    m.espanolContent = invalid
  end if
  if m.espanolContentSelect <> invalid
    m.MainContentSelect.removeChild(m.espanolContentSelect)
    m.espanolContentSelect = invalid
  end if
End Function


Function removeMyList()
  if m.myListContent <> invalid
    m.MainContent.removeChild(m.myListContent)
    m.myListContent = invalid
  end if
  if m.myListContentSelect <> invalid
    m.MainContentSelect.removeChild(m.myListContentSelect)
    m.myListContentSelect = invalid
  end if
End Function


' When the list gains/loses focus, then hide or display the focus indicator
Function onListFocusChange(msg)
  list = msg.getRoSGNode()
  setDrawFocusFeedback(list)
End Function


' Control whether the focus indicator is displayed or not based on if the list has focus
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
  end if
  return false
End Function


Function onOpenedChanged()
  if m.top.opened = true
    '//display hidden items, profile, settings, exit.

    if m.itemSelectedRemembered <> invalid
      list = m.top.findNode(m.itemSelectedRemembered.list)
      index = getIndexByID(list, m.itemSelectedRemembered.id)
      list.jumpToItem = index

      if list.id = m.mainItems.id
        '//make sure the other mainItemsSelected matches with  mainItems
        m.mainItemsSelected.jumpToItem = index
      end if
      list.setFocus(true)
    end if

    fade(m.sideNavBackground, "in", 0.2)

    setContentActive(m.MainContent)
    animateItemSize(m.mainItemsSelected, m.mainItemsOriginalItemSize, 0.2)
    animateItemSize(m.mainItems, m.mainItemsOriginalItemSize, 0.2)
  else
    fade(m.sideNavBackground, "out", 0.2)

    setContentActive(m.MainContent, false)
    animateItemSize(m.mainItemsSelected, [108, m.mainItemsSelected.itemSize[1]], 0.2)
    animateItemSize(m.mainItems, [108, m.mainItems.itemSize[1]], 0.2)
    m.listItemSelected = invalid
    m.oldSideNavFocusedButton = invalid
  end if
End Function


Function refresh()
  onOpenedChanged()
End Function


Function setContentActive(content, bActive = true)
  for i = 0 to content.getChildCount() - 1
    item = content.getChild(i)
    item.active = bActive
    if(m.itemSelectedRemembered <> invalid AND m.itemSelectedRemembered.id = item.id)
      item.selected = true
    else
      item.selected = false
    end if
  end for
End Function


Function onItemRequested()
  if m.top.itemRequested <> invalid AND m.top.itemRequested <> "" AND (m.itemSelectedRemembered = invalid OR m.top.itemRequested <> m.itemSelectedRemembered.id)
    '//Go thru the lists and select the option that matches the itemRequested
    focusItemInList(m.mainItems, m.top.itemRequested)
  end if
End Function


Function onSelectedItemRequested()
  index = getIndexByID(m.mainItems, m.top.selectedItemRequested)
  m.mainItemsSelected.jumpToItem = index
End Function


' Find the index of the passed menu ID within the array of menu IDs
Function getIndexOfMenuID(sID)
  nIndex = -1
  if m.MenuItemIDs <> invalid
    for i = 0 to m.MenuItemIDs.Count() - 1
      if sID = m.MenuItemIDs[i]
        nIndex = i
        exit for
      end if
    end for
  end if

  return nIndex
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

  if m.oldSideNavFocusedButton <> invalid AND m.oldSideNavFocusedButton.left_nav_section <> pageType
    row = itemFocused + 1
    col = 1
    m.top.navigateWithinPageInfo = {
      componentOneof: m.Tracking.getAnalyticsComponent("left_side_nav_component", m.oldSideNavFocusedButton)
      means_of_navigation: "SCROLL" 'MeansOfNavigation enum

      vertical_location: row '//The row location of the side nav
      horizontal_location: col '//The column location of the side nav
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
