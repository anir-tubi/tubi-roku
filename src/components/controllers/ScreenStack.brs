''''''''''''''''''''
' initScreenStack
'
' Set the screen stack parent object. This should be an empty Group
Function initScreenStack(stack As Object)
  tubiLog("ScreenStack.initScreenStack")
  m.ScreenStack_ = stack
End Function


'''''''''''''''''''''''
' onKeyEvent
'
' Back pressed on detail screen should close it
Function onKeyEvent(key As String, press As Boolean)
  tubiLog("ScreenStack.onKeyEvent")
  if press then
    if key = "back" 
      if m.ScreenStack_.getChildCount() > 1 then popScreen()
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
End Function

''''''''''''''''''''
' currentScreen
'
' Get the current top of the screen stack 
Function currentScreen()
  return m.ScreenStack_.getChild(m.ScreenStack_.getChildCount()-1)
End Function