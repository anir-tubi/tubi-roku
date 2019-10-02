' gets the ChannelListScreen from the screen cache if it exists, otherwise wraps showChannelGridScreen()
' @constants: assocArray, constants as set in Constants.brs and updated in the hotpatch
' @sPageSource: string, What page is calling this function? This string is what is displayed on the top of the page
'                       to let the user know what page they will go to when they click the back button
Function showChannelListScreen(constants, sPageSource)
  channelListScreen = getFromScreenCache(m.constants.ui.screenIds.channelListScreen)
  if channelListScreen <> invalid
    pushScreen(channelListScreen, true, true)
  else
    showChannelGridScreen(constants, sPageSource, true, m.constants.ui.screenLevels.channelCategoryGridScreen)
  end if
End Function


' gets the CategoryListScreen from the screen cache if it exists, otherwise wraps showChannelGridScreen()
' @constants: assocArray, constants as set in Constants.brs and updated in the hotpatch
' @sPageSource: string, What page is calling this function? This string is what is displayed on the top of the page
'                       to let the user know what page they will go to when they click the back button
Function showCategoryListScreen(constants, sPageSource)
  categoryListScreen = getFromScreenCache(m.constants.ui.screenIds.categoryListScreen)
  if categoryListScreen <> invalid
    pushScreen(categoryListScreen, true, true)
  else
    showChannelGridScreen(constants, sPageSource, false, m.constants.ui.screenLevels.channelCategoryGridScreen)
  end if
End Function


'''''''''''''''''''''
' showChannelGridScreen
'
' @onstants: assocArray, constants as set in Constants.brs and updated in the hotpatch
' @sPageSource: string, What page is calling this function? This string is what is displayed on the top of the page to let the user know what page they will go to when they click the back button
' @bChannel: boolean, Is this a grid page displaying channels? If not, it will be a grid page displaying categories
' @screenLevel: integer, Should this screen have a different screenlevel other than its default one?
Function showChannelGridScreen(constants, sPageSource, bChannel = true, screenLevel = -1)
  gridScreen = CreateObject("roSGNode", "ChannelGridScreen")

  gridScreenId = constants.ui.screenIds.channelListScreen
  pageType = "channel_list_page"
  if bChannel = false
    gridScreenId = constants.ui.screenIds.categoryListScreen
    pageType = "category_list_page"
  end if

  if screenLevel > 0
    gridScreen.screenLevel = screenLevel
  end if
  gridScreen.id = gridScreenId
  gridScreen.callingPage = sPageSource
  gridScreen.displayChannels = bChannel
  gridScreen.trackingLoadStartTime = UpTime(0)
  gridScreen.observeFieldScoped("contentSelected", "onGridContentSelected")
  gridScreen.observeFieldScoped("backgroundUriList", "onChannelBackgroundChange")
  gridScreen.observeFieldScoped("refreshChannel", "onRefreshGridSignal")
  gridScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
  gridScreen.isLoading = true

  gridScreen.trackingPageInfo = {
    pageType: pageType
    pageValues: {}
  }

  setInScreenCache(gridScreen)
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


Function refreshGridScreen(gridScreen)
  m.refreshingChannelGridCache = true
  gridScreen.isLoading = true
  getGridDataFromServer(gridScreen)
End Function


Function onRefreshGridSignal(msg)
  gridScreen = msg.getRoSGNode()
  refreshGridScreen(gridScreen)
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
    task.kidsMode = shouldKidsModeBeSentToServer()
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
  screen = tearDownChannelGridTask(task)
  
  if screen <> invalid and (screen.id = m.constants.ui.screenIds.channelListScreen or screen.id = m.constants.ui.screenIds.categoryListScreen)
    popScreen(false)

    'delete the screen from the screen cache so that the next time the user attempts to load the page, the page will be loaded
    'from scratch again. Otherwise an empty page will load and content will never be fetched.
    deleteFromScreenCache(screen.id)

    sErrorType = m.constants.errors.context.categoriesScreen
    sErrorContent = LCase(m.global.constants.ui.terms.categories)
    if screen.displayChannels = true
      sErrorType = m.constants.errors.context.channelsScreen
      sErrorContent = LCase(m.global.constants.ui.terms.channels)
    end if

    errorCode = getUserFacingErrorCode(sErrorType, m.constants.errors.subtypes.fetchError, errorInfo.code)
    prelimMessage = "Could not retrieve " + sErrorContent + " content."

    dialogEvent = {
      type: "dialog"
      values: {
        dialog_type: "NETWORK_ERROR" 'DialogType enum
        pageOneof: m.Tracking.getAnalyticsPage(screen.trackingPageInfo.pageType, screen.trackingPageInfo.pageValues)
        dialog_action: "SHOW"
        dialog_sub_type: errorCode
      }
    }

    modalInfo = {
      message: getErrorMessage(prelimMessage, errorCode)
      openTrackEvent: dialogEvent
      trackingTask: m.trackingLoggingTask
    }
    showErrorModal(modalInfo)
    loadTime = Int((Uptime(0) - screen.trackingLoadStartTime) * 1000) 'in ms
    screenTrackingLoad(screen.trackingPageInfo, loadTime, false)
  end if
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
