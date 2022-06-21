' Show the homescreen, whether existing in the screen pool already or creating a new one
'
' @constants: assocArray, constants as set in Constants.brs and updated in the hotpatch
' @authInfo: assocArray, normally set by m.global.authInfo
' @screenID: string, What kind of homescreen do you wish to make: regular, movies, or TV
' @componentToFocus: string, one of the values in constants.ui.homescreen.focusItems
Function showHomeScreen(constants, authInfo, screenID = "", componentToFocus = "")
  tubiLog("HomeScreenHelpers.showHomeScreen")
  if screenID = ""
    screenID = constants.ui.screenIds.homeScreen
  end if

  homeScreen = getFromScreenCache(screenID)
  if homeScreen <> invalid
    ' this is required for setting focus to homescreen after activation/signout
    homeScreen.shouldFocusWhenPushed = m.top.fadeInContentController

    '//when calling pushScreen() for a cached home screen, then report navigate_to_page and
    ' page_load events immediately, since there is no content fetching occuring.
    shouldSendPageLoadEvent = true
    if homeScreen.isLoading = true
      ' when a user signs in/out, the homescreen may be in the screen cache, however the page may be
      ' going through the loading process, in which case we will send the PageLoadEvent when the
      ' homescreen concludes loading, in onHomescreenContentReady().
      shouldSendPageLoadEvent = false
      showHideSpinner(true)
    else
      showHideSpinner(false)
    end if

    homeScreen.signedIn = isLoggedInUser(authInfo)

    refreshHomescreenTopNav(homeScreen)
    ' set which component to focus on once the screen gains focus
    if componentToFocus = m.constants.ui.homescreen.focusItems.topNav
      homeScreen.componentToFocus = m.constants.ui.homescreen.focusItems.topNav
    else
      homeScreen.componentToFocus = m.constants.ui.homescreen.focusItems.contentGrid
    end if

    ' Reset user back to the top of the content when they return to content experience homepage
    if isICTSExperimentEnabled() = true
      screenIds = constants.ui.screenIds
      if screenID = screenIds.nostalgiaScreen or screenID = screenIds.bestKnownScreen or screenID = screenIds.linearTVScreen or screenID = screenIds.espanolScreen
        homeScreen.jumpToRowItem = [0, 0]
      end if
    end if

    pushScreen(homeScreen, true, shouldSendPageLoadEvent)
  else
    showHideSpinner(true)
    homeScreen = CreateObject("roSGNode", "HomeScreen")
    homeScreen.shouldFocusWhenPushed = m.top.fadeInContentController
    homeScreen.observeFieldScoped("backgroundUriList", "homeScreenBackgroundUpdated")
    homeScreen.observeFieldScoped("sponsorshipBackground", "onSponsorshipBackgroundChanged")
    homeScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
    homeScreen.observeFieldScoped("loadAllCategories", "onLoadAllCategories")
    homeScreen.observeFieldScoped("contentFocused", "onHomeScreenContentFocused")
    homeScreen.observeFieldScoped("contentSelected", "onContentSelected")
    homeScreen.observeFieldScoped("contentToPlay", "onContentToPlay")
    homeScreen.observeFieldScoped("topNavItemSelected", "onTopNavItemSelected")
    homeScreen.observeFieldScoped("topNavBackItemSelected", "onTopNavBackItemSelected")
    homeScreen.observeFieldScoped("transportVoiceResponse", "onTransportVoiceResponse")
    homeScreen.observeFieldScoped("scrollingstatus", "onScrollingStatusChange")
    homeScreen.observeFieldScoped("loadCategoriesIndex", "onLoadCategoriesIndex")
    homeScreen.observeFieldScoped("topNavToggled", "onScreenTopNavToggled")
    homeScreen.observeFieldScoped("navigatedAwayFromTopNav", "onNavigatedFromTopNavToSideNav")
    homeScreen.observeFieldScoped("stopLinearVideoPlayer", "onStopLinearVideoPlayer")
    homeScreen.observeFieldScoped("sponsoredRowFocused", "onHomescreenSponsoredRowFocused")
    homeScreen.observeFieldScoped("columnFocused", "onColumnFocusChanged")
    homeScreen.observeFieldScoped("stopVideoPreview", "onStopVideoPreview")
    homeScreen.observeFieldScoped("pauseVideoPreview", "onPauseVideoPreview")

    '//::TODO:: epg - remove this observer once the roku_linear_epg_v5 experiment is done
    homeScreen.observeField("focusedChild", "onHomeScreenFocusChange")

    m.playerFullscreenCountdownTimer.unobserveFieldScoped("fire") '//Stop lsitenting to timer before listing to it in case a previous screen started the timer
    m.playerFullscreenCountdownTimer.observeFieldScoped("fire", "onFullscreenCountdown")

    sContentMode = constants.ui.contentMode.homescreen
    if screenID = constants.ui.screenIds.homeScreen
      homeScreen.topNavSelectedId = constants.ui.sideNavIds.home
    else if screenID = constants.ui.screenIds.movieScreen
      sContentMode = constants.ui.contentMode.movie
      homeScreen.topNavSelectedId = constants.ui.sideNavIds.movies
    else if screenID = constants.ui.screenIds.tvScreen
      sContentMode = constants.ui.contentMode.tv
      homeScreen.topNavSelectedId = constants.ui.sideNavIds.tv
    else if screenID = constants.ui.screenIds.espanolScreen
      sContentMode = constants.ui.contentMode.latino
    else if screenID = constants.ui.screenIds.linearTVScreen
      sContentMode = constants.ui.contentMode.linear
      homeScreen.topNavSelectedId = constants.ui.sideNavIds.linearTV
    else if screenID = constants.ui.screenIds.bestKnownScreen
      sContentMode = constants.ui.contentMode.bestKnown
    else if screenID = constants.ui.screenIds.nostalgiaScreen
      sContentMode = constants.ui.contentMode.nostalgia
    end if

    homeScreen.contentMode = sContentMode
    homeScreen.shouldKidsModeBeSentToServer = shouldKidsModeBeSentToServer()

    homeScreen.signedIn = isLoggedInUser(authInfo)
    homeScreen.kidsModeFeatureOn = m.kidsModeFeatureOn
    homeScreen.canLoadCategories = true
    homeScreen.id = screenID

    refreshHomescreenTopNav(homeScreen)
    fetchHomescreen(homeScreen)
    setInScreenCache(homeScreen)

    ' set which component to focus on once the screen gains focus
    if componentToFocus = m.constants.ui.homescreen.focusItems.topNav
      homeScreen.componentToFocus = m.constants.ui.homescreen.focusItems.topNav
    else
      homeScreen.componentToFocus = m.constants.ui.homescreen.focusItems.contentGrid
    end if

    'page_load tracking will happen when content is received and displayed when onHomescreenContentReady() is called.
    pushScreen(homeScreen, true, false)
  end if
