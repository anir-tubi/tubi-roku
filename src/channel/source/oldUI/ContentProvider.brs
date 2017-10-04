'used to populate content for the gridscreen and ultimately the detail/episode screens
function ContentProvider(pubId as String, shortAppName as String, imageSize as String, videoContentType = "hls" as String, appNameToFilter = "" as String, utils = "", showLinearTV = false)

  obj = {
    utils:                utils

    getPlaylist:          ContentProvider_getPlaylist
    getAllPlaylistsCount: ContentProvider_getAllPlaylistsCount
    getEpisodeInPlaylist: ContentProvider_getChildItem
    getChildItem:         ContentProvider_getChildItem
    getEpisodeFromServer: ContentProvider_getEpisodeFromServer
    getUpdatedUrlForEpisode: ContentProvider_getUpdatedUrlForEpisode
    getPlaylistLength:    ContentProvider_getPlaylistLength
    getPlaylistFromXmlObj: ContentProvider_getPlaylistFromXmlObj
    prependPlaylistToPlaylists: ContentProvider_prependPlaylistToPlaylists
    getAllPlaylistsFromServer: ContentProvider_getAllPlaylistsFromServer
    getContentFromLocalPlaylists: ContentProvider_getContentFromLocalPlaylists
    getSeriesFromServer: ContentProvider_getSeriesFromServer
    getAllEpisodesForPlaylistFromServer: ContentProvider_getAllEpisodesForPlaylistFromServer
    getSavedUserContentFromMemory: ContentProvider_getSavedUserContentFromMemory
    setUrlsWithContentType: ContentProvider_setUrlsWithContentType
    getBookmarksAndPreviouslyViewedFromServer: ContentProvider_getBookmarksAndPreviouslyViewedFromServer
    handleGetUserPlaylists: ContentProvider_handleGetUserPlaylists
    addBasicInfoToUserPlaylistHashes: ContentProvider_addBasicInfoToUserPlaylistHashes
    getFullUserPlaylistContent: ContentProvider_getFullUserPlaylistContent
    parseAndSavePreviouslyViewed: ContentProvider_parseAndSavePreviouslyViewed
    parseAndSaveBookmarks: ContentProvider_parseAndSaveBookmarks
    translateAndStore: ContentProvider_translateAndStore
    translate: ContentProvider_translate
    getNowPosFromLocalStore: ContentProvider_getNowPosFromLocalStore

    getEpisodeByPath : function(path)
      len = path.count()
      print "len " ; len
      pl = m.playlists[path[0]]

      for i=1 to len-1 step +1
        if(pl <> invalid)
          print "playlist " ; pl.name
        end if

        epArray = pl.episodes
        if epArray <> invalid
          pl = epArray[path[i]].playlist
        else
          print "pl not found"
        end if
      end for
      return curr
    end function


    ' everything below considered private
    pubId:  pubId
    isHD: utils.deviceInfo.displayType = "HDTV"

    ' server: "http://192.168.1.159:5000"
    server: "https://uapi.adrise.tv"

    shortAppName: shortAppName
    maxContent: 50    'max contents in each category for 256MB devices
    miniMaxCountent: 25

    imageSize: imageSize

    path: []
    autoplayId : 0
    autoplayIsSeries: false
    autoplayIsSeason: false


    appNameToFilter: appNameToFilter

    playlists: invalid ' array of objects, with members "name" and "episodes"
    showLinearTV: showLinearTV    'true if linear tv is turned on
    linearTvAdded: false   'is set to true after linear tv is turned on in the first row so linear tv doesn't appear in series episodes lists
    
    'initialize playlists generated from saved user info (ie. a bookmarks playlist and previously viewed playlist)
    savedUserContent: invalid
    userPlaylists: {
      bookmarks: {
        name: "Bookmarks"
        depth: 0
        videosPrelim: {}
        seriesPrelim: {}
        episodes: []
        videosIdString: ""
        isLoaded: false
      }
      previous: {
        name: "Previously Viewed"
        depth: 0
        videosPrelim: {}
        seriesPrelim: {}
        episodes: []
        videosIdString: ""
        isLoaded: false
      }
    }

    userPlaylistVideos: {}
    userPlaylistSeries: {}

    isRegWall: false
    regWallContent: []

    allowAfterHours: true
	}

  obj.setUrlsWithContentType(videoContentType)
	return obj
