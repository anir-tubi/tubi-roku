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

    '//when calling pushScreen() for a cached home screen, then report navigate_to_page and
    ' page_load events immediately, since there is no content fetching occuring.
    shouldSendPageLoadEvent = true
    if homescreen.isLoading = true
      ' when a user signs in/out, the homescreen may be in the screen cache, however the page may be
      ' going through the loading process, in which case we will send the PageLoadEvent when the
      ' homescreen concludes loading, in onHomescreenContentReady().
      shouldSendPageLoadEvent = false
      showHideSpinner(true)
    else
      showHideSpinner(false)
    end if

    pushScreen(homeScreen, true, shouldSendPageLoadEvent)
  else
    showHideSpinner(true)
    homeScreen = CreateObject("roSGNode", "HomeScreen")
    homeScreen.shouldFocusWhenPushed = m.top.fadeInContentController
    homeScreen.observeFieldScoped("backgroundUriList", "homeScreenBackgroundUpdated")
    homeScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
    homeScreen.observeFieldScoped("loadAllCategories", "onLoadAllCategories")
    homeScreen.observeFieldScoped("contentFocused", "onHomeScreenContentFocused")
    homeScreen.observeFieldScoped("focusedChild", "onHomeScreenFocusChanged")

    
    homeScreen.observeFieldScoped("contentSelected", "onContentSelected")
    homeScreen.observeFieldScoped("topNavItemSelected", "onTopNavItemSelected")
    m.playerFullscreenCountdownTimer.unobserveFieldScoped("fire") '//Stop lsitenting to timer before listing to it in case a previous screen started the timer
    m.playerFullscreenCountdownTimer.observeFieldScoped("fire", "onFullscreenCountdown")

    sContentMode = constants.ui.contentMode.homescreen
    if screenID = constants.ui.screenIds.homeScreen
      m.top.observeFieldScoped("homescreenResponse", "onHomescreenResponse")
    else if screenID = constants.ui.screenIds.movieScreen
      m.top.observeFieldScoped("moviescreenResponse", "onMoviescreenResponse")
      sContentMode = constants.ui.contentMode.movie
      m.top.observeFieldScoped("reloadMovieUserCategoriesResponse", "onReloadUserCategoriesResponseInMovieScreen")
    else if screenID = constants.ui.screenIds.tvScreen
      sContentMode = constants.ui.contentMode.tv
      m.top.observeFieldScoped("tvscreenResponse", "onTVscreenResponse")
      m.top.observeFieldScoped("reloadTVUserCategoriesResponse", "onReloadUserCategoriesResponseInTVScreen")
    else if screenID = constants.ui.screenIds.espanolScreen
      m.top.observeFieldScoped("espanolscreenResponse", "onEspanolscreenResponse")
      sContentMode = constants.ui.contentMode.latino
      m.top.observeFieldScoped("reloadEspanolUserCategoriesResponse", "onReloadUserCategoriesResponseInEspanolScreen")
    else if screenID = constants.ui.screenIds.newsScreen
      m.top.observeFieldScoped("newsScreenResponse", "onNewsScreenResponse")
      sContentMode = constants.ui.contentMode.linear
      m.top.observeFieldScoped("reloadNewsUserCategoriesResponse", "onReloadUserCategoriesResponseInNewsScreen")
    end if 
    homeScreen.contentMode = sContentMode

    homeScreen.isNewsAllowedInTopNav = isParentalControlsAdultLevel()
    homeScreen.shouldKidsModeBeSentToServer = shouldKidsModeBeSentToServer()
    homeScreen.signedIn = (authInfo <> invalid)
    homeScreen.kidsModeFeatureOn = m.kidsModeFeatureOn
    homeScreen.canLoadCategories = true
    homeScreen.id = screenID

    refreshHomescreen(homescreen)
    
    setInScreenCache(homeScreen)

    'page_load tracking will happen when content is received and displayed when onHomescreenContentReady() is called.
    pushScreen(homeScreen, true, false)
  end if

  '// Unobserve and then reobserve the topNavHasFocus field. Do this because sometimes, this field is unoberserved at other points in the code. 
  homeScreen.unobserveFieldScoped("topNavHasFocus")
  homeScreen.observeFieldScoped("topNavHasFocus", "onHomeScreeenTopNavFocused")
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


Function showNewsScreen()
  showHomeScreen(m.constants, m.global.authInfo, m.constants.ui.screenIds.newsScreen)
End Function


Function showDefaultHomeScreen()
  showHomeScreen(m.constants, m.global.authInfo)
End Function


Function reloadDefaultHomeScreenContent()
  '//If homescreen exists, then reload its content
  homescreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
  if homescreen <> invalid
    refreshHomescreen(homescreen)
  end if