End Function



Function onHomeScreenFocusChange(msg)
  tubiLog("HomeScreenHelpers.onHomeScreenFocusChange")
  screen = msg.getRoSGNode()
  if screen <> invalid and screen.isInFocusChain() = true
    if isParentalControlsAdultLevel() = true and isKidsUIOn() = false and m.deeplinkContent = invalid
      '//Fire experiment exposure event when the Home Screen is focused - just in case there is a deep link to linear content
      '//::NOTE:: delete this function once the experiment is over
      getExperimentResource("roku_linear_epg", "roku_linear_epg_v5", true)
    end if

    if isLoggedInUser() = false
      getExperimentResource("roku_registration_subtext_homegrid", "roku_registration_subtext_homegrid_sidenav", true)
      getExperimentResource("roku_registration_subtext_homegrid", "roku_registration_subtext_homegrid_all", true)
    end if
  end if

End Function



Function homeBatchResponse(response)

  screenID = m.constants.ui.screenIds.homeScreen
  homeScreen = getFromScreenCache(screenID)
  if homeScreen <> invalid
    homeScreen.batchResponse = response
  end if

End Function


Function movieBatchResponse(response)

  screenID = m.constants.ui.screenIds.movieScreen
  homeScreen = getFromScreenCache(screenID)
  if homeScreen <> invalid
    homeScreen.batchResponse = response
  end if

End Function


Function tvBatchResponse(response)

  screenID = m.constants.ui.screenIds.tvScreen
  homeScreen = getFromScreenCache(screenID)
  if homeScreen <> invalid
    homeScreen.batchResponse = response
  end if

End Function


Function espanolBatchResponse(response)

  screenID = m.constants.ui.screenIds.espanolScreen
  homeScreen = getFromScreenCache(screenID)
  if homeScreen <> invalid
    homeScreen.batchResponse = response
  end if

End Function


Function nostalgiaBatchResponse(response)

  screenID = m.constants.ui.screenIds.nostalgiaScreen
  homeScreen = getFromScreenCache(screenID)
  if homeScreen <> invalid
    homeScreen.batchResponse = response
  end if

End Function


Function bestKnownBatchResponse(response)

  screenID = m.constants.ui.screenIds.bestKnownScreen
  homeScreen = getFromScreenCache(screenID)
  if homeScreen <> invalid
    homeScreen.batchResponse = response
  end if

End Function


Function LinearTVBatchResponse(response)

  screenID = m.constants.ui.screenIds.linearTVScreen
  homeScreen = getFromScreenCache(screenID)
  if homeScreen <> invalid
    homeScreen.batchResponse = response
  end if

End Function


' @componentToFocus: string, one of the values in constants.ui.homescreen.focusItems
Function showNostalgiaScreen(componentToFocus = "")
  showHomeScreen(m.constants, m.global.authInfo, m.constants.ui.screenIds.nostalgiaScreen, componentToFocus)
End Function


' @componentToFocus: string, one of the values in constants.ui.homescreen.focusItems
Function showBestKnownScreen(componentToFocus = "")
  showHomeScreen(m.constants, m.global.authInfo, m.constants.ui.screenIds.bestKnownScreen, componentToFocus)
End Function


' @componentToFocus: string, one of the values in constants.ui.homescreen.focusItems
Function showEspanolScreen(componentToFocus = "")
  showHomeScreen(m.constants, m.global.authInfo, m.constants.ui.screenIds.espanolScreen, componentToFocus)
End Function


' @componentToFocus: string, one of the values in constants.ui.homescreen.focusItems
Function showMoviesScreen(componentToFocus = "")
  showHomeScreen(m.constants, m.global.authInfo, m.constants.ui.screenIds.movieScreen, componentToFocus)
End Function


' @componentToFocus: string, one of the values in constants.ui.homescreen.focusItems
Function showTVScreen(componentToFocus = "")
  showHomeScreen(m.constants, m.global.authInfo, m.constants.ui.screenIds.tvScreen, componentToFocus)
End Function


' @componentToFocus: string, one of the values in constants.ui.homescreen.focusItems
Function showLinearTVScreen(componentToFocus = "")
  showHomeScreen(m.constants, m.global.authInfo, m.constants.ui.screenIds.linearTVScreen, componentToFocus)
End Function


' @componentToFocus: string, one of the values in constants.ui.homescreen.focusItems
Function showDefaultHomeScreen(componentToFocus = "")
  m.contentExperienceMode = m.constants.ui.contentExperienceModes.standard
  showHomeScreen(m.constants, m.global.authInfo, m.constants.ui.screenIds.homeScreen, componentToFocus)
End Function


Function reloadDefaultHomeScreenContent()
  '//If homescreen exists, then reload its content
  homescreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
  if homescreen <> invalid
    fetchHomescreen(homescreen)
  end if
End Function


Function onReloadUserCategoriesResponseInEspanolScreen(response)
  onReloadUserCategoriesInHomeScreen(response, m.constants.ui.screenIds.espanolScreen)
End Function


