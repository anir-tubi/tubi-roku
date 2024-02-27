Function init()
  m.top.functionName = "execInitializeUserData"
End Function


'''''''''
' Synchronously load auth info, followed by loading of user categories (if user is logged in)
Function execInitializeUserData()
  tubiLog("AuthTask.execInitializeUserData")
  constants = getConstantsFromGlobal()
  Request = TubiRequest(constants.settings)
  Auth = TubiAuth(constants, Request)
  authInfo = Auth.getAuthInfo()


  ' guest users who have recently failed the age gate, continue to be locked in Kids mode for the entire
  ' 24 hour duration. Guest users who have not failed the age gate delete any previous hasAge info which
  ' ensures that no age gate is shown.
  if authInfo = invalid
    guestUserHasAgeInfo = Auth.getGuestUserHasAgeInfo()
    if guestUserHasAgeInfo.expired = true
      Auth.deleteGuestUserHasAgeInfo()
      m.top.guestUserHasAgeInfo = invalid
    else
      m.top.guestUserHasAgeInfo = guestUserHasAgeInfo
    end if
  end if

  m.top.authInfo = authInfo  ' set last so that it can be used as a trigger
End Function


Function execRefreshAuthInfo()
  tubiLog("AuthTask.execRefreshAuthInfo")
  constants = getConstantsFromGlobal()
  Request = TubiRequest(constants.settings)
  Auth = TubiAuth(constants, Request)
  newAuthInfo = invalid

  ' only transfer the refresh token and log the external user in
  ' if there is no one currently logged in on the roku
  if m.top.externalAuthInfo <> invalid
    'this runs synchronously
    newAuthInfo = Auth.transferRefreshToken(m.top.externalAuthInfo)
  end if

  m.top.authInfoRefreshed = newAuthInfo
End Function


Function execSignOut()
  tubiLog("AuthTask.execSignOut")
  constants = getConstantsFromGlobal() 'single thread-local reference to avoid thread rendezvous
  Request = TubiRequest(constants.settings)
  Auth = TubiAuth(constants, Request)
  Auth.logout()
  Auth.deleteGuestUserHasAgeInfo()
  m.top.guestUserHasAgeInfo = invalid
  m.top.authInfo = Auth.getAuthInfo()
End Function
