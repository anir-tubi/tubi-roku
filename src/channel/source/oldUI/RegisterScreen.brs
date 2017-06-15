function RegisterScreen(uniqueId, utils)
  mode = utils.deviceInfo.displayMode

  res = "720"
  if mode <> "1080p" and mode <> "720p"
    res = "480"
  end if

  return {
    ' registerPort: CreateObject("roMessagePort")
    uniqueId: uniqueId
    currNumber: ""
    isComplete: false
    row: 5 '4
    col: 1
    pressedItem: invalid
    res: res
    utils: utils
    baseUrl: "http://tubitv.com"
    allowSMS: true

    setupInitialScreen: RegisterScreen_setupInitialScreen

    '1st set of numbers describes SD. 2nd set of numbers describes HD
    rects: {
        bg :  [
          [
          0,
          0,
          720,
          480
          ],
          [
          0,
          0,
          1280,
          720
          ]
         ],
        entry :  [
          [
          449,
          72,
          199,
          53
          ],
          [
          811,
          105,
          343,
          80
          ]
         ],
        x0_0 :  [
          [
          421,
          131,
          81,
          53
          ],
          [
          811,
          197,
          109,
          80
          ]
         ],
        x0_1 :  [
          [
          508,
          131,
          81,
          53
          ],
          [
          925,
          197,
          109,
          80
          ]
         ],
        x0_2 :  [
          [
          596,
          131,
          81,
          53
          ],
          [
          1041,
          197,
          109,
          80
          ]
         ],
        x1_0 :  [
          [
          421,
          188,
          81,
          53
          ],
          [
          811,
          282,
          109,
          80
          ]
         ],
        x1_1 :  [
          [
          508,
          188,
          81,
          53
          ],
          [
          926,
          282,
          109,
          80
          ]
         ],
        x1_2 :  [
          [
          596,
          188,
          81,
          53
          ],
          [
          1042,
          282,
          109,
          80
          ]
         ],
        x2_0 :  [
          [
          421,
          245,
          81,
          53
          ],
          [
          811,
          369,
          109,
          80
          ]
         ],
        x2_1 :  [
          [
          508,
          245,
          81,
          53
          ],
          [
          925,
          369,
          109,
          80
          ]
         ],
        x2_2 :  [
          [
          596,
          245,
          81,
          53
          ],
          [
          1041,
          369,
          109,
          80
          ]
         ],
        x3_0 :  [
          [
          421,
          302,
          81,
          53
          ],
          [
          811,
          453,
          109,
          80
          ]
         ],
        x3_1 :  [
          [
          508,
          302,
          81,
          53
          ],
          [
          926,
          453,
          109,
          80
          ]
         ],
        x4_0 :  [ 'cancel'
          [
          421,
          379,
          81,
          53
          ],
          [
          811,
          568,
          109,
          80
          ]
         ],
        x4_1 :  [ 'submit'
          [
          508,
          379,
          169,
          53
          ],
          [
          926,
          568,
          226,
          80
          ]
         ],

         x4_2 :  [ 'no smartphone'
          [
          148,
          379,
          258,
          53
          ],
          [
          408, 'x placement
          568, 'y placement
          342, 'width
          80   'height
          ]
         ],

        x5_0 :  [
          [
          180,
          379,
          170,
          53
          ],
          [
          400,
          569,
          226,
          80
          ]
         ],
        x5_1 :  [
          [
          372,
          379,
          170,
          53
          ],
          [
          656,
          569,
          226,
          80
          ]
         ],

        mature :  [
          [
          0,
          129,
          416,
          314
          ],
          [
          0,
          194,
          740,
          471
          ]
         ]


        },

    show: function(regWall = "")
      
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
                  if m.allowSMS <> invalid and m.allowSMS = false
                    m.utils.trackEvent({
                      trackType: "navigate"
                      value: "/deviceregistration/code"
                      ctx: "/deviceregistration/"
                      port: port
                    })

                    sleep(300) 'pause just for a tiny bit to show the button turn color
                    isRegistered = m.webRegister()

                    print "shutting web register screen and isRegistered = "; isRegistered
                    if isRegistered = true
                      m.isComplete = true
                      m.canvas.close()
                    end if
                  else
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
                  end if
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


    addDigit : function(n)
      l = len(m.currNumber)
      if(l<10)
        m.currNumber = m.currNumber + ToStr(n)
      else
        m.showMessage("Can't enter more digits", "Phone number must be ten digits long.")
      end if
    end function

    deleteCharacter : function()
      l = len(m.currNumber)
      if(l>0)
        m.currNumber = mid(m.currNumber, 0, l-1)
      end if
    end function

    submit : function()
      l = len(m.currNumber)
      if(l<10)
        m.showMessage("Phone number too short", "Please enter the 10-digit number of your mobile phone.")
      else
        regOutput = m.showRegistrationInProgress()
        m.isComplete = true

        m.utils.trackEvent({
          trackType: "navigate"
          value: "/home"
          ctx: "/deviceregistration/sms"
          port: GetGlobalAA().app.gridScreen.gridPort
        })
        
        m.canvas.close()
        if(regOutput <> invalid and regOutput.mode = "registered")
          m.utils.trackEvent({
            trackType: "registerSuccess"
            value: "/deviceregistration/sms"
            port: GetGlobalAA().app.gridScreen.gridPort
          })
          if regOutput.fn <> invalid and regOutput.ln <> invalid
            m.showMessage("Thank you", "You are now registered as " + regOutput.fn + " " + regOutput.ln + ".")
          else
            m.showMessage("Thank you", "You are now a registered Tubi TV user.")
          end if
          m.token = invalid
        end if
      end if
    end function

    cancel : function()
      m.isComplete = true
      m.canvas.close()
    end function

    paint: function()
      layers = []


      if(m.pressedItem <> invalid)
        m.drawHilite(layers, "x" + ToStr(m.pressedItem.row)+ "_" + ToStr(m.pressedItem.col), true)
      end if
       m.drawHilite(layers, "x" + ToStr(m.row)+ "_" + ToStr(m.col), false)

      if(m.isInitialScreen <> true)
        number = m.currNumber
        l = len(m.currNumber)
        if(l>6)
          number = "(" + m.currNumber.mid(0, 3) + ") " + m.currNumber.mid(3, 3) + "-" + m.currNumber.mid(6)
        else if (l>3)
          number = "(" + m.currNumber.mid(0, 3) + ") " + m.currNumber.mid(3)
        end if

        m.drawText(layers, "entry", number, "#444444", invalid)

        for row=0 to 2
          for col=0 to 2
            name = "x" + ToStr(row) + "_" + ToStr(col)
            t = ToStr((row*3)+(col+1))
            m.drawText(layers, name, t, invalid, invalid)
          end for
        end for
        m.drawText(layers, "x3_0", "Back", invalid, "Medium")
        m.drawText(layers, "x3_1", "0", invalid, invalid)
        m.drawText(layers, "x4_0", "Cancel", invalid, "Medium")
        if (m.pressedItem <> invalid and m.pressedItem.row = 4 and m.pressedItem.col = 1)
          m.drawText(layers, "x4_1", "Submit", "#ffffff", "Medium")
        else
          m.drawText(layers, "x4_1", "Submit", "#ff9900", "Medium")
        end if
        m.drawText(layers, "x4_2", "Don't have a smartphone?", "#ffffff", "Medium")

      else
        m.drawText(layers, "x5_1", "No Thanks", invalid, "Medium")

        if (m.pressedItem <> invalid and m.pressedItem.col = 1)
          m.drawText(layers, "x5_0", "OK", "#ffffff", "Medium")
        else
          m.drawText(layers, "x5_0", "OK", "#ff9900", "Medium")
        end if
      end if
      m.canvas.SetLayer(2, layers)
    end function

    getRect: function (name, inset)
      which = 1
      if m.res = "480"
        which = 0
      end if

      r = m.rects[name][which]

      return {
        x: r[0] + inset
        y: r[1] + inset
        w: r[2] - (2*inset)
        h: r[3] - (2*inset)
      }
    end function

    drawText: function(layers, name, text, color, fontSize)
        if color = invalid
          color = "#FFFFFF"
        end if
        if fontSize = invalid
          fontSize = "Large"
        end if

        layers.push({
          Text: text
          TextAttrs: {
              Font: fontSize
              VAlign: "center"
              Color: color
            },
          targetRect: m.getRect(name, 0)
          compositionMode: "Source"
        })
    end function

    drawHilite: function(layers, name, isPressed)
      rOuter = m.getRect(name, 0)
      rInner = m.getRect(name, 8)

      if(isPressed)
        action =  "pressed"
      else
        action = "selected"
      end if

      if(name = "x4_1" or name = "x5_0" or name = "x5_1")
        button =  "submit"
      else if name = "x4_2"
        button = "nophone"
      else
        button = "dial"
      end if

      layers.Push({
        Url: "pkg:/images/oldUI/" + m.res + "/btn_" + button + "_" + action + ".png"
        TargetRect: rOuter
        compositionMode: "Source_over"
      })
    end function

    showMessage: function (title, message)
      port = CreateObject("roMessagePort")
      dialog = CreateObject("roMessageDialog")
      dialog.SetMessagePort(port)
      dialog.SetTitle(title)
      dialog.SetText(message)
      dialog.AddButton(1, "ok")
      dialog.Show()
      while true
        dlgMsg = wait(0, dialog.GetMessagePort())

        if type(dlgMsg) = "roMessageDialogEvent"
          if dlgMsg.isButtonPressed()
            if dlgMsg.GetIndex() = 1
              dialog.Close()
              exit while
            end if
          else if dlgMsg.isScreenClosed()
            exit while
          end if
        end if
      end while
    end function

    showRegistrationInProgress: function ()
      settings = m.utils.getSettings()
      port = CreateObject("roMessagePort")
      dialog = CreateObject("roMessageDialog")
      dialog.SetMessagePort(port)
      dialog.SetTitle("Waiting for registration to complete....")
      dialog.SetText("Please check your phone for an SMS message and follow the link to complete registration. You may also exit the registration process by clicking cancel below.")

      dialog.AddButton(1, "cancel")
      dialog.EnableBackButton(true)
      dialog.Show()

      clock = CreateObject("roTimespan")
      nextCall = 0

      'set up the async POST request to send a registration SMS
      sendSmsUrl = settings.regUrlBase + "/sms/generate"
      sendSmsBody = {
        device_id: m.utils.getUniqueId()
        platform: "roku"
        phone_number: m.currNumber
      }
      jsonSmsBody = FormatJson(sendSmsBody)
      smsHeaders = {
        "Content-Type": "application/json"
      }

      'send request to the server to send the SMS to the user's phone - with 5 retries if the request fails
      sendSmsReqId = 0
      count = 0
      while sendSmsReqId = 0
        sendSmsReqId = m.utils.sendAsyncRequest(sendSmsUrl, port, "getRegToken", "POST", true, jsonSmsBody, smsHeaders)
        count = count + 1
        if count = 5
          exit while
        end if
      end while

      pollReqIds = {}
      token = invalid
      count = 0

      'wait for the response for the SMS call - expecting to get a token that will be used to make polling requests
      while true
        dlgMsg = wait(200, port)
        if type(dlgMsg) = "roUrlEvent"
          response = m.utils.getAsyncResponse(dlgMsg, 0)
          
          'we get the initial response from our sendSms request, so now start polling
          if response.id = sendSmsReqId
            if response.data <> invalid and response.data.len() > 0
              smsResp = ParseJson(response.data)
              if smsResp.activation_token <> invalid and smsResp.activation_token.len() = 36 'in case we don't get a uuid token back
                token = smsResp.activation_token
              end if
            end if
          end if

          'check if we have a response from one of our polling calls
          if pollReqIds[response.id.toStr()] <> invalid
            if response.data <> invalid and response.data.len() > 0
              pollResponse = ParseJson(response.data)
              if pollResponse.status = "registered"
                'store auth info in registry
                authInfo = m.utils.formatAuthInfoFromServer(pollResponse)
                m.utils.saveAuthInfo(authInfo)

                return {
                  mode: pollResponse.status
                  fn: pollResponse.first_name
                  ln: pollResponse.last_name
                }
              end if
            end if
          end if
        end if
          
        'make another polling call if appropriate
        if token <> invalid and clock.TotalMilliseconds() > nextCall

          'set up the async POST request to poll if registration completed
          pollUrl = settings.regUrlBase + "/status"
          pollBody = {
            device_id: m.utils.deviceInfo.deviceId
            platform: "roku"
            activation_token: token
          }
          pollJsonBody = FormatJson(pollBody)
          pollHeaders = {
            "Content-Type": "application/json"
          }

          pollReqId = m.utils.sendAsyncRequest(pollUrl, port, "registerPoll", "POST", true, pollJsonBody, pollHeaders)
          pollReqIds[pollReqId.toStr()] = true

          nextCall = clock.TotalMilliseconds() + 3000
          count = count + 1
          if(count > 40)

            m.utils.trackEvent({
              trackType: "registerFail"
              value: "sms-user-timeout"
              port: GetGlobalAA().app.gridScreen.gridPort
            })

            return invalid
          end if
        end if

        if type(dlgMsg) = "roMessageDialogEvent"
          if dlgMsg.isButtonPressed()
            if dlgMsg.GetIndex() = 1
              return invalid
            end if
          else if dlgMsg.isScreenClosed()
            return invalid
          end if
        end if
        ' if m.asyncId = 0 and clock.TotalMilliseconds() > nextCall
        '   m.asyncId = m.utils.sendAsyncRequest(url + "/api?type=checkToken&token=" + m.token, port, "registerPoll")
     '    end if
      end while
      return invalid
    end function

    processResponse : function (response)
        r1 = CreateObject("roRegex", "\n", "")
        r2 = CreateObject("roRegex", ",", "")
        a = r1.Split(response)
        num = a.count()
        if(num > 0)
          out = {}
          o = r2.Split(a[num-1])
          len = o.count()

          if(o[0] = "pending")
            out.mode = "pending"
            return out
          end if
          out.mode = "registered"
          out.id = o[0]
          out.fn = o[1]
          out.ln = o[2]
          return out
        end if
        return {mode: "pending"}
     end function

    'used when users choose to register without a phone
    webRegister: function()
      settings = m.utils.getSettings()

      'create new regId to send to server as a unique id that will be stored in Roku's local memory if registration is completed
      'regId will be saved into into memory as "token"
      regId = m.utils.generateUuId()

      webRegPort = CreateObject("roMessagePort")

      'set up registation screen
      webRegScreen = CreateObject("roCodeRegistrationScreen")
      webRegScreen.SetMessagePort(webRegPort)

      webRegScreen.AddHeaderText("Steps to activate Tubi TV for Roku")
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

      m.utils.trackEvent({
        trackType: "pageLoad"
        value: "/deviceregistration/code"
        port: webRegPort
      })

      'close the phone register screen since we will never return to it from this screen
      ' m.canvas.Close()

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
          codeRetryCount = 0
        
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
                  getCodeResponse = m.utils.getAsyncResponse(msg, 0)
                  ' if getCodeResponse <> invalid and getCodeResponse.data <> invalid and getCodeResponse.data.len() > 0 and getCodeResponse.responseCode = 200
                  if getCodeResponse <> invalid and getCodeResponse.id = webRegAsyncId
                    if getCodeResponse.data <> invalid and getCodeResponse.data.len() > 0
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
                    
                    'did not successfully get a code from the server - so retry
                    else
                      if codeRetryCount <= 3
                        webRegAsyncId = m.utils.sendAsyncRequest(webRegUrlGetCode, webRegPort, "webRegistration", "POST", true, getCodeBodyJson, getCodeHeaders)
                        
                        m.utils.trackEvent({
                          trackType: "registerFail"
                          value: "bad-server-response-code"
                          port: webRegPort
                        })

                        codeRetryCount = codeRetryCount + 1
                      else
                        m.utils.trackEvent({
                          trackType: "navigate"
                          value: "/home"
                          ctx: "/deviceregistration/code"
                          port: webRegPort
                        })

                        m.showMessage("We're sorry", "Could not get code from server.")
                        webRegScreen.Close()
                        return false
                      end if
                    end if
                  end if
                else if haveRegistrationCode = true 'means the current response is to a get confirmation request (polling)
                  registrationResponse = m.utils.getAsyncResponse(msg, 0)
                  ' if registrationResponse <> invalid and registrationResponse.data <> invalid and registrationResponse.data.len() > 0 and registrationResponse.responseCode = 200
                  if registrationResponse <> invalid and registrationResponse.id = webRegAsyncId
                    if registrationResponse.data <> invalid and registrationResponse.data.len() > 0
                      registrationInfo = ParseJson(registrationResponse.data)

                      if registrationInfo.status = "pending"
                        'we get a response with no confirmation that user registered - so we're still waiting
                        pollCounter = pollCounter + 2
                        'if we've polled for 5 minutes stop polling
                        if pollCounter > 600
                          m.showMessage("We're sorry", "After checking for 10 minutes, we did not see you register.")
                          
                          m.utils.trackEvent({
                            trackType: "registerFail"
                            value: "code-user-timeout"
                            port: webRegPort
                          })                    
                          
                          m.utils.trackEvent({
                            trackType: "navigate"
                            value: "/home"
                            ctx: "/deviceregistration/code"
                            port: webRegPort
                          })
      
                          webRegScreen.Close()
                          return false
                        end if
                      else if registrationInfo.status = "registered"
                        'we get a response confirming the user registered so let the user know and exit the page
                        'store auth info in registry
                        authInfo = m.utils.formatAuthInfoFromServer(registrationInfo)
                        m.utils.saveAuthInfo(authInfo)

                        m.utils.trackEvent({
                          trackType: "registerSuccess"
                          value: "/deviceregistration/code"
                          port: webRegPort
                        })

                        'create a message box with a button for closing the box
                        'when user closes box, webRegScreen should close and bring users to the gridScreen
                        m.showMessage("Thank you", "You are now registered as " + registrationInfo.first_name + " " + registrationInfo.last_name + ".")

                        m.utils.trackEvent({
                          trackType: "navigate"
                          value: "/home"
                          ctx: "/deviceregistration/code"
                          port: webRegPort
                        })

                        webRegScreen.Close()
                        return true
                      end if


                    else
                      'we get an error
                      print "there was an error while polling for response from web registration"
                      m.showMessage("We're sorry", "Registration wasn't able to be completed.")

                      m.utils.trackEvent({
                        trackType: "registerFail"
                        value: "bad-server-response-poll"
                        port: webRegPort
                      })

                      m.utils.trackEvent({
                        trackType: "navigate"
                        value: "/home"
                        ctx: "/deviceregistration/code"
                        port: webRegPort
                      })

                      webRegScreen.Close()
                      return false
                    end if

                  else if registrationResponse <> invalid and registrationResponse.id <> webRegAsyncId
                    'we got a response from a user tracking event, so no need to do anything
                    print "registration screen user event response"
                  end if

                else 'something went horribly wrong
                  print "haveRegistrationCode is not an expected type"
                  m.showMessage("We're sorry", "Registration wasn't able to be completed...")
                  m.utils.trackEvent({
                    trackType: "registerFail"
                    value: "unknown-error"
                    port: webRegPort
                  })

                  m.utils.trackEvent({
                    trackType: "navigate"
                    value: "/home"
                    ctx: "/deviceregistration/code"
                    port: webRegPort
                  })

                  webRegScreen.Close()
                  return false
                end if
              else if type(msg) = "roCodeRegistrationScreenEvent"
                if msg.GetIndex() = 0 or msg.GetIndex() = 1 'back button or cancel button pressed
                  m.utils.cancelAsyncRequest(webRegAsyncId)
                  
                  m.utils.trackEvent({
                    trackType: "registerFail"
                    value: "user-cancel"
                    port: webRegPort
                  })

                  m.utils.trackEvent({
                    trackType: "navigate"
                    value: "/home"
                    ctx: "/deviceregistration/code"
                    port: webRegPort
                  })
                  
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
                  ' return false
                end if
              end if
            end if
          end while
        end if
      end while

    end function
  }
end function



Function RegisterScreen_setupInitialScreen()
  m.isInitialScreen = true
  m.row = 5
  m.col = 0
  m.isComplete = false
  m.currNumber = ""

  loadingImage = {
    Url: "pkg:/images/oldUI/" + m.res + "/bg_initial.jpg"
    TargetRect: m.getRect("bg", 0)
    compositionMode: "Source"
  }

  return [loadingImage]
End Function
