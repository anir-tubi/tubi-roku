' Show the "my stuff" screen
Function showMyStuffScreen()
  tubiLog("MyStuffScreenHelpers.showMyStuffScreen")
  screen = getFromScreenCache(m.constants.ui.screenIds.myStuffScreen)
  bLoadData = true
  bLoggedInUser = isLoggedInUser()

  if screen <> invalid
    if bLoggedInUser = false OR (screen.content <> invalid AND shouldRefresh(screen.content) = false)
      '//If not logged in, or if content has not been indicated to be stale, then no need to load data
      bLoadData = false
      screen.isLoading = false
      showHideSpinner(false)
    else
      screen.isLoading = true
      showHideSpinner(true)
    end if
  else

    screen = CreateObject("roSGNode", "MyStuffScreen")
    screen.trackingLoadStartTime = UpTime(0)
    screen.observeFieldScoped("contentSelected", "onMyStuffContentSelected")
    screen.observeFieldScoped("contentFocused", "onMyStuffScreenContentFocused")
    screen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
    screen.observeFieldScoped("transportVoiceResponse", "onTransportVoiceResponse")
    screen.observeFieldScoped("contentToPlay", "onContentToPlay")
    screen.observeFieldScoped("backgroundUriList", "onVideoContentScreenBackgroundUpdated")
    screen.observeFieldScoped("signUpButtonSelected", "onSignUpButtonSelectedOnMyStuffScreen")
    screen.observeFieldScoped("homeButtonSelected", "onHomeButtonSelectedOnMyStuffScreen")
    screen.observeFieldScoped("refreshContent", "onRefreshContentSignalForMyStuffScreen")
    screen.observeFieldScoped("componentInteractionInfo", "onComponentInteractionInfoChange")
    screen.observeFieldScoped("pauseVideoPreview", "onPauseVideoPreview")

    if bLoggedInUser = true
      screen.isLoading = true
      showHideSpinner(true)
    else
      bLoadData = false
    end if
  end if

  screen.isVideoPreviewOn = m.pub_serverPersistentData.isVideoPreviewOn
  m.pubSub.subscribe("pub_serverPersistentData.isVideoPreviewOn", screen, "isVideoPreviewOn")

  setInScreenCache(screen)
  screen.trackingPageInfo = {
    pageType: "for_you_page"
    pageValues: {}
  }

  ' make queue API request only if bLoadData is set to true
  if bLoadData = true
    fetchMyStuffCategoryDetails()
  else if bLoggedInUser = true
    jumpToPreviousFocusedItem(screen)
    showHideSpinner(false)
  end if

  if bLoadData = false
    '//Report the page_load analytics if the screen content does not have to (re)load.
    '// If the content needs to load, then the page load event will get fired later when the content is done loading
    screenTrackingLoad(screen.trackingPageInfo, 0)
  end if

  ' don't send page load tracking until screen details content is returned from the API
  pushScreen(screen, true, false)

  screen.signedIn = bLoggedInUser '//display the guest or signed-in user profile experience. Do this AFTER pushScreen to ensure focus is properly set 1st.
End Function


' Get the content for the MyStuff Screen: continue watching and queue container
Function fetchMyStuffCategoryDetails()
  tubiLog("MyStuffScreenHelpers.fetchMyStuffCategoryDetails")

  isKidsMode = shouldKidsModeBeSentToServer()

  '//Set the categories of the screen. This is static so can be hardcoded
  content = CreateObject("roSGNode", "ContentNode")

  '//Add the Continue Watching container
  contentNode = CreateObject("roSGNode", "CategoryContentNode")
  contentNode.id = m.constants.ui.categoryIds.history
  content.appendChild(contentNode)

  '//Add the MyList container
  contentNode = CreateObject("roSGNode", "CategoryContentNode")
  contentNode.id = m.constants.ui.categoryIds.queue
  content.appendChild(contentNode)

  isSignedInUser = isLoggedInUser()

  batchRequests = m.cmsApi.createMyStuffScreenBatchReqInfo(content, isKidsMode, isSignedInUser)
  if batchRequests <> invalid
    m.makeBatchRequest({
      requests: batchRequests
      responseType: "node"
      isSignedInUser: isSignedInUser
      successCallback: onMyStuffBatchResponse
    })
  end if
End Function


