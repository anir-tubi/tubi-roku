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
  tubiLog("ScreenStack.onKeyEvent")
  if press then
    if key = "back" 
      if m.ScreenStack_.getChildCount() > 1 then 
        popScreen()
      else if m.ScreenStackEmptyCallback_ <> invalid and type(m.ScreenStackEmptyCallback_) = "roFunction" then
       ' only remove the last item if we have a valid callback
        popScreen()
        m.ScreenStackEmptyCallback_()
      end if
      return true  ' unhandled back button will exit the app. prevent that by returning true
    end if
  end if
  return false
End Function


''''''''''''''''''''''
' pushScreen
'
' Push a screen on to the stack, allowing the back button to retrace steps
Function pushScreen(screen As Object)
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
  if top <> invalid
    screenTrackingNavigate(top, screen)
  end if
  
  'handle user tracking for loading screen
  screenTrackingLoad(screen)

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
Function popScreen()
  tubiLog("ScreenStack.popScreen")
  top = m.ScreenStack_.getChild(m.ScreenStack_.getChildCount()-1)
  fields = top.getFields()
  for each f in fields
    ' make sure the controller completely dereferences the screen
    top.unobserveField(f)
  end for
  m.ScreenStack_.removeChild(top)
  newTop = m.ScreenStack_.getChild(m.ScreenStack_.getChildCount()-1)
  if newTop <> invalid then
    ' just in case empty the whole stack
    newTop.visible = true
    newTop.opacity = 1.0
    newTop.setFocus(true)
  end if

  'handle user tracking for navigating to screen
  if top <> invalid and newTop <> invalid
    screenTrackingNavigate(top, newTop)
  end if

  'handle user tracking for loading screen
  if newTop <> invalid
    screenTrackingLoad(newTop)
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
' screenTrackingNavigate
'
' Get the current top of the screen stack 
Function screenTrackingNavigate(oldScreen, newScreen)
  'tracking for navigating to a screen
  sourceUri = ""
  if oldScreen.trackingUri <> invalid
    sourceUri = oldScreen.trackingUri
  end if

  destinationUri = invalid
  if newScreen.trackingUri <> invalid
    destinationUri = newScreen.trackingUri
  end if

  if destinationUri <> invalid 
    m.global.TrackingTask.trackEvent = {
      trackType: "navigate"
      value: destinationUri
      ctx: sourceUri
    }
  end if
End Function


''''''''''''''''''''
' screenTrackingLoad
'
' Get the current top of the screen stack 
Function screenTrackingLoad(newScreen)
  destinationUri = invalid
  if newScreen.trackingUri <> invalid
    destinationUri = newScreen.trackingUri
  end if

  'tracking for loading screen
  if destinationUri <> invalid
    m.global.TrackingTask.trackEvent = {
      trackType: "pageLoad"
      value: destinationUri
    }
  end if
End Function