end function


function _isUrl(s)
  i = Instr(1, s, "http://")
  if i = 1
    return true
  else
    return false
  end if
end function


'--------------- method: setContentType() ----------
function ContentProvider_setUrlsWithContentType(contentType as String)
  version = m.utils.deviceInfo.firmwareVersion
  major = Int(version)
  if major = 3
    contentType = "mp4"
  else
    contentType = "hls"
  end if

  model = m.utils.deviceInfo.model
  authInfo = m.utils.getAuthInfo()

  userIdQueryString = ""
  if authInfo.userId <> invalid
    userIdQueryString = "&user_id=" + authInfo.userId
  end if

  deviceIdQueryString = "&device_id=" + m.utils.deviceInfo.deviceId

  m.urls = {
    getPlaylists: m.server + "/legacy_cms/v2/app/xml?platform=roku&model=" + model + userIdQueryString + deviceIdQueryString
    getVideos: m.server + "/legacy_cms/v2/videos/xml?platform=roku" + userIdQueryString + deviceIdQueryString + "&content_ids="
  }
End Function

'--------- method: getPlaylist() ----------
function ContentProvider_getPlaylist(index as Integer) as Object
	if m.playlists = invalid
	  m.getAllPlaylistsFromServer()
  end if

  if m.playlists <> invalid and index < m.playlists.count()
    return m.playlists[index]
  else
    return invalid
  end if

end function

'--------- method: getChildItem() ----------
function ContentProvider_getChildItem (playlist as Object, itemIndex as Integer) as Object
  if playlist <> invalid
    if playlist.haveAllEpisodes = invalid
      m.getAllEpisodesForPlaylistFromServer(playlist, "gridscreen")
    end if

    if itemIndex < playlist.episodes.count()
      episode = playlist.episodes[itemIndex]
      return episode
    end if
  end if

  return invalid
end function

'--------- method: getPlaylistLength() ----------
function ContentProvider_getPlaylistLength (playlist as Object) as Integer
  if playlist.episodes = invalid
    return 0
  end if
  return playlist.episodes.count()
end function

'--------- method: getEpisodeFromServer() ----------
function ContentProvider_GetEpisodeFromServer(videoId as String) as Object
	xml = m.utils.getXml(m.urls.getVideos + videoId, "getEpisode_v2", true)
	if xml = invalid or xml.GetName() <> "videos"
    return invalid
  end if

  'returns a roXml object
  return xml.video
end function


'--------- method: getUpdatedUrlForEpisode() ----------
function ContentProvider_getUpdatedUrlForEpisode(episode as Object) as Object
  'get roXml object
  if episode.id <> invalid and (type(episode.id) = "roString" or type(episode.id) = "String")
    episodeFromServer = m.getEpisodeFromServer(episode.id)

    if type(episodeFromServer) = "roXMLList" and episodeFromServer.url.getText().len() > 0
      episode.streams = [{url: episodeFromServer.url.getText()}]
    end if
  end if

  return episode
end function


'--------- ContentProvider_getAllPlaylistsFromServer() ----------
function ContentProvider_getAllPlaylistsFromServer()

  xml = m.utils.getXml(m.urls.getPlaylists, "getApp_v2", true)

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
      if child.title.getText() <> "After Hours" or m.allowAfterHours = true
      	m.path[0] = m.playlistCounter + rowOffset

        m.playlists.push(m.getPlaylistFromXmlObj(child, m.imageSize, 1, invalid, "gridscreen"))
        m.playlistCounter = m.playlistCounter + 1
      end if
    end for
  end if
end function

'--------- ContentProvider_getAllPlaylistsCount() ----------
function ContentProvider_getAllPlaylistsCount()
  if m.playlists <> invalid
    return m.playlists.Count()
  end if
  return 0
end function