End Function


Function onReloadUserCategoriesResponseInEspanolScreen(msg)
  onReloadUserCategoriesInHomeScreen(msg, m.constants.ui.screenIds.espanolScreen)
End Function


Function onReloadUserCategoriesResponseInNewsScreen(msg)
  onReloadUserCategoriesInHomeScreen(msg, m.constants.ui.screenIds.newsScreen)
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

          showErrorModal(modalInfo, onUserCategoriesFailed, screenID, invalid, invalid, [getTranslation("dialog_button_continue")])
        end if
      end if
    end if
  end if
End Function



'//If the homescreen is loading, then display the default background
Function setHomeScreenLoading(homeScreen)
  screen = getCurrentScreen()
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
  refreshHomescreen(homeScreen)
End Function


'//Refresh the content and the enabling of the top nav of the home screen
Function refreshHomescreen(homescreen)
  '//When the screen loads new content, make sure the topNav is displayed if it is supposed to. For example, if the user changes the parental settings from adults to older kids, then the app is in kidsMode and should not display the top nav. Changing the topNav status when reloading the content will ensure the top nav is diosplayed when it should be.
  bTopNavAllowed = isTopNavHomeScreenEnabled()
  if homeScreen.id = m.constants.ui.screenIds.espanolScreen
    if getExperimentResource("roku_top_nav", "roku_top_nav_options_experiment", false).espanol_in_top_nav = false
      bTopNavAllowed = false
    end if
  else if homeScreen.id = m.constants.ui.screenIds.newsScreen
    if getExperimentResource("roku_top_nav", "roku_top_nav_options_experiment", false).news_in_top_nav = false
      bTopNavAllowed = false
    end if
  end if

  homeScreen.enableTopNav = bTopNavAllowed
  fetchHomescreen(homescreen)
End Function


Function fetchHomeScreen(homeScreen)
  ' This check causes all category fetches to be skipped prior to the field
  ' being set to true.  Then, once true categories reload any time fetchHomeScreen() is
  ' called, such as when signedIn field changes.
  if homeScreen.canLoadCategories = true
    reqName = m.constants.reqNames.getHomescreen
   
    homeScreen.trackingLoadStartTime = UpTime(0)
    homeScreen.unobserveFieldScoped("contentReady")
    homeScreen.observeFieldScoped("contentReady", "onHomescreenContentReady")

    responseHandler = "homescreenResponse"
    options = {
      params: {
        "contentMode": homeScreen.contentMode
      }
    }

    if m.constants.settings.mode = "dev" and m.constants.settings.numContainers <> invalid
      options.params["groupSize"] = m.constants.settings.numContainers
    else
      options.params["groupSize"] = getExperimentResource("roku_limit_containers", "roku_limit_containers_v2").num_containers
    end if

    if homeScreen.id = m.constants.ui.screenIds.movieScreen
      responseHandler = "moviescreenResponse"
    else if homeScreen.id = m.constants.ui.screenIds.tvScreen
      responseHandler = "tvscreenResponse"
    else if homeScreen.id = m.constants.ui.screenIds.espanolScreen 
      responseHandler = "espanolscreenResponse" 
    else if homeScreen.id = m.constants.ui.screenIds.newsScreen 
      responseHandler = "newsScreenResponse" 
    end if

    m.metadataFetchTask.request = m.metadataFetchTaskDTO.createRequest("homescreen", m.top, responseHandler, reqName, invalid, shouldKidsModeBeSentToServer(), options)
    homeScreen.resetContentAreaValues = true
    setHomeScreenLoading(homeScreen)
  end if
End Function


''''''''''''''''''''''''''''''
' onNewsScreenResponse
'
Function onNewsScreenResponse()
  respondToHomescreenResponse(m.constants.ui.screenIds.newsScreen, m.top.newsScreenResponse)
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
        
        homeScreen.content = rawResponse.convertedMetadata
        homeScreen.contentUpdated = true

        ' don't set focus on the home screen if side nav has focus, for example
        if homeScreen.isInFocusChain() = true
          homeScreen.setFocus(true)
        end if

      else
        homeScreen.unobserveFieldScoped("contentReady")
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

          fnCancelFunction = retryCategoryList
          cancelParams = screenID
          if screenID <> m.constants.ui.screenIds.homeScreen
            '//it might be true there is no where to go to if the content of the main homescreen fails to load, but 
            '// if the content of a different homescreen type fails to load, then destroy the current homescreen and (based on screen stack logic) take user back to the previous screen  
            fnCancelFunction = destroyScreen
          end if
          showErrorModal(modalInfo, retryCategoryList, screenID, fnCancelFunction, cancelParams)
        end if

        loadTime = Int((Uptime(0) - homeScreen.trackingLoadStartTime) * 1000) 'in ms
        screenTrackingLoad(homeScreen.trackingPageInfo, loadTime, false)
      end if
    end if
  end if
