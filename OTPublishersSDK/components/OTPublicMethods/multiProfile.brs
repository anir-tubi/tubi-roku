Function switchProfile(DSID as String)
  try
    activeDSID = getCurrentActiveProfile()
    if DSID = invalid then DSID = ""
    if isStringType(DSID) AND DSID.Trim() = "" then DSID = getGenericProfile()
    profileExists = isProfileExists(DSID)
    if isString(activeDSID) AND DSID <> activeDSID AND isValid(isMultiProfileAllowed())
      isAllowed = profileExists
      if not isAllowed then isAllowed = not isMaxProfileLimitReached()
      if isAllowed
        currentProfile = m.registry.readSection()
        currentProfileTCF = m.registry.readSection("TCF")
        currentProfileGPP = m.registry.readSection("GPP")
        if isvalid(currentProfileTCF) AND currentProfileTCF.count() > 0 then currentProfile["TCF"] = FormatJson(currentProfileTCF)
        if isvalid(currentProfileGPP) AND currentProfileGPP.count() > 0 then currentProfile["GPP"] = FormatJson(currentProfileGPP)
        m.registry.write(activeDSID, FormatJson(currentProfile), "OT_Profiles")
        m.registry.deleteSection()
        m.registry.deleteSection("TCF")
        m.registry.deleteSection("GPP")
        if profileExists
          hasIdentifier = m.registry.read(DSID, "OT_Profiles")
          m.registry.delete(DSID, "OT_Profiles")
          OTSDKData = ParseJson(hasIdentifier)
          if OTSDKData.doesExist("TCF")
            m.registry.writeSection(ParseJson(OTSDKData["TCF"]), "TCF")
            OTSDKData.delete("TCF")
          end if
          if OTSDKData.doesExist("GPP")
            m.registry.writeSection(ParseJson(OTSDKData["GPP"]), "GPP")
            OTSDKData.delete("GPP")
          end if
          m.registry.writeSection(OTSDKData)
          m.logger.set(m.errortype.success, m.errorTags.MultiProfile, "user '" + DSID + "'", m.constant.success["205"])
        else
          m.logger.set(m.errortype.success, m.errorTags.MultiProfile, "new user '" + DSID + "'", m.constant.success["205"])
        end if
      else
        return false
      end if
    end if
    return true
  catch e
    m.logger.error(e)
    return false
  end try
End Function

'   switch user profile public method
Function switchUserProfile(DSID as String) as Void
  result = false
  message = ""
  m.logger.set(m.errortype.info, m.errorTags.PublicMethod, "switchUserProfile" + m.constant.info["705"])
  if not (isValid(DSID) AND (type(DSID) = "String" OR type(DSID) = "roString"))
    message = m.constant.error["504"] + "switchUserProfile"
    m.logger.set(m.errortype.error, m.errorTags.MultiProfile, message)
  else if isValid(isMultiProfileAllowed())
    if DSID.Trim() = "" then DSID = getGenericProfile()
    isAllowed = isProfileExists(DSID)
    if not isAllowed then isAllowed = not isMaxProfileLimitReached()
    if isAllowed
      activeProfile = getCurrentActiveProfile()
      if activeProfile = DSID
        message = m.constant.failed["604"]
        m.logger.set(m.errortype.Failed, m.errorTags.MultiProfile, message)
      else
        params = OTSdkParams()
        params.identifier = DSID
        startSDK(params)
        result = true
        message = "user '" + DSID + "'" + m.constant.success["205"]
      end if
    else
      message = m.constant.warning["909"]
      m.logger.set(m.errortype.Warning, m.errorTags.MultiProfile, message)
    end if
  else
    message = m.constant.warning["910"]
    m.logger.set(m.errortype.Warning, m.errorTags.MultiProfile, message)
  end if
  m.onSwitchUserProfileCallback = {
    name: "onSwitchUserProfileCallback",
    response: result,
    message: message
  }
  if result
    createPromiseFromNode(m.top, true, "onDataSuccessMP").then(sub(data)
      if data <> invalid AND data
        m.logger.set(m.errortype.success, m.errorTags.MultiProfile, m.onSwitchUserProfileCallback.message)
        m.top.eventlistener["onSwitchUserProfileCallback"] = m.onSwitchUserProfileCallback
      else
        m.onSwitchUserProfileCallback.response = false
        m.top.eventlistener["onSwitchUserProfileCallback"] = m.onSwitchUserProfileCallback
      end if
      m.onSwitchUserProfileCallback = invalid
    end sub)
  else
    m.top.eventlistener["onSwitchUserProfileCallback"] = m.onSwitchUserProfileCallback
    m.onSwitchUserProfileCallback = invalid
  end if
End Function