Function onReloadUserCategoriesResponseInNostalgiaScreenScreen(response)
  onReloadUserCategoriesInHomeScreen(response, m.constants.ui.screenIds.nostalgiaScreen)
End Function


Function onReloadUserCategoriesResponseInBestKnownScreenScreen(response)
  onReloadUserCategoriesInHomeScreen(response, m.constants.ui.screenIds.bestKnownScreen)
End Function


Function onReloadUserCategoriesResponseInLinearTVScreen(response)
  onReloadUserCategoriesInHomeScreen(response, m.constants.ui.screenIds.linearTVScreen)
End Function


Function onReloadUserCategoriesResponseInMovieScreen(response)
  onReloadUserCategoriesInHomeScreen(response, m.constants.ui.screenIds.movieScreen)
End Function


Function onReloadUserCategoriesResponseInTVScreen(response)
  onReloadUserCategoriesInHomeScreen(response, m.constants.ui.screenIds.tvScreen)
End Function


' @response: roSGNode, a ContentNode representing a container/category, may have no children
' @screenId: string, the id of the specific home page as found in m.constants.ui.screenIds
Function onReloadUserCategoriesInHomeScreen(response, screenID = "")
  tubiLog("HomeScreenHelpers.onReloadUserCategoriesInHomeScreen")

  if screenID = ""
    screenID = m.constants.ui.screenIds.homeScreen
  end if
  homeScreen = getFromScreenCache(screenID)

  if homeScreen <> invalid
    if homeScreen.content <> invalid
      newCategory = invalid
      oldCategory = invalid

      if type(response) = "roSGNode"
        if response.getChildCount() > 0
          newCategory = response
        end if

        oldCategory = homeScreen.content.findNode(response.id)
      end if

      homeScreen.rowAdded = ""
      homeScreen.rowRemoved = ""

      ' there are 4 options here
      ' 1) new category and old category both have content in them - replace the old with the new
      ' 2) new category has content, old category doesn't exist - add the new category
      ' 3) new category doesn't have content (will be invalid), old category does have content - remove old category
      ' 4) new category doesn't have content (will be invalid), old category doesn't exist - do nothing
      if newCategory <> invalid and oldCategory <> invalid
        'replace old category with new category
        homeScreen.content.replaceChild(newCategory, m.NodeHelpers.getChildIndex(homeScreen.content, oldCategory))
        homeScreen.repopulateContent = true
      else if newCategory <> invalid and oldCategory = invalid
        'add new category
        'if new category is history, put it one before queue, or if queue doens't exist put it in 2nd position
        'if new category is queue put it one after history, or if history doesn't exist, put it in 2nd position
        if newCategory.id = m.constants.ui.categoryIds.history
          clonedContent = homeScreen.content.clone(true)
          homeScreen.rowAdded = m.constants.ui.categoryIds.history
          clonedContent.insertChild(newCategory, homeScreen.content.continueWatchingIndex)
          homeScreen.content = clonedContent
        else if newCategory.id = m.constants.ui.categoryIds.queue
          homeScreen.rowAdded = m.constants.ui.categoryIds.queue
          clonedContent = homeScreen.content.clone(true)
          clonedContent.insertChild(newCategory, homeScreen.content.queueIndex)
          homeScreen.content = clonedContent
        end if

        homeScreen.repopulateContent = true '//In case the rows are of different heights, tell homescreen to refresh to display rows correctly
      else if newCategory = invalid and oldCategory <> invalid
        if oldCategory.id = m.constants.ui.categoryIds.history
          homeScreen.rowRemoved = m.constants.ui.categoryIds.history
        else if oldCategory.id = m.constants.ui.categoryIds.queue
          homeScreen.rowRemoved = m.constants.ui.categoryIds.queue
        end if

        'remove old category
        homeScreen.content.removeChild(oldCategory)
        homeScreen.repopulateContent = true '//In case the rows are of different heights, tell homescreen to refresh to display rows correctly
      else if newCategory = invalid and oldCategory = invalid
        'do nothing
      end if
    end if

    '//Stop loading of homescreen which will refresh the screen's content
    homeScreen.isLoading = false
  end if
End Function

Function onErrorReloadUserCategoriesInNostalgiaScreen(response)
  onErrorReloadUserCategories(response, m.constants.ui.screenIds.nostalgiaScreen)
End Function


Function onErrorReloadUserCategoriesInBestKnownScreen(response)
  onErrorReloadUserCategories(response, m.constants.ui.screenIds.bestKnownScreen)
End Function


Function onErrorReloadUserCategoriesInEspanolScreen(response)
  onErrorReloadUserCategories(response, m.constants.ui.screenIds.espanolScreen)
End Function


Function onErrorReloadUserCategoriesInLinearTVScreen(response)
  onErrorReloadUserCategories(response, m.constants.ui.screenIds.linearTVScreen)
End Function


Function onErrorReloadUserCategoriesInMovieScreen(response)
  onErrorReloadUserCategories(response, m.constants.ui.screenIds.movieScreen)
End Function


Function onErrorReloadUserCategoriesInTVScreen(response)
  onErrorReloadUserCategories(response, m.constants.ui.screenIds.tvScreen)
End Function


Function onErrorReloadUserCategories(response, screenID = "")
  tubiLog("HomeScreenHelpers.onErrorReloadUserCategories")

  if screenID = ""
    screenID = m.constants.ui.screenIds.homeScreen
  end if
  homeScreen = getFromScreenCache(screenID)

  if homeScreen <> invalid and response <> invalid
    analyticsContentMode = m.Tracking.getAnalyticsHomePageContentMode(screenID)

    ' if we were loading in the background, don't show an error modal
    if homeScreen.isInFocusChain() = true
      errorMessage = getTranslation("screenHome_error_fetchCategories_description")
      errorCode = getUserFacingErrorCode(m.constants.errors.context.homeScreen, m.constants.errors.subtypes.fetchError, response.code)
      dialogEvent = {
        type: "dialog"
        values: {
          dialog_type: "PLAYER_ERROR"
          pageOneof: m.Tracking.getAnalyticsPage("home_page", {content_mode: analyticsContentMode})
          dialog_action: "SHOW"
          dialog_sub_type: errorCode
        }
      }

      modalInfo = {
        message: getErrorMessage(errorMessage, errorCode)
        openTrackEvent: dialogEvent
        trackingTask: m.trackingLoggingTask
      }

      showErrorModal(modalInfo, onUserCategoriesFailed, screenID, invalid, invalid, [getTranslation("dialog_button_continue")])
    end if
  end if
