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
    m.performanceMetricsTracker.startAppLaunchMetricTiming("home_screen_tensor_request")
    showHideSpinner(true)
    homeScreen = CreateObject("roSGNode", "HomeScreen")
    homeScreen.shouldFocusWhenPushed = m.top.fadeInContentController
    homeScreen.observeFieldScoped("backgroundUriList", "onVideoContentScreenBackgroundUpdated")
    homeScreen.observeFieldScoped("sponsorshipBackground", "onSponsorshipBackgroundChanged")
    homeScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
    homeScreen.observeFieldScoped("loadAllCategories", "onLoadAllCategories")
    homeScreen.observeFieldScoped("loadAllCategoriesViaRefreshTimer", "onLoadAllCategoriesAfterRefreshTimer")
    homeScreen.observeFieldScoped("contentFocused", "onRowFocusedItemChange")
    homeScreen.observeFieldScoped("focusLost", "onHomeScreenFocusLost")
    homeScreen.observeFieldScoped("contentSelected", "onContentSelected")
    homeScreen.observeFieldScoped("contentToPlay", "onContentToPlay")
    homeScreen.observeFieldScoped("transportVoiceResponse", "onTransportVoiceResponse")
    homeScreen.observeFieldScoped("loadCategoryForIds", "onLoadCategoryForIds")
    homeScreen.observeFieldScoped("stopLinearVideoPlayer", "onStopLinearVideoPlayer")
    homeScreen.observeFieldScoped("sponsoredRowFocused", "onHomeScreenSponsoredRowFocused")
    homeScreen.observeFieldScoped("rowCurrFocusColumn", "onRowCurrFocusColumnChange")
    homeScreen.observeFieldScoped("pauseVideoPreview", "onPauseVideoPreview")
    homeScreen.observeFieldScoped("componentInteractionInfo", "onComponentInteractionInfoChange")
    homeScreen.observeFieldScoped("listCurrFocusRow", "onRowCurrFocusRowChange")
    homeScreen.observeFieldScoped("listHasFocus", "onListHasFocusChange")
    homeScreen.observeFieldScoped("adTimerImpressionFire", "onAdTimerImpressionFired")
    homeScreen.observeFieldScoped("currCategoryId", "onCurrCategoryIdChange")
    homeScreen.observeFieldScoped("currentFocusedItemBoundingRect", "onRowListTranslationChange")
    homeScreen.observeFieldScoped("rowListTranslation", "onRowListTranslationChange")
    homeScreen.observeFieldScoped("listScrollDirection", "onListScrollDirectionChange")
    homeScreen.observeFieldScoped("listScrollingStatus", "onListScrollingStatusChange")

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
  tubiLog("HomeScreenHelpers.processHomeScreenBatchResponse")
  homeScreen = getFromScreenCache(screenId)
  if homeScreen <> invalid
    homeScreen.batchResponse = response
  end if
End Function


'//This is called when the homescreen has already loaded but the ad display content has expired and needs to be refreshed.
Function onHomesceenAdDisplayBatchResponse(response)
  tubiLog("HomeScreenHelpers.onHomesceenAdDisplayBatchResponse")
  homeScreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
  if homeScreen <> invalid AND isNonEmptyArray(response) = true
    '//Don't Refresh the skin
    homeScreen.batchAdResponse = response
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
Function onReloadUserCategoriesInHomeScreen(response, screenId = "")
  tubiLog("HomeScreenHelpers.onReloadUserCategoriesInHomeScreen")

  if screenId = ""
    screenId = m.constants.ui.screenIds.homeScreen
  end if
  homeScreen = getFromScreenCache(screenId)

  if homeScreen <> invalid
    ' For video tiles experiment, we need to update the featured row content.
    ' Since all the rows will be using new video tiles format.
    if m.isUserInVideoTilesExperiment = true AND screenId = m.constants.ui.screenIds.homeScreen
      content = homeScreen.content
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


' load all category content. Series do not have season or episode information though.
Function onLoadAllCategories(msg)
  tubiLog("HomeScreenHelpers.onLoadAllCategories")
  homeScreen = msg.getRoSGNode()

  fetchHomescreen(homeScreen, true)
End Function


' load all category content. Series do not have season or episode information though.
Function onLoadAllCategoriesAfterRefreshTimer(msg)
  tubiLog("HomeScreenHelpers.onLoadAllCategoriesAfterRefreshTimer")
  homeScreen = msg.getRoSGNode()

  useCache = true
  if m.constants.settings.mode <> "production" AND m.constants.settings.screenOverrideContentRefreshTimeoutSeconds <> invalid AND m.constants.settings.screenOverrideContentRefreshTimeoutSeconds > 0
    '//If we are overriding the content refresh timeout using a forced refresh timer (for testing purposes), then always fetch fresh content
    useCache = false
  end if

  fetchHomescreen(homeScreen, useCache)
End Function


