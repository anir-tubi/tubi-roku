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
'   mediaType    - "season", "series", "episode", "movie", "shortFormVideo", "tvspecial", "sportsevent", "livestream" and "livefeed"
'   entry        - string, custom parameter, used for tracking the source of deeplinks, passed to referred analytics events
'   deviceId     - string, custom paramater, the device id of the device sending the deeplink (used when mobile "casts" to roku)
'   resumeTime   - integer, custom paramater, the position from which a deeplink should resume (used when mobile "casts" to roku)
'   refreshToken - string, custom paramater, a token that can be used to refresh the auth token.
'                  Is used to transfer login info from a "casting" device to roku (used when mobile "casts" to roku)
'   userId       - integer, custom paramater, the user id of the user sending the deeplink (used when mobile "casts" to roku)
'
' deeplinks from iOS look like:
' http://192.168.20.31:8060/launch/41468?deviceId=E7E674A4%2D25DD%2D4B7A%2DBC67%2DB9AD1BAC7CC5&mediaType=movie&contentID=342067&resumeTime=0&userId=0&entry=iphone
' http://192.168.20.31:8060/launch/41468?mediaType=episode&entry=iphone&deviceId=E7E674A4%2D25DD%2D4B7A%2DBC67%2DB9AD1BAC7CC5&contentID=456881&userId=0&resumeTime=0
Function createDeeplinkContentFromStartupArgs(args)
  tubilog("DeeplinkHelpers.createDeeplinkContentFromStartupArgs")
  'handle/set up any deep linking that may have occurred
  if (args.contentId = invalid AND args.page = invalid) then
    return invalid
  end if

  content = CreateObject("roSGNode", "DeeplinkContentNode")
  if args.contentId <> invalid
    content.id = args.contentId
    tubiLog("Deep Link detected for content id " + content.id)
  else
    content.id = ""
    tubiLog("Deep Link detected for page")
  end if


  ' default deep link source is no-source
  sourceArg = args.source
  mediaType = args.mediaType
  if isNonEmptyString(mediaType) = true
    mediaType = LCase(mediaType)
  end if
  if args <> invalid AND arrayIncludes(["sportsevent", "livestream", "livefeed"], mediaType)
    content.source = m.constants.deeplinks["sports-hub"]
  else if sourceArg = invalid OR m.constants.deeplinks[sourceArg] = invalid
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
  if args.deviceId <> invalid AND args.deviceId.unescape() <> ""
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

  if isNonEmptyString(content.id) = true AND args.mediaType <> invalid ' video request expect for season
    mediaType = LCase(args.mediaType)
    if mediaType = "series"
      content.type = "series"
      content.deeplinkType = "series"
    else if mediaType = "season"
      content.type = "series"
      content.deeplinkType = "season"
    else if mediaType = "movie" OR mediaType = "tvspecial"
      content.type = "video"
      content.deeplinkType = "movie"
    else if mediaType = "episode"
      content.type = "video"
      content.deeplinkType = "episode"
    else if mediaType = "shortformvideo"
      content.type = "video"
      content.deeplinkType = "shortFormVideo"
    else if mediaType = "livefeed" OR mediaType = "livestream" OR mediaType = "sportsevent"
      if mediaType = "sportsevent"
        sportsEvent = parseSportsEventContentId(content.id)
        ' channel is used short term, eventually we should use program id
        if isNonEmptyString(sportsEvent.channel) then
          content.id = sportsEvent.channel
        end if
      end if
      content.type = "linear"
      content.deeplinkType = "linear"
    else if mediaType = "sports"
      content.type = "video"
      content.deeplinkType = "sports"
      ' Temporary for Fox player testing
    else if mediaType = "fox"
      content.type = "linear"
      content.deeplinkType = "fox"
    end if
  else if args.mediaType = invalid AND args.page <> invalid ' page request
    page = LCase(args.page)
    if page = "movies"
      content.deeplinkType = "moviePage"
    else if page = "livefeed"
      content.deeplinkType = "liveTV"
    else if page = "genre" OR page = "category"
      content.deeplinkType = "category"
    else if page = "network"
      content.deeplinkType = "channel"
    else if page = "tv"
      content.deeplinkType = "tvPage"
    else if page = "espanol"
      content.deeplinkType = "espanolPage"
    else if page = "kids"
      content.deeplinkType = "kids"
    else if page = "home"
      content.deeplinkType = "homePage"
    end if
  end if

  if sourceArg = m.constants.deeplinks["external-control"] AND isNonEmptyString(args.roomId) = true
    content.deeplinkType = "cast"
    content.roomId = args.roomId
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
End Function


