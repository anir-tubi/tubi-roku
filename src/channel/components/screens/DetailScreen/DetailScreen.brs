Function init()
  m.Info = m.top.findNode("DetailInfoPanel")
  m.Menu = m.top.findNode("Menu")
  m.ResumeMenuItem = m.top.findNode("ResumeMenuItem")
  m.PlayMenuItem = m.top.findNode("PlayMenuItem")
  m.EpisodesMenuItem = m.top.findNode("EpisodesMenuItem")
  m.AddQueueMenuItem = m.top.findNode("AddQueueMenuItem")
  m.RemoveQueueMenuItem = m.top.findNode("RemoveQueueMenuItem")
  m.RemoveHistoryMenuItem = m.top.findNode("RemoveHistoryMenuItem")
  m.WatchTrailerMenuItem = m.top.findNode("WatchTrailerMenuItem")

  m.top.observeField("length", "onLengthChange")
  m.top.observeField("isSeries", "onIsSeries")
  m.top.observeField("isBookmark", "onIsBookmark")
  m.top.observeField("isHistory", "onIsHistory")
  m.top.observeField("resumePoint", "onResumePointChange")
  m.top.observeField("hasTrailer", "onHasTrailer")
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("addToQueueTitle", "onAddToQueueTitleChange")
  m.top.observeField("removeQueueTitle", "onRemoveFromQueueTitleChange")
  m.Menu.observeField("itemSelected", "onMenuItemSelected")

  m.defaultHeroUri = "pkg:/images/art-blur-background.png"
  setInitialMenuItems()
End Function

Function onScreenFocusChange()
  tubiLog("DetailScreen.onScreenFocusChange")
  if m.top.hasFocus() then
    ' defaulted to screen, move to a subcomponent
    m.Menu.setFocus(true)
  end if
End Function


Function onLengthChange()
  tubiLog("DetailScreen.onLengthChange")
  m.ResumeMenuItem.length = m.top.length
End Function


Function onResumePointChange()
  tubiLog("DetailScreen.onResumePointChange")
  menuItems = cloneDeep(m.Menu.content)
  resumeIndex = getChildIndexById(m.Menu.content, m.ResumeMenuItem.id)

  m.ResumeMenuItem.playstart = m.top.resumePoint
  if resumeIndex = -1 and m.top.resumePoint > 0
    menuItems.insertChild(m.ResumeMenuItem, 0)
    m.Menu.content = menuItems
  else if resumeIndex > -1 and m.top.resumePoint = 0
    menuItems.removeChildIndex(resumeIndex)
    m.Menu.content = menuItems
  end if
End Function


Function onIsBookmark()
  tubiLog("DetailScreen.onIsBookmark")
  'reset the value in the case that add to queue button was pressed and title is currently "Adding"
  m.AddQueueMenuItem.title = "Add to queue"
  m.RemoveQueueMenuItem.title = "Remove from queue"
  
  menuItems = cloneDeep(m.Menu.content)
  addQueueIndex = getChildIndexById(m.Menu.content, m.AddQueueMenuItem.id)
  removeQueueIndex = getChildIndexById(m.Menu.content, m.RemoveQueueMenuItem.id)

  if m.top.isBookmark = false
    if addQueueIndex = -1
    'add queue item doesn't exist
      if removeQueueIndex > -1
        'remove queue item does exist so replace remove queue item with add queue item
        menuItems.removeChildIndex(removeQueueIndex)
        menuItems.insertChild(m.AddQueueMenuItem, removeQueueIndex)
      else
        menuItems.appendChild(m.AddQueueMenuItem)
      end if
    else if removeQueueIndex > -1
      'both add to queue and remove from queue items exist... this shouldn't happen
      menuItems.removeChildIndex(removeQueueIndex)
    end if
  else
    if removeQueueIndex = -1
      'remove queue item doesn't exist
      if addQueueIndex > -1
        'add queue item exists, so replace add queue item with remove queue item
        menuItems.removeChildIndex(addQueueIndex)
        menuItems.insertChild(m.RemoveQueueMenuItem, addQueueIndex)
      else
        menuItems.appendChild(m.RemoveQueueMenuItem)
      end if
    else if addQueueIndex > -1
      'both add to queue and remove from queue items exist... this shouldn't happen
      menuItems.removeChildIndex(m.AddQueueMenuItem)
    end if
  end if
  m.Menu.content = menuItems
End Function


Function onIsHistory()
  tubiLog("DetailScreen.onIsHistory")
  removeHistoryIndex = getChildIndexById(m.Menu.content, m.RemoveHistoryMenuItem.id)
  previousItems = [m.AddQueueMenuItem, m.RemoveQueueMenuItem]
  addRemoveMenuItem(m.top.isHistory, removeHistoryIndex, m.RemoveHistoryMenuItem, previousItems)
End Function


Function onIsSeries()
  tubiLog("DetailScreen.onIsSeries")
  episodeIndex = getChildIndexById(m.Menu.content, m.EpisodesMenuItem.id)
  addRemoveMenuItem(m.top.isSeries, episodeIndex, m.EpisodesMenuItem, [m.PlayMenuItem])
