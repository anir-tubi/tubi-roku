print "Hot Patch 13"

settings = m.app.utils.getSettings()

'themesFolder = "http://cdn.adrise.com/hotpatches/roku/themes/"

' theme = {
'   GridScreenLogoHD: themesFolder + "narrow_banner_HD.png"
'   GridScreenLogoSD: themesFolder + "narrow_banner_SD.png"
'   ' GridScreenDescriptionImageHD: themesFolder + "bubble-hd.png"
'   ' GridScreenDescriptionImageSD: themesFolder + "red_call_out_HD.png"
'   TallBannerHD: themesFolder + "wide_banner_HD.png"
'   TallBannerSD: themesFolder + "wide_banner_SD.png"
'   OverhangLogoHD: themesFolder + "wide_banner_HD.png"
'   OverhangLogoSD: themesFolder + "wide_banner_SD.png"
'   GridScreenBackgroundColor: "#000000"
'   BackgroundColor: "#000000"
' }


m.app.player.ads.isRokuAdFrameworkOn = true
m.app.player.useCustomPlayer = true
m.app.facebookDetection = false

if m.app.settings.shortAppName = "tubitv"
  
  'use to change the theme (the theme details are above), ie. headers and background colors
  ' m.app.utils.appManager.setTheme(theme)

  m.app.linearTv.showLinearTv = true
  m.app.cp.showLinearTv = true
  m.app.cp.maxContent = 100

  'limit max content per category to 80 for Roku devices with 256MB of memory
  TwoFiftySixMBModels = {
    "2400X": true  ' LT (2011)
    "2450X": true  ' LT (2012)
    "2500X": true  ' HD
    "3000X": true  ' 2 HD
    "3050X": true  ' 2 XD
    "3100X": true  ' 2 XS
    "3400X": true  ' MHL Stick
    "3420X": true  ' MHL Stick
  }
  if TwoFiftySixMBModels[m.app.utils.deviceInfo.model] = true
    m.app.cp.maxContent = 50
  end if

  ' m.app.utils.log.idsToLog["1GS3CY077172"] = true


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



  'Necessary to change the way strings are created to use as assocArray keys. Prevents bookmarks from working properly.
  'And maybe ad tracking? Basically anywhere that multiple async calls are made before the response for the previous call is returned.
  m.app.utils.sendAsyncRequest = function(url as String, port, name = "" as String, reqType = invalid, isHttps = false, body = invalid, headers = invalid) as Integer
    settings = m.getSettings()
    urlXfer = CreateObject("roURLTransfer")
    'urlXfer.InitClientCertificates()


    'if we send logging for logging API requests, we end up in an infinite loop
    if url <> settings.loggingUrl
      m.log.info(port, "send-async-request-id", urlXfer.GetIdentity().toStr())
      m.log.info(port, "send-async-request-name", name)
      m.log.info(port, "send-async-request-type", reqType)
      m.log.info(port, "send-async-request-url", url)
      m.log.info(port, "send-async-request-body", body)
      m.log.info(port, "send-async-request-headers", headers)
    end if

    url = m.buildUrl(url, name, urlXfer)

    urlXfer.setUrl(url)

    urlXfer.addHeader("User-Agent",  m.deviceInfo.userAgent + " " + m.deviceInfo.model)
    if (port = invalid)
      port = CreateObject("roMessagePort")
    end if
    urlXfer.setPort(port)
    urlXfer.EnableEncodings(true)
    
    if isHttps = true
      urlXfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
      urlXfer.AddHeader("X-Roku-Reserved-Dev-Id", "")
    end if

    'add any passed headers
    if type(headers) = "roAssociativeArray" and headers.count() > 0
      for each headerType in headers
        urlXfer.addHeader(headerType, headers[headerType])
      end for
    end if

    validRequestTypes = {
      POST: true
      GET: true
      DELETE: true
      PUT: true
    }

    if reqType = invalid or validRequestTypes[reqType] = invalid
      reqType = "GET"
    end if
    urlXfer.setRequest(reqType)
    
    if reqType = "POST" or reqType = "PUT"
      if type(body) <> "String"
        body = ""
      end if

      if urlXfer.asyncPostFromString(body) = false
        print reqType; " request failed. "; url
        return 0
      end if
    else
      if urlXfer.asyncGetToString() = false
        print reqType; " request failed. "; url 
        return 0
      end if
    end if

    id = urlXfer.GetIdentity()
    if (port <> invalid)
      'stores the roUrlTransfer object so that any response can be matched with it
      if m.asynchRequests = invalid
        m.asynchRequests = {}
      end if

      m.asynchRequests[id.ToStr()] = urlXfer

      if url <> settings.loggingUrl
        m.log.info(port, "stored-async-request-objects", "async request objects stored = " +  m.asynchRequests.count().toStr())
        print ""
      end if
    end if

    return id
  end function

  m.app.utils.getAsyncResponse = function (msg as Object, id as Integer) as Object
    if type(msg) = "roUrlEvent"
      currId = msg.GetSourceIdentity()

      if id = 0 or id = currId
        out = {
            data : msg.GetString()
            id : currId
            responseCode : msg.GetResponseCode()
            obj: m.asynchRequests[currId.toStr()]
            failReason: msg.GetFailureReason()
          }
        m.asynchRequests.delete(currId.toStr())
        return out
      end if
    end if
    return invalid
  end function


  'put protection for regOutput.fn and regOutput.ln which may not exist in db.
  m.app.registerScreen.submit = function()
    l = len(m.currNumber)
    if(l<10)
      m.showMessage("Phone number too short", "Please enter the 10-digit number of your mobile phone.")
    else
      regOutput = m.showRegistrationInProgress()
      m.isComplete = true

      m.utils.trackEvent({
        trackType: "navigate"
        value: "/home"
        ctx: "/deviceregistration/sms"
        port: GetGlobalAA().app.gridScreen.gridPort
      })
      
      m.canvas.close()
      if(regOutput <> invalid and regOutput.mode = "registered")
        m.utils.trackEvent({
          trackType: "registerSuccess"
          value: "/deviceregistration/sms"
          port: GetGlobalAA().app.gridScreen.gridPort
        })
        if regOutput.fn <> invalid and regOutput.ln <> invalid
          m.showMessage("Thank you", "You are now registered as " + regOutput.fn + " " + regOutput.ln + ".")
        else
          m.showMessage("Thank you", "You are now a registered Tubi TV user.")
        end if
        m.token = invalid
      end if
    end if
  end function



  '-------------------------------------------------------------------'
  '--------------Fix Set of Bugs Found in Roku Crash Logs-------------'
  '-----------------------------12/12/16------------------------------'
  '-------------------------------------------------------------------'

  m.app.cp.getUpdatedUrlForEpisode = Function(episode as Object) as Object
    'get roXml object
    if episode.id <> invalid and (type(episode.id) = "roString" or type(episode.id) = "String")
      episodeFromServer = m.getEpisodeFromServer(episode.id)

      if type(episodeFromServer) = "roXMLList" and episodeFromServer.url.getText().len() > 0
        episode.streams = [{url: episodeFromServer.url.getText()}]
      end if
    end if

    return episode
  end Function




  m.app.player.savePreviouslyViewedUpdate = function(episode, nowPos)
    settings = m.utils.getSettings()
    if m.cp = invalid
      m.cp = GetGlobalAA().app.cp
    end if

    'set the appropriate info based on if it's a movie or episode
    parentId = invalid
    localUpdateId = episode.id
    contentType = "movie"
    userPlaylistsStore = "userPlaylistVideos"
    contentToStore = episode

    if episode.isParentSeries = true
      parentId = episode.parentId
      localUpdateId = parentId
      contentType = "episode"
      userPlaylistsStore = "userPlaylistSeries"
      contentToStore = m.cp.getContentFromLocalPlaylists(parentId, "series")
    end if


    'add the content to our local stores if it doesn't already exist
    if m.cp[userPlaylistsStore][localUpdateId] = invalid
      m.cp[userPlaylistsStore][localUpdateId] = contentToStore
    end if

    stopLoop = false
    'save the nowPos on our local stores so we can reference later
    if episode.isParentSeries = true
      'update the nowPos for the correct episode in the series
      parentInStore = m.cp[userPlaylistsStore][localUpdateId]
      if parentInStore <> invalid and parentInStore.playlist <> invalid and parentInStore.playlist.episodes <> invalid and parentInStore.playlist.episodes.count() > 0

        for i=0 to parentInStore.playlist.episodes.count()-1 step 1
          season = parentInStore.playlist.episodes[i]
          if season.playlist <> invalid and season.playlist.episodes <> invalid and season.playlist.episodes.count() > 0

            for j=0 to season.playlist.episodes.count()-1 step 1
              child = season.playlist.episodes[j]
              if child.id = episode.id
                'update the new previously viewed/history info locally
                child.nowPos = nowPos
                stopLoop = true
                exit for
              end if
            end for
          end if

          if stopLoop = true
            exit for
          end if
        end for
      end if

    else
      'update the nowPos for the current video
      m.cp[userPlaylistsStore][localUpdateId].nowPos = nowPos
    end if
    
    'only do the following if the user is logged in
    authInfo = m.utils.getAuthInfo()
    if authInfo.accessToken <> invalid
    
      'send the newest nowPos to the server. we will listen for the response in the main player port event loop
      addPreviouslyViewedReqId = m.utils.updatePreviouslyViewed(episode.id, parentId, nowPos, "add", contentType, m.playerPort)
      if addPreviouslyViewedReqId <> invalid
        m.previouslyViewedReqIds[addPreviouslyViewedReqId.toStr()] = true
      end if
      
      'updates both video and series
      m.cp[userPlaylistsStore][localUpdateId].isPreviouslyViewed = true

      'add to the previouslyViewed episodes array so it will be included in the category on the gridscreen
      count = 0
      if m.cp.userPlaylists[settings.previouslyViewedRegistry] <> invalid and m.cp.userPlaylists[settings.previouslyViewedRegistry].episodes <> invalid
        for each previousEpisode in m.cp.userPlaylists[settings.previouslyViewedRegistry].episodes
          if previousEpisode <> invalid and previousEpisode.id = localUpdateId
            m.cp.userPlaylists[settings.previouslyViewedRegistry].episodes.delete(count) 'since we want to move it to the front of the list
            exit for
          end if
          count = count + 1
        end for
        m.cp.userPlaylists[settings.previouslyViewedRegistry].episodes.unshift(m.cp[userPlaylistsStore][localUpdateId])
      end if
    end if

  end function




  m.app.episodeListScreen.show = Function(series)
    ' series.playlist = {
    '   name: "someName"
    '   haveAllEpisodes: true
    '   episodes: []   << all the seasons for the series 
    ' }

    if series = invalid or series.playlist = invalid
      print "no series with a playist passed to episodeListScreen.show()"
      return invalid
    end if


    playlist = series.playlist
    landscape = true
    handleItemSource = "episodeListScreen"

    screen = CreateObject("roPosterScreen")
    'if appSettings.isLandscape = true

    thumbRatio = invalid
    if playlist.episodes <> invalid and playlist.episodes.count() > 0
      if playlist.episodes[0].thumbnailRatio <> invalid
        thumbRatio = playlist.episodes[0].thumbnailRatio
      else if playlist.episodes[0].episodes <> invalid and playlist.episodes[0].episodes.count() > 0 and playlist.episodes[0].episodes[0].thumbnailRatio <> invalid
        thumbRatio = playlist.episodes[0].episodes[0].thumbnailRatio
      end if
    end if

    screen.SetListStyle("flat-episodic-16x9")

    'truncate breadcrumb in top right corner to 24 characters. On partner apps it can cover the logo.
    breadCrumbName = Left(playlist.name, 24)
    screen.SetBreadcrumbEnabled(true)
    if m.utils.appName <> "tubitv"
      screen.SetBreadcrumbText(breadCrumbName, "")
    else
      screen.SetBreadcrumbText(playlist.name, "")
    end if

    screen.SetMessagePort(m.episodePort)
    isTwoLevel = false

    child = m.cp.getChildItem(playlist,0)
    if(child = invalid)
      return 0
    end if

    'set the content on to the screen - also gets all the series season/episode meta data
    if child.playlist <> invalid
      m.set2Level(screen, invalid, series)
      isTwoLevel = true
    else 'this should not happen if series are given seasons (all series should have at least 1 season)
      list = []
      for each item in playlist.episodes
        item.ShortDescriptionLine2 = item.description
        item.ShortDescriptionLine1 = item.title
        item.Categories = []
        list.Push(item)
        screen.SetContentList(list)
      end for
    end if
    screen.setFocusToFilterBanner(false)
    screen.Show()

    m.utils.trackEvent({
      trackType: "pageLoad"
      value: "/series/episodelist/" + series.id
      port: m.episodePort
    })

    listIndex = 0
    itemIndex = 0


    ' todo: eliminate some redundancy: make this happen between "setup" and "doEventHandling"
    ' if doing autoplay
    if m.autoplayItem1 <> invalid
      if m.autoplayItem2 <> invalid
        listIndex = m.autoplayItem1
        itemIndex =  m.autoplayItem2
        isTwoLevel = true
        m.set2Level(screen, listIndex, series)
        subList = m.cp.getChildItem(playlist, listIndex)
        m.autoplayItem1 = invalid
        m.autoplayItem2 = invalid
        itemIndex = GetGlobalAA().app.handleItemPicked(subList.playlist, listIndex, itemIndex, handleItemSource)
      else
        listIndex = invalid
        itemIndex =  m.autoplayItem1
        m.autoplayItem1 = invalid
        itemIndex = GetGlobalAA().app.handleItemPicked(playlist, listIndex, itemIndex, handleItemSource)
      end if

      if listIndex <> invalid
        screen.setFocusedList(listIndex)
      end if
      screen.SetFocusedListItem(itemIndex)
      bypassFocusList = true
    else
      bypassFocusList = false
    end if

    while true
      msg = wait(0, m.episodePort)
      if type(msg) = "roUrlEvent"
        m.utils.getAsyncResponse(msg, 0)

      else if type(msg) = "roPosterScreenEvent"
        if msg.isScreenClosed()
          return -1
        else if msg.isListFocused() 'user moved to a new season
          isTwoLevel = true
          listIndex = msg.getIndex()

          m.set2Level(screen, listIndex, series)

        else if msg.isListItemSelected()
          itemIndex = msg.getIndex()
          if(isTwoLevel)
            subList = m.cp.getChildItem(playlist, listIndex)
            newItemIndex = GetGlobalAA().app.handleItemPicked(subList.playlist, listIndex, itemIndex, handleItemSource)
            
            activeContent = m.getActiveContent(series, newItemIndex, listIndex)
            itemIndex = activeContent.episode
            listIndex = activeContent.season

          else
            itemIndex = GetGlobalAA().app.handleItemPicked(playlist, listIndex, itemIndex, handleItemSource)
          end if
          screen.setFocusedList(listIndex)
          screen.SetFocusedListItem(itemIndex)
        end if
      end if
    end while
  End Function



  m.app.cp.getContentFromLocalPlaylists = Function(contentId, contentType)
    if contentType <> "series" and contentType <> "video"
      return invalid
    end if

    for each playlist in m.playlists
      for each content in playlist.episodes
        if content <> invalid and content.id = contentId
          
          if contentType = "series" and content["type"] = "level"
            return content
          
          else if contentType = "video" and content["type"] = "video"
            return content

          end if
        end if
      end for
    end for
    
    return invalid
  End Function



  m.app.handleItemPicked = Function(playlist, listIndex, itemIndex, source)
    settings = m.utils.getSettings()
    episode = m.cp.getEpisodeInPlaylist(playlist, itemIndex)

    if episode.type = "tubiLogin" or episode.type = "bookmarks"
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
        else
          m.episodeListScreen.autoPlay(episode, m.cp.autoplayData.path[2], m.cp.autoplayData.path[3])
          m.cp.autoplayData = invalid
        end if
      end if
    end if
    return itemIndex
  End Function



  m.app.gridScreen.showToolsRow = Function (rokuGridScreen, cp)
    settings = m.utils.getSettings()
    toolsName = "Tools"

    'Populate Tools Category for Tubi
    if settings.registerWithTubi = true

      authInfo = m.utils.getAuthInfo() 'should always return at least an empty roAssocArray {}
      accessToken = authInfo.accessToken
      loggedInDesc = "You are now signed in to Tubi TV. Click here to sign out."
      if authInfo.fn <> invalid and authInfo.ln <> invalid
        loggedInDesc = "You are signed in as " + authInfo.fn + " " + authInfo.ln + "." + chr(10) + " Click here to sign out from Tubi TV."
      end if

      if (accessToken = invalid)
        item1 = {
          type: "tubiLogin"
          sdposterurl: "http://cdn.adrise.com/hotpatches/roku/login-portraitSD.jpg"
          hdposterurl: "http://cdn.adrise.com/hotpatches/roku/login-portraitHD.jpg"
          title: "Sign up"
          description: "Click here to register with Tubi TV."
          }
        m.isLogoutButtonShown = false
      else
        item1 = {
          type: "tubiLogin"
          sdposterurl: "http://cdn.adrise.com/hotpatches/roku/logout-portraitSD.jpg"
          hdposterurl: "http://cdn.adrise.com/hotpatches/roku/logout-portraitHD.jpg"
          title: "Sign out"
          description: loggedInDesc
          }
        m.isLogoutButtonShown = true
      endif

      'add search "button" to top row
      searchItem = {
        type: "search"
        sdposterurl: "http://cdn.adrise.com/hotpatches/roku/find-portraitSD.jpg"
        hdposterurl: "http://cdn.adrise.com/hotpatches/roku/find-portraitHD.jpg"
        title: "Search " + settings.appName
        description: "Go to search screen."
      }

      bookmarkItem = {
        type: "bookmarks"
        sdposterurl: "http://cdn.adrise.com/hotpatches/roku/queue-portraitSD.jpg"
        hdposterurl: "http://cdn.adrise.com/hotpatches/roku/queue-portraitHD.jpg"
        title: "Log In For Queue and View History Access"
        description: "Now you can access all the videos in your queue and your view history from any Tubi TV device!"
      }

      policyItem = {
        type: "policy"
        sdposterurl: "http://cdn.adrise.com/hotpatches/roku/policy-portraitSD.jpg"
        hdposterurl: "http://cdn.adrise.com/hotpatches/roku/policy-portraitHD.jpg"
        title: "Tubi TV Privacy Policy"
        description: "Read Tubi TV's Privacy Policy"          
      }

      list = [item1]

      if settings.showSearch = true
        list.push(searchItem)
      end if

      'add bookmarks "button" to top row if appropriate
      if (accessToken = invalid)
        list.push(bookmarkItem)
      end if

      list.push(policyItem)

    'pupulate Tools category for non tubi if necessary
    else
      isSubscribed = m.utils.getSubscribed()

      item1 = {
        type: "vezo"
        sdposterurl: "http://cdn.adrise.com/hotpatches/roku/watch-adfree-portrait2.jpg"
        hdposterurl: "http://cdn.adrise.com/hotpatches/roku/watch-adfree-portrait2.jpg"
        title: "Want to skip ads?"
        description: "Click here to learn more"
        }
      if isSubscribed = true
        item1.title = "You are subscribed to " + settings.appName
        item1.description = "Visit http://vezo.tv to manage your subscriptions"
      end if

      item2 = {
        type: "vezo"
        sdposterurl: "http://cdn.adrise.com/hotpatches/roku/help-portrait.jpg"
        hdposterurl: "http://cdn.adrise.com/hotpatches/roku/help-portrait.jpg"
        title: "Support"
        description: "Please visit http://vezo.tv or email support@vezo.tv"
        }
      list = [item1, item2]
    end if

    if list <> invalid
      playlist = {
        episodes: list
        name: toolsName
      }
    end if

    'if the tools/register row hasn't yet been prepended to the playlists array, prepend it otherwise, overwrite it
    '(in case of previous logout or login)
    if cp.getPlaylist(0) <> invalid and cp.getPlaylist(0).name <> toolsName
      cp.prependPlaylistToPlaylists(playlist)
    else
      if playlist <> invalid and cp.playlists <> invalid
        cp.playlists.shift()
        cp.prependPlaylistToPlaylists(playlist)
      end if
    end if 
  End Function



  '-------------------------------------------------------------------'
  '------------//Fix Set of Bugs Found in Roku Crash Logs-------------'
  '---------------------------//12/12/16------------------------------'
  '-------------------------------------------------------------------'





  '-------------------------------------------------------------------'
  '--------------Fix Set of Bugs Found in Roku Crash Logs-------------'
  '-----------------------------12/19/16------------------------------'
  '-------------------------------------------------------------------'


  m.app.player.ads.getCuePoints = function(episode)
    settings = m.utils.getSettings()

    'set default values for the pub id and episode id
    pubId = settings.pubid
    epId = "0"
    'set the url to get the cuepoints


    if episode <> invalid
      if type(episode.pubId) = "String" or type(episode.pubId) = "roString"
        pubId = episode.pubId
      end if

      if type(episode.id) = "String" or type(episode.id) = "roString"
        epId = episode.id
      end if
    end if

    cuepointUrl = settings.cuepointsUrlBase + "?format=json&pubid=" + pubId + "&platform=roku&cid=" + epId

    'get the cuepoints synchronously
    cuepointsJson = m.utils.getTextFile(cuepointUrl, "getCuePoints")

    'parse the returned JSON to a Brightscript object - should return an array
    cuepoints = ParseJson(cuepointsJson)

    if type(cuepoints) = "roArray" and cuepoints.count() > 0
      m.midrolls = cuepoints
      return cuepoints
    end if

    'return invalid by default
    return invalid
  end function


  m.app.cp.getAllPlaylistsCount = function()
    if m.playlists <> invalid
      return m.playlists.Count()
    end if
    return 0
  end function


  m.app.detailScreen.show = function(episode, playlist, itemIndex)
    maxIndex = m.cp.getPlaylistLength(playlist) - 1

    screen = CreateObject("roSpringboardScreen")
    screen.SetBreadcrumbText("", playlist.name)
    screen.SetDescriptionStyle("movie")

    if episode.thumbnailRatio = invalid
       screen.SetPosterStyle(m.settings.SetPosterStyle)
    else
      if episode.thumbnailRatio > 1
        posterStyle = "rounded-rect-16x9-generic"  'landscape
      else
        posterStyle = "multiple-portrait-generic"  'portrait
      end if
      screen.SetPosterStyle(posterStyle)
    end if

    screen.SetStaticRatingEnabled(false)
    screen.SetMessagePort(m.detailsPort)

    showRentButton = (m.settings.allowRentals=true)
    m.update(screen, episode, showRentButton, m.detailsPort)

    screen.Show()

    settings = m.utils.getSettings()
    while true
      msg = wait(0, m.detailsPort)

      'prevents build up of roUrlObjects from user tracking events
      'do not delete - prevents memory leaks even though we don't use respObj anywhere
      if type(msg) = "roUrlEvent"
        respObj = m.utils.getAsyncResponse(msg, 0)
        'we know we have a response from adding a bookmark - so update the bookmarksServerId where necessary
        if m.addBookmarkReqIds[respObj.id.toStr()] <> invalid
          if respObj.data <> invalid and respObj.data.len() > 0
            addBookmarkResponse = parseJson(respObj.data)

            if addBookmarkResponse.content_type <> invalid

              if addBookmarkResponse.content_type = "series"
                m.cp.userPlaylistSeries[addBookmarkResponse.content_id.toStr()].bookmarksServerId = addBookmarkResponse.id
              else if addBookmarkResponse.content_type = "movie"
                m.cp.userPlaylistVideos[addBookmarkResponse.content_id.toStr()].bookmarksServerId = addBookmarkResponse.id
              end if

            end if
          end if
        end if
      end if

      if type(msg) = "roSpringboardScreenEvent"

        if msg.isScreenClosed()

          exit while
        else if msg.isButtonPressed()
          button = msg.GetIndex()
          episode.PlayStart = 0
          if button = 1 or button = 2 'user wants to play or resume playing

            'set the state for the content as being resumed or playing from start - default is false
            'this will be used to determine if ads should be called on resume
            episode.isResumed = false

            'Check for registration walls
            watchAllowed = true
            if episode.regWallType <> invalid
              userInfo = m.utils.getUserData()
              if userInfo = invalid or userInfo.fn = invalid
                watchAllowed = false
                regWallShow = GetGlobalAA().app.registerScreen.show
                regWallShow(episode.regWallType)
                userInfo = m.utils.getUserData()
                if userInfo <> invalid and userInfo.fn <> invalid
                  watchAllowed = true
                end if
              end if
            end if

            if (watchAllowed = true) 'only false if there is a reg wall in effect
              play = true

              if play
                if button = 2 ' resume playing
                  'set the state of the episode to be resumed since resume play was selected
                  episode.isResumed = true

                  'get the start time from the local stores that have the previouslyViewed/history info
                  'episode.PlayStart is what the Roku player looks at to determine where to start the video
                  nowPos = m.cp.getNowPosFromLocalStore(episode)
                  if nowPos <> invalid and nowPos > 5
                    episode.PlayStart = nowPos
                  end if
                end if

                ' play till end of playlist
                while true
                  ret = m.player.playVideo(episode)

                  'move the details page to the next item in the playlist
                  if (ret <> "CLOSED" and itemIndex < maxIndex)

                    itemIndex = itemIndex + 1
                    episode = m.cp.getEpisodeInPlaylist(playlist, itemIndex)
                    episode.PlayStart = 0

                    'check if the newly advanced content is also a video, if not go back to the previous one
                    if (episode.type <> "video")
                      itemIndex = itemIndex - 1
                      episode = m.cp.getEpisodeInPlaylist(playlist, itemIndex)
                      exit while
                    end if
                    m.update(screen, episode, showRentButton, m.detailsPort)
                  else
                    exit while
                  end if
                end while
                m.updateButtons(screen, episode, showRentButton)
              end if
            end if
          else if button = 3
            m.showRentDialog(episode)
          else if button = 4
            m.showCaptionsDialog(episode)
          else if button = 5 'user wants to bookmark the page
            isSaved = m.saveBookmark(episode, m.detailsPort)
            if isSaved = true
              m.updateButtons(screen, episode, showRentButton)
            end if
          else if button = 6 'user wants to remove the bookmark for this content
            isRemoved = m.removeBookmarkOrPreviouslyViewed(episode, settings.bookmarkRegistry, m.detailsPort)
            if isRemoved = true
              m.updateButtons(screen, episode, showRentButton)
            end if
          else if button = 7 'user wants to remove the content from previously viewed
            isRemoved = m.removeBookmarkOrPreviouslyViewed(episode, settings.previouslyViewedRegistry, m.detailsPort)
            if isRemoved = true
              m.updateButtons(screen, episode, showRentButton)
            end if
          end if

        else if msg.isRemoteKeyPressed()
          button = msg.GetIndex()
          if button = 4 or button = 5
            newItemIndex = m.moveForwardBackward(itemIndex, maxIndex, (button = 5))
            newEpisode = m.cp.getEpisodeInPlaylist(playlist, newItemIndex)
            if newEpisode <> invalid and newEpisode.type = "video"
              episode = newEpisode
              itemIndex = newItemIndex
              m.update(screen, episode, showRentButton, m.detailsPort)
            end if
          else
            ' print msg
          end if
        end if
      else
      ' print "test"
      end if

    end while
    return itemIndex
  end function



  '-------------------------------------------------------------------'
  '------------//Fix Set of Bugs Found in Roku Crash Logs-------------'
  '---------------------------//12/19/16------------------------------'
  '-------------------------------------------------------------------'



  'Retry for first calls to get content ids for continue watching and queue categories
  m.app.cp.getBookmarksAndPreviouslyViewedFromServer = function()
    settings = m.utils.getSettings()
    getBookmarksPort = CreateObject("roMessagePort")

    authInfo = m.utils.getAuthInfo()  'from memory

    'if the user is not logged in (aka doesn't have an accessToken in local memory),
    'then don't get any bookmarks or previously viewed
    if authInfo.accessToken = invalid
      return invalid
    end if
    
    basicUserPlaylistData = {
      bookmarks: invalid
      previouslyViewed: invalid
    }

    authInfo = m.utils.checkIfAuthExpired(authInfo)
    headers = m.utils.getAuthHeaders(authInfo.accessToken)

    'get bookmarks from server
    bookmarksId = m.utils.sendAsyncRequest(settings.bookmarksUrlNoPage, getBookmarksPort, "getAllBookmarks", "GET", true, invalid, headers)

    'get previously viewed from server
    previouslyViewedId = m.utils.sendAsyncRequest(settings.previouslyViewedUrlNoPage, getBookmarksPort, "getAllPreviouslyViewed", "GET", true, invalid, headers)

    bookmarkContinue = false
    previousContinue = false
    bookmarkRetries = 0
    previousRetries = 0

    while true
      msg = wait(0, getBookmarksPort)
      if type(msg) = "roUrlEvent"
        response = m.utils.getAsyncResponse(msg, 0)

        if response.id = bookmarksId
          basicBookmarks = invalid
          print "Bookmarks "; bookmarkRetries; " : "; response
          if response.responseCode >= 200 and response.responseCode < 300
            if response.data <> invalid and response.data <> ""
              basicBookmarks = response.data
            end if
            basicUserPlaylistData.bookmarks = basicBookmarks
            bookmarkContinue = true
            m.handleGetUserPlaylists(settings.bookmarkRegistry, response.data)

          else
            if bookmarkRetries >= 2 ' means max of 3 total attempts, one regular and 2 retries
              bookmarkContinue = true
            else
              bookmarksId = m.utils.sendAsyncRequest(settings.bookmarksUrlNoPage, getBookmarksPort, "getAllBookmarks", "GET", true, invalid, headers)
              bookmarkRetries = bookmarkRetries + 1
            end if
          end if

        else if response.id = previouslyViewedId
          basicPreviouslyViewed = invalid
          print "Previous "; previousRetries; " : " response
          if response.responseCode >= 200 and response.responseCode < 300
            if response.data <> invalid and response.data <> ""
              basicPreviouslyViewed = response.data
            end if
            basicUserPlaylistData.previouslyViewed = basicPreviouslyViewed
            previousContinue = true
            m.handleGetUserPlaylists(settings.previouslyViewedRegistry, response.data)

          else
            if previousRetries >= 2 ' means max of 3 total attempts, one regular and 2 retries
              previousContinue = true
            else
              previouslyViewedId = m.utils.sendAsyncRequest(settings.previouslyViewedUrlNoPage, getBookmarksPort, "getAllPreviouslyViewed", "GET", true, invalid, headers)
              previousRetries = previousRetries + 1
            end if
          end if
        end if
      end if

      if (bookmarkContinue = true and previousContinue = true)
        exit while
      end if

    end while

    return basicUserPlaylistData
  end function



end if