'----------- ContentProvider_getPlaylistFromXmlObj()----------
'each playlist corresponds to a category or row on Roku grid screen
function ContentProvider_getPlaylistFromXmlObj(obj, imageSize, depth, parent, source)
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

    'limits the number of contents per category in the lower memory models (as defined in m.utils.deviceInfo)
    if m.utils.deviceInfo.lowMemory <> true or (m.playlistCounter > 10 and count < m.miniMaxCountent) or (m.playlistCounter <= 10 and count < m.maxContent)

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
        
        'set up autoplay for videos and series episodes(from deeplinking usually or maybe from search screen)
        if id = m.autoplayId
          p = []
          for i=0 to depth-1 step +1
           p[i] = m.path[i]
          end for
          p.push(count)
          m.autoplayId = invalid

          if m.autoplayIsSeason = false
            m.autoplayData = { item: item, path: p, depth: depth }
            print "have video autoplay---------------------"
          else if m.autoplayIsSeason = true
            m.autoplayData = { item: parent, path: p, depth: depth }
            print "have season autoplay---------------------"
          end if
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
        if(parent = invalid and id = m.autoplayId and m.autoplayIsSeries = true)
          p = []
          for i=0 to depth-1 step +1
            p[i] = m.path[i]
          end for
          p.push(count)
          m.autoplayData = { item: item, path: p, depth: depth }
          m.autoplayId = invalid
          print "have autoplay series ---------------------"
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

'--------- _contentProvider.getAllEpisodesForPlaylistFromServer() ----------
sub ContentProvider_getAllEpisodesForPlaylistFromServer (playlist, source)
    settings = m.utils.getSettings()

    if playlist.videosIdString = invalid or playlist.videosIdString = ""
      return
    end if

    'remove the leading comma if necessary (for bookmarks and previously viewed)
    if Left(playlist.videosIdString, 1) = ","
      playlist.videosIdString = playlist.videosIdString.mid(1)
    end if

    xml = m.utils.getXml(m.urls.getVideos + playlist.videosIdString, "getVideos_v2", true)

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

          if videoDetails.creditsCuepoint <> invalid and videoDetails.creditsCuepoint.getText() <> ""
            playlist.videosPrelim[xmlId].creditsCuepoint = Val(videoDetails.creditsCuepoint.getText())
          end if
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
          if videoDetails.nielsenGenre <> invalid
            playlist.videosPrelim[xmlId].nielsenGenre = videoDetails.nielsenGenre.getText()
          end if
          
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


          'if there is only one subtitle make it the default'
          if videoDetails.subtitles.count() = 1
            subtitles.default = videoDetails.subtitles.subtitle[0].language.getText()
            playlist.videosPrelim[xmlId].subtitleUrl = videoDetails.subtitles.subtitle[0].url.getText()
          end if


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

          ' streams = []
          ' for each rendition in videoDetails.renditions.rendition
          '   if (rendition.video_container.getText() <> invalid)
          '     playlist.videosPrelim[xmlId].streamFormat = LCase(ValidStr(rendition.video_container.getText()))
          '   end if

          '   newStream = {
          '     url:  ValidStr(rendition.url.getText())
          '   }
          '   bitrate = StrToI(ValidStr(rendition.total_bitrate_kbs.getText()))
          '   if (bitrate > 0)
          '     newStream.bitrate = bitrate
          '   end if
          '   height = StrToI(ValidStr(rendition.video_height.getText()))
          '   ' m.isHD and
          '   if height > 480
          '     if height > 720
          '       playlist.videosPrelim[xmlId].fullHD = true
          '     end if
          '     playlist.videosPrelim[xmlId].isHD = true
          '     playlist.videosPrelim[xmlId].hdBranded = true
          '     newStream.quality = true
          '   end if
          '   streams.Push(newStream)
          ' end for
          ' if streams.count() <> 0
          '   playlist.videosPrelim[xmlId].streams = streams
          ' end if

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

 end sub


'--------- _contentProvider.getContentFromLocalPlaylists() ----------
'iterate over all content in each playlist until we find the data for the series we are looking for
'returns the data for the series we want, as it's stored in the playlist
'@contentType: string, can be either "video" or "series"
function ContentProvider_getContentFromLocalPlaylists(contentId, contentType)
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
end function


