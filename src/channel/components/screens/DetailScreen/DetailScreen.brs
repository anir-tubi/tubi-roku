Function init()
  m.trackingLoggingTask = m.global.trackingLoggingTask
  m.constants = m.global.constants
  Request = TubiRequest()
  Auth = TubiAuth(m.constants, Request)
  m.Tracking = TubiTracking(m.constants, Request, Auth)
  m.NodeHelpers = TubiNodeHelpers()
  m.Info = m.top.findNode("DetailInfoPanel")
  m.Menu = m.top.findNode("Menu")
  m.ResumeMenuItem = m.top.findNode("ResumeMenuItem")
  m.PlayMenuItem = m.top.findNode("PlayMenuItem")
  m.EpisodesMenuItem = m.top.findNode("EpisodesMenuItem")
  m.AddQueueMenuItem = m.top.findNode("AddQueueMenuItem")
  m.RemoveQueueMenuItem = m.top.findNode("RemoveQueueMenuItem")
  m.RemoveHistoryMenuItem = m.top.findNode("RemoveHistoryMenuItem")
  m.ChannelMenuItem = m.top.findNode("ChannelMenuItem")
  m.WatchTrailerMenuItem = m.top.findNode("WatchTrailerMenuItem")
  m.RelatedContentGroup = m.top.findNode("RelatedContentGroup")
  m.RelatedGrid = m.top.findNode("RelatedGrid")
  m.RelatedTitle = m.top.findNode("RelatedTitle")
  m.RelatedRowLabel = m.top.findNode("RelatedRowLabel")
  m.AnimationGroup = m.top.findNode("AnimationGroup")

  m.top.observeField("length", "onLengthChange")
  m.top.observeField("isSeries", "onIsSeries")
  m.top.observeField("isBookmark", "onIsBookmark")
  m.top.observeField("isHistory", "onIsHistory")
  m.top.observeField("isChannelItem", "onIsChannel")
  m.top.observeField("resumePoint", "onResumePointChange")
  m.top.observeField("hasTrailer", "onHasTrailer")
  m.top.observeField("focusedChild", "onScreenFocusChange")
  m.top.observeField("addToQueueTitle", "onAddToQueueTitleChange")
  m.top.observeField("removeQueueTitle", "onRemoveFromQueueTitleChange")
  m.top.observeField("removeHistoryTitle", "onRemoveFromHistoryTitleChange")
  m.top.observeField("channelName", "onChannelNameChange")
  m.top.observeField("channelImage", "onChannelImageChange")
  m.top.observeField("isLoading", "onIsLoading")
  m.Menu.observeField("itemSelected", "onMenuItemSelected")
  m.top.observeField("relatedContent", "onRelatedContentChange")
  m.RelatedGrid.observeField("itemSelected", "onRelatedContentSelected")
  m.RelatedGrid.observeField("itemFocused", "onRelatedItemFocused")
  m.top.observeField("jumpToItem", "onJumpToItem")
  m.Info.observeField("descriptionSelected", "onDescriptionSelected")

  m.defaultHeroUri = "pkg:/images/art-blur-background.png"
  setInitialMenuItems()
  m.focusTarget = m.Menu

  m.focusAnimationDuration = 0.4

  ' modal popup to show full, scrollable description
  m.descriptionModal = invalid

  'set initial tracking values
  m.top.trackingPageInfo = {
    pageType: "video_page"
    pageValues: {
      video_id: 0
    }
  }

  ' Used to determine if navigate_within_page events should be sent. Only send when the related content already
  ' has focus, not when it gains focus.
  m.relatedHasFocus = false
End Function

Function onDescriptionSelected()
  tubiLog("DetailScreen.onDescriptionSelected")
  m.descriptionModal = CreateObject("roSGNode", "ModalDialogScreen")
  m.descriptionModal.title = "Full Synopsis"
  m.descriptionModal.scrollable = true
  m.descriptionModal.message = m.top.description
  m.descriptionModal.buttons = ["Close"]
  m.descriptionModal.observeFieldScoped("buttonSelected", "onCloseDescriptionModal")
  m.descriptionModal.observeFieldScoped("exitButton", "onCloseDescriptionModal")
  m.top.appendChild(m.descriptionModal)
  m.descriptionModal.setFocus(true)

  m.trackingLoggingTask.trackEvent = {
    type: "dialog"
    values: {
      dialog_type: "INFORMATION"
      pageOneof: m.Tracking.getAnalyticsPage("video_page", {video_id: m.top.content.id.toInt()}) 
    }
  }
End Function

Function onCloseDescriptionModal()
  tubiLog("DetailScreen.onCloseDescriptionModal")
  m.top.removeChild(m.descriptionModal)
  m.descriptionModal = invalid
  m.top.setFocus(true)
End Function


Function onJumpToItem()
  focusMenu(true)
End Function

