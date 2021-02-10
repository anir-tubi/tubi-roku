' Show the homescreen, whether existing in the screen pool already or creating a new one
'
' @constants: assocArray, constants as set in Constants.brs and updated in the hotpatch
' @authInfo: assocArray, normally set by m.global.authInfo
' @screenID: string, What kind of homescreen do you wish to make: regular, movies, or TV
Function showHomeScreen(constants, authInfo, screenID = "")
  tubiLog("HomeScreenHelpers.showHomeScreen")
  if screenID = ""
    screenID = constants.ui.screenIds.homeScreen
  end if
  homeScreen = getFromScreenCache(screenID)
  if homeScreen <> invalid
    ' this is required for setting focus to homescreen after activation/signout
    homeScreen.shouldFocusWhenPushed = m.top.fadeInContentController 
    pushScreen(homeScreen, true, true)
  else
    homeScreen = CreateObject("roSGNode", "HomeScreen")
    homeScreen.shouldFocusWhenPushed = m.top.fadeInContentController
    homeScreen.observeFieldScoped("backgroundUriList", "homeScreenBackgroundUpdated")
    homeScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
    homeScreen.observeFieldScoped("loadAllCategories", "onLoadAllCategories")
    homeScreen.observeFieldScoped("contentFocused", "onHomeScreenContentFocused")
    homeScreen.observeFieldScoped("focusedChild", "onHomeScreenFocusChanged")

    
    homeScreen.observeFieldScoped("contentSelected", "onContentSelected")
    homeScreen.observeFieldScoped("contentReady", "onHomescreenContentReady")
    m.playerFullscreenCountdownTimer.observeFieldScoped("fire", "onFullscreenCountdown")

    sContentMode = constants.ui.contentMode.homescreen
    if screenID = constants.ui.screenIds.homeScreen
      m.top.observeField("homescreenResponse", "onHomescreenResponse")
    else if screenID = constants.ui.screenIds.movieScreen
      m.top.observeField("moviescreenResponse", "onMoviescreenResponse")
      sContentMode = constants.ui.contentMode.movie
      m.top.observeFieldScoped("reloadMovieUserCategoriesResponse", "onReloadUserCategoriesResponseInMovieScreen")
    else if screenID = constants.ui.screenIds.tvScreen
      sContentMode = constants.ui.contentMode.tv
      m.top.observeField("tvscreenResponse", "onTVscreenResponse")
      m.top.observeFieldScoped("reloadTVUserCategoriesResponse", "onReloadUserCategoriesResponseInTVScreen")
    else if screenID = constants.ui.screenIds.espanolScreen
      m.top.observeField("espanolscreenResponse", "onEspanolscreenResponse")
      sContentMode = constants.ui.contentMode.latino
      m.top.observeFieldScoped("reloadEspanolUserCategoriesResponse", "onReloadUserCategoriesResponseInEspanolScreen")
    end if 
    homeScreen.contentMode = sContentMode

    homeScreen.id = screenID
    homeScreen.signedIn = (authInfo <> invalid)
    homeScreen.kidsModeFeatureOn = m.kidsModeFeatureOn
    homeScreen.shouldKidsModeBeSentToServer = shouldKidsModeBeSentToServer()
    homeScreen.canLoadCategories = true

    fetchHomeScreen(homescreen)
    
    setInScreenCache(homeScreen)
    'this is the first screen so no need for navigate_to_page tracking.
    'page_load tracking will happen when content is received.
    pushScreen(homeScreen, false, false)    
  end if
End Function


Function showEspanolScreen()
  showHomeScreen(m.constants, m.global.authInfo, m.constants.ui.screenIds.espanolScreen)
End Function


Function showMoviesScreen()
  showHomeScreen(m.constants, m.global.authInfo, m.constants.ui.screenIds.movieScreen)
End Function


Function showTVScreen()
  showHomeScreen(m.constants, m.global.authInfo, m.constants.ui.screenIds.tvScreen)
End Function


Function onReloadUserCategoriesResponseInEspanolScreen(msg)
  onReloadUserCategoriesInHomeScreen(msg, m.constants.ui.screenIds.espanolScreen)
