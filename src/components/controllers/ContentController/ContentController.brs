Function init()
  tubiLog(" ")
  tubiLog("Init Scenegraph----------------")
  ' save a global reference to the fetch task for nodes to access
  m.metadataFetchTask = m.top.findNode("MetadataFetchTask")
  m.global.addField("metadataFetchTask", "node", false)
  m.global.metadataFetchTask = m.metadataFetchTask

  m.metadataFetchTask.observeField("ready", "onMetadataTaskReady")
  m.global.metadataFetchTask.control = "RUN"
  m.ScreenStack = m.top.findNode("ScreenStack")

End Function


'''''''''''''''''''''''
' onMetadataTaskReady
'
' Load the categories once the metadata task thread is ready.  This
' may be much after the task state is change to "RUN".  The task itself
' takes a moment to initialize and get its observer ready to handle
' incoming metadata requests.
Function onMetadataTaskReady()
  tubiLog("ContentController.onMetadataTaskReady")

  if m.metadataFetchTask.ready = true then
    ' Create the cateogry screen only after the task thread is ready
    m.categoryScreen = CreateObject("roSGNode", "CategoryScreen")
    m.categoryScreen.observeField("contentSelected", "onContentSelected")
    m.categoryScreen.observeField("searchSelected", "onSearchSelected")
    m.categoryScreen.observeField("signInSelected", "onSignInSelected")
    m.categoryScreen.observeField("aboutSelected", "onAboutSelected")
    pushScreen(m.categoryScreen)

    ' only do this once
    m.metadataFetchTask.unobserveField("ready")
  end if
End Function


'''''''''''''''''''''''
' onContentSelected
'
' Show the detail screen for the selected content
Function onContentSelected()
  top = currentScreen()
  
  if top <> invalid and top.contentSelected <> invalid then
    m.detailScreen = CreateObject("roSGNode", "DetailScreen")
    m.detailScreen.shortContent = top.contentSelected
    m.detailScreen.observeField("playContent", "onPlay")
    m.detailScreen.observeField("resumeContent", "onResume")
    pushScreen(m.detailScreen)
  end if
End Function


''''''''''''''''''''
' onSearchSelected
'
' Show the search screen
Function onSearchSelected()
  tubiLog("ContentController.onSearchSelected")
  m.searchScreen = CreateObject("roSGNode", "SearchScreen")
  m.searchScreen.observeField("contentSelected", "onContentSelected")
  pushScreen(m.searchScreen)
End Function


''''''''''''''''''''
' onSignInSelected
'
' Launch the Sign In experience
Function onSignInSelected()
  tubiLog("ContentController.onSignInSelected")
End Function


''''''''''''''''''''
' onAboutSelected
'
' Show the about screen
Function onAboutSelected()
  tubiLog("ContentController.onAboutSelected")
End Function


'''''''''''
' onPlay
'
' Notify the main Brightscript thread to invoke the video player
Function onPlay()
  tubiLog("ContentController.onPlay")
  content = m.detailScreen.content
  content.playstart = 0.0 'reset the start position
  'TODO(Chris): For unauthenticated users, we need to reset any resume 
  ' position that might have been set.  Also, when we come back from
  ' playback, we want to redraw the detail screen to reflect the new
  ' resume position.
  m.top.playContent = content
End Function


'''''''''''
' onResume
'
' Notify the main Brightscript thread to invoke the video player, resuming at the indicated location
Function onResume()
  tubiLog("ContentController.onResume")
  content = m.detailScreen.resumeContent
  m.top.playContent = content
End Function

'''''''''''''''''''''''
' onKeyEvent
'
' Back pressed on detail screen should close it
Function onKeyEvent(key As String, press As Boolean)
  if press then
    if key = "back" and m.ScreenStack.getChildCount() > 1 then
      popScreen()
      return true
    end if
  end if
  return false
End Function


''''''''''''''''''''''
' pushScreen
'
' Push a screen on to the stack, allowing the back button to retrace steps
Function pushScreen(screen As Object)
  top = m.ScreenStack.getChild(m.ScreenStack.getChildCount()-1)
  if top <> invalid then
    top.visible = false
    top.opacity = 0.0
    top.setFocus(false)
  end if
  m.ScreenStack.appendChild(screen) 
  screen.setFocus(true)
  screen.visible = true
  screen.opacity = 1.0
End Function


''''''''''''''''''''
' popScreen
'
' Remove the top-most screen of the stack, making the previous screen visible
Function popScreen()
  top = m.ScreenStack.getChild(m.ScreenStack.getChildCount()-1)
  fields = top.getFields()
  for each f in fields
    ' make sure the controller completely dereferences the screen
    top.unobserveField(f)
  end for
  m.ScreenStack.removeChild(top)
  newTop = m.ScreenStack.getChild(m.ScreenStack.getChildCount()-1)
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
  return m.ScreenStack.getChild(m.ScreenStack.getChildCount()-1)
End Function