'--------- _contentProvider.getSeriesFromServer() ----------
'make call to v4 API to get all the info (seasons, episodes) for a single series
'@seriesIds : array of series ids
function ContentProvider_getSeriesFromServer(seriesIds)
  if type(seriesIds) <> "roArray" and seriesIds.count() < 1
    return invalid
  end if

  settings = m.utils.getSettings()

  seriesIdsCommas = ""
  for each id in seriesIds
    if type(id) = "String" or type(id) = "roString"
      seriesIdsCommas = seriesIdsCommas + "0" + id + ","
    end if
  end for

  'remove last trailing comma
  seriesIdsCommas = Left(seriesIdsCommas, seriesIdsCommas.len()-1)

  seriesPort = CreateObject("roMessagePort")
  url = settings.cmsApiUrlBase + "&content_ids=" + seriesIdsCommas + "&page_enabled=false&fields=*(id,children)"
  requestId = m.utils.sendAsyncRequest(url, seriesPort, "getSeriesFromServer", "GET", true, invalid, invalid)

  series = invalid
  while true
    msg = wait(0, seriesPort)
    if type(msg) = "roUrlEvent"
      response = m.utils.getAsyncResponse(msg, 0)
      if response.data <> invalid and response.data.len() > 0 and response.responseCode = 200
        series = ParseJson(response.data)
      end if
      exit while
    end if
  end while

  return series
end function


'--------- _contentProvider.getSavedUserContentFromMemory() ----------
'get bookmarks and previously viewed info from registry memory
'this runs only at the time the gridscreen is built
function ContentProvider_getSavedUserContentFromMemory()

  'if we've already got the saved user content no need to touch memory again
  if m.savedUserContent <> invalid
    return m.savedUserContent
  end if

  settings = m.utils.getSettings()
  bookmarksReg = settings.bookmarkRegistry
  previousReg = settings.previouslyViewedRegistry

  bookmarks =  m.utils.getUserPlaylistContent(bookmarksReg)
  previous = m.utils.getUserPlaylistContent(previousReg)

  m.savedUserContent = {
    savedBookmarks: bookmarks
    savedPrevious: previous
  }

  return m.savedUserContent
end function

'--------- _contentProvider.prependPlaylist() ----------
sub ContentProvider_prependPlaylistToPlaylists(playlist)
  if m.playlists <> invalid
    m.playlists.Unshift(playlist)
  end if
end sub

'side effects of this function (and functions run by this function), end result is
'a hash map of videos (m.userPlaylistVideos) and series(m.userPlaylistSeries) that contain content info that the
'user playlists (bookmarks and previously viewed) will point to.
'-------------_contentProvider.getBookmarksAndPreviouslyViewedFromServer()------------
function ContentProvider_getBookmarksAndPreviouslyViewedFromServer()
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
          if bookmarkRetries >= 20 ' means max of 21 total attempts, one regular and 20 retries
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
          if previousRetries >= 20 ' means max of 21 total attempts, one regular and 20 retries
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


'-------------_contentProvider.handleGetUserPlaylists()------------
'@playlistType is a string that should be the content of either settings.bookmarkRegistry or settings.previouslyViewedRegistry
'@responseData is a JSON string that should be the response from the server when attempting to get the userPlaylist info
'returns the request id used to get the full content data for the content ids contained in responseData
' function ContentProvider_handleGetUserPlaylists(playlistType, responseData, port)
function ContentProvider_handleGetUserPlaylists(playlistType, responseData)
  settings = m.utils.getSettings()

  basicsFromServer = invalid
  if responseData <> invalid and responseData.len() > 0
    basicsFromServer = ParseJson(responseData)
  end if

  'populate the m.userPlaylistVideo and m.userPlaylistSeries hashes so as to prime them with the server's bookmark and history ids
  m.addBasicInfoToUserPlaylistHashes(basicsFromServer, playlistType)
  
  return getFullUserPlaylistRequestId

end function



