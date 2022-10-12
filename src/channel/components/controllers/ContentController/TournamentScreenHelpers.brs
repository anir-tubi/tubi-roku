' Show the tournament Screen
' @constants: assocArray, constants as set in Constants.brs
' @componentToFocus: string, one of the values in constants.ui.tournamentScreen.focusItems
Function showTournamentScreen(constants, componentToFocus = "")
  tubiLog("tournamentScreenHelpers.showtournamentScreen")


' isPreTournament is used to decide whether epgRow on tournament page should be first row, or last row.
' currently isPreTournement is hard coded to false, because of the decision to keep the epgRow at the end on tournament page.
  isPreTournament = false

  screenID = constants.ui.screenIds.tournamentScreen

  tournamentScreen = getFromScreenCache(screenID)
  showHideLogo(m.constants.logoType.tubiFifa)

  if tournamentScreen <> invalid
    ' this is required for setting focus to tournamentScreen after activation/signout
    tournamentScreen.shouldFocusWhenPushed = m.top.fadeInContentController
    changeTournamentScreenBackground(tournamentScreen)
    shouldSendPageLoadEvent = true
    if tournamentScreen.contentReady = false
      shouldSendPageLoadEvent = false
      showHideSpinner(true)
    else
      showHideSpinner(false)
    end if

    tournamentScreen.signedIn = isLoggedInUser()
    tournamentScreen.isPreTournament = isPreTournament

    ' set which component to focus on once the screen gains focus
    if componentToFocus = m.constants.ui.tournamentScreen.focusItems.topNav
      tournamentScreen.componentToFocus = m.constants.ui.tournamentScreen.focusItems.topNav
    else
      tournamentScreen.componentToFocus = tournamentScreen.focusedComponent
    end if

    pushScreen(tournamentScreen, true, shouldSendPageLoadEvent)
  else

    displayDefaultBackground()  ' clear background from previous screens until tournamentScreen loads
    showHideSpinner(true)

    tournamentScreen = CreateObject("roSGNode", "TournamentScreen")
    tournamentScreen.id = screenID
    tournamentScreen.observeFieldScoped("backgroundUriList", "ontournamentScreenBackgroundChange")
    tournamentScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
    tournamentScreen.observeFieldScoped("programGuidecomponentInteractionInfo", "onComponentInteractionInfoChange")
    tournamentScreen.observeFieldScoped("componentInteractionInfo", "onComponentInteractionInfoChange")
    tournamentScreen.observeFieldScoped("transportVoiceResponse", "onTransportVoiceResponse")
    tournamentScreen.observeFieldScoped("contentToPlay", "onContentToPlay")
    tournamentScreen.observeFieldScoped("topNavItemSelected", "onTopNavItemSelected")
    tournamentScreen.observeFieldScoped("topNavBackItemSelected", "onTopNavBackItemSelected")
    tournamentScreen.observeFieldScoped("topNavToggled", "onScreenTopNavToggled")
    tournamentScreen.observeFieldScoped("EPGScrollingStatus", "onEPGScrollingStatusChange")
    tournamentScreen.observeFieldScoped("refreshtournamentScreenVideoPlay", "onRefreshtournamentScreenVideoPlay")
    tournamentScreen.observeFieldScoped("tournamentScreenEPGOkPressed", "onTournamentScreenEPGOKPressed")
    tournamentScreen.observeFieldScoped("linearChannelToPlay", "onTournamentScreenLinearContentToPlay")
    tournamentScreen.observeFieldScoped("contentSelected", "onTournamentScreenVodContentToPlay")
    tournamentScreen.observeFieldScoped("reloadTournamentScreen", "onReloadTournamentScreen")
    tournamentScreen.signedIn = isLoggedInUser()
    tournamentScreen.isPreTournament = isPreTournament
    tournamentScreen.isLinearTVAllowedInTopNav = isParentalControlsAdultLevel() '

    m.playerFullscreenCountdownTimer.unobserveFieldScoped("fire") '//Stop lsitenting to timer before listing to it in case a previous screen started the timer
    m.playerFullscreenCountdownTimer.observeFieldScoped("fire", "onFullscreenCountdown")

    tournamentScreen.shouldFocusWhenPushed = m.top.fadeInContentController 'just in case if get deeplink this page in future.
    tournamentScreen.refreshTopNav = true

    refreshtournamentScreen(tournamentScreen)

    setInScreenCache(tournamentScreen)

    ' set which component to focus on once the screen gains focus
    if componentToFocus = m.constants.ui.tournamentScreen.focusItems.topNav
      tournamentScreen.componentToFocus = m.constants.ui.tournamentScreen.focusItems.topNav
    else if isPreTournament = true
      tournamentScreen.componentToFocus = m.constants.ui.tournamentScreen.focusItems.epgTimeGrid
    else
      tournamentScreen.componentToFocus = m.constants.ui.tournamentScreen.focusItems.categoryGridList
    end if
    pushScreen(tournamentScreen, true, false)

    tournamentScreen.topNavSelectedId = m.constants.ui.sideNavIds.tournament
  end if

