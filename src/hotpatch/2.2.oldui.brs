print "Hot Patch 2.2.oldui"

'add protection to the url generating function in order to fix crashes as seen in roku's crash repoport UI
m.app.player.ads.populateUrl = function(episode, playerSettings)
  settings = m.utils.getSettings()

  deviceId = "&deviceId=" + m.utils.deviceInfo.deviceId
  model = "&model=" + m.utils.deviceInfo.model

  ' add Roku Advertiser Id (RIDA) to ad call url  
  urlAdId = ""
  if m.utils.deviceInfo.deviceAdId <> invalid
    urlAdId = "&advid=" + m.utils.deviceInfo.deviceAdId
  end if

  optOut = "&opt-out=0"
  if m.utils.deviceInfo.isAdIdTrackingDisabled = true
    optOut = "&opt-out=1"
  end if

  'add TubiTV user/registration id to ad call url
  urlTubiId = ""
  userData = m.utils.getUserData()
  if userData <> invalid and userData.token <> invalid
    urlTubiId = "&tubitvid=" + userData.token
  end if

  'add if Linear/Live TV is on or off to ad call url
  isLinear = ""
  if GetGlobalAA().app.linearTV.linearTvOn = true
    isLinear = "&linear=1"
  end if

  'select the ad sdk
  adSdk = "&sdk=5.0_video"
  if m.isRokuAdFrameworkOn = true
    adSdk = "&sdk=raf_vast"
  end if

  appId = "&appId=" + settings.shortAppName
  pubId = "&pubid=" + settings.pubId  'default pub id from settings
  contentType = "&content-type=hls"
  if playerSettings <> invalid
    if type(playerSettings.appId) = "String" or type(playerSettings.appId) = "roString"
      appId = "&appId=" + playerSettings.appId
    end if

    if type(playerSettings.pubId) = "String" or type(playerSettings.pubId) = "roString"
      pubId = "&pubid=" + playerSettings.pubId
    end if

    if type(playerSettings.contentType) = "String" or type(playerSettings.contentType) = "roString"
      contentType = "&content-type=" + playerSettings.contentType
    end if
  end if

  cid = ""
  nowPos = "&nowpos=0"
  if episode <> invalid
    if type(episode.id) = "String" or type(episode.id) = "roString"
      cid = "&cid=" + episode.id
    end if

    if type(episode.nowPos) = "roFloat" or type(episode.nowPos) = "roInteger"
      nowPos = "&nowpos=" + Int(episode.nowPos).ToStr()
    end if
  end if

  'create the url to be used for ad calls'
  url = m.baseUrl + "?platform=roku" + appId + adSdk + cid + nowPos + model + deviceId + optOut + urlAdId + urlTubiId + pubId + contentType + isLinear + "&_=" + RND(1000000000000).ToStr()

  return url
end function





'don't let users leave the app by pressing back from the sign in screen
m.app.registerScreen.show = function(regWall = "")
    
  'necessary when calling the show() method from detail screen
  '(ie. for registration walls)
  if m.res = invalid
    m = GetGlobalAA().app.registerScreen
  end if


  g = GetGlobalAA()

  m.canvas = CreateObject("roImageCanvas")
  port = CreateObject("roMessagePort")

  m.canvas.SetMessagePort(port)

  'sets state on m and returns the layers array
  layers = m.setupInitialScreen()

  'change the background for any registration walls
  if regWall = "premiere"
    layers[0].Url = "pkg:/images/oldUI/" + m.res + "/bg_premiere_wall.jpg"
  end if

  m.canvas.SetLayer(0, layers)
  m.paint()

  m.canvas.Show()
  m.utils.trackEvent({
    trackType: "pageLoad"
    value: "/deviceregistration"
    port: port
  })

  while(true)
    msg = wait(30, port)

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

    if type(msg) = "roUrlEvent"
      respObj = m.utils.getAsyncResponse(msg, 0)

    else if type(msg) = "roImageCanvasEvent"
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
                Url: "pkg:/images/oldUI/" + m.res + "/bg_entry.jpg"
                TargetRect: m.getRect("bg", 0)
                compositionMode: "Source"
              }
              layers = [loadingImage]
              m.canvas.SetLayer(0, layers)
              m.isInitialScreen = false
              m.row = 1
              m.col = 1
              m.pressedItem = invalid

              m.utils.trackEvent({
                trackType: "navigate"
                value: "/deviceregistration/sms"
                ctx: "/deviceregistration/"
                port: port
              })

              m.utils.trackEvent({
                trackType: "pageLoad"
                value: "/deviceregistration/sms"
                port: port
              })
              
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

        'enter phone number screen
        else
          if (index = 0) ' back
            layers = m.setupInitialScreen()
            m.canvas.SetLayer(0, layers)

            m.utils.trackEvent({
              trackType: "navigate"
              value: "/deviceregistration/"
              ctx: "/deviceregistration/sms"
              port: port
            })

            m.utils.trackEvent({
              trackType: "pageLoad"
              value: "/deviceregistration/"
              port: port
            })

            m.paint()

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
              m.utils.trackEvent({
                trackType: "navigate"
                value: "/deviceregistration/code"
                ctx: "/deviceregistration/sms"
                port: port
              })

              sleep(300) 'pause just for a tiny bit to show the button turn color
              isRegistered = m.webRegister()
              
              print "shutting web register screen and isRegistered = "; isRegistered
              if isRegistered = true
                m.isComplete = true
                m.canvas.close()
              end if
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
