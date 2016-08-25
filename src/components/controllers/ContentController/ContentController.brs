Function init()
  tubiLog(" ")
  tubiLog("Init Scenegraph----------------")
  ' save a global reference to the fetch task for nodes to access
  m.metadataFetchTask = m.top.findNode("MetadataFetchTask")
  m.global.addField("metadataFetchTask", "node", false)
  m.global.metadataFetchTask = m.metadataFetchTask
  
  m.background = m.top.findNode("ContentBackground")
  m.background.color = m.global.constants.ui.colors.backgroundColor

  m.metadataFetchTask.observeField("ready", "onMetadataTaskReady")
  m.global.metadataFetchTask.control = "RUN"
  initScreenStack(m.top.findNode("ScreenStack"))

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
    'TODO(Chris): Check if user is logged in here, then skip sign in 
    startSignIn()
    m.metadataFetchTask.unobserveField("ready")
  end if
End Function


''''''''''''''''''''''''
' startSignIn
'
' Defer to the sign-in controller for sign in experience
Function startSignIn()
  m.SignIn = m.top.createChild("SignInController")
  m.SignIn.observeField("guestPass", "onSignInComplete")
  m.SignIn.observeField("signedIn", "onSignInComplete")
  m.SignIn.observeField("registered", "onSignInComplete")
  m.SignIn.setFocus(true)
End Function


'''''''''''''''''''''''''
' onSignInComplete
'
' The sign-in flow has ended, do what comes next
Function onSignInComplete()
  m.SignIn.unobserveField("guestPass")
  m.SignIn.unobserveField("signedIn")
  m.SignIn.unobserveField("registered")
  m.top.removeChild(m.SignIn)
  m.SignIn = invalid

  ' flush the screenstack in any case where the user has successfully
  ' gone through the sign-in.  If they 'back' out of it, the screen
  ' stack will stay intact and this function will not be called
  while currentScreen() <> invalid
    popScreen()
  end while

  m.categoryScreen = CreateObject("roSGNode", "CategoryScreen")
  m.categoryScreen.observeField("contentSelected", "onContentSelected")
  m.categoryScreen.observeField("searchSelected", "onSearchSelected")
  m.categoryScreen.observeField("signInSelected", "onSignInSelected")
  m.categoryScreen.observeField("aboutSelected", "onAboutSelected")
  pushScreen(m.categoryScreen)
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
  startSignIn()
End Function


''''''''''''''''''''
' onAboutSelected
'
' Show the about screen
Function onAboutSelected()
  tubiLog("ContentController.onAboutSelected")
  m.aboutScreen = CreateObject("roSGNode", "ModalDialogScreen")
  m.aboutScreen.title = "About Tubi TV"
  message = "(C) 2016 Tubi TV" + Chr(10) ' + Chr(13)
  message = message + "All rights reserved." + Chr(10) '+ Chr(13)
  message = message + "Tubi TV related marks are trademarks of Tubi TV, an adRise Company."
  m.aboutScreen.message = message
  m.aboutScreen.buttons = ["Close"]
  m.aboutScreen.observeField("buttonSelected", "onCloseAbout")
  pushModal(m.aboutScreen)
End Function

'''''''''''''''''''
' onCloseAbout
'
' Dismiss the About modal
Function onCloseAbout()
  popScreen()
  m.aboutScreen = invalid
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
