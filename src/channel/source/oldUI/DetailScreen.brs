function DetailScreen (cp, settings, utils, player)

  return {
    pingRentServer: DetailScreen_pingRentServer
    showRentDialog: DetailScreen_showRentDialog
    update: DetailScreen_update
    updateButtons: DetailScreen_updateButtons
    showCaptionsDialog: DetailScreen_showCaptionsDialog
    episodeWithLongDescription: DetailScreen_episodeWithLongDescription
    moveForwardBackward : DetailScreen_moveForwardBackward
    saveBookmark: DetailScreen_saveBookmark
    removeBookmarkOrPreviouslyViewed: DetailScreen_removeBookmarkOrPreviouslyViewed
    playPlaylist: DetailScreen_playPlaylist

    utils: utils
    settings: settings
    cp: cp
    player: player
    addBookmarkReqIds: {}
    detailsPort: CreateObject("roMessagePort")

    show: function(episode, playlist, itemIndex)

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

      'play deeplinked content
      if m.cp.autoplayData <> invalid
        m.cp.autoplayData = invalid
        itemIndex = m.playPlaylist(screen, playlist, episode, itemIndex, maxIndex)
      end if

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
                  itemIndex = m.playPlaylist(screen, playlist, episode, itemIndex, maxIndex)
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
  }
end function


function DetailScreen_playPlaylist(screen, playlist, episode, itemIndex, maxIndex)
  showRentButton = (m.settings.allowRentals=true)

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
  return itemIndex
end function


'------------------------------------------------------------------
function DetailScreen_episodeWithLongDescription (episode)
  newEpisodeObj = {}
	for Each n In episode
    newEpisodeObj[n] = episode[n]
  end For
	newEpisodeObj.description = episode.longDescription
	return newEpisodeObj
end function

'------------------------------------------------------------------
function DetailScreen_moveForwardBackward (itemIndex as Integer, max as Integer, isForward as Boolean)
  if isForward = false
		if (itemIndex = 0)
		  itemIndex = max
		else
		  itemIndex = itemIndex - 1
		end if
	else
		if (itemIndex = max)
			itemIndex = 0
		else
			itemIndex = itemIndex + 1
		end if
  end if
  return itemIndex
end function

'------------------------------------------------------------------
function DetailScreen_updateButtons(screen as Object, episode as Object, showRentButton as Boolean)
  screen.ClearButtons()

  nowPos = m.cp.getNowPosFromLocalStore(episode)

  if(nowPos <> invalid and nowPos > 5)
    screen.AddButton(2, "Resume playing")
    screen.AddButton(1, "Play from start")
  else
    screen.AddButton(1, "Play")
  end if
  
  'can prevent rent buttons from showing by changing setting in builder
	if(showRentButton and episode.rentalPrice <> invalid)
	  screen.AddButton(3, "Rent for $" + episode.rentalPrice + ", ad-free")
	end if

  'add subtitles if they exist - episode.subtitles will be invalid if there are no subtitles (as determined in cp)
	if(m.utils.supportsSubtitles()=true and episode.subtitles <> invalid)
	  screen.AddButton(4, "Subtitles...")
	end if

  'add the Add to Bookmarks or Remove from Bookmarks button (only for tubitv)
  settings = m.utils.getSettings()
  if settings.showBookmarks = true 'will be invalid for all non tubitv apps

    authInfo = m.utils.getAuthInfo()
    'prevent the add or remove buttons from showing if the user is not logged in
    if authInfo.accessToken <> invalid
      'check if the content for this details page is saved as a bookmark and show the appropriate button
      if episode.isParentSeries = false and m.cp.userPlaylistVideos[episode.id] <> invalid and m.cp.userPlaylistVideos[episode.id].isBookmark = true
        screen.AddButton(6, "Remove from queue")
      else if episode.isParentSeries = true and m.cp.userPlaylistSeries[episode.parentId] <> invalid and m.cp.userPlaylistSeries[episode.parentId].isBookmark = true
        screen.AddButton(6, "Remove from queue")
      else
        screen.AddButton(5, "Add to queue")
      end if

      'check if the content for this details page is in our previously viewed and show the appropriate button
      if episode.isParentSeries = false and m.cp.userPlaylistVideos[episode.id] <> invalid and m.cp.userPlaylistVideos[episode.id].isPreviouslyViewed = true
        screen.AddButton(7, "Remove from history")
      else if episode.isParentSeries = true and m.cp.userPlaylistSeries[episode.parentId] <> invalid and m.cp.userPlaylistSeries[episode.parentId].isPreviouslyViewed = true
        screen.AddButton(7, "Remove from history")
      end if
    end if

  end if
