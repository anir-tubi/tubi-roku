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
    updateInlineVideoMetadataOverlayVisibility()

    homeScreen.isVideoPreviewOn = m.pub_serverPersistentData.isVideoPreviewOn
    m.pubSub.subscribe("pub_serverPersistentData.isVideoPreviewOn", homeScreen, "isVideoPreviewOn")
    homeScreen.kidsMode = isKidsUIOn()

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
    homeScreen.observeFieldScoped("stopLinearVideoPlayer", "onStopLinearVideoPlayer")
    homeScreen.observeFieldScoped("sponsoredRowFocused", "onHomeScreenSponsoredRowFocused")
    homeScreen.observeFieldScoped("columnFocused", "onColumnFocusChanged")
    homeScreen.observeFieldScoped("currFocusRow", "onHomeScreenRowFocusChanged")
    homeScreen.observeFieldScoped("pauseVideoPreview", "onPauseVideoPreview")
    homeScreen.observeFieldScoped("loadCategoryForIds", "onLoadCategoryForIds")
    homeScreen.observeFieldScoped("eventCtaListItemSelected", "onEventCtaListItemSelected")
    homeScreen.observeFieldScoped("componentInteractionInfo", "onComponentInteractionInfoChange")
    homeScreen.observeFieldScoped("featuredRowCurrFocusColumn", "onFeaturedRowCurrFocusColumnChange")
    homeScreen.observeFieldScoped("featuredListCurrFocusRow", "onFeaturedRowCurrFocusRowChange")
    homeScreen.observeFieldScoped("featuredRowFocusedItem", "onFeaturedRowFocusedItemChange")
    homeScreen.observeFieldScoped("featuredListHasFocus", "onFeaturedListHasFocusChange")
    homeScreen.observeFieldScoped("currCategoryId", "onCurrCategoryIdChange")
    homeScreen.observeFieldScoped("currentFocusedItemBoundingRect", "onFeaturedRowListTranslationChange")
    homeScreen.observeFieldScoped("featuredRowListTranslation", "onFeaturedRowListTranslationChange")
    homeScreen.observeFieldScoped("featuredListScrollDirection", "onFeaturedListScrollDirectionChange")
    homeScreen.observeFieldScoped("featuredListScrollingStatus", "onFeaturedListScrollingStatusChange")

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
    updateInlineVideoMetadataOverlayVisibility()
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
    if isKidsUIOn() = false AND m.isUserInVideoTilesExperiment = true AND isNode(response) = true AND response.getChildCount() > 0 AND homeScreen.contentMode = m.constants.ui.contentMode.homescreen
      updateCategoryGridWithFeaturedList(response, homeScreen)
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
    ' For video tiles experiment, we need to update the featured row content.
    ' Since all the rows will be using new video tiles format.
    if m.isUserInVideoTilesExperiment = true
      content = homeScreen.featuredRowContent
    else
      content = homeScreen.content
    end if

    if content <> invalid
      newCategory = invalid
      oldCategory = invalid

      if type(response) = "roSGNode"
        if response.getChildCount() > 0
          newCategory = response
        end if

        oldCategory = content.findNode(response.id)
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
        content.replaceChild(newCategory, m.NodeHelpers.getChildIndex(content, oldCategory))
        homeScreen.repopulateContent = true
      else if newCategory <> invalid AND oldCategory = invalid
        'add new category
        'if new category is history, put it one before queue, or if queue doesn't exist put it in 2nd position
        'if new category is queue put it one after history, or if history doesn't exist, put it in 2nd position
        if newCategory.id = m.constants.ui.categoryIds.queue OR newCategory.id = m.constants.ui.categoryIds.history then
          homeScreen.rowAdded = newCategory.id

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
        content.removeChild(oldCategory)

        homeScreen.repopulateContent = true '//In case the rows are of different heights, tell homescreen to refresh to display rows correctly
      else if newCategory = invalid AND oldCategory = invalid
        'do nothing
      end if
    end if

    '//Stop loading of homescreen which will refresh the screen's content
    homeScreen.isLoading = false
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

  fetchHomescreen(homeScreen, true)
End Function


