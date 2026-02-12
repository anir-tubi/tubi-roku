'This Function can be used in screens where we need to check if the user is in multi account
Function isUserInMultiAccountFromRegistry()

  nMultiAccount = 0
  if m.kidsModeFeatureOn = invalid
    m.kidsModeFeatureOn = getExternalConfigValueFromGlobal("enable_multiple_accounts", false)
  end if

  if m.kidsModeFeatureOn = false
    return false
  end if

  registry = CreateObject("roRegistry")
  sections = registry.getSectionList()
  isTreatmentEnabled = (getStatsigExperimentResource("roku_multi_account", "roku_multi_account_v0", false).variant <> "none")
  authPrefix = "auth"

  if m.constants <> invalid AND m.constants.settings.stagingApis = true then
    authPrefix = "auth_staging"
  end if

  for each section in sections
    if section.InStr(authPrefix + "__") = 0
      profileId = section.Replace(authPrefix + "__", "")
      if profileId <> "" AND profileId <> "guest"
        nMultiAccount = nMultiAccount + 1
      end if
    end if
  end for

  ' at least one account is present when experiment is enabled
  if isTreatmentEnabled = true AND nMultiAccount > 0
    return true
  end if

  ' if there are multiple accounts then we should continue to support multi account
  if isTreatmentEnabled = false AND nMultiAccount > 1
    return true
  end if

  return false
End Function