' @authInfo: assocArray, authInfo AA as returned by Auth().getAuthInfo()
Function isLoggedInUser(authInfo = invalid)
  if authInfo = invalid
    authInfo = m.global.authInfo
  end if

  return (authInfo <> invalid and authInfo.userId <> invalid)
End Function


Function isNewUser()

  bNewUser = m.global.isNewUser
  return (bNewUser <> invalid and bNewUser = true and isLoggedInUser() = false)

End Function


Function needsToShowAgeVerificationScreen()
  if isLoggedInUser() = true AND m.global.authInfo.hasAge = true then
    return false
  else
    guestUserHasAgeInfo = TubiAuth(m.constants, m.Request).getGuestUserHasAgeInfo()
    ' In the case that the user is logged in but there is no age information associated with the account, hasAge defaults to false.
    if guestUserHasAgeInfo.hasAge = true and guestUserHasAgeInfo.expired <> true
      return false
    end if
  end if
  return true
End Function

