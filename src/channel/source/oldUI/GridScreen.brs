function GridScreen (utils)
  return {
    rowOffset: 0
    isShown: false
    isLogoutButtonShown: false
    isFocusSet: false
    isShownAfterAutoPlay: false
    basicUserPlaylistData: invalid

    'create the roTimespan object to be used for 'on focus' tracking
    'we want to see if the user has focused on something for at least a second
    timer: CreateObject("roTimespan")
    focusCount: 0

    'keeps track of calls to get user playlist info
    httpIds: {}
    bookmarksRetryCount: 0
    previouslyViewedRetryCount: 0

    utils: utils
    populatePlaylistWithEpisodes: GridScreen_populatePlaylistWithEpisodes
    loadOnNewFocus: GridScreen_loadOnNewFocus
    clearSubsets: GridScreen_clearSubsets
    handleInput: GridScreen_handleInput
    showUserPlaylists: GridScreen_showUserPlaylists

    show: function (selItem, cp, gridStyle, showLinearTv)
      m.cp = cp
      settings = m.utils.getSettings()
      m.bookmarkRowNum = 2
      m.previouslyViewedRowNum = 1
      rokuGridScreen = CreateObject("roGridScreen")
      msgPort = CreateObject("roMessagePort")
      rokuGridScreen.SetMessagePort(msgPort)
      rokuGridScreen.SetDisplayMode("scale-to-fill")
      rokuGridScreen.SetGridStyle(gridStyle)
      m.rokuGridScreen = rokuGridScreen
      
      m.rokuGridScreen.Show()
      m.utils.trackEvent({
        trackType: "pageLoad"
        value: "/home"
        port: msgPort
      })

      'Get the bookmarks and the previously viewed content from server (queue and history)
      'but only the first time the grid screen loads once the user is logged in!
      if m.isLogoutButtonShown = false or m.isShownAfterAutoPlay = true
        m.basicUserPlaylistData = m.cp.getBookmarksAndPreviouslyViewedFromServer()
        m.isShownAfterAutoPlay = false
      end if
      
      m.initGrid(m.rokuGridScreen, cp)

      m.playlistsCount = cp.getAllPlaylistsCount()

      'sets the focus box on the gridscreen accounting for the 'Tools' row, if it exists
      'should only happen the very first time the grid screen is entered
      if m.isShown = false
        selItem.listIndex = selItem.listIndex+m.rowOffset
        m.isShown = true
      end if

      playlists =[]

      'get all episode data for each row/playlist
      rowNum = 0

      
      while true
        if rowNum = m.rowOffset + 2
          'before loading the 3rd/5th row (depending on if logged in), make the calls for the user playlists
          if m.basicUserPlaylistData <> invalid and m.basicUserPlaylistData.bookmarks <> invalid and m.cp.userPlaylists.bookmarks.isLoaded = false
            fullBookmarksId = m.cp.getFullUserPlaylistContent(m.basicUserPlaylistData.bookmarks, settings.bookmarkRegistry, msgPort)
            if fullBookmarksId <> invalid
              m.httpIds.fullBookmarksId = fullBookmarksId
            end if
          end if

          if m.basicUserPlaylistData <> invalid and m.basicUserPlaylistData.previouslyViewed <> invalid and m.cp.userPlaylists.previous.isLoaded = false
            fullPreviouslyViewedId = m.cp.getFullUserPlaylistContent(m.basicUserPlaylistData.previouslyViewed, settings.previouslyViewedRegistry, msgPort)
            if fullPreviouslyViewedId <> invalid
              m.httpIds.fullPreviouslyViewedId = fullPreviouslyViewedId
            end if
          end if
        end if

        if playlists[rowNum] = invalid
          playlists[rowNum] = cp.getPlaylist(rowNum)
        end if

        if playlists[rowNum] = invalid
          if cp.errorMessage <> invalid
            m.rokuGridScreen.Close()
            m.clearSubsets(playlists) 'needed so gridscreen will populate on re-entry
            return false
          end if

          'should only happen on the last row when rowNum is greater than the number of playlists from CP
          playlists.delete(rowNum)

          'if there are no more rows, finishing building the previous couple rows and leave while loop (stop populating)
          ' if playlists[rowNum] = invalid
          for i=0 to 2 step 1
            if playlists[rowNum - 3 + i] <> invalid and playlists[rowNum - 3 + i].isComplete <> true
              rokuGridScreen.SetContentListSubset(rowNum - 3 + i, playlists[rowNum - 3 + i].episodes, 8, playlists[rowNum - 3 + i].episodes.count() - 11)
              playlists[rowNum - 3 + i].isComplete = true
            end if
          end for
          exit while
          ' end if

          ' exit while
        else
          'get all videos/shows for a category/playlist/row
          playlists[rowNum].episodes = m.populatePlaylistWithEpisodes(playlists[rowNum])
        end if


        if gridStyle = "two-row-flat-landscape-custom"
          m.rokuGridScreen.SetDescriptionVisible(false)
        end if

        'load the current row first
        if m.isShown = true
          m.loadOnNewFocus(playlists, selItem)
        end if


        'sets the focus on entering the grid screen to the appropriate row and item
        if m.isFocusSet = false
          m.rokuGridScreen.SetFocusedListItem(selItem.listIndex, selItem.itemIndex)
          m.isFocusSet = true
        end if

        'populate subset of episodes in each Roku category/row with video/show info - but not queue or view history
        'we will populate view and queue history later when we get full info for the content in those categories
        if playlists[rowNum].episodes.count() > 0
          if playlists[rowNum].isSubsetted <> true
            'populate first 11 episodes for the current row
            m.rokuGridScreen.SetContentListSubset(rowNum, playlists[rowNum].episodes, 0, 8)
            m.rokuGridScreen.SetContentListSubset(rowNum, playlists[rowNum].episodes, playlists[rowNum].episodes.count() - 3, 3)
            playlists[rowNum].isSubsetted = true
            'set the focus to the appropriate video in the list
            if rowNum = selItem.listIndex
              m.rokuGridScreen.SetListOffset(selItem.listIndex, selItem.itemIndex)
            end if
          end if

          if rowNum > m.rowOffset
            if playlists[rowNum - m.rowOffset].isComplete <> true and playlists[rowNum - m.rowOffset].episodes.count() > 0
              'fill in the remaining episodes in the row that is 3 rows above the current row
              m.rokuGridScreen.SetContentListSubset(rowNum-m.rowOffset, playlists[rowNum - m.rowOffset].episodes, 8, playlists[rowNum - m.rowOffset].episodes.count() - 11)
              playlists[rowNum - m.rowOffset].isComplete = true
            end if
          end if
        end if

        'the gridscreen has been shown at least once
        m.isShown = true

        'stop early if user selects something or exits
        status = m.checkForInput(selItem, msgPort, 10, playlists)

        'do the appropriate action based on any remote input received
        inputResult = m.handleInput(status, rokuGridScreen, playlists, selItem, msgPort)
        if inputResult <> invalid
          m.clearSubsets(playlists)
          return inputResult
        end if

        if cp.autoplayData <> invalid
          rokuGridScreen.Close()
          m.isFocusSet = false
          m.isShownAfterAutoPlay = true
          m.clearSubsets(playlists)
          return true
        end if



        rowNum = rowNum + 1
      end while

      ' loop until user selects something or exits
      while true
        'stop early if user selects something or exits
        status = m.checkForInput(selItem, msgPort, 0, playlists)


        'do the appropriate action based on any remote input received'
        inputResult = m.handleInput(status, rokuGridScreen, playlists, selItem, msgPort)
        if inputResult <> invalid
          m.clearSubsets(playlists)
          return inputResult
        end if


      end while
    end function

    checkForInput: function (selItem, msgPort, time, playlists)
      settings = m.utils.getSettings()
      status = {
        message: ""
      }

      msg = wait(time, msgPort)

      if msg <> invalid
        'prevents build up of roUrlObjects from user tracking events
        'do not delete - prevents memory leaks even though we don't use respObj anywhere
        if type(msg) = "roUrlEvent"
          respObj = m.utils.getAsyncResponse(msg, 0)

          'check for and handle any responses for user user playlists from the content API
          if m.httpIds <> invalid
            if m.httpIds.fullBookmarksId <> invalid
              if respObj.id = m.httpIds.fullBookmarksId
                if respObj.responseCode >= 200 and respObj.responseCode < 300
                  bookmarkEpisodes = m.cp.parseAndSaveBookmarks(respObj.data, m.basicUserPlaylistData.bookmarks)

                  if bookmarkEpisodes <> invalid
                    m.cp.playlists[m.bookmarkRowNum].episodes = bookmarkEpisodes
                    m.cp.userPlaylists[settings.bookmarkRegistry].isLoaded = true
                  end if

                  bookmarkPlaylist = m.cp.getPlaylist(m.bookmarkRowNum)
                  if bookmarkPlaylist <> invalid and bookmarkPlaylist.episodes <> invalid
                    m.rokuGridScreen.SetContentList(m.bookmarkRowNum, bookmarkPlaylist.episodes)
                  end if
                else
                  'retry
                  if m.bookmarksRetryCount < 20
                    fullBookmarksId = m.cp.getFullUserPlaylistContent(m.basicUserPlaylistData.bookmarks, settings.bookmarkRegistry, msgPort)
                    if fullBookmarksId <> invalid
                      m.httpIds.fullBookmarksId = fullBookmarksId
                    end if
                    m.bookmarksRetryCount = m.bookmarksRetryCount + 1
                  end if
                end if
              end if
            end if

            if m.httpIds.fullPreviouslyViewedId <> invalid
              if respObj.id = m.httpIds.fullPreviouslyViewedId

                if respObj.responseCode >= 200 and respObj.responseCode < 300
                  previouslyViewedEpisodes = m.cp.parseAndSavePreviouslyViewed(respObj.data, m.basicUserPlaylistData.previouslyViewed)

                  if previouslyViewedEpisodes <> invalid
                    m.cp.playlists[m.previouslyViewedRowNum].episodes = previouslyViewedEpisodes
                    m.cp.userPlaylists[settings.previouslyViewedRegistry].isLoaded = true
                  end if

                  previouslyViewedPlaylist = m.cp.getPlaylist(m.previouslyViewedRowNum)
                  if previouslyViewedPlaylist <> invalid and previouslyViewedPlaylist.episodes <> invalid
                    m.rokuGridScreen.SetContentList(m.previouslyViewedRowNum, previouslyViewedPlaylist.episodes)
                  end if
                else
                  'retry
                  if m.previouslyViewedRetryCount < 20
                    fullPreviouslyViewedId = m.cp.getFullUserPlaylistContent(m.basicUserPlaylistData.previouslyViewed, settings.previouslyViewedRegistry, msgPort)
                    if fullPreviouslyViewedId <> invalid
                      m.httpIds.fullPreviouslyViewedId = fullPreviouslyViewedId
                    end if
                    m.previouslyViewedRetryCount = m.previouslyViewedRetryCount + 1
                  end if
                end if
              end if              
            end if
          end if

        else if type(msg) = "roGridScreenEvent"

          if msg.isScreenClosed()
            status.message = "exit"
          else if msg.isListItemSelected()
            'no need to change selItem here because it already happens every time focus is set
            'plus there seems to be buggy behavior if we are in the top row of an app and we use the
            'isListItemSelected() version of msg.GetData()
            status.message = "selected"
          else if msg.isListItemFocused()
            m.focusCount = m.focusCount + 1
            status.message = "focused"
            selItem.listIndex = msg.GetIndex()
            selItem.itemIndex = msg.GetData()
            playlist = playlists[selItem.listIndex]
            if playlist <> invalid
              ' m.utils.trackEvent({
              '   trackType: "navigateInPage"
              '   value: m.focusCount
              '   ctx: "/home/" + (selItem.listIndex + 1).toStr() + "/cat/" + m.utils.sluggify(playlist.name) + "/1/" + (selItem.itemIndex + 1).toStr()
              '   port: msgPort
              ' })
              

            end if

          end if
        end if
      end if

      return status
    end function

    showToolsRow:  function (rokuGridScreen, cp)
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
            title: "Log In For Queue and Continue Watching Access"
            description: "Now you can access all the saved videos in your Queue and your Continue Watching lists from any Tubi TV device."
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
    end function

    'Sets the gridscreen with the appropriate number of rows and names for each rows
    'Determines if a Tools row is necessary and adds the 'Tools' name the first time the gridscreen is visited
    'This function is called every time a user navigates back to the gridscreen.
    'The 2nd time the gridscreen is generated, cp.playlists already exists (including the tools row)
    'and the 'Tools' name doesn't need to be pre added
    initGrid: function (rokuGridScreen as Object, cp as Object)
      settings = m.utils.getSettings()

      oldOffset = m.rowOffset
      m.rowOffset = 0
      names = []
      rowNum = 0
      listCount = 0
      hasBookmarks = false
      hasPreviouslyViewed = false

      'init the tools row
      if m.utils.getSettings().allowVezoSubscription or m.utils.getSettings().registerWithTubi
        m.rowOffset = m.rowOffset + 1
        names.push(settings.toolsRowName)
        listCount = listCount + 1
      end if

      basicBookmarksData = invalid
      basicPrevioulsyViewedData = invalid

      if m.basicUserPlaylistData <> invalid
        if m.basicUserPlaylistData.bookmarks <> invalid and m.cp.userPlaylists.bookmarks.isLoaded = false
          basicBookmarksData = ParseJson(m.basicUserPlaylistData.bookmarks)
        end if
        if m.basicUserPlaylistData.previouslyViewed <> invalid and m.cp.userPlaylists.previous.isLoaded = false
          basicPrevioulsyViewedData = ParseJson(m.basicUserPlaylistData.previouslyViewed)
        end if
      end if

      'init the previously viewed category
      if (basicPrevioulsyViewedData <> invalid and basicPrevioulsyViewedData.total_count <> invalid and basicPrevioulsyViewedData.total_count > 0) or (m.isLogoutButtonShown = true and m.cp.userPlaylists[settings.previouslyViewedRegistry].episodes.count() > 0)
        m.rowOffset = m.rowOffset + 1
        names.push(settings.previouslyViewedCatName)
        hasPreviouslyViewed = true
        listCount = listCount + 1
      else
        m.bookmarkRowNum = 1
      end if

      'init the bookmarks category
      if (basicBookmarksData <> invalid and basicBookmarksData.total_count <> invalid and basicBookmarksData.total_count > 0) or (m.isLogoutButtonShown = true and m.cp.userPlaylists[settings.bookmarkRegistry].episodes.count() > 0)
        m.rowOffset = m.rowOffset + 1
        names.push(settings.bookmarksCatName)
        hasBookmarks = true
        listCount = listCount + 1
      end if

      while true
        playlist = cp.getPlaylist(rowNum)
        if playlist <> invalid and playlist.name <> invalid
          if playlist.name <> settings.toolsRowName and playlist.name <> settings.previouslyViewedCatName and playlist.name <> settings.bookmarksCatName
            names.push(playlist.name)
            listCount = listCount + 1
          end if
        else
          exit while
        end if
        rowNum = rowNum + 1
      end while

      m.rokuGridScreen.SetupLists(listCount)
      m.rokuGridScreen.SetListNames(names)

      'removes all the specially added rows so that we can add them back on (if necessary)
      for i=1 to oldOffset step 1
        m.cp.playlists.shift()
      end for

      'add the user playlists rows the first time the grid screen is entered
      'add the bookmarks row
      if hasBookmarks = true
        m.showUserPlaylists(settings.bookmarkRegistry)
      end if

      'add the previously viewed row
      if hasPreviouslyViewed = true
        m.showUserPlaylists(settings.previouslyViewedRegistry)
      end if

      'add the tools row
      if names[0] = settings.toolsRowName
        m.showToolsRow(m.rokuGridScreen, cp)
      end if
    end function
  }
