Function init()
  m.top.functionName = "registrationLoop"
End Function

Function registrationLoop() As Void
  tubiLog("RegistrationCodeTask.registrationLoop")
  constants = m.global.constants 'single thread-local reference to avoid thread rendevue
  Request = TubiRequest()
  
  ' Get Registration code
  url = constants.urls.users.urlBase + "/code/generate"
  params = {
    platform: constants.platform  
    device_id: constants.deviceInfo.deviceId
  }
  body = FormatJSON(params)
  reqOptions = {
    method: "POST"
    body: body
    headers: {
      "Content-type": "application/json"
    }
  }
  regCodeRequest = Request.createAsync(url, "webRegistration", reqOptions)
  
  port = CreateObject("roMessagePort")
  regCodeRequest.start(port)
  m.top.observeField("cancel", port)
  
  while true
    msg = wait(0, port)
    if type(msg) = "roUrlEvent" then
      result = regCodeRequest.handleEvent(msg)
      if result <> invalid then
        if result.response.code >= 200 and result.response.code < 300 then
          parsed = ParseJSON(result.response.data)
          if parsed <> invalid and parsed.activation_code <> invalid then
            m.top.code = parsed.activation_code
            activation_token = parsed.activation_token
            tubiLog("Received activation code: " + parsed.activation_code)
            exit while
          else
            tubiLog("Bad response generating reg code")
            return  ' bad response didn't have a reg code
          end if
        else
          tubiLog("Reg code generation failed " + stri(result.response.code))
          return 
        end if
      else
        ' no response available yet, keep waiting
      end if
    end if

    ' Check for cancellation on every loop, rather than isolating in a roSGNodeEvent check
    if m.top.cancel = true then 
      tubiLog("Registration cancelled")
      return
    end if
  end while


  ' Poll for registration status
  timespan = CreateObject("roTimeSpan")
  timespan.mark()
  while timespan.TotalSeconds() < m.top.expiration
    sleep(m.top.frequency)
    tubiLog("Polling registration status")
    url = constants.urls.users.urlBase + "/code/status"
    params = {
      activation_token: activation_token
      platform: constants.platform  
      device_id: constants.deviceInfo.deviceId
    }
    body = FormatJSON(params)
    reqOptions = {
      method: "POST"
      body: body
      headers: {
        "Content-type": "application/json"
      }
    }
    regCodeStatus = Request.createAsync(url, "webConfirmationPoll", reqOptions)
    regCodeStatus.start(port)
  
    while true
      msg = wait(0, port)
      if type(msg) = "roUrlEvent" then
        result = regCodeStatus.handleEvent(msg)
        if result <> invalid then
          if result.response.code >= 200 and result.response.code < 300 then
            parsed = ParseJSON(result.response.data)
            if parsed <> invalid and parsed.status <> invalid then
              tubiLog("Poll status = " + parsed.status)
              if parsed.status = "registered" then 
                auth = TubiAuth(constants, Request)
                ' persist the registration information before we notify the scene graph
                auth.handleRegistration(parsed)
                m.top.response = parsed  ' status may be "pending" or "registered"
                return  ' end the thread
              else
                m.top.response = parsed  ' status may be "pending" or "registered"
                exit while  ' pop out to outer while loop
              end if
            else
              tubiLog("Bad response polling reg code status")
              return
            end if
          else
            tubiLog("Reg code polling failed " + stri(result.code))
            return 
          end if
        else
          ' no response available yet, keep waiting
        end if
      end if
      if m.top.cancel = true then 
        tubiLog("Registration cancelled")
        return
      end if
    end while
  end while

End Function