End Function


Function onReloadUserCategoriesResponseInMovieScreen(msg)
  onReloadUserCategoriesInHomeScreen(msg, m.constants.ui.screenIds.movieScreen)
End Function


Function onReloadUserCategoriesResponseInTVScreen(msg)
  onReloadUserCategoriesInHomeScreen(msg, m.constants.ui.screenIds.tvScreen)
End Function


Function onReloadUserCategoriesInHomeScreen(msg, screenID = "")
  tubiLog("HomeScreenHelpers.onReloadUserCategoriesInHomeScreen")
  handledRequest = msg.getData()
  
  if screenID = ""
    screenID = m.constants.ui.screenIds.homeScreen
  end if
  homeScreen = getFromScreenCache(screenID)
  
  if homeScreen <> invalid
    if handledRequest.response <> invalid then
      response = handledRequest.response
      if response.code >= 200 and response.code < 300 then
        newCategory = handledRequest.convertedMetadata

        if homeScreen.content <> invalid
          oldCategory = invalid
          if newCategory <> invalid and newCategory.id <> invalid
            oldCategory = homeScreen.content.findNode(newCategory.id)
          else if handledRequest.context.id <> invalid
            oldCategory = homeScreen.content.findNode(handledRequest.context.id)
          end if
          
          homeScreen.rowAdded = ""
          homeScreen.rowRemoved = ""

          ' there are 4 options here
          ' 1) new category and old category both have content in them - replace the old with the new
          ' 2) new category has content, old category doesn't exist - add the new category
          ' 3) new category doesn't have content (will be invalid), old category does have content - remove old category
          ' 4) new category doesn't have content (will be invalid), old category doesn't exist - do nothing
          if newCategory <> invalid and oldCategory <> invalid
            'replace old category with new category
            homeScreen.content.replaceChild(newCategory, m.NodeHelpers.getChildIndex(homeScreen.content, oldCategory))
            homeScreen.repopulateContent = true
          else if newCategory <> invalid and oldCategory = invalid
            'add new category
            'if new category is history, put it one before queue, or if queue doens't exist put it in 2nd position
            'if new category is queue put it one after history, or if history doesn't exist, put it in 2nd position
            if newCategory.id = m.constants.ui.categoryIds.history
              clonedContent = homeScreen.content.clone(true)
              homeScreen.rowAdded = m.constants.ui.categoryIds.history
              clonedContent.insertChild(newCategory, homeScreen.content.continueWatchingIndex)
              homeScreen.content = clonedContent
            else if newCategory.id = m.constants.ui.categoryIds.queue
              homeScreen.rowAdded = m.constants.ui.categoryIds.queue
              clonedContent = homeScreen.content.clone(true)
              clonedContent.insertChild(newCategory, homeScreen.content.queueIndex)
              homeScreen.content = clonedContent
            end if
            
            clonedContent = invalid
            homeScreen.repopulateContent = true '//In case the rows are of different heights, tell homescreen to refresh to display rows correctly
          else if newCategory = invalid and oldCategory <> invalid
            if oldCategory.id = m.constants.ui.categoryIds.history
              homeScreen.rowRemoved = m.constants.ui.categoryIds.history
            else if oldCategory.id = m.constants.ui.categoryIds.queue
              homeScreen.rowRemoved = m.constants.ui.categoryIds.queue            
            end if
            'remove old category
            homeScreen.content.removeChild(oldCategory)
            homeScreen.repopulateContent = true '//In case the rows are of different heights, tell homescreen to refresh to display rows correctly
          else if newCategory = invalid and oldCategory = invalid
            'do nothing
          end if
        end if

        '//Stop loading of homescreen which will refresh the screen's content
        homeScreen.isLoading = false
      else
        ' if we were loading in the background, don't show an error modal
        if homeScreen.isInFocusChain()
          errorMessage = getTranslation("screenHome_error_fetchCategories_description")
          errorCode = getUserFacingErrorCode(m.constants.errors.context.homeScreen, m.constants.errors.subtypes.fetchError, response.code)
          dialogEvent =  {
            type: "dialog"
            values: {
              dialog_type: "PLAYER_ERROR"
              pageOneof: m.Tracking.getAnalyticsPage("home_page", {})
              dialog_action: "SHOW"
              dialog_sub_type: errorCode
            }
          }
          
          modalInfo = {
            message: getErrorMessage(errorMessage, errorCode)
            openTrackEvent: dialogEvent
            trackingTask: m.trackingLoggingTask
          }

          showErrorModal(modalInfo, onUserCategoriesFailed, invalid, invalid, invalid, [getTranslation("dialog_button_continue")])
        end if
      end if
    end if
  end if
