' Wrapper around the m.screenStack push interface to handle analytics events
' Push a screen on to the stack, allowing the back button to retrace steps
Function pushScreen(screen As Object, sendNavigateEvents = true, sendLoadingEvents = true)
  tubiLog("ScreenStackHelpers.pushScreen " + screen.id)
  m.sentSponsorPixels = {} '//refresh this associative array that keeps track of the viewing of the sponsor images. Only send out the sponsor pixels once per page load so refresh upon a loading of a new screen.
  setSponsorshipBackground("") '//reset the sponsorship background whenever a screen is pushed

  current = m.screenStack.current
  if current <> invalid
    'handle user tracking for navigating to screen
    if sendNavigateEvents = true
      screenTrackingNavigate(current.trackingPageInfo, screen.trackingPageInfo, current.trackingComponentInfo)
    end if
  end if

  'handle user tracking for loading screen
  if sendLoadingEvents = true
    screenTrackingLoad(screen.trackingPageInfo)
  end if

  ' don't focus the pushed screen if there is an active modal
  modal = getTopModal()
  if modal <> invalid AND modal.isInFocusChain() = true AND modal.isHidden = false then
    screen.shouldFocusWhenPushed = false
  end if

  m.screenStack.push = screen
End Function


' Tells the screen stack to focus onto the current screen
Function focusCurrentScreen()
  m.screenStack.focusCurrent = true
End Function


' Remove a screen with a particular ID IF there is more than 1 screen in the stack.
' @param id: string, the id of the screens which should be removed from the stack. If there are multiple screens in the stack with the ID, then the top most screen will be removed
Function removeTopMostScreenWithIDFromStack(id)
  if m.screenStack.getChildCount() > 1
    '//check if the top most screen has the passed ID, and then use the pop function
    current = m.screenStack.current
    if current <> invalid AND current.id = id
      popScreen(false, false)
    else
      m.screenStack.idToRemoveScreenFromStack = id
    end if
  end if
End Function


' Wrapper around the m.screenStack push interface to handle analytics events
' Remove the top-most screen of the stack, making the previous screen visible
'
' @sendNavigateEvents: boolean, don't send NavigateToPage analytics events. This might be useful in the
'                               case where a page fails to load but the page was already added to the screen
'                               stack, and now the screen must be removed from screen stack, but the user did
'                               not purposefully navigate back
' @sendLoadingEvents: boolean, don't send PageLoad analytics event when removing the screen from the stack.
'                              This might be useful in the case where the screen below the screen being popped
'                              must be created and the PageLoad event should be fired once it is fully loaded.
'                              An example of this is when the user signs out.
Function popScreen(sendNavigateEvents = true, sendLoadingEvents = true)
  tubiLog("ScreenStackHelpers.popScreen")
  m.sentSponsorPixels = {} '//refresh this associative array that keeps track of the viewing of the sponsor images. Only send out the sponsor pixels once per page load so refresh upon an unloading of a screen.
  setSponsorshipBackground("") '//reset the sponsorship background whenever a screen is popped

  toBePopped = getCurrentScreen()
  topHidden = getHiddenScreen(1)

  ' If the screen to be popped is the only screen, it will leave an empty screen stack.
  ' In the case of an empty screen stack, we will build a home page. From an analytics standpoint
  ' this is like navigating from the screen to be popped to the homescreen. So, create a fake
  ' home screen for analytics purposes.
  if topHidden = invalid
    topHidden = {
      trackingPageInfo: {
        pageType: "home_page"
        pageValues: {}
      }
    }
  end if

  if sendNavigateEvents = true AND topHidden <> invalid AND toBePopped <> invalid
    screenTrackingNavigate(toBePopped.trackingPageInfo, topHidden.trackingPageInfo)
  end if

  if sendLoadingEvents = true AND topHidden <> invalid
    screenTrackingLoad(topHidden.trackingPageInfo)
  end if

  m.screenStack.pop = true
End Function


' Get a screen at any depth in the stack. Depth of 0 is the top most screen (aka getCurrentScreen())
' May return invalid if depth greater than the number of screens in the screen stack.
Function getHiddenScreen(depth = 1)
  screenCount = m.screenStack.getChildCount()
  return m.screenStack.getChild(screenCount - depth - 1)
End Function


' iterates over screen stack from top to bottom and returns the first screen found with an id that
' matches the id of the screen passed in
'
' @screenId: string, the id of the screen that is being searched for
Function getScreenFromStackById(screenId)
  for i = m.screenStack.getChildCount() - 1 to 0 step -1
    screen = m.screenStack.getChild(i)

    if screen.id = screenId
      return screen
    end if
  end for

  return invalid
