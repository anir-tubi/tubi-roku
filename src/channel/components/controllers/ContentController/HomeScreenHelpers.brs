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
    homeScreen.observeFieldScoped("pauseVideoPreview", "onPauseVideoPreview")
    homeScreen.observeFieldScoped("loadCategoryForIds", "onLoadCategoryForIds")
    homeScreen.observeFieldScoped("eventCtaListItemSelected", "onEventCtaListItemSelected")
    homeScreen.observeFieldScoped("componentInteractionInfo", "onComponentInteractionInfoChange")
    homeScreen.observeFieldScoped("featuredRowCurrFocusColumn", "onFeaturedRowCurrFocusColumnChange")
    homeScreen.observeFieldScoped("featuredRowFocusedItem", "onFeaturedRowFocusedItemChange")
    homeScreen.observeFieldScoped("featuredListHasFocus", "onFeaturedListHasFocusChange")
    homeScreen.observeFieldScoped("currCategoryId", "onCurrCategoryIdChange")
    homeScreen.observeFieldScoped("currentFocusedItemBoundingRect", "onFeaturedRowListTranslationChange")
    homeScreen.observeFieldScoped("featuredRowListTranslation", "onFeaturedRowListTranslationChange")

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
    experiment = getExperimentResource("roku_home_screen_redesign", "roku_home_screen_redesign_v3", false)
    if isKidsUIOn() = false AND experiment.design_type = "withDescriptionPortraitSmall" AND isNode(response) = true AND response.getChildCount() > 0 AND homeScreen.contentMode = m.constants.ui.contentMode.homescreen
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

    initialBlockSize = m.constants.performance.categoryGridList.initialBlockSize

    if initialBlockSize > 0 AND getExperimentResource("roku_home_screen_container_items_lazy_load", "roku_home_screen_container_items_lazy_load_v1", true).enabled = true
      initialBlockSize = 7
    end if

    params[limitParamName] = initialBlockSize

    if homeScreen <> invalid AND homeScreen.content <> invalid AND useCache = true AND homeScreen.content.lastModified <> invalid AND getExperimentResource("roku_home_screen_if_modified_since", "roku_home_screen_if_modified_since_v1", false).enabled = true
      headers["If-Modified-Since"] = homeScreen.content.lastModified
    end if

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
    if isKidsUIOn() = false AND ads <> invalid
      updateSkinAdRowContent(homeScreen, ads)
    end if

    homeScreen.personalizationId = rawResponse.personalizationId
    homeScreen.shouldTrackViewableImpressionEvent = (isUserInAdultsMode() = true AND isKidsUIOn() = false)

    experiment = getExperimentResource("roku_home_screen_redesign", "roku_home_screen_redesign_v3", true)
    containerRow = m.nodeHelpers.getChildById(rawResponse, experiment.container_id)
    redesignRow = containerRow

    rawResponse.removeChild(containerRow)
    rawResponse.insertChild(redesignRow, 0)

    if isKidsUIOn() = false AND (experiment.design_type = "withDescriptionPortraitSmall") AND isNode(rawResponse) = true AND rawResponse.getChildCount() > 0 AND homeScreen.id = m.constants.ui.screenIds.homescreen
      updateCategoryGridWithFeaturedList(rawResponse, homeScreen)
    end if

    homeScreen.content = rawResponse

    onHomeScreenContentUpdateComplete(homeScreen.id)
    
    getExperimentResource("roku_home_screen_container_items_lazy_load", "roku_home_screen_container_items_lazy_load_v1", true)

    getExperimentResource("roku_no_change_experiment", "roku_no_change_experiment_v2", true)

    getExperimentResource("roku_home_screen_if_modified_since", "roku_home_screen_if_modified_since_v1", true)
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

    if isNode(category) = true AND category.paginationInfo <> invalid
      cursor = category.paginationInfo.cursor
      hasMoreContent = category.paginationInfo.hasMoreContent
      if hasMoreContent = true AND  columnFocused >= (cursor - 10) AND category.state <> "containerPaginationRequestPending"
        isKidsMode = shouldKidsModeBeSentToServer()
        isSignedInUser = isLoggedInUser()
        categoryReqInfo = m.cmsApi.createGetContainerContentsReqInfo(category, homeScreen, isKidsMode, isSignedInUser, m.uiMode, false)
        if categoryReqInfo <> invalid
          category.state = "containerPaginationRequestPending"
          m.makeRequest({
            url: categoryReqInfo.url
            requestType: categoryReqInfo.requestType
            options: categoryReqInfo.options
            successCallback: onContainerMoreItemsSuccess
            silenceCallbackWarnings: true
            responseType: "node"
            isSignedInUser: isLoggedInUser()
            uiMode: m.uiMode
          })
        end if
      end if
    end if
  end if
