' Parse launch arguments for any deep linking.
' Returns a DeeplinkContentNode or invalid
' @args: assocArray, the args passed to main() at startup
'
' Feed: http://cms.adrise.com/roku/partnerSearch/xml
'
' ARGUMENTS TO ROKU MAIN():
'
' Non-deep link args and example values:
'   splashTime                      - "1600"
'   instant_on_run_mode             - "foreground"
'   lastExitOrTerminationReason     - "EXIT_UNKNOWN"
'   source                          - 'meta-search', 'external-control'
'
' Deep link args:
'   contentId    - string identifier
'   entry        - 'banner' or omitted for search source
'   mediaType    - "season", "series", "episode", "movie", "shortform", and "live"
'   entry        - string, custom parameter, used for tracking the source of deeplinks, passed to referred analytics events
'   deviceId     - string, custome paramater, the device id of the device sending the deeplink (used when mobile "casts" to roku)
'   resumeTime   - integer, custome paramater, the position from which a deeplink should resume (used when mobile "casts" to roku)
'   refreshToken - string, custome paramater, a token that can be used to refresh the auth token.
'                  Is used to transfer login info from a "casting" device to roku (used when mobile "casts" to roku)
'   userId       - integer, custome paramater, the user id of the user sending the deeplink (used when mobile "casts" to roku)
'
' deeplinks from iOS look like:
' http://192.168.20.31:8060/launch/41468?deviceId=E7E674A4%2D25DD%2D4B7A%2DBC67%2DB9AD1BAC7CC5&mediaType=movie&contentID=342067&resumeTime=0&userId=0&entry=iphone
' http://192.168.20.31:8060/launch/41468?mediaType=episode&entry=iphone&deviceId=E7E674A4%2D25DD%2D4B7A%2DBC67%2DB9AD1BAC7CC5&contentID=456881&userId=0&resumeTime=0
Function createDeeplinkContentFromStartupArgs(args)
  tubilog("DeeplinkHelpers.createDeeplinkContentFromStartupArgs")
  'handle/set up any deep linking that may have occurred
  if (args.contentId <> invalid or args.page <> invalid)
    content = CreateObject("roSGNode", "DeeplinkContentNode")
    if args.contentId <> invalid
      content.id = args.contentId
      tubiLog("Deep Link detected for content id " + content.id )
    else
      content.id = ""
      tubiLog("Deep Link detected for page ")
    end if


    ' default deep link source is no-source
    sourceArg = args.source
    if sourceArg = invalid or m.constants.deeplinks[sourceArg] = invalid
      content.source = "no-source"
    else
      content.source = m.constants.deeplinks[sourceArg]
    end if

    ' if there is a parameter called entry with a value, that is the source of the deep link
    ' typically entry = banner from the Roku banner ads ('entry' is a custom parameter)
    ' deep link urls with entry source should look like:
    ' contentID=18267&entry=banner
    if args.entry <> invalid
      content.source = args.entry
    end if

    ' the device id of the device deeplinking to roku. Might be an iOS or android device that is "casting" to roku.
    if args.deviceId <> invalid and args.deviceId.unescape() <> ""
      content.sourceDeviceId = args.deviceId.unescape()
    end if

    ' set up the resume time if we are deeplinking to a specific point in the video
    if args.resumeTime <> invalid
      content.nowPos = args.resumeTime.ToInt()
    end if

    ' if deep linked from Roku search it's possible that we are deep linking to a series, instead of actual video content
    ' deep links from search for series should like:
    ' contentID=335&mediaType=series
    ' or deeplinks for pages within the app where page parameter has been provided in which case mediatype will not provided
    ' page=network
    ' or page=network&contentId=fox
    ' See full list of mediaType at https://sdkdocs.roku.com/display/sdkdoc/External+Control+Guide

    if content.id <> "" and args.mediaType <> invalid ' video request expect for season
      if args.mediaType = "series"
        content.type = "series"
        content.deeplinkType = "series"
      else if args.mediaType = "season"
        content.type = "series"
        content.deeplinkType = "season"
      else if args.mediaType = "movie"
        content.type = "video"
        content.deeplinkType = "movie"
      else if args.mediaType = "episode"
        content.type = "video"
        content.deeplinkType = "episode"
      else if args.mediaType = "live"
        content.type = "linear"
        content.deeplinkType = "linear"
      end if
    else if args.mediaType = invalid and args.page <> invalid ' page request
      if args.page = "movies"
        content.deeplinkType = "moviePage"
      else if args.page = "live"
        content.deeplinkType = "liveTV"
      else if args.page = "genre"
        content.deeplinkType = "category"
      else if args.page = "network"
        content.deeplinkType = "channel"
      else if args.page = "tv"
        content.deeplinkType = "tvPage"
      else if args.page = "espanol"
        content.deeplinkType = "espanolPage"
      else if args.page = "alist"
        content.deeplinkType = "alistPage"
      else if args.page = "nostalgia"
        content.deeplinkType = "nostalgiaPage"
      else if args.page = "kids"
        content.deeplinkType = "kids"
      end if
    end if

    ' remove any 0s that might be prepended to the content id
    if content.source = "search"
      prepend = "0"
      while prepend = "0"
        prepend = left(content.id, 1)
        if prepend = "0"
          length = content.id.len()
          content.id = content.id.right(length - 1)
        end if
      end while
    end if

    'see tubitv.atlassian.net/wiki/display/EC/Referrals
    content.medium = "partnership"
    if args.medium <> invalid
      content.medium = args.medium
    end if

    'see tubitv.atlassian.net/wiki/display/EC/Referrals
    content.campaign = "default-campaign"
    if args.campaign <> invalid
      content.campaign = args.campaign
    end if

    return content
  else
    return invalid
  end if
