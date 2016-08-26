Function init()
  m.top.functionName = "execLogOut"
End Function

Function execLogOut()
  ' module loading
  constants = m.global.constants 'single thread-local reference to avoid thread rendevue
  Request = TubiRequest()
  Auth = TubiAuth(constants, Request)

  Auth.logout() 
End Function