' Creates utmCampaignConfig AA for use with tensor API
' Returns AA or invalid
' @args: assocArray, the args passed to main() at startup
' Deep link args:
'   avd - string, custom parameter, provides a means of identifying what creative someone saw that brought them into the application
'   utm_campaign_config - string, custom parameter, JSON string containing avd. If both are passed in avd will be used instead
Function generateUtmCampaignConfig(args)
  utmCampaignConfig = invalid
  if isString(args.avd) = true then
    json = formatJson({
      "avd": args.avd
    })
    ba = createObject("roByteArray")
    ba.fromAsciiString(json)
    utmCampaignConfig = ba.toBase64String()
  else if isString(args.utm_campaign_config) = true then
    utmCampaignConfig = args.utm_campaign_config
  end if
  return utmCampaignConfig
End Function


Function handleDeeplink()
  tubiLog("ContentController.handleDeeplink")
  handleDeeplinkContentByType()
End Function


Function handleInputDeeplink(inputInfo) as Void
  tubilog("DeeplinkHelpers.handleInputDeeplink")
  resetSideNav(false)
  videoPlayer = getFromScreenCache(m.constants.ui.screenIds.videoPlayerScreen)
  stopVideoContent(videoPlayer) 'sets m.enteredFromDeeplink = false AND m.deeplinkContent = invalid

  if videoPlayer <> invalid
    videoContent = videoPlayer.content
    historyPosition = round(videoPlayer.position)

    if historyPosition > m.constants.player.historyFrequency1Min
      updateHistoryLocally(videoContent, historyPosition)
      updateHistoryAndHandleResponse(videoContent, historyPosition)
    end if
  end if

  stopCountdownTimer() 'stop previous counter
  stopAndHideLinearVideoPlayer()
  if isVideoPreviewOn() = true
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
  for i = 0 to m.top.getChildCount() - 1
    screen = m.top.getChild(i)
    if screen <> invalid AND screen.isSubtype("BaseDialogScreen") = true
      closeModal(screen, "back")
    end if
  end for

  handleDeeplinkContentByType()

End Function


' this function calls appropriate functions to handle the deeplinks based on deeplink type
Function handleDeeplinkContentByType()
  tubilog("deeplinkHelpers.handleDeeplinkContentByType")
  if m.deepLinkContent <> invalid
    if m.deepLinkContent.deeplinkType = "cast"
      showDefaultHomeScreen()
      focusSideNavOption(m.constants.ui.sideNavIds.home)
      startCastingSession()
    else if m.deepLinkContent.deeplinkType = "linear" OR m.deepLinkContent.deeplinkType = "liveTV"
      'if fadeInContentController has not be set true, then linear content can not play.
      'in that case, we are setting a callback to call handleLinearDeeplinkContent after fadeInContentController is triggered
      callback = handleLiveEventDeeplinkContent
      if m.top.fadeInContentController = true
        callback()
      else
        m.linearScreenAfterFn = callback
      end if
    else if m.deepLinkContent.deeplinkType = "category"
      handleCategoryDeeplinkContent()
    else if m.deepLinkContent.deeplinkType = "channel"
      handleNetworkDeeplinkContent()
    else if m.deepLinkContent.deeplinkType = "moviePage"
      handleMoviesPageDeeplinkContent()
    else if m.deepLinkContent.deeplinkType = "kids"
      handleKidsPageDeeplinkContent()
    else if m.deepLinkContent.deeplinkType = "espanolPage"
      handleEspanolPageDeeplinkContent()
    else if m.deepLinkContent.deeplinkType = "homePage"
      handleHomePageDeeplinkContent()
    else if m.deepLinkContent.deeplinkType = "tvPage"
      handleTVPageDeeplinkContent()
    else if m.deepLinkContent.deeplinkType = "series"
      if Left(m.deepLinkContent.id, 1) = "0"
        playbackSource = getPlaybackSourceForDeeplinkType()
        showDetailScreen(m.deepLinkContent, false, skipDetailScreenDeeplinkWrapper, handleSingleContentDeeplinkError, playbackSource)
      else
        getSingleContentFromServer(m.deeplinkContent, onDeeplinkSeriesContentSuccess, handleSingleContentDeeplinkError)
      end if

    else if m.deepLinkContent.deeplinkType = "episode"
      getSingleContentFromServer(m.deeplinkContent, onDeeplinkEpisodeContentSuccess, handleSingleContentDeeplinkError)

    else if m.deepLinkContent.deeplinkType = "season"
      if Left(m.deepLinkContent.id, 1) = "0"
        playbackSource = getPlaybackSourceForDeeplinkType()
        showDetailScreen(m.deepLinkContent, false, skipDetailScreenDeeplinkWrapper, handleSingleContentDeeplinkError, playbackSource)
      else
        getSingleContentFromServer(m.deeplinkContent, onDeeplinkSeasonContentSuccess, handleSingleContentDeeplinkError)
      end if

    else if m.deepLinkContent.deeplinkType = "movie" OR m.deepLinkContent.deeplinkType = "tvspecial"
      playbackSource = getPlaybackSourceForDeeplinkType()
      showDetailScreen(m.deeplinkContent, false, skipDetailScreenDeeplinkWrapper, handleSingleContentDeeplinkError, playbackSource)

    else if m.deepLinkContent.deeplinkType = "sports"
      playbackSource = getPlaybackSourceForDeeplinkType()
      showDetailScreen(m.deeplinkContent, false, skipDetailScreenDeeplinkWrapper, handleSingleContentDeeplinkError, playbackSource)
      sideNavID = m.constants.ui.screenIdToSideNavId[m.constants.ui.screenIds.homeScreen]
      focusSideNavOption(sideNavID)
    else if m.deepLinkContent.deeplinkType = "shortFormVideo"
      ' shortFormVideo media refers to content that is under 15 minutes long. Examples include movie trailers, news snippets, comedy clips, food reviews, and similar videos.
      ' In our app, it primarily features movie trailers
      getSingleContentFromServer(m.deeplinkContent, onDeeplinkShortFormContentSuccess, handleSingleContentDeeplinkError)
    else if m.deepLinkContent.deeplinkType = "fox" then
      playLinearVideoWithFoxPlayer()
    else
      message = getTranslation("error_deeplink_page")
      showDeeplinkErrorModal(invalid, message)
    end if
  end if

