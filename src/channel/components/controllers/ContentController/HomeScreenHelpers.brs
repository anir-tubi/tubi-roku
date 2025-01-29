' Show the homescreen, whether existing in the screen pool already or creating a new one
'
' @constants: assocArray, constants as set in Constants.brs and updated in the hotpatch
' @screenID: string, What kind of homescreen do you wish to make: regular, movies, or TV
Function showHomeScreen(constants, screenID = "")
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

    authInfo = m.tubiAuthUpdate.getAuthInfo()
    homeScreen.signedIn = isLoggedInUser(authInfo)

    homeScreen.isVideoPreviewOn = m.pub_serverPersistentData.isVideoPreviewOn
    m.pubSub.subscribe("pub_serverPersistentData.isVideoPreviewOn", homeScreen, "isVideoPreviewOn")

    pushScreen(homeScreen, true, shouldSendPageLoadEvent)

    '//when cached homescreen is displayed, then check UI needs to be updated
    setHomeScreenAfterFocus(homeScreen.contentFocused, homeScreen)
  else
    showHideSpinner(true)
    homeScreen = CreateObject("roSGNode", "HomeScreen")
    homeScreen.shouldFocusWhenPushed = m.top.fadeInContentController
    homeScreen.observeFieldScoped("backgroundUriList", "onVideoContentScreenBackgroundUpdated")
    homeScreen.observeFieldScoped("sponsorshipBackground", "onSponsorshipBackgroundChanged")
    homeScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
    homeScreen.observeFieldScoped("loadAllCategories", "onLoadAllCategories")
    homeScreen.observeFieldScoped("contentFocused", "onHomeScreenContentFocused")
    homeScreen.observeFieldScoped("contentSelected", "onContentSelected")
    homeScreen.observeFieldScoped("contentToPlay", "onContentToPlay")
    homeScreen.observeFieldScoped("transportVoiceResponse", "onTransportVoiceResponse")
    homeScreen.observeFieldScoped("loadCategoriesIndex", "onLoadCategoriesIndex")
    homeScreen.observeFieldScoped("stopLinearVideoPlayer", "onStopLinearVideoPlayer")
    homeScreen.observeFieldScoped("sponsoredRowFocused", "onHomescreenSponsoredRowFocused")
    homeScreen.observeFieldScoped("columnFocused", "onColumnFocusChanged")
    homeScreen.observeFieldScoped("currFocusRow", "onHomescreenRowFocusChanged")
    homeScreen.observeFieldScoped("stopVideoPreview", "onStopVideoPreview")
    homeScreen.observeFieldScoped("pauseVideoPreview", "onPauseVideoPreview")
    homeScreen.observeFieldScoped("loadCategoryForIds", "onLoadCategoryForIds")
    homeScreen.observeFieldScoped("eventCtaListItemSelected", "onEventCtaListItemSelected")
    homeScreen.observeFieldScoped("componentInteractionInfo", "onComponentInteractionInfoChange")

    m.playerFullscreenCountdownTimer.unobserveFieldScoped("fire") '//Stop listening to timer before listing to it in case a previous screen started the timer
    m.playerFullscreenCountdownTimer.observeFieldScoped("fire", "onFullscreenCountdown")

    sContentMode = constants.ui.contentMode.homescreen
    if screenID = constants.ui.screenIds.movieScreen
      sContentMode = constants.ui.contentMode.movie
    else if screenID = constants.ui.screenIds.tvScreen
      sContentMode = constants.ui.contentMode.tv
    else if screenID = constants.ui.screenIds.espanolScreen
      sContentMode = constants.ui.contentMode.latino
    end if

    homeScreen.contentMode = sContentMode
    homeScreen.shouldKidsModeBeSentToServer = shouldKidsModeBeSentToServer()

    authInfo = m.tubiAuthUpdate.getAuthInfo()
    homeScreen.signedIn = isLoggedInUser(authInfo)
    homeScreen.isVideoPreviewOn = m.pub_serverPersistentData.isVideoPreviewOn
    m.pubSub.subscribe("pub_serverPersistentData.isVideoPreviewOn", homeScreen, "isVideoPreviewOn")
    homeScreen.kidsModeFeatureOn = m.kidsModeFeatureOn
    homeScreen.kidsMode = isKidsUIOn()
    homeScreen.canLoadCategories = true
    homeScreen.id = screenID

    fetchHomescreen(homeScreen)
    setInScreenCache(homeScreen)

    'page_load tracking will happen when content is received and displayed when onHomescreenContentReady() is called.
    pushScreen(homeScreen, true, false)
  end if

  if m.global <> invalid
    m.global.addField("refreshLinearChannels", "boolean", false)
  end if
End Function


Function homeBatchResponse(response)
  processHomeScreenBatchResponse(response, m.constants.ui.screenIds.homeScreen)
End Function


Function movieBatchResponse(response)
  processHomeScreenBatchResponse(response, m.constants.ui.screenIds.movieScreen)
End Function


Function tvBatchResponse(response)
  processHomeScreenBatchResponse(response, m.constants.ui.screenIds.tvScreen)
End Function


Function espanolBatchResponse(response)
  processHomeScreenBatchResponse(response, m.constants.ui.screenIds.espanolScreen)
End Function


Function processHomeScreenBatchResponse(response, screenId)
  homeScreen = getFromScreenCache(screenId)
  if homeScreen <> invalid

    containerRow = m.nodeHelpers.getChildById(response, m.constants.ui.categoryIds.purpleCarpet)
    if containerRow <> invalid
      m.purpleCarpetContainerContentNode = containerRow.clone(true)
      if m.isFoxPlayerLoadRequired = true then
        loadFoxVideoPlayerComponentLibrary()
      end if

      response.removeChild(containerRow)
      context = {
        purpleCarpetContainer: containerRow
        screenId: screenId
      }

      ' If the user has navigated away from the homescreen before the container info for the purple carpet has returned,
      ' avoid making the Fox listing call since a request to the Fox listing API will be made when a user returns to the homescreen.
      currentScreen = getCurrentScreen()
      if currentScreen.id = screenId
        updateContainerWithProgramInfoFromFoxListing(context, refreshPurpleCarpetContainer)
      end if

    end if
    homeScreen.batchResponse = response
  end if