Function fetchHomeScreen(homeScreen, useCache = false)
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

    if homeScreen <> invalid AND homeScreen.content <> invalid AND useCache = true AND homeScreen.content.lastModified <> invalid
      headers["If-Modified-Since"] = homeScreen.content.lastModified
    end if

    options.params = params
    options.headers = headers
    isLinearBlock = isLinearBlocked()
    homeScreenReqInfo = m.CmsApi.createHomeScreenReqInfo(isKidsMode, options, isLinearBlock)
    m.makeRequest({
      url: homeScreenReqInfo.url
      requestType: reqName
      options: homeScreenReqInfo.options
      successCallback: successHandler
      errorCallback: errorHandler
      responseType: "node"
      isSignedInUser: isLoggedInUser()
      isLinearBlock: isLinearBlock
      uiMode: m.uiMode
    })

    if useCache = false
      homeScreen.resetContentAreaValues = true
      setHomeScreenLoading(homeScreen)
    end if
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

    ads = rawResponse.ads
    isSkinAdsAvailable = isKidsUIOn() = false AND ads <> invalid
    if isSkinAdsAvailable = true
      updateSkinAdRowContent(homeScreen, ads)
    else
      updateSkinAdRowContent(homeScreen, invalid)
    end if

    homeScreen.personalizationId = rawResponse.personalizationId
    homeScreen.shouldTrackViewableImpressionEvent = (isUserInAdultsMode() = true AND isKidsUIOn() = false)

    if isKidsUIOn() = false AND screenID = m.constants.ui.screenIds.homeScreen
      ' Below logic is for the control reorder containers experiment.
      ' For now we are using for swapping featured row and recommended row.
      experiment = getExperimentResource("roku_home_screen_redesign", "roku_home_screen_redesign_v_1_3", true)
      isUserInControlReOrderContainersExperiment = (experiment <> invalid AND experiment.design_type = "controlReOrderContainers")
      if isUserInControlReOrderContainersExperiment = true
        containerToBeReOrdered = m.nodeHelpers.getChildById(rawResponse, experiment.container_id)
        rawResponse.removeChild(containerToBeReOrdered)
        rawResponse.insertChild(containerToBeReOrdered, 0)
      end if

      if m.isUserInVideoTilesExperiment = true AND isNode(rawResponse) = true AND rawResponse.getChildCount() > 0
        ' Only show the video tile overlay group if the screen is the home screen and the skin ads are not available.
        ' This is needed because we refresh home screen behind the scenes during parent controls change.
        screen = getCurrentScreen()
        m.videoTileOverlayGroup.visible = (isSkinAdsAvailable = false AND screen <> invalid AND screen.id = m.constants.ui.screenIds.homeScreen)
        updateCategoryGridWithFeaturedList(rawResponse, homeScreen)
        rawResponse = invalid
      end if
    else
      m.videoTileOverlayGroup.visible = false
    end if

    homeScreen.content = rawResponse

    onHomeScreenContentUpdateComplete(homeScreen.id)

    getExperimentResource("roku_no_change_experiment", "roku_no_change_experiment_v3", true)

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
  screen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
  if response.httpStatusCode <> 304 OR screen.content = invalid
    handleHomeScreenErrorResponse(m.constants.ui.screenIds.homeScreen, response)
  else if screen.content <> invalid AND screen.content.validDuration <> invalid
    ' Updating the valid_duration.
    screen.content.validUntil = Uptime(0) + screen.content.validDuration
  end if
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
Function onHomeScreenSponsoredRowFocused(msg)
  isSponsoredRowFocused = msg.getData()
  homeScreen = msg.getRoSGNode()
  currentScreen = getCurrentScreen()
  if isSponsoredRowFocused = true AND homeScreen <> invalid AND currentScreen <> invalid AND currentScreen.isSameNode(homeScreen)
    row = homeScreen.rowFocused
    if row <> invalid
      manageHomeScreenSponsorPixels(row)
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


'//when a new column of the row list begins to gain partial focus during a horizontal scroll, then do something
Function onColumnFocusChanged(msg)
  tubiLog("HomeScreenHelpers.onColumnFocusChanged")
  if isLinearPlayerLoadingOrPlaying() = true
    ' as the row list is scrolling, if the the linear video player is playing or loading, then make sure the linear video player is stopped.
    stopAndHideLinearVideoPlayer()
  end if

  columnFocused = msg.getData()
  homeScreen = msg.getRoSGNode()
  rowFocused = homeScreen.currFocusRow
  if isNumber(rowFocused) = true AND homeScreen.content <> invalid
    category = homeScreen.content.getChild(rowFocused)
    makeContainerRequest(category, columnFocused, homeScreen)
  end if