end function

'------------------------------------------------------------------
function DetailScreen_pingRentServer(episode)
  if(episode.pubId <> invalid AND episode.pubId <> "")
    pubId = episode.pubId
  else
    pubId = m.player.getPubId()
  end if
  port = CreateObject("roMessagePort")

  rentButtonIndicator = ""
  print "RENT http://ads.adrise.tv/track/ppv.php?cid=" + episode.id + "&platform=roku&deviceid=" + m.utils.deviceInfo.deviceId + "&pubid=" + pubId + rentButtonIndicator
  m.utils.sendAsyncRequest("http://ads.adrise.tv/track/ppv.php?cid=" + episode.id + "&platform=roku&deviceid=" + m.utils.deviceInfo.deviceId + "&pubid=" + pubId + rentButtonIndicator, port, "rent")
end function

'------------------------------------------------------------------
function DetailScreen_update(screen as Object, episode as Object, showRentButton as Boolean, msgPort)

  episode.categories = []
  if m.settings.show_language = true and episode.language <> invalid
    episode.categories.push(episode.language)
  end if
  if m.settings.show_country = true and episode.country <> invalid
    episode.categories.push(episode.country)
  end if
  m.updateButtons(screen, episode, showRentButton)
  screen.SetContent(m.episodeWithLongDescription(episode))

  'send tracking information that the detail screen has been populated
  '(happens when screen is entered and if someone presses left/right to get to new conent on the details page)
  vidOrSeries = "video"
  if episode.isParentSeries = true
    vidOrSeries = "series"
  end if
  m.utils.trackEvent({
    trackType: "pageLoad"
    value: "/video/" + episode.id
    port: msgPort
  })
end function

'------------------------------------------------------------------
function DetailScreen_showRentDialog(episode)
    port = CreateObject("roMessagePort")
    dialog = CreateObject("roMessageDialog")
    dialog.SetMessagePort(port)

    if episode.rentalPrice <> invalid
      price = episode.rentalPrice
    else
      price = "0.99"
    end if

    m.pingRentServer(episode)

    'dialog.SetText("Watch '" + episode.title + "' ad-free for " + price + ".")
    'dialog.SetText("To rent, visit http://adrise.tv/rent on your computer, tablet or phone.")
    'dialog.SetText("You'll see this movie at the top of the list. Simply select it, and pay " + price + " to rent it for 24 hours.")
    'dialog.SetText("Then, watch the movie on your Roku ad-free.")
    dialog.SetText("Go to http://adrise.com/rent to rent this movie.")
    dialog.SetText("Then, watch the movie on your Roku ad-free.")
    dialog.AddButton(1, "ok")
    dialog.EnableBackButton(true)
    dialog.Show()

    while true
      dlgMsg = wait(0, port)

      if type(dlgMsg) = "roMessageDialogEvent"
        if dlgMsg.isButtonPressed()
          dialog.close()
          exit while
        end if
        if dlgMsg.isScreenClosed()
            exit while
        end if
      else
        resp = utils.getAsyncResponse (dlgMsg, 0)
        if(resp <> invalid and resp.data <> invalid)
           ' print resp
        end if
      end if
    end while
end function

