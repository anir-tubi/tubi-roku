function AdriseApp (params)
  appManager = CreateObject("roAppManager")
  appManager.SetTheme(getTheme())

  s = getSettings()

  utils = AdriseUtils(s.shortAppName)

  utils.appManager = appManager
  utils.setProxy(s.proxyUrl, s.proxyFolder)
  utils.log = AdriseLogging(utils)

  version = utils.deviceInfo.firmwareVersion
  major = Int(version)
  if major = 3
    s.contentType = "mp4"
  end if

  player = AdrisePlayerInternal({
    appID: s.shortAppName
    pubId: s.pubId
    background : s.adrise_bg
    fontColor: s.adrise_fontcolor
    loadingUrl: s.adrise_loadingurl
    subscription: s.subscription
    contentType: s.contentType
    utils: utils
    pingFrequency: 10
  })

  linearTv = AdriseLinearTv(utils, player)

  cp = ContentProvider(s.pubId, s.shortAppName, s.imageSize, s.contentType, "", utils, linearTv.showLinearTv)

  searchResultsScreen = AdriseSearchResultsListScreen(player, cp, s, utils)
  searchScreen = AdriseSearchScreen(utils, cp, searchResultsScreen)
  policyScreen = AdrisePolicyScreen(utils, s)
 
  app = {
    'linkToVezo: LinkToVezo(utils, player, s)
    utils: utils
    settings: s
    cp: cp
    player: player
    linearTv: linearTv
    gridScreen: GridScreen(utils)
    detailScreen: DetailScreen(cp, s, utils, player)
    createServerLinker: createServerLinker
    registerScreen: RegisterScreen(utils.getUniqueId(), utils)
    episodeListScreen: EpisodeListScreen(cp, s, utils)
		' registerLinker: createRegisterLinker(utils, player, s)
		runCount: utils.getRunCount()
    searchScreen: searchScreen
    searchResultsScreen: searchResultsScreen
    policyScreen: policyScreen

    handleItemPicked: AdriseApp_handleItemPicked
    showMessage: AdriseApp_showMessage
    runApp: AdriseApp_runApp

    params: params
  }

  if s.zoneId <> ""
    app.player.zoneId = s.zoneId
  end if

  return app
end function


