function EpisodeListScreen(cp, appSettings, utils)
  return {
    cp: cp
    appSettings: appSettings
    utils: utils
    show: EpisodeListScreen_show
    autoPlay: function(series, item1, item2, isSeason)
			m.autoplayItem1 = item1
			m.autoplayItem2 = item2
      m.autoplayIsSeason = isSeason
			m.show(series)
		end function

    set2Level: EpisodeListScreen_set2Level
    getActiveEpisode: EpisodeListScreen_getActiveEpisode
    getActiveContent: EpisodeListScreen_getActiveContent
    episodePort: CreateObject("roMessagePort")
  }
end function

function EpisodeListScreen_show(series)
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
    m.set2Level(screen, invalid, invalid, series)
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
  		m.set2Level(screen, listIndex, itemIndex, series)
  	  subList = m.cp.getChildItem(playlist, listIndex)
			m.autoplayItem1 = invalid
			m.autoplayItem2 = invalid

      if m.autoplayIsSeason = false
			 itemIndex = GetGlobalAA().app.handleItemPicked(subList.playlist, listIndex, itemIndex, handleItemSource)
      end if

    else
  		itemIndex =  m.autoplayItem1
			m.autoplayItem1 = invalid
      m.set2Level(screen, listIndex, itemIndex, series)
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

        'setting item index here and after the m.set2Level call allows for deep linking to work accurately
        'while also letting the user's view history take affect.
        if itemIndex = 0
          itemIndex = invalid
        end if
        m.set2Level(screen, listIndex, itemIndex, series)
        itemIndex = 0

        ' 'populate the content for the season/playlist if we don't have it yet
        ' if playlist.episodes[listIndex].playlist.haveAllEpisodes <> true
        '   m.cp.getAllEpisodesForPlaylistFromServer(playlist.episodes[listIndex].playlist, "episode")
        ' end if

        ' 'if we are on the season that contains the 'current episode' then focus on it - otherwise focus on the first episode in the season
        ' activeEpisode = 0
        ' activeContent = m.getActiveContent(series)

        ' if listIndex = activeContent.season
        '   activeEpisode = activeContent.episode
        ' end if 

        ' screen.SetFocusedListItem(activeEpisode)
      else if msg.isListItemSelected()
        itemIndex = msg.getIndex()
        if(isTwoLevel)
          subList = m.cp.getChildItem(playlist, listIndex)
          newItemIndex = GetGlobalAA().app.handleItemPicked(subList.playlist, listIndex, itemIndex, handleItemSource)
          
          activeContent = m.getActiveContent(series, newItemIndex, listIndex)
          itemIndex = activeContent.episode
          listIndex = activeContent.season

          'after detail screen is closed (revealing episodeListScreen again), update progress bars
          ' eps = playlist.episodes[listIndex].playlist.episodes
          ' if eps <> invalid
          '   screen.SetContentList(eps)
          '   activeEpisode = m.getActiveEpisode(eps)
          '   if activeEpisode = -1
          '     activeEpisode = 0
          '   else if activeEpisode >= playlist.episodes.[listIndex].playlist.episodes.count()
          '     activeEpisode = 0
          '   end if
          '   screen.SetContentList(eps)
          ' end if

        else
          itemIndex = GetGlobalAA().app.handleItemPicked(playlist, listIndex, itemIndex, handleItemSource)
        end if
        screen.setFocusedList(listIndex)
        screen.SetFocusedListItem(itemIndex)
      end if
    end if
  end while
end function

function EpisodeListScreen_getActiveEpisode(episodes)
  best = -1
  count = 0
  for each item in episodes
    if item <> invalid and item.id <> invalid
      d = m.utils.getSavedContentData(item.id)
      if(d<>invalid and d.pos>30)
        item.BookmarkPosition = d.pos
        if d.pos < (item.length * .95)
          if best = -1
            best = count
          end if
        else
          best = count + 1
        end if
      end if
      count = count + 1
    end if
  end for
  return best
end function

function EpisodeListScreen_set2Level(screen, listIndex, itemIndex, series)
  playlist = series.playlist

  activeContent = m.getActiveContent(series, invalid, invalid)

  activeSeason = 0
  activeEpisode = 0

  if listIndex <> invalid
    activeSeason = listIndex

    if itemIndex <> invalid
      activeEpisode = itemIndex

    'if we are on the season that contains the 'current episode' then focus on it - otherwise focus on the first episode in the season
    else if listIndex = activeContent.season
      activeEpisode = activeContent.episode
    end if
  
  else
    activeSeason = activeContent.season
    activeEpisode = activeContent.episode
  end if

  'get the content for all the episodes if it doesn't already exist
  if playlist.episodes[activeSeason].playlist.haveAllEpisodes <> true
    m.cp.getAllEpisodesForPlaylistFromServer(playlist.episodes[activeSeason].playlist, "episode")
  end if
  episodes = playlist.episodes[activeSeason].playlist.episodes

  'set the season names on the screen
  listNames = []
  for each item in playlist.episodes
    listNames.push(item.title)
  end for

  screen.SetListNames(listNames)

  'set the starting episode and season
  screen.SetContentList(episodes)
  screen.SetFocusedListItem(activeEpisode)

  'set the appropriate season
  'this will not have any effect if seasonsCounter is equal to the currently focused list
  'this will trigger a roPosterEvent in EpisodeListScreen_show,
  'which will in turn find and set the appropriate episode to focus on
  screen.setFocusedList(activeSeason)

end function