'------------------------------------------------------------------
function DetailScreen_showCaptionsDialog(episode)
  port = CreateObject("roMessagePort")
  dialog = CreateObject("roMessageDialog")
  dialog.SetMessagePort(port)

  deviceInfo = CreateObject("roDeviceInfo")
  globalCaptions = deviceInfo.GetCaptionsMode()

  'if we have subtitles set the appropriate text
  if episode.subtitles <> invalid and episode.subtitles.languages <> invalid
    dialog.SetText("Set subtitles for " + episode.title)
    languages = episode.subtitles.languages

    curr = episode.subtitles.default
    if episode.subtitles.current <> invalid
      curr = episode.subtitles.current
    end if

    currIndex = 0
    if languages.count() = 1
      dialog.AddButton(0, "Off")
      dialog.AddButton(1, "Instant replay")
      dialog.AddButton(2, "On")
      if curr = languages[0].name
        currIndex = 2
      end if

    else
      dialog.AddButton(0, "No subtitles")
      dialog.AddButton(1, "Instant replay")
      count = 2
      For Each n In languages
        dialog.AddButton(count, n.name)
        if curr = n.name
          currIndex = count
        end if
        count = count + 1
      end for
    end if

    'makes sure that the highlighted selection always starts at off if episode.showSubtitles is currently set to false
    'in other words, the initial selection will be what the current state is
    if globalCaptions = "Off"
      currIndex = 0
    else if globalCaptions = "Instant replay"
      currIndex = 1
    end if

  'there are no captions/subtitles so let the user know - this should only happen if user presses star while watching content
  else
    dialog.SetText("Sorry, there are no captions available for this video.")
    dialog.AddButton(0, "Ok")
    currIndex = 0
  end if

  dialog.SetFocusedMenuItem(currIndex)

  dialog.EnableBackButton(true)
  dialog.EnableOverlay(true)
  dialog.Show()

  while true
    dlgMsg = wait(0, port)

    if type(dlgMsg) = "roMessageDialogEvent"
      if dlgMsg.isButtonPressed()
        buttonIndex = dlgMsg.GetIndex()
        if buttonIndex = 0
          deviceInfo.setCaptionsMode("Off")

          m.utils.trackEvent({
            trackType: "subtitles"
            ctx: episode.id
            value: "off"
            port: m.detailsPort
          })

          m.utils.log.info(m.detailsPort, "clientInfo", "subtitles-off", "Subtitles disabled")
        else if buttonIndex = 1
          deviceInfo.setCaptionsMode("Instant replay")
          m.utils.log.info(m.detailsPort, "clientInfo", "subtitles-off", "Subtitles set to Instant replay")
        else
          episode.subtitles.current = episode.subtitles.languages[buttonIndex-2].name
          episode.subtitleUrl = episode.subtitles.languages[buttonIndex-2].url
          deviceInfo.setCaptionsMode("On")

          m.utils.trackEvent({
            trackType: "subtitles"
            ctx: episode.id
            value: "on"
            port: m.detailsPort
          })

          m.utils.log.info(m.detailsPort, "clientInfo", "subtitles-off", "Subtitles set to " + episode.subtitles.current)
        end if
        return deviceInfo.GetCaptionsMode()
      end if

      if dlgMsg.isScreenClosed()
        return deviceInfo.GetCaptionsMode()
      end if
    end if
  end while
end function

function DetailScreen_saveBookmark(episode, msgPort)
  settings = m.utils.getSettings()

  'get the content type of the episode
  if episode.isParentSeries = true
    contentType = "series"
    serverContentType = contentType
    idToCheck = episode.parentId
    contentToAdd = m.cp.getContentFromLocalPlaylists(episode.parentId, "series")
    bookmarkId = "s" + idToCheck
  else
    contentType = "video"
    serverContentType = "movie"
    idToCheck = episode.id
    contentToAdd = episode
    bookmarkId = "v" + idToCheck
  end if

  'send the bookmark to the server
  addBookmarkReqId = m.utils.updateBookmarks(idToCheck, "add", serverContentType, msgPort)
  'save the request id so that when we are listening for responses, we can check to see if we indeed received a response for an addBookmark call
  if addBookmarkReqId <> invalid
    m.addBookmarkReqIds[addBookmarkReqId.toStr()] = true
  end if 

  'add bookmark data to the appropriate userPlaylist stores if it doesn't already exist
  contentToAdd.isBookmark = true
  if contentType = "video"
    if m.cp.userPlaylistVideos[idToCheck] = invalid
      m.cp.userPlaylistVideos[idToCheck] = contentToAdd
    else
      m.cp.userPlaylistVideos[idToCheck].isBookmark = true
    end if
  else if contentType = "series"
    if m.cp.userPlaylistSeries[idToCheck] = invalid
      m.cp.userPlaylistSeries[idToCheck] = contentToAdd
    else
      m.cp.userPlaylistSeries[idToCheck].isBookmark = true
    end if
  end if

  'don't add if .isLoaded = false, otherwise we get multiples of the same content when deep linking
  if m.cp.userPlaylists[settings.bookmarkRegistry].isLoaded = true
    'add the bookmark data to the Bookmark category playlist (as a reference to the userPlaylist stores)
    m.cp.userPlaylists[settings.bookmarkRegistry].episodes.unshift(contentToAdd)
  end if

  'changing the "Add to Queue" button to say "Remove from Queue" happens after this function completes

  m.utils.trackEvent({
    trackType: "addBookmark"
    value: idToCheck
    ctx: "/video/" + episode.id
    port: msgPort
  })
  return true