'-------------_contentProvider.addBasicInfoToUserPlaylistHashes()------------
'primes the m.userPlaylistVideos and m.userPlaylistSeries hash maps with serverBookmarkId and serverPreviouslyViewedId as necessary
function ContentProvider_addBasicInfoToUserPlaylistHashes(basicsFromServer, userPlaylistType)
  settings = m.utils.getSettings()
  if basicsFromServer <> invalid and basicsFromServer.items <> invalid and userPlaylistType <> invalid
    for each content in basicsFromServer.items
      serverIdType = invalid
      if userPlaylistType = settings.bookmarkRegistry
        serverIdType = "bookmarksServerId"
      else if userPlaylistType = settings.previouslyViewedRegistry
        serverIdType = "previouslyViewedServerId"
      end if

      if serverIdType <> invalid
        if content.content_type = "movie" or content.content_type = "video"
          if m.userPlaylistVideos[content.content_id.toStr()] = invalid
            m.userPlaylistVideos[content.content_id.toStr()] = {}
          end if
          m.userPlaylistVideos[content.content_id.toStr()][serverIdType] = content.id
        else if content.content_type = "series"
          if m.userPlaylistSeries[content.content_id.toStr()] = invalid
            m.userPlaylistSeries[content.content_id.toStr()] = {}
          end if
          m.userPlaylistSeries[content.content_id.toStr()][serverIdType] = content.id
        end if
      end if
    end for
  end if
end function


'-------------_contentProvider.getFullUserPlaylistContent()------------
'make a request for the full content information for each bookmark or previouslyViewed
'we listen for the response in getBookmarksAndPreviouslyViewedFromServer
function ContentProvider_getFullUserPlaylistContent(basicsFromServer, playlistType, port)
  settings = m.utils.getSettings()
  if basicsFromServer <> invalid and basicsFromServer.len() > 0
    basicsFromServer = ParseJson(basicsFromServer)
  else
    return invalid
  end if

  requestId = invalid

  if basicsFromServer <> invalid
    if basicsFromServer.total_count > 0
      basicItems = basicsFromServer.items '[]'

      ids = ""
      for each item in basicItems

        if item.content_type = "series"
          id = "0" + item.content_id.toStr()
        else if item.content_type = "movie" or item.content_type = "video"
          id = item.content_id.toStr()
        end if

        ids = ids + "," + id
      end for
      ids = Right(ids, ids.len()-1)

      url = settings.cmsApiUrlBase + "&content_ids=" + ids + "&page_enabled=false&fields=*(id,type,title,duration,ratings,description,year,posterarts,subtitles,lang,url,publisher_id,actors,directors,tags,children,credit_cuepoints)"
      requestId = m.utils.sendAsyncRequest(url, port, "getFull" + playlistType, "GET", true, invalid, invalid)
    end if
  end if

  return requestId
end function

'-------------_contentProvider.parseAndSavePreviouslyViewed()------------
'add the positions to the previously viewed full content, so we can parse it and add to our content stores later
'then do the actual parsing and saving
function ContentProvider_parseAndSavePreviouslyViewed(previouslyViewedFullFromServer, previouslyViewedBasicFromServer)
  if previouslyViewedFullFromServer <> invalid and previouslyViewedFullFromServer.len() > 0
    previouslyViewedFullFromServer = ParseJson(previouslyViewedFullFromServer)
  else
    return invalid
  end if

  if previouslyViewedBasicFromServer <> invalid and previouslyViewedBasicFromServer.len() > 0
    previouslyViewedBasicFromServer = ParseJson(previouslyViewedBasicFromServer)
  else
    return invalid
  end if    

  basicVideos = {}
  basicSeries = {}
  basicEpisodes = {}
  
  if previouslyViewedBasicFromServer <> invalid and previouslyViewedBasicFromServer.items <> invalid
    for each basicItem in previouslyViewedBasicFromServer.items
      if basicItem.content_type <> invalid and basicItem.content_id <> invalid
        basicItem.content_id = basicItem.content_id.toStr()
        if basicItem.content_type = "series"
          basicItem.content_id = "0" + basicItem.content_id

          'add the episodes to the basicEpiodes hash so we can easily access the position property later
          if basicItem.episodes <> invalid
            for each basicEpisode in basicItem.episodes
              basicEpisodes[basicEpisode.content_id.toStr()] = basicEpisode
            end for
          end if
        end if

        fullItem = previouslyViewedFullFromServer[basicItem.content_id]

        if fullItem <> invalid
          'add the nowPos and currentEpisode properties which will be parsed and added to the product stores
          if fullItem.type = "s"
            currentEpisodePosition = basicItem.position

            if basicItem.episodes[currentEpisodePosition].content_id <> invalid
              fullItem.currentEpisodeId = basicItem.episodes[currentEpisodePosition].content_id.toStr()
            end if
            
            if fullItem.children <> invalid
              for each season in fullItem.children
                if season.children <> invalid
                  for each episode in season.children
                    if episode.id <> invalid and basicEpisodes[episode.id.toStr()] <> invalid
                        episode.nowPos = basicEpisodes[episode.id.toStr()].position
                    end if
                  end for
                end if
              end for
            end if

          else if fullItem.type = "v" and basicItem.position <> invalid
            fullItem.nowPos = basicItem.position
          end if
      
          fullItem.isPreviouslyViewed = true
          translatedContent = m.translateAndStore(fullItem, invalid, invalid)
          m.userPlaylists.previous.episodes.push(translatedContent)
        end if
      end if
    end for

    return m.userPlaylists.previous.episodes
  end if

  return invalid

