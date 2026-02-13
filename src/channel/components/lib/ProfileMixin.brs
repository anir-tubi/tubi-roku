
'this function should be used in content controller context

Function isUserInMultiAccount()
  if m.Auth = invalid
    m.Auth = TubiAuth(m.constants)
  end if

  profiles = m.Auth.getAllProfilesAuthInfo()

  if m.enableMultipleAccounts = invalid
    m.enableMultipleAccounts = getExternalConfigValueFromGlobal("enable_multiple_accounts", false)
  end if

  ' if multi account not enabled from remote config, then swith off multi account feature
  if m.enableMultipleAccounts = false
    return false
  end if

  isTreamentEnabled = (getStatsigExperimentResource("roku_multi_account", "roku_multi_account_v0", false).variant <> "none")

  if profiles["guest"] <> invalid
    profileCount = profiles.count() - 1
  else
    profileCount = profiles.count()
  end if

  if isTreamentEnabled = true AND profileCount > 0
    return true
  end if


  ' THIS IF IS COMMENTED OUT FOR SUBMISSION BUILD. IT WILL BE UNCOMMENTED FOR REMOTE RELEASE.
  ' if isTreamentEnabled = false AND profileCount > 1
  '   return true
  ' end if

  return false
End Function