end function

function DetailScreen_removeBookmarkOrPreviouslyViewed(episode, playlistType, msgPort)
  settings = m.utils.getSettings()

  if playlistType = settings.bookmarkRegistry
    isInPlaylist = "isBookmark"
    requestType = "updateBookmarks"
    contentServerIdType = "bookmarksServerId"
    categoryName = settings.bookmarksCatName
    trackType = "deleteBookmark"
  else if playlistType = settings.previouslyViewedRegistry
    isInPlaylist = "isPreviouslyViewed"
    requestType = "updatePreviouslyViewed"
    contentServerIdType = "previouslyViewedServerId"
    categoryName = settings.previouslyViewedCatName
    trackType = "deletePreviouslyViewed"
  else
    return false
  end if

  'get the content type of the episode
  if episode.isParentSeries = true
    contentType = "series"
    serverContentType = contentType
    idToCheck = episode.parentId
    idToSave = "s" + episode.parentId
  else
    contentType = "video"
    serverContentType = "movie"
    idToCheck = episode.id
    idToSave = "v" + episode.id
  end if

  'set isBookmark/isPreviouslyViewed to false in local data stores (m.cp.userPlaylistVideos, m.cp.userPlaylistSeries)
  'so detail screen will recognize that this content is no longer being bookmarked
  contentServerId = invalid
  if contentType = "series"
    'fail/ignore the delete button press if the content is not a bookmark/previouslyViewed or doesn't have a contentServerId
    if m.cp.userPlaylistSeries[idToCheck] = invalid or m.cp.userPlaylistSeries[idToCheck][isInPlaylist] <> true or m.cp.userPlaylistSeries[idToCheck][contentServerIdType] = invalid
      return false
    end if
      
    m.cp.userPlaylistSeries[idToCheck][isInPlaylist] = false
    contentServerId = m.cp.userPlaylistSeries[idToCheck][contentServerIdType]
  else if contentType = "video"
    'fail/ignore the delete button press if the content is not a bookmark or doesn't have a contentServerId
    if m.cp.userPlaylistVideos[idToCheck] = invalid or m.cp.userPlaylistVideos[idToCheck][isInPlaylist] <> true or m.cp.userPlaylistVideos[idToCheck][contentServerIdType] = invalid
      return false
    end if
    
    m.cp.userPlaylistVideos[idToCheck][isInPlaylist] = false
    contentServerId = m.cp.userPlaylistVideos[idToCheck][contentServerIdType]
  end if

  'send request to server to delete the bookmark/previouslyViewed
  if playlistType = settings.bookmarkRegistry
    deleteBookmarkReqId = m.utils.updateBookmarks(contentServerId, "delete", serverContentType, msgPort)
  else if playlistType = settings.previouslyViewedRegistry
    deletePreviouslyViewedReqId = m.utils.updatePreviouslyViewed(contentServerId, invalid, invalid, "delete", invalid, msgPort)
  end if

  'iterate over all content in the active bookmarks/previoulsy viewed playlist and remove the right one
  count = 0
  for each item in m.cp.userPlaylists[playlistType].episodes
    if item.id = idToCheck
      m.cp.userPlaylists[playlistType].episodes.delete(count)
      exit for
    end if
    count = count + 1    
  end for

  if trackType = "deleteBookmark"
    m.utils.trackEvent({
      trackType: trackType
      value: idToCheck
      port: msgPort
    })
  end if

  return true
end function
