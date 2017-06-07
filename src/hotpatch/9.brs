print "Hot Patch 9"

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



m.app.player.ads.isRokuAdFrameworkOn = false

if m.app.settings.shortAppName = "tubitv"
  
  'use to change the theme (the theme details are above), ie. headers and background colors
  ' m.app.utils.appManager.setTheme(theme)

  'remove rental option for tubitv
  m.app.settings.allowRentals = false

  m.app.linearTv.showLinearTv = true
  m.app.cp.showLinearTv = true

  m.app.linearTv.sdposterurl = "http://cdn.adrise.com/hotpatches/roku/LinearTV-beta-SD.jpg"
  m.app.linearTv.hdposterurl = "http://cdn.adrise.com/hotpatches/roku/LinearTV-beta-HD.jpg"

  linearTvUrl = "http://cms.adrise.com/v3/livetv?cid=roku&platform=roku&id=tubitv"
  linearScheduleJson = m.app.utils.getTextFile(linearTvUrl, "getLinearSchedule")
  m.app.linearTv.newLinearEpisodes = parseJson(linearScheduleJson)
  for each episode in m.app.linearTV.newLinearEpisodes
    episode.id = episode.id.ToStr()
  end for

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

  m.app.linearTv.linearEpisodes.Append(m.app.linearTv.newLinearEpisodes)

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
end if

'make linear tv more fault resistant by adding an additional check in case something is wrong with a content
m.app.linearTv.getCurrentEpisode = function(linearPlaylist)
  episodeEndpoints = []
  playlistDuration = 0
  count = 0
  for each episode in linearPlaylist.episodes
    if episode.length <> invalid
      playlistDuration = playlistDuration + episode.length
      episodeEndpoints.push(playlistDuration)
    else
      'remove the episode from list of episodes if it has no length (usually means there is no episode info at all)
      'this maintains the syncs between number of episodes and number of endpoints
      linearPlaylist.episodes.Delete(count)
    end if
    count = count + 1
  end for

  print "linearPlaylist.episodes "; linearPlaylist.episodes[0]

  if m.now = invalid
    m.now = CreateObject("roDateTime")
  end if
  m.now.Mark()
  m.hour = m.now.GetHours()
  m.minute = m.now.GetMinutes()
  m.seconds = m.now.GetSeconds()
  timeInSeconds = m.hour * 3600 + m.minute * 60 + m.seconds

  if playlistDuration > 0
    percentPositionInPlaylist = (timeInSeconds / playlistDuration) - Fix(timeInSeconds / playlistDuration)
    positionInPlaylist = Fix(percentPositionInPlaylist * playlistDuration) 'in seconds

    count = 0
    for each endpoint in episodeEndpoints
      if positionInPlaylist < endpoint
        if linearPlaylist.episodes[count].length <> invalid
          startTime = linearPlaylist.episodes[count].length - (endpoint - positionInPlaylist)
          return {
            initialEpisodeIndex: count
            startTime: startTime
          }
        end if
      end if
      count = count + 1
    end for
  end if
  
  'default return if something goes wrong'
  return {
    initialEpisodeIndex: invalid
    startTime: invalid
  }
end function



'update the getAllEpisodesForPlaylistFromServer call to work with updated api
m.app.cp.getChildItem = function(playlist as Object, itemIndex as Integer) as Object
  if playlist.haveAllEpisodes = invalid
    m.getAllEpisodesForPlaylistFromServer(playlist, "gridscreen")
  end if

  if itemIndex < playlist.episodes.count()
    episode = playlist.episodes[itemIndex]
    return episode
  else
    return invalid
  end if
end function
m.app.cp.getEpisodeInPlaylist = m.app.cp.getChildItem


'update the getPlaylistFromXmlObj call to work with updated api'
m.app.cp.getAllPlaylistsFromServer = function()
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

'update to work with updated api (landscape gridscreen images)'
m.app.cp.getPlaylistFromXmlObj = function(obj, imageSize, depth, parent, source)
  title = ValidStr(obj.title.getText())
  videosIdString = ""
  items = []
  videos = {}
  bookmarksPrelim = {}
  previousPrelim = {}
  children = obj.children.getChildElements()
  count = 0
  
  'get saved Bookmarks and Recently Viewed
  userPlaylistContent = m.getSavedUserContentFromMemory()

  settings = m.utils.getSettings()
  ' if settings.maxContent = invalid
  '   settings.maxContent = 75
  ' end if
  
  for each child in children  'child = level or video for a row/category/playlist
    ' if count >= settings.maxContent
    '   exit for
    ' end if
    
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

    
    id = child.id.getText()

    if child.getName() = "video"
      item = {
        type : "video"
        title: child.title.getText()
        id: id
        adrise_contentId: id
        position: count
      }

      ' 'if there is a parent id, it means we are at the season or episode level
      if parent <> invalid
        item.isParentSeries = true
        item.parent = parent
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
            m.userPlaylists.bookmarks.videosPrelim[id] = item
            ' m.userPlaylists.bookmarks.videosPrelim[id].position = m.bookmarksCount

            'item is updated by reference later when it gets pushed through getAllEpisodesForPlaylistFromServer
            'during the normal course of loading the main gridscreen
            m.userPlaylists.bookmarks.episodes.push(item)
            'add the id to the videosIdString
            m.userPlaylists.bookmarks.videosIdString = m.userPlaylists.bookmarks.videosIdString + "," + id
          end if
        end if

        'the id matches and it's a video so set up the preliminary hash for previously viewed
        if userPlaylistContent <> invalid and userPlaylistContent.savedPrevious[prependedId] <> invalid
          'only add the content to the previously viewed playlist if it hasn't already been added (in case the content exists in more than one category)
          if m.userPlaylists.previous.videosPrelim[id] = invalid
            m.userPlaylists.previous.videosPrelim[id] = item
            
            'item is updated by reference later when it gets pushed through getAllEpisodesForPlaylistFromServer
            'during the normal course of loading the main gridscreen            
            m.userPlaylists.previous.episodes.push(item)
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
            m.userPlaylists.bookmarks.episodes.push(item)
            m.userPlaylists.bookmarks.seriesPrelim[id] = true 'only used to prevent duplicates
          end if
        end if

        'the id matches and it's a series so set up the preliminary hash for previously viewed
        if userPlaylistContent <> invalid and userPlaylistContent.savedPrevious[prependedId] <> invalid
          if m.userPlaylists.previous.seriesPrelim[id] = invalid
            m.userPlaylists.previous.episodes.push(item)
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
    ' parent: parent 'will be invalid for top level objects (videos/series)
  }
end function

