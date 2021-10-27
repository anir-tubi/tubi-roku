Function showChannelScreen(content, sPageSource = "")
  channelScreen = CreateObject("roSGNode", "ChannelDetailScreen")
  channelScreen.callingPage = sPageSource
  channelScreen.trackingLoadStartTime = UpTime(0)
  channelScreen.observeFieldScoped("contentSelected", "onChannelContentSelected")
  channelScreen.observeFieldScoped("backgroundUriList", "onChannelBackgroundChange")
  channelScreen.observeFieldScoped("sponsorshipBackground", "onSponsorshipBackgroundChanged")
  channelScreen.observeFieldScoped("focusedChild", "onChannelScreenFocusChanged")
  channelScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
  channelScreen.observeFieldScoped("refreshChannel", "onRefreshChannelSignal")
  channelScreen.observeFieldScoped("signInRequired", "onSignInRequiredModal")
  channelScreen.observeFieldScoped("backButtonPressed", "onChannelScreenBackPressed")
  channelScreen.observeFieldScoped("transportVoiceResponse", "onTransportVoiceResponse")
  channelScreen.observeFieldScoped("contentToPlay", "onContentToPlay")
  channelScreen.id = m.constants.ui.screenIds.channelDetailScreen
  channelScreen.categoryId = content.id
  channelScreen.isLoading = true
  
  channelScreen.trackingPageInfo = {
    pageType: "category_page"
    pageValues: {
      category_slug: content.id
    }
  }

  displayDefaultBackground()
  pushScreen(channelScreen, true, false) ' don't send page load tracking until we resolve channel content
  
  authInfo = m.global.authInfo
  ' make queue API request only if the user loggedIn
  if authInfo = invalid and content.id = m.constants.ui.categoryIds.queue
    displaySignInRequiredModal(channelScreen)
  else
    getChannelFromServer(channelScreen, content)
  end if
  
End Function


Function onSignInRequiredModal(msg)

  tubiLog("ChannelScreenHelpers.onSignInRequiredModal")
  screen = msg.getRoSGNode()
  
  if screen <> invalid and screen.content = invalid
    displaySignInRequiredModal(screen)
  end if

End Function


Function displaySignInRequiredModal(screen)

  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: "SIGNIN_REQUIRED" 'DialogType enum
      pageOneof: m.Tracking.getAnalyticsPage(screen.trackingPageInfo.pageType, screen.trackingPageInfo.pageValues)
      dialog_action: "SHOW"
      dialog_sub_type: "sign-in-mylist"
    }
  }
  title = getTranslation("dialog_whoops_title")
  message = getTranslation("dialog_mylist_signIn_description")
  buttons = [getTranslation("dialog_button_register_signIn"), getTranslation("dialog_button_cancel")]
  showSimpleInstantResumableModal(title, message, buttons, dialogEvent, m.trackingLoggingTask, onSignInModalSelectedViaSideNavMyList, removeTopScreen)

End Function


Function onChannelScreenFocusChanged(msg)
  channelScreen = msg.getRoSGNode()
  if channelScreen.isInFocusChain() = true

    '//If the channel Screen regains focus, then ensure the sponsored background is correct. Important when the BACK button is used and the channelScreen has sponsored content.
    setSponsorshipBackground(channelScreen.sponsorshipBackground)
  end if
End Function


Function onChannelContentSelected(msg)
  tubiLog("ChannelScreenHelpers.onChannelContentSelected")
  channelScreen = msg.getRoSGNode()

  '//Keep track of the sponsored exposure ID if the selected video is within a sponsored container
  channel = channelScreen.content.getChild(0)
  if channel <> invalid and channel.sponsorExp <> invalid
    m.videoSponsorExposureId = channel.sponsorExp
  end if

  showDetailScreen(channelScreen.contentSelected, true)
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
  contentId = content.id
  ' TODO: FIND A BETTER WAY TO SOLVE THE u_continue_watching issue
  if content.id = "u_continue_watching"
    contentId = "continue_watching"
  end if
  channelTask.channelId = contentId
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
  bEmptyResponse = false

  loadedContent = task.response
  if loadedContent <> invalid and loadedContent.getChildCount() > 0
    '//get the root channnel content
    channel = loadedContent.getChild(0) '//Channel or category
    if channel = invalid or channel.getChildCount() <= 0
      bEmptyResponse = true
    else
      if channel.sponsorImages <> invalid and channel.sponsorImages.pixels <> invalid and channel.sponsorImages.pixels["container_details"] <> invalid
        '//When a sponsored container is made visible, then call the pixels
        sponsorPixels = channel.sponsorImages.pixels["container_details"]
        sendSponsorPixels(sponsorPixels)
      end if
    end if
  else
    bEmptyResponse = true
  end if
  
  if bEmptyResponse = true
    screen.isLoading = true
  else
    screen.isLoading = false
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

  if bEmptyResponse = true
    '//if no content, then display empty modal
    if task.channelId = m.constants.ui.categoryIds.queue
      showEmptyContentModal(screen)
    else
      showChannelContentError(msg, true)
    end if
  end if
End Function


Function showEmptyContentModal(screen)

  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: "CONTENT_NOT_FOUND" 'DialogType enum
      pageOneof: m.Tracking.getAnalyticsPage(screen.trackingPageInfo.pageType, screen.trackingPageInfo.pageValues)
      dialog_action: "SHOW"
      dialog_sub_type: "mylist-is-empty"
    }
  }
  
  title = getTranslation("dialog_mylist_empty_title")
  message = getTranslation("dialog_mylist_empty_description")
  buttons = [getTranslation("dialog_button_ok")]
  showSimpleInstantResumableModal(title, message, buttons, dialogEvent, m.trackingLoggingTask, removeTopScreen, removeTopScreen)

End Function


Function removeTopScreen()

  topScreen = getCurrentScreen()
  popScreen(false, false)
  topScreen = getCurrentScreen()
  
  sideNavId = m.constants.ui.screenIdToSideNavId[topScreen.id]
  focusSideNavOption(sideNavId)

end Function


Function onChannelContentError(msg)
  showChannelContentError(msg, false)
End Function


Function showChannelContentError(msg, bContentEmptyError = false)
  tubiLog("ChannelScreenHelpers.onChannelContentError")
  sErrorTitle = ""
  sErrorMessage = getTranslation("error_noGetChannels_description")
  if bContentEmptyError = true
    sErrorTitle = getTranslation("dialog_errorOops_title")
    sErrorMessage = getTranslation("error_noContent_description")
  end if 
  errorInfo = msg.getData()
  task = msg.getRoSGNode()
  screen = task.target
  topScreen = getCurrentScreen()
  if screen <> invalid and topScreen.id = m.constants.ui.screenIds.channelDetailScreen
    ' Screen is created/pushed in showChannelScreen, since there is no content, remove it.
    ' Do not send navigation tracking info when popping the screen, as navigation tracking wasn't
    ' sent in the case of an error.
    ' 
    ' If topScreen.id does not = the ID of a channelDetailScreen, then we know that the current screen is not being displayed
    ' So hold off on removing the screen and displaying an error. When the user traverses the navigation stack, then it will eventiually reveal this screen and if there is still no content, then it will display an error then.
    popScreen(false, false)
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

  task.unobserveField("response")
  task.unobserveField("error")
End Function


Function onChannelScreenBackPressed()
  onKeyEvent("back", true)
End Function