Function fetchHomeScreen(homeScreen, useCache = false)
  tubiLog("HomeScreenHelpers.fetchHomeScreen")
  ' This check causes all category fetches to be skipped prior to the field
  ' being set to true.  Then, once true categories reload any time fetchHomeScreen() is
  ' called, such as when signedIn field changes.
  if homeScreen.canLoadCategories = true
    '//reset contentFetchCompleted flags
    homeScreen.contentFetchCompleted = false
    homeScreen.adContentFetchCompleted = false

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
    else if homeScreen.id = m.constants.ui.screenIds.homeScreen
      if isKidsUIOn() = false AND isParentalControlsAdultLevel() = true
        '//Call an ad endpoint to get ad content for the homescreen. The ad endpoint will return if any ads are active
        aAdTypes = [m.constants.adTypes.adRowlistCarousel, m.constants.adTypes.adRowlistSpotlight, m.constants.adTypes.skinAd]

        createHomescreenAdRequest(homeScreen.id, onHomesceenAdDisplaySuccessResponse, aAdTypes, onHomesceenAdDisplayErrorResponse)
      else
        'If in kids mode, then user is not in experiment and we should indicate that the adContentFetchCompleted flag is true so that ads are not waited on when loading homescreen content
        homeScreen.adContent = []
        homeScreen.adContentFetchCompleted = true
      end if
    end if

    ' For tensor API, we need to pass as empty string for homescreen
    if homeScreen.contentMode = m.constants.ui.contentMode.homescreen
      contentMode = ""
    else
      contentMode = homeScreen.contentMode
    end if

    options = {}

    headers = {}
    params = {
      group_start: 0
      group_size: m.constants.performance.categoryGridList.numContainers
      contents_limit: m.constants.performance.categoryGridList.initialBlockSize
      content_mode: contentMode
    }

    isKidsMode = shouldKidsModeBeSentToServer()

    if homeScreen <> invalid AND homeScreen.content <> invalid AND useCache = true AND homeScreen.content.lastModified <> invalid
      headers["If-Modified-Since"] = homeScreen.content.lastModified
    end if

    options.params = params
    options.headers = headers
    homeScreenReqInfo = m.CmsApi.createHomeScreenReqInfo(isKidsMode, options)
    m.makeRequest({
      url: homeScreenReqInfo.url
      requestType: m.constants.reqNames.getHomescreen
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

    homeScreen.containerPaginationStatus = "none"
  end if
End Function


' @homescreenId: string, the screen ID of the homescreen
' @successCallback: function to call on success
' @aAdTypes: array of strings, the ad types to request; possible values are found under m.constants.adTypes.
' @errorCallback: function to call on error
Function createHomescreenAdRequest(homescreenId, successCallback, aAdTypes = [], errorCallback = invalid) as Void
  if isNonEmptyArray(aAdTypes) = false
    '//If no ad types are specified, then there is no need to make the ad request
    return
  end if

  appMode = "DEFAULT_MODE"
  if isKidsUIOn() = true
    appMode = "KIDS_MODE"
  else if m.uiMode = m.constants.ui.modes.latino
    appMode = "LATINO_MODE"
  end if

  authInfo = m.tubiAuthUpdate.getAuthInfo()
  userId = ""
  if authInfo <> invalid AND authInfo.userId <> invalid
    userId = authInfo.userId.toStr()
  end if
  adDisplayReqInfo = m.cmsApi.createAdHomescreenDisplayContainerReqInfo(aAdTypes, appMode, userId, isKidsUIOn())
  m.makeRequest({
    url: adDisplayReqInfo.url
    requestType: m.constants.reqNames.getHomescreenAds
    options: adDisplayReqInfo.options
    successCallback: successCallback
    errorCallback: errorCallback
    responseType: "array"
    screenId: homescreenId
    adTypes: aAdTypes
    timeoutInMilliSec: adDisplayReqInfo.timeoutInMilliSec
    isUserInVideoTilesExperiment: m.isUserInVideoTilesExperiment
  })
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


Function onHomesceenAdDisplaySuccessResponse(response)
  tubiLog("HomeScreenHelpers.onHomesceenAdDisplaySuccessResponse")

  homeScreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
  if homeScreen <> invalid
    aParsedResponseAfterExperimentCheck = []
    skinAdsWrapper = invalid

    if isNonEmptyArray(response) = true AND isKidsUIOn() = false AND isParentalControlsAdultLevel() = true
      for each adResponse in response
        '// Iterate through the ad responses and determine whether each ad should be displayed
        '// based on the associated experiment's values.
        if adResponse <> invalid
          if adResponse.type = m.constants.ui.contentTypes.skinAd
            if getStatsigExperimentResource("ads_homegrid_layer", "ads_hdc_all_holdback_v2", true).enabled = true
              skinAdsWrapper = adResponse

              ' Do not display video tile overlay group if the skin ads is available.
              ' This is needed because we refresh home screen behind the scenes during parent controls change.
              m.videoTileOverlayGroup.visible = false
            end if
          else if adResponse.type = m.constants.ui.contentTypes.adRowlistCarousel OR adResponse.type = m.constants.ui.contentTypes.adRowlistSpotlight
            if getStatsigExperimentResource("ads_homegrid_layer", "ads_hdc_all_holdback_v2", true).enabled = true
              aParsedResponseAfterExperimentCheck.push(adResponse)
            end if
          end if
        end if
      end for
    end if

    homeScreen.skinAdContent = skinAdsWrapper
    homeScreen.skinAdContentUpdated = true
    homeScreen.adContent = aParsedResponseAfterExperimentCheck
    homeScreen.adContentFetchCompleted = true

    checkIfHomeScreenContentIsReady(homeScreen)
  end if
End Function


Function onHomesceenAdDisplayErrorResponse(_response)
  tubiLog("HomeScreenHelpers.onHomesceenAdDisplayErrorResponse")
  '//If the ad response fails, then fail silently and continue with the homescreen content update
  homeScreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
  homeScreen.adContentFetchCompleted = true
  checkIfHomeScreenContentIsReady(homeScreen)
End Function


Function checkIfHomeScreenContentIsReady(homeScreen)
  tubiLog("HomeScreenHelpers.checkIfHomeScreenContentIsReady")
  sID = homeScreen.id
  bIsHomeScreen = (sID = m.constants.ui.screenIds.homeScreen)
  '//Check if ad content has loaded, but only for the default homescreen type. The other homescreen types do not have ad content. (Note that adContentFetchCompleted will be true even if backend responds that there is no ad content)
  bAdContentLoaded = (bIsHomeScreen = true AND homeScreen.adContentFetchCompleted = true)
  bContentLoaded = (homeScreen.contentFetchCompleted = true)

  bHomeScreenContentReady = false
  if bContentLoaded = true
    if bIsHomeScreen = false
      ' For non-default homeScreens, we do not have ad content to wait for, so just indicate that the homescreen content is ready
      bHomeScreenContentReady = true
    else if bAdContentLoaded = true
      bHomeScreenContentReady = true

      adContent = homeScreen.adContent
      homescreenContent = homeScreen.content

      if adContent <> invalid then
        ' Insert each node into homeScreen.content at rowPlacement index
        for each node in adContent
          if node <> invalid AND node.type <> m.constants.ui.contentTypes.skinAd
            homescreenContent.insertChild(node, node.rowPlacement)
          end if
        end for
      end if
    end if

    if bHomeScreenContentReady = true
      onHomeScreenContentUpdateComplete(sID)
    end if
  end if

End Function


''''''''''''''''''''''''''''''
' respondToHomeScreenSuccessResponse
'
Function respondToHomeScreenSuccessResponse(screenID, rawResponse)
  tubiLog("HomeScreenHelpers.respondToHomeScreenSuccessResponse, screenID: " + screenID)
  m.performanceMetricsTracker.endAppLaunchMetricTiming("home_screen_tensor_request")
  m.performanceMetricsTracker.startAppLaunchMetricTiming("home_screen_populate_content")
  homeScreen = getFromScreenCache(screenID)
  if homeScreen <> invalid
    ' Check if response is empty (no children)
    isResponseEmpty = false
    if isNode(rawResponse) = true
      ' Check if node has no children
      if rawResponse.getChildCount() = 0
        isResponseEmpty = true
      end if
    end if

    ' If response is empty, show error modal
    if isResponseEmpty = true
      ' Only show error modal if screen is in focus
      handleHomeScreenErrorResponse(screenID, rawResponse)
    else
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
      homeScreen.contentFetchCompleted = true

      homeScreen.personalizationId = rawResponse.personalizationId
      homeScreen.shouldTrackViewableImpressionEvent = (isUserInAdultsMode() = true AND isKidsUIOn() = false)

      if isKidsUIOn() = false AND screenID = m.constants.ui.screenIds.homeScreen
        sanitizeHomeScreenResponseAndReturnLiveEventsContainer(rawResponse)
        refreshLiveEventsContainerWithEpgListingInfo(rawResponse)

        getStatsigExperimentResource("roku_video_tiles", "roku_video_tiles_1_7", true)
        if m.isUserInVideoTilesExperiment = true AND isNode(rawResponse) = true AND rawResponse.getChildCount() > 0
          ' Only show the video tile overlay group if the screen is the home screen and the skin ads are not available.
          ' This is needed because we refresh home screen behind the scenes during parent controls change.
          screen = getCurrentScreen()
          isSkinAdsAvailable = (homeScreen.skinAdContent <> invalid)
          m.videoTileOverlayGroup.visible = (isSkinAdsAvailable = false AND screen <> invalid AND screen.id = m.constants.ui.screenIds.homeScreen)
          updateCategoryGridWithRowList(rawResponse, homeScreen)
        else
          m.videoTileOverlayGroup.visible = false
          homeScreen.content = rawResponse
        end if
      else
        m.videoTileOverlayGroup.visible = false
        homeScreen.content = rawResponse
      end if

      checkIfHomeScreenContentIsReady(homeScreen)

      getExperimentResource("roku_no_change_experiment", "roku_no_change_experiment_v3", true)
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
  tubiLog("HomeScreenHelpers.onHomeScreenErrorResponse")
  screen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
  if response.httpStatusCode <> 304 OR screen.content = invalid
    handleHomeScreenErrorResponse(m.constants.ui.screenIds.homeScreen, response)
  else if screen.content <> invalid AND screen.content.validDuration <> invalid
    ' Updating the valid_duration.
    screen.content.validUntil = Uptime(0) + screen.content.validDuration
  end if
  m.performanceMetricsTracker.endAppLaunchMetricTiming("home_screen_tensor_request")
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
  if isSponsoredRowFocused = true AND homeScreen <> invalid AND currentScreen <> invalid AND currentScreen.isSameNode(homeScreen) AND m.isUserInVideoTilesExperiment = false
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


Function onHomeScreenFocusLost(msg)
  tubiLog("HomeScreenHelpers.onHomeScreenFocusLost")
  homeScreen = msg.getRoSGNode()
  bLostFocus = msg.getData()
  focusedContent = homeScreen.contentFocused
  if bLostFocus = true
    m.inlinePreviewFocusIndicator.visible = false
    if focusedContent <> invalid AND focusedContent.type = m.constants.ui.contentTypes.adRowlistSpotlight
      '//Hide the video preview when the focus is no longer on the homscreen but the ad rowlist spotlight is still displayed. This is to ensure we can't see the player does not have rounded corners.
      stopVideoPreview()
    end if
  end if
End Function


Function onContainerMoreItemsSuccess(response)
  homeScreen = getCurrentScreen()
  if homeScreen <> invalid AND homeScreen.content <> invalid AND isNode(response) = true AND homeScreen.listCurrFocusRow <> invalid
    appendContentToCategory(response, homeScreen.content)
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

  if isNode(category) = true AND category.paginationInfo <> invalid AND columnFocused >= firstBatchLimit
    cursor = category.paginationInfo.cursor
    hasMoreContent = category.paginationInfo.hasMoreContent
    rightEdge = cursor - 10
    if isInteger(category.totalDuplicates)
      rightEdge = rightEdge - category.totalDuplicates
    end if
    if hasMoreContent = true AND columnFocused >= rightEdge AND category.state <> "containerPaginationRequestPending"
      isKidsMode = shouldKidsModeBeSentToServer()
      isSignedInUser = isLoggedInUser()
      categoryReqInfo = m.cmsApi.createGetContainerContentsReqInfo(category, homeScreen, isKidsMode, isSignedInUser, m.uiMode, false)
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
          uiMode: m.uiMode
          categoryId: category.id
          requestContext: {
            childrenContentIDs: category.childrenContentIDs
            totalDuplicates: category.totalDuplicates
          }
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
      content = homeScreen.content
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
Function appendContentToCategory(response, contentNode)
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
      category.childrenContentIDs = response.childrenContentIDs
      category.totalDuplicates = response.totalDuplicates
      category.json = FormatJson(fullJson)
      category.state = response.state
      category.appendChildren(items)
      screen.containerAppendMoreTilesStatus = "complete"
      if m.videoPreviewDebounce.control = "stop"
        m.videoPreviewDebounce.control = "start"
      end if
    end if
  end if
End Function


' setHomeScreenAfterFocus()
' This function should be called when a new rowlist item on the homescreen gains focus.
' Anything that needs to be set after a focus should be done in this function
' @param focusedContent, roSGNode - The TubiContentNode of the focused content
' @param homeScreen, roSGNode - The HomeScreen component that contains the focused content
Function setHomeScreenAfterFocus(focusedContent, homeScreen) as Void
  tubiLog("HomeScreenHelpers.setHomeScreenAfterFocus")

  setUIBasedOnFocusedContent(focusedContent)

  if focusedContent = invalid
    return
  end if

  currentScreen = getCurrentScreen()
  if currentScreen = invalid OR currentScreen.id = m.constants.ui.screenIds.linearVideoPlayerScreen
    return
  end if

  ' Default: stop countdown timer unless we're continuing to play linear content
  shouldStopCountdownTimer = true

  ' Handle linear content autoplay
  isLinearAutoplayCondition = (focusedContent.type = m.constants.ui.categoryTypes.linear AND m.SideNav.opened <> true AND m.tempModal = invalid AND m.constants.deviceInfo.isAutoplayEnabled = true)

  if isLinearAutoplayCondition = true
    isAlreadyPlaying = isLinearPlayerPlayingThisContent(focusedContent)

    if isAlreadyPlaying = false
      ' Display background and play the video
      m.backgroundGroup.posterVisible = true
      stopLinearVideoContent()

      isGateEnabled = getStatsigExperimentResource("roku_linear_reg_gate", "roku_linear_reg_gate_v1_1", false).enabled
      if focusedContent.needsLogin = false OR isGateEnabled = false
        playbackSource = {
          "srcForAnalytic": m.constants.player.playbackSource.unknown
          "srcForAds": m.constants.player.playbackOrigin.container
          "playbackContainer": currentScreen.currCategoryId
        }
        playLinearVideoContent(focusedContent, true, homeScreen.id, true, playbackSource)
      end if
    else
      ' Content is already playing, keep countdown timer running
      shouldStopCountdownTimer = false
      startCountdownTimer()
      m.backgroundGroup.posterVisible = false
    end if
  else
    ' Non-linear or autoplay disabled: stop linear player if playing
    if isLinearPlayerLoadingOrPlaying() = true
      stopAndHideLinearVideoPlayer()
    end if
  end if

  ' Handle video preview for home screen content
  isHomeScreenInFocus = (currentScreen.isSameNode(homeScreen) = true AND currentScreen.isInFocusChain() = true)
  if isHomeScreenInFocus = true
    componentTrackingInfo = getCategoryComponentTrackingInfo(currentScreen)

    ' Check if this is ad carousel/spotlight content with video preview
    isAdCarousel = (focusedContent.type = m.constants.ui.contentTypes.adRowlistCarousel)
    isAdSpotlight = (focusedContent.type = m.constants.ui.contentTypes.adRowlistSpotlight)
    hasVideoPreview = (focusedContent.videoPreviewUrl <> "")

    if (isAdCarousel = true OR isAdSpotlight = true) AND hasVideoPreview = true
      ' Set video preview with delay for ad content
      if isAdSpotlight = true
        updatePlayerLayoutBasedOnFocusedContent(focusedContent)
        stopVideoPreview()
        m.videoPreviewDebounce.duration = m.constants.player.videoPreviewDelayTimes.adSpotlight
      else
        m.videoPreviewDebounce.duration = m.constants.player.videoPreviewDelayTimes.adCarousel
      end if
      m.videoPreviewDebounce.control = "start"
    else
      ' Set video preview immediately for regular content
      setVideoPreviewAfterFocus(focusedContent, currentScreen.trackingPageInfo, componentTrackingInfo)
    end if
  end if

  if shouldStopCountdownTimer = true
    stopCountdownTimer()
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
        else
          showHideLogoBasedOnUiMode(skinAdContent.titleImageUrl, skinAdContent.titlePrefix)
        end if

        setBackgroundColor(skinAdContent.bgColor)
      end if
    end if
  end if
End Function


'//When the ad timer impression is fired from the homescreen, then send the pixels to the ad server
Function onAdTimerImpressionFired(msg)
  tubiLog("HomeScreenHelpers.onAdTimerImpression")
  homeScreen = msg.getRoSGNode()
  checkHomeScreenFocusRowToSendAdPixels(homeScreen)
End Function


'//Check the focused row if it has any ad pixels to be sent
' @homeScreen: roSGNode, the HomeScreen component
Function checkHomeScreenFocusRowToSendAdPixels(homeScreen)
  tubiLog("HomeScreenHelpers.checkHomeScreenFocusRowToSendAdPixels")
  if homeScreen <> invalid
    row = homeScreen.rowFocused
    if row <> invalid AND row.imageImpTracking <> invalid
      imageImpTracking = row.imageImpTracking
      '//Once the pixel has been sent, then set the imageImpTracking to invalid so that it is not sent again
      row.imageImpTracking = invalid
      sendAdPixels(imageImpTracking)
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
      sendAdPixels(sponsorPixels)
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
    if content.needsLogin = true AND isLoggedInUser() = false AND getStatsigExperimentResource("roku_linear_reg_gate", "roku_linear_reg_gate_v1_1").enabled = true
      showLinearPlayerSignInModal(content)
    else
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


Function getCurrentFocusedContainerId(screen, content)
  containerId = invalid
  if screen <> invalid AND screen.currCategoryId <> invalid
    containerId = screen.currCategoryId
  else if screen <> invalid AND screen.categoryId <> invalid
    containerId = screen.categoryId
  else if content <> invalid
    containerId = content.parentId
  end if

  return containerId
End Function


' Called when the user selects a content item on the home screen.
' @msg, roSGNode, the message containing the content item and the home screen node.
Function onContentSelected(msg)
  tubiLog("HomeScreenHelpers.onContentSelected")
  content = msg.getData()
  contentType = content.type

  if contentType <> m.constants.ui.contentTypes.adRowlistCarousel AND contentType <> m.constants.ui.contentTypes.adRowlistSpotlight
    '//process the user content selection if the content selected is not a carousel or spotlight ad campaign type

    homeScreen = msg.getRoSGNode()
    containerId = getCurrentFocusedContainerId(homeScreen, content)
    m.autoplayContext = containerId
    playbackSource = {
      "srcForAnalytic": m.constants.player.playbackSource.unknown
      "srcForAds": m.constants.player.playbackOrigin.container
      "playbackContainer": containerId
    }
    processUserContentSelection(content, homeScreen, playbackSource)

    if contentType = m.constants.ui.contentTypes.skinAd
      ' If the content selected is a skinAd, then check if there are any ad pixels to be sent.
      checkHomeScreenFocusRowToSendAdPixels(homeScreen)
    end if
  end if
End Function


Function onContentToPlay(msg)
  content = msg.getData()
  contentType = content.type
  screen = msg.getRoSGNode()
  containerId = getCurrentFocusedContainerId(screen, content)


  if contentType <> m.constants.ui.contentTypes.adRowlistCarousel AND contentType <> m.constants.ui.contentTypes.adRowlistSpotlight
    playbackSource = {
      "srcForAnalytic": m.constants.player.playbackSource.unknown
      "srcForAds": m.constants.player.playbackOrigin.container
      "playbackContainer": containerId
    }

    processUserPlayAction(content, screen, playbackSource)
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
      pageOneof: m.Tracking.getAnalyticsPage("home_page", { content_mode: "CONTENT_MODE_UNKNOWN" })
      dialog_action: "SHOW"
      dialog_sub_type: "reg_intro"
    }
  }

  modalInfo = {
    header: header
    subHeader: subHeader
    message: "" 'message is not used in case of multistyle dialog
    modalDialogTypes: m.constants.modalDialogTypes.multiStyle
    modalDialogStyles: m.constants.modalDialogStyles.multiMessageGroup
    multiStyleMessage: multiMessage
    openTrackEvent: dialogEvent
    trackingTask: m.trackingLoggingTask
    backButtonCallback: invalid
    instantResumeAction: m.constants.instantResumeActions.closeDialog
  }

  ' Check if we're within the special event onboarding time period
  eventStart = getExternalConfigValueFromGlobal("special_event_onboarding_start_time", invalid)
  eventEnd = getExternalConfigValueFromGlobal("special_event_onboarding_end_time", invalid)
  isWithinEventPeriod = isNowWithinTimePeriod(eventStart, eventEnd)

  if isWithinEventPeriod = true
    imageUrl = ["https://mrcdn-production.tubitv.com/appFiles/images/welcome-banner.webp"]
  else
    imageUrl = ["pkg:/images/transparent.png"]
  end if

  modalInfo.append({
    imageUrls: imageUrl
    imageDimensions: [[617, 120]]
  })

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
  aAdTypes = []
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
  else if homeScreen.id = m.constants.ui.screenIds.homescreen
    '//check if there are any ad category IDs in the list of category IDs
    for i = categoryIDs.count() - 1 to 0 step -1
      categoryID = categoryIDs[i]
      if categoryID = m.constants.ui.categoryIds.adRowlistCarousel
        aAdTypes.push(m.constants.adTypes.adRowlistCarousel)
        categoryIDs.delete(i)
      else if categoryID = m.constants.ui.categoryIds.adRowlistSpotlight
        aAdTypes.push(m.constants.adTypes.adRowlistSpotlight)
        categoryIDs.delete(i)
      else if categoryID = m.constants.ui.categoryIds.skinAd
        aAdTypes.push(m.constants.adTypes.skinAd)
        categoryIDs.delete(i)
      end if
    end for
  end if

  createHomescreenAdRequest(homeScreen.id, onHomesceenAdDisplayBatchResponse, aAdTypes)

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
  if m.constants.settings.mode <> "production" AND m.constants.settings.hideStartupModals = true
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


