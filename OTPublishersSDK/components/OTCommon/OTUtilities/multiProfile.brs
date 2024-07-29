function switchProfile(DSID)
  currentProfile = m.registry.readSection()
  m.registry.deleteSection()
  if isMultiProfileAllowed() and (isMaxProfileLimitReached() or isProfileExists(DSID))
    hasIdentifier = m.registry.read(DSID, "OT_Profiles")
    if m.previousSubjectIdentifier <> invalid and m.previousSubjectIdentifier <> "" then m.registry.write(m.previousSubjectIdentifier, FormatJson(currentProfile), "OT_Profiles")
    if hasIdentifier <> invalid and hasIdentifier <> ""
      m.registry.delete(DSID, "OT_Profiles")
      OTSDKData = ParseJson(hasIdentifier)
      m.registry.writeSection(OTSDKData)
      m.logger.set(m.errortype.success, m.errorTags.MultiProfile, "user '" + DSID + "'", m.constant.success["205"])
    else
      m.logger.set(m.errortype.success, m.errorTags.MultiProfile, "new user '" + DSID + "'", m.constant.success["205"])
    end if
  end if
end function

function resetOTinitialize()
  m.global.removeField("_OT_initialize_data")
  m.global.removeField("_OT_IABVendor_data")
  removeUSPGlobal()
  if m.global.doesExist("IABTCF_AddtlConsent") then m.global.removeField("IABTCF_AddtlConsent")
  removeIabGlobal()
  init()
end function

'   switch user profile public method
function switchUserProfile(DSID as string)
  m.logger.set(m.errortype.info, m.errorTags.PublicMethod, "switchUserProfile" + m.constant.info["705"])
  if DSID = invalid or DSID.Trim() = ""
    m.logger.set(m.errortype.error, m.errorTags.MultiProfile, m.constant.error["504"], "switchUserProfile")
    return ""
  end if
  if isMultiProfileAllowed() and (isMaxProfileLimitReached() or isProfileExists(DSID))
    m.isSwitchUserProfile = true
    if m.subjectIdentifier = DSID
      m.logger.set(m.errortype.Failed, m.errorTags.MultiProfile, m.constant.failed["604"])
      return ""
    end if
    params = OTSdkParams()
    ONETRUST_ROKU_KEYS = m.registry.read("ONETRUST_ROKU_KEYS")
    resetOTinitialize()
    if ONETRUST_ROKU_KEYS <> invalid and ONETRUST_ROKU_KEYS <> ""
      ONETRUST_ROKU_KEYS = ParseJson(ONETRUST_ROKU_KEYS)
      ONETRUST_ROKU_KEYS.identifier = DSID
      m.registry.write("ONETRUST_ROKU_KEYS", FormatJson(ONETRUST_ROKU_KEYS))
    end if
    params.identifier = DSID
    initOTSDKData(params)
    m.top.onSwitchUserProfileCallback = true
  end if
  return ""
end function

'   delete user profile public method
function deleteProfile(DSID as string)
  if DSID = invalid or DSID.Trim() = ""
    m.logger.set(m.errortype.error, m.errorTags.MultiProfile, m.constant.error["504"], "deleteProfile")
  else if isMultiProfileAllowed()
    hasIdentifier = m.registry.read(DSID, "OT_Profiles")
    if m.subjectIdentifier <> invalid and m.subjectIdentifier <> "" and m.subjectIdentifier = DSID.Trim()
      newDSID = getGenericProfile()
      m.previousSubjectIdentifier = ""
      if newDSID <> "" then m.previousSubjectIdentifier = newDSID
      params = OTSdkParams()
      ONETRUST_ROKU_KEYS = m.registry.read("ONETRUST_ROKU_KEYS")
      switchProfile(newDSID)
      m.logger.set(m.errortype.success, m.errorTags.MultiProfile, "current user '" + DSID + "'", m.constant.success["206"])
      resetOTinitialize()
      if ONETRUST_ROKU_KEYS <> invalid and ONETRUST_ROKU_KEYS <> ""
        ONETRUST_ROKU_KEYS = ParseJson(ONETRUST_ROKU_KEYS)
        ONETRUST_ROKU_KEYS.identifier = newDSID
        m.registry.write("ONETRUST_ROKU_KEYS", FormatJson(ONETRUST_ROKU_KEYS))
      end if
      params.identifier = newDSID
      initOTSDKData(params)
      m.top.onDeleteProfileCallback = true
    else if hasIdentifier <> invalid and hasIdentifier <> ""
      m.registry.delete(DSID, "OT_Profiles")
      m.logger.set(m.errortype.success, m.errorTags.MultiProfile, "user '" + DSID + "'", m.constant.success["206"])
      m.top.onDeleteProfileCallback = true
    else
      m.logger.set(m.errortype.error, m.errorTags.MultiProfile, m.constant.failed["605"], "'" + DSID + "'")
    end if
  end if
end function

' verify max profile limit reached
function isMaxProfileLimitReached() as boolean
  isLimitReached = false
  sdkData = m.global._OT_initialize_data
  if sdkData = invalid or sdkData.keys().count() = 0
    return isLimitReached
  end if
  multiProfileConsent = optionalChaining(sdkData, "culture.MobileData.multiProfileConsent")
  if multiProfileConsent <> invalid and multiProfileConsent.isEnabled <> invalid and multiProfileConsent.maxProfilesLimit <> invalid
    numberOfProfilesInRegistry = getNumberOfProfiles()
    if multiProfileConsent.isEnabled
      if multiProfileConsent.maxProfilesLimit > numberOfProfilesInRegistry
        isLimitReached = true
      else
        m.logger.set(m.errortype.Warning, m.errorTags.MultiProfile, m.constant.warning["909"])
        isLimitReached = false
      end if
    else if numberOfProfilesInRegistry = 0
      isLimitReached = true
    end if
  end if
  return isLimitReached
end function

function getNumberOfProfiles()
  keys = []
  OT_Profiles = m.registry.readSection("OT_Profiles")
  if OT_Profiles.count() > 0 then keys = OT_Profiles.keys()
  currentuser = m.registry.read("subjectIdentifier")
  if currentuser <> invalid and currentuser <> "" then keys.push(currentuser)
  return keys.count()
end function

function isProfileExists(DSID)
  OT_Profiles = m.registry.readSection("OT_Profiles")
  currentuser = m.registry.read("subjectIdentifier")
  return (OT_Profiles[DSID] <> invalid and OT_Profiles[DSID] <> "") or (currentuser <> invalid and currentuser = DSID)
end function

' verify multi profile
function isMultiProfileAllowed() as boolean
  isAllowed = false
  sdkData = m.global._OT_initialize_data
  if sdkData = invalid or sdkData.keys().count() = 0
    return isAllowed
  end if
  multiProfileConsent = optionalChaining(sdkData, "culture.MobileData.multiProfileConsent")
  isAllowed = multiProfileConsent <> invalid and multiProfileConsent.isEnabled <> invalid and multiProfileConsent.isEnabled
  if not isAllowed
    m.logger.set(m.errortype.Warning, m.errorTags.MultiProfile, m.constant.warning["910"])
  end if
  return isAllowed
end function

function getGenericProfile()
  DSID = ""
  OT_Profiles = m.registry.readSection("OT_Profiles")
  if OT_Profiles <> invalid and OT_Profiles.keys().count() > 0
    for each item in OT_Profiles
      if OT_Profiles[item].Instr("genericProfile") <> -1
        DSID = item
        exit for
      end if
    end for
  end if
  return DSID
end function