end function

function GridScreen_showUserPlaylists(playlistType)
  settings = m.utils.getSettings()
  
  if playlistType = settings.bookmarkRegistry
    catName = settings.bookmarksCatName
  else if playlistType = settings.previouslyViewedRegistry
    catName = settings.previouslyViewedCatName
  else
    return invalid
  end if

  playlist = {
    episodes: m.cp.userPlaylists[playlistType].episodes
    name: catName
  }
  m.cp.prependPlaylistToPlaylists(playlist)

end function

'Populate a playlist/row with all the content needed to load that row
function Gridscreen_populatePlaylistWithEpisodes(playlist)
  colNum = 0
  episodes = []

  'get all videos/shows for a category/playlist/row
  while true
    episode = m.cp.getEpisodeInPlaylist(playlist, colNum)
    if episode = invalid
      exit while
    else
      episodes.push(episode)
    end if

    colNum = colNum + 1
  end while
  return episodes
end function

'if a new row is focused on, check if a subset of the row has been populated, if not add subset
'additionally check if the row above and below the new row have been populated and add subset if necessary
'finally add the rest of the rows (new row and rows above and below)
'not necessarily in that order
function Gridscreen_loadOnNewFocus(playlists, selItem)
  newCurrentRow = selItem.listIndex  

  'make sure you don't try to add to a row above the first or a row below the last
  isLast = false
  if newCurrentRow = m.playlistsCount - 1
    isLast = true
  end if

  if newCurrentRow > 1
    for i=-1 to 1 step 1
      if newCurrentRow + i < m.playlistsCount
        if playlists[newCurrentRow + i] = invalid
          playlist = m.cp.getPlaylist(newCurrentRow + i)
          playlists.setEntry(newCurrentRow + i, playlist) 
          playlists[newCurrentRow + i].episodes = m.populatePlaylistWithEpisodes(playlists[newCurrentRow + i])
        end if
      end if
    end for

    if playlists[newCurrentRow].isSubsetted <> true
      m.utils.log.info(invalid, "clientInfo", "1: current-row-not-subsetted-on-new-focus", newCurrentRow)
      m.rokuGridScreen.SetContentListSubset(newCurrentRow, playlists[newCurrentRow].episodes, 0, 8)
      m.rokuGridScreen.SetContentListSubset(newCurrentRow, playlists[newCurrentRow].episodes, playlists[newCurrentRow].episodes.count() - 3, 3)
      m.rokuGridScreen.SetListOffset(selItem.listIndex, selItem.itemIndex)
      playlists[newCurrentRow].isSubsetted = true
    end if

    if isLast = false and playlists[newCurrentRow + 1].isSubsetted <> true
      m.utils.log.info(invalid, "clientInfo", "2: next-row-not-subsetted-on-new-focus", newCurrentRow)
      m.rokuGridScreen.SetContentListSubset(newCurrentRow + 1, playlists[newCurrentRow + 1].episodes, 0, 8)
      m.rokuGridScreen.SetContentListSubset(newCurrentRow + 1, playlists[newCurrentRow + 1].episodes, playlists[newCurrentRow + 1].episodes.count() - 3, 3)
      playlists[newCurrentRow + 1].isSubsetted = true
    end if

    if playlists[newCurrentRow].isComplete <> true 
      m.utils.log.info(invalid, "clientInfo", "3: current-row-not-complete-on-new-focus", newCurrentRow)
      m.rokuGridScreen.SetContentListSubset(newCurrentRow, playlists[newCurrentRow].episodes, 8, playlists[newCurrentRow].episodes.count() - 11)
      playlists[newCurrentRow].isComplete = true
    end if

    if isLast = false and playlists[newCurrentRow + 1].isComplete <> true
      m.utils.log.info(invalid, "clientInfo", "4: next-row-not-complete-on-new-focus", newCurrentRow)
      m.rokuGridScreen.SetContentListSubset(newCurrentRow + 1, playlists[newCurrentRow + 1].episodes, 8, playlists[newCurrentRow + 1].episodes.count() - 11)
      playlists[newCurrentRow + 1].isComplete = true
    end if

    if playlists[newCurrentRow - 1].isSubsetted <> true
      m.utils.log.info(invalid, "clientInfo", "5: previous-row-not-subsetted-on-new-focus", newCurrentRow)
      m.rokuGridScreen.SetContentListSubset(newCurrentRow - 1, playlists[newCurrentRow - 1].episodes, 0, 8)
      m.rokuGridScreen.SetContentListSubset(newCurrentRow - 1, playlists[newCurrentRow - 1].episodes, playlists[newCurrentRow - 1].episodes.count() - 3, 3)
      playlists[newCurrentRow - 1].isSubsetted = true
    end if

    if playlists[newCurrentRow - 1].isComplete <> true
      m.utils.log.info(invalid, "clientInfo", "6: current-row-not-complete-on-new-focus", newCurrentRow)
      m.rokuGridScreen.SetContentListSubset(newCurrentRow - 1, playlists[newCurrentRow - 1].episodes, 8, playlists[newCurrentRow - 1].episodes.count() - 11)
      playlists[newCurrentRow - 1].isComplete = true
    end if

  end if
end function

function GridScreen_clearSubsets(playlists)
  for each playlist in playlists
    if playlist <> invalid
      playlist.isSubsetted = false
      playlist.isComplete = false
    end if
  end for
end function

function GridScreen_handleInput(status, gridscreenObj, playlists, selItem, msgPort)
  if status.message <> ""
    if status.message = "selected"
      gridscreenObj.Close()
      m.clearSubsets(playlists) 'needed so gridscreen will populate on re-entry
      m.isFocusSet = false
      return true
    else if status.message = "exit"
      gridscreenObj.Close()
      return false
    else if status.message = "focused"
      'since there are 2 automatic focuses the first time a user enters the gridscreen
      'we need to keep track that we don't send them as user events
      m.focusCount = m.focusCount + 1

      'appropriately loads the row, row below, row above of a newly selected row
      m.loadOnNewFocus(playlists, selItem)
      
    end if
  end if
  return invalid
end function        