' @screenId: string, id of the screen from where the call was made. constants.ui.screenIds.homeScreen or constants.ui.screenIds.eventDetailScreen
Function onHomeScreenContentUpdateComplete(screenId)
  tubiLog("HomeScreenHelpers.onHomeScreenContentUpdateComplete")
  homeScreen = getFromScreenCache(screenId)

  homeScreen.contentUpdated = true
  '//update the UI after the content has loaded
  setUIBasedOnFocusedContent(homeScreen.contentFocused)

  ' don't set focus on the home screen if side nav has focus, for example
  if homeScreen.isInFocusChain() = true
    homeScreen.setFocus(true)
  end if

  m.performanceMetricsTracker.endAppLaunchMetricTiming("home_screen_populate_content")

  startClientImpressionTimer()
End Function


' Fade in and out the focus indicator when the user is scrolling through the rows.
' Provides similar better as row list fadeFocusWhileScrolling experience.
' @param msg: roSGNode, the message object.
Function onRowCurrFocusRowChange(msg)
  screen = msg.getRoSGNode()
  currFocusRow = msg.getData()
  fade(m.autoStartPreviewToPlaybackTimer, "out", 0.1)
  ' It will only start the timer for the first time.
  m.performanceMetricsTracker.startMetricTiming("vertical_scroll_performance")
  updateVideoTileSize(screen.listScrollingStatus)

  if screen.lastFocusedList = "rowList"
    m.videoPreviewPlayer.opacity = 0
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
      checkAndSetSponsorshipBackground(screen.content, currFocusRow)
    end if
  end if

  if currFocusRow = Fix(currFocusRow)
    m.performanceMetricsTracker.endMetricTiming("vertical_scroll_performance", { row: currFocusRow, screen: screen.id })
    if screen.containerPaginationStatus <> "finished"
      makeAdditionalContainersRequestConditionally(currFocusRow, screen)
    end if
  end if
