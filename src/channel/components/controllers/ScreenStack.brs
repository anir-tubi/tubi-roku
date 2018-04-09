''''''''''''''''''''
' initScreenStack
'
' Set the screen stack parent object. This should be an empty Group
Function initScreenStack(stack As Object, stackEmptyCallback=invalid As Object)
  tubiLog("ScreenStack.initScreenStack")
  m.ScreenStack_ = stack
  m.ScreenStackEmptyCallback_ = stackEmptyCallback
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
  top = currentScreen()
  if top <> invalid then
    top.visible = false
    top.opacity = 0.0
    top.setFocus(false)
  end if
  m.ScreenStack_.appendChild(screen) 
  screen.setFocus(true)
  screen.visible = true
  screen.opacity = 1.0
  
  'handle user tracking for navigating to screen
  if sendTrackingEvents = true and top <> invalid
    screenTrackingNavigate(top.trackingUri, screen.trackingUri)
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
  top = currentScreen()
  if top <> invalid then
    top.setFocus(false)
  end if
  m.ScreenStack_.appendChild(dialog) 
  dialog.setFocus(true)
  dialog.visible = true
  dialog.opacity = 1.0
End Function


''''''''''''''''''''
' popScreen
'
' Remove the top-most screen of the stack, making the previous screen visible
Function popScreen(sendTrackingEvents = true as Boolean)
  tubiLog("ScreenStack.popScreen")
  top = m.ScreenStack_.getChild(m.ScreenStack_.getChildCount()-1)
  unobserveAllScoped(top)
  m.ScreenStack_.removeChild(top)
  newTop = m.ScreenStack_.getChild(m.ScreenStack_.getChildCount()-1)
  if newTop <> invalid then
    ' just in case empty the whole stack
    newTop.visible = true
    newTop.opacity = 1.0
    newTop.setFocus(true)
  end if

  'handle user tracking for navigating to screen
  if sendTrackingEvents = true and top <> invalid and newTop <> invalid
    screenTrackingNavigate(top.trackingUri, newTop.trackingUri)
  end if

  'handle user tracking for loading screen
  if sendTrackingEvents = true and newTop <> invalid
    screenTrackingLoad(newTop.trackingUri)
  end if
End Function


''''''''''''''''''''
' currentScreen
'
' Get the current top of the screen stack 
Function currentScreen()
  return m.ScreenStack_.getChild(m.ScreenStack_.getChildCount()-1)
End Function


''''''''''''''''''''
' previousScreen
'
' Get the screen under the current one in the stack
Function previousScreen()
  return m.ScreenStack_.getChild(m.ScreenStack_.getChildCount()-2)
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