End Function


Function onContainerMoreItemsSuccess(response)
  homeScreen = getCurrentScreen()
  if homeScreen <> invalid AND homeScreen.content <> invalid AND isNode(response) = true AND homeScreen.currFocusRow <> invalid
    rowFocused = homeScreen.currFocusRow
    category = homeScreen.content.getChild(rowFocused)
    category = m.NodeHelpers.getChildById(homeScreen.content, response.id)
    items = response.getChildren(-1, 0)
    if isNonEmptyArray(items) = true
      fullJson = ParseJson(category.json)
      newJson = ParseJson(response.json)
      if fullJson <> invalid AND newJson <> invalid
        fullJson.append(newJson)
        category.paginationInfo = response.paginationInfo
        category.json = FormatJson(fullJson)
        category.state = response.state
        category.appendChildren(items)
      end if
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
        if isLinearPlayerLoadingORPlaying() = true
          stopAndHideLinearVideoPlayer()
        end if
      end if

      if currentScreen.isSameNode(homeScreen) = true AND currentScreen.isInFocusChain() = true 'if there are any modals over home screen or focus has been lost to side nav
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

  batchRequests = m.cmsApi.createHomeScreenBatchReqInfoForContainers(categoryIDs, contentMode, isKidsMode, isSignedInUser)

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


Function onFeaturedRowCurrFocusColumnChange()
  m.videoPreviewDebounce.control = "stop"
  screen = getCurrentScreen()
  columnFocused = screen.featuredRowCurrFocusColumn
  if isNumber(columnFocused) = false OR columnFocused < 0
    columnFocused = 0
  end if

  ' Only process if the screen is the home screen.
  if isCurrentScreenHomeScreen() = true
    displayDefaultBackground()
  end if

  if screen <> invalid AND screen.featuredRowContent <> invalid
    if m.inlineVideoPreviewPlayerContainer.opacity = 1
      videoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
      if videoPlayer <> invalid
        videoPlayer.visible = false
      end if
      m.videoPreviewPlayer.visible = false
      if getVideoPreviewState() = "playing"
        pauseVideoPreview()
      end if
    end if

    updatePreviewPlayerToInlineView()
    m.videoPreviewDebounce.control = "start"
    if isLinearPlayerLoadingOrPlaying() = true
      stopAndHideLinearVideoPlayer()
    end if
    m.inlineVideoPreviewPlayerContainer.opacity = 1
    setInlineVideoMetadataOverlay(columnFocused, screen.featuredRowContent)
  end if

End Function


Function startFeaturedInlinePreview()
  screen = getCurrentScreen()
  if isCurrentScreenHomeScreen() = true AND screen.featuredListHasFocus = true
    stopAndHideLinearVideoPlayer()
    if screen.featuredRowContent <> invalid AND screen.featuredRowFocusedItem <> invalid
      content = screen.featuredRowFocusedItem
      setInlineVideoMetadataOverlay(screen.featuredRowCurrFocusColumn, screen.featuredRowContent)

      if content.type = m.constants.ui.categoryTypes.linear AND m.constants.deviceInfo.isAutoPlayEnabled = true
        playLinearInlineGridView(content, screen)
      else
        componentTrackingInfo = invalid
        if screen.trackingComponentInfo <> invalid AND screen.trackingPageInfo <> invalid
          componentTrackingInfo = screen.trackingComponentInfo
          pageInfo = screen.trackingPageInfo
          componentTrackingInfo = {
            pageOneof: m.Tracking.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
            componentOneof: m.Tracking.getAnalyticsComponent(componentTrackingInfo.componentType, componentTrackingInfo.componentValues)
          }
        end if
        setVideoPreviewAfterFocus(content, screen.trackingPageInfo, componentTrackingInfo)
      end if
    end if
  end if