End Function


Function onContainerMoreItemsSuccess(response)
  homeScreen = getCurrentScreen()
  if homeScreen <> invalid AND homeScreen.content <> invalid AND isNode(response) = true AND homeScreen.currFocusRow <> invalid
    rowFocused = homeScreen.currFocusRow
    appendContentToCategory(response, homeScreen.content, rowFocused)
  end if
End Function


Function onVideoTilesListMoreItemsSuccess(response)
  homeScreen = getCurrentScreen()
  if homeScreen <> invalid AND homeScreen.featuredRowContent <> invalid AND isNode(response) = true AND homeScreen.featuredListCurrFocusRow <> invalid
    rowFocused = homeScreen.featuredListCurrFocusRow
    appendContentToCategory(response, homeScreen.featuredRowContent, rowFocused)
  end if
End Function


' Make a request to the server to get more items for a category.
' @category, roSGNode, the category node to make the request for.
' @columnFocused, integer, the column index of the category that is focused.
' @homeScreen, roSGNode, the home screen node.
' @successCallback, function, the function to call when the request is successful.
Function makeContainerRequest(category, columnFocused, homeScreen, successCallback = onContainerMoreItemsSuccess)
  ' We will start fetching more items when the user has scrolled 3 items.
  ' This is to give enough lead time for us to fetch more items before user reaches the end of the list.
  firstBatchLimit = 2
  
  if isNode(category) = true and category.paginationInfo <> invalid and columnFocused >= firstBatchLimit
    cursor = category.paginationInfo.cursor
    hasMoreContent = category.paginationInfo.hasMoreContent
    if hasMoreContent = true and columnFocused >= (cursor - 10) and category.state <> "containerPaginationRequestPending"
      isKidsMode = shouldKidsModeBeSentToServer()
      isSignedInUser = isLoggedInUser()
      isLinearBlock = isLinearBlocked()
      categoryReqInfo = m.cmsApi.createGetContainerContentsReqInfo(category, homeScreen, isKidsMode, isSignedInUser, m.uiMode, false, isLinearBlock)
      if categoryReqInfo <> invalid
        category.state = "containerPaginationRequestPending"
        m.makeRequest({
          url: categoryReqInfo.url
          requestType: categoryReqInfo.requestType
          options: categoryReqInfo.options
          successCallback: successCallback
          errorCallback: onContainerMoreItemsError
          silenceCallbackWarnings: true
          responseType: "node"
          isSignedInUser: isSignedInUser
          isLinearBlock: isLinearBlock
          uiMode: m.uiMode
          categoryId: category.id
        })
      end if
    end if
  end if
End Function


Function onContainerMoreItemsError(error)
  ' Adding a logic to account for any failures in the container pagination request.
  homeScreen = getCurrentScreen()
  if homeScreen <> invalid
    if m.isUserInVideoTilesExperiment = true
      content = homeScreen.featuredRowContent
    else
      content = homeScreen.content
    end if
    if content <> invalid
      category = m.NodeHelpers.getChildById(content, error.categoryId)
      if category <> invalid
        ' Reset the state of the category to none so that we can retry the request as the user scrolls through the list again or re-focuses the row list.
        category.state = "none"
      end if
    end if
  end if
End Function


' Append the content to the individual category container.
' @response, roSGNode, the response from the server.
' @contentNode, roSGNode, the content node to append the content to.
' @rowFocused, integer, the row index of the category that is focused.
Function appendContentToCategory(response, contentNode, rowFocused)
  category = m.NodeHelpers.getChildById(contentNode, response.id)
  items = response.getChildren(-1, 0)
  if isNonEmptyArray(items) = true AND category <> invalid
    fullJson = ParseJson(category.json)
    newJson = ParseJson(response.json)
    if fullJson <> invalid AND newJson <> invalid
      childUICustomization = {}
      if isAA(category.child_ui_customization) = true
        childUICustomization = category.child_ui_customization
        if isAA(response.child_ui_customization) = true
          childUICustomization.append(response.child_ui_customization)
        end if
      end if

      fullJson.append(newJson)
      screen = getCurrentScreen()
      screen.containerAppendMoreTilesStatus = "start"

      category.paginationInfo = response.paginationInfo
      category.child_ui_customization = childUICustomization
      category.json = FormatJson(fullJson)
      category.state = response.state
      category.appendChildren(items)
      screen.containerAppendMoreTilesStatus = "complete"
    end if
  end if
