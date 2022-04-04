' @authInfo: assocArray, authInfo AA as returned by Auth().getAuthInfo()
Function isLoggedInUser(authInfo = invalid)
  if authInfo = invalid
    authInfo = m.global.authInfo
  end if

  return (authInfo <> invalid and authInfo.userId <> invalid)
End Function


Function isReturningUser()
  returningUser = false
  Auth = TubiAuth(m.constants, m.Request)

  'these were converted days since year Jan 1, 1970, the unix epoch when user first-time launch the app
  daysFromEpochForFirstVisit = Auth.getFirstVisit()
  
  'these were converted days since year Jan 1, 1970, the unix epoch 
  daysFromEpoch = getNumberOfDaysSinceEpoch()
  if daysFromEpochForFirstVisit <> invalid and daysFromEpoch <> invalid and daysFromEpoch > daysFromEpochForFirstVisit + 1
    returningUser = true
  end if
  return returningUser
End Function