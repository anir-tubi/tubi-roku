Function init()
  m.constants = m.global.constants
  m.top.observeFieldScoped("focusedChild", "onFocusChange")
  m.top.observeFieldScoped("userName", "onSignedIn")
  m.top.observeFieldScoped("kidsModeValues", "onKidsModeValuesChanged")
  m.top.observeFieldScoped("opened", "onOpenedChange")
  m.top.observeFieldScoped("itemRequested", "onItemRequested")
  m.BottomContent = m.top.findNode("BottomContent")
  m.MainContent = m.top.findNode("MainContent")
  m.TopContent = m.top.findNode("TopContent")
  m.profileContent = m.TopContent.findNode("profile")
  m.kidsModeContent = m.TopContent.findNode("kidsMode")
  '// This is the item to focus on when the sidenav opens. This implies that this was the last item (that has an associated screen) selected 
  m.itemSelectedRemembered = invalid

  m.topItems = m.top.findNode("topItems")
  initList(m.topItems)

  m.bottomItems = m.top.findNode("bottomItems")
  initList(m.bottomItems)

  m.mainItems = m.top.findNode("mainItems")
  initList(m.mainItems)
  m.mainItemsSelected = m.top.findNode("mainItemsSelected")
  m.mainItemsSelected.focusBitmapBlendColor = m.constants.ui.colors.selectedListItem
  m.mainItemsSelected.focusFootprintBlendColor = m.constants.ui.colors.selectedListItem

  '//Inititate the default view
  onSignedIn()
  onOpenedChange()
  '//::TODO::SIDENAV set the width of the items of the lists dynamically to the width of m.top.width, plus some spacing
  '//::TODO::SIDENAV - set all references to sideNav IDs to be called from Constants: i.e. m.constants.ui.sideNavIds.home. 
  '//   To do this, set content in brs instead of xml?
End Function


' Initialize the passed markupList
Function initList(list)
  list.observeFieldScoped("itemSelected", "onItemSelect")
  list.observeFieldScoped("focusedChild", "onListFocusChange")
  list.focusBitmapBlendColor = m.constants.ui.colors.focused
  setDrawFocusFeedback(list)
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


Function onSignedIn()
    sName = "Sign In"
    if m.top.userName <> ""
      sName = m.top.userName 
    end if

    m.profileContent.title = sName
    m.topItems.content = m.TopContent
End Function

' The kids mode has changed, so alter the look of the icon
Function onKidsModeValuesChanged()
  sIconTitle = m.top.kidsModeValues.title
  bEnabled = (m.top.kidsModeValues.grayedOut = false)

  if sIconTitle <> ""
    m.kidsModeContent.title = sIconTitle
    m.kidsModeContent.turnedOn = bEnabled
    nPreviouslyFocusedIndex = m.topItems.itemFocused
    m.topItems.content = m.TopContent
    if m.topItems.hasFocus() = true
      '// If in focus, then set the focus back to the current item after the content has been reset
      m.topItems.jumpToItem = nPreviouslyFocusedIndex
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
    '//display hidden items, profile, settings, exit. Set all buttons to full opacity
    
    if m.itemSelectedRemembered <> invalid
      list = m.top.findNode(m.itemSelectedRemembered.list)
      index = getIndexByID(list, m.itemSelectedRemembered.id)
      list.jumpToItem = index
      list.setFocus(true)
    end if

    fade(m.bottomItems, "in", 0.2)
    setContentActive(m.TopContent)
    setContentActive(m.MainContent)
    setContentActive(m.BottomContent)
    m.mainItemsSelected.visible = true
  else
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
  m.top.itemSelected = item.id
End Function
