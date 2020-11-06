Function init()
  m.constants = m.global.constants
  m.theme = m.global.theme
  m.top.observeFieldScoped("focusedChild", "onFocusChange")
  m.top.observeFieldScoped("stringSignIn", "onSignInChange")
  m.top.observeFieldScoped("kidsModeValues", "onKidsModeValuesChanged")
  m.top.observeFieldScoped("displayEspanol", "onEspanolDisplayChanged")
  m.top.observeFieldScoped("displayMoviesTV", "onMovieTVDisplayChanged")
  m.top.observeFieldScoped("displayChannels", "onChannelsDisplayChanged")
  m.top.observeFieldScoped("opened", "onOpenedChange")
  m.top.observeFieldScoped("itemRequested", "onItemRequested")
  m.top.observeFieldScoped("selectedItemRequested", "onSelectedItemRequested")
  m.top.observeFieldScoped("createMenuItems", "onCreateMenuItems")
  m.BottomContent = m.top.findNode("BottomContent")
  m.MainContent = m.top.findNode("MainContent")
  m.MainContentSelect = m.top.findNode("MainContent-select")
  m.TopContent = m.top.findNode("TopContent")
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
  m.MainContentSelect.appendChild(contentNode)
  
End function


Function setMainContent(item)

  contentNode = CreateObject("roSGNode", "SideNavContentNode")
  contentNode.id = item
  if item = "kidsMode"
    contentNode.title = getTranslation("menu_home")
    contentNode.iconUrl = "pkg:/images/sideNavKids.png"
    m.kidsModeContent = contentNode
  else if item = "search"
    contentNode.title = getTranslation("menu_search")
    contentNode.iconUrl = "pkg:/images/sideNavSearch.png"
  else if item = "home"
    contentNode.title = getTranslation("menu_home")
    contentNode.iconUrl = "pkg:/images/sideNavHome.png"
  else if item = "movies"
    contentNode.title = getTranslation("menu_movies")
    contentNode.iconUrl = "pkg:/images/sideNavMovies.png"
    m.moviesContent = contentNode
  else if item = "tv"
    contentNode.title = getTranslation("menu_tv")
    contentNode.iconUrl = "pkg:/images/sideNavTV.png"
    m.tvContent = contentNode
  else if item = "espanol"
    contentNode.title = "Español"
    contentNode.iconUrl = "pkg:/images/sideNavEspanol.png"
    m.espanolContent = contentNode
  else if item = "mylist"
    contentNode.title = getTranslation("menu_mylist")
    contentNode.iconUrl = "pkg:/images/sideNavMyList.png"    
  else if item = "categories"
    contentNode.title = getTranslation("menu_categories")
    contentNode.iconUrl = "pkg:/images/sideNavCategories.png"
  else if item = "channels"
    contentNode.title = getTranslation("menu_channels")
    contentNode.iconUrl = "pkg:/images/sideNavChannels.png"
    m.channelsContent = contentNode
  end if
  
  m.MainContent.appendChild(contentNode)

End Function


Function onCreateMenuItems()

  m.mainItems = m.top.findNode("mainItems")
  m.mainItemsSelected = m.top.findNode("mainItemsSelected")
  
  menuItems = ["kidsMode", "search", "home", "movies", "tv", "espanol", "categories", "channels"]
  if m.constants.deviceInfo.countryCode = "US"
    experimentInfo = getExperimentResource("roku_safenav_ordering", "roku_safenav_ordering_v1", false)
    if experimentInfo <> invalid
      if experimentInfo.action = "remove_espanol"
        menuItems = ["kidsMode", "search", "home", "movies", "tv", "categories", "channels"]
      else if experimentInfo.action = "insert_espanol_6thPosition"
        menuItems = ["kidsMode", "search", "home", "movies", "tv", "espanol", "categories", "channels"]
      else if experimentInfo.action = "remove_espanol_and_insert_myList_5thPosition"
        menuItems = ["kidsMode", "search", "home", "movies", "tv", "mylist", "categories", "channels"]
      else if experimentInfo.action = "remove_espanol_and_insert_search_7thPosition"
        menuItems = ["kidsMode", "home", "movies", "tv", "categories", "channels", "search"]
      else if experimentInfo.action = "remove_espanol_and_swap_movies_tv"
        menuItems = ["kidsMode", "search", "home", "tv", "movies", "categories", "channels"]
      end if
    end if
  end if
  ' Creates roSGNode dynamically
  setMenuItems(menuItems)  
  
  setStrings()

  m.profileContent = m.TopContent.findNode("profile")
  '// This is the item to focus on when the sidenav opens. This implies that this was the last item (that has an associated screen) selected 
  m.itemSelectedRemembered = invalid

  m.topItems = m.top.findNode("topItems")
  m.bottomItems = m.top.findNode("bottomItems")
  m.mainItemsSelected.focusBitmapBlendColor = m.constants.ui.colors.selectedListItem
  m.mainItemsSelected.focusFootprintBlendColor = m.constants.ui.colors.selectedListItem

  initList(m.topItems)
  initList(m.bottomItems)
  initList(m.mainItems)

  '//Inititate the default view
  onOpenedChange()
  '//::TODO::SIDENAV set the width of the items of the lists dynamically to the width of m.top.width, plus some spacing
  '//::TODO::SIDENAV - set all references to sideNav IDs to be called from Constants: i.e. m.constants.ui.sideNavIds.home. 
  '//   To do this, set content in brs instead of xml?