'Main function that emcompasses the whole app running.
'start this function via app.runApp to initialize the app
function AdriseApp_runApp()

  if m.utils.getSettings().shortAppName = "tubitv"
    ' turn on search for tubitv only
    m.utils.getSettings().showSearch = true
    GetGlobalAA().app.settings.showSearch = true
    if m.utils.deviceInfo.firmwareVersion <= 3.01
      GetGlobalAA().app.settings.showSearch = false
    end if

    'platform name
    GetGlobalAA().app.settings.platformName = "roku"

    'tools row name
    GetGlobalAA().app.settings.toolsRowName = "Tools"

    'ads cuepoint url base
    GetGlobalAA().app.settings.cuepointsUrlBase = "http://ads.adrise.tv/cue-points/"

    'privacy policy text url
    GetGlobalAA().app.settings.policyUrl = "http://cdn.adrise.tv/legal/TubiTVPrivacyPolicy.txt"

    'v4 API url base
    GetGlobalAA().app.settings.cmsApiUrlBase = "https://uapi.adrise.tv/cms/contents?platform=" + GetGlobalAA().app.settings.platformName

    'registration url
    GetGlobalAA().app.settings.regUrlBase = "https://uapi.adrise.tv/user_device/code"

    'user events url
    GetGlobalAA().app.settings.userEventUrlBase = "https://uapi.adrise.tv/datascience"
    GetGlobalAA().app.settings.userEventUrl = GetGlobalAA().app.settings.userEventUrlBase + "/event"

    'logging url
    GetGlobalAA().app.settings.loggingUrl = GetGlobalAA().app.settings.userEventUrlBase + "/logging"

    'bookmarks/recently viewed url base
    GetGlobalAA().app.settings.bookmarksUrlBase = "https://uapi.adrise.tv/user_device"

    'turn on bookmarks for tubitv only'
    GetGlobalAA().app.settings.showBookmarks = true
    GetGlobalAA().app.settings.bookmarksUrl = GetGlobalAA().app.settings.bookmarksUrlBase + "/queues"
    GetGlobalAA().app.settings.bookmarksUrlNoPage = GetGlobalAA().app.settings.bookmarksUrl + "?page_enabled=false"

    ' turn on previously viewed for tubitv only
    GetGlobalAA().app.settings.showPreviouslyViewed = true
    GetGlobalAA().app.settings.previouslyViewedUrl = GetGlobalAA().app.settings.bookmarksUrlBase + "/histories"
    GetGlobalAA().app.settings.previouslyViewedUrlNoPage = GetGlobalAA().app.settings.previouslyViewedUrl + "?page_enabled=false"

    'refresh token url
    GetGlobalAA().app.settings.getAccessTokenUrl = GetGlobalAA().app.settings.bookmarksUrlBase + "/login/refresh"

    'logout url
    GetGlobalAA().app.settings.logoutUrl = GetGlobalAA().app.settings.bookmarksUrlBase + "/logout"

    'migrate login url
    GetGlobalAA().app.settings.migrateLoginUrl = GetGlobalAA().app.settings.bookmarksUrlBase + "/login/migrate"

    'set the name of the bookmarks and previously viewed registry sections'
    GetGlobalAA().app.settings.bookmarkRegistry = "bookmarks"
    GetGlobalAA().app.settings.previouslyViewedRegistry = "previous"

    'set the Bookarks and Previously Viewed category names
    GetGlobalAA().app.settings.bookmarksCatName = "My Queue"
    GetGlobalAA().app.settings.previouslyViewedCatName = "Continue Watching"

    'turn off rental option for tubitv only
    GetGlobalAA().app.settings.allowRentals = false

  end if


  'handle/set up any deep linking that may have occurred
  if (m.params.contentID <> invalid)
    m.cp.autoplayId = m.params.contentID

    if m.utils.getSettings().shortAppName = "tubitv" 
      'default deep link source is search
      deepLinkSource = "search"

      'if there is a parameter called entry with a value, that is the source of the deep link
      'typically entry = banner from the Roku banner ads ('entry' is a custom parameter)
      'deep link urls with entry source should look like:
      'contentID=18267&entry=banner
      if m.params.entry <> invalid
        deepLinkSource = m.params.entry
      end if

      'start building the appropriate URI for deeplink user event
      destination = "/video/" + m.params.contentID

      'if deep linked from Roku search it's possible that we are deep linking to a series/season, instead of actual video content
      'deep links from search for season should like:
      'contentID=340262&MediaType=season
      if m.params.MediaType = "season"
        m.cp.autoplayIsSeason = true
        destination = "/series/episodelist/"

      'this is supposedly deprecated but I don't trust that it doesn't still exist
      'contentID=335&MediaType=series'
      else if m.params.MediaType = "series"
        m.cp.autoplayIsSeries = true
        destination = "/series/episodelist/" + m.params.contentID
      end if

      'see tubitv.atlassian.net/wiki/display/EC/Referrals
      deeplinkMedium = "partnership"
      if m.params.medium <> invalid
        deeplinkMedium = m.params.medium
      end if

      'see tubitv.atlassian.net/wiki/display/EC/Referrals
      deeplinkCampaign = "default-campaign"
      if m.params.campaign <> invalid
        deeplinkCampaign = m.params.campaign
      end if

      'remove any 0s that might be prepended to the content id
      if deepLinkSource = "search"
        prepend = "0"
        while prepend = "0"
          prepend = m.cp.autoplayId.left(1)
          
          if prepend = "0"
            length = m.cp.autoplayId.len()
            m.cp.autoplayId = m.cp.autoplayId.right(length - 1)
          end if
        end while
      end if

      detination = destination + m.cp.autoplayId
      
      m.utils.trackEvent({
        trackType: "deepLink"
        ctx: destination
        extraCtx: {
          source: deepLinkSource
          campaign: deeplinkCampaign
          medium: deeplinkMedium
        }
        port: m.detailScreen.detailsPort
      })

    end if
  else
    m.cp.autoplayId = ""
  end if





  if m.utils.getSettings().allowVezoSubscription
    m.serverLink = m.createServerLinker(m.utils, m.player, m.utils.getSettings())
    m.serverLink.connectToAccount(true)
  else
    serverLink = invalid
  end if


  ' this object persists for the life of the program, and always
  '  points to the item in the grid that is currently focused or will
  '  be focused next time the grid displays.
  m.selectedItem = {
    listIndex: 1
    itemIndex: 2
  }

  if m.utils.getSettings().GridStyle = "Flat-Movie"
    m.selectedItem.listIndex = 0
  else if m.utils.getSettings().GridStyle = "two-row-flat-landscape-custom"
    m.selectedItem.listIndex = 0
    m.selectedItem.itemIndex = 0
  end if

  m.utils.trackEvent({
    trackType: "startApp"
  })

  'if settings call for registration and not a deep link entry, show reg screen if not logged in
  if m.utils.getSettings().registerWithTubi and m.params.contentID = invalid

    authInfo = m.utils.getAuthInfo() 'from device memory

    'one time login sync - checks if old registration data exists and if so, gets new auth info and deletes old registration data
    if authInfo.accessToken = invalid
      authInfo = m.utils.oneTimeLoginMigration()
    end if
    
    if authInfo.accessToken = invalid
      if not m.registerScreen.show()
        return false
      end if
    end if
  
    'one time sync to send stored bookmarks and previously viewed to server
    'this should only happen if the user has an auth token - also, oneTimeBookmarkSync() will do the check if it has already been run
    authInfo = m.utils.getAuthInfo()
    if authInfo.accessToken <> invalid
      m.utils.oneTimeBookmarkSync()
      m.utils.oneTimePreviouslyViewedSync()
    end if
    
  end if

  ' GridScreen.show() returns true if it wants us to show the detail screen, using
  '  the values that are now in 'selectedItem' (as well as using the stuff in
  '  'content' that it populated).
  ' Note: we would prefer not have to recreate the gridscreen each time, but
  ' old devices have an issue with ads playing when the grid screen still exists
  while m.gridScreen.show(m.selectedItem, m.cp, m.utils.getSettings().GridStyle, m.linearTv.showLinearTv) = true
    if m.cp.autoplayData <> invalid
      ' path = m.cp.getEpisodeByPath(m.cp.autoplayData.path)
      m.selectedItem.listIndex = m.cp.autoplayData.path[0]
      m.selectedItem.itemIndex = m.cp.autoplayData.path[1]
    end if

    'does appropriate action based on what 'episode' was selected (includes options on register/search row)
    playlist = m.cp.getPlaylist(m.selectedItem.listIndex)
    m.selectedItem.itemIndex = m.handleItemPicked(playlist, m.selectedItem.listIndex, m.selectedItem.itemIndex, "gridscreen")

    m.cp.autoplayData = invalid
  end while

  if m.cp.errorMessage <> invalid
    m.utils.showErrorMessage (m.utils.getSettings().adrise_bg, m.utils.getSettings().adrise_fontcolor, m.utils.getSettings().adrise_loadingurl, m.cp.errorMessage)
  end if