End Function


Function isDuringTournament() as Boolean
  tubilog("TournamentScreenHelpers.isDuringTournament")

  today = CreateObject("roDateTime")
  today.ToLocalTime()

  startDate = m.constants.tournament.startDate
  endDate = m.constants.tournament.endDate

  ' //BELOW BLOCK IS ADDED FOR QA TESTING. QA can change the dates on <env>.yml file for testing pre/during/post tournament cases
  if m.constants.settings.mode <> "production"
    if isNonEmptyString(m.constants.settings.tournamentStartDate)
      startDate = m.constants.settings.tournamentStartDate
    end if
    if isNonEmptyString(m.constants.settings.tournamentEndDate)
      endDate = m.constants.settings.tournamentEndDate
    end if
  end if

  tournamentStartDate = CreateObject("roDateTime")
  tournamentStartDate.FromISO8601String(startDate)
  tournamentStartDate.ToLocalTime()

  tournamentEndDate = CreateObject("roDateTime")
  tournamentEndDate.FromISO8601String(endDate)
  tournamentEndDate.ToLocalTime()

  if today.asSeconds() >= tournamentStartDate.asSeconds() and today.asSeconds() <= tournamentEndDate.asSeconds()
    return true
  else
    return false
  end if

End Function


Function onTournamentScreenBackgroundChange(msg)
  tubiLog("TournamentScreenHelpers.onTournamentScreenBackgroundChange")
  tournamentScreen = msg.getRoSGNode()
  changeTournamentScreenBackground(tournamentScreen)
End Function


Function changeTournamentScreenBackground(tournamentScreen)
  tubilog("TournamentScreenHelpers.changeTournamentScreenBackground")
  if tournamentScreen <> invalid AND tournamentScreen.backgroundUriList <> invalid
    m.backgroundGroup.backgroundInfo = {
      type: m.constants.ui.backgroundTypes.epg
      uriList : tournamentScreen.backgroundUriList
    }
  end if
End Function


Function refreshtournamentScreen(tournamentScreen)
  tubilog("TournamentScreenHelpers.refreshtournamentScreen")
  fetchTournamentScreenContent(tournamentScreen)
End Function


Function fetchTournamentScreenContent(tournamentScreen)
  tubilog("TournamentScreenHelpers.fetchTournamentScreenContent")
  if isTournamentScreen(tournamentScreen) = true 'AND tournamentScreen.isLoading = false
    tournamentScreen.trackingLoadStartTime = UpTime(0)
    tournamentScreen.signedIn = isLoggedInUser()
    tournamentScreen.unobserveFieldScoped("contentReady")
    tournamentScreen.observeFieldScoped("contentReady", "onTournamentScreenContentReady")
    tournamentApiInfo = m.tensorapi.getTournamentReqInfo()
    tournamentScreen.isLoading = true

    showHideSpinner(true)
    displayDefaultBackground()

    m.makeRequest({
      url : tournamentApiInfo.url
      requestType : m.constants.reqNames.getTournamentScreen
      options : tournamentApiInfo.options
      successCallback : onTournamentScreenSuccessResponse
      errorCallback : onTournamentScreenErrorResponse
      responseType : "node"
      requestorID : m.constants.ui.screenIds.tournamentScreen
      isSignedInUser: tournamentScreen.signedIn
    })
  end if

