
'this function should be used in content controller context

Function isUserInMultiAccount()
  if getStatsigExperimentResource("roku_multi_account", "roku_multi_account_v0", false).variant <> "none"
    if m.tubiAuthUpdate = invalid
      m.tubiAuthUpdate = TubiAuthUpdate(m.constants)
    end if
    profiles = m.tubiAuthUpdate.getAllProfilesAuthInfo()
    if profiles.count() > 0 AND (profiles.count() > 1 OR profiles["guest"] = invalid)
      return true
    end if
  end if
  return false
End Function