end function


Function AdriseApp_handleItemPicked(playlist, listIndex, itemIndex, source)
  settings = m.utils.getSettings()
  episode = m.cp.getEpisodeInPlaylist(playlist, itemIndex)

  if episode.type = "tubiLogin"
    authInfo = m.utils.getAuthInfo()
    if (authInfo.accessToken = invalid)
      'user wants to log in
      
      m.utils.trackEvent({
        trackType: "navigate"
        value: "/deviceregistration"
        ctx: "/home/cat/" + m.utils.sluggify(playlist.name)
        port: m.registerScreen.registerPort
      })

      m.registerScreen.show()

      'if the user has successfully logged in, lets see if we need to do a one time sync
      authInfo = m.utils.getAuthInfo()
      if authInfo.accessToken <> invalid
        m.utils.oneTimeBookmarkSync()
        m.utils.oneTimePreviouslyViewedSync()
        'since we are removing the bookmarks button, we need to reset the itemIndex
        itemIndex = 0
      end if

    'bookmarks button is only shown if the user is logged out already
    'so this else block should never run if bookmarks is selected
    else
      'user wants to log out - send logout to server - listen for response - if ok, delete auth info locally
      logoutPort = CreateObject("roMessagePort")
      logoutUrl = m.settings.logoutUrl
      logoutBody = {
        user_id: authInfo.userId
        device_id: m.utils.deviceInfo.deviceId
        platform: "roku"
      }
      logoutBodyJson = FormatJson(logoutBody)
      logoutHeaders = m.utils.getAuthHeaders(authInfo.refreshToken)
      logoutReqId = m.utils.sendAsyncRequest(logoutUrl, logoutPort, "logout", "POST", true, logoutBodyJson, logoutHeaders)

      while true
        msg = wait(0, logoutPort)
        if type(msg) = "roUrlEvent"
          logoutRes = m.utils.getAsyncResponse(msg, 0)
          print logoutRes
          if logoutRes <> invalid and logoutRes.data <> invalid and logoutRes.data.len() = 0
            'remove local storage of auth tokens
            m.utils.deleteAuthInfo()
            
            'remove local bookmarks and previously viewed info - so that we won't build those categories after logout
            m.cp.bookmarkIds = []
            m.cp.previouslyViewedIds = []

            m.cp.userPlaylists[settings.bookmarkRegistry].episodes = []
            m.cp.userPlaylists[settings.previouslyViewedRegistry].episodes = []

            m.cp.userPlaylistVideos = {}
            m.cp.userPlaylistSeries = {}

            'set state so we know if we need to add the user playlists rows if the user logs back in
            m.gridScreen.isShownAfterLogin = false

            exit while
          end if
        end if
      end while
    end if
  else if episode.type = "vezo"
    m.serverLink.connectToAccount(true)
    if(m.player.subscription)
      m.utils.showErrorMessage (m.utils.getSettings().adrise_bg, m.utils.getSettings().adrise_fontcolor, m.utils.getSettings().adrise_loadingurl, "You are subscribed to " + m.utils.getSettings().appName)
    end if
  else if episode.type = "search" 'load a search screen
    
    m.utils.trackEvent({
      trackType: "navigate"
      value: "/search"
      ctx: "/home/cat/" + m.utils.sluggify(playlist.name)
      port: m.searchScreen.searchPort
    })  
    
    m.searchScreen.show()
  else if episode.type = "linear" 'play linear tv
    'get episode content for linear episodes
    linearPlaylist = m.linearTv.getLinearPlaylist()
    m.cp.getAllEpisodesForPlaylistFromServer(linearPlaylist, "gridscreen")

    'remove any content that might be out of window
    validEpisodes = []
    for each episode in linearPlaylist.episodes
      if episode.id <> invalid and episode.streams <> invalid and episode.streams[0] <> invalid
        validEpisodes.push(episode)
      end if
    end for
    linearPlaylist.episodes = validEpisodes

    'determine correct episode and correct start time
    initialEpisodeInfo = m.linearTv.getCurrentEpisode(linearPlaylist)

    'make sure we have episodes to play
    if initialEpisodeInfo.initialEpisodeIndex <> invalid
      episodeCounter = initialEpisodeInfo.initialEpisodeIndex
      startTime = initialEpisodeInfo.startTime
      linearPlaylist.episodes[episodeCounter].playStart = startTime  'sets start time of first episode to play

      'set linearTvOn status to true
      m.linearTv.linearTvOn = true

      'play video
      maxIndex = m.cp.getPlaylistLength(linearPlaylist) - 1

      'tell the player to treat this first video (only) as one that is being resumed (ie. not starting from very beginning)
      linearPlaylist.episodes[episodeCounter].isResumed = true
      
      while true
        ret = m.player.playVideo(linearPlaylist.episodes[episodeCounter])

        'play next video in linear tv cue
        if ret <> "CLOSED"
          if episodeCounter < maxIndex
            episodeCounter = episodeCounter + 1
          else if episodeCounter = maxIndex
            episodeCounter = 0
          else
            exit while
          end if

          newEpisode = m.cp.getEpisodeInPlaylist(playlist, episodeCounter)
          if newEpisode <> invalid
            episode = newEpisode
            episode.PlayStart = 0
          end if
        else
          'set linearTvOn status to false and leave linear tv
          m.linearTv.linearTvOn = false
          exit while
        end if
      end while
    else
      'Add some messaging so the user knows there is no Live TV content for them.
    end if

  else if episode.type = "policy"
    m.policyScreen.show()

  else if episode.type = "video"   'episode is a movie
    ' does this app have you go through a details screen?
    if m.utils.getSettings().show_details_screen
      context = "/home/" + (listIndex + 1).toStr() + "/cat/" + m.utils.sluggify(playlist.name) + "/1/" + (itemIndex + 1).toStr()
      if source = "episodeListScreen"
        context = "/series/episodelist"
        if episode.parentId <> invalid
          context = context + "/" + episode.parentId
        end if
      end if
      m.utils.trackEvent({
        trackType: "navigate"
        value: "/video/" + episode.id
        ctx: context
        port: m.detailScreen.detailsPort
      })

      itemIndex = m.detailScreen.show(episode, playlist, itemIndex)
    else
      while episode <> invalid
        episode.PlayStart = 0
        if m.player.playVideo(episode) = "CLOSED"
          exit while
        end if
        episode = m.cp.getEpisodeInPlaylist(playlist, itemIndex+1)
        if episode <> invalid
          itemIndex = itemIndex + 1
        end if
      end while
    end if

  else   'episode is a series
    if episode.playlist <> invalid
      if (m.cp.autoplayData = invalid)

        m.utils.trackEvent({
          trackType: "navigate"
          value: "/series/episodelist/" + episode.id
          ctx: "/home/" + (listIndex + 1).toStr() + "/cat/" + m.utils.sluggify(playlist.name) + "/1/" + (itemIndex + 1).toStr()
          port: m.episodeListScreen.episodePort
        })      
	    
        m.episodeListScreen.show(episode)

      else if m.cp.autoplayIsSeries = true
        'm.cp.autoplayIsSeries = true if deeplinking occurred with the mediaType="series" parameter
        m.episodeListScreen.autoPlay(episode, m.cp.autoplayData.path[2], m.cp.autoplayData.path[3], m.cp.autoplayIsSeries)
      else
        'm.cp.autoplayIsSeason = true if deeplinking occurred with the mediaType="season" parameter
        m.episodeListScreen.autoPlay(episode, m.cp.autoplayData.path[2], m.cp.autoplayData.path[3], m.cp.autoplayIsSeason)
      end if
    end if
  end if
  return itemIndex
