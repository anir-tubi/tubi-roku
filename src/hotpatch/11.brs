print "Hot Patch 11"

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


m.app.player.ads.isRokuAdFrameworkOn = false
m.app.player.useCustomPlayer = true

if m.app.settings.shortAppName = "tubitv"
  
  'use to change the theme (the theme details are above), ie. headers and background colors
  ' m.app.utils.appManager.setTheme(theme)

  m.app.linearTv.showLinearTv = true
  m.app.cp.showLinearTv = true

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


  'fix issue so that user playlists get fully loaded (no longer show empty posters)
  m.app.gridscreen.show = function(selItem, cp, gridStyle, showLinearTv)

    m.cp = cp
    rokuGridScreen = CreateObject("roGridScreen")
    msgPort = CreateObject("roMessagePort")
    rokuGridScreen.SetMessagePort(msgPort)
    rokuGridScreen.SetDisplayMode("scale-to-fill")
    rokuGridScreen.SetGridStyle(gridStyle)
    m.rokuGridScreen = rokuGridScreen
    
    m.rokuGridScreen.Show()

    'Get the bookmarks and the previously viewed content from server (queue and history)
    'but only the first time the grid screen loads once the user is logged in!
    if m.isShownAfterLogin = false
      m.cp.getBookmarksAndPreviouslyViewedFromServer()
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
      if playlists[rowNum] = invalid
        playlists[rowNum] = cp.getPlaylist(rowNum)

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

        'populate subset of episodes in each Roku category/row with video/show info
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

          'populate the user rows since we already have the content for them
          if rowNum < m.rowOffset and playlists[rowNum].isComplete <> true
            rokuGridScreen.SetContentListSubset(rowNum, playlists[rowNum].episodes, 8, playlists[rowNum].episodes.count() - 11)
            playlists[rowNum].isComplete = true
          end if

          if rowNum > 2 + m.rowOffset
            ' if playlists[rowNum - 3].isComplete = invalid or playlists[rowNum - 3].isComplete <> true
            if playlists[rowNum - 3].isComplete <> true
              print "we complete row "; rowNum-3
              'fill in the remaining episodes in the row that is 3 rows above the current row
              rokuGridScreen.SetContentListSubset(rowNum-3, playlists[rowNum - 3].episodes, 8, playlists[rowNum - 3].episodes.count() - 11)
              playlists[rowNum - 3].isComplete = true
            end if
          end if
        end if
      end if

      ' print "playlists[rownum] "
      ' print playlists[rowNum]

      'the gridscreen has been shown at least once
      m.isShown = true

      'stop early if user selects something or exits
      status = m.checkForInput(selItem, msgPort, 10, playlists)

      'do the appropriate action based on any remote input received'
      inputResult = m.handleInput(status, rokuGridScreen, playlists, selItem, msgPort)
      if inputResult <> invalid
        return inputResult
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
      'stop early if user selects something or exits
      status = m.checkForInput(selItem, msgPort, 0, playlists)

      'do the appropriate action based on any remote input received'
      inputResult = m.handleInput(status, rokuGridScreen, playlists, selItem, msgPort)
      if inputResult <> invalid
        return inputResult
      end if

    end while
  end function

  'change the url to an external file hosted on cdn
  m.app.registerScreen.show = function(regWall = "")
      
      'necessary when calling the show() method from detail screen
      '(ie. for registration walls)
      if m.res = invalid
        m = GetGlobalAA().app.registerScreen
      end if

      m.isInitialScreen = true
      m.row = 5
      m.col = 0
      m.isComplete = false
      g = GetGlobalAA()

      m.canvas = CreateObject("roImageCanvas")
      port = CreateObject("roMessagePort")

      m.canvas.SetMessagePort(port)


      loadingImage = {
        Url: "http://cdn.adrise.com/hotpatches/roku/registerScreen/" + m.res +  "/bg_initial.jpg"
        TargetRect: m.getRect("bg", 0)
        compositionMode: "Source"
      }

      'change the background for any registration walls
      if regWall = "premiere"
        loadingImage.Url = "pkg:/" + m.res + "/bg_premiere_wall.jpg"
      end if

      layers = [loadingImage]
      m.canvas.SetLayer(0, layers)

      ' layers = []
      m.paint()

      m.canvas.Show()

      while(true)
         msg = wait(30,port)

         if (m.pressedItem <> invalid)
            m.pressedItem.count = m.pressedItem.count -1
            if (m.pressedItem.count < 1)
              m.pressedItem = invalid
              m.paint()
            end if
         end if

         'r = g.app.utils.getAsyncResponse (msg, id)
         'if r <> invalid
         '  print "got id " ; id
         '  print r.data
         'end if
         if m.isComplete = true
          m.isComplete = false
          m.canvas = invalid
          m.pressedItem = invalid
          return true
         end if
         if type(msg) = "roImageCanvasEvent"
            if msg.isRemoteKeyPressed()
              index = msg.GetIndex()

              'show initial "skip/ok" screen if appropriate
              if(m.isInitialScreen = true)


                if (index = 0) ' back
                  m.canvas.close()
                  m.canvas = invalid
                  return true
                else if (index = 6) ' ok button on remote
                  if(m.col = 0) 'selected OK button on screen
                    loadingImage = {
                      ' Url: "pkg:/" + m.res + "/bg_entry.jpg"
                      Url: "http://cdn.adrise.com/hotpatches/roku/registerScreen/" + m.res + "/bg_entry.jpg"
                      TargetRect: m.getRect("bg", 0)
                      compositionMode: "Source"
                    }
                    layers = [loadingImage]
                    m.canvas.SetLayer(0, layers)
                    m.isInitialScreen = false
                    m.row = 1
                    m.col = 1
                    m.pressedItem = invalid
                    m.paint()
                  else 'selected No Thanks button
                    m.canvas.close()
                    m.canvas = invalid
                    return true
                  end if
                else if (index = 5 and m.col=0) ' right
                  m.col = 1
                else if (index = 4 and m.col=1) ' left
                  m.col = 0
                end if
                m.paint()

              else
                if (index = 0) ' back
                  m.canvas.close()
                  m.canvas = invalid
                  return true
                else if (index = 6) ' ok
                  m.pressedItem = {
                    row: m.row
                    col: m.col
                    count: 8
                  }
                  m.paint()
                  if(m.row < 3)
                    m.addDigit(((m.row*3)+(m.col+1)))
                  else if (m.row = 3 and m.col = 1)
                    m.addDigit(0)
                  else if (m.row = 3 and m.col = 0)
                    m.deleteCharacter()
                  else if  (m.row = 4 and m.col = 0)
                    m.cancel()
                  else if  (m.row = 4 and m.col = 1)
                    m.submit()
                  else if (m.row = 4 and m.col = 2) 'register with no phone
                    sleep(300) 'pause just for a tiny bit to show the button turn color
                    isRegistered = m.webRegister()
                    m.isComplete = true
                    m.canvas.close()
                  end if
                else
                  if (index = 5) ' right
                    m.col = m.col + 1
                  else if (index = 2) ' up
                    m.row = m.row - 1
                  else if (index = 4) ' left
                    m.col = m.col - 1
                  else if (index = 3) ' down
                    m.row = m.row + 1
                  end if

                  'control for cases where user tries to move left or right out of the grid
                  if m.col < 0
                    if m.row <> 4
                      m.col = 0
                    else
                      m.col = 2
                    end if
                  else if m.col > 2
                    if m.row <> 4
                      m.col = 2
                    else
                      m.col = 0
                    end if
                  end if

                  'control for cases where user tries to move up or down out of the grid'
                  if m.row > 4
                    m.row = 4
                  else if m.row < 0
                    m.row = 0
                  end if
                  
                  if((m.row = 3) and m.col = 2)
                    m.col = 1
                  end if

                end if
                m.paint()
              end if
            end if
         end if
       end while
     m.canvas = invalid
    return true
  end function

  m.app.registerScreen.webRegister = function()
    settings = m.utils.getSettings()

    'create new regId to send to server as a unique id that will be stored in Roku's local memory if registration is completed
    'regId will be saved into into memory as "token"
    regId = m.utils.generateUuId()

    webRegPort = CreateObject("roMessagePort")

    'set up registation screen
    webRegScreen = CreateObject("roCodeRegistrationScreen")
    webRegScreen.SetMessagePort(webRegPort)
    ' webRegScreen.Show()

    webRegScreen.AddHeaderText("Steps to activate Tubi TV for Roku")
    ' webRegScreen.AddFocalText("From your computer, go to: ", "spacing-sparse")
    webRegScreen.AddParagraph("1) On your computer, go to: http://www.tubitv.com/activate")
    webRegScreen.AddParagraph("2) Sign in with an existing Tubi TV account or sign up for a new account.")
    webRegScreen.AddParagraph("3) Once you are signed in, enter the activation code seen below:")
    webRegScreen.AddParagraph(" ")
    webRegScreen.SetRegistrationCode("Retrieving code...")
    webRegScreen.AddParagraph(" ")
    webRegScreen.AddParagraph("4) The Roku screen will automatically update once your activation completes.")
    webRegScreen.AddButton(2, "Get a new code")
    webRegScreen.AddButton(1, "Cancel")
    webRegScreen.Show()

    'close the phone register screen since we will never return to it from this screen
    m.canvas.Close()

    'get code from server and add it to screen

    'start polling server to see if the user has added the code. If after polling begins, the user asks for a new code
    'stop the current polling async request and start a new async request to get the code.
    'until there is an error or the server responds that the user has registered, there should always be exactly one async request
    'waiting for a response (either getting code or polling to see if registration complete)

    webRegUrlGetCode = settings.regUrlBase + "/generate"
    webRegUrlGetConfirmation = settings.regUrlBase + "/status"

    regCode = invalid
    regId = invalid
    token = invalid
    identifier = invalid

    haveRegistrationCode = false

    pollCounter = 0
    timeSpan = CreateObject("roTimespan")

    while true
      if haveRegistrationCode = false 'then we need to attempt to get the response code
        getCodeBody = {
          device_id: m.utils.deviceInfo.deviceId
          platform: "roku"
        }
        if identifier <> invalid
          getCodeBody.identifier = identifier
        end if
        
        getCodeBodyJson = FormatJson(getCodeBody)

        getCodeHeaders = {
          "Content-Type": "application/json"
        }
        webRegAsyncId = m.utils.sendAsyncRequest(webRegUrlGetCode, webRegPort, "webRegistration", "POST", true, getCodeBodyJson, getCodeHeaders)
      else 'start polling
        pollBody = {
          device_id: m.utils.deviceInfo.deviceId
          platform: "roku"
          activation_token: token
        }
        pollJsonBody = FormatJson(pollBody)
        pollHeaders = {
          "Content-Type": "application/json"
        }
        webRegAsyncId = m.utils.sendAsyncRequest(webRegUrlGetConfirmation, webRegPort, "webConfirmationPoll", "POST", true, pollJsonBody, pollHeaders)
        timeSpan.Mark()
      end if

      if (webRegAsyncId <> 0)
      
        while true
          'keep running through this loop(listening for events) - if we are polling and 2 seconds have passed since the last poll
          'jump out of the inner while loop and make another polling call.
          if timeSpan.TotalMilliseconds() > 2000 and haveRegistrationCode = true
            exit while
          end if

          msg = wait(1000, webRegPort) 'listen for messages for 1 sec (either remote control input message or message indicating a response to the previous async call)
          'make sure the message is from the most recent async request
          'there can be race conditions, especially when asking for a new registration code
          if msg <> invalid
            if type(msg) = "roUrlEvent" and msg.GetFailureReason() <> "Cancelled" 'got response from server for async call
              if haveRegistrationCode = false 'means the current response is to a get code request
                getCodeResponse = m.utils.getAsyncResponse(msg, webRegAsyncId)
                print "GET CODE RESPONSE "; getCodeResponse
                if getCodeResponse <> invalid and getCodeResponse.data <> invalid and getCodeResponse.data.len() > 0 and getCodeResponse.responseCode = 200
                  codeResponse = ParseJson(getCodeResponse.data)
                  regCode = codeResponse.activation_code 'code for a user to enter at tubitv.com/roku to complete registration
                  'only store the first regId that is created - any subsquent calls to get activation code will send new regIds - we don't want those
                  'regIds are known as tokens on the server and web code'                 
                  if regId = invalid
                    regId = codeResponse.activation_token 'regId should be a UUID - to be passed back to server as an identifier when polling
                  end if
                  webRegScreen.SetRegistrationCode(regCode) 'add code to the screen
                  token = regId
                  identifier = regCode
                  haveRegistrationCode = true
                  exit while
                else
                  print "did not receive response from server"
                  m.showMessage("We're sorry", "Could not get code from server.")
                  webRegScreen.Close()
                  return false
                end if
              else if haveRegistrationCode = true 'means the current response is to a get confirmation request (polling)
                registrationResponse = m.utils.getAsyncResponse(msg, webRegAsyncId)

                if registrationResponse <> invalid and registrationResponse.data <> invalid and registrationResponse.data.len() > 0 and registrationResponse.responseCode = 200
                  registrationInfo = ParseJson(registrationResponse.data)

                  if registrationInfo.status = "pending"
                    'we get a response with no confirmation that user registered - so we're still waiting
                    pollCounter = pollCounter + 2
                    'if we've polled for 5 minutes stop polling
                    if pollCounter > 600
                      m.showMessage("We're sorry", "After checking for 10 minutes, we did not see you register.")
                      webRegScreen.Close()
                      return false
                    end if
                  else if registrationInfo.status = "registered"
                    'we get a response confirming the user registered so let the user know and exit the page
                    'store auth info in registry
                    authInfo = m.utils.formatAuthInfoFromServer(registrationInfo)
                    m.utils.saveAuthInfo(authInfo)

                    'create a message box with a button for closing the box
                    'when user closes box, webRegScreen should close and bring users to the gridScreen
                    m.showMessage("Thank you", "You are now registered as " + registrationInfo.first_name + " " + registrationInfo.last_name + "." + chr(10) + chr(10) + "Click OK to go to the Tubi TV home screen.")
                    webRegScreen.Close()
                    return true
                  end if

                'we get an error
                else
                  print "there was an error while polling for response from web registration"
                  m.showMessage("We're sorry", "Registration wasn't able to be completed.")
                  webRegScreen.Close()
                  return false
                end if
              else 'something went horribly wrong
                print "haveRegistrationCode is not an expected type"
                m.showMessage("We're sorry", "Registration wasn't able to be completed.")
              end if
            else if type(msg) = "roCodeRegistrationScreenEvent"
              if msg.GetIndex() = 0 or msg.GetIndex() = 1 'back button or cancel button pressed
                print "web registration back or cancel button pressed"
                m.utils.cancelAsyncRequest(webRegAsyncId)
                ' m.canvas.Close()
                webRegScreen.Close()
                return false
              else if msg.GetIndex() = 2 'request for new code
                'only honor request for new codes if we are not in the process of getting a new code
                'if we try to get a new code, while waiting for the server to respond, the server gets confused and returns an error
                if haveRegistrationCode = true
                  print "new web registration code was requested"
                  haveRegistrationCode = false
                  webRegScreen.SetRegistrationCode("Retrieving...")
                  m.utils.cancelAsyncRequest(webRegAsyncId) 'get rid of any pending async get request before making another
                  exit while
                end if
              else if msg.isScreenClosed() 'don't think this is necessary
                return false
              end if
            end if
          end if
        end while
      end if
    end while

  end function

  'hopefully stops crashes when server doesn't respond to get series information
  'crashes occur when people see message of sending queue and view history to server
  'gets any content saved in the previously viewed registry, and sends it to the server - syncing previouslyViewed/history
  m.app.utils.oneTimePreviouslyViewedSync = function()
    settings = m.getSettings()
    authInfo = m.getAuthInfo()
    cp = GetGlobalAA().app.cp

    'get all nowPosi (old view history) from the device registry
    localNowPos = m.getUserPlaylistContent(invalid) 'super hacky, but it works...(except you get some other junk that you need to separate out)

    'first filter out any non nowPos and separate the time the nowPos was save from the nowPos itself
    for each id in localNowPos
      if Val(id) = 0
        localNowPos.delete(id)
      else
        nowPosPlus = localNowPos[id]
        separated = nowPosPlus.Tokenize(",")
        localNowPos[id] = Int(Val(separated[0]))
      end if
    end for

    if localNowPos.count() = 0
      return invalid
    end if

    'show a dialog letting the user know the one time sync might take a while
    dialog = CreateObject("roMessageDialog")
    dialog.setTitle("Sending Queue and View History To Tubi TV Server")
    dialog.setText("This may take a few minutes. It will only happen once. Once sending is complete, you will be able to access your Tubi TV Queue and View History on all your devices!")
    dialog.show()

    'get all previously viewed content from device memory/registry
    prevViewed = m.getUserPlaylistContent(settings.previouslyViewedRegistry)

    toSend = []
    seriesIds = []

    for each prevViewedId in prevViewed
      cid = Mid(prevViewedId, 2)

      'we have a video
      if Left(prevViewedId, 1) = "v"
        if localNowPos[cid] <> invalid
          toSend.push({
            user_id: authInfo.userId
            content_id: cid
            content_type: "movie"
            position: localNowPos[cid]
          })
        end if

      'we have a series - we'll accumulate all the series ids so we just make one call to the server to get info for all the series
      'we'll iterate over all the series and add them to toSend as necessary in a subsequent loop
      else if Left(prevViewedId, 1) = "s"
        seriesIds.push(cid)
      end if
    end for

    seriesFromServer = cp.getSeriesFromServer(seriesIds)

    if seriesFromServer <> invalid
      'add all the view histories for the series' episodes
      seriesToSend = []
      for each seriesId in seriesIds
        serverSeriesId = "0" + seriesId
        series = seriesFromServer[serverSeriesId]

        if series <> invalid and series.children <> invalid
          for each season in series.children
            if season.children <> invalid
              for each episode in season.children
                if episode.id <> invalid and localNowPos[episode.id] <> invalid
                  seriesToSend.push({
                    user_id: authInfo.userId
                    content_id: episode.id
                    content_type: "episode"
                    position: localNowPos[episode.id]
                    parent_id: seriesId
                  })
                end if
              end for
            end if
          end for
        end if
      end for

      toSend.Append(seriesToSend)
    end if

    migratePort = createObject("roMessagePort")
    url = settings.previouslyViewedUrl
    bodyJson = FormatJson(toSend)
    authInfo = m.checkIfAuthExpired(authInfo)
    headers = m.getAuthHeaders(authInfo.accessToken)
    m.sendAsyncRequest(url, migratePort, "oneTimePreviouslyViewedMigration", "POST", true, bodyJson, headers)

    while true
      msg = wait(0, migratePort)
      if type(msg) = "roUrlEvent"
        response = m.getAsyncResponse(msg, 0)
        if response.data <> invalid and response.data.len() > 0 and response.responseCode = 200
          'dont' really care about the response, as long as it's valid, since we will get all previously viewed/history later
          'since we successfully send the previously viewed data, we can delete the old previously viewed/history info

          'removes all ids from the old view history
          for each previouslyViewedId in localNowPos
            RegDelete(previouslyViewedId)
          end for

          'delete any previously viewed items... we don't need them anymore, will sync with the saved positions instead
          authSection = CreateObject("roRegistry")
          authSection.delete(settings.previouslyViewedRegistry)
          authSection.flush()

        end if
        exit while
      end if
    end while

    'close the dialog
    dialog.close()

  end function

end if