End Function


Function fetchSingleLinearChannel()
  tubilog("deeplinkHelpers.deeplinkPlayLinearChannel")
  screenId = m.constants.ui.screenIds.epgScreen
  fetchEPGChannel(screenId, m.deeplinkContent.id, onSingleChannelFetchForDeeplinkSuccess, showDeeplinkErrorModal)

End Function


Function onSingleChannelFetchForDeeplinkSuccess(successResponse, storeInCache = false)
  tubilog("deeplinkHelpers.onSingleChannelFetchForDeeplinkSuccess")
  linearContent = invalid
  if successResponse.getChildCount() > 0
    linearContent = successResponse.getChild(0)
    linearContent.deeplinkType = "linear"
  end if

  if linearContent <> invalid
    if m.enteredFromDeepLink = true
      sendDeeplinkAnalytics(m.deepLinkContent, linearContent, m.constants.deeplinks.entryPoints.video, m.Tracking, m.trackingLoggingTask, m.constants)
    end if
    ' if the uimode is locked by parentalControl or kidsAgeGate, then show the error model that the
    ' content can be played because of parental controls
    if isKidsModeEnabledByParentalControls() = true OR m.uiMode = m.constants.ui.modes.kidsAgeGate
      message = getTranslation("dialog_contentNotAvailable_Parental_description")
      showDeeplinkErrorModal(invalid, message)
    else
      ' once the channel has been fetched and then set it in the cache to be used by EPG/homeScreen
      if storeInCache = true
        setInContentCache(linearContent, m.constants.ui.screenIds.epgScreen)
      end if

      'show epg Screen for linear content
      showDefaultEPGScreen()
      epgScreen = getFromScreenCache(m.constants.ui.screenIds.epgScreen)
      if epgScreen.timeGridContent = invalid OR epgScreen.timeGridContentLoading = true
        epgScreen.contentIdToFocusOnLoadComplete = linearContent.id
      end if

      if linearContent.needsLogin = false OR (linearContent.needsLogin = true AND isLoggedInUser() = true)
        playbackSource = getPlaybackSourceForDeeplinkType()
        playLinearVideoContent(linearContent, false, m.constants.ui.screenIds.epgScreen, false, playbackSource)
      else if linearContent.needsLogin = true AND isLoggedInUser() = false AND getStatsigExperimentResource("roku_linear_reg_gate", "roku_linear_reg_gate_v1_1").enabled = true
        showLinearPlayerSignInModal(linearContent)
      end if

      sEPGSideNavID = m.constants.ui.screenIdToSideNavId[m.constants.ui.screenIds.epgScreen]
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
Function showDeeplinkErrorModal(response = invalid, message = "")
  tubilog("deeplinkHelpers.showDeeplinkErrorModal")

  dialogType = "CONTENT_NOT_FOUND"
  if response <> invalid
    if response.code = 404
      dialogType = "CONTENT_NOT_FOUND" 'DialogType enum
    else if response.code = 403 OR response.code = 451 OR response.code = 401 OR response.code = 422
      dialogType = "RESTRICTED_CONTENT"
      message = getTranslation("dialog_contentNotAvailable_Parental_description")
    end if
  else if isKidsModeEnabledByParentalControls() = true OR m.uiMode = m.constants.ui.modes.kidsAgeGate
    dialogType = "RESTRICTED_CONTENT"
    if message = ""
      message = getTranslation("dialog_contentNotAvailable_Parental_description")
    end if
  end if

  if message = ""
    message = getTranslation("error_deeplink_content")
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
        pageOneof: m.Tracking.getAnalyticsPage("home_page", { content_mode: "CONTENT_MODE_UNKNOWN" })
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
  if deepLinkContent <> invalid 'if deeplinkContent is invalid then, there is no point in sending referredAnalyticsEvent
    referredAnalyticsEvent = {
      referred_type: "DEEP_LINK"
      campaign: deepLinkContent.campaign
      source: deepLinkContent.source
      medium: deepLinkContent.medium
      source_device_id: deepLinkContent.sourceDeviceId
    }

    if (deepLinkContent.type = m.constants.ui.contentTypes.linear OR deepLinkContent.type = m.constants.ui.contentTypes.video OR (deepLinkContent.type = "series" AND deepLinkContent.deeplinkType = "series")) AND deepLinkContent.id <> invalid AND deepLinkContent.id <> ""
      pageInfo = {
        pageType: "video_player_page"
        pageValues: {
          video_id: deepLinkContent.Id.toInt()
        }
      }
    else if refreshedContent <> invalid
      pageInfo = getDetailScreenAnalyticsPageInfo(refreshedContent, constants)
    else 'default
      pageInfo = {
        pageType: "home_page"
        pageValues: { content_mode: "CONTENT_MODE_UNKNOWN" }
      }
    end if

    if entryPoint = m.constants.deeplinks.entryPoints.detail
      referredAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
    else if entryPoint = m.constants.deeplinks.entryPoints.home
      referredAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage("home_page", { content_mode: "CONTENT_MODE_UNKNOWN" })
    else if entryPoint = m.constants.deeplinks.entryPoints.epg
      referredAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage("linear_browse_page", {})
    else if entryPoint = m.constants.deeplinks.entryPoints.category
      referredAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage("category_list_page", {})
    else if entryPoint = m.constants.deeplinks.entryPoints.channel
      referredAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage("channel_list_page", {})
    else if entryPoint = m.constants.deeplinks.entryPoints.espanol
      referredAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage("home_page", { content_mode: "CONTENT_MODE_LATINO" })
    else if entryPoint = m.constants.deeplinks.entryPoints.movies
      referredAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage("home_page", { content_mode: "CONTENT_MODE_MOVIE" })
    else if entryPoint = m.constants.deeplinks.entryPoints.tv
      referredAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage("home_page", { content_mode: "CONTENT_MODE_TV" })
    else if entryPoint = m.constants.deeplinks.entryPoints.categoryDetail
      referredAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage("category_page", { "category_slug": deepLinkContent.id })
    else if entryPoint = m.constants.deeplinks.entryPoints.news
      referredAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage("home_page", { content_mode: "CONTENT_MODE_LINEAR" })
    else if entryPoint = m.constants.deeplinks.entryPoints.episodeList
      if deepLinkContent <> invalid
        seriesId = deepLinkContent.id.toInt()
        referredAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage("episode_video_list_page", { series_id: seriesId })
      end if
    else if entryPoint = m.constants.deeplinks.entryPoints.linearDetail
      referredAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage("linear_details_page", { video_id: deepLinkContent.id.toInt() })
    else if entryPoint = m.constants.deeplinks.entryPoints.video AND pageInfo <> invalid
      referredAnalyticsEvent.pageOneof = trackingLib.getAnalyticsPage(pageInfo.pageType, pageInfo.pageValues)
    end if

    trackingTask.trackEvent = {
      type: "referred"
      values: referredAnalyticsEvent
    }
  end if