End Function


Function showEspanolScreen()
  showHomeScreen(m.constants, m.constants.ui.screenIds.espanolScreen)
End Function


Function showMoviesScreen()
  showHomeScreen(m.constants, m.constants.ui.screenIds.movieScreen)
End Function


Function showTVScreen()
  showHomeScreen(m.constants, m.constants.ui.screenIds.tvScreen)
End Function


Function showDefaultHomeScreen()
  showHomeScreen(m.constants, m.constants.ui.screenIds.homeScreen)
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
      if newCategory <> invalid AND oldCategory <> invalid
        'replace old category with new category
        homeScreen.content.replaceChild(newCategory, m.NodeHelpers.getChildIndex(homeScreen.content, oldCategory))
        homeScreen.repopulateContent = true
      else if newCategory <> invalid AND oldCategory = invalid
        'add new category
        'if new category is history, put it one before queue, or if queue doesn't exist put it in 2nd position
        'if new category is queue put it one after history, or if history doesn't exist, put it in 2nd position
        if newCategory.id = m.constants.ui.categoryIds.queue OR newCategory.id = m.constants.ui.categoryIds.history then
          homeScreen.rowAdded = newCategory.id

          content = homeScreen.content
          if newCategory.id = m.constants.ui.categoryIds.queue then
            insertIndex = content.queueIndex
          else
            insertIndex = content.continueWatchingIndex
          end if

          contentArray = [newCategory]

          ' We can't use -1 for getting the node children since we aren't getting all the content so we have to calculate how many rows to retrieve
          rowsToRetrieve = content.getChildCount() - insertIndex
          existingRowsRetrieved = content.getChildren(rowsToRetrieve, insertIndex)
          contentArray.append(existingRowsRetrieved)

          ' Replace children is the fastest (1ms on Nemo) way to modify existing ArrayGrid row structure with clone being second fastest (434ms) and insertChild being the slowest (453ms)
          content.replaceChildren(contentArray, insertIndex)

          ' In order to insert a new row while using replaceChildren(), which is the fastest method, we need to replace the existing rows with the new row plus the existing rows minus the last row, and then append the last row.
          ' See https://developer.roku.com/docs/references/brightscript/interfaces/ifsgnodechildren.md#replacechildrenchild_nodes-as-object-index-as-integer-as-boolean for more information
          content.appendChild(contentArray.peek())
        end if

        homeScreen.repopulateContent = true '//In case the rows are of different heights, tell homescreen to refresh to display rows correctly
      else if newCategory = invalid AND oldCategory <> invalid
        if oldCategory.id = m.constants.ui.categoryIds.history
          homeScreen.rowRemoved = m.constants.ui.categoryIds.history
        else if oldCategory.id = m.constants.ui.categoryIds.queue
          homeScreen.rowRemoved = m.constants.ui.categoryIds.queue
        end if

        'remove old category
        homeScreen.content.removeChild(oldCategory)

        homeScreen.repopulateContent = true '//In case the rows are of different heights, tell homescreen to refresh to display rows correctly
      else if newCategory = invalid AND oldCategory = invalid
        'do nothing
      end if
    end if

    '//Stop loading of homescreen which will refresh the screen's content
    homeScreen.isLoading = false
  end if
End Function


Function onErrorReloadUserCategoriesInEspanolScreen(response)
  onErrorReloadUserCategories(response, m.constants.ui.screenIds.espanolScreen)
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

  if homeScreen <> invalid AND response <> invalid
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


'//If the homescreen is loading, then display the default background
Function setHomeScreenLoading(homeScreen)
  screen = getCurrentScreen()
  homeScreen.isLoading = true
  '//checking screen for invalid, to show the loading spinner when user sign outs
  '//Display default background and spinner only if the home screen is the current screen while it is loading
  if screen = invalid OR screen.id = homeScreen.id
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
  tubiLog("HomeScreenHelpers.fetchHomeScreen")
  ' This check causes all category fetches to be skipped prior to the field
  ' being set to true.  Then, once true categories reload any time fetchHomeScreen() is
  ' called, such as when signedIn field changes.
  if homeScreen.canLoadCategories = true
    reqName = m.constants.reqNames.getHomescreen

    homeScreen.trackingLoadStartTime = UpTime(0)
    authInfo = m.tubiAuthUpdate.getAuthInfo()
    homeScreen.signedIn = isLoggedInUser(authInfo)
    homeScreen.unobserveFieldScoped("contentReady")
    homeScreen.observeFieldScoped("contentReady", "onHomescreenContentReady")

    successHandler = onHomeScreenSuccessResponse
    errorHandler = onHomeScreenErrorResponse
    if homeScreen.id = m.constants.ui.screenIds.movieScreen
      successHandler = onMovieScreenSuccessResponse
      errorHandler = onMovieScreenErrorResponse
    else if homeScreen.id = m.constants.ui.screenIds.tvScreen
      successHandler = onTVScreenSuccessResponse
      errorHandler = onTVScreenErrorResponse
    else if homeScreen.id = m.constants.ui.screenIds.espanolScreen
      successHandler = onEspanolScreenSuccessResponse
      errorHandler = onEspanolScreenErrorResponse
    end if

    options = {}

    headers = {}
    params = {}

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

    if m.constants.settings.mode = "dev" AND m.constants.settings.numContainers <> invalid
      params["group_size"] = m.constants.settings.numContainers
    end if

    params[limitParamName] = m.constants.performance.categoryGridList.initialBlockSize

    options.params = params
    options.headers = headers

    homeScreenReqInfo = m.CmsApi.createHomeScreenReqInfo(isKidsMode, options)
    m.makeRequest({
      url: homeScreenReqInfo.url
      requestType: reqName
      options: homeScreenReqInfo.options
      successCallback: successHandler
      errorCallback: errorHandler
      responseType: "node"
      isSignedInUser: isLoggedInUser()
      uiMode: m.uiMode
    })

    homeScreen.resetContentAreaValues = true
    setHomeScreenLoading(homeScreen)
  end if
