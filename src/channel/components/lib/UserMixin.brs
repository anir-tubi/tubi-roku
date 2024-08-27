' @authInfo: assocArray, authInfo AA as returned by Auth().getAuthInfo()
Function isLoggedInUser(authInfo = invalid)
  if authInfo = invalid
    if m.constants = invalid then
      m.constants = getConstantsFromGlobal()
    end if

    authInfo = TubiAuth(m.constants).getAuthInfo()
  end if

  return (authInfo <> invalid AND authInfo.userId <> invalid)
End Function


Function isNewUser()

  bNewUser = m.global.isNewUser
  return (bNewUser <> invalid AND bNewUser = true AND isLoggedInUser() = false)

End Function