end function


'-------------_contentProvider.parseAndSaveBookmarks()------------
function ContentProvider_parseAndSaveBookmarks(bookmarksFullFromServer, basicBookmarks)
  if bookmarksFullFromServer <> invalid and bookmarksFullFromServer.len() > 0
    bookmarksFullFromServer = ParseJson(bookmarksFullFromServer)
  else
    return invalid
  end if

  if basicBookmarks <> invalid and basicBookmarks.len() > 0
    basicBookmarks = ParseJson(basicBookmarks)
  else
    return invalid
  end if  

  if basicBookmarks <> invalid and basicBookmarks.items <> invalid
    'store all the full bookmark content but keep the basic bookmark content order
    for each basicContent in basicBookmarks.items
      if basicContent <> invalid and basicContent.content_id <> invalid and basicContent.content_type <> invalid
        basicContent.content_id = basicContent.content_id.toStr()
        if basicContent.content_type = "series"
          basicContent.content_id = "0" + basicContent.content_id
        end if
        if bookmarksFullFromServer[basicContent.content_id] <> invalid
          fullBookmarkInfo = bookmarksFullFromServer[basicContent.content_id]
          
          'add the content to our local series and video hash stores
          fullBookmarkInfo.isBookmark = true
          translatedContent = m.translateAndStore(fullBookmarkInfo, invalid, invalid)
          m.userPlaylists.bookmarks.episodes.push(translatedContent)
        else
          'remove the initially stored info in the user playlist stores (since we 'primed' them already)
          if basicContent.content_type = "series"
            m.userPlaylistSeries.delete(basicContent.content_id)
          else
            m.userPlaylistVideos.delete(basicContent.content_id)
          end if
        end if
      end if

    end for
    return m.userPlaylists.bookmarks.episodes
  end if

  return invalid
end function


'-------------_contentProvider.translateAndStore()------------
'this function also stores videos and series into m.userPlaylists so we have one source of truth to reference for
'series and videos that come from previously viewed or bookmarks. This ensures that videos/series that show up in multiple categories 
'are only stored one time.
'@parentId and @parentType should be invalid for videos and series
function ContentProvider_translateAndStore(contentFromServer, parentId, parentType)
  'if we have a video or a series, save the translated content to the state.content.store if it doesn't exist there yet.
  'then return a reference to the stored content in state.content.store

  typeVar = "type"  'type is a reserved word so need to jump through hoops to acces any property named 'type'
  if contentFromServer <> invalid
    if contentFromServer[typeVar] = "v"
      store = m.userPlaylistVideos
    else if contentFromServer[typeVar] = "s"
      store = m.userPlaylistSeries
    else
      'not a video or series, so don't store anything just translate and return what was translated
      return m.translate(contentFromServer, parentId, parentType)
    end if  
    
    translatedContent = m.translate(contentFromServer, parentId, parentType)
      
    if translatedContent <> invalid
      'if the content doesn't yet exist in our store .... this shouldn't happen
      'we should have at least something with a bookmarksServerId or previouslyViewedServerId already
      if store[contentFromServer.id] = invalid
        print "ERROR: We translated content that didn't already exist in our user playlists videos or previously viewed hashes."

      'if the content DOES exist in our store, then add on to / overwrite it's properties
      'Do this in case the content exists in both bookmarks and previously viewed. if bookmarks is translated first, when the same content is
      'translated for previously viewed, we just want to add the played-to position in the existing video object in the hash map
      else
        for each property in translatedContent
          store[contentFromServer.id][property] = translatedContent[property]
        end for
      end if
      
      return store[contentFromServer.id]
    end if

  else
    return invalid
  end if
