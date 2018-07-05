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
      screenTrackingNavigate(m.ScreenStackOldTop_.trackingUri, current.trackingUri)
      screenTrackingLoad(current.trackingUri)
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
Function pushScreen(screen As Object, sendTrackingEvents = true as Boolean)
  tubiLog("ScreenStack.pushScreen")
  current = currentScreen()
  m.ScreenStack_.pushView = screen
  
  'handle user tracking for navigating to screen
  if sendTrackingEvents = true and current <> invalid
    screenTrackingNavigate(current.trackingUri, screen.trackingUri)
  end if
  
  'handle user tracking for loading screen
  if sendTrackingEvents = true
    screenTrackingLoad(screen.trackingUri)
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
  m.ScreenStack_.popView = true

  'handle user tracking for navigating to screen
  if sendTrackingEvents = true and current <> invalid
    m.ScreenStackOldTop_ = current
  else
    m.ScreenStackOldTop_ = invalid
  end if
End Function


''''''''''''''''''''
' currentScreen
'
' Get the current top of the screen stack 
Function currentScreen()
  return m.ScreenStack_.findNode(m.ScreenStack_.currentViewId)
End Function


''''''''''''''''''''
' screenTrackingNavigate
'
' 'tracking for navigating to a screen
Function screenTrackingNavigate(oldTrackingUri, newTrackingUri)
  sourceUri = ""
  if oldTrackingUri <> invalid
    sourceUri = oldTrackingUri
  end if

  destinationUri = invalid
  if newTrackingUri <> invalid
    destinationUri = newTrackingUri
  end if

  if destinationUri <> invalid 
    m.global.trackingLoggingTask.trackEvent = {
      trackType: "navigate"
      value: destinationUri
      ctx: sourceUri
    }
  end if
End Function


''''''''''''''''''''
' screenTrackingLoad
'
' tracking for loading a new screen
Function screenTrackingLoad(newTrackingUri)
  destinationUri = invalid
  if newtrackingUri <> invalid
    destinationUri = newTrackingUri
  end if

  'tracking for loading screen
  if destinationUri <> invalid
    m.global.trackingLoggingTask.trackEvent = {
      trackType: "pageLoad"
      value: destinationUri
    }
  end if
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
        screenTrackingNavigate(screen.trackingUri, newScreen.trackingUri)
        screenTrackingLoad(newScreen.trackingUri)
      end if
    end if
  end for
End Function
