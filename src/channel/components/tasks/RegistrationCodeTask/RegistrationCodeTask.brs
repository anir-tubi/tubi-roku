Function init()
  m.top.functionName = "registrationLoop"
End Function

Function registrationLoop() As Void
  tubiLog("RegistrationCodeTask.registrationLoop")
  constants = m.global.constants 'single thread-local reference to avoid thread rendevue
  Request = TubiRequest()
  pollFailureCount = 0
  maxConsecPollFailures = m.top.maxConsecPollFailures
  
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
            'received a valid response but it didn't have any json or the json didn't contain a code
            tubiLog("Bad response generating reg code")
            m.global.trackingLoggingTask.trackEvent = {
              trackType: "registerFail"
              value: "bad-server-response-nocode"
              ctx: result.response.code
            }
            m.top.error = "code"
            return  ' bad response didn't have a reg code
          end if
        else
          'didn't receive a valid response when requesting a code
          tubiLog("Reg code generation failed " + stri(result.response.code))
          'this event will only fire once per attempt to get code, not on every retry
          m.global.trackingLoggingTask.trackEvent = {
            trackType: "registerFail"
            value: "bad-server-response-code"
            ctx: result.response.code
          }
          m.top.error = "code"
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
              if parsed.status = "registered" then   ' status may be "pending" or "registered"
                auth = TubiAuth(constants, Request)
                ' persist the registration information before we notify the scene graph
                auth.handleRegistration(parsed)
                m.top.response = parsed
                m.global.trackingLoggingTask.trackEvent = {
                  trackType: "registerSuccess"
                }  
                return  ' end the thread
              else
                m.top.response = parsed  ' status should be "pending" at this point
                pollFailureCount = 0
                exit while  ' pop out to outer while loop
              end if
            else
              'we got a polling response but either no json attached or no value for the status key
              tubiLog("Bad response polling reg code status")
              m.global.trackingLoggingTask.trackEvent = {
                trackType: "registerFail"
                value: "bad-response-status"
              }              
              pollFailureCount = pollFailureCount + 1
              if pollFailureCount >= maxConsecPollFailures
                m.top.error = "poll"
                return
              else
                'this polling attempt failed but we can continue polling,
                'so exit to outer while loop and send a new polling request
                exit while
              end if
            end if
          else
            tubiLog("Reg code polling failed " + stri(result.response.code))
            m.global.trackingLoggingTask.trackEvent = {
              trackType: "registerFail"
              value: "bad-server-response-poll"
            }
            pollFailureCount = pollFailureCount + 1
            if pollFailureCount >= maxConsecPollFailures
              m.top.error = "poll"
              return
            else
              'this polling attempt failed but we can continue polling,
              'so exit to outer while loop and send a new polling request 
              exit while
            end if
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

  m.top.error = "expire"

  'we haven't exited the while loop by returning out of the function so we must have hit the expiration timeout
  m.global.trackingLoggingTask.trackEvent = {
    trackType: "registerFail"
    value: "code-user-timeout"
  }

End Function