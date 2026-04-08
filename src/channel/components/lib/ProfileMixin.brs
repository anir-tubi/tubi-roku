
'this function should be used in content controller context

Function isUserInMultiAccount()
  if m.enableMultipleAccounts = invalid
    m.enableMultipleAccounts = getExternalConfigValueFromGlobal("enable_multiple_accounts", false)
  end if

  ' if multi account not enabled from remote config, then swith off multi account feature
  if m.enableMultipleAccounts = false
    return false
  end if

  profileCount = getUserProfileCount()

  ' US users are in multi account feature by default.
  ' if user has already created a profile then we always show give them MAKA feature.
  ' one use case is if user in US registers multiple accounts and then travel to MX.
  if (profileCount > 0 AND UCase(m.constants.deviceInfo.countryCode) = "US") OR (profileCount > 1)
    return true
  end if

  return false
End Function


Function getUserProfileCount(profiles = invalid)
  if profiles = invalid
    if m.Auth = invalid
      m.Auth = TubiAuth(m.constants)
    end if

    profiles = m.Auth.getAllProfilesAuthInfo()
  end if

  if profiles["guest"] <> invalid
    profileCount = profiles.count() - 1
  else
    profileCount = profiles.count()
  end if

  return profileCount
End Function
