' gets the categoryPanelListScreen from the screen cache if it exists, otherwise creates a new categoryPanelListScreen
' @constants: assocArray, constants as set in Constants.brs and updated in the hotpatch
' @sendNavigationLoadEvents: boolean, when the page is loaded, do the navigation to page, pageload events needs to be sent
' @categoryId: string, provide a category ID if you wish to jump to specific category as soon as the screen is displayed
Function showCategoryPanelListScreen(constants, sendNavigationLoadEvents = true, categoryId = invalid)
  tubiLog("CategoryPanelListScreenHelpers.showCategoryPanelListScreen")
  categoryPanelListScreen = getFromScreenCache(m.constants.ui.screenIds.categoryPanelListScreen)
  if categoryPanelListScreen <> invalid
    if categoryId <> invalid
      categoryPanelListScreen.jumpToItemByID = categoryId
    end if

    if sendNavigationLoadEvents = false
      pushScreen(categoryPanelListScreen, false, false)
    else
      pushScreen(categoryPanelListScreen, true, true)
    end if
  else
    
    panelScreen = CreateObject("roSGNode", "CategoryPanelListScreen")
    panelScreen.screenLevel = m.constants.ui.screenLevels.categoryPanelListScreen
    pageType = "category_list_page"

    panelScreen.id = m.constants.ui.screenIds.categoryPanelListScreen
    panelScreen.trackingLoadStartTime = UpTime(0)
    panelScreen.observeFieldScoped("backgroundUriList", "onCategoryScreenBackgroundChange")
    panelScreen.observeFieldScoped("refreshContent", "onRefreshCategoryPanelListSignal")
    panelScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
    panelScreen.observeFieldScoped("componentInteractionInfo", "onComponentInteractionInfoChange")
    panelScreen.observeFieldScoped("contentFocused", "onCategoryListContentFocused")
    panelScreen.observeFieldScoped("categoryContentSelected", "onCategoryPanelContentSelected")
    panelScreen.observeFieldScoped("contentToPlay", "onContentToPlay")
    panelScreen.observeFieldScoped("categoryBatchIndex", "onCategoryPanelBatchIndexChange")
    panelScreen.observeFieldScoped("visible", "onCategoryPanelListScreenVisibleChange")
    panelScreen.observeFieldScoped("failedJumpToItemByID", "onJumpToIDFailed")

    ' Stores state if the categoryPanelScreen is in the process of refreshing/fetching content from API.
    ' Is used to determine when to send the PageLoad analytics event (don't send on refresh)
    m.refreshingCategoryDetailsCache = false

    if categoryId <> invalid
      '//the jump will happen after the content has loaded
      panelScreen.jumpToItemByID = categoryId
    end if
    panelScreen.isLoading = true

    panelScreen.trackingPageInfo = {
      pageType: pageType
      pageValues: {}
    }

    displayDefaultBackground()
    setInScreenCache(panelScreen)

    if sendNavigationLoadEvents = false
      pushScreen(panelScreen, false, false)
    else
      pushScreen(panelScreen, true, false)  ' don't send page load tracking until we resolve channel content
    end if

    getCategoryPanelListDataFromServer(panelScreen)
  end if
End Function


Function onCategoryPanelListScreenVisibleChange(msg)
  tubiLog("CategoryPanelListScreenHelpers.onCategoryPanelListScreenVisibleChange")
  categoryPanelListScreen = msg.getRoSGNode()
  if categoryPanelListScreen.visible = false
    '//Once the screen is no longer visible, then remove the content of the categories from the cache
    '// to ensure app's memory use does not impact performance
    deleteScreenContentCache(categoryPanelListScreen.id)
  end if
End Function


' Call the backend to get the data for the category panel represented in the params
' @param categoryId:String - The categorey ID
' @param index - The batch index, the start point where the endpoint should start providing data.
Function fetchCategoryPanelDetails(categoryId, index = 0)
  tubiLog("CategoryPanelListScreenHelpers.fetchCategoryPanelDetails")
  isKidsMode = shouldKidsModeBeSentToServer()

  options = {}
  params = {}
  params["content_mode"] = ""

  if index <> 0
    params["cursor"] = index
    params["contents_limit"] =  m.constants.performance.categoryGridList.lazyLoadBatchSize
    params["expanded"] = true
  end if

  options.params = params

  if categoryId <> m.constants.ui.categoryIds.networks
    categoryReqInfo = m.CmsApi.createCategoryReqInfo(categoryId, isKidsMode, options, invalid, m.constants.ui.screenIds.categoryDetailsScreen)

    m.makeRequest({
      url: categoryReqInfo.url
      requestType: m.constants.reqNames.getCategoryDetailsScreen
      options: categoryReqInfo.options
      successCallback: onCategoryDetailPanelResponse
      errorCallback: onCategoryDetailPanelError
      responseType: "node"
      isSignedInUser: isLoggedInUser()
      uiMode: m.uiMode
    })
  else
    categoryReqInfo = m.cmsApi.createCategoriesListReqInfo(isKidsMode)

    m.makeRequest({
      url: categoryReqInfo.url
      requestType: m.constants.reqNames.getCategoriesListScreen
      options: categoryReqInfo.options
      successCallback: onCategoryDetailPanelResponse
      errorCallback: onCategoryDetailPanelError
      responseType: "node"
      screenId: m.constants.ui.screenIds.channelListScreen
    })
  end if