'update to work with updated api (landscape gridscreen images)'
m.app.cp.getAllEpisodesForPlaylistFromServer = function(playlist, source)
  settings = m.utils.getSettings()

  if playlist.videosIdString = invalid or playlist.videosIdString = ""
    return invalid
  end if

  'remove the leading comma if necessary (for bookmarks and recently viewed)
  if Left(playlist.videosIdString, 1) = ","
    playlist.videosIdString = playlist.videosIdString.mid(1)
  end if

  xml = m.utils.getXml(m.urls.getVideos + playlist.videosIdString, "getVideos_v2")

  defaultVideoPath = invalid
  defaultStaticPath = invalid

  splitter = CreateObject("roRegex", ",", "")
  if xml <> invalid and xml.video <> invalid
    for each videoDetails in xml.video
      xmlId =  videoDetails.id.getText()

      if xmlId <> invalid and xmlId <> "" and playlist.videosPrelim[xmlId] <> invalid
        if source = "gridscreen"
          if settings.GridStyle = "Flat-16x9" 'setting images for landscape styled grid screen
            if videoDetails.thumbnailUrl <> invalid
              thumbUrl = videoDetails.thumbnailUrl.getText()
            end if
            if videoDetails.thumbnailRatio <> invalid
              playlist.videosPrelim[xmlId].thumbnailRatio = val(videoDetails.thumbnailRatio.getText())
            end if
          else 'setting images for portait (Flat-Movie) styled grid screen and one funny app that uses 'two-row-flat-landscape-custom' style
            if videoDetails.posterartUrl <> invalid
              thumbUrl = videoDetails.posterartUrl.getText()
            end if
            if videoDetails.posterartRatio <> invalid
              playlist.videosPrelim[xmlId].thumbnailRatio = val(videoDetails.posterartRatio.getText())
            end if
          end if
        else if source = "episode" 'playlist is for episode list screen
          if videoDetails.thumbnailUrl <> invalid
            thumbUrl = videoDetails.thumbnailUrl.getText()
          end if
          if videoDetails.thumbnailRatio <> invalid
            playlist.videosPrelim[xmlId].thumbnailRatio = val(videoDetails.thumbnailRatio.getText())
          end if
        else if source = "search" 'playlist is for search screen
          if videoDetails.posterartUrl <> invalid
            thumbUrl = videoDetails.posterartUrl.getText()
          end if
          if videoDetails.posterartRatio <> invalid
            playlist.videosPrelim[xmlId].thumbnailRatio = val(videoDetails.posterartRatio.getText())
          end if            
        end if


        'remove when landscape is in effect
        ' thumbUrl = videoDetails.thumbnailUrl.getText()

        if defaultStaticPath <> invalid and not _isUrl(thumbUrl)
          thumbUrl = defaultStaticPath + thumbUrl
          playlist.videosPrelim[xmlId].defaultStaticPath = defaultStaticPath
        end if
        playlist.videosPrelim[xmlId].sdPosterURL = thumbUrl
        playlist.videosPrelim[xmlId].hdPosterURL = thumbUrl
        playlist.videosPrelim[xmlId].description = ValidStr(videoDetails.description.getText())

        playlist.videosPrelim[xmlId].longDescription = playlist.videosPrelim[xmlId].description
        playlist.videosPrelim[xmlId].shortDescriptionLine1 = playlist.videosPrelim[xmlId].title
        ' playlist.videosPrelim[xmlId].shortDescriptionLine2 = playlist.videosPrelim[xmlId].description
        url = videoDetails.url.getText()
        if defaultVideoPath <> invalid and not _isUrl(url)
          url = defaultVideoPath + url
        end if

        playlist.videosPrelim[xmlId].url = url

        if videoDetails.rating <> invalid
          playlist.videosPrelim[xmlId].rating = videoDetails.rating.getText()
        end if
        if videoDetails.language <> invalid
          playlist.videosPrelim[xmlId].language = videoDetails.language.getText()
        end if
        if videoDetails.country <> invalid
          playlist.videosPrelim[xmlId].country = videoDetails.country.getText()
        end if
        if videoDetails.director <> invalid
          playlist.videosPrelim[xmlId].director = videoDetails.director.getText()
        end if
        if videoDetails.starring <> invalid
          playlist.videosPrelim[xmlId].actors = splitter.Split(videoDetails.starring.getText())
        end if
        
        'remove when landscape is in effect
        ' if videoDetails.thumbnailRatio <> invalid
        '   playlist.videosPrelim[xmlId].thumbnailRatio = val(videoDetails.thumbnailRatio.getText())
        ' end if

        if videoDetails.publisherId <> invalid
          playlist.videosPrelim[xmlId].pubId = videoDetails.publisherId.getText()
        end if
        if videoDetails.releaseDate <> invalid
          playlist.videosPrelim[xmlId].releaseDate = videoDetails.year.getText()
        end if
        if videoDetails.rentalPrice <> invalid
          playlist.videosPrelim[xmlId].rentalPrice = ValidStr(videoDetails.rentalPrice.getText())
          if playlist.videosPrelim[xmlId].rentalPrice = ""
            playlist.videosPrelim[xmlId].rentalPrice = invalid
          end if
        end if

        playlist.videosPrelim[xmlId].length = Int(StrToI(ValidStr(videoDetails.duration.getText())))

        if (playlist.videosPrelim[xmlId].url.instr(1,".m3u8") > 1)
          playlist.videosPrelim[xmlId].streamFormat = "hls"
          playlist.videosPrelim[xmlId].streams = [{url: playlist.videosPrelim[xmlId].url}]
        else if (playlist.videosPrelim[xmlId].url.instr(1,".mp4") > 1)
          playlist.videosPrelim[xmlId].streamFormat = "mp4"
          playlist.videosPrelim[xmlId].streams = [{url: playlist.videosPrelim[xmlId].url}]
        end if

        subtitles = {
          languages: []
        }

        for each subtitle in videoDetails.subtitles.subtitle
          newSubtitle = {
            name: ValidStr(subtitle.language.getText())
            url: ValidStr(subtitle.url.getText())
          }
          if ValidStr(subtitle.default.getText()) = "1"
            subtitles.default = newSubtitle.name
            playlist.videosPrelim[xmlId].subtitleUrl = newSubtitle.url
          end if
          subtitles.languages.Push(newSubtitle)
        end for

        if subtitles.languages.count() <> 0
          playlist.videosPrelim[xmlId].subtitles = subtitles
        end if

        streams = []
        for each rendition in videoDetails.renditions.rendition
          if (rendition.video_container.getText() <> invalid)
            playlist.videosPrelim[xmlId].streamFormat = LCase(ValidStr(rendition.video_container.getText()))
          end if

          newStream = {
            url:  ValidStr(rendition.url.getText())
          }
          bitrate = StrToI(ValidStr(rendition.total_bitrate_kbs.getText()))
          if (bitrate > 0)
            newStream.bitrate = bitrate
          end if
          height = StrToI(ValidStr(rendition.video_height.getText()))
          ' m.isHD and
          if height > 480
            if height > 720
              playlist.videosPrelim[xmlId].fullHD = true
            end if
            playlist.videosPrelim[xmlId].isHD = true
            playlist.videosPrelim[xmlId].hdBranded = true
            newStream.quality = true
          end if
          streams.Push(newStream)
        end for
        if streams.count() <> 0
          playlist.videosPrelim[xmlId].streams = streams
        end if

        'Get Any Regwall Info as Defined in Hotpatch'
        if m.isRegWall = true
          idAsInteger = val(xmlId)
          if m.regWallContent[idAsInteger] <> invalid
            playlist.videosPrelim[xmlId].regWallType = m.regWallContent[idAsInteger]
          end if
        end if

        'add the video to the appropriate place in the episodes array
        playlist.episodes[playlist.videosPrelim[xmlId].position] = playlist.videosPrelim[xmlId]
      end if
    end for

    'delete the videosPrelim AssocArray from playlist AssocArray since it is no longer needed
    if playlist.videosPrelim <> invalid
      playlist.delete("videosPrelim")
    end if

    'delete the seriesPrelim AssocArray from the bookmarks and previously viewed objects since it is no longer needed'
    if playlist.seriesPrelim <> invalid
      playlist.delete("seriesPrelim")
    end if

    playlist.haveAllEpisodes = true
  end if
end function