End Function


' @homescreen: roSGNode, a HomeScreen component
Function refreshHomescreenTopNav(homeScreen)

  refreshNeeded = setEnableTopNavOnHomescreen(homeScreen)

  if refreshNeeded = true
    homeScreen.refreshTopNav = true
  end if
End Function


' sets the appropriate values for the 'isLinearTVAllowedInTopNav' and 'enableTopNav' fields in
' the passed in homescreen
' @homescreen: roSGNode, a Homescreen component
'
' @returns: boolean, true if the value on either the isLinearTVAllowedInTopNav or enableTopNav is
'           changing, indicating that the top nav items should be regenerated/refreshed
Function setEnableTopNavOnHomescreen(homeScreen)
  tubiLog("HomeScreenControllers.setEnableTopNavOnHomescreen")
  refreshNeeded = false

  if homeScreen <> invalid
    isPCAdult = isParentalControlsAdultLevel()

    if homeScreen.isLinearTVAllowedInTopNav <> isPCAdult
      preState = homeScreen.isLinearTVAllowedInTopNav
      if isPCAdult = true and getExperimentResource("roku_linear_epg", "roku_linear_epg_v5", false).side_nav = false
        homeScreen.isLinearTVAllowedInTopNav = true
      else
        homeScreen.isLinearTVAllowedInTopNav =  false
      end if
      if preState <> homeScreen.isLinearTVAllowedInTopNav
        refreshNeeded = true
      end if

    end if

    '//When the screen loads new content, make sure the topNav is displayed if it is supposed to. For example, if the user changes the parental settings from adults to older kids, then the app is in kidsMode and should not display the top nav. Changing the topNav status when reloading the content will ensure the top nav is diosplayed when it should be.
    bTopNavAllowed = isTopNavHomeScreenEnabled()
    if homeScreen.id = m.constants.ui.screenIds.espanolScreen
      '//espanol is not in the topNav
      bTopNavAllowed = false
    else if homeScreen.id = m.constants.ui.screenIds.nostalgiaScreen
      '//this screen is not in the topNav
      bTopNavAllowed = false
    else if homeScreen.id = m.constants.ui.screenIds.bestKnownScreen
      '//this screen is not in the topNav
      bTopNavAllowed = false
    end if

    if homeScreen.enableTopNav <> bTopNavAllowed
      homeScreen.enableTopNav = bTopNavAllowed
      refreshNeeded = true
    end if

    if homeScreen.signedIn <> isLoggedInUser() and (getExperimentResource("roku_registration_subtext_homegrid", "roku_registration_subtext_homegrid_topnav", false).subtext_topnav = true or getExperimentResource("roku_registration_subtext_homegrid", "roku_registration_subtext_homegrid_all", false).subtext_topnav = true)
      refreshNeeded = true
    end if
  end if

  return refreshNeeded
End Function


'//If the homescreen is loading, then display the default background
Function setHomeScreenLoading(homeScreen)
  screen = getCurrentScreen()
  homeScreen.isLoading = true
  '//checking screen for invalid, to show the loading spinner when user sign outs
  '//Display default background and spinner only if the home screen is the current screen while it is loading
  if screen = invalid or screen.id = homeScreen.id
    showHideSpinner(true)
    displayDefaultBackground()
  end if
End Function


' load all category content, including . Series do not have season or episode information though.
Function onLoadAllCategories(msg)
  tubiLog("HomeScreenHelpers.onLoadAllCategories")
  homeScreen = msg.getRoSGNode()
  fetchHomescreen(homeScreen)
End Function


Function fetchHomeScreen(homeScreen)
  ' This check causes all category fetches to be skipped prior to the field
  ' being set to true.  Then, once true categories reload any time fetchHomeScreen() is
  ' called, such as when signedIn field changes.
  if homeScreen.canLoadCategories = true
    reqName = m.constants.reqNames.getHomescreen

    homeScreen.trackingLoadStartTime = UpTime(0)
    homeScreen.unobserveFieldScoped("contentReady")
    homeScreen.observeFieldScoped("contentReady", "onHomescreenContentReady")

    sucessHandler = onHomeScreenSuccessResponse
    errorHandler = onHomeScreenErrorResponse
    if homeScreen.id = m.constants.ui.screenIds.movieScreen
      sucessHandler = onMovieScreenSuccessResponse
      errorHandler = onMovieScreenErrorResponse
    else if homeScreen.id = m.constants.ui.screenIds.tvScreen
      sucessHandler = onTVScreenSuccessResponse
      errorHandler = onTVScreenErrorResponse
    else if homeScreen.id = m.constants.ui.screenIds.espanolScreen
      sucessHandler = onEspanolScreenSuccessResponse
      errorHandler = onEspanolScreenErrorResponse
    else if homeScreen.id = m.constants.ui.screenIds.bestKnownScreen
      sucessHandler = onBestKnownScreenSuccessResponse
      errorHandler = onBestKnownScreenErrorResponse
    else if homeScreen.id = m.constants.ui.screenIds.nostalgiaScreen
      sucessHandler = onNostalgiaScreenSuccessResponse
      errorHandler = onNostalgiaScreenErrorResponse
    else if homeScreen.id = m.constants.ui.screenIds.linearTVScreen
      sucessHandler = onLinearTVScreenSuccessResponse
      errorHandler = onLinearTVScreenErrorResponse
    end if

    options = {}

    headers = {}
    params = {}

    isKidsMode = shouldKidsModeBeSentToServer()

    limitParamName = "contents_limit"
    contentModeParamName = "content_mode"

    ' For tensor API, we need to pass as empty string for homescreen
    if homeScreen.contentMode = m.constants.ui.contentMode.homescreen
      contentModeParamValue = ""
    else
      contentModeParamValue = homeScreen.contentMode
    end if

    params[contentModeParamName] = contentModeParamValue

    isKidsMode = shouldKidsModeBeSentToServer()

    if m.constants.settings.mode = "dev" and m.constants.settings.numContainers <> invalid
      params["group_size"] = m.constants.settings.numContainers
    end if

    params[limitParamName] = m.constants.performance.categoryGridList.initialBlockSize

    options.params = params
    options.headers = headers

    homeScreenReqInfo = m.CmsApi.homeScreenReqInfo(isKidsMode, options)
    m.makeRequest({
      url: homeScreenReqInfo.url
      requestType: reqName
      options: homeScreenReqInfo.options
      successCallback: sucessHandler
      errorCallback: errorHandler
      responseType: "node"
      authInfo: m.global.authInfo
      uiMode: m.uiMode
    })

    homeScreen.resetContentAreaValues = true
    setHomeScreenLoading(homeScreen)
  end if
