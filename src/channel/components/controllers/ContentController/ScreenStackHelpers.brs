' Wrapper around the m.screenStack push interface to handle analytics events
' Push a screen on to the stack, allowing the back button to retrace steps
Function pushScreen(screen As Object, sendNavigateEvents = true as Boolean, sendLoadingEvents = true as Boolean)
  tubiLog("ScreenStackHelpers.pushScreen")
  current = m.screenStack.current
  
  'handle user tracking for navigating to screen
  if sendNavigateEvents = true and current <> invalid
    screenTrackingNavigate(current.trackingPageInfo, screen.trackingPageInfo, current.trackingComponentInfo)
  end if
  
  'handle user tracking for loading screen
  if sendLoadingEvents = true
    screenTrackingLoad(screen.trackingPageInfo)
  end if

  m.screenStack.push = screen
End Function


' Wrapper around the m.screenStack push interface to handle analytics events
' Remove the top-most screen of the stack, making the previous screen visible
Function popScreen(sendTrackingEvents = true as Boolean)
  tubiLog("ScreenStackHelpers.popScreen")
  toBePopped = currentScreen()
  topHidden = getHiddenScreen(1)

  if sendTrackingEvents = true and topHidden <> invalid
    if toBePopped <> invalid
      screenTrackingNavigate(toBePopped.trackingPageInfo, topHidden.trackingPageInfo)
    end if
    
    screenTrackingLoad(topHidden.trackingPageInfo)
  end if

  m.screenStack.pop = true
End Function


' Get a screen at any depth in the stack. Depth of 0 is the top most screen (aka currentScreen())
' May return invalid if depth greater than the number of screens in the screen stack.
Function getHiddenScreen(depth = 1)
  screenCount = m.screenStack.getChildCount()
  return m.screenStack.getChild(screenCount - depth - 1)
End Function



' Wrapper for getting the current screen field from the screen stack.
' This is mostly used for legacy reasons because currentScreen() exists in a lot of places in the code before
' screen stack functionality was refactored.
Function currentScreen()
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
      status: "UNKNOWN_ACTION_STATUS" 'ActionStatus enum
      triggerType: "UNKNOWN" 'TriggerType enum
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
    print "stack["; i; "]: "; screen.subtype(); " id = "; screen.id
  end for
End Function


' Wrapper around the m.screenStack clear interface to handle analytics events
Function clearScreenStack()
  tubiLog("ScreenStackHelpers.clearScreenStack")
  m.screenStack.clearStack = true
End Function


' Callback to fire when m.screenStack is empty
Function onScreenStackEmpty()
  tubiLog("ScreenStackHelpers.onScreenStackEmpty")
  ' if we went straight to detail screen for a deep link, launch the home screen.
  ' After we have entered the home screen, ignore back button presses
  if m.enteredFromDeepLink
    popScreen()  ' remove the last screen, probably detail screen
    m.enteredFromDeepLink = false
    startChannel()
  else
    showExitAppModal("onExitAppModalButtonSelected")
    m.trackingLoggingTask.trackEvent = {
      type: "dialog"
      values: {
        dialog_type: "INFORMATION"   'DialogType enum
        pageOneof: m.Tracking.getAnalyticsPage("home_page", {})
      }
    }
  end if
End Function
