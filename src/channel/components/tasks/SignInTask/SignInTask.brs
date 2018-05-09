Function init()
  m.top.functionName = "execSignIn"
End Function

Function execSignIn() As Void
  tubiLog("SignInTask.execSignIn")
  constants = m.global.constants 'single thread-local reference to avoid thread rendevue
  
  Request = TubiRequest()
  Auth = TubiAuth(constants, Request)

  ' Get Registration code
  url = constants.urls.users.login
  params = {
    type: "email"
    platform: constants.platform  
    device_id: constants.deviceInfo.deviceId
    credentials: {
      email: m.top.email
      password: m.top.password
    }
  }
  body = FormatJSON(params)
  reqOptions = {
    method: "POST"
    body: body
  }
  request = Request.createAsync(url, "webLogin", reqOptions)
  
  port = CreateObject("roMessagePort")
  request.start(port)
  
  while true
    msg = wait(0, port)
    if type(msg) = "roUrlEvent" then
      result = request.handleEvent(msg)
      if result <> invalid and result.response <> invalid then
        tubiLog("Received sign in response")
        if result.response.code >= 200 and result.response.code < 300 then
          parsed = ParseJSON(result.response.data)
          if parsed <> invalid then
            ' persist the access token before we notify the scene graph
            Auth.handleRegistration(parsed)
            m.global.trackingLoggingTask.trackEvent = {
              trackType: "signIn"
            }
          else
            tubiLog("Bad response JSON")
          end if
        else
          tubiLog("Sign in failed " + stri(result.response.code))
        end if
        m.top.response = result.response
      end if
    end if
  end while
End Function