End Function


Function onHomeScreenRowFocusChanged()
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
        if isLinearPlayerLoadingOrPlaying() = true
          stopAndHideLinearVideoPlayer()
        end if
      end if

      if currentScreen.isSameNode(homeScreen) = true AND currentScreen.isInFocusChain() = true 'if there are any modals over home screen or focus has been lost to side nav
        componentTrackingInfo = getCategoryComponentTrackingInfo(currentScreen)
        setVideoPreviewAfterFocus(focusedContent, currentScreen.trackingPageInfo, componentTrackingInfo)
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
Function manageHomeScreenSponsorPixels(rowFocused)
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
  if contentType = m.constants.uapiContentTypes.channel
    stopVideoPreview()
    contentMode = ""
    if homeScreen.contentMode <> m.constants.ui.contentMode.homescreen
      contentMode = homeScreen.contentMode
    end if
    showCategoryDetailsScreen(content, true, contentMode)
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
  if contentType = m.constants.uapiContentTypes.channel
    contentMode = ""
    if screen.contentMode <> m.constants.ui.contentMode.homescreen
      contentMode = screen.contentMode
    end if
    showCategoryDetailsScreen(content, true, contentMode)
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
  isLinearBlock = isLinearBlocked()

  if homeScreen.contentMode = m.constants.ui.contentMode.homescreen
    contentMode = ""
  else
    contentMode = homeScreen.contentMode
  end if

  batchRequests = m.cmsApi.createHomeScreenBatchReqInfoForContainers(categoryIDs, contentMode, isKidsMode, isSignedInUser,"standard","", isLinearBlock)

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
    '//If this is a valid skinAds wrapper, then check if it is part of the experiment.
    '// Fire the experiment's exposure event here, regardless.
    if m.constants.settings.disableSkinAds = false AND getExperimentResource("ads_tubi_skins", "ads_tubi_skins_v1", true).enabled = true
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
  else
    homeScreen.skinAdContent = invalid
    homeScreen.skinAdContentUpdated = true
  end if

End Function


' @screenId: string, id of the screen from where the call was made. constants.ui.screenIds.homeScreen or constants.ui.screenIds.eventDetailScreen
Function onHomeScreenContentUpdateComplete(screenId)
  homeScreen = getFromScreenCache(screenId)

  homeScreen.contentUpdated = true
  '//update the UI after the content has loaded
  setUIBasedOnFocusedContent(homeScreen.contentFocused)

  ' don't set focus on the home screen if side nav has focus, for example
  if homeScreen.isInFocusChain() = true
    homeScreen.setFocus(true)
  end if

  startClientImpressionTimer()
End Function


' Fade in and out the focus indicator when the user is scrolling through the rows.
' Provides similar better as row list fadeFocusWhileScrolling experience.
' @param msg: roSGNode, the message object.
Function onFeaturedRowCurrFocusRowChange(msg)
  currFocusRow = msg.getData()
  screen = msg.getRoSGNode()
  m.inlineVideoMetadataOverlay.skipAnimation = true
  ' Avoid the focus indicator from being shown when the row is scrolling.
  ' Start fade in when the user is half way through the scroll.
  if currFocusRow = CInt(currFocusRow)
    fade(m.inlinePreviewFocusIndicator, "in", 0.1)
  else if m.inlinePreviewFocusIndicator.opacity = 1
    fade(m.inlinePreviewFocusIndicator, "out", 0.1)
  end if
  pauseVideoPreviewAndShowPoster()
  ' So that we call at the end of transition.
  if currFocusRow = Fix(currFocusRow)
    checkAndSetSponsorshipBackground(screen.featuredRowContent, currFocusRow)
  end if
End Function


' Triggers a callback when list has started and stopped scrolling through the rows.
' @param msg: roSGNode, the message object.
Function onFeaturedListScrollingStatusChange(msg)
  scrollingStatus = msg.getData()
  ' Below logic helps to avoid us from updating the in transit video metadata overlay when the user is scrolling up or down.
  if scrollingStatus = false
    updateInTransitVideoMetadataOverlay()
    if isVideoPreviewPlaying() = true
      stopVideoPreview()
    end if
  end if
