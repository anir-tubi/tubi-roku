Function init()
  m.top.functionName = "execGetAuthInfo"
End Function

Function execGetAuthInfo()
  tubiLog("AuthTask.execGetAuthInfo")
  ' module loading
  constants = m.global.constants 'single thread-local reference to avoid thread rendevue
  Request = TubiRequest()
  Auth = TubiAuth(constants, Request)

  m.top.authInfo = Auth.getAuthInfo() 
End Function