End Function


''''''''''''''''''''''''''''''
' onEspanolscreenSuccessResponse
'
Function onEspanolScreenSuccessResponse(response)
  respondToHomeScreenSuccessResponse(m.constants.ui.screenIds.espanolScreen, response)
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

    containerRow = m.nodeHelpers.getChildById(rawResponse, m.constants.ui.categoryIds.purpleCarpet)
    isPurpleCarpetContainerPresent = (containerRow <> invalid)

    if containerRow <> invalid
      ' Cloning it so that any modifications does not effect the original tensor response.
      m.purpleCarpetContainerContentNode = containerRow.clone(true)
    end if

    if isPurpleCarpetContainerPresent = true
      rawResponse.removeChild(containerRow)
      m.foxListingEndpointResponse = invalid
      context = {
        purpleCarpetContainer: containerRow
        screenId: homeScreen.id
      }
      updateContainerWithProgramInfoFromFoxListing(context, onHomeScreenContentUpdateComplete)
    else
      ' Since this callback is called for all types of home screen modes like shows and movies we should not resetting the m scope value.
      if screenID = m.constants.ui.screenIds.homeScreen
        m.purpleCarpetContainerContentNode = invalid
      end if
      homeScreen.purpleCarpetContent = invalid
      homeScreen.purpleCarpetContentUpdated = true
    end if

    ads = rawResponse.ads
    if isKidsUIOn() = false AND ads <> invalid AND getExperimentResource("ads_tubi_skins", "ads_tubi_skin_paddington", false).enabled = true
      updateSkinAdRowContent(homeScreen, ads)
    end if

    homeScreen.personalizationId = rawResponse.personalizationId
    homeScreen.shouldTrackViewableImpressionEvent = (isUserInAdultsMode() = true AND isKidsUIOn() = false)

    homeScreen.content = rawResponse

    ' If purple carpet container is not present than we can proceed with showing the home screen or else we need to wait until the filtering of the purple carpet data is completed.
    ' which includes calling listing api and updated the tensor api data with listing api information to enable playback.
    if isPurpleCarpetContainerPresent = false
      onHomeScreenContentUpdateComplete(invalid, homeScreen.id)
    end if

  end if
End Function


''''''''''''''''''''''''''''''
' onEspanolScreenErrorResponse
'
Function onEspanolScreenErrorResponse(response)
  handleHomeScreenErrorResponse(m.constants.ui.screenIds.espanolScreen, response)
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
        if isKidsUIOn() = true
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
    if getCurrentScreen() = invalid OR getCurrentScreen().id <> m.constants.ui.screenIds.linearVideoPlayerScreen
      stopAndHideLinearVideoPlayer()
    end if
  end if
End Function


' the homescreen has communicated that a sponsored row has been focused
Function onHomescreenSponsoredRowFocused(msg)
  isSponsoredRowFocused = msg.getData()
  homeScreen = msg.getRoSGNode()
  currentScreen = getCurrentScreen()
  if isSponsoredRowFocused = true AND homeScreen <> invalid AND currentScreen <> invalid AND currentScreen.isSameNode(homeScreen)
    row = homeScreen.rowFocused
    if row <> invalid
      manageHomescreenSponsorPixels(row)
      setSponsorshipBackground(homeScreen.sponsorshipBackground)
    end if
  end if
End Function


''''''''''''''''''''''''''''''
' jumpToParentScreenContentByID
'
' Focus on a specific item within the screen
' @sID, String = The ID of the content item that should be in focused
' @sDesiredContainerID, String = If there is a desire for a specific container to be in focused, then this is the ID of the desired container
' @sParentScreenID, String = the ID of screen that should jump to the content associated with the sID. If screenId is missing, homeScreen is assumed.
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
  ' Content Focused needs to be updated even when home screen is not in focus so that background image gets displayed even when side nav is in focus.
  if homeScreen.isInFocusChain() = true
    setHomeScreenAfterFocus(focusedContent, homeScreen)
  end if
End Function


'//when a new column of the rowlist begins to gain partial focus during a horizontal scroll, then do something
Function onColumnFocusChanged()
  tubiLog("HomeScreenHelpers.onColumnFocusChanged")
  if isLinearPlayerLoadingOrPlaying() = true
    '//as the rowlist is scrolling, if the the linear video player is playing or loading, then make sure the linear video player has stopped
    stopAndHideLinearVideoPlayer()
  end if
End Function


Function onHomescreenRowFocusChanged()
  if isLinearPlayerLoadingORPlaying() = true
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
  tubiLog("HomeScreenHelpers.setHomeScreenAfterFocus")

  '//update the UI anytime the homescreen changes focus.
  setUIBasedOnFocusedContent(focusedContent)

  if focusedContent <> invalid
    currentScreen = getCurrentScreen()

    if currentScreen <> invalid AND currentScreen.id <> m.constants.ui.screenIds.linearVideoPlayerScreen
      '//unless told otherwise later in this function, the default for bStopCountdownTimer is to assume that
      '//we should stop the countdown timer
      bStopCountdownTimer = true
      if focusedContent.type = m.constants.ui.categoryTypes.linear AND m.SideNav.opened <> true AND m.tempModal = invalid AND m.constants.deviceInfo.isAutoplayEnabled = true
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

          playbackSource = {
            "srcForAnalytic": m.constants.player.playbackSource.unknown
            "srcForAds": m.constants.player.playbackOrigin.container
            "playbackContainer": currentScreen.currCategoryId
          }
          playLinearVideoContent(focusedContent, true, homeScreen.id, true, playbackSource)
        else
          bStopCountdownTimer = false
          startCountdownTimer()

          m.backgroundGroup.posterVisible = false
        end if
      else
        if isLinearPlayerLoadingORPlaying() = true
          stopAndHideLinearVideoPlayer()
        end if
      end if

      if currentScreen.isSameNode(homeScreen) = true AND currentScreen.isInFocusChain() = true  'if there are any modals over home screen or focus has been lost to side nav
        setVideoPreviewAfterFocus(focusedContent, currentScreen.trackingPageInfo)
      end if

      if bStopCountdownTimer = true
        stopCountdownTimer()
      end if
    end if
  end if