End Function


' Updates the in transit video metadata overlay when the user is scrolling up or down.
Function updateInTransitVideoMetadataOverlay()
  screen = getCurrentScreen()
  ' Avoid the focus indicator from being shown when the row is scrolling.
  if screen <> invalid AND isNode(screen.featuredRowContent) = true
    currFocusRow = screen.featuredListCurrFocusRow
    category = screen.featuredRowContent.getChild(currFocusRow)
    columnFocused = 0
    if category <> invalid AND isNumber(category.focusIndex) = true AND category.focusIndex > 0
      columnFocused = category.focusIndex
    end if
    updateVideoTileOnFocusChange(currFocusRow, columnFocused, screen)
  end if
End Function


' Triggers a callback when the user is scrolling through the columns of the row.
Function onFeaturedRowCurrFocusColumnChange()
  m.inlineVideoMetadataOverlay.skipAnimation = false
  m.videoPreviewDebounce.control = "stop"
  screen = getCurrentScreen()
  if screen <> invalid
    columnFocused = screen.featuredRowCurrFocusColumn
    if isNumber(columnFocused) = false OR columnFocused < 0
      columnFocused = 0
    end if

    rowFocused = screen.featuredListCurrFocusRow
    updateVideoTileOnFocusChange(rowFocused, columnFocused, screen)

    ' Calling lazy load for the next batch of items.
    if isNumber(columnFocused) = true AND isNumber(rowFocused) = true AND screen.featuredRowContent <> invalid
      category = screen.featuredRowContent.getChild(rowFocused)
      makeContainerRequest(category, columnFocused, screen, onVideoTilesListMoreItemsSuccess)
    end if
  end if
End Function


' Updates the video tile metadata overlay on focus change.
' @param rowFocused: int, the row index of the focused item.
' @param columnFocused: int, the column index of the focused item.
' @param screen: roSGNode, the screen node.
Function updateVideoTileOnFocusChange(rowFocused, columnFocused, screen)
  ' Only process if the screen is the home screen.
  ' Since all others screens are using topRight background variant vs home screen will use full screen background.
  if isCurrentScreenHomeScreen() = true
    displayDefaultBackground()
  end if

  if screen <> invalid AND screen.featuredRowContent <> invalid
    pauseVideoPreviewAndShowPoster()
    m.videoPreviewDebounce.control = "start"
    setInlineVideoMetadataOverlay(screen.featuredRowContent, columnFocused, rowFocused)
  end if
End Function


Function pauseVideoPreviewAndShowPoster()
 ' If the video preview is playing, we will pause it and show the poster.
 ' This helps with smoother scrolling experience.
  if m.inlineVideoPreviewPlayerContainer.opacity = 1
    videoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
    if videoPlayer <> invalid
      videoPlayer.visible = false
    end if
    m.videoPreviewPlayer.visible = false
    if getVideoPreviewState() = "playing"
      ' Gives better scrolling experience if we pause the video preview.
      ' We are calling stopVideoPreview once we are done with scrolling.
      ' We are pausing to avoid audio from playing in the background when user is scrolling.
      pauseVideoPreview()
    end if
  end if
  isLinearPlayerPlaying = isLinearPlayerLoadingOrPlaying()
  shouldForceInline = (isLinearPlayerPlaying = true)
  updatePreviewPlayerToInlineView(shouldForceInline)
  if isLinearPlayerPlaying = true
    stopAndHideLinearVideoPlayer()
  end if
  m.inlineVideoPreviewPlayerContainer.opacity = 1
End Function


' Starts the inline preview when the featured row list has focus.
Function startFeaturedInlinePreview()
  screen = getCurrentScreen()
  if isCurrentScreenHomeScreen() = true AND screen.featuredListHasFocus = true
    stopAndHideLinearVideoPlayer()
    if screen.featuredRowContent <> invalid AND screen.featuredRowFocusedItem <> invalid
      content = screen.featuredRowFocusedItem

      if content.type = m.constants.ui.categoryTypes.linear AND m.constants.deviceInfo.isAutoPlayEnabled = true
        playLinearInlineGridView(content, screen)
      else
        componentTrackingInfo = getCategoryComponentTrackingInfo(screen)
        setVideoPreviewAfterFocus(content, screen.trackingPageInfo, componentTrackingInfo)
      end if
    end if
  end if