'update so getAllEpisodesForPlaylistFromServer works after api change
m.app.episodeListScreen.show = function(playlist)
  if playlist.episodes[0].playlist.haveAllEpisodes <> true
    m.cp.getAllEpisodesForPlaylistFromServer(playlist, "episode")
  end if

  landscape = true

  port = CreateObject("roMessagePort")
  screen = CreateObject("roPosterScreen")
  'if appSettings.isLandscape = true

  thumbRatio = invalid

  if playlist.episodes.count() > 0
    print "EPISODE!"
    print playlist.episodes[0].playlist.episodes[0]
    if playlist.episodes[0].thumbnailRatio <> invalid
      thumbRatio = playlist.episodes[0].thumbnailRatio
    else if playlist.episodes[0].episodes <> invalid and playlist.episodes[0].episodes.count() > 0 and playlist.episodes[0].episodes[0].thumbnailRatio <> invalid
      thumbRatio = playlist.episodes[0].episodes[0].thumbnailRatio
    end if
  end if

  if thumbRatio = invalid or thumbRatio > 1
    screen.SetListStyle("flat-episodic-16x9")
  else
    screen.SetListStyle("flat-episodic-16x9")
  end if

  'truncate breadcrumb in top right corner to 24 characters. On partner apps it can cover the logo.
  breadCrumbName = Left(playlist.name, 24)
  screen.SetBreadcrumbEnabled(true)
  if m.utils.appName <> "tubitv"
    screen.SetBreadcrumbText(breadCrumbName, "")
  else
    screen.SetBreadcrumbText(playlist.name, "")
  end if

  screen.SetMessagePort(port)
  isTwoLevel = false

  child = m.cp.getChildItem(playlist,0)
  if(child = invalid)
    return 0
  end if
  if child.playlist <> invalid
    m.set2Level(screen, 0, playlist)
    isTwoLevel = true
  else 'this should not happen if series are given seasons (all series should have at least 1 season)
    list = []
    for each item in playlist.episodes
      d = m.utils.getSavedContentData(item.id)
      if(d<>invalid and d.pos>30)
        item.BookmarkPosition = d.pos
      end if
      item.ShortDescriptionLine2 = item.description
      item.ShortDescriptionLine1 = item.title
      item.Categories = []
      list.Push(item)
      screen.SetContentList(list)
    end for
  end if
  screen.setFocusToFilterBanner(false)
  screen.Show()

  listIndex = 0
  itemIndex = 0


  ' todo: eliminate some redundancy: make this happen between "setup" and "doEventHandling"
  ' if doing autoplay
  if m.autoplayItem1 <> invalid
    if m.autoplayItem2 <> invalid
      listIndex = m.autoplayItem1
      itemIndex =  m.autoplayItem2
      isTwoLevel = true
      m.set2Level(screen, listIndex, playlist)
      subList = m.cp.getChildItem(playlist, listIndex)
      episode = m.cp.getChildItem(subList.playlist, itemIndex)
      m.autoplayItem1 = invalid
      m.autoplayItem2 = invalid
      itemIndex = GetGlobalAA().app.handleItemPicked(subList.playlist, itemIndex)
    else
      listIndex = invalid
      itemIndex =  m.autoplayItem1
      episode = m.cp.getChildItem(playlist, itemIndex)
      m.autoplayItem1 = invalid
      itemIndex = GetGlobalAA().app.handleItemPicked(playlist, itemIndex)
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
    msg = wait(0, port)
    m.utils.globalMessageHandler(msg)
    if type(msg) = "roPosterScreenEvent"
      if msg.isScreenClosed()
        return -1
      else if msg.isListFocused() 'user moved to a new season
        isTwoLevel = true
        listIndex = msg.getIndex()

        if playlist.episodes[listIndex].playlist.haveAllEpisodes <> true
          m.cp.getAllEpisodesForPlaylistFromServer(playlist.episodes[listIndex].playlist, "episode")
        end if
        eps = playlist.episodes[listIndex].playlist.episodes
        if eps <> invalid
          screen.SetContentList(eps)
          activeEpisode = m.getActiveEpisode(eps)
          if activeEpisode = -1
            activeEpisode = 0
          else if activeEpisode >= playlist.episodes.[listIndex].playlist.episodes.count()
            activeEpisode = 0
          end if
          screen.SetFocusedListItem(activeEpisode)
        end if
     '    if bypassFocusList = true
        '   bypassFocusList = false
      '     activeEpisode = m.getActiveEpisode(playlist.episodes)
      '     if activeEpisode <> -1
        '     screen.SetFocusedListItem(activeEpisode)
        '   end if
        ' else
      '     ' m.set2Level(screen, listIndex, playlist)
     '      activeEpisode = m.getActiveEpisode(playlist.episodes[listIndex].playlist.episodes)
     '      screen.SetFocusedListItem(activeEpisode)
        ' end if
      else if msg.isListItemSelected()
        itemIndex = msg.getIndex()
        if(isTwoLevel)
          subList = m.cp.getChildItem(playlist, listIndex)
          ' episode = m.cp.getChildItem(subList.playlist, itemIndex)
          itemIndex = GetGlobalAA().app.handleItemPicked(subList.playlist, itemIndex)

          'after detail screen is closed (revealing episodeListScreen again), update progress bars
          eps = playlist.episodes[listIndex].playlist.episodes
          if eps <> invalid
            screen.SetContentList(eps)
            activeEpisode = m.getActiveEpisode(eps)
            if activeEpisode = -1
              activeEpisode = 0
            else if activeEpisode >= playlist.episodes.[listIndex].playlist.episodes.count()
              activeEpisode = 0
            end if
            screen.SetContentList(eps)
          end if

        else
          ' episode = m.cp.getChildItem(playlist, itemIndex)
          itemIndex = GetGlobalAA().app.handleItemPicked(playlist, itemIndex)
        end if
        screen.SetFocusedListItem(itemIndex)
      end if
    end if
  end while
end function


'update getAllEpisodesForPlaylistFromServer call so works after api change
m.app.episodeListScreen.set2Level = function(screen, listIndex, playlist)
  activeEpisode = 0

  listNames = []
  for each item in playlist.episodes
    listNames.push(item.title)
  end for

  screen.SetListNames(listNames)

  'find the appropriate season to start a user on
  while true
    if playlist.episodes[listIndex] <> invalid
      if playlist.episodes[listIndex].playlist.haveAllEpisodes <> true
        m.cp.getAllEpisodesForPlaylistFromServer(playlist.episodes[listIndex].playlist, "episode")
      end if
      eps = playlist.episodes[listIndex].playlist.episodes
      screen.SetContentList(eps)
      activeEpisode = m.getActiveEpisode(eps)

      if activeEpisode = -1
        exit while
      else if activeEpisode >= playlist.episodes.[listIndex].playlist.episodes.count()
        listIndex = listIndex + 1
      else
        screen.SetFocusedListItem(activeEpisode)
        screen.SetContentList(eps)
        exit while
      end if
    else
      listIndex = 0
      exit while
    end if
  end while

  'set the appropriate season
  'this will not have any effect if listIndex is equal to the currently focused list
  'this will trigger a roPosterEvent in EpisodeListScreen_show,
  'which will in turn find and set the appropriate episode to focus on
  screen.setFocusedList(listIndex)

end function


'update getAllEpisodesForPlaylistFromServer call so works after api change
m.app.handleItemPicked = function(playlist, itemIndex)
  episode = m.cp.getEpisodeInPlaylist(playlist, itemIndex)

  if episode.type = "tubiLogin"
    if (m.utils.getUserData() = invalid)
      'user wants to log in
      m.registerScreen.show()
    else
      'user wants to log out'
      m.utils.deleteUserData()
    end if
  else if episode.type = "vezo"
    m.serverLink.connectToAccount(true)
    if(m.player.subscription)
      m.utils.showErrorMessage (m.utils.getSettings().adrise_bg, m.utils.getSettings().adrise_fontcolor, m.utils.getSettings().adrise_loadingurl, "You are subscribed to " + m.utils.getSettings().appName)
    end if
  else if episode.type = "search" 'load a search screen
    m.searchScreen.show()
  else if episode.type = "bookmarks" 'load a bookmarks screen
    m.bookmarksScreen.show()
  else if episode.type = "linear" 'play linear tv
    'get episode content for linear episodes
    linearPlaylist = m.linearTv.getPlaylistFromLinearIds()
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

      'send tracking that linear tv started
      m.utils.trackEvent({
        trackType: "linearTvStart"
      })

      'play video
      maxIndex = m.cp.getPlaylistLength(linearPlaylist) - 1
      'tell the player to treat only this first video as one that is being resumed (ie. not starting from very beginning)
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
        m.cp.getRenditionsForEpisode(episode)
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
        m.episodeListScreen.show(episode.playlist)
      else
        m.episodeListScreen.autoPlay(episode.playlist, m.cp.autoplayData.path[2], m.cp.autoplayData.path[3])
        m.cp.autoplayData = invalid
      end if
    end if
  end if
  return itemIndex
end Function


m.app.searchScreen.show = function()
  port = CreateObject("roMessagePort")
  screen = CreateObject("roSearchScreen")
  screen.SetMessagePort(port)

  screen.SetSearchTermHeaderText("Search Suggestions: ")
  screen.SetSearchButtonText("search")
  screen.SetClearButtonEnabled(false)

  screen.Show()

  searchString = ""
  searching = true
  suggestionCount = 0

  while searching = true
    msg = wait(0, screen.GetMessagePort()) 
    if type(msg) = "roSearchScreenEvent"
      if msg.isScreenClosed()
        print "screen closed"
        searching = false
      else if msg.isCleared()
        print "search terms cleared"
        history.Clear()
      else if msg.isPartialResult() 'letter/number added to the search string
        print "partial search: "; msg.GetMessage()
        searchString = msg.GetMessage()

        if searchString = ""
          screen.ClearSearchTerms()
          suggestionCount = 0

        else if Len(searchString) > 1 and Right(searchString, 1) <> " "
          url = m.setSearchUrl(searchString)

          port = CreateObject("roMessagePort")

          'send async request to search API
          'if the request is send succesfully wait 1 second for a response
          'if a response happens within that time get the response and act on it'
          asyncId = m.utils.sendAsyncRequest(url, port, "searchAPI")
          if (asyncId <> 0)
            while true
              msg = wait(1000, port)
              if msg <> invalid
                response = m.utils.getAsyncResponse(msg, asyncId) 'response.data should be xml object

                if response <> invalid and response.data <> invalid
                  xml = ParseXML(response.data)
                  if xml <> invalid and xml.children.level.children.getChildElements() <> invalid
                    screen.ClearSearchTerms()
                    for each child in xml.children.level.children.getChildElements()
                      suggestionTitle = child.title.GetText()
                      screen.AddSearchTerm(suggestionTitle)
                      if suggestionCount >= 8
                        exit for
                      end if
                      suggestionCount = suggestionCount + 1
                    end for
                    suggestionCount = 0
                  end if
                  exit while
                end if
              end if

            end while
          end if

        end if

      else if msg.isFullResult()
        print "full search: "; msg.GetMessage()
        searchString = msg.GetMessage()
        url = m.setSearchUrl(searchString)

        searchResultsXml = m.utils.getXml(url, "getSearchResults")

        searchPlaylist = m.cp.getPlaylistFromXmlObj(searchResultsXml.children.level, "250x250", 1, invalid, "search")
        m.cp.getAllEpisodesForPlaylistFromServer(searchPlaylist, "search")

        m.searchResultsScreen.showVertical(searchPlaylist)

      else if msg.isButtonInfo()
        print "button info "; msg.GetMessage()
      else
          print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
      end if
    end if
  end while 

