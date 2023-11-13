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
    screen.observeFieldScoped("stopVideoPreview", "onStopVideoPreview")
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
    fetchMyStuffCategoryDetails(screen)
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


' Get the content for the MyStuff Screen: continue watching and queue containers
' @param screen, roSGNode - the MyStuff Screen
Function fetchMyStuffCategoryDetails(screen)
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

  if isKidsMode = false
    '//roku_mylikes_mystuff_v1 - for the duration of the experiment, get a container of liked videos.
    likeIds = getArrayOfLikedIds()
    if likeIds.Count() > 0
      '//Add the Liked IDs as a container
      contentNode = CreateObject("roSGNode", "ContentNode")
      contentNode.id = m.constants.ui.categoryIds.myLikes
      contentNode.categories = likeIds
      content.appendChild(contentNode)
    end if
  end if

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

      if response.getChildCount() > 0
        for i = 0 to response.getChildCount() - 1
          container = response.getChild(i)
          if container.id = m.constants.ui.categoryIds.myLikes
            if getExperimentResource("roku_mylikes_mystuff", "roku_mylikes_mystuff_v1", true).enabled = false
              '//send exposure event here regardless if enabled/disabled
              '//remove liked content if disabled. Do it here since there is no way to know if liked video IDs are valid/current before requesting them.
              response.removeChildIndex(i)
            end if
            exit for
          end if
        end for
      end if

      nValidUntil = determineValidUntilDurationBasedOnChildren(response)
      response.addField("validUntil", "integer", false)
      response.validUntil = nValidUntil
    end if
    
    screen.isLoading = false
    screen.content = response
    screen.contentUpdated = true

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
      screen.jumpToRowItemByIdAndIndex  = {
        id: oldFocusedContentID,
        index: rowItemFocused
      }
    else
      '//focus on the left most item
      screen.jumpToRowItemByIdAndIndex  = {
        index: [0,0]
      }
    end if

  end if
End FUnction


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
End function


Function onSignUpButtonSelectedOnMyStuffScreen(msg)
  tubiLog("MyStuffScreenHelpers.onSignUpButtonSelectedOnMyStuffScreen")
  startSignIn(onRegistrationProcessCompletedOnMyStuffScreen)
End function


Function onHomeButtonSelectedOnMyStuffScreen(msg)
  tubiLog("MyStuffScreenHelpers.onHomeButtonSelectedOnMyStuffScreen")
  '//Take user to the homescreen
  homeSideNavID = m.constants.ui.screenIdToSideNavId[m.constants.ui.screenIds.homeScreen]
  focusSideNavOption(homeSideNavID)
  showDefaultHomeScreen()
End function


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
  stopVideoPreview()  '//In case a video preview is playing, stop it until the new content has loaded.
  fetchMyStuffCategoryDetails(screen)
End Function


' Show the detail screen for the selected content
Function onMyStuffContentSelected(msg)
  tubiLog("MyStuffScreenHelpers.onMyStuffContentSelected")
  content = msg.getData()
  if content.type <> m.constants.ui.contentTypes.emptyContainer
    '//NOTE: If the content type is empty, then it is most likely the user has no items in a myList row  (i.e. continue watching, myList)
    ' and the user attempted to click on an empty row.
    ' Nothing should happen.
    playbackSource = {
      "srcForAnalytic": m.constants.player.playbackSource.unknown
      "srcForAds":m.constants.player.playbackOrigin.container
      "playbackContainer": content.parentId
    }

    pageOriginDetails = {
      "pageOrigin": m.constants.ui.screenIds.myStuffScreen
      "functionName": "onMyStuffContentSelected"
    }

    showDetailScreen(content, true, invalid, invalid, playbackSource, pageOriginDetails)
  end if
End Function


' The event hander function for when a content item gains focus on the my stuff screen
Function onMyStuffScreenContentFocused(msg)
  tubiLog("MyStuffScreenHelpers.onMyStuffScreenContentFocused")
  focusedContent = msg.getData()
  screen = msg.getRoSGNode()
  setVideoPreviewAfterFocus(focusedContent, screen.trackingPageInfo)
End Function