Function onScreenFocusChange()
  tubiLog("DetailScreen.onScreenFocusChange")
  if m.top.hasFocus() then
    m.focusTarget.setFocus(true)
    ' force a background update
    m.top.backgroundUriList = m.top.backgroundUriList

    'determine if the content should be refreshed
    if shouldRefresh(m.top.content) = true or shouldRefresh(m.top.relatedContent) = true
      m.top.refreshContent = true
    end if
  end if
End Function

Function onLengthChange()
  tubiLog("DetailScreen.onLengthChange")
  m.ResumeMenuItem.length = m.top.length
End Function


Function onResumePointChange()
  tubiLog("DetailScreen.onResumePointChange")
  menuItems = m.Menu.content
  resumeIndex = m.NodeHelpers.getChildIndexById(menuItems, m.ResumeMenuItem.id)

  m.ResumeMenuItem.playstart = m.top.resumePoint
  if resumeIndex = -1 and m.top.resumePoint > 0
    menuItems.insertChild(m.ResumeMenuItem, 0)
  else if resumeIndex > -1 and m.top.resumePoint = 0
    menuItems.removeChildIndex(resumeIndex)
  end if
  m.Menu.content = menuItems
End Function


Function onIsBookmark()
  tubiLog("DetailScreen.onIsBookmark")
  'reset the value in the case that add to queue button was pressed and title is currently "Adding"
  m.AddQueueMenuItem.title = "Add to queue"
  m.RemoveQueueMenuItem.title = "Remove from queue"
  
  menuItems = m.Menu.content
  addQueueIndex = m.NodeHelpers.getChildIndexById(menuItems, m.AddQueueMenuItem.id)
  removeQueueIndex = m.NodeHelpers.getChildIndexById(menuItems, m.RemoveQueueMenuItem.id)

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
  'reset the value in the case that remove from history button was pressed and title is currently "Removing..."
  m.RemoveHistoryMenuItem.title = "Remove from history"

  'if removing from history, remove the resume button
  resumeIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.ResumeMenuItem.id)
  if not m.top.isHistory
    addRemoveMenuItem(m.top.isHistory, resumeIndex)
  end if

  removeHistoryIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.RemoveHistoryMenuItem.id)
  previousItems = [m.AddQueueMenuItem, m.RemoveQueueMenuItem]
  addRemoveMenuItem(m.top.isHistory, removeHistoryIndex, m.RemoveHistoryMenuItem, previousItems)
End Function


Function onIsChannel()
  tubiLog("DetailScreen.onIsChannel")
  channelIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.ChannelMenuItem.id)
  previousItems = [
    m.RemoveHistoryMenuItem
    m.RemoveQueueMenuItem
    m.AddQueueMenuItem
  ]
  addRemoveMenuItem(m.top.isChannelItem, channelIndex, m.ChannelMenuItem, previousItems)
End Function


Function onIsSeries()
  tubiLog("DetailScreen.onIsSeries")
  episodeIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.EpisodesMenuItem.id)
  addRemoveMenuItem(m.top.isSeries, episodeIndex, m.EpisodesMenuItem, [m.PlayMenuItem])
End Function


Function onHasTrailer()
  tubiLog("DetailScreen.onHasTrailer")
  trailerIndex = m.NodeHelpers.getChildIndexById(m.Menu.content, m.WatchTrailerMenuItem.id)
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


Function onRemoveFromHistoryTitleChange()
  tubiLog("DetailScreen.onRemoveFromHistoryTitleChange")
  m.RemoveHistoryMenuItem.title = m.top.removeHistoryTitle
End Function


Function onChannelNameChange()
  tubiLog("DetailScreen.onChannelNameChange")
  m.ChannelMenuItem.title = "Go to " + m.top.channelName
End Function


Function onIsLoading()
  tubiLog("DetailScreen.onIsLoading")
  m.Info.visible = not m.top.isLoading
  m.Menu.visible = not m.top.isLoading
  m.RelatedContentGroup.visible = not m.top.isLoading
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
  menuItems = m.Menu.content

  if add = false and itemIndex > -1
    'menu item exists, so we need to remove it
    menuItems.removeChildIndex(itemIndex)
  else if add = true and itemIndex = -1
    'we don't have menu item, and need to add one
    'find the previous item index, and insert the Watch Trailer item one index after
    previousItemIndex = -1
    if itemToAdd <> invalid and previousItems <> invalid and previousItems.count() > 0
      for i=0 to previousItems.count()-1
        previousItemIndex = m.NodeHelpers.getChildIndexById(menuItems, previousItems[i].id)
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

  end if
  m.Menu.content = menuItems
End Function