End Function


' Call this function when the UI needs to be changed based on the content item that has (or if the side nav has focus, will have) focus
Function setUIBasedOnFocusedContent(focusedContent)
  if focusedContent <> invalid
    currentScreen = getCurrentScreen()

    if currentScreen <> invalid
      skinAdContent = currentScreen.skinAdContent
      if currentScreen.id = m.constants.ui.screenIds.homeScreen AND skinAdContent <> invalid AND skinAdContent.getChildCount() > 0
        if focusedContent.gridItemType = m.constants.ui.gridItemTypes.skinAd
          '//Hide the logo if the current row is a skinAd
          showHideLogo(m.constants.logoType.hide)

          sendSkinAdPixels(focusedContent.imageImpTracking)

        else
          showHideLogoBasedOnUiMode(skinAdContent.titleImageUrl, skinAdContent.titlePrefix)
        end if

        '//set the footer image while the homescreen is visible
        setSponsorshipFooter(skinAdContent.footerImageUrl)
        setBackgroundColor(skinAdContent.bgColor)
      end if
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
  if content <> invalid AND content.type = m.constants.ui.contentTypes.linear
    linearContent = getCurrentLinearContent()
    if linearContent <> invalid AND linearContent.id <> invalid AND content.id = linearContent.id
      '//If the user selects the linear content that is already playing, then just maximize it.
      maximizeLinearPlayer(content)
    else
      '//If the user selects the linear content that is not yet playing, then stop the previous content (if any) and start playing the content.
      stopLinearVideoContent()
      playbackSource = {
        "srcForAnalytic": m.constants.player.playbackSource.unknown
        "srcForAds": m.constants.player.playbackOrigin.container
        "playbackContainer": homeScreen.currCategoryId
      }
      playLinearVideoContent(content, false, homeScreen.id, true, playbackSource)
    end if
  end if
End Function


Function stopCountdownTimer()
  tubiLog("HomeScreenHelpers.stopCountdownTimer")

  homeScreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
  if homeScreen <> invalid
    homeScreen.fullscreenCountdown = -1
  end if

  epgScreen = getFromScreenCache(m.constants.ui.screenIds.epgScreen)
  if epgScreen <> invalid
    epgScreen.fullscreenCountdown = -1
  end if

  m.playerFullscreenCountdownTimer.control = "stop"
End Function


Function startCountdownTimer()
  tubiLog("HomeScreenHelpers.startCountdownTimer")
  screen = getCurrentScreen()

  if screen <> invalid AND (screen.id = m.constants.ui.screenIds.homeScreen OR isAnEpgScreen(screen) = true)
    stopCountdownTimer()
    screen.fullscreenCountdown = m.constants.settings.linearFullscreenTimeout

    m.playerFullscreenCountdownTimer.control = "start"
  end if
End Function


' Show the detail screen for the selected content
Function onContentSelected(msg)
  tubiLog("HomeScreenHelpers.onContentSelected")
  content = msg.getData()
  homeScreen = msg.getRoSGNode()
  m.autoplayContext = homeScreen.currCategoryId

  contentType = content.type
  if contentType = m.constants.ui.contentTypes.purpleCarpetEvent
    processPlayEvent(content, homeScreen)
  else if contentType = m.constants.uapiContentTypes.channel
    stopVideoPreview()
    showCategoryDetailsScreen(content)
  else if contentType = m.constants.ui.contentTypes.historySignedOutUser
    '//if a signed out user selects the continue watching row, then navigate him/her to the sign in screen
    startSignIn(refreshScreenAndContentAfterSignIn)
  else if contentType = m.constants.ui.contentTypes.linear
    selectLinearContent(content)
  else if contentType = m.constants.ui.contentTypes.skinAd
    playAdContent(content)
  else
    playbackSource = {
      "srcForAnalytic": m.constants.player.playbackSource.unknown
      "srcForAds": m.constants.player.playbackOrigin.container
      "playbackContainer": homeScreen.currCategoryId
    }
    showDetailScreen(content, true, invalid, invalid, playbackSource)
  end if
End Function


Function onContentToPlay(msg)
  content = msg.getData()
  screen = msg.getRoSGNode()

  if screen <> invalid AND screen.currCategoryId <> invalid
    containerId = screen.currCategoryId
  else if screen <> invalid AND screen.categoryId <> invalid 'category screen
    containerId = screen.categoryId
  else
    containerId = content.parentId
  end if

  playbackSource = {
    "srcForAnalytic": m.constants.player.playbackSource.unknown
    "srcForAds":m.constants.player.playbackOrigin.container
    "playbackContainer": containerId
  }

  contentType = content.type
  ' Since category panel list screen re-uses the method allowing it to play the content.
  if contentType = m.constants.ui.contentTypes.purpleCarpetEvent
    processPlayEvent(content, screen)
  else if contentType = m.constants.uapiContentTypes.channel
    showCategoryDetailsScreen(content)
  else if contentType = m.constants.ui.contentTypes.historySignedOutUser
    '//if a signed out user selects the continue watching row, then navigate him/her to the sign in screen
    startSignIn(refreshScreenAndContentAfterSignIn)
  else if contentType = m.constants.ui.contentTypes.skinAd
    playAdContent(content)
  else
    showDetailScreen(content, false, skipDetailScreen, invalid, playbackSource)
  end if
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

    if currentScreen <> invalid AND currentScreen.isSubType("HomeScreen") = true
      trackingPageInfo = homeScreen.trackingPageInfo
      screenTrackingLoad(trackingPageInfo, loadTime)

      'show registration welcome Screen only to new user over homescreen.
      'we need to check if user already signed up in detail Screen if they have entered through deeplink.
      if hasRegModalBeenShown() = false
        showRegistrationWelcomeModal()
      end if
    end if
  end if
