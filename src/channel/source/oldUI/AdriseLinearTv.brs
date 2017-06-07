function AdriseLinearTv(utils, player)
  return {
    utils: utils
    showLinearTv: true
    linearTvOn: false
    sdposterurl: "http://cdn.adrise.com/hotpatches/roku/LinearTV-beta-SD.jpg"
    hdposterurl: "http://cdn.adrise.com/hotpatches/roku/LinearTV-beta-HD.jpg"
    linearTvUrl: "http://cms.adrise.com/v3/livetv?cid=roku&platform=roku&id=tubitv"

    getCurrentEpisode: linearTv_getCurrentEpisode
    getLinearPlaylist: linearTv_getLinearPlaylist
    
    linearEpisodes: []
  }
end function

'---------------linearTv_getCurrentEpisode------------
'get the initial episode and start time depending on the time of day'
function linearTv_getCurrentEpisode(linearPlaylist)
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
  
  'default return if something goes wrong
  return {
    initialEpisodeIndex: invalid
    startTime: invalid
  }
end function

'-------------linearTv_getPlaylistFromLinearIds------------
'populates a playlist in a format as populated by ContentProvider_getPlaylistFromXmlObj
function linearTv_getLinearPlaylist()
  
  'populate linear episode list from API
  linearScheduleJson = m.utils.getTextFile(m.linearTvUrl, "getLinearSchedule")
  m.linearEpisodes = parseJson(linearScheduleJson)

  items = []
  videos = {}
  idString = ""
  count = 0

  'set up the playlist and return it
  for each episode in m.linearEpisodes
    if type(episode.id) = "Integer"
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
