print "Hot Patch 12"

settings = m.app.utils.getSettings()

themesFolder = "http://cdn.adrise.com/hotpatches/roku/themes/"

' theme = {
'   GridScreenLogoHD: themesFolder + "LG-comedy-gridscreenHD.png"
'   GridScreenLogoSD: themesFolder + "LG-comedy-gridscreenSD.png"
'   ' GridScreenDescriptionImageHD: themesFolder + "bubble-hd.png"
'   ' GridScreenDescriptionImageSD: themesFolder + "red_call_out_HD.png"
'   TallBannerHD: themesFolder + "LG-comedy-detailsHD.png"
'   TallBannerSD: themesFolder + "LG-comedy-detailsSD.png"
'   OverhangLogoHD: themesFolder + "LG-comedy-detailsHD.png"
'   OverhangLogoSD: themesFolder + "LG-comedy-detailsSD.png"
'   GridScreenBackgroundColor: "#000000"
'   BackgroundColor: "#000000"
' }


m.app.player.ads.isRokuAdFrameworkOn = true
m.app.player.useCustomPlayer = true

if m.app.settings.shortAppName = "tubitv"
  m.app.player.ads.roAdFramework.setAdPrefs(false, 2)

  'use to set RAF to a timer
  m.app.player.ads.rafTimer = function()
    date = CreateObject("roDateTime")

    formattedDate = date.AsDateString("short-date")
    'utc is +7 from pst
    if (formattedDate = "9/14/16" and date.GetHours() >= 22) or (formattedDate = "9/15/16" and date.GetHours() < 4)
    ' if formattedDate = "9/2/16"
      ' if date.GetHours() >= 16 and date.GetHours() <= 22 'runs from 10:00am-1:59pm
      ' if date.GetHours() = 17 and date.GetMinutes() <= 30 'runs from 10-10:30am'
        return true
      ' end if
    end if

    return false
  end function

  ' m.app.player.ads.isRokuAdFrameworkOn = m.app.player.ads.rafTimer()

  'UNCOMMENT BELOW TO TURN ON COIN FLIP RAF EXPERIMENT
  ' m.app.player.ads.coinFlip = function()
  '   rand = rnd(0)
  '   if rand >= 0.5
  '     return true
  '   else
  '     return false
  '   end if
  ' end function

  

  'use to change the theme (the theme details are above), ie. headers and background colors
  ' m.app.utils.appManager.setTheme(theme)

  m.app.linearTv.showLinearTv = true
  m.app.cp.showLinearTv = true
  m.app.cp.maxContent = 100

  'the below format can be used to target live tv schedule to a specific date
  'get the current date
  ' date = CreateObject("roDateTime")
  ' date.ToLocalTime()
  ' formattedDate = date.AsDateString("short-date")

  ' if formattedDate = "10/24/15"
  '   m.app.linearTv.hdposterurl = "http://192.168.1.31:8080/rokuHotpatches/LinearTV-horror-HD.png"
  '   m.app.linearTv.sdposterurl = "http://192.168.1.31:8080/rokuHotpatches/LinearTV-horror-SD.png"

  '   m.app.linearTv.newLinearEpisodes = [
  '     {
  '       id: "282413",
  '       title: "George A. Romero's Day of the Dead"
  '     },
  '     {
  '       id: "284006",
  '       title: "The Terror Experiment"
  '     },
  '     {
  '       id: "241962",
  '       title: "Gangsters, Guns, and Zombies"
  '     },
  '     {
  '       id: "15585",
  '       title: "Aaah! Zombies!!!"
  '     },
  '     {
  '       id: "51147",
  '       title: "Toxic Zombies"
  '     },
  '     {
  '       id: "241969",
  '       title: "Outpost: Black Sun"
  '     },
  '     {
  '       id: "51151",
  '       title: "Zombie Brigade"
  '     },
  '     {
  '       id: "12682",
  '       title: "Zombie Undead"
  '     },
  '     {
  '       id: "289782",
  '       title: "All Souls Day"
  '      }
  '   ]
  ' end if  

  ' m.app.linearTv.linearEpisodes.Append(m.app.linearTv.newLinearEpisodes)


  ' ' set Registration Wall
  ' m.app.cp.isRegWall = true
  ' premiereRegWallContent = [
  '   268533,
  '   268544,
  '   268563,
  '   269529,
  '   278532,
  '   278538,
  '   268504,
  '   268557,
  '   273558,
  '   273559,
  '   273579,
  '   268506,
  '   273560,
  '   273580,
  '   268510,
  '   268511,
  '   268558,
  '   268539,
  '   268512,
  '   268513,
  '   273561,
  '   268514,
  '   268515,
  '   268516,
  '   273562,
  '   273564,
  '   273566,
  '   268519,
  '   273567,
  '   278539,
  '   273568,
  '   268520,
  '   268546,
  '   268521,
  '   268522,
  '   278534,
  '   268523,
  '   278535,
  '   273565,
  '   268524,
  '   278536,
  '   268525,
  '   268526,
  '   268528,
  '   268529,
  '   268530,
  '   268531,
  '   268532,
  '   268534,
  '   268535,
  '   278537,
  '   268536,
  '   268507,
  '   268508,
  '   268509,
  '   268541,
  '   268561,
  '   268543,
  '   268545,
  '   268564,
  '   268548,
  '   278533,
  '   268517,
  '   268518,
  '   268559,
  '   278666,
  '   278667,
  '   268527,
  '   268560,
  '   268537,
  '   268538,
  '   268540,
  '   268542,
  '   268562,
  '   268547,
  '   268549,
  '   268565,
  '   268550,
  '   268551,
  '   278540,
  '   268552,
  '   278541,
  '   268553,
  '   268554,
  '   268555,
  '   269939,
  '   269940,
  '   269941,
  '   269942,
  '   269943,
  '   269532,
  '   268556,
  '   268566,
  '   269533,
  '   278542
  ' ]
  
  ' for each id in premiereRegWallContent
  '   m.app.cp.regWallContent.SetEntry(id, "premiere")
  ' end for

  'prevent any categories named "After Hours" from being added to the gridscreen
  ' m.app.cp.getAllPlaylistsFromServer = function()
  '   xml = m.utils.getXml(m.urls.getPlaylists, "getApp_v2")

  '   if xml = invalid or xml.GetName() <> "app"
  '     return false
  '   end if
    
  '   m.playlists = []
  '   errorMessage = xml.errormessage.getText()

  '   if errorMessage <> ""
  '     m.errorMessage = errorMessage
  '   else
  '     if GetGlobalAA().app.gridscreen.rowOffset <> invalid
  '       rowOffset = GetGlobalAA().app.gridscreen.rowOffset
  '     else
  '       rowOffset = 0
  '     end if
  '     m.playlistCounter = 0
      
  '     for each child in xml.children.level
  '       if child.title.getText() <> "After Hours"
  '         m.path[0] = m.playlistCounter + rowOffset
  '         m.playlists.push(m.getPlaylistFromXmlObj(child, m.imageSize, 1, invalid, "gridscreen"))
  '         m.playlistCounter = m.playlistCounter + 1
  '       end if
  '     end for
  '   end if
  ' end function


  m.app.runApp = function()
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

      'v4 API url base
      GetGlobalAA().app.settings.cmsApiUrlBase = "https://uapi.adrise.tv/cms/contents?platform=" + GetGlobalAA().app.settings.platformName

      'registration url
      GetGlobalAA().app.settings.regUrlBase = "https://uapi.adrise.tv/user_device/code"

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

        'if deep linked from Roku search it's possible that we are deep linking to a series, instead of actual video content
        'deep links from search for series should like:
        'contentID=335&MediaType=series
        if m.params.MediaType = "series"
          m.cp.autoplayIsSeries = true
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
        
        m.utils.trackEvent({
          trackType: "deepLink"
          value: m.params.contentID            
          ctx: deepLinkSource
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


    'if linkStatus = "ok"
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
        print authInfo

        'one time login sync - checks if old registration data exists and if so, gets new auth info and deletes old registration data
        if authInfo.accessToken = invalid
          authInfo = m.utils.oneTimeLoginMigration()
        end if
        
        if authInfo.accessToken = invalid
          m.registerScreen.show()
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
          path = m.cp.getEpisodeByPath(m.cp.autoplayData.path)
          m.selectedItem.listIndex = m.cp.autoplayData.path[0]
          m.selectedItem.itemIndex = m.cp.autoplayData.path[1]
        end if

        'does appropriate action based on what 'episode' was selected (includes options on register/search row)
        playlist = m.cp.getPlaylist(m.selectedItem.listIndex)
        m.selectedItem.itemIndex = m.handleItemPicked(playlist, m.selectedItem.itemIndex)

        m.cp.autoplayData = invalid
      end while

      if m.cp.errorMessage <> invalid
        m.utils.showErrorMessage (m.utils.getSettings().adrise_bg, m.utils.getSettings().adrise_fontcolor, m.utils.getSettings().adrise_loadingurl, m.cp.errorMessage)
      end if
    'end if

    m.utils.trackEvent({
      trackType: "ExitApp"
    })
  end function

  '-------------_contentProvider.getBookmarksAndPreviouslyViewedFromServer()------------
  m.app.cp.getBookmarksAndPreviouslyViewedFromServer = function()
    settings = m.utils.getSettings()
    getBookmarksPort = CreateObject("roMessagePort")

    authInfo = m.utils.getAuthInfo()  'from memory

    'if the user is not logged in (aka doesn't have an accessToken in local memory),
    'then don't get any bookmarks or previously viewed
    if authInfo.accessToken = invalid
      return invalid
    end if
    
    authInfo = m.utils.checkIfAuthExpired(authInfo)
    headers = m.utils.getAuthHeaders(authInfo.accessToken)

    'get bookmarks from server
    bookmarksId = m.utils.sendAsyncRequest(settings.bookmarksUrlNoPage, getBookmarksPort, "getAllBookmarks", "GET", true, invalid, headers)
    fullBookmarksId = invalid

    'get previously viewed from server
    previouslyViewedId = m.utils.sendAsyncRequest(settings.previouslyViewedUrlNoPage, getBookmarksPort, "getAllPreviouslyViewed", "GET", true, invalid, headers)
    fullPreviouslyViewedId = invalid

    hasBookmarks = false
    hasPreviouslyViewed = false
    basicPreviouslyViewed = invalid
    while true
      msg = wait(0, getBookmarksPort)
      if type(msg) = "roUrlEvent"
        response = m.utils.getAsyncResponse(msg, 0)

        if response.id = bookmarksId
          basicBookmarks = response.data
          fullBookmarksId = m.handleGetUserPlaylists(settings.bookmarkRegistry, response.data, getBookmarksPort)

          'if we don't get full bookmark data then set state so we can leave this while loop
          if fullBookmarksId = invalid
            hasBookmarks = true
          end if

        else if response.id = previouslyViewedId
          basicPreviouslyViewed = response.data
          fullPreviouslyViewedId = m.handleGetUserPlaylists(settings.previouslyViewedRegistry, response.data, getBookmarksPort)

          'if we don't get full previously viewed data then set state so we can leave this while loop
          if fullPreviouslyViewedId = invalid
            hasPreviouslyViewed = true
          end if

        else if response.id = fullBookmarksId
          m.parseAndSaveBookmarks(response.data, basicBookmarks)
          hasBookmarks = true

        else if response.id = fullPreviouslyViewedId
          m.parseAndSavePreviouslyViewed(response.data, basicPreviouslyViewed)
          hasPreviouslyViewed = true

        end if
      end if

      if hasBookmarks = true and hasPreviouslyViewed = true
        exit while
      end if

    end while
  end function


  'when a user presses play, we ask the cms for the most recent url (in case the token may have expired). If for some reason the CMS
  'returns an empty response, we don't update the stream url. Previously we were updating the stream url to an empty string in this situation
  m.app.cp.getUpdatedUrlForEpisode = function(episode)
    'get roXml object
    episodeFromServer = m.getEpisodeFromServer(episode.id)

    if type(episodeFromServer) = "roXMLList" and episodeFromServer.url.getText().len() > 0
      episode.streams = [{url: episodeFromServer.url.getText()}]
    end if

    return episode
  end function


  'change the video completed event to occur at 95% instead of duration - 10s
  m.app.player.playVideo = function(episode as Object)

    'updates the episode with a new url right before a video is about to play
    'this should prevent a user from running up against an expired DRM token in most cases
    episode = GetGlobalAA().app.cp.getUpdatedUrlForEpisode(episode)

    episode.SwitchingStrategy="full-adaptation"

    ' previously in hotpatch 1
    if m.definition = "sd"
        episode.isHD = false
        episode.hdBranded = false
        if episode.streams <> invalid
          for each stream in episode.streams
            stream.quality = false
          end for
        end if
    end if
    ' end hotpatch

    m.ads.reset()
    episode.nowPos = 0
    m.lastPingTime = -1


    'get the state of the app - ie. where is the player coming from? linear TV? bookmarks? previously viewed?
    m.linearTvOn = GetGlobalAA().app.linearTV.linearTvOn

    'send tracking event that the video started playing
    vidOrSeries = "video"
    if episode.isParentSeries = true
      vidOrSeries = "series"
    end if

    vidSource = {}
    if m.linearTvOn = true
      vidSource.channel = "roku channel"
    else
      vidSource.category = episode.category
    end if

    m.utils.trackEvent({
      trackType: "videoPlay"
      value: episode.id
      ctx: vidOrSeries
      extraCtx: vidSource
      port: m.playerPort
    })

    if episode.playStart <> invalid
      episode.nowPos = episode.playStart
    endif


    ' set up a video ad
    canvas = CreateObject("roImageCanvas")
    canvas.SetMessagePort(m.playerPort)
    canvas.SetLayer(1, {color: "#000000"})
    canvas.Show()

    if m.subscription = false
      if episode.pubId <> invalid and episode.pubId <> ""
        m.pubId = episode.pubId
      end if

      'check if the user is resuming an episode - if so, check if they left off on a cue point
      'if they didn't leave off on a cue point, don't show them any more ads
      if episode.isResumed = true
        'get the cuepoints for the current content and checks if the resume position is on a cuepoint
        cuepoints = m.ads.getCuepoints(episode)
        resumeCuepoint = -1 'default vaule
        if cuepoints <> invalid
          resumeCuepoint = m.ads.checkForCommercialBreak(episode.nowPos, episode, m)
        end if
      end if

      'if the user resumed content but didn't resume on a cue point, then don't show any ads
      if episode.isResumed = true and resumeCuepoint = -1
        'COMPLETED means the player thinks the ads completed so show the content
        'in our case we are not showing ads so act as if they completed
        status = "COMPLETED"

      'otherwise if the user is starting from beginning or resuming on a cue point, show ads
      else
        'get list of ads and play them for preroll
        'UNCOMMENT BELOW TO TURN ON COIN FLIP RAF EXPERIMENT
        ' if m.ads.coinFlip() = true and m.ads.rafTimer() = true
        '   m.ads.isRokuAdFrameworkOn = true
        ' end if

        'COMMENT BELOW WHEN USING THE COIN FLIP
        ' m.ads.isRokuAdFrameworkOn = m.ads.rafTimer()

        if m.ads.isRokuAdFrameworkOn = true
          m.ads.getAdsListViaRoku(episode, m)
          status = m.ads.showCommercialBreakViaRoku(canvas, m)
        else
          videoAdsList = m.ads.getAdsList(episode, m)
          status = m.ads.showCommercialBreak(canvas, videoAdsList, m)
        end if
      end if


      if status = "CLOSED"
        canvas.close()

        if m.linearTvOn = true
          m.utils.trackEvent({
            trackType: "linearVideoStopAd"
            value: episode.adrise_contentid
            ctx: episode.nowPos
            port: m.playerPort
          })
        else
          m.utils.trackEvent({
              trackType: "videoStopAd"
              value: episode.adrise_contentid
              ctx: episode.nowPos
              port: m.playerPort
          })
        end if

        print "closed on first commercial break"
        return "CLOSED"
      else
        'the ads weren't closed by the user, so if this was a resume situation, update that the midroll was played
        ' if episode.isResumed = true and resumeCuepoint <> invalid
        '   m.ads.midrolls
        ' end if


      end if
    end if


    ' if the pre-roll ad completed without the user closing it explicitly,
    ' (or there was no pre-roll because it is a subscription app), play the content
    while true
      if m.useCustomPlayer = false
        status = m.showSpanOfContentVideo(episode)
      else
        status = m.showSpanOfContentVideoNew(episode)
      end if

      while status = "FAILED"
        failHandlerStatus = m.handleVideoFailure(episode)
        if failHandlerStatus = "CLOSE"
          canvas.close()

          if m.linearTvOn = true
            m.utils.trackEvent({
              trackType: "linearVideoFailure"
              value: episode.adrise_contentid
              ctx: episode.nowPos
              port: m.playerPort
            })
          else
            m.utils.trackEvent({
              trackType: "videoFailure"
              value: episode.adrise_contentid
              ctx: episode.nowPos
              port: m.playerPort
            })
          end if

          return "CLOSE"
        else if failHandlerStatus = "IGNORE"
          exit while
        else
          status = failHandlerStatus
          exit while
        end if
      end while

      'while status = "FAILED"
      '  if m.promptForVideoFailure() = "exit"
      '    print "Exit!"
      '    canvas.close()
      '    return "CLOSED"
      '  end if
      '  print "restart failed video"
      '  episode.playStart = episode.nowPos
      '  status = m.showSpanOfContentVideo(episode)
      'end while

      'if STOPFORCOMMERCIAL we already have a validated cached ads list, so run the ads in the cache
      if status = "STOPFORCOMMERCIAL"
        Sleep(500) ' to ensure proper playback of the midroll

        canvas.SetMessagePort(m.playerPort)
        canvas.SetLayer(1, {color: "#000000"})
        canvas.Show()

        'get list of ads and play them
        if m.ads.isRokuAdFrameworkOn = true
          status = m.ads.showCommercialBreakViaRoku(canvas, m)
        else
          videoAdsList = m.ads.getCachedAdsList(episode)
          status = m.ads.showCommercialBreak(canvas, videoAdsList, m)
        end if

        if status = "CLOSED"
          canvas.close()

          if m.linearTvOn = true
            m.utils.trackEvent({
              trackType: "linearVideoStopAd"
              value: episode.adrise_contentid
              ctx: episode.nowPos
              port: m.playerPort
            })
          else
            m.utils.trackEvent({
              trackType: "videoStopAd"
              value: episode.adrise_contentid
              ctx: episode.nowPos
              port: m.playerPort
            })
          end if

          print "closed on midroll commercial break"
          return "CLOSED"
        end if
      else
        if status = "CLOSED"
          if episode.nowPos > episode.length * 0.95

            if m.linearTvOn = true
              m.utils.trackEvent({
                trackType: "linearVideoStopComplete"
                value: episode.adrise_contentid
                ctx: episode.nowPos
                port: m.playerPort
              })
            else
              m.utils.trackEvent({
                trackType: "videoStopComplete"
                value: episode.adrise_contentid
                ctx: episode.nowPos
                port: m.playerPort
              })
            end if

          else

            if m.linearTvOn = true
              m.utils.trackEvent({
                trackType: "linearVideoStopContent"
                value: episode.adrise_contentid
                ctx: episode.nowPos
                port: m.playerPort
              })
            else         
              m.utils.trackEvent({
                trackType: "videoStopContent"
                isComplete: false
                value: episode.adrise_contentid
                ctx: episode.nowPos
                port: m.playerPort
              })
            end if

          end if
        end if

        if status = "COMPLETED"

          if m.linearTvOn = true
            m.utils.trackEvent({
              trackType: "linearVideoStopComplete"
              value: episode.adrise_contentid
              ctx: episode.nowPos
              port: m.playerPort
            })          
          else
            m.utils.trackEvent({
              trackType: "videoStopComplete"
              value: episode.adrise_contentid
              ctx: episode.nowPos
              port: m.playerPort
            })
          end if
        end if

        canvas.close()
        return status
      end if
    end while
  end function



  'fix bug on deep linking to series - seen when selecting a series from Roku Universal Search
  m.app.handleItemPicked = function(playlist, itemIndex)

    episode = m.cp.getEpisodeInPlaylist(playlist, itemIndex)

    if episode.type = "tubiLogin" or episode.type = "bookmarks"
      authInfo = m.utils.getAuthInfo()
      if (authInfo.accessToken = invalid)
        'user wants to log in
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
              
              'remove local bookmarks and previously viewed id arrays - so that we won't build those categories after logout
              m.cp.bookmarkIds = []
              m.cp.previouslyViewedIds = []

              'set isBookmarks and isPreviouslyViewed to false so users wont see the remove from bookmarks button on details page
              m.cp.userPlaylistVideos = {}
              m.cp.userPlaylistSeries = {}

              'set state so we know if we need to add the user playlists rows if the user logs back in
              m.gridscreen.isShownAfterLogin = false

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
      m.searchScreen.show()
    else if episode.type = "linear" 'play linear tv
      'get episode content for linear episodes
      linearPlaylist = m.linearTv.getLinearPlaylist()
      m.cp.getAllEpisodesForPlaylistFromServer(linearPlaylist, "gridscreen")

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

            episode = m.cp.getEpisodeInPlaylist(playlist, episodeCounter)
            episode.PlayStart = 0
          else
            'set linearTvOn status to false and leave linear tv
            m.linearTv.linearTvOn = false
            
            m.utils.trackEvent({
              trackType: "linearTvEnd"
            })

            exit while
          end if
        end while
      else
        'Add some messaging so the user knows there is no Live TV content for them.
      end if

    else if episode.type = "video"   'episode is a movie

      ' does this app have you go through a details screen?
      if m.utils.getSettings().show_details_screen
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
          m.episodeListScreen.show(episode)
        else
          ' m.episodeListScreen.autoPlay(episode.playlist, m.cp.autoplayData.path[2], m.cp.autoplayData.path[3])
          m.episodeListScreen.autoPlay(episode, m.cp.autoplayData.path[2], m.cp.autoplayData.path[3])
          m.cp.autoplayData = invalid
        end if
      end if
    end if
    return itemIndex
  end Function


  'fix crashing bug - when there's an issue with user playlists
  m.app.gridScreen.showUserPlaylists = function(playlistType)
    settings = m.utils.getSettings()
    episodes = []
    episode = invalid
    idList = invalid
    idType = invalid
    
    if playlistType = settings.bookmarkRegistry
      catName = settings.bookmarksCatName
      idList = m.cp.bookmarkIds
    else if playlistType = settings.previouslyViewedRegistry
      catName = settings.previouslyViewedCatName
      idList = m.cp.previouslyViewedIds
    else
      return invalid
    end if

    if idList <> invalid and idList.count() > 0

      for each cid in idList
        if Left(cid, 1) = "v"
          idType = "video"
        else if Left(cid, 1) = "s"
          idType = "series"
        end if
        
        id = Mid(cid, 2, Len(cid)-1)

        if Left(cid, 1) = "v" 'it's a video
          if m.cp.userPlaylistVideos[id] <> invalid
            episode = m.cp.userPlaylistVideos[id]
          end if

        else if Left(cid, 1) = "s" 'it's a series
          if m.cp.userPlaylistSeries[id] <> invalid
            episode = m.cp.userPlaylistSeries[id]
            episode.category = catName
          end if
        end if

        if episode <> invalid
          episodes.push(episode)
        end if
      end for
    end if

    if episodes.count() > 0
      playlist = {
        episodes: episodes
        name: settings.bookmarksCatName
      }
      m.cp.prependPlaylistToPlaylists(playlist)
    end if

  end function

  m.app.cp.setUrlsWithContentType = function()
    version = m.utils.deviceInfo.firmwareVersion
    major = Int(version)
    if major = 3
      contentType = "mp4"
    else
      contentType = "hls"
    end if

    model = m.utils.deviceInfo.model

    m.urls = {
      getPlaylists: m.server + "/v2/app.php?id=" + m.shortAppName + "&platform=roku&format=xml&content-type=" + contentType + "&model=" + model + "&video-fields=title&sdk=5.0"
      getVideos: m.server + "/v2/videos.php?app-id=" + m.shortAppName + "&platform=roku&content-type=" + contentType + "&model=" + model + "&format=xml&id="
    }
  end function

  m.app.cp.getAllPlaylistsFromServer = function()
    m.setUrlsWithContentType()
    xml = m.utils.getXml(m.urls.getPlaylists, "getApp_v2")

    if xml = invalid or xml.GetName() <> "app"
      return false
    end if

    m.playlists = []
    errorMessage = xml.errormessage.getText()
    if errorMessage <> ""
      m.errorMessage = errorMessage
    else
      if GetGlobalAA().app.gridscreen.rowOffset <> invalid
        rowOffset = GetGlobalAA().app.gridscreen.rowOffset
      else
        rowOffset = 0
      end if
      m.playlistCounter = 0
      for each child in xml.children.level
        m.path[0] = m.playlistCounter + rowOffset
        m.playlists.push(m.getPlaylistFromXmlObj(child, m.imageSize, 1, invalid, "gridscreen"))
        m.playlistCounter = m.playlistCounter + 1
      end for
    end if
  end function


  'needed to run RAF "apples to apples" experiment
  'UNCOMMENT BELOW TO TURN ON COIN FLIP RAF EXPERIMENT
  m.app.player.ads.cacheAdsList = function(episode, breakPos, playerSettings)
    if(m.lastAdsList = invalid or m.lastAdsList.breakPos <> breakPos or m.lastAdsList.cid <> episode.adrise_contentId) 
      tmp = episode.nowPos
      episode.nowPos = breakPos

      ' if m.coinFlip() = true and m.rafTimer() = true
      '   m.isRokuAdFrameworkOn = true
      ' end if

      ' m.isRokuAdFrameworkOn = m.rafTimer()

      if m.isRokuAdFrameworkOn = true
        m.getAdsListViaRoku(episode, playerSettings)
        res = m.allAdUnitsList
      else
        res = m.getAdsList(episode, playerSettings)
      end if

      episode.nowPos = tmp
      
      m.lastAdsList = {
        cid: episode.adrise_contentId
        breakPos: breakPos
        list: res
      }
    end if
  end function


  'a function used as a callback every time RAF fires a trackign pixel
  'obj should be the currentAdsList
  ' m.app.player.ads.rafTrackingCallback = function(obj = Invalid, eventType = Invalid, ctx = Invalid)
  '   ads = obj
    
  '   'Impression is fired before "Start". 0% and Impression pixels are fired at Impression
  '   if eventType = "Impression" or eventType = "Start" or eventType = "Complete"
  '     adParentId = invalid
  '     currentAd = invalid
  '     adRisePixels = []
  '     'loop through each pixel in the ad until we find an adrise pixel so we can get the parent Id for the ad
  '     for each adPixel in ctx.ad.tracking
  '       if mid(adPixel.url, 8, 13) = "ads.adrise.tv"
  '         'get the ad parent id
  '         if adParentId = invalid
  '           if mid(adPixel.url, 33, 7) = "php?id="  'we have a percentage
  '             adParentId = mid(adPixel.url, 55, 5)
  '           else if mid(adPixel.url, 39, 7) = "php?id="  'we have an impression
  '             adParentId = mid(adPixel.url, 61, 5)
  '           end if
  '         end if
          
  '         adPixel.deviceid = ads.utils.deviceInfo.deviceId
  '         adRisePixels.push(adPixel)
  '       end if

  '       if currentAd = invalid
  '         if mid(adPixel.url, 8, 24) = "ads.adrise.tv/track/view"
  '           currentAd = val(mid(adPixel.url, 61, 1))
  '         else if mid(adPixel.url, 8, 30) = "ads.adrise.tv/track/impression"
  '           currentAd = val(mid(adPixel.url, 67, 1))
  '         end if
  '       end if

  '     end for

  '     'prepare ad call
  '     body = {}
  '     if ctx.ad <> invalid and ctx.ad.adId <> invalid
  '       body.adid = ctx.ad.adId
  '     end if
  '     if adParentId <> invalid then body.ad_parent_id = adParentId
  '     if ctx.adServer <> invalid then body.adserver = ctx.adServer
  '     body["type"] = eventType
  '     body.deviceid = ads.utils.deviceInfo.deviceId
  '     if ctx.time <> invalid then body.time = ctx.time
  '     if ctx.adIndex <> invalid then body.adindex = ctx.adIndex
  '     if currentAd <> invalid then body.adindex_tubi = currentAd
  '     if ctx.ad.streamFormat <> invalid then body.streamformat = ctx.ad.streamformat
  '     if ctx.errType <> invalid then body.errType = ctx.errType
  '     if ctx.errCode <> invalid then body.errCode = ctx.errCode
  '     if ctx.errMsg <> invalid then body.errMsg = Left(ctx.errMsg, 256)
  '     body.tracking = adRisePixels

  '     jsonBody = FormatJson(body)
  '     headers = {"Content-Type": "application/json"}
  '     url = "https://8ehzajn9yf.execute-api.us-west-2.amazonaws.com/logger/raf"

  '     if ads.rafAnalysisIds = invalid
  '       ads.rafAnalysisIds = {}
  '     end if

  '     reqId = ads.utils.sendAsyncRequest(url, ads.playerPort, "rafAnalysis", "POST", true, jsonBody, headers)
  '     if reqId <> invalid
  '       ads.rafAnalysisIds[reqId.toStr()] = true
  '     end if
  '   end if
  ' end function

  ' m.app.player.ads.roAdFramework.setTrackingCallback(m.app.player.ads.rafTrackingCallback, m.app.player.ads)

  'changes the cache timing to only at 5 seconds before the cuepoint, instead of multiple seconds
  m.app.player.ads.checkForCommercialBreak = function(nowpos, episode, playerSettings)
    if m.midrolls.count() > 0
      'iterate over each cue point'
      for i=0 to m.midrolls.count()-1 step +1
        breakpoint = m.midrolls[i]
        if (breakpoint <> invalid)
          'if the player is within 4 to 7 seconds before the cue point being iterated over
          ' if((nowpos > breakpoint-7) and (nowpos < breakpoint-4))
          if(nowPos = breakpoint-5)
            'make a call to the server to get ads, and save ads in "cache" or memory
            m.cacheAdsList(episode, breakpoint, playerSettings) 
          end if

          'if the player is at the cue point being iterated and we haven't previously played this cuepoint
          'then return the cuepoint so the player can play an ad
          if nowpos = breakpoint
            'by setting the midroll time to -1000, you prevent the user from hitting that midroll again while
            'they are watching the content (for instance if the rewind to a point before a midroll they won't stumble on ads again)
            m.midrolls[i] = -1000
            return breakpoint
          end if
        end if
      end for
    end if
    return -1
  end function




  'determine if we have a roku that is susceptible to crashing
  m.app.utils.isRokuTwo = function()
    rokuTwos = {
      "2400X": true
      "2450X": true
      "2500X": true
      "2720X": true
      "3000X": true
      "3050X": true
      "3100X": true
      "3400X": true
      "3420X": true
      "3500X": true
    }

    if rokuTwos[m.deviceInfo.model] = true
      isTwo = true
    else
      isTwo = false
    end if

    return isTwo
  end function

  m.app.utils.deviceInfo.rokuTwo = m.app.utils.isRokuTwo()


  m.app.cp.getPlaylistFromXmlObj = function(obj, imageSize, depth, parent, source)
    categoryTitle = ValidStr(obj.title.getText())
    videosIdString = ""
    items = []
    videos = {}
    bookmarksPrelim = {}
    previousPrelim = {}
    children = obj.children.getChildElements()
    count = 0
    
    'get saved Bookmarks and Previously Viewed
    userPlaylistContent = m.getSavedUserContentFromMemory()
    
    for each child in children  'child = level or video for a row/category/playlist
      'add linear TV content if necessary
      if m.playlistCounter = 0 and count = 2 and depth = 1 and m.showLinearTV = true and m.linearTvAdded = false
        linearItem = {
          type : "linear"
          title: "Live TV (beta)"
          description: "Tubi TV brings you TV programmed for you. Just sit back and enjoy." + chr(10) + chr(10) + "Send us your feedback:" + chr(10) + "support@tubitv.com"
          shortDescriptionLine1 : "Live TV (beta)"
          sdposterurl: GetGlobalAA().app.linearTv.sdposterurl
          hdposterurl: GetGlobalAA().app.linearTv.hdposterurl
        }
        items.push(linearItem)
        m.linearTvAdded = true
        count = count + 1
      end if

      if m.utils.deviceInfo.rokuTwo <> true or count < m.maxContent
      
        id = child.id.getText()

        if child.getName() = "video"
          item = {
            type : "video"
            title: child.title.getText()
            id: id
            adrise_contentId: id
            position: count
            category: categoryTitle
          }

          ' 'if there is a parent item, it means we are at the season or episode level
          if parent <> invalid
            item.isParentSeries = true
            item.parentId = parent.id
            item.parentTitle = parent.title
            item.category = parent.category

          else
            'series level and stand alone movies will be false
            item.isParentSeries = false
          end if

          videos[id] = item
          videosIdString = videosIdString + "," + id
          items.push({})
        
          'if video content has been saved as either bookmarks or previously viewed in the registry, populate separate user playlists
          if id <> invalid and source = "gridscreen"
            prependedId = "v" + id
            'the id matches and it's a video so set up the preliminary hash for bookmarks
            if userPlaylistContent <> invalid and userPlaylistContent.savedBookmarks[prependedId] <> invalid
              'only add the content to the bookmarks playlist if it hasn't already been added (in case the content exists in more than one category)
              if m.userPlaylists.bookmarks.videosPrelim[id] = invalid
                m.userPlaylists.bookmarks.videosPrelim[id] = true  'only used to prevent duplicates

                'item is updated by reference later when it gets pushed through getAllEpisodesForPlaylistFromServer
                'during the normal course of loading the main gridscreen
                ' m.userPlaylists.bookmarks.episodes.push(item)
                m.userPlaylists.bookmarks.episodes.push(prependedId)
                'add the id to the videosIdString
                m.userPlaylists.bookmarks.videosIdString = m.userPlaylists.bookmarks.videosIdString + "," + id
              end if
            end if

            'the id matches and it's a video so set up the preliminary hash for previously viewed
            if userPlaylistContent <> invalid and userPlaylistContent.savedPrevious[prependedId] <> invalid
              'only add the content to the previously viewed playlist if it hasn't already been added (in case the content exists in more than one category)
              if m.userPlaylists.previous.videosPrelim[id] = invalid
                m.userPlaylists.previous.videosPrelim[id] = true  'only used to prevent duplicates
                
                'item is updated by reference later when it gets pushed through getAllEpisodesForPlaylistFromServer
                'during the normal course of loading the main gridscreen            
                ' m.userPlaylists.previous.episodes.push(item)
                m.userPlaylists.previous.episodes.push(prependedId)
                'add the id to the videosIdString
                m.userPlaylists.previous.videosIdString = m.userPlaylists.previous.videosIdString + "," + id
              end if
            end if
          end if
          
          'set up autoplay for videos (from deeplinking usually or maybe from search screen)
          if(id = m.autoplayId and m.autoplayIsSeries = false)
            p = []
            for i=0 to depth-1 step +1
              p[i] = m.path[i]
            end for
            p.push(count)
            m.autoplayData = { item: item, path: p, depth: depth }
            m.autoplayId = invalid
            print "have autoplay---------------------"
          end if

        else 'child.getName() = 'level' -> means it is a series
          thumbUrl = invalid
          settings = m.utils.getSettings()

          if settings.GridStyle = "two-row-flat-landscape-custom"
            if child.posterartUrl <> invalid
              thumbUrl = child.posterartUrl.getText()
            end if
          else
            if child.thumbnailUrl <> invalid
              thumbUrl = child.thumbnailUrl.getText()
            end if
          end if

          m.path[depth] = count

          item = {
            id: id
            type : "level"
            title: child.title.getText()
            description: child.description.getText()
            shortDescriptionLine1 : child.title.getText()
            'shortDescriptionLine2 : child.description.getText()
            hdposterurl: thumbUrl
            sdPosterURL: thumbUrl
            category: categoryTitle
          }

          'maintains the top level parent for all children ie the parent of an episode is the series, not the season
          if parent = invalid 
            'sending series as parent to season
            topLevel = item 
          else
            'sending series as parent to child
            topLevel = parent 
          end if
          item.playlist = m.getPlaylistFromXmlObj(child, imageSize, depth+1, topLevel, source)
          items.push(item)

          ' if series content has been saved as either bookmarks or previously viewed in the registry, populate separate user playlists
          if id <> invalid and source = "gridscreen"
            prependedId = "s" + id

            'the id matches and it's a series so set up the preliminary hash for bookmarks
            if userPlaylistContent <> invalid and userPlaylistContent.savedBookmarks[prependedId] <> invalid
              'only add the content to the bookmarks playlist if it hasn't already been added (in case the content exists in more than one category)
              if m.userPlaylists.bookmarks.seriesPrelim[id] = invalid
                m.userPlaylists.bookmarks.episodes.push(prependedId)
                m.userPlaylists.bookmarks.seriesPrelim[id] = true 'only used to prevent duplicates
              end if
            end if

            'the id matches and it's a series so set up the preliminary hash for previously viewed
            if userPlaylistContent <> invalid and userPlaylistContent.savedPrevious[prependedId] <> invalid
              if m.userPlaylists.previous.seriesPrelim[id] = invalid
                m.userPlaylists.previous.episodes.push(prependedId)
                m.userPlaylists.previous.seriesPrelim[id] = true 'only used to prevent duplicates
              end if
            end if
          end if

          'set up autoplay for series (from deeplinking usually or maybe from search screen)
          if(id = m.autoplayId and m.autoplayIsSeries = true)
            p = []
            for i=0 to depth-1 step +1
              p[i] = m.path[i]
            end for
            p.push(count)
            m.autoplayData = { item: item, path: p, depth: depth }
            m.autoplayId = invalid
            print "have autoplay---------------------"
          end if

        end if
      end if

      count = count + 1
    end for

    'remove the leading comma in videosIdString
    videosIdString = videosIdString.mid(1)

    return {
      name: obj.title.getText()
      depth: depth
      videosPrelim: videos
      episodes: items
      videosIdString: videosIdString
    }
  end function



  'remove roUrlTransfers from RAF
  m.app.player.ads.showCommercialBreakViaRoku = function(canvas, playerSettings)
    ' ShowVariable(m.allAdUnitsList, "ALL AD UNITS LIST", 4)
    if m.allAdUnitsList.count() > 0
      currentAdPosition = 1
      for each adUnitsListContainer in m.allAdUnitsList
        if adUnitsListContainer.adUnitsList <> invalid and adUnitsListContainer.adUnitsList.count() > 0
          if adUnitsListContainer.type <> invalid and adUnitsListContainer.type = "roku"

            'create the object that will populate the "Ad 1/5" text overlay in RAF
            screenCount = {
              start: currentAdPosition
              total: m.totalAdBreakAds
            }

            isCompleted = m.roAdFramework.showAds(adUnitsListContainer.adUnitsList, screenCount)
            m.roadframework.mediator.util.xfers = []

            if isCompleted = false
              print "RAF ads not completed"
              return "CLOSED"
            end if
            currentAdPosition = currentAdPosition + adUnitsListContainer.adUnitsList.count()
          else if adUnitsListContainer.type <> invalid and adUnitsListContainer.type = "adrise"
            status = m.showCommercialBreak(canvas, adUnitsListContainer.adUnitsList, playerSettings)
            if status = "CLOSED"
              return status
            end if
            currentAdPosition = currentAdPosition + adUnitsListContainer.adUnitsList.count()
          end if
        end if
      end for
    end if
    
    return "COMPLETED"
  end function

end if