End Function


Function onUserCategoriesFailed(screenID)
  tubiLog("HomescreenHelpers.onUserCategoriesFailed")
  homeScreen = getFromScreenCache(screenID)
  if homeScreen <> invalid AND homeScreen.content = invalid
    fetchHomescreen(homeScreen)
  end if
End Function


' load category content
Function onLoadCategoriesIndex(msg)
  tubiLog("HomeScreenHelpers.onLoadCategoriesIndex")
  homeScreen = msg.getRoSGNode()
  index = msg.getData()

  if homeScreen = invalid OR homeScreen.content = invalid OR index < 0
    return false
  end if

  batchResponseHandler = homeBatchResponse
  if homeScreen.id = m.constants.ui.screenIds.movieScreen
    batchResponseHandler = movieBatchResponse
  else if homeScreen.id = m.constants.ui.screenIds.tvScreen
    batchResponseHandler = tvBatchResponse
  else if homeScreen.id = m.constants.ui.screenIds.espanolScreen
    batchResponseHandler = espanolBatchResponse
  end if

  isKidsMode = shouldKidsModeBeSentToServer()
  isSignedInUser = isLoggedInUser()
  uiMode = m.uiMode
  batchRequests = m.cmsApi.createHomeScreenBatchReqInfo(homeScreen, index, isKidsMode, isSignedInUser, uiMode)

  if batchRequests <> invalid
    m.makeBatchRequest({
      requests: batchRequests
      responseType: "node"
      successCallback: batchResponseHandler
    })
  end if

  return true
End Function


' This function build the custom modal as per the design
Function showRegistrationWelcomeModal()
  tubiLog("HomeScreenHelpers.showRegistrationWelcomeModal")

  showHideSpinner(false)

  header = getTranslation("reg_intro_title")
  subHeader = getTranslation("reg_intro_sub_header")

  multiMessage = []
  multiMessage[0] = {
    header: getTranslation("onBoarding_landingScreen_addListLabel")
    subHeader: getTranslation("reg_first_line_sub_item")
    iconUri: "pkg:/images/icon-add-to-queue.webp"
  }

  multiMessage[1] = {
    header: getTranslation("onBoarding_landingScreen_saveProgressLabel")
    subHeader: getTranslation("onBoarding_landingScreen_saveProgressBody")
    iconUri: "pkg:/images/icon-play.webp"
  }

  multiMessage[2] = {
    header: getTranslation("reg_third_line_item")
    subHeader: getTranslation("reg_third_line_sub_item")
    iconUri: "pkg:/images/icon-account.webp"
  }

  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: "INFORMATION"
      pageOneof: m.Tracking.getAnalyticsPage("home_page", {content_mode: "CONTENT_MODE_UNKNOWN"})
      dialog_action: "SHOW"
      dialog_sub_type: "reg_intro"
    }
  }

  modalInfo = {
    header: header
    subHeader: subHeader
    message: ""               'message is not used in case of multistyle dialog
    modalDialogTypes: m.constants.modalDialogTypes.multiStyle
    modalDialogStyles: m.constants.modalDialogStyles.multiMessageGroup
    multiStyleMessage: multiMessage
    openTrackEvent: dialogEvent
    trackingTask: m.trackingLoggingTask
    backButtonCallback: invalid
    instantResumeAction: m.constants.instantResumeActions.closeDialog
  }

  buttonInfo = []

  buttonOne = {
    text: getTranslation("reg_sign_in_button_title")
    type: "accept"
    callback: startSignIn
    callbackParams: invalid
    shouldFocusParentBeforeCallback: false 'special case for signIn button. If parent gets focus when dialog closes, video preview or linear will start playing in backgroud of RFI modal.
  }
  buttonInfo.push(buttonOne)

  buttonTwo = {
    text: getTranslation("reg_continue_as_guest_button_title")
    type: "dismiss"
    callback: invalid
    callbackParams: invalid
  }
  buttonInfo.push(buttonTwo)

  showMultiStyleModal(modalInfo, buttonInfo)
End Function


' load category content
Function onLoadCategoryForIds(msg)
  tubiLog("HomeScreenHelpers.onLoadCategoryForIds")
  homeScreen = msg.getRoSGNode()
  categoryIDs = msg.getData()

  if homeScreen = invalid OR homeScreen.content = invalid OR categoryIDs.count() <= 0
    return false
  end if

  batchResponseHandler = homeBatchResponse
  if homeScreen.id = m.constants.ui.screenIds.movieScreen
    batchResponseHandler = movieBatchResponse
  else if homeScreen.id = m.constants.ui.screenIds.tvScreen
    batchResponseHandler = tvBatchResponse
  else if homeScreen.id = m.constants.ui.screenIds.espanolScreen
    batchResponseHandler = espanolBatchResponse
  end if

  isKidsMode = shouldKidsModeBeSentToServer()
  isSignedInUser = isLoggedInUser()

  if homeScreen.contentMode = m.constants.ui.contentMode.homescreen
    contentMode = ""
  else
    contentMode = homeScreen.contentMode
  end if

  batchRequests = m.cmsApi.createHomeScreenBatchRequestInfoForContainers(categoryIDs, contentMode, isKidsMode, isSignedInUser)

  if batchRequests <> invalid
    m.makeBatchRequest({
      requests: batchRequests
      responseType: "node"
      successCallback: batchResponseHandler
    })
  end if
  return true