end function



m.app.bookmarksScreen.show = function()
  settings = m.utils.getSettings()
  
  'delete all content in the bookmarks and previous viewed memory registries
  'you will need to restart the app after entering this screen to see that things were deleted
  'since this happens after the current user playlists are populated in cp
  '--------------------------------------------------------------------------------------------
  '--------------------------------------------------------------------------------------------
  ' previousReg = settings.previouslyViewedRegistry
  ' bookmarksReg = settings.bookmarkRegistry
  ' allPrevious =  m.utils.getUserPlaylistContent(previousReg)
  ' allBookmarks = m.utils.getUserPlaylistContent(bookmarksReg)

  ' for each id in allPrevious
  '   m.utils.deleteUserPlaylistContent(id, previousReg, invalid)
  ' end for

  ' for each id in allBookmarks
  '   m.utils.deleteUserPlaylistContent(id, bookmarksReg, invalid)
  ' end for
  '--------------------------------------------------------------------------------------------
  '--------------------------------------------------------------------------------------------

  'set up the bookmarks screen as a grid screen component
  msgPort = CreateObject("roMessagePort")
  bookmarksScreen = CreateObject("roGridScreen")
  ' bookmarksScreen = CreateObject("roPosterScreen")
  bookmarksScreen.SetMessagePort(msgPort)
  bookmarksScreen.SetDisplayMode("scale-to-fill")
  bookmarksScreen.SetGridStyle(settings.gridStyle)
  bookmarksScreen.show()

  'sleep after the show call helps prevent ugly green flash - though it's not perfect
  sleep(400)
  
  allPreviouslyViewed = m.utils.getUserPlaylistContent(settings.previouslyViewedRegistry)

  'pre setup the data for the screen - populates m.playlists and m.playlistNames
  m.getAllUserPlaylists()
  
  'get the number of user playlists
  numPlaylists = m.playlists.count()

  'set up the number of rows in the gridscreen
  bookmarksScreen.SetupLists(numPlaylists)

  'add playlist titles to rows
  bookmarksScreen.SetListNames(m.playlistNames)

  if m.playlists.count() = 0
    'show the user a message that there are no playlists and let them exit the screen
    m.messageOn = true
    bookmarksScreen.showMessage("You don't currently have any saved shows." + chr(10) +  "Press the back button to return to all shows.")
  else
    'add the content to each row
    ' for i=0 To m.playlists.count()-1 Step 1
    '   bookmarksScreen.setContentList(i, m.playlists[i].episodes)
    ' end for

    for i=0 To m.playlists.count()-1 Step 1
      if m.playlists[i].haveAllEpisodes <> true

      'set up the positions in the videosPrelim - on the regular grid screen, this is done by cp, but if we try to set the positions
      'for user playlists in cp, we mess up the positions for the regular grid screen. so do it here instead. not ideal, but it works.
        for j=1 to m.playlists[i].episodes.count()-1 step 1
          episode = m.playlists[i].episodes[j]
          episodeId = episode.id
          if m.playlists[i].videosPrelim[episodeId] <> invalid
            m.playlists[i].videosPrelim[episodeId].position = j
          end if
        end for

        'get all the meta data for the videos in the playlist
        m.cp.getAllEpisodesForPlaylistFromServer(m.playlists[i], "gridscreen")
      end if
      'set the playlist to the gridscreen row.
      bookmarksScreen.setContentList(i, m.playlists[i].episodes)
    end for
  end if

  'add tracking to indicate that the bookmarks/recently viewed screen has been opened
  m.utils.trackEvent({
    trackType: "openBookmarks"
    value: m.cp.userPlaylists.bookmarks.episodes.count()
  })
  m.utils.trackEvent({
    trackType: "openRecentlyViewed"
    value: m.cp.userPlaylists.previous.episodes.count()
  })

  'listen for any events
  listening = true
  while listening = true
    msg = wait(0, msgPort)
    if type(msg) = "roGridScreenEvent"
      'did the user select a video or series
      if msg.isListItemSelected()
        row = msg.getIndex()
        item = msg.getData()

        'set the state of what user playlist was selected so we know where the player will be coming from - for tracking purposes
        if m.playlists[row] <> invalid and m.playlists[row].name = "Bookmarks"
          m.startFromBookmarks = true
        else if m.playlists[row] <> invalid and m.playlists[row].name = "Recently Viewed"
          m.startFromRecentlyViewed = true
        end if

        'let the app functionality do what it do - show the appropriate page depending on the selected item
        newItemIndex = GetGlobalAA().app.handleItemPicked(m.playlists[row], item)

        'at this point we have returned back to the bookmarks and recently viewed gridscreen
        'so set the state of the playlists back to false
        m.startFromBookmarks = false
        m.startFromRecentlyViewed = false

        'get updated info from user playlists
        m.getAllUserPlaylists()

        'reset the gridscreen
        bookmarksScreen.SetupLists(m.playlists.count())
        bookmarksScreen.SetListNames(m.playlistNames)

        'reset the rows (contentLists) on the bookmarks gridscreen
        for i=0 To m.playlists.count()-1 Step 1
          if m.playlists[i].episodes <> invalid
            bookmarksScreen.setContentList(i, m.playlists[i].episodes)
          end if
        end for
        bookmarksScreen.show()

      'was the screen closed
      else if msg.isScreenClosed()
        bookmarksScreen.close()
        listening = false

      else if msg.isRemoteKeyPressed()
        print "BUTTON PRESSED "; msg.getIndex()
        if m.messageOn = true and msg.getIndex() = 6 'ok was pressed
          bookmarksScreen.clearMessage()
          bookmarksScreen.close()
        end if

      ' else if msg.isListItemFocused()
      '   row = msg.getIndex()
      '   item = msg.getData()
      '   focusedPlaylist = m.playlists[row]
      '   focusedItem = focusedPlaylist.episodes[item]
      '   if focusedItem.type = "video"
      '     print "VIDEO IN USER PLAYLIST"
      '     print focusedItem
      '     print type(focusedItem.country)
      '     if focusedItem.country <> invalid
      '       print focusedItem.country.Len()
      '     end if
      '   end if

      end if
    end if
  end while

end function


'makes Roku ad framework numbering act properly
m.app.player.ads.totalAdBreakAds = 0