End Function


Function isTournamentScreen(screen)
  tubiLog("TournamentScreenHelpers.isTournamentScreen")

  if screen <> invalid
    return screen.isSubType("tournamentScreen")
  end if
  return false
End Function


Function  onTournamentScreenSuccessResponse(response)
  tubiLog("TournamentScreenHelpers.onTournamentScreenSuccessResponse")
  tournamentScreen = getFromScreenCache(m.constants.ui.screenIds.tournamentScreen)

  if tournamentScreen <> invalid AND response <> invalid AND response.requestorID = tournamentScreen.id

    tournamentScreen.content = response
    tournamentScreen.contentUpdated = true

    ' don't set focus on the tournament screen if side nav has focus, for example
    if tournamentScreen.isInFocusChain() = true
      tournamentScreen.setFocus(true)
    end if
  end if
End Function


Function onTournamentScreenLinearContentToPlay(_msg)
  tubiLog("TournamentScreenHelpers.onTournamentScreenLinearContentToPlay")
  currentScreen = getCurrentScreen()

  if isTournamentScreen(currentScreen) = true
    contentToPlay = currentScreen.LinearChannelToPlay
    if contentToPlay <> invalid
      startPlayVideo = true
      linearVideoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
      if linearVideoPlayer <> invalid AND linearVideoPlayer.content <> invalid
        if linearVideoPlayer.content.id = contentToPlay.id AND linearVideoPlayer.state = "playing"
          'do not Re-play same content
          startPlayVideo = false
        end if
      end if

      if startPlayVideo = true
        stopCountdownTimer() 'stop previous counter if any
        stopLinearVideoContent() 'user might have changed the linearchannel on the video overlay.
        playLinearVideoContent(contentToPlay, true, currentScreen.id)
      end if
    end If
  end if
End Function


Function onTournamentScreenEPGOKPressed(msg)
  tubiLog("TournamentScreenHelpers.onTournamentScreenEPGOKPressed")
  currentScreen = msg.getRoSGNode()
  if currentScreen.linearChannelToPlay <> invalid
    selectLinearContent(currentScreen.linearChannelToPlay)
  end if
End Function


Function onTournamentScreenErrorResponse(response)
  tubilog("TournamentScreenHelpers.onTournamentScreenErrorResponse")
  screen = getCurrentScreen()

  code = 0
  if response <> invalid AND isTournamentScreen(screen) = true AND screen.id = response.requestorID
    screen.unobserveFieldScoped("contentReady")
    showHideSpinner(false)
    'No data has been receieved. So pop the screen and let user go back to previous screen.
    popScreen(false, false)
    errorMessage = getTranslation("screenTournament_error_fetchScreenContent_description")

    if response.code <> invalid
      code = response.code
    end if

    errorCode = getUserFacingErrorCode(m.constants.errors.context.tournament, m.constants.errors.subtypes.fetchError, code)

    dialogEvent = {
      type: "dialog"
      values: {
        dialog_type: "NETWORK_ERROR"
        pageOneof: m.Tracking.getAnalyticsPage("worldcup_browse_page", {})
        dialog_action: "SHOW"
        dialog_sub_type: errorCode
      }
    }

    modalInfo = {
      message: getErrorMessage(errorMessage, errorCode)
      openTrackEvent: dialogEvent
      trackingTask: m.trackingLoggingTask
    }
    showErrorModal(modalInfo)
  end if
End Function