End Function


Function setStrings()
    settingsNode = m.top.findNode("settings")
    settingsNode.title = getTranslation("menu_settings")
    exitNode = m.top.findNode("exit")
    exitNode.title = getTranslation("menu_exit")
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
  initListDisplay(list)
  setDrawFocusFeedback(list)
End Function


Function initListDisplay(list)
  list.focusBitmapBlendColor = m.global.theme.focused
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
    mainContentEspanol = m.MainContent.findNode("espanol")
    m.MainContent.removeChild(mainContentEspanol)

    mainContentEspanolSelect = m.MainContentSelect.findNode("espanol-select")
    m.MainContentSelect.removeChild(mainContentEspanolSelect)

  end if
End Function


' Hide the movies/tv items if this is called
Function onMovieTVDisplayChanged()
  if m.top.displayMoviesTV = false
    '//Remove movies/tv if those items should be hidden. For right now, don't worry about turning it back on
    mainContentMovies = m.MainContent.findNode("movies")
    mainContentTV = m.MainContent.findNode("tv")
    m.MainContent.removeChild(mainContentMovies)
    m.MainContent.removeChild(mainContentTV)

    mainContentMoviesSelect = m.MainContentSelect.findNode("movies-select")
    mainContentTVSelect = m.MainContentSelect.findNode("tv-select")
    m.MainContentSelect.removeChild(mainContentMoviesSelect)
    m.MainContentSelect.removeChild(mainContentTVSelect)
    
    '//Adjust the spacing of the 3 menu lists in the side nav now that 2 menu items have been eliminated.
    contentLayout = m.top.findNode("content")
    contentLayout.itemSpacings = [108, 148]
  end if
End Function


' Hide the Channels item if this is called
Function onChannelsDisplayChanged()
  if m.top.displayChannels = false
    '//Remove Channels if that item should be hidden. For right now, don't worry about turning it back on
    mainContentChannels = m.MainContent.findNode("channels")
    m.MainContent.removeChild(mainContentChannels)

    mainContentChannelsSelect = m.MainContentSelect.findNode("channels-select")
    m.MainContentSelect.removeChild(mainContentChannelsSelect)
  end if
End Function