End Function


' Handler function that handles the backend's response to getting the data for the category panel
'   This usually happens the user focuses on a title of category on the category screen.
' @param categoryContent:Node - The content data for the category panel
Function onCategoryDetailPanelResponse(categoryContent)
  tubiLog("CategoryPanelListScreenHelpers.onCategoryDetailPanelResponse")
  screen = getCurrentScreen()
  focusedItem = screen.contentFocused

  if screen.id = m.constants.ui.screenIds.categoryPanelListScreen AND focusedItem <> invalid
    ' the category details screen is still the top screen after receiving the response
    responseItemsCount = 0
    if categoryContent <> invalid
      responseItemsCount = categoryContent.getChildCount()

      if categoryContent.id = m.constants.ui.contentIds.channelList
        '//if the ID is channelList, then parse the backend's response to switch to networks
        if focusedItem.id = m.constants.ui.categoryIds.networks
          categoryContent.id = focusedItem.id
          categoryContent.title = focusedItem.title
          categoryContent.slug = focusedItem.slug
        end if
      end if

    end if
    

    if categoryContent <> invalid AND focusedItem.id = categoryContent.id
      
      if responseItemsCount > 0
        setInContentCache(categoryContent, screen.id)

        screen.isCategoryLoading = false

        if categoryContent.sponsorImages <> invalid AND categoryContent.sponsorImages.pixels <> invalid AND categoryContent.sponsorImages.pixels["container_details"] <> invalid
          '//When a sponsored container is made visible, then call the pixels
          sponsorPixels = categoryContent.sponsorImages.pixels["container_details"]
          sendSponsorPixels(sponsorPixels)
        end if

        if screen.categoryContent = invalid 'first time
          screen.categoryContent = categoryContent
          screen.shouldLoadCategoryContent = true
        else
          responseChildren = categoryContent.getChildren(-1, 0)
          screen.categoryContent.appendChildren(responseChildren)
        end if

        'Total received content is less than batchsize that means we have reached the maximum available
        'Number of contents on the screen + next batchsize is more than maximum limit
        if responseItemsCount <  m.constants.performance.categoryGridList.lazyLoadBatchSize OR (screen.categoryContent.getChildCount() +  m.constants.performance.categoryGridList.lazyLoadBatchSize > m.constants.performance.categoryGridList.finalLazyLoadSize)
          screen.isCategoryFullyLoaded = true
        else
          screen.isCategoryFullyLoaded = false
        end if

      else if categoryContent <> invalid AND responseItemsCount = 0 AND screen.categoryContent <> invalid AND  screen.isCategoryLoading = false
        screen.isCategoryFullyLoaded = true
      else
        '//there is no content in the container/category response and there is no content already existing in the category UI (panel)
        
        screen.isCategoryLoading = true

        showCategoryDetailPanelError(invalid, true)

        ' After the modal is dismissed, the categoryPanelScreen is given focus.
        ' If there is content that is not valid (i.e. responseItemsCount<=0 or categoryContent = invalid), 
        ' another request will be made to fetch the content
        ' for the categoryPanelScreen. Since we've already established there is no content, we
        ' can prevent another call from taking place by setting the screen's content to invalid.
        screen.categoryContent = invalid
      end if

      if m.refreshingCategoryDetailsCache = false
        loadTime = Int((Uptime(0) - screen.categoryTrackingLoadStartTime) * 1000) 'in ms
        screenTrackingLoad(screen.categoryTrackingPageInfo, loadTime) 
      else
        m.refreshingCategoryDetailsCache = false
      end if
    end if
  end if
End Function


' @error: assocArray, with single key/value, "code"/<<error code as integer>>
Function onCategoryDetailPanelError(error)
  showCategoryDetailPanelError(error, false)
End Function