Function onMyStuffBatchResponse(response)
  tubiLog("MyStuffScreenHelpers.onMyStuffBatchResponse")
  screenID = m.constants.ui.screenIds.myStuffScreen
  screen = getFromScreenCache(screenID)
  if screen <> invalid
    if response <> invalid
      nValidUntil = determineValidUntilDurationBasedOnChildren(response)
      response.addField("validUntil", "integer", false)
      response.validUntil = nValidUntil
    end if

    screen.isLoading = false
    if isNode(response) = true AND response.getChildCount() > 0
      screen.content = response
      screen.contentUpdated = true
    else
      modalInfo = {
        message: getTranslation("error_noContent_description")
      }

      showErrorModal(modalInfo, fetchMyStuffCategoryDetails)
    end if

    jumpToPreviousFocusedItem(screen)
    showHideSpinner(false)

    '//Report the page_load analytics
    loadTime = Int((Uptime(0) - screen.trackingLoadStartTime) * 1000) 'in ms
    currentScreen = getCurrentScreen()

    if currentScreen <> invalid AND currentScreen.isSubType("MyStuffScreen") = true
      screenTrackingLoad(screen.trackingPageInfo, loadTime)
    end if
  end if
End Function


' @response: roSGNode, a ContentNode representing a container/category, may have no children
Function onReloadUserCategoriesResponseInMyStuffScreen(response)
  tubiLog("MyStuffScreenHelpers.onReloadUserCategoriesResponseInMyStuffScreen")
  screen = getFromScreenCache(m.constants.ui.screenIds.myStuffScreen)

  if screen <> invalid
    content = screen.content
    if content <> invalid
      newCategory = invalid
      oldCategory = invalid
      nOldCategoryIndex = -1

      if type(response) = "roSGNode"

        if response.getChildCount() > 0
          newCategory = response
        end if

        if content.getChildCount() > 0
          for i = 0 to content.getChildCount() - 1
            container = content.getChild(i)
            if container.id = response.id
              oldCategory = container
              nOldCategoryIndex = i
              exit for
            end if
          end for
        end if

      end if

      if newCategory <> invalid AND oldCategory <> invalid
        screen.isLoading = true '//In order to properly refresh the screen content, we need to mark the screen has loading, which will reset the content

        'replace the old category with the new category
        content.replaceChild(newCategory, nOldCategoryIndex)

        '//Update the validUntil property based on the updated content
        nValidUntil = determineValidUntilDurationBasedOnChildren(content)
        content.validUntil = nValidUntil

        screen.content = content
        screen.isLoading = false
        screen.contentUpdated = true
        jumpToPreviousFocusedItem(screen)
      end if

    end if
  end if
End Function


Function onErrorReloadUserCategoriesInMyStuffScreen(response)
  tubiLog("MyStuffScreenHelpers.onErrorReloadUserCategoriesInMyStuffScreen")

  screenID = m.constants.ui.screenIds.myStuffScreen
  screen = getFromScreenCache(screenID)
  if screen <> invalid AND response <> invalid

    ' if we were loading in the background, don't show an error modal
    if screen.isInFocusChain() = true
      '//use the same error analytics logic as the homscreen
      errorMessage = getTranslation("screenHome_error_fetchCategories_description")
      errorCode = getUserFacingErrorCode(m.constants.errors.context.myStuffScreen, m.constants.errors.subtypes.fetchError, response.code)
      dialogEvent = {
        type: "dialog"
        values: {
          dialog_type: "PLAYER_ERROR"
          pageOneof: m.Tracking.getAnalyticsPage(screen.trackingPageInfo.pageType, screen.trackingPageInfo.pageValues)
          dialog_action: "SHOW"
          dialog_sub_type: errorCode
        }
      }

      modalInfo = {
        message: getErrorMessage(errorMessage, errorCode)
        openTrackEvent: dialogEvent
        trackingTask: m.trackingLoggingTask
      }

      showErrorModal(modalInfo, onUserMyStuffCategoriesFailed, invalid, setContentToRefresh, screenID, [getTranslation("dialog_button_continue")])
    else
      '//As a last resort, if there was a problem getting a specific category when refreshing,
      '//and the screen is not in focus, then set the entire page to refresh. This way there is a chance
      '//that the user will see the correct content on this screen
      setContentToRefresh(m.constants.ui.screenIds.myStuffScreen)
    end if
  end if
End Function


' Callback function after error modal is dismissed when myStuff category fails to refresh. The entire page will refresh
Function onUserMyStuffCategoriesFailed()
  tubiLog("MyStuffScreenHelpers.onUserMyStuffCategoriesFailed")
  screenID = m.constants.ui.screenIds.myStuffScreen
  screen = getFromScreenCache(screenID)

  if screen <> invalid AND screen.isInFocusChain() = true
    '//refresh the myStuff screen content after the screen had experienced an error
    setContentToRefresh(screenID)
    showMyStuffScreen()
  end if

End Function


