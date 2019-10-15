' Show the homescreen, whether existing in the screen pool already or creating a new one
'
' @constants: assocArray, constants as set in Constants.brs and updated in the hotpatch
' @authInfo: assocArray, normally set by m.global.authInfo
Function showHomeScreen(constants, authInfo)
  tubiLog("HomeScreenHelpers.showHomeScreen")
  homeScreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
  if homeScreen <> invalid
    pushScreen(homeScreen, true, true)
  else
    homeScreen = CreateObject("roSGNode", "HomeScreen")
    homeScreen.observeFieldScoped("backgroundUriList", "homeScreenBackgroundUpdated")
    homeScreen.observeFieldScoped("navigateWithinPageInfo", "onNavigateWithinPageInfoChange")
    homeScreen.observeFieldScoped("loadAllCategories", "onLoadAllCategories")
    
    homeScreen.observeFieldScoped("contentSelected", "onContentSelected")
    homeScreen.observeFieldScoped("firstPosterLoaded", "onFirstPosterLoaded")
    m.top.observeField("homescreenResponse", "onHomescreenResponse")
    
    homeScreen.id = constants.ui.screenIds.homeScreen
    homeScreen.signedIn = (authInfo <> invalid)
    homeScreen.shouldKidsModeBeSentToServer = shouldKidsModeBeSentToServer()
    homeScreen.loadAllCategories = true
    
    setInScreenCache(homeScreen)
    'this is the first screen so no need for navigate_to_page tracking.
    'page_load tracking will happen when content is received.
    pushScreen(homeScreen, false, false)
  end if
End Function


'//If the homescreen is loading, then display the default background
Function setHomeScreenLoading(homeScreen)
  screen = currentScreen() 
  homeScreen.isLoading = true
  if screen <> invalid and screen.id = homeScreen.id
    '//Display default background if the hoime screen is the current screen while it is loading
    displayDefaultBackground()
  end if
End Function


' load all category content, including . Series do not have season or episode information though.
Function onLoadAllCategories(msg)
  tubiLog("HomeScreenHelpers.onLoadAllCategories")
  homeScreen = msg.getRoSGNode()
  ' This check causes all category fetches to be skipped prior to the field
  ' being set to true.  Then, once true it will reload any time loadCategories() is
  ' called, such as when signedIn field changes.
  if homeScreen.loadAllCategories = true
    reqName = m.constants.reqNames.getHomescreen
    '//::TODO:: JHAND - test error here!
    m.metadataFetchTask.request = m.metadataFetchTaskDTO.createRequest("homescreen", m.top, "homescreenResponse", reqName, invalid, shouldKidsModeBeSentToServer())
    setHomeScreenLoading(homeScreen)
  end if
End Function


''''''''''''''''''''''''''''''
' onHomescreenResponse
'
Function onHomescreenResponse()
  tubiLog("HomeScreenHelpers.onHomescreenResponse")
  homeScreen = getFromScreenCache(m.constants.ui.screenIds.homeScreen)
  if homeScreen <> invalid
    if m.top.homescreenResponse.response <> invalid then
      response = m.top.homescreenResponse.response
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
        homeScreen.content = m.top.homescreenResponse.convertedMetadata
        homeScreen.contentUpdated = true
      else
        ' if we were loading in the background, don't show an error modal
        if homeScreen.isInFocusChain()
          errorMessage = "Unable to load Tubi home screen."
          errorCode = getUserFacingErrorCode(m.constants.errors.context.homeScreen, m.constants.errors.subtypes.fetchError, response.code)
          dialogEvent = getHomescreenDialogAnalyticsEvent("NETWORK_ERROR", errorCode, m.Tracking)
          
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
    homeScreen.loadAllCategories = true
    homeScreen.setFocus(true)
  end if
End Function


Function sendHomeScreenDialogAnalyticsEvent(dialogType, trackingLib, trackingTask)
  trackingTask.trackEvent = {
    type: "dialog"
    values: {
      dialog_type: dialogType   'DialogType enum
      pageOneof: trackingLib.getAnalyticsPage("home_page", {})
    }
  }
End Function

' Show the detail screen for the selected content
Function onContentSelected(msg)
  tubiLog("HomeScreenHelpers.onContentSelected")
  content = msg.getData()
  homeScreen = msg.getRoSGNode()
  m.autoplayContext = homeScreen.currCategoryId
  
  if content.type = "channel"
    showChannelScreen(content, "HOME")
  else
    showDetailScreen(content)
  end if
End Function

