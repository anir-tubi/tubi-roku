Function showChannelScreen(content)
  channelScreen = CreateObject("roSGNode", "ChannelDetailScreen")
  channelScreen.trackingLoadStartTime = UpTime(0)
  channelScreen.observeFieldScoped("contentSelected", "onChannelContentSelected")
  channelScreen.observeFieldScoped("backgroundUriList", "onChannelBackgroundChange")
  channelScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
  channelScreen.observeFieldScoped("refreshChannel", "onRefreshChannelSignal")
  channelScreen.isLoading = true

  channelScreen.trackingPageInfo = {
    pageType: "category_page"
    pageValues: {
      category_slug: content.id
    }
  }

  pushScreen(channelScreen, true, false)  ' don't send page load tracking until we resolve channel content
  getChannelFromServer(channelScreen, content)
End Function


Function onChannelContentSelected(msg)
  tubiLog("ChannelScreenHelpers.onChannelContentSelected")
  channelScreen = msg.getRoSGNode()
  showDetailScreen(channelScreen.contentSelected)
End Function


Function onRefreshChannelSignal(msg)
  channelScreen = msg.getRoSGNode()
  if channelScreen <> invalid and channelScreen.content <> invalid
    channelRow = channelScreen.content.getChild(0)
  end if
  m.refreshingChannelCache = true
  channelScreen.isLoading = true
  getChannelFromServer(channelScreen, channelRow)
End Function

Function getChannelFromServer(screen, content)
  tubiLog("ChannelScreenHelpers.getChannelFromServer")
  channelTask = CreateObject("roSGNode", "ChannelMetadataTask")
  channelTask.channelId = content.id
  screen.addField("task", "node", false)
  screen.task = channelTask
  channelTask.addField("target", "node", false)
  channelTask.target = screen
  channelTask.observeField("response", "onChannelContentResponse")
  channelTask.observeField("error", "onChannelContentError")
  channelTask.control = "RUN"
End Function


Function onChannelContentResponse(msg)
  tubiLog("ChannelScreenHelpers.onChannelContentResponse")
  task = msg.getRoSGNode()
  screen = task.target
  screen.isLoading = false

  screen.content = task.response
  task.unobserveField("response")
  task.unobserveField("error")

  if m.refreshingChannelCache <> true
    loadTime = Int((Uptime(0) - screen.trackingLoadStartTime) * 1000) 'in ms
    screenTrackingLoad(screen.trackingPageInfo, loadTime)
  else
    m.refreshingChannelCache = false
  end if
End Function


Function onChannelContentError(msg)
  tubiLog("ChannelScreenHelpers.onChannelContentError")
  errorInfo = msg.getData()
  task = msg.getRoSGNode()
  ' Screen is created/pushed in showChannelScreen, since there is no content, remove it.
  ' Do not send navigation tracking info when popping the screen, as navigation tracking wasn't
  ' sent in the case of an error.
  popScreen(false)
  
  errorObj = createErrorObject(m.global.constants.errors.context.channelScreen, m.global.constants.errors.subtypes.fetchError, "Could not retrieve channel content.", errorInfo.code)
  showErrorModal(errorObj)
  screen = task.target
  loadTime = Int((Uptime(0) - screen.trackingLoadStartTime) * 1000) 'in ms
  screenTrackingLoad(screen.trackingPageInfo, loadTime, false)

  m.trackingLoggingTask.trackEvent = {
    type: "dialog"
    values: {
      dialog_type: "WARNING" 'DialogType enum
      pageOneof: m.Tracking.getAnalyticsPage(screen.trackingPageInfo.pageType, screen.trackingPageInfo.pageValues)
    }
  }

  task.unobserveField("response")
  task.unobserveField("error")
End Function