End Function


Function handleDeeplink()
  tubiLog("ContentController.startUserExperience")
  handleDeeplinkContentByType()
End Function


Function handleInputDeeplink(inputInfo) as Void
  tubilog("DeeplinkHelpers.handleInputDeeplink")
  resetSideNav(false)
  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.videoPlayerScreen)
  stopVideoContent(videoPlayer) 'sets m.enteredFromDeeplink = false and m.deeplinkContent = invalid
  stopCountdownTimer() 'stop previous counter
  stopAndHideLinearVideoPlayer()
  if getExperimentResource("roku_video_preview", "roku_video_preview_v1", false).enabled = true
    stopVideoPreview()
  end if

  if m.uiMode = m.constants.ui.modes.kids
    if needsToShowAgeVerificationScreen() = true then
      showAgeVerificationScreenAtInputDeeplink(m.uiMode)
      return
    else
      ' turn off kids mode for input deeplinks (ie. voice commands)
      ' Normal kids mode allows users to exit kids mode, so treat voice command deeplink as if
      ' user is exiting kids mode.
      ' Keeping the "kidsAgeGate" and "kidsParental" uiModes will prevent voice command deeplinks
      ' from being successful unless the content is kids content.
      setUiMode(m.constants.ui.modes.standard)

      ' remove all screens if in kids mode so that when backing out of the details screen,
      ' the home screen will be re-populated as expected to the standard UI.
      shrinkScreenStack(0)
      emptyScreenCache()
    end if
  end if

  ' the following values will be used to save state and will be used in the process that
  ' is kicked off by showDetailScreen to load the detail screen and video player screen
  m.deeplinkContent = createDeeplinkContentFromStartupArgs(inputInfo)

  ' close any opened modal/pop-up when deeplinking via roInput
  for i=0 to m.top.getChildCount()-1
    screen = m.top.getChild(i)
    if screen <> invalid and screen.subType() = "ModalDialogScreen"
      closeModal(screen, "back")
    end if
  end for

  handleDeeplinkContentByType()

End Function


' this function calls appropriate functions to andle the deeplinks based on deeplink type
Function handleDeeplinkContentByType()
  tubilog("deeplinkHelpers.handleDeeplinkContentByType")
  if m.deepLinkContent <> invalid
    if m.deepLinkContent.deeplinkType = "linear" or m.deepLinkContent.deeplinkType = "liveTV"
      'if fadeInContentController is still playing, then linear content can not play.
      'in that case, consider handling the linear deeplink content after fade in animation is over in onFadeInContentController
      if m.top.fadeInContentController = true
        handleLinearDeeplinkContent()
      else
        m.linearScreenAfterFn = handleLinearDeeplinkContent
      end if
    else if m.deepLinkContent.deeplinkType = "category"
      handleCategoryDeeplinkContent()
    else if m.deepLinkContent.deeplinkType = "channel"
      handleNetworkDeeplinkContent()
    else if m.deepLinkContent.deeplinkType = "moviePage"
      handleMoviesPageDeeplinkContent()
    else if m.deepLinkContent.deeplinkType = "kids"
      handleKidsPageDeeplinkContent()
    else if m.deepLinkContent.deeplinkType = "nostalgiaPage"
      handleNostalgiaPageDeeplinkContent()
    else if m.deepLinkContent.deeplinkType = "alistPage"
      handleBestKnownPageDeeplinkContent()
    else if m.deepLinkContent.deeplinktype = "espanolPage"
      handleEspanolPageDeeplinkContent()
    else if m.deepLinkContent.deeplinktype = "tvPage"
      handleTVPageDeeplinkContent()
    else if m.deepLinkContent.deeplinktype = "series"
      if Left(m.deepLinkContent.id, 1) = "0"
        showDetailScreen(m.deepLinkContent, false, skipDetailScreen, handleSingleContentDeeplinkError)
      else
        getSingleContentFromServer(m.deeplinkContent, onDeeplinkSeriesContentSuccess, handleSingleContentDeeplinkError)
      end if
    else if m.deepLinkContent.deeplinktype = "episode"
      getSingleContentFromServer(m.deeplinkContent, onDeeplinkEpisodeContentSuccess, handleSingleContentDeeplinkError)
    else if m.deepLinkContent.deeplinktype = "season"
      if Left(m.deepLinkContent.id, 1) = "0"
        showDetailScreen(m.deepLinkContent, false, skipDetailScreen, handleSingleContentDeeplinkError)
      else
        getSingleContentFromServer(m.deeplinkContent, onDeeplinkSeasonContentSuccess, handleSingleContentDeeplinkError)
      end if
    else if m.deepLinkContent.deeplinktype = "movie"
      showDetailScreen(m.deeplinkContent, false, skipDetailScreen, handleSingleContentDeeplinkError)
    else
      message = getTranslation("error_deeplink_page")
      showDeeplinkErrorModal(invalid, message)
    end if
  end if

