Function onScreensaverTimeoutChange()
  m.screensaverTimer.control = "stop"
  startScreensaverTimer()
End Function


'@timerDuration: Integer, how long to set the screensaver timer for
Function startScreensaverTimer(timerDuration = m.mainTask.screensaverTimeout)
  if timerDuration > 0 then
    m.screensaverTimer.duration = timerDuration
    m.screensaverTimer.control = "start"
  end if
End Function


Function onScreensaverTimerFired()
  timeUntilScreensaverStart = getTimeUntilScreensaverStart()

  if getExperimentResource("roku_screensaver", "roku_screensaver_v1", false).enabled <> true then
    ' We don't prevent the system screensaver from taking over in the control variant.
    ' In order to make sure we get our network request out in time for the experiment exposure event before the screensaver starts
    ' we trigger one second earlier
    timeUntilScreensaverStart -= 1
  end if

  if timeUntilScreensaverStart > 0 then
    startScreensaverTimer(timeUntilScreensaverStart)
  else if getExperimentResource("roku_screensaver", "roku_screensaver_v1", true).enabled = true then
    ' Start our screensaver
    showScreensaverScreen()
  end if
End Function


Function getTimeUntilScreensaverStart()
  newestTimestampOfLastVideoPlayback = 0

  ' First check if we've had a keypress that would preclude starting the screen saver
  lastKeypressTime = createObject("roDeviceInfo").timeSinceLastKeypress()
  screensaverTimeout = m.mainTask.screensaverTimeout
  if screensaverTimeout > lastKeypressTime then
    ' If so just set time to the remaining time and we'll check again at that time
    return screensaverTimeout - lastKeypressTime
  end if

  ' Else we need to check our video players to see how long it has been since they played to know if we're ok to start
  newestTimestampOfLastVideoPlayback = 0
  screenIds = m.constants.ui.screenIds

  ' First check current screen to see if it is a video player
  currentScreen = getCurrentScreen()
  if currentScreen <> invalid then
    currentScreenId = currentScreen.id
    if currentScreenId = screenIds.videoPlayerScreen OR currentScreenId = screenIds.linearVideoPlayerScreen then
      timestampOfLastVideoPlayback = currentScreen.timestampOfLastVideoPlayback
      if timestampOfLastVideoPlayback = -1 then
        ' Video is currently playing so return the full screensaver delay
        return screensaverTimeout
      end if

      newestTimestampOfLastVideoPlayback = timestampOfLastVideoPlayback
    end if
  end if

  ' Next check the preview player
  previewPlayer = m.videoPreviewPlayer
  if previewPlayer <> invalid then
    timestampOfLastVideoPlayback = previewPlayer.timestampOfLastVideoPlayback
    if timestampOfLastVideoPlayback = -1 then
      ' Video is currently playing so return the full screensaver delay
      return screensaverTimeout
    end if

    if timestampOfLastVideoPlayback > newestTimestampOfLastVideoPlayback then
      newestTimestampOfLastVideoPlayback = timestampOfLastVideoPlayback
    end if
  end if

  ' Finally check if we have a linear player screen that was not the current screen
  linearVideoPlayerScreen = getFromScreenCache(screenIds.linearVideoPlayerScreen)
  if linearVideoPlayerScreen <> invalid then
    timestampOfLastVideoPlayback = linearVideoPlayerScreen.timestampOfLastVideoPlayback
    if timestampOfLastVideoPlayback = - 1 then
      ' Video is currently playing so return the full screensaver delay
      return screensaverTimeout
    end if

    if timestampOfLastVideoPlayback > newestTimestampOfLastVideoPlayback then
      newestTimestampOfLastVideoPlayback = timestampOfLastVideoPlayback
    end if
  end if

  timeSinceLastVideoPlayback = createObject("roDateTime").asSeconds() - newestTimestampOfLastVideoPlayback
  return screensaverTimeout - timeSinceLastVideoPlayback
End Function


Function getScreensaverScreen()
  screensaverScreen = invalid
  screen = getCurrentScreen()
  if screen <> invalid AND screen.id = m.constants.ui.screenIds.screensaverScreen then
    screensaverScreen = screen
  end if

  return screensaverScreen
End Function