end Function

'create a message screen that will appear when the app loads, before the grid screen shows
'apps should usually call this via hotpatch so it loads before the rest of the app
'used for apps that are shutting down or no longer adding content
'headerText is string
'paragraphs is an array of paragraph text strings
'buttons is an associative array of button objects in the form
'{
' buttonText: "string of button text",
' buttonType: "string of button type"
'}
'acceptable button types are "continue", "deepLink" - deepLink will deeplink to TubiTv
Function AdriseApp_showPreMessage(headerText, paragraphs, buttons)
  port = CreateObject("roMessagePort")
  preMessageScreen = CreateObject("roParagraphScreen")
  preMessageScreen.SetMessagePort(port)

  'add header
  ' preMessageScreen.addHeaderText(headerText)
  preMessageScreen.addHeaderText("Horoscopes on The Astrologer will no longer")
  preMessageScreen.addHeaderText("be updated")
  
  'add paragraphs
  for each paragraph in paragraphs
    preMessageScreen.addParagraph(paragraph)
  end for

  'add buttons'
  buttonId = 1
  for each button in buttons
    preMessageScreen.addButton(buttonId, button.buttonText)
    buttonId = buttonId + 1
  end for

  'make the screen usable or 'live'
  preMessageScreen.show()

  while true
    msg = Wait(0, port)
    if type(msg) = "roParagraphScreenEvent"
      if msg.isButtonPressed()
        index = msg.GetIndex() - 1 'subtract one to match index in buttons array that was passed in
        buttonType = buttons[index].buttonType
        
        if buttonType = "deepLink"
          contentID = "41468" 'Tubi Tv content ID
          
          'get IP address
          di = CreateObject("roDeviceInfo")
          x = di.GetIPAddrs()
          for each i in x
            ipAddr =  x[i]
          end for

          'get all apps on device in the form of xml object
          xfer = CreateObject("roURLTransfer")
          getAppsUrl = "http://" + ipAddr + ":8060/query/apps"
          xfer.SetURL(getAppsUrl)
          res = xfer.GetToString() 'should return xml

          'set the deep link url
          if ipAddr <> invalid
            'default if tubitv does not exist on device
            externalLink = "http://" + ipAddr + ":8060/launch/11?contentID=" + contentID

            'if tubitv already on device
            xml = CreateObject("roXMLElement")
            if xml.Parse(res)
              for each child in xml.GetBody()
                  if child.GetName() = "app" and child.GetAttributes().id = contentID
                    externalLink = "http://" + ipAddr + ":8060/launch/" + contentID
                    exit for
                  endif
              end for
            end if 
          end if

          'make call to deep link
          xfer.SetURL(externalLink)
          result = xfer.PostFromString("")

          'close the screen and exit
          preMessageScreen.close()
          return true
        else 'buttonType = "continue"
          'close the screen and exit
          preMessageScreen.close()
          return true 
        end if
        exit while
      end if
    end if
  end while
  
  return false