End Function


Function fetchSingleLinearChannel()
  tubilog("deeplinkHelpers.deeplinkPlayLinearChannel")
  if getExperimentResource("roku_linear_epg", "roku_linear_epg_v5", false).enabled = true
    screenId = m.constants.ui.screenIds.epgScreen
  else
    screenId = m.constants.ui.screenIds.linearTVScreen
  end if
  fetchEPGChannel(screenId, m.deeplinkContent.id, onSingleChannelFetchForDeeplinkSuccess , showDeeplinkErrorModal)

End Function


Function onSingleChannelFetchForDeeplinkSuccess(successResponse, storeInCache=false)
  tubilog("deeplinkHelpers.onSingleChannelFetchForDeeplinkSuccess")
  linearContent = invalid
  if successResponse.getChildCount() > 0
    linearContent = successResponse.getChild(0)
    linearContent.deeplinktype = "linear"
  end if

  if linearContent <> invalid
    if m.enteredFromDeepLink = true
      sendDeeplinkAnalytics(m.deepLinkContent, linearContent, m.constants.deeplinks.entryPoints.video, m.Tracking, m.trackingLoggingTask, m.constants)
    end if
    ' if the uimode is locked by parentalControl or kidsAgeGate, then show the error model that the
    ' content can be played because of parental controls
    if isKidsModeEnabledByParentalControls() = true or m.uiMode = m.constants.ui.modes.kidsAgeGate
      message = getTranslation("dialog_contentNotAvailable_Parental_description")
      showDeeplinkErrorModal(invalid, message)
    else
      ' once the channel has been fetched and then set it in the cache to be used by EPG/homeScreen
      if storeInCache = true
        setInContentCache(linearContent)
      end if

      'if linear EPG experiment is on, then show epg Screen for linear content
      ' if not, then display the linear Home Screen.
      if getExperimentResource("roku_linear_epg", "roku_linear_epg_v5", false).enabled = true
        showDefaultEPGScreen()
        epgScreen = getFromScreenCache(m.constants.ui.screenIds.epgScreen)
        if epgScreen.timeGridContent = invalid or epgScreen.timeGridContentLoading = true
          epgScreen.contentIdToFocusOnLoadComplete = linearContent.id
        end if
        playLinearVideoContent(linearContent, false, m.constants.ui.screenIds.epgScreen)
        sEPGSideNavID = m.constants.ui.screenIdToSideNavId[m.constants.ui.screenIds.epgScreen]
      else
        showLinearTVScreen()
        playLinearVideoContent(linearContent, false, m.constants.ui.screenIds.linearTVScreen)
        sEPGSideNavID = m.constants.ui.screenIdToSideNavId[m.constants.ui.screenIds.homeScreen]
      end if
      focusSideNavOption(sEPGSideNavID)
    end if
  else
    showDeeplinkErrorModal()
   end if

  'm.enteredFromDeepLink will be set to false when back button is pressed on video
  m.deeplinkContent = invalid
End Function


' error callback and error handler for deeplinks.
' @response: roSGNode, error response content
' @message: string, message to show on the deeplink error modal if not using the default
Function showDeeplinkErrorModal(response=invalid,  message = "")
  tubilog("deeplinkHelpers.showDeeplinkErrorModal")
  if message = ""
    message = getTranslation("error_deeplink_content")
  end if

  dialogType = "CONTENT_NOT_FOUND"
  if response <> invalid
    if response.code = 404
      dialogType = "CONTENT_NOT_FOUND" 'DialogType enum
    else if response.code = 403 or response.code = 451 or response.code = 401 or response.code = 422
      dialogType = "RESTRICTED_CONTENT"
      message = getTranslation("dialog_contentNotAvailable_Parental_description")
    end if
  else if isKidsModeEnabledByParentalControls() = true or m.uiMode = m.constants.ui.modes.kidsAgeGate
    dialogType = "RESTRICTED_CONTENT"
    message = getTranslation("dialog_contentNotAvailable_Parental_description")
  end if

  title = getTranslation("dialog_errorOops_title")

  if m.enteredFromDeepLink = true

    sendDeeplinkAnalytics(m.deepLinkContent, m.deepLinkContent, m.constants.deeplinks.entryPoints.home, m.Tracking, m.trackingLoggingTask, m.constants)
    resetDeeplinkValues()
    startChannel() 'adds a homescreen which will remove all other screens underneath

    dialogEvent = {
      type: "dialog"
      values: {
        dialog_type: dialogType
        pageOneof: m.Tracking.getAnalyticsPage("home_page", {content_mode: "CONTENT_MODE_UNKNOWN"})
        dialog_action: "SHOW"
        dialog_sub_type: "launch-deeplink"
      }
    }

    showSimpleInstantResumableModal(title, message, [], dialogEvent, m.trackingLoggingTask)

  else if m.deepLinkContent <> invalid
    m.deepLinkContent = invalid
    ' we are in this block if there is a roInputEvent causing a deeplink (ie. voice control while the channel is open)
    currentScreen = getCurrentScreen()
    if currentScreen <> invalid
      dialogEvent = {
        type: "dialog"
        values: {
          dialog_type: dialogType
          pageOneof: m.Tracking.getAnalyticsPage(currentScreen.trackingPageInfo.pageType, currentScreen.trackingPageInfo.pageValues)
          dialog_action: "SHOW"
          dialog_sub_type: "input-deeplink"
        }
      }
      showSimpleInstantResumableModal(title, message, [], dialogEvent, m.trackingLoggingTask)
    end if
  end if