Function showScreensaverScreen()
  ' There are certain cases like when an ad is paused that our settting to disable the screensaver is overridden. We reenforce our request by setting it again on a player we control
  m.videoPreviewPlayer.disableScreensaver = false
  m.videoPreviewPlayer.disableScreensaver = true
  screensaverScreen = createObject("roSGNode", "ScreensaverScreen")
  screensaverScreen.id = m.constants.ui.screenIds.screensaverScreen
  screensaverScreen.screenLevel = m.constants.ui.screenLevels.screensaverScreen

  screensaverScreen.observeFieldScoped("exitInfo", "onScreensaverScreenExitInfoChange")

  hideNavMenu(false)

  modal = getTopModal()
  if modal <> invalid then
    ' Have to hide before we push
    hideModal(modal)
  end if

  pushScreen(screensaverScreen, false, false)
  showHideSpinner(true)
  loadScreensaverFeed()

  return screensaverScreen
End Function


Function onScreensaverScreenExitInfoChange(msg)
  exitInfo = msg.getData()
  closeScreensaverScreen(exitInfo)
End Function


'@exitInfo: AA, for future use about what item was selected when we exited the screensaver
Function closeScreensaverScreen(exitInfo = {})
  showHideSpinner(false)
  popScreen(false, false)
  startScreensaverTimer()

  modal = getTopModal()
  if modal <> invalid then
    unhideModal(modal)
  end if
End Function


Function loadScreensaverFeed()
  categoryIds = m.constants.ui.categoryIds
  countryCode = UCase(m.constants.deviceInfo.countryCode)
  ' In the US and Canada we use a preset list of containers but for others we use the first two rows from homescreen instead
  if countryCode = "US" OR countryCode = "CA" then
    if shouldKidsModeBeSentToServer() = true then
      sendBatchRequestForScreensaverContainers([
        categoryIds.featured
        categoryIds.mostPopular
      ], 30)
    else
      sendBatchRequestForScreensaverContainers([
        categoryIds.featured
        categoryIds.movieNight
        categoryIds.seriesSpotlight
      ], 20)
    end if
  else
    sendGetScreensaverHomeScreenContainerIdsRequest()
  end if
End Function


'@containerIds: stringarray, list of container ids that we should request the list of items for
'@numberOfItemsPerContainer: integer, max number of items to request for each container request
Function sendBatchRequestForScreensaverContainers(containerIds, numberOfItemsPerContainer)
  batchRequests = []

  isKidsMode = shouldKidsModeBeSentToServer()
  for each containerId in containerIds
    request = m.cmsApi.containerForScreensaverReqInfo(containerId, numberOfItemsPerContainer, isKidsMode)
    batchRequests.push(request)
  end for

  m.makeBatchRequest({
    "requests": batchRequests
    "responseType": "array" ' Don't want to do nodearray as if a request fails it will be an AA response
    "successCallback": onScreensaverContainersRequestsSuccessResponse
    "errorCallback": onScreensaverRequestErrorResponse
  })
End Function


Function onScreensaverContainersRequestsSuccessResponse(containerResponses)
  ' Loop through in reverse order and remove any failed responses before passing along
  for i = containerResponses.count() - 1 to 0 step -1
    containerResponse = containerResponses[i]
    if isNode(containerResponse) = false then
      containerResponses.delete(i)
    end if
  end for

  screensaverScreen = getScreensaverScreen()
  if screensaverScreen <> invalid then
    screensaverScreen.containerResponses = containerResponses
  end if
  showHideSpinner(false)
End Function


Function sendGetScreensaverHomeScreenContainerIdsRequest()
  isKidsMode = shouldKidsModeBeSentToServer()
  reqInfo = m.cmsApi.homeScreenContainerIdsForScreensaverReqInfo(isKidsMode)
  reqInfo.successCallback = onGetScreensaverHomeScreenContainerIdsRequestSuccessResponse
  reqInfo.errorCallback = onScreensaverRequestErrorResponse
  reqInfo.responseType = "node"

  m.makeRequest(reqInfo)
End Function
Function onGetScreensaverHomeScreenContainerIdsRequestSuccessResponse(response)
  sendBatchRequestForScreensaverContainers(response.containerIds, 30)
End Function


Function onScreensaverRequestErrorResponse(response)
  tubiLog("Failed to load screensaver feed")
  closeScreensaverScreen()
End Function
