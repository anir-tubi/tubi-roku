'''''''''''''''''''''
' showCategoryDetailsScreen
'
' @content: roSGNode, a content node for a single pieces of content, might be a video or top level series
' @sendNavigationLoadEvents: boolean, when the page is loaded, do the navigation to page, pageload events needs to be sent
' @contentMode: string, the value from constants.ui.contentMode to be sent as param to the tensor request
Function showCategoryDetailsScreen(content, sendNavigationLoadEvents = true, contentMode = "")
  tubiLog("CategoryDetailsScreenHelpers.showCategoryDetailsScreen")

  categoryDetailsScreen = CreateObject("roSGNode", "CategoryDetailsScreen")
  categoryDetailsScreen.observeFieldScoped("contentSelected", "onCategoryContentSelected")
  categoryDetailsScreen.observeFieldScoped("backgroundUriList", "onCategoryScreenBackgroundChange")
  categoryDetailsScreen.observeFieldScoped("sponsorshipBackground", "onSponsorshipBackgroundChanged")
  categoryDetailsScreen.observeFieldScoped("focusedChild", "onCategoryDetailsScreenFocusChanged")
  categoryDetailsScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
  categoryDetailsScreen.observeFieldScoped("categoryBatchIndex", "onCategoryBatchIndexChange")
  categoryDetailsScreen.observeFieldScoped("transportVoiceResponse", "onTransportVoiceResponse")
  categoryDetailsScreen.observeFieldScoped("contentToPlay", "onContentToPlay")
  categoryDetailsScreen.observeFieldScoped("backButtonPressed", "onCategoryDetailsScreenBackButtonPressed")
  if isVideoPreviewOn() = true
    categoryDetailsScreen.observeFieldScoped("contentFocused", "onCategoryContentFocused")
  end if
  categoryDetailsScreen.id = m.constants.ui.screenIds.categoryDetailsScreen
  categoryDetailsScreen.categoryId = content.id
  categoryDetailsScreen.isLoading = true

  categoryDetailsScreen.trackingPageInfo = {
    pageType: "category_page"
    pageValues: {
      category_slug: content.id
    }
  }

  displayDefaultBackground()

  if sendNavigationLoadEvents = true
    ' don't send page load tracking until category details content is returned from the API
    pushScreen(categoryDetailsScreen, true, false)
  else
    pushScreen(categoryDetailsScreen, false, false)
  end if

  fetchCategoryDetails(content, 0, contentMode)

End Function


'@categoryId: string, categoryId(continue_watching, queue) of the category detail screen
Function isCategoryDetailScreenInStack(categoryId)
  screensInStack = getScreensInStack()

  for each screen in screensInStack
    if screen.id = m.constants.ui.screenIds.categoryDetailsScreen
      if screen.categoryId = categoryId
        return true
      end if
    end if
  end for

  return false
End Function


Function onCategoryDetailsScreenFocusChanged(msg)
  tubiLog("CategoryDetailsScreenHelpers.onCategoryDetailsScreenFocusChanged")
  categoryDetailsScreen = msg.getRoSGNode()
  if categoryDetailsScreen.isInFocusChain() = true

    '//If the categoryDetailsScreen regains focus, then ensure the sponsored background is correct.
    ' Important when the BACK button is used and the categoryDetailsScreen has sponsored content.
    setSponsorshipBackground(categoryDetailsScreen.sponsorshipBackground)
  end if
End Function


Function onCategoryContentSelected(msg)
  tubiLog("CategoryDetailsScreenHelpers.onCategoryContentSelected")
  categoryDetailsScreen = msg.getRoSGNode()

  '//Keep track of the sponsored exposure ID if the selected video is within a sponsored container
  categoryContent = categoryDetailsScreen.content
  if categoryContent <> invalid AND categoryContent.sponsorExp <> invalid
    m.videoSponsorExposureId = categoryContent.sponsorExp
  end if

  playbackSource = {
    "srcForAnalytic": m.constants.player.playbackSource.unknown
    "srcForAds": m.constants.player.playbackOrigin.container
    "playbackContainer": categoryContent.id
  }

  processUserContentSelection(categoryDetailsScreen.contentSelected, categoryDetailsScreen, playbackSource)
End Function


Function onCategoryBatchIndexChange(msg)
  tubiLog("CategoryDetailsScreenHelpers.onCategoryBatchIndexChange")
  categoryDetailsScreen = msg.getRoSGNode()
  index = msg.getData()
  categoryContent = invalid

  if categoryDetailsScreen <> invalid AND categoryDetailsScreen.content <> invalid
    categoryContent = categoryDetailsScreen.content
  end if

  ' Stores state if the categoryDetailsScreen is in the process of refreshing/fetching content from API.
  ' Is used to determine when to send the PageLoad analytics event (don't send on refresh)
  m.refreshingCategoryDetailsCache = true

  if index <> 0

    'fetch the content if screen is not fully loaded or a total refresh has been requested.
    if categoryDetailsScreen.isFullyLoaded <> true
      fetchCategoryDetails(categoryContent, index)
    end if
  else
    '//If index is 0, then refresh the page
    categoryDetailsScreen.content = invalid
    categoryDetailsScreen.isLoading = true
    fetchCategoryDetails(categoryContent)
  end if
End Function


' @content: roSGNode, CategoryContentNode
' @index: integer, the index from which to fetch content from within the category. For instance, if index = 12, the content we fetch will start from the 12th content in the category
' @contentMode: string, the value from constants.ui.contentMode to be sent as param to the tensor request
Function fetchCategoryDetails(content, index = 0, contentMode = "")
  tubiLog("CategoryDetailsScreenHelpers.fetchCategoryDetails")
  isKidsMode = shouldKidsModeBeSentToServer()

  if content <> invalid
    categoryId = content.id
    ' TODO: FIND A BETTER WAY TO SOLVE THE u_continue_watching issue
    if content.id = "u_continue_watching"
      categoryId = "continue_watching"
    end if

    ' Reset fetch completed flags for initial load only
    screen = getCurrentScreen()
    if screen <> invalid AND screen.id = m.constants.ui.screenIds.categoryDetailsScreen AND index = 0
      screen.contentFetchCompleted = false
      screen.adContentFetchCompleted = false
      screen.adContent = []

      ' Request thematic takeover ads (only for initial load, not lazy loading)
      if isKidsUIOn() = false AND isParentalControlsAdultLevel() = true
        aAdTypes = [m.constants.adTypes.thematicTakeover]
        createHomeScreenAdRequest(m.constants.ui.screenIds.categoryDetailsScreen, onCategoryDetailsAdSuccess, aAdTypes, onCategoryDetailsAdError)
      else
        ' In kids mode, skip ad request
        screen.adContent = []
        screen.adContentFetchCompleted = true
      end if
    end if

    options = {}
    params = {}

    ' content_mode is mandatory param and its value needs to be passed as empty for fetching homescreen content
    ' For tensor API, we need to pass as empty string for homescreen
    if contentMode = m.constants.ui.contentMode.homescreen
      params["content_mode"] = ""
    else
      params["content_mode"] = contentMode
    end if

    if index <> 0
      params["cursor"] = index
      params["contents_limit"] = m.constants.performance.categoryGridList.lazyLoadBatchSize
      params["expanded"] = true
    end if

    options.params = params

    categoryReqInfo = m.CmsApi.createCategoryReqInfo(categoryId, isKidsMode, options, invalid, m.constants.ui.screenIds.categoryDetailsScreen)

    m.makeRequest({
      url: categoryReqInfo.url
      requestType: m.constants.reqNames.getCategoryDetailsScreen
      options: categoryReqInfo.options
      successCallback: onCategoryDetailResponse
      errorCallback: onCategoryDetailError
      responseType: "node"
      isSignedInUser: isLoggedInUser()
      uiMode: m.uiMode
      analyticsScreenId: m.constants.ui.screenIds.categoryDetailsScreen
    })
  end if
End Function


Function onCategoryDetailResponse(categoryContent)
  tubiLog("CategoryDetailsScreenHelpers.onCategoryDetailResponse")
  screen = getCurrentScreen()

  if screen.id = m.constants.ui.screenIds.categoryDetailsScreen
    ' the category details screen is still the top screen after receiving the response
    responseItemsCount = 0
    if categoryContent <> invalid
      responseItemsCount = categoryContent.getChildCount()
    end if

    if responseItemsCount > 0
      screen.isLoading = false

      ' For initial load (first time), wait for both content and ads to be ready
      if screen.content = invalid
        ' Set content on screen but don't trigger load until ads are ready
        screen.content = categoryContent
        screen.contentFetchCompleted = true
        checkIfCategoryDetailsContentIsReady(screen)
      else
        ' Lazy loading - append directly (no need to wait for ads)
        responseChildren = categoryContent.getChildren(-1, 0)
        screen.content.appendChildren(responseChildren)
      end if

      'Total received content is less than batchsize that means we have reached the maximum available
      'Number of contents on the screen + next batchsize is more than maximum limit
      if responseItemsCount < m.constants.performance.categoryGridList.lazyLoadBatchSize OR (screen.content.getChildCount() + m.constants.performance.categoryGridList.lazyLoadBatchSize > m.constants.performance.categoryGridList.finalLazyLoadSize)
        screen.isFullyLoaded = true
      else
        screen.isFullyLoaded = false
      end if


    else if categoryContent <> invalid AND responseItemsCount = 0 AND screen.content <> invalid AND screen.isLoading = false
      screen.isFullyLoaded = true
    else
      screen.isLoading = true

      '//if no content, then display appropriate empty modal
      if categoryContent <> invalid AND categoryContent.id = m.constants.ui.categoryIds.queue
        showEmptyContentModal(screen)
      else
        showCategoryDetailError(invalid, true)
      end if

      ' After the modal is dismissed, the categoryDetailsScreen is given focus.
      ' If there is content that is not valid, another request will be made to fetch the content
      ' for the categoryDetailsScreen. Since we've already established there is no content, we
      ' can prevent another call from taking place by setting the screen's content to invalid.
      screen.content = invalid
    end if

    if m.refreshingCategoryDetailsCache <> true
      loadTime = Int((Uptime(0) - screen.trackingLoadStartTime) * 1000) 'in ms
      if categoryContent <> invalid
        trackingPageInfo = screen.trackingPageInfo
        trackingPageInfo.pageValues.personalization_id = categoryContent.personalizationId
        screen.trackingPageInfo = trackingPageInfo
      end if
      screenTrackingLoad(screen.trackingPageInfo, loadTime)
    else
      m.refreshingCategoryDetailsCache = false
    end if
  end if
End Function


Function showEmptyContentModal(screen)
  tubiLog("CategoryDetailsScreenHelpers.showEmptyContentModal")

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
  tubiLog("CategoryDetailsScreen.removeTopScreen")
  topScreen = getCurrentScreen()

  ' Do not send navigation tracking info when popping the screen, as navigation tracking wasn't
  ' sent at the time of pushing the screen on the stack, so that the load time could be calculated
  ' and added to the tracking events on successful fetching of the screen contents. In the case of
  ' an error we do not want events showing navigation back to the original screen if there were no
  ' events logged showing navigation to the categoryDetailsScreen.
  popScreen(false, false)
  topScreen = getCurrentScreen()

  sideNavId = m.constants.ui.screenIdToSideNavId[topScreen.id]
  focusSideNavOption(sideNavId)
End Function


' @error: assocArray, with single key/value, "code"/<<error code as integer>>
Function onCategoryDetailError(error)
  showCategoryDetailError(error, false)
End Function


' @error: assocArray, with single key/value, "code"/<<error code as integer>>
' @bContentEmptyError: boolean, true indicates that the error is due to having no content in the category/channel
Function showCategoryDetailError(error, bContentEmptyError = false)
  tubiLog("CategoryDetailsScreenHelpers.showCategoryDetailError")
  topScreen = getCurrentScreen()

  categoryDetailsScreen = invalid
  ' If topScreen.id does not = the ID of a categoryDetailsScreen, another screen (like the sign in screen)
  ' has been pushed on top of the categoryDetailsScreen. Hold off on removing the screen and
  ' displaying an error. When the user traverses back through the navigation stack, the
  ' categoryDetailsScreen will eventually be revealed and if there is still no content, then
  ' an error modal will be displayed.
  if topScreen.id = m.constants.ui.screenIds.categoryDetailsScreen
    categoryDetailsScreen = topScreen

    doShowError = true

    if categoryDetailsScreen.content <> invalid AND categoryDetailsScreen.content.getChildCount() > 0
      doShowError = false
    end if


    if doShowError = true
      ' categoryDetailsScreen is created/pushed in showCategoryDetailsScreen, since there is no content,
      ' removing it from the stack will occur after the user closes the modal.
      code = ""
      if error <> invalid AND error.code <> invalid
        code = error.code.toStr()
      end if

      errorCode = getUserFacingErrorCode(m.constants.errors.context.categoryDetailsScreen, m.constants.errors.subtypes.fetchError, code)

      dialogEvent = {
        type: "dialog"
        values: {
          dialog_type: "NETWORK_ERROR" 'DialogType enum
          pageOneof: m.Tracking.getAnalyticsPage(topScreen.trackingPageInfo.pageType, topScreen.trackingPageInfo.pageValues)
          dialog_action: "SHOW"
          dialog_sub_type: errorCode
        }
      }

      sErrorTitle = ""
      sErrorMessage = getTranslation("error_noGetChannels_description")
      if bContentEmptyError = true
        sErrorTitle = getTranslation("dialog_errorOops_title")
        sErrorMessage = getTranslation("error_noContent_description")
      end if

      modalInfo = {
        title: sErrorTitle
        message: getErrorMessage(sErrorMessage, errorCode)
        openTrackEvent: dialogEvent
        trackingTask: m.trackingLoggingTask
      }

      showErrorModal(modalInfo, invalid, invalid, removeTopScreen)
    else 'lazy loading so make the isFullyLoaded = true
      categoryDetailsScreen.isFullyLoaded = true
    end if

  else
    categoryDetailsScreen = getScreenFromStackById(m.constants.ui.screenIds.categoryDetailsScreen)
  end if


  'if categorydetailScreen is lazy loading then send the tracking event only for first batch
  if categoryDetailsScreen <> invalid AND categoryDetailsScreen.categoryBatchIndex = 0 'first batch has failed, so send page load event
    loadTime = Int((Uptime(0) - categoryDetailsScreen.trackingLoadStartTime) * 1000) 'in ms
    screenTrackingLoad(categoryDetailsScreen.trackingPageInfo, loadTime, false)
  end if

End Function


Function onCategoryDetailsScreenBackButtonPressed(msg)
  tubiLog("CategoryDetailsScreenHelpers.onCategoryDetailsScreenBackButtonPressed")
  screen = msg.getRoSGNode()

  if screen <> invalid
    previousScreen = getHiddenScreen(1)
    if previousScreen <> invalid AND previousScreen.subType() = "HomeScreen"
      jumpToParentScreenContentByID(screen.contentFocusedId, screen.categoryId, previousScreen.id)
    end if
  end if

  ' Stopping video preview when user navigates back from category details screen.
  stopVideoPreview()

  onKeyEvent("back", true)
End Function


' Handles successful thematic takeover ad response for CategoryDetailsScreen
' @param response: assocarray with screenId and data array
Function onCategoryDetailsAdSuccess(response)
  tubiLog("CategoryDetailsScreenHelpers.onCategoryDetailsAdSuccess")

  screen = getCurrentScreen()
  if screen <> invalid AND screen.id = m.constants.ui.screenIds.categoryDetailsScreen
    screen.adContent = filterThematicTakeovers(response)
    screen.adContentFetchCompleted = true
    checkIfCategoryDetailsContentIsReady(screen)
  end if
End Function


' Handles thematic takeover ad error response for CategoryDetailsScreen
' @param response: error response
Function onCategoryDetailsAdError(response)
  tubiLog("CategoryDetailsScreenHelpers.onCategoryDetailsAdError")

  screen = getCurrentScreen()
  if screen <> invalid AND screen.id = m.constants.ui.screenIds.categoryDetailsScreen
    ' On error, proceed without ads
    screen.adContent = []
    screen.adContentFetchCompleted = true
    checkIfCategoryDetailsContentIsReady(screen)
  end if
End Function


' Checks if both content and ad fetches are complete for CategoryDetailsScreen
' If both complete, applies thematic theme and sets screen content
' @param screen: CategoryDetailsScreen node
Function checkIfCategoryDetailsContentIsReady(screen) as Void
  tubiLog("CategoryDetailsScreenHelpers.checkIfCategoryDetailsContentIsReady")

  if screen = invalid OR screen.id <> m.constants.ui.screenIds.categoryDetailsScreen
    return
  end if

  bContentLoaded = (screen.contentFetchCompleted = true)
  bAdContentLoaded = (screen.adContentFetchCompleted = true)

  if bContentLoaded = true AND bAdContentLoaded = true
    categoryContent = screen.content
    if categoryContent <> invalid
      ' Apply thematic takeover theme if applicable
      applyThematicThemeToContent(categoryContent, screen.adContent)

      ' Fire sponsor pixels if present (original behavior)
      if categoryContent.sponsorImages <> invalid AND isNonEmptyArray(categoryContent.sponsorImages.pixels) = true
        sponsorPixels = categoryContent.sponsorImages.pixels
        sendAdPixels(sponsorPixels)

        ' Clear pixels after sending
        categoryContent.sponsorImages.pixels = invalid
      end if

      ' Trigger content load
      screen.shouldLoadContent = true
    end if
  end if
End Function