end function

Function AdriseApp_showMessage (background, fontColor, loadingImageUrl, message)
  canvas = CreateObject("roImageCanvas")
  port = CreateObject("roMessagePort")
  canvas.SetMessagePort(port)
  background = {
    Color: background
  }
  loadingImage = {
    Url: loadingImageUrl
    TargetRect: {
      x: Int( m.utils.deviceInfo.displayWidth / 2 ) - Int( 336 / 2 ),
      y: Int( m.utils.deviceInfo.displayHeight / 2 ) - Int( 190 / 2 ),
      w: 336,
      h: 210
    }
  }

  loadingText = {
    Text: message
    TextAttrs: {
        Font: "Medium"
        VAlign: "Bottom"
        Color: fontColor
    },
    TargetRect: {
        x: loadingImage.TargetRect.x - 125
        y: loadingImage.TargetRect.y + 230
        w: loadingImage.TargetRect.w + 250
        h: 30
    }
  }
  canvas.SetLayer(2, [background, loadingImage, loadingText])
  canvas.Show()
  canvas.AddButton(1, "ok")
  while(true)
		 msg = wait(0,port)
		 if type(msg) = "roImageCanvasEvent" then
			if msg.isButtonPressed()
				button = msg.GetIndex()
				if (button = 1)
					return true
				end if
			end if
		 end if
   end while
   return true
end function