End Function


' Sets the inline video metadata overlay.
' @param featuredRowContent: roSGNode, the featured row content.
' @param columnFocused: int, the column index of the focused item.
' @param rowFocused: int, the row index of the focused item.
Function setInlineVideoMetadataOverlay(featuredRowContent, columnFocused, rowFocused)
  if (isNumber(columnFocused) = false OR columnFocused < 0)
    columnFocused = 0
  end if
  
  if (isNumber(rowFocused) = false OR rowFocused < 0)
    rowFocused = 0
  end if

  columnFocused = CInt(columnFocused)
  rowFocused = CInt(rowFocused)

  currCategory = featuredRowContent.getChild(rowFocused)
  if currCategory <> invalid
    itemContent = currCategory.getChild(columnFocused)
    m.inlineVideoMetadataOverlay.itemContent = itemContent
    m.inlineVideoGridTitleLogo.itemContent = itemContent  
  end if

  ' Predicting the next row to be focused based on current scroll direction.
  ' We will reset the metadata if user changes the scroll direction inside onFeaturedListScrollDirectionChange.
  screen = getCurrentScreen()
  nextRow = rowFocused
  if screen.featuredListScrollDirection = "down"
    nextRow = rowFocused + 1
  else
    nextRow = rowFocused - 1
  end if

  nextCategory = featuredRowContent.getChild(nextRow)
  if nextCategory <> invalid
    ' Accessing column index from the category node since we preserve user previous focus index.
    columnFocused = nextCategory.focusIndex
    if isNumber(columnFocused) = false OR columnFocused < 0
      columnFocused = 0
    end if
    isNonVideoTile = arrayIncludes(m.constants.ui.nonVideoTileGridItemTypes, nextCategory.gridItemType)
    m.inTransitInlineVideoMetadataOverlay.visible = (isNonVideoTile = false)
    inTransitItemContent = nextCategory.getChild(columnFocused)
    m.inTransitInlineVideoMetadataOverlay.itemContent = inTransitItemContent
  end if
End Function


Function playLinearInlineGridView(content, screen)
  screen = getCurrentScreen()

  if isCurrentScreenHomeScreen() = true
    stopLinearVideoContent()
    playbackSource = {
      "srcForAnalytic": m.constants.player.playbackSource.unknown
      "srcForAds": m.constants.player.playbackOrigin.container
      "playbackContainer": screen.currCategoryId
    }
    playLinearVideoContent(content, true, screen.id, true, playbackSource)
  end if
End Function


Function onFeaturedListHasFocusChange(msg)
  hasFeaturedListFocus = msg.getData()
  screen = msg.getRoSGNode()
  m.videoTileOverlayGroup.visible = (isCurrentScreenHomeScreen() = true AND isKidsUIOn() = false AND screen.lastFocusedList = "featuredRowList")
  content = screen.featuredRowFocusedItem
  previewContent = m.videoPreviewPlayer.content
  m.videoPreviewPlayer.visible = (isCurrentScreenHomeScreen() = false OR (content <> invalid AND previewContent <> invalid AND content.id = previewContent.id))
  if hasFeaturedListFocus = true
    displayDefaultBackground()
    ' Resetting the content focused when the featured row list receives focus.
    if screen.hasField("contentFocused") = true
      screen.contentFocused = invalid
    end if
    previewState = getVideoPreviewStateForThisContent(content)
    m.inlinePreviewFocusIndicator.visible = true
    if previewState = "paused"
      resumeVideoPreview()
    else if previewState = "playing"
      displayDefaultBackground()
      updatePreviewPlayerToInlineView()
    end if
    setUIBasedOnFocusedContent(content)
  else if isCurrentScreenHomeScreen() = true
    m.videoPreviewPlayer.visible = false
    m.inlinePreviewFocusIndicator.visible = false
    if screen.lastFocusedList = "featuredRowList"
      pauseVideoPreview()
    end if
  else
    updatePreviewPlayerToCondensedView()
  end if
End Function