End Function


' Triggers a callback when list has started and stopped scrolling through the rows.
' @param msg: roSGNode, the message object.
Function onListScrollingStatusChange(msg)
  scrollingStatus = msg.getData()
  screen = msg.getRoSgNode()

  isVideoTileEnabledScreen = isKidsUIOn() = false AND screen.id = m.constants.ui.screenIds.homeScreen

  ' Below logic helps to avoid us from updating the in transit video metadata overlay when the user is scrolling up or down.
  if scrollingStatus = false
    if screen.content <> invalid AND isVideoTileEnabledScreen = true
      updateVideoTileSize(scrollingStatus)
      updateInTransitVideoMetadataOverlay()
    end if
    state = m.videoPreviewPlayer.playerState
    if state = "playing" OR state = "paused"
      stopVideoPreview()
    end if

    ' Handle paginated content queue
    if m.paginatedContentQueue <> invalid
      appendPaginatedContainersToScreen(screen, m.paginatedContentQueue)
      m.paginatedContentQueue = invalid
    end if
  end if
End Function


Function onListHasFocusChange(msg)
  tubiLog("HomeScreenHelpers.onListHasFocusChange")
  hasFeaturedListFocus = msg.getData()
  screen = msg.getRoSGNode()
  content = screen.contentFocused
  previewContent = m.videoPreviewPlayer.content
  m.videoPreviewPlayer.visible = (isCurrentScreenHomeScreen() = false OR (content <> invalid AND previewContent <> invalid AND content.id = previewContent.id)) AND (previewContent <> invalid AND previewContent.gridItemType <> m.constants.ui.gridItemTypes.skinAd)
  if hasFeaturedListFocus = true
    if isCurrentScreenHomeScreen() = true
      updateVideoTileScreenBackground(content, screen)
    end if

    previewState = getVideoPreviewStateForThisContent(content)
    m.inlinePreviewFocusIndicator.visible = true
    m.inlinePreviewFocusIndicator.opacity = 1
    if previewState = "paused"
      resumeVideoPreview()
    else if previewState = "playing"
      updatePlayerLayoutBasedOnFocusedContent(content)
    else if m.queuedVideoTilePreview = true
      startDebouncedVideoPreview()
    end if
    setUIBasedOnFocusedContent(content)
  else if isCurrentScreenHomeScreen() = true
    m.videoPreviewPlayer.visible = false
    m.inlinePreviewFocusIndicator.visible = false
    if screen.lastFocusedList = "rowList"
      pauseVideoPreview()
    end if
  else
    screen = getCurrentScreen()
    if screen <> invalid AND screen.id = m.constants.ui.screenIds.linearDetailScreen
      updatePreviewPlayerToFullScreen()
    else
      updatePreviewPlayerToCondensedView()
    end if
  end if