''''''''''''''''''''''''
' onMenuItemSelected
'
Function onMenuItemSelected()
  tubiLog("DetailScreen.onMenuItemSelected")

  selection = m.Menu.content.getChild(m.Menu.itemSelected)
  if selection <> invalid then
    print "Menu item selected: " + selection.title

    if selection.id = "ResumeMenuItem"
      m.top.resumeSelected = true
    else if selection.id = "PlayMenuItem"
      m.top.playSelected = true
    else if selection.id = "WatchTrailerMenuItem"
      m.top.watchTrailerSelected = true
    else if selection.id = "EpisodesMenuItem"
      m.top.episodeListSelected = true
    else if selection.id = "AddQueueMenuItem"
      m.top.addToQueueSelected = true
    else if selection.id = "RemoveQueueMenuItem"
      m.top.removeFromQueueSelected = true
    else if selection.id = "RemoveHistoryMenuItem"
      m.top.removeFromHistorySelected = true
    else if selection.id = "ChannelMenuItem"
      m.top.channelSelected = true
    end if
  end if
End Function


Function onRelatedContentChange()
  tubiLog("DetailScreen.onRelatedContentChange")
  if m.top.relatedContent <> invalid and m.top.relatedContent.getChildCount() > 0
    m.RelatedContentGroup.visible = true
    ' To force a single row in postergrid, set the columns
    m.RelatedGrid.numColumns = m.top.relatedContent.getChildCount()
  else
    m.RelatedContentGroup.visible = false
    if m.RelatedContentGroup.isInFocusChain()
      focusMenu()
    end if
  end if
End Function


Function onRelatedContentSelected()
  m.relatedHasFocus = false

  'set the component info so it can be used in navigate_to_page event
  selectedContent = m.RelatedGrid.content.getChild(m.RelatedGrid.itemSelected)
  col = m.RelatedGrid.itemSelected + 1
  row = 1
  m.top.trackingComponentInfo = {
    componentType: "related_component"
    componentValues: m.Tracking.getAnalyticsTile(selectedContent, col, row)
  }

  m.top.relatedContentSelected = m.RelatedGrid.itemSelected
End Function


Function onRelatedItemFocused()
  tubiLog("DetailScreen.onRelatedItemFocused")
  if m.RelatedGrid.content <> invalid
    focusedContent = m.RelatedGrid.content.getChild(m.RelatedGrid.itemFocused)
    if focusedContent <> invalid
      m.RelatedTitle.text = focusedContent.title
    end if

    ' trigger navigate_within_page events in ContentController
    if m.relatedHasFocus = true
      col = m.RelatedGrid.itemFocused + 1
      row = 1
      ymalComponent = {
        content_tile: m.Tracking.getAnalyticsTile(focusedContent, col, row)
      }
      videoId = m.top.content.id.toInt()

      m.top.navigateWithinPageInfo = {
        pageOneof: m.Tracking.getAnalyticsPage("video_page", {video_id: videoId} )
        componentOneof: m.Tracking.getAnalyticsComponent("related_component", ymalComponent) 'category_list_component doesn't exist in protos
        means_of_navigation: "SCROLL"  'MeansOfNavigation enum
        vertical_location: row '1 based index
        vertical_location_mode: "INDEX"  'LocationMode enum
        horizontal_location: col
        horizontal_location_mode: "COORDINATE"  'LocationMode enum
      }
    end if
    m.relatedHasFocus = true
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
      if not m.top.isWaitingForServerResponse
        m.top.backButtonPressed = true
      end if
      return true
    end if
    ' Down presses arrive here if not consumed by the menu, meaning it's already at the bottom button
    if key = "down"
      if m.Menu.isInFocusChain() and m.RelatedContentGroup.visible then
        focusRelated()
        return true
      else if m.Info.isInFocusChain()
        focusMenu()
        return true
      end if
    end if
    if key = "up"
      if m.RelatedGrid.isInFocusChain()
        focusMenu()
        return true
      else if m.Menu.isInFocusChain() and m.Info.isDescriptionEllipsized
        focusInfo()
        return true
      end if
    end if
    if key = "OK"
      '//ensure this keypress is captured so the default Roku positive audio sound is played.
      return true
    end if
  end if

  return false
End Function


Function focusMenu(immediately=false)
  m.focusTarget = m.Menu
  if immediately
    m.AnimationGroup.translation = [0,0]
    m.RelatedContentGroup.opacity = 0.2
    m.Info.opacity = 1.0
  else
    slideTo(m.AnimationGroup, [0,0], m.focusAnimationDuration)
    animate(m.RelatedContentGroup, { opacity: 0.2, duration: m.focusAnimationDuration})
    animate(m.Info, { opacity: 1.0, duration: m.focusAnimationDuration})
  end if
  if m.top.isInFocusChain()
    m.Menu.setFocus(true)
    m.relatedHasFocus = false
  end if
End Function


Function focusRelated()
  m.focusTarget = m.RelatedGrid
  if m.top.isInFocusChain()
    m.RelatedGrid.setFocus(true)
  end if
  slideTo(m.AnimationGroup, [0,-392], m.focusAnimationDuration)
  animate(m.RelatedContentGroup, { opacity: 1.0, duration: m.focusAnimationDuration })
  animate(m.Info, { opacity: 0.2, duration: m.focusAnimationDuration })
End Function


Function focusInfo()
  m.focusTarget = m.Info
  if m.top.isInFocusChain()
    m.Info.setFocus(true)
  end if
End Function