End Function


Function setInlineVideoMetadataOverlay(columnFocused, featuredRowContent)
  if isNumber(columnFocused) = false OR columnFocused < 0
    columnFocused = 0
  end if

  columnFocused = CINT(columnFocused)

  itemContent = featuredRowContent.getChild(0).getChild(columnFocused)
  m.inlineVideoMetadataOverlay.itemContent = itemContent
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

    screen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
    m.inlineVideoPreviewPlayerContainer.translation = [159, 141]
  end if
End Function


Function onFeaturedListHasFocusChange(msg)
  hasFeaturedListFocus = msg.getData()
  screen = msg.getRoSGNode()
  content = screen.featuredRowFocusedItem
  previewContent = m.videoPreviewPlayer.content
  m.videoPreviewPlayer.visible = (isCurrentScreenHomeScreen() = false OR (content <> invalid AND previewContent <> invalid AND content.id = previewContent.id))
  if hasFeaturedListFocus = true
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
    else
      onFeaturedRowCurrFocusColumnChange()
    end if
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
  experiment = getExperimentResource("roku_home_screen_redesign", "roku_home_screen_redesign_v3", false)
  containerRow = m.nodeHelpers.getChildById(response, experiment.container_id)
  if containerRow <> invalid
    featuredContent = createObject("roSGNode", "CategoryContentNode")
    featuredContent.id = "featuredGrid"  
    containerRow.reParent(featuredContent, false)
    screen.featuredRowContent = featuredContent

    if screen.skinAdContent <> invalid OR (screen.featuredListHasFocus = false AND isKidsUIOn() = false)
      currentScreen = getCurrentScreen()
      isCurrScreenHomeScreen = currentScreen <> invalid AND currentScreen.id = m.constants.ui.screenIds.homeScreen
      if isCurrScreenHomeScreen = true
        m.inlineVideoPreviewPlayerContainer.opacity = 1
      end if
      setInlineVideoMetadataOverlay(0, featuredContent)
      m.inlineVideoMetadataOverlay.showContentPoster = true

      if screen.skinAdContent <> invalid
        m.inlineVideoPreviewPlayerContainer.translation = [m.inlineVideoPreviewPlayerContainer.translation[0], 945.5]
      end if
    end if
  end if
End Function


Function onFeaturedRowFocusedItemChange(msg)
  updatePreviewPlayerToInlineView()
End Function


Function onCurrCategoryIdChange()
  updateInlineVideoMetadataOverlayVisibility(0.3)
End Function


Function updateInlineVideoMetadataOverlayVisibility(duration = 0)
  screen = getCurrentScreen()
  if screen <> invalid
    currCategoryId = screen.currCategoryId
    experiment = getExperimentResource("roku_home_screen_redesign", "roku_home_screen_redesign_v3", false)
    if experiment <> invalid AND experiment.design_type = "withDescriptionPortraitSmall" AND isKidsUIOn() = false
      currentScreen = getCurrentScreen()
      if screen <> invalid AND currentScreen <> invalid AND currentScreen.id = m.constants.ui.screenIds.homeScreen AND currCategoryId = experiment.container_id AND currentScreen.featuredRowContent <> invalid
        content = screen.featuredRowFocusedItem
        if getVideoPreviewStateForThisContent(content) <> "playing"
          m.inlineVideoMetadataOverlay.showContentPoster = true
          pauseVideoPreview()
        end if
        fade(m.inlineVideoPreviewPlayerContainer, "in", duration)
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

    if isNumber(rectY) = true
      inlineVideoPreviewPlayerContainer = m.inlineVideoPreviewPlayerContainer.translation
      m.inlineVideoPreviewPlayerContainer.translation = [inlineVideoPreviewPlayerContainer[0], translation[1] + rectY - 6]
    end if
  end if
End Function