m.app.player.ads.getAdsListViaRoku = function(episode, playerSettings)
  m.allAdUnitsList = []

  'set the content title as id  and the content length(as stated in RAF documentation v1.1 for Nielsen functionality)
  if episode.title <> invalid
    m.roAdFramework.setContentId(episode.title)
  else
    m.roAdFramework.setContentId()
  end if

  if episode.length <> invalid
    m.roAdFramework.setContentLength(episode.length)
  else
    m.roAdFramework.setContentLength()
  end if

  'get the url for making the ad call
  url = m.populateUrl(episode, playerSettings)
  ' url = "http://ad-non-cms-00.adrise.tv/?advid=&appid=adrise-ad-demo&cid=257507&content-type=hls&debug=0&tubitvid=&deviceid=test&nowpos=0&platform=roku&pubid=61c46e332f1721ff821936c7bf0525af&sdk=raf_vast&zid=test"

  'set the url for the Roku Advertising Framework
  m.roAdFramework.setAdUrl(url)

  'get the array of ad units back from the Roku Advertising Framework(RAF)
  'adUnits are called adPods in RAF documentation
  currentAdUnitsList = m.roAdFramework.getAds()

  ' ShowVarSimple(currentAdUnitsList, "Ad Unit List")

  'check to see if the ad server returns an ad that can be used by RAF or needs to use our ad SDK
  'traditional version of xml is in the clickThrough property/clickThrough VAST tag
  'traditional is used if adId of the first ad object in the first ad pod is set equal to 'default'
  if currentAdUnitsList <> invalid and currentAdUnitsList.count() > 0 and currentAdUnitsList[0] <> invalid and currentAdUnitsList[0].ads <> invalid and currentAdUnitsList[0].ads.count() > 0
    adUnitType = "" 'keeps track of what kind adUnitsList/adPod is currently being built by the for loop - can be "adrise" or "roku"
    
    'set up the duration for use by the adRise pre ad splash screen
    if currentAdUnitsList[0].duration <> invalid and currentAdUnitsList[0].duration > 0
        m.commercialDuration = m.commercialDuration + currentAdUnitsList[0].duration
    end if

    adUnitsListContainer = {
      type: ""
      adUnitsList: []
    }

    'save the total number of ads in the adbreak before we (potentially) start breaking them up into different ad unit lists
    m.totalAdBreakAds = currentAdUnitsList[0].ads.count()

    for each adUnit in currentAdUnitsList[0].ads
      if adUnit.adId <> invalid
        print "AD ID "; adUnit.adId
        
        'if the adUnit contains an ad that needs to use the adRise Ad SDK
        if adUnit.adId = "default"
          'if adUnitType is different from the last adUnitType (meaning a new adUnitsListContainer is needed)
          'push the last adUnitsListContainer to m.allAdUnitsList, otherwise we will just add to the last adUnitsListContainer
          'set up the adContainer for adrise type if needed
          if adUnitType <> "adrise"
            if adUnitsListContainer.type <> "" 'means we've already built at least one adUnitsListContainer
              m.allAdUnitsList.push(adUnitsListContainer)
            end if
            adUnitType = "adrise"
            adUnitsListContainer = {
              type: adUnitType
              adUnitsList: []
            }
          end if
          
          'get the adrise adUnit object from the xml passed through the ClickThrough tag
          'and push it to the adUnitsList in the adUnitsListContainer'
          traditionalAdXmlString = adUnit.clickThrough
          adriseAdUnitsList = m.getAdUnitsListTraditional(episode, playerSettings, traditionalAdXmlString) 'in most cases this should return back an adUnitsList with one adUnit it it'
          
          'add duration to m.commercialDuration
          for each adUnit in adriseAdUnitsList
            if adUnit.duration <> invalid
              m.commercialDuration = m.commercialDuration + Val(adUnit.duration)
            end if
          end for

          if adriseAdUnitsList <> invalid and adriseAdUnitsList.count() > 0
            adUnitsListContainer.adUnitsList.append(adriseAdUnitsList)
          else
            print "no ad units returned via ClickThrough"
            if m.midrolls.count() = 0 or (m.midrolls.count() = 1 and m.lastAdFailed = true)
              'set the default midroll if something went wrong with the traditional ad XML and there were no midrolls already
              m.midrolls = [episode.nowpos + 300]
              m.lastAdFailed = true
            end if
          end if
        
        'the ad server had no ads to return so sends us just the midroll times'
        else if adUnit.adId = "empty"
          if m.midrolls.count() = 0 or (m.midrolls.count() = 1 and m.lastAdFailed = true)
            m.midrolls = [] 'reset the midrolls array in case there was a previous default midroll
            if adUnit.clickThrough <> invalid
              m.midrolls = m.getCommaDelimitedMidrolls(adUnit.clickThrough)
            end if
          end if
        
        'if the adUnit contains an ad that needs to use the Roku Ad Framework'
        else
          'if adUnitType is different from the last adUnitType (meaning a new adUnitsListContainer is needed)
          'push the last adUnitsListContainer to m.allAdUnitsList, otherwise we will just add to the last adUnitsListContainer
          'set up the adContainer for roku type if needed
          if adUnitType <> "roku"
            if adUnitsListContainer.type <> "" 'means we've already built at least one adUnitsListContainer
              m.allAdUnitsList.push(adUnitsListContainer)
            end if
            adUnitType = "roku"
            adUnitsListContainer = {
              type: adUnitType
              adUnitsList: [
                {
                  viewed: currentAdUnitsList[0].viewed
                  renderSequence: currentAdUnitsList[0].renderSequence
                  duration: currentAdUnitsList[0].duration
                  renderTime: currentAdUnitsList[0].renderTime
                  ads: []
                }
              ]
            }
          end if

          'make sure we have the appropriate stream format. if stream format is mp4, but file is an HLS, the ad won't play
          for each stream in adUnit.streams
            if stream.url <> invalid and right(stream.url, 4) = "m3u8"
              adUnit.streamFormat = "hls"
            end if
          end for

          'add the roku ad unit to the adUnitsList in the current adUnitsListContainer
          adUnitsListContainer.adUnitsList[0].ads.push(adUnit)

          'add the duration to m.CommercialDuration for use in adRise pre ad splash screens (in case there are any)
          if currentAdUnitsList[0].duration = invalid or currentAdUnitsList[0].duration <= 0
            m.commercialDuration = m.commercialDuration + adUnit.duration
          end if 
          
          'set the midrolls if midrolls haven't already been set by preroll or earlier midroll
          'midrolls are sent as comma delineated strings in the clickThrough property of the ads being sent
          if m.midrolls.count() = 0 or (m.midrolls.count() = 1 and m.lastAdFailed = true)
            m.midrolls = [] 'reset the midrolls array in case there was a previous default midroll
            if adUnit.clickThrough <> invalid
              m.midrolls = m.getCommaDelimitedMidrolls(adUnit.clickThrough)
            end if
          end if
        end if
      end if
    end for

    m.allAdUnitsList.push(adUnitsListContainer) 'push the last adUnitsListContainer
    
    'if no midrolls times were found in any of the ads set the default midroll
    if m.midrolls.count() = 0 or (m.midrolls.count() = 1 and m.lastAdFailed = true)
      m.midrolls = [episode.nowpos + 300]
      m.lastAdFailed = true
    end if
  else
    'no ad units were returned so we need to set the default midroll
    print "no ad units returned"
    if m.midrolls.count() = 0 or (m.midrolls.count() = 1 and m.lastAdFailed = true)
      m.midrolls = [episode.nowpos + 300]
      m.lastAdFailed = true
    end if
  end if

  ' print "CURRENT MIDROLLS"
  ' print m.midrolls
end function

m.app.player.ads.showCommercialBreakViaRoku = function(canvas, playerSettings)
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
          if isCompleted = false
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



'prevents users from getting served midrolls on resume - live tv todo
m.app.player.playVideo = function(episode as Object)

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
  m.startFromBookmarks = GetGlobalAA().app.bookmarksScreen.startFromBookmarks
  m.startFromRecentlyViewed = GetGlobalAA().app.bookmarksScreen.startFromRecentlyViewed

  'send tracking event that the video started playing
  if m.linearTvOn = true
    m.utils.trackEvent({
      trackType: "linearVideoPlay"
      value: episode.adrise_contentid
      port: m.playerPort
    })
  else if m.startFromBookmarks = true
    m.utils.trackEvent({
      trackType: "startVideoBookmarks"
      value: episode.adrise_contentid
      port: m.playerPort
    })
  else if m.startFromRecentlyViewed = true
    m.utils.trackEvent({
      trackType: "startVideoRecentlyViewed"
      value: episode.adrise_contentid
      port: m.playerPort
    })
  else
    m.utils.trackEvent({
      trackType: "videoPlay"
      value: episode.adrise_contentid
      port: m.playerPort
    })
  end if

  if episode.playStart <> invalid
    episode.nowPos = episode.playStart
  endif


  ' set up the background layer that sits behind ads - necessary so that the details screen doesn't show between ads
  canvas = CreateObject("roImageCanvas")
  adBackgroundPort = CreateObject("roMessagePort")
  canvas.SetMessagePort(adBackgroundPort)
  canvas.SetLayer(1, {color: "#000000"})
  canvas.Show()

  if m.subscription = false
    if episode.pubId <> invalid and episode.pubId <> ""
      print "copy episode pubid (" + episode.pubid + ") to settings pubid (" + m.pubID + ")"
      m.pubId = episode.pubId
    end if

    'check if the user is resuming an episode - if so, check if they left off on a cue point
    'if they didn't leave off on a cue point, don't show them any more ads
    if episode.isResumed = true
      'get the cuepoints for the current content and checks if the resume position is on a cuepoint
      isOnCue = m.ads.checkResumeOnCuepoint(episode)
    end if

    'if the user resumed content but didn't resume on a cue point, then don't show any ads
    if episode.isResumed = true and isOnCue = false
      'COMPLETED means the player thinks the ads completed so show the content
      'in our case we are not showing ads so act as if they completed
      status = "COMPLETED"

    'otherwise if the user is starting from beginning or resuming on a cue point, show ads
    else
      'get list of ads and play them for preroll
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
    end if
  end if


  ' if the pre-roll ad completed without the user closing it explicitly,
  ' (or there was no pre-roll because it is a subscription app), play the content
  while true
    status = m.showSpanOfContentVideo(episode)
    print "PLAYER STATUS "; status

    while status = "FAILED"
      failHandlerStatus = m.handleVideoFailure(episode)
      if failHandlerStatus = "CLOSE"
        canvas.close()

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
            value: episode.adrise_contentid
            ctx: episode.nowPos
            port: m.playerPort
          })
        end if

        return "CLOSE"
      else if failHandlerStatus = "IGNORE"
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

      canvas.SetLayer(1, {color: "#000000"})
      canvas.Show()

      'get list of ads and play them
      if m.ads.isRokuAdFrameworkOn = true
        adStatus = m.ads.showCommercialBreakViaRoku(canvas, m)
      else
        videoAdsList = m.ads.getCachedAdsList(episode)
        adStatus = m.ads.showCommercialBreak(canvas, videoAdsList, m)
      end if

      if adStatus = "CLOSED"
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
        if episode.nowPos > episode.length - 10

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
        end if
          m.utils.trackEvent({
            trackType: "videoStopComplete"
            value: episode.adrise_contentid
            ctx: episode.nowPos
            port: m.playerPort
          })
        else
      end if

      canvas.close()
      return status
    end if
  end while