End Function


Function updateCategoryGridWithRowList(response, screen)
  screen.content = response

  if screen.skinAdContent <> invalid OR (screen.listHasFocus = false AND isKidsUIOn() = false)
    currentScreen = getCurrentScreen()
    isCurrScreenHomeScreen = currentScreen <> invalid AND currentScreen.id = m.constants.ui.screenIds.homeScreen
    if isCurrScreenHomeScreen = true AND screen.isInFocusChain() = false
      m.inlineVideoPreviewPlayerContainer.opacity = 1
    end if
    setInlineVideoMetadataOverlay(response, 0, 0)
    m.inlineVideoMetadataOverlay.showContentPoster = true

    if screen.skinAdContent <> invalid AND screen.isInFocusChain() = false
      m.inlineVideoPreviewPlayerContainer.translation = [m.inlineVideoPreviewPlayerContainer.translation[0], 945.5]
    end if
  end if
End Function


Function onRowFocusedItemChange(msg) as Void
  focusedItem = msg.getData()
  screen = msg.getRoSGNode()

  if focusedItem = invalid
    return
  end if

  ' Handle video tile enabled containers
  isVideoTile = isVideoTileEnabledContainer(focusedItem.gridItemType)
  isVideoTileEnabledScreen = isKidsUIOn() = false AND screen.id = m.constants.ui.screenIds.homeScreen
  if screen.oldRowFocusedItem <> invalid AND screen.oldRowFocusedItem.gridItemType = m.constants.ui.gridItemTypes.skinAd
    m.videoPreviewPlayer.visible = false
  end if
  m.videoTileOverlayGroup.visible = isVideoTileEnabledScreen AND focusedItem.gridItemType <> m.constants.ui.gridItemTypes.skinAd

  ' Figure out a better way to handle this.
  if isVideoTileEnabledScreen = false OR focusedItem.gridItemType = m.constants.ui.gridItemTypes.skinAd
    fade(m.inlineVideoPreviewPlayerContainer, "out", 0.1)
    setHomeScreenAfterFocus(focusedItem, screen)
    return
  end if

  if isVideoTile = true
    m.inlineVideoPreviewPlayerContainer.visible = true
    ' Update itemContent if the focused item has changed
    ' For ex: Continue watching row getting updated with new item or existing item deleted
    shouldUpdateOverlay = isNode(m.inlineVideoMetadataOverlay.itemContent) = true AND focusedItem.title <> m.inlineVideoMetadataOverlay.itemContent.title
    if shouldUpdateOverlay = true
      updateInTransitVideoMetadataOverlay()
    end if
  else
    m.inlineVideoPreviewPlayerContainer.visible = false
    ' Handle ad carousel with video preview
    if focusedItem.type = m.constants.ui.contentTypes.adRowlistCarousel AND focusedItem.videoPreviewUrl <> ""
      m.videoPreviewDebounce.duration = m.constants.player.videoPreviewDelayTimes.adCarousel
      m.videoPreviewDebounce.control = "start"
    end if
  end if

  ' Start video preview debounce if conditions are met
  ' Needed for initial load and refresh cases where columnFocusChange is not triggered
  if isVideoPreviewOn() = true AND (m.videoPreviewDebounce.control = "stop" OR m.videoPreviewDebounce.control = "none")
    if screen.listHasFocus = true
      m.videoPreviewDebounce.control = "start"
    else
      m.queuedVideoTilePreview = true
    end if
  end if

  ' Update UI for home screen
  if isCurrentScreenHomeScreen() = true
    updateVideoTileScreenBackground(focusedItem, screen)
    updatePlayerLayoutBasedOnFocusedContent(focusedItem)
  end if

  setUIBasedOnFocusedContent(focusedItem)