end function


'-------------_contentProvider.translate()------------
'this is a recursive function that does the heavy lifting for translateContentFromServer
function ContentProvider_translate(contentFromServer, parentId, parentType)
  translatedContent = {}
  typeVar = "type"
  if contentFromServer <> invalid
    if contentFromServer[typeVar] <> invalid
      if contentFromServer[typeVar] = "c"
        translatedContent[typeVar] = "category"
      else if contentFromServer[typeVar] = "v"
        translatedContent[typeVar] = "video"
      else if contentFromServer[typeVar] = "s"
        translatedContent[typeVar] = "level"
      else if contentFromServer[typeVar] = "a"
        translatedContent[typeVar] = "level"
      end if
    end if

    'record keeping needed for adding series to bookmarks and previously viewed
    if parentId <> invalid
      translatedContent.parentId = parentId
      translatedContent.isParentSeries = true
    else
      translatedContent.isParentSeries = false
    end if 
    if parentType <> invalid then translatedContent.parentType = parentType

    'translate all the stuff from the server
    if contentFromServer.duration <> invalid then translatedContent.length = contentFromServer.duration
    if contentFromServer.actors <> invalid then translatedContent.actors = contentFromServer.actors 'array of actors
    if contentFromServer.tags <> invalid then translatedContent.genres = contentFromServer.tags 'array of genres
    if contentFromServer.lang <> invalid then translatedContent.language = contentFromServer.lang
    if contentFromServer.publisher_id <> invalid then translatedContent.pubId = contentFromServer.publisher_id
    if contentFromServer.country <> invalid then translatedContent.country = contentFromServer.country
    if contentFromServer.year <> invalid and contentFromServer.year <> 0 then translatedContent.releaseDate = contentFromServer.year.ToStr()
    if contentFromServer.isBookmark <> invalid then translatedContent.isBookmark = contentFromServer.isBookmark
    if contentFromServer.isPreviouslyViewed <> invalid then translatedContent.isPreviouslyViewed = contentFromServer.isPreviouslyViewed
    if contentFromServer.currentEpisodeId <> invalid then translatedContent.currentEpisodeId = contentFromServer.currentEpisodeId
    if contentFromServer.nowPos <> invalid then translatedContent.nowPos = contentFromServer.nowPos
    
    if contentFromServer.title <> invalid
      translatedContent.title = contentFromServer.title
      translatedContent.shortDescriptionLine1 = contentFromServer.title
    end if

    if contentFromServer.description <> invalid
      translatedContent.description = contentFromServer.description
      translatedContent.longDescription = contentFromServer.description
    end if
    
    if contentFromServer.id <> invalid
      translatedContent.id = contentFromServer.id
      translatedContent.adrise_contentId = contentFromServer.id
    end if

    if contentFromServer.directors <> invalid and contentFromServer.directors.count() > 0
      translatedContent.director = contentFromServer.directors[0]
    end if

    if contentFromServer.credit_cuepoints <> invalid
      if contentFromServer.credit_cuepoints.prologue <> invalid
        translatedContent.introCuepoint = contentFromServer.credit_cuepoints.prologue
      end if
      if contentFromServer.credit_cuepoints.postlude <> invalid
        translatedContent.creditsCuepoint = contentFromServer.credit_cuepoints.postlude
      end if

    end if

    if parentType <> invalid and contentFromServer.thumbnails <> invalid and type(contentFromServer.thumbnails) = "roArray" and contentFromServer.thumbnails.count() > 0
      translatedContent.hdposterurl = contentFromServer.thumbnails[0]
      translatedContent.sdposterurl = contentFromServer.thumbnails[0]
      translatedContent.thumbnailRatio = 1.1 'if > 1, use landscape image on details page - for series episodes
    else if contentFromServer.posterarts <> invalid and type(contentFromServer.posterarts) = "roArray" and contentFromServer.posterarts.count() > 0
      translatedContent.hdposterurl = contentFromServer.posterarts[0]
      translatedContent.sdposterurl = contentFromServer.posterarts[0]
      translatedContent.thumbnailRatio = 0.1 'if < 1, use landscape image on details page - for movies
    end if
    
    if contentFromServer.ratings <> invalid and contentFromServer.ratings[0] <> invalid and contentFromServer.ratings[0].value <> invalid
      translatedContent.rating = contentFromServer.ratings[0].value
    end if

    if contentFromServer.url <> invalid
      translatedContent.streams = [{url: contentFromServer.url}]
      translatedContent.url = contentFromServer.url
      if contentFromServer.url.instr(1,".m3u8") > 0
        translatedContent.streamformat = "hls"
      else if contentFromServer.url.instr(1,".mp4") > 0
        translatedContent.streamformat = "mp4"
      end if
    end if

    'take care of any subtitles if they exist - should only happen on videos
    if contentFromServer.subtitles <> invalid and type(contentFromServer.subtitles) = "roArray" and contentFromServer.subtitles.count() > 0
      translatedContent.subtitles = {}
      translatedContent.subtitles.languages = []
      for each subtitle in contentFromServer.subtitles
        translatedContent.subtitles.languages.push({
          url: subtitle.url
          name: subtitle.lang
        })
      end for
      
      'set the default subtitles if there is only one set of subtitles
      if translatedContent.subtitles.languages.count() = 1
        translatedContent.subtitles.default = translatedContent.subtitles.languages[0].url
        translatedContent.subtitleUrl = translatedContent.subtitles.languages[0].url
      end if
    end if

    'take care of any children the content might have
    if contentFromServer.children <> invalid and contentFromServer.children.count() > 0
      allTranslatedChildContents = []
      if parentId = invalid
        parentId = contentFromServer.id
      end if
      for each childContent in contentFromServer.children
        translatedChildContent = m.translate(childContent, parentId, translatedContent.type)
        allTranslatedChildContents.push(translatedChildContent)
      end for

      if translatedContent.type = "category"
        translatedContent.contents = allTranslatedChildContents
      else if translatedContent.type = "level"
        translatedContent.playlist = {
          episodes: allTranslatedChildContents
          name: contentFromServer.title
          haveAllEpisodes: true
        }
      end if
        
    end if
  else
    return invalid
  end if

  return translatedContent
end function

'-------------_contentProvider.getNowPosFromLocalStore()------------
'given an episode (movie or series episode), returns the current nowPos for that episode
function ContentProvider_getNowPosFromLocalStore(episode)
  if episode.isParentSeries = true
    parentInStore = m.userPlaylistSeries[episode.parentId]
    if parentInStore <> invalid and parentInStore.playlist <> invalid and parentInStore.playlist.episodes <> invalid and parentInStore.playlist.episodes.count() > 0
      for each season in parentInStore.playlist.episodes
        if season.playlist <> invalid and season.playlist.episodes <> invalid and season.playlist.episodes.count() > 0
          for each child in season.playlist.episodes
            if child.id = episode.id
              if child.nowPos <> invalid
                return child.nowPos
              end if
              exit for
            end if
          end for
        end if
      end for
    end if
  else 'it is a video
    if episode.id <> invalid
      episodeInStore = m.userPlaylistVideos[episode.id]
      if episodeInStore <> invalid and episodeInStore.nowPos <> invalid
        return episodeInStore.nowPos
      end if
    end if
  end if

  return invalid

end function
