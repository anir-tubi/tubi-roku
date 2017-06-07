function createServerLinker(utils, player, settings)
    o =  {
      utils: utils
      settings: settings
      player: player
    }

    ' ping the account and get a status (new, pending, or subscribed)
    ' show the connect dialog if status is new (which will prompt going to site and entering pin code)
    ' return value is ignored
    o.connectToAccount = function (showDialogIfNotSubscribed)
        print "connect to account"

        sec = CreateObject("roRegistrySection", "Default")

        'get the randomly generated vezo id from memory if it exists. Otherwise create a new one.
        'This will be passed to the server and used to determine if the user has a vezo account already.
        'The randomly generated vezo id is deleted from local memory if a user uninstalls the app or does a factory reset.
        hasVezoIdInMemory = false

        print "UUID----------- "; m.utils.generateUuid()

        m.randomVezoId = regRead("randomVezoId", "Default")
        if m.randomVezoId = invalid
          print "No VEZO ID found in memory"
          m.randomVezoId = m.utils.generateUuid()
        else
          print "VEZO ID found in memory "; m.randomVezoId
          hasVezoIdInMemory = true
        end if

        ' list = sec.GetKeyList()
        ' numEntries = list.count()
        ' if(numEntries = 0)
        '   timeNow = CreateObject("roDateTime")
        '   timeNow.Mark()
        '   regWrite("installtime", str(int(timeNow.asSeconds()/(60*60))))
        ' end if

        if m.settings.vezoSubscription = true or m.settings.allowVezoSubscription = true
          if hasVezoIdInMemory = false
            forceLink = "&forceLink=true"
          else
            forceLink = ""
          end if

          resp = m.utils.getTextFile(m.settings.vezoServer + "/authenticateVezoApp?deviceId=roku_" + m.utils.deviceInfo.deviceId + "&vezoId=" + m.randomVezoId + "&appName=" + m.settings.shortAppName + forceLink, "getVezoCode")
          print "get code"
          print resp
          out = m.getCode(resp)
          print out
          while out.mode <> "subscribed" and out.mode <> "cancelled"
            if out.mode = "new"
              print "connect dialog"
              if (showDialogIfNotSubscribed)
                out = m.showConnectDialog(out.code)
              else
                return true
              end if

            else if out.mode = "pending"
              print "subscribe prompt"
              
              'if server says the user has a vevo account, but not subscribed to this channel, and they don't have 
              'a randomly generated ID for vezo in local memory, add the randomly generated ID to local memory.'
              if hasVezoIdInMemory = false
                regWrite("randomVezoId", randomVezoId, "Default")
              end if

              if (showDialogIfNotSubscribed)
                if m.showSubscribePrompt() = true
                  return true
                end if
              else
                return true
              end if

              resp = m.utils.getTextFile(m.settings.vezoServer + "/authenticateVezoApp?deviceId=roku_" + m.utils.deviceInfo.deviceId + "&vezoId=" + m.randomVezoId + "&appName=" + m.settings.shortAppName, "getVezoCode")
              print "get code again"
              print resp
              out = m.getCode(resp)
            else if out.mode = "cancelled"
              return true
            end if
          end while
        end if

        if(out.mode = "subscribed")
          'if server says the user is subscribed, but they don't have a randomly generated ID for vezo in local memory,
          'add the randomly generated ID to local memory.'
          if hasVezoIdInMemory = false
            regWrite("randomVezoId", randomVezoId, "Default")
          end if
          m.player.subscription = true
          m.settings.allowRentals = false
          print "subscribed!"
        end if
        return true
    end function

    ' given a text response, determine if it is pending, subscribed, or new.  If new, get the pin code
    ' returns an object with a mode, possibly a code, and possibly a time that it started pending
    o.getCode = function (response)
        r1 = CreateObject("roRegex", "\n", "")
        r2 = CreateObject("roRegex", ",", "")
        a = r1.Split(response)
        num = a.count()
        print "num strings " ; num
        if(num > 0)
          o = r2.Split(a[num-1])
          len = o.count()

          out = { mode: o[0] }

          print
          print out

          if(out.mode = "new")
            out.code = o[1]
            print " is new "
            return out
          end if

          if(out.mode = "pending")
            print " is pending "
            out.time = o[1]
            return out
          end if

          return out
        end if
        return { mode: "pending", time: "1440" }
      end function

    ' show a dialog that prompts for you to subscribe.
    ' if you press ok, it will check for a subscription, and exit if so
    ' returning true will cause it to exit to the grid
    o.showSubscribePrompt = Function ()
        canvas = CreateObject("roImageCanvas")
        port = CreateObject("roMessagePort")
        canvas.SetMessagePort(port)
        deviceInfo = CreateObject("roDeviceInfo")
        displaySize = deviceInfo.GetDisplaySize()
        background = {
          Color: m.settings.adrise_bg
        }
        loadingImage = {
          Url: m.settings.adrise_loadingurl
          TargetRect: {
            x: Int( displaySize.w / 2 ) - Int( 336 / 2 ),
            y: Int( displaySize.h / 6 ),
            w: 336,
            h: 210
          }
        }
        loadingText = {
          TextAttrs: {
              Font: "Medium"
              VAlign: "Bottom"
              Color: m.settings.adrise_fontcolor
          },
          TargetRect: {
              x: Int(displaySize.w * .15)
              y: Int(displaySize.h * .71)
              w: Int(displaySize.w * .7)
              h: 30
          }
        }
        if m.settings.allowVezoSubscription = true
          loadingText.Text = "This device is linked to your account, but you still need to subscribe to this channel to watch the videos ad free.  Please subscribe by going to Vezo.tv on your computer, tablet or smartphone, then press ok.  To skip the linking process and watch the channel with ads, press cancel."
        else
          loadingText.Text = "This device is linked to your account, but you still need to subscribe to this channel to watch the videos.  Please subscribe by going to Vezo.tv on your computer, tablet or smartphone, then press ok on your Roku remote."
        end if

        canvas.SetLayer(2, [background, loadingImage, loadingText])
        canvas.Show()
        canvas.AddButton(1, "ok")
        if m.settings.allowVezoSubscription = true
          canvas.AddButton(2, "cancel")
        end if
        while(true)
           msg = wait(0,port)
           if type(msg) = "roImageCanvasEvent" then
            if msg.isButtonPressed()
              button = msg.GetIndex()
              if (button = 1)
                print "ok button pressed!"
                resp = m.utils.getTextFile(m.settings.vezoServer + "/authenticateVezoApp?deviceId=roku_" + m.utils.deviceInfo.deviceId + "&vezoId=" + m.randomVezoId + "&appName=" + m.settings.shortAppName, "getVezoCode 2")
                out = m.getCode(resp)
                print "got code"
                print out
                if out.mode = "subscribed"
                  m.player.subscription = true
                  m.settings.allowRentals = false
                  print "subscribed"
                  return true
                else
                  m.utils.showErrorMessage (m.settings.adrise_bg, m.settings.adrise_fontcolor, m.settings.adrise_loadingurl, "You are not yet subscribed.")
                  print "show not yet subscribed dialog"
                end if
              end if

              if (button = 2)
                '	print "fake subscribed!"
                ' m.player.subscription = true
                return true
              end if
            end if
           end if
         end while
         return false
      end function

    o.showConnectDialog = Function (code)
      port = CreateObject("roMessagePort")
      screen = CreateObject("roCodeRegistrationScreen")
      screen.SetMessagePort(port)
      screen.AddFocalText("Want to skip ads?", "spacing-dense")
      screen.AddFocalText(" ", "spacing-dense")
      screen.AddFocalText("Sign in to http://vezo.tv", "spacing-dense")
      screen.AddFocalText("Enter the code below to link your Roku", "spacing-dense")
      screen.AddFocalText("Subscribe to this channel for $4.99/mo.", "spacing-dense")
      screen.AddFocalText(" ", "spacing-dense")
      screen.AddFocalText("This app will auto-refresh after you link this device", "spacing-dense")
      screen.SetRegistrationCode("retrieving code...")
      screen.AddButton(0, "Get a new code")

      if m.settings.allowVezoSubscription = true
        screen.AddButton(1, "Skip this step and watch with ads")
      end if

      screen.Show()

      screen.SetRegistrationCode(code)

      url = m.settings.vezoServer + "/linkToVezo?deviceId=roku_" + m.utils.deviceInfo.deviceId  + "&vezoId=" + m.randomVezoId + "&appName=" + m.settings.shortAppName
      print "Link to Vezo (polling)"
      print url
      print "start poll"

      asyncId = m.utils.sendAsyncRequest(url, port, "linkPoll")
      print asyncId
      while true
        msg = wait(1000, port)
        print "get async resp " ; asyncId
        respObj = m.utils.getAsyncResponse(msg, 0)

        if(respObj <> invalid)
          print "polling response: "
          print respObj.data
          out = m.getCode(respObj.data)
          if out.mode = "pending"
            return  out
          else if out.mode = "subscribed"
            m.player.subscription = true
            m.settings.allowRentals = false
            print "subscribed!"
            return out
          end if
          print "restart poll"
          asyncId = m.utils.sendAsyncRequest(url, port, "linkPoll")
          print asyncId
        end if

        if type(msg) = "roCodeRegistrationScreenEvent"
          print "roCodeRegistrationScreenEvent"
          if msg.isScreenClosed()
              print "cancelled"
              m.utils.cancelAsyncRequest(asyncId)
              return {mode: "cancelled"}
          else if msg.isButtonPressed()
            button = msg.GetIndex()
            if (button = 1)
              print "cancelled"
              m.utils.cancelAsyncRequest(asyncId)
              return {mode: "cancelled"}
            else if (button = 0)
              print "get code again"
              resp = m.utils.getTextFile(m.settings.vezoServer + "/authenticateVezoApp?deviceId=roku_" + m.utils.deviceInfo.deviceId + "&vezoId=" + m.randomVezoId + "&appName=" + m.settings.shortAppName, "getVezoCode")
              print "get app status response (2): "
              print resp

              out = m.getCode(resp)
              print "done getting code" ; out
              if out.mode = "new"
                screen.SetRegistrationCode(out.code)
              else if out.mode = "pending"
                m.utils.cancelAsyncRequest(asyncId)
                return out
              else if out.mode = "subscribed"
                m.player.subscription = true
                m.settings.allowRentals = false
                print "subscribed!"
                m.utils.cancelAsyncRequest(asyncId)
               return out
              end if
            end if
          end if
        end if
      end while
      print "returning"
      return  {mode: "new"}
     end function

    return o
end function