End Function


Function handleLinearDeeplinkContent()
  tubilog("DeeplinkHelpers.handleLinearDeeplinkContent")

  if isParentalControlsAdultLevel() = false OR m.uiMode = m.constants.ui.modes.kidsAgeGate
    ' Display error message indicating to turn off the parental controls
    message = getTranslation("dialog_contentNotAvailable_Parental_description")
    showDeeplinkErrorModal(invalid, message)
  else
    ' linear deeplink request has been received with content ID to play, so fetch and start playing the content
    if m.deeplinkContent.id <> ""
      fetchSingleLinearChannel()
      sCatSideNavID = m.constants.ui.sideNavIds.home
    else
      ' without contentId(deeplinkContentId), just display the default epg Screen
      if m.enteredFromDeepLink = true
        sendDeeplinkAnalytics(m.deepLinkContent, m.deepLinkContent, m.constants.deeplinks.entryPoints.epg, m.Tracking, m.trackingLoggingTask, m.constants)
      end if
      showDefaultEPGScreen()
      'EPG screen is part of homescreen in sideNav.
      sCatSideNavID = m.constants.ui.sideNavIds.linearEPG

    end if
    focusSideNavOption(sCatSideNavID)
  end if

End Function


Function handleHomePageDeeplinkContent()
  tubilog("DeeplinkHelpers.handleHomePageDeeplinkContent")
  if m.enteredFromDeepLink = true
    sendDeeplinkAnalytics(m.deepLinkContent, m.deepLinkContent, m.constants.deeplinks.entryPoints.home, m.Tracking, m.trackingLoggingTask, m.constants)
  end if

  if (isParentalControlsAdultLevel() <> true AND isParentalControlsTeensLevel() <> true) OR m.uiMode = m.constants.ui.modes.kidsAgeGate
    setUiMode(m.constants.ui.modes.kids)
  else
    setUiMode(m.constants.ui.modes.standard)
  end if

  showDefaultHomeScreen()
  focusSideNavOption(m.constants.ui.sideNavIds.home)
  resetDeeplinkValues()