End Function


Function onCurrCategoryIdChange()
  if m.wasAppLaunchMetricFired <> true
    m.wasAppLaunchMetricFired = true
    m.performanceMetricsTracker.endAppLaunchMetricTiming("time_to_first_tile_focus")
    m.performanceMetricsTracker.logAppLaunchMetrics()
  end if
  updateInlineVideoMetadataOverlayVisibility(0.3)
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
Function onListScrollDirectionChange(msg)
  screen = msg.getRoSGNode()
  scrollDirection = msg.getData()
  isVideoTileEnabledScreen = isKidsUIOn() = false AND screen.id = m.constants.ui.screenIds.homeScreen
  if isVideoTileEnabledScreen = true AND (scrollDirection = "down" OR scrollDirection = "up")
    updateVideoTileSize(screen.listScrollingStatus)
    updateInTransitVideoMetadataOverlay()
  end if
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


Function refreshLiveEventsContainerWithEpgListingInfo(response)
  liveEventsContainer = getLiveEventsContainer(response)
  if isNode(liveEventsContainer) AND liveEventsContainer.getChildCount() > 0
    ' Currently limiting it to only one live event spotlight.
    ' Might have to revisit this once we add support for multiple live event in container.
    program = liveEventsContainer.getChild(0)
    if isNode(program) AND isAA(program.scheduleData) AND program.scheduleData.id <> invalid
      scheduleId = program.scheduleData.id.toStr()
      updateLiveEventsContainerWithEpgListingInfo(scheduleId)
    end if
  end if