End Function



'//If the homescreen is loading, then display the default background
Function setHomeScreenLoading(homeScreen)
  screen = currentScreen() 
  homeScreen.isLoading = true
  '//checking screen for invalid, to show the loading spinner when user sign outs
  '//Display default background and spinner only if the home screen is the current screen while it is loading
  if screen = invalid or screen.id = homeScreen.id
    showHideSpinner(true)
    displayDefaultBackground()
  end if
End Function


' load all category content, including . Series do not have season or episode information though.
Function onLoadAllCategories(msg)
  tubiLog("HomeScreenHelpers.onLoadAllCategories")
  homeScreen = msg.getRoSGNode()
  fetchHomeScreen(homeScreen)
End Function


Function fetchHomeScreen(homeScreen)
  ' This check causes all category fetches to be skipped prior to the field
  ' being set to true.  Then, once true categories reload any time fetchHomeScreen() is
  ' called, such as when signedIn field changes.
  if homeScreen.canLoadCategories = true
    reqName = m.constants.reqNames.getHomescreen
    '//::TODO:: JHAND - test error here!
   
    responseHandler = "homescreenResponse"
    options = {
      params: {
        "contentMode": homeScreen.contentMode
      }
    }


    if m.constants.settings.mode = "dev" and m.constants.settings.numContainers <> invalid
      options.params["groupSize"] = m.constants.settings.numContainers
    else
      options.params["groupSize"] = getExperimentResource("roku_limit_containers", "roku_limit_containers_v1").num_containers
    end if

    if homeScreen.id = m.constants.ui.screenIds.movieScreen
      responseHandler = "moviescreenResponse"
    else if homeScreen.id = m.constants.ui.screenIds.tvScreen
      responseHandler = "tvscreenResponse"
    else if homeScreen.id = m.constants.ui.screenIds.espanolScreen 
      responseHandler = "espanolscreenResponse" 
    end if

    m.metadataFetchTask.request = m.metadataFetchTaskDTO.createRequest("homescreen", m.top, responseHandler, reqName, invalid, shouldKidsModeBeSentToServer(), options)
    homeScreen.resetContentAreaValues = true
    setHomeScreenLoading(homeScreen)
  end if
End Function


''''''''''''''''''''''''''''''
' onEspanolscreenResponse
'
Function onEspanolscreenResponse()
  respondToHomescreenResponse(m.constants.ui.screenIds.espanolScreen, m.top.espanolscreenResponse)
End Function


''''''''''''''''''''''''''''''
' onMoviescreenResponse
'
Function onMoviescreenResponse()
  respondToHomescreenResponse(m.constants.ui.screenIds.movieScreen, m.top.moviescreenResponse)
End Function


''''''''''''''''''''''''''''''
' onTVscreenResponse
'
Function onTVscreenResponse()
  respondToHomescreenResponse(m.constants.ui.screenIds.TVScreen, m.top.tvscreenResponse)
End Function



''''''''''''''''''''''''''''''
' onHomescreenResponse
'
Function onHomescreenResponse()
  respondToHomescreenResponse(m.constants.ui.screenIds.homeScreen, m.top.homescreenResponse)
End Function


