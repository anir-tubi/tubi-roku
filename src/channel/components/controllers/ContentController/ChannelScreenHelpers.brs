Function showChannelScreen(content, sPageSource = "")
  channelScreen = CreateObject("roSGNode", "ChannelDetailScreen")
  channelScreen.callingPage = sPageSource
  channelScreen.trackingLoadStartTime = UpTime(0)
  channelScreen.observeFieldScoped("contentSelected", "onChannelContentSelected")
  channelScreen.observeFieldScoped("backgroundUriList", "onChannelBackgroundChange")
  channelScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
  channelScreen.observeFieldScoped("refreshChannel", "onRefreshChannelSignal")
  channelScreen.id = m.constants.ui.screenIds.channelDetailScreen
  channelScreen.isLoading = true

  channelScreen.trackingPageInfo = {
    pageType: "category_page"
    pageValues: {
      category_slug: content.id
    }
  }

  displayDefaultBackground()
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
  channelTask.kidsMode = shouldKidsModeBeSentToServer()
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
    showChannelContentError(msg, true)
  end if
End Function


Function onChannelContentError(msg)
  showChannelContentError(msg, false)
End Function


Function showChannelContentError(msg, bContentEmptyError = false)
  tubiLog("ChannelScreenHelpers.onChannelContentError")
  sErrorTitle = ""
  sErrorMessage = "Could not retrieve channel content."
  if bContentEmptyError = true
    sErrorTitle = "Oops!"
    sErrorMessage = "This page currently does not have any content."
  end if 
  errorInfo = msg.getData()
  task = msg.getRoSGNode()
  screen = task.target
  topScreen = currentScreen()
  if screen <> invalid and topScreen.id = m.constants.ui.screenIds.channelDetailScreen
    ' Screen is created/pushed in showChannelScreen, since there is no content, remove it.
    ' Do not send navigation tracking info when popping the screen, as navigation tracking wasn't
    ' sent in the case of an error.
    popScreen(false)
    errorCode = getUserFacingErrorCode(m.global.constants.errors.context.channelScreen, m.constants.errors.subtypes.fetchError, errorInfo.code)

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
      title: sErrorTitle
      message: getErrorMessage(sErrorMessage, errorCode)
      openTrackEvent: dialogEvent
      trackingTask: m.trackingLoggingTask
    }

    showErrorModal(modalInfo)
  end if

  loadTime = Int((Uptime(0) - screen.trackingLoadStartTime) * 1000) 'in ms
  screenTrackingLoad(screen.trackingPageInfo, loadTime, false)

  modalInfo = {
    title: sErrorTitle
    message: getErrorMessage(sErrorMessage, errorCode)
    openTrackEvent: dialogEvent
    trackingTask: m.trackingLoggingTask
  }

  showErrorModal(modalInfo)
  loadTime = Int((Uptime(0) - screen.trackingLoadStartTime) * 1000) 'in ms
  screenTrackingLoad(screen.trackingPageInfo, loadTime, false)

  task.unobserveField("response")
  task.unobserveField("error")
End Function