End Function


Function handleCategoryDeeplinkContent()
  tubilog("DeeplinkHelpers.handleCategoryDeeplinkContent")


  if m.deeplinkContent.id <> ""
    if m.enteredFromDeepLink = true
      sendDeeplinkAnalytics(m.deepLinkContent, m.deepLinkContent, m.constants.deeplinks.entryPoints.categoryDetail, m.Tracking, m.trackingLoggingTask, m.constants)
    end if
    isUserSigedIn = isLoggedInUser()
    categoryId = m.deeplinkContent.id
    categoryIds = m.constants.ui.categoryIds
    if isUserSigedIn = true OR (categoryId <> categoryIds.history AND categoryId <> categoryIds.queue AND categoryId <> categoryIds.myLikes)
      navigateToCategoryDetailsScreen(categoryId)
      focusSideNavOption(m.constants.ui.sideNavIds.categories)
    else
      showHomeScreen(m.constants)
      focusSideNavOption(m.constants.ui.sideNavIds.home)
    end if
  else
    if m.enteredFromDeepLink = true
      sendDeeplinkAnalytics(m.deepLinkContent, m.deepLinkContent, m.constants.deeplinks.entryPoints.category, m.Tracking, m.trackingLoggingTask, m.constants)
    end if
    showCategoryPanelListScreen(m.constants, true)
  end if
  sCatSideNavID = m.constants.ui.sideNavIds.categories

  if (isParentalControlsAdultLevel() = true OR isParentalControlsTeensLevel() = true) AND m.uiMode <> m.constants.ui.modes.kidsAgeGate
    setUiMode(m.constants.ui.modes.standard)
  end if

  focusSideNavOption(sCatSideNavID)
  resetDeeplinkValues()

End Function


