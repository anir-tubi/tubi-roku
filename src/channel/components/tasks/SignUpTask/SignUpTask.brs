Function init()
  m.top.functionName = "execSignUp"
End Function


Function execSignUp() As Void
  tubiLog("SignUpTask.execSignUp")
  constants = m.global.constants 'single thread-local reference to avoid thread rendezvous
  
  Request = TubiRequest(constants.settings.mode)
  Auth = TubiAuth(constants, Request)
  port = CreateObject("roMessagePort")
  
  requestParams = m.top.requestParams

  ' SignUp using platform, deviceId & credentials(email,password,gender,firstName,lastName,birthday)
  url = constants.urls.users.signup
  params = {
    platform: constants.platform  
    device_id: constants.deviceInfo.deviceId
    credentials: {
      email: requestParams.email
      password: requestParams.password
      gender: requestParams.gender
      first_name: requestParams.first_name
      last_name: requestParams.last_name
      birthday: requestParams.birthday
    }
  }
  body = FormatJSON(params)
  
  reqOptions = {
    method: "POST"
    body: body
  }
  requestObject = Request.createAsync(url, "signup", reqOptions)
  requestObject.start(port)
  
  user_id = invalid
  access_token = invalid
  
  ' This helps to start signup/registerCode process during automation after a delay
  ' so that "press back from Activation Screen" test case will not fail during automation
  sleep(m.top.delay)
  
  while true
    msg = wait(0, port)
    if type(msg) = "roUrlEvent" then
      result = requestObject.handleEvent(msg)
      if result <> invalid and result.response <> invalid then
        tubiLog("Received sign up response")
        if result.response.code >= 200 and result.response.code < 300 then
          parsed = ParseJSON(result.response.data)
          if parsed <> invalid
            user_id = parsed.user_id 
            access_token = parsed.access_token
            exit while
          else
            m.top.error = "signup"  
          end if
        else
          m.top.error = "signup"  
          return          
        end if
      end if
    end if
  end while

 ' Register Code using activationCode, userId & accessToken
  url = constants.urls.users.registerCode
  headers = Auth.getAuthHeaders(access_token)
  params = {
    activation_code: requestParams.activationCode
    user_id: user_id 
  }
  body = FormatJSON(params)
  
  reqOptions = {
    method: "POST"
    headers : headers
    body: body
  }
  requestObject = Request.createAsync(url, "registerCode", reqOptions)
  requestObject.start(port)  
  
  while true
    msg = wait(0, port)
    if type(msg) = "roUrlEvent" then
      result = requestObject.handleEvent(msg)
      if result <> invalid and result.response <> invalid then
        tubiLog("Received registerCode response")
        if result.response.code >= 200 and result.response.code < 300 then
          parsed = ParseJSON(result.response.data)
          if parsed = invalid
            m.top.error = "registerCode"
          end if
        else
          m.top.error = "registerCode" 
        end if
        return
      end if
    end if
  end while  
  
End Function