End Function


''''''''''''''''''''''''''''''
' onLinearTVScreenSuccessResponse
'
Function onLinearTVScreenSuccessResponse(response)
  respondToHomeScreenSuccessResponse(m.constants.ui.screenIds.linearTVScreen, response)
End Function


''''''''''''''''''''''''''''''
' onEspanolscreenSuccessResponse
'
Function onEspanolScreenSuccessResponse(response)
  respondToHomeScreenSuccessResponse(m.constants.ui.screenIds.espanolScreen, response)
End Function


''''''''''''''''''''''''''''''
' onNostalgiaScreenSuccessResponse
'
Function onNostalgiaScreenSuccessResponse(response)
  respondToHomeScreenSuccessResponse(m.constants.ui.screenIds.nostalgiaScreen, response)
End Function


''''''''''''''''''''''''''''''
' onBestKnownScreenSuccessResponse
'
Function onBestKnownScreenSuccessResponse(response)
  respondToHomeScreenSuccessResponse(m.constants.ui.screenIds.bestKnownScreen, response)
End Function


''''''''''''''''''''''''''''''
' onMovieScreenSuccessResponse
'
Function onMovieScreenSuccessResponse(response)
  respondToHomeScreenSuccessResponse(m.constants.ui.screenIds.movieScreen, response)
End Function


''''''''''''''''''''''''''''''
' onTVscreenSuccessResponse
'
Function onTVScreenSuccessResponse(response)
  respondToHomeScreenSuccessResponse(m.constants.ui.screenIds.TVScreen, response)
End Function


''''''''''''''''''''''''''''''
' onHomeScreenSuccessResponse
'
Function onHomeScreenSuccessResponse(response)
  respondToHomeScreenSuccessResponse(m.constants.ui.screenIds.homeScreen, response)
End Function


''''''''''''''''''''''''''''''
' respondToHomeScreenSuccessResponse
'
Function respondToHomeScreenSuccessResponse(screenID, rawResponse)
  homeScreen = getFromScreenCache(screenID)
  if homeScreen <> invalid
    ' Content should be structured as:
    ' <CategoryContentNode json={...all contents info...}>
    '   <CategoryContentNode id="featured">
    '     <ContentNode id="37108" />
    '     <ContentNode id="337825" />
    '      ...
    '   </CategoryContentNode>
    '   <CategoryContentNode id="most_popular" />
    '     <ContentNode id="346629" />
    '     <ContentNode id="407698" />
    '      ...
    '   </CategoryContentNode>
    ' </CategoryContentNode>

    homeScreen.content = rawResponse
    homeScreen.contentUpdated = true

    ' don't set focus on the home screen if side nav has focus, for example
    if homeScreen.isInFocusChain() = true
      homeScreen.setFocus(true)
    end if
  end if
End Function


''''''''''''''''''''''''''''''
' onLinearTVScreenErrorResponse
'
Function onLinearTVScreenErrorResponse(response)
  handleHomeScreenErrorResponse(m.constants.ui.screenIds.linearTVScreen, response)
End Function


''''''''''''''''''''''''''''''
' onEspanolScreenErrorResponse
'
Function onEspanolScreenErrorResponse(response)
  handleHomeScreenErrorResponse(m.constants.ui.screenIds.espanolScreen, response)
End Function


''''''''''''''''''''''''''''''
' onNostalgiaScreenErrorResponse
'
Function onNostalgiaScreenErrorResponse(response)
  handleHomeScreenErrorResponse(m.constants.ui.screenIds.nostalgiaScreen, response)
End Function


''''''''''''''''''''''''''''''
' onBestKnownScreenErrorResponse
'
Function onBestKnownScreenErrorResponse(response)
  handleHomeScreenErrorResponse(m.constants.ui.screenIds.bestKnownScreen, response)
End Function


''''''''''''''''''''''''''''''
' onMoviescreenErrorResponse
'
Function onMovieScreenErrorResponse(response)
  handleHomeScreenErrorResponse(m.constants.ui.screenIds.movieScreen, response)
End Function


''''''''''''''''''''''''''''''
' onTVscreenErrorResponse
'
Function onTVScreenErrorResponse(response)
  handleHomeScreenErrorResponse(m.constants.ui.screenIds.TVScreen, response)
End Function


''''''''''''''''''''''''''''''
' onHomeScreenErrorResponse
'
Function onHomeScreenErrorResponse(response)
  handleHomeScreenErrorResponse(m.constants.ui.screenIds.homeScreen, response)
End Function


