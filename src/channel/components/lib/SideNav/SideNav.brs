Function init()
  m.top.observeFieldScoped("focusedChild", "onFocusChange")
  m.top.observeFieldScoped("userName", "onSignedIn")
  m.top.observeFieldScoped("opened", "onOpenedChange")
  m.top.observeFieldScoped("itemRequested", "onItemRequested")
  m.BottomContent = m.top.findNode("BottomContent")
  m.MainContent = m.top.findNode("MainContent")
  m.TopContent = m.top.findNode("TopContent")
  m.profileContent = m.top.findNode("profile")

  m.topItems = m.top.findNode("topItems")
  initList(m.topItems)

  m.bottomItems = m.top.findNode("bottomItems")
  initList(m.bottomItems)

  m.mainItems = m.top.findNode("mainItems")
  initList(m.mainItems)

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
  setDrawFocusFeedback(list)
End Function


Function onFocusChange()
  if m.top.isInFocusChain() = true
    if m.top.hasFocus() = true
      '//set the focus on the last selected item
      if m.listItemSelected <> invalid
        list = m.top.findNode(m.listItemSelected.list)
        list.setFocus(true)
        list.jumpToItem = m.listItemSelected.index
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
    fade(m.topItems, "in", 0.2)
    fade(m.bottomItems, "in", 0.2)
    setContentActive(m.TopContent)
    setContentActive(m.MainContent)
    setContentActive(m.BottomContent)
  else
    fade(m.topItems, "out", 0.2)
    fade(m.bottomItems, "out", 0.2)
    setContentActive(m.TopContent, false)
    setContentActive(m.MainContent, false)
    setContentActive(m.BottomContent, false)
  end if
End Function

Function refresh()
  onOpenedChange()
End Function

Function setContentActive(content, bActive = true)
  for i = 0 to content.getChildCount()-1
    item = content.getChild(i)
    item.active = bActive
    if m.itemSelectedRemembered = item.id
      item.selected = true
    else 
      item.selected = false
    end if
  end for
End Function


Function onItemRequested()
  if m.top.itemRequested <> invalid and m.top.itemRequested <> "" and m.top.itemRequested <> m.itemSelectedRemembered 
    '//Go thru the lists and select the option that matxches the itemRequested
    if focusItemInList(m.mainItems, m.top.itemRequested) < 0
      if focusItemInList(m.bottomItems, m.top.itemRequested) < 0
        focusItemInList(m.topItems, m.top.itemRequested)
      end if
    end if
  end if
End Function


Function focusItemInList(list, sID)
  index = -1
  content = list.content
    index = -1
    for i = 0 to content.getChildCount() - 1
      item = content.getChild(i)
      if item.id = sID 
        index = i
        exit for
      end if
    end for
    if index >= 0
      list.jumpToItem = index
      m.listItemSelected = {
        list: list.id
        index: index
      }
      m.itemSelectedRemembered = item.id
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
  m.itemSelectedRemembered = item.id
  m.top.itemSelected = item.id
End Function