' @error: assocArray, with single key/value, "code"/<<error code as integer>>
' @bContentEmptyError: boolean, true indicates that the error is due to having no content in the category/channel
Function showCategoryDetailPanelError(error, bContentEmptyError = false)
  tubiLog("CategoryPanelListScreenHelpers.showCategoryDetailPanelError")
  topScreen = getCurrentScreen()

  categoryPanelScreen = invalid
  ' If topScreen.id does not = the ID of a categoryPanelScreen, another screen (like the sign in screen)
  ' has been pushed on top of the categoryPanelScreen. Hold off on removing the screen and
  ' displaying an error. When the user traverses back through the navigation stack, the
  ' categoryPanelScreen will eventually be revealed and if there is still no content, then
  ' an error modal will be displayed.
  if topScreen.id = m.constants.ui.screenIds.categoryPanelListScreen
    categoryPanelScreen = topScreen

    doShowError = true

    if categoryPanelScreen.categoryContent <> invalid AND categoryPanelScreen.categoryContent.getChildCount() > 0
      doShowError = false
    end if

    if doShowError = true
      ' categoryPanelScreen is created/pushed in showcategoryPanelScreen, since there is no content,
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
          pageOneof: m.Tracking.getAnalyticsPage(topScreen.categoryTrackingPageInfo.pageType, topScreen.categoryTrackingPageInfo.pageValues)
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
      showErrorModal(modalInfo, invalid, invalid, refreshCategoryPanelListScreen, categoryPanelScreen) 
    else 'lazy loading so make the isCategoryFullyLoaded = true
      categoryPanelScreen.isCategoryFullyLoaded = true
    end if

  else
    categoryPanelScreen = getScreenFromStackById(m.constants.ui.screenIds.categoryPanelListScreen)
  end if


  'if categorydetailScreen is lazy loading then send the tracking event only for first batch
  if categoryPanelScreen <> invalid AND categoryPanelScreen.categoryBatchIndex = 0 'first batch has failed, so send page load event
    loadTime = Int((Uptime(0) - categoryPanelScreen.categoryTrackingLoadStartTime) * 1000) 'in ms
    screenTrackingLoad(categoryPanelScreen.categoryTrackingPageInfo, loadTime, false)
  end if
End Function


' The list of the categories (on the left side of the CategoryPanelListScreen) needs to be refreshed.
' @param panelScreen, The CategoryPanelListScreen
Function refreshCategoryPanelListScreen(panelScreen)
  tubiLog("CategoryPanelListScreenHelpers.refreshCategoryPanelListScreen")

  sCategoryID = panelScreen.categoryId
  m.refreshingChannelGridCache = true
  panelScreen.isLoading = true
  getCategoryPanelListDataFromServer(panelScreen)

  panelScreen.jumpToItemByID = sCategoryID
End Function


' The category panel (on the right side of the CategoryPanelListScreen) needs to be refreshed.
' @param screen, The CategoryPanelListScreen
Function refreshCategoryPanelListDetailScreen(screen)
  'If the user selects networks from CategoryList Screen we are showing the ChannelListScreen with list of channels.
  focusedItem = screen.contentFocused
  
  if focusedItem <> invalid
    screen.isCategoryLoading = true
    categoryContent = getFromContentCache(focusedItem.id)
    if categoryContent <> invalid AND categoryContent.getChildCount() > 0 AND shouldRefresh(categoryContent) <> true
      '//If the content already exists in the cache and is still fresh, then no need to fetch the content
      onCategoryDetailPanelResponse(categoryContent)
    else
      fetchCategoryPanelDetails(focusedItem.id)
    end if
  end if
End Function


Function onCategoryListContentFocused(msg)
  tubiLog("CategoryPanelListScreenHelpers.onCategoryListContentFocused")
  screen = msg.getRoSGNode()
  refreshCategoryPanelListDetailScreen(screen)
End Function


' Handler when the content (video title) from the CategoryDetailsPanel is selected
Function onCategoryPanelContentSelected(msg)
  tubiLog("CategoryPanelListScreenHelpers.onCategoryPanelContentSelected")
  categoryPanelScreen = msg.getRoSGNode()

  '//The general category that is currently focused in the left panel. The titles of this category are displaying in the right panel.
  categoryContent = categoryPanelScreen.categoryContent
  '//The content item (video or network) that was selected within the right panel
  categoryItemSelected = msg.getData()

  '//Keep track of the sponsored exposure ID if the selected video is within a sponsored container
  if categoryContent <> invalid AND categoryContent.sponsorExp <> invalid
    m.videoSponsorExposureId = categoryContent.sponsorExp
  end if

  if categoryContent.id = m.constants.ui.categoryIds.networks
    showCategoryDetailsScreen(categoryItemSelected) 
  else
    playbackSource = {
      "srcForAnalytic": m.constants.player.playbackSource.unknown
      "srcForAds": m.constants.player.playbackOrigin.container
      "playbackContainer": categoryContent.id
    }
    showDetailScreen(categoryItemSelected, true, invalid, invalid, playbackSource)
  end if
End Function