End Function


'This function handles the logic to determine whether to show the registration modal over homegrid with the following main requirements
' show registration modal only to new user
' within the new user session, show only once when app launches
' do not show if the user is already logged in during deeplink
Function hasRegModalBeenShown()
  currentScreen = getCurrentScreen()
  if m.constants.settings.mode = "qa" AND m.constants.settings.hideStartupModals = true
      return true
  end if

  if isNewUser() = true AND m.hasRegModalBeenShownWithinNewUserSession = false AND isMajorEventDay() = false
    if currentScreen.id = m.constants.ui.screenIds.homeScreen AND isLoggedInUser() = false
      m.hasRegModalBeenShownWithinNewUserSession = true
      return false
    end if
  end if

  return true
End Function


' @param homeScreen, roSGNode - The HomeScreen component that contains the focused content.
' @param content, roSGNode - The ContentNode for the skin item.
Function updateSkinAdRowContent(homeScreen, content)
  tubiLog("HomeScreenHelpers.updateSkinAdRowContent")

  if content <> invalid AND (isNonEmptyString(content.title) = true OR isNonEmptyString(content.titleImageUrl) = true) AND isNonEmptyString(content.id) = true AND (isNonEmptyString(content.videoPreviewUrl) = true OR (isNonEmptyArray(content.backgrounds) = true AND isNonEmptyString(content.backgrounds[0]) = true) ) AND isNonEmptyString(content.HDGRIDPOSTERURL) = true
    '//proceed if the content is valid and has the mandatory fields
    rowContentNode = CreateObject("roSGNode", "SkinAdContentNode")
    rowContentNode.id = content.id
    rowContentNode.type = m.constants.ui.contentTypes.skinAd
    rowContentNode.footerImageUrl = content.footerImageUrl
    rowContentNode.bgColor = content.bgColor
    rowContentNode.title = content.title
    rowContentNode.titleImageUrl = content.titleImageUrl
    rowContentNode.titlePrefix = content.titlePrefix
    rowContentNode.gridItemType = m.constants.ui.gridItemTypes.skinAd
    rowContentNode.description = content.description
    rowContentNode.subDescription = content.subDescription
    rowContentNode.qrCodeUrl = content.qrCodeUrl
    rowContentNode.adInfo = content.adInfo
    rowContentNode.imageImpTracking = content.imageImpTracking

    categoryContentNode = CreateObject("roSGNode", "CategoryContentNode")
    categoryContentNode.id = m.constants.ui.categoryIds.skinAd
    categoryContentNode.appendChild(content)
    rowContentNode.appendChild(categoryContentNode)
    homeScreen.skinAdContent = rowContentNode
    homeScreen.skinAdContentUpdated = true
  end if

End Function


' @param content, roSGNode - The CategoryContentNode for the purple carpet row.
Function updatePurpleCarpetRowContent(homeScreen, content)
  if isNode(content) = true
    rowContentNode = CreateObject("roSGNode", "ContentNode")
    rowContentNode.id = m.constants.ui.categoryIds.purpleCarpet
    content.update({
      gridItemType: m.constants.ui.gridItemTypes.purpleCarpet
    }, true)
    rowContentNode.appendChild(content)

    ' Since for limited ui we will not have any data in the initial but during lazy load of containers we will obtain all the data.
    ' So we will proceed with creating a purple carpet container as long as backend returns top level container.
    if content.getChildCount() > 0
      primaryContent = content.getChild(0)
      bookmark = getBookmark(primaryContent.id)
      homeScreen.didUserSetReminderForEventContent = (bookmark <> invalid)
    end if

    homeScreen.purpleCarpetContent = rowContentNode
  else
    homeScreen.purpleCarpetContent = invalid
  end if
  homeScreen.purpleCarpetContentUpdated = true
End Function


Function onEventCtaListItemSelected(msg)
  id = msg.getData()
  screen = msg.getRoSGNode()
  primaryEventContent = screen.primaryEventContent
  purpleCarpetContent = screen.purpleCarpetContent

  if primaryEventContent <> invalid
    if id = "signInWatch"
      startSignIn(startPurpleCarpetPlaybackAfterSignIn)
    else if id = "details"
      showEventDetailScreen(primaryEventContent.id, purpleCarpetContent)
    else if id = "watchLive"
      processPlayEvent(primaryEventContent, screen, true)
    else if id = "reminder"
      if isLoggedInUser() = false
        startSignIn(setOrRemovePurpleCarpetReminderAfterSignIn)
      else
        setOrRemovePurpleCarpetReminder()
      end if
    else if id = "availableAt" AND m.wasUserShownPurpleCarpetAvailableAtToast = false
      airDatetime = CreateObject("roDateTime")
      airDatetime.FromISO8601String(primaryEventContent.airDateTime)
      airDatetime.toLocalTime()
      formattedTime = localizedTimeString(airDatetime)
      message = getTranslation("available_at_toast_subheading")
      replacements = {
        "time": formattedTime
      }
      heading = getTranslation("available_at_toast_heading", replacements)
      showToast({
        "selfDestructTimer": 5
        "headerText": heading
        "message": message
      })

      m.wasUserShownPurpleCarpetAvailableAtToast = true
    else if id = "goHome"
      restartApp()
    end if
  end if
End Function


