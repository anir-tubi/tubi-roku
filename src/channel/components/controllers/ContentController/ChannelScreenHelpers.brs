Function showChannelScreen(content, sPageSource = "")
  channelScreen = CreateObject("roSGNode", "ChannelDetailScreen")
  channelScreen.callingPage = sPageSource
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
  channelScreen.id = content.id

  pushScreen(channelScreen, true, false)  ' don't send page load tracking until we resolve channel content
  getChannelFromServer(channelScreen, content)
End Function


Function showMovies()
  showCacheableChannelScreen(m.constants.ui.screenIds.movieScreen)
End Function


Function showTV()
  showCacheableChannelScreen(m.constants.ui.screenIds.tvScreen)
End Function

Function showCacheableChannelScreen(sContentID)
  content = {
    id: sContentID
  }  
  categoryScreen = getFromScreenCache(content.id)
  if categoryScreen <> invalid
    pushScreen(categoryScreen, true, true)
  else
    showChannelScreen(content, "Menu")
    channelScreen = currentScreen()
    if channelScreen <> invalid and channelScreen.id = content.id
      setInScreenCache(channelScreen)
    end if
  end if
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
  bError = false

  loadedContent = task.response
  if loadedContent <> invalid and loadedContent.getChildCount() > 0
    '//get the root channnel content
    channel = loadedContent.getChild(0) '//Channel or category 
    if channel.getChildCount() <= 0
      bError = true
    end if
  else
    bError = true
  end if
  screen.content = loadedContent
  screen.shouldLoadContent = true
  task.unobserveField("response")
  task.unobserveField("error")

  if m.refreshingChannelCache <> true
    loadTime = Int((Uptime(0) - screen.trackingLoadStartTime) * 1000) 'in ms
    screenTrackingLoad(screen.trackingPageInfo, loadTime)
  else
    m.refreshingChannelCache = false
  end if

  if bError = true
    '//if no content, then display error
    onChannelContentError(msg, true)
  end if
End Function


Function onChannelContentError(msg, bContentEmptyError = false)
  tubiLog("ChannelScreenHelpers.onChannelContentError")
  sErrorTitle = ""
  sErrorMessage = "Could not retrieve channel content."
  if bContentEmptyError = true
    sErrorTitle = "Oops!"
    sErrorMessage = "This page currently does not have any content."
  end if 
  errorInfo = msg.getData()
  task = msg.getRoSGNode()
  ' Screen is created/pushed in showChannelScreen, since there is no content, remove it.
  ' Do not send navigation tracking info when popping the screen, as navigation tracking wasn't
  ' sent in the case of an error.
  popScreen(false)
  
  errorObj = createErrorObject(m.global.constants.errors.context.channelScreen, m.global.constants.errors.subtypes.fetchError, sErrorMessage, errorInfo.code, sErrorTitle)
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