End Function


' We retry in the cancel or retry cases, since there is nowhere else to go
Function retryCategoryList(screenID)
  tubiLog("HomeScreenHelpers.retryCategoryList") 
  homeScreen = getFromScreenCache(screenID)
  if homeScreen <> invalid
    homeScreen.canLoadCategories = true
    refreshHomescreen(homescreen)
    homeScreen.setFocus(true)
  end if
End Function


Function onHomeScreenFocusChanged(msg)
  tubiLog("HomeScreenHelpers.onHomeScreenFocusChanged")
  homeScreen = msg.getRoSGNode()

  if homeScreen.isInFocusChain() = false or homeScreen.topNavHasFocus = true
    '//If the homescreen loses focus or the top nav is in focus, then stop the linear video player in case it is playing
    stopCountdownTimer()
    if getCurrentScreen() = invalid or getCurrentScreen().id <> m.constants.ui.screenIds.linearVideoPlayerScreen
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
' @sDesiredContainerID, String = If there is a desire for a specific container to be in focuse, then this is the ID of the desired container
' @sHomeScreenID, String = the ID of homescreen that should jump to the content associated with the sID 
Function jumpToHomescreenContentByID(sID, sDesiredContainerID = "", sHomeScreenID = "")
  tubiLog("HomeScreenHelpers.jumpToHomescreenContentByID")
  if sHomeScreenID = ""
    sHomeScreenID = m.constants.ui.screenIds.homeScreen
  end if
  homeScreen = getFromScreenCache(sHomeScreenID)
  if homeScreen <> invalid
    homeScreen.jumpToRowItemByID = [sID, sDesiredContainerID]
  end if
End Function


'// when a new item is focused on, then do something
Function onHomeScreenContentFocused(msg)
  tubiLog("HomeScreenHelpers.onHomeScreenContentFocused")
  focusedContent = msg.getData()
  homeScreen = msg.getRoSGNode()

  if focusedContent <> invalid and (getCurrentScreen() <> invalid or getCurrentScreen().id <> m.constants.ui.screenIds.linearVideoPlayerScreen)
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
        playLinearVideoContent(focusedContent, true, homeScreen.id)
      else 
        startCountdownTimer()
        m.backgroundGroup.posterVisible = false
      end if
    else 
      stopAndHideLinearVideoPlayer()
    end if
  end if
End Function


Function goToFirstTopNavOptionFromAnotherTopNavOption()
  currentScreen = getCurrentScreen()
  if isCurrentScreenHomeScreen() = true and isTopNavHomeScreenEnabled() = true and getCurrentScreen().topNavHasFocus = true and getCurrentScreen().id <> m.constants.ui.screenIds.homeScreen
    currentScreen.unobserveFieldScoped("topNavHasFocus")
    
    showDefaultHomeScreen()

    '//When going to the first top nav item and going to the default home screen, ensure the the top nav is selected, but we do not wish to report the analytics that the topnav toggles off and then back on
    homeScreen = getCurrentScreen()
    homeScreen.unobserveFieldScoped("topNavHasFocus")
    homeScreen.focusOnTopNav = true
    homeScreen.observeFieldScoped("topNavHasFocus", "onHomeScreeenTopNavFocused")
  end if
End Function

' When the top nav gains or loses focus, then send analytics
Function onHomeScreeenTopNavFocused(msg)  
  bTopNavFocused = msg.getData()
  screen = msg.getRoSGNode()
  if bTopNavFocused = true
    user_interaction = "TOGGLE_ON"
  else
    user_interaction = "TOGGLE_OFF"
  end if 

  focusedNavId = m.constants.ui.screenIdToSideNavId[screen.id]
  navComponent = {
    top_nav_section: m.Tracking.sideNavPageMap[focusedNavId]
  }

  event = { 
    type: "component_interaction"
    values: {
      pageOneof: m.Tracking.getAnalyticsPage(screen.trackingPageInfo.pagetype, screen.trackingPageInfo.pageValues)
      componentOneof: m.Tracking.getAnalyticsComponent("top_nav_component", navComponent)
      user_interaction: user_interaction
    }
  }
  m.trackingLoggingTask.trackEvent = event
End Function


Function onFullscreenCountdown()
  tubiLog("HomeScreenHelpers.onFullscreenCountdown")
  homeScreen = getCurrentScreen()
  if homeScreen <> invalid and (homeScreen.id = m.constants.ui.screenIds.homeScreen or homeScreen.id = m.constants.ui.screenIds.newsScreen)
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
  homeScreen = getCurrentScreen()

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
      playLinearVideoContent(content, false, homeScreen.id)
    end if
  end if