''''''''''''''''''''''''''''''
' respondToHomescreenResponse
'
Function respondToHomescreenResponse(screenID, rawResponse)
  tubiLog("HomeScreenHelpers.onHomescreenResponse")
  homeScreen = getFromScreenCache(screenID)
  if homeScreen <> invalid
    if rawResponse.response <> invalid then
      response = rawResponse.response
      if response.code >= 200 and response.code < 300 then
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
        
        ' set sponsor details only for Espanol screen
        if screenID = m.constants.ui.screenIds.espanolScreen
          setSponsorDetails(rawResponse.convertedMetadata)
        end if
        
        homeScreen.content = rawResponse.convertedMetadata
        homeScreen.contentUpdated = true

        ' don't set focus on the home screen if side nav has focus, for example
        if homeScreen.isInFocusChain() = true
          homeScreen.setFocus(true)
        end if

      else
        ' if we were loading in the background, don't show an error modal
        if homeScreen.isInFocusChain()
          errorMessage = getTranslation("screenHome_error_fetchScreenContent_description")
          errorCode = getUserFacingErrorCode(m.constants.errors.context.homeScreen, m.constants.errors.subtypes.fetchError, response.code)

          dialogEvent = {
            type: "dialog"
            values: {
              dialog_type: "NETWORK_ERROR"
              pageOneof: m.Tracking.getAnalyticsPage(homeScreen.trackingPageInfo.pageType, {})
              dialog_action: "SHOW"
              dialog_sub_type: errorCode
            }
          }

          modalInfo = {
            message: getErrorMessage(errorMessage, errorCode)
            openTrackEvent: dialogEvent
            trackingTask: m.trackingLoggingTask
          }

          showErrorModal(modalInfo, retryCategoryList, invalid, retryCategoryList, invalid)
        end if
      end if
    end if
  end if
End Function


' We retry in the cancel or retry cases, since there is nowhere else to go
Function retryCategoryList()
  tubiLog("HomeScreenHelpers.retryCategoryList")
  homeScreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
  if homeScreen <> invalid
    homeScreen.canLoadCategories = true
    homeScreen.loadAllCategories = true
    homeScreen.setFocus(true)
  end if
End Function


Function onHomeScreenFocusChanged(msg)
  tubiLog("HomeScreenHelpers.onHomeScreenFocusChanged")
  homeScreen = msg.getRoSGNode()

  if homeScreen.isInFocusChain() = false
    '//If the homescreen loses focus, then stop the linear video player in case it is playing
    stopCountdownTimer()
    if currentScreen() = invalid or currentScreen().id <> m.constants.ui.screenIds.linearVideoPlayerScreen
      '//If the video player has gained focus, then don't stop it.
      stopAndHideLinearVideoPlayer()
    end if
  end if
End Function


''''''''''''''''''''''''''''''
' jumpToHomescreenContentByID
'
' Focus on a specific item within the homescreen
' @sID, String = The ID of the content item that should be in focused
' sDesiredContainerID, String = If there is a desire for a specific container to be in focuse, then this is the ID of the desired container
Function jumpToHomescreenContentByID(sID, sDesiredContainerID = "")
  tubiLog("HomeScreenHelpers.jumpToHomescreenContentByID")
  homeScreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
  if homeScreen <> invalid
    homeScreen.jumpToRowItemByID = [sID, sDesiredContainerID]
  end if
End Function


'// when a new item is focused on, then do something
Function onHomeScreenContentFocused(msg)
  tubiLog("HomeScreenHelpers.onHomeScreenContentFocused")
  focusedContent = msg.getData()
  homeScreen = msg.getRoSGNode()

  if focusedContent <> invalid and (currentScreen() <> invalid or currentScreen().id <> m.constants.ui.screenIds.linearVideoPlayerScreen)
    stopCountdownTimer()
    if focusedContent.type = m.constants.ui.categoryTypes.linear
      bPlayVideo = true
      linearVideoPlayer = getFromScreenCache(m.constants.ui.screenIds.linearVideoPlayerScreen)
      if linearVideoPlayer <> invalid and linearVideoPlayer.content <> invalid 
        if linearVideoPlayer.content.id = focusedContent.id and linearVideoPlayer.state = "playing"
          '//No need to play the video. It already is playing the video
          bPlayVideo = false
        end if
      end if

      if bPlayVideo = true
        '//If player is currently not playing the current content, then display background and
        '//tell player to load and play the video associated with the focused item
        m.backgroundGroup.posterVisible = true '//reset the background so it can be seen
        stopLinearVideoContent()
        playLinearVideoContent(focusedContent)
      else 
        startCountdownTimer()
        m.backgroundGroup.posterVisible = false
      end if
    else 
      stopAndHideLinearVideoPlayer()
    end if
  end if