Function setOrRemovePurpleCarpetReminder()
  screen = getCurrentScreen()
  if screen <> invalid AND screen.primaryEventContent <> invalid
    primaryEventContent = screen.primaryEventContent
    ' Since we are overriding the content type to purple carpet.
    contentType = m.constants.uapiContentTypes.sportsEvent
    bookmark = getBookmark(primaryEventContent.id)
    didUserSetReminderForEventContent = (bookmark <> invalid)

    if didUserSetReminderForEventContent <> true
      addToQueueReq = m.userDeviceApi.addToQueueReqInfo(primaryEventContent.id, m.constants.ui.contentTypes.sportsEvent, m.constants.userQueueType.remindMe)
      m.makeRequest({
        url: addToQueueReq.url
        requestType: m.constants.reqNames.postToQueue
        options: addToQueueReq.options
        successCallback: onSetReminderSuccess
        silenceCallbackWarnings: true
        responseType: "assocarray"
      })
    else
      removeFromQueueReq = m.userDeviceApi.removeFromQueueReqInfo(bookmark.bookmarkId, primaryEventContent.id, contentType)
      m.makeRequest({
        url: removeFromQueueReq.url
        requestType: m.constants.reqNames.postToQueue
        options: removeFromQueueReq.options
        successCallback: onRemoveReminderSuccess
        silenceCallbackWarnings: true
      })
    end if
  end if
End Function


Function onSetReminderSuccess(_response)
  updateReminderStatusOnScreens(true)
  handleQueueChange()
End Function


Function onRemoveReminderSuccess(_response)
  updateReminderStatusOnScreens(false)
  handleQueueChange()
End Function


Function updateReminderStatusOnScreens(status)
  screen = getCurrentScreen()

  if screen.hasField("didUserSetReminderForEventContent") = true
    screen.didUserSetReminderForEventContent = status
  end if

  ' Since we are using the same callback for both details and home. Making sure home screen is also updated with latest value.
  if isCurrentScreenHomeScreen() = false
    homeScreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
    if homeScreen <> invalid
      homeScreen.didUserSetReminderForEventContent = status
    end if
  end if
End Function


' Starts playback if the event is live or else navigates to details screen.
' @event: contentNode, selected event content node.
' @screen: sgnode, node of the screen from where the item was selected.
' @wasPlayEventInitiatedFromCtaComponent: boolean, Indicates if the play request was initiated from cta.
Function processPlayEvent(event, screen, wasPlayEventInitiatedFromCtaComponent = false)
  currentDatetime = CreateObject("roDateTime")
  airDatetime = CreateObject("roDateTime")
  airDatetime.FromISO8601String(event.airDateTime)
  ' If current time is greater than the air date time that means the program is live and we will start playback if user is signed in.
  if currentDatetime.asSeconds() >= airDatetime.asSeconds() AND (isLoggedInUser() = true OR event.needsLogin = false OR getExternalConfigValueFromGlobal("bypass_registration_gate", false) = true)
    stopLinearVideoContent()
    playbackSource = {
      "srcForAnalytic": m.constants.player.playbackSource.unknown
      "srcForAds": m.constants.player.playbackOrigin.container
      "playbackContainer": m.constants.ui.categoryIds.purpleCarpet
    }
    playLinearVideoContent(event, false, screen.id, false, playbackSource)
  else if wasPlayEventInitiatedFromCtaComponent = false
    ' Reason behind conditional launching of details screen is because we use this helper across home and deeplinking and both rowlist and primary event button list
    ' If the user clicks sign in to watch from home CTA or event details CTA we do not want to land the user in details screen but just refresh the current screen UI.
    ' it will update the button from "signin to watch" to "details"
    showEventDetailScreen(event.id, screen.purpleCarpetContent, event)
  end if
End Function


' @responseContext: assocarray, Will contain to 2 values. purpleCarpetContainer - Purple carpet container content node and screenId - id of the screen that initiated the request.
' @onCompletionCallback: function, callback method that will get triggered once the filtering of purple carpet container data is complete.
Function updateContainerWithProgramInfoFromFoxListing(responseContext, onCompletionCallback)
  ' Storing the callback in m scope since we cannot pass down a method in response context.
  m.onUpdateContainerWithProgramInfoFromFoxListingCompletionCallback = onCompletionCallback

  if m.foxListingEndpointResponse = invalid
    m.makeRequest({
      url: m.constants.urls.foxListingEndpoint
      requestType: m.constants.reqNames.genericWithResponseContext
      successCallback: getProgramInfoFromFoxListingComplete
      errorCallback: getProgramInfoFromFoxListingComplete
      responseType: "assocarray"
      retries: 0
      responseContext: responseContext
    })
  else
    purpleCarpetContainer = filterPurpleCarpetContainerItemsBasedOnListing(m.foxListingEndpointResponse, responseContext.purpleCarpetContainer, responseContext.screenId)

    if isFunction(m.onUpdateContainerWithProgramInfoFromFoxListingCompletionCallback) = true
      m.onUpdateContainerWithProgramInfoFromFoxListingCompletionCallback(purpleCarpetContainer, responseContext.screenId)
    end if

  end if
End Function


Function getProgramInfoFromFoxListingComplete(response)
  if response <> invalid  AND response.responseContext <> invalid
    responseContext = response.responseContext

    purpleCarpetContainer = filterPurpleCarpetContainerItemsBasedOnListing(response.data, responseContext.purpleCarpetContainer, responseContext.screenId)

    if response.data <> invalid
      m.foxListingEndpointResponse = response.data
    end if

    ' Note, m.foxListingEndpointResponse must be set before calling the callback as we use m.foxListingEndpointResponse in the callback.
    if isFunction(m.onUpdateContainerWithProgramInfoFromFoxListingCompletionCallback) = true
      m.onUpdateContainerWithProgramInfoFromFoxListingCompletionCallback(purpleCarpetContainer, responseContext.screenId)
    end if
  end if
End Function


