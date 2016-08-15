Function init()
  ' save a global reference to the fetch task for nodes to access
  m.metadataFetchTask = m.top.findNode("MetadataFetchTask")
  m.global.addField("metadataFetchTask", "node", false)
  m.global.metadataFetchTask = m.metadataFetchTask

  m.metadataFetchTask.observeField("ready", "onMetadataTaskReady")
  m.global.metadataFetchTask.control = "RUN"

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
    m.categoryScreen = m.top.createChild("CategoryScreen")
    m.categoryScreen.observeField("contentSelected", "onContentSelected")
    m.categoryScreen.setFocus(true)

    ' only do this once
    m.metadataFetchTask.unobserveField("ready")
  end if
End Function


'''''''''''''''''''''''
' onContentSelected
'
' Hide the content screen and show the details
Function onContentSelected()
  m.categoryScreen.visible = false


  'TODO(Chris): Maybe create this up front? We also don't want to 
  ' display old info when made visible
  if m.categoryScreen.contentSelected <> invalid then
    m.detailScreen = m.top.createChild("DetailScreen")
    m.detailScreen.shortContent = m.categoryScreen.contentSelected
    m.detailScreen.observeField("playContent", "onPlay")
    m.detailScreen.observeField("resumeContent", "onResume")
    m.detailScreen.setFocus(true)
  end if

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
    if key = "back" and m.detailScreen <> invalid then
      m.detailScreen.unobserveField("playContent")
      m.detailScreen.unobserveField("resumeContent")
      m.top.removeChild(m.detailScreen)
      m.detailScreen = invalid
      m.categoryScreen.visible = true
      m.categoryScreen.setFocus(true)
      return true
    end if
  end if
  return false
End Function