'   delete user profile public method
Function deleteProfile(DSID as String)
  result = false
  message = ""
  messagetemp = ""
  m.logger.set(m.errortype.info, m.errorTags.PublicMethod, "deleteProfile" + m.constant.info["705"])
  if not (isValid(DSID) AND (type(DSID) = "String" OR type(DSID) = "roString"))
    message = m.constant.error["504"] + "deleteProfile"
    m.logger.set(m.errortype.error, m.errorTags.MultiProfile, message)
  else if isValid(isMultiProfileAllowed())
    if DSID.Trim() = "" then DSID = getGenericProfile()
    hasIdentifier = m.registry.read(DSID, "OT_Profiles")
    activeProfile = getCurrentActiveProfile()
    if activeProfile <> invalid AND activeProfile <> "" AND activeProfile = DSID.Trim()
      newDSID = getGenericProfile()
      if isString(newDSID) AND newDSID <> DSID
        switchProfile(newDSID)
        m.registry.delete(DSID, "OT_Profiles")
      else
        if newDSID = DSID then newDSID = ""
        m.registry.deleteSection()
        m.registry.deleteSection("TCF")
        m.registry.deleteSection("GPP")
      end if
      params = OTSdkParams()
      params.identifier = newDSID
      startSDK(params)
      messagetemp = "success"
      message = "current user '" + DSID + "'" + m.constant.success["206"]
      result = true
    else if hasIdentifier <> invalid AND hasIdentifier <> ""
      m.registry.delete(DSID, "OT_Profiles")
      message = "user '" + DSID + "'" + m.constant.success["206"]
      m.logger.set(m.errortype.success, m.errorTags.MultiProfile, message)
      result = true
    else
      message = m.constant.failed["605"] + "'" + DSID + "'"
      m.logger.set(m.errortype.error, m.errorTags.MultiProfile, message)
    end if
  else
    message = m.constant.warning["910"]
    m.logger.set(m.errortype.Warning, m.errorTags.MultiProfile, message)
  end if
  m.onDeleteProfileCallback = {
    name: "onDeleteProfileCallback",
    response: result,
    message: message
  }
  if result AND messagetemp = "success"
    createPromiseFromNode(m.top, true, "onDataSuccessMP").then(sub(data)
      if data <> invalid AND data
        m.logger.set(m.errortype.success, m.errorTags.MultiProfile, m.onDeleteProfileCallback.message)
        m.top.eventlistener["onDeleteProfileCallback"] = m.onDeleteProfileCallback
      else
        m.onDeleteProfileCallback.response = false
        m.top.eventlistener["onDeleteProfileCallback"] = m.onDeleteProfileCallback
      end if
      m.onDeleteProfileCallback = invalid
    end sub)
  else
    m.top.eventlistener["onDeleteProfileCallback"] = m.onDeleteProfileCallback
    m.onDeleteProfileCallback = invalid
  end if
End Function

' verify max profile limit reached
Function isMaxProfileLimitReached() as Boolean
  isLimitReached = false
  multiProfileConsent = isMultiProfileAllowed()
  if isValid(multiProfileConsent)
    numberOfProfilesInRegistry = getprofileCount()
    if not (isValid(multiProfileConsent["limit"]) AND multiProfileConsent["limit"] > numberOfProfilesInRegistry)
      isLimitReached = true
      m.logger.set(m.errortype.Warning, m.errorTags.MultiProfile, m.constant.warning["909"])
    end if
  end if
  return isLimitReached
End Function

Function getprofileCount()
  keys = []
  OT_Profiles = m.registry.readSection("OT_Profiles")
  if OT_Profiles.count() > 0 then keys = OT_Profiles.keys()
  currentuser = m.registry.read("subjectIdentifier")
  if currentuser <> invalid AND currentuser <> "" then keys.push(currentuser)
  return keys.count()
End Function

Function isProfileExists(DSID)
  OT_Profiles = m.registry.readSection("OT_Profiles")
  currentuser = m.registry.read("subjectIdentifier")
  return (OT_Profiles[DSID] <> invalid AND OT_Profiles[DSID] <> "") OR (currentuser <> invalid AND currentuser = DSID)
End Function

' verify multi profile
Function isMultiProfileAllowed() as Dynamic
  data = invalid
  multiProfileConsent = m.registry.read("OT_MP")
  OT_Profiles = m.registry.readSection("OT_Profiles")
  if isValid(OT_Profiles)
    for each item in OT_Profiles
      if OT_Profiles[item].Instr("OT_MP") <> -1
        profile = ParseJson(OT_Profiles[item])
        multiProfileConsent = profile["OT_MP"]
        exit for
      end if
    end for
  end if
  if isValid(multiProfileConsent) AND isString(multiProfileConsent) then data = ParseJson(multiProfileConsent)
  return data
End Function