End Function


' Organizes the information needed to create a "referred" tracking event and sends the information to the trackingTask which will
' actually send the event.
'
' @deepLinkContent: roSGNode, a content node created by deeplink logic and passed to the content controller via m.deeplinkContent
' @refreshedContent: roSGNode, a content node containing full information from the /content API
' @entryPoint: string, indicates where the user will land after the deeplink, can be one of: constants.deeplinks.entryPoints
' @trackingLib: associativeArray, an instance of TubiTracking()
' @trackingTask: roSGNode, an instance of the TrackingLoggingTask
' @constants: associativeArray, m.constants
Function sendDeeplinkAnalytics(deepLinkContent, refreshedContent, entryPoint, trackingLib, trackingTask, constants)
  referredAnalyticsEvent = {
    referred_type: "DEEP_LINK"
    campaign: deepLinkContent.campaign
    source: deepLinkContent.source
    medium: deepLinkContent.medium
    source_device_id: deepLinkContent.sourceDeviceId
  }

  if (deepLinkContent.type = m.constants.ui.contentTypes.linear or deepLinkContent.type = m.constants.ui.contentTypes.video or (deepLinkContent.type = "series" and deepLinkContent.deeplinkType = "series")) and deepLinkContent.id <> invalid and deepLinkContent.id <> ""
    pageInfo = {
      pageType: "video_player_page"
      pageValues: {
        video_id: deepLinkContent.Id.toInt()
      }
    }
  else
    pageInfo = getDetailScreenAnalyticsPageInfo(refreshedContent, constants)
  end if

  if entryPoint =  m.constants.deeplinks.entryPoints.detail
    referredAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
  else if entryPoint = m.constants.deeplinks.entryPoints.home
    referredAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage("home_page", {content_mode: "CONTENT_MODE_UNKNOWN"})
  else if entryPoint = m.constants.deeplinks.entryPoints.epg
    referredAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage("linear_browse_page", {})
  else if entryPoint = m.constants.deeplinks.entryPoints.category
    referredAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage("category_list_page", {})
  else if entryPoint = m.constants.deeplinks.entryPoints.channel
    referredAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage("channel_list_page", {})
  else if entryPoint = m.constants.deeplinks.entryPoints.espanol
    referredAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage("home_page", {content_mode: "CONTENT_MODE_LATINO"})
  else if entryPoint = m.constants.deeplinks.entryPoints.nostalgia
    referredAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage("home_page", {content_mode: "CONTENT_MODE_NOSTALGIA"})
  else if entryPoint = m.constants.deeplinks.entryPoints.bestKnown
    referredAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage("home_page", {content_mode: "CONTENT_MODE_ALIST"})
  else if entryPoint = m.constants.deeplinks.entryPoints.movies
    referredAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage("home_page", {content_mode: "CONTENT_MODE_MOVIE"})
  else if entryPoint = m.constants.deeplinks.entryPoints.tv
    referredAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage("home_page", {content_mode: "CONTENT_MODE_TV"})
  else if entryPoint = m.constants.deeplinks.entryPoints.categoryDetail
    referredAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage("category_page",  {"category_slug": deepLinkContent.id})
  else if entryPoint = m.constants.deeplinks.entryPoints.news
    referredAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage("home_page", {content_mode: "CONTENT_MODE_LINEAR"})
  else if entryPoint = m.constants.deeplinks.entryPoints.episodeList
    if deepLinkContent <> invalid
      seriesId = deepLinkContent.id.toInt()
      referredAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage("episode_video_list_page", { series_id: seriesId })
    end if
  else if entryPoint =  m.constants.deeplinks.entryPoints.video and pageInfo <> invalid
    referredAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
  end if

  trackingTask.trackEvent = {
    type: "referred"
    values: referredAnalyticsEvent
  }
End Function


