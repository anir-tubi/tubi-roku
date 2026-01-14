' Wrapper around the m.screenStack push interface to handle analytics events
' Push a screen on to the stack, allowing the back button to retrace steps
Function pushScreen(screen as Object, sendNavigateEvents = true, sendLoadingEvents = true)
  tubiLog("ScreenStackHelpers.pushScreen " + screen.id)
  resetScreenStack()

  current = m.screenStack.current
  if current <> invalid
    'handle user tracking for navigating to screen
    if sendNavigateEvents = true
      screenTrackingNavigate(current.trackingPageInfo, screen.trackingPageInfo, current.trackingComponentInfo)
      current.trackingComponentInfo = invalid
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


' Remove a specific screen node from the stack
' @param screen: node, the screen node to be removed from the stack
Function removeScreenFromStack(screen)
  if screen <> invalid
    m.screenStack.screenToRemove = screen
  end if
End Function


' Called when a screen is pushed or popped from the screen stack.
Function resetScreenStack()
  m.sentSponsorPixels = {} '//refresh this associative array that keeps track of the viewing of the sponsor images. Only send out the sponsor pixels once per page load so refresh upon an unloading of a screen.
  setSponsorshipBackground("") '//reset the sponsorship background whenever a screen needs to be reset
  setBackgroundColor("") '//reset the background color whenever a screen stack needs to be reset
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
  resetScreenStack()

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
    'Attaching the trackingComponentInfo on NavigateToPage event and resetting it
    screenTrackingNavigate(toBePopped.trackingPageInfo, topHidden.trackingPageInfo, toBePopped.trackingComponentInfo)
    toBePopped.trackingComponentInfo = invalid
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
  if m.screenStack <> invalid
    return m.screenStack.current
  end if

  return invalid
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

  if trackingComponentInfo <> invalid AND trackingComponentInfo.componentType <> invalid
    trackingComponentType = trackingComponentInfo.componentType
    trackingComponentValues = trackingComponentInfo.componentValues
  end if

  eventValues = {
    pageOneof: m.Tracking.getAnalyticsPage(sourcePageType, sourcePageValues) 'page navigating from - a valid page type (see NavigateToPageEvent in events.protos)
    componentOneof: m.Tracking.getAnalyticsComponent(trackingComponentType, trackingComponentValues)
    dest_pageOneof: m.Tracking.getAnalyticsPage(destPageType, destPageValues) 'page navigating to - a valid page type (see NavigateToPageEvent in events.protos)
  }

  if newTrackingPageInfo <> invalid AND newTrackingPageInfo.additionalContextValues <> invalid
    eventValues.append(newTrackingPageInfo.additionalContextValues)
  else if oldTrackingPageInfo <> invalid AND oldTrackingPageInfo.additionalContextValues <> invalid
    ' Handles the case where user is navigating to other screen from the CDC details screen. For ex: registration flow.
    eventValues.append(oldTrackingPageInfo.additionalContextValues)
  end if

  m.trackingLoggingTask.trackEvent = {
    type: "navigate_to_page"
    values: eventValues
  }
End Function


''''''''''''''''''''
' screenTrackingLoad
'
' tracking for loading a new screen
Function screenTrackingLoad(trackingPageInfo, loadTime = 0, success = true)
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

  eventValues = {
    pageOneof: m.Tracking.getAnalyticsPage(pageType, pageValues) 'a valid page type (see PageLoadEvent in events.protos)
    load_time: loadTime
    status: status 'ActionStatus enum
  }

  if trackingPageInfo <> invalid AND trackingPageInfo.additionalContextValues <> invalid
    eventValues.append(trackingPageInfo.additionalContextValues)
  end if

  ' TODO: Create a ticket to refactor our tracking code to make sure all the calls are piped to single method so that it is easier to add additional context in future.
  'tracking for loading screen
  m.trackingLoggingTask.trackEvent = {
    type: "page_load"
    values: eventValues
  }
End Function


Function printScreenStack()
  for i = 0 to m.screenStack.getChildCount() - 1
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
    m.sideNav.visible = (m.constants.ui.sideNavOpenIds[currentScreen.id] = true)
    m.backgroundGroup.screenId = currentScreen.id
  end if
  ' Processing any queued braze messaging if they are queued due to being in non whitelisted screens.
  processQueuedInAppMessage()

  updateInlineVideoMetadataOverlayVisibility()

  if currentScreen <> invalid AND currentScreen.id = m.constants.ui.screenIds.homeScreen AND m.isApplicationSuspendInProgress = false
    if isNode(currentScreen.content) = true
      refreshLiveEventsContainerWithEpgListingInfo(currentScreen.content)
    else
      refreshLiveEventsContainerWithEpgListingInfo(currentScreen.content)
    end if
  end if

  m.performanceMetricsTracker.logMetric("horizontal_scroll_performance")
  m.performanceMetricsTracker.logMetric("vertical_scroll_performance")
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
  if m.screenStack <> invalid then
    return m.screenStack.getChildren(-1, 0)
  end if

  return []
End Function


' Finds a detail screen in the screen stack by screen ID and optional content ID
' Traverses the screen stack from top to bottom looking for a matching screen
' Supports lookup by screen ID alone (when contentId is invalid) or by both screen ID and content ID
' @param id - String, the screen ID to search for (e.g., m.constants.ui.screenIds.vodDetailScreen)
' @param contentId - Optional String or invalid, the content ID to match (default: invalid)
' @return Screen node if found, or invalid if no matching screen exists in the stack
Function getDetailScreenFromStackWithId(id, contentId = invalid)
  detailScreen = invalid
  screenStackDepth = 0
  while detailScreen = invalid
    hiddenScreen = getHiddenScreen(screenStackDepth)

    if hiddenScreen = invalid
      ' we are outside of the screen stack depth so there are no more hidden screens
      exit while
    else if hiddenScreen.id = id AND (contentId = invalid OR (hiddenScreen.content <> invalid AND hiddenScreen.content.id = contentId))
      ' Match found: screen ID matches and either contentId is invalid (match by ID alone) or content ID matches
      detailScreen = hiddenScreen
    else
      screenStackDepth += 1
    end if

  end while

  return detailScreen
End Function