End Function


' Returns the live events container if available.
' @param rawResponse: roSGNode, the raw response.
' @return: roSGNode, the live events container if available, otherwise invalid.
Function getLiveEventsContainer(rawResponse)
  if isNode(rawResponse) = true AND rawResponse.getChildCount() > 0
    for i = 0 to rawResponse.getChildCount() - 1
      child = rawResponse.getChild(i)
      if child.gridItemType = m.constants.ui.gridItemTypes.liveEventSpotlight
        return child
      end if
    end for
  end if

  return invalid
End Function


Function sanitizeHomeScreenResponseAndReturnLiveEventsContainer(rawResponse)
  liveEventsContainer = invalid
  if isNode(rawResponse) = true AND rawResponse.getChildCount() > 0
    liveEventsContainer = getLiveEventsContainer(rawResponse)

    if isNode(liveEventsContainer) = true AND liveEventsContainer.getChildCount() > 0
      program = liveEventsContainer.getChild(0)
      if isNode(program) = true AND isAA(program.scheduleData) AND isGreaterThanCurrentTime(program.scheduleData.endTime) = false
        rawResponse.removeChild(liveEventsContainer)
        liveEventsContainer = invalid
      end if
    end if
  end if

  return liveEventsContainer
End Function


' Requests additional content containers when user scrolls near the bottom
' Implements pagination by loading more containers as needed
' @param currFocusRow - The current row index where user focus is
' @param screen - The screen node requesting additional containers
Function makeAdditionalContainersRequestConditionally(currFocusRow, screen) as Void
  if screen <> invalid AND screen.containerPaginationStatus <> "pending"
    content = screen.content

    if isNode(content) = false
      return
    end if

    containerCount = content.getChildCount()
    if containerCount - currFocusRow > 5
      return
    end if

    screen.containerPaginationStatus = "pending"

    ' For tensor API, we need to pass as empty string for homescreen
    if screen.contentMode = m.constants.ui.contentMode.homescreen
      contentMode = ""
    else
      contentMode = screen.contentMode
    end if

    ' Use groupCursor from content if available, otherwise fall back to containerCount
    groupStart = containerCount
    if content.groupCursor <> invalid
      groupStart = content.groupCursor
    end if

    params = {
      group_start: groupStart
      group_size: m.constants.performance.categoryGridList.numContainers
      contents_limit: m.constants.performance.categoryGridList.initialBlockSize
      content_mode: contentMode
    }

    isKidsMode = shouldKidsModeBeSentToServer()

    options = {
      params: params
      headers: {}
    }
    homeScreenReqInfo = m.CmsApi.createHomeScreenReqInfo(isKidsMode, options)
    m.makeRequest({
      url: homeScreenReqInfo.url
      requestType: m.constants.reqNames.getHomescreen
      options: homeScreenReqInfo.options
      successCallback: onAdditionalContainersSuccessResponse
      errorCallback: onAdditionalContainersErrorResponse
      silenceCallbackWarnings: true
      responseType: "node"
      isSignedInUser: isLoggedInUser()
      uiMode: m.uiMode
      screenId: screen.id
    })
  end if