Function handleNetworkDeeplinkContent()
  tubilog("DeeplinkHelpers.handleNetworkDeeplinkContent")

  if isParentalControlsAdultLevel() = false OR m.uiMode = m.constants.ui.modes.kidsAgeGate
    ' Display error message indicating to turn off the parental controls
    message = getTranslation("dialog_sideNavItemDisabled_Parental_description")
    showDeeplinkErrorModal(invalid, message)
  else
    if isNonEmptyString(m.deeplinkContent.id) = true
      if m.enteredFromDeepLink = true
        sendDeeplinkAnalytics(m.deepLinkContent, m.deepLinkContent, m.constants.deeplinks.entryPoints.categoryDetail, m.Tracking, m.trackingLoggingTask, m.constants)
      end if
      navigateToNetworkDetailsScreen(m.deeplinkContent.id)
    else
      if m.enteredFromDeepLink = true
        sendDeeplinkAnalytics(m.deepLinkContent, m.deepLinkContent, m.constants.deeplinks.entryPoints.channel, m.Tracking, m.trackingLoggingTask, m.constants)
      end if

      showCategoryPanelListScreen(m.constants, true, m.constants.ui.categoryIds.networks)
    end if
    setUiMode(m.constants.ui.modes.standard)
  end if

  '//::NOTE:: there is no longer a channels side nav option, so target the categories side nav item.
  focusSideNavOption(m.constants.ui.sideNavIds.categories)
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
  if isParentalControlsAdultLevel() = false OR m.uiMode = m.constants.ui.modes.kidsAgeGate
    ' Display error message indicating to turn off the parental controls
    message = getTranslation("dialog_sideNavItemDisabled_Parental_description")
    showDeeplinkErrorModal(invalid, message)
  else
    setUiMode(m.constants.ui.modes.latino)
    showEspanolScreen()
    focusSideNavOption(m.constants.ui.sideNavIds.espanol)
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
    focusSideNavOption(m.constants.ui.sideNavIds.movies)
  else if isParentalControlsAdultLevel() = false OR m.uiMode = m.constants.ui.modes.kidsAgeGate
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
    focusSideNavOption(m.constants.ui.sideNavIds.movies)
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
    focusSideNavOption(m.constants.ui.sideNavIds.tv)
  else if isParentalControlsAdultLevel() = false OR m.uiMode = m.constants.ui.modes.kidsAgeGate
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
    focusSideNavOption(m.constants.ui.sideNavIds.tv)
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
' @sendTracking: boolean , this parameter is used to control whether NavigateToPage events needs to send or not. In case of deeplinks, no need to send NavigateToPage Event
Function handleDeeplinkSeriesSuccessResponse(refreshedContent)
  if refreshedContent <> invalid
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
    if m.enteredFromDeeplink = true AND m.deepLinkContent <> invalid AND m.deepLinkContent.nowPos >= 0
      refreshedContent.currentEpisodeId = m.deepLinkContent.id
      episode = getEpisodeContent(refreshedContent)
      if episode <> invalid
        episode.nowPos = m.deepLinkContent.nowPos
      end if
      afterFn = detailScreenResumeHelper
    else if history <> invalid
      refreshedContent.currentEpisodeId = history.currentEpisodeId
      episode = getEpisodeContent(refreshedContent)
      episodeHistory = invalid
      if episode <> invalid
        episodeHistory = getHistory(episode.id)
      end if

      if episodeHistory <> invalid AND episodeHistory.nowPos > 0
        episode.nowPos = episodeHistory.nowPos
        afterFn = detailScreenResumeHelper
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
      populateDetailScreen(detailScreen, refreshedContent, false, -1)

      if refreshedContent.needsLogin = false
        ' only if content is not locked, then move past detail screen
        handleDetailScreenAfterFn(detailScreen, afterFn)
      end if
    end if
  else
    showDeeplinkErrorModal()
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
  playbackSource = getPlaybackSourceForDeeplinkType()
  showDetailScreen(emptySeriesNode, false, successCb, errorCb, playbackSource)
End Function


' success handler upon fetching the trailer in case of shortFormVideo deeplinks.
' @refreshedContent: roSGNode, success video response content
' @successcb: success callback which will handle the success response after fetching the content metadata for the movie associated with the trailer that was deeplinked to.
' @errorcb: errorCallback which will handle error while fetching video for provided contentId
Function handleDeeplinkShortFormSuccessResponse(refreshedContent, successCb = invalid, errorCb = invalid) as Void
  emptyMovieNode = CreateObject("roSGNode", "TubiContentNode")
  emptyMovieNode.type = m.constants.ui.contentTypes.movie

  if refreshedContent <> invalid
    emptyMovieNode.id = refreshedContent.parentId
  end if

  playbackSource = getPlaybackSourceForDeeplinkType()
  showDetailScreen(emptyMovieNode, false, successCb, errorCb, playbackSource)
End Function


Function handleDeeplinkSeasonSuccessResponse(refreshedContent)

  if refreshedContent <> invalid
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
      populateDetailScreen(detailScreen, refreshedContent, false, -1)
      handleDetailScreenAfterFn(detailScreen, afterFn)
    end if
  else
    showDeeplinkErrorModal()
  end if
End Function


' @refreshedContent, roSGNode, success response of a trailer's parent content, most likely a movie.
Function handleDeeplinkTrailerSuccessResponse(refreshedContent)
  if refreshedContent <> invalid
    afterFn = trailerHelper
    detailScreen = getTopDetailScreenFromStack()

    if detailScreen <> invalid
      detailScreen.contentFetchError = false
      populateDetailScreen(detailScreen, refreshedContent, false, -1)

      if refreshedContent.needsLogin = false
        ' only if content is not locked, then move past detail screen
        handleDetailScreenAfterFn(detailScreen, afterFn)
      end if
    end if
  else
    showDeeplinkErrorModal()
  end if
End Function