Function handleLinearDeeplinkContent()
  tubilog("DeeplinkHelpers.handleLinearDeeplinkContent")

  if isParentalControlsAdultLevel() = false or m.uiMode = m.constants.ui.modes.kidsAgeGate
    ' Display error message indicating to turn off the parental controls
    message = getTranslation("dialog_contentNotAvailable_Parental_description")
    showDeeplinkErrorModal(invalid, message)
  else
    ' linear deeplink request has been recieved with content ID to play, so fetch and start playing the content
    if m.deeplinkContent.id <> ""
      fetchSingleLinearChannel()
      if getExperimentResource("roku_linear_epg", "roku_linear_epg_v5", false).side_nav = true
        sCatSideNavID = m.constants.ui.screenIdToSideNavId[m.constants.ui.screenIds.EPGScreen]
      else
        sCatSideNavID = m.constants.ui.sideNavIds.home
      end if
    else
      if isICTSExperimentEnabled() = true
        m.contentExperienceMode = m.constants.ui.contentExperienceModes.liveTV
      end if

      ' without contentId(deeplinkContentId),  just display the default epg Screen or linear TV screen.
      if getExperimentResource("roku_linear_epg", "roku_linear_epg_v5", false).enabled = true
        if m.enteredFromDeepLink = true
          sendDeeplinkAnalytics(m.deepLinkContent, m.deepLinkContent, m.constants.deeplinks.entryPoints.epg, m.Tracking, m.trackingLoggingTask, m.constants)
        end if
        showDefaultEPGScreen()
        sCatSideNavID = m.constants.ui.screenIdToSideNavId[m.constants.ui.screenIds.EPGScreen]
      else
        if m.enteredFromDeepLink = true
          sendDeeplinkAnalytics(m.deepLinkContent, m.deepLinkContent, m.constants.deeplinks.entryPoints.news, m.Tracking, m.trackingLoggingTask, m.constants)
        end if
        showLinearTVScreen()
        sCatSideNavID = m.constants.ui.sideNavIds.home
      end if
    end if
    focusSideNavOption(sCatSideNavID)
  end if
End Function


Function handleCategoryDeeplinkContent()
  tubilog("DeeplinkHelpers.handleCategoryDeeplinkContent")


  if m.deeplinkContent.id <> ""
    if m.enteredFromDeepLink = true
      sendDeeplinkAnalytics(m.deepLinkContent, m.deepLinkContent, m.constants.deeplinks.entryPoints.categoryDetail, m.Tracking, m.trackingLoggingTask, m.constants)
    end if
    showCategoryListScreen(m.constants, m.constants.ui.terms.menu,false)
    contentNode = CreateObject("roSGNode", "CategoryContentNode")
    contentNode.id = m.deeplinkContent.id
    showCategoryDetailsScreen(contentNode, m.constants.ui.terms.categories, false)
    categorylListScreen = getFromScreenCache(m.constants.ui.screenIds.categoryListScreen)
    if categorylListScreen <> invalid
      categorylListScreen.jumpToItemById = m.deeplinkContent.id
    end if
  else
    if m.enteredFromDeepLink = true
      sendDeeplinkAnalytics(m.deepLinkContent, m.deepLinkContent, m.constants.deeplinks.entryPoints.category, m.Tracking, m.trackingLoggingTask, m.constants)
    end if
    showCategoryListScreen(m.constants, m.constants.ui.terms.menu, true)
  end if
  sCatSideNavID = m.constants.ui.sideNavIds.categories

  if (isParentalControlsAdultLevel() = true or isParentalControlsTeensLevel() = true) and m.uiMode <> m.constants.ui.modes.kidsAgeGate
    setUiMode(m.constants.ui.modes.standard)
  end if

  focusSideNavOption(sCatSideNavID)
  resetDeeplinkValues()

End Function


Function handleNetworkDeeplinkContent()
  tubilog("DeeplinkHelpers.handleNetworkDeeplinkContent")

  if isParentalControlsAdultLevel() = false or m.uiMode = m.constants.ui.modes.kidsAgeGate
    ' Display error message indicating to turn off the parental controls
    message = getTranslation("dialog_sideNavItemDisabled_Parental_description")
    showDeeplinkErrorModal(invalid, message)
  else
    if m.deeplinkContent.id <> ""
      if m.enteredFromDeepLink = true
        sendDeeplinkAnalytics(m.deepLinkContent, m.deepLinkContent, m.constants.deeplinks.entryPoints.categoryDetail, m.Tracking, m.trackingLoggingTask, m.constants)
      end if
      showChannelListScreen(m.constants, m.constants.ui.terms.menu, false)
      contentNode = CreateObject("roSGNode", "CategoryContentNode")
      contentNode.id = m.deeplinkContent.id
      showCategoryDetailsScreen(contentNode, m.constants.ui.terms.channels, false)
      channelListScreen = getFromScreenCache(m.constants.ui.screenIds.channelListScreen)
      if channelListScreen <> invalid
        channelListScreen.jumpToItemById = m.deeplinkContent.id
      end if
    else
      if m.enteredFromDeepLink = true
        sendDeeplinkAnalytics(m.deepLinkContent, m.deepLinkContent, m.constants.deeplinks.entryPoints.channel, m.Tracking, m.trackingLoggingTask, m.constants)
      end if
      showChannelListScreen(m.constants, m.constants.ui.terms.menu, true)
    end if
    setUiMode(m.constants.ui.modes.standard)
  end if
  focusSideNavOption(m.constants.ui.sideNavIds.channels)
  resetDeeplinkValues()