end function

m.app.detailScreen.show = function(episode, playlist, itemIndex)
  port = CreateObject("roMessagePort")

  maxIndex = m.cp.getPlaylistLength(playlist) - 1

  screen = CreateObject("roSpringboardScreen")
  screen.SetBreadcrumbText("", playlist.name)
  screen.SetDescriptionStyle("movie")

  if episode.thumbnailRatio = invalid
     screen.SetPosterStyle(m.settings.SetPosterStyle)
  else
    if episode.thumbnailRatio > 1
      posterStyle = "rounded-rect-16x9-generic"
    else
      posterStyle = "multiple-portrait-generic"
    end if
    screen.SetPosterStyle(posterStyle)
  end if

  screen.SetStaticRatingEnabled(false)
  screen.SetMessagePort(port)

  showRentButton = (m.settings.allowRentals=true)
  m.update(screen, episode, showRentButton)
  
  screen.Show()

  settings = m.utils.getSettings()
  while true
    msg = wait(0, port)
    m.utils.setContext("detailScreen", playlist, itemIndex)
    m.utils.globalMessageHandler(msg)
    if type(msg) = "roSpringboardScreenEvent"

      if msg.isScreenClosed()

        exit while
      else if msg.isButtonPressed()
        button = msg.GetIndex()
        episode.PlayStart = 0
        if button = 1 or button = 2

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
            rating = episode.rating

            if play
              if button = 2 ' resume playing
                'set the state of the episode to be resumed since resume play was selected
                episode.isResumed = true
                
                if (episode.id <> invalid)
                  d = m.utils.getSavedContentData(episode.id)
                  if(d <> invalid)
                    episode.PlayStart = d.pos
                  end if
                end if
              end if

              ' play till end of playlist
              while true
                m.cp.GetRenditionsForEpisode(episode)
                ret = m.player.playVideo(episode)

                'save video that was watched into previously viewed playlist
                m.savePreviouslyViewed(episode)

                if (ret <> "CLOSED" and itemIndex < maxIndex)
                  itemIndex = itemIndex + 1
                  episode = m.cp.getEpisodeInPlaylist(playlist, itemIndex)
                  episode.PlayStart = 0
                  if (episode.type <> "video")
                    itemIndex = itemIndex - 1
                    exit while
                  end if
                  m.update(screen, episode, showRentButton)
                else
                  'return itemIndex 'this should be commented out?
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
          isSaved = m.saveBookmark(episode)
          if isSaved = true
            m.updateButtons(screen, episode, showRentButton)
          end if
        else if button = 6 'user wants to remove the bookmark for this content'
          isRemoved = m.removeBookmark(episode)
          if isRemoved = true
            m.updateButtons(screen, episode, showRentButton)
          end if
        end if

      else if msg.isRemoteKeyPressed()
        button = msg.GetIndex()
        if button = 4 or button = 5
          newItemIndex = m.moveForwardBackward(itemIndex, maxIndex, (button = 5))
          newEpisode = m.cp.getEpisodeInPlaylist(playlist, newItemIndex)
          if(newEpisode.type = "video")
            episode = newEpisode
            itemIndex = newItemIndex
            m.update(screen, episode, showRentButton)
          end if
        else
        end if
      end if
    else
    end if

  end while
  return itemIndex
end function

'returns true or false depending on if a user clicked resume play and resumed on a cue point or not
m.app.player.ads.checkResumeOnCuepoint = function(episode)
  'set the url to get the cuepoints
  cuepointUrl = "http://ads.adrise.tv/cue-points/?format=json&pubid=" + episode.pubId + "&platform=web&cid=" + episode.id
  
  'get the cuepoints synchronously
  cuepointsJson = m.utils.getTextFile(cuepointUrl, "getCuePoints")
  print "CUEPOINTS JSON "; type(cuepointsJson); cuepointsJson

  'parse the returned JSON to a Brightscript object - should return an array
  cuepoints = ParseJson(cuepointsJson)

  if type(cuepoints) = "roArray"
    'set the cuepoints so the rest of the program is aware of them
    m.midrolls = cuepoints
    'iterate the cuepoints - if the resume position is equal to one of the cuepoints, then return true
    for each cuepoint in cuepoints
      if episode.nowPos = cuepoint
        return true
      end if
    end for
  end if

  'if the resume position is not equal to any of the cuepoints, return false
  return false
end function

m.app.linearTv.getPlaylistFromLinearIds = function()
  items = []
  videos = {}
  idString = ""
  count = 0
  for each episode in m.linearEpisodes
    if type(episode.id) = "integer"
      episode.id = episode.id.ToStr()
    end if
    idString = idString + "," + episode.id 

    item = {
      type : "video"
      title: episode.title
      id: episode.id
      adrise_contentId: episode.id
      position: count
      isResumed: false
    }
    videos[episode.id] = item
    items.push({})
    count = count + 1
  end for

  idString = idString.mid(1) 'remove first comma

  return {
    name: "Linear TV"
    depth: 1
    videosPrelim: videos
    episodes: items
    videosIdString: idString
  }
end function


'//////////////////////////////////////////////////////////////////
'//////////////////////////////////////////////////////////////////
'//////////////////////////////////////////////////////////////////
'//////////////////////////////////////////////////////////////////
'//////////////////////////////////////////////////////////////////
'//////////////////////////////////////////////////////////////////
'fix the memory leak associated with async requests (ad pixels and tracking events)

'create the player port that will be used for all events in the main player and ads objects
m.app.player.playerPort = CreateObject("roMessagePort")
m.app.player.ads.playerPort = m.app.player.playerPort

m.app.utils.trackEvent = function(evt)
  print "track event"
  time = CreateObject("roDateTime")

  startMS = 1000 * (60 * (60 * time.GetHours() + time.GetMinutes()) + time.GetSeconds()) + time.getMilliseconds()

  ' ------------AdUnit Events------------------
  if evt.trackType = "click" then
    For Each trackUrl in evt.adUnit.clickTrack
      trackUrl = strReplace(trackUrl, "[", "")
      trackUrl = strReplace(trackUrl, "]", "")
      asyncId = m.sendAsyncRequest(trackUrl, evt.port, "trackClick")
    end for
  else if evt.trackType = "imp" then
    For Each trackUrl in evt.adUnit.impTrack
      trackUrl = strReplace(trackUrl, "[", "")
      trackUrl = strReplace(trackUrl, "]", "")
      asyncId = m.sendAsyncRequest(trackUrl, evt.port, "trackImp")
    end for

  else if evt.trackType = "viewthru" then
    For Each trackUrl in evt.adUnit.viewthru[evt.adPercentage]
      trackUrl = strReplace(trackUrl, "[", "")
      trackUrl = strReplace(trackUrl, "]", "")
      evt.adUnit.viewthru[evt.adPercentage] = "" ' making sure it doesn't get fired again
      asyncId = m.sendAsyncRequest(trackUrl, evt.port, "trackViewThru") ' + str(evt.adPercentage))
    end for


  'event tracking for non ad events
  else if evt.trackType <> invalid and m.deviceInfo.firmwareVersion > 3.01 then
    ' trackData = m.getTrackData(evt.trackType, evt.contentId, evt.progressPercent, evt.playerPosition, evt.deepLinkSource, evt.errorMessage)
    trackData = m.getTrackData(evt.trackType, evt.value, evt.ctx)
    m.trackingDataToSend.push(trackData)

    if (evt.trackType <> "playProgress" and evt.trackType <> "linearPlayProgress") or m.trackingDataToSend.count() >= 5
      trackingDataToSendJSON = FormatJson(m.trackingDataToSend)
      trackDataToSendJSONEncoded = urlEncode(trackingDataToSendJSON)

      ' trackUrl = "http://tb.tu-int.com/extEvent?events=" + trackDataToSendJSONEncoded   'staging tracking server
      trackUrl = "http://cms.adrise.com/extEvent?events=" + trackDataToSendJSONEncoded    'production tracking server

      'for testing linear tv crashes only
        linearTrackTime = CreateObject("roDateTime")
        linearTrackTime.ToLocalTime()
        localTime = linearTrackTime.GetHours().toStr() + ":" + linearTrackTime.GetMinutes().toStr() + ":" + linearTrackTime.GetSeconds().toStr()

      '--------------------------'

      ' print "-------------TRACK URL-------------"
      ' print trackUrl; + " : " + localTime
      asyncId = m.sendAsyncRequest(trackUrl, evt.port, "track" + evt.trackType)
      m.trackingDataToSend = []
    end if

  end if