Function handleDeeplinkEpisodeSuccessResponse(refreshedContent)

  if refreshedContent <> invalid
    history = getHistory(refreshedContent.id)
    '  refreshedContent.id =       series id
    '  refreshedContent.seriesId = invalid
    '  refreshedContent.type =     series
    '  m.deepLinkContent.deepLinkType = episode

    ' we now have the full series info for episode deeplinks
    refreshedContent.currentEpisodeId = m.deepLinkContent.id
    'determine if we need to resume or play from start the deeplinked episode
    if m.enteredFromDeeplink = true AND m.deepLinkContent <> invalid AND m.deepLinkContent.nowPos >= 0
      episode = getEpisodeContent(refreshedContent)
      if episode <> invalid
        episode.nowPos = m.deepLinkContent.nowPos
      end if

      afterFn = detailScreenResumeHelper
    else if history <> invalid
      episode = getEpisodeContent(refreshedContent)
      if episode <> invalid
        episodeHistory = getHistory(episode.id)
      end if

      if episodeHistory <> invalid AND episodeHistory.nowPos > 0
        episode.nowPos = episodeHistory.nowPos
      end if
      afterFn = detailScreenResumeHelper
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
      populateDetailScreen(detailScreen, refreshedContent, false, -1)

      if refreshedContent.needsLogin = false
        ' only if content is not locked, then move past detail screen
        handleDetailScreenAfterFn(detailScreen, afterFn)
      end if
    end if
  else
    showDeeplinkErrorModal()
  end if
End Function


'this function will be called to get series details and then to fetch video to be played by deeplinkContent.id
Function onDeeplinkSeriesContentSuccess(singleContent)
  tubilog("deeplinkHelpers.onDeeplinkSeriesContentSuccess")
  if singleContent.type = m.constants.ui.contentTypes.video
    handleDeeplinkVideoSuccessResponse(singleContent, handleDeeplinkSeriesSuccessResponse, handleSingleContentDeeplinkError)
  else
    showDeeplinkErrorModal()
  end if
End Function


'this function will be called to get series details and then to fetch video to be played by deeplinkContent.id
Function onDeeplinkEpisodeContentSuccess(singleContent)
  tubilog("deeplinkHelpers.onDeeplinkEpisodeContentSuccess")

  if singleContent.type = m.constants.ui.contentTypes.video
    handleDeeplinkVideoSuccessResponse(singleContent, handleDeeplinkEpisodeSuccessResponse, handleSingleContentDeeplinkError)
  else
    showDeeplinkErrorModal()
  end if

End Function


Function onDeeplinkSeasonContentSuccess(singleContent)
  tubilog("deeplinkHelpers.onDeeplinkSeasonContentSuccess")
  if singleContent.type = m.constants.ui.contentTypes.video
    handleDeeplinkVideoSuccessResponse(singleContent, handleDeeplinkSeasonSuccessResponse, handleSingleContentDeeplinkError)
  else
    showDeeplinkErrorModal()
  end if
End Function


' @singleContent: roSGNode, contains metadata for a trailer or other short form content.
Function onDeeplinkShortFormContentSuccess(singleContent)
  tubilog("deeplinkHelpers.onDeeplinkShortFormContentSuccess")
  if singleContent.type = m.constants.ui.contentTypes.video
    handleDeeplinkShortFormSuccessResponse(singleContent, handleDeeplinkTrailerSuccessResponse, handleSingleContentDeeplinkError)
  else
    showDeeplinkErrorModal()
  end if
End Function


Function handleSingleContentDeeplinkError(error)
  tubilog("DeeplinkHelpers.handleSingleContentDeeplinkError")
  message = getTranslation("screenDetails_error_getContent_description")
  if m.enteredFromDeepLink = false AND m.deepLinkContent <> invalid
    'only in case of the movie, we have already sneaked the showdetail screen, so we need to
    'bring the user to previous screen.
    if m.deepLinkContent.deeplinkType = "movie" OR m.deepLinkContent.deeplinkType = "sports" OR m.deepLinkContent.deeplinkType = "tvspecial"
      detailScreen = getTopDetailScreenFromStack()
      if detailScreen <> invalid AND detailScreen.content.id = m.deepLinkContent.id
        'Simply popping the screen is resulting in issues, so calling onDetailBackButtonPressedChange function.
        onDetailBackButtonPressedChange()
      end if
    end if
    currentScreen = getCurrentScreen()
    'If user issues input deeplink on linearvideoplayer/videoplayer, video will stop and tries to play deeplink content.
    'In case of deeplink error, bring the user back to detail screen.
    if currentScreen.id = m.constants.ui.screenIds.linearVideoPlayerScreen
      returnToPreviousScreenFromLinearVideo(false)
    else if currentScreen.id = m.constants.ui.screenIds.videoPlayerScreen
      returnToDetailScreenFromVideo(true, true, "deeplink")
    end if

    showDeeplinkErrorModal(error, message)
  else
    ' when user is in trying to deeplink to movie or series and we encounter an error, we need to send analytics and reset the deeplink values
    ' and land the user on the previous screen (most likely the home screen) rather than showing the error modal.
    sendDeeplinkAnalytics(m.deepLinkContent, m.deepLinkContent, m.constants.deeplinks.entryPoints.home, m.Tracking, m.trackingLoggingTask, m.constants)
    resetDeeplinkValues()
    currentScreen = getCurrentScreen()
    if currentScreen <> invalid AND currentScreen.isSubtype("HomeScreen") = false
      popScreen()
    end if
  end if