End Function


Function handleKidsPageDeeplinkContent()
  tubilog("DeeplinkHelpers.handleKidsPageDeeplinkContent")

  if m.enteredFromDeepLink = true
    sendDeeplinkAnalytics(m.deepLinkContent, m.deepLinkContent, m.constants.deeplinks.entryPoints.home, m.Tracking, m.trackingLoggingTask, m.constants)
  end if

  setUiMode(m.constants.ui.modes.kids)
  reloadDefaultHomeScreenContent()
  showDefaultHomeScreen()
  focusSideNavOption(m.constants.ui.sideNavIds.home)
  resetDeeplinkValues()

End Function


Function handleEspanolPageDeeplinkContent()
  tubilog("DeeplinkHelpers.handleEspanolPageDeeplinkContent")
  if m.enteredFromDeepLink = true
    sendDeeplinkAnalytics(m.deepLinkContent, m.deepLinkContent, m.constants.deeplinks.entryPoints.espanol, m.Tracking, m.trackingLoggingTask, m.constants)
  end if
  if isParentalControlsAdultLevel() = false or m.uiMode = m.constants.ui.modes.kidsAgeGate
    ' Display error message indicating to turn off the parental controls
    message = getTranslation("dialog_sideNavItemDisabled_Parental_description")
    showDeeplinkErrorModal(invalid, message)
  else
    m.contentExperienceMode = m.constants.ui.contentExperienceModes.espanol
    setUiMode(m.constants.ui.modes.latino)
    showEspanolScreen()
    if isICTSExperimentEnabled() = true
      focusSideNavOption(m.constants.ui.sideNavIds.home)
    else
      focusSideNavOption(m.constants.ui.sideNavIds.espanol)
    end if

  end if
  resetDeeplinkValues()
End Function


Function handleNostalgiaPageDeeplinkContent()
  tubilog("DeeplinkHelpers.handleNostalgiaPageDeeplinkContent")
  if m.enteredFromDeepLink = true
    sendDeeplinkAnalytics(m.deepLinkContent, m.deepLinkContent, m.constants.deeplinks.entryPoints.nostalgia, m.Tracking, m.trackingLoggingTask, m.constants)
  end if
  if isParentalControlsAdultLevel() = false or m.uiMode = m.constants.ui.modes.kidsAgeGate
    ' Display error message indicating to turn off the parental controls
    message = getTranslation("dialog_sideNavItemDisabled_Parental_description")
    showDeeplinkErrorModal(invalid, message)
  else
    m.contentExperienceMode = m.constants.ui.contentExperienceModes.nostalgia
    setUiMode(m.constants.ui.modes.standard)
    showNostalgiaScreen()
    focusSideNavOption(m.constants.ui.sideNavIds.home)
  end if
  resetDeeplinkValues()
End Function


Function handleBestKnownPageDeeplinkContent()
  tubilog("DeeplinkHelpers.handleBestKnownPageDeeplinkContent")
  if m.enteredFromDeepLink = true
    sendDeeplinkAnalytics(m.deepLinkContent, m.deepLinkContent, m.constants.deeplinks.entryPoints.bestKnown, m.Tracking, m.trackingLoggingTask, m.constants)
  end if
  if isParentalControlsAdultLevel() = false or m.uiMode = m.constants.ui.modes.kidsAgeGate
    ' Display error message indicating to turn off the parental controls
    message = getTranslation("dialog_sideNavItemDisabled_Parental_description")
    showDeeplinkErrorModal(invalid, message)
  else
    m.contentExperienceMode = m.constants.ui.contentExperienceModes.bestKnown
    setUiMode(m.constants.ui.modes.standard)
    showBestKnownScreen()
    focusSideNavOption(m.constants.ui.sideNavIds.home)
  end if
  resetDeeplinkValues()
End Function


Function handleMoviesPageDeeplinkContent()
  tubilog("DeeplinkHelpers.handleMoviesPageDeeplinkContent")

  if isParentalControlsTeensLevel() = true
    if m.enteredFromDeepLink = true
      sendDeeplinkAnalytics(m.deepLinkContent, m.deepLinkContent, m.constants.deeplinks.entryPoints.movies, m.Tracking, m.trackingLoggingTask, m.constants)
    end if
    'teens get TV screen and movie screen
    showMoviesScreen()
    focusSideNavOption(m.constants.ui.sideNavIds.home)
  else if isParentalControlsAdultLevel() = false or m.uiMode = m.constants.ui.modes.kidsAgeGate
      ' Display error message indicating to turn off the parental controls
      message = getTranslation("dialog_sideNavItemDisabled_Parental_description")
      showDeeplinkErrorModal(invalid, message)
      setUiMode(m.constants.ui.modes.kids)
  else
    if m.enteredFromDeepLink = true
      sendDeeplinkAnalytics(m.deepLinkContent, m.deepLinkContent, m.constants.deeplinks.entryPoints.movies, m.Tracking, m.trackingLoggingTask, m.constants)
    end if
    setUiMode(m.constants.ui.modes.standard)
    showMoviesScreen()
    focusSideNavOption(m.constants.ui.sideNavIds.home)
  end if
  resetDeeplinkValues()