''''''''''''''''''''''''''''''
' handleHomeScreenErrorResponse
'
Function handleHomeScreenErrorResponse(screenID, response)

  homeScreen = getFromScreenCache(screenID)
  if homeScreen <> invalid

    homeScreen.unobserveFieldScoped("contentReady")
    ' if we were loading in the background, don't show an error modal
    if homeScreen.isInFocusChain()
      errorMessage = ""
      if screenID = m.constants.ui.screenIds.espanolScreen
        errorMessage = getTranslation("screenEspanol_error_fetchScreenContent_description")
      else if screenID = m.constants.ui.screenIds.movieScreen
        errorMessage = getTranslation("screenMovies_error_fetchScreenContent_description")
      else if screenID = m.constants.ui.screenIds.tvScreen
        errorMessage = getTranslation("screenTv_error_fetchScreenContent_description")
      else
        if homeScreen.kidsModeFeatureOn = true
          errorMessage = getTranslation("screenKids_error_fetchScreenContent_description")
        else
          errorMessage = getTranslation("screenHome_error_fetchScreenContent_description")
        end if
      end if
      errorCode = getUserFacingErrorCode(m.constants.errors.context.homeScreen, m.constants.errors.subtypes.fetchError, response.code)

      trackingPageInfo = homeScreen.trackingPageInfo

      dialogEvent = {
        type: "dialog"
        values: {
          dialog_type: "NETWORK_ERROR"
          pageOneof: m.Tracking.getAnalyticsPage(trackingPageInfo.pageType, trackingPageInfo.pageValues)
          dialog_action: "SHOW"
          dialog_sub_type: errorCode
        }
      }

      modalInfo = {
        message: getErrorMessage(errorMessage, errorCode)
        openTrackEvent: dialogEvent
        trackingTask: m.trackingLoggingTask
      }

      fnCancelFunction = retryCategoryList
      cancelParams = screenID
      if screenID <> m.constants.ui.screenIds.homeScreen
        '//it might be true there is no where to go to if the content of the main homescreen fails to load, but
        '// if the content of a different homescreen type fails to load, then destroy the current homescreen and (based on screen stack logic) take user back to the previous screen
        fnCancelFunction = destroyScreen
      end if
      showErrorModal(modalInfo, retryCategoryList, screenID, fnCancelFunction, cancelParams)
      showHideSpinner(false)
    end if

    loadTime = Int((Uptime(0) - homeScreen.trackingLoadStartTime) * 1000) 'in ms
    screenTrackingLoad(homeScreen.trackingPageInfo, loadTime, false)
  end if

End Function


' We retry in the cancel or retry cases, since there is nowhere else to go
Function retryCategoryList(screenID)
  tubiLog("HomeScreenHelpers.retryCategoryList")
  homeScreen = getFromScreenCache(screenID)
  if homeScreen <> invalid
    homeScreen.canLoadCategories = true
    fetchHomescreen(homeScreen)
    homeScreen.setFocus(true)
  end if
End Function


Function onStopLinearVideoPlayer(msg)
  tubiLog("HomescreenHelpers.onStopLinearVideoPlayer")
  shouldStop = msg.getData()
  if shouldStop = true
    stopCountdownTimer()

    ' Check if the video player has not gone to full screen before stopping.
    ' This is never expected to happen, but might be possible in the case of a race condition.
    if getCurrentScreen() = invalid or getCurrentScreen().id <> m.constants.ui.screenIds.linearVideoPlayerScreen
      stopAndHideLinearVideoPlayer()
    end if
  end if
End Function


' the homescreen has communicated that a sponsored row has been focused
Function onHomescreenSponsoredRowFocused(msg)
  isSponsoredRowFocused = msg.getData()
  if isSponsoredRowFocused = true
    homeScreen = msg.getRoSGNode()
    if homeScreen <> invalid
      row = homeScreen.rowFocused
      if row <> invalid
        manageHomescreenSponsorPixels(row)
        setSponsorshipBackground(homeScreen.sponsorshipBackground)
      end if
    end if
  end if
End Function


''''''''''''''''''''''''''''''
' jumpToParentScreenContentByID
'
' Focus on a specific item within the screen
' @sID, String = The ID of the content item that should be in focused
' @sDesiredContainerID, String = If there is a desire for a specific container to be in focuse, then this is the ID of the desired container
' @ScreenID, String = the ID of screen that should jump to the content associated with the sID. If screenId is missing, homeScreen is assumed.
Function jumpToParentScreenContentByID(sID, sDesiredContainerID = "", sParentScreenID = "")
  tubiLog("HomeScreenHelpers.jumpToParentScreenContentByID")
  if sParentScreenID = ""
    sParentScreenID = m.constants.ui.screenIds.homeScreen
  end if
  screen = getFromScreenCache(sParentScreenID)
  if screen <> invalid
    screen.jumpToRowItemByID = [sID, sDesiredContainerID]
  end if
End Function


'// when a new item is focused on, then do something
Function onHomeScreenContentFocused(msg)
  tubiLog("HomeScreenHelpers.onHomeScreenContentFocused")
  focusedContent = msg.getData()
  homeScreen = msg.getRoSGNode()
  setHomeScreenAfterFocus(focusedContent, homeScreen)
End Function


'//when a new column of the rowlist begins to gain partial focus during a horizontal scroll, then do something
Function onColumnFocusChanged()
  tubiLog("HomeScreenHelpers.onColumnFocusChanged")
  if isLinearPlayerLoading() = true or isLinearPlayerPlaying() = true
    '//as the rowlist is scrolling, if the the linear video player is playing or loading, then make sure the linear video player has stopped
    stopAndHideLinearVideoPlayer()
  end if
End Function