End Function


' Wrapper for getting the current screen field from the screen stack.
Function getCurrentScreen()
  return m.screenStack.current
End Function


' 'tracking for navigating to a screen
Function screenTrackingNavigate(oldTrackingPageInfo, newTrackingPageInfo, trackingComponentInfo = invalid)
  sourcePageType = ""
  sourcePageValues = {}
  if oldTrackingPageInfo <> invalid
    sourcePageType = oldTrackingPageInfo.pageType
    sourcePageValues = oldTrackingPageInfo.pageValues
  end if

  destPageType = ""
  destPageValues = {}
  if newTrackingPageInfo <> invalid
    destPageType = "dest_" + newTrackingPageInfo.pageType
    destPageValues = newTrackingPageInfo.pageValues
  end if

  trackingComponentType = ""
  trackingComponentValues = {}
  if trackingComponentInfo <> invalid
    trackingComponentType = trackingComponentInfo.componentType
    trackingComponentValues = trackingComponentInfo.componentValues
  end if

  m.trackingLoggingTask.trackEvent = {
    type: "navigate_to_page"
    values: {
      pageOneof: m.Tracking.getAnalyticsPage(sourcePageType, sourcePageValues)  'page navigating from - a valid page type (see NavigateToPageEvent in events.protos)
      componentOneof: m.Tracking.getAnalyticsComponent(trackingComponentType, trackingComponentValues)
      dest_pageOneof: m.Tracking.getAnalyticsPage(destPageType, destPageValues) 'page navigating to - a valid page type (see NavigateToPageEvent in events.protos)
    }
  }
End Function


''''''''''''''''''''
' screenTrackingLoad
'
' tracking for loading a new screen
Function screenTrackingLoad(trackingPageInfo, loadTime=0, success=true)
  pageType = ""
  pageValues = {}
  if trackingPageInfo <> invalid
    pageType = trackingPageInfo.pageType
    pageValues = trackingPageInfo.pageValues
  end if

  if success = true
    status = "SUCCESS"
  else
    status = "FAIL"
  end if

  'tracking for loading screen
  m.trackingLoggingTask.trackEvent = {
    type: "page_load"
    values: {
      pageOneof: m.Tracking.getAnalyticsPage(pageType, pageValues)  'a valid page type (see PageLoadEvent in events.protos)
      load_time: loadTime
      status: status  'ActionStatus enum
    }
  }
End Function


Function printScreenStack()
  for i=0 to m.screenStack.getChildCount()-1
    screen = m.ScreenStack.getChild(i)
    print "stack["; i;"]: "; screen.subtype(); " id = "; screen.id
  end for
End Function


' Wrapper around the m.screenStack shrink interface which keeps the top x most screens and removes the rest
' of the screens from underneath them
Function shrinkScreenStack(keepAmt)
  tubiLog("ScreenStackHelpers.shrinkScreenStack")
  m.screenStack.shrinkStack = keepAmt
End Function


' Wrapper around the m.screenStack clear interface which removes all screen in the stack
Function clearScreenStack()
  tubiLog("ScreenStackHelpers.clearScreenStack")
  m.screenStack.clearStack = true
End Function


' Wrapper around m.screenStack.getChildCount() to find out how many screens are currently in the stack
Function getScreenStackSize()
  tubiLog("ScreenStackHelpers.getScreenStackSize")
  return m.screenStack.getChildCount()
End Function


' Callback to fire when m.screenStack is empty - should only happen in the case of deeplinks
Function onScreenStackEmpty()
  tubiLog("ScreenStackHelpers.onScreenStackEmpty")
  startChannel()
End Function


Function onScreenChange()
  currentScreen = getCurrentScreen()
  if currentScreen <> invalid AND currentScreen.id <> invalid
    bSideNavVisible = (m.constants.ui.sideNavOpenIds[currentScreen.id] = true)
    m.sideNav.visible = bSideNavVisible
  end if
  ' Processing any queued braze messaging if they are queued due to being in non whitelisted screens.
  processQueuedInAppMessage()
End Function


Function getScreenIdsFromStack()
  ' Looping through the child nodes of stack to find all the screens in stack.
  screenIds = []
  ' Gets all childrens.
  screens = m.screenStack.getChildren(-1, 0)
  for each screen in screens
    screenIds.push(screen.id)
  end for

  return screenIds
End Function


' Returns all the screens in the screen stack in an array
Function getScreensInStack()
  return m.screenStack.getChildren(-1, 0)
End Function