End Function


Function handleTVPageDeeplinkContent()
  tubilog("DeeplinkHelpers.handleTVPageDeeplinkContent")

  if isParentalControlsTeensLevel() = true
    if m.enteredFromDeepLink = true
      sendDeeplinkAnalytics(m.deepLinkContent, m.deepLinkContent, m.constants.deeplinks.entryPoints.tv, m.Tracking, m.trackingLoggingTask, m.constants)
    end if
    'teens get TV screen and movie screen
    showTVScreen()
    focusSideNavOption(m.constants.ui.sideNavIds.home)
  else if isParentalControlsAdultLevel() = false or m.uiMode = m.constants.ui.modes.kidsAgeGate
    ' Display error message indicating to turn off the parental controls
    message = getTranslation("dialog_sideNavItemDisabled_Parental_description")
    showDeeplinkErrorModal(invalid, message)
    setUiMode(m.constants.ui.modes.kids)
  else
    if m.enteredFromDeepLink = true
      sendDeeplinkAnalytics(m.deepLinkContent, m.deepLinkContent, m.constants.deeplinks.entryPoints.tv, m.Tracking, m.trackingLoggingTask, m.constants)
    end if
    setUiMode(m.constants.ui.modes.standard)
    showTVScreen()
    focusSideNavOption(m.constants.ui.sideNavIds.home)
  end if
  resetDeeplinkValues()
End Function


Function resetDeeplinkValues()
  m.deepLinkContent = invalid
  m.enteredFromDeepLink = false
End Function


' success handler for Series deeplinks.
' @detailScreen: roSGNode, series detail page
' @refreshedContent: roSGNode, success response content
' @sendTracking: boolean , this paramter is used to control whether NavigateToPage events needs to send or not. In case of deeplinks, no need to send NavigateToPage Event
Function handleDeeplinkSeriesSuccessResponse(refreshedContent)
  history = getHistory(refreshedContent.id)

  '  refreshedContent.id:       series id
  '  refreshedContent.seriesId: invalid
  '  refreshedContent.type:     series
  '  m.deepLinkContent.deepLinkType: series

  ' As of spring 2018 (firmware 8.1), "series" media types are valid and
  ' will have a content id of an episode, not the series.  Roku states that
  ' the episode id is NOT what should be played, rather we are allowed
  ' to choose the most appropriate episode and automatically start playback.
  ' Here we use the history to choose an episode or just default to the first one.
  afterFn = playHelper
  if history <> invalid
    refreshedContent.currentEpisodeId = history.currentEpisodeId
    episode = getEpisodeContent(refreshedContent)

    episodeHistory = getHistory(episode.id)

    if episodeHistory <> invalid and episodeHistory.nowPos > 0
      episode.nowPos = episodeHistory.nowPos
      afterFn = resumeHelper
    end if
  else
    refreshedContent.currentEpisodeId = ""
  end if

  if m.enteredFromDeepLink = true
    ' m.enteredFromDeepLink will be set to false when the video is played
    sendDeeplinkAnalytics(m.deepLinkContent, refreshedContent, m.constants.deeplinks.entryPoints.video, m.Tracking, m.trackingLoggingTask, m.constants)
  end if

  detailScreen = getTopDetailScreenFromStack()

  if detailScreen <> invalid
    detailScreen.contentFetchError = false
    populateDetailScreen(detailScreen, refreshedContent)
    handleDetailScreenAfterFn(detailScreen, afterFn)
  end if
End Function

' success handler for video fetch in case of series/season/episode deeplinks.
' @refreshedContent: roSGNode, success video response content
' @successcb: successcallback which will handle success response after fetching video for provided contentId
' @errorcb: errorCallback which will handle error while fetching video for provided contentId
Function handleDeeplinkVideoSuccessResponse(refreshedContent, successCb = invalid, errorCb = invalid) as Void
  '  refreshedContent.id =       episode id
  '  refreshedContent.seriesId = series id
  '  refreshedContent.type =     video
  '  m.deepLinkContent.deepLinkType = season | episode | series

  ' deeplink sent us an episode id, so here, we have full info for an episode, but we need full info for a series
  ' don't send deeplink analytics here, we will send it once we get the refreshedContent (response from getSingleContentFromServer())
  emptySeriesNode = CreateObject("roSGNode", "TubiContentNode")
  emptySeriesNode.type = m.constants.ui.contentTypes.series
  emptySeriesNode.id = refreshedContent.seriesId
  showDetailScreen(emptySeriesNode, false, successCb, errorCb)
End Function