' setHomeScreenAfterFocus()
' This function should be called when a new rowlist item on the homescreen gains focus.
' Anything that needs to be set after a focus should be done in this function
' @param focusedContent, roSGNode - The TubiContentNode of the focused content
' @param homeScreen, roSGNode - The HomeScreen component that contains the focused content
Function setHomeScreenAfterFocus(focusedContent, homeScreen)

  if focusedContent <> invalid and getCurrentScreen() <> invalid and getCurrentScreen().id <> m.constants.ui.screenIds.linearVideoPlayerScreen
    '//unless told otherwise later in this function, the default for bStopCountdownTimer is to assume that
    '//we should stop the countdown timer
    bStopCountdownTimer = true
    epgExperimentResource = getExperimentResource("roku_linear_epg", "roku_linear_epg_v5", false)

    if focusedContent.type = m.constants.ui.categoryTypes.linear and focusedContent.id <> m.constants.ui.contentIds.tvGuide and m.SideNav.opened <> true
      bPlayVideo = true
      if isLinearPlayerPlayingThisContent(focusedContent) = true
        '//No need to play the video. It already is playing the video
        bPlayVideo = false
      end if

      if bPlayVideo = true
        '//If player is currently not playing the current content, then display background and
        '//tell player to load and play the video associated with the focused item
        m.backgroundGroup.posterVisible = true '//reset the background so it can be seen
        stopLinearVideoContent()
        playLinearVideoContent(focusedContent, true, homeScreen.id)
      else
        bStopCountdownTimer = false
        startCountdownTimer()

        if epgExperimentResource.enabled = false or epgExperimentResource.update_homescreen = false
          m.backgroundGroup.posterVisible = false
        end if
      end if
    else
      stopAndHideLinearVideoPlayer()
    end if

    if getExperimentResource("roku_video_preview", "roku_video_preview_v2", false).enabled = true and focusedContent.type <> invalid and m.SideNav.opened <> true
      previewState = getVideoPreviewStateForThisContent(focusedContent)
      if previewState = "buffering" or previewState = "playing"
        videoPreview = m.top.findNode(m.constants.ui.componentIds.videoPreviewPlayer)
        if videoPreview <> invalid
          setPageTypeForVideoPreview("home_page")
        end if
        m.backgroundGroup.posterVisible = false
      else if previewState = "paused"
        resumeVideoPreview()
      else
        ' this block is needed if user focuses to different content,
        ' it stops the preview of current content & starts the preview of new content
        stopVideoPreview()

        if isLinearPlayerPlayingThisContent(focusedContent) = false
          m.backgroundGroup.posterVisible = true
        end if

        if focusedContent.videoPreviewUrl <> ""
           ' fire exposure event for video preview non-control group
          getExperimentResource("roku_video_preview", "roku_video_preview_v2", true)
          startVideoPreview(focusedContent, "home_page")
        end if
      end if
    else if focusedContent.type <> invalid and m.SideNav.opened <> true and focusedContent.videoPreviewUrl <> ""
      ' fire exposure event for video preview control group
      getExperimentResource("roku_video_preview", "roku_video_preview_v2", true)
    end if

    if focusedContent.type <> invalid and epgExperimentResource.update_homescreen = true
      if focusedContent.type = m.constants.ui.categoryTypes.linear
        m.clock.visible = true
        m.logoGroup.visible = false
      else
        m.clock.visible = false
        m.logoGroup.visible = true
      end if
    end if

    if bStopCountdownTimer = true
      stopCountdownTimer()
    end if

  end if

End Function


'//Check the focused row if it is a sponsored container and if so, possibly send out the pixels
' @rowFocused: roSGNode, a CategoryContentNode
Function manageHomescreenSponsorPixels(rowFocused)
  if rowFocused <> invalid
    m.videoSponsorExposureId = ""
    '//When a sponsored container is made visible, then call the pixels
    containerId = rowFocused.id
    m.videoSponsorExposureId = rowFocused.sponsorExp
    sponsorPixels = rowFocused.sponsorImages.pixels["homescreen"]

    '//Only send sponsor pixels once per page load
    if m.sentSponsorPixels[containerId] <> true
      m.sentSponsorPixels[containerId] = true '//set to true when the sponsor image has been seen at least once per page load. This AA will be reset when the homescreen is no longer visible
      sendSponsorPixels(sponsorPixels)
    end if
  end if
End Function



' Select the Linear content that is currently focused
Function selectLinearContent(content)
  tubiLog("HomeScreenHelpers.selectLinearContent()")
  homeScreen = getCurrentScreen()

  '//stop timer and tell player to go fullscreen
  stopCountdownTimer()
  if content <> invalid and content.type = m.constants.ui.contentTypes.linear

    stopVideoPreviewIfPlaying() 'stop the videopreview if it is still playing.
    if content.id <> m.constants.ui.contentIds.tvGuide
      linearContent = getCurrentLinearContent()
      if linearContent <> invalid and linearContent.id <> invalid and content.id = linearContent.id
        '//If the user selects the linear content that is already playing, then just maximize it.
        maximizeLinearPlayer(content)
      else
        '//If the user selects the linear content that is not yet playing, then stop the previous content (if any) and start playing the content.
        stopLinearVideoContent()
        playLinearVideoContent(content, false, homeScreen.id)
      end if
    else
      if getExperimentResource("roku_linear_epg", "roku_linear_epg_v5", false).enabled = true
        showDefaultEPGScreen()
      end if
    end if
  end if
End Function


Function stopCountdownTimer()
  tubiLog("HomeScreenHelpers.stopCountdownTimer")
  if getExperimentResource("roku_linear_epg", "roku_linear_epg_v5", false).update_homescreen = true
    '//hide the countdown timer
    setPlayerCountDownChange(-1)
  else
    homeScreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
    if homeScreen <> invalid
      homeScreen.fullscreenCountdown = -1
    end if
    linearTVScreen = getFromScreenCache(m.constants.ui.screenIds.linearTVScreen)
    if linearTVScreen <> invalid
      linearTVScreen.fullscreenCountdown = -1
    end if
  end if
  epgScreen = getFromScreenCache(m.constants.ui.screenIds.epgScreen)
  if epgScreen <> invalid
    epgScreen.fullscreenCountdown = -1
  end if

  epgScreen = getFromScreenCache(m.constants.ui.screenIds.sportsEPGScreen)
  if epgScreen <> invalid
    epgScreen.fullscreenCountdown = -1
  end if

  epgScreen = getFromScreenCache(m.constants.ui.screenIds.newsEPGScreen)
  if epgScreen <> invalid
    epgScreen.fullscreenCountdown = -1
  end if

  epgScreen = getFromScreenCache(m.constants.ui.screenIds.entertainmentEPGScreen)
  if epgScreen <> invalid
    epgScreen.fullscreenCountdown = -1
  end if
  m.playerFullscreenCountdownTimer.control = "stop"
