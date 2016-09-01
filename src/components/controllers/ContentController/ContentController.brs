Function init()
  tubiLog(" ")
  tubiLog("Init Scenegraph----------------")
  ' save a global reference to the fetch task for nodes to access
  m.metadataFetchTask = m.top.findNode("MetadataFetchTask")
  m.global.addField("metadataFetchTask", "node", false)
  m.global.metadataFetchTask = m.metadataFetchTask
  
  m.background = m.top.findNode("ContentBackground")
  m.background.color = m.global.constants.ui.colors.backgroundColor

  m.global.addField("bookmarkIds", "assocarray", false)
  m.global.addField("historyIds", "assocarray", false)
  m.global.addField("bookmarkOrder", "stringarray", false)
  m.global.addField("historyOrder", "stringarray", false)
  m.global.bookmarkIds = invalid 'these are set in handleInitialBookmarks(), once a user has logged in
  m.global.historyIds = invalid  'these are set in handleInitialHistory(), once a user has logged in
  m.global.bookmarkOrder = invalid  'this are set in handleInitialBookmarks(), once a user has logged in
  m.global.historyOrder = invalid  'this are set in handleInitialHistory(), once a user has logged in

  m.metadataFetchTask.observeField("ready", "onMetadataTaskReady")
  m.global.metadataFetchTask.control = "RUN"

  m.authTask = m.top.findNode("AuthTask")
  m.authTask.observeField("authInfo", "onAuthInfoReceived")
  m.authInfoReceived = false
  m.authTask.control = "RUN"

  m.top.observeField("itemDetail", "onItemDetailChange")

  m.logOutTask = m.top.findNode("LogOutTask")

  initScreenStack(m.top.findNode("ScreenStack"))
End Function


'''''''''''''''''''''''''
' startUserExperience
'
' Only once we have a metadata task ready AND the user's login status
' will we launch the UI
Function startUserExperience()
  tubiLog("ContentController.startUserExperience")
  if m.metadataFetchTask.ready and m.authInfoReceived then
    if m.top.itemDetail <> invalid then
      tubiLog("ContentController detected deep link request")
      ' we were asked to deep link into a content item. Go to it
      ' whether we were logged in or not.  Make sure the category
      ' screen is loaded too
      startCategoryScreen()
      onItemDetailChange()
      'TODO(Chris): capture the 'back' button when the screen stack is empty so
      ' that we can show the category screen without haveing to preload it here
    else if m.authTask.authInfo = invalid then
      startSignIn()
    else
      startCategoryScreen()
      m.categoryScreen.signedIn = true
    end if
  end if
End Function


'''''''''''''''''''''''
' startCategoryScreen
'
' On either app start (if user is signed in) or after the sign in
' flow is complete, create and show the category screen.
Function startCategoryScreen()
  m.categoryScreen = CreateObject("roSGNode", "CategoryScreen")
  m.categoryScreen.observeField("contentSelected", "onContentSelected")
  m.categoryScreen.observeField("searchSelected", "onSearchSelected")
  m.categoryScreen.observeField("signInSelected", "onSignInSelected")
  m.categoryScreen.observeField("signOutSelected", "onSignOutSelected")
  m.categoryScreen.observeField("aboutSelected", "onAboutSelected")
  pushScreen(m.categoryScreen)
End Function


'''''''''''''''''''''''
' onAuthInfoReceived
'
'
Function onAuthInfoReceived()
  tubiLog("ContentController.onAuthInfoReceived")
  m.authInfoReceived = true
  startUserExperience()
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
    m.metadataFetchTask.unobserveField("ready")
    startUserExperience()
  end if
End Function


''''''''''''''''''''''''
' startSignIn
'
' Defer to the sign-in controller for sign in experience
Function startSignIn()
  tubiLog("ContentController.startSignIn")
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
  tubiLog("ContentController.onSignInComplete")

  ' flush the screenstack in any case where the user has successfully
  ' gone through the sign-in.  If they 'back' out of it, the screen
  ' stack will stay intact and this function will not be called
  while currentScreen() <> invalid
    popScreen()
  end while

  startCategoryScreen()
  if m.SignIn.signedIn or m.SignIn.registered then
    m.categoryScreen.signedIn = true
  end if

  m.SignIn.unobserveField("guestPass")
  m.SignIn.unobserveField("signedIn")
  m.SignIn.unobserveField("registered")
  m.top.removeChild(m.SignIn)
  m.SignIn = invalid
End Function