Function handleDeeplinkSeasonSuccessResponse(refreshedContent)
  '  refreshedContent.id =       series id
  '  refreshedContent.seriesId = invalid
  '  refreshedContent.type =     series
  '  m.deepLinkContent.deepLinkType = season

  ' we've now received the full series info, so we can build the relevant screens
  refreshedContent.currentEpisodeId = m.deepLinkContent.id
  ' when deeplinkType = "season", deeplinkContent.id should be an episode id. We want to send tracking with the series id.
  m.deepLinkContent.id = refreshedContent.id
  afterFn = episodesHelper

  if m.enteredFromDeepLink = true
    sendDeeplinkAnalytics(m.deepLinkContent, refreshedContent, m.constants.deeplinks.entryPoints.episodeList, m.Tracking, m.trackingLoggingTask, m.constants)
    m.enteredFromDeepLink = false
  end if
  detailScreen = getTopDetailScreenFromStack()
  if detailScreen <> invalid
    detailScreen.contentFetchError = false
    populateDetailScreen(detailScreen, refreshedContent)
    handleDetailScreenAfterFn(detailScreen, afterFn)
  end if
End Function


Function handleDeeplinkEpisodeSuccessResponse(refreshedContent)
  history = getHistory(refreshedContent.id)
  '  refreshedContent.id =       series id
  '  refreshedContent.seriesId = invalid
  '  refreshedContent.type =     series
  '  m.deepLinkContent.deepLinkType = episode

  ' we now have the full series info for episode deeplinks
  refreshedContent.currentEpisodeId = m.deepLinkContent.id
  'determine if we need to resume or play from start the deeplinked episode
  if history <> invalid
    episode = getEpisodeContent(refreshedContent)
    episodeHistory = getHistory(episode.id)
    if episodeHistory <> invalid and episodeHistory.nowPos > 0
      episode.nowPos = episodeHistory.nowPos
    end if
    afterFn = resumeHelper
  else
    afterFn = playHelper
  end if

  if m.enteredFromDeepLink = true
    ' m.enteredFromDeepLink will be set to false when the video is played
    sendDeeplinkAnalytics(m.deepLinkContent, refreshedContent, m.constants.deeplinks.entryPoints.video, m.Tracking, m.trackingLoggingTask, m.constants)
  end if
  detailScreen = getTopDetailScreenFromStack()

  if detailScreen <> invalid
    detailScreen.contentFetchError = false
    populateDetailScreen(detailScreen, refreshedContent)
    handleDetailScreenAfterFn(detailScreen, afterFn)
  end if
End Function


'this function will be called to get series details and then to fetch video to be played by deeplinkContent.id
Function onDeeplinkSeriesContentSuccess(singleContent)
  tubilog("deeplinkHelpers.onDeeplinkSeriesContentSuccess")
  if singleContent.type = m.constants.ui.contentTypes.video
    handleDeeplinkVideoSuccessResponse(singleContent, handleDeeplinkSeriesSuccessResponse, handleSingleContentDeeplinkError)
  end if
End Function


'this function will be called to get series details and then to fetch video to be played by deeplinkContent.id
Function onDeeplinkEpisodeContentSuccess(singleContent)
  tubilog("deeplinkHelpers.onDeeplinkEpisodeContentSuccess")

  if singleContent.type = m.constants.ui.contentTypes.video
    handleDeeplinkVideoSuccessResponse(singleContent,  handleDeeplinkEpisodeSuccessResponse, handleSingleContentDeeplinkError)
  end if

End Function


Function onDeeplinkSeasonContentSuccess(singleContent)
  tubilog("deeplinkHelpers.onDeeplinkSeasonContentSuccess")
  if singleContent.type = m.constants.ui.contentTypes.video
    handleDeeplinkVideoSuccessResponse( singleContent, handleDeeplinkSeasonSuccessResponse, handleSingleContentDeeplinkError)
  end if
End Function


Function handleSingleContentDeeplinkError(error)
  tubilog("DeeplinkHelpers.handleSingleContentDeeplinkError")

  message = getTranslation("screenDetails_error_getContent_description")
  if m.enteredFromDeepLink = false and m.deepLinkContent <> invalid
    'only in case of the movie, we have already sneaked the showdetail screen, so we need to
    'bring the user to previous screen.
    if m.deepLinkContent.deeplinktype = "movie"
      detailScreen = getTopDetailScreenFromStack()
      if detailScreen <> invalid and detailScreen.content.id = m.deepLinkContent.id
        'Simply popping the screen is resulting in issues, so calling onDetailBackPressed function.
        onDetailBackPressed()
      end if
    end if

    'If user issues input deeplink on linearvideoplayer/videoplayer, video will stop and tries to play deeplink content.
    'In case of deeplink error, bring the user back to detail screen.
    currentScreen = getCurrentScreen()
    if currentScreen.id = m.constants.ui.screenIds.linearVideoPlayerScreen
      returnToPreviousScreenFromLinearVideo(false)
    else if currentScreen.id = m.constants.ui.screenIds.videoPlayerScreen
      returnToDetailScreenFromVideo(true)
    end if
  end if
  showDeeplinkErrorModal(error, message)

End Function