' @listing: array, array of listings items from fox listing api.
' @purpleCarpetContainer: ContentNode, the purple carpet container node. Node structure will be similar to rowlist content node.
' @screenId: string, id of the screen from where the call was made. constants.ui.screenIds.homeScreen or constants.ui.screenIds.eventDetailScreen
Function filterPurpleCarpetContainerItemsBasedOnListing(listing, purpleCarpetContainer, screenId)
  if isNonEmptyArray(listing) = true AND isNode(purpleCarpetContainer) = true
    mappedListings = {}

    ' In case listing api returns multiple listings with same tubi_id, we will follow below logic.
    ' startTime = Math.min(startDate of all listing items with the corresponding tubiId)
    ' endTime = Math.max(endDate of all listing items with the corresponding tubiId)

    for each item in listing
      ' Only using the entry if we have valid tubi id and start and endate.
      asset = item.asset
      if asset <> invalid AND asset.listing <> invalid AND asset.listing.tubi_id <> invalid AND asset.listing.startDate <> invalid AND asset.listing.endDate <> invalid
        if mappedListings[asset.listing.tubi_id] = invalid
          mappedListings[asset.listing.tubi_id] = {
            id: item.id
            startDate: asset.listing.startDate
            endDate: asset.listing.endDate
          }
        else
          mappedItem = mappedListings[asset.listing.tubi_id]

          ' We are picking the oldest start date.
          if compareDates(mappedItem.startDate, asset.listing.startDate) = true
            mappedItem.startDate = asset.listing.startDate
          end if

          ' We are picking the largest future end date.
          if compareDates(mappedItem.endDate, asset.listing.endDate) = false
            mappedItem.endDate = asset.listing.endDate
          end if

          mappedListings[asset.listing.tubi_id] = mappedItem
        end if
      end if
    end for

    eventList = purpleCarpetContainer.getChildren(-1, 0)
    filteredEventList = []

    if isNonEmptyArray(eventList) = true

      for each item in eventList
        processedItem = invalid

        if mappedListings[item.id] <> invalid
          mappedListingItem = mappedListings[item.id]

          if mappedListingItem <> invalid

            ' Checking the event has not ended.
            if isGreaterThanCurrentTime(mappedListingItem.endDate) = true
              processedItem = item
              processedItem.update({
                ' Since across the purple carpet component and info panel and rest of the application we are using airDateTime
                ' overriding the value so that we do not have to pass down the listing data down to every place and we can have one common logic.
                airDatetime: mappedListingItem.startDate

                ' will be passed to player for playback.
                foxContentId: mappedListingItem.id
              }, true)

              ' If the registration by pass is enabled then setting needs login to false.
              if getExternalConfigValueFromGlobal("bypass_registration_gate", false) = true
                processedItem.update({
                  needsLogin: false
                }, true)
              end if
            end if

          end if

        end if

        if processedItem <> invalid
          filteredEventList.push(processedItem)
        end if
      end for

      ' Since before the event we will not have listing api return the actual listing.
      ' But user might still land on event details screen from banner or deeplink or search screen in which we need to use backend info.
      ' If we get match for the tensor and listing then we good to proceed or else only removing for home screen.
      if isNonEmptyArray(filteredEventList) = true
        m.nodeHelpers.removeAllChildren(purpleCarpetContainer)
        purpleCarpetContainer.appendChildren(filteredEventList)
      else if screenId <> m.constants.ui.screenIds.eventDetailScreen
        m.nodeHelpers.removeAllChildren(purpleCarpetContainer)
      end if
    end if
  else if isNode(purpleCarpetContainer) = true AND screenId <> m.constants.ui.screenIds.eventDetailScreen
    ' If listing api fails or returns empty response than removing all the items from the container so that it is hidden.
    m.nodeHelpers.removeAllChildren(purpleCarpetContainer)
  end if

  return purpleCarpetContainer
End Function


' @purpleCarpetContainer: ContentNode, the purple carpet container node. Node structure will be similar to rowlist content node.
' @screenId: string, id of the screen from where the call was made. constants.ui.screenIds.homeScreen or constants.ui.screenIds.eventDetailScreen
Function onHomeScreenContentUpdateComplete(purpleCarpetContainer, screenId)
  tubiLog("HomeScreenHelpers.onHomeScreenContentUpdateComplete")
  homeScreen = getFromScreenCache(screenId)

  if purpleCarpetContainer <> invalid
    updatePurpleCarpetRowContent(homeScreen, purpleCarpetContainer)
  end if

  homeScreen.contentUpdated = true
  '//update the UI after the content has loaded
  setUIBasedOnFocusedContent(homeScreen.contentFocused)

  ' don't set focus on the home screen if side nav has focus, for example
  if homeScreen.isInFocusChain() = true
    homeScreen.setFocus(true)
  end if

  m.sendImpressionEventTimer.control = "stop"
  m.sendImpressionEventTimer.control = "start"
End Function


' @purpleCarpetContainer: ContentNode, the purple carpet container node. Node structure will be similar to rowlist content node.
' @screenId: string, id of the screen from where the call was made. constants.ui.screenIds.homeScreen or constants.ui.screenIds.eventDetailScreen
Function refreshPurpleCarpetContainer(purpleCarpetContainer, screenId)
  screen = getFromScreenCache(screenId)
  updatePurpleCarpetRowContent(screen, purpleCarpetContainer)
End Function


' @callback: function, callback to be triggered once the purple carpet container data is enriched with data from listing endpoint and games that got ended are removed.
Function getFoxListingItemsAndRefreshPurpleCarpetContainerData(callback = refreshPurpleCarpetContainer)
  if isNode(m.purpleCarpetContainerContentNode) = true

    ' Setting invalid to the field forces a re-fetch of the listing API in updateContainerWithProgramInfoFromFoxListing.
    m.foxListingEndpointResponse = invalid

    contentNode = m.purpleCarpetContainerContentNode.clone(true)
    context = {
      purpleCarpetContainer: contentNode
      screenId: m.constants.ui.screenIds.homeScreen
    }
    updateContainerWithProgramInfoFromFoxListing(context, callback)
  end if
End Function