end function

m.app.player.showSpanOfContentVideo = function(episode As Object)
  status = 0

  if type(episode) <> "roAssociativeArray"
    print "invalid data passed to showVideoScreen"
    return "COMPLETED"
  endif

  screen = CreateObject("roVideoScreen")

  screen.SetMessagePort(m.playerPort)
  screen.SetPositionNotificationPeriod(1)

  if m.utils.supportsSubtitles() = true
    if episode.subtitleUrl <> invalid
      screen.showSubtitle(true)
      print "show subtitles true" + episode.subtitleUrl
    else
      screen.showSubtitle(false)
      print "show subtitles false"
    end if
  else
    print "doesn't support subtitles"
  end if

  screen.SetContent(episode)
  screen.Show()

  failCount = 0

  while true
    msg = wait(0, m.playerPort)
    ' print "playerport message: "; type(msg) '" | "; msg.GetMessage(); " | "; msg.GetIndex()

    if type(msg) = "roUrlEvent"
      respObj = m.utils.getAsyncResponse(msg, 0)
    end if

    m.utils.globalMessageHandler(msg)

    if type(msg) = "roVideoScreenEvent"
      ' print msg.getMessage(); " | index = "; msg.GetIndex()
      if msg.getMessage() = "Playback interrupted by user."
        print "video was closed"
        status = "CLOSED"
        exit while
      else if msg.isRequestFailed()
        if failCount > 10
          print "Video request failure: "; msg.GetIndex(); " " msg.GetMessage()
          m.utils.trackEvent({
            trackType: "videoFailure"
            value: episode.adrise_contentid
            ctx: msg.GetMessage()
            port: m.playerPort
          })
          status =  "FAILED"
          exit while
        else
          print "Video request failure: "; msg.GetIndex(); " " msg.GetMessage() ; " " ; failCount
          failCount = failCount + 1
        end if
      else if msg.isStatusMessage()
        print "Video status: "; msg.GetIndex(); " " msg.GetMessage()
      else if msg.isButtonPressed()
        print "Button pressed: "; msg.GetIndex(); " " msg.GetMessage()
      else if msg.isStreamStarted()
        'g = GetGlobalAA()
        'if g.customizations.trackVideo <> invalid
        '  g.customizations.trackVideo(episode)
        'end if
      else if msg.isFullResult()
        RegDelete(episode.adrise_contentId)
        status = "COMPLETED"
        exit while
      else if msg.isPlaybackPosition()
        failCount = 0
        nowPos = msg.GetIndex()
        episode.nowPos = nowPos

        pingTime = Int(nowPos / m.pingFrequency)

        if m.lastPingTime <> pingTime

          if m.linearTvOn = true
             m.utils.trackEvent({
              trackType:  "linearPlayProgress"
              ctx: episode.adrise_contentid
              value: nowPos/episode.length
              port: m.playerPort
            })
           else
            m.utils.trackEvent({
              trackType:  "playProgress"
              ctx: episode.adrise_contentid
              value: nowPos/episode.length
              port: m.playerPort
            })
          end if

          m.lastPingTime = pingTime
        end if

        'if nowPos > 50 and m.failCount < 3
        '  m.failCount = m.failCount + 1
        '  return "FAILED"
        'end if

        'save into registry memory the last position of the video that was watched
        if (episode.length <> invalid)
          m.utils.saveContentData(episode.adrise_contentId, nowPos)
        end if

        'checks if there is a commercial break about to occur
        'if there is, caches an appropriate set of ads for the ad break depending on which framework is being used'
        breakPos = m.ads.checkForCommercialBreak(nowPos, episode, m)
        if breakPos <> -1
          print "checkForCommercial returned " ; breakPos
          episode.nowPos = breakPos
          episode.playStart = breakPos
          list = m.ads.getCachedAdsList(episode)
          if list <> invalid
            status = "STOPFORCOMMERCIAL"
            exit while
          end if
        end if
      end if
    end if
  end while

  screen.Close()
  return status
end function

m.app.player.handleVideoFailure = function(episode)
  dialog = CreateObject("roMessageDialog")
  dialog.SetMessagePort(m.playerPort)

  dialog.SetText("Video playback failed.")
  dialog.SetText("Would you like to try resuming?")

  dialog.SetText("If problem persists, please visit adrise.tv/support")
  dialog.AddButton(1, "Try resuming")
  dialog.AddButton(2, "Ignore error")
  dialog.AddButton(3, "Exit video")
  dialog.EnableBackButton(true)
  dialog.Show()

  while true
    dlgMsg = wait(0, m.playerPort)

    if type(dlgMsg) = "roUrlEvent"
      respObj = m.utils.getAsyncResponse(msg, 0)
    end if

    if type(dlgMsg) = "roMessageDialogEvent"
      if dlgMsg.isButtonPressed()
        button = dlgMsg.GetIndex()
        if (button = 1)
          episode.playStart = episode.nowPos
          status = m.showSpanOfContentVideo(episode)
          return status
        else if (button = 2)
          return "IGNORE"
        else if (button = 3)
          return "CLOSE"
        end if
      end if

      if dlgMsg.isScreenClosed()
        return "IGNORE"
      end if
    end if
  end while
  return ""
end function


'temporary brightline functions
m.app.player.ads.adriseAds_brightlineOnStart = function(roVideoPlayerEvent)
  GlobalUtils = GetGlobalAA().app.utils
  GlobalAdUnit = GetGlobalAA().app.player.ads.currentAdUnit
  playerPort = GetGlobalAA().app.player.ads.playerPort
  print "BRIGHTLINE AD START EVENT"
  GlobalUtils.trackEvent({
    trackType:  "imp"
    adUnit: GlobalAdUnit
    port: playerPort
  })
end function

m.app.player.ads.adriseAds_brightlineOnComplete = function(roVideoPlayerEvent)
  GlobalUtils = GetGlobalAA().app.utils
  GlobalAdUnit = GetGlobalAA().app.player.ads.currentAdUnit
  playerPort = GetGlobalAA().app.player.ads.playerPort
  print "BRIGHTLINE AD COMPLETE EVENT"
  GlobalAdUnit.status = "COMPLETED"
  GlobalUtils.trackEvent({
    trackType:  "viewthru"
    adUnit: GlobalAdUnit
    adPercentage: 100
    port: playerPort
  })
end function

m.app.player.ads.adriseAds_brightlineOnPosition = function(roVideoPlayerEvent)
  GlobalUtils = GetGlobalAA().app.utils
  adUnit = GetGlobalAA().app.player.ads.currentAdUnit
  playerPort = GetGlobalAA().app.player.ads.playerPort
  statusInterval = adUnit.Duration.toInt() / 4
  lastSavedPos = adUnit.positionPoints.lastSavedPos
  positionPercentage = adUnit.positionPoints.positionPercentage
  nowPos = roVideoPlayerEvent.GetIndex()

  if nowPos = 0
    GlobalUtils.trackEvent({
      adUnit: adUnit
      trackType: "viewthru"
      adPercentage: positionPercentage
      port: playerPort
    })
  else if abs(nowPos - lastSavedPos) > statusInterval and positionPercentage < 75
    adUnit.positionPoints.lastSavedPos = nowpos
    adUnit.positionPoints.positionPercentage = positionPercentage + 25
    positionPercentage = positionPercentage + 25
    if (positionPercentage < 100)
      GlobalUtils.trackEvent({
          adUnit: adUnit
          trackType: "viewthru"
          adPercentage: positionPercentage
          port: playerPort
        })
    end if
  end if
end function