Function onTournamentScreenContentReady(msg)
  tubiLog("TournamentScreenHelpers.onTournamentScreenContentReady")
  tournamentScreen = msg.getRoSGNode()

  if tournamentScreen.contentReady = true
    tournamentScreen.unobserveFieldScoped("contentReady")
    tournamentScreen.isLoading = false
    showHideSpinner(false)
    if tournamentScreen.trackingPageInfo <> invalid
      '//Report the page_load analytics
      loadTime = Int((Uptime(0) - tournamentScreen.trackingLoadStartTime) * 1000) 'in ms
      screenTrackingLoad(tournamentScreen.trackingPageInfo, loadTime)
    end if
  end if
End Function


Function onRefreshTournamentScreenVideoPlay(msg)
  tubiLog("TournamentScreenHelpers.onRefreshTournamentScreenVideoPlay")

  refreshVideoPlay = msg.getData()
  tournamentScreen = msg.getRoSGNode()
  refreshTournamentScreenVideoPlay(refreshVideoPlay,tournamentScreen)
End Function


' This function will handle the minimized video player on tournament Screen
'   refreshVideoPlay = true  - Close the Video player since tournamentScreen/EPG component lost focus (sideNav or topNav)
'   refreshVideoPlay = false, there are two possibilities
'     1) tournamentScreen returning back from full video screen. Keep the video as it is, and make sure the video screen and focused channel are the same.
'     2) tournamentScreen:EPG component is gaining focus from side/topNav. In this case restart the video.
Function refreshTournamentScreenVideoPlay(refreshVideoPlay, tournamentScreen)
  tubilog("TournamentScreenHelpers.refreshTournamentScreenVideoPlay")

  currentScreen = getCurrentScreen()
  screenID = currentScreen.id
  if screenID = m.constants.ui.screenIds.linearVideoPlayerScreen
    'do nothing. Linear screen is taken over.
  else if refreshVideoPlay = true
    m.backgroundGroup.posterVisible = true
    stopCountdownTimer()
    tournamentScreen.fullScreenCountdown = -1
    stopAndHideLinearVideoPlayer()
  else 'from FullScreen video
    linearVideoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)

    if linearVideoPlayer <> invalid AND linearVideoPlayer.state = "playing"
        m.backgroundGroup.posterVisible = false

        focusedChannel = tournamentScreen.linearChannelFocused
        if focusedChannel <> invalid AND focusedChannel.id <> invalid
          if isLinearPlayerPlayingThisContent(focusedChannel) <> true 'user selected different channel on EPG overlay
            m.backgroundGroup.posterVisible = true

            if isTournamentScreen(currentScreen) = true AND currentScreen.linearChannelToPlay <> invalid AND currentScreen.focusedComponent = m.constants.ui.tournamentScreen.focusItems.epgTimeGrid
              playLinearVideoContent(currentScreen.linearChannelToPlay, true, currentScreen.id)
            end if
          end if
        end if

        startCountdownTimer()

    else ' from top/side Nav/contentGrid
      m.backgroundGroup.posterVisible = true

      if isTournamentScreen(currentScreen) = true AND currentScreen.linearChannelToPlay <> invalid AND currentScreen.focusedComponent = m.constants.ui.tournamentScreen.focusItems.epgTimeGrid
        playLinearVideoContent(currentScreen.linearChannelToPlay, true, currentScreen.id)
      end if
    end if
  end if

End Function


Function onTournamentScreenVodContentToPlay(msg)
  tubiLog("TournamentScreenHelpers.onTournamentScreenVodContentToPlay")
  itemSelected = msg.getData()

  if itemSelected <> invalid
    showDetailScreen(itemSelected, true)
  end if
End Function


Function onReloadTournamentScreen(msg)
  tubiLog("TournamentSceenHelpers.onReloadTournamentScreen")
  screen = msg.getRoSGNode()
  refreshTournamentScreen(screen)
End Function


Function showTournamentScreenWrapper(param)
  stopVideoPreview()
  showTournamentScreen(param.constants, param.componentToFocus)
End Function