End Function


Function stopCountdownTimer()
  tubiLog("HomeScreenHelpers.stopCountdownTimer")  
  homeScreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
  if homeScreen <> invalid
    homeScreen.fullscreenCountdown = -1
  end if
  newsScreen = getFromScreenCache(m.constants.ui.screenIds.newsScreen)
  if newsScreen <> invalid
    newsScreen.fullscreenCountdown = -1
  end if
  m.playerFullscreenCountdownTimer.control = "stop"
End Function


Function startCountdownTimer()
  tubiLog("HomeScreenHelpers.stopCountdownTimer")  
  homeScreen = getCurrentScreen()
  if homeScreen <> invalid and (homeScreen.id = m.constants.ui.screenIds.homeScreen or homeScreen.id = m.constants.ui.screenIds.newsScreen)
    stopCountdownTimer()
    '//Start/reset timer to play video in fullscreen after a few seconds
    homeScreen.fullscreenCountdown =  m.constants.timers.linearFullscreenTimeout
    m.playerFullscreenCountdownTimer.control = "start"
  end if
End Function


Function onTopNavItemSelected(msg)
  tubiLog("HomeScreenHelpers.onTopNavItemSelected")
  content = msg.getData()
  homeScreen = msg.getRoSGNode()

  if homeScreen.trackingPageInfo <> invalid
    '//Dispatch a selection component_interaction analytic event when a top nav item is selected
    navComponent = {
      top_nav_section: m.Tracking.sideNavPageMap[content.id]
    }
    pageOneof = m.Tracking.getAnalyticsPage(homeScreen.trackingPageInfo.pagetype, homeScreen.trackingPageInfo.pageValues)
    event = { 
      type: "component_interaction"
      values: {
        pageOneof: pageOneof
        componentOneof: m.Tracking.getAnalyticsComponent("top_nav_component", navComponent)
        user_interaction: "CONFIRM"
      }
    }
    m.trackingLoggingTask.trackEvent = event
  end if

  '//When selecting an item from the top nav, make sure to stop listening to the focusing or unfocusing of the topNav. The TOGGLE_ON/TOGGLE_OFF event should not fire even immediately after the selection of a topNav item
  homeScreen.unobserveFieldScoped("topNavHasFocus")
  if homeScreen.id <> content.id
    if content.id = m.constants.ui.sideNavIds.movies
      showMoviesScreen()
    else if content.id = m.constants.ui.sideNavIds.tv
      showTVScreen()
    else if content.id = m.constants.ui.sideNavIds.home
      showDefaultHomeScreen()
    else if content.id = m.constants.ui.sideNavIds.espanol
      showEspanolScreen()
    else if content.id = m.constants.ui.sideNavIds.news
      showNewsScreen()
    end if
  else
    '//If the user selected a top nav item that is associated with the current screen, then simply close the top nav
    homeScreen.focusOnTopNav = false
    '//Don't forget to listen to the "topNavHasFocus" since in this use case, the code does not open a new screen and reach showHomeScreen() which is where it resets and listens to the that field again
    homeScreen.observeFieldScoped("topNavHasFocus", "onHomeScreeenTopNavFocused")
  end if
  currentScreen = getCurrentScreen()
  if currentScreen.id <> homeScreen.id
    homeScreen.jumpToRowItem = [0,0] '//reset original homescreen so it is set back to the origin content item.
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
    startSignIn(onCWRowAfterSignIn)
  else if content.type = "utility"
    onUtilityItemSelected(content)
  else if content.type = m.constants.ui.contentTypes.linear
    selectLinearContent(content)
  else
    showDetailScreen(content, true)
  end if
End Function


Function onHomescreenContentReady(msg)
  tubiLog("HomescreenHelpers.onHomescreenContentReady ")
  fireAppLoadBeacon()
  homescreen = msg.getRoSGNode()
  homeScreen.unobserveFieldScoped("contentReady")
  homeScreen.isLoading = false
  showHideSpinner(false)

  '//Report the page_load analytics
  loadTime = Int((Uptime(0) - homeScreen.trackingLoadStartTime) * 1000) 'in ms
  screenTrackingLoad(homeScreen.trackingPageInfo, loadTime)
End Function


Function onUtilityItemSelected(content)
  itemSelectedId = content.id
  currentScreenNow = getCurrentScreen()

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


Function onUserCategoriesFailed(screenID)
  tubiLog("HomescreenHelpers.onUserCategoriesFailed")
  homeScreen = getFromScreenCache(screenID)
  if homeScreen <> invalid and homeScreen.content = invalid
    refreshHomescreen(homeScreen)
  end if
End Function