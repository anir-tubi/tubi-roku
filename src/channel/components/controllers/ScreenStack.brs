''''''''''''''''''''
' initScreenStack
'
' Set the screen stack parent object. This should be an empty Group
Function initScreenStack(stack As Object, stackEmptyCallback=invalid As Object)
  tubiLog("ScreenStack.initScreenStack")
  m.ScreenStack_ = stack
  m.ScreenStackEmptyCallback_ = stackEmptyCallback
  m.ScreenStackOldTop_ = invalid
  stack.observeField("currentViewId", "onScreenStackChange")
End Function


Function onScreenStackChange()
  tubiLog("ScreenStack.onScreenStackChange")
  current = currentScreen()
  if current <> invalid
    current.setFocus(true)
    if m.ScreenStackOldTop_ <> invalid
      screenTrackingNavigate(m.ScreenStackOldTop_.trackingPageInfo, current.trackingPageInfo)
      screenTrackingLoad(current.trackingPageInfo)
      m.ScreenStackOldTop_ = invalid
    end if
  end if
End Function

'''''''''''''''''''''''
' onKeyEvent
'
' Back pressed on detail screen should close it
Function onKeyEvent(key As String, press As Boolean)
  tubiLog("ScreenStack.onKeyEvent key = " + key)
  if m.lastUserActivity <> invalid
    m.lastUserActivity = Uptime(0)
  end if
  if press then
    ' for autohide support, bring the UI back on any keypress
    if m.ScreenStack_.opacity < 1.0 and type(unAutohide) = "Function"
      showUI(key)
      return true
    else if key = "back"
      if m.ScreenStack_.getChildCount() > 1 then
        popScreen(true)
      else if m.ScreenStackEmptyCallback_ <> invalid and type(m.ScreenStackEmptyCallback_) = "roFunction" then
        ' Don't remove the last item, let the callback decide what to do
        m.ScreenStackEmptyCallback_()
      end if
      ' Always consume back button, otherwise it will cause the app to exit
      return true
    end if
  end if
  return false
End Function


''''''''''''''''''''''
' pushScreen
'
' Push a screen on to the stack, allowing the back button to retrace steps
Function pushScreen(screen As Object, sendNavigateEvents = true as Boolean, sendLoadingEvents = true as Boolean)
  tubiLog("ScreenStack.pushScreen")
  current = currentScreen()
  m.ScreenStack_.pushView = screen
  
  'handle user tracking for navigating to screen
  if sendNavigateEvents = true and current <> invalid
    screenTrackingNavigate(current.trackingPageInfo, screen.trackingPageInfo, current.trackingComponentInfo)
  end if
  
  'handle user tracking for loading screen
  if sendLoadingEvents = true
    screenTrackingLoad(screen.trackingPageInfo)
  end if

End Function


''''''''''''''''''''
' pushModal
'
' Push a modal dialog on to the screen stack.  Only difference from
' pushScreen is that we leave the existing currentScreen visible.
Function pushModal(dialog As Object)
  tubiLog("ScreenStack.pushModal")
  m.ScreenStack_.pushView = dialog
End Function


''''''''''''''''''''
' popScreen
'
' Remove the top-most screen of the stack, making the previous screen visible
Function popScreen(sendTrackingEvents = true as Boolean)
  tubiLog("ScreenStack.popScreen")
  current = currentScreen()
  m.NodeHelpers.unobserveAllScoped(current)

  ' m.ScreenStackOldTop_ is used in onScreenStackChange() to fire navigation and page load events.
  ' It must be set before m.ScreenStack_.popView as m.ScreenStack_.popView will trigger a chain of events
  ' that will eventually lead to onScreenStackChange() being called.
  if sendTrackingEvents = true and current <> invalid
    m.ScreenStackOldTop_ = current
  else
    m.ScreenStackOldTop_ = invalid
  end if

  m.ScreenStack_.popView = true
End Function


''''''''''''''''''''
' currentScreen
'
' Get the current top of the screen stack 
Function currentScreen()
  return m.ScreenStack_.findNode(m.ScreenStack_.currentViewId)
End Function


''''''''''''''''''''
' getHiddenScreen
'
' Get a screen at any depth in the stack. Depth of 0 is the top most screen (aka currentScreen())
Function getHiddenScreen(depth)
  screenCount = m.ScreenStack_.getChildCount()
  return m.ScreenStack_.getChild(screenCount - depth - 1)
End Function


''''''''''''''''''''
' screenTrackingNavigate
'
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

  m.global.trackingLoggingTask.trackEvent = {
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
  m.global.trackingLoggingTask.trackEvent = {
    type: "page_load"
    values: {
      pageOneof: m.Tracking.getAnalyticsPage(pageType, pageValues)  'a valid page type (see PageLoadEvent in events.protos)
      load_time: loadTime
      status: status  'ActionStatus enum
    }
  }
End Function


Function printScreenStack()
  for i=0 to m.ScreenStack_.getChildCount()-1
    screen = m.ScreenStack_.getChild(i)
    print "stack["; i; "]: "; screen.subtype(); " id = "; screen.id
  end for
End Function

Function clearScreenStack(sendTrackingEvents = true as Boolean)
  tubiLog("ScreenStack.popScreen")
  for i=m.ScreenStack_.getChildCount()-1 to 0 step -1
    screen = m.ScreenStack_.getChild(i)
    m.NodeHelpers.unobserveAllScoped(screen)
    m.ScreenStack_.removeChild(screen)
    'handle user tracking for navigating to screen
    if sendTrackingEvents = true and i > 0
      newScreen = m.ScreenStack_.getChild(i-1)
      if newScreen <> invalid
        screenTrackingNavigate(screen.trackingPageInfo, newScreen.trackingPageInfo)
        screenTrackingLoad(newScreen.trackingPageInfo)
      end if
    end if
  end for
End Function
