
'this function should be used in content controller context

Function isUserInMultiAccount()
  if m.tubiAuthUpdate = invalid
    m.tubiAuthUpdate = TubiAuthUpdate(m.constants)
  end if

  profiles = m.tubiAuthUpdate.getAllProfilesAuthInfo()
  authInfo = m.tubiAuthUpdate.getAuthInfo()

  ' if multi account not enabled from remote config, then swith off multi account feature
  if getExternalConfigValueFromGlobal("enable_multiple_accounts", false) = false
    ' if user is in US kids mode and then travels to UK then we should not show kids account
    if isKidsProfile(authInfo) = true
      if isNonEmptyString(authInfo.parentId) = true
        m.tubiAuthUpdate.copyProfileToMainAuth(authInfo.parentId)
      end if
    end if
    return false
  end if

  isTreamentEnabled = (getStatsigExperimentResource("roku_multi_account", "roku_multi_account_v0", true).variant <> "none")

  if profiles["guest"] <> invalid
    profileCount = profiles.count() - 1
  else
    profileCount = profiles.count()
  end if

  if isTreamentEnabled = true
    if profileCount > 0
      return true
    end if
  else
    if profileCount > 1
      return true
    end if
  end if
  return false
End Function