Function jumpToPreviousFocusedItem(screen)
  tubiLog("MyStuffScreenHelpers.jumpToPreviousFocusedItem")
  if screen <> invalid
    rowItemFocused = invalid
    oldFocusedContentID = ""
    cursorPosition = screen.cursorPosition
    if cursorPosition <> invalid AND cursorPosition[0] >= 0 AND cursorPosition[1] >= 0
      rowItemFocused = screen.cursorPosition
    end if
    if screen.contentFocused <> invalid
      '//Does the screen have a previous focused item?
      oldFocusedContentID = screen.contentFocused.id
    end if

    if rowItemFocused <> invalid
      '//try to focus on the previous focused item before the content was reloaded.
      screen.jumpToRowItemByIdAndIndex = {
        id: oldFocusedContentID,
        index: rowItemFocused
      }
    else
      '//focus on the left most item
      screen.jumpToRowItemByIdAndIndex = {
        index: [0, 0]
      }
    end if

  end if
End Function


' Determine the valid until duration baed on the passed content's container children.
' The shortest duration of the containers should be chosen for the duration of the parent.
' @param content: node - the content node that has children with validUntil values.
Function determineValidUntilDurationBasedOnChildren(content)
  nValidReturn = 0
  shortestValidDuration = invalid

  if content <> invalid
    for i = 0 to content.getChildCount() - 1
      category = content.getChild(i)

      '//Find out the shortest validUntil duration to set this to the valudUntil property of the entire array of categories
      if shortestValidDuration = invalid
        shortestValidDuration = category.validUntil
      else if category.validUntil <> invalid
        if category.validUntil < shortestValidDuration
          shortestValidDuration = category.validUntil
        end if
      end if
    end for

    '//Set the validUntil property of the array of categories
    if shortestValidDuration <> invalid
      nValidReturn = shortestValidDuration
    else
      nValidReturn = Uptime(0) + m.constants.cacheTimes.category
    end if
  end if

  return nValidReturn
End Function


Function onSignUpButtonSelectedOnMyStuffScreen()
  tubiLog("MyStuffScreenHelpers.onSignUpButtonSelectedOnMyStuffScreen")
  startSignIn(onRegistrationProcessCompletedOnMyStuffScreen)
End Function


Function onHomeButtonSelectedOnMyStuffScreen()
  tubiLog("MyStuffScreenHelpers.onHomeButtonSelectedOnMyStuffScreen")
  '//Take user to the homescreen
  homeSideNavID = m.constants.ui.screenIdToSideNavId[m.constants.ui.screenIds.homeScreen]
  focusSideNavOption(homeSideNavID)
  showDefaultHomeScreen()
End Function


'myStuff screen has told us that the content is out of cache window, so refresh
Function onRefreshContentSignalForMyStuffScreen(msg)
  tubiLog("MyStuffScreenHelpers.onRefreshContentSignalForMyStuffScreen")
  bLoggedInUser = isLoggedInUser()
  screen = msg.getRoSGNode()
  if screen.isLoading = false AND bLoggedInUser = true
    refreshContentSignalForMyStuffScreen(screen)
  end if
End Function


' @param screen, roSGNode - the MyStuff Screen
Function refreshContentSignalForMyStuffScreen(screen)
  tubiLog("MyStuffScreenHelpers.refreshContentSignalForMyStuffScreen")
  screen.isLoading = true
  showHideSpinner(true)
  screen.content = invalid
  screen.contentUpdated = true
  stopVideoPreview() '//In case a video preview is playing, stop it until the new content has loaded.
  fetchMyStuffCategoryDetails()
End Function


' Show the detail screen for the selected content
Function onMyStuffContentSelected(msg)
  tubiLog("MyStuffScreenHelpers.onMyStuffContentSelected")
  content = msg.getData()
  screen = msg.getRoSGNode()
  if content.type <> m.constants.ui.contentTypes.emptyContainer
    '//NOTE: If the content type is empty, then it is most likely the user has no items in a myList row  (i.e. continue watching, myList)
    ' and the user attempted to click on an empty row.
    ' Nothing should happen.
    playbackSource = {
      "srcForAnalytic": m.constants.player.playbackSource.unknown
      "srcForAds": m.constants.player.playbackOrigin.container
      "playbackContainer": getCurrentFocusedContainerId(screen, content)
    }

    processUserContentSelection(content, screen, playbackSource)
  end if
End Function


' The event hander function for when a content item gains focus on the my stuff screen
Function onMyStuffScreenContentFocused(msg)
  tubiLog("MyStuffScreenHelpers.onMyStuffScreenContentFocused")
  focusedContent = msg.getData()
  screen = msg.getRoSGNode()
  componentTrackingInfo = getCategoryComponentTrackingInfo(screen)
  setVideoPreviewAfterFocus(focusedContent, screen.trackingPageInfo, componentTrackingInfo)
End Function