Function onCategoryPanelBatchIndexChange(msg)
  tubiLog("CategoryPanelListScreenHelpers.onCategoryPanelBatchIndexChange")
  categoryPanelScreen = msg.getRoSGNode()
  index = msg.getData()
  categoryContent = invalid

  if categoryPanelScreen <> invalid AND categoryPanelScreen.categoryContent <> invalid
    categoryContent = categoryPanelScreen.categoryContent
  end if

  m.refreshingCategoryDetailsCache = true

  if index <> 0 AND categoryContent <> invalid
    'fetch the content if screen is not fully loaded or a total refresh has been requested.
    if categoryPanelScreen.isCategoryFullyLoaded <> true
      fetchCategoryPanelDetails(categoryContent.id, index)
    end if
  else
    '//If index is 0, then refresh the page
    categoryPanelScreen.categoryContent = invalid
    categoryPanelScreen.isCategoryLoading = true
    fetchCategoryPanelDetails(categoryContent.id)
  end if
End Function


Function onRefreshCategoryPanelListSignal(msg)
  tubiLog("CategoryPanelListScreenHelpers.onRefreshCategoryPanelListSignal")
  panelScreen = msg.getRoSGNode()
  refreshCategoryPanelListScreen(panelScreen)
End Function


' Call the backend to get the list of categories to be displayed on the left hand side CategoryPanelList
' @param: screen - The CategoryPanelListScreen
Function getCategoryPanelListDataFromServer(screen)
  tubiLog("CategoryPanelListScreenHelpers.getCategoryPanelListDataFromServer")
  if screen <> invalid AND screen.id = m.constants.ui.screenIds.categoryPanelListScreen
    shouldKidsModeBeSentToServer = shouldKidsModeBeSentToServer()
    categoriesListReqInfo = m.cmsApi.createCategoriesListReqInfo(shouldKidsModeBeSentToServer)

    m.makeRequest({
      url: categoriesListReqInfo.url
      requestType: m.constants.reqNames.getCategoriesListScreen
      options: categoriesListReqInfo.options
      successCallback: onCategoriesPanelListSuccess
      errorCallback: onCategoriesPanelListError
      responseType: "node"
      screenId: screen.id
    })
  end if
End Function


' @response: roSGNode, a contentNode with children for each category or channel
Function onCategoriesPanelListSuccess(response)
  tubiLog("CategoryPanelListScreenHelpers.onCategoriesPanelListSuccess")

  if response <> invalid
    screenId = m.constants.ui.screenIds.categoryPanelListScreen
    screen = getFromScreenCache(screenId)

    if screen <> invalid
      screen.isLoading = false
      screen.content = response
      screen.shouldLoadContent = true

      if m.refreshingChannelGridCache <> true
        loadTime = Int((Uptime(0) - screen.trackingLoadStartTime) * 1000) 'in ms
        screenTrackingLoad(screen.trackingPageInfo, loadTime)
      end if
    end if
  end if
End Function


'//If the deeplink setting of jumpToCategoryId failed to set focus on a specific category, then 
'//this might mean that the category does not exist in the category list. Try to load the category in a separate category page
Function onJumpToIDFailed(msg)
  tubiLog("CategoryPanelListScreenHelpers.onJumpToIDFailed")
  jumpToCategoryId = msg.getData()

  contentNode = CreateObject("roSGNode", "CategoryContentNode")
  contentNode.id = jumpToCategoryId
  showCategoryDetailsScreen(contentNode, false) 
End Function


Function onCategoriesPanelListError(errorInfo)
  tubiLog("CategoryPanelListScreenHelpers.onCategoriesPanelListError")

  screen = getFromScreenCache(errorInfo.screenId)

  if screen <> invalid AND screen.id = m.constants.ui.screenIds.categoryPanelListScreen
    'the categoryPanelListScreen will be popped from the stack after the user closes the error modal

    'delete the screen from the screen cache so that the next time the user attempts to load the page, the page will be loaded
    'from scratch again. Otherwise an empty page will load and content will never be fetched.
    deleteFromScreenCache(screen.id)

    sErrorType = m.constants.errors.context.categoriesScreen
    prelimMessage = getTranslation("screenCategories_error_retrieve_message")

    errorCode = getUserFacingErrorCode(sErrorType, m.constants.errors.subtypes.fetchError, errorInfo.code)

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
      message: getErrorMessage(prelimMessage, errorCode)
      openTrackEvent: dialogEvent
      trackingTask: m.trackingLoggingTask
    }

    showErrorModal(modalInfo, invalid, invalid, removeTopScreen)
    loadTime = Int((Uptime(0) - screen.trackingLoadStartTime) * 1000) 'in ms
    screenTrackingLoad(screen.trackingPageInfo, loadTime, false)
  end if
End Function