'''''''''''''''''''''''
' onContentSelected
'
' Show the detail screen for the selected content
Function onContentSelected()
  tubiLog("ContentController.onContentSelected")
  top = currentScreen()
  
  if top <> invalid and top.contentSelected <> invalid then
    showDetailScreen(top.contentSelected)
  end if
End Function


''''''''''''''''''''
' onHistoryQueueChange
'
'
Function onHistoryQueueChange()
  if m.categoryScreen <> invalid then m.categoryScreen.dirtyUserCategories = true
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
' onSignOutSelected
'
' Log the user out, update screens
Function onSignOutSelected()
  tubiLog("ContentController.onSignOutSelected")
  if m.categoryScreen <> invalid then
    m.categoryScreen.signedIn = false
  end if
  if m.detailScreen <> invalid then
    m.detailScreen.signedIn = false
  end if
  m.AuthTask.functionName = "execSignOut"
  m.AuthTask.control = "RUN"
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
  tubiLog("ContentController.onCloseAbout")
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


'''''''''''''''''''''
' onItemDetailChange
'
' Show the detail screen for the content id
Function onItemDetailChange()
  tubiLog("onItemDetailChange")
  if m.metadataFetchTask.ready and m.authInfoReceived and m.top.itemDetail <> invalid then
    'TODO(Chris): Supplement this content with history & queue status once we have it
    testLog("Deep link contentId = " + m.top.itemDetail.id)
    testLog("Deep link type = " + m.top.itemDetail.type)
    showDetailScreen(m.top.itemDetail)
  end if
End Function


'''''''''''
' handleInitialBookmarks
'
' Use the metadataFetchTask to populate the content for the user's "My Queue" category
Function handleInitialBookmarks()
  if m.authTask.initialBookmarks <> invalid
    initialBookmarks = m.authTask.initialBookmarks
    
    'parse the initial bookmark response and create a list of bookmark server ids that will persist in the content controller
    parsedInitialBookmarks = ParseJson(initialBookmarks)

    bookmarkOrder = []

    bookmarkIds = {
      'each videos and series assocArray should look like:
      '{contentId: bookmarkServerId, ...}
      videos: {}
      series: {}
    }

    for each bookmark in parsedInitialBookmarks.items
      if bookmark.contentType = m.global.constants.uapiContentTypes.movie
        bookmarkIds.videos[bookmark.content_id.toStr()] = bookmark.id

        bookmarkOrder.push({
          cid: history.content_id.toStr()
          "type": m.global.constants.uapiContentTypes.movie
        })

      else if bookmark.contentType = m.global.constants.uapiContentTypes.series
        bookmarkIds.series[bookmark.content_id.toStr()] = bookmark.id

        bookmarkOrder.push({
          cid: history.content_id.toStr()
          "type": m.global.constants.uapiContentTypes.series
        })
      end if
    end for

    m.global.bookmarkIds = bookmarkIds
    m.global.bookmarkOrder = bookmarkOrder

  end if
End Function


'''''''''''''''''''''
' showDetailScreen
'
'
Function showDetailScreen(content)
  m.detailScreen = CreateObject("roSGNode", "DetailScreen")
  m.detailScreen.shortContent = content
  m.detailScreen.observeField("playContent", "onPlay")
  m.detailScreen.observeField("resumeContent", "onResume")
  m.detailScreen.observeField("signInSelected", "onSignInSelected")
  m.detailScreen.observeField("addToQueueSelected", "onHistoryQueueChange")
  m.detailScreen.observeField("removeFromQueueSelected", "onHistoryQueueChange")
  m.detailScreen.observeField("removeFromHistorySelected", "onHistoryQueueChange")
  m.detailScreen.signedIn = m.categoryScreen.signedIn
  pushScreen(m.detailScreen)
End Function


'''''''''''
' handleInitialHistory
'
' Use the metadataFetchTask to populate the content for the user's "My Queue" category
Function handleInitialHistory()
  if m.authTask.initialHistory <> invalid

    initialHistory = m.authTask.initialHistory
    
    'parse the initial bookmark response and create a list of bookmark server ids that will persist in the content controller
    parsedInitialHistory = ParseJson(initialHistory)

    historyOrder = []

    historyIds = {
      'each videos and series assocArray should look like:
      '{contentId: {
      '   serverId: historyServerId
      '   position: 365
      '  }
      '}
      videos: {}
      series: {}
    }

    for each history in parsedInitialHistory.items
      if history.contentType = m.global.constants.uapiContentTypes.movie
        historyIds.videos[history.content_id.toStr()] = {
          serverId: history.id
          position: history.position
        }

        historyOrder.push({
          cid: history.content_id.toStr()
          "type": m.global.constants.uapiContentTypes.movie
        })

      else if history.contentType = m.global.constants.uapiContentTypes.series
        historyIds.series[history.content_id.toStr()] = {
          serverId: history.id
          position: history.position          
        }

        for each episode in history.episodes
          historyIds.videos[episode.content_id.toStr()] = {
            serverId: episode.id
            position: episode.position
          }
        end for

        historyOrder.push({
          cid: history.content_id.toStr()
          "type": m.global.constants.uapiContentTypes.series
        })

      end if
    end for

    m.global.historyIds = historyIds
    m.global.historyOrder = historyOrder

  end if
End Function
