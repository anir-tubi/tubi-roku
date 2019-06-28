'''''''''''''''''''''
' showChannelGridScreen
'
' @sPageSource: string, What page is calling this function? This string is what is displayed on the top of the page to let the user know what page they will go to when they click the back button
' @bChannel: boolean, Is this a grid page displaying channels? If not, it will be a grid page displaying categories
Function showChannelGridScreen(sPageSource, bChannel = true)
  gridScreen = CreateObject("roSGNode", "ChannelGridScreen")
  gridScreen.callingPage = sPageSource
  gridScreen.displayChannels = bChannel
  gridScreen.trackingLoadStartTime = UpTime(0)
  gridScreen.observeFieldScoped("contentSelected", "onGridContentSelected")
  gridScreen.observeFieldScoped("backgroundUriList", "onChannelBackgroundChange")
  gridScreen.observeFieldScoped("refreshChannel", "onRefreshGridSignal")
  gridScreen.isLoading = true

  gridScreen.trackingPageInfo = {
    pageType: "category_list_page"
    pageValues: {
    }
  }

  pushScreen(gridScreen, true, false)  ' don't send page load tracking until we resolve channel content
  getGridDataFromServer(gridScreen)
End Function


Function onGridContentSelected(msg)
  tubiLog("ChannelGridScreenHelpers.onGridContentSelected")
  gridScreen = msg.getRoSGNode()
  sType = ""
  if gridScreen.displayChannels = true
    sType = m.constants.ui.terms.channels
  else 
    sType = m.constants.ui.terms.categories
  end if
  sType = UCase(sType)
  showChannelScreen(gridScreen.contentSelected, sType)
End Function


Function onRefreshGridSignal(msg)
  gridScreen = msg.getRoSGNode()
  m.refreshingChannelGridCache = true
  gridScreen.isLoading = true
  getGridDataFromServer(gridScreen)
End Function

Function getGridDataFromServer(screen)
  tubiLog("ChannelGridScreenHelpers.getGridDataFromServer")
  if screen.hasField("task") = true and type(screen.task) = "roSGNode"
    ' If the screen already has a ChannelsCategoriesMetadataTask attached to it, cancel any potential outstanding requests
    ' so that we don't have any reference to them floating about when we tear down the task.
    ' We will tear down the task after the request is canceled in onGridContentCanceled().
    ' Since we tear down the task on recieving a response or error, we should only hit this condition if
    ' there is a request in flight.
    screen.task.cancelRequest = true
  else
    task = CreateObject("roSGNode", "ChannelsCategoriesMetadataTask")
    task.displayChannels = screen.displayChannels
    screen.addField("task", "node", false)
    screen.task = task
    task.addField("target", "node", false)
    task.target = screen
    task.observeFieldScoped("response", "onGridContentResponse")
    task.observeFieldScoped("error", "onGridContentError")
    task.observeFieldScoped("canceled", "onGridContentCanceled")
    task.control = "RUN"
  end if
End Function


Function onGridContentResponse(msg)
  tubiLog("ChannelGridScreenHelpers.onGridContentResponse")
  task = msg.getRoSGNode()
  screen = task.target
  screen.isLoading = false
  screen.content = task.response
  screen.shouldLoadContent = true
  tearDownChannelGridTask(task)

  if m.refreshingChannelGridCache <> true
    loadTime = Int((Uptime(0) - screen.trackingLoadStartTime) * 1000) 'in ms
    screenTrackingLoad(screen.trackingPageInfo, loadTime)
  end if
End Function


Function onGridContentError(msg)
  tubiLog("ChannelGridScreenHelpers.onGridContentError")
  errorInfo = msg.getData()
  task = msg.getRoSGNode()
  ' Screen is created/pushed in showChannelScreen, since there is no content, remove it.
  ' Do not send navigation tracking info when popping the screen, as navigation tracking wasn't
  ' sent in the case of an error.
  popScreen(false)
  screen = tearDownChannelGridTask(task)
  
  sErrorType = m.constants.errors.context.categoriesScreen
  sErrorContent = LCase(m.global.constants.ui.terms.categories)
  if screen.displayChannels = true
    sErrorType = m.constants.errors.context.channelsScreen
    sErrorContent = LCase(m.global.constants.ui.terms.channels)
  end if


  errorObj = createErrorObject(sErrorType, m.constants.errors.subtypes.fetchError, "Could not retrieve " + sErrorContent + " content.", errorInfo.code)
  showErrorModal(errorObj)
  loadTime = Int((Uptime(0) - screen.trackingLoadStartTime) * 1000) 'in ms
  screenTrackingLoad(screen.trackingPageInfo, loadTime, false)

  m.trackingLoggingTask.trackEvent = {
    type: "dialog"
    values: {
      dialog_type: "WARNING" 'DialogType enum
      pageOneof: m.Tracking.getAnalyticsPage(screen.trackingPageInfo.pageType, screen.trackingPageInfo.pageValues)
    }
  }
End Function


' Callback once the canceled request has been sucessfully canceled
' Tear down the task, and re-run getGridDataFromServer
Function onGridContentCanceled(msg)
  tubiLog("ChannelGridScreenHelpers.onGridContentCanceled")
  task = msg.getRoSGNode()
  screen = tearDownChannelGridTask(task)
  if screen <> invalid
    getGridDataFromServer(screen)
  end if
End Function


' @task: roSGNode, a ChannelsCategoriesMetadataTask
' returns the screen that was attached to the task as a target (presumably the ChannelGridScreen)
Function tearDownChannelGridTask(task)
  if task <> invalid
    task.unobserveFieldScoped("response")
    task.unobserveFieldScoped("error")
    task.unobserveFieldScoped("canceled")
    screen = task.target
    if screen <> invalid
      screen.task = invalid
      task.target = invalid
      return screen
    end if
  end if
  return invalid
End Function