End Function


Function onFullscreenCountdown()
  tubiLog("HomeScreenHelpers.onFullscreenCountdown")
  homeScreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
  if homeScreen <> invalid
    nCurrentCount = homeScreen.fullscreenCountdown
    nNewCount = nCurrentCount - 1
    homeScreen.fullscreenCountdown = nNewCount
    if nNewCount <= 0
      selectLinearContent(homeScreen.contentFocused)
    end if
  end if
End Function


' Select the Linear content that is currently focused
Function selectLinearContent(content)
  tubiLog("HomeScreenHelpers.selectLinearContent()") 

  '//stop timer and tell player to go fullscreen   
  stopCountdownTimer()
  if content <> invalid and content.type = m.constants.ui.contentTypes.linear
    linearContent = getCurrentLinearContent()
    if linearContent <> invalid and linearContent.id <> invalid and content.id = linearContent.id
      '//If the user selects the linear content that is already playing, then just maximize it. 
      maximizeLinearPlayer(content) 
    else
      '//If the user selects the linear content that is not yet playing, then stop the previous content (if any) and start playing the content. 
      stopLinearVideoContent()
      playLinearVideoContent(content, false)
    end if
  end if
End Function


Function stopCountdownTimer()
  tubiLog("HomeScreenHelpers.stopCountdownTimer")  
  homeScreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
  if homeScreen <> invalid
    homeScreen.fullscreenCountdown = -1
  end if
  m.playerFullscreenCountdownTimer.control = "stop"
End Function


Function startCountdownTimer()
  tubiLog("HomeScreenHelpers.stopCountdownTimer")  
  homeScreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
  if homeScreen <> invalid
    stopCountdownTimer()
    '//Start/reset timer to play video in fullscreen after a few seconds
    homeScreen.fullscreenCountdown =  m.constants.timers.linearFullscreenTimeout
    m.playerFullscreenCountdownTimer.control = "start"
  end if
End Function


' Show the detail screen for the selected content
Function onContentSelected(msg)
  tubiLog("HomeScreenHelpers.onContentSelected")
  content = msg.getData()
  homeScreen = msg.getRoSGNode()
  m.autoplayContext = homeScreen.currCategoryId

  if content.type = "channel"
    showChannelScreen(content, "HOME")
  else if content.type = m.constants.ui.contentTypes.historySignedOutUser
    '//if a signed out user selects the continue watching row, then navigate him/her to the sign in screen
    startSignIn()
  else if content.type = "utility"
    onUtilityItemSelected(content)
  else if content.type = m.constants.ui.contentTypes.linear
    selectLinearContent(content)
  else
    showDetailScreen(content, true)
  end if
End Function


Function onHomescreenContentReady(msg)
  fireAppLoadBeacon()
  homescreen = msg.getRoSGNode()
  homeScreen.isLoading = false
  showHideSpinner(false)
End Function


' onHomeSuccessResponse
'
' this is the callback from Home screen success data
' @response : ContentNode
function onHomeSuccessResponse(response)

end function


' onHomeErrorResponse
' 
' this is the callback from Home screen error data
' @error : ContentNode
function onHomeErrorResponse(error)

end function


Function onUtilityItemSelected(content)
  itemSelectedId = content.id
  currentScreenNow = currentScreen()

  if itemSelectedId = m.constants.ui.utilityIds.movies
    showMoviesScreen()
    m.SideNav.itemRequested = m.constants.ui.sideNavIds.movies
  else if itemSelectedId = m.constants.ui.utilityIds.tv
    showTVScreen()
    m.SideNav.itemRequested = m.constants.ui.sideNavIds.tv
  else
    showChannelScreen(content, "HOME")  
  end if
End Function  


Function onUserCategoriesFailed()
  tubiLog("HomescreenHelpers.onUserCategoriesFailed")
  homeScreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
  if homeScreen <> invalid and homeScreen.content = invalid
    fetchHomeScreen(homeScreen)
  end if
End Function