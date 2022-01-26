' gets the ChannelListScreen from the screen cache if it exists, otherwise wraps showChannelGridScreen()
' @constants: assocArray, constants as set in Constants.brs and updated in the hotpatch
' @sPageSource: string, What page is calling this function? This string is what is displayed on the top of the page
'                       to let the user know what page they will go to when they click the back button
Function showChannelListScreen(constants, sPageSource)
  channelListScreen = getFromScreenCache(m.constants.ui.screenIds.channelListScreen)
  if channelListScreen <> invalid
    pushScreen(channelListScreen, true, true)
  else
    showChannelGridScreen(constants, sPageSource, true, m.constants.ui.screenLevels.channelCategoryGridScreen)
  end if
End Function


' gets the CategoryListScreen from the screen cache if it exists, otherwise wraps showChannelGridScreen()
' @constants: assocArray, constants as set in Constants.brs and updated in the hotpatch
' @sPageSource: string, What page is calling this function? This string is what is displayed on the top of the page
'                       to let the user know what page they will go to when they click the back button
Function showCategoryListScreen(constants, sPageSource)
  categoryListScreen = getFromScreenCache(m.constants.ui.screenIds.categoryListScreen)
  if categoryListScreen <> invalid
    pushScreen(categoryListScreen, true, true)
  else
    showChannelGridScreen(constants, sPageSource, false, m.constants.ui.screenLevels.channelCategoryGridScreen)
  end if
End Function


'''''''''''''''''''''
' showChannelGridScreen
'
' @constants: assocArray, constants as set in Constants.brs and updated in the hotpatch
' @sPageSource: string, What page is calling this function? This string is what is displayed on the top of the page to let the user know what page they will go to when they click the back button
' @bChannel: boolean, Is this a grid page displaying channels? If not, it will be a grid page displaying categories
' @screenLevel: integer, Should this screen have a different screenlevel other than its default one?
Function showChannelGridScreen(constants, sPageSource, bChannel = true, screenLevel = -1)
  gridScreen = CreateObject("roSGNode", "ChannelGridScreen")

  gridScreenId = constants.ui.screenIds.channelListScreen
  pageType = "channel_list_page"
  if bChannel = false
    gridScreenId = constants.ui.screenIds.categoryListScreen
    pageType = "category_list_page"
  end if

  if screenLevel > 0
    gridScreen.screenLevel = screenLevel
  end if
  gridScreen.id = gridScreenId
  gridScreen.callingPage = sPageSource
  gridScreen.displayChannels = bChannel
  gridScreen.trackingLoadStartTime = UpTime(0)
  gridScreen.observeFieldScoped("contentSelected", "onGridContentSelected")
  gridScreen.observeFieldScoped("visibleItems", "onVisibleItemsChange")
  gridScreen.observeFieldScoped("backgroundUriList", "onCategoryScreenBackgroundChange")
  gridScreen.observeFieldScoped("refreshChannel", "onRefreshGridSignal")
  gridScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
  gridScreen.isLoading = true

  gridScreen.trackingPageInfo = {
    pageType: pageType
    pageValues: {}
  }

  setInScreenCache(gridScreen)
  pushScreen(gridScreen, true, false)  ' don't send page load tracking until we resolve channel content
  getGridDataFromServer(gridScreen)
End Function


Function onGridContentSelected(msg)
  tubiLog("ChannelGridScreenHelpers.onGridContentSelected")
  gridScreen = msg.getRoSGNode()
  sType = ""
  if gridScreen.displayChannels = true
    sType = m.constants.ui.terms.channels
  else 
    sType = m.constants.ui.terms.categories
  end if
  sType = UCase(sType)
  showCategoryDetailsScreen(gridScreen.contentSelected, sType)
End Function


Function onVisibleItemsChange(msg)
  tubiLog("ChannelGridScreenHelpers.onVisibleItemsChange")
  aVisibleContentNodes = msg.getData()
  if aVisibleContentNodes <> invalid and aVisibleContentNodes.Count() > 0
    '//Check thru the array of content nodes of the visible items to see if any of the items within those rows
    '//have sponsorships, and then send out the pixels for those items (if they have not been sent already)
    for each contentNode in aVisibleContentNodes
      if contentNode <> invalid and contentNode.sponsorImages <> invalid and contentNode.sponsorImages.pixels <> invalid and contentNode.sponsorImages.pixels["container_list"] <> invalid
        containerId = contentNode.id
        sponsorPixels = contentNode.sponsorImages.pixels["container_list"]
        '//Only send sponsor pixels once per page load
        if m.sentSponsorPixels[containerId] <> true
          m.sentSponsorPixels[containerId] = true '//set to true when the sponsor image has been seen at least once per page load. This AA will be reset when the homescreen is no longer visible.
          sendSponsorPixels(sponsorPixels)
        end if
      end if
    end for
  end if

End Function


Function refreshGridScreen(gridScreen)
  m.refreshingChannelGridCache = true
  gridScreen.isLoading = true
  getGridDataFromServer(gridScreen)
End Function


Function onRefreshGridSignal(msg)
  gridScreen = msg.getRoSGNode()
  refreshGridScreen(gridScreen)
End Function


Function getGridDataFromServer(screen)
  tubiLog("ChannelGridScreenHelpers.getGridDataFromServer")
  if screen <> invalid
    shouldKidsModeBeSentToServer = shouldKidsModeBeSentToServer()
    categoriesListReqInfo = m.cmsApi.getCategoriesListRequestInfo(shouldKidsModeBeSentToServer)

    m.makeRequest({
      url: categoriesListReqInfo.url
      requestType: m.constants.reqNames.getCategoriesListScreen
      options: categoriesListReqInfo.options
      successCallback: onCategoriesListSuccess
      errorCallback: onCategoriesListError
      responseType: "node"
      screenId: screen.id
    })
  end if
End Function


' @response: roSGNode, a contentNode with children for each category or channel
Function onCategoriesListSuccess(response)
  tubiLog("ChannelGridScreenHelpers.onCategoriesListSuccess")

  if response <> invalid
    screenId = m.constants.ui.screenIds.categoryListScreen
    if response.id = m.constants.ui.contentIds.channelList
      screenId = m.constants.ui.screenIds.channelListScreen
    end if

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


Function onCategoriesListError(errorInfo)
'//::TODO:: make sure the side nav button returns to previous focus.
  tubiLog("ChannelGridScreenHelpers.onCategoriesListError")

  screen = getFromScreenCache(errorInfo.screenId)
  
  if screen <> invalid and (screen.id = m.constants.ui.screenIds.channelListScreen or screen.id = m.constants.ui.screenIds.categoryListScreen)
    popScreen(false, false)

    'delete the screen from the screen cache so that the next time the user attempts to load the page, the page will be loaded
    'from scratch again. Otherwise an empty page will load and content will never be fetched.
    deleteFromScreenCache(screen.id)

    sErrorType = m.constants.errors.context.categoriesScreen
    prelimMessage = getTranslation("screenCategories_error_retrieve_message")

    if screen.displayChannels = true
      sErrorType = m.constants.errors.context.channelsScreen
      prelimMessage = getTranslation("screenChannels_error_retrieve_message")
    end if

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

    showErrorModal(modalInfo)
    loadTime = Int((Uptime(0) - screen.trackingLoadStartTime) * 1000) 'in ms
    screenTrackingLoad(screen.trackingPageInfo, loadTime, false)
  end if
End Function