' The kids mode has changed, so alter the look of the icon
Function onKidsModeValuesChanged()
  bOn = m.top.kidsModeValues.featureOn <> false
  if bOn
    sIconTitle = m.top.kidsModeValues.title
    bEnabled = (m.top.kidsModeValues.grayedOut = false)
    m.theme = m.global.theme
    initListDisplay(m.topItems)
    initListDisplay(m.bottomItems)
    initListDisplay(m.mainItems)
    
    if sIconTitle <> ""
      m.kidsModeContent.title = sIconTitle
      m.kidsModeContent.turnedOn = bEnabled
      nPreviouslyFocusedIndex = m.mainItems.itemFocused
      m.mainItems.content = m.MainContent
      if m.mainItems.hasFocus() = true
        '// If in focus, then set the focus back to the current item after the content has been reset
        m.mainItems.jumpToItem = nPreviouslyFocusedIndex
      end if
    end if
    
    '//::HARDCODE:: this page will disable or enable the channel icon based on kids mode = true. This component should not be smart like this but since this is a temporary thing, we can hardcode the component knowing what to do if this condition has been met.
    m.channelsContent.turnedOn = (m.top.kidsModeValues.on <> true)
    m.moviesContent.turnedOn = (m.top.kidsModeValues.on <> true)
    m.tvContent.turnedOn = (m.top.kidsModeValues.on <> true)
    if (m.top.kidsModeValues.on <> true and m.top.kidsModeValues.isAdultModeEnabledByParentalControl = true)
      if m.espanolContent <> invalid then m.espanolContent.turnedOn = true
    else
      if m.espanolContent <> invalid then m.espanolContent.turnedOn = false
    end if
    if m.top.kidsModeValues.on = true
      m.sideNavBackground.uri = m.constants.ui.uris.sideNavBackground_kidsMode
    else
      m.sideNavBackground.uri = ""
    end if
  else
    '//Remove kids mode if on is not true. For right now, don't worry about turning it back on
    m.MainContent.removeChild(m.kidsModeContent)
    mainContentKidsModeSelect = m.MainContentSelect.findNode("kidsMode-select")
    m.MainContentSelect.removeChild(mainContentKidsModeSelect)

    '//::NOTE:: This assumes that featureOn will be set to false at the beginning of the app, so 
    '//   when that happens, we need to call focusItemInList() to reset the placement of the focus of the m.MainContentSelect list
    if m.itemSelectedRemembered <> invalid
      focusItemInList(m.mainItems, m.itemSelectedRemembered.id)
    end if
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
Function onKeyEvent(key, press)
  if press = true
    if key = "up"
      if m.mainItems.isInFocusChain() = true
        m.topItems.jumpToItem = m.topItems.content.getChildCount() - 1
        m.topItems.setFocus(true)
      else if m.bottomItems.isInFocusChain() = true
        m.mainItems.jumpToItem = m.mainItems.content.getChildCount() - 1
        m.mainItems.setFocus(true)
      else if m.topItems.isInFocusChain() = true
        return false
      end if
      return true
    else if key = "down"
      if m.mainItems.isInFocusChain() = true
        m.bottomItems.jumpToItem = 0
        m.bottomItems.setFocus(true)
      else if m.topItems.isInFocusChain() = true
        m.mainItems.setFocus(true)
      else if m.bottomItems.isInFocusChain() = true and m.bottomItems.itemFocused >= (m.bottomItems.getChildCount() -1)
        return false
      end if
      return true
    end if

    return false
  end if
End Function


Function onOpenedChange()
  if m.top.opened = true
    ' sends exposure event when user opens sidenav
    ' calling getExperimentResource() automatically sends the exposure, and limits sending the exposure event to once per session.
    if m.constants.deviceInfo.countryCode = "US"
      getExperimentResource("roku_safenav_ordering", "roku_safenav_ordering_v1")
    end if  
  
    '//display hidden items, profile, settings, exit. Set all buttons to full opacity
    
    if m.itemSelectedRemembered <> invalid
      list = m.top.findNode(m.itemSelectedRemembered.list)
      index = getIndexByID(list, m.itemSelectedRemembered.id)
      list.jumpToItem = index
      list.setFocus(true)
    end if

    fade(m.sideNavBackground, "in", 0.2)
    fade(m.bottomItems, "in", 0.2)
    setContentActive(m.TopContent)
    setContentActive(m.MainContent)
    setContentActive(m.BottomContent)
    m.mainItemsSelected.visible = true
  else
    fade(m.sideNavBackground, "out", 0.2)
    fade(m.bottomItems, "out", 0.2)
    setContentActive(m.TopContent, false)
    setContentActive(m.MainContent, false)
    setContentActive(m.BottomContent, false)
    m.mainItemsSelected.visible = false
    m.listItemSelected = invalid
  end if
End Function


Function refresh()
  onOpenedChange()
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

    if nIndexMain < 0
      if focusItemInList(m.bottomItems, m.top.itemRequested) < 0
        focusItemInList(m.topItems, m.top.itemRequested)
      end if
    end if
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
    if list.id = m.mainItems.id
      m.mainItemsSelected.jumpToItem = index
    end if
    m.listItemSelected = {
      list: list.id
      index: index
    }

    if m.mainItems.id = list.id
      item = list.content.getChild(index)
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

  m.listItemSelected = {
    list: list.id
    index: index
  }
End Function


