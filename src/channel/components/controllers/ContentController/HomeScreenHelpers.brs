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
    pushScreen(homeScreen, true, true)
  else
    homeScreen = CreateObject("roSGNode", "HomeScreen")
    homeScreen.shouldFocusWhenPushed = m.top.animationLogoCompleted
    homeScreen.observeFieldScoped("backgroundUriList", "homeScreenBackgroundUpdated")
    homeScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
    homeScreen.observeFieldScoped("loadAllCategories", "onLoadAllCategories")

    m.top.observeFieldScoped("reloadMovieUserCategoriesResponse", "onReloadUserCategoriesResponseInMovieScreen")
    m.top.observeFieldScoped("reloadTVUserCategoriesResponse", "onReloadUserCategoriesResponseInTVScreen")
    
    homeScreen.observeFieldScoped("contentSelected", "onContentSelected")
    homeScreen.observeFieldScoped("contentReady", "onHomescreenContentReady")
    m.top.observeField("homescreenResponse", "onHomescreenResponse")
    m.top.observeField("moviescreenResponse", "onMoviescreenResponse")
    m.top.observeField("tvscreenResponse", "onTVscreenResponse")
    
    homeScreen.id = screenID
    homeScreen.signedIn = (authInfo <> invalid)
    homeScreen.shouldKidsModeBeSentToServer = shouldKidsModeBeSentToServer()
    homeScreen.canLoadCategories = true
    sContentMode = constants.ui.screenIds.homeScreen
    if homeScreen.id = constants.ui.screenIds.movieScreen
      sContentMode = constants.ui.contentMode.movie
    else if homeScreen.id = constants.ui.screenIds.tvScreen
      sContentMode = constants.ui.contentMode.tv
    end if
    homeScreen.contentMode = sContentMode

    homeScreen.canLoadCategories = true
    fetchHomeScreen(homescreen)
    
    setInScreenCache(homeScreen)
    'this is the first screen so no need for navigate_to_page tracking.
    'page_load tracking will happen when content is received.
    pushScreen(homeScreen, false, false)
  end if
End Function

Function showMoviesScreen()
  showHomeScreen(m.constants, m.global.authInfo, m.constants.ui.screenIds.movieScreen)
End Function


Function showTVScreen()
  showHomeScreen(m.constants, m.global.authInfo, m.constants.ui.screenIds.tvScreen)
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
              clonedContent.insertChild(newCategory, homeScreen.content.continueWatchingIndex)
              homeScreen.content = clonedContent
            else if newCategory.id = m.constants.ui.categoryIds.queue
              clonedContent = homeScreen.content.clone(true)
              clonedContent.insertChild(newCategory, homeScreen.content.queueIndex)
              homeScreen.content = clonedContent
            end if
            
            clonedContent = invalid
            homeScreen.repopulateContent = true '//In case the rows are of different heights, tell homescreen to refresh to display rows correctly
          else if newCategory = invalid and oldCategory <> invalid
            'remove old category
            homeScreen.content.removeChild(oldCategory)
            homeScreen.repopulateContent = true '//In case the rows are of different heights, tell homescreen to refresh to display rows correctly
          else if newCategory = invalid and oldCategory = invalid
            'do nothing
          end if
        end if

        '//Stop loading of homescreen which will refresh the screen's content
        homeScreen.isLoading = false
        showHideSpinner(false)
      else
        ' if we were loading in the background, don't show an error modal
        if homeScreen.isInFocusChain()
          errorMessage = getTranslation("screenHome_error_fetchCategories_description")
          errorCode = getUserFacingErrorCode(m.constants.errors.context.homeScreen, m.constants.errors.subtypes.fetchError, response.code)
          dialogEvent =  {
            type: "dialog"
            values: {
              dialog_type: "NETWORK_ERROR" 'DialogType enum - TODO: Update this when a "PLAYER_ERROR" value becomes available in protos
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

          showErrorModal(modalInfo, onUserCategoriesFailed, invalid, invalid, invalid, [getTranslation("screenHome_error_button_continue")])
        end if
      end if
    end if
  end if
End Function



'//If the homescreen is loading, then display the default background
Function setHomeScreenLoading(homeScreen)
  screen = currentScreen() 
  homeScreen.isLoading = true
  showHideSpinner(true)
  if screen <> invalid and screen.id = homeScreen.id
    '//Display default background if the hoime screen is the current screen while it is loading
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
    params = {contentMode : homeScreen.contentMode}
    if homeScreen.id = m.constants.ui.screenIds.movieScreen
      responseHandler = "moviescreenResponse"
    else if homeScreen.id = m.constants.ui.screenIds.tvScreen
      responseHandler = "tvscreenResponse"
    end if

    m.metadataFetchTask.request = m.metadataFetchTaskDTO.createRequest("homescreen", m.top, responseHandler, reqName, invalid, shouldKidsModeBeSentToServer(), params)
    homeScreen.resetContentAreaValues = true
    setHomeScreenLoading(homeScreen)
  end if
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


' Show the detail screen for the selected content
Function onContentSelected(msg)
  tubiLog("HomeScreenHelpers.onContentSelected")
  content = msg.getData()
  homeScreen = msg.getRoSGNode()
  m.autoplayContext = homeScreen.currCategoryId

  sBackMessage = "HOME"
  if homeScreen.id = m.constants.ui.screenIds.movieScreen
    sBackMessage = "MOVIES"
  else if homeScreen.id = m.constants.ui.screenIds.tvScreen
    sBackMessage = "TV SHOWS"
  end if

  if content.type = "channel"
    showChannelScreen(content, sBackMessage)
  else
    showDetailScreen(content)
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