Function setMultiProfileserverData()
  multiProfileConsent = optionalChaining(m, "OT_Data.OT_modelData.appConfig.multiProfileConsent")
  if isValid(multiProfileConsent)
    OT_MP = {}
    if isValid(multiProfileConsent.downloadDataAfterSwitch) then OT_MP["DData"] = multiProfileConsent.downloadDataAfterSwitch
    if isValid(multiProfileConsent.maxProfilesLimit) then OT_MP["limit"] = multiProfileConsent.maxProfilesLimit
    m.registry.write("OT_MP", FormatJson(OT_MP))
    m.logger.set(m.errortype.Warning, m.errorTags.MultiProfile, m.constant.warning["911"])
  else
    OT_MP = m.registry.read("OT_MP")
    if isString(OT_MP) then m.registry.delete("OT_MP")
    if isValid(m.isMigrated) AND m.isMigrated
      m.isMigrated = invalid
      OT_Profiles = m.registry.readSection("OT_Profiles")
      if isValid(OT_Profiles) then m.registry.deleteSection("OT_Profiles")
    end if
    m.logger.set(m.errortype.Warning, m.errorTags.MultiProfile, m.constant.warning["910"])
  end if
End Function

Function getGenericProfile()
  DSID = ""
  OT_Profiles = m.registry.readSection("OT_Profiles")
  genericProfile = m.registry.read("genericProfile")
  if isValid(genericProfile)
    DSID = getCurrentActiveProfile()
  else if OT_Profiles <> invalid AND OT_Profiles.keys().count() > 0
    for each item in OT_Profiles
      if OT_Profiles[item].Instr("genericProfile") <> -1
        DSID = item
        exit for
      end if
    end for
  end if
  return DSID
End Function

Function getCurrentActiveProfile()
  subjectIdentifier = ""
  identifier = m.registry.read("subjectIdentifier")
  if isString(identifier) then subjectIdentifier = identifier
  return subjectIdentifier
End Function

Function renameProfile(oldDSID, newDSID = invalid)
  m.logger.set(m.errortype.info, m.errorTags.PublicMethod, "renameProfile" + m.constant.info["705"])
  value = {
    response: false,
    message: ""
  }
  if not isValid(isMultiProfileAllowed())
    if isString(newDSID)
      value.message = "Multi-Profile Consent is disabled. Please pass only one parameter: newProfileID."
      m.logger.set(m.errortype.info, m.errorTags.MultiProfile, value.message)
      return value
    end if
    newDSID = oldDSID
    oldDSID = getCurrentActiveProfile()
  end if
  if not isString(oldDSID)
    value.message = "could you please pass a valid oldProfileID."
    m.logger.set(m.errortype.info, m.errorTags.MultiProfile, value.message)
    return value
  end if

  if not isString(newDSID)
    value.message = "could you please pass a valid newProfileID."
    m.logger.set(m.errortype.info, m.errorTags.MultiProfile, value.message)
    return value
  end if

  oldDSID = oldDSID.trim()
  newDSID = newDSID.trim()
  if oldDSID = newDSID
    value.message = "Old and new profile ID values are the same, renaming will not be performed."
    m.logger.set(m.errortype.info, m.errorTags.MultiProfile, value.message)
    return value
  end if

  if not isProfileExists(oldDSID)
    value.message = "No user profile found with ID: " + oldDSID + ". Please pass a valid user ID."
    m.logger.set(m.errortype.info, m.errorTags.MultiProfile, value.message)
    return value
  end if

  if isProfileExists(newDSID)
    value.message = "User already exists with the new profile ID: " + newDSID + ". Two users cannot have same user ID. Pass a unique userID for the new one."
    m.logger.set(m.errortype.info, m.errorTags.MultiProfile, value.message)
    return value
  end if

  hasIdentifier = m.registry.read(oldDSID, "OT_Profiles")
  activeProfile = getCurrentActiveProfile()
  if activeProfile <> invalid AND activeProfile <> "" AND activeProfile = oldDSID
    m.registry.write("subjectIdentifier", newDSID)
    m.registry.write("OT_RP", "1")
    genericProfile = m.registry.read("genericProfile")
    if isString(genericProfile) then m.registry.delete("genericProfile")
    OT_Data = m.global.OT_Data
    if isValid(OT_Data["headers"]) then OT_Data["headers"]["identifier"] = newDSID
    m.global.OT_Data = OT_Data
    value.message = "user '" + newDSID + "'" + m.constant.success["207"]
    m.logger.set(m.errortype.success, m.errorTags.MultiProfile, value.message)
    value.response = true
  else if hasIdentifier <> invalid AND hasIdentifier <> ""
    OTSDKData = ParseJson(hasIdentifier)
    OTSDKData["subjectIdentifier"] = newDSID
    OTSDKData["OT_RP"] = "1"
    if OTSDKData.doesExist("genericProfile") then OTSDKData.delete("genericProfile")
    m.registry.delete(oldDSID, "OT_Profiles")
    m.registry.write(newDSID, FormatJson(OTSDKData), "OT_Profiles")
    value.message = "user '" + newDSID + "'" + m.constant.success["207"]
    m.logger.set(m.errortype.success, m.errorTags.MultiProfile, value.message)
    value.response = true
  end if
  return value
End Function