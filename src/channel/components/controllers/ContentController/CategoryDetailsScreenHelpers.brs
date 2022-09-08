Function showCategoryDetailsScreen(content, sPageSource = "", sendNavigationLoadEvents = true)
  categoryDetailsScreen = CreateObject("roSGNode", "CategoryDetailsScreen")
  categoryDetailsScreen.callingPage = sPageSource
  categoryDetailsScreen.trackingLoadStartTime = UpTime(0)
  categoryDetailsScreen.observeFieldScoped("contentSelected", "onCategoryContentSelected")
  categoryDetailsScreen.observeFieldScoped("backgroundUriList", "onCategoryScreenBackgroundChange")
  categoryDetailsScreen.observeFieldScoped("sponsorshipBackground", "onSponsorshipBackgroundChanged")
  categoryDetailsScreen.observeFieldScoped("focusedChild", "onCategoryDetailsScreenFocusChanged")
  categoryDetailsScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
  categoryDetailsScreen.observeFieldScoped("refreshCategoryDetailsScreen", "onRefreshCategoryDetailsSignal")
  categoryDetailsScreen.observeFieldScoped("signInRequired", "onSignInRequiredModal")
  categoryDetailsScreen.observeFieldScoped("backButtonPressed", "onCategoryDetailsScreenBackPressed")
  categoryDetailsScreen.observeFieldScoped("transportVoiceResponse", "onTransportVoiceResponse")
  categoryDetailsScreen.observeFieldScoped("contentToPlay", "onContentToPlay")
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

  ' make queue API request only if the user loggedIn
  if content.id = m.constants.ui.categoryIds.queue AND isLoggedInUser() = false
    displaySignInRequiredModal(categoryDetailsScreen)
  else
    fetchCategoryDetails(content)
  end if

End Function


Function onSignInRequiredModal(msg)

  tubiLog("CategoryDetailsScreenHelpers.onSignInRequiredModal")
  screen = msg.getRoSGNode()

  if screen <> invalid AND screen.content = invalid
    displaySignInRequiredModal(screen)
  end if

End Function


Function displaySignInRequiredModal(screen)

  dialogEvent = {
    type: "dialog"
    values: {
      dialog_type: "SIGNIN_REQUIRED" 'DialogType enum
      pageOneof: m.Tracking.getAnalyticsPage(screen.trackingPageInfo.pageType, screen.trackingPageInfo.pageValues)
      dialog_action: "SHOW"
      dialog_sub_type: "sign-in-mylist"
    }
  }
  title = getTranslation("dialog_whoops_title")
  message = getTranslation("dialog_mylist_signIn_description")
  buttons = [getTranslation("dialog_button_register_signIn"), getTranslation("dialog_button_cancel")]
  showSimpleInstantResumableModal(title, message, buttons, dialogEvent, m.trackingLoggingTask, onSignInModalSelectedViaSideNavMyList, removeTopScreen)

End Function


Function onCategoryDetailsScreenFocusChanged(msg)
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

  showDetailScreen(categoryDetailsScreen.contentSelected, true)
End Function


Function onRefreshCategoryDetailsSignal(msg)
  categoryDetailsScreen = msg.getRoSGNode()
  if categoryDetailsScreen <> invalid AND categoryDetailsScreen.content <> invalid
    categoryContent = categoryDetailsScreen.content
  end if

  ' Stores state if the categoryDetailsScreen is in the process of refreshing/fetching content from API.
  ' Is used to determine when to send the PageLoad analytics event (don't send on refresh)
  m.refreshingCategoryDetailsCache = true

  categoryDetailsScreen.isLoading = true
  fetchCategoryDetails(categoryContent)
End Function


' @content: roSGNode, CategoryContentNode
Function fetchCategoryDetails(content)
  tubiLog("CategoryDetailsScreenHelpers.fetchCategoryDetails")
  isKidsMode = shouldKidsModeBeSentToServer()

  if content <> invalid
    categoryId = content.id
    ' TODO: FIND A BETTER WAY TO SOLVE THE u_continue_watching issue
    if content.id = "u_continue_watching"
      categoryId = "continue_watching"
    end if

    options = {}
    params = {}

    ' content_mode is mandatory param and its value needs to be passed as empty for fetching homescreen content
    params["content_mode"] = ""

    options.params = params

    categoryReqInfo = m.CmsApi.categoryReqInfo(categoryId, isKidsMode, options)

    m.makeRequest({
      url: categoryReqInfo.url
      requestType: m.constants.reqNames.getCategoryDetailsScreen
      options: categoryReqInfo.options
      successCallback: onCategoryDetailResponse
      errorCallback: onCategoryDetailError
      responseType: "node"
    })
  end if
End Function


Function onCategoryDetailResponse(categoryContent)
  tubiLog("CategoryDetailsScreenHelpers.onCategoryDetailResponse")
  screen = getCurrentScreen()

  if screen.id = m.constants.ui.screenIds.categoryDetailsScreen
    ' the category details screen is still the top screen after receiving the response

    if categoryContent <> invalid AND categoryContent.getChildCount() > 0
      screen.isLoading = false

      if categoryContent.sponsorImages <> invalid AND categoryContent.sponsorImages.pixels <> invalid AND categoryContent.sponsorImages.pixels["container_details"] <> invalid
        '//When a sponsored container is made visible, then call the pixels
        sponsorPixels = categoryContent.sponsorImages.pixels["container_details"]
        sendSponsorPixels(sponsorPixels)
      end if

      screen.content = categoryContent
      screen.shouldLoadContent = true
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
  ' popScreen(false, false)
  if topScreen.id = m.constants.ui.screenIds.categoryDetailsScreen
    categoryDetailsScreen = topScreen

    ' categoryDetailsScreen is created/pushed in showCategoryDetailsScreen, since there is no content,
    ' remove it from the stack will occur after the user closes the modal.
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
  else
    categoryDetailsScreen = getScreenFromStackById(m.constants.ui.screenIds.categoryDetailsScreen)
  end if

  if categoryDetailsScreen <> invalid
    loadTime = Int((Uptime(0) - categoryDetailsScreen.trackingLoadStartTime) * 1000) 'in ms
    screenTrackingLoad(categoryDetailsScreen.trackingPageInfo, loadTime, false)
  end If
End Function


Function onCategoryDetailsScreenBackPressed()
  onKeyEvent("back", true)
End Function