End Function

' parses a uri encoded list of key:value pair
' example: channel%3A1234%2Cprogram%3A5678 -> channel:1234,program:5678
' returns AA of key:value pairs
' expected to have channel and program
Function parseSportsEventContentId(contentId) as Object
  sportsEvent = {
    channel: invalid
    program: invalid
  }
  decoded = contentId.decodeUriComponent()
  entries = decoded.split(",")
  for each entry in entries
    keyValue = entry.split(":")
    if sportsEvent.doesExist(keyValue[0]) = true
      sportsEvent[keyValue[0]] = keyValue[1]
    end if
  end for
  return sportsEvent
End Function


Function skipDetailScreenDeeplinkWrapper(refreshedContent)
  ' This is a hack to handle cases where wrong media type is passed in the deeplink for fox player.
  if refreshedContent <> invalid AND refreshedContent.playerType = m.constants.ui.playerTypes.fox
    popScreen()
    onDeeplinkLiveEventContentSuccess(refreshedContent)
  else if refreshedContent.type = m.constants.ui.contentTypes.linear
    handleSingleContentDeeplinkError(invalid) 'if the content type is linear, then do not show detailScreen instead show error dialog.
  else
    skipDetailScreen(refreshedContent)
  end if
End Function


' Callback triggered once the request to fetch sports event information succeeds.
Function onDeeplinkSportsContentSuccess(content)
  if content <> invalid
    showSportsDetailsScreen()
  else
    showDeeplinkErrorModal()
  end if

End Function


Function showSportsDetailsScreen()
  playbackSource = getPlaybackSourceForDeeplinkType()
  showDetailScreen(m.deeplinkContent, false, skipDetailScreenDeeplinkWrapper, handleSingleContentDeeplinkError, playbackSource)
  sideNavID = m.constants.ui.screenIdToSideNavId[m.constants.ui.screenIds.homeScreen]
  focusSideNavOption(sideNavID)
End Function


Function getPlaybackSourceForDeeplinkType()
  if m.enteredFromDeepLink = true
    return {
      "srcForAnalytic": m.constants.player.playbackSource.unknown
      "srcForAds": m.constants.player.playbackOrigin.deeplink
    }
  else
    return {
      "srcForAnalytic": m.constants.player.playbackSource.unknown
      "srcForAds": m.constants.player.playbackOrigin.search
    }
  end if

End Function


Function handleLiveEventDeeplinkContent()
  getSingleContentFromServer(m.deepLinkContent, onDeeplinkLiveEventContentSuccess, handleSingleContentDeeplinkError)
End Function


Function onDeeplinkLiveEventContentSuccess(content)
  if content <> invalid AND isAA(content.scheduleData)
    playbackSource = getPlaybackSourceForDeeplinkType()
    scheduleData = content.scheduleData
    entryPoint = m.constants.deeplinks.entryPoints.linearDetail
    shouldFireAnalytics = true
    if isAA(scheduleData) AND isNonEmptyString(scheduleData.startTime) = true AND (isLoggedInUser() = true OR content.needsLogin = false)
      startTime = content.scheduleData.startTime
      endTime = content.scheduleData.endTime
      isEventLive = isLessThanOrEqualToCurrentTime(startTime) AND isGreaterThanCurrentTime(endTime)
      if isEventLive = true
        entryPoint = m.constants.deeplinks.entryPoints.video
        playerType = content.playerType
        if isAA(content.scheduleData)
          playerType = content.scheduleData.playerType
        end if
        if playerType = m.constants.ui.playerTypes.fox
          playLinearVideoWithFoxPlayer(content)
        else
          shouldFireAnalytics = false
          screenId = m.constants.ui.screenIds.epgScreen
          fetchEPGChannel(screenId, scheduleData.channelId, onSingleChannelFetchForDeeplinkSuccess, showDeeplinkErrorModal)
        end if
      else
        showLinearDetailScreen(content, playbackSource)
      end if
    else
      showLinearDetailScreen(content, playbackSource)
    end if
    if m.deeplinkContent <> invalid AND shouldFireAnalytics = true
      sendDeeplinkAnalytics(m.deeplinkContent, content, entryPoint, m.tracking, m.trackingLoggingTask, m.constants)
    end if
  else
    handleLinearDeeplinkContent()
  end if
End Function