End Function


Function startCountdownTimer()
  tubiLog("HomeScreenHelpers.stopCountdownTimer")
  Screen = getCurrentScreen()
  if Screen <> invalid and (Screen.id = m.constants.ui.screenIds.homeScreen or Screen.id = m.constants.ui.screenIds.linearTVScreen)
    stopCountdownTimer()
    '//Start/reset timer to play video in fullscreen after a few seconds
    if getExperimentResource("roku_linear_epg", "roku_linear_epg_v5", false).update_homescreen = true
      setPlayerCountDownChange(m.constants.timers.linearFullscreenTimeout)
    else
      Screen.fullscreenCountdown = m.constants.timers.linearFullscreenTimeout
    end if
    m.playerFullscreenCountdownTimer.control = "start"
  else if Screen <> invalid and isAnEpgScreen(Screen) = true
    stopCountdownTimer()
    Screen.fullscreenCountdown = m.constants.timers.linearFullscreenTimeout
    m.playerFullscreenCountdownTimer.control = "start"
  end if
End Function


' Display a countdown timer over the minmized linear video player to show how many seconds are left before the player goes fullscreen
' @param nFullscreenCountdown, Integer - The number of seconds left in the countdown timer. If less than 0, then the timer is hidden.
Function setPlayerCountDownChange(nFullscreenCountdown)
  tubiLog("HomeScreenHelpers.setPlayerCountDownChange")
  m.fullscreenCountdown = nFullscreenCountdown
  if nFullscreenCountdown >= 0
    m.LinearCountdownTimer.display = true
    m.LinearCountdownTimer.seconds = nFullscreenCountdown
  else
    m.LinearCountdownTimer.display = false
  end if
End Function


Function onScrollingStatusChange(msg)
  '//if in the middle of scrolling, then stop the linear video player (if it is playing)
  homeScreen = msg.getRoSGNode()
  focusedContent = homeScreen.focusedChild
  setHomeScreenAfterFocus(focusedContent, homeScreen)
End Function


' Show the detail screen for the selected content
Function onContentSelected(msg)
  tubiLog("HomeScreenHelpers.onContentSelected")
  content = msg.getData()
  homeScreen = msg.getRoSGNode()
  m.autoplayContext = homeScreen.currCategoryId

  if content.type = "channel"
    showCategoryDetailsScreen(content, "HOME")
  else if content.type = m.constants.ui.contentTypes.historySignedOutUser
    '//if a signed out user selects the continue watching row, then navigate him/her to the sign in screen
    startSignIn(onCWRowAfterSignIn)
  else if content.type = m.constants.ui.contentTypes.linear
    selectLinearContent(content)
  else
    showDetailScreen(content, true)
  end if
End Function


Function onContentToPlay(msg)
  content = msg.getData()
  showDetailScreen(content, false, skipDetailScreen)
End Function


Function onHomescreenContentReady(msg)
  tubiLog("HomescreenHelpers.onHomescreenContentReady")
  homeScreen = msg.getRoSGNode()
  if homeScreen.contentReady = true
    fireAppLoadBeacon()
    homeScreen.unobserveFieldScoped("contentReady")
    homeScreen.isLoading = false
    showHideSpinner(false)

    '//Report the page_load analytics
    loadTime = Int((Uptime(0) - homeScreen.trackingLoadStartTime) * 1000) 'in ms
    currentScreen = getCurrentScreen()
    if currentScreen <> invalid AND currentScreen.id = m.constants.ui.screenIds.homeScreen
      screenTrackingLoad(homeScreen.trackingPageInfo, loadTime)
    end if
  end if
End Function


Function onUserCategoriesFailed(screenID)
  tubiLog("HomescreenHelpers.onUserCategoriesFailed")
  homeScreen = getFromScreenCache(screenID)
  if homeScreen <> invalid and homeScreen.content = invalid
    fetchHomescreen(homeScreen)
  end if
End Function


' load category content
Function onLoadCategoriesIndex(msg)
  tubiLog("HomeScreenHelpers.onLoadCategoriesIndex")
  homeScreen = msg.getRoSGNode()
  index = msg.getData()

  if homeScreen = invalid or homeScreen.content = invalid or index < 0
    return false
  end if

  batchResponseHandler = homeBatchResponse
  if homeScreen.id = m.constants.ui.screenIds.movieScreen
    batchResponseHandler = movieBatchResponse
  else if homeScreen.id = m.constants.ui.screenIds.tvScreen
    batchResponseHandler = tvBatchResponse
  else if homeScreen.id = m.constants.ui.screenIds.espanolScreen
    batchResponseHandler = espanolBatchResponse
  else if homeScreen.id = m.constants.ui.screenIds.bestKnownScreen
    batchResponseHandler = bestKnownBatchResponse
  else if homeScreen.id = m.constants.ui.screenIds.nostalgiaScreen
    batchResponseHandler = nostalgiaBatchResponse
  else if homeScreen.id = m.constants.ui.screenIds.linearTVScreen
    batchResponseHandler = linearTVBatchResponse
  end if

  isKidsMode = shouldKidsModeBeSentToServer()
  batchRequests = m.cmsApi.createHomeScreenBatchReqInfo(homeScreen, index, isKidsMode)

  if batchRequests <> invalid
    m.makeBatchRequest({
      requests: batchRequests
      responseType: "node"
      successCallback: batchResponseHandler
    })
  end if

End Function