m.app.player.ads.showVideoAd = function(canvas, adUnit, adDetails, playerSettings)


  m.currentAdUnit = adUnit

  ' print "AD UNIT------------------ : "
  ' print adUnit
  ' print "----------------------------"

  if m.adIsLexusInteractive(adUnit)
    la = m.lexusAd(adUnit)
    la.setUpCanvas(true)
    la.paintCanvas()
    return la.doEventLoop()
  end if

  status = "COMPLETED"
  
  'check if ad is Brightline companion overlay type by checking if companionOverlay property exists
  'since Brighltine throws errors on 3.1 firmware, only serve Brightline ads on greater than 3.1 firmware
  version = m.utils.deviceInfo.firmwareVersion
  major = Int(version)
  
  if (m.adIsBrightlineCompanionAd(adUnit) and major <> 3)
    ip = BL_InteractivePreroll()

    ip.Append({
      onVideoPlayerStreamStarted: GetGlobalAA().app.player.ads.adriseAds_brightlineOnStart
      onVideoPlayerFullResult: GetGlobalAA().app.player.ads.adriseAds_brightlineOnComplete
      onVideoPlayerPlaybackPosition: GetGlobalAA().app.player.ads.adriseAds_brightlineOnPosition
      onVideoPlayerPartialResult: adriseAds_brightlineOnExitWrapper
    })
    ip.initialize(adUnit)

    while true
      if m.currentAdUnit.status <> invalid
        print status 
        status = m.currentAdUnit.status
        exit while
      end if 
    end while

    return status
  end if
  

  ' print "show video ad"
  ' ShowVarSimple(adUnit, "ad")

  print "ad unit total options "; adUnit.totalOptions


  adCanvas = CreateObject("roImageCanvas")
  adPort = CreateObject("roMessagePort")
  adCanvas.SetMessagePort(adPort)

  if type(adUnit) <> "roAssociativeArray"
    adCanvas.close()
    return "COMPLETED"
  end if

  player = CreateObject("roVideoPlayer")
  ' be sure to use the same message port for both the ad canvas and the ad player
  player.SetMessagePort(adPort)
  player.SetDestinationRect(adCanvas.GetCanvasRect())
  player.SetPositionNotificationPeriod(1)

  ' set up some messaging to display while the pre-roll buffers
  m.utils.showAdLoadingLayer(adCanvas, playerSettings.displaySize, adDetails.secondsLeft, adDetails.adCounter, adDetails.totalAds, playerSettings.background, playerSettings.fontColor, playerSettings.loadingurl, playerSettings.appid)
  adCanvas.Show()

  m.utils.trackEvent({
    trackType:  "imp"
    adUnit: adUnit
    port: adPort
    })
  player.AddContent(adUnit)

  player.Play()
  print "play ad start"

  lastSavedPos = 0
  positionPercentage = 0
  statusInterval = adUnit.Duration.toInt() / 4

  showImageOptions = {
    z: 10
    cMode: "Source_over"
    h: 80
  }

  'create the overlay for a skippable ad if necessary
  if adUnit.adIsSkippable = true
    m.skippableOverlay = m.createSkippableAd(adCanvas, m.utils)
  end if

  while true
    currOption = adUnit.currentOption
    msg = wait(0, adPort)
    
    if type(msg) = "roUrlEvent"
      respObj = m.utils.getAsyncResponse(msg, 0)
    end if

    if type(msg) = "roImageCanvasEvent"
      if (msg.isRemoteKeyPressed())
        i = msg.GetIndex()
        print "remote key pressed "  ; i
        if (i = 13)
          print "Pressed play"
        else if (i = 8)
          print "Pressed rewind"
        else if (i = 9)
          print "Pressed fast forward"
        else if (i = 6)
          print "Pressed select"

          'if ok is pressed during a skippable ad, after the skip time has elapsed
          if adUnit.adIsSkippable = true
            if m.skippableOverlay <> invalid and m.skippableOverlay.time >= m.skippableOverlay.skipTime
              status = "COMPLETED"
              print "skipped ad"

              'send tracking for skipped ad
              if adUnit.totalOptions > 0
                currOption = 0 'always set currOption = 0 for skippable ads

                'send the appropriate amount of tracking pixels depending on the XML structure
                if adUnit.adBar[currOption].urls <> invalid
                  numUrls = adUnit.adBar[currOption].urls.count()
                  for each url in adUnit.adBar[currOption].urls
                    m.utils.sendAsyncRequest(url, m.playerPort, "adSelectMultiple")
                  end for
                else if adUnit.adBar[currOption].url <> invalid
                  m.utils.sendAsyncRequest(adUnit.adBar[currOption].url, m.playerPort, "adSelectSingle")
                end if

              end if
              exit while
            end if
          end if

          if adUnit.adIsSelectable = true
            if adUnit.totalOptions > 0
              filename = adUnit.adbarThanksImage + "?" + RND(10000000).ToStr()
              showImageOptions.mode = "1"
              m.utils.showImageOnCanvas(filename, adCanvas, showImageOptions)
              adCanvas.Show()

              ' multiple urls
              if adUnit.adBar[currOption].urls <> invalid
                numUrls = adUnit.adBar[currOption].urls.count()
                for each url in adUnit.adBar[currOption].urls
                  m.utils.sendAsyncRequest(url, m.playerPort, "adSelectMultiple")
                end for
              else if adUnit.adBar[currOption].url <> invalid
                m.utils.sendAsyncRequest(adUnit.adBar[currOption].url, m.playerPort, "adSelectSingle")
              end if

              ' disable future interactions:
              adUnit.totalOptions = 0
            end if
            m.selectableAds.handleAdClick(adUnit)
          end if

        else if (i = 4 or i = 5) ' left or right
          if adUnit.adIsSelectable
            if (adUnit.totalOptions > 0)
              if i = 4
                currOption = currOption-1
              else if i = 5
                currOption = currOption+1
              end if
              if (currOption < adUnit.totalOptions and currOption >= 0)
                filename = adUnit.adBar[currOption].img + "?" + RND(10000000).ToStr()
                showImageOptions.mode = "2"
                m.utils.showImageOnCanvas(filename, adCanvas, showImageOptions)
                adCanvas.Show()
                adUnit.currentOption = currOption
              end if
            end if
          end if

        else if (i = 2 or i = 0)
          ' Pressed Up
          player.Stop()
          adCanvas.close()
          status = "CLOSED"
          return status
        else if (i = 3)
          print "Pressed down"
        end if
      else if (msg.isScreenClosed())
        adCanvas.close()
        return status
      end if
    else if type(msg) = "roVideoPlayerEvent"
      if msg.isStreamStarted()
        print "stream started"

      else if msg.isStatusMessage() and msg.getMessage() = "startup progress"
         'm.paintCanvas()
          ' print "loading progress " ; (msg.GetIndex() / 10)

      '---------------------------------
      else if msg.isFullResult()
        if (m.videoAdErrorCount = 0)
          if (positionPercentage >= 75)
            m.utils.trackEvent({
              trackType: "viewthru"
              adUnit: adUnit
              adPercentage: 100
              port: m.playerPort
            })
            ' adCanvas.close()
          end if
          exit while
        end if

      '---------------------------------
      else if msg.isPlaybackPosition()
        nowpos = msg.GetIndex()

        m.utils.globalMessageHandler(msg)
        if nowpos = 0
          adCanvas.SetLayer(9, {TargetRect: {x: 0, y: 0, w: 0, h: 0}, CompositionMode: "Source"})

          if m.skippableOverlay <> invalid
            m.skippableOverlay.setup()
          end if

          m.utils.trackEvent({
            trackType: "viewthru"
            adUnit: adUnit
            adPercentage: positionPercentage
            port: adPort
            })
        else if nowpos > 0
          if m.skippableOverlay <> invalid
            m.skippableOverlay.update(nowpos)
          end if

          if adUnit.totalOptions > 0 and adUnit.adBar[currOption].img <> ""
            filename = adUnit.adBar[currOption].img + "?" + RND(10000000).ToStr()
            adCanvas.SetLayer(10, {Url: filename, TargetRect: {x: 0 , y: 30, w: playerSettings.displaySize.w, h: 80}, CompositionMode: "Source_over" })
            adCanvas.Show()
          end if
          if abs(nowpos - lastSavedPos) > statusInterval and positionPercentage < 75
            lastSavedPos = nowpos
            positionPercentage = positionPercentage + 25
            if (positionPercentage < 100)
              m.utils.trackEvent({
                  adUnit: adUnit
                  trackType: "viewthru"
                  adPercentage: positionPercentage
                  port: adPort
                })
            end if
          end if

        end if
      '---------------------------------
      else if msg.isPartialResult()
        print "isPartialResult"
        status = "COMPLETED"
        print "partial"
        exit while

      '---------------------------------
      else if msg.isRequestFailed()
        print "Video(AD) request failure: "; msg.GetIndex(); " " msg.GetData(); " " msg.GetMessage(); " " msg.GetType()
        if (m.videoAdErrorCount < 2)
          m.videoAdErrorCount = m.videoAdErrorCount + 1
          player = CreateObject("roVideoPlayer")
          ' be sure to use the same message port for both the ad canvas and the player
          player.SetMessagePort(adCanvas.GetMessagePort())
          player.SetDestinationRect(adCanvas.GetCanvasRect())
          player.SetPositionNotificationPeriod(1)
          player.AddContent(adUnit)
          player.Play()
        else
          m.utils.trackEvent({
            trackType: "adFailure"
            value: adUnit.streams[0].url 'the ad url
            ctx: msg.GetMessage()
            port: m.playerPort
          })
          exit while
        end if

      '---------------------------------
      else if msg.isStatusMessage()
        if msg.GetMessage() = "start of play"
          ' once the video starts, clear out the ad canvas so it doesn't cover the video
          adCanvas.ClearLayer(2)
          adCanvas.SetLayer(1, {color: "#00000000", CompositionMode: "Source"})
          adCanvas.Show()
        end if
      end if
    end if
  end while

  player.Stop()
  adCanvas.close()
  return status
end function