End Function


Function onHasTrailer()
  tubiLog("DetailScreen.onHasTrailer")
  trailerIndex = getChildIndexById(m.Menu.content, m.WatchTrailerMenuItem.id)
  addRemoveMenuItem(m.top.hasTrailer, trailerIndex, m.WatchTrailerMenuItem, [m.PlayMenuItem])
End Function


Function onAddToQueueTitleChange()
  tubiLog("DetailScreen.onAddToQueueTitleChange")
  m.AddQueueMenuItem.title = m.top.addToQueueTitle
End Function


Function onRemoveFromQueueTitleChange()
  tubiLog("DetailScreen.onRemoveFromQueueTitleChange")
  m.RemoveQueueMenuItem.title = m.top.removeQueueTitle
End Function


''''''''''''''''''''''
' setInitialMenuItems
'
' Detail screen always has at least a play button and "add to queue" button
' Set basic buttons first, additional buttons will be added based on the input fields of the details screen
Function setInitialMenuItems() As Void
  tubiLog("DetailScreen.setInitialMenuItems")
  menuItems = CreateObject("roSGNode", "ContentNode")
  menuItems.appendChild(m.PlayMenuItem)
  menuItems.appendChild(m.AddQueueMenuItem)
  ' m.AddQueueMenuItem.title = "Add to queue"
  m.Menu.content = menuItems
End Function


''''''''''''''''''''''
' addRemoveMenuItem
'
' add or remove a specific menu item
' @add: boolean, add an item if true, remove if false
' @itemIndex: int, index location of the item in the menuItems. -1 indicates the item does not exist in the menuItems.
' @itemToAdd: one of the DetailMenuItemContentNode children of the DetailScreen (ie m.EpisodesMenuItem). This is optional for remove.
' @previousItem: array, indicates which existing item the added item will follow. If the array contains multiple items,
'                       the first item in the array that is found will dictate the placement of the new item, 
'                       and all other items will be disregarded.
' Set basic buttons first, additional buttons will be added based on the input fields of the details screen
Function addRemoveMenuItem(add, itemIndex, itemToAdd = invalid, previousItems = []) As Void
  menuItems = cloneDeep(m.Menu.content)

  if add = false and itemIndex > -1
    'menu item exists, so we need to remove it
    menuItems.removeChildIndex(itemIndex)
    m.Menu.content = menuItems
  else if add = true and itemIndex = -1
    'we don't have menu item, and need to add one
    'find the previous item index, and insert the Watch Trailer item one index after
    previousItemIndex = -1
    if itemToAdd <> invalid and previousItems <> invalid and previousItems.count() > 0
      for i=0 to previousItems.count()-1
        previousItemIndex = getChildIndexById(menuItems, previousItems[i].id)
        if previousItemIndex > -1
          exit for
        end if
      end for
    end if

    if previousItemIndex > -1
      menuItems.insertChild(itemToAdd, previousItemIndex + 1)
    else
      menuItems.appendChild(itemToAdd)
    end if

    m.Menu.content = menuItems
  end if
End Function


''''''''''''''''''''''''
' onMenuItemSelected
'
Function onMenuItemSelected()
  tubiLog("DetailScreen.onMenuItemSelected")

  selection = m.Menu.content.getChild(m.Menu.itemSelected)
  if selection <> invalid then
    print "Menu item selected: " + selection.title

    if selection.id = "ResumeMenuItem" then
      m.top.resumeSelected = true
    else if selection.id = "PlayMenuItem" then
      m.top.playSelected = true
    else if selection.id = "WatchTrailerMenuItem" then
      m.top.watchTrailerSelected = true
    else if selection.id = "EpisodesMenuItem"
      m.top.episodeListSelected = true
    else if selection.id = "AddQueueMenuItem" then
      m.top.addToQueueSelected = true
    else if selection.id = "RemoveQueueMenuItem" then
      m.top.removeFromQueueSelected = true
    else if selection.id = "RemoveHistoryMenuItem" then
      m.top.removeFromHistorySelected = true
    end if
  end if
End Function


''''''''''''''''''''
' onDialogButton
'
Function onDialogButton()
  buttonSelected = m.Dialog.buttonSelected
  m.top.removeChild(m.Dialog)
  m.Dialog.unobserveField("buttonSelected")
  m.Dialog = invalid
  m.Menu.setFocus(true)
  if buttonSelected = 0 then
    m.top.signInSelected = true
  end if
End Function


'''''''''''''''''''''''
' onKeyEvent
'
' Hijack any back button presses before they make it to the screen stack if we are waiting for a server
' response from any of add/remove queue/history so that we make sure the category screen can update with new user category content
Function onKeyEvent(key As String, press As Boolean)
  tubiLog("DetailScreen.onKeyEvent key = " + key)
  if press then
    if key = "back"
      if m.top.isWaitingForServerResponse = true
        return true
      end if
    end if
  end if

  return false
End Function