function EpisodeListScreen_getActiveContent(series, itemIndex, listIndex)

  'anonymous helper function that does all the appropriate checks when we want to advance 1 episode in a series
  findNextEpisode = function(series, activeEpisode, activeSeason)
    activeEpisode = activeEpisode + 1
    if activeEpisode = series.playlist.episodes[activeSeason].playlist.episodes.count()
      activeEpisode = 0
      'check if there is a next season
      if series.playlist.episodes[activeSeason + 1] <> invalid
        activeSeason = activeSeason + 1
      else
        'there is no next season so set the current season and current episode back to the very beggining of the series
        activeSeason = 0
      end if
    end if

    return {
      episode: activeEpisode
      season: activeSeason
    }
  end function


  'we're returning to the episode list screen after having entered a detail screen
  'we might be on the same episode whose details screen we entered, or we may have moved to another episode
  if itemIndex <> invalid and listIndex <> invalid

    'get the content for all the episodes in this season if it doesn't already exist
    if series.playlist.episodes[listIndex] <> invalid and series.playlist.episodes[listIndex].playlist.haveAllEpisodes <> true
      m.cp.getAllEpisodesForPlaylistFromServer(series.playlist.episodes[listIndex].playlist, "episode")
    end if

    episode = series.playlist.episodes[listIndex].playlist.episodes[itemIndex]
    
    if episode <> invalid
      episode.nowPos = m.cp.getNowPosFromLocalStore(episode)
  
      'if the user watched past the credit cue point advance the episode one
      if episode.creditsCuepoint <> invalid and episode.nowPos <> invalid and episode.nowPos > episode.creditsCuepoint

        newActiveContent = findNextEpisode(series, itemIndex, listIndex)

        'update the user playlist stores with the new current episode info
        m.cp.userPlaylistSeries[series.id].currentEpisode = newActiveContent.episode

        'if the user just watched passed the credits cuepoint on the last episode of a season,
        'get the content for all the episodes in the next season if it doesn't already exist
        if series.playlist.episodes[newActiveContent.season].playlist.haveAllEpisodes <> true
          m.cp.getAllEpisodesForPlaylistFromServer(series.playlist.episodes[newActiveContent.season].playlist, "episode")
        end if
        m.cp.userPlaylistSeries[series.id].currentEpisodeId = series.playlist.episodes.[newActiveContent.season].playlist.episodes[newActiveContent.episode].id

        return newActiveContent

      'otherwise, return the same indexes that we entered with
      else
        return {
          episode: itemIndex
          season: listIndex
        }
      end if
    end if
  end if


  'we're entering the episode list screen from the grid screen.
  'find the appropriate current episode based on the current episode id stored in the userPlaylist series store for the passed in series
  
  'in case a user is not looking at the user playlists
  currentEpisodeId = invalid
  if m.cp.userPlaylistSeries[series.id] <> invalid
    currentEpisodeId = m.cp.userPlaylistSeries[series.id].currentEpisodeId
  end if

  activeEpisode = 0
  activeSeason = 0

  if series <> invalid and series.playlist <> invalid and series.playlist.episodes <> invalid and series.playlist.episodes.count() > 0
    for i=0 to series.playlist.episodes.count()-1 step 1
      
      'get the content for all the episodes in this season if it doesn't already exist
      if series.playlist.episodes[i].playlist.haveAllEpisodes <> true
        m.cp.getAllEpisodesForPlaylistFromServer(series.playlist.episodes[i].playlist, "episode")
      end if

      season = series.playlist.episodes[i]
      if season.playlist <> invalid and season.playlist.episodes <> invalid and season.playlist.episodes.count() > 0
        for j=0 to season.playlist.episodes.count()-1 step 1
          episode = season.playlist.episodes[j]

          if currentEpisodeId = invalid 'will happen if user selects series that is not in the previously viewed store
            'add the series to the previoulsy viewed store and add the currentEpisodeId
            m.cp.userPlaylistSeries[series.id] = series
            m.cp.userPlaylistSeries[series.id].currentEpisodeId = episode.id
            m.cp.userPlaylistSeries[series.id].nowPos = 0
            currentEpisodeId = episode.id

          else if episode.id <> invalid and episode.id = currentEpisodeId
            'check if the nowPos for the current episode is beyond the credits cuepoint for the current episode
            'and move the current episode forward if necessary
            episode.nowPos = m.cp.getNowPosFromLocalStore(episode)

            if episode.creditsCuepoint <> invalid and episode.nowPos <> invalid and episode.nowPos > episode.creditsCuepoint
              activeEpisode = activeEpisode + 1
              
              if activeEpisode = series.playlist.episodes[i].playlist.episodes.count()
                activeEpisode = 0
                'check if there is a next season
                if series.playlist.episodes[i + 1] <> invalid
                  activeSeason = i + 1
                else
                  'there is no next season so set the current season and current episode back to the very beggining of the series
                  activeSeason = 0
                end if
              end if
            end if


            'update the user playlist stores with the new current episode info
            m.cp.userPlaylistSeries[series.id].currentEpisode = activeEpisode

            'if the user just watched passed the credits cuepoint on the last episode of a season,
            'get the content for all the episodes in the next season if it doesn't already exist
            if series.playlist.episodes[activeSeason].playlist.haveAllEpisodes <> true
              m.cp.getAllEpisodesForPlaylistFromServer(series.playlist.episodes[activeSeason].playlist, "episode")
            end if
            m.cp.userPlaylistSeries[series.id].currentEpisodeId = series.playlist.episodes.[activeSeason].playlist.episodes[activeEpisode].id

            return {
              episode: activeEpisode
              season: activeSeason
            } 
          end if
        
          activeEpisode = activeEpisode + 1
        end for
      end if

      activeSeason = activeSeason + 1
      activeEpisode = 0
    end for
  end if
  
  'default return values
  return {
    episode: 0
    season: 0
  }

end function