End Function


' Handles successful response from additional containers request
' Appends new containers immediately if not scrolling, otherwise queues them
' @param response - Response node containing additional content containers
Function onAdditionalContainersSuccessResponse(response)
  screen = getScreenFromStackById(response.screenId)
  if screen <> invalid
    scrollingStatus = screen.listScrollingStatus

    if scrollingStatus = false
      appendPaginatedContainersToScreen(screen, response)
    else
      m.paginatedContentQueue = response
    end if
  end if
End Function


Function onAdditionalContainersErrorResponse(response)
  screen = getScreenFromStackById(response.screenId)
  if screen <> invalid
    ' Resetting the state so that we can retry on the next scroll down.
    screen.containerPaginationStatus = "complete"
  end if
End Function


' Appends paginated content containers to the screen
' Updates pagination status and triggers video preview debounce if needed
' @param screen - The screen node to append containers to
' @param response - Response node containing content containers to append
Function appendPaginatedContainersToScreen(screen, response)
  content = screen.content

  if content <> invalid AND isNode(response) = true AND response.getChildCount() > 0
    items = response.getChildren(-1, 0)
    content.appendChildren(items)

    ' Update groupCursor from paginated response for next pagination request
    if response.groupCursor <> invalid
      content.groupCursor = response.groupCursor
    end if

    screen.hasNewContainers = true
    if m.videoPreviewDebounce.control = "stop"
      m.videoPreviewDebounce.control = "start"
    end if
    if response.groupCursor = invalid
      screen.containerPaginationStatus = "finished"
    else
      screen.containerPaginationStatus = "complete"
    end if
  else
    screen.containerPaginationStatus = "finished"
  end if
End Function
