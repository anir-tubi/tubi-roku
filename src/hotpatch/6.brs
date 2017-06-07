print "Hot Patch 6"
if m.app.settings.shortAppName = "tubitv"
  deviceInfo = CreateObject("roDeviceInfo")
  firmware = deviceInfo.GetVersion()
  firmwareVersion = Val(Mid(firmware, 3, 4))

  if firmwareVersion <= 3.01

    '//////////////////////////////////////////////////////////////////'
    '//////////////////////////////////////////////////////////////////'
    '//////////////////////GRIDSCREEN//////////////////////////////////'
    '//////////////////////////////////////////////////////////////////'
    '//////////////////////////////////////////////////////////////////'
    m.app.gridScreen.show = function (selItem, cp, gridStyle)

      'show a spinning image while the grid screen loads
      messageDialog = CreateObject("roMessageDialog")
      ' messageDialog.Show()
      messageDialog.SetText("Tubi TV Is Loading...")
      messageDialog.ShowBusyAnimation()
      messageDialog.Show()

      m.cp = cp
      rokuGridScreen = CreateObject("roGridScreen")
      msgPort = CreateObject("roMessagePort")
      rokuGridScreen.SetMessagePort(msgPort)
      rokuGridScreen.SetDisplayMode("scale-to-fill")
      rokuGridScreen.SetGridStyle(gridStyle)
      m.rokuGridScreen = rokuGridScreen
      m.initGrid(m.rokuGridScreen, cp)
      m.utils.portWaitStarting(msgPort)
    
      m.isShown = false
      m.showSearch = false
      m.isFocusSet = false
      m.playlistsCount = cp.getAllPlaylistsCount()

      if m.isShown = false    'should only happen the very first time the grid screen is entered
        selItem.listIndex = selItem.listIndex+m.rowOffset
      end if

      playlists =[]



    
      'get all episode data for each row/playlist
      rowNum = 0
      ' if m.isShown = false
      '   rowNum = 1
      ' end if

      while true
        if playlists[rowNum] = invalid or playlists[rowNum].data = invalid
          playlists[rowNum] = {
            data: cp.getPlaylist(rowNum)
          }

          if playlists[rowNum].data = invalid
            if cp.errorMessage <> invalid
               m.rokuGridScreen.Close()
               return false
            end if
    
            'should only happen on the last row when rowNum is greater than the number of playlists from CP
            playlists.delete(rowNum)
    
            'if there are no more rows, finishing building the previous couple rows and leave while loop (stop populating)
            if playlists[rowNum] = invalid or playlists[rowNum].data = invalid
              for i=0 to 2 step 1
                if playlists[rowNum - 3 + i] <> invalid and playlists[rowNum - 3 + i].data <> invalid and playlists[rowNum - 3 + i].isComplete = invalid
                  rokuGridScreen.SetContentListSubset(rowNum - 3 + i, playlists[rowNum - 3 + i].episodes, 8, playlists[rowNum - 3 + i].episodes.count() - 11)
                  playlists[rowNum - 3 + i].isComplete = true
                end if
              end for
              exit while
            end if

            exit while
          else
            'get all videos/shows for a category/playlist/row
            playlists[rowNum].episodes = m.populatePlaylistWithEpisodes(playlists[rowNum])
          end if

          'don't think this if statement is necessary, but left in for non tubi apps (just in case)
          if m.isShown = false 

            if gridStyle = "two-row-flat-landscape-custom"
              m.rokuGridScreen.SetDescriptionVisible(false)
            end if

            m.isShown = true
          end if

          m.rokuGridScreen.Show()

          'sets the focus on entering the grid screen to the appropriate row
          'Roku always defaults to 3rd item index, so setting focus for item has no effect
          if m.isFocusSet = false
            m.rokuGridScreen.SetFocusedListItem(selItem.listIndex, selItem.itemIndex)
            m.isFocusSet = true
          end if


          'close the spinning dialog if it's still open
          if messageDialog <> invalid
            messageDialog.close()
          end if

          'populate subset of episodes in each Roku category/row with video/show info 
          if playlists[rowNum].episodes.count() > 0
            if playlists[rowNum].isSubsetted = invalid or playlists[rowNum].isSubsetted <> true
              'populate first 11 episodes for the current row
              m.rokuGridScreen.SetContentListSubset(rowNum, playlists[rowNum].episodes, 0, 8)
              m.rokuGridScreen.SetContentListSubset(rowNum, playlists[rowNum].episodes, playlists[rowNum].episodes.count() - 3, 3)
              playlists[rowNum].isSubsetted = true
              'set the focus to the appropriate video in the list
              if rowNum = selItem.listIndex
                m.rokuGridScreen.SetListOffset(selItem.listIndex, selItem.itemIndex)
              end if
            end if
    
            'present a dialog for users of legacy devices in HD mode'
            if rowNum > 0 + m.rowOffset and rowNum < 2 + m.rowOffset
              deviceInfo2 = CreateObject("roDeviceInfo")
              displayMode = deviceInfo2.GetDisplayMode()
              if displayMode = "720p"
              ' if firmwareVersion <= 3.01 and m.app.utils.deviceInfo.displayMode = "720p"
                dialog = CreateObject("roMessageDialog")
                dialogMsgPort = CreateObject("roMessagePort")
                dialog.SetMessagePort(dialogMsgPort)
                title = "Tubi TV is not fully supported ..."
                message = "Tubi TV is not fully supported on your version of Roku device. You may switch to SD mode to see posters. Movies will still play properly in HD mode." + chr(10) + chr(10) + "Please update or upgrade your device, if possible." + chr(10) + chr(10) + "Tubi TV"
                dialog.SetTitle(title)
                dialog.SetText(message)
                dialog.AddButton(1, "OK")
                dialog.SetMenuTopLeft(true)
                dialog.EnableOverlay(true)
                dialog.EnableBackButton(true)
    
                dialog.Show()
    
                while true
                  msg = wait(0, dialogMsgPort) ' wait for an event
    
                  ' make sure the message we got is of the type we are expecting
                  if type(msg) = "roMessageDialogEvent"
                    if msg.isButtonPressed()
                      ' the user pressed a button on the roMessageDialog
                      ' the index of the button assigned in the AddButton() function
                      ' will correspond to the value returned by the event's GetIndex() function
                      buttonIndex = msg.GetIndex()
    
                      if buttonIndex = 1
                        dialog.Close()
                        exit while
                      end if
                    else if msg.isScreenClosed()
                      ' the user closed the screen, exit the while loop
                      exit while
                    end if
                  end if
                end while
              end if
            end if
    
            if rowNum > 2 + m.rowOffset
              if playlists[rowNum - 3].isComplete = invalid
                'fill in the remaining episodes in the row that is 3 rows above the current row
                m.rokuGridScreen.SetContentListSubset(rowNum-3, playlists[rowNum - 3].episodes, 8, playlists[rowNum - 3].episodes.count() - 11)
                playlists[rowNum - 3].isComplete = true
              end if
            end if
          end if
        end if

        'stop early if user selects something or exits
        status = m.checkForInput(selItem, msgPort, 10)

        if status.message = "selected"
          m.rokuGridScreen.Close()
          m.isFocusSet = false
          return true
        else if status.message = "exit"
          m.rokuGridScreen.Close()
          return false
        else if status.message = "focused"
          newCurrentRow = status.rowIndex
          'appropriately loads the row, row below, row above of a newly selected row
          m.loadOnNewFocus(newCurrentRow, playlists)
        end if

        if cp.autoplayData <> invalid
          rokuGridScreen.Close()
          m.isFocusSet = false
          return true
        end if

        rowNum = rowNum + 1
      end while
    
      ' loop until user selects something or exits
      while true
        status = m.checkForInput (selItem, msgPort, 0)
        if status.message = "exit"
            return false
        else if status.message = "selected"
          rokuGridScreen.Close()
          m.isFocusSet = false
          return true
        else if status.message = "focused"
          selItem.listIndex = status.rowIndex
          selItem.itemIndex = status.itemIndex
          newCurrentRow = status.rowIndex
          m.loadOnNewFocus(newCurrentRow, playlists)
        end if
      end while
    end function
  
    m.app.gridScreen.populatePlaylistWithEpisodes = function(playlist)
      'Populate a playlist/row with all the content needed to load that row
      colNum = 0
      episodes = []

      'get all videos/shows for a category/playlist/row
      while true
        episode = m.cp.getEpisodeInPlaylist(playlist.data, colNum)
        if episode = invalid
          exit while
        else
          episodes.push(episode)
        end if

        colNum = colNum + 1
      end while
      return episodes
    end function

    m.app.gridScreen.checkForInput = function(selItem, msgPort, time)
      status = {
        message: ""
      }
      msg = wait(time, msgPort)
      if msg <> invalid
        m.utils.setContext("gridScreen", selItem) 'think this doesn't do anything
        if type(msg) = "roGridScreenEvent"
          if msg.isScreenClosed()
            status.message = "exit"
          else if msg.isListItemSelected()
            ' status.itemIndex = msg.GetData()
            ' status.rowIndex = msg.GetIndex()
            selItem.listIndex = msg.GetIndex()
            selItem.itemIndex = msg.GetData()
            status.message = "selected"
          else if msg.isListItemFocused()
            status.message = "focused"
            status.itemIndex = msg.GetData()
            status.rowIndex = msg.GetIndex()
            ' print "FOCUSED ITEM----------------------"
            ' print status.rowIndex ; " " ; status.itemIndex
          end if
        end if
      end if
      return status
    end function


    m.app.gridScreen.loadOnNewFocus = function(newCurrentRow, playlists)

      'make sure you don't try to add to a row above the first or a row below the last
      if newCurrentRow > 1 and newCurrentRow < m.playlistsCount - 2
        for i=-1 to 1 step 1
          if playlists[newCurrentRow + i] = invalid
            playlist = {
              data: m.cp.getPlaylist(newCurrentRow + i)
            }
            playlists.setEntry(newCurrentRow + i, playlist) 
            playlists[newCurrentRow + i].episodes = m.populatePlaylistWithEpisodes(playlists[newCurrentRow + i])
          end if
        end for

        if playlists[newCurrentRow] = invalid or playlists[newCurrentRow].isSubsetted = invalid
          print "1: "; newCurrentRow 
          m.rokuGridScreen.SetContentListSubset(newCurrentRow, playlists[newCurrentRow].episodes, 0, 8)
          m.rokuGridScreen.SetContentListSubset(newCurrentRow, playlists[newCurrentRow].episodes, playlists[newCurrentRow].episodes.count() - 3, 3)
          playlists[newCurrentRow].isSubsetted = true
        end if

        if playlists[newCurrentRow + 1] = invalid or playlists[newCurrentRow + 1].isSubsetted = invalid
          print "2: "; newCurrentRow
          m.rokuGridScreen.SetContentListSubset(newCurrentRow + 1, playlists[newCurrentRow + 1].episodes, 0, 8)
          m.rokuGridScreen.SetContentListSubset(newCurrentRow + 1, playlists[newCurrentRow + 1].episodes, playlists[newCurrentRow + 1].episodes.count() - 3, 3)
          playlists[newCurrentRow + 1].isSubsetted = true
        end if

        if playlists[newCurrentRow] = invalid or playlists[newCurrentRow].isComplete = invalid
          print "3: "; newCurrentRow
          m.rokuGridScreen.SetContentListSubset(newCurrentRow, playlists[newCurrentRow].episodes, 8, playlists[newCurrentRow].episodes.count() - 11)
          playlists[newCurrentRow].isComplete = true
        end if

        if playlists[newCurrentRow + 1] = invalid or playlists[newCurrentRow + 1].isComplete = invalid
          print "4: "; newCurrentRow
          m.rokuGridScreen.SetContentListSubset(newCurrentRow + 1, playlists[newCurrentRow + 1].episodes, 8, playlists[newCurrentRow + 1].episodes.count() - 11)
          playlists[newCurrentRow + 1].isComplete = true
        end if

        if playlists[newCurrentRow - 1] = invalid or playlists[newCurrentRow - 1].isSubsetted = invalid
          print "5: "; newCurrentRow
          m.rokuGridScreen.SetContentListSubset(newCurrentRow - 1, playlists[newCurrentRow - 1].episodes, 0, 8)
          m.rokuGridScreen.SetContentListSubset(newCurrentRow - 1, playlists[newCurrentRow - 1].episodes, playlists[newCurrentRow - 1].episodes.count() - 3, 3)
          playlists[newCurrentRow - 1].isSubsetted = true
        end if

        if playlists[newCurrentRow - 1] = invalid or playlists[newCurrentRow - 1].isComplete = invalid
          print "6: "; newCurrentRow
          m.rokuGridScreen.SetContentListSubset(newCurrentRow - 1, playlists[newCurrentRow - 1].episodes, 8, playlists[newCurrentRow - 1].episodes.count() - 11)
          playlists[newCurrentRow - 1].isComplete = true
        end if
      end if
    end function

    m.app.gridScreen.showToolsRow = function(rokuGridScreen, cp)
      settings = m.utils.getSettings()
      ShowVarSimple(settings, "settings")
      if settings.registerWithTubi = true
        print "register with tubi"

        userData = m.utils.getUserData()

        if (userData = invalid)
          rs = m.utils.getRegisterScreen()
          isRegistered = rs.checkRegistration()
          print "isRegistered: " ; isRegistered
          if isRegistered = true
            userData = m.utils.getUserData()
          end if
        end if
        if (userData <> invalid)
          print "have user data"
        else
          print "no user data"
        end if

        if (userData = invalid)
          item1 = {
            type: "tubiLogin"
            sdposterurl: "http://cdn.adrise.com/hotpatches/roku/signup-portraitSD.jpg"
            hdposterurl: "http://cdn.adrise.com/hotpatches/roku/signup-portraitHD.jpg"
            title: "Sign up"
            description: "Click here to register with Tubi TV."
            }
        else
          item1 = {
            type: "tubiLogin"
            sdposterurl: "http://cdn.adrise.com/hotpatches/roku/signout-portraitSD.jpg"
            hdposterurl: "http://cdn.adrise.com/hotpatches/roku/signout-portraitHD.jpg"
            title: "Sign out"
            description: "You are signed in as " + userData.fn + " " + userData.ln + "." + chr(10) + " Click here to sign out from Tubi TV."
            }
        endif

        'add search "button" to top row
        searchItem = {
          type: "search"
          sdposterurl: "http://cdn.adrise.com/hotpatches/roku/search-portraitSD.jpg"
          hdposterurl: "http://cdn.adrise.com/hotpatches/roku/search-portraitHD.jpg"
          title: "Search " + settings.appName
          description: "Go to search screen."
        }
        if m.showSearch = true
          list = [item1, searchItem]
        else 
          list = [item1]
        end if
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
          name: "Tools"
        }
      end if

      'if the tools/register row hasn't yet been prepended to the playlists array, prepend it otherwise, overwrite it
      '(in case of previous logout or login)
      if m.cp.getPlaylist(0).episodes[0].type <> playlist.episodes[0].type
        m.cp.prependPlaylistToPlaylists(playlist)
      else
        if playlist <> invalid
          m.cp.playlists.shift()
          m.cp.prependPlaylistToPlaylists(playlist)
        end if
      end if 
    end function

    m.app.gridScreen.initGrid = function(rokuGridScreen as Object, cp as Object)
      names = []
      rowNum = 0
      listCount = 0

      if m.utils.getSettings().allowVezoSubscription or m.utils.getSettings().registerWithTubi
        m.rowOffset = 1
        names = ["Tools"]
        listCount = 1
      end if

      while true
        playlist = cp.getPlaylist(rowNum)
        if playlist <> invalid and playlist.name <> invalid
          if playlist.name <> "Tools"
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

      if m.rowOffset > 0
        m.showToolsRow(m.rokuGridScreen, cp)
      end if
    end function

    '//////////////////////////////////////////////////////////////////'
    '//////////////////////////////////////////////////////////////////'
    '//////////////////////CONTENT PROVIDER////////////////////////////'
    '//////////////////////////////////////////////////////////////////'
    '//////////////////////////////////////////////////////////////////'

    m.app.cp.getAllPlaylistsCount = function()
      if m.playlists.Count() <> invalid
        return m.playlists.Count()
      end if
      return 0
    end function

    m.app.cp.prependPlaylistToPlaylists = function(playlist)
      if m.playlists <> invalid
        m.playlists.Unshift(playlist)
      end if
    end function

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
          m.playlists.push(m.getPlaylistFromXmlObj(child, m.imageSize, 1))
          m.playlistCounter = m.playlistCounter + 1
        end for
      end if
    end function

    ' ////////////////////////////////////////////////////////////////////////////////
    ' ////////////////////////////////////////////////////////////////////////////////    
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

          m.playlists.push(m.getPlaylistFromXmlObj(child, m.imageSize, 1, "gridscreen"))
          m.playlistCounter = m.playlistCounter + 1
        end for
      end if
    end function

    'update to work with updated api (landscape gridscreen images)'
    m.app.cp.getPlaylistFromXmlObj = function(obj, imageSize, depth, source)
      title = ValidStr(obj.title.getText())
      videosIdString = ""
      items = []
      videos = {}
      children = obj.children.getChildElements()
      count = 0
      
      for each child in children  'child = level or video for a row/category/playlist

        id = child.id.getText()

        if child.getName() = "video"
          item = {
            type : "video"
            title: child.title.getText()
            id: id
            adrise_contentId: id
            position: count
          }

          videosIdString = videosIdString + "," + id
          items.push(item)
          
          'set up autoplay for videos (from deeplinking usually or maybe from search screen)
          if(id = m.autoplayId)
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
            type : "level"
            title: child.title.getText()
            description: child.description.getText()
            shortDescriptionLine1 : child.title.getText()
            'shortDescriptionLine2 : child.description.getText()
            hdposterurl: thumbUrl
            sdPosterURL: thumbUrl
            playlist: m.getPlaylistFromXmlObj(child, imageSize, depth+1, source)
          }
          items.push(item)

        end if
        count = count + 1
      end for

      'remove the leading comma in videosIdString
      videosIdString = videosIdString.mid(1)

      return {
        name: obj.title.getText()
        depth: depth
        episodes: items
        videosIdString: videosIdString
      }
    end function

    'update to work with updated api (landscape gridscreen images)'
    m.app.cp.getAllEpisodesForPlaylistFromServer = function(playlist, source)
      
    settings = m.utils.getSettings()

      if playlist.videosIdString = invalid or playlist.videosIdString = ""
        return invalid
      end if

      xml = m.utils.getXml(m.urls.getVideos + playlist.videosIdString, "getVideos_v2")

      defaultVideoPath = invalid
      defaultStaticPath = invalid

      splitter = CreateObject("roRegex", ",", "")
      if xml <> invalid and xml.video <> invalid
        for each videoDetails in xml.video
          xmlId = videoDetails.id.getText()

          for each video in playlist.episodes
            if xmlId <> invalid and xmlId <> "" and xmlId = video.adrise_contentId

              if source = "gridscreen"
                if settings.GridStyle = "Flat-16x9" 'setting images for landscape styled grid screen
                  if videoDetails.thumbnailUrl <> invalid
                    thumbUrl = videoDetails.thumbnailUrl.getText()
                  end if
                  if videoDetails.thumbnailRatio <> invalid
                    video.thumbnailRatio = val(videoDetails.thumbnailRatio.getText())
                  end if
                else 'setting images for portait (Flat-Movie) styled grid screen and one funny app that uses 'two-row-flat-landscape-custom' style
                  if videoDetails.posterartUrl <> invalid
                    thumbUrl = videoDetails.posterartUrl.getText()
                  end if
                  if videoDetails.posterartRatio <> invalid
                    video.thumbnailRatio = val(videoDetails.posterartRatio.getText())
                  end if
                end if
              else if source = "episode" 'playlist is for episode list screen
                if videoDetails.thumbnailUrl <> invalid
                  thumbUrl = videoDetails.thumbnailUrl.getText()
                end if
                if videoDetails.thumbnailRatio <> invalid
                  video.thumbnailRatio = val(videoDetails.thumbnailRatio.getText())
                end if
              else if source = "search" 'playlist is for search screen
                if videoDetails.posterartUrl <> invalid
                  thumbUrl = videoDetails.posterartUrl.getText()
                end if
                if videoDetails.posterartRatio <> invalid
                  video.thumbnailRatio = val(videoDetails.posterartRatio.getText())
                end if            
              end if

              if defaultStaticPath <> invalid and not _isUrl(thumbUrl)
                thumbUrl = defaultStaticPath + thumbUrl
                video.defaultStaticPath = defaultStaticPath
              end if
              video.sdPosterURL = thumbUrl
              video.hdPosterURL = thumbUrl
              video.description = ValidStr(videoDetails.description.getText())

              video.longDescription = video.description
              video.shortDescriptionLine1 = video.title
              ' video.shortDescriptionLine2 = video.description
              url = videoDetails.url.getText()
              if defaultVideoPath <> invalid and not _isUrl(url)
                url = defaultVideoPath + url
              end if

              video.url = url

              if videoDetails.rating <> invalid
                video.rating = videoDetails.rating.getText()
              end if
              if videoDetails.language <> invalid
                video.language = videoDetails.language.getText()
              end if
              if videoDetails.country <> invalid
                video.country = videoDetails.country.getText()
              end if
              if videoDetails.director <> invalid
                video.director = videoDetails.director.getText()
              end if
              if videoDetails.starring <> invalid
                video.actors = splitter.Split(videoDetails.starring.getText())
              end if
              if videoDetails.publisherId <> invalid
                video.pubId = videoDetails.publisherId.getText()
              end if
              if videoDetails.releaseDate <> invalid
                video.releaseDate = videoDetails.year.getText()
              end if
              if videoDetails.rentalPrice <> invalid
                video.rentalPrice = ValidStr(videoDetails.rentalPrice.getText())
                if video.rentalPrice = ""
                  video.rentalPrice = invalid
                end if
              end if

              video.length = Int(StrToI(ValidStr(videoDetails.duration.getText())))

              if (video.url.instr(1,".m3u8") > 1)
                video.streamFormat = "hls"
                video.streams = [{url: video.url}]
              else if (video.url.instr(1,".mp4") > 1)
                video.streamFormat = "mp4"
                video.streams = [{url: video.url}]
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
                  video.subtitleUrl = newSubtitle.url
                end if
                subtitles.languages.Push(newSubtitle)
              end for

              if subtitles.languages.count() <> 0
                video.subtitles = subtitles
              end if

              streams = []
              for each rendition in videoDetails.renditions.rendition
                if (rendition.video_container.getText() <> invalid)
                  video.streamFormat = LCase(ValidStr(rendition.video_container.getText()))
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
                    video.fullHD = true
                  end if
                  video.isHD = true
                  video.hdBranded = true
                  newStream.quality = true
                end if
                streams.Push(newStream)
              end for
              if streams.count() <> 0
                video.streams = streams
              end if

              'Get Any Regwall Info as Defined in Hotpatch'
              if m.isRegWall = true
                idAsInteger = val(xmlId)
                if m.regWallContent[idAsInteger] <> invalid
                  video.regWallType = m.regWallContent[idAsInteger]
                end if
              end if

              exit for
            end if
          end for
        end for

        playlist.haveAllEpisodes = true
      end if
     end function


    '//////////////////////////////////////////////////////////////////'
    '//////////////////////////////////////////////////////////////////'
    '////////////////////// EPISODE LIST SCREEN ///////////////////////'
    '//////////////////////////////////////////////////////////////////'
    '//////////////////////////////////////////////////////////////////'

    'update so getAllEpisodesForPlaylistFromServer works after api change
     m.app.episodeListScreen.show = function(playlist)
      ' showVarSimple(playlist, "playlist")
      if playlist.episodes[0].playlist.haveAllEpisodes <> true
        m.cp.getAllEpisodesForPlaylistFromServer(playlist, "episode")
      end if

      landscape = true

      port = CreateObject("roMessagePort")
      screen = CreateObject("roPosterScreen")
      'if appSettings.isLandscape = true

      thumbRatio = invalid

      if playlist.episodes.count() > 0
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

      child = m.cp.getChildItem(playlist, 0)
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

      m.utils.portWaitStarting(port)

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
          itemIndex = m.app.handleItemPicked(subList.playlist, itemIndex)
        else
          listIndex = invalid
          itemIndex =  m.autoplayItem1
          episode = m.cp.getChildItem(playlist, itemIndex)
          m.autoplayItem1 = invalid
          itemIndex = m.app.handleItemPicked(playlist, itemIndex)
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
              episode = m.cp.getChildItem(subList.playlist, itemIndex)
              itemIndex = m.app.handleItemPicked(subList.playlist, itemIndex)

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
              episode = m.cp.getChildItem(playlist, itemIndex)
              itemIndex = m.app.handleItemPicked(playlist, itemIndex)
            end if
            screen.SetFocusedListItem(itemIndex)
          end if
        end if
      end while
    end function


    'update getAllEpisodesForPlaylistFromServer so works after api change
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
    


    '//////////////////////////////////////////////////////////////////'
    '//////////////////////////////////////////////////////////////////'
    '////////////////////// PLAYER ////////////////////////////////////'
    '//////////////////////////////////////////////////////////////////'
    '//////////////////////////////////////////////////////////////////'

    'Brightline Start Position Ad "Pixel"
    m.app.player.ads.brightlineOnPosition = function(roVideoPlayerEvent)
      globalUtils = GetGlobalAA().app.utils
      adUnit = GetGlobalAA().app.player.ads.currentAdUnit
      statusInterval = adUnit.Duration.toInt() / 4
      lastSavedPos = adUnit.positionPoints.lastSavedPos
      positionPercentage = adUnit.positionPoints.positionPercentage
      nowPos = roVideoPlayerEvent.GetIndex()

      if nowPos = 0
        globalUtils.trackEvent({
          adUnit: adUnit
          trackType: "viewthru"
          adPercentage: positionPercentage
        })
      else if abs(nowPos - lastSavedPos) > statusInterval and positionPercentage < 75
        adUnit.positionPoints.lastSavedPos = nowpos
        adUnit.positionPoints.positionPercentage = positionPercentage + 25
        positionPercentage = positionPercentage + 25
        if (positionPercentage < 100)
          globalUtils.trackEvent({
              adUnit: adUnit
              trackType: "viewthru"
              adPercentage: positionPercentage
            })
        end if
      end if    
    end function
    
    m.app.player.ads.showVideoAd = function(canvas, adUnit, adDetails, playerSettings)
      m.currentAdUnit = adUnit

      if m.adIsLexusInteractive(adUnit)
        la = m.lexusAd(adUnit)
        la.setUpCanvas(true)
        la.paintCanvas()
        return la.doEventLoop()
      end if

      status = "COMPLETED"
      
      'check if ad is Brightline companion overlay type by checking if companionOverlay property exists
      'since Brighltine throws errors on 3.1 firmware, only serve Brightline ads on greater than 3.1 firmware
      di = CreateObject("roDeviceInfo")
      firmware = di.GetVersion()
      firmwareVersion = Val(Mid(firmware, 3, 4))
      major = Int(firmwareVersion)
      
      if (m.adIsBrightlineCompanionAd(adUnit) and major <> 3)
        print "DOES THE GLOBAL OBJECT HAVE THE ADS WHERE WE THINK????"
        print GetGlobalAA().app.player.ads
        ip = BL_InteractivePreroll()

        ip.Append({
          onVideoPlayerStreamStarted: adriseAds_brightlineOnStartWrapper
          onVideoPlayerFullResult: adriseAds_brightlineOnCompleteWrapper
          onVideoPlayerPlaybackPosition: GetGlobalAA().app.player.ads.brightlineOnPosition
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
      

      print "show video ad"
      'ShowVarSimple(adUnit, "ad")


      port = CreateObject("roMessagePort")
      canvas = CreateObject("roImageCanvas")
      canvas.SetMessagePort(port)

      m.utils.portWaitStarting(port)

      if type(adUnit) <> "roAssociativeArray"
        canvas.close()
        return "COMPLETED"
      end if

      player = CreateObject("roVideoPlayer")
      ' be sure to use the same message port for both the canvas and the player
      player.SetMessagePort(canvas.GetMessagePort())
      player.SetDestinationRect(canvas.GetCanvasRect())
      player.SetPositionNotificationPeriod(1)

      ' set up some messaging to display while the pre-roll buffers
      m.utils.showAdLoadingLayer(canvas, playerSettings.displaySize, adDetails.secondsLeft, adDetails.adCounter, adDetails.totalAds, playerSettings.background, playerSettings.fontColor, playerSettings.loadingurl)
      canvas.Show()

      m.utils.trackEvent({
        trackType:  "imp"
        adUnit: adUnit
        port: port
        })
      player.AddContent(adUnit)

      player.Play()
      print "play ad start"

      lastSavedPos   = 0
      positionPercentage = 0
      statusInterval = adUnit.Duration.toInt() / 4

      showImageOptions = {
        z: 10
        cMode: "Source_over"
        h: 80
        }

      if m.adIsSkippable(adUnit)
        m.skippable = m.createSkippableAd(canvas, m.utils)
      else
        m.skippable = invalid
      end if

      while true
        currOption = adUnit.currentOption
        msg = wait(0, canvas.GetMessagePort())
        respObj = m.utils.getAsyncResponse(msg, 0)

        result = m.preprocessAdMessage(msg, adUnit, canvas, player, port, positionPercentage)
        if(result <> invalid)
          return result
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

              if m.skippable <> invalid and m.skippable.time >= m.skippable.skipTime
                status = "COMPLETED"
                print "skipped ad"
                exit while
              end if

              if adUnit.totalOptions > 0
                filename = adUnit.adbarThanksImage + "?" + RND(10000000).ToStr()
                showImageOptions.mode = "1"
                m.utils.showImageOnCanvas(filename, canvas, showImageOptions)
                canvas.Show()

                ' multiple urls
                if adUnit.adBar[currOption].urls <> invalid
                  numUrls = adUnit.adBar[currOption].urls.count()
                  for each url in adUnit.adBar[currOption].urls
                    m.utils.sendAsyncRequest(url, invalid, "adSelectMultiple")
                  end for
                else if adUnit.adBar[currOption].url <> invalid
                  m.utils.sendAsyncRequest(adUnit.adBar[currOption].url, invalid, "adSelectSingle")
                end if

                ' disable future interactions:
                adUnit.totalOptions = 0
              end if
              m.selectableAds.handleAdClick(adUnit)
            else if (i = 4 or i = 5) ' left or right
              if (adUnit.totalOptions > 0)
                if i = 4
                  currOption = currOption-1
                else if i = 5
                  currOption = currOption+1
                end if
                if (currOption < adUnit.totalOptions and currOption >= 0)
                  filename = adUnit.adBar[currOption].img + "?" + RND(10000000).ToStr()
                  showImageOptions.mode = "2"
                  m.utils.showImageOnCanvas(filename, canvas, showImageOptions)
                  canvas.Show()
                  adUnit.currentOption = currOption
                end if
              end if
            else if (i = 2 or i = 0)
              ' Pressed Up
              player.Stop()
              canvas.close()
              status = "CLOSED"
              return status
            else if (i = 3)
              print "Pressed down"
            end if
          else if (msg.isScreenClosed())
            canvas.close()
            return status
          end if
        else if type(msg) = "roVideoPlayerEvent"
          if msg.isStreamStarted()
            print "stream started"

          else if msg.isStatusMessage() and msg.getMessage() = "startup progress"
             'm.paintCanvas()
              print "loading progress " ; (msg.GetIndex() / 10)

          '---------------------------------
          else if msg.isFullResult()
            if (m.videoAdErrorCount = 0)
              if (positionPercentage >= 75)
                m.utils.trackEvent({
                  trackType: "viewthru"
                  adUnit: adUnit
                  adPercentage: 100
                })
                canvas.close()
              end if
              exit while
            end if

          '---------------------------------
          else if msg.isPlaybackPosition()
            nowpos = msg.GetIndex()

            m.utils.globalMessageHandler(msg)
            if nowpos = 0
              canvas.SetLayer(9, {TargetRect: {x: 0, y: 0, w: 0, h: 0}, CompositionMode: "Source"})

              if m.skippable <> invalid
                m.skippable.setup()
              end if

              m.utils.trackEvent({
                trackType: "viewthru"
                adUnit: adUnit
                adPercentage: positionPercentage
                })
            else if nowpos > 0
              if m.skippable <> invalid
                m.skippable.update(nowpos)
              end if

              if adUnit.totalOptions > 0 and adUnit.adBar[currOption].img <> ""
                filename = adUnit.adBar[currOption].img + "?" + RND(10000000).ToStr()
                canvas.SetLayer(10, {Url: filename, TargetRect: {x: 0 , y: 30, w: playerSettings.displaySize.w, h: 80}, CompositionMode: "Source_over" })
                canvas.Show()
              end if
              if abs(nowpos - lastSavedPos) > statusInterval and positionPercentage < 75
                lastSavedPos = nowpos
                positionPercentage = positionPercentage + 25
                if (positionPercentage < 100)
                  m.utils.trackEvent({
                      adUnit: adUnit
                      trackType: "viewthru"
                      adPercentage: positionPercentage
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
            print "Video request failure: "; msg.GetIndex(); " " msg.GetData(); " " msg.GetMessage(); " " msg.GetType()
            if (m.videoAdErrorCount < 2)
              m.videoAdErrorCount = m.videoAdErrorCount + 1
              player = CreateObject("roVideoPlayer")
              ' be sure to use the same message port for both the canvas and the player
              player.SetMessagePort(canvas.GetMessagePort())
              player.SetDestinationRect(canvas.GetCanvasRect())
              player.SetPositionNotificationPeriod(1)
              player.AddContent(adUnit)
              player.Play()
            else
              m.utils.trackEvent({
                trackType: "videoFailure"
                contentId: episode.adrise_contentid
                errorMessage: msg.GetMessage()
              })
              exit while
            end if

          '---------------------------------
          else if msg.isStatusMessage()
            if msg.GetMessage() = "start of play"
              ' once the video starts, clear out the canvas so it doesn't cover the video
              canvas.ClearLayer(2)
              canvas.SetLayer(1, {color: "#00000000", CompositionMode: "Source"})
              canvas.Show()
            end if
          end if
        end if
      end while

      player.Stop()
      canvas.close()
      return status
    end function

  end if
end if