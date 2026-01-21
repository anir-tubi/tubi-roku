'This Function can be used in screens where we need to check if the user is in multi account
Function isUserInMultiAccountFromRegistry()
  if getStatsigExperimentResource("roku_multi_account", "roku_multi_account_v0", false).variant <> "none"
    registry = CreateObject("roRegistry")
    sections = registry.getSectionList()

    authPrefix = "auth"
    if m.constants <> invalid AND m.constants.settings.stagingApis = true then
      authPrefix = "auth_staging"
    end if

    for each section in sections
      if section.InStr(authPrefix + "__") = 0
        profileId = section.Replace(authPrefix + "__", "")
        if profileId <> "" AND profileId <> "guest"
          return true
        end if
      end if
    end for
  end if
  return false
End Function