Function updateCategoryGridWithFeaturedList(response, screen)
  screen.featuredRowContent = response

  if screen.skinAdContent <> invalid OR (screen.featuredListHasFocus = false AND isKidsUIOn() = false)
    currentScreen = getCurrentScreen()
    isCurrScreenHomeScreen = currentScreen <> invalid AND currentScreen.id = m.constants.ui.screenIds.homeScreen
    if isCurrScreenHomeScreen = true AND screen.isInFocusChain() = false
      m.inlineVideoPreviewPlayerContainer.opacity = 1
    end if
    setInlineVideoMetadataOverlay(response, 0 , 0)
    m.inlineVideoMetadataOverlay.showContentPoster = true

    if screen.skinAdContent <> invalid AND screen.isInFocusChain() = false
      m.inlineVideoPreviewPlayerContainer.translation = [m.inlineVideoPreviewPlayerContainer.translation[0], 945.5]
    end if
  end if
End Function


Function onFeaturedRowFocusedItemChange(msg)
  focusedItem = msg.getData()
  ' Only process if the focused item is a video tile.
  if focusedItem <> invalid AND arrayIncludes(m.constants.ui.nonVideoTileGridItemTypes, focusedItem.gridItemType) = false
    m.inlineVideoPreviewPlayerContainer.visible = true
    ' In certain cases where the focused item is not the same as the itemContent, we need to update the itemContent.
    ' For ex: One instance is Continue watching row getting updated with the new item or existing item been deleted.
    if isNode(m.inlineVideoMetadataOverlay.itemContent) = true AND focusedItem.title <> m.inlineVideoMetadataOverlay.itemContent.title
      updateInTransitVideoMetadataOverlay()
    end if
    updatePreviewPlayerToInlineView()

    ' If VideoPreview is on and we have not started the debounce, we will start it.
    ' This is needed in case where for initial load and refresh cases where columnFocusChange is not triggered.
    if isVideoPreviewOn() = true AND m.videoPreviewDebounce.control = "stop"
      m.videoPreviewDebounce.control = "start"
    end if
  else
    m.inlineVideoPreviewPlayerContainer.visible = false
  end if
End Function


Function onCurrCategoryIdChange()
  updateInlineVideoMetadataOverlayVisibility(0.3)
End Function


Function updateInlineVideoMetadataOverlayVisibility(duration = 0)
  screen = getCurrentScreen()
  if screen <> invalid
    isHomeScreen = (screen <> invalid AND screen.id = m.constants.ui.screenIds.homeScreen)
    m.videoTileOverlayGroup.visible = isHomeScreen
    if m.isUserInVideoTilesExperiment = true AND isKidsUIOn() = false
      if isHomeScreen AND screen.featuredRowContent <> invalid
        content = screen.featuredRowFocusedItem
        if getVideoPreviewStateForThisContent(content) <> "playing"
          m.inlineVideoMetadataOverlay.showContentPoster = true
          ' Gives better scrolling experience if we pause the video preview.
          ' We are calling stopVideoPreview once we are done with scrolling.
          pauseVideoPreview()
        end if
      else
        ' Below logic handles displaying the large preview poster when skin ad is focused and during navigating back from ad player.
        if screen <> invalid AND screen.lastFocusedList <> "skinAdRow"
          fade(m.inlineVideoPreviewPlayerContainer, "out", duration, 0.1)
        else
          fade(m.inlineVideoPreviewPlayerContainer, "in", duration)
        end if
      end if
    else
      m.inlineVideoPreviewPlayerContainer.opacity = 0
    end if
  end if
End Function


Function onFeaturedRowListTranslationChange(msg)
  screen = msg.getRoSGNode()
  translation = screen.featuredRowListTranslation
  if translation <> invalid
    rectY = 52
    if screen.currentFocusedItemBoundingRect <> invalid AND screen.currentFocusedItemBoundingRect.y <> 0
      rectY = screen.currentFocusedItemBoundingRect.y
    end if

    isVerticalScroll = arrayIncludes(["down", "up"], screen.featuredListScrollDirection)

    if isNumber(rectY) = true
      inlineVideoPreviewPlayerContainer = m.inlineVideoPreviewPlayerContainer.translation
      ' Below logic is required to avoid having the flickering effect when we update the translation of the focused expanded video tile once the scroll stops.
      if isVerticalScroll = true AND screen.featuredListScrollingStatus = false
        m.inlineVideoPreviewPlayerContainer.opacity = 0
      end if
      m.inlineVideoPreviewPlayerContainer.translation = [inlineVideoPreviewPlayerContainer[0], translation[1] + rectY]
      m.inlineVideoPreviewPlayerContainer.opacity = 1
    end if

    ' For Performance optimization reasons not processing it unless user is scrolling vertically.
    if isVerticalScroll = true AND screen.inTransitCurrentFocusedItemBoundingRect <> invalid AND screen.inTransitCurrentFocusedItemBoundingRect.y <> 0
      inTransitRectY = screen.inTransitCurrentFocusedItemBoundingRect.y
      ' As soon as the scrolling stops we will hide the in transit video metadata overlay.
      if screen.featuredListScrollingStatus = true
        m.inTransitInlineVideoMetadataOverlay.opacity = 1
        m.inTransitInlineVideoMetadataOverlay.translation = [165, translation[1] + inTransitRectY + 5]
      else
        m.inTransitInlineVideoMetadataOverlay.opacity = 0
      end if
    end if
  end if
End Function


Function getCategoryComponentTrackingInfo(screen)
  componentTrackingInfo = invalid
  if screen <> invalid AND screen.trackingComponentInfo <> invalid AND screen.trackingPageInfo <> invalid
    componentTrackingInfo = screen.trackingComponentInfo
    pageInfo = screen.trackingPageInfo
    if isNonEmptyString(pageInfo.pageType) = true AND isNonEmptyString(componentTrackingInfo.componentType) = true
      componentTrackingInfo = {
        pageOneof: m.Tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
        componentOneof: m.Tracking.getAnalyticsComponent(componentTrackingInfo.componentType, componentTrackingInfo.componentValues)
      }
    end if
  end if

  return componentTrackingInfo
End Function


' Triggers callback when user switches the scroll direction.
' This ensure we update the in transit video metadata overlay when the user is switching direction.
' Below when user is scrolling down we use next container poster vs previous container poster.
' @param msg: roSGNode, the message object.
Function onFeaturedListScrollDirectionChange(msg)
  scrollDirection = msg.getData()
  if scrollDirection = "down" OR scrollDirection = "up"
    updateInTransitVideoMetadataOverlay()
  end if
End Function


' This function is part of roku_linear_no_show_v2 experiment. Remove it after experiment over.  Exp will be never graduated. 
Function isLinearBlocked()
  'only apply to US new users and only to users under the experiment. 
  if UCase(m.constants.deviceInfo.countryCode) = "US" AND getExperimentResult("roku_linear_no_show", "roku_linear_no_show_v2") <> invalid
    if isNewUser() = true
      'all newUsers are under linear holdout experiment
      if getExperimentResource("roku_linear_no_show", "roku_linear_no_show_v2", true).enabled = true ' if experiment is not running there wont be any exposure events.
        saveServerPersistentData({
          "isLinearBlocked": "linearblocked"
        }, "device")
        return true
      else   ' isLinearBlocked only if experiment is running in popper.
        saveServerPersistentData({
          "isLinearBlocked": "linearshow"
        }, "device")
        return false
      end if
    else
      if m.pub_serverPersistentData.isLinearBlocked = "linearblocked"

        getExperimentResource("roku_linear_no_show", "roku_linear_no_show_v2", true)
        return true
      else if m.pub_serverPersistentData.isLinearBlocked = "linearshow"
        getExperimentResource("roku_linear_no_show", "roku_linear_no_show_v2", true)
        return false
      else ' returning user never was in experiment
        return false
      end if
    end if
  end if

  return false 'default case for non us users, not experiment started etc

End Function


' Checks if the row is sponsored and sets the sponsorship background.
' @param content: roSGNode, the content of the featured list.
' @param rowIndex: int, the index of the row.
Function checkAndSetSponsorshipBackground(content, rowIndex)
  if content <> invalid
    category = content.getChild(rowIndex)
    background = ""

    if category <> invalid AND category.sponsorImages <> invalid AND category.sponsorImages.pixels <> invalid AND category.sponsorImages.pixels.homescreen <> invalid
      ' Low end devices we only support brand color.
      if m.constants.deviceInfo.limitedUi = false
        background = category.sponsorImages.brandBackground
      else
        background = category.sponsorImages.brandColor
      end if
      manageHomeScreenSponsorPixels(category)
    end if
    setSponsorshipBackground(background)
  end if
End Function
